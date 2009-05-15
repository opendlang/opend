/**A comprehensive sorting library for statistical functions.  Each function
 * takes N arguments, which are arrays or array-like objects, sorts the first
 * and sorts the rest in lockstep.  For merge and insertion sort, if the last
 * argument is a ulong*, increments the dereference of this ulong* by the bubble
 * sort distance between the first argument and the sorted version of the first
 * argument.  This is useful for some statistical calculations.
 *
 * All sorting functions have the precondition that all parallel input arrays
 * must have the same length.
 *
 * Note:  These functions only work with arrays and ranges very similar to
 * arrays.  This will likely remain the case for the foreseeable future because
 * they were heavily optimized specifically for arrays before ranges existed.
 * Furthermore, every internal use for them occurs after data has been copied
 * from generic ranges to arrays.
 *
 * Examples:
 * ---
 * auto foo = [3, 1, 2, 4, 5].dup;
 * auto bar = [8, 6, 7, 5, 3].dup;
 * qsort(foo, bar);
 * assert(foo == [1, 2, 3, 4, 5]);
 * assert(bar == [6, 7, 8, 5, 3]);
 * auto baz = [1.0, 0, -1, -2, -3].dup;
 * mergeSort!("a > b")(bar, foo, baz);
 * assert(bar == [8, 7, 6, 5, 3]);
 * assert(foo == [3, 2, 1, 4, 5]);
 * assert(baz == [-1.0, 0, 1, -2, -3]);
 * ---
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

module dstats.sort;

import std.traits, std.algorithm, std.math, std.functional, std.math,
       std.typetuple, std.range, std.array;

import dstats.alloc;

version(unittest) {
    import std.stdio, std.random;

    void main (){
    }
}

void rotateLeft(T)(T input)
if(isRandomAccessRange!(T)) {
    if(input.length < 2) return;
    ElementType!(T) temp = input[0];
    foreach(i; 1..input.length) {
        input[i-1] = input[i];
    }
    input[$-1] = temp;
}

void rotateRight(T)(T input)
if(isRandomAccessRange!(T)) {
    if(input.length < 2) return;
    ElementType!(T) temp = input[$-1];
    for(size_t i = input.length - 1; i > 0; i--) {
        input[i] = input[i-1];
    }
    input[0] = temp;
}

/**Less than, except a NAN is less than anything except another NAN. This
 * behavior is totally arbitrary, but something has to be done with NANs by default
 * to avoid totally breaking the sorting algorithms when they occur.*/
bool lessThan(T)(const T lhs, const T rhs) {
    static if(isFloatingPoint!(T)) {
        return ((lhs < rhs) || (isnan(lhs) && !isnan(rhs)));
    } else {
        return lhs < rhs;
    }
}

/**Greater than, except anything except another NAN > a NAN.  This behavior
 * is totally arbitrary, but something has to be done with NANs by default
 * to avoid totally breaking the sorting algorithms when they occur.*/
bool greaterThan(T)(const T lhs, const T rhs) {
    static if(isFloatingPoint!(T)) {
        return ((lhs > rhs) || !isnan(lhs) && isnan(rhs));
    } else {
        return lhs > rhs;
    }
}


/* Returns the index, NOT the value, of the median of the first, middle, last
 * elements of data.*/
size_t medianOf3(alias compFun, T)(const T[] data) {
    alias binaryFun!(compFun) comp;
    immutable size_t mid = data.length / 2;
    immutable uint result = ((cast(uint) (comp(data[0], data[mid]))) << 2) |
                            ((cast(uint) (comp(data[0], data[$ - 1]))) << 1) |
                            (cast(uint) (comp(data[mid], data[$ - 1])));

    assert(result != 2 && result != 5 && result < 8); // Cases 2, 5 can't happen.
    switch(result) {
        case 1:  // 001
        case 6:  // 110
            return data.length - 1;
        case 3:  // 011
        case 4:  // 100
            return 0;
        case 0:  // 000
        case 7:  // 111
            return mid;
    }
}

unittest {
    assert(medianOf3!(lessThan)([1,2,3,4,5]) == 2);
    assert(medianOf3!(lessThan)([1,2,5,4,3]) == 4);
    assert(medianOf3!(lessThan)([3,2,1,4,5]) == 0);
    assert(medianOf3!(lessThan)([5,2,3,4,1]) == 2);
    assert(medianOf3!(lessThan)([5,2,1,4,3]) == 4);
    assert(medianOf3!(lessThan)([3,2,5,4,1]) == 0);
    writeln("Passed medianOf3 unittest.");
}


