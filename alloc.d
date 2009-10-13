/**Allocation functions.
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

module dstats.alloc;

import std.traits, core.memory, core.thread, std.array, std.range, dstats.base;
static import std.c.stdio;

version(unittest) {
    import std.stdio, std.conv, dstats.sort;
    void main() {}
}

template IsType(T, Types...) {
    // Original idea by Burton Radons, modified
    static if (Types.length == 0)
        const bool IsType = false;
    else
        const bool IsType = is(T == Types[0]) || IsType!(T, Types[1 .. $]);
}

template ArrayType1(T: T[]) {
    alias T ArrayType1;
}

template isReferenceType(Types...) {  //Thanks to Bearophile.
    static if (Types.length == 0) {
        const bool isReferenceType = false;
    } else static if (Types.length == 1) {
        static if (IsType!(Unqual!(Types[0]), bool, byte, ubyte, short, ushort,
                           int, uint, long, ulong, float, double, real, ifloat,
                           idouble, ireal, cfloat, cdouble, creal, char, dchar,
                           wchar) ) {
            const bool isReferenceType = false;
        } else static if ( is(Types[0] == struct) ) {
            const bool isReferenceType =
            isReferenceType!(FieldTypeTuple!(Types[0]));
        } else static if (isStaticArray!(Types[0])) {
            const bool isReferenceType = isReferenceType!(ArrayType1!(Types[0]));
        } else
            const bool isReferenceType = true;
    } else
        const bool isReferenceType = isReferenceType!(Types[0]) |
        isReferenceType!(Types[1 .. $]);
} // end isReferenceType!()

unittest {
    static assert(!isReferenceType!(typeof("Foo"[0])));
    static assert(isReferenceType!(uint*));
    static assert(!isReferenceType!(typeof([0,1,2])));
    struct noPtrs {
        uint f;
        uint b;
    }
    struct ptrs {
        uint* f;
        uint b;
    }
    static assert(!isReferenceType!(noPtrs));
    static assert(isReferenceType!(ptrs));
    pragma(msg, "Passed isReferenceType unittest");
}

template blockAttribute(T) {
    static if (isReferenceType!(T))
        enum blockAttribute = 0;
    else enum blockAttribute = GC.BlkAttr.NO_SCAN;
}

///Returns a new array of type T w/o initializing elements.
T[] newVoid(T)(size_t length) {
    T* ptr = cast(T*) GC.malloc(length * T.sizeof, blockAttribute!(T));
    return ptr[0..length];
}

void lengthVoid(T)(ref T[] input, int newLength) {
    input.lengthVoid(cast(size_t) newLength);
}

///Lengthens an array w/o initializing new elements.
void lengthVoid(T)(ref T[] input, size_t newLength) {
    if (newLength <= input.length ||
            GC.sizeOf(input.ptr) >= newLength * T.sizeof) {
        input = input.ptr[0..newLength];  //Don't realloc if I don't have to.
    } else {
        T* newPtr = cast(T*) GC.realloc(input.ptr,
                                        T.sizeof * newLength, blockAttribute!(T));
        input = newPtr[0..newLength];
    }
}

void reserve(T)(ref T[] input, int newLength) {
    input.reserve(cast(size_t) newLength);
}

/**Reserves more space for an array w/o changing its length or initializing
 * the space.*/
void reserve(T)(ref T[] input, size_t newLength) {
    if (newLength <= input.length || capacity(input.ptr) >= newLength * T.sizeof)
        return;
    T* newPtr = cast(T*) GC.realloc(input.ptr, T.sizeof * newLength);
    staticSetTypeInfo!(T)(newPtr);
    input = newPtr[0..input.length];
}

private template Appends(T, U) {
    enum bool Appends = AppendsImpl!(T, U).ret;
}

private template AppendsImpl(T, U) {
    T[] a;
    U b;
    enum bool ret = is(typeof(a ~= b));
}

///Appends to an array, deleting the old array if it has to be realloced.
void appendDelOld(T, U)(ref T[] to, U from)
if(Appends!(T, U)) {
    auto oldPtr = to.ptr;
    to ~= from;
    if (oldPtr != to.ptr)
        delete oldPtr;
}

unittest {
    uint[] foo;
    foo.appendDelOld(5);
    foo.appendDelOld(4);
    foo.appendDelOld(3);
    foo.appendDelOld(2);
    foo.appendDelOld(1);
    assert(foo == cast(uint[]) [5,4,3,2,1]);
    writefln("Passed appendDelOld test.");
}

