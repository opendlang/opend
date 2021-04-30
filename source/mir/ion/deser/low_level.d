/++
+/
module mir.ion.deser.low_level;

import mir.appender: ScopedBuffer;
import mir.bignum.decimal: Decimal;
import mir.bignum.integer: BigInt;
import mir.ion.exception;
import mir.ion.internal.basic_types;
import mir.ion.type_code;
import mir.ion.value;
import mir.reflection: isSomeStruct;
import mir.small_array;
import mir.small_string;
import mir.timestamp;
import mir.utility: _expect;

import std.traits:
    isArray,
    ForeachType,
    hasUDA,
    isFloatingPoint,
    isIntegral,
    isSigned,
    isSomeChar,
    isUnsigned,
    Unqual;

package template isFirstOrderSerdeType(T)
{
    import mir.serde: serdeGetFinalProxy;

    static if (isSomeStruct!T)
    {
        static if (isBigInt!T)
            enum isFirstOrderSerdeType = true;
        else
        static if (isDecimal!T)
            enum isFirstOrderSerdeType = true;
        else
        static if (isTimestamp!T)
            enum isFirstOrderSerdeType = true;
        else
        static if (is(T : SmallString!maxLength, size_t maxLength))
            enum isFirstOrderSerdeType = true;
        else
        static if (is(T : SmallArray!(E, maxLength), E, size_t maxLength))
            enum isFirstOrderSerdeType = isFirstOrderSerdeType!E;
        else
        static if (is(T == serdeGetFinalProxy!T))
            enum isFirstOrderSerdeType = false;
        else
            enum isFirstOrderSerdeType = isFirstOrderSerdeType!(serdeGetFinalProxy!T);
    }
    else
    static if (isArray!T)
        enum isFirstOrderSerdeType = .isFirstOrderSerdeType!(Unqual!(ForeachType!T));
    else
    static if (is(T == V[K], K, V))
        enum isFirstOrderSerdeType = false;
    else
    static if (is(T == serdeGetFinalProxy!T))
        enum isFirstOrderSerdeType = true;
    else
        enum isFirstOrderSerdeType = isFirstOrderSerdeType!(serdeGetFinalProxy!T);
}

package(mir.ion) template isNullable(T)
{
    import std.traits : hasMember;

    static if (
        hasMember!(T, "isNull") &&
        is(typeof(__traits(getMember, T, "isNull")) == bool) &&
        hasMember!(T, "get") &&
        // !is(typeof(T.init.get()) == void) &&
        hasMember!(T, "nullify") // &&
        // is(typeof(__traits(getMember, T, "nullify")) == void)
    )
    {
        enum isNullable = true;
    }
    else
    {
        enum isNullable = false;
    }
}

/++
Deserialize `null` value
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, ref T value)
    pure @safe nothrow @nogc
    if (is(T == typeof(null)))
{
    version (LDC) pragma(inline, true);
    return data == null ? IonErrorCode.none : IonErrorCode.expectedNullValue;
}

///
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;

    auto data = IonValue([0x1F]).describe; // null.bool
    typeof(null) value;
    assert(deserializeValueImpl!(typeof(null))(data, value) == IonErrorCode.none);
}

/++
Deserialize boolean value
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, ref T value)
    pure @safe nothrow @nogc
    if (is(T == bool))
{
    return data.get(value);
}

///
pure version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;

    auto data = IonValue([0x11]).describe;
    bool value;
    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value);
}

/++
Deserialize integral value.
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, ref T value)
    pure @safe nothrow @nogc
    if (isIntegral!T && !is(T == enum))
{
    static if (__traits(isUnsigned, T))
    {
        IonUInt ionValue;
        if (auto error = data.get(ionValue))
            return error;
        return ionValue.get!T(value);
    }
    else
    {
        IonInt ionValue;
        if (auto error = data.get(ionValue))
            return error;
        return ionValue.get!T(value);
    }
}

