module gamut.io;

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
    alias ReadProc = int function(void* buffer, int size, int count, fi_handle handle);
    alias WriteProc = uint function(void* buffer, int size, int count, fi_handle handle);
    alias SeekProc = void function(fi_handle handle, int offset, int origin);
    alias TellProc = void function(fi_handle handle);
}