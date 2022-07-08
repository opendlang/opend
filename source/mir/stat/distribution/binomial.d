/++
This module contains algorithms for the binomial probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.binomial;

import mir.bignum.fp: Fp;
import mir.internal.utility: isFloatingPoint;
import mir.stat.distribution.poisson: PoissonAlgo;

/++
Algorithms used to calculate binomial dstribution.

`BinomialAlgo.direct` can be more time-consuming for large values of the number
of events (`k`) or the number of trials (`n`). Additional algorithms are
provided to the user to choose the trade-off between running time and accuracy.

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Binomial_distribution, binomial probability distribution)
+/
enum BinomialAlgo {
    /++
    Direct
    +/
    direct,
    /++
    Approximates poisson distribution with normal distribution. Generally a better approximation when
    `n > 20` and `p` is far from 0 or 1, but a variety of rules of thumb can help determine when it is 
    appropriate to use.
    +/
    approxNormal,
    /++
    Approximates poisson distribution with normal distribution (including continuity correction). More 
    accurate than `BinomialAlgo.approxNormal`.
    +/
    approxNormalContinuityCorrection,
    /++
    Approximates poisson distribution with poisson distribution (also requires specifying poissonAlgo). 
    Generally a better approximation when `n >= 20` and `p <= 0.05` or when `n >= 100` and `np <= 10`.
    +/
    approxPoisson
}

private
@safe pure nothrow @nogc
T binomialPMFImpl(T, BinomialAlgo binomialAlgo)(const size_t k, const size_t n, const T p)
    if (isFloatingPoint!T && binomialAlgo == BinomialAlgo.direct)
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: pow;
    import mir.combinatorics: binomial;

    return binomial(n, k) * pow(p, k) * pow(1 - p, n - k);
}

private
@safe pure nothrow @nogc
T binomialPMFImpl(T, BinomialAlgo binomialAlgo)(const size_t k, const size_t n, const T p)
    if (isFloatingPoint!T && binomialAlgo == BinomialAlgo.approxNormal)
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: sqrt;
    import mir.stat.distribution.normal: normalPDF;

    return normalPDF(k, n * p, sqrt(n * p * (1 - p)));
}

private
@safe pure nothrow @nogc
T binomialPMFImpl(T, BinomialAlgo binomialAlgo)(const size_t k, const size_t n, const T p)
    if (isFloatingPoint!T && binomialAlgo == BinomialAlgo.approxNormalContinuityCorrection)
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: sqrt;
    import mir.stat.distribution.normal: normalCDF;

    return normalCDF(cast(T) k + 0.5, n * p, sqrt(n * p * (1 - p))) - normalCDF(cast(T) k - 0.5, n * p, sqrt(n * p * (1 - p)));
}

private
@safe pure nothrow @nogc
T binomialPMFImpl(T, BinomialAlgo binomialAlgo, PoissonAlgo poissonAlgo)(const size_t k, const size_t n, const T p)
    if (isFloatingPoint!T && binomialAlgo == BinomialAlgo.approxPoisson)
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.stat.distribution.poisson: poissonPMF;

    return poissonPMF!poissonAlgo(k, n * p);
}

/++
Computes the binomial probability mass function (PMF).

Additional algorithms may be provided for calculating PMF that allow trading off
time and accuracy. If `approxPoisson` is provided, the default is `PoissonAlgo.gamma`

Params:
    binomialAlgo = algorithm for calculating PMF (default: BinomialAlgo.direct)
    poissonAlgo = algorithm for poisson approximation (default: PoissonAlgo.gamma)

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Binomial_distribution, binomial probability distribution)
+/
@safe pure nothrow @nogc
template binomialPMF(BinomialAlgo binomialAlgo = BinomialAlgo.direct,
                     PoissonAlgo poissonAlgo = PoissonAlgo.gamma)
{
    /++
    Params:
    k = value to evaluate PMF (e.g. number of "heads")
    n = number of trials
    p = `true` probability
    +/
    T binomialPMF(T)(const size_t k, const size_t n, const T p)
        if (isFloatingPoint!T)
        in (k <= n, "k must be less than or equal to n")
        in (p >= 0, "p must be greater than or equal to 0")
        in (p <= 1, "p must be less than or equal to 1")
    {
        static if (binomialAlgo != BinomialAlgo.approxPoisson)
            return binomialPMFImpl!(T, binomialAlgo)(k, n, p);
        else
            return binomialPMFImpl!(T, binomialAlgo, poissonAlgo)(k, n, p);
    }
}

