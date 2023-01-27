/++
This module contains algorithms for the Categorical Distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2023 Mir Stat Authors.

+/

module mir.stat.distribution.categorical;

import mir.algorithm.iteration: all;
import mir.internal.utility: isFloatingPoint;
import mir.math.common: approxEqual;
import mir.ndslice.slice: Slice, SliceKind;

private T sum(T)(const Slice!(T*, 1) p) {
    import std.traits: Unqual;

    Unqual!T output = 0;
    foreach (e; p) {
        output += e;
    }
    return output;
}

/++
Computes the Categorical probability mass function (PMF).

Params:
    x = value to evaluate PMF
    p = slice containing the probability associated with the Categorical Distribution

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Categorical_distribution, Categorical Distribution)
+/
T categoricalPMF(T)(const size_t x, const Slice!(T*, 1) p)
    if (isFloatingPoint!T)
    in (x < p.length, "x must be less than the length of p")
    in (p.sum.approxEqual(1.0), "p must sum to 1")
    in (p.all!("a >= 0"), "p must be greater than or equal to 0")
    in (p.all!("a <= 1"), "p must be less than or equal to 1")
{
    return p[x];
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    static immutable x = [0.1, 0.5, 0.4];
    auto p = x.sliced;

    0.categoricalPMF(p).shouldApprox == 0.1;
    1.categoricalPMF(p).shouldApprox == 0.5;
    2.categoricalPMF(p).shouldApprox == 0.4;
}

/++
Computes the Categorical cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF
    p = slice containing the probability associated with the Categorical Distribution

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Categorical_distribution, Categorical Distribution)
+/
T categoricalCDF(T)(const size_t x, const Slice!(T*, 1) p)
    if (isFloatingPoint!T)
    in (x < p.length, "x must be less than the length of p")
    in (p.sum.approxEqual(1.0), "p must sum to 1")
    in (p.all!("a >= 0"), "p must be greater than or equal to 0")
    in (p.all!("a <= 1"), "p must be less than or equal to 1")
{
    return p[0 .. (x + 1)].sum;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    static immutable x = [0.1, 0.5, 0.4];
    auto p = x.sliced;

    0.categoricalCDF(p).shouldApprox == 0.1;
    1.categoricalCDF(p).shouldApprox == 0.6;
    2.categoricalCDF(p).shouldApprox == 1.0;
}

/++
Computes the Categorical complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    p = slice containing the probability associated with the Categorical Distribution

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Categorical_distribution, Categorical Distribution)
+/
T categoricalCCDF(T)(const size_t x, const Slice!(T*, 1) p)
    if (isFloatingPoint!T)
    in (x < p.length, "x must be less than the length of p")
    in (p.sum.approxEqual(1.0), "p must sum to 1")
    in (p.all!("a >= 0"), "p must be greater than or equal to 0")
    in (p.all!("a <= 1"), "p must be less than or equal to 1")
{
    return p[x .. $].sum;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    static immutable x = [0.1, 0.5, 0.4];
    auto p = x.sliced;

    0.categoricalCCDF(p).shouldApprox == 1.0;
    1.categoricalCCDF(p).shouldApprox == 0.9;
    2.categoricalCCDF(p).shouldApprox == 0.4;
}

/++
Computes the Categorical inverse cumulative distribution function (InvCDF).

Params:
    q = value to evaluate InvCDF
    p = slice containing the probability associated with the Categorical Distribution

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Categorical_distribution, Categorical Distribution)
+/
size_t categoricalInvCDF(T)(const T q, const Slice!(T*, 1) p)
    if (isFloatingPoint!T)
    in (q >= 0, "q must be greater than or equal to 0")
    in (q <= 1, "q must be less than or equal to 1")
    in (p.sum.approxEqual(1.0), "p must sum to 1")
    in (p.all!("a >= 0"), "p must be greater than or equal to 0")
    in (p.all!("a <= 1"), "p must be less than or equal to 1")
{
    import std.traits: Unqual;

    Unqual!T s = 0.0;
    size_t i;
    s += p[i];
    while (q > s) {
        i++;
        s += p[i];
    }
    return i;// this ensures categoricalInvCDF(a, p) == b, which is consistent with categoricalCDF(b, p) == a (similar to bernoulliInvCDF)
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.test: should;

    static immutable x = [0.1, 0.5, 0.4];
    auto p = x.sliced;

    categoricalInvCDF(0.0, p).should == 0;
    categoricalInvCDF(0.1, p).should == 0;
    categoricalInvCDF(0.2, p).should == 1;
    categoricalInvCDF(0.3, p).should == 1;
    categoricalInvCDF(0.4, p).should == 1;
    categoricalInvCDF(0.5, p).should == 1;
    categoricalInvCDF(0.6, p).should == 1;
    categoricalInvCDF(0.7, p).should == 2;
    categoricalInvCDF(0.8, p).should == 2;
    categoricalInvCDF(0.9, p).should == 2;
    categoricalInvCDF(1.0, p).should == 2;
}

/++
Computes the Categorical log probability mass function (LPMF).

Params:
    x = value to evaluate LPMF
    p = slice containing the probability associated with the Categorical Distribution

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Categorical_distribution, Categorical Distribution)
+/
T categoricalLPMF(T)(const size_t x, const Slice!(T*, 1) p)
    if (isFloatingPoint!T)
    in (x < p.length, "x must be less than the length of p")
    in (p.sum.approxEqual(1.0), "p must sum to 1")
    in (p.all!("a >= 0"), "p must be greater than or equal to 0")
    in (p.all!("a <= 1"), "p must be less than or equal to 1")
{
    import mir.math.common: log;
    return x.categoricalPMF(p).log;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: log;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    static immutable x = [0.1, 0.5, 0.4];
    auto p = x.sliced;

    0.categoricalLPMF(p).shouldApprox == log(0.1);
    1.categoricalLPMF(p).shouldApprox == log(0.5);
    2.categoricalLPMF(p).shouldApprox == log(0.4);
}
