module main;

import std.stdio;
import std.file;
import std.conv;
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

        ubyte[] png_encoded;
        double png_encode_ms = measure( { png_encoded = image.saveToMemory(ImageFormat.PNG); } );
        double png_size_kb = png_encoded.length / 1024.0;
        double png_decode_ms = measure( { image.loadFromMemory(png_encoded); } );
        double png_encode_mpps = (width * height * 1.0e-6) / (png_encode_ms * 0.001);
        double png_decode_mpps = (width * height * 1.0e-6) / (png_decode_ms * 0.001);


        writefln("       decode ms   encode ms   decode mpps   encode mpps   size kb   rate");
        writefln("png     %8.1f    %8.1f      %8.2f      %8.2f  %8.2f   %4.1f", png_decode_ms, png_encode_ms, png_decode_mpps, png_encode_mpps, png_size_kb, 1.0);

        image.loadFromFile(f);

        ubyte[] qoi_encoded;
        double qoi_encode_ms = measure( { qoi_encoded = image.saveToMemory(ImageFormat.QOI); } );
        double qoi_size_kb = qoi_encoded.length / 1024.0;
        double qoi_decode_ms = measure( { image.loadFromMemory(qoi_encoded); } );
        double qoi_encode_mpps = (width * height * 1.0e-6) / (qoi_encode_ms * 0.001);
        double qoi_decode_mpps = (width * height * 1.0e-6) / (qoi_decode_ms * 0.001);
        double qoi_rate = qoi_size_kb / png_size_kb;

        writefln("qoi     %8.1f    %8.1f      %8.2f      %8.2f  %8.2f   %4.1f", qoi_decode_ms, qoi_encode_ms, qoi_decode_mpps, qoi_encode_mpps, qoi_size_kb, qoi_rate);

        if (image.errored)
            throw new Exception(to!string(image.errorMessage));

        ubyte[] qoix_encoded;
        double qoix_encode_ms = measure( { qoix_encoded = image.saveToMemory(ImageFormat.QOIX); } );
        double qoix_size_kb = qoix_encoded.length / 1024.0;
        double qoix_decode_ms = measure( { image.loadFromMemory(qoix_encoded); } );
        double qoix_encode_mpps = (width * height * 1.0e-6) / (qoix_encode_ms * 0.001);
        double qoix_decode_mpps = (width * height * 1.0e-6) / (qoix_decode_ms * 0.001);
        double qoix_rate = qoix_size_kb / png_size_kb;

        writefln("qoix    %8.1f    %8.1f      %8.2f      %8.2f  %8.2f   %4.1f", qoix_decode_ms, qoix_encode_ms, qoix_decode_mpps, qoix_encode_mpps, qoix_size_kb, qoix_rate);

        free(qoi_encoded.ptr);
        free(qoix_encoded.ptr);
        free(png_encoded.ptr);
    }
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