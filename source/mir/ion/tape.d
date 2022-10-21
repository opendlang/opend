/++
+/
// TODO: tape building for Annotations
module mir.ion.tape;

import core.stdc.string: memmove, memcpy;
import mir.bignum.low_level_view;
import mir.bitop;
import mir.date;
import mir.lob;
import mir.timestamp: Timestamp;
import mir.ion.type_code;
import mir.utility: _expect;
import std.traits;

version(LDC) import ldc.attributes: optStrategy;
else private struct optStrategy { string opt; }

/++
+/
size_t ionPutVarUInt(T)(scope ubyte* ptr, const T num)
    if (isUnsigned!T)
{
    T value = num;
    enum s = T.sizeof * 8 / 7 + 1;
    uint len;
    do ptr[s - 1 - len++] = value & 0x7F;
    while (value >>>= 7);
    ptr[s - 1] |= 0x80;
    if (!__ctfe)
    {
        auto arr = *cast(ubyte[s-1]*)(ptr + s - len);
        *cast(ubyte[s-1]*)ptr = arr;
    }
    else
    {
        foreach(i; 0 .. len)
            ptr[i] = ptr[i + s - len];
    }
    return len;
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[19] data = void;

    alias AliasSeq(T...) = T;

    foreach(T; AliasSeq!(ubyte, ushort, uint, ulong))
    {
        data[] = 0;
        assert(ionPutVarUInt!T(data.ptr, 0) == 1);
        assert(data[0] == 0x80);

        data[] = 0;
        assert(ionPutVarUInt!T(data.ptr, 1) == 1);
        assert(data[0] == 0x81);

        data[] = 0;
        assert(ionPutVarUInt!T(data.ptr, 0x7F) == 1);
        assert(data[0] == 0xFF);

        data[] = 0;
        assert(ionPutVarUInt!T(data.ptr, 0xFF) == 2);
        assert(data[0] == 0x01);
        assert(data[1] == 0xFF);
    }

    foreach(T; AliasSeq!(ushort, uint, ulong))
    {

        data[] = 0;
        assert(ionPutVarUInt!T(data.ptr, 0x3FFF) == 2);
        assert(data[0] == 0x7F);
        assert(data[1] == 0xFF);

        data[] = 0;
        assert(ionPutVarUInt!T(data.ptr, 0x7FFF) == 3);
        assert(data[0] == 0x01);
        assert(data[1] == 0x7F);
        assert(data[2] == 0xFF);

        data[] = 0;
        assert(ionPutVarUInt!T(data.ptr, 0xFFEE) == 3);
        assert(data[0] == 0x03);
        assert(data[1] == 0x7F);
        assert(data[2] == 0xEE);
    }

    data[] = 0;
    assert(ionPutVarUInt(data.ptr, uint.max) == 5);
    assert(data[0] == 0x0F);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0xFF);

    data[] = 0;
    assert(ionPutVarUInt!ulong(data.ptr, ulong.max >> 1) == 9);
    assert(data[0] == 0x7F);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0xFF);

    data[] = 0;
    assert(ionPutVarUInt(data.ptr, ulong.max) == 10);
    assert(data[0] == 0x01);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0x7F);
    assert(data[9] == 0xFF);
}

/++
+/
size_t joyPutVarUInt(T)(scope ubyte* ptr, const T num)
    if (isUnsigned!T)
{
    T value = num;
    size_t length;
    do ptr[length++] = value & 0x7F;
    while (value >>>= 7);
    *ptr |= 0x80;
    return length;
}

///
@("joyPutVarUInt")
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[19] data = void;

    alias AliasSeq(T...) = T;

    foreach(T; AliasSeq!(ubyte, ushort, uint, ulong))
    {
        data[] = 0;
        assert(joyPutVarUInt!T(data.ptr, 0) == 1);
        assert(data[0] == 0x80);

        data[] = 0;
        assert(joyPutVarUInt!T(data.ptr, 1) == 1);
        assert(data[0] == 0x81);

        data[] = 0;
        assert(joyPutVarUInt!T(data.ptr, 0x7F) == 1);
        assert(data[0] == 0xFF);

        data[] = 0;
        assert(joyPutVarUInt!T(data.ptr, 0xFF) == 2);
        assert(data[0] == 0xFF);
        assert(data[1] == 0x01);
    }

    foreach(T; AliasSeq!(ushort, uint, ulong))
    {

        data[] = 0;
        assert(joyPutVarUInt!T(data.ptr, 0x3FFF) == 2);
        assert(data[0] == 0xFF);
        assert(data[1] == 0x7F);

        data[] = 0;
        assert(joyPutVarUInt!T(data.ptr, 0x7FFF) == 3);
        assert(data[0] == 0xFF);
        assert(data[1] == 0x7F);
        assert(data[2] == 0x01);

        data[] = 0;
        assert(joyPutVarUInt!T(data.ptr, 0xFFEE) == 3);
        assert(data[0] == 0xEE);
        assert(data[1] == 0x7F);
        assert(data[2] == 0x03);
    }

    data[] = 0;
    assert(joyPutVarUInt(data.ptr, uint.max) == 5);
    assert(data[0] == 0xFF);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x0F);

    data[] = 0;
    assert(joyPutVarUInt!ulong(data.ptr, ulong.max >> 1) == 9);
    assert(data[0] == 0xFF);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0x7F);

    data[] = 0;
    assert(joyPutVarUInt(data.ptr, ulong.max) == 10);
    assert(data[0] == 0xFF);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0x7F);
    assert(data[9] == 0x01);
}

/++
+/
size_t ionPutVarInt(T)(scope ubyte* ptr, const T num)
    if (isSigned!T)
{
    return .ionPutVarInt!(Unsigned!T)(ptr, num < 0 ? cast(Unsigned!T)(0-num) : num, num < 0);
}

/++
+/
size_t ionPutVarInt(T)(scope ubyte* ptr, const T num, bool sign)
    if (isUnsigned!T)
{
    T value = num; 
    if (_expect(value < 64, true))
    {
        *ptr = cast(ubyte)(value | 0x80 | (sign << 6));
        return 1;
    }
    enum s = T.sizeof * 8 / 7 + 1;
    size_t len;
    do ptr[s - 1 - len++] = value & 0x7F;
    while (value >>>= 7);
    auto sb = ptr[s - len] >>> 6;
    auto r = ptr[s - len] & ~(~sb + 1);
    len += sb;
    ptr[s - len] = cast(ubyte)r | (cast(ubyte)sign << 6);
    ptr[s - 1] |= 0x80;
    auto arr = *cast(ubyte[s-1]*)(ptr + s - len);
    *cast(ubyte[s-1]*)ptr = arr;
    return len;
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[19] data = void;

    alias AliasSeq(T...) = T;

    foreach(T; AliasSeq!(ubyte, ushort, uint, ulong))
    {
        data[] = 0;
        assert(ionPutVarInt!T(data.ptr, 0, false) == 1);
        assert(data[0] == 0x80);

        data[] = 0;
        assert(ionPutVarInt!T(data.ptr, 1, false) == 1);
        assert(data[0] == 0x81);

        data[] = 0;
        assert(ionPutVarInt!T(data.ptr, 1, true) == 1);
        assert(data[0] == 0xC1);

        data[] = 0;
        assert(ionPutVarInt!T(data.ptr, 0x3F, false) == 1);
        assert(data[0] == 0xBF);

        data[] = 0;
        assert(ionPutVarInt!T(data.ptr, 0x3F, true) == 1);
        assert(data[0] == 0xFF);

        data[] = 0;
        assert(ionPutVarInt!T(data.ptr, 0x7F, false) == 2);
        assert(data[0] == 0x00);
        assert(data[1] == 0xFF);

        data[] = 0;
        assert(ionPutVarInt!T(data.ptr, 128, true) == 2);
        assert(data[0] == 0x41);
        assert(data[1] == 0x80);

        data[] = 0;
        assert(ionPutVarInt!T(data.ptr, 127, true) == 2);
        assert(data[0] == 0x40);
        assert(data[1] == 0xFF);


        data[] = 0;
        assert(ionPutVarInt!T(data.ptr, 3, true) == 1);
        assert(data[0] == 0xC3);

        data[] = 0;
        assert(ionPutVarInt!T(data.ptr, 127, true) == 2);
        assert(data[0] == 0x40);
        assert(data[1] == 0xFF);

        data[] = 0;
        assert(ionPutVarInt!T(data.ptr, 63, true) == 1);
        assert(data[0] == 0xFF);
    }

    data[] = 0;
    assert(ionPutVarInt!uint(data.ptr, int.max, false) == 5);
    assert(data[0] == 0x07);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0xFF);

    data[] = 0;
    assert(ionPutVarInt!uint(data.ptr, int.max, true) == 5);
    assert(data[0] == 0x47);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0xFF);

    data[] = 0;
    assert(ionPutVarInt!uint(data.ptr, int.max + 1, true) == 5);
    assert(data[0] == 0x48);
    assert(data[1] == 0x00);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x80);

    data[] = 0;
    assert(ionPutVarInt!ulong(data.ptr, long.max >> 1, false) == 9);
    assert(data[0] == 0x3F);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0xFF);

    data[] = 0;
    assert(ionPutVarInt!ulong(data.ptr, long.max, false) == 10);
    assert(data[0] == 0x00);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0x7F);
    assert(data[9] == 0xFF);

    data[] = 0;
    assert(ionPutVarInt!ulong(data.ptr, long.max, true) == 10);
    assert(data[0] == 0x40);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0x7F);
    assert(data[9] == 0xFF);

    data[] = 0;
    assert(ionPutVarInt!ulong(data.ptr, -long.min, true) == 10);
    assert(data[0] == 0x41);
    assert(data[1] == 0x00);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x00);
    assert(data[9] == 0x80);

    data[] = 0;
    assert(ionPutVarInt(data.ptr, ulong.max, true) == 10);
    assert(data[0] == 0x41);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0x7F);
    assert(data[9] == 0xFF);

    data[] = 0;
    assert(ionPutVarInt(data.ptr, ulong.max, false) == 10);
    assert(data[0] == 0x01);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0x7F);
    assert(data[9] == 0xFF);
}

