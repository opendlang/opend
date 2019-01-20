/**
* Copyright: Copyright Auburn Sounds 2019.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.mmx;

public import inteli.types;
import inteli.internals;

nothrow @nogc:

// Important: you don't need to call _mm_empty when using "MMX" capabilities of intel-intrinsics,
// since it just generates the right IR and cleaning-up FPU registers is up to the codegen.
// intel-intrinsics is just semantics.

__m64 _mm_add_pi16 (__m64 a, __m64 b)
{
    return cast(__m64)(cast(short4)a + cast(short4)b);
}

__m64 _mm_add_pi32 (__m64 a, __m64 b)
{
    return cast(__m64)(cast(int2)a + cast(int2)b);
}

__m64 _mm_add_pi8 (__m64 a, __m64 b)
{
    return cast(__m64)(cast(byte8)a + cast(byte8)b);
}
 
 /+
 unittest
 {
    
 }
__m64 _mm_adds_pi16 (__m64 a, __m64 b)
paddsb
__m64 _mm_adds_pi8 (__m64 a, __m64 b)
paddusw
__m64 _mm_adds_pu16 (__m64 a, __m64 b)
paddusb
__m64 _mm_adds_pu8 (__m64 a, __m64 b)
pand
__m64 _mm_and_si64 (__m64 a, __m64 b)
pandn
__m64 _mm_andnot_si64 (__m64 a, __m64 b)
pcmpeqw
__m64 _mm_cmpeq_pi16 (__m64 a, __m64 b)
pcmpeqd
__m64 _mm_cmpeq_pi32 (__m64 a, __m64 b)
pcmpeqb
__m64 _mm_cmpeq_pi8 (__m64 a, __m64 b)
pcmpgtw
__m64 _mm_cmpgt_pi16 (__m64 a, __m64 b)
pcmpgtd
__m64 _mm_cmpgt_pi32 (__m64 a, __m64 b)
pcmpgtb
__m64 _mm_cmpgt_pi8 (__m64 a, __m64 b)
movq
__int64 _mm_cvtm64_si64 (__m64 a)
movd
__m64 _mm_cvtsi32_si64 (int a)
movq
__m64 _mm_cvtsi64_m64 (__int64 a)
movd
int _mm_cvtsi64_si32 (__m64 a)
emms
void _m_empty (void)
emms
void _mm_empty (void)
movd
__m64 _m_from_int (int a)
movq
__m64 _m_from_int64 (__int64 a)
pmaddwd
__m64 _mm_madd_pi16 (__m64 a, __m64 b)
pmulhw
__m64 _mm_mulhi_pi16 (__m64 a, __m64 b)
pmullw
__m64 _mm_mullo_pi16 (__m64 a, __m64 b)
por
__m64 _mm_or_si64 (__m64 a, __m64 b)
packsswb
__m64 _mm_packs_pi16 (__m64 a, __m64 b)
packssdw
__m64 _mm_packs_pi32 (__m64 a, __m64 b)
packuswb
__m64 _mm_packs_pu16 (__m64 a, __m64 b)
packssdw
__m64 _m_packssdw (__m64 a, __m64 b)
packsswb
__m64 _m_packsswb (__m64 a, __m64 b)
packuswb
__m64 _m_packuswb (__m64 a, __m64 b)
paddb
__m64 _m_paddb (__m64 a, __m64 b)
paddd
__m64 _m_paddd (__m64 a, __m64 b)
paddsb
__m64 _m_paddsb (__m64 a, __m64 b)
paddsw
__m64 _m_paddsw (__m64 a, __m64 b)
paddusb
__m64 _m_paddusb (__m64 a, __m64 b)
paddusw
__m64 _m_paddusw (__m64 a, __m64 b)
paddw
__m64 _m_paddw (__m64 a, __m64 b)
pand
__m64 _m_pand (__m64 a, __m64 b)
pandn
__m64 _m_pandn (__m64 a, __m64 b)
pcmpeqb
__m64 _m_pcmpeqb (__m64 a, __m64 b)
pcmpeqd
__m64 _m_pcmpeqd (__m64 a, __m64 b)
pcmpeqw
__m64 _m_pcmpeqw (__m64 a, __m64 b)
pcmpgtb
__m64 _m_pcmpgtb (__m64 a, __m64 b)
pcmpgtd
__m64 _m_pcmpgtd (__m64 a, __m64 b)
pcmpgtw
__m64 _m_pcmpgtw (__m64 a, __m64 b)
pmaddwd
__m64 _m_pmaddwd (__m64 a, __m64 b)
pmulhw
__m64 _m_pmulhw (__m64 a, __m64 b)
pmullw
__m64 _m_pmullw (__m64 a, __m64 b)
por
__m64 _m_por (__m64 a, __m64 b)
pslld
__m64 _m_pslld (__m64 a, __m64 count)
pslld
__m64 _m_pslldi (__m64 a, int imm8)
psllq
__m64 _m_psllq (__m64 a, __m64 count)
psllq
__m64 _m_psllqi (__m64 a, int imm8)
psllw
__m64 _m_psllw (__m64 a, __m64 count)
psllw
__m64 _m_psllwi (__m64 a, int imm8)
psrad
__m64 _m_psrad (__m64 a, __m64 count)
psrad
__m64 _m_psradi (__m64 a, int imm8)
psraw
__m64 _m_psraw (__m64 a, __m64 count)
psraw
__m64 _m_psrawi (__m64 a, int imm8)
psrld
__m64 _m_psrld (__m64 a, __m64 count)
psrld
__m64 _m_psrldi (__m64 a, int imm8)
psrlq
__m64 _m_psrlq (__m64 a, __m64 count)
psrlq
__m64 _m_psrlqi (__m64 a, int imm8)
psrlw
__m64 _m_psrlw (__m64 a, __m64 count)
psrlw
__m64 _m_psrlwi (__m64 a, int imm8)
psubb
__m64 _m_psubb (__m64 a, __m64 b)
psubd
__m64 _m_psubd (__m64 a, __m64 b)
psubsb
__m64 _m_psubsb (__m64 a, __m64 b)
psubsw
__m64 _m_psubsw (__m64 a, __m64 b)
psubusb
__m64 _m_psubusb (__m64 a, __m64 b)
psubusw
__m64 _m_psubusw (__m64 a, __m64 b)
psubw
__m64 _m_psubw (__m64 a, __m64 b)
punpckhbw
__m64 _m_punpckhbw (__m64 a, __m64 b)
punpckhdq
__m64 _m_punpckhdq (__m64 a, __m64 b)
punpcklbw
__m64 _m_punpckhwd (__m64 a, __m64 b)
punpcklbw
__m64 _m_punpcklbw (__m64 a, __m64 b)
punpckldq
__m64 _m_punpckldq (__m64 a, __m64 b)
punpcklwd
__m64 _m_punpcklwd (__m64 a, __m64 b)
pxor
__m64 _m_pxor (__m64 a, __m64 b)
+/

__m64 _mm_set_pi16 (short e3, short e2, short e1, short e0) pure @trusted
{ 
    short[4] arr = [e0, e1, e2, e3];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    short4 R = cast(short4) _mm_set_pi16(3, 2, 1, 0);
    short[4] correct = [0, 1, 2, 3];
    assert(R.array == correct);
}

__m64 _mm_set_pi32 (int e1, int e0) pure @trusted
{ 
    int[2] arr = [e0, e1];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    int2 R = cast(int2) _mm_set_pi32(1, 0);
    int[2] correct = [0, 1];
    assert(R.array == correct);
}

__m64 _mm_set_pi8 (char e7, char e6, char e5, char e4, char e3, char e2, char e1, char e0) pure @trusted
{ 
    byte[8] arr = [e0, e1, e2, e3, e4, e5, e6, e7];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    byte8 R = cast(byte8) _mm_set_pi8(7, 6, 5, 4, 3, 2, 1, 0);
    byte[8] correct = [0, 1, 2, 3, 4, 5, 6, 7];
    assert(R.array == correct);
}

__m64 _mm_set1_pi16 (short a) pure @trusted
{
    short[4] arr = [a, a, a, a];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    short4 R = cast(short4) _mm_set1_pi16(44);
    short[4] correct = [44, 44, 44, 44];
    assert(R.array == correct);
}

__m64 _mm_set1_pi32 (int a) pure @trusted
{
    int[2] arr = [a, a];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    int2 R = cast(int2) _mm_set1_pi32(43);
    int[2] correct = [43, 43];
    assert(R.array == correct);
}

__m64 _mm_set1_pi8 (byte a) pure @trusted
{
    byte[8] arr = [a, a, a, a, a, a, a, a];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    byte8 R = cast(byte8) _mm_set1_pi8(42);
    byte[8] correct = [42, 42, 42, 42, 42, 42, 42, 42];
    assert(R.array == correct);
}

__m64 _mm_setr_pi16 (short e3, short e2, short e1, short e0) pure @trusted
{ 
    short[4] arr = [e3, e2, e1, e0];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    short4 R = cast(short4) _mm_setr_pi16(0, 1, 2, 3);
    short[4] correct = [0, 1, 2, 3];
    assert(R.array == correct);
}

__m64 _mm_setr_pi32 (int e1, int e0) pure @trusted
{ 
    int[2] arr = [e1, e0];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    int2 R = cast(int2) _mm_setr_pi32(0, 1);
    int[2] correct = [0, 1];
    assert(R.array == correct);
}

__m64 _mm_setr_pi8 (char e7, char e6, char e5, char e4, char e3, char e2, char e1, char e0) pure @trusted
{ 
    byte[8] arr = [e7, e6, e5, e4, e3, e2, e1, e0];
    return *cast(__m64*)(arr.ptr);
}
unittest
{
    byte8 R = cast(byte8) _mm_setr_pi8(0, 1, 2, 3, 4, 5, 6, 7);
    byte[8] correct = [0, 1, 2, 3, 4, 5, 6, 7];
    assert(R.array == correct);
}

__m64 _mm_setzero_si64 () pure @trusted
{
    __m64 r;
    r[0] = 0;
    return r;
}
unittest
{
    __m64 R = _mm_setzero_si64();
    assert(R[0] == 0);
}


/+
__m64 _mm_sll_pi16 (__m64 a, __m64 count)
pslld
__m64 _mm_sll_pi32 (__m64 a, __m64 count)
psllq
__m64 _mm_sll_si64 (__m64 a, __m64 count)
psllw
__m64 _mm_slli_pi16 (__m64 a, int imm8)
pslld
__m64 _mm_slli_pi32 (__m64 a, int imm8)
psllq
__m64 _mm_slli_si64 (__m64 a, int imm8)
psraw
__m64 _mm_sra_pi16 (__m64 a, __m64 count)
psrad
__m64 _mm_sra_pi32 (__m64 a, __m64 count)
psraw
__m64 _mm_srai_pi16 (__m64 a, int imm8)
psrad
__m64 _mm_srai_pi32 (__m64 a, int imm8)
psrlw
__m64 _mm_srl_pi16 (__m64 a, __m64 count)
psrld
__m64 _mm_srl_pi32 (__m64 a, __m64 count)
psrlq
__m64 _mm_srl_si64 (__m64 a, __m64 count)
psrlw
__m64 _mm_srli_pi16 (__m64 a, int imm8)
psrld
__m64 _mm_srli_pi32 (__m64 a, int imm8)
psrlq
__m64 _mm_srli_si64 (__m64 a, int imm8)
psubw
__m64 _mm_sub_pi16 (__m64 a, __m64 b)
psubd
__m64 _mm_sub_pi32 (__m64 a, __m64 b)
psubb
__m64 _mm_sub_pi8 (__m64 a, __m64 b)
psubsw
__m64 _mm_subs_pi16 (__m64 a, __m64 b)
psubsb
__m64 _mm_subs_pi8 (__m64 a, __m64 b)
psubusw
__m64 _mm_subs_pu16 (__m64 a, __m64 b)
psubusb
__m64 _mm_subs_pu8 (__m64 a, __m64 b)
movd
int _m_to_int (__m64 a)
movq
__int64 _m_to_int64 (__m64 a)
punpcklbw
__m64 _mm_unpackhi_pi16 (__m64 a, __m64 b)
punpckhdq
__m64 _mm_unpackhi_pi32 (__m64 a, __m64 b)
punpckhbw
__m64 _mm_unpackhi_pi8 (__m64 a, __m64 b)
punpcklwd
__m64 _mm_unpacklo_pi16 (__m64 a, __m64 b)
punpckldq
__m64 _mm_unpacklo_pi32 (__m64 a, __m64 b)
punpcklbw
__m64 _mm_unpacklo_pi8 (__m64 a, __m64 b)
pxor
__m64 _mm_xor_si64 (__m64 a, __m64 b)

+/

 void _mm_empty()
 {
     // Do nothing, see top comment
 }