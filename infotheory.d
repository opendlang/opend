/**Basic information theory.  Joint entropy, mutual information, conditional
 * mutual information.  This module uses the base 2 definition of these
 * quantities, i.e, entropy, mutual info, etc. are output in bits.
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

module dstats.infotheory;

import std.traits, std.math, std.typetuple, std.functional, std.range,
       std.array, std.typecons;

import dstats.sort, dstats.summary, dstats.base, dstats.alloc;

version(unittest) {
    import std.stdio, std.bigint;

    void main() {}
}

/**This function calculates the Shannon entropy of a forward range that is
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
real entropyCounts(T)(T data)
if(isForwardRange!(T)) {
    auto save = data;
    return entropyCounts(save, sum!(T, real)(data));
}

real entropyCounts(T)(T data, real n)
if(isForwardRange!(T)) {
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
    real uniform3 = entropyCounts([4, 4, 4].dup);
    assert(approxEqual(uniform3, log2(3)));
    real uniform4 = entropyCounts([5, 5, 5, 5].dup);
    assert(approxEqual(uniform4, 2));
    assert(entropyCounts([2,2].dup)==1);
    assert(entropyCounts([5.1,5.1,5.1,5.1].dup)==2);
    assert(approxEqual(entropyCounts([1,2,3,4,5].dup), 2.1492553971685));
    writefln("Passed entropyCounts unittest.");
}

template FlattenType(T...) {
    alias FlattenTypeImpl!(T).ret FlattenType;
}

template FlattenTypeImpl(T...) {
    static if(T.length == 0) {
        alias TypeTuple!() ret;
    } else {
        T[0] j;
        static if(is(typeof(j._jointRanges))) {
            alias TypeTuple!(typeof(j._jointRanges), FlattenType!(T[1..$])) ret;
        } else {
            alias TypeTuple!(T[0], FlattenType!(T[1..$])) ret;
        }
    }
}

private Joint!(FlattenType!(T, U)) flattenImpl(T, U...)(T start, U rest) {
    static if(rest.length == 0) {
        return start;
    } else static if(is(typeof(rest[0]._jointRanges))) {
        return flattenImpl(jointImpl(start.tupleof, rest[0]._jointRanges), rest[1..$]);
    } else {
        return flattenImpl(jointImpl(start.tupleof, rest[0]), rest[1..$]);
    }
}

Joint!(FlattenType!(T)) flatten(T...)(T args) {
    static assert(args.length > 0);
    static if(is(typeof(args[0]._jointRanges))) {
        auto myTuple = args[0];
    } else {
        auto myTuple = jointImpl(args[0]);
    }
    static if(args.length == 1) {
        return myTuple;
    } else {
        return flattenImpl(myTuple, args[1..$]);
    }
}

/**Bind a set of ranges together to represent a joint probability distribution.
 *
 * Examples:
 * ---
 * auto foo = [1,2,3,1,1];
 * auto bar = [2,4,6,2,2];
 * auto e = entropy(joint(foo, bar));  // Calculate joint entropy of foo, bar.
 */
Joint!(FlattenType!(T)) joint(T...)(T args) {
    return jointImpl(flatten(args).tupleof);
}

Joint!(T) jointImpl(T...)(T args) {
    return Joint!(T)(args);
}

/**Iterate over a set of ranges in lockstep and return an ObsEnt,
 * which is used internally by entropy functions on each iteration.*/
struct Joint(T...) {
    T _jointRanges;

    auto front() {
        alias ElementsTuple!(T) E;
        alias ObsEnt!(E) rt;
        rt ret;
        foreach(ti, elem; _jointRanges) {
            ret.tupleof[ti] = elem.front;
        }
        return ret;
    }

    void popFront() {
        foreach(ti, elem; _jointRanges) {
            _jointRanges[ti].popFront;
        }
    }

    bool empty() {
        foreach(elem; _jointRanges) {
            if(elem.empty) {
                return true;
            }
        }
        return false;
    }

