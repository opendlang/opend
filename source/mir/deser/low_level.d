/++
+/
module mir.deser.low_level;

import mir.appender: scopedBuffer, ScopedBuffer;
import mir.bignum.decimal: Decimal;
import mir.bignum.integer: BigInt;
import mir.ion.exception;
import mir.ion.internal.basic_types;
import mir.ion.type_code;
import mir.ion.value;
import mir.rc.array: RCArray;
import mir.small_array;
import mir.small_string;
import mir.timestamp;
import mir.utility: _expect;
import mir.serde: serdeGetFinalProxy;
import mir.lob : Clob, Blob;

import std.traits:
    isArray,
    isAggregateType,
    ForeachType,
    hasUDA,
    isFloatingPoint,
    isIntegral,
    isSigned,
    isSomeChar,
    isUnsigned,
    Unqual;

template isFirstOrderSerdeType(T)
{
    import mir.serde: serdeGetFinalProxy, serdeLikeStruct, serdeLikeList;

    static if (isAggregateType!T)
    {
        static if (is(T == Clob) || is(T == Blob))
            enum isFirstOrderSerdeType = true;
        else
        static if (isBigInt!T)
            enum isFirstOrderSerdeType = true;
        else
        static if (isDecimal!T)
            enum isFirstOrderSerdeType = true;
        else
        static if (isTimestamp!T || is(typeof(Timestamp(T.init))) && __traits(getAliasThis, T).length == 0)
            enum isFirstOrderSerdeType = true;
        else
        static if (is(T : SmallString!maxLength, size_t maxLength))
            enum isFirstOrderSerdeType = false;
        else
        static if (is(T : SmallArray!(E, maxLength), E, size_t maxLength))
            enum isFirstOrderSerdeType = isFirstOrderSerdeType!E;
        else
        static if (is(T : RCArray!E, E))
            enum isFirstOrderSerdeType = isFirstOrderSerdeType!E;
        else
        static if (hasUDA!(T, serdeLikeStruct) || hasUDA!(T, serdeLikeList))
            enum isFirstOrderSerdeType = false;
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
    static if (is(T == enum))
        enum isFirstOrderSerdeType = false;
    else
    static if (isSomeChar!T)
        enum isFirstOrderSerdeType = false;
    else
    static if (is(T == serdeGetFinalProxy!T))
        enum isFirstOrderSerdeType = true;
    else
        enum isFirstOrderSerdeType = isFirstOrderSerdeType!(serdeGetFinalProxy!T, false);
}

version(mir_ion_test)
unittest
{
    import std.datetime.date;
    import std.datetime.systime;
    static assert(isFirstOrderSerdeType!Date);
    static assert(isFirstOrderSerdeType!DateTime);
    static assert(isFirstOrderSerdeType!SysTime);
}

version(mir_ion_test)
unittest
{
    import mir.date;
    static assert(isFirstOrderSerdeType!Date);
}

/++
Deserialize `null` value
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, scope ref T value)
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
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, scope ref T value)
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
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, scope ref T value)
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
IonErrorCode deserializeValueImpl(T : BigInt!maxSize64, size_t maxSize64)(IonDescribedValue data, scope ref T value)
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
Deserialize Blob value.
+/
IonErrorCode deserializeValueImpl()(IonDescribedValue data, ref Blob value)
    pure @safe nothrow
{
    Blob ionValue;
    if (auto error = data.get(ionValue))
        return error;
    value = ionValue.data.dup.Blob;
    return IonErrorCode.none;
}

///
version(mir_ion_test) unittest
{
    import mir.deser.ion : deserializeIon;
    import mir.lob : Blob;
    import mir.ser.ion : serializeIon;

    static struct BlobWrapper { Blob blob; }
    auto blob = BlobWrapper(Blob([0xF0, 0x00, 0xBA, 0x50]));
    auto serdeBlob = serializeIon(blob).deserializeIon!BlobWrapper;
    assert(serdeBlob == blob);
}

/++
Deserialize Clob value.
+/
IonErrorCode deserializeValueImpl()(IonDescribedValue data, ref Clob value)
    pure @safe nothrow
{
    Clob ionValue;
    if (auto error = data.get(ionValue))
        return error;
    value = ionValue.data.dup.Clob;
    return IonErrorCode.none;
}

///
version(mir_ion_test) unittest
{
    import mir.deser.ion : deserializeIon;
    import mir.lob : Clob;
    import mir.ser.ion : serializeIon;

    static struct ClobWrapper { Clob clob; }
    auto clob = ClobWrapper(Clob("abcd"));
    auto serdeClob = serializeIon(clob).deserializeIon!ClobWrapper;
    assert(serdeClob == clob);
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
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, scope ref T value)
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

            enum bool allowSpecialValues = true;
            enum bool allowDotOnBounds = true;
            enum bool allowDExponent = true;
            enum bool allowStartingPlus = true;
            enum bool allowUnderscores = false;
            enum bool allowLeadingZeros = true;
            enum bool allowExponent = true;
            enum bool checkEmpty = false;

            if (!decimal.fromStringImpl!(
                char,
                allowSpecialValues,
                allowDotOnBounds,
                allowDExponent,
                allowStartingPlus,
                allowUnderscores,
                allowLeadingZeros,
                allowExponent,
                checkEmpty,
            )(ionValue, exponentKey))
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
IonErrorCode deserializeValueImpl(T : Decimal!maxW64bitSize, size_t maxW64bitSize)(IonDescribedValue data, scope ref T value)
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
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, scope ref T value)
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

