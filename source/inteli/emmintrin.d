/**
* Copyright: Copyright Auburn Sounds 2016.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.emmintrin;

version(LDC):

public import inteli.xmmintrin; // SSE2 includes SSE1

public import inteli.types;
import core.simd;
import inteli.ldc_compat;
import ldc.gccbuiltins_x86;

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

pragma(LDC_intrinsic, "llvm.x86.sse2.add.sd")
    double2 __builtin_ia32_addsd(double2, double2) pure @safe;
alias _mm_add_sd = __builtin_ia32_addsd;

__m128d _mm_add_pd (__m128d a, __m128d b) pure @safe
{
    return a + b;
}
// MMXREG: _mm_add_si64

alias _mm_adds_epi16 = __builtin_ia32_paddsw128;
alias _mm_adds_epi8 = __builtin_ia32_paddsb128;
alias _mm_adds_epu8 = __builtin_ia32_paddusb128;
alias _mm_adds_epu16 = __builtin_ia32_paddusw128;

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

alias _mm_avg_epu16 = __builtin_ia32_pavgw128;
alias _mm_avg_epu8 = __builtin_ia32_pavgb128;

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

alias _mm_clflush = __builtin_ia32_clflush;

pragma(LDC_intrinsic, "llvm.x86.sse2.cmp.pd")
    double2 __builtin_ia32_cmppd(double2, double2, byte) pure @safe;

// TODO
/+
__m128i _mm_cmpeq_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( cast(short8)a == cast(short8)b );
}

__m128i _mm_cmpeq_epi32 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( cast(int4)a == cast(int4)b );
}

__m128i _mm_cmpeq_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( cast(byte16)a == cast(byte16)b );
}
+/

__m128d _mm_cmpeq_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(a, b, 0);
}

__m128d _mm_cmpeq_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(a, b, 0);
}

__m128d _mm_cmpge_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(b, a, 2);
}

__m128d _mm_cmpge_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(b, a, 2);
}

// TODO
/+__m128i _mm_cmpgt_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( cast(short8)a > cast(short8)b );
}

__m128i _mm_cmpgt_epi32 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( cast(int4)a > cast(int4)b );
}

__m128i _mm_cmpgt_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( cast(byte16)a > cast(byte16)b );
}+/

__m128d _mm_cmpgt_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(b, a, 1);
}

__m128d _mm_cmpgt_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(b, a, 1);
}

__m128d _mm_cmple_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(a, b, 2);
}

__m128d _mm_cmple_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(a, b, 2);
}

// TODO
/+__m128i _mm_cmplt_epi16 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( cast(short8)a < cast(short8)b );
}

__m128i _mm_cmplt_epi32 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( cast(int4)a < cast(int4)b );
}

__m128i _mm_cmplt_epi8 (__m128i a, __m128i b) pure @safe
{
    return cast(__m128i)( cast(byte8)a < cast(byte8)b );
}+/

__m128d _mm_cmplt_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(a, b, 1);
}

__m128d _mm_cmplt_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(a, b, 1);
}

__m128d _mm_cmpneq_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(a, b, 4);
}

__m128d _mm_cmpneq_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(a, b, 4);
}

__m128d _mm_cmpnge_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(b, a, 6);
}

__m128d _mm_cmpnge_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(b, a, 6);
}

__m128d _mm_cmpngt_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(b, a, 5);
}

__m128d _mm_cmpngt_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(b, a, 5);
}

__m128d _mm_cmpnle_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(a, b, 6);
}

__m128d _mm_cmpnle_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(a, b, 6);
}

__m128d _mm_cmpnlt_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(a, b, 5);
}

__m128d _mm_cmpnlt_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(a, b, 5);
}

__m128d _mm_cmpord_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(a, b, 7);
}

__m128d _mm_cmpord_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(a, b, 7);
}

__m128d _mm_cmpunord_pd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmppd(a, b, 3);
}

__m128d _mm_cmpunord_sd (__m128d a, __m128d b) pure @safe
{
    return __builtin_ia32_cmpsd(a, b, 3);
}

alias _mm_comieq_sd = __builtin_ia32_comisdeq;
alias _mm_comige_sd = __builtin_ia32_comisdge;
alias _mm_comigt_sd = __builtin_ia32_comisdgt;
alias _mm_comile_sd = __builtin_ia32_comisdle;
alias _mm_comilt_sd = __builtin_ia32_comisdlt;
alias _mm_comineq_sd = __builtin_ia32_comisdneq;

// TODO: alias _mm_cvtepi32_pd = __builtin_ia32_cvtdq2pd;

alias _mm_cvtepi32_ps = __builtin_ia32_cvtdq2ps;
alias _mm_cvtpd_epi32 = __builtin_ia32_cvtpd2dq;
// MMXREG: _mm_cvtpd_pi32

alias _mm_cvtpd_ps = __builtin_ia32_cvtpd2ps;
// MMXREG: _mm_cvtpi32_pd
alias _mm_cvtps_epi32 = __builtin_ia32_cvtps2dq;

// TODO: alias _mm_cvtps_pd = __builtin_ia32_cvtps2pd;

double _mm_cvtsd_f64 (__m128d a) pure @safe
{
    return extractelement!(double2, 0)(a);
}

alias _mm_cvtsd_si32 = __builtin_ia32_cvtsd2si;
alias _mm_cvtsd_si64 = __builtin_ia32_cvtsd2si64;
alias _mm_cvtsd_si64x = _mm_cvtsd_si64;

alias _mm_cvtsd_ss = __builtin_ia32_cvtsd2ss;
int _mm_cvtsi128_si32 (__m128i a) pure @safe
{
    return extractelement!(int4, 0)(a);
}

long _mm_cvtsi128_si64 (__m128i a) pure @safe
{
    return extractelement!(long2, 0)(a);
}
alias _mm_cvtsi128_si64x = _mm_cvtsi128_si64;

alias _mm_cvtsi32_sd = __builtin_ia32_cvtsi2sd;

__m128i _mm_cvtsi32_si128 (int a) pure @safe
{
    int4 r = [a, 0, 0, 0];
    return r;
}

alias _mm_cvtsi64_sd = __builtin_ia32_cvtsi642sd;

__m128i _mm_cvtsi64_si128 (long a) pure @safe
{
    long2 r = [a, 0];
    return r;
}

alias _mm_cvtsi64x_sd = _mm_cvtsi64_sd;
alias _mm_cvtsi64x_si128 = _mm_cvtsi64_si128;



alias _mm_cvtss_sd = __builtin_ia32_cvtss2sd;
alias _mm_cvttpd_epi32 = __builtin_ia32_cvttpd2dq;
//MMXREG: _mm_cvttpd_pi32
alias _mm_cvttps_epi32 = __builtin_ia32_cvttps2dq;
alias _mm_cvttsd_si32 = __builtin_ia32_cvttsd2si;
alias _mm_cvttsd_si64 = __builtin_ia32_cvttsd2si64;
alias _mm_cvttsd_si64x = _mm_cvttsd_si64;

pragma(LDC_intrinsic, "llvm.x86.sse2.div.sd")
    double2 __builtin_ia32_divsd(double2, double2) pure @safe;

__m128d _mm_div_ps(__m128d a, __m128d b)
{
    return a / b;
}
alias _mm_div_sd = __builtin_ia32_divsd;

int _mm_extract_epi16(int imm8)(__m128i a) pure @safe
{
    return shufflevector!(short8, imm8)(a);
}

__m128i _mm_insert_epi16(int imm8)(__m128i a, int i) pure @safe
{
    return insertelement!(short8, imm8)(a, i);
}

alias _mm_lfence = __builtin_ia32_lfence;

__m128d _mm_load_pd (const(double) * mem_addr) pure
{
    __m128d* aligned = cast(__m128d*)mem_addr;
    return *aligned;
}

__m128d _mm_load_pd1 (const(double)* mem_addr) pure @safe
{
    return [*mem_addr, *mem_addr];
}

__m128d _mm_load_sd (const(double)* mem_addr) pure @safe
{
    return [*mem_addr, 0];
}

__m128i _mm_load_si128 (const(__m128i)* mem_addr) pure
{
    return *mem_addr;
}

alias _mm_load1_pd = _mm_load_pd1;

__m128d _mm_loadh_pd (__m128d a, const(double)* mem_addr) pure @safe
{
    return insertelement!(__m128d, 1)(a, *mem_addr);
}

// Note: strange signature since the memory doesn't have to aligned
__m128i _mm_loadl_epi64 (const(__m128i)* mem_addr) pure @safe
{
    auto pLong = cast(const(long)*)mem_addr;
    long2 res = [*pLong, 0];
    return cast(__m128i)res;
}
__m128d _mm_loadl_pd (__m128d a, const(double)* mem_addr) pure @safe
{
    return insertelement!(__m128d, 0)(a, *mem_addr);
}

__m128d _mm_loadr_pd (const(double)* mem_addr) pure
{
    __m128d a = _mm_load_pd(mem_addr);
    return shufflevector!(__m128d, 1, 0)(a, a);
}

__m128d _mm_loadu_pd (const(double)* mem_addr) pure @safe
{
    return loadUnaligned!(double2)(mem_addr);
}

__m128i _mm_loadu_si128 (const(__m128i)* mem_addr) pure
{
    return loadUnaligned!(__m128i)(cast(int*)mem_addr);
}

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

__m128i _mm_move_epi64 (__m128i a) pure @safe
{
    long2 result = [ extractelement!(long2, 0)(a), 0 ];
    return result;
}

__m128d _mm_move_sd (__m128d a, __m128d b) pure @safe
{
    return shufflevector!(double2, 2, 1)(a, b);
}

alias _mm_movemask_epi8 = __builtin_ia32_pmovmskb128;
alias _mm_movemask_pd = __builtin_ia32_movmskpd;
// MMXREG: _mm_movepi64_pi64
// MMXREG: __m128i _mm_movpi64_epi64 (__m64 a)

alias _mm_mul_epu32 = __builtin_ia32_pmuludq128;

__m128d _mm_mul_pd(__m128d a, __m128d b) pure @safe
{
    return a * b;
}

pragma(LDC_intrinsic, "llvm.x86.sse2.mul.sd")
    double2 __builtin_ia32_mulsd(double2, double2) pure @safe;
alias _mm_mul_sd = __builtin_ia32_mulsd;

// MMXREG: _mm_mul_su32

alias _mm_mulhi_epi16 = __builtin_ia32_pmulhw128;
alias _mm_mulhi_epu16 = __builtin_ia32_pmulhuw128;

__m128i _mm_mullo_epi16 (__m128i a, __m128i b)
{
    return cast(__m128i)(cast(short8)a * cast(short8)b);
}

unittest
{
    short8 a;
    short8 b;
    a = _mm_mullo_epi16(a, b);
}

alias _mm_packs_epi32 = __builtin_ia32_packssdw128;
alias _mm_packs_epi16 = __builtin_ia32_packsswb128;
alias _mm_packus_epi16 = __builtin_ia32_packuswb128;

alias _mm_pause = __builtin_ia32_pause;



alias _mm_sad_epu8 = __builtin_ia32_psadbw128;

__m128i _mm_setzero_si128() pure @safe
{
    return [0, 0, 0, 0];
}

pragma(LDC_intrinsic, "llvm.x86.sse2.pshuf.d")
    int4 __builtin_ia32_pshufd(int4, byte) pure @safe;
alias _mm_shuffle_epi32 = __builtin_ia32_pshufd;

pragma(LDC_intrinsic, "llvm.x86.sse2.pshufh.w")
    short8 __builtin_ia32_pshufhw(short8, byte) pure @safe;
alias _mm_shufflehi_epi16 = __builtin_ia32_pshufhw;

pragma(LDC_intrinsic, "llvm.x86.sse2.pshufl.w")
    short8 __builtin_ia32_pshuflw(short8, byte) pure @safe;
alias _mm_shufflelo_epi16 = __builtin_ia32_pshuflw;


alias _mm_sll_epi32 = __builtin_ia32_pslld128;
alias _mm_sll_epi64 = __builtin_ia32_psllq128;
alias _mm_sll_epi16 = __builtin_ia32_psllw128;
alias _mm_slli_epi32 = __builtin_ia32_pslldi128;
alias _mm_slli_epi64 = __builtin_ia32_psllqi128;
alias _mm_slli_epi16 = __builtin_ia32_psllwi128;

__m128i _mm_slli_si128(ubyte imm8)(__m128i op)
{
    static if (imm8 & 0xF0)
        return _mm_setzero_si128();
    else
        return shufflevector!(byte16,
        16 - imm8, 17 - imm8, 18 - imm8, 19 - imm8, 20 - imm8, 21 - imm8, 22 - imm8, 23 - imm8,
        24 - imm8, 25 - imm8, 26 - imm8, 27 - imm8, 28 - imm8, 29 - imm8, 30 - imm8, 31 - imm8)
        (_mm_setzero_si128(), op);
}

alias _mm_sra_epi32 = __builtin_ia32_psrad128;
alias _mm_sra_epi16 = __builtin_ia32_psraw128;
alias _mm_srai_epi32 = __builtin_ia32_psradi128;
alias _mm_srai_epi16= __builtin_ia32_psrawi128;
alias _mm_srl_epi32 = __builtin_ia32_psrld128;
alias _mm_srl_epi64 = __builtin_ia32_psrlq128;
alias _mm_srl_epi16 = __builtin_ia32_psrlw128;
alias _mm_srli_epi32 = __builtin_ia32_psrldi128;

__m128i _mm_srli_si128(ubyte imm8)(__m128i op)
{
    static if (imm8 & 0xF0)
        return _mm_setzero_si128();
    else
        return shufflevector!(byte16,
        imm8+0, imm8+1, imm8+2, imm8+3, imm8+4, imm8+5, imm8+6, imm8+7,
        imm8+8, imm8+9, imm8+10, imm8+11, imm8+12, imm8+13, imm8+14, imm8+15)(op, _mm_setzero_si128());
}

alias _mm_bsrli_si128 = _mm_srli_si128;

alias _mm_srlq_epi32 = __builtin_ia32_psrlqi128;
alias _mm_srlw_epi32 = __builtin_ia32_psrlwi128;

alias _mm_subs_epi8 = __builtin_ia32_psubsb128;
alias _mm_subs_epi16 = __builtin_ia32_psubsw128;
alias _mm_subs_epu8 = __builtin_ia32_psubusb128;
alias _mm_subs_epu16 = __builtin_ia32_psubusw128;
alias _mm_sqrt_pd = __builtin_ia32_sqrtpd;
alias _mm_sqrt_sd = __builtin_ia32_sqrtsd;

pragma(LDC_intrinsic, "llvm.x86.sse2.storel.dq")
    void __builtin_ia32_storelv4si(void*, int4);
alias _mm_storel_epi64 = __builtin_ia32_storelv4si;

pragma(LDC_intrinsic, "llvm.x86.sse2.storeu.dq")
    void __builtin_ia32_storedqu(void*, byte16);
alias _mm_store_si128 = __builtin_ia32_storedqu;

pragma(LDC_intrinsic, "llvm.x86.sse2.storeu.pd")
    void __builtin_ia32_storeupd(void*, double2);
alias _mm_storeu_pd = __builtin_ia32_storeupd;

pragma(LDC_intrinsic, "llvm.x86.sse2.sub.sd")
    double2 __builtin_ia32_subsd(double2, double2) pure @safe;
alias _mm_sub_sd = __builtin_ia32_subsd;

alias _mm_ucomieq_sd = __builtin_ia32_ucomisdeq;
alias _mm_ucomige_sd = __builtin_ia32_ucomisdge;
alias _mm_ucomigt_sd = __builtin_ia32_ucomisdgt;
alias _mm_ucomile_sd = __builtin_ia32_ucomisdle;
alias _mm_ucomilt_sd = __builtin_ia32_ucomisdlt;
alias _mm_ucomineq_sd = __builtin_ia32_ucomisdneq;

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