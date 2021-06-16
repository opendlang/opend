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
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 r;
        r.ptr[0] = cast(short)(sa.array[0] + sa.array[1]);
        r.ptr[1] = cast(short)(sa.array[2] + sa.array[3]);
        r.ptr[2] = cast(short)(sa.array[4] + sa.array[5]);
        r.ptr[3] = cast(short)(sa.array[6] + sa.array[7]);
        r.ptr[4] = cast(short)(sb.array[0] + sb.array[1]);
        r.ptr[5] = cast(short)(sb.array[2] + sb.array[3]);
        r.ptr[6] = cast(short)(sb.array[4] + sb.array[5]);
        r.ptr[7] = cast(short)(sb.array[6] + sb.array[7]);
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
        int4 ia = cast(int4)a;
        int4 ib = cast(int4)b;
        int4 r;
        r.ptr[0] = ia.array[0] + ia.array[1];
        r.ptr[1] = ia.array[2] + ia.array[3];
        r.ptr[2] = ib.array[0] + ib.array[1];
        r.ptr[3] = ib.array[2] + ib.array[3];
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

/// Horizontally add adjacent pairs of 16-bit integers in `a` and `b`, and pack the signed 16-bit results.
__m64 _mm_hadd_pi16 (__m64 a, __m64 b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m64) __builtin_ia32_phaddw(cast(short4)a, cast(short4)b);
    }
    else static if (LDC_with_ARM64)
    {
        return cast(__m64) vpadd_s16(cast(short4)a, cast(short4)b);
    }
    else
    {
        // LDC x86: generates phaddw since LDC 1.24 -O2.
        short4 r;
        short4 sa = cast(short4)a;
        short4 sb = cast(short4)b;
        r.ptr[0] = cast(short)(sa.array[0] + sa.array[1]); 
        r.ptr[1] = cast(short)(sa.array[2] + sa.array[3]);
        r.ptr[2] = cast(short)(sb.array[0] + sb.array[1]);
        r.ptr[3] = cast(short)(sb.array[2] + sb.array[3]);
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi16(1, -2, 4, 8);
    __m64 B = _mm_setr_pi16(16, 32, -1, -32768);
    short4 C = cast(short4) _mm_hadd_pi16(A, B);
    short[4] correct = [ -1, 12, 48, 32767 ];
    assert(C.array == correct);
}


__m64 _mm_hadd_pi32 (__m64 a, __m64 b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m64) __builtin_ia32_phaddd(cast(int2)a, cast(int2)b);
    }
    else static if (LDC_with_ARM64)
    {
        return cast(__m64)vpadd_s32(cast(int2)a, cast(int2)b);
    }
    else
    {
        // LDC x86: generates phaddd since LDC 1.24 -O2
        int2 ia = cast(int2)a;
        int2 ib = cast(int2)b;
        int2 r;
        r.ptr[0] = ia.array[0] + ia.array[1];
        r.ptr[1] = ib.array[0] + ib.array[1];
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi32(int.min, -1);
    __m64 B = _mm_setr_pi32(1, int.max);
    int2 C = cast(int2) _mm_hadd_pi32(A, B);
    int[2] correct = [ int.max, int.min ];
    assert(C.array == correct);
}