// C functions, marked w/ nothrow.
extern(C) nothrow int fprintf(shared(void*), in char *,...);
extern(C) nothrow void exit(int);

/**TempAlloc struct.  See TempAlloc project on Scrapple.*/
struct TempAlloc {
private:
    struct Stack(T) {  // Simple, fast stack w/o error checking.
        private size_t capacity;
        private size_t index;
        private T* data;
        private enum sz = T.sizeof;

        private static size_t max(size_t lhs, size_t rhs) pure nothrow {
            return (rhs > lhs) ? rhs : lhs;
        }

        void push(T elem) nothrow {
            if (capacity == index) {
                capacity = max(16, capacity * 2);
                data = cast(T*) ntRealloc(data, capacity * sz, cast(GC.BlkAttr) 0);
                data[index..capacity] = T.init;  // Prevent false ptrs.
            }
            data[index++] = elem;
        }

        T pop() nothrow {
            index--;
            auto ret = data[index];
            data[index] = T.init;  // Prevent false ptrs.
            return ret;
        }
    }

    struct Block {
        size_t used = 0;
        void* space = null;
    }

    final class State {
        size_t used;
        void* space;
        size_t totalAllocs;
        void*[] lastAlloc;
        uint nblocks;
        uint nfree;
        size_t frameIndex;

        // inUse holds info for all blocks except the one currently being
        // allocated from.  freelist holds space ptrs for all free blocks.
        Stack!(Block) inUse;
        Stack!(void*) freelist;

        void putLast(void* last) nothrow {
            // Add an element to lastAlloc, checking length first.
            if (totalAllocs == lastAlloc.length)
                doubleSize(lastAlloc);
            lastAlloc[totalAllocs++] = cast(void*) last;
        }
    }

    // core.thread.Thread.thread_needLock() is nothrow (read the code if you
    // don't believe me) but not marked as such because nothrow is such a new
    // feature in D.  This is a workaround until that gets fixed.
    static enum tnl = cast(bool function() nothrow) &thread_needLock;

    enum blockSize = 4U * 1024U * 1024U;
    enum nBookKeep = 1_048_576;  // How many bytes to allocate upfront for bookkeeping.
    enum alignBytes = 16U;
    static __thread State state;
    static State mainThreadState;

    static void die() nothrow {
        fprintf(std.c.stdio.stderr, "TempAlloc error: Out of memory.\0".ptr);
        exit(1);
    }

    static void doubleSize(ref void*[] lastAlloc) nothrow {
        size_t newSize = lastAlloc.length * 2;
        void** ptr = cast(void**)
        ntRealloc(lastAlloc.ptr, newSize * (void*).sizeof, GC.BlkAttr.NO_SCAN);

        if (lastAlloc.ptr != ptr) {
            ntFree(lastAlloc.ptr);
        }

        lastAlloc = ptr[0..newSize];
    }

    static void* ntMalloc(size_t size, GC.BlkAttr attr) nothrow {
        try { return GC.malloc(size, attr); } catch { die(); }
        return null;  // Can't assert b/c then it would throw.
    }

    static void* ntRealloc(void* ptr, size_t size, GC.BlkAttr attr) nothrow {
        try { return GC.realloc(ptr, size, attr); } catch { die(); }
        return null;
    }

    static void ntFree(void* ptr) nothrow {
        try { GC.free(ptr); } catch {}
        return;
    }

    static size_t getAligned(size_t nbytes) pure nothrow {
        size_t rem = nbytes % alignBytes;
        return (rem == 0) ? nbytes : nbytes - rem + alignBytes;
    }

    static State stateInit() nothrow {
        State stateCopy;
        try { stateCopy = new State; } catch { die(); }

        with(stateCopy) {
            space = ntMalloc(blockSize, GC.BlkAttr.NO_SCAN);
            lastAlloc = (cast(void**) ntMalloc(nBookKeep, GC.BlkAttr.NO_SCAN))
                        [0..nBookKeep / (void*).sizeof];
            nblocks++;
        }

        state = stateCopy;
        if (!tnl())
            mainThreadState = stateCopy;
        return stateCopy;
    }

public:
    /**Allows caller to cache the state class on the stack and pass it in as a
     * parameter.  This is ugly, but results in a speed boost that can be
     * significant in some cases because it avoids a thread-local storage
     * lookup.  Also used internally.*/
    static State getState() nothrow {
        // Believe it or not, even with builtin TLS, the thread_needLock()
        // is worth it to avoid the TLS lookup.
        State stateCopy = (tnl()) ? state : mainThreadState;
        return (stateCopy is null) ? stateInit : stateCopy;
    }

