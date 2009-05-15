/**Relatively low-level primitives on which to build higher-level math/stat
 * functionality.  Some are used internally, some are just things that may be
 * useful to users of this library.  This module is starting to take on the
 * appearance of a small utility library.
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

module dstats.base;

public import std.math, std.traits, dstats.gamma, dstats.alloc;
private import dstats.sort, std.c.stdlib, std.bigint, std.typecons,
               std.functional, std.algorithm, std.range, std.bitmanip,
               std.stdio;

import std.string : strip;
import std.conv : to;

immutable real[] staticLogFacTable;

enum : size_t {
    staticFacTableLen = 10_000,
}

static this() {
    // Allocating on heap instead of static data segment to avoid
    // false pointer GC issues.
    real[] sfTemp = new real[staticFacTableLen];
    sfTemp[0] = 0;
    for(uint i = 1; i < staticFacTableLen; i++) {
        sfTemp[i] = sfTemp[i - 1] + log(i);
    }
    staticLogFacTable = cast(immutable) sfTemp;
}

version(unittest) {
    import std.stdio, std.algorithm, std.random, std.file;

    void main (){}
}

/**Parameter in some functions to determine where results are returned.
 * Alloc.HEAP returns on the GC heap and is always the default.  Alloc.STACK
 * returns on the TempAlloc stack, and can be a useful optimization in some
 * cases.*/
enum Alloc {
    ///Return on TempAlloc stack.
    STACK,

    ///Return on GC heap.
    HEAP
}

/** Tests whether T is an input range whose elements can be implicitly
 * converted to reals.*/
template realInput(T) {
    enum realInput = isInputRange!(T) && is(ElementType!(T) : real);
}

// See Bugzilla 2873.  This can be removed once that's fixed.
template hasLength(R) {
    enum bool hasLength = is(typeof(R.init.length) : ulong) ||
                      is(typeof(R.init.length()) : ulong);
}


/**Tests whether T can be iterated over using foreach.  This is a superset
 * of isInputRange, as it also accepts things that use opApply, builtin
 * arrays, builtin associative arrays, etc.  Useful when all you need is
 * lowest common denominator iteration functionality and don't care about
 * more advanced range features.*/
template isIterable(T)
{
    static if (is(typeof({foreach(elem; T.init) {}}))) {
        enum bool isIterable = true;
    } else {
        enum bool isIterable = false;
    }
}

unittest {
    struct Foo {  // For testing opApply.

        int opApply(int delegate(ref uint) dg) { assert(0); }
    }

    static assert(isIterable!(uint[]));
    static assert(!isIterable!(uint));
    static assert(isIterable!(Foo));
    static assert(isIterable!(uint[string]));
    static assert(isIterable!(Chain!(uint[], uint[])));
}

/**Determine the iterable type of any iterable object, regardless of whether
 * it uses ranges, opApply, etc.  This is typeof(elem) if one does
 * foreach(elem; T.init) {}.*/
template IterType(T) {
    alias ReturnType!(
        {
            foreach(elem; T.init) {
                return elem;
            }
        }) IterType;
}

unittest {
    struct Foo {  // For testing opApply.
        // For testing.

        int opApply(int delegate(ref uint) dg) { assert(0); }
    }

    static assert(is(IterType!(uint[]) == uint));
    static assert(is(IterType!(Foo) == uint));
    static assert(is(IterType!(uint[string]) == uint));
    static assert(is(IterType!(Chain!(uint[], uint[])) == uint));
}

/**Tests whether T is iterable and has elements of a type implicitly
 * convertible to real.*/
template realIterable(T) {
    enum realIterable = isIterable!(T) && is(IterType!(T) : real);
}

/**Writes the contents of an input range to an output range.
 *
 * Returns:  The output range.*/
O mate(I, O)(I input, O output)
if(isInputRange!(I) && isOutputRange!(O, ElementType!(I))) {
    foreach(elem; input) {
        output.put(elem);
    }
    return output;
}

/**Bins data into nbin equal width bins, indexed from
 * 0 to nbin - 1, with 0 being the smallest bin, etc.
 * The values returned are the counts for each bin.  Returns results on the GC
 * heap by default, but uses TempAlloc stack if alloc == Alloc.STACK.
 *
 * Works with any forward range with elements implicitly convertible to real.*/
