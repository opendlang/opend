/++
This module contains algorithms for the Laplace Distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2023 Mir Stat Authors.

+/

module mir.stat.distribution.laplace;

import mir.internal.utility: isFloatingPoint;

/++
Computes the Laplace probability density function (PDF).

Params:
    x = value to evaluate PDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Laplace_distribution, Laplace Distribution)
+/
T laplacePDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: exp, fabs;

    return 0.5 * exp(-fabs(x));
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate PDF
    location = location parameter
    scale = scale parameter
+/
T laplacePDF(T)(const T x, const T location, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "scale must be greater than zero")
{
    return laplacePDF((x - location) / scale) / scale;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    laplacePDF(-2.0).shouldApprox == 0.06766764;
    laplacePDF(-1.0).shouldApprox == 0.1839397;
    laplacePDF(-0.5).shouldApprox == 0.3032653;
    laplacePDF(0.0).shouldApprox == 0.5;
    laplacePDF(0.5).shouldApprox == 0.3032653;
    laplacePDF(1.0).shouldApprox == 0.1839397;
    laplacePDF(2.0).shouldApprox == 0.06766764;

    // Can also provide location/scale parameters
    laplacePDF(-1.0, 2.0, 3.0).shouldApprox == 0.06131324;
    laplacePDF(1.0, 2.0, 3.0).shouldApprox == 0.1194219;
    laplacePDF(4.0, 2.0, 3.0).shouldApprox == 0.08556952;
}

/++
Computes the Laplace cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Laplace_distribution, Laplace Distribution)
+/
T laplaceCDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: exp;

    if (x <= 0) {
        return 0.5 * exp(x);
    } else {
        return 1 - 0.5 * exp(-x);
    }
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate CDF
    location = location parameter
    scale = scale parameter
+/
T laplaceCDF(T)(const T x, const T location, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "scale must be greater than zero")
{
    return laplaceCDF((x - location) / scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    laplaceCDF(-2.0).shouldApprox == 0.06766764;
    laplaceCDF(-1.0).shouldApprox == 0.1839397;
    laplaceCDF(-0.5).shouldApprox == 0.3032653;
    laplaceCDF(0.0).shouldApprox == 0.5;
    laplaceCDF(0.5).shouldApprox == 0.6967347;
    laplaceCDF(1.0).shouldApprox == 0.8160603;
    laplaceCDF(2.0).shouldApprox == 0.9323324;

    // Can also provide location/scale parameters
    laplaceCDF(-1.0, 2.0, 3.0).shouldApprox == 0.1839397;
    laplaceCDF(1.0, 2.0, 3.0).shouldApprox == 0.3582657;
    laplaceCDF(4.0, 2.0, 3.0).shouldApprox == 0.7432914;
}

/++
Computes the Laplace complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Laplace_distribution, Laplace Distribution)
+/
T laplaceCCDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: exp;

    if (x <= 0) {
        return 1 - 0.5 * exp(x);
    } else {
        return 0.5 * exp(-x);
    }
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate CCDF
    location = location parameter
    scale = scale parameter
+/
T laplaceCCDF(T)(const T x, const T location, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "scale must be greater than zero")
{
    return laplaceCCDF((x - location) / scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    laplaceCCDF(-2.0).shouldApprox == 0.9323324;
    laplaceCCDF(-1.0).shouldApprox == 0.8160603;
    laplaceCCDF(-0.5).shouldApprox == 0.6967347;
    laplaceCCDF(0.0).shouldApprox == 0.5;
    laplaceCCDF(0.5).shouldApprox == 0.3032653;
    laplaceCCDF(1.0).shouldApprox == 0.1839397;
    laplaceCCDF(2.0).shouldApprox == 0.06766764;

    // Can also provide location/scale parameters
    laplaceCCDF(-1.0, 2.0, 3.0).shouldApprox == 0.8160603;
    laplaceCCDF(1.0, 2.0, 3.0).shouldApprox == 0.6417343;
    laplaceCCDF(4.0, 2.0, 3.0).shouldApprox == 0.2567086;
}

/++
Computes the Laplace inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate InvCDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Laplace_distribution, Laplace Distribution)
+/
T laplaceInvCDF(T)(const T p)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: log;

    if (p <= 0.5) {
        return log(2 * p);
    } else {
        return -log(2 - 2 * p);
    }
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
T laplaceInvCDF(T)(const T p, const T location, const T scale)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in (scale > 0, "scale must be greater than zero")
{
    return location + scale * laplaceInvCDF(p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    laplaceInvCDF(0.0).shouldApprox == -double.infinity;
    laplaceInvCDF(0.25).shouldApprox == -0.6931472;
    laplaceInvCDF(0.5).shouldApprox == 0.0;
    laplaceInvCDF(0.75).shouldApprox == 0.6931472;
    laplaceInvCDF(1.0).shouldApprox == double.infinity;

    // Can also provide location/scale parameters
    laplaceInvCDF(0.2, 2, 3).shouldApprox == -0.7488722;
    laplaceInvCDF(0.4, 2, 3).shouldApprox == 1.330569;
    laplaceInvCDF(0.6, 2, 3).shouldApprox == 2.669431;
    laplaceInvCDF(0.8, 2, 3).shouldApprox == 4.748872;
}

/++
Computes the Laplace log probability density function (LPDF).

Params:
    x = value to evaluate LPDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Laplace_distribution, Laplace Distribution)
+/
T laplaceLPDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: fabs;
    import mir.math.constant: LN2;

    return -T(LN2) - fabs(x);
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate LPDF
    location = location parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Laplace_distribution, Laplace Distribution)
+/
T laplaceLPDF(T)(const T x, const T location, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "shape must be greater than zero")
{
    import mir.math.common: log;

    return laplaceLPDF((x - location) / scale) - log(scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: log;
    import mir.test: shouldApprox;

    laplaceLPDF(-2.0).shouldApprox == log(0.06766764);
    laplaceLPDF(-1.0).shouldApprox == log(0.1839397);
    laplaceLPDF(-0.5).shouldApprox == log(0.3032653);
    laplaceLPDF(0.0).shouldApprox == log(0.5);
    laplaceLPDF(0.5).shouldApprox == log(0.3032653);
    laplaceLPDF(1.0).shouldApprox == log(0.1839397);
    laplaceLPDF(2.0).shouldApprox == log(0.06766764);

    // Can also provide location/scale parameters
    laplaceLPDF(-1.0, 2.0, 3.0).shouldApprox == log(0.06131324);
    laplaceLPDF(1.0, 2.0, 3.0).shouldApprox == log(0.1194219);
    laplaceLPDF(4.0, 2.0, 3.0).shouldApprox == log(0.08556952);
}
