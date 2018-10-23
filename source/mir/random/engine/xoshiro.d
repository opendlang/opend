/++
$(SCRIPT inhibitQuickIndex = 1;)

$(BOOKTABLE $(H2 Generators)

    $(TR $(TH Generator name) $(TH Description))
    $(RROW Xoshiro256StarStar, `xoshiro256**`: all-purpose, rock-solid generator)
    $(RROW Xoshiro128StarStar_32, `xoshiro128**` (32-bit): 32-bit-oriented parameterization of `xoshiro**`)
    $(RROW Xoroshiro128Plus, $(HTTP en.wikipedia.org/wiki/Xoroshiro128%2B, xoroshiro128+): fast, small, and high-quality))

$(BOOKTABLE $(H2 Generic Templates)

    $(TR $(TH Template name) $(TH Description))
    $(RROW XoshiroEngine, `xoshiro**` generator.)
)

Copyright: Copyright Andrei Alexandrescu 2008 - 2009, Masahiro Nakagawa, Ilya Yaroshenko 2016-, Sebastiano Vigna.
License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Masahiro Nakagawa, Ilya Yaroshenko (rework), Nathan Sashihara

Macros:
    WIKI_D = $(HTTP en.wikipedia.org/wiki/$1_distribution, $1 random variable)
    WIKI_D2 = $(HTTP en.wikipedia.org/wiki/$1_distribution, $2 random variable)
    T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
    RROW = $(TR $(TDNW $(LREF $1)) $(TD $+))
+/
module mir.random.engine.xoshiro;

import std.traits;

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
$(HTTP xoshiro.di.unimi.it/xoshiro256starstar.c).
+/
alias Xoshiro256StarStar = XoshiroEngine!(ulong,256,"**",17,45,1,7,5,9);

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random /+: isSaturatedRandomEngine, rand+/;
    import mir.random.engine.xoshiro : Xoshiro256StarStar;
    import mir.math.common: fabs;

    static assert(isRandomEngine!Xoshiro256StarStar);
    static assert(isSaturatedRandomEngine!Xoshiro256StarStar);
    auto gen = Xoshiro256StarStar(1234u);//Seed with constant.
    assert(gen.rand!double.fabs == 0x1.b45d9a0e3ae53p-2);//Generate number from 0 inclusive to 1 exclusive.
    assert(gen.rand!ulong == 15548185570577040190UL);
    //Xoshiro256StarStar has a jump function that is equivalent
    //to 2 ^^ 128 invocations of opCall.
    gen.jump();
    assert(gen.rand!ulong == 10759542936515257968UL);
}

version(mir_random_test) version(unittest)
private void testIsPhobosStyleRandom(RNG)()
{
    //Test RNG can be used as a Phobos-style random.
    alias UIntType = typeof(RNG.init());
    import std.random: isSeedable, isPhobosUniformRNG = isUniformRNG;
    static assert(isPhobosUniformRNG!(RNG, UIntType));
    static assert(isSeedable!(RNG, UIntType));
    auto gen1 = RNG(1);
    auto gen2 = RNG(2);
    gen2.seed(1);
    assert(gen1 == gen2);
    immutable a = gen1.front;
    gen1.popFront();
    assert(a == gen2());
    assert(gen1.front == gen2());
}

@nogc nothrow pure @safe version(mir_random_test) unittest
{
    testIsPhobosStyleRandom!Xoshiro256StarStar();
}

/++
32-bit-oriented `xoshiro**` with 128 bits of state.
In general $(LREF Xoshiro256StarStar) is preferable except if you are
tight on space <em>and</em> know that the generator's output will be
consumed 32 bits at a time. (If you need a generator with 128 bits of
state that is geared towards producing 64 bits at a time,
$(LREF Xoroshiro128Plus) is an option.)
32 bit output. 128 bits of state. Period of `2^^128-1`. 4-dimensionally
equidistributed. None of its bits fail binary rank tests and it passes
tests for Hamming-weight dependencies introduced in the `xoshiro` paper.
From the authors:

<blockquote>
This is xoshiro128** 1.0, our 32-bit all-purpose, rock-solid generator. It
has excellent (sub-ns) speed, a state size (128 bits) that is large
enough for mild parallelism, and it passes all tests we are aware of.
</blockquote>

A `jump()` function is included that skips ahead by `2^^64` calls,
to generate non-overlapping subsequences for parallel computations.

Public domain reference implementation:
$(HTTP xoshiro.di.unimi.it/xoshiro128starstar.c).
+/
alias Xoshiro128StarStar_32 = XoshiroEngine!(uint,128,"**",9,11,0,7,5,9);

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import mir.random : isSaturatedRandomEngine, rand;
    import mir.random.engine.xoshiro : Xoshiro128StarStar_32;

    static assert(isSaturatedRandomEngine!Xoshiro128StarStar_32);
    auto gen = Xoshiro128StarStar_32(1234u);//Seed with constant.
    assert(gen.rand!uint == 1751597702U);
    //Xoshiro128StarStar_32 has a jump function that is equivalent
    //to 2 ^^ 64 invocations of opCall.
    gen.jump();
    assert(gen.rand!uint == 1248004684U);
}

