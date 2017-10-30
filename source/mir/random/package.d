/++
$(SCRIPT inhibitQuickIndex = 1;)

Basic API to construct non-uniform random number generators and stochastic algorithms.
Non-unoform and uniform random variable can be found at `mir.random.variable`.

$(TABLE $(H2 Generation functions),
$(TR $(TH Function Name) $(TH Description))
$(T2 rand, Generates real, integral, boolean, and enumerated uniformly distributed values.)
$(T2 randIndex, Generates uniformly distributed index.)
$(T2 randGeometric, Generates geometric distribution with `p = 1/2`.)
$(T2 randExponential2, Generates scaled Exponential distribution.)
)

Publicly includes  `mir.random.engine`.

Authors: Ilya Yaroshenko
Copyright: Copyright, Ilya Yaroshenko 2016-.
License:    $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, ndslice, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))

+/
module mir.random;

import std.traits;

public import mir.random.engine;

version (LDC)
{
    import ldc.intrinsics: log2 = llvm_log2;

    private
    pragma(inline, true)
    T bsf(T)(T v) pure @safe nothrow @nogc
    {
        import ldc.intrinsics;
        return llvm_cttz(v, true);
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
    alias R = EngineReturnType!G;
    enum P = T.sizeof / R.sizeof;
    static if (P > 1)
    {
        _Uab!(R[P],T) u = void;
        foreach (ref e; u.asArray)
            e = gen();
        return u.asInteger;
    }
    else static if (preferHighBits!G && P == 0)
    {
        version(LDC) pragma(inline, true);
        return cast(T) (gen() >>> ((R.sizeof - T.sizeof) * 8));
    }
    else
    {
        version(LDC) pragma(inline, true);
        return cast(T) gen();
    }
}

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine.xorshift;
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
    import std.traits : Signed;
    return 0 > cast(Signed!(EngineReturnType!G)) gen();
}

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine.xorshift;
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
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine.xorshift;
    auto gen = Xorshift(1);
    enum A { a, b, c }
    auto e = gen.rand!A;
}

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine.xorshift;
    auto gen = Xorshift(1);
    enum A : dchar { a, b, c }
    auto e = gen.rand!A;
}

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine.xorshift;
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

private static union _Uab(A,B) if (A.sizeof == B.sizeof && !is(Unqual!A == Unqual!B))
{
    A a;
    B b;

    private import std.traits: isArray, isIntegral, isFloatingPoint;

    static if (isArray!A && !isArray!B)
        alias asArray = a;
    static if (isArray!B && !isArray!A)
        alias asArray = b;

    static if (isIntegral!A && !isIntegral!B)
        alias asInteger = a;
    static if (isIntegral!B && !isIntegral!A)
        alias asInteger = b;

    static if (isFloatingPoint!A && !isFloatingPoint!B)
        alias asFloatingPoint = a;
    static if (isFloatingPoint!B && !isFloatingPoint!A)
        alias asFloatingPoint = b;
}

/++
Params:
    gen = saturated random number generator
    boundExp = bound exponent (optional). `boundExp` must be less or equal to `T.max_exp`.
Returns:
    Uniformly distributed real for interval `(-2^^boundExp , 2^^boundExp)`.
