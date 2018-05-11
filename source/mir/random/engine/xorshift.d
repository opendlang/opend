/++
$(SCRIPT inhibitQuickIndex = 1;)

$(BOOKTABLE $(H2 Generators)

    $(TR $(TH Generator name) $(TH Description))
    $(RROW Xoshiro256StarStar, $(HTTP xoshiro.di.unimi.it, xoshiro256*): all-purpose, rock-solid generator)
    $(RROW Xoroshiro128Plus, $(HTTP en.wikipedia.org/wiki/Xoroshiro128%2B, xoroshiro128+): fast, small, and high-quality)
    $(RROW Xorshift1024StarPhi, $(HTTP xoroshiro.di.unimi.it, xorshift1024*φ): when something larger than `xoroshiro128+` is needed)
    $(RROW Xorshift64Star32, xorshift64*/32: internal state of 64 bits and output of 32 bits)
    $(TR $(TD $(LREF Xorshift32) .. $(LREF Xorshift160)) $(TD Basic xorshift generator with `n` bits of state (32, 64, 96, 128, 160)))
    $(RROW Xorshift192, Generator from Marsaglia's paper combining 160-bit xorshift with a counter)
    $(RROW Xorshift, An alias to one of the generators in this package))

$(BOOKTABLE $(H2 Generic Templates)

    $(TR $(TH Template name) $(TH Description))
    $(RROW XorshiftStarEngine, `xorshift*` generator with any word size and any number of bits of state.)
    $(RROW XorshiftEngine, `xorshift` generator with any word size and any number of bits of state.)
)

Copyright: Copyright Andrei Alexandrescu 2008 - 2009, Masahiro Nakagawa, Ilya Yaroshenko 2016-.
License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Masahiro Nakagawa, Ilya Yaroshenko (rework), Nathan Sashihara

Macros:
    WIKI_D = $(HTTP en.wikipedia.org/wiki/$1_distribution, $1 random variable)
    WIKI_D2 = $(HTTP en.wikipedia.org/wiki/$1_distribution, $2 random variable)
    T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
    RROW = $(TR $(TDNW $(LREF $1)) $(TD $+))
+/
module mir.random.engine.xorshift;

import std.traits;

/+
Mixin to initialize an array of ulongs `s` from a single ulong `x0`.
If s.length > 1 this will never initialize `s` to all zeroes. If
s.length == 1 it is up to the caller to check s[0].

Remark from Sebastino Vigna:
<blockquote>
We suggest to use a SplitMix64 to initialize the state of our generators
starting from a 64-bit seed, as research has shown[*] that initialization
must be performed with a generator radically different in nature from the
one initialized to avoid correlation on similar seeds.
</blockquote>
[*] https://dl.acm.org/citation.cfm?doid=1276927.1276928
+/
private enum init_s_from_x0_using_splitmix64 =
q{
    static assert(is(typeof(s[0]) == ulong));
    static assert(is(typeof(x0) == ulong));
    //http://xoroshiro.di.unimi.it/splitmix64.c
    foreach (ref e; s)
    {
        ulong z = (x0 += 0x9e3779b97f4a7c15uL);
        z = (z ^ (z >>> 30)) * 0xbf58476d1ce4e5b9uL;
        z = (z ^ (z >>> 27)) * 0x94d049bb133111ebuL;
        e = z ^ (z >>> 31);
    }
};

/++
Xorshift generator.
Implemented according to $(HTTP www.jstatsoft.org/v08/i14/paper, Xorshift RNGs)
(Marsaglia, 2003) with Sebastino Vigna's optimization for large arrays.

Period is `2 ^^ bits - 1` except for a legacy 192-bit uint version (see
note below).

Params:
    UIntType = Word size of this xorshift generator and the return type
               of `opCall`.
    bits = The number of bits of state of this generator. This must be
           a positive multiple of the size in bits of UIntType. If
           bits is large this struct may occupy slightly more memory
           than this so it can use a circular counter instead of
           shifting the entire array.
    sa = The direction and magnitude of the 1st shift. Positive
         means left, negative means right.
    sb = The direction and magnitude of the 2nd shift. Positive
         means left, negative means right.
    sc = The direction and magnitude of the 3rd shift. Positive
         means left, negative means right.

Note:
For historical compatibility when `bits == 192` and `UIntType` is `uint`
a legacy hybrid PRNG is used consisting of a 160-bit xorshift combined
with a 32-bit counter. This combined generator has period equal to the
least common multiple of `2 ^^ 160 - 1` and `2 ^^ 32`.
+/
struct XorshiftEngine(UIntType, uint bits, int sa, int sb, int sc)
if (isUnsigned!UIntType)
{
    static assert(bits > 0 && bits % (UIntType.sizeof * 8) == 0,
        "bits must be an even multiple of "~UIntType.stringof
        ~".sizeof * 8, not "~bits.stringof~".");

    static assert(!((sa >= 0) == (sb >= 0) && (sa >= 0) >= (sc >= 0))
        && (sa * sb * sc != 0),
        "shifts cannot be zero and cannot all be in same direction: cannot be ["
        ~sa.stringof~", "~sb.stringof~", "~sc.stringof~"].");

    static assert(sa != sb && sb != sc,
        "consecutive shifts with the same magnitude and direction would cancel!");

    // Shift magnitudes.
    private enum a = (sa < 0 ? -sa : sa);
    private enum b = (sb < 0 ? -sb : sb);
    private enum c = (sc < 0 ? -sc : sc);

    // Shift expressions to mix in.
    private enum shiftA(string expr) = `((`~expr~`) `~(sa > 0 ? `<< a)` : ` >>> a)`);
    private enum shiftB(string expr) = `((`~expr~`) `~(sb > 0 ? `<< b)` : ` >>> b)`);
    private enum shiftC(string expr) = `((`~expr~`) `~(sc > 0 ? `<< c)` : ` >>> c)`);

    /// Marker for `mir.random.isRandomEngine`
    enum isRandomEngine = true;
    /// Largest generated value.
    enum UIntType max = UIntType.max;

    /*
     * Marker indicating it's safe to construct from void
     * (i.e. the constructor doesn't depend on the struct
     * being in an initially valid state).
     * Non-public because we don't want to commit to this
     * design.
     */
    package enum bool _isVoidInitOkay = true;

    private
    {
        enum uint N = bits / (UIntType.sizeof * 8);
        // Ugly legacy 192 bit uint hybrid counter/xorshift.
        // Retained for backwards compatibility for now.
        enum bool isLegacy192Bit = UIntType.sizeof == uint.sizeof && bits == 192;
        enum bool usePointer = N > 3 && !isLegacy192Bit;
        static if (usePointer)
            uint p;
        else
            enum uint p = N - 1;
        enum uint initialP = UIntType.sizeof <= uint.sizeof ? N - 1 : 0;
        static if (isLegacy192Bit)
            UIntType value_;
        static if (N == 1)
            union {
                UIntType s0_;
                UIntType[N] s;
            }
        else
            UIntType[N] s = void;
    }

    @disable this();
    @disable this(this);

    /**
     * Constructs a $(D XorshiftEngine) generator seeded with $(D_PARAM x0).
     */
    static if (UIntType.sizeof > uint.sizeof)
    this()(UIntType x0) @nogc nothrow pure @safe
    if (UIntType.sizeof > uint.sizeof) // Repeat condition so it appears in DDoc.
    {
        static if (usePointer)
            p = initialP;
        static if (UIntType.sizeof == ulong.sizeof)
        {
            //Seed using splitmix64 as recommended by Vigna.
            mixin(init_s_from_x0_using_splitmix64);
        }
        else
        {
            //Seed using PCG variant with k bits of state and k bits of output.
            import mir.random.engine.pcg : PermutedCongruentialEngine, rxs_m_xs_forward, stream_t;
            alias RndElementType = Unsigned!(Unqual!UIntType);
            alias RndEngine = PermutedCongruentialEngine!(rxs_m_xs_forward!(RndElementType,RndElementType),stream_t.oneseq,true);
            static assert(is(ReturnType!((ref RndEngine a) => a()) == RndElementType));

            auto rnd = RndEngine(cast(RndElementType) x0);
            foreach (ref e; s)
            {
                e = cast(UIntType) rnd();
            }
        }
        //If N > 1 the internal state cannot be all zeroes by construction.
        //If N == 1 we need to check.
        static if (N == 1)
        {
            if (s[0] == 0)
                s[0] = cast(Unqual!UIntType) 3935559000370003845UL;
        }
    }
    /// ditto
    static if (UIntType.sizeof <= uint.sizeof)
    this()(uint x0) @nogc nothrow pure @safe
    if (UIntType.sizeof <= uint.sizeof) // Repeat condition so it appears in DDoc.
    {
        static if (usePointer)
            p = initialP;
        // Initialization routine from MersenneTwisterEngine.
        foreach (uint i, ref e; s)
        {
            e = cast(UIntType) (x0 = 1812433253U * (x0 ^ (x0 >> 30)) + i + 1);
            if (e == 0)
                e = cast(UIntType) (i + 1);
        }
        opCall();
    }

    /// Advances the random sequence.
    UIntType opCall() @nogc nothrow pure @safe
    {
        static if (isLegacy192Bit)
        {
            import mir.internal.utility: Iota;
            auto x = s[0] ^ mixin(shiftA!`s[0]`);
            foreach (i; Iota!(N - 1))
                s[i] = s[i + 1];
            s[N-2] = s[N-2] ^ mixin(shiftC!`s[N-2]`) ^ x ^ mixin(shiftB!`x`);
            value_ = s[N-2] + (s[N-1] += 362437);
            return value_;
        }
        else static if (N == 1)
        {
            s0_ ^= mixin(shiftA!`s0_`);
            s0_ ^= mixin(shiftB!`s0_`);
            s0_ ^= mixin(shiftC!`s0_`);
            return s0_;
        }
        else static if (N > 1 && !usePointer)
        {
            import mir.internal.utility: Iota;
            auto x = s[0] ^ mixin(shiftA!`s[0]`);
            foreach (i; Iota!(N - 1))
                s[i] = s[i + 1];
            s[N-1] = s[N-1] ^ mixin(shiftC!`s[N-1]`) ^ x ^ mixin(shiftB!`x`);
            return s[N-1];
        }
        else
        {
            const s_N_minus_1 = s[p];
            static if ((N & (N - 1)) == 0)
            {
                p = (p + 1) & (N - 1);
            }
            else
            {
                if (++p >= N)
                    p = 0;
            }
            auto x = s[p];
            x ^= mixin(shiftA!`x`);
            return s[p] = s_N_minus_1 ^ mixin(shiftC!`s_N_minus_1`) ^ x ^ mixin(shiftB!`x`);
        }
    }
}

// Keep this public so code using it still works, but don't include it
// in the documentation.
template XorshiftEngine(uint bits, uint a, uint b, uint c)
{
    // Assume uint and shift directions so the defaults will work.
    static if (bits <= 32)
        alias XorshiftEngine = .XorshiftEngine!(uint, bits, a, -b, c);//left, right, left
    else static if (bits == 192)
        alias XorshiftEngine = .XorshiftEngine!(uint, bits, -a, b, c);//right, left, left
    else
        alias XorshiftEngine = .XorshiftEngine!(uint, bits, a, -b, -c);//left, right, right
}

/++
Define `XorshiftEngine` generators with well-chosen parameters for 32-bit architectures.
`Xorshift` is an alias of one of the generators in this module.
+/
alias Xorshift32  = XorshiftEngine!(32,  13, 17, 15) ;
alias Xorshift64  = XorshiftEngine!(64,  10, 13, 10); /// ditto
alias Xorshift96  = XorshiftEngine!(96,  10, 5,  26); /// ditto
alias Xorshift128 = XorshiftEngine!(128, 11, 8,  19); /// ditto
alias Xorshift160 = XorshiftEngine!(160, 2,  1,  4);  /// ditto
alias Xorshift192 = XorshiftEngine!(192, 2,  1,  4);  /// ditto
alias Xorshift    = Xorshift128;                      /// ditto

///
@safe version(mir_random_test) unittest
{
    import mir.random.engine;
    auto rnd = Xorshift(cast(uint)unpredictableSeed);
    auto num = rnd();

    import std.traits;
    static assert(is(ReturnType!rnd == uint));
    static assert(isSaturatedRandomEngine!Xorshift);
}


/++
Template for the $(HTTP vigna.di.unimi.it/ftp/papers/xorshift.pdf,
xorshift* family of generators) (Vigna, 2016; draft 2014).

<blockquote>
xorshift* generators are very fast, high-quality PRNGs (pseudorandom
number generators) obtained by scrambling the output of a Marsaglia
xorshift generator with a 64-bit invertible multiplier (as suggested by
Marsaglia in his paper). They are an excellent choice for all
non-cryptographic applications, as they are incredibly fast, have long
periods and their output passes strong statistical test suites.
</blockquote>

Params:
    StateUInt = Word size of this xorshift generator.
    nbits = The number of bits of state of this generator. This must be
            a positive multiple of the size in bits of UIntType. If
            nbits is large this struct may occupy slightly more memory
            than this so it can use a circular counter instead of
            shifting the entire array.
    sa = The direction and magnitude of the 1st shift. Positive
              means left, negative means right.
    sb = The direction and magnitude of the 2nd shift. Positive
              means left, negative means right.
    sc = The direction and magnitude of the 3rd shift. Positive
              means left, negative means right.
    multiplier = Output of the internal xorshift engine is multiplied
                 by a constant to eliminate linear artifacts except
                 in the low-order bits. This constant must be an odd
                 number other than 1.
    OutputUInt = Return type of `opCall`. By default same as StateUInt
                 but can be set to a narrower unsigned type in which
                 case the high bits of the multiplication result are
                 returned.

Note:
If `sa`, `sb`, and `sc` are all positive (which if interpreted
as same-direction shifts could not result in a full-period xorshift
generator) the shift directions are instead implicitly
right-left-right when `bits == UIntType.sizeof * 8` and in all
other cases left-right-right. This maintains full compatibility
with older versions of `XorshiftStarEngine` that took all shifts as
unsigned magnitudes.
+/
struct XorshiftStarEngine(StateUInt, uint nbits, int sa, int sb, int sc, StateUInt multiplier, OutputUInt = StateUInt)
if (isUnsigned!StateUInt && isUnsigned!OutputUInt && OutputUInt.sizeof <= StateUInt.sizeof
    && !(sa >0 && sb > 0 && sc > 0))
{
    static assert(multiplier != 1 && multiplier % 2 != 0,
        typeof(this).stringof~": multiplier must be an odd number other than 1!");

    static assert(OutputUInt.sizeof <= StateUInt.sizeof,
        typeof(this).stringof~": OutputUInt cannot be larger than StateUInt!");

    static assert(nbits > 0 && nbits % (StateUInt.sizeof * 8) == 0,
        "bits must be an even multiple of "~StateUInt.stringof
        ~".sizeof * 8, not "~nbits.stringof~".");

    static assert(!((sa >= 0) == (sb >= 0) && (sa >= 0) >= (sc >= 0))
        && (sa * sb * sc != 0),
        "shifts cannot be zero and cannot all be in same direction: cannot be ["
        ~sa.stringof~", "~sb.stringof~", "~sc.stringof~"].");

    static assert(sa != sb && sb != sc,
        "consecutive shifts with the same magnitude and direction would cancel!");

    // Shift magnitudes.
    private enum a = (sa < 0 ? -sa : sa);
    private enum b = (sb < 0 ? -sb : sb);
    private enum c = (sc < 0 ? -sc : sc);

    // Shift expressions to mix in.
    private enum shiftA(string expr) = `((`~expr~`) `~(sa > 0 ? `<< a)` : ` >>> a)`);
    private enum shiftB(string expr) = `((`~expr~`) `~(sb > 0 ? `<< b)` : ` >>> b)`);
    private enum shiftC(string expr) = `((`~expr~`) `~(sc > 0 ? `<< c)` : ` >>> c)`);

    /// Marker for `mir.random.isRandomEngine`
    enum isRandomEngine = true;
    /// Largest generated value.
    enum OutputUInt max = OutputUInt.max;

    /++
    Note that when StateUInt is the same size as OutputUInt the two lowest bits
    of this generator are
    $(LINK2 https://en.wikipedia.org/wiki/Linear-feedback_shift_register,
    LFSRs), and thus will fail binary rank tests.
    To provide some context, $(I every) bit of a Mersenne Twister generator
    (either the 32-bit or 64-bit variant) is an LFSR.

    The `rand!T` functions in `mir.random` automatically will discard
    the low bits when generating output smaller than `OutputUInt` due to
    this generator having `preferHighBits` defined `true`.
    +/
    enum bool preferHighBits = true;

    /*
     * Marker indicating it's safe to construct from void
     * (i.e. the constructor doesn't depend on the struct
     * being in an initially valid state).
     * Non-public because we don't want to commit to this
     * design.
     */
    package enum bool _isVoidInitOkay = true;

  private:
    enum uint N = nbits / (StateUInt.sizeof * 8);
    enum bool usePointer = N > 3;
    StateUInt[N] s = void;
    static if (usePointer)
        uint p;
    else
        enum p = N - 1;
    enum uint initialP = StateUInt.sizeof <= uint.sizeof ? N - 1 : 0;

  public:

    @disable this();
    @disable this(this);

    /**
     * Constructs a $(D XorshiftStarEngine) generator seeded with $(D_PARAM x0).
     */
    this()(StateUInt x0) @safe pure nothrow @nogc
    {
        static if (N == 1)
        {
            s[0] = x0;
        }
        else static if (StateUInt.sizeof == ulong.sizeof)
        {
            //Seed using splitmix64 as recommended by Vigna.
            mixin(init_s_from_x0_using_splitmix64);
        }
        else
        {
            //Seed using PCG variant with k bits of state and k bits of output.
            import mir.random.engine.pcg : PermutedCongruentialEngine, rxs_m_xs_forward, stream_t;
            alias RndElementType = Unsigned!(Unqual!StateUInt);
            alias RndEngine = PermutedCongruentialEngine!(rxs_m_xs_forward!(RndElementType,RndElementType),stream_t.oneseq,true);
            static assert(is(ReturnType!((ref RndEngine a) => a()) == RndElementType));

            auto rnd = RndEngine(cast(RndElementType) x0);
            foreach (ref e; s)
            {
                e = cast(StateUInt) rnd();
            }
        }
        static if (usePointer)
            p = 0;
        //If N > 1 the internal state cannot be all zeroes by construction.
        //If N == 1 we need to check.
        static if (N == 1)
        {
            if (s[0] == 0)
                s[0] = cast(Unqual!StateUInt) 3935559000370003845UL;
        }
    }

    /// Advances the random sequence.
    OutputUInt opCall()() @safe pure nothrow @nogc
    {
        static if (N == 1)
        {
            auto x = s[0];
            x ^= mixin(shiftA!`x`);
            x ^= mixin(shiftB!`x`);
            x ^= mixin(shiftC!`x`);
        }
        else static if (N > 1 && !usePointer)
        {
            import mir.internal.utility: Iota;
            auto x = s[0] ^ mixin(shiftA!`s[0]`);
            foreach (i; Iota!(N - 1))
                s[i] = s[i + 1];
            x = s[N-1] ^ mixin(shiftC!`s[N-1]`) ^ x ^ mixin(shiftB!`x`);
        }
        else
        {
            const s_N_minus_1 = s[p];
            static if ((N & (N - 1)) == 0)
            {
                p = (p + 1) & (N - 1);
            }
            else
            {
                if (++p >= N)
                    p = 0;
            }
            auto x = s[p];
            x ^= mixin(shiftA!`x`);
            x = s_N_minus_1 ^ mixin(shiftC!`s_N_minus_1`) ^ x ^ mixin(shiftB!`x`);
        }
        s[p] = x;

        static if (StateUInt.sizeof > OutputUInt.sizeof)
        {
            enum uint rshift = (StateUInt.sizeof - OutputUInt.sizeof) * 8;
            return cast(OutputUInt) ((x * multiplier) >>> rshift);
        }
        else
        {
            return cast(OutputUInt) (x * multiplier);
        }
    }

    static if (nbits == 1024 && N == 16 && sa == 31 && sb == -11 && sc == -30)
    {
        /**
         * This is the jump function for the standard 1024-bit generator.
         * It is equivalent to $(D 2 ^^ 512) invocations of $(D opCall());
         * it can be used to generate $(D 2 ^^ 512) non-overlapping
         * subsequences for parallel computations. This function will only be
         * defined if the shifts are the same as for $(D Xorshift1024StarPhi).
         */
        void jump()() @safe pure nothrow @nogc
        if (nbits == 1024 && N == 16 && sa == 31 && sb == -11 && sc == -30)
        {
            static immutable ulong[16] JUMP = [0x84242f96eca9c41duL,
                0xa3c65b8776f96855uL, 0x5b34a39f070b5837uL, 0x4489affce4f31a1euL,
                0x2ffeeb0a48316f40uL, 0xdc2d9891fe68c022uL, 0x3659132bb12fea70uL,
                0xaac17d8efa43cab8uL, 0xc4cb815590989b13uL, 0x5ee975283d71c93buL,
                0x691548c86c1bd540uL, 0x7910c41d10a1e6a5uL, 0x0b5fc64563b3e2a8uL,
                0x047f7684e9fc949duL, 0xb99181f2d8f685cauL, 0x284600e3f30e38c3uL];
            ulong[16] t;
            foreach (jump; JUMP)
            {
                foreach (uint b; 0 .. 64)
                {
                    if (0 != (jump & (ulong(1) << b)))
                    {
                        foreach (j, ref e; t)
                            e ^= s[(j + p) & 15];
                    }
                    opCall();
                }
            }
            foreach (j, e; t)
                s[(j + p) & 15] = cast(StateUInt) e;
        }
    }
}
/// ditto
template XorshiftStarEngine(StateUInt, uint nbits, int sa, int sb, int sc, StateUInt multiplier, OutputUInt = StateUInt)
if (isUnsigned!StateUInt && isUnsigned!OutputUInt && OutputUInt.sizeof <= StateUInt.sizeof
    && (sa >0 && sb > 0 && sc > 0))
{
    static if (nbits == StateUInt.sizeof * 8)
        alias XorshiftStarEngine = .XorshiftStarEngine!(StateUInt, nbits, -sa, sb, -sc, multiplier, OutputUInt);
    else
        alias XorshiftStarEngine = .XorshiftStarEngine!(StateUInt, nbits, sa, -sb, -sc, multiplier, OutputUInt);
}

/++
Define $(D XorshiftStarEngine) with well-chosen parameters
for large simulations on 64-bit machines.

Period of $(D (2 ^^ 1024) - 1), 16-dimensionally equidistributed,
and $(HTTP xoroshiro.di.unimi.it/#quality, faster and statistically
superior) to $(REF_ALTTEXT Mt19937_64, Mt19937_64, mir, random, engine, mersenne_twister)
while occupying significantly less memory. This generator is recommended
for random number generation on 64-bit systems except when $(D 1024 + 32)
bits of state are excessive.

As described by Vigna in the 2014 draft of
$(HTTP vigna.di.unimi.it/ftp/papers/xorshift.pdf, his paper published in
2016 detailing the xorshift* family), except with a better multiplier recommended by the
author as of 2017-10-08.

Public domain reference implementation:
$(HTTP xoroshiro.di.unimi.it/xorshift1024star.c).
+/
alias Xorshift1024StarPhi = XorshiftStarEngine!(ulong,1024,31,11,30,0x9e3779b97f4a7c13uL);

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine : EngineReturnType, isSaturatedRandomEngine;
    auto rnd = Xorshift1024StarPhi(12434UL);
    auto num = rnd();
    assert(num != rnd());

    static assert(is(EngineReturnType!Xorshift1024StarPhi == ulong));
    static assert(isSaturatedRandomEngine!Xorshift1024StarPhi);

    //Xorshift1024StarPhi has a jump function that is equivalent
    //to 2 ^^ 512 invocations of opCall.
    rnd.jump();
    num = rnd();
    assert(num != rnd());
}

