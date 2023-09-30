/++
This module contains algorithms for univariate descriptive statistics.

Note that used specialized summing algorithms execute more primitive operations
than vanilla summation. Therefore, if in certain cases maximum speed is required
at expense of precision, one can use $(REF_ALTTEXT $(TT Summation.fast), Summation.fast, mir, math, sum)$(NBSP).

$(SCRIPT inhibitQuickIndex = 1;)
$(DIVC quickindex,
$(BOOKTABLE,
$(TR $(TH Category) $(TH Symbols))
    $(TR $(TD Location) $(TD
        $(LREF gmean)
        $(LREF hmean)
        $(LREF mean)
        $(LREF median)
    ))
    $(TR $(TD Deviation) $(TD
        $(LREF dispersion)
        $(LREF entropy)
        $(LREF interquartileRange)
        $(LREF medianAbsoluteDeviation)
        $(LREF quantile)
        $(LREF standardDeviation)
        $(LREF variance)
    ))
    $(TR $(TD Higher Moments, etc.) $(TD
        $(LREF kurtosis)
        $(LREF skewness)
    ))
    $(TR $(TD Other Moment Functions) $(TD
        $(LREF centralMoment)
        $(LREF coefficientOfVariation)
        $(LREF moment)
        $(LREF rawMoment)
        $(LREF standardizedMoment)
    ))
    $(TR $(TD Accumulators) $(TD
        $(LREF EntropyAccumulator)
        $(LREF GMeanAccumulator)
        $(LREF KurtosisAccumulator)
        $(LREF MeanAccumulator)
        $(LREF MomentAccumulator)
        $(LREF SkewnessAccumulator)
        $(LREF VarianceAccumulator)
    ))
    $(TR $(TD Algorithms) $(TD
        $(LREF KurtosisAlgo)
        $(LREF MomentAlgo)
        $(LREF QuantileAlgo)
        $(LREF SkewnessAlgo)
        $(LREF StandardizedMomentAlgo)
        $(LREF VarianceAlgo)
    ))
    $(TR $(TD Types) $(TD
        $(LREF entropyType)
        $(LREF gmeanType)
        $(LREF hmeanType)
        $(LREF meanType)
        $(LREF quantileType)
        $(LREF statType)
        $(LREF stdevType)
    ))
))

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall, Ilya Yaroshenko

Copyright: 2022-3 Mir Stat Authors.

Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, stat, $1)$(NBSP)
MATHREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, math, $1)$(NBSP)
MATHREF_ALT = $(GREF_ALTTEXT mir-algorithm, $(B $(TT $2)), $2, mir, math, $1)$(NBSP)
NDSLICEREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, ndslice, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
T3=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3))
T4=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4))

+/

module mir.stat.descriptive.univariate;

///
public import mir.math.sum: Summation;

import mir.internal.utility: isFloatingPoint;
import mir.math.common: fmamath;
import mir.math.sum: Summator, ResolveSummationType;
import mir.ndslice.slice: hasAsSlice, isConvertibleToSlice, isSlice, Slice, SliceKind;
import std.traits: isIterable, isMutable;

///
package(mir)
template statType(T, bool checkComplex = true)
{
    import mir.internal.utility: isFloatingPoint;

    static if (isFloatingPoint!T) {
        import std.traits: Unqual;
        alias statType = Unqual!T;
    } else static if (is(T : double)) {
        alias statType = double;
    } else static if (checkComplex) {
        import mir.internal.utility: isComplex;
        static if (isComplex!T) {
            static if (__traits(getAliasThis, T).length == 1)
            {
                alias statType = .statType!(typeof(__traits(getMember, T, __traits(getAliasThis, T)[0]))); 
            }
            else
            {
                import std.traits: Unqual;
                alias statType = Unqual!T;
            }
        } else {
            static assert(0, "statType: type " ~ T.stringof ~ " must be convertible to a complex floating point type");
        }
    } else {
        static assert(0, "statType: type " ~ T.stringof ~ " must be convertible to a floating point type");
    }
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static assert(is(statType!int == double));
    static assert(is(statType!uint == double));
    static assert(is(statType!double == double));
    static assert(is(statType!float == float));
    static assert(is(statType!real == real));
    
    static assert(is(statType!(const(int)) == double));
    static assert(is(statType!(immutable(int)) == double));
    static assert(is(statType!(const(double)) == double));
    static assert(is(statType!(immutable(double)) == double));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.complex: Complex;

    static assert(is(statType!(Complex!float) == Complex!float));
    static assert(is(statType!(Complex!double) == Complex!double));
    static assert(is(statType!(Complex!real) == Complex!real));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static struct Foo {
        float x;
        alias x this;
    }

    static assert(is(statType!Foo == double)); // note: this is not float
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.complex;
    static struct Foo {
        Complex!float x;
        alias x this;
    }

    static assert(is(statType!Foo == Complex!float));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static struct Foo {
        double x;
        alias x this;
    }

    static assert(is(statType!Foo == double));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.complex;
    static struct Foo {
        Complex!double x;
        alias x this;
    }

    static assert(is(statType!Foo == Complex!double));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static struct Foo {
        real x;
        alias x this;
    }

    static assert(is(statType!Foo == double)); // note: this is not real
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.complex;
    static struct Foo {
        Complex!real x;
        alias x this;
    }

    static assert(is(statType!Foo == Complex!real));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static struct Foo {
        int x;
        alias x this;
    }

    static assert(is(statType!Foo == double)); // note: this is not ints
}

///
package(mir)
template meanType(T)
{
    import mir.math.sum: sumType;

    alias U = sumType!T;

    static if (__traits(compiles, {
        auto temp = U.init + U.init;
        auto a = temp / 2;
        temp += U.init;
    })) {
        alias V = typeof((U.init + U.init) / 2);
        alias meanType = statType!V;
    } else {
        static assert(0, "meanType: Can't calculate mean of elements of type " ~ U.stringof);
    }
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static assert(is(meanType!(int[]) == double));
    static assert(is(meanType!(double[]) == double));
    static assert(is(meanType!(float[]) == float));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.complex;
    static assert(is(meanType!(Complex!float[]) == Complex!float));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static struct Foo {
        float x;
        alias x this;
    }

    static assert(is(meanType!(Foo[]) == float));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.complex;
    static struct Foo {
        Complex!float x;
        alias x this;
    }

    static assert(is(meanType!(Foo[]) == Complex!float));
}

/++
Output range for mean.
+/
struct MeanAccumulator(T, Summation summation)
{
    import mir.primitives: elementCount, hasShape;
    import std.traits: isIterable;

    ///
    size_t count;
    ///
    Summator!(T, summation) summator;

    ///
    F mean(F = T)() const @safe @property pure nothrow @nogc
    {
        return cast(F) summator.sum / cast(F) count;
    }
    
    ///
    F sum(F = T)() const @safe @property pure nothrow @nogc
    {
        return cast(F) summator.sum;
    }

    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        static if (hasShape!Range)
        {
            count += r.elementCount;
            summator.put(r);
        }
        else
        {
            foreach(x; r)
            {
                count++;
                summator.put(x);
            }
        }
    }

    ///
    void put()(T x)
    {
        count++;
        summator.put(x);
    }
    
    ///
    void put(F = T)(MeanAccumulator!(F, summation) m)
    {
        count += m.count;
        summator.put(cast(T) m.summator);
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;

    MeanAccumulator!(double, Summation.pairwise) x;
    x.put([0.0, 1, 2, 3, 4].sliced);
    assert(x.mean == 2);
    x.put(5);
    assert(x.mean == 2.5);
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;

    MeanAccumulator!(float, Summation.pairwise) x;
    x.put([0, 1, 2, 3, 4].sliced);
    assert(x.mean == 2);
    assert(x.sum == 10);
    x.put(5);
    assert(x.mean == 2.5);
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    double[] x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25];
    double[] y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
    
    MeanAccumulator!(float, Summation.pairwise) m0;
    m0.put(x);
    MeanAccumulator!(float, Summation.pairwise) m1;
    m1.put(y);
    m0.put(m1);
    assert(m0.mean == 29.25 / 12);
}

/++
Computes the mean of the input.

By default, if `F` is not floating point type or complex type, then the result
will have a `double` type if `F` is implicitly convertible to a floating point 
type or a type for which `isComplex!F` is true.

Params:
    F = controls type of output
    summation = algorithm for calculating sums (default: Summation.appropriate)
Returns:
    The mean of all the elements in the input, must be floating point or complex type

See_also: 
    $(SUBREF sum, Summation)
+/
template mean(F, Summation summation = Summation.appropriate)
{
    import core.lifetime: move;
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath meanType!F mean(Range)(Range r)
        if (isIterable!Range)
    {
        alias G = typeof(return);
        MeanAccumulator!(G, ResolveSummationType!(summation, Range, G)) mean;
        mean.put(r.move);
        return mean.mean;
    }
    
    /++
    Params:
        ar = values
    +/
    @fmamath meanType!F mean(scope const F[] ar...)
    {
        alias G = typeof(return);
        MeanAccumulator!(G, ResolveSummationType!(summation, const(G)[], G)) mean;
        mean.put(ar);
        return mean.mean;
    }
}

/// ditto
template mean(Summation summation = Summation.appropriate)
{
    import core.lifetime: move;
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath meanType!Range mean(Range)(Range r)
        if (isIterable!Range)
    {
        alias F = typeof(return);
        return .mean!(F, summation)(r.move);
    }
    
    /++
    Params:
        ar = values
    +/
    @fmamath meanType!T mean(T)(scope const T[] ar...)
    {
        alias F = typeof(return);
        return .mean!(F, summation)(ar);
    }
}

/// ditto
template mean(F, string summation)
{
    mixin("alias mean = .mean!(F, Summation." ~ summation ~ ");");
}

/// ditto
template mean(string summation)
{
    mixin("alias mean = .mean!(Summation." ~ summation ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.complex;
    alias C = Complex!double;

    assert(mean([1.0, 2, 3]) == 2);
    assert(mean([C(1, 3), C(2), C(3)]) == C(2, 1));
    
    assert(mean!float([0, 1, 2, 3, 4, 5].sliced(3, 2)) == 2.5);
    
    static assert(is(typeof(mean!float([1, 2, 3])) == float));
}

/// Mean of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    assert(x.mean == 29.25 / 12);
}

/// Mean of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.ndslice.fuse: fuse;

    auto x = [
        [0.0, 1.0, 1.5, 2.0, 3.5, 4.25],
        [2.0, 7.5, 5.0, 1.0, 1.5, 0.0]
    ].fuse;

    assert(x.mean == 29.25 / 12);
}

/// Column mean of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;

    auto x = [
        [0.0, 1.0, 1.5, 2.0, 3.5, 4.25],
        [2.0, 7.5, 5.0, 1.0, 1.5, 0.0]
    ].fuse;
    auto result = [1, 4.25, 3.25, 1.5, 2.5, 2.125];

    // Use byDim or alongDim with map to compute mean of row/column.
    assert(x.byDim!1.map!mean.all!approxEqual(result));
    assert(x.alongDim!0.map!mean.all!approxEqual(result));

    // FIXME
    // Without using map, computes the mean of the whole slice
    // assert(x.byDim!1.mean == x.sliced.mean);
    // assert(x.alongDim!0.mean == x.sliced.mean);
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;

    //Set sum algorithm or output type

    auto a = [1, 1e100, 1, -1e100].sliced;

    auto x = a * 10_000;

    assert(x.mean!"kbn" == 20_000 / 4);
    assert(x.mean!"kb2" == 20_000 / 4);
    assert(x.mean!"precise" == 20_000 / 4);
    assert(x.mean!(double, "precise") == 20_000.0 / 4);

    auto y = uint.max.repeat(3);
    assert(y.mean!ulong == 12884901885 / 3);
}

/++
For integral slices, pass output type as template parameter to ensure output
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

    auto y = x.mean;
    assert(y.approxEqual(29.0 / 12, 1.0e-10));
    static assert(is(typeof(y) == double));

    assert(x.mean!float.approxEqual(29f / 12, 1.0e-10));
}

/++
Mean works for complex numbers and other user-defined types (provided they
can be converted to a floating point or complex type)
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex.math: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.complex;
    alias C = Complex!double;

    auto x = [C(1.0, 2), C(2, 3), C(3, 4), C(4, 5)].sliced;
    assert(x.mean.approxEqual(C(2.5, 3.5)));
}

/// Compute mean tensors along specified dimention of tensors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice: alongDim, iota, as, map;
    /++
      [[0,1,2],
       [3,4,5]]
     +/
    auto x = iota(2, 3).as!double;
    assert(x.mean == (5.0 / 2.0));

    auto m0 = [(0.0+3.0)/2.0, (1.0+4.0)/2.0, (2.0+5.0)/2.0];
    assert(x.alongDim!0.map!mean == m0);
    assert(x.alongDim!(-2).map!mean == m0);

    auto m1 = [(0.0+1.0+2.0)/3.0, (3.0+4.0+5.0)/3.0];
    assert(x.alongDim!1.map!mean == m1);
    assert(x.alongDim!(-1).map!mean == m1);

    assert(iota(2, 3, 4, 5).as!double.alongDim!0.map!mean == iota([3, 4, 5], 3 * 4 * 5 / 2));
}

/// Arbitrary mean
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    assert(mean(1.0, 2, 3) == 2);
    assert(mean!float(1, 2, 3) == 2);
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    assert([1.0, 2, 3, 4].mean == 2.5);
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: iota, alongDim, map;

    auto x = iota([2, 2], 1);
    auto y = x.alongDim!1.map!mean;
    assert(y.all!approxEqual([1.5, 3.5]));
    static assert(is(meanType!(typeof(y)) == double));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.mean == 29.25 / 12);
    assert(x.sliced.mean!float == 29.25 / 12);
}

///
package(mir)
template hmeanType(T)
{
    import mir.math.sum: sumType;
    
    alias U = sumType!T;

    static if (__traits(compiles, {
        U t = U.init + cast(U) 1; //added for when U.init = 0
        auto temp = cast(U) 1 / t + cast(U) 1 / t;
    })) {
        alias V = typeof(cast(U) 1 / ((cast(U) 1 / U.init + cast(U) 1 / U.init) / cast(U) 2));
        alias hmeanType = statType!V;
    } else {
        static assert(0, "hmeanType: Can't calculate hmean of elements of type " ~ U.stringof);
    }
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.complex;
    static assert(is(hmeanType!(int[]) == double));
    static assert(is(hmeanType!(double[]) == double));
    static assert(is(hmeanType!(float[]) == float)); 
    static assert(is(hmeanType!(Complex!float[]) == Complex!float));    
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.complex;
    static struct Foo {
        float x;
        alias x this;
    }
    
    static struct Bar {
        Complex!float x;
        alias x this;
    }

    static assert(is(hmeanType!(Foo[]) == float));
    static assert(is(hmeanType!(Bar[]) == Complex!float));
}

/++
Computes the harmonic mean of the input.

By default, if `F` is not floating point type or complex type, then the result
will have a `double` type if `F` is implicitly convertible to a floating point 
type or a type for which `isComplex!F` is true.

Params:
    F = controls type of output
    summation = algorithm for calculating sums (default: Summation.appropriate)
Returns:
    harmonic mean of all the elements of the input, must be floating point or complex type

See_also: 
    $(SUBREF sum, Summation)
+/
template hmean(F, Summation summation = Summation.appropriate)
{
    import core.lifetime: move;
    import std.traits: isIterable;

    /++
    Params:
        r = range
    +/
    @fmamath hmeanType!F hmean(Range)(Range r)
        if (isIterable!Range)
    {
        import mir.ndslice.topology: map;

        alias G = typeof(return);
        auto numerator = cast(G) 1;

        static if (summation == Summation.fast && __traits(compiles, r.move.map!"numerator / a"))
        {
            return numerator / r.move.map!"numerator / a".mean!(G, summation);
        }
        else
        {
            MeanAccumulator!(G, ResolveSummationType!(summation, Range, G)) imean;
            foreach (e; r)
                imean.put(numerator / e);
            return numerator / imean.mean;
        }
    }
   
    /++
    Params:
        ar = values
    +/
    @fmamath hmeanType!F hmean(scope const F[] ar...)
    {
        alias G = typeof(return);

        auto numerator = cast(G) 1;

        static if (summation == Summation.fast && __traits(compiles, ar.map!"numerator / a"))
        {
            return numerator / ar.map!"numerator / a".mean!(G, summation);
        }
        else
        {
            MeanAccumulator!(G, ResolveSummationType!(summation, const(G)[], G)) imean;
            foreach (e; ar)
                imean.put(numerator / e);
            return numerator / imean.mean;
        }
    }
}

/// ditto
template hmean(Summation summation = Summation.appropriate)
{
    import core.lifetime: move;
    import std.traits: isIterable;

    /++
    Params:
        r = range
    +/
    @fmamath hmeanType!Range hmean(Range)(Range r)
        if (isIterable!Range)
    {
        alias F = typeof(return);
        return .hmean!(F, summation)(r.move);
    }
    
    /++
    Params:
        ar = values
    +/
    @fmamath hmeanType!T hmean(T)(scope const T[] ar...)
    {
        alias F = typeof(return);
        return .hmean!(F, summation)(ar);
    }
}

/// ditto
template hmean(F, string summation)
{
    mixin("alias hmean = .hmean!(F, Summation." ~ summation ~ ");");
}

/// ditto
template hmean(string summation)
{
    mixin("alias hmean = .hmean!(Summation." ~ summation ~ ");");
}

/// Harmonic mean of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [20.0, 100.0, 2000.0, 10.0, 5.0, 2.0].sliced;

    assert(x.hmean.approxEqual(6.97269));
}

/// Harmonic mean of matrix
version(mir_stat_test)
pure @safe
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;

    auto x = [
        [20.0, 100.0, 2000.0], 
        [10.0, 5.0, 2.0]
    ].fuse;

    assert(x.hmean.approxEqual(6.97269));
}

/// Column harmonic mean of matrix
version(mir_stat_test)
pure @safe
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;

    auto x = [
        [20.0, 100.0, 2000.0],
        [ 10.0, 5.0, 2.0]
    ].fuse;

    auto y = [13.33333, 9.52381, 3.996004];

    // Use byDim or alongDim with map to compute mean of row/column.
    assert(x.byDim!1.map!hmean.all!approxEqual(y));
    assert(x.alongDim!0.map!hmean.all!approxEqual(y));
}

/// Can also pass arguments to hmean
version(mir_stat_test)
pure @safe nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: repeat;
    import mir.ndslice.slice: sliced;

    //Set sum algorithm or output type
    auto x = [1, 1e-100, 1, -1e-100].sliced;

    assert(x.hmean!"kb2".approxEqual(2));
    assert(x.hmean!"precise".approxEqual(2));
    assert(x.hmean!(double, "precise").approxEqual(2));

    //Provide the summation type
    assert(float.max.repeat(3).hmean!double.approxEqual(float.max));
}

/++
For integral slices, pass output type as template parameter to ensure output
type is correct. 
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [20, 100, 2000, 10, 5, 2].sliced;

    auto y = x.hmean;

    assert(y.approxEqual(6.97269));
    static assert(is(typeof(y) == double));

    assert(x.hmean!float.approxEqual(6.97269));
}

/++
hmean works for complex numbers and other user-defined types (provided they
can be converted to a floating point or complex type)
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex.math: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.complex;
    alias C = Complex!double;

    auto x = [C(1, 2), C(2, 3), C(3, 4), C(4, 5)].sliced;
    assert(x.hmean.approxEqual(C(1.97110904, 3.14849332)));
}

/// Arbitrary harmonic mean
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = hmean(20.0, 100, 2000, 10, 5, 2);
    assert(x.approxEqual(6.97269));
    
    auto y = hmean!float(20, 100, 2000, 10, 5, 2);
    assert(y.approxEqual(6.97269));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [20.0, 100.0, 2000.0, 10.0, 5.0, 2.0];

    assert(x.sliced.hmean.approxEqual(6.97269));
    assert(x.sliced.hmean!float.approxEqual(6.97269));
}

private
F nthroot(F)(in F x, in size_t n)
    if (isFloatingPoint!F)
{
    import mir.math.common: sqrt, pow;

    if (n > 2) {
        return pow(x, cast(F) 1 / cast(F) n);
    } else if (n == 2) {
        return sqrt(x);
    } else if (n == 1) {
        return x;
    } else {
        return cast(F) 1;
    }
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;

    assert(nthroot(9.0, 0).approxEqual(1));
    assert(nthroot(9.0, 1).approxEqual(9));
    assert(nthroot(9.0, 2).approxEqual(3));
    assert(nthroot(9.5, 2).approxEqual(3.08220700));
    assert(nthroot(9.0, 3).approxEqual(2.08008382));
}

/++
Output range for gmean.
+/
struct GMeanAccumulator(T) 
    if (isMutable!T && isFloatingPoint!T)
{
    import mir.math.numeric: ProdAccumulator;
    import mir.primitives: elementCount, hasShape;

    ///
    size_t count;
    ///
    ProdAccumulator!T prodAccumulator;

    ///
    F gmean(F = T)() const @property
        if (isFloatingPoint!F)
    {
        import mir.math.common: exp2;

        return nthroot(cast(F) prodAccumulator.mantissa, count) * exp2(cast(F) prodAccumulator.exp / count);
    }

    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        static if (hasShape!Range)
        {
            count += r.elementCount;
            prodAccumulator.put(r);
        }
        else
        {
            foreach(x; r)
            {
                count++;
                prodAccumulator.put(x);
            }
        }
    }

    ///
    void put()(T x)
    {
        count++;
        prodAccumulator.put(x);
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    GMeanAccumulator!double x;
    x.put([1.0, 2, 3, 4].sliced);
    assert(x.gmean.approxEqual(2.21336384));
    x.put(5);
    assert(x.gmean.approxEqual(2.60517108));
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    GMeanAccumulator!float x;
    x.put([1, 2, 3, 4].sliced);
    assert(x.gmean.approxEqual(2.21336384));
    x.put(5);
    assert(x.gmean.approxEqual(2.60517108));
}

///
package(mir)
template gmeanType(T)
{
    // TODO: including copy because visibility in mir.math.numeric is set to package
    private template prodType(T)
    {
        import mir.math.sum: elementType;

        alias U = elementType!T;
        
        static if (__traits(compiles, {
            auto temp = U.init * U.init;
            temp *= U.init;
        })) {
            alias V = typeof(U.init * U.init);
            alias prodType = statType!(V, false);
        } else {
            static assert(0, "prodType: Can't prod elements of type " ~ U.stringof);
        }
    }

    alias U = prodType!T;

    static if (__traits(compiles, {
        auto temp = U.init * U.init;
        auto a = nthroot(temp, 2);
        temp *= U.init;
    })) {
        alias V = typeof(nthroot(U.init * U.init, 2));
        alias gmeanType = statType!(V, false);
    } else {
        static assert(0, "gmeanType: Can't calculate gmean of elements of type " ~ U.stringof);
    }
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static assert(is(gmeanType!int == double));
    static assert(is(gmeanType!double == double));
    static assert(is(gmeanType!float == float));
    static assert(is(gmeanType!(int[]) == double));
    static assert(is(gmeanType!(double[]) == double));
    static assert(is(gmeanType!(float[]) == float));    
}

/++
Computes the geometric average of the input.

By default, if `F` is not floating point type, then the result will have a 
`double` type if `F` is implicitly convertible to a floating point type.

Params:
    r = range, must be finite iterable
Returns:
    The geometric average of all the elements in the input, must be floating point type

See_also: 
    $(SUBREF numeric, prod)
+/
@fmamath gmeanType!F gmean(F, Range)(Range r)
    if (isFloatingPoint!F && isIterable!Range)
{
    import core.lifetime: move;

    alias G = typeof(return);
    GMeanAccumulator!G gmean;
    gmean.put(r.move);
    return gmean.gmean;
}
    
/// ditto
@fmamath gmeanType!Range gmean(Range)(Range r)
    if (isIterable!Range)
{
    import core.lifetime: move;

    alias G = typeof(return);
    return .gmean!(G, Range)(r.move);
}

/++
Params:
    ar = values
+/
@fmamath gmeanType!F gmean(F)(scope const F[] ar...)
    if (isFloatingPoint!F)
{
    alias G = typeof(return);
    GMeanAccumulator!G gmean;
    gmean.put(ar);
    return gmean.gmean;
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    assert(gmean([1.0, 2, 3]).approxEqual(1.81712059));
    
    assert(gmean!float([1, 2, 3, 4, 5, 6].sliced(3, 2)).approxEqual(2.99379516));
    
    static assert(is(typeof(gmean!float([1, 2, 3])) == float));
}

/// Geometric mean of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [3.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 2.0].sliced;

    assert(x.gmean.approxEqual(2.36178395));
}

/// Geometric mean of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;

    auto x = [
        [3.0, 1.0, 1.5, 2.0, 3.5, 4.25],
        [2.0, 7.5, 5.0, 1.0, 1.5, 2.0]
    ].fuse;

    assert(x.gmean.approxEqual(2.36178395));
}

/// Column gmean of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;

    auto x = [
        [3.0, 1.0, 1.5, 2.0, 3.5, 4.25],
        [2.0, 7.5, 5.0, 1.0, 1.5, 2.0]
    ].fuse;
    auto result = [2.44948974, 2.73861278, 2.73861278, 1.41421356, 2.29128784, 2.91547594];

    // Use byDim or alongDim with map to compute mean of row/column.
    assert(x.byDim!1.map!gmean.all!approxEqual(result));
    assert(x.alongDim!0.map!gmean.all!approxEqual(result));

    // FIXME
    // Without using map, computes the mean of the whole slice
    // assert(x.byDim!1.gmean.all!approxEqual(result));
    // assert(x.alongDim!0.gmean.all!approxEqual(result));
}

/// Can also set output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;

    auto x = [5120.0, 7340032, 32, 3758096384].sliced;

    assert(x.gmean!float.approxEqual(259281.45295212));

    auto y = uint.max.repeat(2);
    assert(y.gmean!float.approxEqual(cast(float) uint.max));
}

/++
For integral slices, pass output type as template parameter to ensure output
type is correct.
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [5, 1, 1, 2, 4, 4,
              2, 7, 5, 1, 2, 10].sliced;

    auto y = x.gmean;
    static assert(is(typeof(y) == double));
    
    assert(x.gmean!float.approxEqual(2.79160522));
}

/// gean works for user-defined types, provided the nth root can be taken for them
version(mir_stat_test)
@safe pure nothrow
unittest
{
    static struct Foo {
        float x;
        alias x this;
    }

    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [Foo(1.0), Foo(2.0), Foo(3.0)].sliced;
    assert(x.gmean.approxEqual(1.81712059));
}

/// Compute gmean tensors along specified dimention of tensors
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, iota, map;
    
    auto x = [
        [1.0, 2, 3],
        [4.0, 5, 6]
    ].fuse;

    assert(x.gmean.approxEqual(2.99379516));

    auto result0 = [2.0, 3.16227766, 4.24264069];
    assert(x.alongDim!0.map!gmean.all!approxEqual(result0));
    assert(x.alongDim!(-2).map!gmean.all!approxEqual(result0));

    auto result1 = [1.81712059, 4.93242414];
    assert(x.alongDim!1.map!gmean.all!approxEqual(result1));
    assert(x.alongDim!(-1).map!gmean.all!approxEqual(result1));

    auto y = [
        [
            [1.0, 2, 3],
            [4.0, 5, 6]
        ], [
            [7.0, 8, 9],
            [10.0, 9, 10]
        ]
    ].fuse;
    
    auto result3 = [
        [2.64575131, 4.0,        5.19615242],
        [6.32455532, 6.70820393, 7.74596669]
    ];
    assert(y.alongDim!0.map!gmean.all!approxEqual(result3));
}

/// Arbitrary gmean
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;

    assert(gmean(1.0, 2, 3).approxEqual(1.81712059));
    assert(gmean!float(1, 2, 3).approxEqual(1.81712059));
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    assert([1.0, 2, 3, 4].gmean.approxEqual(2.21336384));
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    assert(gmean([1, 2, 3]).approxEqual(1.81712059));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [3.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 2.0];

    assert(x.sliced.gmean.approxEqual(2.36178395));
    assert(x.sliced.gmean!float.approxEqual(2.36178395));
}

/++
Computes the median of `slice`.

By default, if `F` is not floating point type or complex type, then the result
will have a `double` type if `F` is implicitly convertible to a floating point 
type or a type for which `isComplex!F` is true.

Can also pass a boolean variable, `allowModify`, that allows the input slice to
be modified. By default, a reference-counted copy is made. 

Params:
    F = output type
    allowModify = Allows the input slice to be modified, default is false
Returns:
    the median of the slice

See_also: 
    $(LREF mean)
+/
template median(F, bool allowModify = false)
{
    import std.traits: Unqual;

    /++
    Params:
        slice = slice
    +/
    @nogc
    meanType!F median(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
    {
        static assert (!allowModify ||
                       isMutable!(slice.DeepElement),
                           "allowModify must be false or the input must be mutable");
        alias G = typeof(return);
        size_t len = slice.elementCount;
        assert(len > 0, "median: slice must have length greater than zero");

        import mir.ndslice.topology: as, flattened;

        static if (!allowModify) {
            import mir.ndslice.allocation: rcslice;
            
            if (len > 2) {
                auto view = slice.lightScope;
                auto val = view.as!(Unqual!(slice.DeepElement)).rcslice;
                auto temp = val.lightScope.flattened;
                return .median!(G, true)(temp);
            } else {
                return mean!G(slice);
            }
        } else {
            import mir.ndslice.sorting: partitionAt;
            
            auto temp = slice.flattened;

            if (len > 5) {
                size_t half_n = len / 2;
                partitionAt(temp, half_n);
                if (len % 2 == 1) {
                    return cast(G) temp[half_n];
                } else {
                    //move largest value in first half of slice to half_n - 1
                    partitionAt(temp[0 .. half_n], half_n - 1);
                    return (temp[half_n - 1] + temp[half_n]) / cast(G) 2;
                }
            } else {
                return smallMedianImpl!(G)(temp);
            }
        }
    }
}

/// ditto
template median(bool allowModify = false)
{
    import core.lifetime: move;
    import mir.primitives: DeepElementType;

    /// ditto
    meanType!(Slice!(Iterator, N, kind))
        median(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
    {
        static assert (!allowModify ||
                       isMutable!(DeepElementType!(Slice!(Iterator, N, kind))),
                           "allowModify must be false or the input must be mutable");
        alias F = typeof(return);
        return .median!(F, allowModify)(slice.move);
    }
}

/++
Params:
    ar = array
+/
meanType!(T[]) median(T)(scope const T[] ar...)
{
    import mir.ndslice.slice: sliced;

    alias F = typeof(return);
    return median!(F, false)(ar.sliced);
}

/++
Params:
    withAsSlice = input that satisfies hasAsSlice
+/
auto median(T)(T withAsSlice)
    if (hasAsSlice!T)
{
    return median(withAsSlice.asSlice);
}

/// Median of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;

    auto x0 = [9.0, 1, 0, 2, 3, 4, 6, 8, 7, 10, 5].sliced;
    assert(x0.median == 5);

    auto x1 = [9.0, 1, 0, 2, 3, 4, 6, 8, 7, 10].sliced;
    assert(x1.median == 5);
}

/// Median of dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    auto x0 = [9.0, 1, 0, 2, 3, 4, 6, 8, 7, 10, 5];
    assert(x0.median == 5);

    auto x1 = [9.0, 1, 0, 2, 3, 4, 6, 8, 7, 10];
    assert(x1.median == 5);
}