Note: `fabs` can be used to get a value from positive interval `[0, 2^^boundExp$(RPAREN)`.
+/
T rand(T, G)(ref G gen, sizediff_t boundExp = 0)
    if (isSaturatedRandomEngine!G && isFloatingPoint!T)
{
    assert(boundExp <= T.max_exp);
    enum W = T.sizeof * 8 - T.mant_dig - 1 - bool(T.mant_dig == 64);
    static if (T.mant_dig == float.mant_dig)
    {
        _Uab!(int,float) u = void;
        u.asInteger = gen.rand!int;
        enum uint EXPMASK = 0x7F80_0000;
        boundExp -= T.min_exp - 1;
        size_t exp = EXPMASK & u.asInteger;
        exp = boundExp - (exp ? bsf(exp) - (T.mant_dig - 1) : gen.randGeometric + W);
        u.asInteger &= ~EXPMASK;
        if(cast(sizediff_t)exp < 0)
        {
            exp = -cast(sizediff_t)exp;
            uint m = u.asInteger & int.max;
            if(exp >= T.mant_dig)
                m = 0;
            else
                m >>= cast(uint)exp;
            u.asInteger = (u.asInteger & ~int.max) ^ m;
            exp = 0;
        }
        u.asInteger = cast(uint)(exp << (T.mant_dig - 1)) ^ u.asInteger;
        return u.asFloatingPoint;
    }
    else
    static if (T.mant_dig == double.mant_dig)
    {
        _Uab!(long,double) u = void;
        u.asInteger = gen.rand!long;
        enum ulong EXPMASK = 0x7FF0_0000_0000_0000;
        boundExp -= T.min_exp - 1;
        ulong exp = EXPMASK & u.asInteger;
        exp = boundExp - (exp ? bsf(exp) - (T.mant_dig - 1) : gen.randGeometric + W);
        u.asInteger &= ~EXPMASK;
        if(cast(long)exp < 0)
        {
            exp = -cast(sizediff_t)exp;
            ulong m = u.asInteger & long.max;
            if(exp >= T.mant_dig)
                m = 0;
            else
                m >>= cast(uint)exp;
            u.asInteger = (u.asInteger & ~long.max) ^ m;
            exp = 0;
        }
        u.asInteger = (exp << (T.mant_dig - 1)) ^ u.asInteger;
        return u.asFloatingPoint;
    }
    else
    static if (T.mant_dig == 64)
    {
        auto d = gen.rand!int;
        auto m = gen.rand!ulong;
        enum uint EXPMASK = 0x7FFF;
        boundExp -= T.min_exp - 1;
        size_t exp = EXPMASK & d;
        exp = boundExp - (exp ? bsf(exp) : gen.randGeometric + W);
        if (cast(sizediff_t)exp > 0)
            m |= ~long.max;
        else
        {
            m &= long.max;
            exp = -cast(sizediff_t)exp;
            if(exp >= T.mant_dig)
                m = 0;
            else
                m >>= cast(uint)exp;
            exp = 0;
        }
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
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.math.common: fabs;
    import mir.random.engine.xorshift;
    auto gen = Xorshift(1);
    
    auto a = gen.rand!float;
    assert(-1 < a && a < +1);

    auto b = gen.rand!double(4);
    assert(-16 < b && b < +16);
    
    auto c = gen.rand!double(-2);
    assert(-0.25 < c && c < +0.25);
    
    auto d = gen.rand!real.fabs;
    assert(0.0L <= d && d < 1.0L);
}


/// Subnormal numbers
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine.xorshift;
    auto gen = Xorshift(1);
    auto x = gen.rand!double(double.min_exp-1);
    assert(-double.min_normal < x && x < double.min_normal);
}

/++
Params:
    gen = uniform random number generator
    m = positive module
Returns:
    Uniformly distributed integer for interval `[0 .. m$(RPAREN)`.
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
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine.xorshift;
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
    alias R = EngineReturnType!G;
    static if (is(R == ulong))
        alias T = size_t;
    else
        alias T = R;
    for(size_t count = 0;; count += T.sizeof * 8)
        if(auto val = gen.rand!T())
            return count + bsf(val);
}

@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine.xorshift;
    auto gen = Xoroshiro128Plus(1);
    size_t s = gen.randGeometric;//Merely verify the call is @safe etc.
}

/++
Params:
    gen = saturated random number generator
Returns:
    `X ~ Exp(1) / log(2)`.