///ditto
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, scope ref T value)
    // pure @safe nothrow @nogc
    if (!(hasProxy!T && !hasLikeStruct!T && isFirstOrderSerdeType!T) && is(typeof(Timestamp.init.opCast!T)))
{
    Timestamp temporal;
    if (auto error = .deserializeValueImpl(data, temporal))
        return error;
    value = temporal.opCast!T;
    return IonErrorCode.none;
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
    static if (is(T == enum) || isAggregateType!T)
        enum hasProxy = hasUDA!(T, serdeProxy);
    else
        enum hasProxy = false;
}

package template hasLikeStruct(T)
{
    import mir.serde: serdeLikeStruct;
    static if (is(T == enum) || isAggregateType!T)
        enum hasLikeStruct = hasUDA!(T, serdeLikeStruct);
    else
        enum hasLikeStruct = false;
}

package template hasDiscriminatedField(T)
{
    import mir.serde: serdeDiscriminatedField;
    static if (is(T == enum) || isAggregateType!T)
        enum hasDiscriminatedField = hasUDA!(T, serdeDiscriminatedField);
    else
        enum hasDiscriminatedField = false;
}

package template hasFallbackStruct(T)
{
    import mir.serde: serdeFallbackStruct;
    static if (is(T == enum) || isAggregateType!T)
        enum hasFallbackStruct = hasUDA!(T, serdeFallbackStruct);
    else
        enum hasFallbackStruct = false;
}

/++
Deserialize struct/class value with proxy.
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, scope ref T value)
    if (hasProxy!T && !hasLikeStruct!T && isFirstOrderSerdeType!T)
{
    import std.traits: Select;
    import mir.serde: serdeGetProxy, serdeScoped, serdeScoped;
    import mir.conv: to;

    serdeGetProxy!T proxy;
    deserializeValueImpl(data, proxy);
    value = proxy.to!T;
    return IonErrorCode.none;
}

/++
Deserialize enum value.
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, scope ref T value)
    if (is(T == enum) && !hasProxy!T)
{
    import mir.serde: serdeParseEnum;
    scope const(char)[] ionValue;
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
Deserialize ascii value from ion string.
+/
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, scope ref T value)
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

private IonErrorCode deserializeListToScopedBuffer(Buffer)(IonDescribedValue data, ref Buffer buffer)
{
    auto ionValue = data.trustedGet!IonList;
    foreach (IonErrorCode error, IonDescribedValue ionElem; ionValue)
    {
        import std.traits: Unqual;
        if (_expect(error, false))
            return error;
        Unqual!(typeof(buffer.data[0])) value;
        error = deserializeValueImpl(ionElem, value);
        if (_expect(error, false))
            return error;
        import core.lifetime: move;
        buffer.put(move(value));
    }
    return IonErrorCode.none;
}


///
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, scope ref T value)
    if (is(T == E[], E) && !isSomeChar!E)
{
    alias E = Unqual!(ForeachType!T);
    if (data.descriptor.type == IonTypeCode.list)
    {
        import std.array: std_appender = appender;
        auto buffer = std_appender!(E[]);
        if (auto error = deserializeListToScopedBuffer(data, buffer))
            return error;
        value = buffer.data;
        return IonErrorCode.none;
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
IonErrorCode deserializeValueImpl(T)(IonDescribedValue data, scope ref T value)
    if (is(T == RCArray!E, E) && !isSomeChar!E)
{
    alias E = Unqual!(ForeachType!T);
    if (data.descriptor.type == IonTypeCode.list)
    {
        import core.lifetime: move;
        import std.traits: TemplateArgsOf;
        auto buffer = scopedBuffer!E;
        if (auto error = deserializeListToScopedBuffer(data, buffer))
            return error;
        auto ar = RCArray!E(buffer.length, false);
        () @trusted {
            buffer.moveDataAndEmplaceTo(ar[]);
        } ();
        static if (__traits(compiles, value = move(ar)))
            value = move(ar);
        else () @trusted {
            value = ar.opCast!T;
        } ();
        return IonErrorCode.none;
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
    import mir.ion.exception;
    import mir.ion.value;
    import mir.rc.array: RCArray;

    auto data = IonValue([
        0xbe, 0x91, 0x00, 0x00, 0x21, 0x0c,
        0x00, 0x00, 0x48, 0x43, 0x0c, 0x6b,
        0xf5, 0x26, 0x34, 0x00, 0x00, 0x00,
        0x00]).describe;

    RCArray!(const double) value;
    assert(deserializeValueImpl(data, value) == IonErrorCode.none);
    assert(value[] == [12, 100e13]);
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
IonErrorCode deserializeValueImpl(T : E[N], E, size_t N)(IonDescribedValue data, out T value)
{
    if (data.descriptor.type == IonTypeCode.list)
    {
        size_t i;
        foreach (IonErrorCode error, IonDescribedValue ionElem; data.trustedGet!IonList)
        {
            if (_expect(error, false))
                return error;
            if (i >= N)
                return IonErrorCode.tooManyElementsForStaticArray;
            error = .deserializeValueImpl(ionElem, value[i++]);
            if (_expect(error, false))
                return error;
        }
        if (i < N)
            return IonErrorCode.notEnoughElementsForStaticArray;
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
