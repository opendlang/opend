// Note: this is a godbolt template that can help to new intrinsics
import core.simd;

version(GNU) import gcc.builtins;
version(LDC) import ldc.simd;
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


alias __m128i = int4;
alias __m128 = float4;
alias __m128d = double2;

version(LDC)
{
    enum LDC_with_SSE41 = __traits(targetHasFeature, "sse4.1");
    enum LDC_with_ARM64 = __traits(targetHasFeature, "neon");
}
else
{
    enum LDC_with_SSE41 = false;
    enum LDC_with_ARM64 = false;
}

version(GNU)
{
    enum GDC_with_SSE41 = true;
}
else
{
    enum GDC_with_SSE41 = false;
}

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