/++
+/
size_t ionPutVarIntR(T)(scope ubyte* ptr, const T num)
    if (isSigned!T)
{
    return .ionPutVarIntR!(Unsigned!T)(ptr, num < 0 ? cast(Unsigned!T)(0-num) : num, num < 0);
}

/++
+/
size_t ionPutVarIntR(T)(scope ubyte* ptr, const T num, bool sign)
    if (isUnsigned!T)
{
    T value = num; 
    if (_expect(value < 64, true))
    {
        *(ptr - 1) = cast(ubyte)(value | 0x80 | (sign << 6));
        return 1;
    }
    enum s = T.sizeof * 8 / 7 + 1;
    size_t len;
    do *(ptr - ++len) = value & 0x7F;
    while (value >>>= 7);
    auto sb = *(ptr - len) >>> 6;
    auto r = *(ptr - len) & ~(~sb + 1);
    len += sb;
    *(ptr - len) = cast(ubyte)r | (cast(ubyte)sign << 6);
    *(ptr - 1) |= 0x80;
    return len;
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[10] data = void;

    alias AliasSeq(T...) = T;


    foreach(T; AliasSeq!(ubyte, ushort, uint, ulong))
    {
        data[] = 0;
        assert(ionPutVarIntR!T(data.ptr + 10, 0, false) == 1);
        assert(data[$ - 1] == 0x80);

        data[] = 0;
        assert(ionPutVarIntR!T(data.ptr + 10, 1, false) == 1);
        assert(data[$ - 1] == 0x81);

        data[] = 0;
        assert(ionPutVarIntR!T(data.ptr + 10, 1, true) == 1);
        assert(data[$ - 1] == 0xC1);

        data[] = 0;
        assert(ionPutVarIntR!T(data.ptr + 10, 0x3F, false) == 1);
        assert(data[$ - 1] == 0xBF);

        data[] = 0;
        assert(ionPutVarIntR!T(data.ptr + 10, 0x3F, true) == 1);
        assert(data[$ - 1] == 0xFF);

        data[] = 0;
        assert(ionPutVarIntR!T(data.ptr + 10, 0x7F, false) == 2);
        assert(data[$ - 2] == 0x00);
        assert(data[$ - 1] == 0xFF);

        data[] = 0;
        assert(ionPutVarIntR!T(data.ptr + 10, 128, true) == 2);
        assert(data[$ - 2] == 0x41);
        assert(data[$ - 1] == 0x80);

        data[] = 0;
        assert(ionPutVarIntR!T(data.ptr + 10, 127, true) == 2);
        assert(data[$ - 2] == 0x40);
        assert(data[$ - 1] == 0xFF);


        data[] = 0;
        assert(ionPutVarIntR!T(data.ptr + 10, 3, true) == 1);
        assert(data[$ - 1] == 0xC3);

        data[] = 0;
        assert(ionPutVarIntR!T(data.ptr + 10, 127, true) == 2);
        assert(data[$ - 2] == 0x40);
        assert(data[$ - 1] == 0xFF);

        data[] = 0;
        assert(ionPutVarIntR!T(data.ptr + 10, 63, true) == 1);
        assert(data[$ - 1] == 0xFF);
    }

    data[] = 0;
    assert(ionPutVarIntR!uint(data.ptr + 10, int.max, false) == 5);
    assert(data[5 + 0] == 0x07);
    assert(data[5 + 1] == 0x7F);
    assert(data[5 + 2] == 0x7F);
    assert(data[5 + 3] == 0x7F);
    assert(data[5 + 4] == 0xFF);

    data[] = 0;
    assert(ionPutVarIntR!uint(data.ptr + 10, int.max, true) == 5);
    assert(data[5 + 0] == 0x47);
    assert(data[5 + 1] == 0x7F);
    assert(data[5 + 2] == 0x7F);
    assert(data[5 + 3] == 0x7F);
    assert(data[5 + 4] == 0xFF);

    data[] = 0;
    assert(ionPutVarIntR!uint(data.ptr + 10, int.max + 1, true) == 5);
    assert(data[5 + 0] == 0x48);
    assert(data[5 + 1] == 0x00);
    assert(data[5 + 2] == 0x00);
    assert(data[5 + 3] == 0x00);
    assert(data[5 + 4] == 0x80);

    data[] = 0;
    assert(ionPutVarIntR!ulong(data.ptr + 10, long.max >> 1, false) == 9);
    assert(data[1 + 0] == 0x3F);
    assert(data[1 + 1] == 0x7F);
    assert(data[1 + 2] == 0x7F);
    assert(data[1 + 3] == 0x7F);
    assert(data[1 + 4] == 0x7F);
    assert(data[1 + 5] == 0x7F);
    assert(data[1 + 6] == 0x7F);
    assert(data[1 + 7] == 0x7F);
    assert(data[1 + 8] == 0xFF);

    data[] = 0;
    assert(ionPutVarIntR!ulong(data.ptr + 10, long.max, false) == 10);
    assert(data[0] == 0x00);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0x7F);
    assert(data[9] == 0xFF);

    data[] = 0;
    assert(ionPutVarIntR!ulong(data.ptr + 10, long.max, true) == 10);
    assert(data[0] == 0x40);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0x7F);
    assert(data[9] == 0xFF);

    data[] = 0;
    assert(ionPutVarIntR!ulong(data.ptr + 10, -long.min, true) == 10);
    assert(data[0] == 0x41);
    assert(data[1] == 0x00);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x00);
    assert(data[9] == 0x80);

    data[] = 0;
    assert(ionPutVarIntR(data.ptr + 10, ulong.max, true) == 10);
    assert(data[0] == 0x41);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0x7F);
    assert(data[9] == 0xFF);

    data[] = 0;
    assert(ionPutVarIntR(data.ptr + 10, ulong.max, false) == 10);
    assert(data[0] == 0x01);
    assert(data[1] == 0x7F);
    assert(data[2] == 0x7F);
    assert(data[3] == 0x7F);
    assert(data[4] == 0x7F);
    assert(data[5] == 0x7F);
    assert(data[6] == 0x7F);
    assert(data[7] == 0x7F);
    assert(data[8] == 0x7F);
    assert(data[9] == 0xFF);
}

/++
+/
@optStrategy("optsize")
size_t ionPutUIntField()(
    scope ubyte* ptr,
    BigUIntView!(const size_t) value,
    )
{
    auto data = value.coefficients;
    size_t ret;
    static if (size_t.sizeof > 1)
    {
        if (data.length)
        {
            ret = .ionPutUIntField(ptr, data[$ - 1]);
            data = data[0 .. $ - 1];
        }
    }
    foreach_reverse (d; data)
    {
        *cast(ubyte[size_t.sizeof]*)(ptr + ret) = byteData(d);
        ret += size_t.sizeof;
    }
    return ret;
}

/++
+/
size_t ionPutUIntField(T)(scope ubyte* ptr, const T num)
    if (isUnsigned!T && T.sizeof >= 4)
{
    T value = num;
    auto c = cast(size_t)ctlzp(value);
    enum ubyte cm = 0xF8 & (value.sizeof * 8 - 1);
    value <<= c & cm;
    c >>>= 3;
    *cast(ubyte[T.sizeof]*)ptr = byteData(value);
    return T.sizeof - c;
}

/++
+/
size_t ionPutUIntField(T)(scope ubyte* ptr, const T num)
    if (is(T == ubyte))
{
    *ptr = num;
    return num != 0;
}

/++
+/
size_t ionPutUIntField(T)(scope ubyte* ptr, const T num)
    if (is(T == ushort))
{
    return ionPutUIntField!uint(ptr, num);
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[8] data;

    alias AliasSeq(T...) = T;

    foreach(T; AliasSeq!(ubyte, ushort, uint, ulong))
    {
        data[] = 0;
        assert(ionPutUIntField!T(data.ptr, 0) == 0);

        data[] = 0;
        assert(ionPutUIntField!T(data.ptr, 1) == 1);
        assert(data[0] == 0x01);

        data[] = 0;
        assert(ionPutUIntField!T(data.ptr, 0x3F) == 1);
        assert(data[0] == 0x3F);

        data[] = 0;
        assert(ionPutUIntField!T(data.ptr, 0xFF) == 1);
        assert(data[0] == 0xFF);

        data[] = 0;
        assert(ionPutUIntField!T(data.ptr, 0x80) == 1);
        assert(data[0] == 0x80);
    }

    data[] = 0;
    assert(ionPutUIntField!uint(data.ptr, int.max) == 4);
    assert(data[0] == 0x7F);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);

    data[] = 0;
    assert(ionPutUIntField!uint(data.ptr, int.max + 1) == 4);
    assert(data[0] == 0x80);
    assert(data[1] == 0x00);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);

    data[] = 0;
    assert(ionPutUIntField!ulong(data.ptr, long.max >> 1) == 8);
    assert(data[0] == 0x3F);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);

    data[] = 0;
    assert(ionPutUIntField!ulong(data.ptr, long.max) == 8);
    assert(data[0] == 0x7F);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);

    data[] = 0;
    assert(ionPutUIntField!ulong(data.ptr, long.max + 1) == 8);
    assert(data[0] == 0x80);
    assert(data[1] == 0x00);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);

    data[] = 0;
    assert(ionPutUIntField(data.ptr, ulong.max) == 8);
    assert(data[0] == 0xFF);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);
}


