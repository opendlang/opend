// Note: this is a godbolt template that can help to new intrinsics
import core.simd;

public import core.math: sqrt; // since it's an intrinsic
version(GNU) import gcc.builtins;
version(LDC) import ldc.simd;
version(LDC) import ldc.intrinsics;
version(LDC) import ldc.gccbuiltins_x86;

/// Unpack and interleave 32-bit integers from the high half of each 128-bit lane in `a` and `b`.
__m256i _mm256_unpackhi_epi32 (__m256i a, __m256i b) pure @trusted
{
    static if (GDC_with_AVX2)
        enum bool split = false;
    else version(GNU)
        enum bool split = true;
    else
        enum bool split = false;

    
    static if (GDC_with_AVX2)
    {
        return cast(long4) __builtin_ia32_punpckhdq256(cast(int8)a, cast(int8)b);
    }
    else static if (LDC_with_optimizations)
    {
        // LDC AVX2: Suprisingly, this start using vunpckhps in LDC 1.31 -O2
        enum ir = `%r = shufflevector <8 x i32> %0, <8 x i32> %1, <8 x i32> <i32 2, i32 10, i32 3, i32 11, i32 6, i32 14, i32 7, i32 15>
            ret <8 x i32> %r`;
        return cast(__m256i)LDCInlineIR!(ir, int8, int8, int8)(cast(int8)a, cast(int8)b);
    }
    else static if (split)
    {
        __m128i a_lo = _mm256_extractf128_si256!0(a);
        __m128i a_hi = _mm256_extractf128_si256!1(a);
        __m128i b_lo = _mm256_extractf128_si256!0(b);
        __m128i b_hi = _mm256_extractf128_si256!1(b);
        __m128i r_lo = _mm_unpackhi_epi32(a_lo, b_lo);
        __m128i r_hi = _mm_unpackhi_epi32(a_hi, b_hi);
        return _mm256_set_m128i(r_hi, r_lo);
    }
    else
    {
        int8 R;
        int8 ai = cast(int8)a;
        int8 bi = cast(int8)b;
        R.ptr[0] = ai.array[2];
        R.ptr[1] = bi.array[2];
        R.ptr[2] = ai.array[3];
        R.ptr[3] = bi.array[3];
        R.ptr[4] = ai.array[6];
        R.ptr[5] = bi.array[6];
        R.ptr[6] = ai.array[7];
        R.ptr[7] = bi.array[7];
        return cast(__m256i) R;
    }
}

__m128i _mm_unpackhi_epi32 (__m128i a, __m128i b) pure @trusted
{
    static if (GDC_with_SSE2)
    {
        return __builtin_ia32_punpckhdq128(a, b);
    }
    else static if (LDC_with_optimizations)
    {
        enum ir = `%r = shufflevector <4 x i32> %0, <4 x i32> %1, <4 x i32> <i32 2, i32 6, i32 3, i32 7>
                   ret <4 x i32> %r`;
        return LDCInlineIR!(ir, int4, int4, int4)(cast(int4)a, cast(int4)b);
    }
    else
    {
        __m128i r = void;
        r.ptr[0] = a.array[2];
        r.ptr[1] = b.array[2];
        r.ptr[2] = a.array[3];
        r.ptr[3] = b.array[3];
        return r;
    }
}



version(GNU)
{
    enum MMXSizedVectorsAreEmulated = false;
    enum SSESizedVectorsAreEmulated = false;

    enum GDC_with_MMX = true;
    
    static if (!is(Vector!(float[8])))
    {
        enum AVXSizedVectorsAreEmulated = true;
        struct float8
        {
            float[8] array;
            alias ptr = array;
        }
    }
    else
    {
        enum AVXSizedVectorsAreEmulated = false;
    }

    static if (!is(Vector!(double[4])))
    {
        struct double4
        {
            double[4] array;
            alias ptr = array;
        }
    }
    static if (!is(Vector!(long[4])))
    {
        struct long4
        {
            long[4] array;
            alias ptr = array;
        }
    }
    static if (!is(Vector!(short[16])))
    {
        struct short16
        {
            short[16] array;
            alias ptr = array;
        }
    }

     static if (!is(Vector!(int[8])))
    {
        struct int8
        {
            int[8] array;
            alias ptr = array;
        }
    }

     static if (!is(Vector!(byte[32])))
    {
        struct byte32
        {
            byte[32] array;
            alias ptr = array;
        }
    }
}
else
{
    enum GDC_with_MMX = false;
}


version(DigitalMars)
{
    version(D_SIMD)
    {
        version(D_AVX2)
        {

        }
        else
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
        }
    }
    else
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
    alias Vector!(long [1]) long1;
    alias Vector!(float[2]) float2;
    alias Vector!(int  [2]) int2;
    alias Vector!(short[4]) short4;
    alias Vector!(byte [8]) byte8;

    enum MMXSizedVectorsAreEmulated = false;
    enum SSESizedVectorsAreEmulated = false;
    enum AVXSizedVectorsAreEmulated = false;
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
    version(ARM)
    {
        enum LDC_with_ARM32 = true;
    }
    else
        enum LDC_with_ARM32 = false;



    enum LDC_with_SSE   = __traits(targetHasFeature, "sse");
    enum LDC_with_SSE2  = __traits(targetHasFeature, "sse2");
    enum LDC_with_SSE3  = __traits(targetHasFeature, "sse3");
    enum LDC_with_SSSE3 = __traits(targetHasFeature, "ssse3");
    enum LDC_with_AVX   = __traits(targetHasFeature, "avx");
    enum LDC_with_AVX2  = __traits(targetHasFeature, "avx2");
    
    enum LDC_with_ARM64 = __traits(targetHasFeature, "neon");
    enum LDC_with_SSE41 = __traits(targetHasFeature, "sse4.1");
    enum LDC_with_SSE42 = __traits(targetHasFeature, "sse4.2");
    alias shufflevectorLDC = shufflevector;
}
else
{
    enum LDC_with_SSE = false;
    enum LDC_with_SSE2 = false;
    enum LDC_with_SSE3 = false;
    enum LDC_with_SSSE3 = false;
    enum LDC_with_AVX = false;
    enum LDC_with_AVX2 = false;
    
    enum LDC_with_ARM32 = false;
    enum LDC_with_ARM64 = false;
    
    enum LDC_with_SSE41 = false;
    enum LDC_with_SSE42 = false;
}

