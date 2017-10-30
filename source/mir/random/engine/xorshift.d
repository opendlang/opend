/++
Xorshift and related generators.

Copyright: Copyright Andrei Alexandrescu 2008 - 2009, Masahiro Nakagawa, Ilya Yaroshenko 2016-.
License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Masahiro Nakagawa, Ilya Yaroshenko (rework), Nathan Sashihara
+/
module mir.random.engine.xorshift;

import std.traits;

/++
Xorshift generator using 32bit algorithm.
Implemented according to $(HTTP www.jstatsoft.org/v08/i14/paper, Xorshift RNGs).
$(BOOKTABLE $(TEXTWITHCOMMAS Supporting bits are below, $(D bits) means second parameter of XorshiftEngine.),
 $(TR $(TH bits) $(TH period))
 $(TR $(TD 32)   $(TD 2^32 - 1))
 $(TR $(TD 64)   $(TD 2^64 - 1))
 $(TR $(TD 96)   $(TD 2^96 - 1))
 $(TR $(TD 128)  $(TD 2^128 - 1))
 $(TR $(TD 160)  $(TD 2^160 - 1))
 $(TR $(TD 192)  $(TD 2^192 - 2^32))
)
+/
struct XorshiftEngine(uint bits, uint a, uint b, uint c)
    if (isUnsigned!uint)
{
    ///
    enum isRandomEngine = true;

    static assert(bits == 32 || bits == 64 || bits == 96 || bits == 128 || bits == 160 || bits == 192,
                  "Xorshift supports only 32, 64, 96, 128, 160 and 192 bit versions. "
                  ~ bits.stringof ~ " is not supported.");

  private:

    enum size = bits / 32;

    static if (bits == 32)
        uint[size] seeds_ = [2463534242];
    else static if (bits == 64)
        uint[size] seeds_ = [123456789, 362436069];
    else static if (bits == 96)
        uint[size] seeds_ = [123456789, 362436069, 521288629];
    else static if (bits == 128)
        uint[size] seeds_ = [123456789, 362436069, 521288629, 88675123];
    else static if (bits == 160)
        uint[size] seeds_ = [123456789, 362436069, 521288629, 88675123, 5783321];
    else static if (bits == 192)
    {
        uint[size] seeds_ = [123456789, 362436069, 521288629, 88675123, 5783321, 6615241];
        uint       value_;
    }
    else
    {
        static assert(false, "Mir Error: Xorshift has no instantiation rule for "
                             ~ bits.stringof ~ " bits.");
    }


  public:

    @disable this();
    @disable this(this);

    /// Largest generated value.
    enum uint max = uint.max;

    /**
     * Constructs a $(D XorshiftEngine) generator seeded with $(D_PARAM x0).
     */
    this(uint x0) @safe pure nothrow @nogc
    {
        // Initialization routine from MersenneTwisterEngine.
        foreach (uint i, ref e; seeds_)
        {
            e = x0 = 1812433253U * (x0 ^ (x0 >> 30)) + i + 1;
            if (e == 0)
                e = i + 1;
        }
        opCall();
    }

    /**
     * Advances the random sequence.
     */
    uint opCall() @safe pure nothrow @nogc
    {
        uint temp;

        static if (bits == 32)
        {
            temp      = seeds_[0] ^ (seeds_[0] << a);
            temp      = temp ^ (temp >> b);
            seeds_[0] = temp ^ (temp << c);
            return seeds_[$-1];
        }
        else static if (bits == 64)
        {
            temp      = seeds_[0] ^ (seeds_[0] << a);
            seeds_[0] = seeds_[1];
            seeds_[1] = seeds_[1] ^ (seeds_[1] >> c) ^ temp ^ (temp >> b);
            return seeds_[$-1];
        }
        else static if (bits == 96)
        {
            temp      = seeds_[0] ^ (seeds_[0] << a);
            seeds_[0] = seeds_[1];
            seeds_[1] = seeds_[2];
            seeds_[2] = seeds_[2] ^ (seeds_[2] >> c) ^ temp ^ (temp >> b);
            return seeds_[$-1];
        }
        else static if (bits == 128)
        {
            temp      = seeds_[0] ^ (seeds_[0] << a);
            seeds_[0] = seeds_[1];
            seeds_[1] = seeds_[2];
            seeds_[2] = seeds_[3];
            seeds_[3] = seeds_[3] ^ (seeds_[3] >> c) ^ temp ^ (temp >> b);
            return seeds_[$-1];
        }
        else static if (bits == 160)
        {
            temp      = seeds_[0] ^ (seeds_[0] << a);
            seeds_[0] = seeds_[1];
            seeds_[1] = seeds_[2];
            seeds_[2] = seeds_[3];
            seeds_[3] = seeds_[4];
            seeds_[4] = seeds_[4] ^ (seeds_[4] >> c) ^ temp ^ (temp >> b);
            return seeds_[$-1];
        }
        else static if (bits == 192)
        {
            temp      = seeds_[0] ^ (seeds_[0] >> a);
            seeds_[0] = seeds_[1];
            seeds_[1] = seeds_[2];
            seeds_[2] = seeds_[3];
            seeds_[3] = seeds_[4];
            seeds_[4] = seeds_[4] ^ (seeds_[4] << c) ^ temp ^ (temp << b);
            value_ = seeds_[4] + (seeds_[5] += 362437);
            return value_;
        }
        else
        {
            static assert(false, "Mir Error: Xorshift has no popFront() update for "
                                 ~ bits.stringof ~ " bits.");
        }
    }
}


