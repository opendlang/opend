module pdfd.font;

import std.algorithm;
import std.file;
import std.array;
import standardpaths;

private string[] getFontDirectories() 
{
    return standardPaths(StandardPath.fonts);
}

// Gives back a list of absoliute pathes of .ttf files we know about
string[] listAllFontFiles()
{
    string[] listAllLocalFontFiles()
    {
        string[] fontAbsolutepathes;

        foreach(fontDir; getFontDirectories() )
        {
            auto files = filter!`endsWith(a.name,".ttf")`(dirEntries(fontDir, SpanMode.breadth)).array;
            foreach(f; files)
                fontAbsolutepathes ~= f.name;
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

unittest
{
    import std.stdio;
    writeln(listAllFontFiles());
}

// TODO: aggregates all fonts by family, like a browser does with @font-face