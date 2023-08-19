/**
* SSE4.1 intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=SSE4_1
*
* Copyright: Guillaume Piolat 2021.
*            Johan Engelen 2021.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.smmintrin;

// SSE4.1 instructions
// https://software.intel.com/sites/landingpage/IntrinsicsGuide/#techs=SSE4_1
// Note: this header will work whether you have SSE4.1 enabled or not.
// With LDC, use "dflags-ldc": ["-mattr=+sse4.1"] or equivalent to actively
// generate SSE4.1 instructions.
// With GDC, use "dflags-gdc": ["-msse4.1"] or equivalent to generate SSE4.1 instructions.

public import inteli.types;
import inteli.internals;

// smmintrin pulls in all previous instruction set intrinsics.
public import inteli.tmmintrin;

nothrow @nogc:

enum int _MM_FROUND_TO_NEAREST_INT = 0x00; /// SSE4.1 rounding modes
enum int _MM_FROUND_TO_NEG_INF     = 0x01; /// ditto
enum int _MM_FROUND_TO_POS_INF     = 0x02; /// ditto
enum int _MM_FROUND_TO_ZERO        = 0x03; /// ditto
enum int _MM_FROUND_CUR_DIRECTION  = 0x04; /// ditto
enum int _MM_FROUND_RAISE_EXC      = 0x00; /// ditto
enum int _MM_FROUND_NO_EXC         = 0x08; /// ditto

enum int _MM_FROUND_NINT      = (_MM_FROUND_RAISE_EXC | _MM_FROUND_TO_NEAREST_INT);
enum int _MM_FROUND_FLOOR     = (_MM_FROUND_RAISE_EXC | _MM_FROUND_TO_NEG_INF);
enum int _MM_FROUND_CEIL      = (_MM_FROUND_RAISE_EXC | _MM_FROUND_TO_POS_INF);
enum int _MM_FROUND_TRUNC     = (_MM_FROUND_RAISE_EXC | _MM_FROUND_TO_ZERO);
enum int _MM_FROUND_RINT      = (_MM_FROUND_RAISE_EXC | _MM_FROUND_CUR_DIRECTION);
enum int _MM_FROUND_NEARBYINT = (_MM_FROUND_NO_EXC    | _MM_FROUND_CUR_DIRECTION);

/// Blend packed 16-bit integers from `a` and `b` using control mask `imm8`, and store the results.
// Note: changed signature, GDC needs a compile-time value for imm8.
__m128i _mm_blend_epi16(int imm8)(__m128i a, __m128i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        pragma(inline, true); // else wouldn't inline in _mm256_blend_epi16
        return cast(__m128i) __builtin_ia32_pblendw128(cast(short8)a, cast(short8)b, imm8);
    }
    else 
    {
        // LDC x86 This generates pblendw since LDC 1.1 and -O2
        short8 r;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        for (int n = 0; n < 8; ++n)
        {
            r.ptr[n] = (imm8 & (1 << n)) ? sb.array[n] : sa.array[n];
        }
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1,  2,  3,  4,  5,  6,  7);
    __m128i B = _mm_setr_epi16(8, 9, 10, 11, 12, 13, 14, 15);
    short8 C = cast(short8) _mm_blend_epi16!147(A, B); // 10010011
    short[8] correct =        [8, 9,  2,  3, 12,  5,  6, 15];
    assert(C.array == correct);
}


/// Blend packed double-precision (64-bit) floating-point elements from `a` and `b` using control mask `imm8`.
// Note: changed signature, GDC needs a compile-time value for `imm8`.
__m128d _mm_blend_pd(int imm8)(__m128d a, __m128d b) @trusted
{
    static assert(imm8 >= 0 && imm8 < 4);
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(double2) __builtin_ia32_blendpd(cast(double2)a, cast(double2)b, imm8);
    }
    else
    {
        // LDC x86: blendpd since LDC 1.1 -02, uses blendps after LDC 1.12
        double2 r;
        for (int n = 0; n < 2; ++n)
        {
            r.ptr[n] = (imm8 & (1 << n)) ? b.array[n] : a.array[n];
        }
        return cast(__m128d)r;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(0, 1);
    __m128d B = _mm_setr_pd(8, 9);
    double2 C = _mm_blend_pd!2(A, B);
    double[2] correct =    [0, 9];
    assert(C.array == correct);
}


/// Blend packed single-precision (32-bit) floating-point elements from `a` and `b` using control 
/// mask `imm8`.
// Note: changed signature, GDC needs a compile-time value for imm8.
__m128 _mm_blend_ps(int imm8)(__m128 a, __m128 b) pure @trusted
{
    // PERF DMD
    static assert(imm8 >= 0 && imm8 < 16);
    static if (GDC_with_SSE41)
    {
        return __builtin_ia32_blendps(a, b, imm8);
    }
    else version(LDC)
    {
        // LDC x86: generates blendps since LDC 1.1 -O2
        //   arm64: pretty good, two instructions worst case
        return shufflevectorLDC!(float4, (imm8 & 1) ? 4 : 0,
                                         (imm8 & 2) ? 5 : 1,
                                         (imm8 & 4) ? 6 : 2,
                                         (imm8 & 8) ? 7 : 3)(a, b);
    }
    else
    {
        // PERF GDC without SSE4.1 is quite bad
        __m128 r;
        for (int n = 0; n < 4; ++n)
        {
            r.ptr[n] = (imm8 & (1 << n)) ? b.array[n] : a.array[n];
        }
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(0, 1,  2,  3);
    __m128 B = _mm_setr_ps(8, 9, 10, 11);
    float4 C = cast(float4) _mm_blend_ps!13(A, B); // 1101
    float[4] correct =    [8, 1, 10, 11];
    assert(C.array == correct);
}

/// Blend packed 8-bit integers from `a` and `b` using `mask`.
__m128i _mm_blendv_epi8 (__m128i a, __m128i b, __m128i mask) @trusted
{
    // PERF DMD
    /*static if (GDC_with_SSE41)
    {
        // This intrinsic do nothing in GDC 12.
        // TODO report to GDC. No problem in GCC.
        return cast(__m128i) __builtin_ia32_pblendvb128 (cast(ubyte16)a, cast(ubyte16)b, cast(ubyte16)mask);
    }
    else*/
    static if (LDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pblendvb(cast(byte16)a, cast(byte16)b, cast(byte16)mask);
    }
    else static if (LDC_with_ARM64)
    {
        // LDC arm64: two instructions since LDC 1.12 -O2
        byte16 maskSX = vshrq_n_s8(cast(byte16)mask, 7);
        return cast(__m128i) vbslq_s8(maskSX, cast(byte16)b, cast(byte16)a);
    }
    else
    {
        __m128i m = _mm_cmpgt_epi8(_mm_setzero_si128(), mask);
        return _mm_xor_si128(_mm_subs_epu8(_mm_xor_si128(a, b), m), b);
    }
}
unittest
{
    __m128i A = _mm_setr_epi8( 0,  1,  2,  3,  4,  5,  6,  7,  
                               8,  9, 10, 11, 12, 13, 14, 15);
    __m128i B = _mm_setr_epi8(16, 17, 18, 19, 20, 21, 22, 23, 
                              24, 25, 26, 27, 28, 29, 30, 31);
    __m128i M = _mm_setr_epi8( 1, -1,  1,  1, -4,  1, -8,  127,  
                               1,  1, -1, -1,  4,  1,  8, -128);
    byte16 R = cast(byte16) _mm_blendv_epi8(A, B, M);
    byte[16] correct =      [  0, 17,  2,  3, 20,  5, 22,  7,
                               8,  9, 26, 27, 12, 13, 14, 31 ];
    assert(R.array == correct);
}


/// Blend packed double-precision (64-bit) floating-point elements from `a` and `b` using `mask`.
__m128d _mm_blendv_pd (__m128d a, __m128d b, __m128d mask) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE42)
    {
        // PERF Amazingly enough, GCC/GDC generates the blendvpd instruction
        // with -msse4.2 but not -msse4.1.
        // Not sure what is the reason, and there is a replacement sequence.
        // Sounds like a bug.
        return __builtin_ia32_blendvpd(a, b, mask);
    }
    else static if (LDC_with_SSE41)
    {
        return __builtin_ia32_blendvpd(a, b, mask);
    }
    else static if (LDC_with_ARM64)
    {
        long2 shift;
        shift = 63;
        long2 lmask = cast(long2)mask >> shift;
        return cast(__m128d) vbslq_s64(lmask, cast(long2)b, cast(long2)a);
    }
    else
    {
        __m128d r; // PERF =void;
        long2 lmask = cast(long2)mask;
        for (int n = 0; n < 2; ++n)
        {
            r.ptr[n] = (lmask.array[n] < 0) ? b.array[n] : a.array[n];
        }
        return r;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 2.0);
    __m128d B = _mm_setr_pd(3.0, 4.0);
    __m128d M1 = _mm_setr_pd(-3.0, 2.0);
    __m128d R1 = _mm_blendv_pd(A, B, M1);
    double[2] correct1 = [3.0, 2.0];
    assert(R1.array == correct1);

    // Note: wouldn't work with -double.nan, since in some AArch64 archs the NaN sign bit is lost
    // See Issue #78
    __m128d M2 = _mm_setr_pd(double.nan, double.infinity);
    __m128d R2 = _mm_blendv_pd(A, B, M2);
    double[2] correct2 = [1.0, 2.0];
    assert(R2.array == correct2);
}


