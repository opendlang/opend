// Note: this is a godbolt template that can help to new intrinsics
import core.simd;

public import core.math: sqrt; // since it's an intrinsic
version(GNU) import gcc.builtins;
version(LDC) import ldc.simd;
version(LDC) import ldc.intrinsics;
version(LDC) import ldc.gccbuiltins_x86;

__m256i _mm256_cvtepi16_epi64 (__m128i a) pure @trusted
{
    static if (GDC_with_AVX2)
    {
        return cast(__m256i) __builtin_ia32_pmovsxwq256(cast(short8)a);
    }
    else version(LDC)
    {
        enum ir = `
            %v = shufflevector <8 x i16> %0,<8 x i16> %0, <4 x i32> <i32 0, i32 1,i32 2, i32 3>
            %r = sext <4 x i16> %v to <4 x i64>
            ret <4 x i64> %r`;
        return cast(__m256i) LDCInlineIR!(ir, long4, short8)(cast(short8)a);
    }
    else
    {
        // LDC x86 generates vpmovsxwq since LDC 1.12 -O1
        short8 sa = cast(short8)a;
        long4 r;
        r.ptr[0] = sa.array[0];
        r.ptr[1] = sa.array[1];
        r.ptr[2] = sa.array[2];
        r.ptr[3] = sa.array[3];
        return cast(__m256i)r;
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



    enum LDC_with_SSE = __traits(targetHasFeature, "sse");
    enum LDC_with_SSE2 = __traits(targetHasFeature, "sse2");
    enum LDC_with_SSSE3 = __traits(targetHasFeature, "ssse3");
    enum LDC_with_AVX = __traits(targetHasFeature, "avx");
    enum LDC_with_AVX2 = __traits(targetHasFeature, "avx2");
    
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
    enum LDC_with_ARM32 = false;
    enum LDC_with_ARM64 = false;
    enum LDC_with_SSSE3 = false;
    enum LDC_with_SSE41 = false;
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