/**Quick sort.  Unstable, O(N log N) time average, worst
 * case, O(log N) space, small constant term in time complexity.
 *
 * In this implementation, the following steps are taken to avoid the
 * O(N<sup>2</sup>) worst case of naive quick sorts:
 *
 * 1.  At each recursion, the median of the first, middle and last elements of
 *     the array is used as the pivot.
 *
 * 2.  To handle the case of few unique elements, the "Fit Pivot" technique
 *     previously decribed by Andrei Alexandrescu is used.  This allows
 *     reasonable performance with few unique elements, with zero overhead
 *     in other cases.
 *
 * 3.  After a much larger than expected amount of recursion has occured,
 *     this function transitions to a heap sort.  This guarantees an O(N log N)
 *     worst case.*/
T[0] qsort(alias compFun = lessThan, T...)(T data)
in {
    assert(data.length > 0);
    size_t len = data[0].length;
    foreach(array; data[1..$]) {
        assert(array.length == len);
    }
} body {
    // Because we transition to insertion sort at N = 50 elements,
    // using the ideal recursion depth to determine the transition point
    // to heap sort is reasonable.
    uint TTL = cast(uint) log2(cast(real) data[0].length);
    qsortImpl!(compFun)(data, TTL);
    return data[0];
}

//TTL = time to live, before transitioning to heap sort.
void qsortImpl(alias compFun, T...)(T data, uint TTL) {
    alias binaryFun!(compFun) comp;
    if(data[0].length < 50) {
         insertionSort!(compFun)(data);
         return;
    }
    if(TTL == 0) {
        heapSort!(compFun)(data);
        return;
    }
    TTL--;

    {
        immutable size_t med3 = medianOf3!(comp)(data[0]);
        foreach(array; data) {
            auto temp = array[med3];
            array[med3] = array[$ - 1];
            array[$ - 1] = temp;
        }
    }

    T less, greater;
    ptrdiff_t lessI = -1, greaterI = data[0].length - 1;

    auto pivot = data[0][$ - 1];
    while(true) {
        while(comp(data[0][++lessI], pivot)) {}
        while(greaterI > 0 && comp(pivot, data[0][--greaterI])) {}

        if(lessI < greaterI) {
            foreach(array; data) {
                auto temp = array[lessI];
                array[lessI] = array[greaterI];
                array[greaterI] = temp;
            }
        } else break;
    }

    foreach(ti, array; data) {
        auto temp = array[$ - 1];
        array[$ - 1] = array[lessI];
        array[lessI] = temp;
        less[ti] = array[0..min(lessI, greaterI + 1)];
        greater[ti] = array[lessI + 1..$];
    }
    // Allow tail recursion optimization for larger block.  This guarantees
    // that, given a reasonable amount of stack space, no stack overflow will
    // occur even in pathological cases.
    if(greater[0].length > less[0].length) {
        qsortImpl!(compFun)(less, TTL);
        qsortImpl!(compFun)(greater, TTL);
        return;
    }
    qsortImpl!(compFun)(greater, TTL);
    qsortImpl!(compFun)(less, TTL);
}

unittest {
    {  // Test integer.
        uint[] test = new uint[1_000];
        foreach(ref e; test) {
            e = uniform(0, 100);
        }
        auto test2 = test.dup;
        foreach(i; 0..1_000) {
            randomShuffle(zip(test, test2));
            uint len = uniform(0, 1_000);
            qsort(test[0..len], test2[0..len]);
            assert(isSorted(test[0..len]));
            assert(test == test2);
        }
    }
    { // Test float.
        double[] test = new double[1_000];
        foreach(ref e; test) {
            e = uniform(0.0, 100_000);
        }
        auto test2 = test.dup;
        foreach(i; 0..1_000) {
            randomShuffle(zip(test, test2));
            uint len = uniform(0, 1_000);
            qsort!("a > b")(test[0..len], test2[0..len]);
            assert(isSorted!("a > b")(test[0..len]));
            assert(test == test2);
        }
    }
    writeln("Passed qsort test.");
}

/* Keeps track of what array merge sort data is in.  This is a speed hack to
 * copy back and forth less.*/
private enum {
    DATA,
    TEMP
}

