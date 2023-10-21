# Gamut

Gamut (DUB package: `gamut`) is an image decoding/encoding library for D.

It's design is inspired by the FreeImage design, where the Image concept is monomorphic and can do it all.

Gamut tries to have the fastest and most memory-conscious image decoders available in pure D code.
It is `nothrow @nogc @safe` for usage in -betterC and in disabled-runtime D.


## Decoding

- PNG: 8-bit and 16-bit, L/LA/RGB/RGBA
- JPEG: 8-bit, L/RGB/RGBA, baseline and progressive
- TGA: 8-bit, indexed, L/LA/RGB/RGBA
- GIF: 8-bit, RGBA **WIP**
- QOI: 8-bit, RGB/RGBA
- QOIX: 8-bit, 10-bit, L/LA/RGB/RGBA. _Improvement upon QOI. This format may change between major Gamut tags, so is not a storage format._

## Encoding

- PNG. 8-bit, 16-bit, L/LA/RGB/RGBA
- JPEG: 8-bit, greyscale/RGB, baseline
- TGA: 8-bit, RGB/RGBA
- GIF: 8-bit, RGBA
- QOI: 8-bit, RGB/RGBA
- QOIX: 8-bit, 10-bit, L/LA/RGB/RGBA
- DDS: BC7 encoded, 8-bit, RGB/RGBA



## Changelog

- **v2.2.y** Added 16-bit PNG output.
- **v2.1.y** Added TGA format support.
- **v2.x.y** QOIX bitstream changed. Ways to disown and deallocate image allocation pointer. It's safe to update to latest tag in the same major version. Do keep a 16-bit source in case the bitstream changes.
- **v1.x.y** Initial release.

## Why QOIX?

Our benchmark results for 8-bit color images:

| Codec | decode mpps | encode mpps | bit-per-pixel |
|-------|-------------|-------------|---------------|
| PNG (stb) | 89.73   | 14.34       | 10.29693      |
| QOI   | 201.9       | 150.8       | 10.35162      |
| QOIX  | 179.0       | 125.0       | 7.93607       |


- QOIX and QOI generally outperforms PNG in decoding speed and encoding speed.
- QOIX outperforms QOI in compression efficiency at the cost of speed:
  * because it's based upon better intra predictors
  * because it is followed by LZ4, which removes some of the QOI worst cases.
- QOIX adds support for 8-bit greyscale and greyscale + alpha images, with a "QOI-plane" custom codec.
- QOIX adds support for 10-bit images, with a "QOI-10b" custom codec. It drops the last 6 bits of precision (lossy) to outperform PNG 16-bit in every way for some use cases.


&nbsp;


----


&nbsp;



# Gamut API documentation

## 1. `Image` basics

> **Key concept:**
> The `Image` struct is where most of the public API resides.

### **1.1 Get the dimensions of an image:**
  ```d
  Image image = Image(800, 600);
  int w = image.width();
  int h = image.height();
  assert(w == 800 && h == 600);
  ```

### **1.2 Get the pixel format of an image:**
  ```d
  Image image = Image(800, 600);
  PixelType type = image.type();
  assert(type == PixelType.rgba8); // rgba8 is default if not provided
  ```

  > **Key concept:** `PixelType` completely describes the pixel format, for example `PixelType.rgb8` is a 24-bit format with one byte for red, green and blue components each (in that order). Nothing is specified about the color space though.

  Here are the possible `PixelType`:


  ```d
  enum PixelType
  {
      l8,
      l16,
      lf32,
      la8,
      la16,
      laf32,
      rgb8, 
      rgb16,
      rgbf32,
      rgba8,
      rgba16,
      rgbaf32
  }
  ```

  For now, all pixels format have one to four components:
  - 1 component is implicitely Greyscale
  - 2 components is implicitely Greyscale + alpha
  - 3 components is implicitely Red + Green + Blue
  - 4 components is implicitely Red + Green + Blue + Alpha

  _**Bit-depth:** Each of these components can be represented in 8-bit, 16-bit, or 32-bit floating-point (0.0f to 1.0f range)._



### **1.3 Create an image:**

