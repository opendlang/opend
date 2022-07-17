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
    int width() pure const
    {
        assert(!errored);
        return _width;
    }

    /// Returns: Height of image in pixels.
    ///          `GAMUT_UNKNOWN_WIDTH` if not available.
    int height() pure const
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

    /// Returns a pointer to the `y` nth line of pixels.
    /// Only possible if the image has plain pixels.
    /// What is points to, dependes on the image `type()`.
    /// Returns: The scanline start. You can read `pitchInBytes` bytes from there.
    inout(ubyte)* scanline(int y) inout @trusted
    {
        assert(hasPlainPixels());
        assert(y >= 0 && y < _height);
        return _data + _pitch * y;
    }

    /// Returns: Horizontal resolution in Dots Per Inch (DPI).
    ///          `GAMUT_UNKNOWN_RESOLUTION` if unknown.
    float dotsPerInchX() pure const
    {
        if (_resolutionY == GAMUT_UNKNOWN_RESOLUTION || _pixelAspectRatio == GAMUT_UNKNOWN_ASPECT_RATIO)
            return GAMUT_UNKNOWN_RESOLUTION;
        return _resolutionY * _pixelAspectRatio;
    }

    /// Returns: Vertical resolution in Dots Per Inch (DPI).
    ///          `GAMUT_UNKNOWN_RESOLUTION` if unknown.
    float dotsPerInchY() pure const
    {
        return _resolutionY;
    }

    /// Returns: Pixel Aspect Ratio for the image (PAR).
    ///          `GAMUT_UNKNOWN_ASPECT_RATIO` if unknown.
    ///
    /// This is physical width of a pixel / physical height of a pixel.
    ///
    /// Reference: https://en.wikipedia.org/wiki/Pixel_aspect_ratio
    float pixelAspectRatio() pure const
    {
        return _pixelAspectRatio;
    }

    /// Returns: Horizontal resolution in Pixels Per Meters (PPM).
    ///          `GAMUT_UNKNOWN_RESOLUTION` if unknown.
    float pixelsPerMeterX() pure const
    {
        float dpi = dotsPerInchX();
        if (dpi == GAMUT_UNKNOWN_RESOLUTION)
            return GAMUT_UNKNOWN_RESOLUTION;
        return convertMetersToInches(dpi);
    }

    /// Returns: Vertical resolution in Pixels Per Meters (PPM).
    ///          `GAMUT_UNKNOWN_RESOLUTION` if unknown.
    float pixelsPerMeterY() pure const
    {
        float dpi = dotsPerInchY();
        if (dpi == GAMUT_UNKNOWN_RESOLUTION)
            return GAMUT_UNKNOWN_RESOLUTION;
        return convertMetersToInches(dpi);
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

    /// The error message (null if no error currently held).
    const(char)* errorMessage() pure const
    {
        return _error;
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
        return hasData() && imageTypeIsPlain(_type); // Note: all formats are plain, for now.
    }

    /// A planar image is for example YUV420.
    /// If the image is planar, its lines are not accessible like that.
    /// Currently not supported.
    bool isPlanar() pure const
    {
        return hasData() && imageTypeIsPlanar(_type);
    }

    /// A compressed image doesn't have its pixels available.
    /// Currently not supported.
    bool isCompressed() pure const
    {
        return hasData() && imageTypeIsCompressed(_type);
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

        if (!imageIsValidSize(width, height))
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

    /// Copy pixels to an image with same size and type.
    void copyPixelsTo(ref Image img) const @trusted
    {
        assert(img._width  == _width);
        assert(img._height == _height);
        assert(img._type   == _type);

        // PERF: if same pitch, do a single memcpy
        //       caution with negative pitch

        int scanlineLen = _width * imageTypePixelSize(type);

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


    //
    // <CONVERSION>
    //

    /// Convert the image to one channel equivalent, using a greyscale transformation (all channels weighted equally).
    void convertToGreyScale()
    {
        ImageType t = ImageType.unknown;
        final switch(_type) with (ImageType)
        {
            case unknown: assert(false);
            case uint8:   t = uint8; break;
            case uint16:  t = uint16; break;
            case f32:     t = f32; break;
            case la8:     t = uint8; break;
            case la16:    t = uint16; break;
            case laf32:   t = f32; break;
            case rgb8:    t = uint8; break;
            case rgb16:   t = uint16; break;
            case rgbf32:  t = f32; break;
            case rgba8:   t = uint8; break;
            case rgba16:  t = uint16; break;
            case rgbaf32: t = f32; break;
        }
        convertTo(t);
    }

    /// Convert the image to a RGB equivalent, using duplication and/or alpha-stripping.
    void convertToRGB()
    {
        ImageType t = ImageType.unknown;
        final switch(_type) with (ImageType)
        {
            case unknown: assert(false);
            case uint8:   t = rgb8; break;
            case uint16:  t = rgb16; break;
            case f32:     t = rgbf32; break;
            case la8:     t = rgb8; break;
            case la16:    t = rgb16; break;
            case laf32:   t = rgbf32; break;
            case rgb8:    t = rgb8; break;
            case rgb16:   t = rgb16; break;
            case rgbf32:  t = rgbf32; break;
            case rgba8:   t = rgb8; break;
            case rgba16:  t = rgb16; break;
            case rgbaf32: t = rgbf32; break;
        }
        convertTo(t);
    }

    /// Convert the image to a RGBA equivalent, using duplication.
    /// If the image had no alpha, it received a fully opaqua alpha value.
    void convertToRGBA()
    {
        ImageType t = ImageType.unknown;
        final switch(_type) with (ImageType)
        {
            case unknown: assert(false);
            case uint8:   t = rgba8; break;
            case uint16:  t = rgba16; break;
            case f32:     t = rgbaf32; break;
            case la8:     t = rgba8; break;
            case la16:    t = rgba16; break;
            case laf32:    t = rgbaf32; break;
            case rgb8:    t = rgba8; break;
            case rgb16:   t = rgba16; break;
            case rgbf32:  t = rgbaf32; break;
            case rgba8:   t = rgba8; break;
            case rgba16:  t = rgba16; break;
            case rgbaf32: t = rgbaf32; break;
        }
        convertTo(t);
    }

    /// Convert the image bit-depth to 8-bit per component.
    void convertTo8Bit()
    {
        ImageType t = ImageType.unknown;
        ImageType type = _type;
        final switch(type) with (ImageType)
        {
            case unknown: assert(false);
            case uint8:   t = uint8; break;
            case uint16:  t = uint8; break;
            case f32:     t = uint8; break;
            case la8:     t = la8; break;
            case la16:    t = la8; break;
            case laf32:   t = la8; break;
            case rgb8:    t = rgb8; break;
            case rgb16:   t = rgb8; break;
            case rgbf32:  t = rgb8; break;
            case rgba8:   t = rgba8; break;
            case rgba16:  t = rgba8; break;
            case rgbaf32: t = rgba8; break;
        }
        convertTo(t);
    }

    /// Convert the image bit-depth to 16-bit per component.
    void convertTo16Bit()
    {
        ImageType t = ImageType.unknown;
        final switch(_type) with (ImageType)
        {
            case unknown: assert(false);
            case uint8:   t = uint16; break;
            case uint16:  t = uint16; break;
            case f32:     t = uint16; break;
            case la8:     t = la16; break;
            case la16:    t = la16; break;
            case laf32:   t = la16; break;
            case rgb8:    t = rgb16; break;
            case rgb16:   t = rgb16; break;
            case rgbf32:  t = rgb16; break;
            case rgba8:   t = rgba16; break;
            case rgba16:  t = rgba16; break;
            case rgbaf32: t = rgba16; break;
        }
        convertTo(t);
    }

    /// Convert the image bit-depth to 32-bit float per component.
    void convertToFP32()
    {
        ImageType t = ImageType.unknown;
        final switch(_type) with (ImageType)
        {
            case unknown: assert(false);
            case uint8:   t = f32; break;
            case uint16:  t = f32; break;
            case f32:     t = f32; break;
            case la8:     t = laf32; break;
            case la16:    t = laf32; break;
            case laf32:   t = laf32; break;
            case rgb8:    t = rgbf32; break;
            case rgb16:   t = rgbf32; break;
            case rgbf32:  t = rgbf32; break;
            case rgba8:   t = rgbaf32; break;
            case rgba16:  t = rgbaf32; break;
            case rgbaf32: t = rgbaf32; break;
        }
        convertTo(t);
    }

    /// Convert the image to the following format.
    /// This can destruct channels, loose precision, etc.
    /// Returns: true on success.
    bool convertTo(ImageType targetType) @trusted
    {
        assert(!errored()); // this should have been caught before.
        if (targetType == ImageType.unknown)
        {
            error(kStrUnsupportedTypeConversion);
            return false;
        }

        if (_type == targetType)
            return true; // success, same type alread

        if (!hasData())
            return true; // success, no pixel data, so everything was "converted"

        if (width() == 0 || height() == 0)
        {
            return true; // image dimension is zero, everything fine
        }

        ubyte* source = _data;
        int sourcePitch = _pitch;
        int destPitch = computePitch(targetType, width);

        // Do not use realloc to avoid invalidating previous data.
        // PERF: can do this, if not owned.
        bool err;
        ubyte* dest = allocStorage(null, targetType, width, height, destPitch, err);
        if (err)
        {
            error(kStrOutOfMemory);
            return false;
        }

        // Need an intermediate buffer.
        // PERF: eventually, find a way to bypass that if supported.
        ImageType interType = intermediateConversionType(_type, targetType);
        ubyte* interBuf = cast(ubyte*) malloc( width * imageTypePixelSize(interType));
        scope(exit) free(interBuf);

        bool ok = convertInternal(_type, source, sourcePitch, 
                                  targetType, dest, destPitch,
                                  width, height,
                                  interType, interBuf);
        if (!ok)
        {
            error(kStrUnsupportedTypeConversion);
            return false;
        }

        _data = dest; // TODO LEAK, should free existing bitmap if owned
        _type = targetType;
        _pitch = destPitch;
        return true;
    }

    /// Reinterpret cast the image content.
    /// For example if you want to consider a RGBA8 image to be uint8, but with a 4x larger width.
    /// This doesn't allocates new data storage.
    ///
    /// Warning: This fails if the cast is impossible, for example casting a uint8 image to RGBA8 only
    /// works if the width is a multiple of 4.
    ///
    /// So it is a bit like casting slices in D.
    bool castTo(ImageType targetType) @trusted
    {
        assert(!errored()); // this should have been caught before.
        if (targetType == ImageType.unknown)
        {
            error(kStrInvalidImageTypeCast);
            return false;
        }

        if (_type == targetType)
            return true; // success, nothing to do

        if (!hasData())
        {
            _type = targetType;
            return true; // success, no pixel data, so everything was "cast"
        }

        if (width() == 0 || height() == 0)
        {
            return true; // image dimension is zero, everything fine
        }

        // Basically, you can cast if the source type size is a multiple of the dest type.
        int srcBytes = imageTypePixelSize(_type);
        int destBytes = imageTypePixelSize(_type);

        // Byte length of source line.
        int sourceLineSize = width * srcBytes;
        assert(sourceLineSize >= 0);

        // Is it dividable by destBytes? If yes, cast is successful.
        if ( (sourceLineSize % destBytes) == 0)
        {
            _width = sourceLineSize / destBytes;
            _type = targetType;
            return true;
        }
        else
        {
            error(kStrInvalidImageTypeCast);
            return false;
        }
    }

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
        assert(msg !is null);
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
    /// FUTURE: negative pitch for costless vertical flip.
    int _pitch = 0; 

    /// Pointer to last known error. `null` means "no errors".
    /// Once an error has occured, continuing to use the image is Undefined Behaviour.
    /// Must be zero-terminated.
    /// By default, a T.init image is errored().
    const(char)* _error = kStrImageNotInitialized;

    /// Pixel aspect ratio.
    /// https://en.wikipedia.org/wiki/Pixel_aspect_ratio
    float _pixelAspectRatio = GAMUT_UNKNOWN_ASPECT_RATIO;

    /// Physical image resolution in vertical pixel-per-inch.
    float _resolutionY = GAMUT_UNKNOWN_RESOLUTION;

private:

    /// Compute a suitable pitch when making an image.
    /// FUTURE some flags that change alignment constraints?
    int computePitch(ImageType type, int width)
    {
        return width * imageTypePixelSize(type);
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
        bool err;
        ubyte* newStorage = allocStorage(_data, type, width, height, pitch, err);

        if (err)
            return false;

        _data = newStorage;
        _type = type;
        _width = width;
        _height = height;
        _pitch = pitch;
        return true;
    }

    /// Discard ancient data, and reallocate stuff.
    /// Returns true in *errored.
    /// Note: that you can request zero byte, and realloc would still give a non-null pointer, 
    /// that you would have to keep. This is a success case.
    static ubyte* allocStorage(void* existingData, ImageType type, int width, int  height, int pitch, out bool err) @trusted
    {       
        int size = storageSize(type, width, height, pitch);
        // PERF: all gamut using same heap? to reuse allocation.
        ubyte* res = cast(ubyte*) realloc(existingData, size);

        err = false;
        if (size != 0 && res is null) // realloc is allowed to return null if zero bytes required.
            err = true;

        return res;
    }

    /// The size of the allocation needed for this storage.
    static int storageSize(ImageType type, int width, int  height, int pitch)
    {
        assert(pitch >= 0); // TODO support negative pitch
        assert( imageTypePixelSize(type) * width <= pitch);
        return width * pitch;
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
        bool fcloseOK = fclose(f) == 0;
        return r && fcloseOK;
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



// FUTURE: this will also manage color conversion.
ImageType intermediateConversionType(ImageType srcType, ImageType destType)
{
    return ImageType.rgbaf32; // PERF: smaller intermediate types
}

// This converts scanline per scanline, using an intermediate format to lessen the number of conversions.
bool convertInternal(ImageType srcType, const(ubyte)* src, int srcPitch, 
                     ImageType destType, ubyte* dest, int destPitch,
                     int width, int height,
                     ImageType interType, ubyte* interBuf) @system
{
    assert(srcType != destType);
    assert(srcType != ImageType.unknown && destType != ImageType.unknown);

    if (imageTypeIsPlanar(srcType) || imageTypeIsPlanar(destType))
        return false; // No support
    if (imageTypeIsCompressed(srcType) || imageTypeIsCompressed(destType))
        return false; // No support

    // For each scanline
    for (int y = 0; y < height; ++y)
    {
        convertToIntermediateScanline(srcType, src, interType, interBuf, width);
        convertFromIntermediate(interType, interBuf, destType, dest, width);
        src += srcPitch;
        dest += destPitch;
    }
    return true;
}


/// See_also: OpenGL ES specification 2.3.5.1 and 2.3.5.2 for details about converting from 
/// floating-point to integers, and the other way around.
void convertToIntermediateScanline(ImageType srcType, 
                                   const(ubyte)* src, 
                                   ImageType dstType, 
                                   ubyte* dest, int width) @system
{
    if (dstType == ImageType.rgbaf32)
    {
        float* outp = cast(float*) dest;

        final switch(srcType) with (ImageType)
        {
            case unknown: assert(false);
            case uint8:
            {
                const(ubyte)* s = src;
                for (int x = 0; x < width; ++x)
                {
                    float b = s[x] / 255.0f;
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = 1.0f;
                }
                break;
            }
            case uint16:
            {
                const(ushort)* s = cast(const(ushort)*) src;
                for (int x = 0; x < width; ++x)
                {
                    float b = s[x] / 65535.0f;
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = 1.0f;
                }
                break;
            }
            case f32:
            {
                const(float)* s = cast(const(float)*) src;
                for (int x = 0; x < width; ++x)
                {
                    float b = s[x];
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = 1.0f;
                }
                break;
            }
            case la8:
            {
                const(ubyte)* s = src;
                for (int x = 0; x < width; ++x)
                {
                    float b = *s++ / 255.0f;
                    float a = *s++ / 255.0f;
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = a;
                }
                break;
            }
            case la16:
            {
                const(ushort)* s = cast(const(ushort)*) src;
                for (int x = 0; x < width; ++x)
                {
                    float b = *s++ / 65535.0f;
                    float a = *s++ / 65535.0f;
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = a;
                }
                break;
            }
            case laf32:
            {
                const(float)* s = cast(const(float)*) src;
                for (int x = 0; x < width; ++x)
                {
                    float b = *s++;
                    float a = *s++;
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = b;
                    *outp++ = a;
                }
                break;
            }
            case rgb8:
            {
                const(ubyte)* s = src;
                for (int x = 0; x < width; ++x)
                {
                    float r = *s++ / 255.0f;
                    float g = *s++ / 255.0f;
                    float b = *s++ / 255.0f;
                    *outp++ = r;
                    *outp++ = g;
                    *outp++ = b;
                    *outp++ = 1.0f;
                }
                break;
            }
            case rgb16:
            {
                const(ushort)* s = cast(const(ushort)*) src;
                for (int x = 0; x < width; ++x)
                {
                    float r = *s++ / 65535.0f;
                    float g = *s++ / 65535.0f;
                    float b = *s++ / 65535.0f;
                    *outp++ = r;
                    *outp++ = g;
                    *outp++ = b;
                    *outp++ = 1.0f;
                }
                break;
            }
            case rgbf32:
            {
                const(float)* s = cast(const(float)*) src;
                for (int x = 0; x < width; ++x)
                {
                    float r = *s++;
                    float g = *s++;
                    float b = *s++;
                    *outp++ = r;
                    *outp++ = g;
                    *outp++ = b;
                    *outp++ = 1.0f;
                }
                break;
            }
            case rgba8:
            {
                const(ubyte)* s = src;
                for (int x = 0; x < width; ++x)
                {
                    float r = *s++ / 255.0f;
                    float g = *s++ / 255.0f;
                    float b = *s++ / 255.0f;
                    float a = *s++ / 255.0f;
                    *outp++ = r;
                    *outp++ = g;
                    *outp++ = b;
                    *outp++ = a;
                }
                break;
            }
            case rgba16:
            {
                const(ushort)* s = cast(const(ushort)*) src;
                for (int x = 0; x < width; ++x)
                {
                    float r = *s++ / 65535.0f;
                    float g = *s++ / 65535.0f;
                    float b = *s++ / 65535.0f;
                    float a = *s++ / 65535.0f;
                    *outp++ = r;
                    *outp++ = g;
                    *outp++ = b;
                    *outp++ = a;
                }
                break;
            }
            case rgbaf32:
            {
                const(float)* s = cast(const(float)*) src;
                for (int x = 0; x < width; ++x)
                {
                    float r = *s++;
                    float g = *s++;
                    float b = *s++;
                    float a = *s++;
                    *outp++ = r;
                    *outp++ = g;
                    *outp++ = b;
                    *outp++ = a;
                }
                break;
            }
        }
    }
    else
        assert(false);

}

void convertFromIntermediate(ImageType srcType, const(ubyte)* src, ImageType dstType, ubyte* dest, int width) @system
{
    if (srcType == ImageType.rgbaf32)
    {    
        const(float)* inp = cast(const(float)*) src;

        final switch(dstType) with (ImageType)
        {
            case unknown: assert(false);
            case uint8:
            {
                ubyte* s = dest;
                for (int x = 0; x < width; ++x)
                {
                    ubyte b = cast(ubyte)(0.5f + (inp[4*x+0] + inp[4*x+1] + inp[4*x+2]) * 255.0f / 3.0f);
                    *s++ = b;
                }
                break;
            }
            case uint16:
            {
                ushort* s = cast(ushort*) dest;
                for (int x = 0; x < width; ++x)
                {
                    ushort b = cast(ushort)(0.5f + (inp[4*x+0] + inp[4*x+1] + inp[4*x+2]) * 65535.0f / 3.0f);
                    *s++ = b;
                }
                break;
            }
            case f32:
            {
                float* s = cast(float*) dest;
                for (int x = 0; x < width; ++x)
                {
                    float b = (inp[4*x+0] + inp[4*x+1] + inp[4*x+2]) / 3.0f;
                    *s++ = b;
                }
                break;
            }
            case la8:
            {
                ubyte* s = dest;
                for (int x = 0; x < width; ++x)
                {
                    ubyte b = cast(ubyte)(0.5f + (inp[4*x+0] + inp[4*x+1] + inp[4*x+2]) * 255.0f / 3.0f);
                    ubyte a = cast(ubyte)(0.5f + inp[4*x+3] * 255.0f);
                    *s++ = b;
                    *s++ = a;
                }
                break;
            }
            case la16:
            {
                ushort* s = cast(ushort*) dest;
                for (int x = 0; x < width; ++x)
                {
                    ushort b = cast(ushort)(0.5f + (inp[4*x+0] + inp[4*x+1] + inp[4*x+2]) * 65535.0f / 3.0f);
                    ushort a = cast(ushort)(0.5f + inp[4*x+3] * 65535.0f);
                    *s++ = b;
                    *s++ = a;
                }
                break;
            }
            case laf32:
            {
                float* s = cast(float*) dest;
                for (int x = 0; x < width; ++x)
                {
                    float b = (inp[4*x+0] + inp[4*x+1] + inp[4*x+2]) / 3.0f;
                    float a = inp[4*x+3];
                    *s++ = b;
                    *s++ = a;
                }
                break;
            }
            case rgb8:
            {
                ubyte* s = dest;
                for (int x = 0; x < width; ++x)
                {
                    ubyte r = cast(ubyte)(0.5f + inp[4*x+0] * 255.0f);
                    ubyte g = cast(ubyte)(0.5f + inp[4*x+1] * 255.0f);
                    ubyte b = cast(ubyte)(0.5f + inp[4*x+2] * 255.0f);
                    *s++ = r;
                    *s++ = g;
                    *s++ = b;
                }
                break;
            }
            case rgb16:
            {
                ushort* s = cast(ushort*) dest;
                for (int x = 0; x < width; ++x)
                {
                    ushort r = cast(ushort)(0.5f + inp[4*x+0] * 65535.0f);
                    ushort g = cast(ushort)(0.5f + inp[4*x+1] * 65535.0f);
                    ushort b = cast(ushort)(0.5f + inp[4*x+2] * 65535.0f);
                    *s++ = r;
                    *s++ = g;
                    *s++ = b;
                }
                break;
            }
            case rgbf32:
            {
                float* s = cast(float*) dest;
                for (int x = 0; x < width; ++x)
                {
                    *s++ = inp[4*x+0];
                    *s++ = inp[4*x+1];
                    *s++ = inp[4*x+2];
                }
                break;
            }
            case rgba8:
            {
                ubyte* s = dest;
                for (int x = 0; x < width; ++x)
                {
                    ubyte r = cast(ubyte)(0.5f + inp[4*x+0] * 255.0f);
                    ubyte g = cast(ubyte)(0.5f + inp[4*x+1] * 255.0f);
                    ubyte b = cast(ubyte)(0.5f + inp[4*x+2] * 255.0f);
                    ubyte a = cast(ubyte)(0.5f + inp[4*x+3] * 255.0f);
                    *s++ = r;
                    *s++ = g;
                    *s++ = b;
                    *s++ = a;
                }
                break;
            }
            case rgba16:
            {
                ushort* s = cast(ushort*)dest;
                for (int x = 0; x < width; ++x)
                {
                    ushort r = cast(ushort)(0.5f + inp[4*x+0] * 65535.0f);
                    ushort g = cast(ushort)(0.5f + inp[4*x+1] * 65535.0f);
                    ushort b = cast(ushort)(0.5f + inp[4*x+2] * 65535.0f);
                    ushort a = cast(ushort)(0.5f + inp[4*x+3] * 65535.0f);
                    *s++ = r;
                    *s++ = g;
                    *s++ = b;
                    *s++ = a;
                }
                break;
            }
            case rgbaf32:
            {
                float* s = cast(float*) dest;
                for (int x = 0; x < width; ++x)
                {
                    *s++ = inp[4*x+0];
                    *s++ = inp[4*x+1];
                    *s++ = inp[4*x+2];
                    *s++ = inp[4*x+3];
                }
                break;
            }
        }
    }
    else
        assert(false);
}