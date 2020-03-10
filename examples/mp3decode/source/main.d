module main;

import std.stdio;
import audioformats;

/// Usage: mp3decode source.mp3 output.wav
void main(string[] args)
{
    if (args.length != 3)
        throw new Exception("usage: mp3decode input.mp3 output.wav");
    AudioStream input, output;

    input.openFromFile(args[1]);

    float sampleRate = input.getSamplerate();
    int channels = input.getNumChannels();
    long length = input.getLengthInFrames();

    float[] buf = new float[1024 * channels];

    output.openToFile(args[2], AudioFileFormat.wav, sampleRate, channels);

    // Chunked encore/decode
    int read;
    do
    {
        read = input.readSamplesFloat(buf);
        output.writeSamplesFloat(buf[0..read]);
    } while(read > 0);
}