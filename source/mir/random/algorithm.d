/++
Authors: Ilya Yaroshenko, documentation is partially based on Phobos.
Copyright: Copyright, Ilya Yaroshenko 2016-.
License:  $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
+/
module mir.random.algorithm;

import std.range.primitives;
import std.traits;
import mir.math.common;

import mir.random;
public import mir.random.engine;

private enum bool isPassByRef(P) = !is(P == struct) && !is(P == union) && !isPointer!P && !isScalarType!P
    && (isFunction!P || isDelegate!P || is(P == class) || is(P == interface));

private ref PointerTarget!Gptr deref(Gptr)(Gptr g) @nogc nothrow pure @safe
    if (isPointer!Gptr && !isPassByRef!Gptr)
{
    pragma(inline, true);
    return *g;
}
private Gptr deref(Gptr)(Gptr g) @nogc nothrow pure @safe
    if (isPassByRef!Gptr && !isPointer!Gptr)
{
    pragma(inline, true);
    return g;
}
nothrow pure @system version(mir_random_test) unittest
{
    uint i = 5;
    uint* i_ptr = &i;
    assert(deref(i_ptr) == 5);

    Object o = new Object();
    assert(o is deref(o));
}

private alias DerefType(Gptr) = typeof(deref(Gptr.init));
@nogc nothrow pure @system version(mir_random_test) unittest
{
    static assert(is(DerefType!(uint*) == uint));
    static assert(is(DerefType!Object == Object));
}

/++
Is the argument either an object (reference type) or a pointer to a struct
that meets $(REF_ALTTEXT mir.random.engine.isSaturatedRandomEngine,
isSaturatedRandomEngine, mir, random, engine)?
+/
public template isReferenceToSaturatedRandomEngine(G)
{
    static if (is(typeof(deref(G.init))))
        ///
        enum bool isReferenceToSaturatedRandomEngine = isSaturatedRandomEngine!(typeof(deref(G.init)));
    else
        ///
        enum bool isReferenceToSaturatedRandomEngine = false;
}

/++
Field interface for random distributions and uniform random bit generators.
It used to construct ndslices in combination with `slicedField` and `slice`.

Note: $(UL $(LI The structure holds a pointer to a generator.) $(LI The structure must not be copied (explicitly or implicitly) outside from a function.))
+/
struct RandomField(G, D, T)
    if (isReferenceToSaturatedRandomEngine!G)
{
    private D _var;
    private G _gen;
    private Unqual!(typeof(_var(deref(_gen)))) _val;
    /++
    Constructor.
    Stores the pointer to the `gen` engine.
    +/
    this()(G gen, D var) { _gen = gen; _var = var; }
    ///
    T opIndex()(size_t)
    {
        import mir.internal.utility: isComplex;
        static if (isComplex!T)
        {
            return _var(deref(_gen)) + _var(deref(_gen)) * 1fi;
        }
        else
        {
            return _var(deref(_gen));
        }

    }
}

/// ditto
struct RandomField(alias gen, D, T)
    if (isSaturatedRandomEngine!(typeof(gen)))
{
    private D _var;
    private Unqual!(typeof(_var(gen))) _val;
    ///
    this()(D var) { _var = var; }
    ///
    T opIndex()(size_t)
    {
        import mir.internal.utility: isComplex;
        static if (isComplex!T)
        {
            return _var(gen) + _var(gen) * 1fi;
        }
        else
        {
            return _var(gen);
        }

    }
}

/// ditto
struct RandomField(G)
    if (isReferenceToSaturatedRandomEngine!G)
{
    private G _gen;
    /++
    Constructor.
    Stores the pointer to the `gen` engine.
    +/
    this()(G gen) { _gen = gen; }
    ///
    Unqual!(EngineReturnType!(DerefType!G)) opIndex()(size_t) { return (deref(_gen))(); }
}

