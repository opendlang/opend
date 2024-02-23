/**
QOI support.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.plugins.qoi;

nothrow @nogc @safe:

import core.stdc.stdlib: malloc, free, realloc;
import core.stdc.string: memcpy;
import gamut.types;
import gamut.io;
import gamut.image;
import gamut.plugin;
import gamut.internals.errors;
import gamut.internals.types;

version(decodeQOI)
    import gamut.codecs.qoi;
else version(encodeQOI)
    import gamut.codecs.qoi;

ImageFormatPlugin makeQOIPlugin()
{
    ImageFormatPlugin p;
    p.format = "QOI";
    p.extensionList = "qoi";

    // Discussion: https://github.com/phoboslab/qoi/issues/167#issuecomment-1117240154
    p.mimeTypes = "image/qoi";

    version(decodeQOI)
        p.loadProc = &loadQOI;
    else
        p.loadProc = null;
    version(encodeQOI)
        p.saveProc = &saveQOI;
    else
        p.saveProc = null;
    p.detectProc = &detectQOI;
    return p;
}


version(decodeQOI)
void loadQOI(ref Image image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    // Read all available bytes from input
    // This is temporary.

    // Find length of input
    if (io.seek(handle, 0, SEEK_END) != 0)
    {
        image.error(kStrImageDecodingIOFailure);
        return;
    }

    int len = cast(int) io.tell(handle); // works, see io.d for why

    if (!io.rewind(handle))
    {
        image.error(kStrImageDecodingIOFailure);
        return;
    }

    ubyte* buf = cast(ubyte*) malloc(len);
    if (buf is null)
    {
        image.error(kStrImageDecodingMallocFailure);
        return;
    }
    scope(exit) free(buf);

    int requestedComp = computeRequestedImageComponents(flags);
    if (requestedComp == 0) // error
    {
        image.error(kStrInvalidFlags);
        return;
    }

    // QOI decoder can't decode to greyscale or greyscale + alpha, but it can decode to RGB/RGBA
    if (requestedComp == -1 || requestedComp == 1 || requestedComp == 2)
        requestedComp = 0; // auto

    ubyte* decoded;
    qoi_desc desc;

    // read all input at once.
    if (len != io.read(buf, 1, len, handle))
    {
        image.error(kStrImageDecodingIOFailure);
        return;
    }
        
    decoded = cast(ubyte*) qoi_decode(buf, len, &desc, requestedComp);
    assert(decoded);
    if (decoded is null)
    {
        image.error(kStrImageDecodingFailed);
        return;
    }    

    if (!imageIsValidSize(1, desc.width, desc.height))
    {
        image.error(kStrImageTooLarge);
        free(decoded);
        return;
    }

    // TODO: support desc.colorspace information

    image._allocArea = decoded;
    image._data = decoded;
    image._width = desc.width;
    image._height = desc.height;

    int decodedComp = (requestedComp == 0) ? desc.channels : requestedComp;

    if (decodedComp == 3)
        image._type = PixelType.rgb8;
    else if (decodedComp == 4)
        image._type = PixelType.rgba8;
    else
    {
        // QOI with channel different from 3 or 4 is impossible.
        assert(false);
    }

    image._pitch = desc.channels * desc.width;
    image._pixelAspectRatio = GAMUT_UNKNOWN_ASPECT_RATIO;
    image._resolutionY = GAMUT_UNKNOWN_RESOLUTION;
    image._layoutConstraints = 0; // no particular constraint followed in QOI decoder.
    image._layerCount = 1;
    image._layerOffset = 0;

    // Convert to target type and constraints
    image.convertTo(applyLoadFlags(image._type, flags), cast(LayoutConstraints) flags);
}


bool detectQOI(IOStream *io, IOHandle handle) @trusted
{
    static immutable ubyte[4] qoiSignature = [0x71, 0x6f, 0x69, 0x66]; // "qoif"
    return fileIsStartingWithSignature(io, handle, qoiSignature);
}

version(encodeQOI)
bool saveQOI(ref const(Image) image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    if (page != 0)
        return false;

    qoi_desc desc;
    desc.width = image._width;
    desc.height = image._height;
    desc.pitchBytes = image._pitch;
    desc.colorspace = QOI_SRGB; // FUTURE: support other colorspace somehow, or at least fail if not SRGB
        
    switch (image._type)
    {
        case PixelType.rgb8:  desc.channels = 3; break;
        case PixelType.rgba8: desc.channels = 4; break;
        default: 
            {
                int a = 0;
                return false; // not supported
            }
    }
        
    int qoilen;
    ubyte* encoded = cast(ubyte*) qoi_encode(image._data, &desc, &qoilen);
    if (encoded == null)
        return false;
    scope(exit) free(encoded);

    // Write all output at once. This is rather bad, could be done progressively.
    // PERF: adapt qoi writer to output in our own buffer directly.
    if (qoilen != io.write(encoded, 1, qoilen, handle))
        return false;

    return true;
}
