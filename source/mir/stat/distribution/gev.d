/++
This module contains algorithms for the Generalized Extreme Value (GEV) Distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: Ilia Ki, John Michael Hall

Copyright: 2022-3 Mir Stat Authors.

+/

module mir.stat.distribution.gev;

import mir.internal.utility: isFloatingPoint;

import mir.math.common: fabs, exp, pow, log;

/++
Computes the generalized extreme value (GEV) probability density function (PDF).

Params:
    x = value to evaluate
    mu = location
    sigma = scale
    xi = shape

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Generalized_extreme_value_distribution, Generalized Extreme Value (GEV) Distribution)
+/
T gevPDF(T)(const T x, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
    in (xi >= 0 || x <= mu - sigma / xi, "if xi is less than zero, x must be less than or equal to mu - sigma / xi")
    in (xi <= 0 || x >= mu - sigma / xi, "if xi is greater than zero, xi must be greater than or equal to mu - sigma / xi")
{
    auto s = (x - mu) / sigma;
    if (xi.fabs <= T.min_normal)
    {
        auto t = exp(-s);
        return t * exp(-t);
    }
    auto v = 1 + xi * s;
    if (v <= 0)
        return 0;
    auto a = pow(v, -1 / xi);
    return a * exp(-a) / (v * sigma);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    gevPDF(-3, 2, 3, -0.5).shouldApprox == 0.02120353011709564;
    gevPDF(-1, 2, 3, +0.5).shouldApprox == 0.04884170370329114;
    gevPDF(-1, 2, 3, 0.0).shouldApprox == 0.1793740787340172;
}

// Checking v <= 0 branch
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: should;
    gevPDF(-1.0, 0, 1, 1).should == 0;
}

/++
Computes the generalized extreme value (GEV) cumulatve distribution function (CDF).

Params:
    x = value to evaluate
    mu = location
    sigma = scale
    xi = shape

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Generalized_extreme_value_distribution, Generalized Extreme Value (GEV) Distribution)
+/
T gevCDF(T)(const T x, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
    in (xi >= 0 || x <= mu - sigma / xi, "if xi is less than zero, x must be less than or equal to mu - sigma / xi")
    in (xi <= 0 || x >= mu - sigma / xi, "if xi is greater than zero, xi must be greater than or equal to mu - sigma / xi")
{
    auto s = (x - mu) / sigma;
    if (xi.fabs <= T.min_normal)
        return exp(-exp(-s));
    auto v = 1 + xi * s;
    if (v <= 0)
        return xi > 0 ? 0 : 1;
    auto a = pow(v, -1 / xi);
    return exp(-a);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    gevCDF(-3, 2, 3, -0.5).shouldApprox == 0.034696685646156494;
    gevCDF(-1, 2, 3, +0.5).shouldApprox == 0.01831563888873418;
    gevCDF(-1, 2, 3, 0.0).shouldApprox == 0.06598803584531254;
}

// Checking v <= 0 branch
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: should;
    gevCDF(-1.0, 0, 1, 1).should == 0;
    gevCDF(1.0, 0, 1, -1).should == 1;
}

/++
Computes the generalized extreme value (GEV) complementary cumulatve distribution function (CCDF).

Params:
    x = value to evaluate
    mu = location
    sigma = scale
    xi = shape

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Generalized_extreme_value_distribution, Generalized Extreme Value (GEV) Distribution)
+/
T gevCCDF(T)(const T x, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
    in (xi >= 0 || x <= mu - sigma / xi, "if xi is less than zero, x must be less than or equal to mu - sigma / xi")
    in (xi <= 0 || x >= mu - sigma / xi, "if xi is greater than zero, xi must be greater than or equal to mu - sigma / xi")
{
    return 1 - gevCDF(x, mu, sigma, xi);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    gevCCDF(-3, 2, 3, -0.5).shouldApprox == 0.965303314353844;
    gevCCDF(-1, 2, 3, +0.5).shouldApprox == 0.981684361111266;
    gevCCDF(-1, 2, 3, 0.0).shouldApprox == 0.934011964154687;
}

// Checking v <= 0 branch
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: should;
    gevCCDF(-1.0, 0, 1, 1).should == 1;
    gevCCDF(1.0, 0, 1, -1).should == 0;
}

/++
Computes the generalized extreme value (GEV) inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate
    mu = location
    sigma = scale
    xi = shape

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Generalized_extreme_value_distribution, Generalized Extreme Value (GEV) Distribution)
+/
T gevInvCDF(T)(const T p, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    auto logp = log(p);
    if (xi.fabs <= T.min_normal)
        return mu - sigma * log(-logp);
    return mu + (pow(-logp, -xi) - 1) * sigma / xi;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    gevInvCDF(0.034696685646156494, 2, 3, -0.5).shouldApprox == -3;
    gevInvCDF(0.01831563888873418, 2, 3, +0.5).shouldApprox == -1;
    gevInvCDF(0.06598803584531254, 2, 3, 0.0).shouldApprox == -1;
}

/++
Computes the generalized extreme value (GEV) log probability density function (LPDF).

Params:
    x = value to evaluate
    mu = location
    sigma = scale
    xi = shape

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Generalized_extreme_value_distribution, Generalized Extreme Value (GEV) Distribution)
+/
T gevLPDF(T)(const T x, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
    in (xi >= 0 || x <= mu - sigma / xi, "if xi is less than zero, x must be less than or equal to mu - sigma / xi")
    in (xi <= 0 || x >= mu - sigma / xi, "if xi is greater than zero, xi must be greater than or equal to mu - sigma / xi")
{
    import mir.math.common: log;

    auto s = (x - mu) / sigma;
    if (xi.fabs <= T.min_normal)
    {
        auto t = exp(-s);
        return log(t) - t;
    }
    auto v = 1 + xi * s;
    if (v <= 0)
        return -double.infinity;
    auto a = pow(v, -1 / xi);
    return log(a) - a - log(v * sigma);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    gevLPDF(-3, 2, 3, -0.5).shouldApprox == -3.85358759620891;
    gevLPDF(-1, 2, 3, +0.5).shouldApprox == -3.01917074698827;
    gevLPDF(-1, 2, 3, 0.0).shouldApprox == -1.71828182845905;
}

// Checking v <= 0 branch
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;
    gevLPDF(-1.0, 0, 1, 1).shouldApprox == -double.infinity;
}
