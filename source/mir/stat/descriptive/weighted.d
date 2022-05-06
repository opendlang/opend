/++
This module contains algorithms for descriptive statistics with weights.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2022 Mir Stat Authors.

Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, stat, $1)$(NBSP)
MATHREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, math, $1)$(NBSP)
NDSLICEREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, ndslice, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
T3=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $+))
T4=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4))
+/
module mir.stat.descriptive.weighted;

import mir.math.sum: Summator, ResolveSummationType;
import mir.stat.descriptive.univariate: Summation;

private void putter2(Slices, T, U, Summation summation1, Summation summation2)
    (scope Slices slices, ref Summator!(T, summation1) seed1, ref Summator!(U, summation2) seed2)
{
    import mir.functional: RefTuple;
    static if (is(Slices == RefTuple!(V1, V2), V1, V2)) {
        seed1.put(slices[0]);
        seed2.put(slices[1]);
    } else {
        do
        {
            import mir.ndslice.internal: frontOf;
            frontOf!(slices)[0].putter2(seed1, seed2);
            slices.popFront;
        }
        while(!slices.empty);
    }
}

/++
Assumptions used for weighted moments
+/
enum AssumeWeights : bool
{
    /++
    Primary, does not assume weights sum to one
    +/
    primary,
    
    /++
    Assumes weights sum to one
    +/
    sumToOne
}

/++
Output range for wmean.
+/
struct WMeanAccumulator(T, Summation summation, AssumeWeights assumeWeights,
                        U = T, Summation weightsSummation = summation)
{
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, kindOf;
    import std.range.primitives: isInputRange;
    import std.traits: isIterable;

    ///
    Summator!(T, summation) wsummator;

    static if (!assumeWeights) {
        ///
        Summator!(U, weightsSummation) weights;
    }

    ///
    F wmean(F = T)() const @safe @property pure nothrow @nogc
    {
        static if (assumeWeights) {
            return this.wsum!F;
        } else {
            assert(this.weight!F != 0, "weight must not equal zero");
            return this.wsum!F / this.weight!F;
        }
    }

    ///
    F wsum(F = T)() const @safe @property pure nothrow @nogc
    {
        return cast(F) wsummator.sum;
    }

    ///
    F weight(F = U)() const @safe @property pure nothrow @nogc
    {
        return cast(F) weights.sum;
    }

    ///
    void put(Slice1, Slice2)(Slice1 s, Slice2 w)
        if (isSlice!Slice1 && isSlice!Slice2)
    {
        static assert (Slice1.N == Slice2.N, "s and w must have the same number of dimensions");
        static assert (kindOf!Slice1 == kindOf!Slice2, "s and w must have the same kind");

        import mir.ndslice.slice: Contiguous;
        import mir.ndslice.topology: zip, map;

        assert(s._lengths == w._lengths, "WMeanAcumulator.put: both slices must have the same lengths");

        static if (kindOf!Slice1 != Contiguous && Slice1.N > 1) {
            assert(s.strides == w.strides, "WMeanAccumulator.put: cannot put canonical and universal slices when strides do not match");
            auto combine = s.zip!true(w);
        } else {
            auto combine = s.zip!false(w);
        }

        static if (assumeWeights) {
            auto combine2 = combine.map!"a * b";
            wsummator.put(combine2);
        } else {
            auto combine2 = combine.map!("b", "a * b");
            combine2.putter2(weights, wsummator);
        }
    }

    ///
    void put(SliceLike1, SliceLike2)(SliceLike1 s, SliceLike2 w)
        if (isConvertibleToSlice!SliceLike1 && !isSlice!SliceLike1 &&
            isConvertibleToSlice!SliceLike2 && !isSlice!SliceLike2)
    {
        import mir.ndslice.slice: toSlice;
        this.put(s.toSlice, w.toSlice);
    }

    ///
    void put(Range)(Range r)
        if (isIterable!Range && !assumeWeights)
    {
        import mir.primitives: hasShape, elementCount;
        static if (hasShape!Range) {
            wsummator.put(r);
            weights.put(cast(U) r.elementCount);
        } else {
            foreach(x; r)
            {
                this.put(x);
            }
        }
    }

    ///
    void put(RangeA, RangeB)(RangeA r, RangeB w)
        if (isInputRange!RangeA && !isConvertibleToSlice!RangeA &&
            isInputRange!RangeB && !isConvertibleToSlice!RangeB)
    {
        do
        {
            assert(!(!r.empty && w.empty) && !(r.empty && !w.empty),
                   "r and w must both be empty at the same time, one cannot be empty while the other has remaining items");
            this.put(r.front, w.front);
            r.popFront;
            w.popFront;
        } while(!r.empty || !w.empty); // Using an || instead of && so that the loop does not end early. mis-matched lengths of r and w sould be caught by above assert
    }

    ///
    void put()(T x, U w)
    {
        static if (!assumeWeights) {
            weights.put(w);
        }
        wsummator.put(x * w);
    }

    ///
    void put()(T x)
        if (!assumeWeights)
    {
        weights.put(cast(U) 1);
        wsummator.put(x);
    }

    ///
    void put(F = T, G = U)(WMeanAccumulator!(F, summation, assumeWeights, G, weightsSummation) wm)
        if (!assumeWeights) // because calculating is easier. When assumeWeightsSumtoOne = true, need to divide original wsummator and wm by 2.
    {
        weights.put(cast(U) wm.weights);
        wsummator.put(cast(T) wm.wsummator);
    }
}

/// Assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.stat.descriptive.univariate: Summation;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.sumToOne) x;
    x.put([0.0, 1, 2, 3, 4].sliced, [0.2, 0.2, 0.2, 0.2, 0.2].sliced);
    assert(x.wmean == 2);
    x.put(5, 0.0);
    assert(x.wmean == 2);
}

// dynamic array test, assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.sumToOne) x;
    x.put([0.0, 1, 2, 3, 4], [0.2, 0.2, 0.2, 0.2, 0.2]);
    assert(x.wmean == 2);
}

// static array test, assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.sumToOne) x;
    static immutable y = [0.0, 1, 2, 3, 4];
    static immutable w = [0.2, 0.2, 0.2, 0.2, 0.2];
    x.put(y, w);
    assert(x.wmean == 2);
}

// 2-d slice test, assume weights sum to 1
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.sumToOne) x;
    auto y = [
        [0.0, 1, 2],
        [3.0, 4, 5]
    ].fuse;
    auto w = [
        [1.0 / 21, 2.0 / 21, 3.0 / 21],
        [4.0 / 21, 5.0 / 21, 6.0 / 21]
    ].fuse;
    x.put(y, w);
    assert(x.wmean.approxEqual(70.0 / 21));
}

// universal 2-d slice test, assume weights sum to 1, using map
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: iota, map, universal;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.sumToOne) x;
    auto y = iota([2, 3]).universal;
    auto w = iota([2, 3], 1).map!(a => a / 21.0).universal;
    x.put(y, w);
    assert(x.wmean.approxEqual(70.0 / 21));
}

// 2-d canonical slice test, assume weights sum to 1, using map
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: canonical, iota, map;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.sumToOne) x;
    auto y = iota([2, 3]).canonical;
    auto w = iota([2, 3], 1).map!(a => a / 21.0).canonical;
    x.put(y, w);
    assert(x.wmean.approxEqual(70.0 / 21));
}

/// Do not assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.descriptive.univariate: Summation;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    x.put([0.0, 1, 2, 3, 4].sliced, [1, 2, 3, 4, 5].sliced);
    assert(x.wmean.approxEqual(40.0 / 15));
    x.put(5, 6);
    assert(x.wmean.approxEqual(70.0 / 21));
}

// dynamic array test, do not assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    x.put([0.0, 1, 2, 3, 4], [1, 2, 3, 4, 5]);
    assert(x.wmean.approxEqual(40.0 / 15));
}

// static array test, do not assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    static immutable y = [0.0, 1, 2, 3, 4];
    static immutable w = [1, 2, 3, 4, 5];
    x.put(y, w);
    assert(x.wmean.approxEqual(40.0 / 15));
}

// 2-d slice test, do not assume weights sum to 1
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    auto y = [
        [0.0, 1, 2],
        [3.0, 4, 5]
    ].fuse;
    auto w = [
        [1.0, 2, 3],
        [4.0, 5, 6]
    ].fuse;
    x.put(y, w);
    assert(x.wmean.approxEqual(70.0 / 21));
}

