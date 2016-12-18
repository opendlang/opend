/**Probability distribution CDFs, PDFs/PMFs, and a few inverse CDFs.
 *
 * Authors:  David Simcha, Don Clugston*/
 /*
 * Acknowledgements:  Some of this module was borrowed the mathstat module
 * of Don Clugston's MathExtra library.  This was done to create a
 * coherent, complete library without massive dependencies, and without
 * reinventing the wheel.  These functions have been renamed to
 * fit the naming conventions of this library, and are noted below.
 * The code from Don Clugston's MathExtra library was based on the Cephes
 * library by Stephen Moshier.
 *
 * Conventions:
 * Cumulative distribution functions are named <distribution>CDF.  For
 * discrete distributions, are the P(X <= x) where X is the random variable,
 * NOT P(X < x).
 *
 * All CDFs have a complement, named <distribution>CDFR, which stands for
 * "Cumulative Distribution Function Right".  For discrete distributions,
 * this is P(X >= x), NOT P(X > x) and is therefore NOT equal to
 * 1 - <distribution>CDF.  Also, even for continuous distributions, the
 * numerical accuracy is higher for small p-values if the CDFR is used than
 * if 1 - CDF is used.
 *
 * If a PDF/PMF function is included for a distribution, it is named
 * <distribution>PMF or <distribution>PDF (PMF for discrete, PDF for
 * continuous distributions).
 *
 * If an inverse CDF is included, it is named inv<Distribution>CDF.
 *
 * For all distributions, the test statistic is the first function parameter
 * and the distribution parameters are further down the function parameter
 * list.  This is important for certain generic code, such as  tests and
 * the parametrize template.
 *
 * The following functions are identical or functionally equivalent to
 * functions found in MathExtra/Tango.Math.probability.  This information
 * might be useful if someone is trying to integrate this library into other code:
 *
 * normalCDF <=> normalDistribution
 *
 * normalCDFR <=> normalDistributionCompl
 *
 * invNormalCDF <=> normalDistributionComplInv
 *
 * studentsTCDF <=> studentsTDistribution  (Note reversal in argument order)
 *
 * invStudentsTCDF <=> studentsTDistributionInv (Again, arg order reversed)
 *
 * binomialCDF <=> binomialDistribution
 *
 * negBinomCDF <=> negativeBinomialDistribution
 *
 * poissonCDF <=> poissonDistribution
 *
 * chiSqrCDF <=> chiSqrDistribution (Note reversed arg order)
 *
 * chiSqrCDFR <=> chiSqrDistributionCompl (Note reversed arg order)
 *
 * invChiSqCDFR <=> chiSqrDistributionComplInv
 *
 * fisherCDF <=> fDistribution (Note reversed arg order)
 *
 * fisherCDFR <=> fDistributionCompl (Note reversed arg order)
 *
 * invFisherCDFR <=> fDistributionComplInv
 *
 * gammaCDF <=> gammaDistribution  (Note arg reversal)
 *
 * gammaCDFR <=> gammaDistributionCompl  (Note arg reversal)
 *
 * Note that CDFRs/Compls of continuous distributions are not equivalent,
 * because in Tango/MathExtra they represent P(X > x) while in dstats they
 * represent P(X >= x).
 *
 *
 * Copyright (c) 2008-2009, David Simcha and Don Clugston
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

module dstats.distrib;

import std.algorithm, std.conv, std.exception, std.math, std.traits,
    std.mathspecial, std.range;

alias std.mathspecial.erfc erfc;
alias std.mathspecial.erf erf;

import dstats.base;

// CTFE doesn't work yet for sqrt() in GDC.  This value is sqrt(2 * PI).
enum SQ2PI = 2.50662827463100050241576528481104525300698674060993831662992;

version(unittest) {
    import std.stdio, std.random;

    alias std.math.approxEqual ae;
}

/**Takes a distribution function (CDF or PDF/PMF) as a template argument, and
 * parameters as function arguments in the order that they appear in the
 * function declaration and returns a delegate that binds the supplied
 * parameters to the distribution function.  Assumes the non-parameter
 * argument is the first argument to the distribution function.
 *
 * Examples:
 * ---
 * auto stdNormal = parametrize!(normalCDF)(0.0L, 1.0L);
 * ---
 *
 * stdNormal is now a delegate for the normal(0, 1) distribution.*/
double delegate(ParameterTypeTuple!(distrib)[0])
              parametrize(alias distrib)(ParameterTypeTuple!(distrib)[1..$]
              parameters) {

    double calculate(ParameterTypeTuple!(distrib)[0] arg) {
        return distrib(arg, parameters);
    }

    return &calculate;
}

unittest {
    // Just basically see if this compiles.
    auto stdNormal = parametrize!normalCDF(0, 1);
    assert(approxEqual(stdNormal(2.5), normalCDF(2.5, 0, 1)));
}

///
struct ParamFunctor(alias distrib) {
    ParameterTypeTuple!(distrib)[1..$] parameters;

    double opCall(ParameterTypeTuple!(distrib)[0] arg) {
        return distrib(arg, parameters);
    }
}

/**Takes a distribution function (CDF or PDF/PMF) as a template argument, and
 * parameters as function arguments in the order that they appear in the
 * function declaration and returns a functor that binds the supplied
 * parameters to the distribution function.  Assumes the non-parameter
 * argument is the first argument to the distribution function.
 *
 * Examples:
 * ---
 * auto stdNormal = paramFunctor!(normalCDF)(0.0L, 1.0L);
 * ---
 *
 * stdNormal is now a functor for the normal(0, 1) distribution.*/
ParamFunctor!(distrib) paramFunctor(alias distrib)
                       (ParameterTypeTuple!(distrib)[1..$] parameters) {
    ParamFunctor!(distrib) ret;
    foreach(ti, elem; parameters) {
        ret.tupleof[ti] = elem;
    }
    return ret;
}

unittest {
    // Just basically see if this compiles.
    auto stdNormal = paramFunctor!normalCDF(0, 1);
    assert(approxEqual(stdNormal(2.5), normalCDF(2.5, 0, 1)));
}

///
double uniformPDF(double X, double lower, double upper) {
    dstatsEnforce(X >= lower, "Can't have X < lower bound in uniform distribution.");
    dstatsEnforce(X <= upper, "Can't have X > upper bound in uniform distribution.");
    return 1.0L / (upper - lower);
}

///
double uniformCDF(double X, double lower, double upper) {
    dstatsEnforce(X >= lower, "Can't have X < lower bound in uniform distribution.");
    dstatsEnforce(X <= upper, "Can't have X > upper bound in uniform distribution.");

    return (X - lower) / (upper - lower);
}

///
double uniformCDFR(double X, double lower, double upper) {
    dstatsEnforce(X >= lower, "Can't have X < lower bound in uniform distribution.");
    dstatsEnforce(X <= upper, "Can't have X > upper bound in uniform distribution.");

    return (upper - X) / (upper - lower);
}

///
double poissonPMF(ulong k, double lambda) {
    dstatsEnforce(lambda > 0, "Cannot have a Poisson with lambda <= 0 or nan.");

    return exp(cast(double) k * log(lambda) -
            (lambda + logFactorial(k)));  //Grouped for best precision.
}

unittest {
    assert(approxEqual(poissonPMF(1, .1), .0904837));
}

enum POISSON_NORMAL = 1UL << 12;  // Where to switch to normal approx.

// The gamma incomplete function is too unstable and the distribution
// is for all practical purposes normal anyhow.
private double normApproxPoisCDF(ulong k, double lambda)
in {
    assert(lambda > 0);
} body {
    double sd = sqrt(lambda);
    // mean == lambda.
    return normalCDF(k + 0.5L, lambda, sd);
}

/**P(K <= k) where K is r.v.*/
double poissonCDF(ulong k, double lambda) {
    dstatsEnforce(lambda > 0, "Cannot have a poisson with lambda <= 0 or nan.");

    return (max(k, lambda) >= POISSON_NORMAL) ?
           normApproxPoisCDF(k, lambda) :
           gammaIncompleteCompl(k + 1, lambda);
}

unittest {
    // Make sure this jives with adding up PMF elements, since this is a
    // discrete distribution.
    static double pmfSum(uint k, double lambda) {
        double ret = 0;
        foreach(i; 0..k + 1) {
            ret += poissonPMF(i, lambda);
        }
        return ret;
    }

    assert(approxEqual(poissonCDF(1, 0.5), pmfSum(1, 0.5)));
    assert(approxEqual(poissonCDF(3, 0.7), pmfSum(3, 0.7)));

    // Absurdly huge values:  Test normal approximation.
    // Values from R.
    double ans = poissonCDF( (1UL << 50) - 10_000_000, 1UL << 50);
    assert(approxEqual(ans, 0.3828427));

    // Make sure cutoff is reasonable, i.e. make sure gamma incomplete branch
    // and normal branch get roughly the same answer near the cutoff.
    for(double lambda = POISSON_NORMAL / 2; lambda <= POISSON_NORMAL * 2; lambda += 100) {
        for(ulong k = POISSON_NORMAL / 2; k <= POISSON_NORMAL * 2; k += 100) {
            double normAns = normApproxPoisCDF(k, lambda);
            double gammaAns = gammaIncompleteCompl(k + 1, lambda);
            assert(abs(normAns - gammaAns) < 0.01, text(normAns, '\t', gammaAns));
        }
    }
}

