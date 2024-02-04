module opend;

import std.algorithm;
import std.array : array;
import std.getopt;
import std.file;
import std.string : endsWith;
import std.path;
import std.process : execute;
import std.stdio : writeln;

import util;
import platform;
import project;
import commands;

string compiler = `dmd`;
string type = "executable";
string buildType = "debug";

string getExeFileName()
{
    immutable dname = getPackageNameFromPath(getcwd());
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
    immutable dname = getPackageNameFromPath(getcwd());
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
    // dmd with -lib puts the static library in the directory specified by -od. Doesn't happen with executables
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

    Platform p = Platform.create();
    p.compilerPath = compiler;

    // Must be trying to run a single file
    if(args.length > 1 && args[1].endsWith(".d"))
    {
        RunFileCommand cmd = new RunFileCommand(p);
        cmd.run(args[1 .. $]);
        return 0;
    }

    if(args.length > 1 && args[1] == "please")
    { 
        if(args[2] == "add-local-package")
        {
            AddLocalCommand cmd = new AddLocalCommand(p);
            cmd.run(args[3 .. $]);
            return 0;
        }
    }

    if(availOutputs.all!(x => x != type))
    {
        writeln(i"Invalid output `$(type)` (provide `executable` or `library`)");
        return -1;
    }

    if(availBuildTypes.all!(x => x != buildType))
    {
        writeln(i"Invalid build type `$(buildType)` (provide `debug` or `release`)");
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
        writeln("Could not find source code directory (tried `src` and `source`)");
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

    OpenDProject prj = new OpenDProject(getcwd(), p);
    auto flg = prj.getIs.map!(x => "-I=" ~ x).array;
    cmd ~= flg;

    writeln("Running " ~ flattenCmd(cmd));

    auto result = execute(cmd);
    if(result[0] != 0)
    {
        writeln(result[1]);
        writeln("Error!");
        return -1;
    }
    writeln(i"Build completed, output files written to ./build/");
    return 0;
}
