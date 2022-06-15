/**
I/O streams in FreeImage.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.io;

import core.stdc.stdio;
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
    void setupForFileIO() @trusted
    {
        read  = cast(ReadProc) &fread;
        write = cast(WriteProc) &fwrite;
        seek  = cast(SeekProc) &fseek;
        tell  = cast(TellProc) &ftell;
        eof   = cast(EofProc) &feof;
    }

    /// Setup the IOStream for wrapping another IOStream and logging what happens.
    /// The passed `IOHandle` will need to be a `WrappedIO`.
    /// For internal Gamut usage.
    debug void setupSetupForLogging(ref IOStream io) @trusted
    {
        io.read  = &debug_fread;
        io.write = &debug_fwrite;
        io.seek  = &debug_fseek;
        io.tell  = &debug_ftell;
        io.eof   = &debug_feof;
    }
}


package struct WrappedIO
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

debug extern(C) @system
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