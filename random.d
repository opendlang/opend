/**Generates random samples from a small but growing number of probability
 * distributions.
 *
 * Author:  David Simcha
 *
 * Copyright (c) 2009, David Simcha
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 *     * Neither the name of the authors nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*/


/* Unit tests are non-deterministic.  They prove that the distributions
 * are reasonable by using K-S tests and summary stats, but cannot
 * deterministically prove correctness.*/

module dstats.random;

import std.math, std.algorithm, dstats.distrib;
public import std.random; //For uniform distrib.

version(unittest) {
    import std.stdio, dstats.tests, dstats.summary;
    void main() {}
}

///Generates a random number from normal(mean, sd) distribution.
real rNorm(RGen)(ref RGen gen, real mean = 0.0L, real sd = 1.0L) {
    real p = uniform(gen, 0.0L, 1.0L);
    return invNormalCDF(p) * sd + mean;
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    real[] observ = new real[100_000];
    foreach(ref elem; observ)
        elem = rNorm(gen);
    auto ksRes = ksPval(observ, parametrize!(normalCDF)(0.0L, 1.0L));
    writeln("100k samples from normal(0, 1):  K-S P-val:  ", ksRes);
    writeln("\tMean Expected: 0  Observed:  ", mean(observ));
    writeln("\tMedian Expected: 0  Observed:  ", median(observ));
    writeln("\tStdev Expected:  1  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  0  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  0  Observed:  ", skewness(observ));
    delete observ;
}

///Random Cauchy-distributed number.
real rCauchy(RGen)(ref RGen gen, real X0 = 0, real gamma = 1) {
    real p = uniform(gen, 0.0L, 1.0L);
    return invCauchyCDF(p, X0, gamma);
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    real[] observ = new real[100_000];
    foreach(ref elem; observ)
        elem = rCauchy(gen);
    auto ksRes = ksPval(observ, parametrize!(cauchyCDF)(0.0L, 1.0L));
    writeln("100k samples from Cauchy(0, 1):  K-S P-val:  ", ksRes);
    writeln("\tMean Expected: N/A  Observed:  ", mean(observ));
    writeln("\tMedian Expected: 0  Observed:  ", median(observ));
    writeln("\tStdev Expected:  N/A  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  N/A  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  N/A  Observed:  ", skewness(observ));
    delete observ;
}

real rStudentT(RGen)(ref RGen gen, real df) {
    real pVal = uniform(gen, 0.0L, 1.0L);
    return invStudentsTCDF(pVal, df);
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    real[] observ = new real[10_000];
    foreach(ref elem; observ)
        elem = rStudentT(gen, 5);
    auto ksRes = ksPval(observ, parametrize!(studentsTCDF)(5));
    writeln("10k samples from T(5):  K-S P-val:  ", ksRes);
    writeln("\tMean Expected: 0  Observed:  ", mean(observ));
    writeln("\tMedian Expected: 0  Observed:  ", median(observ));
    writeln("\tStdev Expected:  1.2909  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  6  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  0  Observed:  ", skewness(observ));
    delete observ;
}

/**Generates a random number from the Poisson distribution.*/
uint rPoisson(RGen)(ref RGen gen, real lambda) {
    real pVal = uniform(gen, 0.0L, 1.0L);
    uint guess = cast(uint) max(round(
          invNormalCDF(pVal, lambda, sqrt(lambda)) + 0.5), 0.0L);
    if(pVal < 0.5 && guess > lambda) // Numerical issues w/ extreme vals.
        guess = 0;
    real guessP = poissonCDF(guess, lambda);

    if(guessP == pVal) {
        return guess;
    } else if(guessP < pVal) {
        for(uint k = guess + 1; ; k++) {
            guessP += poissonPMF(k, lambda);
            if(guessP == 1 || guessP > pVal) {
                return k;
            }
        }
    } else {
        for(uint k = guess - 1; k != uint.max; k--) {
            guessP -= poissonPMF(k + 1, lambda);
            if(guessP < pVal) {
                return k + 1;
            }
        }
        return 0;
    }
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    real lambda = 4L;
    uint[] observ = new uint[100_000];
    foreach(ref elem; observ)
        elem = rPoisson(gen, lambda);
    auto ksRes = ksPval(observ, parametrize!(poissonCDF)(lambda));
    writeln("100k samples from poisson(", lambda,
            "):  K-S P-val:  ", ksRes);
    writeln("\tMean Expected: ", lambda,
            "  Observed:  ", mean(observ));
    writeln("\tMedian Expected: ??  Observed:  ", median(observ));
    writeln("\tStdev Expected:  ", sqrt(lambda),
            "  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  ", 1 / lambda,
            "  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  ", 1 / sqrt(lambda),
            "  Observed:  ", skewness(observ));
    delete observ;
}

