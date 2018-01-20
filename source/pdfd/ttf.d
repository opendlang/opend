module pdfd.ttf;

import std.stdio;
import std.conv;
import std.string;

import binrange;

/// OpenType 1.8 file parser, for the purpose of finding all fonts in a file, their family name, their weight, etc.
/// This OpenType file might either be:
/// - a single font
/// - a collection file starting with a TTC Header
/// You may find the specification here: www.microsoft.com/typography/otspec/
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
            throw new Exception("Unrecognized tag in Offset Table");

        int numTables = popBE!ushort(offsetTable);
        skipBytes(offsetTable, 6);

        const(uint)[] tableRecordEntries = cast(uint[])(offsetTable[0..16*numTables]);

        // Binary search following
        // https://en.wikipedia.org/wiki/Binary_search_algorithm#Algorithm
        int L = 0;
        int R = numTables - 1;
        while (L <= R)
        {
            int m = (L+R)/2;
            uint tag = forceBigEndian(tableRecordEntries[m * 4]);
            if (tag < fourCC)
                L = m + 1;
            else if (tag > fourCC)
                R = m - 1;
            else 
            {
                // found
                assert (tag == fourCC);                
                uint checkSum = forceBigEndian(tableRecordEntries[m*4+1]);
                uint offset = forceBigEndian(tableRecordEntries[m*4+2]);
                uint len = forceBigEndian(tableRecordEntries[m*4+3]);
                return _wholeFileData[offset..offset+len];
            }
        }
        return null; // not found
    }

    /// Ditto, but throw if not found.
    const(ubyte)[] getTable(uint fourCC)
    {
        const(ubyte)[] result = findTable(fourCC);
        if (result is null)
            throw new Exception(format("Table not found: %s", fourCC));
        return result;
    }

    string familyName()
    {
        return getName(NameID.fontFamily);
    }

private:
    // need whole file since some data may be shared across fonts
    // And also table offsets are relative to the whole file.
    const(ubyte)[] _wholeFileData;

    OpenTypeFile _file;
    int _fontIndex;

    /// Returns: that "name" information, in UTF-8
    string getName(NameID requestedNameID)
    {
        const(ubyte)[] nameTable = getTable(0x6e616d65 /* 'name' */);
        const(ubyte)[] nameTableParsed = nameTable;

        ushort format = popBE!ushort(nameTableParsed);
        if (format > 1)
            throw new Exception("Unrecognized format in 'name' table");

        ushort numNameRecords = popBE!ushort(nameTableParsed);
        ushort stringOffset = popBE!ushort(nameTableParsed);

        const(ubyte)[] stringDataStorage = nameTable[stringOffset..$];

        foreach(i; 0..numNameRecords)
        {
            PlatformID platformID = cast(PlatformID) popBE!ushort(nameTableParsed);
            ushort encodingID = popBE!ushort(nameTableParsed);
            ushort languageID = popBE!ushort(nameTableParsed);
            ushort nameID = popBE!ushort(nameTableParsed);
            ushort length = popBE!ushort(nameTableParsed);
            ushort offset = popBE!ushort(nameTableParsed); // String offset from start of storage area (in bytes)
            if (nameID == requestedNameID)
            {
                writeln("platform ID = ", platformID);
                writeln("encodingID = ", encodingID);
                writeln("languageID = ", encodingID);
                writeln("nameID = ", nameID);
                writeln("length = ", length);

                // found
                const(ubyte)[] stringSlice = stringDataStorage[offset..offset+length];
                string name;

                if (platformID == PlatformID.macintosh && encodingID == 0)
                {
                    // MacRoman encoding
                    name = decodeMacRoman(stringSlice);
                }
                else
                {
                    // Most of the time it's UTF16-BE
                    name = decodeUTF16BE(stringSlice);                
                }
                return name;                
            }
        }

        return null; // not found
    }

    enum PlatformID : ushort
    {
        unicode,
        macintosh,
        iso,
        windows,
        custom,
    }

    enum NameID : ushort
    {
        copyrightNotice      = 0,
        fontFamily           = 1,
        fontSubFamily        = 2,
        uniqueFontIdentifier = 3,
        fullFontName         = 4,
        versionString        = 5,
        postscriptName       = 6,
        trademark            = 7,
        manufacturer         = 8,
        designer             = 9,
        description          = 10,
        // There are other information available in a font
        // not reproduced here
    }
}


private:

uint forceBigEndian(ref const(uint) x) pure nothrow @nogc
{
    version(BigEndian)
        return x;
    else
    {
        import core.bitop: bswap;
        return bswap(x);
    }
}

string decodeMacRoman(const(ubyte)[] input) pure
{
    static immutable dchar[128] CONVERT_TABLE  =
    [
        'Ä', 'Å', 'Ç', 'É', 'Ñ', 'Ö', 'Ü', 'á', 'à', 'â', 'ä'   , 'ã', 'å', 'ç', 'é', 'è',
        'ê', 'ë', 'í', 'ì', 'î', 'ï', 'ñ', 'ó', 'ò', 'ô', 'ö'   , 'õ', 'ú', 'ù', 'û', 'ü',
        '†', '°', '¢', '£', '§', '•', '¶', 'ß', '®', '©', '™'   , '´', '¨', '≠', 'Æ', 'Ø',
        '∞', '±', '≤', '≥', '¥', 'µ', '∂', '∑', '∏', 'π', '∫'   , 'ª', 'º', 'Ω', 'æ', 'ø',
        '¿', '¡', '¬', '√', 'ƒ', '≈', '∆', '«', '»', '…', '\xA0', 'À', 'Ã', 'Õ', 'Œ', 'œ',
        '–', '—', '“', '”', '‘', '’', '÷', '◊', 'ÿ', 'Ÿ', '⁄'   , '€', '‹', '›', 'ﬁ', 'ﬂ',
        '‡', '·', '‚', '„', '‰', 'Â', 'Ê', 'Á', 'Ë', 'È', 'Í'   , 'Î', 'Ï', 'Ì', 'Ó', 'Ô',
        '?', 'Ò', 'Ú', 'Û', 'Ù', 'ı', 'ˆ', '˜', '¯', '˘', '˙'   , '˚', '¸', '˝', '˛', 'ˇ',
    ];

    string textTranslated = "";
    foreach(i; 0..input.length)
    {
        char c = input[i];
        dchar ch;
        if (c < 128)
            ch = c;
        else
            ch = CONVERT_TABLE[c - 128];
        textTranslated ~= ch;
    }
    return textTranslated;
}

string decodeUTF16BE(const(ubyte)[] input) pure
{
    wstring utf16 = "";
    
    if ((input.length % 2) != 0)
        throw new Exception("Couldn't decode UTF-16 string");

    int numCodepoints = cast(int)(input.length)/2;
    for (int i = 0; i < numCodepoints; ++i)
    {
        wchar ch = popBE!ushort(input);
        utf16 ~= ch;
    }
    return to!string(utf16);
}
