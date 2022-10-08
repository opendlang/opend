/**
* AVX intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=AVX
*
* Copyright: Guillaume Piolat 2022.
*            Johan Engelen 2022.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.avxintrin;

// AVX instructions
// https://software.intel.com/sites/landingpage/IntrinsicsGuide/#techs=AVX
// Note: this header will work whether you have AVX enabled or not.
// With LDC, use "dflags-ldc": ["-mattr=+avx"] or equivalent to actively
// generate AVX instructions.
// With GDC, use "dflags-gdc": ["-mavx"] or equivalent to actively
// generate AVX instructions.

public import inteli.types;
import inteli.internals;

// Pull in all previous instruction set intrinsics.
public import inteli.tmmintrin;

nothrow @nogc:

/// Add packed double-precision (64-bit) floating-point elements in `a` and `b`.
__m256d _mm256_add_pd (__m256d a, __m256d b) pure @trusted
{
    return a + b;
}
unittest
{
    align(32) double[4] A = [-1, 2, -3, 40000];
    align(32) double[4] B = [ 9, -7, 8, -0.5];
    __m256d R = _mm256_add_pd(_mm256_load_pd(A.ptr), _mm256_load_pd(B.ptr));
    double[4] correct = [8, -5, 5, 39999.5];
    assert(R.array == correct);
}

/// Add packed single-precision (32-bit) floating-point elements in `a` and `b`.
__m256 _mm256_add_ps (__m256 a, __m256 b) pure @trusted
{
    return a + b;
}
unittest
{
    align(32) float[8] A = [-1.0f, 2, -3, 40000, 0, 3, 5, 6];
    align(32) float[8] B = [ 9.0f, -7, 8,  -0.5, 8, 7, 3, -1];
    __m256 R = _mm256_add_ps(_mm256_load_ps(A.ptr), _mm256_load_ps(B.ptr));
    float[8] correct     = [8, -5, 5, 39999.5, 8, 10, 8, 5];
    assert(R.array == correct);
}

/// Alternatively add and subtract packed double-precision (64-bit) floating-point
///  elements in `a` to/from packed elements in `b`.
__m256d _mm256_addsub_pd (__m256d a, __m256d b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_addsubpd256(a, b);
    }
    else static if (LDC_with_AVX)
    {
        return __builtin_ia32_addsubpd256(a, b);
    }
    else
    {
        //// Note: GDC x86 generates addsubpd since GDC 11.1 with -O3
        ////       LDC x86 generates addsubpd since LDC 1.18 with -O2
        //// LDC ARM: not fantastic, ok since LDC 1.18 -O2
        a.ptr[0] = a.array[0] + (-b.array[0]);
        a.ptr[1] = a.array[1] + b.array[1];
        a.ptr[2] = a.array[2] + (-b.array[2]);
        a.ptr[3] = a.array[3] + b.array[3];
        return a;
    }
}
unittest
{
    align(32) double[4] A = [-1, 2, -3, 40000];
    align(32) double[4] B = [ 9, -7, 8, -0.5];
    __m256d R = _mm256_addsub_pd(_mm256_load_pd(A.ptr), _mm256_load_pd(B.ptr));
    double[4] correct = [-10, -5, -11, 39999.5];
    assert(R.array == correct);
}

/// Alternatively add and subtract packed single-precision (32-bit) floating-point elements 
/// in `a` to/from packed elements in `b`.
__m256 _mm256_addsub_ps (__m256 a, __m256 b) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_addsubps256(a, b);
    }
    else static if (LDC_with_AVX)
    {
        return __builtin_ia32_addsubps256(a, b);
    }
    else
    {
        // Note: GDC x86 generates addsubps since GDC 11 -O3
        //               and in absence of AVX, a pair of SSE3 addsubps since GDC 12 -O2
        //       LDC x86 generates addsubps since LDC 1.18 -O2
        //               and in absence of AVX, a pair of SSE3 addsubps since LDC 1.1 -O1
        // LDC ARM: neat output since LDC 1.21 -O2
   
        a.ptr[0] = a.array[0] + (-b.array[0]);
        a.ptr[1] = a.array[1] + b.array[1];
        a.ptr[2] = a.array[2] + (-b.array[2]);
        a.ptr[3] = a.array[3] + b.array[3];
        a.ptr[4] = a.array[4] + (-b.array[4]);
        a.ptr[5] = a.array[5] + b.array[5];
        a.ptr[6] = a.array[6] + (-b.array[6]);
        a.ptr[7] = a.array[7] + b.array[7];
        return a;
    }
}
unittest
{
    align(32) float[8] A = [-1.0f,  2,  -3, 40000,    0, 3,  5,  6];
    align(32) float[8] B = [ 9.0f, -7,   8,  -0.5,    8, 7,  3, -1];
    __m256 R = _mm256_addsub_ps(_mm256_load_ps(A.ptr), _mm256_load_ps(B.ptr));
    float[8] correct     = [  -10, -5, -11, 39999.5, -8, 10, 2,  5];
    assert(R.array == correct);
}

/// Compute the bitwise AND of packed double-precision (64-bit) floating-point elements in `a` and `b`.
__m256d _mm256_and_pd (__m256d a, __m256d b) pure @trusted
{
    // Note: GCC avxintrin.h uses the builtins for AND NOTAND OR of _ps and _pd,
    //       but those do not seem needed at any optimization level.
    return cast(__m256d)(cast(__m256i)a & cast(__m256i)b);
}
unittest
{
    double a = 4.32;
    double b = -78.99;
    long correct = (*cast(long*)(&a)) & (*cast(long*)(&b));
    __m256d A = _mm256_set_pd(a, b, a, b);
    __m256d B = _mm256_set_pd(b, a, b, a);
    long4 R = cast(long4)( _mm256_and_pd(A, B) );
    assert(R.array[0] == correct);
    assert(R.array[1] == correct);
    assert(R.array[2] == correct);
    assert(R.array[3] == correct);
}

/// Compute the bitwise AND of packed single-precision (32-bit) floating-point elements in `a` and `b`.
__m256 _mm256_and_ps (__m256 a, __m256 b) pure @trusted
{
    return cast(__m256)(cast(__m256i)a & cast(__m256i)b);
}
unittest
{
    float a = 4.32f;
    float b = -78.99f;
    int correct = (*cast(int*)(&a)) & (*cast(int*)(&b));
    __m256 A = _mm256_set_ps(a, b, a, b, a, b, a, b);
    __m256 B = _mm256_set_ps(b, a, b, a, b, a, b, a);
    int8 R = cast(int8)( _mm256_and_ps(A, B) );
    foreach(i; 0..8)
        assert(R.array[i] == correct);
}

/// Compute the bitwise NOT of packed double-precision (64-bit) floating-point elements in `a`
/// and then AND with b.
__m256d _mm256_andnot_pd (__m256d a, __m256d b) pure @trusted
{
    // PERF DMD
    __m256i notA = _mm256_not_si256(cast(__m256i)a);
    __m256i ib = cast(__m256i)b;
    __m256i ab = notA & ib;
    return cast(__m256d)ab;
}
unittest
{
    double a = 4.32;
    double b = -78.99;
    long notA = ~ ( *cast(long*)(&a) );
    long correct = notA & (*cast(long*)(&b));
    __m256d A = _mm256_set_pd(a, a, a, a);
    __m256d B = _mm256_set_pd(b, b, b, b);
    long4 R = cast(long4)( _mm256_andnot_pd(A, B) );
    foreach(i; 0..4)
        assert(R.array[i] == correct);
}

/// Compute the bitwise NOT of packed single-precision (32-bit) floating-point elements in `a`
/// and then AND with b.
__m256 _mm256_andnot_ps (__m256 a, __m256 b) pure @trusted
{
    // PERF DMD
    __m256i notA = _mm256_not_si256(cast(__m256i)a);
    __m256i ib = cast(__m256i)b;
    __m256i ab = notA & ib;
    return cast(__m256)ab;
}
unittest
{
    float a = 4.32f;
    float b = -78.99f;
    int notA = ~ ( *cast(int*)(&a) );
    int correct = notA & (*cast(int*)(&b));
    __m256 A = _mm256_set1_ps(a);
    __m256 B = _mm256_set1_ps(b);
    int8 R = cast(int8)( _mm256_andnot_ps(A, B) );
    foreach(i; 0..8)
        assert(R.array[i] == correct);
}

/// Blend packed double-precision (64-bit) floating-point elements from `a` and `b` using control 
/// mask `imm8`.
__m256d _mm256_blend_pd(int imm8)(__m256d a, __m256d b)
{
    static assert(imm8 >= 0 && imm8 < 16);

    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_blendpd256 (a, b, imm8);
    }
    else
    {
        // Works great with LDC.
        double4 r;
        for (int n = 0; n < 4; ++n)
        {
            r.ptr[n] = (imm8 & (1 << n)) ? b.array[n] : a.array[n];
        }
        return r;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(0, 1, 2, 3);
    __m256d B = _mm256_setr_pd(8, 9, 10, 11);
    double4 C = _mm256_blend_pd!0x06(A, B);
    double[4] correct =    [0, 9, 10, 3];
    assert(C.array == correct);
}

/// Blend packed single-precision (32-bit) floating-point elements from `a` and `b` using control 
/// mask `imm8`.
__m256 _mm256_blend_ps(int imm8)(__m256 a, __m256 b) pure @trusted
{
    static assert(imm8 >= 0 && imm8 < 256);
    // PERF DMD
    // PERF ARM64: not awesome with some constant values, up to 8/9 instructions
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_blendps256 (a, b, imm8);
    }
    else
    {
        // LDC x86: vblendps generated since LDC 1.27 -O1
        float8 r;
        for (int n = 0; n < 8; ++n)
        {
            r.ptr[n] = (imm8 & (1 << n)) ? b.array[n] : a.array[n];
        }
        return r;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(0, 1,  2,  3,  4,  5,  6,  7);
    __m256 B = _mm256_setr_ps(8, 9, 10, 11, 12, 13, 14, 15);
    float8 C = _mm256_blend_ps!0xe7(A, B);
    float[8] correct =       [8, 9, 10,  3,  4, 13, 14, 15];
    assert(C.array == correct);
}

/// Blend packed double-precision (64-bit) floating-point elements from `a` and `b` using mask.
__m256d _mm256_blendv_pd (__m256d a, __m256d b, __m256d mask) @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        // Amazingly enough, GCC/GDC generates the vblendvpd instruction
        // with -mavx2 but not -mavx.
        // Not sure what is the reason, and there is a replacement sequence.
        // PERF: Sounds like a bug, similar to _mm_blendv_pd
        return __builtin_ia32_blendvpd256(a, b, mask);
    }
    else static if (LDC_with_AVX)
    {
        return __builtin_ia32_blendvpd256(a, b, mask);
    }
    else
    {
        // LDC x86: vblendvpd since LDC 1.27 -O2
        //     arm64: only 4 instructions, since LDC 1.27 -O2
        __m256d r;
        long4 lmask = cast(long4)mask;
        for (int n = 0; n < 4; ++n)
        {
            r.ptr[n] = (lmask.array[n] < 0) ? b.array[n] : a.array[n];
        }
        return r;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(1.0, 2.0, 3.0, 4.0);
    __m256d B = _mm256_setr_pd(5.0, 6.0, 7.0, 8.0);
    __m256d M = _mm256_setr_pd(-3.0, 2.0, 1.0, -4.0);
    __m256d R = _mm256_blendv_pd(A, B, M);
    double[4] correct1 = [5.0, 2.0, 3.0, 8.0];
    assert(R.array == correct1); // Note: probably the same NaN-mask oddity exist on arm64+linux than with _mm_blendv_pd
}

/// Blend packed single-precision (32-bit) floating-point elements from `a` and `b` 
/// using `mask`.
/// Blend packed single-precision (32-bit) floating-point elements from `a` and `b` 
/// using `mask`.
__m256 _mm256_blendv_ps (__m256 a, __m256 b, __m256 mask) @trusted
{
    // PERF DMD
    // PERF LDC/GDC without AVX could use two intrinsics for each part
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_blendvps256(a, b, mask);
    }
    else static if (LDC_with_AVX)
    {
        return __builtin_ia32_blendvps256(a, b, mask);
    }
    else static if (LDC_with_ARM64)
    {
        int8 shift;
        shift = 31;
        int8 lmask = cast(int8)mask >> shift;     
        int8 ia = cast(int8)a;   
        int8 ib = cast(int8)b;
        return cast(__m256)(ia ^ ((ia ^ ib) & lmask));
    }
    else
    {
        __m256 r = void; // PERF =void;
        int8 lmask = cast(int8)mask;
        for (int n = 0; n < 8; ++n)
        {
            r.ptr[n] = (lmask.array[n] < 0) ? b.array[n] : a.array[n];
        }
        return r;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(1.0f, 2.0f, 3.0f, 4.0f, 1.0f, 2.0f, 3.0f, 4.0f);
    __m256 B = _mm256_setr_ps(5.0f, 6.0f, 7.0f, 8.0f, 5.0f, 6.0f, 7.0f, 8.0f);
    __m256 M = _mm256_setr_ps(-3.0f, 2.0f, 1.0f, -4.0f, -3.0f, 2.0f, 1.0f, -4.0f);
    __m256 R = _mm256_blendv_ps(A, B, M);
    float[8] correct1 = [5.0f, 2.0f, 3.0f, 8.0f, 5.0f, 2.0f, 3.0f, 8.0f];
    assert(R.array == correct1); // Note: probably the same NaN-mask oddity exist on arm64+linux than with _mm_blendv_pd
}

/// Broadcast 128 bits from memory (composed of 2 packed double-precision (64-bit)
/// floating-point elements) to all elements.
/// This effectively duplicates the 128-bit vector.
__m256d _mm256_broadcast_pd (const(__m128d)* mem_addr) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_vbroadcastf128_pd256(cast(float4*)mem_addr);
    }
    else
    {
        const(double)* p = cast(const(double)*) mem_addr;
        __m256d r;
        r.ptr[0] = p[0];
        r.ptr[1] = p[1];
        r.ptr[2] = p[0];
        r.ptr[3] = p[1];
        return r;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(3, -4);
    __m256d B = _mm256_broadcast_pd(&A);
    double[4] correct = [3, -4, 3, -4];
    assert(B.array == correct);
}

/// Broadcast 128 bits from memory (composed of 4 packed single-precision (32-bit) 
/// floating-point elements) to all elements.
/// This effectively duplicates the 128-bit vector.
__m256 _mm256_broadcast_ps (const(__m128)* mem_addr) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_vbroadcastf128_ps256(cast(float4*)mem_addr);
    }   
    else
    {
        const(float)* p = cast(const(float)*)mem_addr;
        __m256 r;
        r.ptr[0] = p[0];
        r.ptr[1] = p[1];
        r.ptr[2] = p[2];
        r.ptr[3] = p[3];
        r.ptr[4] = p[0];
        r.ptr[5] = p[1];
        r.ptr[6] = p[2];
        r.ptr[7] = p[3];
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1, 2, 3, -4);
    __m256 B = _mm256_broadcast_ps(&A);
    float[8] correct = [1.0f, 2, 3, -4, 1, 2, 3, -4];
    assert(B.array == correct);
}

/// Broadcast a single-precision (32-bit) floating-point element from memory to all elements.
__m256d _mm256_broadcast_sd (const(double)* mem_addr) pure @trusted
{
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_vbroadcastsd256(mem_addr);
    }
    else
    {
        double a = *mem_addr;
        __m256d r;
        r.ptr[0] = a;
        r.ptr[1] = a;
        r.ptr[2] = a;
        r.ptr[3] = a;
        return r;
    }
}
unittest
{
    double t = 7.5f;
    __m256d A = _mm256_broadcast_sd(&t);
    double[4] correct = [7.5, 7.5, 7.5, 7.5];
    assert(A.array == correct);
}

/// Broadcast a single-precision (32-bit) floating-point element from memory to all elements.
__m128 _mm_broadcast_ss (const(float)* mem_addr) pure @trusted
{
    // PERF: DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_vbroadcastss(mem_addr);
    }
    else
    {
        float a = *mem_addr;
        __m128 r;
        r.ptr[0] = a;
        r.ptr[1] = a;
        r.ptr[2] = a;
        r.ptr[3] = a;
        return r;
    }
}
unittest
{
    float t = 7.5f;
    __m128 A = _mm_broadcast_ss(&t);
    float[4] correct = [7.5f, 7.5f, 7.5f, 7.5f];
    assert(A.array == correct);
}

__m256 _mm256_broadcast_ss (const(float)* mem_addr)
{
    // PERF: DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_vbroadcastss256 (mem_addr);
    }
    else
    {
        float a = *mem_addr;
        __m256 r = __m256(a);
        return r;
    }
}
unittest
{
    float t = 7.5f;
    __m256 A = _mm256_broadcast_ss(&t);
    float[8] correct = [7.5f, 7.5f, 7.5f, 7.5f, 7.5f, 7.5f, 7.5f, 7.5f];
    assert(A.array == correct);
}

/// Cast vector of type `__m256d` to type `__m256`.
__m256 _mm256_castpd_ps (__m256d a) pure @safe
{
    return cast(__m256)a;
}

/// Cast vector of type `__m256d` to type `__m256i`.
__m256i _mm256_castpd_si256 (__m256d a) pure @safe
{
    return cast(__m256i)a;
}

/// Cast vector of type `__m128d` to type `__m256d`; the upper 128 bits of the result are undefined.
__m256d _mm256_castpd128_pd256 (__m128d a) pure @trusted
{
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_pd256_pd(a);
    }
    else
    {
        __m256d r = void;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        return r;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(4.0, -6.125);
    __m256d B = _mm256_castpd128_pd256(A);
    assert(B.array[0] == 4.0);
    assert(B.array[1] == -6.125);
}

/// Cast vector of type `__m256d` to type `__m128d`; the upper 128 bits of `a` are lost.
__m128d _mm256_castpd256_pd128 (__m256d a) pure @trusted
{
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_pd_pd256(a);
    }
    else
    {
        __m128d r;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        return r;
    }
}
unittest
{
    __m256d A = _mm256_set_pd(1, 2, -6.25, 4.0);
    __m128d B = _mm256_castpd256_pd128(A);
    assert(B.array[0] == 4.0);
    assert(B.array[1] == -6.25);
}

/// Cast vector of type `__m256` to type `__m256d`.
__m256d _mm256_castps_pd (__m256 a) pure @safe
{
    return cast(__m256d)a;
}

/// Cast vector of type `__m256` to type `__m256i`.
__m256i _mm256_castps_si256 (__m256 a) pure @safe
{
    return cast(__m256i)a;
}

/// Cast vector of type `__m128` to type `__m256`; the upper 128 bits of the result are undefined.
__m256 _mm256_castps128_ps256 (__m128 a) pure @trusted
{
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_ps256_ps(a);
    }
    else
    {
        __m256 r = void;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        r.ptr[2] = a.array[2];
        r.ptr[3] = a.array[3];
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2, 3, 4);
    __m256 B = _mm256_castps128_ps256(A);
    float[4] correct = [1.0f, 2, 3, 4];
    assert(B.array[0..4] == correct);
}

/// Cast vector of type `__m256` to type `__m128`. The upper 128-bit of `a` are lost.
__m128 _mm256_castps256_ps128 (__m256 a) pure @trusted
{
    return *cast(const(__m128)*)(&a);
}
unittest
{
    __m256 A = _mm256_setr_ps(1.0f, 2, 3, 4, 5, 6, 7, 8);
    __m128 B = _mm256_castps256_ps128(A);
    float[4] correct = [1.0f, 2, 3, 4];
    assert(B.array == correct);
}

/// Cast vector of type `__m128i` to type `__m256i`; the upper 128 bits of the result are undefined.
__m256i _mm256_castsi128_si256 (__m128i a) pure @trusted
{
    long2 la = cast(long2)a;
    long4 r = void;
    r.ptr[0] = la.array[0];
    r.ptr[1] = la.array[1];
    return r;
}
unittest
{
    __m128i A = _mm_setr_epi64(-1, 42);
    __m256i B = _mm256_castsi128_si256(A);
    long[2] correct = [-1, 42];
    assert(B.array[0..2] == correct);
}

/// Cast vector of type `__m256i` to type `__m256d`.
__m256d _mm256_castsi256_pd (__m256i a) pure @safe
{
    return cast(__m256d)a;
}

/// Cast vector of type `__m256i` to type `__m256`.
__m256 _mm256_castsi256_ps (__m256i a) pure @safe
{
    return cast(__m256)a;
}

/// Cast vector of type `__m256i` to type `__m128i`. The upper 128-bit of `a` are lost.
__m128i _mm256_castsi256_si128 (__m256i a) pure @trusted
{
    long2 r = void;
    r.ptr[0] = a.array[0];
    r.ptr[1] = a.array[1];
    return cast(__m128i)r;
}
unittest
{
    long4 A;
    A.ptr[0] = -1;
    A.ptr[1] = 42;
    long2 B = cast(long2)(_mm256_castsi256_si128(A));
    long[2] correct = [-1, 42];
    assert(B.array[0..2] == correct);
}


// TODO __m256d _mm256_ceil_pd (__m256d a)
// TODO __m256 _mm256_ceil_ps (__m256 a)
// TODO __m128d _mm_cmp_pd (__m128d a, __m128d b, const int imm8)
// TODO __m256d _mm256_cmp_pd (__m256d a, __m256d b, const int imm8)
// TODO __m128 _mm_cmp_ps (__m128 a, __m128 b, const int imm8)
// TODO __m256 _mm256_cmp_ps (__m256 a, __m256 b, const int imm8)
// TODO __m128d _mm_cmp_sd (__m128d a, __m128d b, const int imm8)
// TODO __m128 _mm_cmp_ss (__m128 a, __m128 b, const int imm8)
// TODO __m256d _mm256_cvtepi32_pd (__m128i a)
// TODO __m256 _mm256_cvtepi32_ps (__m256i a)
// TODO __m128i _mm256_cvtpd_epi32 (__m256d a)
// TODO __m128 _mm256_cvtpd_ps (__m256d a)
// TODO __m256i _mm256_cvtps_epi32 (__m256 a)
// TODO __m256d _mm256_cvtps_pd (__m128 a)
// TODO double _mm256_cvtsd_f64 (__m256d a)
// TODO int _mm256_cvtsi256_si32 (__m256i a)
// TODO float _mm256_cvtss_f32 (__m256 a)
// TODO __m128i _mm256_cvttpd_epi32 (__m256d a)
// TODO __m256i _mm256_cvttps_epi32 (__m256 a)

/// Divide packed double-precision (64-bit) floating-point elements in `a` by packed elements in `b`.
__m256d _mm256_div_pd (__m256d a, __m256d b) pure @safe
{
    return a / b;
}
unittest
{
    __m256d a = [1.5, -2.0, 3.0, 1.0];
    a = _mm256_div_pd(a, a);
    double[4] correct = [1.0, 1.0, 1.0, 1.0];
    assert(a.array == correct);
}

/// Divide packed single-precision (32-bit) floating-point elements in `a` by packed elements in `b`.
__m256 _mm256_div_ps (__m256 a, __m256 b) pure @safe
{
    return a / b;
}
unittest
{
    __m256 a = [1.5f, -2.0f, 3.0f, 1.0f, 4.5f, -5.0f, 6.0f, 7.0f];
    a = _mm256_div_ps(a, a);
    float[8] correct = [1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f, 1.0f];
    assert(a.array == correct);
}

/// Conditionally multiply the packed single-precision (32-bit) floating-point elements in `a` and 
/// `b` using the high 4 bits in `imm8`, sum the four products, and conditionally store the sum 
/// using the low 4 bits of `imm8`.
__m256 _mm256_dp_ps(int imm8)(__m256 a, __m256 b)
{
    // PERF DMD
    // PERF without AVX, can use 2 _mm_dp_ps exactly (beware the imm8 is tricky)
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_dpps256(a, b, cast(byte)imm8);
    }
    else static if (LDC_with_AVX)
    {
        return __builtin_ia32_dpps256(a, b, cast(byte)imm8);
    }
    else
    {
        __m256 zero = _mm256_setzero_ps();
        enum ubyte op = (imm8 >>> 4) & 15;
        __m256 temp = _mm256_blend_ps!( op | (op << 4) )(zero, a * b);
        float lo = temp.array[0] + temp.array[1] + temp.array[2] + temp.array[3];
        float hi = temp.array[4] + temp.array[5] + temp.array[6] + temp.array[7];
        __m256 r = _mm256_set_m128(_mm_set1_ps(hi), _mm_set1_ps(lo));
        enum ubyte op2 = (imm8 & 15);
        return _mm256_blend_ps!(op2 | (op2 << 4))(zero, r);
    }
}
unittest
{
    // Products:                 9    14    20   24     6    16    12   -24
    __m256 A = _mm256_setr_ps(1.0f, 2.0f, 4.0f, 8.0f, 1.0f, 2.0f, 4.0f, 8.0f);
    __m256 B = _mm256_setr_ps(9.0f, 7.0f, 5.0f, 3.0f, 6.0f, 8.0f, 3.0f,-3.0f);
    float8 R1 = _mm256_dp_ps!(0xf0 + 0xf)(A, B);
    float8 R2 = _mm256_dp_ps!(0x30 + 0x5)(A, B);
    float8 R3 = _mm256_dp_ps!(0x50 + 0xa)(A, B);
    float[8] correct1 =   [67.0f, 67.0f, 67.0f,67.0f,  10,   10,   10,  10];
    float[8] correct2 =   [23.0f, 0.0f, 23.0f,  0.0f,  22,    0,   22,   0];
    float[8] correct3 =   [0.0f, 29.0f, 0.0f,  29.0f,   0,   18,    0,  18];
    assert(R1.array == correct1);
    assert(R2.array == correct2);
    assert(R3.array == correct3);
}

/// Extract a 32-bit integer from `a`, selected with `imm8`.
int _mm256_extract_epi32 (__m256i a, const int imm8) pure @trusted
{
    return (cast(int8)a).array[imm8 & 7];
}
unittest
{
    align(16) int[8] data = [-1, 2, -3, 4, 9, -7, 8, -6];
    auto A = _mm256_loadu_si256(cast(__m256i*) data.ptr);
    assert(_mm256_extract_epi32(A, 0) == -1);
    assert(_mm256_extract_epi32(A, 1 + 8) == 2);
    assert(_mm256_extract_epi32(A, 3 + 16) == 4);
    assert(_mm256_extract_epi32(A, 7 + 32) == -6);
}

/// Extract a 64-bit integer from `a`, selected with `index`.
long _mm256_extract_epi64 (__m256i a, const int index) pure @safe
{
    return a.array[index & 3];
}
unittest
{
    __m256i A = _mm256_setr_epi64x(-7, 6, 42, 0);
    assert(_mm256_extract_epi64(A, -8) == -7);
    assert(_mm256_extract_epi64(A, 1) == 6);
    assert(_mm256_extract_epi64(A, 2 + 4) == 42);
}


// TODO __m128d _mm256_extractf128_pd (__m256d a, const int imm8)
// TODO __m128 _mm256_extractf128_ps (__m256 a, const int imm8)
// TODO __m128i _mm256_extractf128_si256 (__m256i a, const int imm8)
// TODO __m256d _mm256_floor_pd (__m256d a)
// TODO __m256 _mm256_floor_ps (__m256 a)
// TODO __m256d _mm256_hadd_pd (__m256d a, __m256d b)
// TODO __m256 _mm256_hadd_ps (__m256 a, __m256 b)
// TODO __m256d _mm256_hsub_pd (__m256d a, __m256d b)
// TODO __m256 _mm256_hsub_ps (__m256 a, __m256 b)
// TODO __m256i _mm256_insert_epi16 (__m256i a, __int16 i, const int index)
// TODO __m256i _mm256_insert_epi32 (__m256i a, __int32 i, const int index)
// TODO __m256i _mm256_insert_epi64 (__m256i a, __int64 i, const int index)
// TODO __m256i _mm256_insert_epi8 (__m256i a, __int8 i, const int index)
// TODO __m256d _mm256_insertf128_pd (__m256d a, __m128d b, int imm8)
// TODO __m256 _mm256_insertf128_ps (__m256 a, __m128 b, int imm8)
// TODO __m256i _mm256_insertf128_si256 (__m256i a, __m128i b, int imm8)

/// Load 256-bits of integer data from unaligned memory into dst. 
/// This intrinsic may perform better than `_mm256_loadu_si256` when the data crosses a cache 
/// line boundary.
__m256i _mm256_lddqu_si256(const(__m256i)* mem_addr) @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_AVX)
    {
        return cast(__m256i) __builtin_ia32_lddqu256(cast(const(char)*)mem_addr);
    }
    else static if (LDC_with_AVX)
    {
        // unfortunately builtin is not marked pure
        return cast(__m256i) __builtin_ia32_lddqu256(cast(const void*)mem_addr);
    }
    else
        return _mm256_loadu_si256(mem_addr);
}
unittest
{
    int[10] correct = [0, -1, 2, -3, 4, 9, -7, 8, -6, 34];
    int8 A = cast(int8) _mm256_lddqu_si256(cast(__m256i*) &correct[1]);
    assert(A.array == correct[1..9]);
}

/// Load 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) 
/// from memory. `mem_addr` must be aligned on a 32-byte boundary or a general-protection 
/// exception may be generated.
__m256d _mm256_load_pd (const(double)* mem_addr) pure @trusted
{
    return *cast(__m256d*)mem_addr;
}
unittest
{
    static immutable align(32) double[4] correct = [1.0, 2.0, 3.5, -42.0];
    __m256d A = _mm256_load_pd(correct.ptr);
    assert(A.array == correct);
}

/// Load 256-bits (composed of 8 packed single-precision (32-bit) 
/// floating-point elements) from memory. 
/// `mem_addr` must be aligned on a 32-byte boundary or a 
/// general-protection exception may be generated.
__m256 _mm256_load_ps (const(float)* mem_addr) pure @trusted
{
    return *cast(__m256*)mem_addr;
}
unittest
{
    static immutable align(32) float[8] correct = 
        [1.0, 2.0, 3.5, -42.0, 7.43f, 0.0f, 3, 2];
    __m256 A = _mm256_load_ps(correct.ptr);
    assert(A.array == correct);
}

/// Load 256-bits of integer data from memory. `mem_addr` does not need to be aligned on
/// any particular boundary.
// MAYDO: take void* as input, make that @system
__m256i _mm256_loadu_si256 (const(__m256i)* mem_addr) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return cast(__m256i) __builtin_ia32_loaddqu256(cast(const(char)*) mem_addr);
    }
    else version(LDC)
    {
        return loadUnaligned!(__m256i)(cast(long*)mem_addr);
    }
    else
    {
        const(long)* p = cast(const(long)*)mem_addr; 
        long4 r;
        r.ptr[0] = p[0];
        r.ptr[1] = p[1];
        r.ptr[2] = p[2];
        r.ptr[3] = p[3];
        return r;
    }
}
unittest
{
    align(16) int[8] correct = [-1, 2, -3, 4, 9, -7, 8, -6];
    int8 A = cast(int8) _mm256_loadu_si256(cast(__m256i*) correct.ptr);
    assert(A.array == correct);
}

/// Load 256-bits of integer data from memory. `mem_addr` must be aligned on a 
/// 32-byte boundary or a general-protection exception may be generated.
__m256i _mm256_load_si256 (const(void)* mem_addr) pure @trusted // TODO @system
{
    return *cast(__m256i*)mem_addr;
}
unittest
{
    static immutable align(64) long[4] correct = [1, -2, long.min, long.max];
    __m256i A = _mm256_load_si256(correct.ptr);
    assert(A.array == correct);
}

/// Load 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) 
/// from memory. `mem_addr` does not need to be aligned on any particular boundary.
__m256d _mm256_loadu_pd (const(void)* mem_addr) pure @trusted // TODO @system
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_loadupd256 ( cast(const(double)*) mem_addr);
    }
    else version(LDC)
    {
        return loadUnaligned!(__m256d)(cast(double*)mem_addr);
    }    
    else
    {
        const(double)* p = cast(const(double)*)mem_addr; 
        double4 r;
        r.ptr[0] = p[0];
        r.ptr[1] = p[1];
        r.ptr[2] = p[2];
        r.ptr[3] = p[3];
        return r;
    }
}
unittest
{
    double[4] correct = [1.0, -2.0, 0.0, 768.5];
    __m256d A = _mm256_loadu_pd(correct.ptr);
    assert(A.array == correct);
}

/// Load 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from memory.
/// `mem_addr` does not need to be aligned on any particular boundary.
__m256 _mm256_loadu_ps (const(float)* mem_addr) pure @trusted // TODO @system
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_loadups256 ( cast(const(float)*) mem_addr);
    }
    else version(LDC)
    {
        return loadUnaligned!(__m256)(cast(float*)mem_addr);
    }    
    else
    {
        const(float)* p = cast(const(float)*)mem_addr; 
        float8 r = void;
        r.ptr[0] = p[0];
        r.ptr[1] = p[1];
        r.ptr[2] = p[2];
        r.ptr[3] = p[3];
        r.ptr[4] = p[4];
        r.ptr[5] = p[5];
        r.ptr[6] = p[6];
        r.ptr[7] = p[7];
        return r;
    }
}
unittest
{
    align(32) float[10] correct = [0.0f, 1, 2, 3, 4, 5, 6, 7, 8, 9];
    __m256 A = _mm256_loadu_ps(&correct[1]);
    assert(A.array == correct[1..9]);
}

// TODO __m256 _mm256_loadu2_m128 (float const* hiaddr, float const* loaddr)
// TODO __m256d _mm256_loadu2_m128d (double const* hiaddr, double const* loaddr)
// TODO __m256i _mm256_loadu2_m128i (__m128i const* hiaddr, __m128i const* loaddr)
// TODO __m128d _mm_maskload_pd (double const * mem_addr, __m128i mask)
// TODO __m256d _mm256_maskload_pd (double const * mem_addr, __m256i mask)
// TODO __m128 _mm_maskload_ps (float const * mem_addr, __m128i mask)
// TODO __m256 _mm256_maskload_ps (float const * mem_addr, __m256i mask)
// TODO void _mm_maskstore_pd (double * mem_addr, __m128i mask, __m128d a)
// TODO void _mm256_maskstore_pd (double * mem_addr, __m256i mask, __m256d a)
// TODO void _mm_maskstore_ps (float * mem_addr, __m128i mask, __m128 a)
// TODO void _mm256_maskstore_ps (float * mem_addr, __m256i mask, __m256 a)
// TODO __m256d _mm256_max_pd (__m256d a, __m256d b)
// TODO __m256 _mm256_max_ps (__m256 a, __m256 b)
// TODO __m256d _mm256_min_pd (__m256d a, __m256d b)
// TODO __m256 _mm256_min_ps (__m256 a, __m256 b)
// TODO __m256d _mm256_movedup_pd (__m256d a)
// TODO __m256 _mm256_movehdup_ps (__m256 a)
// TODO __m256 _mm256_moveldup_ps (__m256 a)
// TODO int _mm256_movemask_pd (__m256d a)
// TODO int _mm256_movemask_ps (__m256 a)

/// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`.
__m256d _mm256_mul_pd (__m256d a, __m256d b) pure @safe
{
    return a * b;
}
unittest
{
    __m256d a = [-2.0, 1.5, -2.0, 1.5];
    a = _mm256_mul_pd(a, a);
    assert(a.array == [4.0, 2.25, 4.0, 2.25]);
}

/// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`.
__m256 _mm256_mul_ps (__m256 a, __m256 b) pure @safe
{
    return a * b;
}
unittest
{
    __m256 a = [1.5f, -2.0f, 3.0f, 1.0f, 1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm256_mul_ps(a, a);
    float[8] correct = [2.25f, 4.0f, 9.0f, 1.0f, 2.25f, 4.0f, 9.0f, 1.0f];
    assert(a.array == correct);
}


/// Compute the bitwise NOT of 256 bits in `a`. #BONUS
__m256i _mm256_not_si256 (__m256i a) pure @safe
{
    return ~a;
}
unittest
{
    __m256i A = _mm256_set1_epi64x(-748);
    long4 notA = cast(long4) _mm256_not_si256(A);
    int[4] correct = [747, 747, 747, 747];
    assert(notA.array == correct);
}

/// Compute the bitwise OR of packed double-precision (64-bit) floating-point elements in `a` and `b`.
__m256d _mm256_or_pd (__m256d a, __m256d b) pure @safe
{
    return cast(__m256d)( cast(__m256i)a | cast(__m256i)b );
}

/// Compute the bitwise OR of packed single-precision (32-bit) floating-point elements in `a` and `b`.
__m256 _mm256_or_ps (__m256 a, __m256 b) pure @safe
{
    return cast(__m256)( cast(__m256i)a | cast(__m256i)b );
}

// TODO __m128d _mm_permute_pd (__m128d a, int imm8)
// TODO __m256d _mm256_permute_pd (__m256d a, int imm8)
// TODO __m128 _mm_permute_ps (__m128 a, int imm8)
// TODO __m256 _mm256_permute_ps (__m256 a, int imm8)
// TODO __m256d _mm256_permute2f128_pd (__m256d a, __m256d b, int imm8)
// TODO __m256 _mm256_permute2f128_ps (__m256 a, __m256 b, int imm8)
// TODO __m256i _mm256_permute2f128_si256 (__m256i a, __m256i b, int imm8)
// TODO __m128d _mm_permutevar_pd (__m128d a, __m128i b)
// TODO __m256d _mm256_permutevar_pd (__m256d a, __m256i b)
// TODO __m128 _mm_permutevar_ps (__m128 a, __m128i b)
// TODO __m256 _mm256_permutevar_ps (__m256 a, __m256i b)
// TODO __m256 _mm256_rcp_ps (__m256 a)
// TODO __m256d _mm256_round_pd (__m256d a, int rounding)
// TODO __m256 _mm256_round_ps (__m256 a, int rounding)
// TODO __m256 _mm256_rsqrt_ps (__m256 a)
// TODO __m256i _mm256_set_epi16 (short e15, short e14, short e13, short e12, short e11, short e10, short e9, short e8, short e7, short e6, short e5, short e4, short e3, short e2, short e1, short e0)
// TODO __m256i _mm256_set_epi32 (int e7, int e6, int e5, int e4, int e3, int e2, int e1, int e0)

/// Set packed 64-bit integers with the supplied values.
__m256i _mm256_set_epi64x (long e3, long e2, long e1, long e0) pure @trusted
{
    long4 r = void;
    r.ptr[0] = e0;
    r.ptr[1] = e1;
    r.ptr[2] = e2;
    r.ptr[3] = e3;
    return r;
}
unittest
{
    __m256i A = _mm256_set_epi64x(-1, 42, long.min, long.max);
    long[4] correct = [long.max, long.min, 42, -1];
    assert(A.array == correct);
}

// TODO __m256i _mm256_set_epi8 (char e31, char e30, char e29, char e28, char e27, char e26, char e25, char e24, char e23, char e22, char e21, char e20, char e19, char e18, char e17, char e16, char e15, char e14, char e13, char e12, char e11, char e10, char e9, char e8, char e7, char e6, char e5, char e4, char e3, char e2, char e1, char e0)

/// Set packed `__m256d` vector with the supplied values.
__m256 _mm256_set_m128 (__m128 hi, __m128 lo) pure @trusted
{
    // DMD PERF
    static if (GDC_with_AVX)
    {
        __m256 r = __builtin_ia32_ps256_ps(lo);
        return __builtin_ia32_vinsertf128_ps256(r, hi, 1);
    }
    else version(DigitalMars)
    {
        __m256 r = void;
        r.ptr[0] = lo.array[0];
        r.ptr[1] = lo.array[1];
        r.ptr[2] = lo.array[2];
        r.ptr[3] = lo.array[3];
        r.ptr[4] = hi.array[0];
        r.ptr[5] = hi.array[1];
        r.ptr[6] = hi.array[2];
        r.ptr[7] = hi.array[3];
        return r;
    }
    else
    {
        // PERF: this crash on DMD v100.2 on Linux x86_64, find out why since 
        // it would be better performance wise
        __m256 r = void;
        __m128* p = cast(__m128*)(&r);
        p[0] = lo;
        p[1] = hi;
        return r;
    }
}
unittest
{
    __m128 lo = _mm_setr_ps(1.0f, 2, 3, 4);
    __m128 hi = _mm_setr_ps(3.0f, 4, 5, 6);
    __m256 R = _mm256_set_m128(hi, lo);
    float[8] correct = [1.0f, 2, 3, 4, 3, 4, 5, 6];
    assert(R.array == correct);
}

/// Set packed `__m256d` vector with the supplied values.
__m256d _mm256_set_m128d (__m128d hi, __m128d lo) pure @trusted
{
    __m256d r = void;
    r.ptr[0] = lo.array[0];
    r.ptr[1] = lo.array[1];
    r.ptr[2] = hi.array[0];
    r.ptr[3] = hi.array[1];
    return r;
}
unittest
{
    __m128d lo = _mm_setr_pd(1.0, 2.0);
    __m128d hi = _mm_setr_pd(3.0, 4.0);
    __m256d R = _mm256_set_m128d(hi, lo);
    double[4] correct = [1.0, 2.0, 3.0, 4.0];
    assert(R.array == correct);
}

/// Set packed `__m256i` vector with the supplied values.
__m256i _mm256_set_m128i (__m128i hi, __m128i lo) pure @trusted
{
    // DMD PERF
    static if (GDC_with_AVX)
    {
        __m256i r = cast(long4) __builtin_ia32_si256_si (lo);
        return cast(long4) __builtin_ia32_vinsertf128_si256(cast(int8)r, hi, 1);
    }
    else version(DigitalMars)
    {
        int8 r = void;
        r.ptr[0] = lo.array[0];
        r.ptr[1] = lo.array[1];
        r.ptr[2] = lo.array[2];
        r.ptr[3] = lo.array[3];
        r.ptr[4] = hi.array[0];
        r.ptr[5] = hi.array[1];
        r.ptr[6] = hi.array[2];
        r.ptr[7] = hi.array[3];
        return cast(long4)r;
    }
    else
    {
        // PERF Does this also vcrash for DMD? with DMD v100.2 on Linux x86_64
        __m256i r = void;
        __m128i* p = cast(__m128i*)(&r);
        p[0] = lo;
        p[1] = hi;
        return r;
    }
}
unittest
{
    __m128i lo = _mm_setr_epi32( 1,  2,  3,  4);
    __m128i hi =  _mm_set_epi32(-3, -4, -5, -6);
    int8 R = cast(int8)_mm256_set_m128i(hi, lo);
    int[8] correct = [1, 2, 3, 4, -6, -5, -4, -3];
    assert(R.array == correct);
}

/// Set packed double-precision (64-bit) floating-point elements with the supplied values.
__m256d _mm256_set_pd (double e3, double e2, double e1, double e0) pure @trusted
{
    __m256d r = void;
    r.ptr[0] = e0;
    r.ptr[1] = e1;
    r.ptr[2] = e2;
    r.ptr[3] = e3;
    return r;
}
unittest
{
    __m256d A = _mm256_set_pd(3, 2, 1, 546);
    double[4] correct = [546.0, 1.0, 2.0, 3.0];
    assert(A.array == correct);
}

/// Set packed single-precision (32-bit) floating-point elements with the supplied values.
__m256 _mm256_set_ps (float e7, float e6, float e5, float e4, float e3, float e2, float e1, float e0) pure @trusted
{
    // PERF: see #102, use = void?
    __m256 r;
    r.ptr[0] = e0;
    r.ptr[1] = e1;
    r.ptr[2] = e2;
    r.ptr[3] = e3;
    r.ptr[4] = e4;
    r.ptr[5] = e5;
    r.ptr[6] = e6;
    r.ptr[7] = e7;
    return r;
}
unittest
{
    __m256 A = _mm256_set_ps(3, 2, 1, 546.0f, -1.25f, -2, -3, 0);
    float[8] correct = [0, -3, -2, -1.25f, 546.0f, 1.0, 2.0, 3.0];
    assert(A.array == correct);
}

/// Broadcast 16-bit integer `a` to all elements of the return value.
__m256i _mm256_set1_epi16 (short a) pure @trusted
{
    // workaround https://issues.dlang.org/show_bug.cgi?id=21469
    // It used to ICE, now the codegen is just wrong.
    // TODO report this backend issue.
    version(DigitalMars) 
    {
        short16 v = a;
        return cast(__m256i) v;
    }
    else
    {
        pragma(inline, true);
        return cast(__m256i)(short16(a));
    }
}
unittest
{
    short16 a = cast(short16) _mm256_set1_epi16(31);
    for (int i = 0; i < 16; ++i)
        assert(a.array[i] == 31);
}

/// Broadcast 32-bit integer `a` to all elements.
__m256i _mm256_set1_epi32 (int a) pure @trusted
{
    // Bad codegen else in DMD.
    // TODO report this backend issue.
    version(DigitalMars) 
    {
        int8 v = a;
        return cast(__m256i) v;
    }
    else
    {
        pragma(inline, true);
        return cast(__m256i)(int8(a));
    }
}
unittest
{
    int8 a = cast(int8) _mm256_set1_epi32(31);
    for (int i = 0; i < 8; ++i)
        assert(a.array[i] == 31);
}

/// Broadcast 64-bit integer `a` to all elements of the return value.
__m256i _mm256_set1_epi64x (long a)
{
    return cast(__m256i)(long4(a));
}
unittest
{
    long4 a = cast(long4) _mm256_set1_epi64x(-31);
    for (int i = 0; i < 4; ++i)
        assert(a.array[i] == -31);
}

/// Broadcast 8-bit integer `a` to all elements of the return value.
__m256i _mm256_set1_epi8 (byte a) pure @trusted
{
    version(DigitalMars) // workaround https://issues.dlang.org/show_bug.cgi?id=21469
    {
        byte32 v = a;
        return cast(__m256i) v;
    }
    else
    {
        pragma(inline, true);
        return cast(__m256i)(byte32(a));
    }
}
unittest
{
    byte32 a = cast(byte32) _mm256_set1_epi8(31);
    for (int i = 0; i < 32; ++i)
        assert(a.array[i] == 31);
}

/// Broadcast double-precision (64-bit) floating-point value `a` to all elements of the return value.
__m256d _mm256_set1_pd (double a) pure @trusted
{
    return __m256d(a);
}
unittest
{
    double a = 464.21;
    double[4] correct = [a, a, a, a];
    double4 A = cast(double4) _mm256_set1_pd(a);
    assert(A.array == correct);
}

/// Broadcast single-precision (32-bit) floating-point value `a` to all elements of the return value.
__m256 _mm256_set1_ps (float a) pure @trusted
{
    return __m256(a);
}
unittest
{
    float a = 464.21f;
    float[8] correct = [a, a, a, a, a, a, a, a];
    float8 A = cast(float8) _mm256_set1_ps(a);
    assert(A.array == correct);
}

/// Set packed 16-bit integers with the supplied values in reverse order.
__m256i _mm256_setr_epi16 (short e15, short e14, short e13, short e12, short e11, short e10, short e9,  short e8,
                           short e7,  short e6,  short e5,  short e4,  short e3,  short e2,  short e1,  short e0) pure @trusted
{
    short[16] result = [ e15,  e14,  e13,  e12,  e11,  e10,  e9,   e8,
                         e7,   e6,   e5,   e4,   e3,   e2,   e1,   e0];
    static if (GDC_with_AVX)
    {
         return cast(__m256i) __builtin_ia32_loaddqu256(cast(const(char)*) result.ptr);
    }
    else version(LDC)
    {
        return cast(__m256i)( loadUnaligned!(short16)(result.ptr) );
    }
    else
    {
        short16 r;
        for(int n = 0; n < 16; ++n)
            r.ptr[n] = result[n];
        return cast(__m256i)r;
    }
}
unittest
{
    short16 A = cast(short16) _mm256_setr_epi16(-1, 0, -21, 21, 42, 127, -42, -128,
                                                -1, 0, -21, 21, 42, 127, -42, -128);
    short[16] correct = [-1, 0, -21, 21, 42, 127, -42, -128,
                         -1, 0, -21, 21, 42, 127, -42, -128];
    assert(A.array == correct);
}

/// Set packed 32-bit integers with the supplied values in reverse order.
__m256i _mm256_setr_epi32 (int e7, int e6, int e5, int e4, int e3, int e2, int e1, int e0) pure @trusted
{
    int[8] result = [e7, e6, e5, e4, e3, e2, e1, e0];
    static if (GDC_with_AVX)
    {
        return cast(__m256i) __builtin_ia32_loaddqu256(cast(const(char)*) result.ptr);
    }
    else version(LDC)
    {
        return cast(__m256i)( loadUnaligned!(int8)(result.ptr) );
    }
    else
    {
        int8 r;
        for(int n = 0; n < 8; ++n)
            r.ptr[n] = result[n];
        return cast(__m256i)r;
    }
}
unittest
{
    int8 A = cast(int8) _mm256_setr_epi32(-1, 0, -2147483648, 2147483647, 42, 666, -42, -666);
    int[8] correct = [-1, 0, -2147483648, 2147483647, 42, 666, -42, -666];
    assert(A.array == correct);
}

/// Set packed 64-bit integers with the supplied values in reverse order.
__m256i _mm256_setr_epi64x (long e3, long e2, long e1, long e0) pure @trusted
{
    long4 r = void;
    r.ptr[0] = e3;
    r.ptr[1] = e2;
    r.ptr[2] = e1;
    r.ptr[3] = e0;
    return r;
}
unittest
{
    __m256i A = _mm256_setr_epi64x(-1, 42, long.min, long.max);
    long[4] correct = [-1, 42, long.min, long.max];
    assert(A.array == correct);
}

/// Set packed 8-bit integers with the supplied values in reverse order.
__m256i _mm256_setr_epi8 (byte e31, byte e30, byte e29, byte e28, byte e27, byte e26, byte e25, byte e24,
                          byte e23, byte e22, byte e21, byte e20, byte e19, byte e18, byte e17, byte e16,
                          byte e15, byte e14, byte e13, byte e12, byte e11, byte e10, byte e9,  byte e8,
                          byte e7,  byte e6,  byte e5,  byte e4,  byte e3,  byte e2,  byte e1,  byte e0) pure @trusted
{
    // PERF GDC, not checked
    byte[32] result = [ e31,  e30,  e29,  e28,  e27,  e26,  e25,  e24,
                        e23,  e22,  e21,  e20,  e19,  e18,  e17,  e16,
                        e15,  e14,  e13,  e12,  e11,  e10,  e9,   e8,
                        e7,   e6,   e5,   e4,   e3,   e2,   e1,   e0];
    static if (GDC_with_AVX)
    {
        return cast(__m256i) __builtin_ia32_loaddqu256(cast(const(char)*) result.ptr);
    }
    else version(LDC)
    {
        return cast(__m256i)( loadUnaligned!(byte32)(result.ptr) );
    }
    else
    {
        byte32 r;
        for(int n = 0; n < 32; ++n)
            r.ptr[n] = result[n];
        return cast(__m256i)r;
    }
}
unittest
{
    byte32 A = cast(byte32) _mm256_setr_epi8( -1, 0, -21, 21, 42, 127, -42, -128,
                                              -1, 0, -21, 21, 42, 127, -42, -128,
                                              -1, 0, -21, 21, 42, 127, -42, -128,
                                              -1, 0, -21, 21, 42, 127, -42, -128);
    byte[32] correct = [-1, 0, -21, 21, 42, 127, -42, -128,
                        -1, 0, -21, 21, 42, 127, -42, -128,
                        -1, 0, -21, 21, 42, 127, -42, -128,
                        -1, 0, -21, 21, 42, 127, -42, -128];
    assert(A.array == correct);
}

// TODO __m256 _mm256_setr_m128 (__m128 lo, __m128 hi)
// TODO __m256d _mm256_setr_m128d (__m128d lo, __m128d hi)
// TODO __m256i _mm256_setr_m128i (__m128i lo, __m128i hi)

/// Set packed double-precision (64-bit) floating-point elements with the supplied values in reverse order.
__m256d _mm256_setr_pd (double e3, double e2, double e1, double e0) pure @trusted
{
    version(LDC)
    {
        // PERF, probably not the best
        double[4] result = [e3, e2, e1, e0];
        return loadUnaligned!(double4)(result.ptr);
    }
    else
    {
        __m256d r;
        r.ptr[0] = e3;
        r.ptr[1] = e2;
        r.ptr[2] = e1;
        r.ptr[3] = e0;
        return r;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(3, 2, 1, 546.125);
    double[4] correct = [3.0, 2.0, 1.0, 546.125];
    assert(A.array == correct);
}


/// Set packed single-precision (32-bit) floating-point elements with the supplied values in reverse order.
__m256 _mm256_setr_ps (float e7, float e6, float e5, float e4, float e3, float e2, float e1, float e0) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        align(32) float[8] r = [ e7,   e6,   e5,   e4,   e3,   e2,   e1,   e0];
        return *cast(__m256*)r;
    }
    else version(LDC)
    {
        align(32) float[8] r = [ e7,   e6,   e5,   e4,   e3,   e2,   e1,   e0];
        return *cast(__m256*)r;
    }
    else
    {
        __m256 r;
        r.ptr[0] = e7;
        r.ptr[1] = e6;
        r.ptr[2] = e5;
        r.ptr[3] = e4;
        r.ptr[4] = e3;
        r.ptr[5] = e2;
        r.ptr[6] = e1;
        r.ptr[7] = e0;
        return r;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(   3, 2, 1, 546.125f, 4, 5, 6, 7);
    float[8] correct       = [3.0f, 2, 1, 546.125f, 4, 5, 6, 7];
    assert(A.array == correct);
}

/// Return vector of type `__m256d` with all elements set to zero.
__m256d _mm256_setzero_pd() pure @safe
{
    return double4(0.0);
}
unittest
{
    __m256d A = _mm256_setzero_pd();
    double[4] correct = [0.0, 0.0, 0.0, 0.0];
    assert(A.array == correct);
}

/// Return vector of type `__m256` with all elements set to zero.
__m256 _mm256_setzero_ps() pure @safe
{
    return float8(0.0f);
}
unittest
{
    __m256 A = _mm256_setzero_ps();
    float[8] correct = [0.0f, 0, 0, 0, 0, 0, 0, 0];
    assert(A.array == correct);
}

/// Return vector of type `__m256i` with all elements set to zero.
__m256i _mm256_setzero_si256() pure @trusted
{
    return __m256i(0);
}
unittest
{
    __m256i A = _mm256_setzero_si256();
    long[4] correct = [0, 0, 0, 0];
    assert(A.array == correct);
}

/// Shuffle double-precision (64-bit) floating-point elements within 128-bit lanes using the 
/// control in `imm8`.
__m256d _mm256_shuffle_pd(int imm8)(__m256d a, __m256d b) pure @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_shufpd256(a, b, imm8);
    }
    else version(LDC)
    {
        return shufflevectorLDC!(double4,        
                                       (imm8 >> 0) & 1,
                                 4 + ( (imm8 >> 1) & 1),
                                 2 + ( (imm8 >> 2) & 1),
                                 6 + ( (imm8 >> 3) & 1) )(a, b);
    }
    else
    {
        double4 r = void;
        r.ptr[0] = a.array[(imm8 >> 0) & 1];
        r.ptr[1] = b.array[(imm8 >> 1) & 1];
        r.ptr[2] = a.array[2 + ( (imm8 >> 2) & 1)];
        r.ptr[3] = b.array[2 + ( (imm8 >> 3) & 1)];
        return r;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd( 0, 1, 2, 3);
    __m256d B = _mm256_setr_pd( 4, 5, 6, 7);
    __m256d C = _mm256_shuffle_pd!75 /* 01001011 */(A, B);
    double[4] correct = [1.0, 5.0, 2.0, 7.0];
    assert(C.array == correct);
} 

