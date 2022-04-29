/**
Easy API, for nicer D code. It replaces the FreeImage API, much like FreeImagePlug.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.easy;

import gamut.bitmap;
import gamut.general;
import gamut.types;
import gamut.internals.cstring;

nothrow @nogc @safe:

/// Image type. Wraps FIBitmap.
struct Image
{
nothrow @nogc @safe:
public:

    ~this()
    {
        cleanupBitmap();
    }

    void load(const(char)[] path) @trusted
    {
        // Lazy-initialize the library if not done already.
        FreeImage_Initialise(false);


        CString cstr = CString(path);
        cleanupBitmap();
        _bitmap = FreeImage_Load(FIF_PNG, cstr.storage, PNG_DEFAULT);
    }

    int width() pure
    {
        return FreeImage_GetWidth(_bitmap);
    }

    int height() pure
    {
        return FreeImage_GetHeight(_bitmap);
    }

private:
    FIBITMAP* _bitmap;

    void cleanupBitmap() @trusted
    {
        if (_bitmap !is null)
        {
            FreeImage_Unload(_bitmap);
        }
    }
}