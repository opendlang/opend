/++
Authors: Ilya Yaroshenko, documentation is partially based on Phobos.
Copyright: Copyright, Ilya Yaroshenko 2016-.
License:  $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

$(RED This module is available in the extended configuration.)
+/
module mir.random.algorithm;


static if (is(typeof({ import mir.ndslice.slice; })))
{
import mir.math.common;
import mir.primitives;
import mir.random;
import mir.random.ndvariable: isNdRandomVariable;
import mir.random.variable: isRandomVariable;
import std.range.primitives: isInputRange, isForwardRange, popFrontExactly, hasSlicing;
import std.traits;
public import mir.random.engine;
import mir.ndslice.slice: Slice;

/++
Allocates ndslice (vector, matrix, or tensor) and fills it with random numbers.
If no variable is specified each element `e` is generated per `rand!(typeof(e))`.

Params:
    gen = random engine (optional, param or template param)
    var = random variable (optional)
    lengths = one or more lengths
+/
pragma(inline, false)
auto randomSlice(G, D, size_t N)(G gen, D var, size_t[N] lengths...)
    if (N && isSaturatedRandomEngine!G && isRandomVariable!D &&
        (is(G == class) || is(G == interface)))
{
    import mir.ndslice.allocation: uninitSlice;
    alias T = typeof(var(gen));
    auto ret = lengths.uninitSlice!T();
    foreach (ref e; ret.field)
        e = var(gen);
    return ret;
}

/// ditto
pragma(inline, false)
auto randomSlice(G, D, size_t N)(scope ref G gen, D var, size_t[N] lengths...)
    if (N && isSaturatedRandomEngine!G && isRandomVariable!D &&
        is(G == struct))
{
    import mir.ndslice.allocation: uninitSlice;
    alias T = typeof(var(gen));
    auto ret = lengths.uninitSlice!T();
    foreach (ref e; ret.field)
        e = var(gen);
    return ret;
}

/// ditto
auto randomSlice(G, D, size_t N)(scope G* gen, D var, size_t[N] lengths...)
    if (N && isSaturatedRandomEngine!G && isRandomVariable!D &&
        is(G == struct))
{
    return randomSlice(*gen, var, lengths);
}

/// ditto
auto randomSlice(D, size_t N)(D var, size_t[N] lengths...)
    if (N && isRandomVariable!D)
{
    return randomSlice(rne, var, lengths);
}

/// ditto
pragma(inline, false)
auto randomSlice(G, D, size_t N)(G gen, D var, size_t[N] lengths...)
    if (N > 1 && isSaturatedRandomEngine!G && isNdRandomVariable!D &&
        (is(G == class) || is(G == interface)))
{
    import mir.algorithm.iteration: each;
    import mir.ndslice.allocation: uninitSlice;
    import mir.ndslice.topology: pack;
    alias T = D.Element;
    auto ret = lengths.uninitSlice!T();
    ret.pack!1.each!(a => var(gen, a));
    return ret;
}

/// ditto
pragma(inline, false)
auto randomSlice(G, D, size_t N)(scope ref G gen, D var, size_t[N] lengths...)
    if (N > 1 && isSaturatedRandomEngine!G && isNdRandomVariable!D &&
        is(G == struct))
{
    import mir.algorithm.iteration: each;
    import mir.ndslice.allocation: uninitSlice;
    import mir.ndslice.topology: pack;
    alias T = D.Element;
    auto ret = lengths.uninitSlice!T();
    ret.pack!1.each!(a => var(gen, a.field));
    return ret;
}

/// ditto
auto randomSlice(G, D, size_t N)(scope G* gen, D var, size_t[N] lengths...)
    if (N > 1 && isSaturatedRandomEngine!G && isNdRandomVariable!D &&
        is(G == struct))
{
    return randomSlice(*gen, var, lengths);
}

/// ditto
auto randomSlice(D, size_t N)(D var, size_t[N] lengths...)
    if (N > 1 && isNdRandomVariable!D)
{
    return randomSlice(rne, var, lengths);
}

/// ditto
pragma(inline, false)
auto randomSlice(T, G, size_t N)(G gen, size_t[N] lengths...)
    if (N && isSaturatedRandomEngine!G && (is(G == class) || is(G == interface)))
{
    import mir.internal.utility: isComplex;
    import mir.ndslice.allocation: uninitSlice;
    auto ret = lengths.uninitSlice!T();
    foreach (ref e; ret.field)
        static if (isComplex!T)
        {
            alias R = typeof(T.init.re);
            e = gen.rand!R + gen.rand!R * 1fi;
        }
        else
            e = gen.rand!T;
    return ret;
}

/// ditto
pragma(inline, false)
auto randomSlice(T, G, size_t N)(scope ref G gen, size_t[N] lengths...)
    if (N && isSaturatedRandomEngine!G && is(G == struct))
{
    import mir.internal.utility: isComplex;
    import mir.ndslice.allocation: uninitSlice;
    auto ret = lengths.uninitSlice!T();
    foreach (ref e; ret.field)
        static if (isComplex!T)
        {
            alias R = typeof(T.init.re);
            e = gen.rand!R + gen.rand!R * 1fi;
        }
        else
            e = gen.rand!T;
    return ret;
}

/// ditto
auto randomSlice(T, G, size_t N)(scope G* gen, size_t[N] lengths...)
    if (N && isSaturatedRandomEngine!G && is(G == struct))
{
    return randomSlice!T(*gen, lengths);
}

/// ditto
auto randomSlice(T, alias gen = rne, size_t N)(size_t[N] lengths...)
    if (N && isSaturatedRandomEngine!(typeof(gen)))
{
    return randomSlice!T(gen, lengths);
}

/// Random sample from Normal distribution
nothrow @safe version(mir_random_test) unittest
{
    // mir.ndslice package is required for 'randomSlice', it can be found in 'mir-algorithm'
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        import mir.random.variable: normalVar;
        // Using default RNE:
        auto sample = normalVar.randomSlice(10);
        assert(sample.shape == [10]);

        import mir.ndslice.slice: Slice;
        assert(is(typeof(sample) == Slice!(double*)));

        // Using pointer to RNE:
        sample = threadLocalPtr!Random.randomSlice(normalVar, 15);

        // Using local RNE:
        auto rng = Random(12345);
        sample = rng.randomSlice(normalVar, 15);
    }
}

