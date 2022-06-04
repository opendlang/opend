module main;

import std.stdio;
import gamut;


void usage()
{
    writeln();
    writeln("Usage: convert [-i input.png|jpg] [-bitness {8|16|auto}] output.png\n");
    writeln();
    writeln("Params:");
    writeln("  -i           Specify an input file");
    writeln("  -bitness     Change bitness of file");
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
            if (arg == "-i")
            {
                if (input)
                    throw new Exception("Multiple input files provided");
                ++i;
                input = args[i];
            }
            else if (arg == "-bitness")
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
                if (output)
                    throw new Exception("Multiple ouput filesprovided");
                output = arg;
            }
        }

        if (help)
        {
            usage();
            return 0;
        }

        Image image;
        Image* result = &image;

        image.loadFromFile(input);
        if (!image.isValid)
        {
            throw new Exception("Couldn't open file " ~ input);
        }

        /*Image converted;
        if (bitness == 8)
        {
            converted = image.convertToRGBA8();
            result = &converted;
        }
        if (bitness == 16)
        {
            converted = image.convertToRGBA16();
            result = &converted;
        }*/

        bool r = result.saveToFile(output);  
        if (!r)
        {
            throw new Exception("Couldn't save file " ~ output);
        }
        return 0;
    }
    catch(Exception e)
    {
        writefln("error: %s", e.message);
        usage();
        return 1;
    }
}
