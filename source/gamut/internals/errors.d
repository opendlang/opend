/**
Error messages, and some checks.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.internals.errors;



// Some error messages are shared between format plugins, save a few bytes.
static immutable string kStrInvalidFlags = "Invalid image decoding flags";
static immutable string kStrImageTooLarge = "Can't load an image that exceeds Gamut size limitations";
static immutable string kStrImageDecodingFailed = "Image decoding failed";
static immutable string kStrImageWrongComponents = "Invalid number of component for image";
static immutable string kStrImageDecodingIOFailure = "I/O failure while decoding image";
static immutable string kStrImageDecodingMallocFailure = "Allocation failure while decoding image";
static immutable string kStrImageNotInitialized = "Uninitialized image";

