/**Generates random samples from a various probability distributions.
 * These are mostly D ports of the NumPy random number generators.*/

/* This library is a D port of a large portion of the Numpy random number
 * library.  A few distributions were excluded because they were too obscure
 * to be tested properly.  They may be included at some point in the future.
 *
 * Port to D copyright 2009 David Simcha.
 *
 * The original C code is available under the licenses below.  No additional
 * restrictions shall apply to this D translation.  Eventually, I will try to
 * discuss the licensing issues with the original authors of Numpy and
 * make this sane enough that this module can be included in Phobos without
 * concern.  For now, it's free enough that you can at least use it in
 * personal projects without any serious issues.
 *
 * Main Numpy license:
 *
 * Copyright (c) 2005-2009, NumPy Developers.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 *        notice, this list of conditions and the following disclaimer.
 *
 *     * Redistributions in binary form must reproduce the above
 *        copyright notice, this list of conditions and the following
 *        disclaimer in the documentation and/or other materials provided
 *        with the distribution.
 *
 *     * Neither the name of the NumPy Developers nor the names of any
 *        contributors may be used to endorse or promote products derived
 *        from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * distribution.c  license:
 *
 * Copyright 2005 Robert Kern (robert.kern@gmail.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/* The implementations of rHypergeometricHyp() and rHypergeometricHrua()
 * were adapted from Ivan Frohne's rv.py which has this
 * license:
 *
 *            Copyright 1998 by Ivan Frohne; Wasilla, Alaska, U.S.A.
 *                            All Rights Reserved
 *
 * Permission to use, copy, modify and distribute this software and its
 * documentation for any purpose, free of charge, is granted subject to the
 * following conditions:
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the software.
 *
 *   THE SOFTWARE AND DOCUMENTATION IS PROVIDED WITHOUT WARRANTY OF ANY KIND,
 *   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO MERCHANTABILITY, FITNESS
 *   FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHOR
 *   OR COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM OR DAMAGES IN A CONTRACT
 *   ACTION, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 *   SOFTWARE OR ITS DOCUMENTATION.
 */

 /* References:
 *
 * Devroye, Luc. _Non-Uniform Random Variate Generation_.
 *  Springer-Verlag, New York, 1986.
 *  http://cgm.cs.mcgill.ca/~luc/rnbookindex.html
 *
 * Kachitvichyanukul, V. and Schmeiser, B. W. Binomial Random Variate
 *  Generation. Communications of the ACM, 31, 2 (February, 1988) 216.
 *
 * Hoermann, W. The Transformed Rejection Method for Generating Poisson Random
 *  Variables. Insurance: Mathematics and Economics, (to appear)
 *  http://citeseer.csail.mit.edu/151115.html
 *
 * Marsaglia, G. and Tsang, W. W. A Simple Method for Generating Gamma
 * Variables. ACM Transactions on Mathematical Software, Vol. 26, No. 3,
 * September 2000, Pages 363-372.
 */


/* Unit tests are non-deterministic.  They prove that the distributions
 * are reasonable by using K-S tests and summary stats, but cannot
 * deterministically prove correctness.*/

module dstats.random;

import std.math, dstats.distrib, std.traits, std.typetuple,
    std.exception, std.mathspecial, std.array;
import std.algorithm : min, max;
public import std.random; //For uniform distrib.

import dstats.alloc, dstats.base;

version(unittest) {
    import std.stdio, dstats.tests, dstats.summary, std.range;
}

/**Convenience function to allow one-statement creation of arrays of random
 * numbers.
 *
 * Examples:
 * ---
 * // Create an array of 10 random numbers distributed Normal(0, 1).
 * auto normals = randArray!rNormal(10, 0, 1);
 * ---
 */
auto randArray(alias randFun, Args...)(size_t N, auto ref Args args) {
    alias typeof(randFun(args)) R;
    return randArray!(R, randFun, Args)(N, args);
}

unittest {
    // Just check if it compiles.
    auto nums = randArray!rNormal(5, 0, 1);
    auto nums2 = randArray!rBinomial(10, 5, 0.5);
}

/**Allows the creation of an array of random numbers with an explicitly
 * specified type.  Useful, for example, when single-precision floats are all
 * you need.
 *
 * Examples:
 * ---
 * // Create an array of 10 million floats distributed Normal(0, 1).
 * float[] normals = randArray!(float, rNormal)(10, 0, 1);
 * ---
 */
R[] randArray(R, alias randFun, Args...)(size_t N, auto ref Args args) {
    auto ret = uninitializedArray!(R[])(N);
    foreach(ref elem; ret) {
        elem = randFun(args);
    }

    return ret;
}

///
struct RandRange(alias randFun, T...) {
private:
    T args;
    double normData = double.nan;  // TLS stuff for normal.
    typeof(randFun(args)) frontElem;
public:
    enum bool empty = false;

    this(T args) {
        this.args = args;
        popFront;
    }

    @property typeof(randFun(args)) front() {
        return frontElem;
    }

    void popFront() {
        /* This is a kludge to make the contents of this range deterministic
         * given the state of the underlying random number generator without
         * a massive redesign.  We store the state in this struct and
         * swap w/ the TLS data for rNormal on each call to popFront.  This has to
         * be done no matter what distribution we're using b/c a lot of others
         * rely on the normal.*/
        auto lastNormPtr = &lastNorm;  // Cache ptr once, avoid repeated TLS lookup.
        auto temp = *lastNormPtr;  // Store old state.
        *lastNormPtr = normData;  // Replace it.
        this.frontElem = randFun(args);
        normData = *lastNormPtr;
        *lastNormPtr = temp;
    }

