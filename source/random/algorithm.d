///
module random.algorithm;

import std.traits;

public import random.generator;

/++
Range interface for uniform random bit generators.

Note:
    The structure hold a pointer to a generator.
    The structure must not be copied (explicitly or implicitly) outside from a function.
+/
struct RandomRangeAdaptor(G)
    if (isURBG!G)
{
    private G* _gen;
    private ReturnType!G _val;
    /// Largest generated value.
    enum ReturnType!G max = G.max;
    /// Constructor. Stores the pointer to the `gen` engine.
    this(ref G gen) { _gen = &gen; popFront(); }
    /// Infinity Input Range primitives
    enum empty = false;
    /// ditto
    ReturnType!G front() @property { return _val; }
    /// ditto
    void popFront() { _val = (*_gen)(); }
}

/// ditto
RandomRangeAdaptor!G randomRangeAdaptor(G)(ref G gen)
    if (isURBG!G)
{
    return typeof(return)(gen);
}

///
unittest
{
    import std.range, std.algorithm;
    auto rng = Xorshift(1);
    auto bitSample = rng
        .randomRangeAdaptor
        .filter!(val => val % 2 == 0)
        .map!(val => val % 100)
        .take(5)
        .array;
    assert(bitSample == [58, 30, 86, 16, 76]);
}
