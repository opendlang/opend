/++
This module contains algorithms for the gamma distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: Ilia Ki, John Michael Hall

Copyright: 2022 Mir Stat Authors.
+/

module mir.stat.distribution.gamma;

import mir.internal.utility: isFloatingPoint;

/++
Computes the gamma probability density function (PDF).

`shape` values less than `1` are supported when it is a floating point type.

If `shape is passed as a `size_t` type (or a type convertible to that), then the
PDF is calculated using the relationship with the poisson distribution (i.e.
replacing the `gamma` function with the `factorial`).

Params:
    x = value to evaluate PDF
    shape = shape parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Gamma_distribution, gamma probability distribution)
+/
auto gammaPDF(T)(const T x, const T shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import mir.math.common: exp, pow;
    import std.mathspecial: gamma;
    
    if (x == 0) {
        if (shape > 1) {
            return 0;
        } else if (shape < 1) {
            return T.infinity;
        } else {
            return T(1.0) / scale;
        }
    }

    T x_scale = x / scale;
    return exp(-x_scale) * pow(x_scale, shape - 1) / (cast(T) gamma(shape)) / scale;
}

/// ditto
auto gammaPDF(T)(const T x, const size_t shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import mir.stat.distribution.poisson: poissonPMF;

    if (x == 0) {
        if (shape > 1) {
            return 0;
        } else {
            return T(1.0) / scale;
        }
    }

    return poissonPMF!"direct"(shape - 1, x / scale) / scale;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    2.0.gammaPDF(3.0).shouldApprox == 0.2706706;
    2.0.gammaPDF(3.0, 4.0).shouldApprox == 0.01895408;
    // Calling with `size_t` uses factorial function instead of gamma, but
    // produces same results
    2.0.gammaPDF(3).shouldApprox == 2.0.gammaPDF(3.0);
    2.0.gammaPDF(3, 4.0).shouldApprox == 2.0.gammaPDF(3.0, 4.0);
}

//
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: should, shouldApprox;

    // check integer, x = 0
    0.0.gammaPDF(2).should == 0;
    0.0.gammaPDF(1).should == 1;
    0.0.gammaPDF(1, 4).shouldApprox == 0.25;

    // check float, x = 0
    0.0.gammaPDF(2.0).should == 0;
    0.0.gammaPDF(1.0).should == 1;
    0.0.gammaPDF(0.5).should == double.infinity;
    0.0.gammaPDF(2.0, 4.0).should == 0;
    0.0.gammaPDF(1.0, 4.0).shouldApprox == 0.25;
    0.0.gammaPDF(0.5, 4.0).should == double.infinity;

    // check integer
    0.5.gammaPDF(3).shouldApprox == 0.07581633;
    3.5.gammaPDF(4, 2.5).shouldApprox == 0.0451108;

    // check float, shape >= 1
    1.25.gammaPDF(1.0).shouldApprox == 0.2865048;
    1.25.gammaPDF(1.0, 0.5).shouldApprox == 0.16417;
    1.5.gammaPDF(2.5, 0.5).shouldApprox == 0.3892174;

    // check float, shape < 1
    0.005.gammaPDF(0.01).shouldApprox == 1.898102;
    1.5.gammaPDF(0.25).shouldApprox == 0.04540553;
    3.0.gammaPDF(0.5, 2.0).shouldApprox == 0.05139344;
}

/++
Computes the gamma cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF
    shape = shape parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Gamma_distribution, gamma probability distribution)
+/
@safe pure nothrow @nogc
T gammaCDF(T)(const T x, const T shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import std.mathspecial: gammaIncomplete;
    return gammaIncomplete(shape, x / scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    2.0.gammaCDF(5).shouldApprox == 0.05265302;
    1.0.gammaCDF(5, 0.5).shouldApprox == 0.05265302;
}

// checking some more extreme values for shape and others
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;
    0.5.gammaCDF(2, 1.5).shouldApprox == 0.04462492;
    0.25.gammaCDF(0.5, 4).shouldApprox == 0.276326;
    0.0625.gammaCDF(0.5).shouldApprox == 0.276326;
    0.0625.gammaCDF(2).shouldApprox == 0.001873621;
    0.00007854393.gammaCDF(0.5).shouldApprox == 0.01;
    10.gammaCDF(2, 1.5).shouldApprox == 0.9902431;
    5.gammaCDF(0.5, 1.5).shouldApprox == 0.9901767;
    6.666666.gammaCDF(2).shouldApprox == 0.9902431;
    3.333333.gammaCDF(0.5).shouldApprox == 0.9901767;
}

/++
Computes the gamma complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    shape = shape parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Gamma_distribution, gamma probability distribution)
+/
@safe pure nothrow @nogc
T gammaCCDF(T)(const T x, const T shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import std.mathspecial: gammaIncompleteCompl;
    return gammaIncompleteCompl(shape, x / scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    2.0.gammaCCDF(5).shouldApprox == 0.947347;
    1.0.gammaCCDF(5, 0.5).shouldApprox == 0.947347;
}

// checking some more extreme values for shape and others
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    0.5.gammaCCDF(2, 1.5).shouldApprox == 0.9553751;
    0.25.gammaCCDF(0.5, 4).shouldApprox == 0.7236736;
    0.0625.gammaCCDF(0.5).shouldApprox == 0.7236736;
    0.0625.gammaCCDF(2).shouldApprox == 0.9981264;
    0.00007854393.gammaCCDF(0.5).shouldApprox == 0.99;
    10.gammaCCDF(2, 1.5).shouldApprox == 0.009756859;
    5.gammaCCDF(0.5, 1.5).shouldApprox == 0.009823275;
    6.666666.gammaCCDF(2).shouldApprox == 0.009756865;
    3.333333.gammaCCDF(0.5).shouldApprox == 0.009823278;
}

/++
Computes the gamma inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate InvCDF
    shape = shape parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Gamma_distribution, gamma probability distribution)
+/

@safe pure nothrow @nogc
T gammaInvCDF(T)(const T p, const T shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import std.mathspecial: gammaIncompleteComplInverse;
    return gammaIncompleteComplInverse(shape, 1 - p) * scale;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    0.05.gammaInvCDF(5).shouldApprox == 1.97015;
    0.05.gammaInvCDF(5, 0.5).shouldApprox == 0.9850748;
}

// checking some more extreme values for shape and others
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;
    0.04.gammaInvCDF(2, 1.5).shouldApprox == 0.4703589;
    0.27.gammaInvCDF(0.5, 4).shouldApprox == 0.2382233;
    0.27.gammaInvCDF(0.5).shouldApprox == 0.05955582;
    0.002.gammaInvCDF(2).shouldApprox == 0.06461886;
    0.01.gammaInvCDF(0.5).shouldApprox == 0.00007854393;
    0.99.gammaInvCDF(2, 1.5).shouldApprox == 9.957528;
    0.99.gammaInvCDF(0.5, 1.5).shouldApprox == 4.976172;
    0.99.gammaInvCDF(2).shouldApprox == 6.638352;
    0.99.gammaInvCDF(0.5).shouldApprox == 3.317448;
}

// confirming consistency with gammaCDF
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    2.0.gammaCDF(5).gammaInvCDF(5).shouldApprox == 2;
    1.0.gammaCDF(5, 0.5).gammaInvCDF(5, 0.5).shouldApprox == 1;
    0.5.gammaCDF(2, 1.5).gammaInvCDF(2, 1.5).shouldApprox == 0.5;
    0.5.gammaCDF(2, 1.5).gammaInvCDF(2, 1.5).shouldApprox == 0.5;
    0.25.gammaCDF(0.5, 4).gammaInvCDF(0.5, 4).shouldApprox == 0.25;
    0.0625.gammaCDF(0.5).gammaInvCDF(0.5).shouldApprox == 0.0625;
    0.0625.gammaCDF(2).gammaInvCDF(2).shouldApprox == 0.0625;
    0.00007854393.gammaCDF(0.5).gammaInvCDF(0.5).shouldApprox == 0.00007854393;
    10.gammaCDF(2, 1.5).gammaInvCDF(2, 1.5).shouldApprox == 10;
    5.gammaCDF(0.5, 1.5).gammaInvCDF(0.5, 1.5).shouldApprox == 5;
    6.666666.gammaCDF(2).gammaInvCDF(2).shouldApprox == 6.666666;
    3.333333.gammaCDF(0.5).gammaInvCDF(0.5).shouldApprox == 3.333333;
}

/++
Computes the gamma log probability density function (LPDF).

`shape` values less than `1` are supported when it is a floating point type.

If `shape is passed as a `size_t` type (or a type convertible to that), then the
LPDF is calculated using the relationship with the poisson distribution (i.e.
replacing the `logGamma` function with the `logFactorial`).

