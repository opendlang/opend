/++
+/
module mir.ion.value;

import mir.bignum.decimal: Decimal;
import mir.bignum.low_level_view;
import mir.bignum.low_level_view: BigUIntView;
import mir.ion.exception;
import mir.ion.lob;
import mir.ion.type_code;
import mir.utility: _expect;
import std.traits: isMutable, isIntegral, isSigned, isUnsigned, Unsigned, Signed, isFloatingPoint;

/++
Ion Version Marker
+/
struct IonVersionMarker
{
    /// Major Version
    ushort major = 1;
    /// Minor Version
    ushort minor = 0;
}

/// Aliases the $(SUBREF type_code, IonTypeCode) to the corresponding Ion Typed Value type.
alias IonType(IonTypeCode code : IonTypeCode.null_) = IonNull;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.bool_) = bool;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.uInt) = IonUInt;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.nInt) = IonNInt;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.float_) = IonFloat;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.decimal) = IonDecimal;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.timestamp) = IonTimestamp;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.symbol) = IonSymbolID;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.string) = const(char)[];
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.clob) = IonClob;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.blob) = IonBlob;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.list) = IonList;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.sexp) = IonSexp;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.struct_) = IonStruct;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.annotations) = IonAnnotationWrapper;

/// Aliases the type to the corresponding $(SUBREF type_code, IonTypeCode).
alias IonTypeCodeOf(T : IonNull) = IonTypeCode.null_;
/// ditto
alias IonTypeCodeOf(T : bool) = IonTypeCode.bool_;
/// ditto
alias IonTypeCodeOf(T : IonUInt) = IonTypeCode.uInt;
/// ditto
alias IonTypeCodeOf(T : IonNInt) = IonTypeCode.nInt;
/// ditto
alias IonTypeCodeOf(T : IonFloat) = IonTypeCode.float_;
/// ditto
alias IonTypeCodeOf(T : IonDecimal) = IonTypeCode.decimal;
/// ditto
alias IonTypeCodeOf(T : IonTimestamp) = IonTypeCode.timestamp;
/// ditto
alias IonTypeCodeOf(T : IonSymbolID) = IonTypeCode.symbol;
/// ditto
alias IonTypeCodeOf(T : const(char)[]) = IonTypeCode.string;
/// ditto
alias IonTypeCodeOf(T : IonClob) = IonTypeCode.clob;
/// ditto
alias IonTypeCodeOf(T : IonBlob) = IonTypeCode.blob;
/// ditto
alias IonTypeCodeOf(T : IonList) = IonTypeCode.list;
/// ditto
alias IonTypeCodeOf(T : IonSexp) = IonTypeCode.sexp;
/// ditto
alias IonTypeCodeOf(T : IonStruct) = IonTypeCode.struct_;
/// ditto
alias IonTypeCodeOf(T : IonAnnotationWrapper) = IonTypeCode.annotations;

/++
A template to check if the type is one of Ion Typed Value types.
See_also: $(SUBREF type_code, IonTypeCode)
+/
enum isIonType(T) = false;
/// ditto
enum isIonType(T : IonNull) = true;
/// ditto
enum isIonType(T : bool) = true;
/// ditto
enum isIonType(T : IonUInt) = true;
/// ditto
enum isIonType(T : IonNInt) = true;
/// ditto
enum isIonType(T : IonFloat) = true;
/// ditto
enum isIonType(T : IonDecimal) = true;
/// ditto
enum isIonType(T : IonTimestamp) = true;
/// ditto
enum isIonType(T : IonSymbolID) = true;
/// ditto
enum isIonType(T : const(char)[]) = true;
/// ditto
enum isIonType(T : IonClob) = true;
/// ditto
enum isIonType(T : IonBlob) = true;
/// ditto
enum isIonType(T : IonList) = true;
/// ditto
enum isIonType(T : IonSexp) = true;
/// ditto
enum isIonType(T : IonStruct) = true;
/// ditto
enum isIonType(T : IonAnnotationWrapper) = true;

/// Ion null value.
struct IonNull
{
    ///
    IonTypeCode code;

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        serializer.putNull(code);
    }
}

/++
Ion Value

The type descriptor octet has two subfields: a four-bit type code T, and a four-bit length L.

----------
       7       4 3       0
      +---------+---------+
value |    T    |    L    |
      +---------+---------+======+
      :     length [VarUInt]     :
      +==========================+
      :      representation      :
      +==========================+
----------
+/
struct IonValue
{
    const(ubyte)[] data;

    /++
    Describes value (nothrow version).
    Params:
        value = (out) $(LREF IonDescribedValue)
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode describe(scope ref IonDescribedValue value)
        @safe pure nothrow @nogc const
    {
        auto d = data[];
        if (auto error = parseValue(d, value))
            return error;
        if (_expect(d.length, false))
            return IonErrorCode.illegalBinaryData;
        return IonErrorCode.none;
    }

    version (D_Exceptions)
    {
        /++
        Describes value.
        Returns: $(LREF IonDescribedValue)
        +/
        IonDescribedValue describe()
            @safe pure @nogc const
        {
            IonDescribedValue ret;
            if (auto error = describe(ret))
                throw error.ionException;
            return ret;
        }
    }

    /++
    Returns: GC-allocated copy.
    +/
    @safe pure nothrow const
    IonValue gcCopy()()
    {
        return IonValue(data.dup);
    }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        describe.serialize(serializer);
    }

    ///
    unittest
    {
        import mir.ion.ser.json;
        assert(IonValue([0x11]).serializeJson == "true");
    }
}

/++
Ion Type Descriptor
+/
struct IonDescriptor
{
    /++
    The type descriptor octet has two subfields: a four-bit type code T, and a four-bit length L.
    +/
    this(scope const(ubyte)* reference)
        @safe pure nothrow @nogc
    {
        assert(reference);
        this.type = cast(IonTypeCode)((*reference) >> 4);
        assert(type <= IonTypeCode.max);
        this.L = cast(uint)((*reference) & 0xF);
    }

    /// T
    IonTypeCode type;

    /// L
    uint L;
}

/++
Ion Described Value stores type descriptor and rerpresentation.
+/
struct IonDescribedValue
{
    /// Type Descriptor
    IonDescriptor descriptor;
    /// Rerpresentation
    const(ubyte)[] data;

