/**
Memory streams.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.memory;

import core.stdc.stdlib;
import gamut.types;
import gamut.bitmap;

nothrow @nogc @safe:

// TODO: provide ability to provide the FIMEMORY? To avoid an allocation.


/// Called memory-file in FreeImage 
/// This is basically an owned buffer, with capacity, optionally borrowed.
struct FIMEMORY
{
    // If the memory is owned by FIMEMORY, or borrowed.
    bool owned = false;

    // If can only read from buffer.
    bool readOnly = false;

    // Pointer to data (owned or borrowed).
    // if owned, the buffer is allocated with malloc/free/realloc
    ubyte* data = null;

    // Length of buffer.
    size_t bytes = 0;
}


/// Open a memory stream. The function returns a pointer to the opened memory stream.
/// When called with default arguments (null), this function opens a memory stream for read/write
/// access. The stream will support loading and saving of FIBITMAP in a memory file (managed 
/// internally by FreeImage). It will also support seeking and telling in the memory file. 
/// This function can also be used to wrap a memory buffer provided by the application driving
/// FreeImage. A buffer containing image data is given as function arguments `data` (start of the 
/// and size_in_bytes (buffer size in bytes). A memory buffer wrapped by FreeImage is 
/// read only. Images can be loaded but cannot be saved.                                                                    buffer) and size_in_bytes (buffer size in bytes). A memory buffer wrapped by FreeImage is 
FIMEMORY* FreeImage_OpenMemory(const(ubyte)* data = null, size_t size_in_bytes = 0) @system
{
    FIMEMORY* stream = cast(FIMEMORY*) malloc(FIMEMORY.sizeof);
    if (stream is null)
        return stream;

    *stream = FIMEMORY.init;
    if (data == null)
    {
        stream.owned = true;
        return stream;
    }
    else
    {
        stream.owned = false;
        stream.readOnly = true;
        stream.data = cast(ubyte*) data; // const_cast here
        stream.bytes = size_in_bytes;
    }
    return stream;
}

/// Close and free an opened memory stream. 
/// When the stream is managed by FreeImage, the memory file is destroyed. Otherwise 
/// (wrapped buffer), it’s destruction is left to the application driving FreeImage.
/// You always need to call this function once you’re done with a memory stream 
/// (whatever the way you opened the stream), or you will have a memory leak.
void FreeImage_CloseMemory(FIMEMORY *stream) @system
{
    assert (stream !is null);
    if (stream.owned)
    {
        free(stream.data);
    }
    free(stream);
}

/// This function does for memory streams what FreeImage_Load does for file streams. 
/// FreeImage_LoadFromMemory decodes a bitmap, allocates memory for it and then returns it 
/// as a FIBITMAP. The first parameter defines the type of bitmap to be loaded. For example, 
/// when FIF_BMP is passed, a BMP file is loaded into memory (an overview of possible 
/// FREE_IMAGE_FORMAT constants is available in Table 1). The second parameter tells 
/// FreeImage the memory stream it has to decode. The last parameter is used to change the 
/// behaviour or enable a feature in the bitmap plugin. Each plugin has its own set of 
/// parameters.
/// Some bitmap loaders can receive parameters to change the loading behaviour. 
/// When the parameter is not available or unused you can pass the value 0 or 
/// <TYPE_OF_BITMAP>_DEFAULT (e.g. BMP_DEFAULT, ICO_DEFAULT, etc).
FIBITMAP* FreeImage_LoadFromMemory(FREE_IMAGE_FORMAT fif, FIMEMORY *stream, int flags = 0)
{
    assert(fif != FIF_UNKNOWN);
    if (stream is null)
        return null;       

  /*  FreeImageIO io;
    io.read = &FreeImage_ReadMemory;
    io.write = &FreeImage_WriteMemory;
    io.seek = &FreeImage_SeekMemory;
    io.tell = &FreeImage_TellMemory; */

    return FreeImage_LoadFromHandle(fif, &io, cast(fi_handle)f, flags);
}

// FreeImage_SaveToMemory

/// Provides a direct buffer access to a memory stream. Upon entry, stream is the target memory 
/// stream, returned value data is a pointer to the memory buffer, returned value size_in_bytes is 
/// the buffer size in bytes. The function returns TRUE if successful, FALSE otherwise.
/// This pointer is invalidated when you call `FreeImage_SaveToMemory`.
bool FreeImage_AcquireMemory(FIMEMORY *stream, ubyte** data, size_t* size_in_bytes)
{
    *data = stream.data;
    *size_in_byte = size_in_bytes;
    return true;
}

// FreeImage_TellMemory
// FreeImage_SeekMemory
// FreeImage_ReadMemory
// FreeImage_WriteMemory

// FreeImage_LoadMultiBitmapFromMemory
// FreeImage_SaveMultiBitmapToMemory