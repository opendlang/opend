/++
$(H4 High level Msgpack serialization API)

This module requires msgpack-d package.

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ion.ser.msgpack;

import mir.ion.exception: IonException;

version(D_Exceptions) private static immutable bigIntConvException = new IonException("Overflow when converting BigIntView");
version(D_Exceptions) private static immutable msgpackAnnotationException = new IonException("MsgPack can store exactly one annotation.");
version(D_Exceptions) private static immutable stringTooLargeException = new IonException("Too large of a string for MessagePack");

/++ MessagePack support +/

enum MessagePackFmt : ubyte
{
    /++ Integers +/
    
    /++ 7-bit positive integer +/
    fixint = 0x00,
    /++ 5-bit negative integer (???) +/
    fixnint = 0xe0,
    /++ 8-bit unsigned integer +/
    uint8 = 0xcc,
    /++ 16-bit unsigned integer +/
    uint16 = 0xcd,
    /++ 32-bit unsigned integer +/
    uint32 = 0xce,
    /++ 64-bit unsigned integer +/
    uint64 = 0xcf,
    /++ 8-bit signed integer +/
    int8 = 0xd0,
    /++ 16-bit signed integer +/
    int16 = 0xd1,
    /++ 32-bit signed integer +/
    int32 = 0xd2,
    /++ 64-bit signed integer +/
    int64 = 0xd3,

    /++ Maps +/

    /++ Map with a maximum length of 15 key-value pairs +/
    fixmap = 0x80,
    /++ Map with a maximum length of 65535 key-value pairs +/
    map16 = 0xde,
    /++ Map with a maximum length of 4294967295 key-value pairs +/
    map32 = 0xdf,

    /++ Arrays +/

    /++ Array with a maximum length of 15 elements +/
    fixarray = 0x90,
    /++ Array with a maximum length of 65535 elements +/
    array16 = 0xdc,
    /++ Array with a maximum length of 4294967295 elements +/ 
    array32 = 0xdd,
    
    /++ Strings +/

    /++ String with a maximum length of 31 bytes +/
    fixstr = 0xa0,
    /++ String with a maximum length of 255 (1 << 8 - 1) bytes +/
    str8 = 0xd9,
    /++ String with a maximum length of 65535 (1 << 16 - 1) bytes +/
    str16 = 0xda,
    /++ String with a maximum length of 4294967295 (1 << 32 - 1) bytes +/
    str32 = 0xdb,

    /++ Nil +/
    nil = 0xc0,

    /++ Boolean values +/
    false_ = 0xc2,
    true_ = 0xc3,

    /++ Binary (byte array) +/

    /++ Byte array with a maximum length of 255 bytes +/
    bin8 = 0xc4,
    /++ Byte array with a maximum length of 65535 bytes +/
    bin16 = 0xc5,
    /++ Byte array with a maximum length of 4294967295 bytes +/
    bin32 = 0xc6,

    /++ Implementation-specific extensions +/
    
    /++ Integer & byte array whose length is 1 byte +/
    fixext1 = 0xd4,
    /++ Integer & byte array whose length is 2 bytes +/
    fixext2 = 0xd5,
    /++ Integer & byte array whose length is 4 bytes +/ 
    fixext4 = 0xd6,
    /++ Integer & byte array whose length is 8 bytes +/
    fixext8 = 0xd7,
    /++ Integer & byte array whose length is 16 bytes +/
    fixext16 = 0xd8,
    /++ Integer & byte array whose maximum length is 255 bytes +/
    ext8 = 0xc7,
    /++ Integer & byte array whose maximum length is 65535 bytes +/
    ext16 = 0xc8,
    /++ Integer & byte array whose maximum length is 4294967295 bytes +/
    ext32 = 0xc9,

    /+ Timestamp extension type +/
    /+ 32-bit timestamp value that stores the number of seconds that have elapsed since the UNIX epoch (1970-01-01 00:00:00 UTC). +/
    timestamp32 = 0xd6,
    /+ 64-bit timestamp value that stores the number of seconds / nanoseconds since the UNIX epoch (1970-01-01 00:00:00 UTC). +/
    timestamp64 = 0xd7,
    /+ 96-bit timestamp value that stores the number of seconds / nanoseconds since the UNIX epoch (1970-01-01 00:00:00 UTC). +/
    timestamp96 = 0xc7,

    /++ Floats +/

    /++ Single-precision IEEE 754 floating point number +/
    float32 = 0xca,
    /++ Double-precision IEEE 754 floating point number +/
    float64 = 0xcb,
}

