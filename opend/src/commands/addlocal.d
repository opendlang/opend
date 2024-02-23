module commands.addlocal;

import commands;
import exceptions;
import project;
import platform;

class AddLocalCommand : Command
{
    this(Platform platform)
    {
        super(platform);
    }

    override void run(string[] args)
    {
        if(args.length != 1)
            throw new CommandException("Requires only one path to be specified!");

        OpenDProject prj = new OpenDProject(platform.currentDir, platform);
        prj.addLocalPacakge(args[0]);
    }
}
