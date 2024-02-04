/++
This module contains algorithms for multivariate descriptive statistics.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2023 Mir Stat Authors.

Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, stat, $1)$(NBSP)
MATHREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, math, $1)$(NBSP)
MATHREF_ALT = $(GREF_ALTTEXT mir-algorithm, $(B $(TT $2)), $2, mir, math, $1)$(NBSP)
NDSLICEREF = $(GREF_ALTTEXT mir-algorithm, $(TT $2), $2, mir, ndslice, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
T3=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3))
T4=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4))

+/

module mir.stat.descriptive.multivariate;

import mir.internal.utility: isFloatingPoint;
import mir.math.sum: Summation, Summator;
import std.traits: isMutable;

private void putter3(Slices, T, U, Summation summation1, Summation summation2, Summation summation3)
    (scope Slices slices, ref Summator!(T, summation1) seed1, ref Summator!(U, summation2) seed2, ref Summator!(U, summation3) seed3)
{
    import mir.functional: Tuple;
    static if (is(Slices == Tuple!(V1, V2, V3), V1, V2, V3)) {
        seed1.put(slices[0]);
        seed2.put(slices[1]);
        seed3.put(slices[2]);
    } else {
        import mir.ndslice.internal: frontOfDim;
        do
        {
            frontOfDim!(0, slices)[0].putter3(seed1, seed2, seed3);
            slices.popFront;
        }
        while(!slices.empty);
    }
}

/++
Covariance algorithms.

See Also:
    $(WEB en.wikipedia.org/wiki/Algorithms_for_calculating_variance, Algorithms for calculating variance).
+/
enum CovarianceAlgo
{
    /++
    Performs Welford's online algorithm for updating covariance. While it only
    iterates each input once, it can be slower for smaller inputs. However, it
    is also more accurate. Can also `put` another CovarianceAccumulator of the
    same type, which uses the parallel algorithm from Chan et al.
    +/
    online,
   
    /++
    Calculates covariance using E(x*y) - E(x)*E(y) (alowing for adjustments for
    population/sample variance). This algorithm can be numerically unstable.
    +/
    naive,

    /++
    Calculates covariance using a two-pass algorithm whereby the inputs are first
    centered and then the sum of products is calculated from that. May be faster
    than `online` and generally more accurate than the `naive` algorithm.
    +/
    twoPass,

    /++
    Calculates covariance assuming the mean of the inputs is zero.
    +/
    assumeZeroMean,

    /++
    When slices, slice-like objects, or ranges are the inputs, uses the two-pass
    algorithm. When an individual data-point is added, uses the online algorithm.
    +/
    hybrid
}

///
struct CovarianceAccumulator(T, CovarianceAlgo covarianceAlgo, Summation summation)
    if (isMutable!T && covarianceAlgo == CovarianceAlgo.naive)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import mir.primitives: isInputRange, front, empty, popFront;

    ///
    private size_t _count;
    ///
    alias S = Summator!(T, summation);
    ///
    S summatorLeft;
    ///
    S summatorRight;
    ///
    S summatorOfProducts;

    ///
    this(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX &&
            isInputRange!RangeY)
    {
        import core.lifetime: move;
        this.put(x.move, y.move);
    }

    ///
    void put(IteratorX, IteratorY, SliceKind kindX, SliceKind kindY)(
        Slice!(IteratorX, 1, kindX) x,
        Slice!(IteratorY, 1, kindY) y
    )
    in
    {
        assert(x.length == y.length,
               "CovarianceAcumulator.put: both vectors must have the same length");
    }
    do
    {
        import mir.ndslice.topology: zip, map;

        _count += x.length;
        summatorLeft.put(x);
        summatorRight.put(y);
        summatorOfProducts.put(x.zip(y).map!"a * b");
    }

    ///
    void put(SliceLikeX, SliceLikeY)(SliceLikeX x, SliceLikeY y)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeY && !isSlice!SliceLikeY)
    {
        import mir.ndslice.slice: toSlice;
        this.put(x.toSlice, y.toSlice);
    }

    ///
    void put(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && !isConvertibleToSlice!RangeX && is(elementType!RangeX : T) &&
            isInputRange!RangeY && !isConvertibleToSlice!RangeY && is(elementType!RangeY : T))
    {
        do
        {
            assert(!(!x.empty && y.empty) && !(x.empty && !y.empty),
                   "x and y must both be empty at the same time, one cannot be empty while the other has remaining items");
            this.put(x.front, y.front);
            x.popFront;
            y.popFront;
        } while(!x.empty || !y.empty); // Using an || instead of && so that the loop does not end early. mis-matched lengths of x and y sould be caught by above assert
    }

    ///
    void put()(T x, T y)
    {
        _count++;
        summatorLeft.put(x);
        summatorRight.put(y);
        summatorOfProducts.put(x * y);
    }

    ///
    void put(U, Summation sumAlgo)(CovarianceAccumulator!(U, covarianceAlgo, sumAlgo) v)
    {
        _count += v.count;
        summatorLeft.put(v.sumLeft!U);
        summatorRight.put(v.sumRight!U);
        summatorOfProducts.put(v.sumOfProducts!U);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F sumLeft(F = T)() @property
    {
        return cast(F) summatorLeft.sum;
    }
    ///
    F sumRight(F = T)() @property
    {
        return cast(F) summatorRight.sum;
    }
    ///
    F meanLeft(F = T)() @property
    {
        return sumLeft!F / count;
    }
    ///
    F meanRight(F = T)() @property
    {
        return sumRight!F / count;
    }
    ///
    F sumOfProducts(F = T)() @property
    {
        return cast(F) summatorOfProducts.sum;
    }
    ///
    F centeredSumOfProducts(F = T)() @property
    {
        return sumOfProducts!F - sumLeft!F * sumRight!F / count;
    }
    ///
    F covariance(F = T)(bool isPopulation) @property
        in (count + isPopulation > 1, "More data points required")
    {
        return sumOfProducts!F / (count + isPopulation - 1) -
            (sumLeft!F * sumRight!F) * (F(1) / (count * (count + isPopulation - 1)));
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CovarianceAccumulator!(double, CovarianceAlgo.naive, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == 82.25 / 12 - (29.25 * 36) / (12 * 12);
    v.covariance(false).shouldApprox == 82.25 / 11 - (29.25 * 36) / (12 * 12) * (12.0 / 11);

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == 94.25 / 13 - (33.25 * 39) / (13 * 13);
    v.covariance(false).shouldApprox == 94.25 / 12 - (33.25 * 39) / (13 * 13) * (13.0 / 12);
}

// Check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25];

    CovarianceAccumulator!(double, CovarianceAlgo.naive, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == 82.25 / 12 - (29.25 * 36) / (12 * 12);
    v.covariance(false).shouldApprox == 82.25 / 11 - (29.25 * 36) / (12 * 12) * (12.0 / 11);

    v.meanLeft.shouldApprox == 2.4375;
    v.meanRight.shouldApprox == 3;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == 94.25 / 13 - (33.25 * 39) / (13 * 13);
    v.covariance(false).shouldApprox == 94.25 / 12 - (33.25 * 39) / (13 * 13) * (13.0 / 12);
}

// rcslice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.allocation: mininitRcslice;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;
    auto v = CovarianceAccumulator!(double, CovarianceAlgo.naive, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;
}

// Check adding CovarianceAccumultors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CovarianceAccumulator!(double, CovarianceAlgo.naive, Summation.naive) v1;
    v1.put(x1, y1);
    CovarianceAccumulator!(double, CovarianceAlgo.naive, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.range: iota;

    auto x = iota(0, 5);
    auto y = iota(-3, 2);
    CovarianceAccumulator!(double, CovarianceAlgo.naive, Summation.naive) v;
    v.put(x, y);
    v.covariance(true).should == 10.0 / 5;
}

///
struct CovarianceAccumulator(T, CovarianceAlgo covarianceAlgo, Summation summation)
    if (isFloatingPoint!T && isMutable!T && covarianceAlgo == CovarianceAlgo.online)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import mir.primitives: isInputRange, front, empty, popFront;

    ///
    private size_t _count;
    ///
    alias S = Summator!(T, summation);
    ///
    S summatorLeft;
    ///
    S summatorRight;
    ///
    S centeredSummatorOfProducts;

    ///
    this(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        import core.lifetime: move;
        this.put(x.move, y.move);
    }

    ///
    this()(T x, T y)
    {
        this.put(x, y);
    }

    ///
    void put(IteratorX, IteratorY, SliceKind kindX, SliceKind kindY)(
        Slice!(IteratorX, 1, kindX) x,
        Slice!(IteratorY, 1, kindY) y
    )
    in
    {
        assert(x.length == y.length,
               "CovarianceAcumulator.put: both vectors must have the same length");
    }
    do
    {
        import mir.ndslice.topology: zip;

        foreach(e; x.zip(y)) {
            this.put(e[0], e[1]);
        }
    }

    ///
    void put(SliceLikeX, SliceLikeY)(SliceLikeX x, SliceLikeY y)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeY && !isSlice!SliceLikeY)
    {
        import mir.ndslice.slice: toSlice;
        this.put(x.toSlice, y.toSlice);
    }

    ///
    void put(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && !isConvertibleToSlice!RangeX &&
            isInputRange!RangeY && !isConvertibleToSlice!RangeY)
    {
        import std.range: zip;
        foreach(a, b; zip(x, y)) {
            this.put(a, b);
        }
    }

    ///
    void put()(T x, T y)
    {
        T delta = x;
        if (count > 0) {
            delta -= meanLeft;
        }
        _count++;
        summatorLeft.put(x);
        summatorRight.put(y);
        centeredSummatorOfProducts.put(delta * (y - meanRight));
    }

    ///
    void put(U, CovarianceAlgo covAlgo, Summation sumAlgo)(CovarianceAccumulator!(U, covAlgo, sumAlgo) v)
        if (covAlgo != CovarianceAlgo.assumeZeroMean)
    {
        size_t oldCount = count;
        T deltaLeft = v.meanLeft;
        T deltaRight = v.meanRight;
        if (count > 0) {
            deltaLeft -= meanLeft!T;
            deltaRight -= meanRight!T;
        }
        _count += v.count;
        summatorLeft.put(v.sumLeft!T);
        summatorRight.put(v.sumRight!T);
        centeredSummatorOfProducts.put(v.centeredSumOfProducts!T + deltaLeft * deltaRight * v.count * oldCount / count);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F sumLeft(F = T)() @property
    {
        return cast(F) summatorLeft.sum;
    }
    ///
    F sumRight(F = T)() @property
    {
        return cast(F) summatorRight.sum;
    }
    ///
    F meanLeft(F = T)() @property
    {
        return sumLeft!F / count;
    }
    ///
    F meanRight(F = T)() @property
    {
        return sumRight!T / count;
    }
    ///
    F centeredSumOfProducts(F = T)() @property
    {
        return cast(F) centeredSummatorOfProducts.sum;
    }
    ///
    F covariance(F = T)(bool isPopulation) @property
        in (count + isPopulation > 1, "More data points required")
    {
        return centeredSumOfProducts!F / (count + isPopulation - 1);
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CovarianceAccumulator!(double, CovarianceAlgo.online, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == -5.5 / 13;
    v.covariance(false).shouldApprox == -5.5 / 12;
}

// Check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25];

    CovarianceAccumulator!(double, CovarianceAlgo.online, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.meanLeft.shouldApprox == 2.4375;
    v.meanRight.shouldApprox == 3;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == -5.5 / 13;
    v.covariance(false).shouldApprox == -5.5 / 12;
}

// rcslice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.allocation: mininitRcslice;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;
    auto v = CovarianceAccumulator!(double, CovarianceAlgo.online, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;
}

// Check adding CovarianceAccumultors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CovarianceAccumulator!(double, CovarianceAlgo.online, Summation.naive) v1;
    v1.put(x1, y1);
    CovarianceAccumulator!(double, CovarianceAlgo.online, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;
}

// Check adding CovarianceAccumultors (naive)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CovarianceAccumulator!(double, CovarianceAlgo.online, Summation.naive) v1;
    v1.put(x1, y1);
    CovarianceAccumulator!(double, CovarianceAlgo.naive, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;
}

// Check adding CovarianceAccumultors (twoPass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CovarianceAccumulator!(double, CovarianceAlgo.online, Summation.naive) v1;
    v1.put(x1, y1);
    auto v2 = CovarianceAccumulator!(double, CovarianceAlgo.twoPass, Summation.naive)(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;
}

// Initializing with one point
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;

    auto v = CovarianceAccumulator!(double, CovarianceAlgo.online, Summation.naive)(4.0, 3.0);
    v.covariance(true).should == 0;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.range: chunks, iota;

    auto x = iota(0, 5);
    auto y = iota(-3, 2);
    CovarianceAccumulator!(double, CovarianceAlgo.online, Summation.naive) v;
    v.put(x, y);
    v.covariance(true).should == 10 / 5;
    CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive) v2;
    v2.put(x.chunks(1), y.chunks(1));
    v2.covariance(true).should == 10 / 5;
}

///
struct CovarianceAccumulator(T, CovarianceAlgo covarianceAlgo, Summation summation)
    if (isMutable!T && covarianceAlgo == CovarianceAlgo.twoPass)
{
    import mir.functional: naryFun;
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import mir.primitives: isInputRange, front, empty, popFront;
    import mir.stat.descriptive.univariate: MeanAccumulator;

    ///
    private size_t _count;
    ///
    alias S = Summator!(T, summation);
    ///
    private S summatorLeft;
    ///
    private S summatorRight;
    ///
    private S centeredSummatorOfProducts;

    ///
    this(IteratorX, IteratorY, SliceKind kindX, SliceKind kindY)(
         Slice!(IteratorX, 1, kindX) x, Slice!(IteratorY, 1, kindY) y)
     in
     {
        assert(x.length == y.length,
               "CovarianceAcumulator.put: both vectors must have the same length");
     }
     do
    {
        import mir.ndslice.internal: LeftOp;
        import mir.ndslice.topology: map, vmap, zip;

        _count = x.length;
        summatorLeft.put(x.lightScope);
        summatorRight.put(y.lightScope);
        centeredSummatorOfProducts.put(x.vmap(LeftOp!("-", T)(meanLeft)).zip(y.vmap(LeftOp!("-", T)(meanRight))).map!(naryFun!"a * b"));
    }

    ///
    this(SliceLikeX, SliceLikeY)(SliceLikeX x, SliceLikeY y)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeY && !isSlice!SliceLikeY)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice, y.toSlice);
    }

    ///
    this(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && !isConvertibleToSlice!RangeX && is(elementType!RangeX : T) &&
            isInputRange!RangeY && !isConvertibleToSlice!RangeY && is(elementType!RangeY : T))
    {
        import mir.primitives: elementCount, hasShape;

        static if (hasShape!RangeX && hasShape!RangeY) {
            assert(x.elementCount == y.elementCount);
            _count += x.elementCount;
            summatorLeft.put(x);
            summatorRight.put(y);
        } else {
            import std.range: zip;

            foreach(a, b; zip(x, y)) {
                _count++;
                summatorLeft.put(a);
                summatorRight.put(b);
            }
        }

        T xMean = meanLeft;
        T yMean = meanRight;
        do
        {
            assert(!(!x.empty && y.empty) && !(x.empty && !y.empty),
                   "x and y must both be empty at the same time, one cannot be empty while the other has remaining items");
            centeredSummatorOfProducts.put((x.front - xMean) * (y.front - yMean));
            x.popFront;
            y.popFront;
        } while(!x.empty || !y.empty); // Using an || instead of && so that the loop does not end early. mis-matched lengths of x and y sould be caught by above assert
    }

    ///
    this()(T x, T y)
    {
        _count++;
        summatorLeft.put(x);
        summatorRight.put(y);
        centeredSummatorOfProducts.put(0);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F sumLeft(F = T)() @property
    {
        return cast(F) summatorLeft.sum;
    }
    ///
    F sumRight(F = T)() @property
    {
        return cast(F) summatorRight.sum;
    }
    ///
    F meanLeft(F = T)() @property
    {
        return sumLeft!F / count;
    }
    ///
    F meanRight(F = T)() @property
    {
        return sumRight!F / count;
    }
    ///
    F centeredSumOfProducts(F = T)() @property
    {
        return cast(F) centeredSummatorOfProducts.sum;
    }
    ///
    F covariance(F = T)(bool isPopulation) @property
        in (count + isPopulation > 1, "More data points required")
    {
        return centeredSumOfProducts!F / (count + isPopulation - 1);
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    auto v = CovarianceAccumulator!(double, CovarianceAlgo.twoPass, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;
}

// Check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25];

    auto v = CovarianceAccumulator!(double, CovarianceAlgo.twoPass, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.meanLeft.shouldApprox == 2.4375;
    v.meanRight.shouldApprox ==3;
}

// rcslice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.allocation: mininitRcslice;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;
    auto v = CovarianceAccumulator!(double, CovarianceAlgo.twoPass, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;
}

// Check Vmap
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;
    auto x = a + 1;
    auto y = b - 1;

    auto v = CovarianceAccumulator!(double, CovarianceAlgo.twoPass, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;
}

// Initializing with one point
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;

    auto v = CovarianceAccumulator!(double, CovarianceAlgo.twoPass, Summation.naive)(4.0, 3.0);
    v.centeredSumOfProducts.should == 0;
}

// withAsSlice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.rc.array: RCArray;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];
    auto y = RCArray!double(12);
    foreach(i, ref e; y)
        e = b[i];

    auto v = CovarianceAccumulator!(double, CovarianceAlgo.twoPass, Summation.naive)(x, y);
    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;
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
    auto y1 = iota(-3, 2);
    auto v1 = CovarianceAccumulator!(double, CovarianceAlgo.twoPass, Summation.naive)(x1, y1);
    v1.covariance(true).should == 10.0 / 5;

    // this version can't use elementCount
    auto x2 = x1.map!(a => 2 * a);
    auto y2 = y1.map!(a => 2 * a);
    auto v2 = CovarianceAccumulator!(double, CovarianceAlgo.twoPass, Summation.naive)(x2, y2);
    v2.covariance(true).should == 40.0 / 5;
}