/// Horizontally add adjacent pairs of signed 16-bit integers in `a` and `b` using saturation, 
/// and pack the signed 16-bit results.
__m128i _mm_hadds_epi16 (__m128i a, __m128i b) @trusted
{
     // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phaddsw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phaddsw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_ARM64)
    {
        // uzp1/uzp2/sqadd sequence
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 c = shufflevector!(short8, 0, 2, 4, 6, 8, 10, 12, 14)(sa, sb);
        short8 d = shufflevector!(short8, 1, 3, 5, 7, 9, 11, 13, 15)(sa, sb);
        return cast(__m128i)vqaddq_s16(c, d);
    }
    else
    {
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 r;
        r.ptr[0] = saturateSignedIntToSignedShort(sa.array[0] + sa.array[1]);
        r.ptr[1] = saturateSignedIntToSignedShort(sa.array[2] + sa.array[3]);
        r.ptr[2] = saturateSignedIntToSignedShort(sa.array[4] + sa.array[5]);
        r.ptr[3] = saturateSignedIntToSignedShort(sa.array[6] + sa.array[7]);
        r.ptr[4] = saturateSignedIntToSignedShort(sb.array[0] + sb.array[1]);
        r.ptr[5] = saturateSignedIntToSignedShort(sb.array[2] + sb.array[3]);
        r.ptr[6] = saturateSignedIntToSignedShort(sb.array[4] + sb.array[5]);
        r.ptr[7] = saturateSignedIntToSignedShort(sb.array[6] + sb.array[7]);
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(1, -2, 4, 8, 16, 32, -1, -32768);
    short8 C = cast(short8) _mm_hadds_epi16(A, A);
    short[8] correct = [ -1, 12, 48, -32768, -1, 12, 48, -32768];
    assert(C.array == correct);
}

/// Horizontally add adjacent pairs of signed 16-bit integers in `a` and `b` using saturation, 
/// and pack the signed 16-bit results.
__m64 _mm_hadds_pi16 (__m64 a, __m64 b)
{
    static if (GDC_with_SSSE3)
    {
        return cast(__m64)__builtin_ia32_phaddsw(cast(short4)a, cast(short4)b);
    }
    else static if (LDC_with_SSSE3)
    {
        // Note: LDC doesn't have __builtin_ia32_phaddsw
        long2 la;
        la.ptr[0] = a.array[0];
        long2 lb;
        lb.ptr[0] = b.array[0];
        int4 sum = cast(int4)__builtin_ia32_phaddsw128(cast(short8)la, cast(short8)lb);
        int2 r;
        r.ptr[0] = sum.array[0];
        r.ptr[1] = sum.array[2];
        return cast(__m64)r;
    }
    else static if (LDC_with_ARM64)
    {
        // uzp1/uzp2/sqadd sequence
        short4 sa = cast(short4)a;
        short4 sb = cast(short4)b;
        short4 c = shufflevector!(short4, 0, 2, 4, 6)(sa, sb);
        short4 d = shufflevector!(short4, 1, 3, 5, 7)(sa, sb);
        return cast(__m64)vqadd_s16(c, d);
    }
    else
    {
        short4 sa = cast(short4)a;
        short4 sb = cast(short4)b;
        short4 r;
        r.ptr[0] = saturateSignedIntToSignedShort(sa.array[0] + sa.array[1]);
        r.ptr[1] = saturateSignedIntToSignedShort(sa.array[2] + sa.array[3]);
        r.ptr[2] = saturateSignedIntToSignedShort(sb.array[0] + sb.array[1]);
        r.ptr[3] = saturateSignedIntToSignedShort(sb.array[2] + sb.array[3]);
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi16(-16, 32, -100, -32768);
    __m64 B = _mm_setr_pi16( 64, 32,    1,  32767);
    short4 C = cast(short4) _mm_hadds_pi16(A, B);
    short[4] correct = [ 16, -32768,  96,  32767];
    assert(C.array == correct);
}


/// Horizontally add adjacent pairs of 16-bit integers in `a` and `b`, and pack the signed 16-bit results.
__m128i _mm_hsub_epi16 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phsubw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phsubw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_ARM64)
    {
        // Produce uzp1 uzp2 sub sequence since LDC 1.8 -O1 
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 c = shufflevector!(short8, 0, 2, 4, 6, 8, 10, 12, 14)(sa, sb);
        short8 d = shufflevector!(short8, 1, 3, 5, 7, 9, 11, 13, 15)(sa, sb);
        return cast(__m128i)(c - d);
    }
    else 
    {
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 r;
        r.ptr[0] = cast(short)(sa.array[0] - sa.array[1]);
        r.ptr[1] = cast(short)(sa.array[2] - sa.array[3]);
        r.ptr[2] = cast(short)(sa.array[4] - sa.array[5]);
        r.ptr[3] = cast(short)(sa.array[6] - sa.array[7]);
        r.ptr[4] = cast(short)(sb.array[0] - sb.array[1]);
        r.ptr[5] = cast(short)(sb.array[2] - sb.array[3]);
        r.ptr[6] = cast(short)(sb.array[4] - sb.array[5]);
        r.ptr[7] = cast(short)(sb.array[6] - sb.array[7]);
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(short.min, 1, 4, 8, 16, 32, 1, -32768);
    short8 C = cast(short8) _mm_hsub_epi16(A, A);
    short[8] correct = [ short.max, -4, -16, -32767, short.max, -4, -16, -32767];
    assert(C.array == correct);
}

/// Horizontally add adjacent pairs of 32-bit integers in `a` and `b`, and pack the signed 32-bit results.
__m128i _mm_hsub_epi32 (__m128i a, __m128i b) @trusted
{ 
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phsubd128(cast(int4)a, cast(int4)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phsubd128(cast(int4)a, cast(int4)b);
    }
    else static if (LDC_with_ARM64)
    {
        // Produce uzp1 uzp2 sub sequence since LDC 1.8 -O1 
        int4 ia = cast(int4)a;
        int4 ib = cast(int4)b;
        int4 c = shufflevector!(int4, 0, 2, 4, 6)(ia, ib);
        int4 d = shufflevector!(int4, 1, 3, 5, 7)(ia, ib);
        return cast(__m128i)(c - d);
    }
    else
    {
        int4 ia = cast(int4)a;
        int4 ib = cast(int4)b;
        int4 r;
        r.ptr[0] = ia.array[0] - ia.array[1];
        r.ptr[1] = ia.array[2] - ia.array[3];
        r.ptr[2] = ib.array[0] - ib.array[1];
        r.ptr[3] = ib.array[2] - ib.array[3];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(1, 2, int.min, 1);
    __m128i B = _mm_setr_epi32(int.max, -1, 4, 4);
    int4 C = cast(int4) _mm_hsub_epi32(A, B);
    int[4] correct = [ -1, int.max, int.min, 0 ];
    assert(C.array == correct);
}

__m64 _mm_hsub_pi16 (__m64 a, __m64 b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m64)__builtin_ia32_phsubw(cast(short4)a, cast(short4)b);
    }
    else static if (LDC_with_ARM64)
    {
        // Produce uzp1 uzp2 sub sequence since LDC 1.3 -O1 
        short4 sa = cast(short4)a;
        short4 sb = cast(short4)b;
        short4 c = shufflevector!(short4, 0, 2, 4, 6)(sa, sb);
        short4 d = shufflevector!(short4, 1, 3, 5, 7)(sa, sb);
        return cast(__m64)(c - d);
    }
    else
    {
        // LDC x86: generates phsubw since LDC 1.24 -O2
        short4 sa = cast(short4)a;
        short4 sb = cast(short4)b;
        short4 r;
        r.ptr[0] = cast(short)(sa.array[0] - sa.array[1]);
        r.ptr[1] = cast(short)(sa.array[2] - sa.array[3]);
        r.ptr[2] = cast(short)(sb.array[0] - sb.array[1]);
        r.ptr[3] = cast(short)(sb.array[2] - sb.array[3]);
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi16(short.min, 1, 4, 8);
    __m64 B = _mm_setr_pi16(16, 32, 1, -32768);
    short4 C = cast(short4) _mm_hsub_pi16(A, B);
    short[4] correct = [ short.max, -4, -16, -32767];
    assert(C.array == correct);
}

__m64 _mm_hsub_pi32 (__m64 a, __m64 b)
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m64)__builtin_ia32_phsubd(cast(int2)a, cast(int2)b);
    }
    else static if (LDC_with_ARM64)
    {
        // LDC arm64: generates zip1+zip2+sub sequence since LDC 1.8 -O1
        int2 ia = cast(int2)a;
        int2 ib = cast(int2)b;
        int2 c = shufflevector!(int2, 0, 2)(ia, ib);
        int2 d = shufflevector!(int2, 1, 3)(ia, ib);
        return cast(__m64)(c - d);
    }
    else
    {
        // LDC x86: generates phsubd since LDC 1.24 -O2
        int2 ia = cast(int2)a;
        int2 ib = cast(int2)b;
        int2 r;
        r.ptr[0] = ia.array[0] - ia.array[1];
        r.ptr[1] = ib.array[0] - ib.array[1];
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi32(int.min, 1);
    __m64 B = _mm_setr_pi32(int.max, -1);
    int2 C = cast(int2) _mm_hsub_pi32(A, B);
    int[2] correct = [ int.max, int.min ];
    assert(C.array == correct);
}

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

