/++
 + Permuted Congruential Generator (PCG)
 +
 + Implemeted as per the C++ version of PCG, $(HTTP _pcg-random.org).
 +
 + Paper available $(HTTP _pcg-random.org/paper.html)
 +
 + Author:  Melissa O'Neill (C++). D translation Nicholas Wilson.
 +
 + PCG Random Number Generation for C++
 +
 + Copyright 2014 Melissa O'Neill <oneill@pcg-random.org>
 +
 + Licensed under the Apache License, Version 2.0 (the "License");
 + you may not use this file except in compliance with the License.
 + You may obtain a copy of the License at
 +
 +     $(HTTP www.apache.org/licenses/LICENSE-2.0)
 +
 + Unless required by applicable law or agreed to in writing, software
 + distributed under the License is distributed on an "AS IS" BASIS,
 + WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 + See the License for the specific language governing permissions and
 + limitations under the License.
 +
 + For additional information about the PCG random number generation scheme,
 + including its license and other licensing options, visit
 +
 +     $(HTTP _pcg-random.org)
 +/
module mir.random.engine.pcg;

import mir.random.engine;
import std.traits : ReturnType, TemplateArgsOf;

@safe:
nothrow:
@nogc:

/// 32-bit output PCGs with 64 bits of state.
alias pcg32        = PermutedCongruentialEngine!(xsh_rr!(uint,ulong),stream_t.specific,true);
/// ditto
alias pcg32_unique = PermutedCongruentialEngine!(xsh_rr!(uint,ulong),stream_t.unique,true);
/// ditto
alias pcg32_oneseq = PermutedCongruentialEngine!(xsh_rr!(uint,ulong),stream_t.oneseq,true);
/// ditto
alias pcg32_fast   = PermutedCongruentialEngine!(xsh_rr!(uint,ulong),stream_t.none,true);

static if (__traits(compiles, ucent.max))
{
    /// 64-bit output PCGs with 128 bits of state. Requires `ucent` type.
    alias pcg64        = PermutedCongruentialEngine!(xsh_rr!(ulong,ucent),stream_t.specific,true);
    ///
    alias pcg64_unique = PermutedCongruentialEngine!(xsh_rr!(ulong,ucent),stream_t.unique,true);
    ///
    alias pcg64_oneseq = PermutedCongruentialEngine!(xsh_rr!(ulong,ucent),stream_t.oneseq,true);
    ///
    alias pcg64_fast   = PermutedCongruentialEngine!(xsh_rr!(ulong,ucent),stream_t.none,true);
}

/// PCGs with n bits output and n bits of state.
alias pcg8_once_insecure  = PermutedCongruentialEngine!(rxs_m_xs_forward!(ubyte ,ubyte ),stream_t.specific,true);
/// ditto
alias pcg16_once_insecure = PermutedCongruentialEngine!(rxs_m_xs_forward!(ushort,ushort),stream_t.specific,true);
/// ditto
alias pcg32_once_insecure = PermutedCongruentialEngine!(rxs_m_xs_forward!(uint  ,uint  ),stream_t.specific,true);
/// ditto
alias pcg64_once_insecure = PermutedCongruentialEngine!(rxs_m_xs_forward!(ulong,ulong  ),stream_t.specific,true);
//alias pcg128_once_insecure = PermutedCongruentialEngine!(rxs_m_xs_forward!(ucent,ucent,stream_t.specific,true);

