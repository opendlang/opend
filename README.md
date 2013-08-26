DerelictFT
==========

A dynamic binding to the [FreeType](http://freetype.org/) library, version 2.4, for the D Programming Language.

For information on how to build DerelictFT and link it with your programs, please see the post [Building and Using Packages in DerelictOrg](http://dblog.aldacron.net/forum/index.php?topic=841.0) at the Derelict forums.

For information on how to load the FreeType library via DerelictFT, see the page [DerelictUtil for Users](https://github.com/DerelictOrg/DerelictUtil/wiki/DerelictUtil-for-Users) at the DerelictUtil Wiki. In the meantime, here's some sample code.

```D
import derelict.freetype.ft;

void main() {
    // Load the FreeType library.
    DerelictFT.load();

    // Now FreeType functions can be called.
    ...
}
```