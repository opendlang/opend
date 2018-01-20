module pdfd.ttf;

import std.stdio;
import std.conv;
import std.string;

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
        uint firstTag = popBE!uint(file);

        if (firstTag == 0x00010000 || firstTag == 0x4F54544F /* 'OTTO' */)
        {
            _isCollection = false;
            _numberOfFonts = 1;
        }
        else if (firstTag == 0x74746366 /* 'ttcf' */)
        {
            _isCollection = true;
            uint version_ = popBE!uint(file); // ignored for now
            _numberOfFonts = popBE!int(file);

            offsetToOffsetTable.length = _numberOfFonts;
            foreach(i; 0.._numberOfFonts)
                offsetToOffsetTable[i] = popBE!uint(file);
        }
        else
            throw new Exception("Couldn't recognize the font file type");
    }

    /// Number of fonts in this OpenType file
    int numberOfFonts()
    {
        return _numberOfFonts;
    }

private:
    const(ubyte)[] _wholeFileData;
    int[] offsetToOffsetTable;

    int _numberOfFonts;
    bool _isCollection; // It is a TTC or single font?

    uint offsetForFont(int index)
    {
        assert(index < numberOfFonts());

        if (_isCollection)
            return offsetToOffsetTable[index];
        else
            return 0;
    }

    const(char)[] familyName()
    {
        return "lol";
    }
}

/// Parses a font from a font file (which could contain data for several of them).
class OpenTypeFont
{
public:

    this(OpenTypeFile file, int index)
    {
        _file = file;
        _fontIndex = index;
        _wholeFileData = file._wholeFileData;
    }

    /// Returns: an index in the file, where that table start for this particular font.
    const(ubyte)[] findTable(uint fourCC)
    {
        int offsetToOffsetTable = _file.offsetForFont(_fontIndex);
        const(ubyte)[] offsetTable = _wholeFileData[offsetToOffsetTable..$];

        uint firstTag = popBE!uint(offsetTable);

        if (firstTag != 0x00010000 && firstTag != 0x4F54544F /* 'OTTO' */)
            throw new Exception("Unrecognized tag in Offser Table");

        int numTables = popBE!ushort(offsetTable);
        writefln("numTables = %s", numTables);
        skipBytes(offsetTable, 6);

        // Parse the Table Record entries
        // TODO: log search, this should be sorted by increasing tag
        for(int i = 0; i < numTables; ++i)
        {
            uint tag = popBE!uint(offsetTable);
            writefln("seen tag %x while looking for %x", tag, fourCC);
            if (tag == fourCC)
            {
                uint checkSum = popBE!uint(offsetTable);
                uint offset = popBE!uint(offsetTable);
                uint len = popBE!uint(offsetTable);
                return _wholeFileData[offset..offset+len];
            }
            else
                skipBytes(offsetTable, 12);
        }
        writefln("not found");
        return null; // Not found
    }

    /// Ditto, but throw if not found.
    const(ubyte)[] getTable(uint fourCC)
    {
        const(ubyte)[] result = findTable(fourCC);
        if (result is null)
            throw new Exception(format("Table not found: %s", fourCC));
        return result;
    }

    /// Returns: family name in UTF-8
    string familyName()
    {
        const(ubyte)[] nameTable = getTable(0x6e616d65 /* 'name' */);
        const(ubyte)[] nameTableParsed = nameTable;

        ushort format = popBE!ushort(nameTableParsed);
        return to!string(format); // TODO parse family name
    }


private:
    // need whole file since some data may be shared across fonts
    const(ubyte)[] _wholeFileData;

    OpenTypeFile _file;
    int _fontIndex;
}