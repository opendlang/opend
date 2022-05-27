import gamut;

static import std.file;
import std.stdio;


long getTickMs() nothrow @nogc @safe
{
    import core.time;
    return convClockFreq(MonoTime.currTime.ticks, MonoTime.ticksPerSecond, 1_000);
}


void main(string[] args) @safe
{
    Image image;

    long tBefore = getTickMs();
    image.loadFromFile("material.png");
    long tAfter = getTickMs();

    writefln("Loaded material.png from file, in %s ms", tAfter - tBefore);
    writefln("  => width x height = %s x %s", image.width, image.height);
    assert(image.width == 1252);
    assert(image.height == 974);

    void[] data = std.file.read("material.png");
    tBefore = getTickMs();
    bool success = image.loadFromMemory( data );
    tAfter = getTickMs();
    assert(success);

    writefln("Loaded material.png from memory, in %s ms", tAfter - tBefore);
    writefln("  => width x height = %s x %s", image.width, image.height);
    assert(image.width == 1252);
    assert(image.height == 974);
}