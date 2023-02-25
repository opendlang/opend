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
// With GDC, use "dflags-gdc": ["-mavx2"] or equivalent to actively
// generate AVX2 instructions.

public import inteli.types;
import inteli.internals;

// Pull in all previous instruction set intrinsics.
public import inteli.avxintrin;

nothrow @nogc:

/// Compute the absolute value of packed signed 16-bit integers in `a`.
__m256i _mm256_abs_epi16 (__m256i a) @trusted
{
    // PERF DMD
    version(LDC)
        enum split = true; // akways beneficial in LDC neon, ssse3, or even sse2
    else
        enum split = GDC_with_SSSE3;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pabsw256(cast(short16)a);
    }
    else static if (__VERSION__ >= 2097 && LDC_with_AVX2)
    {
        // Before LDC 1.27 llvm.abs LLVM intrinsic didn't exist, and hence 
        // no good way to do abs(256-bit)
        return cast(__m256i) inteli_llvm_abs!short16(cast(short16)a, false);
    }    
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_abs_epi16(a_lo);
        __m128i r_hi = _mm_abs_epi16(a_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }    
    else
    {        
        short16 sa = cast(short16)a;
        for (int i = 0; i < 16; ++i)
        {
            short s = sa.array[i];
            sa.ptr[i] = s >= 0 ? s : cast(short)(-cast(int)(s));
        }  
        return cast(__m256i)sa;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(0, -1, -32768, 32767, 10, -10, 1000, -1000,
                                  1, -1, -32768, 32767, 12, -13, 1000, -1040);
    short16 B = cast(short16) _mm256_abs_epi16(A);
    short[16] correct = [0, 1, -32768, 32767, 10, 10, 1000, 1000,
                         1, 1, -32768, 32767, 12, 13, 1000, 1040];
    assert(B.array == correct);
}

/// Compute the absolute value of packed signed 32-bit integers in `a`.
__m256i _mm256_abs_epi32 (__m256i a) @trusted
{
    // PERF DMD
    version(LDC)
        enum split = true; // always beneficial in LDC neon, ssse3, or even sse2
    else
        enum split = false; // GDC manages to split and use pabsd in SSSE3 without guidance

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pabsd256(cast(int8)a);
    }
    else static if (__VERSION__ >= 2097 && LDC_with_AVX2)
    {
        // Before LDC 1.27 llvm.abs LLVM intrinsic didn't exist, and hence 
        // no good way to do abs(256-bit)
        return cast(__m256i) inteli_llvm_abs!int8(cast(int8)a, false);
    }
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_abs_epi32(a_lo);
        __m128i r_hi = _mm_abs_epi32(a_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else
    {
        int8 sa = cast(int8)a;
        for (int i = 0; i < 8; ++i)
        {
            int s = sa.array[i];
            sa.ptr[i] = (s >= 0 ? s : -s);
        }
        return cast(__m256i)sa;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, -1, -2_147_483_648, -2_147_483_647, -1, 0, -2_147_483_648, -2_147_483_646);
    int8 B = cast(int8) _mm256_abs_epi32(A);
    int[8] correct = [0, 1, -2_147_483_648, 2_147_483_647, 1, 0, -2_147_483_648, 2_147_483_646];
    assert(B.array == correct);
}

/// Compute the absolute value of packed signed 8-bit integers in `a`.
__m256i _mm256_abs_epi8 (__m256i a) @trusted
{
    // PERF DMD
    // PERF GDC in SSSE3 to AVX doesn't use pabsb and split is catastrophic because of _mm_min_epu8
    version(LDC)
        enum split = true; // akways beneficial in LDC neon, ssse3, sse2
    else
        enum split = false;

    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pabsb256(cast(ubyte32)a);
    }
    else static if (__VERSION__ >= 2097 && LDC_with_AVX2)
    {
        // Before LDC 1.27 llvm.abs LLVM intrinsic didn't exist, and hence 
        // no good way to do abs(256-bit)
        return cast(__m256i) inteli_llvm_abs!byte32(cast(byte32)a, false);
    }
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i r_lo = _mm_abs_epi8(a_lo);
        __m128i r_hi = _mm_abs_epi8(a_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else
    {
        // Basically this loop is poison for LDC optimizer
        byte32 sa = cast(byte32)a;
        for (int i = 0; i < 32; ++i)
        {
            byte s = sa.array[i];
            sa.ptr[i] = s >= 0 ? s : cast(byte)(-cast(int)(s));
        }
        return cast(__m256i)sa;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi8(0, -1, -128, -127, 127,  0,  0,  0,  0,  0, 0, 0, 0, 0, 0, 0,
                                 0, -1, -128, -126, 127, -6, -5, -4, -3, -2, 0, 1, 2, 3, 4, 5);
    byte32 B = cast(byte32) _mm256_abs_epi8(A);
    byte[32] correct =          [0,  1, -128,  127, 127,  0,  0,  0,  0,  0, 0, 0, 0, 0, 0, 0,
                                 0,  1, -128,  126, 127,  6,  5,  4,  3,  2, 0, 1, 2, 3, 4, 5];
    assert(B.array == correct);
}

/// Add packed 16-bit integers in `a` and `b`.
__m256i _mm256_add_epi16 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return cast(__m256i)(cast(short16)a + cast(short16)b);
}
unittest
{
    __m256i A = _mm256_setr_epi16( -7, -1, 0, 9, -100, 100, 234, 432, -32768, 32767, 0, -1, -20000, 0,  6, -2);
    short16 R = cast(short16) _mm256_add_epi16(A, A);
    short[16] correct         = [ -14, -2, 0, 18, -200, 200, 468, 864,     0,    -2, 0, -2,  25536, 0, 12, -4 ];
    assert(R.array == correct);
}

