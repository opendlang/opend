/**
Bitmap management and information functions.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.bitmap;

import core.stdc.stdio;
import core.stdc.string: memcpy;
import core.stdc.stdlib: malloc, realloc, free;
import gamut.types;
import gamut.io;
import gamut.image;
import gamut.plugin;
import gamut.internals.cstring;
import gamut.internals.errors;


nothrow @nogc @safe:






// ================================================================================================
//
//                                           INTERNALS
//
// ================================================================================================


private:
