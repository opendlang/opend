module main;

import std.stdio;
import std.file;
import gamut;

void main(string[] args)
{ 
  //  testIssue35();
    testReallocSpeed();
}

void testIssue35()
{
    Image image;
    image.loadFromFile("test-images/issue35.jpg", LOAD_RGB | LOAD_8BIT | LOAD_ALPHA | LAYOUT_VERT_STRAIGHT | LAYOUT_GAPLESS);
    assert(!image.isError);
    image.saveToFile("output/issue35.png");
}

void testReallocSpeed()
{
    Clock a;
    a.initialize();

    Image image;

    long before = a.getTickUs();

    foreach(n; 0..1)
    {
        foreach(i; 0..4095)
        {
            int width = 2048;
            int height = 2048;
            image.setStorage(width,  // TEMP public
                             height,PixelType.rgba8, 
                             0,
                             false);
        }
    }
    long after = a.getTickUs();
    writefln("temps = %s", after - before);


}

version(Windows)
{
    import core.sys.windows.windows;
}


struct Clock
{
    nothrow @nogc:

    void initialize()
    {
        version(Windows)
        {
            QueryPerformanceFrequency(&_qpcFrequency);
        }
    }

    /// Get us timestamp.
    /// Must be thread-safe.
    // It doesn't handle wrap-around superbly.
    long getTickUs() nothrow @nogc
    {
        version(Windows)
        {
            import core.sys.windows.windows;
            LARGE_INTEGER lint;
            QueryPerformanceCounter(&lint);
            double seconds = lint.QuadPart / cast(double)(_qpcFrequency.QuadPart);
            long us = cast(long)(seconds * 1_000_000);
            return us;
        }
        else
        {
            import core.time;
            return convClockFreq(MonoTime.currTime.ticks, MonoTime.ticksPerSecond, 1_000_000);
        }
    }

private:
    version(Windows)
    {
        LARGE_INTEGER _qpcFrequency;
    }
}
