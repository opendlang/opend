module main;

import std.stdio;
import std.array;
import std.algorithm;
import std.file;
import std.conv;
import std.path;

import gamut;
import cubelut;

void usage()
{
    writeln("Apply a suite of LUT to one image. Place .cube files in LUTs/ directory.");
    writeln;
    writeln("Usage: apply-lut image.ext\n");
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
            if (arg == "--help")
            {
                help = true;
            }
            else
            {
                if (input !is null)
                {
                    throw new Exception("Too many input images provided");
                }
                input = arg;
            }
        }

        if (help || input is null)
        {
            usage();
            return 0;
        }       

        // Find all LUTs
        auto cubeFiles = filter!`endsWith(a.name,".cube")`(dirEntries("LUTs",SpanMode.depth)).array;
        if (cubeFiles.length == 0)
        {
            writeln("No LUTs found in LUTs/");
            return 1;
        }

        foreach(cubeFile; cubeFiles)
        {
            writefln("*** Using LUT %s", cubeFile);
            LUT lut;
            lut.readFromCubeFile(cubeFile);

            // Read original image
            
            Image image;
            image.loadFromFile(input);
            if (image.errored)
                throw new Exception(to!string(image.errorMessage));

            PixelType origType = image.type();
            PixelType targetType = convertPixelTypeToRGB(origType); // because a greyscale image is not grayscale after a 3D LUT

            image.convertTo(PixelType.rgbaf32);


            // Process each scanline
            assert(image.type == PixelType.rgbaf32);
            assert(image.hasData());

            for (int y = 0; y < image.height(); ++y)
            {
                float[4]* scan = cast(float[4]*) image.scanline(y);
                lut.processScanline(scan, image.width);
            }

            // Convert to target type.
            image.convertTo(targetType);

            string outputFile = "output/" ~ stripExtension(baseName(cubeFile)) ~ ".png";
            bool r = image.saveToFile(outputFile);
            if (!r)
            {
                throw new Exception("Couldn't save output file.");
            }
            writefln(" => Written to %s", outputFile);
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