/// Shuffle single-precision (32-bit) floating-point elements in `a` within 128-bit lanes using 
/// the control in `imm8`.
__m256 _mm256_shuffle_ps(int imm8)(__m256 a, __m256 b) pure @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_shufps256(a, b, imm8);
    }
    else version(LDC)
    {
        return shufflevectorLDC!(float8, (imm8 >> 0) & 3,
                                 (imm8 >> 2) & 3,
                                 8 + ( (imm8 >> 4) & 3),
                                 8 + ( (imm8 >> 6) & 3),
                                 4 + ( (imm8 >> 0) & 3),
                                 4 + ( (imm8 >> 2) & 3),
                                 12 + ( (imm8 >> 4) & 3),
                                 12 + ( (imm8 >> 6) & 3) )(a, b);
    }
    else
    {
        float8 r = void;
        r.ptr[0] = a.array[(imm8 >> 0) & 3];
        r.ptr[1] = a.array[(imm8 >> 2) & 3];
        r.ptr[2] = b.array[(imm8 >> 4) & 3];
        r.ptr[3] = b.array[(imm8 >> 6) & 3];
        r.ptr[4] = a.array[4 + ( (imm8 >> 0) & 3 )];
        r.ptr[5] = a.array[4 + ( (imm8 >> 2) & 3 )];
        r.ptr[6] = b.array[4 + ( (imm8 >> 4) & 3 )];
        r.ptr[7] = b.array[4 + ( (imm8 >> 6) & 3 )];
        return r;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps( 0,  1,  2,  3,  4,  5,  6,  7);
    __m256 B = _mm256_setr_ps( 8,  9, 10, 11, 12, 13, 14, 15);
    __m256 C = _mm256_shuffle_ps!75 /* 01001011 */(A, B);
    float[8] correct = [3.0f, 2, 8, 9, 7, 6, 12, 13];
    assert(C.array == correct);
} 

