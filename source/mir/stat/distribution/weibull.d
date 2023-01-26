/++
This module contains algorithms for the Weibull Distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2023 Mir Stat Authors.

+/

module mir.stat.distribution.weibull;

import mir.internal.utility: isFloatingPoint;

/++
Computes the Weibull probability density function (PDF).

Params:
    x = value to evaluate PDF
    shape = shape parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Weibull_distribution, Weibull Distribution)
+/
T weibullPDF(T)(const T x, const T shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import mir.math.common: exp, pow;

    const T x_scale = x / scale;
    return (shape / scale) * pow(x_scale, shape - 1) * exp(-pow(x_scale, shape));
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    0.0.weibullPDF(3.0).shouldApprox == 0;
    0.5.weibullPDF(3.0).shouldApprox == 0.6618727;
    1.0.weibullPDF(3.0).shouldApprox == 1.103638;
    1.5.weibullPDF(3.0).shouldApprox == 0.2309723;

    // Can also provide scale parameter
    0.5.weibullPDF(2.0, 3.0).shouldApprox == 0.1080672;
    1.0.weibullPDF(2.0, 3.0).shouldApprox == 0.1988532;
    1.5.weibullPDF(2.0, 3.0).shouldApprox == 0.2596003;
}

//
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    0.0.weibullPDF(1.0, 3.0).shouldApprox == 0.3333333;
}

/++
Computes the Weibull cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF
    shape = shape parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Weibull_distribution, Weibull Distribution)
+/
T weibullCDF(T)(const T x, const T shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import mir.math.common: exp, pow;

    return 1 - exp(-pow(x / scale, shape));
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    0.0.weibullCDF(3.0).shouldApprox == 0;
    0.5.weibullCDF(3.0).shouldApprox == 0.1175031;
    1.0.weibullCDF(3.0).shouldApprox == 0.6321206;
    1.5.weibullCDF(3.0).shouldApprox == 0.9657819;

    // Can also provide scale parameter
    0.5.weibullCDF(2.0, 3.0).shouldApprox == 0.02739552;
    1.0.weibullCDF(2.0, 3.0).shouldApprox == 0.1051607;
    1.5.weibullCDF(2.0, 3.0).shouldApprox == 0.2211992;
}

/++
Computes the Weibull complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    shape = shape parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Weibull_distribution, Weibull Distribution)
+/
T weibullCCDF(T)(const T x, const T shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import mir.math.common: exp, pow;

    return exp(-pow(x / scale, shape));
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    0.0.weibullCCDF(3.0).shouldApprox == 1;
    0.5.weibullCCDF(3.0).shouldApprox == 0.8824969;
    1.0.weibullCCDF(3.0).shouldApprox == 0.3678794;
    1.5.weibullCCDF(3.0).shouldApprox == 0.03421812;

    // Can also provide scale parameter
    0.5.weibullCCDF(2.0, 3.0).shouldApprox == 0.9726045;
    1.0.weibullCCDF(2.0, 3.0).shouldApprox == 0.8948393;
    1.5.weibullCCDF(2.0, 3.0).shouldApprox == 0.7788008;
}

/++
Computes the Weibull inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate InvCDF
    shape = shape parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Weibull_distribution, Weibull Distribution)
+/
T weibullInvCDF(T)(const T p, const T shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import mir.math.common: log, pow;

    return scale * pow(-log(1 - p), T(1) / shape);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    weibullInvCDF(0.0, 3).shouldApprox == 0.0;
    weibullInvCDF(0.25, 3).shouldApprox == 0.6601424;
    weibullInvCDF(0.5, 3).shouldApprox == 0.884997;
    weibullInvCDF(0.75, 3).shouldApprox == 1.115026;
    weibullInvCDF(1.0, 3).shouldApprox == double.infinity;

    // Can also provide scale parameter
    weibullInvCDF(0.2, 2, 3).shouldApprox == 1.417142;
    weibullInvCDF(0.4, 2, 3).shouldApprox == 2.144162;
    weibullInvCDF(0.6, 2, 3).shouldApprox == 2.871692;
    weibullInvCDF(0.8, 2, 3).shouldApprox == 3.805909;
}


/++
Computes the Weibull log probability density function (LPDF).

Params:
    x = value to evaluate LPDF
    shape = shape parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Weibull_distribution, Weibull Distribution)
+/
T weibullLPDF(T)(const T x, const T shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to zero")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import mir.math.common: log, pow;
    import mir.math.internal.xlogy: xlogy;

    const T x_scale = x / scale;
    return log(shape / scale) + xlogy(shape - 1, x_scale) - pow(x_scale, shape);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: log;
    import mir.test: shouldApprox;

    0.0.weibullLPDF(3.0).shouldApprox == log(0.0);
    0.5.weibullLPDF(3.0).shouldApprox == log(0.6618727);
    1.0.weibullLPDF(3.0).shouldApprox == log(1.103638);
    1.5.weibullLPDF(3.0).shouldApprox == log(0.2309723);

    // Can also provide scale parameter
    0.5.weibullLPDF(2.0, 3.0).shouldApprox == log(0.1080672);
    1.0.weibullLPDF(2.0, 3.0).shouldApprox == log(0.1988532);
    1.5.weibullLPDF(2.0, 3.0).shouldApprox == log(0.2596003);
}
