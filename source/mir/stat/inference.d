/++
This module contains statistical inference algorithms.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: Ilia Ki, John Michael Hall

Copyright: 2022 Mir Stat Authors.
+/
module mir.stat.inference;

public import mir.stat.descriptive.univariate: KurtosisAlgo, Summation;
import mir.internal.utility: isFloatingPoint;

/++
Tests that a sample comes from a normal distribution.

Params:
    kurtosisAlgo = algorithm for calculating skewness and kurtosis (default: KurtosisAlgo.online)
    summation = algorithm for calculating sums (default: Summation.appropriate)
Returns:
    The kurtosis of the input, must be floating point
References:
    D’Agostino, R. B. (1971), “An omnibus test of normality for moderate and large sample size”, Biometrika, 58, 341-348;
    D’Agostino, R. and Pearson, E. S. (1973), “Tests for departure from normality”, Biometrika, 60, 613-622
+/
template dAgostinoPearsonTest(
    KurtosisAlgo kurtosisAlgo = KurtosisAlgo.online, 
    Summation summation = Summation.appropriate)
{
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
        p = null hypothesis probability
    +/
    F dAgostinoPearsonTest(Range, F)(Range r, out F p)
        if(isFloatingPoint!F && isIterable!Range)
    {
        import core.lifetime: move;
        import mir.stat.descriptive.univariate: KurtosisAccumulator, SkewnessAccumulator;
        import mir.stat.distribution.chi2: chi2CCDF;
        import mir.math.sum: ResolveSummationType;

        KurtosisAccumulator!(F, kurtosisAlgo, ResolveSummationType!(summation, Range, F)) kurtosisAccumulator = r;
        auto kurtosisStat = kurtosisTestImpl!F(kurtosisAccumulator);

        static if (kurtosisAlgo == KurtosisAlgo.naive || kurtosisAlgo == KurtosisAlgo.online)
            alias skewnessAccumulator = kurtosisAccumulator;
        else
            SkewnessAccumulator!(F, kurtosisAlgo, ResolveSummationType!(summation, Range, F)) skewnessAccumulator = r.move;

        auto skewnessStat = skewnessTestImpl!F(skewnessAccumulator);
        auto stat = skewnessStat * skewnessStat + kurtosisStat * kurtosisStat;
        p = chi2CCDF(stat, 2);
        return stat;
    }
}

/// ditto
template dAgostinoPearsonTest(string kurtosisAlgo, string summation = "appropriate")
{
    mixin("alias dAgostinoPearsonTest = .dAgostinoPearsonTest!(KurtosisAlgo." ~ kurtosisAlgo ~ ", Summation." ~ summation ~ ");");
}

///
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    double p;
    x.dAgostinoPearsonTest(p).shouldApprox == 4.151936053369771;
    p.shouldApprox == 0.12543494432988342;

    p = p.nan;
    x.dAgostinoPearsonTest!"threePass"(p).shouldApprox == 4.151936053369771;
    p.shouldApprox == 0.12543494432988342;
}

private F skewnessTestImpl(F, Accumulator)(ref const Accumulator acc)
    if (isFloatingPoint!F)
{
    import mir.math.common: sqrt, log;
    auto b2 = acc.skewness!F(true);
    auto n = acc.count;
    assert(n > 7, "skewnessTestImpl: count must be larger than seven");
    auto y = b2 * sqrt((F(n + 1) * (n + 3)) / (6 * (n - 2)));
    auto beta2 = 3 * (F(n) * n + 27 * n - 70) * (n + 1) * (n + 3) / (F(n - 2) * (n + 5) * (n + 7) * (n + 9));
    auto w2 = -1 + sqrt(2 * (beta2 - 1));
    auto delta = 1 / sqrt(0.5f * log(w2));
    auto alpha = sqrt(2 / (w2 - 1));
    auto y_alpha = y / alpha;
    return delta * log(y_alpha + sqrt(y_alpha * y_alpha + 1));
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.stat.descriptive.univariate: SkewnessAccumulator;
    import mir.math.common: approxEqual, pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    SkewnessAccumulator!(double, KurtosisAlgo.naive, Summation.naive) v = x;

    auto zsk = v.skewnessTestImpl!double;
    zsk.shouldApprox == 1.7985465327962042;
    import mir.stat.distribution.normal: normalCCDF;
    auto p = zsk.normalCCDF * 2;
    p.shouldApprox == 0.07209044155600682;
}

private F kurtosisTestImpl(F, Accumulator)(ref const Accumulator acc)
    if (isFloatingPoint!F)
{
    import mir.math.common: copysign, sqrt, fabs, pow;
    auto b2 = acc.kurtosis!F(true, true);
    auto n = acc.count;
    assert(n > 7, "kurtosisTestImpl: count must be larger than seven");
    auto varb2 = F(24) * n * (F(n - 2) * (n - 3)) / (F(n + 1) * (n + 1) * F((n + 3) * (n + 5)));
    auto x = (b2 - 3 * (n - 1) / F(n + 1)) / sqrt(varb2);
    auto beta1sqrt = 6 * (F(n) * n - 5 * n + 2) / (F(n + 7) * (n + 9)) * sqrt((6 * (n + 3) * F(n + 5)) / (n * F(n - 2) * (n - 3)));
    auto a = 6 + 8 / beta1sqrt * (2 / beta1sqrt + sqrt(1 + 4 / (beta1sqrt * beta1sqrt)));
    auto t1 = 1 - 2 / (9 * a);
    auto denom = 1 + x * sqrt(2 / (a - 4));
    auto t2 = pow((1 - 2 / a) / denom.fabs, 1 / F(3)).copysign(denom);
    assert(denom);
    return (t1 - t2) * sqrt(F(4.5) * a);
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.stat.descriptive.univariate: KurtosisAccumulator;
    import mir.math.common: approxEqual, pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    KurtosisAccumulator!(double, KurtosisAlgo.naive, Summation.naive) v = x;

    auto zku = v.kurtosisTestImpl!double;
    zku.shouldApprox == 0.9576880612895426;
    import mir.stat.distribution.normal: normalCCDF;
    auto p = zku.normalCCDF * 2;
    p.shouldApprox == 0.3382200786902009;
}
