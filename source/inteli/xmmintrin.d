/**
* SSE intrinsics.
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=SSE
* 
* Copyright: Copyright Guillaume Piolat 2016-2020.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.xmmintrin;

public import inteli.types;

import inteli.internals;

import inteli.mmx;
import inteli.emmintrin;

import core.stdc.stdlib: malloc, free;
import core.stdc.string: memcpy;
import core.exception: onOutOfMemoryError;

version(D_InlineAsm_X86)
    version = InlineX86Asm;
else version(D_InlineAsm_X86_64)
    version = InlineX86Asm;


// SSE1

nothrow @nogc:


enum int _MM_EXCEPT_INVALID    = 0x0001; /// MXCSR Exception states.
enum int _MM_EXCEPT_DENORM     = 0x0002; ///ditto
enum int _MM_EXCEPT_DIV_ZERO   = 0x0004; ///ditto
enum int _MM_EXCEPT_OVERFLOW   = 0x0008; ///ditto
enum int _MM_EXCEPT_UNDERFLOW  = 0x0010; ///ditto
enum int _MM_EXCEPT_INEXACT    = 0x0020; ///ditto
enum int _MM_EXCEPT_MASK       = 0x003f; /// MXCSR Exception states mask.

enum int _MM_MASK_INVALID      = 0x0080; /// MXCSR Exception masks.
enum int _MM_MASK_DENORM       = 0x0100; ///ditto
enum int _MM_MASK_DIV_ZERO     = 0x0200; ///ditto
enum int _MM_MASK_OVERFLOW     = 0x0400; ///ditto
enum int _MM_MASK_UNDERFLOW    = 0x0800; ///ditto
enum int _MM_MASK_INEXACT      = 0x1000; ///ditto
enum int _MM_MASK_MASK         = 0x1f80; /// MXCSR Exception masks mask.

enum int _MM_ROUND_NEAREST     = 0x0000; /// MXCSR Rounding mode.
enum int _MM_ROUND_DOWN        = 0x2000; ///ditto
enum int _MM_ROUND_UP          = 0x4000; ///ditto
enum int _MM_ROUND_TOWARD_ZERO = 0x6000; ///ditto
enum int _MM_ROUND_MASK        = 0x6000; /// MXCSR Rounding mode mask.

enum int _MM_FLUSH_ZERO_MASK   = 0x8000; /// MXCSR Denormal flush to zero mask.
enum int _MM_FLUSH_ZERO_ON     = 0x8000; /// MXCSR Denormal flush to zero modes.
enum int _MM_FLUSH_ZERO_OFF    = 0x0000; ///ditto

/// Add packed single-precision (32-bit) floating-point elements in `a` and `b`.
__m128 _mm_add_ps(__m128 a, __m128 b) pure @safe
{
    pragma(inline, true);
    return a + b;
}
unittest
{
    __m128 a = [1, 2, 3, 4];
    a = _mm_add_ps(a, a);
    assert(a.array[0] == 2);
    assert(a.array[1] == 4);
    assert(a.array[2] == 6);
    assert(a.array[3] == 8);
}

/// Add the lower single-precision (32-bit) floating-point element 
/// in `a` and `b`, store the result in the lower element of result, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_add_ss(__m128 a, __m128 b) pure @safe
{
    static if (GDC_with_SSE)
    {
        return __builtin_ia32_addss(a, b);
    }
    else static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.ADDSS, a, b);
    }
    else
    {
        a[0] += b[0];
        return a;
    }
}
unittest
{
    __m128 a = [1, 2, 3, 4];
    a = _mm_add_ss(a, a);
    assert(a.array == [2.0f, 2, 3, 4]);
}

/// Compute the bitwise AND of packed single-precision (32-bit) floating-point elements in `a` and `b`.
__m128 _mm_and_ps (__m128 a, __m128 b) pure @safe
{
    pragma(inline, true);
    return cast(__m128)(cast(__m128i)a & cast(__m128i)b);
}
unittest
{
    float a = 4.32f;
    float b = -78.99f;
    int correct = (*cast(int*)(&a)) & (*cast(int*)(&b));
    __m128 A = _mm_set_ps(a, b, a, b);
    __m128 B = _mm_set_ps(b, a, b, a);
    int4 R = cast(int4)( _mm_and_ps(A, B) );
    assert(R.array[0] == correct);
    assert(R.array[1] == correct);
    assert(R.array[2] == correct);
    assert(R.array[3] == correct);
}

/// Compute the bitwise NOT of packed single-precision (32-bit) floating-point elements in `a` and then AND with `b`.
__m128 _mm_andnot_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.ANDNPS, a, b);
    else
        return cast(__m128)( (~cast(__m128i)a) & cast(__m128i)b );
}
unittest
{
    float a = 4.32f;
    float b = -78.99f;
    int correct  = ~(*cast(int*)(&a)) &  (*cast(int*)(&b));
    int correct2 =  (*cast(int*)(&a)) & ~(*cast(int*)(&b));
    __m128 A = _mm_set_ps(a, b, a, b);
    __m128 B = _mm_set_ps(b, a, b, a);
    int4 R = cast(int4)( _mm_andnot_ps(A, B) );
    assert(R.array[0] == correct2);
    assert(R.array[1] == correct);
    assert(R.array[2] == correct2);
    assert(R.array[3] == correct);
}

/// Average packed unsigned 16-bit integers in ``a` and `b`.
__m64 _mm_avg_pu16 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_avg_epu16(to_m128i(a), to_m128i(b)));
}

/// Average packed unsigned 8-bit integers in ``a` and `b`.
__m64 _mm_avg_pu8 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_avg_epu8(to_m128i(a), to_m128i(b)));
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for equality.
__m128 _mm_cmpeq_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, a, b, 0);
    else
        return cast(__m128) cmpps!(FPComparison.oeq)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, float.nan, float.nan);
    __m128i R = cast(__m128i) _mm_cmpeq_ps(A, B);
    int[4] correct = [0, -1, 0, 0];
    assert(R.array == correct);
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for equality, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmpeq_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPSS, a, b, 0);
    else
        return cast(__m128) cmpss!(FPComparison.oeq)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmpeq_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmpeq_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmpeq_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmpeq_ss(A, E);
    int[4] correct1 = [-1, 0, 0, 0];
    int[4] correct2 = [0, 0, 0, 0];
    int[4] correct3 = [0, 0, 0, 0];
    int[4] correct4 = [0, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for greater-than-or-equal.
__m128 _mm_cmpge_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, b, a, 2);
    else
        return cast(__m128) cmpps!(FPComparison.oge)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, 1.0f, float.nan);
    __m128i R = cast(__m128i) _mm_cmpge_ps(A, B);
    int[4] correct = [0, -1,-1, 0];
    assert(R.array == correct);
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for greater-than-or-equal, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmpge_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        __m128 c = cast(__m128) __simd(XMM.CMPSS, b, a, 2);
        a[0] = c[0];
        return a;
    }
    else
        return cast(__m128) cmpss!(FPComparison.oge)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmpge_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmpge_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmpge_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmpge_ss(A, E);
    int[4] correct1 = [-1, 0, 0, 0];
    int[4] correct2 = [-1, 0, 0, 0];
    int[4] correct3 = [0, 0, 0, 0];
    int[4] correct4 = [0, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for greater-than.
__m128 _mm_cmpgt_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, b, a, 1);
    else
        return cast(__m128) cmpps!(FPComparison.ogt)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, 1.0f, float.nan);
    __m128i R = cast(__m128i) _mm_cmpgt_ps(A, B);
    int[4] correct = [0, 0,-1, 0];
    assert(R.array == correct);
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for greater-than, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmpgt_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        __m128 c = cast(__m128) __simd(XMM.CMPSS, b, a, 1);
        a[0] = c[0];
        return a;
    }
    else
        return cast(__m128) cmpss!(FPComparison.ogt)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmpgt_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmpgt_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmpgt_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmpgt_ss(A, E);
    int[4] correct1 = [0, 0, 0, 0];
    int[4] correct2 = [-1, 0, 0, 0];
    int[4] correct3 = [0, 0, 0, 0];
    int[4] correct4 = [0, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for less-than-or-equal.
__m128 _mm_cmple_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, a, b, 2);
    else
        return cast(__m128) cmpps!(FPComparison.ole)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, 1.0f, float.nan);
    __m128i R = cast(__m128i) _mm_cmple_ps(A, B);
    int[4] correct = [-1, -1, 0, 0];
    assert(R.array == correct);
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for less-than-or-equal, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmple_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPSS, a, b, 2);
    else
        return cast(__m128) cmpss!(FPComparison.ole)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmple_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmple_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmple_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmple_ss(A, E);
    int[4] correct1 = [-1, 0, 0, 0];
    int[4] correct2 = [0, 0, 0, 0];
    int[4] correct3 = [0, 0, 0, 0];
    int[4] correct4 = [-1, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for less-than.
__m128 _mm_cmplt_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, a, b, 1);
    else
        return cast(__m128) cmpps!(FPComparison.olt)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, 1.0f, float.nan);
    __m128i R = cast(__m128i) _mm_cmplt_ps(A, B);
    int[4] correct = [-1, 0, 0, 0];
    assert(R.array == correct);
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for less-than, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmplt_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPSS, a, b, 1);
    else
        return cast(__m128) cmpss!(FPComparison.olt)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmplt_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmplt_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmplt_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmplt_ss(A, E);
    int[4] correct1 = [0, 0, 0, 0];
    int[4] correct2 = [0, 0, 0, 0];
    int[4] correct3 = [0, 0, 0, 0];
    int[4] correct4 = [-1, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for not-equal.
__m128 _mm_cmpneq_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, a, b, 4);
    else
        return cast(__m128) cmpps!(FPComparison.une)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, 1.0f, float.nan);
    __m128i R = cast(__m128i) _mm_cmpneq_ps(A, B);
    int[4] correct = [-1, 0, -1, -1];
    assert(R.array == correct);
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for not-equal, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmpneq_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPSS, a, b, 4);
    else
        return cast(__m128) cmpss!(FPComparison.une)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmpneq_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmpneq_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmpneq_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmpneq_ss(A, E);
    int[4] correct1 = [0, 0, 0, 0];
    int[4] correct2 = [-1, 0, 0, 0];
    int[4] correct3 = [-1, 0, 0, 0];
    int[4] correct4 = [-1, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for not-greater-than-or-equal.
__m128 _mm_cmpnge_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, b, a, 6);
    else
        return cast(__m128) cmpps!(FPComparison.ult)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, 1.0f, float.nan);
    __m128i R = cast(__m128i) _mm_cmpnge_ps(A, B);
    int[4] correct = [-1, 0, 0, -1];
    assert(R.array == correct);
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for not-greater-than-or-equal, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmpnge_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        __m128 c = cast(__m128) __simd(XMM.CMPSS, b, a, 6);
        a[0] = c[0];
        return a;
    }
    else
        return cast(__m128) cmpss!(FPComparison.ult)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmpnge_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmpnge_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmpnge_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmpnge_ss(A, E);
    int[4] correct1 = [0, 0, 0, 0];
    int[4] correct2 = [0, 0, 0, 0];
    int[4] correct3 = [-1, 0, 0, 0];
    int[4] correct4 = [-1, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for not-greater-than.
__m128 _mm_cmpngt_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, b, a, 5);
    else
        return cast(__m128) cmpps!(FPComparison.ule)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, 1.0f, float.nan);
    __m128i R = cast(__m128i) _mm_cmpngt_ps(A, B);
    int[4] correct = [-1, -1, 0, -1];
    assert(R.array == correct);
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for not-greater-than, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmpngt_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        __m128 c = cast(__m128) __simd(XMM.CMPSS, b, a, 5);
        a[0] = c[0];
        return a;
    }
    else
        return cast(__m128) cmpss!(FPComparison.ule)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmpngt_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmpngt_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmpngt_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmpngt_ss(A, E);
    int[4] correct1 = [-1, 0, 0, 0];
    int[4] correct2 = [0, 0, 0, 0];
    int[4] correct3 = [-1, 0, 0, 0];
    int[4] correct4 = [-1, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for not-less-than-or-equal.
__m128 _mm_cmpnle_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, a, b, 6);
    else
        return cast(__m128) cmpps!(FPComparison.ugt)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, 1.0f, float.nan);
    __m128i R = cast(__m128i) _mm_cmpnle_ps(A, B);
    int[4] correct = [0, 0, -1, -1];
    assert(R.array == correct);
}


/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for not-less-than-or-equal, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmpnle_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPSS, a, b, 6);
    else
        return cast(__m128) cmpss!(FPComparison.ugt)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmpnle_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmpnle_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmpnle_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmpnle_ss(A, E);
    int[4] correct1 = [0, 0, 0, 0];
    int[4] correct2 = [-1, 0, 0, 0];
    int[4] correct3 = [-1, 0, 0, 0];
    int[4] correct4 = [0, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` for not-less-than.
__m128 _mm_cmpnlt_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, a, b, 5);
    else
        return cast(__m128) cmpps!(FPComparison.uge)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, 1.0f, float.nan);
    __m128i R = cast(__m128i) _mm_cmpnlt_ps(A, B);
    int[4] correct = [0, -1, -1, -1];
    assert(R.array == correct);
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` for not-less-than, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmpnlt_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPSS, a, b, 5);
    else
        return cast(__m128) cmpss!(FPComparison.uge)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmpnlt_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmpnlt_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmpnlt_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmpnlt_ss(A, E);
    int[4] correct1 = [-1, 0, 0, 0];
    int[4] correct2 = [-1, 0, 0, 0];
    int[4] correct3 = [-1, 0, 0, 0];
    int[4] correct4 = [0, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` to see if neither is NaN.
__m128 _mm_cmpord_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, a, b, 7);
    else
        return cast(__m128) cmpps!(FPComparison.ord)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, 1.0f, float.nan);
    __m128i R = cast(__m128i) _mm_cmpord_ps(A, B);
    int[4] correct = [-1, -1, -1, 0];
    assert(R.array == correct);
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` to see if neither is NaN, 
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmpord_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPSS, a, b, 7);
    else
        return cast(__m128) cmpss!(FPComparison.ord)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmpord_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmpord_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmpord_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmpord_ss(A, E);
    int[4] correct1 = [-1, 0, 0, 0];
    int[4] correct2 = [-1, 0, 0, 0];
    int[4] correct3 = [0, 0, 0, 0];
    int[4] correct4 = [-1, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b` to see if either is NaN.
__m128 _mm_cmpunord_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPPS, a, b, 3);
    else
        return cast(__m128) cmpps!(FPComparison.uno)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, float.nan);
    __m128 B = _mm_setr_ps(3.0f, 2.0f, 1.0f, float.nan);
    __m128i R = cast(__m128i) _mm_cmpunord_ps(A, B);
    int[4] correct = [0, 0, 0, -1];
    assert(R.array == correct);
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b` to see if either is NaN.
/// and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_cmpunord_ss (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.CMPSS, a, b, 3);
    else return cast(__m128) cmpss!(FPComparison.uno)(a, b);
}
unittest
{
    __m128 A = _mm_setr_ps(3.0f, 0, 0, 0);
    __m128 B = _mm_setr_ps(3.0f, float.nan, float.nan, float.nan);
    __m128 C = _mm_setr_ps(2.0f, float.nan, float.nan, float.nan);
    __m128 D = _mm_setr_ps(float.nan, float.nan, float.nan, float.nan);
    __m128 E = _mm_setr_ps(4.0f, float.nan, float.nan, float.nan);
    __m128i R1 = cast(__m128i) _mm_cmpunord_ss(A, B);
    __m128i R2 = cast(__m128i) _mm_cmpunord_ss(A, C);
    __m128i R3 = cast(__m128i) _mm_cmpunord_ss(A, D);
    __m128i R4 = cast(__m128i) _mm_cmpunord_ss(A, E);
    int[4] correct1 = [0, 0, 0, 0];
    int[4] correct2 = [0, 0, 0, 0];
    int[4] correct3 = [-1, 0, 0, 0];
    int[4] correct4 = [0, 0, 0, 0];
    assert(R1.array == correct1 && R2.array == correct2 && R3.array == correct3 && R4.array == correct4);
}


/// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for equality, 
/// and return the boolean result (0 or 1).
int _mm_comieq_ss (__m128 a, __m128 b) pure @safe
{
    return a.array[0] == b.array[0];
}
unittest
{
    assert(1 == _mm_comieq_ss(_mm_set_ss(78.0f), _mm_set_ss(78.0f)));
    assert(0 == _mm_comieq_ss(_mm_set_ss(78.0f), _mm_set_ss(-78.0f)));
    assert(0 == _mm_comieq_ss(_mm_set_ss(78.0f), _mm_set_ss(float.nan)));
    assert(0 == _mm_comieq_ss(_mm_set_ss(float.nan), _mm_set_ss(-4.22f)));
    assert(1 == _mm_comieq_ss(_mm_set_ss(0.0), _mm_set_ss(-0.0)));
}

/// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for greater-than-or-equal, 
/// and return the boolean result (0 or 1).
int _mm_comige_ss (__m128 a, __m128 b) pure @safe
{
    return a.array[0] >= b.array[0];
}
unittest
{
    assert(1 == _mm_comige_ss(_mm_set_ss(78.0f), _mm_set_ss(78.0f)));
    assert(1 == _mm_comige_ss(_mm_set_ss(78.0f), _mm_set_ss(-78.0f)));
    assert(0 == _mm_comige_ss(_mm_set_ss(-78.0f), _mm_set_ss(78.0f)));
    assert(0 == _mm_comige_ss(_mm_set_ss(78.0f), _mm_set_ss(float.nan)));
    assert(0 == _mm_comige_ss(_mm_set_ss(float.nan), _mm_set_ss(-4.22f)));
    assert(1 == _mm_comige_ss(_mm_set_ss(-0.0f), _mm_set_ss(0.0f)));
}

/// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for greater-than, 
/// and return the boolean result (0 or 1).
int _mm_comigt_ss (__m128 a, __m128 b) pure @safe // comiss + seta
{
    return a.array[0] > b.array[0];
}
unittest
{
    assert(0 == _mm_comigt_ss(_mm_set_ss(78.0f), _mm_set_ss(78.0f)));
    assert(1 == _mm_comigt_ss(_mm_set_ss(78.0f), _mm_set_ss(-78.0f)));
    assert(0 == _mm_comigt_ss(_mm_set_ss(78.0f), _mm_set_ss(float.nan)));
    assert(0 == _mm_comigt_ss(_mm_set_ss(float.nan), _mm_set_ss(-4.22f)));
    assert(0 == _mm_comigt_ss(_mm_set_ss(0.0f), _mm_set_ss(-0.0f)));
}

/// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for less-than-or-equal, 
/// and return the boolean result (0 or 1).
int _mm_comile_ss (__m128 a, __m128 b) pure @safe // comiss + setbe
{
    return a.array[0] <= b.array[0];
}
unittest
{
    assert(1 == _mm_comile_ss(_mm_set_ss(78.0f), _mm_set_ss(78.0f)));
    assert(0 == _mm_comile_ss(_mm_set_ss(78.0f), _mm_set_ss(-78.0f)));
    assert(1 == _mm_comile_ss(_mm_set_ss(-78.0f), _mm_set_ss(78.0f)));
    assert(0 == _mm_comile_ss(_mm_set_ss(78.0f), _mm_set_ss(float.nan)));
    assert(0 == _mm_comile_ss(_mm_set_ss(float.nan), _mm_set_ss(-4.22f)));
    assert(1 == _mm_comile_ss(_mm_set_ss(0.0f), _mm_set_ss(-0.0f)));
}

/// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for less-than, 
/// and return the boolean result (0 or 1).
int _mm_comilt_ss (__m128 a, __m128 b) pure @safe // comiss + setb
{
    return a.array[0] < b.array[0];
}
unittest
{
    assert(0 == _mm_comilt_ss(_mm_set_ss(78.0f), _mm_set_ss(78.0f)));
    assert(0 == _mm_comilt_ss(_mm_set_ss(78.0f), _mm_set_ss(-78.0f)));
    assert(1 == _mm_comilt_ss(_mm_set_ss(-78.0f), _mm_set_ss(78.0f)));
    assert(0 == _mm_comilt_ss(_mm_set_ss(78.0f), _mm_set_ss(float.nan)));
    assert(0 == _mm_comilt_ss(_mm_set_ss(float.nan), _mm_set_ss(-4.22f)));
    assert(0 == _mm_comilt_ss(_mm_set_ss(-0.0f), _mm_set_ss(0.0f)));
}

/// Compare the lower single-precision (32-bit) floating-point element in `a` and `b` for not-equal, 
/// and return the boolean result (0 or 1).
int _mm_comineq_ss (__m128 a, __m128 b) pure @safe // comiss + setne
{
    return a.array[0] != b.array[0];
}
unittest
{
    assert(0 == _mm_comineq_ss(_mm_set_ss(78.0f), _mm_set_ss(78.0f)));
    assert(1 == _mm_comineq_ss(_mm_set_ss(78.0f), _mm_set_ss(-78.0f)));
    assert(1 == _mm_comineq_ss(_mm_set_ss(78.0f), _mm_set_ss(float.nan)));
    assert(1 == _mm_comineq_ss(_mm_set_ss(float.nan), _mm_set_ss(-4.22f)));
    assert(0 == _mm_comineq_ss(_mm_set_ss(0.0f), _mm_set_ss(-0.0f)));
}

/// Convert packed signed 32-bit integers in `b` to packed single-precision (32-bit) 
/// floating-point elements, store the results in the lower 2 elements, 
/// and copy the upper 2 packed elements from `a` to the upper elements of result.
alias _mm_cvt_pi2ps = _mm_cvtpi32_ps;

/// Convert 2 lower packed single-precision (32-bit) floating-point elements in `a` 
/// to packed 32-bit integers.
__m64 _mm_cvt_ps2pi (__m128 a) @safe
{
    return to_m64(_mm_cvtps_epi32(a));
}

/// Convert the signed 32-bit integer `b` to a single-precision (32-bit) floating-point element, 
/// store the result in the lower element, and copy the upper 3 packed elements from `a` to the 
/// upper elements of the result.
__m128 _mm_cvt_si2ss (__m128 v, int x) pure @trusted
{
    v.ptr[0] = cast(float)x;
    return v;
}
unittest
{
    __m128 a = _mm_cvt_si2ss(_mm_set1_ps(0.0f), 42);
    assert(a.array == [42f, 0, 0, 0]);
}

/// Convert packed 16-bit integers in `a` to packed single-precision (32-bit) floating-point elements.
__m128 _mm_cvtpi16_ps (__m64 a) pure @safe
{
    __m128i ma = to_m128i(a);
    ma = _mm_unpacklo_epi16(ma, _mm_setzero_si128()); // Zero-extend to 32-bit
    ma = _mm_srai_epi32(_mm_slli_epi32(ma, 16), 16); // Replicate sign bit
    return _mm_cvtepi32_ps(ma);
}
unittest
{
    __m64 A = _mm_setr_pi16(-1, 2, -3, 4);
    __m128 R = _mm_cvtpi16_ps(A);
    float[4] correct = [-1.0f, 2.0f, -3.0f, 4.0f];
    assert(R.array == correct);
}

/// Convert packed signed 32-bit integers in `b` to packed single-precision (32-bit) 
/// floating-point elements, store the results in the lower 2 elements, 
/// and copy the upper 2 packed elements from `a` to the upper elements of result.
__m128 _mm_cvtpi32_ps (__m128 a, __m64 b) pure @trusted
{
    __m128 fb = _mm_cvtepi32_ps(to_m128i(b));
    a.ptr[0] = fb.array[0];
    a.ptr[1] = fb.array[1];
    return a;
}
unittest
{
    __m128 R = _mm_cvtpi32_ps(_mm_set1_ps(4.0f), _mm_setr_pi32(1, 2));
    float[4] correct = [1.0f, 2.0f, 4.0f, 4.0f];
    assert(R.array == correct);
}

/// Convert packed signed 32-bit integers in `a` to packed single-precision (32-bit) floating-point elements, 
/// store the results in the lower 2 elements, then covert the packed signed 32-bit integers in `b` to 
/// single-precision (32-bit) floating-point element, and store the results in the upper 2 elements.
__m128 _mm_cvtpi32x2_ps (__m64 a, __m64 b) pure @trusted
{
    long2 l;
    l.ptr[0] = a.array[0];
    l.ptr[1] = b.array[0];
    return _mm_cvtepi32_ps(cast(__m128i)l);
}
unittest
{
    __m64 A = _mm_setr_pi32(-45, 128);
    __m64 B = _mm_setr_pi32(0, 1000);
    __m128 R = _mm_cvtpi32x2_ps(A, B);
    float[4] correct = [-45.0f, 128.0f, 0.0f, 1000.0f];
    assert(R.array == correct);
}

/// Convert the lower packed 8-bit integers in `a` to packed single-precision (32-bit) floating-point elements.
__m128 _mm_cvtpi8_ps (__m64 a) pure @safe
{
    __m128i b = to_m128i(a); 

    // Zero extend to 32-bit
    b = _mm_unpacklo_epi8(b, _mm_setzero_si128());
    b = _mm_unpacklo_epi16(b, _mm_setzero_si128());

    // Replicate sign bit
    b = _mm_srai_epi32(_mm_slli_epi32(b, 24), 24); // Replicate sign bit
    return _mm_cvtepi32_ps(b);
}
unittest
{
    __m64 A = _mm_setr_pi8(-1, 2, -3, 4, 0, 0, 0, 0);
    __m128 R = _mm_cvtpi8_ps(A);
    float[4] correct = [-1.0f, 2.0f, -3.0f, 4.0f];
    assert(R.array == correct);
}

/// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 16-bit integers.
/// Note: this intrinsic will generate 0x7FFF, rather than 0x8000, for input values between 0x7FFF and 0x7FFFFFFF.
__m64 _mm_cvtps_pi16 (__m128 a) @safe
{
    // The C++ version of this intrinsic convert to 32-bit float, then use packssdw
    // Which means the 16-bit integers should be saturated
    __m128i b = _mm_cvtps_epi32(a);
    b = _mm_packs_epi32(b, b);
    return to_m64(b);
}
unittest
{
    __m128 A = _mm_setr_ps(-1.0f, 2.0f, -33000.0f, 70000.0f);
    short4 R = cast(short4) _mm_cvtps_pi16(A);
    short[4] correct = [-1, 2, -32768, 32767];
    assert(R.array == correct);
}

/// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers.
__m64 _mm_cvtps_pi32 (__m128 a) @safe
{
    return to_m64(_mm_cvtps_epi32(a));
}
unittest
{
    __m128 A = _mm_setr_ps(-33000.0f, 70000.0f, -1.0f, 2.0f, );
    int2 R = cast(int2) _mm_cvtps_pi32(A);
    int[2] correct = [-33000, 70000];
    assert(R.array == correct);
}

/// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 8-bit integers, 
/// and store the results in lower 4 elements. 
/// Note: this intrinsic will generate 0x7F, rather than 0x80, for input values between 0x7F and 0x7FFFFFFF.
__m64 _mm_cvtps_pi8 (__m128 a) @safe
{
    // The C++ version of this intrinsic convert to 32-bit float, then use packssdw + packsswb
    // Which means the 8-bit integers should be saturated
    __m128i b = _mm_cvtps_epi32(a);
    b = _mm_packs_epi32(b, _mm_setzero_si128());
    b = _mm_packs_epi16(b, _mm_setzero_si128());
    return to_m64(b);
}
unittest
{
    __m128 A = _mm_setr_ps(-1.0f, 2.0f, -129.0f, 128.0f);
    byte8 R = cast(byte8) _mm_cvtps_pi8(A);
    byte[8] correct = [-1, 2, -128, 127, 0, 0, 0, 0];
    assert(R.array == correct);
}

/// Convert packed unsigned 16-bit integers in `a` to packed single-precision (32-bit) floating-point elements.
__m128 _mm_cvtpu16_ps (__m64 a) pure @safe
{
    __m128i ma = to_m128i(a);
    ma = _mm_unpacklo_epi16(ma, _mm_setzero_si128()); // Zero-extend to 32-bit
    return _mm_cvtepi32_ps(ma);
}
unittest
{
    __m64 A = _mm_setr_pi16(-1, 2, -3, 4);
    __m128 R = _mm_cvtpu16_ps(A);
    float[4] correct = [65535.0f, 2.0f, 65533.0f, 4.0f];
    assert(R.array == correct);
}

/// Convert the lower packed unsigned 8-bit integers in `a` to packed single-precision (32-bit) floating-point element.
__m128 _mm_cvtpu8_ps (__m64 a) pure @safe
{
    __m128i b = to_m128i(a); 

    // Zero extend to 32-bit
    b = _mm_unpacklo_epi8(b, _mm_setzero_si128());
    b = _mm_unpacklo_epi16(b, _mm_setzero_si128());
    return _mm_cvtepi32_ps(b);
}
unittest
{
    __m64 A = _mm_setr_pi8(-1, 2, -3, 4, 0, 0, 0, 0);
    __m128 R = _mm_cvtpu8_ps(A);
    float[4] correct = [255.0f, 2.0f, 253.0f, 4.0f];
    assert(R.array == correct);
}

/// Convert the signed 32-bit integer `b` to a single-precision (32-bit) floating-point element, 
/// store the result in the lower element, and copy the upper 3 packed elements from `a` to the 
/// upper elements of result.
__m128 _mm_cvtsi32_ss(__m128 v, int x) pure @trusted
{
    v.ptr[0] = cast(float)x;
    return v;
}
unittest
{
    __m128 a = _mm_cvtsi32_ss(_mm_set1_ps(0.0f), 42);
    assert(a.array == [42.0f, 0, 0, 0]);
}


/// Convert the signed 64-bit integer `b` to a single-precision (32-bit) floating-point element, 
/// store the result in the lower element, and copy the upper 3 packed elements from `a` to the 
/// upper elements of result.
__m128 _mm_cvtsi64_ss(__m128 v, long x) pure @trusted
{
    v.ptr[0] = cast(float)x;
    return v;
}
unittest
{
    __m128 a = _mm_cvtsi64_ss(_mm_set1_ps(0.0f), 42);
    assert(a.array == [42.0f, 0, 0, 0]);
}

/// Take the lower single-precision (32-bit) floating-point element of `a`.
float _mm_cvtss_f32(__m128 a) pure @safe
{
    return a.array[0];
}

/// Convert the lower single-precision (32-bit) floating-point element in `a` to a 32-bit integer.
int _mm_cvtss_si32 (__m128 a) @safe // PERF GDC
{
    static if (GDC_with_SSE)
    {
        return __builtin_ia32_cvtss2si(a);
    }
    else static if (LDC_with_SSE)
    {
        return __builtin_ia32_cvtss2si(a);
    }
    else static if (DMD_with_DSIMD)
    {
        __m128 b;
        __m128i r = cast(__m128i) __simd(XMM.CVTPS2DQ, a); // Note: converts 4 integers.
        return r.array[0];
    }
    else
    {
        return convertFloatToInt32UsingMXCSR(a.array[0]);
    }
}
unittest
{
    assert(1 == _mm_cvtss_si32(_mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f)));
}

/// Convert the lower single-precision (32-bit) floating-point element in `a` to a 64-bit integer.
long _mm_cvtss_si64 (__m128 a) @safe
{
    static if (LDC_with_SSE2)
    {
        version(X86_64)
        {
            return __builtin_ia32_cvtss2si64(a);
        }
        else
        {
            // Note: In 32-bit x86, there is no way to convert from float/double to 64-bit integer
            // using SSE instructions only. So the builtin doesn't exit for this arch.
            return convertFloatToInt64UsingMXCSR(a.array[0]);
        }
    }
    else
    {
        return convertFloatToInt64UsingMXCSR(a.array[0]);
    }
}
unittest
{
    assert(1 == _mm_cvtss_si64(_mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f)));

    uint savedRounding = _MM_GET_ROUNDING_MODE();

    _MM_SET_ROUNDING_MODE(_MM_ROUND_NEAREST);
    assert(-86186 == _mm_cvtss_si64(_mm_set1_ps(-86186.49f)));

    _MM_SET_ROUNDING_MODE(_MM_ROUND_DOWN);
    assert(-86187 == _mm_cvtss_si64(_mm_set1_ps(-86186.1f)));

    _MM_SET_ROUNDING_MODE(_MM_ROUND_UP);
    assert(86187 == _mm_cvtss_si64(_mm_set1_ps(86186.1f)));

    _MM_SET_ROUNDING_MODE(_MM_ROUND_TOWARD_ZERO);
    assert(-86186 == _mm_cvtss_si64(_mm_set1_ps(-86186.9f)));

    _MM_SET_ROUNDING_MODE(savedRounding);
}


/// Convert the lower single-precision (32-bit) floating-point element in `a` to a 32-bit 
/// integer with truncation.
int _mm_cvtt_ss2si (__m128 a) pure @safe
{
    // x86: cvttss2si always generated, even in -O0
    return cast(int)(a.array[0]);
}
alias _mm_cvttss_si32 = _mm_cvtt_ss2si; ///ditto
unittest
{
    assert(1 == _mm_cvtt_ss2si(_mm_setr_ps(1.9f, 2.0f, 3.0f, 4.0f)));
}


/// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit 
/// integers with truncation.
__m64 _mm_cvtt_ps2pi (__m128 a) pure @safe
{
    return to_m64(_mm_cvttps_epi32(a));
}

/// Convert the lower single-precision (32-bit) floating-point element in `a` to a 64-bit 
/// integer with truncation.
long _mm_cvttss_si64 (__m128 a) pure @safe
{
    return cast(long)(a.array[0]);
}
unittest
{
    assert(1 == _mm_cvttss_si64(_mm_setr_ps(1.9f, 2.0f, 3.0f, 4.0f)));
}

/// Divide packed single-precision (32-bit) floating-point elements in `a` by packed elements in `b`.
__m128 _mm_div_ps(__m128 a, __m128 b) pure @safe
{
    pragma(inline, true);
    return a / b;
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_div_ps(a, a);
    float[4] correct = [1.0f, 1.0f, 1.0f, 1.0f];
    assert(a.array == correct);
}

/// Divide the lower single-precision (32-bit) floating-point element in `a` by the lower 
/// single-precision (32-bit) floating-point element in `b`, store the result in the lower 
/// element of result, and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_div_ss(__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.DIVSS, a, b);
    else static if (GDC_with_SSE)
        return __builtin_ia32_divss(a, b);
    else
    {
        a[0] /= b[0];
        return a;
    }
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_div_ss(a, a);
    float[4] correct = [1.0f, -2.0, 3.0f, 1.0f];
    assert(a.array == correct);
}

/// Extract a 16-bit unsigned integer from `a`, selected with `imm8`. Zero-extended.
int _mm_extract_pi16 (__m64 a, int imm8)
{
    short4 sa = cast(short4)a;
    return cast(ushort)(sa.array[imm8]);
}
unittest
{
    __m64 A = _mm_setr_pi16(-1, 6, 0, 4);
    assert(_mm_extract_pi16(A, 0) == 65535);
    assert(_mm_extract_pi16(A, 1) == 6);
    assert(_mm_extract_pi16(A, 2) == 0);
    assert(_mm_extract_pi16(A, 3) == 4);
}

/// Free aligned memory that was allocated with `_mm_malloc` or `_mm_realloc`.
void _mm_free(void * mem_addr) @trusted
{
    // support for free(NULL)
    if (mem_addr is null)
        return;

    // Technically we don't need to store size and alignement in the chunk, but we do in case we
    // have to implement _mm_realloc

    size_t pointerSize = (void*).sizeof;
    void** rawLocation = cast(void**)(cast(char*)mem_addr - size_t.sizeof);
    size_t* alignmentLocation = cast(size_t*)(cast(char*)mem_addr - 3 * pointerSize);
    size_t alignment = *alignmentLocation;
    assert(alignment != 0);
    assert(isPointerAligned(mem_addr, alignment));
    free(*rawLocation);
}

/// Get the exception mask bits from the MXCSR control and status register. 
/// The exception mask may contain any of the following flags: `_MM_MASK_INVALID`, 
/// `_MM_MASK_DIV_ZERO`, `_MM_MASK_DENORM`, `_MM_MASK_OVERFLOW`, `_MM_MASK_UNDERFLOW`, `_MM_MASK_INEXACT`.
/// Note: won't correspond to reality on non-x86, where MXCSR this is emulated.
uint _MM_GET_EXCEPTION_MASK() @safe
{
    return _mm_getcsr() & _MM_MASK_MASK;
}

/// Get the exception state bits from the MXCSR control and status register. 
/// The exception state may contain any of the following flags: `_MM_EXCEPT_INVALID`, 
/// `_MM_EXCEPT_DIV_ZERO`, `_MM_EXCEPT_DENORM`, `_MM_EXCEPT_OVERFLOW`, `_MM_EXCEPT_UNDERFLOW`, `_MM_EXCEPT_INEXACT`.
/// Note: won't correspond to reality on non-x86, where MXCSR this is emulated. No exception reported.
uint _MM_GET_EXCEPTION_STATE() @safe
{
    return _mm_getcsr() & _MM_EXCEPT_MASK;
}

/// Get the flush zero bits from the MXCSR control and status register. 
/// The flush zero may contain any of the following flags: `_MM_FLUSH_ZERO_ON` or `_MM_FLUSH_ZERO_OFF`
uint _MM_GET_FLUSH_ZERO_MODE() @safe
{
    return _mm_getcsr() & _MM_FLUSH_ZERO_MASK;
}

/// Get the rounding mode bits from the MXCSR control and status register. The rounding mode may 
/// contain any of the following flags: `_MM_ROUND_NEAREST, `_MM_ROUND_DOWN`, `_MM_ROUND_UP`, `_MM_ROUND_TOWARD_ZERO`.
uint _MM_GET_ROUNDING_MODE() @safe
{
    return _mm_getcsr() & _MM_ROUND_MASK;
}

/// Get the unsigned 32-bit value of the MXCSR control and status register.
/// Note: this is emulated on ARM, because there is no MXCSR register then.
uint _mm_getcsr() @trusted
{
    static if (LDC_with_ARM)
    {
        // Note: we convert the ARM FPSCR into a x86 SSE control word.
        // However, only rounding mode and flush to zero are actually set.
        // The returned control word will have all exceptions masked, and no exception detected.

        uint fpscr = arm_get_fpcr();

        uint cw = 0; // No exception detected
        if (fpscr & _MM_FLUSH_ZERO_MASK_ARM)
        {
            // ARM has one single flag for ARM.
            // It does both x86 bits.
            // https://developer.arm.com/documentation/dui0473/c/neon-and-vfp-programming/the-effects-of-using-flush-to-zero-mode
            cw |= _MM_FLUSH_ZERO_ON;
            cw |= 0x40; // set "denormals are zeros"
        } 
        cw |= _MM_MASK_MASK; // All exception maske

        // Rounding mode
        switch(fpscr & _MM_ROUND_MASK_ARM)
        {
            default:
            case _MM_ROUND_NEAREST_ARM:     cw |= _MM_ROUND_NEAREST;     break;
            case _MM_ROUND_DOWN_ARM:        cw |= _MM_ROUND_DOWN;        break;
            case _MM_ROUND_UP_ARM:          cw |= _MM_ROUND_UP;          break;
            case _MM_ROUND_TOWARD_ZERO_ARM: cw |= _MM_ROUND_TOWARD_ZERO; break;
        }
        return cw;
    }
    else version(GNU)
    {
        static if (GDC_with_SSE)
        {
            return __builtin_ia32_stmxcsr();
        }
        else version(X86)
        {
            uint sseRounding = 0;
            asm pure nothrow @nogc @trusted
            {
                "stmxcsr %0;\n" 
                  : "=m" (sseRounding)
                  : 
                  : ;
            }
            return sseRounding;
        }
        else
            static assert(false);
    }
    else version (InlineX86Asm)
    {
        uint controlWord;
        asm nothrow @nogc pure @safe
        {
            stmxcsr controlWord;
        }
        return controlWord;
    }
    else
        static assert(0, "Not yet supported");
}
unittest
{
    uint csr = _mm_getcsr();
}

/// Insert a 16-bit integer `i` inside `a` at the location specified by `imm8`.
__m64 _mm_insert_pi16 (__m64 v, int i, int imm8) pure @trusted
{
    short4 r = cast(short4)v;
    r.ptr[imm8 & 3] = cast(short)i;
    return cast(__m64)r;
}
unittest
{
    __m64 A = _mm_set_pi16(3, 2, 1, 0);
    short4 R = cast(short4) _mm_insert_pi16(A, 42, 1 | 4);
    short[4] correct = [0, 42, 2, 3];
    assert(R.array == correct);
}

/// Load 128-bits (composed of 4 packed single-precision (32-bit) floating-point elements) from memory.
//  `p` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
__m128 _mm_load_ps(const(float)*p) pure @trusted // FUTURE shouldn't be trusted, see #62
{
    pragma(inline, true);
    return *cast(__m128*)p;
}
unittest
{
    static immutable align(16) float[4] correct = [1.0f, 2.0f, 3.0f, 4.0f];
    __m128 A = _mm_load_ps(correct.ptr);
    assert(A.array == correct);
}

/// Load a single-precision (32-bit) floating-point element from memory into all elements.
__m128 _mm_load_ps1(const(float)*p) pure @trusted
{
    return __m128(*p);
}
unittest
{
    float n = 2.5f;
    float[4] correct = [2.5f, 2.5f, 2.5f, 2.5f];
    __m128 A = _mm_load_ps1(&n);
    assert(A.array == correct);
}

/// Load a single-precision (32-bit) floating-point element from memory into the lower of dst, and zero the upper 3 
/// elements. `mem_addr` does not need to be aligned on any particular boundary.
__m128 _mm_load_ss (const(float)* mem_addr) pure @trusted
{
    pragma(inline, true);
    static if (DMD_with_DSIMD)
    {
        return cast(__m128)__simd(XMM.LODSS, *cast(__m128*)mem_addr);
    }
    else
    {
        __m128 r; // PERf =void;
        r.ptr[0] = *mem_addr;
        r.ptr[1] = 0;
        r.ptr[2] = 0;
        r.ptr[3] = 0;
        return r;
    }
}
unittest
{
    float n = 2.5f;
    float[4] correct = [2.5f, 0.0f, 0.0f, 0.0f];
    __m128 A = _mm_load_ss(&n);
    assert(A.array == correct);
}

/// Load a single-precision (32-bit) floating-point element from memory into all elements.
alias _mm_load1_ps = _mm_load_ps1;

/// Load 2 single-precision (32-bit) floating-point elements from memory into the upper 2 elements of result, 
/// and copy the lower 2 elements from `a` to result. `mem_addr does` not need to be aligned on any particular boundary.
__m128 _mm_loadh_pi (__m128 a, const(__m64)* mem_addr) pure @trusted
{
    pragma(inline, true);
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.LODHPS, a, *cast(const(__m128)*)mem_addr); 
    }
    else
    {
        // x86: movlhps generated since LDC 1.9.0 -O1
        long2 la = cast(long2)a;
        la.ptr[1] = (*mem_addr).array[0];
        return cast(__m128)la;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    __m128 B = _mm_setr_ps(5.0f, 6.0f, 7.0f, 8.0f);
    __m64 M = to_m64(cast(__m128i)B);
     __m128 R = _mm_loadh_pi(A, &M);
    float[4] correct = [1.0f, 2.0f, 5.0f, 6.0f];
    assert(R.array == correct);
}

/// Load 2 single-precision (32-bit) floating-point elements from memory into the lower 2 elements of result, 
/// and copy the upper 2 elements from `a` to result. `mem_addr` does not need to be aligned on any particular boundary.
__m128 _mm_loadl_pi (__m128 a, const(__m64)* mem_addr) pure @trusted
{
    pragma(inline, true);

    // Disabled because of https://issues.dlang.org/show_bug.cgi?id=23046
    /*
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.LODLPS, a, *cast(const(__m128)*)mem_addr); 
    }
    else */
    {
        // x86: movlpd/movlps generated with all LDC -01
        long2 la = cast(long2)a;
        la.ptr[0] = (*mem_addr).array[0];
        return cast(__m128)la;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    __m128 B = _mm_setr_ps(5.0f, 6.0f, 7.0f, 8.0f);
    __m64 M = to_m64(cast(__m128i)B);
     __m128 R = _mm_loadl_pi(A, &M);
    float[4] correct = [5.0f, 6.0f, 3.0f, 4.0f];
    assert(R.array == correct);
}

