/++
This module contains algorithms for transforming data that are useful in
statistical applications.

License: $(LINK2 http://boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: John Michael Hall, Ilya Yaroshenko

Copyright: 2020 Mir Stat Authors.

Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, stat, $1)$(NBSP)
MATHREF = $(REF_ALTTEXT $(TT $2), $2, mir, math, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
T4=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4))
+/

module mir.stat.transform;

public import mir.math.stat: center;

import mir.math.common: fmamath;
import mir.math.stat: mean, standardDeviation, VarianceAlgo;
import mir.math.sum: Summation;
import mir.ndslice.slice: Slice, SliceKind, hasAsSlice;

/++
For each `e` of the input, applies `e op m` where `m` is the result of `fun` and
`op` is an operation, such as `"+"`, `"-"`, `"*"`, or `"/"`. For instance, if
`op = "-"`, then this function computes `e - m` for each `e` of the input and
where `m` is the result of applying `fun` to the input.
Overloads are provided to directly provide `m` to the function, rather than
calculate it using `fun`.
Params:
    fun = function used to sweep
    op = operation
Returns:
    The input 
See_also:
    $(MATHREF stat, center),
    $(LREF, scale)
+/
template sweep(alias fun, string op)
{
    import mir.ndslice.internal: LeftOp, ImplicitlyUnqual;
    import mir.ndslice.slice: Slice, SliceKind, sliced, hasAsSlice;
    import mir.ndslice.topology: vmap;
    /++
    Params:
        slice = slice
    +/
    @fmamath auto sweep(Iterator, size_t N, SliceKind kind)(
        Slice!(Iterator, N, kind) slice)
    {
        import core.lifetime: move;

        auto m = fun(slice.lightScope);
        return .sweep!op(slice.move, m);
    }
    
    /// ditto
    @fmamath auto sweep(T)(T[] array)
    {
        return sweep(array.sliced);
    }

    /// ditto
    @fmamath auto sweep(T)(T withAsSlice)
        if (hasAsSlice!T)
    {
        return sweep(withAsSlice.asSlice);
    }
}

/++
Params:
    op = operation
+/
template sweep(string op)
{
    /++
    Params:
        slice = slice
        m = value to pass to vmap
    +/
    @fmamath auto sweep(Iterator, size_t N, SliceKind kind, T)(
               Slice!(Iterator, N, kind) slice, T m)
    {
        import core.lifetime: move;
        import mir.ndslice.internal: LeftOp, ImplicitlyUnqual;
        import mir.ndslice.topology: vmap;

        return slice.move.vmap(LeftOp!(op, ImplicitlyUnqual!T)(m));
    }
        
    /// ditto
    @fmamath auto sweep(T)(T[] array, T m)
    {
        import mir.ndslice.slice: sliced;

        return sweep(array.sliced, m);
    }

    /// ditto
    @fmamath auto sweep(T, U)(T withAsSlice, U m)
        if (hasAsSlice!T)
    {
        return sweep(withAsSlice.asSlice, m);
    }
}

/// Sweep vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static double f(T)(T x) {
        return 3.5;
    }

    auto x = [1.0, 2, 3, 4, 5, 6].sliced;
    assert(x.sweep!(f, "-").all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
    assert(x.sweep!"-"(3.5).all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
    assert(x.sweep!(f, "+").all!approxEqual([4.5, 5.5, 6.5, 7.5, 8.5, 9.5]));
}

/// Sweep dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;

    static double f(T)(T x) {
        return 3.5;
    }

    auto x = [1.0, 2, 3, 4, 5, 6];
    assert(x.sweep!(f, "-").all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
    assert(x.sweep!"-"(3.5).all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
    assert(x.sweep!(f, "+").all!approxEqual([4.5, 5.5, 6.5, 7.5, 8.5, 9.5]));
}

/// Sweep matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice: fuse;

    static double f(T)(T x) {
        return 3.5;
    }

    auto x = [
        [1.0, 2, 3],
        [4.0, 5, 6]
    ].fuse;

    auto y0 = [
        [-2.5, -1.5, -0.5],
        [ 0.5,  1.5,  2.5]
    ];

    auto y1 = [
        [4.5, 5.5, 6.5],
        [7.5, 8.5, 9.5]
    ];

    assert(x.sweep!(f, "-").all!approxEqual(y0));
    assert(x.sweep!"-"(3.5).all!approxEqual(y0));
    assert(x.sweep!(f, "+").all!approxEqual(y1));
}

/// Column sweep matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all, equal;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;

    static double f(T)(T x) {
        return 0.5 * (x[0] +x[1]);
    }

    auto x = [
        [20.0, 100.0, 2000.0],
        [10.0,   5.0,    2.0]
    ].fuse;

    auto result = [
        [ 5.0,  47.5,  999],
        [-5.0, -47.5, -999]
    ].fuse;

    // Use byDim with map to sweep mean of row/column.
    auto xSweepByDim = x.byDim!1.map!(sweep!(f, "-"));
    auto resultByDim = result.byDim!1;
    assert(xSweepByDim.equal!(equal!approxEqual)(resultByDim));

    auto xSweepAlongDim = x.alongDim!0.map!(sweep!(f, "-"));
    auto resultAlongDim = result.alongDim!0;
    assert(xSweepAlongDim.equal!(equal!approxEqual)(resultAlongDim));
}

