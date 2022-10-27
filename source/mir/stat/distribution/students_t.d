/++
This module contains algorithms for the Student's t probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.students_t;

import mir.internal.utility: isFloatingPoint;

import mir.math.constant: PI;
import mir.math.common: sqrt;

enum real SQRTPI = sqrt(PI);
enum real SQRTPIINV = 1 / SQRTPI;

/++
Computes the Student's t probability distribution function (PDF).

Params:
    x = value to evaluate PDF
    nu = degrees of freedom

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Student%27s_t-distribution, Student's t-distribution)
+/
@safe pure nothrow @nogc
T studentsTPDF(T)(const T x, const T nu)
    if (isFloatingPoint!T)
    in (nu > 0, "nu must be greater than zero")
{
    import mir.math.common: pow, sqrt;
    import mir.stat.distribution.normal: normalPDF;
    import std.mathspecial: gamma;

    if (nu != T.infinity) {
        return (gamma((nu + 1) * 0.5) / gamma(nu * 0.5)) / sqrt(nu) * T(SQRTPIINV) * pow(1 + (x * x) / nu, -(nu + 1) * 0.5);
    } else {
        return normalPDF(x);
    }
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate PDF
    nu = degrees of freedom
    mean = location parameter
    stdDev = scale parameter
+/
@safe pure nothrow @nogc
T studentsTPDF(T)(const T x, const T nu, const T mean, const T stdDev)
    if (isFloatingPoint!T)
    in (nu > 0, "nu must be greater than zero")
    in (stdDev > 0, "stdDev must be greater than zero")
{
    return studentsTPDF((x - mean) / stdDev, nu);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTPDF(-3.0, 5).shouldApprox == 0.01729258;
    studentsTPDF(-2.0, 5).shouldApprox == 0.06509031;
    studentsTPDF(-1.0, 5).shouldApprox == 0.2196798;
    studentsTPDF(0.0, 5).shouldApprox == 0.3796067;
    studentsTPDF(1.0, 5).shouldApprox == 0.2196798;
    studentsTPDF(2.0, 5).shouldApprox == 0.06509031;
    studentsTPDF(3.0, 5).shouldApprox == 0.01729258;

    // Can include location/scale
    studentsTPDF(-3.0, 5, 1, 2).shouldApprox == 0.06509031;
    studentsTPDF(-2.0, 5, 1, 2).shouldApprox == 0.1245173;
    studentsTPDF(-1.0, 5, 1, 2).shouldApprox == 0.2196798;
    studentsTPDF(0.0, 5, 1, 2).shouldApprox == 0.3279185;
    studentsTPDF(1.0, 5, 1, 2).shouldApprox == 0.3796067;
    studentsTPDF(2.0, 5, 1, 2).shouldApprox == 0.3279185;
    studentsTPDF(3.0, 5, 1, 2).shouldApprox == 0.2196798;
}

// Checking other DoF
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTPDF(-3.0, 25).shouldApprox == 0.007253748;
    studentsTPDF(-2.0, 25).shouldApprox == 0.0573607;
    studentsTPDF(-1.0, 25).shouldApprox == 0.237211;
    studentsTPDF(0.0, 25).shouldApprox == 0.3949738;
    studentsTPDF(1.0, 25).shouldApprox == 0.237211;
    studentsTPDF(2.0, 25).shouldApprox == 0.0573607;
    studentsTPDF(3.0, 25).shouldApprox == 0.007253748;

    studentsTPDF(-3.0, double.infinity).shouldApprox == 0.004431848;
    studentsTPDF(-2.0, double.infinity).shouldApprox == 0.05399097;
    studentsTPDF(-1.0, double.infinity).shouldApprox == 0.2419707;
    studentsTPDF(0.0, double.infinity).shouldApprox == 0.3989423;
    studentsTPDF(1.0, double.infinity).shouldApprox == 0.2419707;
    studentsTPDF(2.0, double.infinity).shouldApprox == 0.05399097;
    studentsTPDF(3.0, double.infinity).shouldApprox == 0.004431848;
}

// Checking negative location parameter
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTPDF(-3.0, 5, -1, 2).shouldApprox == 0.2196798;
    studentsTPDF(-2.0, 5, -1, 2).shouldApprox == 0.3279185;
    studentsTPDF(-1.0, 5, -1, 2).shouldApprox == 0.3796067;
    studentsTPDF(0.0, 5, -1, 2).shouldApprox == 0.3279185;
    studentsTPDF(1.0, 5, -1, 2).shouldApprox == 0.2196798;
    studentsTPDF(2.0, 5, -1, 2).shouldApprox == 0.1245173;
    studentsTPDF(3.0, 5, -1, 2).shouldApprox == 0.06509031;
}