// The gamma incomplete function is too unstable and the distribution
// is for all practical purposes normal anyhow.
private double normApproxPoisCDFR(ulong k, double lambda)
in {
    assert(lambda > 0);
} body {
    double sd = sqrt(lambda);
    // mean == lambda.
    return normalCDFR(k - 0.5L, lambda, sd);
}

/**P(K >= k) where K is r.v.*/
double poissonCDFR(ulong k, double lambda) {
    dstatsEnforce(lambda > 0, "Can't have a poisson with lambda <= 0 or nan.");

    return (max(k, lambda) >= POISSON_NORMAL) ?
            normApproxPoisCDFR(k, lambda) :
            gammaIncomplete(k, lambda);
}

unittest {
    // Make sure this jives with adding up PMF elements, since this is a
    // discrete distribution.
    static double pmfSum(uint k, double lambda) {
        double ret = 0;
        foreach(i; 0..k + 1)  {
            ret += poissonPMF(i, lambda);
        }
        return ret;
    }

    assert(approxEqual(poissonCDFR(1, 0.5), 1 - pmfSum(0, 0.5)));
    assert(approxEqual(poissonCDFR(3, 0.7), 1 - pmfSum(2, 0.7)));

    // Absurdly huge value to test normal approximation.
    // Values from R.
    double ans = poissonCDFR( (1UL << 50) - 10_000_000, 1UL << 50);
    assert(approxEqual(ans, 0.6171573));

    // Make sure cutoff is reasonable, i.e. make sure gamma incomplete branch
    // and normal branch get roughly the same answer near the cutoff.
    for(double lambda = POISSON_NORMAL / 2; lambda <= POISSON_NORMAL * 2; lambda += 100) {
        for(ulong k = POISSON_NORMAL / 2; k <= POISSON_NORMAL * 2; k += 100) {
            double normAns = normApproxPoisCDFR(k, lambda);
            double gammaAns = gammaIncomplete(k, lambda);
            assert(abs(normAns - gammaAns) < 0.01, text(normAns, '\t', gammaAns));
        }
    }
}

/**Returns the value of k for the given p-value and lambda.  If p-val
 * doesn't exactly map to a value of k, the k for which poissonCDF(k, lambda)
 * is closest to pVal is used.*/
uint invPoissonCDF(double pVal, double lambda) {
    dstatsEnforce(lambda > 0, "Cannot have a poisson with lambda <= 0 or nan.");
    dstatsEnforce(pVal >= 0 && pVal <= 1, "P-values must be between 0, 1.");

    // Use normal approximation to get approx answer, then brute force search.
    // This works better than you think because for small n, there's not much
    // search space and for large n, the normal approx. is doublely good.
    uint guess = cast(uint) max(round(
          invNormalCDF(pVal, lambda, sqrt(lambda)) + 0.5), 0.0L);
    double guessP = poissonCDF(guess, lambda);

    if(guessP == pVal) {
        return guess;
    } else if(guessP < pVal) {
        for(uint k = guess + 1; ; k++) {
            double newP = guessP + poissonPMF(k, lambda);
            if(newP >= 1)
                return k;
            if(abs(newP - pVal) > abs(guessP - pVal)) {
                return k - 1;
            } else {
                guessP = newP;
            }
        }
    } else {
        for(uint k = guess - 1; k != uint.max; k--) {
            double newP = guessP - poissonPMF(k + 1, lambda);
            if(abs(newP - pVal) > abs(guessP - pVal)) {
                return k + 1;
            } else {
                guessP = newP;
            }
        }
        return 0;
    }
}

unittest {
   foreach(i; 0..1_000) {
       // Restricted variable ranges are because, in the tails, more than one
       // value of k can map to the same p-value at machine precision.
       // Obviously, this is one of those corner cases that nothing can be
       // done about.
       double lambda = uniform(.05L, 8.0L);
       uint k = uniform(0U, cast(uint) ceil(3.0L * lambda));
       double pVal = poissonCDF(k, lambda);
       assert(invPoissonCDF(pVal, lambda) == k);
   }
}

///
double binomialPMF(ulong k, ulong n, double p) {
    dstatsEnforce(k <= n, "k cannot be > n in binomial distribution.");
    dstatsEnforce(p >= 0 && p <= 1, "p must be between 0, 1 in binomial distribution.");
    return exp(logNcomb(n, k) + k * log(p) + (n - k) * log(1 - p));
}

unittest {
    assert(approxEqual(binomialPMF(0, 10, .5), cast(double) 1/1024));
    assert(approxEqual(binomialPMF(100, 1000, .11), .024856));
}

// Determines what value of n we switch to normal approximation at b/c
// betaIncomplete becomes unstable.
private enum BINOM_APPROX = 1UL << 24;

// Cutoff value of n * p for deciding whether to go w/ normal or poisson approx
// when betaIncomplete becomes unstable.
private enum BINOM_POISSON = 1_024;

// betaIncomplete is numerically unstable for huge values of n.
// Luckily this is exactly when the normal approximation becomes
// for all practical purposes exact.
private double normApproxBinomCDF(double k, double n, double p)
in {
    assert(k <= n);
    assert(p >= 0 && p <= 1);
} body {
    double mu = p * n;
    double sd = sqrt( to!double(n) ) * sqrt(p) * sqrt(1 - p);
    double xCC = k + 0.5L;
    return normalCDF(xCC, mu, sd);
}

///P(K <= k) where K is random variable.
double binomialCDF(ulong k, ulong n, double p) {
    dstatsEnforce(k <= n, "k cannot be > n in binomial distribution.");
    dstatsEnforce(p >= 0 && p <= 1, "p must be between 0, 1 in binomial distribution.");

    if(k == n) {
        return 1;
    } else if(k == 0) {
        return pow(1.0 - p,  cast(double) n);
    }

    if(n > BINOM_APPROX) {
        if(n * p < BINOM_POISSON) {
            return poissonCDF(k, n * p);
        } else if(n * (1 - p) < BINOM_POISSON) {
            return poissonCDFR(n - k, n * (1 - p));
        } else {
            return normApproxBinomCDF(k, n, p);
        }
    }

    return betaIncomplete(n - k, k + 1, 1.0 - p);
}

unittest {
    assert(approxEqual(binomialCDF(10, 100, .11), 0.4528744401));
    assert(approxEqual(binomialCDF(15, 100, .12), 0.8585510507));
    assert(approxEqual(binomialCDF(50, 1000, .04), 0.95093595));
    assert(approxEqual(binomialCDF(7600, 15000, .5), .9496193045414));
    assert(approxEqual(binomialCDF(0, 10, 0.2), 0.1073742));

    // Absurdly huge numbers:
    {
        ulong k = (1UL << 60) - 100_000_000;
        ulong n = 1UL << 61;
        assert(approxEqual(binomialCDF(k, n, 0.5L), 0.4476073));
    }

    // Test Poisson branch.
    double poisAns = binomialCDF(85, 1UL << 26, 1.49e-6);
    assert(approxEqual(poisAns, 0.07085327));

    // Test poissonCDFR branch.
    poisAns = binomialCDF( (1UL << 25) - 100, 1UL << 25, 0.9999975L);
    assert(approxEqual(poisAns, 0.04713316));

    // Make sure cutoff is reasonable:  Just below it, we should get similar
    // results for normal, exact.
    for(ulong n = BINOM_APPROX / 2; n < BINOM_APPROX; n += 200_000) {
        for(double p = 0.01; p <= 0.99; p += 0.05) {

            long lowerK = roundTo!long( n * p * 0.99);
            long upperK = roundTo!long( n * p / 0.99);

            for(ulong k = lowerK; k <= min(n, upperK); k += 1_000) {
                double normRes = normApproxBinomCDF(k, n, p);
                double exactRes = binomialCDF(k, n, p);
                assert(abs(normRes - exactRes) < 0.001,
                    text(normRes, '\t', exactRes));
            }
        }
    }

}

// betaIncomplete is numerically unstable for huge values of n.
// Luckily this is exactly when the normal approximation becomes
// for all practical purposes exact.
private double normApproxBinomCDFR(ulong k, ulong n, double p)
in {
    assert(k <= n);
    assert(p >= 0 && p <= 1);
} body {
    double mu = p * n;
    double sd = sqrt( to!double(n) ) * sqrt(p)  * sqrt(1 - p);
    double xCC = k - 0.5L;
    return normalCDFR(xCC, mu, sd);
}