/// Median of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.ndslice.fuse: fuse;

    auto x0 = [
        [9.0, 1, 0, 2,  3], 
        [4.0, 6, 8, 7, 10]
    ].fuse;

    assert(x0.median == 5);
}

/// Row median of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: alongDim, byDim, map;

    auto x = [
        [0.0, 1.0, 1.5, 2.0, 3.5, 4.25], 
        [2.0, 7.5, 5.0, 1.0, 1.5, 0.0]
    ].fuse;

    auto result = [1.75, 1.75].sliced;

    // Use byDim or alongDim with map to compute median of row/column.
    assert(x.byDim!0.map!median.all!approxEqual(result));
    assert(x.alongDim!1.map!median.all!approxEqual(result));
}

/// Can allow original slice to be modified or set output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;

    auto x0 = [9.0, 1, 0, 2, 3, 4, 6, 8, 7, 10, 5].sliced;
    assert(x0.median!true == 5);
    
    auto x1 = [9, 1, 0, 2, 3, 4, 6, 8, 7, 10].sliced;
    assert(x1.median!(float, true) == 5);
}

/// Arbitrary median
version(mir_stat_test)
@safe pure nothrow
unittest
{
    assert(median(0, 1, 2, 3, 4) == 2);
}

// @nogc test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.ndslice.slice: sliced;

    static immutable x = [9.0, 1, 0, 2, 3];
    assert(x.sliced.median == 2);
}

// withAsSlice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    static immutable a = [9.0, 1, 0, 2, 3, 4, 6, 8, 7, 10, 5];

    auto x = RCArray!double(11);
    foreach(i, ref e; x)
        e = a[i];

    assert(x.median.approxEqual(5));
}

/++
For integral slices, can pass output type as template parameter to ensure output
type is correct
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;

    auto x = [9, 1, 0, 2, 3, 4, 6, 8, 7, 10].sliced;
    assert(x.median!float == 5f);

    auto y = x.median;
    assert(y == 5.0);
    static assert(is(typeof(y) == double));
}

// additional logic tests
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [3, 3, 2, 0, 2, 0].sliced;
    assert(x.median!float.approxEqual(2));

    x[] = [2, 2, 4, 0, 4, 3];
    assert(x.median!float.approxEqual(2.5));
    x[] = [1, 4, 5, 4, 4, 3];
    assert(x.median!float.approxEqual(4));
    x[] = [1, 5, 3, 5, 2, 2];
    assert(x.median!float.approxEqual(2.5));
    x[] = [4, 3, 2, 1, 4, 5];
    assert(x.median!float.approxEqual(3.5));
    x[] = [4, 5, 3, 5, 5, 4];
    assert(x.median!float.approxEqual(4.5));
    x[] = [3, 3, 3, 0, 0, 1];
    assert(x.median!float.approxEqual(2));
    x[] = [4, 2, 2, 1, 2, 5];
    assert(x.median!float.approxEqual(2));
    x[] = [2, 3, 1, 4, 5, 5];
    assert(x.median!float.approxEqual(3.5));
    x[] = [1, 1, 4, 5, 5, 5];
    assert(x.median!float.approxEqual(4.5));
    x[] = [2, 4, 0, 5, 1, 0];
    assert(x.median!float.approxEqual(1.5));
    x[] = [3, 5, 2, 5, 4, 2];
    assert(x.median!float.approxEqual(3.5));
    x[] = [3, 5, 4, 1, 4, 3];
    assert(x.median!float.approxEqual(3.5));
    x[] = [4, 2, 0, 3, 1, 3];
    assert(x.median!float.approxEqual(2.5));
    x[] = [100, 4, 5, 0, 5, 1];
    assert(x.median!float.approxEqual(4.5));
    x[] = [100, 5, 4, 0, 5, 1];
    assert(x.median!float.approxEqual(4.5));
    x[] = [100, 5, 4, 0, 1, 5];
    assert(x.median!float.approxEqual(4.5));
    x[] = [4, 5, 100, 1, 5, 0];
    assert(x.median!float.approxEqual(4.5));
    x[] = [0, 1, 2, 2, 3, 4];
    assert(x.median!float.approxEqual(2));
    x[] = [0, 2, 2, 3, 4, 5];
    assert(x.median!float.approxEqual(2.5));
}

// smallMedianImpl tests
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x0 = [9.0, 1, 0, 2, 3].sliced;
    assert(x0.median.approxEqual(2));

    auto x1 = [9.0, 1, 0, 2].sliced;
    assert(x1.median.approxEqual(1.5));
    
    auto x2 = [9.0, 0, 1].sliced;
    assert(x2.median.approxEqual(1));
    
    auto x3 = [1.0, 0].sliced;
    assert(x3.median.approxEqual(0.5));
    
    auto x4 = [1.0].sliced;
    assert(x4.median.approxEqual(1));
}

// Check issue #328 fixed
version(mir_stat_test)
@safe pure nothrow
unittest {
    import mir.ndslice.topology: iota;

    auto x = iota(18);
    auto y = median(x);
    assert(y == 8.5);
}

private pure @trusted nothrow @nogc
F smallMedianImpl(F, Iterator)(Slice!Iterator slice) 
{
    size_t n = slice.elementCount;

    assert(n > 0, "smallMedianImpl: slice must have elementCount greater than 0");
    assert(n <= 5, "smallMedianImpl: slice must have elementCount of 5 or less");

    import mir.functional: naryFun;
    import mir.ndslice.sorting: medianOf;
    import mir.utility: swapStars;

    auto sliceI0 = slice._iterator;
    
    if (n == 1) {
        return cast(F) *sliceI0;
    }

    auto sliceI1 = sliceI0;
    ++sliceI1;

    if (n > 2) {
        auto sliceI2 = sliceI1;
        ++sliceI2;
        alias less = naryFun!("a < b");

        if (n == 3) {
            medianOf!less(sliceI0, sliceI1, sliceI2);
            return cast(F) *sliceI1;
        } else {
            auto sliceI3 = sliceI2;
            ++sliceI3;
            if (n == 4) {
                // Put min in slice[0], lower median in slice[1]
                medianOf!less(sliceI0, sliceI1, sliceI2, sliceI3);
                // Ensure slice[2] < slice[3]
                medianOf!less(sliceI2, sliceI3);
                return cast(F) (*sliceI1 + *sliceI2) / cast(F) 2;
            } else {
                auto sliceI4 = sliceI3;
                ++sliceI4;
                medianOf!less(sliceI0, sliceI1, sliceI2, sliceI3, sliceI4);
                return cast(F) *sliceI2;
            }
        }
    } else {
        return cast(F) (*sliceI0 + *sliceI1) / cast(F) 2;
    }
}

// smallMedianImpl tests
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x0 = [9.0, 1, 0, 2, 3].sliced;
    assert(x0.smallMedianImpl!double.approxEqual(2));

    auto x1 = [9.0, 1, 0, 2].sliced;
    assert(x1.smallMedianImpl!double.approxEqual(1.5));

    auto x2 = [9.0, 0, 1].sliced;
    assert(x2.smallMedianImpl!double.approxEqual(1));

    auto x3 = [1.0, 0].sliced;
    assert(x3.smallMedianImpl!double.approxEqual(0.5));

    auto x4 = [1.0].sliced;
    assert(x4.smallMedianImpl!double.approxEqual(1));

    auto x5 = [2.0, 1, 0, 9].sliced;
    assert(x5.smallMedianImpl!double.approxEqual(1.5));

    auto x6 = [1.0, 2, 0, 9].sliced;
    assert(x6.smallMedianImpl!double.approxEqual(1.5));

    auto x7 = [1.0, 0, 9, 2].sliced;
    assert(x7.smallMedianImpl!double.approxEqual(1.5));
}

/++
Output range that applies function `fun` to each input before summing
+/
struct MapSummator(alias fun, T, Summation summation) 
    if(isMutable!T)
{
    ///
    Summator!(T, summation) summator;

    ///
    F sum(F = T)() const @property
    {
        return cast(F) summator.sum;
    }
    
    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        import mir.ndslice.topology: map;
        summator.put(r.map!fun);
    }

    ///
    void put()(T x)
    {
        summator.put(fun(x));
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: powi;
    import mir.ndslice.slice: sliced;

    alias f = (double x) => (powi(x, 2));
    MapSummator!(f, double, Summation.pairwise) x;
    x.put([0.0, 1, 2, 3, 4].sliced);
    assert(x.sum == 30.0);
    x.put(5);
    assert(x.sum == 55.0);
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;

    alias f = (double x) => (x + 1);
    MapSummator!(f, double, Summation.pairwise) x;
    x.put([0.0, 1, 2, 3, 4].sliced);
    assert(x.sum == 15.0);
    x.put(5);
    assert(x.sum == 21.0);
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.ndslice.slice: sliced;

    alias f = (double x) => (x + 1);
    MapSummator!(f, double, Summation.pairwise) x;
    static immutable a = [0.0, 1, 2, 3, 4];
    x.put(a.sliced);
    assert(x.sum == 15.0);
    x.put(5);
    assert(x.sum == 21.0);
}

version(mir_stat_test)
@safe pure
unittest
{
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.slice: sliced;

    alias f = (double x) => (x + 1);
    MapSummator!(f, double, Summation.pairwise) x;
    auto a = [
        [0.0, 1, 2],
        [3.0, 4, 5]
    ].fuse;
    auto b = [6.0, 7, 8].sliced;
    x.put(a);
    assert(x.sum == 21.0);
    x.put(b);
    assert(x.sum == 45.0);
}

/++
Variance algorithms.

See Also:
    $(WEB en.wikipedia.org/wiki/Algorithms_for_calculating_variance, Algorithms for calculating variance).
+/
enum VarianceAlgo
{
    /++
    Performs Welford's online algorithm for updating variance. Can also `put`
    another VarianceAccumulator of different types, which uses the parallel
    algorithm from Chan et al., described above.
    +/
    online,
    
    /++
    Calculates variance using E(x^^2) - E(x)^2 (alowing for adjustments for 
    population/sample variance). This algorithm can be numerically unstable. As
    in: 
    E(x ^^ 2) - E(x) ^^ 2
    +/
    naive,

    /++
    Calculates variance using a two-pass algorithm whereby the input is first 
    centered and then the sum of squares is calculated from that. As in:
    E((x - E(x)) ^^ 2)
    +/
    twoPass,

    /++
    Calculates variance assuming the mean of the dataseries is zero. 
    +/
    assumeZeroMean,
    
    /++
    When slices, slice-like objects, or ranges are the inputs, uses the two-pass
    algorithm. When an individual data-point is added, uses the online algorithm.
    +/
    hybrid
}

///
struct VarianceAccumulator(T, VarianceAlgo varianceAlgo, Summation summation)
    if (isMutable!T && varianceAlgo == VarianceAlgo.naive)
{
    import mir.math.sum: Summator;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;

    ///
    private Summator!(T, summation) summatorOfSquares;

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
        summatorOfSquares.put(x * x);
    }

    ///
    void put(U, Summation sumAlgo)(VarianceAccumulator!(U, varianceAlgo, sumAlgo) v)
    {
        meanAccumulator.put(v.meanAccumulator);
        summatorOfSquares.put(v.sumOfSquares!T);
    }

const:

    ///
    size_t count() @property
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)() const @property
    {
        return meanAccumulator.mean!F;
    }
    ///
    F sumOfSquares(F = T)()
    {
        return cast(F) summatorOfSquares.sum;
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return sumOfSquares!F - count * mean!F * mean!F;
    }
    ///
    F variance(F = T)(bool isPopulation) @property
    in
    {
        assert(count > 1, "VarianceAccumulator.varaince: count must be larger than one");
    }
    do
    {
        return sumOfSquares!F / (count + isPopulation - 1) - 
            mean!F * mean!F * count / (count + isPopulation - 1);
    }
}

/// naive
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    VarianceAccumulator!(double, VarianceAlgo.naive, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));

    v.put(4.0);
    assert(v.variance(true).approxEqual(57.01923 / 13));
    assert(v.variance(false).approxEqual(57.01923 / 12));
}

// Can put VarianceAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    VarianceAccumulator!(double, VarianceAlgo.naive, Summation.naive) v;
    v.put(x);
    VarianceAccumulator!(double, VarianceAlgo.naive, Summation.naive) w;
    w.put(y);
    v.put(w);
    v.variance(true).shouldApprox == 54.76562 / 12;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.range: iota;
    import std.algorithm: map;

    auto x1 = iota(0, 5);
    auto v1 = VarianceAccumulator!(double, VarianceAlgo.naive, Summation.naive)(x1);
    v1.variance(true).should == 2;
    v1.centeredSumOfSquares.should == 10;
    auto x2 = x1.map!(a => 2 * a);
    auto v2 = VarianceAccumulator!(double, VarianceAlgo.naive, Summation.naive)(x2);
    v2.variance(true).should == 8;
}

///
struct VarianceAccumulator(T, VarianceAlgo varianceAlgo, Summation summation)
    if (isMutable!T && varianceAlgo == VarianceAlgo.online)
{
    import mir.math.sum: Summator;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;

    ///
    private Summator!(T, summation) centeredSummatorOfSquares;

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
        T delta = x;
        if (count > 0) {
            delta -= meanAccumulator.mean;
        }
        meanAccumulator.put(x);
        centeredSummatorOfSquares.put(delta * (x - meanAccumulator.mean));
    }

    ///
    void put(U, VarianceAlgo varAlgo, Summation sumAlgo)(VarianceAccumulator!(U, varAlgo, sumAlgo) v)
        if(!is(varAlgo == VarianceAlgo.assumeZeroMean))
    {
        size_t oldCount = count;
        T delta = v.mean!T;
        if (oldCount > 0) {
            delta -= meanAccumulator.mean;
        }
        meanAccumulator.put!T(v.meanAccumulator);
        centeredSummatorOfSquares.put(v.centeredSumOfSquares!T + delta * delta * v.count * oldCount / count);
    }

const:

    ///
    size_t count() @property
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)() const @property
    {
        return meanAccumulator.mean!F;
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F variance(F = T)(bool isPopulation) @property
    in
    {
        assert(count > 1, "VarianceAccumulator.variance: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
}

/// online
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    VarianceAccumulator!(double, VarianceAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));

    v.put(4.0);
    assert(v.variance(true).approxEqual(57.01923 / 13));
    assert(v.variance(false).approxEqual(57.01923 / 12));
}

// can put slices
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    VarianceAccumulator!(double, VarianceAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(12.55208 / 6));
    assert(v.variance(false).approxEqual(12.55208 / 5));

    v.put(y);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// Can put accumulator (online)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    VarianceAccumulator!(double, VarianceAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(12.55208 / 6));
    assert(v.variance(false).approxEqual(12.55208 / 5));

    VarianceAccumulator!(double, VarianceAlgo.online, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// Can put accumulator (naive)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    VarianceAccumulator!(double, VarianceAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(12.55208 / 6));
    assert(v.variance(false).approxEqual(12.55208 / 5));

    VarianceAccumulator!(double, VarianceAlgo.naive, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// Can put accumulator (twoPass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    VarianceAccumulator!(double, VarianceAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(12.55208 / 6));
    assert(v.variance(false).approxEqual(12.55208 / 5));

    auto w = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(y);
    v.put(w);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// complex
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex.math: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.complex: Complex;

    auto x = [Complex!double(1.0, 3), Complex!double(2), Complex!double(3)].sliced;

    VarianceAccumulator!(Complex!double, VarianceAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(Complex!double(-4.0, -6) / 3));
    assert(v.variance(false).approxEqual(Complex!double(-4.0, -6) / 2));
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.range: iota;
    import std.algorithm: map;

    auto x1 = iota(0, 5);
    auto v1 = VarianceAccumulator!(double, VarianceAlgo.online, Summation.naive)(x1);
    v1.variance(true).should == 2;
    v1.centeredSumOfSquares.should == 10;
    auto x2 = x1.map!(a => 2 * a);
    auto v2 = VarianceAccumulator!(double, VarianceAlgo.online, Summation.naive)(x2);
    v2.variance(true).should == 8;
}

///
struct VarianceAccumulator(T, VarianceAlgo varianceAlgo, Summation summation)
    if (isMutable!T && varianceAlgo == VarianceAlgo.twoPass)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import std.range: isInputRange;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;

    ///
    private Summator!(T, summation) centeredSummatorOfSquares;

    ///
    this(Iterator, size_t N, SliceKind kind)(
         Slice!(Iterator, N, kind) slice)
    {
        import mir.functional: naryFun;
        import mir.ndslice.internal: LeftOp;
        import mir.ndslice.topology: vmap, map;

        meanAccumulator.put(slice.lightScope);
        centeredSummatorOfSquares.put(slice.vmap(LeftOp!("-", T)(meanAccumulator.mean)).map!(naryFun!"a * a"));
    }

    ///
    this(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice);
    }

    ///
    this(Range)(Range range)
        if (isInputRange!Range && !isConvertibleToSlice!Range && is(elementType!Range : T))
    {
        import std.algorithm: map;
        meanAccumulator.put(range);

        auto centeredRangeMultiplier = range.map!(a => (a - mean)).map!("a * a");
        centeredSummatorOfSquares.put(centeredRangeMultiplier);
    }

const:

    ///
    size_t count() @property
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)() const @property
    {
        return meanAccumulator.mean;
    }
    ///
    F centeredSumOfSquares(F = T)() const @property
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F variance(F = T)(bool isPopulation) @property
    in
    {
        assert(count > 1, "SkewnessAccumulator.variance: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
}

/// twoPass
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(x);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// dynamic array test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    double[] x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                  2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto v = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(x);
    assert(v.centeredSumOfSquares.approxEqual(54.76562));
}

// withAsSlice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.math.sum: sum;
    import mir.rc.array: RCArray;

    static immutable a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];

    auto v = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(x);
    assert(v.centeredSumOfSquares.sum.approxEqual(54.76562));
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.range: iota;
    import std.algorithm: map;

    auto x1 = iota(0, 5);
    auto v1 = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(x1);
    v1.variance(true).should == 2;
    v1.centeredSumOfSquares.should == 10;
    auto x2 = x1.map!(a => 2 * a);
    auto v2 = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(x2);
    v2.variance(true).should == 8;
}

///
struct VarianceAccumulator(T, VarianceAlgo varianceAlgo, Summation summation)
    if (isMutable!T && varianceAlgo == VarianceAlgo.assumeZeroMean)
{
    import mir.math.sum: Summator;
    import mir.ndslice.slice: Slice, SliceKind, hasAsSlice;

    private size_t _count;
    ///
    private Summator!(T, summation) centeredSummatorOfSquares;

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
        _count++;
        centeredSummatorOfSquares.put(x * x);
    }

    ///
    void put(U, Summation sumAlgo)(VarianceAccumulator!(U, varianceAlgo, sumAlgo) v)
    {
        _count += v.count;
        centeredSummatorOfSquares.put(v.centeredSumOfSquares!T);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F mean(F = T)() const @property
    {
        return cast(F) 0;
    }
    ///
    MeanAccumulator!(T, summation) meanAccumulator()()
    {
        typeof(return) m = { _count, T(0) };
        return m;
    }
    ///
    F centeredSumOfSquares(F = T)() const @property
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F variance(F = T)(bool isPopulation) @property
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
}

/// assumeZeroMean
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.stat.transform: center;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;

    VarianceAccumulator!(double, VarianceAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
    v.put(4.0);
    assert(v.variance(true).approxEqual(70.76562 / 13));
    assert(v.variance(false).approxEqual(70.76562 / 12));
}

// can put slices
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.stat.transform: center;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = a.center;
    auto x = b[0 .. 6];
    auto y = b[6 .. $];

    VarianceAccumulator!(double, VarianceAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(13.492188 / 6));
    assert(v.variance(false).approxEqual(13.492188 / 5));

    v.put(y);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// can put two accumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.stat.transform: center;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = a.center;
    auto x = b[0 .. 6];
    auto y = b[6 .. $];

    VarianceAccumulator!(double, VarianceAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(13.492188 / 6));
    assert(v.variance(false).approxEqual(13.492188 / 5));

    VarianceAccumulator!(double, VarianceAlgo.assumeZeroMean, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// complex
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex: Complex;
    import mir.complex.math: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [Complex!double(1.0, 3), Complex!double(2), Complex!double(3)].sliced;
    auto x = a.center;

    VarianceAccumulator!(Complex!double, VarianceAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(Complex!double(-4.0, -6) / 3));
    assert(v.variance(false).approxEqual(Complex!double(-4.0, -6) / 2));
}

///
struct VarianceAccumulator(T, VarianceAlgo varianceAlgo, Summation summation)
    if (isMutable!T && varianceAlgo == VarianceAlgo.hybrid)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import std.range: isInputRange;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;

    ///
    private Summator!(T, summation) centeredSummatorOfSquares;

    ///
    this(Iterator, size_t N, SliceKind kind)(
         Slice!(Iterator, N, kind) slice)
    {
        import mir.functional: naryFun;
        import mir.ndslice.internal: LeftOp;
        import mir.ndslice.topology: vmap, map;

        meanAccumulator.put(slice.lightScope);
        centeredSummatorOfSquares.put(slice.vmap(LeftOp!("-", T)(meanAccumulator.mean)).map!(naryFun!"a * a"));
    }

    ///
    this(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice);
    }

    ///
    this(Range)(Range range)
        if (isIterable!Range && !isConvertibleToSlice!Range)
    {
        static if (isInputRange!Range && is(elementType!Range : T))
        {
            import std.algorithm: map;
            meanAccumulator.put(range);

            auto centeredRangeMultiplier = range.map!(a => (a - mean)).map!("a * a");
            centeredSummatorOfSquares.put(centeredRangeMultiplier);
        } else {
            this.put(range);
        }
    }

    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        static if (isInputRange!Range && is(elementType!Range : T)) {
            auto v = typeof(this)(r);
            this.put(v);
        } else{
            foreach(x; r)
            {
                this.put(x);
            }
        }
    }

    ///
    void put()(T x)
    {
        T delta = x;
        if (count > 0) {
            delta -= meanAccumulator.mean;
        }
        meanAccumulator.put(x);
        centeredSummatorOfSquares.put(delta * (x - meanAccumulator.mean));
    }

    ///
    void put(U, VarianceAlgo varAlgo, Summation sumAlgo)(VarianceAccumulator!(U, varAlgo, sumAlgo) v)
        if(!is(varAlgo == VarianceAlgo.assumeZeroMean))
    {
        size_t oldCount = count;
        T delta = v.mean!T;
        if (oldCount > 0) {
            delta -= meanAccumulator.mean;
        }
        meanAccumulator.put!T(v.meanAccumulator);
        centeredSummatorOfSquares.put(v.centeredSumOfSquares!T + delta * delta * v.count * oldCount / count);
    }

const:

    ///
    size_t count() @property
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)() const @property
    {
        return meanAccumulator.mean!F;
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F variance(F = T)(bool isPopulation) @property
    in
    {
        assert(count > 1, "VarianceAccumulator.variance: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
}

/// online
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = VarianceAccumulator!(double, VarianceAlgo.hybrid, Summation.naive)(x);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));

    v.put(4.0);
    assert(v.variance(true).approxEqual(57.01923 / 13));
    assert(v.variance(false).approxEqual(57.01923 / 12));
}

// can put slices
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = VarianceAccumulator!(double, VarianceAlgo.hybrid, Summation.naive)(x);
    assert(v.variance(true).approxEqual(12.55208 / 6));
    assert(v.variance(false).approxEqual(12.55208 / 5));

    v.put(y);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// Can put accumulator (hybrid)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    VarianceAccumulator!(double, VarianceAlgo.hybrid, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(12.55208 / 6));
    assert(v.variance(false).approxEqual(12.55208 / 5));

    VarianceAccumulator!(double, VarianceAlgo.hybrid, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// Can put accumulator (naive)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    VarianceAccumulator!(double, VarianceAlgo.hybrid, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(12.55208 / 6));
    assert(v.variance(false).approxEqual(12.55208 / 5));

    VarianceAccumulator!(double, VarianceAlgo.naive, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// Can put accumulator (online)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    VarianceAccumulator!(double, VarianceAlgo.hybrid, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(12.55208 / 6));
    assert(v.variance(false).approxEqual(12.55208 / 5));

    VarianceAccumulator!(double, VarianceAlgo.online, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// Can put accumulator (twoPass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    VarianceAccumulator!(double, VarianceAlgo.hybrid, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(12.55208 / 6));
    assert(v.variance(false).approxEqual(12.55208 / 5));

    auto w = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(y);
    v.put(w);
    assert(v.variance(true).approxEqual(54.76562 / 12));
    assert(v.variance(false).approxEqual(54.76562 / 11));
}

// complex
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex.math: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.complex: Complex;

    auto x = [Complex!double(1.0, 3), Complex!double(2), Complex!double(3)].sliced;

    VarianceAccumulator!(Complex!double, VarianceAlgo.hybrid, Summation.naive) v;
    v.put(x);
    assert(v.variance(true).approxEqual(Complex!double(-4.0, -6) / 3));
    assert(v.variance(false).approxEqual(Complex!double(-4.0, -6) / 2));
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.range: chunks, iota;
    import std.algorithm: map;

    auto x1 = iota(0, 5);
    auto v1 = VarianceAccumulator!(double, VarianceAlgo.hybrid, Summation.naive)(x1);
    v1.variance(true).should == 2;
    v1.centeredSumOfSquares.should == 10;
    auto x2 = x1.map!(a => 2 * a);
    auto v2 = VarianceAccumulator!(double, VarianceAlgo.hybrid, Summation.naive)(x2);
    v2.variance(true).should == 8;
    VarianceAccumulator!(double, VarianceAlgo.hybrid, Summation.naive) v3;
    v3.put(x1.chunks(1));
    v3.centeredSumOfSquares.should == 10;
    auto v4 = VarianceAccumulator!(double, VarianceAlgo.hybrid, Summation.naive)(x1.chunks(1));
    v4.centeredSumOfSquares.should == 10;
}

/++
Calculates the variance of the input

By default, if `F` is not floating point type or complex type, then the result
will have a `double` type if `F` is implicitly convertible to a floating point 
type or a type for which `isComplex!F` is true.

Params:
    F = controls type of output
    varianceAlgo = algorithm for calculating variance (default: VarianceAlgo.hybrid)
    summation = algorithm for calculating sums (default: Summation.appropriate)
Returns:
    The variance of the input, must be floating point or complex type
+/
template variance(
    F, 
    VarianceAlgo varianceAlgo = VarianceAlgo.hybrid, 
    Summation summation = Summation.appropriate)
{
    /++
    Params:
        r = range, must be finite iterable
        isPopulation = true if population variance, false if sample variance (default)
    +/
    @fmamath meanType!F variance(Range)(Range r, bool isPopulation = false)
        if (isIterable!Range)
    {
        import core.lifetime: move;

        alias G = typeof(return);
        auto varianceAccumulator = VarianceAccumulator!(G, varianceAlgo, ResolveSummationType!(summation, Range, G))(r.move);
        return varianceAccumulator.variance(isPopulation);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath meanType!F variance(scope const F[] ar...)
    {
        alias G = typeof(return);
        auto varianceAccumulator = VarianceAccumulator!(G, varianceAlgo, ResolveSummationType!(summation, const(G)[], G))(ar);
        return varianceAccumulator.variance(false);
    }
}

/// ditto
template variance(
    VarianceAlgo varianceAlgo = VarianceAlgo.hybrid, 
    Summation summation = Summation.appropriate)
{
    /++
    Params:
        r = range, must be finite iterable
        isPopulation = true if population variance, false if sample variance (default)
    +/
    @fmamath meanType!Range variance(Range)(Range r, bool isPopulation = false)
        if(isIterable!Range)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .variance!(F, varianceAlgo, summation)(r.move, isPopulation);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath meanType!T variance(T)(scope const T[] ar...)
    {
        alias F = typeof(return);
        return .variance!(F, varianceAlgo, summation)(ar);
    }
}

/// ditto
template variance(F, string varianceAlgo, string summation = "appropriate")
{
    mixin("alias variance = .variance!(F, VarianceAlgo." ~ varianceAlgo ~ ", Summation." ~ summation ~ ");");
}

/// ditto
template variance(string varianceAlgo, string summation = "appropriate")
{
    mixin("alias variance = .variance!(VarianceAlgo." ~ varianceAlgo ~ ", Summation." ~ summation ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.complex.math: capproxEqual = approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.complex;
    alias C = Complex!double;

    assert(variance([1.0, 2, 3]).approxEqual(2.0 / 2));
    assert(variance([1.0, 2, 3], true).approxEqual(2.0 / 3));

    assert(variance([C(1, 3), C(2), C(3)]).capproxEqual(C(-4, -6) / 2));
    
    assert(variance!float([0, 1, 2, 3, 4, 5].sliced(3, 2)).approxEqual(17.5 / 5));
    
    static assert(is(typeof(variance!float([1, 2, 3])) == float));
}

/// Variance of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.variance.approxEqual(54.76562 / 11));
}

/// Variance of matrix
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

    assert(x.variance.approxEqual(54.76562 / 11));
}

/// Column variance of matrix
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
    auto result = [13.16667 / 2, 7.041667 / 2, 0.1666667 / 2, 30.16667 / 2];

    // Use byDim or alongDim with map to compute variance of row/column.
    assert(x.byDim!1.map!variance.all!approxEqual(result));
    assert(x.alongDim!0.map!variance.all!approxEqual(result));

    // FIXME
    // Without using map, computes the variance of the whole slice
    // assert(x.byDim!1.variance == x.sliced.variance);
    // assert(x.alongDim!0.variance == x.sliced.variance);
}

