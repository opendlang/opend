/**
 * This module contains a minimal garbage collector implementation according to
 * published requirements.  This library is mostly intended to serve as an
 * example, but it is usable in applications which do not rely on a garbage
 * collector to clean up memory (ie. when dynamic array resizing is not used,
 * and all memory allocated with 'new' is freed deterministically with
 * 'delete').
 *
 * Please note that block attribute data must be tracked, or at a minimum, the
 * FINALIZE bit must be tracked for any allocated memory block because calling
 * rt_finalize on a non-object block can result in an access violation.  In the
 * allocator below, this tracking is done via a leading uint bitmask.  A real
 * allocator may do better to store this data separately, similar to the basic
 * GC.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2016.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Sean Kelly
 */
module core.internal.gc.impl.manual.gc;

import core.gc.gcinterface;

import core.internal.container.array;

import cstdlib = core.stdc.stdlib : calloc, free, malloc, realloc;
static import core.memory;

version(D_BetterC)
extern (C) void onOutOfMemoryError(void* pretend_sideffect = null) @trusted pure nothrow @nogc; /* dmd @@@BUG11461@@@ */
else
extern (C) void onOutOfMemoryError(void* pretend_sideffect = null, string file = __FILE__, size_t line = __LINE__) @trusted nothrow @nogc;

// register GC in C constructor (_STI_)
private pragma(crt_constructor) void gc_manual_ctor()
{
    _d_register_manual_gc();
}

extern(C) void _d_register_manual_gc()
{
    import core.gc.registry;
    registerGCFactory("manual", &initialize);
}

private GC initialize()
{
    import core.lifetime : emplace;

    auto gc = cast(ManualGC) cstdlib.malloc(__traits(classInstanceSize, ManualGC));
    if (!gc)
        onOutOfMemoryError();

    return emplace(gc);
}

class ManualGC : GC
{
    Array!Root roots;
    Array!Range ranges;

    this()
    {
    }

    ~this()
    {
        // TODO: cannot free as memory is overwritten and
        //  the monitor is still read in rt_finalize (called by destroy)
        // cstdlib.free(cast(void*) this);
    }

    void enable()
    {
    }

    void disable()
    {
    }

    void collect() nothrow
    {
    }

    void collectNoStack() nothrow
    {
    }

    void minimize() nothrow
    {
    }

    uint getAttr(void* p) nothrow
    {
        return 0;
    }

    uint setAttr(void* p, uint mask) nothrow
    {
        return 0;
    }

    uint clrAttr(void* p, uint mask) nothrow
    {
        return 0;
    }

    void* malloc(size_t size, uint bits, const TypeInfo ti) nothrow @system
    {
        void* p = cstdlib.malloc(size + spaceForMetainfo);
        updateMetainfoBlock(null, p, size, ti);

        if (size && p is null)
            onOutOfMemoryError();
        return p + spaceForMetainfo;
    }

    BlkInfo qalloc(size_t size, uint bits, const scope TypeInfo ti) nothrow @system
    {
        BlkInfo retval;
        retval.base = malloc(size, bits, ti);
        retval.size = size;
        retval.attr = bits;
        return retval;
    }

    void* calloc(size_t size, uint bits, const TypeInfo ti) nothrow @system
    {
        void* p = cstdlib.calloc(1, size + spaceForMetainfo);
        updateMetainfoBlock(null, p, size, ti);

        if (size && p is null)
            onOutOfMemoryError();
        return p + spaceForMetainfo;
    }

    void* realloc(void* p, size_t size, uint bits, const TypeInfo ti) nothrow @system
    {
        updateMetainfoBlock(p, null, 0, null); // free the old block to ensure we never refer to the thing after free
        p = cstdlib.realloc(p, size + spaceForMetainfo);

        // if realloc fails we're broken uh oh but that's fatal to druntime anyway
        if (size && p is null)
            onOutOfMemoryError();

        updateMetainfoBlock(null, p, size, ti); // alloc the new block

        return p + spaceForMetainfo;
    }

    size_t extend(void* p, size_t minsize, size_t maxsize, const TypeInfo ti) nothrow
    {
        return 0;
    }

    size_t reserve(size_t size) nothrow
    {
        return 0;
    }

