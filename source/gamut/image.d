/**
Gamut public API. This is the main image abstraction.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.image;

import core.stdc.stdio;
import core.stdc.stdlib: malloc, free, realloc;
import core.stdc.string: strlen;

import gamut.types;
import gamut.io;
import gamut.plugin;
import gamut.scanline;
import gamut.internals.cstring;
import gamut.internals.errors;
import gamut.internals.types;

public import gamut.types: ImageFormat;

nothrow @nogc @safe:

/// Deallocate pixel data. Everything allocated with `allocatePixelStorage` or disowned eventually needs
/// to be through that function.
void freeImageData(void* mallocArea) @system
{
    deallocatePixelStorage(mallocArea);
}

/// Deallocate an encoded image created with `saveToMemory`.
void freeEncodedImage(ubyte[] encodedImage) @system
{
    deallocateEncodedImage(encodedImage);
}

/// Image type.
/// Image has disabled copy ctor and postblit, to avoid accidental allocations.
/// 
/// IMPORTANT
///
/// Images are subtyped like this:
///
///                 Image                              Images can be: isError() or isValid().
///                /     \                             Image start their life as Image.init in error state.
///        isError()  or  isValid()                    Image that are `isValid` have a known PixelType, unlike `isError` images.
///                      /         \
///                hasData()  or   !hasData()          Images that have a type can have a data pointer or not.
///                                                    If it has no type, it implicitely has no data, and asking if it has data 
///                                                    is forbidden.
///                                                    Also: isOwned() exist for image that are hasData().
///                                                    Only image with hasData() have to follow the LayoutConstraints,
///                                                    though all image have a LayoutConstraints.
///
///     is8Bit  or   is16Bit  or    isFP32             Image components can be stored in 8-bit ubyte, 16-bit ushort, or float
///          \____      |    ______/
///               \     |   /
///                 isValid()
///            ___/     |   \______                    Planar and compressed images are not implemented yet, so it's only
///           /         |          \                   "plain pixels" for now.
///   isPlanar or isPlainPixels  or isCompressed
///                                                    Also: hasNonZeroSize(). 
///                                                    Images with a type have a width and height and a layer count
///                                                    (and any of this can be zero!).
///
///                 isValid()
///            ___/     |   \______                    Images can have several "layers", each of them is a consecutive 2D image.
///           /         |          \                   This is for animated image support.
/// hasZerolayer or hasOneLayer  or hasMultipleLayers  Similar to OpenGL 2D array textures.
///                     |
///                     V
///         (most typical case is 1 layer)
///
///
/// IMPORTANT: there is no constness in Image. All Image are considered read/write, with no const concept.
///
/// Public Functions are labelled this way:
///   #valid    => the calling Image must have a type (ie. not in error state).
///   #data     => the calling Image must have data (requires #valid)
///   #plain    => the calling Image must have plain-pixels.
///   #own      => the calling Image must have data AND own it.
/// It is a programming error to call a function that doesn't follow the tag constraints (will assert)
///
struct Image
{
nothrow @nogc @safe:
public:

    //
    // <BASIC STORAGE>
    //

    /// Get the pixel type.
    /// See_also: `PixelType`.
    /// Tags: none.
    PixelType type() pure const
    {
        return _type;
    }

    /// Returns: Width of image in pixels.
    /// Tags: #valid
    int width() pure const
    {
        assert(isValid());
        return _width;
    }

    /// Returns: Height of image in pixels.
    /// Tags: #valid
    int height() pure const
    {
        assert(isValid());
        return _height;
    }

    /// Returns: Number of layers.
    int layers() pure const
    {
        return _layerCount;
    }

    /// Get the image pitch (byte distance between rows), in bytes.
    ///
    /// Warning: This pitch can be, or not be, a negative integer.
    ///          When the image has layout constraint LAYOUT_VERT_FLIPPED, 
    ///             it is always kept <= 0 (if the image has data).
    ///          When the image has layout constraint LAYOUT_VERT_STRAIGHT, 
    ///             it is always kept >= 0 (if the image has data).
    ///
    /// See_also: `scanlineInBytes`.
    /// Tags: #valid #data
    int pitchInBytes() pure const
    {
        assert(isValid() && hasData());

        bool forceVFlip   = (_layoutConstraints & LAYOUT_VERT_FLIPPED) != 0;
        bool forceNoVFlip = (_layoutConstraints & LAYOUT_VERT_STRAIGHT) != 0;
        if (forceVFlip)
            assert(_pitch <= 0); // Note if height were zero, _pitch could perhaps be zero.
        if (forceNoVFlip)
            assert(_pitch >= 0);

        return _pitch;
    }

    /// Get the layer offset (byte distance between successive layers), in bytes.
    ///
    /// Warning: This pitch cannot be a negative integer.
    /// If the image has 0 or 1 layers, then return 0.
    ///
    /// See_also: `pitchInBytes`, `layers`.
    /// Tags: #valid #data
    int layerOffsetInBytes() pure const
    {
        assert(_layerCount >= 0);
        if (_layerCount == 0 || _layerCount == 1)
            assert(_layerOffset == 0);

        return _layerOffset;
    }

    /// Length of the managed scanline pixels, in bytes.
    /// 
    /// This is NOT the pointer offset between two scanlines (`pitchInBytes`).
    /// This is just `width() * size-of-one-pixel`.
    /// Those bytes are "part of the image", while the trailing and border pixels are not.
    ///
    /// See_also: `pitchInBytes`.
    /// Tags: #valid #data
    int scanlineInBytes() pure const
    {
        assert(hasData());
        return _width * pixelTypeSize(type);
    }

    /// A compressed image doesn't have its pixels available.
    /// Warning: only makes sense for image that `hasData()`, with non-zero height.
    /// Tags: #valid #data
    bool isStoredUpsideDown() pure const
    {
        assert(hasData());
        return _pitch < 0;
    }

    /// Returns a scanline pointer to the `y` nth line of pixels.
    /// Only possible if the image has plain pixels.
    /// What pixel format it points to, depends on the image `type()`.
    ///
    /// ---
    /// Guarantees by layout constraints:
    ///  * next scanptr (if any) is returned pointer + pitchInBytes() bytes.
    ///  * scanline pointer are aligned by given scanline alignment flags (at least).
    ///  * after each scanline there is at least a number of trailing pixels given by layout flags
    ///  * scanline pixels can be processed by multiplicity given by layout flags
    ///  * around the image, there is a border whose width is at least the one given by layout flags.
    ///  * it is valid, if the layout guarantees a border, to adress additional scanlines below 0 and
    ///    above height()-1
    /// ---
    ///
    /// For each scanline pointer, you can _always_ READ `ptr[0..abs(pitchInBytes())]` without memory error.
    /// However, WRITING to this scanline excess pixels doesn't guarantee anything by itself since the image 
    /// could be a sub-image, and the underlying buffer could be shared. 
    ///
    /// Returns: The scanline start.
    ///          Next scanline (if any) is returned pointer + pitchInBytes() bytes
    ///          If the layout has a border, you can adress pixels with a X coordinate in:
    ///          -borderWidth to width - 1 + borderWidth.
    /// Note: It is also valid to call scanline() and scanptr() for images that have zero width and/or zero height.
    /// Tags: #valid #data #plain
    inout(void)* scanptr(int y) inout pure @trusted
    {
        assert(isPlainPixels());
        int borderWidth = layoutBorderWidth(_layoutConstraints);
        assert( (y >= -borderWidth) && (y < _height + borderWidth) );
        return _data + _pitch * y;
    }

    /// Returns a slice to the `y` nth line of pixels.
    /// Only possible if the image has plain pixels.
    /// What pixel format it points to, depends on the image `type()`.
    ///
    /// Horizontally: trailing pixels, gap bytes, and border pixels are NOT included in that scanline, which is
    /// only the nominal image extent.
    ///
    /// However, vertically it is valid to adress scanlines on top and bottom of an image that has a border.
    /// It is also valid to call scanline() and scanptr() for images that have zero width and/or zero height.
    ///
    /// Returns: The whole `y`th row of pixels.
    /// Tags: #valid #data #plain
    inout(void)[] scanline(int y) inout pure @trusted
    {
        return scanptr(y)[0..scanlineInBytes()];
    }

    /// Returns a slice of all pixels at once in O(1). 
    /// This is only possible if the image is stored non-flipped, and without space
    /// between scanline.
    /// To avoid accidental correctness, the image need the layout constraints:
    /// `LAYOUT_GAPLESS | LAYOUT_VERT_STRAIGHT`.
    /// Tags: #valid #data #plain
    inout(ubyte)[] allPixelsAtOnce() inout pure @trusted
    {
        assert(isPlainPixels());

        // the image need the LAYOUT_GAPLESS flag.
        assert(isGapless());

        // the image need the LAYOUT_VERT_STRAIGHT flag.
        assert(mustNotBeStoredUpsideDown());

        // Why there is no #overflow here:
        int psize = pixelTypeSize(_type);

        assert(psize <= GAMUT_MAX_PIXEL_SIZE);
        assert(_width <= GAMUT_MAX_IMAGE_WIDTH);
        assert(_height <= GAMUT_MAX_IMAGE_HEIGHT);

        // Note: it should fit into size_t. 
        // If the image size was larger than that, it couldn't have been created.
        long numBytes = (cast(long)_width) * _height * psize;
        assert(numBytes <= cast(ulong)(size_t.max));

        return _data[0..cast(size_t)numBytes];
    }

    //
    // </BASIC STORAGE>
    //

    //
    // <RESOLUTION>
    //

    /// Returns: Horizontal resolution in Dots Per Inch (DPI).
    ///          `GAMUT_UNKNOWN_RESOLUTION` if unknown.
    /// Tags: none.
    float dotsPerInchX() pure const
    {
        if (_resolutionY == GAMUT_UNKNOWN_RESOLUTION || _pixelAspectRatio == GAMUT_UNKNOWN_ASPECT_RATIO)
            return GAMUT_UNKNOWN_RESOLUTION;
        return _resolutionY * _pixelAspectRatio;
    }

    /// Returns: Vertical resolution in Dots Per Inch (DPI).
    ///          `GAMUT_UNKNOWN_RESOLUTION` if unknown.
    /// Tags: none.
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
    /// Tags: none.
    float pixelAspectRatio() pure const
    {
        return _pixelAspectRatio;
    }

    /// Returns: Horizontal resolution in Pixels Per Meters (PPM).
    ///          `GAMUT_UNKNOWN_RESOLUTION` if unknown.
    /// Tags: none.
    float pixelsPerMeterX() pure const
    {
        float dpi = dotsPerInchX();
        if (dpi == GAMUT_UNKNOWN_RESOLUTION)
            return GAMUT_UNKNOWN_RESOLUTION;
        return convertMetersToInches(dpi);
    }

    /// Returns: Vertical resolution in Pixels Per Meters (PPM).
    ///          `GAMUT_UNKNOWN_RESOLUTION` if unknown.
    /// Tags: none.
    float pixelsPerMeterY() pure const
    {
        float dpi = dotsPerInchY();
        if (dpi == GAMUT_UNKNOWN_RESOLUTION)
            return GAMUT_UNKNOWN_RESOLUTION;
        return convertMetersToInches(dpi);
    }

    //
    // </RESOLUTION>
    //


    //
    // <GETTING STATUS AND CAPABILITIES>
    //

    /// The image is unusable and has no known `PixelType`, nor any data pointed to.
    /// You can reach this state with OOM, failing to load a source image, etc.
    /// Always return `!isError()`.
    /// Tags: none.
    deprecated("Use isError() or isValid() instead") alias errored = isError;
    bool isError() pure const
    {
        return _error !is null;
    }

    /// Im  ge is valid, meaning it is not in error state.
    /// Always return `!isError()`.
    /// Tags: none.
    bool isValid() pure const
    {
        return _error is null;
    }

    /// The error message (null if no error currently held).
    /// This slice is followed by a '\0' zero terminal character, so
    /// it can be safely given to `print`.
    /// Tags: none.
    const(char)[] errorMessage() pure const @trusted
    {
        if (_error is null)
            return null;
        return _error[0..strlen(_error)];
    }

    /// An image can have a pixel type (usually pixels), or not.
    /// Not a lot of operations are available if there is no type.
    /// Note: An image that has no must necessarily have no data.
    /// Tags: none.
    deprecated("Use isValid() or isError() instead") bool hasType() pure const
    {
        return _type != PixelType.unknown;
    }

    // Enable this when debugging gamut
    /*
    invariant()
    {
        if (_error is null)
        {
            assert(_type != PixelType.unknown);
        }
        else if (_error !is null)
        {
            assert(_type == PixelType.unknown);
        }
    }
    */

    /// Is the image type represented by 8-bit components?
    /// Tags: #valid.
    bool is8Bit() pure const
    {
        assert(isValid);
        return convertPixelTypeTo8Bit(_type) == _type;
    }

    /// Is the image type represented by 16-bit components?
    /// Tags: #valid.
    bool is16Bit() pure const
    {
        assert(isValid);
        return convertPixelTypeTo16Bit(_type) == _type;
    }

    /// Is the image type represented by 32-bit floating point components?
    /// Tags: #valid.
    bool isFP32() pure const
    {
        assert(isValid);
        return convertPixelTypeToFP32(_type) == _type;
    }
    
    /// An image can have data (usually pixels), or not.
    /// "Data" refers to pixel content, that can be in a decoded form, but also in more
    /// complicated forms such as planar, compressed, etc. (FUTURE)
    ///
    /// Note: An image that has no data doesn't have to follow its `LayoutConstraints`.
    ///       But an image with zero size must.
    /// An image that "has data" also "has a type".
    /// Tags: #valid.
    bool hasData() pure const
    {
        // If you crash here, the image is errored, and you should have checked for it.
        // It doesn't make sense to ask if an image has data, if it doesn't have a type (error state).
        // "Having data" is a superset of having a _type.
        assert(isValid());

        return _data !is null;
    }

    /// An that has data can own it (will free it in destructor) or can borrow it.
    /// An image that has no data, cannot own it.
    /// Tags: none.
    bool isOwned() pure const
    {
        return hasData() && (_allocArea !is null);
    }

    /// Disown the image allocation data.
    /// This return both the pixel _data (same as and the allocation data
    /// The data MUST be freed with `freeImageData`.
    /// The image still points into that data, and you must ensure the data lifetime exceeeds
    /// the image lifetime.
    /// Tags: #valid #own #data 
    /// Warning: this return the malloc'ed area, NOT the image data itself.
    ///          However, with the constraints
    ubyte* disownData() pure 
    {
        assert(isOwned());
        ubyte* r = _allocArea;
        _allocArea = null;
        assert(!isOwned());
        return r;
    }

    /// A plain pixel image is for example rgba8, and has `scanline()` access.
    /// Currently only one supported.
    /// Tags: #valid.
    deprecated alias hasPlainPixels = isPlainPixels;
    bool isPlainPixels() pure const
    {
        assert(isValid);
        return pixelTypeIsPlain(_type); // Note: all formats are plain, for now.
    }

    /// A planar image is for example YUV420.
    /// If the image is planar, its rows are not accessible like that.
    /// Currently not supported.
    /// Tags: #valid.
    bool isPlanar() pure const
    {
        assert(isValid);
        return pixelTypeIsPlanar(_type);
    }

    /// A compressed image doesn't have its pixels available.
    /// Currently not supported.
    /// Tags: #valid.
    bool isCompressed() pure const
    {
        assert(isValid);
        return pixelTypeIsCompressed(_type);
    }

    /// An image for which width > 0 and height > 0.
    /// Tags: none.
    bool hasNonZeroSize() pure const
    {
        return width() != 0 && height() != 0 && layers() != 0;
    }

    /// An image is allowed to have zero layers, in which case it is considered much like 
    /// having zero width or zero height.
    /// Tags: #valid.
    bool hasZeroLayer() pure const
    {
        assert(isValid);
        return _layerCount == 0;
    }

    /// Typical images have one layer.
    /// Tags: #valid.
    bool hasSingleLayer() pure const
    {
        assert(isValid);
        return _layerCount == 1;
    }

    /// Animated images have more.
    /// Tags: #valid.
    bool hasMultipleLayers() pure const
    {
        assert(isValid);
        return _layerCount > 1;
    }

    //
    // </GETTING STATUS AND CAPABILITIES>
    //


    //
    // <INITIALIZE>
    //

    /// Clear the image, and creates a new owned image, with given dimensions and plain pixels.
    /// The image data is cleared with zeroes.
    /// Tags: none.
    this(int width, int height, 
         PixelType type = PixelType.rgba8,
         LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        create(width, height, type, layoutConstraints);
    }
    ///ditto
    void create(int width, int height, 
                PixelType type = PixelType.rgba8,
                LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        createLayered(1, width, height, type, layoutConstraints);
    }
    ///ditto
    void createLayered(int layers, int width, int height, 
                       PixelType type = PixelType.rgba8,
                       LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        if (!forgetPreviousUsage(layers, width, height))
            return;

        if (!setStorage(layers, width, height, type, layoutConstraints, true))
        {
            // precise error set by setStorage
            return;
        }
    }

    /// Clear the image, and creates a new owned image, with given dimensions and plain pixels.
    /// The image data is left uninitialized, so it may contain data from former allocations.
    /// Tags: none.
    void createNoInit(int width, int height, 
                      PixelType type = PixelType.rgba8,
                      LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        createLayeredNoInit(1, width, height, type, layoutConstraints);
    }
    ///ditto
    void createLayeredNoInit(int layers, int width, int height, 
                             PixelType type = PixelType.rgba8,
                             LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        if (!forgetPreviousUsage(layers, width, height))
            return;

        if (!setStorage(layers, width, height, type, layoutConstraints, false))
        {
            // precise error set by setStorage
            return;
        }
    }
    ///ditto
    alias setSize = createNoInit; // TODO: deprecated that bad name, 
                                  // it sounds like there will be a "resize" with resampling

    // TODO createView from another Image + a rect

    /// Create a view into existing data.
    /// The image data is considered read/write, and not owned.
    /// No layout constraints are assumed.
    /// The input scanlines must NOT overlap.
    /// Params:
    ///    data             Pointer to first scanline pixels.
    ///    layers           Number of layers.
    ///    width            Width of input data in pixels.
    ///    height           Height of input data in pixels.
    ///    type             Type of pixels for the created view.
    ///    pitchInBytes     Byte offset between two consecutive rows of pixels.
    ///                     Can not be too small as the scanline would overlap, in this case the 
    ///                     image will be left in an errored state.
    ///    layerOffsetBytes Byte offset between two consecutive layers. Can not be negative.
    ///                     for layers == 0 or layers == 1, this is ignored and 0 is set instead.  
    /// Tags: none.
    void createViewFromData(void* data, 
                            int width, 
                            int height, 
                            PixelType type,
                            int pitchInBytes) @system
    {
        createLayeredViewFromData(data, 1, width, height, type, pitchInBytes, 0);        
    }
    ///ditto
    void createLayeredViewFromData(void* data, 
                                   int layers,
                                   int width, 
                                   int height, 
                                   PixelType type,
                                   int pitchInBytes,
                                   int layerOffsetBytes) @system
    {
        if (!forgetPreviousUsage(layers, width, height))
            return;

        // If scanlines overlap, there is a problem.
        int minPitch = pixelTypeSize(type) * width;
        int absPitch = pitchInBytes >= 0 ? pitchInBytes : -pitchInBytes;
        if (absPitch < minPitch)
        {
            error(kStrOverlappingScanlines);
            return;
        }

        bool hasMultipleLayers = (layers > 1);

        if (hasMultipleLayers)
        {
            if (layerOffsetBytes < 0)
            {
                error(kStrInvalidNegLayerOffset);
                return;
            }
            long minLayerOffset = cast(long)absPitch * height;
            if (layerOffsetBytes < minLayerOffset)
            {
                error(kStrOverlappingLayers);
                return;
            }
        }

        _data = cast(ubyte*) data;
        _allocArea = null; // not owned
        _type = type;
        _width = width;
        _height = height;
        _pitch = pitchInBytes;
        _layoutConstraints = LAYOUT_DEFAULT; // No constraint whatsoever, we lack that information
        _layerCount = layers;
        _layerOffset = (layers == 0 || layers == 1) ? 0 : layerOffsetBytes;
    }

    deprecated("Use createWithNoData instead") alias initWithNoData = createWithNoData;

    /// Initialize an image with no data, for example if you wanted an image without the pixel content.
    /// Tags: none.
    void createWithNoData(int width, int height, 
                          PixelType type = PixelType.rgba8,
                          LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        createLayeredWithNoData(1, width, height, type, layoutConstraints);
    }
    ///ditto
    void createLayeredWithNoData(int layers, int width, int height, 
                                 PixelType type = PixelType.rgba8,
                                 LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        if (!forgetPreviousUsage(layers, width, height))
            return;

        if (!layoutConstraintsValid(layoutConstraints))
        {
            error(kStrIllegalLayoutConstraints);
            return;
        }

        _data = null;      // no data
        _allocArea = null; // not owned
        _type = type;
        _width = width;
        _height = height;
        _pitch = 0;
        _layoutConstraints = layoutConstraints;
        _layerCount = layers;
        _layerOffset = 0;
    }

    /// Clone an existing image. 
    /// This image should have plain pixels.
    /// Tags: #valid #data #plain.
    Image clone() const
    {
        assert(isPlainPixels());

        Image r;
        r.setSize(_width, _height, _type, _layoutConstraints);
        if (r.isError)
            return r;

        copyPixelsTo(r);
        return r;
    }

    /// Copy pixels to an image with same size and type. Both images should have plain pixels.
    /// Tags: #valid #data #plain.
    void copyPixelsTo(ref Image img) const @trusted
    {
        assert(isPlainPixels());

        assert(img._width  == _width);
        assert(img._height == _height);
        assert(img._type   == _type);

        // PERF: if both are gapless, can do a single memcpy

        int scanlineLen = _width * pixelTypeSize(type);

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
    ///
    /// Params:
    ///    path  A string containing the file path.
    ///    flags Flags can contain LOAD_xxx flags and LAYOUT_xxx flags.
    ///
    /// Returns: `true` if successfull. The image will be in errored state if there is a problem.
    /// See_also: `LoadFlags`, `LayoutConstraints`.
    /// Tags: none.
    bool loadFromFile(const(char)[] path, int flags = 0) @trusted
    {
        cleanupBitmapAndTypeIfAny();

        CString cstr = CString(path);

        // Deduce format.
        ImageFormat fif = identifyFormatFromFile(cstr.storage);
        if (fif == ImageFormat.unknown) 
        {
            fif = identifyImageFormatFromFilename(cstr.storage); // try to guess the file format from the file extension
        }
        
        loadFromFileInternal(fif, cstr.storage, flags);
        return isValid();
    }

    /// Load an image from a memory location.
    ///
    /// Params:
    ///    bytes Arrays containing the encoded image to decode.
    ///    flags Flags can contain LOAD_xxx flags and LAYOUT_xxx flags.
    ///
    /// Returns: `true` if successfull. The image will be in errored state if there is a problem.
    ///
    /// See_also: `LoadFlags`, `LayoutConstraints`.
    /// Tags: none.
    bool loadFromMemory(const(ubyte)[] bytes, int flags = 0) @trusted
    {
        cleanupBitmapAndTypeIfAny();

        MemoryFile mem;
        mem.initFromExistingSlice(bytes);

        // Deduce format.
        ImageFormat fif = identifyFormatFromMemoryFile(mem);

        IOStream io;
        io.setupForMemoryIO();
        loadFromStreamInternal(fif, io, cast(IOHandle)&mem, flags);

        return isValid();
    }
    ///ditto
    bool loadFromMemory(const(void)[] bytes, int flags = 0) @trusted
    {
        return loadFromMemory(cast(const(ubyte)[])bytes, flags);
    }

    /// Load an image from a set of user-defined I/O callbacks.
    ///
    /// Params:
    ///    fif The target image format.
    ///    io The user-defined callbacks.
    ///    handle A void* user pointer to pass to I/O callbacks.
    ///    flags Flags can contain LOAD_xxx flags and LAYOUT_xxx flags.
    ///
    /// Tags: none.
    bool loadFromStream(ref IOStream io, IOHandle handle, int flags = 0) @system
    {
        cleanupBitmapAndTypeIfAny();

        // Deduce format from stream.
        ImageFormat fif = identifyFormatFromStream(io, handle);

        loadFromStreamInternal(fif, io, handle, flags);
        return isValid();
    }
    
    /// Saves an image to a file, detecting the format from the path extension.
    ///
    /// Params:
    ///     path The path of output file.
    ///      
    /// Returns: `true` if file successfully written.
    /// Tags: none.
    bool saveToFile(const(char)[] path, int flags = 0) @trusted
    {
        assert(isValid()); // else, nothing to save
        CString cstr = CString(path);

        ImageFormat fif = identifyImageFormatFromFilename(cstr.storage);
        
        return saveToFileInternal(fif, cstr.storage, flags);
    }
    /// Save the image into a file, with a given file format.
    ///
    /// Params:
    ///     fif The `ImageFormat` to use.
    ///     path The path of output file.
    ///
    /// Returns: `true` if file successfully written.
    /// Tags: none.
    bool saveToFile(ImageFormat fif, const(char)[] path, int flags = 0) const @trusted
    {
        assert(isValid()); // else, nothing to save
        CString cstr = CString(path);
        return saveToFileInternal(fif, cstr.storage, flags);
    }

    /// Saves the image into a new memory location.
    /// The returned data must be released with a call to `freeEncodedImage`.
    /// Returns: `null` if saving failed.
    /// Warning: this is NOT GC-allocated, so this allocation will leak unless you call 
    /// `freeEncodedImage` after use.
    /// Tags: none.
    ubyte[] saveToMemory(ImageFormat fif, int flags = 0) const @trusted
    {
        assert(isValid()); // else, nothing to save

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

    /// Save an image with a set of user-defined I/O callbacks.
    ///
    /// Params:
    ///     fif The `ImageFormat` to use.
    ///     io User-defined stream object.
    ///     handle User provided `void*` pointer  passed to the I/O callbacks.
    ///
    /// Returns: `true` if file successfully written.
    /// Tags: none.
    bool saveToStream(ImageFormat fif, ref IOStream io, IOHandle handle, int flags = 0) const @trusted
    {
        assert(isValid()); // else, nothing to save

        if (fif == ImageFormat.unknown)
        {
            // No format given for save.
            return false;
        }

        if (!isPlainPixels)
            return false; // no data that is pixels, impossible to save that.

        const(ImageFormatPlugin)* plugin = &g_plugins[fif];
        void* data = null; // probably exist to pass metadata stuff
        if (plugin.saveProc is null)
            return false;
        bool r = plugin.saveProc(this, &io, handle, 0, flags, data);
        return r;
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
            if (fif != ImageFormat.TGA)
            {
                if (detectFormatFromStream(fif, io, handle))
                    return fif;
            }
        }

        // Note: TGA needs to be last, because the detection test is fuzzy for this one.
        if (detectFormatFromStream(ImageFormat.TGA, io, handle))
            return ImageFormat.TGA;

        return ImageFormat.unknown;
    }

    /// Identify the format of an image by looking at its extension.
    /// Returns: Its `ImageFormat`, or `ImageFormat.unknown` in case of identification failure or input error.
    ///          Maybe then you can try `identifyFormatFromFile` instead, which minimally reads the input.
    static ImageFormat identifyFormatFromFileName(const(char) *filename)
    {
        return identifyImageFormatFromFilename(filename);
    }

    // 
    // </FILE FORMAT IDENTIFICATION>
    //


    //
    // <CONVERSION>
    //

    /// Get the image layout constraints.
    /// Tags: none.
    LayoutConstraints layoutConstraints() pure const
    {
        return _layoutConstraints;
    }

    /// Keep the same pixels and type, but change how they are arranged in memory to fit some constraints.
    /// Tags: #valid
    deprecated("use setLayout instead") alias changeLayout = setLayout;
    bool setLayout(LayoutConstraints layoutConstraints)
    {
        return convertTo(_type, layoutConstraints);
    }

    /// Convert the image to greyscale, using a greyscale transformation (all channels weighted equally).
    /// Alpha is preserved if existing.
    /// Tags: #valid
    bool convertToGreyscale(LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        return convertTo( convertPixelTypeToGreyscale(_type), layoutConstraints);
    }

    /// Convert the image to a greyscale + alpha equivalent, using duplication and/or adding an opaque alpha channel.
    /// Tags: #valid
    bool convertToGreyscaleAlpha(LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        return convertTo( convertPixelTypeToAddAlphaChannel( convertPixelTypeToGreyscale(_type) ), layoutConstraints);
    }

    /// Convert the image to a RGB equivalent, using duplication if greyscale.
    /// Alpha is preserved if existing.
    /// Tags: #valid
    bool convertToRGB(LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        return convertTo( convertPixelTypeToRGB(_type), layoutConstraints);
    }

    /// Convert the image to a RGBA equivalent, using duplication and/or adding an opaque alpha channel.
    /// Tags: #valid
    bool convertToRGBA(LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        return convertTo( convertPixelTypeToAddAlphaChannel( convertPixelTypeToRGB(_type) ), layoutConstraints);
    }

    /// Add an opaque alpha channel if not-existing already.
    /// Tags: #valid
    bool addAlphaChannel(LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        return convertTo( convertPixelTypeToAddAlphaChannel(_type), layoutConstraints);
    }

    /// Removes the alpha channel if not-existing already.
    /// Tags: #valid
    bool dropAlphaChannel(LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        return convertTo( convertPixelTypeToDropAlphaChannel(_type), layoutConstraints);
    }

    /// Convert the image bit-depth to 8-bit per component.
    /// Tags: #valid
    bool convertTo8Bit(LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        return convertTo( convertPixelTypeTo8Bit(_type), layoutConstraints);
    }

    /// Convert the image bit-depth to 16-bit per component.
    /// Tags: #valid.
    bool convertTo16Bit(LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        return convertTo( convertPixelTypeTo16Bit(_type), layoutConstraints);
    }

    /// Convert the image bit-depth to 32-bit float per component.
    /// Tags: #valid.
    bool convertToFP32(LayoutConstraints layoutConstraints = LAYOUT_DEFAULT)
    {
        return convertTo( convertPixelTypeToFP32(_type), layoutConstraints);
    }

    /// Convert the image to the following format.
    /// This can destruct channels, loose precision, etc.
    /// You can also change the layout constraints at the same time.
    ///
    /// Returns: true on success.
    /// Tags: #valid.
    bool convertTo(PixelType targetType, LayoutConstraints layoutConstraints = LAYOUT_DEFAULT) @trusted
    {
        assert(isValid()); // this should have been caught before.

        if (targetType == PixelType.unknown)
        {
            error(kStrUnsupportedTypeConversion);
            return false;
        }

        // The asked for layout must be valid itself.
        assert(layoutConstraintsValid(layoutConstraints));

        if (!hasData())
        {
            _type = targetType;
            _layoutConstraints = layoutConstraints;
            return true; // success, no pixel data, so everything was "converted", layout constraints do not hold
        }

        // Detect if the particular hazard of allocation have given the image "ad-hoc" constraints
        // we didn't strictly require. Typically, if the image is already vertically straight, no need to 
        // reallocate just for that.
        LayoutConstraints adhocConstraints = getAdHocLayoutConstraints();

        enum bool useAdHoc = true; // FUTURE: remove once deemed harmless

        // Are the new layout constraints already valid?
        bool compatibleLayout = layoutConstraintsCompatible(layoutConstraints, useAdHoc ? adhocConstraints : _layoutConstraints);

        if (_type == targetType && compatibleLayout)
        {
            // PERF: it would be possible, if the layout only differ for stance with Vflip, to flip
            // lines in place here. But this can be handled below with reallocation.
            _layoutConstraints = layoutConstraints;
            return true; // success, same type already, and compatible constraints
        }

        if ((width() == 0 || height()) == 0 && compatibleLayout)
        {
            // Image dimension is zero, and compatible constraints, everything fine
            // No need for reallocation or copy.
            _layoutConstraints = layoutConstraints;
            return true;
        }

        ubyte* source = _data;
        int sourcePitch = _pitch;

        // Do not realloc the same block to avoid invalidating previous data.
        // We'll manage this manually.
        assert(_data !is null);

        // PERF: do some conversions in place? if target type is smaller then input, always possible

        // Do we need to convert scanline by scanline, using a scratch buffer?
        bool needConversionWithIntermediateType = targetType != _type;
        PixelType interType = intermediateConversionType(_type, targetType);
        int interBufSize = width * pixelTypeSize(interType);
        int bonusBytes = needConversionWithIntermediateType ? interBufSize : 0;

        int layerCount = _layerCount; // keep same number of layers

        ubyte* dest; // first scanline
        ubyte* newAllocArea;  // the result of realloc-ed
        int destPitch;
        int destLayerOffset;
        bool err;
        bool clearWithZeroes = false; // no need, since all pixels will be rewritten
        allocatePixelStorage(null, // so that the former allocation keep existing for the copy
                             targetType,
                             layerCount,
                             width,
                             height,
                             layoutConstraints,
                             bonusBytes,
                             clearWithZeroes,
                             dest,
                             newAllocArea,
                             destPitch,
                             destLayerOffset,
                             err);
        
        if (err)
        {
            error(kStrOutOfMemory);
            return false;
        }

        // Do we need a conversion of just a memcpy?
        bool ok = false;
        if (targetType == _type)
        {
            // TODO: iterate for each layer
            ok = copyScanlines(targetType, 
                               source, sourcePitch,
                               dest, destPitch,
                               width, height);
        }
        else
        {
            // TODO: iterate for each layer
            // Need an intermediate buffer. We allocated one in the new image buffer.
            // After that conversion, noone will ever talk about it, and the bonus bytes will stay unused.
            ubyte* interBuf = newAllocArea;

            ok = convertScanlines(_type, source, sourcePitch, 
                                  targetType, dest, destPitch,
                                  width, height,
                                  interType, interBuf);
        }

        if (!ok)
        {
            // Keep former image
            deallocatePixelStorage(newAllocArea);
            error(kStrUnsupportedTypeConversion);
            return false;
        }

        cleanupBitmapAndTypeIfAny(); // forget about former image

        _layoutConstraints = layoutConstraints;
        _data = dest;
        _allocArea = newAllocArea; // now own the new one.
        _type = targetType;
        _pitch = destPitch;
        _layerCount = layerCount;
        _layerOffset = destLayerOffset;
        _error = null;
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
    /// TODO: castTo breaks layout constraints, what to do with them?
    /// Tags: #valid.
    bool castTo(PixelType targetType) @trusted
    {
        assert(isValid());
        if (targetType == PixelType.unknown)
        {
            // TODO: should cleanup data
            error(kStrInvalidPixelTypeCast);
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
        int srcBytes = pixelTypeSize(_type);
        int destBytes = pixelTypeSize(_type);

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
            // TODO: should cleanup data
            error(kStrInvalidPixelTypeCast);
            return false;
        }
    }

    //
    // </CONVERSION>
    //


    //
    // <LAYOUT>
    //

    /// On how many bytes each scanline is aligned.
    /// Useful to know for SIMD.
    /// The actual alignment could be higher than what the layout constraints strictly tells.
    /// See_also: `LayoutConstraints`.
    /// Tags: none.
    int scanlineAlignment()
    {
        return layoutScanlineAlignment(_layoutConstraints);
    }

    /// Get the number of border pixels around the image.
    /// This is an area that can be safely accessed, using -pitchInBytes() and pointer offsets.
    /// The actual border width could well be higher, but there is no way of safely knowing that.
    /// See_also: `LayoutConstraints`.
    /// Tags: none.
    int borderWidth() pure
    {
        return layoutBorderWidth(_layoutConstraints);
    }

    /// Get the multiplicity of pixels in a single scanline.
    /// The actual multiplicity could well be higher.
    /// See_also: `LayoutConstraints`.
    /// Tags: none.
    int pixelMultiplicity()
    {
        return layoutMultiplicity(_layoutConstraints);
    }

    /// Get the guaranteed number of scanline trailing pixels, from the layout constraints.
    /// Each scanline is followed by at least that much out-of-image pixels, that can be safely
    /// READ.
    /// The actual number of trailing pixels can well be larger than what the layout strictly tells,
    /// but we'll never know.
    /// See_also: `LayoutConstraints`.
    /// Tags: none.
    int trailingPixels() pure
    {
        return layoutTrailingPixels(_layoutConstraints);
    }

    /// Get if being gapless is guaranteed by the layout constraints.
    /// Note that this only holds if there is some data in the first place.
    /// See_also: `allPixels()`, `LAYOUT_GAPLESS`, `LAYOUT_VERT_STRAIGHT`.
    /// Tags: none.
    bool isGapless() pure const
    {
        return layoutGapless(_layoutConstraints);
    }

    /// Returns: `true` is the image is constrained to be stored upside-down.
    /// Tags: none.
    bool mustBeStoredUpsideDown() pure const
    {
        return (_layoutConstraints & LAYOUT_VERT_FLIPPED) != 0;
    }

    /// Returns: `true` is the image is constrained to NOT be stored upside-down.
    /// Tags: none.
    bool mustNotBeStoredUpsideDown() pure const
    {
        return (_layoutConstraints & LAYOUT_VERT_STRAIGHT) != 0;
    }

    //
    // </LAYOUT>
    //

    //
    // <TRANSFORM>
    //

    /// Flip the image data horizontally.
    /// If the image has no data, the operation is successful.
    /// Tags: #valid.
    bool flipHorizontally() pure @trusted
    {
        assert(isValid());

        if (!hasData())
            return true; // Nothing to do

        ubyte[GAMUT_MAX_PIXEL_SIZE] temp;

        int W = width();
        int H = height();
        int Xdiv2 = W / 2;
        int scanBytes = scanlineInBytes();
        int psize = pixelTypeSize(type);

        // Stupid pixel per pixel swap
        for (int y = 0; y < H; ++y)
        {
            ubyte* scan = cast(ubyte*) scanline(y);
            for (int x = 0; x < Xdiv2; ++x)
            {
                ubyte* pixelA = &scan[x * psize];
                ubyte* pixelB = &scan[(W - 1 - x) * psize];
                temp[0..psize] = pixelA[0..psize];
                pixelA[0..psize] = pixelB[0..psize];
                pixelB[0..psize] = temp[0..psize];
            }
        }
        return true;
    }

    /// Flip the image vertically.
    /// If the image has no data, the operation is successful.
    ///
    /// - If the layout allows it, `flipVerticallyLogical` is called. The scanline pointers are 
    ///   inverted, and pitch is negated. This just flips the "view" of the image.
    ///
    /// - If there is a constraint to keep the image strictly upside-down, or strictly not 
    ///   upside-down, then `flipVerticallyPhysical` is called instead.
    ///
    /// Returns: `true` on success, sets an error else and return `false`.
    /// Tags: #valid.
    bool flipVertically() pure
    {
        assert(isValid());

        if (mustBeStoredUpsideDown() || mustNotBeStoredUpsideDown())
            return flipVerticallyPhysical();
        else
            return flipVerticallyLogical();
    }
    ///ditto
    bool flipVerticallyLogical() pure @trusted
    {
        if (!hasData())
            return true; // Nothing to do

        if (mustBeStoredUpsideDown() || mustNotBeStoredUpsideDown())
        {
            error(kStrUnsupportedVFlip);
            return false;
        }

        // Note: flipping the image preserve all layout properties! 
        // What a nice design here.
        // Border, trailing pixels, scanline alignment... they all survive vertical flip.
        flipScanlinePointers(_width, _height, _data, _pitch);

        return true;
    }
    ///ditto
    bool flipVerticallyPhysical() pure @trusted
    {
        if (!hasData())
            return true; // Nothing to do

        int H = height();
        int Ydiv2 = H / 2;
        int scanBytes = scanlineInBytes();

        // Stupid byte per byte swap
        for (int y = 0; y < Ydiv2; ++y)
        {
            ubyte* scanA = cast(ubyte*) scanline(y);
            ubyte* scanB = cast(ubyte*) scanline(H - 1 - y);
            for (int b = 0; b < scanBytes; ++b)
            {
                ubyte ch = scanA[b];
                scanA[b] = scanB[b]; 
                scanB[b] = ch;
            }
        }
        return true;
    }

    //
    // </TRANSFORM>
    //

    @disable this(this); // Non-copyable. This would clone the image, and be expensive.


    /// Destructor. Everything is reclaimed.
    ~this()
    {
        cleanupBitmapAndTypeIfAny();
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

        // must loose type
        _type = PixelType.unknown;
    }

    /// The type of the data pointed to.
    PixelType _type = PixelType.unknown;

    /// The data layout constraints, in flags.
    /// See_also: `LayoutConstraints`.
    LayoutConstraints _layoutConstraints = LAYOUT_DEFAULT;

    /// Pointer to the pixel data. What is pointed to depends on `_type`.
    /// The amount of what is pointed to depends upon the dimensions.
    /// it is possible to have `_data` null but `_type` is known.
    ubyte* _data = null;

    /// Pointer to the `malloc` area holding the data.
    /// _allocArea being null signify that there is no data, or that the data is borrowed.
    /// _allocArea not being null signify that the image is owning its data.
    ubyte* _allocArea = null;

    /// Width of the image in pixels, when pixels makes sense.
    /// By default, this width is 0 (but as the image has no pixel data, this doesn't matter).
    int _width = 0;

    /// Height of the image in pixels, when pixels makes sense.
    /// By default, this height is 0 (but as the image has no pixel data, this doesn't matter).
    int _height = 0;

    /// Number of layers of the image. A normal image has typically 1 layer, animated image have more.
    int _layerCount = 0;

    /// Pitch in bytes between lines, when a pitch makes sense. This pitch can be, or not be, a negative integer.
    /// When the image has layout constraint LAYOUT_VERT_FLIPPED, it is always kept <= 0.
    /// When the image has layout constraint LAYOUT_VERT_STRAIGHT, it is always kept >= 0.
    int _pitch = 0; 

    /// Pitch in bytes between successive layers. All layers have same dimension and constraints and type.
    /// Always >= 0, unlike _pitch.
    int _layerOffset = 0;

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
    deprecated int computePitch(PixelType type, int width)
    {
        return width * pixelTypeSize(type);
    }

    // Used by creation functions, this makes some checks too.
    bool forgetPreviousUsage(int newLayers, int newWidth, int newHeight) @safe
    {
        // FUTURE: Note that this invalidates any borrow we could have here...
        cleanupBitmapAndTypeIfAny();

        clearError();

        if (newLayers < 0 || newWidth < 0 || newHeight < 0)
        {
            error(kStrIllegalNegativeDimension);
            return false;
        }

        if (!imageIsValidSize(newLayers, newWidth, newHeight))
        {
            error(kStrImageTooLarge);
            return false;
        }
        return true;
    }

    void cleanupBitmapAndTypeIfAny() @safe
    {
        cleanupBitmapIfAny();
        cleanupTypeIfAny();
    }

    void cleanupBitmapIfAny() @trusted
    {
        cleanupBitmapIfOwned();
        _data = null;
    }

    void cleanupTypeIfAny()
    {
        _type = PixelType.unknown;
        _error = assumeZeroTerminated(kStrImageHasNoType);
    }

    // If owning an allocation, free it, else keep it.
    void cleanupBitmapIfOwned() @trusted
    {        
        if (_allocArea !is null)
        {
            deallocatePixelStorage(_allocArea);
            _allocArea = null;
            _data = null;
        }
    }

    /// Discard ancient data, and reallocate stuff.
    /// Returns true on success, false on OOM.
    /// When failing, sets the errored state.
    private bool setStorage(
                    int numLayers,
                    int width,
                    int height,
                    PixelType type, 
                    LayoutConstraints constraints,
                    bool clearWithZeroes) @trusted
    {
        if (!layoutConstraintsValid(constraints))
        {
            error(kStrIllegalLayoutConstraints);
            return false;
        }

        ubyte* dataPointer;
        ubyte* mallocArea;
        int pitchBytes;
        int layerOffset;
        bool err;

        allocatePixelStorage(_allocArea,
                             type, 
                             numLayers,
                             width,
                             height,
                             constraints,
                             0,
                             clearWithZeroes,
                             dataPointer,
                             mallocArea,
                             pitchBytes,
                             layerOffset,
                             err);
        if (err)
        {
            error(kStrOutOfMemory);
            return false;
        }

        _data = dataPointer;
        _allocArea = mallocArea;
        _type = type;
        _width = width;
        _height = height;
        _pitch = pitchBytes;
        _layoutConstraints = constraints;
        _layerCount = numLayers;
        _layerOffset = layerOffset;

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
        loadFromStreamInternal(fif, io, cast(IOHandle)f, flags);

        if (0 != fclose(f))
        {
            // TODO cleanup image?
            error(kStrFileCloseFailed);
        }
    }

    void loadFromStreamInternal(ImageFormat fif, ref IOStream io, IOHandle handle, int flags = 0) @system
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

    // When we look at this Image, what are some constraints that it could spontaneously follow?
    // Also look at existing _layoutConstraints.
    // Params:
    //     preferGapless Generates a LayoutConstraints with LAYOUT_GAPLESS rather than other things.
    //
    // Warning: the LayoutConstraints it returns is not necessarilly user-valid, it can contain both
    //          scanline alignment and gapless constraints. This should NEVER be kept as actual constraints.
    LayoutConstraints getAdHocLayoutConstraints()
    {
        assert(hasData());

        // An image that doesn't own its data can't infer some adhoc constraints, or the conditions are stricter.        
        bool owned = isOwned;

        int pitch = pitchInBytes();
        int absPitch = pitch >= 0 ? pitch : -pitch;
        int scanLen = scanlineInBytes();
        int pixelSize = pixelTypeSize(type);
        int width = _width;
        int excessBytes = scanLen - absPitch;
        int excessPixels = excessBytes / pixelSize;
        assert(excessBytes >= 0 && excessPixels >= 0);
        
        LayoutConstraints c = 0;

        // Multiplicity constraint: take largest of inferred, and _layoutConstraints-related.
        {
            int multi = pixelMultiplicity(); // as much is guaranteed by the _constraint

            // the multiplicity inferred by looking at how many pixel can fit at the end of the scanline
            int inferredWithGap = 1; 
            if (excessPixels >= 7)
                inferredWithGap = 8;
            else if (excessPixels >= 3)
                inferredWithGap = 4;
            else if (excessPixels >= 1)
                inferredWithGap = 2;

            // the multiplicity inferred by looking at width divisibility
            // Slight note: this is not fully complete, a 2-width + 2 trailing pixels => 4-multiplicity
            int inferredWithWidth = 1;
            if ( (width % 2) == 0) inferredWithWidth = 2;
            if ( (width % 4) == 0) inferredWithWidth = 4;
            if ( (width % 8) == 0) inferredWithWidth = 8;

            // take max
            if (multi < inferredWithGap)   multi = inferredWithGap;
            if (multi < inferredWithWidth) multi = inferredWithWidth;
            assert(multi == 1 || multi == 2 || multi == 4 || multi == 8);

            if (multi == 8)
                c |= LAYOUT_MULTIPLICITY_8;
            else if (multi == 4)
                c |= LAYOUT_MULTIPLICITY_4;
            else if (multi == 2)
                c |= LAYOUT_MULTIPLICITY_2;
        }

        // Trailing bytes constraint: infer is the largest, no need to look at _layoutConstraints.
        {
            if (excessPixels >= 7)
                c |= LAYOUT_TRAILING_7;
            else if (excessPixels >= 3)
                c |= LAYOUT_TRAILING_3;
            else if (excessPixels >= 1)
                c |= LAYOUT_TRAILING_1;
        }

        // scanline alignment: infer is the largest, since the constraints shows in pitch and pointer address
        {
            LayoutConstraints firstScanAlign = getPointerAlignment(cast(size_t)_data);
            LayoutConstraints pitchAlign = getPointerAlignment(cast(size_t)absPitch);
            LayoutConstraints allScanlinesAlign = firstScanAlign < pitchAlign ? firstScanAlign : pitchAlign;
            c |= allScanlinesAlign;
        }

        // vertical
        if (pitch >= 0)
            c |= LAYOUT_VERT_STRAIGHT;
        if (pitch <= 0)
            c |= LAYOUT_VERT_FLIPPED;

        // gapless
        if (pitch == absPitch)
            c |= LAYOUT_GAPLESS;

        // TODO: do not infer LAYOUT_GAPLESS if there are multiple layers, 
        // that have no adequate layer offsets.
        // Semantic of LAYOUT_GAPLESS and allPixelsAtOnce need to be adapted

        // Border constraint: can only trust the _constraint. Cannot infer more.
        c |= (_layoutConstraints & LAYOUT_BORDER_MASK);

        return c;
    }
}


private:

// FUTURE: this will also manage color conversion.
PixelType intermediateConversionType(PixelType srcType, PixelType destType)
{
    if (pixelTypeExpressibleInRGBA8(srcType) && pixelTypeExpressibleInRGBA8(destType))
        return PixelType.rgba8;

    return PixelType.rgbaf32;
}

// This converts scanline per scanline, using an intermediate format to lessen the number of conversions.
bool convertScanlines(PixelType srcType, const(ubyte)* src, int srcPitch, 
                      PixelType destType, ubyte* dest, int destPitch,
                      int width, int height,
                      PixelType interType, ubyte* interBuf) @system
{
    assert(srcType != destType);
    assert(srcType != PixelType.unknown && destType != PixelType.unknown);

    if (pixelTypeIsPlanar(srcType) || pixelTypeIsPlanar(destType))
        return false; // No support
    if (pixelTypeIsCompressed(srcType) || pixelTypeIsCompressed(destType))
        return false; // No support

    if (srcType == interType)
    {
        // Source type is already in the intermediate type format.
        // Do not use the interbuf.
        for (int y = 0; y < height; ++y)
        {
            convertFromIntermediate(srcType, src, destType, dest, width);
            src += srcPitch;
            dest += destPitch;
        }
    }
    else if (destType == interType)
    {
        // Destination type is the intermediate type.
        // Do not use the interbuf.
        for (int y = 0; y < height; ++y)
        {
            convertToIntermediateScanline(srcType, src, destType, dest, width);
            src += srcPitch;
            dest += destPitch;
        }
    }
    else
    {
        // For each scanline
        for (int y = 0; y < height; ++y)
        {
            convertToIntermediateScanline(srcType, src, interType, interBuf, width);
            convertFromIntermediate(interType, interBuf, destType, dest, width);
            src += srcPitch;
            dest += destPitch;
        }
    }
    return true;
}

// This copy scanline per scanline of the same type
bool copyScanlines(PixelType type, 
                   const(ubyte)* src, int srcPitch, 
                   ubyte* dest, int destPitch,
                   int width, int height) @system
{
    if (pixelTypeIsPlanar(type))
        return false; // No support
    if (pixelTypeIsCompressed(type))
        return false; // No support

    int scanlineBytes = pixelTypeSize(type) * width;
    for (int y = 0; y < height; ++y)
    {
        dest[0..scanlineBytes] = src[0..scanlineBytes];
        src += srcPitch;
        dest += destPitch;
    }
    return true;
}


/// See_also: OpenGL ES specification 2.3.5.1 and 2.3.5.2 for details about converting from 
/// floating-point to integers, and the other way around.
void convertToIntermediateScanline(PixelType srcType, 
                                   const(ubyte)* src, 
                                   PixelType dstType, 
                                   ubyte* dest, int width) @system
{
    if (dstType == PixelType.rgba8)
    {
        switch(srcType) with (PixelType)
        {
            case l8:      scanline_convert_l8_to_rgba8    (src, dest, width); break;
            case la8:     scanline_convert_la8_to_rgba8   (src, dest, width); break;
            case rgb8:    scanline_convert_rgb8_to_rgba8  (src, dest, width); break;
            case rgba8:   scanline_convert_rgba8_to_rgba8 (src, dest, width); break;
            default:
                assert(false); // should not use rgba8 as intermediate type
        }
    }
    else if (dstType == PixelType.rgbaf32)
    {
        final switch(srcType) with (PixelType)
        {
            case unknown: assert(false);
            case l8:      scanline_convert_l8_to_rgbaf32     (src, dest, width); break;
            case l16:     scanline_convert_l16_to_rgbaf32    (src, dest, width); break;
            case lf32:    scanline_convert_lf32_to_rgbaf32   (src, dest, width); break;
            case la8:     scanline_convert_la8_to_rgbaf32    (src, dest, width); break;
            case la16:    scanline_convert_la16_to_rgbaf32   (src, dest, width); break;
            case laf32:   scanline_convert_laf32_to_rgbaf32  (src, dest, width); break;
            case rgb8:    scanline_convert_rgb8_to_rgbaf32   (src, dest, width); break;
            case rgb16:   scanline_convert_rgb16_to_rgbaf32  (src, dest, width); break;
            case rgbf32:  scanline_convert_rgbf32_to_rgbaf32 (src, dest, width); break;
            case rgba8:   scanline_convert_rgba8_to_rgbaf32  (src, dest, width); break;
            case rgba16:  scanline_convert_rgba16_to_rgbaf32 (src, dest, width); break;
            case rgbaf32: scanline_convert_rgbaf32_to_rgbaf32(src, dest, width); break;
        }
    }
    else
        assert(false);
}

void convertFromIntermediate(PixelType srcType, const(ubyte)* src, PixelType dstType, ubyte* dest, int width) @system
{
    if (srcType == PixelType.rgba8)
    {
        alias inp = src;
        switch(dstType) with (PixelType)
        {
            case l8:      scanline_convert_rgba8_to_l8    (src, dest, width); break;
            case la8:     scanline_convert_rgba8_to_la8   (src, dest, width); break;
            case rgb8:    scanline_convert_rgba8_to_rgb8  (src, dest, width); break;
            case rgba8:   scanline_convert_rgba8_to_rgba8 (src, dest, width); break;
            default:
                assert(false); // should not use rgba8 as intermediate type
        }
    }
    else if (srcType == PixelType.rgbaf32)
    {    
        const(float)* inp = cast(const(float)*) src;
        final switch(dstType) with (PixelType)
        {
            case unknown: assert(false);
            case l8:      scanline_convert_rgbaf32_to_l8     (src, dest, width); break;
            case l16:     scanline_convert_rgbaf32_to_l16    (src, dest, width); break;
            case lf32:    scanline_convert_rgbaf32_to_lf32   (src, dest, width); break;
            case la8:     scanline_convert_rgbaf32_to_la8    (src, dest, width); break;
            case la16:    scanline_convert_rgbaf32_to_la16   (src, dest, width); break;
            case laf32:   scanline_convert_rgbaf32_to_laf32  (src, dest, width); break;
            case rgb8:    scanline_convert_rgbaf32_to_rgb8   (src, dest, width); break;
            case rgb16:   scanline_convert_rgbaf32_to_rgb16  (src, dest, width); break;
            case rgbf32:  scanline_convert_rgbaf32_to_rgbf32 (src, dest, width); break;
            case rgba8:   scanline_convert_rgbaf32_to_rgba8  (src, dest, width); break;
            case rgba16:  scanline_convert_rgbaf32_to_rgba16 (src, dest, width); break;
            case rgbaf32: scanline_convert_rgbaf32_to_rgbaf32(src, dest, width); break;
        }
    }
    else
        assert(false);
}


// Test gapless pixel access
unittest
{
    Image image;
    image.setSize(16, 16, PixelType.rgba8, LAYOUT_GAPLESS | LAYOUT_VERT_STRAIGHT);
    assert(image.isGapless);

    ubyte[] all = image.allPixelsAtOnce();
    assert(all !is null);
}

// Semantics for image without pixel data type.
// You can do very little with it apart from calling an initializing function.
unittest
{
    Image image;

    // An image that is uninitialized has no pixel type, and is in error state.
    assert(image.type() == PixelType.unknown);
    assert(!image.isValid());
    assert(image.isError());

    // You can load an image. If it fails, it will have no type.
    image.loadFromFile("unkonwn-special-file");
    assert(!image.isValid());
    assert(image.isError());
}

// Semantics for image without data (but with a type).
unittest
{
    Image image;
    image.createWithNoData(450, 614, PixelType.rgba8);
    assert(!image.hasData());
    assert(!image.isOwned());
    assert(image.isValid());
    assert(image.width == 450);
    assert(image.height == 614);
    assert(!image.isError());
    assert(!image.hasData());
    assert(image.isPlainPixels());
    assert(!image.isPlanar());
    assert(!image.isCompressed());
    assert(image.hasNonZeroSize());
}

// Semantics for image with plain pixels
unittest
{
    Image image;
    image.createNoInit(3, 5, PixelType.rgba8);
    assert(image.isValid());
    assert(image.isOwned());
    assert(image.width == 3);
    assert(image.height == 5);
    assert(image.isValid());
    assert(!image.isError());
    assert(image.hasData());
    assert(image.isPlainPixels());
    assert(!image.isPlanar());
    assert(!image.isCompressed());
    assert(image.hasNonZeroSize());
    image.convertTo16Bit();
    Image B = image.clone();
}

// Semantics for zero initialization
 @trusted unittest
{
    // Create with initialization and a border. Every pixel should be zero, including border.
    Image image;

    image.create(5, 4, PixelType.l8, LAYOUT_BORDER_3 | LAYOUT_GAPLESS); // impossible layout
    assert(image.isError());

    image.create(5, 4, PixelType.l8, LAYOUT_BORDER_3); // can create image with border
    for (int y = -3; y < 4 + 3; ++y)
    {
        ubyte* scan = cast(ubyte*) image.scanline(y);
        for (int x = -3; x < 5 + 3; ++x)
        {
            assert(scan[x] == 0);
        }
    }
}

// Semantics for image with plain pixels, but with zero width and height.
// Basically all operations are available to it.
unittest
{
    Image image;
    image.setSize(0, 0, PixelType.rgba8);

    static void zeroSizeChecks(ref Image image) @safe
    {
        assert(image.isValid());
        assert(image.isOwned());
        assert(image.layers == 1);
        assert(image.layerOffsetInBytes() == 0);
        assert(image.width == 0);
        assert(image.height == 0);
        assert(!image.isError());
        assert(image.hasData()); // It has data, just, it has a zero size.
        assert(image.isPlainPixels());
        assert(!image.isPlanar());
        assert(!image.isCompressed()); 
        assert(!image.hasNonZeroSize());
    }
    zeroSizeChecks(image);
    image.convertTo16Bit();    
    zeroSizeChecks(image);
    Image B = image.clone();
    zeroSizeChecks(B);
}

@trusted unittest
{
    ushort[4][3] pixels = 
    [ [ 5, 5, 5, 5],
      [ 5, 6, 5, 5],
      [ 5, 5, 5, 7] ];
    Image image;
    int width = 4;
    int height = 3;
    int pitch = width * cast(int)ushort.sizeof; 
    image.createViewFromData(&pixels[0][0], width, height, PixelType.l16, pitch);
    assert(!image.isError);
    ushort* l0 = cast(ushort*) image.scanline(0);
    ushort* l1 = cast(ushort*) image.scanline(1);
    ushort* l2 = cast(ushort*) image.scanline(2);
    assert(l0[0..4] == [5, 5, 5, 5]);
    assert(l1[1] == 6);
    assert(l2[0..4] == [5, 5, 5, 7]);

    // Upside down data
    image.createViewFromData(&pixels[2][0], width, height, PixelType.l16, -pitch);
    assert(!image.isError);

    // Overlapping scanlines is illegal
    image.createViewFromData(&pixels[0][0], width, height, PixelType.l16, pitch-1);
    assert(image.isError);
}

// Test encodings
@trusted unittest 
{
    ubyte[3][3] pixels = 
    [ [ 255, 0, 0],
      [ 15, 64, 255],
      [ 0, 255, 255] ];

    Image image;
    int width = 3;
    int height = 1;
    int pitch = 3 * 3; /* whatever */
    image.createViewFromData(&pixels[0][0], width, height, PixelType.rgb8, pitch);
    assert(!image.isError);

    void checkEncode(const(ubyte)[] encoded, bool lossless) nothrow @trusted
    {
        assert(encoded !is null);
        Image image;
        image.loadFromMemory(encoded);
        image.convertTo(PixelType.rgb8);
        assert(!image.isError);
        assert(image.layers == 1);
        assert(image.width == 3);
        assert(image.height == 1);

        ubyte* l0 = cast(ubyte*) image.scanptr(0);
        if (lossless) 
        {
            assert(l0[0..9] == [255, 0, 0, 15, 64, 255, 0, 255, 255]);
        }

        ubyte[] wl0 = cast(ubyte[]) image.scanline(0);
        if (lossless) 
        {
            assert(wl0 == [255, 0, 0, 15, 64, 255, 0, 255, 255]);
        }
    }

    version(encodePNG)
    {
        ubyte[] png = image.saveToMemory(ImageFormat.PNG);
        version(decodePNG) checkEncode(png, true);
        freeEncodedImage(png);
    }
    version(encodeJPEG)
    {
        ubyte[] jpeg = image.saveToMemory(ImageFormat.JPEG);
        version(decodeJPEG) checkEncode(jpeg, false);
        freeEncodedImage(jpeg);
    }
    version(encodeQOI)
    {
        ubyte[] qoi = image.saveToMemory(ImageFormat.QOI);
        version(decodeQOI) checkEncode(qoi, true);
        freeEncodedImage(qoi);
    }

    version(encodeQOIX)
    {
        ubyte[] qoix = image.saveToMemory(ImageFormat.QOIX);
        version(decodeQOIX) checkEncode(qoix, true);
        freeEncodedImage(qoix);
    }

   version(encodeTGA)
    {
        ubyte[] tga = image.saveToMemory(ImageFormat.TGA);
        version(decodeTGA) checkEncode(tga, true);
        freeEncodedImage(tga);
    }
}

// Layered images, semantics test.
unittest
{
    Image image;

    // Uninitialized image has 0 layers.
    assert(image.layers == 0);
    assert(image.layerOffsetInBytes() == 0);

    // Create a black 5-layers, 640x480 image with default pixel format.
    image.createLayered(5, 640, 480); 
    assert(image.layers == 5);
    assert(image.width == 640);
    assert(image.height == 480);
    import std.stdio;
    debug writeln("a");
    assert(image.hasMultipleLayers);
    debug writeln("b");
    assert(image.hasNonZeroSize);
    debug writeln("c");
    assert(image.layerOffsetInBytes() > 0);
    debug writeln("d");

    // Possible to create a zero-layer image.
    image.createLayered(0, 1, 1); 
    assert(image.layers == 0);
    assert(!image.hasMultipleLayers);
    assert(!image.hasMultipleLayers);
    assert(image.hasZeroLayer);
    assert(!image.hasSingleLayer);
    assert(!image.hasNonZeroSize);
    assert(image.layerOffsetInBytes() == 0);

    // Create an uninitialized 5-layers, 640x480 image with default pixel 
    image.createLayeredNoInit(5, 640, 480);
    assert(image.layers == 5);
    assert(image.width == 640);
    assert(image.height == 480);
    assert(image.layerOffsetInBytes() > 0);

    // Create a no-data 5-layers, 640x480 image with default pixel 
    image.createLayeredWithNoData(5, 640, 480);
    assert(image.layers == 5);
    assert(image.width == 640);
    assert(image.height == 480);
    assert(image.hasMultipleLayers);
    assert(!image.hasZeroLayer);
    assert(!image.hasSingleLayer);
    assert(image.layerOffsetInBytes() == 0);
}