/// Can also set algorithm type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto x = a + 1_000_000_000;

    auto y = x.variance;
    assert(y.approxEqual(54.76562 / 11));

    // The naive algorithm is numerically unstable in this case
    auto z0 = x.variance!"naive";
    assert(!z0.approxEqual(y));
    
    auto z1 = x.variance!"online";
    assert(z1.approxEqual(54.76562 / 11));

    // But the two-pass algorithm provides a consistent answer
    auto z2 = x.variance!"twoPass";
    assert(z2.approxEqual(y));

    // And the assumeZeroMean algorithm is way off
    auto z3 = x.variance!"assumeZeroMean";
    assert(z3.approxEqual(1.2e19 / 11));
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;

    //Set population variance, variance algorithm, sum algorithm or output type

    auto a = [1.0, 1e100, 1, -1e100].sliced;
    auto x = a * 10_000;

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean 
    from the second and fourth numbers has no effect. Further, after centering 
    and squaring `x`, the first and third numbers in the slice have precision 
    too low to be included in the centered sum of squares. 
    +/
    assert(x.variance(false).approxEqual(2.0e208 / 3));
    assert(x.variance(true).approxEqual(2.0e208 / 4));

    assert(x.variance!("online").approxEqual(2.0e208 / 3));
    assert(x.variance!("online", "kbn").approxEqual(2.0e208 / 3));
    assert(x.variance!("online", "kb2").approxEqual(2.0e208 / 3));
    assert(x.variance!("online", "precise").approxEqual(2.0e208 / 3));
    assert(x.variance!(double, "online", "precise").approxEqual(2.0e208 / 3));
    assert(x.variance!(double, "online", "precise")(true).approxEqual(2.0e208 / 4));

    auto y = uint.max.repeat(3);
    auto z = y.variance!ulong;
    assert(z == 0.0);
    static assert(is(typeof(z) == double));
}

/++
For integral slices, pass output type as template parameter to ensure output
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

    auto y = x.variance;
    assert(y.approxEqual(50.91667 / 11));
    static assert(is(typeof(y) == double));

    assert(x.variance!float.approxEqual(50.91667 / 11));
}

/++
Variance works for complex numbers and other user-defined types (provided they
can be converted to a floating point or complex type)
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex.math: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.complex;
    alias C = Complex!double;

    auto x = [C(1, 2), C(2, 3), C(3, 4), C(4, 5)].sliced;
    assert(x.variance.approxEqual((C(0, 10)) / 3));
}

/// Compute variance along specified dimention of tensors
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

    assert(x.variance.approxEqual(17.5 / 5));

    auto m0 = [4.5, 4.5, 4.5];
    assert(x.alongDim!0.map!variance.all!approxEqual(m0));
    assert(x.alongDim!(-2).map!variance.all!approxEqual(m0));

    auto m1 = [1.0, 1.0];
    assert(x.alongDim!1.map!variance.all!approxEqual(m1));
    assert(x.alongDim!(-1).map!variance.all!approxEqual(m1));

    assert(iota(2, 3, 4, 5).as!double.alongDim!0.map!variance.all!approxEqual(repeat(3600.0 / 2, 3, 4, 5)));
}

/// Arbitrary variance
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    assert(variance(1.0, 2, 3) == 1.0);
    assert(variance!float(1, 2, 3) == 1f);
}

// UCFS test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    assert([1.0, 2, 3, 4].variance.approxEqual(5.0 / 3));
}

// testing types are right along dimension
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: iota, alongDim, map;

    auto x = iota([2, 2], 1);
    auto y = x.alongDim!1.map!variance;
    assert(y.all!approxEqual([0.5, 0.5]));
    static assert(is(meanType!(typeof(y)) == double));
}

// @nogc test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.variance.approxEqual(54.76562 / 11));
    assert(x.sliced.variance!float.approxEqual(54.76562 / 11));
}

///
package(mir)
template stdevType(T)
{
    import mir.internal.utility: isFloatingPoint;
    
    alias U = meanType!T;

    static if (isFloatingPoint!U) {
        alias stdevType = U;
    } else {
        static assert(0, "stdevType: Can't calculate standard deviation of elements of type " ~ U.stringof);
    }
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static assert(is(stdevType!(int[]) == double));
    static assert(is(stdevType!(double[]) == double));
    static assert(is(stdevType!(float[]) == float));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static struct Foo {
        float x;
        alias x this;
    }

    static assert(is(stdevType!(Foo[]) == float));
}

/++
Calculates the standard deviation of the input

By default, if `F` is not floating point type, then the result will have a
`double` type if `F` is implicitly convertible to a floating point type.

Params:
    F = controls type of output
    varianceAlgo = algorithm for calculating variance (default: VarianceAlgo.hybrid)
    summation = algorithm for calculating sums (default: Summation.appropriate)
Returns:
    The standard deviation of the input, must be floating point type type
+/
template standardDeviation(
    F, 
    VarianceAlgo varianceAlgo = VarianceAlgo.hybrid, 
    Summation summation = Summation.appropriate)
{
    import mir.math.common: sqrt;

    /++
    Params:
        r = range, must be finite iterable
        isPopulation = true if population standard deviation, false if sample standard deviation (default)
    +/
    @fmamath stdevType!F standardDeviation(Range)(Range r, bool isPopulation = false)
        if (isIterable!Range)
    {
        import core.lifetime: move;
        alias G = typeof(return);
        return r.move.variance!(G, varianceAlgo, ResolveSummationType!(summation, Range, G))(isPopulation).sqrt;
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!F standardDeviation(scope const F[] ar...)
    {
        alias G = typeof(return);
        return ar.variance!(G, varianceAlgo, ResolveSummationType!(summation, const(G)[], G)).sqrt;
    }
}

/// ditto
template standardDeviation(
    VarianceAlgo varianceAlgo = VarianceAlgo.hybrid, 
    Summation summation = Summation.appropriate)
{
    /++
    Params:
        r = range, must be finite iterable
        isPopulation = true if population standard deviation, false if sample standard deviation (default)
    +/
    @fmamath stdevType!Range standardDeviation(Range)(Range r, bool isPopulation = false)
        if(isIterable!Range)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .standardDeviation!(F, varianceAlgo, summation)(r.move, isPopulation);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!T standardDeviation(T)(scope const T[] ar...)
    {
        alias F = typeof(return);
        return .standardDeviation!(F, varianceAlgo, summation)(ar);
    }
}

/// ditto
template standardDeviation(F, string varianceAlgo, string summation = "appropriate")
{
    mixin("alias standardDeviation = .standardDeviation!(F, VarianceAlgo." ~ varianceAlgo ~ ", Summation." ~ summation ~ ");");
}

/// ditto
template standardDeviation(string varianceAlgo, string summation = "appropriate")
{
    mixin("alias standardDeviation = .standardDeviation!(VarianceAlgo." ~ varianceAlgo ~ ", Summation." ~ summation ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.slice: sliced;

    assert(standardDeviation([1.0, 2, 3]).approxEqual(sqrt(2.0 / 2)));
    assert(standardDeviation([1.0, 2, 3], true).approxEqual(sqrt(2.0 / 3)));
    
    assert(standardDeviation!float([0, 1, 2, 3, 4, 5].sliced(3, 2)).approxEqual(sqrt(17.5 / 5)));
    
    static assert(is(typeof(standardDeviation!float([1, 2, 3])) == float));
}

/// Standard deviation of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.standardDeviation.approxEqual(sqrt(54.76562 / 11)));
}

/// Standard deviation of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.fuse: fuse;

    auto x = [
        [0.0, 1.0, 1.5, 2.0, 3.5, 4.25],
        [2.0, 7.5, 5.0, 1.0, 1.5, 0.0]
    ].fuse;

    assert(x.standardDeviation.approxEqual(sqrt(54.76562 / 11)));
}

/// Column standard deviation of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: alongDim, byDim, map;

    auto x = [
        [0.0,  1.0, 1.5, 2.0], 
        [3.5, 4.25, 2.0, 7.5],
        [5.0,  1.0, 1.5, 0.0]
    ].fuse;
    auto result = [13.16667 / 2, 7.041667 / 2, 0.1666667 / 2, 30.16667 / 2].map!sqrt;

    // Use byDim or alongDim with map to compute standardDeviation of row/column.
    assert(x.byDim!1.map!standardDeviation.all!approxEqual(result));
    assert(x.alongDim!0.map!standardDeviation.all!approxEqual(result));

    // FIXME
    // Without using map, computes the standardDeviation of the whole slice
    // assert(x.byDim!1.standardDeviation == x.sliced.standardDeviation);
    // assert(x.alongDim!0.standardDeviation == x.sliced.standardDeviation);
}

/// Can also set algorithm type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto x = a + 1_000_000_000;

    auto y = x.standardDeviation;
    assert(y.approxEqual(sqrt(54.76562 / 11)));

    // The naive algorithm is numerically unstable in this case
    auto z0 = x.standardDeviation!"naive";
    assert(!z0.approxEqual(y));

    // But the two-pass algorithm provides a consistent answer
    auto z1 = x.standardDeviation!"twoPass";
    assert(z1.approxEqual(y));
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;

    //Set population standard deviation, standardDeviation algorithm, sum algorithm or output type

    auto a = [1.0, 1e100, 1, -1e100].sliced;
    auto x = a * 10_000;

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean 
    from the second and fourth numbers has no effect. Further, after centering 
    and squaring `x`, the first and third numbers in the slice have precision 
    too low to be included in the centered sum of squares. 
    +/
    assert(x.standardDeviation(false).approxEqual(sqrt(2.0e208 / 3)));
    assert(x.standardDeviation(true).approxEqual(sqrt(2.0e208 / 4)));

    assert(x.standardDeviation!("online").approxEqual(sqrt(2.0e208 / 3)));
    assert(x.standardDeviation!("online", "kbn").approxEqual(sqrt(2.0e208 / 3)));
    assert(x.standardDeviation!("online", "kb2").approxEqual(sqrt(2.0e208 / 3)));
    assert(x.standardDeviation!("online", "precise").approxEqual(sqrt(2.0e208 / 3)));
    assert(x.standardDeviation!(double, "online", "precise").approxEqual(sqrt(2.0e208 / 3)));
    assert(x.standardDeviation!(double, "online", "precise")(true).approxEqual(sqrt(2.0e208 / 4)));

    auto y = uint.max.repeat(3);
    auto z = y.standardDeviation!ulong;
    assert(z == 0.0);
    static assert(is(typeof(z) == double));
}

/++
For integral slices, pass output type as template parameter to ensure output
type is correct.
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.slice: sliced;

    auto x = [0, 1, 1, 2, 4, 4,
              2, 7, 5, 1, 2, 0].sliced;

    auto y = x.standardDeviation;
    assert(y.approxEqual(sqrt(50.91667 / 11)));
    static assert(is(typeof(y) == double));

    assert(x.standardDeviation!float.approxEqual(sqrt(50.91667 / 11)));
}

/++
Variance works for other user-defined types (provided they
can be converted to a floating point)
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    
    static struct Foo {
        float x;
        alias x this;
    }
    
    Foo[] foo = [Foo(1f), Foo(2f), Foo(3f)];
    assert(foo.standardDeviation == 1f);
}

/// Compute standard deviation along specified dimention of tensors
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: as, iota, alongDim, map, repeat;

    auto x = [
        [0.0, 1, 2],
        [3.0, 4, 5]
    ].fuse;

    assert(x.standardDeviation.approxEqual(sqrt(17.5 / 5)));

    auto m0 = repeat(sqrt(4.5), 3);
    assert(x.alongDim!0.map!standardDeviation.all!approxEqual(m0));
    assert(x.alongDim!(-2).map!standardDeviation.all!approxEqual(m0));

    auto m1 = [1.0, 1.0];
    assert(x.alongDim!1.map!standardDeviation.all!approxEqual(m1));
    assert(x.alongDim!(-1).map!standardDeviation.all!approxEqual(m1));

    assert(iota(2, 3, 4, 5).as!double.alongDim!0.map!standardDeviation.all!approxEqual(repeat(sqrt(3600.0 / 2), 3, 4, 5)));
}

/// Arbitrary standard deviation
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: sqrt;

    assert(standardDeviation(1.0, 2, 3) == 1.0);
    assert(standardDeviation!float(1, 2, 3) == 1f);
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    assert([1.0, 2, 3, 4].standardDeviation.approxEqual(sqrt(5.0 / 3)));
}

version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.topology: iota, alongDim, map;

    auto x = iota([2, 2], 1);
    auto y = x.alongDim!1.map!standardDeviation;
    assert(y.all!approxEqual([sqrt(0.5), sqrt(0.5)]));
    static assert(is(meanType!(typeof(y)) == double));
}

version(mir_stat_test)
@safe pure @nogc nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.standardDeviation.approxEqual(sqrt(54.76562 / 11)));
    assert(x.sliced.standardDeviation!float.approxEqual(sqrt(54.76562 / 11)));
}

/++
Algorithms used to calculate the quantile of an input `x` at probability `p`.

These algorithms match the same provided in R's (as of version 3.6.2) `quantile`
function. In turn, these were discussed in Hyndman and Fan (1996). 

All sample quantiles are defined as weighted averages of consecutive order
statistics. For each `quantileAlgo`, the sample quantile is given by
(using R's 1-based indexing notation):

    (1 - `gamma`) * `x$(SUBSCRIPT j)` + `gamma` * `x$(SUBSCRIPT j + 1)`


where `x$(SUBSCRIPT j)` is the `j`th order statistic. `gamma` is a function of
`j = floor(np + m)` and `g = np + m - j` where `n` is the sample size, `p` is
the probability, and `m` is a constant determined by the quantile type.

$(BOOKTABLE ,
    $(TR
        $(TH Type)
        $(TH m)
        $(TH gamma)
    )
    $(LEADINGROWN 3, Discontinuous sample quantile)
    $(T3 type1, 0, 0 if `g = 0` and 1 otherwise.)
    $(T3 type2, 0, 0.5 if `g = 0` and 1 otherwise.)
    $(T3 type3, -0.5, 0 if `g = 0` and `j` is even and 1 otherwise.)
    $(LEADINGROWN 3, Continuous sample quantile)
    $(T3 type4, 0, `gamma = g`)
    $(T3 type5, 0.5, `gamma = g`)
    $(T3 type6, `p`, `gamma = g`)
    $(T3 type7, `1 - p`, `gamma = g`)
    $(T3 type8, `(p + 1) / 3`, `gamma = g`)
    $(T3 type9, `p / 4 + 3 / 8`, `gamma = g`)
)

References:
    Hyndman, R. J. and Fan, Y. (1996) Sample quantiles in statistical packages, American Statistician 50, 361--365. 10.2307/2684934.

See_also: 
    $(LINK2 https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/quantile, quantile)
+/
enum QuantileAlgo {
    /++
    $(H4 Discontinuous sample quantile)

    Inverse of empirical distribution function.
    +/
    type1,
    /++
    Similar to type1, but averages at discontinuities.
    +/
    type2,
    /++
    SAS definition: nearest even order statistic.
    +/
    type3,
    /++
    $(H4 Continuous sample quantile)

    Linear interpolation of the empirical cdf.
    +/
    type4,
    /++
    A piece-wise linear function hwere the knots are the values midway through
    the steps of the empirical cdf. Popular amongst hydrologists.
    +/
    type5,
    /++
    Used by Minitab and by SPSS.
    +/
    type6,
    /++
    This is used by S and is the default for R.
    +/
    type7,
    /++
    The resulting quantile estimates are approximately median-unbiased
    regardless of the distribution of the input. Preferred by Hyndman and Fan
    (1996).
    +/
    type8,
    /++
    The resulting quantile estimates are approximately unbiased for the expected
    order statistics of the input is normally distributed.
    +/
    type9
}

/++
For all $(LREF QuantileAlgo) except $(LREF QuantileAlgo.type1) and $(LREF QuantileAlgo.type3),
this is an alias to the $(MATHREF stat, meanType) of `T`

For $(LREF QuantileAlgo.type1) and $(LREF QuantileAlgo.type3), this is an alias to the
$(MATHREF sum, elementType) of `T`.
+/
package(mir.stat)
template quantileType(T, QuantileAlgo quantileAlgo)
{
    static if (quantileAlgo == QuantileAlgo.type1 ||
               quantileAlgo == QuantileAlgo.type3)
    {
        import mir.math.sum: elementType;

        alias quantileType = elementType!T;
    }
    else
    {
        alias quantileType = meanType!T;
    }
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static assert(is(quantileType!(int[], QuantileAlgo.type1) == int));
    static assert(is(quantileType!(double[], QuantileAlgo.type1) == double));
    static assert(is(quantileType!(float[], QuantileAlgo.type1) == float));

    static assert(is(quantileType!(int[], QuantileAlgo.type2) == double));
    static assert(is(quantileType!(double[], QuantileAlgo.type2) == double));
    static assert(is(quantileType!(float[], QuantileAlgo.type2) == float));

    static assert(is(quantileType!(int[], QuantileAlgo.type3) == int));
    static assert(is(quantileType!(double[], QuantileAlgo.type3) == double));
    static assert(is(quantileType!(float[], QuantileAlgo.type3) == float));

    static assert(is(quantileType!(int[], QuantileAlgo.type4) == double));
    static assert(is(quantileType!(double[], QuantileAlgo.type4) == double));
    static assert(is(quantileType!(float[], QuantileAlgo.type4) == float));

    static assert(is(quantileType!(int[], QuantileAlgo.type5) == double));
    static assert(is(quantileType!(double[], QuantileAlgo.type5) == double));
    static assert(is(quantileType!(float[], QuantileAlgo.type5) == float));

    static assert(is(quantileType!(int[], QuantileAlgo.type6) == double));
    static assert(is(quantileType!(double[], QuantileAlgo.type6) == double));
    static assert(is(quantileType!(float[], QuantileAlgo.type6) == float));

    static assert(is(quantileType!(int[], QuantileAlgo.type7) == double));
    static assert(is(quantileType!(double[], QuantileAlgo.type7) == double));
    static assert(is(quantileType!(float[], QuantileAlgo.type7) == float));

    static assert(is(quantileType!(int[], QuantileAlgo.type8) == double));
    static assert(is(quantileType!(double[], QuantileAlgo.type8) == double));
    static assert(is(quantileType!(float[], QuantileAlgo.type8) == float));

    static assert(is(quantileType!(int[], QuantileAlgo.type9) == double));
    static assert(is(quantileType!(double[], QuantileAlgo.type9) == double));
    static assert(is(quantileType!(float[], QuantileAlgo.type9) == float));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.complex: Complex;

    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type1) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type2) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type3) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type4) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type5) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type6) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type7) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type8) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type9) == Complex!float));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import std.complex: Complex;

    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type1) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type2) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type3) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type4) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type5) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type6) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type7) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type8) == Complex!float));
    static assert(is(quantileType!(Complex!(float)[], QuantileAlgo.type9) == Complex!float));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    static struct Foo {
        float x;
        alias x this;
    }

    static assert(is(quantileType!(Foo[], QuantileAlgo.type7) == float));

    static assert(is(quantileType!(Foo[], QuantileAlgo.type1) == Foo));
    static assert(is(quantileType!(Foo[], QuantileAlgo.type3) == Foo));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.complex: Complex;
    static struct Foo {
        Complex!float x;
        alias x this;
    }

    static assert(is(quantileType!(Foo[], QuantileAlgo.type7) == Complex!float));
}

version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import std.complex: Complex;
    static struct Foo {
        Complex!float x;
        alias x this;
    }

    static assert(is(quantileType!(Foo[], QuantileAlgo.type7) == Complex!float));
}

@fmamath private @safe pure nothrow @nogc
auto quantileImpl(F, QuantileAlgo quantileAlgo, Iterator, G)(Slice!Iterator slice, G p)
    if ((isFloatingPoint!F || (quantileAlgo == QuantileAlgo.type1 || 
                               quantileAlgo == QuantileAlgo.type3)) &&
        isFloatingPoint!G)
{
    assert(p >= 0 && p <= 1, "quantileImpl: p must be between 0 and 1");
    size_t n = slice.elementCount;
    assert(n > 1, "quantileImpl: slice.elementCount must be greater than 1");

    import mir.math.common: floor;
    import mir.ndslice.sorting: partitionAt;
    import std.traits: Unqual;

    alias GG = Unqual!G;

    GG m;

    static if (quantileAlgo == QuantileAlgo.type1) {
        m = 0;
    } else static if (quantileAlgo == QuantileAlgo.type2) {
        m = 0;
    } else static if (quantileAlgo == QuantileAlgo.type3) {
        m = -0.5;
    } else static if (quantileAlgo == QuantileAlgo.type4) {
        m = 0;
    } else static if (quantileAlgo == QuantileAlgo.type5) {
        m = 0.5;
    } else static if (quantileAlgo == QuantileAlgo.type6) {
        m = p;
    } else static if (quantileAlgo == QuantileAlgo.type7) {
        m = 1 - p;
    } else static if (quantileAlgo == QuantileAlgo.type8) {
        m = (p + 1) / 3;
    } else static if (quantileAlgo == QuantileAlgo.type9) {
        m = p / 4 + cast(GG) 3 / 8;
    }

    GG g = n * p + m - 1; //note: 0-based, not 1-based indexing

    GG pre_j = floor(g);
    GG pre_j_1 = pre_j + 1;
    size_t j;
    if (pre_j >= (n - 1)) { //note: 0-based, not 1-based indexing
        j = n - 1;
    } else if (pre_j < 0) {
        j = 0;
    } else {
        j = cast(size_t) pre_j;
    }

    size_t j_1;
    if (pre_j_1 >= (n - 1)) { //note: 0-based, not 1-based indexing
        j_1 = n - 1;
    } else if (pre_j_1 < 0) {
        j_1 = 0;
    } else {
        j_1 = cast(size_t) pre_j_1;
    }

    g -= j;
    GG gamma;

    static if (quantileAlgo == QuantileAlgo.type1) {
        if (g == 0) {
            gamma = 0;
        } else {
            gamma = 1;
        }
    } else static if (quantileAlgo == QuantileAlgo.type2) {
        if (g == 0) {
            gamma = 0.5;
        } else {
            gamma = 1;
        }
    } else static if (quantileAlgo == QuantileAlgo.type3) {
        if (g == 0 && (j + 1) % 2 == 0) { //need to adjust because 0-based indexing
            gamma = 0;
        } else {
            gamma = 1;
        }
    } else {
        gamma = g;
    }

    if (gamma == 0) {
        partitionAt(slice, j);
        return cast(F) slice[j];
    } else if (gamma == 1) {
        partitionAt(slice, j_1);
        return cast(F) slice[j_1];
    } else if (j != j_1) {
        partitionAt(slice, j_1);
        partitionAt(slice[0 .. j_1], j);
        return cast(F) ((1 - gamma) * slice[j] + gamma * slice[j_1]);
    } else {
        partitionAt(slice, j);
        return cast(F) slice[j];
    }
}

/++
Computes the quantile(s) of the input, given one or more probabilities `p`.

By default, if `p` is a $(NDSLICEREF slice, Slice), built-in dynamic array, or type
with `asSlice`, then the output type is a reference-counted copy of the input. A
compile-time parameter is provided to instead overwrite the input in-place.

For all $(LREF QuantileAlgo) except $(LREF QuantileAlgo.type1) and $(LREF QuantileAlgo.type3),
by default, if `F` is not floating point type or complex type, then the result
will have a `double` type if `F` is implicitly convertible to a floating point 
type or a type for which `isComplex!F` is true.

For $(LREF QuantileAlgo.type1) and $(LREF QuantileAlgo.type3), the return type is the
$(MATHREF sum, elementType) of the input.

Params:
    F = controls type of output
    quantileAlgo = algorithm for calculating quantile (default: $(LREF QuantileAlgo.type7))
    allowModifySlice = controls whether the input is modified in place, default is false

Returns:
    The quantile of all the elements in the input at probability `p`.

See_also: 
    $(LREF median),
    $(MATHREF sum, partitionAt),
    $(MATHREF sum, elementType)
+/
template quantile(F, 
                  QuantileAlgo quantileAlgo = QuantileAlgo.type7, 
                  bool allowModifySlice = false,
                  bool allowModifyProbability = false)
    if (isFloatingPoint!F || (quantileAlgo == QuantileAlgo.type1 || 
                              quantileAlgo == QuantileAlgo.type3))
{
    import mir.math.sum: elementType;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind, sliced;
    import mir.ndslice.topology: flattened;
    import std.traits: Unqual;

    /++
    Params:
        slice = slice
        p = probability
    +/
    quantileType!(F, quantileAlgo) quantile(Iterator, size_t N, SliceKind kind, G)
            (Slice!(Iterator, N, kind) slice, G p)
        if (isFloatingPoint!(Unqual!G))
    {
        import mir.ndslice.slice: IteratorOf;
        import std.traits: Unqual;

        alias FF = typeof(return);
        static if (!allowModifySlice) {
            import mir.ndslice.allocation: rcslice;
            import mir.ndslice.topology: as;

            auto view = slice.lightScope;
            auto val = view.as!(Unqual!(slice.DeepElement)).rcslice;
            auto temp = val.lightScope.flattened;
        } else {
            auto temp = slice.flattened;
        }
        return quantileImpl!(FF, quantileAlgo, IteratorOf!(typeof(temp)), Unqual!G)(temp, p);
    }

    /++
    Params:
        slice = slice
        p = probability slice
    +/
    auto quantile(IteratorA, size_t N, SliceKind kindA, IteratorB, SliceKind kindB)
            (Slice!(IteratorA, N, kindA) slice, 
             Slice!(IteratorB, 1, kindB) p)
        if (isFloatingPoint!(elementType!(Slice!(IteratorB))))
    {
        import mir.ndslice.allocation: rcslice;
        import mir.ndslice.slice: IteratorOf;
        import mir.ndslice.topology: as;

        alias G = elementType!(Slice!(IteratorB));
        alias FF = quantileType!(F, quantileAlgo);

        static if (!allowModifySlice) {

            auto view = slice.lightScope;
            auto val = view.as!(Unqual!(slice.DeepElement)).rcslice;
            auto temp = val.lightScope.flattened;
        } else {
            auto temp = slice.flattened;
        }

        static if (allowModifyProbability) {
            foreach(ref e; p) {
                e = quantileImpl!(FF, quantileAlgo, IteratorOf!(typeof(temp)), G)(temp, e);
            }
            return p;
        } else {
            auto view_p = p.lightScope;
            auto val_p = view_p.as!G.rcslice;
            auto temp_p = val_p.lightScope.flattened;
            foreach(ref e; temp_p) {
                e = quantileImpl!(FF, quantileAlgo, IteratorOf!(typeof(temp)), G)(temp, e);
            }
            return temp_p;
        }
    }

    /// ditto
    auto quantile(Iterator, size_t N, SliceKind kind)(
        Slice!(Iterator, N, kind) slice, scope const F[] p...)
        if (isFloatingPoint!(elementType!(F[])))
    {
        import mir.ndslice.allocation: rcslice;
        import mir.ndslice.slice: IteratorOf;

        alias G = elementType!(F[]);
        alias FF = quantileType!(F, quantileAlgo);

        static if (!allowModifySlice) {
            import mir.ndslice.allocation: rcslice;
            import mir.ndslice.topology: as;

            auto view = slice.lightScope;
            auto val = view.as!(Unqual!(slice.DeepElement)).rcslice;
            auto temp = val.lightScope.flattened;
        } else {
            auto temp = slice.flattened;
        }

        auto val_p = p.rcslice!G;
        auto temp_p = val_p.lightScope.flattened;
        foreach(ref e; temp_p) {
            e = quantileImpl!(FF, quantileAlgo, IteratorOf!(typeof(temp)), G)(temp, e);
        }
        return temp_p;
    }

    /// ditto
    auto quantile(SliceLike, G)(SliceLike x, G p)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike &&
            isFloatingPoint!(Unqual!G))
    {
        import mir.ndslice.slice: toSlice;
        return quantile(x.toSlice, p);
    }

    /// ditto
    auto quantile(SliceLikeX, SliceLikeP)(SliceLikeX x, SliceLikeP p)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeP && !isSlice!SliceLikeP)
    {
        import mir.ndslice.slice: toSlice;
        return quantile(x.toSlice, p.toSlice);
    }
}

///
template quantile(QuantileAlgo quantileAlgo = QuantileAlgo.type7, 
                  bool allowModifySlice = false,
                  bool allowModifyProbability = false)
{
    import mir.math.sum: elementType;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import std.traits: Unqual;

    /++
    Params:
        slice = slice
        p = probability
    +/
    quantileType!(Slice!(Iterator), quantileAlgo) quantile(Iterator, size_t N, SliceKind kind, G)
            (Slice!(Iterator, N, kind) slice, G p)
        if (isFloatingPoint!(Unqual!G))
    {
        alias F = typeof(return);

        return .quantile!(F, quantileAlgo, allowModifySlice, allowModifyProbability)(slice, p);
    }

    /// ditto
    auto quantile(IteratorA, size_t N, SliceKind kindA, IteratorB, SliceKind kindB)
            (Slice!(IteratorA, N, kindA) slice, 
             Slice!(IteratorB, 1, kindB) p)
        if (isFloatingPoint!(elementType!(Slice!(IteratorB))))
    {
        alias F = quantileType!(Slice!(IteratorA), quantileAlgo);
        return .quantile!(F, quantileAlgo, allowModifySlice, allowModifyProbability)(slice, p);
    }

    /// ditto
    auto quantile(Iterator, size_t N, SliceKind kind, G)(
        Slice!(Iterator, N, kind) slice, scope G[] p...)
        if (isFloatingPoint!(elementType!(G[])))
    {
        alias F = quantileType!(Slice!(Iterator), quantileAlgo);
        return .quantile!(F, quantileAlgo, allowModifySlice, allowModifyProbability)(slice, p);
    }

    /// ditto
    auto quantile(SliceLike, G)(SliceLike x, G p)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike &&
            isFloatingPoint!(Unqual!G))
    {
        import mir.ndslice.slice: toSlice;
        alias F = quantileType!(typeof(x.toSlice), quantileAlgo);
        return .quantile!(F, quantileAlgo, allowModifySlice, allowModifyProbability)(x, p);
    }

    /// ditto
    auto quantile(SliceLikeX, SliceLikeP)(SliceLikeX x, SliceLikeP p)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeP && !isSlice!SliceLikeP)
    {
        import mir.ndslice.slice: toSlice;
        alias F = quantileType!(typeof(x.toSlice), quantileAlgo);
        return .quantile!(F, quantileAlgo, allowModifySlice, allowModifyProbability)(x, p);
    }
}

/// ditto
template quantile(F, string quantileAlgo,
                  bool allowModifySlice = false,
                  bool allowModifyProbability = false)
{
    mixin("alias quantile = .quantile!(F, QuantileAlgo." ~ quantileAlgo ~ ", allowModifySlice, allowModifyProbability);");
}

/// ditto
template quantile(string quantileAlgo,
                  bool allowModifySlice = false,
                  bool allowModifyProbability = false)
{
    mixin("alias quantile = .quantile!(QuantileAlgo." ~ quantileAlgo ~ ", allowModifySlice, allowModifyProbability);");
}

/// Simple example
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [3.0, 1.0, 4.0, 2.0, 0.0].sliced;
              
    assert(x.quantile(0.5).approxEqual(2.0));

    auto qtile = [0.25, 0.75].sliced;

    assert(x.quantile(qtile).all!approxEqual([1.0, 3.0]));
    assert(x.quantile(0.25, 0.75).all!approxEqual([1.0, 3.0]));
}

//no change in x by default
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [3.0, 1.0, 4.0, 2.0, 0.0].sliced;
    auto x_copy = x.dup;
    auto result = x.quantile(0.5);

    assert(result.approxEqual(2.0));
    assert(x.all!approxEqual(x_copy));
}