> Different ways to create an `Image`:
> - `create()` or regular constructor `this()` creates a new owned image filled with zeros.
> - `createNoInit()` or `setSize()` creates a new owned uninitialized image.
> - `createViewFromData()` creates a view into existing data.
> - `createNoData()` creates a new image with no data pointed to (still has a type, size...).

  ```d
  // Create with zero initialization.
  Image image = Image(640, 480, PixelType.rgba8); 
  image.create(640, 480, PixelType.rgba8);

  // Create with no initialization.
  image.setSize(640, 480, PixelType.rgba8);
  image.createNoInit(640, 480, PixelType.rgba8);

  // Create view into existing data.
  image.createViewFromData(data.ptr, w, h, PixelType.rgb8, pitchbytes);
  ```

 - At creation time, the `Image` forgets about its former life, and leaves any `isError()` state or former data/type
 - `Image.init` is in `isError()` state
 - `isValid()` can be used instead of `!isError()`
 - Being valid == not being error == having a `PixelType`


&nbsp;


----


&nbsp;


## 2. Loading and saving an image

### **2.1 Load an `Image` from a file:**

Another way to create an `Image` is to load an encoded image.

  ```d
  Image image;
  image.loadFromFile("logo.png");
  if (image.isError)
      throw new Exception(image.errorMessage);
  ```

  You can then read `width()`, `height()`, `type()`, etc...

  > **There is no exceptions in Gamut.** Instead the Image itself has an error API:
  > - `bool isError()` return `true` if the `Image` is in an error state. In an error state, the image can't be used anymore until recreated (for example, loading another file).
  > - `const(char)[] errorMessage()` is then available, and is guaranteed to be zero-terminated with an extra byte.


### **2.2 Load an image from memory:**
  ```d
  auto pngBytes = cast(const(ubyte)[]) import("logo.png"); 
  Image image;
  image.loadFromMemory(pngBytes);
  if (!image.isValid) 
      throw new Exception(image.errorMessage());
  ```
  > **Key concept:** You can force the loaded image to be a certain type using `LoadFlags`.

  Here are the possible `LoadFlags`:
  ```d
  LOAD_NORMAL      // Default: preserve type from original.
  
  LOAD_ALPHA       // Force one alpha channel.
  LOAD_NO_ALPHA    // Force zero alpha channel.
  
  LOAD_GREYSCALE   // Force greyscale.
  LOAD_RGB         // Force RGB values.
  
  LOAD_8BIT        // Force 8-bit `ubyte` per component.
  LOAD_16BIT       // Force 16-bit `ushort` per component.
  LOAD_FP32        // Force 32-bit `float` per component.
  ```

  Example:
  ```d
  Image image;  
  image.loadFromMemory(pngBytes, LOAD_RGB | LOAD_ALPHA | LOAD_8BIT);  // force PixelType.rgba8 
  ```
  Not all load flags are compatible, for example `LOAD_8BIT` and `LOAD_16BIT` cannot be used together.
    

### **2.3 Save an image to a file:**

  ```d
  Image image;
  if (!image.saveToFile("output.png"))
      throw new Exception("Writing output.png failed");
  ```

  > **Key concept:** `ImageFormat` is simply the codecs/containers files Gamut encode and decodes to.

  ```d
  enum ImageFormat
  {
      unknown,
      JPEG,
      PNG,
      QOI,
      QOIX,
      DDS,
      TGA,
      GIF
  }
  ```

  This can be used to avoid inferring the output format from the filename:
  ```d
  Image image;
  if (!image.saveToFile(ImageFormat.PNG, "output.png"))
      throw new Exception("Writing output.png failed");
  ```

### **2.4 Save an image to memory:**

  ```d
  Image image;
  ubyte[] qoixEncoded = image.saveToMemory(ImageFormat.QOIX);
  scope(exit) freeEncodedImage(qoixEncoded);
  ```

  The returned slice must be freed up with `freeEncodedImage`.


&nbsp;


----


&nbsp;


## 3. Accessing image pixels

### **3.1 Get the row pitch, in bytes:**
  ```d
  int pitch = image.pitchInBytes();
  ```

  > **Key concept:** The image `pitch` is the distance between the start of two consecutive scanlines, in bytes.
  **IMPORTANT: This pitch can be negative.**