///Bernoulli r.v. with probability p of equaling 1.
uint rBernoulli(RGen)(ref RGen gen, real P = 0.5) {
    real pVal = uniform(gen, 0.0L, 1.0L);
    return cast(uint) (pVal <= P);
}
// No unit test.  Tested indirectly through rBinomial test, too simple to
// bother writing a separate test for.

import std.stdio;
long gue;

/**Generates a random number from the binionial distribution.*/
uint rBinomial(RGen)(ref RGen gen, uint n, real p) {
    // Generate p-value, get normal approx. as starting point, search for
    // binomial element that matches this starting point.  Normal approx.
    // is usually within 1 or 2 elements.
    real pVal = uniform(gen, 0.0L, 1.0L);
    uint guess = cast(uint) max(round(
          invNormalCDF(pVal, n * p, sqrt(n * p * (1 - p)))) + 0.5, 0);
    if(guess > n) {
        if(pVal < 0.5)  // Numerical issues/overflow.
            guess = 0;
        else guess = n;
    }
    real guessP = binomialCDF(guess, n, p);

    if(guessP == pVal) {
        return guess;
    } else if(guessP < pVal) {
        for(uint k = guess + 1; k <= n; k++) {
            guessP += binomialPMF(k, n, p);
            if(guessP > pVal) {
                return k;
            }
        }
        return n;
    } else {
        for(uint k = guess - 1; k != uint.max; k--) {
            guessP -= binomialPMF(k + 1, n, p);
            if(guessP < pVal) {
                return k + 1;
            }
        }
        return 0;
    }
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    real p = 0.7;
    uint n = 10;
    uint[] observ = new uint[100_000];
    foreach(ref elem; observ)
        elem = rBinomial(gen, n, p);
    auto ksRes = ksPval(observ, parametrize!(binomialCDF)(n, p));
    writeln("100k samples from binom.(", n, ", ", p,
            "):  K-S P-val:  ", ksRes);
    writeln("\tMean Expected: ", n * p,
            "  Observed:  ", mean(observ));
    writeln("\tMedian Expected: ", n * p, "  Observed:  ", median(observ));
    writeln("\tStdev Expected:  ", sqrt(n * p * (1 - p)),
            "  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  ", (1 - 6 * p * (1 - p)) / (n * p * (1 - p)),
            "  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  ", (1 - 2 * p) / (sqrt(n * p * (1 - p))),
            "  Observed:  ", skewness(observ));
    delete observ;
}

/**Generates a random number from a hypergeometric distribution.
 *
 * Bugs:  Slow for large values of N.  Fairly naive implementation.
 * Reasonably fast, though, for small values (<100) of N.*/
uint rHypergeometric(RGen)(ref RGen gen, uint N1, uint N2, uint N)
in {
    assert(N <= (N1 + N2));
} body {
    uint result = 0;
    real total = N1 + N2;
    real[2] NR;
    NR[0] = N2;
    NR[1] = N1;
    foreach(i; 0..N) {
        uint X = rBernoulli(gen, NR[1] / (NR[0] + NR[1]));
        NR[X] -= 1.0L;
        result += X;
    }
    return result;
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    uint n1 = 20, n2 = 30, n = 10;
    uint[] observ = new uint[100_000];
    foreach(ref elem; observ)
        elem = rHypergeometric(gen, n1, n2, n);
    auto ksRes = ksPval(observ, parametrize!(hypergeometricCDF)(n1, n2, n));
    writeln("100k samples from hypergeom.(", n1, ", ", n2, ", ", n,
            "):  K-S P-val:  ", ksRes);
    writeln("\tMean Expected: ", n * cast(real) n1 / (n1 + n2),
            "  Observed:  ", mean(observ));
    writeln("\tMedian Expected: ??  Observed:  ", median(observ));
    writeln("\tStdev Expected:  ", sqrt(cast(real) n * (cast(real) n1 / (n1 + n2))
            * (1 - cast(real) n1 / (n1 + n2)) * (n1 + n2 - n) / (n1 + n2 - 1)),
            "  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  ??  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  ??  Observed:  ", skewness(observ));
    delete observ;
}

/**Negative binomially distributed r.v.  For geometrically distributed r.v.,
 * set n = 1, since geometric distribution is just a special case of neg.
 * binomial.*/
