module audioformats.io;

import audioformats.internals;

nothrow @nogc
{
    alias ioSeekCallback          = bool function(long offset, bool relative, void* userData); // return true on success
    alias ioTellCallback          = long function(                            void* userData);  
    alias ioGetFileLengthCallback = long function(                            void* userData);
    alias ioReadCallback          = int  function(void* outData, int bytes,   void* userData); // returns number of read bytes
    alias ioWriteCallback         = int  function(void* inData, int bytes,    void* userData); // returns number of written bytes
    alias ioSkipCallback          = bool function(int bytes,                  void* userData);
    alias ioFlushCallback         = bool function(                            void* userData);
}

struct IOCallbacks
{
nothrow @nogc:

    ioSeekCallback seek;
    ioTellCallback tell;
    ioGetFileLengthCallback getFileLength;
    ioReadCallback read;
    ioWriteCallback write;
    ioSkipCallback skip;
    ioFlushCallback flush;


    // Now, some helpers for binary parsing based on these callbacks

    // <reading>

    bool nothingToReadAnymore(void* userData)
    {
        return remainingBytesToRead(userData) <= 0;
    }

    long remainingBytesToRead(void* userData)
    {
        long cursor = tell(userData);
        long fileLength = getFileLength(userData);
        assert(cursor <= fileLength);
        return fileLength - cursor;
    }
  
    /// Read one ubyte from stream and advance the stream cursor.
    /// On error, return an error, the stream then is considered invalid.
    ubyte peek_ubyte(void* userData, bool* err)
    {
        ubyte b = read_ubyte(userData, err);
        if (*err)
            return 0;

        *err = seek(tell(userData) - 1, false, userData);
        return b;
    }

    /// Read one ubyte from stream and advance the stream cursor.
    /// On error, return 0 and an error, stream is then considered invalid.
    ubyte read_ubyte(void* userData, bool* err)
    {
        ubyte b;
        if (1 == read(&b, 1, userData))
        {
            *err = false;
            return b;
        }
        *err = true;
        return 0;
    }

    /// Reads a 16-byte UUID from the stream and advance cursor.
    /// On error, the stream is considered invalid, and the return value is undefined behaviour.
    ubyte[16] read_guid(void* userData, bool* err)
    {
        ubyte[16] b;
        if (16 == read(&b, 16, userData))
        {
            *err = false;
            return b;
        }
        *err = true;
        return b;
    }

    /// Read one Little Endian ushort from stream and advance the stream cursor.
    /// On error, return 0 and an error, stream is then considered invalid.
    ushort read_ushort_LE(void* userData, bool* err)
    {
        ubyte[2] v;
        if (2 == read(v.ptr, 2, userData))
        {
            version(BigEndian)
            {
                ubyte v0 = v[0];
                v[0] = v[1];
                v[1] = v0;
            }

            *err = false;
            return *cast(ushort*)(v.ptr);
        }
        else
        {
            *err = true;
            return 0;
        }
    }

    /// Read one Big Endian 32-bit unsigned int from stream and advance the stream cursor.
    /// On error, return 0 and an error, stream is then considered invalid.
    uint read_uint_BE(void* userData, bool* err)
    {
        ubyte[4] v;
        if (4 == read(v.ptr, 4, userData))
        {
            version(LittleEndian)
            {
                ubyte v0 = v[0];
                v[0] = v[3];
                v[3] = v0;
                ubyte v1 = v[1];
                v[1] = v[2];
                v[2] = v1;
            }
            *err = false;
            return *cast(uint*)(v.ptr);
        }
        else
        {
            *err = true;
            return 0;
        }
    }

    /// Read one Little Endian 32-bit unsigned int from stream and advance the stream cursor.
    /// On error, return 0 and an error, stream is then considered invalid.
    uint read_uint_LE(void* userData, bool* err)
    {
        ubyte[4] v;
        if (4 == read(v.ptr, 4, userData))
        {
            version(BigEndian)
            {
                ubyte v0 = v[0];
                v[0] = v[3];
                v[3] = v0;
                ubyte v1 = v[1];
                v[1] = v[2];
                v[2] = v1;
            }
            *err = false;
            return *cast(uint*)(v.ptr);
        }
        else
        {
            *err = true;
            return 0;
        }
    }

    /// Read one Little Endian 24-bit unsigned int from stream and advance the stream cursor.
    /// On error, return 0 and an error, stream is then considered invalid.
    uint read_24bits_LE(void* userData, bool *err)
    {
        ubyte[3] v;
        if (3 == read(v.ptr, 3, userData))
        {
            *err = false;
            return v[0] | (v[1] << 8) | (v[2] << 16);
        }
        else
        {
            *err = true;
            return 0;
        }
    }

    /// Read one Little Endian 32-bit float from stream and advance the stream cursor.
    /// On error, return `float.nan` and an error, stream is then considered invalid.
    float read_float_LE(void* userData, bool* err)
    {
        uint u = read_uint_LE(userData, err);
        if (*err)
            return float.nan;
        else
            return *cast(float*)(&u);
    }

    /// Read one Little Endian 64-bit float from stream and advance the stream cursor.
    /// On error, return `double.nan` and an error, stream is then considered invalid.
    double read_double_LE(void* userData, bool* err)
    {
        ubyte[8] v;
        if (8 == read(v.ptr, 8, userData))
        {
            version(BigEndian)
            {
                ubyte v0 = v[0];
                v[0] = v[7];
                v[7] = v0;
                ubyte v1 = v[1];
                v[1] = v[6];
                v[6] = v1;
                ubyte v2 = v[2];
                v[2] = v[5];
                v[5] = v2;
                ubyte v3 = v[3];
                v[3] = v[4];
                v[4] = v3;
            }
            return *cast(double*)(v.ptr);
        }
        else
        {
            *err = true;
            return double.nan;
        }
    }

