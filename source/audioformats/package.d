/**
Library for sound file decoding and encoding. See README.md for licence explanations.

Copyright: Guillaume Piolats 2020.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module audioformats;


// Public API

public import audioformats.stream;


import core.stdc.stdlib: free;

nothrow @nogc:

/// Encode a slice to a WAV file.
///
/// Returns: `true` on success.
bool saveAsWAV(const(float)[] data, 
               const(char)[] filePath,
               int numChannels = 1,
               float sampleRate = 44100.0f,
               EncodingOptions options = EncodingOptions.init)
{
    return saveAsWAVImpl!float(data, filePath, numChannels, sampleRate, options);
}
///ditto
bool saveAsWAV(const(double)[] data, 
               const(char)[] filePath,
               int numChannels = 1,
               float sampleRate = 44100.0f,
               EncodingOptions options = EncodingOptions.init)
{
    return saveAsWAVImpl!double(data, filePath, numChannels, sampleRate, options);
}


/// Encode a slice to a WAV in memory.
/// The returned slice MUST be freed with `freeEncodedAudio`.
///
/// Returns: `null` in case of error.
const(ubyte)[] toWAV(const(float)[] data, 
                     int numChannels = 1,
                     float sampleRate = 44100.0f,
                     EncodingOptions options = EncodingOptions.init)
{
    return toWAVImpl!float(data, numChannels, sampleRate, options);
}
///ditto
const(ubyte)[] toWAV(const(double)[] data, 
                     int numChannels = 1,
                     float sampleRate = 44100.0f,
                     EncodingOptions options = EncodingOptions.init)
{
    return toWAVImpl!double(data, numChannels, sampleRate, options);
}


/// Disowned audio buffers (with eg. `encodeToWAV`) must be freed with this function.
void freeEncodedAudio(const(ubyte)[] encoded)
{
    free(cast(void*)encoded.ptr);
}


private:


const(ubyte)[] toWAVImpl(T)(const(T)[] data, int numChannels, float sampleRate, EncodingOptions options)
{
    assert(data !is null);
    import core.stdc.string: strlen;

    AudioStream encoder;
    encoder.openToBuffer(AudioFileFormat.wav, sampleRate, numChannels, options);
    if (encoder.isError)
        return false;
    static if (is(T == float))
        encoder.writeSamplesFloat(data);
    else
        encoder.writeSamplesDouble(data);
    if (encoder.isError)
        return false;
    const(ubyte)[] r = encoder.finalizeAndGetEncodedResultDisown();
    return r;
}

bool saveAsWAVImpl(T)(const(T)[] data, 
                      const(char)[] filePath,
                      int numChannels, 
                      float sampleRate,
                      EncodingOptions options)
{
    if (data is null)
        return false;
    if (filePath is null)
        return false;

    import core.stdc.string: strlen;

    AudioStream encoder;
    encoder.openToFile(filePath, AudioFileFormat.wav, sampleRate, numChannels, options);
    if (encoder.isError)
        return false; // opening failed

    static if (is(T == float))
        encoder.writeSamplesFloat(data);
    else
        encoder.writeSamplesDouble(data);
    if (encoder.isError)
        return false;  // writing samples failed

    encoder.flush();
    if (encoder.isError)
        return false; // flushing failed

    encoder.finalizeEncoding();
    if (encoder.isError)
        return false; // finalizing encoding failed
    return true;
}