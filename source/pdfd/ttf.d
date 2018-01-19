module pdfd.ttf;

import std.stdio;
import binrange;

/// openType 1.8 file parser, for the purpose of finding all fonts in a file, their family name, their weight, etc.
/// This OpenType file might either be:
/// - a single font
/// - a collection file starting with a TTC Header
class OpenTypeFile
{
    this(const(ubyte[]) wholeFileContents)
    {
        _wholeFileData = wholeFileContents;
        const(ubyte)[] file = wholeFileContents[];

        // Read first tag
        uint sfntVersion = popBE!uint(input);

        if (sfntVersion == 0x00010000 || sfntVersion == 0x4F54544F /* 'OTTO' */)
        {
            _isCollection = false;
            _numberOfFonts = 1;
        }
        else if (sfntVersion == 0x74746366 /* 'ttcf' */)
        {
            _isCollection = true;
            assert(false); // not supported yet
        }
    }

    const(char)[] familyName()
    {
        return "lol";
    }

    /// Number of fonts in this OpenType file
    int numberOfFonts()
    {
        return _numberOfFonts;
    }

private:
    const(ubyte)[] _wholeFileData;

    int _numberOfFonts;
    bool _isCollection; // It is a TTC or single font?
}