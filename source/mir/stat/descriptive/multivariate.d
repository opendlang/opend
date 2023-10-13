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
        if (!is(covAlgo == CovarianceAlgo.assumeZeroMean))
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

    CovarianceAccumulator!(double, CovarianceAlgo.online, Summation.naive) v1;
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
template cov(F,
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
    @fmamath F cov(RangeX, RangeY)(RangeX x, RangeY y, bool isPopulation = false)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        import core.lifetime: move;

        auto covarianceAccumulator = CovarianceAccumulator!(F, covarianceAlgo, ResolveSummationType!(summation, RangeX, F))(x.move, y.move);
        return covarianceAccumulator.covariance(isPopulation);
    }
}

/// ditto
template cov(
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
    @fmamath CommonType!(meanType!RangeX, meanType!RangeY) cov(RangeX, RangeY)(RangeX x, RangeY y, bool isPopulation = false)
        if (isInputRange!RangeX && isInputRange!RangeY)
    {
        import core.lifetime: move;

        alias F = typeof(return);
        return .cov!(F, covarianceAlgo, summation)(x.move, y.move, isPopulation);
    }
}

/// ditto
template cov(F, string covarianceAlgo, string summation = "appropriate")
{
    mixin("alias cov = .cov!(F, CovarianceAlgo." ~ covarianceAlgo ~ ", Summation." ~ summation ~ ");");
}

/// ditto
template cov(string covarianceAlgo, string summation = "appropriate")
{
    mixin("alias cov = .cov!(CovarianceAlgo." ~ covarianceAlgo ~ ", Summation." ~ summation ~ ");");
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

    x.cov(y, true).shouldApprox == -5.5 / 12;
    x.cov(y).shouldApprox == -5.5 / 11;
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

    x.cov(y).shouldApprox == -5.5 / 11;

    // The naive algorithm is numerically unstable in this case
    assert(!x.cov!"naive"(y).approxEqual(-5.5 / 11));

    // The two-pass algorithm provides the same answer as hybrid
    x.cov!"twoPass"(y).shouldApprox == -5.5 / 11;

    // And the assumeZeroMean algorithm is way off
    assert(!x.cov!"assumeZeroMean"(y).approxEqual(-5.5 / 11));
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
    x.cov(y).shouldApprox == 1.0e208 / 3;
    x.cov(y, true).shouldApprox == 1.0e208 / 4;

    x.cov!("online")(y).shouldApprox == 1.0e208 / 3;
    x.cov!("online", "kbn")(y).shouldApprox == 1.0e208 / 3;
    x.cov!("online", "kb2")(y).shouldApprox == 1.0e208 / 3;
    x.cov!("online", "precise")(y).shouldApprox == 1.0e208 / 3;
    x.cov!(double, "online", "precise")(y).shouldApprox == 1.0e208 / 3;

    auto z = uint.max.repeat(3);
    z.cov!float(z).shouldApprox == 0.0;
    static assert(is(typeof(z.cov!float(z)) == float));
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

    x.cov(y).shouldApprox == -18.583333 / 11;
    static assert(is(typeof(x.cov(y)) == double));

    x.cov!float(y).shouldApprox == -18.583333 / 11;
    static assert(is(typeof(x.cov!float(y)) == float));
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
    x.cov(y).shouldApprox == -5.5 / 11;
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

    x.cov(y, true).shouldApprox == -5.5 / 12;
    x.cov(y).shouldApprox == -5.5 / 11;
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
    alias fs = staticMap!(cov, S, E);
    double[fs.length] output;

    auto e = [E];
    auto time = benchmarkRandom2!(fs)(n, m, output);
    writeln("Covariance performance test");
    foreach (size_t i; 0 .. fs.length) {
        writeln("Function ", i + 1, ", Algo: ", e[i], ", Output: ", output[i], ", Elapsed time: ", time[i]);
    }
    writeln();
}
