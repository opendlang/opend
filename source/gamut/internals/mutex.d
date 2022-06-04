/**
@nogc nothrow mutex with thread-safe lazy init.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)

Note: This library is re-implemented in D from FreeImage documentation (FreeImage3180.pdf).
      See the differences in DIFFERENCES.md
*/
module gamut.internals.mutex;

import core.atomic;
import core.stdc.stdlib : malloc, free;
import core.lifetime : emplace;
static import core.sync.mutex;

nothrow @nogc @safe:

/// A Mutex suitable for disabled runtime, immune from simultaneous creation.
/// A `nothrow @nogc @safe` Mutex, on top of druntime mutex.
/// Additionally, this mutex is checked against creation race.
struct Mutex
{
nothrow @nogc @safe:
    
    /// Initialize the mutex, if not existing already.
    /// This function can be called concurrently.
    void initialize() @trusted
    {
        // Is there a mutex already?
        if (atomicLoad(_mutex) !is null)
        {
            return;
        }

        // Create one mutex.
        DRuntimeMutex mtx = cast(DRuntimeMutex) malloc(__traits(classInstanceSize, DRuntimeMutex));
        emplace(mtx);

        void* p = cast(void*)mtx;
        void** here = &_mutex;
        void* ifThis = null;

        // Try to set _mutex.
        if (!cas(here, &ifThis, p))
        {
            // Another thread created _mutex first. Destroy our useless instance.
            destroyMutexInstance(mtx);
        }
    }

    ~this() @trusted
    {
        destroyMutexInstance(cast(DRuntimeMutex)_mutex);
    }

    /// Lock mutex, with lazy interlocked initialization if needed.
    void lockLazy() @trusted
    {
        initialize();
        (cast(DRuntimeMutex)_mutex).lock_nothrow();
    }

    /// Lock mutex. Rentrant.
    void lock() @trusted
    {
        (cast(DRuntimeMutex)_mutex).lock_nothrow();
    }

    /// Unlock mutex.
    void unlock() @trusted
    {
        (cast(DRuntimeMutex)_mutex).unlock_nothrow();
    }

private:
    alias DRuntimeMutex = core.sync.mutex.Mutex;
    void* _mutex = null; // should be shared, but cas() complained...

    void destroyMutexInstance(DRuntimeMutex m) @system
    {
        if (m is null)
            return;

        // In general destroying classes like this is not
        // safe, but since we know that the only base class
        // of Mutex is Object and it doesn't have a dtor
        // we can simply call the non-virtual __dtor() here.
        m.__dtor();     
        free(cast(void*)m);
    }
}

// Test reentrance.
@trusted unittest
{
    Mutex m;
    m.initialize();
    m.lock();
    m.lock();
    m.unlock();
    m.unlock();
}

// Test lazy-init.
@trusted unittest
{
    Mutex m;
    m.lockLazy();
    m.unlock();
}