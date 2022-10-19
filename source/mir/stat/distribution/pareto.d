/++
This module contains algorithms for the pareto probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.pareto;

import mir.internal.utility: isFloatingPoint;

/++
Computes the pareto probability distribution function (PDF).

Params:
    x = value to evaluate PDF
    xMin = scale parameter
    alpha = shape parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Pareto_distribution, pareto probability distribution)
+/
@safe pure nothrow @nogc
T paretoPDF(T)(const T x, const T xMin, const T alpha)
    if (isFloatingPoint!T)
    in(x >= xMin, "x must be greater than or equal to xMin")
    in(xMin > 0, "xMin must be greater than zero")
    in(alpha > 0, "alpha must be greater than zero")
{
    import mir.math.common: pow;

    return alpha * pow(xMin, alpha) / pow(x, alpha + 1);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    1.0.paretoPDF(1, 3).shouldApprox == 3;
    2.0.paretoPDF(1, 3).shouldApprox == 0.1875;
    3.0.paretoPDF(2, 4).shouldApprox == 0.2633745;
}

/++
Computes the pareto cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF
    xMin = scale parameter
    alpha = shape parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Pareto_distribution, pareto probability distribution)
+/
@safe pure nothrow @nogc
T paretoCDF(T)(const T x, const T xMin, const T alpha)
    if (isFloatingPoint!T)
    in(x >= xMin, "x must be greater than or equal to xMin")
    in(xMin > 0, "xMin must be greater than zero")
    in(alpha > 0, "alpha must be greater than zero")
{
    import mir.math.common: pow;

    return 1 - pow(xMin / x, alpha);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    1.0.paretoCDF(1, 3).shouldApprox == 0;
    2.0.paretoCDF(1, 3).shouldApprox == 0.875;
    3.0.paretoCDF(2, 4).shouldApprox == 0.8024691;
}

/++
Computes the pareto complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    xMin = scale parameter
    alpha = shape parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Pareto_distribution, pareto probability distribution)
+/
@safe pure nothrow @nogc
T paretoCCDF(T)(const T x, const T xMin, const T alpha)
    if (isFloatingPoint!T)
    in(x >= xMin, "x must be greater than or equal to xMin")
    in(xMin > 0, "xMin must be greater than zero")
    in(alpha > 0, "alpha must be greater than zero")
{
    import mir.math.common: pow;

    return pow(xMin / x, alpha);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    1.0.paretoCCDF(1, 3).shouldApprox == 1;
    2.0.paretoCCDF(1, 3).shouldApprox == 0.125;
    3.0.paretoCCDF(2, 4).shouldApprox == 0.1975309;
}

/++
Computes the pareto inverse cumulative distribution function (InvCDF).

Params:
    x = value to evaluate InvCDF
    xMin = scale parameter
    alpha = shape parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Pareto_distribution, pareto probability distribution)
+/
@safe pure nothrow @nogc
T paretoInvCDF(T)(const T p, const T xMin, const T alpha)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in(xMin > 0, "xMin must be greater than zero")
    in(alpha > 0, "alpha must be greater than zero")
{
    import mir.math.common: pow;

    return xMin / pow(1 - p, cast(T) 1 / alpha);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    0.0.paretoInvCDF(1, 3).shouldApprox == 1;
    0.875.paretoInvCDF(1, 3).shouldApprox == 2;
    0.8024691.paretoInvCDF(2, 4).shouldApprox == 3;
}

/++
Computes the pareto log probability distribution function (LPDF).

Params:
    x = value to evaluate LPDF
    xMin = scale parameter
    alpha = shape parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Pareto_distribution, pareto probability distribution)
+/
@safe pure nothrow @nogc
T paretoLPDF(T)(const T x, const T xMin, const T alpha)
    if (isFloatingPoint!T)
    in(x >= xMin, "x must be greater than or equal to xMin")
    in(xMin > 0, "xMin must be greater than zero")
    in(alpha > 0, "alpha must be greater than zero")
{
    import mir.math.common: log;
    import mir.math.internal.xlogy: xlogy;

    return log(alpha) + xlogy(alpha, xMin) - xlogy(alpha + 1, x);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: log;
    import mir.test: shouldApprox;

    1.0.paretoLPDF(1, 3).shouldApprox == log(paretoPDF(1.0, 1, 3));
    2.0.paretoLPDF(1, 3).shouldApprox == log(paretoPDF(2.0, 1, 3));
    3.0.paretoLPDF(2, 4).shouldApprox == log(paretoPDF(3.0, 2, 4));
}
