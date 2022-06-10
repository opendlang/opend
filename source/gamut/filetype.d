/**
File type detection.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.filetype;

/// The following functions retrieve the FREE_IMAGE_FORMAT from a bitmap by reading up to 
/// 16 bytes and analysing it.
/// Note that for some bitmap types no FREE_IMAGE_FORMAT can be retrieved. This has to do 
/// with the bit-layout of the bitmap-types, which are sometimes not compatible with FreeImage’s 
/// file-type retrieval system.
/// However, these formats can be identified using the `FreeImage_GetFIFFromFilename`
/// function.

import core.stdc.stdio;

import gamut.types;
import gamut.io;
import gamut.memory;
import gamut.plugin;


nothrow @nogc @safe:


/// Orders FreeImage to analyze the bitmap signature. The function then returns one of the 
/// predefined FREE_IMAGE_FORMAT constants or a bitmap identification number registered 
/// by a plugin. The size parameter is currently not used and can be set to 0.
ImageFormat FreeImage_GetFileType(const(char)*filename, int size = 0) @trusted // Note: size unused
{
    FILE* f = fopen(filename, "rb");
    if (f is null)
        return ImageFormat.unknown;
    FreeImageIO io;
    setupFreeImageIOForFile(io);
    ImageFormat type = FreeImage_GetFileTypeFromHandle(&io, cast(fi_handle)f, size);    
    fclose(f); // TODO: Note sure what to do if fclose fails here.
    return type;
}

/// Uses the FreeImageIO structure as described in the topic Bitmap management functions to 
/// identify a bitmap type. Now the bitmap bits are retrieved from an arbitrary place.
ImageFormat FreeImage_GetFileTypeFromHandle(FreeImageIO *io, fi_handle handle, int size = 0) // Note: size unnused
{
    for (ImageFormat fif = ImageFormat.first; fif <= ImageFormat.max; ++fif)
    {
        if (FreeImage_ValidateFromHandle(fif, io, handle))
            return fif;
    }
    return ImageFormat.unknown;
}

/// Uses a memory handle to identify a bitmap type. The bitmap bits are retrieved from an 
/// arbitrary place (see the chapter on Memory I/O streams for more information on memory 
/// handles)
ImageFormat FreeImage_GetFileTypeFromMemory(FIMEMORY* stream, int size = 0) @trusted // Note: size unnused
{
    assert (stream !is null);
    FreeImageIO io;
    setupFreeImageIOForMemory(io);
    return FreeImage_GetFileTypeFromHandle(&io, cast(fi_handle)stream, size);
}

/// Orders FreeImage to read the bitmap signature and compare this signature to the input fif 
/// `FREE_IMAGE_FORMAT`. The function then returns TRUE if the bitmap signature 
/// corresponds to the input `FREE_IMAGE_FORMAT` constant.
bool FreeImage_Validate(ImageFormat fif, const(char)* filename) @trusted
{
    FILE* f = fopen(filename, "rb");
    if (f is null)
        return false;

    FreeImageIO io;
    setupFreeImageIOForFile(io);
    bool b = FreeImage_ValidateFromHandle(fif, &io, cast(fi_handle)f);
    fclose(f); // TODO: Note sure what to do if fclose fails here.
    return b;
}

deprecated("Use FreeImage_Validate instead, it supports Unicode") alias FreeImage_ValidateU = FreeImage_Validate;

bool FreeImage_ValidateFromHandle(ImageFormat fif, FreeImageIO *io, fi_handle handle)
{
    assert(fif != ImageFormat.unknown);
    Plugin* plugin = FreeImage_PluginAcquireForReading(fif);
    if (plugin)
    {
        scope(exit) FreeImage_PluginRelease(plugin);
        if (plugin.validateProc(io, handle))
            return true;
    }
    return false;
}

/// Uses a memory handle to identify a bitmap type.
bool FreeImage_ValidateFromMemory(ImageFormat fif, FIMEMORY* stream) @trusted
{
    assert (stream !is null);
    FreeImageIO io;
    setupFreeImageIOForMemory(io);
    return FreeImage_ValidateFromHandle(fif, &io, cast(fi_handle)stream);
}
