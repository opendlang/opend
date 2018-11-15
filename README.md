[![Dub version](https://img.shields.io/dub/v/mir-random.svg)](http://code.dlang.org/packages/mir-random)
[![Dub downloads](https://img.shields.io/dub/dt/mir-random.svg)](http://code.dlang.org/packages/mir-random)
[![License](https://img.shields.io/dub/l/mir-random.svg)](http://code.dlang.org/packages/mir-random)

[![Circle CI](https://circleci.com/gh/libmir/mir-random.svg?style=svg)](https://circleci.com/gh/libmir/mir-random)
[![Build Status](https://travis-ci.org/libmir/mir-random.svg?branch=master)](https://travis-ci.org/libmir/mir-random)
[![Build status](https://ci.appveyor.com/api/projects/status/github/libmir/mir-random?svg=true)](https://ci.appveyor.com/project/9il/mir-random/branch/master)
[![Gitter](https://img.shields.io/gitter/room/libmir/public.svg)](https://gitter.im/libmir/public)


# mir-random
Advanced Random Number Generators

Documentation - http://docs.random.dlang.io

### Example (3 seconds)
```d
void main()
{
    import mir.random;
    import mir.random.variable: normalVar;
    import mir.random.algorithm: randomSlice;

    auto sample = normalVar.randomSlice(10);

    import std.stdio;
    sample[$.randIndex].writeln;
}
```

<!-- [![Open on run.dlang.io](https://img.shields.io/badge/run.dlang.io-open-blue.svg)](https://run.dlang.io/is/mTVJL6) -->


### Example (10 seconds)
```d
void main()
{
    import mir.random;
    import mir.random.variable: normalVar;
    import mir.random.algorithm: randomSlice;

    // Engines are allocated on stack or global
    auto rng = Random(unpredictableSeed);
    auto sample = rng.randomSlice(normalVar, 10);

    import std.stdio;
    sample[rng.randIndex($)].writeln;
}
```

<!-- [![Open on run.dlang.io](https://img.shields.io/badge/run.dlang.io-open-blue.svg)](https://run.dlang.io/is/F1Iucp) -->


## Comparison with Phobos
 - Does not depend on DRuntime (Better C concept)

##### `random` (new implementation and API)
 - Mir Random `rand!float`/`rand!double`/`rand!real` generates saturated real random numbers in `(-1, 1)`. For example, `rand!real` can produce more than 2^78 unique numbers. In other hand, `std.random.uniform01!real` produces less than `2^31` unique numbers with default Engine.
 - Mir Random fixes Phobos integer underflow bugs.
 - Additional optimization was added for enumerated types.
 - Random [nd-array (ndslice)](https://github.com/libmir/mir-algorithm) generation.
 - Bounded integer generation in `randIndex` uses Daniel Lemire's fast alternative to modulo reduction. The throughput increase measured for `randIndex!uint` on an x86-64 processor compiled with LDC 1.6.0 was 1.40x for `Mt19937_64` and 1.73x for `Xoroshiro128Plus`. The throughput increase measured for `randIndex!ulong` was 2.36x for `Mt19937_64` and 4.25x for `Xoroshiro128Plus`.

##### `random.variable` (new)
 - Uniform
 - Exponential
 - Gamma
 - Normal
 - Cauchy
 - ...

##### `random.ndvariable` (new)
 - Simplex
 - Sphere
 - Multivariate Normal
 - ...

##### `random.algorithm` (new)
 - Ndslice and range API adaptors

##### `random.engine.*` (fixed, reworked, new)
 - `opCall` API instead of range interface is used (similar to C++)
 - No default and copy constructors are allowed for generators.
 - `unpredictableSeed` has not state, returns `size_t`
 - `unpredictableSeed!UIntType` overload for seeds of any unsigned type (merged to Phobos)
 - Any unsigned generators are allowed.
 - `min` property was removed. Any integer generator can normalize its minimum down to zero.
 - Mt19937: +100% performance for initialization. (merged to Phobos)
 - Mt19937: +54% performance for generation. (merged to Phobos)
 - Mt19937: fixed to be more CPU cache friendly. (merged to Phobos)
 - 64-bit Mt19937 initialization is fixed (merged to Phobos)
 - 64-bit Mt19937 is default for 64-bit targets
 - Permuted Congruential Generators (new)
 - SplitMix generators (new)
 - Fixed XorshiftEngine's support for non-`uint` word sizes & allow various shift directions (merged to Phobos)
 - XorshiftStar Generators (new)
 - Xoroshiro128Plus generator (new)
 - Xoshiro256StarStar & Xoshiro128StarStar_32 generators (new)
