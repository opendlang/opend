/**
Manipulation on image types and layout, that do not belong to public API.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

*/
module gamut.internals.types;

import core.stdc.stdlib: realloc, free;

import gamut.types;

nothrow @nogc @safe:

/// Returns: `true` if this `ImageType` is "plain", meaning that it's 1/2/3/4 channel of L/LA/RGB/RGBA data.
/// Currently: all images are plain, or have no data.
bool imageTypeIsPlain(ImageType t) pure
{
    return true;
}

/// Returns: `true` if this `ImageType` is planar, meaning the data is best iterated by the user.
bool imageTypeIsPlanar(ImageType t) pure
{
    return false; // No support yet in gamut.
}

/// Returns: `true` if this `ImageType` is compressed, meaning the data is inscrutable until decoded.
bool imageTypeIsCompressed(ImageType t) pure
{
    return false; // No support yet in gamut.
}

/// Size of one pixel for given image type `type`.
int imageTypePixelSize(ImageType type) pure
{
    final switch(type)
    {
        case ImageType.l8:      return 1;
        case ImageType.l16:     return 2;
        case ImageType.lf32:    return 4;
        case ImageType.la8:     return 2;
        case ImageType.la16:    return 4;
        case ImageType.laf32:   return 8;
        case ImageType.rgb8:    return 3;
        case ImageType.rgb16:   return 6;
        case ImageType.rgba8:   return 4;
        case ImageType.rgba16:  return 8;
        case ImageType.rgbf32:  return 12;
        case ImageType.rgbaf32: return 16;
        case ImageType.unknown: assert(false);
    }
}

/// Number of channels in this image type.
int imageTypeNumChannels(ImageType type) pure
{
    final switch(type)
    {
        case ImageType.l8:   return 1;
        case ImageType.l16:  return 1;
        case ImageType.lf32:     return 1;
        case ImageType.la8:     return 2;
        case ImageType.la16:    return 2;
        case ImageType.laf32:   return 2;
        case ImageType.rgb8:    return 3;
        case ImageType.rgb16:   return 3;
        case ImageType.rgbf32:  return 3;
        case ImageType.rgba8:   return 4;
        case ImageType.rgba16:  return 4;
        case ImageType.rgbaf32: return 4;
        case ImageType.unknown: assert(false);
    }
}

/// Is this type 8-bit?
int imageTypeIs8Bit(ImageType type) pure
{
    switch(type)
    {
        case ImageType.l8:
        case ImageType.la8:
        case ImageType.rgb8:
        case ImageType.rgba8:
            return true;
        default:
            return false;
    }
}

/// Is this type 16-bit?
int imageTypeIs16Bit(ImageType type) pure
{
    switch(type)
    {
        case ImageType.l16:
        case ImageType.la16:
        case ImageType.rgb8:
        case ImageType.rgba8:
            return true;
        default:
            return false;
    }
}

/// Is this type 32-bit floating-point?
int imageTypeIsFP32(ImageType type) pure
{
    switch(type)
    {
        case ImageType.lf32:
        case ImageType.laf32:
        case ImageType.rgbf32:
        case ImageType.rgbaf32:
            return true;
        default:
            return false;
    }
}

/// Check if these image dimensions are valid in Gamut.
bool imageIsValidSize(int width, int height) pure
{
    if (width < 0 || height < 0)
        return false;

    if (width > GAMUT_MAX_IMAGE_WIDTH || height > GAMUT_MAX_IMAGE_HEIGHT)
        return false;

    long pixels = cast(long)width * cast(long)height;
    if (pixels > GAMUT_MAX_IMAGE_WIDTH_x_HEIGHT)
        return false;

    return true;
}


/// From a layout constraint, get requested pixel multiplicity.
int layoutMultiplicity(LayoutConstraints constraints)
{
    return 1 << (constraints & 3);
}
unittest
{
    assert(layoutMultiplicity(LAYOUT_MULTIPLICITY_1) == 1);
    assert(layoutMultiplicity(LAYOUT_MULTIPLICITY_8) == 8);
}

