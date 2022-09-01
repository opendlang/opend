/++
This module contains algorithms for the continuous uniform probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.uniform;

import mir.internal.utility: isFloatingPoint;

/++
Computes the uniform probability distribution function (PDF).

Params:
    x = value to evaluate PDF
    lower = lower bound
    upper = upper bound

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Continuous_uniform_distribution, uniform probability distribution)
+/
@safe pure nothrow @nogc
T uniformPDF(T)(const T x, const T lower = 0, const T upper = 1)
    if (isFloatingPoint!T)
    in(x >= lower, "x must be greater than or equal to lower bound in uniform probability distribution")
    in(x <= upper, "x must be less than or equal to upper bound in uniform probability distribution")
    in(lower < upper, "lower must be less than upper")
{
    return 1.0L / (upper - lower);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    assert(0.5.uniformPDF == 1);
    assert(0.5.uniformPDF(0.0, 1.5).approxEqual(2.0 / 3));
    assert(2.5.uniformPDF(1.0, 3.0).approxEqual(0.5));
}

/++
Computes the uniform cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF
    lower = lower bound
    upper = upper bound

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Continuous_uniform_distribution, uniform probability distribution)
+/
@safe pure nothrow @nogc
T uniformCDF(T)(const T x, const T lower = 0, const T upper = 1)
    if (isFloatingPoint!T)
    in(x >= lower, "x must be greater than or equal to lower bound in uniform probability distribution")
    in(x <= upper, "x must be less than or equal to upper bound in uniform probability distribution")
    in(lower < upper, "lower must be less than upper")
{
    return (x - lower) / (upper - lower);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    assert(0.5.uniformCDF == 0.5);
    assert(0.5.uniformCDF(0.0, 1.5).approxEqual(1.0 / 3));
    assert(2.5.uniformCDF(1.0, 3.0).approxEqual(3.0 / 4));
}

/++
Computes the uniform complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    lower = lower bound
    upper = upper bound

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Continuous_uniform_distribution, uniform probability distribution)
+/
@safe pure nothrow @nogc
T uniformCCDF(T)(const T x, const T lower = 0, const T upper = 1)
    if (isFloatingPoint!T)
    in(x >= lower, "x must be greater than or equal to lower bound in uniform probability distribution")
    in(x <= upper, "x must be less than or equal to upper bound in uniform probability distribution")
    in(lower < upper, "lower must be less than upper")
{
    return (upper - x) / (upper - lower);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    assert(0.5.uniformCCDF == 0.5);
    assert(0.5.uniformCCDF(0.0, 1.5).approxEqual(2.0 / 3));
    assert(2.5.uniformCCDF(1.0, 3.0).approxEqual(1.0 / 4));
}

/++
Computes the uniform inverse cumulative distribution function (InvCDF)

Params:
    p = value to evaluate InvCDF
    lower = lower bound
    upper = upper bound

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Continuous_uniform_distribution, uniform probability distribution)
+/
@safe pure nothrow @nogc
T uniformInvCDF(T)(const T p, const T lower = 0, const T upper = 1)
    if (isFloatingPoint!T)
    in(p >= 0, "p must be greater than or equal to 0")
    in(p <= 1, "p must be less than or equal to 1")
    in(lower < upper, "lower must be less than upper")
{
    return lower + p * (upper - lower);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual;
    assert(0.5.uniformInvCDF == 0.5);
    assert((1.0 / 3).uniformInvCDF(0.0, 1.5).approxEqual(0.5));
    assert((3.0 / 4).uniformInvCDF(1.0, 3.0).approxEqual(2.5));
}

/++
Computes the uniform log probability distribution function (LPDF)

Params:
    x = value to evaluate LPDF
    lower = lower bound
    upper = upper bound

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Continuous_uniform_distribution, uniform probability distribution)
+/
@safe pure nothrow @nogc
T uniformLPDF(T)(const T x, const T lower = 0, const T upper = 1)
    if (isFloatingPoint!T)
    in(x >= lower, "x must be greater than or equal to lower bound in uniform probability distribution")
    in(x <= upper, "x must be less than or equal to upper bound in uniform probability distribution")
    in(lower < upper, "lower must be less than upper")
{
    import mir.math.common: log;

    return -log(upper - lower);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, log;
    assert(0.5.uniformLPDF == 0);
    assert(0.5.uniformLPDF(0.0, 1.5).approxEqual(-log(1.5)));
    assert(1.5.uniformLPDF(1.0, 3.0).approxEqual(-log(2.0)));
}