/// Compute the square root of packed double-precision (64-bit) floating-point elements in `a`.
__m256d _mm256_sqrt_pd (__m256d a) pure @trusted
{
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_sqrtpd256(a);
    } 
    else version(LDC)
    {    
        return llvm_sqrt(a);
    }    
    else
    {
        a.ptr[0] = sqrt(a.array[0]);
        a.ptr[1] = sqrt(a.array[1]);
        a.ptr[2] = sqrt(a.array[2]);
        a.ptr[3] = sqrt(a.array[3]);
        return a;
    }
}
unittest
{
    __m256d A = _mm256_sqrt_pd(_mm256_set1_pd(4.0));
    double[4] correct = [2.0, 2, 2, 2];
    assert(A.array == correct);
}

/// Compute the square root of packed single-precision (32-bit) floating-point elements in `a`.
__m256 _mm256_sqrt_ps (__m256 a) pure @trusted
{
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_sqrtps256(a);
    } 
    else version(LDC)
    {    
        return llvm_sqrt(a);
    }    
    else
    {
        a.ptr[0] = sqrt(a.array[0]);
        a.ptr[1] = sqrt(a.array[1]);
        a.ptr[2] = sqrt(a.array[2]);
        a.ptr[3] = sqrt(a.array[3]);
        a.ptr[4] = sqrt(a.array[4]);
        a.ptr[5] = sqrt(a.array[5]);
        a.ptr[6] = sqrt(a.array[6]);
        a.ptr[7] = sqrt(a.array[7]);
        return a;
    }
}
unittest
{
    __m256 A = _mm256_sqrt_ps(_mm256_set1_ps(4.0f));
    float[8] correct = [2.0f, 2, 2, 2, 2, 2, 2, 2];
    assert(A.array == correct);
}