/// From a layout constraint, get requested trailing pixels.
int layoutTrailingPixels(LayoutConstraints constraints) @trusted
{
    return (1 << ((constraints & 0x0C) >> 2)) - 1;
}
unittest
{
    assert(layoutTrailingPixels(LAYOUT_TRAILING_0) == 0);
    assert(layoutTrailingPixels(LAYOUT_TRAILING_1) == 1);
    assert(layoutTrailingPixels(LAYOUT_TRAILING_3) == 3);
    assert(layoutTrailingPixels(LAYOUT_TRAILING_7 | LAYOUT_MULTIPLICITY_8) == 7);
}

/// From a layout constraint, get scanline alignment.
int layoutScanlineAlignment(LayoutConstraints constraints)
{
    return 1 << ((constraints >> 4) & 0x0f);
}
unittest
{
    assert(layoutScanlineAlignment(LAYOUT_SCANLINE_ALIGNED_1 | LAYOUT_TRAILING_7) == 1);
    assert(layoutScanlineAlignment(LAYOUT_SCANLINE_ALIGNED_128) == 128);
}

/// From a layout constraint, get surrounding border width.
int layoutBorderWidth(LayoutConstraints constraints)
{
    return (constraints >> 7) & 3;
}
unittest
{
    assert(layoutBorderWidth(LAYOUT_BORDER_0) == 0);
    assert(layoutBorderWidth(LAYOUT_BORDER_1) == 1);
    assert(layoutBorderWidth(LAYOUT_BORDER_2 | LAYOUT_TRAILING_7) == 2);
    assert(layoutBorderWidth(LAYOUT_BORDER_3) == 3);
}

/// _Assuming the same ImageType_, can an allocation made with constraint `older` 
/// be used with constraint `newer`?
bool layoutConstraintsCompatible(LayoutConstraints newer, LayoutConstraints older)
{
    if (layoutMultiplicity(newer) > layoutMultiplicity(older))
        return false;

    if (layoutTrailingPixels(newer) > layoutTrailingPixels(older))
        return false;

    if (layoutScanlineAlignment(newer) > layoutScanlineAlignment(older))
        return false;

    if (layoutBorderWidth(newer) > layoutBorderWidth(older))
        return false;

    return true; // is compatible
}

