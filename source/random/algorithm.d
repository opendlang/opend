/++
Authors: Ilya Yaroshenko
Copyright: Copyright, Ilya Yaroshenko 2016-.
License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
+/
module random.algorithm;

import std.traits;

import random.variable;
public import random.engine;

/++
Range interface for uniform random bit generators.

Note:
    The structure hold a pointer to a generator.
    The structure must not be copied (explicitly or implicitly) outside from a function.
+/
struct RandomRange(G)
    if (isRandomEngine!G)
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
RandomRange!G randomRange(G)(ref G gen)
    if (isRandomEngine!G)
{
    return typeof(return)(gen);
}

///
unittest
{
    import std.range, std.algorithm;
    import random.engine.xorshift;
    auto rng = Xorshift(1);
    auto bitSample = rng // by reference
        .randomRange
        .filter!(val => val % 2 == 0)
        .map!(val => val % 100)
        .take(5)
        .array;
    assert(bitSample == [58, 30, 86, 16, 76]);
}

/++
Range interface for random variables.

Note:
    The structure hold a pointer to a generator.
    The structure must not be copied (explicitly or implicitly) outside from a function.
+/
struct RandomRange(G, D)
    if (isRandomEngine!G)
{
    private D _var;
    private G* _gen;
    private Unqual!(typeof(_var(*_gen))) _val;
    /// Largest generated value.
    enum ReturnType!G max = G.max;
    /// Constructor. Stores the pointer to the `gen` engine.
    this(ref G gen, D var) { _gen = &gen; _var = var; popFront(); }
    /// Infinity Input Range primitives
    enum empty = false;
    /// ditto
    auto front() @property { return _val; }
    /// ditto
    void popFront() { _val = _var(*_gen); }
}

/// ditto
RandomRange!(G, D) randomRange(G, D)(ref G gen, D var)
    if (isRandomEngine!G)
{
    return typeof(return)(gen, var);
}

///
unittest
{
    import std.range;

    import random;
    import random.variable: NormalVariable;
 
    auto rng = Random(unpredictableSeed);
    auto sample = rng // by reference
        .randomRange(NormalVariable!double(0, 1))
        .take(1000)
        .array;

    //import std.stdio;
    //writeln(sample);
}
