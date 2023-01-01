/**
Scanline conversion public API. This is used both internally and externally, because converting
a whole row of pixels at once is a rather common operations.

Copyright: Copyright Guillaume Piolat 2023
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.scanline;

@system:
nothrow:
@nogc:

/// Convert a row of pixel from RGBA 32-bit (0 to 1.0) float to LA 8-bit (0 to 255).
void scanline_convert_rgbaf32_to_la8(const(float)* inScanline, ubyte* outScanline, int width)
{
    // Issue #21, workaround for DMD optimizer.
    version(DigitalMars) pragma(inline, false);
    ubyte* s = outScanline;
    for (int x = 0; x < width; ++x)
    {
        ubyte b = cast(ubyte)(0.5f + (inScanline[4*x+0] + inScanline[4*x+1] + inScanline[4*x+2]) * 255.0f / 3.0f);
        ubyte a = cast(ubyte)(0.5f + inScanline[4*x+3] * 255.0f);
        *s++ = b;
        *s++ = a;
    }
}