/// As above but the increment is not dynamically setable.
alias pcg8_oneseq_once_insecure = PermutedCongruentialEngine!(rxs_m_xs_forward!(ubyte ,ubyte ),stream_t.oneseq,true);
/// ditto
alias pcg16_oneseq_once_insecure = PermutedCongruentialEngine!(rxs_m_xs_forward!(ushort,ushort),stream_t.oneseq,true);
/// ditto
alias pcg32_oneseq_once_insecure = PermutedCongruentialEngine!(rxs_m_xs_forward!(uint  ,uint  ),stream_t.oneseq,true);
/// ditto
alias pcg64_oneseq_once_insecure = PermutedCongruentialEngine!(rxs_m_xs_forward!(ulong,ulong  ),stream_t.oneseq,true);
/// ditto
/// Requires `ucent` type.
static if (__traits(compiles, ucent.max))
alias pcg128_oneseq_once_insecure = PermutedCongruentialEngine!(rxs_m_xs_forward!(ucent,ucent  ),stream_t.specific,true);

/++
 + The PermutedCongruentialEngine:
 + Params:
 +  output - should be one of the above functions.
 +      Controls the output permutation of the state.
 +  stream - one of unique, none, oneseq, specific.
 +      Controls the Increment of the LCG portion of the PCG.
 +      unique   - increment is cast(size_t) &RNG
 +      none     - increment is 0.
 +      oneseq   - increment is the default increment.
 +      specific - increment is runtime setable and defaults to the default (same as oneseq)
 +  output_previous
 +      if true then the pre-advance version (increasing instruction-level parallelism)
 +      if false then use the post-advance version (reducing register pressure)
 +  mult_
 +      optionally set the multiplier for the LCG.
 +/
struct PermutedCongruentialEngine(alias output,        // Output function
                                  stream_t stream,     // The stream type
                                  bool output_previous,
                                  mult_...) if (mult_.length <= 1)
{
    ///
    enum isRandomEngine = true;

    ///
    alias Uint  = TemplateArgsOf!output[1];

    static if (mult_.length == 0)
        enum mult = default_multiplier!Uint;
    else
    {
        static assert(is(typeof(mult_[0]) == Uint),
            "The specified multiplier must be the state type of the output function");
        enum mult = mult_[0];
    }
        
    @disable this(this);
    @disable this();
    static if (stream == stream_t.none)
        mixin no_stream!Uint;
    else static if (stream == stream_t.unique)
        mixin unique_stream!Uint;
    else static if (stream == stream_t.specific)
        mixin specific_stream!Uint;
    else static if (stream == stream_t.oneseq)
        mixin oneseq_stream!Uint;
    else
        static assert(0);

    ///
    Uint state;
    
    ///
    enum period_pow2 = Uint.sizeof*8 - 2*is_mcg;

    ///
    enum max = (ReturnType!output).max;

private:

    static if (__traits(compiles, { enum e = mult + increment; }))
    {
        static Uint bump()(Uint state_)
        {
            return cast(Uint)(state_ * mult + increment);
        }
    }
    else
    {
        Uint bump()(Uint state_)
        {
            return cast(Uint)(state_ * mult + increment);
        }
    }

    Uint base_generate()()
    {
        return state = bump(state);
    }

    Uint base_generate0()()
    {
        Uint old_state = state;
        state = bump(state);
        return old_state;
    }

public:
    static if (can_specify_stream)
    ///
    this()(Uint seed, Uint stream_ = default_increment_unset_stream!Uint)
    {
        state = bump(cast(Uint)(seed + increment));
        set_stream(stream_);
    }
    else
    ///
    this()(Uint seed)
    {
        static if (is_mcg)
            state = seed | 3u;
        else
            state = bump(cast(Uint)(seed + increment));
    }

    ///
    ReturnType!output opCall()()
    {
        static if(output_previous)
            return output(base_generate0());
        else
            return output(base_generate());
    }

    /++
    Skip forward in the random sequence in $(BIGOH log n) time.
    Even though delta is an unsigned integer, we can pass a
    signed integer to go backwards, it just goes "the long way round".
    +/
    void skip()(Uint delta)
    {
        // The method used here is based on Brown, "Random Number Generation
        // with Arbitrary Stride,", Transactions of the American Nuclear
        // Society (Nov. 1994).  The algorithm is very similar to fast
        // exponentiation.
        //
        // Even though delta is an unsigned integer, we can pass a
        // signed integer to go backwards, it just goes "the long way round".
        
        Uint acc_mult = 1, acc_plus = 0;
        Uint cur_plus = increment, cur_mult = mult;
        while (delta > 0)
        {
            if (delta & 1)
            {
                acc_mult *= cur_mult;
                acc_plus = cast(Uint)(acc_plus * cur_mult + cur_plus);
            }
            cur_plus  *= cur_mult + 1;
            cur_mult *= cur_mult;
            delta >>= 1;
        }
        state = cast(Uint)(acc_mult*state + acc_plus);
    }

    static if (output_previous)
    {
        /++
        Compatibility with $(LINK2 https://dlang.org/phobos/std_random.html#.isUniformRNG,
        Phobos library methods). Presents this RNG as an InputRange.
        Only available if `output_previous == true`.

        The reason that this is enabled when `output_previous == true` is because
        `front` can be implemented without additional cost.

        This struct disables its default copy constructor and so will only work with
        Phobos functions that "do the right thing" and take RNGs by reference and
        do not accidentally make implicit copies.
        +/
        enum bool isUniformRandom = true;
        /// ditto
        enum ReturnType!output min = (ReturnType!output).min;
        /// ditto
        enum bool empty = false;
        /// ditto
        @property ReturnType!output front()() const { return output(state); }
        /// ditto
        void popFront()() { state = bump(state); }
        /// ditto
        void seed()(Uint seed) { this.__ctor(seed); }
    }
}

