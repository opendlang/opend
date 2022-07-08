/++
This module contains algorithms for the poisson probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.poisson;

import mir.bignum.fp: Fp;
import mir.internal.utility: isFloatingPoint;

/++
Algorithms used to calculate poisson dstribution.

`PoissonAlgo.direct` can be more time-consuming for large values of the number
of events (`k`) or the rate of occurences (`lambda`). Additional algorithms are
provided to the user to choose the trade-off between running time and accuracy.

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Poisson_distribution, poisson probability distribution)
+/
enum PoissonAlgo {
    /++
    Direct
    +/
    direct,
    /++
    Gamma Incomplete function
    +/
    gamma,
    /++
    Approximates poisson distribution with normal distribution. Generally a better approximation when
    `lambda > 1000`.
    +/
    approxNormal,
    /++
    Approximates poisson distribution with normal distribution (including continuity correction). More 
    accurate than `PoissonAlgo.approxNormal`. Generally a better approximation when `lambda > 10`.
    +/
    approxNormalContinuityCorrection
}

private
@safe pure nothrow @nogc
T poissonPMFImpl(T, PoissonAlgo poissonAlgo)(const size_t k, const T lambda)
    if (isFloatingPoint!T && poissonAlgo == PoissonAlgo.direct)
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    import mir.math.common: exp, pow;
    import mir.math.numeric: factorial;

    return exp(-lambda) * pow(lambda, k) / (cast(T) factorial(k));
}

private
@safe pure nothrow @nogc
T poissonPMFImpl(T, PoissonAlgo poissonAlgo)(const size_t k, const T lambda)
    if (isFloatingPoint!T && poissonAlgo == PoissonAlgo.gamma)
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    import std.mathspecial: gammaIncompleteCompl;

    return gammaIncompleteCompl(k + 1, lambda) - gammaIncompleteCompl(k, lambda);
}

private
@safe pure nothrow @nogc
T poissonPMFImpl(T, PoissonAlgo poissonAlgo)(const size_t k, const T lambda)
    if (isFloatingPoint!T && poissonAlgo == PoissonAlgo.approxNormal)
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    import mir.math.common: sqrt;
    import mir.stat.distribution.normal: normalPDF;

    return normalPDF(k, lambda, sqrt(lambda));
}

private
@safe pure nothrow @nogc
T poissonPMFImpl(T, PoissonAlgo poissonAlgo)(const size_t k, const T lambda)
    if (isFloatingPoint!T && poissonAlgo == PoissonAlgo.approxNormalContinuityCorrection)
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    import mir.math.common: sqrt;
    import mir.stat.distribution.normal: normalCDF;

    return normalCDF(cast(T) k + 0.5, lambda, sqrt(lambda)) - normalCDF(cast(T) k - 0.5, lambda, sqrt(lambda));
}

/++
Computes the poisson probability mass function (PMF).

Params:
    poissonAlgo = algorithm for calculating PMF (default: PoissonAlgo.direct)

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Poisson_distribution, poisson probability distribution)
+/
@safe pure nothrow @nogc
template poissonPMF(PoissonAlgo poissonAlgo = PoissonAlgo.direct)
{
    /++
    Params:
        k = value to evaluate PMF (e.g. number of events)
        lambda = expected rate of occurence
    +/
    T poissonPMF(T)(const size_t k, const T lambda)
        if (isFloatingPoint!T)
        in (lambda > 0, "lambda must be greater than or equal to 0")
    {
        return poissonPMFImpl!(T, poissonAlgo)(k, lambda);
    }
}