/++
Computes the Student's t cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF
    nu = degrees of freedom

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Student%27s_t-distribution, Student's t-distribution)
+/
@safe pure nothrow @nogc
T studentsTCDF(T)(const T x, const T nu)
    if (isFloatingPoint!T)
    in (nu > 0, "nu must be greater than zero")
{
    import mir.stat.distribution.beta: betaCDF, betaCCDF;
    import mir.stat.distribution.normal: normalCDF;

    if (nu != T.infinity) {
        T output;
        if (nu > x * x) {
            output = betaCCDF(x * x / (nu + x * x), 0.5, 0.5 * nu);
        } else {
            output = betaCDF((nu / (nu + x * x)), 0.5 * nu, 0.5);
        }
        output *= 0.5;
        if (x > 0) {
            output = 1 - output;
        }
        return output;
    } else {
        return normalCDF(x);
    }
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate CDF
    nu = degrees of freedom
    mean = location parameter
    stdDev = scale parameter
+/
@safe pure nothrow @nogc
T studentsTCDF(T)(const T x, const T nu, const T mean, const T stdDev)
    if (isFloatingPoint!T)
    in (nu > 0, "nu must be greater than zero")
    in (stdDev > 0, "stdDev must be greater than zero")
{
    return studentsTCDF((x - mean) / stdDev, nu);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTCDF(-3.0, 5).shouldApprox == 0.01504962;
    studentsTCDF(-2.0, 5).shouldApprox == 0.05096974;
    studentsTCDF(-1.0, 5).shouldApprox == 0.1816087;
    studentsTCDF(0.0, 5).shouldApprox == 0.5;
    studentsTCDF(1.0, 5).shouldApprox == 0.8183913;
    studentsTCDF(2.0, 5).shouldApprox == 0.9490303;
    studentsTCDF(3.0, 5).shouldApprox == 0.9849504;

    // Can include location/scale
    studentsTCDF(-3.0, 5, 1, 2).shouldApprox == 0.05096974;
    studentsTCDF(-2.0, 5, 1, 2).shouldApprox == 0.09695184;
    studentsTCDF(-1.0, 5, 1, 2).shouldApprox == 0.1816087;
    studentsTCDF(0.0, 5, 1, 2).shouldApprox == 0.3191494;
    studentsTCDF(1.0, 5, 1, 2).shouldApprox == 0.5;
    studentsTCDF(2.0, 5, 1, 2).shouldApprox == 0.6808506;
    studentsTCDF(3.0, 5, 1, 2).shouldApprox == 0.8183913;
}

// Checking other DoF
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTCDF(-3.0, 25).shouldApprox == 0.00301909;
    studentsTCDF(-2.0, 25).shouldApprox == 0.02823799;
    studentsTCDF(-1.0, 25).shouldApprox == 0.163446;
    studentsTCDF(0.0, 25).shouldApprox == 0.5;
    studentsTCDF(1.0, 25).shouldApprox == 0.836554;
    studentsTCDF(2.0, 25).shouldApprox == 0.971762;
    studentsTCDF(3.0, 25).shouldApprox == 0.9969809;

    studentsTCDF(-3.0, double.infinity).shouldApprox == 0.001349898;
    studentsTCDF(-2.0, double.infinity).shouldApprox == 0.02275013;
    studentsTCDF(-1.0, double.infinity).shouldApprox == 0.1586553;
    studentsTCDF(0.0, double.infinity).shouldApprox == 0.5;
    studentsTCDF(1.0, double.infinity).shouldApprox == 0.8413447;
    studentsTCDF(2.0, double.infinity).shouldApprox == 0.9772499;
    studentsTCDF(3.0, double.infinity).shouldApprox == 0.9986501;
}

// Checking negative location parameter
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTCDF(-3.0, 5, -1, 2).shouldApprox == 0.1816087;
    studentsTCDF(-2.0, 5, -1, 2).shouldApprox == 0.3191494;
    studentsTCDF(-1.0, 5, -1, 2).shouldApprox == 0.5;
    studentsTCDF(0.0, 5, -1, 2).shouldApprox == 0.6808506;
    studentsTCDF(1.0, 5, -1, 2).shouldApprox == 0.8183913;
    studentsTCDF(2.0, 5, -1, 2).shouldApprox == 0.9030482;
    studentsTCDF(3.0, 5, -1, 2).shouldApprox == 0.9490303;
}