/// Blend packed single-precision (32-bit) floating-point elements from `a` and `b` using `mask`.
__m128 _mm_blendv_ps (__m128 a, __m128 b, __m128 mask) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return __builtin_ia32_blendvps(a, b, mask);
    }
    else static if (LDC_with_SSE41)
    {
        return __builtin_ia32_blendvps(a, b, mask);
    }
    else static if (LDC_with_ARM64)
    {
        int4 shift;
        shift = 31;
        int4 lmask = cast(int4)mask >> shift;
        return cast(__m128) vbslq_s32(lmask, cast(int4)b, cast(int4)a);
    }
    else
    {
        __m128 r; // PERF =void;
        int4 lmask = cast(int4)mask;
        for (int n = 0; n < 4; ++n)
        {
            r.ptr[n] = (lmask.array[n] < 0) ? b.array[n] : a.array[n];
        }
        return r;
    }
}
unittest
{
    __m128 A  = _mm_setr_ps( 0.0f, 1.0f, 2.0f, 3.0f);
    __m128 B  = _mm_setr_ps( 4.0f, 5.0f, 6.0f, 7.0f);
    __m128 M1 = _mm_setr_ps(-3.0f, 2.0f, 1.0f, -10000.0f);
    __m128 M2 = _mm_setr_ps(float.nan, float.nan, -0.0f, +0.0f);
    __m128 R1 = _mm_blendv_ps(A, B, M1);
    __m128 R2 = _mm_blendv_ps(A, B, M2);
    float[4] correct1 =    [ 4.0f, 1.0f, 2.0f, 7.0f];
    float[4] correct2 =    [ 0.0f, 1.0f, 6.0f, 3.0f];
    assert(R1.array == correct1);

    // Note: wouldn't work with -float.nan, since in some AArch64 archs the NaN sign bit is lost
    // See Issue #78
    assert(R2.array == correct2);
}

/// Round the packed double-precision (64-bit) floating-point elements in `a` up to an integer value, 
/// and store the results as packed double-precision floating-point elements.
__m128d _mm_ceil_pd (__m128d a) @trusted
{
    static if (LDC_with_ARM64)
    {
        // LDC arm64 acceptable since 1.8 -O2
        // Unfortunately x86 intrinsics force a round-trip back to double2
        // ARM neon semantics wouldn't have that
        long2 l = vcvtpq_s64_f64(a);
        double2 r;
        r.ptr[0] = l.array[0];
        r.ptr[1] = l.array[1];
        return r;
    }
    else
    {
        return _mm_round_pd!2(a);
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.3f, -2.12f);
    __m128d B = _mm_setr_pd(53.6f, -2.7f);
    A = _mm_ceil_pd(A);
    B = _mm_ceil_pd(B);
    double[2] correctA = [2.0, -2.0];
    double[2] correctB = [54.0, -2.0];
    assert(A.array == correctA);
    assert(B.array == correctB);
}

/// Round the packed single-precision (32-bit) floating-point elements in `a` up to an integer value, 
/// and store the results as packed single-precision floating-point elements.
__m128 _mm_ceil_ps (__m128 a) @trusted
{
    static if (LDC_with_ARM64)
    {
        // LDC arm64 acceptable since 1.8 -O1
        int4 l = vcvtpq_s32_f32(a);
        float4 r;
        r.ptr[0] = l.array[0];
        r.ptr[1] = l.array[1];
        r.ptr[2] = l.array[2];
        r.ptr[3] = l.array[3];
        return r;
    }
    else
    {
        return _mm_round_ps!2(a);
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.3f, -2.12f, 53.6f, -2.7f);
    __m128 C = _mm_ceil_ps(A);
    float[4] correct = [2.0f, -2.0f, 54.0f, -2.0f];
    assert(C.array == correct);
}

/// Round the lower double-precision (64-bit) floating-point element in `b` up to an integer value, 
/// store the result as a double-precision floating-point element in the lower element of result, 
/// and copy the upper element from `a` to the upper element of dst.
__m128d _mm_ceil_sd (__m128d a, __m128d b) @trusted
{
    static if (LDC_with_ARM64)
    {
        a[0] = vcvtps_s64_f64(b[0]);
        return a;
    }
    else
    {
        return _mm_round_sd!2(a, b);
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.3, -2.12);
    __m128d B = _mm_setr_pd(53.6, -3.7);
    __m128d C = _mm_ceil_sd(A, B);
    double[2] correct = [54.0, -2.12];
    assert(C.array == correct);
}

/// Round the lower single-precision (32-bit) floating-point element in `b` up to an integer value,
/// store the result as a single-precision floating-point element in the lower element of result, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_ceil_ss (__m128 a, __m128 b) @trusted
{
    static if (LDC_with_ARM64)
    {
        a[0] = vcvtps_s32_f32(b[0]);
        return a;
    }
    else
    {
        return _mm_round_ss!2(a, b);
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.3f, -2.12f, -4.5f, 1.1f);
    __m128 B = _mm_setr_ps(53.6f, -3.7f, 8.0f, 7.0f);
    __m128 C = _mm_ceil_ss(A, B);
    float[4] correct = [54.0f, -2.12f, -4.5f, 1.1f];
    assert(C.array == correct);
}

/// Compare packed 64-bit integers in `a` and `b` for equality.
__m128i _mm_cmpeq_epi64 (__m128i a, __m128i b) @trusted
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        version(DigitalMars)
        {
            // DMD doesn't recognize long2 == long2
            long2 la = cast(long2)a;
            long2 lb = cast(long2)b;
            long2 res;
            res.ptr[0] = (la.array[0] == lb.array[0]) ? -1 : 0;
            res.ptr[1] = (la.array[1] == lb.array[1]) ? -1 : 0;
            return cast(__m128i)res;
        }
        else
        {
            return cast(__m128i)(cast(long2)a == cast(long2)b);
        }
    }
    else static if (GDC_with_SSE41)
    {
        return cast(__m128i)__builtin_ia32_pcmpeqq(cast(long2)a, cast(long2)b);
    }
    else version(LDC)
    {
        // LDC x86: generates pcmpeqq since LDC 1.1 -O1
        //     arm64: generates cmeq since LDC 1.8 -O1
        return cast(__m128i) equalMask!long2(cast(long2)a, cast(long2)b);
    }
    else
    {
        // Clever pcmpeqd + pand use with LDC 1.24 -O2
        long2 la = cast(long2)a;
        long2 lb = cast(long2)b;
        long2 res;
        res.ptr[0] = (la.array[0] == lb.array[0]) ? -1 : 0;
        res.ptr[1] = (la.array[1] == lb.array[1]) ? -1 : 0;
        return cast(__m128i)res;
    }
}
unittest
{
    __m128i A = _mm_setr_epi64(-1, -2);
    __m128i B = _mm_setr_epi64(-3, -2);
    __m128i C = _mm_setr_epi64(-1, -4);
    long2 AB = cast(long2) _mm_cmpeq_epi64(A, B);
    long2 AC = cast(long2) _mm_cmpeq_epi64(A, C);
    long[2] correct1 = [0, -1];
    long[2] correct2 = [-1, 0];
    assert(AB.array == correct1);
    assert(AC.array == correct2);
}


/// Sign extend packed 16-bit integers in `a` to packed 32-bit integers.
__m128i _mm_cvtepi16_epi32 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i)__builtin_ia32_pmovsxwd128(cast(short8)a);
    }
    else static if (LDC_with_optimizations)
    {
        // LDC x86: Generates pmovsxwd since LDC 1.1 -O0, also good in arm64
        enum ir = `
            %v = shufflevector <8 x i16> %0,<8 x i16> %0, <4 x i32> <i32 0, i32 1,i32 2, i32 3>
            %r = sext <4 x i16> %v to <4 x i32>
            ret <4 x i32> %r`;
        return cast(__m128d) LDCInlineIR!(ir, int4, short8)(cast(short8)a);
    }
    else
    {
        short8 sa = cast(short8)a;
        int4 r;
        r.ptr[0] = sa.array[0];
        r.ptr[1] = sa.array[1];
        r.ptr[2] = sa.array[2];
        r.ptr[3] = sa.array[3];
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-1, 0, -32768, 32767, 0, 0, 0, 0);
    int4 C = cast(int4) _mm_cvtepi16_epi32(A);
    int[4] correct = [-1, 0, -32768, 32767];
    assert(C.array == correct);
}

/// Sign extend packed 16-bit integers in `a` to packed 64-bit integers.
__m128i _mm_cvtepi16_epi64 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i)__builtin_ia32_pmovsxwq128(cast(short8)a);
    }
    else static if (LDC_with_optimizations)
    {
        // LDC x86: Generates pmovsxwq since LDC 1.1 -O0, also good in arm64
        enum ir = `
            %v = shufflevector <8 x i16> %0,<8 x i16> %0, <2 x i32> <i32 0, i32 1>
            %r = sext <2 x i16> %v to <2 x i64>
            ret <2 x i64> %r`;
        return cast(__m128i) LDCInlineIR!(ir, long2, short8)(cast(short8)a);
    }
    else
    {
        short8 sa = cast(short8)a;
        long2 r;
        r.ptr[0] = sa.array[0];
        r.ptr[1] = sa.array[1];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-32768, 32767, 0, 0, 0, 0, 0, 0);
    long2 C = cast(long2) _mm_cvtepi16_epi64(A);
    long[2] correct = [-32768, 32767];
    assert(C.array == correct);
}