///P(K >= k) where K is random variable.
double binomialCDFR(ulong k, ulong n, double p) {
    dstatsEnforce(k <= n, "k cannot be > n in binomial distribution.");
    dstatsEnforce(p >= 0 && p <= 1, "p must be between 0, 1 in binomial distribution.");

    if(k == 0) {
        return 1;
    } else if(k == n) {
        return pow(p, cast(double) n);
    }

    if(n > BINOM_APPROX) {
        if(n * p < BINOM_POISSON) {
            return poissonCDFR(k, n * p);
        } else if(n * (1 - p) < BINOM_POISSON) {
            return poissonCDF(n - k, n * (1 - p));
        } else {
            return normApproxBinomCDFR(k, n, p);
        }
    }

    return betaIncomplete(k, n - k + 1, p);
}

unittest {
    // Values from R, Maxima.
    assert(approxEqual(binomialCDF(10, 100, .11), 1 -
                      binomialCDFR(11, 100, .11)));
    assert(approxEqual(binomialCDF(15, 100, .12), 1 -
                       binomialCDFR(16, 100, .12)));
    assert(approxEqual(binomialCDF(50, 1000, .04), 1 -
                       binomialCDFR(51, 1000, .04)));
    assert(approxEqual(binomialCDF(7600, 15000, .5), 1 -
                       binomialCDFR(7601, 15000, .5)));
    assert(approxEqual(binomialCDF(9, 10, 0.3), 1 -
                       binomialCDFR(10, 10, 0.3)));

    // Absurdly huge numbers, test normal branch.
    {
        ulong k = (1UL << 60) - 100_000_000;
        ulong n = 1UL << 61;
        assert(approxEqual(binomialCDFR(k, n, 0.5L), 0.5523927));
    }

    // Test Poisson inversion branch.
    double poisRes = binomialCDFR((1UL << 25) - 70, 1UL << 25, 0.9999975L);
    assert(approxEqual(poisRes, 0.06883905));

    // Test Poisson branch.
    poisRes = binomialCDFR(350, 1UL << 25, 1e-5);
    assert(approxEqual(poisRes, 0.2219235));

    // Make sure cutoff is reasonable:  Just below it, we should get similar
    // results for normal, exact.
    for(ulong n = BINOM_APPROX / 2; n < BINOM_APPROX; n += 200_000) {
        for(double p = 0.01; p <= 0.99; p += 0.05) {

            long lowerK = roundTo!long( n * p * 0.99);
            long upperK = roundTo!long( n * p / 0.99);

            for(ulong k = lowerK; k <= min(n, upperK); k += 1_000) {
                double normRes = normApproxBinomCDFR(k, n, p);
                double exactRes = binomialCDFR(k, n, p);
                assert(abs(normRes - exactRes) < 0.001,
                    text(normRes, '\t', exactRes));
            }
        }
    }
}

/**Returns the value of k for the given p-value, n and p.  If p-value does
 * not exactly map to a value of k, the value for which binomialCDF(k, n, p)
 * is closest to pVal is used.*/
uint invBinomialCDF(double pVal, uint n, double p) {
    dstatsEnforce(pVal >= 0 && pVal <= 1, "p-values must be between 0, 1.");
    dstatsEnforce(p >= 0 && p <= 1, "p must be between 0, 1 in binomial distribution.");

    // Use normal approximation to get approx answer, then brute force search.
    // This works better than you think because for small n, there's not much
    // search space and for large n, the normal approx. is doublely good.
    uint guess = cast(uint) max(round(
          invNormalCDF(pVal, n * p, sqrt(n * p * (1 - p)))) + 0.5, 0);
    if(guess > n) {
        if(pVal < 0.5)  // Numerical issues/overflow.
            guess = 0;
        else guess = n;
    }
    double guessP = binomialCDF(guess, n, p);

    if(guessP == pVal) {
        return guess;
    } else if(guessP < pVal) {
        for(uint k = guess + 1; k <= n; k++) {
            double newP = guessP + binomialPMF(k, n, p);
            if(abs(newP - pVal) > abs(guessP - pVal)) {
                return k - 1;
            } else {
                guessP = newP;
            }
        }
        return n;
    } else {
        for(uint k = guess - 1; k != uint.max; k--) {
            double newP = guessP - binomialPMF(k + 1, n, p);
            if(abs(newP - pVal) > abs(guessP - pVal)) {
                return k + 1;
            } else {
                guessP = newP;
            }
        }
        return 0;
    }
}

unittest {
   Random gen = Random(unpredictableSeed);
   foreach(i; 0..1_000) {
       // Restricted variable ranges are because, in the tails, more than one
       // value of k can map to the same p-value at machine precision.
       // Obviously, this is one of those corner cases that nothing can be
       // done about.  Using small n's, moderate p's prevents this.
       uint n = uniform(5U, 10U);
       uint k = uniform(0U, n);
       double p = uniform(0.1L, 0.9L);
       double pVal = binomialCDF(k, n, p);
       assert(invBinomialCDF(pVal, n, p) == k);
   }
}

///
double hypergeometricPMF(long x, long n1, long n2, long n)
in {
    assert(x <= n);
} body {
    if(x > n1 || x < (n - n2)) {
        return 0;
    }
    double result = logNcomb(n1, x) + logNcomb(n2, n - x) - logNcomb(n1 + n2, n);
    return exp(result);
}

unittest {
    assert(approxEqual(hypergeometricPMF(5, 10, 10, 10), .3437182));
    assert(approxEqual(hypergeometricPMF(9, 12, 10, 15), .27089783));
    assert(approxEqual(hypergeometricPMF(9, 100, 100, 15), .15500003));
}

/**P(X <= x), where X is random variable.  Uses either direct summation,
 * normal or binomial approximation depending on parameters.*/
// If anyone knows a better algorithm for this, feel free...
// I've read a decent amount about it, though, and getting hypergeometric
// CDFs that are both accurate and fast is just plain hard.  This
// implementation attempts to strike a balance between the two, so that
// both speed and accuracy are "good enough" for most practical purposes.
double hypergeometricCDF(long x, long n1, long n2, long n) {
    dstatsEnforce(x <= n, "x must be <= n in hypergeometric distribution.");
    dstatsEnforce(n <= n1 + n2, "n must be <= n1 + n2 in hypergeometric distribution.");
    dstatsEnforce(x >= 0, "x must be >= 0 in hypergeometric distribution.");

    ulong expec = (n1 * n) / (n1 + n2);
    long nComp = n1 + n2 - n, xComp = n2 + x - n;

    // Try to reduce number of calculations using identities.
    if(x >= n1 || x == n) {
        return 1;
    } else if(x > expec && x > n / 2) {
        return 1 - hypergeometricCDF(n - x - 1, n2, n1, n);
    } else if(xComp < x && xComp > 0) {
        return hypergeometricCDF(xComp, n2, n1, nComp);
    }

    // Speed depends on x mostly, so always use exact for small x.
    if(x <= 100) {
        return hyperExact(x, n1, n2, n);
    }

    // Determine whether to use exact, normal approx or binomial approx.
    // Using obviously arbitrary but relatively stringent standards
    // for determining whether to approximate.
    enum NEXACT = 50L;

    double p = cast(double) n1 / (n1 + n2);
    double pComp = cast(double) n2 / (n1 + n2);
    double pMin = min(p, pComp);
    if(min(n, nComp) * pMin >= 100) {
        // Since high relative error in the lower tail is a significant problem,
        // this is a hack to improve the normal approximation:  Use the normal
        // approximation, except calculate the last NEXACT elements exactly,
        // since elements around the e.v. are where absolute error is highest.
        // For large x, gives most of the accuracy of an exact calculation in
        // only a small fraction of the time.
        if(x <= expec + NEXACT / 2) {
            return min(1, normApproxHyper(x - NEXACT, n1, n2, n) +
                hyperExact(x, n1, n2, n, x - NEXACT + 1));
        } else {
            // Just use plain old normal approx.  Since P is large, the
            // relative error won't be so bad anyhow.
            return normApproxHyper(x, n1, n2, n);
        }
    }
    // Try to make n as small as possible by applying mathematically equivalent
    // transformations so that binomial approx. works as well as possible.
    ulong bSc1 = (n1 + n2) / n, bSc2 = (n1 + n2) / n1;

    if(bSc1 >= 50 && bSc1 > bSc2) {
        // Same hack as normal approximation for rel. acc. in lower tail.
        if(x <= expec + NEXACT / 2) {
            return min(1, binomialCDF(cast(uint) (x - NEXACT), cast(uint) n, p) +
                hyperExact(x, n1, n2, n, x - NEXACT + 1));
        } else {
            return binomialCDF(cast(uint) x, cast(uint)  n, p);
        }
    } else if(bSc2 >= 50 && bSc2 > bSc1) {
        double p2 = cast(double) n / (n1 + n2);
        if(x <= expec + NEXACT / 2) {
            return min(1, binomialCDF(cast(uint) (x - NEXACT), cast(uint)  n1, p2) +
                hyperExact(x, n1, n2, n, x - NEXACT + 1));
        } else {
            return binomialCDF(cast(uint) x, cast(uint) n1, p2);
        }
    } else {
        return hyperExact(x, n1, n2, n);
    }
}

