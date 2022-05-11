/++
License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.
+/

module mir.math.internal.logBeta;

import mir.internal.utility: isFloatingPoint;

package(mir)
@safe pure nothrow @nogc
T logBeta(T)(const T alpha, const T beta)
    if (isFloatingPoint!T)
{
    import std.mathspecial: logGamma;

    return logGamma(alpha) + logGamma(beta) - logGamma(alpha + beta);
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, log;
    import std.mathspecial: beta;

    assert(logBeta(1.0, 2).approxEqual(log(beta(1.0, 2))));
    assert(logBeta(0.5, 4).approxEqual(log(beta(0.5, 4))));
}
