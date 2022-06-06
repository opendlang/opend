/++
License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.
+/

module mir.math.internal.log_binomial;

import mir.bignum.fp: Fp;
import mir.internal.utility: isFloatingPoint;

private enum size_t logFactorialAlternative = 2500;

///
T logFactorial(T = double)(ulong count, ulong start = 1)
    if (isFloatingPoint!T)
    in (start, "start must be larger than zero")
{
    import mir.bignum.fp: fp_log;
    import mir.math.numeric: factorial;
    import std.mathspecial: logGamma;

    if (count + start < logFactorialAlternative) {
        return fp_log!T(factorial(count, start));
    } else {
        T output = T(logGamma(count + start)); // normally logGamma(x + 1), but start is included in value so subtract out
        if (start < logFactorialAlternative) {
            return output - fp_log!T(factorial(start - 1));
        } else {
            return output - T(logGamma(start));
        }
    }
}

///
@safe pure nothrow @nogc
version(mir_stat_test_logBinomial)
unittest {
    import mir.math.common: approxEqual, log;
    assert(logFactorial(0) == 0);
    assert(logFactorial(1) == 0);
    assert(logFactorial(2).approxEqual(log(1.0 * 2)));
    assert(logFactorial(3).approxEqual(log(1.0 * 2 * 3)));
    assert(logFactorial(4).approxEqual(log(1.0 * 2 * 3 * 4)));
    assert(logFactorial(5).approxEqual(log(1.0 * 2 * 3 * 4 * 5)));
}

// test starting points
@safe pure nothrow @nogc
version(mir_stat_test_logBinomial)
unittest {
    import mir.math.common: approxEqual, log;
    assert(logFactorial(2, 2).approxEqual(log(2.0 * 3)));
    assert(logFactorial(3, 2).approxEqual(log(2.0 * 3 * 4)));
    assert(logFactorial(4, 2).approxEqual(log(2.0 * 3 * 4 * 5)));
    assert(logFactorial(4, 3).approxEqual(log(3.0 * 4 * 5 * 6)));
    assert(logFactorial(4, 4).approxEqual(log(4.0 * 5 * 6 * 7)));
    assert(logFactorial(5, 2).approxEqual(log(2.0 * 3 * 4 * 5 * 6)));
    assert(logFactorial(5, 3).approxEqual(log(3.0 * 4 * 5 * 6 * 7)));
    assert(logFactorial(5, 4).approxEqual(log(4.0 * 5 * 6 * 7 * 8)));
    assert(logFactorial(5, 5).approxEqual(log(5.0 * 6 * 7 * 8 * 9)));
}

// test larger value
@safe pure nothrow @nogc
version(mir_stat_test_logBinomial)
unittest {
    import mir.bignum.fp: fp_log;
    import mir.math.common: approxEqual, log;
    import mir.math.numeric: factorial;
    import std.mathspecial: logGamma;

    size_t x = logFactorialAlternative + 500;
    assert(logFactorial(x).approxEqual(logGamma(cast(double) x + 1)));
    assert(logFactorial(x, 2).approxEqual(logGamma(cast(double) x + 1 + 1) - log(1.0)));
    assert(logFactorial(x, 3).approxEqual(logGamma(cast(double) x + 2 + 1) - log(2.0)));
    assert(logFactorial(x, x / 2).approxEqual(logGamma(cast(double) x + x / 2) - fp_log!double(factorial(x / 2 - 1))));
}

private enum size_t logBinomialCoefficientAlternative = 2500;

///
T logBinomialCoefficient(T = double)(ulong n, uint k)
    if (isFloatingPoint!T)
    in (k <= n, "k must be less than or equal to n")
{
    import mir.math.common: log;
    import mir.bignum.fp: fp_log;
    import mir.math.numeric: binomialCoefficient;

    if (k > n - k) {
        k = cast(uint)(n - k);
    }
    if (k == 0) {
        return T(0.0);
    } else if (k == 1) {
        return log(cast(T) n);
    } else {
        if (n < logBinomialCoefficientAlternative) {
            return fp_log!T(binomialCoefficient(n, k));
        } else {
            return logFactorial!T(k, n - k + 1) - logFactorial!T(k);
        }
    }
}