/// Sign extend packed 32-bit integers in `a` to packed 64-bit integers.
__m128i _mm_cvtepi32_epi64 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i)__builtin_ia32_pmovsxdq128(cast(int4)a);
    }
    else static if (LDC_with_optimizations)
    {
        // LDC x86: Generates pmovsxdq since LDC 1.1 -O0, also good in arm64
        enum ir = `
            %v = shufflevector <4 x i32> %0,<4 x i32> %0, <2 x i32> <i32 0, i32 1>
            %r = sext <2 x i32> %v to <2 x i64>
            ret <2 x i64> %r`;
        return cast(__m128i) LDCInlineIR!(ir, long2, int4)(cast(int4)a);
    }
    else
    {
        int4 sa = cast(int4)a;
        long2 r;
        r.ptr[0] = sa.array[0];
        r.ptr[1] = sa.array[1];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(-4, 42, 0, 0);
    long2 C = cast(long2) _mm_cvtepi32_epi64(A);
    long[2] correct = [-4, 42];
    assert(C.array == correct);
}


/// Sign extend packed 8-bit integers in `a` to packed 16-bit integers.
__m128i _mm_cvtepi8_epi16 (__m128i a) pure @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        alias ubyte16 = __vector(ubyte[16]);
        return cast(__m128i)__builtin_ia32_pmovsxbw128(cast(ubyte16)a);
    }
    else static if (LDC_with_optimizations)
    {
        // LDC x86: pmovsxbw generated since LDC 1.1.0 -O0 
        // LDC ARM64: sshll generated since LDC 1.8.0 -O1
        enum ir = `
            %v = shufflevector <16 x i8> %0,<16 x i8> %0, <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
            %r = sext <8 x i8> %v to <8 x i16>
            ret <8 x i16> %r`;
        return cast(__m128i) LDCInlineIR!(ir, short8, byte16)(cast(byte16)a);
    }
    else
    {
        byte16 sa = cast(byte16)a;
        short8 r;
        foreach(n; 0..8)
            r.ptr[n] = sa.array[n];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(127, -128, 1, -1, 0, 2, -4, -8, 0, 0, 0, 0, 0, 0, 0, 0);
    short8 C = cast(short8) _mm_cvtepi8_epi16(A);
    short[8] correct = [127, -128, 1, -1, 0, 2, -4, -8];
    assert(C.array == correct);
}


/// Sign extend packed 8-bit integers in `a` to packed 32-bit integers.
__m128i _mm_cvtepi8_epi32 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        alias ubyte16 = __vector(ubyte[16]);
        return cast(__m128i)__builtin_ia32_pmovsxbd128(cast(ubyte16)a);
    }
    else static if (LDC_with_SSE41 && LDC_with_optimizations)
    {
        // LDC x86: Generates pmovsxbd since LDC 1.1 -O0
        enum ir = `
            %v = shufflevector <16 x i8> %0,<16 x i8> %0, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
            %r = sext <4 x i8> %v to <4 x i32>
            ret <4 x i32> %r`;
        return cast(__m128i) LDCInlineIR!(ir, int4, byte16)(cast(byte16)a);
    }
    else
    {
        // LDC ARM64: this gives the same codegen than a vmovl_s16/vmovl_s8 sequence would
        byte16 sa = cast(byte16)a;
        int4 r;
        r.ptr[0] = sa.array[0];
        r.ptr[1] = sa.array[1];
        r.ptr[2] = sa.array[2];
        r.ptr[3] = sa.array[3];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(127, -128, 1, -1, 0, 2, -4, -8, 0, 0, 0, 0, 0, 0, 0, 0);
    int4 C = cast(int4) _mm_cvtepi8_epi32(A);
    int[4] correct = [127, -128, 1, -1];
    assert(C.array == correct);
}


/// Sign extend packed 8-bit integers in the low 8 bytes of `a` to packed 64-bit integers.
__m128i _mm_cvtepi8_epi64 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        alias ubyte16 = __vector(ubyte[16]);
        return cast(__m128i)__builtin_ia32_pmovsxbq128(cast(ubyte16)a);
    }
    else static if (LDC_with_optimizations)
    {
        // LDC x86: Generates pmovsxbq since LDC 1.1 -O0, 
        // LDC arm64: it's ok since LDC 1.8 -O1
        enum ir = `
            %v = shufflevector <16 x i8> %0,<16 x i8> %0, <2 x i32> <i32 0, i32 1>
            %r = sext <2 x i8> %v to <2 x i64>
            ret <2 x i64> %r`;
        return cast(__m128i) LDCInlineIR!(ir, long2, byte16)(cast(byte16)a);
    }
    else
    {
        byte16 sa = cast(byte16)a;
        long2 r;
        foreach(n; 0..2)
            r.ptr[n] = sa.array[n];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(127, -128, 1, -1, 0, 2, -4, -8, 0, 0, 0, 0, 0, 0, 0, 0);
    long2 C = cast(long2) _mm_cvtepi8_epi64(A);
    long[2] correct = [127, -128];
    assert(C.array == correct);
}


/// Zero extend packed unsigned 16-bit integers in `a` to packed 32-bit integers.
__m128i _mm_cvtepu16_epi32 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pmovzxwd128(cast(short8)a);
    }
    else
    {
        // LDC x86: generates pmovzxwd since LDC 1.12 -O1 also good without SSE4.1
        //     arm64: ushll since LDC 1.12 -O1
        short8 sa = cast(short8)a;
        int4 r;
        r.ptr[0] = cast(ushort)sa.array[0];
        r.ptr[1] = cast(ushort)sa.array[1];
        r.ptr[2] = cast(ushort)sa.array[2];
        r.ptr[3] = cast(ushort)sa.array[3];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-1, 0, -32768, 32767, 0, 0, 0, 0);
    int4 C = cast(int4) _mm_cvtepu16_epi32(A);
    int[4] correct = [65535, 0, 32768, 32767];
    assert(C.array == correct);
}


/// Zero extend packed unsigned 16-bit integers in `a` to packed 64-bit integers.
__m128i _mm_cvtepu16_epi64 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pmovzxwq128(cast(short8)a);
    }
    else static if (LDC_with_ARM64)
    {
        // LDC arm64: a bit shorter than below, in -O2
        short8 sa = cast(short8)a;
        long2 r;
        for(int n = 0; n < 2; ++n)
            r.ptr[n] = cast(ushort)sa.array[n];
        return cast(__m128i)r;
    }
    else
    {
        // LDC x86: generates pmovzxwd since LDC 1.12 -O1 also good without SSE4.1
        short8 sa = cast(short8)a;
        long2 r;
        r.ptr[0] = cast(ushort)sa.array[0];
        r.ptr[1] = cast(ushort)sa.array[1];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-1, 0, -32768, 32767, 0, 0, 0, 0);
    long2 C = cast(long2) _mm_cvtepu16_epi64(A);
    long[2] correct = [65535, 0];
    assert(C.array == correct);
}


/// Zero extend packed unsigned 32-bit integers in `a` to packed 64-bit integers.
__m128i _mm_cvtepu32_epi64 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pmovzxdq128(cast(short8)a);
    }
    else
    {
        // LDC x86: generates pmovzxdq since LDC 1.12 -O1 also good without SSE4.1
        //     arm64: generates ushll since LDC 1.12 -O1
        int4 sa = cast(int4)a;
        long2 r;
        r.ptr[0] = cast(uint)sa.array[0];
        r.ptr[1] = cast(uint)sa.array[1];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(-1, 42, 0, 0);
    long2 C = cast(long2) _mm_cvtepu32_epi64(A);
    long[2] correct = [4294967295, 42];
    assert(C.array == correct);
}


/// Zero extend packed unsigned 8-bit integers in `a` to packed 16-bit integers.
__m128i _mm_cvtepu8_epi16 (__m128i a) pure @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pmovzxbw128(cast(ubyte16)a);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `
            %v = shufflevector <16 x i8> %0,<16 x i8> %0, <8 x i32> <i32 0, i32 1,i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
            %r = zext <8 x i8> %v to <8 x i16>
            ret <8 x i16> %r`;
        return cast(__m128i) LDCInlineIR!(ir, short8, byte16)(cast(byte16)a);
    }
    else
    {
        return _mm_unpacklo_epi8(a, _mm_setzero_si128());
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(127, -128, 1, -1, 0, 2, -4, -8, 0, 0, 0, 0, 0, 0, 0, 0);
    short8 C = cast(short8) _mm_cvtepu8_epi16(A);
    short[8] correct = [127, 128, 1, 255, 0, 2, 252, 248];
    assert(C.array == correct);
}


/// Zero extend packed unsigned 8-bit integers in `a` to packed 32-bit integers.
__m128i _mm_cvtepu8_epi32 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        alias ubyte16 = __vector(ubyte[16]);
        return cast(__m128i) __builtin_ia32_pmovzxbd128(cast(ubyte16)a);
    }
    else static if (LDC_with_ARM64)
    {
        // LDC arm64: a bit better than below in -O2
        byte16 sa = cast(byte16)a;
        int4 r;
        for(int n = 0; n < 4; ++n) 
            r.ptr[n] = cast(ubyte)sa.array[n];
        return cast(__m128i)r;
    }
    else
    {
        // LDC x86: generates pmovzxbd since LDC 1.12 -O1 also good without SSE4.1
        // PERF: catastrophic with GDC without SSE4.1
        byte16 sa = cast(byte16)a;
        int4 r;
        r.ptr[0] = cast(ubyte)sa.array[0];
        r.ptr[1] = cast(ubyte)sa.array[1];
        r.ptr[2] = cast(ubyte)sa.array[2];
        r.ptr[3] = cast(ubyte)sa.array[3];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(127, -128, 1, -1, 0, 2, -4, -8, 0, 0, 0, 0, 0, 0, 0, 0);
    int4 C = cast(int4) _mm_cvtepu8_epi32(A);
    int[4] correct = [127, 128, 1, 255];
    assert(C.array == correct);
}