/// Modify probability in place
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [3.0, 1.0, 4.0, 2.0, 0.0].sliced;

    auto qtile = [0.25, 0.75].sliced;
    auto qtile_copy = qtile.dup;

    x.quantile!("type7", false, true)(qtile);
    assert(qtile.all!approxEqual([1.0, 3.0]));
    assert(!qtile.all!approxEqual(qtile_copy));
}

/// Quantile of vector
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2,
              2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5].sliced;

    assert(x.quantile(0.5).approxEqual(5.20));

    auto qtile = [0.25, 0.75].sliced;

    assert(x.quantile(qtile).all!approxEqual([3.250, 8.500]));
}

/// Quantile of matrix
version(mir_stat_test)
@safe pure
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.slice: sliced;

    auto x = [
        [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2],
        [2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5]
    ].fuse;

    assert(x.quantile(0.5).approxEqual(5.20));

    auto qtile = [0.25, 0.75].sliced;

    assert(x.quantile(qtile).all!approxEqual([3.250, 8.500]));
}

/// Row quantile of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: alongDim, byDim, map, flattened;

    auto x = [
        [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2],
        [2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5]
    ].fuse;

    auto result0 = [5.200, 5.700];

    // Use byDim or alongDim with map to compute median of row/column.
    assert(x.byDim!0.map!(a => a.quantile(0.5)).all!approxEqual(result0));
    assert(x.alongDim!1.map!(a => a.quantile(0.5)).all!approxEqual(result0));

    auto qtile = [0.25, 0.75].sliced;
    auto result1 = [[3.750, 7.600], [2.825, 9.025]];

    assert(x.byDim!0.map!(a => a.quantile(qtile)).all!(all!approxEqual)(result1));
}

/// Allow modification of input
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [3.0, 1.0, 4.0, 2.0, 0.0].sliced;
    auto x_copy = x.dup;

    auto result = x.quantile!(QuantileAlgo.type7, true)(0.5);
    assert(!x.all!approxEqual(x_copy));
}

/// Double-check probability is not modified
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [3.0, 1.0, 4.0, 2.0, 0.0].sliced;

    auto qtile = [0.25, 0.75].sliced;
    auto qtile_copy = qtile.dup;

    auto result = x.quantile!("type7", false, false)(qtile);
    assert(result.all!approxEqual([1.0, 3.0]));
    assert(qtile.all!approxEqual(qtile_copy));
}

/// Can also set algorithm type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2,
              2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5].sliced;

    assert(x.quantile!"type1"(0.5).approxEqual(5.20));
    assert(x.quantile!"type2"(0.5).approxEqual(5.20));
    assert(x.quantile!"type3"(0.5).approxEqual(5.20));
    assert(x.quantile!"type4"(0.5).approxEqual(5.20));
    assert(x.quantile!"type5"(0.5).approxEqual(5.20));
    assert(x.quantile!"type6"(0.5).approxEqual(5.20));
    assert(x.quantile!"type7"(0.5).approxEqual(5.20));
    assert(x.quantile!"type8"(0.5).approxEqual(5.20));
    assert(x.quantile!"type9"(0.5).approxEqual(5.20));
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;

    auto a = [1, 1e100, 1, -1e100].sliced;

    auto x = a * 10_000;

    auto result0 = x.quantile!float(0.5);
    assert(result0 == 10_000f);
    static assert(is(typeof(result0) == float));

    auto result1 = x.quantile!(float, "type8")(0.5);
    assert(result1 == 10_000f);
    static assert(is(typeof(result1) == float));
}

/// Support for integral and user-defined types for type 1 & 3
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.topology: repeat;

    auto x = uint.max.repeat(3);
    assert(x.quantile!(uint, "type1")(0.5) == uint.max);
    assert(x.quantile!(uint, "type3")(0.5) == uint.max);

    static struct Foo {
        float x;
        alias x this;
    }

    Foo[] foo = [Foo(1f), Foo(2f), Foo(3f)];
    assert(foo.quantile!"type1"(0.5) == 2f);
    assert(foo.quantile!"type3"(0.5) == 2f);
}

/// Compute quantile along specified dimention of tensors
version(mir_stat_test)
@safe pure
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.topology: as, iota, alongDim, map, repeat;

    auto x = [
        [0.0, 1, 3],
        [4.0, 5, 7]
    ].fuse;

    assert(x.quantile(0.5).approxEqual(3.5));

    auto m0 = [2.0, 3.0, 5.0];
    assert(x.alongDim!0.map!(a => a.quantile(0.5)).all!approxEqual(m0));
    assert(x.alongDim!(-2).map!(a => a.quantile(0.5)).all!approxEqual(m0));

    auto m1 = [1.0, 5.0];
    assert(x.alongDim!1.map!(a => a.quantile(0.5)).all!approxEqual(m1));
    assert(x.alongDim!(-1).map!(a => a.quantile(0.5)).all!approxEqual(m1));

    assert(iota(2, 3, 4, 5).as!double.alongDim!0.map!(a => a.quantile(0.5)).all!approxEqual(iota([3, 4, 5], 3 * 4 * 5 / 2)));
}

/// Support for array
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;

    double[] x = [3.0, 1.0, 4.0, 2.0, 0.0];
              
    assert(x.quantile(0.5).approxEqual(2.0));

    double[] qtile = [0.25, 0.75];

    assert(x.quantile(qtile).all!approxEqual([1.0, 3.0]));
}

//@nogc test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2,
                          2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5];

    assert(x.sliced.quantile(0.5).approxEqual(5.20));

    static immutable qtile = [0.25, 0.75];
    static immutable result = [3.250, 8.500];

    assert(x.sliced.quantile(qtile).all!approxEqual(result));
}

// withAsSlice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    static immutable a = [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2,
                          2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5];

    auto x = RCArray!double(20);
    foreach(i, ref e; x)
        e = a[i];

    assert(x.quantile(0.5).approxEqual(5.20));

    auto qtile = RCArray!double(2);
    qtile[0] = 0.25;
    qtile[1] = 0.75;
    static immutable result = [3.250, 8.500];

    assert(x.quantile(qtile).all!approxEqual(result));
}

//x.length = 20, qtile at tenths
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2,
              2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5].sliced;
    auto qtile = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0].sliced;

    assert(x.quantile!"type1"(qtile.dup).all!approxEqual([0.2, 1.0, 2.2, 3.5, 4.5, 5.2, 5.8, 8.2, 8.5, 9.2, 9.8]));
    assert(x.quantile!"type2"(qtile.dup).all!approxEqual([0.2, 1.4, 2.35, 3.65, 4.85, 5.2, 6.0, 8.35, 8.85, 9.2, 9.8]));   
    assert(x.quantile!"type3"(qtile.dup).all!approxEqual([0.2, 1.0, 2.2, 3.5, 4.5, 5.2, 5.8, 8.2, 8.5, 9.2, 9.8]));
    assert(x.quantile!"type4"(qtile.dup).all!approxEqual([0.2, 1.0, 2.2, 3.5, 4.5, 5.2, 5.8, 8.2, 8.5, 9.2, 9.8]));
    assert(x.quantile!"type5"(qtile.dup).all!approxEqual([0.20, 1.40, 2.35, 3.65, 4.85, 5.20, 6.00, 8.35, 8.85, 9.20, 9.80]));
    assert(x.quantile!"type6"(qtile.dup).all!approxEqual([0.20, 1.08, 2.26, 3.59, 4.78, 5.20, 6.04, 8.41, 9.06, 9.20, 9.80]));
    assert(x.quantile!"type7"(qtile.dup).all!approxEqual([0.20, 1.72, 2.44, 3.71, 4.92, 5.20, 5.96, 8.29, 8.64, 9.20, 9.80]));
    assert(x.quantile!"type8"(qtile.dup).all!approxEqual([0.200000, 1.293333, 2.320000, 3.630000, 4.826667, 5.200000, 6.013333, 8.370000, 8.920000, 9.200000, 9.800000]));
    assert(x.quantile!"type9"(qtile.dup).all!approxEqual([0.2000, 1.3200, 2.3275, 3.6350, 4.8325, 5.2000, 6.0100, 8.3650, 8.9025, 9.200, 9.800]));
}

//x.length = 20, qtile at 5s
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2,
              2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5].sliced;
    auto qtile = [0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.95].sliced;

    assert(x.quantile!"type1"(qtile.dup).all!approxEqual([0.2, 1.8, 2.5, 3.8, 5.2, 5.2, 6.2, 8.5, 9.2, 9.2]));
    assert(x.quantile!"type2"(qtile.dup).all!approxEqual([0.60, 2.00, 3.00, 4.15, 5.20, 5.50, 7.20, 8.50, 9.20, 9.50]));   
    assert(x.quantile!"type3"(qtile.dup).all!approxEqual([0.2, 1.8, 2.5, 3.8, 5.2, 5.2, 6.2, 8.5, 9.2, 9.2]));
    assert(x.quantile!"type4"(qtile.dup).all!approxEqual([0.2, 1.8, 2.5, 3.8, 5.2, 5.2, 6.2, 8.5, 9.2, 9.2]));
    assert(x.quantile!"type5"(qtile.dup).all!approxEqual([0.60, 2.00, 3.00, 4.15, 5.20, 5.50, 7.20, 8.50, 9.20, 9.50]));
    assert(x.quantile!"type6"(qtile.dup).all!approxEqual([0.240, 1.860, 2.750, 4.045, 5.200, 5.530, 7.500, 8.500, 9.200, 9.770]));
    assert(x.quantile!"type7"(qtile.dup).all!approxEqual([0.960, 2.140, 3.250, 4.255, 5.200, 5.470, 6.900, 8.500, 9.200, 9.230]));
    assert(x.quantile!"type8"(qtile.dup).all!approxEqual([0.480000, 1.953333, 2.916667, 4.115000, 5.200000, 5.510000, 7.300000, 8.500000, 9.200000, 9.590000]));
    assert(x.quantile!"type9"(qtile.dup).all!approxEqual([0.51000, 1.96500, 2.93750, 4.12375, 5.20000, 5.50750, 7.27500, 8.50000, 9.20000, 9.56750]));
}

//x.length = 21, qtile at tenths
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [ 1.0, 9.3, 0.2, 8.1, 5.5, 3.3, 4.3, 7.9, 5.0, 5.0, 
              10.0, 2.4, 1.7, 2.1, 3.6, 5.0, 8.8, 9.8, 6.0, 8.8, 
               8.8].sliced;
    auto qtile = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0].sliced;

    assert(x.quantile!"type1"(qtile.dup).all!approxEqual([0.2, 1.7, 2.4, 3.6, 5.0, 5.0, 6.0, 8.1, 8.8, 9.3, 10.0]));
    assert(x.quantile!"type2"(qtile.dup).all!approxEqual([0.2, 1.7, 2.4, 3.6, 5.0, 5.0, 6.0, 8.1, 8.8, 9.3, 10.0]));   
    assert(x.quantile!"type3"(qtile.dup).all!approxEqual([0.2, 1.0, 2.1, 3.3, 4.3, 5.0, 6.0, 8.1, 8.8, 9.3, 10.0]));
    assert(x.quantile!"type4"(qtile.dup).all!approxEqual([0.20, 1.07, 2.16, 3.39, 4.58, 5.00, 5.80, 8.04, 8.80, 9.25, 10.00]));
    assert(x.quantile!"type5"(qtile.dup).all!approxEqual([0.20, 1.42, 2.31, 3.54, 4.93, 5.00, 6.19, 8.24, 8.80, 9.50, 10.00]));
    assert(x.quantile!"type6"(qtile.dup).all!approxEqual([0.20, 1.14, 2.22, 3.48, 4.86, 5.00, 6.38, 8.38, 8.80, 9.70, 10.00]));
    assert(x.quantile!"type7"(qtile.dup).all!approxEqual([0.2, 1.7, 2.4, 3.6, 5.0, 5.0, 6.0, 8.1, 8.8, 9.3, 10.0]));
    assert(x.quantile!"type8"(qtile.dup).all!approxEqual([0.200000, 1.326667, 2.280000, 3.520000, 4.906667, 5.000000, 6.253333, 8.286667, 8.800000, 9.566667, 10.000000]));
    assert(x.quantile!"type9"(qtile.dup).all!approxEqual([0.2000, 1.3500, 2.2875, 3.5250, 4.9125, 5.0000, 6.2375, 8.2750, 8.8000, 9.5500, 10.0000]));
}

//x.length = 21, qtile at 5s
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [ 1.0, 9.3, 0.2, 8.1, 5.5, 3.3, 4.3, 7.9, 5.0, 5.0, 
              10.0, 2.4, 1.7, 2.1, 3.6, 5.0, 8.8, 9.8, 6.0, 8.8, 
               8.8].sliced;
    auto qtile = [0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.95].sliced;

    assert(x.quantile!"type1"(qtile.dup).all!approxEqual([1.0, 2.1, 3.3, 4.3, 5.0, 5.5, 7.9, 8.8, 8.8, 9.8]));
    assert(x.quantile!"type2"(qtile.dup).all!approxEqual([1.0, 2.1, 3.3, 4.3, 5.0, 5.5, 7.9, 8.8, 8.8, 9.8]));   
    assert(x.quantile!"type3"(qtile.dup).all!approxEqual([0.2, 1.7, 2.4, 3.6, 5.0, 5.5, 7.9, 8.8, 8.8, 9.8]));
    assert(x.quantile!"type4"(qtile.dup).all!approxEqual([0.240, 1.760, 2.625, 3.845, 5.000, 5.275, 7.235, 8.625, 8.800, 9.775]));
    assert(x.quantile!"type5"(qtile.dup).all!approxEqual([0.640, 1.960, 3.075, 4.195, 5.000, 5.525, 7.930, 8.800, 8.975, 9.890]));
    assert(x.quantile!"type6"(qtile.dup).all!approxEqual([0.28, 1.82, 2.85, 4.09, 5.00, 5.55, 7.96, 8.80, 9.15, 9.98]));
    assert(x.quantile!"type7"(qtile.dup).all!approxEqual([1.0, 2.1, 3.3, 4.3, 5.0, 5.5, 7.9, 8.8, 8.8, 9.8]));
    assert(x.quantile!"type8"(qtile.dup).all!approxEqual([0.520000, 1.913333, 3.000000, 4.160000, 5.000000, 5.533333, 7.940000, 8.800000, 9.033333, 9.920000]));
    assert(x.quantile!"type9"(qtile.dup).all!approxEqual([0.55000, 1.92500, 3.01875, 4.16875, 5.00000, 5.53125, 7.93750, 8.80000, 9.01875, 9.91250]));
}

/++
Computes the interquartile range of the input.

By default, this function computes the result using $(LREF quantile), i.e.
`result = quantile(x, 0.75) - quantile(x, 0.25)`. There are also overloads for
providing a low value, as in `result = quantile(x, 1 - low) - quantile(x, low)`
and both a low and high value, as in `result = quantile(x, high) - quantile(x, low)`.

For all $(LREF QuantileAlgo) except $(LREF QuantileAlgo.type1) and $(LREF QuantileAlgo.type3),
by default, if `F` is not floating point type or complex type, then the result
will have a `double` type if `F` is implicitly convertible to a floating point 
type or a type for which `isComplex!F` is true.

For $(LREF QuantileAlgo.type1) and $(LREF QuantileAlgo.type3), the return type is the
$(MATHREF sum, elementType) of the input.

Params:
    F = controls type of output
    quantileAlgo = algorithm for calculating quantile (default: $(LREF QuantileAlgo.type7))
    allowModifySlice = controls whether the input is modified in place, default is false

Returns:
    The interquartile range of the input. 

See_also: 
    $(LREF quantile)
+/
template interquartileRange(F, QuantileAlgo quantileAlgo = QuantileAlgo.type7,
                            bool allowModifySlice = false)
{
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;

    /++
    Params:
        slice = slice
    +/
    @fmamath quantileType!(F, quantileAlgo) interquartileRange(
        Iterator, size_t N, SliceKind kind)(
            Slice!(Iterator, N, kind) slice)
    {
        import core.lifetime: move;

        alias FF = typeof(return);
        auto lo_hi = quantile!(FF, quantileAlgo, allowModifySlice, false)(slice.move, cast(FF) 0.25, cast(FF) 0.75);
        return lo_hi[1] - lo_hi[0];
    }

    /++
    Params:
        slice = slice
        lo = low value
    +/
    @fmamath quantileType!(F, quantileAlgo) interquartileRange(
        Iterator, size_t N, SliceKind kind)(
            Slice!(Iterator, N, kind) slice,
            F lo = 0.25)
    {
        import core.lifetime: move;

        alias FF = typeof(return);
        auto lo_hi = quantile!(FF, quantileAlgo, allowModifySlice, false)(slice.move, cast(FF) lo, cast(FF) (1 - lo));
        return lo_hi[1] - lo_hi[0];
    }

    /++
    Params:
        slice = slice
        lo = low value
        hi = high value
    +/
    @fmamath quantileType!(F, quantileAlgo) interquartileRange(
        Iterator, size_t N, SliceKind kind)(
            Slice!(Iterator, N, kind) slice,
            F lo,
            F hi)
    {
        import core.lifetime: move;

        alias FF = typeof(return);
        auto lo_hi = quantile!(FF, quantileAlgo, allowModifySlice, false)(slice.move, cast(FF) lo, cast(FF) hi);
        return lo_hi[1] - lo_hi[0];
    }

    /++
    Params:
        array = array
    +/
    @fmamath quantileType!(F[], quantileAlgo) interquartileRange(scope F[] array...)
    {
        import mir.ndslice.slice: sliced;

        alias FF = typeof(return);
        return .interquartileRange!(FF, quantileAlgo, allowModifySlice)(array.sliced);
    }

    /// ditto
    @fmamath auto interquartileRange(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        return interquartileRange(x.toSlice);
    }
}

/// ditto
template interquartileRange(QuantileAlgo quantileAlgo = QuantileAlgo.type7,
                            bool allowModifySlice = false)
{
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;

    /// ditto
    @fmamath quantileType!(Slice!(Iterator), quantileAlgo)
        interquartileRange(Iterator, size_t N, SliceKind kind)(
            Slice!(Iterator, N, kind) slice)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .interquartileRange!(F, quantileAlgo, allowModifySlice)(slice.move);
    }

    /// ditto
    @fmamath quantileType!(Slice!(Iterator), quantileAlgo)
        interquartileRange(Iterator, size_t N, SliceKind kind, F)(
            Slice!(Iterator, N, kind) slice,
            F lo)
    {
        import core.lifetime: move;

        alias FF = typeof(return);
        return .interquartileRange!(FF, quantileAlgo, allowModifySlice)(slice.move, cast(FF) lo);
    }

    /// ditto
    @fmamath quantileType!(Slice!(Iterator), quantileAlgo)
        interquartileRange(Iterator, size_t N, SliceKind kind, F)(
            Slice!(Iterator, N, kind) slice,
            F lo,
            F hi)
    {
        import core.lifetime: move;

        alias FF = typeof(return);
        return .interquartileRange!(F, quantileAlgo, allowModifySlice)(slice.move, cast(FF) lo, cast(FF) hi);
    }

    /// ditto
    @fmamath quantileType!(T[], quantileAlgo)
        interquartileRange(T)(scope T[] array...)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .interquartileRange!(F, quantileAlgo, allowModifySlice)(array);
    }

    /// ditto
    @fmamath auto interquartileRange(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        alias F = quantileType!(typeof(x.toSlice), quantileAlgo);
        return .interquartileRange!(F, quantileAlgo, allowModifySlice)(x);
    }
}

/// ditto
template interquartileRange(F, string quantileAlgo, bool allowModifySlice = false)
{
    mixin("alias interquartileRange = .interquartileRange!(F, QuantileAlgo." ~ quantileAlgo ~ ", allowModifySlice);");
}

/// ditto
template interquartileRange(string quantileAlgo, bool allowModifySlice = false)
{
    mixin("alias interquartileRange = .interquartileRange!(QuantileAlgo." ~ quantileAlgo ~ ", allowModifySlice);");
}

/// Simple example
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [3.0, 1.0, 4.0, 2.0, 0.0].sliced;

    assert(x.interquartileRange.approxEqual(2.0));
    assert(x.interquartileRange(0.25).approxEqual(2.0));
    assert(x.interquartileRange(0.25, 0.75).approxEqual(2.0));
}

//no change in x by default
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [3.0, 1.0, 4.0, 2.0, 0.0].sliced;
    auto x_copy = x.dup;
    auto result = x.interquartileRange;

    assert(x.all!approxEqual(x_copy));
}

/// Interquartile Range of vector
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2,
              2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5].sliced;

    assert(x.interquartileRange.approxEqual(5.25));
}

/// Interquartile Range of matrix
version(mir_stat_test)
@safe pure
unittest 
{
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.ndslice.slice: sliced;

    auto x = [
        [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2],
        [2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5]
    ].fuse;

    assert(x.interquartileRange.approxEqual(5.25));
}

/// Allow modification of input
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [3.0, 1.0, 4.0, 2.0, 0.0].sliced;
    auto x_copy = x.dup;

    auto result = x.interquartileRange!(QuantileAlgo.type7, true);
    assert(!x.all!approxEqual(x_copy));
}

/// Can also set algorithm type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2,
              2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5].sliced;

    assert(x.interquartileRange!"type1".approxEqual(6.0));
    assert(x.interquartileRange!"type2".approxEqual(5.5));
    assert(x.interquartileRange!"type3".approxEqual(6.0));
    assert(x.interquartileRange!"type4".approxEqual(6.0));
    assert(x.interquartileRange!"type5".approxEqual(5.5));
    assert(x.interquartileRange!"type6".approxEqual(5.75));
    assert(x.interquartileRange!"type7".approxEqual(5.25));
    assert(x.interquartileRange!"type8".approxEqual(5.583333));
    assert(x.interquartileRange!"type9".approxEqual(5.5625));
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto a = [1, 1e34, 1, -1e34, 0].sliced;

    auto x = a * 10_000;

    auto result0 = x.interquartileRange!float;
    assert(result0.approxEqual(10_000));
    static assert(is(typeof(result0) == float));

    auto result1 = x.interquartileRange!(float, "type8");
    assert(result1.approxEqual(6.666667e37));
    static assert(is(typeof(result1) == float));
}

/// Support for array
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.math.common: approxEqual;

    double[] x = [3.0, 1.0, 4.0, 2.0, 0.0];
              
    assert(x.interquartileRange.approxEqual(2.0));
}

// withAsSlice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    static immutable a = [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2,
                          2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5];

    auto x = RCArray!double(20);
    foreach(i, ref e; x)
        e = a[i];

    assert(x.interquartileRange.approxEqual(5.25));
    assert(x.interquartileRange!double.approxEqual(5.25));
}

// Arbitrary test
version(mir_stat_test)
@safe pure nothrow
unittest 
{
    import mir.math.common: approxEqual;

    assert(interquartileRange(3.0, 1.0, 4.0, 2.0, 0.0).approxEqual(2.0));
}

// @nogc test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest 
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [1.0, 9.8, 0.2, 8.5, 5.8, 3.5, 4.5, 8.2, 5.2, 5.2,
                          2.5, 1.8, 2.2, 3.8, 5.2, 9.2, 6.2, 9.2, 9.2, 8.5];

    assert(x.sliced.interquartileRange.approxEqual(5.25));
}

/++
Calculates the median absolute deviation about the median of the input.

By default, if `F` is not floating point type, then the result will have a
`double` type if `F` is implicitly convertible to a floating point type.

Params:
    F = output type

Returns:
    The median absolute deviation of the input
+/
template medianAbsoluteDeviation(F)
{
    import mir.ndslice.slice: hasAsSlice;

    /++
    Params:
        slice = slice
    +/
    @fmamath meanType!F medianAbsoluteDeviation(Iterator, size_t N, SliceKind kind)(
            Slice!(Iterator, N, kind) slice)
    {
        import core.lifetime: move;
        import mir.math.common: fabs;
        import mir.ndslice.topology: map;
        import mir.stat.transform: center;

        alias G = typeof(return);
        static assert(isFloatingPoint!G, "medianAbsoluteDeviation: output type must be floating point");
        return slice.move.center!(median!(G, false)).map!fabs.median!(G, false);
    }
}

/// ditto
@fmamath meanType!(Slice!(Iterator, N, kind))
    medianAbsoluteDeviation(Iterator, size_t N, SliceKind kind)(
        Slice!(Iterator, N, kind) slice)
{
    import core.lifetime: move;

    alias F = typeof(return);
    return medianAbsoluteDeviation!F(slice.move);
}

/// ditto
@fmamath meanType!(T[]) medianAbsoluteDeviation(T)(scope const T[] ar...)
{
    import mir.ndslice.slice: sliced;

    alias G = typeof(return);
    return medianAbsoluteDeviation!G(ar.sliced);
}

/// ditto
@fmamath auto medianAbsoluteDeviation(SliceLike)(SliceLike x)
    if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
{
    import mir.ndslice.slice: toSlice;
    return medianAbsoluteDeviation(x.toSlice);
}

/// medianAbsoluteDeviation of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.medianAbsoluteDeviation.approxEqual(1.25));
}

// dynamic array test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.medianAbsoluteDeviation.approxEqual(1.25));
}

/// Median Absolute Deviation of matrix
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

    assert(x.medianAbsoluteDeviation.approxEqual(1.25));
}

/// Median Absolute Deviation of dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.medianAbsoluteDeviation.approxEqual(1.25));
}

// @nogc test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.medianAbsoluteDeviation.approxEqual(1.25));
}

// withAsSlice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    static immutable a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];

    assert(a.medianAbsoluteDeviation.approxEqual(1.25));
}

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
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind, sliced;

    static if (__traits(isSame, naryFun!transform, transform))
    {
        /++
        Params:
            slice = slice
        +/
        @fmamath auto dispersion(Iterator, size_t N, SliceKind kind)(
            Slice!(Iterator, N, kind) slice)
        {
            import mir.ndslice.topology: map;
            import mir.stat.transform: center;

            return summarize(slice.center!centralTendency.map!transform);
        }

        /// ditto
        @fmamath auto dispersion(T)(scope const T[] ar...)
        {
            return dispersion(ar.sliced);
        }

        /// ditto
        @fmamath auto dispersion(SliceLike)(SliceLike x)
            if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
        {
            import mir.ndslice.slice: toSlice;
            return dispersion(x.toSlice);
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
    import mir.complex: Complex;
    import mir.complex.math: capproxEqual = approxEqual;
    import mir.functional: naryFun;
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    alias C = Complex!double;

    assert(dispersion([1.0, 2, 3]).approxEqual(2.0 / 3));

    assert(dispersion([C(1.0, 3), C(2), C(3)]).capproxEqual(C(-4, -6) / 3));

    assert(dispersion!(mean!float, "a * a", mean!float)([0, 1, 2, 3, 4, 5].sliced(3, 2)).approxEqual(17.5 / 6));

    static assert(is(typeof(dispersion!(mean!float, "a ^^ 2", mean!float)([1, 2, 3])) == float));
}

/// Dispersion of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

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

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];
              
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

// mir.complex test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex: Complex;
    import mir.complex.math: approxEqual;
    import mir.ndslice.slice: sliced;

    alias C = Complex!double;

    auto x = [C(1.0, 2), C(2.0, 3), C(3.0, 4), C(4.0, 5)].sliced;
    assert(x.dispersion.approxEqual(C(0.0, 10.0) / 4));
}

// std.complex test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import std.complex: complex;
    import std.math.operations: isClose;

    auto x = [complex(1.0, 2), complex(2, 3), complex(3, 4), complex(4, 5)].sliced;
    assert(x.dispersion.isClose(complex(0.0, 10.0) / 4));
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
    import mir.ndslice.slice: sliced;
    import std.complex: Complex;
    import std.math.operations: isClose;

    auto x = [Complex!double(1, 2), Complex!double(2, 3), Complex!double(3, 4), Complex!double(4, 5)].sliced;
    assert(x.dispersion.isClose(Complex!double(0, 10) / 4));
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

// withAsSlice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    static immutable a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];

    assert(x.dispersion.approxEqual(54.76562 / 12));
}

/++
Skewness algorithms.

See_also:
    $(WEB en.wikipedia.org/wiki/Skewness, Skewness),
    $(WEB en.wikipedia.org/wiki/Algorithms_for_calculating_variance, Algorithms for calculating variance)
+/
enum SkewnessAlgo
{
    /++
    Similar to Welford's algorithm for updating variance, but adjusted for skewness.
    Can also `put` another SkewnessAccumulator of the same type, which
    uses the parallel algorithm from Terriberry that extends the work of Chan et
    al. 
    +/
    online,

    /++
    Calculates skewness using
    (E(x^^3) - 3 * mu * sigma ^^ 2 + mu ^^ 3) / (sigma ^^ 3)

    This algorithm can be numerically unstable.
    +/
    naive,

    /++
    Calculates skewness by first calculating the mean, then calculating
    E((x - E(x)) ^^ 3) / (E((x - E(x)) ^^ 2) ^^ 1.5)
    +/
    twoPass,

    /++
    Calculates skewness by first calculating the mean, then the standard deviation, then calculating
    E(((x - E(x)) / (E((x - E(x)) ^^ 2) ^^ 0.5)) ^^ 3)
    +/
    threePass,

    /++
    Calculates skewness assuming the mean of the input is zero. 
    +/
    assumeZeroMean,

    /++
    When slices, slice-like objects, or ranges are the inputs, uses the two-pass
    algorithm. When an individual data-point is added, uses the online algorithm.
    +/
    hybrid
}

///
struct SkewnessAccumulator(T, SkewnessAlgo skewnessAlgo, Summation summation)
    if (isMutable!T && skewnessAlgo == SkewnessAlgo.naive)
{
    import mir.functional: naryFun;
    import mir.math.sum: Summator;
    import std.traits: isIterable;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;
    ///
    alias S = Summator!(T, summation);
    ///
    private S summatorOfSquares;
    ///
    private S summatorOfCubes;

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
        T x2 = x * x;
        summatorOfSquares.put(x2);
        summatorOfCubes.put(x2 * x);
    }

    void put(U, Summation sumAlgo)(SkewnessAccumulator!(U, skewnessAlgo, sumAlgo) v)
    {
        meanAccumulator.put(v.meanAccumulator);
        summatorOfSquares.put(v.sumOfSquares!T);
        summatorOfCubes.put(v.sumOfCubes!T);
    }