@nogc nothrow pure @safe version(mir_random_test) unittest
{
    //Test that the default generators (all having output_previous==true)
    //can be used as Phobos-style randoms.
    import std.meta: AliasSeq;
    import std.random: isSeedable, isPhobosUniformRNG = isUniformRNG;
    foreach(RNG; AliasSeq!(pcg32, pcg32_oneseq, pcg32_fast,
                           pcg32_once_insecure, pcg32_oneseq_once_insecure,
                           pcg64_once_insecure, pcg64_oneseq_once_insecure))
    {
        static assert(isPhobosUniformRNG!(RNG, typeof(RNG.max)));
        static assert(isSeedable!(RNG, RNG.Uint));
        auto gen1 = RNG(1);
        auto gen2 = RNG(2);
        gen2.seed(1);
        assert(gen1 == gen2);
        immutable a = gen1.front;
        gen1.popFront();
        assert(a == gen2());
        assert(gen1.front == gen2());
    }

    foreach(RNG; AliasSeq!(pcg32_unique))
    {
        static assert(isPhobosUniformRNG!(RNG, typeof(RNG.max)));
        static assert(isSeedable!(RNG, RNG.Uint));
    }
}

// Default multiplier to use for the LCG portion of the PCG
private template default_multiplier(Uint)
{
    static if (is(Uint == ubyte))
        enum ubyte default_multiplier = 141u;
    else static if (is(Uint == ushort))
        enum ushort default_multiplier = 12829u;
    else static if (is(Uint == uint))
        enum uint default_multiplier = 747796405u;
    else static if (is(Uint == ulong))
        enum ulong default_multiplier = 6364136223846793005u;
    else static if (is(ucent) && is(Uint == ucent))
        mixin("enum ucent default_multiplier = 0x2360ED051FC65DA44385DF649FCCF645;");
    else
        static assert(0);
}

// Default increment to use for the LCG portion of the PCG
private template default_increment(Uint)
{
    static if (is(Uint == ubyte))
        enum ubyte default_increment = 77u;
    else static if (is(Uint == ushort))
        enum ushort default_increment = 47989u;
    else static if (is(Uint == uint))
        enum uint default_increment = 2891336453u;
    else static if (is(Uint == ulong))
        enum ulong default_increment = 1442695040888963407u;
    else static if (is(ucent) && is(Uint == ucent))
        mixin("enum ucent default_increment = 0x5851F42D4C957F2D14057B7EF767814F;");
    else
        static assert(0);
}