/// ditto
@safe pure nothrow @nogc
template binomialPMF(string binomialAlgo, string poissonAlgo = "gamma")
{
    mixin("alias binomialPMF = .binomialPMF!(BinomialAlgo." ~ binomialAlgo ~ ", PoissonAlgo." ~ poissonAlgo ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, pow;

    assert(4.binomialPMF(6, 2.0 / 3).approxEqual(15.0 * pow(2.0 / 3, 4) * pow(1.0 / 3, 2)));
    // For large values of `n` with `p` not too extreme, can approximate with normal distribution
    assert(550_000.binomialPMF!"approxNormal"(1_000_000, 0.55).approxEqual(0.0008019042));
    // Or closer with continuity correction
    assert(550_000.binomialPMF!"approxNormalContinuityCorrection"(1_000_000, 0.55).approxEqual(0.000801904));
    // Poisson approximation is better when `p` is low
    assert(10_000.binomialPMF!"approxPoisson"(1_000_000, 0.01).approxEqual(0.00398939));
}

// test multiple
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, pow;
    import mir.combinatorics: binomial;

    for (size_t i; i <= 5; i++) {
        assert(i.binomialPMF(5, 0.25).approxEqual(binomial(5, i) * pow(0.25, i) * pow(0.75, 5 - i)));
        assert(i.binomialPMF(5, 0.50).approxEqual(binomial(5, i) * pow(0.50, 5)));
        assert(i.binomialPMF(5, 0.75).approxEqual(binomial(5, i) * pow(0.75, i) * pow(0.25, 5 - i)));
    }
}

// test BinomialAlgo.approxNormal / approxNormalContinuityCorrection / approxPoisson
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, sqrt;
    import mir.stat.distribution.normal: normalCDF, normalPDF;
    import mir.stat.distribution.poisson: poissonPMF;
    
    for (size_t i; i < 5; i++) {
        assert(i.binomialPMF!"approxNormal"(5, 0.75).approxEqual(normalPDF(i, 5.0 * 0.75, sqrt(5.0 * 0.75 * 0.25))));
        assert(i.binomialPMF!"approxNormalContinuityCorrection"(5, 0.75).approxEqual(normalCDF(i + 0.5, 5.0 * 0.75, sqrt(5.0 * 0.75 * 0.25)) - normalCDF(i - 0.5, 5.0 * 0.75, sqrt(5.0 * 0.75 * 0.25))));
        assert(i.binomialPMF!"approxPoisson"(5, 0.75).approxEqual(poissonPMF!"gamma"(i, 5 * 0.75)));
        assert(i.binomialPMF!("approxPoisson", "direct")(5, 0.75).approxEqual(poissonPMF(i, 5 * 0.75)));
    }
}

/++
Computes the  binomial probability mass function (PMF) directly with extended 
floating point types (e.g. `Fp!128`), which provides additional accuracy for
large values of `k`, `n`, or `p`. 

Params:
    k = value to evaluate PMF (e.g. number of "heads")
    n = number of trials
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Binomial_distribution, binomial probability distribution)
+/
@safe pure nothrow @nogc
T fp_binomialPMF(T)(const size_t k, const size_t n, const T p)
    if (is(T == Fp!size, size_t size))
    in (k <= n, "k must be less than or equal to n")
    in (cast(double) p >= 0, "p must be greater than or equal to 0")
    in (cast(double) p <= 1, "p must be less than or equal to 1")
{
    import mir.math.internal.fp_powi: fp_powi;
    import mir.math.numeric: binomialCoefficient;

    return binomialCoefficient(n, cast(const uint) k) * fp_powi(p, k) * fp_powi(T(1 - cast(double) p), n - k);
}