Ret[] binCounts(Ret = ushort, T)(T data, uint nbin, Alloc alloc = Alloc.HEAP)
if(isForwardRange!(T) && realInput!(T))
in {
    assert(nbin > 0);
} body {
    alias Unqual!(ElementType!(T)) E;
    E min = data.front, max = data.front;
    foreach(elem; data) {
        if(elem > max)
            max = elem;
        else if(elem < min)
            min = elem;
    }
    E range = max - min;

    Ret[] bins;
    if(alloc == Alloc.HEAP) {
        bins = new Ret[nbin];
    } else {
        bins = newStack!(Ret)(nbin);
        bins[] = 0U;
    }

    foreach(elem; data) {
        // Using the truncation as a feature.
        uint whichBin = cast(uint) ((elem - min) * nbin / range);

        // Handle edge case by putting largest item in largest bin.
        if(whichBin == nbin)
            whichBin--;

        bins[whichBin]++;
    }

    return bins;
}

unittest {
    double[] data = [0.0, .01, .03, .05, .11, .3, .5, .7, .89, 1];
    auto res = binCounts(data, 10);
    assert(res == [cast(ushort) 4, 1, 0, 1, 0, 1, 0, 1, 1, 1]);
    res = binCounts(data, 10, Alloc.STACK);
    assert(res == [cast(ushort) 4, 1, 0, 1, 0, 1, 0, 1, 1, 1]);
    TempAlloc.free;
    writeln("Passed binCounts unittest.");
}

/**Bins data into nbin equal width bins, indexed from
 * 0 to nbin - 1, with 0 being the smallest bin, etc.
 * The values returned are the bin index for each element.
 *
 * Returns on GC heap by default, but TempAlloc stack if alloc == Alloc.STACK.
 * Works with any forward range with elements implicitly convertible to real.
 *
 * Default return type is ubyte, because in the dstats.infotheory,
 * entropy() and related functions specialize on ubytes, and become
 * substandially faster.  However, if you're using more than 255 bins,
 * you'll have to provide a different return type as a template parameter.*/
Ret[] bin(Ret = ubyte, T)(T data, uint nbin, Alloc alloc = Alloc.HEAP)
if(isForwardRange!(T) && realInput!(T) && isIntegral!(Ret))
in {
    assert(nbin <= Ret.max + 1);
    assert(nbin > 0);
} body {
    alias ElementType!(T) E;
    Unqual!(E) min = data.front, max = data.front;
    auto dminmax = data;
    dminmax.popFront;
    foreach(elem; dminmax) {
        if(elem > max)
            max = elem;
        else if(elem < min)
            min = elem;
    }
    E range = max - min;

    Ret[] bins;
    if(alloc == Alloc.HEAP) {
        bins = newVoid!(Ret)(data.length);
    } else {
        bins = newStack!(Ret)(data.length);
    }

    foreach(i, elem; data) {
        // Using the truncation as a feature.
        uint whichBin = cast(uint) ((elem - min) * nbin / range);

        // Handle edge case by putting largest item in largest bin.
        if(whichBin == nbin)
            whichBin--;

        bins[i] = whichBin;
    }

    return bins;
}

unittest {
    mixin(newFrame);
    double[] data = [0.0, .01, .03, .05, .11, .3, .5, .7, .89, 1];
    auto res = bin(data, 10);
    assert(res == [cast(ubyte) 0, 0, 0, 0, 1, 3, 5, 7, 8, 9]);
    res = bin(data, 10, Alloc.STACK);
    assert(res == [cast(ubyte) 0, 0, 0, 0, 1, 3, 5, 7, 8, 9]);
    TempAlloc.free;
    writeln("Passed bin unittest.");
}

/**Bins data into nbin equal frequency bins, indexed from
 * 0 to nbin - 1, with 0 being the smallest bin, etc.
 * The values returned are the bin index for each element.
 *
 * Returns on GC heap by default, but TempAlloc stack if alloc == Alloc.STACK.
 * Works with any forward range with elements implicitly convertible to real
 * and a length property.
 *
 * Default return type is ubyte, because in the dstats.infotheory,
 * entropy() and related functions specialize on ubytes, and become
 * substandially faster.  However, if you're using more than 256 bins,
 * you'll have to provide a different return type as a template parameter.*/
Ret[] frqBin(Ret = ubyte, T)(T data, uint nbin, Alloc alloc = Alloc.HEAP)
if(realInput!(T) && isForwardRange!(T) && hasLength!(T) && isIntegral!(Ret))
in {
    assert(nbin > 0);
    assert(nbin <= data.length);
    assert(nbin <= Ret.max + 1);
} body {
    Ret[] result;
    if(alloc == Alloc.HEAP) {
        result = newVoid!(Ret)(data.length);
    } else {
        result = newStack!(Ret)(data.length);
    }

    auto perm = newStack!(uint)(data.length); scope(exit) TempAlloc.free;
    foreach(i, ref e; perm)
        e = i;
    auto dd = tempdup(data);
    qsort(dd, perm);
    TempAlloc.free;

    uint rem = data.length % nbin;
    Ret bin = 0;
    uint i = 0, frq = data.length / nbin;
    while(i < data.length) {
        foreach(j; 0..(bin < rem) ? frq + 1 : frq) {
            result[perm[i++]] = bin;
        }
        bin++;
    }
    return result;
}