///
struct CovarianceAccumulator(T, CovarianceAlgo covarianceAlgo, Summation summation)
    if (isMutable!T && covarianceAlgo == CovarianceAlgo.assumeZeroMean)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: Slice, SliceKind, hasAsSlice, isConvertibleToSlice, isSlice;
    import mir.primitives: isInputRange, front, empty, popFront;

    private size_t _count;

    ///
    Summator!(T, summation) centeredSummatorOfProducts;

    ///
    this(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        this.put(x, y);
    }

    ///
    this()(T x, T y)
    {
        this.put(x, y);
    }

    ///
    void put(IteratorX, IteratorY, SliceKind kindX, SliceKind kindY)(
        Slice!(IteratorX, 1, kindX) x,
        Slice!(IteratorY, 1, kindY) y
    )
    in
    {
        assert(x.length == y.length,
               "CovarianceAcumulator.put: both vectors must have the same length");
    }
    do
    {
        import mir.ndslice.topology: zip, map;

        _count += x.length;
        centeredSummatorOfProducts.put(x.zip(y).map!"a * b");
    }

    ///
    void put(SliceLikeX, SliceLikeY)(SliceLikeX x, SliceLikeY y)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeY && !isSlice!SliceLikeY)
    {
        import mir.ndslice.slice: toSlice;
        this.put(x.toSlice, y.toSlice);
    }

    ///
    void put(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && !isConvertibleToSlice!RangeX && is(elementType!RangeX : T) &&
            isInputRange!RangeY && !isConvertibleToSlice!RangeY && is(elementType!RangeY : T))
    {
        do
        {
            assert(!(!x.empty && y.empty) && !(x.empty && !y.empty),
                   "x and y must both be empty at the same time, one cannot be empty while the other has remaining items");
            this.put(x.front, y.front);
            x.popFront;
            y.popFront;
        } while(!x.empty || !y.empty); // Using an || instead of && so that the loop does not end early. mis-matched lengths of x and y sould be caught by above assert
    }

    ///
    void put()(T x, T y)
    {
        _count++;
        centeredSummatorOfProducts.put(x * y);
    }

    ///
    void put(U, Summation sumAlgo)(CovarianceAccumulator!(U, covarianceAlgo, sumAlgo) v)
    {
        _count += v.count;
        centeredSummatorOfProducts.put(v.centeredSumOfProducts!T);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F sumLeft(F = T)() @property
    {
        return 0;
    }
    ///
    F sumRight(F = T)() @property
    {
        return 0;
    }
    ///
    F meanLeft(F = T)() @property
    {
        return 0;
    }
    ///
    F meanRight(F = T)() @property
    {
        return 0;
    }
    ///
    F centeredSumOfProducts(F = T)() @property
    {
        return cast(F) centeredSummatorOfProducts.sum;
    }
    ///
    F covariance(F = T)(bool isPopulation) @property
        in (count + isPopulation > 1, "More data points required")
    {
        return centeredSumOfProducts!F / (count + isPopulation - 1);
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.stat.transform: center;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;
    auto x = a.center;
    auto y = b.center;

    CovarianceAccumulator!(double, CovarianceAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == 6.5 / 13;
    v.covariance(false).shouldApprox == 6.5 / 12;
}

// Check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.stat.descriptive.univariate: mean;
    import mir.test: should, shouldApprox;

    auto a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    auto b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto aMean = a.mean;
    auto bMean = b.mean;
    auto x = a.dup;
    auto y = b.dup;
    for (size_t i; i < a.length; i++) {
        x[i] -= aMean;
        y[i] -= bMean;
    }

    CovarianceAccumulator!(double, CovarianceAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == 6.5 / 13;
    v.covariance(false).shouldApprox == 6.5 / 12;
   
    v.meanLeft.should == 0;
    v.meanRight.should == 0;
}

// rcslice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.allocation: mininitRcslice;
    import mir.stat.transform: center;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;
    auto v = CovarianceAccumulator!(double, CovarianceAlgo.assumeZeroMean, Summation.naive)(x.center, y.center);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;
}

// Check adding CovarianceAccumultors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto a1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto b1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto a2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto b2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;
    auto meanA = (a1.sum + a2.sum) / 12;
    auto meanB = (b1.sum + b2.sum) / 12;
    auto x1 = a1 - meanA;
    auto y1 = b1 - meanB;
    auto x2 = a2 - meanA;
    auto y2 = b2 - meanB;

    CovarianceAccumulator!(double, CovarianceAlgo.assumeZeroMean, Summation.naive) v1;
    v1.put(x1, y1);
    CovarianceAccumulator!(double, CovarianceAlgo.assumeZeroMean, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;
}

// Initializing with one point
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;

    auto v = CovarianceAccumulator!(double, CovarianceAlgo.assumeZeroMean, Summation.naive)(4.0, 3.0);
    v.centeredSumOfProducts.should == 12;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.range: iota;

    auto x = iota(0, 5);
    auto y = iota(-3, 2);
    auto v = CovarianceAccumulator!(double, CovarianceAlgo.assumeZeroMean, Summation.naive)(x, y);
    v.centeredSumOfProducts.should == 0;
}

