module pdfd.ttf;

import std.stdio;

/// TTF file parser, for the purpose of finding all fonts in a file, their family name, their weight, etc.
// Need TTF format doc
class TrueTypeFont
{
    this(ubyte[] fileContents)
    {
        _data = fileContents;
    }

    const(char)[] familyName()
    {
        return "lol";
    }

private:
    ubyte[] _data;
}