/// Add packed 32-bit integers in `a` and `b`.
__m256i _mm256_add_epi32(__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return cast(__m256i)(cast(int8)a + cast(int8)b);
}
unittest
{
    __m256i A = _mm256_setr_epi32( -7, -1, 0, 9, -100, 100, 234, 432);
    int8 R = cast(int8) _mm256_add_epi32(A, A);
    int[8] correct = [ -14, -2, 0, 18, -200, 200, 468, 864 ];
    assert(R.array == correct);
}

/// Add packed 64-bit integers in `a` and `b`.
__m256i _mm256_add_epi64 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return a + b;
}
unittest
{
    __m256i A = _mm256_setr_epi64(-1, 0x8000_0000_0000_0000, 42, -12);
    long4 R = cast(__m256i) _mm256_add_epi64(A, A);
    long[4] correct = [ -2, 0, 84, -24 ];
    assert(R.array == correct);
}

/// Add packed 8-bit integers in `a` and `b`.
__m256i _mm256_add_epi8 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return cast(__m256i)(cast(byte32)a + cast(byte32)b);
}
unittest
{
    __m256i A = _mm256_setr_epi8(4, 8, 13, -7, -1, 0, 9, 77, 4, 8, 13, -7, -1, 0, 9, 78,
                                 4, 9, 13, -7, -1, 0, 9, 77, 4, 8, 13, -7, -2, 0, 10, 78);
    byte32 R = cast(byte32) _mm256_add_epi8(A, A);
    byte[32] correct = [8, 16, 26, -14, -2, 0, 18, -102, 8, 16, 26, -14, -2, 0, 18, -100,
                        8, 18, 26, -14, -2, 0, 18, -102, 8, 16, 26, -14, -4, 0, 20, -100];
    assert(R.array == correct);
}

/// Add packed 16-bit signed integers in `a` and `b` using signed saturation.
__m256i _mm256_adds_epi16 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_paddsw256(cast(short16)a, cast(short16)b);
    }
    else version(LDC)
    {
        return cast(__m256i) inteli_llvm_adds!short16(cast(short16)a, cast(short16)b);
    }
    else
    {
        short16 r;
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        foreach(i; 0..16)
            r.ptr[i] = saturateSignedIntToSignedShort(sa.array[i] + sb.array[i]);
        return cast(__m256i)r;
    }
}
unittest
{
    short16 res = cast(short16) _mm256_adds_epi16(_mm256_setr_epi16( 7,  6,  5, -32768, 3, 3, 32767,   0,  7,  6,  5, -32768, 3, 3, 32767,   0),
                                                  _mm256_setr_epi16( 7,  6,  5, -30000, 3, 1,     1, -10,  7,  6,  5, -30000, 3, 1,     1, -10));
    static immutable short[16] correctResult                    =  [14, 12, 10, -32768, 6, 4, 32767, -10, 14, 12, 10, -32768, 6, 4, 32767, -10];
    assert(res.array == correctResult);
}

/// Add packed 8-bit signed integers in `a` and `b` using signed saturation.
__m256i _mm256_adds_epi8 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_paddsb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else version(LDC)
    {
        return cast(__m256i) inteli_llvm_adds!byte32(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        byte32 r;
        byte32 sa = cast(byte32)a;
        byte32 sb = cast(byte32)b;
        foreach(i; 0..32)
            r.ptr[i] = saturateSignedWordToSignedByte(sa.array[i] + sb.array[i]);
        return cast(__m256i)r;
    }
}
unittest
{
    byte32 res = cast(byte32) _mm256_adds_epi8(_mm256_setr_epi8(15, 14, 13, 12, 11, 127, 9, 8, 7, 6, 5, -128, 3, 2, 1, 0, 15, 14, 13, 12, 11, 127, 9, 8, 7, 6, 5, -128, 3, 2, 1, 0),
                                               _mm256_setr_epi8(15, 14, 13, 12, 11,  10, 9, 8, 7, 6, 5,   -4, 3, 2, 1, 0, 15, 14, 13, 12, 11,  10, 9, 8, 7, 6, 5,   -4, 3, 2, 1, 0));
    static immutable byte[32] correctResult                  = [30, 28, 26, 24, 22, 127,18,16,14,12,10, -128, 6, 4, 2, 0, 30, 28, 26, 24, 22, 127,18,16,14,12,10, -128, 6, 4, 2, 0]; 
    assert(res.array == correctResult);
}

/// Add packed 16-bit unsigned integers in `a` and `b` using unsigned saturation.
__m256i _mm256_adds_epu16 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_paddusw256(cast(short16)a, cast(short16)b);
    }
    else version(LDC)
    {
        return cast(__m256i) inteli_llvm_addus!short16(cast(short16)a, cast(short16)b);
    }
    else
    {
        short16 r;
        short16 sa = cast(short16)a;
        short16 sb = cast(short16)b;
        foreach(i; 0..16)
            r.ptr[i] = saturateSignedIntToUnsignedShort(cast(ushort)(sa.array[i]) + cast(ushort)(sb.array[i]));
        return cast(__m256i)r;
    }
}
unittest
{
    short16 res = cast(short16) _mm256_adds_epu16(_mm256_set_epi16(3, 2, cast(short)65535, 0, 3, 2, cast(short)65535, 0, 3, 2, cast(short)65535, 0, 3, 2, cast(short)65535, 0),
                                             _mm256_set_epi16(3, 2, 1, 0, 3, 2, 1, 0, 3, 2, 1, 0, 3, 2, 1, 0));
    static immutable short[16] correctResult = [0, cast(short)65535, 4, 6, 0, cast(short)65535, 4, 6, 0, cast(short)65535, 4, 6, 0, cast(short)65535, 4, 6];
    assert(res.array == correctResult);
}

