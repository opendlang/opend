/++
This module contains algorithms for the Cornish-Fisher expansion

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.
+/

module mir.stat.distribution.cornish_fisher;

import mir.internal.utility: isFloatingPoint;

/++
Approximates the inverse CDF of a continuous distribution using the Cornish-Fisher expansion.

It is generally recommended to only use the Cornish-Fisher expansion with
distributions that are similar to the normal distribution. Extreme values of
`skewness` or `excessKurtosis` can result in poorer approximations.

Params:
    p = quantile to calculate inverse CDF
    mu = mean
    std = standard deviation
    skewness = skewness
    excessKurtosis = excess kurtosis (kurtosis - 3)

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Cornish%E2%80%93Fisher_expansion, Cornish-Fisher Expansion)
+/
T cornishFisherInvCDF(T)(const T p, const T mu, const T std, const T skewness, const T excessKurtosis)
    if (isFloatingPoint!T)
{
    return mu + std * cornishFisherInvCDF(p, skewness, excessKurtosis);
}

///
version(mir_stat_test)
@safe pure @nogc nothrow
unittest {
    import mir.test: shouldApprox;

    0.99.cornishFisherInvCDF(0, 1, 0.1, 1).shouldApprox == 2.629904;
    0.99.cornishFisherInvCDF(0.1, 0.2, 0.1, 1).shouldApprox == 0.6259808;
}

/++
Ditto, but assumes mu = 0 and std = 1

Params:
    p = quantile to calculate inverse CDF
    skewness = skewness (default = 0)
    excessKurtosis = excess kurtosis (kurtosis - 3) (default = 0)
+/
T cornishFisherInvCDF(T)(const T p, const T skewness = 0, const T excessKurtosis = 0)
    if (isFloatingPoint!T)
{
    import mir.stat.distribution.normal: normalInvCDF;

    T x = normalInvCDF(p);
    return x.cornishFisherInvCDFImpl(skewness, excessKurtosis);
}

///
version(mir_stat_test)
@safe pure @nogc nothrow
unittest {
    import mir.test: shouldApprox;

    0.5.cornishFisherInvCDF.shouldApprox == 0;
    0.5.cornishFisherInvCDF(1).shouldApprox == -0.1666667;
    0.5.cornishFisherInvCDF(-1, 0).shouldApprox == 0.1666667;

    0.9.cornishFisherInvCDF(0.1, 0).shouldApprox == 1.292868;
    0.9.cornishFisherInvCDF(0.1, 1).shouldApprox ==  1.220374;
    0.9.cornishFisherInvCDF(0.1, -1).shouldApprox == 1.365363;

    0.99.cornishFisherInvCDF(0.1, 0).shouldApprox == 2.396116;
    0.99.cornishFisherInvCDF(0.1, 1).shouldApprox == 2.629904;
    0.99.cornishFisherInvCDF(0.1, -1).shouldApprox == 2.162328;

    0.01.cornishFisherInvCDF(0.1, 0).shouldApprox == -2.249053  ;
    0.01.cornishFisherInvCDF(0.1, 1).shouldApprox == -2.482841;
    0.01.cornishFisherInvCDF(0.1, -1).shouldApprox == -2.015265;
}

package(mir.stat)
T cornishFisherInvCDFImpl(T)(const T x, const T skewness, const T excessKurtosis)
    if (isFloatingPoint!T)
{
    import mir.stat.distribution.normal: normalInvCDF;

    T x2 = x * x;
    T x3 = x2 * x;
    return x + (x2 - 1) * skewness / 6 + (x3 - 3 * x) * excessKurtosis / 24 - (2 * x3 - 5 * x) * skewness * skewness / 36;
}

//
version(mir_stat_test)
@safe pure @nogc nothrow
unittest {
    import mir.test: shouldApprox;

    0.0.cornishFisherInvCDFImpl(0, 0).shouldApprox == 0;
    0.0.cornishFisherInvCDFImpl(1, 0).shouldApprox == -0.1666667;
    0.0.cornishFisherInvCDFImpl(-1, 0).shouldApprox == 0.1666667;

    1.281552.cornishFisherInvCDFImpl(0.1, 0).shouldApprox == 1.292868;
    1.281552.cornishFisherInvCDFImpl(0.1, 1).shouldApprox ==  1.220374;
    1.281552.cornishFisherInvCDFImpl(0.1, -1).shouldApprox == 1.365363;

    2.326348.cornishFisherInvCDFImpl(0.1, 0).shouldApprox == 2.396116;
    2.326348.cornishFisherInvCDFImpl(0.1, 1).shouldApprox == 2.629904;
    2.326348.cornishFisherInvCDFImpl(0.1, -1).shouldApprox == 2.162328;

    (-2.326348).cornishFisherInvCDFImpl(0.1, 0).shouldApprox == -2.249053  ;
    (-2.326348).cornishFisherInvCDFImpl(0.1, 1).shouldApprox == -2.482841;
    (-2.326348).cornishFisherInvCDFImpl(0.1, -1).shouldApprox == -2.015265;
}
