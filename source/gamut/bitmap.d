/// Bitmap Management functions.
module gamut.bitmap;

import core.memory: pureMalloc, pureRealloc, pureFree;
import gamut.types;

nothrow @nogc @safe:


struct FIBITMAP
{
private:
    ubyte* _data = null;
}

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
FIBITMAP* FreeImage_Allocate(int width, int height, int bpp, uint red_mask = 0, uint green_mask = 0, uint blue_mask = 0) pure @trusted
{
    return FreeImage_AllocateT(FIT_BITMAP, width, height, bpp, red_mask, green_mask, blue_mask);
}

/// While most imaging applications only deal with photographic images, many scientific 
/// applications need to deal with high resolution images (e.g. 16-bit greyscale images), with real 
/// valued pixels or even with complex pixels (think for example about the result of a Fast Fourier 
/// Transform applied to a 8-bit greyscale image: the result is a complex image). 
/// A special parameter, an enum named `FREE_IMAGE_TYPE`, is used to specify the bitmap 
/// type of a FIBITMAP.
FIBITMAP* FreeImage_AllocateT(FREE_IMAGE_TYPE type, int width, int height, 
                              int bpp = 8, uint red_mask = 0, uint green_mask = 0, uint blue_mask = 0) pure @trusted
{
    FIBITMAP* bitmap = cast(FIBITMAP*) pureMalloc(FIBITMAP.sizeof);
    if (!bitmap) 
        return null;
    *bitmap = FIBITMAP.init;
    ubyte* data = pureReallocatePixelData(null, type, width, height, bpp);    
    if (data == null)
    {
        pureFree(bitmap);
    }
    bitmap._data = data;
    return bitmap;
}



/// FreeImage_Allocate


/// FreeImage_AllocateT

/// FreeImage_Load

/// FreeImage_LoadU


/// FreeImage_LoadFromHandle

/// FreeImage_Save

/// FreeImage_SaveU


/// FreeImage_Clone


/// FreeImage_Unload

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


private:

/// Valid BPP for standard bitmaps FIT_BITMAPS.
bool isValidBPPStandardBitmap(int bpp) pure
{
    return bpp == 1 || bpp == 4 || bpp == 8 || bpp == 16 || bpp == 24 || bpp == 32;
}

// Size of one pixel for type FIT_BITMAP + bpp
size_t bytesForBPPStandardBitmap(int bpp) pure
{
    if (bpp < 8) return 1;
    else return (bpp >> 3);
}

// Size of one pixel for type
size_t bytesForImageType(FREE_IMAGE_TYPE type) pure
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