/++
Generates 32 bits of output from 64 bits of state. A fast generator
with excellent statistical properties for memory-constrained situations
where more than 64 bits of state would be too much and generating
only 32 bits with each `opCall` will not cause a slowdown. Today
$(REF_ALTTEXT SplitMix64, SplitMix64, mir, random, engine, splitmix)
(which has 64 bit output) or $(REF_ALTTEXT pcg32_oneseq, pcg32_oneseq,
mir, random, engine, pcg) from the PCG family of generators might fill
this niche better but the wide popularity of this generator and its
$(HTTP www.pcg-random.org/posts/other-good-options.html#xorshift42-12864-andor-xorshift42-6432,
continued recommendation by some) in 2017 merit its inclusion in a PRNG
library.

Note that `xorshift64*/32` is slower than `xorshift1024*` even when only
32 bits of output are needed at a time.
<a href="https://web.archive.org/web/20151209100332/http://xorshift.di.unimi.it:80/">
Per Vigna:</a>
<blockquote>
The three xor/shifts of a `xorshift64*` generator must be executed sequentially,
as each one is dependent on the result of the previous one. In a `xorshift1024*`
generator two of the xor/shifts are completely independent and can be
parallelized internally by the CPU.
</blockquote>

<a href="https://web.archive.org/web/20151011045529/http://xorshift.di.unimi.it:80/xorshift64star.c">
Public domain xorshift64* reference implementation (Internet Archive).</a>
+/
alias Xorshift64Star32 = XorshiftStarEngine!(ulong,64,12,25,27,2685821657736338717uL,uint);
///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine : isSaturatedRandomEngine;
    static assert(isSaturatedRandomEngine!Xorshift64Star32);
    Xorshift64Star32 rnd = Xorshift64Star32(123456789);
    uint x = rnd();
    assert(x == 3988833114);
}