/++
+/
size_t ionPutUIntFieldR(T)(scope ubyte* ptr, const T num)
    if (isUnsigned!T && T.sizeof >= 4)
{
    T value = num;
    auto c = cast(size_t)ctlzp(value);
    enum ubyte cm = 0xF8 & (value.sizeof * 8 - 1);
    c >>>= 3;
    *cast(ubyte[T.sizeof]*)(ptr - T.sizeof) = byteData(value);
    return T.sizeof - c;
}

/++
+/
size_t ionPutUIntFieldR(T)(scope ubyte* ptr, const T num)
    if (is(T == ubyte))
{
    *(ptr - 1) = num;
    return num != 0;
}

/++
+/
size_t ionPutUIntFieldR(T)(scope ubyte* ptr, const T num)
    if (is(T == ushort))
{
    return ionPutUIntFieldR!uint(ptr, num);
}


///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[8] data;

    alias AliasSeq(T...) = T;

    foreach(T; AliasSeq!(ubyte, ushort, uint, ulong))
    {
        data[] = 0;
        assert(ionPutUIntFieldR!T(data.ptr + data.length, 0) == 0);

        data[] = 0;
        assert(ionPutUIntFieldR!T(data.ptr + data.length, 1) == 1);
        assert(data[$ - 1] == 0x01);

        data[] = 0;
        assert(ionPutUIntFieldR!T(data.ptr + data.length, 0x3F) == 1);
        assert(data[$ - 1] == 0x3F);

        data[] = 0;
        assert(ionPutUIntFieldR!T(data.ptr + data.length, 0xFF) == 1);
        assert(data[$ - 1] == 0xFF);

        data[] = 0;
        assert(ionPutUIntFieldR!T(data.ptr + data.length, 0x80) == 1);
        assert(data[$ - 1] == 0x80);
    }

    data[] = 0;
    assert(ionPutUIntFieldR!uint(data.ptr + data.length, int.max) == 4);
    assert(data[4 + 0] == 0x7F);
    assert(data[4 + 1] == 0xFF);
    assert(data[4 + 2] == 0xFF);
    assert(data[4 + 3] == 0xFF);

    data[] = 0;
    assert(ionPutUIntFieldR!uint(data.ptr + data.length, int.max + 1) == 4);
    assert(data[4 + 0] == 0x80);
    assert(data[4 + 1] == 0x00);
    assert(data[4 + 2] == 0x00);
    assert(data[4 + 3] == 0x00);

    data[] = 0;
    assert(ionPutUIntFieldR!ulong(data.ptr + data.length, long.max >> 1) == 8);
    assert(data[0] == 0x3F);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);

    data[] = 0;
    assert(ionPutUIntFieldR!ulong(data.ptr + data.length, long.max) == 8);
    assert(data[0] == 0x7F);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);

    data[] = 0;
    assert(ionPutUIntFieldR!ulong(data.ptr + data.length, long.max + 1) == 8);
    assert(data[0] == 0x80);
    assert(data[1] == 0x00);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);

    data[] = 0;
    assert(ionPutUIntFieldR(data.ptr + data.length, ulong.max) == 8);
    assert(data[0] == 0xFF);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);
}

/++
+/
@optStrategy("optsize")
size_t ionPutIntField()(
    scope ubyte* ptr,
    BigIntView!(const size_t) value,
    )
{
    auto data = value.unsigned.coefficients;
    if (data.length == 0)
    {
        *ptr = value.sign << 7;
        return value.sign;
    }
    size_t ret = .ionPutIntField(ptr, data[$ - 1], value.sign);
    data = data[0 .. $ - 1];
    foreach_reverse (d; data)
    {
        *cast(ubyte[size_t.sizeof]*)(ptr + ret) = byteData(d);
        ret += size_t.sizeof;
    }
    return ret;
}

/++
+/
size_t ionPutIntField(T)(scope ubyte* ptr, const T num)
    if (isSigned!T && isIntegral!T)
{
    T value = num;
    bool sign = value < 0;
    if (sign)
        value = cast(T)(0-value);
    return ionPutIntField!(Unsigned!T)(ptr, value, sign);
}

/++
+/
size_t ionPutIntField(T)(scope ubyte* ptr, const T num, bool sign)
    if (isUnsigned!T)
{
    T value = num;
    static if (T.sizeof >= 4)
    {
        auto c = cast(uint)ctlzp(value);
        bool s = (c & 0x7) == 0;
        *ptr = sign << 7;
        ptr += s;
        enum ubyte cm = 0xF8 & (value.sizeof * 8 - 1);
        value <<= c & cm;
        c >>>= 3;
        value |= T(sign) << (T.sizeof * 8 - 1);
        c = uint(T.sizeof) - c + s - (value == 0);
        *cast(ubyte[T.sizeof]*)ptr = byteData(value);
        return c;
    }
    else
    {
        return ionPutIntField!uint(ptr, value, sign);
    }
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[9] data;

    alias AliasSeq(T...) = T;

    foreach(T; AliasSeq!(ubyte, ushort, uint, ulong))
    {
        data[] = 0;
        assert(ionPutIntField!T(data.ptr, 0, false) == 0, T.stringof);

        data[] = 0;
        assert(ionPutIntField!T(data.ptr, 0, true) == 1);
        assert(data[0] == 0x80);

        data[] = 0;
        assert(ionPutIntField!T(data.ptr, 1, false) == 1);
        assert(data[0] == 0x01);

        data[] = 0;
        assert(ionPutIntField!T(data.ptr, 1, true) == 1);
        assert(data[0] == 0x81);

        data[] = 0;
        assert(ionPutIntField!T(data.ptr, 0x3F, true) == 1);
        assert(data[0] == 0xBF);

        data[] = 0;
        assert(ionPutIntField!T(data.ptr, 0xFF, false) == 2);
        assert(data[0] == 0x00);
        assert(data[1] == 0xFF);

        data[] = 0;
        assert(ionPutIntField!T(data.ptr, 0xFF, true) == 2);
        assert(data[0] == 0x80);
        assert(data[1] == 0xFF);

        data[] = 0;
        assert(ionPutIntField!T(data.ptr, 0x80, true) == 2);
        assert(data[0] == 0x80);
        assert(data[1] == 0x80);
    }

    data[] = 0;
    assert(ionPutIntField(data.ptr, int.max) == 4);
    assert(data[0] == 0x7F);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);

    data[] = 0;
    assert(ionPutIntField(data.ptr, int.min) == 5);
    assert(data[0] == 0x80);
    assert(data[1] == 0x80);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);

    data[] = 0;
    assert(ionPutIntField(data.ptr, long.max >> 1) == 8);
    assert(data[0] == 0x3F);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);

    data[] = 0;
    assert(ionPutIntField(data.ptr, ulong(long.max >> 1), true) == 8);
    assert(data[0] == 0xBF);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);

    data[] = 0;
    assert(ionPutIntField(data.ptr, long.max) == 8);
    assert(data[0] == 0x7F);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);

    data[] = 0;
    assert(ionPutIntField(data.ptr, ulong(long.max), true) == 8);
    assert(data[0] == 0xFF);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);

    data[] = 0;
    assert(ionPutIntField!ulong(data.ptr, long.max + 1, false) == 9);
    assert(data[0] == 0x00);
    assert(data[1] == 0x80);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x00);

    data[] = 0;
    assert(ionPutIntField(data.ptr, ulong.max, true) == 9);
    assert(data[0] == 0x80);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);
    assert(data[8] == 0xFF);
}

/++
+/
size_t ionPutIntFieldR(T)(scope ubyte* ptr, const T num)
    if (isSigned!T && isIntegral!T)
{
    T value = num;
    bool sign = value < 0;
    if (sign)
        value = cast(T)(0-value);
    return ionPutIntFieldR!(Unsigned!T)(ptr, value, sign);
}

