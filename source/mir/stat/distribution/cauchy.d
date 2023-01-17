/++
This module contains algorithms for the Cauchy probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2023 Mir Stat Authors.

+/

module mir.stat.distribution.cauchy;

import mir.internal.utility: isFloatingPoint;
import mir.math.common: log;
import mir.math.constant: PI;

enum real LOGPI = log(PI);

/++
Computes the Cauchy probability distribution function (PDF).

Params:
    x = value to evaluate PDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Cauchy_distribution, Cauchy distribution)
+/
T cauchyPDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.constant: M_1_PI;

    return T(M_1_PI) / (1 + x * x);
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate PDF
    x0 = location parameter
    gamma = scale parameter
+/
T cauchyPDF(T)(const T x, const T x0, const T gamma)
    if (isFloatingPoint!T)
    in (gamma > 0, "gamma must be greater than zero")
{
    return cauchyPDF((x - x0) / gamma) / gamma;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    cauchyPDF(-3.0).shouldApprox == 0.03183099;
    cauchyPDF(-2.0).shouldApprox == 0.06366198;
    cauchyPDF(-1.0).shouldApprox == 0.1591549;
    cauchyPDF(0.0).shouldApprox == 0.3183099;
    cauchyPDF(1.0).shouldApprox == 0.1591549;
    cauchyPDF(2.0).shouldApprox == 0.06366198;
    cauchyPDF(3.0).shouldApprox == 0.03183099;

    // Can include location/scale
    cauchyPDF(-3.0, 1, 2).shouldApprox == 0.03183099;
    cauchyPDF(-2.0, 1, 2).shouldApprox == 0.04897075;
    cauchyPDF(-1.0, 1, 2).shouldApprox == 0.07957747;
    cauchyPDF(0.0, 1, 2).shouldApprox == 0.127324;
    cauchyPDF(1.0, 1, 2).shouldApprox == 0.1591549;
    cauchyPDF(2.0, 1, 2).shouldApprox == 0.127324;
    cauchyPDF(3.0, 1, 2).shouldApprox == 0.07957747;
}

/++
Computes the Cauchy cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Cauchy_distribution, Cauchy distribution)
+/
T cauchyCDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.constant: M_1_PI;
    import std.math.trigonometry: atan;

    return 0.5 + T(M_1_PI) * atan(x);
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate CDF
    x0 = location parameter
    gamma = scale parameter
+/
T cauchyCDF(T)(const T x, const T x0, const T gamma)
    if (isFloatingPoint!T)
    in (gamma > 0, "gamma must be greater than zero")
{
    return cauchyCDF((x - x0) / gamma);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    cauchyCDF(-3.0).shouldApprox == 0.1024164;
    cauchyCDF(-2.0).shouldApprox == 0.1475836;
    cauchyCDF(-1.0).shouldApprox == 0.25;
    cauchyCDF(0.0).shouldApprox == 0.5;
    cauchyCDF(1.0).shouldApprox == 0.75;
    cauchyCDF(2.0).shouldApprox == 0.8524164;
    cauchyCDF(3.0).shouldApprox == 0.8975836;

    // Can include location/scale
    cauchyCDF(-3.0, 1, 2).shouldApprox == 0.1475836;
    cauchyCDF(-2.0, 1, 2).shouldApprox == 0.187167;
    cauchyCDF(-1.0, 1, 2).shouldApprox == 0.25;
    cauchyCDF(0.0, 1, 2).shouldApprox == 0.3524164;
    cauchyCDF(1.0, 1, 2).shouldApprox == 0.5;
    cauchyCDF(2.0, 1, 2).shouldApprox == 0.6475836;
    cauchyCDF(3.0, 1, 2).shouldApprox == 0.75;
}

/++
Computes the Cauchy complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Cauchy_distribution, Cauchy distribution)
+/
T cauchyCCDF(T)(const T x)
    if (isFloatingPoint!T)
{
    return cauchyCDF(-x);
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate CCDF
    x0 = location parameter
    gamma = scale parameter
+/
T cauchyCCDF(T)(const T x, const T x0, const T gamma)
    if (isFloatingPoint!T)
    in (gamma > 0, "gamma must be greater than zero")
{
    return cauchyCDF((x0 - x) / gamma);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    cauchyCCDF(-3.0).shouldApprox == 0.8975836;
    cauchyCCDF(-2.0).shouldApprox == 0.8524164;
    cauchyCCDF(-1.0).shouldApprox == 0.75;
    cauchyCCDF(0.0).shouldApprox == 0.5;
    cauchyCCDF(1.0).shouldApprox == 0.25;
    cauchyCCDF(2.0).shouldApprox == 0.1475836;
    cauchyCCDF(3.0).shouldApprox == 0.1024164;

    // Can include location/scale
    cauchyCCDF(-3.0, 1, 2).shouldApprox == 0.8524164;
    cauchyCCDF(-2.0, 1, 2).shouldApprox == 0.812833;
    cauchyCCDF(-1.0, 1, 2).shouldApprox == 0.75;
    cauchyCCDF(0.0, 1, 2).shouldApprox == 0.6475836;
    cauchyCCDF(1.0, 1, 2).shouldApprox == 0.5;
    cauchyCCDF(2.0, 1, 2).shouldApprox == 0.3524164;
    cauchyCCDF(3.0, 1, 2).shouldApprox == 0.25;
}

/++
Computes the Cauchy inverse cumulative distribution function (InvCDF).

Params:
    x = value to evaluate InvCDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Cauchy_distribution, Cauchy distribution)
