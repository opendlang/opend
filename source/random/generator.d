/**
Facilities for random number generation.

The new-style generator objects hold their own state so they are
immune of threading issues. The generators feature a number of
well-known and well-documented methods of generating random
numbers. An overall fast and reliable means to generate random numbers
is the $(D_PARAM Mt19937) generator, which derives its name from
"$(LUCKY Mersenne Twister) with a period of 2 to the power of
19937". In memory-constrained situations, $(LUCKY linear congruential)
generators such as $(D MinstdRand0) and $(D MinstdRand) might be
useful. The standard library provides an alias $(D_PARAM Random) for
whichever generator it considers the most fit for the target
environment.

Source:    $(PHOBOSSRC std/_random.d)

Macros:

Copyright: Copyright Andrei Alexandrescu 2008 - 2009, Joseph Rushton Wakeling 2012, Ilya Yaroshenko 2016-.
License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: $(HTTP erdani.org, Andrei Alexandrescu)
           Masahiro Nakagawa (Xorshift random generator) Ilya Yaroshenko (rework)
Phobos_Credits:   The entire random number library architecture is derived from the
           excellent $(HTTP open-std.org/jtc1/sc22/wg21/docs/papers/2007/n2461.pdf, C++0X)
           random number facility proposed by Jens Maurer and contributed to by
           researchers at the Fermi laboratory (excluding Xorshift).
*/
/*
         Copyright Andrei Alexandrescu 2008 - 2009.
Distributed under the Boost Software License, Version 1.0.
   (See accompanying file LICENSE_1_0.txt or copy at
         http://www.boost.org/LICENSE_1_0.txt)
*/
module random.generator;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

import std.traits;

version(unittest)
{
    static import std.meta;
    package alias PseudoRngTypes = std.meta.AliasSeq!(Mt19937_32, Mt19937_64, Xorshift32, Xorshift64,
                                                      Xorshift96, Xorshift128, Xorshift160, Xorshift192);
}

// Segments of the code in this file Copyright (c) 1997 by Rick Booth
// From "Inner Loops" by Rick Booth, Addison-Wesley

// Work derived from:

/*
   A C-program for MT19937, with initialization improved 2002/1/26.
   Coded by Takuji Nishimura and Makoto Matsumoto.

   Before using, initialize the state by using init_genrand(seed)
   or init_by_array(init_key, key_length).

   Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

     1. Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

     2. Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.

     3. The names of its contributors may not be used to endorse or promote
        products derived from this software without specific prior written
        permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


   Any feedback is very welcome.
   http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html
   email: m-mat @ math.sci.hiroshima-u.ac.jp (remove space)
*/

/**
 * Test if T is a random-bit generator.
 */
template isURBG(T)
{
    private alias R = typeof(T.init());
    static if (hasUDA!(T, URBG) && isUnsigned!R)
    {
        enum isURBG = is(typeof({
            enum max = T.max;
            static assert(is(typeof(T.max) == R));
            }));
    }
    else enum isURBG = false; 
}

/**
 * Test if T is a saturated random-bit generator.
 * A random number generator is saturated if `T.max == ReturnType!T.max`.
 */
template isSURBG(T)
{
    static if (isURBG!T)
        enum isSURBG = T.max == ReturnType!T.max;
    else
        enum isSURBG = false;
}

/// Defenition to as Uniform Random Bit Generator
enum URBG;

 /**
 Linear Congruential generator.
 */