/++
+/
size_t ionPutIntFieldR(T)(scope ubyte* ptr, const T num, bool sign)
    if (isUnsigned!T)
{
    T value = num;
    static if (T.sizeof >= 4)
    {
        auto c = cast(uint)ctlzp(value);
        bool s = (c & 0x7) == 0;
        enum ubyte cm = 0xF8 & (value.sizeof * 8 - 1);
        c >>>= 3;
        c = uint(T.sizeof) - c + s - ((value | sign) == 0);
        value |= T(sign) << ((c - (c > T.sizeof)) * 8 - 1);
        *cast(ubyte[T.sizeof]*)(ptr - T.sizeof) = byteData(value);
        *(ptr - T.sizeof - 1) = sign << 7;
        return c;
    }
    else
    {
        return ionPutIntFieldR!uint(ptr, value, sign);
    }
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[9] data;

    alias AliasSeq(T...) = T;

    foreach(T; AliasSeq!(ubyte, ushort, uint, ulong))
    {
        data[] = 0;
        assert(ionPutIntFieldR!T(data.ptr + 9, 0, false) == 0, T.stringof);

        data[] = 0;
        assert(ionPutIntFieldR!T(data.ptr + 9, 0, true) == 1);
        assert(data[$ - 1] == 0x80);

        data[] = 0;
        assert(ionPutIntFieldR!T(data.ptr + 9, 1, false) == 1);
        assert(data[$ - 1] == 0x01);

        data[] = 0;
        assert(ionPutIntFieldR!T(data.ptr + 9, 1, true) == 1);
        assert(data[$ - 1] == 0x81);

        data[] = 0;
        assert(ionPutIntFieldR!T(data.ptr + 9, 0x3F, true) == 1);
        assert(data[$ - 1] == 0xBF);

        data[] = 0;
        assert(ionPutIntFieldR!T(data.ptr + 9, 0xFF, false) == 2);
        assert(data[$ - 2] == 0x00);
        assert(data[$ - 1] == 0xFF);

        data[] = 0;
        assert(ionPutIntFieldR!T(data.ptr + 9, 0xFF, true) == 2);
        assert(data[$ - 2] == 0x80);
        assert(data[$ - 1] == 0xFF);

        data[] = 0;
        assert(ionPutIntFieldR!T(data.ptr + 9, 0x80, true) == 2);
        assert(data[$ - 2] == 0x80);
        assert(data[$ - 1] == 0x80);
    }

    data[] = 0;
    assert(ionPutIntFieldR(data.ptr + 9, int.max) == 4);
    assert(data[5 + 0] == 0x7F);
    assert(data[5 + 1] == 0xFF);
    assert(data[5 + 2] == 0xFF);
    assert(data[5 + 3] == 0xFF);

    data[] = 0;
    assert(ionPutIntFieldR(data.ptr + 9, int.min) == 5);
    assert(data[4 + 0] == 0x80);
    assert(data[4 + 1] == 0x80);
    assert(data[4 + 2] == 0x00);
    assert(data[4 + 3] == 0x00);
    assert(data[4 + 4] == 0x00);

    data[] = 0;
    assert(ionPutIntFieldR(data.ptr + 9, long.max >> 1) == 8);
    assert(data[1 + 0] == 0x3F);
    assert(data[1 + 1] == 0xFF);
    assert(data[1 + 2] == 0xFF);
    assert(data[1 + 3] == 0xFF);
    assert(data[1 + 4] == 0xFF);
    assert(data[1 + 5] == 0xFF);
    assert(data[1 + 6] == 0xFF);
    assert(data[1 + 7] == 0xFF);

    data[] = 0;
    assert(ionPutIntFieldR(data.ptr + 9, long.max) == 8);
    assert(data[1 + 0] == 0x7F);
    assert(data[1 + 1] == 0xFF);
    assert(data[1 + 2] == 0xFF);
    assert(data[1 + 3] == 0xFF);
    assert(data[1 + 4] == 0xFF);
    assert(data[1 + 5] == 0xFF);
    assert(data[1 + 6] == 0xFF);
    assert(data[1 + 7] == 0xFF);

    data[] = 0xFF;
    assert(ionPutIntFieldR!ulong(data.ptr + 9, long.max + 1, false) == 9);
    assert(data[0] == 0x00);
    assert(data[1] == 0x80);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x00);

    data[] = 0;
    assert(ionPutIntFieldR(data.ptr + 9, ulong.max, true) == 9);
    assert(data[0] == 0x80);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);
    assert(data[8] == 0xFF);
}

/++
+/
size_t ionPut(scope ubyte* ptr, typeof(null), IonTypeCode typeCode = IonTypeCode.null_) pure nothrow @nogc
{
    *ptr++ = cast(ubyte) (0x0F | (typeCode << 4));
    return 1;
}

///
// @system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[1] data;
    assert(ionPut(data.ptr, null) == 1);
    import mir.conv;
    assert(data[0] == 0x0F, data[0].to!string);
}

/++
+/
size_t ionPut(T : bool)(scope ubyte* ptr, const T value)
{
    *ptr++ = 0x10 | value;
    return 1;
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[1] data;
    assert(ionPut(data.ptr, true) == 1);
    assert(data[0] == 0x11);
    assert(ionPut(data.ptr, false) == 1);
    assert(data[0] == 0x10);
}

/++
+/
size_t ionPut(T)(scope ubyte* ptr, const T value, bool sign = false)
    if (isUnsigned!T)
{
    auto L = ionPutUIntField!T(ptr + 1, value);
    static if (T.sizeof <= 8)
    {
        *ptr = cast(ubyte) (0x20 | (sign << 4) | L);
        return L + 1;
    }
    else
    {
        static assert(0, "cent and ucent types not supported by mir.ion for now");
    }
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[19] data = void;
    assert(ionPut(data.ptr, 0u) == 1);
    assert(data[0] == 0x20);
    assert(ionPut(data.ptr, 0u, true) == 1);
    assert(data[0] == 0x30);
    assert(ionPut(data.ptr, 0xFFu) == 2);
    assert(data[0] == 0x21);
    assert(data[1] == 0xFF);
    assert(ionPut(data.ptr, 0xFFu, true) == 2);
    assert(data[0] == 0x31);
    assert(data[1] == 0xFF);

    assert(ionPut(data.ptr, ulong.max, true) == 9);
    assert(data[0] == 0x38);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);
    assert(data[8] == 0xFF);
}

/++
+/
size_t ionPutR(T)(scope ubyte* ptr, const T value, bool sign = false)
    if (isUnsigned!T)
{
    auto L = ionPutUIntFieldR!T(ptr, value);
    static if (T.sizeof <= 8)
    {
        *(ptr - (L + 1)) = cast(ubyte) (0x20 | (sign << 4) | L);
        return L + 1;
    }
    else
    {
        static assert(0, "cent and ucent types not supported by mir.ion for now");
    }
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[19] data = void;
    assert(ionPutR(data.ptr + 1, 0u) == 1);
    assert(data[0] == 0x20);
    assert(ionPutR(data.ptr + 1, 0u, true) == 1);
    assert(data[0] == 0x30);
    assert(ionPutR(data.ptr + 2, 0xFFu) == 2);
    assert(data[0] == 0x21);
    assert(data[1] == 0xFF);
    assert(ionPutR(data.ptr + 2, 0xFFu, true) == 2);
    assert(data[0] == 0x31);
    assert(data[1] == 0xFF);

    assert(ionPutR(data.ptr + 9, ulong.max, true) == 9);
    assert(data[0] == 0x38);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);
    assert(data[8] == 0xFF);
}

/++
+/
size_t joyPut(T)(scope ubyte* ptr, const T value, bool sign = false)
    if (isUnsigned!T)
{
    auto L = ionPutUIntField!T(ptr, value);
    static if (T.sizeof <= 8)
    {
        ptr[L] = cast(ubyte) (0x20 | (sign << 4) | L);
        return L + 1;
    }
    else
    {
        static assert(0, "cent and ucent types not supported by mir.ion for now");
    }
}

///
@("joyPutInteger0")
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[19] data = void;
    assert(joyPut(data.ptr, 0u) == 1);
    assert(data[0] == 0x20);
    assert(joyPut(data.ptr, 0u, true) == 1);
    assert(data[0] == 0x30);
    assert(joyPut(data.ptr, 0xFFu) == 2);
    assert(data[0] == 0xFF);
    assert(data[1] == 0x21);
    assert(joyPut(data.ptr, 0xFFu, true) == 2);
    assert(data[0] == 0xFF);
    assert(data[1] == 0x31);

    assert(joyPut(data.ptr, ulong.max, true) == 9);
    assert(data[0] == 0xFF);
    assert(data[1] == 0xFF);
    assert(data[2] == 0xFF);
    assert(data[3] == 0xFF);
    assert(data[4] == 0xFF);
    assert(data[5] == 0xFF);
    assert(data[6] == 0xFF);
    assert(data[7] == 0xFF);
    assert(data[8] == 0x38);
}

/++
+/
size_t ionPut(T)(scope ubyte* ptr, const T value)
    if (isSigned!T && isIntegral!T)
{
    bool sign = value < 0;
    T num = value;
    if (sign)
        num = cast(T)(0-num);
    return ionPut!(Unsigned!T)(ptr, num, sign);
}

///
@("ionPutInteger")
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[19] data = void;
    assert(ionPut(data.ptr, -16) == 2);
    assert(data[0] == 0x31);
    assert(data[1] == 0x10);

    assert(ionPut(data.ptr, 258) == 3);
    assert(data[0] == 0x22);
    assert(data[1] == 0x01);
    assert(data[2] == 0x02);
}

/++
+/
size_t joyPut(T)(scope ubyte* ptr, const T value)
    if (isSigned!T && isIntegral!T)
{
    bool sign = value < 0;
    T num = value;
    if (sign)
        num = cast(T)(0-num);
    return joyPut!(Unsigned!T)(ptr, num, sign);
}

///
@("joyPutInteger1")
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[19] data = void;
    assert(joyPut(data.ptr, -16) == 2);
    assert(data[0] == 0x10);
    assert(data[1] == 0x31);

    assert(joyPut(data.ptr, 258) == 3);
    assert(data[0] == 0x01);
    assert(data[1] == 0x02);
    assert(data[2] == 0x22);
}

private auto byteData(T)(const T value)
    if (__traits(isUnsigned, T))
{
    static if (T.sizeof == 1)
    {
        T num = value;
    }
    else
    version (LittleEndian)
    {
        import core.bitop: bswap;
        T num = bswap(value);
    }
    else
    {
        T num = value;
    }

    ubyte[T.sizeof] data;

    if (__ctfe)
    {
        foreach (ref d; data)
        {
            d = num & 0xFF;
            num >>= 8;
        }
    }
    else
    {
        data = cast(ubyte[T.sizeof])cast(T[1])[num];
    }

    return data;
}

/++
+/
size_t ionPut(T)(scope ubyte* ptr, const T value)
    if (is(T == float))
{
    auto num = *cast(uint*)&value;
    auto s = (num != 0) << 2;
    *ptr = cast(ubyte)(0x40 + s);
    *cast(ubyte[4]*)(ptr + 1) = byteData(num);
    return 1 + s;
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[5] data;
    assert(ionPut(data.ptr, -16f) == 5);
    assert(data[0] == 0x44);
    assert(data[1] == 0xC1);
    assert(data[2] == 0x80);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);

    assert(ionPut(data.ptr, 0f) == 1);
    assert(data[0] == 0x40);

    assert(ionPut(data.ptr, -0f) == 5);
    assert(data[0] == 0x44);
    assert(data[1] == 0x80);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
}

