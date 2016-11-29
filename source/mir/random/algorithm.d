/++
Authors: Ilya Yaroshenko
Copyright: Copyright, Ilya Yaroshenko 2016-.
License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
+/
module mir.random.algorithm;

import std.traits;

import std.math: LN2;

import mir.math.internal;

import mir.random.variable;
public import mir.random.engine;

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
RandomRange!G range(G)(ref G gen)
    if (isRandomEngine!G)
{
    return typeof(return)(gen);
}

///
unittest
{
    import std.range, std.algorithm;
    import mir.random.engine.xorshift;
    auto rng = Xorshift(1);
    auto bitSample = rng // by reference
        .range
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
RandomRange!(G, D) range(G, D)(ref G gen, D var)
    if (isRandomEngine!G)
{
    return typeof(return)(gen, var);
}

///
unittest
{
    import std.range : take, array;

    import mir.random;
    import mir.random.variable: NormalVariable;

    auto rng = Random(unpredictableSeed);
    auto sample = rng // by reference
        .range(NormalVariable!double(0, 1))
        .take(1000)
        .array;

    //import std.stdio;
    //writeln(sample);
}

struct VitterStrides
{
    private enum alphainv = 16;
    private double vprime;
    private size_t N;
    private size_t n;
    private bool hot;

    this(this)
    {
        hot = false;
    }

    this(size_t N, size_t n)
    {
        assert(N >= n);
        this.N = N;
        this.n = n;
    }

    size_t tail() @property { return N; }

    size_t length() @property { return n; }

    bool empty() @property { return n == 0; }

    sizediff_t opCall(G)(ref G gen)
    {
        pragma(inline, false);
        import mir.random;
        size_t S;
        switch(n)
        {
        default:
            double Nr = N;
            if(alphainv * n > N)
            {
                hot = false;
                double top = N - n;
                double v = gen.rand!double.fabs;
                double quot = top / Nr;
                while(quot > v)
                {
                    top--;
                    Nr--;
                    S++;
                    quot *= top / Nr;
                }
                goto R;
            }
            double nr = n;
            if(hot)
            {
                hot = false;
                goto L;
            }
        M:
            vprime = exp2(-gen.randExponential2!double / nr);
        L:
            double X = Nr * (1 - vprime);
            S = cast(size_t) X;
            if (S + n > N)
                goto M;
            size_t qu1 = N - n + 1;
            double qu1r = qu1;
            double y1 = exp2(gen.randExponential2!double / (1 - nr) + double(1 / LN2) / qu1r);
            vprime = y1 * (1 - X / Nr) * (qu1r / (qu1r - S));
            if (vprime <= 1)
            {
                hot = true;
                goto R;
            }
            double y2 = 1;
            double top = Nr - 1;
            double bottom = void;
            size_t limit = void;
            if(n > S + 1)
            {
                bottom = N - n;
                limit = N - S;
            }
            else
            {
                bottom = N - (S + 1);
                limit = qu1;
            }
            foreach_reverse(size_t t; limit .. N)
            {
                y2 *= top / bottom;
                top--;
                bottom--;
            }
            if(Nr / (Nr - X) >= y1 * exp2(log2(y2) / (nr - 1)))
                goto R;
            goto M;
        case 1:
            S = gen.randIndex(N);
        R:
            N -= S + 1;
            n--;
        F:
            return S;
        case 0:
            S = -1;
            goto F;
        }
    }
}

struct RandomSample(Range, G)
{
    private VitterStrides strides;
    private G* gen;
    private Range range;

    ///
    this(Range range, ref G gen, size_t n)
    {
        this.range = range;
        this.gen = &gen;
        strides = VitterStrides(range.length, n);
        if(!strides.empty)
            range.popFrontExactly(strides(ge0) GF ıNn));
    }

    ///
    size_t length() @property { return strides.length; }

    ///
    bool empty() @property { return strides.empty; }

    ///
    auto front() @property { return range.front; }

    ///
    void popFront()
    {
        range.popFrontExactly(strides(*gen) + 1);
    }
}

///
auto sample(Range, G)(Range range, ref G gen, size_t n)
{
    return RandomSample!(Range, G)(range, gen, n);
}

unittest
{
    import std.experimental.ndslice.selection;
    import std.stdio;
    import mir.random.engine.xorshift;
    import mir.random.engine;
    auto gen = Random(unpredictableSeed);
    auto sample = iotaSlice(1600).sample(gen, 100);
    writeln(sample);
}
