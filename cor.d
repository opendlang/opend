/**Pearson, Spearman and Kendall correlations, covariance.
 *
 * Author:  David Simcha
 *
 * Copyright (c) 2009, David Simcha
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
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*/

module dstats.cor;

import core.memory;

import dstats.sort, dstats.base, dstats.alloc;

version(unittest) {
    import std.stdio, std.random, std.algorithm;

    Random gen;

    void main() {
        gen.seed(unpredictableSeed);
    }
}

/**Pearson correlation.  When the term correlation is used unqualified, it is
 * usually referring to this quantity.  Pearson correlation assumes the input
 * data is normally distributed and is therefore a parametric test.*/
real pcor(T, U)(const T[] input1, const U[] input2)
in {
    assert(input1.length == input2.length);
} body {
    OnlinePcor corCalc;
    foreach(i; 0..input1.length) {
        corCalc.addElement(input1[i], input2[i]);
    }

    return corCalc.cor;
}

unittest {
    assert(approxEqual(pcor([1,2,3,4,5], [1,2,3,4,5]), 1));
    assert(approxEqual(pcor([1,2,3,4,5], [10.0, 8.0, 6.0, 4.0, 2.0]), -1));
    assert(approxEqual(pcor([2, 4, 1, 6, 19], [4, 5, 1, 3, 2]), -.2382314));
    writefln("Passed pcor unittest.");
}

/**Allows computation of mean, stdev, variance, covariance, Pearson correlation online.
 * Getters for stdev, var, cov, cor cost floating point division ops.  Getters
 * for means cost a single branch to check for N == 0.  This struct uses O(1)
 * space.*/
struct OnlinePcor {
private:
    real _mean1 = 0, _mean2 = 0, _var1 = 0, _var2 = 0, _cov = 0, _k = 0;
public:
    ///
    void addElement(T, U)(T elem1, U elem2) {
        _k++;
        real kNeg1 = 1.0L / _k;
        _cov += (elem1 * elem2 - _cov) * kNeg1;
        _var1 += (elem1 * elem1 - _var1) * kNeg1;
        _var2 += (elem2 * elem2 - _var2) * kNeg1;
        _mean1 += (elem1 - _mean1) * kNeg1;
        _mean2 += (elem2 - _mean2) * kNeg1;
    }

    ///
    real var1() const {
        return (_k < 2) ? real.nan : (_var1 - _mean1 * _mean1) * (_k / (_k - 1));
    }

    ///
    real var2() const {
        return (_k < 2) ? real.nan : (_var2 - _mean2 * _mean2) * (_k / (_k - 1));
    }

    ///
    real stdev1() const {
        return sqrt(var1);
    }

    ///
    real stdev2() const {
        return sqrt(var2);
    }

    ///
    real cor() const {
        return cov / stdev1 / stdev2;
    }

    ///
    real cov() const {
        return (_k < 2) ? real.nan : (_cov - _mean1 * _mean2) * (_k / (_k - 1));
    }

    ///
    real mean1() const {
        return (_k == 0) ? real.nan : _mean1;
    }

    ///
    real mean2() const {
        return (_k == 0) ? real.nan : _mean2;
    }

    ///
    real N() const {
        return _k;
    }
}

///
real covariance(T, U)(const T[] input1, const U[] input2)
in {
    assert(input1.length == input2.length);
} body {
    OnlinePcor covCalc;
    foreach(i; 0..input1.length) {
        covCalc.addElement(input1[i], input2[i]);
    }
    return covCalc.cov;
}

unittest {
    assert(approxEqual(covariance([1,4,2,6,3], [3,1,2,6,2]), 2.05));
    writeln("Passed covariance test.");
}

/**Spearman's rank correlation.  Non-parametric.  This is essentially the
 * Pearson correlation of the ranks of the data, with ties dealt with by
 * averaging.*/
real scor(T, U)(const T[] input1, const U[] input2)
in {
    assert(input1.length == input2.length);
} body {  // Not using rank() so I can recycle some allocations.
    if(input1.length < 2)
        return real.nan;

    mixin(newFrame);
    uint[] perms = newStack!(uint)(input1.length);
    foreach(i, ref p; perms) {
        p = i;
    }

    T[] iDup;
    size_t largerSize = (T.sizeof > U.sizeof) ? T.sizeof : U.sizeof;
    iDup = (cast(T*) TempAlloc.malloc(largerSize * input1.length))
           [0..input1.length];
    iDup[] = input1[];
    qsort(iDup, perms);

    float[] i1Ranks = newStack!(float)(input1.length),
            i2Ranks = newStack!(float)(input1.length);

    foreach(i; 0..perms.length)  {
        i1Ranks[perms[i]] = i + 1;
    }
    averageTies(iDup, i1Ranks, perms);
    foreach(i; 0..iDup.length) {
        perms[i] = i;
    }

    // Recycling allocations is good for the environment.
    // This works because I previously made sure that the array was big enough
    // for the larger of T, U.
    U[] iDup2 = (cast(U*) iDup.ptr)[0..input2.length];
    iDup2[] = input2[];

    qsort(iDup2, perms);
    foreach(i; 0..perms.length)  {
        i2Ranks[perms[i]] = i + 1;
    }
    averageTies(iDup2, i2Ranks, perms);

    return pcor(i1Ranks, i2Ranks);
}

