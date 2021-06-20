/**
* SSE4.1 intrinsics.
*
* Copyright: Guillaume Piolat 2021.
*            Johan Engelen 2021.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.smmintrin;

// SSE4.1 instructions
// https://software.intel.com/sites/landingpage/IntrinsicsGuide/#techs=SSE4_1
// Note: this header will work whether you have SSE4.1 enabled or not.
// With LDC, use "dflags-ldc": ["-mattr=+sse4.1"] or equivalent to actively
// generate SSE4.1 instructions.

public import inteli.types;
import inteli.internals;

// smmintrin pulls in all previous instruction set intrinsics.
public import inteli.tmmintrin;

nothrow @nogc:

enum int _MM_FROUND_TO_NEAREST_INT = 0x00; /// SSE4.1 rounding modes
enum int _MM_FROUND_TO_NEG_INF     = 0x01; /// ditto
enum int _MM_FROUND_TO_POS_INF     = 0x02; /// ditto
enum int _MM_FROUND_TO_ZERO        = 0x03; /// ditto
enum int _MM_FROUND_CUR_DIRECTION  = 0x04; /// ditto
enum int _MM_FROUND_RAISE_EXC      = 0x00; /// ditto
enum int _MM_FROUND_NO_EXC         = 0x08; /// ditto

enum int _MM_FROUND_NINT      = (_MM_FROUND_RAISE_EXC | _MM_FROUND_TO_NEAREST_INT);
enum int _MM_FROUND_FLOOR     = (_MM_FROUND_RAISE_EXC | _MM_FROUND_TO_NEG_INF);
enum int _MM_FROUND_CEIL      = (_MM_FROUND_RAISE_EXC | _MM_FROUND_TO_POS_INF);
enum int _MM_FROUND_TRUNC     = (_MM_FROUND_RAISE_EXC | _MM_FROUND_TO_ZERO);
enum int _MM_FROUND_RINT      = (_MM_FROUND_RAISE_EXC | _MM_FROUND_CUR_DIRECTION);
enum int _MM_FROUND_NEARBYINT = (_MM_FROUND_NO_EXC    | _MM_FROUND_CUR_DIRECTION);

/*
/// Blend packed 16-bit integers from a and b using control mask imm8, and store the results in dst.
__m128i _mm_blend_epi16 (__m128i a, __m128i b, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Blend packed double-precision (64-bit) floating-point elements from a and b using control mask imm8, and store the results in dst.
__m128d _mm_blend_pd (__m128d a, __m128d b, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Blend packed single-precision (32-bit) floating-point elements from a and b using control mask imm8, and store the results in dst.
__m128 _mm_blend_ps (__m128 a, __m128 b, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Blend packed 8-bit integers from a and b using mask, and store the results in dst.
__m128i _mm_blendv_epi8 (__m128i a, __m128i b, __m128i mask) @trusted
{
}
unittest
{
}
*/

/*
/// Blend packed double-precision (64-bit) floating-point elements from a and b using mask, and store the results in dst.
__m128d _mm_blendv_pd (__m128d a, __m128d b, __m128d mask) @trusted
{
}
unittest
{
}
*/

/*
/// Blend packed single-precision (32-bit) floating-point elements from a and b using mask, and store the results in dst.
__m128 _mm_blendv_ps (__m128 a, __m128 b, __m128 mask) @trusted
{
}
unittest
{
}
*/

/*
/// Round the packed double-precision (64-bit) floating-point elements in a up to an integer value, and store the results as packed double-precision floating-point elements in dst.
__m128d _mm_ceil_pd (__m128d a) @trusted
{
}
unittest
{
}
*/

/*
/// Round the packed single-precision (32-bit) floating-point elements in a up to an integer value, and store the results as packed single-precision floating-point elements in dst.
__m128 _mm_ceil_ps (__m128 a) @trusted
{
}
unittest
{
}
*/

/*
/// Round the lower double-precision (64-bit) floating-point element in b up to an integer value, store the result as a double-precision floating-point element in the lower element of dst, and copy the upper element from a to the upper element of dst.
__m128d _mm_ceil_sd (__m128d a, __m128d b) @trusted
{
}
unittest
{
}
*/

