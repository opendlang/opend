module platform.linux;

import std.array;
import std.conv : to;

import platform;

class LinuxPlatform : Platform
{
    override string tmpPath()
    {
        import std.path;
        return absolutePath(expandTilde("~/.opend")).array.to!string;
    }

    package this()
    {
        super();
    }

protected:
    override string getExeFileNameForFile(string file)
    {
        return file.replace(".d", "");
    }
}
