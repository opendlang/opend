# gamut

`gamut` is an image decoding/encoding library for D.

It's design is inspired by the FreeImage design, where the Image concept is monomorphic and can do it all.

`gamut` tries to have the fastest and most memory-conscious image decoders available in pure D code.
It is `nothrow @nogc @safe` for usage in -betterC and in disabled-runtime D.


## Decoding

- PNG: 8-bit and 16-bit, greyscale/LA/RGB/RGBA
- JPEG: 8-bit, greyscale/RGB/RGBA, baseline and progressive
- QOI: 8-bit, RGB/RGBA


## Encoding

- PNG. 8-bit, RGB/RGBA
- JPEG: 8-bit, greyscale/RGB, baseline
- QOI: 8-bit, RGB/RGBA


## Why?

FreeImage API is good and covers most use cases.
`easy.d` provides a wrapper around FIBITMAP to ease the API further.
A pure D library simplifies your build.
