// Note: this is a godbolt template that can help to new intrinsics
import core.simd;

public import core.math: sqrt; // since it's an intrinsic
version(GNU) import gcc.builtins;
version(LDC) import ldc.simd;
version(LDC) import ldc.intrinsics;
version(LDC) import ldc.gccbuiltins_x86;

// <your code here>

__m128i _mm_strange_intrinsic (__m128i a) pure @safe
{
    return a;
}

// </your code here>

// Useful links for your efforts:
// - intel intrinsics guide: https://software.intel.com/sites/landingpage/IntrinsicsGuide/
// - arm intrinsics guide: https://developer.arm.com/architectures/instruction-sets/intrinsics/
// - clang headers: https://github.com/llvm/llvm-project/tree/main/clang/lib/Headers
// - LLVM 12 intrinsics list for x86: https://github.com/llvm/llvm-project-staging/blob/staging/apple/llvm/include/llvm/IR/IntrinsicsX86.td
// - LLVM 12 intrinsics list for arm: https://github.com/llvm/llvm-project-staging/blob/staging/apple/llvm/include/llvm/IR/IntrinsicsAArch64.td

version(DigitalMars)
{
    struct double4
    {
        double[4] array;
        alias ptr = array;
    }

    struct float8
    {
        float[8] array;
        alias ptr = array;
    }

    struct long4
    {
        long[4] array;
        alias ptr = array;
    }
    

    struct long1
    {
        long[1] array;
        alias ptr = array;
    }

    struct short4
    {
        short[4] array;
        alias ptr = array;
    }

    struct int2
    {
        int[2] array;
        alias ptr = array;
    }

    version(D_SIMD)
    {
        enum DMD_with_DSIMD = true;
    }
    else
        enum DMD_with_DSIMD = false;
}
else
    enum DMD_with_DSIMD = false;

enum DMD_with_32bit_asm = false;

version(LDC)
{
    alias long1 = __vector(long[1]);
}

alias __m64 = long1;
alias __m128i = int4;
alias __m128 = float4;
alias __m128d = double2;

alias __m256 = float8;
alias __m256d = double4;
alias __m256i = long4;



version(LDC)
{
    enum LDC_with_SSE = __traits(targetHasFeature, "sse");
    enum LDC_with_SSE2 = __traits(targetHasFeature, "sse2");
    enum LDC_with_SSSE3 = __traits(targetHasFeature, "ssse3");
    enum LDC_with_AVX = __traits(targetHasFeature, "avx");
    enum LDC_with_AVX2 = __traits(targetHasFeature, "avx");
    enum LDC_with_ARM64 = __traits(targetHasFeature, "neon");
    enum LDC_with_SSE41 = __traits(targetHasFeature, "sse4.1");
    alias shufflevectorLDC = shufflevector;
}
else
{
    enum LDC_with_SSE = false;
    enum LDC_with_SSE2 = false;
    enum LDC_with_AVX = false;
    enum LDC_with_AVX2 = false;
    enum LDC_with_ARM64 = false;
    enum LDC_with_SSSE3 = false;
    enum LDC_with_SSE41 = false;
}

version(GNU)
{
    static if (__VERSION__ >= 2100) // Starting at GDC 12.1
    {
        enum GDC_with_AVX2 = __traits(compiles, __builtin_ia32_broadcastmb128);
        enum GDC_with_AVX = __traits(compiles, __builtin_ia32_vbroadcastf128_pd256);
        enum GDC_with_SSE2 = true;
        enum GDC_with_SSE = true;
        enum GDC_with_SSE41 = false;
        enum GDC_with_SSSE3 = __traits(compiles, __builtin_ia32_pshufb128);
    }
    else
    {
        enum GDC_with_SSE = false;
        enum GDC_with_SSE2 = false;
        enum GDC_with_AVX = false;
        enum GDC_with_AVX2 = false;
        enum GDC_with_SSE41 = false;
        enum GDC_with_SSSE3 = false;
    }
}
else
{
    enum GDC_with_SSE = false;
    enum GDC_with_SSE2 = false;
    enum GDC_with_AVX = false;
    enum GDC_with_AVX2 = false;
    enum GDC_with_SSE41 = false;
    enum GDC_with_SSSE3 = false;
}
enum GDC_or_LDC_with_AVX = LDC_with_AVX || GDC_with_AVX;
enum GDC_or_LDC_with_AVX2 = LDC_with_AVX2 || GDC_with_AVX2;


version(LDC)
{
    // Since LDC 1.13, using the new ldc.llvmasm.__ir variants instead of inlineIR
    static if (__VERSION__ >= 2083)
    {
         import ldc.llvmasm;
         alias LDCInlineIR = __ir_pure;

         // A version of inline IR with prefix/suffix didn't exist before LDC 1.13
         alias LDCInlineIREx = __irEx_pure; 
    }
    else
    {
        alias LDCInlineIR = inlineIR;
    }
}