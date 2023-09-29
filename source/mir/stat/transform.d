/++
This module contains algorithms for transforming data that are useful in
statistical applications.

$(SCRIPT inhibitQuickIndex = 1;)
$(DIVC quickindex,
$(BOOKTABLE ,
$(TR $(TH Function Name) $(TH Description)
)
    $(TR $(TD $(LREF center))
        $(TD Subtracts the mean (or using some other function) from each element
        of a slice.
    ))
    $(TR $(TD $(LREF robustScale))
        $(TD Subtracts the median and divides by the difference between a lower
        and upper quantile from each element of a slice.
    ))
    $(TR $(TD $(LREF scale))
        $(TD Subtracts the mean (or using some other function) and divides by
        the standard deviation (or using some other function) from each element
        of a slice.
    ))
    $(TR $(TD $(LREF sweep))
        $(TD Applies a function and an operation to each element of a slice.
    ))
    $(TR $(TD $(LREF zscore))
        $(TD Subtracts the mean and divides by the standard deviation from each
        element of a slice.
    ))
))

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall, Ilya Yaroshenko

Copyright: 2022-3 Mir Stat Authors.

Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, stat, $1)$(NBSP)
SUB2REF = $(REF_ALTTEXT $(TT $2), $2, mir, stat, descriptive, $1)$(NBSP)
MATHREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, math, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
T4=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4))

+/

module mir.stat.transform;

import mir.math.common: fmamath;
import mir.math.sum: Summation;
import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind, hasAsSlice;
import mir.stat.descriptive.univariate: mean, QuantileAlgo, standardDeviation, VarianceAlgo;

/++
Centers `slice`, which must be a finite iterable.

By default, `slice` is centered by the mean. A custom function may also be
provided using `centralTendency`.

Returns:
    The elements in the slice with the average subtracted from them.
+/
template center(alias centralTendency = mean!(Summation.appropriate))
{
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    /++
    Params:
        slice = slice
    +/
    auto center(Iterator, size_t N, SliceKind kind)(
        Slice!(Iterator, N, kind) slice)
    {
        import core.lifetime: move;
        import mir.ndslice.internal: LeftOp, ImplicitlyUnqual;
        import mir.ndslice.topology: vmap;

        auto m = centralTendency(slice.lightScope);
        alias T = typeof(m);
        return slice.move.vmap(LeftOp!("-", ImplicitlyUnqual!T)(m));
    }
    
    /// ditto
    auto center(T)(T x)
        if (isConvertibleToSlice!T && !isSlice!T)
    {
        import mir.ndslice.slice: toSlice;
        return center(x.toSlice);
    }
}

