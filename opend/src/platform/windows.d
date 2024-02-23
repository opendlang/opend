module platform.windows;

version(Windows):

import std.array;

import platform;

class WindowsPlatform : Platform
{
    override string tmpPath()
    {
        import std.process;
        return environment["APPDATA"] ~ "\\opend";
    }

    package this()
    {
        super();
    }

protected:
    override string getExeFileNameForFile(string file)
    {
        return file.replace(".d", ".exe");
    }
}