unittest {
    double[] data = [5U, 1, 3, 8, 30, 10, 7];
    auto res = frqBin(data, 3);
    assert(res == [cast(ubyte) 0, 0, 0, 1, 2, 2, 1]);
    data = [3, 1, 4, 1, 5, 9, 2, 6, 5];
    res = frqBin(data, 4, Alloc.STACK);
    assert(res == [cast(ubyte) 1, 0, 1, 0, 2, 3, 0, 3, 2]);
    data = [3U, 1, 4, 1, 5, 9, 2, 6, 5, 3, 4, 8, 9, 7, 9, 2];
    res = frqBin(data, 4);
    assert(res == [cast(ubyte) 1, 0, 1, 0, 2, 3, 0, 2, 2, 1, 1, 3, 3, 2, 3, 0]);
    TempAlloc.free;
    writeln("Passed frqBin unittest.");
}

/**Generates a sequence from [start..end] by increment.  Includes start,
 * excludes end.  Does so eagerly as an array.
 *
 * Examples:
 * ---
 * auto s = seq(0, 5);
 * assert(s == [0, 1, 2, 3, 4]);
 * ---*/

T[] seq(T)(T start, T end, T increment = 1, Alloc alloc = Alloc.HEAP) {
    T[] output;
    if(alloc == Alloc.HEAP) {
        output = newVoid!(T)(cast(size_t) ((end - start) / increment));
    } else {
        output = newStack!(T)(cast(size_t) ((end - start) / increment));
    }
    size_t count = 0;
    for(T i = start; i < end; i += increment) {
        output[count++] = i;
    }
    return output;
}

unittest {
    auto s = seq(0, 5);
    assert(s == [0, 1, 2, 3, 4]);
    writeln("Passed seq test.");
}

/**Given an input array, outputs an array containing the rank from
 * [1, input.length] corresponding to each element.  Ties are dealt with by
 * averaging.  This function duplicates the input range, and does not reorder
 * it.  Return type is float[] by default, but if you are sure you have no ties,
 * ints can be used for efficiency, and if you need more precision when
 * averaging ties, you can use double or real.
 *
 * Works with any input range.
 *
 * Examples:
 * ---
 * uint[] test = [3, 5, 3, 1, 2];
 * assert(rank(test) == [3.5f, 5f, 3.5f, 1f, 2f]);
 * assert(test == [3U, 5, 3, 1, 2]);
 * ---*/
Ret[] rank(Ret = float, T)(const T[] input) {
    auto iDup = tempdup(input);
    scope(exit) TempAlloc.free;
    return rankSort!(Ret)(iDup);
}

/**Same as rank(), but sorts the input range in ascending order rather than
 * duping it and working on a copy.  The array returned will still be
 * identical to that returned by rank(), i.e. the rank of each element will
 * correspond to the ranks of the elements in the input array before sorting.
 *
 * Works with any random access range with a length property.
 *
 * Examples:
 * ---
 * uint[] test = [3, 5, 3, 1, 2];
 * assert(rank(test) == [3.5f, 5f, 3.5f, 1f, 2f]);
 * assert(test == [1U, 2, 3, 4, 5]);
 * ---*/
Ret[] rankSort(Ret = float, T)(T input)
if(isRandomAccessRange!(T)) {
    Ret[] ranks = newVoid!(Ret)(input.length);
    rankSort!(Ret, T)(input, ranks);
    return ranks;
}

// Speed hack used internally.
void rankSort(Ret, T)(T input, Ret[] ranks) {
    size_t[] perms = newStack!(size_t)(input.length);
    scope(exit) TempAlloc.free;

    foreach(i, ref p; perms)
        p = i;

    qsort(input, perms);
    foreach(i; 0..perms.length)  {
        ranks[perms[i]] = i + 1;
    }
    averageTies(input, ranks, perms);
    return ranks;
}

unittest {
    uint[] test = [3, 5, 3, 1, 2];
    assert(rank(test) == [3.5f, 5f, 3.5f, 1f, 2f]);
    assert(test == [3U, 5, 3, 1, 2]);
    assert(rank!(double)(test) == [3.5, 5, 3.5, 1, 2]);
    assert(rankSort(test) == [3.5f, 5f, 3.5f, 1f, 2f]);
    assert(test == [1U,2,3,3,5]);
    writeln("Passed rank test.");
}

