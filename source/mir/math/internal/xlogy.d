/++
License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.
+/

module mir.math.internal.xlogy;

import mir.internal.utility: isFloatingPoint;

package(mir)
@safe pure nothrow @nogc
T xlogy(T)(const T x, const T y)
    if (isFloatingPoint!T)
{
    import mir.math.common: log;

    if (x == 0)
        return 0;
    else
        return x * log(y);
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, log;

    assert(xlogy(0.0, 2) == 0);
    assert(xlogy(0.5, 4).approxEqual(0.5 * log(4.0)));
}

package(mir)
@safe pure nothrow @nogc
T xlog1py(T)(const T x, const T y)
    if (isFloatingPoint!T)
{
    import std.math.exponential: log1p;

    if (x == 0)
        return 0;
    else
        return x * log1p(y);
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, log;

    assert(xlog1py(0.0, 2) == 0);
    assert(xlog1py(0.5, 4).approxEqual(0.5 * log(1 + 4.0)));
}