/++
+/
size_t joyPut(T)(scope ubyte* ptr, const T value)
    if (is(T == float))
{
    auto num = *cast(uint*)&value;
    auto s = (num != 0) << 2;
    *cast(ubyte[4]*) ptr = byteData(num);
    ptr[s] = cast(ubyte)(0x40 + s);
    return 1 + s;
}

///
@("joyPutIntegerFloat")
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[5] data;
    assert(joyPut(data.ptr, -16f) == 5);
    assert(data[0] == 0xC1);
    assert(data[1] == 0x80);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x44);

    assert(joyPut(data.ptr, 0f) == 1);
    assert(data[0] == 0x40);

    assert(joyPut(data.ptr, -0f) == 5);
    assert(data[0] == 0x80);
    assert(data[1] == 0x00);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x44);
}

/++
+/
size_t ionPut(T)(scope ubyte* ptr, const T value)
    if (is(T == double))
{
    auto num = *cast(ulong*)&value;
    auto s = (num != 0) << 3;
    *ptr = cast(ubyte)(0x40 + s);
    *cast(ubyte[8]*)(ptr + 1) = byteData(num);
    return 1 + s;
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[9] data;
    assert(ionPut(data.ptr, -16.0) == 9);
    assert(data[0] == 0x48);
    assert(data[1] == 0xC0);
    assert(data[2] == 0x30);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x00);

    assert(ionPut(data.ptr, 0.0) == 1);
    assert(data[0] == 0x40);

    assert(ionPut(data.ptr, -0.0) == 9);
    assert(data[0] == 0x48);
    assert(data[1] == 0x80);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x00);
}

/++
+/
size_t ionPutR(T)(scope ubyte* ptr, const T value)
    if (is(T == double))
{
    auto num = *cast(ulong*)&value;
    auto s = (num != 0) << 3;
    *cast(ubyte[8]*)(ptr - double.sizeof) = byteData(num);
    *(ptr - (s + 1)) = cast(ubyte)(0x40 + s);
    return s + 1;
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[9] data;
    assert(ionPutR(data.ptr + data.length, -16.0) == 9);
    assert(data[0] == 0x48);
    assert(data[1] == 0xC0);
    assert(data[2] == 0x30);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x00);

    assert(ionPutR(data.ptr + data.length, 0.0) == 1);
    assert(data[$ - 1] == 0x40);

    assert(ionPutR(data.ptr + data.length, -0.0) == 9);
    assert(data[0] == 0x48);
    assert(data[1] == 0x80);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x00);
}

/++
+/
size_t joyPut(T)(scope ubyte* ptr, const T value)
    if (is(T == double))
{
    auto num = *cast(ulong*)&value;
    auto s = (num != 0) << 3;
    *cast(ubyte[8]*) ptr = byteData(num);
    ptr[s] = cast(ubyte)(0x40 + s);
    return 1 + s;
}

///
@("joyPutIntegerDouble")
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[9] data;
    assert(joyPut(data.ptr, -16.0) == 9);
    assert(data[0] == 0xC0);
    assert(data[1] == 0x30);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x48);

    assert(joyPut(data.ptr, 0.0) == 1);
    assert(data[0] == 0x40);

    assert(joyPut(data.ptr, -0.0) == 9);
    assert(data[0] == 0x80);
    assert(data[1] == 0x00);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x48);
}

/++
+/
size_t ionPut(T)(scope ubyte* ptr, const T value)
    if (is(T == real))
{
    return ionPut!double(ptr, value);
}

///
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[9] data;
    assert(ionPut(data.ptr, -16.0L) == 9);
    assert(data[0] == 0x48);
    assert(data[1] == 0xC0);
    assert(data[2] == 0x30);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x00);

    assert(ionPut(data.ptr, 0.0L) == 1);
    assert(data[0] == 0x40);

    assert(ionPut(data.ptr, -0.0L) == 9);
    assert(data[0] == 0x48);
    assert(data[1] == 0x80);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x00);
}

/++
+/
size_t joyPut(T)(scope ubyte* ptr, const T value)
    if (is(T == real))
{
    return joyPut!double(ptr, value);
}

///
@("joyPutIntegerReal")
@system pure nothrow @nogc
version(mir_ion_test) unittest
{
    ubyte[9] data;
    assert(joyPut(data.ptr, -16.0L) == 9);
    assert(data[0] == 0xC0);
    assert(data[1] == 0x30);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x48);

    assert(joyPut(data.ptr, 0.0L) == 1);
    assert(data[0] == 0x40);

    assert(joyPut(data.ptr, -0.0L) == 9);
    assert(data[0] == 0x80);
    assert(data[1] == 0x00);
    assert(data[2] == 0x00);
    assert(data[3] == 0x00);
    assert(data[4] == 0x00);
    assert(data[5] == 0x00);
    assert(data[6] == 0x00);
    assert(data[7] == 0x00);
    assert(data[8] == 0x48);
}

/++
+/
size_t ionPut()(
    scope ubyte* ptr,
    BigUIntView!(const size_t) value,
    )
{
    return ionPut(ptr, value.signed);
}

pure
version(mir_ion_test) unittest
{
    ubyte[32] data;
    // big unsigned integer
    assert(ionPut(data.ptr, BigUIntView!size_t.fromHexString("88BF4748507FB9900ADB624CCFF8D78897DC900FB0460327D4D86D327219").lightConst) == 32);
    assert(data[0] == 0x2E);
    assert(data[1] == 0x9E);
    // assert(data[2 .. 32] == BigUIntView!(ubyte, WordEndian.big).fromHexString("88BF4748507FB9900ADB624CCFF8D78897DC900FB0460327D4D86D327219").coefficients);
}

/++
+/
size_t joyPut()(
    scope ubyte* ptr,
    BigUIntView!(const size_t) value,
    )
{
    return joyPut(ptr, value.signed);
}

@("joyPutBigUIntView")
pure
version(mir_ion_test) unittest
{
    ubyte[32] data;
    // big unsigned integer
    assert(joyPut(data.ptr, BigUIntView!size_t.fromHexString("88BF4748507FB9900ADB624CCFF8D78897DC900FB0460327D4D86D327219").lightConst) == 32);
    assert(data[31] == 0x2E);
    assert(data[30] == 0x9E);
    // assert(data[2 .. 32] == BigUIntView!(ubyte, WordEndian.big).fromHexString("88BF4748507FB9900ADB624CCFF8D78897DC900FB0460327D4D86D327219").coefficients);
}

/++
+/
size_t ionPut()(
    scope ubyte* ptr,
    BigIntView!(const size_t) value,
    )
{
    auto length = ionPutUIntField(ptr + 1, value.unsigned);
    auto q = 0x20 | (value.sign << 4);
    if (_expect(length < 0xE, true))
    {
        *ptr = cast(ubyte)(q | length);
        return length + 1;
    }
    else
    {
        *ptr = cast(ubyte)(q | 0xE);
        ubyte[19] lengthPayload = void;
        auto lengthLength = ionPutVarUInt(lengthPayload.ptr, length);

        if (__ctfe)
        {
            foreach_reverse (i; 0 .. length)
                ptr[i + 1 + lengthLength] = ptr[i + 1];
            ptr[1 .. lengthLength + 1] = lengthPayload[0 .. lengthLength];
        }
        else
        {
            memmove(ptr + 1 + lengthLength, ptr + 1, length);
            memcpy(ptr + 1, lengthPayload.ptr, lengthLength);
        }
        return length + 1 + lengthLength;
    }
}

pure
version(mir_ion_test) unittest
{
    ubyte[9] data;
    // big unsigned integer
    assert(ionPut(data.ptr, -BigUIntView!size_t.fromHexString("45be").lightConst) == 3);
    assert(data[0] == 0x32);
    assert(data[1] == 0x45);
    assert(data[2] == 0xbe);
}

/++
+/
size_t joyPut()(
    scope ubyte* ptr,
    BigIntView!(const size_t) value,
    )
{
    auto length = ionPutUIntField(ptr, value.unsigned);
    return joyPutEnd(ptr, value.sign ? IonTypeCode.nInt : IonTypeCode.uInt, length);
}

@("joyPutBigIntView")
pure
version(mir_ion_test) unittest
{
    import mir.test;
    ubyte[9] data;
    // big signed integer
    data[0 .. joyPut(data.ptr, -BigUIntView!size_t.fromHexString("45be").lightConst)]
        .should == [0x45, 0xbe, 0x32];
}

/++
+/
size_t ionPut()(
    scope ubyte* ptr,
    DecimalView!(const size_t) value,
    )
{
    size_t length;
    if (value.coefficient.coefficients.length == 0 && value.sign == false && value.exponent == 0)
        goto L;
    length = ionPutVarInt(ptr + 1, value.exponent);
    length += ionPutIntField(ptr + 1 + length, value.signedCoefficient);
    if (_expect(length < 0xE, true))
    {
    L:
        *ptr = cast(ubyte)(0x50 | length);
        return length + 1;
    }
    else
    {
        *ptr = 0x5E;
        ubyte[19] lengthPayload = void;
        auto lengthLength = ionPutVarUInt(lengthPayload.ptr, length);
        if (__ctfe)
        {
            foreach_reverse (i; 0 .. length)
                ptr[i + 1 + lengthLength] = ptr[i + 1];
            ptr[1 .. lengthLength + 1] = lengthPayload[0 .. lengthLength];
        }
        else
        {
            memmove(ptr + 1 + lengthLength, ptr + 1, length);
            memcpy(ptr + 1, lengthPayload.ptr, lengthLength);
        }
        return length + 1 + lengthLength;
    }
}

