module main;

import std.stdio;
import std.file;
import std.conv;
import std.path;
import std.string;
import std.algorithm;
import gamut;
import core.stdc.stdlib: free;

void usage()
{
    writeln();
    writeln("Usage: qoix\n");
    writeln("   This just run the test suite.");
    writeln;
}

int main(string[] args)
{    
    // Encore all image in test suite in QOI
    auto files = filter!`endsWith(a.name,".png")`(dirEntries("test-images",SpanMode.depth));

    double mean_encode_mpps = 0;
    double mean_decode_mpps = 0;
    double mean_bpp = 0;

    int N = 0;
    foreach(f; files)
    {
        writeln();
        writeln(f);

        Image image;
        image.loadFromFile(f);
        if (image.errored)
            throw new Exception(to!string(image.errorMessage));
        if (image.type == ImageType.uint8)
            image.convertTo(ImageType.rgb8);

        if (image.errored)
            throw new Exception(to!string(image.errorMessage));

        int width = image.width;
        int height = image.height;

        if (image.errored)
            throw new Exception(to!string(image.errorMessage));

        ubyte[] qoix_encoded;
        double qoix_encode_ms = measure( { qoix_encoded = image.saveToMemory(ImageFormat.QOIX); } );
        scope(exit) free(qoix_encoded.ptr);
        double qoix_size_kb = qoix_encoded.length / 1024.0;
        double qoix_decode_ms = measure( { image.loadFromMemory(qoix_encoded); } );
        double qoix_encode_mpps = (width * height * 1.0e-6) / (qoix_encode_ms * 0.001);
        double qoix_decode_mpps = (width * height * 1.0e-6) / (qoix_decode_ms * 0.001);
        double bit_per_pixel = (qoix_encoded.length * 8.0) / (width * height);

        mean_encode_mpps += qoix_encode_mpps;
        mean_decode_mpps += qoix_decode_mpps;
        mean_bpp += bit_per_pixel;

        writefln("       decode mpps   encode mpps      bit-per-pixel");
        writefln("          %8.2f      %8.2f           %8.5f", qoix_decode_mpps, qoix_encode_mpps, bit_per_pixel);
        N += 1;

        // Check encoding is properly done.
        {
            Image image2;
            image2.loadFromMemory(qoix_encoded);
            string path = "output/" ~ baseName(f) ~ ".png";
            image2.saveToFile(path, ImageFormat.PNG);
        }
    }
    mean_encode_mpps /= N;
    mean_decode_mpps /= N;
    mean_bpp /= N;
    writefln("\nTOTAL  decode mpps   encode mpps      bit-per-pixel");
    writefln("          %8.2f      %8.2f           %8.5f", mean_decode_mpps, mean_encode_mpps, mean_bpp);
   

    return 0;
}

long getTickUs() nothrow @nogc
{
    import core.time;
    return convClockFreq(MonoTime.currTime.ticks, MonoTime.ticksPerSecond, 1_000_000);
}



double measure(void  delegate() nothrow @nogc dg) nothrow @nogc
{
    long A = getTickUs();
    dg();
    long B = getTickUs();
    return cast(double)( (B - A) / 1000.0 );
}