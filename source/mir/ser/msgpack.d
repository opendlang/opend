/++
$(H4 High level Msgpack serialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ser.msgpack;

import mir.ion.exception: IonException;
import mir.serde: SerdeTarget;

version(D_Exceptions) {
    private static immutable bigIntConvException = new IonException("Overflow when converting BigInt");
    private static immutable msgpackAnnotationException = new IonException("MsgPack can store exactly one annotation.");
    private static immutable stringTooLargeException = new IonException("Too large of a string for MessagePack");
    private static immutable blobTooLargeException = new IonException("Too large of a blob for MessagePack");
    private static immutable mapTooLargeException = new IonException("Too large of a map for MessagePack");
    private static immutable arrayTooLargeException = new IonException("Too large of an array for MessagePack");
}

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

    /++ Floats +/

    /++ Single-precision IEEE 754 floating point number +/
    float32 = 0xca,
    /++ Double-precision IEEE 754 floating point number +/
    float64 = 0xcb,
}

/++
Msgpack serialization back-end
+/
struct MsgpackSerializer(Appender)
{
        import mir.appender: ScopedBuffer;
        import mir.bignum.decimal: Decimal;
        import mir.bignum.integer: BigInt;
        import mir.ion.symbol_table: IonSymbolTable, IonSystemSymbolTable_v1;
        import mir.ion.tape;
        import mir.ion.type_code;
        import mir.lob;
        import mir.serde: SerdeTarget;
        import mir.string_table: createTable, minimalIndexType;
        import mir.timestamp: Timestamp;
        import mir.utility: _expect;
        import std.traits: isNumeric;

        Appender* buffer;
        ScopedBuffer!(char, 128) strBuf;
        ScopedBuffer!(uint, 128) lengths;

        /// Mutable value used to choose format specidied or user-defined serialization specializations
        int serdeTarget = SerdeTarget.msgpack;
        private bool _annotation;

        @safe pure:

        this(Appender* app) @trusted
        {
            this.buffer = app;
            lengths.initialize;
            strBuf.initialize;
        }

scope:

        size_t aggrBegin(string packerMethod)(size_t length = size_t.max)
        {
            lengths.put(0);
            __traits(getMember, this, packerMethod)(length == size_t.max ? uint.max : length);
            return length == size_t.max ? buffer.data.length : size_t.max;
        }

        @trusted
        void aggrEnd(string packerMethod)(size_t state)
        {
            import core.stdc.string: memmove;
            auto length = lengths.data[$ - 1];
            lengths.popBackN(1);
            if (state != size_t.max)
            {
                if (length < 16)
                {
                    auto data = buffer.data[state .. $];
                    memmove(data.ptr - 4, data.ptr, data.length);
                    buffer.popBackN(4);
                }
                else
                if (length < 65536)
                {
                    auto data = buffer.data[state .. $];
                    memmove(data.ptr - 2, data.ptr, data.length);
                    buffer.popBackN(2);
                }
                auto appLength = buffer.data.length;
                buffer._currentLength = state - 5;
                __traits(getMember, this, packerMethod)(length);
                buffer._currentLength = appLength;
            }
        }

        private void beginMap(size_t size)
        {
            if (size < 16)
            {
                buffer.put(cast(ubyte)(MessagePackFmt.fixmap | cast(ubyte)size));
            }
            else if (size <= ushort.max)
            {
                buffer.put(MessagePackFmt.map16);
                buffer.put(packMsgPackExt(cast(ushort)size));
            }
            else if (size <= uint.max)
            {
                buffer.put(MessagePackFmt.map32);
                buffer.put(packMsgPackExt(cast(uint)size));
            }
            else
            {
                version(D_Exceptions)
                    throw mapTooLargeException;
                else
                    assert(0, "Too large of a map for MessagePack");
            }
        }

