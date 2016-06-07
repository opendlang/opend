/**
* Copyright: Copyright Auburn Sounds 2016.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.emmintrin;

public import inteli.types;
import ldc.gccbuiltins_x86;


// SSE2
/+
pragma(LDC_intrinsic, "llvm.x86.sse2.add.sd")
    double2 __builtin_ia32_addsd(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.clflush")
    void __builtin_ia32_clflush(void*);

pragma(LDC_intrinsic, "llvm.x86.sse2.cmp.pd")
    double2 __builtin_ia32_cmppd(double2, double2, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cmp.sd")
    double2 __builtin_ia32_cmpsd(double2, double2, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.comieq.sd")
    int __builtin_ia32_comisdeq(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.comige.sd")
    int __builtin_ia32_comisdge(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.comigt.sd")
    int __builtin_ia32_comisdgt(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.comile.sd")
    int __builtin_ia32_comisdle(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.comilt.sd")
    int __builtin_ia32_comisdlt(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.comineq.sd")
    int __builtin_ia32_comisdneq(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtdq2pd")
    double2 __builtin_ia32_cvtdq2pd(int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtdq2ps")
    float4 __builtin_ia32_cvtdq2ps(int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtpd2dq")
    int4 __builtin_ia32_cvtpd2dq(double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtpd2ps")
    float4 __builtin_ia32_cvtpd2ps(double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtps2dq")
    int4 __builtin_ia32_cvtps2dq(float4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtps2pd")
    double2 __builtin_ia32_cvtps2pd(float4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtsd2si")
    int __builtin_ia32_cvtsd2si(double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtsd2si64")
    long __builtin_ia32_cvtsd2si64(double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtsd2ss")
    float4 __builtin_ia32_cvtsd2ss(float4, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtsi2sd")
    double2 __builtin_ia32_cvtsi2sd(double2, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtsi642sd")
    double2 __builtin_ia32_cvtsi642sd(double2, long) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvtss2sd")
    double2 __builtin_ia32_cvtss2sd(double2, float4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvttpd2dq")
    int4 __builtin_ia32_cvttpd2dq(double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvttps2dq")
    int4 __builtin_ia32_cvttps2dq(float4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvttsd2si")
    int __builtin_ia32_cvttsd2si(double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.cvttsd2si64")
    long __builtin_ia32_cvttsd2si64(double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.div.sd")
    double2 __builtin_ia32_divsd(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.lfence")
    void __builtin_ia32_lfence();

pragma(LDC_intrinsic, "llvm.x86.sse2.maskmov.dqu")
    void __builtin_ia32_maskmovdqu(byte16, byte16, void*);

pragma(LDC_intrinsic, "llvm.x86.sse2.max.pd")
    double2 __builtin_ia32_maxpd(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.max.sd")
    double2 __builtin_ia32_maxsd(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.mfence")
    void __builtin_ia32_mfence();

pragma(LDC_intrinsic, "llvm.x86.sse2.min.pd")
    double2 __builtin_ia32_minpd(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.min.sd")
    double2 __builtin_ia32_minsd(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.movmsk.pd")
    int __builtin_ia32_movmskpd(double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.mul.sd")
    double2 __builtin_ia32_mulsd(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.packssdw.128")
    short8 __builtin_ia32_packssdw128(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.packsswb.128")
    byte16 __builtin_ia32_packsswb128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.packuswb.128")
    byte16 __builtin_ia32_packuswb128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.padds.b")
    byte16 __builtin_ia32_paddsb128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.padds.w")
    short8 __builtin_ia32_paddsw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.paddus.b")
    byte16 __builtin_ia32_paddusb128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.paddus.w")
    short8 __builtin_ia32_paddusw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pause")
    void __builtin_ia32_pause();

pragma(LDC_intrinsic, "llvm.x86.sse2.pavg.b")
    byte16 __builtin_ia32_pavgb128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pavg.w")
    short8 __builtin_ia32_pavgw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pmadd.wd")
    int4 __builtin_ia32_pmaddwd128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pmaxs.w")
    short8 __builtin_ia32_pmaxsw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pmaxu.b")
    byte16 __builtin_ia32_pmaxub128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pmins.w")
    short8 __builtin_ia32_pminsw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pminu.b")
    byte16 __builtin_ia32_pminub128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pmovmskb.128")
    int __builtin_ia32_pmovmskb128(byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pmulh.w")
    short8 __builtin_ia32_pmulhw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pmulhu.w")
    short8 __builtin_ia32_pmulhuw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pmulu.dq")
    long2 __builtin_ia32_pmuludq128(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psad.bw")
    long2 __builtin_ia32_psadbw128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pshuf.d")
    int4 __builtin_ia32_pshufd(int4, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pshufh.w")
    short8 __builtin_ia32_pshufhw(short8, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pshufl.w")
    short8 __builtin_ia32_pshuflw(short8, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psll.d")
    int4 __builtin_ia32_pslld128(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psll.q")
    long2 __builtin_ia32_psllq128(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psll.w")
    short8 __builtin_ia32_psllw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pslli.d")
    int4 __builtin_ia32_pslldi128(int4, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pslli.q")
    long2 __builtin_ia32_psllqi128(long2, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.pslli.w")
    short8 __builtin_ia32_psllwi128(short8, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psra.d")
    int4 __builtin_ia32_psrad128(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psra.w")
    short8 __builtin_ia32_psraw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psrai.d")
    int4 __builtin_ia32_psradi128(int4, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psrai.w")
    short8 __builtin_ia32_psrawi128(short8, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psrl.d")
    int4 __builtin_ia32_psrld128(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psrl.q")
    long2 __builtin_ia32_psrlq128(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psrl.w")
    short8 __builtin_ia32_psrlw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psrli.d")
    int4 __builtin_ia32_psrldi128(int4, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psrli.q")
    long2 __builtin_ia32_psrlqi128(long2, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psrli.w")
    short8 __builtin_ia32_psrlwi128(short8, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psubs.b")
    byte16 __builtin_ia32_psubsb128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psubs.w")
    short8 __builtin_ia32_psubsw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psubus.b")
    byte16 __builtin_ia32_psubusb128(byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.psubus.w")
    short8 __builtin_ia32_psubusw128(short8, short8) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.sqrt.pd")
    double2 __builtin_ia32_sqrtpd(double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.sqrt.sd")
    double2 __builtin_ia32_sqrtsd(double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.storel.dq")
    void __builtin_ia32_storelv4si(void*, int4);

pragma(LDC_intrinsic, "llvm.x86.sse2.storeu.dq")
    void __builtin_ia32_storedqu(void*, byte16);

pragma(LDC_intrinsic, "llvm.x86.sse2.storeu.pd")
    void __builtin_ia32_storeupd(void*, double2);

pragma(LDC_intrinsic, "llvm.x86.sse2.sub.sd")
    double2 __builtin_ia32_subsd(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.ucomieq.sd")
    int __builtin_ia32_ucomisdeq(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.ucomige.sd")
    int __builtin_ia32_ucomisdge(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.ucomigt.sd")
    int __builtin_ia32_ucomisdgt(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.ucomile.sd")
    int __builtin_ia32_ucomisdle(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.ucomilt.sd")
    int __builtin_ia32_ucomisdlt(double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse2.ucomineq.sd")
    int __builtin_ia32_ucomisdneq(double2, double2) pure @safe;

+/