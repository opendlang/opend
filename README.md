# audio-formats
Audio format loading for D.

Can decode WAV / MP3 / FLAC / OPUS / OGG from a file or memory.
Can encode WAV to a file or to memory.

It is a replacement for the `wave-d` package but with more formats, `nothrow @nogc` and chunk support.

# API

See `examples/transcode/main.d`:
https://github.com/AuburnSounds/audio-formats/blob/master/examples/transcode/source/main.d

# File format support

|       | Decoding   | Encoding |
|-------|------------|----------|
| WAV   | Yes        | Yes      |
| MP3   | Yes (LGPL) | No       |
| FLAC  | Yes        | No       |
| OPUS  | Yes (LGPL) | No       |
| OGG   | Broken     | No       |


**All of this wouldn't be possible without the hard work of Ketmar and Zoadian.** 


# References

- https://github.com/Zoadian/mp3decoder


# License

- LGPL v2.1 with MP3 decoding.
- LGPL v2.1 with OPUS decoding.
- Boost license otherwise.
(use DUB subconfigurations) to choose.


# Bugs

- OGG decoding doesn't work, the sound is unusable.