    @property typeof(this) save() {
        return this;
    }
}

/**Turn a random number generator function into an infinite range.
 * Params is a tuple of the distribution parameters.  This is specified
 * in the same order as when calling the function directly.
 *
 * The sequence generated by this range is deterministic and repeatable given
 * the state of the underlying random number generator.  If the underlying
 * random number generator is explicitly specified, as opposed to using the
 * default thread-local global RNG, it is copied when the struct is copied.
 * See below for an example of this behavior.
 *
 * Examples:
 * ---
 * // Print out some summary statistics for 10,000 Poisson-distributed
 * // random numbers w/ Poisson parameter 2.
 * auto gen = Random(unpredictableSeed);
 * auto pois1k = take(10_000, randRange!rPoisson(2, gen));
 * writeln( summary(pois1k) );
 * writeln( summary(pois1k) );  // Exact same results as first call.
 * ---
 */
RandRange!(randFun, T) randRange(alias randFun, T...)(T params) {
    alias RandRange!(randFun, T) RT;
    RT ret;  // Bypass the ctor b/c it's screwy.
    ret.args = params;
    ret.popFront;
    return ret;
}

unittest {
    // The thing to test here is that the results are deterministic given
    // an underlying RNG.

    {
        auto norms = take(randRange!rNormal(0, 1, Random(unpredictableSeed)), 99);
        auto arr1 = array(norms);
        auto arr2 = array(norms);
        assert(arr1 == arr2);
    }

    {
        auto binomSmall = take(randRange!rBinomial(20, 0.5, Random(unpredictableSeed)), 99);
        auto arr1 = array(binomSmall);
        auto arr2 = array(binomSmall);
        assert(arr1 == arr2);
    }

    {
        auto binomLarge = take(randRange!rBinomial(20000, 0.4, Random(unpredictableSeed)), 99);
        auto arr1 = array(binomLarge);
        auto arr2 = array(binomLarge);
        assert(arr1 == arr2);
    }
    writeln("Passed RandRange test.");
}

// Thread local data for normal distrib. that is preserved across calls.
private static double lastNorm = double.nan;

///
double rNormal(RGen = Random)(double mean, double sd, ref RGen gen = rndGen) {
    dstatsEnforce(sd > 0, "Standard deviation must be > 0 for rNormal.");

    double lr = lastNorm;
    if (!isNaN(lr)) {
        lastNorm = double.nan;
        return lr * sd + mean;
    }

    double x1 = void, x2 = void, r2 = void;
    do {
        x1 = uniform(-1.0L, 1.0L, gen);
        x2 = uniform(-1.0L, 1.0L, gen);
        r2 = x1 * x1 + x2 * x2;
    } while (r2 > 1.0L || r2 == 0.0L);
    double f = sqrt(-2.0L * log(r2) / r2);
    lastNorm = f * x1;
    return f * x2 * sd + mean;
}


unittest {
    auto observ = randArray!rNormal(100_000, 0, 1);
    auto ksRes = ksTest(observ, parametrize!(normalCDF)(0.0L, 1.0L));
    auto summ = summary(observ);

    writeln("100k samples from normal(0, 1):  K-S P-val:  ", ksRes.p);
    writeln("\tMean Expected: 0  Observed:  ", summ.mean);
    writeln("\tMedian Expected: 0  Observed:  ", median(observ));
    writeln("\tStdev Expected:  1  Observed:  ", summ.stdev);
    writeln("\tKurtosis Expected:  0  Observed:  ", summ.kurtosis);
    writeln("\tSkewness Expected:  0  Observed:  ", summ.skewness);
}

///
double rCauchy(RGen = Random)(double X0, double gamma, ref RGen gen = rndGen) {
    dstatsEnforce(gamma > 0, "gamma must be > 0 for Cauchy distribution.");

    return (rNormal(0, 1, gen) / rNormal(0, 1, gen)) * gamma + X0;
}

unittest {
    auto observ = randArray!rCauchy(100_000, 2, 5);
    auto ksRes = ksTest(observ, parametrize!(cauchyCDF)(2.0L, 5.0L));

    auto summ = summary(observ);
    writeln("100k samples from Cauchy(2, 5):  K-S P-val:  ", ksRes.p);
    writeln("\tMean Expected: N/A  Observed:  ", summ.mean);
    writeln("\tMedian Expected: 2  Observed:  ", median(observ));
    writeln("\tStdev Expected:  N/A  Observed:  ", summ.stdev);
    writeln("\tKurtosis Expected:  N/A  Observed:  ", summ.kurtosis);
    writeln("\tSkewness Expected:  N/A  Observed:  ", summ.skewness);
}

///
double rStudentsT(RGen = Random)(double df, ref RGen gen = rndGen) {
    dstatsEnforce(df > 0, "Student's T distribution must have >0 degrees of freedom.");

    double N = rNormal(0, 1, gen);
    double G = stdGamma(df / 2, gen);
    double X = sqrt(df / 2) * N / sqrt(G);
    return X;
}