/// Shuffle packed 8-bit integers in `a` according to shuffle control mask in the corresponding 8-bit element of `b`.
__m128i _mm_shuffle_epi8 (__m128i a, __m128i b) @trusted
{
    // This is the lovely pshufb.
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_pshufb128(cast(byte16) a, cast(byte16) b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_pshufb128(cast(byte16) a, cast(byte16) b);
    }
    else static if (LDC_with_ARM64)
    {
        byte16 bb = cast(byte16)b;
        byte16 mask;
        mask = cast(byte)(0x8F);
        bb = bb & mask;
        byte16 r = vqtbl1q_s8(cast(byte16)a, bb);
        return cast(__m128i)r;
    }
    else
    {
        byte16 r;
        byte16 ba = cast(byte16)a;
        byte16 bb = cast(byte16)b;
        for (int i = 0; i < 16; ++i)
        {
            byte s = bb.array[i];
            r.ptr[i] = (s < 0) ? 0 : ba.array[ s & 15 ];
        }
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(15,   14,      13,  12, 11,  10, 9, 8, 7, 6,  5,  4,  3,  2,  1,  0);
    __m128i B = _mm_setr_epi8(15, -128, 13 + 16, -12, 11, -10, 9, 8, 7, 6, -5,  4,  3, -2,  1,  0);
    byte16 C = cast(byte16) _mm_shuffle_epi8(A, B);
    byte[16] correct =         [0,   0,       2,  0,  4,   0, 6, 7, 8, 9,  0, 11, 12,  0, 14, 15];
    assert(C.array == correct);
}

/// Shuffle packed 8-bit integers in `a` according to shuffle control mask in the corresponding 8-bit element of `b`.
__m64 _mm_shuffle_pi8 (__m64 a, __m64 b)
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        alias ubyte8  =__vector(ubyte[8]);
        return cast(__m64) __builtin_ia32_pshufb(cast(ubyte8) a, cast(ubyte8) b);
    }
    else static if (LDC_with_SSSE3)
    {
        // GDC does proper dance to avoid mmx registers, do it manually in LDC since __builtin_ia32_pshufb doesn't exist there
        __m128i A = to_m128i(a);
        __m128i index = to_m128i(b);
        index = index & _mm_set1_epi32(0xF7F7F7F7);
        return to_m64( cast(__m128i) __builtin_ia32_pshufb128(cast(byte16)A, cast(byte16) index) );
    }
    else static if (LDC_with_ARM64)
    {
        byte8 bb = cast(byte8)b;
        byte8 mask;
        mask = cast(byte)(0x87);
        bb = bb & mask;
        __m128i l = to_m128i(a);
        byte8 r = vtbl1_s8(cast(byte16)l, cast(byte8)bb);
        return cast(__m64)r;
    }
    else
    {
        byte8 r;
        byte8 ba = cast(byte8)a;
        byte8 bb = cast(byte8)b;
        for (int i = 0; i < 8; ++i)
        {
            byte s = bb.array[i];
            r.ptr[i] = (s < 0) ? 0 : ba.array[ s & 7 ];
        }
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi8(7,  6,  5,  4,      3,  2,  1,  0);
    __m64 B = _mm_setr_pi8(7,  6, -5,  4,  3 + 8, -2,  1,  0);
    byte8 C = cast(byte8) _mm_shuffle_pi8(A, B);
    byte[8] correct =    [0,  1,  0,  3,      4,  0,  6,  7];
    assert(C.array == correct);
}

