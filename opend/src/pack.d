module pack;

import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.file;

import exceptions;
import util;

class Package
{
    this(string path)
    {
        this.path = path;
    }

    bool doesNeedRebuild()
    {
        checkBuildTime();
        return needsRebuild;
    }

    string getImportPath()
    {
        string[] sourceDirs = sourceDirectories.map!(x => path ~ "/" ~ x)
                                .filter!(x => exists(x) && isDir(x))
                                .array;
        if(sourceDirs.length == 0)
            throw new NotAnOpenDPackageException(path);
        return sourceDirs[0];
    }

private:
    void scan()
    {
        checkBuildTime();
    }

    void checkBuildTime()
    {
        if(buildTimeChecked)
            return;

        buildTimeChecked = true;
        SysTime mod = getModTime(getLibFile);
        auto files = getFiles(path);
        if(files.length == 0)
            return;
        
        SysTime newestFile = files.map!(x => getModTime(x)).array.sort!((x, y) => x < y).front();
        if(mod > newestFile)
            needsRebuild = true;
    }

    SysTime getModTime(string file)
    {
        SysTime acc, mod;
        getTimes(file, acc, mod);
        return mod;
    }

    string getLibFile()
    {
        auto name = getPackageNameFromPath(path);
        // return path ~ "/build/" ~ name ~ ".lib";
        return text(path, "/build/", name, ".lib");
    }

    SysTime buildTime;

    bool needsRebuild = false;
    string path;

    bool buildTimeChecked = false;

    immutable static string[] sourceDirectories = ["src", "source"];
}