/// fp_binomialPMF provides accurate values for large values of `n`
version(mir_stat_test_fp)
@safe pure nothrow @nogc
unittest {
    import mir.bignum.fp: Fp, fp_log;
    import mir.conv: to;
    import mir.math.common: approxEqual, exp, log;

    enum size_t val = 1_000_000;

    assert(0.fp_binomialPMF(val + 5, Fp!128(0.75)).fp_log!double.approxEqual(binomialLPMF(0, val + 5, 0.75)));
    assert(1.fp_binomialPMF(val + 5, Fp!128(0.75)).fp_log!double.approxEqual(binomialLPMF(1, val + 5, 0.75)));
    assert(2.fp_binomialPMF(val + 5, Fp!128(0.75)).fp_log!double.approxEqual(binomialLPMF(2, val + 5, 0.75)));
    assert(5.fp_binomialPMF(val + 5, Fp!128(0.75)).fp_log!double.approxEqual(binomialLPMF(5, val + 5, 0.75)));
    assert((val / 2).fp_binomialPMF(val + 5, Fp!128(0.75)).fp_log!double.approxEqual(binomialLPMF(val / 2, val + 5, 0.75)));
    assert((val - 5).fp_binomialPMF(val + 5, Fp!128(0.75)).fp_log!double.approxEqual(binomialLPMF(val - 5, val + 5, 0.75)));
    assert((val - 2).fp_binomialPMF(val + 5, Fp!128(0.75)).fp_log!double.approxEqual(binomialLPMF(val - 2, val + 5, 0.75)));
    assert((val - 1).fp_binomialPMF(val + 5, Fp!128(0.75)).fp_log!double.approxEqual(binomialLPMF(val - 1, val + 5, 0.75)));
    assert((val - 0).fp_binomialPMF(val + 5, Fp!128(0.75)).fp_log!double.approxEqual(binomialLPMF(val, val + 5, 0.75)));
}

// using Fp!128, p = 0.5
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.conv: to;
    import mir.math.common: approxEqual;

    assert(0.fp_binomialPMF(5, Fp!128(0.5)).to!double.approxEqual(binomialPMF(0, 5, 0.5)));
    assert(1.fp_binomialPMF(5, Fp!128(0.5)).to!double.approxEqual(binomialPMF(1, 5, 0.5)));
    assert(2.fp_binomialPMF(5, Fp!128(0.5)).to!double.approxEqual(binomialPMF(2, 5, 0.5)));
    assert(3.fp_binomialPMF(5, Fp!128(0.5)).to!double.approxEqual(binomialPMF(3, 5, 0.5)));
    assert(4.fp_binomialPMF(5, Fp!128(0.5)).to!double.approxEqual(binomialPMF(4, 5, 0.5)));
    assert(5.fp_binomialPMF(5, Fp!128(0.5)).to!double.approxEqual(binomialPMF(5, 5, 0.5)));
}

// using Fp!128, p = 0.75
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.conv: to;
    import mir.math.common: approxEqual;

    assert(0.fp_binomialPMF(5, Fp!128(0.75)).to!double.approxEqual(binomialPMF(0, 5, 0.75)));
    assert(1.fp_binomialPMF(5, Fp!128(0.75)).to!double.approxEqual(binomialPMF(1, 5, 0.75)));
    assert(2.fp_binomialPMF(5, Fp!128(0.75)).to!double.approxEqual(binomialPMF(2, 5, 0.75)));
    assert(3.fp_binomialPMF(5, Fp!128(0.75)).to!double.approxEqual(binomialPMF(3, 5, 0.75)));
    assert(4.fp_binomialPMF(5, Fp!128(0.75)).to!double.approxEqual(binomialPMF(4, 5, 0.75)));
    assert(5.fp_binomialPMF(5, Fp!128(0.75)).to!double.approxEqual(binomialPMF(5, 5, 0.75)));
}

private
@safe pure nothrow @nogc
T binomialCDFImpl(T, BinomialAlgo binomialAlgo)(const size_t k, const size_t n, const T p)
    if (isFloatingPoint!T && binomialAlgo == BinomialAlgo.direct)
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: pow;

    if (k == n) {
        return 1;
    } else if (k == 0) {
        return pow(1 - p, n);
    } else if (k <= n / 2 + 1) {
        T result = 0;

        foreach (size_t i; 0 .. (k + 1)) {
            result += binomialPMFImpl!(T, binomialAlgo)(i, n, p);
        }

        return result;
    } else {
        return 1 - binomialCDFImpl!(T, binomialAlgo)(n - k - 1, n, 1 - p);
    }
}

private
@safe pure nothrow @nogc
T binomialCDFImpl(T, BinomialAlgo binomialAlgo)(const size_t k, const size_t n, const T p)
    if (isFloatingPoint!T &&
        (binomialAlgo == BinomialAlgo.approxNormal || 
         binomialAlgo == BinomialAlgo.approxNormalContinuityCorrection))
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: sqrt;
    import mir.stat.distribution.normal: normalCDF;

    T l = k;
    static if (binomialAlgo == BinomialAlgo.approxNormalContinuityCorrection) {
        l += 0.5;
    }
    return normalCDF(l, n * p, sqrt(n * p * (1 - p)));
}

