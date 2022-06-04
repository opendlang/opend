# gamut

`gamut` is a partial re-implementation of FreeImage in D.
It recreates the library through its documentation (FreeImage3180.pdf).

`gamut` tries to have the fastest and most memory-conscious image decoders available in pure D code.
It is `nothrow @nogc @safe` for usage in -betterC and in disabled-runtime D.

Like FreeImage, it is based around a monomorphic image type, that can do it all.

## Status

- [x] Read 8-bit PNG 
- [x] Read 16-bit PNG
- [x] Write 8-bit PNG
- [ ] Read 8-bit JPEG (no grayscale yet)
- [ ] Read / Write QOI
- [ ] Paletted loading


## Why?

and all design decisions have already been made.
`easy.d` provides a wrapper around FIBITMAP to ease the API further.
