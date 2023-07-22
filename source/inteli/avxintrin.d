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


/// IMPORTANT NOTE ABOUT MASK LOAD/STORE:
///
/// In theory, masked load/store can adress unadressable memory provided the mask is zero.
/// In practice, that is not the case for the following reasons:
/// 
/// - AMD manual says:
///   "Exception and trap behavior for elements not selected for loading or storing from/to memory
///   is implementation dependent. For instance, a given implementation may signal a data 
///   breakpoint or a page fault for doublewords that are zero-masked and not actually written."
///
/// - Intel fetches the whole cacheline anyway:
///   https://erik.science/2019/06/21/AVX-fun.html
///   "Even if the mask is stored in the special mask registers, it will still first fetch the data
///    before checking the mask."
///
/// So intel-intrinsics adopted the tightened semantics of only adressing fully addressable memory 
/// with masked loads and stores.


/// Some AVX intrinsics takes a float comparison constant.
/// When labelled "ordered" it means "AND ordered"
/// When labelled "unordered" it means "OR unordered"
alias _CMP_EQ = int;
///ditto
enum : _CMP_EQ
{
    _CMP_EQ_OQ    = 0x00, // Equal (ordered, non-signaling)
    _CMP_LT_OS    = 0x01, // Less-than (ordered, signaling)
    _CMP_LE_OS    = 0x02, // Less-than-or-equal (ordered, signaling)
    _CMP_UNORD_Q  = 0x03, // Unordered (non-signaling)
    _CMP_NEQ_UQ   = 0x04, // Not-equal (unordered, non-signaling)
    _CMP_NLT_US   = 0x05, // Not-less-than (unordered, signaling)
    _CMP_NLE_US   = 0x06, // Not-less-than-or-equal (unordered, signaling)
    _CMP_ORD_Q    = 0x07, // Ordered (nonsignaling)
    _CMP_EQ_UQ    = 0x08, // Equal (unordered, non-signaling)
    _CMP_NGE_US   = 0x09, // Not-greater-than-or-equal (unordered, signaling)
    _CMP_NGT_US   = 0x0a, // Not-greater-than (unordered, signaling)
    _CMP_FALSE_OQ = 0x0b, // False (ordered, non-signaling)
    _CMP_NEQ_OQ   = 0x0c, // Not-equal (ordered, non-signaling)
    _CMP_GE_OS    = 0x0d, // Greater-than-or-equal (ordered, signaling)
    _CMP_GT_OS    = 0x0e, // Greater-than (ordered, signaling)
    _CMP_TRUE_UQ  = 0x0f, // True (unordered, non-signaling)
    _CMP_EQ_OS    = 0x10, // Equal (ordered, signaling)
    _CMP_LT_OQ    = 0x11, // Less-than (ordered, non-signaling)
    _CMP_LE_OQ    = 0x12, // Less-than-or-equal (ordered, non-signaling)
    _CMP_UNORD_S  = 0x13, // Unordered (signaling)
    _CMP_NEQ_US   = 0x14, // Not-equal (unordered, signaling)
    _CMP_NLT_UQ   = 0x15, // Not-less-than (unordered, non-signaling)
    _CMP_NLE_UQ   = 0x16, // Not-less-than-or-equal (unordered, non-signaling)
    _CMP_ORD_S    = 0x17, // Ordered (signaling)
    _CMP_EQ_US    = 0x18, // Equal (unordered, signaling)
    _CMP_NGE_UQ   = 0x19, // Not-greater-than-or-equal (unordered, non-signaling)
    _CMP_NGT_UQ   = 0x1a, // Not-greater-than (unordered, non-signaling)
    _CMP_FALSE_OS = 0x1b, // False (ordered, signaling)
    _CMP_NEQ_OS   = 0x1c, // Not-equal (ordered, signaling)
    _CMP_GE_OQ    = 0x1d, // Greater-than-or-equal (ordered, non-signaling)
    _CMP_GT_OQ    = 0x1e, // Greater-than (ordered, non-signaling)
    _CMP_TRUE_US  = 0x1f  // (unordered, signaling)
}

public import inteli.types;
import inteli.internals;

// Pull in all previous instruction set intrinsics.
public import inteli.smmintrin;
public import inteli.tmmintrin;



// In x86, LDC earlier version may have trouble preserving the stack pointer when an unsupported
// 256-bit vector type is passed, and AVX is disabled.
// This leads to disabling some intrinsics in this particular situation, since they are not safe for
// the caller.
version(LDC)
{
    version(X86)
    {
        enum llvm256BitStackWorkaroundIn32BitX86 = __VERSION__ < 2099;
    }
    else 
        enum llvm256BitStackWorkaroundIn32BitX86 = false;
}
else
    enum llvm256BitStackWorkaroundIn32BitX86 = false;




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
    static if (GDC_or_LDC_with_AVX)
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
    static if (GDC_or_LDC_with_AVX)
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
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_blendps256 (a, b, imm8);
    }
    else version(LDC)
    {
        // LDC x86: generates a vblendps since LDC 1.1 -O0
        //   arm64: pretty good, four instructions worst case
        return shufflevectorLDC!(float8, (imm8 & 1) ? 8 : 0,
                                 (imm8 & 2) ? 9 : 1,
                                 (imm8 & 4) ? 10 : 2,
                                 (imm8 & 8) ? 11 : 3,
                                 (imm8 & 16) ? 12 : 4,
                                 (imm8 & 32) ? 13 : 5,
                                 (imm8 & 64) ? 14 : 6,
                                 (imm8 & 128) ? 15 : 7)(a, b);
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
        // Sounds like a bug, similar to _mm_blendv_pd
        // or maybe the instruction in unsafe?
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
    assert(R.array == correct1);
}

/// Blend packed single-precision (32-bit) floating-point elements from `a` and `b` 
/// using `mask`.
__m256 _mm256_blendv_ps (__m256 a, __m256 b, __m256 mask) @trusted
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
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
        // In both LDC and GDC with SSE4.1, this generates blendvps as fallback
        __m256 r;
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
    assert(R.array == correct1);
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
    // PERF DMD
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
    // PERF DMD
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

/// Round the packed double-precision (64-bit) floating-point elements in `a` up to an integer 
/// value, and store the results as packed double-precision floating-point elements.
__m256d _mm256_ceil_pd (__m256d a) @safe
{
    static if (LDC_with_ARM64)
    {
         __m128d lo = _mm256_extractf128_pd!0(a);
        __m128d hi = _mm256_extractf128_pd!1(a);
        __m128d ilo = _mm_ceil_pd(lo);
        __m128d ihi = _mm_ceil_pd(hi);
        return _mm256_set_m128d(ihi, ilo);
    }
    else
    {
        return _mm256_round_pd!2(a);
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(1.3f, -2.12f, 53.6f, -2.7f);
    A = _mm256_ceil_pd(A);
    double[4] correct = [2.0, -2.0, 54.0, -2.0];
    assert(A.array == correct);
}

/// Round the packed single-precision (32-bit) floating-point elements in `a` up to an integer 
/// value, and store the results as packed single-precision floating-point elements.
__m256 _mm256_ceil_ps (__m256 a) @safe
{
    static if (LDC_with_ARM64)
    {
        __m128 lo = _mm256_extractf128_ps!0(a);
        __m128 hi = _mm256_extractf128_ps!1(a);
        __m128 ilo = _mm_ceil_ps(lo);
        __m128 ihi = _mm_ceil_ps(hi);
        return _mm256_set_m128(ihi, ilo);
    }
    else
    {
        return _mm256_round_ps!2(a);
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(1.3f, -2.12f, 53.6f, -2.7f, -1.3f, 2.12f, -53.6f, 2.7f);
    __m256 C = _mm256_ceil_ps(A);
    float[8] correct       = [2.0f, -2.0f,  54.0f, -2.0f, -1,    3,     -53,    3];
    assert(C.array == correct);
}

/// Compare packed double-precision (64-bit) floating-point elements in `a` and `b` based on the 
/// comparison operand specified by `imm8`. 
__m128d _mm_cmp_pd(int imm8)(__m128d a, __m128d b) pure @safe
{
    enum comparison = mapAVXFPComparison(imm8);
    return cast(__m128d) cmppd!comparison(a, b);
}
unittest
{
    __m128d A = _mm_setr_pd(double.infinity, double.nan);
    __m128d B = _mm_setr_pd(3.0,             4.0);
    long2 R = cast(long2) _mm_cmp_pd!_CMP_GT_OS(A, B);
    long[2] correct = [-1, 0];
    assert(R.array == correct);

    long2 R2 = cast(long2) _mm_cmp_pd!_CMP_NLE_UQ(A, B);
    long[2] correct2 = [-1, -1];
    assert(R2.array == correct2);
}

///ditto
__m256d _mm256_cmp_pd(int imm8)(__m256d a, __m256d b) pure @safe
{
    enum comparison = mapAVXFPComparison(imm8);
    return cast(__m256d) cmppd256!comparison(a, b);
}
unittest
{
    __m256d A = _mm256_setr_pd(1.0, 2.0, 3.0, double.nan);
    __m256d B = _mm256_setr_pd(3.0, 2.0, 1.0, double.nan);
    __m256i R = cast(__m256i) _mm256_cmp_pd!_CMP_LT_OS(A, B);
    long[4] correct = [-1, 0, 0, 0];
    assert(R.array == correct);
}

/// Compare packed double-precision (32-bit) floating-point elements in `a` and `b` based on the 
/// comparison operand specified by `imm8`. 
__m128 _mm_cmp_ps(int imm8)(__m128 a, __m128 b) pure @safe
{
    enum comparison = mapAVXFPComparison(imm8);
    return cast(__m128) cmpps!comparison(a, b);
}

///ditto
__m256 _mm256_cmp_ps(int imm8)(__m256 a, __m256 b) pure @safe
{
    enum comparison = mapAVXFPComparison(imm8);
    return cast(__m256) cmpps256!comparison(a, b);
}

/// Compare the lower double-precision (64-bit) floating-point element in `a` and `b` based on the
/// comparison operand specified by `imm8`, store the result in the lower element of result, and 
/// copy the upper element from `a` to the upper element of result.
__m128d _mm_cmp_sd(int imm8)(__m128d a, __m128d b) pure @safe
{
    enum comparison = mapAVXFPComparison(imm8);
    return cast(__m128d) cmpsd!comparison(a, b);
}

/// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` based on the
/// comparison operand specified by `imm8`, store the result in the lower element of result, and 
/// copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmp_ss(int imm8)(__m128 a, __m128 b) pure @safe
{
    enum comparison = mapAVXFPComparison(imm8);
    return cast(__m128) cmpss!comparison(a, b);
}

/// Convert packed signed 32-bit integers in a to packed double-precision (64-bit) floating-point 
/// elements.
__m256d _mm256_cvtepi32_pd (__m128i a) pure @trusted
{
    static if (LDC_with_optimizations)
    {
        enum ir = `
            %r = sitofp <4 x i32> %0 to <4 x double>
            ret <4 x double> %r`;
        return LDCInlineIR!(ir, double4, __m128i)(a);
    }
    else static if (GDC_with_AVX)
    {
        return __builtin_ia32_cvtdq2pd256(a);
    }
    else
    {
        double4 r;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        r.ptr[2] = a.array[2];
        r.ptr[3] = a.array[3];
        return r;
    }
}
unittest
{
    __m256d R = _mm256_cvtepi32_pd(_mm_set1_epi32(54));
    double[4] correct = [54.0, 54, 54, 54];
    assert(R.array == correct);
}

/// Convert packed signed 32-bit integers in `a` to packed single-precision (32-bit) floating-point 
/// elements.
__m256 _mm256_cvtepi32_ps (__m256i a) pure @trusted
{
    static if (LDC_with_optimizations)
    {
        enum ir = `
            %r = sitofp <8 x i32> %0 to <8 x float>
            ret <8 x float> %r`;
        return LDCInlineIR!(ir, float8, int8)(cast(int8)a);
    }
    else static if (GDC_with_AVX)
    {
        return __builtin_ia32_cvtdq2ps256(cast(int8)a);
    }
    else
    {
        int8 ia = cast(int8)a;
        __m256 r;
        r.ptr[0] = ia.array[0];
        r.ptr[1] = ia.array[1];
        r.ptr[2] = ia.array[2];
        r.ptr[3] = ia.array[3];
        r.ptr[4] = ia.array[4];
        r.ptr[5] = ia.array[5];
        r.ptr[6] = ia.array[6];
        r.ptr[7] = ia.array[7];
        return r;
    }
}
unittest
{
    __m256 R = _mm256_cvtepi32_ps(_mm256_set1_epi32(5));
    float[8] correct = [5.0f, 5, 5, 5, 5, 5, 5, 5];
    assert(R.array == correct);
}

/// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit 
/// integers. Follows the current rounding mode.
__m128i _mm256_cvtpd_epi32 (__m256d a) @safe
{
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_cvtpd2dq256(a);
    }
    else
    {
        __m128d lo = _mm256_extractf128_pd!0(a);
        __m128d hi = _mm256_extractf128_pd!1(a);
        __m128i ilo = _mm_cvtpd_epi32(lo); // Only lower 64-bit contains significant values
        __m128i ihi = _mm_cvtpd_epi32(hi);
        return _mm_unpacklo_epi64(ilo, ihi);
    }
}
unittest
{
    int4 A = _mm256_cvtpd_epi32(_mm256_setr_pd(61.0, 55.0, -100, 1_000_000));
    int[4] correct = [61, 55, -100, 1_000_000];
    assert(A.array == correct);
}

/// Convert packed double-precision (64-bit) floating-point elements in `a` to packed single-precision (32-bit) 
/// floating-point elements.
__m128 _mm256_cvtpd_ps (__m256d a) pure @trusted
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_cvtpd2ps256(a);
    }
    else
    {
        __m128 r;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        r.ptr[2] = a.array[2];
        r.ptr[3] = a.array[3];
        return r;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(1.0, 2, 3, 5);
    __m128 R = _mm256_cvtpd_ps(A);
    float[4] correct = [1.0f, 2, 3, 5];
    assert(R.array == correct);
}

/// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit 
/// integers, using the current rounding mode.
__m256i _mm256_cvtps_epi32 (__m256 a) @trusted
{
    static if (GDC_or_LDC_with_AVX)
    {
        return cast(__m256i) __builtin_ia32_cvtps2dq256(a);
    }
    else
    {
        __m128 lo = _mm256_extractf128_ps!0(a);
        __m128 hi = _mm256_extractf128_ps!1(a);
        __m128i ilo = _mm_cvtps_epi32(lo);
        __m128i ihi = _mm_cvtps_epi32(hi);
        return _mm256_set_m128i(ihi, ilo);
    }
}
unittest
{
    uint savedRounding = _MM_GET_ROUNDING_MODE();

    _MM_SET_ROUNDING_MODE(_MM_ROUND_NEAREST);
    __m256i A = _mm256_cvtps_epi32(_mm256_setr_ps(1.4f, -2.1f, 53.5f, -2.9f, -1.4f, 2.1f, -53.5f, 2.9f));
    assert( (cast(int8)A).array == [1, -2, 54, -3, -1, 2, -54, 3]);

    _MM_SET_ROUNDING_MODE(_MM_ROUND_DOWN);
    A = _mm256_cvtps_epi32(_mm256_setr_ps(1.3f, -2.11f, 53.4f, -2.8f, -1.3f, 2.11f, -53.4f, 2.8f));
    assert( (cast(int8)A).array == [1, -3, 53, -3, -2, 2, -54, 2]);

    _MM_SET_ROUNDING_MODE(_MM_ROUND_UP);
    A = _mm256_cvtps_epi32(_mm256_setr_ps(1.3f, -2.12f, 53.6f, -2.7f, -1.3f, 2.12f, -53.6f, 2.7f));
    assert( (cast(int8)A).array == [2, -2, 54, -2, -1, 3, -53, 3]);

    _MM_SET_ROUNDING_MODE(_MM_ROUND_TOWARD_ZERO);
    A = _mm256_cvtps_epi32(_mm256_setr_ps(1.4f, -2.17f, 53.8f, -2.91f, -1.4f, 2.17f, -53.8f, 2.91f));
    assert( (cast(int8)A).array == [1, -2, 53, -2, -1, 2, -53, 2]);

    _MM_SET_ROUNDING_MODE(savedRounding);
}


