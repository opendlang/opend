/++
This module contains algorithms for descriptive statistics.

License: $(LINK2 http://boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: John Michael Hall, Ilya Yaroshenko

Copyright: 2020 Mir Stat Authors.

Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, stat, $1)$(NBSP)
MATHREF = $(REF_ALTTEXT $(TT $2), $2, mir, math, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
T4=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4))
+/

module mir.stat.descriptive;

public import mir.math.stat: gmean, GMeanAccumulator, hmean, mean,
    MeanAccumulator, median, standardDeviation, variance, VarianceAccumulator,
    VarianceAlgo, stdevType;

import mir.internal.utility: isFloatingPoint;
import mir.math.common: fmamath;
import mir.math.sum: Summation, Summator, ResolveSummationType;
import std.traits: isMutable;

/++
Calculates the dispersion of the input.
For an input `x`, this function first centers `x` by subtracting each `e` in `x`
by the result of `centralTendency`, then it transforms the centered values using
the function `transform`, and then finally summarizes that information using
the `summarize` funcion. 
The default functions provided are equivalent to calculating the population
variance. The `centralTendency` default is the `mean` function, which results
in the input being centered about the mean. The default `transform` function
will square the centered values. The default `summarize` function is `mean`,
which will return the mean of the squared centered values.
Params:
    centralTendency = function that will produce the value that the input is centered about, default is `mean`
    transform = function to transform centered values, default squares the centered values
    summarize = function to summarize the transformed centered values, default is `mean`
Returns:
    The dispersion of the input
+/
template dispersion(
    alias centralTendency = mean,
    alias transform = "a * a",
    alias summarize = mean)
{
    import mir.functional: naryFun;
    import mir.ndslice.slice: Slice, SliceKind, sliced, hasAsSlice;

    static if (__traits(isSame, naryFun!transform, transform))
    {
        /++
        Params:
            slice = slice
        +/
        @fmamath auto dispersion(Iterator, size_t N, SliceKind kind)(
            Slice!(Iterator, N, kind) slice)
        {
            import core.lifetime: move;
            import mir.ndslice.topology: map;
            import mir.math.stat: center;

            return summarize(slice.move.center!centralTendency.map!transform);
        }
        
        /// ditto
        @fmamath auto dispersion(T)(scope const T[] ar...)
        {
            return dispersion(ar.sliced);
        }

        /// ditto
        @fmamath auto dispersion(T)(T withAsSlice)
            if (hasAsSlice!T)
        {
            return dispersion(withAsSlice.asSlice);
        }
    }
    else
        alias dispersion = .dispersion!(centralTendency, naryFun!transform, summarize);
}

/// Simple examples
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.functional: naryFun;
    import mir.ndslice.slice: sliced;

    assert(dispersion([1.0, 2, 3]).approxEqual(2.0 / 3));

    assert(dispersion([1.0 + 3i, 2, 3]).approxEqual((-4.0 - 6i) / 3));

    assert(dispersion!(mean!float, "a * a", mean!float)([0, 1, 2, 3, 4, 5].sliced(3, 2)).approxEqual(17.5 / 6));
    
    static assert(is(typeof(dispersion!(mean!float, "a ^^ 2", mean!float)([1, 2, 3])) == float));
}

/// Dispersion of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.dispersion.approxEqual(54.76562 / 12));
}

/// Dispersion of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;

    auto x = [
        [0.0, 1.0, 1.5, 2.0, 3.5, 4.25],
        [2.0, 7.5, 5.0, 1.0, 1.5, 0.0]
    ].fuse;

    assert(x.dispersion.approxEqual(54.76562 / 12));
}

/// Column dispersion of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;

    auto x = [
        [0.0,  1.0, 1.5, 2.0], 
        [3.5, 4.25, 2.0, 7.5],
        [5.0,  1.0, 1.5, 0.0]
    ].fuse;
    auto result = [13.16667 / 3, 7.041667 / 3, 0.1666667 / 3, 30.16667 / 3];

    // Use byDim or alongDim with map to compute dispersion of row/column.
    assert(x.byDim!1.map!dispersion.all!approxEqual(result));
    assert(x.alongDim!0.map!dispersion.all!approxEqual(result));

    // FIXME
    // Without using map, computes the dispersion of the whole slice
    // assert(x.byDim!1.dispersion == x.sliced.dispersion);
    // assert(x.alongDim!0.dispersion == x.sliced.dispersion);
}

/// Can also set functions to change type of dispersion that is used
version(mir_stat_test)
@safe
unittest
{
    import mir.functional: naryFun;
    import mir.math.common: approxEqual, fabs, sqrt;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
              
    alias square = naryFun!"a * a";

    // Other population variance examples
    assert(x.dispersion.approxEqual(54.76562 / 12));
    assert(x.dispersion!mean.approxEqual(54.76562 / 12));
    assert(x.dispersion!(mean, square).approxEqual(54.76562 / 12));
    assert(x.dispersion!(mean, square, mean).approxEqual(54.76562 / 12));
    
    // Population standard deviation
    assert(x.dispersion!(mean, square, mean).sqrt.approxEqual(sqrt(54.76562 / 12)));
    
    // Mean absolute deviation about the mean
    assert(x.dispersion!(mean, fabs, mean).approxEqual(21.0 / 12));
    //Mean absolute deviation about the median
    assert(x.dispersion!(median, fabs, mean).approxEqual(19.25000 / 12));
    //Median absolute deviation about the mean
    assert(x.dispersion!(mean, fabs, median).approxEqual(1.43750));
    //Median absolute deviation about the median
    assert(x.dispersion!(median, fabs, median).approxEqual(1.25000));
}

/++
For integral slices, pass output type to `centralTendency`, `transform`, and 
`summary` functions as template parameter to ensure output type is correct.
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.functional: naryFun;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0, 1, 1, 2, 4, 4,
              2, 7, 5, 1, 2, 0].sliced;

    alias square = naryFun!"a * a";

    auto y = x.dispersion;
    assert(y.approxEqual(50.91667 / 12));
    static assert(is(typeof(y) == double));

    assert(x.dispersion!(mean!float, square, mean!float).approxEqual(50.91667 / 12));
}

/++
Dispersion works for complex numbers and other user-defined types (provided that
the `centralTendency`, `transform`, and `summary` functions are defined for those
types)
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [1.0 + 2i, 2 + 3i, 3 + 4i, 4 + 5i].sliced;
    assert(x.dispersion.approxEqual((0.0+10.0i)/ 4));
}

/// Compute mean tensors along specified dimention of tensors
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: as, iota, alongDim, map, repeat;

    auto x = [
        [0.0, 1, 2],
        [3.0, 4, 5]
    ].fuse;

    assert(x.dispersion.approxEqual(17.5 / 6));

    auto m0 = [2.25, 2.25, 2.25];
    assert(x.alongDim!0.map!dispersion.all!approxEqual(m0));
    assert(x.alongDim!(-2).map!dispersion.all!approxEqual(m0));

    auto m1 = [2.0 / 3, 2.0 / 3];
    assert(x.alongDim!1.map!dispersion.all!approxEqual(m1));
    assert(x.alongDim!(-1).map!dispersion.all!approxEqual(m1));

    assert(iota(2, 3, 4, 5).as!double.alongDim!0.map!dispersion.all!approxEqual(repeat(1800.0 / 2, 3, 4, 5)));
}

/// Arbitrary dispersion
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.functional: naryFun;
    import mir.math.common: approxEqual;

    alias square = naryFun!"a * a";

    assert(dispersion(1.0, 2, 3).approxEqual(2.0 / 3));
    assert(dispersion!(mean!float, square, mean!float)(1, 2, 3).approxEqual(2f / 3));
}

// UFCS UT
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    assert([1.0, 2, 3, 4].dispersion.approxEqual(5.0 / 4));
}

// Confirm type output is correct
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.math.stat: meanType;
    import mir.ndslice.topology: iota, alongDim, map;

    auto x = iota([2, 2], 1);
    auto y = x.alongDim!1.map!dispersion;
    assert(y.all!approxEqual([0.25, 0.25]));
    static assert(is(meanType!(typeof(y)) == double));
}

// @nogc UT
version(mir_stat_test)
@safe pure @nogc nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.dispersion.approxEqual(54.76562 / 12));
}

/++
Skew algorithms.
See Also:
    $(WEB en.wikipedia.org/wiki/Skewness, Skewness).
    $(WEB en.wikipedia.org/wiki/Algorithms_for_calculating_variance, Algorithms for calculating variance).
+/
enum SkewnessAlgo
{
    /++
    Similar to Welford's algorithm for updating variance, but adjusted for
    skewness. Can also `put` another SkewnessAccumulator of the same type, which
    uses the parallel algorithm from Terriberry that extends the work of Chan et
    al. 
    +/
    online,
    
    /++
    Calculates skewness using
    (E(x^^3) - 3 * mu * sigma ^^ 2 + mu ^^ 3) / (sigma ^^ 3) (alowing for
    adjustments for population/sample skewness). This algorithm can be
    numerically unstable.
    +/
    naive,

    /++
    Calculates skewness using a two-pass algorithm whereby the input is first
    scaled by the mean and variance (using $(MATHREF stat, VarianceAccumulator.online))
    and then the sum of cubes is calculated from that. 
    +/
    twoPass,

    /++
    Calculates skewness using a three-pass algorithm whereby the input is first
    scaled by the mean and variance (using $(MATHREF stat, VarianceAccumulator.twoPass))
    and then the sum of cubes is calculated from that. 
    +/
    threePass,

