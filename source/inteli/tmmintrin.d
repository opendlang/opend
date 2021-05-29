/**
* SSSE3 intrinsics.
*
* Copyright: Guillaume Piolat 2021.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.tmmintrin;

public import inteli.types;
import inteli.internals;

public import inteli.pmmintrin;

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