// universal slice test, do not assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: iota, universal;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    auto y = iota(6).universal;
    auto w = iota([6], 1).universal;
    x.put(y, w);
    assert(x.wmean.approxEqual(70.0 / 21));
}

// canonical slice test, do not assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: canonical, iota;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    auto y = iota(6).canonical;
    auto w = iota([6], 1).canonical;
    x.put(y, w);
    assert(x.wmean.approxEqual(70.0 / 21));
}

// 2-d universal slice test, do not assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: iota, universal;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    auto y = iota([2, 3]).universal;
    auto w = iota([2, 3], 1).universal;
    x.put(y, w);
    assert(x.wmean.approxEqual(70.0 / 21));
}

// 2-d canonical slice test, do not assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: canonical, iota;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    auto y = iota([2, 3]).canonical;
    auto w = iota([2, 3], 1).canonical;
    x.put(y, w);
    assert(x.wmean.approxEqual(70.0 / 21));
}

/// Assume no weights, like MeanAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.stat.descriptive.univariate: Summation;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    x.put([0.0, 1, 2, 3, 4].sliced);
    assert(x.wmean == 2);
    x.put(5);
    assert(x.wmean == 2.5);
}

// dynamic array test, assume no weights
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    x.put([0.0, 1, 2, 3, 4]);
    assert(x.wmean == 2);
}

// static array test, assume no weights
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    static immutable y = [0.0, 1, 2, 3, 4];
    x.put(y);
    assert(x.wmean == 2);
}

// Adding WMeanAccmulators
version(mir_stat_test)
@safe pure nothrow
unittest
{
    double[] x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25];
    double[] y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    
    WMeanAccumulator!(float, Summation.pairwise, AssumeWeights.primary) m0;
    m0.put(x);
    WMeanAccumulator!(float, Summation.pairwise, AssumeWeights.primary) m1;
    m1.put(y);
    m0.put(m1);
    assert(m0.wmean == 29.25 / 12);
}

// repeat test, assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: slicedField;
    import mir.ndslice.topology: iota, map, repeat;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    auto y = iota(6);
    auto w = repeat(1.0, 6).map!(a => a / 6.0).slicedField;
    x.put(y, w);
    assert(x.wmean.approxEqual(15.0 / 6));
}

// repeat test, do not assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: slicedField;
    import mir.ndslice.topology: iota, repeat;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    auto y = iota(6);
    auto w = repeat(1.0, 6).slicedField;
    x.put(y, w);
    assert(x.wmean.approxEqual(15.0 / 6));
}

// range test without shape, assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import std.algorithm: map;
    import std.range: iota;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.sumToOne) x;
    auto y = iota(6);
    auto w = iota(1, 7).map!(a => a / 21.0);
    x.put(y, w);
    assert(x.wmean.approxEqual(70.0 / 21));
}

// range test without shape, do not assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import std.range: iota;

    WMeanAccumulator!(double, Summation.pairwise, AssumeWeights.primary) x;
    auto y = iota(6);
    auto w = iota(1, 7);
    x.put(y, w);
    assert(x.wmean.approxEqual(70.0 / 21));
}

// complex test, do not assume weights sum to 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex;
    import mir.complex.math: capproxEqual = approxEqual;
    alias C = Complex!double;

    WMeanAccumulator!(C, Summation.pairwise, AssumeWeights.primary, double) x;
    x.put([C(1, 3), C(2), C(3)]);
    assert(x.wmean.capproxEqual(C(6, 3) / 3));
}

/++
Computes the weighted mean of the input.

By default, if `F` is not floating point type or complex type, then the result
will have a `double` type if `F` is implicitly convertible to a floating point 
type or a type for which `isComplex!F` is true.

Params:
    F = controls type of output
    summation = algorithm for calculating sums (default: Summation.appropriate)
    assumeWeights = true if weights are assumed to add to 1 (default = AssumeWeights.primary)
    G = controls the type of weights
Returns:
    The weighted mean of all the elements in the input, must be floating point or complex type

See_also: 
    $(MATHREF sum, Summation),
    $(MATHREF stat, mean),
    $(MATHREF stat, meanType)
