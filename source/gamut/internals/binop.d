/**
Just plain functions for reading and writing binary streams, without templates now.

Copyright: Copyright Guillaume Piolat 2015-2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.internals.binop;

pure nothrow @nogc @system:

// Those functions takes a pointer and update it.
// Image codecs are choke full of these sort of functions.
// No checks, you must check elsewhere that there is no overflow.
//
// All those functions take a ubyte* buffer.

version(LittleEndian)
{}
else
{
    static assert(false); // adapt this file
}

/// Skip bytes, this is for semantic purpose.
void skip_bytes(ref inout(ubyte)* bytes, int toSkip)
{
    bytes += toSkip;
}

//
// Bytes (8-bit read and writes)
//

/// Read a `byte`.
byte read_byte(ref inout(ubyte)* s)
{
    return *s++;
}

/// Read a `ubyte`.
ubyte read_ubyte(ref inout(ubyte)* s)
{
    return *s++;
}

/// Write a `byte`.
void write_byte(ref ubyte* s, byte v)
{
    *s++ = v;
}

/// Write a `ubyte`.
void write_ubyte(ref ubyte* s, ubyte v)
{
     *s++ = v;
}

//
// Shorts (16-bit read and writes)
//

/// Read a Little Endian `short`.
short read_short_LE(ref inout(ubyte)* s)
{
    return cast(short) read_ushort_LE(s);
}

/// Read a Little Endian `ushort`.
ushort read_ushort_LE(ref inout(ubyte)* s) 
{
    ushort v = *cast(ushort*)s;
    s += 2;
    return v;
}

/// Write a Little Endian `short`.
void write_short_LE(ref ubyte* s, short v) 
{
    write_ushort_LE(s, v);
}

/// Write a Little Endian `ushort`.
void write_ushort_LE(ref ubyte* s, ushort v) 
{
    *cast(ushort*)s = v;
    s += 2;
}

/// Read a Big Endian `short`.
short read_short_BE(ref inout(ubyte)* s)
{
    return read_ushort_BE(s);
}

/// Read a Big Endian `ushort`.
ushort read_ushort_BE(ref inout(ubyte)* s)
{
    ubyte a = *s++;
    ubyte b = *s++;
    return a << 8 | b;
}

/// Write a Big Endian `short`.
void write_short_BE(ref ubyte* s, short v) 
{
    write_ushort_BE(s, v);
}

/// Write a Big Endian `ushort`.
void write_ushort_BE(ref ubyte* s, ushort v) 
{
    *s++ = (0xff00 & v) >> 8;
    *s++ = (0x00ff & v);
}

//
// Ints (32-bit read and writes)
//

/// Read a Little Endian `int`.
int read_int_LE(ref inout(ubyte)* s)
{
    return read_uint_LE(s);
}

/// Read a Little Endian `uint`.
uint read_uint_LE(ref inout(ubyte)* s) 
{
    uint v = *cast(uint*)s;
    s += uint.sizeof;
    return v;
}

/// Write a Little Endian `int`.
void write_int_LE(ref ubyte* s, int v) 
{
    write_uint_LE(s, v);
}

/// Write a Little Endian `uint`.
void write_uint_LE(ref ubyte* s, uint v) 
{
    *cast(uint*)s = v;
    s += uint.sizeof;
}

/// Read a Big Endian `int`.
int read_int_BE(ref inout(ubyte)* s) 
{
    return read_uint_BE(s);
}

/// Read a Big Endian `uint`.
uint read_uint_BE(ref inout(ubyte)* s)
{
    ubyte a = *s++;
    ubyte b = *s++;
    ubyte c = *s++;
    ubyte d = *s++;
    return a << 24 | b << 16 | c << 8 | d;
}

/// Write a Big Endian `int`.
void write_int_BE(ref ubyte* s, int v) 
{
    write_uint_BE(s, v);
}

/// Write a Big Endian `uint`.
void write_uint_BE(ref ubyte* s, uint v) 
{
    *s++ = (0xff000000 & v) >> 24;
    *s++ = (0x00ff0000 & v) >> 16;
    *s++ = (0x0000ff00 & v) >> 8;
    *s++ = (0x000000ff & v);
}

//
// Long (64-bit read and writes)
//

/// Read a Little Endian `long`.
long read_long_LE(ref inout(ubyte)* s)
{
    return read_ulong_LE(s);
}

/// Read a Little Endian `ulong`.
ulong read_ulong_LE(ref inout(ubyte)* s) 
{
    ulong v = *cast(ulong*)s;
    s += ulong.sizeof;
    return v;
}

/// Write a Little Endian `long`.
void write_long_LE(ref ubyte* s, long v) 
{
    write_ulong_LE(s, v);
}

/// Write a Little Endian `ulong`.
void write_ulong_LE(ref ubyte* s, ulong v) 
{
    *cast(ulong*)s = v;
    s += ulong.sizeof;
}

/// Read a Big Endian `long`.
long read_long_BE(ref inout(ubyte)* s) 
{
    return read_ulong_BE(s);
}

/// Read a Big Endian `ulong`.
ulong read_ulong_BE(ref inout(ubyte)* s)
{
    ulong r = 0;
    foreach(n; 0..8)
    {
        r = (r << 8) | *s++;
    }
    return r;
}

/// Write a Big Endian `long`.
void write_long_BE(ref ubyte* s, long v) 
{
    write_ulong_BE(s, v);
}

/// Write a Big Endian `uint`.
void write_ulong_BE(ref ubyte* s, ulong v) 
{
    *s++ = (0xff00000000000000 & v) >> 56;
    *s++ = (0x00ff000000000000 & v) >> 48;
    *s++ = (0x0000ff0000000000 & v) >> 40;
    *s++ = (0x000000ff00000000 & v) >> 32;
    *s++ = (0x00000000ff000000 & v) >> 24;
    *s++ = (0x0000000000ff0000 & v) >> 16;
    *s++ = (0x000000000000ff00 & v) >> 8;
    *s++ = (0x00000000000000ff & v);
}

//
// Float (32-bit FP) read and write.
//

/// Read a Little Endian `float`.
float read_float_LE(ref inout(ubyte)* s)
{
    uint u = read_uint_LE(s);
    return *cast(float*)&u;
}

/// Write a Little Endian `float`.
void write_float_LE(ref ubyte* s, float v) 
{
    write_uint_LE(s, *cast(uint*)&v);
}

/// Read a Big Endian `float`.
float read_float_BE(ref inout(ubyte)* s)
{
    uint u = read_uint_BE(s);
    return *cast(float*)&u;
}

/// Write a Big Endian `float`.
void write_float_BE(ref ubyte* s, float v) 
{
    write_uint_BE(s, *cast(uint*)&v);
}

//
// Double (64-bit FP) read and write.
//

/// Read a Little Endian `double`.
double read_double_LE(ref inout(ubyte)* s)
{
    ulong u = read_ulong_LE(s);
    return *cast(double*)&u;
}

/// Write a Little Endian `float`.
void write_double_LE(ref ubyte* s, double v) 
{
    write_ulong_LE(s, *cast(ulong*)&v);
}

/// Read a Big Endian `float`.
double read_double_BE(ref inout(ubyte)* s)
{
    ulong u = read_ulong_BE(s);
    return *cast(double*)&u;
}

/// Write a Big Endian `float`.
void write_double_BE(ref ubyte* s, double v) 
{
    write_ulong_BE(s, *cast(ulong*)&v);
}


unittest
{
    ubyte[10] arr = [ 0x00, 0x01, 0x02, 0x03 ,
                      0x00, 0x01, 0x02, 0x03,
                      0x04, 0x05 ];
    ubyte* pRead = arr.ptr;

    assert(read_uint_LE(pRead) == 0x03020100);
    assert(read_int_BE(pRead) == 0x00010203);
    assert(read_short_BE(pRead) == 0x0405);

    import std.array;
    ubyte[4 + 8 + 2] arr2;
    ubyte* pWrite = arr2.ptr;
    write_float_BE(pWrite, 1.0f);
    write_double_LE(pWrite, 2.0);
    write_short_LE(pWrite, 2);
}

unittest
{
    ubyte[8] arr = [0, 0, 0, 0, 0, 0, 0xe0, 0x3f];

    ubyte* p = arr.ptr;
    assert(read_double_LE(p) == 0.5);

    arr = [0, 0, 0, 0, 0, 0, 0xe0, 0xbf];
    p = arr.ptr;
    assert(read_double_LE(p) == -0.5);
}
