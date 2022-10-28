/**
License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
*/
/**
 * Normal Distribution
 *
 * Copyright: Based on the CEPHES math library, which is
 *            Copyright (C) 1994 Stephen L. Moshier (moshier@world.std.com).
 * Authors:   Stephen L. Moshier, ported to D by Don Clugston and David Nadlinger. Adopted to Mir by Ilya Yaroshenko.
 */
/**
 * Macros:
 *  NAN = $(RED NAN)
 *  INTEGRAL = &#8747;
 *  POWER = $1<sup>$2</sup>
 *      <caption>Special Values</caption>
 *      $0</table>
 */

module mir.stat.distribution.normal;

///
public import mir.math.func.normal: normalPDF, normalCDF, normalInvCDF;

import mir.internal.utility: isFloatingPoint;

/++
Computes the normal complementary cumulative distribution function (CCDF)

Params:
    x = value to evaluate CCDF
    mean = mean
    stdDev = standard deviation

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Normal_distribution, normal probability distribution)
+/
@safe pure nothrow @nogc
T normalCCDF(T)(const T x, const T mean, const T stdDev)
    if (isFloatingPoint!T)
{
    return normalCCDF((x - mean) / stdDev);
}

/// ditto
@safe pure nothrow @nogc
T normalCCDF(T)(const T a)
    if (isFloatingPoint!T)
{
    return normalCDF(-a);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert(0.5.normalCCDF.approxEqual(1 - normalCDF(0.5)));
    assert(0.5.normalCCDF(0, 1.5).approxEqual(1 - normalCDF(0.5, 0, 1.5)));
    assert(1.5.normalCCDF(1, 3).approxEqual(1 - normalCDF(1.5, 1, 3)));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;

    assert((-3.0).normalCCDF.approxEqual(1 - normalCDF(-3.0)));
    assert(3.0.normalCCDF.approxEqual(1 - normalCDF(3.0)));
    assert((-7.0).normalCCDF(1, 4).approxEqual(1 - normalCDF(-7.0, 1, 4)));
    assert(9.0.normalCCDF(1, 4).approxEqual(1 - normalCDF(9.0, 1, 4)));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    assert(normalCCDF(double.infinity).approxEqual(1 - normalCDF(double.infinity)));
    assert(normalCCDF(-double.infinity).approxEqual(1 - normalCDF(-double.infinity)));
}

///
enum real LOGSQRT2PI = 0.91893853320467274178032973640561764L; // log(sqrt(2pi))

/++
Computes the normal log probability distribution function (LPDF)

Params:
    x = value to evaluate LPDF
    mean = mean
    stdDev = standard deviation

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Normal_distribution, normal probability distribution)
+/
@safe pure nothrow @nogc
T normalLPDF(T)(const T x, const T mean, const T stdDev)
    if (isFloatingPoint!T)
{
    import mir.math.common: log;
    return normalLPDF((x - mean) / stdDev) - log(stdDev);
}

/// ditto
@safe pure nothrow @nogc
T normalLPDF(T)(const T x)
    if (isFloatingPoint!T)
{
    import mir.math.common: pow;

    return -0.5 * pow(x, 2) - T(LOGSQRT2PI);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, log;
    assert(0.5.normalLPDF.approxEqual(log(normalPDF(0.5))));
    assert(0.5.normalLPDF(0, 1.5).approxEqual(log(normalPDF(0.5, 0, 1.5))));
    assert(1.5.normalLPDF(1, 3).approxEqual(log(normalPDF(1.5, 1, 3))));
}