/// Load 4 single-precision (32-bit) floating-point elements from memory in reverse order. 
/// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
__m128 _mm_loadr_ps (const(float)* mem_addr) pure @trusted // FUTURE shouldn't be trusted, see #62
{
    __m128* aligned = cast(__m128*)mem_addr; // x86: movaps + shups since LDC 1.0.0 -O1
    __m128 a = *aligned;
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.SHUFPS, a, a, 27);
    }
    else
    {
        __m128 r; // PERF =void;
        r.ptr[0] = a.array[3];
        r.ptr[1] = a.array[2];
        r.ptr[2] = a.array[1];
        r.ptr[3] = a.array[0];
        return r;
    }
}
unittest
{
    align(16) static immutable float[4] arr = [ 1.0f, 2.0f, 3.0f, 8.0f ];
    __m128 A = _mm_loadr_ps(arr.ptr);
    float[4] correct = [ 8.0f, 3.0f, 2.0f, 1.0f ];
    assert(A.array == correct);
}

/// Load 128-bits (composed of 4 packed single-precision (32-bit) floating-point elements) from memory. 
/// `mem_addr` does not need to be aligned on any particular boundary.
__m128 _mm_loadu_ps(const(float)* mem_addr) pure @trusted
{
    pragma(inline, true);
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_loadups(mem_addr);
    }
    else static if (LDC_with_optimizations)
    {
        static if (LDC_with_optimizations)
        {
            return loadUnaligned!(__m128)(mem_addr);
        }
        else
        {
            __m128 result;
            result.ptr[0] = mem_addr[0];
            result.ptr[1] = mem_addr[1];
            result.ptr[2] = mem_addr[2];
            result.ptr[3] = mem_addr[3];
            return result;
        }
    }
    else version(DigitalMars)
    {
        static if (DMD_with_DSIMD)
        {
            return cast(__m128)__simd(XMM.LODUPS, *cast(const(float4*))mem_addr);
        }
        else static if (SSESizedVectorsAreEmulated)
        {
            // Since this vector is emulated, it doesn't have alignement constraints
            // and as such we can just cast it.
            return *cast(__m128*)(mem_addr);
        }
        else
        {
            __m128 result;
            result.ptr[0] = mem_addr[0];
            result.ptr[1] = mem_addr[1];
            result.ptr[2] = mem_addr[2];
            result.ptr[3] = mem_addr[3];
            return result;
        }
    }
    else
    {
        __m128 result;
        result.ptr[0] = mem_addr[0];
        result.ptr[1] = mem_addr[1];
        result.ptr[2] = mem_addr[2];
        result.ptr[3] = mem_addr[3];
        return result;
    }
}
unittest
{
    align(16) static immutable float[5] arr = [ 1.0f, 2.0f, 3.0f, 8.0f, 9.0f ];  // force unaligned load
    __m128 A = _mm_loadu_ps(&arr[1]);
    float[4] correct = [ 2.0f, 3.0f, 8.0f, 9.0f ];
    assert(A.array == correct);
}