unittest {
    // Values from R and the Maxima CAS.
    // Test exact branch, including reversing, complementing.
    assert(approxEqual(hypergeometricCDF(5, 10, 10, 10), 0.6718591));
    assert(approxEqual(hypergeometricCDF(3, 11, 15, 10), 0.27745322));
    assert(approxEqual(hypergeometricCDF(18, 27, 31, 35), 0.88271714));
    assert(approxEqual(hypergeometricCDF(21, 29, 31, 35), 0.99229253));

    // Normal branch.
    assert(approxEqual(hypergeometricCDF(501, 2000, 1000, 800), 0.002767073));
    assert(approxEqual(hypergeometricCDF(565, 2000, 1000, 800), 0.9977068));
    assert(approxEqual(hypergeometricCDF(2700, 10000, 20000, 8000), 0.825652));

    // Binomial branch.  One for each transformation.
    assert(approxEqual(hypergeometricCDF(110, 5000, 7000, 239), 0.9255627));
    assert(approxEqual(hypergeometricCDF(19840, 2950998, 12624, 19933), 0.2020618));
    assert(approxEqual(hypergeometricCDF(130, 24195, 52354, 295), 0.9999973));
    assert(approxEqual(hypergeometricCDF(103, 901, 49014, 3522), 0.999999));
}

///P(X >= x), where X is random variable.
double hypergeometricCDFR(ulong x, ulong n1, ulong n2, ulong n) {
    dstatsEnforce(x <= n, "x must be <= n in hypergeometric distribution.");
    dstatsEnforce(n <= n1 + n2, "n must be <= n1 + n2 in hypergeometric distribution.");
    dstatsEnforce(x >= 0, "x must be >= 0 in hypergeometric distribution.");

    return hypergeometricCDF(n - x, n2, n1, n);
}

unittest {
    //Reverses n1, n2 and subtracts x from n to get mirror image.
    assert(approxEqual(hypergeometricCDF(5,10,10,10),
                       hypergeometricCDFR(5,10,10,10)));
    assert(approxEqual(hypergeometricCDF(3, 11, 15, 10),
                       hypergeometricCDFR(7, 15, 11, 10)));
    assert(approxEqual(hypergeometricCDF(18, 27, 31, 35),
                       hypergeometricCDFR(17, 31, 27, 35)));
    assert(approxEqual(hypergeometricCDF(21, 29, 31, 35),
                       hypergeometricCDFR(14, 31, 29, 35)));
}

double hyperExact(ulong x, ulong n1, ulong n2, ulong n, ulong startAt = 0) {
    dstatsEnforce(x <= n, "x must be <= n in hypergeometric distribution.");
    dstatsEnforce(n <= n1 + n2, "n must be <= n1 + n2 in hypergeometric distribution.");
    dstatsEnforce(x >= 0, "x must be >= 0 in hypergeometric distribution.");

    immutable double constPart = logFactorial(n1) + logFactorial(n2) +
        logFactorial(n) + logFactorial(n1 + n2 - n) - logFactorial(n1 + n2);
    double sum = 0;
    for(ulong i = x; i != startAt - 1; i--) {
        double oldSum = sum;
        sum += exp(constPart - logFactorial(i) - logFactorial(n1 - i) -
               logFactorial(n2 + i - n) - logFactorial(n - i));
        if(isIdentical(sum, oldSum)) { // At full machine precision.
            break;
        }
    }
    return sum;
}

double normApproxHyper(ulong x, ulong n1, ulong n2, ulong n) {
    double p1 = cast(double) n1 / (n1 + n2);
    double p2 = cast(double) n2 / (n1 + n2);
    double numer = x + 0.5L - n * p1;
    double denom = sqrt(n * p1 * p2 * (n1 + n2 - n) / (n1 + n2 - 1));
    return normalCDF(numer / denom);
}

// Aliases for old names.  Not documented because new names should be used.
deprecated {
    alias chiSquareCDF chiSqrCDF;
    alias chiSquareCDFR chiSqrCDFR;
    alias invChiSquareCDFR invChiSqCDFR;
}

///
double chiSquarePDF(double x, double v) {
    dstatsEnforce(x >= 0, "x must be >= 0 in chi-square distribution.");
    dstatsEnforce(v >= 1.0, "Must have at least 1 degree of freedom for chi-square.");

    // Calculate in log space for stability.
    immutable logX = log(x);
    immutable numerator = logX * (0.5 * v - 1) - 0.5 * x;
    immutable denominator = LN2 * (0.5 * v) + logGamma(0.5 * v);
    return exp(numerator - denominator);
}

unittest {
    assert( approxEqual(chiSquarePDF(1, 2), 0.3032653));
    assert( approxEqual(chiSquarePDF(2, 1), 0.1037769));
}

/**
 *  $(POWER &chi;,2) distribution function and its complement.
 *
 * Returns the area under the left hand tail (from 0 to x)
 * of the Chi square probability density function with
 * v degrees of freedom. The complement returns the area under
 * the right hand tail (from x to &infin;).
 *
 *  chiSquareCDF(x | v) = ($(INTEGRATE 0, x)
 *          $(POWER t, v/2-1) $(POWER e, -t/2) dt )
 *             / $(POWER 2, v/2) $(GAMMA)(v/2)
 *
 *  chiSquareCDFR(x | v) = ($(INTEGRATE x, &infin;)
 *          $(POWER t, v/2-1) $(POWER e, -t/2) dt )
 *             / $(POWER 2, v/2) $(GAMMA)(v/2)
 *
 * Params:
 *  v  = degrees of freedom. Must be positive.
 *  x  = the $(POWER &chi;,2) variable. Must be positive.
 *
 */
double chiSquareCDF(double x, double v) {
    dstatsEnforce(x >= 0, "x must be >= 0 in chi-square distribution.");
    dstatsEnforce(v >= 1.0, "Must have at least 1 degree of freedom for chi-square.");

    // These are very common special cases where we can make the calculation
    // a lot faster and/or more accurate.
    if(v == 1) {
        // Then it's the square of a normal(0, 1).
        return 1.0L - erfc(sqrt(x) * SQRT1_2);
    } else if(v == 2) {
        // Then it's an exponential w/ lambda == 1/2.
        return 1.0L - exp(-0.5 * x);
    } else {
        return gammaIncomplete(0.5 * v, 0.5 * x);
    }
}

///
double chiSquareCDFR(double x, double v) {
    dstatsEnforce(x >= 0, "x must be >= 0 in chi-square distribution.");
    dstatsEnforce(v >= 1.0, "Must have at least 1 degree of freedom for chi-square.");

    // These are very common special cases where we can make the calculation
    // a lot faster and/or more accurate.
    if(v == 1) {
        // Then it's the square of a normal(0, 1).
        return erfc(sqrt(x) * SQRT1_2);
    } else if(v == 2) {
        // Then it's an exponential w/ lambda == 1/2.
        return exp(-0.5 * x);
    } else {
        return gammaIncompleteCompl(0.5 * v, 0.5 * x);
    }
}

/**
 *  Inverse of complemented $(POWER &chi;, 2) distribution
 *
 * Finds the $(POWER &chi;, 2) argument x such that the integral
 * from x to &infin; of the $(POWER &chi;, 2) density is equal
 * to the given cumulative probability p.
 *
 * Params:
 * p = Cumulative probability. 0<= p <=1.
 * v = Degrees of freedom. Must be positive.
 *
 */
double invChiSquareCDFR(double v, double p) {
    dstatsEnforce(v >= 1.0, "Must have at least 1 degree of freedom for chi-square.");
    dstatsEnforce(p >= 0 && p <= 1, "P-values must be between 0, 1.");
    return  2.0 * gammaIncompleteComplInverse( 0.5*v, p);
}