unittest {
    //Test against a few known values.
    assert(approxEqual(scor([1,2,3,4,5,6], [3,1,2,5,4,6]), 0.77143));
    assert(approxEqual(scor([3,1,2,5,4,6], [1,2,3,4,5,6] ), 0.77143));
    assert(approxEqual(scor([3,6,7,35,75], [1,63,53,67,3]), 0.3));
    assert(approxEqual(scor([1,63,53,67,3], [3,6,7,35,75]), 0.3));
    assert(approxEqual(scor([1.5,6.3,7.8,4.2,1.5], [1,63,53,67,3]), .56429));
    assert(approxEqual(scor([1,63,53,67,3], [1.5,6.3,7.8,4.2,1.5]), .56429));
    assert(approxEqual(scor([1.5,6.3,7.8,7.8,1.5], [1,63,53,67,3]), .79057));
    assert(approxEqual(scor([1,63,53,67,3], [1.5,6.3,7.8,7.8,1.5]), .79057));
    assert(approxEqual(scor([1.5,6.3,7.8,6.3,1.5], [1,63,53,67,3]), .63246));
    assert(approxEqual(scor([1,63,53,67,3], [1.5,6.3,7.8,6.3,1.5]), .63246));
    assert(approxEqual(scor([3,4,1,5,2,1,6,4], [1,3,2,6,4,2,6,7]), .6829268));
    assert(approxEqual(scor([1,3,2,6,4,2,6,7], [3,4,1,5,2,1,6,4]), .6829268));
    uint[] one = new uint[1000], two = new uint[1000];
    foreach(i; 0..100) {  //Further sanity checks for things like commutativity.
        size_t lowerBound = uniform(gen, 0, one.length);
        size_t upperBound = uniform(gen, 0, one.length);
        if(lowerBound > upperBound) swap(lowerBound, upperBound);
        foreach(ref o; one) {
            o = uniform(gen, 1, 10);  //Generate lots of ties.
        }
        foreach(ref o; two) {
             o = uniform(gen, 1, 10);  //Generate lots of ties.
        }
        real sOne =
             scor(one[lowerBound..upperBound], two[lowerBound..upperBound]);
        real sTwo =
             scor(two[lowerBound..upperBound], one[lowerBound..upperBound]);
        foreach(ref o; one)
            o*=-1;
        real sThree =
             -scor(one[lowerBound..upperBound], two[lowerBound..upperBound]);
        real sFour =
             -scor(two[lowerBound..upperBound], one[lowerBound..upperBound]);
        foreach(ref o; two) o*=-1;
        one[lowerBound..upperBound].reverse;
        two[lowerBound..upperBound].reverse;
        real sFive =
             scor(one[lowerBound..upperBound], two[lowerBound..upperBound]);
        assert(approxEqual(sOne, sTwo) || (isnan(sOne) && isnan(sTwo)));
        assert(approxEqual(sTwo, sThree) || (isnan(sThree) && isnan(sTwo)));
        assert(approxEqual(sThree, sFour) || (isnan(sThree) && isnan(sFour)));
        assert(approxEqual(sFour, sFive) || (isnan(sFour) && isnan(sFive)));
    }
    writefln("Passed scor unittest.");
}


/*  Kendall's Tau correlation, O(N^2) version.  Kept around
  * for testing, but pretty useless otherwise.  Since new version falls back
  * on insertion sorting when N is small, this is likely not faster
  * even for small N.  Advantage is that it's a very direct translation from
  * standard formulas, and therefore unlikely to have weird, subtle bugs.*/

real kcorOld(T, U)(const T[] input1, const U[] input2)
in {
    assert(input1.length == input2.length);
} body {
    ulong m1=0, m2=0;
    int s=0;
    scope uint[const(T)] f1=frequency(input1);
    scope uint[const(U)] f2=frequency(input2);
    foreach(f; f1) {
        m1+=(f*(f-1))/2;
    }
    foreach(f; f2) {
        m2+=(f*(f-1))/2;
    }
    foreach (i; 0..input2.length) {
        foreach (j; (i+1)..input2.length) {
            if (input2[i] > input2[j]) {
                if (input1[i] > input1[j]) {
                    s++;
                } else if (input1[i] < input1[j]) {
                    s--;
                }
            } else if (input2[i] < input2[j]) {
                if (input1[i] > input1[j]) {
                    s--;
                } else if (input1[i] < input1[j]) {
                    s++;
                }
            }
        }
    }
    ulong denominator1=(input2.length*(input2.length-1))/2 - m1;
    ulong denominator2=(input2.length*(input2.length-1))/2 - m2;
    return s/sqrt(cast(real) (denominator1*denominator2));
}