/// Allocate size bytes of memory, aligned to the alignment specified in align,
/// and return a pointer to the allocated memory. `_mm_free` should be used to free
/// memory that is allocated with `_mm_malloc`.
void* _mm_malloc(size_t size, size_t alignment) @trusted
{
    assert(alignment != 0);
    size_t request = requestedSize(size, alignment);
    void* raw = malloc(request);
    if (request > 0 && raw == null) // malloc(0) can validly return anything
        onOutOfMemoryError();
    return storeRawPointerPlusInfo(raw, size, alignment); // PERF: no need to store size
}

/// Conditionally store 8-bit integer elements from a into memory using mask (elements are not stored when the highest 
/// bit is not set in the corresponding element) and a non-temporal memory hint.
void _mm_maskmove_si64 (__m64 a, __m64 mask, char* mem_addr) @trusted
{
    // this works since mask is zero-extended
    return _mm_maskmoveu_si128 (to_m128i(a), to_m128i(mask), mem_addr);
}

deprecated("Use _mm_maskmove_si64 instead") alias _m_maskmovq = _mm_maskmove_si64;///

/// Compare packed signed 16-bit integers in `a` and `b`, and return packed maximum value.
__m64 _mm_max_pi16 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_max_epi16(to_m128i(a), to_m128i(b)));
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`, and return packed maximum values.
__m128 _mm_max_ps(__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.MAXPS, a, b);
    }
    else static if (GDC_with_SSE)
    {
        return __builtin_ia32_maxps(a, b);
    }
    else static if (LDC_with_SSE)
    {
        return __builtin_ia32_maxps(a, b);
    }
    else
    {
        // ARM: Optimized into fcmgt + bsl since LDC 1.8 -02
        __m128 r; // PERF =void;
        r[0] = (a[0] > b[0]) ? a[0] : b[0];
        r[1] = (a[1] > b[1]) ? a[1] : b[1];
        r[2] = (a[2] > b[2]) ? a[2] : b[2];
        r[3] = (a[3] > b[3]) ? a[3] : b[3];
        return r;    
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1, 2, float.nan, 4);
    __m128 B = _mm_setr_ps(4, 1, 4, float.nan);
    __m128 M = _mm_max_ps(A, B);
    assert(M.array[0] == 4);
    assert(M.array[1] == 2);
    assert(M.array[2] == 4);    // in case of NaN, second operand prevails (as it seems)
    assert(M.array[3] != M.array[3]); // in case of NaN, second operand prevails (as it seems)
}

/// Compare packed unsigned 8-bit integers in `a` and `b`, and return packed maximum values.
__m64 _mm_max_pu8 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_max_epu8(to_m128i(a), to_m128i(b)));
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b`, store the maximum value in the 
/// lower element of result, and copy the upper 3 packed elements from `a` to the upper element of result.
 __m128 _mm_max_ss(__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.MAXSS, a, b);
    }
    else static if (GDC_with_SSE)
    {
        return __builtin_ia32_maxss(a, b);
    }
    else static if (LDC_with_SSE)
    {
        return __builtin_ia32_maxss(a, b); 
    }
    else
    {  
        __m128 r = a;
        r[0] = (a[0] > b[0]) ? a[0] : b[0];
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1, 2, 3, 4);
    __m128 B = _mm_setr_ps(4, 1, 4, 1);
    __m128 C = _mm_setr_ps(float.nan, 1, 4, 1);
    __m128 M = _mm_max_ss(A, B);
    assert(M.array[0] == 4);
    assert(M.array[1] == 2);
    assert(M.array[2] == 3);
    assert(M.array[3] == 4);
    M = _mm_max_ps(A, C); // in case of NaN, second operand prevails
    assert(M.array[0] != M.array[0]);
    M = _mm_max_ps(C, A); // in case of NaN, second operand prevails
    assert(M.array[0] == 1);
}

