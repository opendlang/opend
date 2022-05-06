module gamut.io;

import core.stdc.stdio;
import core.stdc.config: c_long;
public import core.stdc.stdio: SEEK_SET, SEEK_CUR, SEEK_END;

nothrow @nogc:

/// FreeImage has the unique feature to load a bitmap from an arbitrary source. This source 
/// might for example be a cabinet file, a zip file or an Internet stream. Handling of these arbitrary 
/// sources is not directly handled in the FREEIMAGE.DLL, but can be easily added by using a 
/// FreeImageIO structure as defined in FREEIMAGE.H.
/// FreeImageIO is a structure that contains 4 function pointers: one to read from a source, one 
/// to write to a source, one to seek in the source and one to tell where in the source we 
/// currently are. When you populate the FreeImageIO structure with pointers to functions and 
/// pass that structure to FreeImage_LoadFromHandle, FreeImage will call your functions to 
/// read, seek and tell in a file. The handle-parameter (third parameter from the left) is used in 
/// this to differentiate between different contexts, e.g. different files or different Internet streams.
struct FreeImageIO
{	
	ReadProc read;
	WriteProc write;
	SeekProc seek;
	TellProc tell;
}

alias fi_handle = void*;

extern(C)
{
    @system
    {
        alias ReadProc = uint function(void* buffer, int size, int count, fi_handle handle);
        alias WriteProc = uint function(void* buffer, int size, int count, fi_handle handle);
    }

    // Origin: position from which offset is added
    //   SEEK_SET = beginning of file.
    //   SEEK_CUR = Current position of file pointer.
    //   SEEK_END = end of file.
    // This function returns zero if successful, or else it returns a non-zero value.
    @system alias SeekProc = int function(fi_handle handle, long offset, int origin);

    // Tells where we are in the file. -1 if error.
    @system alias TellProc = long function(fi_handle handle);
}

extern(C)
{
    uint file_read(scope void* buffer, int size, int count, fi_handle handle) @system
    {
        return cast(uint) fread(buffer, size, count, cast(FILE*)handle);
    }

    uint file_write(scope void* buffer, int size, int count, fi_handle handle) @system
    {
        return cast(uint) fwrite(buffer, size, count, cast(FILE*)handle);
    }

    int file_seek(fi_handle handle, long offset, int whence) @system
    {
        if (offset >= c_long.min && offset <= c_long.max)
            return fseek(cast(FILE*)handle, cast(c_long)offset, whence);
        else
            return -1; // error, too large offset.
    }

    long file_tell(fi_handle handle) @system
    {
        return cast(long) ftell(cast(FILE*)handle);
    }
}

