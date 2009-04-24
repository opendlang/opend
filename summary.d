/**Summary statistics such as mean, median, sum, variance, skewness, kurtosis.
 * Except for median, which cannot be calculated online, all summary statistics
 * have both an input range interface and an output range interface.
 *
 * Bugs:  This whole module assumes that input will be reals or types implicitly
 *        convertible to real.  No allowances are made for user-defined numeric
 *        types such as BigInts.  This is necessary for simplicity.  However,
 *        if you have a function that converts your data to reals, most of
 *        these functions work with any input range, so you can simply map
 *        this function onto your range.
 *
 * Author:  David Simcha*/
 /*
 * You may use this software under your choice of either of the following
 * licenses.  YOU NEED ONLY OBEY THE TERMS OF EXACTLY ONE OF THE TWO LICENSES.
 * IF YOU CHOOSE TO USE THE PHOBOS LICENSE, YOU DO NOT NEED TO OBEY THE TERMS OF
 * THE BSD LICENSE.  IF YOU CHOOSE TO USE THE BSD LICENSE, YOU DO NOT NEED
 * TO OBEY THE TERMS OF THE PHOBOS LICENSE.  IF YOU ARE A LAWYER LOOKING FOR
 * LOOPHOLES AND RIDICULOUSLY NON-EXISTENT AMBIGUITIES IN THE PREVIOUS STATEMENT,
 * GET A LIFE.
 *
 * ---------------------Phobos License: ---------------------------------------
 *
 *  Copyright (C) 2008-2009 by David Simcha.
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 *
 * --------------------BSD License:  -----------------------------------------
 *
 * Copyright (c) 2008-2009, David Simcha
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 *     * Neither the name of the authors nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED ''AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


module dstats.summary;

import std.algorithm, std.functional, std.conv, std.string, std.range,
       std.array;

import dstats.sort, dstats.base, dstats.alloc;

version(unittest) {
    import std.stdio, std.random, std.algorithm, std.conv;

    void main() {
    }
}

/**Finds median of an input range in O(N) time on average.  In the case of an
 * even number of elements, the mean of the two middle elements is returned.
 * This is a convenience founction designed specifically for numeric types,
 * where the averaging of the two middle elements is desired.  A more general
 * selection algorithm that can handle any type with a total ordering, as well
 * as selecting any position in the ordering, can be found at
 * dstats.sort.quickSelect() and dstats.sort.partitionK().
 * Allocates memory, does not reorder input data.*/
real median(T)(T data)
if(realInput!(T)) {
    // Allocate once on TempAlloc if possible, i.e. if we know the length.
    // This can be done on TempAlloc.  Otherwise, have to use GC heap
    // and appending.
    auto dataDup = tempdup(data);
    scope(exit) TempAlloc.free;
    return medianPartition(dataDup);
}

/**Median finding as in median(), but will partition input data such that
 * elements less than the median will have smaller indices than that of the
 * median, and elements larger than the median will have larger indices than
 * that of the median. Useful both for its partititioning and to avoid
 * memory allocations.  Requires a random access range with swappable
 * elements.*/
real medianPartition(T)(T data)
if(isRandomAccessRange!(T) &&
   is(ElementType!(T) : real) &&
   hasSwappableElements!(T) &&
   dstats.base.hasLength!(T))
in {
    assert(data.length > 0);
} body {
    // Upper half of median in even length case is just the smallest element
    // with an index larger than the lower median, after the array is
    // partially sorted.
    if(data.length == 1) {
        return data[0];
    } else if(data.length & 1) {  //Is odd.
        return cast(real) partitionK(data, data.length / 2);
    } else {
        auto lower = partitionK(data, data.length / 2 - 1);
        auto upper = ElementType!(T).max;

        // Avoid requiring slicing to be supported.
        foreach(i; data.length / 2..data.length) {
            if(data[i] < upper) {
                upper = data[i];
            }
        }
        return lower * 0.5L + upper * 0.5L;
    }
}

