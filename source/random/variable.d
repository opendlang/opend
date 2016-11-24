/++
Authors: Ilya Yaroshenko
Copyright: Copyright, Ilya Yaroshenko 2016-.
License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
+/
module random.variable;

import random;
import std.traits;

import std.math : nextDown, isFinite, LN2;


version(LDC)
    import ldc.intrinsics: fabs = llvm_fabs, sqrt = llvm_sqrt, log = llvm_log;
else
    import std.math: fabs, sqrt, log;

/// User Defined Attribute definition for Random Variable.
enum RandomVariable;

/++
Test if T is a random variable.
+/
template isRandomVariable(T)
{
    static if (hasUDA!(T, RandomEngine))
        enum isRandomVariable = is(typeof({
                auto gen = Random(1);
                T rv;
                auto x = rv(gen);
                auto y = rv!Random(gen);
                static assert(is(typeof(x) == typeof(y)));
            }));
    else enum isRandomVariable = false;
}

/++
Discrete Uniform Random Variable.
Returns: `X ~ U[a, b]`
+/
@RandomVariable struct UniformVariable(T)
    if (isIntegral!T)
{
    private alias U = Unsigned!T;
    private U _length;
    private T _location = 0;

    /++
    Constraints: `a <= b`.
    +/
    this(T a, T b)
    {
        assert(a <= b, "constraint: a <= b");
        _length = b - a + 1;
        _location = a;
    }

    ///
    T opCall(G)(ref G gen)
        if (isSaturatedRandomEngine!G)
    {
        return _length ? gen.randIndex!U(_length) + _location : gen.rand!U;
    }

    ///
    T min() @property { return _location; }
    ///
    T max() @property { return _length - 1 + _location; }
}

///
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    auto rv = UniformVariable!int(-10, 10); // [-10, 10]
    auto x = rv(gen); // random variable
    assert(rv.min == -10);
    assert(rv.max == 10);
}

/++
Real Uniform Random Variable.
Returns: `X ~ U[a, b)`
+/
@RandomVariable struct UniformVariable(T)
    if (isFloatingPoint!T)
{
    private T _a;
    private T _b;

    /++
    Constraints: `a < b`, `a` and `b` are finite numbers.
    +/
    this(T a, T b)
    {
        assert(a < b, "constraint: a < b");
        assert(a.isFinite);
        assert(b.isFinite);
        _a = a;
        _b = b;
    }

    ///
    T opCall(G)(ref G gen)
        if (isSaturatedRandomEngine!G)
    {
        auto ret =  gen.rand!T.fabs * (_b - _a) + _a;
        if(ret < _b)
            return ret;
        return max;
    }

    ///
    T min() @property { return _a; }
    ///
    T max() @property { return _b.nextDown; }
}

///
unittest
{
    import std.math : nextDown;
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    auto rv = UniformVariable!double(-8, 10); // [-8, 10)
    auto x = rv(gen); // random variable
    assert(rv.min == -8.0);
    assert(rv.max == 10.0.nextDown);
}

unittest
{
    import std.math : nextDown;
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    auto rv = UniformVariable!double(-8, 10); // [-8, 10)
    foreach(_; 0..1000)
    {
        auto x = rv(gen);
        assert(rv.min <= x && x <= rv.max);
    }
}

/++
Exponential Random Variable.
Returns: `X ~ Exp(β)`
+/
@RandomVariable struct ExponentialVariable(T)
    if (isFloatingPoint!T)
{
    private T _scale = 1;

    ///
    this(T scale)
    {
        _scale = T(LN2) * scale;
    }

    ///
    T opCall(G)(ref G gen)
        if (isSaturatedRandomEngine!G)
    {
        return gen.randExponential2!T * _scale;
    }
}

///
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    auto rv = ExponentialVariable!double(1);
    auto x = rv(gen);
}

private T hypot01(T)(const T x, const T y)
{
    // Scale x and y to avoid underflow and overflow.
    // If one is huge and the other tiny, return the larger.
    // If both are huge, avoid overflow by scaling by 1/sqrt(real.max/2).
    // If both are tiny, avoid underflow by scaling by sqrt(real.min_normal*real.epsilon).

    enum T SQRTMIN = 0.5f * sqrt(T.min_normal); // This is a power of 2.
    enum T SQRTMAX = 1 / SQRTMIN; // 2^^((max_exp)/2) = nextUp(sqrt(T.max))

    static assert(2*(SQRTMAX/2)*(SQRTMAX/2) <= T.max);

    // Proves that sqrt(T.max) ~~  0.5/sqrt(T.min_normal)
    static assert(T.min_normal*T.max > 2 && T.min_normal*T.max <= 4);

    T u = fabs(x);
    T v = fabs(y);
    if (u < v)  // check for NaN as well.
    {
        auto t = v;
        v = u;
        u = t;
    }

    if (u <= SQRTMIN)
    {
        // hypot (tiny, tiny) -- avoid underflow
        // This is only necessary to avoid setting the underflow
        // flag.
        u *= SQRTMAX / T.epsilon;
        v *= SQRTMAX / T.epsilon;
        return sqrt(u * u + v * v) * SQRTMIN * T.epsilon;
    }

    if (u * T.epsilon > v)
    {
        // hypot (huge, tiny) = huge
        return u;
    }

    // both are in the normal range
    return sqrt(u*u + v*v);
}

/++
Normal Random Variable.
Returns: `X ~ N(μ, σ)`
+/
@RandomVariable struct NormalVariable(T)
    if (isFloatingPoint!T)
{
    private T _location = 0;
    private T _scale = 1;
    private T _y = 0;
    private bool _hot;

    ///
    this(T location, T scale)
    {
        _location = location;
        _scale = scale;
    }

    ///
    T opCall(G)(ref G gen)
        if (isSaturatedRandomEngine!G)
    {
        T _x = void;
        if (_hot)
        {
            _hot = false;
            _x = _y;
        }
        else
        {
            T u = void;
            T v = void;
            T s = void;
            do
            {
                u = gen.rand!T;
                v = gen.rand!T;
                s = hypot01(u, v);
            }
            while (s > 1 || s == 0);
            auto scale = 2 * sqrt(-log(s)) / s;
            _y = v * scale;
            _x = u * scale;
            _hot = true;
        }
        return _x * _scale + _location;
    }
}

///
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    auto rv = NormalVariable!double(0, 1);
    auto x = rv(gen);
}

/++
Cauchy Random Variable.
Returns: `X ~ Cauchy(x, γ)`
+/
@RandomVariable struct CauchyVariable(T)
    if (isFloatingPoint!T)
{
    private T _location = 0;
    private T _scale = 1;

    ///
    this(T location, T scale)
    {
        _location = location;
        _scale = scale;
    }

    ///
    T opCall(G)(ref G gen)
        if (isSaturatedRandomEngine!G)
    {
        T u = void;
        T v = void;
        T x = void;
        do
        {
            u = gen.rand!T;
            v = gen.rand!T;
            x = u / v;
        }
        while (u * u + v * v > 1 || !(x.fabs < T.infinity));
        return x * _scale + _location;
    }
}

///
unittest
{
    import random.engine.xorshift;
    auto gen = Xorshift(1);
    auto rv = CauchyVariable!double(0, 1);
    auto x = rv(gen);
}