/// Allocate pixel data. Discard ancient data if any, and reallocate with `realloc`.
///
/// Returns true in `err` in case of success. If the function is successful 
/// then `deallocatePixelStorage` MUST be called later on.
///
/// Params:
///     existingData The existing `mallocArea` from a former call to `allocatePixelStorage`.
///     type         Pixel data type.
///     width        Image width.
///     height       Image height.
///     constraints  The layout constraints to follow for the scanlines and allocation.
///     bonusBytes   If non-zero, the area mallocArea[0..bonusBytes] can be used for user storage.
///                  Only the caller can use as temp storage, since Image won't preserve knowledge of these
///                  bonusBytes once the allocation is done.
///     dataPointer  The pointer to the first scanline.
///     mallocArea   The pointer to the allocation beginning. Will be different from dataPointer and
///                  must be kept somewhere.
///     pitchBytes   Byte offset between two adjacent scanlines. Scanlines cannot ever overlap.
///     err          True if successful. Only err indicates success, not mallocArea.
///
/// Note: even if you can request zero bytes, `realloc` can give you a non-null pointer, 
/// that you would have to keep. This is a success case given by `err` only.
void allocatePixelStorage(ubyte* existingData, 
                          ImageType type, 
                          int width, 
                          int height, 
                          LayoutConstraints constraints,
                          int bonusBytes,
                          out ubyte* dataPointer, // first scanline
                          out ubyte* mallocArea,  // the result of realloc-ed
                          out int pitchBytes,
                          out bool err) @trusted
{      
    assert(width >= 0); // width == 0 and height == 0 must be supported!
    assert(height >= 0);

    int border         = layoutBorderWidth(constraints);
    int rowAlignment   = layoutScanlineAlignment(constraints);
    int trailingPixels = layoutTrailingPixels(constraints);
    int xMultiplicity  = layoutMultiplicity(constraints);

    assert(border >= 0);
    assert(rowAlignment >= 1); // Not yet implemented!
    assert(xMultiplicity >= 1); // Not yet implemented!
    assert(trailingPixels >= 0);

    static size_t nextMultipleOf(size_t base, size_t multiple) pure
    {
        assert(multiple > 0);
        size_t n = (base + multiple - 1) / multiple;
        return multiple * n;
    }

    static int computeRightPadding(int width, int border, int xMultiplicity) pure
    {
        int nextMultiple = cast(int)(nextMultipleOf(width + border, xMultiplicity));
        return nextMultiple - (width + border);
    }    

    /// Returns: next pointer aligned with alignment bytes.
    static ubyte* nextAlignedPointer(ubyte* start, size_t alignment) pure
    {
        return cast(ubyte*)nextMultipleOf(cast(size_t)(start), alignment);
    }

    // Compute size of right border, in pixels.
    // How many "padding pixels" do we need to extend the right border with to respect `xMultiplicity`?
    int rightPadding = computeRightPadding(width, border, xMultiplicity);
    int borderRight = border + rightPadding;
    if (borderRight < trailingPixels)
        borderRight = trailingPixels;

    int actualWidthInPixels  = border + width  + borderRight;
    int actualHeightInPixels = border + height + border;

    // Compute byte pitch and align it on `rowAlignment`
    int pixelSize = imageTypePixelSize(type);
    int bytePitch = pixelSize * actualWidthInPixels;
    bytePitch = cast(int) nextMultipleOf(bytePitch, rowAlignment);

    // How many bytes do we need for all samples? A bit more for aligning the first valid pixel.
    size_t allocationSize = bytePitch * actualHeightInPixels;
    allocationSize += (rowAlignment - 1) + bonusBytes;

    // We don't need to preserve former data, nor to align the allocation.
    // Note: allocationSize can legally be zero.
    ubyte* allocation = cast(ubyte*) realloc(existingData, allocationSize);

    // realloc is allowed to return null if zero bytes required.
    if (allocationSize != 0 && allocation is null) 
    {
        err = true;
        return;
    }

    // Compute pointer to pixel data itself.
    size_t offsetToFirstMeaningfulPixel = bonusBytes + bytePitch * border + pixelSize * border;       
    ubyte* pixels = nextAlignedPointer(allocation + offsetToFirstMeaningfulPixel, rowAlignment);

    dataPointer = pixels;
    mallocArea = allocation;
    pitchBytes = bytePitch;
    err = false;
}

/// Deallocate pixel data. Everything allocated with `allocatePixelStorage` eventually needs
/// to be through that function.
void deallocatePixelStorage(void* mallocArea) @trusted
{
    free(mallocArea);
}

bool validLoadFlags(LoadFlags loadFlags) pure
{
    if ((loadFlags & LOAD_GREYSCALE) && (loadFlags & LOAD_RGB)) return false;
    if ((loadFlags & LOAD_ALPHA) && (loadFlags & LOAD_NO_ALPHA)) return false;

    int bitnessFlags = 0;
    if (loadFlags & LOAD_8BIT) ++bitnessFlags;
    if (loadFlags & LOAD_16BIT) ++bitnessFlags;
    if (loadFlags & LOAD_FP32) ++bitnessFlags;
    if (bitnessFlags > 1)
        return false;

    return true;
}



