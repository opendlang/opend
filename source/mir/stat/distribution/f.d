/++
This module contains algorithms for the F probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.
+/

module mir.stat.distribution.f;

import mir.internal.utility: isFloatingPoint;

/++
Computes the F probability distribution function (PDF).

Params:
    x = value to evaluate PDF
    df1 = degrees of freedom parameter #1
    df2 = degrees of freedom parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/F-distribution, F probability distribution)
+/
@safe pure nothrow @nogc
T fPDF(T)(const T x, const T df1, const T df2)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (df1 > 0, "df1 must be greater than zero")
    in (df2 > 0, "df2 must be greater than zero")
{
    import mir.math.common: pow, sqrt;
    import std.mathspecial: beta;

    if (df1 == 1 && x == 0)
        return T.infinity;
    return sqrt(pow(df1 * x, df1) * pow(df2, df2) / pow(df1 * x + df2, df1 + df2)) / (x * beta(df1 * 0.5, df2 * 0.5));
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    0.50.fPDF(1, 1).shouldApprox == 0.3001054;
    0.75.fPDF(1, 2).shouldApprox == 0.2532039;
    0.25.fPDF(0.5, 4).shouldApprox == 0.4904035;
    0.10.fPDF(2, 1).shouldApprox == 0.7607258;
    0.00.fPDF(1, 3).shouldApprox == double.infinity;
}

/++
Computes the F cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF
    df1 = degrees of freedom parameter #1
    df2 = degrees of freedom parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/F-distribution, F probability distribution)
+/
@safe pure nothrow @nogc
T fCDF(T)(const T x, const T df1, const T df2)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (df1 > 0, "df1 must be greater than zero")
    in (df2 > 0, "df2 must be greater than zero")
{
    import std.mathspecial: betaIncomplete;

    return betaIncomplete(df1 * 0.5, df2 * 0.5, (df1 * x) / (df1 * x + df2));
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    0.50.fCDF(1, 1).shouldApprox == 0.3918266;
    0.75.fCDF(1, 2).shouldApprox == 0.522233;
    0.25.fCDF(0.5, 4).shouldApprox == 0.5183719;
    0.10.fCDF(2, 1).shouldApprox == 0.08712907;
}

/++
Computes the F complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    df1 = degrees of freedom parameter #1
    df2 = degrees of freedom parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/F-distribution, F probability distribution)
+/
@safe pure nothrow @nogc
T fCCDF(T)(const T x, const T df1, const T df2)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (df1 > 0, "df1 must be greater than zero")
    in (df2 > 0, "df2 must be greater than zero")
{
    import std.mathspecial: betaIncomplete;

    return betaIncomplete(df2 * 0.5, df1 * 0.5, df2 / (df1 * x + df2));
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    0.50.fCCDF(1, 1).shouldApprox == 0.6081734;
    0.75.fCCDF(1, 2).shouldApprox == 0.477767;
    0.25.fCCDF(0.5, 4).shouldApprox == 0.4816281;
    0.10.fCCDF(2, 1).shouldApprox == 0.9128709;
}

/++
Computes the F inverse cumulative distribution function (InvCDF).

Params:
    p = value to evaluate InvCDF
    df1 = degrees of freedom parameter #1
    df2 = degrees of freedom parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/F-distribution, F probability distribution)
+/
@safe pure nothrow @nogc
T fInvCDF(T)(const T p, const T df1, const T df2)
    if (isFloatingPoint!T)
    in (p >= 0, "p must be greater than or equal to 0")
    in (p <= 1, "p must be less than or equal to 1")
    in (df1 > 0, "df1 must be greater than zero")
    in (df2 > 0, "df2 must be greater than zero")
{
    import std.mathspecial: betaIncompleteInverse;

    if (p == 0)
        return 0;
    if (p == 1)
        return T.infinity;
    const T invBeta = betaIncompleteInverse(df1 * 0.5, df2 * 0.5, p);
    return invBeta * df2 / ((1 - invBeta) * df1);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    0.3918266.fInvCDF(1, 1).shouldApprox == 0.50; 
    0.522233.fInvCDF(1, 2).shouldApprox == 0.75;
    0.5183719.fInvCDF(0.5, 4).shouldApprox == 0.25;
    0.08712907.fInvCDF(2, 1).shouldApprox == 0.10;
    0.0.fInvCDF(1, 1).shouldApprox == 0;
    1.0.fInvCDF(1, 1).shouldApprox == double.infinity;
}

/++
Computes the F log probability distribution function (LPDF).

Params:
    x = value to evaluate LPDF
    df1 = degrees of freedom parameter #1
    df2 = degrees of freedom parameter #2

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/F-distribution, F probability distribution)
+/
@safe pure nothrow @nogc
T fLPDF(T)(const T x, const T df1, const T df2)
    if (isFloatingPoint!T)
    in (x >= 0, "x must be greater than or equal to 0")
    in (df1 > 0, "df1 must be greater than zero")
    in (df2 > 0, "df2 must be greater than zero")
{
    import mir.math.common: log;
    import mir.math.internal.log_beta: logBeta;

    if (df1 == 1 && x == 0)
        return T.infinity;
    return 0.5 * (df1 * log(df1 * x) + df2 * log(df2) - (df1 + df2) * log(df1 * x + df2)) - log(x) - logBeta(df1 * 0.5, df2 * 0.5);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: log;
    import mir.test: shouldApprox;

    0.50.fLPDF(1, 1).shouldApprox == log(0.3001054);
    0.75.fLPDF(1, 2).shouldApprox == log(0.2532039);
    0.25.fLPDF(0.5, 4).shouldApprox == log(0.4904035);
    0.10.fLPDF(2, 1).shouldApprox == log(0.7607258);
    0.00.fLPDF(1, 3).shouldApprox == double.infinity;
}