/// Can also pass arguments to sweep function
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static double f(T)(T x, double a) {
        return a;
    }

    static double g(double a, T)(T x) {
        return a;
    }

    auto x = [1.0, 2, 3, 4, 5, 6].sliced;
    assert(x.sweep!(a => f(a, 3.5), "-").all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
    assert(x.sweep!(a => f(a, 3.5), "+").all!approxEqual([4.5, 5.5, 6.5, 7.5, 8.5, 9.5]));
    assert(x.sweep!(a => g!3.5(a), "-").all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
    assert(x.sweep!(a => g!3.5(a), "+").all!approxEqual([4.5, 5.5, 6.5, 7.5, 8.5, 9.5]));
}

/++
Scales the input.
By default, the input is first centered using the mean of the input. A custom
function may also be provided using `centralTendency`. The centered input is
then divided by the sample standard deviation of the input. A custom function
may also be provided using `dispersion`.
Overloads are also provided to scale with variables `m` and `d`, which
correspond to the results of `centralTendency` and `dispersion`. This function
is equivalent to `center` when passing `d = 1`.
Params:
    centralTendency = function used to center input, default is `mean`
    dispersion = function used to , default is `dispersion`
Returns:
    The scaled result
See_also:
    $(MATHREF stat, center),
    $(MATHREF stat, VarianceAlgo)
    $(MATHREF sum, Summation)
    $(MATHREF stat, mean),
    $(MATHREF stat, standardDeviation),
    $(MATHREF stat, median),
    $(MATHREF stat, gmean),
    $(MATHREF stat, hmean),
    $(MATHREF stat, variance),
    $(SUBREF descriptive, dispersion)
+/
template scale(alias centralTendency = mean!(Summation.appropriate),
               alias dispersion = standardDeviation!(VarianceAlgo.online, Summation.appropriate))
{
    import mir.ndslice.slice: Slice, SliceKind, sliced, hasAsSlice;

    /++
    Params:
        slice = slice
    +/
    @fmamath auto scale(Iterator, size_t N, SliceKind kind)(
        Slice!(Iterator, N, kind) slice)
    {
        import core.lifetime: move;

        auto m = centralTendency(slice.lightScope);
        auto d = dispersion(slice.lightScope);
        return .scale!(Iterator, N, kind, typeof(m))(slice.move, m, d);
    }
    
    /// ditto
    @fmamath auto scale(T)(T[] array)
    {
        return scale(array.sliced);
    }

    /// ditto
    @fmamath auto scale(T)(T withAsSlice)
        if (hasAsSlice!T)
    {
        return scale(withAsSlice.asSlice);
    }
}

/++
Params:
    slice = slice
    m = value to subtract from slice
    d = value to divide slice by
+/
@fmamath auto scale(Iterator, size_t N, SliceKind kind, T, U)(
           Slice!(Iterator, N, kind) slice, T m, U d)
{
    import core.lifetime: move;
    import mir.ndslice.internal: LeftOp, ImplicitlyUnqual;
    import mir.ndslice.topology: vmap;

    return slice.move.sweep!"-"(m).sweep!"/"(d);
}
    
/// ditto
@fmamath auto scale(T, U)(T[] array, T m, U d)
{
    import mir.ndslice.slice: sliced;

    return scale(array.sliced, m, d);
}

/// ditto
@fmamath auto scale(T, U, V)(T withAsSlice, U m, V d)
    if (hasAsSlice!T)
{
    return scale(withAsSlice.asSlice, m, d);
}

/// Scale vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.math.stat: gmean, hmean, median;
    import mir.ndslice.slice: sliced;

    auto x = [1.0, 2, 3, 4, 5, 6].sliced;

    assert(x.scale.all!approxEqual([-1.336306, -0.801784, -0.267261, 0.267261, 0.801784, 1.336306]));
    assert(x.scale(3.5, 1.87083).all!approxEqual([-1.336306, -0.801784, -0.267261, 0.267261, 0.801784, 1.336306]));
    
    // Can scale using different `centralTendency` functions
    assert(x.scale!hmean.all!approxEqual([-0.774512, -0.23999, 0.294533, 0.829055, 1.363578, 1.898100]));
    assert(x.scale!gmean.all!approxEqual([-1.065728, -0.531206, 0.003317, 0.537839, 1.072362, 1.606884]));
    assert(x.scale!median.all!approxEqual([-1.336306, -0.801784, -0.267261, 0.267261, 0.801784, 1.336306]));
    
    // Can scale using different `centralTendency` and `dispersion` functions
    assert(x.scale!(mean, a => a.standardDeviation(true)).all!approxEqual([-1.46385, -0.87831, -0.29277, 0.29277, 0.87831, 1.46385]));
    assert(x.scale!(hmean, a => a.standardDeviation(true)).all!approxEqual([-0.848436, -0.262896, 0.322645, 0.908185, 1.493725, 2.079265]));
    assert(x.scale!(gmean, a => a.standardDeviation(true)).all!approxEqual([-1.167447, -0.581907, 0.003633, 0.589173, 1.174713, 1.760253]));
    assert(x.scale!(median, a => a.standardDeviation(true)).all!approxEqual([-1.46385, -0.87831, -0.29277, 0.29277, 0.87831, 1.46385]));
}

