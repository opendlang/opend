## Differences from original FreeImage

- Files of size larger than 2^31-1 bytes are not supported.
- Unlike in FreeImage, scan lines in FIBITMAP are not aligned to 32-bit boundaries.
- `FreeImage_GetLine` returns a signed number of bytes.
- `FreeImage_GetPitch` returns a signed number of bytes.
- Some of the "controversial" names as signalled by documentation were replaced by more explicit names.
  The old names are still supported but under a `deprecated alias`.
- The FIT_LA16 type: one channel of luminance, one channel of alpha.
- Bitmaps are NOT stored upside-down.