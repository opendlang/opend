/**
* Copyright: Copyright Auburn Sounds 2016-2018.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.emmintrin;

public import inteli.types;
public import inteli.xmmintrin; // SSE2 includes SSE1

import inteli.internals;

nothrow @nogc:

// SSE2 instructions
// https://software.intel.com/sites/landingpage/IntrinsicsGuide/#techs=SSE2

__m128i _mm_add_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(short8)a + cast(short8)b);
}

__m128i _mm_add_epi32 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(int4)a + cast(int4)b);
}

__m128i _mm_add_epi64 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(long2)a + cast(long2)b);
}

__m128i _mm_add_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(byte16)a + cast(byte16)b);
}

__m128d _mm_add_sd(__m128d a, __m128d b) pure @safe
{
    a[0] += b[0];
    return a;
}
unittest
{
    __m128d a = [1.5, -2.0];
    a = _mm_add_sd(a, a);
    assert(a.array == [3.0, -2.0]);
}


__m128d _mm_add_pd (__m128d a, __m128d b) pure @safe
{
    return a + b;
}
unittest
{
    __m128d a = [1.5, -2.0];
    a = _mm_add_pd(a, a);
    assert(a.array == [3.0, -4.0]);
}

// MMXREG: _mm_add_si64

version(LDC)
{
    alias _mm_adds_epi16 = __builtin_ia32_paddsw128;
}
else
{
    __m128i _mm_adds_epi16(__m128i a, __m128i b) pure @trusted
    {
        short[8] res;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        foreach(i; 0..8)
            res[i] = saturateSignedIntToSignedShort(sa.array[i] + sb.array[i]);
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    short8 res = cast(short8) _mm_adds_epi16(_mm_set_epi16(7, 6, 5, 4, 3, 2, 1, 0),
                                             _mm_set_epi16(7, 6, 5, 4, 3, 2, 1, 0));
    static immutable short[8] correctResult = [0, 2, 4, 6, 8, 10, 12, 14];
    assert(res.array == correctResult);
}

version(LDC)
{
    alias _mm_adds_epi8 = __builtin_ia32_paddsb128;
}
else
{
    __m128i _mm_adds_epi8(__m128i a, __m128i b) pure @trusted
    {
        byte[16] res;
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        foreach(i; 0..16)
            res[i] = saturateSignedWordToSignedByte(sa.array[i] + sb.array[i]);
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}
unittest
{
    byte16 res = cast(byte16) _mm_adds_epi8(_mm_set_epi8(15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
                                            _mm_set_epi8(15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0));
    static immutable byte[16] correctResult = [0, 2, 4, 6, 8, 10, 12, 14,
                                               16, 18, 20, 22, 24, 26, 28, 30];
    assert(res.array == correctResult);
}

version(LDC)
{
    alias _mm_adds_epu8 = __builtin_ia32_paddusb128;
}
else
{
    __m128i _mm_adds_epu8(__m128i a, __m128i b) pure @trusted
    {
        ubyte[16] res;
        byte16 sa = cast(byte16)a;
        byte16 sb = cast(byte16)b;
        foreach(i; 0..16)
            res[i] = saturateSignedWordToUnsignedByte(cast(ubyte)(sa.array[i]) + cast(ubyte)(sb.array[i]));
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}

version(LDC)
{
    alias _mm_adds_epu16 = __builtin_ia32_paddusw128;
}
else
{
    __m128i _mm_adds_epu16(__m128i a, __m128i b) pure @trusted
    {
        ushort[8] res;
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        foreach(i; 0..8)
            res[i] = saturateSignedIntToUnsignedShort(cast(ushort)(sa.array[i]) + cast(ushort)(sb.array[i]));
        return _mm_loadu_si128(cast(int4*)res.ptr);
    }
}

__m128d _mm_and_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d)( cast(__m128i)a & cast(__m128i)b );
}

__m128i _mm_and_si128 (__m128i a, __m128i b) pure @safe
{
    return a & b;
}

__m128d _mm_andnot_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d)( (~cast(__m128i)a) & cast(__m128i)b );
}

__m128i _mm_andnot_si128 (__m128i a, __m128i b) pure @safe
{
    return (~a) & b;
}

version(LDC)
{
    pragma(LDC_intrinsic, "llvm.x86.sse2.pavg.w")
        short8 _mm_avg_epu16(short8, short8) pure @safe;

    pragma(LDC_intrinsic, "llvm.x86.sse2.pavg.b")
        byte16 _mm_avg_epu8(byte16, byte16) pure @safe;
}
// TODO


// TODO: __m128i _mm_bslli_si128 (__m128i a, int imm8)
// TODO: __m128i _mm_bsrli_si128 (__m128i a, int imm8)

__m128 _mm_castpd_ps (__m128d a) pure @safe
{
    return cast(__m128)a;
}

__m128i _mm_castpd_si128 (__m128d a) pure @safe
{
    return cast(__m128i)a;
}

__m128d _mm_castps_pd (__m128 a) pure @safe
{
    return cast(__m128d)a;
}

__m128i _mm_castps_si128 (__m128 a) pure @safe
{
    return cast(__m128i)a;
}

__m128d _mm_castsi128_pd (__m128i a) pure @safe
{
    return cast(__m128d)a;
}

__m128 _mm_castsi128_ps (__m128i a) pure @safe
{
    return cast(__m128)a;
}

version(LDC)
{
    alias _mm_clflush = __builtin_ia32_clflush;
}
// TODO

version(LDC)
{
    // just used for "ord" intrinsics
    pragma(LDC_intrinsic, "llvm.x86.sse2.cmp.pd")
        double2 __builtin_ia32_cmppd(double2, double2, byte) pure @safe;
}

__m128i _mm_cmpeq_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) equalMask!short8(cast(short8)a, cast(short8)b);
}
unittest
{
    short8   A = [-3, -2, -1,  0,  0,  1,  2,  3];
    short8   B = [ 4,  3,  2,  1,  0, -1, -2, -3];
    short[8] E = [ 0,  0,  0,  0, -1,  0,  0,  0];
    short8   R = cast(short8)(_mm_cmpeq_epi16(cast(__m128i)A, cast(__m128i)B));
    assert(R.array == E);
}

__m128i _mm_cmpeq_epi32 (__m128i a, __m128i b) pure @safe
{
    return equalMask!__m128i(a, b);
}
unittest
{
    int4   A = [-3, -2, -1,  0];
    int4   B = [ 4, -2,  2,  0];
    int[4] E = [ 0, -1,  0, -1];
    int4   R = cast(int4)(_mm_cmpeq_epi16(A, B));
    assert(R.array == E);
}

__m128i _mm_cmpeq_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) equalMask!byte16(cast(byte16)a, cast(byte16)b);
}
unittest
{
    __m128i A = _mm_setr_epi8(1, 2, 3, 1, 2, 1, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1);
    __m128i B = _mm_setr_epi8(2, 2, 1, 2, 3, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1, 1);
    byte16 C = cast(byte16) _mm_cmpeq_epi8(A, B);
    byte[16] correct =       [0,-1, 0, 0, 0,-1, 0, 0, 0, 0, 0,-1, 0, 0, 0, -1];
    __m128i D = _mm_cmpeq_epi8(A, B);
    assert(C.array == correct);
}


version(LDC)
{
    __m128d _mm_cmpeq_pd (__m128d a, __m128d b) pure @safe // TODO
    {
        return cast(__m128d) equalMask!double2(a, b);
    }

    __m128d _mm_cmpeq_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(a, b, 0);
    }

    __m128d _mm_cmpge_pd (__m128d a, __m128d b) pure @safe // TODO
    {
        return cast(__m128d) greaterOrEqualMask!double2(a, b);
    }

    __m128d _mm_cmpge_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(b, a, 2);
    }
}


__m128i _mm_cmpgt_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( greaterMask!short8(cast(short8)a, cast(short8)b));
}
unittest
{
    short8   A = [-3, -2, -1,  0,  0,  1,  2,  3];
    short8   B = [ 4,  3,  2,  1,  0, -1, -2, -3];
    short[8] E = [ 0,  0,  0,  0,  0, -1, -1, -1];
    short8   R = cast(short8)(_mm_cmpgt_epi16(cast(__m128i)A, cast(__m128i)B));
    assert(R.array == E);
}

__m128i _mm_cmpgt_epi32 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( greaterMask!int4(a, b));
}
unittest
{
    int4   A = [-3,  2, -1,  0];
    int4   B = [ 4, -2,  2,  0];
    int[4] E = [ 0, -1,  0,  0];
    int4   R = cast(int4)(_mm_cmpgt_epi32(A, B));
    assert(R.array == E);
}

__m128i _mm_cmpgt_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( greaterMask!byte16(cast(byte16)a, cast(byte16)b));
}
unittest
{
    __m128i A = _mm_setr_epi8(1, 2, 3, 1, 2, 1, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1);
    __m128i B = _mm_setr_epi8(2, 2, 1, 2, 3, 1, 2, 3, 2, 1, 0, 0, 1, 2, 1, 1);
    byte16 C = cast(byte16) _mm_cmpgt_epi8(A, B);
    byte[16] correct =       [0, 0,-1, 0, 0, 0, 0, 0,-1,-1,-1, 0, 0, 0,-1, 0];
    __m128i D = _mm_cmpeq_epi8(A, B);
    assert(C.array == correct);
}

version(LDC)
{

    __m128d _mm_cmpgt_pd (__m128d a, __m128d b) pure @safe // TODO
    {
        return cast(__m128d) greaterMask!double2(a, b);
    }

    __m128d _mm_cmpgt_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(b, a, 1);
    }

    __m128d _mm_cmple_pd (__m128d a, __m128d b) pure @safe // TODO
    {
        return cast(__m128d) greaterOrEqualMask!double2(b, a);
    }

    __m128d _mm_cmple_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(a, b, 2);
    }
}


__m128i _mm_cmplt_epi16 (__m128i a, __m128i b) pure @safe
{
    return _mm_cmpgt_epi16(b, a);
}

__m128i _mm_cmplt_epi32 (__m128i a, __m128i b) pure @safe
{
    return _mm_cmpgt_epi32(b, a);
}

__m128i _mm_cmplt_epi8 (__m128i a, __m128i b) pure @safe
{
    return _mm_cmpgt_epi8(b, a);
}

version(LDC)
{
    __m128d _mm_cmplt_pd (__m128d a, __m128d b) pure @safe // TODO
    {
        return cast(__m128d) greaterMask!double2(b, a);
    }

    __m128d _mm_cmplt_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(a, b, 1);
    }

    __m128d _mm_cmpneq_pd (__m128d a, __m128d b) pure @safe // TODO
    {
        return cast(__m128d) notEqualMask!double2(a, b);
    }

    __m128d _mm_cmpneq_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(a, b, 4);
    }

    __m128d _mm_cmpnge_pd (__m128d a, __m128d b) pure @safe
    {
        // TODO Incorrect for NaN
        return _mm_cmplt_pd(b, a);
    }

    __m128d _mm_cmpnge_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(b, a, 6);
    }

    __m128d _mm_cmpngt_pd (__m128d a, __m128d b) pure @safe // TODO
    {
        // TODO: Incorrect for NaN
        return _mm_cmple_pd(b, a);
    }

    __m128d _mm_cmpngt_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(b, a, 5);
    }

    __m128d _mm_cmpnle_pd (__m128d a, __m128d b) pure @safe // TODO
    {
        // TODO: Incorrect for NaN
        return _mm_cmpgt_pd(b, a);
    }

    __m128d _mm_cmpnle_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(a, b, 6);
    }

    __m128d _mm_cmpnlt_pd (__m128d a, __m128d b) pure @safe // TODO
    {
        // TODO: Incorrect for NaN
        return _mm_cmpge_pd(b, a);
    }

    __m128d _mm_cmpnlt_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(a, b, 5);
    }

    __m128d _mm_cmpord_pd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmppd(a, b, 7);
    }

    __m128d _mm_cmpord_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(a, b, 7);
    }

    __m128d _mm_cmpunord_pd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmppd(a, b, 3);
    }

    __m128d _mm_cmpunord_sd (__m128d a, __m128d b) pure @safe // TODO
    {
        return __builtin_ia32_cmpsd(a, b, 3);
    }
}

version(LDC)
{
    alias _mm_comieq_sd = __builtin_ia32_comisdeq; // TODO
    alias _mm_comige_sd = __builtin_ia32_comisdge; // TODO
    alias _mm_comigt_sd = __builtin_ia32_comisdgt; // TODO
    alias _mm_comile_sd = __builtin_ia32_comisdle; // TODO
    alias _mm_comilt_sd = __builtin_ia32_comisdlt; // TODO
    alias _mm_comineq_sd = __builtin_ia32_comisdneq; // TODO
}

// TODO: alias _mm_cvtepi32_pd = __builtin_ia32_cvtdq2pd;

// PERF: replace with __builtin_convertvector when available
__m128 _mm_cvtepi32_ps(__m128i a) pure @safe
{
    __m128 res;
    res.array[0] = cast(float)a.array[0];
    res.array[1] = cast(float)a.array[1];
    res.array[2] = cast(float)a.array[2];
    res.array[3] = cast(float)a.array[3];
    return res;
}
unittest
{
    __m128 a = _mm_cvtepi32_ps(_mm_setr_epi32(-1, 0, 1, 1000));
    assert(a.array == [-1.0f, 0.0f, 1.0f, 1000.0f]);
}


version(LDC) // TODO
{
    alias _mm_cvtpd_epi32 = __builtin_ia32_cvtpd2dq;
}

// MMXREG: _mm_cvtpd_pi32
version(LDC)
{
    alias _mm_cvtpd_ps = __builtin_ia32_cvtpd2ps;
// MMXREG: _mm_cvtpi32_pd
    alias _mm_cvtps_epi32 = __builtin_ia32_cvtps2dq;
}
// TODO

// TODO: alias _mm_cvtps_pd = __builtin_ia32_cvtps2pd;

double _mm_cvtsd_f64 (__m128d a) pure @safe
{
    return extractelement!(double2, 0)(a);
}

version(LDC)
{
    alias _mm_cvtsd_si32 = __builtin_ia32_cvtsd2si;
    alias _mm_cvtsd_si64 = __builtin_ia32_cvtsd2si64;
    alias _mm_cvtsd_si64x = _mm_cvtsd_si64;
}
// TODO

version(LDC)
{
    alias _mm_cvtsd_ss = __builtin_ia32_cvtsd2ss;
}
// TODO

int _mm_cvtsi128_si32 (__m128i a) pure @safe
{
    return a[0];
}

long _mm_cvtsi128_si64 (__m128i a) pure @safe
{
    long2 la = cast(long2)a;
    return la[0];
}
alias _mm_cvtsi128_si64x = _mm_cvtsi128_si64;

__m128d _mm_cvtsi32_sd(__m128d v, int x) pure @safe
{
    v[0] = cast(double)x;
    return v;
}
unittest
{
    __m128d a = _mm_cvtsi32_sd(_mm_set1_pd(0.0f), 42);
    assert(a.array == [42.0, 0]);
}

__m128i _mm_cvtsi32_si128 (int a) pure @safe
{
    int4 r = [0, 0, 0, 0];
    r[0] = a;
    return r;
}

// Note: on macOS, using "llvm.x86.sse2.cvtsi642sd" was buggy
__m128d _mm_cvtsi64_sd(__m128d v, long x) pure @safe
{
    v[0] = cast(double)x;
    return v;
}
unittest
{
    __m128d a = _mm_cvtsi64_sd(_mm_set1_pd(0.0f), 42);
    assert(a.array == [42.0, 0]);
}

__m128i _mm_cvtsi64_si128 (long a) pure @safe
{
    long2 r = [0, 0];
    r[0] = a;
    return cast(__m128i)(r);
}

alias _mm_cvtsi64x_sd = _mm_cvtsi64_sd;
alias _mm_cvtsi64x_si128 = _mm_cvtsi64_si128;

double2 _mm_cvtss_sd(double2 v, float4 x) pure @safe
{
    v[0] = x[0];
    return v;
}
unittest
{
    __m128d a = _mm_cvtss_sd(_mm_set1_pd(0.0f), _mm_set1_ps(42.0f));
    assert(a.array == [42.0, 0]);
}

version(LDC)
{
    alias _mm_cvttpd_epi32 = __builtin_ia32_cvttpd2dq;
    //MMXREG: _mm_cvttpd_pi32
    alias _mm_cvttps_epi32 = __builtin_ia32_cvttps2dq;
    alias _mm_cvttsd_si32 = __builtin_ia32_cvttsd2si;
    alias _mm_cvttsd_si64 = __builtin_ia32_cvttsd2si64;
    alias _mm_cvttsd_si64x = _mm_cvttsd_si64;
}
// TODO



__m128d _mm_div_ps(__m128d a, __m128d b)
{
    return a / b;
}

__m128d _mm_div_sd(__m128d a, __m128d b) pure @safe
{
    a[0] /= b[0];
    return a;
}
unittest
{
    __m128d a = [2.0, 4.5];
    a = _mm_div_sd(a, a);
    assert(a.array == [1.0, 4.5]);
}

int _mm_extract_epi16(int imm8)(__m128i a) pure @safe
{
    return shufflevector!(short8, imm8)(a);
}

__m128i _mm_insert_epi16(int imm8)(__m128i a, int i) pure @safe
{
    return insertelement!(short8, imm8)(a, i);
}

version(LDC)
{
    alias _mm_lfence = __builtin_ia32_lfence;
}
// TODO


__m128d _mm_load_pd (const(double) * mem_addr) pure
{
    __m128d* aligned = cast(__m128d*)mem_addr;
    return *aligned;
}

__m128d _mm_load_pd1 (const(double)* mem_addr) pure
{
    double[2] arr = [*mem_addr, *mem_addr];
    return loadUnaligned!(double2)(&arr[0]);
}

__m128d _mm_load_sd (const(double)* mem_addr) pure @safe
{
    double2 r = [0, 0];
    r[0] = *mem_addr;
    return r;
}
unittest
{
    double x = -42;
    __m128d a = _mm_load_sd(&x);
    assert(a.array == [-42.0, 0.0]);
}

__m128i _mm_load_si128 (const(__m128i)* mem_addr) pure @trusted
{
    return *mem_addr;
}

alias _mm_load1_pd = _mm_load_pd1;

__m128d _mm_loadh_pd (__m128d a, const(double)* mem_addr) pure @safe
{
    a[1] = *mem_addr;
    return a;
}

// Note: strange signature since the memory doesn't have to aligned
__m128i _mm_loadl_epi64 (const(__m128i)* mem_addr) pure @safe
{
    auto pLong = cast(const(long)*)mem_addr;
    long2 r = [0, 0];
    r[0] = *pLong;
    return cast(__m128i)(r);
}

__m128d _mm_loadl_pd (__m128d a, const(double)* mem_addr) pure @safe
{
    a[0] = *mem_addr;
    return a;
}

__m128d _mm_loadr_pd (const(double)* mem_addr) pure @trusted
{
    __m128d a = _mm_load_pd(mem_addr);
    return shufflevector!(__m128d, 1, 0)(a, a);
}

__m128d _mm_loadu_pd (const(double)* mem_addr) pure @safe
{
    return loadUnaligned!(double2)(mem_addr);
}

__m128i _mm_loadu_si128 (const(__m128i)* mem_addr) pure @trusted
{
    return loadUnaligned!(__m128i)(cast(int*)mem_addr);
}

__m128i _mm_loadu_si32 (const(void)* mem_addr) pure @trusted
{
    int r = *cast(int*)(mem_addr);
    int4 result = [0, 0, 0, 0];
    result[0] = r;
    return result;
}
unittest
{
    int r = 42;
    __m128i A = _mm_loadu_si32(&r);
    int[4] correct = [42, 0, 0, 0];
    assert(A.array == correct);
}

version(LDC)
{
    alias _mm_madd_epi16 = __builtin_ia32_pmaddwd128;

    alias _mm_maskmoveu_si128 = __builtin_ia32_maskmovdqu;

    pragma(LDC_intrinsic, "llvm.x86.sse2.pmaxs.w")
        short8 __builtin_ia32_pmaxsw128(short8, short8) pure @safe;
    alias _mm_max_epi16 = __builtin_ia32_pmaxsw128;

    pragma(LDC_intrinsic, "llvm.x86.sse2.pmaxu.b")
        byte16 __builtin_ia32_pmaxub128(byte16, byte16) pure @safe;
    alias _mm_max_epu8 = __builtin_ia32_pmaxub128;

    alias _mm_max_pd = __builtin_ia32_maxpd;
    alias _mm_max_sd = __builtin_ia32_maxsd;

    alias _mm_mfence = __builtin_ia32_mfence;

    pragma(LDC_intrinsic, "llvm.x86.sse2.pmins.w")
        short8 __builtin_ia32_pminsw128(short8, short8) pure @safe;
    alias _mm_min_epi16 = __builtin_ia32_pminsw128;

    pragma(LDC_intrinsic, "llvm.x86.sse2.pminu.b")
        byte16 __builtin_ia32_pminub128(byte16, byte16) pure @safe;
    alias _mm_min_epu8 = __builtin_ia32_pminub128;

    alias _mm_min_pd = __builtin_ia32_minpd;
    alias _mm_min_sd = __builtin_ia32_minsd;
}
// TODO

__m128i _mm_move_epi64 (__m128i a) pure @safe
{
    long2 result = [ 0, 0 ];
    long2 la = cast(long2) a;
    result[0] = la[0];
    return cast(__m128i)(result);
}
unittest
{
    long2 A = [13, 47];
    long2 B = cast(long2) _mm_move_epi64( cast(__m128i)A );
    long[2] correct = [13, 0];
    assert(B.array == correct);
}

__m128d _mm_move_sd (__m128d a, __m128d b) pure @safe
{
    b[1] = a[1];
    return b;
}
unittest
{
    double2 A = [13.0, 47.0];
    double2 B = [34.0, 58.0];
    double2 C = _mm_move_sd(A, B);
    double[2] correct = [34.0, 47.0];
    assert(C.array == correct);
}

version(LDC)
{
    alias _mm_movemask_epi8 = __builtin_ia32_pmovmskb128;
    alias _mm_movemask_pd = __builtin_ia32_movmskpd;
}

// MMXREG: _mm_movepi64_pi64
// MMXREG: __m128i _mm_movpi64_epi64 (__m64 a)

// PERF: unfortunately, __builtin_ia32_pmuludq128 disappeared from LDC
// but seems there in clang
__m128i _mm_mul_epu32(__m128i a, __m128i b) pure @safe
{
    __m128i zero = _mm_setzero_si128();
    long2 la = cast(long2) shufflevector!(int4, 0, 4, 2, 6)(a, zero);
    long2 lb = cast(long2) shufflevector!(int4, 0, 4, 2, 6)(b, zero);
    static if (__VERSION__ >= 2076)
    {
        return cast(__m128i)(la * lb);
    }
    else
    {
        // long2 mul not supported before LDC 1.5
        la[0] *= lb[0];
        la[1] *= lb[1];
        return cast(__m128i)(la);
    }
}
unittest
{
    __m128i A = _mm_set_epi32(0, 0xDEADBEEF, 0, 0xffffffff);
    __m128i B = _mm_set_epi32(0, 0xCAFEBABE, 0, 0xffffffff);
    __m128i C = _mm_mul_epu32(A, B);
    long2 LC = cast(long2)C;
    assert(LC.array[0] == 18446744065119617025uL);
    assert(LC.array[1] == 12723420444339690338uL);
}


__m128d _mm_mul_pd(__m128d a, __m128d b) pure @safe
{
    return a * b;
}
unittest
{
    __m128d a = [-2.0, 1.5];
    a = _mm_mul_pd(a, a);
    assert(a.array == [4.0, 2.25]);
}

__m128d _mm_mul_sd(__m128d a, __m128d b) pure @safe
{
    a[0] *= b[0];
    return a;
}
unittest
{
    __m128d a = [-2.0, 1.5];
    a = _mm_mul_sd(a, a);
    assert(a.array == [4.0, 1.5]);
}


// MMXREG: _mm_mul_su32

version(LDC)
{
    alias _mm_mulhi_epi16 = __builtin_ia32_pmulhw128;
    alias _mm_mulhi_epu16 = __builtin_ia32_pmulhuw128;
}
// TODO

__m128i _mm_mullo_epi16 (__m128i a, __m128i b)
{
    return cast(__m128i)(cast(short8)a * cast(short8)b);
}

__m128d _mm_or_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d)( cast(__m128i)a | cast(__m128i)b );
}

__m128i _mm_or_si128 (__m128i a, __m128i b) pure @safe
{
    return a | b;
}

version(LDC)
{
    alias _mm_packs_epi32 = __builtin_ia32_packssdw128;
    alias _mm_packs_epi16 = __builtin_ia32_packsswb128;
}
version(LDC)
{
    alias _mm_packus_epi16 = __builtin_ia32_packuswb128;
}
else
{
    __m128i _mm_packus_epi16 (__m128i a, __m128i b) pure
    {
        short8 sa = cast(short8)a;
        short8 sb = cast(short8)b;
        ubyte[16] result = void;
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
        return cast(__m128i) loadUnaligned!(byte16)(cast(byte*)result.ptr);
    }
}
unittest
{
    __m128i A = _mm_setr_epi16(-10, 400, 0, 256, 255, 2, 1, 0);
    byte16 AA = cast(byte16) _mm_packus_epi16(A, A);
    static immutable ubyte[16] correctResult = [0, 255, 0, 255, 255, 2, 1, 0,
                                                0, 255, 0, 255, 255, 2, 1, 0];
    foreach(i; 0..16)
        assert(AA[i] == cast(byte)(correctResult[i]));
}

// TODO
version(LDC)
{
    alias _mm_pause = __builtin_ia32_pause;
}
// TODO

version(LDC)
{
    alias _mm_sad_epu8 = __builtin_ia32_psadbw128;
}
// TODO

__m128i _mm_set_epi16 (short e7, short e6, short e5, short e4, short e3, short e2, short e1, short e0) pure @trusted
{
    short[8] result = [e0, e1, e2, e3, e4, e5, e6, e7];
    return cast(__m128i) loadUnaligned!(short8)(result.ptr);
}
unittest
{
    __m128i A = _mm_set_epi16(7, 6, 5, 4, 3, 2, 1, 0);
    short8 B = cast(short8) A;
    foreach(i; 0..8)
        assert(B.array[i] == i);
}

__m128i _mm_set_epi32 (int e3, int e2, int e1, int e0) pure @trusted
{
    int[4] result = [e0, e1, e2, e3];
    return loadUnaligned!(int4)(result.ptr);
}
unittest
{
    __m128i A = _mm_set_epi32(3, 2, 1, 0);
    foreach(i; 0..4)
        assert(A.array[i] == i);
}

__m128i _mm_set_epi64x (long e1, long e0) pure @trusted
{
    long[2] result = [e0, e1];
    return cast(__m128i)( loadUnaligned!(long2)(result.ptr) );
}
unittest
{
    __m128i A = _mm_set_epi64x(1234, 5678);
    long2 B = cast(long2) A;
    assert(B.array[0] == 5678);
    assert(B.array[1] == 1234);
}

__m128i _mm_set_epi8 (byte e15, byte e14, byte e13, byte e12,
                      byte e11, byte e10, byte e9, byte e8,
                      byte e7, byte e6, byte e5, byte e4,
                      byte e3, byte e2, byte e1, byte e0) pure @trusted
{
    byte[16] result = [e0, e1,  e2,  e3,  e4,  e5,  e6, e7,
                     e8, e9, e10, e11, e12, e13, e14, e15];
    return cast(__m128i)( loadUnaligned!(byte16)(result.ptr) );
}

__m128d _mm_set_pd (double e1, double e0) pure @trusted
{
    double[2] result = [e0, e1];
    return loadUnaligned!(double2)(result.ptr);
}

__m128d _mm_set_pd1 (double a) pure @trusted
{
    double[2] result = [a, a];
    return loadUnaligned!(double2)(result.ptr);
}

__m128d _mm_set_sd (double a) pure @trusted
{
    double[2] result = [a, 0];
    return loadUnaligned!(double2)(result.ptr);
}

__m128i _mm_set1_epi16 (short a) pure @trusted
{
    short[8] result = [a, a, a, a, a, a, a, a];
    return cast(__m128i)( loadUnaligned!(short8)(result.ptr) );
}

__m128i _mm_set1_epi32 (int a) pure @trusted
{
    int[4] result = [a, a, a, a];
    return loadUnaligned!(int4)(result.ptr);
}
unittest
{
    __m128 a = _mm_set1_ps(-1.0f);
    __m128 b = cast(__m128) _mm_set1_epi32(0x7fffffff);
    assert(_mm_and_ps(a, b).array == [1.0f, 1, 1, 1]);
}

__m128i _mm_set1_epi64x (long a) pure @trusted
{
    long[2] result = [a, a];
    return cast(__m128i)( loadUnaligned!(long2)(result.ptr) );
}

__m128i _mm_set1_epi8 (char a) pure @trusted
{
    byte[16] result = [a, a, a, a, a, a, a, a, a, a, a, a, a, a, a, a];
    return cast(__m128i)( loadUnaligned!(byte16)(result.ptr) );
}

alias _mm_set1_pd = _mm_set_pd1;

__m128i _mm_setr_epi16 (short e7, short e6, short e5, short e4, short e3, short e2, short e1, short e0) pure @trusted
{
    short[8] result = [e7, e6, e5, e4, e3, e2, e1, e0];
    return cast(__m128i)( loadUnaligned!(short8)(result.ptr) );
}

__m128i _mm_setr_epi32 (int e3, int e2, int e1, int e0) pure @trusted
{
    int[4] result = [e3, e2, e1, e0];
    return cast(__m128i)( loadUnaligned!(int4)(result.ptr) );
}

__m128i _mm_setr_epi64 (long e1, long e0) pure @trusted
{
    long[2] result = [e1, e0];
    return cast(__m128i)( loadUnaligned!(long2)(result.ptr) );
}

__m128i _mm_setr_epi8 (char e15, char e14, char e13, char e12,
                       char e11, char e10, char e9, char e8,
                       char e7, char e6, char e5, char e4,
                       char e3, char e2, char e1, char e0) pure @trusted
{
    byte[16] result = [e15, e14, e13, e12, e11, e10, e9, e8,
                      e7,  e6,  e5,  e4,  e3,  e2, e1, e0];
    return cast(__m128i)( loadUnaligned!(byte16)(result.ptr) );
}

__m128d _mm_setr_pd (double e1, double e0) pure @trusted
{
    double[2] result = [e1, e0];
    return loadUnaligned!(double2)(result.ptr);
}

__m128d _mm_setzero_pd () pure @trusted
{
    double[2] result = [0.0, 0.0];
    return loadUnaligned!(double2)(result.ptr);
}

__m128i _mm_setzero_si128() pure @trusted
{
    int[4] result = [0, 0, 0, 0];
    return cast(__m128i)( loadUnaligned!(int4)(result.ptr) );
}

__m128i _mm_shuffle_epi32(int imm8)(__m128i a) pure @safe
{
    return shufflevector!(int4, (imm8 >> 0) & 3,
                                (imm8 >> 2) & 3,
                                (imm8 >> 4) & 3,
                                (imm8 >> 6) & 3)(a, a);
}
unittest
{
    __m128i A = _mm_setr_epi32(0, 1, 2, 3);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    int4 B = cast(int4) _mm_shuffle_epi32!SHUFFLE(A);
    int[4] expectedB = [ 3, 2, 1, 0 ];
    assert(B.array == expectedB);
}

__m128d _mm_shuffle_pd (int imm8)(__m128d a) pure @safe
{
    return shufflevector!(double2, 0 + ( imm8 & 1 ),
                                   2 + ( (imm8 >> 1) & 1 ))(a, a);
}
unittest
{
    __m128d A = _mm_setr_pd(0.5f, 2.0f);
    enum int SHUFFLE = _MM_SHUFFLE2(1, 1);
    __m128d B = _mm_shuffle_pd!SHUFFLE(A);
    double[2] expectedB = [ 2.0f, 2.0f ];
    assert(B.array == expectedB);
}

__m128i _mm_shufflehi_epi16(int imm8)(__m128i a) pure @safe
{
    return cast(__m128i) shufflevector!(short8, 0, 1, 2, 3,
                                      4 + ( (imm8 >> 0) & 3 ),
                                      4 + ( (imm8 >> 2) & 3 ),
                                      4 + ( (imm8 >> 4) & 3 ),
                                      4 + ( (imm8 >> 6) & 3 ))(cast(short8)a, cast(short8)a);
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, 4, 5, 6, 7);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    short8 C = cast(short8) _mm_shufflehi_epi16!SHUFFLE(A);
    short[8] expectedC = [ 0, 1, 2, 3, 7, 6, 5, 4 ];
    assert(C.array == expectedC);
}

__m128i _mm_shufflelo_epi16(int imm8)(__m128i a) pure @safe
{
    return cast(__m128i) shufflevector!(short8, ( (imm8 >> 0) & 3 ),
                                                ( (imm8 >> 2) & 3 ),
                                                ( (imm8 >> 4) & 3 ),
                                                ( (imm8 >> 6) & 3 ), 4, 5, 6, 7)(cast(short8)a, cast(short8)a);
}
unittest
{
    __m128i A = _mm_setr_epi16(0, 1, 2, 3, 4, 5, 6, 7);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    short8 B = cast(short8) _mm_shufflelo_epi16!SHUFFLE(A);
    short[8] expectedB = [ 3, 2, 1, 0, 4, 5, 6, 7 ];
    assert(B.array == expectedB);
}

version(LDC)
{
    alias _mm_sll_epi32 = __builtin_ia32_pslld128;
    alias _mm_sll_epi64 = __builtin_ia32_psllq128;
    alias _mm_sll_epi16 = __builtin_ia32_psllw128;
    alias _mm_slli_epi32 = __builtin_ia32_pslldi128;
    alias _mm_slli_epi64 = __builtin_ia32_psllqi128;
    alias _mm_slli_epi16 = __builtin_ia32_psllwi128;
}
// TODO

__m128i _mm_slli_si128(ubyte imm8)(__m128i op) pure @safe
{
    static if (imm8 & 0xF0)
        return _mm_setzero_si128();
    else
        return shufflevector!(byte16,
        16 - imm8, 17 - imm8, 18 - imm8, 19 - imm8, 20 - imm8, 21 - imm8, 22 - imm8, 23 - imm8,
        24 - imm8, 25 - imm8, 26 - imm8, 27 - imm8, 28 - imm8, 29 - imm8, 30 - imm8, 31 - imm8)
        (_mm_setzero_si128(), op);
}

version(LDC)
{
    // Disappeared with LDC 1.11
    static if (__VERSION__ < 2081)
        alias _mm_sqrt_pd = __builtin_ia32_sqrtpd;
    else
    {
        __m128d _mm_sqrt_pd(__m128d vec) pure @safe
        {
            vec.array[0] = llvm_sqrt(vec.array[0]);
            vec.array[1] = llvm_sqrt(vec.array[1]);
            return vec;
        }
    }
}
else
{
    __m128d _mm_sqrt_pd(__m128d vec) pure @safe
    {
        import std.math: sqrt;
        vec.array[0] = sqrt(vec.array[0]);
        vec.array[1] = sqrt(vec.array[1]);
        return vec;
    }
}


version(LDC)
{
    // Disappeared with LDC 1.11
    static if (__VERSION__ < 2081)
        alias _mm_sqrt_sd = __builtin_ia32_sqrtsd;
    else
    {
        __m128d _mm_sqrt_sd(__m128d vec) pure @safe
        {
            vec.array[0] = llvm_sqrt(vec.array[0]);
            vec.array[1] = vec.array[1];
            return vec;
        }
    }
}
else
{
    __m128d _mm_sqrt_sd(__m128d vec) pure @safe
    {
        import std.math: sqrt;
        vec.array[0] = sqrt(vec.array[0]);
        vec.array[1] = vec.array[1];
        return vec;
    }
}


version(LDC)
{
    alias _mm_sra_epi16  = __builtin_ia32_psraw128;
    alias _mm_sra_epi32  = __builtin_ia32_psrad128;
    alias _mm_srai_epi16 = __builtin_ia32_psrawi128;
    alias _mm_srai_epi32 = __builtin_ia32_psradi128;

    alias _mm_srl_epi16  = __builtin_ia32_psrlw128;
    alias _mm_srl_epi32  = __builtin_ia32_psrld128;
    alias _mm_srl_epi64  = __builtin_ia32_psrlq128;
    alias _mm_srli_epi16 = __builtin_ia32_psrlwi128;
    alias _mm_srli_epi32 = __builtin_ia32_psrldi128;
    alias _mm_srli_epi64 = __builtin_ia32_psrlqi128;
}
// TODO

__m128i _mm_srli_si128(ubyte imm8)(__m128i op) pure @safe
{
    static if (imm8 & 0xF0)
        return _mm_setzero_si128();
    else
        return cast(__m128i) shufflevector!(byte16,
                                            imm8+0, imm8+1, imm8+2, imm8+3, imm8+4, imm8+5, imm8+6, imm8+7,
                                            imm8+8, imm8+9, imm8+10, imm8+11, imm8+12, imm8+13, imm8+14, imm8+15)
                                           (cast(byte16) op, cast(byte16)_mm_setzero_si128());
}

// Note: this is a bonus intrinsic
__m128 _mm_srli_si128(ubyte imm8)(__m128 op) @safe
{
    return cast(__m128)_mm_srli_si128!imm8(cast(__m128i)op);
}
unittest
{
    // test that cast works at all
    __m128 A = cast(__m128) _mm_set1_epi32(0x3F800000);
    assert(A.array == [1.0f, 1.0f, 1.0f, 1.0f]);

    // test _mm_srli_si128 for __m128i
    assert(_mm_srli_si128!4(_mm_set_epi32(4, 3, 2, 1)).array == [2, 3, 4, 0]);
    assert(_mm_srli_si128!8(_mm_set_ps(4.0f, 3.0f, 2.0f, 1.0f)).array == [3.0f, 4.0f, 0, 0]);
}

__m128d _mm_srli_si128(ubyte imm8)(__m128d op) pure @safe
{
    return cast(__m128d) _mm_srli_si128!imm8(cast(__m128i)op);
}

void _mm_store_pd (double* mem_addr, __m128d a) pure
{
    __m128d* aligned = cast(__m128d*)mem_addr;
    *aligned = a;
}

void _mm_store_pd1 (double* mem_addr, __m128d a) pure
{
    __m128d* aligned = cast(__m128d*)mem_addr;
    *aligned = shufflevector!(double2, 0, 0)(a, a);
}

void _mm_store_sd (double* mem_addr, __m128d a) pure @safe
{
    *mem_addr = extractelement!(double2, 0)(a);
}

void _mm_store_si128 (__m128i* mem_addr, __m128i a) pure @safe
{
    *mem_addr = a;
}

alias _mm_store1_pd = _mm_store_pd1;

void _mm_storeh_pd (double* mem_addr, __m128d a) pure @safe
{
    *mem_addr = extractelement!(double2, 1)(a);
}

void _mm_storel_epi64 (__m128i* mem_addr, __m128i a) pure @safe
{
    long* dest = cast(long*)mem_addr;
    *dest = extractelement!(long2, 0)(cast(long2)a);
}

void _mm_storel_pd (double* mem_addr, __m128d a) pure @safe
{
    *mem_addr = extractelement!(double2, 0)(a);
}

void _mm_storer_pd (double* mem_addr, __m128d a) pure
{
    __m128d* aligned = cast(__m128d*)mem_addr;
    *aligned = shufflevector!(double2, 1, 0)(a, a);
}

void _mm_storeu_pd (double* mem_addr, __m128d a) pure @safe
{
    storeUnaligned!double2(a, mem_addr);
}

void _mm_storeu_si128 (__m128i* mem_addr, __m128i a) pure @safe
{
    storeUnaligned!__m128i(a, cast(int*)mem_addr);
}

// TODO: _mm_stream_pd
// TODO: _mm_stream_si128
// TODO: _mm_stream_si32
// TODO: _mm_stream_si64

__m128i _mm_sub_epi16(__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(short8)a - cast(short8)b);
}

__m128i _mm_sub_epi32(__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(int4)a - cast(int4)b);
}

__m128i _mm_sub_epi64(__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(long2)a - cast(long2)b);
}

__m128i _mm_sub_epi8(__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)(cast(byte16)a - cast(byte16)b);
}

__m128d _mm_sub_pd(__m128d a, __m128d b) pure @safe
{
    return a - b;
}

__m128d _mm_sub_sd(__m128d a, __m128d b) pure @safe
{
    a[0] -= b[0];
    return a;
}
unittest
{
    __m128d a = [1.5, -2.0];
    a = _mm_sub_sd(a, a);
    assert(a.array == [0.0, -2.0]);
}


// MMXREG: _mm_sub_si64

version(LDC)
{
    alias _mm_subs_epi16 = __builtin_ia32_psubsw128;
    alias _mm_subs_epi8 = __builtin_ia32_psubsb128;
    alias _mm_subs_epu16 = __builtin_ia32_psubusw128;
    alias _mm_subs_epu8 = __builtin_ia32_psubusb128;

    alias _mm_ucomieq_sd = __builtin_ia32_ucomisdeq;
    alias _mm_ucomige_sd = __builtin_ia32_ucomisdge;
    alias _mm_ucomigt_sd = __builtin_ia32_ucomisdgt;
    alias _mm_ucomile_sd = __builtin_ia32_ucomisdle;
    alias _mm_ucomilt_sd = __builtin_ia32_ucomisdlt;
    alias _mm_ucomineq_sd = __builtin_ia32_ucomisdneq;
}
// TODO

__m128d _mm_undefined_pd() pure @safe
{
    __m128d result = void;
    return result;
}
__m128i _mm_undefined_si128() pure @safe
{
    __m128i result = void;
    return result;
}

__m128i _mm_unpackhi_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) shufflevector!(short8, 4, 12, 5, 13, 6, 14, 7, 15)
                                       (cast(short8)a, cast(short8)b);
}

__m128i _mm_unpackhi_epi32 (__m128i a, __m128i b) pure @safe
{
    return shufflevector!(int4, 2, 6, 3, 7)(cast(int4)a, cast(int4)b);
}

__m128i _mm_unpackhi_epi64 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) shufflevector!(long2, 1, 3)(cast(long2)a, cast(long2)b);
}

__m128i _mm_unpackhi_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)shufflevector!(byte16, 8,  24,  9, 25, 10, 26, 11, 27,
                                               12, 28, 13, 29, 14, 30, 15, 31)
                                               (cast(byte16)a, cast(byte16)b);
}

__m128d _mm_unpackhi_pd (__m128d a, __m128d b) pure @safe
{
    return shufflevector!(__m128d, 1, 3)(a, b);
}

__m128i _mm_unpacklo_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) shufflevector!(short8, 0, 8, 1, 9, 2, 10, 3, 11)
                                       (cast(short8)a, cast(short8)b);
}

__m128i _mm_unpacklo_epi32 (__m128i a, __m128i b) pure @safe
{
    return shufflevector!(int4, 0, 4, 1, 6)
                         (cast(int4)a, cast(int4)b);
}

__m128i _mm_unpacklo_epi64 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) shufflevector!(long2, 0, 2)
                                       (cast(long2)a, cast(long2)b);
}

__m128i _mm_unpacklo_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i) shufflevector!(byte16, 0, 16, 1, 17, 2, 18, 3, 19,
                                                4, 20, 5, 21, 6, 22, 7, 23)
                                       (cast(byte16)a, cast(byte16)b);
}

__m128d _mm_unpacklo_pd (__m128d a, __m128d b) pure @safe
{
    return shufflevector!(__m128d, 0, 2)(a, b);
}

__m128d _mm_xor_pd (__m128d a, __m128d b) pure @safe
{
    return cast(__m128d)(cast(__m128i)a ^ cast(__m128i)b);
}

__m128i _mm_xor_si128 (__m128i a, __m128i b) pure @safe
{
    return a ^ b;
}

unittest
{
    // distance between two points in 4D
    float distance(float[4] a, float[4] b) nothrow @nogc
    {
        __m128 va = _mm_loadu_ps(a.ptr);
        __m128 vb = _mm_loadu_ps(b.ptr);
        __m128 diffSquared = _mm_sub_ps(va, vb);
        diffSquared = _mm_mul_ps(diffSquared, diffSquared);
        __m128 sum = _mm_add_ps(diffSquared, _mm_srli_si128!8(diffSquared));
        sum = _mm_add_ps(sum, _mm_srli_si128!4(sum));
        return _mm_cvtss_f32(_mm_sqrt_ss(sum));
    }
    assert(distance([0, 2, 0, 0], [0, 0, 0, 0]) == 2);
}