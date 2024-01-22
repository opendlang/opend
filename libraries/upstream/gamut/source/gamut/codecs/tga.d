/**
TGA read/writer from stb_image.h

Copyright: Copyright Guillaume Piolat 2023
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
/*
------------------------------------------------------------------------------
This software is available under 2 licenses -- choose whichever you prefer.
------------------------------------------------------------------------------
ALTERNATIVE A - MIT License
Copyright (c) 2017 Sean Barrett
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
------------------------------------------------------------------------------
ALTERNATIVE B - Public Domain (www.unlicense.org)
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
software, either in source code form or as a compiled binary, for any purpose,
commercial or non-commercial, and by any means.
In jurisdictions that recognize copyright laws, the author or authors of this
software dedicate any and all copyright interest in the software to the public
domain. We make this dedication for the benefit of the public at large and to
the detriment of our heirs and successors. We intend this dedication to be an
overt act of relinquishment in perpetuity of all present and future rights to
this software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
------------------------------------------------------------------------------
*/
module gamut.codecs.tga;

import core.stdc.stdlib: malloc, free;

import gamut.scanline;
import gamut.types;
import gamut.io;


/// This supports l8, la8, rgb8, rgba8 as input, and can output RGB8 or RGBA8 .TGA with RLE
/// Reference: http://www.paulbourke.net/dataformats/tga/
version(encodeTGA)
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
    byte* similarMask; // 0 => different as previous pixel n-1      1 => same as previous pixel n-1
    byte* opcode;      // RLE or Raw
    bool _enableRLE;

    bool initialize(IOStream* io, void* handle, PixelType inputType, int width, int height, bool enableRLE)
    {
        _inputType = inputType;
        _io = io;
        _handle = handle;
        _enableRLE = enableRLE;

        if (width > 65535) // not supported by TARGA
            return false;
        if (height > 65535)
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
        // single alloc for all buffers
        scanSpace = cast(ubyte*) malloc(width * _channels + width*2);
        similarMask = cast(byte*)(scanSpace + (width * _channels));
        opcode = similarMask + width;

        ubyte[18] header;
        header[0] = 0;
        header[1] = 0;
        header[2] = _enableRLE ? 10 : 2;
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

    static struct Color
    {
        ubyte r, g, b, a;
    }

    // Note: .tga scanlines are stored reversed, call this in reverse order.
    bool encodeScanline(const(void)* scanptr)
    {
        if (_width == 0)
            return true; // in case we ever want 0-width TGA

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

        if (_enableRLE)
        {
            // Probably need a flag to enable this.
            bool dropColorInformationInTransparentAreas = false;

            // 1. Compute a similarity between consecutive pixels
            {
                Color last;  
                for (int x = 0; x < _width; ++x)
                {
                    // Read color
                    Color c;
                    c.r = scanSpace[_channels*x];
                    c.g = scanSpace[_channels*x+1];
                    c.b = scanSpace[_channels*x+2];
                    c.a = (_channels == 3) ? 255 : scanSpace[x*4+3];
                    bool similar = (c == last) || (c.a == 0 && dropColorInformationInTransparentAreas);
                    similarMask[x] = similar ? 1 : 0;
                    last = c;
                }
                similarMask[0] = 0;
            }

            // 2. Compute the length of subsequent pixels that are all different from earlier ones, 
            //    or all the same as earlier ones.
            int numSame = 0; // the number of FOLLOWING pixel that are same as the one considered
            int numDifferent = 0; // the number of FOLLOWING pixel that are different neighbour by neighbour
            for (int x = _width - 1; x >= 0; --x)
            {
                // Decision of opcode here. How to best encode that pixel and the following from here?
                float bppRaw = (1 + numDifferent * _channels) / cast(float)numDifferent;
                float bppRLE = (1 + _channels) / cast(float)numSame;

                if (bppRaw <= bppRLE)
                {
                    // Encode as RAW
                    assert(numDifferent >= 0 && numDifferent < 128);
                    opcode[x] = cast(byte)numDifferent;
                }
                else
                {
                    // Encode as RLE
                    assert(numSame >= 0 && numSame < 128);
                    opcode[x] = cast(byte)(0x80 | numSame);
                }

                // Compute chains of pixels for the n-1.
                if (similarMask[x])
                {
                    numSame += 1;
                    if (numSame >= 127)
                        numSame = 127;
                    numDifferent = 0;
                }
                else
                {
                    numDifferent += 1;
                    if (numDifferent >= 127)
                        numDifferent = 127;
                    numSame = 0;
                }
            }

            // Rewrite similarMask to write the number of times a color is repeated.
            //      0 means:   single color pixel, can be encoded in either mode
            // 1..127 means:   Raw, n+1 pixel encodings follow
            // -1..-128 means: RLE: -n colors not followed by a similar color.

            // 3. We can encode with the opcode we computed, acts like a trivial decision.
            int x = 0;
            for (; x < _width; )
            {
                byte hint = opcode[x];

                // The hint can be used directly as opcode.
                if (1 != _io.write(&hint, 1, 1, _handle))
                    return false;

                // Amazingly, raw and rle can be handled by same code.
                int num = (hint & 127)+1;
                size_t nbytes = (hint >= 0) ? num * _channels : _channels;
                size_t written = _io.write(&scanSpace[x*_channels], 1, nbytes, _handle);
                if (written != nbytes)
                    return false;
                x += num;
            }
            assert(x == _width);
        }
        else
        {
            // only raw encode, just paste the scanline
            size_t nbytes = _width * _channels;
            size_t written = _io.write(scanSpace, 1, nbytes, _handle);
            if (written != nbytes)
                return false;
        }
        return true;
    }
}

