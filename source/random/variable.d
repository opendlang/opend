/++
Authors: Ilya Yaroshenko
Copyright: Copyright, Ilya Yaroshenko 2016-.
License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
+/
module random.variable;

import random;
import std.traits;

version(LDC)
    import ldc.intrinsics: fabs = llvm_fabs;
else
    import std.math: fabs;

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
    private T _offset;

    /++
    Constraints: `a <= b`.
    +/
    this(T a, T b)
    {
        assert(a <= b, "constraint: a <= b");
        _length = b - a + 1;
        _offset = a;
    }

    ///
    T opCall(G)(ref G gen)
        if (isSaturatedRandomEngine!G)
    {
        return _length ? gen.randIndex!U(_length) + _offset : gen.rand!U;
    }

    ///
    T min() @property { return _offset; }
    ///
    T max() @property { return _length - 1 + _offset; }
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
    import std.math : nextDown, isFinite;
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
