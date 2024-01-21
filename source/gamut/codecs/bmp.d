/**
BMP codec.

Copyright: Copyright Tero Hänninen 2016-2022
           Copyright Guillaume Piolat 2024
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.codecs.bmp;

import core.stdc.stdlib: malloc, free;
import gamut.io;
import gamut.image;
import gamut.scanline;

@nogc nothrow:

// Header of a BMP file.
struct BMP_Header 
{
    uint file_size;
    uint pixel_data_offset;
    uint dib_size;
    int width;
    int height;
    ushort planes;
    int bits_pp;
    uint dib_version;
    DibV1 dib_v1;
    DibV2 dib_v2;
    uint dib_v3_alpha_mask;
    DibV4 dib_v4;
    DibV5 dib_v5;
}

// Part of BMP header, not always present.
struct DibV1 
{
    uint compression;
    uint idat_size;
    uint pixels_per_meter_x;
    uint pixels_per_meter_y;
    uint palette_length;
    uint important_color_count;
}

// Part of BMP header, not always present.
struct DibV2 
{
    uint red_mask;
    uint green_mask;
    uint blue_mask;
}

// Part of BMP header, not always present.
struct DibV4 
{
    uint color_space_type;
    ubyte[36] color_space_endpoints;
    uint gamma_red;
    uint gamma_green;
    uint gamma_blue;
}

/// Part of BMP header, not always present.
struct DibV5 
{
    uint icc_profile_data;
    uint icc_profile_size;
}

/+
// Detects whether a BMP image is readable from stream.
package bool detect_bmp(Reader stream) {
    try {
        ubyte[18] tmp = void;  // bmp header + size of dib header
        stream.readExact(tmp, tmp.length);
        size_t ds = littleEndianToNative!uint(tmp[14..18]);
        return (tmp[0..2] == bmp_header
            && (ds == 12 || ds == 40 || ds == 52 || ds == 56 || ds == 108 || ds == 124));
    } catch (Throwable) {
        return false;
    } finally {
        stream.seek(0, SEEK_SET);
    }
}
+/

/*

BMP_Header read_bmp_header(Reader stream) {
    ubyte[18] tmp = void;  // bmp header + size of dib header
    stream.readExact(tmp[], tmp.length);

    if (tmp[0..2] != bmp_header)
        throw new ImageIOException("corrupt header");

    uint dib_size = littleEndianToNative!uint(tmp[14..18]);
    uint dib_version;
    switch (dib_size) {
        case 12: dib_version = 0; break;
        case 40: dib_version = 1; break;
        case 52: dib_version = 2; break;
        case 56: dib_version = 3; break;
        case 108: dib_version = 4; break;
        case 124: dib_version = 5; break;
        default: throw new ImageIOException("unsupported dib version");
    }
    auto dib_header = new ubyte[dib_size-4];
    stream.readExact(dib_header[], dib_header.length);

    DibV1 dib_v1;
    DibV2 dib_v2;
    uint dib_v3_alpha_mask;
    DibV4 dib_v4;
    DibV5 dib_v5;

    if (1 <= dib_version) {
        DibV1 v1 = {
            compression           : littleEndianToNative!uint(dib_header[12..16]),
            idat_size             : littleEndianToNative!uint(dib_header[16..20]),
            pixels_per_meter_x    : littleEndianToNative!uint(dib_header[20..24]),
            pixels_per_meter_y    : littleEndianToNative!uint(dib_header[24..28]),
            palette_length        : littleEndianToNative!uint(dib_header[28..32]),
            important_color_count : littleEndianToNative!uint(dib_header[32..36]),
        };
        dib_v1 = v1;
    }

    if (2 <= dib_version) {
        DibV2 v2 = {
            red_mask              : littleEndianToNative!uint(dib_header[36..40]),
            green_mask            : littleEndianToNative!uint(dib_header[40..44]),
            blue_mask             : littleEndianToNative!uint(dib_header[44..48]),
        };
        dib_v2 = v2;
    }

    if (3 <= dib_version) {
        dib_v3_alpha_mask = littleEndianToNative!uint(dib_header[48..52]);
    }

    if (4 <= dib_version) {
        DibV4 v4 = {
            color_space_type      : littleEndianToNative!uint(dib_header[52..56]),
            color_space_endpoints : dib_header[56..92],
            gamma_red             : littleEndianToNative!uint(dib_header[92..96]),
            gamma_green           : littleEndianToNative!uint(dib_header[96..100]),
            gamma_blue            : littleEndianToNative!uint(dib_header[100..104]),
        };
        dib_v4 = v4;
    }

    if (5 <= dib_version) {
        DibV5 v5 = {
            icc_profile_data      : littleEndianToNative!uint(dib_header[108..112]),
            icc_profile_size      : littleEndianToNative!uint(dib_header[112..116]),
        };
        dib_v5 = v5;
    }

    int width, height; ushort planes; int bits_pp;
    if (0 == dib_version) {
        width = littleEndianToNative!ushort(dib_header[0..2]);
        height = littleEndianToNative!ushort(dib_header[2..4]);
        planes = littleEndianToNative!ushort(dib_header[4..6]);
        bits_pp = littleEndianToNative!ushort(dib_header[6..8]);
    } else {
        width = littleEndianToNative!int(dib_header[0..4]);
        height = littleEndianToNative!int(dib_header[4..8]);
        planes = littleEndianToNative!ushort(dib_header[8..10]);
        bits_pp = littleEndianToNative!ushort(dib_header[10..12]);
    }

    BMP_Header header = {
        file_size             : littleEndianToNative!uint(tmp[2..6]),
        pixel_data_offset     : littleEndianToNative!uint(tmp[10..14]),
        width                 : width,
        height                : height,
        planes                : planes,
        bits_pp               : bits_pp,
        dib_version           : dib_version,
        dib_v1                : dib_v1,
        dib_v2                : dib_v2,
        dib_v3_alpha_mask     : dib_v3_alpha_mask,
        dib_v4                : dib_v4,
        dib_v5                : dib_v5,
    };
    return header;
}

*/

