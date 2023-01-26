/++
This module contains algorithms for the Rayleigh Distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2023 Mir Stat Authors.

+/

module mir.stat.distribution.rayleigh;

import mir.internal.utility: isFloatingPoint;

/++
Computes the Rayleigh probability density function (PDF).

Params:
    x = value to evaluate PDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Rayleigh_distribution, Rayleigh Distribution)
+/
T rayleighPDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: exp;

    return x * exp(-0.5 * x * x);
}

/++
Ditto, with scale parameter.

Params:
    x = value to evaluate PDF
    scale = scale parameter
+/
T rayleighPDF(T)(const T x, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "scale must be greater than zero")
{
    import mir.math.common: exp;

    const T scale2 = scale * scale;
    return x / scale2 * exp(-0.5 * x * x / scale2);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    0.0.rayleighPDF.shouldApprox == 0.0;
    0.5.rayleighPDF.shouldApprox == 0.4412485;
    1.0.rayleighPDF.shouldApprox == 0.6065307;
    2.0.rayleighPDF.shouldApprox == 0.2706706;

    // Can also provide scale parameter
    0.5.rayleighPDF(2.0).shouldApprox == 0.1211541;
    1.0.rayleighPDF(2.0).shouldApprox == 0.2206242;
    4.0.rayleighPDF(2.0).shouldApprox == 0.1353353;
}

/++
Computes the Rayleigh cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Rayleigh_distribution, Rayleigh Distribution)
+/
T rayleighCDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: exp;

    return 1 - exp(-0.5 * x * x);
}

/++
Ditto, with scale parameter.

Params:
    x = value to evaluate CDF
    scale = scale parameter
+/
T rayleighCDF(T)(const T x, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "scale must be greater than zero")
{
    return rayleighCDF(x / scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    0.0.rayleighCDF.shouldApprox == 0.0;
    0.5.rayleighCDF.shouldApprox == 0.1175031;
    1.0.rayleighCDF.shouldApprox == 0.3934693;
    2.0.rayleighCDF.shouldApprox == 0.8646647;

    // Can also provide scale parameter
    0.5.rayleighCDF(2.0).shouldApprox == 0.03076677;
    1.0.rayleighCDF(2.0).shouldApprox == 0.1175031;
    4.0.rayleighCDF(2.0).shouldApprox == 0.8646647;
}

/++
Computes the Rayleigh complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Rayleigh_distribution, Rayleigh Distribution)
+/
T rayleighCCDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: exp;

    return exp(-0.5 * x * x);
}

/++
Ditto, with scale parameter.

Params:
    x = value to evaluate CCDF
    scale = scale parameter
+/
T rayleighCCDF(T)(const T x, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "scale must be greater than zero")
{
    return rayleighCCDF(x / scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    0.0.rayleighCCDF.shouldApprox == 1.0;
    0.5.rayleighCCDF.shouldApprox == 0.8824969;
    1.0.rayleighCCDF.shouldApprox == 0.6065307;
    2.0.rayleighCCDF.shouldApprox == 0.1353353;

    // Can also provide scale parameter
    0.5.rayleighCCDF(2.0).shouldApprox == 0.9692332;
    1.0.rayleighCCDF(2.0).shouldApprox == 0.8824969;
    4.0.rayleighCCDF(2.0).shouldApprox == 0.1353353;
}

/++
Computes the Rayleigh inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate InvCDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Rayleigh_distribution, Rayleigh Distribution)
+/
T rayleighInvCDF(T)(const T p)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: log, sqrt;
   
    return sqrt(-2 * log(1 - p));
}

/++
Ditto, with scale parameter.

Params:
    p = value to evaluate InvCDF
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Logistic_distribution, Logistic probability distribution)
+/
T rayleighInvCDF(T)(const T p, const T scale)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in (scale > 0, "scale must be greater than zero")
{
    return scale * rayleighInvCDF(p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    rayleighInvCDF(0.0).shouldApprox == 0.0;
    rayleighInvCDF(0.25).shouldApprox == 0.7585276;
    rayleighInvCDF(0.5).shouldApprox == 1.17741;
    rayleighInvCDF(0.75).shouldApprox == 1.665109;
    rayleighInvCDF(1.0).shouldApprox == double.infinity;

    // Can also provide scale parameter
    rayleighInvCDF(0.2, 2).shouldApprox == 1.336094;
    rayleighInvCDF(0.4, 2).shouldApprox == 2.021535;
    rayleighInvCDF(0.6, 2).shouldApprox == 2.707457;
    rayleighInvCDF(0.8, 2).shouldApprox == 3.588245;
}

/++
Computes the Rayleigh log probability density function (LPDF).

Params:
    x = value to evaluate LPDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Rayleigh_distribution, Rayleigh Distribution)
+/
T rayleighLPDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: log;

    return log(x) - 0.5 * x * x;
}

/++
Ditto, with scale parameter.

Params:
    x = value to evaluate LPDF
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Rayleigh_distribution, Rayleigh Distribution)
+/
T rayleighLPDF(T)(const T x, const T scale)
    if (isFloatingPoint!T)
    in (scale > 0, "shape must be greater than zero")
{
    import mir.math.common: log;

    return log(x) - 2 * log(scale) - 0.5 * x * x / (scale * scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: log;
    import mir.test: shouldApprox;

    0.0.rayleighLPDF.shouldApprox == -double.infinity;
    0.5.rayleighLPDF.shouldApprox == log(0.4412485);
    1.0.rayleighLPDF.shouldApprox == log(0.6065307);
    2.0.rayleighLPDF.shouldApprox == log(0.2706706);

    // Can also provide scale parameter
    0.5.rayleighLPDF(2.0).shouldApprox == log(0.1211541);
    1.0.rayleighLPDF(2.0).shouldApprox == log(0.2206242);
    4.0.rayleighLPDF(2.0).shouldApprox == log(0.1353353);
}