pure
version(mir_ion_test) unittest
{
    ubyte[34] data;
    // 0.6
    assert(ionPut(data.ptr, DecimalView!size_t(false, -1, BigUIntView!size_t.fromHexString("06")).lightConst) == 3);
    assert(data[0] == 0x52);
    assert(data[1] == 0xC1);
    assert(data[2] == 0x06);

    // -0.6
    assert(ionPut(data.ptr, DecimalView!size_t(true, -1, BigUIntView!size_t.fromHexString("06")).lightConst) == 3);
    assert(data[0] == 0x52);
    assert(data[1] == 0xC1);
    assert(data[2] == 0x86);


    // 0e-3
    assert(ionPut(data.ptr, DecimalView!size_t(false, 3, BigUIntView!size_t([0])).lightConst) == 2);
    assert(data[0] == 0x51);
    assert(data[1] == 0x83);

    // -0e+0
    assert(ionPut(data.ptr, DecimalView!size_t(true, 0, BigUIntView!size_t([0])).lightConst) == 3);
    assert(data[0] == 0x52);
    assert(data[1] == 0x80);
    assert(data[2] == 0x80);

    // 0e+0
    assert(ionPut(data.ptr, DecimalView!size_t(false, 0, BigUIntView!size_t([0])).lightConst) == 2);
    assert(data[0] == 0x51);
    assert(data[1] == 0x80);

    // 0e+0 (minimal)
    assert(ionPut(data.ptr, DecimalView!size_t(false, 0, BigUIntView!size_t.init).lightConst) == 1);
    assert(data[0] == 0x50);

    // big decimal
    assert(ionPut(data.ptr, DecimalView!size_t(false, -9, BigUIntView!size_t.fromHexString("88BF4748507FB9900ADB624CCFF8D78897DC900FB0460327D4D86D327219")).lightConst) == 34);
    assert(data[0] == 0x5E);
    assert(data[1] == 0xA0);
    assert(data[2] == 0xC9);
    assert(data[3] == 0x00);
    // assert(data[4 .. 34] == BigUIntView!(ubyte, WordEndian.big).fromHexString("88BF4748507FB9900ADB624CCFF8D78897DC900FB0460327D4D86D327219").coefficients);

    // -12.345
    // assert( >=0);
    assert(ionPut(data.ptr, DecimalView!size_t(true, -3, BigUIntView!size_t.fromHexString("3039")).lightConst) == 4);
    assert(data[0] == 0x53);
    assert(data[1] == 0xC3);
    assert(data[2] == 0xB0);
    assert(data[3] == 0x39);
    // assert(data[0] == 0x50);
}

/++
+/
size_t joyPut()(
    scope ubyte* ptr,
    DecimalView!(const size_t) value,
    )
{
    size_t length;
    if (value.coefficient.coefficients.length || value.sign)
    {
        length = ionPutVarInt(ptr, value.exponent);
        length += ionPutIntField(ptr + length, value.signedCoefficient);
    }
    return joyPutEnd(ptr, IonTypeCode.decimal, length);
}

@("joyPutDecimalView")
pure
version(mir_ion_test) unittest
{
    import mir.test;

    ubyte[34] data;
    // 0.6
    assert(joyPut(data.ptr, DecimalView!size_t(false, -1, BigUIntView!size_t.fromHexString("06")).lightConst) == 3);
    assert(data[0] == 0xC1);
    assert(data[1] == 0x06);
    assert(data[2] == 0x52);

    // -0.6
    assert(joyPut(data.ptr, DecimalView!size_t(true, -1, BigUIntView!size_t.fromHexString("06")).lightConst) == 3);
    assert(data[0] == 0xC1);
    assert(data[1] == 0x86);
    assert(data[2] == 0x52);


    // 0e-3
    assert(joyPut(data.ptr, DecimalView!size_t(false, 3, BigUIntView!size_t([0])).lightConst) == 2);
    assert(data[0] == 0x83);
    assert(data[1] == 0x51);

    // -0e+0
    assert(joyPut(data.ptr, DecimalView!size_t(true, 0, BigUIntView!size_t([0])).lightConst) == 3);
    assert(data[0] == 0x80);
    assert(data[1] == 0x80);
    assert(data[2] == 0x52);

    // 0e+0
    assert(joyPut(data.ptr, DecimalView!size_t(false, 0, BigUIntView!size_t([0])).lightConst) == 2);
    assert(data[0] == 0x80);
    assert(data[1] == 0x51);

    // 0e+0 (minimal)
    assert(joyPut(data.ptr, DecimalView!size_t(false, 0, BigUIntView!size_t.init).lightConst) == 1);
    assert(data[0] == 0x50);

    // big decimal
    data[0 .. joyPut(data.ptr, DecimalView!size_t(false, -9, BigUIntView!size_t.fromHexString("88BF4748507FB9900ADB624CCFF8D78897DC900FB0460327D4D86D327219")).lightConst)]
        .should == [0xC9, 0x00, 0x88, 0xBF, 0x47, 0x48, 0x50, 0x7F, 0xB9, 0x90, 0x0A, 0xDB, 0x62, 0x4C, 0xCF, 0xF8, 0xD7, 0x88, 0x97, 0xDC, 0x90, 0x0F, 0xB0, 0x46, 0x03, 0x27, 0xD4, 0xD8, 0x6D, 0x32, 0x72, 0x19, 0xA0, 0x5E];

    // -12.345
    data[0 .. joyPut(data.ptr, DecimalView!size_t(true, -3, BigUIntView!size_t.fromHexString("3039")).lightConst)]
        .should == [0xC3, 0xB0, 0x39, 0x53];
}

///
size_t ionPutDecimal()(scope ubyte* ptr, bool sign, ulong coefficient, long exponent)
{
    version(LDC)
        pragma(inline, true);
    size_t length;
    // if (coefficient == 0)
    //     goto L;
    length = ionPutVarInt(ptr + 1, exponent);
    length += ionPutIntField(ptr + 1 + length, coefficient, sign);
    if (_expect(length < 0xE, true))
    {
    L:
        *ptr = cast(ubyte)(0x50 | length);
        return length + 1;
    }
    else
    {
        memmove(ptr + 2, ptr + 1, 16);
        *ptr = 0x5E;
        assert(length < 0x80);
        ptr[1] = cast(ubyte) (length ^ 0x80);
        return length + 2;
    }
}

///
size_t ionPutDecimalR()(scope ubyte* ptr, bool sign, ulong coefficient, long exponent)
{
    version(LDC)
        pragma(inline, true);
    size_t length;
    // if (coefficient == 0)
    //     goto L;
    length = ionPutIntFieldR(ptr, coefficient, sign);
    length += ionPutVarIntR(ptr - length, exponent);
    ptr -= length;
    if (_expect(length < 0xE, true))
    {
    L:
        *--ptr = cast(ubyte)(0x50 | length);
        return length + 1;
    }
    else
    {
        *--ptr = cast(ubyte)(0x80 | length);
        *--ptr = 0x5E;
        return length + 2;
    }
}

///
size_t joyPutDecimal()(scope ubyte* ptr, bool sign, ulong coefficient, long exponent)
{
    version(LDC)
        pragma(inline, true);
    size_t length;
    if (coefficient || sign)
    {
        length = ionPutVarInt(ptr, exponent);
        length += ionPutIntField(ptr + length, coefficient, sign);
    }
    return joyPutEnd(ptr, IonTypeCode.decimal, length);
}

/++
+/
size_t ionPut(T)(scope ubyte* ptr, const T value)
    if (is(T == Timestamp))
{
    size_t ret = 1;
    ret += ionPutVarInt(ptr + ret, value.offset);
    ret += ionPutVarUInt(ptr + ret, cast(ushort)value.year);
    if (value.precision >= Timestamp.precision.month)
    {
        ptr[ret++] = cast(ubyte) (0x80 | value.month);
        if (value.precision >= Timestamp.precision.day)
        {
            ptr[ret++] = cast(ubyte) (0x80 | value.day);
            if (value.precision >= Timestamp.precision.minute)
            {
                ptr[ret++] = cast(ubyte) (0x80 | value.hour);
                ptr[ret++] = cast(ubyte) (0x80 | value.minute);
                if (value.precision >= Timestamp.precision.second)
                {
                    ptr[ret++] = cast(ubyte) (0x80 | value.second);
                    if (value.precision > Timestamp.precision.second) //fraction
                    {
                        ret += ionPutVarInt(ptr + ret, value.fractionExponent);
                        ret += ionPutIntField(ptr + ret, long(value.fractionCoefficient));
                    }
                }
            }
        }
    }
    auto length = ret - 1;
    if (_expect(ret < 0xF, true))
    {
        *ptr = cast(ubyte) (0x60 | length);
        return ret;
    }
    else
    {
        if (__ctfe)
            foreach_reverse (i; 0 .. length)
                ptr[i + 2] = ptr[i + 1];
        else
            memmove(ptr + 2, ptr + 1, length);
        *ptr = 0x6E;
        ptr[1] = cast(ubyte) (0x80 | length);
        return ret + 1;
    }
}

///
version(mir_ion_test) unittest
{
    import mir.timestamp;

    ubyte[20] data;

    ubyte[] result = [0x68, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84];
    auto ts = Timestamp(2000, 7, 8, 2, 3, 4);
    assert(data[0 .. ionPut(data.ptr, ts)] == result);

    result = [0x69, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0xC2];
    ts = Timestamp(2000, 7, 8, 2, 3, 4, -2, 0);
    assert(data[0 .. ionPut(data.ptr, ts)] == result);

    result = [0x6A, 0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0xC3, 0x10];
    ts = Timestamp(2000, 7, 8, 2, 3, 4, -3, 16);
    assert(data[0 .. ionPut(data.ptr, ts)] == result);
}