@URBG struct LinearCongruentialEngine(Uint, Uint a, Uint c, Uint m)
    if (isUnsigned!Uint)
{
    /// Highest generated value ($(D modulus - 1 - bool(c == 0))).
    enum Uint max = m - 1 - bool(c == 0);
/**
The parameters of this distribution. The random number is $(D_PARAM x
= (x * multipler + increment) % modulus).
 */
    enum Uint multiplier = a;
    ///ditto
    enum Uint increment = c;
    ///ditto
    enum Uint modulus = m;

    static assert(m == 0 || a < m);
    static assert(m == 0 || c < m);
    static assert(m == 0 || (cast(ulong)a * (m-1) + c) % m == (c < a ? c - a + m : c - a));

    @disable this();
    @disable this(this);

    // Check for maximum range
    private static ulong gcd()(ulong a, ulong b)
    {
        while (b)
        {
            auto t = b;
            b = a % b;
            a = t;
        }
        return a;
    }

    private static ulong primeFactorsOnly()(ulong n)
    {
        ulong result = 1;
        ulong iter = 2;
        for (; n >= iter * iter; iter += 2 - (iter == 2))
        {
            if (n % iter) continue;
            result *= iter;
            do
            {
                n /= iter;
            } while (n % iter == 0);
        }
        return result * n;
    }

    @safe pure nothrow unittest
    {
        static assert(primeFactorsOnly(100) == 10);
        static assert(primeFactorsOnly(11) == 11);
        static assert(primeFactorsOnly(7 * 7 * 7 * 11 * 15 * 11) == 7 * 11 * 15);
        static assert(primeFactorsOnly(129 * 2) == 129 * 2);
        // enum x = primeFactorsOnly(7 * 7 * 7 * 11 * 15);
        // static assert(x == 7 * 11 * 15);
    }

    private static bool properLinearCongruentialParameters()(ulong m,ulong a, ulong c)
    {
        if (m == 0)
        {
            static if (is(Uint == uint))
            {
                // Assume m is uint.max + 1
                m = (1uL << 32);
            }
            else
            {
                return false;
            }
        }
        // Bounds checking
        if (a == 0 || a >= m || c >= m) return false;
        // c and m are relatively prime
        if (c > 0 && gcd(c, m) != 1) return false;
        // a - 1 is divisible by all prime factors of m
        if ((a - 1) % primeFactorsOnly(m)) return false;
        // if a - 1 is multiple of 4, then m is a  multiple of 4 too.
        if ((a - 1) % 4 == 0 && m % 4) return false;
        // Passed all tests
        return true;
    }

    // check here
    static assert(c == 0 || properLinearCongruentialParameters(m, a, c),
            "Incorrect instantiation of LinearCongruentialEngine");

/**
Constructs a $(D_PARAM LinearCongruentialEngine) generator seeded with
$(D x0).
Params:
    x0 = seed, must be positive if c equals to 0.
 */
    this(Uint x0) @safe pure
    {
        static if (c == 0)
            assert(x0, "Invalid (zero) seed for " ~ LinearCongruentialEngine.stringof);
        _x = modulus ? (x0 % modulus) : x0;
    }

    /**
       Advances the random sequence.
    */
    Uint opCall() @safe pure nothrow @nogc
    {
        static if (m)
        {
            static if (is(Uint == uint))
            {
                static if (m == uint.max)
                {
                    immutable ulong
                        x = (cast(ulong) a * _x + c),
                        v = x >> 32,
                        w = x & uint.max;
                    immutable y = cast(uint)(v + w);
                    _x = (y < v || y == uint.max) ? (y + 1) : y;
                }
                else static if (m == int.max)
                {
                    immutable ulong
                        x = (cast(ulong) a * _x + c),
                        v = x >> 31,
                        w = x & int.max;
                    immutable uint y = cast(uint)(v + w);
                    _x = (y >= int.max) ? (y - int.max) : y;
                }
                else
                {
                    _x = cast(uint) ((cast(ulong) a * _x + c) % m);
                }
            }
            else static assert(0);
        }
        else
        {
            _x = a * _x + c;
        }
        static if (c == 0)
            return _x - 1;
        else
            return _x;
    }

    private Uint _x;
}

/**
Define $(D_PARAM LinearCongruentialEngine) generators with well-chosen
parameters. $(D MinstdRand0) implements Park and Miller's "minimal
standard" $(HTTP
wikipedia.org/wiki/Park%E2%80%93Miller_random_number_generator,
generator) that uses 16807 for the multiplier. $(D MinstdRand)
implements a variant that has slightly better spectral behavior by
using the multiplier 48271. Both generators are rather simplistic.
 */
alias MinstdRand0 = LinearCongruentialEngine!(uint, 16807, 0, 2147483647);
/// ditto
alias MinstdRand = LinearCongruentialEngine!(uint, 48271, 0, 2147483647);