/++
$(HTTP xoroshiro.di.unimi.it, xoroshiro128+) (XOR/rotate/shift/rotate) generator.
64 bit output. 128 bits of state. Period of $(D (2 ^^ 128) - 1).

Created in 2016 by David Blackman and Sebastiano Vigna as the successor
to Vigna's extremely popular $(HTTP vigna.di.unimi.it/ftp/papers/xorshiftplus.pdf,
xorshift128+) generator used in the JavaScript engines of
$(HTTP v8project.blogspot.com/2015/12/theres-mathrandom-and-then-theres.html,
Google Chrome), $(LINK2 https://bugzilla.mozilla.org/show_bug.cgi?id=322529#c99,
Mozilla Firefox), $(LINK2 https://bugs.webkit.org/show_bug.cgi?id=151641, Safari),
and $(LINK2 https://github.com/Microsoft/ChakraCore/commit/dbda0182dc0a983dfb37d90c05000e79b6fc75b0,
Microsoft Edge). From the authors:

<blockquote>
This is the successor to xorshift128+. It is the fastest full-period
generator passing BigCrush without systematic failures, but due to the
relatively short period it is acceptable only for applications with a
mild amount of parallelism; otherwise, use a xorshift1024* generator.

Beside passing BigCrush, this generator passes the PractRand test suite
up to (and included) 16TB, with the exception of binary rank tests, as
the lowest bit of this generator is an LFSR. The next bit is not an
LFSR, but in the long run it will fail binary rank tests, too. The
other bits have no LFSR artifacts.

We suggest to use a sign test to extract a random Boolean value, and
right shifts to extract subsets of bits.
</blockquote>

Public domain reference implementation:
$(HTTP xoroshiro.di.unimi.it/xoroshiro128plus.c).
+/
struct Xoroshiro128Plus
{
    ///
    enum isRandomEngine = true;
    /// Largest generated value.
    enum ulong max = ulong.max;

    /++
    State must not be entirely zero.
    The constructor ensures this condition is met.
    +/
    ulong[2] s = void;

    /++
    The lowest bit of this generator is an
    $(LINK2 https://en.wikipedia.org/wiki/Linear-feedback_shift_register,
    LFSR). The next bit is not an LFSR, but in the long run it will fail
    binary rank tests, too. The other bits have no LFSR artifacts.
    To provide some context, $(I every) bit of a Mersenne Twister generator
    (either the 32-bit or 64-bit variant) is an LFSR.

    The `rand!T` functions in `mir.random` automatically will discard
    the low bits when generating output smaller than `ulong` due to
    this generator having `preferHighBits` defined `true`.
    +/
    enum bool preferHighBits = true;

    @disable this();
    @disable this(this);

    /// Constructs an $(D Xoroshiro128Plus) generator seeded with $(D_PARAM x0).
    this()(ulong x0) @nogc nothrow pure @safe
    {
        //Seed using splitmix64 as recommended by Vigna.
        mixin(init_s_from_x0_using_splitmix64);
    }

    /// Advances the random sequence.
    ulong opCall()()
    {
        //Public domain implementation:
        //http://xoroshiro.di.unimi.it/xoroshiro128plus.c
        import core.bitop : rol;
        immutable s0 = s[0];
        auto s1 = s[1];
        immutable result = s0 + s1;

        s1 ^= s0;
        s[0] = rol!(55,ulong)(s0) ^ s1 ^ (s1 << 14); // a, b
        s[1] = rol!(36,ulong)(s1); // c

        return result;
    }

    /++
    This is the jump function for the generator. It is equivalent
    to 2^^64 calls to $(D opCall()); it can be used to generate 2^^64
    non-overlapping subsequences for parallel computations.
    +/
    void jump()() @nogc nothrow pure @safe
    {
        static immutable ulong[2] JUMP = [ 0xbeac0467eba5facbUL, 0xd86b048b86aa9922UL ];

        ulong s0 = 0;
        ulong s1 = 0;
        foreach (jump; JUMP)
        {
            foreach (b; 0 .. 64)
            {
                if (jump & (1uL << b))
                {
                    s0 ^= s[0];
                    s1 ^= s[1];
                }
                opCall();
            }
        }
        s[0] = s0;
        s[1] = s1;
    }


    /++
    Compatibility with $(LINK2 https://dlang.org/phobos/std_random.html#.isUniformRNG,
    Phobos library methods). Presents this RNG as an InputRange.

    This struct disables its default copy constructor and so will only work with
    Phobos functions that "do the right thing" and take RNGs by reference and
    do not accidentally make implicit copies.
    +/
    enum bool isUniformRandom = true;
    /// ditto
    enum typeof(this.max) min = typeof(this.max).min;
    /// ditto
    enum bool empty = false;
    /// ditto
    @property ulong front()() const { return s[0] + s[1]; }
    /// ditto
    void popFront()() { opCall(); }
    /// ditto
    void seed()(ulong x0)
    {
        this.__ctor(x0);
    }
}

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random.engine : isSaturatedRandomEngine;
    static assert(isSaturatedRandomEngine!Xoroshiro128Plus);
    auto gen = Xoroshiro128Plus(1234u);//Seed with constant.
    assert(gen() == 5968561782418604543);//Generate number.
    foreach (i; 0 .. 8)
        gen();
    assert(gen() == 8335647863237943914uL);
    //Xoroshiro128Plus has a jump function that is equivalent
    //to 2 ^^ 64 invocations of opCall.
    gen.jump();
    auto n = gen();
}

