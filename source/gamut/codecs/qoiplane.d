module gamut.codecs.qoiplane;

nothrow @nogc:

import core.stdc.stdlib: realloc, malloc, free;
import core.stdc.string: memset;

import gamut.codecs.qoi2avg;

/// A QOI-inspired codec for 8-bit greyscale images.
///
/// Because the input is 8-bit, we are forced to split bytes in nibbles.
///
/// Incompatible adaptation of QOI format - https://phoboslab.org
///
/// -- LICENSE: The MIT License(MIT)
/// Copyright(c) 2021 Dominic Szablewski (original QOI format)
/// Copyright(c) 2022 Guillaume Piolat
/// Permission is hereby granted, free of charge, to any person obtaining a copy of
/// this software and associated documentation files(the "Software"), to deal in
/// the Software without restriction, including without limitation the rights to
/// use, copy, modify, merge, publish, distribute, sublicense, and / or sell copies
/// of the Software, and to permit persons to whom the Software is furnished to do
/// so, subject to the following conditions :
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.

/// -- Documentation

/// This library provides the following functions;
/// - qoiplane_decode  -- decode the raw bytes of a QOI-plane image from memory
/// - qoiplane_encode  -- encode an rgba buffer into a QOI-plane image in memory
/// 
///
/// A QOI-Plane file has a 23 byte header, compatible with Gamut QOIX.
///
/// struct qoi_header_t {
///     char     magic[4];         // magic bytes "qoix"
///     uint32_t width;            // image width in pixels (BE)
///     uint32_t height;           // image height in pixels (BE)
///     uint8_t  version_;         // Major version of QOIX format.
///     uint8_t  channels;         // 1 = 8-bit luminance
///     uint8_t  colorspace;       // 0 = sRGB with linear alpha, 1 = all channels linear
///     float    pixelAspectRatio; // -1 = unknown, else Pixel Aspect Ratio
///     float    resolutionX;      // -1 = unknown, else physical resolution in DPI
/// };
///
/// The decoder and encoder start with {l: 0} as the previous
/// pixel value. Pixels are either encoded as
/// - a run of the previous pixel
/// - a difference to the previous pixel value
/// - full luminance value
///
/// Each chunk starts with a tag, followed by a number of data bits. The bit length
/// of chunks is divisible by 4 - i.e. all chunks are nibble aligned. All values
/// encoded in these data bits have the most significant bit on the left. 
/// The last nibble needs to be 0xf.
///
/// The byte stream's end is marked with 4 0xff bytes.
///
///
/// Encoding:
///
/// QOIPLANE_DIFF1     0xxx             => diff -4..+3 vs average of rounded up left pixel and top pixel
/// QOIPLANE_REPEAT1   10xx             => repeat 1 to 4 times the last pixel
/// QOIPLANE_DIFF2     110x xxxx        => diff -16..15 vs average of rounded up left pixel and top pixel
/// QOIPLANE_DIRECT    1110 xxxx xxxx   => direct value
/// QOIPLANE_REPEAT2   1111 xxxx xxxx   => repeat 5 to 259 times a pixel.
///                                        (1111 1111 1111 disallowed, indicates end of stream)

static immutable ubyte[6] qoiplane_padding = [255,255,255,255,255,255]; // this is 4x a full QOIPLANE_REPEAT2