/// ditto
struct RandomField(alias gen)
    if (isSaturatedRandomEngine!(typeof(gen)))
{
    ///
    Unqual!(typeof(gen())) opIndex()(size_t) { return gen(); }
}

/// ditto
RandomField!(G, D, T) field(T, G, D)(ref G gen, D var)
    if (isReferenceToSaturatedRandomEngine!G)
{
    return typeof(return)(gen, var);
}

/// ditto
RandomField!(gen, D, T) field(alias gen, D, T)(D var)
    if (isSaturatedRandomEngine!(typeof(gen)))
{
    return RandomField!(gen,D,T)(var);
}

/// ditto
auto field(G, D)(ref G gen, D var)
    if (isReferenceToSaturatedRandomEngine!G)
{
    return RandomField!(G, D, Unqual!(typeof(var(deref(gen)))))(gen, var);
}

/// ditto
auto field(alias gen, D)(D var)
    if (isSaturatedRandomEngine!(typeof(gen)))
{
    return RandomField!(gen,D,Unqual!(typeof(var(gen))))(var);
}

/// ditto
RandomField!(G) field(G)(ref G gen)
    if (isReferenceToSaturatedRandomEngine!G)
{
    return typeof(return)(gen);
}

/// ditto
RandomField!(gen) field(alias gen)()
    if (isSaturatedRandomEngine!(typeof(gen)))
{
    return RandomField!(gen)();
}

/// Normal distribution
nothrow @safe version(mir_random_test) unittest
{
    import mir.ndslice: slicedField, slice;
    import mir.random;
    import mir.random.variable: NormalVariable;

    immutable seed = unpredictableSeed;

    //Using pointer to RNG:
    auto var = NormalVariable!double(0, 1);
    Random* rng_ptr = new Random(seed);
    auto sample1 = rng_ptr
        .field(var)        // construct random field from standard normal distribution
        .slicedField(5, 3) // construct random matrix 5 row x 3 col (lazy, without allocation)
        .slice;            // allocates data of random matrix

    //Using alias of local RNG:
    var = NormalVariable!double(0, 1);//Reset internal state of NormalVariable.
    Random rng = Random(seed);
    auto sample2 =
         field!rng(var)    // construct random field from standard normal distribution
        .slicedField(5, 3) // construct random matrix 5 row x 3 col (lazy, without allocation)
        .slice;            // allocates data of random matrix    }

    assert(sample1 == sample2);
}

/// Normal distribution for complex numbers
nothrow @safe version(mir_random_test) unittest
{
    import mir.ndslice: slicedField, slice;
    import mir.random;
    import mir.random.variable: NormalVariable;

    immutable seed = unpredictableSeed;

    //Using pointer to RNG:
    auto var = NormalVariable!double(0, 1);
    Random* rng_ptr = new Random(seed);
    auto sample1 = rng_ptr
        .field!cdouble(var)// construct random field from standard normal distribution
        .slicedField(5, 3) // construct random matrix 5 row x 3 col (lazy, without allocation)
        .slice;            // allocates data of random matrix

    //Using alias of local RNG:
    var = NormalVariable!double(0, 1);//Reset internal state of NormalVariable.
    Random rng = Random(seed);
    auto sample2 =
         field!(rng,typeof(var),cdouble)(var)// construct random field from standard normal distribution
        .slicedField(5, 3) // construct random matrix 5 row x 3 col (lazy, without allocation)
        .slice;            // allocates data of random matrix

    assert(sample1 == sample2);
}

/// Bi
nothrow pure @safe version(mir_random_test) unittest
{
    import mir.ndslice: slicedField, slice;
    import mir.random.engine.xorshift;

    //Using pointer to RNG:
    Xorshift* rng_ptr = new Xorshift(1);
    auto bitSample1 = rng_ptr
        .field              // construct random field
        .slicedField(5, 3)  // construct random matrix 5 row x 3 col (lazy, without allocation)
        .slice;             // allocates data of random matrix

    //Using alias of local RNG:
    Xorshift rng = Xorshift(1);
    auto bitSample2 =
         field!rng          // construct random field
        .slicedField(5, 3)  // construct random matrix 5 row x 3 col (lazy, without allocation)
        .slice;             // allocates data of random matrix

    assert(bitSample1 == bitSample2);
}

