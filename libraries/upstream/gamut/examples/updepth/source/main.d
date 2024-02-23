module main;

import std.stdio;
import gamut;


void usage()
{
    writeln("Convert Dplug old-style RGB8 depth images into 10-bit QOIX, which will load faster.");
    writeln;
    writeln("Usage: updepth depth.png depth.qoix\n");
    writeln;
    writeln("Params:");
    writeln("  -i           Specify an input file");
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

        Image image = loadOwnedImageDepth(input);

        if (image.isError)
        {
            throw new Exception("Couldn't convert file " ~ input);
        }

        image.convertTo16Bit();
        writeln;
        writefln("Converted to %s", input);
        writefln(" - width      = %s", image.width);
        writefln(" - height     = %s", image.height);
        writefln(" - type       = %s", image.type);

        bool r = image.saveToFile(output);
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

/// Old-style Dplug loading for RGB8 image.
/// The idea at the time was to offset R, G and B to gain approx 1 bit of precision once they would be merged.
Image loadOwnedImageDepth(string inputFile)
{
    Image image;
    image.loadFromFile(inputFile, LOAD_NO_ALPHA);
    if (image.isError)
    {
        assert(false, "Decoding failed");
    }

    writefln("Opened %s", inputFile);
    writefln(" - width      = %s", image.width);
    writefln(" - height     = %s", image.height);
    writefln(" - type       = %s", image.type);

    if (image.type() == PixelType.rgb8)
    {
        // Legacy 8-bit to 16-bit depth conversion
        // This is the original legacy way to load depth.
        // Load as 8-bit RGBA, then mix the channels so as to support
        // legacy depth maps.
        Image image16;
        image16.setSize(image.width, image.height, PixelType.l16);
        int width = image.width;
        int height = image.height;

        for (int j = 0; j < height; ++j)
        {
            ubyte* inDepth = cast(ubyte*) image.scanline(j);
            ushort* outDepth = cast(ushort*) image16.scanline(j);

            for (int i = 0; i < width; ++i)
            {
                // Using 257 to span the full range of depth: 257 * (255+255+255)/3 = 65535
                // If we do that inside stb_image, it will first reduce channels _then_ increase bitdepth.
                // Instead, this is used to gain 1.5 bit of accuracy for 8-bit depth maps. :)
                float d = 0.5f + 257 * (inDepth[3*i+0] + inDepth[3*i+1] + inDepth[3*i+2]) / 3; 
                outDepth[i] = cast(ushort)(d);
            }
        }
        return image16;
    }
    else
    {
        assert(false);
    }
}