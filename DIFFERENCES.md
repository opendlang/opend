## Differences from original FreeImage

- `FI_BITMAP` doesn't exist, it's all specialized formats.
   * Consequently, BPP doesn't exist either as a concept in Gamut.
   * Consequently, red/green/blue masks do not exist either.

- Lacks support for most formats.
- Add support for vanilla QOI format.


- no bitmap can have a width or height larger than 16384.
- Files of size larger than 2^31-1 bytes are not supported.
- Unlike in FreeImage, scan lines in FIBITMAP are not aligned to 32-bit boundaries.
- `FreeImage_GetLine` returns a signed number of bytes instead of unsigned.
- `FreeImage_GetPitch` returns a signed number of bytes instead of unsigned.
- Some of the "controversial" names as signalled by documentation were replaced by more explicit names.
  The old names are still supported but under a `deprecated alias`.
- The FIT_LA16 type: one channel of luminance, one channel of alpha.
- Bitmaps are NOT stored upside-down.
- Different loading flags (see `types.d`).