version(decodeTGA)
struct TGADecoder
{
nothrow:
@nogc:

    IOStream* _io;
    void* _handle;

    ubyte _cmapType; // 0 = not indexed      1 = indexed
    ushort _paletteStart;
    ushort _paletteLen;
    ubyte _imageType; 
    ubyte _cmapSize;
    ubyte _bpp;
    int _inverted;
    int _width = 0;
    int _height = 0;
    bool _isRLE;
    bool _rgb16;
    ubyte _dataOffset;

    bool initialize(IOStream* io, IOHandle handle)
    {
        _io = io;
        _handle = handle;
        return true;
    }

    // If successful, this is a probable TGA (header isn't very decisive...) and you can read _width/_height/_bpp
    bool getImageInfo()
    {
        // Taken right from stb_image.h

        bool err;
        _dataOffset = _io.read_ubyte(_handle, &err);
        if (err)
            return false;
        
        _cmapType = _io.read_ubyte(_handle, &err);
        if (err || _cmapType > 1)
            return false; // only RGB or indexed allowed

        _imageType = _io.read_ubyte(_handle, &err);
        if (err) return false;

        if (_cmapType == 1) // has colormap
        {
            if (_imageType != 1 && _imageType != 9)
                return false;

            _paletteStart = _io.read_ushort_LE(_handle, &err);
            if (err)
                return false;
            _paletteLen = _io.read_ushort_LE(_handle, &err);
            if (err)
                return false;

            if (_paletteLen == 0)
                return false; // no entry in palette

            _cmapSize = _io.read_ubyte(_handle, &err); // check bits per palette color entry
            if (err) 
                return false;

            if ( (_cmapSize != 8) && (_cmapSize != 15) && (_cmapSize != 16) && (_cmapSize != 24) && (_cmapSize != 32) ) 
            {
                return false;
            }

            if (!_io.skipBytes(_handle, 4)) // image x and y origin
                return false;
        }
        else // no colormap
        {
            // grey and RGB, RLE or not
            if ( (_imageType != 2) && (_imageType != 3) && (_imageType != 10) && (_imageType != 11) )
                return false;

            if (!_io.skipBytes(_handle, 9))
                return false;
        }

        _width = _io.read_ushort_LE(_handle, &err);
        if (err) return false;
        _height = _io.read_ushort_LE(_handle, &err);
        if (err) return false;
        if (_width < 1 || _height < 1)
            return false; // Apparently size 0 not allowed

        _bpp = _io.read_ubyte(_handle, &err); //   bits per pixel
        if (err) return false; 

        if ( (_cmapType == 1) && (_bpp != 8) && (_bpp != 16) ) // for colormapped images, bpp is size of an index
            return false;
        if ( (_bpp != 8) && (_bpp != 15) && (_bpp != 16) && (_bpp != 24) && (_bpp != 32) )
            return false;

        return true; // OK, this is maybe a TGA
    }