///
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;

    auto data = IonValue([0x21, 0x07]).describe;
    int valueS;
    uint valueU;

    assert(deserializeValueImpl(data, valueS) == IonErrorCode.none);
    assert(valueS == 7);

    assert(deserializeValueImpl(data, valueU) == IonErrorCode.none);
    assert(valueU == 7);

    data = IonValue([0x31, 0x07]).describe;

    assert(deserializeValueImpl(data, valueS) == IonErrorCode.none);
    assert(valueS == -7);
}

/++
Deserialize big integer value.
+/
IonErrorCode deserializeValueImpl(T : BigInt!maxSize64, size_t maxSize64)(IonDescribedValue data, ref T value)
    pure @safe nothrow @nogc
{
    IonInt ionValue;
    if (auto error = data.get(ionValue))
        return error;
    if (value.copyFrom(ionValue.field))
        return IonErrorCode.integerOverflow;
    return IonErrorCode.none;
}

///
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;
    import mir.bignum.integer;

    auto data = IonValue([0x31, 0x07]).describe;
    BigInt!256 value = void; // 256x64

    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value.sign);
    assert(value.view.unsigned == 7);
}

/++
Deserialize floating point value.

Special_deserialisation_symbol_values:

$(TABLE
    $(TR $(TD `nan"`))
    $(TR $(TD `+inf"`))
    $(TR $(TD `-inf`))
)
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, ref T value)
    pure @safe nothrow @nogc
    if (isFloatingPoint!T)
{
    if (_expect(data != null, true))
    {
        if (data.descriptor.type == IonTypeCode.float_)
        {
            return data.trustedGet!IonFloat.get!T(value);
        }
        else
        if (data.descriptor.type == IonTypeCode.decimal)
        {
            return data.trustedGet!IonDecimal.get!T(value);
        }
        else
        if (data.descriptor.type == IonTypeCode.uInt || data.descriptor.type == IonTypeCode.nInt)
        {
            IonInt ionValue;
            if (auto error = data.get(ionValue))
                return error;
            value = cast(T) ionValue.field;
            return IonErrorCode.none;
        }
        else
        {
            const(char)[] ionValue;
            if (auto error = data.get(ionValue))
                return error;

            import mir.bignum.decimal;
            Decimal!256 decimal = void;
            DecimalExponentKey exponentKey;

            if (!decimal.fromStringImpl(ionValue, exponentKey))
                return IonErrorCode.expectedFloatingValue;

            value = cast(T) decimal;
            return IonErrorCode.none;
        }
    }
    return IonErrorCode.expectedFloatingValue;
}

///
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;
    // from ion float
    auto data = IonValue([0x44, 0x42, 0xAA, 0x40, 0x00]).describe;
    double value;

    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value == 85.125);

    // from ion double
    data = IonValue([0x48, 0x40, 0x55, 0x48, 0x00, 0x00, 0x00, 0x00, 0x00]).describe;

    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value == 85.125);

    // from ion decimal
    data = IonValue([0x56, 0x00, 0xcb, 0x80, 0xbc, 0x2d, 0x86]).describe;

    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value == -12332422e75);
}

/++
Deserialize decimal value.
+/
IonErrorCode deserializeValueImpl(T : Decimal!maxW64bitSize, size_t maxW64bitSize)(IonDescribedValue data, ref T value)
    pure @safe nothrow @nogc
{
    IonDecimal ionValue;
    if (auto error = data.get(ionValue))
        return error;
    IonDescribedDecimal ionDescribedDecimal;
    if (auto error = ionValue.get(ionDescribedDecimal))
        return error;
    return ionDescribedDecimal.get(value);
}

///
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;
    import mir.bignum.decimal;

    Decimal!256 value; // 256x64 bits

    // from ion decimal
    auto data = IonValue([0x56, 0x00, 0xcb, 0x80, 0xbc, 0x2d, 0x86]).describe;

    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(cast(double)value == -12332422e75);
}

/++
Deserialize timestamp value.
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, ref T value)
    pure @safe nothrow @nogc
    if (is(T == Timestamp))
{
    if (_expect(data != null, true))
    {
        if (data.descriptor.type == IonTypeCode.timestamp)
        {
            return data.trustedGet!IonTimestamp.get!T(value);
        }
        else
        {
            const(char)[] ionValue;
            if (!data.get(ionValue) && Timestamp.fromString(ionValue, value))
                return IonErrorCode.none;
        }
    }
    return IonErrorCode.expectedTimestampValue;
}

