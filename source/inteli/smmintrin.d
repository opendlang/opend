/**
* SSE4.1 intrinsics.
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
__m128i _mm_blend_epi16(int imm8)(__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
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
// Note: changed signature, GDC needs a compile-time value for imm8.
__m128d _mm_blend_pd (__m128d a, __m128d b, const int imm8) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_blendpd(cast(short8)a, cast(short8)b, imm8);
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
    double2 C = _mm_blend_pd(A, B, 2); // 10
    double[2] correct =    [0, 9];
    assert(C.array == correct);
}


/// Blend packed single-precision (32-bit) floating-point elements from `a` and `b` using control mask `imm8`.
// Note: changed signature, GDC needs a compile-time value for imm8.
__m128 _mm_blend_ps(int imm8)(__m128 a, __m128 b) @trusted
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
        return shufflevector!(float4, (imm8 & 1) ? 4 : 0,
                                      (imm8 & 2) ? 5 : 1,
                                      (imm8 & 4) ? 6 : 2,
                                      (imm8 & 8) ? 7 : 3)(a, b);
    }
    else
    {
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
    // PERF Catastrophic on ARM64
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pblendvb(cast(byte16)a, cast(byte16)b, cast(byte16)mask);
    }
    else static if (LDC_with_SSE41)
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
        // Amazingly enough, GCC/GDC generates the blendvpd instruction
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
        __m128d r;
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

    // BUG: LDC _mm_blendv_pd doesn't work with NaN mask in arm64 Linux for some unknown reason.
    // but it does work in arm64 macOS
    // yields different results despite FP seemingly not being used
    version(linux)
    {}
    else
    {
        __m128d M2 = _mm_setr_pd(double.nan, -double.nan);
        __m128d R2 = _mm_blendv_pd(A, B, M2);
        double[2] correct2 = [1.0, 4.0];
        assert(R2.array == correct2);
    }
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
        __m128 r;
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
    __m128 M2 = _mm_setr_ps(float.nan, -float.nan, -0.0f, +0.0f);
    __m128 R1 = _mm_blendv_ps(A, B, M1);
    __m128 R2 = _mm_blendv_ps(A, B, M2);
    float[4] correct1 =    [ 4.0f, 1.0f, 2.0f, 7.0f];
    float[4] correct2 =    [ 0.0f, 5.0f, 6.0f, 3.0f];
    assert(R1.array == correct1);

    // BUG: like above, LDC _mm_blendv_ps doesn't work with NaN mask in arm64 Linux for some unknown reason.
    // yields different results despite FP seemingly not being used
    version(linux)
    {}
    else
    {
        assert(R2.array == correct2);
    }
}


/*
/// Round the packed double-precision (64-bit) floating-point elements in a up to an integer value, and store the results as packed double-precision floating-point elements in dst.
__m128d _mm_ceil_pd (__m128d a) @trusted
{
}
unittest
{
}
*/

/*
/// Round the packed single-precision (32-bit) floating-point elements in a up to an integer value, and store the results as packed single-precision floating-point elements in dst.
__m128 _mm_ceil_ps (__m128 a) @trusted
{
}
unittest
{
}
*/

/*
/// Round the lower double-precision (64-bit) floating-point element in b up to an integer value, store the result as a double-precision floating-point element in the lower element of dst, and copy the upper element from a to the upper element of dst.
__m128d _mm_ceil_sd (__m128d a, __m128d b) @trusted
{
}
unittest
{
}
*/

/*
/// Round the lower single-precision (32-bit) floating-point element in b up to an integer value, store the result as a single-precision floating-point element in the lower element of dst, and copy the upper 3 packed elements from a to the upper elements of dst.
__m128 _mm_ceil_ss (__m128 a, __m128 b) @trusted
{
}
unittest
{
}
*/