/// Scale dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;

    auto x = [1.0, 2, 3, 4, 5, 6];
    assert(x.scale.all!approxEqual([-1.336306, -0.801784, -0.267261, 0.267261, 0.801784, 1.336306]));
    assert(x.scale(3.5, 1.87083).all!approxEqual([-1.336306, -0.801784, -0.267261, 0.267261, 0.801784, 1.336306]));
}

/// Scale matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice: fuse;
    
    auto x = [
        [1.0, 2, 3], 
        [4.0, 5, 6]
    ].fuse;
    
    assert(x.scale.all!approxEqual([[-1.336306, -0.801784, -0.267261], [0.267261, 0.801784, 1.336306]]));
    assert(x.scale(3.5, 1.87083).all!approxEqual([[-1.336306, -0.801784, -0.267261], [0.267261, 0.801784, 1.336306]]));
}

/// Column scale matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all, equal;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;

    auto x = [
        [20.0, 100.0, 2000.0],
        [10.0,   5.0,    2.0]
    ].fuse;

    auto result = [
        [ 0.707107,  0.707107,  0.707107],
        [-0.707107, -0.707107, -0.707107]
    ].fuse;

    // Use byDim with map to scale by row/column.
    auto xScaleByDim = x.byDim!1.map!scale;
    auto resultByDim = result.byDim!1;
    assert(xScaleByDim.equal!(equal!approxEqual)(resultByDim));

    auto xCenterAlongDim = x.alongDim!0.map!scale;
    auto resultAlongDim = result.alongDim!0;
    assert(xScaleByDim.equal!(equal!approxEqual)(resultAlongDim));
}

/// Can also pass arguments to `mean` and `standardDeviation` functions used by scale
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    //Set sum algorithm
    auto a = [1, 1e100, 1, -1e100];

    auto x = a.sliced * 10_000;

    auto result = [6.123724e-101, 1.224745, 6.123724e-101, -1.224745].sliced;

    assert(x.scale!(mean!"kbn", standardDeviation!("online", "kbn")).all!approxEqual(result));
    assert(x.scale!(mean!"kb2", standardDeviation!("online", "kb2")).all!approxEqual(result));
    assert(x.scale!(mean!"precise", standardDeviation!("online", "precise")).all!approxEqual(result));
}

/++
Computes the Z-score of the input.
The Z-score is computed by first calculating the mean and standard deviation of
the input, by default in one pass, and then scaling the input using those values.
Returns:
    The z-score of the input
See_also:
    $(LREF scale),
    $(MATHREF stat, mean),
    $(MATHREF stat, standardDeviation),
    $(MATHREF stat, variance)
+/
template zscore(F, 
                VarianceAlgo varianceAlgo = VarianceAlgo.online,
                Summation summation = Summation.appropriate)
{
    /++
    Params:
        slice = slice
        isPopulation = true if population standard deviation, false is sample (default)
    +/
    @fmamath auto zscore(Iterator, size_t N, SliceKind kind)(
        Slice!(Iterator, N, kind) slice, 
        bool isPopulation = false)
    {
        import core.lifetime: move;
        import mir.math.common: sqrt;
        import mir.math.stat: meanType, VarianceAccumulator;
        import mir.math.sum: ResolveSummationType;

        alias G = meanType!F;
        alias T = typeof(slice);
        auto varianceAccumulator = VarianceAccumulator!(
            G, varianceAlgo, ResolveSummationType!(summation, T, G))(
            slice.lightScope);
        return scale(slice,
                     varianceAccumulator.mean,
                     varianceAccumulator.variance(isPopulation).sqrt);
    }
    
    /// ditto
    @fmamath auto zscore(T)(T[] array, bool isPopulation = false)
    {
        import mir.ndslice.slice: sliced;

        return zscore(array.sliced, isPopulation);
    }

    /// ditto
    @fmamath auto zscore(T)(T withAsSlice, bool isPopulation = false)
        if (hasAsSlice!T)
    {
        return zscore(withAsSlice.asSlice, isPopulation);
    }
}