    /++
    Returns: true if the value is any Ion `null`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return descriptor.L == 0xF;
    }

    /++
    Gets typed value (nothrow version).
    Params:
        value = (out) Ion Typed Value
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T)(ref T value)
        @safe pure nothrow @nogc const
        if (isIonType!T || is(T == IonInt))
    {
        static if (is(T == IonNull))
        {
            if (_expect(descriptor.L != 0xF, false))
                return IonErrorCode.unexpectedIonType;
        }
        else
        static if (is(T == IonInt))
        {
            if (_expect(descriptor.L == 0xF || (descriptor.type | 1) != IonTypeCodeOf!IonNInt, false))
                return IonErrorCode.unexpectedIonType;
        }
        else
        {
            if (_expect(descriptor.L == 0xF || descriptor.type != IonTypeCodeOf!T, false))
                return IonErrorCode.unexpectedIonType;
        }
        value = trustedGet!T;
        return IonErrorCode.none;
    }

    /++
    Gets typed value.
    Returns: Ion Typed Value
    +/
    T get(T)()
        @safe pure @nogc const
        if (isIonType!T || is(T == IonInt))
    {
        static if (is(T == IonNull))
        {
            if (_expect(descriptor.L != 0xF, false))
                throw IonErrorCode.unexpectedIonType.ionException;
        }
        else
        static if (is(T == IonInt))
        {
            if (_expect(descriptor.type == IonTypeCode.null_ || (descriptor.type | 1) != IonTypeCodeOf!IonNInt, false))
                throw IonErrorCode.unexpectedIonType.ionException;
        }
        else
        {
            if (_expect(descriptor.type == IonTypeCode.null_ || descriptor.type != IonTypeCodeOf!T, false))
                throw IonErrorCode.unexpectedIonType.ionException;
        }
        return trustedGet!T;
    }

    /++
    Gets typed value (nothrow internal version).
    Returns:
        Ion Typed Value
    Note:
        This function doesn't check the encoded value type.
    +/
    T trustedGet(T)()
        @safe pure nothrow @nogc const
        if (isIonType!T || is(T == IonInt))
    {
        static if (is(T == IonInt))
        {
            assert(descriptor.type == IonTypeCode.null_ || (descriptor.type == IonTypeCodeOf!IonNInt || descriptor.type == IonTypeCodeOf!IonUInt), T.stringof);
        }
        else
        static if (is(T == IonNull))
        {
            assert(descriptor.L == 0xF, T.stringof);
        }
        else
        {
            assert(descriptor.type == IonTypeCode.null_ ||  descriptor.type == IonTypeCodeOf!T, T.stringof);
        }

        static if (is(T == IonNull))
        {
            return T(descriptor.type);
        }
        else
        static if (is(T == bool))
        {
            return descriptor.L & 1;
        }
        else
        static if (is(T == IonStruct))
        {
            return T(descriptor, data);
        }
        else
        static if (is(T == const(char)[]))
        {
            return cast(const(char)[])data;
        }
        else
        static if (is(T == IonClob))
        {
            return T(cast(const(char)[])data);
        }
        else
        static if (is(T == IonUInt) || is(T == IonNInt) || is(T == IonSymbolID))
        {
            return T(BigUIntView!(const ubyte, WordEndian.big)(data));
        }
        else
        static if (is(T == IonInt))
        {
            return T(BigIntView!(const ubyte, WordEndian.big)(data, descriptor.type & 1));
        }
        else
        {
            return T(data);
        }
    }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        if (this == null)
        {
            trustedGet!IonNull.serialize(serializer);
        }
        else
        {
            final switch (descriptor.type) with (IonTypeCode)
            {
                case IonTypeCode.null_:
                    assert(0);
                case IonTypeCode.bool_:
                    serializer.putValue(trustedGet!bool);
                    break;
                case IonTypeCode.uInt:
                case IonTypeCode.nInt:
                    // trustedGet!IonInt.serialize(serializer);
                    break;
                case IonTypeCode.float_:
                    trustedGet!IonFloat.serialize(serializer);
                    break;
                case IonTypeCode.decimal:
                    trustedGet!IonDecimal.serialize(serializer);
                    break;
                case IonTypeCode.timestamp:
                    trustedGet!IonTimestamp.serialize(serializer);
                    break;
                case IonTypeCode.symbol:
                    // trustedGet!IonSymbolID.serialize(serializer);
                    break;
                case IonTypeCode.string:
                    // trustedGet!(const(char)[]).serialize(serializer);
                    break;
                case IonTypeCode.clob:
                    // trustedGet!IonClob.serialize(serializer);
                    break;
                case IonTypeCode.blob:
                    // trustedGet!IonBlob.serialize(serializer);
                    break;
                case IonTypeCode.list:
                    // trustedGet!IonList.serialize(serializer);
                    break;
                case IonTypeCode.sexp:
                    // trustedGet!IonSexp.serialize(serializer);
                    break;
                case IonTypeCode.struct_:
                    // trustedGet!IonStruct.serialize(serializer);
                    break;
                case IonTypeCode.annotations:
                    // trustedGet!IonAnnotationWrapper.serialize(serializer);
                    break;
            }
        }
    }
}

/++
Ion integer field.
+/
struct IonIntField
{
    ///
    const(ubyte)[] data;

    /++
    Params:
        value = (out) signed integer
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T)(scope ref T value)
        @safe pure nothrow @nogc const
        if (isSigned!T)
    {
        auto d = cast()data;
        size_t i;
        T f;
        bool s;
        if (d.length == 0)
            goto R;
        f = d[0] & 0x7F;
        s = d[0] >> 7;
        for(;;)
        {
            d = d[1 .. $];
            if (d.length == 0)
            {
                if (_expect(f < 0, false))
                    break;
                if (s)
                    f = cast(T)(0-f);
            R:
                value = f;
                return IonErrorCode.none;
            }
            i += cast(bool)f;
            f <<= 8;
            f |= d[0];
            if (_expect(i >= T.sizeof, false))
                break;
        }
        return IonErrorCode.overflowInIntegerValue;
    }

    version (D_Exceptions)
    {
        /++
        Returns: signed integer
        Precondition: `this != null`.
        +/
        T get(T)()
            @safe pure @nogc const
            if (isSigned!T)
        {
            T ret;
            if (auto error = get(ret))
                throw error.ionException;
            return ret;
        }
    }

    /++
    Returns: $(SUBREF exception, IonErrorCode)
    Precondition: `this != null`.
    +/
    IonErrorCode getErrorCode(T)()
        @trusted pure nothrow @nogc const
        if (isSigned!T)
    {
        T value;
        return get!T(value);
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    assert(IonValue([0x1F]).describe.get!IonNull.code == IonTypeCode.bool_);
    assert(IonValue([0x10]).describe.get!bool == false);
    assert(IonValue([0x11]).describe.get!bool == true);
}

/++
Ion non-negative integer number.
+/
struct IonUInt
{
    ///
    BigUIntView!(const ubyte, WordEndian.big) field;


    /++
    Returns: true if the integer isn't `null.int` and equals to `rhs`.
    +/
    bool opEquals(ulong rhs)
        @safe pure nothrow @nogc const
    {
        return field == rhs;
    }

    /++
    Params:
        value = (out) unsigned or signed integer
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T)(scope ref T value)
        @trusted pure nothrow @nogc const
        if (isIntegral!T)
    {
        static if (isUnsigned!T)
        {
            return field.get(value) ? IonErrorCode.overflowInIntegerValue : IonErrorCode.none;
        }
        else
        {
            if (auto overflow = field.get(*cast(Unsigned!T*)&value))
                return IonErrorCode.overflowInIntegerValue;
            if (_expect(value < 0, false))
                return IonErrorCode.overflowInIntegerValue;
            return IonErrorCode.none;
        }
    }

    version (D_Exceptions)
    {
        /++
        Returns: unsigned or signed integer
        +/
        T get(T)()
            @safe pure @nogc const
            if (isIntegral!T)
        {
            T ret;
            if (auto error = get(ret))
                throw error.ionException;
            return ret;
        }
    }

    /++
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode getErrorCode(T)()
        @trusted pure nothrow @nogc const
        if (isIntegral!T)
    {
        T value;
        return get!T(value);
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    assert(IonValue([0x2F]).describe.get!IonNull == IonNull(IonTypeCode.uInt));
    assert(IonValue([0x21, 0x07]).describe.get!IonUInt.get!int == 7);

    int v;
    assert(IonValue([0x22, 0x01, 0x04]).describe.get!IonUInt.get(v) == IonErrorCode.none);
    assert(v == 260);
}