/++
Range interface for random distributions and uniform random bit generators.

Note: $(UL $(LI The structure holds a pointer to a generator.) $(LI The structure must not be copied (explicitly or implicitly) outside from a function.))
+/
struct RandomRange(G, D)
    if (isReferenceToSaturatedRandomEngine!G)
{
    private D _var;
    private G _gen;
    private Unqual!(typeof(_var(deref(_gen)))) _val;
    /++
    Constructor.
    Stores the pointer to the `gen` engine.
    +/
    this()(G gen, D var) { _gen = gen; _var = var; popFront(); }
    /// Infinity Input Range primitives
    enum empty = false;
    /// ditto
    auto front()() @property { return _val; }
    /// ditto
    void popFront()() { _val = _var(deref(_gen)); }
}

/// ditto
struct RandomRange(alias gen, D)
    if (isSaturatedRandomEngine!(typeof(gen)))
{
    private D _var;
    private Unqual!(typeof(_var(gen))) _val;
    ///
    this()(D var) { _var = var; popFront(); }
    /// Infinity Input Range primitives
    enum empty = false;
    /// ditto
    auto front()() @property { return _val; }
    /// ditto
    void popFront()() { _val = _var(gen); }
}

///ditto
struct RandomRange(G)
    if (isReferenceToSaturatedRandomEngine!G)
{
    private G _gen;
    private EngineReturnType!(DerefType!G) _val;
    /// Largest generated value.
    enum Unqual!(EngineReturnType!(DerefType!G)) max = G.max;
    /++
    Constructor.
    Stores the pointer to the `gen` engine.
    +/
    this()(G gen) { _gen = gen; popFront(); }
    /// Infinity Input Range primitives
    enum empty = false;
    /// ditto
    Unqual!(EngineReturnType!(DerefType!G)) front()() @property { return _val; }
    /// ditto
    void popFront()() { _val = (deref(_gen))(); }
}

///ditto
struct RandomRange(alias gen)
    if (isSaturatedRandomEngine!(typeof(gen)))
{
    private typeof((() => gen())()) _val;
    //Necessary because it's impossible for a struct
    //to have a zero-args ctor that does anything,
    //so we can't just do:
    //
    //this()() { popFront(); } //<-- will never get called
    //
    //this() { popFront(); } <-- will not compile
    private bool _ready;

    /// Largest generated value.
    enum typeof(typeof(gen).max) max = typeof(gen).max;
    /// Infinity Input Range primitives
    enum empty = false;
    /// ditto
    typeof((() => gen())()) front()() @property
    { 
        if (!_ready)
        {
            _val = gen();
            _ready = true;
        }
        return _val;
    }
    /// ditto
    void popFront()()
    {
        if (!_ready)
        {
            _val = gen();
            _ready = true;
        }
        _val = gen();
    }
}

/// ditto
RandomRange!(G, D) range(G, D)(ref G gen, D var)
    if (isReferenceToSaturatedRandomEngine!G)
{
    return typeof(return)(gen, var);
}

/// ditto
RandomRange!(gen, D) range(alias gen, D)(D var)
    if (isSaturatedRandomEngine!(typeof(gen)))
{
    return typeof(return)(var);
}

/// ditto
RandomRange!G range(G)(ref G gen)
    if (isReferenceToSaturatedRandomEngine!G)
{
    return typeof(return)(gen);
}

/// ditto
auto range(alias gen)()
    if (isSaturatedRandomEngine!(typeof(gen)))
{
    return RandomRange!(gen)();
}

