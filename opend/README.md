# OpenD

This is the main page for the OpenD language build system.  
**WARNING**: This is still a work in progress, and in very early stages of development. Expect stuff to change rapidly.

## Meta

The main idea is that calling `opend` should "Just Work"™. Calling `opend` in your program's directory will look for a subdirectory named "src" or "source" and compile every .d file in there.
Optionally, you can specify the source code directory as an argument on the command line, e.g. `opend mysourcedir` to build .d files in the directory "mysourcedir". `opend` will name the output file after the current directory.
By default, calling `opend` will execute something like this:
```
dmd src/main.d -od=build/ -of=build/cwd.exe
```

## Options

A few options are available:
* `--compiler=/path/to/compiler` specifies the path to your desired compiler
* `--output=[executable|library]` specifies whether to output an executable or a library (defaults to `executable`)
* `--type=[debug|release]` specifies the build type (defaults to `debug`). This determines whether to include debug symbols or to optimize the code.

## Building opend

Just call `opend` in this directory. If you don't have it, running `dmd src/opend.d -of=opend` should be enough.

## Some future plans

We hope to keep `opend` as simple as possible. Anyway, here's a short list of TODOs:
* Store the build configuration in a `.opend` file
* Create some kind of registry for thirdparty dependencies
* Add more build stuff
* Refactor code...