uint rNegBinom(RGen)(ref RGen gen, uint n, real p)
in {
    assert(p >= 0 && p <= 1);
    assert(n > 0);
} body {
    real pVal = uniform(gen, 0.0L, 1.0L);
    // Normal or gamma approx, then adjust.
    real mean = n * (1 - p) / p;
    real var = n * (1 - p) / (p * p);
    real skew = (2 - p) / sqrt(n * (1 - p));
    //writeln(skew, "\t", mean, "\t", var);
    real kk = 4.0L / (skew * skew);
    real theta = sqrt(var / kk);
    real offset = (kk * theta) - mean + 0.5L;
    uint guess;

    // invGammaCDFR is very expensive, but worth it in cases where normal approx
    // would be the worst.  Otherwise, use normal b/c it's *MUCH* cheaper to
    // calculate.
    if(skew > 1.5 && var > 1_048_576)
        guess = cast(uint) max(round(
         invGammaCDFR(1 - pVal, 1 / theta, kk) - offset), 0.0L);
    else
        guess = cast(uint) max(round(
           invNormalCDF(pVal, mean, sqrt(var)) + 0.5), 0.0L);
    // This is pretty arbitrary behavior, but I don't want to use exceptions
    // and it has to be handled as a special case.
    if(pVal > 1 - real.epsilon)
        return uint.max;
    real guessP = negBinomCDF(guess, n, p);

    if(guessP == pVal) {
        return guess;
    } else if(guessP < pVal) {
        for(uint k = guess + 1; ; k++) {
            real newP = guessP + negBinomPMF(k, n, p);
            // Test for aliasing.
            if(newP == guessP) {
                return k - 1;
            } else if(newP >= pVal) {
                return k;
            } else if(newP >= 1) {
                return k;
            } else {
                guessP = newP;
            }
        }
    } else {
        for(uint k = guess - 1; guess != uint.max; k--) {
            real newP = guessP - negBinomPMF(k + 1, n, p);
            // Test for aliasing.
            if(newP == guessP) {
                return k + 1;
            } else if(newP <= pVal) {
                return k + 1;
            } else {
                guessP = newP;
            }
        }
        return 0;
    }
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    real p = 0.65L;
    uint n = 5;
    uint[] observ = new uint[100_000];
    foreach(ref elem; observ)
        elem = rNegBinom(gen, n, p);
    auto ksRes = ksPval(observ, parametrize!(negBinomCDF)(n, p));
    writeln("100k samples from neg. binom.(", n,", ",  p,
            "):  K-S P-val:  ", ksRes);
    writeln("\tMean Expected: ", n * (1 - p) / p,
            "  Observed:  ", mean(observ));
    writeln("\tMedian Expected: ??  Observed:  ", median(observ));
    writeln("\tStdev Expected:  ", sqrt(n * (1 - p) / (p * p)),
            "  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  ", 6 / n + p * p / (n * (1 - p)),
            "  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  ", (2 - p) / sqrt(n * (1 - p)),
            "  Observed:  ", skewness(observ));
    delete observ;
}

///
real rLaplace(RGen)(ref RGen gen, real mu = 0, real b = 1) {
    real p = uniform(gen, 0.0L, 1.0L);
    return invLaplaceCDF(p, mu, b);
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    real[] observ = new real[100_000];
    foreach(ref elem; observ)
        elem = rLaplace(gen);
    auto ksRes = ksPval(observ, parametrize!(laplaceCDF)(0.0L, 1.0L));
    writeln("100k samples from Laplace(0, 1):  K-S P-val:  ", ksRes);
    writeln("\tMean Expected: 0  Observed:  ", mean(observ));
    writeln("\tMedian Expected: 0  Observed:  ", median(observ));
    writeln("\tStdev Expected:  1.414  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  3  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  0  Observed:  ", skewness(observ));
    delete observ;
}

/**Exponentially distributed r.v.  This is a special case of the
 * gamma distribution, with b = 1.  However, it's a common special
 * case and this function is a lot faster than the more general rGamma.*/
real rExponential(RGen)(ref RGen gen, real lambda) {
    real p = uniform(gen, 0.0L, 1.0L);
    return -log(p) / lambda;
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    real[] observ = new real[100_000];
    foreach(ref elem; observ)
        elem = rExponential(gen, 2.0L);
    auto ksRes = ksPval(observ, parametrize!(gammaCDF)(2, 1));
    writeln("100k samples from exponential(2):  K-S P-val:  ", ksRes);
    writeln("\tMean Expected: 0.5  Observed:  ", mean(observ));
    writeln("\tMedian Expected: 0.3465  Observed:  ", median(observ));
    writeln("\tStdev Expected:  0.5  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  6  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  2  Observed:  ", skewness(observ));
    delete observ;
}

/**Gamma distributed r.v.  If b is set to one, this becomes
 * reduces to the exponential distribution.  However, since
 * this is a common special case, a separate exponential random
 * number generator is provided for speed.*/
real rGamma(RGen)(ref RGen gen, real a = 1, real b = 1) {
    real p = uniform(gen, 0.0L, 1.0L);
    return invGammaCDFR(p, a, b);
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    real[] observ = new real[100_000];
    foreach(ref elem; observ)
        elem = rGamma(gen, 2.0L, 3.0L);
    auto ksRes = ksPval(observ, parametrize!(gammaCDF)(2, 3));
    writeln("100k samples from gamma(2, 3):  K-S P-val:  ", ksRes);
    writeln("\tMean Expected: 1.5  Observed:  ", mean(observ));
    writeln("\tMedian Expected: ??  Observed:  ", median(observ));
    writeln("\tStdev Expected:  0.866  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  2  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  1.15  Observed:  ", skewness(observ));
    delete observ;
}
