/++
SplitMix generator family.

An n-bit splitmix PRNG has an internal n-bit counter and an n-bit increment.
The state is advanced by adding the increment to the counter and output is
the counter's value <a href="#fmix64">mixed</a>. The increment remains constant
for an instance over its lifetime, so each instance of the PRNG needs to
explicitly store its increment only if the `split()` operation is needed.

The first version of splitmix was described in
$(LINK2 http://gee.cs.oswego.edu/dl/papers/oopsla14.pdf, Fast Splittable
Pseudorandom Number Generators) (2014) by Guy L. Steele Jr., Doug Lea, and
Christine H. Flood. A key selling point of the generator was the ability
to $(I split) the sequence:

<blockquote>
"A conventional linear PRNG object provides a generate method that returns
one pseudorandom value and updates the state of the PRNG, but a splittable
PRNG object also has a second operation, split, that replaces the original
PRNG object with two (seemingly) independent PRNG objects, by creating and
returning a new such object and updating the state of the original object.
Splittable PRNG objects make it easy to organize the use of pseudorandom
numbers in multithreaded programs structured using fork-join parallelism."
</blockquote>

However, splitmix $(LINK2 http://xoroshiro.di.unimi.it/splitmix64.c,
is also used) as a non-splittable PRNG with a constant increment that
does not vary from one instance to the next. This cuts the needed space
in half. This module provides predefined fixed-increment $(LREF SplitMix64)
and splittable $(LREF Splittable64).
+/
module mir.random.engine.splitmix;
import std.traits: TemplateOf;

@nogc:
nothrow:
pure:
@safe:

/++
64-bit $(LINK2 https://en.wikipedia.org/wiki/MurmurHash,
MurmurHash3)-style bit mixer, parameterized.

Pattern is:
---
ulong fmix64(ulong x)
{
    x = (x ^ (x >>> shift1)) * m1;
    x = (x ^ (x >>> shift2)) * m2;
    return x ^ (x >>> shift3);
}
---

As long as m1 and m2 are odd each operation is invertible with the consequence
that `fmix64(a) == fmix64(b)` if and only if `(a == b)`.

Good parameters for fmix64 are found empirically. Several sets of
<a href="#murmurHash3Mix">suggested parameters</a> are provided.
+/
ulong fmix64(ulong m1, ulong m2, uint shift1, uint shift2, uint shift3)(ulong x) @nogc nothrow pure @safe
{
    enum bits = ulong.sizeof * 8;
    //Sets of parameters for this function are selected empirically rather than
    //on the basis of theory. Nevertheless we can identify minimum reasonable
    //conditions. Meeting these conditions does not imply that a set of
    //parameters is suitable, but any sets of parameters that fail to meet
    //these conditions are obviously unsuitable.
    static assert(m1 != 1 && m1 % 2 == 1, "Multiplier must be odd number other than 1!");
    static assert(m2 != 1 && m2 % 2 == 1, "Multiplier must be odd number other than 1!");
    static assert(shift1 > 0 && shift1 < bits, "Shift out of bounds!");
    static assert(shift2 > 0 && shift2 < bits, "Shift out of bounds!");
    static assert(shift3 > 0 && shift3 < bits, "Shift out of bounds!");
    static assert(shift1 + shift2 + shift3 >= bits - 1,
        "Shifts must be sufficient for most significant bit to affect least significant bit!");
    static assert(ulong.max / m1 <= m2,
        "Multipliers must be sufficient for least significant bit to affect most significant bit!");

    pragma(inline, true);
    x = (x ^ (x >>> shift1)) * m1;
    x = (x ^ (x >>> shift2)) * m2;
    return x ^ (x >>> shift3);
}

/++
Well known sets of parameters for $(LREF fmix64).
Predefined are murmurHash3Mix and staffordMix01 through staffordMix14.