/// Store 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) from 
/// `a` into memory. `mem_addr` must be aligned on a 32-byte boundary or a general-protection 
/// exception may be generated.
void _mm256_store_pd (double* mem_addr, __m256d a) pure @system
{
    *cast(__m256d*)mem_addr = a;
}
unittest
{
    align(32) double[4] mem;
    double[4] correct = [1.0, 2, 3, 4];
    _mm256_store_pd(mem.ptr, _mm256_setr_pd(1.0, 2, 3, 4));
    assert(mem == correct);
}

/// Store 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from 
/// `a` into memory. `mem_addr` must be aligned on a 32-byte boundary or a general-protection 
/// exception may be generated.
void _mm256_store_ps (float* mem_addr, __m256 a) pure @system
{
    *cast(__m256*)mem_addr = a;
}
unittest
{
    align(32) float[8] mem;
    float[8] correct = [1.0, 2, 3, 4, 5, 6, 7, 8];
    _mm256_store_ps(mem.ptr, _mm256_set_ps(8.0, 7, 6, 5, 4, 3, 2, 1));
    assert(mem == correct);
}

// TODO void _mm256_store_si256 (__m256i * mem_addr, __m256i a)
// TODO void _mm256_storeu_pd (double * mem_addr, __m256d a)
// TODO void _mm256_storeu_ps (float * mem_addr, __m256 a)

