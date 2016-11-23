/++
The Mersenne Twister generator.

Copyright: Copyright Andrei Alexandrescu 2008 - 2009, Ilya Yaroshenko 2016-.
License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: $(HTTP erdani.org, Andrei Alexandrescu) Ilya Yaroshenko (rework)
+/
module random.engine.mersenne_twister;

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

import std.traits;
import random.engine;

/++
The $(LUCKY Mersenne Twister) generator.
+/
@RandomEngine struct MersenneTwisterEngine(Uint, size_t w, size_t n, size_t m, size_t r,
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
    static assert(isSaturatedRandomEngine!Mt19937_32);
    static assert(isSaturatedRandomEngine!Mt19937_64);
    auto gen = Mt19937_32(Mt19937_32.defaultSeed);
    foreach(_; 0 .. 9999)
        gen();
    assert(gen() == 4123659995);
}
