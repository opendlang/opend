module util;

import std.file;
import std.path;

///
string getPackageNameFromPath(string path)
{
    return baseName(path);
}
///
unittest
{
    assert(getPackageNameFromPath("C:\\some\\path") == "path");
    assert(getPackageNameFromPath("/var/path/" == "path"));
}

/// Retrieves all files in `dir` as fill pathes
string[] getFiles(string dir)
{
    string[] ret;
    foreach(ref DirEntry d; dirEntries(dir, SpanMode.breadth))
    {
        // Only care about files with ".d" extensions
        if(d.isDir || extension(d.name) != ".d")
            continue;

        // Auto-escape pathes!
        // Actually, I checked (on Windows) and paths having spaces in them work fine too.
        ret ~= /*"\"" ~ */absolutePath(d.name) /*~ "\""*/;
    }
    return ret;
}
