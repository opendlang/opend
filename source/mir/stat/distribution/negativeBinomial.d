/++
This module contains algorithms for the negative binomial probability distribution.

There are multiple alternative formulations of the negative binomial distribution. The
formulation in this module uses the number of Bernoulli trials until `r` successes. 

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.negativeBinomial;

import mir.bignum.fp: Fp;
import mir.internal.utility: isFloatingPoint;

/++
Computes the negative binomial probability mass function (PMF).

Params:
    k = value to evaluate PMF (e.g. number of "heads")
    r = number of successes until stopping
    p = `true` probability


See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Negative_binomial_distribution, negative binomial probability distribution)
+/
@safe pure nothrow @nogc
T negativeBinomialPMF(T)(const size_t k, const size_t r, const T p)
    if (isFloatingPoint!T)
    in (r > 0, "number of failures must be larger than zero")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: pow;
    import mir.combinatorics: binomial;

    return binomial(k + r - 1, r - 1) * pow(1 - p, k) * pow(p, r);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    4.negativeBinomialPMF(6, 3.0 / 4).shouldApprox == 0.0875988;
}

//
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    0.negativeBinomialPMF(6, 2.0 / 3).shouldApprox == 0.0877915;
    1.negativeBinomialPMF(6, 2.0 / 3).shouldApprox == 0.175583;
    2.negativeBinomialPMF(6, 2.0 / 3).shouldApprox == 0.2048468;
    3.negativeBinomialPMF(6, 2.0 / 3).shouldApprox == 0.1820861;
    4.negativeBinomialPMF(6, 2.0 / 3).shouldApprox == 0.1365645;
    5.negativeBinomialPMF(6, 2.0 / 3).shouldApprox == 0.09104303;
    6.negativeBinomialPMF(6, 2.0 / 3).shouldApprox == 0.05563741;
    7.negativeBinomialPMF(6, 2.0 / 3).shouldApprox == 0.0317928;
    8.negativeBinomialPMF(6, 2.0 / 3).shouldApprox == 0.0172211;
    9.negativeBinomialPMF(6, 2.0 / 3).shouldApprox == 0.008929461;
    10.negativeBinomialPMF(6, 2.0 / 3).shouldApprox == 0.00446473;
}

/++
Computes the  negative binomial probability mass function (PMF) directly with extended 
floating point types (e.g. `Fp!128`), which provides additional accuracy for
extreme values of `k`, `r`, or `p`. 

Params:
    k = value to evaluate PMF (e.g. number of "heads")
    r = number of successes until stopping
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Negative_binomial_distribution, negative binomial probability distribution)
+/
@safe pure nothrow @nogc
T fp_negativeBinomialPMF(T)(const size_t k, const size_t r, const T p)
    if (is(T == Fp!size, size_t size))
    in (r > 0, "number of failures must be larger than zero")
    in (cast(double) p >= 0, "p must be greater than or equal to 0")
    in (cast(double) p <= 1, "p must be less than or equal to 1")
{
    import mir.math.internal.fp_powi: fp_powi;
    import mir.math.numeric: binomialCoefficient;

    return binomialCoefficient(k + r - 1, cast(const uint) (r - 1)) * fp_powi(T(1 - cast(double) p), k) * fp_powi(p, r);
}

/// fp_binomialPMF provides accurate values for large values of `n`
version(mir_stat_test_fp)
@safe pure nothrow @nogc
unittest {
    import mir.bignum.fp: Fp, fp_log;
    import mir.test: shouldApprox;

    enum size_t val = 1_000_000;

    0.fp_negativeBinomialPMF(val + 5, Fp!128(0.75)).fp_log!double.shouldApprox == negativeBinomialLPMF(0, val + 5, 0.75);
    1.fp_negativeBinomialPMF(val + 5, Fp!128(0.75)).fp_log!double.shouldApprox == negativeBinomialLPMF(1, val + 5, 0.75);
    2.fp_negativeBinomialPMF(val + 5, Fp!128(0.75)).fp_log!double.shouldApprox == negativeBinomialLPMF(2, val + 5, 0.75);
    5.fp_negativeBinomialPMF(val + 5, Fp!128(0.75)).fp_log!double.shouldApprox == negativeBinomialLPMF(5, val + 5, 0.75);
    (val / 2).fp_negativeBinomialPMF(val + 5, Fp!128(0.75)).fp_log!double.shouldApprox == negativeBinomialLPMF(val / 2, val + 5, 0.75);
    (val - 5).fp_negativeBinomialPMF(val + 5, Fp!128(0.75)).fp_log!double.shouldApprox == negativeBinomialLPMF(val - 5, val + 5, 0.75);
    (val - 2).fp_negativeBinomialPMF(val + 5, Fp!128(0.75)).fp_log!double.shouldApprox == negativeBinomialLPMF(val - 2, val + 5, 0.75);
    (val - 1).fp_negativeBinomialPMF(val + 5, Fp!128(0.75)).fp_log!double.shouldApprox == negativeBinomialLPMF(val - 1, val + 5, 0.75);
    (val - 0).fp_negativeBinomialPMF(val + 5, Fp!128(0.75)).fp_log!double.shouldApprox == negativeBinomialLPMF(val, val + 5, 0.75);
}