private
@safe pure nothrow @nogc
T binomialCDFImpl(T, BinomialAlgo binomialAlgo, PoissonAlgo poissonAlgo)(const size_t k, const size_t n, const T p)
    if (isFloatingPoint!T && binomialAlgo == BinomialAlgo.approxPoisson)
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.stat.distribution.poisson: poissonCDF;

    return poissonCDF!poissonAlgo(k, n * p);
}

/++
Computes the binomial cumulative distribution function (CDF).

Additional algorithms may be provided for calculating CDF that allow trading off
time and accuracy. If `approxPoisson` is provided, the default is `PoissonAlgo.gamma`

Params:
    binomialAlgo = algorithm for calculating CDF (default: BinomialAlgo.direct)
    poissonAlgo = algorithm for poisson approximation (default: PoissonAlgo.gamma)

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Binomial_distribution, binomial probability distribution)
+/
@safe pure nothrow @nogc
template binomialCDF(BinomialAlgo binomialAlgo = BinomialAlgo.direct,
                     PoissonAlgo poissonAlgo = PoissonAlgo.gamma)
{
    /++
    Params:
    k = value to evaluate CDF (e.g. number of "heads")
    n = number of trials
    p = `true` probability
    +/
    T binomialCDF(T)(const size_t k, const size_t n, const T p)
        if (isFloatingPoint!T)
        in (k <= n, "k must be less than or equal to n")
        in (p >= 0, "p must be greater than or equal to 0")
        in (p <= 1, "p must be less than or equal to 1")
    {
        static if (binomialAlgo != BinomialAlgo.approxPoisson)
            return binomialCDFImpl!(T, binomialAlgo)(k, n, p);
        else
            return binomialCDFImpl!(T, binomialAlgo, poissonAlgo)(k, n, p);
    }
}

/// ditto
@safe pure nothrow @nogc
template binomialCDF(string binomialAlgo, string poissonAlgo = "gamma")
{
    mixin("alias binomialCDF = .binomialCDF!(BinomialAlgo." ~ binomialAlgo ~ ", PoissonAlgo." ~ poissonAlgo ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, pow;

    assert(4.binomialCDF(6, 2.0 / 3).approxEqual(binomialPMF(0, 6, 2.0 / 3) + binomialPMF(1, 6, 2.0 / 3) + binomialPMF(2, 6, 2.0 / 3) + binomialPMF(3, 6, 2.0 / 3) + binomialPMF(4, 6, 2.0 / 3)));
    // For large values of `n` with `p` not too extreme, can approximate with normal distribution
    assert(550_000.binomialCDF!"approxNormal"(1_000_000, 0.55).approxEqual(0.5));
    // Or closer with continuity correction
    assert(550_000.binomialCDF!"approxNormalContinuityCorrection"(1_000_000, 0.55).approxEqual(0.500401));
    // Poisson approximation is better when `p` is low
    assert(10_000.binomialCDF!"approxPoisson"(1_000_000, 0.01).approxEqual(0.5026596));
}

// test multiple direct
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    
    static double sumOfbinomialPMFs(T)(size_t k, size_t n, T p) {
        double result = 0.0;
        for (size_t i; i <= k; i++) {
            result += binomialPMF(i, n, p);
        }
        return result;
    }

    // n = 5
    for (size_t i; i <= 5; i++) {
        assert(i.binomialCDF(5, 0.25).approxEqual(sumOfbinomialPMFs(i, 5, 0.25)));
        assert(i.binomialCDF(5, 0.50).approxEqual(sumOfbinomialPMFs(i, 5, 0.50)));
        assert(i.binomialCDF(5, 0.75).approxEqual(sumOfbinomialPMFs(i, 5, 0.75)));
    }

    // n = 6
    for (size_t i; i <= 6; i++) {
        assert(i.binomialCDF(6, 0.25).approxEqual(sumOfbinomialPMFs(i, 6, 0.25)));
        assert(i.binomialCDF(6, 0.5).approxEqual(sumOfbinomialPMFs(i, 6, 0.5)));
        assert(i.binomialCDF(6, 0.75).approxEqual(sumOfbinomialPMFs(i, 6, 0.75)));
    }
}

// test BinomialAlgo.approxNormal / approxNormalContinuityCorrection / approxPoisson
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, sqrt;
    import mir.stat.distribution.normal: normalCDF;
    import mir.stat.distribution.poisson: poissonCDF;
    
    for (size_t i; i < 5; i++) {
        assert(i.binomialCDF!"approxNormal"(5, 0.75).approxEqual(normalCDF(i, 5.0 * 0.75, sqrt(5.0 * 0.75 * 0.25))));
        assert(i.binomialCDF!"approxNormalContinuityCorrection"(5, 0.75).approxEqual(normalCDF(i + 0.5, 5.0 * 0.75, sqrt(5.0 * 0.75 * 0.25))));
        assert(i.binomialCDF!"approxPoisson"(5, 0.75).approxEqual(poissonCDF!"gamma"(i, 5 * 0.75)));
        assert(i.binomialCDF!("approxPoisson", "direct")(5, 0.75).approxEqual(poissonCDF(i, 5 * 0.75)));
    }
}