private template mcg_multiplier(Uint)
{
    static if (is(Uint == ubyte))
        enum ubyte mcg_multiplier = 217u;
    else static if (is(Uint == ushort))
        enum ushort mcg_multiplier = 62169u;
    else static if (is(Uint == uint))
        enum uint mcg_multiplier = 277803737u;
    else static if (is(Uint == ulong))
        enum ulong mcg_multiplier = 12605985483714917081u;
    else static if (is(ucent) && is(Uint == ucent))
        mixin("enum ucent mcg_multiplier = 0x6BC8F622C397699CAEF17502108EF2D9;");
    else
        static assert(0);
}

private template mcg_unmultiplier(Uint)
{
    static if (is(Uint == ubyte))
        enum ubyte mcg_unmultiplier = 105u;
    else static if (is(Uint == ushort))
        enum ushort mcg_unmultiplier = 28009u;
    else static if (is(Uint == uint))
        enum uint mcg_unmultiplier = 2897767785u;
    else static if (is(Uint == ulong))
        enum ulong mcg_unmultiplier = 15009553638781119849u;
    else static if (is(ucent) && is(Uint == ucent))
        mixin("enum ucent mcg_unmultiplier = 0xC827645E182BC965D04CA582ACB86D69;");
    else
        static assert(0);
}

private template default_increment_unset_stream(Uint)
{
    enum default_increment_unset_stream = (default_increment!Uint & ~1) >> 1;
}

/// Increment for LCG portion of the PCG is the address of the RNG
mixin template unique_stream(Uint)
{
    ///
    enum is_mcg = false;
    ///
    @property Uint increment()() const @trusted
    {
        return cast(Uint) (&this) | 1;
    }
    ///
    Uint stream()()
    {
        return increment >> 1;
    }
    ///
    enum can_specify_stream = false;
    ///
    enum size_t streams_pow2 = Uint.sizeof < size_t.sizeof ? Uint.sizeof : size_t.sizeof - 1u;
}

@nogc nothrow pure @system unittest
{
    pcg32_unique gen = pcg32_unique(1);
    void* address = &gen;
    assert(gen.increment == (1 | cast(ulong) address));
}


/// Increment is 0. The LCG portion of the PCG is an MCG.
mixin template no_stream(Uint)
{
    ///
    enum is_mcg = true;
    ///
    enum Uint increment = 0;
    
    ///
    enum can_specify_stream = false;
    ///
    enum size_t streams_pow2 = 0;
}

/// Increment of the LCG portion of the PCG is default_increment.
mixin template oneseq_stream(Uint)
{
    ///
    enum is_mcg = false;
    ///
    enum Uint increment = default_increment!Uint;
    ///
    enum can_specify_stream = false;
    ///
    enum size_t streams_pow2 = 0;
}

/// The increment is dynamically settable and defaults to default_increment!T.
mixin template specific_stream(Uint)
{
    ///
    enum is_mcg = false;
    ///
    Uint inc_ = default_increment!Uint;
    ///
    @property Uint increment()() { return inc_; }
    ///
    @property void increment()(Uint u) { inc_ = u;}
    ///
    enum can_specify_stream = true;
    ///
    void set_stream()(Uint u)
    {
        inc_ = cast(Uint)((u << 1) | 1);
    }
    ///
    enum size_t streams_pow2 = size_t.sizeof*8 -1u;
}

/// Select the above mixin templates.
enum stream_t
{
    unique,
    none,
    oneseq,
    specific,
}

/++
 + XorShifts are invertable, but they are someting of a pain to invert.
 + This function backs them out.  It's used by the whacky "inside out"
 + generator defined later.
 +/