/// Zero extend packed unsigned 8-bit integers in the low 8 bytes of `a` to packed 64-bit integers.
__m128i _mm_cvtepu8_epi64 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        alias ubyte16 = __vector(ubyte[16]);
        return cast(__m128i)__builtin_ia32_pmovzxbq128(cast(ubyte16)a);
    }
    else static if (LDC_with_ARM64)
    {
        // LDC arm64: this optimizes better than the loop below
        byte16 sa = cast(byte16)a;
        long2 r;
        for (int n = 0; n < 2; ++n)
            r.ptr[n] = cast(ubyte)sa.array[n];
        return cast(__m128i)r;
    }
    else
    {
        // LDC x86: Generates pmovzxbq since LDC 1.1 -O0, a pshufb without SSE4.1
        byte16 sa = cast(byte16)a;
        long2 r;
        r.ptr[0] = cast(ubyte)sa.array[0];
        r.ptr[1] = cast(ubyte)sa.array[1];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(127, -2, 1, -1, 0, 2, -4, -8, 0, 0, 0, 0, 0, 0, 0, 0);
    long2 C = cast(long2) _mm_cvtepu8_epi64(A);
    long[2] correct = [127, 254];
    assert(C.array == correct);
}

/// Conditionally multiply the packed double-precision (64-bit) floating-point elements 
/// in `a` and `b` using the high 4 bits in `imm8`, sum the four products, and conditionally
/// store the sum in dst using the low 4 bits of `imm8`.
__m128d _mm_dp_pd(int imm8)(__m128d a, __m128d b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return __builtin_ia32_dppd(a, b, imm8 & 0x33);
    }
    else static if (LDC_with_SSE41)
    {
        return __builtin_ia32_dppd(a, b, imm8 & 0x33);
    }
    else
    {
        __m128d zero = _mm_setzero_pd();
        __m128d temp = _mm_blend_pd!( (imm8 >>> 4) & 3)(zero, a * b);
        double sum = temp.array[0] + temp.array[1];
        return _mm_blend_pd!(imm8 & 3)(zero, _mm_set1_pd(sum));
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 2.0);
    __m128d B = _mm_setr_pd(4.0, 8.0);
    double2 R1 = _mm_dp_pd!(0x10 + 0x3 + 0x44)(A, B);
    double2 R2 = _mm_dp_pd!(0x20 + 0x1 + 0x88)(A, B);
    double2 R3 = _mm_dp_pd!(0x30 + 0x2 + 0x00)(A, B);
    double[2] correct1 = [ 4.0,  4.0];
    double[2] correct2 = [16.0,  0.0];
    double[2] correct3 = [ 0.0, 20.0];
    assert(R1.array == correct1);
    assert(R2.array == correct2);
    assert(R3.array == correct3);
}

/// Conditionally multiply the packed single-precision (32-bit) floating-point elements 
/// in `a` and `b` using the high 4 bits in `imm8`, sum the four products, 
/// and conditionally store the sum in result using the low 4 bits of `imm8`.
__m128 _mm_dp_ps(int imm8)(__m128 a, __m128 b) @trusted
{
      // PERF DMD
    static if (GDC_with_SSE41)
    {
        return __builtin_ia32_dpps(a, b, cast(ubyte)imm8);
    }
    else static if (LDC_with_SSE41)
    {
        return __builtin_ia32_dpps(a, b, cast(byte)imm8);
    }
    else
    {
        __m128 zero = _mm_setzero_ps();
        __m128 temp = _mm_blend_ps!( (imm8 >>> 4) & 15)(zero, a * b);
        float sum = temp.array[0] + temp.array[1] + temp.array[2] + temp.array[3];
        return _mm_blend_ps!(imm8 & 15)(zero, _mm_set1_ps(sum));
    }        
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 4.0f, 8.0f);
    __m128 B = _mm_setr_ps(9.0f, 7.0f, 5.0f, 3.0f);
    float4 R1 = _mm_dp_ps!(0xf0 + 0xf)(A, B);
    float4 R2 = _mm_dp_ps!(0x30 + 0x5)(A, B);
    float4 R3 = _mm_dp_ps!(0x50 + 0xa)(A, B);
    float[4] correct1 =   [67.0f, 67.0f, 67.0f, 67.0f];
    float[4] correct2 =   [23.0f, 0.0f, 23.0f, 0.0f];
    float[4] correct3 =   [0.0f, 29.0f, 0.0f, 29.0f];
    assert(R1.array == correct1);
    assert(R2.array == correct2);
    assert(R3.array == correct3);
}


/// Extract a 32-bit integer from `a`, selected with `imm8`.
int _mm_extract_epi32 (__m128i a, const int imm8) pure @trusted
{
    return (cast(int4)a).array[imm8 & 3];
}
unittest
{
    __m128i A = _mm_setr_epi32(1, 2, 3, 4);
    assert(_mm_extract_epi32(A, 0) == 1);
    assert(_mm_extract_epi32(A, 1 + 8) == 2);
    assert(_mm_extract_epi32(A, 3 + 4) == 4);
}

/// Extract a 64-bit integer from `a`, selected with `imm8`.
long _mm_extract_epi64 (__m128i a, const int imm8) pure @trusted
{
    long2 la = cast(long2)a;
    return la.array[imm8 & 1];
}
unittest
{
    __m128i A = _mm_setr_epi64(45, -67);
    assert(_mm_extract_epi64(A, 0) == 45);
    assert(_mm_extract_epi64(A, 1) == -67);
    assert(_mm_extract_epi64(A, 2) == 45);
}

/// Extract an 8-bit integer from `a`, selected with `imm8`.
/// Warning: the returned value is zero-extended to 32-bits.
int _mm_extract_epi8 (__m128i a, const int imm8) @trusted
{
    byte16 ba = cast(byte16)a;
    return cast(ubyte) ba.array[imm8 & 15];
}
unittest
{
    __m128i A = _mm_setr_epi8(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, -1, 14, 15);
    assert(_mm_extract_epi8(A, 7) == 7);
    assert(_mm_extract_epi8(A, 13) == 255);
    assert(_mm_extract_epi8(A, 7 + 16) == 7);
}

/// Extract a single-precision (32-bit) floating-point element from `a`, selected with `imm8`.
/// Note: returns a 32-bit $(I integer).
int _mm_extract_ps (__m128 a, const int imm8) @trusted
{
    return (cast(int4)a).array[imm8 & 3];
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, -4.0f);
    assert(_mm_extract_ps(A, 0) == 0x3f800000);
    assert(_mm_extract_ps(A, 1 + 8) == 0x40000000);
    assert(_mm_extract_ps(A, 3 + 4) == cast(int)0xc0800000);
}



/// Round the packed double-precision (64-bit) floating-point elements in `a` down to an 
/// integer value, and store the results as packed double-precision floating-point elements.
__m128d _mm_floor_pd (__m128d a) @trusted
{
    static if (LDC_with_ARM64)
    {
        // LDC arm64 acceptable since 1.8 -O2
        long2 l = vcvtmq_s64_f64(a);
        double2 r;
        r.ptr[0] = l.array[0];
        r.ptr[1] = l.array[1];
        return r;
    }
    else
    {
        return _mm_round_pd!1(a);
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.3f, -2.12f);
    __m128d B = _mm_setr_pd(53.6f, -2.7f);
    A = _mm_floor_pd(A);
    B = _mm_floor_pd(B);
    double[2] correctA = [1.0, -3.0];
    double[2] correctB = [53.0, -3.0];
    assert(A.array == correctA);
    assert(B.array == correctB);
}

/// Round the packed single-precision (32-bit) floating-point elements in `a` down to an 
/// integer value, and store the results as packed single-precision floating-point elements.
__m128 _mm_floor_ps (__m128 a) @trusted
{
    static if (LDC_with_ARM64)
    {
        // LDC arm64 acceptable since 1.8 -O1
        int4 l = vcvtmq_s32_f32(a);
        float4 r;
        r.ptr[0] = l.array[0];
        r.ptr[1] = l.array[1];
        r.ptr[2] = l.array[2];
        r.ptr[3] = l.array[3];
        return r;
    }
    else
    {
        return _mm_round_ps!1(a);
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.3f, -2.12f, 53.6f, -2.7f);
    __m128 C = _mm_floor_ps(A);
    float[4] correct = [1.0f, -3.0f, 53.0f, -3.0f];
    assert(C.array == correct);
}

/// Round the lower double-precision (64-bit) floating-point element in `b` down to an 
/// integer value, store the result as a double-precision floating-point element in the 
/// lower element, and copy the upper element from `a` to the upper element.
__m128d _mm_floor_sd (__m128d a, __m128d b) @trusted
{
    static if (LDC_with_ARM64)
    {
        a[0] = vcvtms_s64_f64(b[0]);
        return a;
    }
    else
    {
        return _mm_round_sd!1(a, b);
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.3, -2.12);
    __m128d B = _mm_setr_pd(-53.1, -3.7);
    __m128d C = _mm_floor_sd(A, B);
    double[2] correct = [-54.0, -2.12];
    assert(C.array == correct);
}

/// Round the lower single-precision (32-bit) floating-point element in `b` down to an
/// integer value, store the result as a single-precision floating-point element in the
/// lower element, and copy the upper 3 packed elements from `a` to the upper elements.
__m128 _mm_floor_ss (__m128 a, __m128 b) @trusted
{
    static if (LDC_with_ARM64)
    {
        a[0] = vcvtms_s32_f32(b[0]);
        return a;
    }
    else
    {
        return _mm_round_ss!1(a, b);
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.3f, -2.12f, -4.5f, 1.1f);
    __m128 B = _mm_setr_ps(-539.3f, -3.7f, 8.0f, 7.0f);
    __m128 C = _mm_floor_ss(A, B);
    float[4] correct = [-540.0f, -2.12f, -4.5f, 1.1f];
    assert(C.array == correct);
}