///
@safe unittest
{
    // seed with a constant
    auto rnd0 = MinstdRand0(1);
    auto n = rnd0(); // same for each run
    // Seed with an unpredictable value
    rnd0 = MinstdRand0(cast(uint)unpredictableSeed);
    n = rnd0(); // different across runs

    import std.traits;
    static assert(is(ReturnType!rnd0 == uint));
}

unittest
{
    static assert(isURBG!MinstdRand);
    static assert(isURBG!MinstdRand0);

    static assert(!isSURBG!MinstdRand);
    static assert(!isSURBG!MinstdRand0);

    // The correct numbers are taken from The Database of Integer Sequences
    // http://www.research.att.com/~njas/sequences/eisBTfry00128.txt
    auto checking0 = [
        16807,282475249,1622650073,984943658,1144108930,470211272,
        101027544,1457850878,1458777923,2007237709,823564440,1115438165,
        1784484492,74243042,114807987,1137522503,1441282327,16531729,
        823378840,143542612 ];

    auto rnd0 = MinstdRand0(1);

    foreach (e; checking0)
    {
        assert(rnd0() == e - 1);
    }
    // Test the 10000th invocation
    // Correct value taken from:
    // http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2007/n2461.pdf
    rnd0 = MinstdRand0(1);
    foreach(_; 0 .. 9999)
        rnd0();
    assert(rnd0() == 1043618065 - 1);

    // Test MinstdRand
    auto checking = [48271UL,182605794,1291394886,1914720637,2078669041,
                     407355683];
    auto rnd = MinstdRand(1);
    foreach (e; checking)
    {
        assert(rnd() == e - 1);
    }

    // Test the 10000th invocation
    // Correct value taken from:
    // http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2007/n2461.pdf
    rnd = MinstdRand(1);
    foreach(_; 0 .. 9999)
        rnd();
    assert(rnd() == 399268537 - 1);
}


/**
The $(LUCKY Mersenne Twister) generator.
 */
@URBG struct MersenneTwisterEngine(Uint, size_t w, size_t n, size_t m, size_t r,
                             Uint a,
                             uint u, Uint d,
                             uint s, Uint b,
                             uint t, Uint c,
                             uint l)
    if (isUnsigned!Uint)
{
    static assert(0 < w && w <= Uint.sizeof * 8);
    static assert(1 <= m && m <= n);
    static assert(0 <= r && 0 <= u && 0 <= s && 0 <= t && 0 <= l);
    static assert(r <= w && u <= w && s <= w && t <= w && l <= w);
    static assert(0 <= a && 0 <= b && 0 <= c);

    @disable this();
    @disable this(this);

    private enum Uint upperMask = ~((cast(Uint) 1u << (Uint.sizeof * 8 - (w - r))) - 1);
    private enum Uint lowerMask = (cast(Uint) 1u << r) - 1;

    /**
    Parameters for the generator.
    */
    enum size_t wordSize   = w;
    enum size_t stateSize  = n; /// ditto
    enum size_t shiftSize  = m; /// ditto
    enum size_t maskBits   = r; /// ditto
    enum Uint xorMask    = a; /// ditto
    enum uint temperingU = u; /// ditto
    enum Uint temperingD = d; /// ditto
    enum uint temperingS = s; /// ditto
    enum Uint temperingB = b; /// ditto
    enum uint temperingT = t; /// ditto
    enum Uint temperingC = c; /// ditto
    enum uint temperingL = l; /// ditto

    /// Largest generated value.
    enum Uint max = Uint.max >> (Uint.sizeof * 8u - w);
    static assert(a <= max && b <= max && c <= max);

    /// The default seed value.
    enum Uint defaultSeed = 5489;

    /// payload index
    Uint index; /* means mt is not initialized */
    /// payload
    Uint[n] mt;

    /**
       Constructs a MersenneTwisterEngine object.
    */
    this(Uint value) @safe pure nothrow @nogc
    {
        static if (w == Uint.sizeof * 8)
        {
            mt[0] = value;
        }
        else
        {
            static assert(max + 1 > 0);
            mt[0] = value % (max + 1);
        }
        static if (is(Uint == uint))
            enum Uint f = 1812433253;
        else
        static if (is(Uint == ulong))
            enum Uint f = 6364136223846793005;
        else
        static assert(0, "ucent is not supported by MersenneTwisterEngine.");
        Uint i = 1;
        for (; i < n; ++i)
        {
            mt[i] = f * (mt[i-1] ^ (mt[i-1] >> (w - 2))) + i;
        }
        index = i;
    }

    /**
       Advances the generator.
    */
    Uint opCall() @safe pure nothrow @nogc
    {
        version (LDC)
        {
            import ldc.intrinsics: llvm_expect;
            enum cond = `llvm_expect(index >= n, false)`;
        }
        else
        {
            enum cond = `index >= n`;
        }
        if (mixin(cond))
        {
            /* generate N words at one time */
            Uint kk = 0;
            const limit1 = n - m;
            for (; kk < limit1; ++kk)
            {
                auto y = (mt[kk] & upperMask) | (mt[kk + 1] & lowerMask);
                auto x = y >> 1;
                if (y & 1)
                    x ^= a;
                mt[kk] = mt[kk + m] ^ x;
            }
            const limit2 = n - 1;
            for (; kk < limit2; ++kk)
            {
                auto y = (mt[kk] & upperMask) | (mt[kk + 1] & lowerMask);
                auto x = y >> 1;
                if (y & 1)
                    x ^= a;
                mt[kk] = mt[kk + m - n] ^ x;
            }
            auto y = (mt[n - 1] & upperMask) | (mt[0] & lowerMask);
            auto x = y >> 1;
            if (y & 1)
                x ^= a;
            mt[n - 1] = mt[m - 1] ^ x;
            index = 0;
        }

        auto y = mt[index++];

        /* Tempering */
        static if (d == Uint.max)
            y ^= (y >> u);
        else
            y ^= (y >> u) & d;
        y ^= (y << s) & b;
        y ^= (y << t) & c;
        y ^= (y >> l);

        return y;
    }
}