    /++
    Calculates skewness assuming the mean of the input is zero. 
    +/
    assumeZeroMean,
}

///
struct SkewnessAccumulator(T, SkewnessAlgo skewnessAlgo, Summation summation)
    if (isMutable!T && skewnessAlgo == SkewnessAlgo.naive)
{
    import mir.functional: naryFun;
    import std.traits: isIterable;

    ///
    this(Range)(Range r)
        if (isIterable!Range)
    {
        import core.lifetime: move;
        this.put(r.move);
    }

    ///
    this()(T x)
    {
        this.put(x);
    }

    ///
    VarianceAccumulator!(T, VarianceAlgo.naive, summation) varianceAccumulator;

    ///
    size_t count() @property
    {
        return varianceAccumulator.count;
    }

    ///
    F mean(F = T)() @property
    {
        return varianceAccumulator.mean;
    }

    ///
    Summator!(T, summation) sumOfCubes;

    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        foreach(x; r)
        {
            this.put(x);
        }
    }

    ///
    void put()(T x)
    {
        accumulator.put(x);
        sumOfCubes.put(x * x * x);
    }

    ///
    F skewness(F = T)(bool isPopulation) @property
        if (isFloatingPoint!F)
    {
        assert(count > 0, "SkewnessAccumulator.skewness: count must be larger than zero");

        import mir.math.common: sqrt;

        F mu = accumulator.mean!F;
        F varP = accumulator.variance!F(true);
        assert(varP > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");

        F avg_centeredSumOfCubes = cast(F) sumOfCubes.sum / cast(F) count - cast(F) 3 * mu * varP - (mu ^^ 3);

        if (isPopulation == false) {
            F varS = accumulator.variance!F(false);
            assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");

            F mult = (cast(F) (count * count)) / (cast(F) (count - 1) * (count - 2));

            return avg_centeredSumOfCubes / (varS * varS.sqrt) * mult;
        } else {
            
            return avg_centeredSumOfCubes / (varP * varP.sqrt);
        }
    }
}

/// naive
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    enum PopulationTrueCT = true;
    enum PopulationFalseCT = false;
    bool PopulationTrueRT = true;
    bool PopulationFalseRT = false;

    SkewnessAccumulator!(double, SkewnessAlgo.naive, Summation.naive) v;
    v.put(x);
    assert(v.skewness(PopulationTrueRT).approxEqual((117.005859 / 12) / pow(54.765625 / 12, 1.5)));
    assert(v.skewness(PopulationTrueCT).approxEqual((117.005859 / 12) / pow(54.765625 / 12, 1.5)));
    assert(v.skewness(PopulationFalseRT).approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));
    assert(v.skewness(PopulationFalseCT).approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));

    v.put(4.0);
    assert(v.skewness(PopulationTrueRT).approxEqual((100.238166 / 13) / pow(57.019231 / 13, 1.5)));
    assert(v.skewness(PopulationTrueCT).approxEqual((100.238166 / 13) / pow(57.019231 / 13, 1.5)));
    assert(v.skewness(PopulationFalseRT).approxEqual((100.238166 / 13) / pow(57.019231 / 12, 1.5) * (13.0 ^^ 2) / (12.0 * 11.0)));
    assert(v.skewness(PopulationFalseCT).approxEqual((100.238166 / 13) / pow(57.019231 / 12, 1.5) * (13.0 ^^ 2) / (12.0 * 11.0)));
}

///
struct SkewnessAccumulator(T, SkewnessAlgo skewnessAlgo, Summation summation)
    if (isMutable!T && 
        skewnessAlgo == SkewnessAlgo.online)
{
    import std.traits: isIterable;

    ///
    this(Range)(Range r)
        if (isIterable!Range)
    {
        import core.lifetime: move;
        this.put(r.move);
    }

    ///
    this()(T x)
    {
        this.put(x);
    }

    ///
    MeanAccumulator!(T, summation) meanAccumulator;

    ///
    size_t count() @property
    {
        return meanAccumulator.count;
    }

    ///
    F mean(F = T)() @property
    {
        return meanAccumulator.mean;
    }

    ///
    Summator!(T, summation) centeredSumOfSquares;

    ///
    Summator!(T, summation) centeredSumOfCubes;

    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        foreach(x; r)
        {
            this.put(x);
        }
    }

    ///
    void put()(T x)
    {
        T deltaOld = x;
        if (count > 0) {
            deltaOld -= accumulator.mean;
        }
        accumulator.put(x);
        T deltaNew = x - accumulator.mean;
        centeredSumOfCubes.put((deltaOld ^^ 3) * (cast(T) (count - 1) * (count - 2)) / (cast(T) (count * count)) -
                               3 * deltaOld * centeredSumOfSquares.sum / (cast(T) count));
        centeredSumOfSquares.put(deltaOld * deltaNew);
    }

    ///
    void put()(SkewnessAccumulator!(T, skewnessAlgo, summation) v)
    {
        size_t oldCount = count;
        T delta = v.mean;
        if (oldCount > 0) {
            delta -= accumulator.mean;
        }
        accumulator.put!T(v.accumulator);
        centeredSumOfCubes.put(v.centeredSumOfCubes.sum + 
                               delta * delta * delta * (cast(T) v.count * oldCount * (oldCount - v.count)) / (cast(T) (count * count)) +
                               3 * delta * ((cast(T) oldCount) * v.centeredSumOfSquares.sum - (cast(T) v.count) * centeredSumOfSquares.sum) / (cast(T) count));
        centeredSumOfSquares.put(v.centeredSumOfSquares.sum + delta * delta * (cast(T) v.count * oldCount) / (cast(T) count));
    }

    ///
    F skewness(F = T)(bool isPopulation) @property
        if (isFloatingPoint!F)
    {
        assert(count > 0, "SkewnessAccumulator.skewness: count must be larger than zero");

        import mir.math.common: sqrt;

        if (isPopulation == false) {
            assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");

            F varS = centeredSumOfSquares.sum / (cast(F) (count - 1));
            assert(varS > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");

            F mult = (cast(F) (count * count)) / (cast(F) (count - 1) * (count - 2));

            return (centeredSumOfCubes.sum / cast(F) count) / (varS * varS.sqrt) * mult;
        } else {
            F varP = centeredSumOfSquares.sum / (cast(F) count);
            assert(varP > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");

            return (centeredSumOfCubes.sum / cast(F) count) / (varP * varP.sqrt);
        }
    }
}

/// online
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    enum PopulationTrueCT = true;
    enum PopulationFalseCT = false;
    bool PopulationTrueRT = true;
    bool PopulationFalseRT = false;

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.skewness(PopulationTrueRT).approxEqual((117.005859 / 12) / pow(54.765625 / 12, 1.5)));
    assert(v.skewness(PopulationTrueCT).approxEqual((117.005859 / 12) / pow(54.765625 / 12, 1.5)));
    assert(v.skewness(PopulationFalseRT).approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));
    assert(v.skewness(PopulationFalseCT).approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));

    v.put(4.0);
    assert(v.skewness(PopulationTrueRT).approxEqual((100.238166 / 13) / pow(57.019231 / 13, 1.5)));
    assert(v.skewness(PopulationTrueCT).approxEqual((100.238166 / 13) / pow(57.019231 / 13, 1.5)));
    assert(v.skewness(PopulationFalseRT).approxEqual((100.238166 / 13) / pow(57.019231 / 12, 1.5) * (13.0 ^^ 2) / (12.0 * 11.0)));
    assert(v.skewness(PopulationFalseCT).approxEqual((100.238166 / 13) / pow(57.019231 / 12, 1.5) * (13.0 ^^ 2) / (12.0 * 11.0)));
}

// Can put slice
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfCubes.sum.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.sum.approxEqual(12.552083));

    v.put(y);
    assert(v.centeredSumOfCubes.sum.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.sum.approxEqual(54.765625));
}

// Can put SkewnessAccumulator
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfCubes.sum.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.sum.approxEqual(12.552083));

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.centeredSumOfCubes.sum.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.sum.approxEqual(54.765625));
}

