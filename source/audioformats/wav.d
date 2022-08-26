/**
Supports Microsoft WAV audio file format.

Copyright: Guillaume Piolat 2015-2020.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module audioformats.wav;

import core.stdc.math: round, floor, fabs;
import core.stdc.stdlib: rand, RAND_MAX;
import audioformats.io;
import audioformats.internals;


version(decodeWAV)
{
    /// Use both for scanning and decoding
    final class WAVDecoder
    {
    public:
    @nogc:

        static immutable ubyte[16] KSDATAFORMAT_SUBTYPE_IEEE_FLOAT = 
        [3, 0, 0, 0, 0, 0, 16, 0, 128, 0, 0, 170, 0, 56, 155, 113];

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
                    throw mallocNew!AudioFormatsException("Expected RIFF chunk.");

                if (chunkSize < 4)
                    throw mallocNew!AudioFormatsException("RIFF chunk is too small to contain a format.");

                if (_io.read_uint_BE(_userData) !=  RIFFChunkId!"WAVE")
                    throw mallocNew!AudioFormatsException("Expected WAVE format.");
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
                        throw mallocNew!AudioFormatsException("Found several 'fmt ' chunks in RIFF file.");

                    foundFmt = true;

                    if (chunkSize < 16)
                        throw mallocNew!AudioFormatsException("Expected at least 16 bytes in 'fmt ' chunk."); // found in real-world for the moment: 16 or 40 bytes

                    _audioFormat = _io.read_ushort_LE(_userData);
                    bool isWFE = _audioFormat == WAVE_FORMAT_EXTENSIBLE;

                    if (_audioFormat != LinearPCM && _audioFormat != FloatingPointIEEE && !isWFE)
                        throw mallocNew!AudioFormatsException("Unsupported audio format, only PCM and IEEE float and WAVE_FORMAT_EXTENSIBLE are supported.");

                    _channels = _io.read_ushort_LE(_userData);

                    _sampleRate = _io.read_uint_LE(_userData);
                    if (_sampleRate <= 0)
                        throw mallocNew!AudioFormatsException("Unsupported sample-rate."); // we do not support sample-rate higher than 2^31hz

                    uint bytesPerSec = _io.read_uint_LE(_userData);
                    int bytesPerFrame = _io.read_ushort_LE(_userData);
                    bitsPerSample = _io.read_ushort_LE(_userData);

                    if (bitsPerSample != 8 && bitsPerSample != 16 && bitsPerSample != 24 && bitsPerSample != 32 && bitsPerSample != 64) 
                        throw mallocNew!AudioFormatsException("Unsupported bitdepth");

                    if (bytesPerFrame != (bitsPerSample / 8) * _channels)
                        throw mallocNew!AudioFormatsException("Invalid bytes-per-second, data might be corrupted.");

                    // Sometimes there is no cbSize
                    if (chunkSize >= 18)
                    {
                        ushort cbSize = _io.read_ushort_LE(_userData);

                        if (isWFE)
                        {
                            if (cbSize >= 22)
                            {
                                ushort wReserved = _io.read_ushort_LE(_userData);
                                uint dwChannelMask = _io.read_uint_LE(_userData);
                                ubyte[16] SubFormat = _io.read_guid(_userData);

                                if (SubFormat == KSDATAFORMAT_SUBTYPE_IEEE_FLOAT)
                                {
                                    _audioFormat = FloatingPointIEEE;
                                }
                                else
                                    throw mallocNew!AudioFormatsException("Unsupported GUID in WAVE_FORMAT_EXTENSIBLE.");
                            }
                            else
                                throw mallocNew!AudioFormatsException("Unsupported WAVE_FORMAT_EXTENSIBLE.");

                            _io.skip(chunkSize - (18 + 2 + 4 + 16), _userData);
                        }
                        else
                        {
                            _io.skip(chunkSize - 18, _userData);
                        }
                    }
                    else
                    {
                        _io.skip(chunkSize - 16, _userData);
                    }

                }
                else if (chunkId == RIFFChunkId!"data")
                {
                    if (foundData)
                        throw mallocNew!AudioFormatsException("Found several 'data' chunks in RIFF file.");

                    if (!foundFmt)
                        throw mallocNew!AudioFormatsException("'fmt ' chunk expected before the 'data' chunk.");

                    _bytePerSample = bitsPerSample / 8;
                    uint frameSize = _channels * _bytePerSample;
                    if (chunkSize % frameSize != 0)
                        throw mallocNew!AudioFormatsException("Remaining bytes in 'data' chunk, inconsistent with audio data type.");

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
                throw mallocNew!AudioFormatsException("'fmt ' chunk not found.");

            if (!foundData)
                throw mallocNew!AudioFormatsException("'data' chunk not found.");

            // Get ready to decode
            _io.seek(_samplesOffsetInFile, false, _userData);
            _framePosition = 0; // seek to start
        }

        /// Returns: false in case of failure.
        bool seekPosition(int absoluteFrame)
        {
            if (absoluteFrame < 0)
                return false;
            if (absoluteFrame > _lengthInFrames)
                return false;
            uint frameSize = _channels * _bytePerSample;
            long pos = _samplesOffsetInFile + absoluteFrame * frameSize;
            _io.seek(pos, false, _userData);
            _framePosition = absoluteFrame;
            return true;
        }

        /// Returns: position in absolute number of frames since beginning.
        int tellPosition()
        {
            return _framePosition;
        }

        // read interleaved samples
        // `outData` should have enough room for frames * _channels
        // Returs: Frames actually read.
        int readSamples(T)(T* outData, int maxFrames)
        {
            assert(_framePosition <= _lengthInFrames);
            int available = _lengthInFrames - _framePosition;

            // How much frames can we decode?
            int frames = maxFrames;
            if (frames > available)
                frames = available;
            _framePosition += frames;

            int numSamples = frames * _channels;

            uint n = 0;

            try
            {
                if (_audioFormat == FloatingPointIEEE)
                {
                    if (_bytePerSample == 4)
                    {
                        for (n = 0; n < numSamples; ++n)
                            outData[n] = _io.read_float_LE(_userData);
                    }
                    else if (_bytePerSample == 8)
                    {
                        for (n = 0; n < numSamples; ++n)
                            outData[n] = _io.read_double_LE(_userData);
                    }
                    else
                        throw mallocNew!AudioFormatsException("Unsupported bit-depth for floating point data, should be 32 or 64.");
                }
                else if (_audioFormat == LinearPCM)
                {
                    if (_bytePerSample == 1)
                    {
                        for (n = 0; n < numSamples; ++n)
                        {
                            ubyte b = _io.read_ubyte(_userData);
                            outData[n] = (b - 128) / 127.0;
                        }
                    }
                    else if (_bytePerSample == 2)
                    {
                        for (n = 0; n < numSamples; ++n)
                        {
                            short s = _io.read_ushort_LE(_userData);
                            outData[n] = s / 32767.0;
                        }
                    }
                    else if (_bytePerSample == 3)
                    {
                        for (n = 0; n < numSamples; ++n)
                        {
                            int s = _io.read_24bits_LE(_userData);
                            // duplicate sign bit
                            s = (s << 8) >> 8;
                            outData[n] = s / 8388607.0;
                        }
                    }
                    else if (_bytePerSample == 4)
                    {
                        for (n = 0; n < numSamples; ++n)
                        {
                            int s = _io.read_uint_LE(_userData);
                            outData[n] = s / 2147483648.0;
                        }
                    }
                    else
                        throw mallocNew!AudioFormatsException("Unsupported bit-depth for integer PCM data, should be 8, 16, 24 or 32 bits.");
                }
                else
                    assert(false); // should have been handled earlier, crash
            }
            catch(AudioFormatsException e)
            {
                destroyFree(e); // well this is really unexpected, since no read should fail in this loop
                return 0;
            }

            // Return number of integer samples read
            return frames;
        }

    package:
        int _sampleRate;
        int _channels;
        int _audioFormat;
        int _bytePerSample;
        long _samplesOffsetInFile;
        uint _lengthInFrames;
        uint _framePosition;

    private:
        void* _userData;
        IOCallbacks* _io;
    }
}


version(encodeWAV)
{
    /// Use both for scanning and decoding
    final class WAVEncoder
    {
    public:
    @nogc:
        enum Format
        {
            s8,
            s16le,
            s24le,
            fp32le,
            fp64le,
        }

        static bool isFormatLinearPCM(Format fmt)
        {
            return fmt <= Format.s24le;
        }

        this(IOCallbacks* io, void* userData, int sampleRate, int numChannels, Format format, bool enableDither)
        {
            _io = io;
            _userData = userData;
            _channels = numChannels;
            _format = format;
            _enableDither = enableDither;

            // Avoids a number of edge cases.
            if (_channels < 0 || _channels > 1024)
                throw mallocNew!AudioFormatsException("Can't save a WAV with this numnber of channels.");

            // RIFF header
            // its size will be overwritten at finalizing
            _riffLengthOffset = _io.tell(_userData) + 4;
            _io.writeRIFFChunkHeader(_userData, RIFFChunkId!"RIFF", 0);
            _io.write_uint_BE(_userData, RIFFChunkId!"WAVE");

            // 'fmt ' sub-chunk
            _io.writeRIFFChunkHeader(_userData, RIFFChunkId!"fmt ", 0x10);
            _io.write_ushort_LE(_userData, isFormatLinearPCM(format) ? LinearPCM : FloatingPointIEEE);
            _io.write_ushort_LE(_userData, cast(ushort)(_channels));
            _io.write_uint_LE(_userData, sampleRate);

            size_t bytesPerSec = sampleRate * cast(size_t) frameSize();
            _io.write_uint_LE(_userData,  cast(uint)(bytesPerSec));

            int bytesPerFrame = frameSize();
            _io.write_ushort_LE(_userData, cast(ushort)bytesPerFrame);

            _io.write_ushort_LE(_userData, cast(ushort)(sampleSize() * 8));

            // data sub-chunk
            _dataLengthOffset = _io.tell(_userData) + 4;
            _io.writeRIFFChunkHeader(_userData, RIFFChunkId!"data", 0); // write 0 but temporarily, this will be overwritten at finalizing
            _writtenFrames = 0;
        }

        // write interleaved samples
        // `inSamples` should have enough room for frames * _channels
        int writeSamples(T)(T* inSamples, int frames) nothrow
        {
            int n = 0;
            try
            {
                int samples = frames * _channels;
                
                final switch(_format)
                {
                    case Format.s8:
                        ditherInput(inSamples, samples, 127.0f);
                        for ( ; n < samples; ++n)
                        {
                            double x = _ditherBuf[n];
                            int b = cast(int)(128.5 + x * 127.0); 
                            _io.write_byte(_userData, cast(byte)b);
                        }
                        break;

                    case Format.s16le:
                        ditherInput(inSamples, samples, 32767.0f);
                        for ( ; n < samples; ++n)
                        {
                            double x = _ditherBuf[n];
                            int s = cast(int)(32768.5 + x * 32767.0);
                            s -= 32768;
                            assert(s >= -32767 && s <= 32767);
                            _io.write_short_LE(_userData, cast(short)s);
                        }
                        break;

                    case Format.s24le:
                        ditherInput(inSamples, samples, 8388607.0f);
                        for ( ; n < samples; ++n)
                        {
                            double x = _ditherBuf[n];
                            int s = cast(int)(8388608.5 + x * 8388607.0);
                            s -= 8388608;
                            assert(s >= -8388607 && s <= 8388607);
                            _io.write_24bits_LE(_userData, s);
                        }
                        break;

                    case Format.fp32le:
                        for ( ; n < samples; ++n)
                        {
                            _io.write_float_LE(_userData, inSamples[n]);
                        }
                        break;
                    case Format.fp64le:
                        for ( ; n < samples; ++n)
                        {
                            _io.write_double_LE(_userData, inSamples[n]);
                        }
                        break;
                }
                _writtenFrames += frames;
            }
            catch(AudioFormatsException e)
            {
                destroyFree(e);
            }
            catch(Exception e)
            {
                assert(false); // disallow
            }
            return n;
        }

        int sampleSize()
        {
            final switch(_format)
            {
                case Format.s8:     return 1;
                case Format.s16le:  return 2;
                case Format.s24le:  return 3;
                case Format.fp32le: return 4;
                case Format.fp64le: return 8;
            }
        }

        int frameSize()
        {
            return sampleSize() * _channels;
        }

        void finalizeEncoding() 
        {
            size_t bytesOfData = frameSize() * _writtenFrames;

            // write final number of samples for the 'RIFF' chunk
            {
                uint riffLength = cast(uint)( 4 + (4 + 4 + 16) + (4 + 4 + bytesOfData) );
                _io.seek(_riffLengthOffset, false, _userData);
                _io.write_uint_LE(_userData, riffLength);
            }

            // write final number of samples for the 'data' chunk
            {
                _io.seek(_dataLengthOffset, false, _userData);
                _io.write_uint_LE(_userData, cast(uint)bytesOfData );
            }
        }

    private:
        void* _userData;
        IOCallbacks* _io;
        Format _format;
        int _channels;
        int _writtenFrames;
        long _riffLengthOffset, _dataLengthOffset;

        bool _enableDither;
        double[] _ditherBuf;
        TPDFDither _tpdf;

        void ditherInput(T)(T* inSamples, int frames, double scaleFactor)
        {
            if (_ditherBuf.length < frames)
                _ditherBuf.reallocBuffer(frames);

            for (int n = 0; n < frames; ++n)
            {
                _ditherBuf[n] = inSamples[n];
            }

            if (_enableDither)
                _tpdf.process(_ditherBuf.ptr, frames, scaleFactor);
        }
    }
}


private:

// wFormatTag
immutable int LinearPCM = 0x0001;
immutable int FloatingPointIEEE = 0x0003;
immutable int WAVE_FORMAT_EXTENSIBLE = 0xFFFE;


/+
MIT License

Copyright (c) 2018 Chris Johnson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
+/
/// This is based upon TPDF Dither by Chris Johnson / AirWindows
/// though the algorithm changed quite a bit, tuned on 8-bit dither by ear.
struct TPDFDither
{
nothrow:
@nogc:

    void process(double* inoutSamples, int frames, double scaleFactor)
    {      
        for (int n = 0; n < frames; ++n)
        {
            double x = inoutSamples[n];           

            x *= scaleFactor;
            //0-1 is now one bit, now we dither

            enum double TUNE0 = 0.25; // could probably be better if tuned interactively
            enum double TUNE1 = TUNE0*0.5; // ditto

            x += (0.5 - 0.5 * (TUNE0+TUNE1));
            x += TUNE0 * (rand()/cast(double)RAND_MAX);
            x += TUNE1 * (rand()/cast(double)RAND_MAX);
            x = floor(x);
            //TPDF: two 0-1 random noises
            x /= scaleFactor;
            if (x < -1.0) x = -1.0;
            if (x > 1.0) x = 1.0;
            inoutSamples[n] = x;
        }
    }
}