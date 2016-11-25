/++
Authors: Ilya Yaroshenko
Copyright: Copyright, Ilya Yaroshenko 2016-.
License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
+/
module random;

import std.traits;

public import random.engine;

version (LDC)
{
    import ldc.intrinsics: log2 = llvm_log2;

    private
    pragma(inline, true)
    size_t bsf(size_t v) pure @safe nothrow @nogc
    {
        import ldc.intrinsics;
        return cast(int)llvm_cttz(v, true);
    }
}
else
{
    import std.math: log2;
    import core.bitop: bsf;
}

/++
Params:
    gen = saturated random number generator
Returns:
    Uniformly distributed integer for interval `[0 .. T.max]`.
+/
T rand(T, G)(ref G gen)
    if (isSaturatedRandomEngine!G && isIntegral!T && !is(T == enum))
{
    alias R = ReturnType!G;
    enum P = T.sizeof / R.sizeof;
    static if (P > 1)
    {
        T ret = void;
        foreach(p; 0..P)
            (cast(R*)(&ret))[p] = gen();
        return ret;
    }
    else
    {
        version(LDC) pragma(inline, true);
        return cast(T) gen();
    }
}

///
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    auto s = gen.rand!short;
    auto n = gen.rand!ulong;
}

/++
Params:
    gen = saturated random number generator
Returns:
    Uniformly distributed boolean.
+/
bool rand(T : bool, G)(ref G gen)
    if (isSaturatedRandomEngine!G)
{
    return gen() & 1;
}

///
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    auto s = gen.rand!bool;
}

private alias Iota(size_t j) = Iota!(0, j);

private template Iota(size_t i, size_t j)
{
    import std.meta;
    static assert(i <= j, "Iota: i should be less than or equal to j");
    static if (i == j)
        alias Iota = AliasSeq!();
    else
        alias Iota = AliasSeq!(i, Iota!(i + 1, j));
}

/++
Params:
    gen = saturated random number generator
Returns:
    Uniformly distributed enumeration.
+/
T rand(T, G)(ref G gen)
    if (isSaturatedRandomEngine!G && is(T == enum))
{
    static if (is(T : long))
        enum tiny = [EnumMembers!T] == [Iota!(EnumMembers!T.length)];
    else
        enum tiny = false;
    static if (tiny)
    {
        return cast(T) gen.randIndex(EnumMembers!T.length);
    }
    else
    {
        static immutable T[EnumMembers!T.length] members = [EnumMembers!T];
        return members[gen.randIndex($)];
    }
}

///
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    enum A { a, b, c }
    auto e = gen.rand!A;
}

///
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    enum A : dchar { a, b, c }
    auto e = gen.rand!A;
}

///
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    enum A : string { a = "a", b = "b", c = "c" }
    auto e = gen.rand!A;
}

private static union _U
{
    real r;
    struct
    {
        version(LittleEndian)
        {
            ulong m;
            ushort e;
        }
        else
        {
            ushort e;
            align(2)
            ulong m;
        }
    }
}

/++
Params:
    gen = saturated random number generator
    boundExp = bound exponent (optional). `boundExp` must be less or equal to `T.max_exp`.
Returns:
    Uniformly distributed real for interval `(2^^(-boundExp) , 2^^boundExp)`.
Note: `fabs` can be used to get a value from positive interval `[0, 2^^boundExp)`.
+/
T rand(T, G)(ref G gen, sizediff_t boundExp = 0)
    if (isSaturatedRandomEngine!G && isFloatingPoint!T)
{
    assert(boundExp <= T.max_exp);
    enum W = T.sizeof * 8 - T.mant_dig - 1 - bool(T.mant_dig == 64);
    static if (is(T == float))
    {
        auto d = gen.rand!uint;
        enum uint EXPMASK = 0x7F80_0000;
        boundExp -= T.min_exp - 1;
        size_t exp = EXPMASK & d;
        exp = boundExp - (exp ? bsf(exp) - (T.mant_dig - 1) : gen.randGeometric + W);
        if(cast(sizediff_t)exp < 0)
        {
            exp = 0;
            d &= ~long.max;
        }
        d = cast(uint)(exp << (T.mant_dig - 1)) ^ (d & ~EXPMASK);
        return *cast(T*)&d;
    }
    else
    static if (is(T == double))
    {
        auto d = gen.rand!ulong;
        enum ulong EXPMASK = 0x7FF0_0000_0000_0000;
        boundExp -= T.min_exp - 1;
        ulong exp = EXPMASK & d;
        exp = boundExp - (exp ? bsf(exp) - (T.mant_dig - 1) : gen.randGeometric + W);
        if(cast(long)exp < 0)
        {
            exp = 0;
            d &= ~long.max;
        }
        d = (exp << (T.mant_dig - 1)) ^ (d & ~EXPMASK);
        return *cast(T*)&d;
    }
    else
    static if (T.mant_dig == 64)
    {
        auto d = gen.rand!uint;
        auto m = gen.rand!ulong;
        enum uint EXPMASK = 0x7FFF;
        boundExp -= T.min_exp - 1;
        size_t exp = EXPMASK & d;
        exp = boundExp - (exp ? bsf(exp) : gen.randGeometric + W);
        if(cast(sizediff_t)exp < 0)
        {
            exp = 0;
            m = 0;
        }
        else
        if (exp)
            m |= ~long.max;
        else
            m &= long.max;
        d = cast(uint) exp ^ (d & ~EXPMASK);
        _U ret = void;
        ret.e = cast(ushort)d;
        ret.m = m;
        return ret.r;
    }
    /// TODO: quadruple
    else static assert(0);
}

