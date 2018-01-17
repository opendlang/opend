module pdfd.ttf;

import std.stdio;

/// TTF file parser, for the purpose of finding all fonts in a file, their family name, their weight, etc.
class TrueTypeFont
{
    this(ubyte[] fileContents)
    {
        _data = fileContents;

        
        writeln(_data[0..16]);
    }

private:
    ubyte[] _data;

}