/// Compare packed 64-bit integers in `a` and `b` for equality.
__m128i _mm_cmpeq_epi64 (__m128i a, __m128i b) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
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
    else version(LDC)
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
    else version(LDC)
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
    else version(LDC)
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
__m128i _mm_cvtepi8_epi16 (__m128i a) @trusted
{
    // PERF DMD
    static if (GDC_with_SSE41)
    {
        alias ubyte16 = __vector(ubyte[16]);
        return cast(__m128i)__builtin_ia32_pmovsxbw128(cast(ubyte16)a);
    }
    else version(LDC)
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
    else static if (LDC_with_SSE41)
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
    else version(LDC)
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
    static if (GDC_with_SSE41)
    {
        return cast(__m128i) __builtin_ia32_pmovzxwq128(cast(short8)a);
    }
    else static if (LDC_with_ARM64)
    {
        // LDC arm64: a bit shorter than below
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


/*
/// Zero extend packed unsigned 32-bit integers in `a` to packed 64-bit integers.
__m128i _mm_cvtepu32_epi64 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Zero extend packed unsigned 8-bit integers in `a` to packed 16-bit integers.
__m128i _mm_cvtepu8_epi16 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Zero extend packed unsigned 8-bit integers in `a` to packed 32-bit integers.
__m128i _mm_cvtepu8_epi32 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Zero extend packed unsigned 8-bit integers in the low 8 bytes of `a` to packed 64-bit integers.
__m128i _mm_cvtepu8_epi64 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Conditionally multiply the packed double-precision (64-bit) floating-point elements in a and b using the high 4 bits in imm8, sum the four products, and conditionally store the sum in dst using the low 4 bits of imm8.
__m128d _mm_dp_pd (__m128d a, __m128d b, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Conditionally multiply the packed single-precision (32-bit) floating-point elements in a and b using the high 4 bits in imm8, sum the four products, and conditionally store the sum in dst using the low 4 bits of imm8.
__m128 _mm_dp_ps (__m128 a, __m128 b, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Extract a 32-bit integer from a, selected with imm8, and store the result in dst.
int _mm_extract_epi32 (__m128i a, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Extract a 64-bit integer from a, selected with imm8, and store the result in dst.
__int64 _mm_extract_epi64 (__m128i a, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Extract an 8-bit integer from a, selected with imm8, and store the result in the lower element of dst.
int _mm_extract_epi8 (__m128i a, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Extract a single-precision (32-bit) floating-point element from a, selected with imm8, and store the result in dst.
int _mm_extract_ps (__m128 a, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Round the packed double-precision (64-bit) floating-point elements in a down to an integer value, and store the results as packed double-precision floating-point elements in dst.
__m128d _mm_floor_pd (__m128d a) @trusted
{
}
unittest
{
}
*/

/*
/// Round the packed single-precision (32-bit) floating-point elements in a down to an integer value, and store the results as packed single-precision floating-point elements in dst.
__m128 _mm_floor_ps (__m128 a) @trusted
{
}
unittest
{
}
*/

/*
/// Round the lower double-precision (64-bit) floating-point element in b down to an integer value, store the result as a double-precision floating-point element in the lower element of dst, and copy the upper element from a to the upper element of dst.
__m128d _mm_floor_sd (__m128d a, __m128d b) @trusted
{
}
unittest
{
}
*/

/*
/// Round the lower single-precision (32-bit) floating-point element in b down to an integer value, store the result as a single-precision floating-point element in the lower element of dst, and copy the upper 3 packed elements from a to the upper elements of dst.
__m128 _mm_floor_ss (__m128 a, __m128 b) @trusted
{
}
unittest
{
}
*/

/*
/// Copy a to dst, and insert the 32-bit integer i into dst at the location specified by imm8.
__m128i _mm_insert_epi32 (__m128i a, int i, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Copy a to dst, and insert the 64-bit integer i into dst at the location specified by imm8.
__m128i _mm_insert_epi64 (__m128i a, __int64 i, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Copy a to dst, and insert the lower 8-bit integer from i into dst at the location specified by imm8.
__m128i _mm_insert_epi8 (__m128i a, int i, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Copy a to tmp, then insert a single-precision (32-bit) floating-point element from b into tmp using the control in imm8. Store tmp to dst using the mask in imm8 (elements are zeroed out when the corresponding bit is set).
__m128 _mm_insert_ps (__m128 a, __m128 b, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed signed 32-bit integers in a and b, and store packed maximum values in dst.
__m128i _mm_max_epi32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed signed 8-bit integers in a and b, and store packed maximum values in dst.
__m128i _mm_max_epi8 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed unsigned 16-bit integers in a and b, and store packed maximum values in dst.
__m128i _mm_max_epu16 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed unsigned 32-bit integers in a and b, and store packed maximum values in dst.
__m128i _mm_max_epu32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed signed 32-bit integers in a and b, and store packed minimum values in dst.
__m128i _mm_min_epi32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed signed 8-bit integers in a and b, and store packed minimum values in dst.
__m128i _mm_min_epi8 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed unsigned 16-bit integers in a and b, and store packed minimum values in dst.
__m128i _mm_min_epu16 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed unsigned 32-bit integers in a and b, and store packed minimum values in dst.
__m128i _mm_min_epu32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Horizontally compute the minimum amongst the packed unsigned 16-bit integers in a, store the minimum and index in dst, and zero the remaining bits in dst.
__m128i _mm_minpos_epu16 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the sum of absolute differences (SADs) of quadruplets of unsigned 8-bit integers in a compared to those in b, and store the 16-bit results in dst. Eight SADs are performed using one quadruplet from b and eight quadruplets from a. One quadruplet is selected from b starting at on the offset specified in imm8. Eight quadruplets are formed from sequential 8-bit integers selected from a starting at the offset specified in imm8.
__m128i _mm_mpsadbw_epu8 (__m128i a, __m128i b, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Multiply the low signed 32-bit integers from each packed 64-bit element in a and b, and store the signed 64-bit results in dst.
__m128i _mm_mul_epi32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Multiply the packed 32-bit integers in a and b, producing intermediate 64-bit integers, and store the low 32 bits of the intermediate integers in dst.
__m128i _mm_mullo_epi32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Convert packed signed 32-bit integers from `a` and `b` to packed 16-bit integers using unsigned saturation.
__m128i _mm_packus_epi32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/// Round the packed double-precision (64-bit) floating-point elements in a using the rounding parameter, and store the results as packed double-precision floating-point elements in dst.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
/*
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128d _mm_round_pd (__m128d a, int rounding) @trusted
{
}
unittest
{
}
*/

/// Round the packed single-precision (32-bit) floating-point elements in a using the rounding parameter, and store the results as packed single-precision floating-point elements in dst.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
/*
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128 _mm_round_ps (__m128 a, int rounding) @trusted
{
}
unittest
{
}
*/

/// Round the lower double-precision (64-bit) floating-point element in b using the rounding parameter, store the result as a double-precision floating-point element in the lower element of dst, and copy the upper element from a to the upper element of dst.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
/*
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128d _mm_round_sd (__m128d a, __m128d b, int rounding) @trusted
{
}
unittest
{
}
*/

/// Round the lower single-precision (32-bit) floating-point element in b using the rounding parameter, store the result as a single-precision floating-point element in the lower element of dst, and copy the upper 3 packed elements from a to the upper elements of dst.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
/*
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128 _mm_round_ss (__m128 a, __m128 b, int rounding) @trusted
{
}
unittest
{
}
*/

/*
/// Load 128-bits of integer data from memory into dst using a non-temporal memory hint. mem_addr must be aligned on a 16-byte boundary or a general-protection exception may be generated.
__m128i _mm_stream_load_si128 (__m128i * mem_addr) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise NOT of a and then AND with a 128-bit vector containing all 1's, and return 1 if the result is zero, otherwise return 0.
int _mm_test_all_ones (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise AND of 128 bits (representing integer data) in a and mask, and return 1 if the result is zero, otherwise return 0.
int _mm_test_all_zeros (__m128i a, __m128i mask) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise AND of 128 bits (representing integer data) in a and mask, and set ZF to 1 if the result is zero, otherwise set ZF to 0. Compute the bitwise NOT of a and then AND with mask, and set CF to 1 if the result is zero, otherwise set CF to 0. Return 1 if both the ZF and CF values are zero, otherwise return 0.
int _mm_test_mix_ones_zeros (__m128i a, __m128i mask) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise AND of 128 bits (representing integer data) in a and b, and set ZF to 1 if the result is zero, otherwise set ZF to 0. Compute the bitwise NOT of a and then AND with b, and set CF to 1 if the result is zero, otherwise set CF to 0. Return the CF value.
int _mm_testc_si128 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise AND of 128 bits (representing integer data) in a and b, and set ZF to 1 if the result is zero, otherwise set ZF to 0. Compute the bitwise NOT of a and then AND with b, and set CF to 1 if the result is zero, otherwise set CF to 0. Return 1 if both the ZF and CF values are zero, otherwise return 0.
int _mm_testnzc_si128 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise AND of 128 bits (representing integer data) in a and b, and set ZF to 1 if the result is zero, otherwise set ZF to 0. Compute the bitwise NOT of a and then AND with b, and set CF to 1 if the result is zero, otherwise set CF to 0. Return the ZF value.
int _mm_testz_si128 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/


// LDC intrinsics present from 1.0.0 to 

/*

pragma(LDC_intrinsic, "llvm.x86.sse41.blendvpd")
    double2 __builtin_ia32_blendvpd(double2, double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.blendvps")
    float4 __builtin_ia32_blendvps(float4, float4, float4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.dppd")
    double2 __builtin_ia32_dppd(double2, double2, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.dpps")
    float4 __builtin_ia32_dpps(float4, float4, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.insertps")
    float4 __builtin_ia32_insertps128(float4, float4, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.mpsadbw")
    short8 __builtin_ia32_mpsadbw128(byte16, byte16, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.packusdw")
    short8 __builtin_ia32_packusdw128(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.pblendvb")
    byte16 __builtin_ia32_pblendvb128(byte16, byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.phminposuw")
    short8 __builtin_ia32_phminposuw128(short8) pure @safe;


pragma(LDC_intrinsic, "llvm.x86.sse41.ptestc")
    int __builtin_ia32_ptestc128(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.ptestnzc")
    int __builtin_ia32_ptestnzc128(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.ptestz")
    int __builtin_ia32_ptestz128(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.round.pd")
    double2 __builtin_ia32_roundpd(double2, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.round.ps")
    float4 __builtin_ia32_roundps(float4, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.round.sd")
    double2 __builtin_ia32_roundsd(double2, double2, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.round.ss")
    float4 __builtin_ia32_roundss(float4, float4, int) pure @safe;

    */