/// Convert packed single-precision (32-bit) floating-point elements in `a`` to packed double-precision 
/// (64-bit) floating-point elements.
__m256d _mm256_cvtps_pd (__m128 a) pure @trusted
{   
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_cvtps2pd256(a); // LDC doesn't have the builtin
    }
    else
    {
        // LDC: x86, needs -O2 to generate cvtps2pd since LDC 1.2.0
        __m256d r;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        r.ptr[2] = a.array[2];
        r.ptr[3] = a.array[3];
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2, 3, 5);
    __m256d R = _mm256_cvtps_pd(A);
    double[4] correct = [1.0, 2, 3, 5];
    assert(R.array == correct);
}

/// Return the lower double-precision (64-bit) floating-point element of `a`.
double _mm256_cvtsd_f64 (__m256d a) pure @safe
{
    return a.array[0];
}

/// Return the lower 32-bit integer in `a`.
int _mm256_cvtsi256_si32 (__m256i a) pure @safe
{
    return (cast(int8)a).array[0];
}

/// Return the lower single-precision (32-bit) floating-point element of `a`.
float _mm256_cvtss_f32 (__m256 a) pure @safe
{
    return a.array[0];
}

/// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit 
/// integers with truncation.
__m128i _mm256_cvttpd_epi32 (__m256d a) pure @trusted
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return cast(__m128i)__builtin_ia32_cvttpd2dq256(a);
    }
    else
    {
        __m128i r;
        r.ptr[0] = cast(int)a.array[0];
        r.ptr[1] = cast(int)a.array[1];
        r.ptr[2] = cast(int)a.array[2];
        r.ptr[3] = cast(int)a.array[3];
        return r;
    }
}
unittest
{
    __m256d A = _mm256_set_pd(4.7, -1000.9, -7.1, 3.1);
    __m128i R = _mm256_cvttpd_epi32(A);
    int[4] correct = [3, -7, -1000, 4];
    assert(R.array == correct);
}

/// Convert packed single-precision (32-bit) floating-point elements in `a`.
__m256i _mm256_cvttps_epi32 (__m256 a) pure @trusted
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return cast(__m256i)__builtin_ia32_cvttps2dq256(a);
    }
    else
    {
        int8 r;
        r.ptr[0] = cast(int)a.array[0];
        r.ptr[1] = cast(int)a.array[1];
        r.ptr[2] = cast(int)a.array[2];
        r.ptr[3] = cast(int)a.array[3];
        r.ptr[4] = cast(int)a.array[4];
        r.ptr[5] = cast(int)a.array[5];
        r.ptr[6] = cast(int)a.array[6];
        r.ptr[7] = cast(int)a.array[7];
        return cast(__m256i)r;
    }
}
unittest
{
    __m256 A = _mm256_set_ps(4.7, -1000.9, -7.1, 3.1, 1.4, 2.9, -2.9, 0);
    int8 R = cast(int8) _mm256_cvttps_epi32(A);
    int[8] correct = [0, -2, 2, 1, 3, -7, -1000, 4];
    assert(R.array == correct);
}

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
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_dpps256(a, b, cast(ubyte)imm8);
    }
    else
    {
        // Note: in LDC with SSE4.1 but no AVX, we _could_ increase perf a bit by using two 
        // _mm_dp_ps.
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

/// Extract a 128-bits lane from `a`, selected with `index` (0 or 1).
/// Note: `_mm256_extractf128_pd!0` is equivalent to `_mm256_castpd256_pd128`.
__m128d _mm256_extractf128_pd(ubyte imm8)(__m256d a) pure @trusted
{
    version(GNU) pragma(inline, true); // else GDC has trouble inlining this

    // PERF DMD
    static if (GDC_with_AVX)
    {
        // Note: needs to be a template intrinsics because of this builtin.
        return __builtin_ia32_vextractf128_pd256(a, imm8 & 1);
    }
    else
    {
        double2 r = void;
        enum int index = 2*(imm8 & 1);
        r.ptr[0] = a.array[index+0];
        r.ptr[1] = a.array[index+1];
        return r;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(1.0, 2, 3, 4);
    double[4] correct = [1.0, 2, 3, 4];
    __m128d l0 = _mm256_extractf128_pd!18(A);
    __m128d l1 = _mm256_extractf128_pd!55(A);
    assert(l0.array == correct[0..2]);
    assert(l1.array == correct[2..4]);
}

///ditto
__m128 _mm256_extractf128_ps(ubyte imm8)(__m256 a) pure @trusted
{
    version(GNU) pragma(inline, true); // else GDC has trouble inlining this

    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_vextractf128_ps256(a, imm8 & 1);
    }
    else
    {
        float4 r = void; // Optimize well since LDC 1.1 -O1
        enum int index = 4*(imm8 & 1);
        r.ptr[0] = a.array[index+0];
        r.ptr[1] = a.array[index+1];
        r.ptr[2] = a.array[index+2];
        r.ptr[3] = a.array[index+3];
        return r;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(1.0, 2, 3, 4, 5, 6, 7, 8);
    float[8] correct = [1.0, 2, 3, 4, 5, 6, 7, 8];
    __m128 l0 = _mm256_extractf128_ps!8(A);
    __m128 l1 = _mm256_extractf128_ps!255(A);
    assert(l0.array == correct[0..4]);
    assert(l1.array == correct[4..8]);
}

///ditto
__m128i _mm256_extractf128_si256(ubyte imm8)(__m256i a) pure @trusted
{
    version(GNU) pragma(inline, true); // else GDC has trouble inlining this

    // PERF DMD
    static if (GDC_with_AVX)
    {
        // Note: if it weren't for this GDC intrinsic, _mm256_extractf128_si256
        // could be a non-template, however, this wins in -O0.
        // Same story for _mm256_extractf128_ps and _mm256_extractf128_pd
        return __builtin_ia32_vextractf128_si256(cast(int8)a, imm8 & 1);
    }
    else
    {
        long2 r = void;
        enum int index = 2*(imm8 & 1);
        r.ptr[0] = a.array[index+0];
        r.ptr[1] = a.array[index+1];
        return cast(__m128i)r;
    }
}
unittest
{
    __m256i A = _mm256_setr_epi32(9, 2, 3, 4, 5, 6, 7, 8);
    int[8] correct = [9, 2, 3, 4, 5, 6, 7, 8];
    __m128i l0 = _mm256_extractf128_si256!0(A);
    __m128i l1 = _mm256_extractf128_si256!1(A);
    assert(l0.array == correct[0..4]);
    assert(l1.array == correct[4..8]);
}

/// Round the packed double-precision (64-bit) floating-point elements in `a` down to an integer 
/// value, and store the results as packed double-precision floating-point elements.
__m256d _mm256_floor_pd (__m256d a) @safe
{
    static if (LDC_with_ARM64)
    {
        __m128d lo = _mm256_extractf128_pd!0(a);
        __m128d hi = _mm256_extractf128_pd!1(a);
        __m128d ilo = _mm_floor_pd(lo);
        __m128d ihi = _mm_floor_pd(hi);
        return _mm256_set_m128d(ihi, ilo);
    }
    else
    {
        return _mm256_round_pd!1(a);
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(1.3f, -2.12f, 53.6f, -2.7f);
    A = _mm256_floor_pd(A);
    double[4] correct = [1.0, -3.0, 53.0, -3.0];
    assert(A.array == correct);
}

/// Round the packed single-precision (32-bit) floating-point elements in `a` down to an integer 
/// value, and store the results as packed single-precision floating-point elements.
__m256 _mm256_floor_ps (__m256 a) @safe
{
    static if (LDC_with_ARM64)
    {
        __m128 lo = _mm256_extractf128_ps!0(a);
        __m128 hi = _mm256_extractf128_ps!1(a);
        __m128 ilo = _mm_floor_ps(lo);
        __m128 ihi = _mm_floor_ps(hi);
        return _mm256_set_m128(ihi, ilo);
    }
    else
    {
        return _mm256_round_ps!1(a);
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(1.3f, -2.12f, 53.6f, -2.7f, -1.3f, 2.12f, -53.6f, 2.7f);
    __m256 C = _mm256_floor_ps(A);
    float[8] correct       = [1.0f, -3.0f,  53.0f, -3.0f, -2,    2,     -54,    2];
    assert(C.array == correct);
}

/// Horizontally add adjacent pairs of double-precision (64-bit) floating-point elements in `a` 
/// and `b`. 
__m256d _mm256_hadd_pd (__m256d a, __m256d b) pure @trusted
{
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_haddpd256(a, b);
    }
    else
    {
        __m256d res;
        res.ptr[0] = a.array[1] + a.array[0];
        res.ptr[1] = b.array[1] + b.array[0];
        res.ptr[2] = a.array[3] + a.array[2];
        res.ptr[3] = b.array[3] + b.array[2];
        return res;
    }
}
unittest
{
    __m256d A =_mm256_setr_pd(1.5, 2.0, 21.0, 9.0);
    __m256d B =_mm256_setr_pd(1.0, 7.0, 100.0, 14.0);
    __m256d C = _mm256_hadd_pd(A, B);
    double[4] correct =      [3.5, 8.0, 30.0, 114.0];
    assert(C.array == correct);
}

/// Horizontally add adjacent pairs of single-precision (32-bit) floating-point elements in `a` and
/// `b`.
__m256 _mm256_hadd_ps (__m256 a, __m256 b) pure @trusted
{
    // PERD DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_haddps256(a, b);
    }
    else static if (LDC_with_ARM64)
    {
        __m128 a_hi = _mm256_extractf128_ps!1(a);
        __m128 a_lo = _mm256_extractf128_ps!0(a);
        __m128 b_hi = _mm256_extractf128_ps!1(b);
        __m128 b_lo = _mm256_extractf128_ps!0(b);
        __m128 hi = vpaddq_f32(a_hi, b_hi);
        __m128 lo = vpaddq_f32(a_lo, b_lo);
        return _mm256_set_m128(hi, lo);
    }
    else
    {    
        __m256 res;
        res.ptr[0] = a.array[1] + a.array[0];
        res.ptr[1] = a.array[3] + a.array[2];
        res.ptr[2] = b.array[1] + b.array[0];
        res.ptr[3] = b.array[3] + b.array[2];
        res.ptr[4] = a.array[5] + a.array[4];
        res.ptr[5] = a.array[7] + a.array[6];
        res.ptr[6] = b.array[5] + b.array[4];
        res.ptr[7] = b.array[7] + b.array[6];
        return res;
    }
}
unittest
{
    __m256 A =_mm256_setr_ps(1.0f, 2.0f, 3.0f, 5.0f, 1.0f, 2.0f, 3.0f, 5.0f);
    __m256 B =_mm256_setr_ps(1.5f, 2.0f, 3.5f, 4.0f, 1.5f, 2.0f, 3.5f, 5.0f);
    __m256 R = _mm256_hadd_ps(A, B);
    float[8] correct =      [3.0f, 8.0f, 3.5f, 7.5f, 3.0f, 8.0f, 3.5f, 8.5f];
    assert(R.array == correct);
}

/// Horizontally subtract adjacent pairs of double-precision (64-bit) floating-point elements in
/// `a` and `b`. 
__m256d _mm256_hsub_pd (__m256d a, __m256d b) pure @trusted
{
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_hsubpd256(a, b);
    }
    else 
    {
        // 2 zip1, 2 zip2, 2 fsub... I don't think there is better in arm64
        __m256d res;
        res.ptr[0] = a.array[0] - a.array[1];
        res.ptr[1] = b.array[0] - b.array[1];
        res.ptr[2] = a.array[2] - a.array[3];
        res.ptr[3] = b.array[2] - b.array[3];
        return res;
    }
}
unittest
{
    __m256d A =_mm256_setr_pd(1.5, 2.0, 21.0, 9.0);
    __m256d B =_mm256_setr_pd(1.0, 7.0, 100.0, 14.0);
    __m256d C = _mm256_hsub_pd(A, B);
    double[4] correct =      [-0.5, -6.0, 12.0, 86.0];
    assert(C.array == correct);
}

__m256 _mm256_hsub_ps (__m256 a, __m256 b) pure @trusted
{
    // PERD DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_hsubps256(a, b);
    }
    else
    {
        __m128 a_hi = _mm256_extractf128_ps!1(a);
        __m128 a_lo = _mm256_extractf128_ps!0(a);
        __m128 b_hi = _mm256_extractf128_ps!1(b);
        __m128 b_lo = _mm256_extractf128_ps!0(b);
        __m128 hi = _mm_hsub_ps(a_hi, b_hi);
        __m128 lo = _mm_hsub_ps(a_lo, b_lo);
        return _mm256_set_m128(hi, lo);
    }
}
unittest
{
    __m256 A =_mm256_setr_ps(1.0f, 2.0f, 3.0f, 5.0f, 1.0f, 2.0f, 3.0f, 5.0f);
    __m256 B =_mm256_setr_ps(1.5f, 2.0f, 3.5f, 4.0f, 1.5f, 2.0f, 3.5f, 5.0f);
    __m256 R = _mm256_hsub_ps(A, B);
    float[8] correct =   [-1.0f, -2.0f, -0.5f, -0.5f, -1.0f, -2.0f, -0.5f, -1.5f];
    assert(R.array == correct);
}

/// Copy `a`, and insert the 16-bit integer `i` into the result at the location specified by 
/// `index & 15`.
__m256i _mm256_insert_epi16 (__m256i a, short i, const int index) pure @trusted
{
    short16 sa = cast(short16)a;
    sa.ptr[index & 15] = i;
    return cast(__m256i)sa;
}
unittest
{
    __m256i A = _mm256_set1_epi16(1);
    short16 R = cast(short16) _mm256_insert_epi16(A, 2, 16 + 16 + 7);
    short[16] correct = [1, 1, 1, 1, 1, 1, 1, 2, 
                         1, 1, 1, 1, 1, 1, 1, 1 ];
    assert(R.array == correct);
}

/// Copy `a`, and insert the 32-bit integer `i` into the result at the location specified by 
/// `index & 7`.
__m256i _mm256_insert_epi32 (__m256i a, int i, const int index) pure @trusted
{
    int8 ia = cast(int8)a;
    ia.ptr[index & 7] = i;
    return cast(__m256i)ia;
}
unittest
{
    __m256i A = _mm256_set1_epi32(1);
    int8 R = cast(int8) _mm256_insert_epi32(A, -2, 8 + 8 + 1);
    int[8] correct = [1, -2, 1, 1, 1, 1, 1, 1];
    assert(R.array == correct);
}

/// Copy `a`, and insert the 64-bit integer `i` into the result at the location specified by 
/// `index & 3`.
__m256i _mm256_insert_epi64(__m256i a, long i, const int index) pure @trusted
{
    a.ptr[index & 3] = i;
    return a;
}
unittest
{
    __m256i A = _mm256_set1_epi64(1);
    long4 R = cast(long4) _mm256_insert_epi64(A, -2, 2 - 4 - 4);
    long[4] correct = [1, 1, -2, 1];
    assert(R.array == correct);
}

/// Copy `a`, and insert the 8-bit integer `i` into the result at the location specified by 
/// `index & 31`.
__m256i _mm256_insert_epi8(__m256i a, byte i, const int index) pure @trusted
{
    byte32 ba = cast(byte32)a;
    ba.ptr[index & 31] = i;
    return cast(__m256i)ba;
}
unittest
{
    __m256i A = _mm256_set1_epi8(1);
    byte32 R = cast(byte32) _mm256_insert_epi8(A, -2, 7 - 32 - 32);
    byte[32] correct = [1, 1, 1, 1, 1, 1, 1,-2, 1, 1, 1, 1, 1, 1, 1, 1,
                        1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ];
    assert(R.array == correct);
}