    static if(T.length > 0 && allSatisfy!(dstats.base.hasLength, T)) {
        uint length() {
            uint ret = uint.max;
            foreach(range; _jointRanges) {
                auto len = range.length;
                if(len < ret) {
                    ret = len;
                }
            }
            return ret;
        }
    }
}

template ElementsTuple(T...) {
    static if(T.length == 1) {
        alias TypeTuple!(Unqual!(ElementType!(T[0]))) ElementsTuple;
    } else {
        alias TypeTuple!(Unqual!(ElementType!(T[0])), ElementsTuple!(T[1..$]))
            ElementsTuple;
    }
}

private template Comparable(T) {
    enum bool Comparable = is(typeof({
        T a;
        T b;
        return a < b; }));
}

struct ObsEnt(T...) {
    T compRep;

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

    bool opEquals(ref typeof(this) rhs) {
        foreach(ti, elem; this.tupleof) {
            if(elem != rhs.tupleof[ti])
                return false;
        }
        return true;
    }

    static if(allSatisfy!(Comparable, T)) {
        int opCmp(ref typeof(this) rhs) {
            foreach(ti, elem; this.tupleof) {
                if(rhs.tupleof[ti] < elem) {
                    return -1;
                } else if(rhs.tupleof[ti] > elem) {
                    return 1;
                }
            }
            return 0;
        }
    }

}

/**Calculates the joint entropy of a set of observations.  Each input range
 * represents a vector of observations. If only one range is given, this reduces
 * to the plain old entropy.  Input range must have a length.
 *
 * Note:  This function specializes if ElementType!(T) is a byte, ubyte, or
 * char, resulting in a much faster entropy calculation.  When possible, try
 * to provide data in the form of a byte, ubyte, or char.
 *
 * Examples:
 * ---
 * int[] foo = [1, 1, 1, 2, 2, 2, 3, 3, 3];
 * real entropyFoo = entropy(foo);  // Plain old entropy of foo.
 * assert(approxEqual(entropyFoo, log2(3)));
 * int[] bar = [1, 2, 3, 1, 2, 3, 1, 2, 3];
 * real HFooBar = entropy(joint(foo, bar));  // Joint entropy of foo and bar.
 * assert(approxEqual(HFooBar, log2(9)));
 * ---
 */
real entropy(T)(T data)
if(isInputRange!(T) && dstats.base.hasLength!(T)) {
    if(data.length <= ubyte.max) {
        return entropyImpl!(ubyte, T)(data);
    } else if(data.length <= ushort.max) {
        return entropyImpl!(ushort, T)(data);
    } else {
        return entropyImpl!(uint, T)(data);
    }
}

private real entropyImpl(U, T)(T data)
if(ElementType!(T).sizeof > 1) {  // Generic version.
    alias typeof(data.front()) E;

    TempAlloc.frameInit;
    alias StackHash!(E, U) mySh;
    immutable len = data.length;  // In case length calculation is expensive.
    mySh counts = mySh(len / 5);

    foreach(elem; data)  {
        counts[elem]++;
    }

    real ans = entropyCounts(counts.values, len);
    TempAlloc.frameFree;
    return ans;
}

private real entropyImpl(U, T)(T data)  // byte/char specialization
if(ElementType!(T).sizeof == 1) {
    alias typeof(data.front()) E;

    U[ubyte.max + 1] counts;

    uint min = ubyte.max, max = 0;
    foreach(elem; data)  {
        static if(is(E == byte)) {
            // Keep adjacent elements adjacent.  In real world use cases,
            // probably will have ranges like [-1, 1].
            ubyte e = cast(ubyte) (elem) + byte.max;
        } else {
            ubyte e = cast(ubyte) elem;
        }
        counts[e]++;
        if(e > max) {
            max = e;
        }
        if(e < min) {
            min = e;
        }
    }

    return entropyCounts(counts.ptr[min..max + 1], data.length);
}

