module gamut.codecs.qoi10b;

nothrow @nogc:

import core.stdc.stdlib: realloc, malloc, free;
import core.stdc.string: memset;

import gamut.codecs.qoi2avg;
import inteli.emmintrin;

/// A QOI-inspired codec for 10-bit images, called "QOI-10b". 
/// Input image is 16-bit ushort, but only 10-bits gets encoded making it lossy.
///
///
/// Incompatible adaptation of QOI format - https://phoboslab.org
///
/// -- LICENSE: The MIT License(MIT)
/// Copyright(c) 2021 Dominic Szablewski (original QOI format)
/// Copyright(c) 2022 Guillaume Piolat (QOI-10b variant for 10b images, 1/2/3/4 channels).
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
/// - qoi10b_decode  -- decode the raw bytes of a QOI-10b image from memory
/// - qoi10b_encode  -- encode an rgba buffer into a QOI-10b image in memory
/// 
///
/// A QOI-10b file has a 25 byte header, compatible with Gamut QOIX.
///
/// struct qoix_header_t {
///     char     magic[4];         // magic bytes "qoix"
///     uint32_t width;            // image width in pixels (BE)
///     uint32_t height;           // image height in pixels (BE)
///     uint8_t  version_;         // Major version of QOIX format.
///     uint8_t  channels;         // 1, 2, 3 or 4
///     uint8_t  bitdepth;         // 10 = this QOI-10b codec is always 10-bit (8 would indicate QOI2AVG or QOI-plane)
///     uint8_t  colorspace;       // 0 = sRGB with linear alpha, 1 = all channels linear
///     uint8_t  compression;      // 0 = none, 1 = LZ4
///     float    pixelAspectRatio; // -1 = unknown, else Pixel Aspect Ratio
///     float    resolutionX;      // -1 = unknown, else physical resolution in DPI
/// };
///
/// The decoder and encoder start with {r: 0; g: 0; b: 0; a: 0} as the previous
/// pixel value. Pixels are either encoded as
/// - a run of the previous pixel
/// - a difference to the previous pixel value
/// - full luminance value
///
/// The byte stream's end is marked with 5 0xff bytes.
///
/// This codec is simply like QOI2AVG but with extra 2 bits for each components, and it breaks byte alignment.
///
/// Optimized?    Opcode       Bits(RGB)   Bits(grey)  Meaning
/// [ ]           QOI_OP_LUMA      14           6     0ggggg[rrrrbbbb]  (less g or more g => doesn't work)
/// [ ]           QOI_OP_LUMA0     12           6     10gggg[rrrbbb]
/// [ ]           QOI_OP_LUMA2     22          10     110ggggggg[rrrrrrbbbbbb]
/// [ ]           QOI_OP_LUMA3     30          14     11100ggggggggg[rrrrrrrrbbbbbbbb]
/// [ ]           QOI_OP_ADIFF     10          10     11101xxxxx
/// [x]           QOI_OP_RUN        8           8     11110xxx
///                                16          16     11110111xxxxxxxx
/// [ ]           QOI_OP_ADIFF2    16          16     111110xxxxxxxx 
/// [x]           QOI_OP_GRAY      18          18     11111100gggggggggg
/// [ ]           QOI_OP_RGB       38          18     11111101rrrrrrrrrr[ggggggggggbbbbbbbbbb]
/// [ ]           QOI_OP_RGBA      48          28     11111110rrrrrrrrrr[ggggggggggbbbbbbbbbb]aaaaaaaaaa
/// [ ]           QOI_OP_END        8           8     11111111

// Note: LOCO-I predictor doesn't really work here, it slowdown quite a bit for 0.5% bitrate improvement.
//       Not sure what happens here.

enum ubyte QOI_OP_ADIFF2 = 0xf8;

enum int WORST_OPCODE_BITS = 48;

enum enableAveragePrediction = true; 

enum bool newpred = false;//true;