///
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;
    import mir.bignum.decimal;

    Decimal!256 value; // 256x64 bits

    // from ion decimal
    auto data = IonValue([0x56, 0x00, 0xcb, 0x80, 0xbc, 0x2d, 0x86]).describe;

    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(cast(double)value == -12332422e75);
}

package template hasProxy(T)
{
    import mir.serde: serdeProxy;
    static if (is(T == enum) || isSomeStruct!T)
        enum hasProxy = hasUDA!(T, serdeProxy);
    else
        enum hasProxy = false;
}

package template hasScoped(T)
{
    import mir.serde: serdeScoped;
    static if (is(T == enum) || isSomeStruct!T)
        enum hasScoped = hasUDA!(T, serdeScoped);
    else
        enum hasScoped = false;
}

/++
Deserialize struct/class value with proxy.
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, ref T value)
    if (hasProxy!T && isFirstOrderSerdeType!T)
{
    import std.traits: Select;
    import mir.serde: serdeGetProxy, serdeScoped, serdeScoped;
    import mir.conv: to;

    serdeGetProxy!T proxy;
    enum S = hasUDA!(T, serdeScoped) && __traits(compiles, .deserializeScopedValueImpl(data, proxy));
    alias Fun = Select!(S, .deserializeScopedValueImpl, .deserializeValueImpl);
    Fun(data, proxy);
    value = proxy.to!T;
    return IonErrorCode.none;
}

/++
Deserialize enum value.
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, ref T value)
    if (is(T == enum) && !hasProxy!T)
{
    import mir.serde: serdeParseEnum;
    const(char)[] ionValue;
    if (auto error = data.get(ionValue))
        return error;
    if (serdeParseEnum(ionValue, value))
        return IonErrorCode.none;
    return IonErrorCode.expectedEnumValue;
}

///
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;
    enum E {a, b, c}

    // from ion string
    auto data = IonValue([0x81, 'b']).describe;
    E value;

    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value == E.b);
}

/++
Deserialize string value.
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, ref T value)
    pure @safe nothrow
    if (is(T == string) || is(T == const(char)[]) || is(T == char[]))
{
    // TODO: symbol deserialization
    if (_expect(data.descriptor.type != IonTypeCode.string && data.descriptor.type != IonTypeCode.null_, false))
        return IonErrorCode.expectedStringValue;
    auto ionValue = data.trustedGet!(const(char)[]);
    static if (is(T == string))
        value = ionValue.idup;
    else
        value = ionValue.dup;
    return IonErrorCode.none; 
}

///
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;

    auto data = IonValue([0x83, 'b', 'a', 'r']).describe;
    string value;

    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value == "bar");
}

/++
Deserialize small string value.
+/
IonErrorCode deserializeValueImpl(T : SmallString!maxLength, size_t maxLength)(IonDescribedValue data, ref T value)
    pure @safe nothrow
{
    // TODO: symbol deserialization
    if (_expect(data.descriptor.type != IonTypeCode.string && data.descriptor.type != IonTypeCode.null_, false))
        return IonErrorCode.expectedStringValue;
    auto ionValue = data.trustedGet!(const(char)[]);
    if (ionValue.length > maxLength)
        return IonErrorCode.smallStringOverflow;
    value.trustedAssign(ionValue);
    return IonErrorCode.none; 
}

///
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;

    auto data = IonValue([0x83, 'b', 'a', 'r']).describe;
    string value;

    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value == "bar");
}

/++
Deserialize ascii value from ion string.
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, ref T value)
    pure @safe nothrow
    if (is(T == char))
{
    const(char)[] ionValue;
    if (auto error = data.get(ionValue))
        return error;
    if (_expect(ionValue.length != 1, false))
        return IonErrorCode.expectedCharValue; 
    value = ionValue[0];
    return IonErrorCode.none; 
}

///
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;

    auto data = IonValue([0x81, 'b']).describe;
    char value;

    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value == 'b');
}

