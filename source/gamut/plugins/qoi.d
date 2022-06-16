/**
Bridge FreeImage and QOI codec.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.plugins.qoi;

nothrow @nogc @safe:

import core.stdc.stdlib: malloc, free, realloc;
import core.stdc.string: memcpy;
import gamut.types;
import gamut.bitmap;
import gamut.io;
import gamut.image;
import gamut.plugin;
import gamut.internals.errors;

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
        p.loadProc = &Load_QOI;
    else
        p.loadProc = null;
    version(encodeQOI)
        p.saveProc = &Save_QOI;
    else
        p.saveProc = null;
    p.detectProc = &Validate_QOI;
    return p;
}


version(decodeQOI)
void Load_QOI(ref Image image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    // Read all available bytes from input
    // PERF: qoi_decode should understand IOStream directly.
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
        
    decoded = cast(ubyte*) qoi_decode(buf, len, &desc, requestedComp);
    if (decoded is null)
    {
        image.error(kStrImageDecodingFailed);
        return;
    }    

    if (desc.width > GAMUT_MAX_IMAGE_WIDTH || desc.height > GAMUT_MAX_IMAGE_HEIGHT)
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


bool Validate_QOI(IOStream *io, IOHandle handle) @trusted
{
    static immutable ubyte[4] qoiSignature = [0x71, 0x6f, 0x69, 0x66]; // "qoif"
    return fileIsStartingWithSignature(io, handle, qoiSignature);
}

version(encodeQOI)
bool Save_QOI(ref const(Image) image, IOStream *io, IOHandle handle, int page, int flags, void *data) @trusted
{
    if (page != 0)
        return false;

    qoi_desc desc;
    desc.width = image._width;
    desc.height = image._height;
    desc.colorspace = QOI_SRGB; // TODO: support other colorspace somehow, or at least fail if not SRGB
        
    switch (image._type)
    {
        case ImageType.rgb8:  desc.channels = 3; break;
        case ImageType.rgba8: desc.channels = 4; break;
        default: 
            return false; // not supported
    }

    // PERF: remove that intermediate copy, whose sole purpose is being gap-free
    //       the qoi encoder cannot read pixel using a pitch
    // <temp>
    int len = desc.width * desc.height * desc.channels;
    ubyte* continuous = cast(ubyte*) malloc(len);
    if (!continuous)
        return false;
    scope(exit) free(continuous);
    // removes holes
    for (int y = 0; y < desc.height; ++y)
    {
        const(ubyte)* source = image._data + y * image._pitch;
        ubyte* dest   = continuous + y * desc.width * desc.channels;
        int lineBytes = desc.channels * desc.width;
        memcpy(dest, source, lineBytes);
    }
    // </temp>
        
    int qoilen;
    ubyte* encoded = cast(ubyte*) qoi_encode(continuous, &desc, &qoilen);
    if (encoded == null)
        return false;
    scope(exit) free(encoded);

    // Write all output at once. This is rather bad, could be done progressively.
    // PERF: adapt qoi writer to output in our own buffer directly.
    if (qoilen != io.write(encoded, 1, qoilen, handle))
        return false;

    return true;
}