/// ditto
@safe pure nothrow @nogc
template poissonPMF(string poissonAlgo)
{
    mixin("alias poissonPMF = .poissonPMF!(PoissonAlgo." ~ poissonAlgo ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, exp;
    
    assert(3.poissonPMF(6.0).approxEqual(exp(-6.0) * 216 / 6));
    // Can compute directly with differences of upper incomplete gamma function
    assert(3.poissonPMF!"gamma"(6.0).approxEqual(poissonPMF(3, 6.0)));
    // For large values of k or lambda, can approximate with normal distribution
    assert(1_000_000.poissonPMF!"approxNormal"(1_000_000.0).approxEqual(poissonPMF!"gamma"(1_000_000, 1_000_000.0), 10e-3));
    // Or closer with continuity correction
    assert(1_000_000.poissonPMF!"approxNormalContinuityCorrection"(1_000_000.0).approxEqual(poissonPMF!"gamma"(1_000_000, 1_000_000.0), 10e-3));
}

// test PoissonAlgo.direct
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, exp;

    assert(0.poissonPMF(5.0).approxEqual(exp(-5.0)));
    assert(1.poissonPMF(5.0).approxEqual(exp(-5.0) * 5));
    assert(2.poissonPMF(5.0).approxEqual(exp(-5.0) * 25 / 2));
    assert(3.poissonPMF(5.0).approxEqual(exp(-5.0) * 125 / 6));
    assert(4.poissonPMF(5.0).approxEqual(exp(-5.0) * 625 / 24));
    assert(5.poissonPMF(5.0).approxEqual(exp(-5.0) * 3125 / 120));
    assert(6.poissonPMF(5.0).approxEqual(exp(-5.0) * 15625 / 720));
    assert(7.poissonPMF(5.0).approxEqual(exp(-5.0) * 78125 / 5040));
    assert(8.poissonPMF(5.0).approxEqual(exp(-5.0) * 390625 / 40320));
    assert(9.poissonPMF(5.0).approxEqual(exp(-5.0) * 1953125 / 362880));
    assert(10.poissonPMF(5.0).approxEqual(exp(-5.0) * 9765625 / 3628800));
}

// test PoissonAlgo.gamma
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    for (size_t i; i < 20; i++) {
        assert(i.poissonPMF!"gamma"(5.0).approxEqual(poissonPMF(i, 5.0)));
    }
}

// test PoissonAlgo.approxNormal / approxNormalContinuityCorrection
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, sqrt;
    import mir.stat.distribution.normal: normalCDF, normalPDF;
    for (size_t i; i < 20; i++) {
        assert(i.poissonPMF!"approxNormal"(5.0).approxEqual(normalPDF(i, 5.0, sqrt(5.0))));
        assert(i.poissonPMF!"approxNormalContinuityCorrection"(5.0).approxEqual(normalCDF(i + 0.5, 5.0, sqrt(5.0)) - normalCDF(i - 0.5, 5.0, sqrt(5.0))));
    }
}

/++
Computes the poisson probability mass function (PMF) directly with extended 
floating point types (e.g. `Fp!128`), which provides additional accuracy for
large values of `lambda` or `k`. 

Params:
    k = value to evaluate PMF (e.g. number of "heads")
    lambda = expected rate of occurence

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Poisson_distribution, poisson probability distribution)
+/
@safe pure nothrow @nogc
T fp_poissonPMF(T)(const size_t k, const T lambda)
    if (is(T == Fp!size, size_t size))
    in (cast(double) lambda > 0, "lambda must be greater than or equal to 0")
{
    import mir.math.common: exp;
    import mir.math.internal.fp_powi: fp_powi;
    import mir.math.numeric: factorial;

    return T(exp(-cast(double) lambda)) * fp_powi(lambda, k) / factorial(k);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.bignum.fp: Fp;
    import mir.conv: to;
    import mir.math.common: approxEqual, exp;

    assert(0.fp_poissonPMF(Fp!128(5.0)).to!double.approxEqual(poissonPMF(0, 5.0)));
    assert(1.fp_poissonPMF(Fp!128(5.0)).to!double.approxEqual(poissonPMF(1, 5.0)));
    assert(2.fp_poissonPMF(Fp!128(5.0)).to!double.approxEqual(poissonPMF(2, 5.0)));
    assert(3.fp_poissonPMF(Fp!128(5.0)).to!double.approxEqual(poissonPMF(3, 5.0)));
    assert(4.fp_poissonPMF(Fp!128(5.0)).to!double.approxEqual(poissonPMF(4, 5.0)));
    assert(5.fp_poissonPMF(Fp!128(5.0)).to!double.approxEqual(poissonPMF(5, 5.0)));
    assert(6.fp_poissonPMF(Fp!128(5.0)).to!double.approxEqual(poissonPMF(6, 5.0)));
    assert(7.fp_poissonPMF(Fp!128(5.0)).to!double.approxEqual(poissonPMF(7, 5.0)));
    assert(8.fp_poissonPMF(Fp!128(5.0)).to!double.approxEqual(poissonPMF(8, 5.0)));
    assert(9.fp_poissonPMF(Fp!128(5.0)).to!double.approxEqual(poissonPMF(9, 5.0)));
    assert(10.fp_poissonPMF(Fp!128(5.0)).to!double.approxEqual(poissonPMF(10, 5.0)));
}

