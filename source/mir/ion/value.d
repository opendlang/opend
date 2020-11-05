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
alias IonType(IonTypeCode code : IonTypeCode.null_) = typeof(null);
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.bool_) = IonBool;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.uInt) = IonUInt;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.nInt) = IonNInt;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.float_) = IonFloat;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.decimal) = IonDecimal;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.timestamp) = IonTimestampValue;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.symbol) = IonSymbolID;
/// ditto
alias IonType(IonTypeCode code : IonTypeCode.string) = IonString;
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
alias IonTypeCodeOf(T : typeof(null)) = IonTypeCode.null_;
/// ditto
alias IonTypeCodeOf(T : IonBool) = IonTypeCode.bool_;
/// ditto
alias IonTypeCodeOf(T : IonUInt) = IonTypeCode.uInt;
/// ditto
alias IonTypeCodeOf(T : IonNInt) = IonTypeCode.nInt;
/// ditto
alias IonTypeCodeOf(T : IonFloat) = IonTypeCode.float_;
/// ditto
alias IonTypeCodeOf(T : IonDecimal) = IonTypeCode.decimal;
/// ditto
alias IonTypeCodeOf(T : IonTimestampValue) = IonTypeCode.timestamp;
/// ditto
alias IonTypeCodeOf(T : IonSymbolID) = IonTypeCode.symbol;
/// ditto
alias IonTypeCodeOf(T : IonString) = IonTypeCode.string;
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
enum isIonType(T : typeof(null)) = true;
/// ditto
enum isIonType(T : IonBool) = true;
/// ditto
enum isIonType(T : IonUInt) = true;
/// ditto
enum isIonType(T : IonNInt) = true;
/// ditto
enum isIonType(T : IonFloat) = true;
/// ditto
enum isIonType(T : IonDecimal) = true;
/// ditto
enum isIonType(T : IonTimestampValue) = true;
/// ditto
enum isIonType(T : IonSymbolID) = true;
/// ditto
enum isIonType(T : IonString) = true;
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
    IonValue gcCopy()
    {
        return IonValue(data.dup);
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
    const(ubyte)* reference;

    /// T
    IonTypeCode type() @safe pure nothrow @nogc const @property
    {
        assert(reference);
        return cast(typeof(return))((*reference) >> 4);
    }
    /// L
    uint L() @safe pure nothrow @nogc const @property
    {
        assert(reference);
        return cast(typeof(return))((*reference) & 0xF);
    }
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
    Returns: true if the blob is `null.blob`.
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
        static if (is(T == IonInt))
        {
            if (_expect((descriptor.type | 1) != IonTypeCodeOf!IonNInt, false))
                return IonErrorCode.unexpectedIonType;
        }
        else
        {
            if (_expect(descriptor.type != IonTypeCodeOf!T, false))
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
        static if (is(T == IonInt))
        {
            if (_expect((descriptor.type | 1) != IonTypeCodeOf!IonNInt, false))
                throw IonErrorCode.unexpectedIonType.ionException;
        }
        else
        {
            if (_expect(descriptor.type != IonTypeCodeOf!T, false))
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
            assert(descriptor.type == IonTypeCodeOf!IonNInt || descriptor.type == IonTypeCodeOf!IonUInt);
        }
        else
        {
            assert(descriptor.type == IonTypeCodeOf!T);
        }
        static if (is(T == typeof(null)))
        {
            return T.init;
        }
        else
        static if (is(T == IonBool))
        {
            return T(descriptor);
        }
        else
        static if (is(T == IonStruct))
        {
            return T(descriptor, data);
        }
        else
        static if (is(T == IonString) || is(T == IonClob))
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

/++
Nullable boolean type. Encodes `false`, `true`, and `null.bool`.
+/
struct IonBool
{
    ///
    IonDescriptor descriptor;

    /++
    Returns: true if the boolean is `null.bool`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        assert (descriptor.type == IonTypeCode.bool_);
        return *descriptor.reference == 0x1F;
    }

    /++
    Params:
        rhs = right hand side value for `==` and `!=` expressions.
    Returns: true if the boolean isn't `null.bool` and equals to the `rhs`.
    +/
    bool opEquals(bool rhs)
        @safe pure nothrow @nogc const
    {
        assert (descriptor.type == IonTypeCode.bool_);
        return descriptor.L == rhs;
    }

    /++
    Returns: `bool`
    Precondition: `this != null`.
    +/
    bool get()
        @safe pure nothrow @nogc const
    {
        assert(descriptor.reference);
        auto d = *descriptor.reference;
        assert((d | 1) == 0x11);
        return d & 1;
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    assert(IonValue([0x1F]).describe.get!IonBool == null);
    assert(IonValue([0x10]).describe.get!IonBool.get == false);
    assert(IonValue([0x11]).describe.get!IonBool.get == true);
}

/++
Ion non-negative integer number.
+/
struct IonUInt
{
    ///
    BigUIntView!(const ubyte, WordEndian.big) field;

    /++
    Returns: true if the integer is `null.int`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return field.coefficients is null;
    }

    /++
    Returns: true if the integer isn't `null.int` and equals to `rhs`.
    +/
    bool opEquals(ulong rhs)
        @safe pure nothrow @nogc const
    {
        if (this == null)
            return false;
        return field == rhs;
    }

    /++
    Params:
        value = (out) unsigned or signed integer
    Returns: $(SUBREF exception, IonErrorCode)
    Precondition: `this != null`.
    +/
    IonErrorCode get(T)(scope ref T value)
        @trusted pure nothrow @nogc const
        if (isIntegral!T)
    {
        assert(this != null);
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
        Precondition: `this != null`.
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
    Precondition: `this != null`.
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
    assert(IonValue([0x2F]).describe.get!IonUInt == null);
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
    Returns: true if the integer is `null.int`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return field.coefficients is null;
    }

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
    Precondition: `this != null`.
    +/
    IonErrorCode get(T)(scope ref T value)
        @trusted pure nothrow @nogc const
        if (isIntegral!T)
    {
        assert(this != null);
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
        Precondition: `this != null`.
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
    Precondition: `this != null`.
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
    assert(IonValue([0x3F]).describe.get!IonNInt == null);
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
    Returns: true if the integer is `null.int`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return field.coefficients is null;
    }

    /++
    Params:
        value = (out) signed or unsigned integer
    Returns: $(SUBREF exception, IonErrorCode)
    Precondition: `this != null`.
    +/
    IonErrorCode get(T)(scope ref T value)
        @trusted pure nothrow @nogc const
        if (isIntegral!T)
    {
        assert(this != null);
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
        Precondition: `this != null`.
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
    Precondition: `this != null`.
    +/
    IonErrorCode getErrorCode(T)()
        @trusted pure nothrow @nogc const
        if (isIntegral!T)
    {
        T value;
        return get!T(value);
    }
}

/// test with $(LREF IonUInt)s
@safe pure
version(mir_ion_test) unittest
{
    import mir.ion.exception;

    assert(IonValue([0x2F]).describe.get!IonInt == null);
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

    assert(IonValue([0x3F]).describe.get!IonInt == null);
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
    Returns: true if the float is `null.float`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return data is null;
    }

    /++
    Params:
        value = (out) `float`, `double`, or `real`
    Returns: $(SUBREF exception, IonErrorCode)
    Precondition: `this != null`.
    +/
    IonErrorCode get(T)(scope ref T value)
        @safe pure nothrow @nogc const
        if (isFloatingPoint!T)
    {
        assert(this != null);
        if (data.length == 8)
        {
            value = parseDouble(data);
            return IonErrorCode.none;
        }
        if (data.length == 4)
        {
            value = parseSingle(data);
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
        Precondition: `this != null`.
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
    Precondition: `this != null`.
    +/
    IonErrorCode getErrorCode(T)()
        @trusted pure nothrow @nogc const
        if (isFloatingPoint!T)
    {
        T value;
        return get!T(value);
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    // null
    assert(IonValue([0x4F]).describe.get!IonFloat == null);

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
    Precondition: `this != null`.
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
        Precondition: `this != null`.
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
    Precondition: `this != null`.
    +/
    IonErrorCode getErrorCode()()
        @trusted pure nothrow @nogc const
        if (isFloatingPoint!T)
    {
        Decimal!256 decimal;
        return get!T(decimal);
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
    Returns: true if the decimal is `null.decimal`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return data is null;
    }

    /++
    Describes decimal (nothrow version).
    Params:
        value = (out) $(LREF IonDescribedDecimal)
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T : IonDescribedDecimal)(scope ref T value)
        @safe pure nothrow @nogc const
    {
        assert(this != null);
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
    Precondition: `this != null`.
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
    Precondition: `this != null`.
    +/
    IonErrorCode getErrorCode(T = IonDescribedDecimal)()
        @trusted pure nothrow @nogc const
    {
        T value;
        return get!T(value);
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    // null.decimal
    assert(IonValue([0x5F]).describe.get!IonDecimal == null);

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
struct IonTimestampValue
{
    import mir.ion.timestamp;

    ///
    const(ubyte)[] data;

    /++
    Returns: true if the timestamp is `null.timestamp`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return data is null;
    }

    /++
    Describes decimal (nothrow version).
    Params:
        value = (out) $(LREF IonTimestamp)
    Returns: $(SUBREF exception, IonErrorCode)
    +/
    IonErrorCode get(T : IonTimestamp)(scope ref T value)
        @safe pure nothrow @nogc const
    {
        pragma(inline, false);
        assert(this != null);
        auto d = data[];
        IonTimestamp v;
        if (auto error = parseVarInt(d, v.offset))
            return error;
        if (auto error = parseVarUInt(d, v.year))
            return error;

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
        Returns: $(LREF IonTimestamp)
        +/
        IonTimestamp get(T = IonTimestamp)()
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
    Precondition: `this != null`.
    +/
    IonErrorCode getErrorCode(T = IonTimestamp)()
        @trusted pure nothrow @nogc const
    {
        T value;
        return get!T(value);
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    import mir.ion.timestamp;

    // null.timestamp
    assert(IonValue([0x6F]).describe.get!IonTimestampValue == null);

    ubyte[][] set = [
        [0x68, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84,         ], // 2000-07-08T02:03:04Z with no fractional seconds
        [0x69, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0x80,   ], // The same instant with 0d0 fractional seconds and implicit zero coefficient
        [0x6A, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0x80, 00], // The same instant with 0d0 fractional seconds and explicit zero coefficient
        [0x69, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0xC0,   ], // The same instant with 0d-0 fractional seconds
        [0x69, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0x81,   ], // The same instant with 0d1 fractional seconds
    ];

    auto r = IonTimestamp(2000, 7, 8, 2, 3, 4);

    foreach(data; set)
    {
        assert(IonValue(data).describe.get!IonTimestampValue.get == r);
    }

    assert(IonValue([0x69, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0xC2])
        .describe
        .get!IonTimestampValue
        .get ==
            IonTimestamp(2000, 7, 8, 2, 3, 4, -2, 0));

    assert(IonValue([0x6A, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0xC3, 0x10])
        .describe
        .get!IonTimestampValue
        .get ==
            IonTimestamp(2000, 7, 8, 2, 3, 4, -3, 16));
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
    Returns: true if the symbol is `null.symbol`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return representation.coefficients is null;
    }

    /++
    Params:
        value = (out) symbol id
    Returns: $(SUBREF exception, IonErrorCode)
    Precondition: `this != null`.
    +/
    IonErrorCode get(T)(scope ref T value)
        @safe pure nothrow @nogc const
        if (isUnsigned!T)
    {
        assert(this != null);
        return representation.get(value) ? IonErrorCode.overflowInIntegerValue : IonErrorCode.none;
    }

    /++
    Returns: unsigned or signed integer
    Precondition: `this != null`.
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
    Precondition: `this != null`.
    +/
    IonErrorCode getErrorCode(T = size_t)()
        @trusted pure nothrow @nogc const
        if (isUnsigned!T)
    {
        T value;
        return get!T(value);
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    assert(IonValue([0x7F]).describe.get!IonSymbolID == null);
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

/++
Ion String.

These are always sequences of Unicode characters, encoded as a sequence of UTF-8 octets.
+/
struct IonString
{
    ///
    const(char)[] data;

    /++
    Returns: true if the string is `null.string`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return data is null;
    }
}

///
@safe pure
version(mir_ion_test) unittest
{
    // null.string
    assert(IonValue([0x8F]).describe.get!IonString == null);
    // empty string
    assert(IonValue([0x80]).describe.get!IonString != null);
    assert(IonValue([0x80]).describe.get!IonString.data == "");

    assert(IonValue([0x85, 0x63, 0x6f, 0x76, 0x69, 0x64]).describe.get!IonString.data == "covid");
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
    Returns: true if the sexp is `null.sexp`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return data is null;
    }

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
    Returns: true if the sexp is `null.sexp`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return data is null;
    }

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
    Returns: true if the struct is `null.struct`.
    +/
    bool opEquals(typeof(null))
        @safe pure nothrow @nogc const
    {
        return data is null;
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
}

///
@safe pure
version(mir_ion_test) unittest
{
    // null.struct
    assert(IonValue([0xDF]).describe.get!IonStruct == null);

    // empty struct
    auto ionStruct = IonValue([0xD0]).describe.get!IonStruct;
    size_t i;
    assert(ionStruct != null);
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

    const L = uint(descriptorData & 0xF);
    const type = cast(IonTypeCode)(descriptorData >> 4);
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

private double parseDouble(scope const(ubyte)[] data)
    @trusted pure nothrow @nogc
{
    version(LDC) pragma(inline, true);
    version (LittleEndian) import core.bitop : bswap;
    assert(data.length == 8);
    double value;
    *cast(ubyte[8]*) &value = cast(ubyte[8]) data[0 .. 8];
    version (LittleEndian) *cast(ulong*)&value = bswap(*cast(ulong*)&value);
    return value;
}

private float parseSingle(scope const(ubyte)[] data)
    @trusted pure nothrow @nogc
{
    version(LDC) pragma(inline, true);
    version (LittleEndian) import core.bitop : bswap;
    assert(data.length == 4);
    float value;
    *cast(ubyte[4]*) &value = cast(ubyte[4]) data[0 .. 4];
    version (LittleEndian) *cast(uint*)&value = bswap(*cast(uint*)&value);
    return value;
}
