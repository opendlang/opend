/**
License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
*/
/**
 * Generalized extreme value distribution
 *
 * Copyright: Ilia Ki, 2022
 * Authors: Ilia Ki
 */
/**
 * Macros:
 *  NAN = $(RED NAN)
 *  INTEGRAL = &#8747;
 *  POWER = $1<sup>$2</sup>
 *      <caption>Special Values</caption>
 *      $0</table>
 */
module mir.stat.distribution.gev;

import mir.internal.utility: isFloatingPoint;

import mir.math.common: fabs, exp, pow, log;

/++
Computes the generalized extreme value probability distribution function (PDF).

Params:
    x = value to evaluate
    mu = location
    sigma = scale
    xi = shape
+/
T gevPDF(T)(const T x, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
{
    auto s = (x - mu) / sigma;
    if (xi.fabs <= T.min_normal)
    {
        auto t = exp(-s);
        return t * exp(-t);
    }
    auto v = 1 + xi * s;
    if (v <= 0)
        return 0;
    auto a = pow(v, -1 / xi);
    return a * exp(-a) / (v * sigma);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test;
    gevPDF(-3, 2, 3, -0.5).shouldApprox == 0.02120353011709564;
    gevPDF(-1, 2, 3, +0.5).shouldApprox == 0.04884170370329114;
    gevPDF(-1, 2, 3, 0.0).shouldApprox == 0.1793740787340172;
}

/++
Computes the generalized extreme value cumulatve distribution function (CDF).

Params:
    x = value to evaluate
    mu = location
    sigma = scale
    xi = shape
+/
T gevCDF(T)(const T x, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
{
    auto s = (x - mu) / sigma;
    if (xi.fabs <= T.min_normal)
        return exp(-exp(-s));
    auto v = 1 + xi * s;
    if (v <= 0)
        return xi > 0 ? 0 : 1;
    auto a = pow(v, -1 / xi);
    return exp(-a);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test;
    gevCDF(-3, 2, 3, -0.5).shouldApprox == 0.034696685646156494;
    gevCDF(-1, 2, 3, +0.5).shouldApprox == 0.01831563888873418;
    gevCDF(-1, 2, 3, 0.0).shouldApprox == 0.06598803584531254;
}

/++
Computes the generalized extreme value inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate
    mu = location
    sigma = scale
    xi = shape
+/
T gevInvCDF(T)(const T p, const T mu, const T sigma, const T xi)
    if (isFloatingPoint!T)
{
    auto logp = log(p);
    if (xi.fabs <= T.min_normal)
        return mu - sigma * log(-logp);
    return mu + (pow(-logp, -xi) - 1) * sigma / xi;
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test;
    gevInvCDF(0.034696685646156494, 2, 3, -0.5).shouldApprox == -3;
    gevInvCDF(0.01831563888873418, 2, 3, +0.5).shouldApprox == -1;
    gevInvCDF(0.06598803584531254, 2, 3, 0.0).shouldApprox == -1;
}