const:

    ///
    size_t count() @property
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)() @property
    {
        return meanAccumulator.mean!F;
    }
    ///
    F variance(F = T)(bool isPopulation) @property
    in
    {
        assert(count > 1, "SkewnessAccumulator.varaince: count must be larger than one");
    }
    do
    {
        return sumOfSquares!F / (count + isPopulation - 1) - 
            mean!F * mean!F * count / (count + isPopulation - 1);
    }
    ///
    F sumOfCubes(F = T)()
    {
        return cast(F) summatorOfCubes.sum;
    }
    ///
    F sumOfSquares(F = T)()
    {
        return cast(F) summatorOfSquares.sum;
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return sumOfSquares!F - count * mean!F * mean!F;
    }
    ///
    F centeredSumOfCubes(F = T)()
    {
        F mu = mean!F;
        return sumOfCubes!F - 3 * mu * sumOfSquares!F + 2 * count * mu * mu * mu;
    }
    ///
    F scaledSumOfCubes(F = T)(bool isPopulation)
    {
        import mir.math.common: sqrt;
        F var = variance!F(isPopulation);
        return centeredSumOfCubes!F / (var * var.sqrt);
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");
        assert(variance(true) > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");
    }
    do
    {
        import mir.math.common: sqrt;

        return scaledSumOfCubes!F(isPopulation) * count /
            ((count + isPopulation - 1) * (count + 2 * isPopulation - 2));
        /+ equivalent to
        F mu = mean!F;
        F avg_centeredSumOfCubes = sumOfCubes!F / count - 3 * mu * variance!F(true) - (mu * mu * mu);
        F var = variance!F(isPopulation);
        return avg_centeredSumOfCubes / (var * var.sqrt) *
                (cast(F) count * count / ((count + isPopulation - 1) * (count + 2 * isPopulation - 2)));
        +/
    }
}

/// naive
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    SkewnessAccumulator!(double, SkewnessAlgo.naive, Summation.naive) v;
    v.put(x);
    v.skewness(true).shouldApprox == (117.005859 / 12) / pow(54.765625 / 12, 1.5);
    v.skewness(false).shouldApprox == (117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0);

    v.put(4.0);
    v.skewness(true).shouldApprox == (100.238166 / 13) / pow(57.019231 / 13, 1.5);
    v.skewness(false).shouldApprox == (100.238166 / 13) / pow(57.019231 / 12, 1.5) * (13.0 ^^ 2) / (12.0 * 11.0);
}

// check two-dimensional
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: pow;
    import mir.math.sum: Summation;
    import mir.ndslice.fuse: fuse;
    import mir.test: shouldApprox;

    auto x = [[0.0, 1.0, 1.5, 2.0, 3.5, 4.25],
              [2.0, 7.5, 5.0, 1.0, 1.5, 0.00]].fuse;

    SkewnessAccumulator!(double, SkewnessAlgo.naive, Summation.naive) v;
    v.put(x);
    v.skewness(true).shouldApprox == (117.005859 / 12) / pow(54.765625 / 12, 1.5);
    v.skewness(false).shouldApprox == (117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0);
}

// Can put SkewnessAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: pow;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    SkewnessAccumulator!(double, SkewnessAlgo.naive, Summation.naive) v;
    v.put(x);
    SkewnessAccumulator!(double, SkewnessAlgo.naive, Summation.naive) w;
    w.put(y);
    v.put(w);
    v.skewness(true).shouldApprox == (117.005859 / 12) / pow(54.765625 / 12, 1.5);
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.range: iota;
    import std.algorithm: map;

    auto x1 = iota(0, 5);
    auto v1 = SkewnessAccumulator!(double, SkewnessAlgo.naive, Summation.naive)(x1);
    v1.skewness(true).should == 0;
    auto x2 = x1.map!(a => 2 * a);
    auto v2 = SkewnessAccumulator!(double, SkewnessAlgo.naive, Summation.naive)(x2);
    v2.skewness(true).should == 0;
}

///
struct SkewnessAccumulator(T, SkewnessAlgo skewnessAlgo, Summation summation)
    if (isMutable!T && skewnessAlgo == SkewnessAlgo.online)
{
    import mir.math.sum: Summator;
    import std.traits: isIterable;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;
    ///
    alias S = Summator!(T, summation);
    ///
    private S centeredSummatorOfSquares;
    ///
    private S centeredSummatorOfCubes;

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
            deltaOld -= mean;
        }
        meanAccumulator.put(x);
        T deltaNew = x - mean;
        centeredSummatorOfCubes.put(deltaOld * deltaOld * deltaOld * (count - 1) * (count - 2) / (count * count) -
                                    3 * deltaOld * centeredSumOfSquares / count);
        centeredSummatorOfSquares.put(deltaOld * deltaNew);
    }

    ///
    void put(U, SkewnessAlgo skewAlgo, Summation sumAlgo)(SkewnessAccumulator!(U, skewAlgo, sumAlgo) v)
        if(!is(skewAlgo == SkewnessAlgo.assumeZeroMean))
    {
        size_t oldCount = count;
        T delta = v.mean;
        if (oldCount > 0) {
            delta -= mean;
        }
        meanAccumulator.put!T(v.meanAccumulator);
        centeredSummatorOfCubes.put(v.centeredSumOfCubes!T + 
                                    delta * delta * delta * v.count * oldCount * (oldCount - v.count) / (count * count) +
                                    3 * delta * (oldCount * v.centeredSumOfSquares!T - v.count * centeredSumOfSquares!T) / count);
        centeredSummatorOfSquares.put(v.centeredSumOfSquares!T + delta * delta * v.count * oldCount / count);
    }

const:

    ///
    size_t count() @property
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)() @property
    {
        return meanAccumulator.mean!F;
    }
    ///
    F variance(F = T)(bool isPopulation) @property
    in
    {
        assert(count > 1, "SkewnessAccumulator.variance: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F centeredSumOfCubes(F = T)()
    {
        return cast(F) centeredSummatorOfCubes.sum;
    }
    ///
    F scaledSumOfCubes(F = T)(bool isPopulation)
    {
        import mir.math.common: sqrt;
        F var = variance!F(isPopulation);
        return centeredSumOfCubes!F / (var * var.sqrt);
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");
        assert(centeredSummatorOfSquares.sum > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");
    }
    do
    {
        import mir.math.common: sqrt;
        F s = centeredSumOfSquares!F;
        return centeredSumOfCubes!F / (s * s.sqrt) * count * sqrt(cast(F) count + isPopulation - 1) /
            (count + 2 * isPopulation - 2);
        /+ Equivalent to
        return scaledSumOfCubes!F(isPopulation) / count *
                (cast(F) count * count / ((count + isPopulation - 1) * (count + 2 * isPopulation - 2)));
        +/
    }
}

/// online
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.skewness(true).approxEqual((117.005859 / 12) / pow(54.765625 / 12, 1.5)));
    assert(v.skewness(false).approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));

    v.put(4.0);
    assert(v.skewness(true).approxEqual((100.238166 / 13) / pow(57.019231 / 13, 1.5)));
    assert(v.skewness(false).approxEqual((100.238166 / 13) / pow(57.019231 / 12, 1.5) * (13.0 ^^ 2) / (12.0 * 11.0)));
}

// Can put slice
version(mir_stat_test)
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
    assert(v.centeredSumOfCubes.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    v.put(y);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfCubes.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator (naive)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfCubes.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    SkewnessAccumulator!(double, SkewnessAlgo.naive, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator (twoPass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfCubes.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = SkewnessAccumulator!(double, SkewnessAlgo.twoPass, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator (threePass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfCubes.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = SkewnessAccumulator!(double, SkewnessAlgo.threePass, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator (assumeZeroMean)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto b = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;
    auto y = b.center;

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) v;
    v.put(x);
    auto w = SkewnessAccumulator!(double, SkewnessAlgo.assumeZeroMean, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(84.015625)); //note: different from above due to inconsistent centering
    assert(v.centeredSumOfSquares.approxEqual(52.885417)); //note: different from above due to inconsistent centering
}

// check variance/scaledSumOfCubes
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive) v;
    v.put(x);
    auto varP = x.variance!"online"(true);
    auto varS = x.variance!"online"(false);
    v.variance(true).shouldApprox == varP;
    v.variance(false).shouldApprox == varS;
    v.scaledSumOfCubes(true).shouldApprox == v.centeredSumOfCubes / (varP * varP.sqrt);
    v.scaledSumOfCubes(false).shouldApprox == v.centeredSumOfCubes / (varS * varS.sqrt);
}

///
struct SkewnessAccumulator(T, SkewnessAlgo skewnessAlgo, Summation summation)
    if (isMutable!T && skewnessAlgo == SkewnessAlgo.twoPass)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import std.range: isInputRange;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;
    ///
    alias S = Summator!(T, summation);
    ///
    private S centeredSummatorOfSquares;
    ///
    private S centeredSummatorOfCubes;

    ///
    this(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
    {
        import mir.functional: naryFun;
        import mir.ndslice.topology: vmap, map;
        import mir.ndslice.internal: LeftOp;

        meanAccumulator.put(slice.lightScope);

        auto sliceMap = slice.vmap(LeftOp!("-", T)(mean)).map!(naryFun!"a * a", naryFun!"a * a * a");
        centeredSummatorOfSquares.put(sliceMap.map!"a[0]");
        centeredSummatorOfCubes.put(sliceMap.map!"a[1]");
    }

    ///
    this(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice);
    }

    ///
    this(Range)(Range range)
        if (isInputRange!Range && !isConvertibleToSlice!Range && is(elementType!Range : T))
    {
        import std.algorithm: map;
        meanAccumulator.put(range);

        auto centeredRangeMultiplier = range.map!(a => (a - mean)).map!("a * a", "a * a * a");
        centeredSummatorOfSquares.put(centeredRangeMultiplier.map!"a[0]");
        centeredSummatorOfCubes.put(centeredRangeMultiplier.map!"a[1]");
    }

const:

    ///
    size_t count()()
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)()
    {
        return meanAccumulator.mean!F;
    }
    ///
    F variance(F = T)(bool isPopulation)
    in
    {
        assert(count > 1, "SkewnessAccumulator.variance: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F centeredSumOfCubes(F = T)()
    {
        return cast(F) centeredSummatorOfCubes.sum;
    }
    ///
    F scaledSumOfCubes(F = T)(bool isPopulation)
    {
        import mir.math.common: sqrt;
        F var = variance!F(isPopulation);
        return centeredSumOfCubes!F / (var * var.sqrt);
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");
        assert(centeredSummatorOfSquares.sum > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");
    }
    do
    {
        import mir.math.common: sqrt;
        F s = centeredSumOfSquares!F;
        return centeredSumOfCubes!F / (s * s.sqrt) * count * sqrt(cast(F) count + isPopulation - 1) /
            (count + 2 * isPopulation - 2);
        /+ Equivalent to
        return scaledSumOfCubes!F(isPopulation) / count *
                (cast(F) count * count / ((count + isPopulation - 1) * (count + 2 * isPopulation - 2)));
        +/
    }
}

/// twoPass
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.twoPass, Summation.naive)(x);
    assert(v.skewness(true).approxEqual(12.000999 / 12));
    assert(v.skewness(false).approxEqual(12.000999 / 12 * sqrt(12.0 * 11.0) / 10.0));
}

// check withAsSlice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.rc.array: RCArray;
    import mir.test: shouldApprox;

    static immutable a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.twoPass, Summation.naive)(x);
    v.scaledSumOfCubes(true).shouldApprox == 12.000999;
}

// check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: shouldApprox;

    double[] x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                  2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.twoPass, Summation.naive)(x);
    v.scaledSumOfCubes(true).shouldApprox == 12.000999;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.range: iota;
    import std.algorithm: map;

    auto x1 = iota(0, 5);
    auto v1 = SkewnessAccumulator!(double, SkewnessAlgo.twoPass, Summation.naive)(x1);
    v1.skewness(true).should == 0;
    auto x2 = x1.map!(a => 2 * a);
    auto v2 = SkewnessAccumulator!(double, SkewnessAlgo.twoPass, Summation.naive)(x2);
    v2.skewness(true).should == 0;
}

///
struct SkewnessAccumulator(T, SkewnessAlgo skewnessAlgo, Summation summation)
    if (isMutable!T && skewnessAlgo == SkewnessAlgo.threePass)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import std.range: isInputRange;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;
    ///
    alias S = Summator!(T, summation);
    ///
    private S centeredSummatorOfSquares;
    ///
    private S scaledSummatorOfCubes;

    ///
    this(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
    {
        import mir.functional: naryFun;
        import mir.ndslice.topology: vmap, map;
        import mir.ndslice.internal: LeftOp;
        import mir.math.common: sqrt;

        meanAccumulator.put(slice.lightScope);
        centeredSummatorOfSquares.put(slice.vmap(LeftOp!("-", T)(mean)).map!(naryFun!"a * a"));

        T stdP = variance!T(true).sqrt;
        assert(stdP > 0, "SkewnessAccumulator.this: must divide by positive standard deviation");

        scaledSummatorOfCubes.put(slice.
            vmap(LeftOp!("-", T)(mean)).
            vmap(LeftOp!("*", T)(1 / stdP)).
            map!(naryFun!"a * a * a"));
    }

    ///
    this(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice);
    }

    ///
    this(Range)(Range range)
        if (isInputRange!Range && !isConvertibleToSlice!Range && is(elementType!Range : T))
    {
        import mir.math.common: sqrt;
        import std.algorithm: map;

        meanAccumulator.put(range);
        auto centeredRange = range.map!(a => (a - mean));
        centeredSummatorOfSquares.put(centeredRange.map!"a * a");
        T stdP = variance!T(true).sqrt;
        auto scaledRange = centeredRange.map!(a => a / stdP);
        scaledSummatorOfCubes.put(scaledRange.map!"a * a * a");
    }

const:

    ///
    size_t count()()
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)()
    {
        return meanAccumulator.mean!F;
    }
    ///
    F variance(F = T)(bool isPopulation)
    in
    {
        assert(count > 1, "SkewnessAccumulator.variance: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F centeredSumOfCubes(F = T)()
    {
        import mir.math.common: sqrt;
        F varP = variance!F(true); // based on using the population variance as divisor above
        return scaledSumOfCubes!F * varP * varP.sqrt;
    }
    ///
    F scaledSumOfCubes(F = T)()
    {
        return cast(F) scaledSummatorOfCubes.sum;
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");
    }
    do
    {
        // formula for other skewness accumulators doesn't work here since we are
        // enforcing the the scaledSumOfCubes uses population variance and not that it can switch
        import mir.math.common: sqrt;
        return scaledSumOfCubes!F / (count + 2 * isPopulation - 2) *
                sqrt(cast(F) (count + isPopulation - 1) / count);
        /+ Equivalent to
        return scaledSumOfCubes!F / count * 
                sqrt(cast(F) count * (count + isPopulation - 1)) / (count + 2 * isPopulation - 2)
        +/
    }
}

/// threePass
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.threePass, Summation.naive)(x);
    assert(v.skewness(true).approxEqual(12.000999 / 12));
    assert(v.skewness(false).approxEqual(12.000999 / 12 * sqrt(12.0 * 11.0) / 10.0));
}

// check withAsSlice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.math.sum: Summation;
    import mir.rc.array: RCArray;

    static immutable a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.threePass, Summation.naive)(x);
    assert(v.scaledSumOfCubes.approxEqual(12.000999));
}

// check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.math.sum: Summation;

    double[] x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                  2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.threePass, Summation.naive)(x);
    assert(v.scaledSumOfCubes.approxEqual(12.000999));
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.range: iota;
    import std.algorithm: map;

    auto x1 = iota(0, 5);
    auto v1 = SkewnessAccumulator!(double, SkewnessAlgo.threePass, Summation.naive)(x1);
    v1.skewness(true).should == 0;
    auto x2 = x1.map!(a => 2 * a);
    auto v2 = SkewnessAccumulator!(double, SkewnessAlgo.threePass, Summation.naive)(x2);
    v2.skewness(true).should == 0;
}

///
struct SkewnessAccumulator(T, SkewnessAlgo skewnessAlgo, Summation summation)
    if (isMutable!T && skewnessAlgo == SkewnessAlgo.assumeZeroMean)
{
    import mir.math.sum: Summator;
    import std.traits: isIterable;

    ///
    private size_t _count;
    ///
    alias S = Summator!(T, summation);
    ///
    private S centeredSummatorOfSquares;
    ///
    private S centeredSummatorOfCubes;

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
        _count++;
        T x2 = x * x;
        centeredSummatorOfSquares.put(x2);
        centeredSummatorOfCubes.put(x2 * x);
    }

    ///
    void put(U, Summation sumAlgo)(SkewnessAccumulator!(U, skewnessAlgo, sumAlgo) v)
    {
        _count += v.count;
        centeredSummatorOfSquares.put(v.centeredSumOfSquares!T);
        centeredSummatorOfCubes.put(v.centeredSumOfCubes!T);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F mean(F = T)() @property
    {
        return cast(F) 0;
    }
    ///
    F variance(F = T)(bool isPopulation) @property
    in
    {
        assert(count > 1, "SkewnessAccumulator.variance: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
    MeanAccumulator!(T, summation) meanAccumulator()()
    {
        typeof(return) m = { _count, T(0) };
        return m;
    }
    ///
    F centeredSumOfCubes(F = T)() @property
    {
        return cast(F) centeredSummatorOfCubes.sum;
    }
    ///
    F centeredSumOfSquares(F = T)() @property
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F scaledSumOfCubes(F = T)(bool isPopulation) @property
    {
        import mir.math.common: sqrt;

        F var = variance!F(isPopulation);
        return centeredSumOfCubes!F / (var * var.sqrt);
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");
        assert(centeredSummatorOfSquares.sum > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");
    }
    do
    {
        import mir.math.common: sqrt;
        F s = centeredSumOfSquares!F;
        return centeredSumOfCubes!F / (s * s.sqrt) * count * sqrt(cast(F) count + isPopulation - 1) /
            (count + 2 * isPopulation - 2);
        /+ Equivalent to
        return scaledSumOfCubes!F(isPopulation) / count *
                (cast(F) count * count / ((count + isPopulation - 1) * (count + 2 * isPopulation - 2)));
        +/
    }
}

/// assumeZeroMean
version(mir_stat_test)
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

    SkewnessAccumulator!(double, SkewnessAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.skewness(true).approxEqual((117.005859 / 12) / pow(54.765625 / 12, 1.5)));
    assert(v.skewness(false).approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * 12.0 ^^ 2 / (11.0 * 10.0)));

    v.put(4.0);
    assert(v.skewness(true).approxEqual((181.005859 / 13) / pow(70.765625 / 13, 1.5)));
    assert(v.skewness(false).approxEqual((181.005859 / 13) / pow(70.765625 / 12, 1.5) * 13.0 ^^ 2 / (12.0 * 11.0)));
}

// Can put slices
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = a.center;
    auto x = b[0 .. 6];
    auto y = b[6 .. $];

    SkewnessAccumulator!(double, SkewnessAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfCubes.approxEqual(-11.206543));
    assert(v.centeredSumOfSquares.approxEqual(13.49219));

    v.put(y);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = a.center;
    auto x = b[0 .. 6];
    auto y = b[6 .. $];

    SkewnessAccumulator!(double, SkewnessAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfCubes.approxEqual(-11.206543));
    assert(v.centeredSumOfSquares.approxEqual(13.49219));

    SkewnessAccumulator!(double, SkewnessAlgo.assumeZeroMean, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// check variance/scaledSumOfCubes
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;
    import mir.test: shouldApprox;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;

    SkewnessAccumulator!(double, SkewnessAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    auto varP = x.variance!"assumeZeroMean"(true);
    auto varS = x.variance!"assumeZeroMean"(false);
    v.variance(true).shouldApprox == varP;
    v.variance(false).shouldApprox == varS;
    v.scaledSumOfCubes(true).shouldApprox == v.centeredSumOfCubes / (varP * varP.sqrt);
    v.scaledSumOfCubes(false).shouldApprox == v.centeredSumOfCubes / (varS * varS.sqrt);
}

///
struct SkewnessAccumulator(T, SkewnessAlgo skewnessAlgo, Summation summation)
    if (isMutable!T && skewnessAlgo == SkewnessAlgo.hybrid)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import std.range: isInputRange;
    import std.traits: isIterable;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;
    ///
    alias S = Summator!(T, summation);
    ///
    private S centeredSummatorOfSquares;
    ///
    private S centeredSummatorOfCubes;

    ///
    this(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
    {
        import mir.functional: naryFun;
        import mir.ndslice.topology: vmap, map;
        import mir.ndslice.internal: LeftOp;

        meanAccumulator.put(slice.lightScope);

        auto sliceMap = slice.vmap(LeftOp!("-", T)(mean)).map!(naryFun!"a * a", naryFun!"a * a * a");
        centeredSummatorOfSquares.put(sliceMap.map!"a[0]");
        centeredSummatorOfCubes.put(sliceMap.map!"a[1]");
    }

    ///
    this(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice);
    }

    ///
    this(Range)(Range range)
        if (isIterable!Range && !isConvertibleToSlice!Range)
    {
        static if (isInputRange!Range && is(elementType!Range : T)) {
            import std.algorithm: map;
            meanAccumulator.put(range);

            auto centeredRangeMultiplier = range.map!(a => (a - mean)).map!("a * a", "a * a * a");
            centeredSummatorOfSquares.put(centeredRangeMultiplier.map!"a[0]");
            centeredSummatorOfCubes.put(centeredRangeMultiplier.map!"a[1]");
        } else {
            this.put(range);
        }
    }

    ///
    this()(T x)
    {
        this.put(x);
    }

    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        static if (isInputRange!Range && is(elementType!Range : T)) {
            auto v = typeof(this)(r);
            this.put(v);
        } else {
            foreach(x; r)
            {
                this.put(x);
            }
        }
    }

    ///
    void put()(T x)
    {
        T deltaOld = x;
        if (count > 0) {
            deltaOld -= mean;
        }
        meanAccumulator.put(x);
        T deltaNew = x - mean;
        centeredSummatorOfCubes.put(deltaOld * deltaOld * deltaOld * (count - 1) * (count - 2) / (count * count) -
                                    3 * deltaOld * centeredSumOfSquares / count);
        centeredSummatorOfSquares.put(deltaOld * deltaNew);
    }

    ///
    void put(U, SkewnessAlgo skewAlgo, Summation sumAlgo)(SkewnessAccumulator!(U, skewAlgo, sumAlgo) v)
        if(!is(skewAlgo == SkewnessAlgo.assumeZeroMean))
    {
        size_t oldCount = count;
        T delta = v.mean;
        if (oldCount > 0) {
            delta -= mean;
        }
        meanAccumulator.put!T(v.meanAccumulator);
        centeredSummatorOfCubes.put(v.centeredSumOfCubes!T + 
                                    delta * delta * delta * v.count * oldCount * (oldCount - v.count) / (count * count) +
                                    3 * delta * (oldCount * v.centeredSumOfSquares!T - v.count * centeredSumOfSquares!T) / count);
        centeredSummatorOfSquares.put(v.centeredSumOfSquares!T + delta * delta * v.count * oldCount / count);
    }

const:

    ///
    size_t count() @property
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)() @property
    {
        return meanAccumulator.mean!F;
    }
    ///
    F variance(F = T)(bool isPopulation) @property
    in
    {
        assert(count > 1, "SkewnessAccumulator.variance: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F centeredSumOfCubes(F = T)()
    {
        return cast(F) centeredSummatorOfCubes.sum;
    }
    ///
    F scaledSumOfCubes(F = T)(bool isPopulation)
    {
        import mir.math.common: sqrt;
        F var = variance!F(isPopulation);
        return centeredSumOfCubes!F / (var * var.sqrt);
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");
        assert(centeredSummatorOfSquares.sum > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");
    }
    do
    {
        import mir.math.common: sqrt;
        F s = centeredSumOfSquares!F;
        return centeredSumOfCubes!F / (s * s.sqrt) * count * sqrt(cast(F) count + isPopulation - 1) /
            (count + 2 * isPopulation - 2);
        /+ Equivalent to
        return scaledSumOfCubes!F(isPopulation) / count *
                (cast(F) count * count / ((count + isPopulation - 1) * (count + 2 * isPopulation - 2)));
        +/
    }
}

/// hybrid
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x);
    assert(v.skewness(true).approxEqual((117.005859 / 12) / pow(54.765625 / 12, 1.5)));
    assert(v.skewness(false).approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));

    v.put(4.0);
    assert(v.skewness(true).approxEqual((100.238166 / 13) / pow(57.019231 / 13, 1.5)));
    assert(v.skewness(false).approxEqual((100.238166 / 13) / pow(57.019231 / 12, 1.5) * (13.0 ^^ 2) / (12.0 * 11.0)));
}

// check withAsSlice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.rc.array: RCArray;
    import mir.test: shouldApprox;

    static immutable a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x);
    v.scaledSumOfCubes(true).shouldApprox == 12.000999;
}

// check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: shouldApprox;

    double[] x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                  2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x);
    v.scaledSumOfCubes(true).shouldApprox == 12.000999;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.algorithm: map;
    import std.range: chunks, iota;

    auto x1 = iota(0, 5);
    auto v1 = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x1);
    v1.skewness(true).should == 0;
    auto x2 = x1.map!(a => 2 * a);
    auto v2 = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x2);
    v2.skewness(true).should == 0;
    SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive) v3;
    v3.put(x1.chunks(1));
    v3.skewness(true).should == 0;
    auto v4 = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x1.chunks(1));
    v4.skewness(true).should == 0;
}

// Can put slice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x);
    assert(v.centeredSumOfCubes.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    v.put(y);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x);
    assert(v.centeredSumOfCubes.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator (naive)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x);
    assert(v.centeredSumOfCubes.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = SkewnessAccumulator!(double, SkewnessAlgo.naive, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator (online)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x);
    assert(v.centeredSumOfCubes.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = SkewnessAccumulator!(double, SkewnessAlgo.online, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator (twoPass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x);
    assert(v.centeredSumOfCubes.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = SkewnessAccumulator!(double, SkewnessAlgo.twoPass, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator (threePass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x);
    assert(v.centeredSumOfCubes.approxEqual(4.071181));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = SkewnessAccumulator!(double, SkewnessAlgo.threePass, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(117.005859));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put SkewnessAccumulator (assumeZeroMean)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto b = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;
    auto y = b.center;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x);
    auto w = SkewnessAccumulator!(double, SkewnessAlgo.assumeZeroMean, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfCubes.approxEqual(84.015625)); //note: different from above due to inconsistent centering
    assert(v.centeredSumOfSquares.approxEqual(52.885417)); //note: different from above due to inconsistent centering
}

// check variance/scaledSumOfCubes
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = SkewnessAccumulator!(double, SkewnessAlgo.hybrid, Summation.naive)(x);
    auto varP = x.variance!"twoPass"(true);
    auto varS = x.variance!"twoPass"(false);
    v.variance(true).shouldApprox == varP;
    v.variance(false).shouldApprox == varS;
    v.scaledSumOfCubes(true).shouldApprox == v.centeredSumOfCubes / (varP * varP.sqrt);
    v.scaledSumOfCubes(false).shouldApprox == v.centeredSumOfCubes / (varS * varS.sqrt);
}

/++
Calculates the skewness of the input

By default, if `F` is not floating point type, then the result will have a
`double` type if `F` is implicitly convertible to a floating point type.

Params:
    F = controls type of output
    skewnessAlgo = algorithm for calculating skewness (default: SkewnessAlgo.hybrid)
    summation = algorithm for calculating sums (default: Summation.appropriate)

Returns:
    The skewness of the input, must be floating point or complex type

See_also:
    $(LREF SkewnessAlgo)
+/
template skewness(F, 
                  SkewnessAlgo skewnessAlgo = SkewnessAlgo.hybrid, 
                  Summation summation = Summation.appropriate)
{
    import std.traits: isIterable;

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
template skewness(SkewnessAlgo skewnessAlgo = SkewnessAlgo.hybrid, 
                  Summation summation = Summation.appropriate)
{
    import std.traits: isIterable;

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
version(mir_stat_test)
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
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.skewness.approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));
}

/// Skewness of matrix
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

    assert(x.skewness.approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));
}

/// Column skewness of matrix
version(mir_stat_test)
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
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual, pow, sqrt;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto x = a + 100_000_000_000;

    // The online algorithm is numerically unstable in this case
    auto y = x.skewness!"online";
    assert(!y.approxEqual((117.005859 / 12) / pow(54.765625 / 11, 1.5) * (12.0 ^^ 2) / (11.0 * 10.0)));

    // The naive algorithm has an assert error in this case because standard
    // deviation is calculated naively as zero. The skewness formula would then
    // be dividing by zero. 
    //auto z0 = x.skewness!(real, "naive");

    // However, the two-pass and three-pass algorithms are numerically stable in this case
    auto z1 = x.skewness!"twoPass";
    assert(z1.approxEqual(12.000999 / 12 * sqrt(12.0 * 11.0) / 10.0));
    assert(!z1.approxEqual(y));
    auto z2 = x.skewness!"threePass";
    assert(z2.approxEqual((12.000999 / 12) * sqrt(12.0 * 11.0) / 10.0));
    assert(!z2.approxEqual(y));

    // And the assumeZeroMean algorithm provides the incorrect answer, as expected
    auto z3 = x.skewness!"assumeZeroMean";
    assert(!z3.approxEqual(y));
}

// Alt version with x a tenth of above's value
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual, pow, sqrt;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto x = a + 10_000_000_000;

    // The online algorithm is numerically stable in this case
    auto y = x.skewness!"online";
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
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;

    //Set population skewness, skewness algorithm, sum algorithm or output type

    auto a = [1.0, 1e98, 1, -1e98].sliced;
    auto x = a * 10_000;

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean 
    from the second and fourth numbers has no effect. Further, after centering 
    and squaring `x`, the first and third numbers in the slice have precision 
    too low to be included in the centered sum of squares. 
    +/
    assert(x.skewness(false).approxEqual(0.0));
    assert(x.skewness(true).approxEqual(0.0));

    assert(x.skewness!("online").approxEqual(0.0));
    assert(x.skewness!("online", "kbn").approxEqual(0.0));
    assert(x.skewness!("online", "kb2").approxEqual(0.0));
    assert(x.skewness!("online", "precise").approxEqual(0.0));
    assert(x.skewness!(double, "online", "precise").approxEqual(0.0));
    assert(x.skewness!(double, "online", "precise")(true).approxEqual(0.0));

    auto y = [uint.max - 2, uint.max - 1, uint.max].sliced;
    auto z = y.skewness!(ulong, "threePass");
    assert(z == 0.0);
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

    auto y = x.skewness;
    assert(y.approxEqual(0.925493));
    static assert(is(typeof(y) == double));

    assert(x.skewness!float.approxEqual(0.925493));
}

/++
Skewness works for other user-defined types (provided they
can be converted to a floating point)
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    static struct Foo {
        float x;
        alias x this;
    }

    Foo[] foo = [Foo(1f), Foo(2f), Foo(3f)];
    assert(foo.skewness == 0f);
}

/// Compute skewness along specified dimention of tensors
version(mir_stat_test)
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
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    assert(skewness(1.0, 2, 3) == 0.0);
    assert(skewness!float(1, 2, 3) == 0f);
}

// Check skewness vector UFCS
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    assert([1.0, 2, 3, 4].skewness.approxEqual(0.0));
}

