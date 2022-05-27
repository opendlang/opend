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
    image.loadFromFile("diffuse.jpg");
    long tAfter = getTickMs();

    writefln("Loaded diffuse.jpg from file, in %s ms", tAfter - tBefore);
    writefln("  => width x height = %s x %s", image.width, image.height);

    void[] data = std.file.read("diffuse.jpg");
    tBefore = getTickMs();
    bool success = image.loadFromMemory( data );
    tAfter = getTickMs();
    assert(success);

    writefln("Loaded diffuse.jpg from memory, in %s ms", tAfter - tBefore);
    writefln("  => width x height = %s x %s", image.width, image.height);
}