static immutable ubyte[5] qoi10b_padding = [255,255,255,255,255];

enum qoi10_rgba_t initialPredictor = { r:0, g:0, b:0, a:1023 };

struct qoi10_rgba_t 
{   
    // 0 to 1023 values
    ushort r;
    ushort g;
    ushort b;
    ushort a;
}

uint QOI10b_COLOR_HASH(qoi10_rgba_t C)
{
    long colorAsLong = *(cast(long*)&C);
    return (((colorAsLong * 2654435769) >> 22) & 1023);
}

/* Encode raw RGBA16 pixels into a QOI-10b image in memory.
This immediately loosen precision from 16-bit t 10-bit, so this is lossy.
The function either returns null on failure (invalid parameters or malloc 
failed) or a pointer to the encoded data on success. On success the out_len 
is set to the size in bytes of the encoded data.
The returned qoi data should be free()d after use. */
version(encodeQOIX)
ubyte* qoi10b_encode(const(ubyte)* data, const(qoi_desc)* desc, int *out_len) 
{
    if ( (desc.channels != 1 && desc.channels != 2 && desc.channels != 3 && desc.channels != 4) ||
        desc.height >= QOIX_PIXELS_MAX / desc.width || desc.compression != QOIX_COMPRESSION_NONE
    ) {
        return null;
    }

    if (desc.bitdepth != 10)
        return null;

    int channels = desc.channels;

    // At worst, each pixel take 38 bit to be encoded.
    int num_pixels = desc.width * desc.height;

   int scanline_size = cast(int)(qoi10_rgba_t.sizeof) * desc.width;

    int max_size = cast(int) (cast(long)num_pixels * WORST_OPCODE_BITS + 7) / 8 + QOIX_HEADER_SIZE + cast(int)(qoi10b_padding.sizeof);

    ubyte* stream;

    int p = 0; // write index into output stream
    ubyte* bytes = cast(ubyte*) QOI_MALLOC(max_size + 2 * scanline_size);
    if (!bytes) 
    {
        return null;
    }

    qoi_write_32(bytes, &p, QOIX_MAGIC);
    qoi_write_32(bytes, &p, desc.width);
    qoi_write_32(bytes, &p, desc.height);
    bytes[p++] = 1; // Put a version number :)
    bytes[p++] = desc.channels; // 1, 2, 3 or 4
    bytes[p++] = desc.bitdepth; // 10
    bytes[p++] = desc.colorspace;
    bytes[p++] = QOIX_COMPRESSION_NONE;
    qoi_write_32f(bytes, &p, desc.pixelAspectRatio);
    qoi_write_32f(bytes, &p, desc.resolutionY);

    int currentBit = 7; // beginning of a byte
    bytes[p] = 0;

    // write the nbits last bits of x, starting from the highest one
    void outputBits(uint x, int nbits) nothrow @nogc
    {
        assert(nbits >= 2 && nbits <= 16);
        assert( (nbits % 2) == 0);

        for (int b = nbits - 2; b >= 0; b -= 2)
        {
            // which bit to write
            ubyte pairOfBits = (x >>> b) & 3;
            bytes[p] |= (pairOfBits << (currentBit - 1));

            currentBit -= 2;

            if (currentBit == -1)
            {
                p++;
                bytes[p] = 0;
                currentBit = 7;
            }
        }
    }

    void outputByte(ubyte b)
    {
        outputBits(b, 8);
    }

    qoi10_rgba_t px = initialPredictor;
    qoi10_rgba_t px_ref = initialPredictor;

    // To serve as predictor
    qoi10_rgba_t* scanlineConverted     = cast(qoi10_rgba_t*)(&bytes[max_size]);
    qoi10_rgba_t* lastScanlineConverted = cast(qoi10_rgba_t*)(&bytes[max_size + scanline_size]);

    ubyte[1024] index_lookup;
    uint index_pos = 0;
    
    
    index_lookup[] = 0;

    bool streamIsGrey = (channels == 1 || channels == 2);
    int run = 0;
    int encoded_pixels = 0;

    void encodeRun()
    {
        assert(run > 0 && run <= 256);
        run--;
        if (run < 7) 
        {
            outputByte( cast(ubyte)(QOI_OP_RUN | run) ); // run 1 to 7
        }
        else 
        {
            outputByte( cast(ubyte)(QOI_OP_RUN | 7) ); // QOI_OP_RUN2 is inside the QOI_OP_RUN
            outputBits(run - 7, 8);
        }
        run = 0;
    }
    
    for (int posy = 0; posy < desc.height; ++posy)
    {
        {
            const(ushort)* line = cast(const(ushort*))(data + desc.pitchBytes * posy);
   
            // 1. First convert the scanline to full qoi10_rgba_t to serve as predictor.

            for (int posx = 0; posx < desc.width; ++posx)
            {
                qoi10_rgba_t pixel;

                // Note that we drop six lower bits here. This codec is lossy 
                // if you really have more than 10-bits of precision.
                // The use case is PBR knob in Dplug, who needs 10-bit (presumably) for the elevation map.
                switch(channels)
                {
                    default:
                    case 4:
                        pixel.r = line[posx * channels + 0];
                        pixel.g = line[posx * channels + 1];
                        pixel.b = line[posx * channels + 2];
                        pixel.a = line[posx * channels + 3];
                        break;
                    case 3:
                        pixel.r = line[posx * channels + 0];
                        pixel.g = line[posx * channels + 1];
                        pixel.b = line[posx * channels + 2];
                        pixel.a = 65535;
                        break;
                    case 2:
                        pixel.r = line[posx * channels + 0];
                        pixel.g = pixel.r;
                        pixel.b = pixel.r;
                        pixel.a = line[posx * channels + 1];
                        break;
                    case 1:
                        pixel.r = line[posx * channels + 0];
                        pixel.g = pixel.r;
                        pixel.b = pixel.r;
                        pixel.a = 65535;
                        break;
                }

                pixel.r = pixel.r >>> 6;
                pixel.g = pixel.g >>> 6;
                pixel.b = pixel.b >>> 6;
                pixel.a = pixel.a >>> 6;

                assert(pixel.r <= 1023);
                assert(pixel.g <= 1023);
                assert(pixel.b <= 1023);
                assert(pixel.a <= 1023);

                scanlineConverted[posx] = pixel; // Note: if we'd like lossy, this would be the reconstructed buffer.
            }
        }

        for (int posx = 0; posx < desc.width; ++posx)
        {
            px_ref = px;

            px = scanlineConverted[posx];

            if (px == px_ref) 
            {
                run++;
                if (run == 256 || encoded_pixels + 1 == num_pixels)
                    encodeRun();
            }
            else 
            {
                if (run > 0) 
                    encodeRun();

                {
                    int va = (px.a - px_ref.a) & 1023;
                    if (va) 
                    {
                        if (va < 16 || va >= (1024 - 16)) // does it fit on 5 bits?
                        {
                            // it fits on 5 bits
                            outputBits((0x1d << 5) | (va & 0x1f), 10); // QOI_OP_ADIFF
                        }
                        else if (va < 128 || va >= (1024 - 128)) // does it fit on 8 bits?
                        {
                            outputBits( (QOI_OP_ADIFF2 >>> 2), 6);
                            outputBits(va, 8);  
                        }
                        else
                        {
                            outputByte(QOI_OP_RGBA);
                            outputBits(px.r, 10);
                            if (!streamIsGrey)
                            {
                                outputBits(px.g, 10);
                                outputBits(px.b, 10);
                            }
                            outputBits(px.a, 10);
                            goto pixel_is_encoded;
                        }
                    }

                    if (posy > 0 && enableAveragePrediction)
                    {
                        static if (newpred)
                        {
                            if (posx == 0)
                            {
                                // first pixel in the row, take above pixel
                                px_ref.r = lastScanlineConverted[posx].r;
                                px_ref.g = lastScanlineConverted[posx].g;
                                px_ref.b = lastScanlineConverted[posx].b;
                            }
                            else 
                            {
                                qoi10_rgba_t pred = locoIntraPredictionSIMD(px_ref, lastScanlineConverted[posx], lastScanlineConverted[posx-1]);
                                px_ref.r = pred.r;
                                px_ref.g = pred.g;
                                px_ref.b = pred.b;
                            }
                        }
                        else
                        {
                            px_ref.r = (px_ref.r + lastScanlineConverted[posx].r + 1) >> 1;
                            px_ref.g = (px_ref.g + lastScanlineConverted[posx].g + 1) >> 1;
                            px_ref.b = (px_ref.b + lastScanlineConverted[posx].b + 1) >> 1;
                        }
                    }

                    int vg   = (px.g - px_ref.g) & 1023;
                    int vg_r = (px.r - px_ref.r - vg) & 1023;
                    int vg_b = (px.b - px_ref.b - vg) & 1023;

                    if (streamIsGrey)
                    {
                        assert(vg_r == 0);
                        assert(vg_b == 0);
                    }


                    if ( ( (vg_r >= (1024- 4)) || (vg_r <  4) ) &&  // fits in 3 bits?
                         ( (vg   >= (1024-8)) || (vg   < 8) ) &&    // fits in 4 bits?
                        ( (vg_b >= (1024- 4)) || (vg_b <  4) ) )   // fits in 3 bits?
                    {
                        outputBits(0x20 | (vg & 0x0f), 6); // QOI_OP_LUMA0
                        if (!streamIsGrey)
                        {
                            outputBits( (vg_r << 3) | (vg_b & 7), 6);
                        }
                    }
                    else if ( ( (vg_r >= (1024- 8)) || (vg_r <  8) ) &&  // fits in 4 bits?
                         ( (vg   >= (1024-16)) || (vg   < 16) ) &&  // fits in 5 bits?
                         ( (vg_b >= (1024- 8)) || (vg_b <  8) ) )   // fits in 4 bits?
                    {
                        outputBits(vg & 0x1f, 6); // QOI_OP_LUMA
                        if (!streamIsGrey)
                        {
                            outputBits(vg_r, 4);
                            outputBits(vg_b, 4);
                        }
                    }
                    else if (!streamIsGrey && px.g == px.r && px.g == px.b) 
                    {  
                        // Note: in greyscale, more expensive than QOI_OP_LUMA2
                        // This opcode should not be used if input is grey.
                        outputByte(QOI_OP_GRAY);
                        outputBits(px.g, 10);
                    }
                    else
                    if ( ( (vg_r >= (1024-32)) || (vg_r < 32) ) &&  // fits in 6 bits?
                         ( (vg   >= (1024-64)) || (vg   < 64) ) &&  // fits in 7 bits?
                         ( (vg_b >= (1024-32)) || (vg_b < 32) ) )   // fits in 6 bits?
                    {
                        outputBits((0x6 << 7) | (vg & 0x7f), 10); // QOI_OP_LUMA2
                        if (!streamIsGrey)
                        {
                            outputBits(vg_r, 6);
                            outputBits(vg_b, 6);
                        }
                    } 
                    else
                    if ( ( (vg_r >= (1024-128)) || (vg_r < 128) ) && // fits in 8 bits?
                         ( (vg   >= (1024-256)) || (vg   < 256) ) && // fits in 9 bits?
                         ( (vg_b >= (1024-128)) || (vg_b < 128) ) )   // fits in 8 bits?
                    {
                        outputBits((0x1c << 9) | (vg & 0x1ff), 14); // QOI_OP_LUMA3
                        if (!streamIsGrey)
                        {
                            outputBits(vg_r, 8);
                            outputBits(vg_b, 8);
                        }
                    } 
                    else
                    {
                        outputByte(QOI_OP_RGB);
                        outputBits(px.r, 10);
                        if (!streamIsGrey)
                        {
                            outputBits(px.g, 10);
                            outputBits(px.b, 10);
                        }
                    }
                }
            }

            pixel_is_encoded:

            encoded_pixels++;
        }

        // Exchange scanline pointers
        {
            qoi10_rgba_t* temp = scanlineConverted;
            scanlineConverted = lastScanlineConverted;
            lastScanlineConverted = temp;
        }
    }

    for (int i = 0; i < cast(int)(qoi10b_padding.sizeof); i++) 
    {
        outputByte(qoi10b_padding[i]);
    }

    // finish the last byte
    if (currentBit != 7)
        outputBits(0xff, currentBit + 1);
    assert(currentBit == 7); // full byte

    *out_len = p;
    return bytes;
}