enum CMP_RGB  = 0;
enum CMP_BITS = 3;

/+

package IFImage read_bmp(Reader stream, long req_chans = 0) {
    if (req_chans < 0 || 4 < req_chans)
        throw new ImageIOException("unknown color format");

    BMP_Header hdr = read_bmp_header(stream);

    if (hdr.width < 1 || hdr.height == 0)
        throw new ImageIOException("invalid dimensions");
    if (hdr.pixel_data_offset < (14 + hdr.dib_size)
     || hdr.pixel_data_offset > 0xffffff /* arbitrary */) {
        throw new ImageIOException("invalid pixel data offset");
    }
    if (hdr.planes != 1)
        throw new ImageIOException("not supported");

    auto bytes_pp       = 1;
    bool paletted       = true;
    size_t palette_length = 256;
    bool rgb_masked     = false;
    auto pe_bytes_pp    = 3;

    if (1 <= hdr.dib_version) {
        if (256 < hdr.dib_v1.palette_length)
            throw new ImageIOException("ivnalid palette length");
        if (hdr.bits_pp <= 8 &&
           (hdr.dib_v1.palette_length == 0 || hdr.dib_v1.compression != CMP_RGB))
             throw new ImageIOException("unsupported format");
        if (hdr.dib_v1.compression != CMP_RGB && hdr.dib_v1.compression != CMP_BITS)
             throw new ImageIOException("unsupported compression");

        switch (hdr.bits_pp) {
            case 8  : bytes_pp = 1; paletted = true; break;
            case 24 : bytes_pp = 3; paletted = false; break;
            case 32 : bytes_pp = 4; paletted = false; break;
            default: throw new ImageIOException("not supported");
        }

        palette_length = hdr.dib_v1.palette_length;
        rgb_masked = hdr.dib_v1.compression == CMP_BITS;
        pe_bytes_pp = 4;
    }

    static size_t mask_to_idx(in uint mask) {
        switch (mask) {
            case 0xff00_0000: return 3;
            case 0x00ff_0000: return 2;
            case 0x0000_ff00: return 1;
            case 0x0000_00ff: return 0;
            default: throw new ImageIOException("unsupported mask");
        }
    }

    size_t redi = 2;
    size_t greeni = 1;
    size_t bluei = 0;
    if (rgb_masked) {
        if (hdr.dib_version < 2)
            throw new ImageIOException("invalid format");
        redi = mask_to_idx(hdr.dib_v2.red_mask);
        greeni = mask_to_idx(hdr.dib_v2.green_mask);
        bluei = mask_to_idx(hdr.dib_v2.blue_mask);
    }

    bool alpha_masked = false;
    size_t alphai = 0;
    if (bytes_pp == 4 && 3 <= hdr.dib_version && hdr.dib_v3_alpha_mask != 0) {
        alpha_masked = true;
        alphai = mask_to_idx(hdr.dib_v3_alpha_mask);
    }

    ubyte[] depaletted_line = null;
    ubyte[] palette = null;
    if (paletted) {
        depaletted_line = new ubyte[hdr.width * pe_bytes_pp];
        palette = new ubyte[palette_length * pe_bytes_pp];
        stream.readExact(palette[], palette.length);
    }

    stream.seek(hdr.pixel_data_offset, SEEK_SET);

    const tgt_chans = (0 < req_chans) ? req_chans
                                      : (alpha_masked) ? _ColFmt.RGBA
                                                       : _ColFmt.RGB;

    const src_fmt = (!paletted || pe_bytes_pp == 4) ? _ColFmt.BGRA : _ColFmt.BGR;
    const LineConv!ubyte convert = get_converter!ubyte(src_fmt, tgt_chans);

    const size_t src_linesize = hdr.width * bytes_pp;  // without padding
    const size_t src_pad = 3 - ((src_linesize-1) % 4);
    const ptrdiff_t tgt_linesize = (hdr.width * cast(int) tgt_chans);

    const ptrdiff_t tgt_stride = (hdr.height < 0) ? tgt_linesize : -tgt_linesize;
    ptrdiff_t ti               = (hdr.height < 0) ? 0 : (hdr.height-1) * tgt_linesize;

    auto src_line      = new ubyte[src_linesize + src_pad];
    auto bgra_line_buf = (paletted) ? null : new ubyte[hdr.width * 4];
    auto result        = new ubyte[hdr.width * abs(hdr.height) * cast(int) tgt_chans];

    foreach (_; 0 .. abs(hdr.height)) {
        stream.readExact(src_line[], src_line.length);

        if (paletted) {
            const size_t ps = pe_bytes_pp;
            size_t di = 0;
            foreach (idx; src_line[0..src_linesize]) {
                if (idx > palette_length)
                    throw new ImageIOException("invalid palette index");
                size_t i = idx * ps;
                depaletted_line[di .. di+ps] = palette[i .. i+ps];
                if (ps == 4) {
                    depaletted_line[di+3] = 255;
                }
                di += ps;
            }
            convert(depaletted_line[], result[ti .. ti + tgt_linesize]);
        } else {
            for (size_t si, di;   si < src_linesize;   si+=bytes_pp, di+=4) {
                bgra_line_buf[di + 0] = src_line[si + bluei];
                bgra_line_buf[di + 1] = src_line[si + greeni];
                bgra_line_buf[di + 2] = src_line[si + redi];
                bgra_line_buf[di + 3] = (alpha_masked) ? src_line[si + alphai]
                                                       : 255;
            }
            convert(bgra_line_buf[], result[ti .. ti + tgt_linesize]);
        }

        ti += tgt_stride;
    }

    IFImage ret = {
        w      : hdr.width,
        h      : abs(hdr.height),
        c      : cast(ColFmt) tgt_chans,
        pixels : result,
    };
    return ret;
}