See David Stafford's 2011 blog entry
$(LINK2 https://zimbry.blogspot.com/2011/09/better-bit-mixing-improving-on.html,
Better Bit Mixing - Improving on MurmurHash3's 64-bit Finalizer).
+/
alias murmurHash3Mix() = .fmix64!(0xff51afd7ed558ccdUL, 0xc4ceb9fe1a85ec53UL, 33, 33, 33);
///ditto
alias staffordMix01() = .fmix64!(0x7fb5d329728ea185UL, 0x81dadef4bc2dd44dUL, 31, 27, 33);
///ditto
alias staffordMix02() = .fmix64!(0x64dd81482cbd31d7UL, 0xe36aa5c613612997UL, 33, 31, 31);
///ditto
alias staffordMix03() = .fmix64!(0x99bcf6822b23ca35UL, 0x14020a57acced8b7UL, 31, 30, 33);
///ditto
alias staffordMix04() = .fmix64!(0x62a9d9ed799705f5UL, 0xcb24d0a5c88c35b3UL, 33, 28, 32);
///ditto
alias staffordMix05() = .fmix64!(0x79c135c1674b9addUL, 0x54c77c86f6913e45UL, 31, 29, 30);
///ditto
alias staffordMix06() = .fmix64!(0x69b0bc90bd9a8c49UL, 0x3d5e661a2a77868dUL, 31, 27, 30);
///ditto
alias staffordMix07() = .fmix64!(0x16a6ac37883af045UL, 0xcc9c31a4274686a5UL, 30, 26, 32);
///ditto
alias staffordMix08() = .fmix64!(0x294aa62849912f0bUL, 0x0a9ba9c8a5b15117UL, 30, 28, 31);
///ditto
alias staffordMix09() = .fmix64!(0x4cd6944c5cc20b6dUL, 0xfc12c5b19d3259e9UL, 32, 29, 32);
///ditto
alias staffordMix10() = .fmix64!(0xe4c7e495f4c683f5UL, 0xfda871baea35a293UL, 30, 32, 33);
///ditto
alias staffordMix11() = .fmix64!(0x97d461a8b11570d9UL, 0x02271eb7c6c4cd6bUL, 27, 28, 32);
///ditto
alias staffordMix12() = .fmix64!(0x3cd0eb9d47532dfbUL, 0x63660277528772bbUL, 29, 26, 33);
///ditto
alias staffordMix13() = .fmix64!(0xbf58476d1ce4e5b9UL, 0x94d049bb133111ebUL, 30, 27, 31);
///ditto
alias staffordMix14() = .fmix64!(0x4be98134a5976fd3UL, 0x3bc0993a5ad19a13UL, 30, 29, 31);
///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    enum ulong x1 = murmurHash3Mix(0x1234_5678_9abc_defeUL);//Mix some number at compile time.
    static assert(x1 == 0xb194_3cfe_a4f7_8f08UL);

    immutable ulong x2 = murmurHash3Mix(0x1234_5678_9abc_defeUL);//Mix some number at run time.
    assert(x1 == x2);//Same result.
}
///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    //Verify all sets of predefined parameters are valid
    //and no two are identical.
    ulong[15] array;
    array[0] = murmurHash3Mix(1);
    array[1] = staffordMix01(1);
    array[2] = staffordMix02(1);
    array[3] = staffordMix03(1);
    array[4] = staffordMix04(1);
    array[5] = staffordMix05(1);
    array[6] = staffordMix06(1);
    array[7] = staffordMix07(1);
    array[8] = staffordMix08(1);
    array[9] = staffordMix09(1);
    array[10] = staffordMix10(1);
    array[11] = staffordMix11(1);
    array[12] = staffordMix12(1);
    array[13] = staffordMix13(1);
    array[14] = staffordMix14(1);
    foreach (i; 1 .. array.length - 1)
        foreach (e; array[0 .. i])
            if (e == array[i])
                assert(0, "fmix64 predefines are not all distinct!");
}

/++
 Canonical fixed increment (non-splittable) SplitMix64 engine.

 64 bits of state, period of `2 ^^ 64`.
 +/
