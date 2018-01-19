module pdfd.systemfonts;

import std.algorithm;
import std.file;
import std.array;
import standardpaths;

import pdfd.ttf;

/// FontRegistry parses all fonts from thhee system.
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
        ubyte[] fileContents = cast(ubyte[]) std.file.read(pathToTrueTypeFontFile);
        auto ttf = new TrueTypeFont(fileContents);
        // TODO
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
                auto filesTTF = filter!`endsWith(a.name,".ttf")`(dirEntries(fontDir, SpanMode.breadth)).array;
                foreach(f; filesTTF)
                    fontAbsolutepathes ~= f.name;

                auto filesTTC = filter!`endsWith(a.name,".ttc")`(dirEntries(fontDir, SpanMode.breadth)).array;
                foreach(f; filesTTC)
                {
                    import std.stdio;
                    writeln(f.name);
                    fontAbsolutepathes ~= f.name;
                }
            }
            return fontAbsolutepathes;
        }

        string[] listAllSystemFontFiles()
        {
            string[] fontAbsolutepathes;

            foreach(fontDir; getFontDirectories() )
            {
                auto files = filter!`endsWith(a.name,".ttf")`(dirEntries(fontDir, SpanMode.shallow)).array;
                foreach(f; files)
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