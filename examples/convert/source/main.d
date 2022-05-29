module main;

import std.stdio;
import gamut;

void main(string[] args)
{
    if (args.length != 3)
        throw new Exception("usage: convert input.{png|jpg} output.png");

    string inputPath = args[1];
    string outputPath = args[2];

    Image image;

    image.loadFromFile(inputPath);
    if (!image.isValid)
    {
        throw new Exception("Couldn't open " ~ inputPath);
    }

    bool r = image.saveToFile(outputPath);  
    if (!r)
    {
        throw new Exception("Couldn't save " ~ outputPath);
    }
}