/// Store 256-bits of integer data from `a` into memory. `mem_addr` does not need to be aligned on any particular boundary.
void _mm256_storeu_si256 (const(__m256i)* mem_addr, __m256i a) pure @trusted
{
    // PERF: DMD and GDC
    version(LDC)
    {
        storeUnaligned!__m256i(a, cast(long*)mem_addr);
    }
    else
    {
        long4 v = cast(long4)a;
        long* p = cast(long*)mem_addr;
        for(int n = 0; n < 4; ++n)
            p[n] = v[n];
    }
}

// TODO void _mm256_storeu2_m128 (float* hiaddr, float* loaddr, __m256 a)
// TODO void _mm256_storeu2_m128d (double* hiaddr, double* loaddr, __m256d a)
// TODO void _mm256_storeu2_m128i (__m128i* hiaddr, __m128i* loaddr, __m256i a)
// TODO void _mm256_stream_pd (double * mem_addr, __m256d a)
// TODO void _mm256_stream_ps (float * mem_addr, __m256 a)
// TODO void _mm256_stream_si256 (__m256i * mem_addr, __m256i a)

/// Subtract packed double-precision (64-bit) floating-point elements in `b` from 
/// packed double-precision (64-bit) floating-point elements in `a`.
__m256d _mm256_sub_pd (__m256d a, __m256d b) pure @safe
{
    return a - b;
}
unittest
{
    __m256d a = [1.5, -2.0, 3.0, 200000.0];
    a = _mm256_sub_pd(a, a);
    double[4] correct = [0.0, 0, 0, 0];
    assert(a.array == correct);
}