+/
T cauchyInvCDF(T)(const T p)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.math.constant: PI;
    import std.math.trigonometry: tan;

    if (p > 0 && p < 1) {
        return tan(T(PI) * (p - 0.5));
    } else if (p == 0) {
        return -T.infinity;
    } else if (p == 1) {
        return T.infinity;
    }
    assert(0, "Should not be here");
}

/++
Ditto, with location and scale parameters.

Params:
    p = value to evaluate CCDF
    x0 = location parameter
    gamma = scale parameter
+/
T cauchyInvCDF(T)(const T p, const T x0, const T gamma)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in (gamma > 0, "gamma must be greater than zero")
{
     return x0 + gamma * cauchyInvCDF(p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    cauchyInvCDF(0.0).shouldApprox == -double.infinity;
    cauchyInvCDF(0.1).shouldApprox == -3.077684;
    cauchyInvCDF(0.2).shouldApprox == -1.376382;
    cauchyInvCDF(0.3).shouldApprox == -0.7265425;
    cauchyInvCDF(0.4).shouldApprox == -0.3249197;
    cauchyInvCDF(0.5).shouldApprox == 0.0;
    cauchyInvCDF(0.6).shouldApprox == 0.3249197;
    cauchyInvCDF(0.7).shouldApprox == 0.7265425;
    cauchyInvCDF(0.8).shouldApprox == 1.376382;
    cauchyInvCDF(0.9).shouldApprox == 3.077684;
    cauchyInvCDF(1.0).shouldApprox == double.infinity;

    // Can include location/scale
    cauchyInvCDF(0.2, 1, 2).shouldApprox == -1.752764;
    cauchyInvCDF(0.4, 1, 2).shouldApprox == 0.3501606;
    cauchyInvCDF(0.6, 1, 2).shouldApprox == 1.649839;
    cauchyInvCDF(0.8, 1, 2).shouldApprox == 3.752764;
}

/++
Computes the Cauchy log probability distribution function (LPDF).

Params:
    x = value to evaluate LPDF

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Cauchy_distribution, Cauchy distribution)
+/
T cauchyLPDF(T)(const T x)
    if (isFloatingPoint!T)
{
    return -T(LOGPI) - log(1 + x * x);
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate LPDF
    x0 = location parameter
    gamma = scale parameter
+/
T cauchyLPDF(T)(const T x, const T x0, const T gamma)
    if (isFloatingPoint!T)
    in (gamma > 0, "gamma must be greater than zero")
{
    import mir.math.common: log;

    return cauchyLPDF((x - x0) / gamma) - log(gamma);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: log;
    import mir.test: shouldApprox;

    cauchyLPDF(-3.0).shouldApprox == log(0.03183099);
    cauchyLPDF(-2.0).shouldApprox == log(0.06366198);
    cauchyLPDF(-1.0).shouldApprox == log(0.1591549);
    cauchyLPDF(0.0).shouldApprox == log(0.3183099);
    cauchyLPDF(1.0).shouldApprox == log(0.1591549);
    cauchyLPDF(2.0).shouldApprox == log(0.06366198);
    cauchyLPDF(3.0).shouldApprox == log(0.03183099);

    // Can include location/scale
    cauchyLPDF(-3.0, 1, 2).shouldApprox == log(0.03183099);
    cauchyLPDF(-2.0, 1, 2).shouldApprox == log(0.04897075);
    cauchyLPDF(-1.0, 1, 2).shouldApprox == log(0.07957747);
    cauchyLPDF(0.0, 1, 2).shouldApprox == log(0.127324);
    cauchyLPDF(1.0, 1, 2).shouldApprox == log(0.1591549);
    cauchyLPDF(2.0, 1, 2).shouldApprox == log(0.127324);
    cauchyLPDF(3.0, 1, 2).shouldApprox == log(0.07957747);
}