// Used internally by rank().
void averageTies(T, U)(T sortedInput, U[] ranks, uint[] perms) nothrow
in {
    assert(sortedInput.length == ranks.length);
    assert(ranks.length == perms.length);
} body {
    uint tieCount = 1, tieSum = cast(uint) ranks[perms[0]];
    foreach(i; 1..ranks.length) {
        if(sortedInput[i] == sortedInput[i-1]) {
            tieCount++;
            tieSum += ranks[perms[i]];
        } else{
            if(tieCount > 1){
                real avg = cast(real) tieSum / tieCount;
                foreach(perm; perms[i - tieCount..i]) {
                    ranks[perm] = avg;
                }
                tieCount = 1;
            }
            tieSum = cast(uint) ranks[perms[i]];
        }
    }
    if(tieCount > 1) { // Handle the end.
        real avg = cast(real) tieSum / tieCount;
        foreach(perm; perms[perms.length - tieCount..$]) {
            ranks[perm] = avg;
        }
        tieCount = 1;
    }
}

/**Returns an AA of counts of every element in input.  Works w/ any iterable.
 *
 * Examples:
 * ---
 * int[] foo = [1,2,3,1,2,4];
 * uint[int] frq = frequency(foo);
 * assert(frq.length == 4);
 * assert(frq[1] == 2);
 * assert(frq[4] == 1);
 * ---*/
uint[IterType!(T)] frequency(T)(T input)
if(isIterable!(T)) {
    typeof(return) output;
    foreach(i; input) {
        output[i]++;
    }
    return output;
}

unittest {
    int[] foo = [1,2,3,1,2,4];
    uint[int] frq = frequency(foo);
    assert(frq.length == 4);
    assert(frq[1] == 2);
    assert(frq[4] == 1);
    writeln("Passed frequency test.");
}

///
T sign(T)(T num) pure nothrow {
    if (num > 0) return 1;
    if (num < 0) return -1;
    return 0;
}

unittest {
    assert(sign(3.14159265)==1);
    assert(sign(-3)==-1);
    assert(sign(-2.7182818)==-1);
    writefln("Passed sign unittest.");
}

///
/*Values up to 9,999 are pre-calculated and stored in
 * an invariant global array, for performance.  After this point, the gamma
 * function is used, because caching would take up too much memory, and if
 * done lazily, would cause threading issues.*/
real logFactorial(uint n) {
    //Input is uint, can't be less than 0, no need to check.
    if(n < staticFacTableLen) {
        return staticLogFacTable[n];
    } else return lgamma(cast(real) (n + 1));
}

unittest {
    // Cache branch.
    assert(cast(uint) round(exp(logFactorial(4)))==24);
    assert(cast(uint) round(exp(logFactorial(5)))==120);
    assert(cast(uint) round(exp(logFactorial(6)))==720);
    assert(cast(uint) round(exp(logFactorial(7)))==5040);
    assert(cast(uint) round(exp(logFactorial(3)))==6);
    // Gamma branch.
    assert(approxEqual(logFactorial(12000), 1.007175584216837e5, 1e-14));
    assert(approxEqual(logFactorial(14000), 1.196610688711534e5, 1e-14));
    writefln("Passed logFactorial unit test.");
}

///Log of (n choose k).
real logNcomb(uint n, uint k)
in {
    assert(k <= n);
} body {
    if(n < k) return -real.infinity;
    //Extra parentheses increase numerical accuracy.
    return logFactorial(n) - (logFactorial(k) + logFactorial(n-k));
}

unittest {
    assert(cast(uint) round(exp(logNcomb(4,2)))==6);
    assert(cast(uint) round(exp(logNcomb(30,8)))==5852925);
    assert(cast(uint) round(exp(logNcomb(28,5)))==98280);
    writefln("Passed logNcomb unit test.");
}

/////No, nothing this horribly inefficient is used internally.
//BigInt factorial(uint N) {
//    BigInt result = 1;
//    for(uint i = 2; i <= N; i++) {
//        result *= i;
//    }
//    return result;
//}
//
//unittest {
//    assert(factorial(4) == 24);
//    assert(factorial(5) == 120);
//    assert(factorial(6) == 720);
//    assert(factorial(7) == 5040);
//    assert(factorial(3) == 6);
//    writefln("Passed factorial test.");
//}

