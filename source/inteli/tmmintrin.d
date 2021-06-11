/**
* SSSE3 intrinsics.
*
* Copyright: Guillaume Piolat 2021.
*            Johan Engelen 2021.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.tmmintrin;

public import inteli.types;
import inteli.internals;

public import inteli.pmmintrin;
import inteli.mmx;

nothrow @nogc:


// SSSE3 instructions
// https://software.intel.com/sites/landingpage/IntrinsicsGuide/#techs=SSSE3
// Note: this header will work whether you have SSSE3 enabled or not.
// With LDC, use "dflags-ldc": ["-mattr=+ssse3"] or equivalent to actively 
// generate SSE3 instructions.

/// Compute the absolute value of packed signed 16-bit integers in `a`.
__m128i _mm_abs_epi16 (__m128i a) @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i)__simd(XMM.PABSW, a);
    }
    else static if (GDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_pabsw128(cast(short8)a);
    }
    else static if (LDC_with_ARM64)
    {
        return cast(__m128i) vabsq_s16(cast(short8)a);
    }
    else
    {
        // LDC x86: generate pabsw since LDC 1.1 -O2
        short8 sa = cast(short8)a;
        for (int i = 0; i < 8; ++i)
        {
            short s = sa.array[i];
            sa.ptr[i] = s >= 0 ? s : cast(short)(-cast(int)(s));
        }  
        return cast(__m128i)sa;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, -1, -32768, 32767, 10, -10, 1000, -1000);
    short8 B = cast(short8) _mm_abs_epi16(A);
    short[8] correct = [0, 1, -32768, 32767, 10, 10, 1000, 1000];
    assert(B.array == correct);
}

/// Compute the absolute value of packed signed 32-bit integers in `a`.
__m128i _mm_abs_epi32 (__m128i a) @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i)__simd(XMM.PABSD, cast(int4)a);
    }
    else static if (GDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_pabsd128(cast(int4)a);
    }
    else static if (LDC_with_ARM64)
    {
        return cast(__m128i) vabsq_s32(cast(int4)a);
    }
    else
    {
        // LDC x86: generates pabsd since LDC 1.1 -O2
        int4 sa = cast(int4)a;
        for (int i = 0; i < 4; ++i)
        {
            int s = sa.array[i];
            sa.ptr[i] = s >= 0 ? s : -s;
        }  
        return cast(__m128i)sa;
    } 
}
unittest
{
    __m128i A = _mm_setr_epi32(0, -1, -2_147_483_648, -2_147_483_647);
    int4 B = cast(int4) _mm_abs_epi32(A);
    int[4] correct = [0, 1, -2_147_483_648, 2_147_483_647];
    assert(B.array == correct);
}

/// Compute the absolute value of packed signed 8-bit integers in `a`.
__m128i _mm_abs_epi8 (__m128i a) @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i)__simd(XMM.PABSB, cast(byte16)a);
    }
    else static if (GDC_with_SSSE3)
    {
        alias ubyte16 = __vector(ubyte[16]);
        return cast(__m128i) __builtin_ia32_pabsb128(cast(ubyte16)a);
    }
    else static if (LDC_with_ARM64)
    {
        return cast(__m128i) vabsq_s8(cast(byte16)a);
    }
    else static if (LDC_with_SSSE3)
    {
        return __asm!__m128i("pabsb $1,$0","=x,x",a);
    }
    else
    {
        // A loop version like in _mm_abs_epi16/_mm_abs_epi32 would be very slow 
        // in LDC x86 and wouldn't vectorize. Doesn't generate pabsb in LDC though.
        return _mm_min_epu8(a, _mm_sub_epi8(_mm_setzero_si128(), a));
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(0, -1, -128, -127, 127, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    byte16 B = cast(byte16) _mm_abs_epi8(A);
    byte[16] correct =       [0,  1, -128,  127, 127, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    assert(B.array == correct);
}

/// Compute the absolute value of packed signed 16-bit integers in `a`.
__m64 _mm_abs_pi16 (__m64 a) @trusted
{
    return to_m64(_mm_abs_epi16(to_m128i(a)));
}
unittest
{
    __m64 A = _mm_setr_pi16(0, -1, -32768, 32767);
    short4 B = cast(short4) _mm_abs_pi16(A);
    short[4] correct = [0, 1, -32768, 32767];
    assert(B.array == correct);
}

/// Compute the absolute value of packed signed 32-bit integers in `a`.
__m64 _mm_abs_pi32 (__m64 a) @trusted
{
     return to_m64(_mm_abs_epi32(to_m128i(a)));
}
unittest
{
    __m64 A = _mm_setr_pi32(-1, -2_147_483_648);
    int2 B = cast(int2) _mm_abs_pi32(A);
    int[2] correct = [1, -2_147_483_648];
    assert(B.array == correct);
}

/// Compute the absolute value of packed signed 8-bit integers in `a`.
__m64 _mm_abs_pi8 (__m64 a) @trusted
{
    return to_m64(_mm_abs_epi8(to_m128i(a)));
}
unittest
{
    __m64 A = _mm_setr_pi8(0, -1, -128, -127, 127, 0, 0, 0);
    byte8 B = cast(byte8) _mm_abs_pi8(A);
    byte[8] correct =       [0,  1, -128,  127, 127, 0, 0, 0];
    assert(B.array == correct);
}

/// Concatenate 16-byte blocks in `a` and `b` into a 32-byte temporary result, shift the result right by `count` bytes, and return the low 16 bytes.
__m128i _mm_alignr_epi8(ubyte count)(__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_palignr128(cast(long2)a, cast(long2)b, count * 8);
    }
    else
    {
        // Generates palignr since LDC 1.1 -O1
        // Also generates a single ext instruction on arm64.
        return cast(__m128i) shufflevector!(byte16, ( 0 + count) % 32,
                                                    ( 1 + count) % 32,
                                                    ( 2 + count) % 32,
                                                    ( 3 + count) % 32,
                                                    ( 4 + count) % 32,
                                                    ( 5 + count) % 32,
                                                    ( 6 + count) % 32,
                                                    ( 7 + count) % 32,
                                                    ( 8 + count) % 32,
                                                    ( 9 + count) % 32,
                                                    (10 + count) % 32,
                                                    (11 + count) % 32,
                                                    (12 + count) % 32,
                                                    (13 + count) % 32,
                                                    (14 + count) % 32,
                                                    (15 + count) % 32)(cast(byte16)a, cast(byte16)b);
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    __m128i B = _mm_setr_epi8(17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32);

    {
        byte16 C = cast(byte16)_mm_alignr_epi8!7(A ,B);
        byte[16] correct = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
        assert(C.array == correct);
    }
    {
        byte16 C = cast(byte16)_mm_alignr_epi8!20(A ,B);
        byte[16] correct = [21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 1, 2, 3, 4];
        assert(C.array == correct);
    }
}

/// Concatenate 8-byte blocks in `a` and `b` into a 16-byte temporary result, shift the result right by `count` bytes, and return the low 8 bytes.
__m64 _mm_alignr_pi8(ubyte count)(__m64 a, __m64 b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m64)__builtin_ia32_palignr(cast(long)a, cast(long)b, count * 8);
    }
    else
    {
        // Note: in LDC x86 this uses a pshufb.
        // Generates ext in arm64.
        return cast(__m64) shufflevector!(byte8, (0 + count) % 16,
                                                 (1 + count) % 16,
                                                 (2 + count) % 16,
                                                 (3 + count) % 16,
                                                 (4 + count) % 16,
                                                 (5 + count) % 16,
                                                 (6 + count) % 16,
                                                 (7 + count) % 16)(cast(byte8)a, cast(byte8)b);
    }
}
unittest
{
    __m64 A = _mm_setr_pi8(1, 2, 3, 4, 5, 6, 7, 8);
    __m64 B = _mm_setr_pi8(17, 18, 19, 20, 21, 22, 23, 24);

    {
        byte8 C = cast(byte8)_mm_alignr_pi8!3(A ,B);
        byte[8] correct = [4, 5, 6, 7, 8, 17, 18, 19];
        assert(C.array == correct);
    }
    {
        byte8 C = cast(byte8)_mm_alignr_pi8!10(A ,B);
        byte[8] correct = [19, 20, 21, 22, 23, 24, 1, 2];
        assert(C.array == correct);
    }
}

/// Horizontally add adjacent pairs of 16-bit integers in `a` and `b`, and pack the signed 16-bit results.
__m128i _mm_hadd_epi16 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phaddw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phaddw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_ARM64)
    {
        return cast(__m128i)vpaddq_s16(cast(short8)a, cast(short8)b);
    }
    else
    {
        // Note: LDC x86 would generate phaddw with -O2, but builtin works in -O0 and -O1
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 r;
        r[0] = cast(short)(sa[0] + sa[1]);
        r[1] = cast(short)(sa[2] + sa[3]);
        r[2] = cast(short)(sa[4] + sa[5]);
        r[3] = cast(short)(sa[6] + sa[7]);
        r[4] = cast(short)(sb[0] + sb[1]);
        r[5] = cast(short)(sb[2] + sb[3]);
        r[6] = cast(short)(sb[4] + sb[5]);
        r[7] = cast(short)(sb[6] + sb[7]);
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(1, -2, 4, 8, 16, 32, -1, -32768);
    short8 C = cast(short8) _mm_hadd_epi16(A, A);
    short[8] correct = [ -1, 12, 48, 32767, -1, 12, 48, 32767];
    assert(C.array == correct);
}

/// Horizontally add adjacent pairs of 32-bit integers in `a` and `b`, and pack the signed 32-bit results.
__m128i _mm_hadd_epi32 (__m128i a, __m128i b) @trusted
{ 
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phaddd128(cast(int4)a, cast(int4)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phaddd128(cast(int4)a, cast(int4)b);
    }
    else static if (LDC_with_ARM64)
    {
        return cast(__m128i)vpaddq_s32(cast(int4)a, cast(int4)b);
    }
    else
    {
        // x86: Would generate phaddd since LDC 1.3 -O2, but builtin better
        int4 ia = cast(int4)a;
        int4 ib = cast(int4)b;
        int4 r;
        r[0] = ia[0] + ia[1];
        r[1] = ia[2] + ia[3];
        r[2] = ib[0] + ib[1];
        r[3] = ib[2] + ib[3];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(1, -2, int.min, -1);
    __m128i B = _mm_setr_epi32(1, int.max, 4, -4);
    int4 C = cast(int4) _mm_hadd_epi32(A, B);
    int[4] correct = [ -1, int.max, int.min, 0 ];
    assert(C.array == correct);
}


/*
__m64 _mm_hadd_pi16 (__m64 a, __m64 b)
{
}
unittest
{
}
*/
/*
__m64 _mm_hadd_pi32 (__m64 a, __m64 b)
{
}
unittest
{
}
*/
/*
__m128i _mm_hadds_epi16 (__m128i a, __m128i b)
{
}
unittest
{
}
*/
/*
__m64 _mm_hadds_pi16 (__m64 a, __m64 b)
{
}
unittest
{
}
*/
/*
__m128i _mm_hsub_epi16 (__m128i a, __m128i b)
{
}
unittest
{
}
*/
/*
__m128i _mm_hsub_epi32 (__m128i a, __m128i b)
{
}
unittest
{
}
*/
/*
__m64 _mm_hsub_pi16 (__m64 a, __m64 b)
{
}
unittest
{
}
*/
/*
__m64 _mm_hsub_pi32 (__m64 a, __m64 b)
{
}
unittest
{
}
*/
/*
__m128i _mm_hsubs_epi16 (__m128i a, __m128i b)
{
}
unittest
{
}
*/
/*
__m64 _mm_hsubs_pi16 (__m64 a, __m64 b)
{
}
unittest
{
}
*/
/*
__m128i _mm_maddubs_epi16 (__m128i a, __m128i b)
{
}
unittest
{
}
*/
/*
__m64 _mm_maddubs_pi16 (__m64 a, __m64 b)
{
}
unittest
{
}
*/
/*
__m128i _mm_mulhrs_epi16 (__m128i a, __m128i b)
{
}
unittest
{
}
*/
/*
__m64 _mm_mulhrs_pi16 (__m64 a, __m64 b)
{
}
unittest
{
}
*/
/*
__m128i _mm_shuffle_epi8 (__m128i a, __m128i b)
{
}
unittest
{
}
*/
/*
__m64 _mm_shuffle_pi8 (__m64 a, __m64 b)
{
}
unittest
{
}
*/
/*
__m128i _mm_sign_epi16 (__m128i a, __m128i b)
{
}
unittest
{
}
*/
/*
__m128i _mm_sign_epi32 (__m128i a, __m128i b)
{
}
unittest
{
}
*/
/*
__m128i _mm_sign_epi8 (__m128i a, __m128i b)
{
}
unittest
{
}
*/
/*
__m64 _mm_sign_pi16 (__m64 a, __m64 b)
{
}
unittest
{
}
*/
/*
__m64 _mm_sign_pi32 (__m64 a, __m64 b)
{
}
unittest
{
}
*/
/*
__m64 _mm_sign_pi8 (__m64 a, __m64 b)
{
}
unittest
{
}
*/



/*


Note: LDC 1.0 to 1.27 have the following builtins:

pragma(LDC_intrinsic, "llvm.x86.ssse3.phadd.d.128")
    int4 __builtin_ia32_phaddd128(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.phadd.sw.128")
    short8 __builtin_ia32_phaddsw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.phadd.w.128")
    short8 __builtin_ia32_phaddw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.phsub.d.128")
    int4 __builtin_ia32_phsubd128(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.phsub.sw.128")
    short8 __builtin_ia32_phsubsw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.phsub.w.128")
    short8 __builtin_ia32_phsubw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.pmadd.ub.sw.128")
    short8 __builtin_ia32_pmaddubsw128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.pmul.hr.sw.128")
    short8 __builtin_ia32_pmulhrsw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.pshuf.b.128")
    byte16 __builtin_ia32_pshufb128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.psign.b.128")
    byte16 __builtin_ia32_psignb128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.psign.d.128")
    int4 __builtin_ia32_psignd128(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.psign.w.128")
    short8 __builtin_ia32_psignw128(short8, short8) pure @safe;

*/