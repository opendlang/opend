# Table of contents

| File                                                                               | Purpose                                                         |
|------------------------------------------------------------------------------------|-----------------------------------------------------------------|
| [bitfields.d](https://github.com/dlang/dmd/blob/master/compiler/src/dmd/common/bitfields.d) | Pack multiple boolean fields into bit fields                    |
| [file.d](https://github.com/dlang/dmd/blob/master/compiler/src/dmd/common/file.d)           | Functions and objects dedicated to file I/O and management      |
| [int128.d](https://github.com/dlang/dmd/blob/master/compiler/src/dmd/common/int128.d)       | 128-bit integer arithmetic                                      |
| [outbuffer.d](https://github.com/dlang/dmd/blob/master/compiler/src/dmd/common/outbuffer.d) | An expandable buffer in which you can write text or binary data |
| [smallbuffer.d](https://github.com/dlang/dmd/blob/master/compiler/src/dmd/common/smallbuffer.d) | Temporary array using a fixed buffer, with heap allocation as fallback |
| [string.d](https://github.com/dlang/dmd/blob/master/compiler/src/dmd/common/string.d)      | Common string functions including filename manipulation         |

This table covers the D modules in `dmd/common/`; `outbuffer.h` is the corresponding C++ interface header.
