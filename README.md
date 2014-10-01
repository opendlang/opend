DerelictFT
==========

A dynamic binding to the [FreeType][1] library, version 2.5.3, for the D Programming Language.

For information on how to build DerelictFT and link it with your programs, please see the post [Using Derelict][2] at The One With D.

For information on how to load the FreeType library via DerelictFT, see the page [DerelictUtil for Users][3] at the DerelictUtil Wiki. In the meantime, here's some sample code.

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
[2]: http://dblog.aldacron.net/derelict-help/using-derelict/
[3]: https://github.com/DerelictOrg/DerelictUtil/wiki/DerelictUtil-for-Users