/// Insert the 32-bit integer `i` into `a` at the location specified by `imm8[1:0]`.
__m128i _mm_insert_epi32 (__m128i a, int i, const int imm8) pure @trusted
{
    // GDC: nothing special to do, pinsrd generated with -O1 -msse4.1
    // LDC x86: psinrd since LDC 1.1 -O2 with -mattr=+sse4.1
    // LDC arm64: ins.s since LDC 1.8 -O2
    int4 ia = cast(int4)a;
    ia.ptr[imm8 & 3] = i;
    return cast(__m128i)ia; 
}
unittest
{
    __m128i A = _mm_setr_epi32(1, 2, 3, 4);
    int4 C = cast(int4) _mm_insert_epi32(A, 5, 2 + 4);
    int[4] result = [1, 2, 5, 4];
    assert(C.array == result);
}

/// Insert the 64-bit integer `i` into `a` at the location specified by `imm8[0]`.
__m128i _mm_insert_epi64 (__m128i a, long i, const int imm8) pure @trusted
{
    // GDC: nothing special to do, psinrq generated with -O1 -msse4.1
    // LDC x86: always do something sensible.
    long2 la = cast(long2)a;
    la.ptr[imm8 & 1] = i;
    return cast(__m128i)la;
}
unittest
{
    __m128i A = _mm_setr_epi64(1, 2);
    long2 C = cast(long2) _mm_insert_epi64(A, 5, 1 + 2);
    long[2] result = [1, 5];
    assert(C.array == result);
}

/// Insert the 8-bit integer `i` into `a` at the location specified by `imm8[2:0]`.
/// Copy a to dst, and insert the lower 8-bit integer from i into dst at the location specified by imm8.
__m128i _mm_insert_epi8 (__m128i a, int i, const int imm8) @trusted
{
    // GDC: nothing special to do, pinsrb generated with -O1 -msse4.1
    // LDC x86: doesn't do pinsrb, maybe it's slower. arm64 also spills to memory.
    byte16 ba = cast(byte16)a;
    ba.ptr[imm8 & 15] = cast(byte)i;
    return cast(__m128i)ba; 
}
unittest
{
    __m128i A = _mm_setr_epi8(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
    byte16 C = cast(byte16) _mm_insert_epi8(A, 30, 4 + 16);
    byte[16] result = [0, 1, 2, 3, 30, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
    assert(C.array == result);
}


/// Warning: of course it does something totally different from `_mm_insert_epi32`!
/// Copy `a` to `tmp`, then insert a single-precision (32-bit) floating-point element from `b` 
/// into `tmp` using the control in `imm8`. Store `tmp` to result using the mask in `imm8[3:0]` 
/// (elements are zeroed out when the corresponding bit is set).
__m128 _mm_insert_ps(int imm8)(__m128 a, __m128 b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return __builtin_ia32_insertps128(a, b, cast(ubyte)imm8);
    }
    else static if (LDC_with_SSE41)
    {
        return __builtin_ia32_insertps128(a, b, cast(byte)imm8);
    }
    else
    {
        float4 tmp2 = a;
        float tmp1 = b.array[(imm8 >> 6) & 3];
        tmp2.ptr[(imm8 >> 4) & 3] = tmp1;
        return _mm_blend_ps!(imm8 & 15)(tmp2, _mm_setzero_ps());
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    __m128 B = _mm_setr_ps(5.0f, 6.0f, 7.0f, 8.0f);
    __m128 C = _mm_insert_ps!(128 + (32 + 16) + 4)(A, B);
    float[4] correct =    [1.0f, 2.0f, 0.0f, 7.0f];
    assert(C.array == correct);
}


/// Compare packed signed 32-bit integers in `a` and `b`, returns packed maximum values.
__m128i _mm_max_epi32 (__m128i a, __m128i b) pure @trusted
{
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pmaxsd128(cast(int4)a, cast(int4)b);
    }
    else version(LDC)
    {
        // x86: pmaxsd since LDC 1.1 -O1
        // ARM: smax.4s since LDC 1.8 -01
        int4 sa = cast(int4)a;
        int4 sb = cast(int4)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            int4 greater = sa > sb;
        else
            int4 greater = greaterMask!int4(sa, sb);
        return cast(__m128i)( (greater & sa) | (~greater & sb) );
    }
    else
    {
        __m128i higher = _mm_cmpgt_epi32(a, b);
        __m128i aTob = _mm_xor_si128(a, b); // a ^ (a ^ b) == b
        __m128i mask = _mm_and_si128(aTob, higher);
        return _mm_xor_si128(b, mask);
    }
}
unittest
{
    int4 R = cast(int4) _mm_max_epi32(_mm_setr_epi32(0x7fffffff, 1, -4, 7),
                                      _mm_setr_epi32(        -4,-8,  9, -8));
    int[4] correct =                               [0x7fffffff, 1,  9,  7];
    assert(R.array == correct);
}

/// Compare packed signed 8-bit integers in `a` and `b`, 
/// and return packed maximum values.
__m128i _mm_max_epi8 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pmaxsb128(cast(ubyte16)a, cast(ubyte16)b);
    }
    else version(LDC)
    {
        // x86: pmaxsb since LDC 1.1 -O1
        // ARM64: smax.16b since LDC 1.8.0 -O1
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            byte16 greater = sa > sb;
        else
            byte16 greater = cast(byte16) greaterMask!byte16(sa, sb);
        return cast(__m128i)( (greater & sa) | (~greater & sb) );
    }
    else
    {
        __m128i lower = _mm_cmpgt_epi8(a, b); // ones where a should be selected, b else
        __m128i aTob = _mm_xor_si128(a, b); // a ^ (a ^ b) == b
        __m128i mask = _mm_and_si128(aTob, lower);
        return _mm_xor_si128(b, mask);
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(127,  1, -4, -8, 9,    7, 0, 57, 0, 0, 0, 0, 0, 0, 0, 0);
    __m128i B = _mm_setr_epi8(  4, -8,  9, -7, 0, -128, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0);
    byte16 R = cast(byte16) _mm_max_epi8(A, B);
    byte[16] correct =       [127,  1,  9, -7, 9,    7, 0, 57, 0, 0, 0, 0, 0, 0, 0, 0];
    assert(R.array == correct);
}

/// Compare packed unsigned 16-bit integers in `a` and `b`, returns packed maximum values.
__m128i _mm_max_epu16 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pmaxuw128(cast(short8)a, cast(short8)b);
    }
    else version(LDC)
    {
        // x86: pmaxuw since LDC 1.1 -O1
        // ARM64: umax.8h since LDC 1.8.0 -O1
        // PERF: without sse4.1, LLVM 12 produces a very interesting
        //          psubusw xmm0, xmm1
        //          paddw   xmm0, xmm1
        //       sequence that maybe should go in other min/max intrinsics? 
        ushort8 sa = cast(ushort8)a;
        ushort8 sb = cast(ushort8)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            ushort8 greater = sa > sb;
        else
            ushort8 greater = cast(ushort8) greaterMask!ushort8(sa, sb);
        return cast(__m128i)( (greater & sa) | (~greater & sb) );
    }
    else
    {
        b = _mm_subs_epu16(b, a);
        b = _mm_add_epi16(b, a);
        return b;
    }
}
unittest
{
    short8 R = cast(short8) _mm_max_epu16(_mm_setr_epi16(32767,  1, -4, -8, 9,     7, 0, 57),
                                          _mm_setr_epi16(   -4, -8,  9, -7, 0,-32768, 0,  0));
    short[8] correct =                                  [   -4, -8, -4, -7, 9,-32768, 0, 57];
    assert(R.array == correct);
}

/// Compare packed unsigned 32-bit integers in `a` and `b`, returns packed maximum values.
__m128i _mm_max_epu32 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pmaxud128(cast(int4)a, cast(int4)b);
    }
    else version(LDC)
    {
        // x86: pmaxud since LDC 1.1 -O1, also good without sse4.1
        // ARM64: umax.4s since LDC 1.8.0 -O1
        uint4 sa = cast(uint4)a;
        uint4 sb = cast(uint4)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            uint4 greater = sa > sb;
        else
            uint4 greater = cast(uint4) greaterMask!uint4(sa, sb);
        return cast(__m128i)( (greater & sa) | (~greater & sb) );
    }
    else
    {
        __m128i valueShift = _mm_set1_epi32(-0x80000000);
        __m128i higher = _mm_cmpgt_epi32(_mm_add_epi32(a, valueShift), _mm_add_epi32(b, valueShift));
        __m128i aTob = _mm_xor_si128(a, b); // a ^ (a ^ b) == b
        __m128i mask = _mm_and_si128(aTob, higher);
        return _mm_xor_si128(b, mask);
    }
}
unittest
{
    int4 R = cast(int4) _mm_max_epu32(_mm_setr_epi32(0x7fffffff, 1,  4, -7),
                                      _mm_setr_epi32(        -4,-8,  9, -8));
    int[4] correct =                                [        -4,-8,  9, -7];
    assert(R.array == correct);
}

