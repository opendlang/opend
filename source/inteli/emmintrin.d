/**
* SSE2 intrinsics. 
* https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#techs=SSE2
*
* Copyright: Copyright Guillaume Piolat 2016-2020, Stefanos Baziotis 2019.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.emmintrin;

public import inteli.types;
public import inteli.xmmintrin; // SSE2 includes SSE1
import inteli.mmx;
import inteli.internals;

nothrow @nogc:


// SSE2 instructions
// https://software.intel.com/sites/landingpage/IntrinsicsGuide/#techs=SSE2

/// Add packed 16-bit integers in `a` and `b`.
__m128i _mm_add_epi16 (__m128i a, __m128i b) pure @safe
{
    pragma(inline, true);
    return cast(__m128i)(cast(short8)a + cast(short8)b);
}
unittest
{
    __m128i A = _mm_setr_epi16(4, 8, 13, -7, -1, 0, 9, 77);
    short8 R = cast(short8) _mm_add_epi16(A, A);
    short[8] correct = [8, 16, 26, -14, -2, 0, 18, 154];
    assert(R.array == correct);
}

/// Add packed 32-bit integers in `a` and `b`.
__m128i _mm_add_epi32 (__m128i a, __m128i b) pure @safe
{
    pragma(inline, true);
    return cast(__m128i)(cast(int4)a + cast(int4)b);
}
unittest
{
    __m128i A = _mm_setr_epi32( -7, -1, 0, 9);
    int4 R = _mm_add_epi32(A, A);
    int[4] correct = [ -14, -2, 0, 18 ];
    assert(R.array == correct);
}

/// Add packed 64-bit integers in `a` and `b`.
__m128i _mm_add_epi64 (__m128i a, __m128i b) pure @safe
{
    pragma(inline, true);
    return cast(__m128i)(cast(long2)a + cast(long2)b);
}
unittest
{
    __m128i A = _mm_setr_epi64(-1, 0x8000_0000_0000_0000);
    long2 R = cast(long2) _mm_add_epi64(A, A);
    long[2] correct = [ -2, 0 ];
    assert(R.array == correct);
}

/// Add packed 8-bit integers in `a` and `b`.
__m128i _mm_add_epi8 (__m128i a, __m128i b) pure @safe
{
    pragma(inline, true);
    return cast(__m128i)(cast(byte16)a + cast(byte16)b);
}
unittest
{
    __m128i A = _mm_setr_epi8(4, 8, 13, -7, -1, 0, 9, 77, 4, 8, 13, -7, -1, 0, 9, 78);
    byte16 R = cast(byte16) _mm_add_epi8(A, A);
    byte[16] correct = [8, 16, 26, -14, -2, 0, 18, -102, 8, 16, 26, -14, -2, 0, 18, -100];
    assert(R.array == correct);
}

/// Add the lower double-precision (64-bit) floating-point element 
/// in `a` and `b`, store the result in the lower element of dst, 
/// and copy the upper element from `a` to the upper element of destination. 
__m128d _mm_add_sd(__m128d a, __m128d b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128d) __simd(XMM.ADDSD, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_addsd(a, b);
    }
    else version(DigitalMars)
    {
        // Work-around for https://issues.dlang.org/show_bug.cgi?id=19599
        // Note that this is unneeded since DMD >= 2.094.0 at least, haven't investigated again
        asm pure nothrow @nogc @trusted { nop;}
        a[0] = a[0] + b[0];
        return a;
    }
    else
    {
        a[0] += b[0];
        return a;
    }
}
unittest
{
    __m128d a = [1.5, -2.0];
    a = _mm_add_sd(a, a);
    assert(a.array == [3.0, -2.0]);
}

/// Add packed double-precision (64-bit) floating-point elements in `a` and `b`.
__m128d _mm_add_pd (__m128d a, __m128d b) pure @safe
{
    pragma(inline, true);
    return a + b;
}
unittest
{
    __m128d a = [1.5, -2.0];
    a = _mm_add_pd(a, a);
    assert(a.array == [3.0, -4.0]);
}

/// Add 64-bit integers `a` and `b`.
__m64 _mm_add_si64 (__m64 a, __m64 b) pure @safe
{
    // PERF DMD
    pragma(inline, true);
    return a + b;
}

/// Add packed 16-bit integers in `a` and `b` using signed saturation.
__m128i _mm_adds_epi16(__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PADDSW, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_paddsw128(cast(short8)a, cast(short8)b);
    }
    else version(LDC)
    {
        return cast(__m128i) inteli_llvm_adds!short8(cast(short8)a, cast(short8)b);
    }
    else
    {
        short[8] res; // PERF =void;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        foreach(i; 0..8)
            res[i] = saturateSignedIntToSignedShort(sa.array[i] + sb.array[i]);
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    short8 res = cast(short8) _mm_adds_epi16(_mm_setr_epi16( 7,  6,  5, -32768, 3, 3, 32767,   0),
                                             _mm_setr_epi16( 7,  6,  5, -30000, 3, 1,     1, -10));
    static immutable short[8] correctResult             =  [14, 12, 10, -32768, 6, 4, 32767, -10];
    assert(res.array == correctResult);
}

/// Add packed 8-bit signed integers in `a` and `b` using signed saturation.
__m128i _mm_adds_epi8(__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PADDSB, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_paddsb128(cast(ubyte16)a, cast(ubyte16)b);
    }
    else version(LDC)
    {
        return cast(__m128i) inteli_llvm_adds!byte16(cast(byte16)a, cast(byte16)b);
    }
    else
    {
        byte[16] res; // PERF =void;
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        foreach(i; 0..16)
            res[i] = saturateSignedWordToSignedByte(sa[i] + sb[i]);
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    byte16 res = cast(byte16) _mm_adds_epi8(_mm_set_epi8(15, 14, 13, 12, 11, 127, 9, 8, 7, 6, 5, -128, 3, 2, 1, 0),
                                            _mm_set_epi8(15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, -4, 3, 2, 1, 0));
    static immutable byte[16] correctResult = [0, 2, 4, 6, -128, 10, 12, 14,
                                               16, 18, 127, 22, 24, 26, 28, 30];
    assert(res.array == correctResult);
}

/// Add packed 8-bit unsigned integers in `a` and `b` using unsigned saturation.
__m128i _mm_adds_epu8(__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PADDUSB, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_paddusb128(cast(ubyte16)a, cast(ubyte16)b);
    }
    else version(LDC)
    {
        return cast(__m128i) inteli_llvm_addus!byte16(cast(byte16)a, cast(byte16)b);
    }
    else
    {
        ubyte[16] res; // PERF =void;
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        foreach(i; 0..16)
            res[i] = saturateSignedWordToUnsignedByte(cast(ubyte)(sa.array[i]) + cast(ubyte)(sb.array[i]));
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    byte16 res = cast(byte16) 
        _mm_adds_epu8(_mm_set_epi8(7, 6, 5, 4, 3, 2, cast(byte)255, 0, 7, 6, 5, 4, 3, 2, cast(byte)255, 0),
                      _mm_set_epi8(7, 6, 5, 4, 3, 2, 1, 0, 7, 6, 5, 4, 3, 2, 1, 0));
    static immutable byte[16] correctResult = [0, cast(byte)255, 4, 6, 8, 10, 12, 14, 
                                               0, cast(byte)255, 4, 6, 8, 10, 12, 14];
    assert(res.array == correctResult);
}

/// Add packed unsigned 16-bit integers in `a` and `b` using unsigned saturation.
__m128i _mm_adds_epu16(__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        // Note: DMD generates a reverted paddusw vs LDC and GDC, but that doesn't change the result anyway
        return cast(__m128i) __simd(XMM.PADDUSW, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_paddusw128(cast(short8)a, cast(short8)b);
    }
    else version(LDC)
    {
        return cast(__m128i) inteli_llvm_addus!short8(cast(short8)a, cast(short8)b);
    }
    else
    {
        ushort[8] res; // PERF =void;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        foreach(i; 0..8)
            res[i] = saturateSignedIntToUnsignedShort(cast(ushort)(sa.array[i]) + cast(ushort)(sb.array[i]));
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    short8 res = cast(short8) _mm_adds_epu16(_mm_set_epi16(3, 2, cast(short)65535, 0, 3, 2, cast(short)65535, 0),
                                             _mm_set_epi16(3, 2, 1, 0, 3, 2, 1, 0));
    static immutable short[8] correctResult = [0, cast(short)65535, 4, 6, 0, cast(short)65535, 4, 6];
    assert(res.array == correctResult);
}

/// Compute the bitwise AND of packed double-precision (64-bit) 
/// floating-point elements in `a` and `b`.
__m128d _mm_and_pd (__m128d a, __m128d b) pure @safe
{
    pragma(inline, true);
    return cast(__m128d)( cast(long2)a & cast(long2)b );
}
unittest
{
    double a = 4.32;
    double b = -78.99;
    long correct = (*cast(long*)(&a)) & (*cast(long*)(&b));
    __m128d A = _mm_set_pd(a, b);
    __m128d B = _mm_set_pd(b, a);
    long2 R = cast(long2)( _mm_and_pd(A, B) );
    assert(R.array[0] == correct);
    assert(R.array[1] == correct);
}

/// Compute the bitwise AND of 128 bits (representing integer data) in `a` and `b`.
__m128i _mm_and_si128 (__m128i a, __m128i b) pure @safe
{
    pragma(inline, true);
    return a & b;
}
unittest
{
    __m128i A = _mm_set1_epi32(7);
    __m128i B = _mm_set1_epi32(14);
    __m128i R = _mm_and_si128(A, B);
    int[4] correct = [6, 6, 6, 6];
    assert(R.array == correct);
}

/// Compute the bitwise NOT of packed double-precision (64-bit) 
/// floating-point elements in `a` and then AND with `b`.
__m128d _mm_andnot_pd (__m128d a, __m128d b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128d) __simd(XMM.ANDNPD, a, b);
    }
    else
    {
        return cast(__m128d)( ~(cast(long2)a) & cast(long2)b);
    }
}
unittest
{
    double a = 4.32;
    double b = -78.99;
    long correct  = (~*cast(long*)(&a)) & ( *cast(long*)(&b));
    long correct2 = ( *cast(long*)(&a)) & (~*cast(long*)(&b));
    __m128d A = _mm_setr_pd(a, b);
    __m128d B = _mm_setr_pd(b, a);
    long2 R = cast(long2)( _mm_andnot_pd(A, B) );
    assert(R.array[0] == correct);
    assert(R.array[1] == correct2);
}

/// Compute the bitwise NOT of 128 bits (representing integer data) 
/// in `a` and then AND with `b`.
__m128i _mm_andnot_si128 (__m128i a, __m128i b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PANDN, a, b);
    }
    else
    {
        return (~a) & b;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(7, -2, 9, 54654);
    __m128i B = _mm_setr_epi32(14, 78, 111, -256);
    __m128i R = _mm_andnot_si128(A, B);
    int[4] correct = [8, 0, 102, -54784];
    assert(R.array == correct);
}

/// Average packed unsigned 16-bit integers in `a` and `b`.
__m128i _mm_avg_epu16 (__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PAVGW, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pavgw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_ARM64)
    {
        return cast(__m128i) vrhadd_u16(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSE2)
    {
        // Exists since LDC 1.18
        return cast(__m128i) __builtin_ia32_pavgw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_optimizations)
    {
        // Generates pavgw even in LDC 1.0, even in -O0
        // But not in ARM
        enum ir = `
            %ia = zext <8 x i16> %0 to <8 x i32>
            %ib = zext <8 x i16> %1 to <8 x i32>
            %isum = add <8 x i32> %ia, %ib
            %isum1 = add <8 x i32> %isum, < i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1>
            %isums = lshr <8 x i32> %isum1, < i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1>
            %r = trunc <8 x i32> %isums to <8 x i16>
            ret <8 x i16> %r`;
        return cast(__m128i) LDCInlineIR!(ir, short8, short8, short8)(cast(short8)a, cast(short8)b);
    }
    else
    {
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 sr = void;
        foreach(i; 0..8)
        {
            sr.ptr[i] = cast(ushort)( (cast(ushort)(sa.array[i]) + cast(ushort)(sb.array[i]) + 1) >> 1 );
        }
        return cast(int4)sr;
    }
}
unittest
{
    __m128i A = _mm_set1_epi16(31);
    __m128i B = _mm_set1_epi16(64);
    short8 avg = cast(short8)(_mm_avg_epu16(A, B));
    foreach(i; 0..8)
        assert(avg.array[i] == 48);
}

/// Average packed unsigned 8-bit integers in `a` and `b`.
__m128i _mm_avg_epu8 (__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PAVGB, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pavgb128(cast(ubyte16)a, cast(ubyte16)b);
    }
    else static if (LDC_with_SSE2)
    {
        // Exists since LDC 1.18
        return cast(__m128i) __builtin_ia32_pavgb128(cast(byte16)a, cast(byte16)b);
    }
    else static if (LDC_with_ARM64)
    {
        return cast(__m128i) vrhadd_u8(cast(byte16)a, cast(byte16)b);
    }
    else static if (LDC_with_optimizations)
    {
        // Generates pavgb even in LDC 1.0, even in -O0
        // But not in ARM
        enum ir = `
            %ia = zext <16 x i8> %0 to <16 x i16>
            %ib = zext <16 x i8> %1 to <16 x i16>
            %isum = add <16 x i16> %ia, %ib
            %isum1 = add <16 x i16> %isum, < i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1>
            %isums = lshr <16 x i16> %isum1, < i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1, i16 1>
            %r = trunc <16 x i16> %isums to <16 x i8>
            ret <16 x i8> %r`;
        return cast(__m128i) LDCInlineIR!(ir, byte16, byte16, byte16)(cast(byte16)a, cast(byte16)b);
    }
    else
    {
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        byte16 sr = void;
        foreach(i; 0..16)
        {
            sr.ptr[i] = cast(ubyte)( (cast(ubyte)(sa.array[i]) + cast(ubyte)(sb.array[i]) + 1) >> 1 );
        }
        return cast(int4)sr;
    }
}
unittest
{
    __m128i A = _mm_set1_epi8(31);
    __m128i B = _mm_set1_epi8(64);
    byte16 avg = cast(byte16)(_mm_avg_epu8(A, B));
    foreach(i; 0..16)
        assert(avg.array[i] == 48);
}

/// Shift `a` left by `bytes` bytes while shifting in zeros.
alias _mm_bslli_si128 = _mm_slli_si128;
unittest
{
    __m128i toShift = _mm_setr_epi8(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
    byte[16] exact =               [0, 0, 0, 0, 0, 0, 1, 2, 3, 4,  5,  6,  7,  8,  9, 10];
    __m128i result = _mm_bslli_si128!5(toShift);
    assert( (cast(byte16)result).array == exact);
}

/// Shift `v` right by `bytes` bytes while shifting in zeros.
alias _mm_bsrli_si128 = _mm_srli_si128;
unittest
{
    __m128i toShift = _mm_setr_epi8(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
    byte[16] exact =               [5, 6, 7, 8, 9,10,11,12,13,14, 15,  0,  0,  0,  0,  0];
    __m128i result = _mm_bsrli_si128!5(toShift);
    assert( (cast(byte16)result).array == exact);
}

/// Cast vector of type `__m128d` to type `__m128`. 
/// Note: Also possible with a regular `cast(__m128)(a)`.
__m128 _mm_castpd_ps (__m128d a) pure @safe
{
    return cast(__m128)a;
}

/// Cast vector of type `__m128d` to type `__m128i`. 
/// Note: Also possible with a regular `cast(__m128i)(a)`.
__m128i _mm_castpd_si128 (__m128d a) pure @safe
{
    return cast(__m128i)a;
}

/// Cast vector of type `__m128` to type `__m128d`. 
/// Note: Also possible with a regular `cast(__m128d)(a)`.
__m128d _mm_castps_pd (__m128 a) pure @safe
{
    return cast(__m128d)a;
}

/// Cast vector of type `__m128` to type `__m128i`. 
/// Note: Also possible with a regular `cast(__m128i)(a)`.
__m128i _mm_castps_si128 (__m128 a) pure @safe
{
    return cast(__m128i)a;
}

/// Cast vector of type `__m128i` to type `__m128d`. 
/// Note: Also possible with a regular `cast(__m128d)(a)`.
__m128d _mm_castsi128_pd (__m128i a) pure @safe
{
    return cast(__m128d)a;
}

/// Cast vector of type `__m128i` to type `__m128`. 
/// Note: Also possible with a regular `cast(__m128)(a)`.
__m128 _mm_castsi128_ps (__m128i a) pure @safe
{
    return cast(__m128)a;
}

/// Invalidate and flush the cache line that contains `p` 
/// from all levels of the cache hierarchy.
void _mm_clflush (const(void)* p) @trusted
{
    static if (GDC_with_SSE2)
    {
        __builtin_ia32_clflush(p);
    }
    else static if (LDC_with_SSE2)
    {
        __builtin_ia32_clflush(cast(void*)p);
    }
    else version(D_InlineAsm_X86)
    {
        asm pure nothrow @nogc @safe
        {
            mov EAX, p;
            clflush [EAX];
        }
    }
    else version(D_InlineAsm_X86_64)
    {
        asm pure nothrow @nogc @safe
        {
            mov RAX, p;
            clflush [RAX];
        }
    }
    else 
    {
        // Do nothing. Invalidating cacheline does
        // not affect correctness.
    }
}
unittest
{
    ubyte[64] cacheline;
    _mm_clflush(cacheline.ptr);
}

/// Compare packed 16-bit integers in `a` and `b` for equality.
__m128i _mm_cmpeq_epi16 (__m128i a, __m128i b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128i)(cast(short8)a == cast(short8)b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pcmpeqw128(cast(short8)a, cast(short8)b);
    }
    else
    {
        return cast(__m128i) equalMask!short8(cast(short8)a, cast(short8)b);
    }
}
unittest
{
    short8   A = [-3, -2, -1,  0,  0,  1,  2,  3];
    short8   B = [ 4,  3,  2,  1,  0, -1, -2, -3];
    short[8] E = [ 0,  0,  0,  0, -1,  0,  0,  0];
    short8   R = cast(short8)(_mm_cmpeq_epi16(cast(__m128i)A, cast(__m128i)B));
    assert(R.array == E);
}

/// Compare packed 32-bit integers in `a` and `b` for equality.
__m128i _mm_cmpeq_epi32 (__m128i a, __m128i b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128i)(cast(int4)a == cast(int4)b);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_pcmpeqd128(a, b);
    }
    else
    {
        return equalMask!__m128i(a, b);
    }
}
unittest
{
    int4   A = [-3, -2, -1,  0];
    int4   B = [ 4, -2,  2,  0];
    int[4] E = [ 0, -1,  0, -1];
    int4   R = cast(int4)(_mm_cmpeq_epi32(A, B));
    assert(R.array == E);
}

/// Compare packed 8-bit integers in `a` and `b` for equality.
__m128i _mm_cmpeq_epi8 (__m128i a, __m128i b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128i)(cast(byte16)a == cast(byte16)b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pcmpeqb128(cast(ubyte16)a, cast(ubyte16)b);
    }
    else
    {
        return cast(__m128i) equalMask!byte16(cast(byte16)a, cast(byte16)b);
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(1, 2, 3, 1, 2, 1, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1);
    __m128i B = _mm_setr_epi8(2, 2, 1, 2, 3, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1, 1);
    byte16 C = cast(byte16) _mm_cmpeq_epi8(A, B);
    byte[16] correct =       [0,-1, 0, 0, 0,-1, 0, 0, 0, 0, 0,-1, 0, 0, 0, -1];
    assert(C.array == correct);
}

/// Compare packed double-precision (64-bit) floating-point elements 
/// in `a` and `b` for equality.
__m128d _mm_cmpeq_pd (__m128d a, __m128d b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(double2)(cast(double2)a == cast(double2)b);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpeqpd(a, b);
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.oeq)(a, b);
    }
}
unittest
{
    double2 A = _mm_setr_pd(1.0, 2.0);
    double2 B = _mm_setr_pd(0.0, 2.0);
    double2 N = _mm_setr_pd(double.nan, double.nan);
    long2 C = cast(long2) _mm_cmpeq_pd(A, B);
    long[2] correctC = [0, -1];
    assert(C.array == correctC);
    long2 D = cast(long2) _mm_cmpeq_pd(N, N);
    long[2] correctD = [0, 0];
    assert(D.array == correctD);
}

/// Compare the lower double-precision (64-bit) floating-point elements
/// in `a` and `b` for equality, store the result in the lower element,
/// and copy the upper element from `a`.
__m128d _mm_cmpeq_sd (__m128d a, __m128d b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128d) __simd(XMM.CMPSD, a, b, 0);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpeqsd(a, b);
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.oeq)(a, b);
    }
}
unittest
{
    double2 A = _mm_setr_pd(0.0, 2.0);
    double2 B = _mm_setr_pd(1.0, 2.0);
    double2 C = _mm_setr_pd(1.0, 3.0);
    double2 D = cast(double2) _mm_cmpeq_sd(A, B);
    long2 E = cast(long2) _mm_cmpeq_sd(B, C);
    double[2] correctD = [0.0, 2.0];
    double two = 2.0;
    long[2] correctE = [-1, *cast(long*)&two];
    assert(D.array == correctD);
    assert(E.array == correctE);
}

/// Compare packed 16-bit integers elements in `a` and `b` for greater-than-or-equal.
/// #BONUS
__m128i _mm_cmpge_epi16 (__m128i a, __m128i b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128i)(cast(short8)a >= cast(short8)b);
    }
    else version (LDC)
    {
        // LDC ARM64: generates cmge since -O1
        return cast(__m128i) greaterOrEqualMask!short8(cast(short8)a, cast(short8)b);
    }
    else
    {        
        return _mm_xor_si128(_mm_cmpeq_epi16(a, b), _mm_cmpgt_epi16(a, b));
    }
}
unittest
{
    short8   A = [-3, -2, -32768,  0,  0,  1,  2,  3];
    short8   B = [ 4,  3,  32767,  1,  0, -1, -2, -3];
    short[8] E = [ 0,  0,      0,  0,  -1, -1, -1, -1];
    short8   R = cast(short8)(_mm_cmpge_epi16(cast(__m128i)A, cast(__m128i)B));
    assert(R.array == E);
}

/// Compare packed double-precision (64-bit) floating-point elements 
/// in `a` and `b` for greater-than-or-equal.
__m128d _mm_cmpge_pd (__m128d a, __m128d b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128d)(a >= b);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpgepd(a, b);
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.oge)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point elements 
/// in `a` and `b` for greater-than-or-equal, store the result in the 
/// lower element, and copy the upper element from `a`.
__m128d _mm_cmpge_sd (__m128d a, __m128d b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128d) __simd(XMM.CMPSD, b, a, 2);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmplesd(b, a);
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.oge)(a, b);
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 0.0);
    __m128d B = _mm_setr_pd(double.nan, 0.0);
    __m128d C = _mm_setr_pd(2.0, 0.0);
    assert( (cast(long2)_mm_cmpge_sd(A, A)).array[0] == -1);
    assert( (cast(long2)_mm_cmpge_sd(A, B)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpge_sd(A, C)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpge_sd(B, A)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpge_sd(B, B)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpge_sd(B, C)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpge_sd(C, A)).array[0] == -1);
    assert( (cast(long2)_mm_cmpge_sd(C, B)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpge_sd(C, C)).array[0] == -1);
}

/// Compare packed 16-bit integers in `a` and `b` for greater-than.
__m128i _mm_cmpgt_epi16 (__m128i a, __m128i b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128i)(cast(short8)a > cast(short8)b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pcmpgtw128(cast(short8)a, cast(short8)b);
    }
    else
    {
        return cast(__m128i) greaterMask!short8(cast(short8)a, cast(short8)b);
    }
}
unittest
{
    short8   A = [-3, -2, -1,  0,  0,  1,  2,  3];
    short8   B = [ 4,  3,  2,  1,  0, -1, -2, -3];
    short[8] E = [ 0,  0,  0,  0,  0, -1, -1, -1];
    short8   R = cast(short8)(_mm_cmpgt_epi16(cast(__m128i)A, cast(__m128i)B));
    assert(R.array == E);
}

/// Compare packed 32-bit integers in `a` and `b` for greater-than.
__m128i _mm_cmpgt_epi32 (__m128i a, __m128i b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128i)(cast(int4)a > cast(int4)b);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_pcmpgtd128(a, b); 
    }
    else
    {
        return cast(__m128i)( greaterMask!int4(a, b));
    }
}
unittest
{
    int4   A = [-3,  2, -1,  0];
    int4   B = [ 4, -2,  2,  0];
    int[4] E = [ 0, -1,  0,  0];
    int4   R = cast(int4)(_mm_cmpgt_epi32(A, B));
    assert(R.array == E);
}

/// Compare packed 8-bit integers in `a` and `b` for greater-than.
__m128i _mm_cmpgt_epi8 (__m128i a, __m128i b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128i)(cast(byte16)a > cast(byte16)b);
    }
    else
    {
        // Note: __builtin_ia32_pcmpgtb128 is buggy, do not use with GDC
        return cast(__m128i) greaterMask!byte16(cast(byte16)a, cast(byte16)b);
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(1, 2, 3, 1,  127, -80, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1);
    __m128i B = _mm_setr_epi8(2, 2, 1, 2, -128, -42, 2, 3, 2, 1, 0, 0, 1, 2, 1, 1);
    byte16 C = cast(byte16) _mm_cmpgt_epi8(A, B);
    byte[16] correct =       [0, 0,-1, 0,   -1,   0, 0, 0,-1,-1,-1, 0, 0, 0,-1, 0];
    __m128i D = _mm_cmpeq_epi8(A, B);
    assert(C.array == correct);
}

/// Compare packed double-precision (64-bit) floating-point elements 
/// in `a` and `b` for greater-than.
__m128d _mm_cmpgt_pd (__m128d a, __m128d b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128d)(a > b);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpgtpd(a, b); 
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.ogt)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point elements 
/// in `a` and `b` for greater-than, store the result in the lower element,
/// and copy the upper element from `a`.
__m128d _mm_cmpgt_sd (__m128d a, __m128d b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128d) __simd(XMM.CMPSD, b, a, 1);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpltsd(b, a);
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.ogt)(a, b);
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 0.0);
    __m128d B = _mm_setr_pd(double.nan, 0.0);
    __m128d C = _mm_setr_pd(2.0, 0.0);
    assert( (cast(long2)_mm_cmpgt_sd(A, A)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpgt_sd(A, B)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpgt_sd(A, C)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpgt_sd(B, A)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpgt_sd(B, B)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpgt_sd(B, C)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpgt_sd(C, A)).array[0] == -1);
    assert( (cast(long2)_mm_cmpgt_sd(C, B)).array[0] ==  0);
    assert( (cast(long2)_mm_cmpgt_sd(C, C)).array[0] ==  0);
}


/// Compare packed 16-bit integers elements in `a` and `b` for greater-than-or-equal.
/// #BONUS
__m128i _mm_cmple_epi16 (__m128i a, __m128i b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128i)(cast(short8)a <= cast(short8)b);
    }
    else version (LDC)
    {
        // LDC ARM64: generates cmge since -O1
        return cast(__m128i) greaterOrEqualMask!short8(cast(short8)b, cast(short8)a);
    }
    else
    {
        return _mm_xor_si128(_mm_cmpeq_epi16(b, a), _mm_cmpgt_epi16(b, a));
    }
}
unittest
{
    short8   A = [-3, -2, -32768,  1,  0,  1,  2,  3];
    short8   B = [ 4,  3,  32767,  0,  0, -1, -2, -3];
    short[8] E = [-1, -1,     -1,  0,  -1, 0,  0,  0];
    short8   R = cast(short8)(_mm_cmple_epi16(cast(__m128i)A, cast(__m128i)B));
    assert(R.array == E);
}

/// Compare packed double-precision (64-bit) floating-point elements 
/// in `a` and `b` for less-than-or-equal.
__m128d _mm_cmple_pd (__m128d a, __m128d b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128d)(a <= b);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmplepd(a, b); 
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.ole)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point elements 
/// in `a` and `b` for less-than-or-equal, store the result in the 
/// lower element, and copy the upper element from `a`.
__m128d _mm_cmple_sd (__m128d a, __m128d b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128d) __simd(XMM.CMPSD, a, b, 2);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmplesd(a, b); 
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.ole)(a, b);
    }
}

/// Compare packed 16-bit integers in `a` and `b` for less-than.
__m128i _mm_cmplt_epi16 (__m128i a, __m128i b) pure @safe
{
    return _mm_cmpgt_epi16(b, a);
}

/// Compare packed 32-bit integers in `a` and `b` for less-than.
__m128i _mm_cmplt_epi32 (__m128i a, __m128i b) pure @safe
{
    return _mm_cmpgt_epi32(b, a);
}

/// Compare packed 8-bit integers in `a` and `b` for less-than.
__m128i _mm_cmplt_epi8 (__m128i a, __m128i b) pure @safe
{
    return _mm_cmpgt_epi8(b, a);
}

/// Compare packed double-precision (64-bit) floating-point elements
/// in `a` and `b` for less-than.
__m128d _mm_cmplt_pd (__m128d a, __m128d b) pure @safe
{
    static if (SIMD_COMPARISON_MASKS_16B)
    {
        return cast(__m128d)(a < b);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpltpd(a, b); 
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.olt)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point elements
/// in `a` and `b` for less-than, store the result in the lower 
/// element, and copy the upper element from `a`.
__m128d _mm_cmplt_sd (__m128d a, __m128d b) pure @safe
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128d) __simd(XMM.CMPSD, a, b, 1);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpltsd(a, b); 
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.olt)(a, b);
    }
}

/// Compare packed double-precision (64-bit) floating-point elements
/// in `a` and `b` for not-equal.
__m128d _mm_cmpneq_pd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpneqpd(a, b); 
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.une)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point elements
/// in `a` and `b` for not-equal, store the result in the lower 
/// element, and copy the upper element from `a`.
__m128d _mm_cmpneq_sd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpneqsd(a, b); 
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.une)(a, b);
    }
}

/// Compare packed double-precision (64-bit) floating-point elements 
/// in `a` and `b` for not-greater-than-or-equal.
__m128d _mm_cmpnge_pd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpngepd(a, b); 
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.ult)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point elements 
/// in `a` and `b` for not-greater-than-or-equal, store the result in 
/// the lower element, and copy the upper element from `a`.
__m128d _mm_cmpnge_sd (__m128d a, __m128d b) pure @safe
{
    // Note: There is no __builtin_ia32_cmpngesd builtin.
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpltsd(b, a); 
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.ult)(a, b);
    }
}

/// Compare packed double-precision (64-bit) floating-point elements 
/// in `a` and `b` for not-greater-than.
__m128d _mm_cmpngt_pd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpngtpd(a, b);
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.ule)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point elements 
/// in `a` and `b` for not-greater-than, store the result in the 
/// lower element, and copy the upper element from `a`.
__m128d _mm_cmpngt_sd (__m128d a, __m128d b) pure @safe
{
    // Note: There is no __builtin_ia32_cmpngtsd builtin.
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmplesd(b, a);
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.ule)(a, b);
    }
}

/// Compare packed double-precision (64-bit) floating-point elements 
/// in `a` and `b` for not-less-than-or-equal.
__m128d _mm_cmpnle_pd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpnlepd(a, b);
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.ugt)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point elements 
/// in `a` and `b` for not-less-than-or-equal, store the result in the 
/// lower element, and copy the upper element from `a`.
__m128d _mm_cmpnle_sd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpnlesd(a, b);
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.ugt)(a, b);
    }
}
 
/// Compare packed double-precision (64-bit) floating-point elements 
/// in `a` and `b` for not-less-than.
__m128d _mm_cmpnlt_pd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpnltpd(a, b);
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.uge)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point elements 
/// in `a` and `b` for not-less-than, store the result in the lower 
/// element, and copy the upper element from `a`.
__m128d _mm_cmpnlt_sd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpnltsd(a, b);
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.uge)(a, b);
    }
}

/// Compare packed double-precision (64-bit) floating-point elements 
/// in `a` and `b` to see if neither is NaN.
__m128d _mm_cmpord_pd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpordpd(a, b);
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.ord)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point elements 
/// in `a` and `b` to see if neither is NaN, store the result in the 
/// lower element, and copy the upper element from `a` to the upper element.
__m128d _mm_cmpord_sd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpordsd(a, b);
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.ord)(a, b);
    }
}

/// Compare packed double-precision (64-bit) floating-point elements 
/// in `a` and `b` to see if either is NaN.
__m128d _mm_cmpunord_pd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpunordpd(a, b);
    }
    else
    {
        return cast(__m128d) cmppd!(FPComparison.uno)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point elements 
/// in `a` and `b` to see if either is NaN, store the result in the lower 
/// element, and copy the upper element from `a` to the upper element.
__m128d _mm_cmpunord_sd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cmpunordsd(a, b);
    }
    else
    {
        return cast(__m128d) cmpsd!(FPComparison.uno)(a, b);
    }
}

/// Compare the lower double-precision (64-bit) floating-point element 
/// in `a` and `b` for equality, and return the boolean result (0 or 1).
int _mm_comieq_sd (__m128d a, __m128d b) pure @safe
{
    // Note: For some of the _mm_comixx_sx intrinsics, NaN semantics of the intrinsic are not the same as the 
    // comisd instruction, it returns false in case of unordered instead.
    //
    // Actually C++ compilers disagree over the meaning of that instruction.
    // GCC will manage NaNs like the comisd instruction (return true if unordered), 
    // but ICC, clang and MSVC will deal with NaN like the Intel Intrinsics Guide says.
    // We choose to do like the most numerous. It seems GCC is buggy with NaNs.
    return a.array[0] == b.array[0];
}
unittest
{
    assert(1 == _mm_comieq_sd(_mm_set_sd(78.0), _mm_set_sd(78.0)));
    assert(0 == _mm_comieq_sd(_mm_set_sd(78.0), _mm_set_sd(-78.0)));
    assert(0 == _mm_comieq_sd(_mm_set_sd(78.0), _mm_set_sd(double.nan)));
    assert(0 == _mm_comieq_sd(_mm_set_sd(double.nan), _mm_set_sd(-4.22)));
    assert(1 == _mm_comieq_sd(_mm_set_sd(0.0), _mm_set_sd(-0.0)));
}

/// Compare the lower double-precision (64-bit) floating-point element 
/// in `a` and `b` for greater-than-or-equal, and return the boolean 
/// result (0 or 1).
int _mm_comige_sd (__m128d a, __m128d b) pure @safe
{
    return a.array[0] >= b.array[0];
}
unittest
{
    assert(1 == _mm_comige_sd(_mm_set_sd(78.0), _mm_set_sd(78.0)));
    assert(1 == _mm_comige_sd(_mm_set_sd(78.0), _mm_set_sd(-78.0)));
    assert(0 == _mm_comige_sd(_mm_set_sd(-78.0), _mm_set_sd(78.0)));
    assert(0 == _mm_comige_sd(_mm_set_sd(78.0), _mm_set_sd(double.nan)));
    assert(0 == _mm_comige_sd(_mm_set_sd(double.nan), _mm_set_sd(-4.22)));
    assert(1 == _mm_comige_sd(_mm_set_sd(-0.0), _mm_set_sd(0.0)));
}

/// Compare the lower double-precision (64-bit) floating-point element 
/// in `a` and `b` for greater-than, and return the boolean result (0 or 1).
int _mm_comigt_sd (__m128d a, __m128d b) pure @safe
{
    return a.array[0] > b.array[0];
}
unittest
{
    assert(0 == _mm_comigt_sd(_mm_set_sd(78.0), _mm_set_sd(78.0)));
    assert(1 == _mm_comigt_sd(_mm_set_sd(78.0), _mm_set_sd(-78.0)));
    assert(0 == _mm_comigt_sd(_mm_set_sd(78.0), _mm_set_sd(double.nan)));
    assert(0 == _mm_comigt_sd(_mm_set_sd(double.nan), _mm_set_sd(-4.22)));
    assert(0 == _mm_comigt_sd(_mm_set_sd(0.0), _mm_set_sd(-0.0)));
}

/// Compare the lower double-precision (64-bit) floating-point element 
/// in `a` and `b` for less-than-or-equal.
int _mm_comile_sd (__m128d a, __m128d b) pure @safe
{
    return a.array[0] <= b.array[0];
}
unittest
{
    assert(1 == _mm_comile_sd(_mm_set_sd(78.0), _mm_set_sd(78.0)));
    assert(0 == _mm_comile_sd(_mm_set_sd(78.0), _mm_set_sd(-78.0)));
    assert(1 == _mm_comile_sd(_mm_set_sd(-78.0), _mm_set_sd(78.0)));
    assert(0 == _mm_comile_sd(_mm_set_sd(78.0), _mm_set_sd(double.nan)));
    assert(0 == _mm_comile_sd(_mm_set_sd(double.nan), _mm_set_sd(-4.22)));
    assert(1 == _mm_comile_sd(_mm_set_sd(0.0), _mm_set_sd(-0.0)));
}

/// Compare the lower double-precision (64-bit) floating-point element 
/// in `a` and `b` for less-than, and return the boolean result (0 or 1).
int _mm_comilt_sd (__m128d a, __m128d b) pure @safe
{
    return a.array[0] < b.array[0];
}
unittest
{
    assert(0 == _mm_comilt_sd(_mm_set_sd(78.0), _mm_set_sd(78.0)));
    assert(0 == _mm_comilt_sd(_mm_set_sd(78.0), _mm_set_sd(-78.0)));
    assert(1 == _mm_comilt_sd(_mm_set_sd(-78.0), _mm_set_sd(78.0)));
    assert(0 == _mm_comilt_sd(_mm_set_sd(78.0), _mm_set_sd(double.nan)));
    assert(0 == _mm_comilt_sd(_mm_set_sd(double.nan), _mm_set_sd(-4.22)));
    assert(0 == _mm_comilt_sd(_mm_set_sd(-0.0), _mm_set_sd(0.0)));
}

/// Compare the lower double-precision (64-bit) floating-point element
/// in `a` and `b` for not-equal, and return the boolean result (0 or 1).
int _mm_comineq_sd (__m128d a, __m128d b) pure @safe
{
    return a.array[0] != b.array[0];
}
unittest
{
    assert(0 == _mm_comineq_sd(_mm_set_sd(78.0), _mm_set_sd(78.0)));
    assert(1 == _mm_comineq_sd(_mm_set_sd(78.0), _mm_set_sd(-78.0)));
    assert(1 == _mm_comineq_sd(_mm_set_sd(78.0), _mm_set_sd(double.nan)));
    assert(1 == _mm_comineq_sd(_mm_set_sd(double.nan), _mm_set_sd(-4.22)));
    assert(0 == _mm_comineq_sd(_mm_set_sd(0.0), _mm_set_sd(-0.0)));
}

/// Convert packed 32-bit integers in `a` to packed double-precision (64-bit)
/// floating-point elements.
__m128d _mm_cvtepi32_pd (__m128i a) pure @trusted
{
    static if (LDC_with_optimizations)
    {
        // Generates cvtdq2pd since LDC 1.0, even without optimizations
        enum ir = `
            %v = shufflevector <4 x i32> %0,<4 x i32> %0, <2 x i32> <i32 0, i32 1>
            %r = sitofp <2 x i32> %v to <2 x double>
            ret <2 x double> %r`;
        return cast(__m128d) LDCInlineIR!(ir, __m128d, __m128i)(a);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cvtdq2pd(a);
    }
    else
    {
        double2 r = void;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        return r;
    }
}
unittest
{
    __m128d A = _mm_cvtepi32_pd(_mm_set1_epi32(54));
    assert(A.array[0] == 54.0);
    assert(A.array[1] == 54.0);
}

/// Convert packed 32-bit integers in `a` to packed single-precision (32-bit) 
/// floating-point elements.
__m128 _mm_cvtepi32_ps(__m128i a) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128)__simd(XMM.CVTDQ2PS, cast(void16) a);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cvtdq2ps(a);
    }
    else static if (LDC_with_optimizations)
    {
        // See #86 for why we had to resort to LLVM IR.
        // Plain code below was leading to catastrophic behaviour. 
        // x86: Generates cvtdq2ps since LDC 1.1.0 -O0
        // ARM: Generats scvtf.4s since LDC 1.8.0 -O0
        enum ir = `
            %r = sitofp <4 x i32> %0 to <4 x float>
            ret <4 x float> %r`;
        return cast(__m128) LDCInlineIR!(ir, float4, int4)(a);
    }
    else
    {
        __m128 res; // PERF =void;
        res.ptr[0] = cast(float)a.array[0];
        res.ptr[1] = cast(float)a.array[1];
        res.ptr[2] = cast(float)a.array[2];
        res.ptr[3] = cast(float)a.array[3];
        return res;
    }
}
unittest
{
    __m128 a = _mm_cvtepi32_ps(_mm_setr_epi32(-1, 0, 1, 1000));
    assert(a.array == [-1.0f, 0.0f, 1.0f, 1000.0f]);
}

/// Convert packed double-precision (64-bit) floating-point elements 
/// in `a` to packed 32-bit integers.
__m128i _mm_cvtpd_epi32 (__m128d a) @trusted
{
    // PERF ARM32
    static if (LDC_with_SSE2)
    {
        return __builtin_ia32_cvtpd2dq(a);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cvtpd2dq(a);
    }
    else static if (LDC_with_ARM64)
    {
        // Get current rounding mode.
        uint fpscr = arm_get_fpcr();
        long2 i;
        switch(fpscr & _MM_ROUND_MASK_ARM)
        {
            default:
            case _MM_ROUND_NEAREST_ARM:     i = vcvtnq_s64_f64(a); break;
            case _MM_ROUND_DOWN_ARM:        i = vcvtmq_s64_f64(a); break;
            case _MM_ROUND_UP_ARM:          i = vcvtpq_s64_f64(a); break;
            case _MM_ROUND_TOWARD_ZERO_ARM: i = vcvtzq_s64_f64(a); break;
        }
        int4 zero = 0;
        return cast(__m128i) shufflevectorLDC!(int4, 0, 2, 4, 6)(cast(int4)i, zero); // PERF: this slow down build for nothing, test without shufflevector
    }
    else
    {
        // PERF ARM32
        __m128i r = _mm_setzero_si128();
        r.ptr[0] = convertDoubleToInt32UsingMXCSR(a.array[0]);
        r.ptr[1] = convertDoubleToInt32UsingMXCSR(a.array[1]);
        return r;
    }
}
unittest
{
    int4 A = _mm_cvtpd_epi32(_mm_set_pd(61.0, 55.0));
    assert(A.array[0] == 55 && A.array[1] == 61 && A.array[2] == 0 && A.array[3] == 0);
}

/// Convert packed double-precision (64-bit) floating-point elements in `v`
/// to packed 32-bit integers
__m64 _mm_cvtpd_pi32 (__m128d v) @safe
{
    return to_m64(_mm_cvtpd_epi32(v));
}
unittest
{
    int2 A = cast(int2) _mm_cvtpd_pi32(_mm_set_pd(61.0, 55.0));
    assert(A.array[0] == 55 && A.array[1] == 61);
}

/// Convert packed double-precision (64-bit) floating-point elements 
/// in `a` to packed single-precision (32-bit) floating-point elements.
__m128 _mm_cvtpd_ps (__m128d a) pure @trusted
{
    static if (LDC_with_SSE2)
    {
        return __builtin_ia32_cvtpd2ps(a); // can't be done with IR unfortunately
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cvtpd2ps(a);
    }
    else
    { 
        __m128 r = void;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        r.ptr[2] = 0;
        r.ptr[3] = 0;
        return r;
    }
}
unittest
{
    __m128d A = _mm_set_pd(5.25, 4.0);
    __m128 B = _mm_cvtpd_ps(A);
    assert(B.array == [4.0f, 5.25f, 0, 0]);
}

/// Convert packed 32-bit integers in `v` to packed double-precision 
/// (64-bit) floating-point elements.
__m128d _mm_cvtpi32_pd (__m64 v) pure @safe
{
    return _mm_cvtepi32_pd(to_m128i(v));
}
unittest
{
    __m128d A = _mm_cvtpi32_pd(_mm_setr_pi32(4, -5));
    assert(A.array[0] == 4.0 && A.array[1] == -5.0);
}

/// Convert packed single-precision (32-bit) floating-point elements 
/// in `a` to packed 32-bit integers
__m128i _mm_cvtps_epi32 (__m128 a) @trusted
{
    static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_cvtps2dq(a);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cvtps2dq(a);
    }
    else static if (LDC_with_ARM64)
    {
        // Get current rounding mode.
        uint fpscr = arm_get_fpcr();
        switch(fpscr & _MM_ROUND_MASK_ARM)
        {
            default:
            case _MM_ROUND_NEAREST_ARM:     return vcvtnq_s32_f32(a);
            case _MM_ROUND_DOWN_ARM:        return vcvtmq_s32_f32(a);
            case _MM_ROUND_UP_ARM:          return vcvtpq_s32_f32(a);
            case _MM_ROUND_TOWARD_ZERO_ARM: return vcvtzq_s32_f32(a);
        }
    }
    else
    {
        __m128i r = void;
        r.ptr[0] = convertFloatToInt32UsingMXCSR(a.array[0]);
        r.ptr[1] = convertFloatToInt32UsingMXCSR(a.array[1]);
        r.ptr[2] = convertFloatToInt32UsingMXCSR(a.array[2]);
        r.ptr[3] = convertFloatToInt32UsingMXCSR(a.array[3]);
        return r;
    }
}
unittest
{
    // GDC bug #98607
    // https://gcc.gnu.org/bugzilla/show_bug.cgi?id=98607
    // GDC does not provide optimization barrier for rounding mode.
    // Workarounded with different literals. This bug will likely only manifest in unittest.
    // GCC people provided no actual fix and instead say other compilers are buggy... when they aren't.

    uint savedRounding = _MM_GET_ROUNDING_MODE();

    _MM_SET_ROUNDING_MODE(_MM_ROUND_NEAREST);
    __m128i A = _mm_cvtps_epi32(_mm_setr_ps(1.4f, -2.1f, 53.5f, -2.9f));
    assert(A.array == [1, -2, 54, -3]);

    _MM_SET_ROUNDING_MODE(_MM_ROUND_DOWN);
    A = _mm_cvtps_epi32(_mm_setr_ps(1.3f, -2.11f, 53.4f, -2.8f));
    assert(A.array == [1, -3, 53, -3]);

    _MM_SET_ROUNDING_MODE(_MM_ROUND_UP);
    A = _mm_cvtps_epi32(_mm_setr_ps(1.3f, -2.12f, 53.6f, -2.7f));
    assert(A.array == [2, -2, 54, -2]);

    _MM_SET_ROUNDING_MODE(_MM_ROUND_TOWARD_ZERO);
    A = _mm_cvtps_epi32(_mm_setr_ps(1.4f, -2.17f, 53.8f, -2.91f));
    assert(A.array == [1, -2, 53, -2]);

    _MM_SET_ROUNDING_MODE(savedRounding);
}

/// Convert packed single-precision (32-bit) floating-point elements 
/// in `a` to packed double-precision (64-bit) floating-point elements.
__m128d _mm_cvtps_pd (__m128 a) pure @trusted
{
    static if (LDC_with_optimizations)
    {
        // Generates cvtps2pd since LDC 1.0 -O0
        enum ir = `
            %v = shufflevector <4 x float> %0,<4 x float> %0, <2 x i32> <i32 0, i32 1>
            %r = fpext <2 x float> %v to <2 x double>
            ret <2 x double> %r`;
        return cast(__m128d) LDCInlineIR!(ir, __m128d, __m128)(a);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cvtps2pd(a);
    }
    else
    {
        double2 r = void;
        r.ptr[0] = a.array[0];
        r.ptr[1] = a.array[1];
        return r;
    }
}
unittest
{
    __m128d A = _mm_cvtps_pd(_mm_set1_ps(54.0f));
    assert(A.array[0] == 54.0);
    assert(A.array[1] == 54.0);
}

/// Copy the lower double-precision (64-bit) floating-point element of `a`.
double _mm_cvtsd_f64 (__m128d a) pure @safe
{
    return a.array[0];
}

/// Convert the lower double-precision (64-bit) floating-point element
/// in `a` to a 32-bit integer.
int _mm_cvtsd_si32 (__m128d a) @safe
{
    static if (LDC_with_SSE2)
    {
        return __builtin_ia32_cvtsd2si(a);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cvtsd2si(a);
    }
    else
    {
        return convertDoubleToInt32UsingMXCSR(a[0]);
    }
}
unittest
{
    assert(4 == _mm_cvtsd_si32(_mm_set1_pd(4.0)));
}

/// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer.
long _mm_cvtsd_si64 (__m128d a) @trusted
{
    static if (LDC_with_SSE2)
    {
        version (X86_64)
        {
            return __builtin_ia32_cvtsd2si64(a);
        }
        else
        {
            // Note: In 32-bit x86, there is no way to convert from float/double to 64-bit integer
            // using SSE instructions only. So the builtin doesn't exist for this arch.
            return convertDoubleToInt64UsingMXCSR(a[0]);
        }
    }
    else
    {
        return convertDoubleToInt64UsingMXCSR(a.array[0]);
    }
}
unittest
{
    assert(-4 == _mm_cvtsd_si64(_mm_set1_pd(-4.0)));

    uint savedRounding = _MM_GET_ROUNDING_MODE();

    _MM_SET_ROUNDING_MODE(_MM_ROUND_NEAREST);
    assert(-56468486186 == _mm_cvtsd_si64(_mm_set1_pd(-56468486186.49)));

    _MM_SET_ROUNDING_MODE(_MM_ROUND_DOWN);
    assert(-56468486187 == _mm_cvtsd_si64(_mm_set1_pd(-56468486186.1)));

    _MM_SET_ROUNDING_MODE(_MM_ROUND_UP);
    assert(56468486187 == _mm_cvtsd_si64(_mm_set1_pd(56468486186.1)));

    _MM_SET_ROUNDING_MODE(_MM_ROUND_TOWARD_ZERO);
    assert(-56468486186 == _mm_cvtsd_si64(_mm_set1_pd(-56468486186.9)));

    _MM_SET_ROUNDING_MODE(savedRounding);
}

deprecated("Use _mm_cvtsd_si64 instead") alias _mm_cvtsd_si64x = _mm_cvtsd_si64; ///

/// Convert the lower double-precision (64-bit) floating-point element in `b` to a single-precision (32-bit) 
/// floating-point element, store that in the lower element of result, and copy the upper 3 packed elements from `a`
/// to the upper elements of result.
__m128 _mm_cvtsd_ss (__m128 a, __m128d b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cvtsd2ss(a, b); 
    }
    else
    {
        // Generates cvtsd2ss since LDC 1.3 -O0
        a.ptr[0] = b.array[0];
        return a;
    }
}
unittest
{
    __m128 R = _mm_cvtsd_ss(_mm_set1_ps(4.0f), _mm_set1_pd(3.0));
    assert(R.array == [3.0f, 4.0f, 4.0f, 4.0f]);
}

/// Get the lower 32-bit integer in `a`.
int _mm_cvtsi128_si32 (__m128i a) pure @safe
{
    return a.array[0];
}

/// Get the lower 64-bit integer in `a`.
long _mm_cvtsi128_si64 (__m128i a) pure @safe
{
    long2 la = cast(long2)a;
    return la.array[0];
}
deprecated("Use _mm_cvtsi128_si64 instead") alias _mm_cvtsi128_si64x = _mm_cvtsi128_si64;

/// Convert the signed 32-bit integer `b` to a double-precision (64-bit) floating-point element, store that in the 
/// lower element of result, and copy the upper element from `a` to the upper element of result.
__m128d _mm_cvtsi32_sd(__m128d a, int b) pure @trusted
{
    a.ptr[0] = cast(double)b;
    return a;
}
unittest
{
    __m128d a = _mm_cvtsi32_sd(_mm_set1_pd(0.0f), 42);
    assert(a.array == [42.0, 0]);
}

/// Copy 32-bit integer `a` to the lower element of result, and zero the upper elements.
__m128i _mm_cvtsi32_si128 (int a) pure @trusted
{
    int4 r = [0, 0, 0, 0];
    r.ptr[0] = a;
    return r;
}
unittest
{
    __m128i a = _mm_cvtsi32_si128(65);
    assert(a.array == [65, 0, 0, 0]);
}

/// Convert the signed 64-bit integer `b` to a double-precision (64-bit) floating-point element, store the result in 
/// the lower element of result, and copy the upper element from `a` to the upper element of result.

__m128d _mm_cvtsi64_sd(__m128d a, long b) pure @trusted
{
    a.ptr[0] = cast(double)b;
    return a;
}
unittest
{
    __m128d a = _mm_cvtsi64_sd(_mm_set1_pd(0.0f), 42);
    assert(a.array == [42.0, 0]);
}

/// Copy 64-bit integer `a` to the lower element of result, and zero the upper element.
__m128i _mm_cvtsi64_si128 (long a) pure @trusted
{
    long2 r = [0, 0];
    r.ptr[0] = a;
    return cast(__m128i)(r);
}

deprecated("Use _mm_cvtsi64_sd instead") alias _mm_cvtsi64x_sd = _mm_cvtsi64_sd; ///
deprecated("Use _mm_cvtsi64_si128 instead") alias _mm_cvtsi64x_si128 = _mm_cvtsi64_si128; ///

/// Convert the lower single-precision (32-bit) floating-point element in `b` to a double-precision (64-bit) 
/// floating-point element, store that in the lower element of result, and copy the upper element from `a` to the upper 
// element of result.
double2 _mm_cvtss_sd(double2 a, float4 b) pure @trusted
{
    a.ptr[0] = b.array[0];
    return a;
}
unittest
{
    __m128d a = _mm_cvtss_sd(_mm_set1_pd(0.0f), _mm_set1_ps(42.0f));
    assert(a.array == [42.0, 0]);
}

/// Convert the lower single-precision (32-bit) floating-point element in `a` to a 64-bit integer with truncation.
long _mm_cvttss_si64 (__m128 a) pure @safe
{
    return cast(long)(a.array[0]); // Generates cvttss2si as expected
}
unittest
{
    assert(1 == _mm_cvttss_si64(_mm_setr_ps(1.9f, 2.0f, 3.0f, 4.0f)));
}

/// Convert packed double-precision (64-bit) floating-point elements in `a` to packed 32-bit integers with truncation.
/// Put zeroes in the upper elements of result.
__m128i _mm_cvttpd_epi32 (__m128d a) pure @trusted
{
    static if (LDC_with_SSE2)
    {
        return __builtin_ia32_cvttpd2dq(a);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_cvttpd2dq(a);
    }
    else
    {
        // Note: doesn't generate cvttpd2dq as of LDC 1.13
        __m128i r; // PERF =void;
        r.ptr[0] = cast(int)a.array[0];
        r.ptr[1] = cast(int)a.array[1];
        r.ptr[2] = 0;
        r.ptr[3] = 0;
        return r;
    }
}
unittest
{
    __m128i R = _mm_cvttpd_epi32(_mm_setr_pd(-4.9, 45641.5f));
    assert(R.array == [-4, 45641, 0, 0]);
}

/// Convert packed double-precision (64-bit) floating-point elements in `v` 
/// to packed 32-bit integers with truncation.
__m64 _mm_cvttpd_pi32 (__m128d v) pure @safe
{
    return to_m64(_mm_cvttpd_epi32(v));
}
unittest
{
    int2 R = cast(int2) _mm_cvttpd_pi32(_mm_setr_pd(-4.9, 45641.7f));
    int[2] correct = [-4, 45641];
    assert(R.array == correct);
}

/// Convert packed single-precision (32-bit) floating-point elements in `a` to packed 32-bit integers with truncation.
__m128i _mm_cvttps_epi32 (__m128 a) pure @trusted
{
    // x86: Generates cvttps2dq since LDC 1.3 -O2
    // ARM64: generates fcvtze since LDC 1.8 -O2
    __m128i r; // PERF = void;
    r.ptr[0] = cast(int)a.array[0];
    r.ptr[1] = cast(int)a.array[1];
    r.ptr[2] = cast(int)a.array[2];
    r.ptr[3] = cast(int)a.array[3];
    return r;
}
unittest
{
    __m128i R = _mm_cvttps_epi32(_mm_setr_ps(-4.9, 45641.5f, 0.0f, 1.0f));
    assert(R.array == [-4, 45641, 0, 1]);
}

/// Convert the lower double-precision (64-bit) floating-point element in `a` to a 32-bit integer with truncation.
int _mm_cvttsd_si32 (__m128d a)
{
    // Generates cvttsd2si since LDC 1.3 -O0
    return cast(int)a.array[0];
}

/// Convert the lower double-precision (64-bit) floating-point element in `a` to a 64-bit integer with truncation.
long _mm_cvttsd_si64 (__m128d a)
{
    // Generates cvttsd2si since LDC 1.3 -O0
    // but in 32-bit instead, it's a long sequence that resort to FPU
    return cast(long)a.array[0];
}

deprecated("Use _mm_cvttsd_si64 instead") alias _mm_cvttsd_si64x = _mm_cvttsd_si64; ///

/// Divide packed double-precision (64-bit) floating-point elements in `a` by packed elements in `b`.
__m128d _mm_div_pd(__m128d a, __m128d b) pure @safe
{
    pragma(inline, true);
    return a / b;
}

__m128d _mm_div_sd(__m128d a, __m128d b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_divsd(a, b);
    }
    else version(DigitalMars)
    {
        // Work-around for https://issues.dlang.org/show_bug.cgi?id=19599
        // Note that this is unneeded since DMD >= 2.094.0 at least, haven't investigated again
        asm pure nothrow @nogc @trusted { nop;}
        a.array[0] = a.array[0] / b.array[0];
        return a;
    }
    else
    {
        a.ptr[0] /= b.array[0];
        return a;
    }
}
unittest
{
    __m128d a = [2.0, 4.5];
    a = _mm_div_sd(a, a);
    assert(a.array == [1.0, 4.5]);
}

/// Extract a 16-bit integer from `v`, selected with `index`.
/// Warning: the returned value is zero-extended to 32-bits.
int _mm_extract_epi16(__m128i v, int index) pure @safe
{
    short8 r = cast(short8)v;
    return cast(ushort)(r.array[index & 7]);
}
unittest
{
    __m128i A = _mm_set_epi16(7, 6, 5, 4, 3, 2, 1, -1);
    assert(_mm_extract_epi16(A, 6) == 6);
    assert(_mm_extract_epi16(A, 0) == 65535);
    assert(_mm_extract_epi16(A, 5 + 8) == 5);
}

/// Copy `v`, and insert the 16-bit integer `i` at the location specified by `index`.
__m128i _mm_insert_epi16 (__m128i v, int i, int index) @trusted
{
    short8 r = cast(short8)v;
    r.ptr[index & 7] = cast(short)i;
    return cast(__m128i)r;
}
unittest
{
    __m128i A = _mm_set_epi16(7, 6, 5, 4, 3, 2, 1, 0);
    short8 R = cast(short8) _mm_insert_epi16(A, 42, 6);
    short[8] correct = [0, 1, 2, 3, 4, 5, 42, 7];
    assert(R.array == correct);
}

/// Perform a serializing operation on all load-from-memory instructions that were issued prior 
/// to this instruction. Guarantees that every load instruction that precedes, in program order, 
/// is globally visible before any load instruction which follows the fence in program order.
void _mm_lfence() @trusted
{
    version(GNU)
    {
        static if (GDC_with_SSE2)
        {
            __builtin_ia32_lfence();
        }
        else version(X86)
        {
            asm pure nothrow @nogc @trusted
            {
                "lfence;\n" : : : ;
            }
        }
        else
            static assert(false);
    }
    else static if (LDC_with_SSE2)
    {
        __builtin_ia32_lfence();
    }
    else static if (LDC_with_ARM64)
    {
         __builtin_arm_dmb(9);  // dmb ishld
    }
    else static if (DMD_with_asm)
    {
        asm nothrow @nogc pure @safe
        {
            lfence;
        }
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
    _mm_lfence();
}

/// Load 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements) from memory.
/// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
__m128d _mm_load_pd (const(double) * mem_addr) pure
{
    pragma(inline, true);
    __m128d* aligned = cast(__m128d*)mem_addr;
    return *aligned;
}
unittest
{
    align(16) double[2] S = [-5.0, 7.0];
    __m128d R = _mm_load_pd(S.ptr);
    assert(R.array == S);
}

/// Load a double-precision (64-bit) floating-point element from memory into both elements of dst.
/// `mem_addr` does not need to be aligned on any particular boundary.
__m128d _mm_load_pd1 (const(double)* mem_addr) pure
{
    double m = *mem_addr;
    __m128d r; // PERF =void;
    r.ptr[0] = m;
    r.ptr[1] = m;
    return r;
}
unittest
{
    double what = 4;
    __m128d R = _mm_load_pd1(&what);
    double[2] correct = [4.0, 4];
    assert(R.array == correct);
}

/// Load a double-precision (64-bit) floating-point element from memory into the lower of result, and zero the upper 
/// element. `mem_addr` does not need to be aligned on any particular boundary.
__m128d _mm_load_sd (const(double)* mem_addr) pure @trusted
{
    double2 r = [0, 0];
    r.ptr[0] = *mem_addr;
    return r;
}
unittest
{
    double x = -42;
    __m128d a = _mm_load_sd(&x);
    assert(a.array == [-42.0, 0.0]);
}

/// Load 128-bits of integer data from memory into dst. 
/// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
__m128i _mm_load_si128 (const(__m128i)* mem_addr) pure @safe
{
    pragma(inline, true);
    return *mem_addr;
}
unittest
{
    align(16) int[4] correct = [-1, 2, 3, 4];
    int4 A = cast(int4) _mm_load_si128(cast(__m128i*) correct.ptr);
    assert(A.array == correct);
}

alias _mm_load1_pd = _mm_load_pd1; ///

/// Load a double-precision (64-bit) floating-point element from memory into the upper element of result, and copy the 
/// lower element from `a` to result. `mem_addr` does not need to be aligned on any particular boundary.
__m128d _mm_loadh_pd (__m128d a, const(double)* mem_addr) pure @trusted
{
    pragma(inline, true);
    a.ptr[1] = *mem_addr;
    return a;
}
unittest
{
    double A = 7.0;
    __m128d B = _mm_setr_pd(4.0, -5.0);
    __m128d R = _mm_loadh_pd(B, &A);
    double[2] correct = [ 4.0, 7.0 ];
    assert(R.array == correct);
}

/// Load 64-bit integer from memory into the first element of result. Zero out the other.
/// Note: strange signature since the memory doesn't have to aligned, and should point to addressable 64-bit, not 128-bit.
/// You may use `_mm_loadu_si64` instead.
__m128i _mm_loadl_epi64 (const(__m128i)* mem_addr) pure @trusted
{
    pragma(inline, true);
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.LODQ, *cast(__m128i*)mem_addr);
    }
    else
    {
        auto pLong = cast(const(long)*)mem_addr;
        long2 r = [0, 0];
        r.ptr[0] = *pLong;
        return cast(__m128i)(r);
    }
}
unittest
{
    long A = 0x7878787870707070;
    long2 R = cast(long2) _mm_loadl_epi64(cast(__m128i*)&A);
    long[2] correct = [0x7878787870707070, 0];
    assert(R.array == correct);
}

/// Load a double-precision (64-bit) floating-point element from memory into the lower element of result, and copy the 
/// upper element from `a` to result. mem_addr does not need to be aligned on any particular boundary.
__m128d _mm_loadl_pd (__m128d a, const(double)* mem_addr) pure @trusted
{
    a.ptr[0] = *mem_addr;
    return a;
}
unittest
{
    double A = 7.0;
    __m128d B = _mm_setr_pd(4.0, -5.0);
    __m128d R = _mm_loadl_pd(B, &A);
    double[2] correct = [ 7.0, -5.0 ];
    assert(R.array == correct);
}

/// Load 2 double-precision (64-bit) floating-point elements from memory into result in reverse order. 
/// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
__m128d _mm_loadr_pd (const(double)* mem_addr) pure @trusted
{
    __m128d a = *cast(__m128d*)(mem_addr);
    __m128d r; // PERF =void;
    r.ptr[0] = a.array[1];
    r.ptr[1] = a.array[0];
    return r;
}
unittest
{
    align(16) double[2] A = [56.0, -74.0];
    __m128d R = _mm_loadr_pd(A.ptr);
    double[2] correct = [-74.0, 56.0];
    assert(R.array == correct);
}

/// Load 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements) from memory. 
/// `mem_addr` does not need to be aligned on any particular boundary.
__m128d _mm_loadu_pd (const(double)* mem_addr) pure @trusted
{
    pragma(inline, true);
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_loadupd(mem_addr); 
    }
    else static if (LDC_with_optimizations)
    {
        return loadUnaligned!(double2)(mem_addr);
    }
    else version(DigitalMars)
    {
        // Apparently inside __simd you can use aligned dereferences without fear.
        // That was issue 23048 on dlang's Bugzilla.
        static if (DMD_with_DSIMD)
        {
            return cast(__m128d)__simd(XMM.LODUPD, *cast(double2*)mem_addr);
        }
        else static if (SSESizedVectorsAreEmulated)
        {
            // Since this vector is emulated, it doesn't have alignement constraints
            // and as such we can just cast it.
            return *cast(__m128d*)(mem_addr);
        }
        else
        {
            __m128d result;
            result.ptr[0] = mem_addr[0];
            result.ptr[1] = mem_addr[1];
            return result;
        }
    }
    else
    {
        __m128d result;
        result.ptr[0] = mem_addr[0];
        result.ptr[1] = mem_addr[1];
        return result;
    }
}
unittest
{
    double[2] A = [56.0, -75.0];
    __m128d R = _mm_loadu_pd(A.ptr);
    double[2] correct = [56.0, -75.0];
    assert(R.array == correct);
}

/// Load 128-bits of integer data from memory. `mem_addr` does not need to be aligned on any particular boundary.
__m128i _mm_loadu_si128 (const(__m128i)* mem_addr) pure @trusted
{
    // PERF DMD
    pragma(inline, true);
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_loaddqu(cast(const(char*))mem_addr);
    }
    else static if (LDC_with_optimizations)
    {
        return loadUnaligned!(__m128i)(cast(int*)mem_addr);
    }
    else
    {
        const(int)* p = cast(const(int)*)mem_addr;
        __m128i r = void;
        r.ptr[0] = p[0];
        r.ptr[1] = p[1];
        r.ptr[2] = p[2];
        r.ptr[3] = p[3];
        return r;
    }
}
unittest
{
    align(16) int[4] correct = [-1, 2, -3, 4];
    int4 A = cast(int4) _mm_loadu_si128(cast(__m128i*) correct.ptr);
    assert(A.array == correct);
}

/// Load unaligned 16-bit integer from memory into the first element, fill with zeroes otherwise.
__m128i _mm_loadu_si16(const(void)* mem_addr) pure @trusted // TODO: should be @system actually
{
    static if (DMD_with_DSIMD)
    {
        int r = *cast(short*)(mem_addr);
        return cast(__m128i) __simd(XMM.LODD, *cast(__m128i*)&r);
    }
    else version(DigitalMars)
    {
        // Workaround issue: https://issues.dlang.org/show_bug.cgi?id=21672
        // DMD cannot handle the below code...
        align(16) short[8] r = [0, 0, 0, 0, 0, 0, 0, 0];
        r[0] = *cast(short*)(mem_addr);
        return *cast(int4*)(r.ptr);
    }
    else
    {
        short r = *cast(short*)(mem_addr);
        short8 result = [0, 0, 0, 0, 0, 0, 0, 0];
        result.ptr[0] = r;
        return cast(__m128i)result;
    }
}
unittest
{
    short r = 13;
    short8 A = cast(short8) _mm_loadu_si16(&r);
    short[8] correct = [13, 0, 0, 0, 0, 0, 0, 0];
    assert(A.array == correct);
}

/// Load unaligned 32-bit integer from memory into the first element of result.
__m128i _mm_loadu_si32 (const(void)* mem_addr) pure @trusted // TODO: should be @system actually
{
    pragma(inline, true);
    int r = *cast(int*)(mem_addr);
    int4 result = [0, 0, 0, 0];
    result.ptr[0] = r;
    return result;
}
unittest
{
    int r = 42;
    __m128i A = _mm_loadu_si32(&r);
    int[4] correct = [42, 0, 0, 0];
    assert(A.array == correct);
}

/// Load unaligned 64-bit integer from memory into the first element of result.
/// Upper 64-bit is zeroed.
__m128i _mm_loadu_si64 (const(void)* mem_addr) pure @system
{
    pragma(inline, true);
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.LODQ, *cast(__m128i*)mem_addr);
    }
    else
    {    
        auto pLong = cast(const(long)*)mem_addr;
        long2 r = [0, 0];
        r.ptr[0] = *pLong;
        return cast(__m128i)r;
    }
}
unittest
{
    long r = 446446446446;
    long2 A = cast(long2) _mm_loadu_si64(&r);
    long[2] correct = [446446446446, 0];
    assert(A.array == correct);
}

/// Multiply packed signed 16-bit integers in `a` and `b`, producing intermediate
/// signed 32-bit integers. Horizontally add adjacent pairs of intermediate 32-bit integers,
/// and pack the results in destination.
__m128i _mm_madd_epi16 (__m128i a, __m128i b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pmaddwd128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pmaddwd128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_optimizations)
    {
        // 5 inst with arm64 + LDC 1.32 + -O1
        enum ir = `            
            %ia = sext <8 x i16> %0 to <8 x i32>
            %ib = sext <8 x i16> %1 to <8 x i32>
            %p = mul <8 x i32> %ia, %ib
            %p_even = shufflevector <8 x i32> %p, <8 x i32> undef, <4 x i32> <i32 0, i32 2,i32 4, i32 6>
            %p_odd  = shufflevector <8 x i32> %p, <8 x i32> undef, <4 x i32> <i32 1, i32 3,i32 5, i32 7>            
            %p_sum = add <4 x i32> %p_even, %p_odd
            ret <4 x i32> %p_sum`;
        return cast(__m128i) LDCInlineIR!(ir, int4, short8, short8)(cast(short8)a, cast(short8)b);
    }
    else
    {
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        int4 r;
        foreach(i; 0..4)
        {
            r.ptr[i] = sa.array[2*i] * sb.array[2*i] + sa.array[2*i+1] * sb.array[2*i+1];
        }
        return r;
    }
}
unittest
{
    short8 A = [0, 1, 2, 3, -32768, -32768, 32767, 32767];
    short8 B = [0, 1, 2, 3, -32768, -32768, 32767, 32767];
    int4 R = _mm_madd_epi16(cast(__m128i)A, cast(__m128i)B);
    int[4] correct = [1, 13, -2147483648, 2*32767*32767];
    assert(R.array == correct);
}

/// Conditionally store 8-bit integer elements from `a` into memory using `mask`
/// (elements are not stored when the highest bit is not set in the corresponding element)
/// and a non-temporal memory hint. `mem_addr` does not need to be aligned on any particular
/// boundary.
void _mm_maskmoveu_si128 (__m128i a, __m128i mask, void* mem_addr) @trusted
{
    static if (GDC_with_SSE2)
    {    
        return __builtin_ia32_maskmovdqu(cast(ubyte16)a, cast(ubyte16)mask, cast(char*)mem_addr);
    }
    else static if (LDC_with_SSE2)
    {
        return __builtin_ia32_maskmovdqu(cast(byte16)a, cast(byte16)mask, cast(char*)mem_addr);
    }
    else static if (LDC_with_ARM64)
    {
        // PERF: catastrophic on ARM32
        byte16 bmask  = cast(byte16)mask;
        byte16 shift = 7;
        bmask = bmask >> shift; // sign-extend to have a 0xff or 0x00 mask
        mask = cast(__m128i) bmask;
        __m128i dest = loadUnaligned!__m128i(cast(int*)mem_addr);
        dest = (a & mask) | (dest & ~mask);
        storeUnaligned!__m128i(dest, cast(int*)mem_addr);
    }
    else
    {
        byte16 b = cast(byte16)a;
        byte16 m = cast(byte16)mask;
        byte* dest = cast(byte*)(mem_addr);
        foreach(j; 0..16)
        {
            if (m.array[j] & 128)
            {
                dest[j] = b.array[j];
            }
        }
    }
}
unittest
{
    ubyte[16] dest =           [42,42,42,42,42,42,42,42,42,42,42,42,42,42,42,42];
    __m128i mask = _mm_setr_epi8(0,-1, 0,-1,-1, 1,-1,-1, 0,-1,-4,-1,-1, 0,-127, 0);
    __m128i A    = _mm_setr_epi8(0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15);
    _mm_maskmoveu_si128(A, mask, dest.ptr);
    ubyte[16] correct =        [42, 1,42, 3, 4,42, 6, 7,42, 9,10,11,12,42,14,42];
    assert(dest == correct);
}

/// Compare packed signed 16-bit integers in `a` and `b`, and return packed maximum values.
__m128i _mm_max_epi16 (__m128i a, __m128i b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pmaxsw128(cast(short8)a, cast(short8)b);
    }
    else version(LDC)
    {
        // x86: pmaxsw since LDC 1.0 -O1
        // ARM: smax.8h since LDC 1.5 -01
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            short8 greater = sa > sb;
        else
            short8 greater = greaterMask!short8(sa, sb);
        return cast(__m128i)( (greater & sa) | (~greater & sb) );
    }
    else
    {
        __m128i lowerShorts = _mm_cmpgt_epi16(a, b); // ones where a should be selected, b else
        __m128i aTob = _mm_xor_si128(a, b); // a ^ (a ^ b) == b
        __m128i mask = _mm_and_si128(aTob, lowerShorts);
        return _mm_xor_si128(b, mask);
    }
}
unittest
{
    short8 R = cast(short8) _mm_max_epi16(_mm_setr_epi16(32767, 1, -4, -8, 9,  7, 0,-57),
                                          _mm_setr_epi16(-4,-8,  9,  7, 0,-32768, 0,  0));
    short[8] correct =                                  [32767, 1,  9,  7, 9,  7, 0,  0];
    assert(R.array == correct);
}

/// Compare packed unsigned 8-bit integers in a and b, and return packed maximum values.
__m128i _mm_max_epu8 (__m128i a, __m128i b) pure @safe
{
    // PERF DMD
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pmaxub128(cast(ubyte16)a, cast(ubyte16)b);
    }
    else version(LDC)
    {
        // x86: pmaxub since LDC 1.0.0 -O1
        // ARM64: umax.16b since LDC 1.5.0 -O1
        // PERF: catastrophic on ARM32
        ubyte16 sa = cast(ubyte16)a;
        ubyte16 sb = cast(ubyte16)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            ubyte16 greater = (cast(ubyte16)a > cast(ubyte16)b);
        else
            ubyte16 greater = cast(ubyte16) greaterMask!ubyte16(sa, sb);
        return cast(__m128i)( (greater & sa) | (~greater & sb) );
    }
    else
    {
        // PERF: use algorithm from _mm_max_epu16
        __m128i value128 = _mm_set1_epi8(-128);
        __m128i higher = _mm_cmpgt_epi8(_mm_add_epi8(a, value128), _mm_add_epi8(b, value128)); // signed comparison
        __m128i aTob = a ^ b; // a ^ (a ^ b) == b
        __m128i mask = aTob & higher;
        return b ^ mask;

    }
}
unittest
{
    byte16 R = cast(byte16) _mm_max_epu8(_mm_setr_epi8(45, 1, -4, -8, 9,  7, 0,-57, -4,-8,  9,  7, 0,-57, 0,  0),
                                         _mm_setr_epi8(-4,-8,  9,  7, 0,-57, 0,  0, 45, 1, -4, -8, 9,  7, 0,-57));
    byte[16] correct =                                [-4,-8, -4, -8, 9,-57, 0,-57, -4,-8, -4, -8, 9,-57, 0,-57];
    assert(R.array == correct);
}

/// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`, and return 
/// packed maximum values.
__m128d _mm_max_pd (__m128d a, __m128d b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_maxpd(a, b);
    }
    else
    {
        // x86: Generates maxpd starting with LDC 1.9 -O2
        a.ptr[0] = (a.array[0] > b.array[0]) ? a.array[0] : b.array[0];
        a.ptr[1] = (a.array[1] > b.array[1]) ? a.array[1] : b.array[1];
        return a;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(4.0, 1.0);
    __m128d B = _mm_setr_pd(1.0, 8.0);
    __m128d M = _mm_max_pd(A, B);
    assert(M.array[0] == 4.0);
    assert(M.array[1] == 8.0);
}

/// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b`, store the maximum value in the 
/// lower element of result, and copy the upper element from `a` to the upper element of result.
__m128d _mm_max_sd (__m128d a, __m128d b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_maxsd(a, b);
    }
    else
    {
         __m128d r = a;
        // Generates maxsd starting with LDC 1.3
        r.ptr[0] = (a.array[0] > b.array[0]) ? a.array[0] : b.array[0];
        return r;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 1.0);
    __m128d B = _mm_setr_pd(4.0, 2.0);
    __m128d M = _mm_max_sd(A, B);
    assert(M.array[0] == 4.0);
    assert(M.array[1] == 1.0);
}

/// Perform a serializing operation on all load-from-memory and store-to-memory instructions that were issued prior to 
/// this instruction. Guarantees that every memory access that precedes, in program order, the memory fence instruction 
/// is globally visible before any memory instruction which follows the fence in program order.
void _mm_mfence() @trusted // not pure!
{
    version(GNU)
    {
        static if (GDC_with_SSE2)
        {
            __builtin_ia32_mfence();
        }
        else version(X86)
        {
            asm pure nothrow @nogc @trusted
            {
                "mfence;\n" : : : ;
            }
        }
        else
            static assert(false);
    }
    else static if (LDC_with_SSE2)
    {
        __builtin_ia32_mfence();
    }
    else static if (DMD_with_asm)
    {
        asm nothrow @nogc pure @safe
        {
            mfence;
        }
    }
    else version(LDC)
    {
        // Note: will generate the DMB ish instruction on ARM
        llvm_memory_fence();
    }
    else
        static assert(false);
}
unittest
{
    _mm_mfence();
}

/// Compare packed signed 16-bit integers in `a` and `b`, and return packed minimum values.
__m128i _mm_min_epi16 (__m128i a, __m128i b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pminsw128(cast(short8)a, cast(short8)b);
    }
    else version(LDC)
    {
        // x86: pminsw since LDC 1.0 -O1
        // ARM64: smin.8h since LDC 1.5 -01
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            short8 greater = sa > sb;
        else
            short8 greater = greaterMask!short8(sa, sb);
        return cast(__m128i)( (~greater & sa) | (greater & sb) );
    }
    else
    {
        __m128i lowerShorts = _mm_cmplt_epi16(a, b); // ones where a should be selected, b else
        __m128i aTob = _mm_xor_si128(a, b); // a ^ (a ^ b) == b
        __m128i mask = _mm_and_si128(aTob, lowerShorts);
        return _mm_xor_si128(b, mask);
    }
}
unittest
{
    short8 R = cast(short8) _mm_min_epi16(_mm_setr_epi16(45, 1, -4, -8, 9,  7, 0,-32768),
                                          _mm_setr_epi16(-4,-8,  9,  7, 0,-57, 0,  0));
    short[8] correct =                                  [-4,-8, -4, -8, 0,-57, 0, -32768];
    assert(R.array == correct);
}

/// Compare packed unsigned 8-bit integers in `a` and `b`, and return packed minimum values.
__m128i _mm_min_epu8 (__m128i a, __m128i b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pminub128(cast(ubyte16)a, cast(ubyte16)b);
    }
    else version(LDC)
    {
        // x86: pminub since LDC 1.0.0 -O1
        // ARM: umin.16b since LDC 1.5.0 -O1
        // PERF: catastrophic on ARM32
        ubyte16 sa = cast(ubyte16)a;
        ubyte16 sb = cast(ubyte16)b;
        static if (SIMD_COMPARISON_MASKS_16B)
            ubyte16 greater = (cast(ubyte16)a > cast(ubyte16)b);
        else
            ubyte16 greater = cast(ubyte16) greaterMask!ubyte16(sa, sb);
        return cast(__m128i)( (~greater & sa) | (greater & sb) );
    }
    else
    {
        // PERF: use the algorithm from _mm_max_epu16
        __m128i value128 = _mm_set1_epi8(-128);
        __m128i lower = _mm_cmplt_epi8(_mm_add_epi8(a, value128), _mm_add_epi8(b, value128)); // signed comparison
        __m128i aTob = a ^ b; // a ^ (a ^ b) == b
        __m128i mask = aTob & lower;
        return b ^ mask;
    }
}
unittest
{
    byte16 R = cast(byte16) _mm_min_epu8(_mm_setr_epi8(45, 1, -4, -8, 9,  7, 0,-57, -4,-8,  9,  7, 0,-57, 0,  0),
                                         _mm_setr_epi8(-4,-8,  9,  7, 0,-57, 0,  0, 45, 1, -4, -8, 9,  7, 0,-57));
    byte[16] correct =                                [45, 1,  9,  7, 0,  7, 0,  0, 45, 1,  9,  7, 0,  7, 0,  0];
    assert(R.array == correct);
}

/// Compare packed double-precision (64-bit) floating-point elements in `a` and `b`, and return packed minimum values.
__m128d _mm_min_pd (__m128d a, __m128d b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_minpd(a, b);
    }
    else
    {
        // Generates minpd starting with LDC 1.9
        a.ptr[0] = (a.array[0] < b.array[0]) ? a.array[0] : b.array[0];
        a.ptr[1] = (a.array[1] < b.array[1]) ? a.array[1] : b.array[1];
        return a;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 2.0);
    __m128d B = _mm_setr_pd(4.0, 1.0);
    __m128d M = _mm_min_pd(A, B);
    assert(M.array[0] == 1.0);
    assert(M.array[1] == 1.0);
}

/// Compare the lower double-precision (64-bit) floating-point elements in `a` and `b`, store the minimum value in 
/// the lower element of result, and copy the upper element from `a` to the upper element of result.
__m128d _mm_min_sd (__m128d a, __m128d b) pure @safe
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_minsd(a, b);
    }
    else
    {
        // Generates minsd starting with LDC 1.3
        __m128d r = a;
        r.array[0] = (a.array[0] < b.array[0]) ? a.array[0] : b.array[0];
        return r;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 3.0);
    __m128d B = _mm_setr_pd(4.0, 2.0);
    __m128d M = _mm_min_sd(A, B);
    assert(M.array[0] == 1.0);
    assert(M.array[1] == 3.0);
}

/// Copy the lower 64-bit integer in `a` to the lower element of result, and zero the upper element.
__m128i _mm_move_epi64 (__m128i a) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        // slightly better with GDC -O0
        return cast(__m128i) __builtin_ia32_movq128(cast(long2)a); 
    }
    else
    {
        long2 result = [ 0, 0 ];
        long2 la = cast(long2) a;
        result.ptr[0] = la.array[0];
        return cast(__m128i)(result);
    }
}
unittest
{
    long2 A = [13, 47];
    long2 B = cast(long2) _mm_move_epi64( cast(__m128i)A );
    long[2] correct = [13, 0];
    assert(B.array == correct);
}

/// Move the lower double-precision (64-bit) floating-point element from `b` to the lower element of result, and copy 
/// the upper element from `a` to the upper element of dst.
__m128d _mm_move_sd (__m128d a, __m128d b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_movsd(a, b); 
    }
    else
    {
        b.ptr[1] = a.array[1];
        return b;
    }
}
unittest
{
    double2 A = [13.0, 47.0];
    double2 B = [34.0, 58.0];
    double2 C = _mm_move_sd(A, B);
    double[2] correct = [34.0, 47.0];
    assert(C.array == correct);
}

/// Create mask from the most significant bit of each 8-bit element in `v`.
int _mm_movemask_epi8 (__m128i a) pure @trusted
{
    // PERF: Not possible in D_SIMD because of https://issues.dlang.org/show_bug.cgi?id=8047
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_pmovmskb128(cast(ubyte16)a);
    }
    else static if (LDC_with_SSE2)
    {
        return __builtin_ia32_pmovmskb128(cast(byte16)a);
    }
    else static if (LDC_with_ARM64)
    {
        // Solution from https://stackoverflow.com/questions/11870910/sse-mm-movemask-epi8-equivalent-method-for-arm-neon
        // The other two solutions lead to unfound intrinsics in LLVM and that took a long time.
        // SO there might be something a bit faster, but this one is reasonable and branchless.
        byte8 mask_shift;
        mask_shift.ptr[0] = 7;
        mask_shift.ptr[1] = 6;
        mask_shift.ptr[2] = 5;
        mask_shift.ptr[3] = 4;
        mask_shift.ptr[4] = 3;
        mask_shift.ptr[5] = 2;
        mask_shift.ptr[6] = 1;
        mask_shift.ptr[7] = 0;
        byte8 mask_and = byte8(-128);
        byte8 lo = vget_low_u8(cast(byte16)a);
        byte8 hi = vget_high_u8(cast(byte16)a);
        lo = vand_u8(lo, mask_and);
        lo = vshr_u8(lo, mask_shift);
        hi = vand_u8(hi, mask_and);
        hi = vshr_u8(hi, mask_shift);
        lo = vpadd_u8(lo,lo);
        lo = vpadd_u8(lo,lo);
        lo = vpadd_u8(lo,lo);
        hi = vpadd_u8(hi,hi);
        hi = vpadd_u8(hi,hi);
        hi = vpadd_u8(hi,hi);
        return (cast(ubyte)(hi[0]) << 8) | cast(ubyte)(lo[0]);
    }
    else
    {
        byte16 ai = cast(byte16)a;
        int r = 0;
        foreach(bit; 0..16)
        {
            if (ai.array[bit] < 0) r += (1 << bit);
        }
        return r;
    }
}
unittest
{
    assert(0x9C36 == _mm_movemask_epi8(_mm_set_epi8(-1, 1, 2, -3, -1, -1, 4, 8, 127, 0, -1, -1, 0, -1, -1, 0)));
}

/// Create mask from the most significant bit of each 16-bit element in `v`. #BONUS
int _mm_movemask_epi16 (__m128i a) pure @trusted
{
    return _mm_movemask_epi8(_mm_packs_epi16(a, _mm_setzero_si128()));
}
unittest
{
    assert(0x9C == _mm_movemask_epi16(_mm_set_epi16(-1, 1, 2, -3, -32768, -1, 32767, 8)));
}

/// Set each bit of mask result based on the most significant bit of the corresponding packed double-precision (64-bit) 
/// loating-point element in `v`.
int _mm_movemask_pd(__m128d v) pure @safe
{
    // PERF: Not possible in D_SIMD because of https://issues.dlang.org/show_bug.cgi?id=8047
    static if (GDC_or_LDC_with_SSE2)
    {
        return __builtin_ia32_movmskpd(v);
    }
    else
    {
        long2 lv = cast(long2)v;
        int r = 0;
        if (lv.array[0] < 0) r += 1;
        if (lv.array[1] < 0) r += 2;
        return r;
    }
}
unittest
{
    __m128d A = cast(__m128d) _mm_set_epi64x(-1, 0);
    assert(_mm_movemask_pd(A) == 2);
}

/// Copy the lower 64-bit integer in `v`.
__m64 _mm_movepi64_pi64 (__m128i v) pure @safe
{
    long2 lv = cast(long2)v;
    return long1(lv.array[0]);
}
unittest
{
    __m128i A = _mm_set_epi64x(-1, -2);
    __m64 R = _mm_movepi64_pi64(A);
    assert(R.array[0] == -2);
}

/// Copy the 64-bit integer `a` to the lower element of dest, and zero the upper element.
__m128i _mm_movpi64_epi64 (__m64 a) pure @trusted
{
    long2 r;
    r.ptr[0] = a.array[0];
    r.ptr[1] = 0;
    return cast(__m128i)r;
}

/// Multiply the low unsigned 32-bit integers from each packed 64-bit element in `a` and `b`, 
/// and store the unsigned 64-bit results.
__m128i _mm_mul_epu32 (__m128i a, __m128i b) pure @trusted
{    
    // PERF DMD D_SIMD
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pmuludq128 (a, b);
    }
    else
    {
        version(LDC)
        {
            static if (__VERSION__ >= 2088)
            {
                // Need LLVM9 for proper optimization
                long2 la, lb;
                la.ptr[0] = cast(uint)a.array[0];
                la.ptr[1] = cast(uint)a.array[2];
                lb.ptr[0] = cast(uint)b.array[0];
                lb.ptr[1] = cast(uint)b.array[2];
            }
            else
            {
                __m128i zero;
                zero = 0;
                long2 la = cast(long2) shufflevectorLDC!(int4, 0, 4, 2, 6)(a, zero);
                long2 lb = cast(long2) shufflevectorLDC!(int4, 0, 4, 2, 6)(b, zero);
            }
        }
        else
        {
            long2 la, lb;
            la.ptr[0] = cast(uint)a.array[0];
            la.ptr[1] = cast(uint)a.array[2];
            lb.ptr[0] = cast(uint)b.array[0];
            lb.ptr[1] = cast(uint)b.array[2];
        }

        version(DigitalMars)
        {
            // DMD has no long2 mul
            la.ptr[0] *= lb.array[0];
            la.ptr[1] *= lb.array[1];
            return cast(__m128i)(la);
        }
        else
        {
            static if (__VERSION__ >= 2076)
            {
                return cast(__m128i)(la * lb);
            }
            else
            {
                // long2 mul not supported before LDC 1.5
                la.ptr[0] *= lb.array[0];
                la.ptr[1] *= lb.array[1];
                return cast(__m128i)(la);
            }
        }
    }
}
unittest
{
    __m128i A = _mm_set_epi32(42, 0xDEADBEEF, 42, 0xffffffff);
    __m128i B = _mm_set_epi32(42, 0xCAFEBABE, 42, 0xffffffff);
    __m128i C = _mm_mul_epu32(A, B);
    long2 LC = cast(long2)C;
    assert(LC.array[0] == 18446744065119617025uL);
    assert(LC.array[1] == 12723420444339690338uL);
}

/// Multiply packed double-precision (64-bit) floating-point elements in `a` and `b`, and return the results. 
__m128d _mm_mul_pd(__m128d a, __m128d b) pure @safe
{
    pragma(inline, true);
    return a * b;
}
unittest
{
    __m128d a = [-2.0, 1.5];
    a = _mm_mul_pd(a, a);
    assert(a.array == [4.0, 2.25]);
}

/// Multiply the lower double-precision (64-bit) floating-point element in `a` and `b`, store the result in the lower 
/// element of result, and copy the upper element from `a` to the upper element of result.
__m128d _mm_mul_sd(__m128d a, __m128d b) pure @trusted
{
    version(DigitalMars)
    {    
        // Work-around for https://issues.dlang.org/show_bug.cgi?id=19599
        // Note that this is unneeded since DMD >= 2.094.0 at least, haven't investigated again
        asm pure nothrow @nogc @trusted { nop;}
        a.array[0] = a.array[0] * b.array[0];
        return a;
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_mulsd(a, b);
    }
    else
    {
        a.ptr[0] *= b.array[0];
        return a;
    }
}
unittest
{
    __m128d a = [-2.0, 1.5];
    a = _mm_mul_sd(a, a);
    assert(a.array == [4.0, 1.5]);
}

/// Multiply the low unsigned 32-bit integers from `a` and `b`, 
/// and get an unsigned 64-bit result.
__m64 _mm_mul_su32 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_mul_epu32(to_m128i(a), to_m128i(b)));
}
unittest
{
    __m64 A = _mm_set_pi32(42, 0xDEADBEEF);
    __m64 B = _mm_set_pi32(42, 0xCAFEBABE);
    __m64 C = _mm_mul_su32(A, B);
    assert(C.array[0] == 0xDEADBEEFuL * 0xCAFEBABEuL);
}

/// Multiply the packed signed 16-bit integers in `a` and `b`, producing intermediate 32-bit integers, and return the 
/// high 16 bits of the intermediate integers.
__m128i _mm_mulhi_epi16 (__m128i a, __m128i b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pmulhw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pmulhw128(cast(short8)a, cast(short8)b);
    }
    else
    {
        // ARM64: LDC 1.5 -O2 or later gives a nice sequence with 2 x ext.16b, 2 x smull.4s and shrn.4h shrn2.8h
        //        PERF: it seems the simde solution has one less instruction in ARM64.
        // PERF: Catastrophic in ARM32.
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 r = void;
        r.ptr[0] = (sa.array[0] * sb.array[0]) >> 16;
        r.ptr[1] = (sa.array[1] * sb.array[1]) >> 16;
        r.ptr[2] = (sa.array[2] * sb.array[2]) >> 16;
        r.ptr[3] = (sa.array[3] * sb.array[3]) >> 16;
        r.ptr[4] = (sa.array[4] * sb.array[4]) >> 16;
        r.ptr[5] = (sa.array[5] * sb.array[5]) >> 16;
        r.ptr[6] = (sa.array[6] * sb.array[6]) >> 16;
        r.ptr[7] = (sa.array[7] * sb.array[7]) >> 16;
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, -16, 2, 3, 4, 8, 16, 7);
    __m128i B = _mm_set1_epi16(16384);
    short8 R = cast(short8)_mm_mulhi_epi16(A, B);
    short[8] correct = [0, -4, 0, 0, 1, 2, 4, 1];
    assert(R.array == correct);
}

/// Multiply the packed unsigned 16-bit integers in `a` and `b`, producing intermediate 32-bit integers, and return the 
/// high 16 bits of the intermediate integers.
__m128i _mm_mulhi_epu16 (__m128i a, __m128i b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pmulhuw128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pmulhuw128(cast(short8)a, cast(short8)b);
    }
    else
    {
        // ARM64: LDC 1.5 -O2 or later gives a nice sequence with 2 x ext.16b, 2 x umull.4s and shrn.4h shrn2.8h
        //      it seems the simde solution has one less instruction in ARM64
        // PERF: Catastrophic in ARM32.
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        short8 r = void;
        r.ptr[0] = cast(short)( (cast(ushort)sa.array[0] * cast(ushort)sb.array[0]) >> 16 );
        r.ptr[1] = cast(short)( (cast(ushort)sa.array[1] * cast(ushort)sb.array[1]) >> 16 );
        r.ptr[2] = cast(short)( (cast(ushort)sa.array[2] * cast(ushort)sb.array[2]) >> 16 );
        r.ptr[3] = cast(short)( (cast(ushort)sa.array[3] * cast(ushort)sb.array[3]) >> 16 );
        r.ptr[4] = cast(short)( (cast(ushort)sa.array[4] * cast(ushort)sb.array[4]) >> 16 );
        r.ptr[5] = cast(short)( (cast(ushort)sa.array[5] * cast(ushort)sb.array[5]) >> 16 );
        r.ptr[6] = cast(short)( (cast(ushort)sa.array[6] * cast(ushort)sb.array[6]) >> 16 );
        r.ptr[7] = cast(short)( (cast(ushort)sa.array[7] * cast(ushort)sb.array[7]) >> 16 );
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, -16, 2, 3, 4, 8, 16, 7);
    __m128i B = _mm_set1_epi16(16384);
    short8 R = cast(short8)_mm_mulhi_epu16(A, B);
    short[8] correct = [0, 0x3FFC, 0, 0, 1, 2, 4, 1];
    assert(R.array == correct);
}

/// Multiply the packed 16-bit integers in `a` and `b`, producing intermediate 32-bit integers, and return the low 16 
/// bits of the intermediate integers.
__m128i _mm_mullo_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(short8)a * cast(short8)b);
}
unittest
{
    __m128i A = _mm_setr_epi16(16384, -16, 0,      3, 4, 1, 16, 7);
    __m128i B = _mm_set1_epi16(16384);
    short8 R = cast(short8)_mm_mullo_epi16(A, B);
    short[8] correct = [0, 0, 0, -16384, 0, 16384, 0, -16384];
    assert(R.array == correct);
}

/// Compute the bitwise NOT of 128 bits in `a`. #BONUS
__m128i _mm_not_si128 (__m128i a) pure @safe
{
    return ~a;
}
unittest
{
    __m128i A = _mm_set1_epi32(-748);
    int4 notA = cast(int4) _mm_not_si128(A);
    int[4] correct = [747, 747, 747, 747];
    assert(notA.array == correct);
}

/// Compute the bitwise OR of packed double-precision (64-bit) floating-point elements in `a` and `b`.
__m128d _mm_or_pd (__m128d a, __m128d b) pure @safe
{
    pragma(inline, true);
    return cast(__m128d)( cast(__m128i)a | cast(__m128i)b );
}

/// Compute the bitwise OR of 128 bits (representing integer data) in `a` and `b`.
__m128i _mm_or_si128 (__m128i a, __m128i b) pure @safe
{
    pragma(inline, true);
    return a | b;
}

/// Convert packed signed 32-bit integers from `a` and `b` to packed 16-bit integers using signed saturation.
__m128i _mm_packs_epi32 (__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PACKSSDW, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_packssdw128(a, b);
    }    
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_packssdw128(a, b);
    }
    else static if (LDC_with_ARM64)
    {
        short4 ra = vqmovn_s32(cast(int4)a);
        short4 rb = vqmovn_s32(cast(int4)b);
        return cast(__m128i)vcombine_s16(ra, rb);
    }
    else
    {
        // PERF: catastrophic on ARM32
        short8 r;
        r.ptr[0] = saturateSignedIntToSignedShort(a.array[0]);
        r.ptr[1] = saturateSignedIntToSignedShort(a.array[1]);
        r.ptr[2] = saturateSignedIntToSignedShort(a.array[2]);
        r.ptr[3] = saturateSignedIntToSignedShort(a.array[3]);
        r.ptr[4] = saturateSignedIntToSignedShort(b.array[0]);
        r.ptr[5] = saturateSignedIntToSignedShort(b.array[1]);
        r.ptr[6] = saturateSignedIntToSignedShort(b.array[2]);
        r.ptr[7] = saturateSignedIntToSignedShort(b.array[3]);
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(100000, -100000, 1000, 0);
    short8 R = cast(short8) _mm_packs_epi32(A, A);
    short[8] correct = [32767, -32768, 1000, 0, 32767, -32768, 1000, 0];
    assert(R.array == correct);
}

/// Convert packed signed 16-bit integers from `a` and `b` to packed 8-bit integers using signed saturation.
__m128i _mm_packs_epi16 (__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PACKSSWB, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_packsswb128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_packsswb128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_ARM64)
    {
        // generate a nice pair of sqxtn.8b + sqxtn2 since LDC 1.5 -02
        byte8 ra = vqmovn_s16(cast(short8)a);
        byte8 rb = vqmovn_s16(cast(short8)b);
        return cast(__m128i)vcombine_s8(ra, rb);
    }
    else
    {
        // PERF: ARM32 is missing
        byte16 r;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        foreach(i; 0..8)
            r.ptr[i] = saturateSignedWordToSignedByte(sa.array[i]);
        foreach(i; 0..8)
            r.ptr[i+8] = saturateSignedWordToSignedByte(sb.array[i]);
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(1000, -1000, 1000, 0, 256, -129, 254, 0);
    byte16 R = cast(byte16) _mm_packs_epi16(A, A);
    byte[16] correct = [127, -128, 127, 0, 127, -128, 127, 0,
                        127, -128, 127, 0, 127, -128, 127, 0];
    assert(R.array == correct);
}

/// Convert packed signed 16-bit integers from `a` and `b` to packed 8-bit integers using unsigned saturation.
__m128i _mm_packus_epi16 (__m128i a, __m128i b) pure @trusted
{
    // PERF DMD catastrophic
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PACKUSWB, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_packuswb128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_packuswb128(cast(short8)a, cast(short8)b);
    }
    else static if (LDC_with_ARM64)
    {
        // generate a nice pair of sqxtun + sqxtun2 since LDC 1.5 -02
        byte8 ra = vqmovun_s16(cast(short8)a);
        byte8 rb = vqmovun_s16(cast(short8)b);
        return cast(__m128i)vcombine_s8(ra, rb);
    }
    else
    {
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        align(16) ubyte[16] result = void;
        for (int i = 0; i < 8; ++i)
        {
            short s = sa[i];
            if (s < 0) s = 0;
            if (s > 255) s = 255;
            result[i] = cast(ubyte)s;

            s = sb[i];
            if (s < 0) s = 0;
            if (s > 255) s = 255;
            result[i+8] = cast(ubyte)s;
        }
        return *cast(__m128i*)(result.ptr);
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-10, 400, 0, 256, 255, 2, 1, 0);
    byte16 AA = cast(byte16) _mm_packus_epi16(A, A);
    static immutable ubyte[16] correctResult = [0, 255, 0, 255, 255, 2, 1, 0,
                                                0, 255, 0, 255, 255, 2, 1, 0];
    foreach(i; 0..16)
        assert(AA.array[i] == cast(byte)(correctResult[i]));
}

/// Provide a hint to the processor that the code sequence is a spin-wait loop. This can help improve the performance 
/// and power consumption of spin-wait loops.
void _mm_pause() @trusted
{
    version(GNU)
    {
        static if (GDC_with_SSE2)
        {
            __builtin_ia32_pause();
        }
        else version(X86)
        {
            asm pure nothrow @nogc @trusted
            {
                "pause;\n" : : : ;
            }
        }
        else
            static assert(false);
    }
    else static if (LDC_with_SSE2)
    {
        __builtin_ia32_pause();
    }
    else static if (DMD_with_asm)
    {
        asm nothrow @nogc pure @safe
        {
            rep; nop; // F3 90 =  pause
        }
    }
    else version (LDC)
    {
        // PERF: Do nothing currently , could be the "yield" intruction on ARM.
    }
    else
        static assert(false);
}
unittest
{
    _mm_pause();
}

/// Compute the absolute differences of packed unsigned 8-bit integers in `a` and `b`, then horizontally sum each 
/// consecutive 8 differences to produce two unsigned 16-bit integers, and pack these unsigned 16-bit integers in the 
/// low 16 bits of 64-bit elements in result.
__m128i _mm_sad_epu8 (__m128i a, __m128i b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psadbw128(cast(ubyte16)a, cast(ubyte16)b);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psadbw128(cast(byte16)a, cast(byte16)b);
    }
    else static if (LDC_with_ARM64)
    {
        ushort8 t = cast(ushort8) vpaddlq_u8(vabdq_u8(cast(byte16) a, cast(byte16) b));

        // PERF: Looks suboptimal vs addp
        ushort r0 = cast(ushort)(t[0] + t[1] + t[2] + t[3]);
        ushort r4 = cast(ushort)(t[4] + t[5] + t[6] + t[7]);
        ushort8 r = 0;
        r[0] = r0;
        r[4] = r4;
        return cast(__m128i) r;
    }
    else
    {
        // PERF: ARM32 is lacking
        byte16 ab = cast(byte16)a;
        byte16 bb = cast(byte16)b;
        ubyte[16] t;
        foreach(i; 0..16)
        {
            int diff = cast(ubyte)(ab.array[i]) - cast(ubyte)(bb.array[i]);
            if (diff < 0) diff = -diff;
            t[i] = cast(ubyte)(diff);
        }
        int4 r = _mm_setzero_si128();
        r.ptr[0] = t[0] + t[1] + t[2] + t[3] + t[4] + t[5] + t[6] + t[7];
        r.ptr[2] = t[8] + t[9] + t[10]+ t[11]+ t[12]+ t[13]+ t[14]+ t[15];
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi8(3, 4, 6, 8, 12, 14, 18, 20, 24, 30, 32, 38, 42, 44, 48, 54); // primes + 1
    __m128i B = _mm_set1_epi8(1);
    __m128i R = _mm_sad_epu8(A, B);
    int[4] correct = [2 + 3 + 5 + 7 + 11 + 13 + 17 + 19,
                      0,
                      23 + 29 + 31 + 37 + 41 + 43 + 47 + 53,
                      0];
    assert(R.array == correct);
}

/// Set packed 16-bit integers with the supplied values.
__m128i _mm_set_epi16 (short e7, short e6, short e5, short e4, short e3, short e2, short e1, short e0) pure @trusted
{
    short8 r = void;
    r.ptr[0] = e0;
    r.ptr[1] = e1;
    r.ptr[2] = e2;
    r.ptr[3] = e3;
    r.ptr[4] = e4;
    r.ptr[5] = e5;
    r.ptr[6] = e6;
    r.ptr[7] = e7;
    return cast(__m128i) r;
}
unittest
{
    __m128i A = _mm_set_epi16(7, 6, 5, 4, 3, 2, 1, 0);
    short8 B = cast(short8) A;
    foreach(i; 0..8)
        assert(B.array[i] == i);
}

/// Set packed 32-bit integers with the supplied values.
__m128i _mm_set_epi32 (int e3, int e2, int e1, int e0) pure @trusted
{
    // PERF: does a constant inline correctly? vs int4 field assignment
    align(16) int[4] r = [e0, e1, e2, e3];
    return *cast(int4*)&r;
}
unittest
{
    __m128i A = _mm_set_epi32(3, 2, 1, 0);
    foreach(i; 0..4)
        assert(A.array[i] == i);
}

/// Set packed 64-bit integers with the supplied values.
__m128i _mm_set_epi64(__m64 e1, __m64 e0) pure @trusted
{
    pragma(inline, true);
    long2 r = void;
    r.ptr[0] = e0.array[0];
    r.ptr[1] = e1.array[0];
    return cast(__m128i)(r);
}
unittest
{
    __m128i A = _mm_set_epi64(_mm_cvtsi64_m64(1234), _mm_cvtsi64_m64(5678));
    long2 B = cast(long2) A;
    assert(B.array[0] == 5678);
    assert(B.array[1] == 1234);
}

/// Set packed 64-bit integers with the supplied values.
__m128i _mm_set_epi64x (long e1, long e0) pure @trusted
{
    pragma(inline, true);
    long2 r = void;
    r.ptr[0] = e0;
    r.ptr[1] = e1;
    return cast(__m128i)(r);
}
unittest
{
    __m128i A = _mm_set_epi64x(1234, -5678);
    long2 B = cast(long2) A;
    assert(B.array[0] == -5678);
    assert(B.array[1] == 1234);
}

/// Set packed 8-bit integers with the supplied values.
__m128i _mm_set_epi8 (byte e15, byte e14, byte e13, byte e12,
                      byte e11, byte e10, byte e9, byte e8,
                      byte e7, byte e6, byte e5, byte e4,
                      byte e3, byte e2, byte e1, byte e0) pure @trusted
{
    align(16) byte[16] result = [e0, e1,  e2,  e3,  e4,  e5,  e6, e7,
                                 e8, e9, e10, e11, e12, e13, e14, e15];
    return *cast(__m128i*)(result.ptr);
}
unittest
{
    byte16 R = cast(byte16) _mm_set_epi8(-1, 0, 56, 127, -128, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
    byte[16] correct = [14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, -128, 127, 56, 0, -1];
    assert(R.array == correct);
}

/// Set packed double-precision (64-bit) floating-point elements with the supplied values.
__m128d _mm_set_pd (double e1, double e0) pure @trusted
{
    pragma(inline, true);
    double2 r = void;
    r.ptr[0] = e0;
    r.ptr[1] = e1;
    return r;
}
unittest
{
    __m128d A = _mm_set_pd(61.0, 55.0);
    double[2] correct = [55.0, 61.0];
    assert(A.array == correct);
}

/// Broadcast double-precision (64-bit) floating-point value `a` to all element.
__m128d _mm_set_pd1 (double a) pure @trusted
{
    pragma(inline, true);
    __m128d r = void;
    r.ptr[0] = a;
    r.ptr[1] = a;
    return r;
}
unittest
{
    __m128d A = _mm_set_pd1(61.0);
    double[2] correct = [61.0, 61.0];
    assert(A.array == correct);
}

/// Copy double-precision (64-bit) floating-point element `a` to the lower element of result, 
/// and zero the upper element.
__m128d _mm_set_sd (double a) pure @trusted
{
    double2 r = void;
    r.ptr[0] = a;
    r.ptr[1] = 0.0;
    return r;
}
unittest
{
    __m128d A = _mm_set_sd(61.0);
    double[2] correct = [61.0, 0.0];
    assert(A.array == correct);
}

/// Broadcast 16-bit integer a to all elements of dst.
__m128i _mm_set1_epi16 (short a) pure @trusted
{
    version(DigitalMars) // workaround https://issues.dlang.org/show_bug.cgi?id=21469 
    {
        short8 v = a;
        return cast(__m128i) v;
    }
    else
    {
        pragma(inline, true);
        return cast(__m128i)(short8(a));
    }
}
unittest
{
    short8 a = cast(short8) _mm_set1_epi16(31);
    for (int i = 0; i < 8; ++i)
        assert(a.array[i] == 31);
}

/// Broadcast 32-bit integer `a` to all elements.
__m128i _mm_set1_epi32 (int a) pure @trusted
{
    pragma(inline, true);
    return cast(__m128i)(int4(a));
}
unittest
{
    int4 a = cast(int4) _mm_set1_epi32(31);
    for (int i = 0; i < 4; ++i)
        assert(a.array[i] == 31);
}

/// Broadcast 64-bit integer `a` to all elements.
__m128i _mm_set1_epi64 (__m64 a) pure @safe
{
    return _mm_set_epi64(a, a);
}
unittest
{
    long b = 0x1DEADCAFE; 
    __m64 a;
    a.ptr[0] = b;
    long2 c = cast(long2) _mm_set1_epi64(a);
    assert(c.array[0] == b);
    assert(c.array[1] == b);
}

/// Broadcast 64-bit integer `a` to all elements
__m128i _mm_set1_epi64x (long a) pure @trusted
{
    long2 b = a; // Must be on its own line to workaround https://issues.dlang.org/show_bug.cgi?id=21470
    return cast(__m128i)(b);
}
unittest
{
    long b = 0x1DEADCAFE;
    long2 c = cast(long2) _mm_set1_epi64x(b);
    for (int i = 0; i < 2; ++i)
        assert(c.array[i] == b);
}

/// Broadcast 8-bit integer `a` to all elements.
__m128i _mm_set1_epi8 (byte a) pure @trusted
{
    pragma(inline, true);
    byte16 b = a; // Must be on its own line to workaround https://issues.dlang.org/show_bug.cgi?id=21470
    return cast(__m128i)(b);
}
unittest
{
    byte16 b = cast(byte16) _mm_set1_epi8(31);
    for (int i = 0; i < 16; ++i)
        assert(b.array[i] == 31);
}

alias _mm_set1_pd = _mm_set_pd1;

/// Set packed 16-bit integers with the supplied values in reverse order.
__m128i _mm_setr_epi16 (short e7, short e6, short e5, short e4, 
                        short e3, short e2, short e1, short e0) pure @trusted
{
    short8 r = void;
    r.ptr[0] = e7;
    r.ptr[1] = e6;
    r.ptr[2] = e5;
    r.ptr[3] = e4;
    r.ptr[4] = e3;
    r.ptr[5] = e2;
    r.ptr[6] = e1;
    r.ptr[7] = e0;
    return cast(__m128i)(r);
}
unittest
{
    short8 A = cast(short8) _mm_setr_epi16(7, 6, 5, -32768, 32767, 2, 1, 0);
    short[8] correct = [7, 6, 5, -32768, 32767, 2, 1, 0];
    assert(A.array == correct);
}

/// Set packed 32-bit integers with the supplied values in reverse order.
__m128i _mm_setr_epi32 (int e3, int e2, int e1, int e0) pure @trusted
{
    // Performs better than = void; with GDC
    pragma(inline, true);
    align(16) int[4] result = [e3, e2, e1, e0];
    return *cast(__m128i*)(result.ptr);
}
unittest
{
    int4 A = cast(int4) _mm_setr_epi32(-1, 0, -2147483648, 2147483647);
    int[4] correct = [-1, 0, -2147483648, 2147483647];
    assert(A.array == correct);
}

/// Set packed 64-bit integers with the supplied values in reverse order.
__m128i _mm_setr_epi64 (long e1, long e0) pure @trusted
{
    long2 r = void;
    r.ptr[0] = e1;
    r.ptr[1] = e0;
    return cast(__m128i)(r);
}
unittest
{
    long2 A = cast(long2) _mm_setr_epi64(-1, 0);
    long[2] correct = [-1, 0];
    assert(A.array == correct);
}

/// Set packed 8-bit integers with the supplied values in reverse order.
__m128i _mm_setr_epi8 (byte e15, byte e14, byte e13, byte e12,
                       byte e11, byte e10, byte e9,  byte e8,
                       byte e7,  byte e6,  byte e5,  byte e4,
                       byte e3,  byte e2,  byte e1,  byte e0) pure @trusted
{
    align(16) byte[16] result = [e15, e14, e13, e12, e11, e10, e9, e8,
                                 e7,  e6,  e5,  e4,  e3,  e2, e1, e0];
    return *cast(__m128i*)(result.ptr);
}
unittest
{
    byte16 R = cast(byte16) _mm_setr_epi8(-1, 0, 56, 127, -128, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
    byte[16] correct = [-1, 0, 56, 127, -128, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
    assert(R.array == correct);
}

/// Set packed double-precision (64-bit) floating-point elements with the supplied values in reverse order.
__m128d _mm_setr_pd (double e1, double e0) pure @trusted
{
    pragma(inline, true);
    double2 result;
    result.ptr[0] = e1;
    result.ptr[1] = e0;
    return result;
}
unittest
{
    __m128d A = _mm_setr_pd(61.0, 55.0);
    double[2] correct = [61.0, 55.0];
    assert(A.array == correct);
}

/// Return vector of type `__m128d` with all elements set to zero.
__m128d _mm_setzero_pd() pure @trusted
{
    pragma(inline, true);
    double2 r = void;
    r.ptr[0] = 0.0;
    r.ptr[1] = 0.0;
    return r;
}
unittest
{
    __m128d A = _mm_setzero_pd();
    double[2] correct = [0.0, 0.0];
    assert(A.array == correct);
}

/// Return vector of type `__m128i` with all elements set to zero.
__m128i _mm_setzero_si128() pure @trusted
{
    pragma(inline, true);
    int4 r = void;
    r.ptr[0] = 0;
    r.ptr[1] = 0;
    r.ptr[2] = 0;
    r.ptr[3] = 0;
    return r;
}
unittest
{
    __m128i A = _mm_setzero_si128();
    int[4] correct = [0, 0, 0, 0];
    assert(A.array == correct);
}

/// Shuffle 32-bit integers in `a` using the control in `imm8`.
/// See_also: `_MM_SHUFFLE`.
__m128i _mm_shuffle_epi32(int imm8)(__m128i a) pure @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_pshufd(a, imm8);
    }
    else static if (LDC_with_optimizations)
    {
        return shufflevectorLDC!(int4, (imm8 >> 0) & 3,
                                 (imm8 >> 2) & 3,
                                 (imm8 >> 4) & 3,
                                 (imm8 >> 6) & 3)(a, a);
    }
    else
    {
        int4 r = void;
        r.ptr[0] = a.ptr[(imm8 >> 0) & 3];
        r.ptr[1] = a.ptr[(imm8 >> 2) & 3];
        r.ptr[2] = a.ptr[(imm8 >> 4) & 3];
        r.ptr[3] = a.ptr[(imm8 >> 6) & 3];
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(0, 1, 2, 3);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    int4 B = cast(int4) _mm_shuffle_epi32!SHUFFLE(A);
    int[4] expectedB = [ 3, 2, 1, 0 ];
    assert(B.array == expectedB);
}

/// Shuffle double-precision (64-bit) floating-point elements using the control in `imm8`.
/// See_also: `_MM_SHUFFLE2`.
__m128d _mm_shuffle_pd (int imm8)(__m128d a, __m128d b) pure @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_shufpd(a, b, imm8);
    }
    else version(LDC)
    {
        return shufflevectorLDC!(double2, 0 + ( imm8 & 1 ),
                                 2 + ( (imm8 >> 1) & 1 ))(a, b);
    }
    else
    {
        double2 r = void;
        r.ptr[0] = a.array[imm8 & 1];
        r.ptr[1] = b.array[(imm8 >> 1) & 1];
        return r;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(0.5, 2.0);
    __m128d B = _mm_setr_pd(4.0, 5.0);
    enum int SHUFFLE = _MM_SHUFFLE2(1, 1);
    __m128d R = _mm_shuffle_pd!SHUFFLE(A, B);
    double[2] correct = [ 2.0, 5.0 ];
    assert(R.array == correct);
}

/// Shuffle 16-bit integers in the high 64 bits of `a` using the control in `imm8`. Store the results in the high 
/// 64 bits of result, with the low 64 bits being copied from from `a` to result.
/// See also: `_MM_SHUFFLE`.
__m128i _mm_shufflehi_epi16(int imm8)(__m128i a) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PSHUFHW, a, a, cast(ubyte)imm8);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pshufhw(cast(short8)a, imm8);
    }
    else static if (LDC_with_optimizations)
    {
        return cast(__m128i) shufflevectorLDC!(short8, 0, 1, 2, 3,
                                          4 + ( (imm8 >> 0) & 3 ),
                                          4 + ( (imm8 >> 2) & 3 ),
                                          4 + ( (imm8 >> 4) & 3 ),
                                          4 + ( (imm8 >> 6) & 3 ))(cast(short8)a, cast(short8)a);
    }
    else
    {
        short8 r = cast(short8)a;
        short8 sa = cast(short8)a;
        r.ptr[4] = sa.array[4 + ( (imm8 >> 0) & 3 ) ];
        r.ptr[5] = sa.array[4 + ( (imm8 >> 2) & 3 ) ];
        r.ptr[6] = sa.array[4 + ( (imm8 >> 4) & 3 ) ];
        r.ptr[7] = sa.array[4 + ( (imm8 >> 6) & 3 ) ];
        return cast(__m128i) r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, 4, 5, 6, 7);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    short8 C = cast(short8) _mm_shufflehi_epi16!SHUFFLE(A);
    short[8] expectedC = [ 0, 1, 2, 3, 7, 6, 5, 4 ];
    assert(C.array == expectedC);
}

/// Shuffle 16-bit integers in the low 64 bits of `a` using the control in `imm8`. Store the results in the low 64 
/// bits of result, with the high 64 bits being copied from from `a` to result.
/// See_also: `_MM_SHUFFLE`.
__m128i _mm_shufflelo_epi16(int imm8)(__m128i a) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PSHUFLW, a, a, cast(ubyte)imm8);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_pshuflw(cast(short8)a, imm8);
    }
    else static if (LDC_with_optimizations)
    {
        return cast(__m128i) shufflevectorLDC!(short8, ( (imm8 >> 0) & 3 ),
                                                       ( (imm8 >> 2) & 3 ),
                                                       ( (imm8 >> 4) & 3 ),
                                                       ( (imm8 >> 6) & 3 ), 4, 5, 6, 7)(cast(short8)a, cast(short8)a);
    }
    else
    {
        short8 r = cast(short8)a;
        short8 sa = cast(short8)a;
        r.ptr[0] = sa.array[(imm8 >> 0) & 3];
        r.ptr[1] = sa.array[(imm8 >> 2) & 3];
        r.ptr[2] = sa.array[(imm8 >> 4) & 3];
        r.ptr[3] = sa.array[(imm8 >> 6) & 3];
        return cast(__m128i) r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, 4, 5, 6, 7);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    short8 B = cast(short8) _mm_shufflelo_epi16!SHUFFLE(A);
    short[8] expectedB = [ 3, 2, 1, 0, 4, 5, 6, 7 ];
    assert(B.array == expectedB);
}

/// Shift packed 32-bit integers in `a` left by `count` while shifting in zeros.
deprecated("Use _mm_slli_epi32 instead.") __m128i _mm_sll_epi32 (__m128i a, __m128i count) pure @trusted
{
    static if (LDC_with_SSE2)
    {
        return __builtin_ia32_pslld128(a, count);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_pslld128(a, count);
    }
    else static if (DMD_with_32bit_asm)
    {
        asm pure nothrow @nogc @trusted
        {
            movdqu XMM0, a;
            movdqu XMM1, count;
            pslld XMM0, XMM1;
            movdqu a, XMM0;
        }
        return a;
    }
    else
    {
        int4 r = void;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc.array[0]);
        foreach(i; 0..4)
            r[i] = cast(uint)(a[i]) << bits;
        return r;
    }
}

/// Shift packed 64-bit integers in `a` left by `count` while shifting in zeros.
deprecated("Use _mm_slli_epi64 instead.") __m128i _mm_sll_epi64 (__m128i a, __m128i count) pure @trusted
{
    static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psllq128(cast(long2)a, cast(long2)count);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psllq128(cast(long2)a, cast(long2)count);
    }
    else static if (DMD_with_32bit_asm)
    {
        asm pure nothrow @nogc @trusted
        {
            movdqu XMM0, a;
            movdqu XMM1, count;
            psllq XMM0, XMM1;
            movdqu a, XMM0;
        }
        return a;
    }
    else
    {
        // ARM: good since LDC 1.12 -O2
        // ~but -O0 version is catastrophic
        long2 r = void;
        long2 sa = cast(long2)a;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc.array[0]);
        foreach(i; 0..2)
            r.array[i] = cast(ulong)(sa.array[i]) << bits;
        return cast(__m128i)r;
    }
}

/// Shift packed 16-bit integers in `a` left by `count` while shifting in zeros.
deprecated("Use _mm_slli_epi16 instead.") __m128i _mm_sll_epi16 (__m128i a, __m128i count) pure @trusted
{
    static if (GDC_or_LDC_with_SSE2)
    {
        return cast(__m128i)__builtin_ia32_psllw128(cast(short8)a, cast(short8)count);
    }
    else static if (DMD_with_32bit_asm)
    {
        asm pure nothrow @nogc
        {
            movdqu XMM0, a;
            movdqu XMM1, count;
            psllw XMM0, XMM1;
            movdqu a, XMM0;
        }
        return a;
    }
    else
    {
        short8 sa = cast(short8)a;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc.array[0]);
        short8 r = void;
        foreach(i; 0..8)
            r.ptr[i] = cast(short)(cast(ushort)(sa.array[i]) << bits);
        return cast(int4)r;
    }
}


/// Shift packed 32-bit integers in `a` left by `imm8` while shifting in zeros.
__m128i _mm_slli_epi32 (__m128i a, int imm8) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_pslldi128(a, cast(ubyte)imm8);
    }
    else static if (LDC_with_SSE2)
    {
        return __builtin_ia32_pslldi128(a, cast(ubyte)imm8);
    }
    else
    {
        // Note: the intrinsics guarantee imm8[0..7] is taken, however
        //       D says "It's illegal to shift by the same or more bits 
        //       than the size of the quantity being shifted"
        //       and it's UB instead.
        int4 r = _mm_setzero_si128();

        ubyte count = cast(ubyte) imm8;
        if (count > 31)
            return r;
        
        foreach(i; 0..4)
            r.array[i] = cast(uint)(a.array[i]) << count;
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(0, 2, 3, -4);
    __m128i B = _mm_slli_epi32(A, 1);
    __m128i B2 = _mm_slli_epi32(A, 1 + 256);
    int[4] expectedB = [ 0, 4, 6, -8];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    __m128i C = _mm_slli_epi32(A, 0);
    int[4] expectedC = [ 0, 2, 3, -4];
    assert(C.array == expectedC);

    __m128i D = _mm_slli_epi32(A, 65);
    int[4] expectedD = [ 0, 0, 0, 0];
    assert(D.array == expectedD);
}

/// Shift packed 64-bit integers in `a` left by `imm8` while shifting in zeros.
__m128i _mm_slli_epi64 (__m128i a, int imm8) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psllqi128(cast(long2)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psllqi128(cast(long2)a, cast(ubyte)imm8);
    }
    else
    {
        long2 sa = cast(long2)a;

        // Note: the intrinsics guarantee imm8[0..7] is taken, however
        //       D says "It's illegal to shift by the same or more bits 
        //       than the size of the quantity being shifted"
        //       and it's UB instead.
        long2 r = cast(long2) _mm_setzero_si128();
        ubyte count = cast(ubyte) imm8;
        if (count > 63)
            return cast(__m128i)r;

        r.ptr[0] = cast(ulong)(sa.array[0]) << count;
        r.ptr[1] = cast(ulong)(sa.array[1]) << count;
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi64(8, -4);
    long2 B = cast(long2) _mm_slli_epi64(A, 1);
    long2 B2 = cast(long2) _mm_slli_epi64(A, 1 + 1024);
    long[2] expectedB = [ 16, -8];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    long2 C = cast(long2) _mm_slli_epi64(A, 0);
    long[2] expectedC = [ 8, -4];
    assert(C.array == expectedC);

    long2 D = cast(long2) _mm_slli_epi64(A, 64);
    long[2] expectedD = [ 0, -0];
    assert(D.array == expectedD);
}

/// Shift packed 16-bit integers in `a` left by `imm8` while shifting in zeros.
__m128i _mm_slli_epi16(__m128i a, int imm8) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psllwi128(cast(short8)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psllwi128(cast(short8)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_ARM64)
    {
        short8 sa = cast(short8)a;
        short8 r = cast(short8)_mm_setzero_si128();
        ubyte count = cast(ubyte) imm8;
        if (count > 15)
            return cast(__m128i)r;
        r = sa << short8(count);
        return cast(__m128i)r;
    }
    else
    {
        short8 sa = cast(short8)a;
        short8 r = cast(short8)_mm_setzero_si128();
        ubyte count = cast(ubyte) imm8;
        if (count > 15)
            return cast(__m128i)r;
        foreach(i; 0..8)
            r.ptr[i] = cast(short)(sa.array[i] << count);
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7);
    short8 B = cast(short8)( _mm_slli_epi16(A, 1) );
    short8 B2 = cast(short8)( _mm_slli_epi16(A, 1 + 256) );
    short[8] expectedB = [ 0, 2, 4, 6, -8, -10, 12, 14 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    short8 C = cast(short8)( _mm_slli_epi16(A, 16) );
    short[8] expectedC = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
    assert(C.array == expectedC);
}


/// Shift `a` left by `bytes` bytes while shifting in zeros.
__m128i _mm_slli_si128(ubyte bytes)(__m128i op) pure @trusted
{
    static if (bytes & 0xF0)
    {
        return _mm_setzero_si128();
    }
    else static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd_ib(XMM.PSLLDQ, op, bytes);
    }
    else static if (GDC_with_SSE2)
    {
        pragma(inline, true); // else it doesn't seem to be inlined at all by GDC TODO _mm_srli_si128
        return cast(__m128i) __builtin_ia32_pslldqi128(cast(long2)op, cast(ubyte)(bytes * 8)); 
    }
    else static if (LDC_with_optimizations)
    {
        return cast(__m128i) shufflevectorLDC!(byte16,
                                               16 - bytes, 17 - bytes, 18 - bytes, 19 - bytes, 20 - bytes, 21 - bytes,
                                               22 - bytes, 23 - bytes, 24 - bytes, 25 - bytes, 26 - bytes, 27 - bytes,
                                               28 - bytes, 29 - bytes, 30 - bytes, 31 - bytes)
                                               (cast(byte16)_mm_setzero_si128(), cast(byte16)op);
    }
    else static if (DMD_with_32bit_asm)
    {
        asm pure nothrow @nogc @trusted // somehow doesn't work for x86_64
        {
            movdqu XMM0, op;
            pslldq XMM0, bytes;
            movdqu op, XMM0;
        }
        return op;
    }
    else
    {
        byte16 A = cast(byte16)op;
        byte16 R = void;
        for (int n = 15; n >= bytes; --n)
            R.ptr[n] = A.array[n-bytes];
        for (int n = bytes-1; n >= 0; --n)
            R.ptr[n] = 0;
        return cast(__m128i)R;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, 4, 5, 6, 7);
    short8 R = cast(short8) _mm_slli_si128!8(A); // shift 8 bytes to the left
    short[8] correct = [ 0, 0, 0, 0, 0, 1, 2, 3 ];
    assert(R.array == correct);

    __m128i B = _mm_slli_si128!16(_mm_set1_epi32(-1));
    int[4] expectedB = [0, 0, 0, 0];
    assert(B.array == expectedB);
}

/// Compute the square root of packed double-precision (64-bit) floating-point elements in `vec`.
__m128d _mm_sqrt_pd(__m128d vec) pure @trusted
{
    version(LDC)
    {
        // Disappeared with LDC 1.11
        static if (__VERSION__ < 2081)
            return __builtin_ia32_sqrtpd(vec);
        else
        {
            // PERF: use llvm_sqrt on the vector
            vec.array[0] = llvm_sqrt(vec.array[0]); 
            vec.array[1] = llvm_sqrt(vec.array[1]);
            return vec;
        }
    }
    else static if (GDC_with_SSE2)    
    {
        return __builtin_ia32_sqrtpd(vec);
    }
    else
    {
        vec.ptr[0] = sqrt(vec.array[0]);
        vec.ptr[1] = sqrt(vec.array[1]);
        return vec;
    }
}

/// Compute the square root of the lower double-precision (64-bit) floating-point element in `b`, store the result in 
/// the lower element of result, and copy the upper element from `a` to the upper element of result.
__m128d _mm_sqrt_sd(__m128d a, __m128d b) pure @trusted
{
    // Note: the builtin has one argument, since the legacy `sqrtsd` SSE2 instruction operates on the same register only.
    //       "128-bit Legacy SSE version: The first source operand and the destination operand are the same. 
    //        The quadword at bits 127:64 of the destination operand remains unchanged."
    version(LDC)
    {
        // Disappeared with LDC 1.11
        static if (__VERSION__ < 2081)
        {
            __m128d c = __builtin_ia32_sqrtsd(b);
            a[0] = c[0];
            return a;
        }
        else
        {
            a.array[0] = llvm_sqrt(b.array[0]);
            return a;
        }
    }
    else static if (GDC_with_SSE2)
    {
        __m128d c = __builtin_ia32_sqrtsd(b);
        a.ptr[0] = c.array[0];
        return a;
    }
    else
    {
        a.ptr[0] = sqrt(b.array[0]);
        return a;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(1.0, 3.0);
    __m128d B = _mm_setr_pd(4.0, 5.0);
    __m128d R = _mm_sqrt_sd(A, B);
    double[2] correct = [2.0, 3.0 ];
    assert(R.array == correct);
}

/// Shift packed 16-bit integers in `a` right by `count` while shifting in sign bits.
deprecated("Use _mm_srai_epi16 instead.") __m128i _mm_sra_epi16 (__m128i a, __m128i count) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psraw128(cast(short8)a, cast(short8)count);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psraw128(cast(short8)a, cast(short8)count);
    }
    else
    {
        short8 sa = cast(short8)a;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc.array[0]);
        short8 r = void;
        foreach(i; 0..8)
            r.ptr[i] = cast(short)(sa.array[i] >> bits);
        return cast(int4)r;
    }
}

/// Shift packed 32-bit integers in `a` right by `count` while shifting in sign bits.
deprecated("Use _mm_srai_epi32 instead.") __m128i _mm_sra_epi32 (__m128i a, __m128i count) pure @trusted
{
    static if (LDC_with_SSE2)
    {
        return __builtin_ia32_psrad128(a, count);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_psrad128(a, count);
    }
    else
    {    
        int4 r = void;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc.array[0]);
        r.ptr[0] = (a.array[0] >> bits);
        r.ptr[1] = (a.array[1] >> bits);
        r.ptr[2] = (a.array[2] >> bits);
        r.ptr[3] = (a.array[3] >> bits);
        return r;
    }
}


/// Shift packed 16-bit integers in `a` right by `imm8` while shifting in sign bits.
__m128i _mm_srai_epi16 (__m128i a, int imm8) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psrawi128(cast(short8)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psrawi128(cast(short8)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_ARM64)
    {
        short8 sa = cast(short8)a;
        ubyte count = cast(ubyte)imm8;
        if (count > 15) 
            count = 15;
        short8 r = sa >> short8(count);
        return cast(__m128i)r;
    }
    else
    {
        short8 sa = cast(short8)a;
        short8 r = void;

        // Note: the intrinsics guarantee imm8[0..7] is taken, however
        //       D says "It's illegal to shift by the same or more bits 
        //       than the size of the quantity being shifted"
        //       and it's UB instead.
        ubyte count = cast(ubyte)imm8;
        if (count > 15) 
            count = 15;
        foreach(i; 0..8)
            r.ptr[i] = cast(short)(sa.array[i] >> count);
        return cast(int4)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7);
    short8 B = cast(short8)( _mm_srai_epi16(A, 1) );
    short8 B2 = cast(short8)( _mm_srai_epi16(A, 1 + 256) );
    short[8] expectedB = [ 0, 0, 1, 1, -2, -3, 3, 3 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    short8 C = cast(short8)( _mm_srai_epi16(A, 18) );
    short[8] expectedC = [ 0, 0, 0, 0, -1, -1, 0, 0 ];
    assert(C.array == expectedC);
}

/// Shift packed 32-bit integers in `a` right by `imm8` while shifting in sign bits.
__m128i _mm_srai_epi32 (__m128i a, int imm8) pure @trusted
{
    static if (LDC_with_SSE2)
    {
        return __builtin_ia32_psradi128(a, cast(ubyte)imm8);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_psradi128(a, cast(ubyte)imm8);
    }
    else
    {
        int4 r = void;

        // Note: the intrinsics guarantee imm8[0..7] is taken, however
        //       D says "It's illegal to shift by the same or more bits 
        //       than the size of the quantity being shifted"
        //       and it's UB instead.
        // See Issue: #56
        ubyte count = cast(ubyte) imm8;
        if (count > 31)
            count = 31;

        r.ptr[0] = (a.array[0] >> count);
        r.ptr[1] = (a.array[1] >> count);
        r.ptr[2] = (a.array[2] >> count);
        r.ptr[3] = (a.array[3] >> count);
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(0, 2, 3, -4);
    __m128i B = _mm_srai_epi32(A, 1);
    __m128i B2 = _mm_srai_epi32(A, 1 + 256);
    int[4] expectedB = [ 0, 1, 1, -2];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    __m128i C = _mm_srai_epi32(A, 32);
    int[4] expectedC = [ 0, 0, 0, -1];
    assert(C.array == expectedC);

    __m128i D = _mm_srai_epi32(A, 0);
    int[4] expectedD = [ 0, 2, 3, -4];
    assert(D.array == expectedD);
}

deprecated("Use _mm_srli_epi16 instead.") __m128i _mm_srl_epi16 (__m128i a, __m128i count) pure @trusted
{
    static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psrlw128(cast(short8)a, cast(short8)count);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psrlw128(cast(short8)a, cast(short8)count);
    }
    else
    {
        short8 sa = cast(short8)a;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc.array[0]);
        short8 r = void;
        foreach(i; 0..8)
            r.ptr[i] = cast(short)(cast(ushort)(sa.array[i]) >> bits);
        return cast(int4)r;
    }
}

deprecated("Use _mm_srli_epi32 instead.") __m128i _mm_srl_epi32 (__m128i a, __m128i count) pure @trusted
{
    static if (LDC_with_SSE2)
    {
        return __builtin_ia32_psrld128(a, count);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_psrld128(a, count);
    }
    else
    {
        int4 r = void;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc.array[0]);
        r.ptr[0] = cast(uint)(a.array[0]) >> bits;
        r.ptr[1] = cast(uint)(a.array[1]) >> bits;
        r.ptr[2] = cast(uint)(a.array[2]) >> bits;
        r.ptr[3] = cast(uint)(a.array[3]) >> bits;
        return r;
    }
}

deprecated("Use _mm_srli_epi64 instead.") __m128i _mm_srl_epi64 (__m128i a, __m128i count) pure @trusted
{
    static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psrlq128(cast(long2)a, cast(long2)count);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psrlq128(cast(long2)a, cast(long2)count);
    }
    else
    {
        // Workaround for https://issues.dlang.org/show_bug.cgi?id=23047
        // => avoid void initialization.
        long2 r;
        long2 sa = cast(long2)a;
        long2 lc = cast(long2)count;
        int bits = cast(int)(lc.array[0]);
        r.ptr[0] = cast(ulong)(sa.array[0]) >> bits;
        r.ptr[1] = cast(ulong)(sa.array[1]) >> bits;
        return cast(__m128i)r;
    }
}

/// Shift packed 16-bit integers in `a` right by `imm8` while shifting in zeros.
__m128i _mm_srli_epi16 (__m128i a, int imm8) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psrlwi128(cast(short8)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psrlwi128(cast(short8)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_ARM64)
    {
        short8 sa = cast(short8)a;
        short8 r = cast(short8) _mm_setzero_si128();

        ubyte count = cast(ubyte)imm8;
        if (count >= 16)
            return cast(__m128i)r;

        r = sa >>> short8(count); // This facility offered with LDC, but not DMD.
        return cast(__m128i)r;
    }
    else
    {
        short8 sa = cast(short8)a;
        ubyte count = cast(ubyte)imm8;

        short8 r = cast(short8) _mm_setzero_si128();
        if (count >= 16)
            return cast(__m128i)r;

        foreach(i; 0..8)
            r.array[i] = cast(short)(cast(ushort)(sa.array[i]) >> count);
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, -4, -5, 6, 7);
    short8 B = cast(short8)( _mm_srli_epi16(A, 1) );
    short8 B2 = cast(short8)( _mm_srli_epi16(A, 1 + 256) );
    short[8] expectedB = [ 0, 0, 1, 1, 0x7FFE, 0x7FFD, 3, 3 ];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    short8 C = cast(short8)( _mm_srli_epi16(A, 16) );
    short[8] expectedC = [ 0, 0, 0, 0, 0, 0, 0, 0];
    assert(C.array == expectedC);

    short8 D = cast(short8)( _mm_srli_epi16(A, 0) );
    short[8] expectedD = [ 0, 1, 2, 3, -4, -5, 6, 7 ];
    assert(D.array == expectedD);
}


/// Shift packed 32-bit integers in `a` right by `imm8` while shifting in zeros.
__m128i _mm_srli_epi32 (__m128i a, int imm8) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_psrldi128(a, cast(ubyte)imm8);
    }
    else static if (LDC_with_SSE2)
    {
        return __builtin_ia32_psrldi128(a, cast(ubyte)imm8);
    }
    else
    {
        ubyte count = cast(ubyte) imm8;

        // Note: the intrinsics guarantee imm8[0..7] is taken, however
        //       D says "It's illegal to shift by the same or more bits 
        //       than the size of the quantity being shifted"
        //       and it's UB instead.
        int4 r = _mm_setzero_si128();
        if (count >= 32)
            return r;
        r.ptr[0] = a.array[0] >>> count;
        r.ptr[1] = a.array[1] >>> count;
        r.ptr[2] = a.array[2] >>> count;
        r.ptr[3] = a.array[3] >>> count;
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(0, 2, 3, -4);
    __m128i B = _mm_srli_epi32(A, 1);
    __m128i B2 = _mm_srli_epi32(A, 1 + 256);
    int[4] expectedB = [ 0, 1, 1, 0x7FFFFFFE];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);
 
    __m128i C = _mm_srli_epi32(A, 255);
    int[4] expectedC = [ 0, 0, 0, 0 ];
    assert(C.array == expectedC);
}

/// Shift packed 64-bit integers in `a` right by `imm8` while shifting in zeros.
__m128i _mm_srli_epi64 (__m128i a, int imm8) pure @trusted
{
    // PERF DMD
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psrlqi128(cast(long2)a, cast(ubyte)imm8);
    }
    else static if (LDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psrlqi128(cast(long2)a, cast(ubyte)imm8);
    }
    else
    {
        long2 r = cast(long2) _mm_setzero_si128();
        long2 sa = cast(long2)a;

        ubyte count = cast(ubyte) imm8;
        if (count >= 64)
            return cast(__m128i)r;

        r.ptr[0] = sa.array[0] >>> count;
        r.ptr[1] = sa.array[1] >>> count;
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi64(8, -4);
    long2 B = cast(long2) _mm_srli_epi64(A, 1);
    long2 B2 = cast(long2) _mm_srli_epi64(A, 1 + 512);
    long[2] expectedB = [ 4, 0x7FFFFFFFFFFFFFFE];
    assert(B.array == expectedB);
    assert(B2.array == expectedB);

    long2 C = cast(long2) _mm_srli_epi64(A, 64);
    long[2] expectedC = [ 0, 0 ];
    assert(C.array == expectedC);
}

/// Shift `v` right by `bytes` bytes while shifting in zeros.
__m128i _mm_srli_si128(ubyte bytes)(__m128i v) pure @trusted
{
    static if (bytes & 0xF0)
    {
        return _mm_setzero_si128();
    }
    else static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd_ib(XMM.PSRLDQ, v, bytes);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psrldqi128(cast(long2)v, cast(ubyte)(bytes * 8));
    }
    else static if (DMD_with_32bit_asm)
    {
        asm pure nothrow @nogc @trusted
        {
            movdqu XMM0, v;
            psrldq XMM0, bytes;
            movdqu v, XMM0;
        }
        return v;
    }
    else static if (LDC_with_optimizations)
    {
        return cast(__m128i) shufflevectorLDC!(byte16,
                                               bytes+0, bytes+1, bytes+2, bytes+3, bytes+4, bytes+5, bytes+6, bytes+7,
                                               bytes+8, bytes+9, bytes+10, bytes+11, bytes+12, bytes+13, bytes+14, bytes+15)
                                               (cast(byte16) v, cast(byte16)_mm_setzero_si128());
    }
    else
    {
        byte16 A = cast(byte16)v;
        byte16 R = void;
        for (int n = 0; n < bytes; ++n)
            R.ptr[15-n] = 0;
        for (int n = bytes; n < 16; ++n)
            R.ptr[15-n] = A.array[15 - n + bytes];
        return cast(__m128i)R;
    }
}
unittest
{
    __m128i R = _mm_srli_si128!4(_mm_set_epi32(4, 3, -2, 1));
    int[4] correct = [-2, 3, 4, 0];
    assert(R.array == correct);

    __m128i A = _mm_srli_si128!16(_mm_set1_epi32(-1));
    int[4] expectedA = [0, 0, 0, 0];
    assert(A.array == expectedA);
}

/// Shift `v` right by `bytes` bytes while shifting in zeros.
/// #BONUS
__m128 _mm_srli_ps(ubyte bytes)(__m128 v) pure @safe
{
    return cast(__m128)_mm_srli_si128!bytes(cast(__m128i)v);
}
unittest
{
    __m128 R = _mm_srli_ps!8(_mm_set_ps(4.0f, 3.0f, 2.0f, 1.0f));
    float[4] correct = [3.0f, 4.0f, 0, 0];
    assert(R.array == correct);
}

/// Shift `v` right by `bytes` bytes while shifting in zeros.
/// #BONUS
__m128d _mm_srli_pd(ubyte bytes)(__m128d v) pure @safe
{
    return cast(__m128d) _mm_srli_si128!bytes(cast(__m128i)v);
}

/// Store 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements) from `a` into memory. 
/// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
void _mm_store_pd (double* mem_addr, __m128d a) pure @trusted
{
    pragma(inline, true);
    __m128d* aligned = cast(__m128d*)mem_addr;
    *aligned = a;
}
unittest
{
    align(16) double[2] A;
    __m128d B = _mm_setr_pd(-8.0, 9.0);
    _mm_store_pd(A.ptr, B);
    assert(A == [-8.0, 9.0]);
}

/// Store the lower double-precision (64-bit) floating-point element from `a` into 2 contiguous elements in memory. 
/// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception may be generated.
void _mm_store_pd1 (double* mem_addr, __m128d a) pure @trusted
{
    __m128d* aligned = cast(__m128d*)mem_addr;
    __m128d r; // PERF =void;
    r.ptr[0] = a.array[0];
    r.ptr[1] = a.array[0];
    *aligned = r;
}

/// Store the lower double-precision (64-bit) floating-point element from `a` into memory. `mem_addr` does not need to 
/// be aligned on any particular boundary.
void _mm_store_sd (double* mem_addr, __m128d a) pure @safe
{
    pragma(inline, true);
    *mem_addr = a.array[0];
}

/// Store 128-bits of integer data from `a` into memory. `mem_addr` must be aligned on a 16-byte boundary or a 
/// general-protection exception may be generated.
void _mm_store_si128 (__m128i* mem_addr, __m128i a) pure @safe
{
    pragma(inline, true);
    *mem_addr = a;
}

alias _mm_store1_pd = _mm_store_pd1; ///

/// Store the upper double-precision (64-bit) floating-point element from `a` into memory.
void _mm_storeh_pd (double* mem_addr, __m128d a) pure @safe
{
    pragma(inline, true);
    *mem_addr = a.array[1];
}

// Note: `mem_addr` doesn't have to actually be aligned, which breaks
// expectations from the user point of view. This problem also exist in C++.
void _mm_storel_epi64 (__m128i* mem_addr, __m128i a) pure @safe
{
    pragma(inline, true);
    long* dest = cast(long*)mem_addr;
    long2 la = cast(long2)a;
    *dest = la.array[0];
}
unittest
{
    long[3] A = [1, 2, 3];
    _mm_storel_epi64(cast(__m128i*)(&A[1]), _mm_set_epi64x(0x1_0000_0000, 0x1_0000_0000));
    long[3] correct = [1, 0x1_0000_0000, 3];
    assert(A == correct);
}

/// Store the lower double-precision (64-bit) floating-point element from `a` into memory.
void _mm_storel_pd (double* mem_addr, __m128d a) pure @safe
{
    pragma(inline, true);
    *mem_addr = a.array[0];
}

/// Store 2 double-precision (64-bit) floating-point elements from `a` into memory in reverse 
/// order. `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception 
/// may be generated.
void _mm_storer_pd (double* mem_addr, __m128d a) pure @system
{
    __m128d reversed = void;
    reversed.ptr[0] = a.array[1];
    reversed.ptr[1] = a.array[0];
    *cast(__m128d*)mem_addr = reversed;
}
unittest
{
    align(16) double[2] A = [0.0, 1.0];
    _mm_storer_pd(A.ptr, _mm_setr_pd(2.0, 3.0));
    assert(A[0] == 3.0 && A[1] == 2.0);
}

/// Store 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements) from 
/// `a` into memory. `mem_addr` does not need to be aligned on any particular boundary.
void _mm_storeu_pd (double* mem_addr, __m128d a) pure @trusted // TODO: signature, should be system
{
    // PERF DMD
    pragma(inline, true);
    static if (GDC_with_SSE2)
    {
        __builtin_ia32_storeupd(mem_addr, a);
    }
    else static if (LDC_with_optimizations)
    {
        storeUnaligned!double2(a, mem_addr);
    }
    else
    {
        mem_addr[0] = a.array[0];
        mem_addr[1] = a.array[1];
    }
}
unittest
{
    __m128d A = _mm_setr_pd(3.0, 4.0);
    align(16) double[4] R = [0.0, 0, 0, 0];
    double[2] correct = [3.0, 4.0];
    _mm_storeu_pd(&R[1], A);
    assert(R[1..3] == correct);
}

/// Store 128-bits of integer data from `a` into memory. `mem_addr` does not need to be aligned on any particular 
/// boundary.
void _mm_storeu_si128 (__m128i* mem_addr, __m128i a) pure @trusted // TODO: signature is wrong, mem_addr is not aligned. Make it @system
{
    // PERF: DMD
    pragma(inline, true);
    static if (GDC_with_SSE2)
    {
        __builtin_ia32_storedqu(cast(char*)mem_addr, cast(ubyte16)a);
    }
    else static if (LDC_with_optimizations)
    {
        storeUnaligned!__m128i(a, cast(int*)mem_addr);
    }
    else
    {
        int* p = cast(int*)mem_addr;
        p[0] = a.array[0];
        p[1] = a.array[1];
        p[2] = a.array[2];
        p[3] = a.array[3];
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(1, 2, 3, 4);
    align(16) int[6] R = [0, 0, 0, 0, 0, 0];
    int[4] correct = [1, 2, 3, 4];
    _mm_storeu_si128(cast(__m128i*)(&R[1]), A);
    assert(R[1..5] == correct);
}

/// Store 16-bit integer from the first element of `a` into memory. 
/// `mem_addr` does not need to be aligned on any particular boundary.
void _mm_storeu_si16 (void* mem_addr, __m128i a) pure @system
{
    short* dest = cast(short*)mem_addr;
    *dest = (cast(short8)a).array[0];
}
unittest
{
    short[2] arr = [-24, 12];
    _mm_storeu_si16(&arr[1], _mm_set1_epi16(26));
    short[2] correct = [-24, 26];
    assert(arr == correct);
}

/// Store 32-bit integer from the first element of `a` into memory. 
/// `mem_addr` does not need to be aligned on any particular boundary.
void _mm_storeu_si32 (void* mem_addr, __m128i a) pure @trusted // TODO should really be @ssytem
{
    pragma(inline, true);
    int* dest = cast(int*)mem_addr;
    *dest = a.array[0];
}
unittest
{
    int[2] arr = [-24, 12];
    _mm_storeu_si32(&arr[1], _mm_setr_epi32(-1, -2, -6, -7));
    assert(arr == [-24, -1]);
}

/// Store 64-bit integer from the first element of `a` into memory. 
/// `mem_addr` does not need to be aligned on any particular boundary.
void _mm_storeu_si64 (void* mem_addr, __m128i a) pure @system
{
    pragma(inline, true);
    long* dest = cast(long*)mem_addr;
    long2 la = cast(long2)a;
    *dest = la.array[0];
}
unittest
{
    long[3] A = [1, 2, 3];
    _mm_storeu_si64(&A[1], _mm_set_epi64x(0x1_0000_0000, 0x1_0000_0000));
    long[3] correct = [1, 0x1_0000_0000, 3];
    assert(A == correct);
}

/// Store 128-bits (composed of 2 packed double-precision (64-bit) floating-point elements)
/// from `a` into memory using a non-temporal memory hint. `mem_addr` must be aligned on a 16-byte
/// boundary or a general-protection exception may be generated.
/// Note: non-temporal stores should be followed by `_mm_sfence()` for reader threads.
void _mm_stream_pd (double* mem_addr, __m128d a) pure @system
{
    // PERF DMD D_SIMD
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_movntpd(mem_addr, a); 
    }
    else static if (LDC_with_InlineIREx && LDC_with_optimizations)
    {
        enum prefix = `!0 = !{ i32 1 }`;
        enum ir = `
            store <2 x double> %1, <2 x double>* %0, align 16, !nontemporal !0
            ret void`;
        LDCInlineIREx!(prefix, ir, "", void, double2*, double2)(cast(double2*)mem_addr, a);
    }
    else
    {
        // Regular store instead.
        __m128d* dest = cast(__m128d*)mem_addr;
        *dest = a;
    }
}
unittest
{
    align(16) double[2] A;
    __m128d B = _mm_setr_pd(-8.0, 9.0);
    _mm_stream_pd(A.ptr, B);
    assert(A == [-8.0, 9.0]);
}

/// Store 128-bits of integer data from a into memory using a non-temporal memory hint.
/// `mem_addr` must be aligned on a 16-byte boundary or a general-protection exception
/// may be generated.
/// Note: non-temporal stores should be followed by `_mm_sfence()` for reader threads.
void _mm_stream_si128 (__m128i* mem_addr, __m128i a) pure @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_movntdq (cast(long2*)mem_addr, cast(long2)a); 
    }
    else static if (LDC_with_InlineIREx && LDC_with_optimizations)
    {
        enum prefix = `!0 = !{ i32 1 }`;
        enum ir = `
            store <4 x i32> %1, <4 x i32>* %0, align 16, !nontemporal !0
            ret void`;
        LDCInlineIREx!(prefix, ir, "", void, int4*, int4)(cast(int4*)mem_addr, a);
    }
    else
    {
        // Regular store instead.
        __m128i* dest = cast(__m128i*)mem_addr;
        *dest = a;
    }
}
unittest
{
    align(16) int[4] A;
    __m128i B = _mm_setr_epi32(-8, 9, 10, -11);
    _mm_stream_si128(cast(__m128i*)A.ptr, B);
    assert(A == [-8, 9, 10, -11]);
}

/// Store 32-bit integer a into memory using a non-temporal hint to minimize cache
/// pollution. If the cache line containing address `mem_addr` is already in the cache,
/// the cache will be updated.
/// Note: non-temporal stores should be followed by `_mm_sfence()` for reader threads.
void _mm_stream_si32 (int* mem_addr, int a) pure @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_movnti(mem_addr, a);
    }
    else static if (LDC_with_InlineIREx && LDC_with_optimizations)
    {
        enum prefix = `!0 = !{ i32 1 }`;
        enum ir = `
            store i32 %1, i32* %0, !nontemporal !0
            ret void`;
        LDCInlineIREx!(prefix, ir, "", void, int*, int)(mem_addr, a);
    }
    else
    {
        // Regular store instead.
        *mem_addr = a;
    }
}
unittest
{
    int A;
    _mm_stream_si32(&A, -34);
    assert(A == -34);
}

/// Store 64-bit integer a into memory using a non-temporal hint to minimize
/// cache pollution. If the cache line containing address `mem_addr` is already
/// in the cache, the cache will be updated.
/// Note: non-temporal stores should be followed by `_mm_sfence()` for reader threads.
void _mm_stream_si64 (long* mem_addr, long a) pure @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_movnti64(mem_addr, a);
    }
    else static if (LDC_with_InlineIREx && LDC_with_optimizations)
    {
        enum prefix = `!0 = !{ i32 1 }`;
        enum ir = `
            store i64 %1, i64* %0, !nontemporal !0
            ret void`;
        LDCInlineIREx!(prefix, ir, "", void, long*, long)(mem_addr, a);

    }
    else
    {
        // Regular store instead.
        *mem_addr = a;
    }
}
unittest
{
    long A;
    _mm_stream_si64(&A, -46);
    assert(A == -46);
}

/// Subtract packed 16-bit integers in `b` from packed 16-bit integers in `a`.
__m128i _mm_sub_epi16(__m128i a, __m128i b) pure @safe
{
    pragma(inline, true);
    return cast(__m128i)(cast(short8)a - cast(short8)b);
}
unittest
{
    __m128i A = _mm_setr_epi16(16,  32767, 1, 2,    3, 4, 6, 6);
    __m128i B = _mm_setr_epi16(15, -32768, 6, 8, 1000, 1, 5, 6);
    short8 C = cast(short8) _mm_sub_epi16(A, B);
    short[8] correct =        [ 1,     -1,-5,-6, -997, 3, 1, 0];
    assert(C.array == correct);
}

/// Subtract packed 32-bit integers in `b` from packed 32-bit integers in `a`.
__m128i _mm_sub_epi32(__m128i a, __m128i b) pure @safe
{
    pragma(inline, true);
    return cast(__m128i)(cast(int4)a - cast(int4)b);
}
unittest
{
    __m128i A = _mm_setr_epi32(16, int.max, 1, 8);
    __m128i B = _mm_setr_epi32(15, int.min, 6, 2);
    int4 C = cast(int4) _mm_sub_epi32(A, B);
    int[4] correct =          [ 1,      -1,-5, 6];
    assert(C.array == correct);
}

/// Subtract packed 64-bit integers in `b` from packed 64-bit integers in `a`.
__m128i _mm_sub_epi64(__m128i a, __m128i b) pure @safe
{
    pragma(inline, true);
    return cast(__m128i)(cast(long2)a - cast(long2)b);
}
unittest
{
    __m128i A = _mm_setr_epi64(  16, long.max);
    __m128i B = _mm_setr_epi64( 199, long.min);
    long2 C = cast(long2) _mm_sub_epi64(A, B);
    long[2] correct =         [-183,       -1];
    assert(C.array == correct);
}

/// Subtract packed 8-bit integers in `b` from packed 8-bit integers in `a`.
__m128i _mm_sub_epi8(__m128i a, __m128i b) pure @safe
{
    pragma(inline, true);
    return cast(__m128i)(cast(byte16)a - cast(byte16)b);
}
unittest
{
    __m128i A = _mm_setr_epi8(16,  127, 1, 2, 3, 4, 6, 6, 16,  127, 1, 2, 3, 4, 6, 6);
    __m128i B = _mm_setr_epi8(15, -128, 6, 8, 3, 1, 5, 6, 16,  127, 1, 2, 3, 4, 6, 6);
    byte16 C = cast(byte16) _mm_sub_epi8(A, B);
    byte[16] correct =       [ 1,   -1,-5,-6, 0, 3, 1, 0,  0,    0, 0, 0, 0, 0, 0, 0];
    assert(C.array == correct);
}

/// Subtract packed double-precision (64-bit) floating-point elements in `b` from packed double-precision (64-bit) 
/// floating-point elements in `a`.
__m128d _mm_sub_pd(__m128d a, __m128d b) pure @safe
{
    pragma(inline, true);
    return a - b;
}
unittest
{
    __m128d A = _mm_setr_pd(4000.0, -8.0);
    __m128d B = _mm_setr_pd(12.0, -8450.0);
    __m128d C = _mm_sub_pd(A, B);
    double[2] correct =     [3988.0, 8442.0];
    assert(C.array == correct);
}

/// Subtract the lower double-precision (64-bit) floating-point element in `b` from the lower double-precision (64-bit) 
/// floating-point element in `a`, store that in the lower element of result, and copy the upper element from `a` to the
/// upper element of result.
__m128d _mm_sub_sd(__m128d a, __m128d b) pure @trusted
{
    version(DigitalMars)
    {
        // Work-around for https://issues.dlang.org/show_bug.cgi?id=19599
        // Note that this is unneeded since DMD >= 2.094.0 at least, haven't investigated again
        asm pure nothrow @nogc @trusted { nop;}
        a[0] = a[0] - b[0];
        return a;
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_subsd(a, b);
    }
    else
    {
        a.ptr[0] -= b.array[0];
        return a;
    }
}
unittest
{
    __m128d a = [1.5, -2.0];
    a = _mm_sub_sd(a, a);
    assert(a.array == [0.0, -2.0]);
}

/// Subtract 64-bit integer `b` from 64-bit integer `a`.
__m64 _mm_sub_si64 (__m64 a, __m64 b) pure @safe
{
    pragma(inline, true);
    return a - b;
}
unittest
{
    __m64 A, B;
    A = -1214;
    B = 489415;
    __m64 C = _mm_sub_si64(B, A);
    assert(C.array[0] == 489415 + 1214);
}

/// Subtract packed signed 16-bit integers in `b` from packed 16-bit integers in `a` using
/// saturation.
__m128i _mm_subs_epi16(__m128i a, __m128i b) pure @trusted
{
    // PERF DMD psubsw
    version(LDC)
    {
        return cast(__m128i) inteli_llvm_subs!short8(cast(short8)a, cast(short8)b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psubsw128(cast(short8) a, cast(short8) b);
    }
    else
    {
        short[8] res; // PERF =void;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        foreach(i; 0..8)
            res.ptr[i] = saturateSignedIntToSignedShort(sa.array[i] - sb.array[i]);
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    short8 res = cast(short8) _mm_subs_epi16(_mm_setr_epi16(32760, -32760, 5, 4, 3, 2, 1, 0),
                                             _mm_setr_epi16(-10  ,     16, 5, 4, 3, 2, 1, 0));
    static immutable short[8] correctResult =              [32767, -32768, 0, 0, 0, 0, 0, 0];
    assert(res.array == correctResult);
}

/// Subtract packed signed 8-bit integers in `b` from packed 8-bit integers in `a` using
/// saturation.
__m128i _mm_subs_epi8(__m128i a, __m128i b) pure @trusted
{
    version(LDC)
    {
        return cast(__m128i) inteli_llvm_subs!byte16(cast(byte16)a, cast(byte16)b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psubsb128(cast(ubyte16) a, cast(ubyte16) b);
    }
    else
    {
        byte[16] res; // PERF =void;
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        foreach(i; 0..16)
            res[i] = saturateSignedWordToSignedByte(sa.array[i] - sb.array[i]);
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    byte16 res = cast(byte16) _mm_subs_epi8(_mm_setr_epi8(-128, 127, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
                                            _mm_setr_epi8(  15, -14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0));
    static immutable byte[16] correctResult            = [-128, 127,  0,  0,  0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    assert(res.array == correctResult);
}

/// Subtract packed 16-bit unsigned integers in `a` and `b` using unsigned saturation.
__m128i _mm_subs_epu16(__m128i a, __m128i b) pure @trusted
{
    version(LDC)
    {
        return cast(__m128i) inteli_llvm_subus!short8(cast(short8)a, cast(short8)b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psubusw128(cast(short8)a, cast(short8)b);
    }
    else
    {
        short[8] res; // PERF =void;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        foreach(i; 0..8)
        {
            int sum = cast(ushort)(sa.array[i]) - cast(ushort)(sb.array[i]);
            res[i] = saturateSignedIntToUnsignedShort(sum);
        }
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    short8 R = cast(short8) _mm_subs_epu16(_mm_setr_epi16(cast(short)65534,  1, 5, 4, 3, 2, 1, 0),
                                           _mm_setr_epi16(cast(short)65535, 16, 4, 4, 3, 0, 1, 0));
    static immutable short[8] correct =                  [               0,  0, 1, 0, 0, 2, 0, 0];
    assert(R.array == correct);
}

/// Subtract packed 8-bit unsigned integers in `a` and `b` using unsigned saturation.
__m128i _mm_subs_epu8(__m128i a, __m128i b) pure @trusted
{
    version(LDC)
    {
        return cast(__m128i) inteli_llvm_subus!byte16(cast(byte16)a, cast(byte16)b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_psubusb128(cast(ubyte16) a, cast(ubyte16) b);
    }
    else
    {
        ubyte[16] res; // PERF =void;
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        foreach(i; 0..16)
            res[i] = saturateSignedWordToUnsignedByte(cast(ubyte)(sa.array[i]) - cast(ubyte)(sb.array[i]));
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    byte16 res = cast(byte16) _mm_subs_epu8(_mm_setr_epi8(cast(byte)254, 127, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
                                            _mm_setr_epi8(cast(byte)255, 120, 14, 42, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0));
    static immutable byte[16] correctResult =            [            0,   7,  0,  0,  0,  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    assert(res.array == correctResult);
}

// Note: the only difference between these intrinsics is the signalling
//       behaviour of quiet NaNs. This is incorrect but the case where
//       you would want to differentiate between qNaN and sNaN and then
//       treat them differently on purpose seems extremely rare.
alias _mm_ucomieq_sd = _mm_comieq_sd; ///
alias _mm_ucomige_sd = _mm_comige_sd; ///
alias _mm_ucomigt_sd = _mm_comigt_sd; ///
alias _mm_ucomile_sd = _mm_comile_sd; ///
alias _mm_ucomilt_sd = _mm_comilt_sd; ///
alias _mm_ucomineq_sd = _mm_comineq_sd; ///

/// Return vector of type `__m128d` with undefined elements.
__m128d _mm_undefined_pd() pure @safe
{
    pragma(inline, true);
    __m128d result = void;
    return result;
}

/// Return vector of type `__m128i` with undefined elements.
__m128i _mm_undefined_si128() pure @safe
{
    pragma(inline, true);
    __m128i result = void;
    return result;
}

/// Unpack and interleave 16-bit integers from the high half of `a` and `b`.
__m128i _mm_unpackhi_epi16 (__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PUNPCKHWD, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_punpckhwd128(cast(short8) a, cast(short8) b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <8 x i16> %0, <8 x i16> %1, <8 x i32> <i32 4, i32 12, i32 5, i32 13, i32 6, i32 14, i32 7, i32 15>
                   ret <8 x i16> %r`;
        return cast(__m128i) LDCInlineIR!(ir, short8, short8, short8)(cast(short8)a, cast(short8)b);
    }
    else static if (DMD_with_32bit_asm || LDC_with_x86_asm)
    {
        asm pure nothrow @nogc @trusted
        {
            movdqu XMM0, a;
            movdqu XMM1, b;
            punpckhwd XMM0, XMM1;
            movdqu a, XMM0;
        }
        return a;
    }   
    else
    {
        short8 r = void;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        r.ptr[0] = sa.array[4];
        r.ptr[1] = sb.array[4];
        r.ptr[2] = sa.array[5];
        r.ptr[3] = sb.array[5];
        r.ptr[4] = sa.array[6];
        r.ptr[5] = sb.array[6];
        r.ptr[6] = sa.array[7];
        r.ptr[7] = sb.array[7];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(4,   5,  6,  7,  8,  9, 10, 11);
    __m128i B = _mm_setr_epi16(12, 13, 14, 15, 16, 17, 18, 19);
    short8 C = cast(short8)(_mm_unpackhi_epi16(A, B));
    short[8] correct = [8, 16, 9, 17, 10, 18, 11, 19];
    assert(C.array == correct);
}

/// Unpack and interleave 32-bit integers from the high half of `a` and `b`.
__m128i _mm_unpackhi_epi32 (__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PUNPCKHDQ, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_punpckhdq128(a, b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <4 x i32> %0, <4 x i32> %1, <4 x i32> <i32 2, i32 6, i32 3, i32 7>
                   ret <4 x i32> %r`;
        return LDCInlineIR!(ir, int4, int4, int4)(cast(int4)a, cast(int4)b);
    }
    else
    {
        __m128i r = void;
        r.ptr[0] = a.array[2];
        r.ptr[1] = b.array[2];
        r.ptr[2] = a.array[3];
        r.ptr[3] = b.array[3];
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(1, 2, 3, 4);
    __m128i B = _mm_setr_epi32(5, 6, 7, 8);
    __m128i C = _mm_unpackhi_epi32(A, B);
    int[4] correct = [3, 7, 4, 8];
    assert(C.array == correct);
}

/// Unpack and interleave 64-bit integers from the high half of `a` and `b`.
__m128i _mm_unpackhi_epi64 (__m128i a, __m128i b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_punpckhqdq128(cast(long2) a, cast(long2) b);
    }
    else
    {
        __m128i r = cast(__m128i)b;
        r[0] = a[2];
        r[1] = a[3];
        return r; 
    }
}
unittest // Issue #36
{
    __m128i A = _mm_setr_epi64(0x22222222_22222222, 0x33333333_33333333);
    __m128i B = _mm_setr_epi64(0x44444444_44444444, 0x55555555_55555555);
    long2 C = cast(long2)(_mm_unpackhi_epi64(A, B));
    long[2] correct = [0x33333333_33333333, 0x55555555_55555555];
    assert(C.array == correct);
}

/// Unpack and interleave 8-bit integers from the high half of `a` and `b`.
__m128i _mm_unpackhi_epi8 (__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PUNPCKHBW, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_punpckhbw128(cast(ubyte16)a, cast(ubyte16)b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <16 x i8> %0, <16 x i8> %1, <16 x i32> <i32 8, i32 24, i32 9, i32 25, i32 10, i32 26, i32 11, i32 27, i32 12, i32 28, i32 13, i32 29, i32 14, i32 30, i32 15, i32 31>
                   ret <16 x i8> %r`;
        return cast(__m128i)LDCInlineIR!(ir, byte16, byte16, byte16)(cast(byte16)a, cast(byte16)b);
    }
    else static if (DMD_with_32bit_asm || LDC_with_x86_asm)
    {
        asm pure nothrow @nogc @trusted
        {
            movdqu XMM0, a;
            movdqu XMM1, b;
            punpckhbw XMM0, XMM1;
            movdqu a, XMM0;
        }
        return a;
    }
    else
    {
        byte16 r = void;
        byte16 ba = cast(byte16)a;
        byte16 bb = cast(byte16)b;
        r.ptr[0] = ba.array[8];
        r.ptr[1] = bb.array[8];
        r.ptr[2] = ba.array[9];
        r.ptr[3] = bb.array[9];
        r.ptr[4] = ba.array[10];
        r.ptr[5] = bb.array[10];
        r.ptr[6] = ba.array[11];
        r.ptr[7] = bb.array[11];
        r.ptr[8] = ba.array[12];
        r.ptr[9] = bb.array[12];
        r.ptr[10] = ba.array[13];
        r.ptr[11] = bb.array[13];
        r.ptr[12] = ba.array[14];
        r.ptr[13] = bb.array[14];
        r.ptr[14] = ba.array[15];
        r.ptr[15] = bb.array[15];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi8( 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15);
    __m128i B = _mm_setr_epi8(16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31);
    byte16 C = cast(byte16) _mm_unpackhi_epi8(A, B);
    byte[16] correct = [8, 24, 9, 25, 10, 26, 11, 27, 12, 28, 13, 29, 14, 30, 15, 31];
    assert(C.array == correct);
}

/// Unpack and interleave double-precision (64-bit) floating-point elements from the high half of `a` and `b`.
__m128d _mm_unpackhi_pd (__m128d a, __m128d b) pure @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_unpckhpd(a, b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <2 x double> %0, <2 x double> %1, <2 x i32> <i32 1, i32 3>
                   ret <2 x double> %r`;
        return LDCInlineIR!(ir, double2, double2, double2)(a, b);
    }
    else
    {
        double2 r = void;
        r.ptr[0] = a.array[1];
        r.ptr[1] = b.array[1];
        return r;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(4.0, 6.0);
    __m128d B = _mm_setr_pd(7.0, 9.0);
    __m128d C = _mm_unpackhi_pd(A, B);
    double[2] correct = [6.0, 9.0];
    assert(C.array == correct);
}

/// Unpack and interleave 16-bit integers from the low half of `a` and `b`.
__m128i _mm_unpacklo_epi16 (__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PUNPCKLWD, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_punpcklwd128(cast(short8) a, cast(short8) b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <8 x i16> %0, <8 x i16> %1, <8 x i32> <i32 0, i32 8, i32 1, i32 9, i32 2, i32 10, i32 3, i32 11>
            ret <8 x i16> %r`;
        return cast(__m128i) LDCInlineIR!(ir, short8, short8, short8)(cast(short8)a, cast(short8)b);
    }
    else static if (DMD_with_32bit_asm || LDC_with_x86_asm)
    {
        asm pure nothrow @nogc @trusted
        {
            movdqu XMM0, a;
            movdqu XMM1, b;
            punpcklwd XMM0, XMM1;
            movdqu a, XMM0;
        }
        return a;
    }
    else
    {
        short8 r = void;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        r.ptr[0] = sa.array[0];
        r.ptr[1] = sb.array[0];
        r.ptr[2] = sa.array[1];
        r.ptr[3] = sb.array[1];
        r.ptr[4] = sa.array[2];
        r.ptr[5] = sb.array[2];
        r.ptr[6] = sa.array[3];
        r.ptr[7] = sb.array[3];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, 4, 5, 6, 7);
    __m128i B = _mm_setr_epi16(8, 9, 10, 11, 12, 13, 14, 15);
    short8 C = cast(short8) _mm_unpacklo_epi16(A, B);
    short[8] correct = [0, 8, 1, 9, 2, 10, 3, 11];
    assert(C.array == correct);
}

/// Unpack and interleave 32-bit integers from the low half of `a` and `b`.
__m128i _mm_unpacklo_epi32 (__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PUNPCKLDQ, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return __builtin_ia32_punpckldq128(a, b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <4 x i32> %0, <4 x i32> %1, <4 x i32> <i32 0, i32 4, i32 1, i32 5>
            ret <4 x i32> %r`;
        return LDCInlineIR!(ir, int4, int4, int4)(cast(int4)a, cast(int4)b);
    }
    else
    {
        __m128i r;
        r.ptr[0] = a.array[0];
        r.ptr[1] = b.array[0];
        r.ptr[2] = a.array[1];
        r.ptr[3] = b.array[1];
        return r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi32(1, 2, 3, 4);
    __m128i B = _mm_setr_epi32(5, 6, 7, 8);
    __m128i C = _mm_unpacklo_epi32(A, B);
    int[4] correct = [1, 5, 2, 6];
    assert(C.array == correct);
}

/// Unpack and interleave 64-bit integers from the low half of `a` and `b`.
__m128i _mm_unpacklo_epi64 (__m128i a, __m128i b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_punpcklqdq128(cast(long2) a, cast(long2) b);
    }
    else
    {
        long2 lA = cast(long2)a;
        long2 lB = cast(long2)b;
        long2 R; // PERF =void;
        R.ptr[0] = lA.array[0];
        R.ptr[1] = lB.array[0];
        return cast(__m128i)R;
    }
}
unittest // Issue #36
{
    __m128i A = _mm_setr_epi64(0x22222222_22222222, 0x33333333_33333333);
    __m128i B = _mm_setr_epi64(0x44444444_44444444, 0x55555555_55555555);
    long2 C = cast(long2)(_mm_unpacklo_epi64(A, B));
    long[2] correct = [0x22222222_22222222, 0x44444444_44444444];
    assert(C.array == correct);
}

/// Unpack and interleave 8-bit integers from the low half of `a` and `b`.
__m128i _mm_unpacklo_epi8 (__m128i a, __m128i b) pure @trusted
{
    static if (DMD_with_DSIMD)
    {
        return cast(__m128i) __simd(XMM.PUNPCKLBW, a, b);
    }
    else static if (GDC_with_SSE2)
    {
        return cast(__m128i) __builtin_ia32_punpcklbw128(cast(ubyte16) a, cast(ubyte16) b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <16 x i8> %0, <16 x i8> %1, <16 x i32> <i32 0, i32 16, i32 1, i32 17, i32 2, i32 18, i32 3, i32 19, i32 4, i32 20, i32 5, i32 21, i32 6, i32 22, i32 7, i32 23>
            ret <16 x i8> %r`;
        return cast(__m128i)LDCInlineIR!(ir, byte16, byte16, byte16)(cast(byte16)a, cast(byte16)b);
    }
    else static if (DMD_with_32bit_asm || LDC_with_x86_asm)
    {
        asm pure nothrow @nogc @trusted
        {
            movdqu XMM0, a;
            movdqu XMM1, b;
            punpcklbw XMM0, XMM1;
            movdqu a, XMM0;
        }
        return a;
    }
    else
    {
        byte16 r = void;
        byte16 ba = cast(byte16)a;
        byte16 bb = cast(byte16)b;
        r.ptr[0] = ba.array[0];
        r.ptr[1] = bb.array[0];
        r.ptr[2] = ba.array[1];
        r.ptr[3] = bb.array[1];
        r.ptr[4] = ba.array[2];
        r.ptr[5] = bb.array[2];
        r.ptr[6] = ba.array[3];
        r.ptr[7] = bb.array[3];
        r.ptr[8] = ba.array[4];
        r.ptr[9] = bb.array[4];
        r.ptr[10] = ba.array[5];
        r.ptr[11] = bb.array[5];
        r.ptr[12] = ba.array[6];
        r.ptr[13] = bb.array[6];
        r.ptr[14] = ba.array[7];
        r.ptr[15] = bb.array[7];
        return cast(__m128i)r;
    }
}
unittest
{
    __m128i A = _mm_setr_epi8( 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15);
    __m128i B = _mm_setr_epi8(16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31);
    byte16 C = cast(byte16) _mm_unpacklo_epi8(A, B);
    byte[16] correct = [0, 16, 1, 17, 2, 18, 3, 19, 4, 20, 5, 21, 6, 22, 7, 23];
    assert(C.array == correct);
}

/// Unpack and interleave double-precision (64-bit) floating-point elements from the low half of `a` and `b`.
__m128d _mm_unpacklo_pd (__m128d a, __m128d b) pure @trusted
{
    // PERF DMD D_SIMD
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_unpcklpd(a, b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <2 x double> %0, <2 x double> %1, <2 x i32> <i32 0, i32 2>
                   ret <2 x double> %r`;
        return LDCInlineIR!(ir, double2, double2, double2)(a, b);
    }
    else
    {
        double2 r = void;
        r.ptr[0] = a.array[0];
        r.ptr[1] = b.array[0];
        return r;
    }
}
unittest
{
    __m128d A = _mm_setr_pd(4.0, 6.0);
    __m128d B = _mm_setr_pd(7.0, 9.0);
    __m128d C = _mm_unpacklo_pd(A, B);
    double[2] correct = [4.0, 7.0];
    assert(C.array == correct);
}

/// Compute the bitwise XOR of packed double-precision (64-bit) floating-point elements in `a` and `b`.
__m128d _mm_xor_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d)(cast(__m128i)a ^ cast(__m128i)b);
}
unittest
{
    __m128d A = _mm_setr_pd(-4.0, 6.0);
    __m128d B = _mm_setr_pd(4.0, -6.0);
    long2 R = cast(long2) _mm_xor_pd(A, B);
    long[2] correct = [long.min, long.min];
    assert(R.array == correct);
}

/// Compute the bitwise XOR of 128 bits (representing integer data) in `a` and `b`.
__m128i _mm_xor_si128 (__m128i a, __m128i b) pure @safe
{
    return a ^ b;
}
unittest
{
    __m128i A = _mm_setr_epi64(975394, 619809709);
    __m128i B = _mm_setr_epi64(-920275025, -6);
    long2 R = cast(long2) _mm_xor_si128(A, B);
    long[2] correct = [975394 ^ (-920275025L), 619809709L ^ -6];
    assert(R.array == correct);
}

unittest
{
    float distance(float[4] a, float[4] b) nothrow @nogc
    {
        __m128 va = _mm_loadu_ps(a.ptr);
        __m128 vb = _mm_loadu_ps(b.ptr);
        __m128 diffSquared = _mm_sub_ps(va, vb);
        diffSquared = _mm_mul_ps(diffSquared, diffSquared);
        __m128 sum = _mm_add_ps(diffSquared, _mm_srli_ps!8(diffSquared));
        sum = _mm_add_ps(sum, _mm_srli_ps!4(sum));
        return _mm_cvtss_f32(_mm_sqrt_ss(sum));
    }
    assert(distance([0, 2, 0, 0], [0, 0, 0, 0]) == 2);
}
