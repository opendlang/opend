/++
This module contains algorithms for the beta proportion probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.betaProportion;

import mir.internal.utility: isFloatingPoint;

/++
Computes the beta proportion probability distribution function (PDF).

Params:
    x = value to evaluate PDF
    mu = shape parameter #1
    kappa = shape parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Beta_distribution, beta probability distribution)
+/
@safe pure nothrow @nogc
T betaProportionPDF(T)(const T x, const T mu, const T kappa)
    if (isFloatingPoint!T)
    in(x >= 0, "x must be greater than or equal to 0")
    in(x <= 1, "x must be less than or equal to 1")
    in(mu > 0, "mu must be greater than zero")
    in(mu < 1, "mu must be less than one")
    in(kappa > 0, "kappa must be greater than zero")
{
    import mir.stat.distribution.beta: betaPDF;

    immutable T alpha = mu * kappa;
    immutable T beta = kappa - alpha;
    return betaPDF(x, alpha, beta);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.5.betaProportionPDF(0.5, 2) == 1);
    assert(0.75.betaProportionPDF((1.0 / 3), 3).approxEqual(0.5));
    assert(0.25.betaProportionPDF((1.0 / 9), 4.5).approxEqual(0.9228516));
}

/++
Computes the beta proportion cumulatve distribution function (CDF).

Params:
    x = value to evaluate CDF
    mu = shape parameter #1
    kappa = shape parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Beta_distribution, beta probability distribution)
+/
@safe pure nothrow @nogc
T betaProportionCDF(T)(const T x, const T mu, const T kappa)
    if (isFloatingPoint!T)
    in(x >= 0, "x must be greater than or equal to 0")
    in(x <= 1, "x must be less than or equal to 1")
    in(mu > 0, "mu must be greater than zero")
    in(mu < 1, "mu must be less than one")
    in(kappa > 0, "kappa must be greater than zero")
{
    import mir.stat.distribution.beta: betaCDF;

    immutable T alpha = mu * kappa;
    immutable T beta = kappa - alpha;
    return betaCDF(x, alpha, beta);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.5.betaProportionCDF(0.5, 2).approxEqual(0.5));
    assert(0.75.betaProportionCDF((1.0 / 3), 3).approxEqual(0.9375));
    assert(0.25.betaProportionCDF((1.0 / 9), 4.5).approxEqual(0.8588867));
}

/++
Computes the beta proportion complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    mu = shape parameter #1
    kappa = shape parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Beta_distribution, beta probability distribution)
+/
@safe pure nothrow @nogc
T betaProportionCCDF(T)(const T x, const T mu, const T kappa)
    if (isFloatingPoint!T)
    in(x >= 0, "x must be greater than or equal to 0")
    in(x <= 1, "x must be less than or equal to 1")
    in(mu > 0, "mu must be greater than zero")
    in(mu < 1, "mu must be less than one")
    in(kappa > 0, "kappa must be greater than zero")
{
    import mir.stat.distribution.beta: betaCCDF;

    immutable T alpha = mu * kappa;
    immutable T beta = kappa - alpha;
    return betaCCDF(x, alpha, beta);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.5.betaProportionCCDF(0.5, 2).approxEqual(0.5));
    assert(0.75.betaProportionCCDF((1.0 / 3), 3).approxEqual(0.0625));
    assert(0.25.betaProportionCCDF((1.0 / 9), 4.5).approxEqual(0.1411133));
}

/++
Computes the beta proportion inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate InvCDF
    mu = shape parameter #1
    kappa = shape parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Beta_distribution, beta probability distribution)
+/
@safe pure nothrow @nogc
T betaProportionInvCDF(T)(const T p, const T mu, const T kappa)
    if (isFloatingPoint!T)
    in(p >= 0, "p must be greater than or equal to 0")
    in(p <= 1, "p must be less than or equal to 1")
    in(mu > 0, "mu must be greater than zero")
    in(mu < 1, "mu must be less than one")
    in(kappa > 0, "kappa must be greater than zero")
{
    import mir.stat.distribution.beta: betaInvCDF;

    immutable T alpha = mu * kappa;
    immutable T beta = kappa - alpha;
    return betaInvCDF(p, alpha, beta);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.5.betaProportionInvCDF(0.5, 2).approxEqual(0.5));
    assert(0.9375.betaProportionInvCDF((1.0 / 3), 3).approxEqual(0.75));
    assert(0.8588867.betaProportionInvCDF((1.0 / 9), 4.5).approxEqual(0.25));
}

/++
Computes the beta proportion log probability distribution function (LPDF).

Params:
    x = value to evaluate LPDF
    mu = shape parameter #1
    kappa = shape parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Beta_distribution, beta probability distribution)
+/
@safe pure nothrow @nogc
T betaProportionLPDF(T)(const T x, const T mu, const T kappa)
    if (isFloatingPoint!T)
    in(x >= 0, "x must be greater than or equal to 0")
    in(x <= 1, "x must be less than or equal to 1")
    in(mu > 0, "mu must be greater than zero")
    in(mu < 1, "mu must be less than one")
    in(kappa > 0, "kappa must be greater than zero")
{
    import mir.stat.distribution.beta: betaLPDF;

    immutable T alpha = mu * kappa;
    immutable T beta = kappa - alpha;
    return betaLPDF(x, alpha, beta);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, log;

    assert(0.5.betaProportionLPDF(0.5, 2).approxEqual(log(betaProportionPDF(0.5, 0.5, 2))));
    assert(0.75.betaProportionLPDF((1.0 / 3), 3).approxEqual(log(betaProportionPDF(0.75, (1.0 / 3), 3))));
    assert(0.25.betaProportionLPDF((1.0 / 9), 4.5).approxEqual(log(betaProportionPDF(0.25, (1.0 / 9), 4.5))));
}
