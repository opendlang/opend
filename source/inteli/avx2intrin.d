/**
* AVX2 intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=AVX2
*
* Copyright: Guillaume Piolat 2022.
*            Johan Engelen 2022.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.avx2intrin;

// AVX2 instructions
// https://software.intel.com/sites/landingpage/IntrinsicsGuide/#techs=AVX2
// Note: this header will work whether you have AVX2 enabled or not.
// With LDC, use "dflags-ldc": ["-mattr=+avx2"] or equivalent to actively
// generate AVX2 instructions.

public import inteli.types;
import inteli.internals;

// Pull in all previous instruction set intrinsics.
public import inteli.avxintrin;

nothrow @nogc:

/// Add packed 32-bit integers in `a` and `b`.
__m256i _mm256_add_epi32(__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return cast(__m256i)(cast(int8)a + cast(int8)b);
}
unittest
{
    __m256i A = _mm256_setr_epi32( -7, -1, 0, 9, -100, 100, 234, 432);
    int8 R = _mm256_add_epi32(A, A);
    int[8] correct = [ -14, -2, 0, 18, -200, 200, 468, 864 ];
    assert(R.array == correct);
}

/// Compute the bitwise AND of 256 bits (representing integer data) in `a` and `b`.
__m256i _mm256_and_si256 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return a & b;
}
unittest
{
    __m256i A = _mm256_set1_epi32(7);
    __m256i B = _mm256_set1_epi32(14);
    __m256i R = _mm256_and_si256(A, B);
    int[8] correct = [6, 6, 6, 6, 6, 6, 6, 6];
    assert(R.array == correct);
}

/// Zero-extend packed unsigned 16-bit integers in `a` to packed 32-bit integers.
__m256i _mm256_cvtepu16_epi32(__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovzxwd256(cast(short8)a);
    }
    else
    {
        short8 sa = cast(short8)a;
        int8 r;
        // Explicit cast to unsigned to get *zero* extension (instead of sign extension).
        r.ptr[0] = cast(ushort)sa.array[0];
        r.ptr[1] = cast(ushort)sa.array[1];
        r.ptr[2] = cast(ushort)sa.array[2];
        r.ptr[3] = cast(ushort)sa.array[3];
        r.ptr[4] = cast(ushort)sa.array[4];
        r.ptr[5] = cast(ushort)sa.array[5];
        r.ptr[6] = cast(ushort)sa.array[6];
        r.ptr[7] = cast(ushort)sa.array[7];
        return cast(__m256i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-1, 0, -32768, 32767, -1, 0, -32768, 32767);
    int8 C = cast(int8) _mm256_cvtepu16_epi32(A);
    int[8] correct = [65535, 0, 32768, 32767, 65535, 0, 32768, 32767];
    assert(C.array == correct);
}

/// Extract 128 bits (composed of integer data) from `a`, selected with `imm8`.
__m128i _mm256_extracti128_si256(int imm8)(__m256i a) pure @trusted
    if ( (imm8 == 0) || (imm8 == 1) )
{
    pragma(inline, true);

    static if (GDC_with_AVX2)
    {
        return cast(__m128i) __builtin_ia32_extract128i256(a, imm8);
    }
    else version (LDC)
    {
        enum str = (imm8 == 1) ? "<i32 2, i32 3>" : "<i32 0, i32 1>";
        enum ir = "%r = shufflevector <4 x i64> %0, <4 x i64> undef, <2 x i32>" ~ str ~ "\n" ~
                  "ret <2 x i64> %r";
        return cast(__m128i) LDCInlineIR!(ir, ulong2, ulong4)(cast(ulong4)a);
    }
    else
    {
        long2 ret;
        ret.ptr[0] = (imm8==1) ? a.array[2] : a.array[0];
        ret.ptr[1] = (imm8==1) ? a.array[3] : a.array[1];
        return cast(__m128i) ret;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32( -7, -1, 0, 9, -100, 100, 234, 432 );
    int[4] correct0 = [ -7, -1, 0, 9 ];
    int[4] correct1 = [ -100, 100, 234, 432 ];
    __m128i R0 = _mm256_extracti128_si256!(0)(A);
    __m128i R1 = _mm256_extracti128_si256!(1)(A);
    assert(R0.array == correct0);
    assert(R1.array == correct1);
}

/// Multiply packed signed 16-bit integers in `a` and `b`, producing intermediate
/// signed 32-bit integers. Horizontally add adjacent pairs of intermediate 32-bit integers,
/// and pack the results in destination.
__m256i _mm256_madd_epi16 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmaddwd256(cast(short16)a, cast(short16)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmaddwd256(cast(short16)a, cast(short16)b);
    }
    else
    {
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        int8 r;
        foreach(i; 0..8)
        {
            r.ptr[i] = sa.array[2*i] * sb.array[2*i] + sa.array[2*i+1] * sb.array[2*i+1];
        }
        return r;
    }
}
unittest
{
    short16 A = [0, 1, 2, 3, -32768, -32768, 32767, 32767, 0, 1, 2, 3, -32768, -32768, 32767, 32767];
    short16 B = [0, 1, 2, 3, -32768, -32768, 32767, 32767, 0, 1, 2, 3, -32768, -32768, 32767, 32767];
    int8 R = _mm256_madd_epi16(cast(__m256i)A, cast(__m256i)B);
    int[8] correct = [1, 13, -2147483648, 2*32767*32767, 1, 13, -2147483648, 2*32767*32767];
    assert(R.array == correct);
}

/// Compute the bitwise OR of 256 bits (representing integer data) in `a` and `b`.
__m256i _mm256_or_si256 (__m256i a, __m256i b) pure @safe
{
    return a | b;
}
// TODO unittest and thus force inline

/// Compute the absolute differences of packed unsigned 8-bit integers in `a` and `b`, then horizontally sum each
/// consecutive 8 differences to produce two unsigned 16-bit integers, and pack these unsigned 16-bit integers in the
/// low 16 bits of 64-bit elements in result.
__m256i _mm256_sad_epu8 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psadbw256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psadbw256(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        // PERF: ARM64/32 is lacking
        byte32 ab = cast(byte32)a;
        byte32 bb = cast(byte32)b;
        ubyte[32] t;
        foreach(i; 0..32)
        {
            int diff = cast(ubyte)(ab.array[i]) - cast(ubyte)(bb.array[i]);
            if (diff < 0) diff = -diff;
            t[i] = cast(ubyte)(diff);
        }
        int8 r = _mm256_setzero_si256();
        r.ptr[0] = t[0]  + t[1]  + t[2]  + t[3]  + t[4]  + t[5]  + t[6]  + t[7];
        r.ptr[2] = t[8]  + t[9]  + t[10] + t[11] + t[12] + t[13] + t[14] + t[15];
        r.ptr[4] = t[16] + t[17] + t[18] + t[19] + t[20] + t[21] + t[22] + t[23];
        r.ptr[6] = t[24] + t[25] + t[26] + t[27] + t[28] + t[29] + t[30] + t[31];
        return r;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi8(3, 4, 6, 8, 12, 14, 18, 20, 24, 30, 32, 38, 42, 44, 48, 54,
                              3, 4, 6, 8, 12, 14, 18, 20, 24, 30, 32, 38, 42, 44, 48, 54); // primes + 1
    __m256i B = _mm256_set1_epi8(1);
    __m256i R = _mm256_sad_epu8(A, B);
    int[8] correct = [2 + 3 + 5 + 7 + 11 + 13 + 17 + 19,
                      0,
                      23 + 29 + 31 + 37 + 41 + 43 + 47 + 53,
                      0,
                      2 + 3 + 5 + 7 + 11 + 13 + 17 + 19,
                      0,
                      23 + 29 + 31 + 37 + 41 + 43 + 47 + 53,
                      0];
    assert(R.array == correct);
}

/// Shift packed 16-bit integers in `a` left by `imm8` while shifting in zeros.
__m256i _mm256_slli_epi16(__m256i a, int imm8) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psllwi256(cast(short16)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psllwi256(cast(short16)a, cast(ubyte)imm8);
    }
    else
    {
        //PERF: ARM
        short16 sa  = cast(short16)a;
        short16 r   = cast(short16)_mm256_setzero_si256();
        ubyte count = cast(ubyte) imm8;
        if (count > 15)
            return cast(__m256i)r;
        foreach(i; 0..16)
            r.ptr[i] = cast(short)(sa.array[i] << count);
        return cast(__m256i)r;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7, 0, 1, 2, 3, -4, -5, 6, 7);
    short16 B = cast(short16)( _mm256_slli_epi16(A, 1) );
    short16 B2 = cast(short16)( _mm256_slli_epi16(A, 1 + 256) );
    short[16] expectedB = [ 0, 2, 4, 6, -8, -10, 12, 14, 0, 2, 4, 6, -8, -10, 12, 14 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    short16 C = cast(short16)( _mm256_slli_epi16(A, 16) );
    short[16] expectedC = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(C.array == expectedC);
}

/// Shift packed 32-bit integers in `a` left by `imm8` while shifting in zeros.
__m256i _mm256_slli_epi32 (__m256i a, int imm8) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return __builtin_ia32_pslldi256(a, cast(ubyte)imm8);
    }
    else static if (LDC_with_AVX2)
    {
        return __builtin_ia32_pslldi256(a, cast(ubyte)imm8);
    }
    else
    {
        // Note: the intrinsics guarantee imm8[0..7] is taken, however
        //       D says "It's illegal to shift by the same or more bits
        //       than the size of the quantity being shifted"
        //       and it's UB instead.
        int8 r = _mm256_setzero_si256();

        ubyte count = cast(ubyte) imm8;
        if (count > 31)
            return r;

        foreach(i; 0..8)
            r.array[i] = cast(uint)(a.array[i]) << count;
        return r;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, 2, 3, -4, 0, 2, 3, -4);
    __m256i B = _mm256_slli_epi32(A, 1);
    __m256i B2 = _mm256_slli_epi32(A, 1 + 256);
    int[8] expectedB = [ 0, 4, 6, -8, 0, 4, 6, -8 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    __m256i C = _mm256_slli_epi32(A, 0);
    int[8] expectedC = [ 0, 2, 3, -4, 0, 2, 3, -4 ];
    assert(C.array == expectedC);

    __m256i D = _mm256_slli_epi32(A, 65);
    int[8] expectedD = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(D.array == expectedD);
}

/// Shift packed 16-bit integers in `a` right by `imm8` while shifting in zeros.
__m256i _mm256_srli_epi16 (__m256i a, int imm8) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrlwi256(cast(short16)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrlwi256(cast(short16)a, cast(ubyte)imm8);
    }
    else
    {
        //PERF: ARM
        short16 sa  = cast(short16)a;
        ubyte count = cast(ubyte)imm8;
        short16 r   = cast(short16) _mm256_setzero_si256();
        if (count >= 16)
            return cast(__m256i)r;

        foreach(i; 0..16)
            r.array[i] = cast(short)(cast(ushort)(sa.array[i]) >> count);
        return cast(__m256i)r;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7, 0, 1, 2, 3, -4, -5, 6, 7);
    short16 B = cast(short16)( _mm256_srli_epi16(A, 1) );
    short16 B2 = cast(short16)( _mm256_srli_epi16(A, 1 + 256) );
    short[16] expectedB = [ 0, 0, 1, 1, 0x7FFE, 0x7FFD, 3, 3, 0, 0, 1, 1, 0x7FFE, 0x7FFD, 3, 3 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    short16 C = cast(short16)( _mm256_srli_epi16(A, 16) );
    short[16] expectedC = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(C.array == expectedC);

    short16 D = cast(short16)( _mm256_srli_epi16(A, 0) );
    short[16] expectedD = [ 0, 1, 2, 3, -4, -5, 6, 7, 0, 1, 2, 3, -4, -5, 6, 7 ];
    assert(D.array == expectedD);
}

/// Shift packed 32-bit integers in `a` right by `imm8` while shifting in zeros.
__m256i _mm256_srli_epi32 (__m256i a, int imm8) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return __builtin_ia32_psrldi256(a, cast(ubyte)imm8);
    }
    else static if (LDC_with_AVX2)
    {
        return __builtin_ia32_psrldi256(a, cast(ubyte)imm8);
    }
    else
    {
        ubyte count = cast(ubyte) imm8;

        // Note: the intrinsics guarantee imm8[0..7] is taken, however
        //       D says "It's illegal to shift by the same or more bits
        //       than the size of the quantity being shifted"
        //       and it's UB instead.
        int8 r = _mm256_setzero_si256();
        if (count >= 32)
            return r;
        r.ptr[0] = a.array[0] >>> count;
        r.ptr[1] = a.array[1] >>> count;
        r.ptr[2] = a.array[2] >>> count;
        r.ptr[3] = a.array[3] >>> count;
        r.ptr[4] = a.array[4] >>> count;
        r.ptr[5] = a.array[5] >>> count;
        r.ptr[6] = a.array[6] >>> count;
        r.ptr[7] = a.array[7] >>> count;
        return r;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, 2, 3, -4, 0, 2, 3, -4);
    __m256i B = _mm256_srli_epi32(A, 1);
    __m256i B2 = _mm256_srli_epi32(A, 1 + 256);
    int[8] expectedB = [ 0, 1, 1, 0x7FFFFFFE, 0, 1, 1, 0x7FFFFFFE];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    __m256i C = _mm256_srli_epi32(A, 255);
    int[8] expectedC = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(C.array == expectedC);
}

/// Compute the bitwise XOR of 256 bits (representing integer data) in `a` and `b`.
__m256i _mm256_xor_si256 (__m256i a, __m256i b) pure @safe
{
    return a ^ b;
}
// TODO unittest and thus force inline