/**Merge sort.  O(N log N) time, O(N) space, small constant.  Stable sort.
 * If last argument is a ulong* instead of an array-like type,
 * the dereference of the ulong* will be incremented by the bubble sort
 * distance between the input array and the sorted version.  This is useful
 * in some statistics functions such as Kendall's tau.*/
T[0] mergeSort(alias compFun = lessThan, T...)(T data)
in {
    assert(data.length > 0);
    size_t len = data[0].length;
    foreach(array; data[1..$]) {
        static if(!is(typeof(array) == ulong*))
            assert(array.length == len);
    }
} body {
    if(data[0].length < 65) {  //Avoid mem allocation.
        return insertionSort!(compFun)(data);
    }
    static if(is(T[$ - 1] == ulong*)) {
        enum dl = data.length - 1;
        alias data[$ - 1] swapCount;
    } else {
        enum dl = data.length;
        alias TypeTuple!() swapCount; // Place holder.
    }

    auto stateCache = TempAlloc.getState;
    typeof(data[0..dl]) temp;
    foreach(i, array; temp) {
        temp[i] = newStack!(typeof(data[i][0]))(data[i].length, stateCache);
    }

    uint res = mergeSortImpl!(compFun)(data[0..dl], temp, swapCount);
    if(res == TEMP) {
        foreach(ti, array; temp) {
            data[ti][0..$] = temp[ti][0..$];
        }
    }

    foreach(array; temp) {
        TempAlloc.free(stateCache);
    }

    return data[0];
}

unittest {
    uint[] test = new uint[1_000], stability = new uint[1_000];
    uint[] temp1 = new uint[1_000], temp2 = new uint[1_000];
    foreach(ref e; test) {
        e = uniform(0, 100);  //Lots of ties.
    }
    foreach(i; 0..100) {
        ulong mergeCount = 0, bubbleCount = 0;
        foreach(j, ref e; stability) {
            e = j;
        }
        randomShuffle(test);
        uint len = uniform(0, 1_000);
        // Testing bubble sort distance against bubble sort,
        // since bubble sort distance computed by bubble sort
        // is straightforward, unlikely to contain any subtle bugs.
        bubbleSort(test[0..len].dup, &bubbleCount);
        if(i & 1)  // Test both temp and non-temp branches.
            mergeSort(test[0..len], stability[0..len], &mergeCount);
        else
            mergeSortTemp(test[0..len], stability[0..len], temp1[0..len],
                          temp2[0..len], &mergeCount);
        assert(bubbleCount == mergeCount);
        assert(isSorted(test[0..len]));
        foreach(j; 1..len) {
            if(test[j - 1] == test[j]) {
                assert(stability[j - 1] < stability[j]);
            }
        }
    }
    // Test without swapCounts.
    foreach(i; 0..1000) {
        foreach(j, ref e; stability) {
            e = j;
        }
        randomShuffle(test);
        uint len = uniform(0, 1_000);
        if(i & 1)  // Test both temp and non-temp branches.
            mergeSort(test[0..len], stability[0..len]);
        else
            mergeSortTemp(test[0..len], stability[0..len], temp1[0..len],
                          temp2[0..len]);
        assert(isSorted(test[0..len]));
        foreach(j; 1..len) {
            if(test[j - 1] == test[j]) {
                assert(stability[j - 1] < stability[j]);
            }
        }
    }
    { // Test lockstep.
        double[] testL = new double[1_000];
        foreach(ref e; testL) {
            e = uniform(0.0, 100_000);
        }
        auto testL2 = testL.dup;
        foreach(i; 0..1_000) {
            randomShuffle(zip(testL, testL2));
            uint len = uniform(0, 1_000);
            mergeSort!("a > b")(testL[0..len], testL2[0..len]);
            assert(isSorted!("a > b")(testL[0..len]));
            assert(testL == testL2);
        }
    }
    writeln("Passed mergeSort test.");
}

/**Merge sort, allowing caller to provide a temp variable.  This allows
 * recycling instead of repeated allocations.  If D is data, T is temp,
 * and U is a ulong* for calculating bubble sort distance, this can be called
 * as mergeSortTemp(D, D, D, T, T, T, U) or mergeSortTemp(D, D, D, T, T, T)
 * where each D has a T of corresponding type.
 *
 * Examples:
 * ---
 * int[] foo = [3, 1, 2, 4, 5].dup;
 * int[] temp = new uint[5];
 * mergeSortTemp!("a < b")(foo, temp);
 * assert(foo == [1, 2, 3, 4, 5]); // The contents of temp will be undefined.
 * foo = [3, 1, 2, 4, 5].dup;
 * real bar = [3.14L, 15.9, 26.5, 35.8, 97.9];
 * real temp2 = new real[5];
 * mergeSortTemp(foo, bar, temp, temp2);
 * assert(foo == [1, 2, 3, 4, 5]);
 * assert(bar == [15.9L, 26.5, 3.14, 35.8, 97.9]);
 * // The contents of both temp and temp2 will be undefined.
 * ---
 */
