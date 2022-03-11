
Goals:
- fast, -betterC, nothrow, @nogc, @safe, pure(?), image library
- easiest API for basic image manipulation
- decoders for PNG and JPEG
- writer for PNG
- retrieve basic metadata, like DPI
- usable in Dplug (quick-loading), printed (print), turtle (game)
- Goals in decreasing order: portability, speed, memory usage, code size
- eventually replaces dplug:graphics shenanigans
- improving intel-intrinsics
- avoid templates as much as possible to prevent code size bloat, and complications 