Uint unxorshift(Uint)(Uint x, size_t bits, size_t shift)
{
    if (2*shift >= bits) {
        return x ^ (x >> shift);
    }
    Uint lowmask1 = (itype(1U) << (bits - shift*2)) - 1;
    Uint highmask1 = ~lowmask1;
    Uint top1 = x;
    Uint bottom1 = x & lowmask1;
    top1 ^= top1 >> shift;
    top1 &= highmask1;
    x = top1 | bottom1;
    Uint lowmask2 = (itype(1U) << (bits - shift)) - 1;
    Uint bottom2 = x & lowmask2;
    bottom2 = unxorshift(bottom2, bits - shift, shift);
    bottom2 &= lowmask1;
    return top1 | bottom2;
}


/++
 + OUTPUT FUNCTIONS.
 +
 + These are the core of the PCG generation scheme.  They specify how to
 + turn the base LCG's internal state into the output value of the final
 + generator.
 +
 + All of the classes have code that is written to allow it to be applied
 + at *arbitrary* bit sizes.
 +/

/++
 + XSH RS -- high xorshift, followed by a random shift
 +
 + Fast.  A good performer.
 +/
O xsh_rs(O, Uint)(Uint state)
{
    enum bits        = Uint.sizeof * 8;
    enum xtypebits   = O.sizeof * 8;
    enum sparebits   = bits - xtypebits;
    enum opbits = sparebits-5 >= 64 ? 5
                : sparebits-4 >= 32 ? 4
                : sparebits-3 >= 16 ? 3
                : sparebits-2 >= 4  ? 2
                : sparebits-1 >= 1  ? 1
                :                     0;
    enum mask           = (1 << opbits) - 1;
    enum maxrandshift   = mask;
    enum topspare       = opbits;
    enum bottomspare    = sparebits - topspare;
    enum xshift         = topspare + (xtypebits+maxrandshift)/2;
    
    auto rshift = opbits ? size_t(state >> (bits - opbits)) & mask : 0;
    state ^= state >> xshift;
    O result = O(s >> (bottomspare - maxrandshift + rshift));
    return result;
}
/++
 + XSH RR -- high xorshift, followed by a random rotate
 +
 + Fast.  A good performer.  Slightly better statistically than XSH RS.
 +/
O xsh_rr(O, Uint)(Uint state)
{
    enum bits        = Uint.sizeof * 8;
    enum xtypebits   = O.sizeof * 8;
    enum sparebits   = bits - xtypebits;
    enum wantedopbits =   xtypebits >= 128 ? 7
                        : xtypebits >=  64 ? 6
                        : xtypebits >=  32 ? 5
                        : xtypebits >=  16 ? 4
                        :                    3;
    enum opbits = sparebits >= wantedopbits ? wantedopbits : sparebits;
    enum amplifier = wantedopbits - opbits;
    enum mask = (1 << opbits) - 1;
    enum topspare    = opbits;
    enum bottomspare = sparebits - topspare;
    enum xshift      = (topspare + xtypebits)/2;
    
    auto rot = opbits ? size_t(state >> (bits - opbits)) & mask : 0;
    auto amprot = (rot << amplifier) & mask;
    state ^= state >> xshift;
    O result = cast(O)(state >> bottomspare);
    import core.bitop: ror;
    result = ror(result, cast(uint)amprot);
    return result;
}
/++
 + RXS -- random xorshift
 +/
O rxs(O, Uint)(Uint state)
{
    enum bits        = Uint.sizeof * 8;
    enum xtypebits   = O.sizeof * 8;
    enum shift       = bits - xtypebits;
    enum extrashift  = (xtypebits - shift)/2;
    enum rshift = shift > 64+8 ? (s >> (bits - 6)) & 63
                  : shift > 32+4 ? (s >> (bits - 5)) & 31
                  : shift > 16+2 ? (s >> (bits - 4)) & 15
                  : shift >  8+1 ? (s >> (bits - 3)) & 7
                  : shift >  4+1 ? (s >> (bits - 2)) & 3
                  : shift >  2+1 ? (s >> (bits - 1)) & 1
                  : 0;
    state ^= state >> (shift + extrashift - rshift);
    O result = state >> rshift;
    return result;
}
/++
 + RXS M XS -- random xorshift, mcg multiply, fixed xorshift
 +
 + The most statistically powerful generator, but all those steps
 + make it slower than some of the others.  We give it the rottenest jobs.
 +
 + Because it's usually used in contexts where the state type and the
 + result type are the same, it is a permutation and is thus invertable.
 + We thus provide a function to invert it.  This function is used to
 + for the "inside out" generator used by the extended generator.
 +/
