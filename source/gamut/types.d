/**
Various public types.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.types;

import core.stdc.stdlib: realloc, free;

nothrow @nogc:
@safe:

/// Image format.
enum ImageFormat
{
    unknown = -1, /// Unknown format (returned value only, never use it as input value)
    first   =  0,
    JPEG    =  0, /// Independent JPEG Group (*.JPG, *.JIF, *.JPEG, *.JPE)
    PNG     =  1, /// Portable Network Graphics (*.PNG)
    QOI     =  2, /// Quite OK Image format (*.QOI)
    QOIX    =  3, /// Quite OK Image format, eXtended as in Gamut (*.QOIX)
    DDS     =  4  /// Compressed texture formats.
}

/// Image format.
enum ImageType
{
    unknown = -1, /// Unknown format (returned value only, never use it as input value)
    uint8 = 0,    /// Array of ushort: unsigned 8-bit
    uint16,       /// Array of ushort: unsigned 16-bit
    f32,          /// Array of float: 32-bit IEEE floating point
    
    la8,          /// 16-bit Luminance Alpha image: 2 x unsigned 8-bit
    la16,         /// 32-bit Luminance Alpha image: 2 x unsigned 16-bit
    laf32,        /// 64-bit Luminance Alpha image: 2 x 32-bit IEEE floating point

    rgb8,         /// 24-bit RGB image: 3 x unsigned 8-bit
    rgb16,        /// 48-bit RGB image: 3 x unsigned 16-bit
    rgbf32,       /// 96-bit RGB float image: 3 x 32-bit IEEE floating point

    rgba8,        /// 32-bit RGBA image: 4 x unsigned 8-bit
    rgba16,       /// 64-bit RGBA image: 4 x unsigned 16-bit    
    rgbaf32,      /// 128-bit RGBA float image: 4 x 32-bit IEEE floating point
}

/// Returns: `true` if this `ImageType` is "plain", meaning that it's 1/2/3/4 channel of L/LA/RGB/RGBA data.
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
        case ImageType.uint8:   return 1;
        case ImageType.uint16:  return 2;
        case ImageType.f32:     return 4;
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

// Limits


/// When images have an unknown width.
enum GAMUT_INVALID_IMAGE_WIDTH = -1;  

/// When images have an unknown height.
enum GAMUT_INVALID_IMAGE_HEIGHT = -1; 

/// When images have an unknown DPI resolution;
enum GAMUT_UNKNOWN_RESOLUTION = -1;

/// When images have an unknown physical pixel ratio.
/// Explanation: it is possible to have a known pixel ratio, but an unknown DPI (eg: PNG).
enum GAMUT_UNKNOWN_ASPECT_RATIO = -1;


/// Converts from meters to inches.
float convertMetersToInches(float x) pure
{
    return x * 39.37007874f;
}

/// Converts from inches to meters.
float convertInchesToMeters(float x) pure
{
    return x / 39.37007874f;
}

/// Converts from PPM (Points Per Meter) to DPI (Dots Per Inch).
alias convertPPMToDPI = convertInchesToMeters;

/// Converts from DPI (Dots Per Inch) to PPM (Points Per Meter).
alias convertDPIToPPM = convertMetersToInches;


/// No Gamut `Image` can exceed this width in gamut.
enum int GAMUT_MAX_IMAGE_WIDTH = 16777216;  

/// No Gamut `Image` can exceed this height in gamut.
enum int GAMUT_MAX_IMAGE_HEIGHT = 16777216;

/// No Gamut `Image` can have a width x height product that exceed this value of 67 Mpixels.
enum int GAMUT_MAX_IMAGE_WIDTH_x_HEIGHT = 67108864;

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

/// Load flags (range: bits 16 to 23).
alias LoadFlags = int;

/// No loading options.
/// Supported by: JPEG, PNG, QOI, QOIX.
enum LoadFlags LOAD_NORMAL = 0; 

/// Load the image in grayscale, faster than loading as RGB8 then converting to greyscale.
/// Can't be used with either `LOAD_RGB` or `LOAD_RGBA`.
/// Supported by: JPEG, PNG.
enum LoadFlags LOAD_GREYSCALE = 0x1000;

/// Load the image in RGB8/RGB16, faster than loading a greyscale image and then converting to RGB8/RGB16.
/// Can't be used with either `LOAD_GREYSCALE` or `LOAD_RGBA`.
/// Supported by: JPEG, PNG, QOI, QOIX.
enum LoadFlags LOAD_RGB       = 0x2000; 

/// Load the image in RGBA8/RGBA16, faster than loading as RGB8 then converting to RGBA8/RGBA16.
/// Can't be used with either `LOAD_GREYSCALE` or `LOAD_RGBA`.
/// Supported by: JPEG, PNG, QOI, QOIX.
enum LoadFlags LOAD_RGBA      = 0x4000;

/// Only decode metadata, not the pixels themselves.
/// Supported by: none yet.
enum LoadFlags LOAD_NOPIXELS  = 0x8000;


// Encode flags

/// Do nothing particular.
/// Supported by: JPEG, PNG, DDS, QOI, QOIX.
enum int ENCODE_NORMAL = 0;

/// Internal use, this is to test a variation of a compiler.
/// Supported by: JPEG, PNG, DDS, QOI, QOIX.
enum int ENCODE_CHALLENGER = 4;


/// Layout constraints flags.
/// All of those introduce "gap pixels" after the scanline, in order to follow the various constraints.
///
/// Example: if you want to process 4x RGBA8 pixels at once, with aligned SSE, use:
///    `LAYOUT_MULTIPLICITY_4 | LAYOUT_SCANLINE_ALIGNED_16`
alias LayoutConstraints = ushort;

enum LayoutConstraints
     LAYOUT_DEFAULT              = 0,  /// Default / do-not-care layout options.
     LAYOUT_GAPLESS              = 0,  /// No requirements for either scanline alignment, trailing samples, multiplicity, or borders. Pixels are gapless.
                                       /// `LAYOUT_GAPLESS` is incompatible with any other flags.
                                       /// An image _can_ be accidentally gapless without `LayoutConstraints == 0`.
                                       /// but it isn't guaranteed.

     // Multiplicity: allows to access by packing them together, without stepping on the next scanline or segfault..
     LAYOUT_MULTIPLICITY_1       = 0,  /// No particular multiplicity requirements.
     LAYOUT_MULTIPLICITY_2       = 1,  /// Beginning at the start of a scanline, pixels can be accessed 2 by 2 without segfault.
     LAYOUT_MULTIPLICITY_4       = 2,  /// Beginning at the start of a scanline, pixels can be accessed 4 by 4 without segfault.
     LAYOUT_MULTIPLICITY_8       = 3,  /// Beginning at the start of a scanline, pixels can be accessed 8 by 8 without segfault.
     
     // Trailing pixels: allows to access the very end of a scanline with SIMD, without stepping on the next scanline or segfault..
     LAYOUT_TRAILING_0           = 0,  /// Scanlines have no trailing requirements.
     LAYOUT_TRAILING_1           = 4,  /// Scanlines must be followed by at least 1 gap pixels.
     LAYOUT_TRAILING_3           = 8,  /// Scanlines must be followed by at least 3 gap pixels.
     LAYOUT_TRAILING_7           = 12, /// Scanlines must be followed by at least 7 gap pixels.
     
     // Scanline alignment: allows to access pixels from start of scanline with aligned SIMD.
     LAYOUT_SCANLINE_ALIGNED_1   = 0,  /// No particular alignment for scanline.
     LAYOUT_SCANLINE_ALIGNED_2   = 16, /// Scanlines required to be at least aligned on 2 bytes boundaries.
     LAYOUT_SCANLINE_ALIGNED_4   = 32, /// Scanlines required to be at least aligned on 4 bytes boundaries.
     LAYOUT_SCANLINE_ALIGNED_8   = 48, /// Scanlines required to be at least aligned on 8 bytes boundaries.
     LAYOUT_SCANLINE_ALIGNED_16  = 64, /// Scanlines required to be at least aligned on 16 bytes boundaries.
     LAYOUT_SCANLINE_ALIGNED_32  = 80, /// Scanlines required to be at least aligned on 32 bytes boundaries.
     LAYOUT_SCANLINE_ALIGNED_64  = 96, /// Scanlines required to be at least aligned on 64 bytes boundaries.
     LAYOUT_SCANLINE_ALIGNED_128 = 112, /// Scanlines required to be at least aligned on 128 bytes boundaries.

     // Allow to access additional pixels in every direction, without segfault or steppig on the next scanline.
     LAYOUT_BORDER_0             = 0,   /// No particular border constraint.
     LAYOUT_BORDER_1             = 128, /// The whole image has a border of 1 pixel addressable without segfault.
     LAYOUT_BORDER_2             = 256, /// The whole image has a border of 2 pixels addressable without segfault.
     LAYOUT_BORDER_3             = 384; /// The whole image has a border of 3 pixels addressable without segfault.

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

/// Allocate pixel data. Discard ancient data, and reallocate with `realloc`.
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
///     bonusBytes   If non-zero, the area dataPointer[0..bonusBytes] can be used for user storage.
///     dataPointer  The pointer to the first scanline.
///     mallocArea   The pointer to the allocation beginning. Will be different from dataPointer and
///                  must be kept somewhere.
///     pitchBytes   Byte offset between two adjacent scanlines. Scanlines cannot ever overlap.
///     err          True if successful.
///
/// Note: even if you can request zero bytes, `realloc` can give you a non-null pointer, 
/// that you would have to keep. This is a success case given by `err` only.
void allocatePixelStorage(ubyte* existingData, 
                          ImageType type, 
                          int width, 
                          int height, 
                          LayoutConstraints constraints,
                          size_t bonusBytes,
                          out ubyte* dataPointer, // first scanline
                          out ubyte* mallocArea,  // the result of realloc-ed
                          out int pitchBytes,
                          out bool err) @trusted
{      
    // TODO support layout constraints

    int size = imageTypePixelSize(type) * width * height;
    
    // PERF: all gamut using same heap? to reuse allocation.
    ubyte* res = cast(ubyte*) realloc(existingData, size);

    err = false;
    if (size != 0 && res is null) // realloc is allowed to return null if zero bytes required.
    {
        err = true;
        return;
    }

    dataPointer = res;
    mallocArea = res;
    pitchBytes = imageTypePixelSize(type) * width;
}

/// Deallocate pixel data. Everything allocated with `allocatePixelStorage` eventually needs
/// to be through that function.
void deallocatePixelStorage(void* mallocArea) @trusted
{
    free(mallocArea);
}