/// Random sample from uniform distribution strictly in the interval `(-1, 1)`.
nothrow @safe version(mir_random_test) unittest
{
    // mir.ndslice package is required for 'randomSlice', it can be found in 'mir-algorithm'
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        import mir.algorithm.iteration: all;
        import mir.math.common: fabs;
        // Using default RNE:
        auto sample = randomSlice!double(10);
        assert(sample.shape == [10]);

        import mir.ndslice.slice: Slice;
        assert(is(typeof(sample) == Slice!(double*)));
        assert(sample.all!(a => a.fabs < 1));

        // Using pointer to RNE:
        sample = threadLocalPtr!Random.randomSlice!double(15);

        // Using local RNE:
        auto rng = Random(12345);
        sample = rng.randomSlice!double(15);

        // For complex numbers:
        auto csample = randomSlice!cdouble(10);
    }
}

/// Random sample from 3D-sphere distribution
nothrow @safe version(mir_random_test) unittest
{
    // mir.ndslice package is required for 'randomSlice', it can be found in 'mir-algorithm'
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        import mir.random.ndvariable: sphereVar;
        // Using default RNE:
        auto sample = sphereVar.randomSlice(10, 3);
        assert(sample.shape == [10, 3]);
        // 10 observations from R_3

        import mir.ndslice.slice: Slice;
        assert(is(typeof(sample) == Slice!(double*, 2)));

        // Using pointer to RNE:
        sample = threadLocalPtr!Random.randomSlice(sphereVar, 15, 3);

        // Using local RNE:
        auto rng = Random(12345);
        sample = rng.randomSlice(sphereVar, 15, 3);
    }
}

/// Random binary data
nothrow @safe version(mir_random_test) unittest
{
    // mir.ndslice package is required for 'randomSlice', it can be found in 'mir-algorithm'
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        // Using default RNE:
        auto sample = randomSlice!ulong(15);
        assert(sample.shape == [15]);

        import mir.ndslice.slice: Slice;
        assert(is(typeof(sample) == Slice!(ulong*)));

        // Using pointer to RNE:
        sample = randomSlice!ulong(threadLocalPtr!Random, 15);

        // Using local RNE:
        auto rng = Random(12345);
        sample = randomSlice!ulong(rng, 15);
    }
}