unittest {
    float brainDeadMedian(float[] foo) {
        qsort(foo);
        if(foo.length & 1)
            return foo[$ / 2];
        return (foo[$ / 2] + foo[$ / 2 - 1]) / 2;
    }

    float[] test = new float[1000];
    uint upperBound, lowerBound;
    foreach(testNum; 0..1000) {
        foreach(ref e; test) {
            e = uniform(0f, 1000f);
        }
        do {
            upperBound = uniform(0u, test.length);
            lowerBound = uniform(0u, test.length);
        } while(lowerBound == upperBound);
        if(lowerBound > upperBound) {
            swap(lowerBound, upperBound);
        }
        auto quickRes = median(test[lowerBound..upperBound]);
        auto accurateRes = brainDeadMedian(test[lowerBound..upperBound]);

        // Off by some tiny fraction in even N case because of division.
        // No idea why, but it's too small a rounding error to care about.
        assert(approxEqual(quickRes, accurateRes));
    }

    // Make sure everything works with lowest common denominator range type.
    struct Count {
        uint num;
        uint upTo;
        uint front() {
            return num;
        }
        void popFront() {
            num++;
        }
        bool empty() {
            return num >= upTo;
        }
    }

    Count a;
    a.upTo = 100;
    assert(approxEqual(median(a), 49.5));
    writeln("Passed median unittest.");
}

/**Finds the arithmetic mean of any input range whose elements are implicitly
 * convertible to real.*/
real mean(T)(T data)
if(realInput!(T)) {
    OnlineMean meanCalc;
    foreach(element; data) {
        meanCalc.put(element);
    }
    return meanCalc.mean;
}

/**Output range to calculate the mean online.  Getter for mean costs a branch to
 * check for N == 0.  This struct uses O(1) space and does *NOT* store the
 * individual elements.
 *
 * Examples:
 * ---
 * OnlineMean summ;
 * summ.put(1);
 * summ.put(2);
 * summ.put(3);
 * summ.put(4);
 * summ.put(5);
 * assert(summ.mean == 3);
 * ---*/
struct OnlineMean {
private:
    real result = 0;
    real k = 0;
public:
    /// Allow implicit casting to real, by returning the current mean.
    alias mean this;

    ///
    void put(real element) {
        result += (element - result) / ++k;
    }

    ///
    real mean() const {
        return (k == 0) ? real.nan : result;
    }

    ///
    real N() const {
        return k;
    }

    ///
    string toString() {
        return to!(string)(mean);
    }
}

///
struct OnlineGeometricMean {
private:
    OnlineMean m;
public:
    ///Allow implicit casting to real, by returning current geometric mean.
    alias geoMean this;

    ///
    void put(real element) {
        m.put(log2(element));
    }

    ///
    real geoMean() const {
        return exp2(m.mean);
    }

    ///
    real N() const {
        return m.k;
    }

    ///
    string toString() {
        return to!(string)(geoMean);
    }
}

///
real geometricMean(T)(T data)
if(realInput!(T)) {
    OnlineGeometricMean m;
    foreach(elem; data) {
        m.put(elem);
    }
    return m.geoMean;
}

unittest {
    string[] data = ["1", "2", "3", "4", "5"];
    auto result = geometricMean(map!(to!(uint, string))(data));
    assert(approxEqual(result, 2.60517));
    writeln("Passed geometricMean unittest.");
}


/**Finds the sum of an input range whose elements implicitly convert to real.
 * User has option of making U a different type than T to prevent overflows
 * on large array summing operations.  However, by default, return type is
 * T (same as input type).*/
U sum(T, U = Unqual!(ElementType!(T)))(T data)
if(realInput!(T)) {
    U sum = 0;
    foreach(value; data) {
        sum += value;
    }
    return sum;
}

unittest {
    assert(sum(cast(int[]) [1,2,3,4,5])==15);
    assert(approxEqual( sum(cast(int[]) [40.0, 40.1, 5.2]), 85.3));
    assert(mean(cast(int[]) [1,2,3]) == 2);
    assert(mean(cast(int[]) [1.0, 2.0, 3.0]) == 2.0);
    assert(mean(cast(int[]) [1, 2, 5, 10, 17]) == 7);
    writefln("Passed sum/mean unittest.");
}


/**Outpu range to compute mean, stdev, variance online.  Getter methods
 * for stdev, var cost a few floating point ops.  Getter for mean costs
 * a single branch to check for N == 0.  Relatively expensive floating point
 * ops, if you only need mean, try OnlineMean.  This struct uses O(1) space and
 * does *NOT* store the individual elements.
 *
 * Examples:
 * ---
 * OnlineMeanSD summ;
 * summ.put(1);
 * summ.put(2);
 * summ.put(3);
 * summ.put(4);
 * summ.put(5);
 * assert(summ.mean == 3);
 * assert(summ.stdev == sqrt(2.5));
 * assert(summ.var == 2.5);
 * ---*/