/// Compare packed signed 16-bit integers in a and b, and return packed minimum values.
__m64 _mm_min_pi16 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_min_epi16(to_m128i(a), to_m128i(b)));
}

/// Compare packed single-precision (32-bit) floating-point elements in `a` and `b`, and return packed maximum values.
__m128 _mm_min_ps(__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.MINPS, a, b);
    }
    else static if (GDC_with_SSE)
    {
        return __builtin_ia32_minps(a, b);
    }
    else static if (LDC_with_SSE)
    {
        // not technically needed, but better perf in debug mode
        return __builtin_ia32_minps(a, b);
    }
    else
    {
        // ARM: Optimized into fcmgt + bsl since LDC 1.8 -02
        __m128 r; // PERF =void;
        r[0] = (a[0] < b[0]) ? a[0] : b[0];
        r[1] = (a[1] < b[1]) ? a[1] : b[1];
        r[2] = (a[2] < b[2]) ? a[2] : b[2];
        r[3] = (a[3] < b[3]) ? a[3] : b[3];
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1, 2, float.nan, 4);
    __m128 B = _mm_setr_ps(4, 1, 4, float.nan);
    __m128 M = _mm_min_ps(A, B);
    assert(M.array[0] == 1);
    assert(M.array[1] == 1);
    assert(M.array[2] == 4);    // in case of NaN, second operand prevails (as it seems)
    assert(M.array[3] != M.array[3]); // in case of NaN, second operand prevails (as it seems)
}

/// Compare packed unsigned 8-bit integers in `a` and `b`, and return packed minimum values.
__m64 _mm_min_pu8 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_min_epu8(to_m128i(a), to_m128i(b)));
}

