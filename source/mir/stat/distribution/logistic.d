/++
This module contains algorithms for the Logistic distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2023 Mir Stat Authors.

+/

module mir.stat.distribution.logistic;

import mir.internal.utility: isFloatingPoint;

/++
Computes the Logistic probability density function (PDF).

Params:
    x = value to evaluate PDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Logistic_distribution, Logistic probability distribution)
+/
T logisticPDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: exp;

    const T exp_x = exp(-x);
    return exp_x / ((1 + exp_x) * (1 + exp_x));
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate PDF
    location = location parameter
    scale = scale parameter
+/
T logisticPDF(T)(const T x, const T location, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "scale must be greater than zero")
{
    return logisticPDF((x - location) / scale) / scale;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    logisticPDF(-2.0).shouldApprox == 0.1049936;
    logisticPDF(-1.0).shouldApprox == 0.1966119;
    logisticPDF(-0.5).shouldApprox == 0.2350037;
    logisticPDF(0.0).shouldApprox == 0.25;
    logisticPDF(0.5).shouldApprox == 0.2350037;
    logisticPDF(1.0).shouldApprox == 0.1966119;
    logisticPDF(2.0).shouldApprox == 0.1049936;

    // Can also provide location/scale parameters
    logisticPDF(-1.0, 2.0, 3.0).shouldApprox == 0.06553731;
    logisticPDF(1.0, 2.0, 3.0).shouldApprox == 0.08106072;
    logisticPDF(4.0, 2.0, 3.0).shouldApprox == 0.07471913;
}

/++
Computes the Logistic cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Logistic_distribution, Logistic probability distribution)
+/
T logisticCDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: exp;

    return 1 / (1 + exp(-x));
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate CDF
    location = location parameter
    scale = scale parameter
+/
T logisticCDF(T)(const T x, const T location, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "scale must be greater than zero")
{
    return logisticCDF((x - location) / scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    logisticCDF(-2.0).shouldApprox == 0.1192029;
    logisticCDF(-1.0).shouldApprox == 0.2689414;
    logisticCDF(-0.5).shouldApprox == 0.3775407;
    logisticCDF(0.0).shouldApprox == 0.5;
    logisticCDF(0.5).shouldApprox == 0.6224593;
    logisticCDF(1.0).shouldApprox == 0.7310586;
    logisticCDF(2.0).shouldApprox == 0.8807971;

    // Can also provide location/scale parameters
    logisticCDF(-1.0, 2.0, 3.0).shouldApprox == 0.2689414;
    logisticCDF(1.0, 2.0, 3.0).shouldApprox == 0.4174298;
    logisticCDF(4.0, 2.0, 3.0).shouldApprox == 0.6607564;
}

/++
Computes the Logistic complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Logistic_distribution, Logistic probability distribution)
+/
T logisticCCDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: exp;

    const T exp_x = exp(-x);
    return exp_x / (1 + exp_x);
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate CCDF
    location = location parameter
    scale = scale parameter
+/
T logisticCCDF(T)(const T x, const T location, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "scale must be greater than zero")
{
    return logisticCCDF((x - location) / scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    logisticCCDF(-2.0).shouldApprox == 0.8807971;
    logisticCCDF(-1.0).shouldApprox == 0.7310586;
    logisticCCDF(-0.5).shouldApprox == 0.6224593;
    logisticCCDF(0.0).shouldApprox == 0.5;
    logisticCCDF(0.5).shouldApprox == 0.3775407;
    logisticCCDF(1.0).shouldApprox == 0.2689414;
    logisticCCDF(2.0).shouldApprox == 0.1192029;

    // Can also provide location/scale parameters
    logisticCCDF(-1.0, 2.0, 3.0).shouldApprox == 0.7310586;
    logisticCCDF(1.0, 2.0, 3.0).shouldApprox == 0.5825702;
    logisticCCDF(4.0, 2.0, 3.0).shouldApprox == 0.3392436;
}

/++
Computes the Logistic inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate InvCDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Logistic_distribution, Logistic probability distribution)
+/
T logisticInvCDF(T)(const T p)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: log;

    return log(p / (1 - p));
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    p = value to evaluate InvCDF
    location = location parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Logistic_distribution, Logistic probability distribution)
+/
T logisticInvCDF(T)(const T p, const T location, const T scale)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in (scale > 0, "scale must be greater than zero")
{
    return location + scale * logisticInvCDF(p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    logisticInvCDF(0.0).shouldApprox == -double.infinity;
    logisticInvCDF(0.25).shouldApprox == -1.098612;
    logisticInvCDF(0.5).shouldApprox == 0.0;
    logisticInvCDF(0.75).shouldApprox == 1.098612;
    logisticInvCDF(1.0).shouldApprox == double.infinity;

    // Can also provide location/scale parameters
    logisticInvCDF(0.2, 2, 3).shouldApprox == -2.158883;
    logisticInvCDF(0.4, 2, 3).shouldApprox == 0.7836047;
    logisticInvCDF(0.6, 2, 3).shouldApprox == 3.216395;
    logisticInvCDF(0.8, 2, 3).shouldApprox == 6.158883;
}

/++
Computes the Logistic log probability density function (LPDF).

Params:
    x = value to evaluate LPDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Logistic_distribution, Logistic probability distribution)
+/
T logisticLPDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: exp, log;

    return -x - 2 * log(1 + exp(-x));
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate LPDF
    location = location parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Logistic_distribution, Logistic probability distribution)
+/
T logisticLPDF(T)(const T x, const T location, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "scale must be greater than zero")
{
    import mir.math.common: log;

    return logisticLPDF((x - location) / scale) - log(scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: log;
    import mir.test: shouldApprox;

    logisticLPDF(-2.0).shouldApprox == log(0.1049936);
    logisticLPDF(-1.0).shouldApprox == log(0.1966119);
    logisticLPDF(-0.5).shouldApprox == log(0.2350037);
    logisticLPDF(0.0).shouldApprox == log(0.25);
    logisticLPDF(0.5).shouldApprox == log(0.2350037);
    logisticLPDF(1.0).shouldApprox == log(0.1966119);
    logisticLPDF(2.0).shouldApprox == log(0.1049936);

    // Can also provide location/scale parameters
    logisticLPDF(-1.0, 2.0, 3.0).shouldApprox == log(0.06553731);
    logisticLPDF(1.0, 2.0, 3.0).shouldApprox == log(0.08106072);
    logisticLPDF(4.0, 2.0, 3.0).shouldApprox == log(0.07471913);
}
