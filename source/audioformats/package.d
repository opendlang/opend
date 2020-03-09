/// Libray for sound file decoding and encoding.
/// All operations are blocking, and should possibly be done in a thread.
module audioformats;


// <PUBLIC API>

/// Format of audio files.
enum AudioFileFormat
{
    wav, /// WAVE format
    mp3, /// MP3 format
    unknown
}

/// Opaque stream type.
alias AudioStream = void*;


enum audiostreamUnknownLength = -1;

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
AudioStreamInfo audiostreamGetInfo(AudioStream stream) nothrow @nogc
{
    AudioStreamInfo info;
    return info;
    // TODO
}

/// Returns: File format of this stream.
AudioFileFormat audiostreamGetFormat(AudioStream stream) nothrow @nogc
{
    return audiostreamGetInfo(stream).format;
}

/// Returns: File format of this stream.
int audiostreamGetNumChannels(AudioStream stream) nothrow @nogc
{
    return audiostreamGetInfo(stream).channels;
}

/// Returns: Length of this stream in frames.
/// Note: may return `audiostreamUnknownLength` if the length is unknown.
long audiostreamGetLengthInFrames(AudioStream stream) nothrow @nogc
{
    return audiostreamGetInfo(stream).lengthInFrames;
}

/// Returns: Sample-rate of this stream in Hz.
float audiostreamGetSamplerate(AudioStream stream) nothrow @nogc
{
    return audiostreamGetInfo(stream).sampleRate;
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
AudioStream audiostreamOpenFromFile(const(char)[] path) nothrow @nogc
{
    // TODO
    return null;
}

/// Opens an audio stream that decodes from memory.
/// This stream will be opened for reading only.
/// Destroy this stream with `closeAudioStream`.
/// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
///
/// Params: path An UTF-8 path to the sound file.
AudioStream audiostreamOpenFromMemory(const(ubyte)* data, int length) nothrow @nogc
{
    return null;
    // TODO
}

/// Read interleaved float samples.
/// `outData` must have enought room for `frames` * `channels` decoded samples.
int audiostreamReadSamplesFloat(AudioStream stream, float* outData, int frames) nothrow @nogc
{
    // TODO
    return 0;
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
///     sampleRate Sample rate of this audio stream. This samplerate might be rounded up to the nearest integer number.
///     numChannels Number of channels of this audio stream.
AudioStream audiostreamOpenToFile(const(char)[] path, 
                                  AudioFileFormat format,
                                  float sampleRate, 
                                  int numChannels) nothrow @nogc
{
    // TODO
    return null;
}

/// Opens an audio stream that writes to a dynamically growable output buffer.
/// This stream will be opened for writing only.
/// Access to the internal buffer after 
/// Destroy this stream with `closeAudioStream`.
/// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
///
/// Params: 
///     path An UTF-8 path to the sound file.
///     sampleRate Sample rate of this audio stream. This samplerate might be rounded up to the nearest integer number.
///     numChannels Number of channels of this audio stream.
AudioStream audiostreamOpenToBuffer(ubyte* data, 
                                    AudioFileFormat format,
                                    float sampleRate, 
                                    int numChannels) nothrow @nogc
{
    // TODO
    return null;
}

/// Opens an audio stream that writes to a pre-defined area in memory of `maxLength` bytes.
/// This stream will be opened for writing only.
/// Destroy this stream with `closeAudioStream`.
/// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
///
/// Params: 
///     path An UTF-8 path to the sound file.
///     sampleRate Sample rate of this audio stream. This samplerate might be rounded up to the nearest integer number.
///     numChannels Number of channels of this audio stream.
AudioStream audiostreamOpenToMemory(ubyte* data, 
                                    size_t maxLength,
                                    AudioFileFormat format,
                                    float sampleRate, 
                                    int numChannels) nothrow @nogc
{
    // TODO
    return null;
}

/// Write interleaved float samples.
/// `inData` must have enough data for `frames` * `channels` samples.
void audiostreamWriteSamplesFloat(AudioStream stream, float* inData, int frames) nothrow @nogc
{
    // TODO
}

/// Flush to disk all written samples, if any. 
/// hence the result is available.
/// Automatically done by `audiostreamClose`.
void audiostreamFlush(AudioStream stream) nothrow @nogc
{
    // TODO
}

/// Finalize the encoding and give access to an internal buffer that holds the whole result.
/// This buffer will have a length given by `audiostreamGetLengthInFrames`.
/// Only works if the stream was open with `audiostreamOpenToBuffer`.
void audiostreamFinalizeAndGetEncodedResult(AudioStream stream) nothrow @nogc
{
    // TODO
}


// </WRITING_API>

void audiostreamClose(AudioStream stream) nothrow @nogc
{
    audiostreamFlush(stream);
    // TODO
}


/*
/// Main resource object.
class AudioStream
{
nothrow:
@nogc:


}*/


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