Params:
    x = value to evaluate LPDF
    shape = shape parameter
    scale = scale parameter

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Gamma_distribution, gamma probability distribution)
+/
@safe pure nothrow @nogc
T gammaLPDF(T)(const T x, const T shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import mir.math.common: log;
    import std.mathspecial: logGamma;

    if (x == 0) {
        if (shape > 1) {
            return -T.infinity;
        } else if (shape < 1) {
            return T.infinity;
        } else {
            return -log(scale);
        }
    }

    T x_scale = x / scale;
    return (shape - 1) * log(x_scale) - x_scale - cast(T) logGamma(shape) - log(scale);
}

/// ditto
@safe pure nothrow @nogc
T gammaLPDF(T)(const T x, const size_t shape, const T scale = 1)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (shape > 0, "shape must be greater than zero")
    in (scale > 0, "scale must be greater than zero")
{
    import mir.math.common: log;
    import mir.stat.distribution.poisson: poissonLPMF;

    if (x == 0) {
        if (shape > 1) {
            return -T.infinity;
        } else if (shape < 1) {
            return T.infinity;
        } else {
            return -log(scale);
        }
    }

    return poissonLPMF(shape - 1, x / scale) - log(scale);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test: shouldApprox;

    2.0.gammaLPDF(3.0).shouldApprox == -1.306853;
    2.0.gammaLPDF(3.0, 4.0).shouldApprox == -3.965736;
    // Calling with `size_t` uses log factorial function instead of log gamma,
    // but produces same results
    2.0.gammaLPDF(3).shouldApprox == 2.0.gammaLPDF(3.0);
    2.0.gammaLPDF(3, 4.0).shouldApprox == 2.0.gammaLPDF(3.0, 4.0);
}