    /// Read one Lthe two fields of a RIFF header: chunk ID and chunk size.
    /// On error, return values are undefined behaviour.
    void readRIFFChunkHeader(void* userData, 
                             ref uint chunkId, 
                             ref uint chunkSize,
                             bool* err)
    {
        // chunk ID is read as Big Endian uint
        chunkId = read_uint_BE(userData, err);
        if (*err)
            return;

        // chunk size is read as Little Endian uint
        chunkSize = read_uint_LE(userData, err);
    }

    // </reading>

    // <writing>

    string writeFailureMessage = "write failure";

    /// Write a Big Endian 32-bit unsigned int to stream and advance cursor.
    /// Returns: `true` on success, else stream is invalid.
    bool write_uint_BE(void* userData, uint value)
    {
        ubyte[4] v;
        *cast(uint*)(v.ptr) = value;
        version(LittleEndian)
        {
            ubyte v0 = v[0];
            v[0] = v[3];
            v[3] = v0;
            ubyte v1 = v[1];
            v[1] = v[2];
            v[2] = v1;
        }
        return (4 == write(v.ptr, 4, userData));
    }

    /// Write a 8-bit signed int to stream and advance cursor.
    /// Returns: `true` on success, else stream is invalid.
    bool write_byte(void* userData, byte value)
    {
        return 1 == write(&value, 1, userData);
    }

    /// Write a 8-bit signed int to stream and advance cursor.
    /// Returns: `true` on success, else stream is invalid.
    bool write_short_LE(void* userData, short value)
    {
        ubyte[2] v;
        *cast(ushort*)(v.ptr) = value;
        version(BigEndian)
        {
            ubyte v0 = v[0];
            v[0] = v[1];
            v[1] = v0;
        }
        return 2 == write(v.ptr, 2, userData);
    }

    /// Write a Little Endian 24-bit signed int to stream and advance cursor.
    /// Returns: `true` on success, else stream is invalid.
    bool write_24bits_LE(void* userData, int value)
    {
        ubyte[4] v;
        *cast(int*)(v.ptr) = value;
        version(BigEndian)
        {
            ubyte v0 = v[0];
            v[0] = v[3];
            v[3] = v0;
            ubyte v1 = v[1];
            v[1] = v[2];
            v[2] = v1;
        }
        return 3 == write(v.ptr, 3, userData);
    }

    /// Write a Little Endian 32-bit float to stream and advance cursor.
    /// Returns: `true` on success, else stream is invalid.
    bool write_float_LE(void* userData, float value)
    {
        return write_uint_LE(userData, *cast(uint*)(&value));
    }

    /// Write a Little Endian 64-bit double to stream and advance cursor.
    /// Returns: `true` on success, else stream is invalid.
    bool write_double_LE(void* userData, float value)
    {
        return write_ulong_LE(userData, *cast(ulong*)(&value));
    }

    /// Write a Little Endian 64-bit unsigned integer to stream and advance cursor.
    /// Returns: `true` on success, else stream is invalid.
    bool write_ulong_LE(void* userData, ulong value)
    {
        ubyte[8] v;
        *cast(ulong*)(v.ptr) = value;
        version(BigEndian)
        {
            ubyte v0 = v[0];
            v[0] = v[7];
            v[7] = v0;
            ubyte v1 = v[1];
            v[1] = v[6];
            v[6] = v1;
            ubyte v2 = v[2];
            v[2] = v[5];
            v[5] = v2;
            ubyte v3 = v[3];
            v[3] = v[4];
            v[4] = v3;
        }

        return 8 == write(v.ptr, 8, userData);
    }

    /// Write a Little Endian 32-bit unsigned integer to stream and advance cursor.
    /// Returns: `true` on success, else stream is invalid.
    bool write_uint_LE(void* userData, uint value)
    {
        ubyte[4] v;
        *cast(uint*)(v.ptr) = value;
        version(BigEndian)
        {
            ubyte v0 = v[0];
            v[0] = v[3];
            v[3] = v0;
            ubyte v1 = v[1];
            v[1] = v[2];
            v[2] = v1;
        }

        return 4 == write(v.ptr, 4, userData);
    }

    /// Write a Little Endian 16-bit unsigned integer to stream and advance cursor.
    /// Returns: `true` on success, else stream is invalid.
    bool write_ushort_LE(void* userData, ushort value)
    {
        ubyte[2] v;
        *cast(ushort*)(v.ptr) = value;
        version(BigEndian)
        {
            ubyte v0 = v[0];
            v[0] = v[1];
            v[1] = v0;
        }
        return 2 == write(v.ptr, 2, userData);
    }

    /// Write a RIFF header to stream and advance cursor.
    /// Returns: `true` on success, else stream is invalid.
    bool writeRIFFChunkHeader(void* userData, uint chunkId, uint chunkSize)
    {
        if (!write_uint_BE(userData, chunkId))
            return false;
        return write_uint_LE(userData, chunkSize);
    }

    // </writing>
}


template RIFFChunkId(string id)
{
    static assert(id.length == 4);
    __gshared uint RIFFChunkId = (cast(ubyte)(id[0]) << 24)
        | (cast(ubyte)(id[1]) << 16)
        | (cast(ubyte)(id[2]) << 8)
        | (cast(ubyte)(id[3]));
}