// Double-check correct output types
version(mir_stat_test)
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
version(mir_stat_test)
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
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.stat.transform: center;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.skewness.approxEqual(1.149008));
    assert(x.skewness(true).approxEqual(1.000083));
    assert(x.skewness!"naive".approxEqual(1.149008));
    assert(x.skewness!"naive"(true).approxEqual(1.000083));
    assert(x.skewness!"online".approxEqual(1.149008));
    assert(x.skewness!"online"(true).approxEqual(1.000083));
    assert(x.skewness!"twoPass".approxEqual(1.149008));
    assert(x.skewness!"twoPass"(true).approxEqual(1.000083));
    assert(x.skewness!"threePass".approxEqual(1.149008));
    assert(x.skewness!"threePass"(true).approxEqual(1.000083));

    auto y = x.center;
    assert(y.skewness!"assumeZeroMean".approxEqual(1.149008));
    assert(y.skewness!"assumeZeroMean"(true).approxEqual(1.000083));
}

// compile with dub test --build=unittest-perf --config=unittest-perf --compiler=ldc2
version(mir_stat_test_skew_performance)
unittest
{
    import mir.math.sum: Summation;
    import mir.math.internal.benchmark;
    import std.stdio: writeln;
    import std.traits: EnumMembers;

    template staticMap(alias fun, alias S, args...)
    {
        import std.meta: AliasSeq;
        alias staticMap = AliasSeq!();
        static foreach (arg; args)
            staticMap = AliasSeq!(staticMap, fun!(double, arg, S));
    }

    size_t n = 10_000;
    size_t m = 1_000;

    alias S = Summation.fast;
    alias E = EnumMembers!SkewnessAlgo;
    alias fs = staticMap!(skewness, S, E);
    double[fs.length] output;

    auto e = [E];
    auto time = benchmarkRandom!(fs)(n, m, output);
    writeln("Skewness performance test");
    foreach (size_t i; 0 .. fs.length) {
        writeln("Function ", i + 1, ", Algo: ", e[i], ", Output: ", output[i], ", Elapsed time: ", time[i]);
    }
    writeln();
}

/++
Kurtosis algorithms.

See_also:
    $(WEB en.wikipedia.org/wiki/Kurtosis, Kurtosis),
    $(WEB en.wikipedia.org/wiki/Algorithms_for_calculating_variance, Algorithms for calculating variance)
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
    (allowing for adjustments for population/sample kurtosis). 

    This algorithm can be numerically unstable.
    +/
    naive,

    /++
    Calculates kurtosis by first calculating the mean, then calculating
    E((x - E(x)) ^^ 4) / (E((x - E(x)) ^^ 2) ^^ 2)
    +/
    twoPass,

    /++
    Calculates kurtosis by first calculating the mean, then the standard deviation, then calculating
    E(((x - E(x)) / (E((x - E(x)) ^^ 2) ^^ 0.5)) ^^ 4)
    +/
    threePass,

    /++
    Calculates kurtosis assuming the mean of the input is zero. 
    +/
    assumeZeroMean,

    /++
    When slices, slice-like objects, or ranges are the inputs, uses the two-pass
    algorithm. When an individual data-point is added, uses the online algorithm.
    +/
    hybrid
}

// Make sure skew algos and kurtosis algos match up
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import std.conv: to;
    assert(SkewnessAlgo.online.to!int == KurtosisAlgo.online.to!int);
    assert(SkewnessAlgo.naive.to!int == KurtosisAlgo.naive.to!int);
    assert(SkewnessAlgo.twoPass.to!int == KurtosisAlgo.twoPass.to!int);
    assert(SkewnessAlgo.threePass.to!int == KurtosisAlgo.threePass.to!int);
    assert(SkewnessAlgo.assumeZeroMean.to!int == KurtosisAlgo.assumeZeroMean.to!int);
    assert(SkewnessAlgo.hybrid.to!int == KurtosisAlgo.hybrid.to!int);
}

///
struct KurtosisAccumulator(T, KurtosisAlgo kurtosisAlgo, Summation summation)
    if (isMutable!T && kurtosisAlgo == KurtosisAlgo.naive)
{
    import mir.math.sum: Summator;
    import std.traits: isIterable;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;
    ///
    alias S = Summator!(T, summation);
    ///
    private S summatorOfSquares;
    ///
    private S summatorOfCubes;
    ///
    private S summatorOfQuarts;

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
        T x2 = x * x;
        summatorOfSquares.put(x2);
        summatorOfCubes.put(x2 * x);
        summatorOfQuarts.put(x2 * x2);
    }

    ///
    void put(U, Summation sumAlgo)(KurtosisAccumulator!(U, kurtosisAlgo, sumAlgo) v)
    {
        meanAccumulator.put(v.meanAccumulator);
        summatorOfSquares.put(v.sumOfSquares!T);
        summatorOfCubes.put(v.sumOfCubes!T);
        summatorOfQuarts.put(v.sumOfQuarts!T);
    }

const:
    ///
    size_t count()
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)()
    {
        return meanAccumulator.mean!F;
    }
    ///
    F variance(F = T)(bool isPopulation) @property
    in
    {
        assert(count > 1, "SkewnessAccumulator.varaince: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
    ///
    F sumOfSquares(F = T)()
    {
        return cast(F) summatorOfSquares.sum;
    }
    ///
    F sumOfCubes(F = T)()
    {
        return cast(F) summatorOfCubes.sum;
    }
    ///
    F sumOfQuarts(F = T)()
    {
        return cast(F) summatorOfQuarts.sum;
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return sumOfSquares!F - count * mean!F * mean!F;
    }
    ///
    F centeredSumOfCubes(F = T)()
    {
        F mu = mean!F;
        return sumOfCubes!F - 3 * mu * sumOfSquares!F + 2 * count * mu * mu * mu;
    }
    ///
    F centeredSumOfQuarts(F = T)()
    {
        F mu = mean!F;
        F mu2 = mu * mu;
        return sumOfQuarts!F - 4 * mu * sumOfCubes!F + 6 * mu2 * sumOfSquares!F - 3 * count * mu2 * mu2;
    }
    ///
    F scaledSumOfCubes(F = T)(bool isPopulation)
    {
        import mir.math.common: sqrt;
        F var = variance!F(isPopulation);
        return centeredSumOfCubes!F / (var * var.sqrt);
    }
    ///
    F scaledSumOfQuarts(F = T)(bool isPopulation)
    {
        F var = variance!F(isPopulation);
        return centeredSumOfQuarts!F / (var * var);
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");
        assert(centeredSumOfSquares > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");
    }
    do
    {
        import mir.math.common: sqrt;
        F s = centeredSumOfSquares!F;
        return centeredSumOfCubes!F / (s * s.sqrt) * count * sqrt(cast(F) count + isPopulation - 1) /
            (count + 2 * isPopulation - 2);
        /+ Equivalent to
        return scaledSumOfCubes!F(isPopulation) / count *
                (cast(F) count * count / ((count + isPopulation - 1) * (count + 2 * isPopulation - 2)));
        +/
    }
    ///
    F kurtosis(F = T)(bool isPopulation, bool isRaw)
    in
    {
        assert(count > 3, "KurtosisAccumulator.kurtosis: count must be larger than three");
        assert(variance(true) > 0, "KurtosisAccumulator.kurtosis: variance must be larger than zero");
    }
    do
    {
        F mult1 = cast(F) count * (count + isPopulation - 1) * (count - isPopulation + 1) / ((count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));
        F mult2 = cast(F) (count + isPopulation - 1) * (count + isPopulation - 1) / ((count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));
        F s = centeredSumOfSquares!F;
        return centeredSumOfQuarts!F / (s * s) * mult1 + 3 * (isRaw - mult2);
    }
}

/// naive
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: pow;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.naive, Summation.naive) v;
    v.put(x);

    v.kurtosis(true, true).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0);
    v.kurtosis(true, false).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0) - 3;
    v.kurtosis(false, false).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0);
    v.kurtosis(false, true).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0) + 3;

    v.skewness(true).shouldApprox == (117.005859 / 12) / pow(54.765625 / 12, 1.5);

    v.put(4.0);
    v.kurtosis(true, true).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0);
    v.kurtosis(true, false).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0) - 3;
    v.kurtosis(false, false).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0);
    v.kurtosis(false, true).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0) + 3;

    v.skewness(true).shouldApprox == (100.238166 / 13) / pow(57.019231 / 13, 1.5);
}

// check two-dimensional
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: pow;
    import mir.math.sum: Summation;
    import mir.ndslice.fuse: fuse;
    import mir.test: shouldApprox;

    auto x = [[0.0, 1.0, 1.5, 2.0, 3.5, 4.25],
              [2.0, 7.5, 5.0, 1.0, 1.5, 0.00]].fuse;

    KurtosisAccumulator!(double, KurtosisAlgo.naive, Summation.naive) v;
    v.put(x);
    v.kurtosis(true, true).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0);
}

// Can put KurtosisAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: pow;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.naive, Summation.naive) v;
    v.put(x);
    KurtosisAccumulator!(double, KurtosisAlgo.naive, Summation.naive) w;
    w.put(y);
    v.put(w);
    v.kurtosis(true, true).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0);
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: shouldApprox;
    import std.range: iota;
    import std.algorithm: map;

    auto x1 = iota(0, 5);
    KurtosisAccumulator!(double, KurtosisAlgo.naive, Summation.naive) v1;
    v1.put(x1);
    v1.kurtosis(false, true).shouldApprox == 1.8;
    auto x2 = x1.map!(a => 2 * a);
    KurtosisAccumulator!(double, KurtosisAlgo.naive, Summation.naive) v2;
    v2.put(x2);
    v2.kurtosis(false, true).shouldApprox == 1.8;
}

// check scaledSumOfCubes/scaledSumOfQuarts/skewness
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.naive, Summation.naive) v;
    v.put(x);
    auto varP = x.variance!"naive"(true);
    auto varS = x.variance!"naive"(false);
    v.scaledSumOfCubes(true).shouldApprox == v.centeredSumOfCubes / (varP * varP.sqrt);
    v.scaledSumOfCubes(false).shouldApprox == v.centeredSumOfCubes / (varS * varS.sqrt);
    v.scaledSumOfQuarts(true).shouldApprox == v.centeredSumOfQuarts / (varP * varP);
    v.scaledSumOfQuarts(false).shouldApprox == v.centeredSumOfQuarts / (varS * varS);
    v.skewness(true).shouldApprox == x.skewness!"naive"(true);
    v.skewness(false).shouldApprox == x.skewness!"naive"(false);
}

///
struct KurtosisAccumulator(T, KurtosisAlgo kurtosisAlgo, Summation summation)
    if (isMutable!T && kurtosisAlgo == KurtosisAlgo.online)
{
    import mir.math.sum: Summator;
    import std.traits: isIterable;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;
    ///
    alias S = Summator!(T, summation);
    ///
    private S centeredSummatorOfSquares;
    ///
    private S centeredSummatorOfCubes;
    ///
    private S centeredSummatorOfQuarts;

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
            deltaOld -= mean;
        }
        meanAccumulator.put(x);
        T deltaNew = x - mean;
        centeredSummatorOfQuarts.put(deltaOld * deltaOld * deltaOld * deltaOld * ((count - 1) * (count * count - 3 * count + 3)) / (count * count * count) +
                                6 * deltaOld * deltaOld * centeredSumOfSquares!T / (count * count) -
                                4 * deltaOld * centeredSumOfCubes!T / count);
        centeredSummatorOfCubes.put(deltaOld * deltaOld * deltaOld * (count - 1) * (count - 2) / (count * count) -
                               3 * deltaOld * centeredSumOfSquares!T / count);
        centeredSummatorOfSquares.put(deltaOld * deltaNew);
    }

    ///
    void put(U, KurtosisAlgo kurtAlgo, Summation sumAlgo)(KurtosisAccumulator!(U, kurtAlgo, sumAlgo) v)
    {
        size_t oldCount = count;
        T delta = v.mean;
        if (oldCount > 0) {
            delta -= mean;
        }
        meanAccumulator.put!T(v.meanAccumulator);
        centeredSummatorOfQuarts.put(v.centeredSumOfQuarts!T + 
                               delta * delta * delta * delta * ((v.count * oldCount) * (oldCount * oldCount - v.count * oldCount + v.count * v.count)) / (count * count * count) +
                               6 * delta * delta * ((oldCount * oldCount) * v.centeredSumOfSquares!T + (v.count * v.count) * centeredSumOfSquares!T) / (count * count) +
                               4 * delta * (oldCount * v.centeredSumOfCubes!T - v.count * centeredSumOfCubes!T) / count);
        centeredSummatorOfCubes.put(v.centeredSumOfCubes!T + 
                               delta * delta * delta * v.count * oldCount * (oldCount - v.count) / (count * count) +
                               3 * delta * (oldCount * v.centeredSumOfSquares!T - v.count * centeredSumOfSquares!T) / count);
        centeredSummatorOfSquares.put(v.centeredSumOfSquares!T + delta * delta * v.count * oldCount / count);
    }

const:

    ///
    size_t count()
    {
        return meanAccumulator.count;
    }
    ///
    F centeredSumOfQuarts(F = T)()
    {
        return cast(F) centeredSummatorOfQuarts.sum;
    }
    ///
    F centeredSumOfCubes(F = T)()
    {
        return cast(F) centeredSummatorOfCubes.sum;
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F scaledSumOfCubes(F = T)(bool isPopulation)
    {
        import mir.math.common: sqrt;
        F var = variance!F(isPopulation);
        return centeredSumOfCubes!F/ (var * var.sqrt);
    }
    ///
    F scaledSumOfQuarts(F = T)(bool isPopulation)
    {
        F var = variance!F(isPopulation);
        return centeredSumOfQuarts!F/ (var * var);
    }
    ///
    F mean(F = T)()
    {
        return meanAccumulator.mean!F;
    }
    ///
    F variance(F = T)(bool isPopulation)
    in
    {
        assert(count > 1, "KurtosisAccumulator.variance: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");
        assert(centeredSummatorOfSquares.sum > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");
    }
    do
    {
        import mir.math.common: sqrt;
        F s = centeredSumOfSquares!F;
        return centeredSumOfCubes!F / (s * s.sqrt) * count * sqrt(cast(F) count + isPopulation - 1) /
            (count + 2 * isPopulation - 2);
        /+ Equivalent to
        return scaledSumOfCubes!F(isPopulation) / count *
                (cast(F) count * count / ((count + isPopulation - 1) * (count + 2 * isPopulation - 2)));
        +/
    }
    ///
    F kurtosis(F = T)(bool isPopulation, bool isRaw)
    in
    {
        assert(count > 3, "KurtosisAccumulator.kurtosis: count must be larger than three");
        assert(variance(true) > 0, "KurtosisAccumulator.kurtosis: variance must be larger than zero");
    }
    do
    {
        F mult1 = cast(F) count * (count + isPopulation - 1) * (count - isPopulation + 1) / ((count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));
        F mult2 = cast(F) (count + isPopulation - 1) * (count + isPopulation - 1) / ((count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));
        F s = centeredSumOfSquares!F;
        return centeredSumOfQuarts!F / (s * s) * mult1 + 3 * (isRaw - mult2);
    }
}

/// online
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) v;
    v.put(x);
    v.kurtosis(true, true).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0);
    v.kurtosis(true, false).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0) - 3;
    v.kurtosis(false, false).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0);
    v.kurtosis(false, true).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0) + 3;

    v.put(4.0);
    v.kurtosis(true, true).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0);
    v.kurtosis(true, false).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0) - 3;
    v.kurtosis(false, false).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0);
    v.kurtosis(false, true).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0) + 3;
}

// Can put slice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    v.put(y);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator (naive)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    KurtosisAccumulator!(double, KurtosisAlgo.naive, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator (twoPass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = KurtosisAccumulator!(double, KurtosisAlgo.twoPass, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator (threePass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = KurtosisAccumulator!(double, KurtosisAlgo.threePass, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator (assumeZeroMean)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto b = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;
    auto y = b.center;

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) v;
    v.put(x);
    KurtosisAccumulator!(double, KurtosisAlgo.assumeZeroMean, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(622.639052)); //note: different from above due to inconsistent centering
    assert(v.centeredSumOfSquares.approxEqual(52.885417)); //note: different from above due to inconsistent centering
}

// check scaledSumOfCubes/scaledSumOfQuarts/skewness
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive) v;
    v.put(x);
    auto varP = x.variance!"online"(true);
    auto varS = x.variance!"online"(false);
    v.scaledSumOfCubes(true).shouldApprox == v.centeredSumOfCubes / (varP * varP.sqrt);
    v.scaledSumOfCubes(false).shouldApprox == v.centeredSumOfCubes / (varS * varS.sqrt);
    v.scaledSumOfQuarts(true).shouldApprox == v.centeredSumOfQuarts / (varP * varP);
    v.scaledSumOfQuarts(false).shouldApprox == v.centeredSumOfQuarts / (varS * varS);
    v.skewness(true).shouldApprox == x.skewness!"online"(true);
    v.skewness(false).shouldApprox == x.skewness!"online"(false);
}

///
struct KurtosisAccumulator(T, KurtosisAlgo kurtosisAlgo, Summation summation)
    if (isMutable!T && kurtosisAlgo == KurtosisAlgo.twoPass)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import std.range: isInputRange;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;
    ///
    alias S = Summator!(T, summation);
    ///
    private S centeredSummatorOfSquares;
    ///
    private S centeredSummatorOfCubes; // only included to facilitate adding to online
    ///
    private S centeredSummatorOfQuarts;

    ///
    this(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
    {
        import mir.functional: naryFun;
        import mir.ndslice.topology: vmap, map;
        import mir.ndslice.internal: LeftOp;

        meanAccumulator.put(slice.lightScope);

        auto sliceMap = slice.vmap(LeftOp!("-", T)(mean)).map!(naryFun!"a * a", naryFun!"(a * a) * a", naryFun!"(a * a) * (a * a)");
        centeredSummatorOfSquares.put(sliceMap.map!"a[0]");
        centeredSummatorOfCubes.put(sliceMap.map!"a[1]");
        centeredSummatorOfQuarts.put(sliceMap.map!"a[2]");
    }

    ///
    this(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice);
    }

    ///
    this(Range)(Range range)
        if (isInputRange!Range && !isConvertibleToSlice!Range && is(elementType!Range : T))
    {
        import std.algorithm: map;
        meanAccumulator.put(range);

        auto centeredRangeMultiplier = range.map!(a => (a - mean)).map!("a * a", "a * a * a", "a * a * a * a");
        centeredSummatorOfSquares.put(centeredRangeMultiplier.map!"a[0]");
        centeredSummatorOfCubes.put(centeredRangeMultiplier.map!"a[1]");
        centeredSummatorOfQuarts.put(centeredRangeMultiplier.map!"a[2]");
    }

const:

    ///
    size_t count()()
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)()
    {
        return meanAccumulator.mean!F;
    }
    ///
    F variance(F = T)(bool isPopulation)
    in
    {
        assert(count > 1, "SkewnessAccumulator.variance: count must be larger than 1");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F centeredSumOfCubes(F = T)()
    {
        return cast(F) centeredSummatorOfCubes.sum;
    }
    ///
    F centeredSumOfQuarts(F = T)()
    {
        return cast(F) centeredSummatorOfQuarts.sum;
    }
    ///
    F scaledSumOfCubes(F = T)(bool isPopulation)
    {
        import mir.math.common: sqrt;
        auto var = variance!F(isPopulation);
        return centeredSumOfCubes!F / (var * var.sqrt);
    }
    ///
    F scaledSumOfQuarts(F = T)(bool isPopulation)
    {
        auto var = variance!F(isPopulation);
        return centeredSumOfQuarts!F / (var * var);
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "KurtosisAccumulator.skewness: count must be larger than two");
        assert(centeredSumOfSquares > 0, "KurtosisAccumulator.skewness: variance must be larger than zero");
    }
    do
    {
        import mir.math.common: sqrt;
        F s = centeredSumOfSquares!F;
        return centeredSumOfCubes!F / (s * s.sqrt) * count * sqrt(cast(F) count + isPopulation - 1) /
            (count + 2 * isPopulation - 2);
        /+ Equivalent to
        return scaledSumOfCubes!F(isPopulation) / count *
                (cast(F) count * count / ((count + isPopulation - 1) * (count + 2 * isPopulation - 2)));
        +/
    }
    ///
    F kurtosis(F = T)(bool isPopulation, bool isRaw)
    in
    {
        assert(count > 3, "KurtosisAccumulator.kurtosis: count must be larger than three");
    }
    do
    {
        F mult1 = cast(F) count * (count + isPopulation - 1) * (count - isPopulation + 1) / ((count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));
        F mult2 = cast(F) (count + isPopulation - 1) * (count + isPopulation - 1) / ((count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));
        F s = centeredSumOfSquares!F;
        return centeredSumOfQuarts!F / (s * s) * mult1 + 3 * (isRaw - mult2);
    }  
}

/// twoPass
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.twoPass, Summation.naive)(x);
    assert(v.kurtosis(true, true).approxEqual(38.062853 / 12));
    assert(v.kurtosis(true, false).approxEqual(38.062853 / 12 - 3.0));
    assert(v.kurtosis(false, true).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)) + 3.0);
    assert(v.kurtosis(false, false).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
}

// check withAsSlice
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.rc.array: RCArray;
    import mir.test: shouldApprox;

    static immutable a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.twoPass, Summation.naive)(x);
    v.scaledSumOfQuarts(true).shouldApprox == 38.062853;
}

// check dynamic slice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: shouldApprox;

    double[] x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                  2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.twoPass, Summation.naive)(x);
    v.scaledSumOfQuarts(true).shouldApprox == 38.062853;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: shouldApprox;
    import std.range: iota;
    import std.algorithm: map;

    auto x1 = iota(0, 5);
    auto v1 = KurtosisAccumulator!(double, KurtosisAlgo.twoPass, Summation.naive)(x1);
    v1.kurtosis(false, true).shouldApprox == 1.8;
    auto x2 = x1.map!(a => 2 * a);
    auto v2 = KurtosisAccumulator!(double, KurtosisAlgo.twoPass, Summation.naive)(x2);
    v2.kurtosis(false, true).shouldApprox == 1.8;
}

// check scaledSumOfCubes/scaledSumOfQuarts/skewness
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.twoPass, Summation.naive)(x);
    auto varP = x.variance!"twoPass"(true);
    auto varS = x.variance!"twoPass"(false);
    v.scaledSumOfCubes(true).shouldApprox == v.centeredSumOfCubes / (varP * varP.sqrt);
    v.scaledSumOfCubes(false).shouldApprox == v.centeredSumOfCubes / (varS * varS.sqrt);
    v.scaledSumOfQuarts(true).shouldApprox == v.centeredSumOfQuarts / (varP * varP);
    v.scaledSumOfQuarts(false).shouldApprox == v.centeredSumOfQuarts / (varS * varS);
    v.skewness(true).shouldApprox == x.skewness!"twoPass"(true);
    v.skewness(false).shouldApprox == x.skewness!"twoPass"(false);
}

///
struct KurtosisAccumulator(T, KurtosisAlgo kurtosisAlgo, Summation summation)
    if (isMutable!T && kurtosisAlgo == KurtosisAlgo.threePass)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import std.range: isInputRange;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;
    ///
    alias S = Summator!(T, summation);
    ///
    private S centeredSummatorOfSquares;
    ///
    private S scaledSummatorOfCubes; //only included to facilitate adding to online accumulator
    ///
    private S scaledSummatorOfQuarts;

    ///
    this(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
    {
        import mir.functional: naryFun;
        import mir.ndslice.topology: vmap, map;
        import mir.ndslice.internal: LeftOp;
        import mir.math.common: sqrt;

        meanAccumulator.put(slice.lightScope);
        auto centeredSlice = slice.vmap(LeftOp!("-", T)(mean));
        centeredSummatorOfSquares.put(centeredSlice.map!(naryFun!"a * a"));

        assert(variance(true) > 0, "KurtosisAccumulator.this: must divide by positive standard deviation");

        auto sliceMap = centeredSlice.
            vmap(LeftOp!("*", T)(1 / variance(true).sqrt)).
            map!(naryFun!"(a * a) * a", naryFun!"(a * a) * (a * a)");
        scaledSummatorOfCubes.put(sliceMap.map!"a[0]");
        scaledSummatorOfQuarts.put(sliceMap.map!"a[1]");
    }

    ///
    this(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice);
    }

    ///
    this(Range)(Range range)
        if (isInputRange!Range && !isConvertibleToSlice!Range && is(elementType!Range : T))
    {
        import mir.math.common: sqrt;
        import std.algorithm: map;

        meanAccumulator.put(range);
        auto centeredRange = range.map!(a => (a - mean));
        centeredSummatorOfSquares.put(centeredRange.map!"a * a");
        auto rangeMap = centeredRange.
            map!(a => a / variance(true).sqrt).
            map!("(a * a) * a", "(a * a) * (a * a)");
        scaledSummatorOfCubes.put(rangeMap.map!"a[0]");
        scaledSummatorOfQuarts.put(rangeMap.map!"a[1]");
    }

const:

    ///
    size_t count()()
    {
        return meanAccumulator.count;
    }
    ///
    F mean(F = T)()
    {
        return meanAccumulator.mean!F;
    }
    ///
    F variance(F = T)(bool isPopulation)
    in
    {
        assert(count > 1, "SkewnessAccumulator.variance: count must be larger than 1");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F centeredSumOfCubes(F = T)()
    {
        import mir.math.common: sqrt;
        // variance consistent with that used for scaledSumOfQuarts above
        auto varP = variance!F(true);
        return scaledSumOfCubes!F * varP * varP.sqrt;
    }
    ///
    F centeredSumOfQuarts(F = T)()
    {
        // variance consistent with that used for scaledSumOfQuarts above
        auto varP = variance!F(true);
        return scaledSumOfQuarts!F * varP * varP;
    }
    ///
    F scaledSumOfCubes(F = T)()
    {
        return cast(F) scaledSummatorOfCubes.sum;
    }
    ///
    F scaledSumOfQuarts(F = T)()
    {
        return cast(F) scaledSummatorOfQuarts.sum;
    }
    ///
    F scaledSumOfCubes(F = T)(bool isPopulation)
    {
        import mir.math.common: sqrt;
        return scaledSumOfCubes!F * (count + isPopulation - 1) * sqrt(cast(F) count + isPopulation - 1) / count / sqrt(cast(F) count);
    }
    ///
    F scaledSumOfQuarts(F = T)(bool isPopulation)
    {
        return scaledSumOfQuarts!F * (count + isPopulation - 1) * (count + isPopulation - 1) / cast(F) count / cast(F) count;
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "KurtosisAccumulator.skewness: count must be larger than two");
    }
    do
    {
        // formula for other kurtosis accumulators doesn't work here since we are
        // enforcing the the scaledSumOfCubes uses population variance and not that it can switch
        import mir.math.common: sqrt;
        return scaledSumOfCubes!F / (count + 2 * isPopulation - 2) *
                sqrt(cast(F) (count + isPopulation - 1) / count);
        /+ Equivalent to
        return scaledSumOfCubes!F / count * 
                sqrt(cast(F) count * (count + isPopulation - 1)) / (count + 2 * isPopulation - 2)
        +/
    }
    ///
    F kurtosis(F = T)(bool isPopulation, bool isRaw)
    in
    {
        assert(count > 3, "KurtosisAccumulator.kurtosis: count must be larger than three");
    }
    do
    {
        // formula for other kurtosis accumulators doesn't work here since we are
        // enforcing the scaling uses population variance and not that it can switch
        F mult1 = cast(F) (count + isPopulation - 1) * (count - isPopulation + 1) / (count * (count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));
        F mult2 = cast(F) (count + isPopulation - 1) * (count + isPopulation - 1) / ((count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));

        return scaledSumOfQuarts!F * mult1 + 3 * (isRaw - mult2);
    }  
}

/// threePass
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.threePass, Summation.naive)(x);
    assert(v.kurtosis(true, true).approxEqual(38.062853 / 12));
    assert(v.kurtosis(true, false).approxEqual(38.062853 / 12 - 3.0));
    assert(v.kurtosis(false, true).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)) + 3.0);
    assert(v.kurtosis(false, false).approxEqual(38.062853 / 12 * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
}

// check withAsSlice
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.math.sum: Summation;
    import mir.rc.array: RCArray;

    static immutable a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.threePass, Summation.naive)(x);
    assert(v.scaledSumOfQuarts.approxEqual(38.062853));
}

// check dynamic slice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.math.sum: Summation;

    double[] x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                  2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.threePass, Summation.naive)(x);
    assert(v.scaledSumOfQuarts.approxEqual(38.062853));
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: shouldApprox;
    import std.range: iota;
    import std.algorithm: map;

    auto x1 = iota(0, 5);
    auto v1 = KurtosisAccumulator!(double, KurtosisAlgo.threePass, Summation.naive)(x1);
    v1.kurtosis(false, true).shouldApprox == 1.8;
    auto x2 = x1.map!(a => 2 * a);
    auto v2 = KurtosisAccumulator!(double, KurtosisAlgo.threePass, Summation.naive)(x2);
    v2.kurtosis(false, true).shouldApprox == 1.8;
}

// check scaledSumOfCubes/scaledSumOfQuarts/skewness
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.threePass, Summation.naive)(x);
    auto varP = x.variance!"twoPass"(true);
    auto varS = x.variance!"twoPass"(false);
    v.scaledSumOfCubes(true).shouldApprox == v.centeredSumOfCubes / (varP * varP.sqrt);
    v.scaledSumOfCubes(false).shouldApprox == v.centeredSumOfCubes / (varS * varS.sqrt);
    v.scaledSumOfQuarts(true).shouldApprox == v.centeredSumOfQuarts / (varP * varP);
    v.scaledSumOfQuarts(false).shouldApprox == v.centeredSumOfQuarts / (varS * varS);
    v.skewness(true).shouldApprox == x.skewness!"threePass"(true);
    v.skewness(false).shouldApprox == x.skewness!"threePass"(false);
}