///
struct CovarianceAccumulator(T, CovarianceAlgo covarianceAlgo, Summation summation)
    if (isFloatingPoint!T && isMutable!T && covarianceAlgo == CovarianceAlgo.hybrid)
{
    import mir.functional: naryFun;
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import mir.primitives: isInputRange, front, empty, popFront;

    ///
    private size_t _count;
    ///
    alias S = Summator!(T, summation);
    ///
    S summatorLeft;
    ///
    S summatorRight;
    ///
    S centeredSummatorOfProducts;

    ///
    this()(T x, T y)
    {
        this.put(x, y);
    }

    ///
    this(IteratorX, IteratorY, SliceKind kindX, SliceKind kindY)(
        Slice!(IteratorX, 1, kindX) x,
        Slice!(IteratorY, 1, kindY) y
    )
    in
    {
        assert(x.length == y.length,
               "CovarianceAcumulator.put: both vectors must have the same length");
    }
    do
    {
        import mir.ndslice.internal: LeftOp;
        import mir.ndslice.topology: map, vmap, zip;

        _count += x.length;
        summatorLeft.put(x.lightScope);
        summatorRight.put(y.lightScope);
        centeredSummatorOfProducts.put(x.vmap(LeftOp!("-", T)(meanLeft)).zip(y.vmap(LeftOp!("-", T)(meanRight))).map!(naryFun!"a * b"));
    }

    ///
    this(SliceLikeX, SliceLikeY)(SliceLikeX x, SliceLikeY y)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeY && !isSlice!SliceLikeY)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice, y.toSlice);
    }

    ///
   this(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && !isConvertibleToSlice!RangeX &&
            isInputRange!RangeY && !isConvertibleToSlice!RangeY)
    {
        static if (is(elementType!RangeX : T) && is(elementType!RangeY : T)) {
            import mir.primitives: elementCount, hasShape;

            static if (hasShape!RangeX && hasShape!RangeY) {
                assert(x.elementCount == y.elementCount);
                _count += x.elementCount;
                summatorLeft.put(x);
                summatorRight.put(y);
            } else {
                import std.range: zip;

                foreach(a, b; zip(x, y)) {
                    _count++;
                    summatorLeft.put(a);
                    summatorRight.put(b);
                }
            }

            T xMean = meanLeft;
            T yMean = meanRight;
            do
            {
                assert(!(!x.empty && y.empty) && !(x.empty && !y.empty),
                       "x and y must both be empty at the same time, one cannot be empty while the other has remaining items");
                centeredSummatorOfProducts.put((x.front - xMean) * (y.front - yMean));
                x.popFront;
                y.popFront;
            } while(!x.empty || !y.empty); // Using an || instead of && so that the loop does not end early. mis-matched lengths of x and y sould be caught by above assert
        } else {
            this.put(x, y);
        }
    }

    ///
    void put(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        static if (is(elementType!RangeX : T) && is(elementType!RangeY : T)) {
            auto v = typeof(this)(x, y);
            this.put(v);
        } else {
            import std.range: zip;
            foreach(a, b; zip(x, y)) {
                this.put(a, b);
            }
        }
    }

    ///
    void put()(T x, T y)
    {
        T delta = x;
        if (count > 0) {
            delta -= meanLeft;
        }
        _count++;
        summatorLeft.put(x);
        summatorRight.put(y);
        centeredSummatorOfProducts.put(delta * (y - meanRight));
    }

    ///
    void put(U, CovarianceAlgo covAlgo, Summation sumAlgo)(CovarianceAccumulator!(U, covAlgo, sumAlgo) v)
    {
        size_t oldCount = count;
        T deltaLeft = v.meanLeft!T;
        T deltaRight = v.meanRight!T;
        if (oldCount > 0) {
            deltaLeft -= meanLeft;
            deltaRight -= meanRight;
        }
        _count += v.count;
        summatorLeft.put(v.sumLeft!T);
        summatorRight.put(v.sumRight!T);
        centeredSummatorOfProducts.put(v.centeredSumOfProducts!T + deltaLeft * deltaRight * v.count * oldCount / count);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F sumLeft(F = T)() @property
    {
        return cast(F) summatorLeft.sum;
    }
    ///
    F sumRight(F = T)() @property
    {
        return cast(F) summatorRight.sum;
    }
    ///
    F meanLeft(F = T)() @property
    {
        return sumLeft!F / count;
    }
    ///
    F meanRight(F = T)() @property
    {
        return sumRight!F / count;
    }
    ///
    F centeredSumOfProducts(F = T)() @property
    {
        return cast(F) centeredSummatorOfProducts.sum;
    }
    ///
    F covariance(F = T)(bool isPopulation) @property
        in (count + isPopulation > 1, "More data points required")
    {
        return centeredSumOfProducts!F / (count + isPopulation - 1);
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == -5.5 / 13;
    v.covariance(false).shouldApprox == -5.5 / 12;
}

// Check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25];

    CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.meanLeft.shouldApprox == 2.4375;
    v.meanRight.shouldApprox == 3;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == -5.5 / 13;
    v.covariance(false).shouldApprox == -5.5 / 12;
}

// rcslice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.allocation: mininitRcslice;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;
    auto v = CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;
}

// Check adding CovarianceAccumultors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive) v1;
    v1.put(x1, y1);
    CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;
}

// Check adding CovarianceAccumultors (naive)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive) v1;
    v1.put(x1, y1);
    CovarianceAccumulator!(double, CovarianceAlgo.naive, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;
}

// Check adding CovarianceAccumultors (twoPass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive) v1;
    v1.put(x1, y1);
    auto v2 = CovarianceAccumulator!(double, CovarianceAlgo.twoPass, Summation.naive)(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;
}

// Check adding CovarianceAccumultors (assumeZeroMean)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;
    import mir.test: shouldApprox;

    auto a1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto b1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto a2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto b2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;
    auto x1 = a1.center;
    auto y1 = b1.center;
    auto x2 = a2.center;
    auto y2 = b2.center;

    CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive) v1;
    v1.put(x1, y1);
    auto v2 = CovarianceAccumulator!(double, CovarianceAlgo.assumeZeroMean, Summation.naive)(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -1.9375 / 12; //note: different from above due to inconsistent centering
    v1.covariance(false).shouldApprox == -1.9375 / 11; //note: different from above due to inconsistent centering
}

// Initializing with one point
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;

    auto v = CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive)(4.0, 3.0);
    v.covariance(true).should == 0;
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
    auto y1 = iota(-3, 2);
    CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive) v1;
    v1.put(x1, y1);
    v1.covariance(true).should == 10.0 / 5;
    // this version can't use elementCount
    CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive) v2;
    auto x2 = x1.map!(a => 2 * a);
    auto y2 = y1.map!(a => 2 * a);
    v2.put(x2, y2);
    v2.covariance(true).should == 40.0 / 5;
    CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive) v3;
    v3.put(x1.chunks(1), y1.chunks(1));
    v3.covariance(true).should == 10.0 / 5;
    auto v4 = CovarianceAccumulator!(double, CovarianceAlgo.hybrid, Summation.naive)(x1.chunks(1), y1.chunks(1));
    v4.covariance(true).should == 10.0 / 5;
}

/++
Calculates the covariance of the inputs.

If `x` and `y` are both slices or convertible to slices, then they must be
one-dimensional.

By default, if `F` is not floating point type, then the result will have a
`double` type if `F` is implicitly convertible to a floating point type.

Params:
    F = controls type of output
    covarianceAlgo = algorithm for calculating covariance (default: CovarianceAlgo.hybrid)
    summation = algorithm for calculating sums (default: Summation.appropriate)
Returns:
    The covariance of the inputs
+/
template covariance(F,
                    CovarianceAlgo covarianceAlgo = CovarianceAlgo.hybrid,
                    Summation summation = Summation.appropriate)
    if (isFloatingPoint!F)
{
    import mir.math.common: fmamath;
    import mir.primitives: isInputRange;
    import mir.math.sum: ResolveSummationType;
    /++
    Params:
        x = range, must be finite iterable
        y = range, must be finite iterable
        isPopulation = true if population covariance, false if sample covariance (default)
    +/
    @fmamath F covariance(RangeX, RangeY)(RangeX x, RangeY y, bool isPopulation = false)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        import core.lifetime: move;

        auto covarianceAccumulator = CovarianceAccumulator!(F, covarianceAlgo, ResolveSummationType!(summation, RangeX, F))(x.move, y.move);
        return covarianceAccumulator.covariance(isPopulation);
    }
}

