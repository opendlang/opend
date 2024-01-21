/**
BMP support.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.plugins.bmp;

nothrow @nogc @safe:

import core.stdc.stdlib: malloc, free, realloc;
import gamut.types;
import gamut.io;
import gamut.plugin;
import gamut.image;
import gamut.internals.errors;
import gamut.internals.types;


version(decodeBMP) import gamut.codecs.stbdec;
else version(encodeBMP) import gamut.codecs.bmpenc;

ImageFormatPlugin makeBMPPlugin()
{
    ImageFormatPlugin p;
    p.format = "BMP";
    p.extensionList = "bmp";
    p.mimeTypes = "image/bmp";
    version(decodeBMP)
        p.loadProc = &loadBMP;
    else
        p.loadProc = null;
    version(encodeBMP)
        p.saveProc = &saveBMP;
    else
        p.saveProc = null;
    p.detectProc = &detectBMP;
    return p;
}

// FUTURE: Note: detection API should report I/O errors other than yes/no for the test, 
// since stream might be fatally errored.
// Returning a ternary would be extra-nice.

bool detectBMP(IOStream *io, IOHandle handle) @trusted
{
    // save I/O cursor
    c_long offset = io.tell(handle);

    bool err;
    ubyte b = io.read_ubyte(handle, &err); if (err) return false; // IO error
    if (b != 'B')
        return false;
    b = io.read_ubyte(handle, &err); if (err) return false; // IO error
    if (b != 'M')
        return false;
    if (!io.skipBytes(handle, 12))
        return false; // IO error
    uint ds = io.read_uint_LE(handle, &err); if (err) return false; // IO error
    bool match = (ds == 12 || ds == 40 || ds == 52 || ds == 56 || ds == 108 || ds == 124);

    // restore I/O cursor
    if (!io.seekAbsolute(handle, offset))
        return false; // IO error

    return match;
}

version(encodeBMP)
bool saveBMP(ref const(Image) image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    if (page != 0)
        return false;    

    int components;

    // For now, can save RGB and RGBA 8-bit images.
    switch (image._type)
    {
        case PixelType.rgb8:
            components = 3; break;
        case PixelType.rgba8:
            components = 4; 
            break;
        default:
            return false;
    }

    int width = image._width;
    int height = image._height;
    int pitch = image._pitch;
    if (width < 1 || height < 1 || width > 32767 || height > 32767)
        return false; // Can't be saved as BMP

    bool success = write_bmp(image, io, handle, width, height, components);

    return success;
}
