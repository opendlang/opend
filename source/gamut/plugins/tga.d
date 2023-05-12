/**
TGA support.

Copyright: Copyright Guillaume Piolat 2023
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.plugins.tga;

nothrow @nogc @safe:

import core.stdc.stdlib: malloc, free, realloc;
import gamut.types;
import gamut.io;
import gamut.plugin;
import gamut.image;
import gamut.internals.errors;
import gamut.internals.types;

version(decodeTGA) import gamut.codecs.tga;
else version(encodeTGA) import gamut.codecs.tga;

ImageFormatPlugin makeTGAPlugin()
{
    ImageFormatPlugin p;
    p.format = "TGA";
    p.extensionList = "tga";
    p.mimeTypes = "image/tga";
    version(decodePNG)
        p.loadProc = &loadTGA;
    else
        p.loadProc = null;
    version(encodePNG)
        p.saveProc = &saveTGA;
    else
        p.saveProc = null;
    p.detectProc = &detectTGA;
    return p;
}


version(decodePNG)
void loadTGA(ref Image image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    assert(false); // Not supported yet
}

bool detectTGA(IOStream *io, IOHandle handle) @trusted
{
    // TODO
    return false;
}

version(encodeTGA)
bool saveTGA(ref const(Image) image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    if (page != 0)
        return false;

    TGAEncoder encoder;

    bool enableRLE = true; // No real reason not to enable RLE.
    if (!encoder.initialize(io, handle, image._type, image._width, image._height, enableRLE))
    {
        return false;
    }

    // Encode scanline one by one, to allow conversion on write.
    for (int y = image._height - 1; y >= 0; --y)
    {
        if (!encoder.encodeScanline(image.scanptr(y)))
            return false;
    }

    return true;
}