unittest {
    assert(feqrel(chiSquareCDFR(invChiSquareCDFR(3.5, 0.1), 3.5), 0.1)>=double.mant_dig-3);
    assert(approxEqual(
        chiSquareCDF(0.4L, 19.02L) + chiSquareCDFR(0.4L, 19.02L), 1.0L));
    assert(ae( invChiSquareCDFR( 3, chiSquareCDFR(1, 3)), 1));

    assert(ae(chiSquareCDFR(0.2, 1), 0.6547208));
    assert(ae(chiSquareCDFR(0.2, 2), 0.9048374));
    assert(ae(chiSquareCDFR(0.8, 1), 0.3710934));
    assert(ae(chiSquareCDFR(0.8, 2), 0.67032));

    assert(ae(chiSquareCDF(0.2, 1), 0.3452792));
    assert(ae(chiSquareCDF(0.2, 2), 0.09516258));
    assert(ae(chiSquareCDF(0.8, 1), 0.6289066));
    assert(ae(chiSquareCDF(0.8, 2), 0.3296800));
}

///
double normalPDF(double x, double mean = 0, double sd = 1) {
    dstatsEnforce(sd > 0, "Standard deviation must be > 0 for normal distribution.");
    double dev = x - mean;
    return exp(-(dev * dev) / (2 * sd * sd)) / (sd * SQ2PI);
}

unittest {
    assert(approxEqual(normalPDF(3, 1, 2), 0.1209854));
}

///P(X < x) for normal distribution where X is random var.
double normalCDF(double x, double mean = 0, double stdev = 1) {
    dstatsEnforce(stdev > 0, "Standard deviation must be > 0 for normal distribution.");

    // Using a slightly non-obvious implementation in terms of erfc because
    // it seems more accurate than erf for very small values of Z.

    double Z = (-x + mean) / stdev;
    return erfc(Z*SQRT1_2)/2;
}

unittest {
    assert(approxEqual(normalCDF(2), .9772498));
    assert(approxEqual(normalCDF(-2), .02275013));
    assert(approxEqual(normalCDF(1.3), .90319951));
}

///P(X > x) for normal distribution where X is random var.
double normalCDFR(double x, double mean = 0, double stdev = 1) {
    dstatsEnforce(stdev > 0, "Standard deviation must be > 0 for normal distribution.");

    double Z = (x - mean) / stdev;
    return erfc(Z * SQRT1_2) / 2;
}

unittest {
    //Should be essentially a mirror image of normalCDF.
    for(double i = -8; i < 8; i += .1) {
        assert(approxEqual(normalCDF(i), normalCDFR(-i)));
    }
}

private enum SQRT2PI =   0x1.40d931ff62705966p+1;    // 2.5066282746310005024
private enum EXP_2  = 0.13533528323661269189L; /* exp(-2) */

/******************************
 * Inverse of Normal distribution function
 *
 * Returns the argument, x, for which the area under the
 * Normal probability density function (integrated from
 * minus infinity to x) is equal to p.
 */
double invNormalCDF(double p, double mean = 0, double sd = 1) {
    dstatsEnforce(p >= 0 && p <= 1, "P-values must be between 0, 1.");
    dstatsEnforce(sd > 0, "Standard deviation must be > 0 for normal distribution.");

    return normalDistributionInverse(p) * sd + mean;
}


unittest {
    // The values below are from Excel 2003.
    assert(fabs(invNormalCDF(0.001) - (-3.09023230616779))< 0.00000000000005);
    assert(fabs(invNormalCDF(1e-50) - (-14.9333375347885))< 0.00000000000005);
    assert(feqrel(invNormalCDF(0.999), -invNormalCDF(0.001))>double.mant_dig-6);

    // Excel 2003 gets all the following values wrong!
    assert(invNormalCDF(0.0)==-double.infinity);
    assert(invNormalCDF(1.0)==double.infinity);
    assert(invNormalCDF(0.5)==0);

    // I don't know the correct result for low values
    // (Excel 2003 returns norminv(p) = -30 for all p < 1e-200).
    // The value tested here is the one the function returned in Jan 2006.
    double unknown1 = invNormalCDF(1e-250L);
    assert( fabs(unknown1 -(-33.79958617269L) ) < 0.00000005);

    Random gen;
    gen.seed(unpredictableSeed);
    // normalCDF function trivial given ERF, unlikely to contain subtle bugs.
    // Just make sure invNormalCDF works like it should as the inverse.
    foreach(i; 0..1000) {
        double x = uniform(0.0L, 1.0L);
        double mean = uniform(0.0L, 100.0L);
        double sd = uniform(1.0L, 3.0L);
        double inv = invNormalCDF(x, mean, sd);
        double rec = normalCDF(inv, mean, sd);
        assert(approxEqual(x, rec));
    }
}

///
double logNormalPDF(double x, double mu = 0, double sigma = 1) {
    dstatsEnforce(sigma > 0, "sigma must be > 0 for log-normal distribution.");

    immutable mulTerm = 1.0L / (x * sigma * SQ2PI);
    double expTerm = log(x) - mu;
    expTerm *= expTerm;
    expTerm /= 2 * sigma * sigma;
    return mulTerm * exp(-expTerm);
}

unittest {
    // Values from R.
    assert(approxEqual(logNormalPDF(1, 0, 1), 0.3989423));
    assert(approxEqual(logNormalPDF(2, 2, 3), 0.06047173));
}

///
double logNormalCDF(double x, double mu = 0, double sigma = 1) {
    dstatsEnforce(sigma > 0, "sigma must be > 0 for log-normal distribution.");

    return 0.5L + 0.5L * erf((log(x) - mu) / (sigma * SQRT2));
}

unittest {
    assert(approxEqual(logNormalCDF(4), 0.9171715));
    assert(approxEqual(logNormalCDF(1, -2, 3), 0.7475075));
}

///
double logNormalCDFR(double x, double mu = 0, double sigma = 1) {
    dstatsEnforce(sigma > 0, "sigma must be > 0 for log-normal distribution.");

    return 0.5L - 0.5L * erf((log(x) - mu) / (sigma * SQRT2));
}

unittest {
    assert(approxEqual(logNormalCDF(4) + logNormalCDFR(4), 1));
    assert(approxEqual(logNormalCDF(1, -2, 3) + logNormalCDFR(1, -2, 3), 1));
}

///
double weibullPDF(double x, double shape, double scale = 1) {
    dstatsEnforce(shape > 0, "shape must be > 0 for weibull distribution.");
    dstatsEnforce(scale > 0, "scale must be > 0 for weibull distribution.");

    if(x < 0) {
        return 0;
    }
    double ret = pow(x / scale, shape - 1) * exp( -pow(x / scale, shape));
    return ret * (shape / scale);
}

unittest {
    assert(approxEqual(weibullPDF(2,1,3), 0.1711390));
}

///
double weibullCDF(double x, double shape, double scale = 1) {
    dstatsEnforce(shape > 0, "shape must be > 0 for weibull distribution.");
    dstatsEnforce(scale > 0, "scale must be > 0 for weibull distribution.");

    double exponent = pow(x / scale, shape);
    return 1 - exp(-exponent);
}

unittest {
    assert(approxEqual(weibullCDF(2, 3, 4), 0.1175031));
}

///
double weibullCDFR(double x, double shape, double scale = 1) {
    dstatsEnforce(shape > 0, "shape must be > 0 for weibull distribution.");
    dstatsEnforce(scale > 0, "scale must be > 0 for weibull distribution.");

    double exponent = pow(x / scale, shape);
    return exp(-exponent);
}

unittest {
    assert(approxEqual(weibullCDF(2, 3, 4) + weibullCDFR(2, 3, 4), 1));
}

// For K-S tests in dstats.random.  Todo:  Flesh out.
double waldCDF(double x, double mu, double lambda) {
    double sqr = sqrt(lambda / (2 * x));
    double term1 = 1 + erf(sqr * (x / mu - 1));
    double term2 = exp(2 * lambda / mu);
    double term3 = 1 - erf(sqr * (x / mu + 1));
    return 0.5L * term1 + 0.5L * term2 * term3;
}

// ditto.
double rayleighCDF(double x, double mode) {
    return 1.0L - exp(-x * x / (2 * mode * mode));
}

///
double studentsTPDF(double t, double df) {
    dstatsEnforce(df > 0, "Student's T must have >0 degrees of freedom.");

    immutable logPart = logGamma(0.5 * df + 0.5) - logGamma(0.5 * df);
    immutable term1 = exp(logPart) / sqrt(df * PI);
    immutable term2 = (1.0 + t / df * t) ^^ (-0.5 * df - 0.5);
    return term1 * term2;
}

///
double studentsTCDF(double t, double df) {
    dstatsEnforce(df > 0, "Student's T must have >0 degrees of freedom.");

    double x = (t + sqrt(t * t + df)) / (2 * sqrt(t * t + df));
    return betaIncomplete(df * 0.5L, df * 0.5L, x);
}

///
double studentsTCDFR(double t, double df)   {
    return studentsTCDF(-t, df);
}

