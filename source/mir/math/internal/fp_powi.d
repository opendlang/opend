/++
License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.
+/

module mir.math.internal.fp_powi;

import mir.bignum.fp: Fp;

package(mir)
T fp_powi(T)(const T x, size_t i)
    if (is(T == Fp!size, size_t size))
{
    if (i == 0) {
        return T(1.0);
    } else if (i == 1) {
        return x;
    } else {
        T output = x;
        for (size_t j = 1; j < i; j++) {
            output *= x;
        }
        return output;
    }
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.conv: to;
    auto x = Fp!128(3.0);
    assert(x.fp_powi(0).to!double == 1);
    assert(x.fp_powi(1).to!double == 3);
    assert(x.fp_powi(2).to!double == 9);
}