/++
Random sampling utility.
Complexity:
    O(n)
References:
    Jeffrey Scott Vitter, An efficient algorithm for sequential random sampling
+/
struct VitterStrides
{
    @nogc:
    nothrow:
    pure:
    @safe:

    private enum alphainv = 16;
    private double vprime;
    private size_t N;
    private size_t n;
    private bool hot;

    this(this)
    {
        hot = false;
    }

    /++
    Params:
        N = range length
        n = sample length
    +/
    this()(size_t N, size_t n)
    {
        assert(N >= n);
        this.N = N;
        this.n = n;
    }

    /// Returns: `true` if sample length equals to 0.
    bool empty()() const @property { return n == 0; }
    /// Returns: `N` (remaining sample length)
    size_t length()() const @property { return n; }
    /// Returns: `n` (remaining range length)
    size_t tail()() const @property { return N; }

    /++
    Returns: random stride step (`S`).
        After each call `N` decreases by `S + 1` and `n` decreases by `1`.
    Params:
        gen = random number engine to use
    +/
    sizediff_t opCall(G)(scope ref G gen)
    {
        pragma(inline, false);
        import mir.math.constant: LN2;
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
            return S;
        case 0:
            S = -1;
            goto R;
        }
    }
}

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine.xorshift;
    auto gen = Xorshift(112);
    auto strides = VitterStrides(20, 3);
    size_t s;
    foreach(_; 0..3)
    {
        s += strides(gen) + 1;
        assert(s + strides.tail == 20);
    }
}

/++
Selects a random subsample out of `range`, containing exactly `n` elements.
The order of elements is the same as in the original range.
Returns: $(LREF RandomSample) over the `range`.
Params:
    range = range to sample from
    gen = random number engine to use
    n = number of elements to include in the sample; must be less than or equal to the `range.length`
Complexity: O(n)
+/
auto sample(G, Range)(G gen, Range range, size_t n)
    if(isInputRange!Range && hasLength!Range && (__traits(hasMember, Range, "popFrontExactly") || hasSlicing!Range) &&
        isSaturatedRandomEngine!G &&
        (is(G == class) || is(G == interface)))
{
    return RandomSample!(G, Range)(range, gen, n);
}

/// ditto
auto sample(G, Range)(G* gen, Range range, size_t n)
    if(isInputRange!Range && hasLength!Range && (__traits(hasMember, Range, "popFrontExactly") || hasSlicing!Range) &&
        isSaturatedRandomEngine!G &&
        is(G == struct))
{
    return RandomSample!(G, Range)(range, gen, n);
}

/// ditto
auto sample(G, Range)(ref G gen, Range range, size_t n) @system
    if(isInputRange!Range && hasLength!Range && (__traits(hasMember, Range, "popFrontExactly") || hasSlicing!Range) &&
        isSaturatedRandomEngine!G &&
        is(G == struct))
{
    return RandomSample!(G, Range)(range, gen, n);
}

/// ditto
auto sample(alias gen = rne, Range)(Range range, size_t n)
    if(isInputRange!Range && hasLength!Range && (__traits(hasMember, Range, "popFrontExactly") || hasSlicing!Range) &&
        __traits(compiles, { static assert(isSaturatedRandomEngine!(typeof(gen))); }))
{
    return RandomSample!(Range, gen)(range, n);
}

/// Default RNE
nothrow @safe version(mir_random_test) unittest
{
    // mir.ndslice package is required for 'iota', it can be found in 'mir-algorithm'
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        import mir.ndslice.topology: iota;

        auto sample = 100.iota.sample(7);
        assert(sample.length == 7);
    }
}

///
nothrow @safe version(mir_random_test) unittest
{
    // mir.ndslice package is required for 'iota', it can be found in 'mir-algorithm'
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        import mir.algorithm.iteration: equal;
        import mir.ndslice.topology: iota;
        import mir.random.engine.xorshift;

        // Using pointer to RNE:
        setThreadLocalSeed!Xorshift(112); //Use a known seed instead of a random seed.
        Xorshift* gen_ptr = threadLocalPtr!Xorshift;
        auto sample1 = gen_ptr.sample(100.iota, 7);

        // Using alias of local RNE:
        Xorshift gen = Xorshift(112);
        auto sample2 = 100.iota.sample!gen(7);

        assert(sample1.equal(sample2));
    }
}

