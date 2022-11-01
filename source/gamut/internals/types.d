/**
Manipulation on image types and layout, that do not belong to public API.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

*/
module gamut.internals.types;

import core.stdc.stdlib: realloc, free;

import gamut.types;

nothrow @nogc @safe:

enum LayoutConstraints
    LAYOUT_MULTIPLICITY_MASK     = 3,
    LAYOUT_TRAILING_MASK         = 12,
    LAYOUT_BORDER_MASK           = 384,
    LAYOUT_SCANLINE_ALIGNED_MASK = 112;


/// Returns: `true` if this `PixelType` is "plain", meaning that it's 1/2/3/4 channel of L/LA/RGB/RGBA data.
/// Currently: all images are plain, or have no data.
bool pixelTypeIsPlain(PixelType t) pure
{
    return true;
}

/// Returns: `true` if this `PixelType` is planar, completely unsupported for now.
bool pixelTypeIsPlanar(PixelType t) pure
{
    return false; // No support yet in gamut.
}

/// Returns: `true` if this `PixelType` is compressed, meaning the data is inscrutable until decoded.
bool pixelTypeIsCompressed(PixelType t) pure
{
    return false; // No support yet in gamut.
}

/// Size of one pixel for given pixel type `type`, in bytes.
int pixelTypeSize(PixelType type) pure
{
    final switch(type) with (PixelType)
    {
        case l8:      return 1;
        case l16:     return 2;
        case lf32:    return 4;
        case la8:     return 2;
        case la16:    return 4;
        case laf32:   return 8;
        case rgb8:    return 3;
        case rgb16:   return 6;
        case rgba8:   return 4;
        case rgba16:  return 8;
        case rgbf32:  return 12;
        case rgbaf32: return 16;
        case unknown: assert(false);
    }
}

enum int GAMUT_MAX_PIXEL_SIZE = 16; // keep it in sync

/// Number of channels in this image type.
int pixelTypeNumChannels(PixelType type) pure
{
    final switch(type) with (PixelType)
    {
        case l8:      return 1;
        case l16:     return 1;
        case lf32:    return 1;
        case la8:     return 2;
        case la16:    return 2;
        case laf32:   return 2;
        case rgb8:    return 3;
        case rgb16:   return 3;
        case rgbf32:  return 3;
        case rgba8:   return 4;
        case rgba16:  return 4;
        case rgbaf32: return 4;
        case unknown: assert(false);
    }
}

/// Is this type 8-bit?
bool pixelTypeIs8Bit(PixelType type) pure
{
    switch(type) with (PixelType)
    {
        case l8:
        case la8:
        case rgb8:
        case rgba8:
            return true;
        default:
            return false;
    }
}

/// Is this type 16-bit?
bool pixelTypeIs16Bit(PixelType type) pure
{
    switch(type) with (PixelType)
    {
        case l16:
        case la16:
        case rgb8:
        case rgba8:
            return true;
        default:
            return false;
    }
}

/// Is this type 32-bit floating-point?
int pixelTypeIsFP32(PixelType type) pure
{
    switch(type) with (PixelType)
    {
        case lf32:
        case laf32:
        case rgbf32:
        case rgbaf32:
            return true;
        default:
            return false;
    }
}

