/**
GIF support.

Copyright: Copyright Guillaume Piolat 2023
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.plugins.gif;

nothrow @nogc @safe:

import core.stdc.stdlib: malloc, free, realloc;
import core.stdc.string: memcpy;
import gamut.types;
import gamut.io;
import gamut.plugin;
import gamut.image;
import gamut.internals.errors;
import gamut.internals.types;

version(decodeGIF) import gamut.codecs.gif;
version(encodeGIF) import gamut.codecs.msf_gif;


ImageFormatPlugin makeGIFPlugin()
{
    ImageFormatPlugin p;
    p.format = "GIF";
    p.extensionList = "gif";
    p.mimeTypes = "image/gif";
    version(decodeGIF)
        p.loadProc = &loadGIF;
    else
        p.loadProc = null;
    version(encodeGIF)
        p.saveProc = &saveGIF;
    else
        p.saveProc = null;
    p.detectProc = &detectGIF;
    return p;
}

bool detectGIF(IOStream *io, IOHandle handle) @trusted
{
    static immutable ubyte[6] gif87Signature = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61];
    if (fileIsStartingWithSignature(io, handle, gif87Signature))
        return true;

    static immutable ubyte[6] gif89Signature = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61];
    if (fileIsStartingWithSignature(io, handle, gif89Signature))
        return true;

    return false;
}


version(decodeGIF)
void loadGIF(ref Image image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{ 
    {
        // Note: in that first opening, the whole file is scanned to get the number of frames.
        GIFDecoder decoder;
        bool err;
        decoder.open(io, handle, &err);
        if (err)
        {
            image.error(kStrImageDecodingFailed);
            return;
        }

        image._resolutionY = GAMUT_UNKNOWN_RESOLUTION;
        image._pixelAspectRatio = decoder.getPixelAspectRatio();

        // TODO: store decoder.FPS() somewhere, need metadata

        // Create destination image.
        // MAYDO: could use scanline conversion to create directly in l8/la8/rgb8, but limited value.
        image.createLayeredNoInit(decoder.width,
                                  decoder.height,
                                  decoder.numLayers,
                                  PixelType.rgba8,
                                  cast(LayoutConstraints) flags);

        for (int layerIndex = 0; layerIndex < decoder.numLayers; ++layerIndex)
        {
            bool gotOneFrame;
            int dummy;
            Image layerN = image.layer(layerIndex);
            decoder.decodeNextFrame(&gotOneFrame, 
                                    &layerN,
                                    &dummy,
                                    &err);
            if (err || !gotOneFrame)
            {
                image.error(kStrImageDecodingFailed);
                return;
            }
        }

    } // clear decoder

    // Convert to target type and constraints.
    image.convertTo(applyLoadFlags(image._type, flags), cast(LayoutConstraints) flags);
}

version(encodeGIF)
bool saveGIF(ref const(Image) image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    if (page != 0)
        return false;

    MsfGifState gifState;    
    if (!msf_gif_begin(&gifState, image.width, image.height))
        return false;

    // 0-frames .gif not supported (not sure if possible)
    if (image.layers == 0)
        return false;

    // Only pixelType rgba8 is supported!
    PixelType type = image.type();
    if (type != PixelType.rgba8)
        return false;

    // MAYDO: could support more types by converting scanlines on-the-fly?
 
    for (int layerIndex = 0; layerIndex < image.layers; ++layerIndex)
    {
        const(Image) layer = image.layer(layerIndex);

        const(ubyte)* pixelData = cast(const(ubyte)*)layer.scanptr(0);
        int centiSecondsPerFame = 7;
        int maxBitDepth = 16;
        int pitchInBytes = image.pitchInBytes();
        if (!msf_gif_frame(&gifState, pixelData, centiSecondsPerFame, maxBitDepth, pitchInBytes))
        {
            return false;
        }
    }
    MsfGifResult result = msf_gif_end(&gifState);

    // PERF: pass IO directly, use that to write data
    if (1 != io.write(result.data, result.dataSize, 1, handle))
        return false;

    msf_gif_free(result);
    return true;
}