/++
+/
size_t joyPut(T)(scope ubyte* ptr, const T value)
    if (is(T == Timestamp))
{
    size_t length;
    length += ionPutVarInt(ptr + length, value.offset);
    length += ionPutVarUInt(ptr + length, cast(ushort)value.year);
    if (value.precision >= Timestamp.precision.month)
    {
        ptr[length++] = cast(ubyte) (0x80 | value.month);
        if (value.precision >= Timestamp.precision.day)
        {
            ptr[length++] = cast(ubyte) (0x80 | value.day);
            if (value.precision >= Timestamp.precision.minute)
            {
                ptr[length++] = cast(ubyte) (0x80 | value.hour);
                ptr[length++] = cast(ubyte) (0x80 | value.minute);
                if (value.precision >= Timestamp.precision.second)
                {
                    ptr[length++] = cast(ubyte) (0x80 | value.second);
                    if (value.precision > Timestamp.precision.second) //fraction
                    {
                        length += ionPutVarInt(ptr + length, value.fractionExponent);
                        length += ionPutIntField(ptr + length, long(value.fractionCoefficient));
                    }
                }
            }
        }
    }

    return joyPutEnd(ptr, IonTypeCode.timestamp, length);
}

///
@("joyPutTimestamp")
version(mir_ion_test) unittest
{
    import mir.test;
    import mir.timestamp;

    ubyte[20] data;

    ubyte[] result = [0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0x68];
    auto ts = Timestamp(2000, 7, 8, 2, 3, 4);
    data[0 .. joyPut(data.ptr, ts)].should == result;

    result = [0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0xC2, 0x69];
    ts = Timestamp(2000, 7, 8, 2, 3, 4, -2, 0);
    data[0 .. joyPut(data.ptr, ts)].should == result;

    result = [0x80, 0x0F, 0xD0, 0x87, 0x88, 0x82, 0x83, 0x84, 0xC3, 0x10, 0x6A];
    ts = Timestamp(2000, 7, 8, 2, 3, 4, -3, 16);
    data[0 .. joyPut(data.ptr, ts)].should == result;
}

/++
+/
size_t ionPut(T)(scope ubyte* ptr, const T value)
    if (is(T == Date))
{
    size_t ret = 1;
    auto ymd = value.yearMonthDay;
    ptr[ret++] = 0x80;
    ret += ionPutVarUInt(ptr + ret, cast(ushort)value.year);
    ptr[ret++] = cast(ubyte) (0x80 | value.month);
    ptr[ret++] = cast(ubyte) (0x80 | value.day);
    auto length = ret - 1;
    *ptr = cast(ubyte) (0x60 | length);
    return ret;
}

///
version(mir_ion_test) unittest
{
    import mir.date;

    ubyte[13] data;

    ubyte[] result = [0x65, 0x80, 0x0F, 0xD0, 0x87, 0x88];
    auto ts = Date(2000, 7, 8);
    assert(data[0 .. ionPut(data.ptr, ts)] == result);
}

/++
+/
size_t ionPutSymbolId(T)(scope ubyte* ptr, const T value)
    if (isUnsigned!T)
{
    auto length = ionPutUIntField(ptr + 1, value);
    *ptr = cast(ubyte)(0x70 | length);
    return length + 1;
}

///
version(mir_ion_test) unittest
{
    ubyte[8] data;

    ubyte[] result = [0x72, 0x01, 0xFF];
    auto id = 0x1FFu;
    assert(data[0 .. ionPutSymbolId(data.ptr, id)] == result);
}

/++
+/
size_t joyPutSymbolId(T)(scope ubyte* ptr, const T value)
    if (isUnsigned!T)
{
    auto length = ionPutUIntField(ptr, value);
    ptr[length] = cast(ubyte)(0x70 | length);
    return length + 1;
}

///
@("joyPutSymbolId")
version(mir_ion_test) unittest
{
    ubyte[8] data;

    ubyte[] result = [0x01, 0xFF, 0x72];
    auto id = 0x1FFu;
    assert(data[0 .. joyPutSymbolId(data.ptr, id)] == result);
}

/++
+/
size_t ionPutSymbolId(T)(scope ubyte* ptr, BigUIntView!T value)
{
    auto length = ionPutUIntField(ptr + 1, value);
    assert(length < 10);
    *ptr = cast(ubyte)(0x70 | length);
    return length + 1;
}

///
version(mir_ion_test) unittest
{
    import mir.bignum.low_level_view: BigUIntView;

    ubyte[8] data;

    ubyte[] result = [0x72, 0x01, 0xFF];
    // auto id = BigUIntView!(ubyte, WordEndian.big).fromHexString("1FF");
    // assert(data[0 .. ionPutSymbolId(data.ptr, id)] == result);
}

/++
+/
size_t ionPut()(scope ubyte* ptr, scope const(char)[] value)
{
    size_t ret = 1;
    if (value.length < 0xE)
    {
        *ptr = cast(ubyte) (0x80 | value.length);
    }
    else
    {
        *ptr = 0x8E;
        ret += ionPutVarUInt(ptr + 1, value.length);
    }
    if (__ctfe)
        ptr[ret .. ret + value.length] = cast(const(ubyte)[])value;
    else
        memcpy(ptr + ret, value.ptr, value.length);
    return ret + value.length;
}

///
version(mir_ion_test) unittest
{
    ubyte[20] data;

    ubyte[] result = [0x85, 'v', 'a', 'l', 'u', 'e'];
    auto str = "value";
    assert(data[0 .. ionPut(data.ptr, str)] == result);

    result = [ubyte(0x8E), ubyte(0x90)] ~ cast(ubyte[])"hexadecimal23456";
    str = "hexadecimal23456";
    assert(data[0 .. ionPut(data.ptr, str)] == result);
}

/++
+/
size_t joyPut()(scope ubyte* ptr, scope const(char)[] value)
{
    if (__ctfe)
        ptr[0 .. value.length] = cast(const(ubyte)[])value;
    else
        memcpy(ptr, value.ptr, value.length);
    return joyPutEnd(ptr, IonTypeCode.string, value.length);
}

///
@("joyPutString")
version(mir_ion_test) unittest
{
    import mir.test;

    ubyte[20] data;

    ubyte[] result = ['v', 'a', 'l', 'u', 'e', 0x85];
    auto str = "value";
    assert(data[0 .. joyPut(data.ptr, str)] == result);

    result = cast(ubyte[])"hexadecimal23456" ~ [ubyte(0x90), ubyte(0x8E)];
    str = "hexadecimal23456";
    data[0 .. joyPut(data.ptr, str)].should == result;
}

/++
+/
size_t ionPut(T)(scope ubyte* ptr, const T value)
    if (is(T == Clob))
{
    size_t ret = 1;
    if (value.data.length < 0xE)
    {
        *ptr = cast(ubyte) (0x90 | value.data.length);
    }
    else
    {
        *ptr = 0x9E;
        ret += ionPutVarUInt(ptr + 1, value.data.length);
    }
    memcpy(ptr + ret, value.data.ptr, value.data.length);
    return ret + value.data.length;
}

///
version(mir_ion_test) unittest
{
    import mir.lob;

    ubyte[20] data;

    ubyte[] result = [0x95, 'v', 'a', 'l', 'u', 'e'];
    auto str = Clob("value");
    assert(data[0 .. ionPut(data.ptr, str)] == result);

    result = [ubyte(0x9E), ubyte(0x90)] ~ cast(ubyte[])"hexadecimal23456";
    str = Clob("hexadecimal23456");
    assert(data[0 .. ionPut(data.ptr, str)] == result);
}

/++
+/
size_t joyPut(T)(scope ubyte* ptr, const T value)
    if (is(T == Clob))
{
    if (__ctfe)
        ptr[0 .. value.data.length] = cast(const(ubyte)[])value.data;
    else
        memcpy(ptr, value.data.ptr, value.data.length);
    return joyPutEnd(ptr, IonTypeCode.clob, value.data.length);
}

///
@("joyPutCLOB")
version(mir_ion_test) unittest
{
    import mir.lob;

    ubyte[20] data;

    ubyte[] result = ['v', 'a', 'l', 'u', 'e', 0x95];
    auto str = Clob("value");
    assert(data[0 .. joyPut(data.ptr, str)] == result);

    result = cast(ubyte[])"hexadecimal23456" ~ [ubyte(0x90), ubyte(0x9E)] ;
    str = Clob("hexadecimal23456");
    assert(data[0 .. joyPut(data.ptr, str)] == result);
}

/++
+/
size_t ionPut(T)(scope ubyte* ptr, const T value)
    if (is(T == Blob))
{
    size_t ret = 1;
    if (value.data.length < 0xE)
    {
        *ptr = cast(ubyte) (0xA0 | value.data.length);
    }
    else
    {
        *ptr = 0xAE;
        ret += ionPutVarUInt(ptr + 1, value.data.length);
    }
    memcpy(ptr + ret, value.data.ptr, value.data.length);
    return ret + value.data.length;
}

///
version(mir_ion_test) unittest
{
    import mir.lob;

    ubyte[20] data;

    ubyte[] result = [0xA5, 'v', 'a', 'l', 'u', 'e'];
    auto payload = Blob(cast(ubyte[])"value");
    assert(data[0 .. ionPut(data.ptr, payload)] == result);

    result = [ubyte(0xAE), ubyte(0x90)] ~ cast(ubyte[])"hexadecimal23456";
    payload = Blob(cast(ubyte[])"hexadecimal23456");
    assert(data[0 .. ionPut(data.ptr, payload)] == result);
}

