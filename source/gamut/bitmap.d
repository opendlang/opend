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


nothrow @nogc @safe:

/// This function decodes a bitmap, allocates memory for it and then returns it as a FIBITMAP. 
/// The first parameter defines the type of bitmap to be loaded. For example, when FIF_BMP is 
/// passed, a BMP file is loaded into memory (an overview of possible FREE_IMAGE_FORMAT 
/// constants is available in Table 1). The second parameter tells FreeImage the file it has to 
/// decode. The last parameter is used to change the behaviour or enable a feature in the bitmap 
/// plugin. Each plugin has its own set of parameters.
void FreeImage_Load(ref Image image, ImageFormat fif, const(char)* filename, int flags = 0) @system
{
    assert(fif != ImageFormat.unknown);
    
    FILE* f = fopen(filename, "rb");
    if (f is null)
    {
        image.error("Couldn't open image file");
        return;
    }

    IOStream io;
    io.setupForFileIO();
    FreeImage_LoadFromHandle(image, fif, &io, cast(IOHandle)f, flags);
    
    if (0 != fclose(f))
    {
        // TODO cleanup BITMAP/Image
        //FreeImage_Unload(image);
        image.error("Closing image file with fclose() failed");
    }
}

/// FreeImage has the unique feature to load a bitmap from an arbitrary source. This source 
/// might for example be a cabinet file, a zip file or an Internet stream.
/// IOStream is a structure that contains 4 function pointers: one to read from a source, one 
/// to write to a source, one to seek in the source and one to tell where in the source we 
/// currently are. When you populate the IOStream structure with pointers to functions and 
/// pass that structure to FreeImage_LoadFromHandle, FreeImage will call your functions to 
/// read, seek and tell in a file. The handle-parameter (third parameter from the left) is used in 
/// this to differentiate between different contexts, e.g. different files or different Internet streams.
void FreeImage_LoadFromHandle(ref Image image, ImageFormat fif, IOStream* io, IOHandle handle, int flags = 0) @system
{
    // I/O logging, useful for debug purpose
    /*IOStream io2;
    WrappedIO wio;
    wio.wrapped = io;
    wio.handle = handle;
    io2.setupForLogging(io2);
    */

    assert(fif != ImageFormat.unknown);
    const(Plugin)* plugin = &g_plugins[fif];

    // Erase that former error if assertions disabled.
    image.clearError();

    int page = 0;
    void *data = null;
    if (!plugin.loadProc)
    {
        image.error("Cannot load image format with this build");
        return;
    }
    plugin.loadProc(image, io, handle, page, flags, data);
}

/// This function saves a previously loaded `FIBITMAP` to a file. The first parameter defines the 
/// type of the bitmap to be saved. For example, when `FIF_BMP` is passed, a BMP file is saved.
/// The second parameter is the name of the bitmap to be saved. If the file already exists it is 
/// overwritten. Note that some bitmap save plugins have restrictions on the bitmap types they 
/// can save.
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
    const(Plugin)* plugin = &g_plugins[fif];
    void* data = null; // probably exist to pass metadata stuff
    if (plugin.saveProc is null)
        return false;
    bool r = plugin.saveProc(image, io, handle, 0, flags, data);
    return r;
}




// ================================================================================================
//
//                                  BITMAP MANAGEMENT FUNCTIONS
//
// ================================================================================================


/// Returns the data type of a bitmap.
ImageType FreeImage_GetImageType(Image *dib) pure
{
    return dib._type;
}

/// Returns the offset between two consecutive scanlines, in bytes.
/// Warning: unlike in FreeImage, scanlines are not always aligned on 32-bit boundaries.
int FreeImage_GetPitch(Image *dib) pure
{
    // No support for arbitrary pitch right now, only dense supported.
    return dib._pitch;
}




// ================================================================================================
//
//                                           INTERNALS
//
// ================================================================================================


private:

// Size of one pixel for type
int bytesForImageType(ImageType type) pure
{
    final switch(type)
    {
        case ImageType.uint8:   return 1;
        case ImageType.int8:    return 1;
        case ImageType.uint16:  return 2;
        case ImageType.int16:   return 2;
        case ImageType.uint32:  return 4;
        case ImageType.int32:   return 4;
        case ImageType.f32:     return 4;
        case ImageType.f64:     return 8;
        case ImageType.la8:     return 2;
        case ImageType.la16:    return 4;
        case ImageType.rgb8:    return 3;
        case ImageType.rgb16:   return 6;
        case ImageType.rgba8:   return 4;
        case ImageType.rgba16:  return 8;
        case ImageType.rgbf32:  return 12;
        case ImageType.rgbaf32: return 16;
        case ImageType.unknown: assert(false);
    }
}

/// Suggest a length of line, in bytes, including padding (FUTURE: with given alignment).
/// Length must be enough to hold all pixel data for this line.
int pitchForImage(ImageType type, int width)
{
    return width * bytesForImageType(type); //  no alignment
}

@trusted unittest 
{
    FIBITMAP *bitmap = FreeImage_AllocateT(FIT_RGB16, 257, 183);
    if (bitmap) 
    {
        // bitmap successfully created!
        assert(FreeImage_GetImageType(bitmap) == FIT_RGB16);
        assert(FreeImage_GetWidth(bitmap) == 257);
        assert(FreeImage_GetHeight(bitmap) == 183);
        FreeImage_Unload(bitmap);
    }
}