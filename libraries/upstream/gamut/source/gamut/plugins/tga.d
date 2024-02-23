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
    version(decodeTGA)
        p.loadProc = &loadTGA;
    else
        p.loadProc = null;
    version(encodeTGA)
        p.saveProc = &saveTGA;
    else
        p.saveProc = null;
    p.detectProc = &detectTGA;
    return p;
}


version(decodeTGA)
void loadTGA(ref Image image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    TGADecoder decoder;
    if (!decoder.initialize(io, handle))
    {
        image.error(kStrImageDecodingFailed);
        return;
    }
    
    if (!decoder.getImageInfo())
    {
        image.error(kStrImageDecodingFailed);
        return;
    }

    if (!imageIsValidSize(1, decoder._width, decoder._height))
    {
        image.error(kStrImageTooLarge);
        return;
    }

    // Allocate space for loaded image, following constraints.
    int decodedComponents;
    ubyte* decoded = decoder.decodeImage(&decodedComponents);

    if (decoded is null)
    {
        image.error(kStrImageDecodingFailed);
        return;
    }

    if (decodedComponents == 1)
        image._type = PixelType.l8;
    else if (decodedComponents == 2)
        image._type = PixelType.la8;
    else if (decodedComponents == 3)
        image._type = PixelType.rgb8;
    else if (decodedComponents == 4)
        image._type = PixelType.rgba8;

    image._width = decoder._width;
    image._height = decoder._height;
    image._allocArea = decoded;
    image._data = decoded;
    image._pitch = decoder._width * decodedComponents;
    image._pixelAspectRatio = GAMUT_UNKNOWN_ASPECT_RATIO;
    image._resolutionY = GAMUT_UNKNOWN_RESOLUTION;
    image._layoutConstraints = LAYOUT_DEFAULT;
    image._layerCount = 1;
    image._layerOffset = 0;

    // Convert to target type and constraints
    image.convertTo(applyLoadFlags(image._type, flags), cast(LayoutConstraints) flags);
}

bool detectTGA(IOStream *io, IOHandle handle) @trusted
{
    version(decodeTGA)
    {
        // save I/O cursor
        c_long offset = io.tell(handle);

        bool res = false;
        {
            TGADecoder decoder;
            if (decoder.initialize(io, handle))
            {
                res = decoder.getImageInfo();
            }
        }

        // restore I/O cursor
        if (!io.seekAbsolute(handle, offset))
        {
            // TODO: that rare error should propagate somehow, 
            // we couldn't reset the cursor hence more detection will fail.
            return false; 
        }
        return res;
    }
    else
    {
        return false;
    }
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