/++
Define `XorshiftEngine` generators with well-chosen parameters. See each bits examples of "Xorshift RNGs".
`Xorshift` is a `Xorshift128`'s alias because 128bits implementation is mostly used.
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
Template for the `xorshift*` family of generators
described in $(HTTP vigna.di.unimi.it/ftp/papers/xorshift.pdf,
An experimental exploration of Marsaglia’s xorshift generators scrambled)
(Vigna, 2016; draft made public in 2014).
+/
struct XorshiftStarEngine(StateUInt, uint nbits, uint a, uint b, uint c, StateUInt multiplier, OutputUInt = StateUInt)
if (isIntegral!StateUInt && isIntegral!OutputUInt
    && StateUInt.sizeof >= OutputUInt.sizeof
    && nbits >= (StateUInt.sizeof * 8) && nbits % (StateUInt.sizeof * 8) == 0)
{
    ///
    enum isRandomEngine = true;
    /// Largest generated value.
    enum OutputUInt max = OutputUInt.max;

    static assert(multiplier != 1 && multiplier % 2 != 0,
        typeof(this).stringof~": multiplier must be an odd number other than 1!");

    /++
    Note that when StateUInt is the same size as OutputUInt the two lowest bits
    of this generator are
    $(LINK2 https://en.wikipedia.org/wiki/Linear-feedback_shift_register,
    LSFRs), and thus will fail binary rank tests. We suggest to use a sign test
    to extract a random Boolean value, and right shifts to extract subsets of bits.
    +/
    enum bool preferHighBits = true;

  private:
    enum uint N = nbits / (StateUInt.sizeof * 8);
    enum bool usePointer = N > 3;
    StateUInt[N] s = void;
    static if (usePointer)
        uint p;

  public:

    @disable this();
    @disable this(this);

    /**
     * Constructs a $(D XorshiftStarEngine) generator seeded with $(D_PARAM x0).
     */
    this()(Unqual!StateUInt x0) @safe pure nothrow @nogc
    {
        static if (N == 1)
        {
            s[0] = x0;
        }
        else static if (StateUInt.sizeof == ulong.sizeof)
        {
            //Seed using splitmix64 as recommended by Vigna.
            //http://xoroshiro.di.unimi.it/splitmix64.c
            foreach (ref e; s)
            {
                Unqual!StateUInt z = (x0 += cast(Unqual!StateUInt) 0x9e3779b97f4a7c15uL);
                z = (z ^ (z >>> 30)) * cast(Unqual!StateUInt) 0xbf58476d1ce4e5b9uL;
                z = (z ^ (z >>> 27)) * cast(Unqual!StateUInt) 0x94d049bb133111ebuL;
                e = z ^ (z >>> 31);
            }
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

    OutputUInt opCall()() @safe pure nothrow @nogc
    {
        static if (N == 1)
        {
            s[0] ^= s[0] >>> a;
            s[0] ^= s[0] << b;
            s[0] ^= s[0] >>> c;
        }
        else static if (!usePointer)
        {
            auto s1 = s[0];
            s[0 .. (N-1)] = s[1 .. N];
            const s0 = s[N-1];
            s1 ^= s1 << a;
            s[N-1] = s1 ^ s0 ^ (s1 >>> b) ^ (s0 >>> c);
        }
        else
        {
            const s0 = s[p];
            static if ((N & (N - 1)) == 0)
            {
                p = (p + 1) & (N - 1);
            }
            else
            {
                if (++p == N)
                    p = 0;
            }
            auto s1 = s[p];
            s1 ^= s1 << a;
            s[p] = s1 ^ s0 ^ (s1 >>> b) ^ (s0 >>> c);
        }

        static if (!usePointer)
            enum p = N - 1;

        static if (StateUInt.sizeof > OutputUInt.sizeof)
        {
            enum uint rshift = (StateUInt.sizeof - OutputUInt.sizeof) * 8;
            return cast(OutputUInt) ((s[p] * multiplier) >>> rshift);
        }
        else
        {
            return cast(OutputUInt) (s[p] * multiplier);
        }
    }

    static if (nbits == 1024 && N == 16 && a == 31 && b == 11 && c == 30)
    {
        /**
         * This is the jump function for the standard 1024-bit generator.
         * It is equivalent to $(D 2 ^^ 512) invocations of $(D opCall());
         * it can be used to generate $(D 2 ^^ 512) non-overlapping
         * subsequences for parallel computations. This function will only be
         * defined if the shifts are the same as for $(D Xorshift1024StarPhi).
         */
        void jump()() @safe pure nothrow @nogc
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

/++
Define $(D XorshiftStarEngine) with well-chosen parameters
for large simulations on 64-bit machines.

Period of $(D (2 ^^ 1024) - 1), 16-dimensionally equidistributed,
and $(HTTP xoroshiro.di.unimi.it/#quality, faster and statistically
superior) to $(REF_ALTTEXT Mt19937_64, Mt19937_64, mir, random, engine, mersenne_twister)
while occupying significantly less memory. This generator is recommended
for random number generation on 64-bit systems except when $(D 1024 + 32)
bits of state are excessive.

As described in $(HTTP vigna.di.unimi.it/ftp/papers/xorshift.pdf,
An experimental exploration of Marsaglia’s xorshift generators
scrambled) (Vigna, 2016; draft made public in 2014) except with
a better multiplier recommended by the author as of 2017-10-08.
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

@nogc nothrow pure @safe version(mir_random_test) unittest
{
    //Test other sizes of XorshiftStarEngine.
    import mir.random.engine : EngineReturnType, isSaturatedRandomEngine;

    alias XorshiftStar64_32 = XorshiftStarEngine!(ulong,64,12,25,27,2685821657736338717uL,uint);
    //Generates 32 bits of output from 64 bits of state.
    //A nice generator when 64 bit multiplication is fast
    //and more than 64 bits is too much, but the PCG family 
    //of generators probably fills this niche better.
    static assert(isSaturatedRandomEngine!XorshiftStar64_32);
    XorshiftStar64_32 rnd = XorshiftStar64_32(uint(0));
    auto n = rnd();
    assert(n != rnd());
    static assert(is(typeof(n) == uint));
}

/++
$(HTTP xoroshiro.di.unimi.it, xoroshiro128+) generator.

Created in 2016 by David Blackman and Sebastiano Vigna as the successor
to Vigna's extremely popular $(HTTP vigna.di.unimi.it/ftp/papers/xorshiftplus.pdf,
xorshift128+) generator used in the JavaScript engines of
$(HTTP v8project.blogspot.com/2015/12/theres-mathrandom-and-then-theres.html,
Google Chrome), $(LINK2 https://bugzilla.mozilla.org/show_bug.cgi?id=322529#c99,
Mozilla Firefox), $(LINK2 https://bugs.webkit.org/show_bug.cgi?id=151641, Safari),
and $(LINK2 https://github.com/Microsoft/ChakraCore/commit/dbda0182dc0a983dfb37d90c05000e79b6fc75b0,
Microsoft Edge).

<blockquote="http://xoroshiro.di.unimi.it/xoroshiro128plus.c">
This is the successor to xorshift128+. It is the fastest full-period
generator passing BigCrush without systematic failures, but due to the
relatively short period it is acceptable only for applications with a
mild amount of parallelism; otherwise, use a xorshift1024* generator.

Beside passing BigCrush, this generator passes the PractRand test suite
up to (and included) 16TB, with the exception of binary rank tests, as
the lowest bit of this generator is an LSFR. The next bit is not an
LFSR, but in the long run it will fail binary rank tests, too. The
other bits have no LFSR artifacts.

We suggest to use a sign test to extract a random Boolean value, and
right shifts to extract subsets of bits.
</blockquote>

64 bit output. 128 bits of state. Period of $(D (2 ^^ 128) - 1).
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
    LSFR). The next bit is not an LFSR, but in the long run it will fail
    binary rank tests, too. The other bits have no LFSR artifacts.

    We suggest to use a sign test to extract a random Boolean value, and
    right shifts to extract subsets of bits.
    +/
    enum bool preferHighBits = true;

    @disable this();
    @disable this(this);

    /// Constructs an $(D Xoroshiro128Plus) generator seeded with $(D_PARAM x0).
    this()(ulong x0) @nogc nothrow pure @safe
    {
        //Seed using splitmix64 as recommended by Vigna.
        //http://xoroshiro.di.unimi.it/splitmix64.c
        foreach (ref e; s)
        {
            ulong z = (x0 += 0x9e3779b97f4a7c15uL);
            z = (z ^ (z >>> 30)) * 0xbf58476d1ce4e5b9uL;
            z = (z ^ (z >>> 27)) * 0x94d049bb133111ebuL;
            e = z ^ (z >>> 31);
        }
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
    Compatibility with Phobos random interface. Presents this RNG as an InputRange.

    This class disables the default copy constructor and so will only work with
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
    //Test Xoroshiro128Plus can be used as a Phobos-style random.
    import std.random: isSeedable, isPhobosUniformRNG = isUniformRNG;
    static assert(isPhobosUniformRNG!(Xoroshiro128Plus, ulong));
    static assert(isSeedable!(Xoroshiro128Plus, ulong));
    auto gen1 = Xoroshiro128Plus(1);
    auto gen2 = Xoroshiro128Plus(2);
    gen2.seed(1);
    assert(gen1 == gen2);
    immutable a = gen1.front;
    gen1.popFront();
    assert(a == gen2());
    assert(gen1.front == gen2());
}
