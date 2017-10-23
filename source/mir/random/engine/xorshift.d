/++
Xorshift and related generators.

Copyright: Copyright Andrei Alexandrescu 2008 - 2009, Masahiro Nakagawa, Ilya Yaroshenko 2016-.
License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Masahiro Nakagawa, Ilya Yaroshenko (rework)
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
