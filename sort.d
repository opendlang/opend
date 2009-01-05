/**A comprehensive sorting library for statistical functions.  Each function
 * takes N arguments, which are arrays or array-like objects, sorts the first
 * and sorts the rest in lockstep.  For the stable sorts, if the last argument
 * is a ulong*, increments the dereference of this ulong* by the bubble sort
 * distance between the first argument and the sorted version of the first
 * argument.  This is useful for some statistical calculations.
 *
 * Examples:
 * ---
 * auto foo = [3, 1, 2, 4, 5].dup;
 * auto bar = [8, 6, 7, 5, 3].dup;
 * qsort(foo, bar);
 * assert(foo == [1, 2, 3, 4, 5]);
 * assert(bar == [6, 7, 8, 5, 3]);
 * mergeSort!("a > b")(bar, foo);
 * assert(bar == [8, 7, 6, 5, 3]);
 * assert(foo == [3, 2, 1, 4, 5]);
 * ---
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

module dstats.sort;

import std.traits, std.algorithm, std.math, std.functional, std.math,
       std.typetuple;

import dstats.alloc;

version(unittest) {
    import std.stdio, std.random;
    Random gen;

    void main (){
    }
}

void rotateLeft(T)(T[] input) {
    if(input.length < 2) return;
    T temp = input[0];
    foreach(i; 1..input.length) {
        input[i-1] = input[i];
    }
    input[$-1] = temp;
}

void rotateRight(T)(T[] input) {
    if(input.length < 2) return;
    T temp = input[$-1];
    for(size_t i = input.length - 1; i > 0; i--) {
        input[i] = input[i-1];
    }
    input[0] = temp;
}

// For testing purposes for stable sorts.  Shuffles N arrays in lockstep.
version(unittest) {
    void randomMultiShuffle(SomeRandomGen, T...)(ref SomeRandomGen r, T array) {
        foreach (i; 0 .. array[0].length) {
            // generate a random number i .. n
            invariant which = i + uniform!(size_t)(r, 0u, array[0].length - i);
            foreach(ti, element; array) {
                swap(element[i], element[which]);
            }
        }
    }
}

/**Less than, except a NAN is less than anything except another NAN. This
 * behavior is totally arbitrary, but something has to be done with NANs by default
 * to avoid totally breaking the sorting algorithms when they occur.*/
bool lessThan(T)(T lhs, T rhs) {
    static if(isFloatingPoint!(T)) {
        return ((lhs < rhs) || (isnan(lhs) && !isnan(rhs)));
    } else {
        return lhs < rhs;
    }
}

/**Greater than, except anything except another NAN > a NAN.  This behavior
 * is totally arbitrary, but something has to be done with NANs by default
 * to avoid totally breaking the sorting algorithms when they occur.*/
bool greaterThan(T)(T lhs, T rhs) {
    static if(isFloatingPoint!(T)) {
        return ((lhs > rhs) || !isnan(lhs) && isnan(rhs));
    } else {
        return lhs > rhs;
    }
}

/**Quick sort.  Unstable, O(N log N) time average, O(N^2) time worst
 * case, O(log N) space, small constant term in time complexity.
 *
 * In this implementation, the following steps are taken to avoid the O(N^2)
 * worst case:
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
 *     this function transitions to a heap sort.*/
