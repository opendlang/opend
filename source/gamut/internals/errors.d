/**
Error messages, and some checks.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

*/
module gamut.internals.errors;



// Some error messages are shared between format plugins, save a few bytes.
static immutable string kStrImageHasNoType             = "Image has no type";
static immutable string kStrCannotOpenFile             = "Cannot open file";
static immutable string kStrFileCloseFailed            = "fclose() failed";
static immutable string kStrImageDecodingFailed        = "Image decoding failed";
static immutable string kStrImageDecodingIOFailure     = "I/O failure while decoding image";
static immutable string kStrImageDecodingMallocFailure = "Allocation failure while decoding image";
static immutable string kStrImageFormatNoLoadSupport   = "Cannot decode this image format in this build";
static immutable string kStrImageFormatNoWriteSupport  = "Cannot encode this image format in this build";
static immutable string kStrImageFormatUnidentified    = "Unidentified image format";
static immutable string kStrImageNotInitialized        = "Uninitialized image";
static immutable string kStrImageTooLarge              = "Can't have an image that exceeds Gamut size limitations";
static immutable string kStrImageWrongComponents       = "Invalid number of component for image";
static immutable string kStrInvalidFlags               = "Invalid image decoding flags";
static immutable string kStrInvalidPixelTypeCast       = "Invalid pixel type cast";
static immutable string kStrIllegalNegativeDimension   = "Illegal negative dimension";
static immutable string kStrIllegalLayoutConstraints   = "Cannot satisfy illegal layout constraints";
static immutable string kStrOutOfMemory                = "Out of memory";
static immutable string kStrUnsupportedTypeConversion  = "Unsupported image pixel type conversion";
static immutable string kStrUnsupportedVFlip           = "Can't flip image vertically";
static immutable string kStrOverlappingScanlines       = "Scanlines are overlapping";
static immutable string kStrOverlappingLayers          = "Layers are overlapping";
static immutable string kStrInvalidNegLayerOffset      = "Invalid negative layer offset";