/// Copy `a`, then insert 128 bits (composed of 2 packed double-precision (64-bit) 
/// floating-point elements) from `b` at the location specified by `imm8`.
__m256d _mm256_insertf128_pd(int imm8)(__m256d a, __m128d b) pure @trusted
{
    static if (GDC_with_AVX)
    {
        enum ubyte lane = imm8 & 1;
        return __builtin_ia32_vinsertf128_pd256(a, b, lane);
    }
    else
    {
        __m256d r = a;
        enum int index = (imm8 & 1) ? 2 : 0;
        r.ptr[index] = b.array[0];
        r.ptr[index+1] = b.array[1];
        return r;
    }
}

/// Copy `a` then insert 128 bits (composed of 4 packed single-precision (32-bit) floating-point
/// elements) from `b`, at the location specified by `imm8`.
__m256 _mm256_insertf128_ps(int imm8)(__m256 a, __m128 b) pure @trusted
{
    static if (GDC_with_AVX)
    {
        enum ubyte lane = imm8 & 1;
        return __builtin_ia32_vinsertf128_ps256(a, b, lane);
    }
    else
    {
        __m256 r = a;
        enum int index = (imm8 & 1) ? 4 : 0;
        r.ptr[index] = b.array[0];
        r.ptr[index+1] = b.array[1];
        r.ptr[index+2] = b.array[2];
        r.ptr[index+3] = b.array[3];
        return r;
    }
}

/// Copy `a`, then insert 128 bits from `b` at the location specified by `imm8`.
__m256i _mm256_insertf128_si256(int imm8)(__m256i a, __m128i b) pure @trusted
{
    static if (GDC_with_AVX)
    {
        enum ubyte lane = imm8 & 1;
        return cast(__m256i) __builtin_ia32_vinsertf128_si256 (cast(int8)a, b, lane);
    }
    else
    {
        long2 lb = cast(long2)b;
        __m256i r = a;
        enum int index = (imm8 & 1) ? 2 : 0;
        r.ptr[index] = lb.array[0];
        r.ptr[index+1] = lb.array[1];
        return r;
    }
}

/// Load 256-bits of integer data from unaligned memory into dst. 
/// This intrinsic may run better than `_mm256_loadu_si256` when the data crosses a cache 
/// line boundary.
__m256i _mm256_lddqu_si256(const(__m256i)* mem_addr) @trusted
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return cast(__m256i) __builtin_ia32_lddqu256(cast(const(char)*)mem_addr);
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
// See this dlang forum post => https://forum.dlang.org/thread/vymrsngsfibkmqsqffce@forum.dlang.org
__m256i _mm256_loadu_si256 (const(__m256i)* mem_addr) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return cast(__m256i) __builtin_ia32_loaddqu256(cast(const(char)*) mem_addr);
    }
    else static if (LDC_with_optimizations)
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
__m256i _mm256_load_si256 (const(void)* mem_addr) pure @system
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
__m256d _mm256_loadu_pd (const(void)* mem_addr) pure @system
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_loadupd256 ( cast(const(double)*) mem_addr);
    }
    else static if (LDC_with_optimizations)
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
__m256 _mm256_loadu_ps (const(float)* mem_addr) pure @system
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_loadups256 ( cast(const(float)*) mem_addr);
    }
    else static if (LDC_with_optimizations)
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

/// Load two 128-bit values (composed of 4 packed single-precision (32-bit) floating-point 
/// elements) from memory, and combine them into a 256-bit value. 
/// `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
__m256 _mm256_loadu2_m128 (const(float)* hiaddr, const(float)* loaddr) pure @system
{
    // Note: no particular instruction for this in x86.
    return _mm256_set_m128(_mm_loadu_ps(hiaddr), _mm_loadu_ps(loaddr));
}
unittest
{
    align(32) float[6] A = [4.5f, 2, 8, 97, -1, 3];
    align(32) float[6] B = [6.5f, 3, 9, 98, -2, 4];
    __m256 R = _mm256_loadu2_m128(&B[1], &A[1]);
    float[8] correct = [2.0f, 8, 97, -1, 3, 9, 98, -2];
    assert(R.array == correct);
}

/// Load two 128-bit values (composed of 2 packed double-precision (64-bit) floating-point
/// elements) from memory, and combine them into a 256-bit value. 
/// `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
__m256d _mm256_loadu2_m128d (const(double)* hiaddr, const(double)* loaddr) pure @system
{
    // Note: no particular instruction for this in x86.
    return _mm256_set_m128d(_mm_loadu_pd(hiaddr), _mm_loadu_pd(loaddr));
}
unittest
{
    align(32) double[4] A = [4.5f, 2, 8, 97];
    align(32) double[4] B = [6.5f, 3, 9, 98];
    __m256d R = _mm256_loadu2_m128d(&B[1], &A[1]);
    double[4] correct = [2.0, 8, 3, 9];
    assert(R.array == correct);
}

/// Load two 128-bit values (composed of integer data) from memory, and combine them into a 
/// 256-bit value. `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
__m256i _mm256_loadu2_m128i (const(__m128i)* hiaddr, const(__m128i)* loaddr) pure @trusted
{
    // Note: no particular instruction for this in x86.
    return _mm256_set_m128i(_mm_loadu_si128(hiaddr), _mm_loadu_si128(loaddr));
}
unittest
{
    align(32) long[4] A = [5, 2, 8, 97];
    align(32) long[4] B = [6, 3, 9, 98];
    __m256i R = _mm256_loadu2_m128i(cast(const(__m128i)*) &B[1], cast(const(__m128i)*)  &A[1]);
    long[4] correct = [2, 8, 3, 9];
    assert(R.array == correct);
}

version(DigitalMars)
{
    // this avoids a bug with DMD < 2.099 -a x86 -O
    private enum bool maskLoadWorkaroundDMD = (__VERSION__ < 2099);
}
else
{
    private enum bool maskLoadWorkaroundDMD = false;
}

/// Load packed double-precision (64-bit) floating-point elements from memory using `mask` 
/// (elements are zeroed out when the high bit of the corresponding element is not set).
/// Note: emulating that instruction isn't efficient, since it needs to perform memory access
/// only when needed.
/// See: "Note about mask load/store" to know why you must address valid memory only.
__m128d _mm_maskload_pd (const(double)* mem_addr, __m128i mask) /* pure */ @system
{
    // PERF DMD
    static if (LDC_with_AVX)
    {
        // MAYDO report that the builtin is impure
        return __builtin_ia32_maskloadpd(mem_addr, cast(long2)mask);
    }
    else static if (GDC_with_AVX)
    {
        return __builtin_ia32_maskloadpd(cast(double2*)mem_addr, cast(long2)mask);
    }
    else
    {
        __m128d a = _mm_loadu_pd(mem_addr);
        __m128d zero = _mm_setzero_pd();
        return _mm_blendv_pd(zero, a, cast(double2)mask);
    }
}
unittest
{
    static if (!maskLoadWorkaroundDMD) 
    {
        double[2] A = [7.5, 1];
        double2 B = _mm_maskload_pd(A.ptr, _mm_setr_epi64(-1, 1));
        double[2] correct = [7.5, 0];
        assert(B.array == correct);
    }
}

/// Load packed double-precision (64-bit) floating-point elements from memory using `mask`
/// (elements are zeroed out when the high bit of the corresponding element is not set).
/// See: "Note about mask load/store" to know why you must address valid memory only.
__m256d _mm256_maskload_pd (const(double)* mem_addr, __m256i mask) /*pure*/ @system
{
    // PERF DMD
    static if (LDC_with_AVX)
    {
        // MAYDO that the builtin is impure
        return __builtin_ia32_maskloadpd256(mem_addr, mask);
    }
    else static if (GDC_with_AVX)
    {
        return __builtin_ia32_maskloadpd256(cast(double4*)mem_addr, mask);
    }
    else
    {
        __m256d a = _mm256_loadu_pd(mem_addr);
        __m256d zero = _mm256_setzero_pd();
        return _mm256_blendv_pd(zero, a, cast(double4)mask);
    }
}
unittest
{
    static if (!maskLoadWorkaroundDMD)
    {
        double[4] A = [7.5, 1, 2, 3];
        double4 B = _mm256_maskload_pd(A.ptr, _mm256_setr_epi64(1, -1, -1, 1));
        double[4] correct = [0.0, 1, 2, 0];
        assert(B.array == correct);
    }
}

/// Load packed single-precision (32-bit) floating-point elements from memory using mask (elements
/// are zeroed out when the high bit of the corresponding element is not set).
/// Note: emulating that instruction isn't efficient, since it needs to perform memory access
/// only when needed.
/// See: "Note about mask load/store" to know why you must address valid memory only.
__m128 _mm_maskload_ps (const(float)* mem_addr, __m128i mask) /* pure */ @system
{
    // PERF DMD
    static if (LDC_with_AVX)
    {
        // MAYDO that the builtin is impure
        return __builtin_ia32_maskloadps(mem_addr, mask);
    }
    else static if (GDC_with_AVX)
    {
        return __builtin_ia32_maskloadps(cast(float4*)mem_addr, mask);
    }
    else
    {
        __m128 a = _mm_loadu_ps(mem_addr);
        __m128 zero = _mm_setzero_ps();
        return _mm_blendv_ps(zero, a, cast(float4)mask);
    }
}
unittest
{
    static if (!maskLoadWorkaroundDMD)
    {
        float[4] A = [7.5f, 1, 2, 3];
        float4 B = _mm_maskload_ps(A.ptr, _mm_setr_epi32(1, -1, -1, 1));  // can address invalid memory with mask load and writes!
        float[4] correct = [0.0f, 1, 2, 0];
        assert(B.array == correct);
    }
}

/// Load packed single-precision (32-bit) floating-point elements from memory using `mask`
/// (elements are zeroed out when the high bit of the corresponding element is not set).
/// Note: emulating that instruction isn't efficient, since it needs to perform memory access
/// only when needed.
/// See: "Note about mask load/store" to know why you must address valid memory only.
__m256 _mm256_maskload_ps (const(float)* mem_addr, __m256i mask) /*pure*/ @system
{
    // PERF DMD
    static if (LDC_with_AVX)
    {
        // MAYDO that the builtin is impure
        return __builtin_ia32_maskloadps256(mem_addr, cast(int8)mask);
    }
    else static if (GDC_with_AVX)
    {
        return __builtin_ia32_maskloadps256(cast(float8*)mem_addr, cast(int8)mask);
    }
    else
    {
        __m256 a = _mm256_loadu_ps(mem_addr);
        __m256 zero = _mm256_setzero_ps();
        return _mm256_blendv_ps(zero, a, cast(float8)mask);
    }
}
unittest
{
    float[8] A                  = [1,   7.5f,  1,  2, 3,  4,  5, 6];
    __m256i  M = _mm256_setr_epi32(1,     -1,  1, -1, 1, -1, -1, 1);
    float8 B = _mm256_maskload_ps(A.ptr, M);
    float[8] correct =            [0.0f, 7.5f, 0,  2, 0,  4,  5, 0];
    assert(B.array == correct);
}

/// Store packed double-precision (64-bit) floating-point elements from `a` into memory using `mask`.
/// Note: emulating that instruction isn't efficient, since it needs to perform memory access
/// only when needed.
/// See: "Note about mask load/store" to know why you must address valid memory only.
void _mm_maskstore_pd (double * mem_addr, __m128i mask, __m128d a) /* pure */ @system
{
    // PERF DMD
    static if (LDC_with_AVX)
    {
        // MAYDO that the builtin is impure
        __builtin_ia32_maskstorepd(mem_addr, cast(long2)mask, a);
    }
    else static if (GDC_with_AVX)
    {
        __builtin_ia32_maskstorepd(cast(double2*)mem_addr, cast(long2)mask, a);
    }
    else
    {
        __m128d source = _mm_loadu_pd(mem_addr);
        __m128d r = _mm_blendv_pd(source, a, cast(double2) mask);
        _mm_storeu_pd(mem_addr, r);
    }
}
unittest
{
    double[2] A = [0.0, 1.0];
    __m128i M = _mm_setr_epi64(-1, 0);
    __m128d B = _mm_setr_pd(2.0, 3.0);
    _mm_maskstore_pd(A.ptr, M, B);
    double[2] correct = [2.0, 1.0];
    assert(A == correct);
}


/// Store packed double-precision (64-bit) floating-point elements from `a` into memory using `mask`.
/// See: "Note about mask load/store" to know why you must address valid memory only.
static if (!llvm256BitStackWorkaroundIn32BitX86)
{
    void _mm256_maskstore_pd (double * mem_addr, __m256i mask, __m256d a) /* pure */ @system
    {
        // PERF DMD
        static if (LDC_with_AVX)
        {
            // MAYDO that the builtin is impure
            __builtin_ia32_maskstorepd256(mem_addr, cast(long4)mask, a);
        }
        else static if (GDC_with_AVX)
        {
            __builtin_ia32_maskstorepd256(cast(double4*)mem_addr, cast(long4)mask, a);
        }
        else
        {
            __m256d source = _mm256_loadu_pd(mem_addr);
            __m256d r = _mm256_blendv_pd(source, a, cast(double4) mask);
            _mm256_storeu_pd(mem_addr, r);
        }
    }
    unittest
    {
        double[4] A = [0.0, 1, 2, 3];
        __m256i M = _mm256_setr_epi64x(-9, 0, -1, 0);
        __m256d B = _mm256_setr_pd(2, 3, 4, 5);
        _mm256_maskstore_pd(A.ptr, M, B);
        double[4] correct = [2.0, 1, 4, 3];
        assert(A == correct);
    }
}

/// Store packed single-precision (32-bit) floating-point elements from `a` into memory using `mask`.
/// Note: emulating that instruction isn't efficient, since it needs to perform memory access
/// only when needed.
/// See: "Note about mask load/store" to know why you must address valid memory only.
void _mm_maskstore_ps (float * mem_addr, __m128i mask, __m128 a)  /* pure */ @system
{
    // PERF DMD
    static if (LDC_with_AVX)
    {
        // MAYDO report that the builtin is impure
        __builtin_ia32_maskstoreps(mem_addr, mask, a);
    }
    else static if (GDC_with_AVX)
    {
        __builtin_ia32_maskstoreps(cast(float4*)mem_addr, mask, a);
    }
    else
    {
        __m128 source = _mm_loadu_ps(mem_addr);
        __m128 r = _mm_blendv_ps(source, a, cast(float4) mask);
        _mm_storeu_ps(mem_addr, r);
    }
}
unittest
{
    float[4] A = [0.0f, 1, 2, 6];
    __m128i M = _mm_setr_epi32(-1, 0, -1, 0);
    __m128 B = _mm_setr_ps(2, 3, 4, 5);
    _mm_maskstore_ps(A.ptr, M, B);
    float[4] correct = [2.0f, 1, 4, 6];
    assert(A == correct);
}

static if (!llvm256BitStackWorkaroundIn32BitX86)
{
    /// Store packed single-precision (32-bit) floating-point elements from `a` into memory using `mask`.
    /// See: "Note about mask load/store" to know why you must address valid memory only.
    void _mm256_maskstore_ps (float * mem_addr, __m256i mask, __m256 a) /* pure */ @system
    {
        // PERF DMD
        static if (LDC_with_AVX)
        {
            // MAYDO report that the builtin is impure
            __builtin_ia32_maskstoreps256(mem_addr, cast(int8)mask, a);
        }
        else static if (GDC_with_AVX)
        {
            __builtin_ia32_maskstoreps256(cast(float8*)mem_addr, cast(int8)mask, a);
        }
        else
        {
            __m256 source = _mm256_loadu_ps(mem_addr);
            __m256 r = _mm256_blendv_ps(source, a, cast(float8) mask);
            _mm256_storeu_ps(mem_addr, r);
        }
    }
    unittest
    {
        float[8] A                 = [0.0f, 0, 1,  2, 3,  4,  5, 7];
        __m256i M = _mm256_setr_epi32(  0, -1, 0, -1, 0, -1, -1, 0);
        __m256 B = _mm256_set1_ps(6.0f);
        _mm256_maskstore_ps(A.ptr, M, B);
        float[8] correct           = [0.0f, 6, 1,  6, 3,  6,  6, 7];
        assert(A == correct);
    }
}

/// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`, and return 
/// packed maximum values.
__m256d _mm256_max_pd (__m256d a, __m256d b) pure @trusted
{    
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_maxpd256(a, b);
    }
    else
    {
        // LDC: becomes good in -O2
        // PERF: GDC without AVX
        a.ptr[0] = (a.array[0] > b.array[0]) ? a.array[0] : b.array[0];
        a.ptr[1] = (a.array[1] > b.array[1]) ? a.array[1] : b.array[1];
        a.ptr[2] = (a.array[2] > b.array[2]) ? a.array[2] : b.array[2];
        a.ptr[3] = (a.array[3] > b.array[3]) ? a.array[3] : b.array[3];
        return a;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(4.0, 1.0, -9.0, double.infinity);
    __m256d B = _mm256_setr_pd(1.0, 8.0,  0.0, 100000.0);
    __m256d M = _mm256_max_pd(A, B);
    double[4] correct =       [4.0, 8.0, 0.0, double.infinity];
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`, and return 
/// packed maximum values.
__m256 _mm256_max_ps (__m256 a, __m256 b) pure @trusted
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_maxps256(a, b);
    }
    else
    {
        // LDC: becomes good in -O2, but looks brittle.
        // PERF GDC without AVX
        a.ptr[0] = (a.array[0] > b.array[0]) ? a.array[0] : b.array[0];
        a.ptr[1] = (a.array[1] > b.array[1]) ? a.array[1] : b.array[1];
        a.ptr[2] = (a.array[2] > b.array[2]) ? a.array[2] : b.array[2];
        a.ptr[3] = (a.array[3] > b.array[3]) ? a.array[3] : b.array[3];
        a.ptr[4] = (a.array[4] > b.array[4]) ? a.array[4] : b.array[4];
        a.ptr[5] = (a.array[5] > b.array[5]) ? a.array[5] : b.array[5];
        a.ptr[6] = (a.array[6] > b.array[6]) ? a.array[6] : b.array[6];
        a.ptr[7] = (a.array[7] > b.array[7]) ? a.array[7] : b.array[7];
        return a;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(4.0, 1.0, -9.0, float.infinity, 1, 2, 3, 4);
    __m256 B = _mm256_setr_ps(1.0, 8.0,  0.0, 100000.0f     , 4, 3, 2, 1);
    __m256 M = _mm256_max_ps(A, B);
    float[8] correct =       [4.0, 8.0,  0.0, float.infinity , 4, 3, 3, 4];
}

// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`, and return 
/// packed minimum values.
__m256d _mm256_min_pd (__m256d a, __m256d b) pure @trusted
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_minpd256(a, b);
    }
    else
    {
        // LDC: becomes good in -O2
        // PERF: GDC without AVX
        a.ptr[0] = (a.array[0] < b.array[0]) ? a.array[0] : b.array[0];
        a.ptr[1] = (a.array[1] < b.array[1]) ? a.array[1] : b.array[1];
        a.ptr[2] = (a.array[2] < b.array[2]) ? a.array[2] : b.array[2];
        a.ptr[3] = (a.array[3] < b.array[3]) ? a.array[3] : b.array[3];
        return a;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(4.0, 1.0, -9.0, double.infinity);
    __m256d B = _mm256_setr_pd(1.0, 8.0,  0.0, 100000.0);
    __m256d M = _mm256_min_pd(A, B);
    double[4] correct =       [1.0, 8.0, -9.0, 100000.0];
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`, and return 
/// packed maximum values.
__m256 _mm256_min_ps (__m256 a, __m256 b) pure @trusted
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_minps256(a, b);
    }
    else
    {
        // LDC: becomes good in -O2, but looks brittle.
        // PERF GDC without AVX
        a.ptr[0] = (a.array[0] < b.array[0]) ? a.array[0] : b.array[0];
        a.ptr[1] = (a.array[1] < b.array[1]) ? a.array[1] : b.array[1];
        a.ptr[2] = (a.array[2] < b.array[2]) ? a.array[2] : b.array[2];
        a.ptr[3] = (a.array[3] < b.array[3]) ? a.array[3] : b.array[3];
        a.ptr[4] = (a.array[4] < b.array[4]) ? a.array[4] : b.array[4];
        a.ptr[5] = (a.array[5] < b.array[5]) ? a.array[5] : b.array[5];
        a.ptr[6] = (a.array[6] < b.array[6]) ? a.array[6] : b.array[6];
        a.ptr[7] = (a.array[7] < b.array[7]) ? a.array[7] : b.array[7];
        return a;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(4.0, 1.0, -9.0, float.infinity, 1, 2, 3, 4);
    __m256 B = _mm256_setr_ps(1.0, 8.0,  0.0, 100000.0f     , 4, 3, 2, 1);
    __m256 M = _mm256_min_ps(A, B);
    float[8] correct =       [1.0, 1.0, -9.0, 100000.0f     , 1, 2, 2, 1];
}

/// Duplicate even-indexed double-precision (64-bit) floating-point elements from `a`.
__m256d _mm256_movedup_pd (__m256d a) @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_movddup256 (a);
    }
    else
    {
        a.ptr[1] = a.array[0];
        a.ptr[3] = a.array[2];
        return a;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(1.0, 2, 3, 4);
    A = _mm256_movedup_pd(A);
    double[4] correct = [1.0, 1, 3, 3];
    assert(A.array == correct);
}

/// Duplicate odd-indexed single-precision (32-bit) floating-point elements from `a`.
__m256 _mm256_movehdup_ps (__m256 a) @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_movshdup256 (a);
    }
    else
    {
        a.ptr[0] = a.array[1];
        a.ptr[2] = a.array[3];
        a.ptr[4] = a.array[5];
        a.ptr[6] = a.array[7];
        return a;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(1.0f, 2, 3, 4, 5, 6, 7, 8);
    A = _mm256_movehdup_ps(A);
    float[8] correct = [2.0, 2, 4, 4, 6, 6, 8, 8];
    assert(A.array == correct);
}

/// Duplicate even-indexed single-precision (32-bit) floating-point elements from `a`.
__m256 _mm256_moveldup_ps (__m256 a) @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_movsldup256 (a);
    }
    else
    {
        a.ptr[1] = a.array[0];
        a.ptr[3] = a.array[2];
        a.ptr[5] = a.array[4];
        a.ptr[7] = a.array[6];
        return a;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(1.0f, 2, 3, 4, 5, 6, 7, 8);
    A = _mm256_moveldup_ps(A);
    float[8] correct = [1.0, 1, 3, 3, 5, 5, 7, 7];
    assert(A.array == correct);
}

/// Set each bit of result mask based on the most significant bit of the corresponding packed 
/// double-precision (64-bit) floating-point element in `a`.
int _mm256_movemask_pd (__m256d a) @safe
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_movmskpd256(a);
    }
    else static if (LDC_with_SSE2)
    {
        // this doesn't benefit GDC, and not clear for arm64.
        __m128d A_lo = _mm256_extractf128_pd!0(a);
        __m128d A_hi = _mm256_extractf128_pd!1(a);

        return (_mm_movemask_pd(A_hi) << 2) | _mm_movemask_pd(A_lo);
    }
    else
    {
        // Fortunately, branchless on arm64
        long4 lv = cast(long4)a;
        int r = 0;
        if (lv.array[0] < 0) r += 1;
        if (lv.array[1] < 0) r += 2;
        if (lv.array[2] < 0) r += 4;
        if (lv.array[3] < 0) r += 8;
        return r;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(-1, -double.infinity, 0, -1);
    assert(_mm256_movemask_pd(A) == 1 + 2 + 8);
}

/// Set each bit of mask result based on the most significant bit of the corresponding packed 
/// single-precision (32-bit) floating-point element in `a`.
int _mm256_movemask_ps (__m256 a) @system
{
    // PERF DMD
    // PERF GDC without AVX
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_movmskps256(a);
    }
    else version(LDC)
    {
        // this doesn't benefit GDC (unable to inline), but benefits both LDC with SSE2 and ARM64
        __m128 A_lo = _mm256_extractf128_ps!0(a);
        __m128 A_hi = _mm256_extractf128_ps!1(a);
        return (_mm_movemask_ps(A_hi) << 4) | _mm_movemask_ps(A_lo);
    }
    else
    {
        int8 lv = cast(int8)a;
        int r = 0;
        if (lv.array[0] < 0) r += 1;
        if (lv.array[1] < 0) r += 2;
        if (lv.array[2] < 0) r += 4;
        if (lv.array[3] < 0) r += 8;
        if (lv.array[4] < 0) r += 16;
        if (lv.array[5] < 0) r += 32;
        if (lv.array[6] < 0) r += 64;
        if (lv.array[7] < 0) r += 128;
        return r;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(-1, -double.infinity, 0, -1, 1, double.infinity, -2, double.nan);
    assert(_mm256_movemask_ps(A) == 1 + 2 + 8 + 64);
}

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

/// Shuffle double-precision (64-bit) floating-point elements in `a` using the control in `imm8`.
__m128d _mm_permute_pd(int imm8)(__m128d a) pure @trusted
{
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_vpermilpd(a, imm8 & 3);
    }
    else
    {
        // Shufflevector not particularly better for LDC here
        __m128d r;
        r.ptr[0] = a.array[imm8 & 1];
        r.ptr[1] = a.array[(imm8 >> 1) & 1];
        return r;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(5, 6);
    __m128d B = _mm_permute_pd!1(A);
    __m128d C = _mm_permute_pd!3(A);
    double[2] RB = [6, 5];
    double[2] RC = [6, 6];
    assert(B.array == RB);
    assert(C.array == RC);
}

///ditto
__m256d _mm256_permute_pd(int imm8)(__m256d a) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_vpermilpd256(a, imm8 & 15);
    }
    else version(LDC)
    {
        return shufflevectorLDC!(double4,        
                                       (imm8 >> 0) & 1,
                                     ( (imm8 >> 1) & 1),
                                 2 + ( (imm8 >> 2) & 1),
                                 2 + ( (imm8 >> 3) & 1) )(a, a);
    }
    else
    {
        __m256d r;
        r.ptr[0] = a.array[ imm8       & 1];
        r.ptr[1] = a.array[(imm8 >> 1) & 1];
        r.ptr[2] = a.array[2 + ((imm8 >> 2) & 1)];
        r.ptr[3] = a.array[2 + ((imm8 >> 3) & 1)];
        return r;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(0.0, 1, 2, 3);
    __m256d R = _mm256_permute_pd!(1 + 4)(A);
    double[4] correct = [1.0, 0, 3, 2];
    assert(R.array == correct);
}

/// Shuffle single-precision (32-bit) floating-point elements in `a` using the control in `imm8`.
__m128 _mm_permute_ps(int imm8)(__m128 a) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_vpermilps(a, cast(ubyte)imm8);
    }
    else version(LDC)
    {
        return shufflevectorLDC!(float4, (imm8 >> 0) & 3, (imm8 >> 2) & 3, (imm8 >> 4) & 3, 
            (imm8 >> 6) & 3)(a, a);
    }
    else
    {
        // PERF: could use _mm_shuffle_ps which is a super set
        // when AVX isn't available
        __m128 r;
        r.ptr[0] = a.array[(imm8 >> 0) & 3];
        r.ptr[1] = a.array[(imm8 >> 2) & 3];
        r.ptr[2] = a.array[(imm8 >> 4) & 3];
        r.ptr[3] = a.array[(imm8 >> 6) & 3];
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(0.0f, 1, 2, 3);
    __m128 R = _mm_permute_ps!(1 + 4 * 3 + 16 * 0 + 64 * 2)(A);
    float[4] correct = [1.0f, 3, 0, 2];
    assert(R.array == correct);
}

/// Shuffle single-precision (32-bit) floating-point elements in `a` within 128-bit lanes using 
/// the control in `imm8`. The same shuffle is applied in lower and higher 128-bit lane.
__m256 _mm256_permute_ps(int imm8)(__m256 a,) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_vpermilps256(a, cast(ubyte)imm8);
    }
    else version(LDC)
    {
        return shufflevectorLDC!(float8, 
            (imm8 >> 0) & 3, (imm8 >> 2) & 3, (imm8 >> 4) & 3, (imm8 >> 6) & 3,
            4 + ((imm8 >> 0) & 3), 4 + ((imm8 >> 2) & 3), 4 + ((imm8 >> 4) & 3), 
            4 + ((imm8 >> 6) & 3))(a, a);
    }
    else
    {
        __m256 r;
        r.ptr[0] = a.array[(imm8 >> 0) & 3];
        r.ptr[1] = a.array[(imm8 >> 2) & 3];
        r.ptr[2] = a.array[(imm8 >> 4) & 3];
        r.ptr[3] = a.array[(imm8 >> 6) & 3];
        r.ptr[4] = a.array[4 + ((imm8 >> 0) & 3)];
        r.ptr[5] = a.array[4 + ((imm8 >> 2) & 3)];
        r.ptr[6] = a.array[4 + ((imm8 >> 4) & 3)];
        r.ptr[7] = a.array[4 + ((imm8 >> 6) & 3)];
        return r;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(0.0f, 1, 2, 3, 4, 5, 6, 7);
    __m256 R = _mm256_permute_ps!(1 + 4 * 3 + 16 * 0 + 64 * 2)(A);
    float[8] correct = [1.0f, 3, 0, 2, 5, 7, 4, 6];
    assert(R.array == correct);
} 

/// Shuffle 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements) 
/// selected by `imm8` from `a` and `b`.
__m256d _mm256_permute2f128_pd(int imm8)(__m256d a, __m256d b) pure @safe
{
    return cast(__m256d) _mm256_permute2f128_si256!imm8(cast(__m256i)a, cast(__m256i)b);
}
///ditto
__m256d _mm256_permute2f128_ps(int imm8)(__m256 a, __m256 b) pure @safe
{
    return cast(__m256) _mm256_permute2f128_si256!imm8(cast(__m256i)a, cast(__m256i)b);
}
///ditto
__m256i _mm256_permute2f128_si256(int imm8)(__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX)
    {
        return cast(__m256i) __builtin_ia32_vperm2f128_si256(cast(int8)a, cast(int8)b, cast(ubyte)imm8);
    }
    else 
    {
        static __m128i SELECT4(int imm4)(__m256i a, __m256i b) pure @trusted
        {
            static assert(imm4 >= 0 && imm4 <= 15);
            static if (imm4 & 8)
            {
                return _mm_setzero_si128();
            }
            else static if ((imm4 & 2) == 0)
            {
                long2 r;
                enum int index = 2*(imm4 & 1);
                r.ptr[0] = a.array[index+0];
                r.ptr[1] = a.array[index+1];
                return cast(__m128i)r;
            }
            else
            {
                static assert( (imm4 & 2) != 0);
                long2 r;
                enum int index = 2*(imm4 & 1);
                r.ptr[0] = b.array[index+0];
                r.ptr[1] = b.array[index+1];
                return cast(__m128i)r;
            }
        }

        long4 r;
        __m128i lo = SELECT4!(imm8 & 15)(a, b);
        __m128i hi = SELECT4!((imm8 >> 4) & 15)(a, b);
        return _mm256_set_m128i(hi, lo);
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(8.0, 1, 2, 3);
    __m256d B = _mm256_setr_pd(4.0, 5, 6, 7);
    __m256d R = _mm256_permute2f128_pd!(128 + 2)(A, B);
    double[4] correct = [4.0, 5.0, 0.0, 0.0];
    assert(R.array == correct);

    __m256d R2 = _mm256_permute2f128_pd!(3*16 + 1)(A, B);
    double[4] correct2 = [2.0, 3.0, 6.0, 7.0];
    assert(R2.array == correct2);
}

/// Shuffle double-precision (64-bit) floating-point elements in `a` using the control in `b`.
/// Warning: the selector is in bit 1, not bit 0, of each 64-bit element!
///          This is really not intuitive.
__m128d _mm_permutevar_pd(__m128d a, __m128i b) pure @trusted
{
    enum bool implementWithByteShuffle = GDC_with_SSSE3 || LDC_with_SSSE3 || LDC_with_ARM64;

    static if (GDC_or_LDC_with_AVX)
    {
        return cast(__m128d) __builtin_ia32_vpermilvarpd(a, cast(long2)b);
    }
    else static if (implementWithByteShuffle)
    {
        align(16) static immutable byte[16] mmAddBase_u8 = [0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7];
        align(16) static immutable byte[16] mmBroadcast_u8 = [0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 8, 8, 8, 8, 8, 8];
        int4 bi = cast(int4)b;
        long2 two;
        two = 2;
        bi = _mm_slli_epi64(cast(__m128i)( (cast(long2)bi) & two), 2);
        bi = _mm_shuffle_epi8(bi, *cast(__m128i*)mmBroadcast_u8.ptr);
        // bi is now [ind0 ind0 ind0 ind0 ind0 ind0 ind0 ind0 ind1 ind1 ind1 ind1 ind1 ind1 ind1 ind1 ]
        byte16 bytesIndices = cast(byte16)bi;
        bytesIndices = bytesIndices + *cast(byte16*)mmAddBase_u8.ptr;

        // which allows us to make a single _mm_shuffle_epi8
        return cast(__m128d) _mm_shuffle_epi8(cast(__m128i)a, cast(__m128i)bytesIndices);
    }
    else
    {
        // This isn't great in ARM64, TBL or TBX instructions can't do that.
        // that could fit the bill, if it had 64-bit operands. But it only has 8-bit operands.
        // SVE2 could do it with svtbx[_f64] probably.
        long2 bl = cast(long2)b;
        __m128d r;
        r.ptr[0] = a.array[ (bl.array[0] & 2) >> 1];
        r.ptr[1] = a.array[ (bl.array[1] & 2) >> 1];
        return r;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(5, 6);
    __m128d B = _mm_permutevar_pd(A, _mm_setr_epi64(2, 1));
    __m128d C = _mm_permutevar_pd(A, _mm_setr_epi64(1 + 2 + 4, 2));    
    // yup, this is super strange, it's actually taking bit 1 and not bit 0 of each 64-bit element
    double[2] RB = [6, 5];
    double[2] RC = [6, 6];
    assert(B.array == RB);
    assert(C.array == RC);
}

///ditto
__m256d _mm256_permutevar_pd (__m256d a, __m256i b) pure @trusted
{
    // Worth it: for GDC, in SSSE3+
    //           for LDC, all the time
    version(LDC)
        enum bool implementWithByteShuffle = true;
    else
        enum bool implementWithByteShuffle = GDC_with_SSSE3;

    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return cast(__m256d) __builtin_ia32_vpermilvarpd256(a, cast(long4)b);
    }
    else static if (implementWithByteShuffle)
    {
        // because we don't have 256-bit vectors, split and use _mm_permutevar_ps
        __m128d a_lo = _mm256_extractf128_pd!0(a);
        __m128d a_hi = _mm256_extractf128_pd!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128d r_lo = _mm_permutevar_pd(a_lo, b_lo);
        __m128d r_hi = _mm_permutevar_pd(a_hi, b_hi);
        return _mm256_set_m128d(r_hi, r_lo);
    }
    else
    {
        long4 bl = cast(long4)b;
        __m256d r;
        r.ptr[0] = a.array[ (bl.array[0] & 2) >> 1];
        r.ptr[1] = a.array[ (bl.array[1] & 2) >> 1];
        r.ptr[2] = a.array[2 + ((bl.array[2] & 2) >> 1)];
        r.ptr[3] = a.array[2 + ((bl.array[3] & 2) >> 1)];
        return r;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(5, 6, 7, 8);
    __m256d B = _mm256_permutevar_pd(A, _mm256_setr_epi64(2, 1, 0, 2));
    __m256d C = _mm256_permutevar_pd(A, _mm256_setr_epi64(1 + 2 + 4, 2, 2, 0));
    // yup, this is super strange, it's actually taking bit 1 and not bit 0 of each 64-bit element
    double[4] RB = [6, 5, 7, 8];
    double[4] RC = [6, 6, 8, 7];
    assert(B.array == RB);
    assert(C.array == RC);
}

/// Shuffle single-precision (32-bit) floating-point elements in `a` using the control in `b`.
__m128 _mm_permutevar_ps (__m128 a, __m128i b) @trusted
{
    // PERF DMD

    enum bool implementWithByteShuffle = GDC_with_SSSE3 || LDC_with_SSSE3 || LDC_with_ARM64;

    static if (GDC_or_LDC_with_AVX)
    {
        return cast(__m128) __builtin_ia32_vpermilvarps(a, cast(int4)b);
    }
    else static if (implementWithByteShuffle)
    {
        // This workaround is worth it: in GDC with SSSE3, in LDC with SSSE3, in ARM64 (neon)
        int4 bi = cast(int4)b;
        int4 three;
        three = 3;
        bi = _mm_slli_epi32(bi & three, 2);
        // bi is [ind0 0 0 0 ind1 0 0 0 ind2 0 0 0 ind3 0 0 0]
        bi = bi | _mm_slli_si128!1(bi);
        bi = bi | _mm_slli_si128!2(bi);
        // bi is now [ind0 ind0 ind0 ind0 ind1 ind1 ind1 ind1 ind2 ind2 ind2 ind2 ind3 ind3 ind3 ind3]
        byte16 bytesIndices = cast(byte16)bi;
        align(16) static immutable byte[16] mmAddBase_u8 = [0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3];
        bytesIndices = bytesIndices + *cast(byte16*)mmAddBase_u8.ptr;

        // which allows us to make a single _mm_shuffle_epi8
        return cast(__m128) _mm_shuffle_epi8(cast(__m128i)a, cast(__m128i)bytesIndices);
    }
    else
    {

        int4 bi = cast(int4)b;
        __m128 r;
        r.ptr[0] = a.array[ (bi.array[0] & 3) ];
        r.ptr[1] = a.array[ (bi.array[1] & 3) ];
        r.ptr[2] = a.array[ (bi.array[2] & 3) ];
        r.ptr[3] = a.array[ (bi.array[3] & 3) ];
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(5, 6, 7, 8);
    __m128 B = _mm_permutevar_ps(A, _mm_setr_epi32(2, 1, 0, 2 + 4));
    __m128 C = _mm_permutevar_ps(A, _mm_setr_epi32(2, 3 + 8, 1, 0));
    float[4] RB = [7, 6, 5, 7];
    float[4] RC = [7, 8, 6, 5];
    assert(B.array == RB);
    assert(C.array == RC);
}

///ditto
__m256 _mm256_permutevar_ps (__m256 a, __m256i b) @trusted
{
    // In order to do those two, it is necessary to use _mm_shuffle_epi8 and reconstruct the integers afterwards.
    enum bool implementWithByteShuffle = GDC_with_SSSE3 || LDC_with_SSSE3 || LDC_with_ARM64;

    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vpermilvarps256(a, cast(int8)b);
    }
    else static if (implementWithByteShuffle)
    {
        // because we don't have 256-bit vectors, split and use _mm_permutevar_ps
        __m128 a_lo = _mm256_extractf128_ps!0(a);
        __m128 a_hi = _mm256_extractf128_ps!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128 r_lo = _mm_permutevar_ps(a_lo, b_lo);
        __m128 r_hi = _mm_permutevar_ps(a_hi, b_hi);
        return _mm256_set_m128(r_hi, r_lo);
    }
    else
    {
        int8 bi = cast(int8)b;
        __m256 r;
        r.ptr[0] = a.array[ (bi.array[0] & 3) ];
        r.ptr[1] = a.array[ (bi.array[1] & 3) ];
        r.ptr[2] = a.array[ (bi.array[2] & 3) ];
        r.ptr[3] = a.array[ (bi.array[3] & 3) ];
        r.ptr[4] = a.array[ 4 + (bi.array[4] & 3) ];
        r.ptr[5] = a.array[ 4 + (bi.array[5] & 3) ];
        r.ptr[6] = a.array[ 4 + (bi.array[6] & 3) ];
        r.ptr[7] = a.array[ 4 + (bi.array[7] & 3) ];
        return r;
    } 
}
unittest
{
    __m256 A = _mm256_setr_ps(1, 2, 3, 4, 5, 6, 7, 8);
    __m256 B = _mm256_permutevar_ps(A, _mm256_setr_epi32(2,     1, 0, 2, 3, 2, 1, 0));
    __m256 C = _mm256_permutevar_ps(A, _mm256_setr_epi32(2, 3 + 8, 1, 0, 2, 3, 0, 1));
    float[8] RB = [3.0f, 2, 1, 3, 8, 7, 6, 5];
    float[8] RC = [3.0f, 4, 2, 1, 7, 8, 5, 6];
    assert(B.array == RB);
    assert(C.array == RC);
}

/// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements
/// in `a`. The maximum relative error for this approximation is less than 1.5*2^-12.
__m256 _mm256_rcp_ps (__m256 a) pure @trusted
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_rcpps256(a);
    }
    else
    {        
        a.ptr[0] = 1.0f / a.array[0];
        a.ptr[1] = 1.0f / a.array[1];
        a.ptr[2] = 1.0f / a.array[2];
        a.ptr[3] = 1.0f / a.array[3];
        a.ptr[4] = 1.0f / a.array[4];
        a.ptr[5] = 1.0f / a.array[5];
        a.ptr[6] = 1.0f / a.array[6];
        a.ptr[7] = 1.0f / a.array[7];
        return a;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(2.34f, -70000.0f, 0.00001f, 345.5f, 9, -46, 1869816, 55583);
    __m256 groundTruth = _mm256_set1_ps(1.0f) / A;
    __m256 result = _mm256_rcp_ps(A);
    foreach(i; 0..8)
    {
        double relError = (cast(double)(groundTruth.array[i]) / result.array[i]) - 1;
        assert(abs_double(relError) < 0.00037); // 1.5*2^-12 is 0.00036621093
    }
}

/// Round the packed double-precision (64-bit) floating-point elements in `a` using the 
/// rounding parameter, and store the results as packed double-precision floating-point elements.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m256d _mm256_round_pd(int rounding)(__m256d a) @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_roundpd256(a, rounding);
    }
    else static if (LDC_with_AVX)
    {
        return __builtin_ia32_roundpd256(a, rounding);
    }
    else
    {
        static if (rounding & _MM_FROUND_CUR_DIRECTION)
        {
            // PERF: non-AVX x86, would probably be faster to convert those double at once to int64

            __m128d A_lo = _mm256_extractf128_pd!0(a);
            __m128d A_hi = _mm256_extractf128_pd!1(a);

            // Convert to 64-bit integers one by one
            long x0 = _mm_cvtsd_si64(A_lo);
            long x2 = _mm_cvtsd_si64(A_hi);
            A_lo.ptr[0] = A_lo.array[1];
            A_hi.ptr[0] = A_hi.array[1];
            long x1 = _mm_cvtsd_si64(A_lo);
            long x3 = _mm_cvtsd_si64(A_hi);

            return _mm256_setr_pd(x0, x1, x2, x3);
        }
        else
        {
            version(GNU) pragma(inline, false); // this was required for SSE4.1 rounding, let it here

            uint old = _MM_GET_ROUNDING_MODE();
            _MM_SET_ROUNDING_MODE((rounding & 3) << 13);
            
            __m128d A_lo = _mm256_extractf128_pd!0(a);
            __m128d A_hi = _mm256_extractf128_pd!1(a);

            // Convert to 64-bit integers one by one
            long x0 = _mm_cvtsd_si64(A_lo);
            long x2 = _mm_cvtsd_si64(A_hi);
            A_lo.ptr[0] = A_lo.array[1];
            A_hi.ptr[0] = A_hi.array[1];
            long x1 = _mm_cvtsd_si64(A_lo);
            long x3 = _mm_cvtsd_si64(A_hi);

            // Convert back to double to achieve the rounding
            // The problem is that a 64-bit double can't represent all the values 
            // a 64-bit integer can (and vice-versa). So this function won't work for
            // large values. (FUTURE: what range exactly?)
            _MM_SET_ROUNDING_MODE(old);
            return _mm256_setr_pd(x0, x1, x2, x3);
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
__m256 _mm256_round_ps(int rounding)(__m256 a) @trusted
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_roundps256(a, rounding);
    }
    else static if (GDC_or_LDC_with_SSE41)
    {
        // we can use _mm_round_ps
        __m128 lo = _mm256_extractf128_ps!0(a);
        __m128 hi = _mm256_extractf128_ps!1(a);
        __m128 ilo = _mm_round_ps!rounding(lo); // unfortunately _mm_round_ps isn't fast for arm64, so we avoid that in that case
        __m128 ihi = _mm_round_ps!rounding(hi);
        return _mm256_set_m128(ihi, ilo);
    }
    else
    {
        static if (rounding & _MM_FROUND_CUR_DIRECTION)
        {
            __m256i integers = _mm256_cvtps_epi32(a);
            return _mm256_cvtepi32_ps(integers);
        }
        else
        {
            version(LDC) pragma(inline, false); // else _MM_SET_ROUNDING_MODE and _mm_cvtps_epi32 gets shuffled
            uint old = _MM_GET_ROUNDING_MODE();
            _MM_SET_ROUNDING_MODE((rounding & 3) << 13);
            scope(exit) _MM_SET_ROUNDING_MODE(old);

            // Convert to 32-bit integers
            __m256i integers = _mm256_cvtps_epi32(a);

            // Convert back to float to achieve the rounding
            // The problem is that a 32-float can't represent all the values 
            // a 32-bit integer can (and vice-versa). So this function won't work for
            // large values. (FUTURE: what range exactly?)
            __m256 result = _mm256_cvtepi32_ps(integers);

            return result;
        }
    }
}
unittest
{
    // tested in other intrinsics
}


/// Compute the approximate reciprocal square root of packed single-precision (32-bit) 
/// floating-point elements in `a`. The maximum relative error for this approximation is less than
/// 1.5*2^-12.
__m256 _mm256_rsqrt_ps (__m256 a) pure @trusted
{
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_rsqrtps256(a);
    }
    else version(LDC)
    {
        a[0] = 1.0f / llvm_sqrt(a[0]);
        a[1] = 1.0f / llvm_sqrt(a[1]);
        a[2] = 1.0f / llvm_sqrt(a[2]);
        a[3] = 1.0f / llvm_sqrt(a[3]);
        a[4] = 1.0f / llvm_sqrt(a[4]);
        a[5] = 1.0f / llvm_sqrt(a[5]);
        a[6] = 1.0f / llvm_sqrt(a[6]);
        a[7] = 1.0f / llvm_sqrt(a[7]);
        return a;
    }
    else
    {
        a.ptr[0] = 1.0f / sqrt(a.array[0]);
        a.ptr[1] = 1.0f / sqrt(a.array[1]);
        a.ptr[2] = 1.0f / sqrt(a.array[2]);
        a.ptr[3] = 1.0f / sqrt(a.array[3]);
        a.ptr[4] = 1.0f / sqrt(a.array[4]);
        a.ptr[5] = 1.0f / sqrt(a.array[5]);
        a.ptr[6] = 1.0f / sqrt(a.array[6]);
        a.ptr[7] = 1.0f / sqrt(a.array[7]);
        return a;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(2.34f, 70000.0f, 0.00001f, 345.5f, 2.34f, 70000.0f, 0.00001f, 345.5f);
    __m256 groundTruth = _mm256_setr_ps(0.65372045f, 0.00377964473f, 316.227766f, 0.05379921937f,
                                        0.65372045f, 0.00377964473f, 316.227766f, 0.05379921937f);
    __m256 result = _mm256_rsqrt_ps(A);
    foreach(i; 0..8)
    {
        double relError = (cast(double)(groundTruth.array[i]) / result.array[i]) - 1;
        assert(abs_double(relError) < 0.00037); // 1.5*2^-12 is 0.00036621093
    }
}

/// Set packed 16-bit integers with the supplied values.
__m256i _mm256_set_epi16 (short e15, short e14, short e13, short e12, short e11, short e10, short e9, short e8, short e7, short e6, short e5, short e4, short e3, short e2, short e1, short e0) pure @trusted
{
    short16 r; // Note: = void would prevent GDC from inlining a constant short16...
    r.ptr[0] = e0;
    r.ptr[1] = e1;
    r.ptr[2] = e2;
    r.ptr[3] = e3;
    r.ptr[4] = e4;
    r.ptr[5] = e5;
    r.ptr[6] = e6;
    r.ptr[7] = e7;
    r.ptr[8] = e8;
    r.ptr[9] = e9;
    r.ptr[10] = e10;
    r.ptr[11] = e11;
    r.ptr[12] = e12;
    r.ptr[13] = e13;
    r.ptr[14] = e14;
    r.ptr[15] = e15;
    return cast(__m256i) r;
}
unittest
{
    short16 A = cast(short16) _mm256_set_epi16(15, 14, 13, 12, 11, 10, 9, 8, 
                                               7, 6, 5, 4, 3, 2, 1, 0);
    foreach(i; 0..16)
        assert(A.array[i] == i);
}

/// Set packed 32-bit integers with the supplied values.
__m256i _mm256_set_epi32 (int e7, int e6, int e5, int e4, int e3, int e2, int e1, int e0) pure @trusted
{
    // Inlines a constant with GCC -O1, LDC -O2
    int8 r; // = void would prevent GCC from inlining a constant call
    r.ptr[0] = e0;
    r.ptr[1] = e1;
    r.ptr[2] = e2;
    r.ptr[3] = e3;
    r.ptr[4] = e4;
    r.ptr[5] = e5;
    r.ptr[6] = e6;
    r.ptr[7] = e7;
    return cast(__m256i)r;
}
unittest
{
    int8 A = cast(int8) _mm256_set_epi32(7, 6, 5, 4, 3, 2, 1, 0);
    foreach(i; 0..8)
        assert(A.array[i] == i);
}

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

///ditto
alias _mm256_set_epi64 = _mm256_set_epi64x; // #BONUS, not sure why this isn't in Intel Intrinsics API.

/// Set packed 8-bit integers with the supplied values.
__m256i _mm256_set_epi8 (byte e31, byte e30, byte e29, byte e28, byte e27, byte e26, byte e25, byte e24, 
                         byte e23, byte e22, byte e21, byte e20, byte e19, byte e18, byte e17, byte e16, 
                         byte e15, byte e14, byte e13, byte e12, byte e11, byte e10,  byte e9,  byte e8, 
                          byte e7,  byte e6,  byte e5,  byte e4,  byte e3,  byte e2,  byte e1,  byte e0)
{
    // Inline a constant call in GDC -O1 and LDC -O2
    align(32) byte[32] result = [ e0,  e1,  e2,  e3,  e4,  e5,  e6,  e7,
                                  e8,  e9, e10, e11, e12, e13, e14, e15,
                                 e16, e17, e18, e19, e20, e21, e22, e23,
                                 e24, e25, e26, e27, e28, e29, e30, e31 ];
    return *cast(__m256i*)(result.ptr);
}
unittest
{
    byte32 R = cast(byte32) _mm256_set_epi8(-1, 0, 56, 127, -128, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 0, 1, 2, 3, 0, 1, 2, 3, 4, 5, 6, 7, 4, 5, 6, 7);
    byte[32] correct = [7, 6, 5, 4, 7, 6, 5, 4, 3, 2, 1, 0, 3, 2, 1, 0,
                        14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, -128, 127, 56, 0, -1];
    assert(R.array == correct);
}

/// Set packed `__m256d` vector with the supplied values.
__m256 _mm256_set_m128 (__m128 hi, __m128 lo) pure @trusted
{
    // DMD PERF
    static if (GDC_with_AVX)
    {
        __m256 r = __builtin_ia32_ps256_ps(lo);
        return __builtin_ia32_vinsertf128_ps256(r, hi, 1);
    }
    else
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

    /*
        // BUG, doesn't work if AVX vector is emulated, but SSE vector is not
        // See issue #108
        __m256 r = void;
        __m128* p = cast(__m128*)(&r);
        p[0] = lo;
        p[1] = hi;
        return r;
    */
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
    else
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
    version(DigitalMars) 
    {
        // workaround https://issues.dlang.org/show_bug.cgi?id=21469
        // It used to ICE, after that the codegen was just wrong.
        // No issue anymore in DMD 2.101, we can eventually remove that
        static if (__VERSION__ < 2101)
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
    version(DigitalMars) 
    {
        // No issue anymore in DMD 2.101, we can eventually remove that
        static if (__VERSION__ < 2101)
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
///ditto
alias _mm256_set1_epi64 = _mm256_set1_epi64x; // #BONUS, not sure why this isn't in Intel Intrinsics API.

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
    else static if (LDC_with_optimizations)
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
    // Inlines a constant with GCC -O1, LDC -O2
    int8 r; // = void would prevent GDC from inlining a constant call
    r.ptr[0] = e7;
    r.ptr[1] = e6;
    r.ptr[2] = e5;
    r.ptr[3] = e4;
    r.ptr[4] = e3;
    r.ptr[5] = e2;
    r.ptr[6] = e1;
    r.ptr[7] = e0;
    return cast(__m256i)r;
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
///ditto
alias _mm256_setr_epi64 = _mm256_setr_epi64x; // #BONUS, not sure why this isn't in Intel Intrinsics API.

/// Set packed 8-bit integers with the supplied values in reverse order.
__m256i _mm256_setr_epi8 (byte e31, byte e30, byte e29, byte e28, byte e27, byte e26, byte e25, byte e24,
                          byte e23, byte e22, byte e21, byte e20, byte e19, byte e18, byte e17, byte e16,
                          byte e15, byte e14, byte e13, byte e12, byte e11, byte e10, byte e9,  byte e8,
                          byte e7,  byte e6,  byte e5,  byte e4,  byte e3,  byte e2,  byte e1,  byte e0) pure @trusted
{
    // Inline a constant call in GDC -O1 and LDC -O2
    align(32) byte[32] result = [ e31,  e30,  e29,  e28,  e27,  e26,  e25,  e24,
                                  e23,  e22,  e21,  e20,  e19,  e18,  e17,  e16,
                                  e15,  e14,  e13,  e12,  e11,  e10,  e9,   e8,
                                   e7,   e6,   e5,   e4,   e3,   e2,   e1,   e0];
    return *cast(__m256i*)(result.ptr);
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

/// Set packed `__m256` vector with the supplied values.
__m256 _mm256_setr_m128 (__m128 lo, __m128 hi)
{
    return _mm256_set_m128(hi, lo);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2, 3, 4);
    __m128 B = _mm_setr_ps(3.0f, 4, 5, 6);
    __m256 R = _mm256_setr_m128(B, A);
    float[8] correct = [3.0f, 4, 5, 6, 1, 2, 3, 4,];
    assert(R.array == correct);
}

/// Set packed `__m256d` vector with the supplied values.
__m256d _mm256_setr_m128d (__m128d lo, __m128d hi)
{
    return _mm256_set_m128d(hi, lo);
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 2.0);
    __m128d B = _mm_setr_pd(3.0, 4.0);
    __m256d R = _mm256_setr_m128d(B, A);
    double[4] correct = [3.0, 4.0, 1.0, 2.0];
    assert(R.array == correct);
}

/// Set packed `__m256i` vector with the supplied values.
__m256i _mm256_setr_m128i (__m128i lo, __m128i hi)
{
    return _mm256_set_m128i(hi, lo);
}
unittest
{
    __m128i A = _mm_setr_epi32( 1,  2,  3,  4);
    __m128i B =  _mm_set_epi32(-3, -4, -5, -6);
    int8 R = cast(int8)_mm256_setr_m128i(B, A);
    int[8] correct = [-6, -5, -4, -3, 1, 2, 3, 4];
    assert(R.array == correct);
}

/// Set packed double-precision (64-bit) floating-point elements with the supplied values in reverse order.
__m256d _mm256_setr_pd (double e3, double e2, double e1, double e0) pure @trusted
{
    static if (LDC_with_optimizations)
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
    // PERF DMD
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
    // PERF DMD
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
        static if (__VERSION__ >= 2084) 
            return llvm_sqrt(a); // that capability appeared in LDC 1.14
        else
        {
            a.ptr[0] = llvm_sqrt(a.array[0]);
            a.ptr[1] = llvm_sqrt(a.array[1]);
            a.ptr[2] = llvm_sqrt(a.array[2]);
            a.ptr[3] = llvm_sqrt(a.array[3]);
            return a;
        }
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
        static if (__VERSION__ >= 2084) 
            return llvm_sqrt(a); // that capability appeared in LDC 1.14
        else
        {  
            a.ptr[0] = llvm_sqrt(a.array[0]);
            a.ptr[1] = llvm_sqrt(a.array[1]);
            a.ptr[2] = llvm_sqrt(a.array[2]);
            a.ptr[3] = llvm_sqrt(a.array[3]);
            a.ptr[4] = llvm_sqrt(a.array[4]);
            a.ptr[5] = llvm_sqrt(a.array[5]);
            a.ptr[6] = llvm_sqrt(a.array[6]);
            a.ptr[7] = llvm_sqrt(a.array[7]);
            return a;
        }
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

/// Store 256-bits of integer data from `a` into memory. `mem_addr` must be aligned on a 32-byte 
/// boundary or a general-protection exception may be generated.
void _mm256_store_si256 (__m256i * mem_addr, __m256i a) pure @safe
{
    *mem_addr = a;
}
unittest
{
    align(32) long[4] mem;
    long[4] correct = [5, -6, -7, 8];
    _mm256_store_si256(cast(__m256i*)(mem.ptr), _mm256_setr_epi64x(5, -6, -7, 8));
    assert(mem == correct);
}

/// Store 256-bits (composed of 4 packed double-precision (64-bit) floating-point elements) from 
/// `a` into memory. `mem_addr` does not need to be aligned on any particular boundary.
void _mm256_storeu_pd (double * mem_addr, __m256d a) pure @system
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        __builtin_ia32_storeupd256(mem_addr, a);
    }
    else static if (LDC_with_optimizations)
    {
        storeUnaligned!__m256d(a, mem_addr);
    }
    else
    {
        for(int n = 0; n < 4; ++n)
            mem_addr[n] = a.array[n];
    }
}
unittest
{
    align(32) double[6] arr = [0.0, 0, 0, 0, 0, 0];
    _mm256_storeu_pd(&arr[1], _mm256_set1_pd(4.0));
    double[4] correct = [4.0, 4, 4, 4];
    assert(arr[1..5] == correct);
}

/// Store 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from 
/// `a` into memory. `mem_addr` does not need to be aligned on any particular boundary.
void _mm256_storeu_ps (float* mem_addr, __m256 a) pure @system
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        __builtin_ia32_storeups256(mem_addr, a);
    }
    else static if (LDC_with_optimizations)
    {
        storeUnaligned!__m256(a, mem_addr);
    }
    else
    {
        for(int n = 0; n < 8; ++n)
            mem_addr[n] = a.array[n];
    }
}
unittest
{
    align(32) float[10] arr = [0.0f, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    _mm256_storeu_ps(&arr[1], _mm256_set1_ps(4.0f));
    float[8] correct = [4.0f, 4, 4, 4, 4, 4, 4, 4];
    assert(arr[1..9] == correct);
}


/// Store 256-bits of integer data from `a` into memory. `mem_addr` does not need to be aligned
///  on any particular boundary.
void _mm256_storeu_si256 (__m256i* mem_addr, __m256i a) pure @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        __builtin_ia32_storedqu256(cast(char*)mem_addr, cast(ubyte32) a);
    }
    else static if (LDC_with_optimizations)
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
unittest
{
    align(32) long[6] arr = [0, 0, 0, 0, 0, 0];
    _mm256_storeu_si256( cast(__m256i*) &arr[1], _mm256_set1_epi64x(4));
    long[4] correct = [4, 4, 4, 4];
    assert(arr[1..5] == correct);
}

/// Store the high and low 128-bit halves (each composed of 4 packed single-precision (32-bit) 
/// floating-point elements) from `a` into memory two different 128-bit locations. 
/// `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
void _mm256_storeu2_m128 (float* hiaddr, float* loaddr, __m256 a) pure @system
{
    // This is way better on GDC, and similarly in LDC, vs using other intrinsics
    loaddr[0] = a.array[0];
    loaddr[1] = a.array[1];
    loaddr[2] = a.array[2];
    loaddr[3] = a.array[3];
    hiaddr[0] = a.array[4];
    hiaddr[1] = a.array[5];
    hiaddr[2] = a.array[6];
    hiaddr[3] = a.array[7];
}
unittest
{
    align(32) float[11] A = [0.0f, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    _mm256_storeu2_m128(&A[1], &A[6], _mm256_set1_ps(2.0f));
    float[11] correct     = [0.0f, 2, 2, 2, 2, 0, 2, 2, 2, 2, 0];
    assert(A == correct);
}

/// Store the high and low 128-bit halves (each composed of 2 packed double-precision (64-bit)
/// floating-point elements) from `a` into memory two different 128-bit locations. 
/// `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
void _mm256_storeu2_m128d (double* hiaddr, double* loaddr, __m256d a) pure @system
{
    loaddr[0] = a.array[0];
    loaddr[1] = a.array[1];
    hiaddr[0] = a.array[2];
    hiaddr[1] = a.array[3];
}
unittest
{
    double[2] A;
    double[2] B;
    _mm256_storeu2_m128d(A.ptr, B.ptr, _mm256_set1_pd(-43.0));
    double[2] correct = [-43.0, -43];
    assert(A == correct);
    assert(B == correct);
}

/// Store the high and low 128-bit halves (each composed of integer data) from `a` into memory two 
/// different 128-bit locations. 
/// `hiaddr` and `loaddr` do not need to be aligned on any particular boundary.
void _mm256_storeu2_m128i (__m128i* hiaddr, __m128i* loaddr, __m256i a) pure @trusted
{
    long* hi = cast(long*)hiaddr;
    long* lo = cast(long*)loaddr;
    lo[0] = a.array[0];
    lo[1] = a.array[1];
    hi[0] = a.array[2];
    hi[1] = a.array[3];
}
unittest
{
    long[2] A;
    long[2] B;
    _mm256_storeu2_m128i(cast(__m128i*)A.ptr, cast(__m128i*)B.ptr, _mm256_set1_epi64x(-42));
    long[2] correct = [-42, -42];
    assert(A == correct);
    assert(B == correct);
}

/// Store 256-bits (composed of 4 packed single-precision (64-bit) floating-point elements) from
/// `a` into memory using a non-temporal memory hint. `mem_addr` must be aligned on a 32-byte 
/// boundary or a general-protection exception may be generated.
/// Note: non-temporal stores should be followed by `_mm_sfence()` for reader threads.
void _mm256_stream_pd (double* mem_addr, __m256d a) pure @system
{
    // PERF DMD
    // PERF GDC + SSE2
    static if (LDC_with_InlineIREx && LDC_with_optimizations)
    {
        enum prefix = `!0 = !{ i32 1 }`;
        enum ir = `
            store <4 x double> %1, <4 x double>* %0, align 32, !nontemporal !0
            ret void`;
        LDCInlineIREx!(prefix, ir, "", void, double4*, double4)(cast(double4*)mem_addr, a);
    }   
    else static if (GDC_with_AVX) // any hope to be non-temporal? Using SSE2 instructions.
    {
        __builtin_ia32_movntpd256 (mem_addr, a);
    }
    else
    {
        // Regular store instead.
        __m256d* dest = cast(__m256d*)mem_addr;
        *dest = a;
    }
}
unittest
{
    align(32) double[4] mem;
    double[4] correct = [5.0, -6, -7, 8];
    _mm256_stream_pd(mem.ptr, _mm256_setr_pd(5.0, -6, -7, 8));
    assert(mem == correct);
}

/// Store 256-bits (composed of 8 packed single-precision (32-bit) floating-point elements) from
/// `a` into memory using a non-temporal memory hint. `mem_addr` must be aligned on a 32-byte 
/// boundary or a general-protection exception may be generated.
/// Note: non-temporal stores should be followed by `_mm_sfence()` for reader threads.
void _mm256_stream_ps (float* mem_addr, __m256 a) pure @system
{
    // PERF DMD
    // PERF GDC + SSE2
    static if (LDC_with_InlineIREx && LDC_with_optimizations)
    {
        enum prefix = `!0 = !{ i32 1 }`;
        enum ir = `
            store <8 x float> %1, <8 x float>* %0, align 32, !nontemporal !0
            ret void`;
        LDCInlineIREx!(prefix, ir, "", void, float8*, float8)(cast(float8*)mem_addr, a);
    }   
    else static if (GDC_with_AVX)
    {
        __builtin_ia32_movntps256 (mem_addr, a);
    }
    else
    {
        // Regular store instead.
        __m256* dest = cast(__m256*)mem_addr;
        *dest = a;
    }
}
unittest
{
    align(32) float[8] mem;
    float[8] correct = [5, -6, -7, 8, 1, 2, 3, 4];
    _mm256_stream_ps(mem.ptr, _mm256_setr_ps(5, -6, -7, 8, 1, 2, 3, 4));
    assert(mem == correct);
}

/// Store 256-bits of integer data from `a` into memory using a non-temporal memory hint. 
/// `mem_addr` must be aligned on a 32-byte boundary or a general-protection exception may be
/// generated.
/// Note: there isn't any particular instruction in AVX to do that. It just defers to SSE2.
/// Note: non-temporal stores should be followed by `_mm_sfence()` for reader threads.
void _mm256_stream_si256 (__m256i * mem_addr, __m256i a) pure @trusted
{
    // PERF DMD
    // PERF GDC
    static if (LDC_with_InlineIREx && LDC_with_optimizations)
    {
        enum prefix = `!0 = !{ i32 1 }`;
        enum ir = `
            store <4 x i64> %1, <4 x i64>* %0, align 16, !nontemporal !0
            ret void`;
        LDCInlineIREx!(prefix, ir, "", void, long4*, long4)(mem_addr, a);
    }
    else static if (GDC_with_SSE2) // any hope to be non-temporal? Using SSE2 instructions.
    {
        long2 lo, hi;
        lo.ptr[0] = a.array[0];
        lo.ptr[1] = a.array[1];
        hi.ptr[0] = a.array[2];
        hi.ptr[1] = a.array[3];
        _mm_stream_si128(cast(__m128i*)mem_addr, cast(__m128i)lo);
        _mm_stream_si128((cast(__m128i*)mem_addr) + 1, cast(__m128i)hi);
    }
    else
    {
        // Regular store instead.
        __m256i* dest = cast(__m256i*)mem_addr;
        *dest = a;
    }
}
unittest
{
    align(32) long[4] mem;
    long[4] correct = [5, -6, -7, 8];
    _mm256_stream_si256(cast(__m256i*)(mem.ptr), _mm256_setr_epi64x(5, -6, -7, 8));
    assert(mem == correct);
}

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

/// Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate value, and 
/// return 1 if the sign bit of each 64-bit element in the intermediate value is zero, 
/// otherwise return 0.
int _mm_testc_pd (__m128d a, __m128d b) pure @trusted
{
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestcpd(a, b);
    }
    else
    {
        // PERF: maybe do the generic version more like simde
        long2 la = cast(long2)a;
        long2 lb = cast(long2)b;
        long2 r = ~la & lb;
        return r.array[0] >= 0 && r.array[1] >= 0;
    }
}
unittest
{
    __m128d A  = _mm_setr_pd(-1, 1);
    __m128d B = _mm_setr_pd(-1, -1);
    __m128d C = _mm_setr_pd(1, -1);
    assert(_mm_testc_pd(A, A) == 1);
    assert(_mm_testc_pd(A, B) == 0);
    assert(_mm_testc_pd(B, A) == 1);
}

///ditto
int _mm256_testc_pd (__m256d a, __m256d b) pure @safe
{
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestcpd256(a, b);
    }
    else static if (LDC_with_ARM64)
    {
        // better to split than do vanilla (down to 10 inst)
        __m128d lo_a = _mm256_extractf128_pd!0(a);
        __m128d lo_b = _mm256_extractf128_pd!0(b);
        __m128d hi_a = _mm256_extractf128_pd!1(a);
        __m128d hi_b = _mm256_extractf128_pd!1(b);
        return _mm_testc_pd(lo_a, lo_b) & _mm_testc_pd(hi_a, hi_b);
    }
    else
    {
        // PERF: do the generic version more like simde, maybe this get rids of arm64 version
        long4 la = cast(long4)a;
        long4 lb = cast(long4)b;
        long4 r = ~la & lb;
        return r.array[0] >= 0 && r.array[1] >= 0 && r.array[2] >= 0 && r.array[3] >= 0;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(-1, 1, -1, 1);
    __m256d B = _mm256_setr_pd(-1, -1, -1, -1);
    __m256d C = _mm256_setr_pd(1, -1, 1, -1);
    assert(_mm256_testc_pd(A, A) == 1);
    assert(_mm256_testc_pd(A, B) == 0);
    assert(_mm256_testc_pd(B, A) == 1);
}

/// Compute the bitwise NOT of `a` and then AND with `b`, producing an intermediate value, and 
/// return 1 if the sign bit of each 32-bit element in the intermediate value is zero, 
/// otherwise return 0.
int _mm_testc_ps (__m128 a, __m128 b) pure @safe
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestcps(a, b);
    }   
    else static if (LDC_with_ARM64)
    {
        int4 la = cast(int4)a;
        int4 lb = cast(int4)b;
        int4 r = ~la & lb;
        int4 shift;
        shift = 31;
        r >>= shift;
        int[4] zero = [0, 0, 0, 0];
        return r.array == zero;
    }
    else
    {
        // PERF: do the generic version more like simde, maybe this get rids of arm64 version
        int4 la = cast(int4)a;
        int4 lb = cast(int4)b;
        int4 r = ~la & lb;
        return r.array[0] >= 0 && r.array[1] >= 0 && r.array[2] >= 0 && r.array[3] >= 0;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(-1, 1, -1, 1);
    __m128 B = _mm_setr_ps(-1, -1, -1, -1);
    __m128 C = _mm_setr_ps(1, -1, 1, -1);
    assert(_mm_testc_ps(A, A) == 1);
    assert(_mm_testc_ps(A, B) == 0);
    assert(_mm_testc_ps(B, A) == 1);
}