T[0] mergeSortTemp(alias compFun = lessThan, T...)(T data)
in {
    assert(data.length > 0);
    size_t len = data[0].length;
    foreach(array; data[1..$]) {
        static if(!is(typeof(array) == ulong*))
            assert(array.length == len);
    }
} body {
    static if(is(T[$ - 1] == ulong*)) {
        enum dl = data.length - 1;
    } else {
        enum dl = data.length;
    }
    uint res = mergeSortImpl!(compFun)(data);

    if(res == TEMP) {
        foreach(ti, array; data[0..$ / 2]) {
            data[ti][0..$] = data[ti + dl / 2][0..$];
        }
    }
    return data[0];
}

private uint mergeSortImpl(alias compFun = lessThan, T...)(T dataIn) {
    static if(is(T[$ - 1] == ulong*)) {
        alias dataIn[$ - 1] swapCount;
        alias dataIn[0..dataIn.length / 2] data;
        alias dataIn[dataIn.length / 2..$ - 1] temp;
    } else {  // Make empty dummy tuple.
        alias TypeTuple!() swapCount;
        alias dataIn[0..dataIn.length / 2] data;
        alias dataIn[dataIn.length / 2..$] temp;
    }

    if(data[0].length < 50) {
        insertionSort!(compFun)(data, swapCount);
        return DATA;
    }
    size_t half = data[0].length / 2;
    typeof(data) left, right, tempLeft, tempRight;
    foreach(ti, array; data) {
        left[ti] = array[0..half];
        right[ti] = array[half..$];
        tempLeft[ti] = temp[ti][0..half];
        tempRight[ti] = temp[ti][half..$];
    }

    /* Implementation note:  The lloc, rloc stuff is a hack to avoid constantly
     * copying data back and forth between the data and temp arrays.
     * Instad of copying every time, I keep track of which array the last merge
     * went into, and only copy at the end or if the two sides ended up in
     * different arrays.*/
    uint lloc = mergeSortImpl!(compFun)(left, tempLeft, swapCount);
    uint rloc = mergeSortImpl!(compFun)(right, tempRight, swapCount);
    if(lloc == DATA && rloc == TEMP) {
        foreach(ti, array; tempLeft) {
            array[] = left[ti][];
        }
        lloc = TEMP;
    } else if(lloc == TEMP && rloc == DATA) {
        foreach(ti, array; tempRight) {
            array[] = right[ti][];
        }
    }
    if(lloc == DATA) {
        merge!(compFun)(left, right, temp, swapCount);
        return TEMP;
    } else {
        merge!(compFun)(tempLeft, tempRight, data, swapCount);
        return DATA;
    }
}

private void merge(alias compFun, T...)(T data) {
    alias binaryFun!(compFun) comp;

    static if(is(T[$ - 1] == ulong*)) {
        enum dl = data.length - 1;  //Length after removing swapCount;
        alias data[$ - 1] swapCount;
    } else {
        enum dl = data.length;
    }

    static assert(dl % 3 == 0);
    alias data[0..dl / 3] left;
    alias  data[dl / 3..dl * 2 / 3] right;
    alias data[dl * 2 / 3..dl] result;
    static assert(left.length == right.length && right.length == result.length);
    size_t i = 0, l = 0, r = 0;
    while(l < left[0].length && r < right[0].length) {
        if(comp(right[0][r], left[0][l])) {

            static if(is(T[$ - 1] == ulong*)) {
                *swapCount += left[0].length - l;
            }

            foreach(ti, array; result) {
                result[ti][i] = right[ti][r];
            }
            r++;
        } else {
            foreach(ti, array; result) {
                result[ti][i] = left[ti][l];
            }
            l++;
        }
        i++;
    }
    if(right[0].length > r) {
        foreach(ti, array; result) {
            result[ti][i..$] = right[ti][r..$];
        }
    } else {
        foreach(ti, array; result) {
            result[ti][i..$] = left[ti][l..$];
        }
    }
}