// Load flags to components asked, intended for an image decoder. 
// This is for STB-style loading who can convert scanline as they are decoded.
//
// Return: 
//   -1 => keep input number of components
//    0 => error
//    1/2/3/4 => forced number of components.
int computeRequestedImageComponents(LoadFlags loadFlags) pure nothrow @nogc @safe
{
    int requestedComp = -1; // keep original

    if (!validLoadFlags(loadFlags))
        return 0;

    if (loadFlags & LOAD_GREYSCALE)
    {
        if (loadFlags & LOAD_ALPHA)
            requestedComp = 2;
        else if (loadFlags & LOAD_NO_ALPHA)
            requestedComp = 1;
    }
    else if (loadFlags & LOAD_RGB)
    {
        if (loadFlags & LOAD_ALPHA)
            requestedComp = 4;
        else if (loadFlags & LOAD_NO_ALPHA)
            requestedComp = 3;
    }
    return requestedComp;
}
unittest
{
    assert(computeRequestedImageComponents(LOAD_GREYSCALE) == -1); // keep same, because it is alpha-preserving.
    assert(computeRequestedImageComponents(LOAD_GREYSCALE | LOAD_NO_ALPHA) == 1);
    assert(computeRequestedImageComponents(LOAD_GREYSCALE | LOAD_ALPHA) == 2);
    assert(computeRequestedImageComponents(LOAD_GREYSCALE | LOAD_ALPHA | LOAD_NO_ALPHA) == 0); // invalid
    assert(computeRequestedImageComponents(LOAD_RGB) == -1);
    assert(computeRequestedImageComponents(LOAD_RGB | LOAD_NO_ALPHA) == 3);
    assert(computeRequestedImageComponents(LOAD_RGB | LOAD_GREYSCALE) == 0); // invalid
    assert(computeRequestedImageComponents(LOAD_RGB | LOAD_ALPHA) == 4);
}


// Type conversion.

/// From a type and LoadFlags, get the target type using the loading flags.
/// This is when the decoder doesn't support inside conversion and we need to use convertTo.
ImageType applyLoadFlags(ImageType type, LoadFlags flags)
{
    // Check incompatible load flags.
    if (!validLoadFlags(flags))
        return ImageType.unknown;

    if (flags & LOAD_GREYSCALE)
        type = convertImageTypeToGreyscale(type);

    if (flags & LOAD_RGB)
        type = convertImageTypeToRGB(type);

    if (flags & LOAD_ALPHA)
        type = convertImageTypeToAddAlphaChannel(type);

    if (flags & LOAD_NO_ALPHA)
        type = convertImageTypeToDropAlphaChannel(type);

    if (flags & LOAD_8BIT)
        type = convertImageTypeTo8Bit(type);

    if (flags & LOAD_16BIT)
        type = convertImageTypeTo16Bit(type);

    if (flags & LOAD_FP32)
        type = convertImageTypeToFP32(type);

    return type;
}

ImageType convertImageTypeToGreyscale(ImageType type)
{
    ImageType t = ImageType.unknown;
    final switch(type) with (ImageType)
    {
        case unknown: t = unknown; break;
        case l8:      t = l8; break;
        case l16:     t = l16; break;
        case lf32:    t = lf32; break;
        case la8:     t = la8; break;
        case la16:    t = la16; break;
        case laf32:   t = laf32; break;
        case rgb8:    t = l8; break;
        case rgb16:   t = l16; break;
        case rgbf32:  t = lf32; break;
        case rgba8:   t = la8; break;
        case rgba16:  t = la16; break;
        case rgbaf32: t = laf32; break;
    }
    return t;
}

ImageType convertImageTypeToRGB(ImageType type)
{
    ImageType t = ImageType.unknown;
    final switch(type) with (ImageType)
    {
        case unknown: t = unknown; break;
        case l8:      t = rgb8; break;
        case l16:     t = rgb16; break;
        case lf32:    t = rgbf32; break;
        case la8:     t = rgba8; break;
        case la16:    t = rgba16; break;
        case laf32:   t = rgbaf32; break;
        case rgb8:    t = rgb8; break;
        case rgb16:   t = rgb16; break;
        case rgbf32:  t = rgbf32; break;
        case rgba8:   t = rgba8; break;
        case rgba16:  t = rgba16; break;
        case rgbaf32: t = rgbaf32; break;
    }
    return t;
}