enum LDC_with_ARM = LDC_with_ARM32 | LDC_with_ARM64;

version(GNU)
{
    static if (__VERSION__ >= 2100) // Starting at GDC 12.1
    {
        enum GDC_with_AVX2 = __traits(compiles, __builtin_ia32_mpsadbw256);
        enum GDC_with_AVX = __traits(compiles, __builtin_ia32_vbroadcastf128_pd256);        
        enum GDC_with_SSE2 = true;
        enum GDC_with_SSE = true;
        enum GDC_with_SSE41 = __traits(compiles, __builtin_ia32_blendps);
        enum GDC_with_SSE42 = __traits(compiles, __builtin_ia32_pcmpgtq);
        enum GDC_with_SSSE3 = __traits(compiles, __builtin_ia32_pshufb128);
    }
    else
    {
        enum GDC_with_SSE = false;
        enum GDC_with_SSE2 = false;
        enum GDC_with_AVX = false;
        enum GDC_with_AVX2 = false;
        enum GDC_with_SSE41 = false;
        enum GDC_with_SSE42 = false;
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
    enum GDC_with_SSE42 = false;
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

version(LDC)
{
    static if (__VERSION__ >= 2097) // LDC 1.27+
    {
        pragma(LDC_intrinsic, "llvm.abs.i#")
            T inteli_llvm_abs(T)(T val, bool attrib);
    }

    static if (__VERSION__ >= 2092) // LDC 1.22+
    {
        pragma(LDC_intrinsic, "llvm.sadd.sat.i#")
            T inteli_llvm_adds(T)(T a, T b) pure @safe;
        pragma(LDC_intrinsic, "llvm.ssub.sat.i#")
            T inteli_llvm_subs(T)(T a, T b) pure @safe;
        pragma(LDC_intrinsic, "llvm.uadd.sat.i#")
            T inteli_llvm_addus(T)(T a, T b) pure @safe;
        pragma(LDC_intrinsic, "llvm.usub.sat.i#")
            T inteli_llvm_subus(T)(T a, T b) pure @safe;
    }
}

static if (__VERSION__ >= 2102)
{
    enum SIMD_COMPARISON_MASKS_8B  = !MMXSizedVectorsAreEmulated; // can do < <= => > with builtin 8 bytes __vectors.
    enum SIMD_COMPARISON_MASKS_16B = !SSESizedVectorsAreEmulated; // can do < <= => > with builtin 16 bytes __vectors.
    enum SIMD_COMPARISON_MASKS_32B = !AVXSizedVectorsAreEmulated; // can do < <= => > with builtin 32 bytes __vectors.
}
else
{
    enum SIMD_COMPARISON_MASKS_8B = false;
    enum SIMD_COMPARISON_MASKS_16B = false;
    enum SIMD_COMPARISON_MASKS_32B = false;
}

version(LDC)
{
    version(D_Optimized)
    {
        enum bool LDC_with_optimizations = true;
    }
    else
    {
        enum bool LDC_with_optimizations = false;
    }
}
else
{
    enum bool LDC_with_optimizations = false;
}

__m128i _mm256_extractf128_si256(ubyte imm8)(__m256i a) pure @trusted
{
    version(GNU) pragma(inline, true); // else GDC has trouble inlining this

    // PERF DMD
    static if (GDC_with_AVX)
    {
        // Note: if it weren't for this GDC intrinsic, _mm256_extractf128_si256
        // could be a non-template, however, this wins in -O0.
        // Same story for _mm256_extractf128_ps and _mm256_extractf128_pd
        return __builtin_ia32_vextractf128_si256(cast(int8)a, imm8 & 1);
    }
    else
    {
        long2 r = void;
        enum int index = 2*(imm8 & 1);
        r.ptr[0] = a.array[index+0];
        r.ptr[1] = a.array[index+1];
        return cast(__m128i)r;
    }
}

__m256i _mm256_set_m128i (__m128i hi, __m128i lo) pure @trusted
{
    // DMD PERF
    static if (GDC_with_AVX)
    {
        __m256i r = cast(long4) __builtin_ia32_si256_si (lo);
        return cast(long4) __builtin_ia32_vinsertf128_si256(cast(int8)r, hi, 1);
    }
    else
    {
        int8 r = void;
        r.ptr[0] = lo.array[0];
        r.ptr[1] = lo.array[1];
        r.ptr[2] = lo.array[2];
        r.ptr[3] = lo.array[3];
        r.ptr[4] = hi.array[0];
        r.ptr[5] = hi.array[1];
        r.ptr[6] = hi.array[2];
        r.ptr[7] = hi.array[3];
        return cast(long4)r;
    }
}