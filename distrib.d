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

import dstats.base, std.algorithm;

enum SQ2PI = sqrt(2 * PI);

version(unittest) {
    import std.stdio, std.random;

    void main(){
    }
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
real delegate(ParameterTypeTuple!(distrib)[0])
              parametrize(alias distrib)(ParameterTypeTuple!(distrib)[1..$]
              parameters) {

    real calculate(ParameterTypeTuple!(distrib)[0] arg) {
        return distrib(arg, parameters);
    }

    return &calculate;
}

unittest {
    // Just basically see if this compiles.
    auto stdNormal = parametrize!normalCDF(0, 1);
    assert(stdNormal(2.5) == normalCDF(2.5, 0, 1));
}

///
struct ParamFunctor(alias distrib) {
    ParameterTypeTuple!(distrib)[1..$] parameters;

    real opCall(ParameterTypeTuple!(distrib)[0] arg) {
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
    assert(stdNormal(2.5) == normalCDF(2.5, 0, 1));
}

///
real uniformCDF(real X, real lower, real upper) pure nothrow
in {
    assert(X >= lower);
    assert(X <= upper);
} body {
    return (X - lower) / (upper - lower);
}

///
real uniformCDFR(real X, real lower, real upper) pure nothrow
in {
    assert(X >= lower);
    assert(X <= upper);
} body {
    return (upper - X) / (upper - lower);
}

///
real poissonPMF(uint k, real lambda) {
    return exp(cast(real) k * log(lambda) -
            (lambda + logFactorial(k)));  //Grouped for best precision.
}

unittest {
    assert(approxEqual(poissonPMF(1, .1), .0904837));
    writefln("Passed poissonPMF test.");
}

/**P(K <= k) where K is r.v.*/
real poissonCDF(uint k, real lambda) {
    return gammaIncompleteCompl(k + 1, lambda);
}

unittest {
    // Make sure this jives with adding up PMF elements, since this is a
    // discrete distribution.
    static real pmfSum(uint k, real lambda) {
        real ret = 0;
        foreach(i; 0..k + 1) {
            ret += poissonPMF(i, lambda);
        }
        return ret;
    }

    assert(approxEqual(poissonCDF(1, 0.5), pmfSum(1, 0.5)));
    assert(approxEqual(poissonCDF(3, 0.7), pmfSum(3, 0.7)));
    writeln("Passed poissonCDF test.");
}

/**P(K >= k) where K is r.v.*/
real poissonCDFR(uint k, real lambda) {
    return gammaIncomplete(k, lambda);
}

unittest {
    // Make sure this jives with adding up PMF elements, since this is a
    // discrete distribution.
    static real pmfSum(uint k, real lambda) {
        real ret = 0;
        foreach(i; 0..k + 1)  {
            ret += poissonPMF(i, lambda);
        }
        return ret;
    }

    assert(approxEqual(poissonCDFR(1, 0.5), 1 - pmfSum(0, 0.5)));
    assert(approxEqual(poissonCDFR(3, 0.7), 1 - pmfSum(2, 0.7)));
    writeln("Passed poissonCDFR test.");
}

/**Returns the value of k for the given p-value and lambda.  If p-val
 * doesn't exactly map to a value of k, the k for which poissonCDF(k, lambda)
 * is closest to pVal is used.*/
uint invPoissonCDF(real pVal, real lambda)
in {
    assert(lambda > 0);
    assert(pVal >= 0 && pVal <= 1);
} body {
    // Use normal approximation to get approx answer, then brute force search.
    // This works better than you think because for small n, there's not much
    // search space and for large n, the normal approx. is really good.
    uint guess = cast(uint) max(round(
          invNormalCDF(pVal, lambda, sqrt(lambda)) + 0.5), 0.0L);
    real guessP = poissonCDF(guess, lambda);

    if(guessP == pVal) {
        return guess;
    } else if(guessP < pVal) {
        for(uint k = guess + 1; ; k++) {
            real newP = guessP + poissonPMF(k, lambda);
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
            real newP = guessP - poissonPMF(k + 1, lambda);
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
       real lambda = uniform(.05L, 8.0L);
       uint k = uniform(0U, cast(uint) ceil(3.0L * lambda));
       real pVal = poissonCDF(k, lambda);
       assert(invPoissonCDF(pVal, lambda) == k);
   }
   writeln("Passed invPoissonCDF unittest.");
}

///
real binomialPMF(uint k, uint n, real p)
in {
    assert(k <= n);
    assert(p >= 0 && p <= 1);
} body {
    return exp(logNcomb(n, k) + k * log(p) + (n - k) * log(1 - p));
}

unittest {
    assert(approxEqual(binomialPMF(0, 10, .5), cast(real) 1/1024));
    assert(approxEqual(binomialPMF(100, 1000, .11), .024856));
    writefln("Passed binomialPMF test.");
}

///P(K <= k) where K is random variable.
real binomialCDF(uint k, uint n, real p)
in {
    assert(k <= n);
    assert(p >= 0 && p <= 1);
} body {
    if(k == n)
        return 1;
    if(k == 0)
        return pow(1.0L - p,  cast(real) n);
    return betaIncomplete(n - k, k + 1, 1.0L - p);
}

unittest {
    assert(approxEqual(binomialCDF(10, 100, .11), 0.4528744401));
    assert(approxEqual(binomialCDF(15, 100, .12), 0.8585510507));
    assert(approxEqual(binomialCDF(50, 1000, .04), 0.95093595));
    assert(approxEqual(binomialCDF(7600, 15000, .5), .9496193045414));
    assert(approxEqual(binomialCDF(0, 10, 0.2), 0.1073742));
    writefln("Passed binomialCDF test.");
}

///P(K >= k) where K is random variable.
real binomialCDFR(uint k, uint n, real p)
in {
    assert(k <= n);
    assert(p >= 0 && p <= 1);
} body {
    if(k == 0)
        return 1;
    if(k == n)
        return pow(p, cast(real) n);
    return betaIncomplete(k, n - k + 1, p);
}

unittest {
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
    writefln("Passed binomialCDFR test.");
}

/**Returns the value of k for the given p-value, n and p.  If p-value does
 * not exactly map to a value of k, the value for which binomialCDF(k, n, p)
 * is closest to pVal is used.*/
uint invBinomialCDF(real pVal, uint n, real p) {
    // Use normal approximation to get approx answer, then brute force search.
    // This works better than you think because for small n, there's not much
    // search space and for large n, the normal approx. is really good.
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
            real newP = guessP + binomialPMF(k, n, p);
            if(abs(newP - pVal) > abs(guessP - pVal)) {
                return k - 1;
            } else {
                guessP = newP;
            }
        }
        return n;
    } else {
        for(uint k = guess - 1; k != uint.max; k--) {
            real newP = guessP - binomialPMF(k + 1, n, p);
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
       real p = uniform(0.1L, 0.9L);
       real pVal = binomialCDF(k, n, p);
       assert(invBinomialCDF(pVal, n, p) == k);
   }
   writeln("Passed invBinomialCDF unittest.");
}

/**P(X <= x), where X is random variable.  Uses either direct summation,
 * normal or binomial approximation depending on parameters.*/
// If anyone knows a better algorithm for this, feel free...
// I've read a decent amount about it, though, and getting hypergeometric
// CDFs that are both accurate and fast is just plain hard.  This
// implementation attempts to strike a balance between the two, so that
// both speed and accuracy are "good enough" for most practical purposes.
real hypergeometricCDF(long x, long n1, long n2, long n)
in {
    assert(x <= n);
} body {
    ulong expec = (n1 * n) / (n1 + n2);
    long nComp = n1 + n2 - n, xComp = n2 + x - n;

    // Try to reduce number of calculations using identities.
    if(x >= n1 || x == n) {
        return 1;
    } else if(x < 0) {  // Can be negative in some recursion cases.
        return 0;
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

    real p = cast(real) n1 / (n1 + n2);
    real pComp = cast(real) n2 / (n1 + n2);
    real pMin = min(p, pComp);
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
        real p2 = cast(real) n / (n1 + n2);
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
    writeln("Passed hypergeometricCDF unittest.");
}

///P(X >= x), where X is random variable.
real hypergeometricCDFR(ulong x, ulong n1, ulong n2, ulong n) {
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
    writefln("Passed hypergeometricCDFR unittest.");
}

real hyperExact(ulong x, ulong n1, ulong n2, ulong n, ulong startAt = 0) {
    immutable real constPart = logFactorial(n1) + logFactorial(n2) +
        logFactorial(n) + logFactorial(n1 + n2 - n) - logFactorial(n1 + n2);
    real sum = 0;
    for(ulong i = x; i != startAt - 1; i--) {
        real oldSum = sum;
        sum += exp(constPart - logFactorial(i) - logFactorial(n1 - i) -
               logFactorial(n2 + i - n) - logFactorial(n - i));
        if(isIdentical(sum, oldSum)) { // At full machine precision.
            break;
        }
    }
    return sum;
}

real normApproxHyper(ulong x, ulong n1, ulong n2, ulong n) {
    real p1 = cast(real) n1 / (n1 + n2);
    real p2 = cast(real) n2 / (n1 + n2);
    real numer = x + 0.5L - n * p1;
    real denom = sqrt(n * p1 * p2 * (n1 + n2 - n) / (n1 + n2 - 1));
    return normalCDF(numer / denom);
}

///
real hypergeometricPMF(long x, long n1, long n2, long n)
in {
    assert(x <= n);
} body {
    if(x > n1 || x < (n - n2)) {
        return 0;
    }
    real result = logNcomb(n1, x) + logNcomb(n2, n - x) - logNcomb(n1 + n2, n);
    return exp(result);
}

unittest {
    assert(approxEqual(hypergeometricPMF(5, 10, 10, 10), .3437182));
    assert(approxEqual(hypergeometricPMF(9, 12, 10, 15), .27089783));
    assert(approxEqual(hypergeometricPMF(9, 100, 100, 15), .15500003));
    writefln("Passed hypergeometricPMF unittest.");
}

/**
 *  $(POWER &chi;,2) distribution function and its complement.
 *
 * Returns the area under the left hand tail (from 0 to x)
 * of the Chi square probability density function with
 * v degrees of freedom. The complement returns the area under
 * the right hand tail (from x to &infin;).
 *
 *  chiSqrCDF(x | v) = ($(INTEGRATE 0, x)
 *          $(POWER t, v/2-1) $(POWER e, -t/2) dt )
 *             / $(POWER 2, v/2) $(GAMMA)(v/2)
 *
 *  chiSqrCDFR(x | v) = ($(INTEGRATE x, &infin;)
 *          $(POWER t, v/2-1) $(POWER e, -t/2) dt )
 *             / $(POWER 2, v/2) $(GAMMA)(v/2)
 *
 * Params:
 *  v  = degrees of freedom. Must be positive.
 *  x  = the $(POWER &chi;,2) variable. Must be positive.
 *
 */
real chiSqrCDF(real x, real v)
in {
 assert(x>=0);
 assert(v>=1.0);
}
body{
   return gammaIncomplete( 0.5*v, 0.5*x);
}

/** ditto */
real chiSqrCDFR(real x, real v)
in {
 assert(x>=0);
 assert(v>=1.0);
}
body{
    return gammaIncompleteCompl( 0.5L*v, 0.5L*x );
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
real invChiSqCDFR(real v, real p)
in {
  assert(p>=0 && p<=1.0L);
  assert(v>=1.0L);
}
body
{
   return  2.0 * gammaIncompleteComplInv( 0.5*v, p);
}

unittest {
  assert(feqrel(chiSqrCDFR(invChiSqCDFR(3.5L, 0.1L), 3.5L), 0.1L)>=real.mant_dig-3);
  assert(chiSqrCDF(0.4L, 19.02L) + chiSqrCDFR(0.4L, 19.02L) ==1.0L);
  assert(approxEqual( invChiSqCDFR( 3, chiSqrCDFR(1, 3)), 1));
  writeln("Passed chi-square unittest.");
}

///
real normalPDF(real x, real mean = 0, real sd = 1)
in {
    assert(sd > 0);
} body {
    real dev = x - mean;
    return exp(-(dev * dev) / (2 * sd * sd)) / (sd * SQ2PI);
}

unittest {
    assert(approxEqual(normalPDF(3, 1, 2), 0.1209854));
}

///P(X < x) for normal distribution where X is random var.
real normalCDF(real x, real mean = 0, real stdev = 1)
in {
    assert(stdev > 0);
} body {
    // Using a slightly non-obvious implementation in terms of erfc because
    // it seems more accurate than erf for very small values of Z.

    real Z = (-x + mean) / stdev;
    return erfc(Z*SQRT1_2)/2;
}

unittest {
    assert(approxEqual(normalCDF(2), .9772498));
    assert(approxEqual(normalCDF(-2), .02275013));
    assert(approxEqual(normalCDF(1.3), .90319951));
    writefln("Passed normalCDF test.");
}

///P(X > x) for normal distribution where X is random var.
real normalCDFR(real x, real mean = 0, real stdev = 1)
in {
    assert(stdev > 0);
} body {
    real Z = (x - mean) / stdev;
    return erfc(Z*SQRT1_2)/2;
}

unittest {
    //Should be essentially a mirror image of normalCDF.
    for(real i = -8; i < 8; i += .1) {
        assert(approxEqual(normalCDF(i), normalCDFR(-i)));
    }
    writefln("Passed normalCDFR test.");
}

const real SQRT2PI =   0x1.40d931ff62705966p+1;    // 2.5066282746310005024
const real EXP_2  = 0.13533528323661269189L; /* exp(-2) */

private {
immutable real P0[8] = [
   -0x1.758f4d969484bfdcp-7,    // -0.011400139698853582732
   0x1.53cee17a59259dd2p-3, // 0.16592193750979583221
   -0x1.ea01e4400a9427a2p-1,    // -0.95704568177942689081
   0x1.61f7504a0105341ap+1, // 2.7653599130008302859
   -0x1.09475a594d0399f6p+2,    // -4.1449800369337538286
   0x1.7c59e7a0df99e3e2p+1, // 2.971493676711545292
   -0x1.87a81da52edcdf14p-1,    // -0.76495449677843806914
   0x1.1fb149fd3f83600cp-7  // 0.0087796794200550691607
];

immutable real Q0[8] = [
   -0x1.64b92ae791e64bb2p-7,    // -0.010886331510064192632
   0x1.7585c7d597298286p-3, // 0.1823840725000038842
   -0x1.40011be4f7591ce6p+0,    // -1.2500169214248199725
   0x1.1fc067d8430a425ep+2, // 4.4961185085232139506
   -0x1.21008ffb1e7ccdf2p+3,    // -9.0313186554593813887
   0x1.3d1581cf9bc12fccp+3, // 9.9088753752567182205
   -0x1.53723a89fd8f083cp+2,    // -5.3038469646037218604
   0x1p+0   // 1
];

immutable real P1[10] = [
   0x1.20ceea49ea142f12p-13,    // 0.00013771451113809605662
   0x1.cbe8a7267aea80bp-7,  // 0.014035302749980729871
   0x1.79fea765aa787c48p-2, // 0.36913549001712241224
   0x1.d1f59faa1f4c4864p+1, // 3.6403083401370131097
   0x1.1c22e426a013bb96p+4, // 17.75851836288460008
   0x1.a8675a0c51ef3202p+5, // 53.050464721918523919
   0x1.75782c4f83614164p+6, // 93.367356531518738722
   0x1.7a2f3d90948f1666p+6, // 94.546133288447683183
   0x1.5cd116ee4c088c3ap+5, // 43.602094518370966827
   0x1.1361e3eb6e3cc20ap+2  // 4.3028497504355521807
];

immutable real Q1[10] = [
   0x1.3a4ce1406cea98fap-13,    // 0.00014987006762866754669
   0x1.f45332623335cda2p-7, // 0.015268706895221911913
   0x1.98f28bbd4b98db1p-2,  // 0.39936273901812389627
   0x1.ec3b24f9c698091cp+1, // 3.8455549449546995474
   0x1.1cc56ecda7cf58e4p+4, // 17.79820137342627204
   0x1.92c6f7376bf8c058p+5, // 50.347151215536627131
   0x1.4154c25aa47519b4p+6, // 80.332772651946720635
   0x1.1b321d3b927849eap+6, // 70.798939638914882544
   0x1.403a5f5a4ce7b202p+4, // 20.014251091705301368
   0x1p+0   // 1
];

immutable real P2[8] = [
   0x1.8c124a850116a6d8p-21,    // 7.3774056430545041787e-07
   0x1.534abda3c2fb90bap-13,    // 0.0001617870121822776094
   0x1.29a055ec93a4718cp-7, // 0.0090828342009931074419
   0x1.6468e98aad6dd474p-3, // 0.17402822927913678347
   0x1.3dab2ef4c67a601cp+0, // 1.2408933017345389353
   0x1.e1fb3a1e70c67464p+1, // 3.7654793404231444828
   0x1.b6cce8035ff57b02p+2, // 6.8562564881284157607
   0x1.9f4c9e749ff35f62p+1  // 3.2445257253129069325
];

immutable real Q2[8] = [
   0x1.af03f4fc0655e006p-21,    // 8.0282885006885383316e-07
   0x1.713192048d11fb2p-13, // 0.00017604524340842589303
   0x1.4357e5bbf5fef536p-7, // 0.0098676559208996361084
   0x1.7fdac8749985d43cp-3, // 0.18742901426157036096
   0x1.4a080c813a2d8e84p+0, // 1.2891853156563028786
   0x1.c3a4b423cdb41bdap+1, // 3.528463857156936774
   0x1.8160694e24b5557ap+2, // 6.0215094817275106307
   0x1p+0   // 1
];

immutable real P3[8] = [
   -0x1.55da447ae3806168p-34,   // -7.7728283809481633868e-11
   -0x1.145635641f8778a6p-24,   // -6.4339663876133447143e-08
   -0x1.abf46d6b48040128p-17,   // -1.2754046756102807876e-05
   -0x1.7da550945da790fcp-11,   // -0.00072793152007373443093
   -0x1.aa0b2a31157775fap-8,    // -0.0065009096152460679857
   0x1.b11d97522eed26bcp-3, // 0.21148222178987070632
   0x1.1106d22f9ae89238p+1, // 2.1330206615874130532
   0x1.029a358e1e630f64p+1  // 2.0203310913027725356
];

immutable real Q3[8] = [
   -0x1.74022dd5523e6f84p-34,   // -8.4584942637876803775e-11
   -0x1.2cb60d61e29ee836p-24,   // -7.0014768675591937804e-08
   -0x1.d19e6ec03a85e556p-17,   // -1.3876523894802171788e-05
   -0x1.9ea2a7b4422f6502p-11,   // -0.00079085420887378582886
   -0x1.c54b1e852f107162p-8,    // -0.0069167088997199649828
   0x1.e05268dd3c07989ep-3, // 0.23453218388704381964
   0x1.239c6aff14afbf82p+1, // 2.2782109971534491995
   0x1p+0   // 1
];

}

/******************************
 * Inverse of Normal distribution function
 *
 * Returns the argument, x, for which the area under the
 * Normal probability density function (integrated from
 * minus infinity to x) is equal to p.
 */
real invNormalCDF(real p, real mean = 0, real sd = 1)
in {
  assert(p>=0.0L && p<=1.0L); // domain error
}
body
{
    if (p == 0.0L) {
        return -real.infinity;
    }
    if( p == 1.0L ) {
        return real.infinity;
    }
    real x, z, y2, x0, x1;
    int code = 1;
    real y = p;
    if( y > (1.0L - EXP_2) ) {
        y = 1.0L - y;
        code = 0;
    }

    if ( y > EXP_2 ) {
        y = y - 0.5L;
        y2 = y * y;
        x = y + y * (y2 * poly( y2, P0)/poly( y2, Q0));
        x = x * SQRT2PI;
        return x * sd + mean;
    }

    x = sqrt( -2.0L * log(y) );
    x0 = x - log(x)/x;
    z = 1.0L/x;
    if( x < 8.0L ) {
        x1 = z * poly( z, P1)/poly( z, Q1);
    } else if( x < 32.0L ) {
        x1 = z * poly( z, P2)/poly( z, Q2);
    } else {
//  assert(0);
        x1 = z * poly( z, P3)/poly( z, Q3);
    }
    x = x0 - x1;
    if( code != 0 ) {
        x = -x;
    }
    return x * sd + mean;
}


unittest {
    // The values below are from Excel 2003.
    assert(fabs(invNormalCDF(0.001) - (-3.09023230616779))< 0.00000000000005);
    assert(fabs(invNormalCDF(1e-50) - (-14.9333375347885))< 0.00000000000005);
    assert(feqrel(invNormalCDF(0.999), -invNormalCDF(0.001))>real.mant_dig-6);

    // Excel 2003 gets all the following values wrong!
    assert(invNormalCDF(0.0)==-real.infinity);
    assert(invNormalCDF(1.0)==real.infinity);
    assert(invNormalCDF(0.5)==0);

    // I don't know the correct result for low values
    // (Excel 2003 returns norminv(p) = -30 for all p < 1e-200).
    // The value tested here is the one the function returned in Jan 2006.
    real unknown1 = invNormalCDF(1e-250L);
    assert( fabs(unknown1 -(-33.79958617269L) ) < 0.00000005);

    Random gen;
    gen.seed(unpredictableSeed);
    // normalCDF function trivial given ERF, unlikely to contain subtle bugs.
    // Just make sure invNormalCDF works like it should as the inverse.
    foreach(i; 0..1000) {
        real x = uniform(0.0L, 1.0L);
        real mean = uniform(0.0L, 100.0L);
        real sd = uniform(1.0L, 3.0L);
        real inv = invNormalCDF(x, mean, sd);
        real rec = normalCDF(inv, mean, sd);
        assert(approxEqual(x, rec));
    }
    writeln("Passed invNormalCDF unittest.");
}

///
real logNormalPDF(real x, real mu = 0, real sigma = 1)
in {
    assert(sigma > 0);
} body {
    real mulTerm = 1.0L / (x * sigma * SQ2PI);
    real expTerm = log(x) - mu;
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
real logNormalCDF(real x, real mu = 0, real sigma = 1)
in {
    assert(sigma > 0);
} body {
    return 0.5L + 0.5L * erf((log(x) - mu) / (sigma * SQRT2));
}

unittest {
    assert(approxEqual(logNormalCDF(4), 0.9171715));
    assert(approxEqual(logNormalCDF(1, -2, 3), 0.7475075));
}

///
real logNormalCDFR(real x, real mu = 0, real sigma = 1)
in {
    assert(sigma > 0);
} body {
    return 0.5L - 0.5L * erf((log(x) - mu) / (sigma * SQRT2));
}

unittest {
    assert(approxEqual(logNormalCDF(4) + logNormalCDFR(4), 1));
    assert(approxEqual(logNormalCDF(1, -2, 3) + logNormalCDFR(1, -2, 3), 1));
    writeln("Passed logNormal tests.");
}

///
real weibullPDF(real x, real shape, real scale = 1)
in {
    assert(shape > 0);
    assert(scale > 0);
} body {
    if(x < 0) {
        return 0;
    }
    real ret = pow(x / scale, shape - 1) * exp( -pow(x / scale, shape));
    return ret * (shape / scale);
}

unittest {
    assert(approxEqual(weibullPDF(2,1,3), 0.1711390));
}

///
real weibullCDF(real x, real shape, real scale = 1)
in {
    assert(shape > 0);
    assert(scale > 0);
} body {
    real exponent = pow(x / scale, shape);
    return 1 - exp(-exponent);
}

unittest {
    assert(approxEqual(weibullCDF(2, 3, 4), 0.1175031));
}

///
real weibullCDFR(real x, real shape, real scale = 1)
in {
    assert(shape > 0);
    assert(scale > 0);
} body {
    real exponent = pow(x / scale, shape);
    return exp(-exponent);
}

unittest {
    assert(approxEqual(weibullCDF(2, 3, 4) + weibullCDFR(2, 3, 4), 1));
    writeln("Passed weibull tests.");
}

// For K-S tests in dstats.random.  Todo:  Flesh out.
real waldCDF(real x, real mu, real lambda) {
    real sqr = sqrt(lambda / (2 * x));
    real term1 = 1 + erf(sqr * (x / mu - 1));
    real term2 = exp(2 * lambda / mu);
    real term3 = 1 - erf(sqr * (x / mu + 1));
    return 0.5L * term1 + 0.5L * term2 * term3;
}

// ditto.
real rayleighCDF(real x, real mode) {
    return 1.0L - exp(-x * x / (2 * mode * mode));
}

///
real studentsTCDF(real t, real df)   {
    real x = (t + sqrt(t * t + df)) / (2 * sqrt(t * t + df));
    return betaIncomplete(df * 0.5L, df * 0.5L, x);
}

///
real studentsTCDFR(real t, real df)   {
    return studentsTCDF(-t, df);
}

unittest {
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
real invStudentsTCDF(real p, real df)
// Author: Don Clugston. Public domain.
in {
   assert(df>0);
   assert(p>=0.0L && p<=1.0L);
}
body
{
    if (p==0) return -real.infinity;
    if (p==1) return real.infinity;

    real rk, z;
    rk =  df;

    if ( p > 0.25L && p < 0.75L ) {
        if ( p == 0.5L ) return 0;
        z = 1.0L - 2.0L * p;
        z = betaIncompleteInv( 0.5L, 0.5L*rk, fabs(z) );
        real t = sqrt( rk*z/(1.0L-z) );
        if( p < 0.5L )
            t = -t;
        return t;
    }
    int rflg = -1; // sign of the result
    if (p >= 0.5L) {
        p = 1.0L - p;
        rflg = 1;
    }
    z = betaIncompleteInv( 0.5L*rk, 0.5L, 2.0L*p );

    if (z<0) return rflg * real.infinity;
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
writeln("Passed studentsTCDF.");
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
real fisherCDF(real x, real df1, real df2)
in {
 assert(df1>=1 && df2>=1);
 assert(x>=0);
}
body{
    real a = cast(real)(df1);
    real b = cast(real)(df2);
    real w = a * x;
    w = w/(b + w);
    return betaIncomplete(0.5L*a, 0.5L*b, w);
}

/** ditto */
real fisherCDFR(real x, real df1, real df2)
in {
 assert(df1>=1 && df2>=1);
 assert(x>=0);
}
body{
    real a = cast(real)(df1);
    real b = cast(real)(df2);
    real w = b / (b + a * x);
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
 *      z = betaIncompleteInv( df2/2, df1/2, p ),
 *      x = df2 (1-z) / (df1 z).
 *
 * Note that the following relations hold for the inverse of
 * the uncomplemented F distribution:
 *
 *      z = betaIncompleteInv( df1/2, df2/2, p ),
 *      x = df2 z / (df1 (1-z)).
*/

/** ditto */
real invFisherCDFR(real df1, real df2, real p )
in {
 assert(df1>=1 && df2>=1);
 assert(p>=0 && p<=1.0);
}
body{
    real a = df1;
    real b = df2;
    /* Compute probability for x = 0.5.  */
    real w = betaIncomplete( 0.5L*b, 0.5L*a, 0.5L );
    /* If that is greater than p, then the solution w < .5.
       Otherwise, solve at 1-p to remove cancellation in (b - b*w).  */
    if ( w > p || p < 0.001L) {
        w = betaIncompleteInv( 0.5L*b, 0.5L*a, p );
        return (b - b*w)/(a*w);
    } else {
        w = betaIncompleteInv( 0.5L*a, 0.5L*b, 1.0L - p );
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
      writeln("Passed fisherCDF unittest.");
}

///
real negBinomPMF(uint k, uint n, real p)
in {
    assert(n > 0);
    assert(p >= 0 && p <= 1);
} body {
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
real negBinomCDF(uint k, uint n, real p )
in {
   assert(p>=0 && p<=1.0); // domain error
   assert(n > 0);
}
body{
    if ( k == 0 ) return pow(p, n);
    return  betaIncomplete( n, k + 1, p );
}

unittest {
    // Values from R.
    assert(approxEqual(negBinomCDF(50, 50, 0.5), 0.5397946));
    assert(approxEqual(negBinomCDF(2, 1, 0.5), 0.875));
}

/**Probability that k or more failures precede the nth success.*/
real negBinomCDFR(uint k, uint n, real p)
in {
    assert(p >= 0 && p <= 1);
    assert(n > 0);
} body {
    if(k == 0)
        return 1;
    return betaIncomplete(k, n, 1.0L - p);
}

unittest {
    assert(approxEqual(negBinomCDFR(10, 20, 0.5), 1 - negBinomCDF(9, 20, 0.5)));
    writeln("Passed negBinomCDF test.");
}

///
uint invNegBinomCDF(real pVal, uint n, real p)
in {
    assert(p >= 0 && p <= 1);
    assert(pVal >= 0 && p <= 1);
    assert(n > 0);
} body {
    // Normal or gamma approx, then adjust.
    real mean = n * (1 - p) / p;
    real var = n * (1 - p) / (p * p);
    real skew = (2 - p) / sqrt(n * (1 - p));
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
        for(uint k = guess - 1; guess != uint.max; k--) {
            real newP = guessP - negBinomPMF(k + 1, n, p);
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
        real p = uniform(0.0L, 1L);
        uint k = uniform(0, 20);
        real pVal = negBinomCDF(k, n, p);

        // In extreme tails, p-values can alias, giving incorrect results.
        // This is a corner case that nothing can be done about.  Just skip
        // these.
        if(pVal >= 1 - 10 * real.epsilon) {
            nSkipped++;
            continue;
        }
        assert(invNegBinomCDF(pVal, n, p) == k);
    }
    writeln("Passed invNegBinomCDF unittest.  (", nSkipped, " skipped.)");
}

/**
 * The &Gamma; distribution and its complement
 *
 * The &Gamma; distribution is defined as the integral from 0 to x of the
 * gamma probability density function. The complementary function returns the
 * integral from x to &infin;
 *
 * gammaCDF = ($(INTEGRATE 0, x) $(POWER t, b-1)$(POWER e, -at) dt) $(POWER a, b)/&Gamma;(b)
 *
 * x must be greater than 0.
 *
 * Also note that the exponential distribution is a special case of the gamma, with b = 1.
 */
real gammaCDF(real x, real a, real b)
in {
   assert(x>=0);
}
body {
   return gammaIncomplete(b, a*x);
}

/** ditto */
real gammaCDFR(real x, real a, real b)
in {
   assert(x>=0);
}
body {
   return gammaIncompleteCompl( b, a * x );
}

///
real invGammaCDFR(real p, real a, real b) {
    real ax = gammaIncompleteComplInv(b, p);
    return ax / a;
}

unittest {
    real inv = invGammaCDFR(0.78, 2, 1);
    assert(approxEqual(gammaCDFR(inv, 2, 1), 0.78));
}

///
real cauchyPDF(real X, real X0 = 0, real gamma = 1) pure nothrow {
    real toSquare = (X - X0) / gamma;
    return 1.0L / (
        PI * gamma * (1 + toSquare * toSquare));
}

unittest {
    assert(approxEqual(cauchyPDF(5), 0.01224269));
    assert(approxEqual(cauchyPDF(2), 0.06366198));
}


///
real cauchyCDF(real X, real X0 = 0, real gamma = 1) {
    return M_1_PI * atan((X - X0) / gamma) + 0.5L;
}

unittest {
    // Values from R
    assert(approxEqual(cauchyCDF(-10), 0.03172552));
    assert(approxEqual(cauchyCDF(1), 0.75));
}

///
real cauchyCDFR(real X, real X0 = 0, real gamma = 1) {
    return M_1_PI * atan((X0 - X) / gamma) + 0.5L;
}

unittest {
    // Values from R
    assert(approxEqual(1 - cauchyCDFR(-10), 0.03172552));
    assert(approxEqual(1 - cauchyCDFR(1), 0.75));
    writeln("Passed cauchyCDF unittest.");
}

///
real invCauchyCDF(real p, real X0 = 0, real gamma = 1) pure nothrow {
    return X0 + gamma * tan(PI * (p - 0.5L));
}

unittest {
    // cauchyCDF already tested.  Just make sure this is the inverse.
    assert(approxEqual(invCauchyCDF(cauchyCDF(.5)), .5));
    assert(approxEqual(invCauchyCDF(cauchyCDF(.99)), .99));
    assert(approxEqual(invCauchyCDF(cauchyCDF(.03)), .03));
    writeln("Passed invCauchyCDF unittest.");
}

// For K-S tests in dstats.random.  To be fleshed out later.  Intentionally
// lacking ddoc.
real logisticCDF(real x, real loc, real shape) {
    return 1.0L / (1 + exp(-(x - loc) / shape));
}

///
real laplacePDF(real x, real mu = 0, real b = 1) pure nothrow {
    return (exp(-abs(x - mu) / b)) / (2 * b);
}

unittest {
    // Values from Maxima.
    assert(approxEqual(laplacePDF(3, 2, 1), 0.18393972058572));
    assert(approxEqual(laplacePDF(-8, 6, 7), 0.0096668059454723));
}

///
real laplaceCDF(real X, real mu = 0, real b = 1) pure nothrow {
    real diff = (X - mu);
    real sign = (diff > 0) ? 1 : -1;
    return 0.5L *(1 + sign * (1 - exp(-abs(diff) / b)));
}

unittest {
    // Values from Octave.
    assert(approxEqual(laplaceCDF(5), 0.9963));
    assert(approxEqual(laplaceCDF(-3.14), .021641));
    assert(approxEqual(laplaceCDF(0.012), 0.50596));
}

///
real laplaceCDFR(real X, real mu = 0, real b = 1) pure nothrow {
    real diff = (mu - X);
    real sign = (diff > 0) ? 1 : -1;
    return 0.5L *(1 + sign * (1 - exp(-abs(diff) / b)));
}

unittest {
    // Values from Octave.
    assert(approxEqual(1 - laplaceCDFR(5), 0.9963));
    assert(approxEqual(1 - laplaceCDFR(-3.14), .021641));
    assert(approxEqual(1 - laplaceCDFR(0.012), 0.50596));
    writeln("Passed laplaceCDF unittest.");
}

///
real invLaplaceCDF(real p, real mu = 0, real b = 1) {
    real p05 = p - 0.5L;
    real sign = (p05 < 0) ? -1.0L : 1.0L;
    return mu - b * sign * log(1.0L - 2 * abs(p05));
}

unittest {
    assert(approxEqual(invLaplaceCDF(0.012), -3.7297));
    assert(approxEqual(invLaplaceCDF(0.82), 1.0217));
    writeln("Passed invLaplaceCDF unittest.");
}


/**Kolmogorov distribution.  Used in Kolmogorov-Smirnov testing.*/
real kolmDist(real X) pure nothrow {
    if(X == 0) {
        //Handle as a special case.  Otherwise, get NAN b/c of divide by zero.
        return 0;
    }
    real delta = real.max, result = 0;
    real i = 1;
    while(delta > real.epsilon) {
        delta = exp(-(2 * i - 1) * (2 * i - 1) * PI * PI  / (8 * X * X));
        i++;
        result += delta;
    }
    result *= (sqrt(2 * PI) / X);
    return result;
}

unittest {
    assert(approxEqual(1 - kolmDist(.75), 0.627167));
    assert(approxEqual(1 - kolmDist(.5), 0.9639452436));
    assert(approxEqual(1 - kolmDist(.9), 0.39273070));
    assert(approxEqual(1 - kolmDist(1.2), 0.112249666));
    writeln("Passed kolmDist unittest.");
}

// Verify that there are no TempAlloc memory leaks anywhere in the code covered
// by the unittest.  This should always be the last unittest of the module.
unittest {
    auto TAState = TempAlloc.getState;
    assert(TAState.used == 0);
    assert(TAState.nblocks < 2);
}