@nogc nothrow @safe version(mir_random_test) unittest
{
    // mir.ndslice package is required for 'iota', it can be found in 'mir-algorithm'
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        import mir.algorithm.iteration: equal;
        import mir.ndslice.topology: iota;
        import mir.random.engine.xorshift;
        setThreadLocalSeed!Xorshift(232);//Use a known seed instead of a random seed.
        Xorshift* gen = threadLocalPtr!Xorshift;

        assert(iota(0).equal(gen.sample(iota(0), 0)));
        assert(iota(1).equal(gen.sample(iota(1), 1)));
        assert(iota(2).equal(gen.sample(iota(2), 2)));
        assert(iota(3).equal(gen.sample(iota(3), 3)));
        assert(iota(8).equal(gen.sample(iota(8), 8)));
        assert(iota(1000).equal(gen.sample(iota(1000), 1000)));
    }
}

@nogc nothrow version(mir_random_test) unittest
{
	__gshared size_t[] arr = [1, 2, 3];
	auto res = rne.sample(arr, 1);
}

@nogc nothrow version(mir_random_test) unittest
{
	__gshared size_t[] arr = [1, 2, 3];
    import mir.ndslice.topology: map;
	auto res = rne.sample(arr.map!(a => a + 1), 1);
}

/++
Lazy input or forward range containing a random sample.
$(LREF VitterStrides) is used to skip elements.
Complexity: O(n)
Note: $(UL $(LI The structure holds a pointer to a generator.) $(LI The structure must not be copied (explicitly or implicitly) outside from a function.))
+/
struct RandomSample(G, Range)
{
    private VitterStrides strides;
    static if (is(G == struct))
        private G* gen;
    else
        private G gen;
    private Range range;

    ///
    this()(Range range, G gen, size_t n)
    if (is(G == class) || is(G == interface))
    {
        this.range = range;
        this.gen = gen;
        strides = VitterStrides(range.length, n);
        auto s = strides(gen);
        if(s > 0)
            this.range.popFrontExactly(s);
    }

    /// ditto
    this()(Range range, G* gen, size_t n)
    if (is(G == struct))
    {
        this.range = range;
        this.gen = gen;
        strides = VitterStrides(range.length, n);
        auto s = strides(*this.gen);
        if(s > 0)
            this.range.popFrontExactly(s);
    }

    /// ditto
    this()(Range range, ref G gen, size_t n) @system
    if (is(G == struct))
    {
        this(range, &gen, n);
    }

    /// Range primitives
    size_t length() const @property { return strides.length + 1; }
    /// ditto
    bool empty()() const @property { return length == 0; }
    /// ditto
    auto ref front()() @property { return range.front; }
    /// ditto
    void popFront()() { range.popFrontExactly(strides(gen) + 1); }
    /// ditto
    static if (isForwardRange!Range)
    auto save()() @property { import std.range.primitives: save; return RandomSample(range.save, gen, length); }
}

/// ditto
struct RandomSample(Range, alias gen)
{
    private VitterStrides strides;
    private Range range;
    ///
    this(Range range, size_t n)
    {
        this.range = range;
        strides = VitterStrides(range.length, n);
        auto s = strides(gen);
        if(s > 0)
            this.range.popFrontExactly(s);
    }

    /// Range primitives
    size_t length()() const @property { return strides.length + 1; }
    /// ditto
    bool empty()() const @property { return length == 0; }
    /// ditto
    auto ref front()() @property { return range.front; }
    /// ditto
    void popFront()() { range.popFrontExactly(strides(gen) + 1); }
    /// ditto
    static if (isForwardRange!Range)
    auto save()() @property { import std.range.primitives: save; return RandomSample!(Range,gen)(range.save, length); }
}

/++
Shuffles elements of `range`.
Params:
    gen = random number engine to use
    range = random-access range whose elements are to be shuffled
