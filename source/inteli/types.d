/**
* Copyright: Copyright Auburn Sounds 2016-2018.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.types;

version(LDC)
{
    public import core.simd;
}
else
{
    // This is a LDC SIMD emulation layer, for use with other D compilers.
    // The goal is to be very similar in precision.
    // The biggest differences are:
    //
    // 1. `cast` everywhere. With LDC vector types, short8 is implicitely convertible to int4
    //   but this is sadly impossible in D without D_SIMD (Windows 32-bit).
    //
    // 2. `vec.array` is directly writeable.

    nothrow:
    @nogc:
    pure:


    struct float4
    {
        float[4] array;
        mixin VectorOps!(float4, float[4]);

        enum float TrueMask = allOnes();
        enum float FalseMask = 0.0f;

        private static float allOnes()
        {
            uint m1 = 0xffffffff;
            return *cast(float*)(&m1);
        }
    }

    struct byte16
    {
        byte[16] array;
        mixin VectorOps!(byte16, byte[16]);
        enum byte TrueMask = -1;
        enum byte FalseMask = 0;
    }

    struct short8
    {
        short[8] array;
        mixin VectorOps!(short8, short[8]);
        enum short TrueMask = -1;
        enum short FalseMask = 0;
    }

    struct int4
    {
        int[4] array;
        mixin VectorOps!(int4, int[4]);
        enum int TrueMask = -1;
        enum int FalseMask = 0;
    }

    struct long2
    {
        long[2] array;
        mixin VectorOps!(long2, long[2]);
        enum long TrueMask = -1;
        enum long FalseMask = 0;
    }

    struct double2
    {
        double[2] array;
        mixin VectorOps!(double2, double[2]);

        enum double TrueMask = allOnes();
        enum double FalseMask = 0.0f;

        private static double allOnes()
        {
            ulong m1 = 0xffffffff_ffffffff;
            return *cast(double*)(&m1);
        }
    }

    static assert(float4.sizeof == 16);
    static assert(byte16.sizeof == 16);
    static assert(short8.sizeof == 16);
    static assert(int4.sizeof == 16);
    static assert(long2.sizeof == 16);
    static assert(double2.sizeof == 16);

    mixin template VectorOps(VectorType, ArrayType: BaseType[N], BaseType, size_t N)
    {
        enum Count = N;
        alias Base = BaseType;

        // Unary operators
        VectorType opUnary(string op)() pure nothrow @safe @nogc
        {
            VectorType res = void;
            mixin("res.array[] = " ~ op ~ "array[];");
            return res;
        }

        // Binary operators
        VectorType opBinary(string op)(VectorType other) pure nothrow @safe @nogc
        {
            VectorType res = void;
            mixin("res.array[] = array[] " ~ op ~ " other.array[];");
            return res;
        }

        // Assigning a static array
        void opAssign(ArrayType v) pure nothrow @safe @nogc
        {
            array[] = v[];
        }

        // Assigning a dyn array
        this(ArrayType v) pure nothrow @safe @nogc
        {
            array[] = v[];
        }

        /// We can't support implicit conversion but do support explicit casting.
        /// "Vector types of the same size can be implicitly converted among each other."
        /// Casting to another vector type is always just a raw copy.
        VecDest opCast(VecDest)() pure nothrow @trusted @nogc
            if (VecDest.sizeof == VectorType.sizeof)
        {
            // import core.stdc.string: memcpy;
            VecDest dest = void;
            // Copy
            dest.array[] = (cast(typeof(dest.array))cast(void[VectorType.sizeof])array)[];
            // memcpy(dest.array.ptr, array.ptr, VectorType.sizeof);
            return dest;
        }

        ref BaseType opIndex(size_t i) pure nothrow @safe @nogc
        {
            return array[i];
        }

    }

    auto extractelement(Vec, int index, Vec2)(Vec2 vec) @trusted
    {
        static assert(Vec.sizeof == Vec2.sizeof);
        import core.stdc.string: memcpy;
        Vec v = void;
        memcpy(&v, &vec, Vec2.sizeof);
        return v.array[index];
    }

    auto insertelement(Vec, int index, Vec2)(Vec2 vec, Vec.Base e) @trusted
    {
        static assert(Vec.sizeof == Vec2.sizeof);
        import core.stdc.string: memcpy;
        Vec v = void;
        memcpy(&v, &vec, Vec2.sizeof);
        v.array[index] = e;
        return v;
    }

    // Note: can't be @safe with this signature
    Vec loadUnaligned(Vec)(const(Vec.Base)* pvec) @trusted
    {
        return *cast(Vec*)(pvec);
    }

     // Note: can't be @safe with this signature
    void storeUnaligned(Vec)(Vec v, Vec.Base* pvec, ) @trusted
    {
        *cast(Vec*)(pvec) = v;
    }


    Vec shufflevector(Vec, mask...)(Vec a, Vec b) @safe
    {
        static assert(mask.length == Vec.Count);

        Vec r = void;
        foreach(int i, m; mask)
        {
            static assert (m < Vec.Count * 2);
            int ind = cast(int)m;
            if (ind < Vec.Count)
                r.array[i] = a.array[ind];
            else
                r.array[i] = b.array[ind-Vec.Count];
        }
        return r;
    }

    // emulate ldc.simd cmpMask

    Vec equalMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "oeq" comparison
    {
        alias BaseType = Vec.Base;
        alias Count = Vec.Count;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] == b.array[i];
            result.array[i] = cond ? Vec.TrueMask : Vec.FalseMask;
        }
        return result;
    }

    Vec notEqualMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "one" comparison
    {
        alias BaseType = Vec.Base;
        alias Count = Vec.Count;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] != b.array[i];
            result.array[i] = cond ? Vec.TrueMask : Vec.FalseMask;
        }
        return result;
    }

    Vec greaterMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "ogt" comparison
    {
        alias BaseType = Vec.Base;
        alias Count = Vec.Count;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] > b.array[i];
            result.array[i] = cond ? Vec.TrueMask : Vec.FalseMask;
        }
        return result;
    }

    Vec greaterOrEqualMask(Vec)(Vec a, Vec b) @safe // for floats, equivalent to "oge" comparison
    {
        alias BaseType = Vec.Base;
        alias Count = Vec.Count;
        Vec result;
        foreach(int i; 0..Count)
        {
            bool cond = a.array[i] > b.array[i];
            result.array[i] = cond ? Vec.TrueMask : Vec.FalseMask;
        }
        return result;
    }

    unittest
    {
        float4 a = [1, 3, 5, 7];
        float4 b = [2, 3, 4, 5];
        int4 c = cast(int4)(greaterMask!float4(a, b));
        static immutable int[4] correct = [0, 0, 0xffff_ffff, 0xffff_ffff];
        assert(c.array == correct);
    }
}

nothrow:
@nogc:

alias __m128 = float4;
alias __m128i = int4;
alias __m128d = double2;
alias __m64 = long; // Note: operation using __m64 are not available.

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


// Note: `ldc.simd` cannot express all nuances of FP comparisons, so we
//       need different IR generation.

enum FPComparison
{
    false_,// no comparison, always returns false
    oeq,   // ordered and equal
    ogt,   // ordered and greater than
    oge,   // ordered and greater than or equal
    olt,   // ordered and less than
    ole,   // ordered and less than or equal
    one,   // ordered and not equal
    ord,   // ordered (no nans)
    ueq,   // unordered or equal
    ugt,   // unordered or greater than ("nle")
    uge,   // unordered or greater than or equal ("nlt")
    ult,   // unordered or less than ("nge")
    ule,   // unordered or less than or equal ("ngt")
    une,   // unordered or not equal ("neq")
    uno,   // unordered (either nans)
    true_, // no comparison, always return true
}

private static immutable string[FPComparison.max+1] FPComparisonToString =
[
    "false",
    "oeq",
    "ogt",
    "oge",
    "olt",
    "ole",
    "one",
    "ord",
    "ueq",
    "ugt",
    "uge",
    "ult",
    "ule",
    "une",
    "uno",
    "true"
];

version(LDC)
{
    import ldc.simd;

    /// Provides packed float comparisons
    package int4 cmpps(FPComparison comparison)(float4 a, float4 b)
    {
        enum ir = `
            %cmp = fcmp `~ FPComparisonToString[comparison] ~` <4 x float> %0, %1
            %r = sext <4 x i1> %cmp to <4 x i32>
            ret <4 x i32> %r`;

        return inlineIR!(ir, int4, float4, float4)(a, b);
    }

    /// Provides packed double comparisons
    package long2 cmppd(FPComparison comparison)(double2 a, double2 b)
    {
        enum ir = `
            %cmp = fcmp `~ FPComparisonToString[comparison] ~` <2 x double> %0, %1
            %r = sext <2 x i1> %cmp to <2 x i64>
            ret <2 x i64> %r`;

        return inlineIR!(ir, long2, double2, double2)(a, b);
    } 
}
else
{
    // Individual float comparison: returns -1 for true or 0 for false.
    private bool compareFloat(T)(FPComparison comparison, T a, T b)
    {
        import std.math;
        bool unordered = isNaN(a) || isNaN(b);
        final switch(comparison) with(FPComparison)
        {
            case false_: return false;
            case oeq: return a == b;
            case ogt: return a > b;
            case oge: return a >= b;
            case olt: return a < b;
            case ole: return a <= b;
            case one: return !unordered && (a != b);
            case ord: return !unordered; 
            case ueq: return unordered || (a == b);
            case ugt: return unordered || (a > b);
            case uge: return unordered || (a >= b);
            case ult: return unordered || (a < b);
            case ule: return unordered || (a <= b);
            case une: return (a != b); // NaN with != always yields true
            case uno: return unordered;
            case true_: return true;
        }
    }

    /// Provides packed float comparisons
    package int4 cmpps(FPComparison comparison)(float4 a, float4 b)
    {
        int4 result;
        foreach(i; 0..4)
        {
            result[i] = compareFloat!(float)(comparison, a[i], b[i]) ? -1 : 0;
        }
        return result;
    }

    /// Provides packed double comparisons
    package long2 cmppd(FPComparison comparison)(double2 a, double2 b)
    {
        long2 result;
        foreach(i; 0..2)
        {
            result[i] = compareFloat!(double)(comparison, a[i], b[i]) ? -1 : 0;
        }
        return result;
    }
}
unittest
{
    // Check all comparison type is working
    float4 A = [1, 3, 5, float.nan];
    float4 B = [2, 3, 4, 5];

    int4 result_false_ = cmpps!(FPComparison.false_)(A, B);
    int4 result_oeq = cmpps!(FPComparison.oeq)(A, B);
    int4 result_ogt = cmpps!(FPComparison.ogt)(A, B);
    int4 result_oge = cmpps!(FPComparison.oge)(A, B);
    int4 result_olt = cmpps!(FPComparison.olt)(A, B);
    int4 result_ole = cmpps!(FPComparison.ole)(A, B);
    int4 result_one = cmpps!(FPComparison.one)(A, B);
    int4 result_ord = cmpps!(FPComparison.ord)(A, B);
    int4 result_ueq = cmpps!(FPComparison.ueq)(A, B);
    int4 result_ugt = cmpps!(FPComparison.ugt)(A, B);
    int4 result_uge = cmpps!(FPComparison.uge)(A, B);
    int4 result_ult = cmpps!(FPComparison.ult)(A, B);
    int4 result_ule = cmpps!(FPComparison.ule)(A, B);
    int4 result_une = cmpps!(FPComparison.une)(A, B);
    int4 result_uno = cmpps!(FPComparison.uno)(A, B);
    int4 result_true_ = cmpps!(FPComparison.true_)(A, B);

    static immutable int[4] correct_false_ = [ 0, 0, 0, 0];
    static immutable int[4] correct_oeq    = [ 0,-1, 0, 0];
    static immutable int[4] correct_ogt    = [ 0, 0,-1, 0];
    static immutable int[4] correct_oge    = [ 0,-1,-1, 0];
    static immutable int[4] correct_olt    = [-1, 0, 0, 0];
    static immutable int[4] correct_ole    = [-1,-1, 0, 0];
    static immutable int[4] correct_one    = [-1, 0,-1, 0];
    static immutable int[4] correct_ord    = [-1,-1,-1, 0];
    static immutable int[4] correct_ueq    = [ 0,-1, 0,-1];
    static immutable int[4] correct_ugt    = [ 0, 0,-1,-1];
    static immutable int[4] correct_uge    = [ 0,-1,-1,-1];
    static immutable int[4] correct_ult    = [-1, 0, 0,-1];
    static immutable int[4] correct_ule    = [-1,-1, 0,-1];
    static immutable int[4] correct_une    = [-1, 0,-1,-1];
    static immutable int[4] correct_uno    = [ 0, 0, 0,-1];
    static immutable int[4] correct_true_  = [-1,-1,-1,-1];

    assert(result_false_.array == correct_false_);
    assert(result_oeq.array == correct_oeq);
    assert(result_ogt.array == correct_ogt);
    assert(result_oge.array == correct_oge);
    assert(result_olt.array == correct_olt);
    assert(result_ole.array == correct_ole);
    assert(result_one.array == correct_one);
    assert(result_ord.array == correct_ord);
    assert(result_ueq.array == correct_ueq);
    assert(result_ugt.array == correct_ugt);
    assert(result_uge.array == correct_uge);
    assert(result_ult.array == correct_ult);
    assert(result_ule.array == correct_ule);
    assert(result_une.array == correct_une);
    assert(result_uno.array == correct_uno);
    assert(result_true_.array == correct_true_);
}
unittest
{
    double2 a = [1, 3];
    double2 b = [2, 3];
    long2 c = cmppd!(FPComparison.ult)(a, b);
    static immutable long[2] correct = [cast(long)(-1), 0];
    assert(c.array == correct);
}