+/
template wmean(F, Summation summation = Summation.appropriate,
               AssumeWeights assumeWeights = AssumeWeights.primary, 
               G = F, Summation weightsSummation = Summation.appropriate)
    if (!is(F : AssumeWeights))
{
    import mir.math.common: fmamath;
    import mir.math.stat: meanType;
    import mir.ndslice.slice: isConvertibleToSlice;
    import std.traits: isIterable;

    /++
    Params:
        s = slice-like
        w = weights
    +/
    @fmamath meanType!F wmean(SliceA, SliceB)(SliceA s, SliceB w)
        if (isConvertibleToSlice!SliceA && isConvertibleToSlice!SliceB)
    {
        import core.lifetime: move;

        alias H = typeof(return);
        WMeanAccumulator!(H, ResolveSummationType!(summation, SliceA, H), assumeWeights, 
                          G, ResolveSummationType!(weightsSummation, SliceB, G)) wmean;
        wmean.put(s.move, w.move);
        return wmean.wmean;
    }

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath meanType!F wmean(Range)(Range r)
        if (isIterable!Range)
    {
        import core.lifetime: move;

        alias H = typeof(return);
        WMeanAccumulator!(H, ResolveSummationType!(summation, Range, H), assumeWeights, G, ResolveSummationType!(weightsSummation, Range, G)) wmean;
        wmean.put(r.move);
        return wmean.wmean;
    }
}

/// ditto
template wmean(Summation summation = Summation.appropriate,
               AssumeWeights assumeWeights = AssumeWeights.primary,
               Summation weightsSummation = Summation.appropriate)
{
    import mir.math.common: fmamath;
    import mir.math.stat: meanType;
    import mir.ndslice.slice: isConvertibleToSlice;
    import std.traits: isIterable;

    /++
    Params:
        s = slice-like
        w = weights
    +/
    @fmamath meanType!SliceA wmean(SliceA, SliceB)(SliceA s, SliceB w)
        if (isConvertibleToSlice!SliceA && isConvertibleToSlice!SliceB)
    {
        import core.lifetime: move;
        import mir.math.sum: sumType;

        alias F = typeof(return);
        return .wmean!(F, summation, assumeWeights, sumType!SliceB, weightsSummation)(s.move, w.move);
    }

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath meanType!Range wmean(Range)(Range r)
        if (isIterable!Range)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .wmean!(F, summation, assumeWeights, F, weightsSummation)(r.move);
    }
}

/// ditto
template wmean(F, AssumeWeights assumeWeights, Summation summation = Summation.appropriate, 
               G = F, Summation weightsSummation = Summation.appropriate)
    if (!is(F : AssumeWeights))
{
    import mir.math.common: fmamath;
    import mir.math.stat: meanType;
    import mir.ndslice.slice: isConvertibleToSlice;
    import std.traits: isIterable;

    /++
    Params:
        s = slice-like
        w = weights
    +/
    @fmamath meanType!F wmean(SliceA, SliceB)(SliceA s, SliceB w)
        if (isConvertibleToSlice!SliceA && isConvertibleToSlice!SliceB)
    {
        import core.lifetime: move;
        import mir.math.sum: sumType;

        alias H = typeof(return);
        return .wmean!(H, summation, assumeWeights, G, weightsSummation)(s.move, w.move);
    }

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath meanType!Range wmean(Range)(Range r)
        if (isIterable!Range)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .wmean!(F, summation, assumeWeights, G, weightsSummation)(r.move);
    }
}

/// ditto
template wmean(F, bool assumeWeights, string summation = "appropriate", 
               G = F, string weightsSummation = "appropriate")
    if (!is(F : AssumeWeights))
{
    mixin("alias wmean = .wmean!(F, Summation." ~ summation ~ ", cast(AssumeWeights) assumeWeights, G, Summation." ~ weightsSummation ~ ");");
}

/// ditto
template wmean(bool assumeWeights, string summation = "appropriate",
               string weightsSummation = "appropriate")
{
    mixin("alias wmean = .wmean!(Summation." ~ summation ~ ", cast(AssumeWeights) assumeWeights, Summation." ~ weightsSummation ~ ");");
}