/// Add packed 8-bit unsigned integers in `a` and `b` using unsigned saturation.
__m256i _mm256_adds_epu8 (__m256i a, __m256i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_paddusb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else version(LDC)
    {
        return cast(__m256i) inteli_llvm_addus!byte32(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        byte32 r;
        byte32 sa = cast(byte32)a;
        byte32 sb = cast(byte32)b;
        foreach(i; 0..32)
            r.ptr[i] = saturateSignedWordToUnsignedByte(cast(ubyte)(sa.array[i]) + cast(ubyte)(sb.array[i]));
        return cast(__m256i)r;
    }
}
unittest
{
    __m256i A          = _mm256_setr_epi8(0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)255, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)136, 0, 0, 0, cast(byte)136, 0, 0, 0, 0, 0, 0);
    __m256i B          = _mm256_setr_epi8(0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0,             1, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)136, 0, 0, 0,            40, 0, 0, 0, 0, 0, 0);
    byte32 R = cast(byte32) _mm256_adds_epu8(A, B);
    static immutable byte[32] correct =  [0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)255, 0, 0, 0, 0, 0, 0, 0, 0, cast(byte)255, 0, 0, 0, cast(byte)176, 0, 0, 0, 0, 0, 0];
    assert(R.array == correct);
}

/// Concatenate pairs of 16-byte blocks in `a` and `b` into a 32-byte temporary result, shift the 
/// result right by `imm8` bytes, and return the low 16 bytes of that in each lane.
__m256i _mm256_alignr_epi8(ubyte count)(__m256i a, __m256i b) pure @trusted
{

    // PERF DMD
    static if (GDC_with_AVX2)
    {
        return cast(__m256i)__builtin_ia32_palignr256(a, b, count * 8);
    }
    else
    {
        // Note that palignr 256-bit does the same as palignr 128-bit by lane. Can split.
        // With LDC 1.24 + avx2 feature + -02, that correctly gives a AVX2 vpalignr despite being split.
        // I guess we could do it with a big 32-items shufflevector but not sure if best.
        // 2 inst on ARM64 neon, which is optimal.
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_alignr_epi8!count(a_lo, b_lo);
        __m128i r_hi = _mm_alignr_epi8!count(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);   
    }
}
unittest
{
    __m128i A = _mm_setr_epi8( 1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16);
    __m128i B = _mm_setr_epi8(17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32);
    __m256i AA = _mm256_set_m128i(A, A);
    __m256i BB = _mm256_set_m128i(B, B);

    {
        byte32 C = cast(byte32) _mm256_alignr_epi8!0(AA, BB);
        byte[32] correct = [17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32];
        assert(C.array == correct);
    }
    {
        byte32 C = cast(byte32) _mm256_alignr_epi8!20(AA, BB);
        byte[32] correct = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 0, 0, 0, 0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 0, 0, 0, 0];
        assert(C.array == correct);
    }
    {
        byte32 C = cast(byte32) _mm256_alignr_epi8!34(AA, BB);
        byte[32] correct = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        assert(C.array == correct);
    }
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
    int8 R = cast(int8) _mm256_and_si256(A, B);
    int[8] correct = [6, 6, 6, 6, 6, 6, 6, 6];
    assert(R.array == correct);
}

/// Compute the bitwise NOT of 256 bits (representing integer data) in `a` and then AND with `b`.
__m256i _mm256_andnot_si256 (__m256i a, __m256i b) pure @safe
{
    pragma(inline, true);
    return (~a) & b;
}
unittest
{
    __m256i A = _mm256_setr_epi32(7, -2, 9, 54654, 7, -2, 9, 54654);
    __m256i B = _mm256_setr_epi32(14, 78, 111, -256, 14, 78, 111, -256);
    int8 R = cast(int8) _mm256_andnot_si256(A, B);
    int[8] correct = [8, 0, 102, -54784, 8, 0, 102, -54784];
    assert(R.array == correct);
}

