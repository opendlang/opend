# cairoD

This is a D2 binding and wrapper for the [cairo](http://cairographics.org) graphics library.

Currently cairoD targets cairo version **1.10.2**.

Homepage: https://github.com/cairoD/cairoD

## Examples

The cairoD library ships with some examples in the [example](https://github.com/cairoD/cairoD/tree/master/example) directory.
Some of these examples are ported from [cairographics.org](http://cairographics.org/samples/), some are original. To build these
examples, simply use dub:

```bash
dub run
```

Some examples can directly present the results in a GTK2 or GTK3 window. Simply use the correct dub configurations:

```bash
dub run --config=gtk2
dub run --config=gtk3
```

![GTK3 example image](example_gtk3.png)

## Building

You can use [dub] to make this library a dependency for your project.
[dub]: http://code.dlang.org/packages/cairod


### Customizing the cairoD configuration
The cairo library provides certain features as optional extensions. What extensions are available depends on the configuration
of the cairo C library. It is recommended to enable exactly the same extensions in cairoD.

cairoD contains a configure script which automatically tries to guess what cairo extensions should be enabled.
It is written in D and it's run automatically by dub before building cairoD. The script tries to find the local C compiler
and then uses this compiler to enquire information about the locally installed cairo library. This will only work
if the development headers for the cairo C library are installed. If the configure script can't figure out which
extensions are supported it enforces a minimal extension set for cairoD.

```bash
#Sample output
Performing "debug" build using dmd for x86_64.
cairod 0.0.1-alpha.1+1.10.2.commit.4.g9d16388: building configuration "stlib"...
Running pre-build commands...
================================================================================
=> Configuring cairoD
=> Environment variables:
   CC               C compiler used to detect cairo features
   CAIROD_FEATURES  Manually overwrite feature flags

=> Trying to detect features supported by cairo library
   Searching for C compiler name...                                          gcc
   Whether C compiler can compile cairo programs...                         true
   For CAIRO_HAS_PS_SURFACE...                                              true
   For CAIRO_HAS_PDF_SURFACE...                                             true
   For CAIRO_HAS_SVG_SURFACE...                                             true
   For CAIRO_HAS_WIN32_SURFACE...                                          false
   For CAIRO_HAS_WIN32_FONT...                                             false
   For CAIRO_HAS_FT_FONT...                                                 true
   For CAIRO_HAS_XCB_SURFACE...                                             true
   For CAIRO_HAS_DIRECTFB_SURFACE...                                       false
   For CAIRO_HAS_XLIB_SURFACE...                                            true
   For CAIRO_HAS_PNG_FUNCTIONS...                                           true

=> Configuration:
   PNG support: true
   Surfaces: PostScript PDF SVG XCB xlib
   Font backends: FreeType
================================================================================
```

#### Selecting the C compiler

The `CC` environment variable can be used to specify the used C compiler. If this is not specified the build script always
defaults to `gcc`.
```bash
CC="arm-linux-gnueabi-gcc" dub build
```

#### Manually selecting the cairoD extensions

It is posslible to list cairoD extensions manually. In this case the configure script will not run `CC` to guess the configuration,
it will simply use the specified extensions instead. Simply add all required extensions as a space separated list to the `CAIROD_FEATURES`
environment variable.

```bash
CAIROD_FEATURES="CAIRO_HAS_PDF_SURFACE CAIRO_HAS_SVG_SURFACE CAIRO_HAS_PNG_FUNCTIONS" dub build

Performing "debug" build using dmd for x86_64.
cairod 0.0.1-alpha.1+1.10.2.commit.4.g9d16388: building configuration "stlib"...
Running pre-build commands...
================================================================================
=> Configuring cairoD
=> Environment variables:
   CC               C compiler used to detect cairo features
   CAIROD_FEATURES  Manually overwrite feature flags

=> Configuration:
   PNG support: true
   Surfaces: PDF SVG
   Font backends: 
================================================================================
```

#### Manually running the configure script

The configure script is written in D and requires rdmd to be built. If you don't have rdmd installed, the build might fail.
There are two possible solutions to this problem:

* You can use minimal configuration versions. These do not run the configure script:
    ```bash
    dub build --config=stlib-minimal
    # To run the unittests
    dub test --config=unittest-minimal
    ``` 
    In this case only the minimal extension set will be enabled.

* The configure script can be run manually as well:
    ```bash
    dmd -run configure.d
    ```
    This will overwrite the configuration file in `src/cairo/c/config.d`. Then build using dub and the minimal configuration to use the configured extensions:
    ```bash
    dub build --config=stlib-minimal
    # To run the unittests
    dub test --config=unittest-minimal
    ``` 

## Links

- Cairo [homepage](http://cairographics.org).

## License

Distributed under the Boost Software License, Version 1.0.

See the accompanying file LICENSE_1_0.txt or view it [online][BoostLicense].

[BoostLicense]: http://www.boost.org/LICENSE_1_0.txt
