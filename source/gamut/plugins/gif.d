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

version(decodeGIF) import gamut.codecs.gifdec;
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
    gd_GIF* gif = gd_open_gif(io, handle);
    if (gif is null)
    {
        image.error(kStrImageDecodingFailed);
        return;
    }   

    int width = gif.width;
    int height = gif.height;

    // First check of width and height
    if (!imageIsValidSize(1, width, height))
    {
        image.error(kStrImageTooLarge);
        return;
    }

    int nFrames = 0;
    ubyte** pFrames = null; // vec of frame pointers
    size_t workbufSize = 3 * width * height;

    // PERF: we wouldn't need a vector of frame data here, if it was possible to add frames to an 
    // Image quickly. But realloc would be too expensive for large animations, also we have no
    // Image call that preserve pixel and yet resize.
    // Alternatively, a way to know number of frames in advance would be cool, probably too slow.

    void oneMoreFrameBuffer()
    {
        nFrames += 1;
        pFrames = cast(ubyte**) realloc(pFrames, (ubyte*).sizeof * nFrames);
        pFrames[nFrames-1] = cast(ubyte*) malloc(workbufSize); // Allocate a RGB buffer for every frame
    }

    void freeBufferVec()
    {
        if (pFrames)
        {
            foreach(int frameIndex; 0..nFrames)
            {
                free(pFrames[frameIndex]);
            }
            free(pFrames);
        }
    }
    scope(exit) freeBufferVec();

    ubyte* workbuf = cast(ubyte*) malloc(workbufSize);
    scope(exit) free(workbuf);


    while (true)
    {
        int res = gd_get_frame(gif);
        if (res == -1)
        {
            image.error(kStrImageDecodingFailed);
            return;
        }
        if (res == 0)
            break; // no more images

        oneMoreFrameBuffer();

        assert(nFrames > 0);
        assert(pFrames !is null);
        assert(pFrames[nFrames-1] !is null);

        gd_render_frame(gif, workbuf);
        memcpy(pFrames[nFrames-1], workbuf, workbufSize);
    }
    
    // Create result image, now that we have all data and number of layers.
    image.createLayeredNoInit(width, 
                              height, 
                              nFrames, 
                              PixelType.rgba8,
                              cast(LayoutConstraints) flags);
    if (image.isError)
        return;

    for (int layerIndex = 0; layerIndex < nFrames; ++layerIndex)
    {
        Image layerN = image.layer(layerIndex);
        Image rawDecoded;
        rawDecoded.createViewFromData(pFrames[layerIndex], width, height, PixelType.rgb8, width*3);

        for (int y = 0; y < height; ++y)
        {
            ubyte* pSourceRGB = cast(ubyte*) rawDecoded.scanptr(y);
            ubyte* pDestRGBA  = cast(ubyte*) layerN.scanptr(y);

            for (int x = 0; x < width; ++x)
            {
                pDestRGBA[4*x+0] = pSourceRGB[3*x+0];
                pDestRGBA[4*x+1] = pSourceRGB[3*x+1];
                pDestRGBA[4*x+2] = pSourceRGB[3*x+2];

                // Convert transparent color to alpha = 0 (alpha = 255 else)
                if (gd_is_bgcolor(gif, &pSourceRGB[3*x]))
                {
                    pDestRGBA[4*x+3] = 0;
                }
                else
                {
                    pDestRGBA[4*x+3] = 255;
                }
            }
        }
    }

    gd_close_gif(gif);

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

        const(ubyte)* pixelData = cast(const(ubyte)*)image.scanptr(0);
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