///
@safe pure nothrow @nogc
version(mir_stat_test)
unittest {
    import mir.bignum.fp: Fp, fp_log;
    import mir.math.numeric: binomialCoefficient;
    import mir.math.common: approxEqual, log;

    assert(logBinomialCoefficient(5, 1).approxEqual(log(5.0)));
    assert(logBinomialCoefficient(5, 2).approxEqual(fp_log!double(binomialCoefficient(5, 2))));
    assert(logBinomialCoefficient(5, 3).approxEqual(fp_log!double(binomialCoefficient(5, 3))));
    assert(logBinomialCoefficient(5, 4).approxEqual(fp_log!double(binomialCoefficient(5, 4))));
}

// test n = 6
@safe pure nothrow @nogc
version(mir_stat_test)
unittest {
    import mir.bignum.fp: fp_log;
    import mir.math.numeric: binomialCoefficient;
    import mir.math.common: approxEqual;

    assert(logBinomialCoefficient(6, 1).approxEqual(fp_log!double(binomialCoefficient(6, 1))));
    assert(logBinomialCoefficient(6, 2).approxEqual(fp_log!double(binomialCoefficient(6, 2))));
    assert(logBinomialCoefficient(6, 3).approxEqual(fp_log!double(binomialCoefficient(6, 3))));
    assert(logBinomialCoefficient(6, 4).approxEqual(fp_log!double(binomialCoefficient(6, 4))));
    assert(logBinomialCoefficient(6, 5).approxEqual(fp_log!double(binomialCoefficient(6, 5))));
}

// test n = 7
@safe pure nothrow @nogc
version(mir_stat_test)
unittest {
    import mir.bignum.fp: fp_log;
    import mir.math.numeric: binomialCoefficient;
    import mir.math.common: approxEqual;

    assert(logBinomialCoefficient(7, 1).approxEqual(fp_log!double(binomialCoefficient(7, 1))));
    assert(logBinomialCoefficient(7, 2).approxEqual(fp_log!double(binomialCoefficient(7, 2))));
    assert(logBinomialCoefficient(7, 3).approxEqual(fp_log!double(binomialCoefficient(7, 3))));
    assert(logBinomialCoefficient(7, 4).approxEqual(fp_log!double(binomialCoefficient(7, 4))));
    assert(logBinomialCoefficient(7, 5).approxEqual(fp_log!double(binomialCoefficient(7, 5))));
    assert(logBinomialCoefficient(7, 6).approxEqual(fp_log!double(binomialCoefficient(7, 6))));
}

// test n = 8
@safe pure nothrow @nogc
version(mir_stat_test)
unittest {
    import mir.bignum.fp: fp_log;
    import mir.math.numeric: binomialCoefficient;
    import mir.math.common: approxEqual;

    assert(logBinomialCoefficient(8, 1).approxEqual(fp_log!double(binomialCoefficient(8, 1))));
    assert(logBinomialCoefficient(8, 2).approxEqual(fp_log!double(binomialCoefficient(8, 2))));
    assert(logBinomialCoefficient(8, 3).approxEqual(fp_log!double(binomialCoefficient(8, 3))));
    assert(logBinomialCoefficient(8, 4).approxEqual(fp_log!double(binomialCoefficient(8, 4))));
    assert(logBinomialCoefficient(8, 5).approxEqual(fp_log!double(binomialCoefficient(8, 5))));
    assert(logBinomialCoefficient(8, 6).approxEqual(fp_log!double(binomialCoefficient(8, 6))));
    assert(logBinomialCoefficient(8, 7).approxEqual(fp_log!double(binomialCoefficient(8, 7))));
}

// test k = 0, n = k
@safe pure nothrow @nogc
version(mir_stat_test)
unittest {
    assert(logBinomialCoefficient(5, 0) == 0);
    assert(logBinomialCoefficient(5, 5) == 0);
    assert(logBinomialCoefficient(1, 1) == 0);
    assert(logBinomialCoefficient(1, 0) == 0);
}

// Test large values
@safe pure nothrow @nogc
version(mir_stat_test)
unittest {
    import mir.bignum.fp: fp_log;
    import mir.math.numeric: binomialCoefficient;
    import mir.math.common: approxEqual, log;

    size_t x = logBinomialCoefficientAlternative + 500;

    assert(logBinomialCoefficient(x, 1).approxEqual(log(cast(double) x)));
    assert(logBinomialCoefficient(x, 250).approxEqual(logFactorial(x) - logFactorial(250) - logFactorial(x - 250)));
    assert(logBinomialCoefficient(x, cast(uint) x / 2).approxEqual(logFactorial(x) - logFactorial(x / 2) - logFactorial(x / 2)));
    assert(logBinomialCoefficient(x, cast(uint) x - 250).approxEqual(logBinomialCoefficient(x, 250)));
}