/* Decode a QOI-10b image from memory.

The function either returns null on failure (invalid parameters or malloc 
failed) or a pointer to the decoded 16-bit pixels. On success, the qoi_desc struct 
is filled with the description from the file header.

The returned pixel data should be free()d after use. */
version(decodeQOIX)
ubyte* qoi10b_decode(const(void)* data, int size, qoi_desc *desc, int channels) 
{
    const(ubyte)* bytes;
    uint header_magic;

    int p = 0, run = 0;

    if (data == null || desc == null ||
        (channels < 0 || channels > 4) ||
            size < QOIX_HEADER_SIZE + cast(int)(qoi10b_padding.sizeof)
                )
    {
        return null;
    }

    bytes = cast(const(ubyte)*)data;

    header_magic = qoi_read_32(bytes, &p);
    desc.width = qoi_read_32(bytes, &p);
    desc.height = qoi_read_32(bytes, &p);
    int qoix_version = bytes[p++];
    desc.channels = bytes[p++];
    desc.bitdepth = bytes[p++];
    desc.colorspace = bytes[p++];
    desc.compression = bytes[p++];
    desc.pixelAspectRatio = qoi_read_32f(bytes, &p);
    desc.resolutionY = qoi_read_32f(bytes, &p);

    if (desc.width == 0 || desc.height == 0 || 
        desc.channels < 1 || desc.channels > 4 ||
        desc.colorspace > 1 ||
        desc.bitdepth != 10 ||
        qoix_version > 1 ||
        desc.compression != QOIX_COMPRESSION_NONE ||
        header_magic != QOIX_MAGIC ||
        desc.height >= QOIX_PIXELS_MAX / desc.width
        ) 
    {
        return null;
    }

    int streamChannels = desc.channels;

    if (channels == 0)
        channels = streamChannels;

    int stride = desc.width * channels * 2;
    desc.pitchBytes = stride;         

    int pixel_data_size = stride * desc.height;
    int decoded_scanline_size = desc.width * cast(int)qoi10_rgba_t.sizeof;

    ubyte* pixels = cast(ubyte*) QOI_MALLOC(pixel_data_size + 2 * decoded_scanline_size);
    if (!pixels) {
        return null;
    }

    // double-buffered scanline, for correct average predictors
    // (else we can't decode 4/3 channels to 1/2 with average prediction, the predictors would be wrong
    //  if taken from the decoded output)
    qoi10_rgba_t* decodedScanline = cast(qoi10_rgba_t*)(&pixels[pixel_data_size]);
    qoi10_rgba_t* lastDecodedScanline = cast(qoi10_rgba_t*)(&pixels[pixel_data_size + decoded_scanline_size]);

    assert(channels >= 1 && channels <= 4);

    int currentBit = 7;

    void rewindInputBit() nothrow @nogc
    {
        if (currentBit == 7)
        {
            p--;
            currentBit = -1;
        }
        currentBit++;
    }

    int read2Bits() nothrow @nogc
    {
        ubyte bb = bytes[p];

        int bit = (bytes[p] >>> (currentBit - 1)) & 3;

        currentBit -= 2;
        if (currentBit == -1)
        {
            currentBit = 7;
            p++;
        }
        return bit;
    }

    uint readBits(int nbits) nothrow @nogc
    {
        assert(nbits % 2 == 0);
        uint r = 0;
        for (int b = 0; b < nbits; b += 2)
        {
            r = (r << 2) | read2Bits();
        }
        return r;
    }

    ubyte readByte() nothrow @nogc
    {
        return cast(ubyte) readBits(8);
    }

    bool streamIsGrey = (streamChannels == 1 || streamChannels == 2);

    qoi10_rgba_t px = initialPredictor;
    qoi10_rgba_t px_ref = initialPredictor;

    int decoded_pixels = 0;
    int num_pixels = desc.width * desc.height;

    for (int posy = 0; posy < desc.height; ++posy)
    {
        for (int posx = 0; posx < desc.width; ++posx)
        {
            px_ref = px;

            if (run > 0) 
            {
                run--;
            }
            else if (decoded_pixels < num_pixels)
            {
                // Compute averaged predictors then

                if (posy > 0 && enableAveragePrediction)
                {
                    static if (newpred)
                    {
                        if (posx == 0)
                        {
                            // first pixel in the row, take above pixel
                            px_ref.r = lastDecodedScanline[posx].r;
                            px_ref.g = lastDecodedScanline[posx].g;
                            px_ref.b = lastDecodedScanline[posx].b;
                        }
                        else 
                        {
                            qoi10_rgba_t pred = locoIntraPredictionSIMD(px_ref, lastDecodedScanline[posx], lastDecodedScanline[posx-1]);
                            px_ref.r = pred.r;
                            px_ref.g = pred.g;
                            px_ref.b = pred.b;
                        }
                    }
                    else
                    {
                        px_ref.r = (px_ref.r + lastDecodedScanline[posx].r + 1) >> 1;
                        px_ref.g = (px_ref.g + lastDecodedScanline[posx].g + 1) >> 1;
                        px_ref.b = (px_ref.b + lastDecodedScanline[posx].b + 1) >> 1;
                    }
                }

                decode_next_op:

                ubyte op = readByte();

                if (op < 0x80)              // QOI_OP_LUMA
                {
                    int vg = (op >> 2) & 31;  // vg is a signed 5-bit number
                    vg = (vg << 27) >> 27;   // extends sign
                    px.g = (px_ref.g + vg       ) & 1023;

                    if (!streamIsGrey)
                    {
                        int vg_r = ((op & 3) << 2) | readBits(2); // vg_r and vg_b are signed 4-bit number in the stream
                        vg_r = (vg_r << 28) >> 28;   // extends sign    
                        int vg_b = cast(int)(readBits(4) << 28) >> 28;
                        px.r = (px_ref.r + vg + vg_r) & 1023;
                        px.b = (px_ref.b + vg + vg_b) & 1023;
                    }
                    else
                    {
                        // Rewind two bits, this is always possible
                        rewindInputBit();
                        rewindInputBit();
                        px.r = px.g;
                        px.b = px.g;
                    }
                }
                else if (op < 0xc0)    // QOI_OP_LUMA0 10xxxx
                {
                    // 10gggg[rrrggg]

                    int vg = (op >> 2) & 15;  // vg is a signed 4-bit number
                    vg = (vg << 28) >> 28;   // extends sign
                    px.g = (px_ref.g + vg       ) & 1023;
                    if (!streamIsGrey)
                    {
                        uint remain = readBits(4);
                        int vg_r = ((op & 3) << 1) | (remain >> 3);
                        int vg_b = remain & 7;
                        vg_r = (vg_r << 29) >> 29;
                        vg_b = (vg_b << 29) >> 29;
                        px.r = (px_ref.r + vg + vg_r) & 1023;
                        px.b = (px_ref.b + vg + vg_b) & 1023;
                    }
                    else
                    {
                        // Rewind two bits, this is always possible
                        rewindInputBit();
                        rewindInputBit();
                        px.r = px.g;
                        px.b = px.g;
                    }
                }
                else if (op < 0xe0)    // QOI_OP_LUMA2
                {
                    int vg   = ((op & 31) << 2) | readBits(2); // vg is a signed 7-bit number
                    vg = (vg << 25) >> 25;                     // extends sign
                    px.g = (px_ref.g + vg       ) & 1023;
                    if (!streamIsGrey)
                    {
                        int vg_r = cast(int)(readBits(6) << 26) >> 26; // vg_r and vg_b are signed 6-bit number in the stream
                        int vg_b = cast(int)(readBits(6) << 26) >> 26;
                        px.r = (px_ref.r + vg + vg_r) & 1023;
                        px.b = (px_ref.b + vg + vg_b) & 1023;
                    }
                    else
                    {
                        px.r = px.g;
                        px.b = px.g;
                    }
                }
                else if (op < 0xe8)    // QOI_OP_LUMA3
                {
                    int vg   = ((op & 7) << 6) | readBits(6); // vg is a signed 9-bit number
                    vg = (vg << 23) >> 23;                    // extends sign
                    px.g = (px_ref.g + vg       ) & 1023;
                    if (!streamIsGrey)
                    {
                        int vg_r = cast(int)(readBits(8) << 24) >> 24; // vg_r and vg_b are signed 8-bit number in the stream
                        int vg_b = cast(int)(readBits(8) << 24) >> 24;
                        px.r = (px_ref.r + vg + vg_r) & 1023;
                        px.b = (px_ref.b + vg + vg_b) & 1023;
                    }
                    else
                    {
                        px.r = px.g;
                        px.b = px.g;
                    }
                }  
                else if (op < 0xf0)    // QOI_OP_ADIFF
                {
                    int adiff = ((op & 7) << 2) | readBits(2);
                    adiff = adiff << 27; // Need sign extension, else the negatives aren't negatives.
                    adiff = adiff >> 27;
                    px.a = cast(ushort)((px.a + adiff) & 1023);
                    goto decode_next_op;
                }
                else if ((op & 0xfc) == QOI_OP_ADIFF2)
                {
                    int adiff = ((op & 3) << 6) | readBits(6);
                    adiff = (adiff << 24) >> 24; // sign-extend
                    px.a = cast(ushort)((px.a + adiff) & 1023);
                    goto decode_next_op;
                }
                else if (op < 0xf8) // QOI_OP_RUN
                {       
                    run = op & 7;
                    if (run == 7)
                    {
                        run = readBits(8) + 7;
                    }
                }               
                else if (op == QOI_OP_RGB)
                {
                    px.r = cast(ushort) readBits(10);
                    if (!streamIsGrey)
                    {
                        px.g = cast(ushort) readBits(10);
                        px.b = cast(ushort) readBits(10);
                    }
                    else
                    {
                        px.g = px.r;
                        px.b = px.r;
                    }
               }
                else if (op == QOI_OP_RGBA)
                {
                    px.r = cast(ushort) readBits(10);
                    if (!streamIsGrey)
                    {
                        px.g = cast(ushort) readBits(10);
                        px.b = cast(ushort) readBits(10);
                    }
                    else
                    {
                        px.g = px.r;
                        px.b = px.r;
                    }
                    px.a = cast(ushort) readBits(10);
                }
                else if (op == QOI_OP_GRAY)
                {
                    px.r = cast(ushort) readBits(10);
                    px.g = px.r;
                    px.b = px.r;
                }                    
                else if (op == QOI_OP_END)
                {
                    goto finished;
                }
                else
                {
                    assert(false);
                }
            }

            decodedScanline[posx] = px;
            decoded_pixels++;
        }

        // convert just-decoded scanline into output type
        ushort* line      = cast(ushort*)(pixels + desc.pitchBytes * posy);

        // PERF: can be 4 different loops here?
        for (int posx = 0; posx < desc.width; ++posx)
        {
            qoi10_rgba_t px16b = decodedScanline[posx]; // 0..1023 components
            px16b.r = cast(ushort)(px16b.r << 6 | (px16b.r >> 4));
            px16b.g = cast(ushort)(px16b.g << 6 | (px16b.g >> 4));
            px16b.b = cast(ushort)(px16b.b << 6 | (px16b.b >> 4));
            px16b.a = cast(ushort)(px16b.a << 6 | (px16b.a >> 4));

            // Expand 10 bit to 16-bits
            switch(channels)
            {
                default:
                case 4:
                    line[posx * channels + 0] = px16b.r;
                    line[posx * channels + 1] = px16b.g;
                    line[posx * channels + 2] = px16b.b;
                    line[posx * channels + 3] = px16b.a;
                    break;
                case 3:
                    line[posx * channels + 0] = px16b.r;
                    line[posx * channels + 1] = px16b.g;
                    line[posx * channels + 2] = px16b.b;
                    break;
                case 2:
                    line[posx * channels + 0] = px16b.r;
                    line[posx * channels + 1] = px16b.a;
                    break;
                case 1:
                    line[posx * channels + 0] = px16b.r;
                    break;
            }
        }

        // swap decoded scanline buffers
        {
            qoi10_rgba_t* temp = decodedScanline;
            decodedScanline = lastDecodedScanline;
            lastDecodedScanline = temp;
        }
    }

    finished:
    return pixels;
}