/// Average packed unsigned 16-bit integers in `a` and `b`.
__m256i _mm256_avg_epu16 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_or_LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pavgw256(cast(short16)a, cast(short16)b);
    }
    else
    {
        // Splitting is always beneficial here, except -O0
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_avg_epu16(a_lo, b_lo);
        __m128i r_hi = _mm_avg_epu16(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_set1_epi16(31457);
    __m256i B = _mm256_set1_epi16(cast(short)64000);
    short16 avg = cast(short16)(_mm256_avg_epu16(A, B));
    foreach(i; 0..16)
        assert(avg.array[i] == cast(short)47729);
}

/// Average packed unsigned 8-bit integers in `a` and `b`.
__m256i _mm256_avg_epu8 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pavgb256(cast(ubyte32)a, cast(ubyte32)b);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pavgb256(cast(byte32)a, cast(byte32)b);
    }
    else
    {
        // Splitting is always beneficial here, except -O0
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_avg_epu8(a_lo, b_lo);
        __m128i r_hi = _mm_avg_epu8(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
}
unittest
{
    __m256i A = _mm256_set1_epi8(-1);
    __m256i B = _mm256_set1_epi8(13);
    byte32 avg = cast(byte32)(_mm256_avg_epu8(A, B));
    foreach(i; 0..32)
        assert(avg.array[i] == cast(byte)134);
}


// TODO __m256i _mm256_blend_epi16 (__m256i a, __m256i b, const int imm8) pure @safe
// TODO __m128i _mm_blend_epi32 (__m128i a, __m128i b, const int imm8) pure @safe
// TODO __m256i _mm256_blend_epi32 (__m256i a, __m256i b, const int imm8) pure @safe
// TODO __m256i _mm256_blendv_epi8 (__m256i a, __m256i b, __m256i mask) pure @safe
// TODO __m128i _mm_broadcastb_epi8 (__m128i a) pure @safe
// TODO __m256i _mm256_broadcastb_epi8 (__m128i a) pure @safe
// TODO __m128i _mm_broadcastd_epi32 (__m128i a) pure @safe
// TODO __m256i _mm256_broadcastd_epi32 (__m128i a) pure @safe
// TODO __m128i _mm_broadcastq_epi64 (__m128i a) pure @safe
// TODO __m256i _mm256_broadcastq_epi64 (__m128i a) pure @safe
// TODO __m128d _mm_broadcastsd_pd (__m128d a) pure @safe
// TODO __m256d _mm256_broadcastsd_pd (__m128d a) pure @safe
// TODO __m256i _mm_broadcastsi128_si256 (__m128i a) pure @safe
// TODO __m256i _mm256_broadcastsi128_si256 (__m128i a) pure @safe
// TODO __m128 _mm_broadcastss_ps (__m128 a) pure @safe
// TODO __m256 _mm256_broadcastss_ps (__m128 a) pure @safe
// TODO __m128i _mm_broadcastw_epi16 (__m128i a) pure @safe
// TODO __m256i _mm256_broadcastw_epi16 (__m128i a) pure @safe
// TODO __m256i _mm256_bslli_epi128 (__m256i a, const int imm8) pure @safe
// TODO __m256i _mm256_bsrli_epi128 (__m256i a, const int imm8) pure @safe
// TODO __m256i _mm256_cmpeq_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_cmpeq_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_cmpeq_epi64 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_cmpeq_epi8 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_cmpgt_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_cmpgt_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_cmpgt_epi64 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_cmpgt_epi8 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_cvtepi16_epi32 (__m128i a) pure @safe
// TODO __m256i _mm256_cvtepi16_epi64 (__m128i a) pure @safe
// TODO __m256i _mm256_cvtepi32_epi64 (__m128i a) pure @safe
// TODO __m256i _mm256_cvtepi8_epi16 (__m128i a) pure @safe
// TODO __m256i _mm256_cvtepi8_epi32 (__m128i a) pure @safe
// TODO __m256i _mm256_cvtepi8_epi64 (__m128i a) pure @safe

/// Zero-extend packed unsigned 16-bit integers in `a` to packed 32-bit integers.
// TODO verify
__m256i _mm256_cvtepu16_epi32(__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovzxwd256(cast(short8)a);
    }
    else
    {
        short8 sa = cast(short8)a;
        int8 r; // PERF =void;
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

// TODO __m256i _mm256_cvtepu16_epi64 (__m128i a) pure @safe
// TODO __m256i _mm256_cvtepu32_epi64 (__m128i a) pure @safe
// TODO __m256i _mm256_cvtepu8_epi16 (__m128i a) pure @safe
// TODO __m256i _mm256_cvtepu8_epi32 (__m128i a) pure @safe
// TODO __m256i _mm256_cvtepu8_epi64 (__m128i a) pure @safe
// TODO int _mm256_extract_epi16 (__m256i a, const int index) pure @safe
// TODO int _mm256_extract_epi8 (__m256i a, const int index) pure @safe

/// Extract 128 bits (composed of integer data) from `a`, selected with `imm8`.
__m128i _mm256_extracti128_si256(int imm8)(__m256i a) pure @trusted
    if ( (imm8 == 0) || (imm8 == 1) )
// TODO verify
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
        long4 al = cast(long4) a;
        long2 ret;
        ret.ptr[0] = (imm8==1) ? al.array[2] : al.array[0];
        ret.ptr[1] = (imm8==1) ? al.array[3] : al.array[1];
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

// TODO __m256i _mm256_hadd_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_hadd_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_hadds_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_hsub_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_hsub_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_hsubs_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m128i _mm_i32gather_epi32 (int const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128i _mm_mask_i32gather_epi32 (__m128i src, int const* base_addr, __m128i vindex, __m128i mask, const int scale) pure @safe
// TODO __m256i _mm256_i32gather_epi32 (int const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m256i _mm256_mask_i32gather_epi32 (__m256i src, int const* base_addr, __m256i vindex, __m256i mask, const int scale) pure @safe
// TODO __m128i _mm_i32gather_epi64 (__int64 const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128i _mm_mask_i32gather_epi64 (__m128i src, __int64 const* base_addr, __m128i vindex, __m128i mask, const int scale) pure @safe
// TODO __m256i _mm256_i32gather_epi64 (__int64 const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m256i _mm256_mask_i32gather_epi64 (__m256i src, __int64 const* base_addr, __m128i vindex, __m256i mask, const int scale) pure @safe
// TODO __m128d _mm_i32gather_pd (double const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128d _mm_mask_i32gather_pd (__m128d src, double const* base_addr, __m128i vindex, __m128d mask, const int scale) pure @safe
// TODO __m256d _mm256_i32gather_pd (double const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m256d _mm256_mask_i32gather_pd (__m256d src, double const* base_addr, __m128i vindex, __m256d mask, const int scale) pure @safe
// TODO __m128 _mm_i32gather_ps (float const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128 _mm_mask_i32gather_ps (__m128 src, float const* base_addr, __m128i vindex, __m128 mask, const int scale) pure @safe
// TODO __m256 _mm256_i32gather_ps (float const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m256 _mm256_mask_i32gather_ps (__m256 src, float const* base_addr, __m256i vindex, __m256 mask, const int scale) pure @safe
// TODO __m128i _mm_i64gather_epi32 (int const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128i _mm_mask_i64gather_epi32 (__m128i src, int const* base_addr, __m128i vindex, __m128i mask, const int scale) pure @safe
// TODO __m128i _mm256_i64gather_epi32 (int const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m128i _mm256_mask_i64gather_epi32 (__m128i src, int const* base_addr, __m256i vindex, __m128i mask, const int scale) pure @safe
// TODO __m128i _mm_i64gather_epi64 (__int64 const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128i _mm_mask_i64gather_epi64 (__m128i src, __int64 const* base_addr, __m128i vindex, __m128i mask, const int scale) pure @safe
// TODO __m256i _mm256_i64gather_epi64 (__int64 const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m256i _mm256_mask_i64gather_epi64 (__m256i src, __int64 const* base_addr, __m256i vindex, __m256i mask, const int scale) pure @safe
// TODO __m128d _mm_i64gather_pd (double const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128d _mm_mask_i64gather_pd (__m128d src, double const* base_addr, __m128i vindex, __m128d mask, const int scale) pure @safe
// TODO __m256d _mm256_i64gather_pd (double const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m256d _mm256_mask_i64gather_pd (__m256d src, double const* base_addr, __m256i vindex, __m256d mask, const int scale) pure @safe
// TODO __m128 _mm_i64gather_ps (float const* base_addr, __m128i vindex, const int scale) pure @safe
// TODO __m128 _mm_mask_i64gather_ps (__m128 src, float const* base_addr, __m128i vindex, __m128 mask, const int scale) pure @safe
// TODO __m128 _mm256_i64gather_ps (float const* base_addr, __m256i vindex, const int scale) pure @safe
// TODO __m128 _mm256_mask_i64gather_ps (__m128 src, float const* base_addr, __m256i vindex, __m128 mask, const int scale) pure @safe
// TODO __m256i _mm256_inserti128_si256 (__m256i a, __m128i b, const int imm8) pure @safe

/// Multiply packed signed 16-bit integers in `a` and `b`, producing intermediate
/// signed 32-bit integers. Horizontally add adjacent pairs of intermediate 32-bit integers,
/// and pack the results in destination.
// TODO verify
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
        int8 r; // PERF =void;
        foreach(i; 0..8)
        {
            r.ptr[i] = sa.array[2*i] * sb.array[2*i] + sa.array[2*i+1] * sb.array[2*i+1];
        }
        return cast(__m256i) r;
    }
}
unittest
{
    short16 A = [0, 1, 2, 3, -32768, -32768, 32767, 32767, 0, 1, 2, 3, -32768, -32768, 32767, 32767];
    short16 B = [0, 1, 2, 3, -32768, -32768, 32767, 32767, 0, 1, 2, 3, -32768, -32768, 32767, 32767];
    int8 R = cast(int8) _mm256_madd_epi16(cast(__m256i)A, cast(__m256i)B);
    int[8] correct = [1, 13, -2147483648, 2*32767*32767, 1, 13, -2147483648, 2*32767*32767];
    assert(R.array == correct);
}