///ditto
int _mm256_testc_ps (__m256 a, __m256 b) pure @safe
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestcps256(a, b);
    }
    else static if (LDC_with_ARM64)
    {
        int8 la = cast(int8)a;
        int8 lb = cast(int8)b;
        int8 r = ~la & lb;
        int8 shift;
        shift = 31;
        r >>= shift;
        int[8] zero = [0, 0, 0, 0, 0, 0, 0, 0];
        return r.array == zero;
    }
    else
    {
        // PERF: do the generic version more like simde, maybe this get rids of arm64 version
        int8 la = cast(int8)a;
        int8 lb = cast(int8)b;
        int8 r = ~la & lb;
        return r.array[0] >= 0 
            && r.array[1] >= 0
            && r.array[2] >= 0
            && r.array[3] >= 0
            && r.array[4] >= 0
            && r.array[5] >= 0
            && r.array[6] >= 0
            && r.array[7] >= 0;
    }
}
unittest
{
    __m256 A = _mm256_setr_ps(-1,  1, -1,  1, -1,  1, -1,  1);
    __m256 B = _mm256_setr_ps(-1, -1, -1, -1, -1, -1, -1, -1);
    __m256 C = _mm256_setr_ps( 1, -1,  1, -1,  1,  1,  1,  1);
    assert(_mm256_testc_ps(A, A) == 1);
    assert(_mm256_testc_ps(B, B) == 1);
    assert(_mm256_testc_ps(A, B) == 0);
    assert(_mm256_testc_ps(B, A) == 1);
    assert(_mm256_testc_ps(C, B) == 0);
    assert(_mm256_testc_ps(B, C) == 1);
}