private
@safe pure nothrow @nogc
T poissonCDFImpl(T, PoissonAlgo poissonAlgo)(const size_t k, const T lambda)
    if (isFloatingPoint!T && poissonAlgo == PoissonAlgo.direct)
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    import mir.math.common: exp;
    import mir.math.numeric: factorial;

    T output = 1;
    if (k > 0) {
        T multiplier = 1;
        for (size_t i = 1; i < (k + 1); i++) {
            multiplier *= (lambda / i);
            output += multiplier;
        }
    }
    return output * exp(-lambda);
}

private
@safe pure nothrow @nogc
T poissonCDFImpl(T, PoissonAlgo poissonAlgo)(const size_t k, const T lambda)
    if (isFloatingPoint!T && poissonAlgo == PoissonAlgo.gamma)
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    import std.mathspecial: gammaIncompleteCompl;
    return cast(T) gammaIncompleteCompl(k + 1, lambda); 
}

private
@safe pure nothrow @nogc
T poissonCDFImpl(T, PoissonAlgo poissonAlgo)(const size_t k, const T lambda)
    if (isFloatingPoint!T && 
        (poissonAlgo == PoissonAlgo.approxNormal || 
         poissonAlgo == PoissonAlgo.approxNormalContinuityCorrection))
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    import mir.math.common: sqrt;
    import mir.stat.distribution.normal: normalCDF;

    T l = k;
    static if (poissonAlgo == PoissonAlgo.approxNormalContinuityCorrection) {
        l = k + 0.5;
    }
    return normalCDF(l, lambda, sqrt(lambda));
}

/++
Computes the poisson cumulative distrivution function (CDF).

Params:
    poissonAlgo = algorithm for calculating CDF (default: PoissonAlgo.direct)

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Poisson_distribution, poisson probability distribution)
+/
@safe pure nothrow @nogc
template poissonCDF(PoissonAlgo poissonAlgo = PoissonAlgo.direct)
{
    /++
    Params:
        k = value to evaluate CDF (e.g. number of events)
        lambda = expected rate of occurence
    +/
    T poissonCDF(T)(const size_t k, const T lambda)
        if (isFloatingPoint!T)
        in (lambda > 0, "lambda must be greater than or equal to 0")
    {
        return poissonCDFImpl!(T, poissonAlgo)(k, lambda);
    }
}

/// ditto
@safe pure nothrow @nogc
template poissonCDF(string poissonAlgo)
{
    mixin("alias poissonCDF = .poissonCDF!(PoissonAlgo." ~ poissonAlgo ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    
    assert(3.poissonCDF(6.0).approxEqual(poissonPMF(0, 6.0) + poissonPMF(1, 6.0) + poissonPMF(2, 6.0) + poissonPMF(3, 6.0)));
    // Can compute directly with upper incomplete gamma function
    assert(3.poissonCDF!"gamma"(6.0).approxEqual(poissonCDF(3, 6.0)));
    // For large values of k or lambda, can approximate with normal distribution
    assert(1_000_000.poissonCDF!"approxNormal"(1_000_000.0).approxEqual(poissonCDF!"gamma"(1_000_000, 1_000_000.0), 10e-3));
    // Or closer with continuity correction
    assert(1_000_000.poissonCDF!"approxNormalContinuityCorrection"(1_000_000.0).approxEqual(poissonCDF!"gamma"(1_000_000, 1_000_000.0), 10e-3));
}

// test PoissonAlgo.direct
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    
    static double sumOfPoissonPMFs(size_t k, double lambda) {
        double output = 0;
        for (size_t i; i < (k + 1); i++) {
            output += poissonPMF(i, lambda);
        }
        return output;
    }
    
    for (size_t i; i < 20; i++) {
        assert(i.poissonCDF(5.0).approxEqual(sumOfPoissonPMFs(i, 5.0)));
    }
}

// test PoissonAlgo.gamma
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    for (size_t i; i < 20; i++) {
        assert(i.poissonCDF!"gamma"(5.0).approxEqual(poissonCDF(i, 5.0)));
    }
}

// test PoissonAlgo.approxNormal / approxNormalContinuityCorrection
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, sqrt;
    import mir.stat.distribution.normal: normalCDF;
    for (size_t i; i < 20; i++) {
        assert(i.poissonCDF!"approxNormal"(5.0).approxEqual(normalCDF(i, 5.0, sqrt(5.0))));
        assert(i.poissonCDF!"approxNormalContinuityCorrection"(5.0).approxEqual(normalCDF(i + 0.5, 5.0, sqrt(5.0))));
    }
}