/**In-place merge sort, based on C++ STL's stable_sort().  O(N log<sup>2</sup> N)
 * time complexity, O(1) space complexity, stable.  Much slower than plain
 * old mergeSort(), so only use it if you really need the O(1) space.*/
T[0] mergeSortInPlace(alias compFun = lessThan, T...)(T data)
in {
    assert(data.length > 0);
    size_t len = data[0].length;
    foreach(array; data[1..$]) {
        assert(array.length == len);
    }
} body {
    if (data[0].length <= 100)
        return insertionSort!(compFun)(data);

    T left, right;
    foreach(ti, array; data) {
        left[ti] = array[0..$ / 2];
        right[ti] = array[$ / 2..$];
    }

    mergeSortInPlace!(compFun, T)(right);
    mergeSortInPlace!(compFun, T)(left);
    mergeInPlace!(compFun)(data, data[0].length / 2);
    return data[0];
}

unittest {
    uint[] test = new uint[1_000], stability = new uint[1_000];
    foreach(ref e; test) {
        e = uniform(0, 100);  //Lots of ties.
    }
    uint[] test2 = test.dup;
    foreach(i; 0..1000) {
        foreach(j, ref e; stability) {
            e = j;
        }
        randomShuffle(zip(test, test2));
        uint len = uniform(0, 1_000);
        mergeSortInPlace(test[0..len], test2[0..len], stability[0..len]);
        assert(isSorted(test[0..len]));
        assert(test == test2);
        foreach(j; 1..len) {
            if(test[j - 1] == test[j]) {
                assert(stability[j - 1] < stability[j]);
            }
        }
    }
    writeln("Passed mergeSortInPlace test.");
}

// Loosely based on C++ STL's __merge_without_buffer().
private void mergeInPlace(alias compFun = lessThan, T...)(T data, size_t middle) {
    static size_t largestLess(alias compFun, T)(T[] data, T value) {
        alias binaryFun!(compFun) comp;
        size_t len = data.length, first, last = data.length, half, middle;

        while (len > 0) {
            half = len / 2;
            middle = first + half;
            if (comp(data[middle], value)) {
                first = middle + 1;
                len = len - half - 1;
            } else
                len = half;
        }
        return first;
    }

    static size_t smallestGr(alias compFun, T)(T[] data, T value) {
        alias binaryFun!(compFun) comp;
        size_t len = data.length, first, last = data.length, half, middle;

        while (len > 0) {
            half = len / 2;
            middle = first + half;
            if (comp(value, data[middle]))
                len = half;
            else {
                first = middle + 1;
                len = len - half - 1;
            }
        }
        return first;
    }


    alias binaryFun!(compFun) comp;
    if (data[0].length < 2 || middle == 0 || middle == data[0].length)
        return;
    if (data[0].length == 2) {
        if(comp(data[0][1], data[0][0])) {
            foreach(array; data) {
                auto temp = array[0];
                array[0] = array[1];
                array[1] = temp;
            }
        }
        return;
    }

    size_t half1, half2, firstCut, secondCut;

    if (middle > data[0].length - middle) {
        half1 = middle / 2;
        auto pivot = data[0][half1];
        half2 = largestLess!(compFun)(data[0][middle..$], pivot);
    } else {
        half2 = (data[0].length - middle) / 2;
        auto pivot = data[0][half2 + middle];
        half1 = smallestGr!(compFun)(data[0][0..middle], pivot);
    }

    foreach(array; data) {
        bringToFront(array[half1..middle], array[middle..middle + half2]);
    }
    size_t newMiddle = half1 + half2;

    T left, right;
    foreach(ti, array; data) {
        left[ti] = array[0..newMiddle];
        right[ti] = array[newMiddle..$];
    }

    mergeInPlace!(compFun, T)(left, half1);
    mergeInPlace!(compFun, T)(right, half2 + middle - newMiddle);
}


/**Heap sort.  Unstable, O(N log N) time average and worst case, O(1) space,
 * large constant term in time complexity.*/
T[0] heapSort(alias compFun = lessThan, T...)(T input)
in {
    assert(input.length > 0);
    size_t len = input[0].length;
    foreach(array; input[1..$]) {
        assert(array.length == len);
    }
} body {
    // Heap sort has such a huge constant that insertion sort's faster for N <
    // 100 (for reals, even larger for smaller types).
    if(input[0].length <= 100) {
        return insertionSort!(compFun)(input);
    }

    alias binaryFun!(compFun) comp;
    if(input[0].length < 2) return input[0];
    makeMultiHeap!(compFun)(input);
    for(size_t end = input[0].length - 1; end > 0; end--) {
        foreach(ti, ia; input) {
            auto temp = ia[end];
            ia[end] = ia[0];
            ia[0] = temp;
        }
        multiSiftDown!(compFun)(input, 0, end);
    }
    return input[0];
}