/// Center vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.descriptive.univariate: gmean, hmean, median;

    auto x = [1.0, 2, 3, 4, 5, 6].sliced;
    assert(x.center.all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
    
    // Can center using different functions
    assert(x.center!hmean.all!approxEqual([-1.44898, -0.44898, 0.55102, 1.55102, 2.55102, 3.55102]));
    assert(x.center!gmean.all!approxEqual([-1.99379516, -0.99379516, 0.00620483, 1.00620483, 2.00620483, 3.00620483]));
    assert(x.center!median.all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));

    // center operates lazily, if original slice is changed, then 
    auto y = x.center;
    assert(y.all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
    x[0]++;
    assert(y.all!approxEqual([-1.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
}

/// Example of lazy behavior of center
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.allocation: slice;
    import mir.ndslice.slice: sliced;

    auto x = [1.0, 2, 3, 4, 5, 6].sliced;
    auto y = x.center;
    auto z = x.center.slice;
    assert(y.all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
    x[0]++;
    // y changes, while z does not
    assert(y.all!approxEqual([-1.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
    assert(z.all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));   
}

/// Center dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;

    auto x = [1.0, 2, 3, 4, 5, 6];
    assert(x.center.all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
}

/// Center matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice: fuse;
    
    auto x = [
        [0.0, 1, 2], 
        [3.0, 4, 5]
    ].fuse;
    
    auto y = [
        [-2.5, -1.5, -0.5], 
        [ 0.5,  1.5,  2.5]
    ].fuse;
    
    assert(x.center.all!approxEqual(y));
}

/// Column center matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all, equal;
    import mir.math.common: approxEqual;
    import mir.ndslice: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;

    auto x = [
        [20.0, 100.0, 2000.0],
        [10.0,   5.0,    2.0]
    ].fuse;

    auto result = [
        [ 5.0,  47.5,  999],
        [-5.0, -47.5, -999]
    ].fuse;

    // Use byDim with map to compute average of row/column.
    auto xCenterByDim = x.byDim!1.map!center;
    auto resultByDim = result.byDim!1;
    assert(xCenterByDim.equal!(equal!approxEqual)(resultByDim));

    auto xCenterAlongDim = x.alongDim!0.map!center;
    auto resultAlongDim = result.alongDim!0;
    assert(xCenterByDim.equal!(equal!approxEqual)(resultAlongDim));
}

/// Can also pass arguments to average function used by center
version(mir_stat_test)
pure @safe nothrow
unittest
{
    import mir.ndslice.slice: sliced;

    //Set sum algorithm or output type
    auto a = [1, 1e100, 1, -1e100];

    auto x = a.sliced * 10_000;

    //Due to Floating Point precision, subtracting the mean from the second
    //and fourth numbers in `x` does not change the value of the result
    auto result = [5000, 1e104, 5000, -1e104].sliced;

    assert(x.center!(mean!"kbn") == result);
    assert(x.center!(mean!"kb2") == result);
    assert(x.center!(mean!"precise") == result);
}

/++
Passing a centered input to `variance` or `standardDeviation` with the
`assumeZeroMean` algorithm is equivalent to calculating `variance` or
`standardDeviation` on the original input.
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.descriptive.univariate: variance;

    auto x = [1.0, 2, 3, 4, 5, 6].sliced;
    assert(x.center.variance!"assumeZeroMean".approxEqual(x.variance));
    assert(x.center.standardDeviation!"assumeZeroMean".approxEqual(x.standardDeviation));
}

// dynamic array test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;

    double[] x = [1.0, 2, 3, 4, 5, 6];

    assert(x.center.all!approxEqual([-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]));
}

// withAsSlice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    static immutable a = [1.0, 2, 3, 4, 5, 6];
    static immutable result = [-2.5, -1.5, -0.5, 0.5, 1.5, 2.5];

    auto x = RCArray!double(6);
    foreach(i, ref e; x)
        e = a[i];

    assert(x.center.all!approxEqual(result));
}

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
    $(LREF center),
    $(LREF scale)
+/
template sweep(alias fun, string op)
{
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
    @fmamath auto sweep(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        return sweep(x.toSlice);
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
    @fmamath auto sweep(SliceLike, T)(SliceLike x, T m)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        return sweep(x.toSlice, m);
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
    import mir.ndslice.fuse: fuse;

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

/// Sweep withAsSlice
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    static double f(T)(T x) {
        return 3.5;
    }

    auto x = RCArray!double(6);
    foreach(i, ref e; x)
        e = i + 1;

    static immutable result1 = [-2.5, -1.5, -0.5, 0.5, 1.5, 2.5];
    assert(x.sweep!(f, "-").all!approxEqual(result1));
    assert(x.sweep!"-"(3.5).all!approxEqual(result1));
    static immutable result2 = [4.5, 5.5, 6.5, 7.5, 8.5, 9.5];
    assert(x.sweep!(f, "+").all!approxEqual(result2));
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
    dispersion = function used as divisor, default is `dispersion`
Returns:
    The scaled result
See_also:
    $(LREF center),
    $(SUB2REF univariate, VarianceAlgo),
    $(MATHREF sum, Summation),
    $(SUB2REF univariate, mean),
    $(SUB2REF univariate, standardDeviation),
    $(SUB2REF univariate, median),
    $(SUB2REF univariate, gmean),
    $(SUB2REF univariate, hmean),
    $(SUB2REF univariate, variance),
    $(SUB2REF univariate, dispersion)
+/
template scale(alias centralTendency = mean!(Summation.appropriate),
               alias dispersion = standardDeviation!(VarianceAlgo.hybrid, Summation.appropriate))
{
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
    @fmamath auto scale(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        return scale(x.toSlice);
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
    
    assert(d > 0, "scale: cannot divide by zero");

    return slice.move.sweep!"-"(m).sweep!"/"(d);
}
    
/// ditto
@fmamath auto scale(SliceLike, T, U)(SliceLike x, T m, U d)
    if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
{
    import mir.ndslice.slice: toSlice;
    return scale(x.toSlice, m, d);
}

/// Scale vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.descriptive.univariate: mean, gmean, hmean, median, standardDeviation;

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
    import mir.ndslice.fuse: fuse;
    
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

    auto xScaleAlongDim = x.alongDim!0.map!scale;
    auto resultAlongDim = result.alongDim!0;
    assert(xScaleAlongDim.equal!(equal!approxEqual)(resultAlongDim));
}

/// Can also pass arguments to `mean` and `standardDeviation` functions used by scale
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.descriptive.univariate: mean, standardDeviation;

    //Set sum algorithm
    auto a = [1, 1e100, 1, -1e100];

    auto x = a.sliced * 10_000;

    auto result = [6.123724e-101, 1.224745, 6.123724e-101, -1.224745].sliced;

    assert(x.scale!(mean!"kbn", standardDeviation!("online", "kbn")).all!approxEqual(result));
    assert(x.scale!(mean!"kb2", standardDeviation!("online", "kb2")).all!approxEqual(result));
    assert(x.scale!(mean!"precise", standardDeviation!("online", "precise")).all!approxEqual(result));
}

// Scale withAsSlice
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    auto x = RCArray!double(6);
    foreach(i, ref e; x)
        e = i + 1;

    static immutable result = [-1.336306, -0.801784, -0.267261, 0.267261, 0.801784, 1.336306];
    assert(x.scale.all!approxEqual(result));
    assert(x.scale(3.5, 1.87083).all!approxEqual(result));
}