private
@safe pure nothrow @nogc
T poissonCCDFImpl(T, PoissonAlgo poissonAlgo)(const size_t k, const T lambda)
    if (isFloatingPoint!T && poissonAlgo == PoissonAlgo.direct)
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    return T(1) - poissonCDFImpl!(T, poissonAlgo)(k, lambda);
}

private
@safe pure nothrow @nogc
T poissonCCDFImpl(T, PoissonAlgo poissonAlgo)(const size_t k, const T lambda)
    if (isFloatingPoint!T && poissonAlgo == PoissonAlgo.gamma)
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    import std.mathspecial: gammaIncomplete;
    return cast(T) gammaIncomplete(k + 1, lambda); 
}

private
@safe pure nothrow @nogc
T poissonCCDFImpl(T, PoissonAlgo poissonAlgo)(const size_t k, const T lambda)
    if (isFloatingPoint!T && 
        (poissonAlgo == PoissonAlgo.approxNormal || 
         poissonAlgo == PoissonAlgo.approxNormalContinuityCorrection))
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    import mir.math.common: sqrt;
    import mir.stat.distribution.normal: normalCCDF;

    T l = k;
    static if (poissonAlgo == PoissonAlgo.approxNormalContinuityCorrection) {
        l = k + 0.5;
    }
    return normalCCDF(l, lambda, sqrt(lambda));
}

/++
Computes the poisson complementary cumulative distrivution function (CCDF).

Params:
    poissonAlgo = algorithm for calculating CCDF (default: PoissonAlgo.direct)

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Poisson_distribution, poisson probability distribution)
+/
@safe pure nothrow @nogc
template poissonCCDF(PoissonAlgo poissonAlgo = PoissonAlgo.direct)
{
    /++
    Params:
        k = value to evaluate CCDF (e.g. number of events)
        lambda = expected rate of occurence
    +/
    T poissonCCDF(T)(const size_t k, const T lambda)
        if (isFloatingPoint!T)
        in (lambda > 0, "lambda must be greater than or equal to 0")
    {
        return poissonCCDFImpl!(T, poissonAlgo)(k, lambda);
    }
}

/// ditto
@safe pure nothrow @nogc
template poissonCCDF(string poissonAlgo)
{
    mixin("alias poissonCCDF = .poissonCCDF!(PoissonAlgo." ~ poissonAlgo ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    
    assert(3.poissonCCDF(6.0).approxEqual(1.0 - (poissonPMF(0, 6.0) + poissonPMF(1, 6.0) + poissonPMF(2, 6.0) + poissonPMF(3, 6.0))));
    // Can compute directly with upper incomplete gamma function
    assert(3.poissonCCDF!"gamma"(6.0).approxEqual(poissonCCDF(3, 6.0)));
    // For large values of k or lambda, can approximate with normal distribution
    assert(1_000_000.poissonCCDF!"approxNormal"(1_000_000.0).approxEqual(poissonCCDF!"gamma"(1_000_000, 1_000_000.0), 10e-3));
    // Or closer with continuity correction
    assert(1_000_000.poissonCCDF!"approxNormalContinuityCorrection"(1_000_000.0).approxEqual(poissonCCDF!"gamma"(1_000_000, 1_000_000.0), 10e-3));
}

// test PoissonAlgo.direct
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    for (size_t i; i < 20; i++) {
        assert(i.poissonCCDF(5.0).approxEqual(1.0 - poissonCDF(i, 5.0)));
    }
}

// test PoissonAlgo.gamma
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    for (size_t i; i < 20; i++) {
        assert(i.poissonCCDF!"gamma"(5.0).approxEqual(poissonCCDF(i, 5.0)));
    }
}

// test PoissonAlgo.approxNormal / approxNormalContinuityCorrection
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, sqrt;
    import mir.stat.distribution.normal: normalCCDF;
    for (size_t i; i < 20; i++) {
        assert(i.poissonCCDF!"approxNormal"(5.0).approxEqual(normalCCDF(i, 5.0, sqrt(5.0))));
        assert(i.poissonCCDF!"approxNormalContinuityCorrection"(5.0).approxEqual(normalCCDF(i + 0.5, 5.0, sqrt(5.0))));
    }
}

