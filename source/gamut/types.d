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
    FIF_BMP     =  0, /// Windows or OS/2 Bitmap File (*.BMP)
    FIF_GIF     =  1, /// Graphics Interchange Format (*.GIF)
    FIF_JPEG    =  2, /// Independent JPEG Group (*.JPG, *.JIF, *.JPEG, *.JPE)
    FIF_PNG     =  3, /// Portable Network Graphics (*.PNG)
    FIF_TIFF    =  4, /// Tagged Image File Format (*.TIF, *.TIFF)
    FIF_QOI     =  24 /// Quite OK Image format (*.QOI)
}

/// Number of internally-supported formats. Equal to 1 + maximum internal format (here: FIF_QOI).
package enum int FREE_IMAGE_FORMAT_NUM = 25; 


alias FREE_IMAGE_TYPE = int;

enum : FREE_IMAGE_TYPE
{
    FIT_UNKNOWN,    /// Unknown format (returned value only, never use it as input value)
    FIT_BITMAP,     /// Standard image: 1-, 4-, 8-, 16-, 24-, 32-bit
    FIT_UINT16,     /// Array of unsigned short: unsigned 16-bit
    FIT_INT16,      /// Array of short: signed 16-bit
    FIT_UINT32,     /// Array of unsigned long: unsigned 32-bit
    FIT_INT32,      /// Array of long: signed 32-bit
    FIT_FLOAT,      /// Array of float: 32-bit IEEE floating point
    FIT_DOUBLE,     /// Array of double: 64-bit IEEE floating point
    FIT_COMPLEX,    /// Array of FICOMPLEX: 2 x 64-bit IEEE floating point
    FIT_LA16,       /// 32-bit Luminance Alpha image: 2 x unsigned 16-bit
    FIT_RGB16,      /// 48-bit RGB image: 3 x unsigned 16-bit
    FIT_RGBA16,     /// 64-bit RGBA image: 4 x unsigned 16-bit
    FIT_RGBF,       /// 96-bit RGB float image: 3 x 32-bit IEEE floating point
    FIT_RGBAF,      /// 128-bit RGBA float image: 4 x 32-bit IEEE floating point
}