/*
/// Round the lower single-precision (32-bit) floating-point element in b up to an integer value, store the result as a single-precision floating-point element in the lower element of dst, and copy the upper 3 packed elements from a to the upper elements of dst.
__m128 _mm_ceil_ss (__m128 a, __m128 b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed 64-bit integers in a and b for equality, and store the results in dst.
__m128i _mm_cmpeq_epi64 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Sign extend packed 16-bit integers in a to packed 32-bit integers, and store the results in dst.
__m128i _mm_cvtepi16_epi32 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Sign extend packed 16-bit integers in a to packed 64-bit integers, and store the results in dst.
__m128i _mm_cvtepi16_epi64 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Sign extend packed 32-bit integers in a to packed 64-bit integers, and store the results in dst.
__m128i _mm_cvtepi32_epi64 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Sign extend packed 8-bit integers in a to packed 16-bit integers, and store the results in dst.
__m128i _mm_cvtepi8_epi16 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Sign extend packed 8-bit integers in a to packed 32-bit integers, and store the results in dst.
__m128i _mm_cvtepi8_epi32 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Sign extend packed 8-bit integers in the low 8 bytes of a to packed 64-bit integers, and store the results in dst.
__m128i _mm_cvtepi8_epi64 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Zero extend packed unsigned 16-bit integers in a to packed 32-bit integers, and store the results in dst.
__m128i _mm_cvtepu16_epi32 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Zero extend packed unsigned 16-bit integers in a to packed 64-bit integers, and store the results in dst.
__m128i _mm_cvtepu16_epi64 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Zero extend packed unsigned 32-bit integers in a to packed 64-bit integers, and store the results in dst.
__m128i _mm_cvtepu32_epi64 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Zero extend packed unsigned 8-bit integers in a to packed 16-bit integers, and store the results in dst.
__m128i _mm_cvtepu8_epi16 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Zero extend packed unsigned 8-bit integers in a to packed 32-bit integers, and store the results in dst.
__m128i _mm_cvtepu8_epi32 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Zero extend packed unsigned 8-bit integers in the low 8 byte sof a to packed 64-bit integers, and store the results in dst.
__m128i _mm_cvtepu8_epi64 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Conditionally multiply the packed double-precision (64-bit) floating-point elements in a and b using the high 4 bits in imm8, sum the four products, and conditionally store the sum in dst using the low 4 bits of imm8.
__m128d _mm_dp_pd (__m128d a, __m128d b, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Conditionally multiply the packed single-precision (32-bit) floating-point elements in a and b using the high 4 bits in imm8, sum the four products, and conditionally store the sum in dst using the low 4 bits of imm8.
__m128 _mm_dp_ps (__m128 a, __m128 b, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Extract a 32-bit integer from a, selected with imm8, and store the result in dst.
int _mm_extract_epi32 (__m128i a, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Extract a 64-bit integer from a, selected with imm8, and store the result in dst.
__int64 _mm_extract_epi64 (__m128i a, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Extract an 8-bit integer from a, selected with imm8, and store the result in the lower element of dst.
int _mm_extract_epi8 (__m128i a, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Extract a single-precision (32-bit) floating-point element from a, selected with imm8, and store the result in dst.
int _mm_extract_ps (__m128 a, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Round the packed double-precision (64-bit) floating-point elements in a down to an integer value, and store the results as packed double-precision floating-point elements in dst.
__m128d _mm_floor_pd (__m128d a) @trusted
{
}
unittest
{
}
*/

/*
/// Round the packed single-precision (32-bit) floating-point elements in a down to an integer value, and store the results as packed single-precision floating-point elements in dst.
__m128 _mm_floor_ps (__m128 a) @trusted
{
}
unittest
{
}
*/

/*
/// Round the lower double-precision (64-bit) floating-point element in b down to an integer value, store the result as a double-precision floating-point element in the lower element of dst, and copy the upper element from a to the upper element of dst.
__m128d _mm_floor_sd (__m128d a, __m128d b) @trusted
{
}
unittest
{
}
*/

/*
/// Round the lower single-precision (32-bit) floating-point element in b down to an integer value, store the result as a single-precision floating-point element in the lower element of dst, and copy the upper 3 packed elements from a to the upper elements of dst.
__m128 _mm_floor_ss (__m128 a, __m128 b) @trusted
{
}
unittest
{
}
*/