///
struct SkewnessAccumulator(T, SkewnessAlgo skewnessAlgo, Summation summation)
    if (isMutable!T && 
        (skewnessAlgo == SkewnessAlgo.twoPass || 
         skewnessAlgo == SkewnessAlgo.threePass))
{
    import mir.functional: naryFun;
    import mir.ndslice.slice: Slice, SliceKind, hasAsSlice;

    ///
    size_t count;

    ///
    Summator!(T, summation) scaledSumOfCubes;

    ///
    this(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
    {
        import core.lifetime: move;
        import mir.ndslice.topology: vmap, map;
        import mir.ndslice.internal: LeftOp;
        import mir.math.common: sqrt;

        static if (skewnessAlgo == SkewnessAlgo.twoPass) {
            auto varianceAccumulator = VarianceAccumulator!(T, VarianceAlgo.online, summation)(slice.lightScope);
        } else static if (skewnessAlgo == SkewnessAlgo.threePass) {
            auto varianceAccumulator = VarianceAccumulator!(T, VarianceAlgo.twoPass, summation)(slice.lightScope);
        }

        count = varianceAccumulator.count;

        assert(varianceAccumulator.variance(true) > 0, "SkewnessAccumulator.this: must divide by positive standard deviation");

        scaledSumOfCubes.put(slice.move.
            vmap(LeftOp!("-", T)(varianceAccumulator.mean)).
            vmap(LeftOp!("/", T)(varianceAccumulator.variance(true).sqrt)).
            map!(naryFun!"a * a * a"));
    }

    ///
    this(U)(U[] array)
    {
        import mir.ndslice.slice: sliced;
        this(array.sliced);
    }

    ///
    this(T)(T withAsSlice)
        if (hasAsSlice!T)
    {
        this(withAsSlice.asSlice);
    }

    ///
    F skewness(F = T)(bool isPopulation) @property
        if (isFloatingPoint!F)
    {
        assert(count > 0, "SkewnessAccumulator.skewness: count must be larger than zero");

        import mir.math.common: sqrt;

        if (isPopulation == false) {
            assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");

            F mult = (cast(F) sqrt(cast(F) (count * (count - 1)))) / (cast(F) (count - 2));

            return cast(F) scaledSumOfCubes.sum / cast(F) count * mult;
        } else {
            return cast(F) scaledSumOfCubes.sum / cast(F) count;
        }
    }
}

/// twoPass & threePass
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    enum PopulationTrueCT = true;
    enum PopulationFalseCT = false;
    bool PopulationTrueRT = true;
    bool PopulationFalseRT = false;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.twoPass, Summation.naive)(x);
    assert(v.skewness(PopulationTrueRT).approxEqual(12.000999 / 12));
    assert(v.skewness(PopulationTrueCT).approxEqual(12.000999 / 12));
    assert(v.skewness(PopulationFalseRT).approxEqual(12.000999 / 12 * sqrt(12.0 * 11.0) / 10.0));
    assert(v.skewness(PopulationFalseCT).approxEqual(12.000999 / 12 * sqrt(12.0 * 11.0) / 10.0));

    auto w = SkewnessAccumulator!(double, SkewnessAlgo.threePass, Summation.naive)(x);
    assert(w.skewness(PopulationTrueRT).approxEqual(12.000999 / 12));
    assert(w.skewness(PopulationTrueCT).approxEqual(12.000999 / 12));
    assert(w.skewness(PopulationFalseRT).approxEqual(12.000999 / 12 * sqrt(12.0 * 11.0) / 10.0));
    assert(w.skewness(PopulationFalseCT).approxEqual(12.000999 / 12 * sqrt(12.0 * 11.0) / 10.0));
}

///
struct SkewnessAccumulator(T, SkewnessAlgo skewnessAlgo, Summation summation)
    if (isMutable!T && skewnessAlgo == SkewnessAlgo.assumeZeroMean)
{
    import mir.ndslice.slice: Slice, SliceKind, hasAsSlice;
    import std.traits: isIterable;

    ///
    this(Range)(Range r)
        if (isIterable!Range)
    {
        this.put(r);
    }

    ///
    this()(T x)
    {
        this.put(x);
    }

    ///
    VarianceAccumulator!(T, VarianceAlgo.assumeZeroMean, summation) varianceAccumulator;

    ///
    size_t count() @property
    {
        return varianceAccumulator.count;
    }
    
    ///
    F mean(F = T)() @property
    {
        return cast(F) 0;
    }

    ///
    Summator!(T, summation) centeredSumOfCubes;


    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        foreach(x; r)
        {
            this.put(x);
        }
    }

    ///
    void put()(T x)
    {
        varianceAccumulator.put(x);
        centeredSumOfCubes.put(x * x * x);
    }

    ///
    void put()(SkewnessAccumulator!(T, skewnessAlgo, summation) v)
    {
        varianceAccumulator.put(v.varianceAccumulator);
        centeredSumOfCubes.put(v.centeredSumOfCubes.sum);
    }

    ///
    F skewness(F = T)(bool isPopulation) @property
        if (isFloatingPoint!F)
    {
        assert(count > 0, "SkewnessAccumulator.skewness: count must be larger than zero");

        import mir.math.common: sqrt;

        F avg_centeredSumOfCubes = cast(F) centeredSumOfCubes.sum / cast(F) count;
        if (isPopulation == false) {
            assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");

            F var = varianceAccumulator.variance!F(false);
            assert(var > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");

            F mult = (cast(F) (count * count)) / (cast(F) (count - 1) * (count - 2));

            return avg_centeredSumOfCubes / (var * var.sqrt) * mult;
        } else {
            F var = varianceAccumulator.variance!F(true);
            assert(var > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");

            return avg_centeredSumOfCubes / (var * var.sqrt);
        }
    }
}

/// assumeZeroMean
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;

    enum PopulationTrueCT = true;
    enum PopulationFalseCT = false;
    bool PopulationTrueRT = true;
    bool PopulationFalseRT = false;

    SkewnessAccumulator!(double, SkewnessAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.skewness(PopulationTrueRT).approxEqual((117.005859 / 12) / pow(54.765625 / 12, 1.5)));
    assert(v.skewness(PopulationTrueCT).approxEqual((117.005859 / 12) / pow(54.765625 / 12, 1.5)));
    assert(v.skewness(PopulationFalseRT).approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * 12.0 ^^ 2 / (11.0 * 10.0)));
    assert(v.skewness(PopulationFalseCT).approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * 12.0 ^^ 2 / (11.0 * 10.0)));

    v.put(4.0);
    assert(v.skewness(PopulationTrueRT).approxEqual((181.005859 / 13) / pow(70.765625 / 13, 1.5)));
    assert(v.skewness(PopulationTrueCT).approxEqual((181.005859 / 13) / pow(70.765625 / 13, 1.5)));
    assert(v.skewness(PopulationFalseRT).approxEqual((181.005859 / 13) / pow(70.765625 / 12, 1.5) * 13.0 ^^ 2 / (12.0 * 11.0)));
    assert(v.skewness(PopulationFalseCT).approxEqual((181.005859 / 13) / pow(70.765625 / 12, 1.5) * 13.0 ^^ 2 / (12.0 * 11.0)));
}

// Can put slices
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = a.center;
    auto x = b[0 .. 6];
    auto y = b[6 .. $];

    SkewnessAccumulator!(double, SkewnessAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfCubes.sum(-11.206543));
    assert(v.varianceAccumulator.centeredSumOfSquares.sum(13.49219));

    v.put(y);
    assert(v.centeredSumOfCubes.sum(117.005859));
    assert(v.varianceAccumulator.centeredSumOfSquares.sum(54.765625));
}

// Can put SkewnessAccumulator
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = a.center;
    auto x = b[0 .. 6];
    auto y = b[6 .. $];

    SkewnessAccumulator!(double, SkewnessAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfCubes.sum(-11.206543));
    assert(v.varianceAccumulator.centeredSumOfSquares.sum(13.49219));

    SkewnessAccumulator!(double, SkewnessAlgo.assumeZeroMean, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.centeredSumOfCubes.sum(117.005859));
    assert(v.varianceAccumulator.centeredSumOfSquares.sum(54.765625));
}

/++
Calculates the skewness of the input

By default, if `F` is not floating point type, then the result will have a
`double` type if `F` is implicitly convertible to a floating point type.

Params:
    F = controls type of output
    skewnessAlgo = algorithm for calculating skewness (default: SkewnessAlgo.online)
    summation: algorithm for calculating sums (default: Summation.appropriate)
Returns:
    The skewness of the input, must be floating point or complex type
+/
template skewness(
    F, 
    SkewnessAlgo skewnessAlgo = SkewnessAlgo.online, 
    Summation summation = Summation.appropriate)
{
    /++
    Params:
        r = range, must be finite iterable
        isPopulation = true if population skewness, false if sample skewness (default)
    +/
    @fmamath stdevType!F skewness(Range)(Range r, bool isPopulation = false)
        if (isIterable!Range)
    {
        import core.lifetime: move;
        alias G = typeof(return);
        auto skewnessAccumulator = SkewnessAccumulator!(G, skewnessAlgo, ResolveSummationType!(summation, Range, G))(r.move);
        return skewnessAccumulator.skewness(isPopulation);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!F skewness(scope const F[] ar...)
    {
        alias G = typeof(return);
        auto skewnessAccumulator = SkewnessAccumulator!(G, skewnessAlgo, ResolveSummationType!(summation, const(G)[], G))(ar);
        return skewnessAccumulator.skewness(false);
    }
}

/// ditto
template skewness(
    SkewnessAlgo skewnessAlgo = SkewnessAlgo.online, 
    Summation summation = Summation.appropriate)
{
    /++
    Params:
        r = range, must be finite iterable
        isPopulation = true if population skewness, false if sample skewness (default)
    +/
    @fmamath stdevType!Range skewness(Range)(Range r, bool isPopulation = false)
        if(isIterable!Range)
    {
        import core.lifetime: move;
        alias F = typeof(return);
        return .skewness!(F, skewnessAlgo, summation)(r.move, isPopulation);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!T skewness(T)(scope const T[] ar...)
    {
        alias F = typeof(return);
        return .skewness!(F, skewnessAlgo, summation)(ar);
    }
}

/// ditto
template skewness(F, string skewnessAlgo, string summation = "appropriate")
{
    mixin("alias skewness = .skewness!(F, SkewnessAlgo." ~ skewnessAlgo ~ ", Summation." ~ summation ~ ");");
}

/// ditto
template skewness(string skewnessAlgo, string summation = "appropriate")
{
    mixin("alias skewness = .skewness!(SkewnessAlgo." ~ skewnessAlgo ~ ", Summation." ~ summation ~ ");");
}

/// Simple example
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    assert(skewness([1.0, 2, 3]).approxEqual(0.0));

    assert(skewness([1.0, 2, 4]).approxEqual((2.222222 / 3) / pow(4.666667 / 2, 1.5) * (3.0 ^^ 2) / (2.0 * 1.0)));
    assert(skewness([1.0, 2, 4], true).approxEqual((2.222222 / 3) / pow(4.666667 / 3, 1.5)));
    
    assert(skewness!float([0, 1, 2, 3, 4, 6].sliced(3, 2)).approxEqual(0.462910));
    
    static assert(is(typeof(skewness!float([1, 2, 3])) == float));
}

/// Skewness of vector
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.skewness.approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));
}