/// Subtract packed single-precision (32-bit) floating-point elements in `b` from 
/// packed single-precision (32-bit) floating-point elements in `a`.
__m256 _mm256_sub_ps (__m256 a, __m256 b) pure @safe
{
    return a - b;
}
unittest
{
    __m256 a = [1.5f, -2.0f, 3.0f, 1.0f, 1.5f, -2000.0f, 3.0f, 1.0f];
    a = _mm256_sub_ps(a, a);
    float[8] correct = [0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f];
    assert(a.array == correct);
}


// TODO int _mm_testc_pd (__m128d a, __m128d b)
// TODO int _mm256_testc_pd (__m256d a, __m256d b)
// TODO int _mm_testc_ps (__m128 a, __m128 b)
// TODO int _mm256_testc_ps (__m256 a, __m256 b)
// TODO int _mm256_testc_si256 (__m256i a, __m256i b)
// TODO int _mm_testnzc_pd (__m128d a, __m128d b)
// TODO int _mm256_testnzc_pd (__m256d a, __m256d b)
// TODO int _mm_testnzc_ps (__m128 a, __m128 b)
// TODO int _mm256_testnzc_ps (__m256 a, __m256 b)
// TODO int _mm256_testnzc_si256 (__m256i a, __m256i b)
// TODO int _mm_testz_pd (__m128d a, __m128d b)
// TODO int _mm256_testz_pd (__m256d a, __m256d b)
// TODO int _mm_testz_ps (__m128 a, __m128 b)
// TODO int _mm256_testz_ps (__m256 a, __m256 b)
// TODO int _mm256_testz_si256 (__m256i a, __m256i b)

