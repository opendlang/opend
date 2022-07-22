/++
This module contains algorithms for the geometric probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.geometric;

import mir.internal.utility: isFloatingPoint;

/++
Computes the geometric probability density function (PMF).

Params:
    k = value to evaluate PMF
    p = `true` probability

See_also: $(LINK2 https://en.wikipedia.org/wiki/Geometric_distribution, geometric probability distribution)
+/
@safe pure @nogc nothrow
T geometricPMF(T)(const size_t k, const T p)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: pow;
    return pow(1 - p, k) * p;   
}

///
@safe pure @nogc nothrow
version(mir_stat_test)
unittest
{
    import mir.test: shouldApprox;

    0.geometricPMF(0.5).shouldApprox == 0.5;
    1.geometricPMF(0.5).shouldApprox == 0.25;
    2.geometricPMF(0.25).shouldApprox == 0.140625;
}

/++
Computes the geometric cumulative density function (CDF).

Params:
    k = value to evaluate CDF
    p = `true` probability

See_also: $(LINK2 https://en.wikipedia.org/wiki/Geometric_distribution, geometric probability distribution)
+/
@safe pure @nogc nothrow
T geometricCDF(T)(const size_t k, const T p)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: pow;
    return 1 - pow(1 - p, k + 1);   
}

/// ditto
@safe pure @nogc nothrow
T geometricCDF(T)(const T x, const T p)
    if (isFloatingPoint!T)
    in (x >= -1, "x must be larger than or equal to -1")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    if (x < 0)
        return 0;
    return geometricCDF!T(cast(const size_t) x, p);  
}

///
@safe pure @nogc nothrow
version(mir_stat_test)
unittest
{
    import mir.test: shouldApprox;

	geometricCDF(-1.0, 0.5).shouldApprox == 0; // UFCS chaining deduces this as size_t instead of a floating point type
    0.geometricCDF(0.5).shouldApprox == 0.5;
    1.geometricCDF(0.5).shouldApprox == 0.75;
    2.geometricCDF(0.5).shouldApprox == 0.875;

    geometricCDF(-1.0, 0.25).shouldApprox == 0; // UFCS chaining deduces this as size_t instead of a floating point type
    0.geometricCDF(0.25).shouldApprox == 0.25;
    1.geometricCDF(0.25).shouldApprox == 0.4375;
    2.geometricCDF(0.25).shouldApprox == 0.578125;
    2.5.geometricCDF(0.25).shouldApprox == 0.578125;
}

/++
Computes the geometric complementary cumulative density function (CCDF).

Params:
    k = value to evaluate CCDF
    p = `true` probability

See_also: $(LINK2 https://en.wikipedia.org/wiki/Geometric_distribution, geometric probability distribution)
+/
@safe pure @nogc nothrow
T geometricCCDF(T)(const size_t k, const T p)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: pow;
    return pow(1 - p, k + 1);   
}

/// ditto
@safe pure @nogc nothrow
T geometricCCDF(T)(const T x, const T p)
    if (isFloatingPoint!T)
    in (x >= -1, "x must be larger than or equal to -1")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    if (x < 0)
        return 1;
    return geometricCCDF!T(cast(const size_t) x, p);  
}

///
@safe pure @nogc nothrow
version(mir_stat_test)
unittest
{
    import mir.test: shouldApprox;

	geometricCCDF(-1.0, 0.5).shouldApprox == 1.0; // UFCS chaining deduces this as size_t instead of a floating point type
    0.geometricCCDF(0.5).shouldApprox == 0.5;
    1.geometricCCDF(0.5).shouldApprox == 0.25;
    2.geometricCCDF(0.5).shouldApprox == 0.125;

    geometricCCDF(-1.0, 0.25).shouldApprox == 1.0; // UFCS chaining deduces this as size_t instead of a floating point type
    0.geometricCCDF(0.25).shouldApprox == 0.75;
    1.geometricCCDF(0.25).shouldApprox == 0.5625;
    2.geometricCCDF(0.25).shouldApprox == 0.421875;
    2.5.geometricCCDF(0.25).shouldApprox == 0.421875;
}

/++
Computes the geometric inverse cumulative distribution function (InvCDF).

Params:
    prob = value to evaluate InvCDF
    p = `true` probability

See_also: $(LINK2 https://en.wikipedia.org/wiki/Geometric_distribution, geometric probability distribution)
+/
@safe pure @nogc nothrow
T geometricInvCDF(T)(const T prob, const T p)
    if (isFloatingPoint!T)
    in (prob >= 0, "prob must be greater than or equal to 0")
    in (prob <= 1, "prob must be less than or equal to 1")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: approxEqual, ceil, nearbyint, log;
    if (prob == 1) {
        return T.infinity;
    }
    if (p == 1) {
        return 0;
    }
    T guess = log(1 - prob) / log(1 - p);
    T guessNearby = nearbyint(guess);
    if (approxEqual(guess, guessNearby, T.epsilon * 2)) {
        return guessNearby - 1;
    } else {
        return ceil(guess) - 1;
    }
}

///
@safe pure @nogc nothrow
version(mir_stat_test)
unittest
{
    import mir.test: should;

    0.geometricInvCDF(0.5).should == -1;
    0.5.geometricInvCDF(0.5).should == 0;
    0.75.geometricInvCDF(0.5).should == 1;
    0.875.geometricInvCDF(0.5).should == 2;
    0.95.geometricInvCDF(0.5).should == 4;

    0.geometricInvCDF(0.25).should == -1;
    0.25.geometricInvCDF(0.25).should == 0;
    0.4375.geometricInvCDF(0.25).should == 1;
    0.578125.geometricInvCDF(0.25).should == 2;
    0.95.geometricInvCDF(0.25).should == 10;

    0.5.geometricInvCDF(1).should == 0;
    1.geometricInvCDF(0.5).should == double.infinity;
}

/++
Computes the geometric log probability density function (LPMF).

Params:
    k = value to evaluate LPMF
    p = `true` probability

See_also: $(LINK2 https://en.wikipedia.org/wiki/Geometric_distribution, geometric probability distribution)
+/
@safe pure @nogc nothrow
T geometricLPMF(T)(const size_t k, const T p)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.common: log;
    import mir.math.internal.xlogy: xlog1py;
    return xlog1py(k, -p) + log(p);   
}

///
@safe pure @nogc nothrow
version(mir_stat_test)
unittest
{
    import mir.math.common: exp;
    import mir.test: shouldApprox;

    0.geometricLPMF(0.5).exp.shouldApprox == 0.geometricPMF(0.5);
    1.geometricLPMF(0.5).exp.shouldApprox == 1.geometricPMF(0.5);
    2.geometricLPMF(0.25).exp.shouldApprox == 2.geometricPMF(0.25);
}