@safe pure
version(mir_ion_test) unittest
{
    alias AliasSeq(T...) = T;
    foreach (T; AliasSeq!(byte, short, int, long, ubyte, ushort, uint, ulong))
    {
        assert(IonValue([0x20]).describe.get!IonUInt.getErrorCode!T == 0);
        assert(IonValue([0x21, 0x00]).describe.get!IonUInt.getErrorCode!T == 0);

        assert(IonValue([0x21, 0x07]).describe.get!IonUInt.get!T == 7);
        assert(IonValue([0x2E, 0x81, 0x07]).describe.get!IonUInt.get!T == 7);
        assert(IonValue([0x2A, 0,0,0, 0,0,0, 0,0,0, 0x07]).describe.get!IonUInt.get!T == 7);
    }

    assert(IonValue([0x21, 0x7F]).describe.get!IonUInt.get!byte == byte.max);
    assert(IonValue([0x22, 0x7F, 0xFF]).describe.get!IonUInt.get!short == short.max);
    assert(IonValue([0x24, 0x7F, 0xFF,0xFF,0xFF]).describe.get!IonUInt.get!int == int.max);
    assert(IonValue([0x28, 0x7F, 0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF]).describe.get!IonUInt.get!long == long.max);
    assert(IonValue([0x2A, 0,0, 0x7F, 0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF]).describe.get!IonUInt.get!long == long.max);

    assert(IonValue([0x21, 0xFF]).describe.get!IonUInt.get!ubyte == ubyte.max);
    assert(IonValue([0x22, 0xFF, 0xFF]).describe.get!IonUInt.get!ushort == ushort.max);
    assert(IonValue([0x24, 0xFF, 0xFF,0xFF,0xFF]).describe.get!IonUInt.get!uint == uint.max);
    assert(IonValue([0x28, 0xFF, 0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF]).describe.get!IonUInt.get!ulong == ulong.max);
    assert(IonValue([0x2A, 0,0, 0xFF, 0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF]).describe.get!IonUInt.get!ulong == ulong.max);

    assert(IonValue([0x21, 0x80]).describe.get!IonUInt.getErrorCode!byte == IonErrorCode.overflowInIntegerValue);
    assert(IonValue([0x22, 0x80, 0]).describe.get!IonUInt.getErrorCode!short == IonErrorCode.overflowInIntegerValue);
    assert(IonValue([0x24, 0x80, 0,0,0]).describe.get!IonUInt.getErrorCode!int == IonErrorCode.overflowInIntegerValue);

    assert(IonValue([0x22, 1, 0]).describe.get!IonUInt.getErrorCode!ubyte == IonErrorCode.overflowInIntegerValue);
    assert(IonValue([0x23, 1, 0,0]).describe.get!IonUInt.getErrorCode!ushort == IonErrorCode.overflowInIntegerValue);
    assert(IonValue([0x25, 1, 0,0,0,0]).describe.get!IonUInt.getErrorCode!uint == IonErrorCode.overflowInIntegerValue);
    assert(IonValue([0x29, 1, 0,0,0,0,0,0,0,0]).describe.get!IonUInt.getErrorCode!ulong == IonErrorCode.overflowInIntegerValue);
}

/++
Ion negative integer number.
+/
struct IonNInt
{
    ///
    BigUIntView!(const ubyte, WordEndian.big) field;

    /++
    Returns: true if the integer isn't `null.int` and equals to `rhs`.
    +/
    bool opEquals(long rhs)
        @safe pure nothrow @nogc const
    {
        if (rhs >= 0)
            return false;
        return IonUInt(field) == -rhs;
    }

    /++
    Params:
        value = (out) signed or unsigned integer
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T)(scope ref T value)
        @trusted pure nothrow @nogc const
        if (isIntegral!T)
    {
        static if (isUnsigned!T)
        {
            return IonErrorCode.overflowInIntegerValue;
        }
        else
        {
            if (auto overflow = field.get(*cast(Unsigned!T*)&value))
                return IonErrorCode.overflowInIntegerValue;
            value = cast(T)(0-value);
            if (_expect(value >= 0, false))
                return IonErrorCode.overflowInIntegerValue;
            return IonErrorCode.none;
        }
    }

    version (D_Exceptions)
    {
        /++
        Returns: unsigned or signed integer
        +/
        T get(T)()
            @safe pure @nogc const
            if (isIntegral!T)
        {
            T ret;
            if (auto error = get(ret))
                throw error.ionException;
            return ret;
        }
    }

    /++
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode getErrorCode(T)()
        @trusted pure nothrow @nogc const
        if (isIntegral!T)
    {
        T value;
        return get!T(value);
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    assert(IonValue([0x3F]).describe.get!IonNull == IonNull(IonTypeCode.nInt));
    assert(IonValue([0x31, 0x07]).describe.get!IonNInt.get!int == -7);

    long v;
    assert(IonValue([0x32, 0x01, 0x04]).describe.get!IonNInt.get(v) == IonErrorCode.none);
    assert(v == -260);

    // IonNInt can't store zero according to the Ion Binary format specification.
    assert(IonValue([0x30]).describe.get!IonNInt.getErrorCode!byte == IonErrorCode.overflowInIntegerValue);
}

@safe pure
version(mir_ion_test) unittest
{
    alias AliasSeq(T...) = T;
    foreach (T; AliasSeq!(byte, short, int, long, ubyte, ushort, uint, ulong))
    {
        assert(IonValue([0x30]).describe.get!IonNInt.getErrorCode!T == IonErrorCode.overflowInIntegerValue);
        assert(IonValue([0x31, 0x00]).describe.get!IonNInt.getErrorCode!T == IonErrorCode.overflowInIntegerValue);

        static if (!__traits(isUnsigned, T))
        {   // signed
            assert(IonValue([0x31, 0x07]).describe.get!IonNInt.get!T == -7);
            assert(IonValue([0x3E, 0x81, 0x07]).describe.get!IonNInt.get!T == -7);
            assert(IonValue([0x3A, 0,0,0, 0,0,0, 0,0,0, 0x07]).describe.get!IonNInt.get!T == -7);
        }
        else
        {   // unsigned integers can't represent negative numbers
            assert(IonValue([0x31, 0x07]).describe.get!IonNInt.getErrorCode!T == IonErrorCode.overflowInIntegerValue);
            assert(IonValue([0x3E, 0x81, 0x07]).describe.get!IonNInt.getErrorCode!T == IonErrorCode.overflowInIntegerValue);
            assert(IonValue([0x3A, 0,0,0, 0,0,0, 0,0,0, 0x07]).describe.get!IonNInt.getErrorCode!T == IonErrorCode.overflowInIntegerValue);
        }
    }

    assert(IonValue([0x31, 0x80]).describe.get!IonNInt.get!byte == byte.min);
    assert(IonValue([0x32, 0x80, 0]).describe.get!IonNInt.get!short == short.min);
    assert(IonValue([0x34, 0x80, 0,0,0]).describe.get!IonNInt.get!int == int.min);
    assert(IonValue([0x38, 0x80, 0,0,0, 0,0,0,0]).describe.get!IonNInt.get!long == long.min);

    assert(IonValue([0x31, 0x81]).describe.get!IonNInt.getErrorCode!byte == IonErrorCode.overflowInIntegerValue);
    assert(IonValue([0x32, 0x80, 1]).describe.get!IonNInt.getErrorCode!short == IonErrorCode.overflowInIntegerValue);
    assert(IonValue([0x34, 0x80, 0,0,1]).describe.get!IonNInt.getErrorCode!int == IonErrorCode.overflowInIntegerValue);
    assert(IonValue([0x38, 0x80, 0,0,0, 0,0,0,1]).describe.get!IonNInt.getErrorCode!long == IonErrorCode.overflowInIntegerValue);
}

/++
Ion signed integer number.
+/
struct IonInt
{
    ///
    BigIntView!(const ubyte, WordEndian.big) field;


    /++
    Params:
        value = (out) signed or unsigned integer
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T)(scope ref T value)
        @trusted pure nothrow @nogc const
        if (isIntegral!T)
    {
        static if (isUnsigned!T)
        {
            if (_expect(field.sign, false))
                return IonErrorCode.overflowInIntegerValue;
        }

        if (auto overflow = field.unsigned.get(*cast(Unsigned!T*)&value))
            return IonErrorCode.overflowInIntegerValue;

        static if (isSigned!T)
        {
            auto nvalue = cast(T)(0-value);
            if (_expect((nvalue > 0) | (nvalue == 0) & field.sign , false))
                return IonErrorCode.overflowInIntegerValue;
            if (field.sign)
                value = nvalue;
        }

        return IonErrorCode.none;
    }

    version (D_Exceptions)
    {
        /++
        Returns: unsigned or signed integer
        +/
        T get(T)()
            @safe pure @nogc const
            if (isIntegral!T)
        {
            T ret;
            if (auto error = get(ret))
                throw error.ionException;
            return ret;
        }
    }

    /++
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode getErrorCode(T)()
        @trusted pure nothrow @nogc const
        if (isIntegral!T)
    {
        T value;
        return get!T(value);
    }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        pragma(msg, S);
        serializer.putValue(field);
    }
}

