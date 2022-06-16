/**
Bitmap management and information functions.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.bitmap;

import core.stdc.stdio;
import core.stdc.string: memcpy;
import core.stdc.stdlib: malloc, realloc, free;
import gamut.types;
import gamut.io;
import gamut.image;
import gamut.plugin;
import gamut.internals.cstring;
import gamut.internals.errors;


nothrow @nogc @safe:


void FreeImage_LoadFromMemory(ref Image image, ImageFormat fif, MemoryFile *stream, int flags = 0) @trusted
{
    assert(fif != ImageFormat.unknown);
    assert (stream !is null);

    IOStream io;
    io.setupForMemoryIO();
    FreeImage_LoadFromHandle(image, fif, &io, cast(IOHandle)stream, flags);
}

bool FreeImage_SaveToMemory(ref const(Image) image, ImageFormat fif, MemoryFile *stream, int flags = 0) @trusted
{
    assert(fif != ImageFormat.unknown);
    assert (stream !is null);

    IOStream io;
    io.setupForMemoryIO();

    return FreeImage_SaveToHandle(image, fif, &io, cast(IOHandle)stream, flags);
}

void FreeImage_Load(ref Image image, ImageFormat fif, const(char)* filename, int flags = 0) @system
{
    assert(fif != ImageFormat.unknown);
    
    FILE* f = fopen(filename, "rb");
    if (f is null)
    {
        image.error(kStrCannotOpenFile);
        return;
    }

    IOStream io;
    io.setupForFileIO();
    FreeImage_LoadFromHandle(image, fif, &io, cast(IOHandle)f, flags);
    
    if (0 != fclose(f))
    {
        // TODO cleanup BITMAP/Image
        //FreeImage_Unload(image);
        image.error(kStrFileCloseFailed);
    }
}

void FreeImage_LoadFromHandle(ref Image image, ImageFormat fif, IOStream* io, IOHandle handle, int flags = 0) @system
{
    // By loading an image, we agreed to forget about past mistakes.
    image.clearError();

    if (fif == ImageFormat.unknown)
    {
        image.error(kStrImageFormatUnidentified);
        return;
    }

    const(ImageFormatPlugin)* plugin = &g_plugins[fif];   

    int page = 0;
    void *data = null;
    if (plugin.loadProc is null)
    {        
        image.error(kStrImageFormatNoLoadSupport);
        return;
    }
    plugin.loadProc(image, io, handle, page, flags, data);
}

bool FreeImage_Save(ref const(Image) image, ImageFormat fif, const(char)* filename, int flags = 0) @trusted
{
    if (!image.hasPlainPixels)
        return false; // no data that is pixels, impossible to save that.

    assert(fif != ImageFormat.unknown);

    FILE* f = fopen(filename, "wb");
    if (f is null)
        return false;

    IOStream io;
    io.setupForFileIO();
    bool r = FreeImage_SaveToHandle(image, fif, &io, cast(IOHandle)f, flags);
    return fclose(f) == 0;
}

bool FreeImage_SaveToHandle(ref const(Image) image, ImageFormat fif, IOStream *io, IOHandle handle, int flags = 0) @trusted
{
    const(ImageFormatPlugin)* plugin = &g_plugins[fif];
    void* data = null; // probably exist to pass metadata stuff
    if (plugin.saveProc is null)
        return false;
    bool r = plugin.saveProc(image, io, handle, 0, flags, data);
    return r;
}






// ================================================================================================
//
//                                           INTERNALS
//
// ================================================================================================


private:
