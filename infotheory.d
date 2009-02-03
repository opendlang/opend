/**Basic information theory.  Joint entropy, mutual information, conditional
 * mutual information.  This module uses the base 2 definition of these
 * quantities, i.e, entropy, mutual info, etc. are output in bits.
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

module dstats.infotheory;

import std.traits, std.math, std.typetuple, std.functional;

import dstats.sort, dstats.summary, dstats.base, dstats.alloc;

version(unittest) {
    import std.stdio, std.bigint;

    void main() {}
}

/**This function calculates the Shannon entropy of an array that is
 * treated as frequency counts of a set of discrete observations.
 *
 * Examples:
 * ---
 * real uniform3 = entropyCounts([4, 4, 4]);
 * assert(approxEqual(uniform3, log2(3)));
 * real uniform4 = entropyCounts([5, 5, 5, 5]);
 * assert(approxEqual(uniform4, 2));
 * ---
 */
real entropyCounts(T)(const T[] data) {
    return entropyCounts(data, sum!(T, real)(data));
}

real entropyCounts(T)(const T[] data, real n) {
    real nNeg1 = 1.0L / n;
    real entropy = 0;
    foreach(value; data) {
        if(value == 0)
            continue;
        real pxi = cast(real) value * nNeg1;
        entropy -= pxi * log2(pxi);
    }
    return entropy;
}

unittest {
    real uniform3 = entropyCounts([4, 4, 4]);
    assert(approxEqual(uniform3, log2(3)));
    real uniform4 = entropyCounts([5, 5, 5, 5]);
    assert(approxEqual(uniform4, 2));
    assert(entropyCounts([2,2])==1);
    assert(entropyCounts([5.1,5.1,5.1,5.1])==2);
    assert(approxEqual(entropyCounts([1,2,3,4,5]), 2.1492553971685));
    writefln("Passed entropyCounts unittest.");
}

// Should be encapsulated within entropy().  Workaround for bug 1629.
struct ObsEnt(T...) {
    atomsOfArrayTuple!(T) compRep;

    hash_t toHash() {
        hash_t sum = 0;
        foreach(i, elem; this.tupleof) {
            static if(is(elem : long) && elem.sizeof <= hash_t.sizeof) {
                sum += elem << i;
            } else static if(__traits(compiles, elem.toHash)) {
                sum += elem.toHash << i;
            } else {
                auto ti = typeid(typeof(elem));
                sum += ti.getHash(&elem) << i;
            }
        }
        return sum;
    }

    bool opEquals(typeof(this) rhs) {
        foreach(ti, elem; this.tupleof) {
            if(elem != rhs.tupleof[ti])
                return false;
        }
        return true;
    }
}

/**Calculates the joint entropy of a set of observations.  Each array represets
 * a vector of observations. If only one array is given, this reduces to the
 * plain old entropy.
 *
 * Examples:
 * ---
 * int[] foo = [1, 1, 1, 2, 2, 2, 3, 3, 3];
 * real entropyFoo = entropy(foo);  // Plain old entropy of foo.
 * assert(approxEqual(entropyFoo, log2(3)));
 * int[] bar = [1, 2, 3, 1, 2, 3, 1, 2, 3];
 * real jointEntropyFooBar = entropy(foo, bar);  // Joint entropy of foo and bar.
 * assert(approxEqual(jointEntropyFooBar, log2(9)));
 * ---
 */
real entropy(T...)(const T data)
in {
    static assert(data.length > 0);
    size_t zeroLen = data[0].length;
    foreach(array; data[1..$]) {
        assert(array.length == zeroLen);
    }
} body {

    static if(data.length > 1) {
        alias ObsEnt!(T) Obs;
    }

    TempAlloc.frameInit;
    static if(data.length > 1) {
        alias StackHash!(Obs, uint) mySh;
        mySh counts = mySh(data[0].length / 5);
        foreach(i; 0..data[0].length) {
            Obs obs;
            foreach(ti, vec; data) {
                obs.tupleof[ti] = data[ti][i];
            }
            counts[obs]++;
        }
    } else {
        alias StackHash!(typeof(data[0][0]), uint) mySh;
        mySh counts = mySh(data[0].length / 5);
        foreach(elem; data[0]) {
            counts[elem]++;
        }
    }

    real nNeg1 = 1.0L / data[0].length;
    real ans = 0;
    foreach(value; counts) {
        if(value == 0)
            continue;
        real pxi = cast(real) value * nNeg1;
        ans -= pxi * log2(pxi);
    }
    TempAlloc.frameFree;

    return ans;
}

