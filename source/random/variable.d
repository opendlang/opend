/++
Authors: Ilya Yaroshenko
Copyright: Copyright, Ilya Yaroshenko 2016-.
License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
+/
module random.variable;

import random;
import std.traits;

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
Returns: `X ~ U(a, b)`
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
        assert(a <= b, "constraint: a < b");
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
    auto gen = Xorshift(1);
    auto rv = UniformVariable!int(-10, 10); // [-10, 11)
    auto x = rv(gen); // random variable
    assert(rv.min == -10);
    assert(rv.max == 10);
}