unittest {
    assert(approxEqual(studentsTPDF(1, 1), 0.1591549));
    assert(approxEqual(studentsTPDF(3, 10), 0.0114055));
    assert(approxEqual(studentsTPDF(-4, 5), 0.005123727));

    assert(approxEqual(studentsTCDF(1, 1), 0.75));
    assert(approxEqual(studentsTCDF(1.061, 2), 0.8));
    assert(approxEqual(studentsTCDF(5.959, 5), 0.9995));
    assert(approxEqual(studentsTCDF(.667, 20), 0.75));
    assert(approxEqual(studentsTCDF(2.353, 3), 0.95));
}

/******************************************
*   Inverse of Student's t distribution
*
* Given probability p and degrees of freedom df,
* finds the argument t such that the one-sided
* studentsDistribution(nu,t) is equal to p.
* Used to test whether two distributions have the same
* standard deviation.
*
* Params:
* df = degrees of freedom. Must be >1
* p  = probability. 0 < p < 1
*/
double invStudentsTCDF(double p, double df) {
    dstatsEnforce(p >= 0 && p <= 1, "P-values must be between 0, 1.");
    dstatsEnforce(df > 0, "Student's T must have >0 degrees of freedom.");

    if (p==0) return -double.infinity;
    if (p==1) return double.infinity;

    double rk, z;
    rk =  df;

    if ( p > 0.25L && p < 0.75L ) {
        if ( p == 0.5L ) return 0;
        z = 1.0L - 2.0L * p;
        z = betaIncompleteInverse( 0.5L, 0.5L*rk, fabs(z) );
        double t = sqrt( rk*z/(1.0L-z) );
        if( p < 0.5L )
            t = -t;
        return t;
    }
    int rflg = -1; // sign of the result
    if (p >= 0.5L) {
        p = 1.0L - p;
        rflg = 1;
    }
    z = betaIncompleteInverse( 0.5L*rk, 0.5L, 2.0L*p );

    if (z<0) return rflg * double.infinity;
    return rflg * sqrt( rk/z - rk );
}

unittest {
    // The remaining values listed here are from Excel, and are unlikely to be accurate
    // in the last decimal places. However, they are helpful as a sanity check.

    //  Microsoft Excel 2003 gives TINV(2*(1-0.995), 10) == 3.16927267160917
    assert(approxEqual(invStudentsTCDF(0.995, 10), 3.169_272_67L));
    assert(approxEqual(invStudentsTCDF(0.6, 8), 0.261_921_096_769_043L));
    assert(approxEqual(invStudentsTCDF(0.4, 18), -0.257_123_042_655_869L));
    assert(approxEqual(studentsTCDF(invStudentsTCDF(0.4L, 18), 18), .4L));
    assert(approxEqual(studentsTCDF( invStudentsTCDF(0.9L, 11), 11), 0.9L));
}

/**
 * The Fisher distribution, its complement, and inverse.
 *
 * The F density function (also known as Snedcor's density or the
 * variance ratio density) is the density
 * of x = (u1/df1)/(u2/df2), where u1 and u2 are random
 * variables having $(POWER &chi;,2) distributions with df1
 * and df2 degrees of freedom, respectively.
 *
 * fisherCDF returns the area from zero to x under the F density
 * function.   The complementary function,
 * fisherCDFR, returns the area from x to &infin; under the F density function.
 *
 * The inverse of the complemented Fisher distribution,
 * invFisherCDFR, finds the argument x such that the integral
 * from x to infinity of the F density is equal to the given probability y.

 * Params:
 *  df1 = Degrees of freedom of the first variable. Must be >= 1
 *  df2 = Degrees of freedom of the second variable. Must be >= 1
 *  x  = Must be >= 0
 */
double fisherCDF(double x, double df1, double df2) {
    dstatsEnforce(df1 > 0 && df2 > 0,
        "Fisher distribution must have >0 degrees of freedom.");
    dstatsEnforce(x >= 0, "x must be >=0 for Fisher distribution.");

    double a = cast(double)(df1);
    double b = cast(double)(df2);
    double w = a * x;
    w = w/(b + w);
    return betaIncomplete(0.5L*a, 0.5L*b, w);
}

/** ditto */
double fisherCDFR(double x, double df1, double df2) {
    dstatsEnforce(df1 > 0 && df2 > 0,
        "Fisher distribution must have >0 degrees of freedom.");
    dstatsEnforce(x >= 0, "x must be >=0 for Fisher distribution.");

    double a = cast(double)(df1);
    double b = cast(double)(df2);
    double w = b / (b + a * x);
    return betaIncomplete( 0.5L*b, 0.5L*a, w );
}

/**
 * Inverse of complemented Fisher distribution
 *
 * Finds the F density argument x such that the integral
 * from x to infinity of the F density is equal to the
 * given probability p.
 *
 * This is accomplished using the inverse beta integral
 * function and the relations
 *
 *      z = betaIncompleteInverse( df2/2, df1/2, p ),
 *      x = df2 (1-z) / (df1 z).
 *
 * Note that the following relations hold for the inverse of
 * the uncomplemented F distribution:
 *
 *      z = betaIncompleteInverse( df1/2, df2/2, p ),
 *      x = df2 z / (df1 (1-z)).
*/
double invFisherCDFR(double df1, double df2, double p ) {
    dstatsEnforce(df1 > 0 && df2 > 0,
        "Fisher distribution must have >0 degrees of freedom.");
    dstatsEnforce(p >= 0 && p <= 1, "P-values must be between 0, 1.");

    double a = df1;
    double b = df2;
    /* Compute probability for x = 0.5.  */
    double w = betaIncomplete( 0.5L*b, 0.5L*a, 0.5L );
    /* If that is greater than p, then the solution w < .5.
       Otherwise, solve at 1-p to remove cancellation in (b - b*w).  */
    if ( w > p || p < 0.001L) {
        w = betaIncompleteInverse( 0.5L*b, 0.5L*a, p );
        return (b - b*w)/(a*w);
    } else {
        w = betaIncompleteInverse( 0.5L*a, 0.5L*b, 1.0L - p );
        return b*w/(a*(1.0L-w));
    }
}

unittest {
    // fDistCompl(df1, df2, x) = Excel's FDIST(x, df1, df2)
      assert(fabs(fisherCDFR(16.5, 6, 4) - 0.00858719177897249L)< 0.0000000000005L);
      assert(fabs((1-fisherCDF(0.1, 12, 23)) - 0.99990562845505L)< 0.0000000000005L);
      assert(fabs(invFisherCDFR(8, 34, 0.2) - 1.48267037661408L)< 0.0000000005L);
      assert(fabs(invFisherCDFR(4, 16, 0.008) - 5.043_537_593_48596L)< 0.0000000005L);
      // This one used to fail because of a bug in the definition of MINLOG.
      assert(approxEqual(fisherCDFR(invFisherCDFR(4,16, 0.008), 4, 16), 0.008));
}

///
double negBinomPMF(ulong k, ulong n, double p) {
    dstatsEnforce(p >= 0 && p <= 1,
        "p must be between 0, 1 for negative binomial distribution.");

    return exp(logNcomb(k - 1 + n, k) +  n * log(p) + k * log(1 - p));
}

unittest {
    // Values from R.
    assert(approxEqual(negBinomPMF(1, 8, 0.7), 0.1383552));
    assert(approxEqual(negBinomPMF(3, 2, 0.5), 0.125));
}


/**********************
 * Negative binomial distribution.
 *
 * Returns the sum of the terms 0 through k of the negative
 * binomial distribution:
 *
 * $(BIGSUM j=0, k) $(CHOOSE n+j-1, j) $(POWER p, n) $(POWER (1-p), j)
 * ???? In mathworld, it is
 * $(BIGSUM j=0, k) $(CHOOSE n+j-1, j-1) $(POWER p, j) $(POWER (1-p), n)
 *
 * In a sequence of Bernoulli trials, this is the probability
 * that k or fewer failures precede the n-th success.
 *
 * The arguments must be positive, with 0 < p < 1 and r>0.
 *
 * The Geometric Distribution is a special case of the negative binomial
 * distribution.
 * -----------------------
 * geometricDistribution(k, p) = negativeBinomialDistribution(k, 1, p);
 * -----------------------
 * References:
 * $(LINK http://mathworld.wolfram.com/NegativeBinomialDistribution.html)
 */
double negBinomCDF(ulong k, ulong n, double p ) {
    dstatsEnforce(p >= 0 && p <= 1,
        "p must be between 0, 1 for negative binomial distribution.");
    if ( k == 0 ) return pow(p, cast(double) n);
    return  betaIncomplete( n, k + 1, p );
}

unittest {
    // Values from R.
    assert(approxEqual(negBinomCDF(50, 50, 0.5), 0.5397946));
    assert(approxEqual(negBinomCDF(2, 1, 0.5), 0.875));
}