/// Compute the bitwise NOT of `a` and then AND with `b`, and return 1 if the result is zero,
/// otherwise return 0.
/// In other words, test if all bits masked by `b` are also 1 in `a`.
int _mm256_testc_si256 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_ptestc256(cast(long4)a, cast(long4)b);
    }
    else static if (LDC_with_ARM64)
    {
        // better to split than do vanilla (down to 10 inst)
        __m128i lo_a = _mm256_extractf128_si256!0(a);
        __m128i lo_b = _mm256_extractf128_si256!0(b);
        __m128i hi_a = _mm256_extractf128_si256!1(a);
        __m128i hi_b = _mm256_extractf128_si256!1(b);
        return _mm_testc_si128(lo_a, lo_b) & _mm_testc_si128(hi_a, hi_b);
    }
    else
    {
        __m256i c = ~a & b;
        long[4] zero = [0, 0, 0, 0];
        return c.array == zero;
    }
}
unittest
{
    __m256i A  = _mm256_setr_epi64(0x01, 0x02, 0x04, 0xf8);
    __m256i M1 = _mm256_setr_epi64(0xfe, 0xfd, 0x00, 0x00);
    __m256i M2 = _mm256_setr_epi64(0x00, 0x00, 0x04, 0x00);
    assert(_mm256_testc_si256(A, A) == 1);
    assert(_mm256_testc_si256(A, M1) == 0);
    assert(_mm256_testc_si256(A, M2) == 1);
}

