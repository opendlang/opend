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
alias _mm_add_ss = __builtin_ia32_addss;

alias _mm_cmpeq_ss = __builtin_ia32_cmpps;
alias _mm_comieq_ss = __builtin_ia32_comieq;
alias _mm_comige_ss = __builtin_ia32_comige;
alias _mm_comigt_ss = __builtin_ia32_comigt;
alias _mm_comile_ss = __builtin_ia32_comile;
alias _mm_comilt_ss = __builtin_ia32_comilt;
alias _mm_comineq_ss = __builtin_ia32_comineq;
alias _mm_cvt_si2ss = __builtin_ia32_cvtsi2ss;
alias _mm_cvtsi64_ss = __builtin_ia32_cvtsi642ss;
alias _mm_cvt_ss2si = __builtin_ia32_cvtss2si;
alias _mm_cvtss_si64 = __builtin_ia32_cvtss2si64;
alias _mm_cvtss_si32 = __builtin_ia32_cvttss2si;
alias _mm_cvtss_si64 = __builtin_ia32_cvttss2si64;
float _mm_cvtss_f32(__m128 a) pure @safe
{
    return a.ptr[0];
}

alias _mm_div_ss = __builtin_ia32_divss;
alias _mm_max_ps = __builtin_ia32_maxps;
alias _mm_max_ss = __builtin_ia32_maxss;
alias _mm_min_ps = __builtin_ia32_minps;
alias _mm_min_ss = __builtin_ia32_minss;
alias _mm_movemask_ps = __builtin_ia32_movmskps;

__m128 _mm_mul_ps(__m128 a, __m128 b) pure @safe
{
    return a * b;    
}
alias _mm_mul_ss = __builtin_ia32_mulss;

float4 _mm_load_ps(const(float)*p)
{
    return *cast(__m128*)p;
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
alias _mm_storeu_ps = __builtin_ia32_storeups;

__m128 _mm_sub_ps(__m128 a, __m128 b) pure @safe
{
  return a - b;
}
alias _mm_sub_ss = __builtin_ia32_subss;

alias _mm_ucomieq_ss = __builtin_ia32_ucomieq;
alias _mm_ucomige_ss = __builtin_ia32_ucomige;
alias _mm_ucomigt_ss = __builtin_ia32_ucomigt;
alias _mm_ucomile_ss = __builtin_ia32_ucomile;
alias _mm_ucomilt_ss = __builtin_ia32_ucomilt;
alias _mm_ucomineq_ss = __builtin_ia32_ucomineq;


