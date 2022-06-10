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

enum GAMUT_MAX_WIDTH = 16384;  /// No FIBITMAP can exceed this width in gamut.
enum GAMUT_MAX_HEIGHT = 16384; /// No FIBITMAP can exceed this height in gamut.

nothrow @nogc @safe:

struct FIBITMAP
{
package:

    FREE_IMAGE_TYPE _type;
    ubyte* _data = null;

    int _width;
    int _height;
    int _bpp;

    /// Pitch in bytes between lines.
    int _pitch; 
}


// ================================================================================================
//
//                                  BITMAP MANAGEMENT FUNCTIONS
//
// ================================================================================================

/// Allocate a black image.
///
/// Params:
///     type The pixel format of the image. 
///     width The width of the image.
///     height The height of the image.
///
/// Returns:
///     A newly allocated `FIBITMAP`, or `null` if an error occured.
FIBITMAP* FreeImage_Allocate(FREE_IMAGE_TYPE type, int width, int height) @trusted
{
    assert(type != FIT_UNKNOWN);

    if (width > GAMUT_MAX_WIDTH)
        return null;

    if (height > GAMUT_MAX_HEIGHT)
        return null;

    FIBITMAP* bitmap = cast(FIBITMAP*) malloc(FIBITMAP.sizeof);
    if (!bitmap) 
        return null;
    bitmap._type = type;
    int pitch = pitchForImage(type, width);
    size_t bytes = height * pitch;

    ubyte* data = cast(ubyte*) realloc(null, bytes);
    if (data == null)
        goto error;

    bitmap._width = width;
    bitmap._height = height;
    bitmap._data = data;
    bitmap._pitch = pitch;
    return bitmap;

    error:
        free(bitmap);
        return null; // failed
}

/// Load flags
enum int
   PNG_DEFAULT = 0;

/// This function decodes a bitmap, allocates memory for it and then returns it as a FIBITMAP. 
/// The first parameter defines the type of bitmap to be loaded. For example, when FIF_BMP is 
/// passed, a BMP file is loaded into memory (an overview of possible FREE_IMAGE_FORMAT 
/// constants is available in Table 1). The second parameter tells FreeImage the file it has to 
/// decode. The last parameter is used to change the behaviour or enable a feature in the bitmap 
/// plugin. Each plugin has its own set of parameters.
FIBITMAP* FreeImage_Load(FREE_IMAGE_FORMAT fif, const(char)* filename, int flags = 0) @system
{
    assert(fif != FIF_UNKNOWN);
    
    FILE* f = fopen(filename, "rb");
    if (f is null)
        return null;

    FreeImageIO io;
    setupFreeImageIOForFile(io);

    FIBITMAP* bitmap = FreeImage_LoadFromHandle(fif, &io, cast(fi_handle)f, flags);
    
    if (0 != fclose(f))
    {
        FreeImage_Unload(bitmap);
        return null;
    }

    return bitmap;
}
///ditto
deprecated("Use FreeImage_Load instead, it was made Unicode-aware") alias FreeImage_LoadU = FreeImage_Load; 

/// FreeImage has the unique feature to load a bitmap from an arbitrary source. This source 
/// might for example be a cabinet file, a zip file or an Internet stream.
/// FreeImageIO is a structure that contains 4 function pointers: one to read from a source, one 
/// to write to a source, one to seek in the source and one to tell where in the source we 
/// currently are. When you populate the FreeImageIO structure with pointers to functions and 
/// pass that structure to FreeImage_LoadFromHandle, FreeImage will call your functions to 
/// read, seek and tell in a file. The handle-parameter (third parameter from the left) is used in 
/// this to differentiate between different contexts, e.g. different files or different Internet streams.
FIBITMAP* FreeImage_LoadFromHandle(FREE_IMAGE_FORMAT fif, FreeImageIO* io, fi_handle handle, int flags = 0) @system
{
    // I/O logging, useful for debug purpose
    /*FreeImageIO io2;
    WrappedIO wio;
    wio.wrapped = io;
    wio.handle = handle;
    setupFreeImageIOForLogging(io2);*/

    Plugin* plugin = FreeImage_PluginAcquireForReading(fif);
    if (plugin is null)
        return null;

    scope(exit) FreeImage_PluginRelease(plugin);

    int page = 0;
    void *data = null;
    assert(plugin.loadProc); // else, do not mark it as suitable for reading
    FIBITMAP* loaded = plugin.loadProc(io, handle, page, flags, data);
    return loaded;
}

deprecated("Use FreeImage_Save instead, it was made Unicode-aware") 
    alias FreeImage_SaveU = FreeImage_Save;

