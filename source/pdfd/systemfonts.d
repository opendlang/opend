module pdfd.systemfonts;

import std.algorithm;
import std.file;
import std.array;
import standardpaths;

import pdfd.ttf;

/// FontRegistry parses all fonts from the system.
/// Aggregates all fonts by family, like a browser does with @font-face
/// This allows to get one particular physical font with just a family name, an approximate weight etc.
class FontRegistry
{
    /// Create a font registry, parsing every available fonts.
    this()
    {
        // Extract all known fonts from system directories
        foreach(fontFile; listAllFontFiles())
            registerFontFile(fontFile);
    }

    /// Add a font file to parse.
    /// Registers every font within that file.
    /// Important: the file must outlive the `FontRegistry` itself.
    void registerFontFile(string pathToTrueTypeFontFile)
    {
        import std.stdio;
        ubyte[] fileContents = cast(ubyte[]) std.file.read(pathToTrueTypeFontFile);

        try
        {
            auto fontFile = new OpenTypeFile(fileContents);
            scope(exit) fontFile.destroy();

            writefln("parsing %s => %s fonts", pathToTrueTypeFontFile, fontFile.numberOfFonts);

            foreach(fontIndex; 0..fontFile.numberOfFonts)
            {
                auto font = new OpenTypeFont(fontFile, fontIndex);
                scope(exit) font.destroy;

                writefln("Family name: %s", font.familyName);
            }
        }
        catch(Exception e)
        {
            // fails silently
        }
    }

private:

    // Describe a single font registered somewhere
    struct KnownFont
    {
        string filePath; // path to the font file
        int fontIndex;   // index into that font file, which could contain multiple fonts
        string familyName;
    }

    /// Get a list of system font directories
    static private string[] getFontDirectories()
    {
        return standardPaths(StandardPath.fonts);
    }

    /// Gives back a list of absoliute pathes of .ttf files we know about
    static string[] listAllFontFiles()
    {
        string[] listAllLocalFontFiles()
        {
            string[] fontAbsolutepathes;

            foreach(fontDir; getFontDirectories() )
            {
                auto files = dirEntries(fontDir, SpanMode.shallow);
                foreach(f; files)
                    if (hasFontExt(f.name))
                        fontAbsolutepathes ~= f.name;
            }
            return fontAbsolutepathes;
        }

        string[] listAllSystemFontFiles()
        {
            string[] fontAbsolutepathes;

            foreach(fontDir; getFontDirectories() )
            {
                auto files = dirEntries(fontDir, SpanMode.shallow);
                foreach(f; files)
                    if (hasFontExt(f.name))
                        fontAbsolutepathes ~= f.name;
            }
            return fontAbsolutepathes;
        }

        return listAllLocalFontFiles() ~ listAllSystemFontFiles();
    }
}

unittest
{
    auto registry = new FontRegistry();
    registry.destroy();
}

private:


static bool hasFontExt(string path)
{
    if (path.length < 4)
        return false;

    string ext = path[$-4..$];

    if (ext == ".ttf" || ext == ".ttc"
     || ext == ".otf" || ext == ".otc")
        return true; // This is very likely a font

    return false;
}