    ubyte* decodeImage(int* outComponents)
    {
        // Bit of post-processing.
        _isRLE = false;
        if (_imageType >= 8) // 10 and 11 become 2 and 3
        {
            _imageType -= 8;
            _isRLE = true;
        }

        bool err;
        _inverted = _io.read_ubyte(_handle, &err); //   bits per pixel
        if (err) 
            return null; 
        _inverted = 1 - ((_inverted >> 5) & 1);

        bool isIndexed = _cmapType != 0;

        //   If I'm paletted, then I'll use the number of bits from the palette
        int components;
        if (isIndexed)
            components = stbi__tga_get_comp(_cmapSize, 0, &_rgb16);
        else 
            components = stbi__tga_get_comp(_bpp, (_imageType == 3), &_rgb16);
        assert(components != 0); // should have been taken care of by earlier getImageInfo()

        if (!_io.skipBytes(_handle, _dataOffset))
            return null;

        long allocationSize = (cast(long)_width)*_height * components;
        if (allocationSize > GAMUT_MAX_IMAGE_BYTES)
            return null;
        if (allocationSize >= cast(ulong)(size_t.max))
            return null;

        ubyte* data = cast(ubyte*) malloc(cast(size_t)allocationSize);
        ubyte* palette = null;

        if ( !isIndexed && !_isRLE && !_rgb16 ) 
        {
            for (int i = 0; i < _height; ++i) 
            {
                int row = _inverted ? _height - i - 1 : i;
                ubyte* prow = data + row * _width * components;
                size_t bytes = _width * components;
                if (bytes != _io.read(prow, 1, bytes, _handle))
                {
                    free(data);
                    return null;
                }
            }
        } 
        else
        {
            // Is there a palette?
            if (isIndexed)
            {
                if (!_io.skipBytes(_handle, _paletteStart))
                    goto errored;

                palette = cast(ubyte*) malloc(_paletteLen * components); // PERF: could be allocated as extra bytes

                if (_rgb16) 
                {
                    ubyte* pal_entry = palette;
                    assert(components == 3);
                    for (int i = 0; i < _paletteLen; ++i) 
                    {
                        stbi__tga_read_rgb16(pal_entry, &err);
                        if (err)
                            goto errored;
                        pal_entry += components;
                    }
                } 
                else
                {
                    // Read whole palette at once.
                    size_t bytes = _paletteLen * components;
                    if (bytes != _io.read(palette, 1, bytes, _handle))
                        goto errored_with_palette;
                }
            }

            int RLE_count = 0;
            int RLE_repeating = 0;
            int read_next_pixel = 1;
            ubyte[4] raw_data;

            // Load the data
            for (int i = 0; i < _width * _height; ++i)
            {
                //   if I'm in RLE mode, do I need to get a RLE stbi__pngchunk?
                if (_isRLE)
                {
                    if (RLE_count == 0)
                    {
                        //   yep, get the next byte as a RLE command
                        int RLE_cmd = _io.read_ubyte(_handle, &err);
                        if (err)
                            goto errored_with_palette;

                        RLE_count = 1 + (RLE_cmd & 127);
                        RLE_repeating = RLE_cmd >> 7;
                        read_next_pixel = 1;
                    } 
                    else if ( !RLE_repeating )
                    {
                        read_next_pixel = 1;
                    }
                } 
                else
                {
                    read_next_pixel = 1;
                }

                //   OK, if I need to read a pixel, do it now
                if ( read_next_pixel )
                {
                    //   load however much data we did have
                    if (isIndexed)
                    {
                        // read in index, then perform the lookup
                        int pal_idx;
                        if (_bpp == 8)
                            pal_idx = _io.read_ubyte(_handle, &err);
                        else
                            pal_idx = _io.read_ushort_LE(_handle, &err);
                        if (err)
                            goto errored_with_palette;

                        if (pal_idx >= _paletteLen) 
                        {
                            // invalid index
                            pal_idx = 0;
                        }
                        pal_idx *= components;
                        for (int j = 0; j < components; ++j) 
                        {
                            raw_data[j] = palette[pal_idx + j];
                        }
                    } 
                    else if (_rgb16) 
                    {
                        assert(components == 3);
                        stbi__tga_read_rgb16(raw_data.ptr, &err);
                        if (err)
                            goto errored_with_palette;
                    } 
                    else 
                    {
                        //   read in the data raw
                        for (int j = 0; j < components; ++j) 
                        {
                            raw_data[j] = _io.read_ubyte(_handle, &err);
                            if (err)
                                goto errored_with_palette;
                        }
                    }
                    //   clear the reading flag for the next pixel
                    read_next_pixel = 0;
                } // end of reading a pixel

                // copy data
                for (int j = 0; j < components; ++j)
                {
                    data[i * components + j] = raw_data[j];
                }

                //   in case we're in RLE mode, keep counting down
                --RLE_count;
            }
            
            //   do I need to invert the image?
            if (_inverted)
            {
                for (int j = 0; j * 2 < _height; ++j)
                {
                    int index1 = j * _width * components;
                    int index2 = (_height - 1 - j) * _width * components;
                    for (int i = _width * components; i > 0; --i)
                    {
                        ubyte temp = data[index1];
                        data[index1] = data[index2];
                        data[index2] = temp;
                        ++index1;
                        ++index2;
                    }
                }
            }
            free(palette);
        }

        // swap RB - if the source data was RGB16, it already is in the right order
        if (components >= 3 && !_rgb16)
        {
            ubyte* tga_pixel = data;
            for (int i = 0; i < _width * _height; ++i)
            {
                ubyte temp = tga_pixel[0];
                tga_pixel[0] = tga_pixel[2];
                tga_pixel[2] = temp;
                tga_pixel += components;
            }
        }

        *outComponents = components;
        return data;

        errored_with_palette:
            free(palette);

        errored:
            free(data);
            return null;
    }