/*
/// Copy a to dst, and insert the 32-bit integer i into dst at the location specified by imm8.
__m128i _mm_insert_epi32 (__m128i a, int i, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Copy a to dst, and insert the 64-bit integer i into dst at the location specified by imm8.
__m128i _mm_insert_epi64 (__m128i a, __int64 i, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Copy a to dst, and insert the lower 8-bit integer from i into dst at the location specified by imm8.
__m128i _mm_insert_epi8 (__m128i a, int i, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Copy a to tmp, then insert a single-precision (32-bit) floating-point element from b into tmp using the control in imm8. Store tmp to dst using the mask in imm8 (elements are zeroed out when the corresponding bit is set).
__m128 _mm_insert_ps (__m128 a, __m128 b, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed signed 32-bit integers in a and b, and store packed maximum values in dst.
__m128i _mm_max_epi32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed signed 8-bit integers in a and b, and store packed maximum values in dst.
__m128i _mm_max_epi8 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed unsigned 16-bit integers in a and b, and store packed maximum values in dst.
__m128i _mm_max_epu16 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed unsigned 32-bit integers in a and b, and store packed maximum values in dst.
__m128i _mm_max_epu32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed signed 32-bit integers in a and b, and store packed minimum values in dst.
__m128i _mm_min_epi32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed signed 8-bit integers in a and b, and store packed minimum values in dst.
__m128i _mm_min_epi8 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed unsigned 16-bit integers in a and b, and store packed minimum values in dst.
__m128i _mm_min_epu16 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compare packed unsigned 32-bit integers in a and b, and store packed minimum values in dst.
__m128i _mm_min_epu32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Horizontally compute the minimum amongst the packed unsigned 16-bit integers in a, store the minimum and index in dst, and zero the remaining bits in dst.
__m128i _mm_minpos_epu16 (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the sum of absolute differences (SADs) of quadruplets of unsigned 8-bit integers in a compared to those in b, and store the 16-bit results in dst. Eight SADs are performed using one quadruplet from b and eight quadruplets from a. One quadruplet is selected from b starting at on the offset specified in imm8. Eight quadruplets are formed from sequential 8-bit integers selected from a starting at the offset specified in imm8.
__m128i _mm_mpsadbw_epu8 (__m128i a, __m128i b, const int imm8) @trusted
{
}
unittest
{
}
*/

/*
/// Multiply the low signed 32-bit integers from each packed 64-bit element in a and b, and store the signed 64-bit results in dst.
__m128i _mm_mul_epi32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Multiply the packed 32-bit integers in a and b, producing intermediate 64-bit integers, and store the low 32 bits of the intermediate integers in dst.
__m128i _mm_mullo_epi32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Convert packed signed 32-bit integers from a and b to packed 16-bit integers using unsigned saturation, and store the results in dst.
__m128i _mm_packus_epi32 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/// Round the packed double-precision (64-bit) floating-point elements in a using the rounding parameter, and store the results as packed double-precision floating-point elements in dst.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
/*
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128d _mm_round_pd (__m128d a, int rounding) @trusted
{
}
unittest
{
}
*/

/// Round the packed single-precision (32-bit) floating-point elements in a using the rounding parameter, and store the results as packed single-precision floating-point elements in dst.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
/*
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128 _mm_round_ps (__m128 a, int rounding) @trusted
{
}
unittest
{
}
*/

/// Round the lower double-precision (64-bit) floating-point element in b using the rounding parameter, store the result as a double-precision floating-point element in the lower element of dst, and copy the upper element from a to the upper element of dst.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
/*
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128d _mm_round_sd (__m128d a, __m128d b, int rounding) @trusted
{
}
unittest
{
}
*/