/// Compare the lower single-precision (32-bit) floating-point elements in `a` and `b`, store the minimum value in the 
/// lower element of result, and copy the upper 3 packed elements from `a` to the upper element of result.
__m128 _mm_min_ss(__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.MINSS, a, b);
    }
    else static if (GDC_with_SSE)
    {
        return __builtin_ia32_minss(a, b);
    }
    else static if (LDC_with_SSE)
    {
        return __builtin_ia32_minss(a, b);
    }
    else
    {
        // Generates minss since LDC 1.3 -O1
        __m128 r = a;
        r[0] = (a[0] < b[0]) ? a[0] : b[0];
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1, 2, 3, 4);
    __m128 B = _mm_setr_ps(4, 1, 4, 1);
    __m128 C = _mm_setr_ps(float.nan, 1, 4, 1);
    __m128 M = _mm_min_ss(A, B);
    assert(M.array[0] == 1);
    assert(M.array[1] == 2);
    assert(M.array[2] == 3);
    assert(M.array[3] == 4);
    M = _mm_min_ps(A, C); // in case of NaN, second operand prevails
    assert(M.array[0] != M.array[0]);
    M = _mm_min_ps(C, A); // in case of NaN, second operand prevails
    assert(M.array[0] == 1);
}

/// Move the lower single-precision (32-bit) floating-point element from `b` to the lower element of result, and copy 
/// the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_move_ss (__m128 a, __m128 b) pure @trusted
{
    // Workaround https://issues.dlang.org/show_bug.cgi?id=21673
    // inlining of this function fails.
    version(DigitalMars) asm nothrow @nogc pure { nop; }

    a.ptr[0] = b.array[0];
    return a;
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    __m128 B = _mm_setr_ps(5.0f, 6.0f, 7.0f, 8.0f);
    __m128 R = _mm_move_ss(A, B);
    float[4] correct = [5.0f, 2.0f, 3.0f, 4.0f];
    assert(R.array == correct);
}

/// Move the upper 2 single-precision (32-bit) floating-point elements from `b` to the lower 2 elements of result, and 
/// copy the upper 2 elements from `a` to the upper 2 elements of dst.
__m128 _mm_movehl_ps (__m128 a, __m128 b) pure @trusted
{
    // PERF DMD
    // Disabled because of https://issues.dlang.org/show_bug.cgi?id=19443
    /*
    static if (DMD_with_DSIMD)
    {
        
        return cast(__m128) __simd(XMM.MOVHLPS, a, b);
    }
    else */
    {
        a.ptr[0] = b.array[2];
        a.ptr[1] = b.array[3];
        return a;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    __m128 B = _mm_setr_ps(5.0f, 6.0f, 7.0f, 8.0f);
    __m128 R = _mm_movehl_ps(A, B);
    float[4] correct = [7.0f, 8.0f, 3.0f, 4.0f];
    assert(R.array == correct);
}

/// Move the lower 2 single-precision (32-bit) floating-point elements from `b` to the upper 2 elements of result, and 
/// copy the lower 2 elements from `a` to the lower 2 elements of result
__m128 _mm_movelh_ps (__m128 a, __m128 b) pure @trusted
{    
    // Was disabled because of https://issues.dlang.org/show_bug.cgi?id=19443
    static if (DMD_with_DSIMD && __VERSION__ >= 2101)
    {
        return cast(__m128) __simd(XMM.MOVLHPS, a, b);
    }
    else
    {
        a.ptr[2] = b.array[0];
        a.ptr[3] = b.array[1];
        return a;
    }    
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    __m128 B = _mm_setr_ps(5.0f, 6.0f, 7.0f, 8.0f);
    __m128 R = _mm_movelh_ps(A, B);
    float[4] correct = [1.0f, 2.0f, 5.0f, 6.0f];
    assert(R.array == correct);
}

/// Create mask from the most significant bit of each 8-bit element in `a`.
int _mm_movemask_pi8 (__m64 a) pure @safe
{
    return _mm_movemask_epi8(to_m128i(a));
}
unittest
{
    assert(0x9C == _mm_movemask_pi8(_mm_set_pi8(-1, 0, 0, -1, -1, -1, 0, 0)));
}

/// Set each bit of result based on the most significant bit of the corresponding packed single-precision (32-bit) 
/// floating-point element in `a`.
int _mm_movemask_ps (__m128 a) pure @trusted
{
    // PERF: Not possible in D_SIMD because of https://issues.dlang.org/show_bug.cgi?id=8047
    static if (GDC_with_SSE)
    {
        return __builtin_ia32_movmskps(a);
    }
    else static if (LDC_with_SSE)
    {
        return __builtin_ia32_movmskps(a);
    }
    else static if (LDC_with_ARM)
    {
        int4 ai = cast(int4)a;
        int4 shift31 = [31, 31, 31, 31]; 
        ai = ai >>> shift31;
        int4 shift = [0, 1, 2, 3]; 
        ai = ai << shift; // 4-way shift, only efficient on ARM.
        int r = ai.array[0] + (ai.array[1]) + (ai.array[2]) + (ai.array[3]);
        return r;
    }
    else
    {
        int4 ai = cast(int4)a;
        int r = 0;
        if (ai.array[0] < 0) r += 1;
        if (ai.array[1] < 0) r += 2;
        if (ai.array[2] < 0) r += 4;
        if (ai.array[3] < 0) r += 8;
        return r;
    }
}
unittest
{
    int4 A = [-1, 0, -43, 0];
    assert(5 == _mm_movemask_ps(cast(float4)A));
}

/// Multiply packed single-precision (32-bit) floating-point elements in `a` and `b`.
__m128 _mm_mul_ps(__m128 a, __m128 b) pure @safe
{
    pragma(inline, true);
    return a * b;
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_mul_ps(a, a);
    float[4] correct = [2.25f, 4.0f, 9.0f, 1.0f];
    assert(a.array == correct);
}

/// Multiply the lower single-precision (32-bit) floating-point element in `a` and `b`, store the result in the lower 
/// element of result, and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_mul_ss(__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.MULSS, a, b);
    else static if (GDC_with_SSE)
        return __builtin_ia32_mulss(a, b);
    else
    {
        a[0] *= b[0];
        return a;
    }
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_mul_ss(a, a);
    float[4] correct = [2.25f, -2.0f, 3.0f, 1.0f];
    assert(a.array == correct);
}

/// Multiply the packed unsigned 16-bit integers in `a` and `b`, producing intermediate 32-bit integers, 
/// and return the high 16 bits of the intermediate integers.
__m64 _mm_mulhi_pu16 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_mulhi_epu16(to_m128i(a), to_m128i(b)));
}
unittest
{
    __m64 A = _mm_setr_pi16(0, -16, 2, 3);
    __m64 B = _mm_set1_pi16(16384);
    short4 R = cast(short4)_mm_mulhi_pu16(A, B);
    short[4] correct = [0, 0x3FFC, 0, 0];
    assert(R.array == correct);
}

/// Compute the bitwise OR of packed single-precision (32-bit) floating-point elements in `a` and `b`, and 
/// return the result.
__m128 _mm_or_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128)__simd(XMM.ORPS, a, b);
    else
        return cast(__m128)(cast(__m128i)a | cast(__m128i)b);
}
unittest
{
    __m128 A = cast(__m128) _mm_set1_epi32(0x80000000);
    __m128 B = _mm_setr_ps(4.0f, -5.0, -9.5f, float.infinity);
    __m128 C = _mm_or_ps(A, B);
    float[4] correct = [-4.0f, -5.0, -9.5f, -float.infinity];
    assert(C.array == correct);
}

deprecated("Use _mm_avg_pu8 instead") alias _m_pavgb = _mm_avg_pu8;///
deprecated("Use _mm_avg_pu16 instead") alias _m_pavgw = _mm_avg_pu16;///
deprecated("Use _mm_extract_pi16 instead") alias _m_pextrw = _mm_extract_pi16;///
deprecated("Use _mm_insert_pi16 instead") alias _m_pinsrw = _mm_insert_pi16;///
deprecated("Use _mm_max_pi16 instead") alias _m_pmaxsw = _mm_max_pi16;///
deprecated("Use _mm_max_pu8 instead") alias _m_pmaxub = _mm_max_pu8;///
deprecated("Use _mm_min_pi16 instead") alias _m_pminsw = _mm_min_pi16;///
deprecated("Use _mm_min_pu8 instead") alias _m_pminub = _mm_min_pu8;///
deprecated("Use _mm_movemask_pi8 instead") alias _m_pmovmskb = _mm_movemask_pi8;///
deprecated("Use _mm_mulhi_pu16 instead") alias _m_pmulhuw = _mm_mulhi_pu16;///

enum _MM_HINT_T0  = 3; ///
enum _MM_HINT_T1  = 2; ///
enum _MM_HINT_T2  = 1; ///
enum _MM_HINT_NTA = 0; ///


version(LDC)
{
    // Starting with LLVM 10, it seems llvm.prefetch has changed its name.
    // Was reported at: https://github.com/ldc-developers/ldc/issues/3397
    static if (__VERSION__ >= 2091) 
    {
        pragma(LDC_intrinsic, "llvm.prefetch.p0i8") // was "llvm.prefetch"
            void llvm_prefetch_fixed(void* ptr, uint rw, uint locality, uint cachetype) pure @safe;
    }
}

/// Fetch the line of data from memory that contains address `p` to a location in the 
/// cache hierarchy specified by the locality hint i.
///
/// Warning: `locality` is a compile-time parameter, unlike in Intel Intrinsics API.
void _mm_prefetch(int locality)(const(void)* p) pure @trusted
{
    static if (GDC_with_SSE)
    {
        return __builtin_prefetch(p, (locality & 0x4) >> 2, locality & 0x3);
    }
    else static if (DMD_with_DSIMD)
    {
        enum bool isWrite = (locality & 0x4) != 0;
        enum level = locality & 3;
        return prefetch!(isWrite, level)(p);
    }
    else version(LDC)
    {
        static if (__VERSION__ >= 2091)
        {
            // const_cast here. `llvm_prefetch` wants a mutable pointer
            llvm_prefetch_fixed( cast(void*)p, 0, locality, 1);
        }
        else
        {
            // const_cast here. `llvm_prefetch` wants a mutable pointer
            llvm_prefetch( cast(void*)p, 0, locality, 1);
        }
    }
    else version(D_InlineAsm_X86_64)
    {
        static if (locality == _MM_HINT_NTA)
        {
            asm pure nothrow @nogc @trusted
            {
                mov RAX, p;
                prefetchnta [RAX];
            }
        }
        else static if (locality == _MM_HINT_T0)
        {
            asm pure nothrow @nogc @trusted
            {
                mov RAX, p;
                prefetcht0 [RAX];
            }
        }
        else static if (locality == _MM_HINT_T1)
        {
            asm pure nothrow @nogc @trusted
            {
                mov RAX, p;
                prefetcht1 [RAX];
            }
        }
        else static if (locality == _MM_HINT_T2)
        {
            asm pure nothrow @nogc @trusted
            {
                mov RAX, p;
                prefetcht2 [RAX];
            }
        }
        else
            assert(false); // invalid locality hint
    }
    else version(D_InlineAsm_X86)
    {
        static if (locality == _MM_HINT_NTA)
        {
            asm pure nothrow @nogc @trusted
            {
                mov EAX, p;
                prefetchnta [EAX];
            }
        }
        else static if (locality == _MM_HINT_T0)
        {
            asm pure nothrow @nogc @trusted
            {
                mov EAX, p;
                prefetcht0 [EAX];
            }
        }
        else static if (locality == _MM_HINT_T1)
        {
            asm pure nothrow @nogc @trusted
            {
                mov EAX, p;
                prefetcht1 [EAX];
            }
        }
        else static if (locality == _MM_HINT_T2)
        {
            asm pure nothrow @nogc @trusted
            {
                mov EAX, p;
                prefetcht2 [EAX];
            }
        }
        else 
            assert(false); // invalid locality hint
    }
    else
    {
        // Generic version: do nothing. From bitter experience, 
        // it's unlikely you get ANY speed-up with manual prefetching.
        // Prefetching or not doesn't change program behaviour.
    }
}
unittest
{
    // From Intel documentation:
    // "The amount of data prefetched is also processor implementation-dependent. It will, however, be a minimum of 
    // 32 bytes."
    ubyte[256] cacheline; // though it seems it cannot generate GP fault
    _mm_prefetch!_MM_HINT_T0(cacheline.ptr); 
    _mm_prefetch!_MM_HINT_T1(cacheline.ptr); 
    _mm_prefetch!_MM_HINT_T2(cacheline.ptr); 
    _mm_prefetch!_MM_HINT_NTA(cacheline.ptr); 
}

deprecated("Use _mm_sad_pu8 instead") alias _m_psadbw = _mm_sad_pu8;///
deprecated("Use _mm_shuffle_pi16 instead") alias _m_pshufw = _mm_shuffle_pi16;///