/// test with $(LREF IonUInt)s
@safe pure
version(mir_ion_test) unittest
{
    import mir.ion.exception;

    assert(IonValue([0x2F]).describe.get!IonNull == IonNull(IonTypeCode.uInt));
    assert(IonValue([0x21, 0x07]).describe.get!IonInt.get!int == 7);
    assert(IonValue([0x20]).describe.get!IonInt.get!int == 0);

    int v;
    assert(IonValue([0x22, 0x01, 0x04]).describe.get!IonInt.get(v) == IonErrorCode.none);
    assert(v == 260);
}

/// test with $(LREF IonNInt)s
@safe pure
version(mir_ion_test) unittest
{
    import mir.ion.exception;

    assert(IonValue([0x3F]).describe.get!IonNull == IonNull(IonTypeCode.nInt));
    assert(IonValue([0x31, 0x07]).describe.get!IonInt.get!int == -7);

    long v;
    assert(IonValue([0x32, 0x01, 0x04]).describe.get!IonInt.get(v) == IonErrorCode.none);
    assert(v == -260);

    // IonNInt can't store zero according to the Ion Binary format specification.
    assert(IonValue([0x30]).describe.get!IonInt.getErrorCode!byte == IonErrorCode.overflowInIntegerValue);
}

/++
Ion floating point number.
+/
struct IonFloat
{
    ///
    const(ubyte)[] data;

    /++
    Params:
        value = (out) `float`, `double`, or `real`
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T)(scope ref T value)
        @safe pure nothrow @nogc const
        if (isFloatingPoint!T)
    {
        if (data.length == 8)
        {
            value = parseFloating!double(data);
            return IonErrorCode.none;
        }
        if (data.length == 4)
        {
            value = parseFloating!float(data);
            return IonErrorCode.none;
        }
        if (_expect(data.length, false))
        {
            return IonErrorCode.wrongFloatDescriptor;
        }
        value = 0;
        return IonErrorCode.none;
    }

    version(D_Exceptions)
    {
        /++
        Returns: floating point number
        +/
        T get(T)()
            @safe pure @nogc const
            if (isFloatingPoint!T)
        {
            T ret;
            if (auto error = get(ret))
                throw error.ionException;
            return ret;
        }
    }

    /++
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode getErrorCode(T)()
        @trusted pure nothrow @nogc const
        if (isFloatingPoint!T)
    {
        T value;
        return get!T(value);
    }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        if (data.length == 8)
        {
            auto value = parseFloating!double(data);
            serializer.putValue(value);
            return;
        }
        if (data.length == 4)
        {
            auto value = parseFloating!float(data);
            serializer.putValue(value);
            return;
        }
        if (_expect(data.length, false))
        {
            throw IonErrorCode.wrongFloatDescriptor.ionException;
        }
        serializer.putValue(0f);
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    // null
    assert(IonValue([0x4F]).describe.get!IonNull == IonNull(IonTypeCode.float_));

    // zero
    auto ionFloat = IonValue([0x40]).describe.get!IonFloat;
    assert(ionFloat.get!float == 0);
    assert(ionFloat.get!double == 0);
    assert(ionFloat.get!real == 0);

    // single
    ionFloat = IonValue([0x44, 0x42, 0xAA, 0x40, 0x00]).describe.get!IonFloat;
    assert(ionFloat.get!float == 85.125);
    assert(ionFloat.get!double == 85.125);
    assert(ionFloat.get!real == 85.125);

    // double
    ionFloat = IonValue([0x48, 0x40, 0x55, 0x48, 0x00, 0x00, 0x00, 0x00, 0x00]).describe.get!IonFloat;
    assert(ionFloat.get!float == 85.125);
    assert(ionFloat.get!double == 85.125);
    assert(ionFloat.get!real == 85.125);
}

/++
+/
struct IonDescribedDecimal
{
    ///
    int exponent;
    ///
    IonIntField coefficient;

    ///
    IonErrorCode getDecimal(size_t maxW64bitSize)(scope ref Decimal!maxW64bitSize value)
        @safe pure nothrow @nogc const
    {
        const length = coefficient.data.length;
        enum maxLength = maxW64bitSize * 8;
        if (_expect(length > maxLength, false))
            return IonErrorCode.overflowInDecimalValue;
        value.exponent = exponent;
        value.coefficient.length = cast(uint) (length / size_t.sizeof + (length % size_t.sizeof != 0));
        value.coefficient.sign = false;
        if (value.coefficient.length == 0)
            return IonErrorCode.none;
        value.coefficient.view.unsigned.mostSignificant = 0;
        auto lhs = value.coefficient.view.unsigned.opCast!(BigUIntView!ubyte).leastSignificantFirst[0 .. length];
        import mir.ndslice.topology: retro;
        lhs[] = coefficient.data.retro;
        if (bool sign = coefficient.data[0] >> 7)
        {
            value.coefficient.sign = true;
            lhs[$ - 1] &= 0x7F;
        }
        return IonErrorCode.none;
    }

    /++
    Params:
        value = (out) floating point number
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T)(scope ref T value)
        @safe pure nothrow @nogc const
        if (isFloatingPoint!T && isMutable!T)
    {
        Decimal!256  decimal;
        if (auto ret = this.getDecimal!256(decimal))
            return ret;
        value = cast(T) decimal;
        return IonErrorCode.none;
    }

    version(D_Exceptions)
    {
        /++
        Returns: floating point number
        +/
        T get(T = double)()
            @safe pure @nogc const
            if (isFloatingPoint!T)
        {
            T ret;
            if (auto error = get(ret))
                throw error.ionException;
            return ret;
        }
    }

    /++
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode getErrorCode()()
        @trusted pure nothrow @nogc const
        if (isFloatingPoint!T)
    {
        Decimal!256 decimal;
        return get!T(decimal);
    }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        Decimal!256  decimal;
        if (auto error = this.getDecimal!256(decimal))
            throw error.ionException;
        serializer.putValue(decimal);
    }
}

/++
Ion described decimal number.
+/
struct IonDecimal
{
    ///
    const(ubyte)[] data;

    /++
    Describes decimal (nothrow version).
    Params:
        value = (out) $(LREF IonDescribedDecimal)
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T : IonDescribedDecimal)(scope ref T value)
        @safe pure nothrow @nogc const
    {
        const(ubyte)[] d = data;
        if (data.length)
        {
            if (auto error = parseVarInt(d, value.exponent))
                return error;
            value.coefficient = IonIntField(d);
        }
        else
        {
            value = T.init;
        }
        return IonErrorCode.none;
    }

    /++
    Params:
        value = (out) floating point number
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T)(scope ref T value)
        @safe pure nothrow @nogc const
        if (isFloatingPoint!T)
    {
        IonDescribedDecimal decimal;
        if (auto error = get(decimal))
            return error;
        return decimal.get(value);
    }

    version (D_Exceptions)
    {
        /++
        Describes decimal.
        Returns: $(LREF IonDescribedDecimal)
        +/
        T get(T = IonDescribedDecimal)()
            @safe pure @nogc const
        {
            T ret;
            if (auto error = get(ret))
                throw error.ionException;
            return ret;
        }
    }

    /++
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode getErrorCode(T = IonDescribedDecimal)()
        @trusted pure nothrow @nogc const
    {
        T value;
        return get!T(value);
    }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        this.get!IonDescribedDecimal.serialize(serializer);
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    // null.decimal
    assert(IonValue([0x5F]).describe.get!IonNull == IonNull(IonTypeCode.decimal));

    auto describedDecimal = IonValue([0x56, 0x50, 0xcb, 0x80, 0xbc, 0x2d, 0x86]).describe.get!IonDecimal.get;
    assert(describedDecimal.exponent == -2123);
    assert(describedDecimal.coefficient.get!int == -12332422);

    describedDecimal = IonValue([0x56, 0x00, 0xcb, 0x80, 0xbc, 0x2d, 0x86]).describe.get!IonDecimal.get;
    assert(describedDecimal.get!double == -12332422e75);

    assert(IonValue([0x50]).describe.get!IonDecimal.get!double == 0);
    assert(IonValue([0x51, 0x83]).describe.get!IonDecimal.get!double == 0);
    assert(IonValue([0x53, 0xc3, 0xb0, 0x39]).describe.get!IonDecimal.get!double == -12.345);
}

/++
Ion Timestamp

