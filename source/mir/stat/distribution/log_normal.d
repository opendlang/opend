/++
This module contains algorithms for the Log-normal probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.log_normal;

import mir.internal.utility: isFloatingPoint;


/++
Computes the Log-normal probability distribution function (PDF).

Params:
    x = value to evaluate PDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Log-normal_distribution, Log-normal distribution)
+/
@safe pure nothrow @nogc
T logNormalPDF(T)(const T x)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
{
    import mir.math.common: log;
    import mir.stat.distribution.normal: normalPDF;
    if (x == 0) return 0;
    return x.log.normalPDF / x;
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate PDF
    mean = location parameter
    stdDev = scale parameter
+/
@safe pure nothrow @nogc
T logNormalPDF(T)(const T x, const T mean, const T stdDev)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
    in (stdDev > 0, "stdDev must be greater than zero")
{
    import mir.math.common: log;
    import mir.stat.distribution.normal: normalPDF;
    if (x == 0) return 0;
    return x.log.normalPDF(mean, stdDev) / x;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    logNormalPDF(0.0).shouldApprox == 0;
    logNormalPDF(1.0).shouldApprox == 0.3989423;
    logNormalPDF(2.0).shouldApprox == 0.156874;
    logNormalPDF(3.0).shouldApprox == 0.07272826;

    // Can include location/scale
    logNormalPDF(0.0, 1, 2).shouldApprox == 0;
    logNormalPDF(1.0, 1, 2).shouldApprox == 0.1760327;
    logNormalPDF(2.0, 1, 2).shouldApprox == 0.09856858;
    logNormalPDF(3.0, 1, 2).shouldApprox == 0.06640961;
}

/++
Computes the Log-normal cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Log-normal_distribution, Log-normal distribution)
+/
@safe pure nothrow @nogc
T logNormalCDF(T)(const T x)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
{
    import mir.math.common: log;
    import mir.stat.distribution.normal: normalCDF;
    return x.log.normalCDF;
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate CDF
    mean = location parameter
    stdDev = scale parameter
+/
@safe pure nothrow @nogc
T logNormalCDF(T)(const T x, const T mean, const T stdDev)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
    in (stdDev > 0, "stdDev must be greater than zero")
{
    import mir.math.common: log;
    import mir.stat.distribution.normal: normalCDF;
    return x.log.normalCDF(mean, stdDev);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    logNormalCDF(0.0).shouldApprox == 0;
    logNormalCDF(1.0).shouldApprox == 0.5;
    logNormalCDF(2.0).shouldApprox == 0.7558914;
    logNormalCDF(3.0).shouldApprox == 0.8640314;

    // Can include location/scale
    logNormalCDF(0.0, 1, 2).shouldApprox == 0;
    logNormalCDF(1.0, 1, 2).shouldApprox == 0.3085375;
    logNormalCDF(2.0, 1, 2).shouldApprox == 0.439031;
    logNormalCDF(3.0, 1, 2).shouldApprox == 0.5196623;
}

/++
Computes the Student's t complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Log-normal_distribution, Log-normal distribution)
+/
@safe pure nothrow @nogc
T logNormalCCDF(T)(const T x)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
{
    import mir.math.common: log;
    import mir.stat.distribution.normal: normalCCDF;
    return x.log.normalCCDF;
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate CCDF
    mean = location parameter
    stdDev = scale parameter
+/
@safe pure nothrow @nogc
T logNormalCCDF(T)(const T x, const T mean, const T stdDev)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
    in (stdDev > 0, "stdDev must be greater than zero")
{
    import mir.math.common: log;
    import mir.stat.distribution.normal: normalCCDF;
    return x.log.normalCCDF(mean, stdDev);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    logNormalCCDF(0.0).shouldApprox == 1;
    logNormalCCDF(1.0).shouldApprox == 0.5;
    logNormalCCDF(2.0).shouldApprox == 0.2441086;
    logNormalCCDF(3.0).shouldApprox == 0.1359686;

    // Can include location/scale
    logNormalCCDF(0.0, 1, 2).shouldApprox == 1;
    logNormalCCDF(1.0, 1, 2).shouldApprox == 0.6914625;
    logNormalCCDF(2.0, 1, 2).shouldApprox == 0.560969;
    logNormalCCDF(3.0, 1, 2).shouldApprox == 0.4803377;
}

/++
Computes the Log-normal inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate InvCDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Log-normal_distribution, Log-normal distribution)
+/
@safe pure nothrow @nogc
T logNormalInvCDF(T)(const T p)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    out (r; r >= 0, "return must be greater than or equal to zero")
{
    import mir.math.common: exp;
    import mir.stat.distribution.normal: normalInvCDF;
    return p.normalInvCDF.exp;
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    p = value to evaluate InvCDF
    mean = location parameter
    stdDev = scale parameter
+/
@safe pure nothrow @nogc
T logNormalInvCDF(T)(const T p, const T mean, const T stdDev)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in (stdDev > 0, "stdDev must be greater than zero")
    out (r; r >= 0, "return must be greater than or equal to zero")
{
    import mir.math.common: exp;
    import mir.stat.distribution.normal: normalInvCDF;
    return p.normalInvCDF(mean, stdDev).exp;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    logNormalInvCDF(0.00).shouldApprox == 0;
    logNormalInvCDF(0.25).shouldApprox == 0.5094163;
    logNormalInvCDF(0.50).shouldApprox == 1;
    logNormalInvCDF(0.75).shouldApprox == 1.963031;
    logNormalInvCDF(1.00).shouldApprox == double.infinity;

    // Can include location/scale
    logNormalInvCDF(0.00, 1, 2).shouldApprox == 0;
    logNormalInvCDF(0.25, 1, 2).shouldApprox == 0.7054076;
    logNormalInvCDF(0.50, 1, 2).shouldApprox == 2.718282;
    logNormalInvCDF(0.75, 1, 2).shouldApprox == 10.47487;
    logNormalInvCDF(1.00, 1, 2).shouldApprox == double.infinity;
}

/++
Computes the Log-normal log probability distribution function (LPDF).

Params:
    x = value to evaluate LPDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Log-normal_distribution, Log-normal distribution)
+/
@safe pure nothrow @nogc
T logNormalLPDF(T)(const T x)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
{
    import mir.math.common: log;
    import mir.stat.distribution.normal: normalLPDF;
    if (x == 0) return -T.infinity;
    return x.log.normalLPDF - log(x);
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate LPDF
    mean = location parameter
    stdDev = scale parameter
+/
@safe pure nothrow @nogc
T logNormalLPDF(T)(const T x, const T mean, const T stdDev)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
    in (stdDev > 0, "stdDev must be greater than zero")
{
    import mir.math.common: log;
    import mir.stat.distribution.normal: normalLPDF;
    if (x == 0) return -T.infinity;
    return x.log.normalLPDF(mean, stdDev) - log(x);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: log;
    import mir.test: shouldApprox;

    logNormalLPDF(0.0).shouldApprox == -double.infinity;
    logNormalLPDF(1.0).shouldApprox == log(0.3989423);
    logNormalLPDF(2.0).shouldApprox == log(0.156874);
    logNormalLPDF(3.0).shouldApprox == log(0.07272826);

    // Can include location/scale
    logNormalLPDF(0.0, 1, 2).shouldApprox == -double.infinity;
    logNormalLPDF(1.0, 1, 2).shouldApprox == log(0.1760327);
    logNormalLPDF(2.0, 1, 2).shouldApprox == log(0.09856858);
    logNormalLPDF(3.0, 1, 2).shouldApprox == log(0.06640961);
}
