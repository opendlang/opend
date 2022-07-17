module main;

import std.stdio;
import gamut;


void usage()
{
    writeln("Decode image metadata, but not the pixels themselves");
    writeln;
    writeln("Usage: metadata input.ext\n");
    writeln;
    writeln("  -h           Shows this help");
    writeln;
}

int main(string[] args)
{
    try
    {
        string input = null;
        bool help = false;

        for(int i = 1; i < args.length; ++i)
        {
            string arg = args[i];
            if (arg == "-h")
            {
                help = true;
            }
            else
            {
                if (input)
                {
                    throw new Exception("Too many files provided");
                }
                else
                    input = arg;
            }
        }

        if (help || input is null)
        {
            usage();
            return 0;
        }

        Image image;  
        image.loadFromFile(input);

        writefln("X resolution (DPI) = %s", image.dotsPerInchX());
        writefln("Y resolution (DPI) = %s", image.dotsPerInchY());
        writefln("X resolution (PPM) = %s", image.pixelsPerMeterX());
        writefln("Y resolution (PPM) = %s", image.pixelsPerMeterY());

        return 0;
    }
    catch(Exception e)
    {
        writefln("error: %s", e.message);
        usage();
        return 1;
    }
}