/// Return vector of type __m256d with undefined elements.
__m256d _mm256_undefined_pd () pure @safe
{
    __m256d r = void;
    return r;
}

/// Return vector of type __m256 with undefined elements.
__m256 _mm256_undefined_ps () pure @safe
{
    __m256 r = void;
    return r;
}

/// Return vector of type __m256i with undefined elements.
__m256i _mm256_undefined_si256 () pure @safe
{
    __m256i r = void;
    return r;
}

// TODO __m256d _mm256_unpackhi_pd (__m256d a, __m256d b)
// TODO __m256 _mm256_unpackhi_ps (__m256 a, __m256 b)
// TODO __m256d _mm256_unpacklo_pd (__m256d a, __m256d b)
// TODO __m256 _mm256_unpacklo_ps (__m256 a, __m256 b)

/// Compute the bitwise XOR of packed double-precision (64-bit) floating-point elements in `a` and `b`.
__m256d _mm256_xor_pd (__m256d a, __m256d b) pure @safe
{
    return cast(__m256d)( cast(__m256i)a ^ cast(__m256i)b );
}

/// Compute the bitwise XOR of packed single-precision (32-bit) floating-point elements in `a` and `b`.
__m256 _mm256_xor_ps (__m256 a, __m256 b) pure @safe
{
    return cast(__m256)( cast(__m256i)a ^ cast(__m256i)b );
}

