/// Libray for sound file decoding and encoding.
/// All operations are blocking, and should possibly be done in a thread.
module audioformats;

public import dplug.core.nogc: mallocNew, destroyFree;
public import audioformats.stream;

// <PUBLIC API>

/// Format of audio files.
enum AudioFileFormat
{
    wav, /// WAVE format
    mp3, /// MP3 format
    unknown
}

/// Opaque stream type. A `null` AudioStream is invalid and should never occur.
alias AudioStreamHandle = void*;

/// Information about a stream.
struct AudioStreamInfo
{
    /// Sampling rate
    float sampleRate;

    /// Number of channels.
    int channels;

    /// Length in frames. A frames is `channels` samples.
    /// A length of `audiostreamUnknownLength` is a special value that means
    /// the length is unknown, or even infinite.
    long lengthInFrames;

    /// Format of the encoded audio.
    AudioFileFormat format;
}


/// Returns: Information about this stream.
AudioStreamInfo audiostreamGetInfo(AudioStreamHandle stream) nothrow @nogc
{
    return ( cast(AudioStream*)stream ).getInfo();
}

/// Returns: File format of this stream.
AudioFileFormat audiostreamGetFormat(AudioStreamHandle stream) nothrow @nogc
{
    return ( cast(AudioStream*)stream ).getFormat();
}

/// Returns: File format of this stream.
int audiostreamGetNumChannels(AudioStreamHandle stream) nothrow @nogc
{
    return ( cast(AudioStream*)stream ).getNumChannels();
}

/// Returns: Length of this stream in frames.
/// Note: may return `audiostreamUnknownLength` if the length is unknown.
long audiostreamGetLengthInFrames(AudioStreamHandle stream) nothrow @nogc
{
    return ( cast(AudioStream*)stream ).getLengthInFrames();
}

/// Returns: Sample-rate of this stream in Hz.
float audiostreamGetSamplerate(AudioStreamHandle stream) nothrow @nogc
{
    return ( cast(AudioStream*)stream ).getSamplerate();
}


// <READING_API>

/// Opens an audio stream that decodes from a file.
/// This stream will be opened for reading only.
/// Destroy this stream with `closeAudioStream`.
///
/// Params: 
///     path An UTF-8 path to the sound file.
///
/// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
AudioStreamHandle audiostreamOpenFromFile(const(char)[] path) @nogc
{
    AudioStream* s = mallocNew!AudioStream();
    s.openFromFile(path);
    return s;
}

/// Opens an audio stream that decodes from memory.
/// This stream will be opened for reading only.
/// Destroy this stream with `closeAudioStream`.
/// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
///
/// Params: path An UTF-8 path to the sound file.
AudioStreamHandle audiostreamOpenFromMemory(const(ubyte)* data, int length) @nogc
{
    AudioStream* s = mallocNew!AudioStream();
    s.openFromMemory(data, length);
    return s;
}

/// Read interleaved float samples.
/// `outData` must have enought room for `frames` * `channels` decoded samples.
int audiostreamReadSamplesFloat(AudioStreamHandle stream, float* outData, int frames) @nogc
{
    return ( cast(AudioStream*)stream ).readSamplesFloat(outData, frames);
}
///ditto
int audiostreamReadSamplesFloat(AudioStreamHandle stream, float[] outData) @nogc
{
    return ( cast(AudioStream*)stream ).readSamplesFloat(outData);
}

// </READING_API>


// <WRITING_API>

/// Opens an audio stream that writes to file.
/// This stream will be opened for writing only.
/// Destroy this stream with `closeAudioStream`.
/// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
///
/// Params: 
///     path An UTF-8 path to the sound file.
///     format Audio file format to generate.
///     sampleRate Sample rate of this audio stream. This samplerate might be rounded up to the nearest integer number.
///     numChannels Number of channels of this audio stream.
AudioStreamHandle audiostreamOpenToFile(const(char)[] path, 
                                        AudioFileFormat format,
                                        float sampleRate, 
                                        int numChannels) @nogc
{
    AudioStream* s = mallocNew!AudioStream();
    s.openToFile(path, format, sampleRate, numChannels);
    return s;
}

/// Opens an audio stream that writes to a dynamically growable internal buffer.
/// This stream will be opened for writing only.
/// Access to the internal buffer after encoding with `audiostreamFinalizeAndGetEncodedResult`.
/// Destroy this stream with `closeAudioStream`.
/// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
///
/// Params: 
///     format Audio file format to generate.
///     sampleRate Sample rate of this audio stream. This samplerate might be rounded up to the nearest integer number.
///     numChannels Number of channels of this audio stream.
AudioStreamHandle audiostreamOpenToBuffer(AudioFileFormat format,
                                          float sampleRate, 
                                          int numChannels) @nogc
{
    AudioStream* s = mallocNew!AudioStream();
    s.openToBuffer(format, sampleRate, numChannels);
    return s;
}

/// Opens an audio stream that writes to a pre-defined area in memory of `maxLength` bytes.
/// This stream will be opened for writing only.
/// Destroy this stream with `closeAudioStream`.
/// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
///
/// Params: 
///     data Pointer to output memory.
///     size_t maxLength.
///     format Audio file format to generate.
///     sampleRate Sample rate of this audio stream. This samplerate might be rounded up to the nearest integer number.
///     numChannels Number of channels of this audio stream.
AudioStreamHandle audiostreamOpenToMemory(ubyte* data, 
                                          size_t maxLength,
                                          AudioFileFormat format,
                                          float sampleRate, 
                                          int numChannels) @nogc
{
    AudioStream* s = mallocNew!AudioStream();
    s.openToMemory(data, maxLength, format, sampleRate, numChannels);
    return s;
}

/// Write interleaved float samples.
/// `inData` must have enough data for `frames` * `channels` samples.
int audiostreamWriteSamplesFloat(AudioStreamHandle stream, float* inData, int frames) nothrow @nogc
{
    return ( cast(AudioStream*)stream ).writeSamplesFloat(inData, frames);
}
///ditto
int audiostreamWriteSamplesFloat(AudioStreamHandle stream, float[] inData) nothrow @nogc
{
    return ( cast(AudioStream*)stream ).writeSamplesFloat(inData);
}

/// Flush to disk all written samples, if any. 
/// hence the result is available.
/// Automatically done by `audiostreamClose`.
void audiostreamFlush(AudioStreamHandle stream) nothrow @nogc
{
    return ( cast(AudioStream*)stream ).flush();
}

/// Finalize the encoding and give access to an internal buffer that holds the whole result.
/// This buffer will have a byte length given by `audiostreamGetLengthInFrames` x channels.
/// Only works if the stream was open with `audiostreamOpenToBuffer`.
const(ubyte)[] audiostreamFinalizeAndGetEncodedResult(AudioStreamHandle stream) nothrow @nogc
{
    return ( cast(AudioStream*)stream ).finalizeAndGetEncodedResult();
}


// </WRITING_API>

void audiostreamClose(AudioStreamHandle stream) nothrow @nogc
{
    destroyFree( cast(AudioStream*)stream );
}



// </PUBLIC API>



private:


enum AudioSampleFormat
{
    pcm8bitSigned,
    pcm8bitUnsigned,
    pcm16bitSigned,
    pcm16bitUnsigned,
    pcm24bitSigned,
    pcm24bitUnsigned,
    pcm32bitFloat,
    pcm64bitFloat
}