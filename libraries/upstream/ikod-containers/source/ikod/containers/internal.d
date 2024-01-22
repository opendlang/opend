module ikod.containers.internal;

private import std.typecons;
private import std.traits;

template StoredType(T)
{
    static if ( is (T==immutable) || is(T==const) )
    {
        static if ( is(T==class) )
        {
            alias StoredType = Rebindable!T;
        }
        else
        {
            alias StoredType = Unqual!T;
        }
    }
    else
    {
        alias StoredType = T;
    }
}

import std.experimental.logger;

debug(cachetools) @safe @nogc
{
    package void safe_tracef(A...)(string f, scope A args, string file = __FILE__, int line = __LINE__) @safe @nogc
    {
        bool osx,ldc;
        version(OSX)
        {
            osx = true;
        }
        version(LDC)
        {
            ldc = true;
        }
        if (!osx || !ldc)
        {
            // this can fail on pair ldc2/osx, see https://github.com/ldc-developers/ldc/issues/3240
            import core.thread;
            debug (cachetools) try
            {
                () @trusted @nogc {tracef("[%x] %s:%d " ~ f, Thread.getThis().id(), file, line, args);}();
            }
            catch(Exception e)
            {
                () @trusted @nogc nothrow {try{errorf("[%x] %s:%d Exception: %s", Thread.getThis().id(), file, line, e);}catch(Throwable) {}}();
            }
        }
    }
}

bool UseGCRanges(T)() {
    return hasIndirections!T;
}

bool UseGCRanges(Allocator, T, bool GCRangesAllowed)()
{
    import std.experimental.allocator.gc_allocator;
    return !is(Allocator==GCAllocator) && hasIndirections!T && GCRangesAllowed;
}

bool UseGCRanges(Allocator, K, V, bool GCRangesAllowed)()
{
    import std.experimental.allocator.gc_allocator;

    return  !is(Allocator == GCAllocator) && (hasIndirections!K || hasIndirections!V ) && GCRangesAllowed;
}

///
/// Return true if it is worth to store values inline in hash table
/// V footprint should be small enough
///
package bool SmallValueFootprint(V)() {
    import std.traits;

    static if (isNumeric!V || isSomeString!V || isSomeChar!V || isPointer!V) {
        return true;
    }
    else static if (is(V == struct) && V.sizeof <= (void*).sizeof) {
        return true;
    }
    else static if (is(V == class) && __traits(classInstanceSize, V) <= (void*).sizeof) {
        return true;
    }
    else
        return false;
}