/// ditto
template covariance(
    CovarianceAlgo covarianceAlgo = CovarianceAlgo.hybrid,
    Summation summation = Summation.appropriate)
{
    import mir.math.common: fmamath;
    import mir.primitives: isInputRange;
    import mir.stat.descriptive.univariate: meanType;
    import std.traits: CommonType;
    /++
    Params:
        x = range, must be finite iterable
        y = range, must be finite iterable
        isPopulation = true if population covariance, false if sample covariance (default)
    +/
    @fmamath CommonType!(meanType!RangeX, meanType!RangeY) covariance(RangeX, RangeY)(RangeX x, RangeY y, bool isPopulation = false)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .covariance!(F, covarianceAlgo, summation)(x.move, y.move, isPopulation);
    }
}

/// ditto
template covariance(F, string covarianceAlgo, string summation = "appropriate")
{
    mixin("alias covariance = .covariance!(F, CovarianceAlgo." ~ covarianceAlgo ~ ", Summation." ~ summation ~ ");");
}

/// ditto
template covariance(string covarianceAlgo, string summation = "appropriate")
{
    mixin("alias covariance = .covariance!(CovarianceAlgo." ~ covarianceAlgo ~ ", Summation." ~ summation ~ ");");
}

/// Covariance of vectors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    x.covariance(y, true).shouldApprox == -5.5 / 12;
    x.covariance(y).shouldApprox == -5.5 / 11;
}

/// Can also set algorithm type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    auto x = a + 10.0 ^^ 9;
    auto y = b + 10.0 ^^ 9;

    x.covariance(y).shouldApprox == -5.5 / 11;

    // The naive algorithm is numerically unstable in this case
    assert(!x.covariance!"naive"(y).approxEqual(-5.5 / 11));

    // The two-pass algorithm provides the same answer as hybrid
    x.covariance!"twoPass"(y).shouldApprox == -5.5 / 11;

    // And the assumeZeroMean algorithm is way off
    assert(!x.covariance!"assumeZeroMean"(y).approxEqual(-5.5 / 11));
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;
    import mir.test: shouldApprox;

    //Set population covariance, covariance algorithm, sum algorithm or output type

    auto a = [1.0, 1e100, 1, -1e100].sliced;
    auto b = [1.0e100, 1, 1, -1e100].sliced;
    auto x = a * 10_000;
    auto y = b * 10_000;

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean
    from the second and fourth numbers has no effect (for `y` the same is true
    for the first and fourth). Further, after centering and multiplying `x` and
    `y`, the third numbers in the slice has precision too low to be included in
    the centered sum of the products.
    +/
    x.covariance(y).shouldApprox == 1.0e208 / 3;
    x.covariance(y, true).shouldApprox == 1.0e208 / 4;

    x.covariance!("online")(y).shouldApprox == 1.0e208 / 3;
    x.covariance!("online", "kbn")(y).shouldApprox == 1.0e208 / 3;
    x.covariance!("online", "kb2")(y).shouldApprox == 1.0e208 / 3;
    x.covariance!("online", "precise")(y).shouldApprox == 1.0e208 / 3;
    x.covariance!(double, "online", "precise")(y).shouldApprox == 1.0e208 / 3;

    auto z = uint.max.repeat(3);
    z.covariance!float(z).shouldApprox == 0.0;
    static assert(is(typeof(z.covariance!float(z)) == float));
}

/++
For integral slices, pass output type as template parameter to ensure output
type is correct.
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0, 1, 1, 2, 4, 4,
              2, 7, 5, 1, 2, 0].sliced;
    auto y = [6, 3, 7, 1, 1, 1,
              9, 5, 3, 1, 3, 7].sliced;

    x.covariance(y).shouldApprox == -18.583333 / 11;
    static assert(is(typeof(x.covariance(y)) == double));

    x.covariance!float(y).shouldApprox == -18.583333 / 11;
    static assert(is(typeof(x.covariance!float(y)) == float));
}

// make sure works with dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.test: shouldApprox;

    double[] x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                    2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    double[] y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                   9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    x.covariance(y).shouldApprox == -5.5 / 11;
}

/// Works with @nogc
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.ndslice.allocation: mininitRcslice;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;

    x.covariance(y, true).shouldApprox == -5.5 / 12;
    x.covariance(y).shouldApprox == -5.5 / 11;
}

// compile with dub test --build=unittest-perf --config=unittest-perf --compiler=ldc2
version(mir_stat_test_cov_performance)
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
    alias E = EnumMembers!CovarianceAlgo;
    alias fs = staticMap!(covariance, S, E);
    double[fs.length] output;

    auto e = [E];
    auto time = benchmarkRandom2!(fs)(n, m, output);
    writeln("Covariance performance test");
    foreach (size_t i; 0 .. fs.length) {
        writeln("Function ", i + 1, ", Algo: ", e[i], ", Output: ", output[i], ", Elapsed time: ", time[i]);
    }
    writeln();
}

/++
Correlation algorithms.

See Also:
    $(LREF CovarianceAlgo)
    $(WEB en.wikipedia.org/wiki/Algorithms_for_calculating_variance, Algorithms for calculating variance).
+/
enum CorrelationAlgo
{
    /++
    Performs Welford's online algorithm for updating correlation. While it only
    iterates each input once, it can be slower for smaller inputs. However, it
    is also more accurate. Can also `put` another CorrelationAccumulator of the
    same type, which uses the parallel algorithm from Chan et al.
    +/
    online,

    /++
    Calculates correlation using (E(x*y) - E(x)*E(y))/(sqrt(E(x^2)-E(x)^2)*sqrt(E(y^2)-E(y)^2)) (alowing for adjustments for
    population/sample variance). This algorithm can be numerically unstable.
    +/
    naive,

    /++
    Calculates correlation using a two-pass algorithm whereby the inputs are first
    centered and then the sum of products is calculated from that. May be faster
    than `online` and generally more accurate than the `naive` algorithm.
    +/
    twoPass,

    /++
    Calculates correlation assuming the mean of the inputs is zero.
    +/
    assumeZeroMean,

    /++
    Calculates correlation assuming the mean of the inputs is zero and standard
    deviation is one.
    +/
    assumeStandardized,

    /++
    When slices, slice-like objects, or ranges are the inputs, uses the two-pass
    algorithm. When an individual data-point is added, uses the online algorithm.
    +/
    hybrid
}