alias SplitMix64 = SplitMixEngine!(staffordMix13, false);
///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random;
    static assert(isSaturatedRandomEngine!SplitMix64);
    auto rng = SplitMix64(1u);
    ulong x = rng.rand!ulong;
    assert(x == 10451216379200822465UL);
}
///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random;
    import std.range.primitives: isRandomAccessRange;
    // SplitMix64 should be both a Mir-style saturated
    // random engine and a Phobos-style uniform RNG
    // and random access range.
    static assert(isPhobosUniformRNG!SplitMix64);
    static assert(isRandomAccessRange!SplitMix64);
    static assert(isSaturatedRandomEngine!SplitMix64);

    SplitMix64 a = SplitMix64(1);
    immutable ulong x = a.front;
    SplitMix64 b = a.save;
    assert (x == a.front);
    assert (x == b.front);
    assert (x == a[0]);

    immutable ulong y = a[1];
    assert(x == a());
    assert(x == b());
    assert(a.front == y);
}

/++
 Canonical splittable (specifiable-increment) SplitMix64 engine.

 128 bits of state, period of `2 ^^ 64`.
 +/
alias Splittable64 = SplitMixEngine!(staffordMix13, true);
///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random;
    static assert(isSaturatedRandomEngine!Splittable64);
    auto rng = Splittable64(1u);
    ulong x = rng.rand!ulong;
    assert(x == 10451216379200822465UL);

    //Split example:
    auto rng1 = Splittable64(1u);
    auto rng2 = rng1.split();

    assert(rng1.rand!ulong == 17911839290282890590UL);
    assert(rng2.rand!ulong == 14201552918486545593UL);
    assert(rng1.increment != rng2.increment);
}
///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random;
    import std.range.primitives: isRandomAccessRange;
    // Splittable64 should be both a Mir-style saturated
    // random engine and a Phobos-style uniform RNG
    // and random access range.
    static assert(isPhobosUniformRNG!Splittable64);
    static assert(isRandomAccessRange!Splittable64);
    static assert(isSaturatedRandomEngine!Splittable64);

    Splittable64 a = Splittable64(1);
    immutable ulong x = a.front;
    Splittable64 b = a.save;
    assert (x == a.front);
    assert (x == b.front);
    assert (x == a[0]);

    immutable ulong y = a[1];
    assert(x == a());
    assert(x == b());
    assert(a.front == y);
}