/++
Computes the Z-score of the input.

The Z-score is computed by first calculating the mean and standard deviation of
the input, by default in one pass, and then scaling the input using those values.

Params:
    F = controls type of output
    varianceAlgo = algorithm for calculating variance (default: VarianceAlgo.hybrid)
    summation = algorithm for calculating sums (default: Summation.appropriate)
Returns:
    The z-score of the input
See_also:
    $(LREF scale),
    $(MATHREF stat, mean),
    $(MATHREF stat, standardDeviation),
    $(MATHREF stat, variance)
+/
template zscore(F, 
                VarianceAlgo varianceAlgo = VarianceAlgo.hybrid,
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
        import mir.math.sum: ResolveSummationType;
        import mir.stat.descriptive.univariate: meanType, VarianceAccumulator;

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
    @fmamath auto zscore(SliceLike)(SliceLike x, bool isPopulation = false)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        return zscore(x.toSlice, isPopulation);
    }
}

/// ditto
template zscore(VarianceAlgo varianceAlgo = VarianceAlgo.hybrid,
                Summation summation = Summation.appropriate)
{
    import mir.stat.descriptive.univariate: meanType;

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
    @fmamath auto zscore(SliceLike)(SliceLike x, bool isPopulation = false)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        alias F = meanType!(SliceLike);
        return .zscore!(F, varianceAlgo, summation)(x.toSlice, isPopulation);
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
    auto xZScoreByDim = x.byDim!1.map!zscore;
    auto resultByDim = result.byDim!1;
    assert(xZScoreByDim.equal!(equal!approxEqual)(resultByDim));

    auto xZScoreAlongDim = x.alongDim!0.map!zscore;
    auto resultAlongDim = result.alongDim!0;
    assert(xZScoreAlongDim.equal!(equal!approxEqual)(resultAlongDim));
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

// zscore withAsSlice
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    auto x = RCArray!double(6);
    foreach(i, ref e; x)
        e = i + 1;

    static immutable result1 = [-1.336306, -0.801784, -0.267261, 0.267261, 0.801784, 1.336306];
    assert(x.zscore.all!approxEqual(result1));
    static immutable result2 = [-1.46385, -0.87831, -0.29277, 0.29277, 0.87831, 1.46385];
    assert(x.zscore(true).all!approxEqual(result2));
}

/++
Scales input using robust statistics.

This function centers the input using the `median` and then `scale`s the data
according to the quantile range defined by (`low_quartile`, 1 - `low_quartile`).
By default, it uses the interquartile range, whereby `low_quartile` equals 0.25.

