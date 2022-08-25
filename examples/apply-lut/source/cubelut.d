module cubelut;

import std.stdio;
import std.string;
import std.conv;
import core.stdc.stdio;

/// A 3D LUT can be applied to floating-point images.
struct LUT
{
    string title;
    float[4][] table;
    int size;

    void readFromCubeFile(string path) // provide .cube file
    {
        auto file = File(path, "r");

        int point = 0;
        int numPoints = 0;
        size = 0; // unknown

        // index to write
        int ix = 0;
        int iy = 0;
        int iz = 0;

        string line;
        while ((line = file.readln()) !is null)
        {
            // chomp end of line
            if (line.length > 0 && line[$-1] == '\n')
                line = line[0..$-1];
            if (line.length > 0 && line[$-1] == '\r')
                line = line[0..$-1];

            if (line.length == 0)
                continue;
            else if (line[0] == '#')
            {
                // comment
                continue;
            }
            else if (line.startsWith("DOMAIN_MIN"))
            {
                // ignore
            }
            else if (line.startsWith("DOMAIN_MAX"))
            {
                // ignore
            }
            else if (line.startsWith("TITLE"))
            {
                title = line[6..$];
            }
            else if (line.startsWith("LUT_3D_SIZE"))
            {
                // init LUT size
                size = to!int(line[12..$]);
                table.length = size * size * size;
                table[] = [0.0f, 0.0f, 0.0f, 0.0f];
                numPoints = size * size * size;
            }
            else
            {
                if (point < numPoints)
                {
                    // Read rgb triplet with sncanf

                    string lineZT = line ~ '\0';
                    float r = 0, g = 0, b = 0, a = 0;

                    if (3 == sscanf(line.ptr, "%f %f %f".ptr, &r, &g, &b))
                    {
                        table[point] = [r, g, b, a];
                        point++;
                    }
                    // else input error, TODO fail                    
                }
            }
        }
        file.close();

    }

    void processScanline(float[4]* pixels, int width)
    {
        for (int x = 0; x < width; ++x)
        {
            float[4] pixel = pixels[x]; // TODO: clamp somewhere

            float fr = pixel[0] * (size - 1);
            float fg = pixel[1] * (size - 1);
            float fb = pixel[2] * (size - 1);
            if (fr < 0) fr = 0;
            if (fg < 0) fg = 0;
            if (fb < 0) fb = 0;

            // TODO linear sampling with 8 integer samples

            int ir = cast(int)(fr + 0.5f);
            int ig = cast(int)(fg + 0.5f);
            int ib = cast(int)(fb + 0.5f);

            float[4] mapped = table[ir + ig * size + ib * size * size];
            pixel[0] = mapped[0];
            pixel[1] = mapped[1];
            pixel[2] = mapped[2]; // do not touch original alpha

            pixels[x] = pixel;
        }
    }
}