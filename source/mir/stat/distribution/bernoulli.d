/++
This module contains algorithms for the bernoulli probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.bernoulli;

import mir.internal.utility: isFloatingPoint;

/++
Computes the bernoulli probability mass function (PMF).

Params:
    x = value to evaluate PMF
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Bernoulli_distribution, bernoulli probability distribution)
+/
@safe pure nothrow @nogc
T bernoulliPMF(T)(const bool x, const T p)
    if (isFloatingPoint!T)
    in(p >= 0, "p must be greater than or equal to 0")
    in(p <= 1, "p must be less than or equal to 1")
{
    return p * x + (1 - p) * (1 - x);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(true.bernoulliPMF(0.5) == 0.5);
    assert(false.bernoulliPMF(0.5) == 0.5);

    assert(true.bernoulliPMF(0.7).approxEqual(0.7));
    assert(false.bernoulliPMF(0.7).approxEqual(0.3));
}

/++
Computes the bernoulli cumulatve distribution function (CDF).

Params:
    x = value to evaluate CDF
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Bernoulli_distribution, bernoulli probability distribution)
+/
@safe pure nothrow @nogc
T bernoulliCDF(T)(const bool x, const T p)
    if (isFloatingPoint!T)
    in(p >= 0, "p must be greater than or equal to 0")
    in(p <= 1, "p must be less than or equal to 1")
{
    return x + (1 - x) * (1 - p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(true.bernoulliCDF(0.5) == 1);
    assert(false.bernoulliCDF(0.5) == 0.5);

    assert(true.bernoulliCDF(0.7) == 1);
    assert(false.bernoulliCDF(0.7).approxEqual(0.3));
}

/++
Computes the bernoulli complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Bernoulli_distribution, bernoulli probability distribution)
+/
@safe pure nothrow @nogc
T bernoulliCCDF(T)(const bool x, const T p)
    if (isFloatingPoint!T)
    in(p >= 0, "p must be greater than or equal to 0")
    in(p <= 1, "p must be less than or equal to 1")
{
    return (1 - x) * p;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(true.bernoulliCCDF(0.5) == 0);
    assert(false.bernoulliCCDF(0.5) == 0.5);

    assert(true.bernoulliCCDF(0.7) == 0);
    assert(false.bernoulliCCDF(0.7).approxEqual(0.7));
}

/++
Computes the bernoulli inverse cumulative distribution function (InvCDF).

Params:
    q = value to evaluate InvCDF
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Bernoulli_distribution, bernoulli probability distribution)
+/
@safe pure nothrow @nogc
bool bernoulliInvCDF(T)(const T q, const T p)
    if (isFloatingPoint!T)
    in(q >= 0, "q must be greater than or equal to 0")
    in(q <= 1, "q must be less than or equal to 1")
    in(p >= 0, "p must be greater than or equal to 0")
    in(p <= 1, "p must be less than or equal to 1")
{
    return q > p; // this ensures bernoulliInvCDF(a, a) == false, which is consistent with bernoulliCDF(false, a) == a
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    assert(0.25.bernoulliInvCDF(0.5) == false);
    assert(0.5.bernoulliInvCDF(0.5) == false);
    assert(0.75.bernoulliInvCDF(0.5) == true);

    assert(0.3.bernoulliInvCDF(0.7) == false);
    assert(0.7.bernoulliInvCDF(0.7) == false);
    assert(0.9.bernoulliInvCDF(0.7) == true);
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    assert(0.0.bernoulliInvCDF(0.5) == false);
    assert(1.0.bernoulliInvCDF(0.5) == true);
    assert(0.0.bernoulliInvCDF(0.7) == false);
    assert(1.0.bernoulliInvCDF(0.7) == true);
}

/++
Computes the bernoulli log probability mass function (LPMF).

Params:
    x = value to evaluate LPDF
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Bernoulli_distribution, bernoulli probability distribution)
+/
@safe pure nothrow @nogc
T bernoulliLPMF(T)(const bool x, const T p)
    if (isFloatingPoint!T)
    in(p >= 0, "p must be greater than or equal to 0")
    in(p <= 1, "p must be less than or equal to 1")
{
    import mir.math.internal.xlogy: xlogy, xlog1py;

    return xlogy(x, p) + xlog1py(1 - x, -p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, log;

    assert(true.bernoulliLPMF(0.5).approxEqual(log(bernoulliPMF(true, 0.5))));
    assert(false.bernoulliLPMF(0.5).approxEqual(log(bernoulliPMF(false, 0.5))));

    assert(true.bernoulliLPMF(0.7).approxEqual(log(bernoulliPMF(true, 0.7))));
    assert(false.bernoulliLPMF(0.7).approxEqual(log(bernoulliPMF(false, 0.7))));
}
