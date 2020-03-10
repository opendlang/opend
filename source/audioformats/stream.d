module audioformats.stream;

import core.stdc.stdio;

import dplug.core.nogc;

import audioformats: AudioStreamInfo, AudioFileFormat;

/// An AudioStream is a pointer to a dynamically allocated `Stream`.
public struct AudioStream
{
public: // This is also part of the public API


    /// Opens an audio stream that decodes from a file.
    /// This stream will be opened for reading only.
    ///
    /// Params: 
    ///     path An UTF-8 path to the sound file.
    ///
    /// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
    void openFromFile(const(char)[] path) @nogc
    {
        cleanUp();

        fileContext = mallocNew!FileContext();
        fileContext.initialize(path, false);

        io.seek          = &file_seek;
        io.tell          = &file_tell;
        io.getFileLength = &file_getFileLength;
        io.read          = &file_read;
        io.write         = null;

        startDecoding();
    }

    /// Opens an audio stream that decodes from memory.
    /// This stream will be opened for reading only.
    /// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
    ///
    /// Params: path An UTF-8 path to the sound file.
    void openFromMemory(const(ubyte)* data, int length) @nogc
    {     
        cleanUp();

        memoryContext = mallocNew!MemoryContext();


        io.seek          = &memory_seek;
        io.tell          = &memory_tell;
        io.getFileLength = &memory_getFileLength;
        io.read          = &memory_read;
        io.write         = null;

        startDecoding();
    }

    /// Opens an audio stream that writes to file.
    /// This stream will be opened for writing only.
    /// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
    ///
    /// Params: 
    ///     path An UTF-8 path to the sound file.
    ///     format Audio file format to generate.
    ///     sampleRate Sample rate of this audio stream. This samplerate might be rounded up to the nearest integer number.
    ///     numChannels Number of channels of this audio stream.
    void openToFile(const(char)[] path, AudioFileFormat format, float sampleRate, int numChannels) @nogc
    {
        cleanUp();
        
        fileContext = mallocNew!FileContext();
        fileContext.initialize(path, true);

        io.seek          = &file_seek;
        io.tell          = &file_tell;
        io.getFileLength = null;
        io.read          = null;
        io.write         = &file_write;

        startEncoding(format, sampleRate, numChannels);
    }

    /// Opens an audio stream that writes to a dynamically growable output buffer.
    /// This stream will be opened for writing only.
    /// Access to the internal buffer after encoding with `finalizeAndGetEncodedResult`.
    /// Note: throws a manually allocated exception in case of error. Free it with `dplug.core.destroyFree`.
    ///
    /// Params: 
    ///     path An UTF-8 path to the sound file.
    ///     format Audio file format to generate.
    ///     sampleRate Sample rate of this audio stream. This samplerate might be rounded up to the nearest integer number.
    ///     numChannels Number of channels of this audio stream.
    void openToBuffer(AudioFileFormat format, float sampleRate, int numChannels) @nogc
    {
        cleanUp();
        // TODO
        startEncoding(format, sampleRate, numChannels);
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
            fileContext = null;
        }

        if (memoryContext !is null)
        {
            // TODO destroy buffer if any            
            destroyFree(memoryContext);
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

    bool isOpenedForWriting() nothrow @nogc
    {
        // Note: 
        //  * when opened for reading, I/O operations given are: seek/tell/getFileLength/read.
        //  * when opened for writing, I/O operations given are: seek/tell/write.
        return io.read is null;
    }

    void startDecoding() @nogc
    {
        // TODO: detect format, instantiate decoder, and start decoding
    }

    void startEncoding(AudioFileFormat format, float sampleRate, int numChannels) @nogc
    {
        // TODO: check format, instantiate encoder, and start encoding
    }
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

    // Initialize this context
    void initialize(const(char)[] path, bool forWrite) @nogc
    {
        CString strZ = CString(path);
        file = fopen(strZ.storage, forWrite ? "wb".ptr : "rb".ptr);

        // finds the size of the file
        fseek(file, 0, SEEK_END);
        fileSize = ftell(file);
        fseek(file, 0, SEEK_SET);
    }
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
    bool bufferCanGrow; // can only be true if `bufferIsOwned`is true.

    // Buffer
    ubyte* buffer;

    size_t size;     // current buffer size
    size_t cursor;   // where we are in the buffer
    size_t capacity; // max buffer size before realloc
}

long memory_tell(void* userData) nothrow @nogc
{
    MemoryContext* context = cast(MemoryContext*)userData;
    return cast(long)(context.cursor);
}

void memory_seek(long offset, void* userData) nothrow @nogc
{
    MemoryContext* context = cast(MemoryContext*)userData;
    if (offset >= context.size) // can't seek past end of buffer, stick to the end so that read return 0 byte
        offset = context.size;
    context.cursor = cast(size_t)offset; // Note: memory streams larger than 2gb not supported
}

long memory_getFileLength(void* userData) nothrow @nogc
{
    MemoryContext* context = cast(MemoryContext*)userData;
    return cast(long)(context.size);
}

int memory_read(void* outData, int bytes, void* userData) nothrow @nogc
{
    MemoryContext* context = cast(MemoryContext*)userData;
    size_t cursor = context.cursor;
    size_t size = context.size;
    size_t available = size - cursor;
    if (bytes < available)
    {
        outData[0..bytes] = context.buffer[cursor..cursor + bytes];
        context.cursor += bytes;
        return bytes;
    }
    else
    {
        outData[0..available] = context.buffer[cursor..cursor + available];
        context.cursor = context.size;
        return cast(int)available;
    }
}

int memory_write(void* inData, int bytes, void* userData) nothrow @nogc
{
    FileContext* context = cast(FileContext*)userData;
    size_t bytesWritten = fwrite(inData, 1, bytes, context.file);
    return cast(int)bytesWritten;
}