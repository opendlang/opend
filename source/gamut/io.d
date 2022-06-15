/**
I/O streams in FreeImage.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.io;

import core.stdc.stdio;
import core.stdc.string: memcpy;
import core.stdc.stdlib: malloc, free;
public import core.stdc.config: c_long;
public import core.stdc.stdio: SEEK_SET, SEEK_CUR, SEEK_END;

nothrow @nogc:


// Limits of I/O in gamut.
// This is because FreeImage callbakcs are modelled upon C stdlib functions, some of those use c_long or int.
enum size_t GAMUT_MAX_POSSIBLE_MEMORY_OFFSET = 0x7fff_ffff;       /// Can't open file larger than this much bytes
enum size_t GAMUT_MAX_POSSIBLE_SIMULTANEOUS_READ = 0x7fff_ffff;   /// Can't read more bytes than this at once
enum size_t GAMUT_MAX_POSSIBLE_SIMULTANEOUS_WRITE = 0x7fff_ffff;  /// Can't write more bytes than this at once



// Note: those function pointers made to be binary compatible with ftell/fseek/fwrite/fread/feof.
extern(C) @system
{
    /// A function with same signature and semantics than `fread`.
    ///
    /// Some details from the Linux man pages:
    ///
    /// "On success, fread() and fwrite() return the number of items read
    ///  or written.  This number equals the number of bytes transferred
    ///  only when size is 1.  If an error occurs, or the end of the file
    ///  is reached, the return value is a short item count (or zero).
    ///
    ///  The file position indicator for the stream is advanced by the
    ///  number of bytes successfully read or written.
    ///
    ///  fread() does not distinguish between end-of-file and error, and
    ///  callers must use feof() and ferror() to determine which
    ///  occurred. (well, ferror not available in gamut).
    ///
    /// Params:
    ///    buffer Where to read. Must be able to hold `size` * `count` bytes.
    ///    size Size of elements to read in stream.
    ///    count Number of elements to read in stream.
    ///
    /// Returns: 
    ///    Number of item successfully read. If return value != `count`, there was an error.
    ///
    /// Limitations: it is forbidden to ask more than 0x7fffffff bytes at once.
    alias ReadProc = size_t function(void* buffer, size_t size, size_t count, IOHandle handle);

    /// A function with same signature and semantics than `fwrite`.
    alias WriteProc = size_t function(const(void)* buffer, size_t size, size_t count, IOHandle handle);

    /// A function with same signature and semantics than `fseek`.
    /// Origin: position from which offset is added
    ///   SEEK_SET = beginning of file.
    ///   SEEK_CUR = Current position of file pointer.
    ///   SEEK_END = end of file.
    /// This function returns zero if successful, or else it returns a non-zero value.
    alias SeekProc = int function(IOHandle handle, c_long offset, int origin);

    /// A function with same signature and semantics than `ftell`.
    /// Tells where we are in the file. -1 if error.
    alias TellProc = c_long function(IOHandle handle);

    /// A function with same signature and semantics than `feof`.
    /// From Linux man:
    /// "The function `feof()` tests the end-of-file indicator for the stream pointed to by stream, 
    ///  returning nonzero if it is set."
    alias EofProc = int function(IOHandle handle);
}


/// Can be a `FILE*` handle, a `FIMEMORY`, a `WrappedIO`...
/// identifies the I/O stream.
alias IOHandle = void*;

/// I/O abstraction, to support load/write from a file, from memory, or from user-provided callbacks.
struct IOStream
{
nothrow @nogc @safe:

    /// A function with semantics and signature similar to `fread`.
    ReadProc  read;

    /// A function with semantics and signature similar to `fwrite`.
    WriteProc write;

    /// A function with semantics and signature similar to `fseek`.
    SeekProc  seek;

    /// A function with semantics and signature similar to `ftell`.
    TellProc  tell;

    /// A function with semantics and signature similar to `feof`.
    EofProc   eof;

    /// Skip bytes.
    /// Returns: true if it was possible to skip those bytes. false if there was an I/O error, or end of file.
    /// Limitations: `nbytes` must be from 0 to 0x7fffffff
    bool skipBytes(IOHandle handle, int nbytes) nothrow @nogc @trusted
    {
        assert(nbytes >= 0 && nbytes <= GAMUT_MAX_POSSIBLE_SIMULTANEOUS_READ);
        return seek(handle, nbytes, SEEK_CUR) == 0;
    }

    /// Seek to beginning of the I/O stream.
    /// Returns: true if successful.
    bool rewind(IOHandle handle) nothrow @nogc @trusted
    {
        return seek(handle, 0, SEEK_SET) == 0;
    }

    /// Seek to asolute position in the I/O stream.
    /// Useful because some function need to preserve it.
    bool seekAbsolute(IOHandle handle, c_long offset) nothrow @nogc @trusted
    {
        return seek(handle, offset, SEEK_SET) == 0;
    }

package:

    /// Setup the IOStream for reading a file. The passed `IOHandle` will need to be a `FILE*`.
    /// For internal Gamut usage.
    void setupForFileIO() pure @trusted
    {
        read  = cast(ReadProc) &fread;
        write = cast(WriteProc) &fwrite;
        seek  = cast(SeekProc) &fseek;
        tell  = cast(TellProc) &ftell;
        eof   = cast(EofProc) &feof;
    }

    /// Setup the IOStream for using a  a file. The passed `IOHandle` will need to be a `FILE*`.
    /// For internal Gamut usage.
    void setupForMemoryIO() pure @trusted
    {
        read  = cast(ReadProc)  &mread;
        write = cast(WriteProc) null;
        seek  = cast(SeekProc)  &mseek;
        tell  = cast(TellProc)  &mtell;
        eof   = cast(EofProc)   &meof;
    }

    /// Setup the IOStream for wrapping another IOStream and logging what happens.
    /// The passed `IOHandle` will need to be a `WrappedIO`.
    /// For internal Gamut usage.
    debug void setupSetupForLogging(ref IOStream io) pure @trusted
    {
        io.read  = &debug_fread;
        io.write = &debug_fwrite;
        io.seek  = &debug_fseek;
        io.tell  = &debug_ftell;
        io.eof   = &debug_feof;
    }
}

debug package struct WrappedIO
{
    IOStream* wrapped; /// I/O object being wrapped.
    IOHandle handle;   /// Original handle.
}

package bool fileIsStartingWithSignature(IOStream *io, IOHandle handle, immutable ubyte[] signature)
{
    assert(signature.length <= 16);

    // save I/O cursor
    c_long offset = io.tell(handle);

    ubyte[16] header;
    bool enoughBytes = (signature.length == io.read(header.ptr, 1, signature.length, handle));
    bool match = enoughBytes && (signature == header[0..signature.length]);

    // restore I/O cursor
    if (!io.seekAbsolute(handle, offset))
        return false; // TODO: that rare error should propagate somehow

    return match;
}

debug extern(C) @system private
{
    // Note: these functions expect a `WrappedIO` to be passed as handle.
    import core.stdc.stdio;

    size_t debug_fwrite (const(void)* buffer, size_t size, size_t count, IOHandle handle)
    {
        WrappedIO* wio = cast(WrappedIO*) handle;
        printf("Write %lld elements of %lld bytes\n", count, size);
        size_t r = wio.wrapped.write(buffer, size, count, wio.handle);
        printf("  => written %lld elements\n", r);
        return r;
    }

    size_t debug_fread (void* buffer, size_t size, size_t count, IOHandle handle)
    {
        WrappedIO* wio = cast(WrappedIO*) handle;
        printf("Read %lld elements of %lld bytes\n", count, size);
        size_t r = wio.wrapped.read(buffer, size, count, wio.handle);
        printf("  => read %lld elements\n", r);
        return r;
    }

    int debug_fseek(IOHandle handle, c_long offset, int origin)
    {
        WrappedIO* wio = cast(WrappedIO*) handle;
        printf("Seek to offset %d, mode %d\n", offset, origin);
        int r = wio.wrapped.seek(wio.handle, offset, origin);
        if (r == 0)
            printf("  => success\n", r);
        else
            printf(" => failure\n");
        return r;
    }

    c_long debug_ftell(IOHandle handle)
    {
        WrappedIO* wio = cast(WrappedIO*) handle;
        printf("Tell offset\n");
        c_long r = wio.wrapped.tell(wio.handle);
        printf("  => offset is %lld\n", cast(long)r);
        return r;
    }

    int debug_feof(IOHandle handle)
    {
        WrappedIO* wio = cast(WrappedIO*) handle;
        printf("Is feof?\n");
        int r = wio.wrapped.eof(wio.handle);
        printf("  => returned %d\n", r);
        return r;
    }
}


package:

// TODO: provide ability to provide the FIMEMORY location? To avoid an allocation.


/// Called memory-file in FreeImage 
/// This is basically an owned buffer, with capacity, optionally borrowed.
struct MemoryFile
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
MemoryFile* FreeImage_OpenMemory(const(ubyte)* data = null, size_t size_in_bytes = 0) @system
{
    MemoryFile* stream = cast(MemoryFile*) malloc(MemoryFile.sizeof);
    if (stream is null)
        return stream;

    *stream = MemoryFile.init;
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
void FreeImage_CloseMemory(MemoryFile *stream) @system
{
    assert (stream !is null);
    if (stream.owned)
    {
        *stream = MemoryFile.init; // poison data
        free(stream.data);
    }
    free(stream);
}



/// Provides a direct buffer access to a memory stream. Upon entry, stream is the target memory 
/// stream, returned value data is a pointer to the memory buffer, returned value size_in_bytes is 
/// the buffer size in bytes. The function returns TRUE if successful, FALSE otherwise.
/// This pointer is invalidated when you call `FreeImage_SaveToMemory`.
bool FreeImage_AcquireMemory(MemoryFile *stream, ubyte** data, size_t* size_in_bytes)
{
    assert(stream);
    *data = stream.data;
    *size_in_bytes = stream.bytes;
    return true;
}

extern(C) @system
{
    c_long mtell(MemoryFile *stream)
    {
        assert (stream !is null);

        // Files larger than 0x7fffffff bytes not supported, return errors.
        if (stream.offset > GAMUT_MAX_POSSIBLE_MEMORY_OFFSET)
            return -1;

        return cast(c_long) stream.offset;
    }

    int mseek(MemoryFile *stream, c_long offset, int origin)
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

    size_t mread(void *buffer, size_t size, size_t count, MemoryFile *stream)
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

    // TODO mwrite
    
    int meof(MemoryFile *stream)
    {
        assert(stream);
        return (stream.offset >= stream.bytes) ? 1 : 0;
    }
}

// Return internal data pointer (allocated with malloc/free)
// stream doesn't own it anymore, the caller does instead.
ubyte[] FreeImage_ReleaseMemory(MemoryFile *stream) @trusted
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
