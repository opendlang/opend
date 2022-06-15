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
import gamut.plugin;
import gamut.internals.cstring;


nothrow @nogc @safe:

/// This function decodes a bitmap, allocates memory for it and then returns it as a FIBITMAP. 
/// The first parameter defines the type of bitmap to be loaded. For example, when FIF_BMP is 
/// passed, a BMP file is loaded into memory (an overview of possible FREE_IMAGE_FORMAT 
/// constants is available in Table 1). The second parameter tells FreeImage the file it has to 
/// decode. The last parameter is used to change the behaviour or enable a feature in the bitmap 
/// plugin. Each plugin has its own set of parameters.
void FreeImage_Load(ref FIBITMAP image, ImageFormat fif, const(char)* filename, int flags = 0) @system
{
    assert(fif != ImageFormat.unknown);
    
    FILE* f = fopen(filename, "rb");
    if (f is null)
    {
        image.error("Couldn't open image file");
        return;
    }

    FreeImageIO io;
    setupFreeImageIOForFile(io);
    FreeImage_LoadFromHandle(image, fif, &io, cast(fi_handle)f, flags);
    
    if (0 != fclose(f))
    {
        // TODO cleanup BITMAP/Image
        //FreeImage_Unload(image);
        image.error("Closing image file with fclose() failed");
    }
}

/// FreeImage has the unique feature to load a bitmap from an arbitrary source. This source 
/// might for example be a cabinet file, a zip file or an Internet stream.
/// FreeImageIO is a structure that contains 4 function pointers: one to read from a source, one 
/// to write to a source, one to seek in the source and one to tell where in the source we 
/// currently are. When you populate the FreeImageIO structure with pointers to functions and 
/// pass that structure to FreeImage_LoadFromHandle, FreeImage will call your functions to 
/// read, seek and tell in a file. The handle-parameter (third parameter from the left) is used in 
/// this to differentiate between different contexts, e.g. different files or different Internet streams.
void FreeImage_LoadFromHandle(ref FIBITMAP image, ImageFormat fif, FreeImageIO* io, fi_handle handle, int flags = 0) @system
{
    // I/O logging, useful for debug purpose
    FreeImageIO io2;
    WrappedIO wio;
    wio.wrapped = io;
    wio.handle = handle;
    setupFreeImageIOForLogging(io2);

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
bool FreeImage_Save(ref FIBITMAP dib, ImageFormat fif, const(char)* filename, int flags = 0) @trusted
{
    assert(fif != ImageFormat.unknown);

    FILE* f = fopen(filename, "wb");
    if (f is null)
        return false;

    FreeImageIO io;
    setupFreeImageIOForFile(io);
    bool r = FreeImage_SaveToHandle(dib, fif, &io, cast(fi_handle)f, flags);
    return fclose(f) == 0;
}

bool FreeImage_SaveToHandle(ref FIBITMAP dib, ImageFormat fif, FreeImageIO *io, fi_handle handle, int flags = 0) @trusted
{
    const(Plugin)* plugin = &g_plugins[fif];
    void* data = null; // probably exist to pass metadata stuff
    if (plugin.saveProc is null)
        return false;
    bool r = plugin.saveProc(dib, io, handle, 0, flags, data);
    return r;
}




// ================================================================================================
//
//                                  BITMAP MANAGEMENT FUNCTIONS
//
// ================================================================================================


/// Returns the data type of a bitmap.
ImageType FreeImage_GetImageType(FIBITMAP *dib) pure
{
    return dib._type;
}

/// Returns the number of colors used in a bitmap. This function returns the palette-size for 
/// palletised bitmaps, and 0 for high-colour bitmaps.
int FreeImage_GetPaletteSize(FIBITMAP *dib) pure
{
    return 0; // 
}
deprecated("Use instead FreeImage_GetPaletteSize") 
    alias FreeImage_GetColorsUsed = FreeImage_GetPaletteSize; ///ditto

/// Returns: Size of one pixel in the bitmap, in bits.
int FreeImage_GetBPP(FIBITMAP *dib) pure
{
    assert(dib._type != ImageType.unknown);
    return 8 * bytesForImageType(dib._type);
}

/// Return width of the bitmap, in bytes.
int FreeImage_GetWidthInBytes(FIBITMAP *dib) pure
{
    assert(dib._type != ImageType.unknown);
    return dib._width * bytesForImageType(dib._type);
}

/// Returns the offset between two consecutive scanlines, in bytes.
/// Warning: unlike in FreeImage, scanlines are not always aligned on 32-bit boundaries.
int FreeImage_GetPitch(FIBITMAP *dib) pure
{
    // No support for arbitrary pitch right now, only dense supported.
    return dib._pitch;
}

deprecated("FreeImage_GetLine returns the number of bytes in a line. Use FreeImage_GetWidthInBytes if you mean that.") 
    alias FreeImage_GetLine = FreeImage_GetWidthInBytes;


/// Returns FALSE if the bitmap does not contain pixel data (i.e. if it contains only header and 
/// possibly some metadata). 
/// Header only bitmap can be loaded using the FIF_LOAD_NOPIXELS load flag (see Table 3). 
/// This load flag will tell the decoder to read header data and available metadata and skip pixel 
/// data decoding. The memory size of the dib is thus reduced to the size of its members, 
/// excluding the pixel buffer. Reading metadata only information is fast since no pixel decoding 
/// occurs. 
/// Header only bitmap can be used with Bitmap information functions, Metadata iterator. They 
/// cannot be used with any pixel processing function or by saving function.
bool FreeImage_HasPixels(FIBITMAP *dib) pure
{
    return dib._data != null;
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
        assert(FreeImage_GetBPP(bitmap) == 48);
        FreeImage_Unload(bitmap);
    }
}