/**Probability that k or more failures precede the nth success.*/
double negBinomCDFR(ulong k, ulong n, double p) {
    dstatsEnforce(p >= 0 && p <= 1,
        "p must be between 0, 1 for negative binomial distribution.");

    if(k == 0)
        return 1;
    return betaIncomplete(k, n, 1.0L - p);
}

unittest {
    assert(approxEqual(negBinomCDFR(10, 20, 0.5), 1 - negBinomCDF(9, 20, 0.5)));
}

///
ulong invNegBinomCDF(double pVal, ulong n, double p) {
    dstatsEnforce(p >= 0 && p <= 1,
        "p must be between 0, 1 for negative binomial distribution.");
    dstatsEnforce(pVal >= 0 && pVal <= 1,
        "P-values must be between 0, 1.");

    // Normal or gamma approx, then adjust.
    double mean = n * (1 - p) / p;
    double var = n * (1 - p) / (p * p);
    double skew = (2 - p) / sqrt(n * (1 - p));
    double kk = 4.0L / (skew * skew);
    double theta = sqrt(var / kk);
    double offset = (kk * theta) - mean + 0.5L;
    ulong guess;

    // invGammaCDFR is very expensive, but worth it in cases where normal approx
    // would be the worst.  Otherwise, use normal b/c it's *MUCH* cheaper to
    // calculate.
    if(skew > 1.5 && var > 1_048_576)
        guess = cast(long) max(round(
         invGammaCDFR(1 - pVal, 1 / theta, kk) - offset), 0.0L);
    else
        guess = cast(long) max(round(
           invNormalCDF(pVal, mean, sqrt(var)) + 0.5), 0.0L);

    // This is pretty arbitrary behavior, but I don't want to use exceptions
    // and it has to be handled as a special case.
    if(pVal > 1 - double.epsilon)
        return ulong.max;
    double guessP = negBinomCDF(guess, n, p);

    if(guessP == pVal) {
        return guess;
    } else if(guessP < pVal) {
        for(ulong k = guess + 1; ; k++) {
            double newP = guessP + negBinomPMF(k, n, p);
            // Test for aliasing.
            if(newP == guessP)
                return k - 1;
            if(abs(pVal - newP) > abs(guessP - pVal)) {
                return k - 1;
            } else if(newP >= 1) {
                return k;
            } else {
                guessP = newP;
            }
        }
    } else {
        for(ulong k = guess - 1; guess != ulong.max; k--) {
            double newP = guessP - negBinomPMF(k + 1, n, p);
            // Test for aliasing.
            if(newP == guessP)
                return k + 1;
            if(abs(newP - pVal) > abs(guessP - pVal)) {
                return k + 1;
            } else {
                guessP = newP;
            }
        }
        return 0;
    }
}

unittest {
    Random gen = Random(unpredictableSeed);
    uint nSkipped;
    foreach(i; 0..1000) {
        uint n = uniform(1u, 10u);
        double p = uniform(0.0L, 1L);
        uint k = uniform(0, 20);
        double pVal = negBinomCDF(k, n, p);

        // In extreme tails, p-values can alias, giving incorrect results.
        // This is a corner case that nothing can be done about.  Just skip
        // these.
        if(pVal >= 1 - 10 * double.epsilon) {
            nSkipped++;
            continue;
        }
        assert(invNegBinomCDF(pVal, n, p) == k);
    }
}

///
double exponentialPDF(double x, double lambda) {
    dstatsEnforce(x >= 0, "x must be >0 in exponential distribution");
    dstatsEnforce(lambda > 0, "lambda must be >0 in exponential distribution");

    return lambda * exp(-lambda * x);
}

///
double exponentialCDF(double x, double lambda) {
    dstatsEnforce(x >= 0, "x must be >0 in exponential distribution");
    dstatsEnforce(lambda > 0, "lambda must be >0 in exponential distribution");

    return 1.0 - exp(-lambda * x);
}

///
double exponentialCDFR(double x, double lambda) {
    dstatsEnforce(x >= 0, "x must be >0 in exponential distribution");
    dstatsEnforce(lambda > 0, "lambda must be >0 in exponential distribution");

    return exp(-lambda * x);
}

///
double invExponentialCDF(double p, double lambda) {
    dstatsEnforce(p >= 0 && p <= 1, "p must be between 0, 1 in exponential distribution");
    dstatsEnforce(lambda > 0, "lambda must be >0 in exponential distribution");
    return log(-1.0 / (p - 1.0)) / lambda;
}

unittest {
    // Values from R.
    assert(approxEqual(exponentialPDF(0.75, 3), 0.3161977));
    assert(approxEqual(exponentialCDF(0.75, 3), 0.8946008));
    assert(approxEqual(exponentialCDFR(0.75, 3), 0.1053992));

    assert(approxEqual(invExponentialCDF(0.8, 2), 0.804719));
    assert(approxEqual(invExponentialCDF(0.2, 7), 0.03187765));
}

///
double gammaPDF(double x, double rate, double shape) {
    dstatsEnforce(x > 0, "x must be >0 in gamma distribution.");
    dstatsEnforce(rate > 0, "rate must be >0 in gamma distribution.");
    dstatsEnforce(shape > 0, "shape must be >0 in gamma distribution.");

    immutable scale = 1.0 / rate;
    immutable firstPart = x ^^ (shape - 1);
    immutable logNumer = -x / scale;
    immutable logDenom = logGamma(shape) + shape * log(scale);
    return firstPart * exp(logNumer - logDenom);
}

///
double gammaCDF(double x, double rate, double shape) {
    dstatsEnforce(x > 0, "x must be >0 in gamma distribution.");
    dstatsEnforce(rate > 0, "rate must be >0 in gamma distribution.");
    dstatsEnforce(shape > 0, "shape must be >0 in gamma distribution.");

    return gammaIncomplete(shape, rate * x);
}

///
double gammaCDFR(double x, double rate, double shape) {
    dstatsEnforce(x > 0, "x must be >0 in gamma distribution.");
    dstatsEnforce(rate > 0, "rate must be >0 in gamma distribution.");
    dstatsEnforce(shape > 0, "shape must be >0 in gamma distribution.");

    return gammaIncompleteCompl(shape, rate * x);
}

/**This just calls invGammaCDFR w/ 1 - p b/c invGammaCDFR is more accurate,
 * but this function is necessary for consistency.
 */
double invGammaCDF(double p, double rate, double shape) {
    return invGammaCDFR(1.0 - p, rate, shape);
}

///
double invGammaCDFR(double p, double rate, double shape) {
    dstatsEnforce(p >= 0 && p <= 1, "p must be between 0, 1 in gamma distribution.");
    dstatsEnforce(rate > 0, "rate must be >0 in gamma distribution.");
    dstatsEnforce(shape > 0, "shape must be >0 in gamma distribution.");

    double ratex = gammaIncompleteComplInverse(shape, p);
    return ratex / rate;
}

unittest {
    assert(approxEqual(gammaPDF(1, 2, 5), 0.1804470));
    assert(approxEqual(gammaPDF(0.5, 8, 4), 1.562935));
    assert(approxEqual(gammaPDF(3, 2, 7), 0.3212463));
    assert(approxEqual(gammaCDF(1, 2, 5), 0.05265302));
    assert(approxEqual(gammaCDFR(1, 2, 5), 0.947347));

    double inv = invGammaCDFR(0.78, 2, 1);
    assert(approxEqual(gammaCDFR(inv, 2, 1), 0.78));

    double inv2 = invGammaCDF(0.78, 2, 1);
    assert(approxEqual(gammaCDF(inv2, 2, 1), 0.78));
}

///
double betaPDF(double x, double alpha, double beta) {
    dstatsEnforce(alpha > 0, "Alpha must be >0 for beta distribution.");
    dstatsEnforce(beta > 0, "Beta must be >0 for beta distribution.");
    dstatsEnforce(x >= 0 && x <= 1, "x must be between 0, 1 for beta distribution.");

    return x ^^ (alpha - 1) * (1 - x) ^^ (beta - 1) /
        std.mathspecial.beta(alpha, beta);
}

///
double betaCDF(double x, double alpha, double beta) {
    dstatsEnforce(alpha > 0, "Alpha must be >0 for beta distribution.");
    dstatsEnforce(beta > 0, "Beta must be >0 for beta distribution.");
    dstatsEnforce(x >= 0 && x <= 1, "x must be between 0, 1 for beta distribution.");

    return std.mathspecial.betaIncomplete(alpha, beta, x);
}

///
double betaCDFR(double x, double alpha, double beta) {
    dstatsEnforce(alpha > 0, "Alpha must be >0 for beta distribution.");
    dstatsEnforce(beta > 0, "Beta must be >0 for beta distribution.");
    dstatsEnforce(x >= 0 && x <= 1, "x must be between 0, 1 for beta distribution.");

    return std.mathspecial.betaIncomplete(beta, alpha, 1 - x);
}