// using Fp!128
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.conv: to;
    import mir.test: shouldApprox;

    for (size_t i; i <= 5; i++) {
        i.fp_negativeBinomialPMF(5, Fp!128(0.50)).to!double.shouldApprox == negativeBinomialPMF(i, 5, 0.50);
        i.fp_negativeBinomialPMF(5, Fp!128(0.75)).to!double.shouldApprox == negativeBinomialPMF(i, 5, 0.75);
    }
}

/++
Computes the negative binomial cumulative distribution function (CDF).

Params:
    k = value to evaluate CDF (e.g. number of "heads")
    r = number of successes until stopping
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Negative_binomial_distribution, negative binomial probability distribution)
+/
@safe pure nothrow @nogc
T negativeBinomialCDF(T)(const size_t k, const size_t r, const T p)
    if (isFloatingPoint!T)
    in (r > 0, "number of failures must be larger than zero")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: pow;
    import std.mathspecial: betaIncomplete;

    if (k == 0) {
        return pow(p, r);
    }
    return 1 - betaIncomplete(k + 1, r, 1 - p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    4.negativeBinomialCDF(6, 3.0 / 4).shouldApprox == 0.9218731;
}

// test multiple
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;
    
    static double sumOfnegativeBinomialPMFs(T)(size_t k, size_t r, T p) {
        double result = 0.0;
        for (size_t i; i <= k; i++) {
            result += negativeBinomialPMF(i, r, p);
        }
        return result;
    }

    for (size_t i; i <= 10; i++) {
        i.negativeBinomialCDF(5, 0.25).shouldApprox == sumOfnegativeBinomialPMFs(i, 5, 0.25);
        i.negativeBinomialCDF(5, 0.50).shouldApprox == sumOfnegativeBinomialPMFs(i, 5, 0.50);
        i.negativeBinomialCDF(5, 0.75).shouldApprox == sumOfnegativeBinomialPMFs(i, 5, 0.75);

        i.negativeBinomialCDF(6, 0.25).shouldApprox == sumOfnegativeBinomialPMFs(i, 6, 0.25);
        i.negativeBinomialCDF(6, 0.5).shouldApprox == sumOfnegativeBinomialPMFs(i, 6, 0.5);
        i.negativeBinomialCDF(6, 0.75).shouldApprox == sumOfnegativeBinomialPMFs(i, 6, 0.75);
    }
}

/++
Computes the negative binomial complementary cumulative distribution function (CCDF).

Params:
    k = value to evaluate CCDF (e.g. number of "heads")
    r = number of successes until stopping
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Negative_binomial_distribution, negative binomial probability distribution)
+/
@safe pure nothrow @nogc
T negativeBinomialCCDF(T)(const size_t k, const size_t r, const T p)
    if (isFloatingPoint!T)
    in (r > 0, "number of failures must be larger than zero")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: pow;
    import std.mathspecial: betaIncomplete;

    if (k == 0) {
        return 1 - pow(p, r);
    }
    return betaIncomplete(k + 1, r, 1 - p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    4.negativeBinomialCCDF(6, 3.0 / 4).shouldApprox == 0.07812691;
}

