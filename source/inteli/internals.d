/**
* Copyright: Copyright Auburn Sounds 2016-2018.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.internals;

version(LDC)
{
    public import core.simd;
    public import ldc.simd;
    public import ldc.gccbuiltins_x86;
    public import ldc.intrinsics;
}

import inteli.types;
import core.stdc.stdio;

package:
nothrow @nogc:

// using the Intel terminology here

byte saturateSignedWordToSignedByte(short value) pure @safe
{
    if (value > 127) value = 127;
    if (value < -128) value = -128;
    return cast(byte) value;
}

ubyte saturateSignedWordToUnsignedByte(short value) pure @safe
{
    if (value > 255) value = 255;
    if (value < 0) value = 0;
    return cast(ubyte) value;
}

short saturateSignedIntToSignedShort(int value) pure @safe
{
    if (value > 32767) value = 32767;
    if (value < -32768) value = -32768;
    return cast(short) value;
}

ushort saturateSignedIntToUnsignedShort(int value) pure @safe
{
    if (value > 65535) value = 65535;
    if (value < 0) value = 0;
    return cast(ushort) value;
}

unittest // test saturate operations
{
    assert( saturateSignedWordToSignedByte(32000) == 127);
    assert( saturateSignedWordToUnsignedByte(32000) == 255);
    assert( saturateSignedWordToSignedByte(-4000) == -128);
    assert( saturateSignedWordToUnsignedByte(-4000) == 0);
    assert( saturateSignedIntToSignedShort(32768) == 32767);
    assert( saturateSignedIntToUnsignedShort(32768) == 32768);
    assert( saturateSignedIntToSignedShort(-32769) == -32768);
    assert( saturateSignedIntToUnsignedShort(-32769) == 0);
}


// printing vectors for implementation
// Note: you can override `pure` within a `debug` clause
void _mm_print_epi32(__m128i v) @trusted
{
    printf("%d %d %d %d\n",
          v[0], v[1], v[2], v[3]);
}

void _mm_print_epi16(__m128i v) @trusted
{
    short8 C = cast(short8)v;
    printf("%d %d %d %d %d %d %d %d\n",
    C[0], C[1], C[2], C[3], C[4], C[5], C[6], C[7]);
}

void _mm_print_epi8(__m128i v) @trusted
{
    byte16 C = cast(byte16)v;
    printf("%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
    C[0], C[1], C[2], C[3], C[4], C[5], C[6], C[7], C[8], C[9], C[10], C[11], C[12], C[13], C[14], C[15]);
}