///
struct CorrelationAccumulator(T, CorrelationAlgo correlationAlgo, Summation summation)
    if (isMutable!T && correlationAlgo == CorrelationAlgo.naive)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import mir.primitives: isInputRange, front, empty, popFront;

    ///
    private size_t _count;
    ///
    alias S = Summator!(T, summation);
    ///
    S summatorLeft;
    ///
    S summatorRight;
    ///
    S summatorOfProducts;
    ///
    S summatorOfSquaresLeft;
    ///
    S summatorOfSquaresRight;

    ///
    this(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX &&
            isInputRange!RangeY)
    {
        import core.lifetime: move;
        this.put(x.move, y.move);
    }

    ///
    void put(IteratorX, IteratorY, SliceKind kindX, SliceKind kindY)(
        Slice!(IteratorX, 1, kindX) x,
        Slice!(IteratorY, 1, kindY) y
    )
    in
    {
        assert(x.length == y.length,
               "CorrelationAcumulator.put: both vectors must have the same length");
    }
    do
    {
        import mir.ndslice.topology: zip, map;

        _count += x.length;
        summatorLeft.put(x);
        summatorRight.put(y);
        summatorOfProducts.put(x.zip(y).map!"a * b");
        summatorOfSquaresLeft.put(x * x);
        summatorOfSquaresRight.put(y * y);
    }

    ///
    void put(SliceLikeX, SliceLikeY)(SliceLikeX x, SliceLikeY y)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeY && !isSlice!SliceLikeY)
    {
        import mir.ndslice.slice: toSlice;
        this.put(x.toSlice, y.toSlice);
    }

    ///
    void put(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && !isConvertibleToSlice!RangeX && is(elementType!RangeX : T) &&
            isInputRange!RangeY && !isConvertibleToSlice!RangeY && is(elementType!RangeY : T))
    {
        do
        {
            assert(!(!x.empty && y.empty) && !(x.empty && !y.empty),
                   "x and y must both be empty at the same time, one cannot be empty while the other has remaining items");
            this.put(x.front, y.front);
            x.popFront;
            y.popFront;
        } while(!x.empty || !y.empty); // Using an || instead of && so that the loop does not end early. mis-matched lengths of x and y sould be caught by above assert
    }

    ///
    void put()(T x, T y)
    {
        _count++;
        summatorLeft.put(x);
        summatorRight.put(y);
        summatorOfProducts.put(x * y);
        summatorOfSquaresLeft.put(x * x);
        summatorOfSquaresRight.put(y * y);
    }

    ///
    void put(U, Summation sumAlgo)(CorrelationAccumulator!(U, correlationAlgo, sumAlgo) v)
    {
        _count += v.count;
        summatorLeft.put(v.sumLeft!U);
        summatorRight.put(v.sumRight!U);
        summatorOfProducts.put(v.sumOfProducts!U);
        summatorOfSquaresLeft.put(v.sumOfSquaresLeft!U);
        summatorOfSquaresRight.put(v.sumOfSquaresRight!U);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F sumLeft(F = T)() @property
    {
        return cast(F) summatorLeft.sum;
    }
    ///
    F sumRight(F = T)() @property
    {
        return cast(F) summatorRight.sum;
    }
    ///
    F meanLeft(F = T)() @property
    {
        return sumLeft!F / count;
    }
    ///
    F meanRight(F = T)() @property
    {
        return sumRight!F / count;
    }
    ///
    F sumOfProducts(F = T)() @property
    {
        return cast(F) summatorOfProducts.sum;
    }
    ///
    F sumOfSquaresLeft(F = T)() @property
    {
        return cast(F) summatorOfSquaresLeft.sum;
    }
    ///
    F sumOfSquaresRight(F = T)() @property
    {
        return cast(F) summatorOfSquaresRight.sum;
    }
    ///
    F centeredSumOfProducts(F = T)() @property
    {
        return sumOfProducts!F - sumLeft!F * sumRight!F / count;
    }
    ///
    F centeredSumOfSquaresLeft(F = T)() @property
    {
        return sumOfSquaresLeft!F - count * meanLeft!F * meanLeft!F;
    }
    ///
    F centeredSumOfSquaresRight(F = T)() @property
    {
        return sumOfSquaresRight!F - count * meanRight!F * meanRight!F;
    }
    ///
    F covariance(F = T)(bool isPopulation) @property
    {
        return sumOfProducts!F / (count + isPopulation - 1) -
            (sumLeft!F * sumRight!F) * (F(1) / (count * (count + isPopulation - 1)));
    }
    ///
    F correlation(F = T)() @property
        in (centeredSumOfSquaresLeft > 0, "`x` must have centered sum of squares larger than zero")
        in (centeredSumOfSquaresRight > 0, "`y` must have centered sum of squares larger than zero")
    {
        import mir.math.common: sqrt;
        return (count * sumOfProducts!F - sumLeft!F * sumRight!F) /
            (sqrt(count * sumOfSquaresLeft!F - sumLeft!F * sumLeft!F) *
             sqrt(count * sumOfSquaresRight!F - sumRight!F * sumRight!F));
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CorrelationAccumulator!(double, CorrelationAlgo.naive, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == 82.25 / 12 - (29.25 * 36) / (12 * 12);
    v.covariance(false).shouldApprox == 82.25 / 11 - (29.25 * 36) / (12 * 12) * (12.0 / 11);

    v.correlation.shouldApprox == -0.0623684;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == 94.25 / 13 - (33.25 * 39) / (13 * 13);
    v.covariance(false).shouldApprox == 94.25 / 12 - (33.25 * 39) / (13 * 13) * (13.0 / 12);

    v.correlation.shouldApprox == -0.0611234;
}

// Check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25];

    CorrelationAccumulator!(double, CorrelationAlgo.naive, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == 82.25 / 12 - (29.25 * 36) / (12 * 12);
    v.covariance(false).shouldApprox == 82.25 / 11 - (29.25 * 36) / (12 * 12) * (12.0 / 11);

    v.meanLeft.shouldApprox == 2.4375;
    v.meanRight.shouldApprox == 3;

    v.correlation.shouldApprox == -0.0623684;

    v.put(4.0, 3.0);

    v.covariance(true).shouldApprox == 94.25 / 13 - (33.25 * 39) / (13 * 13);
    v.covariance(false).shouldApprox == 94.25 / 12 - (33.25 * 39) / (13 * 13) * (13.0 / 12);

    v.correlation.shouldApprox == -0.0611234;
}

// rcslice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.allocation: mininitRcslice;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;
    auto v = CorrelationAccumulator!(double, CorrelationAlgo.naive, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;
    v.correlation.shouldApprox == -0.0623684;
}

// Check adding CorrelationAccumultors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CorrelationAccumulator!(double, CorrelationAlgo.naive, Summation.naive) v1;
    v1.put(x1, y1);
    CorrelationAccumulator!(double, CorrelationAlgo.naive, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;
    v1.correlation.shouldApprox == -0.0623684;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should, shouldApprox;
    import std.range: iota;

    auto x = iota(0, 5);
    auto y = iota(-3, 2);
    CorrelationAccumulator!(double, CorrelationAlgo.naive, Summation.naive) v;
    v.put(x, y);
    v.covariance(true).should == 10.0 / 5;
    v.correlation.shouldApprox == 1;
}

///
struct CorrelationAccumulator(T, CorrelationAlgo correlationAlgo, Summation summation)
    if (isFloatingPoint!T && isMutable!T && correlationAlgo == CorrelationAlgo.online)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import mir.primitives: isInputRange, front, empty, popFront;

    ///
    private size_t _count;
    ///
    alias S = Summator!(T, summation);
    ///
    S summatorLeft;
    ///
    S summatorRight;
    ///
    S centeredSummatorOfProducts;
    ///
    S centeredSummatorOfSquaresLeft;
    ///
    S centeredSummatorOfSquaresRight;

    ///
    this(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        import core.lifetime: move;
        this.put(x.move, y.move);
    }

    ///
    this()(T x, T y)
    {
        this.put(x, y);
    }

    ///
    void put(IteratorX, IteratorY, SliceKind kindX, SliceKind kindY)(
        Slice!(IteratorX, 1, kindX) x,
        Slice!(IteratorY, 1, kindY) y
    )
    in
    {
        assert(x.length == y.length,
               "CorrelationAcumulator.put: both vectors must have the same length");
    }
    do
    {
        import mir.ndslice.topology: zip;

        foreach(e; x.zip(y)) {
            this.put(e[0], e[1]);
        }
    }

    ///
    void put(SliceLikeX, SliceLikeY)(SliceLikeX x, SliceLikeY y)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeY && !isSlice!SliceLikeY)
    {
        import mir.ndslice.slice: toSlice;
        this.put(x.toSlice, y.toSlice);
    }

    ///
    void put(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && !isConvertibleToSlice!RangeX &&
            isInputRange!RangeY && !isConvertibleToSlice!RangeY)
    {
        import std.range: zip;
        foreach(a, b; zip(x, y)) {
            this.put(a, b);
        }
    }

    ///
    void put()(T x, T y)
    {
        T deltaX = x;
        T deltaY = y;
        if (count > 0) {
            deltaX -= meanLeft;
            deltaY -= meanRight;
        }
        _count++;
        summatorLeft.put(x);
        summatorRight.put(y);
        centeredSummatorOfProducts.put(deltaX * (y - meanRight));
        centeredSummatorOfSquaresLeft.put(deltaX * (x - meanLeft));
        centeredSummatorOfSquaresRight.put(deltaY * (y - meanRight));
    }

    ///
    void put(U, CorrelationAlgo covAlgo, Summation sumAlgo)(CorrelationAccumulator!(U, covAlgo, sumAlgo) v)
        if (!is(covAlgo == CorrelationAlgo.assumeZeroMean))
    {
        size_t oldCount = count;
        T deltaLeft = v.meanLeft;
        T deltaRight = v.meanRight;
        if (count > 0) {
            deltaLeft -= meanLeft!T;
            deltaRight -= meanRight!T;
        }
        _count += v.count;
        summatorLeft.put(v.sumLeft!T);
        summatorRight.put(v.sumRight!T);
        centeredSummatorOfProducts.put(v.centeredSumOfProducts!T + deltaLeft * deltaRight * v.count * oldCount / count);
        centeredSummatorOfSquaresLeft.put(v.centeredSumOfSquaresLeft!T + deltaLeft * deltaLeft * v.count * oldCount / count);
        centeredSummatorOfSquaresRight.put(v.centeredSumOfSquaresRight!T + deltaRight * deltaRight * v.count * oldCount / count);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F sumLeft(F = T)() @property
    {
        return cast(F) summatorLeft.sum;
    }
    ///
    F sumRight(F = T)() @property
    {
        return cast(F) summatorRight.sum;
    }
    ///
    F meanLeft(F = T)() @property
    {
        return sumLeft!F / count;
    }
    ///
    F meanRight(F = T)() @property
    {
        return sumRight!T / count;
    }
    ///
    F centeredSumOfProducts(F = T)() @property
    {
        return cast(F) centeredSummatorOfProducts.sum;
    }
    ///
    F centeredSumOfSquaresLeft(F = T)() @property
    {
        return cast(F) centeredSummatorOfSquaresLeft.sum;
    }
        ///
    F centeredSumOfSquaresRight(F = T)() @property
    {
        return cast(F) centeredSummatorOfSquaresRight.sum;
    }
    ///
    F covariance(F = T)(bool isPopulation) @property
    {
        return centeredSumOfProducts!F / (count + isPopulation - 1);
    }
    ///
    F correlation(F = T)() @property
        in (centeredSumOfSquaresLeft > 0, "`x` must have centered sum of squares larger than zero")
        in (centeredSumOfSquaresRight > 0, "`y` must have centered sum of squares larger than zero")
    {
        import mir.math.common: sqrt;
        return centeredSumOfProducts!F / (sqrt(centeredSumOfSquaresLeft!F) * sqrt(centeredSumOfSquaresRight!F));
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CorrelationAccumulator!(double, CorrelationAlgo.online, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.correlation.shouldApprox == -0.0623684;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == -5.5 / 13;
    v.covariance(false).shouldApprox == -5.5 / 12;

    v.correlation.shouldApprox == -0.0611234;
}

// Check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25];

    CorrelationAccumulator!(double, CorrelationAlgo.online, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.meanLeft.shouldApprox == 2.4375;
    v.meanRight.shouldApprox == 3;

    v.correlation.shouldApprox == -0.0623684;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == -5.5 / 13;
    v.covariance(false).shouldApprox == -5.5 / 12;

    v.correlation.shouldApprox == -0.0611234;
}

// rcslice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.allocation: mininitRcslice;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;
    auto v = CorrelationAccumulator!(double, CorrelationAlgo.online, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.correlation.shouldApprox == -0.0623684;
}

// Check adding CorrelationAccumultors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CorrelationAccumulator!(double, CorrelationAlgo.online, Summation.naive) v1;
    v1.put(x1, y1);
    CorrelationAccumulator!(double, CorrelationAlgo.online, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;

    v1.correlation.shouldApprox == -0.0623684;
}

// Check adding CorrelationAccumultors (naive)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CorrelationAccumulator!(double, CorrelationAlgo.online, Summation.naive) v1;
    v1.put(x1, y1);
    CorrelationAccumulator!(double, CorrelationAlgo.naive, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;

    v1.correlation.shouldApprox == -0.0623684;
}

// Check adding CorrelationAccumultors (twoPass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CorrelationAccumulator!(double, CorrelationAlgo.online, Summation.naive) v1;
    v1.put(x1, y1);
    auto v2 = CorrelationAccumulator!(double, CorrelationAlgo.twoPass, Summation.naive)(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;

    v1.correlation.shouldApprox == -0.0623684;
}

// Check adding CorrelationAccumultors (assumeZeroMean)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;
    import mir.test: shouldApprox;

    auto a1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto b1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto a2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto b2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;
    auto x1 = a1.center;
    auto y1 = b1.center;
    auto x2 = a2.center;
    auto y2 = b2.center;

    CorrelationAccumulator!(double, CorrelationAlgo.online, Summation.naive) v1;
    v1.put(x1, y1);
    auto v2 = CorrelationAccumulator!(double, CorrelationAlgo.assumeZeroMean, Summation.naive)(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -1.9375 / 12; //note: different from above due to inconsistent centering
    v1.covariance(false).shouldApprox == -1.9375 / 11; //note: different from above due to inconsistent centering

    v1.correlation.shouldApprox == -0.0229089; //note: different from above due to inconsistent centering
}

// Initializing with one point
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;

    auto v = CorrelationAccumulator!(double, CorrelationAlgo.online, Summation.naive)(4.0, 3.0);
    v.covariance(true).should == 0;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should, shouldApprox;
    import std.range: chunks, iota;

    auto x = iota(0, 5);
    auto y = iota(-3, 2);
    CorrelationAccumulator!(double, CorrelationAlgo.online, Summation.naive) v;
    v.put(x, y);
    v.covariance(true).should == 10 / 5;
    v.correlation.shouldApprox == 1;

    CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive) v2;
    v2.put(x.chunks(1), y.chunks(1));
    v2.covariance(true).should == 10 / 5;
    v2.correlation.shouldApprox == 1;
}

///
struct CorrelationAccumulator(T, CorrelationAlgo correlationAlgo, Summation summation)
    if (isMutable!T && correlationAlgo == CorrelationAlgo.twoPass)
{
    import mir.functional: naryFun;
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import mir.primitives: isInputRange, front, empty, popFront;
    import mir.stat.descriptive.univariate: MeanAccumulator;

    ///
    private size_t _count;
    ///
    alias S = Summator!(T, summation);
    ///
    private S summatorLeft;
    ///
    private S summatorRight;
    ///
    private S centeredSummatorOfProducts;
    ///
    private S centeredSummatorOfSquaresLeft;
    ///
    private S centeredSummatorOfSquaresRight;

    ///
    this(IteratorX, IteratorY, SliceKind kindX, SliceKind kindY)(
         Slice!(IteratorX, 1, kindX) x, Slice!(IteratorY, 1, kindY) y)
     in
     {
        assert(x.length == y.length,
               "CorrelationAcumulator.put: both vectors must have the same length");
     }
     do
    {
        import mir.ndslice.internal: LeftOp;
        import mir.ndslice.topology: map, vmap, zip;

        _count = x.length;
        summatorLeft.put(x.lightScope);
        summatorRight.put(y.lightScope);
        auto z = x.vmap(LeftOp!("-", T)(meanLeft)).zip(y.vmap(LeftOp!("-", T)(meanRight))).map!("a * b", "a * a", "b * b");
        z.putter3(centeredSummatorOfProducts,
                  centeredSummatorOfSquaresLeft,
                  centeredSummatorOfSquaresRight);
    }

    ///
    this(SliceLikeX, SliceLikeY)(SliceLikeX x, SliceLikeY y)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeY && !isSlice!SliceLikeY)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice, y.toSlice);
    }

    ///
    this(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && !isConvertibleToSlice!RangeX && is(elementType!RangeX : T) &&
            isInputRange!RangeY && !isConvertibleToSlice!RangeY && is(elementType!RangeY : T))
    {
        import mir.primitives: elementCount, hasShape;

        static if (hasShape!RangeX && hasShape!RangeY) {
            assert(x.elementCount == y.elementCount);
            _count += x.elementCount;
            summatorLeft.put(x);
            summatorRight.put(y);
        } else {
            import std.range: zip;

            foreach(a, b; zip(x, y)) {
                _count++;
                summatorLeft.put(a);
                summatorRight.put(b);
            }
        }

        T xMean = meanLeft;
        T yMean = meanRight;
        T xDeMean;
        T yDeMean;
        do
        {
            assert(!(!x.empty && y.empty) && !(x.empty && !y.empty),
                   "x and y must both be empty at the same time, one cannot be empty while the other has remaining items");
            xDeMean = x.front - xMean;
            yDeMean = y.front - yMean;
            centeredSummatorOfProducts.put(xDeMean * yDeMean);
            centeredSummatorOfSquaresLeft.put(xDeMean * xDeMean);
            centeredSummatorOfSquaresRight.put(yDeMean * yDeMean);
            x.popFront;
            y.popFront;
        } while(!x.empty || !y.empty); // Using an || instead of && so that the loop does not end early. mis-matched lengths of x and y sould be caught by above assert
    }

    ///
    this()(T x, T y)
    {
        _count++;
        summatorLeft.put(x);
        summatorRight.put(y);
        centeredSummatorOfProducts.put(0);
        centeredSummatorOfSquaresLeft.put(0);
        centeredSummatorOfSquaresRight.put(0);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F sumLeft(F = T)() @property
    {
        return cast(F) summatorLeft.sum;
    }
    ///
    F sumRight(F = T)() @property
    {
        return cast(F) summatorRight.sum;
    }
    ///
    F meanLeft(F = T)() @property
    {
        return sumLeft!F / count;
    }
    ///
    F meanRight(F = T)() @property
    {
        return sumRight!F / count;
    }
    ///
    F centeredSumOfProducts(F = T)() @property
    {
        return cast(F) centeredSummatorOfProducts.sum;
    }
    ///
    F centeredSumOfSquaresLeft(F = T)() @property
    {
        return cast(F) centeredSummatorOfSquaresLeft.sum;
    }
    ///
    F centeredSumOfSquaresRight(F = T)() @property
    {
        return cast(F) centeredSummatorOfSquaresRight.sum;
    }
    ///
    F covariance(F = T)(bool isPopulation) @property
    {
        return centeredSumOfProducts!F / (count + isPopulation - 1);
    }
    ///
    F correlation(F = T)() @property
        in (centeredSumOfSquaresLeft > 0, "`x` must have centered sum of squares larger than zero")
        in (centeredSumOfSquaresRight > 0, "`y` must have centered sum of squares larger than zero")
    {
        import mir.math.common: sqrt;
        return centeredSumOfProducts!F / (sqrt(centeredSumOfSquaresLeft!F) * sqrt(centeredSumOfSquaresRight!F));
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    auto v = CorrelationAccumulator!(double, CorrelationAlgo.twoPass, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.correlation.shouldApprox == -0.0623684;
}

// Check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25];

    auto v = CorrelationAccumulator!(double, CorrelationAlgo.twoPass, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.meanLeft.shouldApprox == 2.4375;
    v.meanRight.shouldApprox ==3;

    v.correlation.shouldApprox == -0.0623684;
}

// rcslice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.allocation: mininitRcslice;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;
    auto v = CorrelationAccumulator!(double, CorrelationAlgo.twoPass, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.correlation.shouldApprox == -0.0623684;
}

// Check Vmap
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;
    auto x = a + 1;
    auto y = b - 1;

    auto v = CorrelationAccumulator!(double, CorrelationAlgo.twoPass, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.correlation.shouldApprox == -0.0623684;
}

// Initializing with one point
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;

    auto v = CorrelationAccumulator!(double, CorrelationAlgo.twoPass, Summation.naive)(4.0, 3.0);
    v.centeredSumOfProducts.should == 0;
    v.count.should == 1;
}

// withAsSlice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.rc.array: RCArray;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];

    auto x = RCArray!double(12);
    foreach(i, ref e; x)
        e = a[i];
    auto y = RCArray!double(12);
    foreach(i, ref e; y)
        e = b[i];

    auto v = CorrelationAccumulator!(double, CorrelationAlgo.twoPass, Summation.naive)(x, y);
    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;
    v.correlation.shouldApprox == -0.0623684;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should, shouldApprox;
    import std.range: iota;
    import std.algorithm: map;

    auto x1 = iota(0, 5);
    auto y1 = iota(-3, 2);
    auto v1 = CorrelationAccumulator!(double, CorrelationAlgo.twoPass, Summation.naive)(x1, y1);
    v1.covariance(true).should == 10.0 / 5;
    v1.correlation.shouldApprox == 1;

    // this version can't use elementCount
    auto x2 = x1.map!(a => 2 * a);
    auto y2 = y1.map!(a => 2 * a);
    auto v2 = CorrelationAccumulator!(double, CorrelationAlgo.twoPass, Summation.naive)(x2, y2);
    v2.covariance(true).should == 40.0 / 5;
    v2.correlation.shouldApprox == 1;
}

