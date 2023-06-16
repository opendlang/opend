# Architecture

- `package.d` and `image.d` are the public API
- `codecs` contains the various raw codecs used in Gamut
- `plugins` (name came from FreeImage) bridges the Image abstraction and the codecs themselves.