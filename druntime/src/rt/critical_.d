/**
 * Implementation of support routines for synchronized blocks.
 *
 * Copyright: Copyright Digital Mars 2000 - 2011.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Walter Bright, Sean Kelly
 * Source: $(DRUNTIMESRC rt/_critical_.d)
 */

/*          Copyright Digital Mars 2000 - 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module rt.critical_;

nothrow:

import rt.monitor_, core.atomic;

import rt.sys.config;

mixin("import " ~ osMutexImport ~ ";");


extern (C) void _d_critical_init() @nogc nothrow
{
    (cast(OsMutex)gcs.mtx).create();
    head = &gcs;
}

extern (C) void _d_critical_term() @nogc nothrow
{
    // This function is only ever called by the runtime shutdown code
    // and therefore is single threaded so the following cast is fine.
    auto h = cast()head;
    for (auto p = h; p; p = p.next)
        (cast(OsMutex)p.mtx).destroy();
}

extern (C) void _d_criticalenter(D_CRITICAL_SECTION* cs)
{
    assert(cs !is null);
    ensureMutex(cast(shared(D_CRITICAL_SECTION*)) cs);
    (cast(OsMutex)cs.mtx).lockNoThrow();
}

extern (C) void _d_criticalenter2(D_CRITICAL_SECTION** pcs)
{
    version (LDC) {
    import ldc.intrinsics : llvm_expect;
    auto condition = (llvm_expect(atomicLoad!(MemoryOrder.acq)(*cast(shared) pcs) is null, false));
    } else {
    auto condition = atomicLoad!(MemoryOrder.acq)(*cast(shared) pcs) is null;
    }
    if (condition)

    {
        (cast(OsMutex)gcs.mtx).lockNoThrow();
        if (atomicLoad!(MemoryOrder.raw)(*cast(shared) pcs) is null)
        {
            auto cs = new shared D_CRITICAL_SECTION;
            (cast(OsMutex)cs.mtx).create();
            atomicStore!(MemoryOrder.rel)(*cast(shared) pcs, cs);
        }
        (cast(OsMutex)gcs.mtx).unlockNoThrow();
    }
    (*pcs).mtx.lockNoThrow();
}

extern (C) void _d_criticalexit(D_CRITICAL_SECTION* cs)
{
    assert(cs !is null);
    cs.mtx.unlockNoThrow();
}

private:

shared D_CRITICAL_SECTION* head;
shared D_CRITICAL_SECTION gcs;

struct D_CRITICAL_SECTION
{
    D_CRITICAL_SECTION* next;
    OsMutex mtx;
}

void ensureMutex(shared(D_CRITICAL_SECTION)* cs)
{
    if (atomicLoad!(MemoryOrder.acq)(cs.next) is null)
    {
        (cast(OsMutex)gcs.mtx).lockNoThrow();
        if (atomicLoad!(MemoryOrder.raw)(cs.next) is null)
        {
            (cast(OsMutex)cs.mtx).create();
            auto ohead = head;
            head = cs;
            atomicStore!(MemoryOrder.rel)(cs.next, ohead);
        }
        (cast(OsMutex)gcs.mtx).unlockNoThrow();
    }
}
