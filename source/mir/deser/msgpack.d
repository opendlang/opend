/++
$(H4 High level Msgpack deserialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.deser.msgpack;
import mir.algebraic : Nullable;
import mir.ser.msgpack : MessagePackFmt;
import mir.ion.exception : IonErrorCode, ionException, ionErrorMsg;
import mir.lob : Blob;

struct MsgpackExtension
{
    Blob data;
    ubyte type;
}

private static T unpackMsgPackVal(T)(scope ref const(ubyte)[] data)
{
    import std.traits : Unsigned;
    alias UT = Unsigned!T;

    if (data.length < UT.sizeof)
    {
        version (D_Exceptions)
            throw IonErrorCode.unexpectedEndOfData.ionException;
        else
            assert(0, IonErrorCode.unexpectedEndOfData.ionErrorMsg);
    }

    UT ret = (cast(UT[1])cast(ubyte[UT.sizeof])data[0 .. UT.sizeof])[0];

    version (LittleEndian)
    {
        import core.bitop : bswap, byteswap;
        static if (T.sizeof >= 4)
        {
            ret = bswap(ret);
        } 
        else static if (T.sizeof == 2)
        {
            ret = byteswap(ret);
        }
    }

    data = data[UT.sizeof .. $];
    return cast(typeof(return))ret;
}

@safe pure
private static void handleMsgPackElement(S)(ref S serializer, MessagePackFmt type, scope ref const(ubyte)[] data)
{
    size_t length = 0;
    switch (type) 
    {
        // fixint
        case MessagePackFmt.fixint: .. case (1 << 7) - 1:
            serializer.putValue(cast(ubyte)type);
            break;

        // fixnint
        case MessagePackFmt.fixnint: .. case 0xFF:
            serializer.putValue(cast(byte)type);
            break;

        case MessagePackFmt.uint8:
            serializer.putValue(data[0]);
            data = data[1 .. $];
            break;
        
        case MessagePackFmt.uint16:
            serializer.putValue(unpackMsgPackVal!ushort(data));
            break;

        case MessagePackFmt.uint32:
            serializer.putValue(unpackMsgPackVal!uint(data));
            break;
        
        case MessagePackFmt.uint64:
            serializer.putValue(unpackMsgPackVal!ulong(data));
            break;

        case MessagePackFmt.int8:
            serializer.putValue(cast(byte)data[0]);
            data = data[1 .. $];
            break;
        
        case MessagePackFmt.int16:
            serializer.putValue(unpackMsgPackVal!short(data));
            break;

        case MessagePackFmt.int32:
            serializer.putValue(unpackMsgPackVal!int(data));
            break;

        case MessagePackFmt.int64:
            serializer.putValue(unpackMsgPackVal!long(data));
            break;

        case MessagePackFmt.fixmap: .. case MessagePackFmt.fixmap + 0xF:
        case MessagePackFmt.map16:
        case MessagePackFmt.map32:
            goto ReadMap;

        case MessagePackFmt.fixarray: .. case MessagePackFmt.fixarray + 0xF:
        case MessagePackFmt.array16:
        case MessagePackFmt.array32:
            goto ReadArray;

        case MessagePackFmt.fixstr: .. case MessagePackFmt.fixstr + 0x1F:
        case MessagePackFmt.str8:
        case MessagePackFmt.str16:
        case MessagePackFmt.str32:
            goto ReadStr;

        case MessagePackFmt.nil:
            serializer.putValue(null);
            break;

        case MessagePackFmt.true_:
        case MessagePackFmt.false_:
            serializer.putValue(type == MessagePackFmt.true_ ? true : false);
            break;

        case MessagePackFmt.bin8: .. case MessagePackFmt.bin32:
            goto ReadBin;
            
        case MessagePackFmt.fixext1: .. case MessagePackFmt.fixext16:
        case MessagePackFmt.ext8: .. case MessagePackFmt.ext32:
            goto ReadExt;

        case MessagePackFmt.float32:
        case MessagePackFmt.float64:
            goto ReadFloat;

        ReadMap:
        {
            import mir.format : stringBuf, print;
            if (type <= MessagePackFmt.fixmap + 0xF && type >= MessagePackFmt.fixmap)
            {
                length = (type - MessagePackFmt.fixmap);
            }
            else if (type == MessagePackFmt.map16)
            {
                length = unpackMsgPackVal!ushort(data);
            }
            else if (type == MessagePackFmt.map32)
            {
                length = unpackMsgPackVal!uint(data);
            }
            else
            {
                assert(0, "Should never happen");
            }

            auto state = serializer.structBegin();
            foreach(i; 0 .. length)
            {
                if (data.length < 1)
                {
                    version (D_Exceptions)
                        throw IonErrorCode.unexpectedEndOfData.ionException;
                    else
                        assert(0, IonErrorCode.unexpectedEndOfData.ionErrorMsg);
                }

                MessagePackFmt keyType = cast(MessagePackFmt)data[0];
                data = data[1 .. $];
                stringBuf keyBuf;
                uint keyLength = 0;
                switch (keyType)
                {
                    // fixstr
                    case MessagePackFmt.fixstr: .. case MessagePackFmt.fixstr + 0x1F:
                    case MessagePackFmt.str8:
                    case MessagePackFmt.str16:
                    case MessagePackFmt.str32:
                        goto StrKey;

                    case MessagePackFmt.fixint: .. case (1 << 7) - 1:
                    case MessagePackFmt.uint8:
                    case MessagePackFmt.uint16:
                    case MessagePackFmt.uint32:
                    case MessagePackFmt.uint64:
                        goto UIntKey;

                    case MessagePackFmt.fixnint: .. case 0xFF:
                    case MessagePackFmt.int8:
                    case MessagePackFmt.int16:
                    case MessagePackFmt.int32:
                    case MessagePackFmt.int64:
                        goto IntKey;
                    
                    case MessagePackFmt.fixext1: .. case MessagePackFmt.fixext16:
                    case MessagePackFmt.ext8: .. case MessagePackFmt.ext32:
                        goto TimestampKey;

                    StrKey:
                    {
                        if (keyType <= MessagePackFmt.fixstr + 0x1F && keyType >= MessagePackFmt.fixstr)
                        {
                            keyLength = (keyType - MessagePackFmt.fixstr);
                        }
                        else if (keyType == MessagePackFmt.str8)
                        {
                            keyLength = unpackMsgPackVal!ubyte(data);
                        }
                        else if (keyType == MessagePackFmt.str16)
                        {
                            keyLength = unpackMsgPackVal!ushort(data);
                        }
                        else if (keyType == MessagePackFmt.str32)
                        {
                            keyLength = unpackMsgPackVal!uint(data);
                        }
                        else
                        {
                            assert(0, "Should never happen");
                        }

                        serializer.putKey((() @trusted => cast(const(char[]))data[0 .. keyLength])());
                        data = data[keyLength .. $];
                        break;
                    }

                    UIntKey:
                    {
                        ulong val = 0;
                        if (keyType <= (1 << 7) - 1 && keyType >= MessagePackFmt.fixint)
                        {
                            val = keyType;
                        }
                        else if (keyType == MessagePackFmt.uint8)
                        {
                            val = unpackMsgPackVal!ubyte(data);
                        }
                        else if (keyType == MessagePackFmt.uint16)
                        {
                            val = unpackMsgPackVal!ushort(data);
                        }
                        else if (keyType == MessagePackFmt.uint32)
                        {
                            val = unpackMsgPackVal!uint(data);
                        }
                        else if (keyType == MessagePackFmt.uint64)
                        {
                            val = unpackMsgPackVal!ulong(data);
                        }
                        else
                        {
                            assert(0, "Should never happen");
                        }

                        keyBuf.print(val);
                        serializer.putKey(keyBuf.data);
                        break;
                    }

                    IntKey:
                    {
                        long val = 0;
                        if (keyType <= 0xFF && keyType >= MessagePackFmt.fixnint)
                        {
                            val = cast(byte)keyType;
                        }
                        else if (keyType == MessagePackFmt.int8)
                        {
                            val = unpackMsgPackVal!byte(data);
                        }
                        else if (keyType == MessagePackFmt.int16)
                        {
                            val = unpackMsgPackVal!short(data);
                        }
                        else if (keyType == MessagePackFmt.int32)
                        {
                            val = unpackMsgPackVal!int(data);
                        }
                        else if (keyType == MessagePackFmt.int64)
                        {
                            val = unpackMsgPackVal!long(data);
                        }
                        else
                        {
                            assert(0, "Should never happen");
                        }

                        keyBuf.print(val);
                        serializer.putKey(keyBuf.data[0 .. keyBuf.length]);
                        break;
                    }

                    // Ugly mess here
                    TimestampKey: {
                        if (keyType <= MessagePackFmt.fixext16 && keyType >= MessagePackFmt.fixext1)
                        {
                            keyLength = 1 << (keyType - MessagePackFmt.fixext1);
                        }
                        else if (keyType == MessagePackFmt.ext8)
                        {
                            keyLength = unpackMsgPackVal!ubyte(data);
                        }
                        else if (keyType == MessagePackFmt.ext16)
                        {
                            keyLength = unpackMsgPackVal!ushort(data);
                        }
                        else if (keyType == MessagePackFmt.ext32)
                        {
                            keyLength = unpackMsgPackVal!uint(data);
                        }
                        else
                        {
                            assert(0, "Should never happen");
                        }

                        if (data.length < (keyLength + 1)) 
                        {
                            version (D_Exceptions)
                                throw IonErrorCode.unexpectedEndOfData.ionException;
                            else
                                assert(0, IonErrorCode.unexpectedEndOfData.ionErrorMsg);
                        }
                        
                        ubyte ext_type = data[0];
                        data = data[1 .. $];

                        if (ext_type == cast(ubyte)-1)
                        {
                            import mir.timestamp : Timestamp;
                            Timestamp time;
                            if (keyLength == 4)
                            {
                                uint unixTime = unpackMsgPackVal!uint(data);
                                time = Timestamp.fromUnixTime(unixTime);
                            }
                            else if (keyLength == 8)
                            {
                                ulong packedUnixTime = unpackMsgPackVal!ulong(data);
                                ulong nanosecs = packedUnixTime >> 34;
                                ulong seconds = packedUnixTime & 0x3ffffffff;
                                time = Timestamp.fromUnixTime(seconds);
                                time.fractionExponent = -9;
                                time.fractionCoefficient = nanosecs;
                                time.precision = Timestamp.Precision.fraction;
                            }
                            else if (keyLength == 12)
                            {
                                uint nanosecs = unpackMsgPackVal!uint(data);
                                long seconds = unpackMsgPackVal!long(data);
                                time = Timestamp.fromUnixTime(seconds);
                                time.fractionExponent = -9;
                                time.fractionCoefficient = nanosecs;
                                time.precision = Timestamp.Precision.fraction;
                            }
                            else
                            {
                                version (D_Exceptions)
                                    throw IonErrorCode.cantParseValueStream.ionException;
                                else
                                    assert(0, IonErrorCode.cantParseValueStream.ionErrorMsg);
                            }

                            time.toString(keyBuf);
                            serializer.putKey(keyBuf.data[0 .. keyBuf.length]);
                        }
                        else
                        {
                            version (D_Exceptions)
                                throw IonErrorCode.cantParseValueStream.ionException;
                            else
                                assert(0, IonErrorCode.cantParseValueStream.ionErrorMsg);
                        }
                        break;
                    }

                    default:
                        version (D_Exceptions)
                            throw IonErrorCode.cantParseValueStream.ionException;
                        else
                            assert(0, IonErrorCode.cantParseValueStream.ionErrorMsg);
                }

                MessagePackFmt valueType = cast(MessagePackFmt)data[0];
                data = data[1 .. $];
                handleMsgPackElement(serializer, valueType, data);
            }
            serializer.structEnd(state);
            break;
        }
        
        ReadArray:
        {
            if (type <= MessagePackFmt.fixarray + 0xF && type >= MessagePackFmt.fixarray)
            {
                length = (type - MessagePackFmt.fixarray);
            }
            else if (type == MessagePackFmt.array16)
            {
                length = unpackMsgPackVal!ushort(data);
            }
            else if (type == MessagePackFmt.array32)
            {
                length = unpackMsgPackVal!uint(data);
            }
            else
            {
                assert(0, "Should never happen");
            }

            auto state = serializer.listBegin(length);
            foreach(i; 0 .. length)
            {
                if (data.length < 1)
                {
                    version (D_Exceptions)
                        throw IonErrorCode.unexpectedEndOfData.ionException;
                    else
                        assert(0, IonErrorCode.unexpectedEndOfData.ionErrorMsg);
                }

                MessagePackFmt elementType = cast(MessagePackFmt)data[0];
                data = data[1 .. $];
            
                serializer.elemBegin;
                handleMsgPackElement(serializer, elementType, data);
            }
            serializer.listEnd(state);
            break;
        }

        ReadExt:
        {
            if (type <= MessagePackFmt.fixext16 && type >= MessagePackFmt.fixext1)
            {
                length = 1 << (type - MessagePackFmt.fixext1);
            }
            else if (type == MessagePackFmt.ext8)
            {
                length = unpackMsgPackVal!ubyte(data);
            }
            else if (type == MessagePackFmt.ext16)
            {
                length = unpackMsgPackVal!ushort(data);
            }
            else if (type == MessagePackFmt.ext32)
            {
                length = unpackMsgPackVal!uint(data);
            }
            else
            {
                assert(0, "Should never happen");
            }

            if (data.length < (length + 1)) 
            {
                version (D_Exceptions)
                    throw IonErrorCode.unexpectedEndOfData.ionException;
                else
                    assert(0, IonErrorCode.unexpectedEndOfData.ionErrorMsg);
            }
            
            ubyte ext_type = data[0];
            data = data[1 .. $];

            if (ext_type == cast(ubyte)-1)
            {
                import mir.timestamp : Timestamp;
                Timestamp time;
                if (length == 4)
                {
                    uint unixTime = unpackMsgPackVal!uint(data);
                    time = Timestamp.fromUnixTime(unixTime);
                }
                else if (length == 8)
                {
                    ulong packedUnixTime = unpackMsgPackVal!ulong(data);
                    ulong nanosecs = packedUnixTime >> 34;
                    ulong seconds = packedUnixTime & 0x3ffffffff;
                    time = Timestamp.fromUnixTime(seconds);
                    time.fractionExponent = -9;
                    time.fractionCoefficient = nanosecs;
                    time.precision = Timestamp.Precision.fraction;
                }
                else if (length == 12)
                {
                    uint nanosecs = unpackMsgPackVal!uint(data);
                    long seconds = unpackMsgPackVal!long(data);
                    time = Timestamp.fromUnixTime(seconds);
                    time.fractionExponent = -9;
                    time.fractionCoefficient = nanosecs;
                    time.precision = Timestamp.Precision.fraction;
                }

                serializer.putValue(time);
            }
            else
            {
                // XXX: How do we want to serialize exts that we don't recognize?
                auto state = serializer.structBegin();
                serializer.putKey("type");
                serializer.putValue(ext_type);
                serializer.putKey("data");
                serializer.putValue(Blob(data[0 .. length]));
                serializer.structEnd(state);
                data = data[length .. $];
            }
            break;
        }
        
        ReadStr:
        {
            if (type <= MessagePackFmt.fixstr + 0x1F && type >= MessagePackFmt.fixstr)
            {
                length = (type - MessagePackFmt.fixstr);
            }
            else if (type == MessagePackFmt.str8)
            {
                length = unpackMsgPackVal!ubyte(data); 
            }
            else if (type == MessagePackFmt.str16)
            {
                length = unpackMsgPackVal!ushort(data);
            }
            else if (type == MessagePackFmt.str32)
            {
                length = unpackMsgPackVal!uint(data);
            }
            else 
            {
                assert(0, "Should never happen");
            }

            if (data.length < length) 
            {
                version (D_Exceptions)
                    throw IonErrorCode.unexpectedEndOfData.ionException;
                else
                    assert(0, IonErrorCode.unexpectedEndOfData.ionErrorMsg);
            }

            serializer.putValue((() @trusted => cast(const(char)[])data[0 .. length])());
            data = data[length .. $];
            break;
        }
        
        ReadBin:
        {
            length = 0;

            if (type == MessagePackFmt.bin8)
            {
                length = unpackMsgPackVal!ubyte(data);
            }
            else if (type == MessagePackFmt.bin16)
            {
                length = unpackMsgPackVal!ushort(data);
            }
            else if (type == MessagePackFmt.bin32)
            {
                length = unpackMsgPackVal!uint(data);
            }
            else 
            {
                assert(0, "Should never happen");
            }

            if (data.length < length)
            {
                version (D_Exceptions)
                    throw IonErrorCode.unexpectedEndOfData.ionException;
                else
                    assert(0, IonErrorCode.unexpectedEndOfData.ionErrorMsg);
            }
            serializer.putValue(Blob(data[0 .. length]));
            data = data[length .. $];
            break;
        }
        
        ReadFloat:
        {
            length = type == MessagePackFmt.float32 ? 4 : 8;

            if (length == 4)
            {
                uint v = unpackMsgPackVal!uint(data);
                serializer.putValue((() @trusted => *cast(float*)&v)());
            }
            else if (length == 8)
            {
                // manually construct the ulong
                ulong v = unpackMsgPackVal!ulong(data);
                serializer.putValue((() @trusted => *cast(double*)&v)());
            }
            break;
        }

        default:
            version (D_Exceptions)
                throw IonErrorCode.cantParseValueStream.ionException;
            else
                assert(0, IonErrorCode.cantParseValueStream.ionErrorMsg);
    }
}

///
struct MsgpackValueStream
{
    const(ubyte)[] data;

    void serialize(S)(ref S serializer) const
    {
        auto window = data[0 .. $];
        bool following = false;
        while (window.length)
        {
            if (following)
                serializer.nextTopLevelValue;
            following = true;

            MessagePackFmt type = cast(MessagePackFmt)window[0];
            window = window[1 .. $];
            handleMsgPackElement(serializer, type, window);
        }
    }
}

///
void deserializeMsgpack(T)(ref T value, scope const(ubyte)[] data)
{
    import mir.appender : scopedBuffer;
    import mir.deser.ion : deserializeIon;
    import mir.ion.conv : msgpack2ion;
    auto buf = scopedBuffer!ubyte();
    data.msgpack2ion(buf);
    return deserializeIon!T(value, buf.data);
}

///
T deserializeMsgpack(T)(scope const(ubyte)[] data)
{
    T value;
    deserializeMsgpack!T(value, data);
    return value;
}

/// Test round-trip serialization/deserialization of signed integral types
@safe pure
version (mir_ion_test)
unittest
{
    import mir.ser.msgpack : serializeMsgpack;

    // Bytes
    assert(serializeMsgpack(byte.min).deserializeMsgpack!byte == byte.min);
    assert(serializeMsgpack(byte.max).deserializeMsgpack!byte == byte.max);
    assert(serializeMsgpack(byte(-32)).deserializeMsgpack!byte == -32);

    // Shorts
    assert(serializeMsgpack(short.min).deserializeMsgpack!short == short.min);
    assert(serializeMsgpack(short.max).deserializeMsgpack!short == short.max);

    // Integers
    assert(serializeMsgpack(int.min).deserializeMsgpack!int == int.min);
    assert(serializeMsgpack(int.max).deserializeMsgpack!int == int.max);

    // Longs
    assert(serializeMsgpack(long.min).deserializeMsgpack!long == long.min);
    assert(serializeMsgpack(long.max).deserializeMsgpack!long == long.max);
}

/// Test round-trip serialization/deserialization of unsigned integral types
@safe pure
version (mir_ion_test)
unittest
{
    import mir.ser.msgpack : serializeMsgpack;

    // Unsigned bytes
    assert(serializeMsgpack(ubyte.min).deserializeMsgpack!ubyte == ubyte.min);
    assert(serializeMsgpack(ubyte.max).deserializeMsgpack!ubyte == ubyte.max);

    // Unsigned shorts
    assert(serializeMsgpack(ushort.min).deserializeMsgpack!ushort == ushort.min);
    assert(serializeMsgpack(ushort.max).deserializeMsgpack!ushort == ushort.max);

    // Unsigned integers
    assert(serializeMsgpack(uint.min).deserializeMsgpack!uint == uint.min);
    assert(serializeMsgpack(uint.max).deserializeMsgpack!uint == uint.max);

    // Unsigned logns
    assert(serializeMsgpack(ulong.min).deserializeMsgpack!ulong == ulong.min);
    assert(serializeMsgpack(ulong.max).deserializeMsgpack!ulong == ulong.max);

    // BigInt
    import mir.bignum.integer : BigInt;
    assert(serializeMsgpack(BigInt!2(0xDEADBEEF)).deserializeMsgpack!long == 0xDEADBEEF);
}

/// Test round-trip serialization/deserialization of null
@safe pure
version (mir_ion_test)
unittest
{
    import mir.ser.msgpack : serializeMsgpack;

    assert(serializeMsgpack(null).deserializeMsgpack!(typeof(null)) == null);
}

/// Test round-trip serialization/deserialization of booleans
@safe pure
version (mir_ion_test)
unittest
{
    import mir.ser.msgpack : serializeMsgpack;

    assert(serializeMsgpack(true).deserializeMsgpack!bool == true);
    assert(serializeMsgpack(false).deserializeMsgpack!bool == false);
}

/// Test round-trip serialization/deserialization of strings
@safe pure
version (mir_ion_test)
unittest
{
    import std.array : replicate;
    import mir.ser.msgpack : serializeMsgpack;

    assert("foobar".serializeMsgpack.deserializeMsgpack!string == "foobar");
    assert("bazfoo".serializeMsgpack.deserializeMsgpack!string == "bazfoo");

    {
        auto str = "a".replicate(32);
        assert(serializeMsgpack(str).deserializeMsgpack!string == str);
    }

    {
        auto str = "a".replicate(ushort.max);
        assert(serializeMsgpack(str).deserializeMsgpack!string == str);
    }

    {
        auto str = "a".replicate(ushort.max + 1);
        assert(serializeMsgpack(str).deserializeMsgpack!string == str);
    }
}

/// Test round-trip serializing/deserialization blobs / clobs
@safe pure
version(mir_ion_test)
unittest
{
    import mir.lob : Blob, Clob;
    import mir.ser.msgpack : serializeMsgpack;
    import std.array : replicate;

    // Blobs
    // These need to be trusted because we cast const(char)[] to ubyte[] (which is fine here!)
    () @trusted {
        auto de = "\xde".replicate(32);
        auto blob = Blob(cast(ubyte[])de);
        assert(serializeMsgpack(blob).deserializeMsgpack!Blob == blob);
    } ();
    
    () @trusted {
        auto de = "\xde".replicate(ushort.max);
        auto blob = Blob(cast(ubyte[])de);
        assert(serializeMsgpack(blob).deserializeMsgpack!Blob == blob);
    } ();

    () @trusted {
        auto de = "\xde".replicate(ushort.max + 1);
        auto blob = Blob(cast(ubyte[])de);
        assert(serializeMsgpack(blob).deserializeMsgpack!Blob == blob);
    } ();

    // Clobs (serialized just as regular strings here)
    () @trusted {
        auto de = "\xde".replicate(32);
        auto clob = Clob(de);
        assert(serializeMsgpack(clob).deserializeMsgpack!string == clob.data);
    } ();
}

/// Test round-trip serialization/deserialization of arrays
@safe pure
version (mir_ion_test)
unittest
{
    import mir.ser.msgpack : serializeMsgpack;

    {
        auto arr = [["foo"], ["bar"], ["baz"]];
        assert(serializeMsgpack(arr).deserializeMsgpack!(typeof(arr)) == arr);
    }

    {
        auto arr = [0xDEADBEEF, 0xCAFEBABE, 0xAAAA_AAAA];
        assert(serializeMsgpack(arr).deserializeMsgpack!(typeof(arr)) == arr);
    }

    {
        auto arr = ["foo", "bar", "baz"];
        assert(serializeMsgpack(arr).deserializeMsgpack!(typeof(arr)) == arr);
    }

    {
        auto arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
        assert(serializeMsgpack(arr).deserializeMsgpack!(typeof(arr)) == arr);
    }
}

@safe pure
version (mir_ion_test)
unittest
{
    import mir.ser.msgpack : serializeMsgpack;
    assert((0.0f).serializeMsgpack.deserializeMsgpack!(float) == 0.0f);
    assert((0.0).serializeMsgpack.deserializeMsgpack!(double) == 0.0);

    assert((float.min_normal).serializeMsgpack.deserializeMsgpack!(float) == float.min_normal);
    assert((float.max).serializeMsgpack.deserializeMsgpack!(float) == float.max);
    assert((double.min_normal).serializeMsgpack.deserializeMsgpack!(double) == double.min_normal);
    assert((double.max).serializeMsgpack.deserializeMsgpack!(double) == double.max);
}

@safe pure
version (mir_ion_test)
unittest
{
    import mir.ser.msgpack : serializeMsgpack;
    import mir.timestamp : Timestamp;
    assert(Timestamp(2022, 2, 14).serializeMsgpack.deserializeMsgpack!(Timestamp) == Timestamp(2022, 2, 14, 0, 0, 0));
    assert(Timestamp(2038, 1, 19, 3, 14, 7).serializeMsgpack.deserializeMsgpack!Timestamp == Timestamp(2038, 1, 19, 3, 14, 7));
    assert(Timestamp(2299, 12, 31, 23, 59, 59).serializeMsgpack.deserializeMsgpack!Timestamp == Timestamp(2299, 12, 31, 23, 59, 59, -9, 0));
    assert(Timestamp(2514, 5, 30, 1, 53, 5).serializeMsgpack.deserializeMsgpack!Timestamp == Timestamp(2514, 5, 30, 1, 53, 5, -9, 0));
    assert(Timestamp(2000, 7, 8, 2, 3, 4, -3, 16).serializeMsgpack.deserializeMsgpack!(Timestamp) == Timestamp(2000, 7, 8, 2, 3, 4, -9, 16000000));
}

/// Test serializing maps (structs)
@safe pure
version(mir_ion_test)
unittest
{
    import mir.ser.msgpack : serializeMsgpack;
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

    assert(serializeMsgpack(book).deserializeMsgpack!(Book) == book);
}

/// Test serializing maps (structs), assuming @nogc
@safe pure @nogc
version(mir_ion_test)
unittest
{
    import mir.appender : scopedBuffer;
    import mir.ser.msgpack : serializeMsgpack;
    // import mir.small_string;

    static struct Book
    {
        // SmallStrings apparently cannot be serialized
        // without allocating?
        // SmallString!64 title;
        bool wouldRecommend;
        // SmallString!64 description;
        uint numberOfNovellas;
        double price;
        float weight;
    }

    auto buf = scopedBuffer!ubyte();
    Book book = Book(true, 5, 7.99, 6.88);
    serializeMsgpack((() @trusted => &buf)(), book);
    assert(buf.data.deserializeMsgpack!Book() == book);
}

/// Test round-trip serialization/deserialization of a large map
@safe pure
version(mir_ion_test)
unittest
{
    import mir.ser.msgpack : serializeMsgpack;
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
    assert(serializeMsgpack(s).deserializeMsgpack!HugeStruct == s);
}

/// Test excessively large array
@safe pure
version(mir_ion_test)
unittest
{
    import mir.ser.msgpack : serializeMsgpack;
    static struct HugeArray
    {
        ubyte[] arg;

        void serialize(S)(ref S serializer) const
        {
            auto state = serializer.structBegin();
            serializer.putKey("arg");
            auto arrayState = serializer.listBegin(); 
            foreach(i; 0 .. (ushort.max + 1))
            {
                serializer.elemBegin; serializer.putValue(ubyte(0));
            }
            serializer.listEnd(arrayState);
            serializer.structEnd(state);
        }
    }

    auto arr = HugeArray();
    assert((serializeMsgpack(arr).deserializeMsgpack!HugeArray).arg.length == ushort.max + 1);
}

/// Test excessively large map
@safe pure
version(mir_ion_test)
unittest
{
    import mir.serde : serdeAllowMultiple;
    import mir.ser.msgpack : serializeMsgpack;
    static struct BFM // Big Freakin' Map
    {
        @serdeAllowMultiple
        ubyte asdf;

        void serialize(S)(ref S serializer) const
        {
            auto state = serializer.structBegin();
            foreach (i; 0 .. (ushort.max + 1))
            {
                serializer.putKey("asdf");
                serializer.putValue(ubyte(0));
            }
            serializer.structEnd(state);
        }
    }

    auto map = BFM();
    assert(serializeMsgpack(map).deserializeMsgpack!BFM == map);
}

/// Test map with varying key lengths
@safe pure
version(mir_ion_test)
unittest
{
    import mir.ser.msgpack : serializeMsgpack;
    import std.array : replicate;
    ubyte[string] map;
    map["a".replicate(32)] = 0xFF;
    map["b".replicate(ubyte.max + 1)] = 0xFF;
    map["c".replicate(ushort.max + 1)] = 0xFF;

    assert(serializeMsgpack(map).deserializeMsgpack!(typeof(map)) == map);
}

/// Test deserializing an extension type
@safe pure
version(mir_ion_test)
unittest
{
    import mir.lob : Blob;

    {
        const(ubyte)[] data = [0xc7, 0x01, 0x02, 0xff];
        MsgpackExtension ext = MsgpackExtension(Blob([0xff]), 0x02);
        assert(data.deserializeMsgpack!MsgpackExtension == ext);
    }

    {
        const(ubyte)[] data = [0xc8, 0x00, 0x01, 0x02, 0xff];
        MsgpackExtension ext = MsgpackExtension(Blob([0xff]), 0x02);
        assert(data.deserializeMsgpack!MsgpackExtension == ext);
    }

    {
        const(ubyte)[] data = [0xc9, 0x00, 0x00, 0x00, 0x01, 0x02, 0xff];
        MsgpackExtension ext = MsgpackExtension(Blob([0xff]), 0x02);
        assert(data.deserializeMsgpack!MsgpackExtension == ext);
    }
}

@safe pure
version(mir_ion_test) unittest
{
    static struct S
    {
        bool compact;
        int schema;
    }
    const(ubyte)[] data = [0x82, 0xa7, 0x63, 0x6f, 0x6d, 0x70, 0x61, 0x63, 0x74, 0xc3, 0xa6, 0x73, 0x63, 0x68, 0x65, 0x6d, 0x61, 0x04];
    assert(data.deserializeMsgpack!S == S(true, 4));
}

@safe pure
version(mir_ion_test) unittest
{
    // fixnint
    {
        const(ubyte)[] data = [0x81, 0xe0, 0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == ["-32": 0xfe]);
    }

    // fixint
    {
        const(ubyte)[] data = [0x81, 0x7f, 0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == ["127": 0xfe]);
    }

    // uint8
    {
        const(ubyte)[] data = [0x81, 0xcc, 0xff, 0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == ["255": 0xfe]);
    }

    // int8
    {
        const(ubyte)[] data = [0x81, 0xd0, 0x81, 0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == ["-127": 0xfe]);
    }

    // uint16
    {
        const(ubyte)[] data = [0x81, 0xcd, 0xde, 0xad, 0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == ["57005": 0xfe]);
    }
    
    // int16
    {
        const(ubyte)[] data = [0x81, 0xd1, 0xde, 0xad, 0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == ["-8531": 0xfe]);
    }

    // uint32
    {
        const(ubyte)[] data = [0x81, 0xce, 0xde, 0xad, 0xbe, 0xef, 0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == ["3735928559": 0xfe]);
    }

    // int32
    {
        const(ubyte)[] data = [0x81, 0xd2, 0xde, 0xad, 0xbe, 0xef, 0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == ["-559038737": 0xfe]);
    }

    static if (ulong.sizeof == 8)
    {
        // uint64
        {
            const(ubyte)[] data = [0x81, 0xcf, 0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef, 0xcc, 0xfe];
            assert(data.deserializeMsgpack!(int[string]) == ["16045690984833335023": 0xfe]);
        }

        // int64
        {
            const(ubyte)[] data = [0x81, 0xd3, 0xde, 0xad, 0xbe, 0xef, 0xde, 0xad, 0xbe, 0xef, 0xcc, 0xfe];
            assert(data.deserializeMsgpack!(int[string]) == ["-2401053088876216593": 0xfe]);
        }
    }
}

@safe pure
version(mir_ion_test) unittest
{
    import mir.ser.msgpack : serializeMsgpack;
    import mir.timestamp : Timestamp;

    {
        auto time = Timestamp(2022, 2, 14, 0, 0, 0);
        const(ubyte)[] data = [0x81];
        data ~= time.serializeMsgpack;
        data ~= [0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == [time.toString(): 0xfe]);
    }

    {
        auto time = Timestamp(2038, 1, 19, 3, 14, 7);
        const(ubyte)[] data = [0x81];
        data ~= time.serializeMsgpack;
        data ~= [0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == [time.toString(): 0xfe]);
    }

    {
        auto time = Timestamp(2299, 12, 31, 23, 59, 59);
        const(ubyte)[] data = [0x81];
        data ~= time.serializeMsgpack;
        data ~= [0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == [Timestamp(2299, 12, 31, 23, 59, 59, -9, 0).toString(): 0xfe]);
    }

    {
        auto time = Timestamp(2514, 5, 30, 1, 53, 5);
        const(ubyte)[] data = [0x81];
        data ~= time.serializeMsgpack;
        data ~= [0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == [Timestamp(2514, 5, 30, 1, 53, 5, -9, 0).toString(): 0xfe]);
    }

    // ext8
    {
        auto time = Timestamp(2000, 7, 8, 2, 3, 4, -3, 16);
        const(ubyte)[] data = [0x81];
        data ~= time.serializeMsgpack;
        data ~= [0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == [Timestamp(2000, 7, 8, 2, 3, 4, -9, 16000000).toString(): 0xfe]);
    }

    // ext16
    {
        const(ubyte)[] data = [0x81, 0xc8, 0x00, 0x08, 0xff, 0x03, 0xd0, 0x90, 0x00, 0x39, 0x66, 0x8b, 0xd8, 0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == [Timestamp(2000, 7, 8, 2, 3, 4, -9, 16_000_000).toString(): 0xfe]);
    }

    // ext32
    {
        const(ubyte)[] data = [0x81, 0xc9, 0x00, 0x00, 0x00, 0x08, 0xff, 0x03, 0xd0, 0x90, 0x00, 0x39, 0x66, 0x8b, 0xd8, 0xcc, 0xfe];
        assert(data.deserializeMsgpack!(int[string]) == [Timestamp(2000, 7, 8, 2, 3, 4, -9, 16_000_000).toString(): 0xfe]);
    }
}

// Test bad MessagePack data
version (mir_ion_test)
unittest
{
    import mir.ion.exception : IonException;

    // Run out of bytes before a full integer can be read
    {
        const(ubyte)[] data = [0xdb, 0x00, 0x00];
        bool caught = false;
        try
        {
            data.deserializeMsgpack!(string);
        }
        catch (IonException e)
        {
            caught = true;
        }

        assert(caught);
    }

    // Run out of bytes in a map
    {
        const(ubyte)[] data = [0x81];
        bool caught = false;
        try
        {
            data.deserializeMsgpack!(int[string]);
        }
        catch (IonException e)
        {
            caught = true;
        }

        assert(caught);
    }
    
    // Run out of bytes in a list
    {
        const(ubyte)[] data = [0x91];
        bool caught = false;
        try
        {
            data.deserializeMsgpack!(int[]);
        }
        catch (IonException e)
        {
            caught = true;
        }

        assert(caught);
    }

    // Run out of bytes in a string
    {
        const(ubyte)[] data = [0xa1];
        bool caught = false;
        try
        {
            data.deserializeMsgpack!(string);
        }
        catch (IonException e)
        {
            caught = true;
        }

        assert(caught);
    }
    
    // Run out of bytes in a binary blob
    {
        import mir.lob : Blob;
        const(ubyte)[] data = [0xc4, 0x01];
        bool caught = false;
        try
        {
            data.deserializeMsgpack!(Blob);
        }
        catch (IonException e)
        {
            caught = true;
        }
        
        assert(caught);
    }

    // Run out of bytes in a extension type
    {
        const(ubyte)[] data = [0xd4];
        bool caught = false;
        try
        {
            data.deserializeMsgpack!(MsgpackExtension);
        }
        catch (IonException e)
        {
            caught = true;
        }

        assert(caught);
    }

    // Test a map with a timestamp key that runs out of bytes
    {
        const(ubyte)[] data = [0x81, 0xc7, 0xff];
        bool caught = false;
        try
        {
            data.deserializeMsgpack!(int[string]);
        }
        catch (IonException e)
        {
            caught = true;
        }

        assert(caught);
    }

    // Test a map with a timestamp key that has an invalid length
    {
        const(ubyte)[] data = [0x81, 0xc7, 0x01, 0xff, 0x00, 0xcc, 0xfe];
        bool caught = false;
        try
        {
            data.deserializeMsgpack!(int[string]);
        }
        catch (IonException e)
        {
            caught = true;
        }

        assert(caught);
    }

    // Test a map with an invalid extension type
    {
        const(ubyte)[] data = [0x81, 0xc7, 0x01, 0xfe, 0x00, 0xcc, 0xfe];
        bool caught = false;
        try
        {
            data.deserializeMsgpack!(int[string]);
        }
        catch (IonException e)
        {
            caught = true;
        }

        assert(caught);
    }

    // Test a map with an unrecognized key
    {
        const(ubyte)[] data = [0x81, 0xc4];
        bool caught = false;
        try
        {
            data.deserializeMsgpack!(int[string]);
        }
        catch (IonException e)
        {
            caught = true;
        }

        assert(caught);
    }

    // Test an invalid type descriptor
    {
        const(ubyte)[] data = [0xc1];
        bool caught = false;
        try
        {
            data.deserializeMsgpack!(bool);
        }
        catch (IonException e)
        {
            caught = true;
        }

        assert(caught);
    }
}