/++
Computes the Student's t complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    nu = degrees of freedom

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Student%27s_t-distribution, Student's t-distribution)
+/
@safe pure nothrow @nogc
T studentsTCCDF(T)(const T x, const T nu)
    if (isFloatingPoint!T)
    in (nu > 0, "nu must be greater than zero")
{
    import mir.stat.distribution.normal: normalCCDF;

    return studentsTCDF(-x, nu);
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate CCDF
    nu = degrees of freedom
    mean = location parameter
    stdDev = scale parameter
+/
@safe pure nothrow @nogc
T studentsTCCDF(T)(const T x, const T nu, const T mean, const T stdDev)
    if (isFloatingPoint!T)
    in (nu > 0, "nu must be greater than zero")
    in (stdDev > 0, "stdDev must be greater than zero")
{
    return studentsTCCDF((x - mean) / stdDev, nu);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTCCDF(-3.0, 5).shouldApprox == 0.9849504;
    studentsTCCDF(-2.0, 5).shouldApprox == 0.9490303;
    studentsTCCDF(-1.0, 5).shouldApprox == 0.8183913;
    studentsTCCDF(0.0, 5).shouldApprox == 0.5;
    studentsTCCDF(1.0, 5).shouldApprox == 0.1816087;
    studentsTCCDF(2.0, 5).shouldApprox == 0.05096974;
    studentsTCCDF(3.0, 5).shouldApprox == 0.01504962;

    // Can include location/scale
    studentsTCCDF(-3.0, 5, 1, 2).shouldApprox == 0.9490303;
    studentsTCCDF(-2.0, 5, 1, 2).shouldApprox == 0.9030482;
    studentsTCCDF(-1.0, 5, 1, 2).shouldApprox == 0.8183913;
    studentsTCCDF(0.0, 5, 1, 2).shouldApprox == 0.6808506;
    studentsTCCDF(1.0, 5, 1, 2).shouldApprox == 0.5;
    studentsTCCDF(2.0, 5, 1, 2).shouldApprox == 0.3191494;
    studentsTCCDF(3.0, 5, 1, 2).shouldApprox == 0.1816087;
}

// Checking other DoF
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTCCDF(-3.0, 25).shouldApprox == 0.9969809;
    studentsTCCDF(-2.0, 25).shouldApprox == 0.971762;
    studentsTCCDF(-1.0, 25).shouldApprox == 0.836554;
    studentsTCCDF(0.0, 25).shouldApprox == 0.5;
    studentsTCCDF(1.0, 25).shouldApprox == 0.163446;
    studentsTCCDF(2.0, 25).shouldApprox == 0.02823799;
    studentsTCCDF(3.0, 25).shouldApprox == 0.00301909;

    studentsTCCDF(-3.0, double.infinity).shouldApprox == 0.9986501;
    studentsTCCDF(-2.0, double.infinity).shouldApprox == 0.9772499;
    studentsTCCDF(-1.0, double.infinity).shouldApprox == 0.8413447;
    studentsTCCDF(0.0, double.infinity).shouldApprox == 0.5;
    studentsTCCDF(1.0, double.infinity).shouldApprox == 0.1586553;
    studentsTCCDF(2.0, double.infinity).shouldApprox == 0.02275013;
    studentsTCCDF(3.0, double.infinity).shouldApprox == 0.001349898;
}

// Checking negative location parameter
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTCCDF(-3.0, 5, -1, 2).shouldApprox == 0.8183913;
    studentsTCCDF(-2.0, 5, -1, 2).shouldApprox == 0.6808506;
    studentsTCCDF(-1.0, 5, -1, 2).shouldApprox == 0.5;
    studentsTCCDF(0.0, 5, -1, 2).shouldApprox == 0.3191494;
    studentsTCCDF(1.0, 5, -1, 2).shouldApprox == 0.1816087;
    studentsTCCDF(2.0, 5, -1, 2).shouldApprox == 0.09695184;
    studentsTCCDF(3.0, 5, -1, 2).shouldApprox == 0.05096974;
}