    int stbi__tga_get_comp(int bits_per_pixel, int is_grey, bool* is_rgb16)
    {
        // only RGB or RGBA (incl. 16bit) or grey allowed
        *is_rgb16 = false;
        switch(bits_per_pixel) 
        {
        case 8:  
            return 1;
        case 16: 
            if(is_grey) 
                return 2;
            goto case 15;
        case 15: 
            *is_rgb16 = true;
            return 3;
        case 24: 
            goto case 32;
        case 32: 
            return bits_per_pixel / 8;
        default: 
            return 0;
        }
    }

    void stbi__tga_read_rgb16(ubyte* outColor, bool* err)
    {
        ushort px = _io.read_ushort_LE(_handle, err);
        if (*err)
            return;
        
        ushort fiveBitMask = 31;

        // we have 3 channels with 5bits each
        int r = (px >> 10) & fiveBitMask;
        int g = (px >> 5) & fiveBitMask;
        int b = px & fiveBitMask;
        // Note that this saves the data in RGB(A) order, so it doesn't need to be swapped later
        outColor[0] = cast(ubyte)((r * 255)/31);
        outColor[1] = cast(ubyte)((g * 255)/31);
        outColor[2] = cast(ubyte)((b * 255)/31);

        // some people claim that the most significant bit might be used for alpha
        // (possibly if an alpha-bit is set in the "image descriptor byte")
        // but that only made 16bit test images completely translucent..
        // so let's treat all 15 and 16bit TGAs as RGB with no alpha.
    }
}
