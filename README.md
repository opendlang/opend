# audio-formats
Audio format loading for D.

Can decode WAV / MP3 / FLAC / OPUS / OGG / MOD / XM from a file or memory.
Can encode WAV to a file or to memory.

It is a replacement for the `wave-d` package but with more formats, `nothrow @nogc` and chunk support.

# API

See `examples/transcode/main.d`:
https://github.com/AuburnSounds/audio-formats/blob/master/examples/transcode/source/main.d

# File format support

|       | Decoding   | Encoding |
|-------|------------|----------|
| WAV   | Yes        | Yes      |
| MP3   | Yes        | No       |
| FLAC  | Yes        | No       |
| OPUS  | Yes (LGPL) | No       |
| OGG   | Yes        | No       |
| MOD   | Yes        | No       |
| XM    | Yes        | No       |


Some of these decoders were originally translated by Ketmar, who did the heavy-lifting.


# References

- https://github.com/Zoadian/mp3decoder
- https://github.com/rombankzero/pocketmod
- https://github.com/Artefact2/libxm


# License

- Boost license otherwise.
- LGPL v2.1 with OPUS decoding.
(use DUB subconfigurations) to choose, default is boost.


# Bugs

- OGG decoding doesn't work, the sound is unusable.