Params:
    F = controls type of output
    quantileAlgo = algorithm for calculating quantile (default: `QuantileAlgo.type7`)
    allowModifySlice = controls whether the input is modified in place, default is false
Returns:
    The robust scaled input
See_also:
    $(LREF scale),
    $(SUB2REF univariate, median),
    $(SUB2REF univariate, quantile),
    $(SUB2REF univariate, interquartileRange)
+/
template robustScale(F,
                     QuantileAlgo quantileAlgo = QuantileAlgo.type7, 
                     bool allowModifySlice = false)
{
    /++
    Params:
        slice = slice
        low_quartile = lower end of quartile range
    +/
    @fmamath auto robustScale(Iterator, size_t N, SliceKind kind, T)(
        Slice!(Iterator, N, kind) slice, 
        T low_quartile = 0.25)
    {
        assert(low_quartile > 0.0, "robustScale: low_quartile must be greater than zero");
        assert(low_quartile < 0.5, "robustScale: low_quartile must be less than 0.5");

        import mir.ndslice.topology: flattened;
        import mir.stat.descriptive.univariate: median, meanType, quantile, quantileType;

        static if (!allowModifySlice) {
            import mir.ndslice.allocation: rcslice;
            import mir.ndslice.topology: as;
            import std.traits: Unqual;

            auto view = slice.lightScope;
            auto val = view.as!(Unqual!(slice.DeepElement)).rcslice;
            auto temp = val.lightScope.flattened;
        } else {
            auto temp = slice.flattened;
        }

        quantileType!(F, quantileAlgo) low_quartile_value = temp.quantile!(F, quantileAlgo, allowModifySlice, false)(low_quartile);
        meanType!F median_value = temp.median!(F, allowModifySlice);
        quantileType!(F, quantileAlgo) high_quartile_value = temp.quantile!(F, quantileAlgo, allowModifySlice, false)(cast(F) 1 - low_quartile);

        static if (allowModifySlice) {
            return scale(temp, median_value, cast(meanType!F) (high_quartile_value - low_quartile_value));
        } else {
            return scale(slice, median_value, cast(meanType!F) (high_quartile_value - low_quartile_value));
        }
    }

    /// ditto
    @fmamath auto robustScale(SliceLike)(SliceLike x, F low_quartile = cast(F) 0.25)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        return robustScale(x.toSlice, low_quartile);
    }
}

/++
Params:
    quantileAlgo = algorithm for calculating quantile (default: `QuantileAlgo.type7`)
    allowModifySlice = controls whether the input is modified in place, default is false
+/
template robustScale(QuantileAlgo quantileAlgo = QuantileAlgo.type7, 
                     bool allowModifySlice = false)
{
    import mir.stat.descriptive.univariate: meanType;

    /++
    Params:
        slice = slice
        low_quartile = lower end of quartile range
    +/
    @fmamath auto robustScale(Iterator, size_t N, SliceKind kind)(
        Slice!(Iterator, N, kind) slice, 
        double low_quartile = 0.25)
    {
        import core.lifetime: move;
        alias F = meanType!(Slice!(Iterator, N, kind));
        return .robustScale!(F, quantileAlgo, allowModifySlice)(slice.move, cast(F) low_quartile);
    }

    /// ditto
    @fmamath auto robustScale(SliceLike)(SliceLike x, double low_quartile = 0.25)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        alias F = meanType!(SliceLike);
        return .robustScale!(F, quantileAlgo, allowModifySlice)(x.toSlice, cast(F) low_quartile);
    }
}

/// ditto
template robustScale(F, string quantileAlgo, bool allowModifySlice = false)
{
    mixin("alias robustScale = .robustScale!(F, QuantileAlgo." ~ quantileAlgo ~ ", allowModifySlice);");
}

/// ditto
template robustScale(string quantileAlgo, bool allowModifySlice = false)
{
    mixin("alias robustScale = .robustScale!(QuantileAlgo." ~ quantileAlgo ~ ", allowModifySlice);");
}

/// ditto
template robustScale(bool allowModifySlice)
{
    mixin("alias robustScale = .robustScale!(QuantileAlgo.type7, allowModifySlice);");
}