// test multiple
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    for (size_t i; i <= 10; i++) {
        i.negativeBinomialCCDF(5, 0.25).shouldApprox == 1 - negativeBinomialCDF(i, 5, 0.25);
        i.negativeBinomialCCDF(5, 0.50).shouldApprox == 1 - negativeBinomialCDF(i, 5, 0.50);
        i.negativeBinomialCCDF(5, 0.75).shouldApprox == 1 - negativeBinomialCDF(i, 5, 0.75);

        i.negativeBinomialCCDF(6, 0.25).shouldApprox == 1 - negativeBinomialCDF(i, 6, 0.25);
        i.negativeBinomialCCDF(6, 0.5).shouldApprox == 1 - negativeBinomialCDF(i, 6, 0.5);
        i.negativeBinomialCCDF(6, 0.75).shouldApprox == 1 - negativeBinomialCDF(i, 6, 0.75);
    }
}

private
@safe pure nothrow @nogc
size_t negativeBinomialInvCDFSearch(T)(const size_t guess, ref T cdfGuess, const T prob, const size_t r, const T p, const size_t searchIncrement)
    if (isFloatingPoint!T)
    in (r > 0, "number of failures must be larger than zero")
    in (prob >= 0, "prob must be greater than or equal to 0")
    in (prob <= 1, "prob must be less than or equal to 1")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    size_t guessNew = guess;
    if (prob <= cdfGuess) {
        T cdfGuessPrevious;
        while (guessNew > 0) {
            cdfGuessPrevious = cdfGuess;
            cdfGuess = negativeBinomialCDF(guessNew - searchIncrement, r, p);
            if (prob > cdfGuess) {
                cdfGuess = cdfGuessPrevious;
                break;
            }
            guessNew = guessNew > searchIncrement ? guessNew - searchIncrement : 0;
        }
    } else {
        while (prob > cdfGuess) {
            guessNew = guessNew + searchIncrement;
            cdfGuess = negativeBinomialCDF(guessNew, r, p);
        }
    }
    return guessNew;
}

/++
Computes the negative binomial inverse cumulative distribution function (InvCDF).

Params:
    prob = value to evaluate InvCDF
    r = number of successes until stopping
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Negative_binomial_distribution, negative binomial probability distribution)
+/
@safe pure nothrow @nogc
size_t negativeBinomialInvCDF(T)(const T prob, const size_t r, const T p)
    if (isFloatingPoint!T)
    in (r > 0, "number of failures must be larger than zero")
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
        return size_t.max;
    }

    size_t guess = 0;
    T mu = r * (1 - p) / p;
    T pre_std = sqrt(r * (1 - p));
    T std = pre_std / p;
    T z = normalInvCDF(prob);
    if (r > 20 && p > 0.25 && p < 0.75) {
        guess = cast(size_t) floor(mu + std * z - 0.5);
    } else {
        // Cornish-Fisher Approximation
        guess = cast(size_t) floor(mu + std * (z + ((2 - p) / pre_std) * (z * z - 1) / 6));
    }
    T cdfGuess = negativeBinomialCDF(guess, r, p);

    if (guess < 10_000) {
        return negativeBinomialInvCDFSearch(guess, cdfGuess, prob, r, p, 1);
    } else {
        // Faster search for large values of guess
        size_t searchIncrement = cast(size_t) floor(guess * 0.001);
        size_t searchIncrementPrevious;
        do {
            searchIncrementPrevious = searchIncrement;
            guess = negativeBinomialInvCDFSearch(guess, cdfGuess, prob, r, p, searchIncrement);
            searchIncrement = cast(size_t) floor(searchIncrement * 0.01);
        } while (searchIncrementPrevious > 0 && searchIncrement > guess * (10 * T.epsilon));
        if (searchIncrementPrevious <= 1) {
            return guess;
        } else {
            return negativeBinomialInvCDFSearch(guess, cdfGuess, prob, r, p, 1);
        }
    }
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: should;
    0.9.negativeBinomialInvCDF(6, 3.0 / 4).should == 4;
}

//
version(mir_stat_test)
@safe pure nothrow
unittest {
    import mir.test: should;

    0.negativeBinomialInvCDF(5, 0.6).should == 0;
    1.negativeBinomialInvCDF(5, 0.6).should == size_t.max;

    for (double x = 0.05; x < 1; x = x + 0.05) {
        size_t value = x.negativeBinomialInvCDF(5, 0.6);
        value.negativeBinomialCDF(5, 0.6).should!"a >= b"(x);
        if (value > 0) {
            (value - 1).negativeBinomialCDF(5, 0.6).should!"a < b"(x);
        }
    }
}

