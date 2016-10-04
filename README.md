DerelictFT
==========

A dynamic binding to version 2.6 and 2.7 of the [FreeType][1] library for the D Programming Language.

Please see the pages [Building and Linking Derelict][2] and [Using Derelict][3], in the Derelict documentation, for information on how to build DerelictFT and load FreeType at run time. In the meantime, here's some sample code.

```D
import derelict.freetype.ft;

void main() {
    // Load the FreeType library.
    DerelictFT.load();

    // Now FreeType functions can be called.
    ...
}
```

[1]: http://freetype.org/
[2]: http://derelictorg.github.io/compiling.html
[3]: http://derelictorg.github.io/using.html