@nogc nothrow pure @safe version(mir_random_test) unittest
{
    testIsPhobosStyleRandom!Xoshiro128StarStar_32();
}

/+
Mixin to initialize an array of ulongs `s` from a single ulong `x0`.
If s.length > 1 this will never initialize `s` to all zeroes. If
s.length == 1 it is up to the caller to check s[0].
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

/+
Mixin to initialize an array of uints `s` from a single uint `x0`.
Ensures no element of `s` is 0.
+/
private enum init_s_from_x0_using_mt32_nozero =
q{
    static assert(is(typeof(s[0]) == uint));
    static assert(is(typeof(x0) == uint));
    // Initialization routine from MersenneTwisterEngine.
    foreach (uint i, ref e; s)
    {
        e = (x0 = 1812433253U * (x0 ^ (x0 >> 30)) + i + 1);
        if (e == 0)
            e = (i + 1);
    }
};

/++
Template for the `xoshiro` family of generators.
See the $(HTTP vigna.di.unimi.it/papers.php#BlVSLPNG, paper)
introducing `xoshiro` and `xoroshiro`.

$(LREF Xoshiro256StarStar) and $(LREF Xoshiro128StarStar_32)
are aliases for `XoshiroEngine` instantiated with recommended
parameters for 64-bit and 32-bit architectures, respectively.

Params:
    UIntType = uint or ulong
    nbits = number of bits (128, 256, 512; must be 4x or 8x bit size of UIntType)
    scrambler = "**" (in the future "+" may be added)
    A = state xor-lshift
    B = state rotate left
    I = index of element used for output
    R = output scramble rotate left
    S = output scramble pre-rotate multiplier (must be odd)
    T = output scramble post-rotate multiplier (must be odd)
+/
struct XoshiroEngine(UIntType, uint nbits, string scrambler,
uint A, uint B, uint I, uint R, UIntType S, UIntType T)
if ((is(UIntType == uint) || is(UIntType == ulong))
    && "**" == scrambler
    && (UIntType.sizeof * 8 * 4 == nbits
        || UIntType.sizeof * 8 * 8 == nbits))
{
    static assert(nbits > 0 && nbits % (UIntType.sizeof * 8) == 0,
        "nbits must be a positive multiple of the size in bits of "
        ~ UIntType.stringof);
    static assert(S % 2 == 1 && S > 1 && T % 2 == 1 && T > 1,
        "scrambler multipliers S and T must be odd numbers > 1");
    static assert(A > 0 && A < UIntType.sizeof*8,
        "left shift A must be non-zero and less than "
        ~UIntType.stringof~".sizeof*8");
    static assert(B > 0 && B < UIntType.sizeof*8
        && R > 0 && R < UIntType.sizeof*8,
        "left rotations B and R must be non-zero and less than "
        ~UIntType.stringof~".sizeof*8");

    ///
    enum isRandomEngine = true;
    /// Largest generated value.
    enum UIntType max = UIntType.max;

    enum bool preferHighBits = "**" != scrambler;

    @disable this();
    @disable this(this);

    /++
    State must not be entirely zero.
    The constructor ensures this condition is met.
    +/
    UIntType[nbits / (UIntType.sizeof * 8)] s;

    /// Initializes the generator with a seed.
    this()(UIntType x0) @nogc nothrow pure @safe
    {
        static if (is(UIntType == ulong))
            mixin(init_s_from_x0_using_splitmix64);
        else static if (is(UIntType == uint))
            mixin(init_s_from_x0_using_mt32_nozero);
        else
            static assert(0, "mir error: no ctor for "
                ~ XoshiroEngine.stringof);
    }

    /++
    Advances the random sequence.

    Returns:
        A uniformly-distributed integer in the closed range
        `[0, UIntType.max]`.
    +/
    UIntType opCall()() @nogc nothrow pure @safe
    {
        import core.bitop : rol;
        const result = rol!(R, UIntType)(s[I] * S) * T;

        const t = s[1] << A;

        static if (s.length == 4)
        {
            s[2] ^= s[0];
            s[3] ^= s[1];
            s[1] ^= s[2];
            s[0] ^= s[3];
        }
        else static if (s.length == 8)
        {
            s[2] ^= s[0];
            s[5] ^= s[1];
            s[1] ^= s[2];
            s[7] ^= s[3];
            s[3] ^= s[4];
            s[4] ^= s[5];
            s[0] ^= s[6];
            s[6] ^= s[7];
        }
        else
        {
            static assert(0, "mir error: no opCall for "
                ~ XoshiroEngine.stringof);
        }

        s[$-2] ^= t;
        s[$-1] = rol!(B, UIntType)(s[$-1]);

        return result;
    }

    static if((is(UIntType == ulong) && nbits == 256 && A == 17 && B == 45))
        private enum _hasJump = true;
    else static if (is(UIntType == ulong) && nbits == 512 && A == 11 && B == 21)
        private enum _hasJump = true;
    else static if (is(UIntType == uint) && nbits == 128 && A == 9 && B == 11)
        private enum _hasJump = true;
    else
        private enum _hasJump = false;

    /++
    Jump functions are defined for certain `UIntType`, `A`, `B`
    combinations:

    <table>
    <tr><td>UIntType</td><td>nbits</td><td>A</td><td>B</td><td>Num. calls skipped</td></tr>
    <tr><td>ulong</td><td>256</td><td>17</td><td>45</td><td>2^^128</td></tr>
    <tr><td>ulong</td><td>512</td><td>11</td><td>21</td><td>2^^256</td></tr>
    <tr><td>uint</td><td>128</td><td>9</td><td>11</td><td>2^^64</td></tr>
    </table>

    These can be used to generate non-overlapping subsequences for parallel
    computations.
    +/
    static if(_hasJump)
    void jump()() @nogc nothrow pure @safe
    {
        static if(is(UIntType == ulong)
                && nbits == 256
                && A == 17 && B == 45)
            static immutable ulong[4] JUMP = [
                0x180ec6d33cfd0aba, 0xd5a61266f0c9392c,
                0xa9582618e03fc9aa, 0x39abdc4529b1661c,
                ];
        else
        static if(is(UIntType == ulong)
                && nbits == 512
                && A == 11 && B == 21)
            static immutable ulong[8] JUMP = [
                0x33ed89b6e7a353f9, 0x760083d7955323be,
                0x2837f2fbb5f22fae, 0x4b8c5674d309511c,
                0xb11ac47a7ba28c25, 0xf1be7667092bcc1c,
                0x53851efdb6df0aaf, 0x1ebbc8b23eaf25db
                ];
        else
        static if(is(UIntType == uint)
                && nbits == 128
                && A == 9 && B == 11)
            static immutable uint[4] JUMP = [
                0x8764000b, 0xf542d2d3,
                0x6fa035c3, 0x77f2db5b
                ];
        else
            static assert(0, "mir error: no jump for "
                ~ XorshiftEngine.stringof);

        UIntType[s.length] sj = 0;
        foreach (i; 0 .. JUMP.length)
            foreach (b; 0 .. (UIntType.sizeof * 8))
            {
                if (JUMP[i] & (UIntType(1) << b))
                {
                    sj[] ^= s[];
                }
                opCall();
            }
        s[] = sj[];
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
    @property UIntType front()() const
    {
        import core.bitop : rol;
        return rol!(R, UIntType)(s[I] * S) * T;
    }
    /// ditto
    void popFront()() { opCall(); }
    /// ditto
    void seed()(UIntType x0)
    {
        this.__ctor(x0);
    }
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
    ulong[2] s;

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

// Verify that code rewriting has not changed algorithm results.
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import std.meta: AliasSeq;
    alias PRNGTypes = AliasSeq!(
        Xoroshiro128Plus, Xoshiro256StarStar, Xoshiro128StarStar_32,
        // (test-only) xoshiro512**
        XoshiroEngine!(ulong,512,"**",11,21,1,7,5,9));
    // Each PRNG has a length 4 array.
    // The first two items are the first two results after seeding with 123456789.
    // If the PRNG has a jump function the next two items in the array are the
    // results after the jump. Otherwise they are 0.
    immutable ulong[4][PRNGTypes.length] expected = [
        // xoroshiro128+
        [11299058612650730663UL, 6338390222986562044UL, 12200862009693591285UL, 8351819689202842404UL],
        // xoshiro256**
        [15127205273500847298UL, 16265768176396019016UL, 3991360392352292703UL, 17616895517737714975UL],
        // xoshiro128** (32-bit)
        [3135079214UL, 1907411621UL, 1969117605UL, 3884474249UL],
        // (test-only) xoshiro512**
        [15127205273500847298UL, 16265768176396019016UL, 12965208988828202353UL, 9889122391782473270UL],
    ];
    foreach (i, PRNGType; PRNGTypes)
    {
        auto rnd = PRNGType(123456789);
        assert(rnd() == expected[i][0]);
        assert(rnd() == expected[i][1]);
        // Test jump functions.
        static if (is(typeof(rnd.jump())))
        {
            rnd.jump();
            assert(rnd() == expected[i][2]);
            assert(rnd() == expected[i][3]);
        }
        else
        {
            static assert(expected[i][2] == 0 && expected[i][3] == 0);
        }
    }
}
