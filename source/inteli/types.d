/**
* `core.simd` emulation layer.
*
* Copyright: Copyright Guillaume Piolat 2016-2020, Stefanos Baziotis 2019.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli.types;


pure:
nothrow:
@nogc:

version(GNU)
{
    // Note: for GDC support, be sure to use https://explore.dgnu.org/

    // Future: just detect vectors, do not base upon arch.

    version(X86_64)
    {
        enum MMXSizedVectorsAreEmulated = false;
        enum SSESizedVectorsAreEmulated = false;

        // Does GDC support AVX-sized vectors?
        static if (__VERSION__ >= 2100) // Starting at GDC 12.1 only.
        {
            enum AVXSizedVectorsAreEmulated = !(is(__vector(double[4]))); 
        }
        else
        {
            enum AVXSizedVectorsAreEmulated = true;
        }

        import gcc.builtins;
    }
    else
    {
        enum MMXSizedVectorsAreEmulated = true;
        enum SSESizedVectorsAreEmulated = true;
        enum AVXSizedVectorsAreEmulated = true;
    }
}
else version(LDC)
{
    public import ldc.simd;

    // Use this alias to mention it should only be used with LDC,
    // for example when emulated shufflevector would just be wasteful.
    alias shufflevectorLDC = shufflevector;

    enum MMXSizedVectorsAreEmulated = false;
    enum SSESizedVectorsAreEmulated = false;
    enum AVXSizedVectorsAreEmulated = false;
}
else version(DigitalMars)
{
    public import core.simd;

    static if (__VERSION__ >= 2100)
    {
        // Note: turning this true is very desirable for DMD performance,
        // but also leads to many bugs being discovered upstream.
        // The fact that it works at all relies on many workardounds.
        // In particular intel-intrinsics with this "on" is a honeypot for DMD backend bugs,
        // and a very strong DMD codegen test suite.
        // What happens typically is that contributors end up on a DMD bug in their PR.
        // But finally, in 2022 D_SIMD has been activated, at least for SSE and some instructions.
        enum bool tryToEnableCoreSimdWithDMD = true;
    }
    else
    {
        enum bool tryToEnableCoreSimdWithDMD = false;
    }

    version(D_SIMD)
    {
        enum MMXSizedVectorsAreEmulated = true;
        enum SSESizedVectorsAreEmulated = !tryToEnableCoreSimdWithDMD;

        // Note: with DMD, AVX-sized vectors can't be enabled yet.
        // On linux + x86_64, this will fail since a few operands seem to be missing. 
        // FUTURE: enable AVX-sized vectors in DMD. :)
        version(D_AVX)
            enum AVXSizedVectorsAreEmulated = true;
        else
            enum AVXSizedVectorsAreEmulated = true;
    }
    else
    {
        // Some DMD 32-bit targets don't have D_SIMD
        enum MMXSizedVectorsAreEmulated = true;
        enum SSESizedVectorsAreEmulated = true;
        enum AVXSizedVectorsAreEmulated = true;
    }
}

enum CoreSimdIsEmulated = MMXSizedVectorsAreEmulated || SSESizedVectorsAreEmulated || AVXSizedVectorsAreEmulated;

static if (CoreSimdIsEmulated)
{
    // core.simd is emulated in some capacity: introduce `VectorOps`

    mixin template VectorOps(VectorType, ArrayType: BaseType[N], BaseType, size_t N)
    {
        enum Count = N;
        alias Base = BaseType;

        BaseType* ptr() return pure nothrow @nogc
        {
            return array.ptr;
        }

        // Unary operators
        VectorType opUnary(string op)() pure nothrow @safe @nogc
        {
            VectorType res = void;
            mixin("res.array[] = " ~ op ~ "array[];");
            return res;
        }

        // Binary operators
        VectorType opBinary(string op)(VectorType other) pure const nothrow @safe @nogc
        {
            VectorType res = void;
            mixin("res.array[] = array[] " ~ op ~ " other.array[];");
            return res;
        }

        // Assigning a BaseType value
        void opAssign(BaseType e) pure nothrow @safe @nogc
        {
            array[] = e;
        }

        // Assigning a static array
        void opAssign(ArrayType v) pure nothrow @safe @nogc
        {
            array[] = v[];
        }

        void opOpAssign(string op)(VectorType other) pure nothrow @safe @nogc
        {
            mixin("array[] "  ~ op ~ "= other.array[];");
        }

        // Assigning a dyn array
        this(ArrayType v) pure nothrow @safe @nogc
        {
            array[] = v[];
        }

        // Broadcast constructor
        this(BaseType x) pure nothrow @safe @nogc
        {
            array[] = x;
        }

        /// We can't support implicit conversion but do support explicit casting.
        /// "Vector types of the same size can be implicitly converted among each other."
        /// Casting to another vector type is always just a raw copy.
        VecDest opCast(VecDest)() pure const nothrow @trusted @nogc
            if (VecDest.sizeof == VectorType.sizeof)
            {
                VecDest dest = void;
                // Copy
                dest.array[] = (cast(typeof(dest.array))cast(void[VectorType.sizeof])array)[];
                return dest;
            }

        ref inout(BaseType) opIndex(size_t i) inout return pure nothrow @safe @nogc
        {
            return array[i];
        }

    }
}
else
{
    public import core.simd;

    // GDC cannot convert implicitely __vector from signed to unsigned, but LDC can
    // And GDC sometimes need those unsigned vector types for some intrinsics.
    // For internal use only.
    package alias ushort8 = Vector!(ushort[8]);
    package alias ubyte8  = Vector!(ubyte[8]);
    package alias ubyte16 = Vector!(ubyte[16]);

    static if (!AVXSizedVectorsAreEmulated)
    {
        package alias ushort16 = Vector!(ushort[16]);
        package alias ubyte32  = Vector!(ubyte[32]);
    }
}

// Emulate ldc.simd cmpMask and other masks.
// Note: these should be deprecated on non-LDC, 
// since it's slower to generate that code.
version(LDC)
{} 
else
{
    private template BaseType(V)
    {
        alias typeof( ( { V v; return v; }()).array[0]) BaseType;
    }

    private template TrueMask(V)
    {
        alias Elem = BaseType!V;

        static if (is(Elem == float))
        {
            immutable uint m1 = 0xffffffff;
            enum Elem TrueMask = *cast(float*)(&m1);
        }
        else static if (is(Elem == double))
        {
            immutable ulong m1 = 0xffffffff_ffffffff;
            enum Elem TrueMask = *cast(double*)(&m1);
        }
        else // integer case
        {
            enum Elem TrueMask = -1;
        }
    }

    Vec equalMask(Vec)(Vec a, Vec b) @trusted // for floats, equivalent to "oeq" comparison
    {
        enum size_t Count = Vec.array.length;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] == b.array[i];
            result.ptr[i] = cond ? TrueMask!Vec : 0;
        }
        return result;
    }

    Vec greaterMask(Vec)(Vec a, Vec b) @trusted // for floats, equivalent to "ogt" comparison
    {
        enum size_t Count = Vec.array.length;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] > b.array[i];
            result.ptr[i] = cond ? TrueMask!Vec : 0;
        }
        return result;
    }
}

unittest
{
    float4 a = [1, 3, 5, 7];
    float4 b = [2, 3, 4, 5];
    int4 c = cast(int4)(greaterMask!float4(a, b));
    static immutable int[4] correct = [0, 0, 0xffff_ffff, 0xffff_ffff];
    assert(c.array == correct);
}

static if (MMXSizedVectorsAreEmulated)
{
    /// MMX-like SIMD types
    struct float2
    {
        float[2] array;
        mixin VectorOps!(float2, float[2]);
    }

    struct byte8
    {
        byte[8] array;
        mixin VectorOps!(byte8, byte[8]);
    }

    struct short4
    {
        short[4] array;
        mixin VectorOps!(short4, short[4]);
    }

    struct int2
    {
        int[2] array;
        mixin VectorOps!(int2, int[2]);
    }

    struct long1
    {
        long[1] array;
        mixin VectorOps!(long1, long[1]);
    }
}
else
{
    // For this compiler, defining MMX-sized vectors is working.
    public import core.simd;
    alias Vector!(long [1]) long1;
    alias Vector!(float[2]) float2;
    alias Vector!(int  [2]) int2;
    alias Vector!(short[4]) short4;
    alias Vector!(byte [8]) byte8;
}

static assert(float2.sizeof == 8);
static assert(byte8.sizeof == 8);
static assert(short4.sizeof == 8);
static assert(int2.sizeof == 8);
static assert(long1.sizeof == 8);


static if (SSESizedVectorsAreEmulated)
{
    /// SSE-like SIMD types

    struct float4
    {
        float[4] array;
        mixin VectorOps!(float4, float[4]);
    }

    struct byte16
    {
        byte[16] array;
        mixin VectorOps!(byte16, byte[16]);
    }

    struct short8
    {
        short[8] array;
        mixin VectorOps!(short8, short[8]);
    }

    struct int4
    {
        int[4] array;
        mixin VectorOps!(int4, int[4]);
    }

    struct long2
    {
        long[2] array;
        mixin VectorOps!(long2, long[2]);
    }

    struct double2
    {
        double[2] array;
        mixin VectorOps!(double2, double[2]);
    }
}

static assert(float4.sizeof == 16);
static assert(byte16.sizeof == 16);
static assert(short8.sizeof == 16);
static assert(int4.sizeof == 16);
static assert(long2.sizeof == 16);
static assert(double2.sizeof == 16);


static if (AVXSizedVectorsAreEmulated)
{
    /// AVX-like SIMD types

    struct float8
    {
        float[8] array;
        mixin VectorOps!(float8, float[8]);
    }

    struct byte32
    {
        byte[32] array;
        mixin VectorOps!(byte32, byte[32]);
    }

    struct short16
    {
        short[16] array;
        mixin VectorOps!(short16, short[16]);
    }

    struct int8
    {
        int[8] array;
        mixin VectorOps!(int8, int[8]);
    }

    struct long4
    {
        long[4] array;
        mixin VectorOps!(long4, long[4]);
    }

    struct double4
    {
        double[4] array;
        mixin VectorOps!(double4, double[4]);
    }
}
else
{
    public import core.simd;    
}
static assert(float8.sizeof == 32);
static assert(byte32.sizeof == 32);
static assert(short16.sizeof == 32);
static assert(int8.sizeof == 32);
static assert(long4.sizeof == 32);
static assert(double4.sizeof == 32);




alias __m256 = float8;
alias __m256i = long4; // long long __vector with ICC, GCC, and clang
alias __m256d = double4;
alias __m128 = float4;
alias __m128i = int4;
alias __m128d = double2;
alias __m64 = long1; // like in Clang, __m64 is a vector of 1 long

int _MM_SHUFFLE2(int x, int y) pure @safe
{
    assert(x >= 0 && x <= 1);
    assert(y >= 0 && y <= 1);
    return (x << 1) | y;
}

int _MM_SHUFFLE(int z, int y, int x, int w) pure @safe
{
    assert(x >= 0 && x <= 3);
    assert(y >= 0 && y <= 3);
    assert(z >= 0 && z <= 3);
    assert(w >= 0 && w <= 3);
    return (z<<6) | (y<<4) | (x<<2) | w;
}

// test assignment from scalar to vector type
unittest
{
    float4 A = 3.0f;
    float[4] correctA = [3.0f, 3.0f, 3.0f, 3.0f];
    assert(A.array == correctA);

    int2 B = 42;
    int[2] correctB = [42, 42];
    assert(B.array == correctB);
}