// alternate guess paths
version(mir_stat_test)
@safe pure nothrow
unittest {
    import mir.test: should;

    static immutable size_t[] ns = [  25,  37,  34,    25,     25,   105];
    static immutable double[] ps = [0.55, 0.2, 0.15, 0.05, 1.0e-8, 0.025];

    size_t value;
    for (size_t i; i < 6; i++) {
        for (double x = 0.01; x < 1; x = x + 0.01) {
            value = x.negativeBinomialInvCDF(ns[i], ps[i]);
            negativeBinomialCDF(value, ns[i], ps[i]).should!"a >= b"(x);
            if (value > 0) {
                negativeBinomialCDF(value - 1, ns[i], ps[i]).should!"a < b"(x);
            }
        }
    }
}

/++
Computes the negative binomial log probability mass function (LPMF).

Params:
    k = value to evaluate PMF (e.g. number of "heads")
    r = number of successes until stopping
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Negative_binomial_distribution, negative binomial probability distribution)
+/
@safe pure nothrow @nogc
T negativeBinomialLPMF(T)(const size_t k, const size_t r, const T p)
    if (isFloatingPoint!T)
    in (r > 0, "number of failures must be larger than zero")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.internal.xlogy: xlogy, xlog1py;
    import mir.math.internal.log_binomial: logBinomialCoefficient;

    return logBinomialCoefficient(k + r - 1, cast(const uint) (r - 1)) + xlog1py(k, -p) + xlogy(r, p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: exp;
    import mir.test: shouldApprox;

    4.negativeBinomialLPMF(6, 3.0 / 4).exp.shouldApprox == 4.negativeBinomialPMF(6, 3.0 / 4);
}

//
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: exp;
    import mir.test: shouldApprox;

    for (size_t i; i <= 10; i++) {
        i.negativeBinomialLPMF(5, 0.5).exp.shouldApprox == negativeBinomialPMF(i, 5, 0.5);
        i.negativeBinomialLPMF(5, 0.75).exp.shouldApprox == negativeBinomialPMF(i, 5, 0.75);
    }
}

/// Accurate values for large values of `n`
version(mir_stat_test_fp)
@safe pure nothrow @nogc
unittest {
    import mir.bignum.fp: Fp, fp_log;
    import mir.test: shouldApprox;

    enum size_t val = 1_000_000;

    0.negativeBinomialLPMF(val + 5, 0.75).shouldApprox == fp_negativeBinomialPMF(0, val + 5, Fp!128(0.75)).fp_log!double;
    1.negativeBinomialLPMF(val + 5, 0.75).shouldApprox == fp_negativeBinomialPMF(1, val + 5, Fp!128(0.75)).fp_log!double;
    2.negativeBinomialLPMF(val + 5, 0.75).shouldApprox == fp_negativeBinomialPMF(2, val + 5, Fp!128(0.75)).fp_log!double;
    5.negativeBinomialLPMF(val + 5, 0.75).shouldApprox == fp_negativeBinomialPMF(5, val + 5, Fp!128(0.75)).fp_log!double;
    (val / 2).negativeBinomialLPMF(val + 5, 0.75).shouldApprox == fp_negativeBinomialPMF(val / 2, val + 5, Fp!128(0.75)).fp_log!double;
    (val - 5).negativeBinomialLPMF(val + 5, 0.75).shouldApprox == fp_negativeBinomialPMF(val - 5, val + 5, Fp!128(0.75)).fp_log!double;
    (val - 2).negativeBinomialLPMF(val + 5, 0.75).shouldApprox == fp_negativeBinomialPMF(val - 2, val + 5, Fp!128(0.75)).fp_log!double;
    (val - 1).negativeBinomialLPMF(val + 5, 0.75).shouldApprox == fp_negativeBinomialPMF(val - 1, val + 5, Fp!128(0.75)).fp_log!double;
    (val - 0).negativeBinomialLPMF(val + 5, 0.75).shouldApprox == fp_negativeBinomialPMF(val, val + 5, Fp!128(0.75)).fp_log!double;
}
