/**
Bitmap conversion functions.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
      See the differences in DIFFERENCES.md
*/
module gamut.conversion;

import gamut.types;
import gamut.bitmap;

nothrow @nogc @safe:

/// Converts a bitmap to 32 bits. A clone of the input bitmap is returned for 32-bit bitmaps. 
/// For 48-bit RGB images, conversion is done by dividing each 16-bit channel by 256 and by 
/// setting the alpha channel to an opaque value (0xFF). For 64-bit RGBA images, conversion is 
/// done by dividing each 16-bit channel by 256. A NULL value is returned for other nonstandard bitmap types.
FIBITMAP* FreeImage_ConvertTo32Bits(FIBITMAP *dib)
{
    assert(dib != null);

    // No pixels => a clone could be fine...
    // TODO: clone or crash?
    assert(FreeImage_HasPixels(dib));

    // Already 32-bit, return a clone regardless of mask.
    if (dib._type == FIT_BITMAP && dib._bpp == 32)
        return FreeImage_Clone(dib);    

    assert(false);
}