@nogc nothrow pure @safe version(mir_random_test) unittest
{
    testIsPhobosStyleRandom!Xoroshiro128Plus();
}

version(mir_random_test) version(unittest)
private void testIsPhobosStyleRandom(RNG)()
{
    //Test RNG can be used as a Phobos-style random.
    import std.random: isSeedable, isPhobosUniformRNG = isUniformRNG;
    import std.random: isSeedable, isPhobosUniformRNG = isUniformRNG;
    static assert(isPhobosUniformRNG!(RNG, ulong));
    static assert(isSeedable!(RNG, ulong));
    auto gen1 = RNG(1);
    auto gen2 = RNG(2);
    gen2.seed(1);
    assert(gen1 == gen2);
    immutable a = gen1.front;
    gen1.popFront();
    assert(a == gen2());
    assert(gen1.front == gen2());
}

/++
`xoshiro256**` (XOR/shift/rotate) as described in $(HTTP arxiv.org/abs/1805.01407,
Scrambled linear pseudorandom number generators) (Blackman and Vigna, 2018).
64 bit output. 256 bits of state. Period of `2^^256-1`. 4-dimensionally
equidistributed. It is 15% slower than `xoroshiro128+` but none of its
bits fail binary rank tests and it passes tests for Hamming-weight
dependencies introduced in the linked paper. From the authors:

