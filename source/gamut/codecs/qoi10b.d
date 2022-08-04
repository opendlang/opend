module gamut.codecs.qoi10b;

nothrow @nogc:

import core.stdc.stdlib: realloc, malloc, free;
import core.stdc.string: memset;

import gamut.codecs.qoi2avg;

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
/// A QOI-Plane file has a 24 byte header, compatible with Gamut QOIX.
///
/// struct qoi_header_t {
///     char     magic[4];         // magic bytes "qoix"
///     uint32_t width;            // image width in pixels (BE)
///     uint32_t height;           // image height in pixels (BE)
///     uint8_t  version_;         // Major version of QOIX format.
///     uint8_t  channels;         // 1, 2, 3 or 4
///     uint8_t  bitdepth;         // 10 = this QOI-10b codec is always 10-bit (8 would indicate QOI2AVG or QOI-plane)
///     uint8_t  colorspace;       // 0 = sRGB with linear alpha, 1 = all channels linear
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
/// Opcode       Bits   Meaning
/// QOI_OP_LUMA    14   0gggggrrrrbbbb
/// QOI_OP_INDEX    8   10xxxxxx
/// QOI_OP_LUMA2   22   110gggggggrrrrrrbbbbbb
/// QOI_OP_LUMA3   30   11100gggggggggrrrrrrrrbbbbbbbb
/// QOI_OP_ADIFF   10   11101xxxxx
/// QOI_OP_RUN      8   11110xxx
/// QOI_OP_RUN2    16   111110xxxxxxxxxx
/// QOI_OP_GRAY    18   11111100gggggggggg
/// QOI_OP_RGB     38   11111101rrrrrrrrrrggggggggggbbbbbbbbbb
/// QOI_OP_RGBA    48   11111110rrrrrrrrrrggggggggggbbbbbbbbbbaaaaaaaaaa
/// QOI_OP_END      8   11111111