///
double invBetaCDF(double p, double alpha, double beta) {
    dstatsEnforce(alpha > 0, "Alpha must be >0 for beta distribution.");
    dstatsEnforce(beta > 0, "Beta must be >0 for beta distribution.");
    dstatsEnforce(p >= 0 && p <= 1, "p must be between 0, 1 for beta distribution.");

    return std.mathspecial.betaIncompleteInverse(alpha, beta, p);
}

unittest {
    // Values from R.
    assert(approxEqual(betaPDF(0.3, 2, 3), 1.764));
    assert(approxEqual(betaPDF(0.78, 0.9, 4), 0.03518569));

    assert(approxEqual(betaCDF(0.3, 2, 3), 0.3483));
    assert(approxEqual(betaCDF(0.78, 0.9, 4), 0.9980752));

    assert(approxEqual(betaCDFR(0.3, 2, 3), 0.6517));
    assert(approxEqual(betaCDFR(0.78, 0.9, 4), 0.001924818));

    assert(approxEqual(invBetaCDF(0.3483, 2, 3), 0.3));
    assert(approxEqual(invBetaCDF(0.9980752, 0.9, 4), 0.78));
}

/**
The Dirichlet probability density.

Params:

x = An input range of observed values.  All must be between [0, 1].  They
must also sum to 1, though this is not checked because small deviations from
this may result due to numerical error.

alpha = A forward range of parameters.  This must have the same length as
x.
*/
double dirichletPDF(X, A)(X x, A alpha)
if(isInputRange!X && isForwardRange!A && is(ElementType!X : double) &&
is(ElementType!A : double)) {

    // Evaluating the multinomial beta function = product(gamma(alpha_1)) over
    // gamma(sum(alpha)), in log space.
    double logNormalizer = 0;
    double sumAlpha = 0;

    foreach(a; alpha.save) {
        dstatsEnforce(a > 0, "All alpha values must be > 0 for Dirichlet distribution.");
        logNormalizer += logGamma(a);
        sumAlpha += a;
    }

    logNormalizer -= logGamma(sumAlpha);
    double sum = 0;
    foreach(xElem, a; lockstep(x, alpha)) {
        dstatsEnforce(xElem > 0, "All x values must be > 0 for Dirichlet distribution.");
        sum += log(xElem) * (a - 1);
    }

    sum -= logNormalizer;
    return exp(sum);
}

unittest {
    // Test against beta
    assert(approxEqual(dirichletPDF([0.1, 0.9], [2, 3]), betaPDF(0.1, 2, 3)));

    // A few values from R's gregmisc package
    assert(approxEqual(dirichletPDF([0.1, 0.2, 0.7], [4, 5, 6]), 1.356672));
    assert(approxEqual(dirichletPDF([0.8, 0.05, 0.15], [8, 5, 6]), 0.04390199));
}

///
double cauchyPDF(double X, double X0 = 0, double gamma = 1) {
    dstatsEnforce(gamma > 0, "gamma must be > 0 for Cauchy distribution.");

    double toSquare = (X - X0) / gamma;
    return 1.0L / (
        PI * gamma * (1 + toSquare * toSquare));
}

unittest {
    assert(approxEqual(cauchyPDF(5), 0.01224269));
    assert(approxEqual(cauchyPDF(2), 0.06366198));
}


///
double cauchyCDF(double X, double X0 = 0, double gamma = 1) {
    dstatsEnforce(gamma > 0, "gamma must be > 0 for Cauchy distribution.");

    return M_1_PI * atan((X - X0) / gamma) + 0.5L;
}

unittest {
    // Values from R
    assert(approxEqual(cauchyCDF(-10), 0.03172552));
    assert(approxEqual(cauchyCDF(1), 0.75));
}

///
double cauchyCDFR(double X, double X0 = 0, double gamma = 1) {
    dstatsEnforce(gamma > 0, "gamma must be > 0 for Cauchy distribution.");

    return M_1_PI * atan((X0 - X) / gamma) + 0.5L;
}

unittest {
    // Values from R
    assert(approxEqual(1 - cauchyCDFR(-10), 0.03172552));
    assert(approxEqual(1 - cauchyCDFR(1), 0.75));
}

///
double invCauchyCDF(double p, double X0 = 0, double gamma = 1) {
    dstatsEnforce(gamma > 0, "gamma must be > 0 for Cauchy distribution.");
    dstatsEnforce(p >= 0 && p <= 1, "P-values must be between 0, 1.");

    return X0 + gamma * tan(PI * (p - 0.5L));
}

unittest {
    // cauchyCDF already tested.  Just make sure this is the inverse.
    assert(approxEqual(invCauchyCDF(cauchyCDF(.5)), .5));
    assert(approxEqual(invCauchyCDF(cauchyCDF(.99)), .99));
    assert(approxEqual(invCauchyCDF(cauchyCDF(.03)), .03));
}

// For K-S tests in dstats.random.  To be fleshed out later.  Intentionally
// lacking ddoc.
double logisticCDF(double x, double loc, double shape) {
    return 1.0L / (1 + exp(-(x - loc) / shape));
}

///
double laplacePDF(double x, double mu = 0, double b = 1) {
    dstatsEnforce(b > 0, "b must be > 0 for laplace distribution.");

    return (exp(-abs(x - mu) / b)) / (2 * b);
}

unittest {
    // Values from Maxima.
    assert(approxEqual(laplacePDF(3, 2, 1), 0.18393972058572));
    assert(approxEqual(laplacePDF(-8, 6, 7), 0.0096668059454723));
}

///
double laplaceCDF(double X, double mu = 0, double b = 1) {
    dstatsEnforce(b > 0, "b must be > 0 for laplace distribution.");

    double diff = (X - mu);
    double sign = (diff > 0) ? 1 : -1;
    return 0.5L *(1 + sign * (1 - exp(-abs(diff) / b)));
}

unittest {
    // Values from Octave.
    assert(approxEqual(laplaceCDF(5), 0.9963));
    assert(approxEqual(laplaceCDF(-3.14), .021641));
    assert(approxEqual(laplaceCDF(0.012), 0.50596));
}

///
double laplaceCDFR(double X, double mu = 0, double b = 1) {
    dstatsEnforce(b > 0, "b must be > 0 for laplace distribution.");

    double diff = (mu - X);
    double sign = (diff > 0) ? 1 : -1;
    return 0.5L *(1 + sign * (1 - exp(-abs(diff) / b)));
}

unittest {
    // Values from Octave.
    assert(approxEqual(1 - laplaceCDFR(5), 0.9963));
    assert(approxEqual(1 - laplaceCDFR(-3.14), .021641));
    assert(approxEqual(1 - laplaceCDFR(0.012), 0.50596));
}

///
double invLaplaceCDF(double p, double mu = 0, double b = 1) {
    dstatsEnforce(p >= 0 && p <= 1, "P-values must be between 0, 1.");
    dstatsEnforce(b > 0, "b must be > 0 for laplace distribution.");

    double p05 = p - 0.5L;
    double sign = (p05 < 0) ? -1.0L : 1.0L;
    return mu - b * sign * log(1.0L - 2 * abs(p05));
}

unittest {
    assert(approxEqual(invLaplaceCDF(0.012), -3.7297));
    assert(approxEqual(invLaplaceCDF(0.82), 1.0217));
}

double kolmDist()(double x) {
    pragma(msg, "kolmDist is scheduled for deprecation.  Please use " ~
        "kolmogorovDistrib instead.");

    return kolmogorovDistrib(x);
}

/**Kolmogorov distribution.  Used in Kolmogorov-Smirnov testing.
 *
 * References: http://en.wikipedia.org/wiki/Kolmogorov-Smirnov
 */
double kolmogorovDistrib(immutable double x) {
    dstatsEnforce(x >= 0, "x must be >= 0 for Kolmogorov distribution.");

    if(x == 0) {
        //Handle as a special case.  Otherwise, get NAN b/c of divide by zero.
        return 0;
    }

    double result = 0;
    double i = 1;
    immutable xSquared = x * x;
    while(true) {
        immutable delta = exp(-(2 * i - 1) * (2 * i - 1) * PI * PI  / (8 * xSquared));
        i++;

        immutable oldResult = result;
        result += delta;
        if(isNaN(result) || oldResult == result) {
            break;
        }
    }
    result *= (sqrt(2 * PI) / x);
    return result;
}

unittest {
    assert(approxEqual(1 - kolmogorovDistrib(.75), 0.627167));
    assert(approxEqual(1 - kolmogorovDistrib(.5), 0.9639452436));
    assert(approxEqual(1 - kolmogorovDistrib(.9), 0.39273070));
    assert(approxEqual(1 - kolmogorovDistrib(1.2), 0.112249666));
}