T[0] qsort(alias compFun = lessThan, T...)(T data) {
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
        // If it takes > 40 recursions, we likely have a pathological case.
        heapSort!(compFun)(data);
        return;
    }
    TTL--;
    size_t middle = data[0].length / 2;

    //Compute median of 3.
    if((!comp(data[0][middle], data[0][$-1]) &&
       !comp(data[0][0], data[0][middle])) ||
        (!comp(data[0][$-1], data[0][middle]) &&
        !comp(data[0][middle], data[0][0]))) {  //Middle is median of 3
        foreach(array; data)
            swap(array[middle], array[$-1]);
    } else if((!comp(data[0][0], data[0][$-1]) &&
              !comp(data[0][middle], data[0][0])) ||
              (!comp(data[0][$-1], data[0][0]) &&
              !comp(data[0][0], data[0][middle]))) {  //First is median of 3.
        foreach(array; data)
            swap(array[0], array[$-1]);
    }
    // Else, last is median of 3, already good.
    // Begin meat of algorithm.

    T less, greater;
    int lessI = -1, greaterI = data[0].length - 1;

    auto pivot = data[0][$ - 1];
    while(true) {
        while(comp(data[0][++lessI], pivot)) {}
        while(greaterI > 0 && comp(pivot, data[0][--greaterI])) {}

        if(lessI < greaterI) {
            foreach(array; data) {
                swap(array[lessI], array[greaterI]);
            }
        } else break;
    }

    foreach(ti, array; data) {
        swap(array[lessI], array[$ - 1]);
        less[ti] = array[0..min(lessI, greaterI + 1)];
        greater[ti] = array[lessI + 1..$];
    }
    // Allow tail recursion optimization for larger block.
    if(greater[0].length > less[0].length) {
        qsortImpl!(compFun)(less, TTL);
        qsortImpl!(compFun)(greater, TTL);
        return;
    }
    qsortImpl!(compFun)(greater, TTL);
    qsortImpl!(compFun)(less, TTL);
}

unittest {
    gen.seed(unpredictableSeed);
    {  // Test integer.
        uint[] test = new uint[1_000];
        foreach(ref e; test) {
            e = uniform(gen, 0, 100);
        }
        auto test2 = test.dup;
        foreach(i; 0..1_000) {
            randomMultiShuffle(gen, test, test2);
            uint len = uniform(gen, 0, 1_000);
            qsort(test[0..len], test2[0..len]);
            assert(isSorted(test[0..len]));
            assert(test == test2);
        }
    }
    { // Test float.
        double[] test = new double[1_000];
        foreach(ref e; test) {
            e = uniform(gen, 0.0, 100_000);
        }
        auto test2 = test.dup;
        foreach(i; 0..1_000) {
            randomMultiShuffle(gen, test, test2);
            uint len = uniform(gen, 0, 1_000);
            qsort!("a > b")(test[0..len], test2[0..len]);
            assert(isSorted!("a > b")(test[0..len]));
            assert(test == test2);
        }
    }
    writeln("Passed qsort test.");
}

//Keeps track of what array merge sort data is in.
private enum {
    DATA,
    TEMP
}

/**Merge sort.  O(N log N) time, O(N) space, small constant.  Stable sort.
 * If last argument is a ulong* instead of an array-like type,
 * the dereference of the ulong* will be incremented by the bubble sort
 * distance between the input array and the sorted version.  This is useful
 * in some statistics functions such as Kendall's tau.*/
T[0] mergeSort(alias compFun = lessThan, T...)(T data) {
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
        e = uniform(gen, 0, 100);  //Lots of ties.
    }
    foreach(i; 0..100) {
        ulong mergeCount = 0, bubbleCount = 0;
        foreach(j, ref e; stability) {
            e = j;
        }
        randomMultiShuffle(gen, test);
        uint len = uniform(gen, 0, 1_000);
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
        randomMultiShuffle(gen, test);
        uint len = uniform(gen, 0, 1_000);
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
    writeln("Passed mergeSort test.");
}

/**Merge sort, allowing caller to provide a temp variable.  This allows
 * recycling instead of repeated allocations.  If D is data, T is temp,
 * and U is a ulong* for calculating bubble sort distance, this can be called
 * as mergeSortTemp(D, D, D, T, T, T, U) or mergeSortTemp(D, D, D, T, T, T)
 * where each D has a T of corresponding type.*/
