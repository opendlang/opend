import gamut;

import std.stdio;
void main(string[] args) @trusted
{
    Image image;
    image.load("material.png");

    writefln("width x height = %s x %s", image.width, image.height);
    assert(image.width == 1252);
    assert(image.height == 974);
}