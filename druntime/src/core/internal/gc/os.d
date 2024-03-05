/**
 * Contains OS-level routines needed by the garbage collector.
 *
 * Copyright: D Language Foundation 2005 - 2021.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Walter Bright, David Friedman, Sean Kelly, Leandro Lucarella
 */
module core.internal.gc.os;

import rt.sys.config;

mixin("public import " ~ osMemoryImport ~ ";");


static if (is(typeof(os_mem_map))) // Use import from rt.sys.--os--.osmemory.d
{

}
// Previously all the OS dependent implementations was done in this file but these
// have been moved to rt/sys/--os--/osmemory.d. The implementations below
// for os_mem_map, os_mem_unmap using c library are still here for demonstration
// purposes. If an OS target is supposed to use these, it is better to take
// these implementations and move it to a separate osmemory.d file.
else static if (is(typeof(valloc))) // else version (GC_Use_Alloc_Valloc)
{
    enum HaveFork = false;

    void *os_mem_map(size_t nbytes) nothrow @nogc
    {
        return valloc(nbytes);
    }


    int os_mem_unmap(void *base, size_t nbytes) nothrow @nogc
    {
        free(base);
        return 0;
    }
}
else static if (is(typeof(malloc))) // else version (GC_Use_Alloc_Malloc)
{
    // NOTE: This assumes malloc granularity is at least (void*).sizeof.  If
    //       (req_size + PAGESIZE) is allocated, and the pointer is rounded up
    //       to PAGESIZE alignment, there will be space for a void* at the end
    //       after PAGESIZE bytes used by the GC.

    enum HaveFork = false;

    import core.internal.gc.impl.conservative.gc;


    const size_t PAGE_MASK = PAGESIZE - 1;


    void *os_mem_map(size_t nbytes) nothrow @nogc
    {   byte *p, q;
        p = cast(byte *) malloc(nbytes + PAGESIZE);
        if (!p)
            return null;
        q = p + ((PAGESIZE - ((cast(size_t) p & PAGE_MASK))) & PAGE_MASK);
        * cast(void**)(q + nbytes) = p;
        return q;
    }


    int os_mem_unmap(void *base, size_t nbytes) nothrow @nogc
    {
        free( *cast(void**)( cast(byte*) base + nbytes ) );
        return 0;
    }
}
else
{
    static assert(false, "No supported allocation methods available.");
}