T[0] mergeSortTemp(alias compFun = lessThan, T...)(T data) {
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

uint mergeSortImpl(alias compFun = lessThan, T...)(T dataIn) {
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

void merge(alias compFun, T...)(T data) {
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
    size_t i = 0;
    while(left[0].length && right[0].length) {
        if(comp(right[0][0], left[0][0])) {

            static if(is(T[$ - 1] == ulong*)) {
                *swapCount += left[0].length;
            }

            foreach(ti, array; result) {
                result[ti][i] = right[ti][0];
                right[ti] = right[ti][1..$];
            }
        } else {
            foreach(ti, array; result) {
                result[ti][i] = left[ti][0];
                left[ti] = left[ti][1..$];
            }
        }
        i++;
    }
    if(right[0].length) {
        foreach(ti, array; result) {
            result[ti][i..$] = right[ti];
        }
    } else {
        foreach(ti, array; result) {
            result[ti][i..$] = left[ti];
        }
    }
}

/**Heap sort.  Unstable, O(N log N) time average and worst case, O(1) space,
 * large constant term in time complexity.*/
T[0] heapSort(alias compFun = lessThan, T...)(T input) {
    alias binaryFun!(compFun) comp;
    if(input[0].length < 2) return input[0];
    makeMultiHeap!(compFun)(input);
    for(size_t end = input[0].length - 1; end > 0; end--) {
        foreach(ti, ia; input) {
            swap(ia[end], ia[0]);
        }
        multiSiftDown!(compFun)(input, 0, end);
    }
    return input[0];
}

unittest {
    gen.seed(unpredictableSeed);
    uint[] test = new uint[1_000];
    foreach(ref e; test) {
        e = uniform(gen, 0, 100_000);
    }
    auto test2 = test.dup;
    foreach(i; 0..1_000) {
        randomMultiShuffle(gen, test, test2);
        uint len = uniform(gen, 0, 1_000);
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
                swap(ia[root], ia[child]);
            }
            root = child;
        }
        else return;
    }
}

/**Insertion sort.  O(N^2) time worst, average case, O(1) space, VERY small
 * constant, which is why it's useful for sorting small subarrays in
 * divide and conquer algorithms.  If last argument is a ulong*, increments
 * the dereference of this argument by the bubble sort distance between the
 * input array and the sorted version of the input.*/