///
struct KurtosisAccumulator(T, KurtosisAlgo kurtosisAlgo, Summation summation)
    if (isMutable!T && kurtosisAlgo == KurtosisAlgo.assumeZeroMean)
{
    import mir.math.sum: Summator;
    import std.traits: isIterable;

    ///
    private size_t _count;
    ///
    alias S = Summator!(T, summation);
    ///
    private S centeredSummatorOfSquares;
    ///
    private S centeredSummatorOfCubes;
    ///
    private S centeredSummatorOfQuarts;

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
        _count++;
        T x2 = x * x;
        centeredSummatorOfSquares.put(x2);
        centeredSummatorOfCubes.put(x2 * x);
        centeredSummatorOfQuarts.put(x2 * x2);
    }

    ///
    void put(U, Summation sumAlgo)(KurtosisAccumulator!(U, kurtosisAlgo, sumAlgo) v)
    {
        _count += v.count;
        centeredSummatorOfSquares.put(v.centeredSumOfSquares!T);
        centeredSummatorOfCubes.put(v.centeredSumOfCubes!T);
        centeredSummatorOfQuarts.put(v.centeredSumOfQuarts!T);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F mean(F = T)() @property
    {
        return cast(F) 0;
    }
    MeanAccumulator!(T, summation) meanAccumulator()()
    {
        typeof(return) m = { _count, T(0) };
        return m;
    }
    ///
    F variance(F = T)(bool isPopulation) @property
    in
    {
        assert(count > 1, "KurtosisAccumulator.variance: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
    ///
    F centeredSumOfQuarts(F = T)() @property
    {
        return cast(F) centeredSummatorOfQuarts.sum;
    }
    ///
    F centeredSumOfCubes(F = T)() @property
    {
        return cast(F) centeredSummatorOfCubes.sum;
    }
    ///
    F centeredSumOfSquares(F = T)() @property
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F scaledSumOfCubes(F = T)(bool isPopulation)
    {
        import mir.math.common: sqrt;
        F var = variance!F(isPopulation);
        return centeredSumOfCubes!F/ (var * var.sqrt);
    }
    ///
    F scaledSumOfQuarts(F = T)(bool isPopulation)
    {
        F var = variance!F(isPopulation);
        return centeredSumOfQuarts!F/ (var * var);
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");
        assert(centeredSummatorOfSquares.sum > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");
    }
    do
    {
        import mir.math.common: sqrt;
        F s = centeredSumOfSquares!F;
        return centeredSumOfCubes!F / (s * s.sqrt) * count * sqrt(cast(F) count + isPopulation - 1) /
            (count + 2 * isPopulation - 2);
        /+ Equivalent to
        return scaledSumOfCubes!F(isPopulation) / count *
                (cast(F) count * count / ((count + isPopulation - 1) * (count + 2 * isPopulation - 2)));
        +/
    }
    ///
    F kurtosis(F = T)(bool isPopulation, bool isRaw)
    in
    {
        assert(count > 3, "KurtosisAccumulator.kurtosis: count must be larger than three");
        assert(variance(true) > 0, "KurtosisAccumulator.kurtosis: variance must be larger than zero");
    }
    do
    {
        F mult1 = cast(F) count * (count + isPopulation - 1) * (count - isPopulation + 1) / ((count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));
        F mult2 = cast(F) (count + isPopulation - 1) * (count + isPopulation - 1) / ((count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));
        F s = centeredSumOfSquares!F;
        return centeredSumOfQuarts!F / (s * s) * mult1 + 3 * (isRaw - mult2);
    }
}

/// assumeZeroMean
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;

    KurtosisAccumulator!(double, KurtosisAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.kurtosis(true, true).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0)));
    assert(v.kurtosis(true, false).approxEqual((792.784119 / 12) / pow(54.765625 / 12, 2.0) - 3.0));
    assert(v.kurtosis(false, false).approxEqual(792.784119 / pow(54.765625 / 11, 2.0) * (12.0 * 13.0) / (11.0 * 10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0)));
    assert(v.kurtosis(false, true).approxEqual(792.784119 / pow(54.765625 / 11, 2.0) * (12.0 * 13.0) / (11.0 * 10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0) + 3.0));

    v.put(4.0);
    assert(v.kurtosis(true, true).approxEqual((1048.784119 / 13) / pow(70.765625 / 13, 2.0)));
    assert(v.kurtosis(true, false).approxEqual((1048.784119 / 13) / pow(70.765625 / 13, 2.0) - 3.0));
    assert(v.kurtosis(false, false).approxEqual(1048.784119 / pow(70.765625 / 12, 2.0) * (13.0 * 14.0) / (12.0 * 11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0)));
    assert(v.kurtosis(false, true).approxEqual(1048.784119 / pow(70.765625 / 12, 2.0) * (13.0 * 14.0) / (12.0 * 11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0) + 3.0));
}

// Can put slice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = a.center;
    auto x = b[0 .. 6];
    auto y = b[6 .. $];

    KurtosisAccumulator!(double, KurtosisAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.approxEqual(52.44613647));
    assert(v.centeredSumOfSquares.approxEqual(13.4921875));

    v.put(y);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = a.center;
    auto x = b[0 .. 6];
    auto y = b[6 .. $];

    KurtosisAccumulator!(double, KurtosisAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.approxEqual(52.44613647));
    assert(v.centeredSumOfSquares.approxEqual(13.4921875));

    KurtosisAccumulator!(double, KurtosisAlgo.assumeZeroMean, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}


// check scaledSumOfCubes/scaledSumOfQuarts/skewness
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;
    import mir.test: shouldApprox;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.assumeZeroMean, Summation.naive)(x);
    auto varP = x.variance!"assumeZeroMean"(true);
    auto varS = x.variance!"assumeZeroMean"(false);
    v.scaledSumOfCubes(true).shouldApprox == v.centeredSumOfCubes / (varP * varP.sqrt);
    v.scaledSumOfCubes(false).shouldApprox == v.centeredSumOfCubes / (varS * varS.sqrt);
    v.scaledSumOfQuarts(true).shouldApprox == v.centeredSumOfQuarts / (varP * varP);
    v.scaledSumOfQuarts(false).shouldApprox == v.centeredSumOfQuarts / (varS * varS);
    v.skewness(true).shouldApprox == x.skewness!"assumeZeroMean"(true);
    v.skewness(false).shouldApprox == x.skewness!"assumeZeroMean"(false);
}

///
struct KurtosisAccumulator(T, KurtosisAlgo kurtosisAlgo, Summation summation)
    if (isMutable!T && kurtosisAlgo == KurtosisAlgo.hybrid)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import std.range: isInputRange;
    import std.traits: isIterable;

    ///
    private MeanAccumulator!(T, summation) meanAccumulator;
    ///
    alias S = Summator!(T, summation);
    ///
    private S centeredSummatorOfSquares;
    ///
    private S centeredSummatorOfCubes;
    ///
    private S centeredSummatorOfQuarts;

    ///
    this(Iterator, size_t N, SliceKind kind)(Slice!(Iterator, N, kind) slice)
    {
        import mir.functional: naryFun;
        import mir.ndslice.topology: vmap, map;
        import mir.ndslice.internal: LeftOp;

        meanAccumulator.put(slice.lightScope);

        auto sliceMap = slice.vmap(LeftOp!("-", T)(mean)).map!(naryFun!"a * a", naryFun!"(a * a) * a", naryFun!"(a * a) * (a * a)");
        centeredSummatorOfSquares.put(sliceMap.map!"a[0]");
        centeredSummatorOfCubes.put(sliceMap.map!"a[1]");
        centeredSummatorOfQuarts.put(sliceMap.map!"a[2]");
    }

    ///
    this(SliceLike)(SliceLike x)
        if (isConvertibleToSlice!SliceLike && !isSlice!SliceLike)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice);
    }

    ///
    this(Range)(Range range)
        if (isIterable!Range && !isConvertibleToSlice!Range)
    {
        static if (isInputRange!Range && is(elementType!Range : T)) {
            import std.algorithm: map;
            meanAccumulator.put(range);

            auto centeredRangeMultiplier = range.map!(a => (a - mean)).map!("a * a", "a * a * a", "a * a * a * a");
            centeredSummatorOfSquares.put(centeredRangeMultiplier.map!"a[0]");
            centeredSummatorOfCubes.put(centeredRangeMultiplier.map!"a[1]");
            centeredSummatorOfQuarts.put(centeredRangeMultiplier.map!"a[2]");
        } else {
            this.put(range);
        }
    }

    ///
    this()(T x)
    {
        this.put(x);
    }

    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        static if (isInputRange!Range && is(elementType!Range : T)) {
            auto v = typeof(this)(r);
            this.put(v);
        } else {
            foreach(x; r)
            {
                this.put(x);
            }
        }
    }

    ///
    void put()(T x)
    {
        T deltaOld = x;
        if (count > 0) {
            deltaOld -= mean;
        }
        meanAccumulator.put(x);
        T deltaNew = x - mean;
        centeredSummatorOfQuarts.put(deltaOld * deltaOld * deltaOld * deltaOld * ((count - 1) * (count * count - 3 * count + 3)) / (count * count * count) +
                                6 * deltaOld * deltaOld * centeredSumOfSquares!T / (count * count) -
                                4 * deltaOld * centeredSumOfCubes!T / count);
        centeredSummatorOfCubes.put(deltaOld * deltaOld * deltaOld * (count - 1) * (count - 2) / (count * count) -
                               3 * deltaOld * centeredSumOfSquares!T / count);
        centeredSummatorOfSquares.put(deltaOld * deltaNew);
    }

    ///
    void put(U, KurtosisAlgo kurtAlgo, Summation sumAlgo)(KurtosisAccumulator!(U, kurtAlgo, sumAlgo) v)
    {
        size_t oldCount = count;
        T delta = v.mean;
        if (oldCount > 0) {
            delta -= mean;
        }
        meanAccumulator.put!T(v.meanAccumulator);
        centeredSummatorOfQuarts.put(v.centeredSumOfQuarts!T + 
                               delta * delta * delta * delta * ((v.count * oldCount) * (oldCount * oldCount - v.count * oldCount + v.count * v.count)) / (count * count * count) +
                               6 * delta * delta * ((oldCount * oldCount) * v.centeredSumOfSquares!T + (v.count * v.count) * centeredSumOfSquares!T) / (count * count) +
                               4 * delta * (oldCount * v.centeredSumOfCubes!T - v.count * centeredSumOfCubes!T) / count);
        centeredSummatorOfCubes.put(v.centeredSumOfCubes!T + 
                               delta * delta * delta * v.count * oldCount * (oldCount - v.count) / (count * count) +
                               3 * delta * (oldCount * v.centeredSumOfSquares!T - v.count * centeredSumOfSquares!T) / count);
        centeredSummatorOfSquares.put(v.centeredSumOfSquares!T + delta * delta * v.count * oldCount / count);
    }

const:

    ///
    size_t count()
    {
        return meanAccumulator.count;
    }
    ///
    F centeredSumOfQuarts(F = T)()
    {
        return cast(F) centeredSummatorOfQuarts.sum;
    }
    ///
    F centeredSumOfCubes(F = T)()
    {
        return cast(F) centeredSummatorOfCubes.sum;
    }
    ///
    F centeredSumOfSquares(F = T)()
    {
        return cast(F) centeredSummatorOfSquares.sum;
    }
    ///
    F scaledSumOfCubes(F = T)(bool isPopulation)
    {
        import mir.math.common: sqrt;
        F var = variance!F(isPopulation);
        return centeredSumOfCubes!F/ (var * var.sqrt);
    }
    ///
    F scaledSumOfQuarts(F = T)(bool isPopulation)
    {
        F var = variance!F(isPopulation);
        return centeredSumOfQuarts!F/ (var * var);
    }
    ///
    F mean(F = T)()
    {
        return meanAccumulator.mean!F;
    }
    ///
    F variance(F = T)(bool isPopulation)
    in
    {
        assert(count > 1, "KurtosisAccumulator.variance: count must be larger than one");
    }
    do
    {
        return centeredSumOfSquares!F / (count + isPopulation - 1);
    }
    ///
    F skewness(F = T)(bool isPopulation)
    in
    {
        assert(count > 2, "SkewnessAccumulator.skewness: count must be larger than two");
        assert(centeredSummatorOfSquares.sum > 0, "SkewnessAccumulator.skewness: variance must be larger than zero");
    }
    do
    {
        import mir.math.common: sqrt;
        F s = centeredSumOfSquares!F;
        return centeredSumOfCubes!F / (s * s.sqrt) * count * sqrt(cast(F) count + isPopulation - 1) /
            (count + 2 * isPopulation - 2);
        /+ Equivalent to
        return scaledSumOfCubes!F(isPopulation) / count *
                (cast(F) count * count / ((count + isPopulation - 1) * (count + 2 * isPopulation - 2)));
        +/
    }
    ///
    F kurtosis(F = T)(bool isPopulation, bool isRaw)
    in
    {
        assert(count > 3, "KurtosisAccumulator.kurtosis: count must be larger than three");
        assert(variance(true) > 0, "KurtosisAccumulator.kurtosis: variance must be larger than zero");
    }
    do
    {
        F mult1 = cast(F) count * (count + isPopulation - 1) * (count - isPopulation + 1) / ((count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));
        F mult2 = cast(F) (count + isPopulation - 1) * (count + isPopulation - 1) / ((count + 2 * isPopulation - 2) * (count + 3 * isPopulation - 3));
        F s = centeredSumOfSquares!F;
        return centeredSumOfQuarts!F / (s * s) * mult1 + 3 * (isRaw - mult2);
    }
}

/// hybrid
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, pow;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x);
    v.kurtosis(true, true).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0);
    v.kurtosis(true, false).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0) - 3;
    v.kurtosis(false, false).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0);
    v.kurtosis(false, true).shouldApprox == (792.784119 / 12) / pow(54.765625 / 12, 2.0) * (11.0 * 13.0) / (10.0 * 9.0) - 3.0 * (11.0 * 11.0) / (10.0 * 9.0) + 3;

    v.put(4.0);
    v.kurtosis(true, true).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0);
    v.kurtosis(true, false).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0) - 3;
    v.kurtosis(false, false).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0);
    v.kurtosis(false, true).shouldApprox == (745.608180 / 13) / pow(57.019231 / 13, 2.0) * (12.0 * 14.0) / (11.0 * 10.0) - 3.0 * (12.0 * 12.0) / (11.0 * 10.0) + 3;
}

// check withAsSlice
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.rc.array: RCArray;
    import mir.test: shouldApprox;

    static immutable a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x);
    v.scaledSumOfQuarts(true).shouldApprox == 38.062853;
}

// check dynamic slice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: shouldApprox;

    double[] x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                  2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x);
    v.scaledSumOfQuarts(true).shouldApprox == 38.062853;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: shouldApprox;
    import std.algorithm: map;
    import std.range: chunks, iota;

    auto x1 = iota(0, 5);
    auto v1 = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x1);
    v1.kurtosis(false, true).shouldApprox == 1.8;
    auto x2 = x1.map!(a => 2 * a);
    auto v2 = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x2);
    v2.kurtosis(false, true).shouldApprox == 1.8;
    KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive) v3;
    v3.put(x1.chunks(1));
    v3.kurtosis(false, true).shouldApprox == 1.8;
    auto v4 = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x1.chunks(1));
    v4.kurtosis(false, true).shouldApprox == 1.8;
}

// Can put slice
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive) v;
    v.put(x);
    assert(v.centeredSumOfQuarts.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    v.put(y);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x);
    assert(v.centeredSumOfQuarts.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator (naive)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x);
    assert(v.centeredSumOfQuarts.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = KurtosisAccumulator!(double, KurtosisAlgo.naive, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator (online)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x);
    assert(v.centeredSumOfQuarts.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = KurtosisAccumulator!(double, KurtosisAlgo.online, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator (twoPass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x);
    assert(v.centeredSumOfQuarts.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = KurtosisAccumulator!(double, KurtosisAlgo.twoPass, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator (threePass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto y = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x);
    assert(v.centeredSumOfQuarts.approxEqual(46.944607));
    assert(v.centeredSumOfSquares.approxEqual(12.552083));

    auto w = KurtosisAccumulator!(double, KurtosisAlgo.threePass, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(792.784119));
    assert(v.centeredSumOfSquares.approxEqual(54.765625));
}

// Can put KurtosisAccumulator (assumeZeroMean)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25].sliced;
    auto b = [2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;
    auto y = b.center;

    auto v = KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive)(x);
    auto w = KurtosisAccumulator!(double, KurtosisAlgo.assumeZeroMean, Summation.naive)(y);
    v.put(w);
    assert(v.centeredSumOfQuarts.approxEqual(622.639052)); //note: different from above due to inconsistent centering
    assert(v.centeredSumOfSquares.approxEqual(52.885417)); //note: different from above due to inconsistent centering
}

// check scaledSumOfCubes/scaledSumOfQuarts/skewness
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: sqrt;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    KurtosisAccumulator!(double, KurtosisAlgo.hybrid, Summation.naive) v;
    v.put(x);
    auto varP = x.variance!"twoPass"(true);
    auto varS = x.variance!"twoPass"(false);
    v.scaledSumOfCubes(true).shouldApprox == v.centeredSumOfCubes / (varP * varP.sqrt);
    v.scaledSumOfCubes(false).shouldApprox == v.centeredSumOfCubes / (varS * varS.sqrt);
    v.scaledSumOfQuarts(true).shouldApprox == v.centeredSumOfQuarts / (varP * varP);
    v.scaledSumOfQuarts(false).shouldApprox == v.centeredSumOfQuarts / (varS * varS);
    v.skewness(true).shouldApprox == x.skewness!"hybrid"(true);
    v.skewness(false).shouldApprox == x.skewness!"hybrid"(false);
}

/++
Calculates the kurtosis of the input

By default, if `F` is not floating point type, then the result will have a
`double` type if `F` is implicitly convertible to a floating point type.

Params:
    F = controls type of output
    kurtosisAlgo = algorithm for calculating kurtosis (default: KurtosisAlgo.hybrid)
    summation = algorithm for calculating sums (default: Summation.appropriate)

Returns:
    The kurtosis of the input, must be floating point

See_also:
    $(LREF KurtosisAlgo)
+/
template kurtosis(
    F, 
    KurtosisAlgo kurtosisAlgo = KurtosisAlgo.hybrid, 
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
    KurtosisAlgo kurtosisAlgo = KurtosisAlgo.hybrid, 
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
    // population excess kurtosis
    assert(kurtosis([1.0, 2, 4, 5], true).approxEqual((34.0 / 4) / pow(10.0 / 4, 2.0) - 3.0));
    // sample raw kurtosis
    assert(kurtosis([1.0, 2, 4, 5], false, true).approxEqual((34.0 / 4) / pow(10.0 / 4, 2.0) * (3.0 * 5.0) / (2.0 * 1.0) - 3.0 * (3.0 * 3.0) / (2.0 * 1.0) + 3.0));
    // population raw kurtosis
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

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

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

    // The online algorithm is numerically unstable in this case
    auto y = x.kurtosis!"online";
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

    // The online algorithm is numerically stable in this case
    auto y = x.kurtosis!"online";
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

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean 
    from the second and fourth numbers has no effect. Further, after centering 
    and taking `x` to the fourth power, the first and third numbers in the slice
    have precision too low to be included in the centered sum of cubes. 
    +/
    assert(x.kurtosis.approxEqual(1.5));
    assert(x.kurtosis(false).approxEqual(1.5));
    assert(x.kurtosis(true).approxEqual(-1.0));
    assert(x.kurtosis(true, true).approxEqual(2.0));
    assert(x.kurtosis(false, true).approxEqual(4.5));

    assert(x.kurtosis!("online").approxEqual(1.5));
    assert(x.kurtosis!("online", "kbn").approxEqual(1.5));
    assert(x.kurtosis!("online", "kb2").approxEqual(1.5));
    assert(x.kurtosis!("online", "precise").approxEqual(1.5));
    assert(x.kurtosis!(double, "online", "precise").approxEqual(1.5));
    assert(x.kurtosis!(double, "online", "precise")(true).approxEqual(-1.0));
    assert(x.kurtosis!(double, "online", "precise")(true, true).approxEqual(2.0));

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
    import mir.stat.transform: center;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.kurtosis.approxEqual(1.006470));
    assert(x.kurtosis(false, true).approxEqual(4.006470));
    assert(x.kurtosis(true).approxEqual(0.171904));
    assert(x.kurtosis(true, true).approxEqual(3.171904));

    assert(x.kurtosis!"naive".approxEqual(1.006470));
    assert(x.kurtosis!"naive"(false, true).approxEqual(4.006470));
    assert(x.kurtosis!"naive"(true).approxEqual(0.171904));
    assert(x.kurtosis!"naive"(true, true).approxEqual(3.171904));

    assert(x.kurtosis!"online".approxEqual(1.006470));
    assert(x.kurtosis!"online"(false, true).approxEqual(4.006470));
    assert(x.kurtosis!"online"(true).approxEqual(0.171904));
    assert(x.kurtosis!"online"(true, true).approxEqual(3.171904));

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

// compile with dub test --build=unittest-perf --config=unittest-perf --compiler=ldc2
version(mir_stat_test_kurt_performance)
unittest
{
    import mir.math.sum: Summation;
    import mir.math.internal.benchmark;
    import std.stdio: writeln;
    import std.traits: EnumMembers;

    template staticMap(alias fun, alias S, args...)
    {
        import std.meta: AliasSeq;
        alias staticMap = AliasSeq!();
        static foreach (arg; args)
            staticMap = AliasSeq!(staticMap, fun!(double, arg, S));
    }

    size_t n = 10_000;
    size_t m = 1_000;

    alias S = Summation.fast;
    alias E = EnumMembers!KurtosisAlgo;
    alias fs = staticMap!(kurtosis, S, E);
    double[fs.length] output;

    auto e = [E];
    auto time = benchmarkRandom!(fs)(n, m, output);
    writeln("Kurtosis performance test");
    foreach (size_t i; 0 .. fs.length) {
        writeln("Function ", i + 1, ", Algo: ", e[i], ", Output: ", output[i], ", Elapsed time: ", time[i]);
    }
    writeln();
}

/++
Calculates the coefficient of variation of the input.

The coefficient of variation is calculated by dividing either the population or
sample (default) standard deviation by the mean of the input. According to
wikipedia, "the coefficient of variation should be computed computed for data
measured on a ratio scale, that is, scales that have a meaningful zero and hence
allow for relative comparison of two measurements." In addition, for "small- and
moderately-sized datasets", the coefficient of variation is biased, even when
using the sample standard deviation.

By default, if `F` is not floating point type, then the result will have a
`double` type if `F` is implicitly convertible to a floating point type.

Params:
    F = controls type of output
    varianceAlgo = algorithm for calculating variance (default: VarianceAlgo.hybrid)
    summation = algorithm for calculating sums (default: Summation.appropriate)

Returns:
    The coefficient of varition of the input, must be floating point type

See_also:
    $(WEB en.wikipedia.org/wiki/Coefficient_of_variation, Coefficient of variation)
+/
template coefficientOfVariation(
    F, 
    VarianceAlgo varianceAlgo = VarianceAlgo.hybrid, 
    Summation summation = Summation.appropriate)
{
    import mir.math.common: sqrt;
    import mir.math.sum: ResolveSummationType;
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
        isPopulation = true if population variance, false if sample variance (default)
    +/
    @fmamath stdevType!F coefficientOfVariation(Range)(Range r, bool isPopulation = false)
        if (isIterable!Range)
    {
        import core.lifetime: move;

        alias G = typeof(return);
        auto varianceAccumulator = VarianceAccumulator!(G, varianceAlgo, ResolveSummationType!(summation, Range, G))(r.move);
        assert(varianceAccumulator.mean!G > 0, "coefficientOfVariation: mean must be larger than zero");
        return varianceAccumulator.variance!G(isPopulation).sqrt / varianceAccumulator.mean!G;
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!F coefficientOfVariation(scope const F[] ar...)
    {
        alias G = typeof(return);
        auto varianceAccumulator = VarianceAccumulator!(G, varianceAlgo, ResolveSummationType!(summation, const(G)[], G))(ar);
        assert(varianceAccumulator.mean!G > 0, "coefficientOfVariation: mean must be larger than zero");
        return varianceAccumulator.variance!G(false).sqrt / varianceAccumulator.mean!G;
    }
}

/// ditto
template coefficientOfVariation(
    VarianceAlgo varianceAlgo = VarianceAlgo.hybrid, 
    Summation summation = Summation.appropriate)
{
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
        isPopulation = true if population variance, false if sample variance (default)
    +/
    @fmamath stdevType!Range coefficientOfVariation(Range)(Range r, bool isPopulation = false)
        if(isIterable!Range)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .coefficientOfVariation!(F, varianceAlgo, summation)(r.move, isPopulation);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!T coefficientOfVariation(T)(scope const T[] ar...)
    {
        alias F = typeof(return);
        return .coefficientOfVariation!(F, varianceAlgo, summation)(ar);
    }
}

///
template coefficientOfVariation(F, string varianceAlgo, string summation = "appropriate")
{
    mixin("alias coefficientOfVariation = .coefficientOfVariation!(F, VarianceAlgo." ~ varianceAlgo ~ ", Summation." ~ summation ~ ");");
}

/// ditto
template coefficientOfVariation(string varianceAlgo, string summation = "appropriate")
{
    mixin("alias coefficientOfVariation = .coefficientOfVariation!(VarianceAlgo." ~ varianceAlgo ~ ", Summation." ~ summation ~ ");");
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    assert(coefficientOfVariation([1.0, 2, 3]).approxEqual(1.0 / 2.0));
    assert(coefficientOfVariation([1.0, 2, 3], true).approxEqual(0.816497 / 2.0));

    assert(coefficientOfVariation!float([0, 1, 2, 3, 4, 5].sliced(3, 2)).approxEqual(1.870829 / 2.5));

    static assert(is(typeof(coefficientOfVariation!float([1, 2, 3])) == float));
}

/// Coefficient of variation of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.coefficientOfVariation.approxEqual(2.231299 / 2.437500));
}

/// Coefficient of variation of matrix
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

    assert(x.coefficientOfVariation.approxEqual(2.231299 / 2.437500));
}

/// Can also set algorithm type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto x = a + 1_000_000_000;

    auto y = x.coefficientOfVariation;
    assert(y.approxEqual(2.231299 / 1_000_000_002.437500));

    // The naive variance algorithm is numerically unstable in this case, but
    // the difference is small as coefficientOfVariation is a ratio
    auto z0 = x.coefficientOfVariation!"naive";
    assert(!z0.approxEqual(y, 0x1p-20f, 0x1p-30f));

    // But the two-pass algorithm provides a consistent answer
    auto z1 = x.coefficientOfVariation!"twoPass";
    assert(z1.approxEqual(y));
}

/// Can also set algorithm or output type
version(mir_stat_test)
//@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    // Set population standard deviation, standardDeviation algorithm, sum algorithm or output type

    auto a = [1.0, 1e100, 1, -1e100].sliced;
    auto x = a * 10_000;

    bool populationTrue = true;

    /++
    For this case, failing to use a summation algorithm results in an assert
    error because the mean is zero due to floating point precision issues.
    +/
    //assert(x.coefficientOfVariation!("online").approxEqual(8.164966e103 / 0.0));

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean 
    from the second and fourth numbers has no effect. Further, after centering 
    and squaring `x`, the first and third numbers in the slice have precision 
    too low to be included in the centered sum of squares. 
    +/
    assert(x.coefficientOfVariation!("online", "kbn").approxEqual(8.164966e103 / 5000.0));
    assert(x.coefficientOfVariation!("online", "kb2").approxEqual(8.164966e103 / 5000.0));
    assert(x.coefficientOfVariation!("online", "precise").approxEqual(8.164966e103 / 5000.0));
    assert(x.coefficientOfVariation!(double, "online", "precise").approxEqual(8.164966e103 / 5000.0));
    assert(x.coefficientOfVariation!(double, "online", "precise")(populationTrue).approxEqual(7.071068e103 / 5000.0));


    auto y = [uint.max - 2, uint.max - 1, uint.max].sliced;
    auto z = y.coefficientOfVariation!ulong;
    assert(z == (1.0 / (cast(double) uint.max - 1)));
    static assert(is(typeof(z) == double));
    assert(y.coefficientOfVariation!(ulong, "online") == (1.0 / (cast(double) uint.max - 1)));
}

/++
For integral slices, pass output type as template parameter to ensure output
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

    auto y = x.coefficientOfVariation;
    assert(y.approxEqual(2.151462f / 2.416667));
    static assert(is(typeof(y) == double));

    assert(x.coefficientOfVariation!float.approxEqual(2.151462f / 2.416667));
}

/++
coefficientOfVariation works for other user-defined types (provided they
can be converted to a floating point)
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    static struct Foo {
        float x;
        alias x this;
    }

    Foo[] foo = [Foo(1f), Foo(2f), Foo(3f)];
    assert(foo.coefficientOfVariation.approxEqual(1f / 2f));
}

/// Arbitrary coefficientOfVariation
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;

    assert(coefficientOfVariation(1.0, 2, 3).approxEqual(1.0 / 2.0));
    assert(coefficientOfVariation!float(1, 2, 3).approxEqual(1f / 2f));
}

// Dynamic array / UFCS
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    assert(coefficientOfVariation([1.0, 2, 3, 4]).approxEqual(1.290994 / 2.50));
    assert([1.0, 2, 3, 4].coefficientOfVariation.approxEqual(1.290994 / 2.50));
}

// Check type of alongDim result
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.algorithm.iteration: all;
    import mir.math.common: approxEqual;
    import mir.ndslice.topology: iota, alongDim, map;

    auto x = iota([2, 2], 1);
    auto y = x.alongDim!1.map!coefficientOfVariation;
    assert(y.all!approxEqual([0.707107 / 1.50, 0.707107 / 3.50]));
    static assert(is(meanType!(typeof(y)) == double));
}

// @nogc test
version(mir_stat_test)
@safe pure @nogc nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.coefficientOfVariation.approxEqual(2.231299 / 2.437500));
    assert(x.sliced.coefficientOfVariation!float.approxEqual(2.231299 / 2.437500));
}

///
struct MomentAccumulator(T, size_t N, Summation summation)
    if (N > 0 && isMutable!T)
{
    import std.traits: isIterable;

    ///
    Summator!(T, summation) summator;

    ///
    size_t count;

    ///
    F moment(F = T)() const @safe @property pure nothrow @nogc
    {
        return cast(F) summator.sum / cast(F) count;
    }

    ///
    F sumOfPower(F = T)() const @safe @property pure nothrow @nogc
    {
        return cast(F) summator.sum;
    }

    ///
    void put(Range)(Range r)
        if (isIterable!Range)
    {
        import mir.math.internal.powi: powi;
        import mir.primitives: hasShape;

        static if (hasShape!Range)
        {
            import mir.ndslice.topology: map;
            import mir.primitives: elementCount;

            count += r.elementCount;
            summator.put(r.map!(a => a.powi(N)));
        }
        else
        {
            foreach(x; r)
            {
                put(x);
            }
        }
    }

    ///
    void put(Range)(Range r, T m)
        if (isIterable!Range)
    {
        import mir.math.internal.powi: powi;
        import mir.primitives: hasShape;

        static if (hasShape!Range)
        {
            import mir.ndslice.internal: LeftOp;
            import mir.ndslice.topology: vmap, map;
            import mir.primitives: elementCount;

            count += r.elementCount;
            static if (N == 1)
            {
                summator.put(r.vmap(LeftOp!("-", T)(m))
                    );
            } else static if (N == 2) {
                summator.put(r.vmap(LeftOp!("-", T)(m)).map!"a * a"
                    );
            } else {
                summator.put(r.vmap(LeftOp!("-", T)(m)).
                               map!(a => a.powi(N))
                    );
            }
        }
        else
        {
            foreach(x; r)
            {
                put(x, m);
            }
        }
    }

    ///
    void put(Range)(Range r, T m, T s)
        if (isIterable!Range)
    {
        import mir.math.internal.powi: powi;
        import mir.primitives: hasShape;

        static if (hasShape!Range)
        {
            import mir.ndslice.internal: LeftOp;
            import mir.ndslice.topology: vmap, map;
            import mir.primitives: elementCount;

            count += r.elementCount;
            static if (N == 1)
            {
                summator.put(r.vmap(LeftOp!("-", T)(m)).
                               vmap(LeftOp!("*", T)(1 / s))
                    );
            } else static if (N == 2) {
                summator.put(r.vmap(LeftOp!("-", T)(m)).
                               vmap(LeftOp!("*", T)(1 / s)).
                               map!"a * a"
                    );
            } else {
                summator.put(r.vmap(LeftOp!("-", T)(m)).
                               vmap(LeftOp!("*", T)(1 / s)).
                               map!(a => a.powi(N))
                    );
            }

        }
        else
        {
            foreach(x; r)
            {
                put(x, m, s);
            }
        }
    }

    ///
    void put()(T x)
    {
        import mir.math.internal.powi;

        count++;
        summator.put(x.powi(N));
    }

    ///
    void put()(MomentAccumulator!(T, N, summation) m)
    {
        count += m.count;
        summator.put(m.summator.sum);
    }

    ///
    this(Range)(Range r)
        if (isIterable!Range)
    {
        import core.lifetime: move;
        this.put(r.move);
    }

    ///
    this(Range)(Range r, T m)
        if (isIterable!Range)
    {
        import core.lifetime: move;
        this.put(r.move, m);
    }

    ///
    this(Range)(Range r, T m, T s)
        if (isIterable!Range)
    {
        import core.lifetime: move;
        this.put(r.move, m, s);
    }

    ///
    this()(T x)
    {
        this.put(x);
    }

    ///
    this()(T x, T m)
    {
        this.put(x, m);
    }

    ///
    this()(T x, T m, T s)
    {
        this.put(x, m, s);
    }
}

