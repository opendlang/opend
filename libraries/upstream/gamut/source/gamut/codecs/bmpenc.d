/**
BMP encoder.
Encoder based upon imageformats dub package.

Copyright: Copyright Tero Hänninen 2016-2022 (encoder)
           Copyright Guillaume Piolat 2024
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.codecs.bmpenc;

import core.stdc.stdlib: malloc, free;
import gamut.io;
import gamut.image;
import gamut.scanline;

@nogc nothrow:

enum CMP_RGB  = 0;
enum CMP_BITS = 3;


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

    ubyte* _scanBuffer = null;   
    size_t _scanLen;
    _scanBuffer = cast(ubyte*) malloc(tgt_linesize + pad);
    _scanLen = tgt_linesize + pad;
    scope(exit) free(_scanBuffer);

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