///
struct CorrelationAccumulator(T, CorrelationAlgo correlationAlgo, Summation summation)
    if (isMutable!T && correlationAlgo == CorrelationAlgo.assumeZeroMean)
{
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: Slice, SliceKind, hasAsSlice, isConvertibleToSlice, isSlice;
    import mir.primitives: isInputRange, front, empty, popFront;

    ///
    private size_t _count;
    ///
    alias S = Summator!(T, summation);
    ///
    S centeredSummatorOfProducts;
    ///
    S centeredSummatorOfSquaresLeft;
    ///
    S centeredSummatorOfSquaresRight;

    ///
    this(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        this.put(x, y);
    }

    ///
    this()(T x, T y)
    {
        this.put(x, y);
    }

    ///
    void put(IteratorX, IteratorY, SliceKind kindX, SliceKind kindY)(
        Slice!(IteratorX, 1, kindX) x,
        Slice!(IteratorY, 1, kindY) y
    )
    in
    {
        assert(x.length == y.length,
               "CorrelationAcumulator.put: both vectors must have the same length");
    }
    do
    {
        import mir.ndslice.topology: zip, map;

        _count += x.length;
        auto z = x.zip(y).map!("a * b", "a * a", "b * b");
        z.putter3(centeredSummatorOfProducts,
                  centeredSummatorOfSquaresLeft,
                  centeredSummatorOfSquaresRight);
    }

    ///
    void put(SliceLikeX, SliceLikeY)(SliceLikeX x, SliceLikeY y)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeY && !isSlice!SliceLikeY)
    {
        import mir.ndslice.slice: toSlice;
        this.put(x.toSlice, y.toSlice);
    }

    ///
    void put(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && !isConvertibleToSlice!RangeX && is(elementType!RangeX : T) &&
            isInputRange!RangeY && !isConvertibleToSlice!RangeY && is(elementType!RangeY : T))
    {
        do
        {
            assert(!(!x.empty && y.empty) && !(x.empty && !y.empty),
                   "x and y must both be empty at the same time, one cannot be empty while the other has remaining items");
            this.put(x.front, y.front);
            x.popFront;
            y.popFront;
        } while(!x.empty || !y.empty); // Using an || instead of && so that the loop does not end early. mis-matched lengths of x and y sould be caught by above assert
    }

    ///
    void put()(T x, T y)
    {
        _count++;
        centeredSummatorOfProducts.put(x * y);
        centeredSummatorOfSquaresLeft.put(x * x);
        centeredSummatorOfSquaresRight.put(y * y);
    }

    ///
    void put(U, Summation sumAlgo)(CorrelationAccumulator!(U, correlationAlgo, sumAlgo) v)
    {
        _count += v.count;
        centeredSummatorOfProducts.put(v.centeredSumOfProducts!T);
        centeredSummatorOfSquaresLeft.put(v.centeredSumOfSquaresLeft!T);
        centeredSummatorOfSquaresRight.put(v.centeredSumOfSquaresRight!T);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F sumLeft(F = T)() @property
    {
        return 0;
    }
    ///
    F sumRight(F = T)() @property
    {
        return 0;
    }
    ///
    F meanLeft(F = T)() @property
    {
        return 0;
    }
    ///
    F meanRight(F = T)() @property
    {
        return 0;
    }
    ///
    F centeredSumOfProducts(F = T)() @property
    {
        return cast(F) centeredSummatorOfProducts.sum;
    }
    ///
    F centeredSumOfSquaresLeft(F = T)() @property
    {
        return cast(F) centeredSummatorOfSquaresLeft.sum;
    }
    ///
    F centeredSumOfSquaresRight(F = T)() @property
    {
        return cast(F) centeredSummatorOfSquaresRight.sum;
    }
    ///
    F covariance(F = T)(bool isPopulation) @property
    {
        return centeredSumOfProducts!F / (count + isPopulation - 1);
    }
    ///
    F correlation(F = T)() @property
        in (centeredSumOfSquaresLeft > 0, "`x` must have centered sum of squares larger than zero")
        in (centeredSumOfSquaresRight > 0, "`y` must have centered sum of squares larger than zero")
    {
        import mir.math.common: sqrt;
        return centeredSumOfProducts!F / (sqrt(centeredSumOfSquaresLeft!F) * sqrt(centeredSumOfSquaresRight!F));
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.stat.transform: center;
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;
    auto x = a.center;
    auto y = b.center;

    CorrelationAccumulator!(double, CorrelationAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.correlation.shouldApprox == -0.0623684;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == 6.5 / 13;
    v.covariance(false).shouldApprox == 6.5 / 12;

    v.correlation.shouldApprox == 0.0628802;
}

// Check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.stat.descriptive.univariate: mean;
    import mir.stat.transform: center;
    import mir.test: should, shouldApprox;

    auto a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    auto b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto aMean = a.mean;
    auto bMean = b.mean;
    auto x = a.dup;
    auto y = b.dup;
    for (size_t i; i < a.length; i++) {
        x[i] -= aMean;
        y[i] -= bMean;
    }

    CorrelationAccumulator!(double, CorrelationAlgo.assumeZeroMean, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.correlation.shouldApprox == -0.0623684;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == 6.5 / 13;
    v.covariance(false).shouldApprox == 6.5 / 12;

    v.correlation.shouldApprox == 0.0628802;

    v.meanLeft.should == 0;
    v.meanRight.should == 0;
}

// rcslice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.allocation: mininitRcslice;
    import mir.stat.transform: center;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;
    auto v = CorrelationAccumulator!(double, CorrelationAlgo.assumeZeroMean, Summation.naive)(x.center, y.center);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;
    v.correlation.shouldApprox == -0.0623684;
}

// Check adding CorrelationAccumultors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto a1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto b1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto a2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto b2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;
    auto meanA = (a1.sum + a2.sum) / 12;
    auto meanB = (b1.sum + b2.sum) / 12;
    auto x1 = a1 - meanA;
    auto y1 = b1 - meanB;
    auto x2 = a2 - meanA;
    auto y2 = b2 - meanB;

    CorrelationAccumulator!(double, CorrelationAlgo.assumeZeroMean, Summation.naive) v1;
    v1.put(x1, y1);
    CorrelationAccumulator!(double, CorrelationAlgo.assumeZeroMean, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;
    v1.correlation.shouldApprox == -0.0623684;
}

// Initializing with one point
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;

    auto v = CorrelationAccumulator!(double, CorrelationAlgo.assumeZeroMean, Summation.naive)(4.0, 3.0);
    v.centeredSumOfProducts.should == 12;
    v.count.should == 1;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;
    import std.range: iota;

    auto x = iota(0, 5);
    auto y = iota(-3, 2);
    auto v = CorrelationAccumulator!(double, CorrelationAlgo.assumeZeroMean, Summation.naive)(x, y);
    v.centeredSumOfProducts.should == 0; // different from other algorithms because these don't have mean of zero
}