/**
A $(D MersenneTwisterEngine) instantiated with the parameters of the
original engine $(HTTP math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html,
MT19937), generating uniformly-distributed 32-bit or 64-bit numbers with a
period of 2 to the power of 19937. Recommended for random number
generation unless memory is severely restricted, in which case a $(D
LinearCongruentialEngine) would be the generator of choice.
 */
alias Mt19937_32 = MersenneTwisterEngine!(uint, 32, 624, 397, 31,
                                       0x9908b0df, 
                                       11, 0xffffffff,
                                        7, 0x9d2c5680,
                                       15, 0xefc60000,
                                       18);
/// ditto
alias Mt19937_64 = MersenneTwisterEngine!(ulong, 64, 312, 156, 31,
                                       0xb5026f5aa96619e9, 
                                       29, 0x5555555555555555,
                                       17, 0x71d67fffeda60000,
                                       37, 0xfff7eee000000000,
                                       43);
/// ditto
static if (is(size_t == uint))
    alias Mt19937 = Mt19937_32;
else
    alias Mt19937 = Mt19937_64;

///
@safe unittest
{
    auto gen = Mt19937(cast(size_t)unpredictableSeed);
    auto n = gen();

    import std.traits;
    static assert(is(ReturnType!gen == size_t));
}

@safe nothrow unittest
{
    static assert(isSURBG!Mt19937_32);
    static assert(isSURBG!Mt19937_64);
    auto gen = Mt19937_32(Mt19937_32.defaultSeed);
    foreach(_; 0 .. 9999)
        gen();
    assert(gen() == 4123659995);
}

/**
 * Xorshift generator using 32bit algorithm.
 *
 * Implemented according to $(HTTP www.jstatsoft.org/v08/i14/paper, Xorshift RNGs).
 *
 * $(BOOKTABLE $(TEXTWITHCOMMAS Supporting bits are below, $(D bits) means second parameter of XorshiftEngine.),
 *  $(TR $(TH bits) $(TH period))
 *  $(TR $(TD 32)   $(TD 2^32 - 1))
 *  $(TR $(TD 64)   $(TD 2^64 - 1))
 *  $(TR $(TD 96)   $(TD 2^96 - 1))
 *  $(TR $(TD 128)  $(TD 2^128 - 1))
 *  $(TR $(TD 160)  $(TD 2^160 - 1))
 *  $(TR $(TD 192)  $(TD 2^192 - 2^32))
 * )
 */