unittest {
    { // Generic version.
        int[] foo = [1, 1, 1, 2, 2, 2, 3, 3, 3];
        real entropyFoo = entropy(foo);
        assert(approxEqual(entropyFoo, log2(3)));
        int[] bar = [1, 2, 3, 1, 2, 3, 1, 2, 3];
        auto stuff = joint(foo, bar);
        real jointEntropyFooBar = entropy(joint(foo, bar));
        assert(approxEqual(jointEntropyFooBar, log2(9)));
    }
    { // byte specialization
        byte[] foo = [-1, -1, -1, 2, 2, 2, 3, 3, 3];
        real entropyFoo = entropy(foo);
        assert(approxEqual(entropyFoo, log2(3)));
        string bar = "ACTGGCTA";
        assert(entropy(bar) == 2);
    }
    writeln("Passed entropy unittest.");
}

/**Calculate the conditional entropy H(data | cond).*/
real condEntropy(T, U)(T data, U cond)
if(isInputRange!(T) && isInputRange!(U)) {
    return entropy(joint(data, cond)) - entropy(cond);
}

unittest {
    // This shouldn't be easy to screw up.  Just really basic.
    int[] foo = [1,2,2,1,1];
    int[] bar = [1,2,3,1,2];
    assert(approxEqual(entropy(foo) - condEntropy(foo, bar),
           mutualInfo(foo, bar)));
    writeln("Passed condEntroy unittest.");
}



/**Calculates the mutual information of two vectors of observations.
 */
real mutualInfo(T, U)(T x, U y)
if(isInputRange!(T) && isInputRange!(U)) {
    return entropy(x) + entropy(y) - entropy(joint(x, y));
}

unittest {
    // Values from R, but converted from base e to base 2.
    assert(approxEqual(mutualInfo(bin([1,2,3,3,8].dup, 10),
           bin([8,6,7,5,3].dup, 10)), 1.921928));
    assert(approxEqual(mutualInfo(bin([1,2,1,1,3,4,3,6].dup, 2),
           bin([2,7,9,6,3,1,7,40].dup, 2)), .2935645));
    assert(approxEqual(mutualInfo(bin([1,2,1,1,3,4,3,6].dup, 4),
           bin([2,7,9,6,3,1,7,40].dup, 4)), .5435671));

    writeln("Passed mutualInfo unittest.");
}

/**Calculates the conditional mutual information I(x, y | z).*/
real condMutualInfo(T, U, V)(T x, U y, V z) {
    return entropy(joint(x, z)) + entropy(joint(y, z)) -
           entropy(joint(x, y, z)) - entropy(z);
}

unittest {
    // Values from Matlab mi package by Hanchuan Peng.
    auto res = condMutualInfo([1,2,1,2,1,2,1,2].dup, [3,1,2,3,4,2,1,2].dup,
                              [1,2,3,1,2,3,1,2].dup);
    assert(approxEqual(res, 0.4387));
    res = condMutualInfo([1,2,3,1,2].dup, [2,1,3,2,1].dup,
                         joint([1,1,1,2,2].dup, [2,2,2,1,1].dup));
    assert(approxEqual(res, 1.3510));
    writeln("Passed condMutualInfo unittest.");
}

/**Calculates the entropy of any old input range of observations more quickly
 * than entropy(), provided that all equal values are adjacent.  If the input
 * is sorted by more than one key, i.e. structs, the result will be the joint
 * entropy of all of the keys.  The compFun alias will be used to compare
 * adjacent elements and determine how many instances of each value exist.*/
real entropySorted(alias compFun = "a == b", T)(T data)
if(isInputRange!(T)) {
    alias ElementType!(T) E;
    alias binaryFun!(compFun) comp;
    immutable n = data.length;
    immutable nrNeg1 = 1.0L / n;

    real sum = 0.0L;
    real nSame = 1.0L;
    auto last = data.front;
    data.popFront;
    foreach(elem; data) {
        if(comp(elem, last))
            nSame++;
        else {
            real p = nSame * nrNeg1;
            nSame = 1.0L;
            sum -= p * log2(p);
        }
        last = elem;
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

// Verify that there are no TempAlloc memory leaks anywhere in the code covered
// by the unittest.  This should always be the last unittest of the module.
unittest {
    auto TAState = TempAlloc.getState;
    assert(TAState.used == 0);
    assert(TAState.nblocks < 2);
}
