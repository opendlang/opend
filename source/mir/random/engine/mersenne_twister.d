/++
The Mersenne Twister generator.

Copyright: Copyright Andrei Alexandrescu 2008 - 2009, Ilya Yaroshenko 2016-.
License:    $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: $(HTTP erdani.org, Andrei Alexandrescu) Ilya Yaroshenko (rework)
+/
module mir.random.engine.mersenne_twister;

import std.traits;
import mir.ndslice.slice : Slice, SliceKind, Contiguous;

/++
The $(LUCKY Mersenne Twister) generator.
+/
struct MersenneTwisterEngine(UIntType, size_t w, size_t n, size_t m, size_t r,
                             UIntType a, size_t u, UIntType d, size_t s,
                             UIntType b, size_t t,
                             UIntType c, size_t l, UIntType f)
    if (isUnsigned!UIntType)
{
    ///
    enum isRandomEngine = true;

    static assert(0 < w && w <= UIntType.sizeof * 8);
    static assert(1 <= m && m <= n);
    static assert(0 <= r && 0 <= u && 0 <= s && 0 <= t && 0 <= l);
    static assert(r <= w && u <= w && s <= w && t <= w && l <= w);
    static assert(0 <= a && 0 <= b && 0 <= c);

    @disable this();
    @disable this(this);

    /// Largest generated value.
    enum UIntType max = UIntType.max >> (UIntType.sizeof * 8u - w);
    static assert(a <= max && b <= max && c <= max && f <= max);

    private enum UIntType lowerMask = (cast(UIntType) 1u << r) - 1;
    private enum UIntType upperMask = ~lowerMask & max;

    /**
    Parameters for the generator.
    */
    enum size_t   wordSize   = w;
    enum size_t   stateSize  = n; /// ditto
    enum size_t   shiftSize  = m; /// ditto
    enum size_t   maskBits   = r; /// ditto
    enum UIntType xorMask    = a; /// ditto
    enum size_t   temperingU = u; /// ditto
    enum UIntType temperingD = d; /// ditto
    enum size_t   temperingS = s; /// ditto
    enum UIntType temperingB = b; /// ditto
    enum size_t   temperingT = t; /// ditto
    enum UIntType temperingC = c; /// ditto
    enum size_t   temperingL = l; /// ditto
    enum UIntType initializationMultiplier = f; /// ditto


    /// The default seed value.
    enum UIntType defaultSeed = 5489;

    /++
    Current reversed payload index with initial value equals to `n-1`
    +/
    size_t index = void;

    private UIntType _z = void;

    /++
    Reversed(!) payload.
    +/
    UIntType[n] data = void;

    /*
     * Marker indicating it's safe to construct from void
     * (i.e. the constructor doesn't depend on the struct
     * being in an initially valid state).
     * Non-public because we don't want to commit to this
     * design.
     */
    package enum bool _isVoidInitOkay = true;

    /++
    Constructs a MersenneTwisterEngine object.
    +/
    this(UIntType value) @safe pure nothrow @nogc
    {
        static if (max == UIntType.max)
            data[$-1] = value;
        else
            data[$-1] = value & max;
        foreach_reverse (size_t i, ref e; data[0 .. $-1])
        {
            e = f * (data[i + 1] ^ (data[i + 1] >> (w - 2))) + cast(UIntType)(n - (i + 1));
            static if (max != UIntType.max)
                e &= max;
        }
        index = n-1;
        opCall();
    }

    /++
    Constructs a MersenneTwisterEngine object.

    Note that `MersenneTwisterEngine([123])` will not result in
    the same initial state as `MersenneTwisterEngine(123)`.
    +/
    this()(scope Slice!(Contiguous, [1], const(UIntType)*) slice) @safe pure nothrow @nogc
    {
        static if (is(UIntType == uint))
        {
            enum UIntType f2 = 1664525u;
            enum UIntType f3 = 1566083941u;
        }
        else static if (is(UIntType == ulong))
        {
            enum UIntType f2 = 3935559000370003845uL;
            enum UIntType f3 = 2862933555777941757uL;
        }
        else
            static assert(0, "init by slice only supported if UIntType is uint or ulong!");

        data[$-1] = cast(UIntType) (19650218u & max);
        foreach_reverse (size_t i, ref e; data[0 .. $-1])
        {
            e = f * (data[i + 1] ^ (data[i + 1] >> (w - 2))) + cast(UIntType)(n - (i + 1));
            static if (max != UIntType.max)
                e &= max;
        }
        index = n-1;
        if (slice.length == 0)
        {
            opCall();
            return;
        }

        size_t final_mix_index = void;

        if (slice.length >= n)
        {
            size_t j = 0;
            //Handle all but tail.
            while (slice.length - j >= n - 1)
            {
                foreach_reverse (i, ref e; data[0 .. $-1])
                {
                    e = (e ^ ((data[i+1] ^ (data[i+1] >> (w - 2))) * f2))
                        + slice[j] + cast(UIntType) j;
                    static if (max != UIntType.max)
                        e &= max;
                    ++j;
                }
                data[$ - 1] = data[0];
            }
            //Handle tail.
            size_t i = n - 2;
            while (j < slice.length)
            {
                data[i] = (data[i] ^ ((data[i+1] ^ (data[i+1] >> (w - 2))) * f2))
                    + slice[j] + cast(UIntType) j;
                static if (max != UIntType.max)
                    data[i] &= max;
                ++j;
                --i;
            }
            //Set the index for use by the next pass.
            final_mix_index = i;
        }
        else
        {
            size_t i = n - 2;
            //Handle all but tail.
            while (i >= slice.length)
            {
                foreach (j; 0 .. slice.length)
                {
                    data[i] = (data[i] ^ ((data[i+1] ^ (data[i+1] >> (w - 2))) * f2))
                        + slice[j] + cast(UIntType) j;
                    static if (max != UIntType.max)
                        data[i] &= max;
                    --i;
                }
            }
            //Handle tail.
            size_t j = 0;
            while (i != cast(size_t) -1)
            {
                data[i] = (data[i] ^ ((data[i+1] ^ (data[i+1] >> (w - 2))) * f2))
                    + slice[j] + cast(UIntType) j;
                static if (max != UIntType.max)
                    data[i] &= max;
                ++j;
                --i;
            }
            data[$ - 1] = data[0];
            i = n - 2;
            data[i] = (data[i] ^ ((data[i+1] ^ (data[i+1] >> (w - 2))) * f2))
                + slice[j] + cast(UIntType) j;
            static if (max != UIntType.max)
                data[i] &= max;
            //Set the index for use by the next pass.
            final_mix_index = n - 2;
        }

        foreach_reverse (i, ref e; data[0 .. final_mix_index])
        {
            e = (e ^ ((data[i+1] ^ (data[i+1] >> (w - 2))) * f3))
                - cast(UIntType)(n - (i + 1));
            static if (max != UIntType.max)
                e &= max;
        }
        foreach_reverse (i, ref e; data[final_mix_index .. n-1])
        {
            e = (e ^ ((data[i+1] ^ (data[i+1] >> (w - 2))) * f3))
                - cast(UIntType)(n - (i + 1));
            static if (max != UIntType.max)
                e &= max;
        }
        data[$-1] = (cast(UIntType)1) << ((UIntType.sizeof * 8) - 1); /* MSB is 1; assuring non-zero initial array */
        opCall();
    }

    /// ditto
    this()(scope const(UIntType)[] array) @safe pure nothrow @nogc
    {
        import mir.ndslice.slice: sliced;
        this(array.sliced);
    }

    /++
    Advances the generator.
    +/
    UIntType opCall() @safe pure nothrow @nogc
    {
        // This function blends two nominally independent
        // processes: (i) calculation of the next random
        // variate from the cached previous `data` entry
        // `_z`, and (ii) updating `data[index]` and `_z`
        // and advancing the `index` value to the next in
        // sequence.
        //
        // By interweaving the steps involved in these
        // procedures, rather than performing each of
        // them separately in sequence, the variables
        // are kept 'hot' in CPU registers, allowing
        // for significantly faster performance.
        sizediff_t index = this.index;
        sizediff_t next = index - 1;
        if(next < 0)
            next = n - 1;
        auto z = _z;
        sizediff_t conj = index - m;
        if(conj < 0)
            conj = index - m + n;
        static if (d == UIntType.max)
            z ^= (z >> u);
        else
            z ^= (z >> u) & d;
        auto q = data[index] & upperMask;
        auto p = data[next] & lowerMask;
        z ^= (z << s) & b;
        auto y = q | p;
        auto x = y >> 1;
        z ^= (z << t) & c;
        if (y & 1)
            x ^= a;
        auto e = data[conj] ^ x;
        z ^= (z >> l);
        _z = data[index] = e;
        this.index = next;
        return z;
    }
}