/// Negate packed 16-bit integers in `a` when the corresponding signed 16-bit integer in `b` is negative.
/// Elements in result are zeroed out when the corresponding element in `b` is zero.
__m128i _mm_sign_epi16 (__m128i a, __m128i b)
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_psignw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_psignw128(cast(short8)a, cast(short8)b);       
    }
    else
    {
        // LDC arm64: 5 instructions
        __m128i mask = _mm_srai_epi16(b, 15);
        __m128i zeromask = _mm_cmpeq_epi16(b, _mm_setzero_si128());
        return _mm_andnot_si128(zeromask, _mm_xor_si128(_mm_add_epi16(a, mask), mask));
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-2, -1, 0, 1,  2, short.min, short.min, short.min);
    __m128i B = _mm_setr_epi16(-1,  0,-1, 1, -2,       -50,         0,        50);
    short8 C = cast(short8) _mm_sign_epi16(A, B);
    short[8] correct =        [ 2,  0, 0, 1, -2, short.min,         0, short.min];
    assert(C.array == correct);
}

/// Negate packed 32-bit integers in `a` when the corresponding signed 32-bit integer in `b` is negative. 
/// Elements in result are zeroed out when the corresponding element in `b` is zero.
__m128i _mm_sign_epi32 (__m128i a, __m128i b)
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_psignd128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_psignd128(cast(short8)a, cast(short8)b);
    }
    else
    {
        __m128i mask = _mm_srai_epi32(b, 31);
        __m128i zeromask = _mm_cmpeq_epi32(b, _mm_setzero_si128());
        return _mm_andnot_si128(zeromask, _mm_xor_si128(_mm_add_epi32(a, mask), mask));
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(-2, -1,  0, int.max);
    __m128i B = _mm_setr_epi32(-1,  0, -1, 1);
    int4 C = cast(int4) _mm_sign_epi32(A, B);
    int[4] correct =          [ 2,  0, 0, int.max];
    assert(C.array == correct);
}