/// Compute the bitwise AND of 128 bits (representing double-precision (64-bit) floating-point 
/// elements) in `a` and `b`, producing an intermediate 128-bit value, and set ZF to 1 if the 
/// sign bit of each 64-bit element in the intermediate value is zero, otherwise set ZF to 0. 
/// Compute the bitwise NOT of a and then AND with b, producing an intermediate value, and set
/// CF to 1 if the sign bit of each 64-bit element in the intermediate value is zero, otherwise
/// set CF to 0. Return 1 if both the ZF and CF values are zero, otherwise return 0.
///
/// In other words: there is at least one negative number in `b` that correspond to a positive number in `a`,
///             AND there is at least one negative number in `b` that correspond to a negative number in `a`.
int _mm_testnzc_pd (__m128d a, __m128d b) pure @safe
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestnzcpd(a, b);
    }
    else
    {
        // ZF = 0 means "there is at least one pair of negative numbers"
        // ZF = 1 means "no pairs of negative numbers"
        // CF = 0 means "there is a negative number in b that is next to a positive number in a"
        // CF = 1 means "all negative numbers in b are also negative in a"
        // Consequently, CF = 0 and ZF = 0 means:
        //   "There is a pair of matching negative numbers in a and b, 
        //   AND also there is a negative number in b, that is matching a positive number in a"
        // Phew.

        // courtesy of simd-everywhere
        __m128i m = _mm_and_si128(cast(__m128i)a, cast(__m128i)b);
        __m128i m2 = _mm_andnot_si128(cast(__m128i)a, cast(__m128i)b);
        m = _mm_srli_epi64(m, 63);
        m2 = _mm_srli_epi64(m2, 63);
        return cast(int)( m.array[0] | m.array[2]) & (m2.array[0] | m2.array[2]);
    }
}
unittest
{
    __m128d PM = _mm_setr_pd( 1, -1);
    __m128d MP = _mm_setr_pd(-1,  1);
    __m128d MM = _mm_setr_pd(-1, -1);
    assert(_mm_testnzc_pd(PM, MP) == 0);
    assert(_mm_testnzc_pd(PM, MM) == 1);
    assert(_mm_testnzc_pd(MP, MP) == 0);
    assert(_mm_testnzc_pd(MP, MM) == 1);
    assert(_mm_testnzc_pd(MM, MM) == 0);
}

/// Compute the bitwise AND of 256 bits (representing double-precision (64-bit) floating-point 
/// elements) in `a` and `b`, producing an intermediate 256-bit value, and set ZF to 1 if the 
/// sign bit of each 64-bit element in the intermediate value is zero, otherwise set ZF to 0. 
/// Compute the bitwise NOT of a and then AND with b, producing an intermediate value, and set
/// CF to 1 if the sign bit of each 64-bit element in the intermediate value is zero, otherwise
/// set CF to 0. Return 1 if both the ZF and CF values are zero, otherwise return 0.
///
/// In other words: there is at least one negative number in `b` that correspond to a positive number in `a`,
///             AND there is at least one negative number in `b` that correspond to a negative number in `a`.
int _mm256_testnzc_pd (__m256d a, __m256d b) pure @safe
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestnzcpd256(a, b);
    }
    else
    {
        long4 la = cast(long4)a;
        long4 lb = cast(long4)b;
        long4 r = la & lb;
        long m = r.array[0] | r.array[1] | r.array[2] | r.array[3];
        int ZF = (~m >> 63) & 1;
        long4 r2 = ~la & lb;
        long m2 = r2.array[0] | r2.array[1] | r2.array[2] | r2.array[3];
        int CF = (~m2 >> 63) & 1;
        return (CF | ZF) == 0;
    }
}
unittest
{
    __m256d PM = _mm256_setr_pd( 1, -1, 1, 1);
    __m256d MP = _mm256_setr_pd(-1,  1, 1, 1);
    __m256d MM = _mm256_setr_pd(-1, -1, 1, 1);
    assert(_mm256_testnzc_pd(PM, MP) == 0);
    assert(_mm256_testnzc_pd(PM, MM) == 1);
    assert(_mm256_testnzc_pd(MP, MP) == 0);
    assert(_mm256_testnzc_pd(MP, MM) == 1);
    assert(_mm256_testnzc_pd(MM, MM) == 0);
}

/// Compute the bitwise AND of 128 bits (representing double-precision (64-bit) floating-point 
/// elements) in `a` and `b`, producing an intermediate 128-bit value, and set ZF to 1 if the 
/// sign bit of each 32-bit element in the intermediate value is zero, otherwise set ZF to 0. 
/// Compute the bitwise NOT of a and then AND with b, producing an intermediate value, and set
/// CF to 1 if the sign bit of each 32-bit element in the intermediate value is zero, otherwise
/// set CF to 0. Return 1 if both the ZF and CF values are zero, otherwise return 0.
///
/// In other words: there is at least one negative number in `b` that correspond to a positive number in `a`,
///             AND there is at least one negative number in `b` that correspond to a negative number in `a`.
int _mm_testnzc_ps (__m128 a, __m128 b) pure @safe
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestnzcps(a, b);
    }
    else
    {
        int4 la = cast(int4)a;
        int4 lb = cast(int4)b;
        int4 r = la & lb;
        int m = r.array[0] | r.array[1] | r.array[2] | r.array[3];
        int ZF = (~m >> 31) & 1;
        int4 r2 = ~la & lb;
        int m2 = r2.array[0] | r2.array[1] | r2.array[2] | r2.array[3];
        int CF = (~m2 >> 31) & 1;
        return (CF | ZF) == 0;
    }
}
unittest
{
    __m128 PM = _mm_setr_ps( 1, -1, 1, 1);
    __m128 MP = _mm_setr_ps(-1,  1, 1, 1);
    __m128 MM = _mm_setr_ps(-1, -1, 1, 1);
    assert(_mm_testnzc_ps(PM, MP) == 0);
    assert(_mm_testnzc_ps(PM, MM) == 1);
    assert(_mm_testnzc_ps(MP, MP) == 0);
    assert(_mm_testnzc_ps(MP, MM) == 1);
    assert(_mm_testnzc_ps(MM, MM) == 0);
}

