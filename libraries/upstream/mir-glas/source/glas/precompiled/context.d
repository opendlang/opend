/++
Copyright: Copyright © 2016-, Ilya Yaroshenko.
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko
+/
module glas.precompiled.context;

import glas.internal.memory;

package(glas) __gshared uint c1;
package(glas) __gshared uint c2;
package(glas) __gshared uint line;
package(glas) __gshared uint initialized;
package(glas) __gshared void[] _memory;

/// Cache Information
pragma(LDC_no_typeinfo)
package struct Cache
{
    /// Cache size in KBs
    uint size;
    /// Ways of associativity. Equals `associative.max` if cache is fully associative.
    ushort associative;
    /// Cache line in KBs
    ushort line;
    /// CPU cores per cache
    ubyte cores;
    /// `true` if cache is inclusive of lower cache levels.
    bool inclusive;
}

package nothrow @nogc extern(C) 
{
    void cpuid_init();
@trusted:
    uint cpuid_cores();
    const(Cache)[] cpuid_dCache();
    const(Cache)[] cpuid_uCache();
}

/++
Initialize GLAS Context. Optional.
+/
pragma(inline, false)
export extern(C) nothrow @nogc void glas_init()
{
    if(initialized)
        return;
    cpuid_init();
    auto dc = cpuid_dCache;
    auto uc = cpuid_uCache;

    while (uc.length && uc[$-1].size > (1024 * 64)) // > 64 MB is CPU memory
    {
        uc = uc[0..$-1];
    }

    if (dc.length)
    {
        c1 = dc[0].size;
        line = dc[0].line;
        dc = dc[1..$];
    }
    else
    if (uc.length)
    {
        c1 = uc[0].size;
        line = uc[0].line;
        uc = uc[1..$];
    }
    else
    {
        c1 = 16;
    }

    if (uc.length)
    {
        c2 = uc[$-1].size;
    }
    else
    if (dc.length)
    {
        c2 = dc[$-1].size;
    }
    else
    {
        c1 = 256;
    }

    c1 <<= 10;
    c2 <<= 10;
    if (line == 0)
        line = 64;
    initialized = true;
}

import ldc.attributes : fastmath;
@fastmath:

/++
Releases memory and closes threads.
Optional.
+/
export extern(C) void glas_release()
{
    if (_memory !is null)
        deallocate(_memory);
}

// Returns: reused unaligned memory chunk
pragma(inline, true)
package(glas) nothrow @nogc void[] memory(size_t size)
{
    if (_memory.length < size)
    {
        auto f = _memory.length << 1;
        if (f > size)
            size = f;
        if (_memory !is null)
            deallocate(_memory);
        _memory = alignedAllocate(size, 4096);
    }
    return _memory[0..size];
}
