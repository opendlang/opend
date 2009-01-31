/**Relatively low-level primitives on which to build higher-level math/stat
 * functionality.  Some are used internally, some are just things that may be
 * useful to users of this library.
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

module dstats.base;

public import std.math, std.traits, dstats.gamma, dstats.alloc;
private import dstats.sort, std.c.stdlib, std.bigint,
               std.functional, std.algorithm;

invariant real[] staticLogFacTable;

enum : size_t {
    staticFacTableLen = 10_000,
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

static this() {
    // Allocating on heap instead of static data segment to avoid
    // false pointer GC issues.
    real[] sfTemp = new real[staticFacTableLen];
    sfTemp[0] = 0;
    for(uint i = 1; i < staticFacTableLen; i++) {
        sfTemp[i] = sfTemp[i - 1] + log(i);
    }
    staticLogFacTable = cast(invariant) sfTemp;
}

version(unittest) {
    import std.stdio, std.algorithm, std.random;

    Random gen;

    void main (){
        gen.seed(unpredictableSeed);
    }
}

/**Bins data into nbin equal width bins, indexed from
 * 0 to nbin - 1, with 0 being the smallest bin, etc.
 * The values returned are the counts for each bin.  Returns results on the GC
 * heap by default, but uses TempAlloc stack if alloc == Alloc.STACK.*/
