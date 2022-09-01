/++
This module contains algorithms for the discrete uniform probability distribution.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.
+/

module mir.stat.distribution.uniform_discrete;

import mir.internal.utility: isFloatingPoint;

/++
Computes the discrete uniform probability mass function (PMF).

Params:
    x = value to evaluate PMF
    lower = lower bound
    upper = upper bound

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Discrete_uniform_distribution, discrete uniform probability distribution)
+/
@safe pure nothrow @nogc
double uniformDiscretePMF(const size_t x, const size_t lower = 0, const size_t upper = 1)
    in(x >= lower, "x must be greater than or equal to lower bound in discrete uniform probability distribution")
    in(x <= upper, "x must be less than or equal to upper bound in discrete uniform probability distribution")
    in(lower <= upper, "lower must be less than or equal to upper")
{
    return 1.0 / (upper - lower + 1);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    1.uniformDiscretePMF.shouldApprox == 0.5;
    2.uniformDiscretePMF(1, 3).shouldApprox == 1.0 / 3;
}

/++
Computes the discrete uniform cumulative distribution function (CDF).

Params:
    x = value to evaluate CDF
    lower = lower bound
    upper = upper bound

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Discrete_uniform_distribution, discrete uniform probability distribution)
+/
@safe pure nothrow @nogc
double uniformDiscreteCDF(const size_t x, const size_t lower = 0, const size_t upper = 1)
    in(x >= lower, "x must be greater than or equal to lower bound in discrete uniform probability distribution")
    in(x <= upper, "x must be less than or equal to upper bound in discrete uniform probability distribution")
    in(lower <= upper, "lower must be less than or equal to upper")
{
    return (cast(double) x - lower + 1) / (upper - lower + 1);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    0.uniformDiscreteCDF.shouldApprox == 0.5;
    1.uniformDiscreteCDF.shouldApprox == 1.0;

    1.uniformDiscreteCDF(1, 3).shouldApprox == 1.0 / 3;
    2.uniformDiscreteCDF(1, 3).shouldApprox == 2.0 / 3;
    3.uniformDiscreteCDF(1, 3).shouldApprox == 1.0;
}

/++
Computes the discrete uniform complementary cumulative distribution function (CCDF).

Params:
    x = value to evaluate CCDF
    lower = lower bound
    upper = upper bound

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Discrete_uniform_distribution, discrete uniform probability distribution)
+/
@safe pure nothrow @nogc
double uniformDiscreteCCDF(const size_t x, const size_t lower = 0, const size_t upper = 1)
    in(x >= lower, "x must be greater than or equal to lower bound in discrete uniform probability distribution")
    in(x <= upper, "x must be less than or equal to upper bound in discrete uniform probability distribution")
    in(lower <= upper, "lower must be less than or equal to upper")
{
    return (cast(double) upper - x) / (upper - lower + 1);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: shouldApprox;

    0.uniformDiscreteCCDF.shouldApprox == 0.5;
    1.uniformDiscreteCCDF.shouldApprox == 0.0;

    1.uniformDiscreteCCDF(1, 3).shouldApprox == 2.0 / 3;
    2.uniformDiscreteCCDF(1, 3).shouldApprox == 1.0 / 3;
    3.uniformDiscreteCCDF(1, 3).shouldApprox == 0.0;
}

/++
Computes the discrete uniform inverse cumulative distribution function (InvCDF)

Params:
    p = value to evaluate InvCDF
    lower = lower bound
    upper = upper bound

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Discrete_uniform_distribution, discrete uniform probability distribution)
+/
@safe pure nothrow @nogc
size_t uniformDiscreteInvCDF(T)(const T p, const size_t lower = 0, const size_t upper = 1)
    if (isFloatingPoint!T)
    in(p >= 0, "p must be greater than or equal to 0")
    in(p <= 1, "p must be less than or equal to 1")
    in(lower < upper, "lower must be less than upper")
{
    size_t n = upper - lower + 1;
    if (p * n <= 1) {
        return lower;
    }
    return cast(size_t) (p * n + lower - 1);
}

///.
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.test: should;

    0.0.uniformDiscreteInvCDF.should == 0;
    0.5.uniformDiscreteInvCDF.should == 0;
    1.0.uniformDiscreteInvCDF.should == 1;

    0.0.uniformDiscreteInvCDF(1, 3).should == 1;
    0.2.uniformDiscreteInvCDF(1, 3).should == 1;
    (1.0 / 3).uniformDiscreteInvCDF(1, 3).should == 1;
    0.5.uniformDiscreteInvCDF(1, 3).should == 1;
    (2.0 / 3).uniformDiscreteInvCDF(1, 3).should == 2;
    1.0.uniformDiscreteInvCDF(1, 3).should == 3;
}

/++
Computes the discrete uniform log probability distribution function (LPDF)

Params:
    x = value to evaluate LPDF
    lower = lower bound
    upper = upper bound

See_also:
    $(LINK2 https://en.wikipedia.org/wiki/Discrete_uniform_distribution, discrete uniform probability distribution)
+/
@safe pure nothrow @nogc
double uniformDiscreteLPMF(const size_t x, const size_t lower = 0, const size_t upper = 1)
    in(x >= lower, "x must be greater than or equal to lower bound in discrete uniform probability distribution")
    in(x <= upper, "x must be less than or equal to upper bound in discrete uniform probability distribution")
    in(lower < upper, "lower must be less than upper")
{
    import mir.math.common: log;

    return -log(cast(double) upper - lower + 1);
}

///
version(mir_stat_test)
@safe pure nothrow @nogc
unittest {
    import mir.math.common: log;
    import mir.test: shouldApprox;

    1.uniformDiscreteLPMF.shouldApprox == -log(2.0);
    2.uniformDiscreteLPMF(1, 3).shouldApprox == -log(3.0);
}
