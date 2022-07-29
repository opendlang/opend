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
import gamut.internals.types;

version(decodeQOIX)
{
    import gamut.codecs.qoi2avg;
    import gamut.codecs.qoiplane;
    import gamut.codecs.lz4;
}
else version(encodeQOIX)
{
    import gamut.codecs.qoi2avg;
    import gamut.codecs.qoi2plane;
    import gamut.codecs.lz4;
}

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

// IMPORTANT: QOIX uses two possible codecs internally
//   - "QOIX" in qoi2avg.d for RGB8 and RGBA8
//   - qoiplane for L8

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

    // TODO: put implicit layout constraint and then convert

    decoded = cast(ubyte*) qoix_lz4_decode(buf, len, &desc, requestedComp);

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

    if (desc.channels == 1)
        image._type = ImageType.uint8;
    else if (desc.channels == 2)
        image._type = ImageType.la8;
    else if (desc.channels == 3)
        image._type = ImageType.rgb8;
    else if (desc.channels == 4)
        image._type = ImageType.rgba8;
    else
    {
        // QOI with channel different from 1, 2, 3 or 4 is impossible.
        assert(false);
    }

    image._pitch = desc.channels * desc.width;
    image._pixelAspectRatio = desc.pixelAspectRatio;
    image._resolutionY = desc.resolutionY;

    // Convert to final requested type.

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
    desc.pixelAspectRatio = image._pixelAspectRatio;
    desc.resolutionY = image._resolutionY;

    switch (image._type)
    {
        case ImageType.uint8: desc.channels = 1; break;
        case ImageType.la8:   desc.channels = 2; break;
        case ImageType.rgb8:  desc.channels = 3; break;
        case ImageType.rgba8: desc.channels = 4; break;
        default: 
            return false; // not supported
    }
        
    int qoilen;

    ubyte* encoded = cast(ubyte*) qoix_lz4_encode(image._data, &desc, &qoilen);

    if (encoded == null)
        return false;
    scope(exit) free(encoded);

    // Write all output at once. This is rather bad, could be done progressively.
    // PERF: adapt qoi writer to output in our own buffer directly.
    if (qoilen != io.write(encoded, 1, qoilen, handle))
        return false;

    return true;
}



/// Encode in QOIX + LZ4
/// File format:
///   QOIX header (15 bytes)
///   Original data size (4 bytes)
///   LZ4 encoded opcodes
version(encodeQOIX)
ubyte* qoix_lz4_encode(const(ubyte)* data, const(qoi_desc)* desc, int *out_len) @trusted
{
    // Encode to QOIX
    int qoilen;
    ubyte* qoix;

    if (desc.channels == 1 || desc.channels == 2)
    {
        qoix = qoiplane_encode(data, desc, &qoilen);
    }
    else
    {
        qoix = qoix_encode(data, desc, &qoilen);
    }

    if (qoix is null)
        return null;
    scope(exit) free(qoix);

    ubyte[] qoixHeader = qoix[0..QOIX_HEADER_SIZE];
    ubyte[] qoixData = qoix[QOIX_HEADER_SIZE..qoilen];
    int datalen = cast(int) qoixData.length;
    int maxsize = LZ4_compressBound(datalen);

    // Encode QOI in LZ4, except the header.

    ubyte* lz4Data = cast(ubyte*) malloc(QOIX_HEADER_SIZE + 4 + maxsize); 

    lz4Data[0..QOIX_HEADER_SIZE] = qoix[0..QOIX_HEADER_SIZE];

    int p = QOIX_HEADER_SIZE;
    qoi_write_32(lz4Data, &p, datalen);

    int lz4Size = LZ4_compress(cast(const(char)*)&qoixData[0], 
                               cast(char*)&lz4Data[QOIX_HEADER_SIZE + 4], 
                               datalen);

    if (lz4Size < 0)
        return null;

    *out_len = QOIX_HEADER_SIZE + 4 + lz4Size;

    lz4Data = cast(ubyte*) realloc(lz4Data, *out_len); // realloc this to fit memory to actually used
    return lz4Data;
}

/// Decodes a QOIX + LZ4
/// File format:
///   QOIX header (15 bytes)
///   Original data size (4 bytes)
///   LZ4 encoded opcodes
version(decodeQOIX)
ubyte* qoix_lz4_decode(const(ubyte)* data, int size, qoi_desc *desc, int channels) @trusted
{
    assert(channels == 0); // only auto-detect

    if (size < QOIX_HEADER_SIZE + 4)
        return null;

    // Read original size of data.
    int p = QOIX_HEADER_SIZE;
    int orig = qoi_read_32(data, &p);

    if (orig < 0)
        return null; // too large, corrupted.

    // Allocate decoding buffer.
    ubyte* decQOIX = cast(ubyte*) malloc(QOIX_HEADER_SIZE + orig);

    decQOIX[0..QOIX_HEADER_SIZE] = data[0..QOIX_HEADER_SIZE];

    const(ubyte)[] lz4Data = data[QOIX_HEADER_SIZE + 4 ..size];

    int qoilen = LZ4_decompress_fast(cast(char*)&lz4Data[0], 
                                     cast(char*)&decQOIX[QOIX_HEADER_SIZE], 
                                     orig);

    if (qoilen < 0)
    {
        free(decQOIX);
        return null;
    }

    int streamChannels = decQOIX[13];
    ubyte* image;
    if (streamChannels == 1 || streamChannels == 2)
    {
        image = qoiplane_decode(decQOIX, QOIX_HEADER_SIZE + orig, desc, channels);
    }
    else if (streamChannels == 3 || streamChannels == 4)
    {        
        image = qoix_decode(decQOIX, QOIX_HEADER_SIZE + orig, desc, channels);
    }

    scope(exit) free(decQOIX);

    return image;
}