<blockquote>
This is xoshiro256** 1.0, our all-purpose, rock-solid generator. It has
excellent (sub-ns) speed, a state (256 bits) that is large enough for
any parallel application, and it passes all tests we are aware of.
</blockquote>

A `jump()` function is included that skips ahead by `2^^128` calls,
to generate non-overlapping subsequences for parallel computations.

Public domain reference implementation:
$(HTTP http://xoshiro.di.unimi.it/xoshiro256starstar.c).
+/
struct Xoshiro256StarStar
{
    ///
    enum isRandomEngine = true;
    /// Largest generated value.
    enum ulong max = ulong.max;

    /++
    No bits of this generator's output fail any tests, but
    the high bits provably have greater linear complexity
    than the low bits.
    +/
    enum bool preferHighBits = true;

    @disable this();
    @disable this(this);

    /++
    State must not be entirely zero.
    The constructor ensures this condition is met.
    +/
    ulong[4] s = void;


    /// Initializes the generator with a 64-bit seed.
    this(ulong x0) @nogc nothrow pure @safe
    {
        //Seed using splitmix64 as recommended by Vigna.
        mixin(init_s_from_x0_using_splitmix64);
    }

    /++
    Advances the random sequence.

    Returns:
        A uniformly-distributed integer in the closed range
        `[0, OutputUInt.max]`.
    +/
    ulong opCall() @nogc nothrow pure @safe
    {
        import core.bitop : rol;
        const result_starstar = rol!(7, ulong)(s[1] * 5) * 9;

        const t = s[1] << 17;

        s[2] ^= s[0];
        s[3] ^= s[1];
        s[1] ^= s[2];
        s[0] ^= s[3];

        s[2] ^= t;
        s[3] = rol!(45, ulong)(s[3]);

        return result_starstar;
    }

    /++
    This is the jump function for the generator. It is equivalent
    to `2^^128` calls to next(); it can be used to generate `2^^128`
    non-overlapping subsequences for parallel computations.
    +/
    void jump()() @nogc nothrow pure @safe
    {
        static immutable ulong[4] JUMP = [
            0x180ec6d33cfd0aba, 0xd5a61266f0c9392c,
            0xa9582618e03fc9aa, 0x39abdc4529b1661c,
            ];

        ulong s0 = 0;
        ulong s1 = 0;
        ulong s2 = 0;
        ulong s3 = 0;
        foreach (i; 0 .. JUMP.length)
            foreach (b; 0 .. 64)
            {
                if (JUMP[i] & (1UL << b))
                {
                    s0 ^= s[0];
                    s1 ^= s[1];
                    s2 ^= s[2];
                    s3 ^= s[3];
                }
                opCall();
            }
        s[0] = s0;
        s[1] = s1;
        s[2] = s2;
        s[3] = s3;
    }

    /++
    Compatibility with $(LINK2 https://dlang.org/phobos/std_random.html#.isUniformRNG,
    Phobos library methods). Presents this RNG as an InputRange.

    This struct disables its default copy constructor and so will only work with
    Phobos functions that "do the right thing" and take RNGs by reference and
    do not accidentally make implicit copies.
    +/
    enum bool isUniformRandom = true;
    /// ditto
    enum typeof(this.max) min = typeof(this.max).min;
    /// ditto
    enum bool empty = false;
    /// ditto
    @property ulong front()() const
    {
        import core.bitop : rol;
        return rol!(7, ulong)(s[1] * 5) * 9;
    }
    /// ditto
    void popFront()() { opCall(); }
    /// ditto
    void seed()(ulong x0)
    {
        this.__ctor(x0);
    }
}

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random : isSaturatedRandomEngine, rand;
    import mir.random.engine.xorshift : Xoshiro256StarStar;
    import mir.math.common: fabs;

    static assert(isSaturatedRandomEngine!Xoshiro256StarStar);
    auto gen = Xoshiro256StarStar(1234u);//Seed with constant.
    assert(gen.rand!double.fabs == 0x1.b45d9a0e3ae53p-2);//Generate number from 0 inclusive to 1 exclusive.
    assert(gen.rand!double.fabs == 0x1.640660c19433ep-3);
    //Xoshiro256StarStar has a jump function that is equivalent
    //to 2 ^^ 128 invocations of opCall.
    gen.jump();
    assert(gen.rand!uint == 2505151307);
}


