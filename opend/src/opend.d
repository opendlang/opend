module opend;

import std.algorithm;
import std.getopt;
import std.file;
import std.string : endsWith;
import std.path;
import std.process : execute;
import std.stdio : writeln;

string compiler = `dmd`;
string type = "executable";
string buildType = "debug";

/// Retrieves all files as full path
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

string getExeFileName()
{
    immutable dname = baseName(getcwd());
    writeln(dname);
    version(Windows)
    {
        immutable extension = ".exe";
    }
    else
    {
        immutable extension = "";
    }

    return dname ~ extension;
}

string getLibFileName()
{
    immutable dname = baseName(getcwd());
    version(Windows)
    {
        immutable extension = ".lib";
    }
    else
    {
        immutable extension = "";
    }

    return dname ~ extension;
}

string[] getDefaultFiles()
{
    if(exists("src") && isDir("src"))
    {
        return getFiles("src");
    }
    else if(exists("source") && isDir("source"))
    {
        return getFiles("source");
    }
    return [];
}

string[] extraSwitches = ["-od=build/"];

string flattenCmd(string[] cmd)
{
    string ret;
    foreach(str; cmd)
    {
        ret ~= str ~ " ";
    }
    return ret;
}

string getOfFlag()
{
    // With -lib enabled, dmd puts .lib file wherever the -od is specified. Doesn't happen with executables
    if(type == "library")
        return "-of=" ~ getLibFileName();
    else
        return "-of=build/" ~ getExeFileName();
}

int main(string[] args)
{
    auto optionsResult = getopt(args,
        "compiler", &compiler,
        "output", &type,
        "type", &buildType);

    static immutable availOutputs = ["executable", "library"];
    static immutable availBuildTypes = ["debug", "release"];

    if(availOutputs.all!(x => x != type))
    {
        writeln(i"Unsupported output type `$(type)`. Only `executable` and `library` are supported");
        return -1;
    }

    if(availBuildTypes.all!(x => x != buildType))
    {
        writeln(i"Unsupported build type `$(buildType)`. Onlt `debug` and `release` are supported");
        return -1;
    }

    writeln("Using compiler " ~ compiler);
    writeln("Target output is " ~ type);

    string[] srcFiles;
    if(args.length > 1)
    {
        srcFiles = getFiles(args[1]);
    }
    else
    {
        srcFiles = getDefaultFiles();
    }

    if(srcFiles.length == 0)
    {
        writeln("No source directory found (either `src`, either `source`)");
        return -1;
    }

    string dstFileName = type == "executable" ? getExeFileName() : getLibFileName();
    writeln("Output file is " ~ dstFileName);
    string[] cmd = [compiler] ~ srcFiles ~ extraSwitches ~ [getOfFlag()];
    if(type == "library")
    {
        cmd ~= ["-lib"];
    }
    if(buildType == "release")
    {
        cmd ~= ["-release"];
    }
    writeln("Running " ~ flattenCmd(cmd));

    auto result = execute(cmd);
    if(result[0] != 0)
    {
        writeln(result[1]);
        writeln("Error!");
        return -1;
    }
    writeln(i"Build successful. Files written to ./build/");
    return 0;
}
