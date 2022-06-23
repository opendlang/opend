/++
This module contains algorithms for the binomial probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

+/

module mir.stat.distribution.binomial;

import mir.bignum.fp: Fp;
import mir.internal.utility: isFloatingPoint;

/++
Computes the binomial probability mass function (PMF).

This function can control the type of the function output through the template
parameter `T`. By default, `T` is set equal to `double`, but other floating
point types or extended precision floating point types (e.g. `Fp!128`) can be
used. For large values of `n`, `Fp!128` is recommended.

Params:
    k = value to evaluate PMF (e.g. number of "heads")
    n = number of trials
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Binomial_distribution, binomial probability distribution)
+/
@safe pure nothrow @nogc
T binomialPMF(T = double, U)(const uint k, const uint n, const U p)
    if (isFloatingPoint!U)
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    static if (isFloatingPoint!T) {
        import mir.math.common: pow;
        import mir.combinatorics: binomial;

        return binomial(n, k) * pow(p, k) * pow(1 - p, n - k);
    } else static if (is(T == Fp!size, size_t size)) {
           import mir.math.numeric: binomialCoefficient;

            T output = binomialCoefficient(n, k);
            for (size_t i; i < k; i++) {
                output *= T(p);
            }
            for (size_t i; i < (n - k); i++) {
                output *= T(1 - p);
            }
            return output;
    } else {
        static assert(0, "binomialPMF requires either a floating point type or mir.bignum.fp.Fp type");
    }
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, pow;
    import mir.combinatorics: binomial;

    assert(0.binomialPMF(5, 0.5).approxEqual(binomial(5, 0) * pow(0.5, 5)));
    assert(1.binomialPMF(5, 0.5).approxEqual(binomial(5, 1) * pow(0.5, 5)));
    assert(2.binomialPMF(5, 0.5).approxEqual(binomial(5, 2) * pow(0.5, 5)));
    assert(3.binomialPMF(5, 0.5).approxEqual(binomial(5, 3) * pow(0.5, 5)));
    assert(4.binomialPMF(5, 0.5).approxEqual(binomial(5, 4) * pow(0.5, 5)));
    assert(5.binomialPMF(5, 0.5).approxEqual(binomial(5, 5) * pow(0.5, 5)));
}

// p = 0.75
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, pow;
    import mir.combinatorics: binomial;

    assert(0.binomialPMF(5, 0.75).approxEqual(binomial(5, 0) * pow(0.75, 0) * pow(0.25, 5)));
    assert(1.binomialPMF(5, 0.75).approxEqual(binomial(5, 1) * pow(0.75, 1) * pow(0.25, 4)));
    assert(2.binomialPMF(5, 0.75).approxEqual(binomial(5, 2) * pow(0.75, 2) * pow(0.25, 3)));
    assert(3.binomialPMF(5, 0.75).approxEqual(binomial(5, 3) * pow(0.75, 3) * pow(0.25, 2)));
    assert(4.binomialPMF(5, 0.75).approxEqual(binomial(5, 4) * pow(0.75, 4) * pow(0.25, 1)));
    assert(5.binomialPMF(5, 0.75).approxEqual(binomial(5, 5) * pow(0.75, 5) * pow(0.25, 0)));
}

// using Fp!128, p = 0.5
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.conv: to;
    import mir.math.common: approxEqual;

    assert(0.binomialPMF!(Fp!128)(5, 0.5).to!double.approxEqual(binomialPMF(0, 5, 0.5)));
    assert(1.binomialPMF!(Fp!128)(5, 0.5).to!double.approxEqual(binomialPMF(1, 5, 0.5)));
    assert(2.binomialPMF!(Fp!128)(5, 0.5).to!double.approxEqual(binomialPMF(2, 5, 0.5)));
    assert(3.binomialPMF!(Fp!128)(5, 0.5).to!double.approxEqual(binomialPMF(3, 5, 0.5)));
    assert(4.binomialPMF!(Fp!128)(5, 0.5).to!double.approxEqual(binomialPMF(4, 5, 0.5)));
    assert(5.binomialPMF!(Fp!128)(5, 0.5).to!double.approxEqual(binomialPMF(5, 5, 0.5)));
}

// using Fp!128, p = 0.75
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.conv: to;
    import mir.math.common: approxEqual;

    assert(0.binomialPMF!(Fp!128)(5, 0.75).to!double.approxEqual(binomialPMF(0, 5, 0.75)));
    assert(1.binomialPMF!(Fp!128)(5, 0.75).to!double.approxEqual(binomialPMF(1, 5, 0.75)));
    assert(2.binomialPMF!(Fp!128)(5, 0.75).to!double.approxEqual(binomialPMF(2, 5, 0.75)));
    assert(3.binomialPMF!(Fp!128)(5, 0.75).to!double.approxEqual(binomialPMF(3, 5, 0.75)));
    assert(4.binomialPMF!(Fp!128)(5, 0.75).to!double.approxEqual(binomialPMF(4, 5, 0.75)));
    assert(5.binomialPMF!(Fp!128)(5, 0.75).to!double.approxEqual(binomialPMF(5, 5, 0.75)));
}