/// Skewness of matrix
version(mir_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.fuse: fuse;

    auto x = [
        [0.0, 1.0, 1.5, 2.0, 3.5, 4.25],
        [2.0, 7.5, 5.0, 1.0, 1.5, 0.0]
    ].fuse;

    assert(x.skewness.approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));
}

/// Column skewness of matrix
version(mir_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;

    auto x = [
        [0.0,  1.0, 1.5, 2.0], 
        [3.5, 4.25, 2.0, 7.5],
        [5.0,  1.0, 1.5, 0.0]
    ].fuse;
    auto result = [-1.090291, 1.732051, 1.732051, 1.229809];

    // Use byDim or alongDim with map to compute skewness of row/column.
    assert(x.byDim!1.map!skewness.all!approxEqual(result));
    assert(x.alongDim!0.map!skewness.all!approxEqual(result));

    // FIXME
    // Without using map, computes the skewness of the whole slice
    // assert(x.byDim!1.skewness == x.sliced.skewness);
    // assert(x.alongDim!0.skewness == x.sliced.skewness);
}

/// Can also set algorithm type
version(mir_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual, pow, sqrt;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto x = a + 100_000_000_000;

    // The default online algorithm is numerically unstable in this case
    auto y = x.skewness;
    assert(!y.approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));

    // The naive algorithm has an assert error in this case because standard
    // deviation is calculated naively as zero. The skewness formula would then
    // be dividing by zero. 
    //auto z0 = x.skewness!(real, "naive");
    
    // The two-pass algorithm is also numerically unstable in this case
    auto z1 = x.skewness!"twoPass";
    assert(!z1.approxEqual(12.000999 / 12 * sqrt(12.0 * 11.0) / 10.0));
    assert(!z1.approxEqual(y));
    
    // However, the three-pass algorithm is numerically stable in this case
    auto z2 = x.skewness!"threePass";
    assert(z2.approxEqual((12.000999 / 12) * sqrt(12.0 * 11.0) / 10.0));
    assert(!z2.approxEqual(y));

    // And the assumeZeroMean algorithm provides the incorrect answer, as expected
    auto z3 = x.skewness!"assumeZeroMean";
    assert(!z3.approxEqual(y));
}

// Alt version with x a tenth of above's value
version(mir_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual, pow, sqrt;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto x = a + 10_000_000_000;

    // The default online algorithm is numerically stable in this case
    auto y = x.skewness;
    assert(y.approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));

    // The naive algorithm has an assert error in this case because standard
    // deviation is calculated naively as zero. The skewness formula would then
    // be dividing by zero. 
    //auto z0 = x.skewness!(real, "naive");
    
    // The two-pass algorithm is  numerically stable in this case
    auto z1 = x.skewness!"twoPass";
    assert(z1.approxEqual(12.000999 / 12 * sqrt(12.0 * 11.0) / 10.0));
    assert(z1.approxEqual(y));
    
    // However, the three-pass algorithm is numerically stable in this case
    auto z2 = x.skewness!"threePass";
    assert(z2.approxEqual((12.000999 / 12) * sqrt(12.0 * 11.0) / 10.0));
    assert(z2.approxEqual(y));

    // And the assumeZeroMean algorithm provides the incorrect answer, as expected
    auto z3 = x.skewness!"assumeZeroMean";
    assert(!z3.approxEqual(y));
}

/// Can also set algorithm or output type
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;

    //Set population skewness, skewness algorithm, sum algorithm or output type

    auto a = [1.0, 1e98, 1, -1e98].sliced;
    auto x = a * 10_000;

    bool populationTrueRT = true;
    bool populationFalseRT = false;
    enum PopulationTrueCT = true;

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean 
    from the second and fourth numbers has no effect. Further, after centering 
    and squaring `x`, the first and third numbers in the slice have precision 
    too low to be included in the centered sum of squares. 
    +/
    assert(x.skewness(populationFalseRT).approxEqual(0.0));
    assert(x.skewness(populationTrueRT).approxEqual(0.0));
    assert(x.skewness(PopulationTrueCT).approxEqual(0.0));

    assert(x.skewness!("online").approxEqual(0.0));
    assert(x.skewness!("online", "kbn").approxEqual(0.0));
    assert(x.skewness!("online", "kb2").approxEqual(0.0));
    assert(x.skewness!("online", "precise").approxEqual(0.0));
    assert(x.skewness!(double, "online", "precise").approxEqual(0.0));
    assert(x.skewness!(double, "online", "precise")(populationTrueRT).approxEqual(0.0));

    auto y = [uint.max - 2, uint.max - 1, uint.max].sliced;
    auto z = y.skewness!(ulong, "threePass");
    assert(z == 0.0);
    static assert(is(typeof(z) == double));
}

/++
For integral slices, can pass output type as template parameter to ensure output
type is correct.
+/
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0, 1, 1, 2, 4, 4,
              2, 7, 5, 1, 2, 0].sliced;

    auto y = x.skewness;
    assert(y.approxEqual(0.925493));
    static assert(is(typeof(y) == double));

    assert(x.skewness!float.approxEqual(0.925493));
}

/++
Skewness works for other user-defined types (provided they
can be converted to a floating point)
+/
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    
    static struct Foo {
        float x;
        alias x this;
    }
    
    Foo[] foo = [Foo(1f), Foo(2f), Foo(3f)];
    assert(foo.skewness == 0f);
}

/// Compute skewness along specified dimention of tensors
version(mir_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: as, iota, alongDim, map, repeat;

    auto x = [
        [0.0, 1, 3],
        [3.0, 4, 5],
        [6.0, 7, 7],
    ].fuse;

    assert(x.skewness.approxEqual(-0.308571));

    auto m0 = [0, 0.0, 0.0];
    assert(x.alongDim!0.map!skewness.all!approxEqual(m0));
    assert(x.alongDim!(-2).map!skewness.all!approxEqual(m0));

    auto m1 = [0.935220, 0.0, -1.732051];
    assert(x.alongDim!1.map!skewness.all!approxEqual(m1));
    assert(x.alongDim!(-1).map!skewness.all!approxEqual(m1));
    assert(iota(3, 4, 5, 6).as!double.alongDim!0.map!skewness.all!approxEqual(repeat(0.0, 4, 5, 6)));
}

/// Arbitrary skewness
version(mir_test)
@safe pure nothrow @nogc
unittest
{
    assert(skewness(1.0, 2, 3) == 0.0);
    assert(skewness!float(1, 2, 3) == 0f);
}

// Check skewness vector UFCS
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    assert([1.0, 2, 3, 4].skewness.approxEqual(0.0));
}

// Double-check correct output types
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: iota, alongDim, map;

    auto x = iota([3, 3], 1);
    auto y = x.alongDim!1.map!skewness;
    assert(y.all!approxEqual([0.0, 0.0, 0.0]));
    static assert(is(stdevType!(typeof(y)) == double));
}

// @nogc skewness test
version(mir_test)
@safe pure @nogc nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.skewness.approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));
    assert(x.sliced.skewness!float.approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));
}

// Test skewness with values
version(mir_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.skewness.approxEqual(1.149008));
    assert(x.skewness(true).approxEqual(1.000083));
    assert(x.skewness!"naive".approxEqual(1.149008));
    assert(x.skewness!"naive"(true).approxEqual(1.000083));
    assert(x.skewness!"twoPass".approxEqual(1.149008));
    assert(x.skewness!"twoPass"(true).approxEqual(1.000083));
    assert(x.skewness!"threePass".approxEqual(1.149008));
    assert(x.skewness!"threePass"(true).approxEqual(1.000083));

    auto y = x.center;
    assert(y.skewness!"assumeZeroMean".approxEqual(1.149008));
    assert(y.skewness!"assumeZeroMean"(true).approxEqual(1.000083));
}

/++
Kurtosis algorithms.
See Also:
    $(WEB en.wikipedia.org/wiki/Kurtosis, Kurtosis).
    $(WEB en.wikipedia.org/wiki/Algorithms_for_calculating_variance, Algorithms for calculating variance).
+/
enum KurtosisAlgo
{
    /++
    Similar to Welford's algorithm for updating variance, but adjusted for
    kurtosis. Can also `put` another KurtosisAccumulator of the same type, which
    uses the parallel algorithm from Terriberry that extends the work of Chan et
    al. 
    +/
    online,
    /++
    Calculates kurtosis using
    (E(x^^4) - 4 * E(x) * E(x ^^ 3) + 6 * (E(x) ^^ 2) E(X ^^ 2) + 3 E(x) ^^ 4) / sigma ^ 2 
    (allowing for adjustments for population/sample kurtosis). This algorithm
    can be numerically unstable.
    +/
    naive,

    /++
    Calculates kurtosis using a two-pass algorithm whereby the input is first
    scaled by the mean and variance (using $(MATHREF stat, VarianceAccumulator.online))
    and then the sum of quarts is calculated from that. 
    +/
    twoPass,