/**A struct that generates all possible permutations of a sequence,
 * and can be iterated over with foreach.  Note that permutations are
 * output in undefined order.  Also note that the returned permutations
 * are references to the internal permutation state.  This is dangerous, but
 * necessary for performance.  Therefore, you
 * will have to dup them if you expect them not to change.  This is also
 * the rationale for not making this struct an input range.
 *
 * Examples:
 * ---
 *  double[][] res;
 *  auto perm = Perm!(double)(cast(double[]) [1.0, 2.0, 3.0]);
 *  foreach(p; perm) {
 *      res ~= p.dup;
 *  }
 *  assert(res.canFind([1.0, 2.0, 3.0]));
 *  assert(res.canFind([1.0, 3.0, 2.0]));
 *  assert(res.canFind([2.0, 1.0, 3.0]));
 *  assert(res.canFind([2.0, 3.0, 1.0]));
 *  assert(res.canFind([3.0, 1.0, 2.0]));
 *  assert(res.canFind([3.0, 2.0, 1.0]));
 *  assert(res.length == 6);
 *  ---*/
struct Perm(T = uint) {
private:
    T* perm;
    size_t* Is;
    size_t currentI;
    size_t len;

public:
    /**Generate permutations from an input range.
     * Create a duplicate of this sequence
     * so that the original sequence is not modified.*/
    this(U)(U input)
    if(isForwardRange!(U)) {
        auto arr = toArray(input);
        Is = (new size_t[arr.length]).ptr;
        len = arr.length;
        perm = arr.ptr;
    }

    /**Get the next permutation in the sequence.*/
    const(T)[] next() {
        if(currentI == len - 1) {
            currentI--;
            return perm[0..len];
        }

        uint max = len - currentI;
        if(Is[currentI] == max) {
            if(currentI == 0)
                return [];
            Is[currentI..len] = 0;
            currentI--;
            return next();
        } else {
            rotateLeft(perm[currentI..len]);
            Is[currentI]++;
            currentI++;
            return next();
        }
    }

    /**Iterate over all permutations of the sequence.*/
    int opApply(int delegate(ref const(T)[]) dg) {
        int res = 0;
        while(true) {
          auto nextSeq = next();
          if(nextSeq.length == 0) break;
          res = dg(nextSeq);
          if (res) break;
        }
        return res;
    }

}

private template PermRet(T...) {
    static if(isForwardRange!(T[0])) {
        alias Perm!(ElementType!(T[0])) PermRet;
    } else static if(T.length == 1) {
        alias Perm!uint PermRet;
    } else alias Perm!(T[0]) PermRet;
}

/**Create a Perm struct from a range or of a set of bounds.
 *
 * Note:  PermRet is just a template to figure out what this should return.
 * I would use auto if not for bug 2251.
 *
 * Examples:
 * ---
 * auto p = perm([1,2,3]);
 * auto p = perm(5);  // Permutations of integers on range [0, 5].
 * auto p = perm(-1, 2); // Permutations of integers on range [-1, 2].
 * ---
 */
PermRet!(T) perm(T...)(T stuff) {
    alias typeof(return) rt;
    static if(isForwardRange!(T[0])) {
        return rt(stuff);
    } else static if(T.length == 1) {
        static assert(isIntegral!(T[0]));
        return rt(seq(0U, cast(uint) stuff[0]));
    } else {
        return rt(seq(stuff));
    }
}


unittest {
    double[][] res;
    auto p1 = perm(cast(double[]) [1.0, 2.0, 3.0]);
    foreach(p; p1) {
        res ~= p.dup;
    }
    sort(res);
    assert(res.canFindSorted([1.0, 2.0, 3.0]));
    assert(res.canFindSorted([1.0, 3.0, 2.0]));
    assert(res.canFindSorted([2.0, 1.0, 3.0]));
    assert(res.canFindSorted([2.0, 3.0, 1.0]));
    assert(res.canFindSorted([3.0, 1.0, 2.0]));
    assert(res.canFindSorted([3.0, 2.0, 1.0]));
    assert(res.length == 6);
    uint[][] res2;
    auto perm2 = perm(3);
    foreach(p; perm2) {
        res2 ~= p.dup;
    }
    sort(res2);
    assert(res2.canFindSorted([0u, 1, 2]));
    assert(res2.canFindSorted([0u, 2, 1]));
    assert(res2.canFindSorted([1u, 0, 2]));
    assert(res2.canFindSorted([1u, 2, 0]));
    assert(res2.canFindSorted([2u, 0, 1]));
    assert(res2.canFindSorted([2u, 1, 0]));
    assert(res2.length == 6);

    // Indirect tests:  If the elements returned are unique, there are N! of
    // them, and they contain what they're supposed to contain, the result is
    // correct.
    auto perm3 = perm(6);
    bool[uint[]] table;
    foreach(p; perm3) {
        table[p.dup] = true;
    }
    assert(table.length == 720);
    foreach(elem, val; table) {
        assert(elem.dup.insertionSort == [0U, 1, 2, 3, 4, 5]);
    }
    auto perm4 = perm(5);
    bool[uint[]] table2;
    foreach(p; perm4) {
        table2[p.dup] = true;
    }
    assert(table2.length == 120);
    foreach(elem, val; table2) {
        assert(elem.dup.insertionSort == [0U, 1, 2, 3, 4]);
    }
    writeln("Passed Perm test.");
}