/++
Computes the Student's t inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate InvCDF
    nu = degrees of freedom

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Student%27s_t-distribution, Student's t-distribution)
+/
@safe pure nothrow @nogc
T studentsTInvCDF(T)(const T p, const T nu)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in (nu > 0, "nu must be greater than zero")
{
    import mir.math.common: sqrt;
    import mir.stat.distribution.beta: betaInvCDF;
    import mir.stat.distribution.normal: normalInvCDF;

    if (p == 0) {
        return -T.infinity;
    } else if (p == 1) {
        return T.infinity;
    } else if (nu != T.infinity) {
        byte output_sign = void;
        T p_new = void;
        T output = void;
        if (p > 0.25 && p < 0.75) {
            if (p == 0.5) {
                return 0;
            }
            output_sign = -1;
            p_new = 1 - 2 * p;
            if (p > 0.5) {
                output_sign = 1;
                p_new *= -1;
            }
            output = betaInvCDF(p_new, 0.5, 0.5 * nu);
            output = sqrt(nu * output / (1 - output));
        } else {
            output_sign = -1;
            p_new = p;
            if (p_new > 0.5) {
                output_sign = 1;
                p_new = 1 - p_new;
            }
            p_new *= 2;
            output = betaInvCDF(p_new, 0.5 * nu, 0.5);
            output = sqrt(nu / output - nu);
        }
        return output_sign * output;
    } else {
        return normalInvCDF(p);
    }
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    p = value to evaluate InvCDF
    nu = degrees of freedom
    mean = location parameter
    stdDev = scale parameter
+/
@safe pure nothrow @nogc
T studentsTInvCDF(T)(const T p, const T nu, const T mean, const T stdDev)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in (nu > 0, "nu must be greater than zero")
    in (stdDev > 0, "stdDev must be greater than zero")
{
    return mean + stdDev * studentsTInvCDF(p, nu);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTInvCDF(0.0, 5).shouldApprox == -double.infinity;
    studentsTInvCDF(0.1, 5).shouldApprox == -1.475884;
    studentsTInvCDF(0.2, 5).shouldApprox == -0.9195438;
    studentsTInvCDF(0.3, 5).shouldApprox == -0.5594296;
    studentsTInvCDF(0.4, 5).shouldApprox == -0.2671809;
    studentsTInvCDF(0.5, 5).shouldApprox == 0.0;
    studentsTInvCDF(0.6, 5).shouldApprox == 0.2671809;
    studentsTInvCDF(0.7, 5).shouldApprox == 0.5594296;
    studentsTInvCDF(0.8, 5).shouldApprox == 0.9195438;
    studentsTInvCDF(0.9, 5).shouldApprox == 1.475884;
    studentsTInvCDF(1.0, 5).shouldApprox == double.infinity;

    // Can include location/scale
    studentsTInvCDF(0.2, 5, 1, 2).shouldApprox == -0.8390876;
    studentsTInvCDF(0.4, 5, 1, 2).shouldApprox == 0.4656382;
    studentsTInvCDF(0.6, 5, 1, 2).shouldApprox == 1.534362;
    studentsTInvCDF(0.8, 5, 1, 2).shouldApprox == 2.839088;
}

// Checking other DoF
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTInvCDF(0.1, 25).shouldApprox == -1.316345;
    studentsTInvCDF(0.2, 25).shouldApprox == -0.8562362;
    studentsTInvCDF(0.3, 25).shouldApprox == -0.5311538;
    studentsTInvCDF(0.7, 25).shouldApprox == 0.5311538;
    studentsTInvCDF(0.8, 25).shouldApprox == 0.8562362;
    studentsTInvCDF(0.9, 25).shouldApprox == 1.316345;

    studentsTInvCDF(0.2, double.infinity).shouldApprox == -0.8416212;
    studentsTInvCDF(0.4, double.infinity).shouldApprox == -0.2533471;
    studentsTInvCDF(0.6, double.infinity).shouldApprox == 0.2533471;
    studentsTInvCDF(0.8, double.infinity).shouldApprox == 0.8416212;
}

// Checking negative location parameter
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    studentsTInvCDF(0.2, 5, -1, 2).shouldApprox == -2.839088;
    studentsTInvCDF(0.4, 5, -1, 2).shouldApprox == -1.534362;
    studentsTInvCDF(0.6, 5, -1, 2).shouldApprox == -0.4656383;
    studentsTInvCDF(0.8, 5, -1, 2).shouldApprox == 0.8390876;
}


/++
Computes the Student's t log probability distribution function (LPDF).