    /**Initializes a frame, i.e. marks the current allocation position.
     * Memory past the position at which this was last called will be
     * freed when frameFree() is called.  Returns a reference to the
     * State class in case the caller wants to cache it for speed.*/
    static State frameInit() nothrow {
        return frameInit(getState);
    }

    /**Same as frameInit() but uses stateCopy cached on stack by caller
     * to avoid a thread-local storage lookup.  Strictly a speed hack.*/
    static State frameInit(State stateCopy) nothrow {
        with(stateCopy) {
            putLast( cast(void*) frameIndex );
            frameIndex = totalAllocs;
        }
        return stateCopy;
    }

    /**Frees all memory allocated by TempAlloc since the last call to
     * frameInit().*/
    static void frameFree() nothrow {
        frameFree(getState);
    }

    /**Same as frameFree() but uses stateCopy cached on stack by caller
    * to avoid a thread-local storage lookup.  Strictly a speed hack.*/
    static void frameFree(State stateCopy) nothrow {
        with(stateCopy) {
            while (totalAllocs > frameIndex) {
                free(stateCopy);
            }
            frameIndex = cast(size_t) lastAlloc[--totalAllocs];
        }
    }

    /**Purely a convenience overload, forwards arguments to TempAlloc.malloc().*/
    static void* opCall(T...)(T args) nothrow {
        return TempAlloc.malloc(args);
    }

    /**Allocates nbytes bytes on the TempAlloc stack.  NOT safe for real-time
     * programming, since if there's not enough space on the current block,
     * a new one will automatically be created.  Also, very large objects
     * (currently over 4MB) will simply be heap-allocated.
     *
     * Bugs:  Memory allocated by TempAlloc is not scanned by the GC.
     * This is necessary for performance and to avoid false pointer issues.
     * Do not store the only reference to a GC-allocated object in
     * TempAlloc-allocated memory.*/
    static void* malloc(size_t nbytes) nothrow {
        return malloc(nbytes, getState);
    }

    /**Same as malloc() but uses stateCopy cached on stack by caller
    * to avoid a thread-local storage lookup.  Strictly a speed hack.*/
    static void* malloc(size_t nbytes, State stateCopy) nothrow {
        nbytes = getAligned(nbytes);
        with(stateCopy) {
            void* ret;
            if (blockSize - used >= nbytes) {
                ret = space + used;
                used += nbytes;
            } else if (nbytes > blockSize) {
                ret = ntMalloc(nbytes, GC.BlkAttr.NO_SCAN);
            } else if (nfree > 0) {
                inUse.push(Block(used, space));
                space = freelist.pop;
                used = nbytes;
                nfree--;
                nblocks++;
                ret = space;
            } else { // Allocate more space.
                inUse.push(Block(used, space));
                space = ntMalloc(blockSize, GC.BlkAttr.NO_SCAN);
                nblocks++;
                used = nbytes;
                ret = space;
            }
            putLast(ret);
            return ret;
        }
    }

    /**Frees the last piece of memory allocated by TempAlloc.  Since
     * all memory must be allocated and freed in strict LIFO order,
     * there's no need to pass a pointer in.  All bookkeeping for figuring
     * out what to free is done internally.*/
    static void free() nothrow {
        free(getState);
    }

    /**Same as free() but uses stateCopy cached on stack by caller
    * to avoid a thread-local storage lookup.  Strictly a speed hack.*/
    static void free(State stateCopy) nothrow {
        with(stateCopy) {
            void* lastPos = lastAlloc[--totalAllocs];

            // Handle large blocks.
            if (lastPos > space + blockSize || lastPos < space) {
                ntFree(lastPos);
                return;
            }

            used = (cast(size_t) lastPos) - (cast(size_t) space);
            if (nblocks > 1 && used == 0) {
                freelist.push(space);
                Block newHead = inUse.pop;
                space = newHead.space;
                used = newHead.used;
                nblocks--;
                nfree++;

                if (nfree >= nblocks * 2) {
                    foreach(i; 0..nfree / 2) {
                        ntFree(freelist.pop);
                        nfree--;
                    }
                }
            }
        }
    }
}