/// Compute the approximate reciprocal of packed single-precision (32-bit) floating-point elements in a`` , 
/// and return the results. The maximum relative error for this approximation is less than 1.5*2^-12.
__m128 _mm_rcp_ps (__m128 a) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.RCPPS, a);
    }
    else static if (GDC_with_SSE)
    {
        return __builtin_ia32_rcpps(a);
    }
    else static if (LDC_with_SSE)
    {
        return __builtin_ia32_rcpps(a);
    }
    else
    {        
        a.ptr[0] = 1.0f / a.array[0];
        a.ptr[1] = 1.0f / a.array[1];
        a.ptr[2] = 1.0f / a.array[2];
        a.ptr[3] = 1.0f / a.array[3];
        return a;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(2.34f, -70000.0f, 0.00001f, 345.5f);
    __m128 groundTruth = _mm_set1_ps(1.0f) / A;
    __m128 result = _mm_rcp_ps(A);
    foreach(i; 0..4)
    {
        double relError = (cast(double)(groundTruth.array[i]) / result.array[i]) - 1;
        assert(abs_double(relError) < 0.00037); // 1.5*2^-12 is 0.00036621093
    }
}

/// Compute the approximate reciprocal of the lower single-precision (32-bit) floating-point element in `a`, store it 
/// in the lower element of the result, and copy the upper 3 packed elements from `a` to the upper elements of result. 
/// The maximum relative error for this approximation is less than 1.5*2^-12.
__m128 _mm_rcp_ss (__m128 a) pure @trusted
{
    // Disabled, see https://issues.dlang.org/show_bug.cgi?id=23049
    /*static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.RCPSS, a);
    }
    else*/
    static if (GDC_with_SSE)
    {
        return __builtin_ia32_rcpss(a);
    }
    else static if (LDC_with_SSE)
    {
        return __builtin_ia32_rcpss(a);
    }
    else
    {
        a.ptr[0] = 1.0f / a.array[0];
        return a;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(2.34f, -70000.0f, 0.00001f, 345.5f);
    __m128 correct = _mm_setr_ps(1 / 2.34f, -70000.0f, 0.00001f, 345.5f);
    __m128 R = _mm_rcp_ss(A);
    double relError = (cast(double)(correct.array[0]) / R.array[0]) - 1;
    assert(abs_double(relError) < 0.00037); // 1.5*2^-12 is 0.00036621093
    assert(R.array[1] == correct.array[1]);
    assert(R.array[2] == correct.array[2]);
    assert(R.array[3] == correct.array[3]);
}

/// Reallocate `size` bytes of memory, aligned to the alignment specified in `alignment`, and 
/// return a pointer to the newly allocated memory. 
/// Previous data is preserved if any.
///
/// IMPORTANT: `size` MUST be > 0.
///
/// `_mm_free` MUST be used to free memory that is allocated with `_mm_malloc` or `_mm_realloc`.
/// Do NOT call _mm_realloc with size = 0.
void* _mm_realloc(void* aligned, size_t size, size_t alignment) nothrow @nogc // #BONUS
{
    return alignedReallocImpl!true(aligned, size, alignment);
}
unittest
{
    enum NALLOC = 8;
    enum size_t[8] ALIGNMENTS = [1, 2, 4, 8, 16, 32, 64, 128];
    
    void*[NALLOC] alloc;

    foreach(t; 0..100)
    {
        foreach(n; 0..NALLOC)
        {
            size_t alignment = ALIGNMENTS[n];
            size_t s = 1 + ( (n + t * 69096) & 0xffff );
            alloc[n] = _mm_realloc(alloc[n], s, alignment);
            assert(isPointerAligned(alloc[n], alignment));
            foreach(b; 0..s)
                (cast(ubyte*)alloc[n])[b] = cast(ubyte)n;
        }
    }
    foreach(n; 0..NALLOC)
    {        
        _mm_free(alloc[n]);
    }
}

/// Reallocate `size` bytes of memory, aligned to the alignment specified in `alignment`, and 
/// return a pointer to the newly allocated memory. 
/// Previous data is discarded.
///
/// IMPORTANT: `size` MUST be > 0.
///
/// `_mm_free` MUST be used to free memory that is allocated with `_mm_malloc` or `_mm_realloc`.
void* _mm_realloc_discard(void* aligned, size_t size, size_t alignment) nothrow @nogc // #BONUS
{
    return alignedReallocImpl!false(aligned, size, alignment);
}

/// Compute the approximate reciprocal square root of packed single-precision (32-bit) floating-point elements in `a`. 
/// The maximum relative error for this approximation is less than 1.5*2^-12.
__m128 _mm_rsqrt_ps (__m128 a) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.RSQRTPS, a);
    }
    else static if (GDC_with_SSE)
    {
        return __builtin_ia32_rsqrtps(a);
    }
    else static if (LDC_with_SSE)
    {
        return __builtin_ia32_rsqrtps(a);
    }
    else version(LDC)
    {
        a[0] = 1.0f / llvm_sqrt(a[0]);
        a[1] = 1.0f / llvm_sqrt(a[1]);
        a[2] = 1.0f / llvm_sqrt(a[2]);
        a[3] = 1.0f / llvm_sqrt(a[3]);
        return a;
    }
    else
    {
        a.ptr[0] = 1.0f / sqrt(a.array[0]);
        a.ptr[1] = 1.0f / sqrt(a.array[1]);
        a.ptr[2] = 1.0f / sqrt(a.array[2]);
        a.ptr[3] = 1.0f / sqrt(a.array[3]);
        return a;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(2.34f, 70000.0f, 0.00001f, 345.5f);
    __m128 groundTruth = _mm_setr_ps(0.65372045f, 0.00377964473f, 316.227766f, 0.05379921937f);
    __m128 result = _mm_rsqrt_ps(A);
    foreach(i; 0..4)
    {
        double relError = (cast(double)(groundTruth.array[i]) / result.array[i]) - 1;
        assert(abs_double(relError) < 0.00037); // 1.5*2^-12 is 0.00036621093
    }
}

/// Compute the approximate reciprocal square root of the lower single-precision (32-bit) floating-point element in `a`,
/// store the result in the lower element. Copy the upper 3 packed elements from `a` to the upper elements of result. 
/// The maximum relative error for this approximation is less than 1.5*2^-12.
__m128 _mm_rsqrt_ss (__m128 a) pure @trusted
{   
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.RSQRTSS, a);
    }
    else static if (GDC_with_SSE)
    {
        return __builtin_ia32_rsqrtss(a);
    }
    else static if (LDC_with_SSE)
    {
        return __builtin_ia32_rsqrtss(a);
    }
    else version(LDC)
    {
        a[0] = 1.0f / llvm_sqrt(a[0]);
        return a;
    }
    else
    {
        a[0] = 1.0f / sqrt(a[0]);
        return a;
    }
}
unittest // this one test 4 different intrinsics: _mm_rsqrt_ss, _mm_rsqrt_ps, _mm_rcp_ps, _mm_rcp_ss
{
    double maxRelativeError = 0.000245; // -72 dB, stuff is apparently more precise than said in the doc?
    void testApproximateSSE(float number) nothrow @nogc
    {
        __m128 A = _mm_set1_ps(number);

        // test _mm_rcp_ps
        __m128 B = _mm_rcp_ps(A);
        foreach(i; 0..4)
        {
            double exact = 1.0f / A.array[i];
            double ratio = cast(double)(B.array[i]) / cast(double)(exact);
            assert(abs_double(ratio - 1) <= maxRelativeError);
        }

        // test _mm_rcp_ss
        {
            B = _mm_rcp_ss(A);
            double exact = 1.0f / A.array[0];
            double ratio = cast(double)(B.array[0]) / cast(double)(exact);
            assert(abs_double(ratio - 1) <= maxRelativeError);
        }

        // test _mm_rsqrt_ps
        B = _mm_rsqrt_ps(A);
        foreach(i; 0..4)
        {
            double exact = 1.0f / sqrt(A.array[i]);
            double ratio = cast(double)(B.array[i]) / cast(double)(exact);
            assert(abs_double(ratio - 1) <= maxRelativeError);
        }

        // test _mm_rsqrt_ss
        {
            B = _mm_rsqrt_ss(A);
            double exact = 1.0f / sqrt(A.array[0]);
            double ratio = cast(double)(B.array[0]) / cast(double)(exact);
            assert(abs_double(ratio - 1) <= maxRelativeError);
        }
    }

    testApproximateSSE(0.00001f);
    testApproximateSSE(1.1f);
    testApproximateSSE(345.0f);
    testApproximateSSE(2.45674864151f);
    testApproximateSSE(700000.0f);
    testApproximateSSE(10000000.0f);
    testApproximateSSE(27841456468.0f);
}

/// Compute the absolute differences of packed unsigned 8-bit integers in `a` and `b`, then horizontally sum each 
/// consecutive 8 differences to produce four unsigned 16-bit integers, and pack these unsigned 16-bit integers in the 
/// low 16 bits of result.
__m64 _mm_sad_pu8 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_sad_epu8(to_m128i(a), to_m128i(b)));
}

/// Set the exception mask bits of the MXCSR control and status register to the value in unsigned 32-bit integer 
/// `_MM_MASK_xxxx`. The exception mask may contain any of the following flags: `_MM_MASK_INVALID`, `_MM_MASK_DIV_ZERO`,
/// `_MM_MASK_DENORM`, `_MM_MASK_OVERFLOW`, `_MM_MASK_UNDERFLOW`, `_MM_MASK_INEXACT`.
void _MM_SET_EXCEPTION_MASK(int _MM_MASK_xxxx) @safe
{
    // Note: unsupported on ARM
    _mm_setcsr((_mm_getcsr() & ~_MM_MASK_MASK) | _MM_MASK_xxxx);
}

/// Set the exception state bits of the MXCSR control and status register to the value in unsigned 32-bit integer 
/// `_MM_EXCEPT_xxxx`. The exception state may contain any of the following flags: `_MM_EXCEPT_INVALID`, 
/// `_MM_EXCEPT_DIV_ZERO`, `_MM_EXCEPT_DENORM`, `_MM_EXCEPT_OVERFLOW`, `_MM_EXCEPT_UNDERFLOW`, `_MM_EXCEPT_INEXACT`.
void _MM_SET_EXCEPTION_STATE(int _MM_EXCEPT_xxxx) @safe
{
    // Note: unsupported on ARM
    _mm_setcsr((_mm_getcsr() & ~_MM_EXCEPT_MASK) | _MM_EXCEPT_xxxx);
}

/// Set the flush zero bits of the MXCSR control and status register to the value in unsigned 32-bit integer 
/// `_MM_FLUSH_xxxx`. The flush zero may contain any of the following flags: `_MM_FLUSH_ZERO_ON` or `_MM_FLUSH_ZERO_OFF`.
void _MM_SET_FLUSH_ZERO_MODE(int _MM_FLUSH_xxxx) @safe
{
    _mm_setcsr((_mm_getcsr() & ~_MM_FLUSH_ZERO_MASK) | _MM_FLUSH_xxxx);
}

/// Set packed single-precision (32-bit) floating-point elements with the supplied values.
__m128 _mm_set_ps (float e3, float e2, float e1, float e0) pure @trusted
{
    __m128 r = void;
    r.ptr[0] = e0;
    r.ptr[1] = e1;
    r.ptr[2] = e2;
    r.ptr[3] = e3;
    return r;
}
unittest
{
    __m128 A = _mm_set_ps(3, 2, 1, 546);
    float[4] correct = [546.0f, 1.0f, 2.0f, 3.0f];
    assert(A.array == correct);
}

deprecated("Use _mm_set1_ps instead") alias _mm_set_ps1 = _mm_set1_ps; ///

/// Set the rounding mode bits of the MXCSR control and status register to the value in unsigned 32-bit integer 
/// `_MM_ROUND_xxxx`. The rounding mode may contain any of the following flags: `_MM_ROUND_NEAREST`, `_MM_ROUND_DOWN`, 
/// `_MM_ROUND_UP`, `_MM_ROUND_TOWARD_ZERO`.
void _MM_SET_ROUNDING_MODE(int _MM_ROUND_xxxx) @safe
{
    // Work-around for https://gcc.gnu.org/bugzilla/show_bug.cgi?id=98607
    version(GNU) asm nothrow @nogc @trusted { "" : : : "memory"; }
    _mm_setcsr((_mm_getcsr() & ~_MM_ROUND_MASK) | _MM_ROUND_xxxx);
}

/// Copy single-precision (32-bit) floating-point element `a` to the lower element of result, and zero the upper 3 elements.
__m128 _mm_set_ss (float a) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.LODSS, a);
    }
    else
    {
        __m128 r = _mm_setzero_ps();
        r.ptr[0] = a;
        return r;
    }
}
unittest
{
    float[4] correct = [42.0f, 0.0f, 0.0f, 0.0f];
    __m128 A = _mm_set_ss(42.0f);
    assert(A.array == correct);
}

/// Broadcast single-precision (32-bit) floating-point value `a` to all elements.
__m128 _mm_set1_ps (float a) pure @trusted
{
    pragma(inline, true);
    __m128 r = a;
    return r;
}
unittest
{
    float[4] correct = [42.0f, 42.0f, 42.0f, 42.0f];
    __m128 A = _mm_set1_ps(42.0f);
    assert(A.array == correct);
}

