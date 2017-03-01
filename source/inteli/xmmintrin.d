/**
* Copyright: Copyright Auburn Sounds 2016.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.xmmintrin;

version(LDC):

public import inteli.types;
import ldc.gccbuiltins_x86;

// SSE1

nothrow @nogc:

float4 _mm_add_ps(float4 a, float4 b) pure @safe
{
    return a + b;
}
pragma(LDC_intrinsic, "llvm.x86.sse.add.ss")
    float4 _mm_add_ss(float4, float4) pure @safe;

__m128i _mm_and_ps (__m128i a, __m128i b) pure @safe
{
    return a & b;
}

__m128i _mm_andnot_ps (__m128i a, __m128i b) pure @safe
{
    return (~a) & b;
}

// TODO: _mm_avg_pu16
// TODO: _mm_avg_pu8

pragma(LDC_intrinsic, "llvm.x86.sse.cmp.ps")
    float4 __builtin_ia32_cmpps(float4, float4, byte) pure @safe;
    
__m128 _mm_cmpeq_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(a, b, 0);
}

__m128 _mm_cmpeq_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(a, b, 0);
}

__m128 _mm_cmpge_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(b, a, 2); // CMPLEPS reversed
}

__m128 _mm_cmpge_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(b, a, 2); // CMPLESS reversed
}

__m128 _mm_cmpgt_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(b, a, 1); // CMPLTPS reversed
}

__m128 _mm_cmpgt_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(b, a, 1); // CMPLTSS reversed
}

__m128 _mm_cmple_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(a, b, 2); // CMPLEPS
}

__m128 _mm_cmple_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(a, b, 2); // CMPLESS
}

__m128 _mm_cmplt_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(a, b, 1); // CMPLTPS
}

__m128 _mm_cmplt_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(a, b, 1); // CMPLTSS
}

__m128 _mm_cmpneq_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(a, b, 4); // CMPNEQPS
}

__m128 _mm_cmpneq_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(a, b, 4); // CMPNEQSS
}

__m128 _mm_cmpnge_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(b, a, 6); // CMPNLEPS reversed
}

__m128 _mm_cmpnge_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(b, a, 6); // CMPNLESS reversed
}

__m128 _mm_cmpngt_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(b, a, 5); // CMPNLTPS reversed
}

__m128 _mm_cmpngt_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(b, a, 5); // CMPNLTPS reversed
}

__m128 _mm_cmpnle_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(a, b, 6); // CMPNLEPS
}

__m128 _mm_cmpnle_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(a, b, 6); // CMPNLESS
}

__m128 _mm_cmpnlt_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(a, b, 5); // CMPNLTPS
}

__m128 _mm_cmpnlt_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(a, b, 5); // CMPNLTSS
}

__m128 _mm_cmpord_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(a, b, 7); // CMPORDPS
}

__m128 _mm_cmpord_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(a, b, 7); // CMPORDSS
}

__m128 _mm_cmpunord_ps (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpps(a, b, 3); // CMPUNORDPS
}

__m128 _mm_cmpunord_ss (__m128 a, __m128 b) pure @safe
{
    return __builtin_ia32_cmpss(a, b, 3); // CMPUNORDSS
}

alias _mm_comieq_ss = __builtin_ia32_comieq;
alias _mm_comige_ss = __builtin_ia32_comige;
alias _mm_comigt_ss = __builtin_ia32_comigt;
alias _mm_comile_ss = __builtin_ia32_comile;
alias _mm_comilt_ss = __builtin_ia32_comilt;
alias _mm_comineq_ss = __builtin_ia32_comineq;

// TODO: __m128 _mm_cvt_pi2ps (__m128 a, __m64 b)
// TODO: __m64 _mm_cvt_ps2pi (__m128 a)

alias _mm_cvt_si2ss = __builtin_ia32_cvtsi2ss;
alias _mm_cvt_ss2si = __builtin_ia32_cvtss2si;

// TODO: __m128 _mm_cvtpi16_ps (__m64 a)
// TODO: __m128 _mm_cvtpi32_ps (__m128 a, __m64 b)
// TODO: __m128 _mm_cvtpi32x2_ps (__m64 a, __m64 b)
// TODO: __m128 _mm_cvtpi8_ps (__m64 a)
// TODO: __m64 _mm_cvtps_pi16 (__m128 a)
// TODO: __m64 _mm_cvtps_pi32 (__m128 a)
// TODO: __m64 _mm_cvtps_pi8 (__m128 a)
// TODO: __m128 _mm_cvtpu16_ps (__m64 a)
// TODO: __m128 _mm_cvtpu8_ps (__m64 a)
// TODO: __m128 _mm_cvtsi32_ss (__m128 a, int b)

alias _mm_cvtsi64_ss = __builtin_ia32_cvtsi642ss;

// TODO: is this the right way?
float _mm_cvtss_f32(__m128 a) pure @safe
{
    return a.ptr[0];
}

// TODO: float _mm256_cvtss_f32 (__m256 a)
// TODO: float _mm512_cvtss_f32 (__m512 a)

alias _mm_cvtss_si32 = __builtin_ia32_cvttss2si;
alias _mm_cvtss_si64 = __builtin_ia32_cvtss2si64;

// TODO: __m64 _mm_cvtt_ps2pi (__m128 a)
// TODO: int _mm_cvtt_ss2si (__m128 a)
// TODO: __m64 _mm_cvttps_pi32 (__m128 a)
// TODO: int _mm_cvttss_si32 (__m128 a)
// TODO: __int64 _mm_cvttss_si64 (__m128 a)

float4 _mm_div_ps(float4 a, float4 b) pure @safe
{
    return a / b;
}
pragma(LDC_intrinsic, "llvm.x86.sse.div.ss")
    float4 _mm_div_ss(float4, float4) pure @safe;

// TODO: int _mm_extract_pi16 (__m64 a, int imm8)
// TODO: unsigned int _MM_GET_EXCEPTION_MASK ()
// TODO: unsigned int _MM_GET_EXCEPTION_STATE ()
// TODO: unsigned int _MM_GET_FLUSH_ZERO_MODE ()
// TODO: unsigned int _MM_GET_ROUNDING_MODE ()
// TODO: stmxcsr
// TODO: unsigned int _mm_getcsr (void)

// TODO: __m64 _mm_insert_pi16 (__m64 a, int i, int imm8)

float4 _mm_load_ps(const(float)*p)
{
    return *cast(__m128*)p;
}

alias _mm_load1_ps = _mm_load_ps1;
float4 _mm_load_ps1(const(float)*p)
{
    float4 f = [ *p, *p, *p, *p ];
    return f;
}

float4 _mm_load_ss (const(float)* mem_addr)
{
    float4 f = [ *mem_addr, 0.0f, 0.0f, 0.0f ];
    return f;
}

float4 _mm_loadu_ps(const(float)*p)
{
    union float4_array
    {
        __m128 vec;
        float[4] arr;
    }
    float4_array fa = void;
    fa.arr = *cast(float[4]*)p;
    return fa.vec;
}

alias _mm_max_ps = __builtin_ia32_maxps;
alias _mm_max_ss = __builtin_ia32_maxss;
alias _mm_min_ps = __builtin_ia32_minps;
alias _mm_min_ss = __builtin_ia32_minss;
alias _mm_movemask_ps = __builtin_ia32_movmskps;

__m128 _mm_mul_ps(__m128 a, __m128 b) pure @safe
{
    return a * b;    
}
pragma(LDC_intrinsic, "llvm.x86.sse.mul.ss")
    float4 _mm_mul_ss(float4, float4) pure @safe;

alias _mm_rcp_ps = __builtin_ia32_rcpps;
alias _mm_rcp_ss = __builtin_ia32_rcpss;
alias _mm_rsqrt_ps = __builtin_ia32_rsqrtps;
alias _mm_rsqrt_ss = __builtin_ia32_rsqrtss;

__m128i _mm_setzero_si128()
{
    return __m128i([0, 0, 0, 0]);
}

alias _mm_sfence = __builtin_ia32_sfence;
alias _mm_sqrt_ps = __builtin_ia32_sqrtps;
alias _mm_sqrt_ss = __builtin_ia32_sqrtss;

pragma(LDC_intrinsic, "llvm.x86.sse.storeu.ps")
    void __builtin_ia32_storeups(void*, float4);
alias _mm_storeu_ps = __builtin_ia32_storeups;

__m128 _mm_sub_ps(__m128 a, __m128 b) pure @safe
{
    return a - b;
}
pragma(LDC_intrinsic, "llvm.x86.sse.sub.ss")
    float4 _mm_sub_ss(float4, float4) pure @safe;

alias _mm_ucomieq_ss = __builtin_ia32_ucomieq;
alias _mm_ucomige_ss = __builtin_ia32_ucomige;
alias _mm_ucomigt_ss = __builtin_ia32_ucomigt;
alias _mm_ucomile_ss = __builtin_ia32_ucomile;
alias _mm_ucomilt_ss = __builtin_ia32_ucomilt;
alias _mm_ucomineq_ss = __builtin_ia32_ucomineq;


