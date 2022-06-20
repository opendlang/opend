/**
Gamut public API. This is the main image abstraction.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.image;

import core.stdc.stdio;
import core.stdc.stdlib: malloc, free, realloc;

import gamut.types;
import gamut.io;
import gamut.plugin;
import gamut.internals.cstring;
import gamut.internals.errors;

public import gamut.types: ImageFormat;

nothrow @nogc @safe:

/// Image type.
/// Image has disabled copy ctor and postblit, to avoid accidental allocations.
struct Image
{
nothrow @nogc @safe:
public:


    //
    // <GETTING DIMENSIONS>
    //  

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

    /// Get the image pitch (byte distance between rows), in bytes.
    /// This pitch can be negative.
    int pitchInBytes(Image *dib) pure const
    {
        return _pitch;
    }

    //
    // </GETTING DIMENSIONS>
    //


    //
    // <GETTING STATUS AND CAPABILITIES>
    //

    /// Get the image type.
    /// See_also: `ImageType`.
    ImageType type() pure const
    {
        return _type;
    }

    /// Was there an error as a result of calling a public method of `Image`?
    /// It is now unusable.
    bool errored() pure const
    {
        return _error !is null;
    }

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

    //
    // </GETTING STATUS AND CAPABILITIES>
    //


    //
    // <INITIALIZE>
    //

    /// Clear the image and initialize a new image, with given dimensions.
    this(int width, int height, ImageType type = ImageType.rgba8)
    {
        setCanvasSize(width, height, type);
    }
    ///ditto
    void setCanvasSize(int width, int height, ImageType type = ImageType.rgba8)
    {
        cleanupBitmapUnlessOwned();
        clearError();

        if (width < 0 || height < 0)
        {
            error(kStrIllegalNegativeDimension);
            return;
        }

        if (width >= GAMUT_MAX_IMAGE_WIDTH || height  >= GAMUT_MAX_IMAGE_WIDTH)
        {
            error(kStrImageTooLarge);
            return;
        }

        int pitch = computePitch(type, width);
        if (!setStorage(type, width, height, pitch))
        {
            error(kStrOutOfMemory);
            return;
        }
    }

    /// Clone an existing image.
    Image clone() const
    {
        Image r;
        r.setCanvasSize(_width, _height, _type);
        if (r.errored)
            return r;

        copyPixelsTo(r);
        return r;
    }

    /// Copy pixels to  an image with same size and type.
    void copyPixelsTo(ref Image img) const @trusted
    {
        assert(img._width  == _width);
        assert(img._height == _height);
        assert(img._type   == _type);

        // PERF: if same pitch, do a single memcpy
        //       caution with negative pitch

        int scanlineLen = _width * bytesForImageType(type);

        const(ubyte)* dataSrc = _data;
        ubyte* dataDst = img._data;

        for (int y = 0; y < _height; ++y)
        {
            dataDst[0..scanlineLen] = dataSrc[0..scanlineLen];
            dataSrc += _pitch;
            dataDst += img._pitch;
        }
    }

    //
    // </INITIALIZE>
    //


    //
    // <SAVING AND LOADING IMAGES>
    //

    /// Load an image from a file location.
    /// Returns: true if successfull.
    bool loadFromFile(const(char)[] path, int flags = 0) @trusted
    {
        cleanupBitmapIfAny();

        CString cstr = CString(path);

        // Deduce format.
        ImageFormat fif = identifyFormatFromFile(cstr.storage);
        if (fif == ImageFormat.unknown) 
        {
            fif = identifyImageFormatFromFilename(cstr.storage); // try to guess the file format from the file extension
        }
        
        loadFromFileInternal(fif, cstr.storage, flags);
        return !errored();
    }

    /// Load an image from a memory location.
    /// Returns: true if successfull.
    bool loadFromMemory(const(ubyte)[] bytes, int flags = 0) @trusted
    {
        cleanupBitmapIfAny();

        MemoryFile mem;
        mem.initFromExistingSlice(bytes);

        // Deduce format.
        ImageFormat fif = identifyFormatFromMemoryFile(mem);

        IOStream io;
        io.setupForMemoryIO();
        loadFromStream(fif, io, cast(IOHandle)&mem, flags);

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

        ImageFormat fif = identifyImageFormatFromFilename(cstr.storage);
        
        return saveToFileInternal(fif, cstr.storage, flags);
    }
    /// Save the image into a file, but provide a file format.
    /// Returns: `true` if file successfully written.
    bool saveToFile(ImageFormat fif, const(char)[] path, int flags = 0) const @trusted
    {
        assert(!errored); // else, nothing to save
        CString cstr = CString(path);
        return saveToFileInternal(fif, cstr.storage, flags);
    }

    /// Saves the image into a new memory location.
    /// The returned data must be released with a call to `free`.
    /// Returns: `null` if saving failed.
    /// Warning: this is NOT GC-allocated.
    ubyte[] saveToMemory(ImageFormat fif, int flags = 0) const @trusted
    {
        assert(!errored); // else, nothing to save

        // Open stream for read/write access.
        MemoryFile mem;
        mem.initEmpty();

        IOStream io;
        io.setupForMemoryIO();
        if (saveToStream(fif, io, cast(IOHandle)&mem, flags))
            return mem.releaseData();
        else
            return null;
    }

    //
    // </SAVING AND LOADING IMAGES>
    //


    // 
    // <FILE FORMAT IDENTIFICATION>
    //

    /// Identify the format of an image by minimally reading it.
    /// Read first bytes of a file to identify it.
    /// You can use a filename, a memory location, or your own `IOStream`.
    /// Returns: Its `ImageFormat`, or `ImageFormat.unknown` in case of identification failure or input error.
    static ImageFormat identifyFormatFromFile(const(char)*filename) @trusted
    {
        FILE* f = fopen(filename, "rb");
        if (f is null)
            return ImageFormat.unknown;
        IOStream io;
        io.setupForFileIO();
        ImageFormat type = identifyFormatFromStream(io, cast(IOHandle)f);    
        fclose(f); // TODO: Note sure what to do if fclose fails here.
        return type;
    }
    ///ditto
    static ImageFormat identifyFormatFromMemory(const(ubyte)[] bytes) @trusted
    {
        MemoryFile mem;
        mem.initFromExistingSlice(bytes);
        return identifyFormatFromMemoryFile(mem);
    }
    ///ditto
    static ImageFormat identifyFormatFromStream(ref IOStream io, IOHandle handle)
    {
        for (ImageFormat fif = ImageFormat.first; fif <= ImageFormat.max; ++fif)
        {
            if (detectFormatFromStream(fif, io, handle))
                return fif;
        }
        return ImageFormat.unknown;
    }

    // 
    // </FILE FORMAT IDENTIFICATION>
    //
    void convertTo(ImageType targetType)
    {

        if (_type == targetType)
            return;



    }

    //
    // <CONVERSION>
    //

    /// Convert the image to the following format.
    /// This can destruct channels, loose precision, etc.




    //
    // </CONVERSION>
    //

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
        _error = null;
    }

    /// Set the image in an errored state, with `msg` as a message.
    /// Note: `msg` MUST be zero-terminated.
    void error(const(char)[] msg) pure
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
    /// By default, a T.init image is errored().
    const(char)* _error = kStrImageNotInitialized;

private:

    /// Compute a suitable pitch when making an image.
    /// FUTURE some flags that change alignment constraints?
    int computePitch(ImageType type, int width)
    {
        return width * bytesForImageType(type);
    }

    void cleanupBitmapIfAny() @trusted
    {   
        if (_data !is null)
        {
            free(_data);
            _data = null;
        }
    }

    void cleanupBitmapUnlessOwned() @trusted
    {
        // TODO owned image can reuse their allocation, but not
        //      borrowed images.
    }

    /// Discard ancient data, and reallocate stuff.
    /// Returns true on success, false on OOM.
    bool setStorage(ImageType type, int width, int  height, int pitch) @trusted
    {
        assert(pitch >= 0); // TODO support negative pitch
        assert( bytesForImageType(type) * width <= pitch);

        int destBytes = width * pitch;

        // PERF: all gamut using same heap? to reuse allocation.
        _data = cast(ubyte*) realloc(_data, destBytes);
        _type = type;

        if (destBytes != 0 && _data is null) // realloc is allowed to return null if zero bytes required.
            return false;

        _width = width;
        _height = height;
        _pitch = pitch;

        return true;
    }

    void loadFromFileInternal(ImageFormat fif, const(char)* filename, int flags = 0) @system
    {
        FILE* f = fopen(filename, "rb");
        if (f is null)
        {
            error(kStrCannotOpenFile);
            return;
        }

        IOStream io;
        io.setupForFileIO();
        loadFromStream(fif, io, cast(IOHandle)f, flags);

        if (0 != fclose(f))
        {
            // TODO cleanup image?
            error(kStrFileCloseFailed);
        }
    }

    void loadFromStream(ImageFormat fif, ref IOStream io, IOHandle handle, int flags = 0) @system
    {
        // By loading an image, we agreed to forget about past mistakes.
        clearError();

        if (fif == ImageFormat.unknown)
        {
            error(kStrImageFormatUnidentified);
            return;
        }

        const(ImageFormatPlugin)* plugin = &g_plugins[fif];   

        int page = 0;
        void *data = null;
        if (plugin.loadProc is null)
        {        
            error(kStrImageFormatNoLoadSupport);
            return;
        }
        plugin.loadProc(this, &io, handle, page, flags, data);
    }

    bool saveToFileInternal(ImageFormat fif, const(char)* filename, int flags = 0) const @trusted
    {
        FILE* f = fopen(filename, "wb");
        if (f is null)
            return false;

        IOStream io;
        io.setupForFileIO();
        bool r = saveToStream(fif, io, cast(IOHandle)f, flags);
        return fclose(f) == 0;
    }

    bool saveToStream(ImageFormat fif, ref IOStream io, IOHandle handle, int flags = 0) const @trusted
    {
        if (fif == ImageFormat.unknown)
        {
            // No format given for save.
            return false;
        }

        if (!hasPlainPixels)
            return false; // no data that is pixels, impossible to save that.

        const(ImageFormatPlugin)* plugin = &g_plugins[fif];
        void* data = null; // probably exist to pass metadata stuff
        if (plugin.saveProc is null)
            return false;
        bool r = plugin.saveProc(this, &io, handle, 0, flags, data);
        return r;
    }

    static ImageFormat identifyFormatFromMemoryFile(ref MemoryFile mem) @trusted
    {
        IOStream io;
        io.setupForMemoryIO();
        return identifyFormatFromStream(io, cast(IOHandle)&mem);
    }  

    static bool detectFormatFromStream(ImageFormat fif, ref IOStream io, IOHandle handle) @trusted
    {
        assert(fif != ImageFormat.unknown);
        const(ImageFormatPlugin)* plugin = &g_plugins[fif];
        assert(plugin.detectProc !is null);
        if (plugin.detectProc(&io, handle))
            return true;
        return false;
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

private:

/*


/// Convert between formats. Returns new data.
/// Returns: null on failure.
ubyte* convertType(ubyte *data, 
                   ImageType inputType, 
                   ImageType outputType, 
                   int width, 
                   int height, 
                   int pitchBytes)
{
    if (inputType == outputType) 
        return data;
   
    // TODO: security there
    int destPitch = width * bytesForImageType(outputType);
    int destBytes = height * destPitch;

    ubyte* dest = cast(ubyte*) malloc(destBytes);
    if (dest == null)
        return null;




    good = cast(ubyte*) stbi__malloc_mad3(req_comp, x, y, 0);
    if (good == null) 
    {
        STBI_FREE(data);
        return null;
    }

    for (j = 0; j < cast(int) y; ++j) 
    {
        ubyte *src  = data + j * x * img_n   ;
        ubyte *dest = good + j * x * req_comp;

        // convert source image with img_n components to one with req_comp components;
        // avoid switch per pixel, so use switch per scanline and massive macros
        switch (img_n * 8 + req_comp) 
        {
            case 1 * 8 + 2:
                { 
                    for(i = x - 1; i >= 0; --i, src += 1, dest += 2)
                    {
                        dest[0] = src[0]; 
                        dest[1] = 255;
                    }
                } 
                break;
            case 1 * 8 + 3:
                { 
                    for(i = x - 1; i >= 0; --i, src += 1, dest += 3)
                    {
                        dest[0] = dest[1] = dest[2] = src[0];
                    }
                } 
                break;
            case 1 * 8 + 4:
                for(i = x - 1; i >= 0; --i, src += 1, dest += 4)
                { 
                    dest[0] = dest[1] = dest[2] = src[0]; 
                    dest[3] = 255;                     
                } 
                break;
            case 2 * 8 + 1:
                { 
                    for(i = x - 1; i >= 0; --i, src += 2, dest += 1)
                    {
                        dest[0] = src[0];
                    }
                } 
                break;
            case 2 * 8 + 3:
                { 
                    for(i = x - 1; i >= 0; --i, src += 2, dest += 3)
                    {
                        dest[0] = dest[1] = dest[2] = src[0]; 
                    }
                } 
                break;
            case 2 * 8 + 4:
                { 
                    for(i = x - 1; i >= 0; --i, src += 2, dest += 4)
                    {
                        dest[0] = dest[1] = dest[2] = src[0]; 
                        dest[3] = src[1]; 
                    }
                } 
                break;
            case 3 * 8 + 4:
                { 
                    for(i = x - 1; i >= 0; --i, src += 3, dest += 4)
                    {
                        dest[0] = src[0];
                        dest[1] = src[1];
                        dest[2] = src[2];
                        dest[3] = 255;
                    }
                } 
                break;
            case 3 * 8 + 1:
                { 
                    for(i = x - 1; i >= 0; --i, src += 3, dest += 1)
                    {
                        dest[0] = stbi__compute_y(src[0],src[1],src[2]); 
                    }
                } 
                break;
            case 3 * 8 + 2:
                { 
                    for(i = x - 1; i >= 0; --i, src += 3, dest += 2)
                    {
                        dest[0] = stbi__compute_y(src[0],src[1],src[2]);
                        dest[1] = 255;
                    }
                } 
                break;

            case 4 * 8 + 1:
                { 
                    for(i = x - 1; i >= 0; --i, src += 4, dest += 1)
                    {
                        dest[0] = stbi__compute_y(src[0],src[1],src[2]);
                    }
                }
                break;

            case 4 * 8 + 2:
                { 
                    for(i = x - 1; i >= 0; --i, src += 4, dest += 2)
                    {
                        dest[0] = stbi__compute_y(src[0],src[1],src[2]); 
                        dest[1] = src[3];
                    }
                }
                break;
            case 4 * 8 + 3:
                { 
                    for(i = x - 1; i >= 0; --i, src += 4, dest += 3)
                    {
                        dest[0] = src[0]; 
                        dest[1] = src[1]; 
                        dest[2] = src[2];        
                    }
                }
                break;
            default: 
                assert(0); 
        }
    }

    STBI_FREE(data);
    return good;
}*/