/++
A $(D MersenneTwisterEngine) instantiated with the parameters of the
original engine $(HTTP en.wikipedia.org/wiki/Mersenne_Twister,
MT19937), generating uniformly-distributed 32-bit numbers with a
period of 2 to the power of 19937.

This is recommended for random number generation on 32-bit systems
unless memory is severely restricted, in which case a
$(REF_ALTTEXT Xorshift, Xorshift, mir, random, engine, xorshift)
would be the generator of choice.
+/
alias Mt19937 = MersenneTwisterEngine!(uint, 32, 624, 397, 31,
                                       0x9908b0df, 11, 0xffffffff, 7,
                                       0x9d2c5680, 15,
                                       0xefc60000, 18, 1812433253);

///
@safe version(mir_random_test) unittest
{
    import mir.random.engine;

    // bit-masking by generator maximum is necessary
    // to handle 64-bit `unpredictableSeed`
    auto gen = Mt19937(unpredictableSeed & Mt19937.max);
    auto n = gen();

    import std.traits;
    static assert(is(ReturnType!gen == uint));
}

/++
A $(D MersenneTwisterEngine) instantiated with the parameters of the
original engine $(HTTP en.wikipedia.org/wiki/Mersenne_Twister,
MT19937), generating uniformly-distributed 64-bit numbers with a
period of 2 to the power of 19937.

