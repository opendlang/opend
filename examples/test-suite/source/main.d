module main;

import core.stdc.stdlib;
import std.stdio;
import std.file;
import gamut;
import gamut.codecs.pngload;

void main(string[] args)
{ 
    testDecodingVSTLogo();
    testIssue35();
    testIssue46();
    testReallocSpeed();
    testCGBI();
}

void testIssue35()
{
    Image image;
    image.loadFromFile("test-images/issue35.jpg", LOAD_RGB | LOAD_8BIT | LOAD_ALPHA | LAYOUT_VERT_STRAIGHT | LAYOUT_GAPLESS);
    assert(!image.isError);
    image.saveToFile("output/issue35.png");
}

// should not fail while loading an empty file, and report an error instead
void testIssue46()
{
    Image image;
    image.loadFromFile("test-images/issue46.jpg");
    assert(image.isError);

    image.loadFromFile("test-images/issue35.jpg");
    assert(!image.isError);

    image.loadFromFile("test-images/issue46.jpg");
    assert(image.isError);
}

void testDecodingVSTLogo()
{
    Image image;
    image.loadFromFile("test-images/vst3-compatible.png");
    assert(!image.isError);

    // Test decoding of first problem chunk in the image
    char[] bytes = cast(char[]) std.file.read("test-images/buggy-miniz-chunk.bin");
    assert(bytes.length == 25568);

    // initial_size is 594825, but more is returned by inflate, 594825 + 272 with both miniz and stbz
    // with stb_image, buffer is extended. But Miniz doesn't seem to support that.

    int initial_size = 594825;
    int outlen;
    ubyte* buf = stbi_zlib_decode_malloc_guesssize_headerflag(bytes.ptr, 25568, initial_size, &outlen, 1);
    assert(buf !is null);
    assert(outlen == 594825 + 272);
    free(buf);
}

void testCGBI()
{
    // Load an iPhone PNG, saves a normal PNG
    Image image;
    image.loadFromFile("test-images/issue51cgbi.png");
    assert(!image.isError);
    image.saveToFile("output/issue51cbgi.png");

    image.loadFromFile("test-images/issue51cgbi2.png");
    assert(!image.isError);
    image.saveToFile("output/issue51cbgi2.png");
}

void testReallocSpeed()
{
    Clock a;
    a.initialize();

    Image image;


    long testRealloc(long delegate(int i) pure nothrow @nogc @safe getWidth, long delegate(int i) getHeight)
    {
        long before = a.getTickUs();
        foreach(n; 0..100)
        {
            foreach(i; 0..256)
            {
                int width  = cast(int) getWidth(cast(int)i);
                int height = cast(int) getHeight(cast(int)i);
                image.setStorage(width, height,PixelType.rgba8, 0, false);
            }
        }
        long after = a.getTickUs();
        return after - before;
    }

    writefln("image sizing with fixed      size = %s", testRealloc( i => 256, 
                                                                    j => 256 ) );
    writefln("image sizing with increasing size = %s", testRealloc( i => 1 + i, 
                                                                    j => 1 + j ) );
    writefln("image sizing with decreasing size = %s", testRealloc( (int j){ return (256 - j); }, 
                                                                    (int j){ return (256 - j); } ));
    writefln("image sizing with random     size = %s", testRealloc( (int i){ return 1 + ((i * cast(long)24986598365983) & 255); }, 
                                                                    (int i){ return 1 + ((i * cast(long)24986598421) & 255); } ));


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