/// ditto
template wmean(F, string summation, bool assumeWeights = false,
               G = F, string weightsSummation = "appropriate")
    if (!is(F : AssumeWeights))
{
    mixin("alias wmean = .wmean!(F, Summation." ~ summation ~ ", cast(AssumeWeights) assumeWeights, G, Summation." ~ weightsSummation ~ ");");
}

/// ditto
template wmean(string summation, bool assumeWeights = false,
               string weightsSummation = "appropriate")
{
    mixin("alias wmean = .wmean!(Summation." ~ summation ~ ", cast(AssumeWeights) assumeWeights, Summation." ~ weightsSummation ~ ");");
}

/// ditto
template wmean(F, string summation, G, string weightsSummation, bool assumeWeights)
    if (!is(F : AssumeWeights))
{
    mixin("alias wmean = .wmean!(F, Summation." ~ summation ~ ", cast(AssumeWeights) assumeWeights, G, Summation." ~ weightsSummation ~ ");");
}

/// ditto
template wmean(string summation, string weightsSummation, bool assumeWeights = false)
{
    mixin("alias wmean = .wmean!(Summation." ~ summation ~ ", cast(AssumeWeights) assumeWeights, Summation." ~ weightsSummation ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex;
    import mir.complex.math: capproxEqual = approxEqual;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    alias C = Complex!double;

    assert(wmean([1.0, 2, 3], [1, 2, 3]) == (1.0 + 4.0 + 9.0) / 6);
    assert(wmean!true([1.0, 2, 3], [1.0 / 6, 2.0 / 6, 3.0 / 6]).approxEqual((1.0 + 4.0 + 9.0) / 6));
    assert(wmean([C(1, 3), C(2), C(3)], [1, 2, 3]).capproxEqual(C((1.0 + 4.0 + 9.0) / 6, 3.0 / 6)));

    assert(wmean!float([0, 1, 2, 3, 4, 5].sliced(3, 2), [1, 2, 3, 4, 5, 6].sliced(3, 2)).approxEqual(70.0 / 21));

    static assert(is(typeof(wmean!float([1, 2, 3], [1, 2, 3])) == float));
}

/// If weights are not provided, then behaves like mean
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.complex;
    alias C = Complex!double;

    assert(wmean([1.0, 2, 3]) == 2);
    assert(wmean([C(1, 3), C(2), C(3)]) == C(2, 1));

    assert(wmean!float([0, 1, 2, 3, 4, 5].sliced(3, 2)) == 2.5);

    static assert(is(typeof(wmean!float([1, 2, 3])) == float));
}

/// Weighted mean of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: iota, map;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto w = iota([12], 1);
    auto w_SumToOne = w.map!(a => a / 78.0);

    assert(x.wmean == 29.25 / 12);
    assert(x.wmean(w) == 203.0 / 78);
    assert(x.wmean!true(w_SumToOne) == 203.0 / 78);
}

/// Weighted mean of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: iota, map;

    auto x = [
        [0.0, 1.0, 1.5, 2.0, 3.5, 4.25],
        [2.0, 7.5, 5.0, 1.0, 1.5, 0.0]
    ].fuse;
    auto w = iota([2, 6], 1);
    auto w_SumToOne = w.map!(a => a / 78.0);

    assert(x.wmean == 29.25 / 12);
    assert(x.wmean(w) == 203.0 / 78);
    assert(x.wmean!true(w_SumToOne) == 203.0 / 78);
}