/// Round the lower single-precision (32-bit) floating-point element in b using the rounding parameter, store the result as a single-precision floating-point element in the lower element of dst, and copy the upper 3 packed elements from a to the upper elements of dst.
/// Rounding is done according to the rounding[3:0] parameter, which can be one of:
///    (_MM_FROUND_TO_NEAREST_INT |_MM_FROUND_NO_EXC) // round to nearest, and suppress exceptions
///    (_MM_FROUND_TO_NEG_INF |_MM_FROUND_NO_EXC)     // round down, and suppress exceptions
///    (_MM_FROUND_TO_POS_INF |_MM_FROUND_NO_EXC)     // round up, and suppress exceptions
///    (_MM_FROUND_TO_ZERO |_MM_FROUND_NO_EXC)        // truncate, and suppress exceptions
/*
///    _MM_FROUND_CUR_DIRECTION // use MXCSR.RC; see _MM_SET_ROUNDING_MODE
__m128 _mm_round_ss (__m128 a, __m128 b, int rounding) @trusted
{
}
unittest
{
}
*/

/*
/// Load 128-bits of integer data from memory into dst using a non-temporal memory hint. mem_addr must be aligned on a 16-byte boundary or a general-protection exception may be generated.
__m128i _mm_stream_load_si128 (__m128i * mem_addr) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise NOT of a and then AND with a 128-bit vector containing all 1's, and return 1 if the result is zero, otherwise return 0.
int _mm_test_all_ones (__m128i a) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise AND of 128 bits (representing integer data) in a and mask, and return 1 if the result is zero, otherwise return 0.
int _mm_test_all_zeros (__m128i a, __m128i mask) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise AND of 128 bits (representing integer data) in a and mask, and set ZF to 1 if the result is zero, otherwise set ZF to 0. Compute the bitwise NOT of a and then AND with mask, and set CF to 1 if the result is zero, otherwise set CF to 0. Return 1 if both the ZF and CF values are zero, otherwise return 0.
int _mm_test_mix_ones_zeros (__m128i a, __m128i mask) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise AND of 128 bits (representing integer data) in a and b, and set ZF to 1 if the result is zero, otherwise set ZF to 0. Compute the bitwise NOT of a and then AND with b, and set CF to 1 if the result is zero, otherwise set CF to 0. Return the CF value.
int _mm_testc_si128 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise AND of 128 bits (representing integer data) in a and b, and set ZF to 1 if the result is zero, otherwise set ZF to 0. Compute the bitwise NOT of a and then AND with b, and set CF to 1 if the result is zero, otherwise set CF to 0. Return 1 if both the ZF and CF values are zero, otherwise return 0.
int _mm_testnzc_si128 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/

/*
/// Compute the bitwise AND of 128 bits (representing integer data) in a and b, and set ZF to 1 if the result is zero, otherwise set ZF to 0. Compute the bitwise NOT of a and then AND with b, and set CF to 1 if the result is zero, otherwise set CF to 0. Return the ZF value.
int _mm_testz_si128 (__m128i a, __m128i b) @trusted
{
}
unittest
{
}
*/


// LDC intrinsics present from 1.0.0 to 

/*

pragma(LDC_intrinsic, "llvm.x86.sse41.blendvpd")
    double2 __builtin_ia32_blendvpd(double2, double2, double2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.blendvps")
    float4 __builtin_ia32_blendvps(float4, float4, float4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.dppd")
    double2 __builtin_ia32_dppd(double2, double2, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.dpps")
    float4 __builtin_ia32_dpps(float4, float4, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.insertps")
    float4 __builtin_ia32_insertps128(float4, float4, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.mpsadbw")
    short8 __builtin_ia32_mpsadbw128(byte16, byte16, byte) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.packusdw")
    short8 __builtin_ia32_packusdw128(int4, int4) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.pblendvb")
    byte16 __builtin_ia32_pblendvb128(byte16, byte16, byte16) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.phminposuw")
    short8 __builtin_ia32_phminposuw128(short8) pure @safe;


pragma(LDC_intrinsic, "llvm.x86.sse41.ptestc")
    int __builtin_ia32_ptestc128(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.ptestnzc")
    int __builtin_ia32_ptestnzc128(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.ptestz")
    int __builtin_ia32_ptestz128(long2, long2) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.round.pd")
    double2 __builtin_ia32_roundpd(double2, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.round.ps")
    float4 __builtin_ia32_roundps(float4, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.round.sd")
    double2 __builtin_ia32_roundsd(double2, double2, int) pure @safe;

pragma(LDC_intrinsic, "llvm.x86.sse41.round.ss")
    float4 __builtin_ia32_roundss(float4, float4, int) pure @safe;

    */