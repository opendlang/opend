module main;

import std.stdio;
import gamut;


void usage()
{
    writeln("Convert image from one format to another.");
    writeln;
    writeln("Usage: convert input.ext output.ext [-bitness {8|16|auto}]\n");
    writeln;
    writeln("Params:");
    writeln("  -i           Specify an input file");
    writeln("  -b/--bitness Change bitness of file");
    writeln("  -h           Shows this help");
    writeln;
}

int main(string[] args)
{
    try
    {
        string input = null;
        string output = null;
        bool help = false;
        int bitness = -1; // auto

        for(int i = 1; i < args.length; ++i)
        {
            string arg = args[i];
            if (arg == "-b" || arg == "--bitness")
            {
                ++i;
                if (args[i] == "8") bitness = 8;
                else if (args[i] == "16") bitness = 16;
                else if (args[i] == "auto") bitness = -1;
                else throw new Exception("Must specify 8, 16, or auto after -bitness");
            }
            else if (arg == "-h")
            {
                help = true;
            }
            else
            {
                if (input)
                {
                    if (output)
                        throw new Exception("Too many files provided");
                    else
                        output = arg;
                }
                else
                    input = arg;
            }
        }

        if (help || input is null || output is null)
        {
            usage();
            return 0;
        }

        Image image;
        Image* result = &image;

        image.loadFromFile(input);


        if (image.errored)
        {
            throw new Exception("Couldn't open file " ~ input);
        }

        writefln("Opened %s", input);
        writefln(" - width      = %s", image.width);
        writefln(" - height     = %s", image.height);
        writefln(" - type       = %s", image.type);

        if (bitness == 8)
            image.convertTo8Bit();
        else if (bitness == 16)
            image.convertTo16Bit();

        bool r = result.saveToFile(output);
        if (!r)
        {
            throw new Exception("Couldn't save file " ~ output);
        }

        writefln(" => Written to %s", output);
        return 0;
    }
    catch(Exception e)
    {
        writefln("error: %s", e.message);
        usage();
        return 1;
    }
}