///
template zscore(VarianceAlgo varianceAlgo = VarianceAlgo.online,
                Summation summation = Summation.appropriate)
{
    import mir.math.stat: meanType;

    /// ditto
    @fmamath auto zscore(Iterator, size_t N, SliceKind kind)(
        Slice!(Iterator, N, kind) slice, 
        bool isPopulation = false)
    {
        import core.lifetime: move;
        alias F = meanType!(Slice!(Iterator, N, kind));
        return .zscore!(F, varianceAlgo, summation)(slice.move, isPopulation);
    }

    /// ditto
    @fmamath auto zscore(T)(T[] array, bool isPopulation = false)
    {
        alias F = meanType!(T[]);
        return .zscore!(F, varianceAlgo, summation)(array, isPopulation);
    }

    /// ditto
    @fmamath auto zscore(T)(T withAsSlice, bool isPopulation = false)
        if (hasAsSlice!T)
    {
        alias F = meanType!(T);
        return .zscore!(F, varianceAlgo, summation)(withAsSlice, isPopulation);
    }
}

/// ditto
template zscore(F, string varianceAlgo, string summation = "appropriate")
{
    mixin("alias zscore = .zscore!(F, VarianceAlgo." ~ varianceAlgo ~ ", Summation." ~ summation ~ ");");
}

/// ditto
template zscore(string varianceAlgo, string summation = "appropriate")
{
    mixin("alias zscore = .zscore!(VarianceAlgo." ~ varianceAlgo ~ ", Summation." ~ summation ~ ");");
}

/// zscore vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [1.0, 2, 3, 4, 5, 6].sliced;

    assert(x.zscore.all!approxEqual([-1.336306, -0.801784, -0.267261, 0.267261, 0.801784, 1.336306]));
    assert(x.zscore(true).all!approxEqual([-1.46385, -0.87831, -0.29277, 0.29277, 0.87831, 1.46385]));
}

/// zscore dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;

    auto x = [1.0, 2, 3, 4, 5, 6];
    assert(x.zscore.all!approxEqual([-1.336306, -0.801784, -0.267261, 0.267261, 0.801784, 1.336306]));
    assert(x.zscore(true).all!approxEqual([-1.46385, -0.87831, -0.29277, 0.29277, 0.87831, 1.46385]));
}

/// zscore matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    
    auto x = [
        [1.0, 2, 3], 
        [4.0, 5, 6]
    ].fuse;
    
    assert(x.zscore.all!approxEqual([[-1.336306, -0.801784, -0.267261], [0.267261, 0.801784, 1.336306]]));
    assert(x.zscore(true).all!approxEqual([[-1.46385, -0.87831, -0.29277], [0.29277, 0.87831, 1.46385]]));
}

/// Column zscore matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all, equal;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;

    auto x = [
        [20.0, 100.0, 2000.0],
        [10.0,   5.0,    2.0]
    ].fuse;

    auto result = [
        [ 0.707107,  0.707107,  0.707107],
        [-0.707107, -0.707107, -0.707107]
    ].fuse;

    // Use byDim with map to scale by row/column.
    auto xScaleByDim = x.byDim!1.map!zscore;
    auto resultByDim = result.byDim!1;
    assert(xScaleByDim.equal!(equal!approxEqual)(resultByDim));

    auto xCenterAlongDim = x.alongDim!0.map!zscore;
    auto resultAlongDim = result.alongDim!0;
    assert(xScaleByDim.equal!(equal!approxEqual)(resultAlongDim));
}

/// Can control how `mean` and `standardDeviation` are calculated and output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;

    //Set sum algorithm or output type
    auto a = [1, 1e100, 1, -1e100];

    auto x = a.sliced * 10_000;

    auto result = [6.123724e-101, 1.224745, 6.123724e-101, -1.224745].sliced;

    assert(x.zscore!("online", "kbn").all!approxEqual(result));
    assert(x.zscore!("online", "kb2").all!approxEqual(result));
    assert(x.zscore!("online", "precise").all!approxEqual(result));
    assert(x.zscore!(double, "online", "precise").all!approxEqual(result));

    auto y = [uint.max, uint.max / 2, uint.max / 3].sliced;
    assert(y.zscore!ulong.all!approxEqual([1.120897, -0.320256, -0.800641]));
}