struct OnlineMeanSD {
private:
    real _mean = 0;
    real _var = 0;
    real _k = 0;
public:
    ///
    void put(real element) {
        real kNeg1 = 1.0L / ++_k;
        _var += (element * element - _var) * kNeg1;
        _mean += (element - _mean) * kNeg1;
    }

    ///
    real mean() const {
        return (_k == 0) ? real.nan : _mean;
    }

    ///
    real stdev() const {
        return sqrt(var);
    }

    ///
    real var() const {
        return (_k < 2) ? real.nan : (_var - _mean * _mean) * (_k / (_k - 1));
    }

    ///
    real N() const {
        return _k;
    }

    ///
    string toString() {
        return format("N = ", cast(ulong) _k, "\nMean = ", mean, "\nVariance = ",
               var, "\nStdev = ", stdev);
}
}

/**Simple holder for mean, stdev/variance.  Plain old data, accessing is
 * cheap.*/
struct MeanSD {
    ///
    real mean;
    ///
    real SD;

    string toString() {
        return format("Mean = ", mean, "\nStdev = ", SD);
    }
}

/**Finds the variance of an input range with members implicitly convertible
 * to reals.*/
real variance(T)(T data)
if(realInput!(T)) {
    return meanVariance(data).SD;
}

/**Calculates both mean and variance of an input range, returns a MeanSD
 * struct.*/
MeanSD meanVariance(T)(T data)
if(realInput!(T)) {
    OnlineMeanSD meanSDCalc;
    foreach(element; data) {
        meanSDCalc.put(element);
    }

    return MeanSD(meanSDCalc.mean, meanSDCalc.var);
}

/**Calculates both mean and standard deviation of an input range, returns a
 * MeanSD struct.*/
MeanSD meanStdev(T)(T data)
if(realInput!(T)) {
    auto ret = meanVariance(data);
    ret.SD = sqrt(ret.SD);
    return ret;
}

/**Calculate the standard deviation of an input range with members
 * implicitly converitble to real.*/
real stdev(T)(T data)
if(realInput!(T)) {
    return meanStdev(data).SD;
}

unittest {
    auto res = meanStdev(cast(int[]) [3, 1, 4, 5]);
    assert(approxEqual(res.SD, 1.7078));
    assert(approxEqual(res.mean, 3.25));
    res = meanStdev(cast(double[]) [1.0, 2.0, 3.0, 4.0, 5.0]);
    assert(approxEqual(res.SD, 1.5811));
    assert(approxEqual(res.mean, 3));
    writefln("Passed variance/standard deviation unittest.");
}

/**Output range to compute mean, stdev, variance, skewness, kurtosis, min, and
 * max online. Using this struct is relatively expensive, so if you just need
 * mean and/or stdev, try OnlineMeanSD or OnlineMean. Getter methods for stdev,
 * var cost a few floating point ops.  Getter for mean costs a single branch to
 * check for N == 0.  Getters for skewness and kurtosis cost a whole bunch of
 * floating point ops.  This struct uses O(1) space and does *NOT* store the
 * individual elements.
 *
 * Examples:
 * ---
 * OnlineSummary summ;
 * summ.put(1);
 * summ.put(2);
 * summ.put(3);
 * summ.put(4);
 * summ.put(5);
 * assert(summ.N == 5);
 * assert(summ.mean == 3);
 * assert(summ.stdev == sqrt(2.5));
 * assert(summ.var == 2.5);
 * assert(approxEqual(summ.kurtosis, -1.9120));
 * assert(summ.min == 1);
 * assert(summ.max == 5);
 * ---*/
struct OnlineSummary {
private:
    real _mean = 0;
    real _m2 = 0;
    real _m3 = 0;
    real _m4 = 0;
    real _k = 0;
    real _min = real.infinity;
    real _max = -real.infinity;
public:
    ///
    void put(real element) {
        immutable real kNeg1 = 1.0L / ++_k;
        _min = (element < _min) ? element : _min;
        _max = (element > _max) ? element : _max;
        _mean += (element - _mean) * kNeg1;
        _m2 += (element * element - _m2) * kNeg1;
        _m3 += (element * element * element - _m3) * kNeg1;
        _m4 += (element * element * element * element - _m4) * kNeg1;
    }

    ///
    real mean() const {
        return (_k == 0) ? real.nan : _mean;
    }

    ///
    real stdev() const {
        return sqrt(var);
    }

    ///
    real var() const {
        return (_k == 0) ? real.nan : (_m2 - _mean * _mean) * (_k / (_k - 1));
    }