/**Allocates an array of type T and size size using TempAlloc.
 * Note that appending to this array using the ~= operator,
 * or enlarging it using the .length property, will result in
 * undefined behavior.  This is because, if the array is located
 * at the beginning of a TempAlloc block, the GC will think the
 * capacity is as large as a TempAlloc block, and will overwrite
 * adjacent TempAlloc-allocated data, instead of reallocating it.
 *
 * Bugs: Do not store the only reference to a GC-allocated reference object
 * in an array allocated by newStack because this memory is not
 * scanned by the GC.*/
T[] newStack(T)(size_t size) nothrow {
    size_t bytes = size * T.sizeof;
    T* ptr = cast(T*) TempAlloc.malloc(bytes);
    return ptr[0..size];
}

/**Same as newStack(size_t) but uses stateCopy cached on stack by caller
* to avoid a thread-local storage lookup.  Strictly a speed hack.*/
T[] newStack(T)(size_t size, TempAlloc.State state) nothrow {
    size_t bytes = size * T.sizeof;
    T* ptr = cast(T*) TempAlloc.malloc(bytes, state);
    return ptr[0..size];
}

/**Concatenate any number of arrays of the same type, placing results on
 * the TempAlloc stack.*/
T[0] stackCat(T...)(T data) {
    foreach(array; data) {
        static assert(is(typeof(array) == typeof(data[0])));
    }

    size_t totalLen = 0;
    foreach(array; data) {
        totalLen += array.length;
    }
    auto ret = newStack!(Unqual!(typeof(T[0][0])))(totalLen);

    size_t offset = 0;
    foreach(array; data) {
        ret[offset..offset + array.length] = array[0..$];
        offset += array.length;
    }
    return cast(T[0]) ret;
}

void rangeCopy(T, U)(T to, U from) {
    static if(is(typeof(to[] = from[]))) {
        to[] = from[];
    } else static if(isRandomAccessRange!(T)) {
        size_t i = 0;
        foreach(elem; from) {
            to[i++] = elem;
        }
    }
}

/**Creates a duplicate of a range for temporary use within a function in the
 * best wsy that can be done safely.  If ElementType!(T) is a value type
 * or T is an array, the results can safely be placed in TempAlloc because
 * either it doesn't need to be scanned by the GC or there's guaranteed to be
 * another reference to the contents somewhere. Otherwise, the results
 * are placed on the GC heap.
 *
 * This function is much faster if T has a length, but works even if it doesn't.
 */
Unqual!(ElementType!(T))[] tempdup(T)(T data)
if(isInputRange!(T) && (isArray!(T) || !isReferenceType!(ElementType!(T)))) {
    alias ElementType!(T) E;
    alias Unqual!(E) U;
    static if(dstats.base.hasLength!(T)) {
        U[] ret = newStack!(U)(data.length);
        rangeCopy(ret, data);
        return ret;
    } else {
        auto state = TempAlloc.getState;
        auto startPtr = TempAlloc(0, state);
        size_t bytesCopied = 0;

        while(!data.empty) {  // Make sure range interface is being used.
            auto elem = data.front;
            if(state.used + U.sizeof <= TempAlloc.blockSize) {
                data.popFront;
                *(cast(U*) (startPtr + bytesCopied)) = elem;
                bytesCopied += U.sizeof;
                state.used += U.sizeof;
            } else {
                if(bytesCopied + U.sizeof >= TempAlloc.blockSize / 2) {
                    // Then just heap-allocate.
                    U[] result = newVoid!(U)(bytesCopied / U.sizeof);
                    result[] = (cast(U*) startPtr)[0..result.length];
                    finishCopy(result, data);
                    TempAlloc.free;
                    state.putLast(result.ptr);
                    return result;
                } else {
                    U[] oldData = (cast(U*) startPtr)[0..bytesCopied / U.sizeof];
                    state.used -= bytesCopied;
                    state.totalAllocs--;
                    U[] newArray = newStack!(U)(bytesCopied / U.sizeof + 1, state);
                    newArray[0..oldData.length] = oldData[];
                    startPtr = state.space;
                    newArray[$ - 1] = elem;
                    bytesCopied += U.sizeof;
                    data.popFront;
                }
            }
        }
        auto rem = bytesCopied % TempAlloc.alignBytes;
        if(rem != 0) {
            auto toAdd = 16 - rem;
            if(state.used + toAdd < TempAlloc.blockSize) {
                state.used += toAdd;
            } else {
                state.used = TempAlloc.blockSize;
            }
        }
        return (cast(U*) startPtr)[0..bytesCopied / U.sizeof];
    }
}