private
@safe pure nothrow @nogc
T binomialCCDFImpl(T, BinomialAlgo binomialAlgo)(const size_t k, const size_t n, const T p)
    if (isFloatingPoint!T && binomialAlgo == BinomialAlgo.direct)
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: pow;

    if (k == n) {
        return 0;
    } else if (k == 0) {
        return 1 - pow(1 - p, n);
    } else if (k >= n / 2) {
        T result = 0;

        foreach (size_t i; (k + 1) .. (n + 1)) {
            result += binomialPMFImpl!(T, binomialAlgo)(i, n, p);
        }

        return result;
    } else {
        return 1 - binomialCCDFImpl!(T, binomialAlgo)(n - k - 1, n, 1 - p);
    }
}

private
@safe pure nothrow @nogc
T binomialCCDFImpl(T, BinomialAlgo binomialAlgo)(const size_t k, const size_t n, const T p)
    if (isFloatingPoint!T &&
        (binomialAlgo == BinomialAlgo.approxNormal || 
         binomialAlgo == BinomialAlgo.approxNormalContinuityCorrection))
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: sqrt;
    import mir.stat.distribution.normal: normalCCDF;

    T l = k;
    static if (binomialAlgo == BinomialAlgo.approxNormalContinuityCorrection) {
        l += 0.5;
    }
    return normalCCDF(l, n * p, sqrt(n * p * (1 - p)));
}

private
@safe pure nothrow @nogc
T binomialCCDFImpl(T, BinomialAlgo binomialAlgo, PoissonAlgo poissonAlgo)(const size_t k, const size_t n, const T p)
    if (isFloatingPoint!T && binomialAlgo == BinomialAlgo.approxPoisson)
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.stat.distribution.poisson: poissonCCDF;

    return poissonCCDF!poissonAlgo(k, n * p);
}

/++
Computes the binomial complementary cumulative distribution function (CCDF).

Additional algorithms may be provided for calculating CCDF that allow trading off
time and accuracy. If `approxPoisson` is provided, the default is `PoissonAlgo.gamma`

Params:
    binomialAlgo = algorithm for calculating CCDF (default: BinomialAlgo.direct)
    poissonAlgo = algorithm for poisson approximation (default: PoissonAlgo.gamma)

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Binomial_distribution, binomial probability distribution)
+/
@safe pure nothrow @nogc
template binomialCCDF(BinomialAlgo binomialAlgo = BinomialAlgo.direct,
                      PoissonAlgo poissonAlgo = PoissonAlgo.gamma)
{
    /++
    Params:
    k = value to evaluate CCDF (e.g. number of "heads")
    n = number of trials
    p = `true` probability
    +/
    T binomialCCDF(T)(const size_t k, const size_t n, const T p)
        if (isFloatingPoint!T)
        in (k <= n, "k must be less than or equal to n")
        in (p >= 0, "p must be greater than or equal to 0")
        in (p <= 1, "p must be less than or equal to 1")
    {
        static if (binomialAlgo != BinomialAlgo.approxPoisson)
            return binomialCCDFImpl!(T, binomialAlgo)(k, n, p);
        else
            return binomialCCDFImpl!(T, binomialAlgo, poissonAlgo)(k, n, p);
    }
}