/// This function saves a previously loaded `FIBITMAP` to a file. The first parameter defines the 
/// type of the bitmap to be saved. For example, when `FIF_BMP` is passed, a BMP file is saved.
/// The second parameter is the name of the bitmap to be saved. If the file already exists it is 
/// overwritten. Note that some bitmap save plugins have restrictions on the bitmap types they 
/// can save.
bool FreeImage_Save(FREE_IMAGE_FORMAT fif, FIBITMAP *dib, const(char)* filename, int flags = 0) @trusted
{
    assert(fif != FIF_UNKNOWN);

    FILE* f = fopen(filename, "wb");
    if (f is null)
        return false;

    FreeImageIO io;
    setupFreeImageIOForFile(io);
    bool r = FreeImage_SaveToHandle(fif, dib, &io, cast(fi_handle)f, flags);
    return fclose(f) == 0;
}

bool FreeImage_SaveToHandle(FREE_IMAGE_FORMAT fif, FIBITMAP *dib, 
                            FreeImageIO *io, fi_handle handle, int flags = 0)
{
    Plugin* plugin = FreeImage_PluginAcquireForWriting(fif);
    if (plugin is null)
        return false;

    scope(exit) FreeImage_PluginRelease(plugin);

    void* data = null; // probalby exist to pass metadata stuff
    assert(plugin.saveProc); // else, do not mark it as suitable for writing
    bool r = plugin.saveProc(io, dib, handle, 0, flags, data);
    return r;
}

/// Makes an exact reproduction of an existing bitmap, including metadata and attached profile if any.
FIBITMAP* FreeImage_Clone(FIBITMAP *dib) @trusted
{
    assert(dib._type != FIT_UNKNOWN); // MAYDO: clone of FIT_UNKNOWN?

    if (dib is null)
        return null;

    FREE_IMAGE_TYPE type = dib._type;
    int width            = dib._width;
    int height           = dib._height;

    FIBITMAP* bitmap = FreeImage_Allocate(dib._type, width, height);
    if (!bitmap) 
        return null;

    // The bitmaps do not necessarily have the same pitch here.
    assert(bitmap._pitch == dib._pitch);
    assert(bitmap._height == dib._height);
    int bytes = height * dib._pitch; // TODO: avoid overflow here
    memcpy(bitmap._data, dib._data, bytes); // Copy whole image.


    // TODO: copy thumbnail, copy meta-data.

    return bitmap;
}

/// Deletes a previously loaded `FIBITMAP` from memory.
void FreeImage_Unload(FIBITMAP *dib) @system
{
    if (dib)
    {
        if (dib._data)
        {
            free(dib._data);
            dib._data = null;
        }
        free(dib);
    }
}

// ================================================================================================
//
//                                  BITMAP MANAGEMENT FUNCTIONS
//
// ================================================================================================


/// Returns the data type of a bitmap.
FREE_IMAGE_TYPE FreeImage_GetImageType(FIBITMAP *dib) pure
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
    assert(dib._type != FIT_UNKNOWN);
    return 8 * bytesForImageType(dib._type);
}

/// Returns the width of the bitmap in pixel units.
int FreeImage_GetWidth(FIBITMAP *dib) pure
{
    return dib._width;
}

/// Returns the height of the bitmap in pixel units.
int FreeImage_GetHeight(FIBITMAP *dib) pure
{
    return dib._height;
}

/// Return width of the bitmap, in bytes.
int FreeImage_GetWidthInBytes(FIBITMAP *dib) pure
{
    assert(dib._type != FIT_UNKNOWN);
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
int bytesForImageType(FREE_IMAGE_TYPE type) pure
{
    assert(type != FIT_UNKNOWN);

    switch(type)
    {
        case FIT_UINT8:   return 1;
        case FIT_INT8:    return 1;
        case FIT_UINT16:  return 2;
        case FIT_INT16:   return 2;
        case FIT_UINT32:  return 4;
        case FIT_INT32:   return 4;
        case FIT_FLOAT:   return 4;
        case FIT_DOUBLE:  return 8;
        case FIT_COMPLEX: return 16;
        case FIT_LA8:     return 2;
        case FIT_LA16:    return 4;
        case FIT_RGB8:    return 3;
        case FIT_RGB16:   return 6;
        case FIT_RGBA8:   return 4;
        case FIT_RGBA16:  return 8;
        case FIT_RGBF:    return 12;
        case FIT_RGBAF:   return 16;
        default:
            assert(false);
    }
}

/// Suggest a length of line, in bytes, including padding (FUTURE: with given alignment).
/// Length must be enough to hold all pixel data for this line.
int pitchForImage(FREE_IMAGE_TYPE type, int width)
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