Unqual!(ElementType!(T))[] tempdup(T)(T data)
if(isInputRange!(T) && !(isArray!(T) || !isReferenceType!(ElementType!(T)))) {
    auto ret = toArray(data);
    TempAlloc.getState.putLast(ret.ptr);
    return ret;
}

private void finishCopy(T, U)(ref T[] result, U range) {
    auto app = appender(&result);
    foreach(elem; range) {
        app.put(elem);
    }
}

// See Bugzilla 2873.  This can be removed once that's fixed.
template hasLength(R) {
    enum bool hasLength = is(typeof(R.init.length) : ulong) ||
                      is(typeof(R.init.length()) : ulong);
}

/**Converts any range to an array on the GC heap by the most efficient means
 * available.  If it is already an array, duplicates the range.*/
Unqual!(ElementType!(T))[] toArray(T)(T range) if(isInputRange!(T)) {
    static if(isArray!(T)) {
        // Allow fast copying by assuming that the input is an array.
        return range.dup;
    } else static if(hasLength!(T)) {
        // Preallocate array, then copy.
        auto ret = newVoid!(Unqual!(ElementType!(T)))(range.length);
        static if(is(typeof(ret[] = range[]))) {
            ret[] = range[];
        } else {
            size_t pos = 0;
            foreach(elem; range) {
                ret[pos++] = elem;
            }
        }
        return ret;
    } else {
        // Don't have length, have to use appending.
        Unqual!(ElementType!(T))[] ret;
        auto app = appender(&ret);
        foreach(elem; range) {
            app.put(elem);
        }
        return ret;
    }
}

unittest {
    // Create quick and dirty finite but lengthless range.
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

    TempAlloc(1024 * 1024 * 3);
    Count count;
    count.upTo = 1024 * 1025;
    auto asArray = tempdup(count);
    foreach(i, elem; asArray) {
        assert(i == elem, to!(string)(i) ~ "\t" ~ to!(string)(elem));
    }
    assert(asArray.length == 1024 * 1025);
    TempAlloc.free;
    TempAlloc.free;
    while(TempAlloc.getState.freelist.index > 0) {
        TempAlloc.getState.freelist.pop;
    }
    writeln("Passed tempdup unittest.");
}

/**A string to mixin at the beginning of a scope, purely for
 * convenience.  Initializes a TempAlloc frame using frameInit(),
 * and inserts a scope statement to delete this frame at the end
 * of the current scope.
 *
 * Slower than calling free() manually when only a few pieces
 * of memory will be allocated in the current scope, due to the
 * extra bookkeeping involved.  Can be faster, however, when
 * large amounts of allocations, such as arrays of arrays,
 * are allocated, due to caching of data stored in thread-local
 * storage.*/
immutable char[] newFrame =
    "TempAlloc.frameInit; scope(exit) TempAlloc.frameFree;";