enum int WORST_OPCODE_BITS = 48;

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
ubyte* qoi10b_encode(const(ubyte)* data, const(qoi_desc)* desc, int *out_len) 
{
    if ( (desc.channels != 1 && desc.channels != 2 && desc.channels != 3 && desc.channels != 4) ||
        desc.height >= QOIX_PIXELS_MAX / desc.width
    ) {
        return null;
    }

    if (desc.bitdepth != 10)
        return null;

    int channels = desc.channels;

    // At worst, each pixel take 38 bit to be encoded.
    int num_pixels = desc.width * desc.height;

    int max_size = cast(int) (cast(long)num_pixels * WORST_OPCODE_BITS + 7) / 8 + QOIX_HEADER_SIZE + cast(int)(qoi10b_padding.sizeof);

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
    bytes[p++] = desc.channels; // 1, 2, 3 or 4
    bytes[p++] = desc.bitdepth; // 10
    bytes[p++] = desc.colorspace;
    qoi_write_32f(bytes, &p, desc.pixelAspectRatio);
    qoi_write_32f(bytes, &p, desc.resolutionY);

    int currentBit = 7;
    bytes[p] = 0;

    // write the nbits last bits of x, starting from the highest one
    void outputBits(uint x, int nbits) nothrow @nogc
    {
        assert(nbits >= 1 && nbits <= 10);

        for (int b = nbits - 1; b >= 0; --b)
        {
            // which bit to write
            ubyte bit = (x >>> b) & 1;
            bytes[p] |= (bit << currentBit);

            currentBit--;

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

    void encodeRun(ref int run) nothrow @nogc
    {
        assert(false); // TODO
    }

    qoi10_rgba_t px = initialPredictor;
    qoi10_rgba_t px_ref = initialPredictor;

    ubyte[1024] index_lookup;
    uint index_pos = 0;
    qoi10_rgba_t[64] index;
    memset(index.ptr, 0, 64 * qoi10_rgba_t.sizeof);
    index_lookup[] = 0;

    int run = 0;
    int px_pos = 0;
    int px_end = channels * desc.width * desc.height;

    for (int posy = 0; posy < desc.height; ++posy)
    {
        const(ushort)* line = cast(const(ushort*))(data + desc.pitchBytes * posy);
        const(ushort)* lineAbove = (posy > 0) ? cast(const(ushort*))(data + desc.pitchBytes * (posy - 1)) : null;

        for (int posx = 0; posx < desc.width; ++posx)
        {
            px_ref = px;

            // Note that we drop six lower bits here. This codec is lossy if you really have more than 10-bits of precision.
            switch(channels)
            {
                default:
                case 4:
                    px.r = line[posx * channels + 0];
                    px.g = line[posx * channels + 1];
                    px.b = line[posx * channels + 2];
                    px.a = line[posx * channels + 3];
                    break;
                case 3:
                    px.r = line[posx * channels + 0];
                    px.g = line[posx * channels + 1];
                    px.b = line[posx * channels + 2];
                    px.a = 65535;
                    break;
                case 2:
                    px.r = line[posx * channels + 0];
                    px.g = px.r;
                    px.b = px.r;
                    px.a = line[posx * channels + 1];
                    break;
                case 1:
                    px.r = line[posx * channels + 0];
                    px.g = px.r;
                    px.b = px.r;
                    px.a = 65535;
                    break;
            }
            px.r = px.r >>> 6;
            px.g = px.g >>> 6;
            px.b = px.b >>> 6;
            px.a = px.a >>> 6;

            assert(px.r <= 1023);
            assert(px.g <= 1023);
            assert(px.b <= 1023);
            assert(px.a <= 1023);

            outputByte(QOI_OP_RGBA);
            outputBits(px.r, 10);
            outputBits(px.g, 10);
            outputBits(px.b, 10);
            outputBits(px.a, 10);
        }
    }


          /*  if (px == px_ref) {
                run++;
                if (run == 1024 || px_pos == px_end) {
                    run--;
                    outputByte( QOI_OP_RUN2 | ((run >> 8) & 3) );
                    outputByte( run & 0xff );
                    run = 0;
                }
            }
            else {
                int hash = QOI10b_COLOR_HASH(px);

                if (run > 0) {
                    run--;
                    if (run < 8) {
                        outputByte( cast(ubyte)(QOI_OP_RUN | run) );
                    }
                    else {
                        outputByte( QOI_OP_RUN2 | ((run >> 8) & 3) );
                        outputByte( run & 0xff );
                    }
                    run = 0;
                }

                if (index[index_lookup[hash]] == px) {
                    bytes[p++] = QOI_OP_INDEX | index_lookup[hash];
                }
                else {
                    index_lookup[hash] = cast(ubyte) index_pos;
                    index[index_pos] = px;
                    index_pos = (index_pos + 1) & 63;

                    short va = (px.a - px_ref.a) & 1023;

           /*         if (va) {
                        if (va >= -4 && va <= 3){
                            bytes[p++] = cast(ubyte)(QOI_OP_ADIFF | (va + 4));
                        } else { 
             */               
   /*                 outputByte(QOI_OP_RGBA);
                    outputBits(px.r, 10);
                    outputBits(px.g, 10);
                    outputBits(px.b, 10);
                    outputBits(px.a, 10); */
        //            continue;
               //         }
                 //   }
/+
                    if (px_pos >= stride)  // ????? doesn't seem OK, TODO
                    {
                        px_ref.rgba.r = (px_ref.rgba.r + lineAbove[posx * channels + 0] + 1) >> 1;
                        px_ref.rgba.g = (px_ref.rgba.g + lineAbove[posx * channels + 1] + 1) >> 1;
                        px_ref.rgba.b = (px_ref.rgba.b + lineAbove[posx * channels + 2] + 1) >> 1;                     
                    }

                    byte vg   = cast(byte)(px.rgba.g - px_ref.rgba.g);
                    byte vg_r = cast(byte)(px.rgba.r - px_ref.rgba.r - vg);
                    byte vg_b = cast(byte)(px.rgba.b - px_ref.rgba.b - vg);

                    if (
                        vg   >= -4 && vg   <  0 && 
                        vg_r >= -1 && vg_r <= 2 &&
                        vg_b >= -1 && vg_b <= 2
                        ) {
                            bytes[p++] = cast(ubyte)( QOI_OP_LUMA | (vg + 4) << 4 | (vg_r + 1) << 2 | (vg_b + 1) );
                        }
                    else if (
                             vg   >=  0 && vg   <= 3 && 
                             vg_r >= -2 && vg_r <= 1 &&
                             vg_b >= -2 && vg_b <= 1
                             ) {
                                bytes[p++] = cast(ubyte)( QOI_OP_LUMA | (vg + 4) << 4 | (vg_r + 2) << 2 | (vg_b + 2) );
                             }
                    else if (
                             px.rgba.g == px.rgba.r &&
                             px.rgba.g == px.rgba.b
                             ) {
                                bytes[p++] = QOI_OP_GRAY;
                                bytes[p++] = px.rgba.g;
                             }
                    else if (
                             vg_r >=  -8 && vg_r <=  7 && 
                             vg   >= -16 && vg   <= 15 && 
                             vg_b >=  -8 && vg_b <=  7
                             ) {
                                bytes[p++] = cast(ubyte)( QOI_OP_LUMA2    | (vg   + 16) );
                                bytes[p++] = cast(ubyte)( (vg_r + 8) << 4 | (vg_b +  8) );
                             }
                    else if (
                             vg_r >= -32 && vg_r <= 31 && 
                             vg   >= -64 && vg   <= 63 && 
                             vg_b >= -32 && vg_b <= 31
                             ) {
                                int dv = ((vg + 64) << 12) | ((vg_r + 32) << 6) | (vg_b + 32);
                                bytes[p++] = QOI_OP_LUMA3 | ((dv >> 16) & 31);
                                bytes[p++] = (dv >> 8) & 255;
                                bytes[p++] = dv & 255;
                             } else {
                                bytes[p++] = QOI_OP_RGB;
                                bytes[p++] = px.rgba.r;
                                bytes[p++] = px.rgba.g;
                                bytes[p++] = px.rgba.b;
                             } +/
        //        }
      //      }

  /*          px_pos += channels;
        }
    } */

    for (int i = 0; i < cast(int)(qoi10b_padding.sizeof); i++) 
    {
        outputByte(qoi10b_padding[i]);
    }

    // finish the last byte
    if (currentBit != 7)
        outputBits(0xff, 7 - currentBit);
    assert(currentBit == 7); // full byte

    *out_len = p;
    return bytes;
}

/* Decode a QOI-10b image from memory.

The function either returns null on failure (invalid parameters or malloc 
failed) or a pointer to the decoded 16-bit pixels. On success, the qoi_desc struct 
is filled with the description from the file header.

The returned pixel data should be free()d after use. */
ubyte* qoi10b_decode(const(void)* data, int size, qoi_desc *desc, int channels) 
{
    const(ubyte)* bytes;
    uint header_magic;
    
    qoi10_rgba_t[64] index;
    
    int p = 0, run = 0;
    int index_pos = 0;

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
    desc.pixelAspectRatio = qoi_read_32f(bytes, &p);
    desc.resolutionY = qoi_read_32f(bytes, &p);

    if (desc.width == 0 || desc.height == 0 || 
        desc.channels < 1 || desc.channels > 4 ||
        desc.colorspace > 1 ||
        desc.bitdepth != 10 ||
        qoix_version > 1 ||
        header_magic != QOIX_MAGIC ||
        desc.height >= QOIX_PIXELS_MAX / desc.width
        ) 
    {
        return null;
    }

    if (channels == 0)
        channels = desc.channels;

    int stride = desc.width * channels * 2;
    desc.pitchBytes = stride;         

    int sizeInBytes = stride * desc.height;

    ubyte* pixels = cast(ubyte*) QOI_MALLOC(sizeInBytes);
    if (!pixels) {
        return null;
    }

    assert(channels >= 1 && channels <= 4);

    memset(index.ptr, 0, 64 * qoi10_rgba_t.sizeof);

    int currentBit = 7;

    int readBit() nothrow @nogc
    {
        ubyte bb = bytes[p];

        int bit = (bytes[p] >>> currentBit) & 1;

        currentBit -= 1;
        if (currentBit == -1)
        {
            currentBit = 7;
            p++;
        }
        return bit;
    }

    uint readBits(int nbits) nothrow @nogc
    {
        uint r = 0;
        for (int b = 0; b < nbits; ++b)
        {
            r = (r << 1) | readBit();
        }
        return r;
    }

    ubyte readByte() nothrow @nogc
    {
        return cast(ubyte) readBits(8);
    }


    qoi10_rgba_t px = initialPredictor;
    qoi10_rgba_t px_ref = initialPredictor;

    bool finished = false;

    for (int posy = 0; posy < desc.height; ++posy)
    {
        ushort* line      = cast(ushort*)(pixels + desc.pitchBytes * posy);
        ushort* lineAbove = (posy > 0) ? cast(ushort*)(pixels + desc.pitchBytes * (posy - 1)) : null;

        for (int posx = 0; posx < desc.width; ++posx)
        {
            if (run > 0) {
                run--;
            }
            else
            {
                px_ref = px;

                ubyte op = readByte();

                /// QOI_OP_LUMA2   22   110gggggggrrrrrrbbbbbb
                /// QOI_OP_LUMA3   30   11100gggggggggrrrrrrrrbbbbbbbb
                /// QOI_OP_ADIFF   10   11101xxxxx
                /// QOI_OP_RUN      8   11110xxx
                /// QOI_OP_RUN2    16   111110xxxxxxxxxx
                /// QOI_OP_GRAY    18   11111100gggggggggg
                /// QOI_OP_RGB     38   11111101rrrrrrrrrrggggggggggbbbbbbbbbb
                /// QOI_OP_RGBA    48   11111110rrrrrrrrrrggggggggggbbbbbbbbbbaaaaaaaaaa
                /// QOI_OP_END      8   11111111

                if (op == QOI_OP_RGBA)
                {
                    px.r = cast(ushort) readBits(10);
                    px.g = cast(ushort) readBits(10);
                    px.b = cast(ushort) readBits(10);
                    px.a = cast(ushort) readBits(10);
                }
                else if (op == QOI_OP_END)
                {
                    finished = true;
                }
                else
                {
                    assert(false);
                }
            }

            qoi10_rgba_t px16b = px;
            assert(px16b.r <= 1023);
            assert(px16b.g <= 1023);
            assert(px16b.b <= 1023);
            assert(px16b.a <= 1023);
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
    }
    return pixels;
}

                // TODO average prediction

/+

                int b1 = bytes[p++];
                if (b1 < 0x80) {        /* QOI_OP_LUMA */
                    int vg = ((b1 >> 4) & 7) - 4;
                    px.rgba.g = cast(ubyte)(px_ref.rgba.g + vg);
                    if (vg < 0) {
                        px.rgba.r = cast(ubyte)( px_ref.rgba.r + vg - 1 + ((b1 >> 2) & 3) );
                        px.rgba.b = cast(ubyte)( px_ref.rgba.b + vg - 1 +  (b1 &  3) );
                    }
                    else {
                        px.rgba.r = cast(ubyte)( px_ref.rgba.r + vg - 2 + ((b1 >> 2) & 3) );
                        px.rgba.b = cast(ubyte)( px_ref.rgba.b + vg - 2 +  (b1 &  3) );
                    }
                    index[index_pos++ & 63] = px;
                }
                else if (b1 < 0xc0) {       /* QOI_OP_INDEX */
                    px = index[b1 & 63];
                }
                else if (b1 < 0xe0) {       /* QOI_OP_LUMA2 */
                    int b2 = bytes[p++];
                    int vg = (b1 & 0x1f) - 16;
                    px.rgba.r = cast(ubyte)( px_ref.rgba.r + vg - 8 + ((b2 >> 4) & 0x0f) );
                    px.rgba.g = cast(ubyte)( px_ref.rgba.g + vg );
                    px.rgba.b = cast(ubyte)( px_ref.rgba.b + vg - 8 +  (b2       & 0x0f) );
                    index[index_pos++ & 63] = px;
                }
                else if (b1 < 0xe8) {       /* QOI_OP_LUMA3 */
                    int dv = (b1 << 8) | bytes[p++];
                    dv = (dv << 8) | bytes[p++];
                    int vg = ((dv >> 12) & 0x7f) - 64;
                    px.rgba.r = cast(ubyte)( px_ref.rgba.r + vg + ((dv >> 6) & 0x3f) - 32 );
                    px.rgba.g = cast(ubyte)( px_ref.rgba.g + vg );
                    px.rgba.b = cast(ubyte)( px_ref.rgba.b + vg + (dv & 0x3f) - 32 );
                    index[index_pos++ & 63] = px;
                }
                else if (b1 < 0xf0) {       /* QOI_OP_ADIFF */
                    px.rgba.a += (b1 & 7) - 4;
                    continue;
                }
                else if (b1 < 0xf8) {       /* QOI_OP_RUN */
                    run = b1 & 7;
                }
                else if (b1 < 0xfc) {       /* QOI_OP_RUN2 */
                    run = ((b1 & 3) << 8) | bytes[p++];
                }
                else if (b1 == QOI_OP_GRAY) {
                    ubyte vg = bytes[p++];
                    px.rgba.r = vg;
                    px.rgba.g = vg;
                    px.rgba.b = vg;
                    index[index_pos++ & 63] = px;
                }
                else if (b1 == QOI_OP_RGB) {
                    px.rgba.r = bytes[p++];
                    px.rgba.g = bytes[p++];
                    px.rgba.b = bytes[p++];
                    index[index_pos++ & 63] = px;
                }
                else if (b1 == QOI_OP_RGBA) {
                    px.rgba.r = bytes[p++];
                    px.rgba.g = bytes[p++];
                    px.rgba.b = bytes[p++];
                    px.rgba.a = bytes[p++];
                    index[index_pos++ & 63] = px;
                }
                else {              /* QOI_OP_END */
                    break;
                }
 +/
          