/// ditto
@safe pure nothrow @nogc
template binomialCCDF(string binomialAlgo, string poissonAlgo = "gamma")
{
    mixin("alias binomialCCDF = .binomialCCDF!(BinomialAlgo." ~ binomialAlgo ~ ", PoissonAlgo." ~ poissonAlgo ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, pow;

    assert(4.binomialCCDF(6, 2.0 / 3).approxEqual(binomialPMF(5, 6, 2.0 / 3) + binomialPMF(6, 6, 2.0 / 3)));
    // For large values of `n` with `p` not too extreme, can approximate with normal distribution
    assert(550_000.binomialCCDF!"approxNormal"(1_000_000, 0.55).approxEqual(0.5));
    // Or closer with continuity correction
    assert(550_000.binomialCCDF!"approxNormalContinuityCorrection"(1_000_000, 0.55).approxEqual(0.499599));
    // Poisson approximation is better when `p` is low
    assert(10_000.binomialCCDF!"approxPoisson"(1_000_000, 0.01).approxEqual(0.4973404));
}

// test multiple
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    // n = 5
    for (size_t i; i <= 5; i++) {
        assert(i.binomialCCDF(5, 0.25).approxEqual(1 - binomialCDF(i, 5, 0.25)));
        assert(i.binomialCCDF(5, 0.50).approxEqual(1 - binomialCDF(i, 5, 0.50)));
        assert(i.binomialCCDF(5, 0.75).approxEqual(1 - binomialCDF(i, 5, 0.75)));
    }

    // n = 6
    for (size_t i; i <= 6; i++) {
        assert(i.binomialCCDF(6, 0.25).approxEqual(1 - binomialCDF(i, 6, 0.25)));
        assert(i.binomialCCDF(6, 0.5).approxEqual(1 - binomialCDF(i, 6, 0.5)));
        assert(i.binomialCCDF(6, 0.75).approxEqual(1 - binomialCDF(i, 6, 0.75)));
    }
}

// test approxNormal / approxNormalContinuityCorrection / approxPoisson
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    for (size_t i; i <= 5; i++) {
        assert(i.binomialCCDF!"approxNormal"(5, 0.25).approxEqual(1 - binomialCDF!"approxNormal"(i, 5, 0.25)));
        assert(i.binomialCCDF!"approxNormalContinuityCorrection"(5, 0.25).approxEqual(1 - binomialCDF!"approxNormalContinuityCorrection"(i, 5, 0.25)));
        assert(i.binomialCCDF!"approxPoisson"(5, 0.25).approxEqual(1 - binomialCDF!"approxPoisson"(i, 5, 0.25)));
        assert(i.binomialCCDF!("approxPoisson", "direct")(5, 0.25).approxEqual(1 - binomialCDF!("approxPoisson", "direct")(i, 5, 0.25)));
    }
}

private
@safe pure nothrow @nogc
size_t binomialInvCDFImpl(T, BinomialAlgo binomialAlgo)(const T prob, const size_t n, const T p)
    if (isFloatingPoint!T && binomialAlgo == BinomialAlgo.direct)
    in (prob >= 0, "prob must be greater than or equal to 0")
    in (prob <= 1, "prob must be less than or equal to 1")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    if (p == 0) {
        return 0;
    } else if (p == 1) {
        return n;
    }

    size_t guess = 0;
    if ((n > 20 && (p > 0.25 && p < 0.75)) ||
        (n * p > 9 * (1 - p) && n * (1 - p) > 9 * p) ||
        (n * p >= 5 && n * (1 - p) >= 5)) {
        guess = binomialInvCDFImpl!(T, BinomialAlgo.approxNormalContinuityCorrection)(prob, n, p);
    } else if ((n >= 20 && p <= 0.05) ||
               (n >= 100 && n * p <= 10)) {
        guess = binomialInvCDFImpl!(T, BinomialAlgo.approxPoisson, PoissonAlgo.approxNormalContinuityCorrection)(prob, n, p);
    }
    T cdfGuess = binomialCDF!(binomialAlgo)(guess, n, p);

    if (prob <= cdfGuess) {
        if (guess == 0) {
            return guess;
        }
        for (size_t i = (guess - 1); guess >= 0; i--) {
            cdfGuess -= binomialPMF!(binomialAlgo)(i + 1, n, p);
            if (prob > cdfGuess) {
                guess = i + 1;
                break;
            }
        }
    } else {
        while(prob > cdfGuess) {
            guess++;
            cdfGuess += binomialPMF!(binomialAlgo)(guess, n, p);
        }
    }
    return guess;
}

private
@safe pure nothrow @nogc
size_t binomialInvCDFImpl(T, BinomialAlgo binomialAlgo)(const T prob, const size_t n, const T p)
    if (isFloatingPoint!T &&
        (binomialAlgo == BinomialAlgo.approxNormal || 
         binomialAlgo == BinomialAlgo.approxNormalContinuityCorrection))
    in (prob >= 0, "prob must be greater than or equal to 0")
    in (prob <= 1, "prob must be less than or equal to 1")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: floor, sqrt;
    import mir.stat.distribution.normal: normalInvCDF;

    if (prob == 0) {
        return 0;
    } else if (prob == 1) {
        return n;
    }
    auto result = normalInvCDF(prob, n * p, sqrt(n * p * (1 - p)));
    static if (binomialAlgo == BinomialAlgo.approxNormalContinuityCorrection) {
        result = result - 0.5;
    }
    return cast(size_t) floor(result);
}