    ///
    real skewness() const {
        real var = var();
        real numerator = _m3 - 3 * _mean * _m2 + 2 * _mean * _mean * _mean;
        return numerator / pow(var, 1.5L);
    }

    ///
    real kurtosis() const {
        real mean4 = mean * mean;
        mean4 *= mean4;
        real vari = var();
        return (_m4 - 4 * _mean * _m3 + 6 * _mean * _mean * _m2 - 3 * mean4) /
               (vari * vari) - 3;
    }

    ///
    real N() const {
        return _k;
    }

    ///
    real min() const {
        return _min;
    }

    ///
    real max() const {
        return _max;
    }

    ///
    string toString() {
        return format("N = ", cast(ulong) _k, "\nMean = ", mean, "\nVariance = ",
               var, "\nStdev = ", stdev, "\nSkewness = ", skewness,
               "\nKurtosis = ", kurtosis, "\nMin = ", _min, "\nMax = ", _max);
    }
}

/**Excess kurtosis relative to normal distribution.  High kurtosis means that
 * the variance is due to infrequent, large deviations from the mean.  Low
 * kurtosis means that the variance is due to frequent, small deviations from
 * the mean.  The normal distribution is defined as having kurtosis of 0.
 * Input must be an input range with elements implicitly convertible to real.*/
real kurtosis(T)(T data)
if(realInput!(T)) {
    OnlineSummary kCalc;
    foreach(elem; data) {
        kCalc.put(elem);
    }
    return kCalc.kurtosis;
}

unittest {
    // Values from Octave.
    assert(approxEqual(kurtosis([1, 1, 1, 1, 10].dup), -.92));
    assert(approxEqual(kurtosis([2.5, 3.5, 4.5, 5.5].dup), -2.0775));
    assert(approxEqual(kurtosis([1,2,2,2,2,2,100].dup), 0.79523));
    writefln("Passed kurtosis unittest.");
}

/**Skewness is a measure of symmetry of a distribution.  Positive skewness
 * means that the right tail is longer/fatter than the left tail.  Negative
 * skewness means the left tail is longer/fatter than the right tail.  Zero
 * skewness indicates a symmetrical distribution.  Input must be an input
 * range with elements implicitly convertible to real.*/
real skewness(T)(T data)
if(realInput!(T)) {
    OnlineSummary sCalc;
    foreach(elem; data) {
        sCalc.put(elem);
    }
    return sCalc.skewness;
}

unittest {
    // Values from Octave.
    assert(approxEqual(skewness([1,2,3,4,5].dup), 0));
    assert(approxEqual(skewness([3,1,4,1,5,9,2,6,5].dup), 0.45618));
    assert(approxEqual(skewness([2,7,1,8,2,8,1,8,2,8,4,5,9].dup), -0.076783));

    // Test handling of ranges that are not arrays.
    string[] stringy = ["3", "1", "4", "1", "5", "9", "2", "6", "5"];
    auto intified = map!(to!(int, string))(stringy);
    assert(approxEqual(skewness(intified), 0.45618));
    writeln("Passed skewness test.");
}

/**Plain old data struct for holding results of summary().  Accessing members
 * is cheap.*/
struct Summary {
    ///
    ulong N;

    ///
    real mean;

    ///
    real var;

    ///
    real SD;

    ///
    real skew;

    ///
    real kurtosis;

    ///
    real min;

    ///
    real max;

    ///
    string toString() {
        return format("N = ", N, "\nMean = ", mean, "\nVariance = ",
               var, "\nStdev = ", SD, "\nSkewness = ", skew,
               "\nKurtosis = ", kurtosis, "\nMin = ", min, "\nMax = ", max);
    }
}

/**Calculates all summary stats (mean, variance, standard dev., skewness
 * and kurtosis) on an input range with elements that can be implicitly
 * converted to real.  Returns the results in a Summary struct.*/
Summary summary(T)(T data)
if(realInput!(T)) {
    OnlineSummary summ;
    foreach(elem; data) {
        summ.put(elem);
    }
    return Summary(data.length, summ.mean, summ.var, summ.stdev, summ.skewness,
                   summ.kurtosis, summ.min, summ.max);
}
// Just a convenience function for a well-tested struct.  No unittest really
// necessary.  (Famous last words.)


// Verify that there are no TempAlloc memory leaks anywhere in the code covered
// by the unittest.  This should always be the last unittest of the module.
unittest {
    auto TAState = TempAlloc.getState;
    assert(TAState.used == 0);
    assert(TAState.nblocks < 2);
}
