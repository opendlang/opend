/**
Easy API, for nicer D code. It replaces the FreeImage API, much like FreeImagePlug.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.easy;

import gamut.bitmap;
import gamut.general;
import gamut.types;
import gamut.memory;
import gamut.filetype;
import gamut.plugin;
import gamut.conversion;
import gamut.internals.cstring;

public import gamut.types: FREE_IMAGE_FORMAT;

nothrow @nogc @safe:

/// Image type.
/// Internally, it wraps FIBitmap.
/// Image has disabled copy ctor and postblit, to avoid accidental allocations.
struct Image
{
nothrow @nogc @safe:
public:

    @disable this(this);

    ~this()
    {
        cleanupBitmapIfAny();
    }

    /// Load an image from a file location.
    /// Returns: true if successfull.
    bool loadFromFile(const(char)[] path, int flags = 0) @trusted
    {
        initializeFreeImageLazilyIfFirstCall();
        cleanupBitmapIfAny();

        CString cstr = CString(path);

        // Deduce format.
        FREE_IMAGE_FORMAT fif = FreeImage_GetFileType(cstr.storage, 0);
        if (fif == FIF_UNKNOWN) 
        {
            fif = FreeImage_GetFIFFromFilename(cstr.storage); // try to guess the file format from the file extension
        }

        // check that the plugin has reading capabilities ...
        if ((fif != FIF_UNKNOWN) && FreeImage_FIFSupportsReading(fif)) 
        {
            _bitmap = FreeImage_Load(fif, cstr.storage, flags);
        }

        return _bitmap !is null;
    }

    /// Load an image from a memory location.
    /// Returns: true if successfull.
    bool loadFromMemory(const(ubyte)[] bytes, int flags = 0) @trusted
    {
        initializeFreeImageLazilyIfFirstCall();
        cleanupBitmapIfAny();

        // PERF: a way to have FIMEMORY in a local instead of heap.
        FIMEMORY* stream = FreeImage_OpenMemory(bytes.ptr, bytes.length);
        scope(exit) FreeImage_CloseMemory(stream);

        // Deduce format.
        FREE_IMAGE_FORMAT fif = FreeImage_GetFileTypeFromMemory(stream, 0);

        // check that the plugin has reading capabilities ...
        if ((fif != FIF_UNKNOWN) && FreeImage_FIFSupportsReading(fif)) 
        {
            _bitmap = FreeImage_LoadFromMemory(fif, stream, flags);
        }

        return _bitmap !is null;
    }
    ///ditto
    bool loadFromMemory(const(void)[] bytes, int flags = 0) @trusted
    {
        return loadFromMemory(cast(const(ubyte)[])bytes, flags);
    }

    /// Save the image into a file.
    /// Returns: `true` if file successfully written.
    bool saveToFile(const(char)[] path, int flags = 0) @trusted
    {
        assert(isValid()); // else, nothing to save
        initializeFreeImageLazilyIfFirstCall();
        CString cstr = CString(path);

        FREE_IMAGE_FORMAT fif = FreeImage_GetFIFFromFilename(cstr.storage);
        if (fif == FIF_UNKNOWN)
            return false; // couldn't recognize format from path.

        return FreeImage_Save(fif, _bitmap, cstr.storage, flags);
    }
    /// Save the image into a file, but provide a file format.
    /// Returns: `true` if file successfully written.
    bool saveToFile(FREE_IMAGE_FORMAT fif, const(char)[] path, int flags = 0) @trusted
    {
        assert(isValid()); // else, nothing to save
        initializeFreeImageLazilyIfFirstCall();
        CString cstr = CString(path);
        return FreeImage_Save(fif, _bitmap, cstr.storage, flags);
    }

    /// Saves the image into a new memory location.
    /// The returned data must be released with a call to `free`.
    /// Returns: `null` if saving failed.
    ubyte[] saveToMemory(FREE_IMAGE_FORMAT fif, int flags = 0) @trusted
    {
        assert(isValid()); // else, nothing to save
        initializeFreeImageLazilyIfFirstCall();

        // PERF: a way to have FIMEMORY in a local instead of heap.
        // Open stream for read/write access.
        FIMEMORY* stream = FreeImage_OpenMemory();
        scope(exit) FreeImage_CloseMemory(stream);
        if (!FreeImage_SaveToMemory(fif, _bitmap, stream, flags))
        {
            return null;
        }
        return FreeImage_ReleaseMemory(stream);
    }

    /// Returns: Width of image in pixels.
    int width() pure
    {
        assert(_bitmap !is null);
        return FreeImage_GetWidth(_bitmap);
    }

    /// Returns: Height of image in pixels.
    int height() pure
    {
        assert(_bitmap !is null);
        return FreeImage_GetHeight(_bitmap);
    }

    /// Returns: `true` if this Image has an internal bitmap.
    ///          That means that loading/initialization succeeded. It doesn't mean that it
    ///          has pixels, since the bitmap contains optional: pixels, thumbnail, and meta-data.
    bool isValid()
    {
        return _bitmap !is null;
    }

    /// Returns: a clone of the image, but with RGBA 8-bit components.
    Image convertToRGBA8()
    {
        assert(isValid());
        FIBITMAP* converted = FreeImage_ConvertTo32Bits(_bitmap);
        Image r;
        r._bitmap = converted;
        return r;
    }

    /// Returns: a clone of the image, but with 16-bit components.
    Image convertToRGBA16()
    {
        assert(isValid());
        assert(false); // TODO
    }

private:
    FIBITMAP* _bitmap;

    void cleanupBitmapIfAny() @trusted
    {
        if (_bitmap !is null)
        {
            FreeImage_Unload(_bitmap);
            _bitmap = null;
        }
    }

    void initializeFreeImageLazilyIfFirstCall()
    {
        // Lazy-initialize the library if not done already.
        FreeImage_Initialise(false);
    }
}