private template CombRet(T) {
    static if(isForwardRange!(T)) {
        alias Comb!(Unqual!(ElementType!(T))) CombRet;
    } else static if(is(T : uint)) {
        alias Comb!uint CombRet;
    } else static assert(0, "comb can only be created with range or uint.");
}

/**Create a Comb struct from a range or of a set of bounds.
 *
 * Note:  CombRet is just a template to figure out what this should return.
 * I would use auto if not for bug 2251.
 *
 * Examples:
 * ---
 * auto p = comb([1,2,3]);
 * auto p = comb(5);  // Permutations of integers on range [0, 5].
 * ---
 */
CombRet!(T) comb(T)(T stuff, uint r) {
    alias typeof(return) rt;
    static if(isForwardRange!(T)) {
        return rt(stuff, r);
    } else {
        return rt(seq(0U, cast(uint) stuff), r);
    }
}

/**Generates every possible combination of r elements of the given sequence, or r
 * array indices from zero to N, depending on which ctor is called.  These can
 * be iterated over with a foreach loop.  Note that the combinations returned
 * are const references to the internal state of the Comb object.  This is
 * dangerous but necessary for performance.  If you want to save them past the
 * next  iteration, you'll have to dup them yourself.  This is also the
 * rationale for not making this struct an input range.
 *
 * Examples:
 * ---
    auto comb1 = Comb!(uint)(5, 2);
    uint[][] vals;
    foreach(c; comb1) {
        vals ~= c.dup;
    }
    assert(vals.canFind([0u,1].dup));
    assert(vals.canFind([0u,2].dup));
    assert(vals.canFind([0u,3].dup));
    assert(vals.canFind([0u,4].dup));
    assert(vals.canFind([1u,2].dup));
    assert(vals.canFind([1u,3].dup));
    assert(vals.canFind([1u,4].dup));
    assert(vals.canFind([2u,3].dup));
    assert(vals.canFind([2u,4].dup));
    assert(vals.canFind([3u,4].dup));
    assert(vals.length == 10);
    ---*/
struct Comb(T) {
private:
    int N;
    int R;
    int diff;
    uint* pos;
    T* myArray;
    T* chosen;

    const(uint)* nextNum() {
        int index = R - 1;
        for(; index != -1 && pos[index] == diff + index; --index) {}
        if(index == -1) {
            return null;
        }
        pos[index]++;
        for(size_t i = index + 1; i < R; ++i) {
            pos[i] = pos[index] + i - index;
        }
        return pos;
    }

    const(T)* nextArray() {
        int index = R - 1;
        for(; index != -1 && pos[index] == diff + index; --index) {}
        if(index == -1) {
            return null;
        }
        pos[index]++;
        chosen[index] = myArray[pos[index]];
        for(size_t i = index + 1; i < R; ++i) {
            pos[i] = pos[index] + i - index;
            chosen[i] = myArray[pos[i]];
        }
        return chosen;
    }

public:
    /**Increment the internal state to the next combination and return a
     * pointer to the beginning of the array of chosen elements.  The first
     * r elements are the ones chosen for this combination.*/
    invariant const(T*) delegate() next;

    static if(is(T == uint)) {
    /**Ctor to generate all possible combinations of array indices for a length r
     * array.  This is a special-case optimization and is faster than simply
     * using the other ctor to generate all length r combinations from
     * seq(0, length).*/
        this(uint n, uint r)
        in {
            assert(r > 0);
            assert(n >= r);
        } body {
            pos = (seq(0U, r)).ptr;
            pos[r - 1]--;
            N = n;
            R = r;
            diff = N - R;
            next = &nextNum;
        }
    }

    /**General ctor.  array is a sequence from which to generate the
     * combinations.  r is the length of the combinations to be generated.*/
    this(T[] array, uint r)
    in {
        assert(r > 0);
    } body {
        pos = (seq(0U, r)).ptr;
        pos[r - 1]--;
        N = array.length;
        R = r;
        diff = N - R;
        auto temp = array.dup;
        myArray = temp.ptr;
        chosen = (new uint[r]).ptr;
        foreach(i; 0..r) {
            chosen[i] = myArray[pos[i]];
        }
        next = &nextArray;
    }

