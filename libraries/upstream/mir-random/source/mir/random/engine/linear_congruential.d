/++
Linear Congruential generator.

Copyright: Copyright Andrei Alexandrescu 2008 - 2009, Ilya Yaroshenko 2016-.
License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: $(HTTP erdani.org, Andrei Alexandrescu) Ilya Yaroshenko (rework)
+/
module mir.random.engine.linear_congruential;

import std.traits;

/++
Linear Congruential generator.
+/
struct LinearCongruentialEngine(Uint, Uint a, Uint c, Uint m)
    if (isUnsigned!Uint)
{
    ///
    enum isRandomEngine = true;

    /// Highest generated value (`modulus - 1 - bool(c == 0)`).
    enum Uint max = m - 1 - bool(c == 0);
/**
The parameters of this distribution. The random number is $(D_PARAM x
= (x * multiplier + increment) % modulus).
 */
    enum Uint multiplier = a;
    ///ditto
    enum Uint increment = c;
    ///ditto
    enum Uint modulus = m;

    static assert(m == 0 || a < m);
    static assert(m == 0 || c < m);
    static assert(m == 0 || (cast(ulong)a * (m-1) + c) % m == (c < a ? c - a + m : c - a));

    /++
    The low bits of a linear congruential generator whose modulus is a
    power of 2 have a much shorter period than the high bits.
    Note that for LinearCongruentialEngine, `modulus == 0` signifies
    a modulus of `2 ^^ (Uint.sizeof*8)` which is not representable as `Uint`.
    +/
    enum bool preferHighBits = 0 == (modulus & (modulus - 1));

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

    @safe pure nothrow version(mir_random_test) unittest
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
`x0`.
Params:
    x0 = seed, must be positive if c equals to 0.
 */
    this(Uint x0) @safe pure nothrow @nogc
    {
        _x = modulus ? (x0 % modulus) : x0;
        static if (c == 0)
        {
            //Necessary to prevent generator from outputting an endless series of zeroes.
            if (_x == 0)
                _x = max;
        }
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
parameters. `MinstdRand0` implements Park and Miller's "minimal
standard" $(HTTP
wikipedia.org/wiki/Park%E2%80%93Miller_random_number_generator,
generator) that uses 16807 for the multiplier. `MinstdRand`
implements a variant that has slightly better spectral behavior by
using the multiplier 48271. Both generators are rather simplistic.
 */
alias MinstdRand0 = LinearCongruentialEngine!(uint, 16807, 0, 2147483647);
/// ditto
alias MinstdRand = LinearCongruentialEngine!(uint, 48271, 0, 2147483647);

///
@safe version(mir_random_test) unittest
{
    import mir.random.engine;
    // seed with a constant
    auto rnd0 = MinstdRand0(1);
    auto n = rnd0(); // same for each run
    // Seed with an unpredictable value
    rnd0 = MinstdRand0(cast(uint)unpredictableSeed);
    n = rnd0(); // different across runs

    import std.traits;
    static assert(is(ReturnType!rnd0 == uint));
}

@safe version(mir_random_test) unittest
{
    auto rnd0 = MinstdRand0(MinstdRand0.modulus);
    auto n = rnd0();
    assert(n != rnd0());
}

version(mir_random_test) unittest
{
    import mir.random.engine;
    static assert(isRandomEngine!MinstdRand);
    static assert(isRandomEngine!MinstdRand0);

    static assert(!isSaturatedRandomEngine!MinstdRand);
    static assert(!isSaturatedRandomEngine!MinstdRand0);

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
