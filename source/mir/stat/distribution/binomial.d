/++
This module contains algorithms for the binomial probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.binomial;

import mir.bignum.fp: Fp;
import mir.internal.utility: isFloatingPoint;


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
    Approximates poisson distribution with normal distribution
    +/
    approxNormal,
    /++
    Approximates poisson distribution with normal distribution (including continuity correction)
    +/
    approxNormalContinuityCorrection
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

/++
Computes the binomial probability mass function (PMF).



See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Binomial_distribution, binomial probability distribution)
+/
@safe pure nothrow @nogc
template binomialPMF(BinomialAlgo binomialAlgo = BinomialAlgo.direct) {
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
        return binomialPMFImpl!(T, binomialAlgo)(k, n, p);
    }
}

/// ditto
@safe pure nothrow @nogc
template binomialPMF(string poissonAlgo)
{
    mixin("alias binomialPMF = .binomialPMF!(BinomialAlgo." ~ binomialAlgo ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, pow;
    import mir.combinatorics: binomial;

    assert(0.binomialPMF(5, 0.5).approxEqual(binomial(5, 0) * pow(0.5, 5)));
    assert(1.binomialPMF(5, 0.5).approxEqual(binomial(5, 1) * pow(0.5, 5)));
    assert(2.binomialPMF(5, 0.5).approxEqual(binomial(5, 2) * pow(0.5, 5)));
    assert(3.binomialPMF(5, 0.5).approxEqual(binomial(5, 3) * pow(0.5, 5)));
    assert(4.binomialPMF(5, 0.5).approxEqual(binomial(5, 4) * pow(0.5, 5)));
    assert(5.binomialPMF(5, 0.5).approxEqual(binomial(5, 5) * pow(0.5, 5)));
}

// p = 0.75
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, pow;
    import mir.combinatorics: binomial;

    assert(0.binomialPMF(5, 0.75).approxEqual(binomial(5, 0) * pow(0.75, 0) * pow(0.25, 5)));
    assert(1.binomialPMF(5, 0.75).approxEqual(binomial(5, 1) * pow(0.75, 1) * pow(0.25, 4)));
    assert(2.binomialPMF(5, 0.75).approxEqual(binomial(5, 2) * pow(0.75, 2) * pow(0.25, 3)));
    assert(3.binomialPMF(5, 0.75).approxEqual(binomial(5, 3) * pow(0.75, 3) * pow(0.25, 2)));
    assert(4.binomialPMF(5, 0.75).approxEqual(binomial(5, 4) * pow(0.75, 4) * pow(0.25, 1)));
    assert(5.binomialPMF(5, 0.75).approxEqual(binomial(5, 5) * pow(0.75, 5) * pow(0.25, 0)));
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
