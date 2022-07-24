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

static immutable ubyte[4] qoiplane_padding = [255,255,255,255]; // this is 4x a full QOIPLANE_REPEAT2

enum ubyte initialPredictor = 0;

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

    bool writeHiNibble = true; // nibble index into output stream.

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

    void outputByte(ubyte b)
    {
        if (writeHiNibble)
        {
            bytes[p++] = b;
        }
        else
        {
            bytes[p++] |= (b >>> 4);
            bytes[p] = cast(ubyte)(b << 4);
        }
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
            outputByte(cast(ubyte)run);
        }
        run = 0;
    }

    ubyte px = initialPredictor;
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
                    outputByte(diff2b); // QOIPLANE_DIFF2
                } 
                else
                {
                    outputNibble(0xe); // QOIPLANE_DIRECT
                    outputByte(px);
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



/* Decode a QOI-plane image from memory.

The function either returns null on failure (invalid parameters or malloc 
failed) or a pointer to the decoded pixels. On success, the qoi_desc struct 
is filled with the description from the file header.

The returned pixel data should be free()d after use. */
ubyte* qoiplane_decode(const(ubyte)* data, int size, qoi_desc *desc, int channels) 
{ 
    if ((channels < 0 && channels > 2) ||
            size < QOIX_HEADER_SIZE + cast(int)(qoiplane_padding.sizeof)) 
    {
        return null;
    }

    const(ubyte)* bytes = data;

    int p = 0;

    uint header_magic = qoi_read_32(bytes, &p);
    desc.width = qoi_read_32(bytes, &p);
    desc.height = qoi_read_32(bytes, &p);
    int qoix_version = bytes[p++];
    desc.channels = bytes[p++];
    desc.colorspace = bytes[p++];
    desc.pixelAspectRatio = qoi_read_32f(bytes, &p);
    desc.resolutionY = qoi_read_32f(bytes, &p);

    if (desc.width == 0 || desc.height == 0 || 
        desc.channels < 1 || desc.channels > 2 ||
        desc.colorspace > 1 ||
        qoix_version > 1 ||
        header_magic != QOIX_MAGIC ||
        desc.height >= QOIX_PIXELS_MAX / desc.width
        ) 
    {
        return null;
    }

    if (channels == 0) 
    {
        channels = desc.channels;
    }

    int stride = desc.width * channels;
    desc.pitchBytes = stride; // FUTURE: force to decode with a given layout / image

    int num_pixels = desc.width * desc.height;
    int output_bytes = num_pixels * channels;

    ubyte* pixels = cast(ubyte*) QOI_MALLOC(output_bytes);
    if (!pixels) 
        return null;

    bool readHiNibble = true; // nibble index into output stream.

    ubyte readNibble() nothrow @nogc
    {
        ubyte r;
        if (readHiNibble)
            r = (bytes[p] >>> 4);
        else
            r = (bytes[p++] & 0xf);
        readHiNibble = !readHiNibble;
        assert(r < 16);
        return r;
    }

    ubyte readUbyte()
    {
        ubyte hi = cast(ubyte)(readNibble() << 4);
        ubyte lo = readNibble();
        return hi | lo;
    }

    ubyte px = initialPredictor;

    int decoded_pixels = 0;
    int run = 0;

    for (int posy = 0; posy < desc.height; ++posy)
    {
        ubyte* line = pixels + desc.pitchBytes * posy;
        const(ubyte)* lineAbove = (posy > 0) ? (pixels + desc.pitchBytes * (posy - 1)) : null;

        for (int posx = 0; posx < desc.width; ++posx)
        {
            if (run > 0) 
            {
                run--;
            }
            else if (decoded_pixels < num_pixels)
            {
                ubyte op = readNibble();

                if ((op & 0xc) == 8) // QOIPLANE_REPEAT1
                {
                    run = (op & 0x3);
                }
                else if ((op & 0xf) == 0xf) // QOIPLANE_REPEAT2
                {
                    run = readUbyte() + 4;
                    if (run == 260) 
                        run = 0x7fffffff; // fill with last pixel until end of decode
                }
                else
                {
                    // Compute predictors.
                    ubyte px_ref = px;
                    ubyte px_top = (posy > 0) ? lineAbove[posx] : px_ref;
                    ubyte px_avg = (px_top + px_ref + 1) / 2;

                    if ((op & 0x8) == 0) // QOIPLANE_DIFF1
                    {
                        assert(op < 8);
                        px = cast(ubyte)(px_avg + op - 4);
                    }
                    else if ((op & 0xe) == 0xc) // QOIPLANE_DIFF2
                    {
                        int vg_l = ((op & 1) << 4) + readNibble();
                        assert(vg_l >= 0 && vg_l <= 31);
                        vg_l -= 16;
                        px = cast(ubyte)(px_avg + vg_l);
                    } 
                    else if ((op & 0xf) == 0xe) // QOIPLANE_DIRECT
                    {
                        px = readUbyte();
                    }
                    else
                        assert(false);
                }
                decoded_pixels++;
            }
            line[posx] = px;
        }
    }

    return pixels;
}
