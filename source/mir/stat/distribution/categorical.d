/++
This module contains algorithms for the $(LINK2 https://en.wikipedia.org/wiki/Categorical_distribution, Categorical Distribution).

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2023 Mir Stat Authors.

+/

module mir.stat.distribution.categorical;

import mir.algorithm.iteration: all;
import mir.internal.utility: isFloatingPoint;
import mir.math.common: approxEqual;
import mir.math.sum: elementType, sumType, sum;
import mir.ndslice.slice: Slice, SliceKind;
import std.traits: CommonType;

/++
Computes the Categorical probability mass function (PMF).

Params:
    x = value to evaluate PMF
    p = slice containing the probability associated with the Categorical Distribution

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Categorical_distribution, Categorical Distribution)
+/
@safe pure nothrow @nogc
elementType!(Slice!(Iterator, 1, kind)) categoricalPMF(Iterator, SliceKind kind)(const size_t x, scope const Slice!(Iterator, 1, kind) p)
    if (isFloatingPoint!(elementType!(Slice!(Iterator, 1, kind))))
    in (x < p.length, "x must be less than the length of p")
    in (p.sum.approxEqual(1.0), "p must sum to 1")
    in (p.all!("a >= 0"), "p must be greater than or equal to 0")
    in (p.all!("a <= 1"), "p must be less than or equal to 1")
{
    return p[x];
}

/// ditto
@safe pure nothrow @nogc
T categoricalPMF(T)(const size_t x, scope const T[] p...)
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

/// Can also use dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.test: shouldApprox;

    double[] p = [0.1, 0.5, 0.4];

    0.categoricalPMF(p).shouldApprox == 0.1;
    1.categoricalPMF(p).shouldApprox == 0.5;
    2.categoricalPMF(p).shouldApprox == 0.4;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: sum;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    static immutable x = [1.0, 5, 4];
    auto p = x.sliced;
    auto q = p / sum(p);

    0.categoricalPMF(q).shouldApprox == 0.1;
    1.categoricalPMF(q).shouldApprox == 0.5;
    2.categoricalPMF(q).shouldApprox == 0.4;
}

/++
Computes the Categorical cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF
    p = slice containing the probability associated with the Categorical Distribution

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Categorical_distribution, Categorical Distribution)
+/
@safe pure nothrow @nogc
sumType!(Slice!(Iterator, 1, kind)) categoricalCDF(Iterator, SliceKind kind)(const size_t x, scope const Slice!(Iterator, 1, kind) p)
    if (isFloatingPoint!(elementType!(Slice!(Iterator, 1, kind))))
    in (x < p.length, "x must be less than the length of p")
    in (p.sum.approxEqual(1.0), "p must sum to 1")
    in (p.all!("a >= 0"), "p must be greater than or equal to 0")
    in (p.all!("a <= 1"), "p must be less than or equal to 1")
{
    return p[0 .. (x + 1)].sum;
}

/// ditto
@safe pure nothrow @nogc
T categoricalCDF(T)(const size_t x, scope const T[] p...)
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

/// Can also use dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.test: shouldApprox;

    double[] p = [0.1, 0.5, 0.4];

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
@safe pure nothrow @nogc
sumType!(Slice!(Iterator, 1, kind)) categoricalCCDF(Iterator, SliceKind kind)(const size_t x, scope const Slice!(Iterator, 1, kind) p)
    if (isFloatingPoint!(elementType!(Slice!(Iterator, 1, kind))))
    in (x < p.length, "x must be less than the length of p")
    in (p.sum.approxEqual(1.0), "p must sum to 1")
    in (p.all!("a >= 0"), "p must be greater than or equal to 0")
    in (p.all!("a <= 1"), "p must be less than or equal to 1")
{
    return p[x .. $].sum;
}

/// ditto
@safe pure nothrow @nogc
T categoricalCCDF(T)(const size_t x, scope const T[] p...)
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

/// Can also use dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.test: shouldApprox;

    double[] p = [0.1, 0.5, 0.4];

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
@safe pure nothrow @nogc
size_t categoricalInvCDF(T, Iterator, SliceKind kind)(const T q, scope const Slice!(Iterator, 1, kind) p)
    if (isFloatingPoint!(CommonType!(T, elementType!(Slice!(Iterator, 1, kind)))))
    in (q >= 0, "q must be greater than or equal to 0")
    in (q <= 1, "q must be less than or equal to 1")
    in (p.sum.approxEqual(1.0), "p must sum to 1")
    in (p.all!("a >= 0"), "p must be greater than or equal to 0")
    in (p.all!("a <= 1"), "p must be less than or equal to 1")
{
    CommonType!(T, elementType!(typeof(p))) s = 0.0;
    size_t i;
    s += p[i];
    while (q > s) {
        i++;
        s += p[i];
    }
    return i;// this ensures categoricalInvCDF(a, p) == b, which is consistent with categoricalCDF(b, p) == a (similar to bernoulliInvCDF)
}

/// ditto
@safe pure nothrow @nogc
size_t categoricalInvCDF(T)(const T q, scope const T[] p...)
    if (isFloatingPoint!T)
    in (q >= 0, "q must be greater than or equal to 0")
    in (q <= 1, "q must be less than or equal to 1")
    in (p.sum.approxEqual(1.0), "p must sum to 1")
    in (p.all!("a >= 0"), "p must be greater than or equal to 0")
    in (p.all!("a <= 1"), "p must be less than or equal to 1")
{
    T s = 0.0;
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

/// Can also use dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.test: should;

    double[] p = [0.1, 0.5, 0.4];

    categoricalInvCDF(0.5, p).should == 1;
}

/++
Computes the Categorical log probability mass function (LPMF).

Params:
    x = value to evaluate LPMF
    p = slice containing the probability associated with the Categorical Distribution

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Categorical_distribution, Categorical Distribution)
+/
@safe pure nothrow @nogc
elementType!(Slice!(Iterator, 1, kind)) categoricalLPMF(Iterator, SliceKind kind)(const size_t x, scope const Slice!(Iterator, 1, kind) p)
    if (isFloatingPoint!(elementType!(Slice!(Iterator, 1, kind))))
    in (x < p.length, "x must be less than the length of p")
    in (p.sum.approxEqual(1.0), "p must sum to 1")
    in (p.all!("a >= 0"), "p must be greater than or equal to 0")
    in (p.all!("a <= 1"), "p must be less than or equal to 1")
{
    import mir.math.common: log;
    return x.categoricalPMF(p).log;
}

/// ditto
@safe pure nothrow @nogc
T categoricalLPMF(T)(const size_t x, scope const T[] p...)
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

/// Can also use dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: log;
    import mir.test: shouldApprox;

    double[] p = [0.1, 0.5, 0.4];

    0.categoricalLPMF(p).shouldApprox == log(0.1);
    1.categoricalLPMF(p).shouldApprox == log(0.5);
    2.categoricalLPMF(p).shouldApprox == log(0.4);
}