O rxs_m_xs_forward(O, Uint)(Uint state)
    if(is(O == Uint))
{
    enum bits        = Uint.sizeof * 8;
    enum xtypebits   = O.sizeof * 8;
    enum opbits = xtypebits >= 128 ? 6
                : xtypebits >=  64 ? 5
                : xtypebits >=  32 ? 4
                : xtypebits >=  16 ? 3
                :                    2;
    enum shift = bits - xtypebits;
    enum mask = (1 << opbits) - 1;
    size_t rshift = opbits ? (state >> (bits - opbits)) & mask : 0;
    state ^= state >> (opbits + rshift);
    state *= mcg_multiplier!Uint;
    O result = state >> shift;
    result ^= result >> ((2U*xtypebits+2U)/3U);
    return result;
}
/// ditto
O rxs_m_xs_reverse(O, Uint)(Uint state)
    if(is(O == Uint))
{
    enum bits        = Uint.sizeof * 8;
    enum opbits = bits >= 128 ? 6
                : bits >=  64 ? 5
                : bits >=  32 ? 4
                : bits >=  16 ? 3
                :               2;
    enum mask = (1 << opbits) - 1;
    
    state = unxorshift(state, bits, (2U*bits+2U)/3U);
    
    state *= mcg_unmultiplier!Uint;
    
    auto rshift = opbits ? (state >> (bits - opbits)) & mask : 0;
    state = unxorshift(s, bits, opbits + rshift);
    
    return s;
}
/++
 + XSL RR -- fixed xorshift (to low bits), random rotate
 +
 + Useful for 128-bit types that are split across two CPU registers.
 +/
O xsl_rr(O, Uint)(Uint state)
{
    enum bits        = Uint.sizeof * 8;
    enum xtypebits   = O.sizeof * 8;
    enum sparebits = bits - xtypebits;
    enum wantedopbits =   xtypebits >= 128 ? 7
                        : xtypebits >=  64 ? 6
                        : xtypebits >=  32 ? 5
                        : xtypebits >=  16 ? 4
                        :                    3;
    enum opbits = sparebits >= wantedopbits ? wantedopbits : sparebits;
    enum amplifier = wantedopbits - opbits;
    enum mask = (1 << opbits) - 1;
    enum topspare = sparebits;
    enum bottomspare = sparebits - topspare;
    enum xshift = (topspare + xtypebits) / 2;
    
    auto rot = opbits ? size_t(state >> (bits - opbits)) & mask : 0;
    auto amprot = (rot << amplifier) & mask;
    state ^= state >> xshift;
    O result = state >> bottomspare;
    result = rotr(result, amprot);
    return result;
}

private template half_size(Uint)
{
    static if (is(Uint == ucent))
        alias half_size = ulong;
    else static if (is(Uint == ulong))
        alias half_size = uint;
    else static if (is(Uint == uint))
        alias half_size = ushort;
    else static if (is(Uint == ushort))
        alias half_size = ubyte;
    else
        static assert(0);
}

/++
 + XSL RR RR -- fixed xorshift (to low bits), random rotate (both parts)
 +
 + Useful for 128-bit types that are split across two CPU registers.
 + If you really want an invertable 128-bit RNG, I guess this is the one.
 +/

