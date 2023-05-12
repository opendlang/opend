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
    scanlineConversionFunction_t _scanConvert;
    int _channels;
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

        
        switch(inputType) with (PixelType)
        {
            case unknown: assert(false);
            case l8:
                _channels = 3;
                _scanConvert = &scanline_convert_l8_to_rgb8; 
                break;
            case la8:   
                _channels = 4;
                _scanConvert = &scanline_convert_la8_to_rgba8; 
                break;
            case rgb8:  
                _channels = 3;
                _scanConvert = &scanline_convert_rgb8_to_rgb8; 
                break;
            case rgba8: 
                _channels = 4;
                _scanConvert = &scanline_convert_rgba8_to_rgba8; 
                break;
            default:
                return false; // Unsupported format
        }

        // Always puts out a RGB8 or RGBA8 TGA file.
        scanSpace = cast(ubyte*) malloc(width * _channels);

        ubyte[18] header;
        header[0] = 0;
        header[1] = 0;
        header[2] = 2;  /* uncompressed RGB */
        header[3..12] = 0;

        header[12] = width & 0xff;
        header[13] = (width & 0xff00) >>> 8;
        header[14] = height & 0xff;
        header[15] = (height & 0xff00) >>> 8;

        header[16] = cast(ubyte)(_channels * 8); // write 24 or 32
        header[17] = 0;

        if (18 != io.write(header.ptr, 1, 18, handle))
            return false;

        return true;
    }

    ~this()
    {
        free(scanSpace);
    }

    // Note: .tga scanlines are stored reversed, call this in reverse order.
    bool encodeScanline(const(void)* scanptr)
    {
        _scanConvert(cast(const(ubyte)*)scanptr, scanSpace, _width, null);

        // swap R and B, since we need to write in BGRA order
        if (_channels == 4)
        {
            for (int x = 0; x < _width; ++x)
            {
                ubyte r = scanSpace[4*x];
                ubyte b = scanSpace[4*x+2];
                scanSpace[4*x+2] = r;
                scanSpace[4*x] = b;
            }
        }
        else if (_channels == 3)
        {
            for (int x = 0; x < _width; ++x)
            {
                ubyte r = scanSpace[3*x];
                ubyte b = scanSpace[3*x+2];
                scanSpace[3*x+2] = r;
                scanSpace[3*x] = b;
            }
        }
        else
            assert(false);

        size_t nbytes = _width * _channels;
        size_t written = _io.write(scanSpace, 1, nbytes, _handle);
        if (written != nbytes)
            return false;

        return true;
    }
}