@nogc nothrow pure @safe version(mir_random_test) unittest
{
    testIsPhobosStyleRandom!Xoshiro256StarStar();
}

// Verify that code rewriting has not changed algorithm results.
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import std.meta: AliasSeq;
    alias PRNGTypes = AliasSeq!(
        Xorshift32, Xorshift64, Xorshift128,
        XorshiftEngine!(ulong, 64, -12, 25, -27),
        XorshiftEngine!(ulong, 128, 23, -18, -5),
        XorshiftEngine!(ulong, 1024, 31, -11, -30),
        Xorshift64Star32, Xorshift1024StarPhi, Xoroshiro128Plus,
        Xoshiro256StarStar,);
    immutable ulong[2][PRNGTypes.length] expected = [
        // xorshift 32, 64, 128 with uint words
        [2731401742UL, 136850760UL],
        [2549865778UL, 1115114167UL],
        [894632230UL, 3350973606UL],
        // xorshift 64, 128, 1024 with ulong words
        [2224398112249372979UL, 5942945680377883074UL],
        [4028400848060651388UL, 13895196393457319541UL],
        [4907124740424754446UL, 15368750743520076923UL],
        // xorshift*64/32, xorshift1024*, xoroshiro128+
        [3988833114UL, 2123560186UL],
        [13627154139265517578UL, 4343624370592319777UL],
        [11299058612650730663UL, 6338390222986562044UL],
        // xoshiro256**
        [15127205273500847298UL, 16265768176396019016UL],
    ];
    foreach (i, PRNGType; PRNGTypes)
    {
        auto rnd = PRNGType(123456789);
        foreach (x; expected[i][])
            assert(x == rnd());
        // Test jump functions.
        static if (is(PRNGType == Xoroshiro128Plus))
        {
            rnd.jump();
            assert(rnd() == 12200862009693591285UL);
            assert(rnd() == 8351819689202842404UL);
        }
        else static if(is(PRNGType == Xorshift1024StarPhi))
        {
            rnd.jump();
            assert(rnd() == 12213380293688671629UL);
            assert(rnd() == 12219340912072210038UL);
        }
        else static if (is(PRNGType == Xoshiro256StarStar))
        {
            rnd.jump();
            assert(rnd() == 3991360392352292703UL);
            assert(rnd() == 17616895517737714975UL);
        }
    }
}