// TODO __m256i _mm256_maddubs_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m128i _mm_maskload_epi32 (int const* mem_addr, __m128i mask) pure @safe
// TODO __m256i _mm256_maskload_epi32 (int const* mem_addr, __m256i mask) pure @safe
// TODO __m128i _mm_maskload_epi64 (__int64 const* mem_addr, __m128i mask) pure @safe
// TODO __m256i _mm256_maskload_epi64 (__int64 const* mem_addr, __m256i mask) pure @safe
// TODO __m256i _mm256_max_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_max_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_max_epi8 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_max_epu16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_max_epu32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_max_epu8 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_min_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_min_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_min_epi8 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_min_epu16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_min_epu32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_min_epu8 (__m256i a, __m256i b) pure @safe
// TODO int _mm256_movemask_epi8 (__m256i a) pure @safe
// TODO __m256i _mm256_mpsadbw_epu8 (__m256i a, __m256i b, const int imm8) pure @safe
// TODO __m256i _mm256_mul_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_mul_epu32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_mulhi_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_mulhi_epu16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_mulhrs_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_mullo_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_mullo_epi32 (__m256i a, __m256i b) pure @safe

/// Compute the bitwise OR of 256 bits (representing integer data) in `a` and `b`.
__m256i _mm256_or_si256 (__m256i a, __m256i b) pure @safe
{
    return a | b;
}
unittest
{
    long A = 0x55555555_55555555;
    long B = 0xAAAAAAAA_AAAAAAAA;
    __m256i vA = _mm256_set_epi64(A, B, A, B);
    __m256i vB = _mm256_set_epi64(B, A, 0, B);
    __m256i R  = _mm256_or_si256(vA, vB);
    long[4] correct = [B, A, -1, -1];
    assert(R.array == correct);
}