/// Compare packed signed 32-bit integers in `a` and `b`, returns packed maximum values.
__m128i _mm_min_epi32 (__m128i a, __m128i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pminsd128(cast(int4)a, cast(int4)b);
    }
    else version(LDC)
    {
        // x86: pminsd since LDC 1.1 -O1, also good without sse4.1
        // ARM: smin.4s since LDC 1.8 -01
        int4 sa = cast(int4)a;
        int4 sb = cast(int4)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            int4 greater = sa > sb;
        else
            int4 greater = greaterMask!int4(sa, sb);
        return cast(__m128i)( (~greater & sa) | (greater & sb) );
    }
    else
    {
        __m128i higher = _mm_cmplt_epi32(a, b);
        __m128i aTob = _mm_xor_si128(a, b); // a ^ (a ^ b) == b
        __m128i mask = _mm_and_si128(aTob, higher);
        return _mm_xor_si128(b, mask);
    }
}
unittest
{
    int4 R = cast(int4) _mm_min_epi32(_mm_setr_epi32(0x7fffffff,  1, -4, 7),
                                      _mm_setr_epi32(        -4, -8,  9, -8));
    int[4] correct =                               [         -4, -8, -4, -8];
    assert(R.array == correct);
}

/// Compare packed signed 8-bit integers in `a` and `b`, 
/// and return packed minimum values.
__m128i _mm_min_epi8 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pminsb128(cast(ubyte16)a, cast(ubyte16)b);
    }
    else version(LDC)
    {
        // x86: pminsb since LDC 1.1 -O1
        // ARM64: smin.16b since LDC 1.8.0 -O1
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            byte16 greater = sa > sb;
        else
            byte16 greater = cast(byte16) greaterMask!byte16(sa, sb);
        return cast(__m128i)( (~greater & sa) | (greater & sb) );
    }
    else
    {
        __m128i lower = _mm_cmplt_epi8(a, b); // ones where a should be selected, b else
        __m128i aTob = _mm_xor_si128(a, b); // a ^ (a ^ b) == b
        __m128i mask = _mm_and_si128(aTob, lower);
        return _mm_xor_si128(b, mask);
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(127,  1, -4, -8, 9,    7, 0, 57, 0, 0, 0, 0, 0, 0, 0, 0);
    __m128i B = _mm_setr_epi8(  4, -8,  9, -7, 0, -128, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0);
    byte16 R = cast(byte16) _mm_min_epi8(A, B);
    byte[16] correct =       [  4, -8, -4, -8, 0, -128, 0,  0, 0, 0, 0, 0, 0, 0, 0, 0];
    assert(R.array == correct);
}

/// Compare packed unsigned 16-bit integers in a and b, and store packed minimum values in dst.
__m128i _mm_min_epu16 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pminuw128(cast(short8)a, cast(short8)b);
    }
    else version(LDC)
    {
        // x86: pminuw since LDC 1.1 -O1, psubusw+psubw sequence without sse4.1
        // ARM64: umin.8h since LDC 1.8.0 -O1
        ushort8 sa = cast(ushort8)a;
        ushort8 sb = cast(ushort8)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            ushort8 greater = (sb > sa);
        else
            ushort8 greater = cast(ushort8) greaterMask!ushort8(sb, sa);
        return cast(__m128i)( (greater & sa) | (~greater & sb) );
    }
    else
    {
        __m128i c = _mm_subs_epu16(b, a);
        b = _mm_sub_epi16(b, c);
        return b;
    }
}
unittest
{
    short8 R = cast(short8) _mm_min_epu16(_mm_setr_epi16(32767,  1, -4, -8, 9,     7, 0, 57),
                                          _mm_setr_epi16(   -4, -8,  9, -7, 0,-32768, 0,  0));
    short[8] correct =                                  [32767,  1,  9, -8, 0,     7, 0,  0];
    assert(R.array == correct);
}

/// Compare packed unsigned 32-bit integers in a and b, and store packed minimum values in dst.
__m128i _mm_min_epu32 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pminud128(cast(int4)a, cast(int4)b);
    }
    else version(LDC)
    {
        // x86: pminud since LDC 1.1 -O1, also good without sse4.1
        // ARM64: umin.4s since LDC 1.8.0 -O1
        uint4 sa = cast(uint4)a;
        uint4 sb = cast(uint4)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            uint4 greater = sa > sb;
        else        
            uint4 greater = cast(uint4) greaterMask!uint4(sa, sb);
        return cast(__m128i)( (~greater & sa) | (greater & sb) );
    }
    else
    {
        __m128i valueShift = _mm_set1_epi32(-0x80000000);
        __m128i higher = _mm_cmpgt_epi32(_mm_add_epi32(b, valueShift), _mm_add_epi32(a, valueShift));
        __m128i aTob = _mm_xor_si128(a, b); // a ^ (a ^ b) == b
        __m128i mask = _mm_and_si128(aTob, higher);
        return _mm_xor_si128(b, mask);
    }
}
unittest
{
    int4 R = cast(int4) _mm_min_epu32(_mm_setr_epi32(0x7fffffff, 1,  4, -7),
                                      _mm_setr_epi32(        -4,-8,  9, -8));
    int[4] correct =                                [0x7fffffff, 1,  4, -8];
    assert(R.array == correct);
}

/// Horizontally compute the minimum amongst the packed unsigned 16-bit integers in `a`, 
/// store the minimum and index in return value, and zero the remaining bits.
__m128i _mm_minpos_epu16 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_phminposuw128(cast(short8)a);
    }
    else static if (LDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_phminposuw128(cast(short8)a);
    }
    else static if (LDC_with_ARM64)
    {
        __m128i indices = _mm_setr_epi16(0, 1, 2, 3, 4, 5, 6, 7);
        __m128i combinedLo = _mm_unpacklo_epi16(indices, a);
        __m128i combinedHi = _mm_unpackhi_epi16(indices, a);
        __m128i best = _mm_min_epu32(combinedLo, combinedHi);
        best = _mm_min_epu32(best, _mm_srli_si128!8(best));
        best = _mm_min_epu32(best, _mm_srli_si128!4(best));
        short8 sbest = cast(short8)best;
        short8 r;
        r[0] = sbest[1];
        r[1] = sbest[0]; // Note: the search must have inverted index in order to prioritize lower index in case of tie
        r[2] = 0;
        r[3] = 0;
        r[4] = 0;
        r[5] = 0;
        r[6] = 0;
        r[7] = 0;
        return cast(__m128i)r;
    }
    else
    {
        short8 sa = cast(short8)a;
        ushort min = 0xffff;
        int index = 0;
        for(int n = 0; n < 8; ++n)
        {
            ushort c = sa.array[n];
            if (c < min)
            {
                min = c;
                index = n;
            }
        }
        short8 r;
        r.ptr[0] = min;
        r.ptr[1] = cast(short)index;
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(14, 15, 1, 2, -3, 4, 5, 6);
    __m128i B = _mm_setr_epi16(14,  4, 4, 2, -3, 2, 5, 6);
    short8 R1 = cast(short8) _mm_minpos_epu16(A);
    short8 R2 = cast(short8) _mm_minpos_epu16(B);
    short[8] correct1 = [1, 2, 0, 0, 0, 0, 0, 0];
    short[8] correct2 = [2, 3, 0, 0, 0, 0, 0, 0];
    assert(R1.array == correct1);
    assert(R2.array == correct2);
}

/// Compute the sum of absolute differences (SADs) of quadruplets of unsigned 8-bit integers 
/// in `a` compared to those in `b`, and store the 16-bit results in dst. 
/// Eight SADs are performed using one quadruplet from `b` and eight quadruplets from `a`. 
/// One quadruplet is selected from `b` starting at on the offset specified in `imm8[1:0]`. 
/// Eight quadruplets are formed from sequential 8-bit integers selected from `a` starting 
/// at the offset specified in `imm8[2]`.
__m128i _mm_mpsadbw_epu8(int imm8)(__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_mpsadbw128(cast(ubyte16)a, cast(ubyte16)b, cast(ubyte)imm8);  
    }
    else static if (LDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_mpsadbw128(cast(byte16)a, cast(byte16)b, cast(byte)imm8);
    }
    else
    {
        int a_offset = ((imm8 & 4) >> 2) * 4; // Yes, the two high order quadruplet are unaddressable...
        int b_offset = (imm8 & 3) * 4;

        byte16 ba = cast(byte16)a;
        byte16 bb = cast(byte16)b;
        short8 r;

        __m128i comp_b = _mm_setr_epi32(b.array[imm8 & 3], 0, b.array[imm8 & 3], 0);

        for (int j = 0; j < 8; j += 2)
        {
            int k = a_offset + j;
            __m128i comp_a = _mm_setr_epi8(ba[k+0], ba[k+1], ba[k+2], ba[k+3],
                                           0, 0, 0, 0, 
                                           ba[k+1], ba[k+2], ba[k+3], ba[k+4],
                                           0, 0, 0, 0);
            short8 diffs = cast(short8) _mm_sad_epu8(comp_a, comp_b); // reusing this wins instructions in both x86 and arm64
            r.ptr[j] = diffs.array[0];
            r.ptr[j+1] = diffs.array[4];
        }
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(0, 1, 2, 3,  4,  5, 6,  7, 8, 9, 10, 11, 12, 13, 14, 15);
    __m128i B = _mm_setr_epi8(9, 1, 2, 3, -1, -1, 0, -1, 5, 5,  5,  5, 12, 13, 14, 15);
    short[8] correct0 = [9, 11, 13, 15, 17, 19, 21, 23];
    short[8] correct1 = [763, 761, 759, 757, 755, 753, 751, 749];
    short[8] correct4 = [17, 19, 21, 23, 25, 27, 31, 35];
    short[8] correct5 = [755, 753, 751, 749, 747, 745, 743, 741];
    short[8] correct7 = [32, 28, 24, 20, 16, 12, 8, 4];
    short8 r1 = cast(short8) _mm_mpsadbw_epu8!1(A, B);
    short8 r4 = cast(short8) _mm_mpsadbw_epu8!4(A, B);
    short8 r5 = cast(short8) _mm_mpsadbw_epu8!5(A, B);
    short8 r7 = cast(short8) _mm_mpsadbw_epu8!7(A, B);
    short8 r8 = cast(short8) _mm_mpsadbw_epu8!8(A, B);
    assert(r1.array == correct1);
    assert(r4.array == correct4);
    assert(r5.array == correct5);
    assert(r7.array == correct7);
    assert(r8.array == correct0);
}