Complexity: O(range.length)
+/
pragma(inline, false)
void shuffle(G, Iterator)(scope ref G gen, Slice!Iterator range)
    if (isSaturatedRandomEngine!G)
{
    for (; !range.empty; range.popFront)
    {
        auto idx = gen.randIndex(range.length);
        static if (is(typeof(&range[0])))
        {
            import mir.utility: swap;
            swap(range.front, range[idx]);
        }
        else
        {
            auto t = range.front;
            range.front = range[idx];
            range[idx] = t;
        }
    }
}

/// ditto
void shuffle(G, Iterator)(scope G* gen, Slice!Iterator range)
    if (isSaturatedRandomEngine!G)
{
    return .shuffle(*gen, range);
}

/// ditto
void shuffle(Iterator)(Slice!Iterator range)
{
    return .shuffle(rne, range);
}

///
nothrow @safe version(mir_random_test) unittest
{
    // mir.ndslice package is required, it can be found in 'mir-algorithm'
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        import mir.ndslice.allocation: slice;
        import mir.ndslice.topology: iota;
        import mir.ndslice.sorting;

        auto a = iota(10).slice;

        shuffle(a);

        sort(a);
        assert(a == iota(10));
    }
}

///
nothrow @safe version(mir_random_test) unittest
{
    // mir.ndslice package is required, it can be found in 'mir-algorithm'
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        import mir.ndslice.slice: sliced;
        import mir.ndslice.sorting;

        auto a = [1, 2, 3, 4];
        a.sliced.shuffle;

        sort(a);
        assert(a == [1, 2, 3, 4]);
    }
}

/++
Partially shuffles the elements of `range` such that upon returning `range[0..n]`
is a random subset of `range` and is randomly ordered. 
`range[n..r.length]` will contain the elements not in `range[0..n]`.
These will be in an undefined order, but will not be random in the sense that their order after
`shuffle` returns will not be independent of their order before
`shuffle` was called.
Params:
    gen = (optional) random number engine to use
    range = random-access range with length whose elements are to be shuffled
    n = number of elements of `r` to shuffle (counting from the beginning);
        must be less than `r.length`
Complexity: O(n)
+/
pragma(inline, false)
void shuffle(G, Iterator)(scope ref G gen, Slice!Iterator range, size_t n)
    if (isSaturatedRandomEngine!G)
{
    assert(n <= range.length, "n must be <= range.length for shuffle.");
    for (; n; n--, range.popFront)
    {
        auto idx = gen.randIndex(range.length);
        static if (is(typeof(&range[0])))
        {
            import mir.utility: swap;
            swap(range.front, range[idx]);
        }
        else
        {
            auto t = range.front;
            range.front = range[idx];
            range[idx] = t;
        }
    }
}

/// ditto
void shuffle(G, Iterator)(scope G* gen, Slice!Iterator range, size_t n)
    if (isSaturatedRandomEngine!G)
{
    return .shuffle(*gen, range, n);
}

/// ditto
void shuffle(Iterator)(Slice!Iterator range, size_t n)
{
    return .shuffle(rne, range, n);
}

///
nothrow @safe version(mir_random_test) unittest
{
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        import mir.ndslice.allocation: slice;
        import mir.ndslice.topology: iota;
        import mir.ndslice.sorting;

        auto a = iota(10).slice;

        shuffle(a, 4);

        sort(a);
        assert(a == iota(10));
    }
}

// Ensure that the demo code in README.md stays up to date.
// If this unittest needs to be updated due to a change, update
// README.md too!
nothrow @safe version(mir_random_test) unittest
{
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        import mir.random;
        import mir.random.variable: normalVar;
        import mir.random.algorithm: randomSlice;

        auto sample = normalVar.randomSlice(10);

        auto k = sample[$.randIndex];
    }
}

nothrow @safe version(mir_random_test) unittest
{
    static if (is(typeof({ import mir.ndslice.slice; })))
    {
        import mir.random;
        import mir.random.variable: normalVar;
        import mir.random.algorithm: randomSlice;

        // Engines are allocated on stack or global
        auto rng = Random(unpredictableSeed);
        auto sample = rng.randomSlice(normalVar, 10);

        auto k = sample[rng.randIndex($)];
    }
}
}
else
{
    version(unittest) {} else static assert(0, "mir.ndslice is required for mir.random.algorithm, it can be found in 'mir-algorithm' repository.");
}