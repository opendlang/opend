# OpenD

This is the main page for the OpenD language build system.  
**WARNING** This is still work in progress, and in very early stages of development. Expect stuff to change rapidly.

## Meta

The main idea is, calling `opend` should "Just Work"™. Therefore, calling `opend` in your app's folder will look for a folder named "src" or "source" and build every .d file from there.
Optionally, you can specify the source file directory right after: `opend mysourcedir`. `opend` will guess the output file name by how the current working folder is called.
By default, calling `opend` will execute something like this:
```
dmd src/main.d -od=build/ -of=build/cwd.exe
```

## Options

A few options are available:
* `--compiler=/path/to/compiler` specifies the path to desired compiler
* `--output=[library|executable]` specifies the build output type. Default is `executable`
* `--type=[debug|release]` specifies the build type. Default is `debug`

## Building opend

Just use `opend` in this directory, duh ～  
(Also, for the first time, running `dmd src/opend.d -of=opend.exe` should be enough)

## Some future plans

We hope to keep `opend` as simple as possible. Anyway, here's a short list of TODOs:
* Store build configuration in `.opend` file
* Create some kind of registry for thirdparty dependencies
* Add more build stuff
* Refactor code...