Params:
    x = value to evaluate LPDF
    nu = degrees of freedom

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Student%27s_t-distribution, Student's t-distribution)
+/
@safe pure nothrow @nogc
T studentsTLPDF(T)(const T x, const T nu)
    if (isFloatingPoint!T)
    in (nu > 0, "nu must be greater than zero")
{
    import mir.math.common: log;
    import mir.stat.distribution.normal: normalLPDF;
    import std.mathspecial: logGamma;

    if (nu != T.infinity) {
        return logGamma((nu + 1) * 0.5) - logGamma(nu * 0.5) - 0.5 * log(nu * T(PI)) - 0.5 * (nu + 1) * log(1 + (x * x) / nu);
    } else {
        return normalLPDF(x);
    }
}

/++
Ditto, with location and scale parameters (by standardizing `x`).

Params:
    x = value to evaluate LPDF
    nu = degrees of freedom
    mean = location parameter
    stdDev = scale parameter
+/
@safe pure nothrow @nogc
T studentsTLPDF(T)(const T x, const T nu, const T mean, const T stdDev)
    if (isFloatingPoint!T)
    in (nu > 0, "nu must be greater than zero")
    in (stdDev > 0, "stdDev must be greater than zero")
{
    return studentsTLPDF((x - mean) / stdDev, nu);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;
    import mir.math.common: log;

    studentsTLPDF(-3.0, 5).shouldApprox == log(0.01729258);
    studentsTLPDF(-2.0, 5).shouldApprox == log(0.06509031);
    studentsTLPDF(-1.0, 5).shouldApprox == log(0.2196798);
    studentsTLPDF(0.0, 5).shouldApprox == log(0.3796067);
    studentsTLPDF(1.0, 5).shouldApprox == log(0.2196798);
    studentsTLPDF(2.0, 5).shouldApprox == log(0.06509031);
    studentsTLPDF(3.0, 5).shouldApprox == log(0.01729258);

    // Can include location/scale
    studentsTLPDF(-3.0, 5, 1, 2).shouldApprox == log(0.06509031);
    studentsTLPDF(-2.0, 5, 1, 2).shouldApprox == log(0.1245173);
    studentsTLPDF(-1.0, 5, 1, 2).shouldApprox == log(0.2196798);
    studentsTLPDF(0.0, 5, 1, 2).shouldApprox == log(0.3279185);
    studentsTLPDF(1.0, 5, 1, 2).shouldApprox == log(0.3796067);
    studentsTLPDF(2.0, 5, 1, 2).shouldApprox == log(0.3279185);
    studentsTLPDF(3.0, 5, 1, 2).shouldApprox == log(0.2196798);
}

// Checking other DoF
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;
    import mir.math.common: log;

    studentsTLPDF(-3.0, 25).shouldApprox == log(0.007253748);
    studentsTLPDF(-2.0, 25).shouldApprox == log(0.0573607);
    studentsTLPDF(-1.0, 25).shouldApprox == log(0.237211);
    studentsTLPDF(0.0, 25).shouldApprox == log(0.3949738);
    studentsTLPDF(1.0, 25).shouldApprox == log(0.237211);
    studentsTLPDF(2.0, 25).shouldApprox == log(0.0573607);
    studentsTLPDF(3.0, 25).shouldApprox == log(0.007253748);

    studentsTLPDF(-3.0, double.infinity).shouldApprox == log(0.004431848);
    studentsTLPDF(-2.0, double.infinity).shouldApprox == log(0.05399097);
    studentsTLPDF(-1.0, double.infinity).shouldApprox == log(0.2419707);
    studentsTLPDF(0.0, double.infinity).shouldApprox == log(0.3989423);
    studentsTLPDF(1.0, double.infinity).shouldApprox == log(0.2419707);
    studentsTLPDF(2.0, double.infinity).shouldApprox == log(0.05399097);
    studentsTLPDF(3.0, double.infinity).shouldApprox == log(0.004431848);
}

// Checking negative location parameter
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;
    import mir.math.common: log;

    studentsTLPDF(-3.0, 5, -1, 2).shouldApprox == log(0.2196798);
    studentsTLPDF(-2.0, 5, -1, 2).shouldApprox == log(0.3279185);
    studentsTLPDF(-1.0, 5, -1, 2).shouldApprox == log(0.3796067);
    studentsTLPDF(0.0, 5, -1, 2).shouldApprox == log(0.3279185);
    studentsTLPDF(1.0, 5, -1, 2).shouldApprox == log(0.2196798);
    studentsTLPDF(2.0, 5, -1, 2).shouldApprox == log(0.1245173);
    studentsTLPDF(3.0, 5, -1, 2).shouldApprox == log(0.06509031);
}