    /**Iterate over all combinations.*/
    int opApply(int delegate(ref const(T)[]) dg) {
        int res = 0;
        while(true) {
          auto nextSeq = next();
          if(nextSeq is null) break;
          res = dg(nextSeq[0..R]);
          if (res) break;
        }
        return res;
    }
}

unittest {
    // Test indexing verison first.
    auto comb1 = comb(5, 2);
    uint[][] vals;
    foreach(c; comb1) {
        vals ~= c.dup;
    }
    sort(vals);
    assert(vals.canFindSorted([0u,1].dup));
    assert(vals.canFindSorted([0u,2].dup));
    assert(vals.canFindSorted([0u,3].dup));
    assert(vals.canFindSorted([0u,4].dup));
    assert(vals.canFindSorted([1u,2].dup));
    assert(vals.canFindSorted([1u,3].dup));
    assert(vals.canFindSorted([1u,4].dup));
    assert(vals.canFindSorted([2u,3].dup));
    assert(vals.canFindSorted([2u,4].dup));
    assert(vals.canFindSorted([3u,4].dup));
    assert(vals.length == 10);

    // Now, test the array version.
    auto comb2 = comb(seq(5U, 10U), 3);
    vals = null;
    foreach(c; comb2) {
        vals ~= c.dup;
    }
    sort(vals);
    assert(vals.canFindSorted([5u, 6, 7].dup));
    assert(vals.canFindSorted([5u, 6, 8].dup));
    assert(vals.canFindSorted([5u, 6, 9].dup));
    assert(vals.canFindSorted([5u, 7, 8].dup));
    assert(vals.canFindSorted([5u, 7, 9].dup));
    assert(vals.canFindSorted([5u, 8, 9].dup));
    assert(vals.canFindSorted([6U, 7, 8].dup));
    assert(vals.canFindSorted([6u, 7, 9].dup));
    assert(vals.canFindSorted([6u, 8, 9].dup));
    assert(vals.canFindSorted([7u, 8, 9].dup));
    assert(vals.length == 10);

    // Now a test of a larger dataset where more subtle bugs could hide.
    // If the values returned are unique even after sorting, are composed of
    // the correct elements, and there is the right number of them, this thing
    // works.

    bool[uint[]] results;  // Keep track of how many UNIQUE items we have.
    auto comb3 = Comb!(uint)(seq(10U, 22U), 6);
    foreach(c; comb3) {
        auto dupped = c.dup.sort;
        // Make sure all elems are unique and within range.
        assert(dupped.length == 6);
        assert(dupped[0] > 9 && dupped[0] < 22);
        foreach(i; 1..dupped.length) {
            // Make sure elements are unique.  Remember, the array is sorted.
            assert(dupped[i] > dupped[i - 1]);
            assert(dupped[i] > 9 && dupped[i] < 22);
        }
        results[dupped] = true;
    }
    assert(results.length == 924);  // (12 choose 6).
    writeln("Passed Comb test.");
}

/**Computes the intersect of two arrays, i.e. the elements that are in both
 * arrays.  Time and space complexity are O(first.length + second.length).
 * Returns on heap by default, but TempAlloc stack if alloc == Alloc.STACK.
 *
 * TODO:  Generalize to N arrays.*/
T[] intersect(T)(const(T)[] first, const(T)[] second, Alloc alloc = Alloc.HEAP) {
    if(first.length > second.length)
        swap(first, second);

    T[] result;  // Have to do this up here before the newFrame.
    if(alloc == Alloc.HEAP) {
        result = newVoid!(T)(first.length);
    } else if(alloc == Alloc.STACK) {
        result = newStack!(T)(first.length);
    }

    alias StackHash!(T, uint) mySh;
    mixin(newFrame);
    mySh firstSet = mySh(first.length);
    foreach(f; first) {
        firstSet[f] = 0;
    }

    foreach(s; second) {
        if(uint* count = s in firstSet)
            (*count)++;
    }

    size_t pos;
    auto key = firstSet.keys;
    auto count = firstSet.values;
    while(!key.empty) {
        if(count.front > 0) {
            result[pos++] = key.front;
        }
        key.popFront;
        count.popFront;
    }
    return result[0..pos];
}

unittest {
    mixin(newFrame);
    assert(intersect([1,3,1,3,6,4,6], [6,6,4,4,2,2,9,10]).sort == [4, 6]);
}