/// robustScale vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all, findIndex;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    
    static immutable input = [100.0, 16, 12, 13, 15, 12, 16, 9, 3, -100];
    auto x = input.dup.sliced;
    auto y = x.robustScale;

    assert(y.all!approxEqual([14.583333, 0.583333, -0.083333, 0.083333, 0.416667, -0.083333, 0.583333, -0.583333, -1.583333, -18.750000]));
    assert(x.robustScale(0.15).all!approxEqual([8.02752, 0.321101, -0.0458716, 0.0458716, 0.229358, -0.0458716, 0.321101, -0.321101, -0.87156, -10.3211]));

    // When allowModifySlice = true, this modifies both the original input and
    // the order of the output
    auto yCopy = y.idup;
    auto z = x.robustScale!true;
    size_t j;
    foreach(i, ref e; input) {
        j = x.findIndex!(a => a == e);
        assert(z[j].approxEqual(yCopy[i]));
    }
}

/// robustScale dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;

    auto x = [100.0, 16, 12, 13, 15, 12, 16, 9, 3, -100];
    assert(x.robustScale.all!approxEqual([14.583333, 0.583333, -0.083333, 0.083333, 0.416667, -0.083333, 0.583333, -0.583333, -1.583333, -18.750000]));
}

/// robustScale matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;

    auto x = [
        [100.0, 16, 12, 13,   15], 
        [ 12.0, 16,  9,  3, -100]
    ].fuse;

    assert(x.robustScale.all!approxEqual([[14.583333, 0.583333, -0.083333, 0.083333, 0.416667], [-0.083333, 0.583333, -0.583333, -1.583333, -18.750000]]));
}

/// Column robustScale matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all, equal;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;

    auto x = [
        [100.0, 16, 12, 13,   15], 
        [ 12.0, 16,  9,  3, -100]
    ].fuse;

    auto result = [
        [28.333333, 0.333333, -1.0, -0.666667,  0.0], 
        [ 0.333333, 0.777778,  0.0, -0.666667, -12.111111]
    ].fuse;

    // Use byDim with map to scale by row/column.
    auto xRobustScaleByDim = x.byDim!0.map!robustScale;
    auto resultByDim = result.byDim!0;
    assert(xRobustScaleByDim.equal!(equal!approxEqual)(resultByDim));

    auto xRobustScaleAlongDim = x.alongDim!1.map!robustScale;
    auto resultAlongDim = result.alongDim!1;
    assert(xRobustScaleAlongDim.equal!(equal!approxEqual)(resultAlongDim));
}

/// Can control `QuantileAlgo` and output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;

    //Set `QuantileAlgo` algorithm or output type
    auto x = [100.0, 16, 12, 13, 15, 12, 16, 9, 3, -100].sliced;

    assert(x.robustScale!("type9").all!approxEqual([11.864407, 0.474576, -0.0677966, 0.0677966, 0.338983, -0.0677966, 0.474576, -0.474576, -1.288136, -15.254237]));
    assert(x.robustScale!("type1").all!approxEqual([12.500000, 0.500000, -0.0714286, 0.0714286, 0.357143, -0.0714286, 0.500000, -0.500000, -1.357143, -16.071429]));
    assert(x.robustScale!(float, "type6").all!approxEqual([10.294118f, 0.411765f, -0.0588235f, 0.0588235f, 0.294118f, -0.0588235f, 0.411765f, -0.411765f, -1.117647f, -13.235294f]));

    auto y = [uint.max, uint.max / 2, uint.max / 3].sliced;
    assert(y.robustScale!"type1".all!approxEqual([0.75, 0, -0.25]));

    auto z = [ulong.max, ulong.max / 2, ulong.max / 3].sliced;
    assert(z.robustScale!(ulong, "type1").all!approxEqual([0.75, 0, -0.25]));
}

// robustScale withAsSlice
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    static immutable value = [100.0, 16, 12, 13, 15, 12, 16, 9, 3, -100];

    auto x = RCArray!double(10);
    foreach(i, ref e; x)
        e = value[i];

    static immutable result = [14.583333, 0.583333, -0.083333, 0.083333, 0.416667, -0.083333, 0.583333, -0.583333, -1.583333, -18.750000];
    assert(x.robustScale.all!approxEqual(result));
}
