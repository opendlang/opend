/**
Error messages, and some checks.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.internals.errors;

// Return: 
//   -1 => keep input number of components
//    0 => error
//    1/2/3/4 => forced number of components.
package int computeRequestedImageComponents(int loadFlags) pure nothrow @nogc @safe
{
    int requestedComp = -1; // keep original

    int forceFlags = 0;
    if (loadFlags & LOAD_GREYSCALE)
    {
        forceFlags++;
        requestedComp = 1;
    }
    if (loadFlags & LOAD_RGB)
    {
        forceFlags++;
        requestedComp = 3;
    }
    if (loadFlags & LOAD_RGBA)
    {
        forceFlags++;
        requestedComp = 4;
    }
    if (forceFlags > 1)
        return 0; // LOAD_GREYSCALE, LOAD_RGB and LOAD_RGBA are mutually exclusive => error

    return requestedComp;
}

// Some error messages are shared between format plugins, save a few bytes.
static immutable string kStrInvalidFlags = "Invalid image decoding flags";
static immutable string kStrImageTooLarge = "Can't load an image that exceeds Gamut size limitations";
static immutable string kStrImageDecodingFailed = "Image decoding failed";
static immutable string kStrImageWrongComponents = "Invalid number of component for image";
static immutable string kStrImageDecodingIOFailure = "I/O failure while decoding image";
static immutable string kStrImageDecodingMallocFailure = "Allocation failure while decoding image";
static immutable string kStrImageNotInitialized = "Uninitialized image";