/**Computes the intersect of two arrays sorted according to compFun, i.e. the
 * elements that are in both arrays.  Time complexity is O(first.length
 * + second.length).  Space complexity is O(min(first.length, second.length)).
 * Faster in practice than intersect() if arrays are both already sorted.
 * Returns on heap by default, but TempAlloc stack if alloc == Alloc.STACK.
 *
 * TODO:  Generalize to N arrays.*/
T[] intersectSorted(alias compFun = "a < b", T)(const(T)[] first,
                    const(T)[] second, Alloc alloc = Alloc.HEAP)
in {
    assert(isSorted!(compFun)(first));
    assert(isSorted!(compFun)(second));
} body {
    if(first.length > second.length)
        swap(first, second);

    T[] result;
    if(alloc == Alloc.HEAP) {
        result = newVoid!(T)(first.length);
    } else if(alloc == Alloc.STACK) {
        result = newStack!(T)(first.length);
    }

    alias binaryFun!(compFun) comp;

    static bool notEqual(T lhs, T rhs) {
        return comp(lhs, rhs) || comp(rhs, lhs);
    }

    size_t leftPos, rightPos, resPos;
    T lastAdded;
    bool anyAdded;
    while(leftPos < first.length && rightPos < second.length) {
        if(comp(second[rightPos], first[leftPos])) {
            rightPos++;
        } else if(comp(first[leftPos], second[rightPos])) {
            leftPos++;
        } else {  // Equal
            if(!anyAdded || notEqual(lastAdded, first[leftPos])) {
                result[resPos++] = first[leftPos];
                lastAdded = first[leftPos];
                anyAdded = true;
            }
            leftPos++;
            rightPos++;
        }
    }
    return result[0..resPos];
}

unittest {
    mixin(newFrame);
    assert(intersectSorted([1,3,1,3,6,4,6].sort, [6,6,4,4,2,2,9,10].sort) == [4,6]);

    // We have two different methods, they shoouldn't be wrong in the same way.
    // Test one against the other.
    uint[] first = new uint[500];
    uint[] second = new uint[1000];
    foreach(i; 0..1000) {
        foreach(ref f; first)
            f = uniform(0U, 2500);
        foreach(ref s; second)
            s = uniform(0U, 5000);
        auto hash = qsort!("a > b")(intersect(first, second));
        auto sort = intersectSorted!("a > b")
                    (qsort!("a > b")(first), qsort!("a > b")(second));
        assert(hash == sort);
    }
    writeln("Passed intersect test.");
}

/**Given a file that contains a line-delimited list of numbers, iterate through
 * it as a forward range, converting each line to a real and skipping any line
 * that cannot be converted.
 *
 * Examples:
 * ---
 * // Find the sum of all the numbers in foo.txt without ever having all of
 * // them in memory at the same time.
 *
 * auto data = NumericFile("foo.txt");
 * auto sum = reduce!"a + b"(data);
 * ---
 */
struct NumericFile {
private:
    real cached;
    bool _empty;
    File handle;
    char[] buf;

public:
    ///
    this(string filename) {
        handle = File(filename, "r");
        popFront;
    }

    ///
    void popFront() {
        while(!handle.eof) {
            auto nBytes = handle.readln(buf);
            auto line = strip(buf[0..nBytes]);
            try {
                cached = to!real(line);
                return;
            } catch {
                // Ignore bad lines.
                continue;
            }
        }
        _empty = true;
    }

    ///
    real front() {
        return cached;
    }

    ///
    bool empty() {
        return _empty;
    }

    ///
    void close() {
        handle.close;
    }
}

unittest {
    string data = "3.14\n2.71\n8.67\nabracadabra\n362436";
    std.file.write("NumericFileTestDeleteMe.txt", data);
    scope(exit) std.file.remove("NumericFileTestDeleteMe.txt");
    auto rng = NumericFile("NumericFileTestDeleteMe.txt");
    assert(approxEqual(rng.front, 3.14));
    rng.popFront;
    assert(approxEqual(rng.front, 2.71));
    rng.popFront;
    assert(approxEqual(rng.front, 8.67));
    rng.popFront;
    assert(approxEqual(rng.front, 362435));
    assert(!rng.empty);
    rng.popFront;
    assert(rng.empty);
    rng.close;  // Normally this would be reference counted.
    writeln("Passed NumericFile unittest.");
}

// Verify that there are no TempAlloc memory leaks anywhere in the code covered
// by the unittest.  This should always be the last unittest of the module.
unittest {
    auto TAState = TempAlloc.getState;
    assert(TAState.used == 0);
    assert(TAState.nblocks < 2);
}
