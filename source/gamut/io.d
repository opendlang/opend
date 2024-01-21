/**
I/O streams.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.io;

import core.stdc.stdio;
import core.stdc.string: memcpy;
import core.stdc.stdlib: malloc, free, realloc;
public import core.stdc.config: c_long;
public import core.stdc.stdio: SEEK_SET, SEEK_CUR, SEEK_END;

nothrow @nogc:


// Limits of I/O in gamut.
// Callbacks are modelled upon C stdlib functions, some of those use c_long or int. So, 32-bit is a possibility.
enum size_t GAMUT_MAX_POSSIBLE_MEMORY_OFFSET = 0x7fff_fffe;       /// Can't open file larger than this much bytes
enum size_t GAMUT_MAX_POSSIBLE_SIMULTANEOUS_READ = 0x7fff_ffff;   /// Can't read more bytes than this at once
enum size_t GAMUT_MAX_POSSIBLE_SIMULTANEOUS_WRITE = 0x7fff_ffff;  /// Can't write more bytes than this at once

static assert(GAMUT_MAX_POSSIBLE_MEMORY_OFFSET + 1 <= cast(long) int.max);

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
    /// Note: c_long offsets in gamut can always be cast to int without loss.
    alias SeekProc = int function(IOHandle handle, c_long offset, int origin);

    /// A function with same signature and semantics than `ftell`.
    /// Tells where we are in the file. -1 if error.
    /// Note: c_long offsets in gamut can always be cast to int without loss.
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

    /// Helper to read one ubyte in stream.
    /// On error, sets `err` to `true` and return 0.
    ubyte read_ubyte(IOHandle handle, bool* err) nothrow @nogc @trusted
    {
        ubyte v;
        if (1 == read(&v, 1, 1, handle))
        {
            *err = false;
            return v;
        }
        else
        {
            *err = true;
            return 0;
        }
    }

    /// Helper to read one little-endian ushort in stream.
    /// On error, sets `err` to `true` and return 0.
    ushort read_ushort_LE(IOHandle handle, bool* err) nothrow @nogc @trusted
    {
        ushort v; // Note: no support for BigEndian here
        if (2 == read(&v, 1, 2, handle))
        {
            *err = false;
            return v;
        }
        else
        {
            *err = true;
            return 0;
        }
    }

    /// Helper to read one little-endian uint in stream.
    /// On error, sets `err` to `true` and return 0.
    uint read_uint_LE(IOHandle handle, bool* err) nothrow @nogc @trusted
    {
        uint v; // Note: no support for BigEndian here
        if (4 == read(&v, 1, 4, handle))
        {
            *err = false;
            return v;
        }
        else
        {
            *err = true;
            return 0;
        }
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

    /// Setup the IOStream for using a  a file. The passed `IOHandle` will need to be a `MemoryFile*`.
    /// For internal Gamut usage.
    void setupForMemoryIO() pure @trusted
    {
        read  = cast(ReadProc)  &mread;
        write = cast(WriteProc) &mwrite;
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
        printf("Write %lld elements of %lld bytes\n", cast(long)count, cast(long)size);
        size_t r = wio.wrapped.write(buffer, size, count, wio.handle);
        printf("  => written %lld elements\n", cast(long)r);
        return r;
    }

    size_t debug_fread (void* buffer, size_t size, size_t count, IOHandle handle)
    {
        WrappedIO* wio = cast(WrappedIO*) handle;
        printf("Read %lld elements of %lld bytes\n", cast(long)count, cast(long)size);
        size_t r = wio.wrapped.read(buffer, size, count, wio.handle);
        printf("  => read %lld elements\n", cast(long)r);
        return r;
    }

    int debug_fseek(IOHandle handle, c_long offset, int origin)
    {
        WrappedIO* wio = cast(WrappedIO*) handle;
        printf("Seek to offset %lld, mode %d\n", cast(long) offset, origin);
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

/// This is basically an owned buffer, with capacity, optionally borrowed.
/// The original things being that it can both be used for reading and writing.
struct MemoryFile
{
public nothrow @nogc @safe:

    /// If the memory is owned by MemoryFile, or borrowed.
    bool owned = false;

    /// If can only read from buffer.
    bool readOnly = false;

    /// Pointer to data (owned or borrowed).
    /// if `owned`, the buffer is guaranteed to be allocated with malloc/free/realloc.
    ubyte* data = null;

    /// Length of buffer.
    size_t bytes = 0;

    /// Current pointer in the buffer.
    size_t offset = 0;

    /// Size of the underlying allocation, meaningful if `owned`.
    size_t capacity = 0;

    /// Return internal data pointer (allocated with malloc/free)
    /// stream doesn't own it anymore, the caller does instead.
    /// Can only be called if that buffer is owned is the first place.
    ubyte[] releaseData() @trusted
    {
        assert (owned);
        owned = false;
        if (data is null)
            return null;
        ubyte* v = data;
        data = null;
        return v[0..offset];
    }

    @disable this(this);

    ~this() @trusted
    {
        if (owned)
        {
            free(data);
            data = null;
        }
    }

    /// Initialize empty buffer for writing.
    /// Must be a T.init object.
    void initEmpty()
    {
        owned = true;
    }

    /// Initialize buffer as reading a slice.
    /// Must be a T.init object.
    void initFromExistingSlice(const(ubyte)[] arr) @system
    {
        owned = false;
        readOnly = true;
        data = cast(ubyte*) arr.ptr; // const_cast here
        bytes = arr.length;
    }

    // Resize internal buffer so that it exceeds numBytes.
    // Such buffers are grow-only.
    void ensureCapacity(size_t numBytes) @trusted
    {
        assert(owned);

        if (capacity >= numBytes)
            return;

        // Take greater of numBytes and 2 x current capacity, as the new capacity.
        size_t newCapacity = numBytes;
        size_t doubleCap = 1 + 2 * capacity;
        if (doubleCap > newCapacity)
            newCapacity = doubleCap;

        capacity = newCapacity;
        data = cast(ubyte*) realloc(data, newCapacity);
    }
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

        stream.offset = cast(size_t) newOffset;
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

    size_t mwrite(void *buffer, size_t size, size_t count, MemoryFile *stream)
    {
        assert (stream !is null);
        assert(size <= GAMUT_MAX_POSSIBLE_SIMULTANEOUS_WRITE);
        assert(count <= GAMUT_MAX_POSSIBLE_SIMULTANEOUS_WRITE);
        size_t bytes = cast(size_t)size * cast(size_t)count; // won't overflow
        assert(bytes <= GAMUT_MAX_POSSIBLE_SIMULTANEOUS_WRITE);
        stream.ensureCapacity(stream.offset + bytes);
        memcpy(&stream.data[stream.offset], buffer, bytes);
        stream.offset += bytes;
        return count;
    }
    
    int meof(MemoryFile *stream)
    {
        assert(stream);
        return (stream.offset >= stream.bytes) ? 1 : 0;
    }
}
