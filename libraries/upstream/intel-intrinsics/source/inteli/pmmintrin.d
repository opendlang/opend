/**
* SSE3 intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=SSE3
*
* Copyright: Guillaume Piolat 2016-2020.
*            Charles Gregory 2019.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.pmmintrin;

public import inteli.types;
import inteli.internals;
public import inteli.emmintrin;


// Note: this header will work whether you have SSE3 enabled or not.
// With LDC, use "dflags-ldc": ["-mattr=+sse3"] or equivalent to actively 
// generate SSE3 instruction (they are often enabled with -O1 or greater).
// With GDC, use "dflags-gdc": ["-msse3"] or equivalent to generate SSE3 instructions.


nothrow @nogc:

/// Alternatively add and subtract packed double-precision (64-bit) 
/// floating-point elements in `a` to/from packed elements in `b`.
__m128d _mm_addsub_pd (__m128d a, __m128d b) pure @trusted
{
    static if (DMD_with_DSIMD_and_SSE3)
    {
        return cast(__m128d) __simd(XMM.ADDSUBPD, cast(void16)a, cast(void16)b);
    }
    else static if (GDC_with_SSE3)
    {
        return __builtin_ia32_addsubpd(a, b);
    }
    else static if (LDC_with_SSE3)
    {
        return __builtin_ia32_addsubpd(a, b);
    }
    else
    {
        // ARM: well optimized starting with LDC 1.18.0 -O2, not disrupted by LLVM 13+
        a.ptr[0] = a.array[0] - b.array[0];
        a.ptr[1] = a.array[1] + b.array[1];
        return a;
    }
}
unittest
{
    auto v1 =_mm_setr_pd(1.0,2.0);
    auto v2 =_mm_setr_pd(1.0,2.0);
    assert(_mm_addsub_pd(v1,v2).array == _mm_setr_pd(0.0,4.0).array);
}

/// Alternatively add and subtract packed single-precision (32-bit) 
/// floating-point elements in `a` to/from packed elements in `b`.
float4 _mm_addsub_ps (float4 a, float4 b) pure @trusted
{
    static if (DMD_with_DSIMD_and_SSE3)
    {
        return cast(__m128) __simd(XMM.ADDSUBPS, cast(void16)a, cast(void16)b);
    }
    else static if (GDC_with_SSE3)
    {
        return __builtin_ia32_addsubps(a, b);
    }
    else static if (LDC_with_SSE3)
    {
        return __builtin_ia32_addsubps(a, b);
    }
    else
    {    
        a.ptr[0] -= b.array[0];
        a.ptr[1] += b.array[1];
        a.ptr[2] -= b.array[2];
        a.ptr[3] += b.array[3];
        return a;
    }
}
unittest
{
    auto v1 =_mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    auto v2 =_mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    assert( _mm_addsub_ps(v1,v2).array == _mm_setr_ps(0.0f, 4.0f, 0.0f, 8.0f).array );
}


/// Horizontally add adjacent pairs of double-precision (64-bit) 
/// floating-point elements in `a` and `b`.
__m128d _mm_hadd_pd (__m128d a, __m128d b) pure @trusted
{
    // PERF: ARM64?
    static if (DMD_with_DSIMD_and_SSE3)
    {
        return cast(__m128d) __simd(XMM.HADDPD, cast(void16)a, cast(void16)b);
    }
    else static if (GDC_or_LDC_with_SSE3)
    {
        return __builtin_ia32_haddpd(a, b);
    }
    else
    {
        __m128d res;
        res.ptr[0] = a.array[1] + a.array[0];
        res.ptr[1] = b.array[1] + b.array[0];
        return res;
    }
}
unittest
{
    auto A =_mm_setr_pd(1.5, 2.0);
    auto B =_mm_setr_pd(1.0, 2.0);
    assert( _mm_hadd_pd(A, B).array ==_mm_setr_pd(3.5, 3.0).array );
}

/// Horizontally add adjacent pairs of single-precision (32-bit) 
/// floating-point elements in `a` and `b`.
__m128 _mm_hadd_ps (__m128 a, __m128 b) pure @trusted
{
    static if (DMD_with_DSIMD_and_SSE3)
    {
        return cast(__m128) __simd(XMM.HADDPS, cast(void16)a, cast(void16)b);
    }
    else static if (GDC_or_LDC_with_SSE3)
    {
        return __builtin_ia32_haddps(a, b);
    }
    else static if (LDC_with_ARM64)
    {
        return vpaddq_f32(a, b);
    }
    else
    {    
        __m128 res;
        res.ptr[0] = a.array[1] + a.array[0];
        res.ptr[1] = a.array[3] + a.array[2];
        res.ptr[2] = b.array[1] + b.array[0];
        res.ptr[3] = b.array[3] + b.array[2];
        return res;
    }
}
unittest
{
    __m128 A =_mm_setr_ps(1.0f, 2.0f, 3.0f, 5.0f);
    __m128 B =_mm_setr_ps(1.5f, 2.0f, 3.5f, 4.0f);
    assert( _mm_hadd_ps(A, B).array == _mm_setr_ps(3.0f, 8.0f, 3.5f, 7.5f).array );
}

/// Horizontally subtract adjacent pairs of double-precision (64-bit) 
/// floating-point elements in `a` and `b`.
__m128d _mm_hsub_pd (__m128d a, __m128d b) pure @trusted
{
    static if (DMD_with_DSIMD_and_SSE3)
    {
        return cast(__m128d) __simd(XMM.HSUBPD, cast(void16)a, cast(void16)b);
    }
    else static if (GDC_or_LDC_with_SSE3)
    {
        return __builtin_ia32_hsubpd(a, b);
    }
    else
    {
        // yep, sounds optimal for ARM64 too. Strangely enough.
        __m128d res;
        res.ptr[0] = a.array[0] - a.array[1];
        res.ptr[1] = b.array[0] - b.array[1];
        return res;
    }
}
unittest
{
    auto A =_mm_setr_pd(1.5, 2.0);
    auto B =_mm_setr_pd(1.0, 2.0);
    assert( _mm_hsub_pd(A, B).array ==_mm_setr_pd(-0.5, -1.0).array );
}

/// Horizontally subtract adjacent pairs of single-precision (32-bit) 
/// floating-point elements in `a` and `b`.
__m128 _mm_hsub_ps (__m128 a, __m128 b) pure @trusted
{
    static if (DMD_with_DSIMD_and_SSE3)
    {
        return cast(__m128) __simd(XMM.HSUBPS, cast(void16)a, cast(void16)b);
    }
    else static if (GDC_or_LDC_with_SSE3)
    {
        return __builtin_ia32_hsubps(a, b);
    }
    else static if (LDC_with_ARM64)
    {
        int4 mask = [0, 0x80000000, 0, 0x80000000];
        a = cast(__m128)(cast(int4)a ^ mask);
        b = cast(__m128)(cast(int4)b ^ mask);
        return vpaddq_f32(a, b);
    }
    else
    {
        __m128 res;
        res.ptr[0] = a.array[0] - a.array[1];
        res.ptr[1] = a.array[2] - a.array[3];
        res.ptr[2] = b.array[0] - b.array[1];
        res.ptr[3] = b.array[2] - b.array[3];
        return res;
    }
}
unittest
{
    __m128 A =_mm_setr_ps(1.0f, 2.0f, 3.0f, 5.0f);
    __m128 B =_mm_setr_ps(1.5f, 2.0f, 3.5f, 4.0f);
    assert(_mm_hsub_ps(A, B).array == _mm_setr_ps(-1.0f, -2.0f, -0.5f, -0.5f).array);
}

/// Load 128-bits of integer data from unaligned memory.
// Note: The saying is LDDQU was only ever useful around 2008
// See_also: https://stackoverflow.com/questions/38370622/a-faster-integer-sse-unalligned-load-thats-rarely-used
alias _mm_lddqu_si128 = _mm_loadu_si128;

/// Load a double-precision (64-bit) floating-point element from memory into both elements of result.
__m128d _mm_loaddup_pd (const(double)* mem_addr) pure @trusted
{
    // Note: generates movddup since LDC 1.3 with -O1 -mattr=+sse3
    // Same for GDC with -O1
    double value = *mem_addr;
    __m128d res;
    res.ptr[0] = value;
    res.ptr[1] = value;
    return res;
}
unittest
{
    double a = 7.5;
    __m128d A = _mm_loaddup_pd(&a);
    double[2] correct = [7.5, 7.5];
    assert(A.array == correct);
}

/// Duplicate the low double-precision (64-bit) floating-point element from `a`.
__m128d _mm_movedup_pd (__m128d a) pure @trusted
{
    // Note: generates movddup since LDC 1.3 with -O1 -mattr=+sse3
    // Something efficient with -01 for GDC
    a.ptr[1] = a.array[0];
    return a;
}
unittest
{
    __m128d A = _mm_setr_pd(7.0, 2.5);
    assert(_mm_movedup_pd(A).array == _mm_set_pd(7.0, 7.0).array);
}

/// Duplicate odd-indexed single-precision (32-bit) floating-point elements from `a`.
__m128 _mm_movehdup_ps (__m128 a) pure @trusted
{
    static if (GDC_with_SSE3)
    {
        return __builtin_ia32_movshdup (a);
    }
    else
    {
        // Generates movshdup since LDC 1.3 with -O1 -mattr=+sse3
        a.ptr[0] = a.array[1];
        a.ptr[2] = a.array[3];
        return a;
    }
    
}
unittest
{
    __m128 A = _mm_movehdup_ps(_mm_setr_ps(1, 2, 3, 4));
    float[4] correct = [2.0f, 2, 4, 4 ];
    assert(A.array == correct);
}

/// Duplicate even-indexed single-precision (32-bit) floating-point elements from `a`.
__m128 _mm_moveldup_ps (__m128 a) pure @trusted
{
    static if (GDC_with_SSE3)
    {
        return __builtin_ia32_movsldup (a);
    }
    else
    {
        // Generates movsldup since LDC 1.3 with -O1 -mattr=+sse3
        a.ptr[1] = a.array[0];
        a.ptr[3] = a.array[2];
        return a;
    }
}
unittest
{
    __m128 A = _mm_moveldup_ps(_mm_setr_ps(1, 2, 3, 4));
    float[4] correct = [1.0f, 1, 3, 3 ];
    assert(A.array == correct);
}