module audioformats.stream;

import core.stdc.stdio;

import dplug.core.nogc;
import audioformats: AudioStreamInfo, AudioFileFormat;

/// An AudioStream is a pointer to a dynamically allocated `Stream`.
public struct AudioStream
{
public: // This is also part of the public API

    void openFromFile(const(char)[] path) @nogc
    {
        cleanUp();

        fileContext = mallocNew!FileContext();

        CString strZ = CString(path);
        fileContext.file = fopen(strZ.storage, "rb".ptr);

        // finds the size of the file
        fseek(fileContext.file, 0, SEEK_END);
        fileContext.fileSize = ftell(fileContext.file);
        fseek(fileContext.file, 0, SEEK_SET);

        io.seek          = &file_seek;
        io.tell          = &file_tell;
        io.getFileLength = &file_getFileLength;
        io.read          = &file_read;
        io.write         = null;

        // TODO
        //startDecoding();
    }

    void openFromMemory(const(ubyte)* data, int length) @nogc
    {     
        cleanUp();
        // TODO
        assert(false);
    }

    void openToFile(const(char)[] path, AudioFileFormat format, float sampleRate, int numChannels) @nogc
    {
        cleanUp();
        
        fileContext = mallocNew!FileContext();

        CString strZ = CString(path);
        fileContext.file = fopen(strZ.storage, "rb".ptr);

        // finds the size of the file
        fseek(fileContext.file, 0, SEEK_END);
        fileContext.fileSize = ftell(fileContext.file);
        fseek(fileContext.file, 0, SEEK_SET);

        io.seek          = null; //&file_seek;
        io.tell          = null; //&file_tell;
        io.getFileLength = null;
        io.read          = null;
        io.write         = &file_write;

        // TODO
        assert(false);
    }

    void openToBuffer(AudioFileFormat format, float sampleRate, int numChannels) @nogc
    {
        cleanUp();
        // TODO
        assert(false);
    }

    ~this() @nogc
    {
        cleanUp();
    }

    void cleanUp() @nogc
    {
        if (fileContext !is null)
        {
            if (fileContext.file !is null)
            {
                int result = fclose(fileContext.file);
                if (result)
                    throw mallocNew!Exception("Closing of audio file errored");            
            }
            destroyFree(fileContext);
        }
    }

    /// Returns: Information about this stream.
    AudioStreamInfo getInfo() nothrow @nogc
    {
        AudioStreamInfo info;
        info.sampleRate = getSamplerate();
        info.format = getFormat();
        info.channels = getNumChannels();
        info.format = getFormat();
        return info;
    }

    /// Returns: File format of this stream.
    AudioFileFormat getFormat() nothrow @nogc
    {
        return AudioFileFormat.wav; //TODO
    }

    /// Returns: File format of this stream.
    int getNumChannels() nothrow @nogc
    {
        //return _channels; TODO
        return 2;
    }

    /// Returns: Length of this stream in frames.
    /// Note: may return `audiostreamUnknownLength` if the length is unknown.
    long getLengthInFrames() nothrow @nogc
    {
        // TODO
        return 0;
    }

    /// Returns: Sample-rate of this stream in Hz.
    float getSamplerate() nothrow @nogc
    {
        // TODO
        return 44100.0f;
    }

    /// Read interleaved float samples.
    /// `outData` must have enought room for `frames` * `channels` decoded samples.
    int readSamplesFloat(float* outData, int frames) @nogc
    {
        // TODO
        return 0;
    }
    ///ditto
    int readSamplesFloat(float[] outData) @nogc
    {
        return readSamplesFloat(outData.ptr, cast(int)outData.length);
    }

    /// Write interleaved float samples.
    /// `inData` must have enough data for `frames` * `channels` samples.
    int writeSamplesFloat(float* inData, int frames) nothrow @nogc
    {
        // TODO
        return 0;
    }
    ///ditto
    int writeSamplesFloat(float[] inData) nothrow @nogc
    {
        return writeSamplesFloat(inData.ptr, cast(int)inData.length);
    }

    void flush() nothrow @nogc
    {
        // TODO
    }

    const(ubyte)[] finalizeAndGetEncodedResult() nothrow @nogc
    {
        return null; // TODO
    }

private:
    IOCallbacks io;
    FileContext* fileContext;
    MemoryContext* memoryContext;
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

// File callbacks
// The file callbacks are using the C stdlib.

static struct FileContext // this is what is passed to I/O when used in file mode
{
    // Used when streaming of writing a file
    FILE* file = null;

    // Size of the file in bytes, only used when reading/writing a file.
    long fileSize;
}

long file_tell(void* userData) nothrow @nogc
{
    FileContext* context = cast(FileContext*)userData;
    return ftell(context.file);
}

void file_seek(long offset, void* userData) nothrow @nogc
{
    FileContext* context = cast(FileContext*)userData;
    assert(offset <= int.max);
    fseek(context.file, cast(int)offset, SEEK_SET); // Limitations: file larger than 2gb not supported
}

long file_getFileLength(void* userData) nothrow @nogc
{
    FileContext* context = cast(FileContext*)userData;
    return context.fileSize;
}

int file_read(void* outData, int bytes, void* userData) nothrow @nogc
{
    FileContext* context = cast(FileContext*)userData;
    size_t bytesRead = fread(outData, 1, bytes, context.file);
    return cast(int)bytesRead;
}

int file_write(void* inData, int bytes, void* userData) nothrow @nogc
{
    FileContext* context = cast(FileContext*)userData;
    size_t bytesWritten = fwrite(inData, 1, bytes, context.file);
    return cast(int)bytesWritten;
}

// Memory read callback
// Using the read buffer instead

struct MemoryContext
{
    bool bufferIsOwned;
    ubyte[] buffer;
    //Vec!ubyte appendBuffer;
}