O xsl_rr_rr(O, Uint)(Uint state)
    if(is(O == Uint))
{
    alias H = half_size!Uint;
    enum htypebits = H.sizeof * 8;
    enum bits      = Uint.sizeof * 8;
    enum sparebits = bits - htypebits;
    enum wantedopbits =   htypebits >= 128 ? 7
                        : htypebits >=  64 ? 6
                        : htypebits >=  32 ? 5
                        : htypebits >=  16 ? 4
                        :                    3;
    enum opbits = sparebits >= wantedopbits ? wantedopbits : sparebits;
    enum amplifier = wantedopbits - opbits;
    enum mask = (1 << opbits) - 1;
    enum topspare = sparebits;
    enum xshift = (topspare + htypebits) / 2;
    
    auto rot = opbits ? size_t(s >> (bits - opbits)) & mask : 0;
    auto amprot = (rot << amplifier) & mask;
    state ^= state >> xshift;
    H lowbits = cast(H)s;
    lowbits = rotr(lowbits, amprot);
    H highbits = cast(H)(s >> topspare);
    auto rot2 = lowbits & mask;
    auto amprot2 = (rot2 << amplifier) & mask;
    highbits = rotr(highbits, amprot2);
    return (O(highbits) << topspare) ^ O(lowbits);
    
}

/++
 + XSH -- fixed xorshift (to high bits)
 +
 + Not available at 64-bits or less.
 +/

O xsh(O, Uint)(Uint state) if(Uint.sizeof > 8)
{
    enum bits        = Uint.sizeof * 8;
    enum xtypebits   = O.sizeof * 8;
    enum sparebits = bits - xtypebits;
    enum topspare = 0;
    enum bottomspare = sparebits - topspare;
    enum xshift = (topspare + xtypebits) / 2;
    
    state ^= state >> xshift;
    O result = state >> bottomspare;
    return result;
}

/++
 + XSL -- fixed xorshift (to low bits)
 +
 + Not available at 64-bits or less.
 +/

O xsl(O, Uint)(Uint state) if(Uint.sizeof > 8)
{
    enum bits        = Uint.sizeof * 8;
    enum xtypebits   = O.sizeof * 8;
    enum sparebits = bits - xtypebits;
    enum topspare = sparebits;
    enum bottomspare = sparebits - topspare;
    enum xshift = (topspare + xtypebits) / 2;
    
    state ^= state >> xshift;
    O result = state >> bottomspare;
    return result;
}

private alias AliasSeq(T...) = T;

@safe version(mir_random_test) unittest
{
    
    foreach(RNG; AliasSeq!(pcg32,pcg32_unique,pcg32_oneseq,pcg32_fast,
                           pcg8_once_insecure,pcg16_once_insecure,pcg32_once_insecure,pcg64_once_insecure,
                           pcg8_oneseq_once_insecure,pcg16_oneseq_once_insecure,pcg32_oneseq_once_insecure,
                           pcg64_oneseq_once_insecure))
    {
        static assert(isSaturatedRandomEngine!RNG);
        auto gen = RNG(cast(RNG.Uint)unpredictableSeed);
        gen();
    }
}
@safe version(mir_random_test) unittest
{
    auto gen = pcg32(0x198c8585);
    gen.skip(1000);
    assert(gen()== 0xd187a760);
    auto gen2 = pcg32(0x198c8585);
    
    foreach(_; 0 .. 1000)
        gen2();
    assert(gen2() == 0xd187a760);
    assert(gen() == gen2());
}

@nogc nothrow pure @safe unittest
{
    foreach (ShouldHaveStaticBump; AliasSeq!(pcg32_oneseq, pcg32_fast, pcg32_oneseq_once_insecure))
        static assert (__traits(compiles, { enum e = ShouldHaveStaticBump.bump(1u); }));

    foreach (ShouldLackStaticBump; AliasSeq!(pcg32, pcg32_unique, pcg32_once_insecure))
        static assert (!__traits(compiles, { enum e = ShouldLackStaticBump.bump(1u); }));
}
