/**
Various public types.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
      See the differences in DIFFERENCES.md
*/
module gamut.types;


/// Image format.
enum ImageFormat
{
    unknown = -1, /// Unknown format (returned value only, never use it as input value)
    first   =  0,
    JPEG    =  0, /// Independent JPEG Group (*.JPG, *.JIF, *.JPEG, *.JPE)
    PNG     =  1, /// Portable Network Graphics (*.PNG)
    QOI     =  2  /// Quite OK Image format (*.QOI)
}

/// Number of internally-supported formats. Equal to 1 + maximum internal format (here: FIF_QOI).
package enum int FREE_IMAGE_FORMAT_NUM = cast(int)(ImageFormat.QOI) + 1; 

/// Image format.
enum ImageType
{
    unknown = -1, /// Unknown format (returned value only, never use it as input value)
    uint8 = 0,    /// Array of ushort: unsigned 8-bit
    int8,         /// Array of short: signed 8-bit
    uint16,       /// Array of ushort: unsigned 16-bit
    int16,        /// Array of short: signed 16-bit
    uint32,       /// Array of uint: unsigned 32-bit
    int32,        /// Array of int: signed 32-bit
    f32,          /// Array of float: 32-bit IEEE floating point
    f64,          /// Array of double: 64-bit IEEE floating point

    la8,          /// 16-bit Luminance Alpha image: 2 x unsigned 8-bit
    la16,         /// 32-bit Luminance Alpha image: 2 x unsigned 16-bit

    rgb8,         /// 24-bit RGB image: 3 x unsigned 8-bit
    rgb16,        /// 48-bit RGB image: 3 x unsigned 16-bit

    rgba8,        /// 32-bit RGBA image: 4 x unsigned 8-bit
    rgba16,       /// 64-bit RGBA image: 4 x unsigned 16-bit

    rgbf32,       /// 96-bit RGB float image: 3 x 32-bit IEEE floating point
    rgbaf32,      /// 128-bit RGBA float image: 4 x 32-bit IEEE floating point
}


// Load flags

enum int JPEG_DEFAULT = 0;    /// Default JPEG loading.

/// Load the JPEG in grayscale, faster than loading as RGB24 then converting to greyscale.
/// Can't be used with either `JPEG_RGB` or `JPEG_RGBA`.
// TODO: make that supported by every codec.
enum int JPEG_GREYSCALE = 1;

/// Load the JPEG in RGB8, can be faster than loading a greyscale JPEG then converting to RGB8.
/// Can't be used with either `JPEG_GREYSCALE` or `JPEG_RGBA`.
// TODO: make that supported by every codec.
enum int JPEG_RGB = 2;

/// Load the JPEG in RGBA8, can be faster than loading a JPEG then converting to RGBA8.
/// Can't be used with either `JPEG_GREYSCALE` or `JPEG_RGB`.
// TODO: make that supported by every codec.
enum int JPEG_RGBA = 4;