///
nothrow @safe version(mir_random_test) unittest
{
    import std.range : take, array;

    import mir.random;
    import mir.random.variable: NormalVariable;

    immutable seed = unpredictableSeed;

    //Using pointer to RNG:
    Random* rng_ptr = new Random(seed);
    auto sample1 = rng_ptr
        .range(NormalVariable!double(0, 1))
        .take(1000)
        .array;

    //Using alias of local RNG:
    Random rng = Random(seed);
    auto sample2 =
         range!rng(NormalVariable!double(0, 1))
        .take(1000)
        .array;

    assert(sample1 == sample2);
}

/// Uniform random bit generation
nothrow pure @safe version(mir_random_test) unittest
{
    import std.stdio;
    import std.range, std.algorithm;
    import std.algorithm: filter;
    import mir.random.engine.xorshift;
    //Using pointer to RNG:
    Xorshift* rng_ptr = new Xorshift(1);
    auto bitSample1 = rng_ptr
        .range
        .filter!"a % 2 == 0"
        .map!"a % 100"
        .take(5)
        .array;
    assert(bitSample1 == [58, 30, 86, 16, 76]);

    //Using alias of RNG:
    Xorshift rng = Xorshift(1);
    auto bitSample2 =
        .range!rng
        .filter!"a % 2 == 0"
        .map!"a % 100"
        .take(5)
        .array;
    assert(bitSample2 == [58, 30, 86, 16, 76]);
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
    this(size_t N, size_t n)
    {
        assert(N >= n);
        this.N = N;
        this.n = n;
    }

    /// Returns: `true` if sample length equals to 0.
    bool empty() @property { return n == 0; }
    /// Returns: `N` (remaining sample length)
    size_t length() @property { return n; }
    /// Returns: `n` (remaining range length)
    size_t tail() @property { return N; }

    /++
    Returns: random stride step (`S`).
        After each call `N` decreases by `S + 1` and `n` decreases by `1`.
    Params:
        gen = random number engine to use
    +/
    sizediff_t opCall(G)(scope ref G gen)
    {
        pragma(inline, false);
        import std.math: LN2;
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
auto sample(Range, G)(Range range, G gen, size_t n)
    if(isInputRange!Range && hasLength!Range && isReferenceToSaturatedRandomEngine!G)
{
    return RandomSample!(Range, G)(range, gen, n);
}
/// ditto
auto sample(Range, alias gen)(Range range, size_t n)
    if(isInputRange!Range && hasLength!Range && isSaturatedRandomEngine!(typeof(gen)))
{
    return RandomSample!(Range, gen)(range, n);
}

///
nothrow pure @safe version(mir_random_test) unittest
{
    import std.range;
    import mir.random.engine.xorshift;
    //Using pointer to RNG:
    Xorshift* gen_ptr = new Xorshift(112);
    auto sample1 = iota(100).sample(gen_ptr, 7);
    size_t sum1 = 0;
    foreach(elem; sample1)
    {
        sum1 += elem;
    }
    //Using alias of local RNG:
    Xorshift gen = Xorshift(112);
    auto sample2 = iota(100).sample!(typeof(iota(100)),gen)(7);
    size_t sum2 = 0;
    foreach(elem; sample2)
    {
        sum2 += elem;
    }

    assert(sum1 == sum2);
}

nothrow pure @safe version(mir_random_test) unittest
{
    import std.algorithm.comparison;
    import std.range;
    import mir.random.engine.xorshift;
    Xorshift* gen = new Xorshift(232);//GC!

    assert(iota(0).equal(iota(0).sample(gen, 0)));
    assert(iota(1).equal(iota(1).sample(gen, 1)));
    assert(iota(2).equal(iota(2).sample(gen, 2)));
    assert(iota(3).equal(iota(3).sample(gen, 3)));
    assert(iota(8).equal(iota(8).sample(gen, 8)));
    assert(iota(1000).equal(iota(1000).sample(gen, 1000)));
}

/++
Lazy input or forward range containing a random sample.
$(LREF VitterStrides) is used to skip elements.
Complexity: O(n)
Note: $(UL $(LI The structure holds a pointer to a generator.) $(LI The structure must not be copied (explicitly or implicitly) outside from a function.))
+/
struct RandomSample(Range, G)
{
    private VitterStrides strides;
    private G gen;
    private Range range;
    ///
    this(Range range, G gen, size_t n)
    {
        this.range = range;
        this.gen = gen;
        strides = VitterStrides(range.length, n);
        auto s = strides(deref(this.gen));
        if(s > 0)
            this.range.popFrontExactly(s);
    }

    /// Range primitives
    size_t length() @property { return strides.length + 1; }
    /// ditto
    bool empty() @property { return length == 0; }
    /// ditto
    auto ref front() @property { return range.front; }
    /// ditto
    void popFront() { range.popFrontExactly(strides(deref(gen)) + 1); }
    /// ditto
    static if (isForwardRange!Range)
    auto save() @property { return RandomSample(range.save, gen, length); }
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
    size_t length() @property { return strides.length + 1; }
    /// ditto
    bool empty() @property { return length == 0; }
    /// ditto
    auto ref front() @property { return range.front; }
    /// ditto
    void popFront() { range.popFrontExactly(strides(gen) + 1); }
    /// ditto
    static if (isForwardRange!Range)
    auto save() @property { return RandomSample!(Range,gen)(range.save, length); }
}

/++
Shuffles elements of `range`.
Params:
    gen = random number engine to use
    range = random-access range whose elements are to be shuffled
Complexity: O(range.length)
+/
void shuffle(Range, G)(scope ref G gen, scope Range range)
    if ((isSaturatedRandomEngine!G || isReferenceToSaturatedRandomEngine!G)
        && isRandomAccessRange!Range && hasLength!Range)
{
    import std.algorithm.mutation : swapAt;
    for (; !range.empty; range.popFront)
    {
        static if (isSaturatedRandomEngine!G)
            range.swapAt(0, gen.randIndex(range.length));
        else
            range.swapAt(0, deref(gen).randIndex(range.length));
    }
}

///
nothrow @safe version(mir_random_test) unittest
{
    import mir.ndslice.allocation: slice;
    import mir.ndslice.topology: iota;
    import mir.ndslice.sorting;

    auto gen = Random(unpredictableSeed);
    auto a = iota(10).slice;

    gen.shuffle(a);

    sort(a);
    assert(a == iota(10));
}


/++
Partially shuffles the elements of `range` such that upon returning `range[0..n]`
is a random subset of `range` and is randomly ordered. 
`range[n..r.length]` will contain the elements not in `range[0..n]`.
These will be in an undefined order, but will not be random in the sense that their order after
`shuffle` returns will not be independent of their order before
`shuffle` was called.
Params:
    gen = random number engine to use
    range = random-access range with length whose elements are to be shuffled
    n = number of elements of `r` to shuffle (counting from the beginning);
        must be less than `r.length`
Complexity: O(n)
+/
void shuffle(Range, G)(scope ref G gen, scope Range range, size_t n)
    if ((isSaturatedRandomEngine!G || isReferenceToSaturatedRandomEngine!G)
        && isRandomAccessRange!Range && hasLength!Range)
{
    import std.algorithm.mutation : swapAt;
    assert(n <= range.length, "n must be <= range.length for shuffle.");
    for (; n; n--, range.popFront)
    {
        static if (isSaturatedRandomEngine!G)
            range.swapAt(0, gen.randIndex(range.length));
        else
            range.swapAt(0, deref(gen).randIndex(range.length));
    }
}

///
nothrow @safe version(mir_random_test) unittest
{
    import mir.ndslice.allocation: slice;
    import mir.ndslice.topology: iota;
    import mir.ndslice.sorting;

    auto gen = Random(unpredictableSeed);
    auto a = iota(10).slice;

    gen.shuffle(a, 4);

    sort(a);
    assert(a == iota(10));
}
