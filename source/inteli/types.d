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
    //   but this is sadly impossible in D.
    // 
    // 2. `vec.array` is directly writeable.

    nothrow:
    @nogc:
    pure:


    struct float4
    {
        float[4] array;
        mixin VectorOps!(float4, float[4], float, 4);
    }

    struct byte16
    {
        byte[16] array;
        mixin VectorOps!(byte16, byte[16], byte, 16);
    }

    struct short8
    {
        short[8] array;
        mixin VectorOps!(short8, short[8], short, 8);
    }

    struct int4
    {
        int[4] array;
        mixin VectorOps!(int4, int[4], int, 4);
    }

    struct long2
    {
        long[2] array;
        mixin VectorOps!(long2, long[2], long, 2);
    }

    struct double2
    {
        double[2] array;
        mixin VectorOps!(double2, double[2], double, 2);
    }

    static assert(float4.sizeof == 16);
    static assert(byte16.sizeof == 16);
    static assert(short8.sizeof == 16);
    static assert(int4.sizeof == 16);
    static assert(long2.sizeof == 16);
    static assert(double2.sizeof == 16);

    mixin template VectorOps(VectorType, ArrayType, BaseType, int N)
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


    Vec shufflevector(Vec, mask...)(Vec a, Vec b)
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
}

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