/++
Default increment used by $(LREF SplitMixEngine).
Defined in $(LINK2 http://gee.cs.oswego.edu/dl/papers/oopsla14.pdf,
Fast Splittable Pseudorandom Number Generators) (2014) as "the odd integer
closest to (2 ^^ 64)/φ, where φ = (1 + √5)/2 is the
$(LINK2 https://en.wikipedia.org/wiki/Golden_ratio, golden ratio)."
In the paper this constant is referred to as "GOLDEN_GAMMA".

From the authors:
<blockquote>
[...] our choice of the odd integer closest to (2 ^^ 64)/φ was based
only on the intuition that it might be a good idea to keep γ values
“well spread out” and the fact that prefixes of the Weyl sequence
generated by 1/φ are known to be “well spread out” [citing vol. 3 of
Knuth's <i>The Art of Computer Programming</i>, exercise 6.4-9]
</blockquote>
+/
enum ulong DEFAULT_SPLITMIX_INCREMENT = 0x9e3779b97f4a7c15UL;
/// ditto
alias GOLDEN_GAMMA = DEFAULT_SPLITMIX_INCREMENT;

/++
Generic SplitMixEngine.

The first parameter $(D_PARAM mixer) should be a explicit instantiation
of $(LREF fmix64) or a predefined parameterization of `fmix64` such as
$(LREF murmurHash3Mix) or $(LREF staffordMix13).

The second parameter is whether the $(LREF split) operation is enabled.
Allows each instance to have a distinct increment, increasing the size
from 64 bits to 128 bits.

The third parameter is the $(LREF default_increment). If the
SplitMixEngine has a fixed increment this value will be used for
each instance. If omitted this paramter defaults to
$(LREF DEFAULT_SPLITMIX_INCREMENT).
+/
struct SplitMixEngine(alias mixer, bool split_enabled = false, OptionalArgs...)
    if ((__traits(compiles, {static assert(__traits(isSame, TemplateOf!(mixer!()), fmix64));})
            || __traits(compiles, {static assert(__traits(isSame, TemplateOf!mixer, fmix64));}))
        && (OptionalArgs.length < 1 || (is(typeof(OptionalArgs[1]) == ulong) && OptionalArgs[1] != DEFAULT_SPLITMIX_INCREMENT))
        && OptionalArgs.length < 2)
{
    @nogc:
    nothrow:
    pure:
    @safe:

    static if (__traits(compiles, {static assert(__traits(isSame, TemplateOf!(mixer!()), fmix64));}))
        alias fmix64 = mixer!();
    else
        alias fmix64 = mixer;

    static if (OptionalArgs.length >= 1)
        /++
         + Either $(LREF DEFAULT_SPLITMIX_INCREMENT) or the optional
         + third argument of this template.
         +/
        enum ulong default_increment = OptionalArgs[1];
    else
        /// ditto
        enum ulong default_increment = DEFAULT_SPLITMIX_INCREMENT;

    static assert(default_increment % 2 != 0, "Increment must be an odd number!");

    /// Marks as a Mir random engine.
    enum bool isRandomEngine = true;
    /// Largest generated value.
    enum ulong max = ulong.max;

    /// Full period (2 ^^ 64).
    enum uint period_pow2 = 64;

    /++
    Whether each instance can set its increment individually.
    Enables the $(LREF split) operation at the cost of increasing
    size from 64 bits to 128 bits.
    +/
    enum bool increment_specifiable = split_enabled;

    /// Current internal state of the generator.
    public ulong state;

    static if (increment_specifiable)
    {
        /++
        Either an enum or a settable value depending on whether `increment_specifiable == true`.
        This should always be an odd number. The paper refers to this as `γ` so it is aliased
        as `gamma`.
        +/
        ulong increment = default_increment;
    }
    else
    {
        /// ditto
        enum ulong increment = default_increment;
    }
    /// ditto
    alias gamma = increment;

    @disable this();
    @disable this(this);

    /++
     + Constructs a $(D SplitMixEngine) generator seeded with $(D_PARAM x0).
     +/
    this()(ulong x0)
    {
        static if (increment_specifiable)
            increment = default_increment;
        this.state = x0;
    }

    /++
     + Constructs a $(D SplitMixEngine) generator seeded with $(D_PARAM x0)
     + using the specified $(D_PARAM increment).
     +
     + Note from the authors (the paper uses `γ` to refer to the _increment):
     +
     + <blockquote>
     + [W]e tested PRNG objects with “sparse” γ values whose representations
     +  have either very few 1-bits or very few 0-bits, and found that such
     + cases produce pseudorandom sequences that DieHarder regards as “weak”
     + just a little more often than usual.
     + </blockquote>
     +
     + As a consequence the provided $(LREF split) function guards against this
     + and also against increments that have long consecutive runs of either 1
     + or 0. However, this constructor only forces $(D_PARAM increment) to be
     + an odd number and performs no other transformation.
     +/
    this()(ulong x0, ulong increment) if (increment_specifiable)
    {
        this.increment = increment | 1UL;
        this.state = x0;
    }

    /// Advances the random sequence.
    ulong opCall()()
    {
        version(LDC) pragma(inline, true);
        else pragma(inline);
        return fmix64(state += increment);
    }
    ///
    @nogc nothrow pure @safe version(mir_random_test) unittest
    {
        auto rnd = SplitMixEngine!staffordMix13(1);
        assert(rnd() == staffordMix13(1 + GOLDEN_GAMMA));
    }

    /++
    Produces a splitmix generator with a different counter-value
    and increment-value than the current generator. Only available
    when <a href="#.SplitMixEngine.increment_specifiable">
    `increment_specifiable == true`</a>.
    +/
    typeof(this) split()() if (increment_specifiable)
    {
        immutable state1 = opCall();
        //Use a different mix function for the increment.
        static if (fmix64(1) == .murmurHash3Mix(1))
            ulong gamma1 = .staffordMix13(state += increment);
        else
            ulong gamma1 = .murmurHash3Mix(state += increment);
        gamma1 |= 1UL;//Ensure increment is odd.
        import core.bitop: popcnt;
        import mir.ndslice.internal: _expect;
        //Approximately 2.15% chance.
        if (_expect(popcnt(gamma1 ^ (gamma1 >>> 1)) < 24, false))
            gamma1 ^= 0xaaaa_aaaa_aaaa_aaaaUL;
        return typeof(this)(state1, gamma1);
    }
    ///
    @nogc nothrow pure @safe version(mir_random_test) unittest
    {
        auto rnd1 = SplitMixEngine!(staffordMix13,true)(1);
        auto rnd2 = rnd1.split();
        assert(rnd1.state != rnd2.state);
        assert(rnd1.increment != rnd2.increment);
        assert(rnd1() != rnd2());
    }

    /++
    Skip forward in the random sequence in $(BIGOH 1) time.
    +/
    void skip()(size_t n)
    {
        state += n * increment;
    }

    /++
    Compatibility with $(LINK2 https://dlang.org/phobos/std_random.html#.isUniformRNG,
    Phobos library methods). Presents this RNG as an InputRange.
    +/
    enum bool isUniformRandom = true;
    /// ditto
    enum ulong min = ulong.min;
    /// ditto
    enum bool empty = false;
    /// ditto
    @property ulong front()() const
    {
        version (LDC) pragma(inline, true);
        else pragma(inline);
        return fmix64(state + increment);
    }
    /// ditto
    void popFront()()
    {
        pragma(inline, true);
        state += increment;
    }
    /// ditto
    void seed()(ulong x0)
    {
        this.__ctor(x0);
    }
    /// ditto
    void seed()(ulong x0, ulong increment) if (increment_specifiable)
    {
        this.__ctor(x0, increment);
    }
    /// ditto
    @property typeof(this) save()() const
    {
        static if (increment_specifiable)
            return typeof(this)(state, increment);
        else
            return typeof(this)(state);
    }
    /// ditto
    ulong opIndex()(size_t n) const
    {
        return fmix64(state + (n + 1) * increment);
    }
    /// ditto
    size_t popFrontN()(size_t n)
    {
        skip(n);
        return n;
    }
    /// ditto
    alias popFrontExactly() = skip;
}
///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    //Can specify engine like this:
    alias RNG1 = SplitMixEngine!staffordMix13;
    alias RNG2 = SplitMixEngine!(fmix64!(0xbf58476d1ce4e5b9UL, 0x94d049bb133111ebUL, 30, 27, 31));

    //Each way of writing it results in the same sequence.
    assert(RNG1(1).opCall() == RNG2(1).opCall());

    //However not each result's name is equally informative.
    static assert(RNG1.stringof == `SplitMixEngine!(staffordMix13, false)`);
    static assert(RNG2.stringof == `SplitMixEngine!(fmix64, false)`);//Doesn't include parameters of fmix64!
}

@nogc nothrow pure @safe version(mir_random_test) unittest
{
    SplitMix64 a = SplitMix64(1);
    a.popFrontExactly(1);
    import std.meta: AliasSeq;
    foreach (f; AliasSeq!(murmurHash3Mix,staffordMix11,staffordMix13))
    {
        auto rnd = SplitMixEngine!(f, true)(0);
        auto rnd2 = rnd.split();
    }
}