///
struct CorrelationAccumulator(T, CorrelationAlgo correlationAlgo, Summation summation)
    if (isFloatingPoint!T && isMutable!T && correlationAlgo == CorrelationAlgo.hybrid)
{
    import mir.functional: naryFun;
    import mir.math.sum: elementType, Summator;
    import mir.ndslice.slice: isConvertibleToSlice, isSlice, Slice, SliceKind;
    import mir.primitives: isInputRange, front, empty, popFront;

    ///
    private size_t _count;
    ///
    alias S = Summator!(T, summation);
    ///
    S summatorLeft;
    ///
    S summatorRight;
    ///
    S centeredSummatorOfProducts;
    ///
    S centeredSummatorOfSquaresLeft;
    ///
    S centeredSummatorOfSquaresRight;

    ///
    this()(T x, T y)
    {
        this.put(x, y);
    }

    ///
    this(IteratorX, IteratorY, SliceKind kindX, SliceKind kindY)(
        Slice!(IteratorX, 1, kindX) x,
        Slice!(IteratorY, 1, kindY) y
    )
    in
    {
        assert(x.length == y.length,
               "CorrelationAcumulator.put: both vectors must have the same length");
    }
    do
    {
        import mir.ndslice.internal: LeftOp;
        import mir.ndslice.topology: map, vmap, zip;

        _count += x.length;
        summatorLeft.put(x.lightScope);
        summatorRight.put(y.lightScope);
        auto z = x.vmap(LeftOp!("-", T)(meanLeft)).zip(y.vmap(LeftOp!("-", T)(meanRight))).map!("a * b", "a * a", "b * b");
        z.putter3(centeredSummatorOfProducts,
                  centeredSummatorOfSquaresLeft,
                  centeredSummatorOfSquaresRight);
    }

    ///
    this(SliceLikeX, SliceLikeY)(SliceLikeX x, SliceLikeY y)
        if (isConvertibleToSlice!SliceLikeX && !isSlice!SliceLikeX &&
            isConvertibleToSlice!SliceLikeY && !isSlice!SliceLikeY)
    {
        import mir.ndslice.slice: toSlice;
        this(x.toSlice, y.toSlice);
    }

    ///
   this(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && !isConvertibleToSlice!RangeX &&
            isInputRange!RangeY && !isConvertibleToSlice!RangeY)
    {
        static if (is(elementType!RangeX : T) && is(elementType!RangeY : T)) {
            import mir.primitives: elementCount, hasShape;

            static if (hasShape!RangeX && hasShape!RangeY) {
                assert(x.elementCount == y.elementCount);
                _count += x.elementCount;
                summatorLeft.put(x);
                summatorRight.put(y);
            } else {
                import std.range: zip;

                foreach(a, b; zip(x, y)) {
                    _count++;
                    summatorLeft.put(a);
                    summatorRight.put(b);
                }
            }

            T xMean = meanLeft;
            T yMean = meanRight;
            T xDeMean;
            T yDeMean;
            do
            {
                assert(!(!x.empty && y.empty) && !(x.empty && !y.empty),
                       "x and y must both be empty at the same time, one cannot be empty while the other has remaining items");
                xDeMean = x.front - xMean;
                yDeMean = y.front - yMean;
                centeredSummatorOfProducts.put(xDeMean * yDeMean);
                centeredSummatorOfSquaresLeft.put(xDeMean * xDeMean);
                centeredSummatorOfSquaresRight.put(yDeMean * yDeMean);
                x.popFront;
                y.popFront;
            } while(!x.empty || !y.empty); // Using an || instead of && so that the loop does not end early. mis-matched lengths of x and y sould be caught by above assert
        } else {
            this.put(x, y);
        }
    }

    ///
    void put(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        static if (is(elementType!RangeX : T) && is(elementType!RangeY : T)) {
            auto v = typeof(this)(x, y);
            this.put(v);
        } else {
            import std.range: zip;
            foreach(a, b; zip(x, y)) {
                this.put(a, b);
            }
        }
    }

    ///
    void put()(T x, T y)
    {
        T deltaX = x;
        T deltaY = y;
        if (count > 0) {
            deltaX -= meanLeft;
            deltaY -= meanRight;
        }
        _count++;
        summatorLeft.put(x);
        summatorRight.put(y);
        centeredSummatorOfProducts.put(deltaX * (y - meanRight));
        centeredSummatorOfSquaresLeft.put(deltaX * (x - meanLeft));
        centeredSummatorOfSquaresRight.put(deltaY * (y - meanRight));
    }

    ///
    void put(U, CorrelationAlgo covAlgo, Summation sumAlgo)(CorrelationAccumulator!(U, covAlgo, sumAlgo) v)
    {
        size_t oldCount = count;
        T deltaLeft = v.meanLeft;
        T deltaRight = v.meanRight;
        if (count > 0) {
            deltaLeft -= meanLeft!T;
            deltaRight -= meanRight!T;
        }
        _count += v.count;
        summatorLeft.put(v.sumLeft!T);
        summatorRight.put(v.sumRight!T);
        centeredSummatorOfProducts.put(v.centeredSumOfProducts!T + deltaLeft * deltaRight * v.count * oldCount / count);
        centeredSummatorOfSquaresLeft.put(v.centeredSumOfSquaresLeft!T + deltaLeft * deltaLeft * v.count * oldCount / count);
        centeredSummatorOfSquaresRight.put(v.centeredSumOfSquaresRight!T + deltaRight * deltaRight * v.count * oldCount / count);
    }

const:

    ///
    size_t count() @property
    {
        return _count;
    }
    ///
    F sumLeft(F = T)() @property
    {
        return cast(F) summatorLeft.sum;
    }
    ///
    F sumRight(F = T)() @property
    {
        return cast(F) summatorRight.sum;
    }
    ///
    F meanLeft(F = T)() @property
    {
        return sumLeft!F / count;
    }
    ///
    F meanRight(F = T)() @property
    {
        return sumRight!F / count;
    }
    ///
    F centeredSumOfProducts(F = T)() @property
    {
        return cast(F) centeredSummatorOfProducts.sum;
    }
    ///
    F centeredSumOfSquaresLeft(F = T)() @property
    {
        return cast(F) centeredSummatorOfSquaresLeft.sum;
    }
    ///
    F centeredSumOfSquaresRight(F = T)() @property
    {
        return cast(F) centeredSummatorOfSquaresRight.sum;
    }
    ///
    F covariance(F = T)(bool isPopulation) @property
    {
        return centeredSumOfProducts!F / (count + isPopulation - 1);
    }
    ///
    F correlation(F = T)() @property
        in (centeredSumOfSquaresLeft > 0, "`x` must have centered sum of squares larger than zero")
        in (centeredSumOfSquaresRight > 0, "`y` must have centered sum of squares larger than zero")
    {
        import mir.math.common: sqrt;
        return centeredSumOfProducts!F / (sqrt(centeredSumOfSquaresLeft!F) * sqrt(centeredSumOfSquaresRight!F));
    }
}

///
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.correlation.shouldApprox == -0.0623684;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == -5.5 / 13;
    v.covariance(false).shouldApprox == -5.5 / 12;

    v.correlation.shouldApprox == -0.0611234;
}

// Check dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25];

    CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive) v;
    v.put(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.meanLeft.shouldApprox == 2.4375;
    v.meanRight.shouldApprox == 3;

    v.correlation.shouldApprox == -0.0623684;

    v.put(4.0, 3.0);
    v.covariance(true).shouldApprox == -5.5 / 13;
    v.covariance(false).shouldApprox == -5.5 / 12;

    v.correlation.shouldApprox == -0.0611234;
}