void _mm256_zeroall () pure @safe
{
    // TODO: DMD needs to do it explicitely if AVX is used.

    static if (GDC_with_AVX)
    {
        __builtin_ia32_vzeroall();
    }
    else
    {
        // Do nothing. The transitions penalty are supposed handled by the backend.
    }
}

void _mm256_zeroupper () pure @safe
{
    // TODO: DMD needs to do it explicitely if AVX is used.

    static if (GDC_with_AVX)
    {
        __builtin_ia32_vzeroupper();
    }
    else
    {
        // Do nothing. The transitions penalty are supposed handled by the backend.
    }
    
}

// TODO __m256d _mm256_zextpd128_pd256 (__m128d a)
// TODO __m256 _mm256_zextps128_ps256 (__m128 a)
// TODO __m256i _mm256_zextsi128_si256 (__m128i a)


/+



pragma(LDC_intrinsic, "llvm.x86.avx.cvt.pd2.ps.256")
    float4 __builtin_ia32_cvtpd2ps256(double4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.cvt.pd2dq.256")
    int4 __builtin_ia32_cvtpd2dq256(double4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.cvt.ps2dq.256")
    int8 __builtin_ia32_cvtps2dq256(float8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.cvtt.pd2dq.256")
    int4 __builtin_ia32_cvttpd2dq256(double4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.cvtt.ps2dq.256")
    int8 __builtin_ia32_cvttps2dq256(float8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.dp.ps.256")
    float8 __builtin_ia32_dpps256(float8, float8, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.hadd.pd.256")
    double4 __builtin_ia32_haddpd256(double4, double4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.hadd.ps.256")
    float8 __builtin_ia32_haddps256(float8, float8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.hsub.pd.256")
    double4 __builtin_ia32_hsubpd256(double4, double4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.hsub.ps.256")
    float8 __builtin_ia32_hsubps256(float8, float8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.ldu.dq.256")
    byte32 __builtin_ia32_lddqu256(const void*);

pragma(LDC_intrinsic, "llvm.x86.avx.maskload.pd")
    double2 __builtin_ia32_maskloadpd(const void*, long2);

pragma(LDC_intrinsic, "llvm.x86.avx.maskload.pd.256")
    double4 __builtin_ia32_maskloadpd256(const void*, long4);

pragma(LDC_intrinsic, "llvm.x86.avx.maskload.ps")
    float4 __builtin_ia32_maskloadps(const void*, int4);

pragma(LDC_intrinsic, "llvm.x86.avx.maskload.ps.256")
    float8 __builtin_ia32_maskloadps256(const void*, int8);

pragma(LDC_intrinsic, "llvm.x86.avx.maskstore.pd")
    void __builtin_ia32_maskstorepd(void*, long2, double2);

pragma(LDC_intrinsic, "llvm.x86.avx.maskstore.pd.256")
    void __builtin_ia32_maskstorepd256(void*, long4, double4);

pragma(LDC_intrinsic, "llvm.x86.avx.maskstore.ps")
    void __builtin_ia32_maskstoreps(void*, int4, float4);

pragma(LDC_intrinsic, "llvm.x86.avx.maskstore.ps.256")
    void __builtin_ia32_maskstoreps256(void*, int8, float8);

pragma(LDC_intrinsic, "llvm.x86.avx.max.pd.256")
    double4 __builtin_ia32_maxpd256(double4, double4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.max.ps.256")
    float8 __builtin_ia32_maxps256(float8, float8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.min.pd.256")
    double4 __builtin_ia32_minpd256(double4, double4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.min.ps.256")
    float8 __builtin_ia32_minps256(float8, float8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.movmsk.pd.256")
    int __builtin_ia32_movmskpd256(double4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.movmsk.ps.256")
    int __builtin_ia32_movmskps256(float8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.ptestc.256")
    int __builtin_ia32_ptestc256(long4, long4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.ptestnzc.256")
    int __builtin_ia32_ptestnzc256(long4, long4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.ptestz.256")
    int __builtin_ia32_ptestz256(long4, long4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.rcp.ps.256")
    float8 __builtin_ia32_rcpps256(float8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.round.pd.256")
    double4 __builtin_ia32_roundpd256(double4, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.round.ps.256")
    float8 __builtin_ia32_roundps256(float8, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.rsqrt.ps.256")
    float8 __builtin_ia32_rsqrtps256(float8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vpermilvar.pd")
    double2 __builtin_ia32_vpermilvarpd(double2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vpermilvar.pd.256")
    double4 __builtin_ia32_vpermilvarpd256(double4, long4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vpermilvar.ps")
    float4 __builtin_ia32_vpermilvarps(float4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vpermilvar.ps.256")
    float8 __builtin_ia32_vpermilvarps256(float8, int8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestc.pd")
    int __builtin_ia32_vtestcpd(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestc.pd.256")
    int __builtin_ia32_vtestcpd256(double4, double4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestc.ps")
    int __builtin_ia32_vtestcps(float4, float4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestc.ps.256")
    int __builtin_ia32_vtestcps256(float8, float8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestnzc.pd")
    int __builtin_ia32_vtestnzcpd(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestnzc.pd.256")
    int __builtin_ia32_vtestnzcpd256(double4, double4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestnzc.ps")
    int __builtin_ia32_vtestnzcps(float4, float4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestnzc.ps.256")
    int __builtin_ia32_vtestnzcps256(float8, float8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestz.pd")
    int __builtin_ia32_vtestzpd(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestz.pd.256")
    int __builtin_ia32_vtestzpd256(double4, double4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestz.ps")
    int __builtin_ia32_vtestzps(float4, float4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.avx.vtestz.ps.256")
    int __builtin_ia32_vtestzps256(float8, float8) pure @safe;

+/