unittest {
    uint[] test = new uint[1_000];
    foreach(ref e; test) {
        e = uniform(0, 100_000);
    }
    auto test2 = test.dup;
    foreach(i; 0..1_000) {
        randomShuffle(zip(test, test2));
        uint len = uniform(0, 1_000);
        heapSort(test[0..len], test2[0..len]);
        assert(isSorted(test[0..len]));
        assert(test == test2);
    }
    writeln("Passed heapSort test.");
}

void makeMultiHeap(alias compFun = lessThan, T...)(T input) {
    if(input[0].length < 2)
        return;
    alias binaryFun!(compFun) comp;
    for(int start = (input[0].length - 1) / 2; start >= 0; start--) {
        multiSiftDown!(compFun)(input, start, input[0].length);
    }
}

void multiSiftDown(alias compFun = lessThan, T...)
     (T input, size_t root, size_t end) {
    alias binaryFun!(compFun) comp;
    alias input[0] a;
    while(root * 2 + 1 < end) {
        size_t child = root * 2 + 1;
        if(child + 1 < end && comp(a[child], a[child + 1])) {
            child++;
        }
        if(comp(a[root], a[child])) {
            foreach(ia; input) {
                auto temp = ia[root];
                ia[root] = ia[child];
                ia[child] = temp;
            }
            root = child;
        }
        else return;
    }
}

/**Insertion sort.  O(N<sup>2</sup>) time worst, average case, O(1) space, VERY
 * small constant, which is why it's useful for sorting small subarrays in
 * divide and conquer algorithms.  If last argument is a ulong*, increments
 * the dereference of this argument by the bubble sort distance between the
 * input array and the sorted version of the input.*/
T[0] insertionSort(alias compFun = lessThan, T...)(T data)
in {
    assert(data.length > 0);
    size_t len = data[0].length;
    foreach(array; data[1..$]) {
        static if(!is(typeof(array) == ulong*))
            assert(array.length == len);
    }
} body {
    alias binaryFun!(compFun) comp;
    static if(is(T[$ - 1] == ulong*)) enum dl = data.length - 1;
    else enum dl = data.length;
    if(data[0].length < 2) {return data[0];}
    foreach_reverse(i; 0..data[0].length - 1) {
        size_t j = i;
        auto val = data[0][i];
        for(; j < data[0].length - 1; j++) {
            if(!comp(data[0][j + 1], val)) {
                break;
            }
            data[0][j] = data[0][j + 1];
        }
        data[0][j] = val;
        foreach(array; data[1..dl]) rotateLeft(array[i..j + 1]);
        static if(is(T[$ - 1] == ulong*)) {
            (*(data[$-1])) += (j - i);  //Increment swapCount variable.
        }
    }
    return data[0];
}

unittest {
    uint[] test = new uint[100], stability = new uint[100];
    foreach(ref e; test) {
        e = uniform(0, 100);  //Lots of ties.
    }
    foreach(i; 0..1_000) {
        ulong insertCount = 0, bubbleCount = 0;
        foreach(j, ref e; stability) {
            e = j;
        }
        randomShuffle(test);
        uint len = uniform(0, 100);
        // Testing bubble sort distance against bubble sort,
        // since bubble sort distance computed by bubble sort
        // is straightforward, unlikely to contain any subtle bugs.
        bubbleSort(test[0..len].dup, &bubbleCount);
        insertionSort(test[0..len], stability[0..len], &insertCount);
        assert(bubbleCount == insertCount);
        assert(isSorted(test[0..len]));
        foreach(j; 1..len) {
            if(test[j - 1] == test[j]) {
                assert(stability[j - 1] < stability[j]);
            }
        }
    }
    writeln("Passed insertionSort test.");
}

