/// Supports Microsoft WAV audio file format.
module audioformats.wav;

import dplug.core.nogc;
import audioformats.io;


/// Use both for scanning and decoding
final class WAVDecoder
{
public:
@nogc:
    this(IOCallbacks* io, void* userData) nothrow
    {
        _io = io;
        _userData = userData;
    }

    // After scan, we know _sampleRate, _lengthInFrames, and _channels, and can call `readSamples`
    void scan()
    {
        // check RIFF header
        {
            uint chunkId, chunkSize;
            _io.readRIFFChunkHeader(_userData, chunkId, chunkSize);
            if (chunkId != RIFFChunkId!"RIFF")
                throw mallocNew!Exception("Expected RIFF chunk.");

            if (chunkSize < 4)
                throw mallocNew!Exception("RIFF chunk is too small to contain a format.");

            if (_io.read_uint_BE(_userData) !=  RIFFChunkId!"WAVE")
                throw mallocNew!Exception("Expected WAVE format.");
        }

        bool foundFmt = false;
        bool foundData = false;

        int byteRate;
        int blockAlign;
        int bitsPerSample;

        while (!_io.nothingToReadAnymore(_userData))
        {
            // Some corrupted WAV files in the wild finish with one
            // extra 0 byte after an AFAn chunk, very odd
            if (_io.remainingBytesToRead(_userData) == 1)
            {
                if (_io.peek_ubyte(_userData) == 0)
                    break;
            }

            // Question: is there any reason to parse the whole WAV file? This prevents streaming.

            uint chunkId, chunkSize;
            _io.readRIFFChunkHeader(_userData, chunkId, chunkSize); 
            if (chunkId == RIFFChunkId!"fmt ")
            {
                if (foundFmt)
                    throw mallocNew!Exception("Found several 'fmt ' chunks in RIFF file.");

                foundFmt = true;

                if (chunkSize < 16)
                    throw mallocNew!Exception("Expected at least 16 bytes in 'fmt ' chunk."); // found in real-world for the moment: 16 or 40 bytes

                _audioFormat = _io.read_ushort_LE(_userData);
                if (_audioFormat == WAVE_FORMAT_EXTENSIBLE)
                    throw mallocNew!Exception("No support for format WAVE_FORMAT_EXTENSIBLE yet."); // Reference: http://msdn.microsoft.com/en-us/windows/hardware/gg463006.aspx

                if (_audioFormat != LinearPCM && _audioFormat != FloatingPointIEEE)
                    throw mallocNew!Exception("Unsupported audio format, only PCM and IEEE float are supported.");

                _channels = _io.read_ushort_LE(_userData);

                _sampleRate = _io.read_uint_LE(_userData);
                if (_sampleRate <= 0)
                    throw mallocNew!Exception("Unsupported sample-rate."); // we do not support sample-rate higher than 2^31hz

                uint bytesPerSec = _io.read_uint_LE(_userData);
                int bytesPerFrame = _io.read_ushort_LE(_userData);
                bitsPerSample = _io.read_ushort_LE(_userData);

                if (bitsPerSample != 8 && bitsPerSample != 16 && bitsPerSample != 24 && bitsPerSample != 32) 
                    throw mallocNew!Exception("Unsupported bitdepth");

                if (bytesPerFrame != (bitsPerSample / 8) * _channels)
                    throw mallocNew!Exception("Invalid bytes-per-second, data might be corrupted.");

                _io.skip(chunkSize - 16, _userData);
            }
            else if (chunkId == RIFFChunkId!"data")
            {
                if (foundData)
                    throw mallocNew!Exception("Found several 'data' chunks in RIFF file.");

                if (!foundFmt)
                    throw mallocNew!Exception("'fmt ' chunk expected before the 'data' chunk.");

                _bytePerSample = bitsPerSample / 8;
                uint frameSize = _channels * _bytePerSample;
                if (chunkSize % frameSize != 0)
                    throw mallocNew!Exception("Remaining bytes in 'data' chunk, inconsistent with audio data type.");

                uint numFrames = chunkSize / frameSize;
                
                _lengthInFrames = numFrames;

                _samplesOffsetInFile = _io.tell(_userData);

                _io.skip(chunkSize, _userData); // skip, will read later
                foundData = true;
            }
            else
            {
                // ignore unknown chunks
                _io.skip(chunkSize, _userData);
            }
        }

        if (!foundFmt)
            throw mallocNew!Exception("'fmt ' chunk not found.");

        if (!foundData)
            throw mallocNew!Exception("'data' chunk not found.");

        // Get ready to decode
        _io.seek(_samplesOffsetInFile, _userData);
    }