Ret[] binCounts(Ret = ushort, T)(const T[] data, uint nbin, Alloc alloc = Alloc.HEAP)
in {
    assert(data.length > 0);
    assert(nbin > 0);
} body {
    T min = data[0], max = data[0];
    foreach(elem; data[1..$]) {
        if(elem > max)
            max = elem;
        else if(elem < min)
            min = elem;
    }
    T range = max - min;

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
 * The values returned are the bin index for each element.  Returns on GC
 * heap by default, but TempAlloc stack if alloc == Alloc.STACK.*/
Ret[] bin(Ret = ushort, T)(const T[] data, uint nbin, Alloc alloc = Alloc.HEAP)
in {
    assert(data.length > 0);
    assert(nbin > 0);
} body {
    Mutable!(T) min = data[0], max = data[0];
    foreach(elem; data[1..$]) {
        if(elem > max)
            max = elem;
        else if(elem < min)
            min = elem;
    }
    T range = max - min;

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
    assert(res == [cast(ushort) 0, 0, 0, 0, 1, 3, 5, 7, 8, 9]);
    res = bin(data, 10, Alloc.STACK);
    assert(res == [cast(ushort) 0, 0, 0, 0, 1, 3, 5, 7, 8, 9]);
    TempAlloc.free;
    writeln("Passed bin unittest.");
}

/**Bins data into nbin equal frequency bins, indexed from
 * 0 to nbin - 1, with 0 being the smallest bin, etc.
 * The values returned are the bin index for each element.  Returns on GC
 * heap by default, but TempAlloc stack if alloc == Alloc.STACK.*/
Ret[] frqBin(Ret = ushort, T)(const T[] data, uint nbin, Alloc alloc = Alloc.HEAP)
in {
    assert(data.length > 0);
    assert(nbin > 0);
    assert(nbin <= data.length);
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
    auto dd = data.tempdup;
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
    assert(res == [cast(ushort) 0, 0, 0, 1, 2, 2, 1]);
    data = [3, 1, 4, 1, 5, 9, 2, 6, 5];
    res = frqBin(data, 4, Alloc.STACK);
    assert(res == [cast(ushort) 1, 0, 1, 0, 2, 3, 0, 3, 2]);
    data = [3U, 1, 4, 1, 5, 9, 2, 6, 5, 3, 4, 8, 9, 7, 9, 2];
    res = frqBin(data, 4);
    assert(res == [cast(ushort) 1, 0, 1, 0, 2, 3, 0, 2, 2, 1, 1, 3, 3, 2, 3, 0]);
    TempAlloc.free;
    writeln("Passed frqBin unittest.");
}

/**Generates a sequence from [start..end] by increment.  Includes start,
 * excludes end.
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
    writeln(stderr, "Passed seq test.");
}

/**Given an input array, outputs an array containing the rank from
 * [1, input.length] corresponding to each element.  Ties are dealt with by
 * averaging.  This function duplicates the input array, and does not reorder
 * it.  Return type is float[] by default, but if you are sure you have no ties,
 * ints can be used for efficiency, and if you need more precision when
 * averaging ties, you can use double or real.
 *
 * Examples:
 * ---
 * uint[] test = [3, 5, 3, 1, 2];
 * assert(rank(test) == [3.5f, 5f, 3.5f, 1f, 2f]);
 * assert(test == [3U, 5, 3, 1, 2]);
 * ---*/
Ret[] rank(Ret = float, T)(const T[] input) {
    auto iDup = input.tempdup;
    scope(exit) TempAlloc.free;
    return rankSort!(Ret)(iDup);
}

/**Same as rank(), but sorts the input array in ascending order rather than
 * duping it and working on a copy.  The array returned will still be
 * identical to that returned by rank(), i.e. the rank of each element will
 * correspond to the ranks of the elements in the input array before sorting.
 *
 * Examples:
 * ---
 * uint[] test = [3, 5, 3, 1, 2];
 * assert(rank(test) == [3.5f, 5f, 3.5f, 1f, 2f]);
 * assert(test == [1U, 2, 3, 4, 5]);
 * ---*/
Ret[] rankSort(Ret = float, T)(T[] input) {
    Ret[] ranks = newVoid!(Ret)(input.length);
    rankSort!(Ret, T)(input, ranks);
    return ranks;
}

// Speed hack used internally.
void rankSort(Ret, T)(T[] input, Ret[] ranks) {
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
    writeln(stderr, "Passed rank test.");
}

// Used internally by rank().
void averageTies(T, U)(T[] sortedInput, U[] ranks, uint[] perms) nothrow
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

/**Returns an AA of counts of every element in input.
 *
 * Examples:
 * ---
 * int[] foo = [1,2,3,1,2,4];
 * uint[int] frq = frequency(foo);
 * assert(frq.length == 4);
 * assert(frq[1] == 2);
 * assert(frq[4] == 1);
 * ---*/
uint[T] frequency(T)(const T[] input) pure nothrow {
    uint[T] output;
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

unittest {
    uint[int] temp=frequency([1,2,2,1,2]);
    assert(temp[1]==2);
    assert(temp[2]==3);
    writefln("Passed frequency unittest.");
}

///
int sign(T)(T num) pure nothrow {
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

///No, nothing this horribly inefficient is used internally.
BigInt factorial(uint N) {
    BigInt result = 1;
    for(uint i = 2; i <= N; i++) {
        result *= i;
    }
    return result;
}

unittest {
    assert(factorial(4) == 24);
    assert(factorial(5) == 120);
    assert(factorial(6) == 720);
    assert(factorial(7) == 5040);
    assert(factorial(3) == 6);
    writefln("Passed factorial test.");
}

/**A struct that generates all possible permutations of a sequence,
 * and can be iterated over with foreach.  Note that permutations are
 * output in undefined order.  Also note that the returned permutations
 * are references to the internal permutation state.  This is dangerous, but
 * necessary for performance.  Therefore, you
 * will have to dup them if you expect them not to change.
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
    /**Generate a sequence of seq(0, length) to permute based on.
     * Exists only if T == uint.*/
    static if(is(T == uint)) {
        this(uint length) {
            perm = (new uint[length]).ptr;
            foreach(i; 0..length) {
                perm[i] = i;
            }
            Is = (new size_t[length]).ptr;
            len = length;
        }
    }

    /**Use user-provided sequence.  Creates a duplicate of this sequence
     * so that the original sequence is not modified.*/
    this(T[] input) {
        perm = input.dup.ptr;
        Is = (new size_t[input.length]).ptr;
        len = input.length;
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

unittest {
    double[][] res;
    alias Perm!(double) PermD;
    auto perm = PermD(cast(double[]) [1.0, 2.0, 3.0]);
    foreach(p; perm) {
        res ~= p.dup;
    }
    assert(res.canFind([1.0, 2.0, 3.0]));
    assert(res.canFind([1.0, 3.0, 2.0]));
    assert(res.canFind([2.0, 1.0, 3.0]));
    assert(res.canFind([2.0, 3.0, 1.0]));
    assert(res.canFind([3.0, 1.0, 2.0]));
    assert(res.canFind([3.0, 2.0, 1.0]));
    assert(res.length == 6);
    uint[][] res2;
    alias Perm!(uint) PermU;
    auto perm2 = PermU(3);
    foreach(p; perm2) {
        res2 ~= p.dup;
    }
    assert(res2.canFind([0u, 1, 2]));
    assert(res2.canFind([0u, 2, 1]));
    assert(res2.canFind([1u, 0, 2]));
    assert(res2.canFind([1u, 2, 0]));
    assert(res2.canFind([2u, 0, 1]));
    assert(res2.canFind([2u, 1, 0]));
    assert(res2.length == 6);

    // Indirect tests:  If the elements returned are unique, there are N! of
    // them, and they contain what they're supposed to contain, the result is
    // correct.
    auto perm3 = PermU(6);
    bool[uint[]] table;
    foreach(p; perm3) {
        table[p.dup] = true;
    }
    assert(table.length == 720);
    foreach(elem, val; table) {
        assert(elem.dup.insertionSort == [0U, 1, 2, 3, 4, 5]);
    }
    auto perm4 = PermU(5);
    bool[uint[]] table2;
    foreach(p; perm4) {
        table2[p.dup] = true;
    }
    assert(table2.length == 120);
    foreach(elem, val; table2) {
        assert(elem.dup.insertionSort == [0U, 1, 2, 3, 4]);
    }
    writeln(stderr, "Passed Perm test.");
}

/**Generates every possible combination of r elements of the given sequence, or r
 * array indices from zero to N, depending on which ctor is called.  These can
 * be iterated over with a foreach loop.  Note that the combinations returned
 * are const references to the internal state of the Comb object.  This is
 * dangerous but necessary for performance.  If you want to save them past the
 * next  iteration, you'll have to dup them yourself.
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

    // Now, test the array version.
    auto comb2 = Comb!(uint)(seq(5U, 10U), 3);
    vals = null;
    foreach(c; comb2) {
        vals ~= c.dup;
    }
    assert(vals.canFind([5u, 6, 7].dup));
    assert(vals.canFind([5u, 6, 8].dup));
    assert(vals.canFind([5u, 6, 9].dup));
    assert(vals.canFind([5u, 7, 8].dup));
    assert(vals.canFind([5u, 7, 9].dup));
    assert(vals.canFind([5u, 8, 9].dup));
    assert(vals.canFind([6U, 7, 8].dup));
    assert(vals.canFind([6u, 7, 9].dup));
    assert(vals.canFind([6u, 8, 9].dup));
    assert(vals.canFind([7u, 8, 9].dup));
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

/* A hash table that uses TempAlloc to allocate space.  Useful for building
 * a quick symbol table in a performance-critical function that can't be
 * performing tons of heap allocations.  Intentionally lacking ddoc because
 * the design or even existence of this is still likely to change.*/
struct StackHash(K, V) {
private:
    struct Node {
        Node* next;
        K key;
        V val;
    }

    Node[] roots;
    TempAlloc.State TAState;
    TypeInfo keyTI;
    size_t _length;
    Node* usedSentinel;

    Node* newNode(K key) {
        Node* ret = cast(Node*) TempAlloc(Node.sizeof, TAState);
        ret.key = key;
        ret.val = V.init;
        ret.next = null;
        return ret;
    }

    Node* newNode(K key, V val) {
        Node* ret = cast(Node*) TempAlloc(Node.sizeof, TAState);
        ret.key = key;
        ret.val = val;
        ret.next = null;
        return ret;
    }

    hash_t getHash(K key) {
        static if(is(K : long) && K.sizeof <= hash_t.sizeof) {
            hash_t hash = cast(hash_t) key;
        } else static if(__traits(compiles, key.toHash())) {
            hash_t hash = key.toHash();
        } else {
            hash_t hash = keyTI.getHash(&key);
        }
        hash %= roots.length;
        return hash;
    }


public:
    this(size_t nElem) {
        // Obviously, the caller can never mean zero, because this struct
        // can't work at all with nElem == 0, so assume it's a mistake and fix
        // it here.
        if(nElem == 0)
            nElem++;
        TAState = TempAlloc.getState;
        roots = newStack!(Node)(nElem, TAState);
        usedSentinel = cast(Node*) roots.ptr;
        foreach(ref root; roots) {
            root.key = K.init;
            root.val = V.init;
            root.next = usedSentinel;
        }
        keyTI = typeid(K);
    }

    ref V opIndex(K key) {
        hash_t hash = getHash(key);

        if(roots[hash].next == usedSentinel) {
            roots[hash].key = key;
            roots[hash].next = null;
            _length++;
            return roots[hash].val;
        } else if(roots[hash].key == key) {
            return roots[hash].val;
        } else {  // Collision.  Start chaining.
            Node** next = &(roots[hash].next);
            while(*next !is null) {
                if((**next).key == key) {
                    return (**next).val;
                }
                next = &((**next).next);
            }
            *next = newNode(key);
            _length++;
            return (**next).val;
        }
    }

    V opIndexAssign(V val, K key) {
        hash_t hash = getHash(key);

        if(roots[hash].next == usedSentinel) {
            roots[hash].key = key;
            roots[hash].val = val;
            roots[hash].next = null;
            _length++;
            return val;
        } else if(roots[hash].key == key) {
            roots[hash].val = val;
            return val;
        } else {  // Collision.  Start chaining.
            Node** next = &(roots[hash].next);
            while(*next !is null) {
                if((**next).key == key) {
                    (**next).val = val;
                    return val;
                }
                next = &((**next).next);
            }
            _length++;
            *next = newNode(key, val);
            return val;
        }
    }

    V[] values() {
        auto space = newVoid!(V)(_length);
        return values(space);
    }

    V[] valStack() {
        auto space = newStack!(V)(_length);
        return values(space);
    }

    V[] values(V[] space) {
        size_t pos;
        foreach(r; roots) {
            if(r.next == usedSentinel)
                continue;
            space[pos++] = r.val;
            Node* next = r.next;
            while(next !is null) {
                space[pos++] = next.val;
                next = next.next;
            }
        }
        return space;
    }

    K[] keys() {
        auto space = newVoid!(K)(_length);
        return keys(space);
    }

    K[] keyStack() {
        auto space = newStack!(K)(_length);
        return keys(space);
    }

    K[] keys(K[] space) {
        size_t pos;
        foreach(r; roots) {
            if(r.next == usedSentinel)
                continue;
            space[pos++] = r.key;
            Node* next = r.next;
            while(next !is null) {
                space[pos++] = next.key;
                next = next.next;
            }
        }
        return space;
    }

    int opApply(int delegate(ref V value) dg) {
        int res = 0;
        outer:
        foreach(r; roots) {
            if(r.next == usedSentinel)
                continue;
            res = dg(r.val);
            if (res) break;
            Node* next = r.next;
            while(next !is null) {
                res = dg(next.val);
                if(res) break outer;
                next = next.next;
            }
        }
        return res;
   }

   int opApply(int delegate(ref K key, ref V value) dg) {
        int res = 0;
        outer:
        foreach(r; roots) {
            if(r.next == usedSentinel)
                continue;
            res = dg(r.key, r.val);
            if (res) break;
            Node* next = r.next;
            while(next !is null) {
                res = dg(next.key, next.val);
                if(res) break outer;
                next = next.next;
            }
        }
        return res;
   }

   V* opIn_r(K key) {
        hash_t hash = getHash(key);

        if(roots[hash].next == usedSentinel) {
            return null;
        } else if(roots[hash].key == key) {
            return &(roots[hash].val);
        } else {  // Collision.  Start chaining.
            Node* next = roots[hash].next;
            while(next !is null) {
                if(next.key == key) {
                    return &(next.val);
                }
                next = next.next;
            }
            return null;
        }
   }

   void remove(K key) {
        hash_t hash = getHash(key);

        Node** next = &(roots[hash].next);
        if(roots[hash].next == usedSentinel) {
            return;
        } else if(roots[hash].key == key) {
            _length--;
            if(roots[hash].next is null) {
                roots[hash].key = K.init;
                roots[hash].val = V.init;
                roots[hash].next = usedSentinel;
                return;
            } else {
                roots[hash].key = (**next).key;
                roots[hash].val = (**next).val;
                roots[hash].next = (**next).next;
                return;
            }
        } else {  // Collision.  Start chaining.
            while(*next !is null) {
                if((**next).key == key) {
                    _length--;
                    *next = (**next).next;
                    break;
                }
                next = &((**next).next);
            }
            return;
        }
   }

   size_t length() {
       return _length;
   }

   real efficiency() {
       uint used = 0;
       foreach(root; roots) {
           if(root.next != usedSentinel) {
               used++;
           }
       }
       return cast(real) used / roots.length;
   }
}

unittest {
    alias StackHash!(string, uint) mySh;
    mixin(newFrame);
    auto data = mySh(2);  // Make sure we get some collisions.
    data["foo"] = 1;
    data["bar"] = 2;
    data["baz"] = 3;
    data["waldo"] = 4;
    assert(!("foobar" in data));
    assert(*("foo" in data) == 1);
    assert(*("bar" in data) == 2);
    assert(*("baz" in data) == 3);
    assert(*("waldo" in data) == 4);
    assert(data["foo"] == 1);
    assert(data["bar"] == 2);
    assert(data["baz"] == 3);
    assert(data["waldo"] == 4);
    assert(data.keys.sort == ["bar", "baz", "foo", "waldo"]);
    assert(data.values.sort == [1U, 2, 3, 4]);
    foreach(k, v; data) {
        assert(data[k] == v);
    }
    foreach(v; data) {
        assert(v > 0 && v < 5);
    }

    // Test remove.

    alias StackHash!(uint, uint) mySh2;
    auto foo = mySh2(7);
    for(uint i = 0; i < 20; i++) {
        foo[i] = i;
    }
    assert(foo.length == 20);
    for(uint i = 0; i < 20; i += 2) {
        foo.remove(i);
    }
    for(uint i = 0; i < 20; i++) {
        if(i & 1) {
            assert(*(i in foo) == i);
        } else {
            assert(!(i in foo));
        }
    }
    auto vals = foo.values;
    assert(foo.length == 10);
    assert(vals.qsort == [1U, 3, 5, 7, 9, 11, 13, 15, 17, 19]);

    writeln("Passed StackHash test.");
}

/* A hash set that uses TempAlloc to allocate space.  Useful for building
 * a quick set in a performance-critical function that can't be
 * performing tons of heap allocations.  Intentionally lacking ddoc because
 * the design or even existence of this is still likely to change.*/
struct StackSet(K) {
private:
    // Choose smallest representation of the data.
    struct Node1 {
        Node1* next;
        K key;
    }

    struct Node2 {
        K key;
        Node2* next;
    }

    static if(Node1.sizeof < Node2.sizeof) {
        alias Node1 Node;
    } else {
        alias Node2 Node;
    }

    Node[] roots;
    TempAlloc.State TAState;
    TypeInfo keyTI;
    size_t _length;
    Node* usedSentinel;

    Node* newNode(K key) {
        Node* ret = cast(Node*) TempAlloc(Node.sizeof, TAState);
        ret.key = key;
        ret.next = null;
        return ret;
    }

    hash_t getHash(K key) {
        static if(is(K : long) && K.sizeof <= hash_t.sizeof) {
            hash_t hash = cast(hash_t) key;
        } else static if(__traits(compiles, key.toHash())) {
            hash_t hash = key.toHash();
        } else {
            hash_t hash = keyTI.getHash(&key);
        }
        hash %= roots.length;
        return hash;
    }

public:
    this(size_t nElem) {
        // Obviously, the caller can never mean zero, because this struct
        // can't work at all with nElem == 0, so assume it's a mistake and fix
        // it here.
        if(nElem == 0)
            nElem++;
        TAState = TempAlloc.getState;
        roots = newStack!(Node)(nElem, TAState);
        usedSentinel = cast(Node*) roots.ptr;
        foreach(ref root; roots) {
            root.key = K.init;
            root.next = usedSentinel;
        }
        keyTI = typeid(K);
    }

    void insert(K key) {
        hash_t hash = getHash(key);

        if(roots[hash].next == usedSentinel) {
            roots[hash].key = key;
            roots[hash].next = null;
            _length++;
            return;
        } else if(roots[hash].key == key) {
            return;
        } else {  // Collision.  Start chaining.
            Node** next = &(roots[hash].next);
            while(*next !is null) {
                if((**next).key == key) {
                    return;
                }
                next = &((**next).next);
            }
            *next = newNode(key);
            _length++;
            return;
        }
    }

    K[] elems() {
        auto space = newVoid!(K)(_length);
        return elems(space);
    }

    K[] elemStack() {
        auto space = newStack!(K)(_length);
        return elems(space);
    }

    K[] elems(K[] space) {
        size_t pos;
        foreach(r; roots) {
            if(r.next == usedSentinel)
                continue;
            space[pos++] = r.key;
            Node* next = r.next;
            while(next !is null) {
                space[pos++] = next.key;
                next = next.next;
            }
        }
        return space;
    }

   int opApply(int delegate(ref K key) dg) {
        int res = 0;
        outer:
        foreach(r; roots) {
            if(r.next == usedSentinel)
                continue;
            res = dg(r.key);
            if (res) break;
            Node* next = r.next;
            while(next !is null) {
                res = dg(next.key);
                if(res) break outer;
                next = next.next;
            }
        }
        return res;
   }

   bool opIn_r(K key) {
        hash_t hash = getHash(key);

        if(roots[hash].next == usedSentinel) {
            return false;
        } else if(roots[hash].key == key) {
            return true;
        } else {  // Collision.  Start chaining.
            Node* next = roots[hash].next;
            while(next !is null) {
                if(next.key == key) {
                    return true;
                }
                next = next.next;
            }
            return false;
        }
   }

   void remove(K key) {
        hash_t hash = getHash(key);

        Node** next = &(roots[hash].next);
        if(roots[hash].next == usedSentinel) {
            return;
        } else if(roots[hash].key == key) {
            _length--;
            if(roots[hash].next is null) {
                roots[hash].key = K.init;
                roots[hash].next = usedSentinel;
                return;
            } else {
                roots[hash].key = (**next).key;
                roots[hash].next = (**next).next;
                return;
            }
        } else {  // Collision.  Start chaining.
            while(*next !is null) {
                if((**next).key == key) {
                    _length--;
                    *next = (**next).next;
                    break;
                }
                next = &((**next).next);
            }
            return;
        }
   }

   size_t length() {
       return _length;
   }
}

unittest {
    mixin(newFrame);
    alias StackSet!(uint) mySS;
    mySS set = mySS(12);
    foreach(i; 0..20) {
        set.insert(i);
    }
    assert(set.elems.qsort == seq(0U, 20U));
    assert(set.elemStack.qsort == seq(0U, 20U));

    for(uint i = 0; i < 20; i += 2) {
        set.remove(i);
    }

    foreach(i; 0..20) {
        if(i & 1) {
            assert(i in set);
        } else {
            assert(!(i in set));
        }
    }
    uint[] contents;
    foreach(elem; set) {
        contents ~= elem;
    }
    assert(contents.qsort == [1U,3,5,7,9,11,13,15,17,19]);
    writeln("Passed StackSet test.");
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
    foreach(key, count; firstSet) {
        if(count > 0)
            result[pos++] = key;
    }

    return result[0..pos];
}

unittest {
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
    assert(intersectSorted([1,3,1,3,6,4,6].sort, [6,6,4,4,2,2,9,10].sort) == [4,6]);

    // We have two different methods, they shoouldn't be wrong in the same way.
    // Test one against the other.
    uint[] first = new uint[500];
    uint[] second = new uint[1000];
    foreach(i; 0..1000) {
        foreach(ref f; first)
            f = uniform(gen, 0U, 2500);
        foreach(ref s; second)
            s = uniform(gen, 0U, 5000);
        auto hash = qsort!("a > b")(intersect(first, second));
        auto sort = intersectSorted!("a > b")
                    (qsort!("a > b")(first), qsort!("a > b")(second));
        assert(hash == sort);
    }
    writeln("Passed intersect test.");
}

// Verify that there are no TempAlloc memory leaks anywhere in the code covered
// by the unittest.  This should always be the last unittest of the module.
unittest {
    auto TAState = TempAlloc.getState;
    assert(TAState.used == 0);
    assert(TAState.nblocks < 2);
}