private IonErrorCode deserializeListToScopedBuffer(E, size_t bytes)(IonDescribedValue data, ref ScopedBuffer!(E, bytes) buffer)
{
    auto ionValue = data.trustedGet!IonList;
    foreach (IonErrorCode error, IonDescribedValue ionElem; ionValue)
    {
        if (_expect(error, false))
            return error;
        E value;
        error = deserializeValueImpl(ionElem, value);
        if (_expect(error, false))
            return error;
        import core.lifetime: move;
        buffer.put(move(value));
    }
    return IonErrorCode.none;
}

/++
Deserializes scoped string value.
This function does not allocate a new string and just make a raw cast of Ion data.
+/
IonErrorCode deserializeScopedValueImpl(T)(IonDescribedValue data, ref T value)
    pure @trusted nothrow @nogc
    if (is(T == string) || is(T == const(char)[]) || is(T == char[]))
{
    // TODO: symbol deserialization
    if (_expect(data.descriptor.type != IonTypeCode.string && data.descriptor.type != IonTypeCode.null_, false))
        return IonErrorCode.expectedStringValue;
    auto ionValue = data.trustedGet!(const(char)[]);
    value = cast(T)ionValue;
    return IonErrorCode.none; 
}

///
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;

    auto data = IonValue([0x83, 'b', 'a', 'r']).describe;
    string value;

    assert(deserializeScopedValueImpl(data, value) == IonErrorCode.none);
    assert(value == "bar");
}

///
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, ref T value)
    if (is(T == E[], E) && !isSomeChar!E)
{
    alias E = Unqual!(ForeachType!T);
    if (data.descriptor.type == IonTypeCode.list)
    {
        if (false)
        {
            ScopedBuffer!E buffer;
            if (auto error = deserializeListToScopedBuffer(data, buffer))
                return error;
        }
        return () @trusted {
            import std.array: uninitializedArray;
            ScopedBuffer!E buffer = void;
            buffer.initialize;
            if (auto error = deserializeListToScopedBuffer(data, buffer))
                return error;
            auto ar = uninitializedArray!(E[])(buffer.length);
            buffer.moveDataAndEmplaceTo(ar);
            value = cast(T) ar;
            return IonErrorCode.none;
        } ();
    }
    else
    if (data.descriptor.type == IonTypeCode.null_)
    {
        value = null;
        return IonErrorCode.none;
    }
    return IonErrorCode.expectedListValue;
}

///
@safe pure
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;

    auto data = IonValue([
        0xbe, 0x91, 0x00, 0x00, 0x21, 0x0c,
        0x00, 0x00, 0x48, 0x43, 0x0c, 0x6b,
        0xf5, 0x26, 0x34, 0x00, 0x00, 0x00,
        0x00]).describe;

    double[] value;
    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value == [12, 100e13]);
}

///
IonErrorCode deserializeValueImpl(T : SmallArray!(E, maxLength), E, size_t maxLength)(IonDescribedValue data, out T value)
{
    if (data.descriptor.type == IonTypeCode.list)
    {
        foreach (IonErrorCode error, IonDescribedValue ionElem; data.trustedGet!IonList)
        {
            if (_expect(error, false))
                return error;
            if (value._length == maxLength)
                return IonErrorCode.smallArrayOverflow;
            E elem;
            error = .deserializeValueImpl(ionElem, elem);
            if (_expect(error, false))
                return error;
            import core.lifetime: move;
            value.trustedAppend(move(elem));
        }
        return IonErrorCode.none;
    }
    else
    if (data.descriptor.type == IonTypeCode.null_)
    {
        return IonErrorCode.none;
    }
    return IonErrorCode.expectedListValue;
}

///
@safe pure
version(mir_ion_test) unittest
{
    import mir.ion.value;
    import mir.ion.exception;
    import mir.small_array;

    auto data = IonValue([
        0xbe, 0x91, 0x00, 0x00, 0x21, 0x0c,
        0x00, 0x00, 0x48, 0x43, 0x0c, 0x6b,
        0xf5, 0x26, 0x34, 0x00, 0x00, 0x00,
        0x00]).describe;
    
    SmallArray!(double, 3) value;
    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value == [12, 100e13]);
}