/* Encode raw L8 pixels into a QOIPlane image in memory.
The function either returns null on failure (invalid parameters or malloc 
failed) or a pointer to the encoded data on success. On success the out_len 
is set to the size in bytes of the encoded data.
The returned qoi data should be free()d after use. */
ubyte* qoiplane_encode(const(ubyte)* data, const(qoi_desc)* desc, int *out_len) 
{
    if (desc.channels != 1 ||
        desc.height >= QOIX_PIXELS_MAX / desc.width
    ) {
        return null;
    }

    // At worst, each pixel take 12 bit to be encoded.
    int num_pixels = desc.width * desc.height;
    int max_size = (num_pixels * 3 + 1) / 2
                 + QOIX_HEADER_SIZE + cast(int)(qoiplane_padding.sizeof);

    ubyte* stream;

    int p = 0; // write index into output stream
    ubyte* bytes = cast(ubyte*) QOI_MALLOC(max_size);
    if (!bytes) 
    {
        return null;
    }

    qoi_write_32(bytes, &p, QOIX_MAGIC);
    qoi_write_32(bytes, &p, desc.width);
    qoi_write_32(bytes, &p, desc.height);
    bytes[p++] = 1; // Put a version number :)
    bytes[p++] = desc.channels; // 1, or 2
    bytes[p++] = desc.colorspace;
    qoi_write_32f(bytes, &p, desc.pixelAspectRatio);
    qoi_write_32f(bytes, &p, desc.resolutionY);

    bool writeHiNibble = false; // nibble index into output stream.

    void outputNibble(ubyte nibble) nothrow @nogc
    {
        assert(nibble < 16);
        if (writeHiNibble)
        {
            bytes[p] = cast(ubyte)(nibble << 4);
        }
        else
        {
            bytes[p++] |= nibble;
        }
        writeHiNibble = !writeHiNibble;
    }

    void encodeRun(ref int run) nothrow @nogc
    {
        assert(run > 0 && run <= 259);
        if (run <= 4)
        {
            ubyte nibble =  0x8 | cast(ubyte)(run - 1);
            outputNibble(nibble); // QOIPLANE_REPEAT1
        }
        else
        {
            run -= 5;
            // QOIPLANE_REPEAT2
            outputNibble(0xf);
            outputNibble( (cast(ubyte)run) >>> 4);
            outputNibble(run & 15);
        }
        run = 0;
    }

    ubyte px = 0;
    int channels = desc.channels;
    int stride = desc.width * channels;
    int run = 0;
    int pixels_encoded = 0;

    for (int posy = 0; posy < desc.height; ++posy)
    {
        const(ubyte)* line = data + desc.pitchBytes * posy;
        const(ubyte)* lineAbove = (posy > 0) ? (data + desc.pitchBytes * (posy - 1)) : null;

        for (int posx = 0; posx < desc.width; ++posx)
        {
            // last pixel is the new predictor
            ubyte px_ref = px;

            // take next pixel to encode
            px = line[posx];            

            if (px == px_ref)
            {
                run++;
                if (run == 259 || (pixels_encoded + 1 == num_pixels))
                    encodeRun(run);
            }
            else 
            {
                if (run > 0) 
                    encodeRun(run);

                // take top pixel (if it exist), else it's the same predictor
                ubyte px_top = (posy > 0) ? lineAbove[posx] : px_ref;

                ubyte px_avg = (px_top + px_ref + 1) / 2;

                byte vg_l = cast(byte)(px - px_avg);

                if (vg_l >= -4 && vg_l <= 3)
                {
                    ubyte nibble = 0x0 | cast(ubyte)(vg_l + 4);
                    outputNibble(nibble); // QOIPLANE_DIFF1
                }
                else if (vg_l >= -16 && vg_l <= 15)
                {
                    ubyte diff2b =  0xc0 | cast(ubyte)(vg_l + 16);
                    outputNibble(diff2b >>> 4); // QOIPLANE_DIFF2   
                    outputNibble(diff2b & 0x0f);
                }
                else 
                {
                    outputNibble(0xe); // QOIPLANE_DIRECT
                    outputNibble(px >>> 4);
                    outputNibble(px & 0x0f);
                }
            }
            pixels_encoded++;
        }
    }

    // Put 3x QOIPLANE_REPEAT2 with full bits in order to have 4 0xff bytes
    foreach(i; 0..9) outputNibble(0xf);

    // Last nibble to fit
    if (!writeHiNibble) outputNibble(0xf);

    *out_len = p;
    return bytes;
}
