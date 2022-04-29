/**
Bitmap management and information functions.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.bitmap;

import core.stdc.stdio;
import core.memory: pureMalloc, pureRealloc, pureFree;
import gamut.types;
import gamut.io;

nothrow @nogc @safe:

// TODO: for security, disallow image above a certain width and height, handle that as error
//       check for overflow in image creation WxH

struct FIBITMAP
{
private:

    FREE_IMAGE_TYPE _type;
    ubyte* _data = null;

    int _width;
    int _height;
    int _bpp;

    uint _red_mask;
    uint _green_mask;
    uint _blue_mask;
}


// ================================================================================================
//
//                                  BITMAP MANAGEMENT FUNCTIONS
//
// ================================================================================================

/// If you want to create a new bitmap in memory from scratch, without loading a pre-made 
/// bitmap from disc, you use this function. `FreeImage_Allocate` takes a width and height 
/// parameter, and a bpp parameter to specify the bit depth of the image and returns a 
/// FIBITMAP. The optional last three parameters (red_mask, green_mask and blue_mask) are 
/// used to tell FreeImage the bit-layout of the color components in the bitmap, e.g. where in a 
/// pixel the red, green and blue components are stored. To give you an idea about how to 
/// interpret the color masks: when red_mask is 0xFF000000 this means that the last 8 bits in 
/// one pixel are used for the color red. When green_mask is 0x000000FF, it means that the first 
/// 8 bits in a pixel are used for the color green.
///
/// Note: FreeImage_Allocate allocates an empty bitmap, i.e. a bitmap that is filled completely 
/// with zeroes. Zero in a bitmap is usually interpreted as black. This means that if your 
/// bitmap is palletised it will contain a completely black palette. You can access, and 
/// hence populate the palette by using the function FreeImage_GetPalette.
/// For 8-bit images only, FreeImage_Allocate will build a default greyscale palette. 
FIBITMAP* FreeImage_Allocate(int width, 
                             int height, 
                             int bpp, 
                             uint red_mask = 0, 
                             uint green_mask = 0, 
                             uint blue_mask = 0) pure @trusted
{
    return FreeImage_AllocateT(FIT_BITMAP, width, height, bpp, red_mask, green_mask, blue_mask);
}

/// While most imaging applications only deal with photographic images, many scientific 
/// applications need to deal with high resolution images (e.g. 16-bit greyscale images), with real 
/// valued pixels or even with complex pixels (think for example about the result of a Fast Fourier 
/// Transform applied to a 8-bit greyscale image: the result is a complex image). 
/// A special parameter, an enum named `FREE_IMAGE_TYPE`, is used to specify the bitmap 
/// type of a FIBITMAP.
FIBITMAP* FreeImage_AllocateT(FREE_IMAGE_TYPE type, 
                              int width, 
                              int height, 
                              int bpp = 8, 
                              uint red_mask = 0, 
                              uint green_mask = 0, 
                              uint blue_mask = 0) pure @trusted
{
    FIBITMAP* bitmap = cast(FIBITMAP*) pureMalloc(FIBITMAP.sizeof);
    if (!bitmap) 
        return null;
    bitmap._type = type;
    ubyte* data = pureReallocatePixelData(null, type, width, height, bpp);    
    if (data == null)
    {
        pureFree(bitmap);
    }
    bitmap._width = width;
    bitmap._height = height;
    bitmap._data = data;
    bitmap._bpp = bpp; // Store even if not significant
    return bitmap;
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
FIBITMAP* FreeImage_Load(FREE_IMAGE_FORMAT fif, const(char)* filenameZ, int flags = 0) @system
{
    assert(fif != FIF_UNKNOWN);
    
    FILE* f = fopen(filenameZ, "rb");
    if (f is null)
        return null;

    FreeImageIO io;

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
    if (fif == FIF_PNG)
    {



    }
    return null;
}

/// FreeImage_Save

deprecated("Use FreeImage_Save instead, it was made Unicode-aware") alias FreeImage_SaveU = FreeImage_Save;
FIBITMAP* FreeImage_Save(FIBITMAP *dib) pure
{
    return null; // TODO
}

/// Makes an exact reproduction of an existing bitmap, including metadata and attached profile if any.
FIBITMAP* FreeImage_Clone(FIBITMAP *dib) pure
{
    assert(dib._type != FIT_UNKNOWN); // MAYDO: clone of FIT_UNKNOWN?

    if (dib is null)
        return null;

    FREE_IMAGE_TYPE type = dib._type;
    int width            = dib._width;
    int height           = dib._height;
    int bpp              = dib._bpp;
    
    uint red_mask = dib._red_mask;
    uint green_mask = dib._green_mask;
    uint blue_mask = dib._blue_mask;

    FIBITMAP* bitmap = FreeImage_AllocateT(dib._type, width, height, bpp, red_mask, green_mask, blue_mask);

    if (!bitmap) 
        return null;

    // TODO: copy pixels if any
    
    return bitmap;
}

/// Deletes a previously loaded `FIBITMAP` from memory.
void FreeImage_Unload(FIBITMAP *dib) pure @system
{
    if (dib)
    {
        if (dib._data)
        {
            pureFree(dib._data);
            dib._data = null;
        }
        pureFree(dib);
    }
}

// ================================================================================================
//
//                                  BITMAP MANAGEMENT FUNCTIONS
//
// ================================================================================================



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

/// Returns the size of one pixel in the bitmap in bits. For example when each pixel takes 32-bits 
/// of space in the bitmap, this function returns 32. Possible bit depths are 1, 4, 8, 16, 24, 32 
/// for standard bitmaps and 16-, 32-, 48-, 64-, 96- and 128-bit for non standard bitmaps.
int FreeImage_GetBPP(FIBITMAP *dib) pure
{
    assert(dib._type != FIT_UNKNOWN);

    if (dib._type == FIT_BITMAP)
    {
        return dib._bpp;
    }
    else
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

/// Returns a bit pattern describing the red color component of a pixel in a FIBITMAP, returns 0 
/// otherwise. 
uint FreeImage_GetRedMask(FIBITMAP *dib) pure
{
    return dib._red_mask;
}

/// Returns a bit pattern describing the green color component of a pixel in a FIBITMAP, returns 0
/// otherwise. 
uint FreeImage_GetGreenMask(FIBITMAP *dib) pure
{
    return dib._green_mask;
}

/// Returns a bit pattern describing the blue color component of a pixel in a FIBITMAP, returns 0 
/// otherwise. 
uint FreeImage_GetBlueMask(FIBITMAP *dib) pure
{
    return dib._blue_mask;
}

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

/// Valid BPP for standard bitmaps FIT_BITMAPS.
bool isValidBPPStandardBitmap(int bpp) pure
{
    return bpp == 1 || bpp == 4 || bpp == 8 || bpp == 16 || bpp == 24 || bpp == 32;
}

// Size of one pixel for type FIT_BITMAP + bpp
int bytesForBPPStandardBitmap(int bpp) pure
{
    if (bpp < 8) return 1;
    else return (bpp >> 3);
}

// Size of one pixel for type
int bytesForImageType(FREE_IMAGE_TYPE type) pure
{
    assert(type != FIT_UNKNOWN && type != FIT_BITMAP);

    switch(type)
    {
        case FIT_UINT16:  return 2;
        case FIT_INT16:   return 2;
        case FIT_UINT32:  return 4;
        case FIT_INT32:   return 4;
        case FIT_FLOAT:   return 4;
        case FIT_DOUBLE:  return 8;
        case FIT_COMPLEX: return 16;
        case FIT_RGB16:   return 6;
        case FIT_RGBA16:  return 8;
        case FIT_RGBF:    return 12;
        case FIT_RGBAF:   return 16;
        default:
            assert(false);
    }
}


ubyte* pureReallocatePixelData(ubyte* oldData, FREE_IMAGE_TYPE type, int width, int height, int bpp) pure @system
{
    size_t bytesPerPixel;
    if (type == FIT_UNKNOWN)
    {
    error:
        pureFree(oldData);
        return null;
    }
    else if (type == FIT_BITMAP)
    {
        if (!isValidBPPStandardBitmap(bpp))
            goto error;

        bytesPerPixel = bytesForBPPStandardBitmap(bpp);        
    }
    else
    {
        bytesPerPixel = bytesForImageType(bpp);
    }

    size_t bytes = width * height * bytesPerPixel;
    ubyte* data = cast(ubyte*) pureRealloc(oldData, bytes); // TODO: not sure what to do with oldData if realloc fails

    if (data)
    {
        // Fill with zeroes
        data[0..bytes] = 0; 
    }
    return data;
}

@trusted unittest 
{
    FIBITMAP *bitmap = FreeImage_AllocateT(FIT_RGB16, 257, 183);
    if (bitmap) 
    {
        // bitmap successfully created!
     /*   assert(FreeImage_GetType(bitmap) == FIT_RGB16);
        assert(FreeImage_GetWidth(bitmap));
        assert(FreeImage_GetHeight(bitmap));
        assert(FreeImage_GetBPP(bitmap) == 48); */
        FreeImage_Unload(bitmap);
    }
}