/// Set the MXCSR control and status register with the value in unsigned 32-bit integer `controlWord`.
void _mm_setcsr(uint controlWord) @trusted
{
    static if (LDC_with_ARM)
    {
        // Convert from SSE to ARM control word. This is done _partially_
        // and only support rounding mode changes.

        // "To alter some bits of a VFP system register without 
        // affecting other bits, use a read-modify-write procedure"
        uint fpscr = arm_get_fpcr();
        
        // Bits 23 to 22 are rounding modes, however not used in NEON
        fpscr = fpscr & ~_MM_ROUND_MASK_ARM;
        switch(controlWord & _MM_ROUND_MASK)
        {
            default:
            case _MM_ROUND_NEAREST:     fpscr |= _MM_ROUND_NEAREST_ARM;     break;
            case _MM_ROUND_DOWN:        fpscr |= _MM_ROUND_DOWN_ARM;        break;
            case _MM_ROUND_UP:          fpscr |= _MM_ROUND_UP_ARM;          break;
            case _MM_ROUND_TOWARD_ZERO: fpscr |= _MM_ROUND_TOWARD_ZERO_ARM; break;
        }
        fpscr = fpscr & ~_MM_FLUSH_ZERO_MASK_ARM;
        if (controlWord & _MM_FLUSH_ZERO_MASK)
            fpscr |= _MM_FLUSH_ZERO_MASK_ARM;
        arm_set_fpcr(fpscr);
    }
    else version(GNU)
    {
        static if (GDC_with_SSE)
        {
            // Work-around for https://gcc.gnu.org/bugzilla/show_bug.cgi?id=98607
            version(GNU) asm nothrow @nogc @trusted { "" : : : "memory"; }
            __builtin_ia32_ldmxcsr(controlWord);
        }
        else version(X86)
        {
            asm nothrow @nogc @trusted
            {
                "ldmxcsr %0;\n" 
                  : 
                  : "m" (controlWord)
                  : ;
            }
        }
        else
            static assert(false);
    }
    else version (InlineX86Asm)
    {
        asm nothrow @nogc @safe
        {
            ldmxcsr controlWord;
        }
    }
    else
        static assert(0, "Not yet supported");
}
unittest
{
    _mm_setcsr(_mm_getcsr());
}

/// Set packed single-precision (32-bit) floating-point elements with the supplied values in reverse order.
__m128 _mm_setr_ps (float e3, float e2, float e1, float e0) pure @trusted
{
    pragma(inline, true);
  
    // This small = void here wins a bit in all optimization levels in GDC
    // and in -O0 in LDC.
    __m128 r = void;
    r.ptr[0] = e3;
    r.ptr[1] = e2;
    r.ptr[2] = e1;
    r.ptr[3] = e0;
    return r;
}
unittest
{
    __m128 A = _mm_setr_ps(3, 2, 1, 546);
    float[4] correct = [3.0f, 2.0f, 1.0f, 546.0f];
    assert(A.array == correct);
}

/// Return vector of type `__m128` with all elements set to zero.
__m128 _mm_setzero_ps() pure @trusted
{
    pragma(inline, true);

    // Note: for all compilers, this works best in debug builds, and in DMD -O
    int4 r; 
    return cast(__m128)r;
}
unittest
{
    __m128 R = _mm_setzero_ps();
    float[4] correct = [0.0f, 0, 0, 0];
    assert(R.array == correct);
}

/// Do a serializing operation on all store-to-memory instructions that were issued prior 
/// to this instruction. Guarantees that every store instruction that precedes, in program order, 
/// is globally visible before any store instruction which follows the fence in program order.
void _mm_sfence() @trusted
{
    version(GNU)
    {
        static if (GDC_with_SSE)
        {
            __builtin_ia32_sfence();
        }
        else version(X86)
        {
            asm pure nothrow @nogc @trusted
            {
                "sfence;\n" : : : ;
            }
        }
        else
            static assert(false);
    }
    else static if (LDC_with_SSE)
    {
        __builtin_ia32_sfence();
    }
    else static if (DMD_with_asm)
    {
        // PERF: can't be inlined in DMD, probably because of that assembly.
        asm nothrow @nogc pure @safe
        {
            sfence;
        }
    }
    else static if (LDC_with_ARM64)
    {
        __builtin_arm_dmb(10); // dmb ishst
    }
    else version(LDC)
    {
        // When the architecture is unknown, generate a full memory barrier,
        // as the semantics of sfence do not really match those of atomics.
        llvm_memory_fence();
    }
    else
        static assert(false);
}
unittest
{
    _mm_sfence();
}


__m64 _mm_shuffle_pi16(int imm8)(__m64 a) pure @trusted
{
    // PERF DMD + D_SIMD
    version(LDC)
    {
        return cast(__m64) shufflevectorLDC!(short4, ( (imm8 >> 0) & 3 ),
                                                     ( (imm8 >> 2) & 3 ),
                                                     ( (imm8 >> 4) & 3 ),
                                                     ( (imm8 >> 6) & 3 ))(cast(short4)a, cast(short4)a);
    }
    else
    {
        // GDC optimizes that correctly starting with -O2
        short4 sa = cast(short4)a;
        short4 r = void;
        r.ptr[0] = sa.array[ (imm8 >> 0) & 3 ];
        r.ptr[1] = sa.array[ (imm8 >> 2) & 3 ];
        r.ptr[2] = sa.array[ (imm8 >> 4) & 3 ];
        r.ptr[3] = sa.array[ (imm8 >> 6) & 3 ];
        return cast(__m64)r;
    }
}
unittest
{
    __m64 A = _mm_setr_pi16(0, 1, 2, 3);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    short4 B = cast(short4) _mm_shuffle_pi16!SHUFFLE(A);
    short[4] expectedB = [ 3, 2, 1, 0 ];
    assert(B.array == expectedB);
}

/// Shuffle single-precision (32-bit) floating-point elements in `a` and `b` using the control in `imm8`, 
/// Warning: the immediate shuffle value `imm` is given at compile-time instead of runtime.
__m128 _mm_shuffle_ps(ubyte imm8)(__m128 a, __m128 b) pure @trusted
{
    static if (GDC_with_SSE)
    {
        return __builtin_ia32_shufps(a, b, imm8);
    }
    else static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.SHUFPS, a, b, imm8);
    }
    else static if (LDC_with_optimizations)
    {
        return shufflevectorLDC!(__m128, imm8 & 3, (imm8>>2) & 3, 
                                 4 + ((imm8>>4) & 3), 4 + ((imm8>>6) & 3) )(a, b);
    }
    else
    {
        float4 r = void;
        r.ptr[0] = a.array[ (imm8 >> 0) & 3 ];
        r.ptr[1] = a.array[ (imm8 >> 2) & 3 ];
        r.ptr[2] = b.array[ (imm8 >> 4) & 3 ];
        r.ptr[3] = b.array[ (imm8 >> 6) & 3 ];
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(0, 1, 2, 3);
    __m128 B = _mm_setr_ps(4, 5, 6, 7);
    __m128 C = _mm_shuffle_ps!0x9c(A, B);
    float[4] correct = [0.0f, 3, 5, 6];
    assert(C.array == correct);
}