// rcslice test
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.math.sum: Summation;
    import mir.ndslice.allocation: mininitRcslice;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;
    auto v = CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive)(x, y);

    v.covariance(true).shouldApprox == -5.5 / 12;
    v.covariance(false).shouldApprox == -5.5 / 11;

    v.correlation.shouldApprox == -0.0623684;
}

// Check adding CorrelationAccumultors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive) v1;
    v1.put(x1, y1);
    CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;

    v1.correlation.shouldApprox == -0.0623684;
}

// Check adding CorrelationAccumultors (naive)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive) v1;
    v1.put(x1, y1);
    CorrelationAccumulator!(double, CorrelationAlgo.naive, Summation.naive) v2;
    v2.put(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;

    v1.correlation.shouldApprox == -0.0623684;
}

// Check adding CorrelationAccumultors (twoPass)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto y1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto x2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive) v1;
    v1.put(x1, y1);
    auto v2 = CorrelationAccumulator!(double, CorrelationAlgo.twoPass, Summation.naive)(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -5.5 / 12;
    v1.covariance(false).shouldApprox == -5.5 / 11;

    v1.correlation.shouldApprox == -0.0623684;
}

// Check adding CorrelationAccumultors (assumeZeroMean)
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: sum, Summation;
    import mir.ndslice.slice: sliced;
    import mir.stat.transform: center;
    import mir.test: shouldApprox;

    auto a1 = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25].sliced;
    auto b1 = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5].sliced;
    auto a2 = [  2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto b2 = [ 9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;
    auto x1 = a1.center;
    auto y1 = b1.center;
    auto x2 = a2.center;
    auto y2 = b2.center;

    CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive) v1;
    v1.put(x1, y1);
    auto v2 = CorrelationAccumulator!(double, CorrelationAlgo.assumeZeroMean, Summation.naive)(x2, y2);
    v1.put(v2);

    v1.covariance(true).shouldApprox == -1.9375 / 12; //note: different from above due to inconsistent centering
    v1.covariance(false).shouldApprox == -1.9375 / 11; //note: different from above due to inconsistent centering

    v1.correlation.shouldApprox == -0.0229089; //note: different from above due to inconsistent centering
}

// Initializing with one point
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should;

    auto v = CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive)(4.0, 3.0);
    v.covariance(true).should == 0;
}

// Test input range
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.sum: Summation;
    import mir.test: should, shouldApprox;
    import std.algorithm: map;
    import std.range: chunks, iota;

    auto x1 = iota(0, 5);
    auto y1 = iota(-3, 2);
    CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive) v1;
    v1.put(x1, y1);
    v1.covariance(true).should == 10.0 / 5;
    v1.correlation.shouldApprox == 1;
    // this version can't use elementCount
    CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive) v2;
    auto x2 = x1.map!(a => 2 * a);
    auto y2 = y1.map!(a => 2 * a);
    v2.put(x2, y2);
    v2.covariance(true).should == 40.0 / 5;
    v2.correlation.shouldApprox == 1;
    CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive) v3;
    v3.put(x1.chunks(1), y1.chunks(1));
    v3.covariance(true).should == 10.0 / 5;
    v3.correlation.shouldApprox == 1;
    auto v4 = CorrelationAccumulator!(double, CorrelationAlgo.hybrid, Summation.naive)(x1.chunks(1), y1.chunks(1));
    v4.covariance(true).should == 10.0 / 5;
    v4.correlation.shouldApprox == 1;
}

/++
Calculates the correlation of the inputs.

If `x` and `y` are both slices or convertible to slices, then they must be
one-dimensional.

Params:
    F = controls type of output
    correlationAlgo = algorithm for calculating correlation (default: CorrelationAlgo.hybrid)
    summation = algorithm for calculating sums (default: Summation.appropriate)
Returns:
    The correlation of the inputs
+/
template correlation(F,
                     CorrelationAlgo correlationAlgo = CorrelationAlgo.hybrid,
                     Summation summation = Summation.appropriate)
    if (isFloatingPoint!F)
{
    import mir.math.common: fmamath;
    import mir.primitives: isInputRange;
    import mir.math.sum: ResolveSummationType;
    /++
    Params:
        x = range, must be finite iterable
        y = range, must be finite iterable
    +/
    @fmamath F correlation(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        import core.lifetime: move;

        auto correlationAccumulator = CorrelationAccumulator!(F, correlationAlgo, ResolveSummationType!(summation, RangeX, F))(x.move, y.move);
        return correlationAccumulator.correlation();
    }
}

/// ditto
template correlation(
    CorrelationAlgo correlationAlgo = CorrelationAlgo.hybrid,
    Summation summation = Summation.appropriate)
{
    import mir.math.common: fmamath;
    import mir.primitives: isInputRange;
    import mir.stat.descriptive.univariate: stdevType;
    import std.traits: CommonType;
    /++
    Params:
        x = range, must be finite iterable
        y = range, must be finite iterable
    +/
    @fmamath CommonType!(stdevType!RangeX, stdevType!RangeY) correlation(RangeX, RangeY)(RangeX x, RangeY y)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .correlation!(F, correlationAlgo, summation)(x.move, y.move);
    }
}

/// ditto
template correlation(F, string correlationAlgo, string summation = "appropriate")
{
    mixin("alias correlation = .correlation!(F, CorrelationAlgo." ~ correlationAlgo ~ ", Summation." ~ summation ~ ");");
}

/// ditto
template correlation(string correlationAlgo, string summation = "appropriate")
{
    mixin("alias correlation = .correlation!(CorrelationAlgo." ~ correlationAlgo ~ ", Summation." ~ summation ~ ");");
}

/// Correlation of vectors
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                2.0,   7.5,   5.0,  1.0,  1.5,  0.0].sliced;
    auto y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    x.correlation(y).shouldApprox == -0.0623684;
}

/// Can also set algorithm type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.math.common: approxEqual;
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto a = [0.0, 1.0, 1.5, 2.0, 3.5, 4.25,
              2.0, 7.5, 5.0, 1.0, 1.5, 0.0].sliced;
    auto b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
               9.25, -0.75,   2.5, 1.25,   -1, 2.25].sliced;

    auto x = a + 10.0 ^^ 9;
    auto y = b + 10.0 ^^ 9;

    x.correlation(y).shouldApprox == -0.0623684;

    // The naive algorithm is numerically unstable in this case
    //assert(!x.correlation!"naive"(y).approxEqual(-0.0623684));

    // The two-pass algorithm provides the same answer as hybrid
    x.correlation!"twoPass"(y).shouldApprox == -0.0623684;

    // And the assumeZeroMean algorithm is way off
    assert(!x.correlation!"assumeZeroMean"(y).approxEqual(-0.0623684));
}

/// Can also set algorithm or output type
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: repeat;
    import mir.test: shouldApprox;

    //Set population covariance, covariance algorithm, sum algorithm or output type

    auto a = [1.0, 1e100, 1, -1e100].sliced;
    auto b = [1.0e100, 1, 1, -1e100].sliced;
    auto x = a * 10_000;
    auto y = b * 10_000;

    /++
    Due to Floating Point precision, when centering `x`, subtracting the mean
    from the second and fourth numbers has no effect (for `y` the same is true
    for the first and fourth). Further, after centering and multiplying `x` and
    `y`, the third numbers in the slice has precision too low to be included in
    the centered sum of the products. For the calculations below, the "true"
    correlation should be a tiny amount above 0.5, but it is as if the
    calculation happens between [0, 1, 0, -1] and [1, 0, 0, -1].
    +/
    x.correlation(y).shouldApprox == 0.5;

    x.correlation!("online")(y).shouldApprox == 0.5;
    x.correlation!("online", "kbn")(y).shouldApprox == 0.5;
    x.correlation!("online", "kb2")(y).shouldApprox == 0.5;
    x.correlation!("online", "precise")(y).shouldApprox == 0.5;
    x.correlation!(double, "online", "precise")(y).shouldApprox == 0.5;

    auto z1 = [uint.max - 2, uint.max - 1, uint.max].sliced;
    auto z2 = [uint.max - 3, uint.max - 2, uint.max - 1].sliced;
    z1.correlation(z2).shouldApprox == 1.0;
    static assert(is(typeof(z1.correlation!float(z2)) == float));
}

/++
For integral slices, pass output type as template parameter to ensure output
type is correct.
+/
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.ndslice.slice: sliced;
    import mir.test: shouldApprox;

    auto x = [0, 1, 1, 2, 4, 4,
              2, 7, 5, 1, 2, 0].sliced;
    auto y = [6, 3, 7, 1, 1, 1,
              9, 5, 3, 1, 3, 7].sliced;

    x.correlation(y).shouldApprox == -0.27934577;
    static assert(is(typeof(x.correlation(y)) == double));

    x.correlation!float(y).shouldApprox == -0.27934577;
    static assert(is(typeof(x.correlation!float(y)) == float));
}

// make sure works with dynamic array
version(mir_stat_test)
@safe pure nothrow
unittest
{
    import mir.test: shouldApprox;

    double[] x = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                    2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    double[] y = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                   9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    x.correlation(y).shouldApprox == -0.0623684;
}

/// Works with @nogc
version(mir_stat_test)
@safe pure nothrow @nogc
unittest
{
    import mir.ndslice.allocation: mininitRcslice;
    import mir.test: shouldApprox;

    static immutable a = [  0.0,   1.0,   1.5,  2.0,  3.5, 4.25,
                            2.0,   7.5,   5.0,  1.0,  1.5,  0.0];
    static immutable b = [-0.75,   6.0, -0.25, 8.25, 5.75,  3.5,
                           9.25, -0.75,   2.5, 1.25,   -1, 2.25];
    auto x = mininitRcslice!double(12);
    auto y = mininitRcslice!double(12);
    x[] = a;
    y[] = b;

    x.correlation(y).shouldApprox == -0.0623684;
}

// compile with dub test --build=unittest-perf --config=unittest-perf --compiler=ldc2
version(mir_stat_test_cor_performance)
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
    alias E = EnumMembers!CorrelationAlgo;
    alias fs = staticMap!(correlation, S, E);
    double[fs.length] output;

    auto e = [E];
    auto time = benchmarkRandom2!(fs)(n, m, output);
    writeln("Correlation performance test");
    foreach (size_t i; 0 .. fs.length) {
        writeln("Function ", i + 1, ", Algo: ", e[i], ", Output: ", output[i], ", Elapsed time: ", time[i]);
    }
    writeln();
}
