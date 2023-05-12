/**
Basic TGA writer.

Copyright: Copyright Guillaume Piolat 2023
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.codecs.tga;

/// Reference: http://www.paulbourke.net/dataformats/tga/

import core.stdc.stdlib: malloc, free;

import gamut.scanline;
import gamut.types;
import gamut.io;


/// This supports l8, la8, rgb8, rgba8 as input, and can output a bgra8 .TGA only
struct TGAEncoder
{
nothrow:
@nogc:

    IOStream* _io;
    void* _handle;
    PixelType _inputType;
    scanlineConversionFunction_t scanConvert;
    int _width;
    int _height;
    ubyte* scanSpace;

    bool initialize(IOStream* io, void* handle, PixelType inputType, int width, int height)
    {
        _inputType = inputType;
        _io = io;
        _handle = handle;

        if (width > 65525) // not supported by TARGA
            return false;
        if (height > 65525)
            return false;

        _width = width;
        _height = height;

        // Always puts out a RGBA8 TGA file. (FUTURE: allow RGB8)
        scanSpace = cast(ubyte*) malloc(width * 4);
        
        switch(inputType) with (PixelType)
        {
            case unknown: assert(false);
            case l8:    scanConvert = &scanline_convert_l8_to_rgba8; break;
            case la8:   scanConvert = &scanline_convert_la8_to_rgba8; break;
            case rgb8:  scanConvert = &scanline_convert_rgb8_to_rgba8; break;
            case rgba8: scanConvert = &scanline_convert_rgba8_to_rgba8; break;
            default:
                return false; // Unsupported format
        }

        ubyte[18] header;
        header[0] = 0;
        header[1] = 0;
        header[2] = 2;  /* uncompressed RGB */
        header[3..12] = 0;

        header[12] = width & 0xff;
        header[13] = (width & 0xff00) >>> 8;
        header[14] = height & 0xff;
        header[15] = (height & 0xff00) >>> 8;

        header[16] = 32; // 32-bit color (could be 24)
        header[17] = 0;

        if (18 != io.write(header.ptr, 1, 18, handle))
            return false;

        return true;
    }

    ~this()
    {
        free(scanSpace);
    }

    bool encodeScanline(const(void)* scanptr)
    {
        scanConvert(cast(const(ubyte)*)scanptr, scanSpace, _width, null);

        // swap R and B, since we need to write in BGRA order
        for (int x = 0; x < _width; ++x)
        {
            ubyte r = scanSpace[4*x];
            ubyte b = scanSpace[4*x+2];
            scanSpace[4*x+2] = r;
            scanSpace[4*x] = b;
        }

        void* pp = scanSpace; 
        assert(_io.write !is null);

        size_t written = _io.write(scanSpace, 1, _width*4, _handle);
        if (written != _width*4)
            return false;

        return true;
    }
}