private
@safe pure nothrow @nogc
size_t binomialInvCDFImpl(T, BinomialAlgo binomialAlgo, PoissonAlgo poissonAlgo)(const T prob, const size_t n, const T p)
    if (isFloatingPoint!T &&
        binomialAlgo == BinomialAlgo.approxPoisson && poissonAlgo != PoissonAlgo.gamma)
    in (prob >= 0, "prob must be greater than or equal to 0")
    in (prob <= 1, "prob must be less than or equal to 1")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.stat.distribution.poisson: poissonInvCDF;

    return poissonInvCDF!poissonAlgo(prob, n * p);
}

/++
Computes the binomial inverse cumulative distribution function (InvCDF).

Additional algorithms may be provided for calculating InvCDF that allow trading off
time and accuracy. If `approxPoisson` is provided, the default is
`PoissonAlgo.direct`, which is different from `binomialPMF` and `binomialCDF`
`PoissonAlgo.gamma` is not supported.

Params:
    binomialAlgo = algorithm for calculating CDF (default: BinomialAlgo.direct)
    poissonAlgo = algorithm for poisson approximation (default: PoissonAlgo.direct)

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Binomial_distribution, binomial probability distribution)
+/
@safe pure nothrow @nogc
template binomialInvCDF(BinomialAlgo binomialAlgo = BinomialAlgo.direct,
                        PoissonAlgo poissonAlgo = PoissonAlgo.direct)
    if (poissonAlgo != PoissonAlgo.gamma)
{
    /++
    Params:
    prob = value to evaluate InvCDF
    n = number of trials
    p = `true` probability
    +/
    size_t binomialInvCDF(T)(const T prob, const size_t n, const T p)
        if (isFloatingPoint!T)
        in (prob >= 0, "prob must be greater than or equal to 0")
        in (prob <= 1, "prob must be less than or equal to 1")
        in (p >= 0, "p must be greater than or equal to 0")
        in (p <= 1, "p must be less than or equal to 1")
    {
        static if (binomialAlgo != BinomialAlgo.approxPoisson)
            return binomialInvCDFImpl!(T, binomialAlgo)(prob, n, p);
        else
            return binomialInvCDFImpl!(T, binomialAlgo, poissonAlgo)(prob, n, p);
    }
}

/// ditto
@safe pure nothrow @nogc
template binomialInvCDF(string binomialAlgo, string poissonAlgo = "direct")
{
    mixin("alias binomialInvCDF = .binomialInvCDF!(BinomialAlgo." ~ binomialAlgo ~ ", PoissonAlgo." ~ poissonAlgo ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    assert(0.15.binomialInvCDF(6, 2.0 / 3) == 3);
    // For large values of `n` with `p` not too extreme, can approximate with normal distribution
    assert(0.5.binomialInvCDF!"approxNormal"(1_000_000, 0.55) == 550_000);
    // Or closer with continuity correction
    assert(0.500401.binomialInvCDF!"approxNormalContinuityCorrection"(1_000_000, 0.55) == 550_000);
    // Poisson approximation is better when `p` is low
    assert(0.5026596.binomialInvCDF!"approxPoisson"(1_000_000, 0.01) == 10_000);
}

// test BinomialAlgo.direct
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.binomialInvCDF(5, 0.6) == 0);
    assert(1.binomialInvCDF(5, 0.6) == 5);
    for (double x = 0.05; x < 1; x = x + 0.05) {
        size_t value = x.binomialInvCDF(5, 0.6);
        assert(value.binomialCDF(5, 0.6) >= x);
        assert((value - 1).binomialCDF(5, 0.6) < x);
    }
}

// test Binomial.direct, alternate guess paths
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    static immutable int[] ns =    [  25,  37,  34,    25,  105];
    static immutable double[] ps = [0.55, 0.2, 0.15, 0.05, 0.025];

    size_t value;
    for (size_t i; i < 1; i++) {
        for (double x = 0.01; x < 1; x = x + 0.01) {
            value = x.binomialInvCDF(ns[i], ps[i]);
            assert(value.binomialCDF(ns[i], ps[i]) >= x);
            assert((value - 1).binomialCDF(ns[i], ps[i]) < x);
        }
    }
}