private
@safe pure nothrow @nogc
size_t poissonInvCDFImpl(T, PoissonAlgo poissonAlgo)(const T p, const T lambda)
    if (isFloatingPoint!T && poissonAlgo == PoissonAlgo.direct)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p < 1, "p must be less than 1")
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    if (p == 0) {
        return 0;
    }

    size_t guess = 0;
    if (lambda > 16) {
        guess = poissonInvCDFImpl!(T, PoissonAlgo.approxNormalContinuityCorrection)(p, lambda);
    }
    T cdfGuess = poissonCDF!(poissonAlgo)(guess, lambda);

    if (p <= cdfGuess) {
        if (guess == 0) {
            return guess;
        }
        for (size_t i = (guess - 1); guess >= 0; i--) {
            cdfGuess -= poissonPMF!(poissonAlgo)(i + 1, lambda);
            if (p > cdfGuess) {
                guess = i + 1;
                break;
            }
        }
    } else {
        while(p > cdfGuess) {
            guess++;
            cdfGuess += poissonPMF!(poissonAlgo)(guess, lambda);
        }
    }
    return guess;
}

private
@safe pure nothrow @nogc
T poissonInvCDFImpl(T, PoissonAlgo poissonAlgo)(const T p, const size_t k)
    if (isFloatingPoint!T && poissonAlgo == PoissonAlgo.gamma)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p < 1, "p must be less than 1")
{
    import std.mathspecial: gammaIncompleteComplInverse;

    if (p == 0) {
        return 0;
    }
    return gammaIncompleteComplInverse(k + 1, p); 
}

private
@safe pure nothrow @nogc
size_t poissonInvCDFImpl(T, PoissonAlgo poissonAlgo)(const T p, const T lambda)
    if (isFloatingPoint!T && 
        (poissonAlgo == PoissonAlgo.approxNormal || 
         poissonAlgo == PoissonAlgo.approxNormalContinuityCorrection))
    in (p >= 0, "p must be greater than or equal to 0")
    in (p < 1, "p must be less than 1")
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    import mir.math.common: ceil, sqrt;
    import mir.stat.distribution.normal: normalInvCDF;

    if (p == 0) {
        return 0;
    }
    auto result = normalInvCDF(p, lambda, sqrt(lambda));
    static if (poissonAlgo == PoissonAlgo.approxNormalContinuityCorrection) {
        result = result - 0.5;
    }
    return cast(size_t) ceil(result);
}

/++
Computes the poisson inverse cumulative distrivution function (InvCDF).

For algorithms `PoissonAlgo.direct`, `PoissonAlgo.approxNormal`, and 
`PoissonAlgo.approxNormalContinuityCorrection`, the inverse CDF returns the 
number of events (`k`) given the probability (`p`) and rate of occurence
(`lambda`). For the `Poisson.gamma` algorith, the inverse CDF returns the rate
of occurence (`lambda`) given the probability (`p`) and the number of events (`k`).

For `PoissonAlgo.direct`, if the value of `lambda` is larger than 16, then an
initial guess is made based on `PoissonAlgo.approxNormalContinuityCorrection`.

Params:
    poissonAlgo = algorithm for calculating InvCDF (default: PoissonAlgo.direct)

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Poisson_distribution, poisson probability distribution)
+/
@safe pure nothrow @nogc
template poissonInvCDF(PoissonAlgo poissonAlgo = PoissonAlgo.direct)
    if (poissonAlgo == PoissonAlgo.direct ||
        poissonAlgo == PoissonAlgo.approxNormal ||
        poissonAlgo == PoissonAlgo.approxNormalContinuityCorrection)
{
    /++
    Params:
        p = value to evaluate InvCDF
        lambda = expected rate of occurence
    +/
    size_t poissonInvCDF(T)(const T p, const T lambda)
        if (isFloatingPoint!T)
        in (p >= 0, "p must be greater than or equal to 0")
        in (p <= 1, "p must be less than or equal to 1")
        in (lambda > 0, "lambda must be greater than or equal to 0")
    {
        return poissonInvCDFImpl!(T, poissonAlgo)(p, lambda);
    }
}

/// ditto
@safe pure nothrow @nogc
template poissonInvCDF(PoissonAlgo poissonAlgo)
    if (poissonAlgo == PoissonAlgo.gamma)
{
    /++
    Params:
        p = value to evaluate InvCDF
        k = number of events
    +/
    T poissonInvCDF(T)(const T p, const size_t k)
        if (isFloatingPoint!T)
        in (p >= 0, "p must be greater than or equal to 0")
        in (p <= 1, "p must be less than or equal to 1")
    {
        return poissonInvCDFImpl!(T, poissonAlgo)(p, k);
    }
}

