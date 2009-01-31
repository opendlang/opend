/**Allocation functions.
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

module dstats.alloc;

import std.traits, core.memory, core.thread, std.c.stdio : stderr;

version(unittest) {
    import std.stdio;
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
        static if (IsType!(Mutable!(Types[0]), bool, byte, ubyte, short, ushort,
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

///Appends to an array, deleting the old array if it has to be realloced.
void appendDelOld(T, U)(ref T[] to, U from)
if (is(Mutable!(T) : Mutable!(U)) || is(Mutable!(T[0]) : Mutable!(U))) {
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
extern(C) nothrow int fprintf(void*, in char *,...);
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

        ~this() {  // Blocks are pretty large.  Prevent false ptrs.
            ntFree(lastAlloc.ptr);
            while(nblocks > 1) {
                ntFree((inUse.pop()).space);
                nblocks--;
            }
            ntFree(space);
            while(nfree > 0) {
                ntFree(freelist.pop);
                nfree--;
            }
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
        fprintf(stderr, "TempAlloc error: Out of memory.\0".ptr);
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
    }

    static void* ntRealloc(void* ptr, size_t size, GC.BlkAttr attr) nothrow {
        try { return GC.realloc(ptr, size, attr); } catch { die(); }
    }

    static void ntFree(void* ptr) nothrow {
        try { GC.free(ptr); } catch {}
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
            if (totalAllocs == lastAlloc.length) // Should happen very infrequently.
                doubleSize(lastAlloc);
            lastAlloc[totalAllocs] = cast(void*) frameIndex;
            frameIndex = totalAllocs;
            totalAllocs++;
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
            while (totalAllocs > frameIndex + 1) {
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
            if (totalAllocs == lastAlloc.length) {
                doubleSize(lastAlloc);
            }
            lastAlloc[totalAllocs++] = ret;
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
    auto ret = newStack!(Mutable!(typeof(T[0][0])))(totalLen);

    size_t offset = 0;
    foreach(array; data) {
        ret[offset..offset + array.length] = array[0..$];
        offset += array.length;
    }
    return cast(T[0]) ret;
}

/**Creates a duplicate of an array on the TempAlloc stack.*/
auto tempdup(T)(T[] data) nothrow {
    alias Mutable!(T) U;
    U[] ret = newStack!(U)(data.length);
    ret[] = data[];
    return ret;
}

/**Same as tempdup(T[]) but uses stateCopy cached on stack by caller
 * to avoid a thread-local storage lookup.  Strictly a speed hack.*/
auto tempdup(T)(T[] data, TempAlloc.State state) nothrow {
    alias Mutable!(T) U;
    U[] ret = newStack!(U)(data.length, state);
    ret[] = data;
    return ret;
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
invariant char[] newFrame =
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
     assert(TempAlloc.getState.nblocks == 5);
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
    fprintf(stderr, "Passed TempAlloc test.\n\0".ptr);
}