Timestamp representations have 7 components, where 5 of these components are optional depending on the precision of the timestamp.
The 2 non-optional components are offset and year.
The 5 optional components are (from least precise to most precise): `month`, `day`, `hour` and `minute`, `second`, `fraction_exponent` and `fraction_coefficient`.
All of these 7 components are in Universal Coordinated Time (UTC).
+/
struct IonTimestamp
{
    import mir.timestamp;

    ///
    const(ubyte)[] data;

    /++
    Describes decimal (nothrow version).
    Params:
        value = (out) $(LREF Timestamp)
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T : Timestamp)(scope ref T value)
        @safe pure nothrow @nogc const
    {
        pragma(inline, false);
        auto d = data[];
        Timestamp v;
        if (auto error = parseVarInt(d, v.offset))
            return error;
        ushort year;
        if (auto error = parseVarUInt(d, year))
            return error;
        v.year = year;

        if (d.length == 0)
            goto R;
        if (auto error = parseVarUInt(d, v.month))
            return error;
        if (v.month == 0 || v.month > 12)
            return IonErrorCode.illegalTimeStamp;
        v.precision = v.precision.month;

        import mir.date: maxDay;
        if (d.length == 0)
            goto R;
        if (auto error = parseVarUInt(d, v.day))
            return error;
        if (v.day == 0 || v.day > maxDay(v.year, v.month))
            return IonErrorCode.illegalTimeStamp;
        v.precision = v.precision.day;

        if (d.length == 0)
            goto R;
        if (auto error = parseVarUInt(d, v.hour))
            return error;
        if (v.hour >= 24)
            return IonErrorCode.illegalTimeStamp;
        {            
            typeof(v.minute) minute;
            if (auto error = parseVarUInt(d, minute))
                return error;
            if (v.minute >= 60)
                return IonErrorCode.illegalTimeStamp;
            v.minute = minute;
        }
        v.precision = v.precision.minute;

        if (d.length == 0)
            goto R;
        {
            typeof(v.second) second;
            if (auto error = parseVarUInt(d, second))
                return error;
            if (v.second >= 60)
                return IonErrorCode.illegalTimeStamp;
            v.second = second;
        }
        v.precision = v.precision.second;

        if (d.length == 0)
            goto R;
        {
            typeof(v.fractionExponent) fractionExponent;
            long fractionCoefficient;
            if (auto error = parseVarInt(d, fractionExponent))
                return error;
            if (auto error = IonIntField(d).get(fractionCoefficient))
                return error;
            if (fractionCoefficient == 0 && fractionExponent >= 0)
                goto R;
            static immutable exps = [
                1L,
                10L,
                100L,
                1_000L,
                10_000L,
                100_000L,
                1_000_000L,
                10_000_000L,
                100_000_000L,
                1_000_000_000L,
                10_000_000_000L,
                100_000_000_000L,
                1_000_000_000_000L,
            ];
            if (fractionExponent < -12
             || fractionExponent > 0
             || fractionCoefficient < 0
             || fractionCoefficient > exps[0-fractionExponent])
                return IonErrorCode.illegalTimeStamp;
            v.fractionExponent = fractionExponent;
            v.fractionCoefficient = fractionCoefficient;
        }
        v.precision = v.precision.fraction;
    R:
        value = v;
        return IonErrorCode.none;
    }

    version (D_Exceptions)
    {
        /++
        Describes decimal.
        Returns: $(LREF Timestamp)
        +/
        Timestamp get(T = Timestamp)()
            @safe pure @nogc const
        {
            T ret;
            if (auto error = get(ret))
                throw error.ionException;
            return ret;
        }
    }

    /++
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode getErrorCode(T = Timestamp)()
        @trusted pure nothrow @nogc const
    {
        T value;
        return get!T(value);
    }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        serializer.putValue(this.get!Timestamp);
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    import mir.timestamp;

    // null.timestamp
    assert(IonValue([0x6F]).describe.get!IonNull == IonNull(IonTypeCode.timestamp));

    ubyte[][] set = [
        [0x68, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84,         ], // 2000-07-08T02:03:04Z with no fractional seconds
        [0x69, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0x80,   ], // The same instant with 0d0 fractional seconds and implicit zero coefficient
        [0x6A, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0x80, 00], // The same instant with 0d0 fractional seconds and explicit zero coefficient
        [0x69, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0xC0,   ], // The same instant with 0d-0 fractional seconds
        [0x69, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0x81,   ], // The same instant with 0d1 fractional seconds
    ];

    auto r = Timestamp(2000, 7, 8, 2, 3, 4);

    foreach(data; set)
    {
        assert(IonValue(data).describe.get!IonTimestamp.get == r);
    }

    assert(IonValue([0x69, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0xC2])
        .describe
        .get!IonTimestamp
        .get ==
            Timestamp(2000, 7, 8, 2, 3, 4, -2, 0));

    assert(IonValue([0x6A, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0xC3, 0x10])
        .describe
        .get!IonTimestamp
        .get ==
            Timestamp(2000, 7, 8, 2, 3, 4, -3, 16));
}

/++
Ion Symbol Id

In the binary encoding, all Ion symbols are stored as integer symbol IDs whose text values are provided by a symbol table.
If L is zero then the symbol ID is zero and the length and symbol ID fields are omitted.
+/
struct IonSymbolID
{
    ///
    BigUIntView!(const ubyte, WordEndian.big) representation;

    /++
    Params:
        value = (out) symbol id
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T)(scope ref T value)
        @safe pure nothrow @nogc const
        if (isUnsigned!T)
    {
        return representation.get(value) ? IonErrorCode.overflowInIntegerValue : IonErrorCode.none;
    }

    /++
    Returns: unsigned or signed integer
    +/
    T get(T = size_t)()
        @safe pure @nogc const
        if (isUnsigned!T)
    {
        T ret;
        if (auto error = get(ret))
            throw error.ionException;
        return ret;
    }

    /++
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode getErrorCode(T = size_t)()
        @trusted pure nothrow @nogc const
        if (isUnsigned!T)
    {
        T value;
        return get!T(value);
    }

    /++
    Serializes SymbolId as Ion value.
    Note: This serialization shouldn't be used for `struct` keys or `annotation` list.
    Params:
        serializer = serializer with `ionPutValueId` primitive.
    +/
    void serialize(S)(ref S serializer) const
    {
        uint id;
        if (auto overflow = representation.get(id))
            throw IonErrorCode.overflowInSymbolId.ionException;
        serializer.ionPutValueId(cast(uint) representation);
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    assert(IonValue([0x7F]).describe.get!IonNull == IonNull(IonTypeCode.symbol));
    assert(IonValue([0x71, 0x07]).describe.get!IonSymbolID.get == 7);

    size_t v;
    assert(IonValue([0x72, 0x01, 0x04]).describe.get!IonSymbolID.get(v) == IonErrorCode.none);
    assert(v == 260);
}

@safe pure
version(mir_ion_test) unittest
{
    assert(IonValue([0x70]).describe.get!IonSymbolID.getErrorCode == 0);
    assert(IonValue([0x71, 0x00]).describe.get!IonSymbolID.getErrorCode == 0);

    assert(IonValue([0x71, 0x07]).describe.get!IonSymbolID.get == 7);
    assert(IonValue([0x7E, 0x81, 0x07]).describe.get!IonSymbolID.get == 7);
    assert(IonValue([0x7A, 0,0,0, 0,0,0, 0,0,0, 0x07]).describe.get!IonSymbolID.get == 7);

    assert(IonValue([0x71, 0xFF]).describe.get!IonSymbolID.get!ubyte == ubyte.max);
    assert(IonValue([0x72, 0xFF, 0xFF]).describe.get!IonSymbolID.get!ushort == ushort.max);
    assert(IonValue([0x74, 0xFF, 0xFF,0xFF,0xFF]).describe.get!IonSymbolID.get!uint == uint.max);
    assert(IonValue([0x78, 0xFF, 0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF]).describe.get!IonSymbolID.get!ulong == ulong.max);
    assert(IonValue([0x7A, 0,0, 0xFF, 0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF]).describe.get!IonSymbolID.get!ulong == ulong.max);

    assert(IonValue([0x72, 1, 0]).describe.get!IonSymbolID.getErrorCode!ubyte == IonErrorCode.overflowInIntegerValue);
    assert(IonValue([0x73, 1, 0,0]).describe.get!IonSymbolID.getErrorCode!ushort == IonErrorCode.overflowInIntegerValue);
    assert(IonValue([0x75, 1, 0,0,0,0]).describe.get!IonSymbolID.getErrorCode!uint == IonErrorCode.overflowInIntegerValue);
    assert(IonValue([0x79, 1, 0,0,0,0,0,0,0,0]).describe.get!IonSymbolID.getErrorCode!ulong == IonErrorCode.overflowInIntegerValue);
}