This is recommended for random number generation on 64-bit systems
unless memory is severely restricted, in which case a
$(REF_ALTTEXT Xorshift, Xorshift, mir, random, engine, xorshift)
would be the generator of choice.
+/
alias Mt19937_64 = MersenneTwisterEngine!(ulong, 64, 312, 156, 31,
                                          0xb5026f5aa96619e9, 29, 0x5555555555555555, 17,
                                          0x71d67fffeda60000, 37,
                                          0xfff7eee000000000, 43, 6364136223846793005);

///
@safe version(mir_random_test) unittest
{
    import mir.random.engine;

    auto gen = Mt19937_64(unpredictableSeed);
    auto n = gen();

    import std.traits;
    static assert(is(ReturnType!gen == ulong));
}

@safe nothrow version(mir_random_test) unittest
{
    import mir.random.engine;

    static assert(isSaturatedRandomEngine!Mt19937);
    static assert(isSaturatedRandomEngine!Mt19937_64);
    auto gen = Mt19937(Mt19937.defaultSeed);
    foreach(_; 0 .. 9999)
        gen();
    assert(gen() == 4123659995);

    auto gen64 = Mt19937_64(Mt19937_64.defaultSeed);
    foreach(_; 0 .. 9999)
        gen64();
    assert(gen64() == 9981545732273789042uL);
}

version(mir_random_test) unittest
{
    enum val = [1341017984, 62051482162767];
    alias MT(UIntType, uint w) = MersenneTwisterEngine!(UIntType, w, 624, 397, 31,
                                                        0x9908b0df, 11, 0xffffffff, 7,
                                                        0x9d2c5680, 15,
                                                        0xefc60000, 18, 1812433253);

    import std.meta: AliasSeq;
    foreach (i, R; AliasSeq!(MT!(ulong, 32), MT!(ulong, 48)))
    {
        static if (R.wordSize == 48) static assert(R.max == 0xFFFFFFFFFFFF);
        auto a = R(R.defaultSeed);
        foreach(_; 0..999)
            a();
        assert(val[i] == a());
    }
}

@safe nothrow @nogc version(mir_random_test) unittest
{
    //Verify that seeding with an array gives the same result as the reference
    //implementation.

    //32-bit: www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/MT2002/CODES/mt19937ar.tgz
    immutable uint[4] seed32 = [0x123u, 0x234u, 0x345u, 0x456u];
    auto gen32 = Mt19937(seed32);
    foreach(_; 0..999)
        gen32();
    assert(3460025646u == gen32());

    //64-bit: www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/mt19937-64.tgz
    immutable ulong[4] seed64 = [0x12345uL, 0x23456uL, 0x34567uL, 0x45678uL];
    auto gen64 = Mt19937_64(seed64);
    foreach(_; 0..999)
        gen64();
    assert(994412663058993407uL == gen64());
}