    /++
    Calculates kurtosis using a three-pass algorithm whereby the input is first
    scaled by the mean and variance (using $(MATHREF stat, VarianceAccumulator.twoPass))
    and then the sum of quarts is calculated from that. 
    +/
    threePass,

    /++
    Calculates kurtosis assuming the mean of the input is zero. 
    +/
    assumeZeroMean,
}

///
struct KurtosisAccumulator(T, KurtosisAlgo kurtosisAlgo, Summation summation)
    if (isMutable!T && kurtosisAlgo == KurtosisAlgo.naive)
{
    import std.traits: isIterable;

    ///
    this(Range)(Range r)
        if (isIterable!Range)
    {
        import core.lifetime: move;
        this.put(r.move);
    }

    ///
    this()(T x)
    {
        this.put(x);
    }

    ///
    MeanAccumulator!(T, summation) meanAccumulator;

    ///
    size_t count() @property
    {
        return meanAccumulator.count;
    }

    ///
    F mean(F = T)() @property
    {
        return meanAccumulator.mean;
    }

    ///
    Summator!(T, summation) sumOfSquares;

    ///
    Summator!(T, summation) sumOfCubes;

    ///
    Summator!(T, summation) sumOfQuarts;

    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        foreach(x; r)
        {
            this.put(x);
        }
    }

    ///
    void put()(T x)
    {
        meanAccumulator.put(x);
        T square = x * x;
        sumOfSquares.put(square);
        T cube = square * x;
        sumOfCubes.put(cube);
        sumOfQuarts.put(cube * x);
    }

    ///
    F kurtosis(F = T)(bool isPopulation, bool isRaw) @property
        if (isFloatingPoint!F)
    {
        assert(count > 0, "KurtosisAccumulator.kurtosis: count must be larger than zero");

        F mu = meanAccumulator.mean!F;
        F avg_sumOfSquares = cast(F) sumOfSquares.sum / cast(F) count;
        F varP = avg_sumOfSquares - mu ^^ 2;
        assert(varP > 0, "KurtosisAccumulator.kurtosis: variance must be larger than zero");

        F avg_sumOfCubes = cast(F) sumOfCubes.sum / cast(F) count;
        F avg_sumOfQuarts = cast(F) sumOfQuarts.sum / cast(F) count;
        F fourthCentralMoment = avg_sumOfQuarts - 
            4 * mu * avg_sumOfCubes + 
            6 * mu ^^ 2 * avg_sumOfSquares - 
            3 * (mu ^^ 4);
        F kurt = fourthCentralMoment / (varP * varP);

        if (isPopulation == false) {
            assert(count > 3, "KurtosisAccumulator.kurtosis: count must be larger than three");

            F mult1 = (cast(F) ((count - 1) * (count + 1))) / (cast(F) (count - 2) * (count - 3));
            F mult2 = (cast(F) ((count - 1) * (count - 1))) / (cast(F) (count - 2) * (count - 3));
            F excessKurtosis = kurt * mult1 - cast(F) 3 * mult2;
            if (isRaw) {
                return excessKurtosis + cast(F) 3;
            } else {
                return excessKurtosis;
            }
        } else {
            if (isRaw) {
                return kurt;
            } else {
                return kurt - cast(F) 3;
            }
        }
    }
}

/// naive
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    enum PopulationTrueCT = true;
    enum PopulationFalseCT = false;
    bool PopulationTrueRT = true;
    bool PopulationFalseRT = false;
    enum RawTrueCT = true;
    enum RawFalseCT = false;
    bool RawTrueRT = true;
    bool RawFalseRT = false;

    KurtosisAccumulator!(double, KurtosisAlgo.naive, Summation.naive) v;
    v.put(x);
    assert(v.kurtosis(PopulationTrueRT, RawTrueRT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0)));
    assert(v.kurtosis(PopulationTrueCT, RawTrueCT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0)));
    assert(v.kurtosis(PopulationTrueRT, RawFalseRT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) - 3.0));
    assert(v.kurtosis(PopulationTrueCT, RawFalseCT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) - 3.0));
    assert(v.kurtosis(PopulationFalseRT, RawFalseRT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
    assert(v.kurtosis(PopulationFalseCT, RawFalseCT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
    assert(v.kurtosis(PopulationFalseRT, RawTrueRT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0) + 3.0));
    assert(v.kurtosis(PopulationFalseCT, RawTrueCT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0) + 3.0));

    v.put(4.0);
    assert(v.kurtosis(PopulationTrueRT, RawTrueRT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0)));
    assert(v.kurtosis(PopulationTrueCT, RawTrueCT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0)));
    assert(v.kurtosis(PopulationTrueRT, RawFalseRT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) - 3.0));
    assert(v.kurtosis(PopulationTrueCT, RawFalseCT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) - 3.0));
    assert(v.kurtosis(PopulationFalseRT, RawFalseRT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0)));
    assert(v.kurtosis(PopulationFalseCT, RawFalseCT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0)));
    assert(v.kurtosis(PopulationFalseRT, RawTrueRT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0) + 3.0));
    assert(v.kurtosis(PopulationFalseCT, RawTrueCT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0) + 3.0));
}

///
struct KurtosisAccumulator(T, KurtosisAlgo kurtosisAlgo, Summation summation)
    if (isMutable!T && 
        kurtosisAlgo == KurtosisAlgo.online)
{
    import std.traits: isIterable;

    ///
    this(Range)(Range r)
        if (isIterable!Range)
    {
        import core.lifetime: move;
        this.put(r.move);
    }

    ///
    this()(T x)
    {
        this.put(x);
    }

    ///
    MeanAccumulator!(T, summation) meanAccumulator;

    ///
    size_t count() @property
    {
        return meanAccumulator.count;
    }

    ///
    F mean(F = T)() @property
    {
        return meanAccumulator.mean;
    }

    ///
    Summator!(T, summation) centeredSumOfSquares;

    ///
    Summator!(T, summation) centeredSumOfCubes;

    ///
    Summator!(T, summation) centeredSumOfQuarts;

    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        foreach(x; r)
        {
            this.put(x);
        }
    }

    ///
    void put()(T x)
    {
        T deltaOld = x;
        if (count > 0) {
            deltaOld -= meanAccumulator.mean;
        }
        meanAccumulator.put(x);
        T deltaNew = x - meanAccumulator.mean;
        centeredSumOfQuarts.put((deltaOld * deltaOld * deltaOld * deltaOld) * (cast(T) ((count - 1) * (count * count - 3 * count + 3))) / (cast(T) (count * count * count)) +
                                cast(T) 6 * deltaOld * deltaOld * centeredSumOfSquares.sum / (cast(T) (count * count)) -
                                cast(T) 4 * deltaOld * (centeredSumOfCubes.sum / (cast(T) count)));
        centeredSumOfCubes.put((deltaOld * deltaOld * deltaOld) * cast(T) (count - 1) * (count - 2) / (cast(T) (count * count)) -
                               cast(T) 3 * deltaOld * centeredSumOfSquares.sum / (cast(T) count));
        centeredSumOfSquares.put(deltaOld * deltaNew);
    }

    ///
    void put()(KurtosisAccumulator!(T, kurtosisAlgo, summation) v)
    {
        size_t oldCount = count;
        T delta = v.mean;
        if (oldCount > 0) {
            delta -= meanAccumulator.mean;
        }
        meanAccumulator.put!T(v.meanAccumulator);
        centeredSumOfQuarts.put(v.centeredSumOfQuarts.sum + 
                               delta * delta * delta * delta * (cast(T) ((v.count * oldCount) * (oldCount * oldCount - v.count * oldCount + v.count * v.count))) / (cast(T) (count * count * count)) +
                               cast(T) 6 * delta * delta * (cast(T) (oldCount * oldCount) * v.centeredSumOfSquares.sum + cast(T) (v.count * v.count) * centeredSumOfSquares.sum) / (cast(T) (count * count)) +
                               cast(T) 4 * delta * (cast(T) oldCount * v.centeredSumOfCubes.sum - cast(T) v.count * centeredSumOfCubes.sum) / (cast(T) count));
        centeredSumOfCubes.put(v.centeredSumOfCubes.sum + 
                               delta * delta * delta * cast(T) v.count * cast(T) oldCount * cast(T) (oldCount - v.count) / cast(T) (count * count) +
                               cast(T) 3 * delta * (cast(T) oldCount * v.centeredSumOfSquares.sum - cast(T) v.count * centeredSumOfSquares.sum) / cast(T) count);
        centeredSumOfSquares.put(v.centeredSumOfSquares.sum + delta * delta * cast(T) v.count * cast(T) oldCount / cast(T) count);
    }

    ///
    F kurtosis(F = T)(bool isPopulation, bool isRaw) @property
        if (isFloatingPoint!F)
    {
        assert(count > 0, "KurtosisAccumulator.kurtosis: count must be larger than zero");

        if (isPopulation == false) {
            assert(count > 3, "KurtosisAccumulator.kurtosis: count must be larger than three");

            F varS = (cast(F) centeredSumOfSquares.sum) / (cast(F) (count - 1));
            assert(varS > 0, "KurtosisAccumulator.kurtosis: variance must be larger than zero");

            F mult1 = (cast(F) (count * (count + 1))) / (cast(F) (count - 1) * (count - 2) * (count - 3));
            F mult2 = (cast(F) ((count - 1) * (count - 1))) / (cast(F) (count - 2) * (count - 3));
            F excessKurtosis = (cast(F) centeredSumOfQuarts.sum) / (varS * varS) * mult1 - cast(F) 3 * mult2;
            if (isRaw) {
                return excessKurtosis + cast(F) 3;
            } else {
                return excessKurtosis;
            }
        } else {
            F varP = (cast(F) centeredSumOfSquares.sum) / (cast(F) count);
            assert(varP > 0, "KurtosisAccumulator.kurtosis: variance must be larger than zero");

            F rawKurtosis = ((cast(F) centeredSumOfQuarts.sum) / (cast(F) count)) / (varP * varP);

            if (isRaw) {
                return rawKurtosis;
            } else {
                return rawKurtosis - cast(F) 3;
            }
        }
    }
}