// test Binomial.approxNormal / approxNormalContinuityCorrection
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: floor, sqrt;
    import mir.stat.distribution.normal: normalInvCDF;

    assert(0.binomialInvCDF!"approxNormal"(1000, 0.55) == 0);
    assert(0.binomialInvCDF!"approxNormalContinuityCorrection"(1000, 0.55) == 0);
    assert(1.binomialInvCDF!"approxNormal"(1000, 0.55) == 1_000);
    assert(1.binomialInvCDF!"approxNormalContinuityCorrection"(1000, 0.55) == 1_000);
    double checkValue;
    for (double x = 0.05; x < 1; x = x + 0.05) {
        checkValue = normalInvCDF(x, 1_000 * 0.55, sqrt(1000 * 0.55 * 0.45));
        assert(x.binomialInvCDF!"approxNormal"(1_000, 0.55) == floor(checkValue));
        assert(x.binomialInvCDF!"approxNormalContinuityCorrection"(1_000, 0.55) == floor(checkValue - 0.5));
    }
}

// test Binomial.approxPoisson
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.stat.distribution.poisson: poissonInvCDF;

    assert(0.binomialInvCDF!"approxPoisson"(20, 0.25) == 0);
    for (double x = 0.05; x < 1; x = x + 0.05) {
        assert(x.binomialInvCDF!"approxPoisson"(20, 0.25) == poissonInvCDF(x, 20 * 0.25));
        assert(x.binomialInvCDF!("approxPoisson", "approxNormalContinuityCorrection")(1_000, 0.55) == poissonInvCDF!"approxNormalContinuityCorrection"(x, 1000 * 0.55));
    }
}

/++
Computes the binomial log probability mass function (LPMF)

Params:
    k = value to evaluate LPMF (e.g. number of "heads")
    n = number of trials
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Binomial_distribution, binomial probability distribution)
+/
T binomialLPMF(T)(const size_t k, const size_t n, const T p)
    if (isFloatingPoint!T)
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.internal.xlogy: xlogy, xlog1py;
    import mir.math.internal.log_binomial: logBinomialCoefficient;

    return logBinomialCoefficient(n, cast(const uint) k) + xlogy(k, p) + xlog1py((n - k), -p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, exp;

    assert(0.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(0, 5, 0.5)));
    assert(1.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(1, 5, 0.5)));
    assert(2.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(2, 5, 0.5)));
    assert(3.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(3, 5, 0.5)));
    assert(4.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(4, 5, 0.5)));
    assert(5.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(5, 5, 0.5)));
}

// test with p = 0.75
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, exp;

    assert(0.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(0, 5, 0.75)));
    assert(1.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(1, 5, 0.75)));
    assert(2.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(2, 5, 0.75)));
    assert(3.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(3, 5, 0.75)));
    assert(4.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(4, 5, 0.75)));
    assert(5.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(5, 5, 0.75)));
}

/// Accurate values for large values of `n`
version(mir_stat_test_fp)
@safe pure nothrow @nogc
unittest {
    import mir.bignum.fp: Fp, fp_log;
    import mir.math.common: approxEqual;

    enum size_t val = 1_000_000;

    assert(0.binomialLPMF(val + 5, 0.75).approxEqual(fp_binomialPMF(0, val + 5, Fp!128(0.75)).fp_log!double));
    assert(1.binomialLPMF(val + 5, 0.75).approxEqual(fp_binomialPMF(1, val + 5, Fp!128(0.75)).fp_log!double));
    assert(2.binomialLPMF(val + 5, 0.75).approxEqual(fp_binomialPMF(2, val + 5, Fp!128(0.75)).fp_log!double));
    assert(5.binomialLPMF(val + 5, 0.75).approxEqual(fp_binomialPMF(5, val + 5, Fp!128(0.75)).fp_log!double));
    assert((val / 2).binomialLPMF(val + 5, 0.75).approxEqual(fp_binomialPMF(val / 2, val + 5, Fp!128(0.75)).fp_log!double));
    assert((val - 5).binomialLPMF(val + 5, 0.75).approxEqual(fp_binomialPMF(val - 5, val + 5, Fp!128(0.75)).fp_log!double));
    assert((val - 2).binomialLPMF(val + 5, 0.75).approxEqual(fp_binomialPMF(val - 2, val + 5, Fp!128(0.75)).fp_log!double));
    assert((val - 1).binomialLPMF(val + 5, 0.75).approxEqual(fp_binomialPMF(val - 1, val + 5, Fp!128(0.75)).fp_log!double));
    assert((val - 0).binomialLPMF(val + 5, 0.75).approxEqual(fp_binomialPMF(val, val + 5, Fp!128(0.75)).fp_log!double));
    
}
