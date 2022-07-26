# gamut

`gamut` is an image decoding/encoding library for D.

It's design is inspired by the FreeImage design, where the Image concept is monomorphic and can do it all.

`gamut` tries to have the fastest and most memory-conscious image decoders available in pure D code.
It is `nothrow @nogc @safe` for usage in -betterC and in disabled-runtime D.


## Decoding

- PNG: 8-bit and 16-bit, L/LA/RGB/RGBA
- JPEG: 8-bit, L/RGB/RGBA, baseline and progressive
- QOI: 8-bit, RGB/RGBA
- QOIX: 8-bit, L/LA/RGB/RGBA. _This is an evolving format, specific to Gamut, that embeds some developments in the QOI family of formats._

## Encoding

- PNG. 8-bit, RGB/RGBA
- JPEG: 8-bit, greyscale/RGB, baseline
- QOI: 8-bit, RGB/RGBA
- QOIX: 8-bit, L/LA/RGB/RGBA
- DDS: BC7 encoded, 8-bit, RGB/RGBA


## Why QOIX?

Our benchmark results:

| Codec | decode mpps | encode mpps | bit-per-pixel |
|-------|-------------|-------------|---------------|
| QOI   | 177.5       | 103.35      | 8.30963       |
| QOIX  | 204.70      | 150.42      | 10.35162      |


- QOIX and QOI generally outperforms PNG in decoding speed and encoding speed.
- QOIX outperform QOI in compression efficiency at the cost of speed:
  * because it's based upon qoi2avg, a better QOI variant for RGB and RGBA images
  * because it is followed by LZ4, which removes some of the QOI worst cases.
- Unlike QOI, QOIX has support for 8-bit greyscale and greyscale + alpha images, with a "QOI-plane" custom codec.