unittest {
    auto observ = randArray!rStudentsT(100_000, 5);
    auto ksRes = ksTest(observ, parametrize!(studentsTCDF)(5));

    auto summ = summary(observ);
    writeln("100k samples from T(5):  K-S P-val:  ", ksRes.p);
    writeln("\tMean Expected: 0  Observed:  ", summ.mean);
    writeln("\tMedian Expected: 0  Observed:  ", median(observ));
    writeln("\tStdev Expected:  1.2909  Observed:  ", summ.stdev);
    writeln("\tKurtosis Expected:  6  Observed:  ", summ.kurtosis);
    writeln("\tSkewness Expected:  0  Observed:  ", summ.skewness);
}

///
double rFisher(RGen = Random)(double df1, double df2, ref RGen gen = rndGen) {
    dstatsEnforce(df1 > 0 && df2 > 0,
        "df1 and df2 must be >0 for the Fisher distribution.");

    return (rChiSquare(df1, gen) * df2) /
           (rChiSquare(df2, gen) * df1);
}

unittest {
    auto observ = randArray!rFisher(100_000, 5, 7);
    auto ksRes = ksTest(observ, parametrize!(fisherCDF)(5, 7));
    writeln("100k samples from fisher(5, 7):  K-S P-val:  ", ksRes.p);
    writeln("\tMean Expected: ",  7.0 / 5, "  Observed:  ", mean(observ));
    writeln("\tMedian Expected: ??  Observed:  ", median(observ));
    writeln("\tStdev Expected:  ??  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  ??  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  ??  Observed:  ", skewness(observ));
    delete observ;
}

///
double rChiSquare(RGen = Random)(double df, ref RGen gen = rndGen) {
    dstatsEnforce(df > 0, "df must be > 0 for chiSquare distribution.");

    return 2.0 * stdGamma(df / 2.0L, gen);
}

unittest {
    double df = 5;
    double[] observ = new double[100_000];
    foreach(ref elem; observ)
    elem = rChiSquare(df);
    auto ksRes = ksTest(observ, parametrize!(chiSquareCDF)(5));
    writeln("100k samples from Chi-Square:  K-S P-val:  ", ksRes.p);
    writeln("\tMean Expected: ", df, "  Observed:  ", mean(observ));
    writeln("\tMedian Expected: ", df - (2.0L / 3.0L), "  Observed:  ", median(observ));
    writeln("\tStdev Expected:  ", sqrt(2 * df), "  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  ", 12 / df, "  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  ", sqrt(8 / df), "  Observed:  ", skewness(observ));
    delete observ;
}

///
int rPoisson(RGen = Random)(double lam, ref RGen gen = rndGen) {
    dstatsEnforce(lam > 0, "lambda must be >0 for Poisson distribution.");

    static int poissonMult(ref RGen gen, double lam) {
        double U = void;

        double enlam = exp(-lam);
        int X = 0;
        double prod = 1.0;
        while (true) {
            U = uniform(0.0L, 1.0L, gen);
            prod *= U;
            if (prod > enlam) {
                X += 1;
            } else {
                return X;
            }
        }
        assert(0);
    }

    enum double LS2PI = 0.91893853320467267;
    enum double TWELFTH = 0.083333333333333333333333;
    static int poissonPtrs(ref RGen gen, double lam) {
        int k;
        double U = void, V = void, us = void;

        double slam = sqrt(lam);
        double loglam = log(lam);
        double b = 0.931 + 2.53*slam;
        double a = -0.059 + 0.02483*b;
        double invalpha = 1.1239 + 1.1328/(b-3.4);
        double vr = 0.9277 - 3.6224/(b-2);

        while (true) {
            U = uniform(-0.5L, 0.5L, gen);
            V = uniform(0.0L, 1.0L, gen);
            us = 0.5 - abs(U);
            k = cast(int) floor((2*a/us + b)*U + lam + 0.43);
            if ((us >= 0.07) && (V <= vr)) {
                return k;
            }
            if ((k < 0) || ((us < 0.013) && (V > us))) {
                continue;
            }
            if ((log(V) + log(invalpha) - log(a/(us*us)+b)) <=
                    (-lam + k*loglam - logGamma(k+1))) {
                return k;
            }
        }
        assert(0);
    }


    if (lam >= 10) {
        return poissonPtrs(gen, lam);
    } else if (lam == 0) {
        return 0;
    } else {
        return poissonMult(gen, lam);
    }
}

