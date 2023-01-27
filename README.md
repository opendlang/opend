[![codecov.io](https://codecov.io/github/libmir/mir-stat/coverage.svg?branch=master)](https://codecov.io/github/libmir/mir-stat?branch=master)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/libmir/mir-stat/d.yml?branch=master)](https://github.com/libmir/mir-stat/actions)
[![Circle CI](https://circleci.com/gh/libmir/mir-stat.svg?style=svg)](https://circleci.com/gh/libmir/mir-stat)

[![Dub downloads](https://img.shields.io/dub/dt/mir-stat.svg)](http://code.dlang.org/packages/mir-stat)
[![Dub downloads](https://img.shields.io/dub/dm/mir-stat.svg)](http://code.dlang.org/packages/mir-stat)
[![License](https://img.shields.io/dub/l/mir-stat.svg)](http://code.dlang.org/packages/mir-stat)
[![Latest version](https://img.shields.io/dub/v/mir-stat.svg)](http://code.dlang.org/packages/mir-stat)
[![Bountysource](https://www.bountysource.com/badge/team?team_id=145399&style=bounties_received)](https://www.bountysource.com/teams/libmir)

# Mir Stat

### Statistical algorithms for the D programming language (Dlang).

This package includes statistical algorithms, including but not limited to:
- [Descriptive statistics](http://mir-stat.libmir.org/mir_stat_descriptive.html)
- [Probability distributions](http://mir-stat.libmir.org/mir_stat_distribution.html)
- [Statistical inference](https://github.com/libmir/mir-stat/blob/master/source/mir/stat/inference.d)
- [Data Transformations](https://github.com/libmir/mir-stat/blob/master/source/mir/stat/transform.d)

#### Full Documentation
[mir-stat.libmir.org](http://mir-stat.libmir.org/)

#### Example
```d
@safe pure nothrow
void main()
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
```