/// Raw moment
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;

    MomentAccumulator!(double, 2, Summation.naive) v;
    v.put(x);

    assert(v.moment.approxEqual(54.76562 / 12));

    v.put(4.0);
    assert(v.moment.approxEqual(70.76562 / 13));
}

// Raw Moment: test putting accumulator
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = a.center;
    auto x = b[0 .. 6];
    auto y = b[6 .. $];

    MomentAccumulator!(double, 2, Summation.naive) v;
    v.put(x);
    assert(v.moment.approxEqual(13.492188 / 6));

    MomentAccumulator!(double, 2, Summation.naive) w;
    w.put(y);
    v.put(w);
    assert(v.moment.approxEqual(54.76562 / 12));
}

// mir.complex test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex;
    import mir.complex.math: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    alias C = Complex!double;

    auto a = [C(1, 3), C(2), C(3)].sliced;
    auto x = a.center;

    MomentAccumulator!(C, 2, Summation.naive) v;
    v.put(x);
    assert(v.moment.approxEqual(C(-4, -6) / 3));
}

// Raw Moment: test std.complex
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;
    import std.complex: Complex;
    import std.math.operations: isClose;

    auto a = [Complex!double(1.0, 3), Complex!double(2.0, 0), Complex!double(3.0, 0)].sliced;
    auto x = a.center;

    MomentAccumulator!(Complex!double, 2, Summation.naive) v;
    v.put(x);
    assert(v.moment.isClose(Complex!double(-4.0, -6.0) / 3));
}

/// Central moment
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    MomentAccumulator!(double, 2, Summation.naive) v;
    auto m = mean(x);
    v.put(x, m);
    assert(v.moment.approxEqual(54.76562 / 12));
}

// Central moment: dynamic array test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    double[] x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                  2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    MomentAccumulator!(double, 2, Summation.naive) v;
    auto m = mean(x);
    v.put(x, m);
    assert(v.sumOfPower.approxEqual(54.76562));
}

// Central moment: withAsSlice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.rc.array: RCArray;

    static immutable a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];

    MomentAccumulator!(double, 2, Summation.naive) v;
    auto m = mean(x);
    v.put(x.asSlice.lightScope, m);
    assert(v.sumOfPower.approxEqual(54.76562));
}

// Central moment: Test N == 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    MomentAccumulator!(double, 1, Summation.naive) v;
    auto m = mean(x);
    v.put(x, m);
    assert(v.moment.approxEqual(0.0 / 12));
    assert(v.count == 12);
}

/// Standardized moment with scaled calculation
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto u = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(x);
    MomentAccumulator!(double, 3, Summation.naive) v;
    v.put(x, u.mean, u.variance(true).sqrt);
    assert(v.moment.approxEqual(12.000999 / 12));
    assert(v.count == 12);
}

// standardized moment: dynamic array test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.rc.array: RCArray;

    double[] x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                  2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto u = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(x);
    MomentAccumulator!(double, 3, Summation.naive) v;
    v.put(x, u.mean, u.variance(true).sqrt);
    assert(v.sumOfPower.approxEqual(12.000999));
}

// standardized moment: withAsSlice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.rc.array: RCArray;

    static immutable a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];

    auto u = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(x);
    MomentAccumulator!(double, 3, Summation.naive) v;
    v.put(x.asSlice.lightScope, u.mean, u.variance(true).sqrt);
    assert(v.sumOfPower.approxEqual(12.000999));
}

// standardized moment: Test N == 2
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto u = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(x);
    MomentAccumulator!(double, 2, Summation.naive) v;
    v.put(x, u.mean, u.variance(true).sqrt);
    assert(v.moment.approxEqual(1.0));
    assert(v.count == 12);
}

// standardized moment: Test N == 1
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual, sqrt;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto u = VarianceAccumulator!(double, VarianceAlgo.twoPass, Summation.naive)(x);
    MomentAccumulator!(double, 1, Summation.naive) v;
    v.put(x, u.mean, u.variance(true).sqrt);
    assert(v.moment.approxEqual(0.0));
    assert(v.count == 12);
}

/++
Calculates the n-th raw moment of the input.

By default, if `F` is not floating point type or complex type, then the result
will have a `double` type if `F` is implicitly convertible to a floating point 
type or a type for which `isComplex!F` is true.

Params:
    F = controls type of output
    N = controls n-th raw moment
    summation = algorithm for calculating sums (default: Summation.appropriate)

Returns:
    The n-th raw moment of the input, must be floating point or complex type
+/
template rawMoment(F, size_t N, Summation summation = Summation.appropriate)
    if (N > 0)
{
    import mir.math.sum: ResolveSummationType;
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath meanType!F rawMoment(Range)(Range r)
        if (isIterable!Range)
    {
        import core.lifetime: move;
        
        alias G = typeof(return);
        MomentAccumulator!(G, N, ResolveSummationType!(summation, Range, G)) momentAccumulator;
        momentAccumulator.put(r.move);
        return momentAccumulator.moment;
    }

    /++
    Params:
        ar = values
    +/
    @fmamath meanType!F rawMoment(scope const F[] ar...)
    {
        alias G = typeof(return);
        MomentAccumulator!(G, N, ResolveSummationType!(summation, const(G)[], G)) momentAccumulator;
        momentAccumulator.put(ar);
        return momentAccumulator.moment;
    }
}

/// ditto
template rawMoment(size_t N, Summation summation = Summation.appropriate)
    if (N > 0)
{
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath meanType!Range rawMoment(Range)(Range r)
        if(isIterable!Range)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .rawMoment!(F, N, summation)(r.move);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath meanType!T rawMoment(T)(scope const T[] ar...)
    {
        alias F = typeof(return);
        return .rawMoment!(F, N, summation)(ar);
    }
}

/// ditto
template rawMoment(F, size_t N, string summation)
    if (N > 0)
{
    mixin("alias rawMoment = .rawMoment!(F, N, Summation." ~ summation ~ ");");
}

/// ditto
template rawMoment(size_t N, string summation)
    if (N > 0)
{
    mixin("alias rawMoment = .rawMoment!(N, Summation." ~ summation ~ ");");
}

/// Basic implementation
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    assert(rawMoment!2([1.0, 2, 3]).approxEqual(14.0 / 3));
    assert(rawMoment!3([1.0, 2, 3]).approxEqual(36.0 / 3));

    assert(rawMoment!(float, 2)([0, 1, 2, 3, 4, 5].sliced(3, 2)).approxEqual(55f / 6));
    static assert(is(typeof(rawMoment!(float, 2)([1, 2, 3])) == float));
}

/// Raw Moment of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto x = a.center;

    assert(x.rawMoment!2.approxEqual(54.76562 / 12));
}

/// Raw Moment of matrix
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.fuse: fuse;
    import mir.stat.transform: center;

    auto a = [
        [0.0, 1.0, 1.5, 2.0, 3.5, 4.25],
        [2.0, 7.5, 5.0, 1.0, 1.5, 0.0]
    ].fuse;
    auto x = a.center;

    assert(x.rawMoment!2.approxEqual(54.76562 / 12));
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;
    import mir.stat.transform: center;

    //Set sum algorithm or output type

    auto a = [1.0, 1e100, 1, -1e100].sliced;
    auto b = a * 10_000;
    auto x = b.center;

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean 
    from the second and fourth numbers has no effect. Further, after centering 
    and squaring `x`, the first and third numbers in the slice have precision 
    too low to be included in the centered sum of squares. 
    +/
    assert(x.rawMoment!2.approxEqual(2.0e208 / 4));

    assert(x.rawMoment!(2, "kbn").approxEqual(2.0e208 / 4));
    assert(x.rawMoment!(2, "kb2").approxEqual(2.0e208 / 4));
    assert(x.rawMoment!(2, "precise").approxEqual(2.0e208 / 4));
    assert(x.rawMoment!(double, 2, "precise").approxEqual(2.0e208 / 4));

    auto y = uint.max.repeat(3);
    auto z = y.rawMoment!(ulong, 2);
    assert(z.approxEqual(cast(double) (cast(ulong) uint.max) ^^ 2u));
    static assert(is(typeof(z) == double));
}

// mir.complex test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex: Complex;
    import mir.complex.math: approxEqual;
    import mir.ndslice.slice: sliced;

    alias C = Complex!double;

    auto x = [C(1, 2), C(2, 3), C(3, 4), C(4, 5)].sliced;
    assert(x.rawMoment!2.approxEqual(C(-24, 80) / 4));
}

/++
rawMoment works for complex numbers and other user-defined types (that are either
implicitly convertible to floating point or if `isComplex` is true)
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import std.complex: Complex;
    import std.math.operations: isClose;

    auto x = [Complex!double(1, 2), Complex!double(2, 3), Complex!double(3, 4), Complex!double(4, 5)].sliced;
    assert(x.rawMoment!2.isClose(Complex!double(-24, 80)/ 4));
}

/// Arbitrary raw moment
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;

    assert(rawMoment!2(1.0, 2, 3).approxEqual(14.0 / 3));
    assert(rawMoment!(float, 2)(1, 2, 3).approxEqual(14f / 3));
}

// dynamic array test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    assert([1.0, 2, 3, 4].rawMoment!2.approxEqual(30.0 / 4));
}

// @nogc test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.rawMoment!2.approxEqual(126.062500 / 12));
}

/++
Calculates the n-th central moment of the input.

By default, if `F` is not floating point type or complex type, then the result
will have a `double` type if `F` is implicitly convertible to a floating point 
type or a type for which `isComplex!F` is true.

Params:
    F = controls type of output
    N = controls n-th central moment
    summation = algorithm for calculating sums (default: Summation.appropriate)

Returns:
    The n-th central moment of the input, must be floating point or complex type
+/
template centralMoment(F, size_t N, Summation summation = Summation.appropriate)
    if (N > 0)
{
    import mir.math.sum: ResolveSummationType;
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath meanType!F centralMoment(Range)(Range r)
        if (isIterable!Range)
    {
        alias G = typeof(return);
        static if (N > 1) {
            MeanAccumulator!(G, ResolveSummationType!(summation, Range, G)) meanAccumulator;
            MomentAccumulator!(G, N, ResolveSummationType!(summation, Range, G)) momentAccumulator;
            meanAccumulator.put(r.lightScope);
            momentAccumulator.put(r, meanAccumulator.mean);
            return momentAccumulator.moment;
        } else {
            return cast(G) 0.0;
        }
    }

    /++
    Params:
        ar = values
    +/
    @fmamath meanType!F centralMoment(scope const F[] ar...)
    {
        alias G = typeof(return);
        static if (N > 1) {
            MeanAccumulator!(G, ResolveSummationType!(summation, const(G)[], G)) meanAccumulator;
            MomentAccumulator!(G, N, ResolveSummationType!(summation, const(G)[], G)) momentAccumulator;
            meanAccumulator.put(ar);
            momentAccumulator.put(ar, meanAccumulator.mean);
            return momentAccumulator.moment;
        } else {
            return cast(G) 0.0;
        }
    }
}

/// ditto
template centralMoment(size_t N, Summation summation = Summation.appropriate)
    if (N > 0)
{
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath meanType!Range centralMoment(Range)(Range r)
        if(isIterable!Range)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .centralMoment!(F, N, summation)(r.move);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath meanType!T centralMoment(T)(scope const T[] ar...)
    {
        alias F = typeof(return);
        return .centralMoment!(F, N, summation)(ar);
    }
}

/// ditto
template centralMoment(F, size_t N, string summation)
    if (N > 0)
{
    mixin("alias centralMoment = .centralMoment!(F, N, Summation." ~ summation ~ ");");
}

/// ditto
template centralMoment(size_t N, string summation)
    if (N > 0)
{
    mixin("alias centralMoment = .centralMoment!(N, Summation." ~ summation ~ ");");
}

/// Basic implementation
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    assert(centralMoment!2([1.0, 2, 3]).approxEqual(2.0 / 3));
    assert(centralMoment!3([1.0, 2, 3]).approxEqual(0.0 / 3));

    assert(centralMoment!(float, 2)([0, 1, 2, 3, 4, 5].sliced(3, 2)).approxEqual(17.5f / 6));
    static assert(is(typeof(centralMoment!(float, 2)([1, 2, 3])) == float));
}

/// Central Moment of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.centralMoment!2.approxEqual(54.76562 / 12));
}

/// Central Moment of matrix
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

    assert(x.centralMoment!2.approxEqual(54.76562 / 12));
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;
    import mir.stat.transform: center;

    //Set sum algorithm or output type

    auto a = [1.0, 1e100, 1, -1e100].sliced;
    auto b = a * 10_000;
    auto x = b.center;

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean 
    from the second and fourth numbers has no effect. Further, after centering 
    and squaring `x`, the first and third numbers in the slice have precision 
    too low to be included in the centered sum of squares. 
    +/
    assert(x.centralMoment!2.approxEqual(2.0e208 / 4));

    assert(x.centralMoment!(2, "kbn").approxEqual(2.0e208 / 4));
    assert(x.centralMoment!(2, "kb2").approxEqual(2.0e208 / 4));
    assert(x.centralMoment!(2, "precise").approxEqual(2.0e208 / 4));
    assert(x.centralMoment!(double, 2, "precise").approxEqual(2.0e208 / 4));

    auto y = uint.max.repeat(3);
    auto z = y.centralMoment!(ulong, 2);
    assert(z.approxEqual(0.0));
    static assert(is(typeof(z) == double));
}

// mir.complex test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.complex: Complex;
    import mir.complex.math: approxEqual;
    import mir.ndslice.slice: sliced;

    alias C = Complex!double;

    auto x = [C(1, 2), C(2, 3), C(3, 4), C(4, 5)].sliced;
    assert(x.centralMoment!2.approxEqual(C(0, 10) / 4));
}

/++
centralMoment works for complex numbers and other user-defined types (that are
either implicitly convertible to floating point or if `isComplex` is true)
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import std.complex: Complex;
    import std.math.operations: isClose;

    auto x = [Complex!double(1, 2), Complex!double(2, 3), Complex!double(3, 4), Complex!double(4, 5)].sliced;
    assert(x.centralMoment!2.isClose(Complex!double(0, 10) / 4));
}

/// Arbitrary central moment
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;

    assert(centralMoment!2(1.0, 2, 3).approxEqual(2.0 / 3));
    assert(centralMoment!(float, 2)(1, 2, 3).approxEqual(2f / 3));
}

// dynamic array test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    assert([1.0, 2, 3, 4].centralMoment!2.approxEqual(5.0 / 4));
}

// @nogc test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.centralMoment!2.approxEqual(54.765625 / 12));
}

// test special casing
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.centralMoment!1.approxEqual(0.0 / 12));
}

///
enum StandardizedMomentAlgo
{
    /// Calculates n-th standardized moment as E(((x - u) / sigma) ^^ N)
    scaled,

    /// Calculates n-th standardized moment as E(((x - u) ^^ N) / ((x - u) ^^ (N / 2)))
    centered
}

/++
Calculates the n-th standardized moment of the input.

By default, if `F` is not floating point type, then the result will have a
`double` type if `F` is implicitly convertible to a floating point type.

Params:
    F = controls type of output
    N = controls n-th standardized moment
    summation = algorithm for calculating sums (default: Summation.appropriate)

Returns:
    The n-th standardized moment of the input, must be floating point
+/
template standardizedMoment(F, size_t N,
                            StandardizedMomentAlgo standardizedMomentAlgo = StandardizedMomentAlgo.scaled,
                            VarianceAlgo varianceAlgo = VarianceAlgo.twoPass,
                            Summation summation = Summation.appropriate)
    if (N > 0)
{
    import mir.math.sum: ResolveSummationType;
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath stdevType!F standardizedMoment(Range)(Range r)
        if (isIterable!Range)
    {
        alias G = typeof(return);
        static if (N > 2) {
            auto varianceAccumulator = VarianceAccumulator!(G, varianceAlgo, ResolveSummationType!(summation, Range, G))(r.lightScope);
            MomentAccumulator!(G, N, ResolveSummationType!(summation, Range, G)) momentAccumulator;
            static if (standardizedMomentAlgo == StandardizedMomentAlgo.scaled) {
                import mir.math.common: sqrt;

                momentAccumulator.put(r, varianceAccumulator.mean, varianceAccumulator.variance(true).sqrt);
                return momentAccumulator.moment;
            } else static if (standardizedMomentAlgo == StandardizedMomentAlgo.centered) {
                import mir.math.common: pow;

                momentAccumulator.put(r, varianceAccumulator.mean);
                return momentAccumulator.moment / pow(varianceAccumulator.variance(true), N / 2);
            }
        } else static if (N == 2) {
            return cast(G) 1.0;
        } else static if (N == 1) {
            return cast(G) 0.0;
        }
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!F standardizedMoment(scope const F[] ar...)
    {
        alias G = typeof(return);
        static if (N > 2) {
            auto varianceAccumulator = VarianceAccumulator!(G, varianceAlgo, ResolveSummationType!(summation, const(G)[], G))(ar);
            MomentAccumulator!(G, N, ResolveSummationType!(summation, const(G)[], G)) momentAccumulator;
            static if (standardizedMomentAlgo == StandardizedMomentAlgo.scaled) {
                import mir.math.common: sqrt;

                momentAccumulator.put(ar, varianceAccumulator.mean, varianceAccumulator.variance(true).sqrt);
                return momentAccumulator.moment;
            } else static if (standardizedMomentAlgo == StandardizedMomentAlgo.centered) {
                import mir.math.common: pow;

                momentAccumulator.put(ar, varianceAccumulator.mean);
                return momentAccumulator.moment / pow(varianceAccumulator.variance(true), N / 2);
            }
        } else static if (N == 2) {
            return cast(G) 1.0;
        } else static if (N == 1) {
            return cast(G) 0.0;
        }
    }
}

/// ditto
template standardizedMoment(size_t N,
                            StandardizedMomentAlgo standardizedMomentAlgo = StandardizedMomentAlgo.scaled,
                            VarianceAlgo varianceAlgo = VarianceAlgo.twoPass,
                            Summation summation = Summation.appropriate)
    if (N > 0)
{
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath stdevType!Range standardizedMoment(Range)(Range r)
        if(isIterable!Range)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .standardizedMoment!(F, N, standardizedMomentAlgo, varianceAlgo, summation)(r.move);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!T standardizedMoment(T)(scope const T[] ar...)
    {
        alias F = typeof(return);
        return .standardizedMoment!(F, N, standardizedMomentAlgo, varianceAlgo, summation)(ar);
    }
}

/// ditto
template standardizedMoment(F, size_t N, string standardizedMomentAlgo, string varianceAlgo = "twoPass", string summation = "appropriate")
    if (N > 0)
{
    mixin("alias standardizedMoment = .standardizedMoment!(F, N, StandardizedMomentAlgo." ~ standardizedMomentAlgo ~ ", VarianceAlgo." ~ varianceAlgo ~ ", Summation." ~ summation ~ ");");
}

/// ditto
template standardizedMoment(size_t N, string standardizedMomentAlgo, string varianceAlgo = "twoPass", string summation = "appropriate")
    if (N > 0)
{
    mixin("alias standardizedMoment = .standardizedMoment!(N, StandardizedMomentAlgo." ~ standardizedMomentAlgo ~ ", VarianceAlgo." ~ varianceAlgo ~ ", Summation." ~ summation ~ ");");
}

/// Basic implementation
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    assert(standardizedMoment!1([1.0, 2, 3]).approxEqual(0.0));
    assert(standardizedMoment!2([1.0, 2, 3]).approxEqual(1.0));
    assert(standardizedMoment!3([1.0, 2, 3]).approxEqual(0.0 / 3));
    assert(standardizedMoment!4([1.0, 2, 3]).approxEqual(4.5 / 3));

    assert(standardizedMoment!(float, 2)([0, 1, 2, 3, 4, 5].sliced(3, 2)).approxEqual(6f / 6));
    static assert(is(typeof(standardizedMoment!(float, 2)([1, 2, 3])) == float));
}

/// Standardized Moment of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.standardizedMoment!3.approxEqual(12.000999 / 12));
}

/// Standardized Moment of matrix
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

    assert(x.standardizedMoment!3.approxEqual(12.000999 / 12));
}

/// Can also set algorithm type
version(mir_stat_test)
@safe pure
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    auto x = a + 100_000_000_000;

    // The default algorithm is numerically stable in this case
    auto y = x.standardizedMoment!3;
    assert(y.approxEqual(12.000999 / 12));

    // The online algorithm is numerically unstable in this case
    auto z1 = x.standardizedMoment!(3, "scaled", "online");
    assert(!z1.approxEqual(12.000999 / 12));
    assert(!z1.approxEqual(y));

    // It is also numerically unstable when using StandardizedMomentAlgo.centered
    auto z2 = x.standardizedMoment!(3, "centered", "online");
    assert(!z2.approxEqual(12.000999 / 12));
    assert(!z2.approxEqual(y));
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    //Set standardized moment algorithm, variance algorithm, sum algorithm, or output type

    auto a = [1.0, 1e98, 1, -1e98].sliced;
    auto x = a * 10_000;

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean 
    from the second and fourth numbers has no effect. Further, after centering 
    and squaring `x`, the first and third numbers in the slice have precision 
    too low to be included in the centered sum of squares. 
    +/
    assert(x.standardizedMoment!3.approxEqual(0.0));

    assert(x.standardizedMoment!(3, "scaled", "online").approxEqual(0.0));
    assert(x.standardizedMoment!(3, "centered", "online").approxEqual(0.0));
    assert(x.standardizedMoment!(3, "scaled", "online", "kbn").approxEqual(0.0));
    assert(x.standardizedMoment!(3, "scaled", "online", "kb2").approxEqual(0.0));
    assert(x.standardizedMoment!(3, "scaled", "online", "precise").approxEqual(0.0));
    assert(x.standardizedMoment!(double, 3, "scaled", "online", "precise").approxEqual(0.0));

    auto y = [uint.max - 2, uint.max - 1, uint.max].sliced;
    auto z = y.standardizedMoment!(ulong, 3);
    assert(z == 0.0);
    static assert(is(typeof(z) == double));
}

/++
For integral slices, can pass output type as template parameter to ensure output
type is correct. By default, they get converted to double.
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0, 1, 1, 2, 4, 4,
              2, 7, 5, 1, 2, 0].sliced;

    auto y = x.standardizedMoment!3;
    assert(y.approxEqual(9.666455 / 12));
    static assert(is(typeof(y) == double));

    assert(x.standardizedMoment!(float, 3).approxEqual(9.666455f / 12));
}

/// Arbitrary standardized moment
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;

    assert(standardizedMoment!3(1.0, 2, 3).approxEqual(0.0 / 3));
    assert(standardizedMoment!(float, 3)(1, 2, 3).approxEqual(0f / 3));
    assert(standardizedMoment!(float, 3, "centered")(1, 2, 3).approxEqual(0f / 3));
}

// dynamic array test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    assert([1.0, 2, 3, 4].standardizedMoment!3.approxEqual(0.0 / 4));
}

// @nogc test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.standardizedMoment!3.approxEqual(12.000999 / 12));
}

// test special casing
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.standardizedMoment!1.approxEqual(0.0 / 12));
}

///
enum MomentAlgo
{
    /// nth raw moment, E(x ^^ n)
    raw,

    /// nth central moment, E((x - u) ^^ n)
    central,

    /// nth standardized moment, E(((x - u) / sigma) ^^ n)
    standardized
}

/++
Calculates the n-th moment of the input.

Params:
    F = controls type of output
    N = controls n-th standardized moment
    momentAlgo = type of moment to be calculated
    summation = algorithm for calculating sums (default: Summation.appropriate)

Returns:
    The n-th moment of the input, must be floating point or complex type
+/
template moment(F, size_t N,
                MomentAlgo momentAlgo,
                Summation summation = Summation.appropriate)
{
    import mir.math.sum: ResolveSummationType;
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath meanType!F moment(Range)(Range r)
        if (isIterable!Range && momentAlgo != MomentAlgo.standardized)
    {
        import core.lifetime: move;

        alias G = typeof(return);
        static if (momentAlgo == MomentAlgo.raw) {
            return .rawMoment!(G, N, ResolveSummationType!(summation, Range, G))(r.move);
        } else static if (momentAlgo == MomentAlgo.central) {
            return .centralMoment!(G, N, ResolveSummationType!(summation, Range, G))(r.move);
        }
    }

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath stdevType!F moment(Range)(Range r)
        if (isIterable!Range && momentAlgo == MomentAlgo.standardized)
    {
        import core.lifetime: move;

        alias G = typeof(return);
        return .standardizedMoment!(G, N, StandardizedMomentAlgo.scaled, VarianceAlgo.twoPass, ResolveSummationType!(summation, Range, G))(r.move);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath meanType!F moment()(scope const F[] ar...)
        if (momentAlgo != MomentAlgo.standardized)
    {
        alias G = typeof(return);
        static if (momentAlgo == MomentAlgo.raw) {
            return .rawMoment!(G, N, ResolveSummationType!(summation, const(G)[], G))(ar);
        } else static if (momentAlgo == MomentAlgo.central) {
            return .centralMoment!(G, N, ResolveSummationType!(summation, const(G)[], G))(ar);
        }
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!F moment()(scope const F[] ar...)
        if (momentAlgo == MomentAlgo.standardized)
    {
        alias G = typeof(return);
        return .standardizedMoment!(G, N, StandardizedMomentAlgo.scaled, VarianceAlgo.twoPass, ResolveSummationType!(summation, const(G)[], G))(ar);
    }
}

/// ditto
template moment(size_t N,
                MomentAlgo momentAlgo,
                Summation summation = Summation.appropriate)
{
    import std.traits: isIterable;

    /++
    Params:
        r = range, must be finite iterable
    +/
    @fmamath stdevType!Range moment(Range)(Range r)
        if(isIterable!Range)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .moment!(F, N, momentAlgo, summation)(r.move);
    }

    /++
    Params:
        ar = values
    +/
    @fmamath stdevType!T moment(T)(scope const T[] ar...)
    {
        alias F = typeof(return);
        return .moment!(F, N, momentAlgo, summation)(ar);
    }
}

/// ditto
template moment(F, size_t N, string momentAlgo, string summation = "appropriate")
{
    mixin("alias moment = .moment!(F, N, MomentAlgo." ~ momentAlgo ~ ", Summation." ~ summation ~ ");");
}

/// ditto
template moment(size_t N, string momentAlgo, string summation = "appropriate")
{
    mixin("alias moment = .moment!(N, MomentAlgo." ~ momentAlgo ~ ", Summation." ~ summation ~ ");");
}

/// Basic implementation
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    assert(moment!(1, "raw")([1.0, 2, 3]).approxEqual(6.0 / 3));
    assert(moment!(2, "raw")([1.0, 2, 3]).approxEqual(14.0 / 3));
    assert(moment!(3, "raw")([1.0, 2, 3]).approxEqual(36.0 / 3));
    assert(moment!(4, "raw")([1.0, 2, 3]).approxEqual(98.0 / 3));

    assert(moment!(1, "central")([1.0, 2, 3]).approxEqual(0.0 / 3));
    assert(moment!(2, "central")([1.0, 2, 3]).approxEqual(2.0 / 3));
    assert(moment!(3, "central")([1.0, 2, 3]).approxEqual(0.0 / 3));
    assert(moment!(4, "central")([1.0, 2, 3]).approxEqual(2.0 / 3));

    assert(moment!(1, "standardized")([1.0, 2, 3]).approxEqual(0.0));
    assert(moment!(2, "standardized")([1.0, 2, 3]).approxEqual(1.0));
    assert(moment!(3, "standardized")([1.0, 2, 3]).approxEqual(0.0 / 3));
    assert(moment!(4, "standardized")([1.0, 2, 3]).approxEqual(4.5 / 3));

    assert(moment!(float, 2, "standardized")([0, 1, 2, 3, 4, 5].sliced(3, 2)).approxEqual(6f / 6));
    static assert(is(typeof(moment!(float, 2, "standardized")([1, 2, 3])) == float));
}

/// Standardized Moment of vector
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;

    assert(x.moment!(3, "standardized").approxEqual(12.000999 / 12));
}

/// Standardized Moment of matrix
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

    assert(x.moment!(3, "standardized").approxEqual(12.000999 / 12));
}

/++
For integral slices, can pass output type as template parameter to ensure output
type is correct. By default, they get converted to double.
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    auto x = [0, 1, 1, 2, 4, 4,
              2, 7, 5, 1, 2, 0].sliced;

    auto y = x.moment!(3, "standardized");
    assert(y.approxEqual(9.666455 / 12));
    static assert(is(typeof(y) == double));

    assert(x.moment!(float, 3, "standardized").approxEqual(9.666455f / 12));
}

/// Arbitrary standardized moment
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;

    assert(moment!(3, "standardized")(1.0, 2, 3).approxEqual(0.0 / 3));
    assert(moment!(float, 3, "standardized")(1, 2, 3).approxEqual(0f / 3));
}

// dynamic array test
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;

    assert([1.0, 2, 3, 4].moment!(3, "standardized").approxEqual(0.0 / 4));
}

// @nogc test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;

    static immutable x = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
                          2.0, 7.5, 5.0, 1.0, 1.5, 0.0];

    assert(x.sliced.moment!(3, "standardized").approxEqual(12.000999 / 12));
}