/**Kendall's Tau, O(N log N) version.  This can be defined in terms of the
 * bubble sort distance, or the number of swaps that would be needed in a
 * bubble sort to sort input2 into the same order as input1.  It is
 * a robust, non-parametric correlation metric.*/
real kcor(T, U)(const T[] input1, const U[] input2) {
    auto i1d = input1.tempdup;
    scope(exit) TempAlloc.free;
    auto i2d = input2.tempdup;
    scope(exit) TempAlloc.free;
    return kcorDestructive(i1d, i2d);
}

/**Kendall's Tau O(N log N) destroys input vectors but requires
 * O(1) auxilliary space provided T.sizeof == U.sizeof.*/
real kcorDestructive(T, U)(T[] input1, U[] input2)
in {
    assert(input1.length == input2.length);
} body {

    static ulong getMs(V)(const V[] data) {  //Assumes data is sorted.
        ulong Ms = 0, tieCount = 0;
        foreach(i; 1..data.length) {
            if(data[i] == data[i-1]) {
                tieCount++;
            } else if(tieCount) {
                Ms += (tieCount*(tieCount+1))/2;
                tieCount = 0;
            }
        }
        if(tieCount) {
            Ms += (tieCount*(tieCount+1)) / 2;
        }
        return Ms;
    }

    ulong m1 = 0, m2 = 0,
          nPair = (cast(ulong) input1.length *
                  ( cast(ulong) input1.length - 1UL)) / 2UL;
    alias input1 i1d;
    alias input2 i2d;
    qsort!("a < b")(i1d, i2d);
    long s = cast(long) nPair;

    ulong tieCount = 0;
    foreach(i; 1UL..i1d.length) {
        if(i1d[i] == i1d[i-1]) {
            tieCount++;
        } else if(tieCount > 0) {
            qsort!("a < b")(i2d[i - tieCount - 1..i]);
            m1 += tieCount * (tieCount + 1) / 2UL;
            s += getMs(i2d[i - tieCount - 1..i]);
            tieCount = 0;
        }
    }
    if(tieCount > 0) {
        qsort!("a < b")(i2d[i1d.length - tieCount - 1..i1d.length]);
        m1 += tieCount * (tieCount + 1UL) / 2UL;
        s += getMs(i2d[i1d.length - tieCount - 1UL..i1d.length]);
    }
    ulong swapCount = 0;

    static if(T.sizeof == U.sizeof) {  // Recycle allocations.
        U[] i1dTemp = (cast(U*) i1d.ptr)[0..input2.length];
        mergeSortTemp!("a < b")(i2d, i1dTemp, &swapCount);
    } else {  // Let the mergeSort function handle the allocation.
        mergeSort!("a < b")(i2d, &swapCount);
    }

    m2 = getMs(i2d);
    s -= (m1 + m2) + 2 * swapCount;
    ulong denominator1 = nPair - m1;
    ulong denominator2 = nPair - m2;
    return s / (sqrt(cast(real) (denominator1)) * sqrt(cast(real) denominator2));
}


unittest {
    //Test against known values.
    assert(approxEqual(kcor([1,2,3,4,5], [3,1,7,4,3]), 0.1054093));
    assert(approxEqual(kcor([3,6,7,35,75],[1,63,53,67,3]), 0.2));
    assert(approxEqual(kcor([1.5,6.3,7.8,4.2,1.5], [1,63,53,67,3]), .3162287));
    uint[] one = new uint[1000], two = new uint[1000];
    // Test complex, fast implementation against straightforward,
    // slow implementation.
    foreach(i; 0..100) {
        size_t lowerBound = uniform(gen, 0, 1000);
        size_t upperBound = uniform(gen, 0, 1000);
        if(lowerBound > upperBound) swap(lowerBound, upperBound);
        foreach(ref o; one) {
            o = uniform(gen, 1, 10);
        }
        foreach(ref o; two) {
             o = uniform(gen, 1, 10);
        }
        real kOne =
             kcor(one[lowerBound..upperBound], two[lowerBound..upperBound]);
        real kTwo =
             kcorOld(one[lowerBound..upperBound], two[lowerBound..upperBound]);
        assert(approxEqual(kOne, kTwo));
    }
    writefln("Passed kcor unittest.");
}

// Verify that there are no TempAlloc memory leaks anywhere in the code covered
// by the unittest.  This should always be the last unittest of the module.
unittest {
    auto TAState = TempAlloc.getState;
    assert(TAState.current.used == 0);
    assert(TAState.nblocks < 2);
}
