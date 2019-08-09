/**
* Copyright: Guillaume Piolat 2016-2019.
*            Charles Gregory 2019.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.pmmintrin;

public import inteli.types;
import inteli.internals;
import inteli.emmintrin;


// Note: this header will work whether you have SSE3 enabled or not.
// With LDC, use "dflags-ldc": ["-mattr=+sse3"] or equivalent to actively 
// generate SSE3 instruction (they are often enabled with -O1 or greater).


nothrow @nogc:

/// Alternatively add and subtract packed double-precision (64-bit) 
/// floating-point elements in `a` to/from packed elements in `b`.
__m128d _mm_addsub_pd (__m128d a, __m128d b) pure @safe
{
    // Note: generates addsubpd since LDC 1.3.0 with -O1
    // PERF: for GDC, detect SSE3 and use the relevant builtin
    a.array[0] = a.array[0] - b.array[0];
    a.array[1] = a.array[1] + b.array[1];
    return a;
}
unittest
{
    auto v1 =_mm_setr_pd(1.0,2.0);
    auto v2 =_mm_setr_pd(1.0,2.0);
    assert(_mm_addsub_pd(v1,v2).array == _mm_setr_pd(0.0,4.0).array);
}

/// Alternatively add and subtract packed single-precision (32-bit) 
/// floating-point elements in `a` to/from packed elements in `b`.
float4 _mm_addsub_ps (float4 a, float4 b) pure @safe
{
    // Note: generates addsubps since LDC 1.3.0 with -O1
    // PERF: for GDC, detect SSE3 and use the relevant builtin
    a.array[0] -= b.array[0];
    a.array[1] += b.array[1];
    a.array[2] -= b.array[2];
    a.array[3] += b.array[3];    
    return a;
}
unittest
{
    auto v1 =_mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    auto v2 =_mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    assert( _mm_addsub_ps(v1,v2).array == _mm_setr_ps(0.0f, 4.0f, 0.0f, 8.0f).array );
}

version(LDC)
{
    /// Horizontally add adjacent pairs of double-precision (64-bit) 
    /// floating-point elements in `a` and `b`.
    __m128d _mm_hadd_pd (__m128d a, __m128d b) pure @safe
    {
        static if (__traits(targetHasFeature, "sse3"))
        {
            return __builtin_ia32_haddpd(a, b);
        }
        else
        {
            __m128d res;
            res[0] = a[1] + a[0];
            res[1] = b[1] + b[0];
            return res;
        }
    }
}
else
{
    // PERF: for GDC, detect SSE3 and use the relevant builtin

    /// Horizontally add adjacent pairs of double-precision (64-bit) 
    /// floating-point elements in `a` and `b`.
    __m128d _mm_hadd_pd (__m128d a, __m128d b) pure @safe
    {
        __m128d res;
        res.array[0] = a.array[1] + a.array[0];
        res.array[1] = b.array[1] + b.array[0];
        return res;
    }
}
unittest
{
    auto A =_mm_setr_pd(1.5, 2.0);
    auto B =_mm_setr_pd(1.0, 2.0);
    assert( _mm_hadd_pd(A, B).array ==_mm_setr_pd(3.5, 3.0).array );
}

version(LDC)
{
    /// Horizontally add adjacent pairs of single-precision (32-bit) 
    /// floating-point elements in `a` and `b`.
    __m128 _mm_hadd_ps (__m128 a, __m128 b) pure @safe
    {
        static if (__traits(targetHasFeature, "sse3"))
        {
            return __builtin_ia32_haddps(a, b);
        }
        else
        {
            __m128 res;
            res[0] = a[1] + a[0];
            res[1] = a[3] + a[2];
            res[2] = b[1] + b[0];
            res[3] = b[3] + b[2];
            return res;
        }
    }
}
else
{
    // PERF: for GDC, detect SSE3 and use the relevant builtin

    /// Horizontally add adjacent pairs of single-precision (32-bit) 
    /// floating-point elements in `a` and `b`.
    __m128 _mm_hadd_ps (__m128 a, __m128 b) pure @safe
    {
        __m128 res;
        res.array[0] = a.array[1] + a.array[0];
        res.array[1] = a.array[3] + a.array[2];
        res.array[2] = b.array[1] + b.array[0];
        res.array[3] = b.array[3] + b.array[2];
        return res;
    }
}
unittest
{
    __m128 A =_mm_setr_ps(1.0f, 2.0f, 3.0f, 5.0f);
    __m128 B =_mm_setr_ps(1.5f, 2.0f, 3.5f, 4.0f);
    assert( _mm_hadd_ps(A, B).array == _mm_setr_ps(3.0f, 8.0f, 3.5f, 7.5f).array );
}

version(LDC)
{
    /// Horizontally subtract adjacent pairs of double-precision (64-bit) 
    /// floating-point elements in `a` and `b`.
    __m128d _mm_hsub_pd (__m128d a, __m128d b) pure @safe
    {
        static if (__traits(targetHasFeature, "sse3"))
        {
            return __builtin_ia32_hsubpd(a, b);
        }
        else
        {
            __m128d res;
            res[0] = a[0] - a[1];
            res[1] = b[0] - b[1];
            return res;
        }
    }
}
else
{
    /// Horizontally subtract adjacent pairs of double-precision (64-bit) 
    /// floating-point elements in `a` and `b`.
    // PERF: for GDC, detect SSE3 and use the relevant builtin

    __m128d _mm_hsub_pd (__m128d a, __m128d b) pure @safe
    {
        __m128d res;
        res.array[0] = a.array[0] - a.array[1];
        res.array[1] = b.array[0] - b.array[1];
        return res;
    }
}
unittest
{
    auto A =_mm_setr_pd(1.5, 2.0);
    auto B =_mm_setr_pd(1.0, 2.0);
    assert( _mm_hsub_pd(A, B).array ==_mm_setr_pd(-0.5, -1.0).array );
}

version(LDC)
{
    /// Horizontally subtract adjacent pairs of single-precision (32-bit) 
    /// floating-point elements in `a` and `b`.
    __m128 _mm_hsub_ps (__m128 a, __m128 b) pure @safe
    {
        static if (__traits(targetHasFeature, "sse3"))
        {
            return __builtin_ia32_hsubps(a, b);
        }
        else
        {
            __m128 res;
            res[0] = a[0] - a[1];
            res[1] = a[2] - a[3];
            res[2] = b[0] - b[1];
            res[3] = b[2] - b[3];
            return res;
        }
    }
}
else
{
    /// Horizontally subtract adjacent pairs of single-precision (32-bit) 
    /// floating-point elements in `a` and `b`.
    __m128 _mm_hsub_ps (__m128 a, __m128 b) pure @safe
    {
        // PERF: GDC probably doesn't generate the right instruction
        __m128 res;
        res.array[0] = a.array[0] - a.array[1];
        res.array[1] = a.array[2] - a.array[3];
        res.array[2] = b.array[0] - b.array[1];
        res.array[3] = b.array[2] - b.array[3];
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


__m128d _mm_loaddup_pd (const(double)* mem_addr) pure @safe
{
    // Note: generates movddup since LDC 1.3 with -O1 -mattr=+sse3
    double value = *mem_addr;
    __m128d res;
    res.array[0] = value;
    res.array[1] = value;
    return res;
}
unittest
{
    double a = 7.5;
    assert(_mm_loaddup_pd(&a).array == _mm_set_pd(7.5, 7.5).array);
}

__m128d _mm_movedup_pd (__m128d a) pure @safe
{
    // Note: generates movddup since LDC 1.3 with -O1 -mattr=+sse3
    // PERF: GDC probably doesn't generate it
    a.array[1] = a.array[0];
    return a;
}
unittest
{
    __m128d A = _mm_setr_pd(7.0, 2.5);
    assert(_mm_movedup_pd(A).array == _mm_set_pd(7.0, 7.0).array);
}

/// Duplicate odd-indexed single-precision (32-bit) floating-point elements from `a`.
__m128 _mm_movehdup_ps (__m128 a) pure @safe
{
    // Generates movshdup since LDC 1.3 with -O1 -mattr=+sse3
    // PERF: GDC probably doesn't generate it
    a.array[0] = a.array[1];
    a.array[2] = a.array[3];
    return a;
}

/// Duplicate even-indexed single-precision (32-bit) floating-point elements from `a`.
__m128 _mm_moveldup_ps (__m128 a) pure @safe
{
    // Generates movsldup since LDC 1.3 with -O1 -mattr=+sse3
    // PERF: GDC probably doesn't generate it
    a.array[1] = a.array[0];
    a.array[3] = a.array[2];
    return a;
}