/**
Various public types.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
      See the differences in DIFFERENCES.md
*/
module gamut.types;

/// TRUE constant. To avoid name clashes, was renamed to FI_TRUE.
enum int FI_TRUE = 1;

/// FALSE constant. To avoid name clashes, was renamed to FI_FALSE.
enum int FI_FALSE = 0;

/// Image codec.
alias FREE_IMAGE_FORMAT = int;

enum : FREE_IMAGE_FORMAT
{
    FIF_UNKNOWN = -1, /// Unknown format (returned value only, never use it as input value)
    FIF_JPEG    =  0, /// Independent JPEG Group (*.JPG, *.JIF, *.JPEG, *.JPE)
    FIF_PNG     =  1, /// Portable Network Graphics (*.PNG)
    FIF_QOI     =  2  /// Quite OK Image format (*.QOI)
}

/// Number of internally-supported formats. Equal to 1 + maximum internal format (here: FIF_QOI).
package enum int FREE_IMAGE_FORMAT_NUM = 25; 

/// Image format.
alias FREE_IMAGE_TYPE = int;

enum : FREE_IMAGE_TYPE
{
    FIT_UNKNOWN = -1,/// Unknown format (returned value only, never use it as input value)
    
    FIT_UINT8 = 0,   /// Array of ushort: unsigned 8-bit
    FIT_INT8,        /// Array of short: signed 8-bit
    FIT_UINT16,      /// Array of ushort: unsigned 16-bit
    FIT_INT16,       /// Array of short: signed 16-bit
    FIT_UINT32,      /// Array of uint: unsigned 32-bit
    FIT_INT32,       /// Array of int: signed 32-bit
    FIT_FLOAT,       /// Array of float: 32-bit IEEE floating point
    FIT_DOUBLE,      /// Array of double: 64-bit IEEE floating point
    FIT_COMPLEX,     /// Array of FICOMPLEX: 2 x 64-bit IEEE floating point

    FIT_LA8,         /// 16-bit Luminance Alpha image: 2 x unsigned 8-bit
    FIT_LA16,        /// 32-bit Luminance Alpha image: 2 x unsigned 16-bit

    FIT_RGB8,        /// 24-bit RGB image: 3 x unsigned 8-bit
    FIT_RGB16,       /// 48-bit RGB image: 3 x unsigned 16-bit

    FIT_RGBA8,       /// 32-bit RGBA image: 4 x unsigned 8-bit
    FIT_RGBA16,      /// 64-bit RGBA image: 4 x unsigned 16-bit

    FIT_RGBF,        /// 96-bit RGB float image: 3 x 32-bit IEEE floating point
    FIT_RGBAF,       /// 128-bit RGBA float image: 4 x 32-bit IEEE floating point
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