/// Negate packed 8-bit integers in `a` when the corresponding signed 8-bit integer in `b` is negative. 
/// Elements in result are zeroed out when the corresponding element in `b` is zero.
__m128i _mm_sign_epi8 (__m128i a, __m128i b)
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_psignb128(cast(byte16)a, cast(byte16)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_psignb128(cast(byte16)a, cast(byte16)b);
    }
    else
    {
        __m128i mask = _mm_cmplt_epi8(b, _mm_setzero_si128()); // extend sign bit
        __m128i zeromask = _mm_cmpeq_epi8(b, _mm_setzero_si128());
        return _mm_andnot_si128(zeromask, _mm_xor_si128(_mm_add_epi8(a, mask), mask));
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(-2, -1, 0, 1,  2, byte.min, byte.min, byte.min, -1,  0,-1, 1, -2,      -50,        0,       50);
    __m128i B = _mm_setr_epi8(-1,  0,-1, 1, -2,      -50,        0,       50, -2, -1, 0, 1,  2, byte.min, byte.min, byte.min);
    byte16  C = cast(byte16) _mm_sign_epi8(A, B);
    byte[16] correct =       [ 2,  0, 0, 1, -2, byte.min,        0, byte.min,  1,  0, 0, 1, -2,       50,        0,      -50];
    assert(C.array == correct);
}

/// Negate packed 16-bit integers in `a`  when the corresponding signed 16-bit integer in `b` is negative.
/// Element in result are zeroed out when the corresponding element in `b` is zero.
__m64 _mm_sign_pi16 (__m64 a, __m64 b)
{
    return to_m64( _mm_sign_epi16( to_m128i(a), to_m128i(b)) );
}
unittest
{
    __m64 A = _mm_setr_pi16( 2, short.min, short.min, short.min);
    __m64 B = _mm_setr_pi16(-2,       -50,         0,        50);
    short4 C = cast(short4) _mm_sign_pi16(A, B);
    short[4] correct =     [-2, short.min,         0, short.min];
    assert(C.array == correct);
}

/// Negate packed 32-bit integers in `a`  when the corresponding signed 32-bit integer in `b` is negative.
/// Element in result are zeroed out when the corresponding element in `b` is zero.
__m64 _mm_sign_pi32 (__m64 a, __m64 b)
{
    return to_m64( _mm_sign_epi32( to_m128i(a), to_m128i(b)) );
}
unittest
{
    __m64 A = _mm_setr_pi32(-2, -100);
    __m64 B = _mm_setr_pi32(-1,  0);
    int2 C = cast(int2) _mm_sign_pi32(A, B);
    int[2] correct =          [ 2,  0];
    assert(C.array == correct);
}

/// Negate packed 8-bit integers in `a` when the corresponding signed 8-bit integer in `b` is negative. 
/// Elements in result are zeroed out when the corresponding element in `b` is zero.
__m64 _mm_sign_pi8 (__m64 a, __m64 b)
{
    return to_m64( _mm_sign_epi8( to_m128i(a), to_m128i(b)) );
}
unittest
{
    __m64 A = _mm_setr_pi8(-2, -1, 0, 1,  2, byte.min, byte.min, byte.min);
    __m64 B = _mm_setr_pi8(-1,  0,-1, 1, -2,      -50,        0,       50);
    byte8  C = cast(byte8) _mm_sign_pi8(A, B);
    byte[8] correct =     [ 2,  0, 0, 1, -2, byte.min,        0, byte.min];
    assert(C.array == correct);
}



/*


Note: LDC 1.0 to 1.27 have the following builtins:

pragma(LDC_intrinsic, "llvm.x86.ssse3.phadd.sw.128")
    short8 __builtin_ia32_phaddsw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.phsub.sw.128")
    short8 __builtin_ia32_phsubsw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.pmadd.ub.sw.128")
    short8 __builtin_ia32_pmaddubsw128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.ssse3.pmul.hr.sw.128")
    short8 __builtin_ia32_pmulhrsw128(short8, short8) pure @safe;

*/