// Kept around only because it's easy to implement, and therefore good for
// testing more complex sort functions against.  Especially useful for bubble
// sort distance, since it's straightforward with a bubble sort, and not with
// a merge sort or insertion sort.
version(unittest) {
    T[0] bubbleSort(alias compFun = lessThan, T...)(T data) {
        alias binaryFun!(compFun) comp;
        static if(is(T[$ - 1] == ulong*))
            enum dl = data.length - 1;
        else enum dl = data.length;
        if(data[0].length < 2)
            return data[0];
        bool swapExecuted;
        foreach(i; 0..data[0].length) {
            swapExecuted = false;
            foreach(j; 1..data[0].length) {
                if(comp(data[0][j], data[0][j - 1])) {
                    swapExecuted = true;
                    static if(is(T[$ - 1] == ulong*))
                        (*(data[$-1]))++;
                    foreach(array; data[0..dl])
                        swap(array[j-1], array[j]);
                }
            }
            if(!swapExecuted) return data[0];
        }
        return data[0];
    }
}

unittest {
    //Sanity check for bubble sort distance.
    uint[] test = [4, 5, 3, 2, 1];
    ulong dist = 0;
    bubbleSort(test, &dist);
    assert(dist == 9);
    dist = 0;
    test = [6, 1, 2, 4, 5, 3];
    bubbleSort(test, &dist);
    assert(dist == 7);
    writeln("Passed bubbleSort test.");
}

/**Returns the kth largest/smallest element (depending on compFun, 0-indexed)
 * in the input array in O(N) time.  Allocates memory, does not modify input
 * array.*/
T quickSelect(alias compFun = lessThan, T)(const T[] data, int k)
in {
    assert(data.length > 0);
    size_t len = data[0].length;
    foreach(array; data[1..$]) {
        assert(array.length == len);
    }
} body {
    auto TAState = TempAlloc.getState;
    auto dataDup = data.tempdup(TAState);  scope(exit) TempAlloc.free(TAState);
    return partitionK!(compFun, T)(dataDup, k);
}

/**Partitions the input data according to compFun, such that position k contains
 * the kth largest/smallest element according to compFun.  For all elements e
 * with indices < k, !compFun(data[k], e) is guaranteed to be true.  For all
 * elements e with indices > k, !compFun(e, data[k]) is guaranteed to be true.
 * For example, if compFun is "a < b", all elements with indices < k will be
 * <= data[k], and all elements with indices larger than k will be >= k.
 * Reorders any additional input arrays in lockstep.
 *
 * Examples:
 * ---
 * auto foo = [3, 1, 5, 4, 2].dup;
 * auto secondSmallest = partitionK(foo, 1);
 * assert(secondSmallest == 2);
 * foreach(elem; foo[0..1]) {
 *     assert(elem <= foo[1]);
 * }
 * foreach(elem; foo[2..$]) {
 *     assert(elem >= foo[1]);
 * }
 * ---
 *
 * Returns:  The kth element of the array.
 */
ArrayElemType!(T[0]) partitionK(alias compFun = lessThan, T...)(T data, int k)
in {
    assert(data.length > 0);
    size_t len = data[0].length;
    foreach(array; data[1..$]) {
        assert(array.length == len);
    }
} body {
    alias binaryFun!(compFun) comp;

    {
        immutable size_t med3 = medianOf3!(comp)(data[0]);
        foreach(array; data) {
            auto temp = array[med3];
            array[med3] = array[$ - 1];
            array[$ - 1] = temp;
        }
    }

    ptrdiff_t lessI = -1, greaterI = data[0].length - 1;
    auto pivot = data[0][$ - 1];
    while(true) {
        while(comp(data[0][++lessI], pivot)) {}
        while(greaterI > 0 && comp(pivot, data[0][--greaterI])) {}

        if(lessI < greaterI) {
            foreach(array; data) {
                auto temp = array[lessI];
                array[lessI] = array[greaterI];
                array[greaterI] = temp;
            }
        } else break;
    }
    foreach(array; data) {
        auto temp = array[lessI];
        array[lessI] = array[$ - 1];
        array[$ - 1] = temp;
    }

    if((greaterI < k && lessI >= k) || lessI == k) {
        return data[0][k];
    } else if(lessI < k) {
        foreach(ti, array; data) {
            data[ti] = array[lessI + 1..$];
        }
        return partitionK!(compFun, T)(data, k - lessI - 1);
    } else {
        foreach(ti, array; data) {
            data[ti] = array[0..min(greaterI + 1, lessI)];
        }
        return partitionK!(compFun, T)(data, k);
    }
}

template ArrayElemType(T : T[]) {
    alias T ArrayElemType;
}