/++
+/
size_t joyPut(T)(scope ubyte* ptr, const T value)
    if (is(T == Blob))
{
    if (__ctfe)
        ptr[0 .. value.data.length] = cast(const(ubyte)[])value.data;
    else
        memcpy(ptr, value.data.ptr, value.data.length);
    return joyPutEnd(ptr, IonTypeCode.blob, value.data.length);
}

///
@("joyPutBLOB")
version(mir_ion_test) unittest
{
    import mir.lob;

    ubyte[20] data;

    ubyte[] result = ['v', 'a', 'l', 'u', 'e', 0xA5];
    auto payload = Blob(cast(ubyte[])"value");
    assert(data[0 .. joyPut(data.ptr, payload)] == result);

    result = cast(ubyte[])"hexadecimal23456" ~ [ubyte(0x90), ubyte(0xAE)];
    payload = Blob(cast(ubyte[])"hexadecimal23456");
    assert(data[0 .. joyPut(data.ptr, payload)] == result);
}

/++
+/
size_t ionPutStartLength()()
{
    return 3;
}

/++
+/
size_t ionPutEmpty()(ubyte* startPtr, IonTypeCode tc)
{
    version(LDC) pragma(inline, true);
    assert (tc == IonTypeCode.string || tc == IonTypeCode.list || tc == IonTypeCode.sexp || tc == IonTypeCode.struct_ || tc == IonTypeCode.annotations);
    auto tck = tc << 4;
    *startPtr = cast(ubyte) tck;
    return 1;
}

/++
+/
size_t ionPutEnd()(ubyte* startPtr, IonTypeCode tc, size_t totalElementLength)
{
    version(LDC) pragma(inline, true);
    assert (tc == IonTypeCode.string || tc == IonTypeCode.list || tc == IonTypeCode.sexp || tc == IonTypeCode.struct_ || tc == IonTypeCode.annotations);
    auto tck = tc << 4;
    if (totalElementLength < 0xE)
    {
        *startPtr = cast(ubyte) (tck | totalElementLength);
        if (__ctfe)
            foreach (i; 0 .. totalElementLength)
                startPtr[i + 1] = startPtr[i + 3];
        else
            memmove(startPtr + 1, startPtr + 3, 16);
        debug {
            startPtr[totalElementLength + 1] = 0xFF;
            startPtr[totalElementLength + 2] = 0xFF;
        }
        return 1 + totalElementLength;
    }
    *startPtr = cast(ubyte)(tck | 0xE);
    if (totalElementLength < 0x80)
    {
        startPtr[1] = cast(ubyte) (0x80 | totalElementLength);
        if (__ctfe)
            foreach (i; 0 .. totalElementLength)
                startPtr[i + 2] = startPtr[i + 3];
        else
            memmove(startPtr + 2, startPtr + 3, 128);
        debug {
            startPtr[totalElementLength + 2] = 0xFF;
        }
        return 2 + totalElementLength;
    }
    if (totalElementLength < 0x4000)
    {
        startPtr[1] = cast(ubyte) (totalElementLength >> 7);
        startPtr[2] = cast(ubyte) (totalElementLength | 0x80);
        return 3 + totalElementLength;
    }
    ubyte[19] lengthPayload  = void;
    auto lengthLength = ionPutVarUInt(lengthPayload.ptr, totalElementLength);
    if (__ctfe)
    {
        foreach_reverse (i; 0 .. totalElementLength)
            startPtr[i + 1 + lengthLength] = startPtr[i + 3];
        startPtr[1 .. lengthLength + 1] = lengthPayload[0 .. lengthLength];
    }
    else
    {
        memmove(startPtr + 1 + lengthLength, startPtr + 3, totalElementLength);
        memcpy(startPtr + 1, lengthPayload.ptr, lengthLength);
    }
    return totalElementLength + 1 + lengthLength;
}

///
version(mir_ion_test) unittest
{
    import mir.ion.type_code;

    ubyte[1024] data;
    auto pos = ionPutStartLength;

    ubyte[] result = [0xB0];
    assert(data[0 .. ionPutEnd(data.ptr, IonTypeCode.list, 0)] == result);

    result = [ubyte(0xB6), ubyte(0x85)] ~ cast(ubyte[])"hello";
    auto len = ionPut(data.ptr + pos, "hello");
    assert(data[0 .. ionPutEnd(data.ptr, IonTypeCode.list, len)] == result);

    result = [0xCE, 0x90, 0x8E, 0x8E];
    result ~= cast(ubyte[])"hello world!!!";
    len = ionPut(data.ptr + pos, "hello world!!!");
    assert(data[0 .. ionPutEnd(data.ptr, IonTypeCode.sexp, len)] == result);

    auto bm = `
Generating test runner configuration 'mir-ion-test-library' for 'library' (library).
Performing "unittest" build using /Users/9il/dlang/ldc2/bin/ldc2 for x86_64.
mir-core 1.1.7: target for configuration "library" is up to date.
mir-algorithm 3.9.2: target for configuration "default" is up to date.
mir-cpuid 1.2.6: target for configuration "library" is up to date.
mir-ion 0.5.7+commit.70.g7dcac11: building configuration "mir-ion-test-library"...
Linking...
To force a rebuild of up-to-date targets, run again with --force.
Running ./mir-ion-test-library`;

    result = [0xBE, 0x04, 0xB0, 0x8E, 0x04, 0xAD];
    result ~= cast(ubyte[])bm;
    len = ionPut(data.ptr + pos, bm);
    assert(data[0 .. ionPutEnd(data.ptr, IonTypeCode.list, len)] == result);
}

/++
+/
size_t joyPutEnd()(ubyte* ptr, IonTypeCode tc, size_t length)
{
    version(LDC) pragma(inline, true);
    if (length < 0xE)
    {
        ptr[length] = cast(ubyte) ((tc << 4) | length);
        return length + 1;
    }
    else
    {
        length += joyPutVarUInt(ptr + length, length);
        ptr[length] = cast(ubyte) ((tc << 4) | 0xE);
        return length + 1;
    }
}

///
@("joyPutEnd")
version(mir_ion_test) unittest
{
    import mir.ion.type_code;

    ubyte[1024] data;

    ubyte[] result = [0xB0];
    assert(data[0 .. joyPutEnd(data.ptr, IonTypeCode.list, 0)] == result);

    result = cast(ubyte[])"hello" ~ [ubyte(0x85), ubyte(0xB6)];
    auto len = joyPut(data.ptr, "hello");
    assert(data[0 .. joyPutEnd(data.ptr, IonTypeCode.list, len)] == result);

    result = cast(ubyte[])"hello world!!!";
    result ~= [0x8E, 0x8E, 0x90, 0xCE];
    len = joyPut(data.ptr, "hello world!!!");
    assert(data[0 .. joyPutEnd(data.ptr, IonTypeCode.sexp, len)] == result);

    auto bm = `
Generating test runner configuration 'mir-ion-test-library' for 'library' (library).
Performing "unittest" build using /Users/9il/dlang/ldc2/bin/ldc2 for x86_64.
mir-core 1.1.7: target for configuration "library" is up to date.
mir-algorithm 3.9.2: target for configuration "default" is up to date.
mir-cpuid 1.2.6: target for configuration "library" is up to date.
mir-ion 0.5.7+commit.70.g7dcac11: building configuration "mir-ion-test-library"...
Linking...
To force a rebuild of up-to-date targets, run again with --force.
Running ./mir-ion-test-library`;

    result = cast(ubyte[])bm;
    result ~= [0xAD, 0x04, 0x8E, 0xB0, 0x04, 0xBE];
    len = joyPut(data.ptr, bm);
    assert(data[0 .. joyPutEnd(data.ptr, IonTypeCode.list, len)] == result);
}

/++
+/
size_t ionPutAnnotationsListStartLength()()
{
    return 1;
}

/++
+/
size_t ionPutAnnotationsListEnd()(ubyte* startPtr, size_t totalElementLength)
{
    if (_expect(totalElementLength < 0x80, true))
    {
        startPtr[0] = cast(ubyte) (0x80 | totalElementLength);
        return 1 + totalElementLength;
    }
    else
    {
        ubyte[19] lengthPayload  = void;
        auto lengthLength = ionPutVarUInt(lengthPayload.ptr, totalElementLength);
        if (__ctfe)
        {
            foreach_reverse (i; 0 .. totalElementLength)
                startPtr[lengthLength] = startPtr[i + 1];
            startPtr[0 .. lengthLength] = lengthPayload[0 .. lengthLength];
        }
        else
        {
            memmove(startPtr + lengthLength, startPtr + 1, totalElementLength);
            memcpy(startPtr, lengthPayload.ptr, lengthLength);
        }
        return totalElementLength + lengthLength;
    }
}

///
size_t ionPutEndR(ubyte* ptr, IonTypeCode type, size_t length)
    pure nothrow @nogc
{
    if (length < 0xE)
    {
        *--ptr = cast(ubyte) ((type << 4) | length);
        return 1;
    }
    else
    {
        length = ionPutVarUIntR(ptr, length);
        *(ptr - (length + 1)) = cast(ubyte) ((type << 4) | 0xE);
        return length + 1;
    }
}

///
size_t ionPutVarUIntR(ubyte* ptr, size_t length)
    pure nothrow @nogc
{
    auto safe = ptr;
    do *--ptr = length & 0x7F;
    while (length >>>= 7);
    *(safe - 1) |= 0x80;
    return safe - ptr;
}
