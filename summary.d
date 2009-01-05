/**Summary dstats such as mean, median, sum, variance, skewness, kurtosis.
 *
 * Bugs:  This whole module assumes that input will be reals or types implicitly
 *        convertible to real.  No allowances are made for user-defined numeric
 *        types such as BigInts.  This is necessary for simplicity.
 *
 * Author:  David Simcha
 *
* Copyright (c) 2009, David Simcha
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*     * Redistributions of source code must retain the above copyright
*       notice, this list of conditions and the following disclaimer.
*     * Redistributions in binary form must reproduce the above copyright
*       notice, this list of conditions and the following disclaimer in the
*       documentation and/or other materials provided with the distribution.
*     * Neither the name of the <organization> nor the
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
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*/


module dstats.summary;

import std.algorithm, std.functional, std.conv, std.string;

import dstats.sort, dstats.base, dstats.alloc;

version(unittest) {
    import std.stdio, std.random;

    Random gen;

    void main() {
    }
}

/**Finds median in O(N) time on average.  In the case of an even number of
 * elements, the mean of the two middle elements is returned.  This is a
 * convenience founction designed specifically for numeric types, where the
 * averaging of the two middle elements is desired.  A more general selection
 * algorithm that can handle any type with a total ordering, as well as
 * selecting any position in the ordering, can be found at
 * dstats.sort.quickSelect() and dstats.sort.partitionK().
 * Allocates memory, does not reorder input data.*/
real median(T)(const T[] data) {
    auto TAState = TempAlloc.getState;
    auto dataDup = data.tempdup(TAState);  scope(exit) TempAlloc.free(TAState);
    return medianPartition(dataDup);
}

/**Median finding as in median(), but will partition input data such that
 * elements less than the median will have smaller indices than that of the
 * median, and elements larger than the median will have larger indices than
 * that of the median. Useful both for its partititioning and to avoid
 * memory allocations.*/