unittest {
    /* Not a particularly good unittest in that it depends on knowing the
     * internals of TempAlloc, but it's the best I could come up w/.  This
     * is really more of a stress test/sanity check than a normal unittest.*/

     // First test to make sure a large number of allocations does what it's
     // supposed to in terms of reallocing lastAlloc[], etc.
     enum nIter =  TempAlloc.blockSize * 5 / TempAlloc.alignBytes;
     foreach(i; 0..nIter) {
         TempAlloc(TempAlloc.alignBytes);
     }
     assert(TempAlloc.getState.nblocks == 5, to!string(TempAlloc.getState.nblocks));
     assert(TempAlloc.getState.nfree == 0);
     foreach(i; 0..nIter) {
        TempAlloc.free;
    }
    assert(TempAlloc.getState.nblocks == 1);
    assert(TempAlloc.getState.nfree == 2);

    // Make sure logic for freeing excess blocks works.  If it doesn't this
    // test will run out of memory.
    enum allocSize = TempAlloc.blockSize / 2;
    void*[] oldStates;
    foreach(i; 0..50) {
        foreach(j; 0..50) {
            TempAlloc(allocSize);
        }
        foreach(j; 0..50) {
            TempAlloc.free;
        }
        oldStates ~= cast(void*) TempAlloc.state;
        oldStates ~= cast(void*) TempAlloc.mainThreadState;
        TempAlloc.state = null;
        TempAlloc.mainThreadState = null;
    }
    oldStates = null;

    // Make sure data is stored properly.
    foreach(i; 0..10) {
        TempAlloc(allocSize);
    }
    foreach(i; 0..5) {
        TempAlloc.free;
    }
    GC.collect;  // Make sure nothing that shouldn't is getting GC'd.
    void* space = TempAlloc.mainThreadState.space;
    size_t used = TempAlloc.mainThreadState.used;

    TempAlloc.frameInit;
    // This array of arrays should not be scanned by the GC because otherwise
    // bugs caused th not having the GC scan certain internal things in
    // TempAlloc that it should would not be exposed.
    uint[][] arrays = (cast(uint[]*) GC.malloc((uint[]).sizeof * 10,
                       GC.BlkAttr.NO_SCAN))[0..10];
    foreach(i; 0..10) {
        uint[] data = newStack!(uint)(250_000);
        foreach(j, ref e; data) {
            e = j * (i + 1);  // Arbitrary values that can be read back later.
        }
        arrays[i] = data;
    }

    // Make stuff get overwrriten if blocks are getting GC'd when they're not
    // supposed to.
    GC.minimize;  // Free up all excess pools.
    uint[][] foo;
    foreach(i; 0..40) {
        foo ~= new uint[1_048_576];
    }
    foo = null;

    for(size_t i = 9; i != size_t.max; i--) {
        foreach(j, e; arrays[i]) {
            assert(e == j * (i + 1));
        }
    }
    TempAlloc.frameFree;
    assert(space == TempAlloc.mainThreadState.space);
    assert(used == TempAlloc.mainThreadState.used);
    while(TempAlloc.state.nblocks > 1 || TempAlloc.state.used > 0) {
        TempAlloc.free;
    }
    fprintf(std.c.stdio.stderr, "Passed TempAlloc test.\n\0".ptr);
}

struct SHNode(K, V) {
    alias SHNode!(K, V) SomeType;
    SomeType* next;
    Unqual!(K) key;
    Unqual!(V) val;
}

/**Forward range struct for iterating over the keys or values of a
 * StackHash or StackSet.  The lifetime of this object must not exceed that
 * of the underlying StackHash or StackSet.*/
struct HashRange(K, S, bool vals = false) {
private:
    S* set;
    size_t index;
    S.Node* next;
    K* frontElem;
    size_t _length;

    this(S* set) {
        this.set = set;
        if(set.rNext[0] == set.usedSentinel) {
            this.popFront;
        } else {
            static if(vals) {
                frontElem = set.rVals.ptr;
            } else {
                frontElem = set.rKeys.ptr;
            }
            next = set.rNext[0];
        }
        this._length = set.length;
    }

public:
    ///
    void popFront() {
        this._length--;
        if(next is null) {
            do {
                index++;
                if(index >= set.rNext.length) {
                    index = size_t.max;  // Sentinel for empty.
                    return;
                }
                next = set.rNext[index];
            } while(set.rNext[index] == set.usedSentinel);
            static if(vals) {
                frontElem = &(set.rVals[index]);
            } else {
                frontElem = &(set.rKeys[index]);
            }
        } else {
            static if(vals) {
                frontElem = &(next.val);
            } else {
                frontElem = &(next.key);
            }
            next = next.next;
        }
    }

    ///
    Unqual!(K) front() {
        return *frontElem;
    }

    ///
    bool empty() {
        return index == size_t.max;
    }

    ///
    size_t length() {
        return _length;
    }
}

/**A hash table that allocates its memory on TempAlloc.  Good for building a
 * temporary hash tables that will not escape the current scope.
 *
 * To avoid TempAlloc memory leaks, use mixin(newFrame).
 *
 * Examples:
 * ---
 * mixin(newFrame);  // To make sure all memory gets freed at end of scope.
 * auto ss = StackHash!(uint)(5);
 * foreach(i; 0..5) {
 *     ss[i]++;
 * }
 * assert(ss[3] == 1);
 * ---
 */
struct StackHash(K, V) {
private:
    alias SHNode!(K, V) Node;

    // Using parallel arrays instead of structs to save on alignment overhead:
    Unqual!(K)[] rKeys;
    Unqual!(V)[] rVals;
    Unqual!(Node*)[] rNext;

    TempAlloc.State TAState;
    TypeInfo keyTI;
    size_t _length;
    Node* usedSentinel;

    Node* newNode(K key) {
        Node* ret = cast(Node*) TempAlloc(Node.sizeof, TAState);
        ret.key =  key;
        ret.val =  V.init;
        ret.next = null;
        return ret;
    }