// TODO __m256i _mm256_packs_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_packs_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_packus_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_packus_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_permute2x128_si256 (__m256i a, __m256i b, const int imm8) pure @safe
// TODO __m256i _mm256_permute4x64_epi64 (__m256i a, const int imm8) pure @safe
// TODO __m256d _mm256_permute4x64_pd (__m256d a, const int imm8) pure @safe
// TODO __m256i _mm256_permutevar8x32_epi32 (__m256i a, __m256i idx) pure @safe
// TODO __m256 _mm256_permutevar8x32_ps (__m256 a, __m256i idx) pure @safe

/// Compute the absolute differences of packed unsigned 8-bit integers in `a` and `b`, then horizontally sum each
/// consecutive 8 differences to produce two unsigned 16-bit integers, and pack these unsigned 16-bit integers in the
/// low 16 bits of 64-bit elements in result.
// TODO verify
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
            t.ptr[i] = cast(ubyte)(diff);
        }
        int8 r = cast(int8) _mm256_setzero_si256();
        r.ptr[0] = t[0]  + t[1]  + t[2]  + t[3]  + t[4]  + t[5]  + t[6]  + t[7];
        r.ptr[2] = t[8]  + t[9]  + t[10] + t[11] + t[12] + t[13] + t[14] + t[15];
        r.ptr[4] = t[16] + t[17] + t[18] + t[19] + t[20] + t[21] + t[22] + t[23];
        r.ptr[6] = t[24] + t[25] + t[26] + t[27] + t[28] + t[29] + t[30] + t[31];
        return cast(__m256i) r;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi8(3, 4, 6, 8, 12, 14, 18, 20, 24, 30, 32, 38, 42, 44, 48, 54,
                              3, 4, 6, 8, 12, 14, 18, 20, 24, 30, 32, 38, 42, 44, 48, 54); // primes + 1
    __m256i B = _mm256_set1_epi8(1);
    int8 R = cast(int8) _mm256_sad_epu8(A, B);
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


// TODO __m256i _mm256_shuffle_epi32 (__m256i a, const int imm8) pure @safe
// TODO __m256i _mm256_shuffle_epi8 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_shufflehi_epi16 (__m256i a, const int imm8) pure @safe
// TODO __m256i _mm256_shufflelo_epi16 (__m256i a, const int imm8) pure @safe
// TODO __m256i _mm256_sign_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_sign_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_sign_epi8 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_sll_epi16 (__m256i a, __m128i count) pure @safe
// TODO __m256i _mm256_sll_epi32 (__m256i a, __m128i count) pure @safe
// TODO __m256i _mm256_sll_epi64 (__m256i a, __m128i count) pure @safe

/// Shift packed 16-bit integers in `a` left by `imm8` while shifting in zeros.
// TODO verify
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
// TODO verify
__m256i _mm256_slli_epi32 (__m256i a, int imm8) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pslldi256(cast(int8)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pslldi256(cast(int8)a, cast(ubyte)imm8);
    }
    else
    {
        // Note: the intrinsics guarantee imm8[0..7] is taken, however
        //       D says "It's illegal to shift by the same or more bits
        //       than the size of the quantity being shifted"
        //       and it's UB instead.
        int8 a_int8 = cast(int8) a;
        int8 r      = cast(int8) _mm256_setzero_si256();

        ubyte count = cast(ubyte) imm8;
        if (count > 31)
            return cast(__m256i) r;

        foreach(i; 0..8)
            r.ptr[i] = cast(uint)(a_int8.array[i]) << count;
        return cast(__m256i) r;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, 2, 3, -4, 0, 2, 3, -4);
    int8 B = cast(int8) _mm256_slli_epi32(A, 1);
    int8 B2 = cast(int8) _mm256_slli_epi32(A, 1 + 256);
    int[8] expectedB = [ 0, 4, 6, -8, 0, 4, 6, -8 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    int8 C = cast(int8) _mm256_slli_epi32(A, 0);
    int[8] expectedC = [ 0, 2, 3, -4, 0, 2, 3, -4 ];
    assert(C.array == expectedC);

    int8 D = cast(int8) _mm256_slli_epi32(A, 65);
    int[8] expectedD = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(D.array == expectedD);
}

// TODO __m256i _mm256_slli_epi64 (__m256i a, int imm8) pure @safe
// TODO __m256i _mm256_slli_si256 (__m256i a, const int imm8) pure @safe
// TODO __m128i _mm_sllv_epi32 (__m128i a, __m128i count) pure @safe
// TODO __m256i _mm256_sllv_epi32 (__m256i a, __m256i count) pure @safe
// TODO __m128i _mm_sllv_epi64 (__m128i a, __m128i count) pure @safe
// TODO __m256i _mm256_sllv_epi64 (__m256i a, __m256i count) pure @safe
// TODO __m256i _mm256_sra_epi16 (__m256i a, __m128i count) pure @safe
// TODO __m256i _mm256_sra_epi32 (__m256i a, __m128i count) pure @safe
// TODO __m256i _mm256_srai_epi16 (__m256i a, int imm8) pure @safe
// TODO __m256i _mm256_srai_epi32 (__m256i a, int imm8) pure @safe
// TODO __m128i _mm_srav_epi32 (__m128i a, __m128i count) pure @safe
// TODO __m256i _mm256_srav_epi32 (__m256i a, __m256i count) pure @safe
// TODO __m256i _mm256_srl_epi16 (__m256i a, __m128i count) pure @safe
// TODO __m256i _mm256_srl_epi32 (__m256i a, __m128i count) pure @safe
// TODO __m256i _mm256_srl_epi64 (__m256i a, __m128i count) pure @safe

