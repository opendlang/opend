/++
Xorshift generator.

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