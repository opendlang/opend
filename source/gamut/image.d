/**
Gamut public API. This is the main image abstraction.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
See the differences in DIFFERENCES.md
*/
module gamut.image;

import core.stdc.stdlib: free;
import gamut.bitmap;
import gamut.general;
import gamut.types;
import gamut.memory;
import gamut.filetype;
import gamut.plugin;
import gamut.conversion;
import gamut.internals.cstring;

public import gamut.types: ImageFormat;

nothrow @nogc @safe:

/// Image type.
/// Internally, it wraps FIBitmap.
/// Image has disabled copy ctor and postblit, to avoid accidental allocations.
struct Image
{
nothrow @nogc @safe:
public:

    @disable this(this); // Non-copyable. This would clone the image, and be expensive.

    ~this()
    {
        cleanupBitmapIfAny();
    }

    /// Load an image from a file location.
    /// Returns: true if successfull.
    bool loadFromFile(const(char)[] path, int flags = 0) @trusted
    {
        cleanupBitmapIfAny();

        CString cstr = CString(path);

        // Deduce format.
        ImageFormat fif = FreeImage_GetFileType(cstr.storage, 0);
        if (fif == ImageFormat.unknown) 
        {
            fif = FreeImage_GetFIFFromFilename(cstr.storage); // try to guess the file format from the file extension
        }
        // check that the plugin has reading capabilities ...
        if ((fif != ImageFormat.unknown) && gamutSupportsInputFormat(fif)) 
        {
            FreeImage_Load(_bitmap, fif, cstr.storage, flags);
        }

        import core.stdc.stdio;
        printf("bitmap = %p\n", &_bitmap);


        return !_bitmap.errored();
    }

    /// Load an image from a memory location.
    /// Returns: true if successfull.
    bool loadFromMemory(const(ubyte)[] bytes, int flags = 0) @trusted
    {
        cleanupBitmapIfAny();

        // PERF: a way to have FIMEMORY in a local instead of heap.
        FIMEMORY* stream = FreeImage_OpenMemory(bytes.ptr, bytes.length);
        scope(exit) FreeImage_CloseMemory(stream);

        // Deduce format.
        ImageFormat fif = FreeImage_GetFileTypeFromMemory(stream, 0);

        // check that the plugin has reading capabilities ...
        if ((fif != ImageFormat.unknown) && gamutSupportsInputFormat(fif)) 
        {
            FreeImage_LoadFromMemory(_bitmap, fif, stream, flags);
        }

        return !_bitmap.errored();
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
        assert(!_bitmap.errored); // else, nothing to save
        CString cstr = CString(path);

        ImageFormat fif = FreeImage_GetFIFFromFilename(cstr.storage);
        if (fif == ImageFormat.unknown)
            return false; // couldn't recognize format from path.

        return FreeImage_Save(_bitmap, fif, cstr.storage, flags);
    }
    /// Save the image into a file, but provide a file format.
    /// Returns: `true` if file successfully written.
    bool saveToFile(ImageFormat fif, const(char)[] path, int flags = 0) @trusted
    {
        assert(!_bitmap.errored); // else, nothing to save
        CString cstr = CString(path);
        return FreeImage_Save(_bitmap, fif, cstr.storage, flags);
    }

    /// Saves the image into a new memory location.
    /// The returned data must be released with a call to `free`.
    /// Returns: `null` if saving failed.
    ubyte[] saveToMemory(ImageFormat fif, int flags = 0) @trusted
    {
        assert(!_bitmap.errored); // else, nothing to save

        // PERF: a way to have FIMEMORY in a local instead of heap.
        // Open stream for read/write access.
        FIMEMORY* stream = FreeImage_OpenMemory();
        scope(exit) FreeImage_CloseMemory(stream);
        if (!FreeImage_SaveToMemory(_bitmap, fif, stream, flags))
        {
            return null;
        }
        return FreeImage_ReleaseMemory(stream);
    }

    /// Returns: Width of image in pixels.
    ///          `GAMUT_UNKNOWN_WIDTH` if not available.
    int width() pure
    {
        assert(!_bitmap.errored);
        return _bitmap._width;
    }

    /// Returns: Height of image in pixels.
    ///          `GAMUT_UNKNOWN_WIDTH` if not available.
    int height() pure
    {
        assert(!_bitmap.errored);
        return _bitmap._height;
    }

    /// Returns: a clone of the image, but with RGBA 8-bit components.
  /+  Image convertToRGBA8()
    {
        assert(!_bitmap.errored);
    /*    FIBITMAP* converted = FreeImage_ConvertTo32Bits(&_bitmap);
        Image r;
        r._bitmap = converted;
        return r;*/
    } +/

    bool errored()
    {
        return _bitmap.errored();
    }


    // <Error management>
    // Note: Errors are only about input errors not usage bugs (they replace `Exception` but not `Error`).

    /// Was there an error as a result of calling a public method of `Image`?
    /// It is now unusable.
    public bool errored() pure const
    {
        return _error !is null;
    }

package:

    // Available only inside gamut.

    /// Clear the error, if any. This is only for use inside Gamut.
    /// Each operations that "recreates" the image, such a loading, clear the existing error and leave 
    /// the Image in a clean-up state.
    void clearError() pure
    {
        assert(_error); // Can't clear error if there wasn't any in the first place.
        _error = null;
    }

    /// Set the image in an errored state, with `msg` as a message.
    /// Note: `msg` MUST be zero-terminated.
    void error(const(char)[] msg) pure
    {
        _error = assumeZeroTerminated(msg);
    }

    void assumeValid() pure const
    {
        // If you fail here, it means you should have checked against input errors 
        // before decoding the image.
        assert(!errored);
    }

private:

    /// The type of the data pointed to.
    ImageType _type = ImageType.unknown;

    /// Pointer to the pixel data. What is pointed to depends on `_type`.
    /// The amount of what is pointed to depends upon the dimensions.
    /// it is possible to have `_data` null but `_type` is known.
    ubyte* _data = null;

    /// Width of the image in pixels, when pixels makes sense.
    /// By default, this width is `GAMUT_INVALID_IMAGE_WIDTH`.
    int _width = GAMUT_INVALID_IMAGE_WIDTH;

    /// Height of the image in pixels, when pixels makes sense.
    /// By default, this height is `GAMUT_INVALID_IMAGE_HEIGHT`.
    int _height = GAMUT_INVALID_IMAGE_HEIGHT;

    /// Pitch in bytes between lines, when a pitch makes sense.
    int _pitch; 

    /// Pointer to last known error. `null` means "no errors".
    /// Once an error has occured, continuing to use the image is Undefined Behaviour.
    /// Must be zero-terminated.
    const(char)* _error = kStrImageNotInitialized; 

    void cleanupBitmapIfAny() @trusted
    {   
        if (_bitmap._data)
        {
            import core.stdc.stdio;
            printf("bitmap = %p\n", &_bitmap);
            printf("data = %p\n", _bitmap._data);
            free(_bitmap._data);
            _bitmap._data = null;
        }
    }
}