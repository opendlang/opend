module pdfd.fontregistry;

import std.algorithm;
import std.file;
import std.array;
import std.uni;
import std.string: format;
import std.math: abs;
import standardpaths;

public import pdfd.opentype;

/// FontRegistry register partial font information for all fonts
/// from the system directories, plus the ones added by the user.
/// Aggregates all fonts by family, a bit like a browser or Word does.
/// This allows to get one particular physical font with just a family
/// name, an approximate weight etc. Without such font-matching, it's
/// impractical and you need to give explicit ttf files manually.
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

        try
        {
            auto fontFile = new OpenTypeFile(fileContents);
            scope(exit) fontFile.destroy();

            foreach(fontIndex; 0..fontFile.numberOfFonts)
            {
                auto font = new OpenTypeFont(fontFile, fontIndex);
                scope(exit) font.destroy;

                KnownFont kf;
                kf.filePath = pathToTrueTypeFontFile;
                kf.fontIndex = fontIndex;
                kf.familyName = font.familyName;
                kf.style = font.style;
                kf.weight = font.weight;
                _knownFonts ~= kf;

                import std.stdio;
                //writefln("Family name: %s", font.familyName);
                //writefln("SubFamily name: %s", font.subFamilyName);
                //writefln("Weight extracted: %s", font.weight);
                //writefln("Style: %s\n", font.style());
            }
        }
        catch(Exception e)
        {
            // For now we consider we shouldn't have unparseable fonts
        }
    }

    /// Returns: a font which best follows the requested characteristics given.
    OpenTypeFont findBestMatchingFont(string familyName, FontWeight weight, FontStyle style)
    {
        KnownFont* best = null;
        float bestScore = float.infinity;

        familyName = toLower(familyName);

        foreach(ref kf; _knownFonts)
        {
            // FONT MATCHING HEURISTIC HERE
            // unlike CSS we don't consider the "current char"
            // the lower, the better
            float score = 0;

            if (familyName != toLower(kf.familyName))
                score += 100000; // no matching family name

            score += abs(weight - kf.weight); // weight difference

            if (style != kf.style)
            {
                // not a big problem to choose oblique and italic interchangeably
                if (style == FontStyle.oblique && kf.style == FontStyle.italic)
                    score += 1;
                else if (style == FontStyle.italic && kf.style == FontStyle.oblique)
                    score += 1;
                else
                    score += 10000;
            }

            if (score < bestScore)
            {
                best = &kf;
                bestScore = score;
            }
        }

        struct KnownFont
        {
            string filePath; // path to the font file
            int fontIndex;   // index into that font file, which could contain multiple fonts
            string familyName;
            FontStyle style;
            FontWeight weight;
        }

        if (best is null)
            throw new Exception(format("No matching font found for '%s'.", familyName));

        return best.getParsedFont();
    }

private:

    // Describe a single font registered somewhere, with the information needed
    // to parse it back.
    // This is all what we keep before the font is requested,
    // to avoid keeping unparsed fonts in memory.
    struct KnownFont
    {
        string filePath; // path to the font file
        int fontIndex;   // index into that font file, which could contain multiple fonts
        string familyName;
        FontStyle style;
        FontWeight weight;
        OpenTypeFont instance;

        OpenTypeFont getParsedFont() // opens and parses that font, lazily
        {
            if (instance is null)
            {
                ubyte[] fileContents = cast(ubyte[]) std.file.read(filePath);
                auto file = new OpenTypeFile(fileContents); // TODO: cache those files too
                instance = new OpenTypeFont(file, fontIndex);
            }
            return instance;
        }
    }

    /// A list of descriptor for all known fonts to the registry.
    KnownFont[] _knownFonts;

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

/// Returns: A global, lazily constructed font registry.
FontRegistry theFontRegistry()
{
    __gshared FontRegistry globalFontRegistry;
    if (globalFontRegistry is null)
        globalFontRegistry = new FontRegistry();

    return globalFontRegistry;
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