/// online
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    enum PopulationTrueCT = true;
    enum PopulationFalseCT = false;
    bool PopulationTrueRT = true;
    bool PopulationFalseRT = false;
    enum RawTrueCT = true;
    enum RawFalseCT = false;
    bool RawTrueRT = true;
    bool RawFalseRT = false;

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.kurtosis(PopulationTrueRT, RawTrueRT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0)));
    assert(v.kurtosis(PopulationTrueCT, RawTrueCT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0)));
    assert(v.kurtosis(PopulationTrueRT, RawFalseRT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) - 3.0));
    assert(v.kurtosis(PopulationTrueCT, RawFalseCT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) - 3.0));
    assert(v.kurtosis(PopulationFalseRT, RawFalseRT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
    assert(v.kurtosis(PopulationFalseCT, RawFalseCT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
    assert(v.kurtosis(PopulationFalseRT, RawTrueRT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0) + 3.0));
    assert(v.kurtosis(PopulationFalseCT, RawTrueCT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0) + 3.0));

    v.put(4.0);
    assert(v.kurtosis(PopulationTrueRT, RawTrueRT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0)));
    assert(v.kurtosis(PopulationTrueCT, RawTrueCT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0)));
    assert(v.kurtosis(PopulationTrueRT, RawFalseRT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) - 3.0));
    assert(v.kurtosis(PopulationTrueCT, RawFalseCT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) - 3.0));
    assert(v.kurtosis(PopulationFalseRT, RawFalseRT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0)));
    assert(v.kurtosis(PopulationFalseCT, RawFalseCT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0)));
    assert(v.kurtosis(PopulationFalseRT, RawTrueRT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0) + 3.0));
    assert(v.kurtosis(PopulationFalseCT, RawTrueCT).approxEqual((745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0) + 3.0));
}

// Can put slice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.sum.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.sum.approxEqual(12.552083));

    v.put(y);
    assert(v.centeredSumOfQuarts.sum.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.sum.approxEqual(54.765625));
}

// Can put KurtosisAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.sum.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.sum.approxEqual(12.552083));

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.sum.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.sum.approxEqual(54.765625));
}

///
struct KurtosisAccumulator(T, KurtosisAlgo kurtosisAlgo, Summation summation)
    if (isMutable!T && 
        (kurtosisAlgo == KurtosisAlgo.twoPass || 
         kurtosisAlgo == KurtosisAlgo.threePass))
{
    import mir.functional: naryFun;
    import mir.ndslice.slice: Slice, SliceKind, hasAsSlice;

    ///
    this(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
    {
        import core.lifetime: move;
        import mir.ndslice.topology: vmap, map;
        import mir.ndslice.internal: LeftOp;
        import mir.math.common: sqrt;

        static if (kurtosisAlgo == KurtosisAlgo.twoPass) {
            auto varianceAccumulator = VarianceAccumulator!(T, VarianceAlgo.online, summation)(slice.lightScope);
        } else static if (kurtosisAlgo == KurtosisAlgo.threePass) {
            auto varianceAccumulator = VarianceAccumulator!(T, VarianceAlgo.twoPass, summation)(slice.lightScope);
        }

        count = varianceAccumulator.count;

        assert(varianceAccumulator.variance(true) > 0, "KurtosisAccumulator.this: must divide by positive standard deviation");

        scaledSumOfQuarts.put(slice.move.
            vmap(LeftOp!("-", T)(varianceAccumulator.mean)).
            vmap(LeftOp!("/", T)(varianceAccumulator.variance(true).sqrt)).
            map!(naryFun!"a * a * a * a"));
    }

    ///
    this(U)(U[] array)
    {
        import mir.ndslice.slice: sliced;
        this(array.sliced);
    }

    ///
    this(T)(T withAsSlice)
        if (hasAsSlice!T)
    {
        this(withAsSlice.asSlice);
    }

    ///
    size_t count;

    ///
    Summator!(T, summation) scaledSumOfQuarts;

    ///
    F kurtosis(F = T)(bool isPopulation, bool isRaw) @property
        if (isFloatingPoint!F)
    {
        assert(count > 0, "KurtosisAccumulator.kurtosis: count must be larger than zero");

        if (isPopulation == false) {
            assert(count > 3, "KurtosisAccumulator.kurtosis: count must be larger than three");

            F mult1 = (cast(F) ((count - 1) * (count + 1))) / (cast(F) (count - 2) * (count - 3));
            F mult2 = (cast(F) ((count - 1) * (count - 1))) / (cast(F) (count - 2) * (count - 3));

            F excessKurtosis = (cast(F) scaledSumOfQuarts.sum / cast(F) count) * mult1 - 3 * mult2;
            if (isRaw) {
                return excessKurtosis + cast(F) 3;
            } else {
                return excessKurtosis;
            }
        } else {
            if (isRaw) {
                return scaledSumOfQuarts.sum / cast(F) count;
            } else {
                return scaledSumOfQuarts.sum / cast(F) count - cast(F) 3;
            }
        }
    }  
}

/// twoPass & threePass
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    enum PopulationTrueCT = true;
    enum PopulationFalseCT = false;
    bool PopulationTrueRT = true;
    bool PopulationFalseRT = false;
    enum RawTrueCT = true;
    enum RawFalseCT = false;
    bool RawTrueRT = true;
    bool RawFalseRT = false;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.twoPass, Summation.naive)(x);
    assert(v.kurtosis(PopulationTrueRT, RawTrueRT).approxEqual(38.062853 / 12));
    assert(v.kurtosis(PopulationTrueCT, RawTrueCT).approxEqual(38.062853 / 12));
    assert(v.kurtosis(PopulationTrueRT, RawFalseRT).approxEqual(38.062853 / 12 - 3.0));
    assert(v.kurtosis(PopulationTrueCT, RawFalseCT).approxEqual(38.062853 / 12 - 3.0));
    assert(v.kurtosis(PopulationFalseRT, RawTrueRT).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)) + 3.0);
    assert(v.kurtosis(PopulationFalseCT, RawTrueCT).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)) + 3.0);
    assert(v.kurtosis(PopulationFalseRT, RawFalseRT).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
    assert(v.kurtosis(PopulationFalseCT, RawFalseCT).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));

    auto w = KurtosisAccumulator!(double, KurtosisAlgo.threePass, Summation.naive)(x);
    assert(v.kurtosis(PopulationTrueRT, RawTrueRT).approxEqual(38.062853 / 12));
    assert(v.kurtosis(PopulationTrueCT, RawTrueCT).approxEqual(38.062853 / 12));
    assert(v.kurtosis(PopulationTrueRT, RawFalseRT).approxEqual(38.062853 / 12 - 3.0));
    assert(v.kurtosis(PopulationTrueCT, RawFalseCT).approxEqual(38.062853 / 12 - 3.0));
    assert(v.kurtosis(PopulationFalseRT, RawTrueRT).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)) + 3.0);
    assert(v.kurtosis(PopulationFalseCT, RawTrueCT).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)) + 3.0);
    assert(v.kurtosis(PopulationFalseRT, RawFalseRT).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
    assert(v.kurtosis(PopulationFalseCT, RawFalseCT).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
}

///
struct KurtosisAccumulator(T, KurtosisAlgo kurtosisAlgo, Summation summation)
    if (isMutable!T && kurtosisAlgo == KurtosisAlgo.assumeZeroMean)
{
    import mir.ndslice.slice: Slice, SliceKind, hasAsSlice;
    import std.traits: isIterable;

    ///
    this(Range)(Range r)
        if (isIterable!Range)
    {
        this.put(r);
    }

    ///
    this()(T x)
    {
        this.put(x);
    }

    ///
    VarianceAccumulator!(T, VarianceAlgo.assumeZeroMean, summation) varianceAccumulator;

    ///
    size_t count() @property
    {
        return varianceAccumulator.count;
    }
    
    ///
    F mean(F = T)() @property
    {
        return cast(F) 0;
    }

    ///
    Summator!(T, summation) centeredSumOfQuarts;

    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        foreach(x; r)
        {
            this.put(x);
        }
    }

    ///
    void put()(T x)
    {
        varianceAccumulator.put(x);
        centeredSumOfQuarts.put(x * x * x * x);
    }

    ///
    void put()(KurtosisAccumulator!(T, kurtosisAlgo, summation) v)
    {
        varianceAccumulator.put(v.varianceAccumulator);
        centeredSumOfQuarts.put(v.centeredSumOfQuarts.sum);
    }

    ///
    F kurtosis(F = T)(bool isPopulation, bool isRaw) @property
        if (isFloatingPoint!F)
    {
        assert(count > 0, "KurtosisAccumulator.kurtosis: count must be larger than zero");

        if (isPopulation == false) {
            assert(count > 3, "KurtosisAccumulator.kurtosis: count must be larger than three");

            F varS = varianceAccumulator.variance!F(false);
            assert(varS > 0, "KurtosisAccumulator.kurtosis: variance must be larger than zero");

            F mult1 = (cast(F) (count * (count + 1))) / (cast(F) (count - 1) * (count - 2) * (count - 3));
            F mult2 = (cast(F) ((count - 1) * (count - 1))) / (cast(F) (count - 2) * (count - 3));

            F excessKurtosis = (cast(F) centeredSumOfQuarts.sum) / (varS * varS) * mult1 - 3 * mult2;
            if (isRaw) {
                return excessKurtosis + cast(F) 3;
            } else {
                return excessKurtosis;
            }
        } else {
            F varP = varianceAccumulator.variance!F(true);
            assert(varP > 0, "KurtosisAccumulator.kurtosis: variance must be larger than zero");

            F rawKurtosis = (cast(F) centeredSumOfQuarts.sum / cast(F) count) / (varP * varP);
            if (isRaw) {
                return rawKurtosis;
            } else {
                return rawKurtosis - cast(F) 3;
            }
        }
    }
}

