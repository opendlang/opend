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
import gamut.internals.errors;

public import gamut.types: ImageFormat;

nothrow @nogc @safe:

/// Image type.
/// Internally, it wraps FIBitmap.
/// Image has disabled copy ctor and postblit, to avoid accidental allocations.
struct Image
{
nothrow @nogc @safe:
public:

    /// An image can have data (usually pixels), or not.
    /// "Data" refers to pixel content, that can be in a decoded form (RGBA8), but also in more
    /// complicated forms such as planar, compressed, etc.
    bool hasData() pure const
    {
        return _data !is null;        
    }

    /// An image can have plain pixels, which means:
    ///   1. it has data
    ///   2. those are in a plain decoded format (not a compressed texture, not planar, etc).
    bool hasPlainPixels() pure const
    {
        return hasData() && true; // all formats are plain, for now.
    }

    /// A planar image is for example YUV420.
    /// If the image is planar, its lines are not accessible like that.
    bool isPlanar() pure const
    {
        return hasData() && false; // not supported yet.
    }

    /// A compressed image doesn't have its pixels available.
    bool isCompressed() pure const
    {
        return hasData() && false; // not supported yet.
    }



    /// Returns FALSE if the bitmap does not contain pixel data (i.e. if it contains only header and 
    /// possibly some metadata). 
    /// Header only bitmap can be loaded using the FIF_LOAD_NOPIXELS load flag (see Table 3). 
    /// This load flag will tell the decoder to read header data and available metadata and skip pixel 
    /// data decoding. The memory size of the dib is thus reduced to the size of its members, 
    /// excluding the pixel buffer. Reading metadata only information is fast since no pixel decoding 
    /// occurs. 
    /// Header only bitmap can be used with Bitmap information functions, Metadata iterator. They 
    /// cannot be used with any pixel processing function or by saving function.
    bool FreeImage_HasPixels(const(Image) *dib) pure
    {
        return dib._data != null;
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
            FreeImage_Load(this, fif, cstr.storage, flags);
        }
        return !errored();
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
            FreeImage_LoadFromMemory(this, fif, stream, flags);
        }

        return !errored();
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
        assert(!errored); // else, nothing to save
        CString cstr = CString(path);

        ImageFormat fif = FreeImage_GetFIFFromFilename(cstr.storage);
        if (fif == ImageFormat.unknown)
            return false; // couldn't recognize format from path.

        return FreeImage_Save(this, fif, cstr.storage, flags);
    }
    /// Save the image into a file, but provide a file format.
    /// Returns: `true` if file successfully written.
    bool saveToFile(ImageFormat fif, const(char)[] path, int flags = 0) @trusted
    {
        assert(!errored); // else, nothing to save
        CString cstr = CString(path);
        return FreeImage_Save(this, fif, cstr.storage, flags);
    }

    /// Saves the image into a new memory location.
    /// The returned data must be released with a call to `free`.
    /// Returns: `null` if saving failed.
    ubyte[] saveToMemory(ImageFormat fif, int flags = 0) @trusted
    {
        assert(!errored); // else, nothing to save

        // PERF: a way to have FIMEMORY in a local instead of heap.
        // Open stream for read/write access.
        FIMEMORY* stream = FreeImage_OpenMemory();
        scope(exit) FreeImage_CloseMemory(stream);
        if (!FreeImage_SaveToMemory(this, fif, stream, flags))
        {
            return null;
        }
        return FreeImage_ReleaseMemory(stream);
    }

    /// Returns: Width of image in pixels.
    ///          `GAMUT_UNKNOWN_WIDTH` if not available.
    int width() pure
    {
        assert(!errored);
        return _width;
    }

    /// Returns: Height of image in pixels.
    ///          `GAMUT_UNKNOWN_WIDTH` if not available.
    int height() pure
    {
        assert(!errored);
        return _height;
    }

    /// Was there an error as a result of calling a public method of `Image`?
    /// It is now unusable.
    public bool errored() pure const
    {
        return _error !is null;
    }


    @disable this(this); // Non-copyable. This would clone the image, and be expensive.


    /// Destructor. Everything is reclaimed.
    ~this()
    {
        cleanupBitmapIfAny();
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
    deprecated alias error = setError;
    void setError(const(char)[] msg) pure
    {
        _error = assumeZeroTerminated(msg);
    }

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


private:

    void cleanupBitmapIfAny() @trusted
    {   
        if (_data !is null)
        {
            free(_data);
            _data = null;
        }
    }
}



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