unittest {
    double lambda = 15L;
    int[] observ = new int[100_000];
    foreach(ref elem; observ)
    elem = rPoisson(lambda);
    writeln("100k samples from poisson(", lambda, "):");
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

///
int rBernoulli(RGen = Random)(double P = 0.5, ref RGen gen = rndGen) {
    dstatsEnforce(P >= 0 && P <= 1, "P must be between 0, 1 for Bernoulli distribution.");

    double pVal = uniform(0.0L, 1.0L, gen);
    return cast(int) (pVal <= P);
}

private struct BinoState {
    bool has_binomial;
    int nsave;
    double psave;
    int m;
    double r,q,fm,p1,xm,xl,xr,c,laml,lamr,p2,p3,p4;
    double a,u,v,s,F,rho,t,A,nrq,x1,x2,f1,f2,z,z2,w,w2,x;
}

private BinoState* binoState() {
    // Store BinoState structs on heap rather than directly in TLS.

    static BinoState* stateTLS;
    auto tlsPtr = stateTLS;
    if (tlsPtr is null) {
        tlsPtr = new BinoState;
        stateTLS = tlsPtr;
    }
    return tlsPtr;
}


private int rBinomialBtpe(RGen = Random)(int n, double p, ref RGen gen = rndGen) {
    auto state = binoState;
    double r,q,fm,p1,xm,xl,xr,c,laml,lamr,p2,p3,p4;
    double a,u,v,s,F,rho,t,A,nrq,x1,x2,f1,f2,z,z2,w,w2,x;
    int m,y,k,i;

    if (!(state.has_binomial) ||
            (state.nsave != n) ||
            (state.psave != p)) {
        /* initialize */
        state.nsave = n;
        state.psave = p;
        state.has_binomial = 1;
        state.r = r = min(p, 1.0-p);
        state.q = q = 1.0 - r;
        state.fm = fm = n*r+r;
        state.m = m = cast(int)floor(state.fm);
        state.p1 = p1 = floor(2.195*sqrt(n*r*q)-4.6*q) + 0.5;
        state.xm = xm = m + 0.5;
        state.xl = xl = xm - p1;
        state.xr = xr = xm + p1;
        state.c = c = 0.134 + 20.5/(15.3 + m);
        a = (fm - xl)/(fm-xl*r);
        state.laml = laml = a*(1.0 + a/2.0);
        a = (xr - fm)/(xr*q);
        state.lamr = lamr = a*(1.0 + a/2.0);
        state.p2 = p2 = p1*(1.0 + 2.0*c);
        state.p3 = p3 = p2 + c/laml;
        state.p4 = p4 = p3 + c/lamr;
    } else {
        r = state.r;
        q = state.q;
        fm = state.fm;
        m = state.m;
        p1 = state.p1;
        xm = state.xm;
        xl = state.xl;
        xr = state.xr;
        c = state.c;
        laml = state.laml;
        lamr = state.lamr;
        p2 = state.p2;
        p3 = state.p3;
        p4 = state.p4;
    }

    /* sigh ... */
Step10:
    nrq = n*r*q;
    u = uniform(0.0L, p4, gen);
    v = uniform(0.0L, 1.0L, gen);
    if (u > p1) goto Step20;
    y = cast(int)floor(xm - p1*v + u);
    goto Step60;

Step20:
    if (u > p2) goto Step30;
    x = xl + (u - p1)/c;
    v = v*c + 1.0 - fabs(m - x + 0.5)/p1;
    if (v > 1.0) goto Step10;
    y = cast(int)floor(x);
    goto Step50;

Step30:
    if (u > p3) goto Step40;
    y = cast(int)floor(xl + log(v)/laml);
    if (y < 0) goto Step10;
    v = v*(u-p2)*laml;
    goto Step50;

Step40:
    y = cast(int)floor(xr - log(v)/lamr);
    if (y > n) goto Step10;
    v = v*(u-p3)*lamr;

Step50:
    k = cast(int) abs(y - m);
    if ((k > 20) && (k < ((nrq)/2.0 - 1))) goto Step52;

    s = r/q;
    a = s*(n+1);
    F = 1.0;
    if (m < y) {
        for (i=m; i<=y; i++) {
            F *= (a/i - s);
        }
    } else if (m > y) {
        for (i=y; i<=m; i++) {
            F /= (a/i - s);
        }
    } else {
        if (v > F) goto Step10;
        goto Step60;
    }

Step52:
    rho = (k/(nrq))*((k*(k/3.0 + 0.625) + 0.16666666666666666)/nrq + 0.5);
    t = -k*k/(2*nrq);
    A = log(v);
    if (A < (t - rho)) goto Step60;
    if (A > (t + rho)) goto Step10;

    x1 = y+1;
    f1 = m+1;
    z = n+1-m;
    w = n-y+1;
    x2 = x1*x1;
    f2 = f1*f1;
    z2 = z*z;
    w2 = w*w;
    if (A > (xm*log(f1/x1)
             + (n-m+0.5)*log(z/w)
             + (y-m)*log(w*r/(x1*q))
             + (13680.-(462.-(132.-(99.-140./f2)/f2)/f2)/f2)/f1/166320.
             + (13680.-(462.-(132.-(99.-140./z2)/z2)/z2)/z2)/z/166320.
             + (13680.-(462.-(132.-(99.-140./x2)/x2)/x2)/x2)/x1/166320.
             + (13680.-(462.-(132.-(99.-140./w2)/w2)/w2)/w2)/w/166320.)) {
        goto Step10;
    }

Step60:
    if (p > 0.5) {
        y = n - y;
    }

    return y;
}

private int rBinomialInversion(RGen = Random)(int n, double p, ref RGen gen = rndGen) {
    auto state = binoState;
    double q, qn, np, px, U;
    int X, bound;

    if (!(state.has_binomial) ||
            (state.nsave != n) ||
            (state.psave != p)) {
        state.nsave = n;
        state.psave = p;
        state.has_binomial = 1;
        state.q = q = 1.0 - p;
        state.r = qn = exp(n * log(q));
        state.c = np = n*p;
        state.m = bound = cast(int) min(n, np + 10.0*sqrt(np*q + 1));
    } else {
        q = state.q;
        qn = state.r;
        np = state.c;
        bound = cast(int) state.m;
    }
    X = 0;
    px = qn;
    U = uniform(0.0L, 1.0L, gen);
    while (U > px) {
        X++;
        if (X > bound) {
            X = 0;
            px = qn;
            U = uniform(0.0L, 1.0L, gen);
        } else {
            U -= px;
            px  = ((n-X+1) * p * px)/(X*q);
        }
    }
    return X;
}

///
int rBinomial(RGen = Random)(int n, double p, ref RGen gen = rndGen) {
    dstatsEnforce(n >= 0, "n must be >= 0 for binomial distribution.");
    dstatsEnforce(p >= 0 && p <= 1, "p must be between 0, 1 for binomial distribution.");

    if (p <= 0.5) {
        if (p*n <= 30.0) {
            return rBinomialInversion(n, p, gen);
        } else {
            return rBinomialBtpe(n, p, gen);
        }
    } else {
        double q = 1.0-p;
        if (q*n <= 30.0) {
            return n - rBinomialInversion(n, q, gen);
        } else {
            return n - rBinomialBtpe(n, q, gen);
        }
    }
}

unittest {
    void testBinom(int n, double p) {
        int[] observ = new int[100_000];
        foreach(ref elem; observ)
        elem = rBinomial(n, p);
        writeln("100k samples from binom.(", n, ", ", p, "):");
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

    testBinom(1000, 0.6);
    testBinom(3, 0.7);
}

private int hypergeoHyp(RGen = Random)(int good, int bad, int sample, ref RGen gen = rndGen) {
    int Z = void;
    double U = void;

    int d1 = bad + good - sample;
    double d2 = cast(double)min(bad, good);

    double Y = d2;
    int K = sample;
    while (Y > 0.0) {
        U = uniform(0.0L, 1.0L, gen);
        Y -= cast(int)floor(U + Y/(d1 + K));
        K--;
        if (K == 0) break;
    }
    Z = cast(int)(d2 - Y);
    if (good > bad) Z = sample - Z;
    return Z;
}

private enum double D1 = 1.7155277699214135;
private enum double D2 = 0.8989161620588988;
private int hypergeoHrua(RGen = Random)(int good, int bad, int sample, ref RGen gen = rndGen) {
    int Z = void;
    double T = void, W = void, X = void, Y = void;

    int mingoodbad = min(good, bad);
    int popsize = good + bad;
    int maxgoodbad = max(good, bad);
    int m = min(sample, popsize - sample);
    double d4 = (cast(double)mingoodbad) / popsize;
    double d5 = 1.0 - d4;
    double d6 = m*d4 + 0.5;
    double d7 = sqrt((popsize - m) * sample * d4 *d5 / (popsize-1) + 0.5);
    double d8 = D1*d7 + D2;
    int d9 = cast(int)floor(cast(double)((m+1)*(mingoodbad+1))/(popsize+2));
    double d10 = (logGamma(d9+1) + logGamma(mingoodbad-d9+1) + logGamma(m-d9+1) +
                logGamma(maxgoodbad-m+d9+1));
    double d11 = min(min(m, mingoodbad)+1.0, floor(d6+16*d7));
    /* 16 for 16-decimal-digit precision in D1 and D2 */

    while (true) {
        X = uniform(0.0L, 1.0L, gen);
        Y = uniform(0.0L, 1.0L, gen);
        W = d6 + d8*(Y- 0.5)/X;

        /* fast rejection: */
        if ((W < 0.0) || (W >= d11)) continue;

        Z = cast(int)floor(W);
        T = d10 - (logGamma(Z+1) + logGamma(mingoodbad-Z+1) + logGamma(m-Z+1) +
                   logGamma(maxgoodbad-m+Z+1));

        /* fast acceptance: */
        if ((X*(4.0-X)-3.0) <= T) break;

        /* fast rejection: */
        if (X*(X-T) >= 1) continue;

        if (2.0*log(X) <= T) break;  /* acceptance */
    }

    /* this is a correction to HRUA* by Ivan Frohne in rv.py */
    if (good > bad) Z = m - Z;

    /* another fix from rv.py to allow sample to exceed popsize/2 */
    if (m < sample) Z = good - Z;

    return Z;
}

///
int rHypergeometric(RGen = Random)(int n1, int n2, int n, ref RGen gen = rndGen) {
    dstatsEnforce(n <= n1 + n2, "n must be <= n1 + n2 for hypergeometric distribution.");
    dstatsEnforce(n1 >= 0 && n2 >= 0 && n >= 0,
        "n, n1, n2 must be >= 0 for hypergeometric distribution.");

    alias n1 good;
    alias n2 bad;
    alias n sample;
    if (sample > 10) {
        return hypergeoHrua(good, bad, sample, gen);
    } else {
        return hypergeoHyp(good, bad, sample, gen);
    }
}

unittest {

    static double hyperStdev(int n1, int n2, int n) {
        return sqrt(cast(double) n * (cast(double) n1 / (n1 + n2))
        * (1 - cast(double) n1 / (n1 + n2)) * (n1 + n2 - n) / (n1 + n2 - 1));
    }

    static double hyperSkew(double n1, double n2, double n) {
        double N = n1 + n2;
        alias n1 m;
        double numer = (N - 2 * m) * sqrt(N - 1) * (N - 2 * n);
        double denom = sqrt(n * m * (N - m) * (N - n)) * (N - 2);
        return numer / denom;
    }

    void testHyper(int n1, int n2, int n) {
        int[] observ = new int[100_000];
        foreach(ref elem; observ)
        elem = rHypergeometric(n1, n2, n);
        auto ksRes = ksTest(observ, parametrize!(hypergeometricCDF)(n1, n2, n));
        writeln("100k samples from hypergeom.(", n1, ", ", n2, ", ", n, "):");
        writeln("\tMean Expected: ", n * cast(double) n1 / (n1 + n2),
                "  Observed:  ", mean(observ));
        writeln("\tMedian Expected: ??  Observed:  ", median(observ));
        writeln("\tStdev Expected:  ", hyperStdev(n1, n2, n),
                "  Observed:  ", stdev(observ));
        writeln("\tKurtosis Expected:  ?? Observed:  ", kurtosis(observ));
        writeln("\tSkewness Expected:  ", hyperSkew(n1, n2, n), "  Observed:  ", skewness(observ));
        delete observ;
    }

    testHyper(4, 5, 2);
    testHyper(120, 105, 70);
}

private int rGeomSearch(RGen = Random)(double p, ref RGen gen = rndGen) {
    int X = 1;
    double sum = p, prod = p;
    double q = 1.0 - p;
    double U = uniform(0.0L, 1.0L, gen);
    while (U > sum) {
        prod *= q;
        sum += prod;
        X++;
    }
    return X;
}

private int rGeomInvers(RGen = Random)(double p, ref RGen gen = rndGen) {
    return cast(int)ceil(log(1.0-uniform(0.0L, 1.0L, gen))/log(1.0-p));
}

int rGeometric(RGen = Random)(double p, ref RGen gen = rndGen) {
    dstatsEnforce(p >= 0 && p <= 1, "p must be between 0, 1 for geometric distribution.");

    if (p >= 0.333333333333333333333333) {
        return rGeomSearch(p, gen);
    } else {
        return rGeomInvers(p, gen);
    }
}

unittest {

    void testGeom(double p) {
        int[] observ = new int[100_000];
        foreach(ref elem; observ)
        elem = rGeometric(p);
        writeln("100k samples from geometric.(", p, "):");
        writeln("\tMean Expected: ", 1 / p,
                "  Observed:  ", mean(observ));
        writeln("\tMedian Expected: ", ceil(-log(2) / log(1 - p)),
                " Observed:  ", median(observ));
        writeln("\tStdev Expected:  ", sqrt((1 - p) / (p * p)),
                "  Observed:  ", stdev(observ));
        writeln("\tKurtosis Expected:  ", 6 + (p * p) / (1 - p),
                "  Observed:  ", kurtosis(observ));
        writeln("\tSkewness Expected:  ", (2 - p) / sqrt(1 - p),
                "  Observed:  ", skewness(observ));
        delete observ;
    }

    testGeom(0.1);
    testGeom(0.74);

}

///
int rNegBinom(RGen = Random)(double n, double p, ref RGen gen = rndGen) {
    dstatsEnforce(n >= 0, "n must be >= 0 for negative binomial distribution.");
    dstatsEnforce(p >= 0 && p <= 1,
        "p must be between 0, 1 for negative binomial distribution.");

    double Y = stdGamma(n, gen);
    Y *= (1 - p) / p;
    return rPoisson(Y, gen);
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    double p = 0.3L;
    int n = 30;
    int[] observ = new int[100_000];
    foreach(ref elem; observ)
    elem = rNegBinom(n, p);
    writeln("100k samples from neg. binom.(", n,", ",  p, "):");
    writeln("\tMean Expected: ", n * (1 - p) / p,
            "  Observed:  ", mean(observ));
    writeln("\tMedian Expected: ??  Observed:  ", median(observ));
    writeln("\tStdev Expected:  ", sqrt(n * (1 - p) / (p * p)),
            "  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  ", (6 - p * (6 - p)) / (n * (1 - p)),
            "  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  ", (2 - p) / sqrt(n * (1 - p)),
            "  Observed:  ", skewness(observ));
    delete observ;
}

///
double rLaplace(RGen = Random)(double mu = 0, double b = 1, ref RGen gen = rndGen) {
    dstatsEnforce(b > 0, "b must be > 0 for Laplace distribution.");

    double p = uniform(0.0L, 1.0L, gen);
    return invLaplaceCDF(p, mu, b);
}

unittest {
    Random gen;
    gen.seed(unpredictableSeed);
    double[] observ = new double[100_000];
    foreach(ref elem; observ)
    elem = rLaplace();
    auto ksRes = ksTest(observ, parametrize!(laplaceCDF)(0.0L, 1.0L));
    writeln("100k samples from Laplace(0, 1):  K-S P-val:  ", ksRes.p);
    writeln("\tMean Expected: 0  Observed:  ", mean(observ));
    writeln("\tMedian Expected: 0  Observed:  ", median(observ));
    writeln("\tStdev Expected:  1.414  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  3  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  0  Observed:  ", skewness(observ));
    delete observ;
}

///
double rExponential(RGen = Random)(double lambda, ref RGen gen = rndGen) {
    dstatsEnforce(lambda > 0, "lambda must be > 0 for exponential distribution.");

    double p = uniform(0.0L, 1.0L, gen);
    return -log(p) / lambda;
}

unittest {
    double[] observ = new double[100_000];
    foreach(ref elem; observ)
    elem = rExponential(2.0L);
    auto ksRes = ksTest(observ, parametrize!(gammaCDF)(2, 1));
    writeln("100k samples from exponential(2):  K-S P-val:  ", ksRes.p);
    writeln("\tMean Expected: 0.5  Observed:  ", mean(observ));
    writeln("\tMedian Expected: 0.3465  Observed:  ", median(observ));
    writeln("\tStdev Expected:  0.5  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  6  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  2  Observed:  ", skewness(observ));
    delete observ;
}

private double stdGamma(RGen = Random)(double shape, ref RGen gen) {
    double b = void, c = void;
    double U = void, V = void, X = void, Y = void;

    if (shape == 1.0) {
        return rExponential(1.0, gen);
    } else if (shape < 1.0) {
        for (;;) {
            U = uniform(0.0L, 1.0, gen);
            V = rExponential(1.0, gen);
            if (U <= 1.0 - shape) {
                X = pow(U, 1.0/shape);
                if (X <= V) {
                    return X;
                }
            } else {
                Y = -log((1-U)/shape);
                X = pow(1.0 - shape + shape*Y, 1./shape);
                if (X <= (V + Y)) {
                    return X;
                }
            }
        }
    } else {
        b = shape - 1./3.;
        c = 1./sqrt(9*b);
        for (;;) {
            do {
                X = rNormal(0.0L, 1.0L, gen);
                V = 1.0 + c*X;
            } while (V <= 0.0);

            V = V*V*V;
            U = uniform(0.0L, 1.0L, gen);
            if (U < 1.0 - 0.0331*(X*X)*(X*X)) return (b*V);
            if (log(U) < 0.5*X*X + b*(1. - V + log(V))) return (b*V);
        }
    }
}

///
double rGamma(RGen = Random)(double a, double b, ref RGen gen = rndGen) {
    dstatsEnforce(a > 0, "a must be > 0 for gamma distribution.");
    dstatsEnforce(b > 0, "b must be > 0 for gamma distribution.");

    return stdGamma(b, gen) / a;
}

unittest {
    double[] observ = new double[100_000];
    foreach(ref elem; observ)
    elem = rGamma(2.0L, 3.0L);
    auto ksRes = ksTest(observ, parametrize!(gammaCDF)(2, 3));
    writeln("100k samples from gamma(2, 3):  K-S P-val:  ", ksRes.p);
    writeln("\tMean Expected: 1.5  Observed:  ", mean(observ));
    writeln("\tMedian Expected: ??  Observed:  ", median(observ));
    writeln("\tStdev Expected:  0.866  Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  2  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  1.15  Observed:  ", skewness(observ));
    delete observ;
}

///
double rBeta(RGen = Random)(double a, double b, ref RGen gen = rndGen) {
    dstatsEnforce(a > 0, "a must be > 0 for beta distribution.");
    dstatsEnforce(b > 0, "b must be > 0 for beta distribution.");

    double Ga = void, Gb = void;

    if ((a <= 1.0) && (b <= 1.0)) {
        double U, V, X, Y;
        /* Use Jonk's algorithm */

        while (1) {
            U = uniform(0.0L, 1.0L, gen);
            V = uniform(0.0L, 1.0L, gen);
            X = pow(U, 1.0/a);
            Y = pow(V, 1.0/b);

            if ((X + Y) <= 1.0) {
                return X / (X + Y);
            }
        }
    } else {
        Ga = stdGamma(a, gen);
        Gb = stdGamma(b, gen);
        return Ga/(Ga + Gb);
    }
    assert(0);
}

unittest {
    double delegate(double) paramBeta(double a, double b) {
        double parametrizedBeta(double x) {
            return betaIncomplete(a, b, x);
        }
        return &parametrizedBeta;
    }

    static double betaStdev(double a, double b) {
        return sqrt(a * b / ((a + b) * (a + b) * (a + b + 1)));
    }

    static double betaSkew(double a, double b) {
        auto numer = 2 * (b - a) * sqrt(a + b + 1);
        auto denom = (a + b + 2) * sqrt(a * b);
        return numer / denom;
    }

    static double betaKurtosis(double a, double b) {
        double numer = a * a * a - a * a * (2 * b - 1) + b * b * (b + 1) - 2 * a * b * (b + 2);
        double denom = a * b * (a + b + 2) * (a + b + 3);
        return 6 * numer / denom;
    }

    void testBeta(double a, double b) {
        double[] observ = new double[100_000];
        foreach(ref elem; observ)
        elem = rBeta(a, b);
        auto ksRes = ksTest(observ, paramBeta(a, b));
        auto summ = summary(observ);
        writeln("100k samples from beta(", a, ", ", b, "):  K-S P-val:  ", ksRes.p);
        writeln("\tMean Expected: ", a / (a + b), " Observed:  ", summ.mean);
        writeln("\tMedian Expected: ??  Observed:  ", median(observ));
        writeln("\tStdev Expected:  ", betaStdev(a, b), "  Observed:  ", summ.stdev);
        writeln("\tKurtosis Expected:  ", betaKurtosis(a, b), "  Observed:  ", summ.kurtosis);
        writeln("\tSkewness Expected:  ", betaSkew(a, b), "  Observed:  ", summ.skewness);
        delete observ;
    }

    testBeta(0.5, 0.7);
    testBeta(5, 3);
}

///
double rLogistic(RGen = Random)(double loc, double scale, ref RGen gen = rndGen) {
    dstatsEnforce(scale > 0, "scale must be > 0 for logistic distribution.");

    double U = uniform(0.0L, 1.0L, gen);
    return loc + scale * log(U/(1.0 - U));
}

unittest {
    double[] observ = new double[100_000];
    foreach(ref elem; observ)
    elem = rLogistic(2.0L, 3.0L);
    auto ksRes = ksTest(observ, parametrize!(logisticCDF)(2, 3));
    writeln("100k samples from logistic(2, 3):  K-S P-val:  ", ksRes.p);
    writeln("\tMean Expected: 2  Observed:  ", mean(observ));
    writeln("\tMedian Expected: 2  Observed:  ", median(observ));
    writeln("\tStdev Expected:  ", PI * PI * 3, " Observed:  ", stdev(observ));
    writeln("\tKurtosis Expected:  1.2  Observed:  ", kurtosis(observ));
    writeln("\tSkewness Expected:  0  Observed:  ", skewness(observ));
    delete observ;
}

///
double rLogNormal(RGen = Random)(double mu, double sigma, ref RGen gen = rndGen) {
    dstatsEnforce(sigma > 0, "sigma must be > 0 for log-normal distribution.");

    return exp(rNormal(mu, sigma, gen));
}

unittest {
    auto observ = randArray!rLogNormal(100_000, -2, 1);
    auto ksRes = ksTest(observ, paramFunctor!(logNormalCDF)(-2, 1));

    auto summ = summary(observ);
    writeln("100k samples from log-normal(-2, 1):  K-S P-val:  ", ksRes.p);
    writeln("\tMean Expected: ", exp(-1.5), "  Observed:  ", summ.mean);
    writeln("\tMedian Expected: ", exp(-2.0L), "  Observed:  ", median(observ));
    writeln("\tStdev Expected:  ", sqrt((exp(1.) - 1) * exp(-4.0L + 1)),
            " Observed:  ", summ.stdev);
    writeln("\tKurtosis Expected:  ?? Observed:  ", summ.kurtosis);
    writeln("\tSkewness Expected:  ", (exp(1.) + 2) * sqrt(exp(1.) - 1),
            " Observed:  ", summ.skewness);
}

///
double rWeibull(RGen = Random)(double shape, double scale = 1, ref RGen gen = rndGen) {
    dstatsEnforce(shape > 0, "shape must be > 0 for weibull distribution.");
    dstatsEnforce(scale > 0, "scale must be > 0 for weibull distribution.");

    return pow(rExponential(1, gen), 1. / shape) * scale;
}

unittest {
    double[] observ = new double[100_000];
    foreach(ref elem; observ)
    elem = rWeibull(2.0L, 3.0L);
    auto ksRes = ksTest(observ, parametrize!(weibullCDF)(2.0, 3.0));
    writeln("100k samples from weibull(2, 3):  K-S P-val:  ", ksRes.p);
    delete observ;
}

///
double rWald(RGen = Random)(double mu, double lambda, ref RGen gen = rndGen) {
    dstatsEnforce(mu > 0, "mu must be > 0 for Wald distribution.");
    dstatsEnforce(lambda > 0, "lambda must be > 0 for Wald distribution.");

    alias mu mean;
    alias lambda scale;

    double mu_2l = mean / (2*scale);
    double Y = rNormal(0, 1, gen);
    Y = mean*Y*Y;
    double X = mean + mu_2l*(Y - sqrt(4*scale*Y + Y*Y));
    double U = uniform(0.0L, 1.0L, gen);
    if (U <= mean/(mean+X)) {
        return X;
    } else

    {
        return mean*mean/X;
    }
}

unittest {
    auto observ = randArray!rWald(100_000, 4, 7);
    auto ksRes = ksTest(observ, parametrize!(waldCDF)(4, 7));

    auto summ = summary(observ);
    writeln("100k samples from wald(4, 7):  K-S P-val:  ", ksRes.p);
    writeln("\tMean Expected: ", 4, "  Observed:  ", summ.mean);
    writeln("\tMedian Expected: ??  Observed:  ", median(observ));
    writeln("\tStdev Expected:  ", sqrt(64.0 / 7), " Observed:  ", summ.stdev);
    writeln("\tKurtosis Expected:  ", 15.0 * 4 / 7, " Observed:  ", summ.kurtosis);
    writeln("\tSkewness Expected:  ", 3 * sqrt(4.0 / 7), " Observed:  ", summ.skewness);
}

///
double rRayleigh(RGen = Random)(double mode, ref RGen gen = rndGen) {
    dstatsEnforce(mode > 0, "mode must be > 0 for Rayleigh distribution.");

    return mode*sqrt(-2.0 * log(1.0 - uniform(0.0L, 1.0L, gen)));
}

unittest {
    auto observ = randArray!rRayleigh(100_000, 3);
    auto ksRes = ksTest(observ, parametrize!(rayleighCDF)(3));
    writeln("100k samples from rayleigh(3):  K-S P-val:  ", ksRes.p);
}

deprecated {
    alias rNorm = rNormal;
    alias rLogNorm = rLogNormal;
    alias rStudentT = rStudentsT;
}