    void free(void* p) nothrow @nogc
    {
        updateMetainfoBlock(p, null, 0, null);
        cstdlib.free(p);
    }

    /**
     * Determine the base address of the block containing p.  If p is not a gc
     * allocated pointer, return null.
     */
    void* addrOf(void* p) nothrow @nogc
    {
        // __delete depends on this returning the same thing malloc returned
        if(p is null)
            return null;
        MetainfoBlock* b = rootMeta;
        while(b !is null) {
            if(b.contains(p))
                return b;
            b = b.next;
        }
        return null;
    }

    /**
     * Determine the allocated size of pointer p.  If p is an interior pointer
     * or not a gc allocated pointer, return 0.
     */
    size_t sizeOf(void* p) nothrow @nogc
    {
        return 0;
    }

    // metadata to make __delete possible
    private void updateMetainfoBlock(void* oldPtr, void* newPtr, size_t size, const TypeInfo ti) nothrow @nogc {
        if(oldPtr is null && newPtr is null)
            return;

        auto oldBlock = cast(MetainfoBlock*) addrOf(oldPtr);
        auto newBlock = cast(MetainfoBlock*) newPtr;

        // three cases left:
        if(oldBlock is null && newBlock !is null) {
            // malloc, add it to the list
            newBlock.size = size;
            cast() newBlock.ti = cast() ti;

            newBlock.prev = null;
            newBlock.next = rootMeta;
            rootMeta = newBlock;
        } else if(oldBlock !is null && newBlock is null) {
            // free, remove it from the list
            auto p = oldBlock.prev;
            auto n = oldBlock.next;
            if(p is null)
                rootMeta = n;
            else {
                p.next = n;
                if(n)
                    n.prev = p;
            }
        } else {
            // should never happen since we treat realloc  as free / malloc in two steps
            assert(0);
        }
    }
    private struct MetainfoBlock {
        MetainfoBlock* prev;
        MetainfoBlock* next;
        size_t size;
        const TypeInfo ti;

        bool contains(void* p) @nogc nothrow @system {
            void* t = cast(void*) &this;
            return p >= t && p < t+size;
        }
    }
    private MetainfoBlock* rootMeta;
    private enum spaceForMetainfo = MetainfoBlock.sizeof;
    // done


    /**
     * Determine the base address of the block containing p.  If p is not a gc
     * allocated pointer, return null.
     */
    BlkInfo query(void* p) nothrow
    {
        return BlkInfo.init;
    }

    core.memory.GC.Stats stats() nothrow
    {
        return typeof(return).init;
    }

    core.memory.GC.ProfileStats profileStats() nothrow
    {
        return typeof(return).init;
    }

    void addRoot(void* p) nothrow @nogc
    {
        roots.insertBack(Root(p));
    }

    void removeRoot(void* p) nothrow @nogc @system
    {
        foreach (ref r; roots)
        {
            if (r is p)
            {
                r = roots.back;
                roots.popBack();
                return;
            }
        }
        assert(false);
    }

    @property RootIterator rootIter() return @nogc
    {
        return &rootsApply;
    }

    private int rootsApply(scope int delegate(ref Root) nothrow dg)
    {
        foreach (ref r; roots)
        {
            if (auto result = dg(r))
                return result;
        }
        return 0;
    }

    void addRange(void* p, size_t sz, const TypeInfo ti = null) nothrow @nogc @system
    {
        ranges.insertBack(Range(p, p + sz, cast() ti));
    }

    void removeRange(void* p) nothrow @nogc
    {
        foreach (ref r; ranges)
        {
            if (r.pbot is p)
            {
                r = ranges.back;
                ranges.popBack();
                return;
            }
        }
        assert(false);
    }

    @property RangeIterator rangeIter() return @nogc
    {
        return &rangesApply;
    }

    private int rangesApply(scope int delegate(ref Range) nothrow dg)
    {
        foreach (ref r; ranges)
        {
            if (auto result = dg(r))
                return result;
        }
        return 0;
    }

    void runFinalizers(const scope void[] segment) nothrow
    {
    }

    bool inFinalizer() nothrow
    {
        return false;
    }

    ulong allocatedInCurrentThread() nothrow
    {
        return typeof(return).init;
    }
}