### **3.2 Access a row of pixels:**
  ```d
  void* scan = image.scanptr(y);  // get pointer to start of pixel row
  void[] row = image.scanline(y); // get slice of pixel row
  ```
  > **Key concept:** The scanline is `void*` because the type it points to depends upon the `PixelType`. In a given scanline, the bytes `scan[0..abs(pitchInBytes())]` are all accessible, even if they may be outside of the image (trailing pixels, gap bytes for alignment, border pixels).


### **3.3 Iterate on pixels:**
  ```d
  assert(image.type == PixelType.rgba16);
  assert(image.hasData());
  for (int y = 0; y < image.height(); ++y)
  {
      ushort* scan = cast(ushort*) image.scanptr(y);
      for (int x = 0; x < image.width(); ++x)
      {
          ushort r = scan[4*x + 0];
          ushort g = scan[4*x + 1];
          ushort b = scan[4*x + 2];
          ushort a = scan[4*x + 3];
      }
  }
  ```
  > **Key concept:** The default is that you do not access pixels in a contiguous manner. See 4. for layout constraints that allow you to get all pixels at once.


&nbsp;


----


&nbsp;



## 4. Layout constraints

One of the most interesting feature of Gamut!
Images in Gamut can follow given constraints over the data layout.  

  > **Key concept:** `LayoutConstraint` are carried by images all their life.

Example:

  ```d
  // Do nothing in particular.
  LayoutConstraint constraints = LAYOUT_DEFAULT; // 0 = default

  // Layout can be given directly at image creation or afterwards.
  Image image;  
  image.loadFromMemory(pngBytes, constraints); 

  // Now the image has a 1 pixel border (at least).
  // Changing the layout only reallocates if needed.
  image.setLayout(LAYOUT_BORDER_1);
  
  // Those layout constraints are preserved.
  // (but: not the excess bytes content, if reallocated)
  image.convertToGreyscale();
  assert(image.layoutConstraints() == LAYOUT_BORDER_1);   
  ```

**Important:** Layout constraints are about the minimum guarantee you want. Your image may be _more_ constrained than that in practice, but you can't rely on that.   
- If you don't specify `LAYOUT_VERT_STRAIGHT`, you should expect your image to be possibly stored upside-down, and account for that possibility.
- If you don't specify `LAYOUT_SCANLINE_ALIGNED_16`, you should not expect your scanlines to be aligned on 16-byte boundaries, even though that can happen accidentally.


Beware not to accidentally reset constraints when resizing:
```d
// If you do not provide layout constraints, 
// the one choosen is 0, the most permissive.
image.setSize(640, 480, PixelType.rgba8, LAYOUT_TRAILING_3);
```


### 4.1 Scanline alignment
    
  > **Scanline alignment** guarantees minimum alignment of each scanline.

```d
LAYOUT_SCANLINE_ALIGNED_1 = 0
LAYOUT_SCANLINE_ALIGNED_2
LAYOUT_SCANLINE_ALIGNED_4
LAYOUT_SCANLINE_ALIGNED_8
LAYOUT_SCANLINE_ALIGNED_16
LAYOUT_SCANLINE_ALIGNED_32
LAYOUT_SCANLINE_ALIGNED_64
LAYOUT_SCANLINE_ALIGNED_128
```

### 4.2 Layout multiplicity  

> **Multiplicity** guarantees access to pixels 1, 2, 4 or 8 at a time. It does this with excess pixels at the end of the scanline, but they need not exist if the scanline has the right width.

```d
LAYOUT_MULTIPLICITY_1 = 0
LAYOUT_MULTIPLICITY_2
LAYOUT_MULTIPLICITY_4
LAYOUT_MULTIPLICITY_8
```
Together with scanline alignment, this allow processing a scanline using aligned SIMD without processing the last few pixels differently.
     

### 4.3 Trailing pixels

> **Trailing pixels** gives you up to 7 excess pixels after each scanline. 
```d
LAYOUT_TRAILING_0 = 0
LAYOUT_TRAILING_1
LAYOUT_TRAILING_3
LAYOUT_TRAILING_7
```

Allows unaligned SIMD access by itself.

### 4.4 Pixel border