unittest {
    int[] foo = [1, 1, 1, 2, 2, 2, 3, 3, 3];
    real entropyFoo = entropy(foo);
    assert(approxEqual(entropyFoo, log2(3)));
    int[] bar = [1, 2, 3, 1, 2, 3, 1, 2, 3];
    real jointEntropyFooBar = entropy(foo, bar);  // Joint entropy of foo and bar.
    assert(approxEqual(jointEntropyFooBar, log2(9)));
    // Testing with BigInts because they're more challenging to get right
    // in terms of hashing and all.
    BigInt[] bi = new BigInt[5];
    bi[0] = 1;
    bi[1] = 2;
    bi[2] = 3;
    bi[3] = 1;
    bi[4] = 1;
    auto bi2 = bi.dup.reverse;
    assert(approxEqual(entropy(bi, bi2), entropyCounts([2, 1, 1, 1])));
    assert(approxEqual(entropy(bi), entropyCounts([3, 1, 1])));
    writeln("Passed entropy unittest.");
}


/**Calculates the mutual information of two vectors of observations.
 */
real mutualInfo(T, U)(T[] x, U[] y)
in {
    assert(x.length == y.length);
} body {
    return entropy(x) + entropy(y) - entropy(x, y);
}

unittest {
    // Values from R, but converted from base e to base 2.
    assert(approxEqual(mutualInfo(bin([1,2,3,3,8], 10),
           bin([8,6,7,5,3], 10)), 1.921928));
    assert(approxEqual(mutualInfo(bin([1,2,1,1,3,4,3,6], 2),
           bin([2,7,9,6,3,1,7,40], 2)), .2935645));
    assert(approxEqual(mutualInfo(bin([1,2,1,1,3,4,3,6], 4),
           bin([2,7,9,6,3,1,7,40], 4)), .5435671));

    writeln("Passed mutualInfo unittest.");
}

/**Calculates the conditional mutual information I(x, y | z).  z can be any
 * number of vectors.  If only two vectors are provided (equivalently if z is
 * empty), this reduces to plain old mutual information.*/
real condMutualInfo(T, U, V...)(T[] x, U[] y, V z)
in {
    size_t zeroLen = z[0].length;
    foreach(array; z[1..$]) {
        assert(array.length == zeroLen);
    }
} body {
    static if(V.length == 0)
        return mutualInfo(x, y);
    else
        return entropy(x, z) + entropy(y, z) - entropy(x, y, z) - entropy(z);
}

unittest {
    // Values from Matlab mi package by Hanchuan Peng.
    auto res = condMutualInfo([1,2,1,2,1,2,1,2], [3,1,2,3,4,2,1,2],
                              [1,2,3,1,2,3,1,2]);
    assert(approxEqual(res, 0.4387));
    res = condMutualInfo([1,2,3,1,2], [2,1,3,2,1], [1,1,1,2,2], [2,2,2,1,1]);
    assert(approxEqual(res, 1.3510));
    writeln("Passed condMutualInfo unittest.");
}

/**Calculates the entropy of any old array of observations more quickly than
 * entropy(), provided that it is sorted.  If the input is sorted by more than
 * one key, i.e. structs, the result will be the joint entropy of all of the
 * keys.  The compFun alias will be used to compare adjacent elements and
 * determine how many instances of each value exist.*/
real entropySorted(alias compFun = "a == b", T)(T[] data) {
    alias binaryFun!(compFun) comp;
    invariant size_t n = data.length;
    invariant real nrNeg1 = 1.0L / n;

    real sum = 0.0L;
    real nSame = 1.0L;
    size_t pos = 1;
    while(pos < n) {
        if(comp(data[pos], data[pos - 1]))
            nSame++;
        else {
            real p = nSame * nrNeg1;
            nSame = 1.0L;
            sum -= p * log2(p);
        }
        pos++;
    }
    // Handle last run.
    real p = nSame * nrNeg1;
    sum -= p * log2(p);

    return sum;
}

unittest {
    uint[] foo = [1U,2,3,1,3,2,6,3,1,6,3,2,2,1,3,5,2,1].dup;
    assert(approxEqual(entropySorted(foo.dup.qsort), entropy(foo)));
    writeln("Passed entroySorted test.");
}

template atomsOfArrayTuple(T...) {
    mixin("alias TypeTuple!(Mutable!(" ~ (atomType!(T[0])).stringof ~ ")" ~
          atomsOfArrayTupleImpl!(T[1..$]) ~ " atomsOfArrayTuple;");
}

template atomsOfArrayTupleImpl(T...) {
    static if(T.length == 0)
        const char[] atomsOfArrayTupleImpl = ")";
    else const char[] atomsOfArrayTupleImpl = ", Mutable!(" ~
                      (atomType!(T[0])).stringof ~ ")" ~
                      atomsOfArrayTupleImpl!(T[1..$]);
}

template atomType(T : T[]) {
    alias T atomType;
}

// Verify that there are no TempAlloc memory leaks anywhere in the code covered
// by the unittest.  This should always be the last unittest of the module.
unittest {
    auto TAState = TempAlloc.getState;
    assert(TAState.used == 0);
    assert(TAState.nblocks < 2);
}
