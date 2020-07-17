/++
License: $(LINK2 http://boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: John Michael Hall

Copyright: 2020 Mir Stat Authors.
+/

module mir.math.func.xlogy;

import mir.internal.utility: isFloatingPoint;
import std.traits: Unqual;

/++
Returns x * log(y)

Returns:
    x * log(y)
+/
F xlogy(F)(F x, F y)
    if (isFloatingPoint!(Unqual!(F)))
{
    import mir.math.common: log;

    assert(x >= 0, "xlogy: x must be greater than or equal to zero");
    assert(y >= 0, "xlogy: y must be greater than or equal to zero");
    return x * log(y);
}