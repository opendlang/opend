/++
This module contains algorithms for the generalized pareto probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.generalized_pareto;

import mir.internal.utility: isFloatingPoint;

/++
Computes the generalized pareto probability distribution function (PDF).

Params:
    x = value to evaluate PDF
    mu = location parameter
    sigma = scale parameter
    xi = shape parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Generalized_Pareto_distribution, generalized pareto probability distribution)
+/
@safe pure nothrow @nogc
T generalizedParetoPDF(T)(const T x, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
    in(sigma > 0, "sigma must be greater than zero")
    in(x >= mu, "x must be greater than or equal to mu")
    in(xi >= 0 || (xi < 0 && x <= (mu - sigma / xi)), "if xi is less than zero, x must be less than mu - sigma / xi")
{
    import mir.math.common: exp, pow;

    const T z = (x - mu) / sigma;
    if (xi != 0) {
        return (cast(T) 1 / sigma) * pow(1 + xi * z, -(cast(T) 1 / xi + 1));
    } else {
        return exp(-z);
    }
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    1.0.generalizedParetoPDF(1, 1, 0.5).shouldApprox == 1;
    2.0.generalizedParetoPDF(1, 1, 0.5).shouldApprox == 0.2962963;
    3.0.generalizedParetoPDF(2, 3, 0.25).shouldApprox == 0.2233923;
    5.0.generalizedParetoPDF(2, 3, 0).shouldApprox == 0.3678794;
}

/++
Computes the generalized pareto cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF
    mu = location parameter
    sigma = scale parameter
    xi = shape parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Generalized_Pareto_distribution, generalized pareto probability distribution)
+/
@safe pure nothrow @nogc
T generalizedParetoCDF(T)(const T x, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
    in(sigma > 0, "sigma must be greater than zero")
    in(x >= mu, "x must be greater than or equal to mu")
    in(xi >= 0 || (xi < 0 && x <= (mu - sigma / xi)), "if xi is less than zero, x must be less than mu - sigma / xi")
{
    import mir.math.common: exp, pow;

    const T z = (x - mu) / sigma;
    if (xi != 0) {
        return 1 - pow(1 + xi * z, -(cast(T) 1) / xi);
    } else {
        return 1 - exp(-z);
    }
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    1.0.generalizedParetoCDF(1, 1, 0.5).shouldApprox == 0;
    2.0.generalizedParetoCDF(1, 1, 0.5).shouldApprox == 0.5555556;
    3.0.generalizedParetoCDF(2, 3, 0.25).shouldApprox == 0.273975;
    5.0.generalizedParetoCDF(2, 3, 0).shouldApprox == 0.6321206;
}

/++
Computes the generalized pareto complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    mu = location parameter
    sigma = scale parameter
    xi = shape parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Generalized_Pareto_distribution, generalized pareto probability distribution)
+/
@safe pure nothrow @nogc
T generalizedParetoCCDF(T)(const T x, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
    in(sigma > 0, "sigma must be greater than zero")
    in(x >= mu, "x must be greater than or equal to mu")
    in(xi >= 0 || (xi < 0 && x <= (mu - sigma / xi)), "if xi is less than zero, x must be less than mu - sigma / xi")
{
    import mir.math.common: exp, pow;

    const T z = (x - mu) / sigma;
    if (xi != 0) {
        return pow(1 + xi * z, -(cast(T) 1) / xi);
    } else {
        return exp(-z);
    }
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    1.0.generalizedParetoCCDF(1, 1, 0.5).shouldApprox == 1;
    2.0.generalizedParetoCCDF(1, 1, 0.5).shouldApprox == 0.4444444;
    3.0.generalizedParetoCCDF(2, 3, 0.25).shouldApprox == 0.726025;
    5.0.generalizedParetoCCDF(2, 3, 0).shouldApprox == 0.3678794;
}

/++
Computes the generalized pareto inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate InvCDF
    mu = location parameter
    sigma = scale parameter
    xi = shape parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Generalized_Pareto_distribution, generalized pareto probability distribution)
+/
@safe pure nothrow @nogc
T generalizedParetoInvCDF(T)(const T p, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in(sigma > 0, "sigma must be greater than zero")
{
    import mir.math.common: pow;
    import std.math.exponential: log1p;

    T output;
    if (xi != 0) {
        output = (cast(T) 1 / xi) * (pow(1 - p, -xi) - 1);
    } else {
        output = -log1p(-p);
    }
    return mu + sigma * output;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    0.0.generalizedParetoInvCDF(1, 1, 0.5).shouldApprox == 1;
    0.5555556.generalizedParetoInvCDF(1, 1, 0.5).shouldApprox == 2;
    0.273975.generalizedParetoInvCDF(2, 3, 0.25).shouldApprox == 3;
    0.6321206.generalizedParetoInvCDF(2, 3, 0).shouldApprox == 5;    
}

/++
Computes the generalized pareto log probability distribution function (LPDF).

Params:
    x = value to evaluate LPDF
    mu = location parameter
    sigma = scale parameter
    xi = shape parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Generalized_Pareto_distribution, generalized pareto probability distribution)
+/
@safe pure nothrow @nogc
T generalizedParetoLPDF(T)(const T x, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
    in(sigma > 0, "sigma must be greater than zero")
    in(x >= mu, "x must be greater than or equal to mu")
    in(xi >= 0 || (xi < 0 && x <= (mu - sigma / xi)), "if xi is less than zero, x must be less than mu - sigma / xi")
{
    import mir.math.common: log;
    import mir.math.internal.xlogy: xlogy;

    const T z = (x - mu) / sigma;
    if (xi != 0) {
        return -log(sigma) + xlogy(-(cast(T) 1 / xi + 1), 1 + xi * z);
    } else {
        return -z;
    }
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: log;
    import mir.test: shouldApprox;

    1.0.generalizedParetoLPDF(1, 1, 0.5).shouldApprox == log(generalizedParetoPDF(1.0, 1, 1, 0.5));
    2.0.generalizedParetoLPDF(1, 1, 0.5).shouldApprox == log(generalizedParetoPDF(2.0, 1, 1, 0.5));
    3.0.generalizedParetoLPDF(2, 3, 0.25).shouldApprox == log(generalizedParetoPDF(3.0, 2, 3, 0.25));
    5.0.generalizedParetoLPDF(2, 3, 0).shouldApprox == log(generalizedParetoPDF(5.0, 2, 3, 0));
}
