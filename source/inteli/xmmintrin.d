/**
* Copyright: Copyright Auburn Sounds 2016-2019.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.xmmintrin;

public import inteli.types;

import inteli.internals;

import inteli.mmx;
import inteli.emmintrin;

import core.stdc.stdlib: malloc, free;
import core.exception: onOutOfMemoryError;

version(D_InlineAsm_X86)
    version = InlineX86Asm;
else version(D_InlineAsm_X86_64)
    version = InlineX86Asm;


// SSE1

nothrow @nogc:


enum int _MM_EXCEPT_INVALID    = 0x0001;
enum int _MM_EXCEPT_DENORM     = 0x0002;
enum int _MM_EXCEPT_DIV_ZERO   = 0x0004;
enum int _MM_EXCEPT_OVERFLOW   = 0x0008;
enum int _MM_EXCEPT_UNDERFLOW  = 0x0010;
enum int _MM_EXCEPT_INEXACT    = 0x0020;
enum int _MM_EXCEPT_MASK       = 0x003f;

enum int _MM_MASK_INVALID      = 0x0080;
enum int _MM_MASK_DENORM       = 0x0100;
enum int _MM_MASK_DIV_ZERO     = 0x0200;
enum int _MM_MASK_OVERFLOW     = 0x0400;
enum int _MM_MASK_UNDERFLOW    = 0x0800;
enum int _MM_MASK_INEXACT      = 0x1000;
enum int _MM_MASK_MASK         = 0x1f80;

enum int _MM_ROUND_NEAREST     = 0x0000;
enum int _MM_ROUND_DOWN        = 0x2000;
enum int _MM_ROUND_UP          = 0x4000;
enum int _MM_ROUND_TOWARD_ZERO = 0x6000;
enum int _MM_ROUND_MASK        = 0x6000;

enum int _MM_FLUSH_ZERO_MASK   = 0x8000;
enum int _MM_FLUSH_ZERO_ON     = 0x8000;
enum int _MM_FLUSH_ZERO_OFF    = 0x0000;

__m128 _mm_add_ps(__m128 a, __m128 b) pure @safe
{
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

__m128 _mm_add_ss(__m128 a, __m128 b) pure @safe
{
    static if (GDC_X86)
        return __builtin_ia32_addss(a, b);
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

__m128 _mm_and_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128)(cast(__m128i)a & cast(__m128i)b);
}
unittest
{
    // Note: tested in emmintrin.d
}

__m128 _mm_andnot_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128)( (~cast(__m128i)a) & cast(__m128i)b );
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

__m128 _mm_cmpeq_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.oeq)(a, b);
}

__m128 _mm_cmpeq_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.oeq)(a, b);
}

__m128 _mm_cmpge_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.oge)(a, b);
}
unittest
{
    __m128i R = cast(__m128i) _mm_cmpge_ps(_mm_setr_ps(0, 1, -1, float.nan),
                                           _mm_setr_ps(0, 0, 0, 0));
    int[4] correct = [-1, -1, 0, 0];
    assert(R.array == correct);
}

__m128 _mm_cmpge_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.oge)(a, b);
}

__m128 _mm_cmpgt_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.ogt)(a, b);
}

__m128 _mm_cmpgt_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.ogt)(a, b);
}

__m128 _mm_cmple_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.ole)(a, b);
}

__m128 _mm_cmple_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.ole)(a, b);
}

__m128 _mm_cmplt_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.olt)(a, b);
}

__m128 _mm_cmplt_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.olt)(a, b);
}

__m128 _mm_cmpneq_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.une)(a, b);
}

__m128 _mm_cmpneq_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.une)(a, b);
}

__m128 _mm_cmpnge_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.ult)(a, b);
}

__m128 _mm_cmpnge_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.ult)(a, b);
}

__m128 _mm_cmpngt_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.ule)(a, b);
}

__m128 _mm_cmpngt_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.ule)(a, b);
}

__m128 _mm_cmpnle_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.ugt)(a, b);
}

__m128 _mm_cmpnle_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.ugt)(a, b);
}

__m128 _mm_cmpnlt_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.uge)(a, b);
}

__m128 _mm_cmpnlt_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.uge)(a, b);
}

__m128 _mm_cmpord_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.ord)(a, b);
}

__m128 _mm_cmpord_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.ord)(a, b);
}

__m128 _mm_cmpunord_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpps!(FPComparison.uno)(a, b);
}

__m128 _mm_cmpunord_ss (__m128 a, __m128 b) pure @safe
{
    return cast(__m128) cmpss!(FPComparison.uno)(a, b);
}

// Note: we've reverted clang and GCC behaviour with regards to EFLAGS
// Some such comparisons yields true for NaNs, other don't.

int _mm_comieq_ss (__m128 a, __m128 b) pure @safe // comiss + sete
{
    return comss!(FPComparison.ueq)(a, b); // yields true for NaN!
}

int _mm_comige_ss (__m128 a, __m128 b) pure @safe // comiss + setae
{
    return comss!(FPComparison.oge)(a, b);
}

int _mm_comigt_ss (__m128 a, __m128 b) pure @safe // comiss + seta
{
    return comss!(FPComparison.ogt)(a, b);
}

int _mm_comile_ss (__m128 a, __m128 b) pure @safe // comiss + setbe
{
    return comss!(FPComparison.ule)(a, b); // yields true for NaN!
}

int _mm_comilt_ss (__m128 a, __m128 b) pure @safe // comiss + setb
{
    return comss!(FPComparison.ult)(a, b); // yields true for NaN!
}

int _mm_comineq_ss (__m128 a, __m128 b) pure @safe // comiss + setne
{
    return comss!(FPComparison.one)(a, b);
}

alias _mm_cvt_pi2ps = _mm_cvtpi32_ps;

__m64 _mm_cvt_ps2pi (__m128 a) pure @safe
{
    return to_m64(_mm_cvtps_epi32(a));
}

__m128 _mm_cvt_si2ss(__m128 v, int x) pure @trusted
{
    v.ptr[0] = cast(float)x;
    return v;
}
unittest
{
    __m128 a = _mm_cvt_si2ss(_mm_set1_ps(0.0f), 42);
    assert(a.array == [42f, 0, 0, 0]);
}

// Note: is just another name for _mm_cvtss_si32
alias _mm_cvt_ss2si = _mm_cvtss_si32;


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


__m128 _mm_cvtpi32x2_ps (__m64 a, __m64 b) pure @trusted
{
    long2 l;
    l.ptr[0] = a.array[0];
    l.ptr[1] = b.array[0];
    return _mm_cvtepi32_ps(cast(__m128i)l);
}

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

__m64 _mm_cvtps_pi16 (__m128 a) pure @safe
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

__m64 _mm_cvtps_pi32 (__m128 a) pure @safe
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

__m64 _mm_cvtps_pi8 (__m128 a) pure @safe
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

// Note: on macOS, using "llvm.x86.sse.cvtsi642ss" was buggy
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

float _mm_cvtss_f32(__m128 a) pure @safe
{
    return a.array[0];
}

version(LDC)
{
    alias _mm_cvtss_si32 = __builtin_ia32_cvtss2si;
}
else
{
    int _mm_cvtss_si32 (__m128 a) pure @safe
    {
        return convertFloatToInt32UsingMXCSR(a.array[0]);
    }
}
unittest
{
    assert(1 == _mm_cvtss_si32(_mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f)));
}

version(LDC)
{
    version(X86_64)
        alias _mm_cvtss_si64 = __builtin_ia32_cvtss2si64;
    else
    {
        // Note: __builtin_ia32_cvtss2si64 crashes LDC in 32-bit
        long _mm_cvtss_si64 (__m128 a) pure @safe
        {
            return convertFloatToInt64UsingMXCSR(a.array[0]);
        }
    }
}
else
{
    long _mm_cvtss_si64 (__m128 a) pure @safe
    {
        return convertFloatToInt64UsingMXCSR(a.array[0]);
    }
}
unittest
{
    assert(1 == _mm_cvtss_si64(_mm_setr_ps(1.0f, 2.0f, 3.0f, 4.0f)));

    uint savedRounding = _MM_GET_ROUNDING_MODE();

    _MM_SET_ROUNDING_MODE(_MM_ROUND_NEAREST);
    assert(-86186 == _mm_cvtss_si64(_mm_set1_ps(-86186.5f)));

    _MM_SET_ROUNDING_MODE(_MM_ROUND_DOWN);
    assert(-86187 == _mm_cvtss_si64(_mm_set1_ps(-86186.1f)));

    _MM_SET_ROUNDING_MODE(_MM_ROUND_UP);
    assert(86187 == _mm_cvtss_si64(_mm_set1_ps(86186.1f)));

    _MM_SET_ROUNDING_MODE(_MM_ROUND_TOWARD_ZERO);
    assert(-86186 == _mm_cvtss_si64(_mm_set1_ps(-86186.9f)));

    _MM_SET_ROUNDING_MODE(savedRounding);
}


version(LDC)
{
    alias _mm_cvtt_ss2si = __builtin_ia32_cvttss2si;
}
else
{
    int _mm_cvtt_ss2si (__m128 a) pure @safe
    {
        return cast(int)(a.array[0]);
    }
}
unittest
{
    assert(1 == _mm_cvtt_ss2si(_mm_setr_ps(1.9f, 2.0f, 3.0f, 4.0f)));
}

__m64 _mm_cvtt_ps2pi (__m128 a) pure @safe
{
    return to_m64(_mm_cvttps_epi32(a));
}

alias _mm_cvttss_si32 = _mm_cvtt_ss2si; // it's actually the same op

// Note: __builtin_ia32_cvttss2si64 crashes LDC when generating 32-bit x86 code.
long _mm_cvttss_si64 (__m128 a) pure @safe
{
    return cast(long)(a.array[0]); // Generates cvttss2si as expected
}
unittest
{
    assert(1 == _mm_cvttss_si64(_mm_setr_ps(1.9f, 2.0f, 3.0f, 4.0f)));
}

__m128 _mm_div_ps(__m128 a, __m128 b) pure @safe
{
    return a / b;
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_div_ps(a, a);
    float[4] correct = [1.0f, 1.0f, 1.0f, 1.0f];
    assert(a.array == correct);
}

__m128 _mm_div_ss(__m128 a, __m128 b) pure @safe
{
    static if (GDC_X86)
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

/// Free aligned memory that was allocated with `_mm_malloc`.
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

uint _MM_GET_EXCEPTION_MASK() pure @safe
{
    return _mm_getcsr() & _MM_MASK_MASK;
}

uint _MM_GET_EXCEPTION_STATE() pure @safe
{
    return _mm_getcsr() & _MM_EXCEPT_MASK;
}

uint _MM_GET_FLUSH_ZERO_MODE() pure @safe
{
    return _mm_getcsr() & _MM_FLUSH_ZERO_MASK;
}

uint _MM_GET_ROUNDING_MODE() pure @safe
{
    return _mm_getcsr() & _MM_ROUND_MASK;
}

uint _mm_getcsr() pure @safe
{
    static if (GDC_X86)
    {
        return __builtin_ia32_stmxcsr();
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

__m64 _mm_insert_pi16 (__m64 v, int i, int index) pure @trusted
{
    short4 r = cast(short4)v;
    r.ptr[index & 3] = cast(short)i;
    return cast(__m64)r;
}
unittest
{
    __m64 A = _mm_set_pi16(3, 2, 1, 0);
    short4 R = cast(short4) _mm_insert_pi16(A, 42, 1 | 4);
    short[4] correct = [0, 42, 2, 3];
    assert(R.array == correct);
}

__m128 _mm_load_ps(const(float)*p) pure @trusted
{
    return *cast(__m128*)p;
}

__m128 _mm_load_ps1(const(float)*p) pure @trusted
{
    return __m128(*p);
}

__m128 _mm_load_ss (const(float)* mem_addr) pure @trusted
{
    float[4] f = [ *mem_addr, 0.0f, 0.0f, 0.0f ];
    return loadUnaligned!(float4)(f.ptr);
}

alias _mm_load1_ps = _mm_load_ps1;

__m128 _mm_loadh_pi (__m128 a, const(__m64)* mem_addr) pure @trusted
{
    long2 la = cast(long2)a;
    la.ptr[1] = (*mem_addr).array[0];
    return cast(__m128)la;
}

__m128 _mm_loadl_pi (__m128 a, const(__m64)* mem_addr) pure @trusted
{
    long2 la = cast(long2)a;
    la.ptr[0] = (*mem_addr).array[0];
    return cast(__m128)la;
}

__m128 _mm_loadr_ps (const(float)* mem_addr) pure @trusted
{
    __m128* aligned = cast(__m128*)mem_addr;
    __m128 a = *aligned;
    return shufflevector!(__m128, 3, 2, 1, 0)(a, a);
}

__m128 _mm_loadu_ps(const(float)*p) pure @safe
{
    return loadUnaligned!(__m128)(p);
}

__m128i _mm_loadu_si16(const(void)* mem_addr) pure @trusted
{
    short r = *cast(short*)(mem_addr);
    short8 result = [0, 0, 0, 0, 0, 0, 0, 0];
    result.ptr[0] = r;
    return cast(__m128i)result;
}
unittest
{
    short r = 13;
    short8 A = cast(short8) _mm_loadu_si16(&r);
    short[8] correct = [13, 0, 0, 0, 0, 0, 0, 0];
    assert(A.array == correct);
}

__m128i _mm_loadu_si64(const(void)* mem_addr) pure @trusted
{
    long r = *cast(long*)(mem_addr);
    long2 result = [0, 0];
    result.ptr[0] = r;
    return cast(__m128i)result;
}
unittest
{
    long r = 446446446446;
    long2 A = cast(long2) _mm_loadu_si64(&r);
    long[2] correct = [446446446446, 0];
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

void _mm_maskmove_si64 (__m64 a, __m64 mask, char* mem_addr) @trusted
{
    // this works since mask is zero-extended
    return _mm_maskmoveu_si128 (to_m128i(a), to_m128i(mask), mem_addr);
}

deprecated alias _m_maskmovq = _mm_maskmove_si64;

__m64 _mm_max_pi16 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_max_epi16(to_m128i(a), to_m128i(b)));
}

static if (GDC_X86)
{
    alias _mm_max_ps = __builtin_ia32_maxps;
}
else version(LDC)
{
    alias _mm_max_ps = __builtin_ia32_maxps;
}
else
{
    __m128 _mm_max_ps(__m128 a, __m128 b) pure @safe
    {
        __m128 r;
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

__m64 _mm_max_pu8 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_max_epu8(to_m128i(a), to_m128i(b)));
}

static if (GDC_X86)
{
    alias _mm_max_ss = __builtin_ia32_maxss;
}
else version(LDC)
{
    alias _mm_max_ss = __builtin_ia32_maxss;
}
else
{
    __m128 _mm_max_ss(__m128 a, __m128 b) pure @safe
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

__m64 _mm_min_pi16 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_min_epi16(to_m128i(a), to_m128i(b)));
}

static if (GDC_X86)
{
    alias _mm_min_ps = __builtin_ia32_minps;
}
else version(LDC)
{
    alias _mm_min_ps = __builtin_ia32_minps;
}
else
{
    __m128 _mm_min_ps(__m128 a, __m128 b) pure @safe
    {
        __m128 r;
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

__m64 _mm_min_pu8 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_min_epu8(to_m128i(a), to_m128i(b)));
}

static if (GDC_X86)
{
    alias _mm_min_ss = __builtin_ia32_minss;
}
else version(LDC)
{
    alias _mm_min_ss = __builtin_ia32_minss;
}
else
{
    __m128 _mm_min_ss(__m128 a, __m128 b) pure @safe
    {
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

__m128 _mm_move_ss (__m128 a, __m128 b) pure @safe
{
    return shufflevector!(__m128, 4, 1, 2, 3)(a, b);
}

__m128 _mm_movehl_ps (__m128 a, __m128 b) pure @safe
{
    return shufflevector!(float4, 2, 3, 6, 7)(a, b);
}

__m128 _mm_movelh_ps (__m128 a, __m128 b) pure @safe
{
    return shufflevector!(float4, 0, 1, 4, 5)(a, b);
}

int _mm_movemask_pi8 (__m64 a) pure @safe
{
    return _mm_movemask_epi8(to_m128i(a));
}
unittest
{
    assert(0x9C == _mm_movemask_pi8(_mm_set_pi8(-1, 0, 0, -1, -1, -1, 0, 0)));
}

static if (GDC_X86)
{
    alias _mm_movemask_ps = __builtin_ia32_movmskps;
}
else version(LDC)
{
    alias _mm_movemask_ps = __builtin_ia32_movmskps;
}
else
{
    int _mm_movemask_ps (__m128 a) pure @safe
    {
        int4 ai = cast(int4)a;
        int r = 0;
        if (ai[0] < 0) r += 1;
        if (ai[1] < 0) r += 2;
        if (ai[2] < 0) r += 4;
        if (ai[3] < 0) r += 8;
        return r;
    }
}
unittest
{
    int4 A = [-1, 0, -43, 0];
    assert(5 == _mm_movemask_ps(cast(float4)A));
}

__m128 _mm_mul_ps(__m128 a, __m128 b) pure @safe
{
    return a * b;
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_mul_ps(a, a);
    float[4] correct = [2.25f, 4.0f, 9.0f, 1.0f];
    assert(a.array == correct);
}

__m128 _mm_mul_ss(__m128 a, __m128 b) pure @safe
{
    static if (GDC_X86)
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

__m128 _mm_or_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128)(cast(__m128i)a | cast(__m128i)b);
}

deprecated alias 
    _m_pavgb = _mm_avg_pu8,
    _m_pavgw = _mm_avg_pu16,
    _m_pextrw = _mm_extract_pi16,
    _m_pinsrw = _mm_insert_pi16,
    _m_pmaxsw = _mm_max_pi16,
    _m_pmaxub = _mm_max_pu8,
    _m_pminsw = _mm_min_pi16,
    _m_pminub = _mm_min_pu8,
    _m_pmovmskb = _mm_movemask_pi8,
    _m_pmulhuw = _mm_mulhi_pu16;

enum _MM_HINT_NTA = 0;
enum _MM_HINT_T0 = 1;
enum _MM_HINT_T1 = 2;
enum _MM_HINT_T2 = 3;

// Note: locality must be compile-time, unlike Intel Intrinsics API
void _mm_prefetch(int locality)(void* p) pure @safe
{
    llvm_prefetch(p, 0, locality, 1);
}

deprecated alias
    _m_psadbw = _mm_sad_pu8,
    _m_pshufw = _mm_shuffle_pi16;

static if (GDC_X86)
{
    alias _mm_rcp_ps = __builtin_ia32_rcpps;
}
else version(LDC)
{
    alias _mm_rcp_ps = __builtin_ia32_rcpps;
}
else
{
    __m128 _mm_rcp_ps (__m128 a) pure @safe
    {
        a[0] = 1.0f / a[0];
        a[1] = 1.0f / a[1];
        a[2] = 1.0f / a[2];
        a[3] = 1.0f / a[3];
        return a;
    }
}

static if (GDC_X86)
{
    alias _mm_rcp_ss = __builtin_ia32_rcpss;
}
else version(LDC)
{
    alias _mm_rcp_ss = __builtin_ia32_rcpss;
}
else
{
    __m128 _mm_rcp_ss (__m128 a) pure @safe
    {
        a[0] = 1.0f / a[0];
        return a;
    }
}

static if (GDC_X86)
{
    alias _mm_rsqrt_ps = __builtin_ia32_rsqrtps;
}
else version(LDC)
{
    alias _mm_rsqrt_ps = __builtin_ia32_rsqrtps;
}
else
{
    __m128 _mm_rsqrt_ps (__m128 a) pure @safe
    {
        a[0] = 1.0f / sqrt(a[0]);
        a[1] = 1.0f / sqrt(a[1]);
        a[2] = 1.0f / sqrt(a[2]);
        a[3] = 1.0f / sqrt(a[3]);
        return a;
    }
}

static if (GDC_X86)
{
    alias _mm_rsqrt_ss = __builtin_ia32_rsqrtss;
}
else version(LDC)
{
    alias _mm_rsqrt_ss = __builtin_ia32_rsqrtss;
}
else
{
    __m128 _mm_rsqrt_ss (__m128 a) pure @safe
    {
        a[0] = 1.0f / sqrt(a[0]);
        return a;
    }
}

unittest
{
    double maxRelativeError = 0.000245; // -72 dB
    void testInvSqrt(float number) nothrow @nogc
    {
        __m128 A = _mm_set1_ps(number);

        // test _mm_rcp_ps
        __m128 B = _mm_rcp_ps(A);
        foreach(i; 0..4)
        {
            double exact = 1.0f / A.array[i];
            double ratio = cast(double)(B.array[i]) / cast(double)(exact);
            assert(abs(ratio - 1) <= maxRelativeError);
        }

        // test _mm_rcp_ss
        {
            B = _mm_rcp_ss(A);
            double exact = 1.0f / A.array[0];
            double ratio = cast(double)(B.array[0]) / cast(double)(exact);
            assert(abs(ratio - 1) <= maxRelativeError);
        }

        // test _mm_rsqrt_ps
        B = _mm_rsqrt_ps(A);
        foreach(i; 0..4)
        {
            double exact = 1.0f / sqrt(A.array[i]);
            double ratio = cast(double)(B.array[i]) / cast(double)(exact);
            assert(abs(ratio - 1) <= maxRelativeError);
        }

        // test _mm_rsqrt_ss
        {
            B = _mm_rsqrt_ss(A);
            double exact = 1.0f / sqrt(A.array[0]);
            double ratio = cast(double)(B.array[0]) / cast(double)(exact);
            assert(abs(ratio - 1) <= maxRelativeError);
        }
    }

    testInvSqrt(1.1f);
    testInvSqrt(2.45674864151f);
    testInvSqrt(27841456468.0f);
}

__m64 _mm_sad_pu8 (__m64 a, __m64 b) pure @safe
{
    return to_m64(_mm_sad_epu8(to_m128i(a), to_m128i(b)));
}

void _MM_SET_EXCEPTION_MASK(int _MM_MASK_xxxx) pure @safe
{
    _mm_setcsr((_mm_getcsr() & ~_MM_MASK_MASK) | _MM_MASK_xxxx);
}

void _MM_SET_EXCEPTION_STATE(int _MM_EXCEPT_xxxx) pure @safe
{
    _mm_setcsr((_mm_getcsr() & ~_MM_EXCEPT_MASK) | _MM_EXCEPT_xxxx);
}

void _MM_SET_FLUSH_ZERO_MODE(int _MM_FLUSH_xxxx) pure @safe
{
    _mm_setcsr((_mm_getcsr() & ~_MM_FLUSH_ZERO_MASK) | _MM_FLUSH_xxxx);
}

__m128 _mm_set_ps (float e3, float e2, float e1, float e0) pure @trusted
{
    // Note: despite appearances, generates sensible code,
    //       inlines correctly and is constant folded
    float[4] result = [e0, e1, e2, e3];
    return loadUnaligned!(float4)(result.ptr);
}
unittest
{
    __m128 A = _mm_set_ps(3, 2, 1, 546);
    float[4] correct = [546.0f, 1.0f, 2.0f, 3.0f];
    assert(A.array == correct);
    assert(A.array[0] == 546.0f);
    assert(A.array[1] == 1.0f);
    assert(A.array[2] == 2.0f);
    assert(A.array[3] == 3.0f);
}

alias _mm_set_ps1 = _mm_set1_ps;

void _MM_SET_ROUNDING_MODE(int _MM_ROUND_xxxx) pure @safe
{
    _mm_setcsr((_mm_getcsr() & ~_MM_ROUND_MASK) | _MM_ROUND_xxxx);
}

__m128 _mm_set_ss (float a) pure @trusted
{
    __m128 r = _mm_setzero_ps();
    r.ptr[0] = a;
    return r;
}
unittest
{
    float[4] correct = [42.0f, 0.0f, 0.0f, 0.0f];
    __m128 A = _mm_set_ss(42.0f);
    assert(A.array == correct);
}

__m128 _mm_set1_ps (float a) pure @trusted
{
    return __m128(a);
}
unittest
{
    float[4] correct = [42.0f, 42.0f, 42.0f, 42.0f];
    __m128 A = _mm_set1_ps(42.0f);
    assert(A.array == correct);
}


void _mm_setcsr(uint controlWord) pure @safe
{
    static if (GDC_X86)
        __builtin_ia32_ldmxcsr(controlWord);
    else version (InlineX86Asm)
    {
        asm pure nothrow @nogc @safe
        {
            ldmxcsr controlWord;
        }
    }
    else
        static assert(0, "Not yet supported");
}

__m128 _mm_setr_ps (float e3, float e2, float e1, float e0) pure @trusted
{
    float[4] result = [e3, e2, e1, e0];
    return loadUnaligned!(float4)(result.ptr);
}
unittest
{
    __m128 A = _mm_setr_ps(3, 2, 1, 546);
    float[4] correct = [3.0f, 2.0f, 1.0f, 546.0f];
    assert(A.array == correct);
    assert(A.array[0] == 3.0f);
    assert(A.array[1] == 2.0f);
    assert(A.array[2] == 1.0f);
    assert(A.array[3] == 546.0f);
}

__m128 _mm_setzero_ps() pure @trusted
{
    // Compiles to xorps without problems
    float[4] result = [0.0f, 0.0f, 0.0f, 0.0f];
    return loadUnaligned!(float4)(result.ptr);
}

static if (GDC_X86)
{
    alias _mm_sfence = __builtin_ia32_sfence;
}
else version(LDC)
{
    alias _mm_sfence = __builtin_ia32_sfence;
}
else
{
    void _mm_sfence() pure @safe
    {
        asm nothrow @nogc pure @safe
        {
            sfence;
        }
    }
}
unittest
{
    _mm_sfence();
}

__m64 _mm_shuffle_pi16(int imm8)(__m64 a) pure @safe
{
    return cast(__m64) shufflevector!(short4, ( (imm8 >> 0) & 3 ),
                                              ( (imm8 >> 2) & 3 ),
                                              ( (imm8 >> 4) & 3 ),
                                              ( (imm8 >> 6) & 3 ))(cast(short4)a, cast(short4)a);
}
unittest
{
    __m64 A = _mm_setr_pi16(0, 1, 2, 3);
    enum int SHUFFLE = _MM_SHUFFLE(0, 1, 2, 3);
    short4 B = cast(short4) _mm_shuffle_pi16!SHUFFLE(A);
    short[4] expectedB = [ 3, 2, 1, 0 ];
    assert(B.array == expectedB);
}

// Note: the immediate shuffle value is given at compile-time instead of runtime.
__m128 _mm_shuffle_ps(ubyte imm)(__m128 a, __m128 b) pure @safe
{
    return shufflevector!(__m128, imm & 3, (imm>>2) & 3, 4 + ((imm>>4) & 3), 4 + ((imm>>6) & 3) )(a, b);
}

static if (GDC_X86)
{
    alias _mm_sqrt_ps = __builtin_ia32_sqrtps;
}
else version(LDC)
{
    // Disappeared with LDC 1.11
    static if (__VERSION__ < 2081)
        alias _mm_sqrt_ps = __builtin_ia32_sqrtps;
    else
    {
        __m128 _mm_sqrt_ps(__m128 vec) pure @safe
        {
            vec.array[0] = llvm_sqrt(vec.array[0]);
            vec.array[1] = llvm_sqrt(vec.array[1]);
            vec.array[2] = llvm_sqrt(vec.array[2]);
            vec.array[3] = llvm_sqrt(vec.array[3]);
            return vec;
        }
    }
}
else
{
    __m128 _mm_sqrt_ps(__m128 vec) pure @trusted
    {
        vec.ptr[0] = sqrt(vec.array[0]);
        vec.ptr[1] = sqrt(vec.array[1]);
        vec.ptr[2] = sqrt(vec.array[2]);
        vec.ptr[3] = sqrt(vec.array[3]);
        return vec;
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

static if (GDC_X86)
{
    alias _mm_sqrt_ss = __builtin_ia32_sqrtss;
}
else version(LDC)
{
    // Disappeared with LDC 1.11
    static if (__VERSION__ < 2081)
        alias _mm_sqrt_ss = __builtin_ia32_sqrtss;
    else
    {
        __m128 _mm_sqrt_ss(__m128 vec) pure @safe
        {
            vec.array[0] = llvm_sqrt(vec.array[0]);
            vec.array[1] = vec.array[1];
            vec.array[2] = vec.array[2];
            vec.array[3] = vec.array[3];
            return vec;
        }
    }
}
else
{
    __m128 _mm_sqrt_ss(__m128 vec) pure @trusted
    {
        vec.ptr[0] = sqrt(vec.array[0]);
        return vec;
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

void _mm_store_ps (float* mem_addr, __m128 a) pure // not safe since nothing guarantees alignment
{
    __m128* aligned = cast(__m128*)mem_addr;
    *aligned = a;
}

alias _mm_store_ps1 = _mm_store1_ps;

void _mm_store_ss (float* mem_addr, __m128 a) pure @safe
{
    *mem_addr = a.array[0];
}
unittest
{
    float a;
    _mm_store_ss(&a, _mm_set_ps(3, 2, 1, 546));
    assert(a == 546);
}

void _mm_store1_ps (float* mem_addr, __m128 a) pure // not safe since nothing guarantees alignment
{
    __m128* aligned = cast(__m128*)mem_addr;
    *aligned = shufflevector!(__m128, 0, 0, 0, 0)(a, a);
}

void _mm_storeh_pi(__m64* p, __m128 a) pure @trusted
{
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

void _mm_storel_pi(__m64* p, __m128 a) pure @trusted
{
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

void _mm_storer_ps(float* mem_addr, __m128 a) pure // not safe since nothing guarantees alignment
{
    __m128* aligned = cast(__m128*)mem_addr;
    *aligned = shufflevector!(__m128, 3, 2, 1, 0)(a, a);
}

void _mm_storeu_ps(float* mem_addr, __m128 a) pure @safe
{
    storeUnaligned!(float4)(a, mem_addr);
}

void _mm_stream_pi (__m64* mem_addr, __m64 a)
{
    // BUG see `_mm_stream_ps` for an explanation why we don't implement non-temporal moves
    *mem_addr = a; // it's a regular move instead
}

// BUG: can't implement non-temporal store with LDC inlineIR since !nontemporal
// needs some IR outside this function that would say:
//
//  !0 = !{ i32 1 }
//
// It's a LLVM IR metadata description.
// Regardless, non-temporal moves are really dangerous for performance...
void _mm_stream_ps (float* mem_addr, __m128 a)
{
    __m128* dest = cast(__m128*)mem_addr;
    *dest = a; // it's a regular move instead
}
unittest
{
    align(16) float[4] A;
    _mm_stream_ps(A.ptr, _mm_set1_ps(78.0f));
    assert(A[0] == 78.0f && A[1] == 78.0f && A[2] == 78.0f && A[3] == 78.0f);
}

__m128 _mm_sub_ps(__m128 a, __m128 b) pure @safe
{
    return a - b;
}
unittest
{
    __m128 a = [1.5f, -2.0f, 3.0f, 1.0f];
    a = _mm_sub_ps(a, a);
    float[4] correct = [0.0f, 0.0f, 0.0f, 0.0f];
    assert(a.array == correct);
}

__m128 _mm_sub_ss(__m128 a, __m128 b) pure @safe
{
    static if (GDC_X86)
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


__m128 _mm_undefined_ps() pure @safe
{
    __m128 undef = void;
    return undef;
}

__m128 _mm_unpackhi_ps (__m128 a, __m128 b) pure @safe
{
    return shufflevector!(float4, 2, 6, 3, 7)(a, b);
}

__m128 _mm_unpacklo_ps (__m128 a, __m128 b) pure @safe
{
    return shufflevector!(float4, 0, 4, 1, 5)(a, b);
}

__m128 _mm_xor_ps (__m128 a, __m128 b) pure @safe
{
    return cast(__m128)(cast(__m128i)a ^ cast(__m128i)b);
}


private
{
    /// Returns: `true` if the pointer is suitably aligned.
    bool isPointerAligned(void* p, size_t alignment) pure
    {
        assert(alignment != 0);
        return ( cast(size_t)p & (alignment - 1) ) == 0;
    }

    /// Returns: next pointer aligned with alignment bytes.
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

    // Store pointer given my malloc, size and alignment
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
