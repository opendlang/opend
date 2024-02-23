/**
* SSSE3 intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=SSSE3
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
// With GDC, use "dflags-gdc": ["-mssse3"] or equivalent to generate SSSE3 instructions.

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
    else static if (LDC_with_optimizations)
    {
        // LDC x86: generates pabsb since LDC 1.1 -O1
        //     arm64: generates abs since LDC 1.8 -O1
        enum ir = `
                %n = sub <16 x i8> <i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0>, %0
                %s = icmp slt <16 x i8> <i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0, i8 0>, %0
                %r = select <16 x i1> %s, <16 x i8> %0, <16 x i8> %n
                ret <16 x i8> %r`;
        return cast(__m128i) LDCInlineIR!(ir, byte16, byte16)(cast(byte16)a);
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

/// Compute the absolute value of packed 64-bit floating-point elements in `a`.
/// #BONUS.
__m128d _mm_abs_pd (__m128d a) @trusted
{
    long2 mask = 0x7fff_ffff_ffff_ffff;
    return cast(__m128d)((cast(long2)a) & mask);
}
unittest
{
    __m128d A = _mm_setr_pd(-42.0f, -double.infinity);
    __m128d R = _mm_abs_pd(A);
    double[2] correct =    [42.0f, +double.infinity];
    assert(R.array == correct);
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

/// Compute the absolute value of packed 32-bit floating-point elements in `a`.
/// #BONUS.
__m128 _mm_abs_ps (__m128 a) @trusted
{
    __m128i mask = 0x7fffffff;
    return cast(__m128)((cast(__m128i)a) & mask);
}
unittest
{
    __m128 A = _mm_setr_ps(-0.0f, 10.0f, -42.0f, -float.infinity);
    __m128 R = _mm_abs_ps(A);
    float[4] correct =    [0.0f, 10.0f, 42.0f, +float.infinity];
    assert(R.array == correct);
}

/// Concatenate 16-byte blocks in `a` and `b` into a 32-byte temporary result, shift the result right by `count` bytes, and return the low 16 bytes.
__m128i _mm_alignr_epi8(ubyte count)(__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_palignr128(cast(long2)a, cast(long2)b, count * 8);
    }
    else version(LDC)
    {
        static if (count >= 32)
        {
            return _mm_setzero_si128();
        }
        else static if (count < 16)
        {
            // Generates palignr since LDC 1.1 -O1
            // Also generates a single ext instruction on arm64.
            return cast(__m128i) shufflevectorLDC!(byte16, ( 0 + count),
                                                        ( 1 + count),
                                                        ( 2 + count),
                                                        ( 3 + count),
                                                        ( 4 + count),
                                                        ( 5 + count),
                                                        ( 6 + count),
                                                        ( 7 + count),
                                                        ( 8 + count),
                                                        ( 9 + count),
                                                        (10 + count),
                                                        (11 + count),
                                                        (12 + count),
                                                        (13 + count),
                                                        (14 + count),
                                                        (15 + count))(cast(byte16)b, cast(byte16)a);
        }
        else
        {
            return cast(__m128i) shufflevectorLDC!(byte16, ( 0 + count) % 32,
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
                                                        (15 + count) % 32)(cast(byte16)_mm_setzero_si128(), cast(byte16)a);
        }
    }
    else
    {
        byte16 ab = cast(byte16)a;
        byte16 bb = cast(byte16)b;
        byte16 r;

        for (int i = 0; i < 16; ++i)
        {
            const int srcpos = count + cast(int)i;
            if (srcpos > 31) 
            {
                r.ptr[i] = 0;
            } 
            else if (srcpos > 15) 
            {
                r.ptr[i] = ab.array[(srcpos) & 15];
            } 
            else 
            {
                r.ptr[i] = bb.array[srcpos];
            }
       }
       return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
    __m128i B = _mm_setr_epi8(17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32);

    {
        byte16 C = cast(byte16)_mm_alignr_epi8!0(A ,B);
        byte[16] correct = [17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32];
        assert(C.array == correct);
    }
    {
        byte16 C = cast(byte16)_mm_alignr_epi8!20(A ,B);
        byte[16] correct = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 0, 0, 0, 0];
        assert(C.array == correct);
    }
    {
        byte16 C = cast(byte16)_mm_alignr_epi8!34(A ,B);
        byte[16] correct = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        assert(C.array == correct);
    }

    __m128i D = _mm_setr_epi8(-123, -82, 103, -69, 103, -26, 9, 106, 58, -11, 79, -91, 114, -13, 110, 60);
    __m128i E = _mm_setr_epi8(25, -51, -32, 91, -85, -39, -125, 31, -116, 104, 5, -101, 127, 82, 14, 81);
    byte16 F = cast(byte16)_mm_alignr_epi8!8(D, E);
    byte[16] correct = [-116, 104, 5, -101, 127, 82, 14, 81, -123, -82, 103, -69, 103, -26, 9, 106];
    assert(F.array == correct);
}

/// Concatenate 8-byte blocks in `a` and `b` into a 16-byte temporary result, shift the result right by `count` bytes, and return the low 8 bytes.
__m64 _mm_alignr_pi8(ubyte count)(__m64 a, __m64 b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m64)__builtin_ia32_palignr(cast(long1)a, cast(long1)b, count * 8);
    }
    else version(LDC)
    {
        static if (count >= 16)
        {
            return _mm_setzero_si64();
        }
        else static if (count < 8)
        {
            // Note: in LDC x86 this uses a pshufb.
            // Generates ext in arm64.
            return cast(__m64) shufflevectorLDC!(byte8, (0 + count),
                                                     (1 + count),
                                                     (2 + count),
                                                     (3 + count),
                                                     (4 + count),
                                                     (5 + count),
                                                     (6 + count),
                                                     (7 + count))(cast(byte8)b, cast(byte8)a);
        }
        else
        {
            return cast(__m64) shufflevectorLDC!(byte8, (0 + count)%16,
                                                     (1 + count)%16,
                                                     (2 + count)%16,
                                                     (3 + count)%16,
                                                     (4 + count)%16,
                                                     (5 + count)%16,
                                                     (6 + count)%16,
                                                     (7 + count)%16)(cast(byte8)_mm_setzero_si64(), cast(byte8)a);
        }
    }
    else
    {
        byte8 ab = cast(byte8)a;
        byte8 bb = cast(byte8)b;
        byte8 r;

        for (int i = 0; i < 8; ++i)
        {
            const int srcpos = count + cast(int)i;
            if (srcpos > 15) 
            {
                r.ptr[i] = 0;
            } 
            else if (srcpos > 7) 
            {
                r.ptr[i] = ab.array[(srcpos) & 7];
            } 
            else 
            {
                r.ptr[i] = bb.array[srcpos];
            }
       }
       return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi8(1, 2, 3, 4, 5, 6, 7, 8);
    __m64 B = _mm_setr_pi8(17, 18, 19, 20, 21, 22, 23, 24);

    {
        byte8 C = cast(byte8)_mm_alignr_pi8!0(A ,B);
        byte[8] correct = [17, 18, 19, 20, 21, 22, 23, 24];
        assert(C.array == correct);
    }

    {
        byte8 C = cast(byte8)_mm_alignr_pi8!3(A ,B);
        byte[8] correct = [ 20, 21, 22, 23, 24, 1, 2, 3];
        assert(C.array == correct);
    }
    {
        byte8 C = cast(byte8)_mm_alignr_pi8!11(A ,B);
        byte[8] correct = [4, 5, 6, 7, 8, 0, 0, 0];
        assert(C.array == correct);
    }
    {
        byte8 C = cast(byte8)_mm_alignr_pi8!17(A ,B);
        byte[8] correct = [0, 0, 0, 0, 0, 0, 0, 0];
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

/// Horizontally add adjacent pairs of 32-bit integers in `a` and `b`, 
/// and pack the signed 32-bit results.
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
        short8 c = shufflevectorLDC!(short8, 0, 2, 4, 6, 8, 10, 12, 14)(sa, sb);
        short8 d = shufflevectorLDC!(short8, 1, 3, 5, 7, 9, 11, 13, 15)(sa, sb);
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
__m64 _mm_hadds_pi16 (__m64 a, __m64 b) @trusted
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
        short4 c = shufflevectorLDC!(short4, 0, 2, 4, 6)(sa, sb);
        short4 d = shufflevectorLDC!(short4, 1, 3, 5, 7)(sa, sb);
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
        short8 c = shufflevectorLDC!(short8, 0, 2, 4, 6, 8, 10, 12, 14)(sa, sb);
        short8 d = shufflevectorLDC!(short8, 1, 3, 5, 7, 9, 11, 13, 15)(sa, sb);
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
        int4 c = shufflevectorLDC!(int4, 0, 2, 4, 6)(ia, ib);
        int4 d = shufflevectorLDC!(int4, 1, 3, 5, 7)(ia, ib);
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

/// Horizontally subtract adjacent pairs of 16-bit integers in `a` and `b`, 
/// and pack the signed 16-bit results.
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
        short4 c = shufflevectorLDC!(short4, 0, 2, 4, 6)(sa, sb);
        short4 d = shufflevectorLDC!(short4, 1, 3, 5, 7)(sa, sb);
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

/// Horizontally subtract adjacent pairs of 32-bit integers in `a` and `b`, 
/// and pack the signed 32-bit results.
__m64 _mm_hsub_pi32 (__m64 a, __m64 b) @trusted
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
        int2 c = shufflevectorLDC!(int2, 0, 2)(ia, ib);
        int2 d = shufflevectorLDC!(int2, 1, 3)(ia, ib);
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

/// Horizontally subtract adjacent pairs of signed 16-bit integers in `a` and `b` using saturation, 
/// and pack the signed 16-bit results.
__m128i _mm_hsubs_epi16 (__m128i a, __m128i b) @trusted
{
     // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phsubsw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_phsubsw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_ARM64)
    {
        // uzp1/uzp2/sqsub sequence
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 c = shufflevectorLDC!(short8, 0, 2, 4, 6, 8, 10, 12, 14)(sa, sb);
        short8 d = shufflevectorLDC!(short8, 1, 3, 5, 7, 9, 11, 13, 15)(sa, sb);
        return cast(__m128i)vqsubq_s16(c, d);
    }
    else
    {
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 r;
        r.ptr[0] = saturateSignedIntToSignedShort(sa.array[0] - sa.array[1]);
        r.ptr[1] = saturateSignedIntToSignedShort(sa.array[2] - sa.array[3]);
        r.ptr[2] = saturateSignedIntToSignedShort(sa.array[4] - sa.array[5]);
        r.ptr[3] = saturateSignedIntToSignedShort(sa.array[6] - sa.array[7]);
        r.ptr[4] = saturateSignedIntToSignedShort(sb.array[0] - sb.array[1]);
        r.ptr[5] = saturateSignedIntToSignedShort(sb.array[2] - sb.array[3]);
        r.ptr[6] = saturateSignedIntToSignedShort(sb.array[4] - sb.array[5]);
        r.ptr[7] = saturateSignedIntToSignedShort(sb.array[6] - sb.array[7]);
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(1, -2, 4, 8, 32767, -1, -10, 32767);
    short8 C = cast(short8) _mm_hsubs_epi16(A, A);
    short[8] correct = [ 3, -4, 32767, -32768, 3, -4, 32767, -32768 ];
    assert(C.array == correct);
}


/// Horizontally subtract adjacent pairs of signed 16-bit integers in `a` and `b` using saturation, 
/// and pack the signed 16-bit results.
__m64 _mm_hsubs_pi16 (__m64 a, __m64 b) @trusted
{
    static if (GDC_with_SSSE3)
    {
        return cast(__m64)__builtin_ia32_phsubsw(cast(short4)a, cast(short4)b);
    }
    else static if (LDC_with_SSSE3)
    {
        // Note: LDC doesn't have __builtin_ia32_phsubsw
        long2 la;
        la.ptr[0] = a.array[0];
        long2 lb;
        lb.ptr[0] = b.array[0];
        int4 sum = cast(int4)__builtin_ia32_phsubsw128(cast(short8)la, cast(short8)lb);
        int2 r;
        r.ptr[0] = sum.array[0];
        r.ptr[1] = sum.array[2];
        return cast(__m64)r;
    }
    else static if (LDC_with_ARM64)
    {
        // uzp1/uzp2/sqsub sequence in -O1
        short4 sa = cast(short4)a;
        short4 sb = cast(short4)b;
        short4 c = shufflevectorLDC!(short4, 0, 2, 4, 6)(sa, sb);
        short4 d = shufflevectorLDC!(short4, 1, 3, 5, 7)(sa, sb);
        return cast(__m64)vqsub_s16(c, d);
    }
    else
    {
        short4 sa = cast(short4)a;
        short4 sb = cast(short4)b;
        short4 r;
        r.ptr[0] = saturateSignedIntToSignedShort(sa.array[0] - sa.array[1]);
        r.ptr[1] = saturateSignedIntToSignedShort(sa.array[2] - sa.array[3]);
        r.ptr[2] = saturateSignedIntToSignedShort(sb.array[0] - sb.array[1]);
        r.ptr[3] = saturateSignedIntToSignedShort(sb.array[2] - sb.array[3]);
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi16(-16, 32, 100, -32768);
    __m64 B = _mm_setr_pi16( 64, 30,   -9,  32767);
    short4 C = cast(short4) _mm_hsubs_pi16(A, B);
    short[4] correct = [ -48, 32767,  34,  -32768];
    assert(C.array == correct);
}


/// Vertically multiply each unsigned 8-bit integer from `a` with the corresponding 
/// signed 8-bit integer from `b`, producing intermediate signed 16-bit integers. 
/// Horizontally add adjacent pairs of intermediate signed 16-bit integers, 
/// and pack the saturated results.
__m128i _mm_maddubs_epi16 (__m128i a, __m128i b) @trusted
{
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_pmaddubsw128(cast(ubyte16)a, cast(ubyte16)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i)__builtin_ia32_pmaddubsw128(cast(byte16)a, cast(byte16)b);
    }
    else
    {
        // zero-extend a to 16-bit
        __m128i zero = _mm_setzero_si128();
        __m128i a_lo = _mm_unpacklo_epi8(a, zero);
        __m128i a_hi = _mm_unpackhi_epi8(a, zero);

        // sign-extend b to 16-bit
        __m128i b_lo = _mm_unpacklo_epi8(b, zero);
        __m128i b_hi = _mm_unpackhi_epi8(b, zero);    
        b_lo = _mm_srai_epi16( _mm_slli_epi16(b_lo, 8), 8);
        b_hi = _mm_srai_epi16( _mm_slli_epi16(b_hi, 8), 8); 

        // Multiply element-wise, no overflow can occur
        __m128i c_lo = _mm_mullo_epi16(a_lo, b_lo);  
        __m128i c_hi = _mm_mullo_epi16(a_hi, b_hi);

        // Add pairwise with saturating horizontal add
        return _mm_hadds_epi16(c_lo, c_hi);
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(  -1,  10, 100, -128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0); // u8
    __m128i B = _mm_setr_epi8(-128, -30, 100,  127, -1, 2, 4, 6, 0, 0, 0, 0, 0, 0, 0, 0); // i8
    short8 C = cast(short8) _mm_maddubs_epi16(A, B);
    short[8] correct =       [   -32768,     26256, 0, 0, 0, 0, 0, 0];
    assert(C.array == correct);
}

/// Vertically multiply each unsigned 8-bit integer from `a` with the corresponding 
/// signed 8-bit integer from `b`, producing intermediate signed 16-bit integers. 
/// Horizontally add adjacent pairs of intermediate signed 16-bit integers, 
/// and pack the saturated results.
__m64 _mm_maddubs_pi16 (__m64 a, __m64 b) @trusted
{
    static if (GDC_with_SSSE3)
    {
        return cast(__m64)__builtin_ia32_pmaddubsw(cast(ubyte8)a, cast(ubyte8)b);
    }
    else static if (LDC_with_SSSE3)
    {
        __m128i A = to_m128i(a);
        __m128i B = to_m128i(b);
        return to_m64( cast(__m128i)__builtin_ia32_pmaddubsw128(cast(byte16) to_m128i(a), cast(byte16) to_m128i(b)));
    }
    else
    {
        // zero-extend a to 16-bit
        __m128i zero = _mm_setzero_si128();
        __m128i A = _mm_unpacklo_epi8(to_m128i(a), zero);

        // sign-extend b to 16-bit
        __m128i B = _mm_unpacklo_epi8(to_m128i(b), zero);    
        B = _mm_srai_epi16( _mm_slli_epi16(B, 8), 8);

        // Multiply element-wise, no overflow can occur
        __m128i c = _mm_mullo_epi16(A, B);

        // Add pairwise with saturating horizontal add
        return to_m64( _mm_hadds_epi16(c, zero));
    }
}
unittest
{
    __m64 A = _mm_setr_pi8(  -1,  10, 100, -128, 0, 0, 0, 0); // u8
    __m64 B = _mm_setr_pi8(-128, -30, 100,  127, -1, 2, 4, 6); // i8
    short4 C = cast(short4) _mm_maddubs_pi16(A, B);
    short[4] correct =       [   -32768,   26256, 0, 0];
    assert(C.array == correct);
}

/// Multiply packed signed 16-bit integers in `a` and `b`, producing intermediate signed 32-bit integers.
/// Truncate each intermediate integer to the 18 most significant bits, round by adding 1, and return bits `[16:1]`.
__m128i _mm_mulhrs_epi16 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_pmulhrsw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_pmulhrsw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_ARM64)
    {
        int4 mul_lo = vmull_s16(vget_low_s16(cast(short8)a),
                                vget_low_s16(cast(short8)b));
        int4 mul_hi = vmull_s16(vget_high_s16(cast(short8)a),
                                vget_high_s16(cast(short8)b));

        // Rounding narrowing shift right
        // narrow = (int16_t)((mul + 16384) >> 15);
        short4 narrow_lo = vrshrn_n_s32(mul_lo, 15);
        short4 narrow_hi = vrshrn_n_s32(mul_hi, 15);

        // Join together.
        return cast(__m128i) vcombine_s16(narrow_lo, narrow_hi);
    }
    else
    {
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 r;

        for (int i = 0; i < 8; ++i)
        {
            // I doubted it at first, but an exhaustive search show this to be equivalent to Intel pseudocode.
            r.ptr[i] = cast(short) ( (sa.array[i] * sb.array[i] + 0x4000) >> 15);
        }

        return cast(__m128i)r;
    }
}

unittest
{
    __m128i A = _mm_setr_epi16(12345, -32768, 32767, 0, 1, 845, -6999, -1);
    __m128i B = _mm_setr_epi16(8877, -24487, 15678, 32760, 1, 0, -149, -1);
    short8 C = cast(short8) _mm_mulhrs_epi16(A, B);
    short[8] correct = [3344, 24487, 15678, 0, 0, 0, 32, 0];
    assert(C.array == correct);
}

/// Multiply packed signed 16-bit integers in `a` and `b`, producing intermediate signed 32-bit integers.
/// Truncate each intermediate integer to the 18 most significant bits, round by adding 1, and return bits `[16:1]`.
__m64 _mm_mulhrs_pi16 (__m64 a, __m64 b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m64) __builtin_ia32_pmulhrsw(cast(short4)a, cast(short4)b);
    }
    else static if (LDC_with_SSSE3)
    {
        return cast(__m64) to_m64( cast(__m128i) __builtin_ia32_pmulhrsw128(cast(short8) to_m128i(a), cast(short8) to_m128i(b)));
    }
    else static if (LDC_with_ARM64)
    {
        int4 mul = vmull_s16(cast(short4)a, cast(short4)b);

        // Rounding narrowing shift right
        // (int16_t)((mul + 16384) >> 15);
        return cast(__m64) vrshrn_n_s32(mul, 15);
    }
    else
    {
        short4 sa = cast(short4)a;
        short4 sb = cast(short4)b;
        short4 r;

        for (int i = 0; i < 4; ++i)
        {
            r.ptr[i] = cast(short) ( (sa.array[i] * sb.array[i] + 0x4000) >> 15);
        }
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi16(12345, -32768, 32767, 0);
    __m64 B = _mm_setr_pi16(8877, -24487, 15678, 32760);
    short4 C = cast(short4) _mm_mulhrs_pi16(A, B);
    short[4] correct = [3344, 24487, 15678, 0];
    assert(C.array == correct);
}


/// Shuffle packed 8-bit integers in `a` according to shuffle control mask in the corresponding 8-bit element of `b`.
__m128i _mm_shuffle_epi8 (__m128i a, __m128i b) pure @trusted
{
    // This is the lovely pshufb.
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_pshufb128(cast(ubyte16) a, cast(ubyte16) b);
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
__m64 _mm_shuffle_pi8 (__m64 a, __m64 b) @trusted
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
__m128i _mm_sign_epi16 (__m128i a, __m128i b) @trusted
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
__m128i _mm_sign_epi32 (__m128i a, __m128i b) @trusted
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
__m128i _mm_sign_epi8 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSSE3)
    {
        return cast(__m128i) __builtin_ia32_psignb128(cast(ubyte16)a, cast(ubyte16)b);
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
__m64 _mm_sign_pi16 (__m64 a, __m64 b) @trusted
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
__m64 _mm_sign_pi32 (__m64 a, __m64 b) @trusted
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
__m64 _mm_sign_pi8 (__m64 a, __m64 b) @trusted
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