///
unittest
{
    import std.math: fabs;
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    
    auto a = gen.rand!float;
    assert(-1 < a && a < +1);
    
    auto b = gen.rand!double(4);
    assert(-16 < b && b < +16);
    
    auto c = gen.rand!double(-2);
    assert(-0.25 < c && c < +0.25);
    
    auto d = gen.rand!real.fabs;
    assert(0 <= d && d < 1);
}


/// Subnormal numbers
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    auto x = gen.rand!double(double.min_exp-1);
    assert(-double.min_normal < x && x < double.min_normal);
}

/++
Params:
    gen = uniform random number generator
    m = positive module
Returns:
    Uniformly distributed integer for interval `[0 .. m)`.
+/
T randIndex(T, G)(ref G gen, T m)
    if(isSaturatedRandomEngine!G && isUnsigned!T)
{
    assert(m, "m must be positive");
    T ret = void;
    T val = void;
    do
    {
        val = gen.rand!T;
        ret = val % m;
    }
    while (val - ret > -m);
    return ret;
}

///
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    auto s = gen.randIndex!uint(100);
    auto n = gen.randIndex!ulong(-100);
}

/++
    Returns: `n >= 0` such that `P(n) := 1 / (2^^(n + 1))`.
+/
size_t randGeometric(G)(ref G gen)
    if(isSaturatedRandomEngine!G)
{
    alias R = ReturnType!G;
    static if (is(R == ulong))
        alias T = size_t;
    else
        alias T = R;
    for(size_t count = 0;; count += T.sizeof * 8)
        if(auto val = gen.rand!T())
            return count + bsf(val);
}

/++
Params:
    gen = saturated random number generator
Returns:
    `X ~ Exp(1) / log(2)`.
Note: `fabs` can be used to get a value from positive interval `[0, 2^^boundExp)`.
+/
T randExponential2(T, G)(ref G gen)
    if (isSaturatedRandomEngine!G && isFloatingPoint!T)
{
    enum W = T.sizeof * 8 - T.mant_dig - 1 - bool(T.mant_dig == 64);
    static if (is(T == float))
    {
        auto d = gen.rand!uint;
        enum uint EXPMASK = 0xFF80_0000;
        auto exp = EXPMASK & d;
        d &= ~EXPMASK;
        d ^= 0x3F000000; // 0.5
        auto y = exp ? bsf(exp) - (T.mant_dig - 1) : gen.randGeometric + W;
        auto x = *cast(T*)&d;
    }
    else
    static if (is(T == double))
    {
        auto d = gen.rand!ulong;
        enum ulong EXPMASK = 0xFFF0_0000_0000_0000;
        auto exp = EXPMASK & d;
        d &= ~EXPMASK;
        d ^= 0x3FE0000000000000; // 0.5
        auto y = exp ? bsf(exp) - (T.mant_dig - 1) : gen.randGeometric + W;
        auto x = *cast(T*)&d;
    }
    else
    static if (T.mant_dig == 64)
    {
        _U ret = void;
        ret.e = 0x3FFE;
        ret.m = gen.rand!ulong | ~long.max;
        auto y = gen.randGeometric;
        auto x = ret.r;
    }
    /// TODO: quadruple
    else static assert(0);

    if (x == 0.5f)
        return y;
    else
        return -log2(x) + y;
}

///
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(cast(uint)unpredictableSeed);
    auto v = gen.randExponential2!double();
}
