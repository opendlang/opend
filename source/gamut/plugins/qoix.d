/**
QOIX support.
This is "living standard" format living in Gamut that tries to improve upon QOI.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.plugins.qoix;

nothrow @nogc @safe:

import core.stdc.stdlib: malloc, free, realloc;
import core.stdc.string: memcpy;
import gamut.types;
import gamut.io;
import gamut.image;
import gamut.plugin;
import gamut.internals.errors;

version = lz4EncodedQOIX;

version(decodeQOIX)
    import gamut.codecs.qoi2avg;
else version(encodeQOIX)
    import gamut.codecs.qoi2avg;

ImageFormatPlugin makeQOIXPlugin()
{
    ImageFormatPlugin p;
    p.format = "QOIX";
    p.extensionList = "qoix";

    p.mimeTypes = "image/qoix";

    version(decodeQOIX)
        p.loadProc = &loadQOIX;
    else
        p.loadProc = null;
    version(encodeQOIX)
        p.saveProc = &saveQOIX;
    else
        p.saveProc = null;
    p.detectProc = &detectQOIX;
    return p;
}


version(decodeQOIX)
void loadQOIX(ref Image image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    // Read all available bytes from input
    // This is temporary.

    // Find length of input
    if (io.seek(handle, 0, SEEK_END) != 0)
    {
        image.error(kStrImageDecodingIOFailure);
        return;
    }

    int len = io.tell(handle);

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
    if (requestedComp == -1)
        requestedComp = 0; // auto

    ubyte* decoded;
    qoi_desc desc;

    // read all input at once.
    if (len != io.read(buf, 1, len, handle))
    {
        image.error(kStrImageDecodingIOFailure);
        return;
    }

    version(lz4EncodedQOIX)        
        decoded = cast(ubyte*) qoix_lz4_decode(buf, len, &desc, requestedComp);
    else
        decoded = cast(ubyte*) qoix_decode(buf, len, &desc, requestedComp);

    if (decoded is null)
    {
        image.error(kStrImageDecodingFailed);
        return;
    }    

    if (!imageIsValidSize(desc.width, desc.height))
    {
        image.error(kStrImageTooLarge);
        free(decoded);
        return;
    }

    // TODO: support desc.colorspace information

    image._data = decoded;
    image._width = desc.width;
    image._height = desc.height;

    if (desc.channels == 3)
        image._type = ImageType.rgb8;
    else if (desc.channels == 4)
        image._type = ImageType.rgba8;
    else
    {
        // QOI with channel different from 3 or 4 is impossible.
        assert(false);
    }

    image._pitch = desc.channels * desc.width;
}


bool detectQOIX(IOStream *io, IOHandle handle) @trusted
{
    static immutable ubyte[4] qoixSignature = [0x71, 0x6f, 0x69, 0x78]; // "qoix"
    return fileIsStartingWithSignature(io, handle, qoixSignature);
}

version(encodeQOIX)
bool saveQOIX(ref const(Image) image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    if (page != 0)
        return false;

    qoi_desc desc;
    desc.width = image._width;
    desc.height = image._height;
    desc.pitchBytes = image._pitch;
    desc.colorspace = QOI_SRGB;
        
    switch (image._type)
    {
        case ImageType.rgb8:  desc.channels = 3; break;
        case ImageType.rgba8: desc.channels = 4; break;
        default: 
            return false; // not supported
    }
        
    int qoilen;

    version(lz4EncodedQOIX)        
        ubyte* encoded = cast(ubyte*) qoix_lz4_encode(image._data, &desc, &qoilen);
    else
        ubyte* encoded = cast(ubyte*) qoix_encode(image._data, &desc, &qoilen);

    if (encoded == null)
        return false;
    scope(exit) free(encoded);

    // Write all output at once. This is rather bad, could be done progressively.
    // PERF: adapt qoi writer to output in our own buffer directly.
    if (qoilen != io.write(encoded, 1, qoilen, handle))
        return false;

    return true;
}
