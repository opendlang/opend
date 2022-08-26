# audio-formats
Audio format loading for D.

- Can decode WAV / MP3 / FLAC / OPUS / OGG / MOD / XM, from file or memory.
- Can encode WAV to a file or to memory.
- Seeking support
- `float` and `double` decoding support
- reduced bitdepth WAV encoding with dithering

This package is a replacement for the `wave-d` package but with more formats, `nothrow @nogc` and chunk support.


# Changelog

## `audio-format` v2.x.y

- **NEW** Doesn't depend upon `dplug:core` anymore.
- **BREAKING** All exceptions thrown by `audio-formats` are `AudioFormatsException`. They must be clean-up with `destroyAudioFormatException`.


# API

See `examples/transcode/main.d`:
https://github.com/AuburnSounds/audio-formats/blob/master/examples/transcode/source/main.d

# File format support

|       | Decoding   | Encoding | Seeking support |
|-------|------------|----------|-----------------|
| WAV   | Yes        | Yes      | Sample          |
| MP3   | Yes        | No       | Sample          |
| FLAC  | Yes        | No       | Sample          |
| OPUS  | Yes (LGPL) | No       | Sample          |
| OGG   | Yes        | No       | Sample          |
| MOD   | Yes        | No       | Pattern+Row     |
| XM    | Yes        | No       | Pattern+Row     |


Some of these decoders were originally translated by Ketmar, who did the heavy-lifting.


# References

- https://github.com/Zoadian/mp3decoder
- https://github.com/rombankzero/pocketmod
- https://github.com/Artefact2/libxm


# License

- Boost license otherwise.
- LGPL v2.1 with OPUS decoding.
(use DUB subconfigurations) to choose, default is boost.

# Extras
The following version identifiers can be used to enable/disable decoder level features  
| Version Identifier | Feature                                                       |
|--------------------|---------------------------------------------------------------|
| AF_LINEAR          | Use linear sampling for MOD modules instead of Amiga sampling |
|                    |                                                               |

# Bugs

- framesRemainingInPattern is unimplemented for XM currently.