/// Can this pixel type be losslessly expressed in rgba8?
bool pixelTypeExpressibleInRGBA8(PixelType type) pure
{
    return pixelTypeIs8Bit(type);
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
int layoutMultiplicity(LayoutConstraints constraints) pure
{
    return 1 << (constraints & 3);
}
unittest
{
    assert(layoutMultiplicity(LAYOUT_MULTIPLICITY_1) == 1);
    assert(layoutMultiplicity(LAYOUT_MULTIPLICITY_8) == 8);
}

/// From a layout constraint, get requested trailing pixels.
int layoutTrailingPixels(LayoutConstraints constraints) pure @trusted
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
int layoutScanlineAlignment(LayoutConstraints constraints) pure
{
    return 1 << ((constraints >> 4) & 0x0f);
}
unittest
{
    assert(layoutScanlineAlignment(LAYOUT_SCANLINE_ALIGNED_1 | LAYOUT_TRAILING_7) == 1);
    assert(layoutScanlineAlignment(LAYOUT_SCANLINE_ALIGNED_128) == 128);
}


/// What is the scanline alignement of such a pointer?
LayoutConstraints getPointerAlignment(size_t ptr)
{
    if ( (ptr & 127) == 0) return LAYOUT_SCANLINE_ALIGNED_128;
    if ( (ptr & 63) == 0) return LAYOUT_SCANLINE_ALIGNED_64;
    if ( (ptr & 31) == 0) return LAYOUT_SCANLINE_ALIGNED_32;
    if ( (ptr & 15) == 0) return LAYOUT_SCANLINE_ALIGNED_16;
    if ( (ptr & 7) == 0) return LAYOUT_SCANLINE_ALIGNED_8;
    if ( (ptr & 3) == 0) return LAYOUT_SCANLINE_ALIGNED_4;
    if ( (ptr & 1) == 0) return LAYOUT_SCANLINE_ALIGNED_2;
    return LAYOUT_SCANLINE_ALIGNED_1;
}

/// From a layout constraint, get surrounding border width.
int layoutBorderWidth(LayoutConstraints constraints) pure
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

/// From a layout constraint, get if being gapless is guaranteed.
bool layoutGapless(LayoutConstraints constraints) pure
{
    return (constraints & LAYOUT_GAPLESS) != 0;
}
unittest
{
    assert(layoutGapless(LAYOUT_GAPLESS));
    assert(!layoutGapless(0));
}

/// Assuming the same `PixelType`, can an allocation made with constraint `older` 
/// be used with constraint `newer`?
/// Note: `older` doesn't need to be a valid LayoutConstraints, but newer must be. 
bool layoutConstraintsCompatible(LayoutConstraints newer, LayoutConstraints older) pure
{
    if ((newer & LAYOUT_GAPLESS) && !(older & LAYOUT_GAPLESS))
        return false;

    if ((newer & LAYOUT_VERT_FLIPPED) && !(older & LAYOUT_VERT_FLIPPED))
        return false;
    if ((newer & LAYOUT_VERT_STRAIGHT) && !(older & LAYOUT_VERT_STRAIGHT))
        return false;

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

/// _Assuming the same `PixelType`, can an allocation made with constraint `older` 
/// be used with constraint `newer`?
bool layoutConstraintsValid(LayoutConstraints constraints) pure
{
    bool forceVFlipped    = (constraints & LAYOUT_VERT_FLIPPED) != 0;
    bool forceNonVFlipped = (constraints & LAYOUT_VERT_STRAIGHT) != 0;

    if (forceVFlipped && forceNonVFlipped)
        return false; // Can't be flipped and non-flipped at the same time.

    // LAYOUT_GAPLESS is incompatible with almost anything
    if (layoutGapless(constraints))
    {
        if (layoutMultiplicity(constraints) > 1)
            return false;
        if (layoutTrailingPixels(constraints) > 0)
            return false;
        if (layoutScanlineAlignment(constraints) > 1)
            return false;
        if (layoutBorderWidth(constraints) > 0)
            return false;
    }

    return true; // Those constraints are not exclusive.
}


// As input: first scanline pointer and pitch in byte.
// As output: same, but following the constraints (flipped optionally).
// This is a way to flip image vertically.
void flipScanlinePointers(int width,
                          int height,
                          ref ubyte* dataPointer, 
                          ref int bytePitch) pure @system
{
    if (height >= 2) // Nothing to do for 0 or 1 row
    {
        ptrdiff_t offset_to_Nm1_row = cast(ptrdiff_t)(bytePitch) * (height - 1);
        dataPointer += offset_to_Nm1_row;
    }
    bytePitch = -bytePitch;
}

// As input: first scanline pointer and pitch in byte.
// As output: same, but following the constraints (flipped optionally).
void applyVFlipConstraintsToScanlinePointers(int width,
                                             int height,
                                             ref ubyte* dataPointer, 
                                             ref int bytePitch,
                                             LayoutConstraints constraints) pure @system
{
    assert(layoutConstraintsValid(constraints));

    bool forceVFlipStorage    = (constraints & LAYOUT_VERT_FLIPPED) != 0;
    bool forceNonVFlipStorage = (constraints & LAYOUT_VERT_STRAIGHT) != 0;

    // Should we flip the first scanline pointer and pitch?
    bool shouldFlip = ( forceVFlipStorage && bytePitch > 0) || (forceNonVFlipStorage && bytePitch < 0);

    if (shouldFlip)
    {
        flipScanlinePointers(width, height, dataPointer, bytePitch);      
    }
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
///     constraints  The layout constraints to follow for the scanlines and allocation. MUST be valid.
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
                          PixelType type, 
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
    assert(layoutConstraintsValid(constraints));

    int border         = layoutBorderWidth(constraints);
    int rowAlignment   = layoutScanlineAlignment(constraints);
    int trailingPixels = layoutTrailingPixels(constraints);
    int xMultiplicity  = layoutMultiplicity(constraints);
    bool gapless       = layoutConstraintsValid(constraints);

    assert(border >= 0);
    assert(rowAlignment >= 1);
    assert(xMultiplicity >= 1);
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
    int pixelSize = pixelTypeSize(type);
    int bytePitch = pixelSize * actualWidthInPixels;
    bytePitch = cast(int) nextMultipleOf(bytePitch, rowAlignment);

    assert(bytePitch >= 0);

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

    // Apply vertical constraints: will the image be stored upside-down?
    ubyte* firstScanlinePtr = pixels;
    int finalPitchInBytes = bytePitch;
    applyVFlipConstraintsToScanlinePointers(width, height, firstScanlinePtr, finalPitchInBytes, constraints);

    dataPointer = firstScanlinePtr;
    pitchBytes = finalPitchInBytes;
    mallocArea = allocation;
    err = false;

    // Check validity of result
    {
        // check gapless
        int scanWidth = pixelSize * width;
        if (gapless)
            assert(scanWidth == (bytePitch < 0 ? -bytePitch : bytePitch));
        
        // check row alignment
        static bool isPointerAligned(void* p, size_t alignment) pure
        {
            assert(alignment != 0);
            return ( cast(size_t)p & (alignment - 1) ) == 0;
        }        
        assert(isPointerAligned(dataPointer, rowAlignment));
        assert(isPointerAligned(dataPointer + pitchBytes, rowAlignment));
    }
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
PixelType applyLoadFlags(PixelType type, LoadFlags flags)
{
    // Check incompatible load flags.
    if (!validLoadFlags(flags))
        return PixelType.unknown;

    if (flags & LOAD_GREYSCALE)
        type = convertPixelTypeToGreyscale(type);

    if (flags & LOAD_RGB)
        type = convertPixelTypeToRGB(type);

    if (flags & LOAD_ALPHA)
        type = convertPixelTypeToAddAlphaChannel(type);

    if (flags & LOAD_NO_ALPHA)
        type = convertPixelTypeToDropAlphaChannel(type);

    if (flags & LOAD_8BIT)
        type = convertPixelTypeTo8Bit(type);

    if (flags & LOAD_16BIT)
        type = convertPixelTypeTo16Bit(type);

    if (flags & LOAD_FP32)
        type = convertPixelTypeToFP32(type);

    return type;
}