/// Compute the bitwise AND of 256 bits (representing double-precision (64-bit) floating-point 
/// elements) in `a` and `b`, producing an intermediate 256-bit value, and set ZF to 1 if the 
/// sign bit of each 32-bit element in the intermediate value is zero, otherwise set ZF to 0. 
/// Compute the bitwise NOT of a and then AND with b, producing an intermediate value, and set
/// CF to 1 if the sign bit of each 32-bit element in the intermediate value is zero, otherwise
/// set CF to 0. Return 1 if both the ZF and CF values are zero, otherwise return 0.
///
/// In other words: there is at least one negative number in `b` that correspond to a positive number in `a`,
///             AND there is at least one negative number in `b` that correspond to a negative number in `a`.
int _mm256_testnzc_ps (__m256 a, __m256 b) pure @safe
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestnzcps256(a, b);
    }
    else
    {
        int8 la = cast(int8)a;
        int8 lb = cast(int8)b;
        int8 r = la & lb;
        int m = r.array[0] | r.array[1] | r.array[2] | r.array[3]
            |   r.array[4] | r.array[5] | r.array[6] | r.array[7];
        int ZF = (~m >> 31) & 1;
        int8 r2 = ~la & lb;
        int m2 = r2.array[0] | r2.array[1] | r2.array[2] | r2.array[3]
               | r2.array[4] | r2.array[5] | r2.array[6] | r2.array[7];
        int CF = (~m2 >> 31) & 1;
        return (CF | ZF) == 0;
    }
}
unittest
{
    __m256 PM = _mm256_setr_ps(1, 1, 1, 1,  1, -1, 1, 1);
    __m256 MP = _mm256_setr_ps(1, 1, 1, 1, -1,  1, 1, 1);
    __m256 MM = _mm256_setr_ps(1, 1, 1, 1, -1, -1, 1, 1);
    assert(_mm256_testnzc_ps(PM, MP) == 0);
    assert(_mm256_testnzc_ps(PM, MM) == 1);
    assert(_mm256_testnzc_ps(MP, MP) == 0);
    assert(_mm256_testnzc_ps(MP, MM) == 1);
    assert(_mm256_testnzc_ps(MM, MM) == 0);
}

/// Compute the bitwise AND of 256 bits (representing integer data) in `a` and `b`, 
/// and set ZF to 1 if the result is zero, otherwise set ZF to 0. 
/// Compute the bitwise NOT of `a` and then AND with `b`, and set CF to 1 if the 
/// result is zero, otherwise set CF to 0. 
/// Return 1 if both the ZF and CF values are zero, otherwise return 0.
int _mm256_testnzc_si256 (__m256i a, __m256i b) pure @trusted
{
    // PERF ARM64
    // PERF DMD
    // PERF LDC without AVX
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_ptestnzc256(cast(long4) a, cast(long4) b);
    }
    else
    {
        // Need to defer to _mm_testnzc_si128 if possible, for more speed
        __m256i c = a & b;
        __m256i d = ~a & b;
        long m = c.array[0] | c.array[1] | c.array[2] | c.array[3];
        long n = d.array[0] | d.array[1] | d.array[2] | d.array[3];
        return (m != 0) & (n != 0);
    }
}
unittest
{
    __m256i A  = _mm256_setr_epi32(0x01, 0x02, 0x04, 0xf8, 0, 0, 0, 0);
    __m256i M  = _mm256_setr_epi32(0x01, 0x40, 0x00, 0x00, 0, 0, 0, 0);
    __m256i Z = _mm256_setzero_si256();
    assert(_mm256_testnzc_si256(A, Z) == 0);
    assert(_mm256_testnzc_si256(A, M) == 1);
    assert(_mm256_testnzc_si256(A, A) == 0);
}

/// Compute the bitwise AND of 128 bits (representing double-precision (64-bit) floating-point 
/// elements) in `a` and `b`, producing an intermediate 128-bit value, return 1 if the sign bit of
/// each 64-bit element in the intermediate value is zero, otherwise return 0.
/// In other words, return 1 if `a` and `b` don't both have a negative number as the same place.
int _mm_testz_pd (__m128d a, __m128d b) pure @trusted
{
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestzpd(a, b);
    }
    else
    {
        long2 la = cast(long2)a;
        long2 lb = cast(long2)b;
        long2 r = la & lb;
        long m = r.array[0] | r.array[1];
        return (~m >> 63) & 1;
    }
}
unittest
{
    __m128d A  = _mm_setr_pd(-1, 1);
    __m128d B = _mm_setr_pd(-1, -1);
    __m128d C = _mm_setr_pd(1, -1);
    assert(_mm_testz_pd(A, A) == 0);
    assert(_mm_testz_pd(A, B) == 0);
    assert(_mm_testz_pd(C, A) == 1);
}

/// Compute the bitwise AND of 256 bits (representing double-precision (64-bit) floating-point 
/// elements) in `a` and `b`, producing an intermediate 256-bit value, return 1 if the sign bit of
/// each 64-bit element in the intermediate value is zero, otherwise return 0.
/// In other words, return 1 if `a` and `b` don't both have a negative number as the same place.
int _mm256_testz_pd (__m256d a, __m256d b) pure @trusted
{
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestzpd256(a, b);
    }
    else
    {
        long4 la = cast(long4)a;
        long4 lb = cast(long4)b;
        long4 r = la & lb;
        long r2 = r.array[0] | r.array[1] | r.array[2] | r.array[3];
        return (~r2 >> 63) & 1;
    }
}
unittest
{
    __m256d A = _mm256_setr_pd(-1, 1, -1, 1);
    __m256d B = _mm256_setr_pd(1,  1, -1, 1);
    __m256d C = _mm256_setr_pd(1, -1, 1, -1);
    assert(_mm256_testz_pd(A, A) == 0);
    assert(_mm256_testz_pd(A, B) == 0);
    assert(_mm256_testz_pd(C, A) == 1);
}

/// Compute the bitwise AND of 128 bits (representing double-precision (32-bit) floating-point 
/// elements) in `a` and `b`, producing an intermediate 128-bit value, return 1 if the sign bit of
/// each 32-bit element in the intermediate value is zero, otherwise return 0.
/// In other words, return 1 if `a` and `b` don't both have a negative number as the same place.
int _mm_testz_ps (__m128 a, __m128 b) pure @safe
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestzps(a, b);
    }
    else
    {
        int4 la = cast(int4)a;
        int4 lb = cast(int4)b;
        int4 r = la & lb;
        int m = r.array[0] | r.array[1] | r.array[2] | r.array[3];
        return (~m >> 31) & 1;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(-1,  1, -1,  1);
    __m128 B = _mm_setr_ps( 1,  1, -1,  1);
    __m128 C = _mm_setr_ps( 1, -1,  1, -1);
    assert(_mm_testz_ps(A, A) == 0);
    assert(_mm_testz_ps(A, B) == 0);
    assert(_mm_testz_ps(C, A) == 1);
    assert(_mm_testz_ps(C, B) == 1);
}

/// Compute the bitwise AND of 256 bits (representing double-precision (32-bit) floating-point 
/// elements) in `a` and `b`, producing an intermediate 256-bit value, return 1 if the sign bit of
/// each 32-bit element in the intermediate value is zero, otherwise return 0.
/// In other words, return 1 if `a` and `b` don't both have a negative number as the same place.
int _mm256_testz_ps (__m256 a, __m256 b) pure @safe
{
    // PERF DMD
    static if (GDC_or_LDC_with_AVX)
    {
        return __builtin_ia32_vtestzps256(a, b);
    }
    else
    {
        int8 la = cast(int8)a;
        int8 lb = cast(int8)b;
        int8 r = la & lb;
        int m = r.array[0] | r.array[1] | r.array[2] | r.array[3]
            | r.array[4] | r.array[5] | r.array[6] | r.array[7];
        return (~m >> 31) & 1;
    }
}

/// Compute the bitwise AND of 256 bits (representing integer data) in 
/// and return 1 if the result is zero, otherwise return 0.
/// In other words, test if all bits masked by `b` are 0 in `a`.
int _mm256_testz_si256 (__m256i a, __m256i b) @trusted
{
    // PERF DMD
    static if (GDC_with_AVX)
    {
        return __builtin_ia32_ptestz256(cast(long4)a, cast(long4)b);
    }
    else static if (LDC_with_AVX)
    {
        return __builtin_ia32_ptestz256(cast(long4)a, cast(long4)b);
    }
    else version(LDC)
    {
        // better to split than do vanilla (down to 8 inst in arm64)
        __m128i lo_a = _mm256_extractf128_si256!0(a);
        __m128i lo_b = _mm256_extractf128_si256!0(b);
        __m128i hi_a = _mm256_extractf128_si256!1(a);
        __m128i hi_b = _mm256_extractf128_si256!1(b);
        return _mm_testz_si128(lo_a, lo_b) & _mm_testz_si128(hi_a, hi_b);
    }
    else
    {
        __m256i c = a & b;
        long[4] zero = [0, 0, 0, 0];
        return c.array == zero;
    }
}
unittest
{
    __m256i A  = _mm256_setr_epi32(0x01, 0x02, 0x04, 0xf8, 0x01, 0x02, 0x04, 0xf8);
    __m256i M1 = _mm256_setr_epi32(0xfe, 0xfd, 0x00, 0x07, 0xfe, 0xfd, 0x00, 0x07);
    __m256i M2 = _mm256_setr_epi32(0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x04, 0x00);
    assert(_mm256_testz_si256(A, A) == 0);
    assert(_mm256_testz_si256(A, M1) == 1);
    assert(_mm256_testz_si256(A, M2) == 0);
}

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

/// Unpack and interleave double-precision (64-bit) floating-point elements from the high half of 
/// each 128-bit lane in `a` and `b`.
__m256d _mm256_unpackhi_pd (__m256d a, __m256d b) pure @trusted
{
    static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <4 x double> %0, <4 x double> %1, <4 x i32> <i32 1, i32 5, i32 3, i32 7>
                   ret <4 x double> %r`;
        return LDCInlineIR!(ir, double4, double4, double4)(a, b);
    }
    else static if (GDC_with_AVX)
    {
        return __builtin_ia32_unpckhpd256 (a, b);
    }
    else
    {
        __m256d r;
        r.ptr[0] = a.array[1];
        r.ptr[1] = b.array[1];
        r.ptr[2] = a.array[3];
        r.ptr[3] = b.array[3];
        return r;
    } 
}
unittest
{
    __m256d A = _mm256_setr_pd(1.0, 2, 3, 4);
    __m256d B = _mm256_setr_pd(5.0, 6, 7, 8);
    __m256d C = _mm256_unpackhi_pd(A, B);
    double[4] correct =       [2.0, 6, 4, 8];
    assert(C.array == correct);
}


/// Unpack and interleave double-precision (64-bit) floating-point elements from the high half of 
/// each 128-bit lane in `a` and `b`.
__m256 _mm256_unpackhi_ps (__m256 a, __m256 b) pure @trusted
{
    static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <8 x float> %0, <8 x float> %1, <8 x i32> <i32 2, i32 10, i32 3, i32 11, i32 6, i32 14, i32 7, i32 15>
            ret <8 x float> %r`;
        return LDCInlineIR!(ir, float8, float8, float8)(a, b);
    }
    else static if (GDC_with_AVX)
    {
        return __builtin_ia32_unpckhps256 (a, b);
    }
    else
    {
        __m256 r;
        r.ptr[0] = a.array[2];
        r.ptr[1] = b.array[2];
        r.ptr[2] = a.array[3];
        r.ptr[3] = b.array[3];
        r.ptr[4] = a.array[6];
        r.ptr[5] = b.array[6];
        r.ptr[6] = a.array[7];
        r.ptr[7] = b.array[7];
        return r;
    } 
}
unittest
{
    __m256 A = _mm256_setr_ps(0.0f,  1,  2,  3,  4,  5,  6,  7);
    __m256 B = _mm256_setr_ps(8.0f,  9, 10, 11, 12, 13, 14, 15);
    __m256 C = _mm256_unpackhi_ps(A, B);
    float[8] correct =       [2.0f, 10,  3, 11,  6, 14,  7, 15];
    assert(C.array == correct);
}

/// Unpack and interleave double-precision (64-bit) floating-point elements from the low half of 
/// each 128-bit lane in `a` and `b`.
__m256d _mm256_unpacklo_pd (__m256d a, __m256d b)
{
    static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <4 x double> %0, <4 x double> %1, <4 x i32> <i32 0, i32 4, i32 2, i32 6>
            ret <4 x double> %r`;
        return LDCInlineIR!(ir, double4, double4, double4)(a, b);
    }
    else static if (GDC_with_AVX)
    {
        return __builtin_ia32_unpcklpd256 (a, b);
    }
    else
    {
        __m256d r;
        r.ptr[0] = a.array[0];
        r.ptr[1] = b.array[0];
        r.ptr[2] = a.array[2];
        r.ptr[3] = b.array[2];
        return r;        
    } 
}
unittest
{
    __m256d A = _mm256_setr_pd(1.0, 2, 3, 4);
    __m256d B = _mm256_setr_pd(5.0, 6, 7, 8);
    __m256d C = _mm256_unpacklo_pd(A, B);
    double[4] correct =       [1.0, 5, 3, 7];
    assert(C.array == correct);
}

/// Unpack and interleave single-precision (32-bit) floating-point elements from the low half of
/// each 128-bit lane in `a` and `b`.
__m256 _mm256_unpacklo_ps (__m256 a, __m256 b)
{
    static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <8 x float> %0, <8 x float> %1, <8 x i32> <i32 0, i32 8, i32 1, i32 9, i32 4, i32 12, i32 5, i32 13>
            ret <8 x float> %r`;
        return LDCInlineIR!(ir, float8, float8, float8)(a, b);
    }
    else static if (GDC_with_AVX)
    {
        return __builtin_ia32_unpcklps256 (a, b);
    }
    else
    {
        __m256 r;
        r.ptr[0] = a.array[0];
        r.ptr[1] = b.array[0];
        r.ptr[2] = a.array[1];
        r.ptr[3] = b.array[1];
        r.ptr[4] = a.array[4];
        r.ptr[5] = b.array[4];
        r.ptr[6] = a.array[5];
        r.ptr[7] = b.array[5];
        return r;        
    } 
}
unittest
{
    __m256 A = _mm256_setr_ps(0.0f,  1,  2,  3,  4,  5,  6,  7);
    __m256 B = _mm256_setr_ps(8.0f,  9, 10, 11, 12, 13, 14, 15);
    __m256 C = _mm256_unpacklo_ps(A, B);
    float[8] correct =       [0.0f,  8,  1,  9,  4, 12,  5, 13];
    assert(C.array == correct);
}

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
    // PERF DMD needs to do it explicitely if AVX is ever used one day.

    static if (GDC_with_AVX)
    {
        __builtin_ia32_vzeroall();
    }
    else
    {
        // Do nothing. The transitions penalty are supposed handled by the backend (eg: LLVM).
    }
}

void _mm256_zeroupper () pure @safe
{
    // PERF DMD needs to do it explicitely if AVX is ever used.

    static if (GDC_with_AVX)
    {
        __builtin_ia32_vzeroupper();
    }
    else
    {
        // Do nothing. The transitions penalty are supposed handled by the backend (eg: LLVM).
    }
    
}

/// Cast vector of type `__m128d` to type `__m256d`; the upper 128 bits of the result are zeroed.
__m256d _mm256_zextpd128_pd256 (__m128d a) pure @trusted
{
    __m256d r;
    r.ptr[0] = a.array[0];
    r.ptr[1] = a.array[1];
    r.ptr[2] = 0;
    r.ptr[3] = 0;
    return r;
}
unittest
{
    __m256d R = _mm256_zextpd128_pd256(_mm_setr_pd(2.0, -3.0));
    double[4] correct = [2.0, -3, 0, 0];
    assert(R.array == correct);
}

/// Cast vector of type `__m128` to type `__m256`; the upper 128 bits of the result are zeroed.
__m256 _mm256_zextps128_ps256 (__m128 a) pure @trusted
{
    double2 la = cast(double2)a;
    double4 r;
    r.ptr[0] = la.array[0];
    r.ptr[1] = la.array[1];
    r.ptr[2] = 0;
    r.ptr[3] = 0;
    return cast(__m256)r;
}
unittest
{
    __m256 R = _mm256_zextps128_ps256(_mm_setr_ps(2.0, -3.0, 4, -5));
    float[8] correct = [2.0, -3, 4, -5, 0, 0, 0, 0];
    assert(R.array == correct);
}

/// Cast vector of type `__m128i` to type `__m256i`; the upper 128 bits of the result are zeroed. 
__m256i _mm256_zextsi128_si256 (__m128i a) pure @trusted
{
    long2 la = cast(long2)a;
    __m256i r;
    r.ptr[0] = la.array[0];
    r.ptr[1] = la.array[1];
    r.ptr[2] = 0;
    r.ptr[3] = 0;
    return r;
}
unittest
{
    __m256i R = _mm256_zextsi128_si256(_mm_setr_epi64(-1, 99));
    long[4] correct = [-1, 99, 0, 0];
    assert(R.array == correct);
}
