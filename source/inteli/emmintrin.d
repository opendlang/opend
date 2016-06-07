/**
* Copyright: Copyright Auburn Sounds 2016.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.emmintrin;

version(LDC):

public import inteli.types;
import ldc.gccbuiltins_x86;


// SSE2
alias _mm_add_sd = __builtin_ia32_addsd;
alias _mm_clflush = __builtin_ia32_clflush;
alias _mm_cmpeq_pd = __builtin_ia32_cmppd;
alias _mm_cmpeq_sd = __builtin_ia32_cmpsd;
alias _mm_comieq_sd = __builtin_ia32_comisdeq;
alias _mm_comige_sd = __builtin_ia32_comisdge;
alias _mm_comigt_sd = __builtin_ia32_comisdgt;
alias _mm_comile_sd = __builtin_ia32_comisdle;
alias _mm_comilt_sd = __builtin_ia32_comisdlt;
alias _mm_comineq_sd = __builtin_ia32_comisdneq;
alias _mm_cvtepi32_pd = __builtin_ia32_cvtdq2pd;
alias _mm_cvtepi32_ps = __builtin_ia32_cvtdq2ps;
alias _mm_cvtpd_epi32 = __builtin_ia32_cvtpd2dq;
alias _mm_cvtpd_ps = __builtin_ia32_cvtpd2ps;
alias _mm_cvtps_epi32 = __builtin_ia32_cvtps2dq;
alias _mm_cvtps_pd = __builtin_ia32_cvtps2pd;
alias _mm_cvtsd_si32 = __builtin_ia32_cvtsd2si;
alias _mm_cvtsd_si64 = __builtin_ia32_cvtsd2si64;
alias _mm_cvtsd_ss = __builtin_ia32_cvtsd2ss;
alias _mm_cvtsi32_sd = __builtin_ia32_cvtsi2sd;
alias _mm_cvtsi64_sd = __builtin_ia32_cvtsi642sd;
alias _mm_cvtss_sd = __builtin_ia32_cvtss2sd;
alias _mm_cvttpd_epi32 = __builtin_ia32_cvttpd2dq;
alias _mm_cvttps_epi32 = __builtin_ia32_cvttps2dq;
alias _mm_cvttsd_si32 = __builtin_ia32_cvttsd2si;
alias _mm_cvttsd_si64 = __builtin_ia32_cvttsd2si64;
alias _mm_div_sd = __builtin_ia32_divsd;
alias _mm_lfence = __builtin_ia32_lfence;
alias _mm_maskmoveu_si128 = __builtin_ia32_maskmovdqu;
alias _mm_max_pd = __builtin_ia32_maxpd;
alias _mm_max_sd = __builtin_ia32_maxsd;
alias _mm_mfence = __builtin_ia32_mfence;
alias _mm_min_pd = __builtin_ia32_minpd;
alias _mm_min_sd = __builtin_ia32_minsd;
alias _mm_movemask_pd = __builtin_ia32_movmskpd;
alias _mm_mul_sd = __builtin_ia32_mulsd;
alias _mm_packs_epi32 = __builtin_ia32_packssdw128;
alias _mm_packs_epi16 = __builtin_ia32_packsswb128;
alias _mm_packus_epi16 = __builtin_ia32_packuswb128;
alias _mm_adds_epi8 = __builtin_ia32_paddsb128;
alias _mm_adds_epi16 = __builtin_ia32_paddsw128;
alias _mm_adds_epu8 = __builtin_ia32_paddusb128;
alias _mm_adds_epu16 = __builtin_ia32_paddusw128;
alias _mm_pause = __builtin_ia32_pause;
alias _mm_avg_epu8 = __builtin_ia32_pavgb128;
alias _mm_avg_epu16 = __builtin_ia32_pavgw128;
alias _mm_madd_epi16 = __builtin_ia32_pmaddwd128;
alias _mm_max_epi16 = __builtin_ia32_pmaxsw128;
alias _mm_max_epu8 = __builtin_ia32_pmaxub128;
alias _mm_min_epi16 = __builtin_ia32_pminsw128;
alias _mm_min_epu8 = __builtin_ia32_pminub128;
alias _mm_movemask_epi8 = __builtin_ia32_pmovmskb128;
alias _mm_mulhi_epi16 = __builtin_ia32_pmulhw128;
alias _mm_mulhi_epu16 = __builtin_ia32_pmulhuw128;
alias _mm_mul_epu32 = __builtin_ia32_pmuludq128;
alias _mm_sad_epu8 = __builtin_ia32_psadbw128;
alias _mm_shuffle_epi32 = __builtin_ia32_pshufd;
alias _mm_shufflehi_epi16 = __builtin_ia32_pshufhw;
alias _mm_shufflelo_epi16 = __builtin_ia32_pshuflw;
alias _mm_sll_epi32 = __builtin_ia32_pslld128;
alias _mm_sll_epi64 = __builtin_ia32_psllq128;
alias _mm_sll_epi16 = __builtin_ia32_psllw128;
alias _mm_slli_epi32 = __builtin_ia32_pslldi128;
alias _mm_slli_epi64 = __builtin_ia32_psllqi128;
alias _mm_slli_epi16 = __builtin_ia32_psllwi128;
alias _mm_sra_epi32 = __builtin_ia32_psrad128;
alias _mm_sra_epi16 = __builtin_ia32_psraw128;
alias _mm_srai_epi32 = __builtin_ia32_psradi128;
alias _mm_srai_epi16= __builtin_ia32_psrawi128;
alias _mm_srl_epi32 = __builtin_ia32_psrld128;
alias _mm_srl_epi64 = __builtin_ia32_psrlq128;
alias _mm_srl_epi16 = __builtin_ia32_psrlw128;
alias _mm_srli_epi32 = __builtin_ia32_psrldi128;
alias _mm_srlq_epi32 = __builtin_ia32_psrlqi128;
alias _mm_srlw_epi32 = __builtin_ia32_psrlwi128;
alias _mm_subs_epi8 = __builtin_ia32_psubsb128;
alias _mm_subs_epi16 = __builtin_ia32_psubsw128;
alias _mm_subs_epu8 = __builtin_ia32_psubusb128;
alias _mm_subs_epu16 = __builtin_ia32_psubusw128;
alias _mm_sqrt_pd = __builtin_ia32_sqrtpd;
alias _mm_sqrt_sd = __builtin_ia32_sqrtsd;
alias _mm_storel_epi64 = __builtin_ia32_storelv4si;
alias _mm_store_si128 = __builtin_ia32_storedqu;
alias _mm_storeu_pd = __builtin_ia32_storeupd;
alias _mm_sub_sd = __builtin_ia32_subsd;
alias _mm_ucomieq_sd = __builtin_ia32_ucomisdeq;
alias _mm_ucomige_sd = __builtin_ia32_ucomisdge;
alias _mm_ucomigt_sd = __builtin_ia32_ucomisdgt;
alias _mm_ucomile_sd = __builtin_ia32_ucomisdle;
alias _mm_ucomilt_sd = __builtin_ia32_ucomisdlt;
alias _mm_ucomineq_sd = __builtin_ia32_ucomisdneq;