version(Have_msgpack_d)
{
    /++
    Msgpack serialization back-end
    +/
    struct MsgpackSerializer()
    {
        import mir.appender: ScopedBuffer;
        import mir.bignum.decimal: Decimal;
        import mir.bignum.integer: BigInt;
        import mir.bignum.low_level_view: BigIntView, WordEndian;
        import mir.ion.symbol_table: IonSymbolTable, IonSystemSymbolTable_v1;
        import mir.ion.tape;
        import mir.ion.type_code;
        import mir.lob;
        import mir.serde: SerdeTarget;
        import mir.string_table: createTable, minimalIndexType;
        import mir.timestamp: Timestamp;
        import mir.utility: _expect;
        import msgpack.packer: PackerImpl;
        import std.traits: isNumeric;

        PackerImpl!(ScopedBuffer!ubyte*) packer;
        ScopedBuffer!(ubyte)* buffer;
        ScopedBuffer!(char, 128) strBuf;
        ScopedBuffer!(uint, 128) lengths;

        /// Mutable value used to choose format specidied or user-defined serialization specializations
        int serdeTarget = SerdeTarget.msgpack;
        private bool _annotation;

    @trusted pure:

        this(ref ScopedBuffer!ubyte buffer)
        {
            this.buffer = &buffer;
            packer = typeof(packer)(&buffer);
            lengths.initialize;
            strBuf.initialize;
        }

        size_t aggrBegin(string packerMethod)(size_t length = size_t.max)
        {
            lengths.put(0);
            __traits(getMember, packer, packerMethod)(length == size_t.max ? uint.max : length);
            return length == size_t.max ? packer.stream.data.length : size_t.max;
        }

        void aggrEnd(string packerMethod)(size_t state)
        {
            import core.stdc.string: memmove;
            auto length = lengths.data[$ - 1];
            lengths.popBackN(1);
            if (state != size_t.max)
            {
                if (length < 16)
                {
                    auto data = packer.stream.data[state .. $];
                    memmove(data.ptr - 4, data.ptr, data.length);
                    packer.stream.popBackN(4);
                }
                else
                if (length < 65536)
                {
                    auto data = packer.stream.data[state .. $];
                    memmove(data.ptr - 2, data.ptr, data.length);
                    packer.stream.popBackN(2);
                }
                auto appLength = packer.stream.length;
                packer.stream._currentLength = state - 5;
                __traits(getMember, packer, packerMethod)(length);
                packer.stream._currentLength = appLength;
            }
        }

        ///
        alias structBegin = aggrBegin!"beginMap";
        ///
        alias structEnd = aggrEnd!"beginMap";

        ///
        alias listBegin = aggrBegin!"beginArray";
        ///
        alias listEnd = aggrEnd!"beginArray";

        ///
        alias sexpBegin = listBegin;

        ///
        alias sexpEnd = listEnd;

        ///
        size_t stringBegin()
        {
            strBuf.reset;
            return 0;
        }

        /++
        Puts string part. The implementation allows to split string unicode points.
        +/
        void putStringPart(scope const(char)[] str)
        {
            strBuf.put(str);
        }

        ///
        void stringEnd(size_t state) @trusted
        {
            putValue(strBuf.data);
        }

        ///
        auto annotationsBegin()
        {
            return size_t(0);
        }

        ///
        void annotationsEnd(size_t state)
        {
            bool _annotation = false;
        }

        ///
        size_t annotationWrapperBegin()
        {
            return structBegin(1);
        }

        ///
        alias annotationWrapperEnd = structEnd;

        ///
        void putKey(scope const char[] key)
        {
            elemBegin;
            putValue(key);
        }

        ///
        void putAnnotation(scope const(char)[] annotation)
        {
            if (_annotation)
                throw msgpackAnnotationException;
            _annotation = true;
            putKey(annotation);
        }

        ///
        void putSymbol(scope const char[] symbol)
        {
            putValue(symbol);
        }

        void putValue(const ubyte num)
        {
            if ((num & 0b1000_0000) == 0)
            {
                buffer.put(MessagePackFmt.fixint | num);
            }
            else 
            {
                buffer.put(MessagePackFmt.uint8);
                buffer.put(num);
            }
        }

        void putValue(const ushort num)
        {
            if ((num & 0b1111_1111_0000_0000) == 0)
            {
                putValue(cast(ubyte)num);
            }
            else
            {
                buffer.put(MessagePackFmt.uint16);
                buffer.put(packMsgPackExt(num));
            }
        }

        void putValue(const uint num)
        {
            if ((num & 0b1111_1111_1111_1111_1111_1111_0000_0000) == 0)
            {
                putValue(cast(ubyte)num);
            }
            else if ((num & 0b1111_1111_1111_1111_0000_0000_0000_0000) == 0)
            {
                putValue(cast(ushort)num);
            }
            else
            {
                buffer.put(MessagePackFmt.uint32);
                buffer.put(packMsgPackExt(num));
            }
        }

        void putValue(const ulong num)
        {
            if ((num & 0b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_0000_0000) == 0)
            {
                putValue(cast(ubyte)num);
            }
            else if ((num & 0b1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_0000_0000_0000_0000) == 0)
            {
                putValue(cast(ushort)num);
            }
            else if ((num & 0b1111_1111_1111_1111_1111_1111_0000_0000_0000_0000_0000_0000_0000_0000) == 0)
            {
                putValue(cast(uint)num);
            }
            else
            {
                buffer.put(MessagePackFmt.uint64);
                buffer.put(packMsgPackExt(num));    
            }
        }

        void putValue(const float num)
        {
            buffer.put(MessagePackFmt.float32);
            uint v = *cast(uint*)&num;
            buffer.put(packMsgPackExt(v));
        }

        void putValue(const double num)
        {
            buffer.put(MessagePackFmt.float64);
            ulong v = *cast(ulong*)&num;
            buffer.put(packMsgPackExt(v));
        } 

        void putValue(const real num)
        {
            putValue(cast(double)num);
        }

        ///
        void putValue(Num)(const Num num)
            if (isNumeric!Num && !is(Num == enum) 
                              && !is(Num == ubyte)
                              && !is(Num == ushort)
                              && !is(Num == uint)
                              && !is(Num == float)
                              && !is(Num == double)
                              && !is(Num == real))
        {
            packer.pack(num);
        }

        ///
        void putValue(W, WordEndian endian)(BigIntView!(W, endian) view)
        {
            auto res = cast(long)view;
            if (res != view)
                throw bigIntConvException;
            putValue(res);
        }

        ///
        void putValue(size_t size)(auto ref const BigInt!size num)
        {
            putValue(num.view);
        }

        ///
        void putValue(size_t size)(auto ref const Decimal!size num)
        {
            putValue(cast(double) num);
        }

        ///
        void putValue(typeof(null))
        {
            buffer.put(MessagePackFmt.nil);
        }

        ///
        void putNull(IonTypeCode code)
        {
            putValue(null);
        }

        ///
        void putValue(bool b)
        {
            buffer.put(0xc2 | b);
        }

        ///
        void putValue(scope const char[] value)
        {
            auto len = value.length;
            if (len <= 31)
            {
                buffer.put(MessagePackFmt.fixstr | cast(ubyte)len);
            }
            else if (len < ubyte.max)
            {
                buffer.put(MessagePackFmt.str8);
                buffer.put(cast(ubyte)len);
            }
            else if (len <= ushort.max)
            {
                buffer.put(MessagePackFmt.str16);
                buffer.put(packMsgPackExt(cast(ushort)len));
            }
            else if (len <= uint.max)
            {
                buffer.put(MessagePackFmt.str32);
                buffer.put(packMsgPackExt(cast(uint)len));
            }
            else
            {
                version(D_Exceptions)
                    throw stringTooLargeException;
                else
                    assert(0, "Too large of a string for MessagePack");
            }

            foreach(c; value) {
                buffer.put(c);
            }
        }

        ///
        void putValue(Clob value)
        {
            putValue(value.data);
        }

        ///
        void putValue(Blob value)
        {
            putValue(cast(const(char)[])value.data);
        }

        private ubyte[T.sizeof] packMsgPackExt(T)(const T num)
            if (__traits(isUnsigned, T))
        {
            T ret = num;
            version (LittleEndian)
            {
                import core.bitop : bswap, byteswap;
                static if (T.sizeof >= 4) {
                    ret = bswap(ret);
                } else static if (T.sizeof == 2) {
                    ret = byteswap(ret);
                }
            }
            return cast(typeof(return))cast(T[1])[ret];
        }

        ///
        void putValue(Timestamp value)
        {
            auto sec = value.toUnixTime;
            auto nanosec = cast(uint)value.getFraction!9;
            if ((sec >> 34) == 0)
            {
                ulong data64 = (ulong(nanosec) << 34) | sec;
                // If there are no bits in the top 32 bits, then automatically
                // write out the smaller data type (in this case, timestamp32) 
                if ((data64 & 0xffffffff00000000L) == 0)
                {
                    buffer.put(MessagePackFmt.timestamp32);
                    buffer.put(cast(ubyte)-1);
                    buffer.put(packMsgPackExt(cast(uint)data64));
                }
                else
                {
                    buffer.put(MessagePackFmt.timestamp64);
                    buffer.put(cast(ubyte)-1);
                    buffer.put(packMsgPackExt(data64));
                }
            }
            else
            {
                // timestamp 96
                ubyte[12] data;
                data[0 .. 4] = packMsgPackExt(nanosec);
                data[4 .. 12] = packMsgPackExt(ulong(sec));

                buffer.put(MessagePackFmt.timestamp96);
                buffer.put(12);
                buffer.put(cast(ubyte)-1);
                buffer.put(data);
            }
        }

        ///
        void elemBegin()
        {
            lengths.data[$ - 1]++;
        }

        ///
        alias sexpElemBegin = elemBegin;

        ///
        void nextTopLevelValue()
        {
        }
    }

    unittest
    {
        import mir.ion.ser.script: SerializerWrapper;
        MsgpackSerializer!() serializer;
        auto s = new SerializerWrapper!(MsgpackSerializer!())(serializer);
    }

    import mir.serde: SerdeTarget;

    ///
    immutable(ubyte)[] serializeMsgpack(T)(auto ref T value, int serdeTarget = SerdeTarget.ion)
    {
        import mir.appender: scopedBuffer;
        import mir.ion.ser: serializeValue;
        auto appender = scopedBuffer!ubyte;
        auto serializer = appender.MsgpackSerializer!();
        serializer.serdeTarget = serdeTarget;
        serializeValue(serializer, value);
        return (()@trusted => cast(immutable) appender.data)();
    }

    /// Test serializing booleans
    version(mir_ion_msgpack_test) unittest
    {
        assert(serializeMsgpack(true) == [0xc3]);
        assert(serializeMsgpack(false) == [0xc2]);
    }

    /// Test serializing nulls
    version(mir_ion_msgpack_test) unittest
    {
        assert(serializeMsgpack(null) == [0xc0]);
    }

    /// Test serializing uint64s
    version(mir_ion_msgpack_test) unittest
    {
        assert(serializeMsgpack(cast(ulong)(uint.max)) == [0xce, 0xff, 0xff, 0xff, 0xff]);
        assert(serializeMsgpack(cast(ulong)(uint.max) + 1) == [0xcf, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]);
        assert(serializeMsgpack(ulong.max) == [0xcf, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
    }

    /// Test serializing floats / doubles / reals
    version(mir_ion_msgpack_test) unittest
    {
        assert(serializeMsgpack(float.min_normal) == [0xca, 0x00, 0x80, 0x00, 0x00]);
        assert(serializeMsgpack(float.max) == [0xca, 0x7f, 0x7f, 0xff, 0xff]);
        assert(serializeMsgpack(double.min_normal) == [0xcb, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
        assert(serializeMsgpack(double.max) == [0xcb, 0x7f, 0xef, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
    }

    /// Test serializing timestamps
    version(mir_ion_msgpack_test) unittest
    {
        import mir.timestamp : Timestamp;
        assert(serializeMsgpack(Timestamp(1970, 1, 1, 0, 0, 0)) == [0xd6, 0xff, 0x00, 0x00, 0x00, 0x00]);
        assert(serializeMsgpack(Timestamp(2038, 1, 19, 3, 14, 7)) == [0xd6, 0xff, 0x7f, 0xff, 0xff, 0xff]);
        assert(serializeMsgpack(Timestamp(2299, 12, 31, 23, 59, 59)) == [0xd7, 0xff, 0x00, 0x00, 0x00, 0x02, 0x6c, 0xb5, 0xda, 0xff]);
        assert(serializeMsgpack(Timestamp(3000, 12, 31, 23, 59, 59)) == [0xc7, 0x0c, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x93, 0x3f, 0xff, 0x7f]);
    }

    /// Test serializing strings
    version(mir_ion_msgpack_test) unittest
    {
        import std.array : replicate;
        assert(serializeMsgpack("a") == [0xa1, 0x61]);

        assert(serializeMsgpack("a".replicate(32)) == 
            cast(ubyte[])[0xd9, 0x20] ~ cast(ubyte[])"a".replicate(32));

        assert(serializeMsgpack("a".replicate(ushort.max)) == 
            cast(ubyte[])[0xda, 0xff, 0xff] ~ cast(ubyte[])"a".replicate(ushort.max));

        assert(serializeMsgpack("a".replicate(ushort.max + 1)) == 
            cast(ubyte[])[0xdb, 0x00, 0x01, 0x00, 0x00] ~ cast(ubyte[])"a".replicate(ushort.max + 1));
    }
}
else
{
    pragma(msg, "msgpack-d backend isn't connected");

    version(D_Ddoc) {
        /++
        +/
        immutable(ubyte)[] serializeMsgpack(T)(auto ref T value, int serdeTarget = SerdeTarget.ion) {}

    }
}
