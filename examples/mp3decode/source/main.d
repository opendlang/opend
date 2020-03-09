module main;

import std.stdio;
import minimp3;
import waved;

/// Usage: mp3decode source.mp3 output.wav
void main(string[] args)
{
    AudioStream input, output;

    input.openFromFile(args[1]);

    float sampleRate = input.getSampleRate();
    int channels = input.getChannels();
    long length = input.getLengthInFrames();

    float[] buf = new float[1024 * input.getChannels()];

    output.openToFile(args[1], AudioFileFormat.wav, sampleRate, numChannels);

    // Chunked encore/decode
    int read;
    while(read = input.readSamplesFloat(buf.ptr, buf.length) )
    {
    	output.writeSamplesFloat(buf.ptr, read);
    }
}