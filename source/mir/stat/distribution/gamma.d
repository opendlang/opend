/++
This module contains algorithms for the gamma distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: Ilia Ki

Copyright: 2022 Mir Stat Authors.
+/

module mir.stat.distribution.gamma;

import mir.internal.utility: isFloatingPoint;

/++
Computes the gamma cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
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
    1.0.gammaCDF(5, 0.5).shouldApprox == 0.05265302;
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
    1.0.gammaCCDF(5, 0.5).shouldApprox == 0.947347;
}