package void read_bmp_info(Reader stream, out int w, out int h, out int chans) {
    BMP_Header hdr = read_bmp_header(stream);
    w = abs(hdr.width);
    h = abs(hdr.height);
    chans = (hdr.dib_version >= 3 && hdr.dib_v3_alpha_mask != 0 && hdr.bits_pp == 32)
          ? ColFmt.RGBA
          : ColFmt.RGB;
}+/


struct BMPEncoder
{
nothrow @nogc:

    void initialize(int w, int tgt_chans)
    {
        const int tgt_linesize = w * tgt_chans;
        const int pad = 3 - ((tgt_linesize - 1) & 3);

        _scanBuffer = cast(ubyte*) malloc(tgt_linesize + pad);
        _scanLen = tgt_linesize + pad;
    }

    // Writes RGB or RGBA data.
    bool write_bmp(ref const(Image) image,
                   IOStream *io, 
                   IOHandle handle, 
                   int w, 
                   int h,
                   int tgt_chans) 
    {
        assert(w >= 1 && w < 32768);
        enum int DIB_SIZE = 108;
        const int tgt_linesize = w * tgt_chans;
        const int pad = 3 - ((tgt_linesize - 1) & 3);
        assert(pad >= 0 && pad < 4);
        const int idat_offset = 14 + DIB_SIZE;
        const size_t filesize = idat_offset + (cast(size_t) h) * (tgt_linesize + pad);
        if (filesize > 0xffff_ffff)
            return false; // image too large (cannot happend for now with rgb8 and rgba8).

        ubyte[14 + DIB_SIZE] hdr;
        hdr[0]      = 0x42;
        hdr[1]      = 0x4d;
        hdr[2..6]   = nativeToLittleEndian_uint(cast(uint) filesize);
        hdr[6..10]  = 0;                                                // reserved
        hdr[10..14] = nativeToLittleEndian_uint(cast(uint) idat_offset);    // offset of pixel data
        hdr[14..18] = nativeToLittleEndian_uint(cast(uint) DIB_SIZE);       // dib header size
        hdr[18..22] = nativeToLittleEndian_uint(w);
        hdr[22..26] = nativeToLittleEndian_uint(h);         // positive -> bottom-up
        hdr[26..28] = nativeToLittleEndian_ushort(1);         // planes
        hdr[28..30] = nativeToLittleEndian_ushort(cast(ushort)(tgt_chans * 8)); // bits per pixel
        hdr[30..34] = nativeToLittleEndian_uint((tgt_chans == 3) ? CMP_RGB : CMP_BITS);
        hdr[34..54] = 0;                                       // rest of dib v1
        if (tgt_chans == 3) 
        {
            hdr[54..70] = 0;    // dib v2 and v3
        } 
        else 
        {
            static immutable ubyte[16] b = [
                0, 0, 0xff, 0,
                0, 0xff, 0, 0,
                0xff, 0, 0, 0,
                0, 0, 0, 0xff
            ];
            hdr[54..70] = b;
        }
        static immutable ubyte[4] BGRs = ['B', 'G', 'R', 's'];
        hdr[70..74] = BGRs;
        hdr[74..122] = 0;

        // write header
        if (1 != io.write(hdr.ptr, hdr.length, 1, handle))
        {
            return false;
        }

        scanlineConversionFunction_t cvtFun = tgt_chans == 3 ? &scanline_convert_rgb8_to_bgr8 
                                                             : &scanline_convert_rgba8_to_bgra8;
        ubyte* outScan = _scanBuffer;
        for (int y = 0; y < h; ++y)
        {
            const(ubyte)* inScan = cast(const(ubyte)*) image.scanptr(h - 1 - y);
            cvtFun(inScan, outScan, w, null); // convert to BGR or BGRA
            size_t written = io.write(_scanBuffer, _scanLen, 1, handle);
            if (1 != written)
            {
                return false;
            }
        }
        return true;
    }

    ~this()
    {
        free(_scanBuffer);
    }

private:
    ubyte* _scanBuffer = null;   
    size_t _scanLen;
}


private:

ubyte[2] nativeToLittleEndian_ushort(short s) pure @safe
{
    ubyte[2] r;
    r[0] = (s       & 0xff);
    r[1] = (s >> 8) & 0xff;
    return r;
}

ubyte[4] nativeToLittleEndian_uint(int s) pure @safe
{
    ubyte[4] r;
    r[0] =  s        & 0xff;
    r[1] = (s >>  8) & 0xff;
    r[2] = (s >> 16) & 0xff;
    r[3] = (s >> 24) & 0xff;
    return r;
}