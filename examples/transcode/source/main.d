module main;

import std.stdio;
import std.file;

import audioformats;
import dplug.core;
import core.stdc.stdlib;

void main(string[] args)
{
    if (args.length != 3)
        throw new Exception("usage: transcode input.{mp3|wav|flac|ogg|opus|mod|xm} output.wav");

    string inputPath = args[1];
    string outputPath = args[2];

    try
    {

        AudioStream input, output;

        input.openFromFile(args[1]);
        float sampleRate = input.getSamplerate();
        int channels = input.getNumChannels();
        long lengthFrames = input.getLengthInFrames();

        writefln("Opening %s:", inputPath);
        writefln("  * format     = %s", convertAudioFileFormatToString(input.getFormat()) );
        writefln("  * samplerate = %s Hz", sampleRate);
        writefln("  * channels   = %s", channels);
        if (lengthFrames == audiostreamUnknownLength)
        {
            writefln("  * length     = unknown");
        }
        else
        {
            double seconds = lengthFrames / cast(double) sampleRate;
            writefln("  * length     = %.3g seconds (%s samples)", seconds, lengthFrames);
        }

        float[] buf = new float[1024 * channels];
        output.openToFile(outputPath, AudioFileFormat.wav, sampleRate, channels);

        // Chunked encode/decode
        int totalFrames = 0;
        int framesRead;
        do
        {
            framesRead = input.readSamplesFloat(buf);
            output.writeSamplesFloat(buf[0..framesRead*channels]);
            totalFrames += framesRead;
        } while(framesRead > 0);

        output.destroy();
        
        writefln("=> %s frames decoded and encoded to %s", totalFrames, outputPath);
    }
    catch(Exception e)
    {
        writeln(e.msg);
        destroyFree(e);
    }
}