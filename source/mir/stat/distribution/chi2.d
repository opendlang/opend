/++
This module contains algorithms for the chi-squared continuous distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: Ilia Ki

Copyright: 2022 Mir Stat Authors.
+/
module mir.stat.distribution.chi2;

import mir.internal.utility: isFloatingPoint;

/++
Computes the Chi-squared probability density function (PDF).

Params:
    x = value to evaluate PDF
    k = degrees of freedom

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Chi-squared_distribution, Chi-squared probability distribution)
+/
@safe pure nothrow @nogc
T chi2PDF(T)(const T x, const uint k)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (k >= 1, "k must be greater than or equal to 1")
{
    import mir.stat.distribution.gamma: gammaPDF;

    return gammaPDF(x, T(k) * 0.5f, 2);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;
    0.2.chi2PDF(2).shouldApprox == 0.4524187;
}

/++
Computes the Chi-squared cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF
    k = degrees of freedom

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Chi-squared_distribution, Chi-squared probability distribution)
+/
@safe pure nothrow @nogc
T chi2CDF(T)(const T x, const uint k)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (k >= 1, "k must be greater than or equal to 1")
{
    import mir.stat.distribution.gamma: gammaCDF;

    return gammaCDF(x, T(k) * 0.5f, 2);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;
    0.2.chi2CDF(2).shouldApprox == 0.09516258;
}

/++
Computes the Chi-squared complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    k = degrees of freedom

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Chi-squared_distribution, Chi-squared probability distribution)
+/
@safe pure nothrow @nogc
T chi2CCDF(T)(const T x, const uint k)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (k >= 1, "k must be greater than or equal to 1")
{
    import mir.stat.distribution.gamma: gammaCCDF;

    return gammaCCDF(x, T(k) * 0.5f , 2);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;
    0.2.chi2CCDF(2).shouldApprox == 0.9048374;
}

/++
Computes the Chi-squared inverse cumulative distribution function (InvCDF).

Params:
    x = value to evaluate InvCDF
    k = degrees of freedom

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Chi-squared_distribution, Chi-squared probability distribution)
+/
@safe pure nothrow @nogc
T chi2InvCDF(T)(const T x, const uint k)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (k >= 1, "k must be greater than or equal to 1")
{
    import mir.stat.distribution.gamma: gammaInvCDF;

    return gammaInvCDF(x, T(k) * 0.5f, 2);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;
    0.09516258.chi2InvCDF(2).shouldApprox == 0.2;
}

/++
Computes the Chi-squared probability density function (LogPDF).

Params:
    x = value to evaluate LogPDF
    k = degrees of freedom

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Chi-squared_distribution, Chi-squared probability distribution)
+/
@safe pure nothrow @nogc
T chi2LogPDF(T)(const T x, const uint k)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (k >= 1, "k must be greater than or equal to 1")
{
    import mir.math.common: log;
    import mir.math.constant: LN2;
    import std.mathspecial: logGamma;

    if (x == 0) {
        if (k > 2) {
            return -T.infinity;
        } else if (k < 2) {
            return T.infinity;
        } else {
            return -T(LN2);
        }
    }

    return (T(k) * 0.5f - 1) * (log(x) - T(LN2)) - x *0.5f - cast(T) logGamma(T(k) * 0.5f) - T(LN2);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;
    0.2.chi2LogPDF(2).shouldApprox == -0.7931472;
}

//
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;
    0.0.chi2LogPDF(2).shouldApprox == -0.6931472;
    0.0.chi2LogPDF(1).shouldApprox == double.infinity;
    0.0.chi2LogPDF(3).shouldApprox == -double.infinity;
}