/// binomialPMF!(Fp!128) provides accurate values for large values of `n`
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.bignum.fp: Fp, fp_log;
    import mir.conv: to;
    import mir.math.common: approxEqual, exp, log;

    enum uint val = 1_000_000;

    assert(0.binomialPMF!(Fp!128)(val + 5, 0.75).fp_log!double.approxEqual(binomialLPMF(0, val + 5, 0.75)));
    assert(1.binomialPMF!(Fp!128)(val + 5, 0.75).fp_log!double.approxEqual(binomialLPMF(1, val + 5, 0.75)));
    assert(2.binomialPMF!(Fp!128)(val + 5, 0.75).fp_log!double.approxEqual(binomialLPMF(2, val + 5, 0.75)));
    assert(5.binomialPMF!(Fp!128)(val + 5, 0.75).fp_log!double.approxEqual(binomialLPMF(5, val + 5, 0.75)));
    assert((val / 2).binomialPMF!(Fp!128)(val + 5, 0.75).fp_log!double.approxEqual(binomialLPMF(val / 2, val + 5, 0.75)));
    assert((val - 5).binomialPMF!(Fp!128)(val + 5, 0.75).fp_log!double.approxEqual(binomialLPMF(val - 5, val + 5, 0.75)));
    assert((val - 2).binomialPMF!(Fp!128)(val + 5, 0.75).fp_log!double.approxEqual(binomialLPMF(val - 2, val + 5, 0.75)));
    assert((val - 1).binomialPMF!(Fp!128)(val + 5, 0.75).fp_log!double.approxEqual(binomialLPMF(val - 1, val + 5, 0.75)));
    assert((val - 0).binomialPMF!(Fp!128)(val + 5, 0.75).fp_log!double.approxEqual(binomialLPMF(val, val + 5, 0.75)));
}

/++
Computes the binomial log probability mass function (LPMF)

Params:
    k = value to evaluate LPMF (e.g. number of "heads")
    n = number of trials
    p = `true` probability

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Binomial_distribution, binomial probability distribution)
+/
T binomialLPMF(T)(uint k, uint n, const T p)
    if (isFloatingPoint!T)
    in (k <= n, "k must be less than or equal to n")
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
{
    import mir.bignum.fp: fp_log;
    import mir.math.internal.xlogy: xlogy, xlog1py;
    import mir.math.internal.log_binomial: logBinomialCoefficient;

    return logBinomialCoefficient(n, k) + xlogy(k, p) + xlog1py((n - k), -p);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, exp;

    assert(0.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(0, 5, 0.5)));
    assert(1.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(1, 5, 0.5)));
    assert(2.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(2, 5, 0.5)));
    assert(3.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(3, 5, 0.5)));
    assert(4.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(4, 5, 0.5)));
    assert(5.binomialLPMF(5, 0.5).exp.approxEqual(binomialPMF(5, 5, 0.5)));
}

// test with p = 0.75
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: approxEqual, exp;

    assert(0.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(0, 5, 0.75)));
    assert(1.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(1, 5, 0.75)));
    assert(2.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(2, 5, 0.75)));
    assert(3.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(3, 5, 0.75)));
    assert(4.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(4, 5, 0.75)));
    assert(5.binomialLPMF(5, 0.75).exp.approxEqual(binomialPMF(5, 5, 0.75)));
}

/// Accurate values for large values of `n`
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.bignum.fp: Fp, fp_log;
    import mir.math.common: approxEqual;

    enum uint val = 1_000_000;

    assert(0.binomialLPMF(val + 5, 0.75).approxEqual(binomialPMF!(Fp!128)(0, val + 5, 0.75).fp_log!double));
    assert(1.binomialLPMF(val + 5, 0.75).approxEqual(binomialPMF!(Fp!128)(1, val + 5, 0.75).fp_log!double));
    assert(2.binomialLPMF(val + 5, 0.75).approxEqual(binomialPMF!(Fp!128)(2, val + 5, 0.75).fp_log!double));
    assert(5.binomialLPMF(val + 5, 0.75).approxEqual(binomialPMF!(Fp!128)(5, val + 5, 0.75).fp_log!double));
    assert((val / 2).binomialLPMF(val + 5, 0.75).approxEqual(binomialPMF!(Fp!128)(val / 2, val + 5, 0.75).fp_log!double));
    assert((val - 5).binomialLPMF(val + 5, 0.75).approxEqual(binomialPMF!(Fp!128)(val - 5, val + 5, 0.75).fp_log!double));
    assert((val - 2).binomialLPMF(val + 5, 0.75).approxEqual(binomialPMF!(Fp!128)(val - 2, val + 5, 0.75).fp_log!double));
    assert((val - 1).binomialLPMF(val + 5, 0.75).approxEqual(binomialPMF!(Fp!128)(val - 1, val + 5, 0.75).fp_log!double));
    assert((val - 0).binomialLPMF(val + 5, 0.75).approxEqual(binomialPMF!(Fp!128)(val, val + 5, 0.75).fp_log!double));
    
}