ImageType convertImageTypeToAddAlphaChannel(ImageType type)
{
    ImageType t = ImageType.unknown;
    final switch(type) with (ImageType)
    {
        case unknown: t = unknown; break;
        case l8:      t = la8; break;
        case l16:     t = la16; break;
        case lf32:    t = laf32; break;
        case la8:     t = la8; break;
        case la16:    t = la16; break;
        case laf32:   t = laf32; break;
        case rgb8:    t = rgba8; break;
        case rgb16:   t = rgba16; break;
        case rgbf32:  t = rgbaf32; break;
        case rgba8:   t = rgba8; break;
        case rgba16:  t = rgba16; break;
        case rgbaf32: t = rgbaf32; break;
    }
    return t;
}

ImageType convertImageTypeToDropAlphaChannel(ImageType type)
{
    ImageType t = ImageType.unknown;
    final switch(type) with (ImageType)
    {
        case unknown: t = unknown; break;
        case l8:      t = l8; break;
        case l16:     t = l16; break;
        case lf32:    t = lf32; break;
        case la8:     t = l8; break;
        case la16:    t = l16; break;
        case laf32:   t = lf32; break;
        case rgb8:    t = rgb8; break;
        case rgb16:   t = rgb16; break;
        case rgbf32:  t = rgbf32; break;
        case rgba8:   t = rgb8; break;
        case rgba16:  t = rgb16; break;
        case rgbaf32: t = rgbf32; break;
    }
    return t;
}

ImageType convertImageTypeTo8Bit(ImageType type)
{
    ImageType t = ImageType.unknown;       
    final switch(type) with (ImageType)
    {
        case unknown: t = unknown; break;
        case l8:      t = l8; break;
        case l16:     t = l8; break;
        case lf32:    t = l8; break;
        case la8:     t = la8; break;
        case la16:    t = la8; break;
        case laf32:   t = la8; break;
        case rgb8:    t = rgb8; break;
        case rgb16:   t = rgb8; break;
        case rgbf32:  t = rgb8; break;
        case rgba8:   t = rgba8; break;
        case rgba16:  t = rgba8; break;
        case rgbaf32: t = rgba8; break;
    }
    return t;
}

ImageType convertImageTypeTo16Bit(ImageType type)
{
    ImageType t = ImageType.unknown;       
    final switch(type) with (ImageType)
    {
        case unknown: t = unknown; break;
        case l8:      t = l16; break;
        case l16:     t = l16; break;
        case lf32:    t = l16; break;
        case la8:     t = la16; break;
        case la16:    t = la16; break;
        case laf32:   t = la16; break;
        case rgb8:    t = rgb16; break;
        case rgb16:   t = rgb16; break;
        case rgbf32:  t = rgb16; break;
        case rgba8:   t = rgba16; break;
        case rgba16:  t = rgba16; break;
        case rgbaf32: t = rgba16; break;
    }
    return t;
}


ImageType convertImageTypeToFP32(ImageType type)
{
    ImageType t = ImageType.unknown;       
    final switch(type) with (ImageType)
    {
        case unknown: t = unknown; break;
        case l8:      t = lf32; break;
        case l16:     t = lf32; break;
        case lf32:    t = lf32; break;
        case la8:     t = laf32; break;
        case la16:    t = laf32; break;
        case laf32:   t = laf32; break;
        case rgb8:    t = rgbf32; break;
        case rgb16:   t = rgbf32; break;
        case rgbf32:  t = rgbf32; break;
        case rgba8:   t = rgbaf32; break;
        case rgba16:  t = rgbaf32; break;
        case rgbaf32: t = rgbaf32; break;
    }
    return t;
}