/// Multiply the low signed 32-bit integers from each packed 64-bit element in a and b, and store the signed 64-bit results in dst.
__m128i _mm_mul_epi32 (__m128i a, __m128i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pmuldq128(cast(int4)a, cast(int4)b);
    }
    else static if (LDC_with_SSE41 && LDC_with_optimizations)
    {
        // For some reason, clang has the builtin but it's not in IntrinsicsX86.td
        // Use IR instead.
        // This generates pmuldq with since LDC 1.2.0 -O0 
        enum ir = `
            %ia = shufflevector <4 x i32> %0,<4 x i32> %0, <2 x i32> <i32 0, i32 2>
            %ib = shufflevector <4 x i32> %1,<4 x i32> %1, <2 x i32> <i32 0, i32 2>
            %la = sext <2 x i32> %ia to <2 x i64>
            %lb = sext <2 x i32> %ib to <2 x i64>
            %r = mul <2 x i64> %la, %lb
            ret <2 x i64> %r`;
        return cast(__m128i) LDCInlineIR!(ir, long2, int4, int4)(cast(int4)a, cast(int4)b);
    }
    else static if (LDC_with_ARM64)  
    {
        // 3 instructions since LDC 1.8 -O2
        // But had to make vmull_s32 be a builtin else it wouldn't optimize to smull
        int2 a_lo = vmovn_s64(cast(long2)a);
        int2 b_lo = vmovn_s64(cast(long2)b);
        return cast(__m128i) vmull_s32(a_lo, b_lo);
    }
    else
    {
        int4 ia = cast(int4)a;
        int4 ib = cast(int4)b;
        long2 r;
        r.ptr[0] = cast(long)ia.array[0] * ib.array[0];
        r.ptr[1] = cast(long)ia.array[2] * ib.array[2];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(61616461, 1915324654, 4564061, 3);
    __m128i B = _mm_setr_epi32(49716422, -915616216, -121144, 0);
    long2 R = cast(long2) _mm_mul_epi32(A, B);
    long[2] correct = [cast(long)61616461 * 49716422, cast(long)4564061 * -121144];
    assert(R.array == correct);
}

/// Multiply the packed 32-bit integers in `a` and `b`, producing intermediate 64-bit integers, 
/// return the low 32 bits of the intermediate integers.
__m128i _mm_mullo_epi32 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    // PERF GDC without SSE4.1 could be better
    static if (GDC_with_SSE41)
    {
        int4 ia = cast(int4)a;
        int4 ib = cast(int4)b;
        // Note: older GDC doesn't have that op, but older GDC
        // also has no support for -msse4.1 detection
        return cast(__m128i)(a * b); 
    }
    else version(LDC)
    {
        int4 ia = cast(int4)a;
        int4 ib = cast(int4)b;
        return cast(__m128i)(a * b);
    }
    else
    {
        // DMD doesn't take the above
        int4 ia = cast(int4)a;
        int4 ib = cast(int4)b;
        int4 r;
        r.ptr[0] = ia.array[0] * ib.array[0];
        r.ptr[1] = ia.array[1] * ib.array[1];
        r.ptr[2] = ia.array[2] * ib.array[2];
        r.ptr[3] = ia.array[3] * ib.array[3];
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(61616461, 1915324654, 4564061, 3);
    __m128i B = _mm_setr_epi32(49716422, -915616216, -121144, 0);
    int4 R = cast(int4) _mm_mullo_epi32(A, B);
    int[4] correct = [cast(int)0xBF370D8E, cast(int)(1915324654 * -915616216), cast(int)(4564061 * -121144), 0];
    assert(R.array == correct);
}


/// Convert packed signed 32-bit integers from `a` and `b` 
/// to packed 16-bit integers using unsigned saturation.
__m128i _mm_packus_epi32 (__m128i a, __m128i b) @trusted
{
    static if (GDC_with_SSE41)
    {
        // PERF For some reason doesn't generates the builtin???
        return cast(__m128i) __builtin_ia32_packusdw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_packusdw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_ARM64)
    {
       int4 z;
       z = 0;       
       return cast(__m128i) vcombine_u16(vqmovn_u32(vmaxq_s32(z, cast(int4)a)),
                                         vqmovn_u32(vmaxq_s32(z, cast(int4)b)));
    }
    else
    {
        // PERF: not great without SSE4.1
        int4 sa = cast(int4)a;
        int4 sb = cast(int4)b;
        align(16) ushort[8] result;
        for (int i = 0; i < 4; ++i)
        {
            int s = sa.array[i];
            if (s < 0) s = 0;
            if (s > 65535) s = 65535;
            result.ptr[i] = cast(ushort)s;

            s = sb.array[i];
            if (s < 0) s = 0;
            if (s > 65535) s = 65535;
            result.ptr[i+4] = cast(ushort)s;
        }
        return *cast(__m128i*)(result.ptr);
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(100000, -100000, 1000, 0);
    short8 R = cast(short8) _mm_packus_epi32(A, A);
    short[8] correct = [cast(short)65535, 0, 1000, 0, cast(short)65535, 0, 1000, 0];
    assert(R.array == correct);
}


/// Round the packed double-precision (64-bit) floating-point elements in `a` using the 
/// rounding parameter, and store the results as packed double-precision floating-point elements.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128d _mm_round_pd(int rounding)(__m128d a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return __builtin_ia32_roundpd(a, rounding);
    }
    else static if (LDC_with_SSE41)
    {
        return __builtin_ia32_roundpd(a, rounding);
    }
    else
    {
        static if (rounding & _MM_FROUND_CUR_DIRECTION)
        {
            // Convert to 64-bit integers
            long lo = _mm_cvtsd_si64(a);
            a.ptr[0] = a.array[1];
            long hi = _mm_cvtsd_si64(a);
            return _mm_setr_pd(lo, hi);
        }
        else
        {
            version(GNU) pragma(inline, false); // else fail unittest with optimizations

            uint old = _MM_GET_ROUNDING_MODE();
            _MM_SET_ROUNDING_MODE((rounding & 3) << 13);
            
            // Convert to 64-bit integers
            long lo = _mm_cvtsd_si64(a);
            a.ptr[0] = a.array[1];
            long hi = _mm_cvtsd_si64(a);

            // Convert back to double to achieve the rounding
            // The problem is that a 64-bit double can't represent all the values 
            // a 64-bit integer can (and vice-versa). So this function won't work for
            // large values. (TODO: what range exactly?)
            _MM_SET_ROUNDING_MODE(old);
            return _mm_setr_pd(lo, hi);
        }
    }
}
unittest
{
    // tested in other intrinsics
}

/// Round the packed single-precision (32-bit) floating-point elements in `a` using the 
/// rounding parameter, and store the results as packed single-precision floating-point elements.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128 _mm_round_ps(int rounding)(__m128 a) @trusted
{
    // PERF ARM64: there is duplication because this isn't optimal for ARM64, so it is avoided externally
    static if (GDC_or_LDC_with_SSE41)
    {
        return __builtin_ia32_roundps(a, rounding);
    }
    else
    {
        static if (rounding & _MM_FROUND_CUR_DIRECTION)
        {
            __m128i integers = _mm_cvtps_epi32(a);
            return _mm_cvtepi32_ps(integers);
        }
        else
        {
            version(LDC) pragma(inline, false); // else _MM_SET_ROUNDING_MODE and _mm_cvtps_epi32 gets shuffled
            uint old = _MM_GET_ROUNDING_MODE();
            _MM_SET_ROUNDING_MODE((rounding & 3) << 13);
            scope(exit) _MM_SET_ROUNDING_MODE(old);

            // Convert to 64-bit integers
            __m128i integers = _mm_cvtps_epi32(a);

            // Convert back to float to achieve the rounding
            // The problem is that a 32-float can't represent all the values 
            // a 32-bit integer can (and vice-versa). So this function won't work for
            // large values. (TODO: what range exactly?)
            __m128 result = _mm_cvtepi32_ps(integers);

            return result;
        }
    }
}
unittest
{
    // tested in other intrinsics
}


/// Round the lower double-precision (64-bit) floating-point element in `b` using the
/// rounding parameter, store the result as a double-precision floating-point element 
/// in the lower element of result, and copy the upper element from `a` to the upper element of result.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128d _mm_round_sd(int rounding)(__m128d a, __m128d b) @trusted
{
    static if (GDC_with_SSE41)
    {
        return __builtin_ia32_roundsd(a, b, rounding);
    }
    else static if (LDC_with_SSE41)
    {
        return __builtin_ia32_roundsd(a, b, rounding);
    }
    else
    {
        static if (rounding & _MM_FROUND_CUR_DIRECTION)
        {
            // Convert to 64-bit integer
            long b0 = _mm_cvtsd_si64(b);
            a.ptr[0] = b0;
            return a;
        }
        else
        {
            version(GNU) pragma(inline, false); // else fail unittest with optimizations

            uint old = _MM_GET_ROUNDING_MODE();
            _MM_SET_ROUNDING_MODE((rounding & 3) << 13);
            
            // Convert to 64-bit integer
            long b0 = _mm_cvtsd_si64(b);
            a.ptr[0] = b0;

            // Convert back to double to achieve the rounding
            // The problem is that a 64-bit double can't represent all the values 
            // a 64-bit integer can (and vice-versa). So this function won't work for
            // large values. (TODO: what range exactly?)
            _MM_SET_ROUNDING_MODE(old);
            return a;
        }
    }
}
unittest
{
    // tested in other intrinsics
}


