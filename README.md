# gamut

`gamut` is an image decoding/encoding library for D.

It is a very partial re-implementation of FreeImage in D, recreating it from its documentation (FreeImage3180.pdf).

`gamut` tries to have the fastest and most memory-conscious image decoders available in pure D code.
It is `nothrow @nogc @safe` for usage in -betterC and in disabled-runtime D.

Like FreeImage, it is based around a monomorphic image type, that can do it all.

## Decoding

- PNG: 8-bit and 16-bit, greyscale/LA/RGB/RGBA
- JPEG: 8-bit, greyscale/RGB/RGBA, baseline and progressive
- QOI: 8-bit, RGB/RGBA

## Encoding

- PNG. 8-bit, RGB/RGBA
- QOI: 8-bit, RGB/RGBA


## Why?

FreeImage API is good and covers most use cases.
`easy.d` provides a wrapper around FIBITMAP to ease the API further.
A pure D library simplifies your build.