/// Column mean of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, byDim, iota, map, universal;

    auto x = [
        [0.0, 1.0, 1.5, 2.0, 3.5, 4.25],
        [2.0, 7.5, 5.0, 1.0, 1.5, 0.0]
    ].fuse;
    auto w = iota([2], 1).universal;
    auto result = [4.0 / 3, 16.0 / 3, 11.5 / 3, 4.0 / 3, 6.5 / 3, 4.25 / 3];

    // Use byDim or alongDim with map to compute mean of row/column.
    assert(x.byDim!1.map!(a => a.wmean(w)).all!approxEqual(result));
    assert(x.alongDim!0.map!(a => a.wmean(w)).all!approxEqual(result));

    // FIXME
    // Without using map, computes the mean of the whole slice
    // assert(x.byDim!1.wmean(w) == x.sliced.wmean);
    // assert(x.alongDim!0.wmean(w) == x.sliced.wmean);
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat, universal;

    //Set sum algorithm (also for weights) or output type

    auto a = [1, 1e100, 1, -1e100].sliced;

    auto x = a * 10_000;
    auto w1 = [1, 1, 1, 1].sliced;
    auto w2 = [0.25, 0.25, 0.25, 0.25].sliced;

    assert(x.wmean!"kbn"(w1) == 20_000 / 4);
    assert(x.universal.wmean!(true, "kbn")(w2.universal) == 20_000 / 4);
    assert(x.universal.wmean!("kbn", true)(w2.universal) == 20_000 / 4);
    assert(x.universal.wmean!("kbn", true, "pairwise")(w2.universal) == 20_000 / 4);
    assert(x.universal.wmean!(true, "kbn", "pairwise")(w2.universal) == 20_000 / 4);
    assert(x.wmean!"kb2"(w1) == 20_000 / 4);
    assert(x.wmean!"precise"(w1) == 20_000 / 4);
    assert(x.wmean!(double, "precise")(w1) == 20_000.0 / 4);

    auto y = uint.max.repeat(3);
    assert(y.wmean!ulong([1, 1, 1].sliced.universal) == 12884901885 / 3);
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
    auto w = [1, 2, 3,  4,  5,  6,
              7, 8, 9, 10, 11, 12].sliced;

    auto y = x.wmean(w);
    assert(y.approxEqual(204.0 / 78, 1.0e-10));
    static assert(is(typeof(y) == double));

    assert(x.wmean!float(w).approxEqual(204f / 78, 1.0e-10));
}

/++
Mean works for complex numbers and other user-defined types (provided they
can be converted to a floating point or complex type)
+/
version(mir_test_weighted)
@safe pure nothrow
unittest
{
    import mir.complex.math: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.complex;
    alias C = Complex!double;

    auto x = [C(1.0, 2), C(2, 3), C(3, 4), C(4, 5)].sliced;
    auto w = [1, 2, 3, 4].sliced;
    assert(x.wmean(w).approxEqual(C(3, 4)));
}

/// Compute weighted mean tensors along specified dimention of tensors
version(mir_stat_test)
@safe pure
unittest
{
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: alongDim, as, iota, map, universal;
    /++
      [[0,1,2],
       [3,4,5]]
     +/
    auto x = [
        [0, 1, 2],
        [3, 4, 5]
    ].fuse.as!double;
    auto w = [
        [1, 2, 3],
        [4, 5, 6]
    ].fuse;
    auto w1 = [1, 2].sliced.universal;
    auto w2 = [1, 2, 3].sliced;

    assert(x.wmean(w) == (70.0 / 21));

    auto m0 = [(0.0 + 6.0) / 3, (1.0 + 8.0) / 3, (2.0 + 10.0) / 3];
    assert(x.alongDim!0.map!(a => a.wmean(w1)) == m0);
    assert(x.alongDim!(-2).map!(a => a.wmean(w1)) == m0);

    auto m1 = [(0.0 + 2.0 + 6.0) / 6, (3.0 + 8.0 + 15.0) / 6];
    assert(x.alongDim!1.map!(a => a.wmean(w2)) == m1);
    assert(x.alongDim!(-1).map!(a => a.wmean(w2)) == m1);

    assert(iota(2, 3, 4, 5).as!double.alongDim!0.map!wmean == iota([3, 4, 5], 3 * 4 * 5 / 2));
}

// test chaining
version(mir_stat_test)
@safe pure nothrow
unittest
{
    assert([1.0, 2, 3, 4].wmean == 2.5);
}

// additional alongDim tests
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.math.stat: meanType;
    import mir.ndslice.topology: iota, alongDim, map;

    auto x = iota([2, 2], 1);
    auto w = iota([2], 2);
    auto y = x.alongDim!1.map!(a => a.wmean(w));
    static assert(is(meanType!(typeof(y)) == double));
}

// @nogc test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    static immutable w = [1.0, 2, 3,  4,  5,  6,
                            7, 8, 9, 10, 11, 12];

    assert(x.wmean == 29.25 / 12);
    assert(x.wmean(w) == 203.0 / 78);
}
