OpenD fork of LDC
===============================

## Build instructions
### Windows
#### Prerequisites

* Microsoft Visual Studio, the newer the better, with:
    * CMake workload
    * Clang workload (ldc will not build with msvc)
* ninja -- ldc will only build with ninja, grab here: https://ninja-build.org/
* LLVM prebuilt binaries, you can grab them here: https://github.com/ldc-developers/llvm-project/releases

#### Building steps
1. Use Visual Studio's "x64 Native Tools Command Prompt". In it, cd to ldc directory.
1. `mkdir build` -- it is best to build in a separate folder
1. `cd build`
1. `cmake .. -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DLLVM_ROOT_DIR="D:\PATH\TO\LLVM" -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl`
    * LDC will **only** build with Ninja. At least I had no luck making it build with msbuild.
    * You can configure `-DCMAKE_BUILD_TYPE` to either `Release`, either `Debug`
    * Reiterating, LDC will **only** build with clang compiler. Or, at least, I had no luck building it with msbuild.
1. `ninja` -- this will build everything

You will find the result in `bin` directory. You can use `ldc2.exe` directly, the `ldc2.conf` files is already set-up, no extra work needed.

LDC – the LLVM-based D Compiler
===============================

LDC is fully Open Source; the parts of the source code not taken/adapted from
other projects are BSD-licensed (see the LICENSE file for details).

Please consult the D wiki for further information:
https://wiki.dlang.org/LDC