/// Shift packed 16-bit integers in `a` right by `imm8` while shifting in zeros.
// TODO verify
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
            r.ptr[i] = cast(short)(cast(ushort)(sa.array[i]) >> count);
        return cast(__m256i)r;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7, 0, 1, 2, 3, -4, -5, 6, 7);
    short16 B = cast(short16) _mm256_srli_epi16(A, 1);
    short16 B2 = cast(short16) _mm256_srli_epi16(A, 1 + 256);
    short[16] expectedB = [ 0, 0, 1, 1, 0x7FFE, 0x7FFD, 3, 3, 0, 0, 1, 1, 0x7FFE, 0x7FFD, 3, 3 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    short16 C = cast(short16) _mm256_srli_epi16(A, 16);
    short[16] expectedC = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(C.array == expectedC);

    short16 D = cast(short16) _mm256_srli_epi16(A, 0);
    short[16] expectedD = [ 0, 1, 2, 3, -4, -5, 6, 7, 0, 1, 2, 3, -4, -5, 6, 7 ];
    assert(D.array == expectedD);
}

/// Shift packed 32-bit integers in `a` right by `imm8` while shifting in zeros.
// TODO verify
__m256i _mm256_srli_epi32 (__m256i a, int imm8) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrldi256(cast(int8)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_psrldi256(cast(int8)a, cast(ubyte)imm8);
    }
    else
    {
        ubyte count = cast(ubyte) imm8;
        int8 a_int8 = cast(int8) a;

        // Note: the intrinsics guarantee imm8[0..7] is taken, however
        //       D says "It's illegal to shift by the same or more bits
        //       than the size of the quantity being shifted"
        //       and it's UB instead.
        int8 r = cast(int8) _mm256_setzero_si256();
        if (count >= 32)
            return cast(__m256i) r;
        r.ptr[0] = a_int8.array[0] >>> count;
        r.ptr[1] = a_int8.array[1] >>> count;
        r.ptr[2] = a_int8.array[2] >>> count;
        r.ptr[3] = a_int8.array[3] >>> count;
        r.ptr[4] = a_int8.array[4] >>> count;
        r.ptr[5] = a_int8.array[5] >>> count;
        r.ptr[6] = a_int8.array[6] >>> count;
        r.ptr[7] = a_int8.array[7] >>> count;
        return cast(__m256i) r;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(0, 2, 3, -4, 0, 2, 3, -4);
    int8 B = cast(int8) _mm256_srli_epi32(A, 1);
    int8 B2 = cast(int8) _mm256_srli_epi32(A, 1 + 256);
    int[8] expectedB = [ 0, 1, 1, 0x7FFFFFFE, 0, 1, 1, 0x7FFFFFFE];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    int8 C = cast(int8) _mm256_srli_epi32(A, 255);
    int[8] expectedC = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(C.array == expectedC);
}

// TODO __m256i _mm256_srli_epi64 (__m256i a, int imm8) pure @safe
// TODO __m256i _mm256_srli_si256 (__m256i a, const int imm8) pure @safe
// TODO __m128i _mm_srlv_epi32 (__m128i a, __m128i count) pure @safe
// TODO __m256i _mm256_srlv_epi32 (__m256i a, __m256i count) pure @safe
// TODO __m128i _mm_srlv_epi64 (__m128i a, __m128i count) pure @safe
// TODO __m256i _mm256_srlv_epi64 (__m256i a, __m256i count) pure @safe
// TODO __m256i _mm256_stream_load_si256 (__m256i const* mem_addr) pure @safe
// TODO __m256i _mm256_sub_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_sub_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_sub_epi64 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_sub_epi8 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_subs_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_subs_epi8 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_subs_epu16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_subs_epu8 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_unpackhi_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_unpackhi_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_unpackhi_epi64 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_unpackhi_epi8 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_unpacklo_epi16 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_unpacklo_epi32 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_unpacklo_epi64 (__m256i a, __m256i b) pure @safe
// TODO __m256i _mm256_unpacklo_epi8 (__m256i a, __m256i b) pure @safe

/// Compute the bitwise XOR of 256 bits (representing integer data) in `a` and `b`.
__m256i _mm256_xor_si256 (__m256i a, __m256i b) pure @safe
// TODO verify
{
    return a ^ b;
}
// TODO unittest and thus force inline