        private void beginArray(size_t size)
        {
            if (size < 16)
            {
                buffer.put(MessagePackFmt.fixarray | cast(ubyte)size);
            }
            else if (size <= ushort.max)
            {
                buffer.put(MessagePackFmt.array16);
                buffer.put(packMsgPackExt(cast(ushort)size));
            }
            else if (size <= uint.max)
            {
                buffer.put(MessagePackFmt.array32);
                buffer.put(packMsgPackExt(cast(uint)size));
            }
            else
            {
                version(D_Exceptions)
                    throw arrayTooLargeException;
                else
                    assert(0, "Too large of an array for MessagePack");
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

        void putValue(ubyte num)
        {
            if ((num & 0x80) == 0)
            {
                buffer.put(cast(ubyte)(MessagePackFmt.fixint | num));
                return;
            }

            buffer.put(MessagePackFmt.uint8);
            buffer.put(num);
        }

        void putValue(ushort num)
        {
            if ((num & 0xff00) == 0)
            {
                putValue(cast(ubyte)num);
                return;
            }

            buffer.put(MessagePackFmt.uint16);
            buffer.put(packMsgPackExt(num));
        }

        void putValue(uint num)
        {
            if ((num & 0xffff0000) == 0)
            {
                putValue(cast(ushort)num);
                return;
            }

            buffer.put(MessagePackFmt.uint32);
            buffer.put(packMsgPackExt(num));
        }

        void putValue(ulong num)
        {
            if ((num & 0xffffffff00000000) == 0)
            {
                putValue(cast(uint)num);
                return;
            }

            buffer.put(MessagePackFmt.uint64);
            buffer.put(packMsgPackExt(num));    
        }

        void putValue(byte num)
        {
            // check if we're a negative byte
            if (num < 0)
            {
                // if this has bit 7 and 6 set, then we can
                // fit this into a fixnint, so do so here
                if ((num & (1 << 6)) && (num & (1 << 5)))
                {
                    buffer.put(cast(ubyte)(num | MessagePackFmt.fixnint));
                    return;
                }
                // otherwise, write it out as a full int8
                buffer.put(MessagePackFmt.int8);
                buffer.put(cast(ubyte)num);
                return;
            }
            // we can always fit a non-negative byte into the
            // fixint, so just pass it down the chain to handle
            putValue(cast(ubyte)num);
        }

        void putValue(short num)
        {
            // check if this can fit into the space of a byte 
            if (num == cast(byte)num)
            {
                putValue(cast(byte)num);
                return;
            }

            buffer.put(MessagePackFmt.int16);
            buffer.put(packMsgPackExt(cast(ushort)num));
        }

        void putValue(int num)
        {
            if (num == cast(short)num)
            {
                putValue(cast(short)num);
                return;
            }

            buffer.put(MessagePackFmt.int32);
            buffer.put(packMsgPackExt(cast(uint)num));
        }

        void putValue(long num)
        {
            if (num == cast(int)num)
            {
                putValue(cast(int)num);
                return;
            }

            buffer.put(MessagePackFmt.int64);
            buffer.put(packMsgPackExt(cast(ulong)num));
        }

        void putValue(float num)
        {
            buffer.put(MessagePackFmt.float32);
            // XXX: better way to do this?
            uint v = () @trusted {return *cast(uint*)&num;}();
            buffer.put(packMsgPackExt(v));
        }

        void putValue(double num)
        {
            buffer.put(MessagePackFmt.float64);
            // XXX: better way to do this?
            ulong v = () @trusted {return *cast(ulong*)&num;}();
            buffer.put(packMsgPackExt(v));
        } 

        void putValue(real num)
        {
            // MessagePack does not support 80-bit floating point numbers,
            // so we'll have to convert down here (and lose a fair bit of precision).
            putValue(cast(double)num);
        }

        ///
        void putValue(size_t size)(auto ref const BigInt!size num)
        {
            auto res = cast(long)num;
            if (res != num)
                throw bigIntConvException;
            putValue(res);
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
            buffer.put(cast(ubyte)(MessagePackFmt.false_ | b));
        }

        ///
        void putValue(scope const(char)[] value)
        {
            if (value.length <= 31)
            {
                buffer.put(MessagePackFmt.fixstr | cast(ubyte)value.length);
            }
            else if (value.length <= ubyte.max)
            {
                buffer.put(MessagePackFmt.str8);
                buffer.put(cast(ubyte)value.length);
            }
            else if (value.length <= ushort.max)
            {
                buffer.put(MessagePackFmt.str16);
                buffer.put(packMsgPackExt(cast(ushort)value.length));
            }
            else if (value.length <= uint.max)
            {
                buffer.put(MessagePackFmt.str32);
                buffer.put(packMsgPackExt(cast(uint)value.length));
            }
            else
            {
                version(D_Exceptions)
                    throw stringTooLargeException;
                else
                    assert(0, "Too large of a string for MessagePack");
            }

            () @trusted { buffer.put(cast(ubyte[])value); }();
        }

        ///
        void putValue(Clob value)
        {
            putValue(value.data);
        }

        ///
        void putValue(Blob value)
        {
            if (value.data.length <= ubyte.max)
            {
                buffer.put(MessagePackFmt.bin8);
                buffer.put(cast(ubyte)value.data.length);
            }
            else if (value.data.length <= ushort.max)
            {
                buffer.put(MessagePackFmt.bin16);
                buffer.put(packMsgPackExt(cast(ushort)value.data.length));
            }
            else if (value.data.length <= uint.max)
            {
                buffer.put(MessagePackFmt.bin32);
                buffer.put(packMsgPackExt(cast(uint)value.data.length));
            }
            else
            {
                version(D_Exceptions)
                    throw blobTooLargeException;
                else
                    assert(0, "Too big of a blob for MessagePack");
            }

            buffer.put(value.data);
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
                    buffer.put(MessagePackFmt.fixext4);
                    buffer.put(cast(ubyte)-1);
                    buffer.put(packMsgPackExt(cast(uint)data64));
                }
                else
                {
                    buffer.put(MessagePackFmt.fixext8);
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

                buffer.put(MessagePackFmt.ext8);
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

@safe pure
version(mir_ion_test) unittest
{
    import mir.appender : ScopedBuffer;
    import mir.ser.interfaces: SerializerWrapper;
    MsgpackSerializer!(ScopedBuffer!ubyte) serializer;
    scope s = new SerializerWrapper!(MsgpackSerializer!(ScopedBuffer!ubyte))(serializer);
}

///
void serializeMsgpack(Appender, T)(ref Appender appender, auto ref T value, int serdeTarget = SerdeTarget.ion)
{
    import mir.ser : serializeValue;
    auto serializer = ((()@trusted => &appender)()).MsgpackSerializer!(Appender);
    serializer.serdeTarget = serdeTarget;
    serializeValue(serializer, value);
}

///
immutable(ubyte)[] serializeMsgpack(T)(auto ref T value, int serdeTarget = SerdeTarget.ion)
{
    import mir.appender : ScopedBuffer, scopedBuffer;
    auto app = scopedBuffer!ubyte;
    serializeMsgpack!(ScopedBuffer!ubyte, T)(app, value, serdeTarget);
    return (()@trusted => app.data.idup)();
}

/// Test serializing booleans
@safe pure
version(mir_ion_test) unittest
{
    assert(serializeMsgpack(true) == [0xc3]);
    assert(serializeMsgpack(false) == [0xc2]);
}

/// Test serializing nulls
@safe pure
version(mir_ion_test) unittest
{
    assert(serializeMsgpack(null) == [0xc0]);
}

/// Test serializing signed integral types
@safe pure
version(mir_ion_test) unittest
{
    // Bytes
    assert(serializeMsgpack(byte.min) == [0xd0, 0x80]);
    assert(serializeMsgpack(byte.max) == [0x7f]);

    // Shorts
    assert(serializeMsgpack(short(byte.max)) == [0x7f]);
    assert(serializeMsgpack(short(byte.max) + 1) == [0xd1, 0x00, 0x80]);
    assert(serializeMsgpack(short.min) == [0xd1, 0x80, 0x00]);
    assert(serializeMsgpack(short.max) == [0xd1, 0x7f, 0xff]);

    // Integers
    assert(serializeMsgpack(int(-32)) == [0xe0]);
    assert(serializeMsgpack(int(byte.max)) == [0x7f]);
    assert(serializeMsgpack(int(short.max)) == [0xd1, 0x7f, 0xff]);
    assert(serializeMsgpack(int(short.max) + 1) == [0xd2, 0x00, 0x00, 0x80, 0x00]);
    assert(serializeMsgpack(int.min) == [0xd2, 0x80, 0x00, 0x00, 0x00]);
    assert(serializeMsgpack(int.max) == [0xd2, 0x7f, 0xff, 0xff, 0xff]);

    // Long integers
    assert(serializeMsgpack(long(int.max)) == [0xd2, 0x7f, 0xff, 0xff, 0xff]);
    assert(serializeMsgpack(long(int.max) + 1) == [0xd3, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00]);
    assert(serializeMsgpack(long.max) == [0xd3, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
    assert(serializeMsgpack(long.min) == [0xd3, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
}

/// Test serializing unsigned integral types
@safe pure
version(mir_ion_test) unittest
{
    // Unsigned bytes
    assert(serializeMsgpack(ubyte.min) == [0x00]);
    assert(serializeMsgpack(ubyte((1 << 7) - 1)) == [0x7f]);
    assert(serializeMsgpack(ubyte((1 << 7))) == [0xcc, 0x80]);
    assert(serializeMsgpack(ubyte.max) == [0xcc, 0xff]);
    
    // Unsigned shorts
    assert(serializeMsgpack(ushort(ubyte.max)) == [0xcc, 0xff]);
    assert(serializeMsgpack(ushort(ubyte.max + 1)) == [0xcd, 0x01, 0x00]);
    assert(serializeMsgpack(ushort.min) == [0x00]);
    assert(serializeMsgpack(ushort.max) == [0xcd, 0xff, 0xff]); 

    // Unsigned integers
    assert(serializeMsgpack(uint(ubyte.max)) == [0xcc, 0xff]);
    assert(serializeMsgpack(uint(ushort.max)) == [0xcd, 0xff, 0xff]);
    assert(serializeMsgpack(uint(ushort.max + 1)) == [0xce, 0x00, 0x01, 0x00, 0x00]);
    assert(serializeMsgpack(uint.min) == [0x00]);
    assert(serializeMsgpack(uint.max) == [0xce, 0xff, 0xff, 0xff, 0xff]);

    // Long unsigned integers
    assert(serializeMsgpack(ulong(ubyte.max)) == [0xcc, 0xff]);
    assert(serializeMsgpack(ulong(ushort.max)) == [0xcd, 0xff, 0xff]);
    assert(serializeMsgpack(ulong(uint.max)) == [0xce, 0xff, 0xff, 0xff, 0xff]);
    assert(serializeMsgpack(ulong(uint.max) + 1) == [0xcf, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00]);
    assert(serializeMsgpack(ulong.min) == [0x00]);
    assert(serializeMsgpack(ulong.max) == [0xcf, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);

    // Mir's BigIntView
    import mir.bignum.integer : BigInt;
    assert(serializeMsgpack(BigInt!2(0xDEADBEEF)) == [0xd3, 0x00, 0x00, 0x00, 0x00, 0xde, 0xad, 0xbe, 0xef]);
}

/// Test serializing floats / doubles / reals
@safe pure
version(mir_ion_test) unittest
{
    assert(serializeMsgpack(float.min_normal) == [0xca, 0x00, 0x80, 0x00, 0x00]);
    assert(serializeMsgpack(float.max) == [0xca, 0x7f, 0x7f, 0xff, 0xff]);
    assert(serializeMsgpack(double.min_normal) == [0xcb, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
    assert(serializeMsgpack(double.max) == [0xcb, 0x7f, 0xef, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
    static if (real.mant_dig == 64)
    {
        assert(serializeMsgpack(real.min_normal) == [0xcb,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]);
        assert(serializeMsgpack(real.max) == [0xcb,0x7f,0xf0,0x00,0x00,0x00,0x00,0x00,0x00]);
    }

    // Mir's Decimal
    import mir.bignum.decimal : Decimal;
    assert(serializeMsgpack(Decimal!2("777.777")) == [0xcb,0x40,0x88,0x4e,0x37,0x4b,0xc6,0xa7,0xf0]);
    assert(serializeMsgpack(Decimal!2("-777.7")) == [0xcb,0xc0,0x88,0x4d,0x99,0x99,0x99,0x99,0x9a]);
}

/// Test serializing timestamps
@safe pure
version(mir_ion_test) unittest
{
    import mir.timestamp : Timestamp;
    assert(serializeMsgpack(Timestamp(1970, 1, 1, 0, 0, 0)) == [0xd6, 0xff, 0x00, 0x00, 0x00, 0x00]);
    assert(serializeMsgpack(Timestamp(2038, 1, 19, 3, 14, 7)) == [0xd6, 0xff, 0x7f, 0xff, 0xff, 0xff]);
    assert(serializeMsgpack(Timestamp(2299, 12, 31, 23, 59, 59)) == [0xd7, 0xff, 0x00, 0x00, 0x00, 0x02, 0x6c, 0xb5, 0xda, 0xff]);
    assert(serializeMsgpack(Timestamp(3000, 12, 31, 23, 59, 59)) == [0xc7, 0x0c, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x93, 0x3f, 0xff, 0x7f]);
}

/// Test serializing strings
@safe pure
version(mir_ion_test) unittest
{
    import std.array : replicate;
    assert(serializeMsgpack("a") == [0xa1, 0x61]);

    // These need to be trusted because we cast const(char)[] to ubyte[] (which is fine here!)
    () @trusted {
        auto a = "a".replicate(32);
        assert(serializeMsgpack(a) == 
            cast(ubyte[])[0xd9, 0x20] ~ cast(ubyte[])a);
    } ();

    () @trusted {
        auto a = "a".replicate(ushort.max);
        assert(serializeMsgpack(a) == 
            cast(ubyte[])[0xda, 0xff, 0xff] ~ cast(ubyte[])a);
    } ();

    () @trusted {
        auto a = "a".replicate(ushort.max + 1);
        assert(serializeMsgpack(a) == 
            cast(ubyte[])[0xdb, 0x00, 0x01, 0x00, 0x00] ~ cast(ubyte[])a);
    } ();
}

/// Test serializing blobs / clobs
@safe pure
version(mir_ion_test) unittest
{
    import mir.lob : Blob, Clob;
    import std.array : replicate;

    // Blobs
    // These need to be trusted because we cast const(char)[] to ubyte[] (which is fine here!)
    () @trusted {
        auto de = "\xde".replicate(32);
        assert(serializeMsgpack(Blob(cast(ubyte[])de)) ==
            cast(ubyte[])[0xc4, 0x20] ~ cast(ubyte[])de);
    } ();
    
    () @trusted {
        auto de = "\xde".replicate(ushort.max);
        assert(serializeMsgpack(Blob(cast(ubyte[])de)) ==
            cast(ubyte[])[0xc5, 0xff, 0xff] ~ cast(ubyte[])de);
    } ();

    () @trusted {
        auto de = "\xde".replicate(ushort.max + 1);
        assert(serializeMsgpack(Blob(cast(ubyte[])de)) ==
            cast(ubyte[])[0xc6, 0x00, 0x01, 0x00, 0x00] ~ cast(ubyte[])de);
    } ();

    // Clobs (serialized just as regular strings here)
    () @trusted {
        auto de = "\xde".replicate(32);
        assert(serializeMsgpack(Clob(de)) == 
            cast(ubyte[])[0xd9, 0x20] ~ cast(ubyte[])de);
    } ();
}

/// Test serializing arrays
@safe pure
version(mir_ion_test) unittest
{
    // nested arrays
    assert(serializeMsgpack([["foo"], ["bar"], ["baz"]]) == [0x93, 0x91, 0xa3, 0x66, 0x6f, 0x6f, 0x91, 0xa3, 0x62, 0x61, 0x72, 0x91, 0xa3, 0x62, 0x61, 0x7a]);
    assert(serializeMsgpack([0xDEADBEEF, 0xCAFEBABE, 0xAAAA_AAAA]) == [0x93, 0xce, 0xde, 0xad, 0xbe, 0xef, 0xce, 0xca, 0xfe, 0xba, 0xbe, 0xce, 0xaa, 0xaa, 0xaa, 0xaa]);
    assert(serializeMsgpack(["foo", "bar", "baz"]) == [0x93, 0xa3, 0x66, 0x6f, 0x6f, 0xa3, 0x62, 0x61, 0x72, 0xa3, 0x62, 0x61, 0x7a]);
    assert(serializeMsgpack([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]) == [0xdc,0x00,0x11,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,0x10,0x11]);
}

/// Test serializing enums
@safe pure
version(mir_ion_test) unittest
{
    enum Foo
    {
        Bar,
        Baz
    }

    assert(serializeMsgpack(Foo.Bar) == [0xa3,0x42,0x61,0x72]);
    assert(serializeMsgpack(Foo.Baz) == [0xa3,0x42,0x61,0x7a]);
}

/// Test serializing maps (structs)
@safe pure
version(mir_ion_test) unittest
{
    static struct Book
    {
        string title;
        bool wouldRecommend;
        string description;
        uint numberOfNovellas;
        double price;
        float weight;
        string[] tags;
    }

    Book book = Book("A Hero of Our Time", true, "", 5, 7.99, 6.88, ["russian", "novel", "19th century"]);

    // This will probably break if you modify how any of the data types
    // are serialized.
    assert(serializeMsgpack(book) == [0x87,0xa5,0x74,0x69,0x74,0x6c,0x65,0xb2,0x41,0x20,0x48,0x65,0x72,0x6f,0x20,0x6f,0x66,0x20,0x4f,0x75,0x72,0x20,0x54,0x69,0x6d,0x65,0xae,0x77,0x6f,0x75,0x6c,0x64,0x52,0x65,0x63,0x6f,0x6d,0x6d,0x65,0x6e,0x64,0xc3,0xab,0x64,0x65,0x73,0x63,0x72,0x69,0x70,0x74,0x69,0x6f,0x6e,0xa0,0xb0,0x6e,0x75,0x6d,0x62,0x65,0x72,0x4f,0x66,0x4e,0x6f,0x76,0x65,0x6c,0x6c,0x61,0x73,0x05,0xa5,0x70,0x72,0x69,0x63,0x65,0xcb,0x40,0x1f,0xf5,0xc2,0x8f,0x5c,0x28,0xf6,0xa6,0x77,0x65,0x69,0x67,0x68,0x74,0xca,0x40,0xdc,0x28,0xf6,0xa4,0x74,0x61,0x67,0x73,0x93,0xa7,0x72,0x75,0x73,0x73,0x69,0x61,0x6e,0xa5,0x6e,0x6f,0x76,0x65,0x6c,0xac,0x31,0x39,0x74,0x68,0x20,0x63,0x65,0x6e,0x74,0x75,0x72,0x79]);
}

/// Test serializing a large map (struct)
@safe pure
version(mir_ion_test) unittest
{
    static struct HugeStruct
    {
        bool a;
        bool b;
        bool c;
        bool d;
        bool e;
        string f;
        string g;
        string h;
        string i;
        string j;
        int k;
        int l;
        int m;
        int n;
        int o;
        long p;
    }

    HugeStruct s = HugeStruct(true, true, true, true, true, "", "", "", "", "", 123, 456, 789, 123, 456, 0xDEADBEEF);
    assert(serializeMsgpack(s) == [0xde,0x00,0x10,0xa1,0x61,0xc3,0xa1,0x62,0xc3,0xa1,0x63,0xc3,0xa1,0x64,0xc3,0xa1,0x65,0xc3,0xa1,0x66,0xa0,0xa1,0x67,0xa0,0xa1,0x68,0xa0,0xa1,0x69,0xa0,0xa1,0x6a,0xa0,0xa1,0x6b,0x7b,0xa1,0x6c,0xd1,0x01,0xc8,0xa1,0x6d,0xd1,0x03,0x15,0xa1,0x6e,0x7b,0xa1,0x6f,0xd1,0x01,0xc8,0xa1,0x70,0xd3,0x00,0x00,0x00,0x00,0xde,0xad,0xbe,0xef]);
}

/// Test serializing annotated structs
@safe pure
version(mir_ion_test) unittest
{
    import mir.algebraic;
    import mir.serde : serdeAlgebraicAnnotation;

    @serdeAlgebraicAnnotation("Foo")
    static struct Foo
    {
        string bar;
    }

    @serdeAlgebraicAnnotation("Fooz")
    static struct Fooz
    {
        long bar;
    }

    alias V = Variant!(Foo, Fooz);
    auto foo = V(Foo("baz"));

    assert(serializeMsgpack(foo) == [0x81,0xa3,0x46,0x6f,0x6f,0x81,0xa3,0x62,0x61,0x72,0xa3,0x62,0x61,0x7a]);
}

/// Test custom serialize function with MessagePack
@safe pure
version(mir_ion_test) unittest
{
    static class MyExampleClass
    {
        string text;

        this(string text)
        {
            this.text = text;
        }

        void serialize(S)(scope ref S serializer) const
        {
            auto state = serializer.stringBegin;
            serializer.putStringPart("Hello! ");
            serializer.putStringPart("String passed: ");
            serializer.putStringPart(this.text);
            serializer.stringEnd(state);

            import mir.ion.type_code : IonTypeCode;
            serializer.putNull(IonTypeCode.string);
        }
    }

    assert(serializeMsgpack(new MyExampleClass("foo bar baz")) == [0xd9,0x21,0x48,0x65,0x6c,0x6c,0x6f,0x21,0x20,0x53,0x74,0x72,0x69,0x6e,0x67,0x20,0x70,0x61,0x73,0x73,0x65,0x64,0x3a,0x20,0x66,0x6f,0x6f,0x20,0x62,0x61,0x72,0x20,0x62,0x61,0x7a,0xc0]);
}

/// Test excessively large struct
@safe pure
static if (size_t.sizeof > uint.sizeof)
version(D_Exceptions)
version(mir_ion_test) unittest
{
    import mir.ion.exception : IonException;

    static class HugeStruct
    {
        void serialize(S)(scope ref S serializer) const
        {
            auto state = serializer.structBegin(size_t(uint.max) + 1);
        }
    }

    bool caught = false;
    try
    {
        serializeMsgpack(new HugeStruct());
    }
    catch (IonException e)
    {
        caught = true;
    }

    assert(caught);
}

/// Test excessively large array
@safe pure
static if (size_t.sizeof > uint.sizeof)
version(D_Exceptions)
version(mir_ion_test) unittest
{
    import mir.ion.exception : IonException;

    static class HugeArray
    {
        void serialize(S)(scope ref S serializer) const
        {
            auto state = serializer.listBegin(size_t(uint.max) + 1); 
        }
    }

    bool caught = false;
    try 
    {
        serializeMsgpack(new HugeArray());
    }
    catch (IonException e)
    {
        caught = true;
    }

    assert(caught);
}

/// Test invalidly large BigInt
@safe pure
version(D_Exceptions)
version(mir_ion_test) unittest
{
    import mir.ion.exception : IonException;
    import mir.bignum.integer : BigInt;

    bool caught = false;
    try
    {
        serializeMsgpack(BigInt!4.fromHexString("c39b18a9f06fd8e962d99935cea0707f79a222050aaeaaaed17feb7aa76999d7"));
    }
    catch (IonException e)
    {
        caught = true;
    }
    assert(caught);
}