@URBG struct XorshiftEngine(uint bits, uint a, uint b, uint c)
    if (isUnsigned!uint)
{
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


/**
 * Define $(D XorshiftEngine) generators with well-chosen parameters. See each bits examples of "Xorshift RNGs".
 * $(D Xorshift) is a Xorshift128's alias because 128bits implementation is mostly used.
 */
alias Xorshift32  = XorshiftEngine!(32,  13, 17, 15) ;
alias Xorshift64  = XorshiftEngine!(64,  10, 13, 10); /// ditto
alias Xorshift96  = XorshiftEngine!(96,  10, 5,  26); /// ditto
alias Xorshift128 = XorshiftEngine!(128, 11, 8,  19); /// ditto
alias Xorshift160 = XorshiftEngine!(160, 2,  1,  4);  /// ditto
alias Xorshift192 = XorshiftEngine!(192, 2,  1,  4);  /// ditto
alias Xorshift    = Xorshift128;                      /// ditto

///
@safe unittest
{
    auto rnd = Xorshift(cast(uint)unpredictableSeed);
    auto num = rnd();

    import std.traits;
    static assert(is(ReturnType!rnd == uint));
    static assert(isSURBG!Xorshift);
}

/* A complete list of all pseudo-random number generators implemented in
 * std.random.  This can be used to confirm that a given function or
 * object is compatible with all the pseudo-random number generators
 * available.  It is enabled only in unittest mode.
 */
@safe unittest
{
    foreach (Rng; PseudoRngTypes)
    {
        static assert(isURBG!Rng);
        auto rng = Rng(cast(uint)unpredictableSeed);
    }
}


version(Darwin)
private
extern(C) nothrow @nogc
ulong mach_absolute_time();

/**
A "good" seed for initializing random number engines. Initializing
with $(D_PARAM unpredictableSeed) makes engines generate different
random number sequences every run.

Returns:
A single unsigned integer seed value, different on each successive call
*/
pragma(inline, true)
@property ulong unpredictableSeed() @trusted nothrow @nogc
{
    version(Windows)
    {
        ulong ticks = void;
        QueryPerformanceCounter(&ticks);
    }
    else
    version(Darwin)
    {
        ulong ticks = mach_absolute_time();
    }
    else
    version(Posix)
    {
        import core.sys.posix.time;
        timespec ts;
        if(clock_gettime(clockArg, &ts) != 0)
        {
            import core.internal.abort : abort;
            abort("Call to clock_gettime failed.");
        }
        ulong ticks = (cast(ulong) ts.tv_sec << 32) ^ ts.tv_nsec;
    }
    version(Posix)
    {
        import core.sys.posix.unistd;
        import core.sys.posix.pthread;
        auto pid = cast(uint) getpid;
        auto tid = cast(uint) pthread_self();
    }
    else
    version(Windows)
    {
        import core.sys.windows.windows;
        import core.sys.windows.winbase;
        auto pid = cast(uint) GetCurrentProcessId;
        auto tid = cast(uint) GetCurrentThreadId;
    }
    ulong k = ((cast(ulong)pid << 32) ^ tid) + ticks;
    k ^= k >> 33;
    k *= 0xff51afd7ed558ccd;
    k ^= k >> 33;
    k *= 0xc4ceb9fe1a85ec53;
    k ^= k >> 33;
    return k;
}

///
@safe unittest
{
    auto rnd = Random(cast(size_t)unpredictableSeed);
    auto n = rnd();
    static assert(is(typeof(n) == size_t));
}

/**
The "default", "favorite", "suggested" random number generator type on
the current platform. It is an alias for one of the previously-defined
generators. You may want to use it if (1) you need to generate some
nice random numbers, and (2) you don't care for the minutiae of the
method being used.
 */

alias Random = Mt19937;

///
unittest
{
    import std.traits;
    static assert(isSURBG!Random);
    static assert(is(ReturnType!Random == size_t));
}
