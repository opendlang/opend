# audio-formats

`audio-formats` is meant to be the easiest package to load and write sounds in D.

## Features

- ✅ Decode from WAV / MP3 / FLAC / OPUS / OGG / MOD / XM
- ✅ Encode to WAV
- ✅ File and memory support
- ✅ Seeking support
- ✅ Chunked support
- ✅ `float` and `double` support
- ✅ WAV encoding with dithering when reducing bit-depth
- ✅ `nothrow @nogc` API
- ✅ Archs: `x86` / `x86_64` / `arm64`



## Changelog

### 🔔 `audio-formats` v2

- Doesn't depend upon `dplug:core` anymore.
- All exceptions thrown by `audio-formats` are now `AudioFormatsException`.  
  They must be clean-up with `destroyAudioFormatException`.

### 🔔 `audio-formats` v1
- Initial release.
  

## How to use it?

- Add audio-formats as dependency to your `dub.json` or `dub.sdl`.
- See the [transcode example](https://github.com/AuburnSounds/audio-formats/blob/master/examples/transcode/source/main.d) for usage.

## What formats are supported exactly?

|       | Decoding   | Encoding | Seeking support |
|-------|------------|----------|-----------------|
| 📀 WAV   | Yes        | Yes      | Sample          |
| 📀 MP3   | Yes        | No       | Sample          |
| 📀 FLAC  | Yes        | No       | Sample          |
| 📀 OPUS  | Yes (LGPL) | No       | Sample          |
| 📀 OGG   | Yes        | No       | Sample          |
| 📀 MOD   | Yes        | No       | Pattern+Row     |
| 📀 XM    | Yes        | No       | Pattern+Row     |


_Some of these decoders were originally translated by Ketmar, who did the heavy-lifting._


## License 

- ⚖️ Boost license otherwise.
- ⚖️ LGPL v2.1 with OPUS decoding.
(use DUB subconfigurations) to choose, default is boost.

## External links and references

- https://github.com/Zoadian/mp3decoder
- https://github.com/rombankzero/pocketmod
- https://github.com/Artefact2/libxm

## Ultra secret options
-The following `version` identifiers can be used to enable/disable decoder level features  
| Version Identifier | Feature                                                       |
|--------------------|---------------------------------------------------------------|
| AF_LINEAR          | Use linear sampling for MOD modules instead of Amiga sampling |
|                    |                                                               |

## Bugs

- `framesRemainingInPattern` is unimplemented for XM currently.