real medianPartition(T)(T[] data)
in {
    assert(data.length > 0);
} body {
    // Upper half of median in even length case is just the smallest element
    // with an index larger than the lower median, after the array is
    // partially sorted.
    static T min(T[] data) {
        T min = data[0];
        foreach(d; data[1..$]) {
            if(d < min)
                min = d;
        }
        return min;
    }

    if(data.length == 1) {
        return data[0];
    } else if(data.length & 1) {  //Is odd.
        return cast(real) partitionK(data, data.length / 2);
    } else {
        auto lower = partitionK(data, data.length / 2 - 1);
        auto upper = min(data[data.length / 2..$]);
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

    gen.seed(unpredictableSeed);
    float[] test = new float[1000];
    uint upperBound, lowerBound;
    foreach(testNum; 0..1000) {
        foreach(ref e; test) {
            e = uniform(gen, 0f, 1000f);
        }
        do {
            upperBound = uniform(gen, 0u, test.length);
            lowerBound = uniform(gen, 0u, test.length);
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
    writeln("Passed median unittest.");
}

///
real mean(T)(const T[] data) {
    OnlineMean meanCalc;
    foreach(element; data) {
        meanCalc.addElement(element);
    }
    return meanCalc.mean;
}

/**Struct to calculate the mean online.  Getter for mean costs a branch to
 * check for N == 0.  This struct uses O(1) space and does *NOT* store the
 * individual elements.
 *
 * Examples:
 * ---
 * OnlineMean summ;
 * summ.addElement(1);
 * summ.addElement(2);
 * summ.addElement(3);
 * summ.addElement(4);
 * summ.addElement(5);
 * assert(summ.mean == 3);
 * ---*/
struct OnlineMean {
private:
    real result = 0;
    real k = 0;
public:
    ///
    void addElement(real element) {
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

    string toString() {
        return to!(string)(mean);
    }
}

///Returns mean of absolute values.
real absMean(T)(const T[] data) {
    OnlineMean meanCalc;
    foreach(element; data) {
        meanCalc.addElement(abs(element));
    }
    return meanCalc.mean;
}

/**User has option of making U a different type than T to prevent overflows
 * on large array summing operations.  However, by default, return type is
 * T (same as input type).*/
U sum(T, U = Mutable!(T))(const T[] data) {
    U sum = 0;
    foreach(value; data) {
        sum += value;
    }
    return sum;
}

/**User has option of making U a different type than T
 * to prevent overflows on large array summing operations.
 * However, by default, return type is T (same as input type).*/
U absSum(T, U = Mutable!(T))(const T[] data) {
    U sum=0;
    foreach(value; data) {
        sum+=abs(value);
    }
    return sum;
}

unittest {
    assert(sum([1,2,3,4,5])==15);
    assert(sum([40.0, 40.1, 5.2])==85.3);
    assert(mean([1,2,3])==2);
    assert(mean([1.0, 2.0, 3.0])==2.0);
    assert(mean([1, 2, 5, 10, 17]) == 7);
    assert(absSum([-1, 2, 3, -4, 5]) == 15);
    assert(absMean([-1, 2, 3, -4, 5]) == 3);
    writefln("Passed sum/mean unittest.");
}


/**Allows computation of mean, stdev, variance online.  Getter methods
 * for stdev, var cost a few floating point ops.  Getter for mean costs
 * a single branch to check for N == 0.  Relatively expensive floating point
 * ops, if you only need mean, try OnlineMean.  This struct uses O(1) space and
 * does *NOT* store the individual elements.
 *
 * Examples:
 * ---
 * OnlineMeanSD summ;
 * summ.addElement(1);
 * summ.addElement(2);
 * summ.addElement(3);
 * summ.addElement(4);
 * summ.addElement(5);
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
    void addElement(real element) {
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

///
real variance(T)(const T[] data) {
    return meanVariance(data).SD;
}

/// Calculates both mean and variance in one pass, returns a MeanSD struct.
MeanSD meanVariance(T)(const T[] data) {
    OnlineMeanSD meanSDCalc;
    foreach(element; data) {
        meanSDCalc.addElement(element);
    }

    return MeanSD(meanSDCalc.mean, meanSDCalc.var);
}

/// Computes mean and standard deviation in one pass, returns both in a struct.
MeanSD meanStdev(T)(const T[] data) {
    auto ret = meanVariance(data);
    ret.SD = sqrt(ret.SD);
    return ret;
}

///
real stdev(T)(const T[] data) {
    return meanStdev(data).SD;
}

unittest {
    auto res = meanStdev([3, 1, 4, 5]);
    assert(approxEqual(res.SD, 1.7078));
    assert(approxEqual(res.mean, 3.25));
    res = meanStdev([1.0, 2.0, 3.0, 4.0, 5.0]);
    assert(approxEqual(res.SD, 1.5811));
    assert(approxEqual(res.mean, 3));
    writefln("Passed variance/standard deviation unittest.");
}

///
real percentVariance(T) (const T[] data) {
    MeanSD stats = meanStdev(data);
    real PV = 100 * abs(stats.SD / stats.mean);
    return abs(PV);
}

/**Allows computation of mean, stdev, variance, skewness, kurtosis, min, and
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
 * summ.addElement(1);
 * summ.addElement(2);
 * summ.addElement(3);
 * summ.addElement(4);
 * summ.addElement(5);
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
    void addElement(real element) {
        invariant real kNeg1 = 1.0L / ++_k;
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

    string toString() {
        return format("N = ", cast(ulong) _k, "\nMean = ", mean, "\nVariance = ",
               var, "\nStdev = ", stdev, "\nSkewness = ", skewness,
               "\nKurtosis = ", kurtosis, "\nMin = ", _min, "\nMax = ", _max);
    }
}

/**Excess kurtosis relative to normal distribution.  High kurtosis means that
 * the variance is due to infrequent, large deviations from the mean.  Low
 * kurtosis means that the variance is due to frequent, small deviations from
 * the mean.  The normal distribution is defined as having kurtosis of 0.*/
real kurtosis(T)(const T[] data) {
    OnlineSummary kCalc;
    foreach(elem; data) {
        kCalc.addElement(elem);
    }
    return kCalc.kurtosis;
}

unittest {
    // Values from Octave.
    assert(approxEqual(kurtosis([1, 1, 1, 1, 10]), -.92));
    assert(approxEqual(kurtosis([2.5, 3.5, 4.5, 5.5]), -2.0775));
    assert(approxEqual(kurtosis([1,2,2,2,2,2,100]), 0.79523));
    writefln("Passed kurtosis unittest.");
}

/**Skewness is a measure of symmetry of a distribution.  Positive skewness
 * means that the right tail is longer/fatter than the left tail.  Negative
 * skewness means the left tail is longer/fatter than the right tail.  Zero
 * skewness indicates a symmetrical distribution.*/
real skewness(T)(const T[] data) {
    OnlineSummary sCalc;
    foreach(elem; data) {
        sCalc.addElement(elem);
    }
    return sCalc.skewness;
}

unittest {
    // Values from Octave.
    assert(approxEqual(skewness([1,2,3,4,5]), 0));
    assert(approxEqual(skewness([3,1,4,1,5,9,2,6,5]), 0.45618));
    assert(approxEqual(skewness([2,7,1,8,2,8,1,8,2,8,4,5,9]), -0.076783));
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

    string toString() {
        return format("N = ", N, "\nMean = ", mean, "\nVariance = ",
               var, "\nStdev = ", SD, "\nSkewness = ", skew,
               "\nKurtosis = ", kurtosis, "\nMin = ", min, "\nMax = ", max);
    }
}

/**Calculates all summary dstats (mean, variance, standard dev., skewness
 * and kurtosis on an array.  Returns the results in a Summary struct.*/
Summary summary(T)(const T[] data) {
    OnlineSummary summ;
    foreach(elem; data) {
        summ.addElement(elem);
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
    assert(TAState.current.used == 0);
    assert(TAState.nblocks < 2);
}