    Node* newNode(K key, V val) {
        Node* ret = cast(Node*) TempAlloc(Node.sizeof, TAState);
        ret.key =  key;
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
        hash %= rNext.length;
        return hash;
    }


public:
    /**Due to the nature of TempAlloc, you must specify on object creation
     * the approximate number of elements your table will have.  Too large a
     * number will waste space and incur poor cache performance.  Too low a
     * number will make this struct perform like a linked list.  Generally,
     * if you're building a table from some other range, some fraction of the
     * size of that range is a good guess.*/
    this(size_t nElem) {
        // Obviously, the caller can never mean zero, because this struct
        // can't work at all with nElem == 0, so assume it's a mistake and fix
        // it here.
        if(nElem == 0)
            nElem++;
        TAState = TempAlloc.getState;
        rKeys = newStack!(K)(nElem, TAState);
        rVals = newStack!(V)(nElem, TAState);
        rNext = newStack!(Node*)(nElem, TAState);
        usedSentinel = cast(Node*) rNext.ptr;
        foreach(ref rKey; rKeys) {
            rKey =  K.init;
        }
        foreach(ref rVal; rVals) {
            rVal = V.init;
        }
        foreach(ref r; rNext) {
            r = usedSentinel;
        }
        keyTI = typeid(K);
    }

    /**Index an element of the range.  If it does not exist, it will be created
     * and initialized to V.init.*/
    ref V opIndex(K key) {
        hash_t hash = getHash(key);

        if(rNext[hash] == usedSentinel) {
            rKeys[hash] =  key;
            rNext[hash] = null;
            _length++;
            return rVals[hash];
        } else if(rKeys[hash] == key) {
            return rVals[hash];
        } else {  // Collision.  Start chaining.
            Node** next = &(rNext[hash]);
            while(*next !is null) {
                if((**next).key ==  key) {
                    return (**next).val;
                }
                next = &((**next).next);
            }
            *next = newNode(key);
            _length++;
            return (**next).val;
        }
    }