///
@safe pure
version(mir_ion_test) unittest
{
    // null.string
    assert(IonValue([0x8F]).describe.get!IonNull == IonNull(IonTypeCode.string));
    // empty string
    assert(IonValue([0x80]).describe.get!(const(char)[]) !is null);
    assert(IonValue([0x80]).describe.get!(const(char)[]) == "");

    assert(IonValue([0x85, 0x63, 0x6f, 0x76, 0x69, 0x64]).describe.get!(const(char)[]) == "covid");
}

/++
Ion List (array)
+/
struct IonList
{
    ///
    const(ubyte)[] data;
    private alias DG = int delegate(IonErrorCode error, IonDescribedValue value) @safe pure nothrow @nogc;
    private alias EDG = int delegate(IonDescribedValue value) @safe pure @nogc;

    /++
    Returns: true if the sexp is `null.sexp`, `null`, or `()`.
    Note: a NOP padding makes in the struct makes it non-empty.
    +/
    bool empty()
        @safe pure nothrow @nogc const @property
    {
        return data.length == 0;
    }

const:

    version (D_Exceptions)
    {
        /++
        +/
        @safe pure @nogc
        int opApply(scope int delegate(IonDescribedValue value) @safe pure @nogc dg)
        {
            return opApply((IonErrorCode error, IonDescribedValue value) {
                if (_expect(error, false))
                    throw error.ionException;
                return dg(value);
            });
        }

        /// ditto
        @trusted @nogc
        int opApply(scope int delegate(IonDescribedValue value)
        @safe @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @trusted pure
        int opApply(scope int delegate(IonDescribedValue value)
        @safe pure dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @trusted
        int opApply(scope int delegate(IonDescribedValue value)
        @safe dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system pure @nogc
        int opApply(scope int delegate(IonDescribedValue value)
        @system pure @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system @nogc
        int opApply(scope int delegate(IonDescribedValue value)
        @system @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system pure
        int opApply(scope int delegate(IonDescribedValue value)
        @system pure dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system
        int opApply(scope int delegate(IonDescribedValue value)
        @system dg) { return opApply(cast(EDG) dg); }
    }

    /++
    +/
    @safe pure nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value) @safe pure nothrow @nogc dg)
    {
        auto d = data[];
        while (d.length)
        {
            IonDescribedValue describedValue;
            auto error = parseValue(d, describedValue);
            if (error == IonErrorCode.nop)
                continue;
            if (auto ret = dg(error, describedValue))
                return ret;
            assert(!error, "User provided delegate MUST break the iteration when error has non-zero value.");
        }
        return 0;
    }

    /// ditto
    @trusted nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe pure @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure nothrow
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe pure nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe pure dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted nothrow
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system pure nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system pure @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure nothrow
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system pure nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system pure dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system nothrow
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system dg) { return opApply(cast(DG) dg); }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        serializer.listBegin;
        foreach (IonDescribedValue value; this)
        {
            serializer.elemBegin;
            value.serialize(serializer);
        }
        serializer.listEnd;
    }
}

///
version(mir_ion_test) unittest
{
    // check parsing with NOP padding:
    // [NOP, int, NOP, double, NOP]
    auto list = IonValue([0xbe, 0x91, 0x00, 0x00, 0x21, 0x0c, 0x00, 0x00, 0x48, 0x43, 0x0c, 0x6b, 0xf5, 0x26, 0x34, 0x00, 0x00, 0x00, 0x00])
        .describe.get!IonList;
    size_t i;
    foreach (elem; list)
    {
        if (i == 0)
            assert(elem.get!IonUInt.get!int == 12);
        if (i == 1)
            assert(elem.get!IonFloat.get!double == 100e13);
        i++;
    }
    assert(i == 2);
}

/++
Ion Sexp (symbol expression, array)
+/
struct IonSexp
{
    /// data view.
    const(ubyte)[] data;

    private alias DG = IonList.DG;
    private alias EDG = IonList.EDG;

    /++
    Returns: true if the sexp is `null.sexp`, `null`, or `()`.
    Note: a NOP padding makes in the struct makes it non-empty.
    +/
    bool empty()
        @safe pure nothrow @nogc const @property
    {
        return data.length == 0;
    }

const:

    version (D_Exceptions)
    {
        /++
        +/
        @safe pure @nogc
        int opApply(scope int delegate(IonDescribedValue value) @safe pure @nogc dg)
        {
            return IonList(data).opApply(dg);
        }

        /// ditto
        @trusted @nogc
        int opApply(scope int delegate(IonDescribedValue value)
        @safe @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @trusted pure
        int opApply(scope int delegate(IonDescribedValue value)
        @safe pure dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @trusted
        int opApply(scope int delegate(IonDescribedValue value)
        @safe dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system pure @nogc
        int opApply(scope int delegate(IonDescribedValue value)
        @system pure @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system @nogc
        int opApply(scope int delegate(IonDescribedValue value)
        @system @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system pure
        int opApply(scope int delegate(IonDescribedValue value)
        @system pure dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system
        int opApply(scope int delegate(IonDescribedValue value)
        @system dg) { return opApply(cast(EDG) dg); }
    }

    /++
    +/
    @safe pure nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value) @safe pure nothrow @nogc dg)
    {
        return IonList(data).opApply(dg);
    }

    /// ditto
    @trusted nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe pure @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure nothrow
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe pure nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe pure dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted nothrow
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @safe dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system pure nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system pure @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure nothrow
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system pure nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system @nogc
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system pure dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system nothrow
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system
    int opApply(scope int delegate(IonErrorCode error, IonDescribedValue value)
    @system dg) { return opApply(cast(DG) dg); }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        serializer.sexpBegin;
        foreach (IonDescribedValue value; this)
        {
            serializer.elemBegin;
            value.serialize(serializer);
        }
        serializer.sexpEnd;
    }
}

///
version(mir_ion_test) unittest
{
    // check parsing with NOP padding:
    // (NOP int NOP double NOP)
    auto list = IonValue([0xce, 0x91, 0x00, 0x00, 0x21, 0x0c, 0x00, 0x00, 0x48, 0x43, 0x0c, 0x6b, 0xf5, 0x26, 0x34, 0x00, 0x00, 0x00, 0x00])
        .describe.get!IonSexp;
    size_t i;
    foreach (elem; list)
    {
        if (i == 0)
            assert(elem.get!IonUInt.get!int == 12);
        if (i == 1)
            assert(elem.get!IonFloat.get!double == 100e13);
        i++;
    }
    assert(i == 2);
}

/++
Ion struct (object)
+/
struct IonStruct
{
    ///
    IonDescriptor descriptor;
    ///
    const(ubyte)[] data;

    private alias DG = int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value) @safe pure nothrow @nogc;
    private alias EDG = int delegate(size_t symbolID, IonDescribedValue value) @safe pure nothrow @nogc;

    ///
    bool sorted()
        @safe pure nothrow @nogc const @property
    {
        return descriptor.L == 1;
    }

    /++
    Returns: true if the struct is `null.struct`, `null`, or `()`.
    Note: a NOP padding makes in the struct makes it non-empty.
    +/
    bool empty()
        @safe pure nothrow @nogc const @property
    {
        return data.length == 0;
    }

const:

    version (D_Exceptions)
    {
        /++
        +/
        @safe pure @nogc
        int opApply(scope int delegate(size_t symbolID, IonDescribedValue value) @safe pure @nogc dg)
        {
            return opApply((IonErrorCode error, size_t symbolID, IonDescribedValue value) {
                if (_expect(error, false))
                    throw error.ionException;
                return dg(symbolID, value);
            });
        }

        /// ditto
        @trusted @nogc
        int opApply(scope int delegate(size_t symbolID, IonDescribedValue value)
        @safe @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @trusted pure
        int opApply(scope int delegate(size_t symbolID, IonDescribedValue value)
        @safe pure dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @trusted
        int opApply(scope int delegate(size_t symbolID, IonDescribedValue value)
        @safe dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system pure @nogc
        int opApply(scope int delegate(size_t symbolID, IonDescribedValue value)
        @system pure @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system @nogc
        int opApply(scope int delegate(size_t symbolID, IonDescribedValue value)
        @system @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system pure
        int opApply(scope int delegate(size_t symbolID, IonDescribedValue value)
        @system pure dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system
        int opApply(scope int delegate(size_t symbolID, IonDescribedValue value)
        @system dg) { return opApply(cast(EDG) dg); }
    }

    /++
    +/
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value) @safe pure nothrow @nogc dg)
        @safe pure nothrow @nogc
    {
        size_t shift;
        auto d = data[];
        while (d.length)
        {
            size_t symbolID;
            IonDescribedValue describedValue;
            auto error = parseVarUInt(d, symbolID);
            if (!error)
            {
                error = parseValue(d, describedValue);
                if (error == IonErrorCode.nop)
                    continue;
            }
            if (auto ret = dg(error, symbolID, describedValue))
                return ret;
            assert(!error, "User provided delegate MUST break the iteration when error has non-zero value.");
        }
        return 0;
    }

    /// ditto
    @trusted nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @safe nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @safe pure @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure nothrow
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @safe pure nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @safe @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @safe pure dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted nothrow
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @safe nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @safe dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @system pure nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @system nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @system pure @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure nothrow
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @system pure nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @system @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @system pure dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system nothrow
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @system nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID, IonDescribedValue value)
    @system dg) { return opApply(cast(DG) dg); }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        serializer.structBegin;
        foreach (size_t symbolID, IonDescribedValue value; this)
        {
            serializer.putKeyId(symbolID);
            value.serialize(serializer);
        }
        serializer.structEnd;
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    // null.struct
    assert(IonValue([0xDF]).describe.get!IonNull == IonNull(IonTypeCode.struct_));

    // empty struct
    auto ionStruct = IonValue([0xD0]).describe.get!IonStruct;
    size_t i;
    foreach (symbolID, elem; ionStruct)
        i++;
    assert(i == 0);

    // added two 2-bytes NOP padings 0x8F 0x00
    ionStruct = IonValue([0xDE, 0x91, 0x8F, 0x00, 0x8A, 0x21, 0x0C, 0x8B, 0x48, 0x43, 0x0C, 0x6B, 0xF5, 0x26, 0x34, 0x00, 0x00, 0x8F, 0x00])
        .describe
        .get!IonStruct;

    foreach (symbolID, elem; ionStruct)
    {
        if (i == 0)
        {
            assert(symbolID == 10);
            assert(elem.get!IonUInt.get!int == 12);
        }
        if (i == 1)
        {
            assert(symbolID == 11);
            assert(elem.get!IonFloat.get!double == 100e13);
        }
        i++;
    }
    assert(i == 2);
}

/++
Ion Annotation Wrapper
+/
struct IonAnnotationWrapper
{
    ///
    const(ubyte)[] data;

    /++
    Unwraps Ion annotations (nothrow version).
    Params:
        annotations = (out) $(LREF IonAnnotations)
        value = (out, optional) $(LREF IonDescribedValue) or $(LREF IonValue)
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode unwrap(scope ref IonAnnotations annotations, scope ref IonDescribedValue value)
        @safe pure nothrow @nogc const
    {
        IonValue v;
        if (auto error = unwrap(annotations, v))
            return error;
        return v.describe(value);
    }

    /// ditto
    IonErrorCode unwrap(scope ref IonAnnotations annotations, scope ref IonValue value)
        @safe pure nothrow @nogc const
    {
        size_t shift;
        size_t length;
        const(ubyte)[] d = data;
        if (auto error = parseVarUInt(d, length))
            return error;
        if (_expect(length == 0, false))
            return IonErrorCode.zeroAnnotations;
        if (_expect(length >= d.length, false))
            return IonErrorCode.unexpectedEndOfData;
        annotations = IonAnnotations(d[0 .. length]);
        value = IonValue(d[length .. $]);
        return IonErrorCode.none;
    }

    version (D_Exceptions)
    {
        /++
        Unwraps Ion annotations.
        Params:
            annotations = (optional out) $(LREF IonAnnotations)
        Returns: $(LREF IonDescribedValue)
        +/
        IonDescribedValue unwrap(scope ref IonAnnotations annotations)
            @safe pure @nogc const
        {
            IonDescribedValue ret;
            if (auto error = unwrap(annotations, ret))
                throw error.ionException;
            return ret;
        }

        /// ditto
        IonDescribedValue unwrap()
            @safe pure @nogc const
        {
            IonAnnotations annotations;
            return unwrap(annotations);
        }
    }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        IonAnnotations annotations;
        auto value = unwrap(annotations);

        serializer.annotationWrapperBegin;

        annotations.serialize(serializer);
        value.serialize(serializer);

        serializer.annotationWrapperEnd;
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    // null.struct
    IonAnnotations annotations;
    assert(IonValue([0xE7, 0x82, 0x8A, 0x8B, 0x53, 0xC3, 0x04, 0x65])
        .describe
        .get!IonAnnotationWrapper
        .unwrap(annotations)
        .get!IonDecimal
        .get!double == 1.125);

    size_t i;
    foreach (symbolID; annotations)
    {
        if (i == 0)
        {
            assert(symbolID == 10);
        }
        if (i == 1)
        {
            assert(symbolID == 11);
        }
        i++;
    }
    assert(i == 2);
}

/++
List of annotations represented as symbol IDs.
+/
struct IonAnnotations
{
    ///
    const(ubyte)[] data;
    private alias DG = int delegate(IonErrorCode error, size_t symbolID) @safe pure nothrow @nogc;
    private alias EDG = int delegate(size_t symbolID) @safe pure @nogc;

    /++
    Returns: true if no annotations provided.
    +/
    bool empty()
        @safe pure nothrow @nogc const @property
    {
        return data.length == 0;
    }

const:

    version (D_Exceptions)
    {
        /++
        +/
        @safe pure @nogc
        int opApply(scope int delegate(size_t symbolID) @safe pure @nogc dg)
        {
            return opApply((IonErrorCode error, size_t symbolID) {
                if (_expect(error, false))
                    throw error.ionException;
                return dg(symbolID);
            });
        }

        /// ditto
        @trusted @nogc
        int opApply(scope int delegate(size_t symbolID)
        @safe @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @trusted pure
        int opApply(scope int delegate(size_t symbolID)
        @safe pure dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @trusted
        int opApply(scope int delegate(size_t symbolID)
        @safe dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system pure @nogc
        int opApply(scope int delegate(size_t symbolID)
        @system pure @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system @nogc
        int opApply(scope int delegate(size_t symbolID)
        @system @nogc dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system pure
        int opApply(scope int delegate(size_t symbolID)
        @system pure dg) { return opApply(cast(EDG) dg); }

        /// ditto
        @system
        int opApply(scope int delegate(size_t symbolID)
        @system dg) { return opApply(cast(EDG) dg); }
    }

    /++
    +/
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID) @safe pure nothrow @nogc dg)
        @safe pure nothrow @nogc
    {
        auto d = data[];
        while (d.length)
        {
            size_t symbolID;
            auto error = parseVarUInt(d, symbolID);
            if (auto ret = dg(error, symbolID))
                return ret;
            assert(!error, "User provided delegate MUST break the iteration when error has non-zero value.");
        }
        return 0;
    }

    /// ditto
    @trusted nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @safe nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @safe pure @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure nothrow
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @safe pure nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @safe @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted pure
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @safe pure dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted nothrow
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @safe nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @trusted
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @safe dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @system pure nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system nothrow @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @system nothrow @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @system pure @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure nothrow
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @system pure nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system @nogc
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @system @nogc dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system pure
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @system pure dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system nothrow
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @system nothrow dg) { return opApply(cast(DG) dg); }

    /// ditto
    @system
    int opApply(scope int delegate(IonErrorCode error, size_t symbolID)
    @system dg) { return opApply(cast(DG) dg); }

    /++
    Params:
        serializer = serializer
    +/
    void serialize(S)(ref S serializer) const
    {
        IonAnnotations annotations;
        auto value = unwrap(annotations);

        serializer.annotationsBegin;

        foreach (size_t id; this)
        {
            serializer.putAnnotationId(id);
        }

        serializer.annotationsEnd;
    }
}

package IonErrorCode parseVarUInt(bool checkInput = true, U)(scope ref const(ubyte)[] data, scope out U result)
    @safe pure nothrow @nogc
    if (is(U == ubyte) || is(U == ushort) || is(U == uint) || is(U == ulong))
{
    version(LDC) pragma(inline, true);
    enum mLength = U(1) << (U.sizeof * 8 / 7 * 7);
    for(;;)
    {
        static if (checkInput)
        {
            if (_expect(data.length == 0, false))
                return IonErrorCode.unexpectedEndOfData;
        }
        else
        {
            assert(data.length);
        }
        ubyte b = data[0];
        data = data[1 .. $];
        result <<= 7;
        result |= b & 0x7F;
        if (cast(byte)b < 0)
            return IonErrorCode.none;
        static if (checkInput)
        {
            if (_expect(result >= mLength, false))
                return IonErrorCode.overflowInParseVarUInt;
        }
        else
        {
            assert(result < mLength);
        }
    }
}

private IonErrorCode parseVarInt(S)(scope ref const(ubyte)[] data, scope out S result)
    @safe pure nothrow @nogc
    if (is(S == byte) || is(S == short) || is(S == int) || is(S == long))
{
    version(LDC) pragma(inline, true);
    enum mLength = S(1) << (S.sizeof * 8 / 7 * 7 - 1);
    S length;
    if (_expect(data.length == 0, false))
        return IonErrorCode.unexpectedEndOfData;
    ubyte b = data[0];
    data = data[1 .. $];
    bool neg;
    if (b & 0x40)
    {
        neg = true;
        b ^= 0x40;
    }
    length =  b & 0x7F;
    goto L;
    for(;;)
    {
        if (_expect(data.length == 0, false))
            return IonErrorCode.unexpectedEndOfData;
        b = data[0];
        data = data[1 .. $];
        length <<= 7;
        length |= b & 0x7F;
    L:
        if (cast(byte)b < 0)
        {
            result = neg ? cast(S)(0-length) : length;
            return IonErrorCode.none;
        }
        if (_expect(length >= mLength, false))
            return IonErrorCode.overflowInParseVarUInt;
    }
}

private IonErrorCode parseValue(ref const(ubyte)[] data, scope ref IonDescribedValue describedValue)
    @safe pure nothrow @nogc
{
    version(LDC) pragma(inline, true);

    if (_expect(data.length == 0, false))
        return IonErrorCode.unexpectedEndOfData;
    auto descriptorPtr = &data[0];
    data = data[1 .. $];
    ubyte descriptorData = *descriptorPtr;

    if (_expect(descriptorData > 0xEE, false))
        return IonErrorCode.illegalTypeDescriptor;

    describedValue = IonDescribedValue(IonDescriptor(descriptorPtr));

    const L = describedValue.descriptor.L;
    const type = describedValue.descriptor.type;
    // if null
    if (L == 0xF)
        return IonErrorCode.none;
    // if bool
    if (type == IonTypeCode.bool_)
    {
        if (_expect(L > 1, false))
            return IonErrorCode.illegalTypeDescriptor;
        return IonErrorCode.none;
    }
    size_t length = L;
    // if large
    bool sortedStruct = descriptorData == 0xD1;
    if (length == 0xE || sortedStruct)
    {
        if (auto error = parseVarUInt(data, length))
            return error;
    }
    if (_expect(length > data.length, false))
        return IonErrorCode.unexpectedEndOfData;
    describedValue.data = data[0 .. length];
    data = data[length .. $];
    // NOP Padding
    return type == IonTypeCode.null_ ? IonErrorCode.nop : IonErrorCode.none;
}

private F parseFloating(F)(scope const(ubyte)[] data)
    @trusted pure nothrow @nogc
    if (isFloatingPoint!F)
{
    version(LDC) pragma(inline, true);

    enum n = F.sizeof;
    static if (n == 4)
        alias U = uint;
    else
    static if (n == 8)
        alias U = ulong;
    else
    static if (n == 16)
        alias U = ucent;
    else static assert(0);

    assert(data.length == n);

    U num;
    if (__ctfe)
    {
        static foreach_reverse (i; 0 .. n)
        {
            num <<= 8;
            num |= data.ptr[i];
        }
    }
    else
    {
        num = (cast(U[1])cast(ubyte[n])data.ptr[0 .. n])[0];
    }
    version (LittleEndian)
    {
        import core.bitop : bswap;
        num = bswap(num);
    }
    return num.unsignedDataToFloating;
}

private auto unsignedDataToFloating(T)(const T data)
    @trusted pure nothrow @nogc
    if (__traits(isUnsigned, T) && T.sizeof >= 4)
{
    static if (T.sizeof == 4)
        alias F = float;
    else
    static if (T.sizeof == 8)
        alias F = double;
    else
        alias F = quadruple;

    version(all)
    {
        return *cast(F*)&data;
    }
    else
    {        
        T num = data;
        bool sign = cast(bool)(num >> (T.sizeof * 8 - 1));
        num &= num.max >> 1;
        if (num == 0)
            return F(sign ? -0.0f : 0.0f);
        int exp = cast(int) (num >> (F.mant_dig - 1));
        num &= (T(1) << (F.mant_dig - 1)) - 1;
        if (exp)
        {
            if (exp == (T(1) << (T.sizeof * 8 - F.mant_dig)) - 1)
            {
                F ret = num == 0 ? F.infinity : F.nan;
                if (sign)
                    ret = -ret;
                return ret;
            }
            exp -= 1;
            num |= T(1) << (F.mant_dig - 1);
        }

        exp -= F.mant_dig - F.min_exp;
        F ret = num;
        import mir.math.ieee: ldexp;
        // ret = ldexp(ret, exp);
        ret *= 2.0 ^^ exp;
        if (sign)
            ret = -ret;
        assert(data == cast(ulong)*cast(T*) &ret);
        return ret;
    }
}

///
@safe pure nothrow @nogc
unittest
{
    assert(unsignedDataToFloating(1UL) == double.min_normal * double.epsilon);
    assert(unsignedDataToFloating(1U) == float.min_normal * float.epsilon);

    assert(unsignedDataToFloating(0xFFF0000000000000U) == -double.infinity);
    assert(unsignedDataToFloating(0x4008000000000000U) == 3.0);
    assert(unsignedDataToFloating(0x4028000000000000U) == 12.0);
    assert(unsignedDataToFloating(0x430c6bf526340000U) == 1e15);
    assert(unsignedDataToFloating(1UL) == double.min_normal * double.epsilon);
    assert(unsignedDataToFloating(1U) == float.min_normal * float.epsilon);

    static assert(unsignedDataToFloating(0xFFF0000000000000U) == -double.infinity);
    static assert(unsignedDataToFloating(0x4008000000000000U) == 3.0, unsignedDataToFloating(0x4008000000000000U));
    static assert(unsignedDataToFloating(0x4028000000000000U) == 12.0, unsignedDataToFloating(0x4028000000000000U));
    static assert(unsignedDataToFloating(0x430c6bf526340000U) == 1e15, unsignedDataToFloating(0x430c6bf526340000U));
    static assert(unsignedDataToFloating(1UL) == double.min_normal * double.epsilon);
    static assert(unsignedDataToFloating(1U) == float.min_normal * float.epsilon);
}