/+

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.d")
int4 __builtin_ia32_gatherd_d(int4, const void*, int4, int4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.d.256")
int8 __builtin_ia32_gatherd_d256(int8, const void*, int8, int8, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.pd")
double2 __builtin_ia32_gatherd_pd(double2, const void*, int4, double2, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.pd.256")
double4 __builtin_ia32_gatherd_pd256(double4, const void*, int4, double4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.ps")
float4 __builtin_ia32_gatherd_ps(float4, const void*, int4, float4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.ps.256")
float8 __builtin_ia32_gatherd_ps256(float8, const void*, int8, float8, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.q")
long2 __builtin_ia32_gatherd_q(long2, const void*, int4, long2, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.d.q.256")
long4 __builtin_ia32_gatherd_q256(long4, const void*, int4, long4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.d")
int4 __builtin_ia32_gatherq_d(int4, const void*, long2, int4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.d.256")
int4 __builtin_ia32_gatherq_d256(int4, const void*, long4, int4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.pd")
double2 __builtin_ia32_gatherq_pd(double2, const void*, long2, double2, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.pd.256")
double4 __builtin_ia32_gatherq_pd256(double4, const void*, long4, double4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.ps")
float4 __builtin_ia32_gatherq_ps(float4, const void*, long2, float4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.ps.256")
float4 __builtin_ia32_gatherq_ps256(float4, const void*, long4, float4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.q")
long2 __builtin_ia32_gatherq_q(long2, const void*, long2, long2, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.gather.q.q.256")
long4 __builtin_ia32_gatherq_q256(long4, const void*, long4, long4, byte);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskload.d")
int4 __builtin_ia32_maskloadd(const void*, int4);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskload.d.256")
int8 __builtin_ia32_maskloadd256(const void*, int8);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskload.q")
long2 __builtin_ia32_maskloadq(const void*, long2);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskload.q.256")
long4 __builtin_ia32_maskloadq256(const void*, long4);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskstore.d")
void __builtin_ia32_maskstored(void*, int4, int4);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskstore.d.256")
void __builtin_ia32_maskstored256(void*, int8, int8);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskstore.q")
void __builtin_ia32_maskstoreq(void*, long2, long2);

pragma(LDC_intrinsic, "llvm.x86.avx2.maskstore.q.256")
void __builtin_ia32_maskstoreq256(void*, long4, long4);

pragma(LDC_intrinsic, "llvm.x86.avx2.mpsadbw")
short16 __builtin_ia32_mpsadbw256(byte32, byte32, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.packssdw")
short16 __builtin_ia32_packssdw256(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.packsswb")
byte32 __builtin_ia32_packsswb256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.packusdw")
short16 __builtin_ia32_packusdw256(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.packuswb")
byte32 __builtin_ia32_packuswb256(short16, short16) pure @safe;


pragma(LDC_intrinsic, "llvm.x86.avx2.pblendvb")
byte32 __builtin_ia32_pblendvb256(byte32, byte32, byte32) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.permd")
int8 __builtin_ia32_permvarsi256(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.permps")
float8 __builtin_ia32_permvarsf256(float8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.phadd.d")
int8 __builtin_ia32_phaddd256(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.phadd.sw")
short16 __builtin_ia32_phaddsw256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.phadd.w")
short16 __builtin_ia32_phaddw256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.phsub.d")
int8 __builtin_ia32_phsubd256(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.phsub.sw")
short16 __builtin_ia32_phsubsw256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.phsub.w")
short16 __builtin_ia32_phsubw256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pmadd.ub.sw")
short16 __builtin_ia32_pmaddubsw256(byte32, byte32) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pmadd.wd")
int8 __builtin_ia32_pmaddwd256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pmovmskb")
int __builtin_ia32_pmovmskb256(byte32) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pmul.hr.sw")
short16 __builtin_ia32_pmulhrsw256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pmulh.w")
short16 __builtin_ia32_pmulhw256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pmulhu.w")
short16 __builtin_ia32_pmulhuw256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psad.bw")
long4 __builtin_ia32_psadbw256(byte32, byte32) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pshuf.b")
byte32 __builtin_ia32_pshufb256(byte32, byte32) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psign.b")
byte32 __builtin_ia32_psignb256(byte32, byte32) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psign.d")
int8 __builtin_ia32_psignd256(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psign.w")
short16 __builtin_ia32_psignw256(short16, short16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psll.d")
int8 __builtin_ia32_pslld256(int8, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psll.q")
long4 __builtin_ia32_psllq256(long4, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psll.w")
short16 __builtin_ia32_psllw256(short16, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pslli.d")
int8 __builtin_ia32_pslldi256(int8, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pslli.q")
long4 __builtin_ia32_psllqi256(long4, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.pslli.w")
short16 __builtin_ia32_psllwi256(short16, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psllv.d")
int4 __builtin_ia32_psllv4si(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psllv.d.256")
int8 __builtin_ia32_psllv8si(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psllv.q")
long2 __builtin_ia32_psllv2di(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psllv.q.256")
long4 __builtin_ia32_psllv4di(long4, long4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psra.d")
int8 __builtin_ia32_psrad256(int8, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psra.w")
short16 __builtin_ia32_psraw256(short16, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrai.d")
int8 __builtin_ia32_psradi256(int8, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrai.w")
short16 __builtin_ia32_psrawi256(short16, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrav.d")
int4 __builtin_ia32_psrav4si(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrav.d.256")
int8 __builtin_ia32_psrav8si(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrl.d")
int8 __builtin_ia32_psrld256(int8, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrl.q")
long4 __builtin_ia32_psrlq256(long4, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrl.w")
short16 __builtin_ia32_psrlw256(short16, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrli.d")
int8 __builtin_ia32_psrldi256(int8, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrli.q")
long4 __builtin_ia32_psrlqi256(long4, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrli.w")
short16 __builtin_ia32_psrlwi256(short16, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrlv.d")
int4 __builtin_ia32_psrlv4si(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrlv.d.256")
int8 __builtin_ia32_psrlv8si(int8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrlv.q")
long2 __builtin_ia32_psrlv2di(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx2.psrlv.q.256")
long4 __builtin_ia32_psrlv4di(long4, long4) pure @safe;

+/