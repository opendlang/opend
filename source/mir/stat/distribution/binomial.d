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
template binomialPMF(BinomialAlgo binomialAlgo = BinomialAlgo.direct, PoissonAlgo poissonAlgo = PoissonAlgo.gamma) {
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

// p = 0.25, 0.5, 0.75
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
Computes the binomial probability mass function (PMF).

////
// TODO: Fixup
////
This function can control the type of the function output through the template
parameter `T`. By default, `T` is set equal to `double`, but other floating
point types or extended precision floating point types (e.g. `Fp!128`) can be
used. For large values of `n`, `Fp!128` is recommended.

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
version(mir_stat_test)
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
version(mir_stat_test)
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