static qoi10_rgba_t locoIntraPredictionSIMD(qoi10_rgba_t a, qoi10_rgba_t b, qoi10_rgba_t c)
{
    // load RGBA16 pixels
    __m128i A = _mm_loadu_si64(&a); 
    __m128i B = _mm_loadu_si64(&b);
    __m128i C = _mm_loadu_si64(&c);

    // Max predictor (A + B - C)
    __m128i P = _mm_sub_epi16(_mm_add_epi16(A, B), C);
    __m128i maxAB = _mm_max_epi16(A, B);
    __m128i minAB = _mm_min_epi16(A, B);

    // 1111 where we should use max(A, B)
    __m128i maxMask = _mm_cmple_epi16(C, minAB);

    // 1111 where we should use min(A, B)
    __m128i minMask = _mm_cmpge_epi16(C, maxAB);

    P = (P & (~minMask)) | (minAB & minMask);
    P = (P & (~maxMask)) | (maxAB & maxMask);

    // Get back to 10-bit, clip

    __m128i Z = _mm_setzero_si128();
    __m128i m1023 = _mm_set1_epi16(1023);
    P = _mm_max_epi16(P, Z);
    P = _mm_min_epi16(P, m1023);

    qoi10_rgba_t r;
    _mm_storel_epi64(cast(__m128i*)&r, P);

    return r;
}

/+
static short locoIntraPrediction(short a, short b, short c)
{
    short max_ab = a > b ? a : b;
    short min_ab = a < b ? a : b;
    if (c >= max_ab)
        return cast(short)min_ab;
    else if (c <= min_ab)
        return cast(short)max_ab;
    else
    {
        int d = a + b - c;
        if (d < 0)
            d = 0;
        if (d > 1023)
            d = 1023;
        return cast(short)d;
    }
}
+/

private __m128i _mm_cmple_epi16(__m128i a, __m128i b) pure @safe
{
    return _mm_or_si128(_mm_cmplt_epi16(a, b), _mm_cmpeq_epi16(a, b));
}

private __m128i _mm_cmpge_epi16(__m128i a, __m128i b)
{
    return _mm_or_si128(_mm_cmpgt_epi16(a, b), _mm_cmpeq_epi16(a, b));
}