unittest {
    enum n = 1000;
    uint[] test = new uint[n];
    uint[] test2 = new uint[n];
    uint[] lockstep = new uint[n];
    foreach(ref e; test) {
        e = uniform(0, 1000);
    }
    foreach(i; 0..1_000) {
        test2[] = test[];
        lockstep[] = test[];
        uint len = uniform(0, n - 1) + 1;
        qsort!("a > b")(test2[0..len]);
        int k = uniform(0, len);
        auto qsRes = partitionK!("a > b")(test[0..len], lockstep[0..len], k);
        assert(qsRes == test2[k]);
        foreach(elem; test[0..k]) {
            assert(elem >= test[k]);
        }
        foreach(elem; test[k + 1..len]) {
            assert(elem <= test[k]);
        }
        assert(test == lockstep);
    }
    writeln("Passed quickSelect/partitionK test.");
}

/**Given a set of data points entered through the put function, this output range
 * maintains the invariant that the top N according to compFun will be
 * contained in the data structure.  Uses a heap internally, O(log N) insertion
 * time.  Good for finding the largest/smallest N elements of a very large
 * dataset that cannot be sorted quickly in its entirety, and may not even fit
 * in memory. If less than N datapoints have been entered, all are contained in
 * the structure.
 *
 * Examples:
 * ---
 * Random gen;
 * gen.seed(unpredictableSeed);
 * uint[] nums = seq(0U, 100U);
 * auto less = TopN!(uint, "a < b")(10);
 * auto more = TopN!(uint, "a > b")(10);
 * randomShuffle(nums, gen);
 * foreach(n; nums) {
 *     less.put(n);
 *     more.put(n);
 * }
 *  assert(less.getSorted == [0U, 1,2,3,4,5,6,7,8,9]);
 *  assert(more.getSorted == [99U, 98, 97, 96, 95, 94, 93, 92, 91, 90]);
 *  ---
 */
struct TopN(T, alias compFun = greaterThan) {
private:
    alias binaryFun!(compFun) comp;
    uint n;
    uint nAdded;

    T[] nodes;
public:
    /** The variable ntop controls how many elements are retained.*/
    this(uint ntop) {
        n = ntop;
        nodes = new T[n];
    }

    /** Insert an element into the topN struct.*/
    void put(T elem) {
        if(nAdded < n) {
            nodes[nAdded] = elem;
            if(nAdded == n - 1) {
                makeMultiHeap!(comp)(nodes);
            }
            nAdded++;
        } else if(nAdded >= n) {
             if(comp(elem, nodes[0])) {
                nodes[0] = elem;
                multiSiftDown!(comp)(nodes, 0, nodes.length);
            }
        }
    }

    /**Get the elements currently in the struct.  Returns a reference to
     * internal state, elements will be in an arbitrary order.  Cheap.*/
    const(T)[] getElements() const {
        return nodes[0..min(n, nAdded)];
    }

    /**Returns the elements sorted by compFun.  The array returned is a
     * duplicate of the input array.  Not cheap.*/
    T[] getSorted() const {
        return qsort!(comp)(nodes[0..min(n, nAdded)].dup);
    }
}

unittest {
    alias TopN!(uint, "a < b") TopNLess;
    alias TopN!(uint, "a > b") TopNGreater;
    Random gen;
    gen.seed(unpredictableSeed);
    uint[] nums = new uint[100];
    foreach(i, ref n; nums) {
        n = i;
    }
    foreach(i; 0..100) {
        auto less = TopNLess(10);
        auto more = TopNGreater(10);
        randomShuffle(nums, gen);
        foreach(n; nums) {
            less.put(n);
            more.put(n);
        }
        assert(less.getSorted == [0U, 1,2,3,4,5,6,7,8,9]);
        assert(more.getSorted == [99U, 98, 97, 96, 95, 94, 93, 92, 91, 90]);
    }
    foreach(i; 0..100) {
        auto less = TopNLess(10);
        auto more = TopNGreater(10);
        randomShuffle(nums, gen);
        foreach(n; nums[0..5]) {
            less.put(n);
            more.put(n);
        }
        assert(less.getSorted == qsort!("a < b")(nums[0..5]));
        assert(more.getSorted == qsort!("a > b")(nums[0..5]));
    }
    writeln("Passed TopN test.");
}

// Verify that there are no TempAlloc memory leaks anywhere in the code covered
// by the unittest.  This should always be the last unittest of the module.
unittest {
    auto TAState = TempAlloc.getState;
    assert(TAState.used == 0);
    assert(TAState.nblocks < 2);
}