/// assumeZeroMean
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.stat: center;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;

    enum PopulationTrueCT = true;
    enum PopulationFalseCT = false;
    bool PopulationTrueRT = true;
    bool PopulationFalseRT = false;
    enum RawTrueCT = true;
    enum RawFalseCT = false;
    bool RawTrueRT = true;
    bool RawFalseRT = false;

    KurtosisAccumulator!(double, KurtosisAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.kurtosis(PopulationTrueRT, RawTrueRT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0)));
    assert(v.kurtosis(PopulationTrueCT, RawTrueCT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0)));
    assert(v.kurtosis(PopulationTrueRT, RawFalseRT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) - 3.0));
    assert(v.kurtosis(PopulationTrueCT, RawFalseCT).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) - 3.0));
    assert(v.kurtosis(PopulationFalseRT, RawFalseRT).approxEqual(792.784119 / pow(54.765625 / 11, 2.0) * (12.0 * 13.0) / (11.0 * 10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
    assert(v.kurtosis(PopulationFalseCT, RawFalseCT).approxEqual(792.784119 / pow(54.765625 / 11, 2.0) * (12.0 * 13.0) / (11.0 * 10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
    assert(v.kurtosis(PopulationFalseRT, RawTrueRT).approxEqual(792.784119 / pow(54.765625 / 11, 2.0) * (12.0 * 13.0) / (11.0 * 10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0) + 3.0));
    assert(v.kurtosis(PopulationFalseCT, RawTrueCT).approxEqual(792.784119 / pow(54.765625 / 11, 2.0) * (12.0 * 13.0) / (11.0 * 10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0) + 3.0));

    v.put(4.0);
    assert(v.kurtosis(PopulationTrueRT, RawTrueRT).approxEqual((1048.784119 / 13) / pow(70.765625 / 13, 2.0)));
    assert(v.kurtosis(PopulationTrueCT, RawTrueCT).approxEqual((1048.784119 / 13) / pow(70.765625 / 13, 2.0)));
    assert(v.kurtosis(PopulationTrueRT, RawFalseRT).approxEqual((1048.784119 / 13) / pow(70.765625 / 13, 2.0) - 3.0));
    assert(v.kurtosis(PopulationTrueCT, RawFalseCT).approxEqual((1048.784119 / 13) / pow(70.765625 / 13, 2.0) - 3.0));
    assert(v.kurtosis(PopulationFalseRT, RawFalseRT).approxEqual(1048.784119 / pow(70.765625 / 12, 2.0) * (13.0 * 14.0) / (12.0 * 11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0)));
    assert(v.kurtosis(PopulationFalseCT, RawFalseCT).approxEqual(1048.784119 / pow(70.765625 / 12, 2.0) * (13.0 * 14.0) / (12.0 * 11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0)));
    assert(v.kurtosis(PopulationFalseRT, RawTrueRT).approxEqual(1048.784119 / pow(70.765625 / 12, 2.0) * (13.0 * 14.0) / (12.0 * 11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0) + 3.0));
    assert(v.kurtosis(PopulationFalseCT, RawTrueCT).approxEqual(1048.784119 / pow(70.765625 / 12, 2.0) * (13.0 * 14.0) / (12.0 * 11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0) + 3.0));
}

// Can put slice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.stat: center;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = a.center;
    auto x = b[0 .. 6];
    auto y = b[6 .. $];

    KurtosisAccumulator!(double, KurtosisAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.sum.approxEqual(52.44613647));
    assert(v.varianceAccumulator.centeredSumOfSquares.sum.approxEqual(13.4921875));

    v.put(y);
    assert(v.centeredSumOfQuarts.sum.approxEqual(792.784119));
    assert(v.varianceAccumulator.centeredSumOfSquares.sum.approxEqual(54.765625));
}

// Can put KurtosisAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.stat: center;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = a.center;
    auto x = b[0 .. 6];
    auto y = b[6 .. $];

    enum PopulationTrueCT = true;
    enum PopulationFalseCT = false;
    bool PopulationTrueRT = true;
    bool PopulationFalseRT = false;
    enum RawTrueCT = true;
    enum RawFalseCT = false;
    bool RawTrueRT = true;
    bool RawFalseRT = false;

    KurtosisAccumulator!(double, KurtosisAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.sum.approxEqual(52.44613647));
    assert(v.varianceAccumulator.centeredSumOfSquares.sum.approxEqual(13.4921875));

    KurtosisAccumulator!(double, KurtosisAlgo.assumeZeroMean, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.sum.approxEqual(792.784119));
    assert(v.varianceAccumulator.centeredSumOfSquares.sum.approxEqual(54.765625));
}

/++
Calculates the kurtosis of the input

By default, if `F` is not floating point type, then the result will have a
`double` type if `F` is implicitly convertible to a floating point type.

Params:
    F = controls type of output
    kurtosisAlgo = algorithm for calculating kurtosis (default: KurtosisAlgo.online)
    summation: algorithm for calculating sums (default: Summation.appropriate)
Returns:
    The kurtosis of the input, must be floating point or complex type
+/
template kurtosis(
    F, 
    KurtosisAlgo kurtosisAlgo = KurtosisAlgo.online, 
    Summation summation = Summation.appropriate)
{
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
        isPopulation = true if population kurtosis, false if sample kurtosis (default)
        isRaw = true if raw kurtosis, false if excess kurtosis (default)
    +/
    @fmamath stdevType!F kurtosis(Range)(Range r, bool isPopulation = false, bool isRaw = false)
        if (isIterable!Range)
    {
        import core.lifetime: move;
        alias G = typeof(return);
        auto kurtosisAccumulator = KurtosisAccumulator!(G, kurtosisAlgo, ResolveSummationType!(summation, Range, G))(r.move);
        return kurtosisAccumulator.kurtosis(isPopulation, isRaw);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!F kurtosis(scope const F[] ar...)
    {
        alias G = typeof(return);
        auto kurtosisAccumulator = KurtosisAccumulator!(G, kurtosisAlgo, ResolveSummationType!(summation, const(G)[], G))(ar);
        return kurtosisAccumulator.kurtosis(false, false);
    }
}

/// ditto
template kurtosis(
    KurtosisAlgo kurtosisAlgo = KurtosisAlgo.online, 
    Summation summation = Summation.appropriate)
{
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
        isPopulation = true if population kurtosis, false if sample kurtosis (default)
        isRaw = true if raw kurtosis, false if excess kurtosis (default)
    +/
    @fmamath stdevType!Range kurtosis(Range)(Range r, bool isPopulation = false, bool isRaw = false)
        if(isIterable!Range)
    {
        import core.lifetime: move;
        alias F = typeof(return);
        return .kurtosis!(F, kurtosisAlgo, summation)(r.move, isPopulation, isRaw);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!T kurtosis(T)(scope const T[] ar...)
    {
        alias F = typeof(return);
        return .kurtosis!(F, kurtosisAlgo, summation)(ar);
    }
}

/// ditto
template kurtosis(F, string kurtosisAlgo, string summation = "appropriate")
{
    mixin("alias kurtosis = .kurtosis!(F, KurtosisAlgo." ~ kurtosisAlgo ~ ", Summation." ~ summation ~ ");");
}

/// ditto
template kurtosis(string kurtosisAlgo, string summation = "appropriate")
{
    mixin("alias kurtosis = .kurtosis!(KurtosisAlgo." ~ kurtosisAlgo ~ ", Summation." ~ summation ~ ");");
}

/// Simple example
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    assert(kurtosis([1.0, 2, 3, 4]).approxEqual(-1.2));

    assert(kurtosis([1.0, 2, 4, 5]).approxEqual((34.0 / 4) / pow(10.0 / 4, 2.0) * (3.0 * 5.0) / (2.0 * 1.0) - 3.0 * (3.0 * 3.0) / (2.0 * 1.0)));
    assert(kurtosis([1.0, 2, 4, 5], true).approxEqual((34.0 / 4) / pow(10.0 / 4, 2.0) - 3.0));
    assert(kurtosis([1.0, 2, 4, 5], false, true).approxEqual((34.0 / 4) / pow(10.0 / 4, 2.0) * (3.0 * 5.0) / (2.0 * 1.0) - 3.0 * (3.0 * 3.0) / (2.0 * 1.0) + 3.0));
    assert(kurtosis([1.0, 2, 4, 5], true, true).approxEqual((34.0 / 4) / pow(10.0 / 4, 2.0)));

    assert(kurtosis!float([0, 1, 2, 3, 4, 6].sliced(3, 2)).approxEqual(-0.2999999));

    static assert(is(typeof(kurtosis!float([1, 2, 3])) == float));
}

/// Kurtosis of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.kurtosis.approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
}

/// Kurtosis of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.fuse: fuse;

    auto x = [
        [0.0, 1.0, 1.5, 2.0, 3.5, 4.25],
        [2.0, 7.5, 5.0, 1.0, 1.5, 0.0]
    ].fuse;

    assert(x.kurtosis.approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
}

/// Column kurtosis of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;

    auto x = [
        [0.0,  1.0,  1.5, 2.0], 
        [3.5, 4.25,  2.0, 7.5],
        [5.0,  1.0,  1.5, 0.0],
        [1.5,  4.5, 4.75, 0.5]
    ].fuse;
    auto result = [-2.067182, -5.918089, 3.504056, 2.690240];

    // Use byDim or alongDim with map to compute kurtosis of row/column.
    assert(x.byDim!1.map!kurtosis.all!approxEqual(result));
    assert(x.alongDim!0.map!kurtosis.all!approxEqual(result));

    // FIXME
    // Without using map, computes the kurtosis of the whole slice
    // assert(x.byDim!1.kurtosis == x.sliced.kurtosis);
    // assert(x.alongDim!0.kurtosis == x.sliced.kurtosis);
}

/// Can also set algorithm type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto x = a + 100_000_000_000;

    // The default online algorithm is numerically unstable in this case
    auto y = x.kurtosis;
    assert(!y.approxEqual((792.78411865 / 12) / pow(54.76562500 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));

    // The naive algorithm has an assert error in this case because standard
    // deviation is calculated naively as zero. The kurtosis formula would then
    // be dividing by zero. 
    //auto z0 = x.kurtosis!(real, "naive");

    // The two-pass algorithm is also numerically unstable in this case
    auto z1 = x.kurtosis!"twoPass";
    assert(!z1.approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)) + 3.0);
    assert(!z1.approxEqual(y));

    // However, the three-pass algorithm is numerically stable in this case
    auto z2 = x.kurtosis!"threePass";
    assert(z2.approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)) + 3.0);
    assert(!z2.approxEqual(y));

    // And the assumeZeroMean algorithm provides the incorrect answer, as expected
    auto z3 = x.kurtosis!"assumeZeroMean";
    assert(!z3.approxEqual(y));
}

