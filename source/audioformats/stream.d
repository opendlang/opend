module audioformats.stream;


import audioformats: AudioStreamInfo, AudioFileFormat;

/// An AudioStream is a pointer to a dynamically allocated `Stream`.
public struct AudioStream
{
public: // This is also part of the public API
nothrow:
@nogc:
   
    void openFromFile(const(char)[] path)
    {
        // TODO
        assert(false);
    }

    void openFromMemory(const(ubyte)* data, int length)
    {        
        // TODO
        assert(false);
    }

    void openToFile(const(char)[] path, AudioFileFormat format, float sampleRate, int numChannels)
    {
        // TODO
        assert(false);
    }

    void openToBuffer(AudioFileFormat format, float sampleRate, int numChannels)
    {
        // TODO
        assert(false);
    }

    ~this()
    {
        // TODO Clean-up
    }

    /// Returns: Information about this stream.
    AudioStreamInfo getInfo()
    {
        AudioStreamInfo info;
        info.sampleRate = getSamplerate();
        info.format = getFormat();
        info.channels = getNumChannels();
        info.format = getFormat();
        return info;
    }

    /// Returns: File format of this stream.
    AudioFileFormat getFormat()
    {
        return AudioFileFormat.wav; //TODO
    }

    /// Returns: File format of this stream.
    int getNumChannels()
    {
        //return _channels; TODO
        return 2;
    }

    /// Returns: Length of this stream in frames.
    /// Note: may return `audiostreamUnknownLength` if the length is unknown.
    long getLengthInFrames()
    {
        // TODO
        return 0;
    }

    /// Returns: Sample-rate of this stream in Hz.
    float getSamplerate()
    {
        // TODO
        return 44100.0f;
    }

    /// Read interleaved float samples.
    /// `outData` must have enought room for `frames` * `channels` decoded samples.
    int readSamplesFloat(float* outData, int frames)
    {
        // TODO
        return 0;
    }

    /// Write interleaved float samples.
    /// `inData` must have enough data for `frames` * `channels` samples.
    int writeSamplesFloat(float* inData, int frames)
    {
        // TODO
        return 0;
    }

    void flush()
    {
        // TODO
        return;
    }

    const(ubyte)[] finalizeAndGetEncodedResult()
    {
        return null; // TODO
    }

private:
    IOCallbacks io;
}

private: // not meant to be imported at all

// Internal object for audio-formats


nothrow @nogc
{
    alias ioSeekCallback          = void function(long offset, void* userData);
    alias ioTellCallback          = long function(void* userData);  
    alias ioGetFileLengthCallback = long function(void* userData);
    alias ioReadCallback          = int  function(void* outData, int bytes, void* userData); // returns number of read bytes
    alias ioWriteCallback         = int  function(void* inData, int bytes, void* userData); // returns number of written bytes
}


struct IOCallbacks
{
    ioSeekCallback seek;
    ioTellCallback tell;
    ioGetFileLengthCallback getFileLength;
    ioReadCallback read;
    ioWriteCallback write;
}