Note: `fabs` can be used to get a value from positive interval `[0, 2^^boundExp$(RPAREN)`.
+/
T randExponential2(T, G)(ref G gen)
    if (isSaturatedRandomEngine!G && isFloatingPoint!T)
{
    enum W = T.sizeof * 8 - T.mant_dig - 1 - bool(T.mant_dig == 64);
    static if (is(T == float))
    {
        _Uab!(uint,float) u = void;
        u.asInteger = gen.rand!uint;
        enum uint EXPMASK = 0xFF80_0000;
        auto exp = EXPMASK & u.asInteger;
        u.asInteger &= ~EXPMASK;
        u.asInteger ^= 0x3F000000; // 0.5
        auto y = exp ? bsf(exp) - (T.mant_dig - 1) : gen.randGeometric + W;
        auto x = u.asFloatingPoint;
    }
    else
    static if (is(T == double))
    {
        _Uab!(ulong,double) u = void;
        u.asInteger = gen.rand!ulong;
        enum ulong EXPMASK = 0xFFF0_0000_0000_0000;
        auto exp = EXPMASK & u.asInteger;
        u.asInteger &= ~EXPMASK;
        u.asInteger ^= 0x3FE0000000000000; // 0.5
        auto y = exp ? bsf(exp) - (T.mant_dig - 1) : gen.randGeometric + W;
        auto x = u.asFloatingPoint;
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
@nogc nothrow @safe version(mir_random_test) unittest
{
    import mir.random.engine.xorshift;
    auto gen = Xorshift(cast(uint)unpredictableSeed);
    auto v = gen.randExponential2!double();
}

/++
$(LINK2 https://dlang.org/phobos/std_random.html#.isUniformRNG,
std.random.isUniformRNG!T)
+/
template isPhobosUniformRNG(T)
{
    import std.random: isUniformRNG;
    enum bool isPhobosUniformRNG = isUniformRNG!T;
}

/++
Extends a Mir-style random number generator to also meet
the Phobos `std.random` interface.
+/
struct PhobosRandom(Engine) if (isRandomEngine!Engine && !isPhobosUniformRNG!Engine)//Doesn't need to be saturated.
{
    alias Uint = EngineReturnType!Engine;
    private Engine _engine;
    private Uint _front;

    /// Default constructor and copy constructor are disabled.
    @disable this();
    /// ditto
    @disable this(this);

    /// Forward constructor arguments to `Engine`.
    this(A...)(auto ref A args)
    if (is(typeof(Engine(args))))
    {
        _engine = Engine(args);
        _front = _engine.opCall();
    }

    /// Phobos-style random interface.
    enum bool isUniformRandom = true;
    /// ditto
    enum Uint min = Uint.min;//Always normalized.
    /// ditto
    enum Uint max = Engine.max;//Might not be saturated.
    /// ditto
    enum bool empty = false;
    /// ditto
    @property Uint front()() const { return _front; }
    /// ditto
    void popFront()() { _front = _engine.opCall(); }
    /// ditto
    void seed(A...)(auto ref A args) if (is(typeof(Engine(args))))
    {
        _engine.__ctor(args);
        _front = _engine.opCall();
    }

    /// Retain support for Mir-style random interface.
    enum bool isRandomEngine = true;
    /// ditto
    enum bool preferHighBits = .preferHighBits!Engine;
    /// ditto
    Uint opCall()()
    {
        Uint result = _front;
        _front = _engine.opCall();
        return result;
    }

    ///
    @property ref inout(Engine) engine()() inout @nogc nothrow pure @safe
    {
        return _engine;
    }

    ///
    alias engine this;
}
/// ditto
template PhobosRandom(Engine) if (isSaturatedRandomEngine!Engine && isPhobosUniformRNG!Engine)
{
    alias PhobosRandom = Engine;
}

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine.xorshift: Xorshift1024StarPhi;
    import std.random: isSeedable, isPhobosUniformRNG = isUniformRNG;

    alias RNG = PhobosRandom!Xorshift1024StarPhi;

    //Phobos interface
    static assert(isPhobosUniformRNG!(RNG, ulong));
    static assert(isSeedable!(RNG, ulong));
    //Mir interface
    static assert(isSaturatedRandomEngine!RNG);
    static assert(is(EngineReturnType!RNG == ulong));

    auto gen = Xorshift1024StarPhi(1);
    auto rng = RNG(1);
    assert(gen() == rng.front);
    rng.popFront();
    assert(gen() == rng.front);
    rng.popFront();
    assert(gen() == rng());

    gen.__ctor(1);
    rng.seed(1);
    assert(gen() == rng());

    //Can still access unique methods due to "alias this":
    rng.jump();
}