    // read interleaved samples
    // `outData` should have enough room for frames * _channels
    void readSamples(float* outData, int frames)
    {
        uint numSamples = frames * _channels;

        if (_audioFormat == FloatingPointIEEE)
        {
            if (_bytePerSample == 4)
            {
                for (uint i = 0; i < numSamples; ++i)
                    outData[i] = _io.read_float_LE(_userData);
            }
            else if (_bytePerSample == 8)
            {
                for (uint i = 0; i < numSamples; ++i)
                    outData[i] = _io.read_double_LE(_userData);
            }
            else
                throw mallocNew!Exception("Unsupported bit-depth for floating point data, should be 32 or 64.");
        }
        else if (_audioFormat == LinearPCM)
        {
            if (_bytePerSample == 1)
            {
                for (uint i = 0; i < numSamples; ++i)
                {
                    ubyte b = _io.read_ubyte(_userData);
                    outData[i] = (b - 128) / 127.0;
                }
            }
            else if (_bytePerSample == 2)
            {
                for (uint i = 0; i < numSamples; ++i)
                {
                    int s = _io.read_ushort_LE(_userData);
                    outData[i] = s / 32767.0;
                }
            }
            else if (_bytePerSample == 3)
            {
                for (uint i = 0; i < numSamples; ++i)
                {
                    int s = _io.read_24bits_LE(_userData);
                    outData[i] = s / 8388607.0;
                }
            }
            else if (_bytePerSample == 4)
            {
                for (uint i = 0; i < numSamples; ++i)
                {
                    int s = _io.read_uint_LE(_userData);
                    outData[i] = s / 2147483648.0;
                }
            }
            else
                throw mallocNew!Exception("Unsupported bit-depth for integer PCM data, should be 8, 16, 24 or 32 bits.");
        }
        else
            assert(false); // should have been handled earlier, crash
    }

package:
    int _sampleRate;
    int _channels;
    int _audioFormat;
    int _bytePerSample;
    long _samplesOffsetInFile;
    uint _lengthInFrames;

private:
    void* _userData;
    IOCallbacks* _io;
}

/// Use both for scanning and decoding
final class WAVEncoder
{
public:
@nogc:
    this(IOCallbacks* io, void* userData, int sampleRate, int numChannels)
    {
        _io = io;
        _userData = userData;
        _channels = numChannels;

        // Avoids a number of edge cases.
        if (_channels < 0 || _channels > 1024)
            throw mallocNew!Exception("Can't save a WAV with this numnber of channels.");

        // RIFF header
        // its size will be overwritten at finalizing
        _riffLengthOffset = _io.tell(_userData) + 4;
        _io.writeRIFFChunkHeader(_userData, RIFFChunkId!"RIFF", 0);
        _io.write_uint_BE(_userData, RIFFChunkId!"WAVE");

        // 'fmt ' sub-chunk
        _io.writeRIFFChunkHeader(_userData, RIFFChunkId!"fmt ", 0x10);
        _io.write_ushort_LE(_userData, FloatingPointIEEE);
        _io.write_ushort_LE(_userData, cast(ushort)(_channels));
        _io.write_uint_LE(_userData, sampleRate);

        size_t bytesPerSec = sampleRate * _channels * float.sizeof;
        _io.write_uint_LE(_userData,  cast(uint)(bytesPerSec));

        int bytesPerFrame = cast(int)(_channels * float.sizeof);
        _io.write_ushort_LE(_userData, cast(ushort)bytesPerFrame);

        _io.write_ushort_LE(_userData, 32);

        // data sub-chunk
        _dataLengthOffset = _io.tell(_userData) + 4;
        _io.writeRIFFChunkHeader(_userData, RIFFChunkId!"data", 0); // write 0 but temporarily, this will be overwritten at finalizing
        _writtenFrames = 0;
    }

    // read interleaved samples
    // `inSamples` should have enough room for frames * _channels
    int writeSamples(float* inSamples, int frames) nothrow
    {
        int n = 0;
        try
        {
            int samples = frames * _channels;
            for ( ; n < samples; ++n)
            {
                _io.write_float_LE(_userData, inSamples[n]);
            }
            _writtenFrames += frames;
        }
        catch(Exception e)
        {
            destroyFree(e);
        }
        return n;
    }

    void finalizeEncoding() 
    {
        size_t bytesOfData = float.sizeof * _channels * _writtenFrames;

        // write final number of samples for the 'RIFF' chunk
        {
            uint riffLength = cast(uint)( 4 + (4 + 4 + 16) + (4 + 4 + bytesOfData) );
            _io.seek(_riffLengthOffset, _userData);
            _io.write_uint_LE(_userData, riffLength);
        }

        // write final number of samples for the 'data' chunk
        {
            _io.seek(_dataLengthOffset, _userData);
            _io.write_uint_LE(_userData, cast(uint)bytesOfData );
        }
    }

private:
    void* _userData;
    IOCallbacks* _io;
    int _channels;
    int _writtenFrames;
    long _riffLengthOffset, _dataLengthOffset;
}


private:

// wFormatTag
immutable int LinearPCM = 0x0001;
immutable int FloatingPointIEEE = 0x0003;
immutable int WAVE_FORMAT_EXTENSIBLE = 0xFFFE;
