module commands.runfile;

import std.process;
import std.stdio;

import commands;
import exceptions;
import platform;

class RunFileCommand : Command
{
    this(Platform platform)
    {
        super(platform);
    }

    override void run(string[] args)
    {
        if(args.length != 1)
            throw new CommandException("Requires only one file!");

        immutable dst = platform.tmpPath ~ "\\";
        immutable target = platform.buildFile(args[0]);
        auto res = executeShell(target);
        writeln(res.output);
    }
}