// test floating point version
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: exp;
    import mir.test: shouldApprox;

    for (double x = 0; x <= 10; x = x + 0.5) {
        x.gammaLPDF(5.0).exp.shouldApprox == x.gammaPDF(5.0);
        x.gammaLPDF(5.0, 1.5).exp.shouldApprox == x.gammaPDF(5.0, 1.5);
        x.gammaLPDF(1.0).exp.shouldApprox == x.gammaPDF(1.0);
        x.gammaLPDF(1.0, 1.5).exp.shouldApprox == x.gammaPDF(1.0, 1.5);
        x.gammaLPDF(0.5).exp.shouldApprox == x.gammaPDF(0.5);
        x.gammaLPDF(0.5, 1.5).exp.shouldApprox == x.gammaPDF(0.5, 1.5);
    }
}

// test size_t version
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: exp;
    import mir.test: shouldApprox;

    for (double x = 0; x <= 10; x = x + 0.5) {
        x.gammaLPDF(5).exp.shouldApprox == x.gammaPDF(5);
        x.gammaLPDF(5, 1.5).exp.shouldApprox == x.gammaPDF(5, 1.5);
        x.gammaLPDF(1).exp.shouldApprox == x.gammaPDF(1);
        x.gammaLPDF(1, 1.5).exp.shouldApprox == x.gammaPDF(1, 1.5);
    }
}