/// ditto
@safe pure nothrow @nogc
template poissonInvCDF(string poissonAlgo)
{
    mixin("alias poissonInvCDF = .poissonInvCDF!(PoissonAlgo." ~ poissonAlgo ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    
    assert(0.15.poissonInvCDF(6.0) == 3);
    // Passing `gamma` returns the rate of occurnece
    assert(0.151204.poissonInvCDF!"gamma"(3).approxEqual(6));
    // For large values of k or lambda, can approximate with normal distribution
    assert(0.5.poissonInvCDF!"approxNormal"(1_000_000.0) == 1_000_000);
    // Or closer with continuity correction
    assert(0.5.poissonInvCDF!"approxNormalContinuityCorrection"(1_000_000.0) == 1_000_000);
}

// test PoissonAlgo.direct
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.poissonInvCDF(5.0) == 0);
    for (double x = 0.05; x < 1; x = x + 0.05) {
        size_t value = x.poissonInvCDF(5.0);
        assert(value.poissonCDF(5.0) >= x);
        assert((value - 1).poissonCDF(5.0) < x);
    }
}

// test PoissonAlgo.direct, large lambda branch
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.poissonInvCDF(25.0) == 0);
    for (double x = 0.01; x < 1; x = x + 0.01) {
        size_t value = x.poissonInvCDF(25.0);
        assert(value.poissonCDF(25.0) >= x);
        assert((value - 1).poissonCDF(25.0) < x);
    }
}

// test PoissonAlgo.gamma (note the difference in how it is tested)
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    for (double x = 0.05; x < 1; x = x + 0.05) {
        for (size_t i; i < 10; i++) {
            assert(poissonCDF!"gamma"(i, poissonInvCDF!"gamma"(x, i)).approxEqual(x));
        }
    }
}

// test PoissonAlgo.approxNormal / approxNormalContinuityCorrection
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: ceil, sqrt;
    import mir.stat.distribution.normal: normalInvCDF;

    assert(0.poissonInvCDF!"approxNormal"(5.0) == 0);
    assert(0.poissonInvCDF!"approxNormalContinuityCorrection"(5.0) == 0);
    double checkValue;
    for (double x = 0.05; x < 1; x = x + 0.05) {
        checkValue = normalInvCDF(x, 5.0, sqrt(5.0));
        assert(x.poissonInvCDF!"approxNormal"(5.0) == ceil(checkValue));
        assert(x.poissonInvCDF!"approxNormalContinuityCorrection"(5.0) == ceil(checkValue - 0.5));
    }
}

/++
Computes the poisson log probability mass function (LogPMF).

Params:
    k = value to evaluate PMF (e.g. number of "heads")
    lambda = expected rate of occurence

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Poisson_distribution, poisson probability distribution)
+/
@safe pure nothrow @nogc
T poissonLogPMF(T)(const size_t k, const T lambda)
    if (isFloatingPoint!T)
    in (lambda > 0, "lambda must be greater than or equal to 0")
{
    import mir.math.common: log;
    import mir.math.internal.log_binomial: logFactorial;

    return k * log(lambda) - (logFactorial!T(k) + lambda);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, exp;

    assert(0.poissonLogPMF(5.0).exp.approxEqual(poissonPMF(0, 5.0)));
    assert(1.poissonLogPMF(5.0).exp.approxEqual(poissonPMF(1, 5.0)));
    assert(2.poissonLogPMF(5.0).exp.approxEqual(poissonPMF(2, 5.0)));
    assert(3.poissonLogPMF(5.0).exp.approxEqual(poissonPMF(3, 5.0)));
    assert(4.poissonLogPMF(5.0).exp.approxEqual(poissonPMF(4, 5.0)));
    assert(5.poissonLogPMF(5.0).exp.approxEqual(poissonPMF(5, 5.0)));
    assert(6.poissonLogPMF(5.0).exp.approxEqual(poissonPMF(6, 5.0)));
    assert(7.poissonLogPMF(5.0).exp.approxEqual(poissonPMF(7, 5.0)));
    assert(8.poissonLogPMF(5.0).exp.approxEqual(poissonPMF(8, 5.0)));
    assert(9.poissonLogPMF(5.0).exp.approxEqual(poissonPMF(9, 5.0)));
    assert(10.poissonLogPMF(5.0).exp.approxEqual(poissonPMF(10, 5.0)));
}
