/++
This module contains algorithms for the beta probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.beta;

import mir.internal.utility: isFloatingPoint;

/++
Computes the beta probability distribution function (PDF).

Params:
    x = value to evaluate PDF
    alpha = shape parameter #1
    beta = shape parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Beta_distribution, beta probability distribution)
+/
@safe pure nothrow @nogc
T betaPDF(T)(const T x, const T alpha, const T beta)
    if (isFloatingPoint!T)
    in(x >= 0, "x must be greater than or equal to 0")
    in(x <= 1, "x must be less than or equal to 1")
    in(alpha > 0, "alpha must be greater than zero")
    in(beta > 0, "beta must be greater than zero")
{
    import mir.math.common: pow;
    import std.mathspecial: betaFunc = beta;

    return pow(x, (alpha - 1)) * pow((1 - x), (beta - 1)) / betaFunc(alpha, beta);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.5.betaPDF(1, 1) == 1);
    assert(0.75.betaPDF(1, 2).approxEqual(0.5));
    assert(0.25.betaPDF(0.5, 4).approxEqual(0.9228516));
}

/++
Computes the beta cumulatve distribution function (CDF).

Params:
    x = value to evaluate CDF
    alpha = shape parameter #1
    beta = shape parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Beta_distribution, beta probability distribution)
+/
@safe pure nothrow @nogc
T betaCDF(T)(const T x, const T alpha, const T beta)
    if (isFloatingPoint!T)
    in(x >= 0, "x must be greater than or equal to 0")
    in(x <= 1, "x must be less than or equal to 1")
    in(alpha > 0, "alpha must be greater than zero")
    in(beta > 0, "beta must be greater than zero")
{
    import std.mathspecial: betaIncomplete;

    return betaIncomplete(alpha, beta, x);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.5.betaCDF(1, 1).approxEqual(0.5));
    assert(0.75.betaCDF(1, 2).approxEqual(0.9375));
    assert(0.25.betaCDF(0.5, 4).approxEqual(0.8588867));
}

/++
Computes the beta complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    alpha = shape parameter #1
    beta = shape parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Beta_distribution, beta probability distribution)
+/
@safe pure nothrow @nogc
T betaCCDF(T)(const T x, const T alpha, const T beta)
    if (isFloatingPoint!T)
    in(x >= 0, "x must be greater than or equal to 0")
    in(x <= 1, "x must be less than or equal to 1")
    in(alpha > 0, "alpha must be greater than zero")
    in(beta > 0, "beta must be greater than zero")
{
    import std.mathspecial: betaIncomplete;

    return betaIncomplete(beta, alpha, 1 - x);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.5.betaCCDF(1, 1).approxEqual(0.5));
    assert(0.75.betaCCDF(1, 2).approxEqual(0.0625));
    assert(0.25.betaCCDF(0.5, 4).approxEqual(0.1411133));
}

/++
Computes the beta inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate InvCDF
    alpha = shape parameter #1
    beta = shape parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Beta_distribution, beta probability distribution)
+/
@safe pure nothrow @nogc
T betaInvCDF(T)(const T p, const T alpha, const T beta)
    if (isFloatingPoint!T)
    in(p >= 0, "p must be greater than or equal to 0")
    in(p <= 1, "p must be less than or equal to 1")
    in(alpha > 0, "alpha must be greater than zero")
    in(beta > 0, "beta must be greater than zero")
{
    import std.mathspecial: betaIncompleteInverse;

    return betaIncompleteInverse(alpha, beta, p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.5.betaInvCDF(1, 1).approxEqual(0.5));
    assert(0.9375.betaInvCDF(1, 2).approxEqual(0.75));
    assert(0.8588867.betaInvCDF(0.5, 4).approxEqual(0.25));
}

/++
Computes the beta log probability distribution function (LPDF).

Params:
    x = value to evaluate LPDF
    alpha = shape parameter #1
    beta = shape parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Beta_distribution, beta probability distribution)
+/
@safe pure nothrow @nogc
T betaLPDF(T)(const T x, const T alpha, const T beta)
    if (isFloatingPoint!T)
    in(x >= 0, "x must be greater than or equal to 0")
    in(x <= 1, "x must be less than or equal to 1")
    in(alpha > 0, "alpha must be greater than zero")
    in(beta > 0, "beta must be greater than zero")
{
    import mir.math.internal.log_beta: logBeta;
    import mir.math.internal.xlogy: xlogy, xlog1py;

    return xlogy(alpha - 1, x) + xlog1py(beta - 1, -x) - logBeta(alpha, beta);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, log;

    assert(0.5.betaLPDF(1, 1).approxEqual(log(betaPDF(0.5, 1, 1))));
    assert(0.75.betaLPDF(1, 2).approxEqual(log(betaPDF(0.75, 1, 2))));
    assert(0.25.betaLPDF(0.5, 4).approxEqual(log(betaPDF(0.25, 0.5, 4))));
}