    ///
    V opIndexAssign(V val, K key) {
        hash_t hash = getHash(key);

        if(rNext[hash] == usedSentinel) {
            rKeys[hash] =  key;
            rVals[hash] = val;
            rNext[hash] = null;
            _length++;
            return val;
        } else if(rKeys[hash] ==  key) {
            rVals[hash] = val;
            return val;
        } else {  // Collision.  Start chaining.
            Node** next = &(rNext[hash]);
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

    ///
    V* opIn_r(K key) {
        hash_t hash = getHash(key);

        if(rNext[hash] == usedSentinel) {
            return null;
        } else if(rKeys[hash] == key) {
            return &(rVals[hash]);
        } else {  // Collision.  Start chaining.
            Node* next = rNext[hash];
            while(next !is null) {
                if(next.key == key) {
                    return &(next.val);
                }
                next = next.next;
            }
            return null;
        }
   }

    ///
    void remove(K key) {
        hash_t hash = getHash(key);

        Node** next = &(rNext[hash]);
        if(rNext[hash] == usedSentinel) {
            return;
        } else if(rKeys[hash] == key) {
            _length--;
            if(rNext[hash] is null) {
                rKeys[hash] = K.init;
                rVals[hash] = V.init;
                rNext[hash] = usedSentinel;
                return;
            } else {
                rKeys[hash] = (**next).key;
                rVals[hash] = (**next).val;
                rNext[hash] = (**next).next;
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

    /**Returns a forward range to iterate over the keys of this table.
     * The lifetime of the HashRange must not exceed the lifetime of this
     * StackHash.*/
    HashRange!(K, StackHash!(K, V)) keys() {
        return typeof(return)(&this);
    }

    /**Returns a forward range to iterate over the values of this table.
     * The lifetime of the HashRange must not exceed the lifetime of this
     * StackHash.*/
    HashRange!(V, StackHash!(K, V), true) values() {
       return typeof(return)(&this);
    }

    ///
    size_t length() const {
        return _length;
    }

    real efficiency() {
       uint used = 0;
       foreach(root; rNext) {
           if(root != usedSentinel) {
               used++;
           }
       }
       return cast(real) used / rNext.length;
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
    auto myKeys = toArray(data.keys);
    qsort(myKeys);
    assert(myKeys == cast(string[]) ["bar", "baz", "foo", "waldo"]);
    auto myValues = toArray(data.values);
    qsort(myValues);
    assert(myValues == [1U, 2, 3, 4]);
    {
        auto k = data.keys;
        auto v = data.values;
        while(!k.empty) {
            assert(data[k.front] == v.front);
            k.popFront;
            v.popFront;
        }
    }
    foreach(v; data.values) {
        assert(v > 0 && v < 5);
    }

    // Test remove.

    alias StackHash!(uint, uint) mySh2;
    auto foo = mySh2(7);
    for(uint i = 0; i < 200; i++) {
        foo[i] = i;
    }
    assert(foo.length == 200);
    for(uint i = 0; i < 200; i += 2) {
        foo.remove(i);
    }
    foreach(i; 20..200) {
        foo.remove(i);
    }
    for(uint i = 0; i < 20; i++) {
        if(i & 1) {
            assert(*(i in foo) == i);
        } else {
            assert(!(i in foo));
        }
    }
    auto vals = toArray(foo.values);
    assert(foo.length == 10);
    assert(vals.qsort == [1U, 3, 5, 7, 9, 11, 13, 15, 17, 19]);

    writeln("Passed StackHash test.");
}

/**A hash set that allocates its memory on TempAlloc.  Good for building a
 * temporary set that will not escape the current scope.
 *
 * To avoid TempAlloc memory leaks, use mixin(newFrame).
 *
 * Examples:
 * ---
 * mixin(newFrame);  // To make sure all memory gets freed at end of scope.
 * auto ss = StackSet!(uint)(5);
 * foreach(i; 0..5) {
 *     ss.insert(i);
 * }
 * assert(3 in ss);
 * ---
 */
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

    Unqual!(K)[] rKeys;
    Node*[] rNext;
    TempAlloc.State TAState;
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
            hash_t hash = typeid(K).getHash(&key);
        }
        hash %= rNext.length;
        return hash;
    }

public:
    /**Due to the nature of TempAlloc, you must specify on object creation
     * the approximate number of elements your set will have.  Too large a
     * number will waste space and incur poor cache performance.  Too low a
     * number will make this struct perform like a linked list.  Generally,
     * if you're building a set from some other range, some fraction of the
     * size of that range is a good guess.*/
    this(size_t nElem) {
        // Obviously, the caller can never mean zero, because this struct
        // can't work at all with nElem == 0, so assume it's a mistake and fix
        // it here.
        if(nElem == 0)
            nElem++;
        TAState = TempAlloc.getState;
        rNext = newStack!(Node*)(nElem, TAState);
        rKeys = newStack!(Unqual!(K))(nElem, TAState);
        usedSentinel = cast(Node*) rNext.ptr;
        foreach(ref root; rKeys) {
            root = K.init;
        }
        foreach(ref root; rNext) {
            root = usedSentinel;
        }
    }

    ///
    void insert(K key) {
        hash_t hash = getHash(key);

        if(rNext[hash] == usedSentinel) {
            rKeys[hash] = key;
            rNext[hash] = null;
            _length++;
            return;
        } else if(rKeys[hash] == key) {
            return;
        } else {  // Collision.  Start chaining.
            Node** next = &(rNext[hash]);
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

    /**Returns a forward range of the elements of this struct.  The range's
     * lifetime must not exceed the lifetime of this object.*/
    HashRange!(K, typeof(this)) elems() {
        auto ret = typeof(return)(&this);
        return ret;
    }

    ///
    bool opIn_r(K key) {
        hash_t hash = getHash(key);

        if(rNext[hash] == usedSentinel) {
            return false;
        } else if(rKeys[hash] == key) {
            return true;
        } else {  // Collision.  Start chaining.
            Node* next = rNext[hash];
            while(next !is null) {
                if(next.key == key) {
                    return true;
                }
                next = next.next;
            }
            return false;
        }
   }

    ///
    void remove(K key) {
        hash_t hash = getHash(key);

        Node** next = &(rNext[hash]);
        if(rNext[hash] == usedSentinel) {
            return;
        } else if(rKeys[hash] == key) {
            _length--;
            if(rNext[hash] is null) {
                rKeys[hash] = K.init;
                rNext[hash] = usedSentinel;
                return;
            } else {
                rKeys[hash] = (**next).key;
                rNext[hash] = (**next).next;
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

    ///
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
    assert(toArray(set.elems).qsort == seq(0U, 20U));

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

    foreach(elem; set.elems) {
        contents ~= elem;
    }
    assert(contents.qsort == [1U,3,5,7,9,11,13,15,17,19]);
    writeln("Passed StackSet test.");
}
