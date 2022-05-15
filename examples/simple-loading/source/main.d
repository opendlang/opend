import gamut;

static import std.file;
import std.stdio;
void main(string[] args) @trusted
{
    Image image;
  /*  image.loadFromFile("material.png");

    writefln("width x height = %s x %s", image.width, image.height);
    assert(image.width == 1252);
    assert(image.height == 974);*/

    bool success = image.loadFromMemory( std.file.read("material.png") );
    assert(success);

    writefln("width x height = %s x %s", image.width, image.height);
    assert(image.width == 1252);
    assert(image.height == 974);
}