// Alt version with x a hundred of above's value
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto x = a + 1_000_000_000;

    // The default online algorithm is numerically stable in this case
    auto y = x.kurtosis;
    assert(y.approxEqual((792.78411865 / 12) / pow(54.76562500 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));

    // The naive algorithm has an assert error in this case because standard
    // deviation is calculated naively as zero. The kurtosis formula would then
    // be dividing by zero. 
    //auto z0 = x.kurtosis!(real, "naive");

    // The two-pass algorithm is  numerically stable in this case
    auto z1 = x.kurtosis!"twoPass";
    assert(z1.approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)) + 3.0);
    assert(z1.approxEqual(y));

    // However, the three-pass algorithm is numerically stable in this case
    auto z2 = x.kurtosis!"threePass";
    assert(z2.approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)) + 3.0);
    assert(z2.approxEqual(y));

    // And the assumeZeroMean algorithm provides the incorrect answer, as expected
    auto z3 = x.kurtosis!"assumeZeroMean";
    assert(!z3.approxEqual(y));
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;

    // Set population/sample kurtosis, excess/raw kurtosis, kurtosis algorithm,
    // sum algorithm or output type

    auto a = [1.0, 1e72, 1, -1e72].sliced;
    auto x = a * 10_000;

    bool PopulationTrueRT = true;
    bool PopulationFalseRT = false;
    enum PopulationTrueCT = true;

    enum RawTrueCT = true;
    bool RawTrueRT = true;
    bool RawFalseRT = false;

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean 
    from the second and fourth numbers has no effect. Further, after centering 
    and taking `x` to the fourth power, the first and third numbers in the slice
    have precision too low to be included in the centered sum of cubes. 
    +/
    assert(x.kurtosis.approxEqual(1.5));
    assert(x.kurtosis(PopulationFalseRT).approxEqual(1.5));
    assert(x.kurtosis(PopulationTrueRT).approxEqual(-1.0));
    assert(x.kurtosis(PopulationTrueCT).approxEqual(-1.0));
    assert(x.kurtosis(PopulationTrueRT, RawTrueRT).approxEqual(2.0));
    assert(x.kurtosis(PopulationFalseRT, RawTrueRT).approxEqual(4.5));
    assert(x.kurtosis(PopulationTrueCT, RawTrueCT).approxEqual(2.0));
    
    assert(x.kurtosis!("online").approxEqual(1.5));
    assert(x.kurtosis!("online", "kbn").approxEqual(1.5));
    assert(x.kurtosis!("online", "kb2").approxEqual(1.5));
    assert(x.kurtosis!("online", "precise").approxEqual(1.5));
    assert(x.kurtosis!(double, "online", "precise").approxEqual(1.5));
    assert(x.kurtosis!(double, "online", "precise")(PopulationTrueRT).approxEqual(-1.0));
    assert(x.kurtosis!(double, "online", "precise")(PopulationTrueRT, RawTrueRT).approxEqual(2.0));

    auto y = [uint.max - 3, uint.max - 2, uint.max - 1, uint.max].sliced;
    auto z = y.kurtosis!(ulong, "threePass");
    assert(z.approxEqual(-1.2));
    static assert(is(typeof(z) == double));
}

/++
For integral slices, can pass output type as template parameter to ensure output
type is correct.
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0, 1, 1, 2, 4, 4,
              2, 7, 5, 1, 2, 0].sliced;

    auto y = x.kurtosis;
    assert(y.approxEqual(0.223394));
    static assert(is(typeof(y) == double));

    assert(x.kurtosis!float.approxEqual(0.223394));
}

/++
Kurtosis works for other user-defined types (provided they can be converted to a
floating point)
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    
    static struct Foo {
        float x;
        alias x this;
    }
    
    Foo[] foo = [Foo(1f), Foo(2f), Foo(3f), Foo(4f)];
    assert(foo.kurtosis.approxEqual(-1.2f));
}

/// Compute kurtosis along specified dimention of tensors
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: as, iota, alongDim, map, repeat;

    auto x = [
        [0.0,  1,  3,  5],
        [3.0,  4,  5,  7],
        [6.0,  7, 10, 11],
        [9.0, 12, 15, 12]
    ].fuse;

    assert(x.kurtosis.approxEqual(-0.770040));

    auto m0 = [-1.200000, -0.152893, -1.713859, -3.869005];
    assert(x.alongDim!0.map!kurtosis.all!approxEqual(m0));
    assert(x.alongDim!(-2).map!kurtosis.all!approxEqual(m0));

    auto m1 = [-1.699512, 0.342857, -4.339100, 1.500000];
    assert(x.alongDim!1.map!kurtosis.all!approxEqual(m1));
    assert(x.alongDim!(-1).map!kurtosis.all!approxEqual(m1));

    assert(iota(4, 5, 6, 7).as!double.alongDim!0.map!kurtosis.all!approxEqual(repeat(-1.2, 5, 6, 7)));
}

/// Arbitrary kurtosis
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;

    assert(kurtosis(1.0, 2, 3, 4).approxEqual(-1.2));
    assert(kurtosis!float(1, 2, 3, 4).approxEqual(-1.2f));
}

// Check kurtosis vector UFCS
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    assert([1.0, 2, 3, 4].kurtosis.approxEqual(-1.2));
}

// Double-check correct output types
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: iota, alongDim, map;

    auto x = iota([4, 4], 1);
    auto y = x.alongDim!1.map!kurtosis;
    assert(y.all!approxEqual([-1.2, -1.2, -1.2, -1.2]));
    static assert(is(stdevType!(typeof(y)) == double));
}

// @nogc kurtosis test
version(mir_stat_test)
@safe pure @nogc nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.kurtosis.approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
    assert(x.sliced.kurtosis!float.approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
}

// Test all using values
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.stat: center;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.kurtosis.approxEqual(1.006470));
    assert(x.kurtosis(false, true).approxEqual(4.006470));
    assert(x.kurtosis(true).approxEqual(0.171904));
    assert(x.kurtosis(true, true).approxEqual(3.171904));

    assert(x.kurtosis!"naive".approxEqual(1.006470));
    assert(x.kurtosis!"naive"(false, true).approxEqual(4.006470));
    assert(x.kurtosis!"naive"(true).approxEqual(0.171904));
    assert(x.kurtosis!"naive"(true, true).approxEqual(3.171904));

    assert(x.kurtosis!"twoPass".approxEqual(1.006470));
    assert(x.kurtosis!"twoPass"(false, true).approxEqual(4.006470));
    assert(x.kurtosis!"twoPass"(true).approxEqual(0.171904));
    assert(x.kurtosis!"twoPass"(true, true).approxEqual(3.171904));

    assert(x.kurtosis!"threePass".approxEqual(1.006470));
    assert(x.kurtosis!"threePass"(false, true).approxEqual(4.006470));
    assert(x.kurtosis!"threePass"(true).approxEqual(0.171904));
    assert(x.kurtosis!"threePass"(true, true).approxEqual(3.171904));

    auto y = x.center;
    assert(y.kurtosis!"assumeZeroMean".approxEqual(1.006470));
    assert(y.kurtosis!"assumeZeroMean"(false, true).approxEqual(4.006470));
    assert(y.kurtosis!"assumeZeroMean"(true).approxEqual(0.171904));
    assert(y.kurtosis!"assumeZeroMean"(true, true).approxEqual(3.171904));
}
