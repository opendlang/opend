/++
This package publicly imports `mir.stat.*` modules.

------
import mir.algorithm.iteration: all;
import mir.math.common: approxEqual, pow;
import mir.test: shouldApprox;

// mir.stat.descriptive
import mir.stat.descriptive.univariate: mean, kurtosis;
auto x = [1.0, 2, 3, 4];
x.mean.shouldApprox == 2.5;
x.kurtosis.shouldApprox == -1.2;

// mir.stat.distribution
import mir.stat.distribution.binomial: binomialPMF;
4.binomialPMF(6, 2.0 / 3).shouldApprox == (15.0 * pow(2.0 / 3, 4) * pow(1.0 / 3, 2));

// mir.stat.transform
import mir.stat.transform: zscore;
assert(x.zscore.all!approxEqual([-1.161895, -0.387298, 0.387298, 1.161895]));

// mir.stat.inference
import mir.stat.inference: dAgostinoPearsonTest;
auto y = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
double p;
y.dAgostinoPearsonTest(p).shouldApprox == 4.151936053369771;
------

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall, Ilya Yaroshenko

Copyright: 2022 Mir Stat Authors.

Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, stat, $1)$(NBSP)
MATHREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, math, $1)$(NBSP)
NDSLICEREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, ndslice, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
T4=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4))

+/

module mir.stat;

///
public import mir.stat.descriptive;
///
public import mir.stat.distribution;
///
public import mir.stat.inference;
///
public import mir.stat.transform;

// Matche comment above to ensure no errors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual, pow;
    import mir.test: shouldApprox;
    
    // mir.stat.descriptive
    import mir.stat.descriptive.univariate: mean, kurtosis;
    auto x = [1.0, 2, 3, 4];
    x.mean.shouldApprox == 2.5;
    x.kurtosis.shouldApprox == -1.2;
    
    // mir.stat.distribution
    import mir.stat.distribution.binomial: binomialPMF;
    4.binomialPMF(6, 2.0 / 3).shouldApprox == (15.0 * pow(2.0 / 3, 4) * pow(1.0 / 3, 2));

    // mir.stat.transform
    import mir.stat.transform: zscore;
    assert(x.zscore.all!approxEqual([-1.161895, -0.387298, 0.387298, 1.161895]));

    // mir.stat.inference
    import mir.stat.inference: dAgostinoPearsonTest;
    auto y = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    double p;
    y.dAgostinoPearsonTest(p).shouldApprox == 4.151936053369771;
}