T[0] insertionSort(alias compFun = lessThan, T...)(T data) {
    alias binaryFun!(compFun) comp;
    static if(is(T[$ - 1] == ulong*)) invariant uint dl = data.length - 1;
    else invariant uint dl = data.length;
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
    gen.seed(unpredictableSeed);
    uint[] test = new uint[100], stability = new uint[100];
    foreach(ref e; test) {
        e = uniform(gen, 0, 100);  //Lots of ties.
    }
    foreach(i; 0..1_000) {
        ulong insertCount = 0, bubbleCount = 0;
        foreach(j, ref e; stability) {
            e = j;
        }
        randomMultiShuffle(gen, test);
        uint len = uniform(gen, 0, 100);
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
T[0] bubbleSort(alias compFun = lessThan, T...)(T data) {
    alias binaryFun!(compFun) comp;
    static if(is(T[$ - 1] == ulong*))
        invariant uint dl = data.length - 1;
    else invariant uint dl = data.length;
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

/**Given a set of data points entered through the addElement function,
 * maintains the invariant that the top N according to compFun will be
 * contained in the data structure.  Uses a heap internally, O(log N) insertion
 * time.  Good for finding the top N elements of a very large dataset that
 * cannot be sorted quickly in its entirety.  If less than N datapoints
 * have been entered, all are contained in the structure.
 *
 * Examples:
 * ---
    Random gen;
    gen.seed(unpredictableSeed);
    uint[] nums = seq(0U, 100U);
    auto less = TopN!(uint, "a < b")(10);
    auto more = TopN!(uint, "a > b")(10);
    randomShuffle(nums, gen);
    foreach(n; nums) {
        less.addElement(n);
        more.addElement(n);
    }
    assert(less.getSorted == [0U, 1,2,3,4,5,6,7,8,9]);
    assert(more.getSorted == [99U, 98, 97, 96, 95, 94, 93, 92, 91, 90]);
    ---*/
struct TopN(T, alias compFun = greaterThan) {
private:
    alias binaryFun!(compFun) comp;
    uint n;
    uint nAdded;

    T[] nodes;
public:
    /**The variable ntop controls how many elements are retained.*/
    this(uint ntop) {
        n = ntop;
        nodes = new T[n];
    }

    /**Insert an element into the topN struct.*/
    void addElement(T elem) {
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
            less.addElement(n);
            more.addElement(n);
        }
        assert(less.getSorted == [0U, 1,2,3,4,5,6,7,8,9]);
        assert(more.getSorted == [99U, 98, 97, 96, 95, 94, 93, 92, 91, 90]);
    }
    foreach(i; 0..100) {
        auto less = TopNLess(10);
        auto more = TopNGreater(10);
        randomShuffle(nums, gen);
        foreach(n; nums[0..5]) {
            less.addElement(n);
            more.addElement(n);
        }
        assert(less.getSorted == qsort!("a < b")(nums[0..5]));
        assert(more.getSorted == qsort!("a > b")(nums[0..5]));
    }
    writeln("Passed TopN test.");
}

/**Returns the kth largest/smallest element (depending on compFun, 0-indexed)
 * in the input array in O(N) time.  Allocates memory, does not modify input
 * array.*/
T quickSelect(alias compFun = lessThan, T)(const T[] data, int k) {
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
 * auto secondElem = partitionK(foo, 1);
 * assert(secondElem == 2);
 * foreach(elem; foo[0..1]) {
 *     assert(elem <= foo[1]);
 * }
 * foreach(elem; foo[2..$]) {
 *     assert(elem >= foo);
 * }
 *
 * Returns:  The kth element of the array.*/
ArrayElemType!(T[0]) partitionK(alias compFun = lessThan, T...)(T data, int k) {
    alias binaryFun!(compFun) comp;

    size_t middle = data[0].length / 2;

    //Compute median of 3.
    if((!comp(data[0][middle], data[0][$-1]) &&
       !comp(data[0][0], data[0][middle])) ||
        (!comp(data[0][$-1], data[0][middle]) &&
        !comp(data[0][middle], data[0][0]))) {  //Middle is median of 3
        foreach(array; data)
            swap(array[middle], array[$-1]);
    } else if((!comp(data[0][0], data[0][$-1]) &&
              !comp(data[0][middle], data[0][0])) ||
              (!comp(data[0][$-1], data[0][0]) &&
              !comp(data[0][0], data[0][middle]))) {  //First is median of 3.
        foreach(array; data)
            swap(array[0], array[$-1]);
    }
    // Else, last is median of 3, already good.

    int lessI = -1, greaterI = data[0].length - 1;
    auto pivot = data[0][$ - 1];
    while(true) {
        while(comp(data[0][++lessI], pivot)) {}
        while(greaterI > 0 && comp(pivot, data[0][--greaterI])) {}

        if(lessI < greaterI) {
            foreach(array; data) {
                swap(array[lessI], array[greaterI]);
            }
        } else break;
    }
    foreach(array; data) {
        swap(array[lessI], array[$ - 1]);
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
    gen.seed(unpredictableSeed);
    enum n = 1000;
    uint[] test = new uint[n];
    uint[] test2 = new uint[n];
    uint[] lockstep = new uint[n];
    foreach(ref e; test) {
        e = uniform(gen, 0, 1000);
    }
    foreach(i; 0..1_000) {
        randomShuffle(test, gen);
        test2[] = test[];
        lockstep[] = test[];
        uint len = uniform(gen, 0, n - 1) + 1;
        qsort!("a > b")(test2[0..len]);
        int k = uniform(gen, 0, len);
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

// Verify that there are no TempAlloc memory leaks anywhere in the code covered
// by the unittest.  This should always be the last unittest of the module.
unittest {
    auto TAState = TempAlloc.getState;
    assert(TAState.current.used == 0);
    assert(TAState.nblocks < 2);
}
