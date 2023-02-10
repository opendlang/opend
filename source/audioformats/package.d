/**
Library for sound file decoding and encoding. See README.md for licence explanations.

Copyright: Guillaume Piolats 2020.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module audioformats;


// Public API

public import audioformats.stream;


public import audioformats.internals: AudioFormatsException;
import core.stdc.stdlib: free;

/// Frees an exception thrown by audio-formats.
void destroyAudioFormatException(AudioFormatsException e) nothrow @nogc
{
    import audioformats.internals;
    destroyFree!AudioFormatsException(e);
}


/// Encode a slice to a WAV file.
///
/// Returns: `true` on success.
bool saveAsWAV(const(float)[] data, 
               const(char)[] filePath,
               int numChannels = 1,
               float sampleRate = 44100.0f,
               EncodingOptions options = EncodingOptions.init) nothrow @nogc
{
    return saveAsWAVImpl!float(data, filePath, numChannels, sampleRate, options);
}
///ditto
bool saveAsWAV(const(double)[] data, 
               const(char)[] filePath,
               int numChannels = 1,
               float sampleRate = 44100.0f,
               EncodingOptions options = EncodingOptions.init) nothrow @nogc
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
                     EncodingOptions options = EncodingOptions.init) nothrow @nogc
{
    return toWAVImpl!float(data, numChannels, sampleRate, options);
}
///ditto
const(ubyte)[] toWAV(const(double)[] data, 
                     int numChannels = 1,
                     float sampleRate = 44100.0f,
                     EncodingOptions options = EncodingOptions.init) nothrow @nogc
{
    return toWAVImpl!double(data, numChannels, sampleRate, options);
}


/// Disowned audio buffers (with eg. `encodeToWAV`) must be freed with this function.
void freeEncodedAudio(const(ubyte)[] encoded)
{
    free(cast(void*)encoded.ptr);
}


private:


const(ubyte)[] toWAVImpl(T)(const(T)[] data, int numChannels, float sampleRate, EncodingOptions options) nothrow @nogc
{
    assert(data !is null);
    import core.stdc.string: strlen;

    try
    {
        AudioStream encoder;
        encoder.openToBuffer(AudioFileFormat.wav, sampleRate, numChannels, options);
        static if (is(T == float))
            encoder.writeSamplesFloat(data);
        else
            encoder.writeSamplesDouble(data);
        const(ubyte)[] r = encoder.finalizeAndGetEncodedResultDisown();
        return r;
    }
    catch (AudioFormatsException e)
    {
        destroyAudioFormatException(e);
        return null;
    }
    catch(Exception e)
    {
        return null;
    }
}

bool saveAsWAVImpl(T)(const(T)[] data, 
                      const(char)[] filePath,
                      int numChannels, 
                      float sampleRate,
                      EncodingOptions options) nothrow @nogc
{
    if (data is null)
        return false;
    if (filePath is null)
        return false;

    import core.stdc.string: strlen;

    try
    {
        AudioStream encoder;
        encoder.openToFile(filePath, AudioFileFormat.wav, sampleRate, numChannels, options);
        static if (is(T == float))
            encoder.writeSamplesFloat(data);
        else
            encoder.writeSamplesDouble(data);
        encoder.flush();
        encoder.finalizeEncoding();
    }
    catch (AudioFormatsException e)
    {
        destroyAudioFormatException(e);
        return false;
    }
    catch(Exception e)
    {
        return false;
    }
    return true;
}