/// Round the lower single-precision (32-bit) floating-point element in `b` using the 
/// rounding parameter, store the result as a single-precision floating-point element 
/// in the lower element of result, and copy the upper 3 packed elements from `a`
/// to the upper elements of result.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128 _mm_round_ss(int rounding)(__m128 a, __m128 b) @trusted
{
    static if (GDC_with_SSE41)
    {
        return __builtin_ia32_roundss(a, b, rounding);
    }
    else static if (LDC_with_SSE41)
    {
        return __builtin_ia32_roundss(a, b, rounding);
    }
    else
    {
        static if (rounding & _MM_FROUND_CUR_DIRECTION)
        {
            int b0 = _mm_cvtss_si32(b);
            a.ptr[0] = b0;   
            return a;
        }
        else version(GNU)
        {
            pragma(inline, false)
            __m128 GDCworkaround() nothrow @nogc @trusted 
            {
                uint old = _MM_GET_ROUNDING_MODE();
                _MM_SET_ROUNDING_MODE((rounding & 3) << 13);

                // Convert to 32-bit integer
                int b0 = _mm_cvtss_si32(b);
                a.ptr[0] = b0;       

                // Convert back to double to achieve the rounding
                // The problem is that a 32-bit float can't represent all the values 
                // a 32-bit integer can (and vice-versa). So this function won't work for
                // large values. (TODO: what range exactly?)
                _MM_SET_ROUNDING_MODE(old);
                return a;
            }
            return GDCworkaround();
        }
        else
        {
            uint old = _MM_GET_ROUNDING_MODE();
            _MM_SET_ROUNDING_MODE((rounding & 3) << 13);

            // Convert to 32-bit integer
            int b0 = _mm_cvtss_si32(b);
            a.ptr[0] = b0;       

            // Convert back to double to achieve the rounding
            // The problem is that a 32-bit float can't represent all the values 
            // a 32-bit integer can (and vice-versa). So this function won't work for
            // large values. (TODO: what range exactly?)
            _MM_SET_ROUNDING_MODE(old);
            return a;
        }
    }
}
unittest
{
    // tested in other intrinsics
}


/// Load 128-bits of integer data from memory using a non-temporal memory hint. 
/// `mem_addr` must be aligned on a 16-byte boundary or a general-protection 
/// exception may be generated.
__m128i _mm_stream_load_si128 (__m128i * mem_addr) pure @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_movntdqa(cast(long2*)mem_addr);
    }
    else static if (LDC_with_InlineIREx && LDC_with_optimizations)
    {
        enum prefix = `!0 = !{ i32 1 }`;
        enum ir = `
            %r = load <4 x i32>, <4 x i32>* %0, !nontemporal !0
            ret <4 x i32> %r`;
        return cast(__m128i) LDCInlineIREx!(prefix, ir, "", int4, int4*)(mem_addr);
    }
    else
    {
        return *mem_addr; // regular move instead
    }
}
// TODO unittest


/// Return 1 if all bits in `a` are all 1's. Else return 0.
int _mm_test_all_ones (__m128i a) @safe
{
    return _mm_testc_si128(a, _mm_set1_epi32(-1));
}
unittest
{
    __m128i A = _mm_set1_epi32(-1);
    __m128i B = _mm_set_epi32(-1, -2, -1, -1);
    assert(_mm_test_all_ones(A) == 1);
    assert(_mm_test_all_ones(B) == 0);
}

/// Return 1 if all bits in `a` are all 0's. Else return 0.
// This is a #BONUS since it was lacking in Intel Intrinsics API.
int _mm_test_all_zeros (__m128i a) @safe
{
    return _mm_testz_si128(a, _mm_set1_epi32(-1));
}
unittest
{
    __m128i A = _mm_set1_epi32(0);
    __m128i B = _mm_set_epi32(0, 8, 0, 0);
    assert(_mm_test_all_zeros(A) == 1);
    assert(_mm_test_all_zeros(B) == 0);
}

/// Compute the bitwise AND of 128 bits (representing integer data) in `a` and `mask`, 
/// and return 1 if the result is zero, otherwise return 0.
int _mm_test_all_zeros (__m128i a, __m128i mask) @safe
{
    return _mm_testz_si128(a, mask); // it's really the same, but with a good name
}

/// Compute the bitwise AND of 128 bits (representing integer data) in `a` and mask, and set ZF to 1 
/// if the result is zero, otherwise set ZF to 0. Compute the bitwise NOT of a and then AND with 
/// mask, and set CF to 1 if the result is zero, otherwise set CF to 0. Return 1 if both the ZF and
/// CF values are zero, otherwise return 0.
int _mm_test_mix_ones_zeros (__m128i a, __m128i mask) @trusted
{
    return _mm_testnzc_si128(a, mask);
}

/// Compute the bitwise NOT of a and then AND with b, and return 1 if the 
/// result is zero, otherwise return 0.
/// In other words, test if all bits masked by `b` are 1 in `a`.
int _mm_testc_si128 (__m128i a, __m128i b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return __builtin_ia32_ptestc128(cast(long2)a, cast(long2)b);
    }
    else static if (LDC_with_SSE41)
    {
        return __builtin_ia32_ptestc128(cast(long2)a, cast(long2)b);
    }
    else static if (LDC_with_ARM64)
    {
        // Acceptable since LDC 1.8 -02
        long2 s64 = vbicq_s64(cast(long2)b, cast(long2)a);
        return !(vgetq_lane_s64(s64, 0) | vgetq_lane_s64(s64, 1));
    }
    else
    {
        __m128i c = ~a & b;
        int[4] zero = [0, 0, 0, 0];
        return c.array == zero;
    }
}
unittest
{
    __m128i A  = _mm_setr_epi32(0x01, 0x02, 0x04, 0xf8);
    __m128i M1 = _mm_setr_epi32(0xfe, 0xfd, 0x00, 0x00);
    __m128i M2 = _mm_setr_epi32(0x00, 0x00, 0x04, 0x00);
    assert(_mm_testc_si128(A, A) == 1);
    assert(_mm_testc_si128(A, M1) == 0);
    assert(_mm_testc_si128(A, M2) == 1);
}

/// Compute the bitwise AND of 128 bits (representing integer data) in `a` and `b`, 
/// and set ZF to 1 if the result is zero, otherwise set ZF to 0. 
/// Compute the bitwise NOT of `a` and then AND with `b`, and set CF to 1 if the 
/// result is zero, otherwise set CF to 0. 
/// Return 1 if both the ZF and CF values are zero, otherwise return 0.
int _mm_testnzc_si128 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return __builtin_ia32_ptestnzc128(cast(long2)a, cast(long2)b);
    }
    else static if (LDC_with_SSE41)
    {
        return __builtin_ia32_ptestnzc128(cast(long2)a, cast(long2)b);
    }
    else static if (LDC_with_ARM64)
    {
        long2 s640 = vandq_s64(cast(long2)b, cast(long2)a);
        long2 s641 = vbicq_s64(cast(long2)b, cast(long2)a);

        return !( !(vgetq_lane_s64(s641, 0) | vgetq_lane_s64(s641, 1))
                | !(vgetq_lane_s64(s640, 0) | vgetq_lane_s64(s640, 1)) );
    }
    else
    {
        __m128i c = a & b;
        __m128i d = ~a & b;
        int[4] zero = [0, 0, 0, 0];
        return !( (c.array == zero) || (d.array == zero));
    }    
}
unittest
{
    __m128i A  = _mm_setr_epi32(0x01, 0x02, 0x04, 0xf8);
    __m128i M  = _mm_setr_epi32(0x01, 0x40, 0x00, 0x00);
    __m128i Z = _mm_setzero_si128();
    assert(_mm_testnzc_si128(A, Z) == 0);
    assert(_mm_testnzc_si128(A, M) == 1);
    assert(_mm_testnzc_si128(A, A) == 0);
}

/// Compute the bitwise AND of 128 bits (representing integer data) in a and b, 
/// and return 1 if the result is zero, otherwise return 0.
/// In other words, test if all bits masked by `b` are 0 in `a`.
int _mm_testz_si128 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return __builtin_ia32_ptestz128(cast(long2)a, cast(long2)b);
    }
    else static if (LDC_with_SSE41)
    {
        return __builtin_ia32_ptestz128(cast(long2)a, cast(long2)b);
    }
    else static if (LDC_with_ARM64)
    {
        // Acceptable since LDC 1.8 -02
        long2 s64 = vandq_s64(cast(long2)a, cast(long2)b);
        return !(vgetq_lane_s64(s64, 0) | vgetq_lane_s64(s64, 1));
    }
    else 
    {
        __m128i c = a & b;
        int[4] zero = [0, 0, 0, 0];
        return c.array == zero;
    }    
}
unittest
{
    __m128i A  = _mm_setr_epi32(0x01, 0x02, 0x04, 0xf8);
    __m128i M1 = _mm_setr_epi32(0xfe, 0xfd, 0x00, 0x07);
    __m128i M2 = _mm_setr_epi32(0x00, 0x00, 0x04, 0x00);
    assert(_mm_testz_si128(A, A) == 0);
    assert(_mm_testz_si128(A, M1) == 1);
    assert(_mm_testz_si128(A, M2) == 0);
}