> **Border** gives you up to 3 excess pixels around an image, eg. for filtering.
```d
LAYOUT_BORDER_0 = 0
LAYOUT_BORDER_1
LAYOUT_BORDER_2
LAYOUT_BORDER_3
```

### 4.5 Forcing pixels to be upside down or straight
> **Vertical** constraint forces the image to be stored in a certain vertical direction (by default: any).
```d
LAYOUT_VERT_FLIPPED
LAYOUT_VERT_STRAIGHT
```


### 4.6 Gapless pixel access
> The **Gapless** constraint force the image to have contiguous scanlines without excess bytes.
```d
LAYOUT_GAPLESS
```

If you have both `LAYOUT_GAPLESS` and `LAYOUT_VERT_STRAIGHT`, then you can access a slice of all pixels at once, with the `ubyte[] allPixelsAtOnce()` method.

  ```d
  image.setSize(640, 480, PixelType.rgba8, LAYOUT_GAPLESS | LAYOUT_VERT_STRAIGHT);
  ubyte[] allpixels = image.allPixelsAtOnce(y);
  ```

`LAYOUT_GAPLESS` is incompatible with constraints that needs excess bytes, like borders, scanline alignment, trailing pixels...


&nbsp;


----


&nbsp;



## 5. Geometric transforms

Gamut provides a few geometric transforms.

```d
Image image;
image.flipHorizontal(); // Flip image pixels horizontally.
image.flipVertical();   // Flip image vertically (pixels or logically, depending on layout)
```


&nbsp;


----


&nbsp;


## 6. Multi-layer images

### 6.1 Create multi-layer images

All `Image` have a number of layers.
```d
Image image;
image.create(640 ,480);
assert(image.layers == 1); // typical image has one layer
assert(image.hasOneLayer);
```

- Create a multi-layer image, cleared with zeroes:
```d
// This single image has 24 black layers.
image.createLayered(800, 600, 24); 
assert(image.layers == 24);
```
- Create a multi-layer uninitialized image:
```d
// Make space for 24 800x600 rgba8 different images.
image.createLayeredNoInit(800, 600, 24);
assert(image.layers == 24);
```

- Create a multi-layer as a view into existing data:
```d
// Create view into existing data.
// layerOffsetBytes is byte offset between first scanlines 
// of two consecutive layers.
image.createLayeredViewFromData(data.ptr, 
                                w, h, numLaters, 
                                PixelType.rgb8, 
                                pitchbytes,
                                layerOffsetBytes);
```

> Gamut **Image** is secretly similar to 2D Array Texture in OpenGL. Each layer is store consecutively in memory.


### 6.2 Get individual layer

`image.layer(int index)` return non-owning view of a single-layer.

```d
Image image;
image.create(640, 480, 5);
assert(image.layer(4).width  == 640);
assert(image.layer(4).height == 480);
assert(image.layer(4).layers ==   1);
```

> **Key concept:** All image operations work on all layers by default. 


> **Regarding layout:** Each layer has its own border, trailing bytes... and follow the same layout constraints. Moreover, `LAYOUT_GAPLESS` also constrain the layers to be immediately next in memory, without any byte (like it constrain the scanlines). The layers **cannot** be stored in reverse order.


### 6.2 Get sub-range of layers

`image.layerRange(int start, int stop)` return non-owning view of a several layers.




### 6.3 Access layer pixels

- Get a pointer to a scanline: 

```d
// Get the 160th scanline of layer 2.
void* scan = image.layerptr(2, 160);
```

- Get a slice of a whole scanline: 

```d
// Get the 160th scanline of layer 2.
void[] line = image.layerline(2, 160);
```

Actually, `scanptr(y)` and `scanline(y)` only access the layer index 0.
```d
// Get the 160th scanline of layer 0.
void* scan = image.scanptr(160);
void[] line = image.scanline(160);
```

>  **Key concept:** First layer has index 0.

Consequently, there are two ways to access pixel data in `Image`:

```d
// Two different ways to access layer pixels.
assert(image.layer(2).scanline(160) == image.layerline(2, 160)
```
> **The calls*:* 
>  - `image.layerptr(layer, y)`
>  - `image.layerline(layer, y)`
>
> _are like:_
>
> - `image.scanptr(y)`
> - `image.scanline(y)`
>
> _but take a **layer index**._
 