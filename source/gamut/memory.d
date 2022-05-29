/**
Memory streams.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.memory;

import core.stdc.stdlib;
import core.stdc.string: memcpy;
import gamut.types;
import gamut.bitmap;
import gamut.io;

nothrow @nogc @safe:


// TODO: provide ability to provide the FIMEMORY location? To avoid an allocation.


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

    // Current pointer in the buffer.
    size_t offset = 0;
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
        *stream = FIMEMORY.init; // poison data
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
FIBITMAP* FreeImage_LoadFromMemory(FREE_IMAGE_FORMAT fif, FIMEMORY *stream, int flags = 0) @trusted
{
    assert(fif != FIF_UNKNOWN);
    assert (stream !is null);

    FreeImageIO io;
    setupFreeImageIOForMemory(io);

    return FreeImage_LoadFromHandle(fif, &io, cast(fi_handle)stream, flags);
}

/// This function does for memory streams what FreeImage_Save does for file streams. 
/// `FreeImage_SaveToMemory` saves a previously loaded `FIBITMAP` to a memory file managed 
/// by FreeImage. The first parameter defines the type of the bitmap to be saved. For example, 
/// when `FIF_BMP` is passed, a BMP file is saved. The second parameter is the 
/// memory stream where the bitmap must be saved. When the memory file pointer point to the 
/// beginning of the memory file, any existing data is overwritten. Otherwise, you can save 
/// multiple images on the same stream.
bool FreeImage_SaveToMemory(FREE_IMAGE_FORMAT fif, FIBITMAP *dib, FIMEMORY *stream, int flags = 0) @trusted
{
    assert(fif != FIF_UNKNOWN);
    assert (stream !is null);

    FreeImageIO io;
    setupFreeImageIOForMemory(io);

    return FreeImage_SaveToHandle(fif, dib, &io, cast(fi_handle)stream, flags);
}

/// Provides a direct buffer access to a memory stream. Upon entry, stream is the target memory 
/// stream, returned value data is a pointer to the memory buffer, returned value size_in_bytes is 
/// the buffer size in bytes. The function returns TRUE if successful, FALSE otherwise.
/// This pointer is invalidated when you call `FreeImage_SaveToMemory`.
bool FreeImage_AcquireMemory(FIMEMORY *stream, ubyte** data, size_t* size_in_bytes)
{
    assert(stream);
    *data = stream.data;
    *size_in_bytes = stream.bytes;
    return true;
}

extern(C)
{

    /// Gets the current position of a memory pointer. Upon entry, stream is the target memory 
    /// stream. The function returns the current file position if successful, -1 otherwise.
    c_long FreeImage_TellMemory(FIMEMORY *stream) @system
    {
        assert (stream !is null);

        // Files larger than 0x7fffffff bytes not supported, return errors.
        if (stream.offset > GAMUT_MAX_POSSIBLE_MEMORY_OFFSET)
            return -1;

        return cast(c_long) stream.offset;
    }

    /// Moves the memory pointer to a specified location. 
    /// The `FreeImage_SeekMemory` function moves the memory file pointer (if any) associated with 
    /// stream to a new location that is offset bytes from origin. The next operation on the stream 
    /// takes place at the new location. On a stream managed by Gamut, the next operation can 
    /// be either a read or a write.
    ///
    /// Params:
    ///     stream Pointer to the target memory stream.
    ///     offset Number of bytes from origin.
    ///     origin Initial position. Must be `SEEK_CUR`, `SEEK_END`, or `SEEK_SET`.
    /// 
    /// Returns: `true` if successful.
    int FreeImage_SeekMemory(FIMEMORY *stream, c_long offset, int origin) @system
    {
        assert (stream !is null);

        long baseOffset;
        if (origin == SEEK_CUR)
        {
            baseOffset = stream.offset;
        }
        else if (origin == SEEK_END)
        {
            baseOffset = stream.bytes;
        }
        else if (origin == SEEK_SET)
        {
            baseOffset = 0;
        }
        long newOffset = baseOffset + offset;
        assert(newOffset < cast(long)GAMUT_MAX_POSSIBLE_MEMORY_OFFSET);

        // It is valid to seek from 0 to bytes.
        //  0________________N-1 N      N+1
        //  ^ ok                 ^ ok   ^ not ok
        bool success = newOffset >= 0 && newOffset <= stream.bytes;
    
        if (!success)
            return -1;

        stream.offset = newOffset;
        return 0;
    }

    /// Reads data from a memory stream.
    /// The `FreeImage_ReadMemory` function reads up to `count` items of `size` bytes from the input 
    /// memory stream and stores them in buffer. The memory pointer associated with stream is 
    /// increased by the number of bytes actually read. 
    /// The function returns the number of full items actually read, which may be less than `count` if an 
    /// error occurs or if the end of the stream is encountered before reaching count. 
    size_t FreeImage_ReadMemory(void *buffer, size_t size, size_t count, FIMEMORY *stream) @system
    {
        assert (stream !is null);

        size_t available = stream.bytes - stream.offset;
        assert (available >= 0); // cursor not allowed to be after eof

        assert(size <= GAMUT_MAX_POSSIBLE_SIMULTANEOUS_READ);
        assert(count <= GAMUT_MAX_POSSIBLE_SIMULTANEOUS_READ);
        long needed = cast(long)size * cast(long)count; // won't overflow

        assert(needed <= GAMUT_MAX_POSSIBLE_SIMULTANEOUS_READ);

        size_t toRead;
        if (available >= needed)
            toRead = count;
        else
            toRead = available / size;

        size_t bytes = toRead * cast(size_t)size;
        memcpy(buffer, &stream.data[stream.offset], bytes);
        stream.offset += bytes;
        return toRead;
    }

    // TODO FreeImage_WriteMemory

}

// FreeImage_LoadMultiBitmapFromMemory
// FreeImage_SaveMultiBitmapToMemory


package:


void setupFreeImageIOForMemory(ref FreeImageIO io) pure @trusted
{
    io.read  = cast(ReadProc)  &FreeImage_ReadMemory;
    io.write = cast(WriteProc) null;
    io.seek  = cast(SeekProc)  &FreeImage_SeekMemory;
    io.tell  = cast(TellProc)  &FreeImage_TellMemory;
    io.eof   = cast(EofProc)   &FreeImage_EofMemory;
}

// Return internal data pointer (allocated with malloc/free)
// stream doesn't own it anymore, the caller does instead.
ubyte[] FreeImage_ReleaseMemory(FIMEMORY *stream) @trusted
{
    assert (stream !is null);
    if (stream.owned)
    {
        stream.owned = false;
        ubyte* data = stream.data;
        if (data is null)
            return null;
        stream.data = null;
        return data[0..stream.bytes];
    }
    else
        return null;
}

private:

extern(C)
{
    int FreeImage_EofMemory(FIMEMORY *stream) @system
    {
        assert(stream);
        return (stream.offset >= stream.bytes) ? 1 : 0;
    }
}