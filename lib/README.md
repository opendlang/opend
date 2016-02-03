This folder contains 32bit and 64bit windows cairo libraries and the required dependecies.
The libraries are copied from [MSYS2](http://msys2.github.io/) and can be used with DMD, MSVC and MinGW compilers. 

Folder layout:
* `32` - contains 32 bit DLLs for all compilers
  * `mars` - contains import library for DMD `-m32`
  * `msvc_mingw` - contains import library for DMD `-m32mscoff` and all other compilers
* `64` contains 64 bit DLLs and import library for all compilers

To use these libraries in a dub based project, copy all libraries to a `lib` folder and add this to dub.json:
```json
    "libs-windows-x86-dmd": ["lib/32/mars/cairo"],
    "libs-windows-x86-gdc": ["lib/32/msvc_mingw/cairo"],
    "libs-windows-x86-ldc": ["lib/32/msvc_mingw/cairo"],
    "libs-windows-x86_64": ["lib/64/cairo"],
    "copyFiles-windows-x86": ["lib/32/*.dll"],
    "copyFiles-windows-x86_64": ["lib/64/*.dll"]
```

The script used to generate this cairo library package can be found [here](http://github.com/cairoD/mingw-cairo-lib).