/// Compute the square root of packed single-precision (32-bit) floating-point elements in `a`.
__m128 _mm_sqrt_ps(__m128 a) @trusted
{
    static if (GDC_with_SSE)
    {
        return __builtin_ia32_sqrtps(a);
    }
    else static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.SQRTPS, a);
    }
    else version(LDC)
    {
        // Disappeared with LDC 1.11
        static if (__VERSION__ < 2081)
            return __builtin_ia32_sqrtps(a);
        else
        {
            // PERF: use llvm_sqrt on the vector, works better
            a[0] = llvm_sqrt(a[0]);
            a[1] = llvm_sqrt(a[1]);
            a[2] = llvm_sqrt(a[2]);
            a[3] = llvm_sqrt(a[3]);
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
    __m128 A = _mm_sqrt_ps(_mm_set1_ps(4.0f));
    assert(A.array[0] == 2.0f);
    assert(A.array[1] == 2.0f);
    assert(A.array[2] == 2.0f);
    assert(A.array[3] == 2.0f);
}

/// Compute the square root of the lower single-precision (32-bit) floating-point element in `a`, store it in the lower
/// element, and copy the upper 3 packed elements from `a` to the upper elements of result.
__m128 _mm_sqrt_ss(__m128 a) @trusted
{
    static if (GDC_with_SSE)
    {
        return __builtin_ia32_sqrtss(a);
    }
    // PERF DMD
    // TODO: enable when https://issues.dlang.org/show_bug.cgi?id=23437 is fixed for good
    /*else static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.SQRTSS, a);
    }*/
    else version(LDC)
    {
        a.ptr[0] = llvm_sqrt(a.array[0]);
        return a;
    }
    else
    {   
        a.ptr[0] = sqrt(a.array[0]);
        return a;
    }
}
unittest
{
    __m128 A = _mm_sqrt_ss(_mm_set1_ps(4.0f));
    assert(A.array[0] == 2.0f);
    assert(A.array[1] == 4.0f);
    assert(A.array[2] == 4.0f);
    assert(A.array[3] == 4.0f);
}

/// Store 128-bits (composed of 4 packed single-precision (32-bit) floating-point elements) from `a` into memory. 
/// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
void _mm_store_ps (float* mem_addr, __m128 a) pure
{
    pragma(inline, true);
    __m128* aligned = cast(__m128*)mem_addr;
    *aligned = a;
}

deprecated("Use _mm_store1_ps instead") alias _mm_store_ps1 = _mm_store1_ps; ///

/// Store the lower single-precision (32-bit) floating-point element from `a` into memory. 
/// `mem_addr` does not need to be aligned on any particular boundary.
void _mm_store_ss (float* mem_addr, __m128 a) pure @safe
{
    pragma(inline, true);
    *mem_addr = a.array[0];
}
unittest
{
    float a;
    _mm_store_ss(&a, _mm_set_ps(3, 2, 1, 546));
    assert(a == 546);
}

/// Store the lower single-precision (32-bit) floating-point element from `a` into 4 contiguous elements in memory. 
/// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
void _mm_store1_ps(float* mem_addr, __m128 a) pure @trusted // FUTURE: shouldn't be trusted, see #62
{
    __m128* aligned = cast(__m128*)mem_addr;
    static if (DMD_with_DSIMD)
    {
        __m128 r = cast(__m128) __simd(XMM.SHUFPS, a, a, 0);
    }
    else
    {
        __m128 r; // PERF =void;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[0];
        r.ptr[2] = a.array[0];
        r.ptr[3] = a.array[0];
    }
    *aligned = r;
}
unittest
{
    align(16) float[4] A;
    _mm_store1_ps(A.ptr, _mm_set_ss(42.0f));
    float[4] correct = [42.0f, 42, 42, 42];
    assert(A == correct);
}

/// Store the upper 2 single-precision (32-bit) floating-point elements from `a` into memory.
void _mm_storeh_pi(__m64* p, __m128 a) pure @trusted
{
    pragma(inline, true);
    long2 la = cast(long2)a;
    (*p).ptr[0] = la.array[1];
}
unittest
{
    __m64 R = _mm_setzero_si64();
    long2 A = [13, 25];
    _mm_storeh_pi(&R, cast(__m128)A);
    assert(R.array[0] == 25);
}

/// Store the lower 2 single-precision (32-bit) floating-point elements from `a` into memory.
void _mm_storel_pi(__m64* p, __m128 a) pure @trusted
{
    pragma(inline, true);
    long2 la = cast(long2)a;
    (*p).ptr[0] = la.array[0];
}
unittest
{
    __m64 R = _mm_setzero_si64();
    long2 A = [13, 25];
    _mm_storel_pi(&R, cast(__m128)A);
    assert(R.array[0] == 13);
}

/// Store 4 single-precision (32-bit) floating-point elements from `a` into memory in reverse order. 
/// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
void _mm_storer_ps(float* mem_addr, __m128 a) pure @trusted // FUTURE should not be trusted
{
    __m128* aligned = cast(__m128*)mem_addr;
    static if (DMD_with_DSIMD)
    {
        __m128 r = cast(__m128) __simd(XMM.SHUFPS, a, a, 27);
    }
    else
    {
        __m128 r; // PERF =void;
        r.ptr[0] = a.array[3];
        r.ptr[1] = a.array[2];
        r.ptr[2] = a.array[1];
        r.ptr[3] = a.array[0];
    }
    *aligned = r;
}
unittest
{
    align(16) float[4] A;
    _mm_storer_ps(A.ptr, _mm_setr_ps(1.0f, 2, 3, 4));
    float[4] correct = [4.0f, 3.0f, 2.0f, 1.0f];
    assert(A == correct);
}

/// Store 128-bits (composed of 4 packed single-precision (32-bit) floating-point elements) from `a` into memory. 
/// `mem_addr` does not need to be aligned on any particular boundary.
void _mm_storeu_ps(float* mem_addr, __m128 a) pure @trusted // FUTURE should not be trusted, see #62
{
    pragma(inline, true);
    static if (DMD_with_DSIMD)
    {
        cast(void) __simd_sto(XMM.STOUPS, *cast(void16*)(cast(float*)mem_addr), a);
    }
    else static if (GDC_with_SSE)
    {
        __builtin_ia32_storeups(mem_addr, a); // better in -O0
    }
    else static if (LDC_with_optimizations)
    {
        storeUnaligned!(float4)(a, mem_addr);
    }
    else
    {
        mem_addr[0] = a.array[0];
        mem_addr[1] = a.array[1];
        mem_addr[2] = a.array[2];
        mem_addr[3] = a.array[3];
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2, 3, 4);
    align(16) float[6] R = [0.0f, 0, 0, 0, 0, 0];
    float[4] correct = [1.0f, 2, 3, 4];
    _mm_storeu_ps(&R[1], A);
    assert(R[1..5] == correct);
}

/// Store 64-bits of integer data from `a` into memory using a non-temporal memory hint.
/// Note: non-temporal stores should be followed by `_mm_sfence()` for reader threads.
void _mm_stream_pi (__m64* mem_addr, __m64 a) pure @trusted
{
    _mm_stream_si64(cast(long*)mem_addr, a.array[0]);
}

/// Store 128-bits (composed of 4 packed single-precision (32-bit) floating-point elements) from 
/// `a`s into memory using a non-temporal memory hint. `mem_addr` must be aligned on a 16-byte 
/// boundary or a general-protection exception may be generated.
/// Note: non-temporal stores should be followed by `_mm_sfence()` for reader threads.
void _mm_stream_ps (float* mem_addr, __m128 a)
{
    // TODO report this bug: DMD generates no stream instruction when using D_SIMD
    static if (GDC_with_SSE)
    {
        return __builtin_ia32_movntps(mem_addr, a); 
    }
    else static if (LDC_with_InlineIREx && LDC_with_optimizations)
    {
        enum prefix = `!0 = !{ i32 1 }`;
        enum ir = `
            store <4 x float> %1, <4 x float>* %0, align 16, !nontemporal !0
            ret void`;
        LDCInlineIREx!(prefix, ir, "", void, __m128*, float4)(cast(__m128*)mem_addr, a);

    }
    else
    {
        // Regular store instead.
        __m128* dest = cast(__m128*)mem_addr;
        *dest = a; // it's a regular move instead
    }
}
unittest
{
    align(16) float[4] A;
    _mm_stream_ps(A.ptr, _mm_set1_ps(78.0f));
    assert(A[0] == 78.0f && A[1] == 78.0f && A[2] == 78.0f && A[3] == 78.0f);
}

/// Subtract packed single-precision (32-bit) floating-point elements in `b` from packed single-precision (32-bit) 
/// floating-point elements in `a`.
__m128 _mm_sub_ps(__m128 a, __m128 b) pure @safe
{
    pragma(inline, true);
    return a - b;
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_sub_ps(a, a);
    float[4] correct = [0.0f, 0.0f, 0.0f, 0.0f];
    assert(a.array == correct);
}

/// Subtract the lower single-precision (32-bit) floating-point element in `b` from the lower single-precision (32-bit)
/// floating-point element in `a`, store the subtration result in the lower element of result, and copy the upper 3 
/// packed elements from a to the upper elements of result.
__m128 _mm_sub_ss(__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
        return cast(__m128) __simd(XMM.SUBSS, a, b);
    else static if (GDC_with_SSE)
        return __builtin_ia32_subss(a, b);
    else
    {
        a[0] -= b[0];
        return a;
    }
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_sub_ss(a, a);
    float[4] correct = [0.0f, -2.0, 3.0f, 1.0f];
    assert(a.array == correct);
}

/// Transpose the 4x4 matrix formed by the 4 rows of single-precision (32-bit) floating-point elements in row0, row1, 
/// row2, and row3, and store the transposed matrix in these vectors (row0 now contains column 0, etc.).
void _MM_TRANSPOSE4_PS (ref __m128 row0, ref __m128 row1, ref __m128 row2, ref __m128 row3) pure @safe
{
    __m128 tmp3, tmp2, tmp1, tmp0;
    tmp0 = _mm_unpacklo_ps(row0, row1);
    tmp2 = _mm_unpacklo_ps(row2, row3);
    tmp1 = _mm_unpackhi_ps(row0, row1);
    tmp3 = _mm_unpackhi_ps(row2, row3);
    row0 = _mm_movelh_ps(tmp0, tmp2);
    row1 = _mm_movehl_ps(tmp2, tmp0);
    row2 = _mm_movelh_ps(tmp1, tmp3);
    row3 = _mm_movehl_ps(tmp3, tmp1);
}
unittest
{
    __m128 l0 = _mm_setr_ps(0, 1, 2, 3);
    __m128 l1 = _mm_setr_ps(4, 5, 6, 7);
    __m128 l2 = _mm_setr_ps(8, 9, 10, 11);
    __m128 l3 = _mm_setr_ps(12, 13, 14, 15);
    _MM_TRANSPOSE4_PS(l0, l1, l2, l3);
    float[4] r0 = [0.0f, 4, 8, 12];
    float[4] r1 = [1.0f, 5, 9, 13];
    float[4] r2 = [2.0f, 6, 10, 14];
    float[4] r3 = [3.0f, 7, 11, 15];
    assert(l0.array == r0);
    assert(l1.array == r1);
    assert(l2.array == r2);
    assert(l3.array == r3);
}

// Note: the only difference between these intrinsics is the signalling
//       behaviour of quiet NaNs. This is incorrect but the case where
//       you would want to differentiate between qNaN and sNaN and then
//       treat them differently on purpose seems extremely rare.
alias _mm_ucomieq_ss = _mm_comieq_ss;
alias _mm_ucomige_ss = _mm_comige_ss;
alias _mm_ucomigt_ss = _mm_comigt_ss;
alias _mm_ucomile_ss = _mm_comile_ss;
alias _mm_ucomilt_ss = _mm_comilt_ss;
alias _mm_ucomineq_ss = _mm_comineq_ss;

/// Return vector of type `__m128` with undefined elements.
__m128 _mm_undefined_ps() pure @safe
{
    pragma(inline, true);
    __m128 undef = void;
    return undef;
}

/// Unpack and interleave single-precision (32-bit) floating-point elements from the high half `a` and `b`.
__m128 _mm_unpackhi_ps (__m128 a, __m128 b) pure @trusted
{
    // PERF GDC use intrinsic
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.UNPCKHPS, a, b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <4 x float> %0, <4 x float> %1, <4 x i32> <i32 2, i32 6, i32 3, i32 7>
                  ret <4 x float> %r`;
        return LDCInlineIR!(ir, float4, float4, float4)(a, b);
    }
    else
    {
        __m128 r; // PERF =void;
        r.ptr[0] = a.array[2];
        r.ptr[1] = b.array[2];
        r.ptr[2] = a.array[3];
        r.ptr[3] = b.array[3];
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    __m128 B = _mm_setr_ps(5.0f, 6.0f, 7.0f, 8.0f);
    __m128 R = _mm_unpackhi_ps(A, B);
    float[4] correct = [3.0f, 7.0f, 4.0f, 8.0f];
    assert(R.array == correct);
}

/// Unpack and interleave single-precision (32-bit) floating-point elements from the low half of `a` and `b`.
__m128 _mm_unpacklo_ps (__m128 a, __m128 b) pure @trusted
{
    // PERF GDC use intrinsic
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.UNPCKLPS, a, b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <4 x float> %0, <4 x float> %1, <4 x i32> <i32 0, i32 4, i32 1, i32 5>
                   ret <4 x float> %r`;
        return LDCInlineIR!(ir, float4, float4, float4)(a, b);
    }
    else
    {
        __m128 r; // PERF =void;
        r.ptr[0] = a.array[0];
        r.ptr[1] = b.array[0];
        r.ptr[2] = a.array[1];
        r.ptr[3] = b.array[1];
        return r;
    }
}
unittest
{
    __m128 A = _mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f);
    __m128 B = _mm_setr_ps(5.0f, 6.0f, 7.0f, 8.0f);
    __m128 R = _mm_unpacklo_ps(A, B);
    float[4] correct = [1.0f, 5.0f, 2.0f, 6.0f];
    assert(R.array == correct);
}

/// Compute the bitwise XOR of packed single-precision (32-bit) floating-point elements in `a` and `b`.
__m128 _mm_xor_ps (__m128 a, __m128 b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128) __simd(XMM.XORPS, cast(void16) a, cast(void16) b);
    }
    else
    {
        return cast(__m128)(cast(__m128i)a ^ cast(__m128i)b);
    }
}
unittest
{
    __m128 A = cast(__m128) _mm_set1_epi32(0x80000000);
    __m128 B = _mm_setr_ps(4.0f, -5.0, -9.5f, float.infinity);
    __m128 C = _mm_xor_ps(A, B);
    float[4] correct = [-4.0f, 5.0, 9.5f, -float.infinity];
    assert(C.array == correct);
}

private
{
    // Returns: `true` if the pointer is suitably aligned.
    bool isPointerAligned(void* p, size_t alignment) pure
    {
        assert(alignment != 0);
        return ( cast(size_t)p & (alignment - 1) ) == 0;
    }

    // Returns: next pointer aligned with alignment bytes.
    void* nextAlignedPointer(void* start, size_t alignment) pure
    {
        return cast(void*)nextMultipleOf(cast(size_t)(start), alignment);
    }

    // Returns number of bytes to actually allocate when asking
    // for a particular alignment
    @nogc size_t requestedSize(size_t askedSize, size_t alignment) pure
    {
        enum size_t pointerSize = size_t.sizeof;
        return askedSize + alignment - 1 + pointerSize * 3;
    }

    // Store pointer given by malloc + size + alignment
    @nogc void* storeRawPointerPlusInfo(void* raw, size_t size, size_t alignment) pure
    {
        enum size_t pointerSize = size_t.sizeof;
        char* start = cast(char*)raw + pointerSize * 3;
        void* aligned = nextAlignedPointer(start, alignment);
        void** rawLocation = cast(void**)(cast(char*)aligned - pointerSize);
        *rawLocation = raw;
        size_t* sizeLocation = cast(size_t*)(cast(char*)aligned - 2 * pointerSize);
        *sizeLocation = size;
        size_t* alignmentLocation = cast(size_t*)(cast(char*)aligned - 3 * pointerSize);
        *alignmentLocation = alignment;
        assert( isPointerAligned(aligned, alignment) );
        return aligned;
    }

    // Returns: x, multiple of powerOfTwo, so that x >= n.
    @nogc size_t nextMultipleOf(size_t n, size_t powerOfTwo) pure nothrow
    {
        // check power-of-two
        assert( (powerOfTwo != 0) && ((powerOfTwo & (powerOfTwo - 1)) == 0));

        size_t mask = ~(powerOfTwo - 1);
        return (n + powerOfTwo - 1) & mask;
    }

    void* alignedReallocImpl(bool PreserveDataIfResized)(void* aligned, size_t size, size_t alignment)
    {
        // Calling `_mm_realloc`, `_mm_realloc_discard` or `realloc`  with size 0 is 
        // Undefined Behavior, and not only since C23.
        // Moreover, alignedReallocImpl was buggy about it.
        assert(size != 0);

        if (aligned is null)
            return _mm_malloc(size, alignment);

        assert(alignment != 0);
        assert(isPointerAligned(aligned, alignment));

        size_t previousSize = *cast(size_t*)(cast(char*)aligned - size_t.sizeof * 2);
        size_t prevAlignment = *cast(size_t*)(cast(char*)aligned - size_t.sizeof * 3);

        // It is illegal to change the alignment across calls.
        assert(prevAlignment == alignment);

        void* raw = *cast(void**)(cast(char*)aligned - size_t.sizeof);
        size_t request = requestedSize(size, alignment);
        size_t previousRequest = requestedSize(previousSize, alignment);
        assert(previousRequest - request == previousSize - size);

        // Heuristic: if a requested size is within 50% to 100% of what is already allocated
        //            then exit with the same pointer
        // PERF it seems like `realloc` should do that, not us.
        if ( (previousRequest < request * 4) && (request <= previousRequest) )
            return aligned;

        void* newRaw = malloc(request);
        if (request > 0 && newRaw == null) // realloc(0) can validly return anything
            onOutOfMemoryError();

        void* newAligned = storeRawPointerPlusInfo(newRaw, size, alignment);

        static if (PreserveDataIfResized)
        {
            size_t minSize = size < previousSize ? size : previousSize;
            memcpy(newAligned, aligned, minSize); // ok to use memcpy: newAligned is into new memory, always different from aligned
        }

        // Free previous data
        _mm_free(aligned);
        assert(isPointerAligned(newAligned, alignment));
        return newAligned;
    }
}

unittest
{
    assert(nextMultipleOf(0, 4) == 0);
    assert(nextMultipleOf(1, 4) == 4);
    assert(nextMultipleOf(2, 4) == 4);
    assert(nextMultipleOf(3, 4) == 4);
    assert(nextMultipleOf(4, 4) == 4);
    assert(nextMultipleOf(5, 4) == 8);

    {
        void* p = _mm_malloc(23, 16);
        assert(p !is null);
        assert(((cast(size_t)p) & 0xf) == 0);
        _mm_free(p);
    }

    void* nullAlloc = _mm_malloc(0, 32);
    assert(nullAlloc != null);
    _mm_free(nullAlloc);
}

unittest
{
    // In C23, it is UB to call realloc with 0 size.
    // Ensure this is not the case, ever.

    int alignment = 1;
    void* alloc = _mm_malloc(18, alignment);

    // DO NOT DO THAT:
    //_mm_realloc(alloc, 0, alignment);

    // DO THAT:
    _mm_free(alloc);
}


// For some reason, order of declaration is important for this one
// so it is misplaced.
// Note: is just another name for _mm_cvtss_si32
alias _mm_cvt_ss2si = _mm_cvtss_si32;
