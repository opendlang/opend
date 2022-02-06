module main;

import std.stdio;
import std.file;

import audioformats;
import dplug.core;
import core.stdc.stdlib;


//debug = checkSeeking;

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
            writefln("  * length     = %.3g seconds (%s frames)", seconds, lengthFrames);
        }

        debug(checkSeeking) additionalTests(input);

        float[] buf = new float[1024 * channels];

        EncodingOptions options;
        options.sampleFormat = AudioSampleFormat.s24;
        options.enableDither = true;

        output.openToFile(outputPath, AudioFileFormat.wav, sampleRate, channels, options);

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

debug(checkSeeking)
{
    // For audio-formats debug purpose.
    void additionalTests(ref AudioStream input)
    {
        int channels = input.getNumChannels();
        long lengthFrames = input.getLengthInFrames();
        if (lengthFrames == audiostreamUnknownLength)
            return;

        int maxFrame = cast(int) lengthFrames;

        // Check that seeking work
        if (input.canSeek() && !input.isModule())
        {
            assert(input.tellPosition() == 0);

            // Seeking at beginning is always legal.
            bool res = input.seekPosition(0);
            assert(res && input.tellPosition() == 0);

            // Seeking past the end is illegal and is a no-op
            res = input.seekPosition(maxFrame + 1);
            assert(!res && input.tellPosition() == 0);

            // Seeking before beginning is illegal and is a no-op
            res = input.seekPosition(-1);
            assert(!res && input.tellPosition() == 0);

            // Seeking in the middle is of course legal
            {
                int where = maxFrame / 2;
                res = input.seekPosition(where);
                int here = input.tellPosition();
                assert(res && here == where);
            }

            // It is legal to seek just before the end.
            if (maxFrame > 0)
            {
                res = input.seekPosition(maxFrame - 1);
                int pos = input.tellPosition();
                assert(res && pos == maxFrame - 1);

                AudioFileFormat fmt = input.getFormat();
                {
                    // Where the remaining decoding should yield one frame
                    float[] smallbuf = new float[16 * channels];
                    int read = input.readSamplesFloat(smallbuf);
                    assert(read == 1);

                    res = input.seekPosition(maxFrame);
                    pos = input.tellPosition();
                    assert(res && pos == maxFrame);
                    // Where the remaining decoding should yield 0 frame
                    read = input.readSamplesFloat(smallbuf);
                    assert(read == 0);

                    // And at this point we cannot seek to beginning in OGG, since stream is finished (has returned 0 samples).
                }
            }

            // Come back at start
, read 16 frames.
            res = input.seekPosition(0);
            assert(res && input.tellPosition() == 0);
            {
                float[] smallbuf = new float[16 * channels];
                int read = input.readSamplesFloat(smallbuf);
                assert(read == 16);
            }
            res = input.seekPosition(0);
        }
    }
}