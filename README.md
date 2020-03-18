# audio-formats
Audio format loading for D.

Can decode WAV / MP3 / FLAC from a file or memory.
Can encode WAV to a file or to memory.

It is a replacement for the `wave-d` package but with more formats, `nothrow @nogc` and chunk support.

# API

See `examples/transode/main.d`.


# File format support

|       | Decoding   | Encoding |
|-------|------------|----------|
| WAV   | Yes        | Yes      |
| MP3   | Yes (LGPL) | No       |
| FLAC  | Yes        | No       |

**All of this wouldn't be possible without the hard work of Ketmar.** This library is merely a repackaging.


# License

- LGPL v2.1 with MP3 decoding.
- Boost license otherwise.
(use DUB subconfigurations) to choose.