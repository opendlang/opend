/**
 * The atomic module provides basic support for lock-free
 * concurrent programming.
 *
 * $(NOTE Use the `-preview=nosharedaccess` compiler flag to detect
 * unsafe individual read or write operations on shared data.)
 *
 * Copyright: Copyright Sean Kelly 2005 - 2016.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Sean Kelly, Alex Rønne Petersen, Manu Evans
 * Source:    $(DRUNTIMESRC core/_atomic.d)
 */

module core.atomic;

///
@safe unittest
{
    int y = 2;
    shared int x = y; // OK

    //x++; // read modify write error
    x.atomicOp!"+="(1); // OK
    //y = x; // read error with preview flag
    y = x.atomicLoad(); // OK
    assert(y == 3);
    //x = 5; // write error with preview flag
    x.atomicStore(5); // OK
    assert(x.atomicLoad() == 5);
}

import core.internal.atomic;
import core.internal.attributes : betterC;
import core.internal.traits : hasUnsharedIndirections;

pragma(inline, true): // LDC

/**
 * Specifies the memory ordering semantics of an atomic operation.
 *
 * See_Also:
 *     $(HTTP en.cppreference.com/w/cpp/atomic/memory_order)
 */
enum MemoryOrder
{
    /**
     * Not sequenced.
     * Corresponds to $(LINK2 https://llvm.org/docs/Atomics.html#monotonic, LLVM AtomicOrdering.Monotonic)
     * and C++11/C11 `memory_order_relaxed`.
     */
    raw = 0,
    /**
     * Hoist-load + hoist-store barrier.
     * Corresponds to $(LINK2 https://llvm.org/docs/Atomics.html#acquire, LLVM AtomicOrdering.Acquire)
     * and C++11/C11 `memory_order_acquire`.
     */
    acq = 2,
    /**
     * Sink-load + sink-store barrier.
     * Corresponds to $(LINK2 https://llvm.org/docs/Atomics.html#release, LLVM AtomicOrdering.Release)
     * and C++11/C11 `memory_order_release`.
     */
    rel = 3,
    /**
     * Acquire + release barrier.
     * Corresponds to $(LINK2 https://llvm.org/docs/Atomics.html#acquirerelease, LLVM AtomicOrdering.AcquireRelease)
     * and C++11/C11 `memory_order_acq_rel`.
     */
    acq_rel = 4,
    /**
     * Fully sequenced (acquire + release). Corresponds to
     * $(LINK2 https://llvm.org/docs/Atomics.html#sequentiallyconsistent, LLVM AtomicOrdering.SequentiallyConsistent)
     * and C++11/C11 `memory_order_seq_cst`.
     */
    seq = 5,
}

/**
 * Loads 'val' from memory and returns it.  The memory barrier specified
 * by 'ms' is applied to the operation, which is fully sequenced by
 * default.  Valid memory orders are MemoryOrder.raw, MemoryOrder.acq,
 * and MemoryOrder.seq.
 *
 * Params:
 *  val = The target variable.
 *
 * Returns:
 *  The value of 'val'.
 */
T atomicLoad(MemoryOrder ms = MemoryOrder.seq, T)(auto ref return scope const T val) pure nothrow @nogc @trusted
    if (!is(T == shared U, U) && !is(T == shared inout U, U) && !is(T == shared const U, U))
{
    static if (__traits(isFloating, T))
    {
        alias IntTy = IntForFloat!T;
        IntTy r = core.internal.atomic.atomicLoad!ms(cast(IntTy*)&val);
        return *cast(T*)&r;
    }
    else
        return core.internal.atomic.atomicLoad!ms(cast(T*)&val);
}

/// Ditto
T atomicLoad(MemoryOrder ms = MemoryOrder.seq, T)(auto ref return scope shared const T val) pure nothrow @nogc @trusted
    if (!hasUnsharedIndirections!T)
{
    import core.internal.traits : hasUnsharedIndirections;
    static assert(!hasUnsharedIndirections!T, "Copying `" ~ shared(const(T)).stringof ~ "` would violate shared.");

    return atomicLoad!ms(*cast(T*)&val);
}

/// Ditto
TailShared!T atomicLoad(MemoryOrder ms = MemoryOrder.seq, T)(auto ref shared const T val) pure nothrow @nogc @trusted
    if (hasUnsharedIndirections!T)
{
    // HACK: DEPRECATE THIS FUNCTION, IT IS INVALID TO DO ATOMIC LOAD OF SHARED CLASS
    // this is here because code exists in the wild that does this...

    return core.internal.atomic.atomicLoad!ms(cast(TailShared!T*)&val);
}

/**
 * Writes 'newval' into 'val'.  The memory barrier specified by 'ms' is
 * applied to the operation, which is fully sequenced by default.
 * Valid memory orders are MemoryOrder.raw, MemoryOrder.rel, and
 * MemoryOrder.seq.
 *
 * Params:
 *  val    = The target variable.
 *  newval = The value to store.
 */
void atomicStore(MemoryOrder ms = MemoryOrder.seq, T, V)(ref T val, V newval) pure nothrow @nogc @trusted
    if (!is(T == shared) && !is(V == shared))
{
    import core.internal.traits : hasElaborateCopyConstructor;
    static assert (!hasElaborateCopyConstructor!T, "`T` may not have an elaborate copy: atomic operations override regular copying semantics.");

    // resolve implicit conversions
    version (LDC)
    {
        import core.internal.traits : Unqual;
        static if (is(Unqual!T == Unqual!V))
        {
            alias arg = newval;
        }
        else
        {
            // don't construct directly from `newval`, assign instead (`alias this` etc.)
            T arg;
            arg = newval;
        }
    }
    else
    {
        T arg = newval;
    }

    static if (__traits(isFloating, T))
    {
        alias IntTy = IntForFloat!T;
        core.internal.atomic.atomicStore!ms(cast(IntTy*)&val, *cast(IntTy*)&arg);
    }
    else
        core.internal.atomic.atomicStore!ms(&val, arg);
}

/// Ditto
void atomicStore(MemoryOrder ms = MemoryOrder.seq, T, V)(ref shared T val, V newval) pure nothrow @nogc @trusted
    if (!is(T == class))
{
    static if (is (V == shared U, U))
        alias Thunk = U;
    else
    {
        import core.internal.traits : hasUnsharedIndirections;
        static assert(!hasUnsharedIndirections!V, "Copying argument `" ~ V.stringof ~ " newval` to `" ~ shared(T).stringof ~ " here` would violate shared.");
        alias Thunk = V;
    }
    atomicStore!ms(*cast(T*)&val, *cast(Thunk*)&newval);
}

/// Ditto
void atomicStore(MemoryOrder ms = MemoryOrder.seq, T, V)(ref shared T val, auto ref shared V newval) pure nothrow @nogc @trusted
    if (is(T == class))
{
    static assert (is (V : T), "Can't assign `newval` of type `shared " ~ V.stringof ~ "` to `shared " ~ T.stringof ~ "`.");

    core.internal.atomic.atomicStore!ms(cast(T*)&val, cast(V)newval);
}

/**
 * Atomically adds `mod` to the value referenced by `val` and returns the value `val` held previously.
 * This operation is both lock-free and atomic.
 *
 * Params:
 *  val = Reference to the value to modify.
 *  mod = The value to add.
 *
 * Returns:
 *  The value held previously by `val`.
 */
T atomicFetchAdd(MemoryOrder ms = MemoryOrder.seq, T)(ref return scope T val, T mod) pure nothrow @nogc @trusted
    if ((__traits(isIntegral, T) || is(T == U*, U)) && !is(T == shared))
in (atomicValueIsProperlyAligned(val))
{
    static if (is(T == U*, U))
        return cast(T)core.internal.atomic.atomicFetchAdd!ms(cast(T*)&val, mod * U.sizeof);
    else
        return core.internal.atomic.atomicFetchAdd!ms(&val, mod);
}

/// Ditto
T atomicFetchAdd(MemoryOrder ms = MemoryOrder.seq, T)(ref return scope shared T val, T mod) pure nothrow @nogc @trusted
    if (__traits(isIntegral, T) || is(T == U*, U))
in (atomicValueIsProperlyAligned(val))
{
    return atomicFetchAdd!ms(*cast(T*)&val, mod);
}

/**
 * Atomically subtracts `mod` from the value referenced by `val` and returns the value `val` held previously.
 * This operation is both lock-free and atomic.
 *
 * Params:
 *  val = Reference to the value to modify.
 *  mod = The value to subtract.
 *
 * Returns:
 *  The value held previously by `val`.
 */
T atomicFetchSub(MemoryOrder ms = MemoryOrder.seq, T)(ref return scope T val, T mod) pure nothrow @nogc @trusted
    if ((__traits(isIntegral, T) || is(T == U*, U)) && !is(T == shared))
in (atomicValueIsProperlyAligned(val))
{
    static if (is(T == U*, U))
        return cast(T)core.internal.atomic.atomicFetchSub!ms(cast(T*)&val, mod * U.sizeof);
    else
        return core.internal.atomic.atomicFetchSub!ms(&val, mod);
}

/// Ditto
T atomicFetchSub(MemoryOrder ms = MemoryOrder.seq, T)(ref return scope shared T val, T mod) pure nothrow @nogc @trusted
    if (__traits(isIntegral, T) || is(T == U*, U))
in (atomicValueIsProperlyAligned(val))
{
    return atomicFetchSub!ms(*cast(T*)&val, mod);
}

/**
* Atomically performs and AND operation between `mod` and the value referenced by `val` and returns the value `val` held previously.
* This operation is both lock-free and atomic.
*
* Params:
*  val = Reference to the value to modify.
*  mod = The value to perform and operation.
*
* Returns:
*  The value held previously by `val`.
*/
T atomicFetchAnd(MemoryOrder ms = MemoryOrder.seq, T)(ref return scope T val, T mod) pure nothrow @nogc @trusted
if ((__traits(isIntegral, T) || is(T == U*, U)) && !is(T == shared))
in (atomicValueIsProperlyAligned(val))
{
    return core.internal.atomic.atomicFetchAnd!ms(&val, mod);
}

/// Ditto
T atomicFetchAnd(MemoryOrder ms = MemoryOrder.seq, T)(ref return scope shared T val, T mod) pure nothrow @nogc @trusted
if (__traits(isIntegral, T) || is(T == U*, U))
in (atomicValueIsProperlyAligned(val))
{
    return atomicFetchAnd!ms(*cast(T*)&val, mod);
}

/**
* Atomically performs and OR operation between `mod` and the value referenced by `val` and returns the value `val` held previously.
* This operation is both lock-free and atomic.
*
* Params:
*  val = Reference to the value to modify.
*  mod = The value to perform and operation.
*
* Returns:
*  The value held previously by `val`.
*/
T atomicFetchOr(MemoryOrder ms = MemoryOrder.seq, T)(ref return scope T val, T mod) pure nothrow @nogc @trusted
if ((__traits(isIntegral, T) || is(T == U*, U)) && !is(T == shared))
in (atomicValueIsProperlyAligned(val))
{
    return core.internal.atomic.atomicFetchOr!ms(&val, mod);
}

/// Ditto
T atomicFetchOr(MemoryOrder ms = MemoryOrder.seq, T)(ref return scope shared T val, T mod) pure nothrow @nogc @trusted
if (__traits(isIntegral, T) || is(T == U*, U))
in (atomicValueIsProperlyAligned(val))
{
    return atomicFetchOr!ms(*cast(T*)&val, mod);
}

/**
* Atomically performs and XOR operation between `mod` and the value referenced by `val` and returns the value `val` held previously.
* This operation is both lock-free and atomic.
*
* Params:
*  val = Reference to the value to modify.
*  mod = The value to perform and operation.
*
* Returns:
*  The value held previously by `val`.
*/
T atomicFetchXor(MemoryOrder ms = MemoryOrder.seq, T)(ref return scope T val, T mod) pure nothrow @nogc @trusted
if ((__traits(isIntegral, T) || is(T == U*, U)) && !is(T == shared))
in (atomicValueIsProperlyAligned(val))
{
    return core.internal.atomic.atomicFetchXor!ms(&val, mod);
}

/// Ditto
T atomicFetchXor(MemoryOrder ms = MemoryOrder.seq, T)(ref return scope shared T val, T mod) pure nothrow @nogc @trusted
if (__traits(isIntegral, T) || is(T == U*, U))
in (atomicValueIsProperlyAligned(val))
{
    return atomicFetchXor!ms(*cast(T*)&val, mod);
}

/**
 * Exchange `exchangeWith` with the memory referenced by `here`.
 * This operation is both lock-free and atomic.
 *
 * Params:
 *  here         = The address of the destination variable.
 *  exchangeWith = The value to exchange.
 *
 * Returns:
 *  The value held previously by `here`.
 */
T atomicExchange(MemoryOrder ms = MemoryOrder.seq,T,V)(T* here, V exchangeWith) pure nothrow @nogc @trusted
    if (!is(T == shared) && !is(V == shared))
in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
{
    // resolve implicit conversions
    T arg = exchangeWith;

    static if (__traits(isFloating, T))
    {
        alias IntTy = IntForFloat!T;
        IntTy r = core.internal.atomic.atomicExchange!ms(cast(IntTy*)here, *cast(IntTy*)&arg);
        return *cast(shared(T)*)&r;
    }
    else
        return core.internal.atomic.atomicExchange!ms(here, arg);
}

/// Ditto
TailShared!T atomicExchange(MemoryOrder ms = MemoryOrder.seq,T,V)(shared(T)* here, V exchangeWith) pure nothrow @nogc @trusted
    if (!is(T == class) && !is(T == interface))
in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
{
    static if (is (V == shared U, U))
        alias Thunk = U;
    else
    {
        import core.internal.traits : hasUnsharedIndirections;
        static assert(!hasUnsharedIndirections!V, "Copying `exchangeWith` of type `" ~ V.stringof ~ "` to `" ~ shared(T).stringof ~ "` would violate shared.");
        alias Thunk = V;
    }
    return atomicExchange!ms(cast(T*)here, *cast(Thunk*)&exchangeWith);
}

/// Ditto
shared(T) atomicExchange(MemoryOrder ms = MemoryOrder.seq,T,V)(shared(T)* here, shared(V) exchangeWith) pure nothrow @nogc @trusted
    if (is(T == class) || is(T == interface))
in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
{
    static assert (is (V : T), "Can't assign `exchangeWith` of type `" ~ shared(V).stringof ~ "` to `" ~ shared(T).stringof ~ "`.");

    return cast(shared)core.internal.atomic.atomicExchange!ms(cast(T*)here, cast(V)exchangeWith);
}

/**
 * Performs either compare-and-set or compare-and-swap (or exchange).
 *
 * There are two categories of overloads in this template:
 * The first category does a simple compare-and-set.
 * The comparison value (`ifThis`) is treated as an rvalue.
 *
 * The second category does a compare-and-swap (a.k.a. compare-and-exchange),
 * and expects `ifThis` to be a pointer type, where the previous value
 * of `here` will be written.
 *
 * This operation is both lock-free and atomic.
 *
 * Params:
 *  here      = The address of the destination variable.
 *  writeThis = The value to store.
 *  ifThis    = The comparison value.
 *
 * Returns:
 *  true if the store occurred, false if not.
 */
template cas(MemoryOrder succ = MemoryOrder.seq, MemoryOrder fail = MemoryOrder.seq)
{
    /// Compare-and-set for non-shared values
    bool cas(T, V1, V2)(T* here, V1 ifThis, V2 writeThis) pure nothrow @nogc @trusted
    if (!is(T == shared) && is(T : V1))
    in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
    {
        // resolve implicit conversions
        const T arg1 = ifThis;
        T arg2 = writeThis;

        static if (__traits(isFloating, T))
        {
            alias IntTy = IntForFloat!T;
            return atomicCompareExchangeStrongNoResult!(succ, fail)(
                cast(IntTy*)here, *cast(IntTy*)&arg1, *cast(IntTy*)&arg2);
        }
        else
            return atomicCompareExchangeStrongNoResult!(succ, fail)(here, arg1, arg2);
    }

    /// Compare-and-set for shared value type
    bool cas(T, V1, V2)(shared(T)* here, V1 ifThis, V2 writeThis) pure nothrow @nogc @trusted
    if (!is(T == class) && (is(T : V1) || is(shared T : V1)))
    in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
    {
        static if (is (V1 == shared U1, U1))
            alias Thunk1 = U1;
        else
            alias Thunk1 = V1;
        static if (is (V2 == shared U2, U2))
            alias Thunk2 = U2;
        else
        {
            import core.internal.traits : hasUnsharedIndirections;
            static assert(!hasUnsharedIndirections!V2,
                          "Copying `" ~ V2.stringof ~ "* writeThis` to `" ~
                          shared(T).stringof ~ "* here` would violate shared.");
            alias Thunk2 = V2;
        }
        return cas(cast(T*)here, *cast(Thunk1*)&ifThis, *cast(Thunk2*)&writeThis);
    }

    /// Compare-and-set for `shared` reference type (`class`)
    bool cas(T, V1, V2)(shared(T)* here, shared(V1) ifThis, shared(V2) writeThis)
    pure nothrow @nogc @trusted
    if (is(T == class))
    in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
    {
        return atomicCompareExchangeStrongNoResult!(succ, fail)(
            cast(T*)here, cast(V1)ifThis, cast(V2)writeThis);
    }

    /// Compare-and-exchange for non-`shared` types
    bool cas(T, V)(T* here, T* ifThis, V writeThis) pure nothrow @nogc @trusted
    if (!is(T == shared) && !is(V == shared))
    in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
    {
        // resolve implicit conversions
        T arg1 = writeThis;

        static if (__traits(isFloating, T))
        {
            alias IntTy = IntForFloat!T;
            return atomicCompareExchangeStrong!(succ, fail)(
                cast(IntTy*)here, cast(IntTy*)ifThis, *cast(IntTy*)&writeThis);
        }
        else
            return atomicCompareExchangeStrong!(succ, fail)(here, ifThis, writeThis);
    }

    /// Compare and exchange for mixed-`shared`ness types
    bool cas(T, V1, V2)(shared(T)* here, V1* ifThis, V2 writeThis) pure nothrow @nogc @trusted
    if (!is(T == class) && (is(T : V1) || is(shared T : V1)))
    in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
    {
        static if (is (V1 == shared U1, U1))
            alias Thunk1 = U1;
        else
        {
            import core.internal.traits : hasUnsharedIndirections;
            static assert(!hasUnsharedIndirections!V1,
                          "Copying `" ~ shared(T).stringof ~ "* here` to `" ~
                          V1.stringof ~ "* ifThis` would violate shared.");
            alias Thunk1 = V1;
        }
        static if (is (V2 == shared U2, U2))
            alias Thunk2 = U2;
        else
        {
            import core.internal.traits : hasUnsharedIndirections;
            static assert(!hasUnsharedIndirections!V2,
                          "Copying `" ~ V2.stringof ~ "* writeThis` to `" ~
                          shared(T).stringof ~ "* here` would violate shared.");
            alias Thunk2 = V2;
        }
        static assert (is(T : Thunk1),
                       "Mismatching types for `here` and `ifThis`: `" ~
                       shared(T).stringof ~ "` and `" ~ V1.stringof ~ "`.");
        return cas(cast(T*)here, cast(Thunk1*)ifThis, *cast(Thunk2*)&writeThis);
    }

    /// Compare-and-exchange for `class`
    bool cas(T, V)(shared(T)* here, shared(T)* ifThis, shared(V) writeThis)
    pure nothrow @nogc @trusted
    if (is(T == class))
    in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
    {
        return atomicCompareExchangeStrong!(succ, fail)(
            cast(T*)here, cast(T*)ifThis, cast(V)writeThis);
    }
}

/**
* Stores 'writeThis' to the memory referenced by 'here' if the value
* referenced by 'here' is equal to 'ifThis'.
* The 'weak' version of cas may spuriously fail. It is recommended to
* use `casWeak` only when `cas` would be used in a loop.
* This operation is both
* lock-free and atomic.
*
* Params:
*  here      = The address of the destination variable.
*  writeThis = The value to store.
*  ifThis    = The comparison value.
*
* Returns:
*  true if the store occurred, false if not.
*/
bool casWeak(MemoryOrder succ = MemoryOrder.seq,MemoryOrder fail = MemoryOrder.seq,T,V1,V2)(T* here, V1 ifThis, V2 writeThis) pure nothrow @nogc @trusted
    if (!is(T == shared) && is(T : V1))
in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
{
    // resolve implicit conversions
    T arg1 = ifThis;
    T arg2 = writeThis;

    static if (__traits(isFloating, T))
    {
        alias IntTy = IntForFloat!T;
        return atomicCompareExchangeWeakNoResult!(succ, fail)(cast(IntTy*)here, *cast(IntTy*)&arg1, *cast(IntTy*)&arg2);
    }
    else
        return atomicCompareExchangeWeakNoResult!(succ, fail)(here, arg1, arg2);
}

/// Ditto
bool casWeak(MemoryOrder succ = MemoryOrder.seq,MemoryOrder fail = MemoryOrder.seq,T,V1,V2)(shared(T)* here, V1 ifThis, V2 writeThis) pure nothrow @nogc @trusted
    if (!is(T == class) && (is(T : V1) || is(shared T : V1)))
in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
{
    static if (is (V1 == shared U1, U1))
        alias Thunk1 = U1;
    else
        alias Thunk1 = V1;
    static if (is (V2 == shared U2, U2))
        alias Thunk2 = U2;
    else
    {
        import core.internal.traits : hasUnsharedIndirections;
        static assert(!hasUnsharedIndirections!V2, "Copying `" ~ V2.stringof ~ "* writeThis` to `" ~ shared(T).stringof ~ "* here` would violate shared.");
        alias Thunk2 = V2;
    }
    return casWeak!(succ, fail)(cast(T*)here, *cast(Thunk1*)&ifThis, *cast(Thunk2*)&writeThis);
}

/// Ditto
bool casWeak(MemoryOrder succ = MemoryOrder.seq,MemoryOrder fail = MemoryOrder.seq,T,V1,V2)(shared(T)* here, shared(V1) ifThis, shared(V2) writeThis) pure nothrow @nogc @trusted
    if (is(T == class))
in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
{
    return atomicCompareExchangeWeakNoResult!(succ, fail)(cast(T*)here, cast(V1)ifThis, cast(V2)writeThis);
}

/**
* Stores 'writeThis' to the memory referenced by 'here' if the value
* referenced by 'here' is equal to the value referenced by 'ifThis'.
* The prior value referenced by 'here' is written to `ifThis` and
* returned to the user.
* The 'weak' version of cas may spuriously fail. It is recommended to
* use `casWeak` only when `cas` would be used in a loop.
* This operation is both lock-free and atomic.
*
* Params:
*  here      = The address of the destination variable.
*  writeThis = The value to store.
*  ifThis    = The address of the value to compare, and receives the prior value of `here` as output.
*
* Returns:
*  true if the store occurred, false if not.
*/
bool casWeak(MemoryOrder succ = MemoryOrder.seq,MemoryOrder fail = MemoryOrder.seq,T,V)(T* here, T* ifThis, V writeThis) pure nothrow @nogc @trusted
    if (!is(T == shared S, S) && !is(V == shared U, U))
in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
{
    // resolve implicit conversions
    T arg1 = writeThis;

    static if (__traits(isFloating, T))
    {
        alias IntTy = IntForFloat!T;
        return atomicCompareExchangeWeak!(succ, fail)(cast(IntTy*)here, cast(IntTy*)ifThis, *cast(IntTy*)&writeThis);
    }
    else
        return atomicCompareExchangeWeak!(succ, fail)(here, ifThis, writeThis);
}

/// Ditto
bool casWeak(MemoryOrder succ = MemoryOrder.seq,MemoryOrder fail = MemoryOrder.seq,T,V1,V2)(shared(T)* here, V1* ifThis, V2 writeThis) pure nothrow @nogc @trusted
    if (!is(T == class) && (is(T : V1) || is(shared T : V1)))
in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
{
    static if (is (V1 == shared U1, U1))
        alias Thunk1 = U1;
    else
    {
        import core.internal.traits : hasUnsharedIndirections;
        static assert(!hasUnsharedIndirections!V1, "Copying `" ~ shared(T).stringof ~ "* here` to `" ~ V1.stringof ~ "* ifThis` would violate shared.");
        alias Thunk1 = V1;
    }
    static if (is (V2 == shared U2, U2))
        alias Thunk2 = U2;
    else
    {
        import core.internal.traits : hasUnsharedIndirections;
        static assert(!hasUnsharedIndirections!V2, "Copying `" ~ V2.stringof ~ "* writeThis` to `" ~ shared(T).stringof ~ "* here` would violate shared.");
        alias Thunk2 = V2;
    }
    static assert (is(T : Thunk1), "Mismatching types for `here` and `ifThis`: `" ~ shared(T).stringof ~ "` and `" ~ V1.stringof ~ "`.");
    return casWeak!(succ, fail)(cast(T*)here, cast(Thunk1*)ifThis, *cast(Thunk2*)&writeThis);
}

/// Ditto
bool casWeak(MemoryOrder succ = MemoryOrder.seq,MemoryOrder fail = MemoryOrder.seq,T,V)(shared(T)* here, shared(T)* ifThis, shared(V) writeThis) pure nothrow @nogc @trusted
    if (is(T == class))
in (atomicPtrIsProperlyAligned(here), "Argument `here` is not properly aligned")
{
    return atomicCompareExchangeWeak!(succ, fail)(cast(T*)here, cast(T*)ifThis, cast(V)writeThis);
}

/**
 * Inserts a full load/store memory fence (on platforms that need it). This ensures
 * that all loads and stores before a call to this function are executed before any
 * loads and stores after the call.
 */
void atomicFence(MemoryOrder order = MemoryOrder.seq)() pure nothrow @nogc @safe
{
    core.internal.atomic.atomicFence!order();
}

/**
 * Gives a hint to the processor that the calling thread is in a 'spin-wait' loop,
 * allowing to more efficiently allocate resources.
 */
void pause() pure nothrow @nogc @safe
{
    core.internal.atomic.pause();
}

/**
 * Performs the binary operation 'op' on val using 'mod' as the modifier.
 *
 * Params:
 *  val = The target variable.
 *  mod = The modifier to apply.
 *
 * Returns:
 *  The result of the operation.
 */
TailShared!T atomicOp(string op, T, V1)(ref shared T val, V1 mod) pure nothrow @nogc @trusted // LDC: was @safe
    if (__traits(compiles, mixin("*cast(T*)&val" ~ op ~ "mod")))
in (atomicValueIsProperlyAligned(val))
{
    // binary operators
    //
    // +    -   *   /   %   ^^  &
    // |    ^   <<  >>  >>> ~   in
    // ==   !=  <   <=  >   >=
    static if (op == "+"  || op == "-"  || op == "*"  || op == "/"   ||
                op == "%"  || op == "^^" || op == "&"  || op == "|"   ||
                op == "^"  || op == "<<" || op == ">>" || op == ">>>" ||
                op == "~"  || // skip "in"
                op == "==" || op == "!=" || op == "<"  || op == "<="  ||
                op == ">"  || op == ">=")
    {
        T get = atomicLoad!(MemoryOrder.raw, T)(val);
        mixin("return get " ~ op ~ " mod;");
    }
    else
    // assignment operators
    //
    // +=   -=  *=  /=  %=  ^^= &=
    // |=   ^=  <<= >>= >>>=    ~=
    static if (op == "+=")
    {
        T m = cast(T) mod;
        return cast(T)(atomicFetchAdd(val, m) + m);
    }
    else static if (op == "-=")
    {
        T m = cast(T) mod;
        return cast(T)(atomicFetchSub(val, m) - m);
    }
    else static if (op == "&=")
    {
        T m = cast(T) mod;
        return cast(T)(atomicFetchAnd(val, m) & m);
    }
    else static if (op == "|=")
    {
        T m = cast(T) mod;
        return cast(T)(atomicFetchOr(val, m) | m);
    }
    else static if (op == "^=")
    {
        T m = cast(T) mod;
        return cast(T)(atomicFetchXor(val, m) ^ m);
    }
    else static if (op == "*="  || op == "/=" || op == "%=" || op == "^^=" ||
                    op == "<<=" || op == ">>=" || op == ">>>=") // skip "~="
    {
        T set, get = atomicLoad!(MemoryOrder.raw, T)(val);
        do
        {
            set = get;
            mixin("set " ~ op ~ " mod;");
        } while (!casWeakByRef(val, get, set));
        return set;
    }
    else
    {
        static assert(false, "Operation not supported.");
    }
}


version (LDC)
{
    enum has64BitXCHG = true;
    enum has64BitCAS = true;

    // Enable 128bit CAS on 64bit platforms if supported.
    version (D_LP64)
    {
        version (PPC64)
            enum has128BitCAS = false;
        else
            enum has128BitCAS = true;
    }
    else
        enum has128BitCAS = false;
}
else version (D_InlineAsm_X86)
{
    enum has64BitXCHG = false;
    enum has64BitCAS = true;
    enum has128BitCAS = false;
}
else version (D_InlineAsm_X86_64)
{
    enum has64BitXCHG = true;
    enum has64BitCAS = true;
    enum has128BitCAS = true;
}
else version (GNU)
{
    import gcc.config;
    enum has64BitCAS = GNU_Have_64Bit_Atomics;
    enum has64BitXCHG = GNU_Have_64Bit_Atomics;
    enum has128BitCAS = GNU_Have_LibAtomic;
}
else
{
    enum has64BitXCHG = false;
    enum has64BitCAS = false;
    enum has128BitCAS = false;
}

private
{
    bool atomicValueIsProperlyAligned(T)(ref T val) pure nothrow @nogc @trusted
    {
        return atomicPtrIsProperlyAligned(&val);
    }

    bool atomicPtrIsProperlyAligned(T)(T* ptr) pure nothrow @nogc @safe
    {
        // NOTE: Strictly speaking, the x86 supports atomic operations on
        //       unaligned values.  However, this is far slower than the
        //       common case, so such behavior should be prohibited.
        static if (T.sizeof > size_t.sizeof)
        {
            version (X86)
            {
                // cmpxchg8b only requires 4-bytes alignment
                return cast(size_t)ptr % size_t.sizeof == 0;
            }
            else
            {
                // e.g., x86_64 cmpxchg16b requires 16-bytes alignment
                return cast(size_t)ptr % T.sizeof == 0;
            }
        }
        else
        {
            return cast(size_t)ptr % T.sizeof == 0;
        }
    }

    template IntForFloat(F)
        if (__traits(isFloating, F))
    {
        static if (F.sizeof == 4)
            alias IntForFloat = uint;
        else static if (F.sizeof == 8)
            alias IntForFloat = ulong;
        else
            static assert (false, "Invalid floating point type: " ~ F.stringof ~ ", only support `float` and `double`.");
    }

    template IntForStruct(S)
        if (is(S == struct))
    {
        static if (S.sizeof == 1)
            alias IntForFloat = ubyte;
        else static if (F.sizeof == 2)
            alias IntForFloat = ushort;
        else static if (F.sizeof == 4)
            alias IntForFloat = uint;
        else static if (F.sizeof == 8)
            alias IntForFloat = ulong;
        else static if (F.sizeof == 16)
            alias IntForFloat = ulong[2]; // TODO: what's the best type here? slice/delegates pass in registers...
        else
            static assert (ValidateStruct!S);
    }

    template ValidateStruct(S)
        if (is(S == struct))
    {
        import core.internal.traits : hasElaborateAssign;

        // `(x & (x-1)) == 0` checks that x is a power of 2.
        static assert (S.sizeof <= size_t.sizeof * 2
            && (S.sizeof & (S.sizeof - 1)) == 0,
            S.stringof ~ " has invalid size for atomic operations.");
        static assert (!hasElaborateAssign!S, S.stringof ~ " may not have an elaborate assignment when used with atomic operations.");

        enum ValidateStruct = true;
    }

    // TODO: it'd be nice if we had @trusted scopes; we could remove this...
    bool casWeakByRef(T,V1,V2)(ref T value, ref V1 ifThis, V2 writeThis) pure nothrow @nogc @trusted
    {
        return casWeak(&value, &ifThis, writeThis);
    }

    /* Construct a type with a shared tail, and if possible with an unshared
    head. */
    template TailShared(U) if (!is(U == shared))
    {
        alias TailShared = .TailShared!(shared U);
    }
    template TailShared(S) if (is(S == shared))
    {
        // Get the unshared variant of S.
        static if (is(S U == shared U)) {}
        else static assert(false, "Should never be triggered. The `static " ~
            "if` declares `U` as the unshared version of the shared type " ~
            "`S`. `S` is explicitly declared as shared, so getting `U` " ~
            "should always work.");

        static if (is(S : U))
            alias TailShared = U;
        else static if (is(S == struct))
        {
            enum implName = () {
                /* Start with "_impl". If S has a field with that name, append
                underscores until the clash is resolved. */
                string name = "_impl";
                string[] fieldNames;
                static foreach (alias field; S.tupleof)
                {
                    fieldNames ~= __traits(identifier, field);
                }
                static bool canFind(string[] haystack, string needle)
                {
                    foreach (candidate; haystack)
                    {
                        if (candidate == needle) return true;
                    }
                    return false;
                }
                while (canFind(fieldNames, name)) name ~= "_";
                return name;
            } ();
            struct TailShared
            {
                static foreach (i, alias field; S.tupleof)
                {
                    /* On @trusted: This is casting the field from shared(Foo)
                    to TailShared!Foo. The cast is safe because the field has
                    been loaded and is not shared anymore. */
                    mixin("
                        @trusted @property
                        ref " ~ __traits(identifier, field) ~ "()
                        {
                            alias R = TailShared!(typeof(field));
                            return * cast(R*) &" ~ implName ~ ".tupleof[i];
                        }
                    ");
                }
                mixin("
                    S " ~ implName ~ ";
                    alias " ~ implName ~ " this;
                ");
            }
        }
        else
            alias TailShared = S;
    }
    @safe unittest
    {
        // No tail (no indirections) -> fully unshared.

        static assert(is(TailShared!int == int));
        static assert(is(TailShared!(shared int) == int));

        static struct NoIndir { int i; }
        static assert(is(TailShared!NoIndir == NoIndir));
        static assert(is(TailShared!(shared NoIndir) == NoIndir));

        // Tail can be independently shared or is already -> tail-shared.

        static assert(is(TailShared!(int*) == shared(int)*));
        static assert(is(TailShared!(shared int*) == shared(int)*));
        static assert(is(TailShared!(shared(int)*) == shared(int)*));

        static assert(is(TailShared!(int[]) == shared(int)[]));
        static assert(is(TailShared!(shared int[]) == shared(int)[]));
        static assert(is(TailShared!(shared(int)[]) == shared(int)[]));

        static struct S1 { shared int* p; }
        static assert(is(TailShared!S1 == S1));
        static assert(is(TailShared!(shared S1) == S1));

        static struct S2 { shared(int)* p; }
        static assert(is(TailShared!S2 == S2));
        static assert(is(TailShared!(shared S2) == S2));

        // Tail follows shared-ness of head -> fully shared.

        static class C { int i; }
        static assert(is(TailShared!C == shared C));
        static assert(is(TailShared!(shared C) == shared C));

        /* However, structs get a wrapper that has getters which cast to
        TailShared. */

        static struct S3 { int* p; int _impl; int _impl_; int _impl__; }
        static assert(!is(TailShared!S3 : S3));
        static assert(is(TailShared!S3 : shared S3));
        static assert(is(TailShared!(shared S3) == TailShared!S3));

        static struct S4 { shared(int)** p; }
        static assert(!is(TailShared!S4 : S4));
        static assert(is(TailShared!S4 : shared S4));
        static assert(is(TailShared!(shared S4) == TailShared!S4));
    }
}


////////////////////////////////////////////////////////////////////////////////
// Unit Tests
////////////////////////////////////////////////////////////////////////////////


version (CoreUnittest)
{
    version (D_LP64)
    {
        enum hasDWCAS = has128BitCAS;
    }
    else
    {
        enum hasDWCAS = has64BitCAS;
    }

    void testXCHG(T)(T val) pure nothrow @nogc @trusted
    in
    {
        assert(val !is T.init);
    }
    do
    {
        T         base = cast(T)null;
        shared(T) atom = cast(shared(T))null;

        assert(base !is val, T.stringof);
        assert(atom is base, T.stringof);

        assert(atomicExchange(&atom, val) is base, T.stringof);
        assert(atom is val, T.stringof);
    }

    void testCAS(T)(T val) pure nothrow @nogc @trusted
    in
    {
        assert(val !is T.init);
    }
    do
    {
        T         base = cast(T)null;
        shared(T) atom = cast(shared(T))null;

        assert(base !is val, T.stringof);
        assert(atom is base, T.stringof);

        assert(cas(&atom, base, val), T.stringof);
        assert(atom is val, T.stringof);
        assert(!cas(&atom, base, base), T.stringof);
        assert(atom is val, T.stringof);

        atom = cast(shared(T))null;

        shared(T) arg = base;
        assert(cas(&atom, &arg, val), T.stringof);
        assert(arg is base, T.stringof);
        assert(atom is val, T.stringof);

        arg = base;
        assert(!cas(&atom, &arg, base), T.stringof);
        assert(arg is val, T.stringof);
        assert(atom is val, T.stringof);
    }

    void testLoadStore(MemoryOrder ms = MemoryOrder.seq, T)(T val = T.init + 1) pure nothrow @nogc @trusted
    {
        T         base = cast(T) 0;
        shared(T) atom = cast(T) 0;

        assert(base !is val);
        assert(atom is base);
        atomicStore!(ms)(atom, val);
        base = atomicLoad!(ms)(atom);

        assert(base is val, T.stringof);
        assert(atom is val);
    }


    void testType(T)(T val = T.init + 1) pure nothrow @nogc @safe
    {
        static if (T.sizeof < 8 || has64BitXCHG)
            testXCHG!(T)(val);
        testCAS!(T)(val);
        testLoadStore!(MemoryOrder.seq, T)(val);
        testLoadStore!(MemoryOrder.raw, T)(val);
    }

    @betterC @safe pure nothrow unittest
    {
        testType!(bool)();

        testType!(byte)();
        testType!(ubyte)();

        testType!(short)();
        testType!(ushort)();

        testType!(int)();
        testType!(uint)();
    }

    @safe pure nothrow unittest
    {

        testType!(shared int*)();

        static interface Inter {}
        static class KlassImpl : Inter {}
        testXCHG!(shared Inter)(new shared(KlassImpl));
        testCAS!(shared Inter)(new shared(KlassImpl));

        static class Klass {}
        testXCHG!(shared Klass)(new shared(Klass));
        testCAS!(shared Klass)(new shared(Klass));

        testXCHG!(shared int)(42);

        testType!(float)(0.1f);

        static if (has64BitCAS)
        {
            testType!(double)(0.1);
            testType!(long)();
            testType!(ulong)();
        }
        static if (has128BitCAS)
        {
            () @trusted
            {
                align(16) struct Big { long a, b; }

                shared(Big) atom;
                shared(Big) base;
                shared(Big) arg;
                shared(Big) val = Big(1, 2);

                assert(cas(&atom, arg, val), Big.stringof);
                assert(atom is val, Big.stringof);
                assert(!cas(&atom, arg, val), Big.stringof);
                assert(atom is val, Big.stringof);

                atom = Big();
                assert(cas(&atom, &arg, val), Big.stringof);
                assert(arg is base, Big.stringof);
                assert(atom is val, Big.stringof);

                arg = Big();
                assert(!cas(&atom, &arg, base), Big.stringof);
                assert(arg is val, Big.stringof);
                assert(atom is val, Big.stringof);
            }();
        }

        shared(size_t) i;

        atomicOp!"+="(i, cast(size_t) 1);
        assert(i == 1);

        atomicOp!"-="(i, cast(size_t) 1);
        assert(i == 0);

        shared float f = 0.1f;
        atomicOp!"+="(f, 0.1f);
        assert(f > 0.1999f && f < 0.2001f);

        static if (has64BitCAS)
        {
            shared double d = 0.1;
            atomicOp!"+="(d, 0.1);
            assert(d > 0.1999 && d < 0.2001);
        }
    }

    @betterC pure nothrow unittest
    {
        static if (has128BitCAS)
        {
            struct DoubleValue
            {
                long value1;
                long value2;
            }

            align(16) shared DoubleValue a;
            atomicStore(a, DoubleValue(1,2));
            assert(a.value1 == 1 && a.value2 ==2);

            while (!cas(&a, DoubleValue(1,2), DoubleValue(3,4))){}
            assert(a.value1 == 3 && a.value2 ==4);

            align(16) DoubleValue b = atomicLoad(a);
            assert(b.value1 == 3 && b.value2 ==4);
        }

        static if (hasDWCAS)
        {
            static struct List { size_t gen; List* next; }
            shared(List) head;
            assert(cas(&head, shared(List)(0, null), shared(List)(1, cast(List*)1)));
            assert(head.gen == 1);
            assert(cast(size_t)head.next == 1);
        }

        // https://issues.dlang.org/show_bug.cgi?id=20629
        static struct Struct
        {
            uint a, b;
        }
        shared Struct s1 = Struct(1, 2);
        atomicStore(s1, Struct(3, 4));
        assert(cast(uint) s1.a == 3);
        assert(cast(uint) s1.b == 4);
    }

    // https://issues.dlang.org/show_bug.cgi?id=20844
    static if (hasDWCAS)
    {
        debug: // tests CAS in-contract

        pure nothrow unittest
        {
            import core.exception : AssertError;

            align(16) shared ubyte[2 * size_t.sizeof + 1] data;
            auto misalignedPointer = cast(size_t[2]*) &data[1];
            size_t[2] x;

            try
                cas(misalignedPointer, x, x);
            catch (AssertError)
                return;

            assert(0, "should have failed");
        }
    }

    @betterC pure nothrow @nogc @safe unittest
    {
        int a;
        if (casWeak!(MemoryOrder.acq_rel, MemoryOrder.raw)(&a, 0, 4))
            assert(a == 4);
    }

    @betterC pure nothrow unittest
    {
        // https://issues.dlang.org/show_bug.cgi?id=17821
        {
            shared ulong x = 0x1234_5678_8765_4321;
            atomicStore(x, 0);
            assert(x == 0);
        }
        {
            struct S
            {
                ulong x;
                alias x this;
            }
            shared S s;
            s = 0x1234_5678_8765_4321;
            atomicStore(s, 0);
            assert(s.x == 0);
        }
        {
            abstract class Logger {}
            shared Logger s1;
            Logger s2;
            atomicStore(s1, cast(shared) s2);
        }
    }

    @betterC pure nothrow unittest
    {
        static struct S { int val; }
        auto s = shared(S)(1);

        shared(S*) ptr;

        // head unshared
        shared(S)* ifThis = null;
        shared(S)* writeThis = &s;
        assert(ptr is null);
        assert(cas(&ptr, ifThis, writeThis));
        assert(ptr is writeThis);

        // head shared
        shared(S*) ifThis2 = writeThis;
        shared(S*) writeThis2 = null;
        assert(cas(&ptr, ifThis2, writeThis2));
        assert(ptr is null);
    }

    // === atomicFetchAdd and atomicFetchSub operations ====
    @betterC pure nothrow @nogc @safe unittest
    {
        shared ubyte u8 = 1;
        shared ushort u16 = 2;
        shared uint u32 = 3;
        shared byte i8 = 5;
        shared short i16 = 6;
        shared int i32 = 7;

        assert(atomicOp!"+="(u8, 8) == 9);
        assert(atomicOp!"+="(u16, 8) == 10);
        assert(atomicOp!"+="(u32, 8) == 11);
        assert(atomicOp!"+="(i8, 8) == 13);
        assert(atomicOp!"+="(i16, 8) == 14);
        assert(atomicOp!"+="(i32, 8) == 15);
        version (D_LP64)
        {
            shared ulong u64 = 4;
            shared long i64 = 8;
            assert(atomicOp!"+="(u64, 8) == 12);
            assert(atomicOp!"+="(i64, 8) == 16);
        }
    }

    @betterC pure nothrow @nogc unittest
    {
        byte[10] byteArray = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19];
        ulong[10] ulongArray = [2, 4, 6, 8, 10, 12, 14, 16, 19, 20];

        {
            auto array = byteArray;
            byte* ptr = &array[0];
            byte* prevPtr = atomicFetchAdd(ptr, 3);
            assert(prevPtr == &array[0]);
            assert(*prevPtr == 1);
            assert(*ptr == 7);
        }
        {
            auto array = ulongArray;
            ulong* ptr = &array[0];
            ulong* prevPtr = atomicFetchAdd(ptr, 3);
            assert(prevPtr == &array[0]);
            assert(*prevPtr == 2);
            assert(*ptr == 8);
        }
    }

    @betterC pure nothrow @nogc @safe unittest
    {
        shared ubyte u8 = 1;
        shared ushort u16 = 2;
        shared uint u32 = 3;
        shared byte i8 = 5;
        shared short i16 = 6;
        shared int i32 = 7;

        assert(atomicOp!"-="(u8, 1) == 0);
        assert(atomicOp!"-="(u16, 1) == 1);
        assert(atomicOp!"-="(u32, 1) == 2);
        assert(atomicOp!"-="(i8, 1) == 4);
        assert(atomicOp!"-="(i16, 1) == 5);
        assert(atomicOp!"-="(i32, 1) == 6);
        version (D_LP64)
        {
            shared ulong u64 = 4;
            shared long i64 = 8;
            assert(atomicOp!"-="(u64, 1) == 3);
            assert(atomicOp!"-="(i64, 1) == 7);
        }
    }

    @betterC pure nothrow @nogc unittest
    {
        byte[10] byteArray = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19];
        ulong[10] ulongArray = [2, 4, 6, 8, 10, 12, 14, 16, 19, 20];

        {
            auto array = byteArray;
            byte* ptr = &array[5];
            byte* prevPtr = atomicFetchSub(ptr, 4);
            assert(prevPtr == &array[5]);
            assert(*prevPtr == 11);
            assert(*ptr == 3); // https://issues.dlang.org/show_bug.cgi?id=21578
        }
        {
            auto array = ulongArray;
            ulong* ptr = &array[5];
            ulong* prevPtr = atomicFetchSub(ptr, 4);
            assert(prevPtr == &array[5]);
            assert(*prevPtr == 12);
            assert(*ptr == 4); // https://issues.dlang.org/show_bug.cgi?id=21578
        }
    }

    @betterC pure nothrow @nogc @safe unittest // https://issues.dlang.org/show_bug.cgi?id=16651
    {
        shared ulong a = 2;
        uint b = 1;
        atomicOp!"-="(a, b);
        assert(a == 1);

        shared uint c = 2;
        ubyte d = 1;
        atomicOp!"-="(c, d);
        assert(c == 1);
    }

    pure nothrow @safe unittest // https://issues.dlang.org/show_bug.cgi?id=16230
    {
        shared int i;
        static assert(is(typeof(atomicLoad(i)) == int));

        shared int* p;
        static assert(is(typeof(atomicLoad(p)) == shared(int)*));

        shared int[] a;
        static if (__traits(compiles, atomicLoad(a)))
        {
            static assert(is(typeof(atomicLoad(a)) == shared(int)[]));
        }

        static struct S { int* _impl; }
        shared S s;
        static assert(is(typeof(atomicLoad(s)) : shared S));
        static assert(is(typeof(atomicLoad(s)._impl) == shared(int)*));
        auto u = atomicLoad(s);
        assert(u._impl is null);
        u._impl = new shared int(42);
        assert(atomicLoad(*u._impl) == 42);

        static struct S2 { S s; }
        shared S2 s2;
        static assert(is(typeof(atomicLoad(s2).s) == TailShared!S));

        static struct S3 { size_t head; int* tail; }
        shared S3 s3;
        static if (__traits(compiles, atomicLoad(s3)))
        {
            static assert(is(typeof(atomicLoad(s3).head) == size_t));
            static assert(is(typeof(atomicLoad(s3).tail) == shared(int)*));
        }

        static class C { int i; }
        shared C c;
        static assert(is(typeof(atomicLoad(c)) == shared C));

        static struct NoIndirections { int i; }
        shared NoIndirections n;
        static assert(is(typeof(atomicLoad(n)) == NoIndirections));
    }

    unittest // Issue 21631
    {
        shared uint si1 = 45;
        shared uint si2 = 38;
        shared uint* psi = &si1;

        assert((&psi).cas(cast(const) psi, &si2));
    }
}












/**
 * This is a D version of a partial implementation of the std::atomic template found in C++ STL.
 * https://en.cppreference.com/w/cpp/atomic/atomic
 *
 */
struct Atomic(T)
{
    private T m_val;

    /**
     * Initializes the underlying object with desired value. The initialization is not atomic.
     *
     * Params:
     *   val = desired value
     */
    this(T val) pure nothrow @nogc
    {
        m_val = val;
    }

    /** Copy constructor is disabled because an atomic cannot be passed to functions as a copy
     * and copy it around will break the whole point of an atomic.
     */
    @disable this(ref return scope Atomic rhs);

    /**
     * Atomically replaces the current value with a desired value. Memory is affected according to the value of order.
     */
    void store(MemoryOrder order = MemoryOrder.seq)(T val) pure nothrow @nogc
    {
        m_val.atomicStore!(order)(val);
    }

    /**
     * Atomically replaces the current value with a desired value.
     *
     * Params:
     *  val = desired value
     */
    void opAssign(T val) pure nothrow @nogc
    {
        store(val);
    }
    
    /**
     * Atomically load the current value.
     *
     * Params:
     *  val = desired value
     */
    alias load this;

    /**
     * Atomically replaces the current value with the result of computation involving the previous value and val.
     * The operation is read-modify-write operation.
     *
     * operator += performs atomic addition. Equivalent to return fetchAdd(arg) + arg;.
     * operator -= performs atomic subtraction. Equivalent to return fetchSub(arg) - arg;.
     * operator &= performs atomic bitwise and. Equivalent to return fetchAnd(arg) & arg;.
     * operator |= performs atomic bitwise or. Equivalent to return fetchOr(arg) | arg;.
     * operator ^= performs atomic bitwise exclusive or. Equivalent to return fetchXor(arg) ^ arg;.
     *
     * Params:
     *  val = value to perform the operation with
     *
     * Returns:
     *  The atomic value AFTER the operation
     */
    T opOpAssign(string op)(T val) pure nothrow @nogc
    {
        static if (op == "+")
        {
            return fetchAdd(val) + val;
        }
        else static if (op == "-")
        {
            return fetchSub(val) - val;
        }
        else static if (op == "&")
        {
            return fetchAnd(val) & val;
        }
        else static if (op == "|")
        {
            return fetchOr(val) | val;
        }
        else static if (op == "^")
        {
            return fetchXor(val) ^ val;
        }
        else static assert(false);
    }

    /**
    * Loads the atomic value from memory and returns it.  The memory barrier specified
    * by 'order' is applied to the operation, which is fully sequenced by
    * default.  Valid memory orders are MemoryOrder.raw, MemoryOrder.acq,
    * and MemoryOrder.seq.
    *
    * Returns:
    *  The atomic value.
    */
    T load(MemoryOrder order = MemoryOrder.seq)() pure nothrow @nogc
    {
        return m_val.atomicLoad!(order)();
    }

    /**
     * Atomically replaces the current value with the result of arithmetic addition of the atomic variable and val.
     * That is, it performs atomic post-increment. The operation is a read-modify-write operation.
     * Memory is affected according to the value of order.
     *
     * Params:
     *  val = The other argument of arithmetic addition
     *
     * Returns:
     *  The atomic value BEFORE the operation
     */
    T fetchAdd(MemoryOrder order = MemoryOrder.seq)(T val) pure nothrow @nogc
    {
        return m_val.atomicFetchAdd!(order)(val);
    }

    /**
     * Atomically replaces the current value with the result of arithmetic subtraction of the atomic variable and val.
     * That is, it performs atomic post-decrment. The operation is a read-modify-write operation.
     * Memory is affected according to the value of order.
     *
     * Params:
     *  val = The other argument of arithmetic subtraction
     *
     * Returns:
     *  The atomic value BEFORE the operation
     */
    T fetchSub(MemoryOrder order = MemoryOrder.seq)(T val) pure nothrow @nogc
    {
        return m_val.atomicFetchSub!(order)(val);
    }

    /**
     * Atomically replaces the current value with the result of bitwise AND of the the atomic value and val.
     * The operation is read-modify-write operation. Memory is affected according to the value of order.
     *
     * Params:
     *  val = The other argument of bitwise AND
     *
     * Returns:
     *  The atomic value BEFORE the operation
     */
    T fetchAnd(MemoryOrder order = MemoryOrder.seq)(T val) pure nothrow @nogc
    {
        return m_val.atomicFetchAnd!(order)(val);
    }

    /**
     * Atomically replaces the current value with the result of bitwise OR of the the atomic value and val.
     * The operation is read-modify-write operation. Memory is affected according to the value of order.
     *
     * Params:
     *  val = The other argument of bitwise OR
     *
     * Returns:
     *  The atomic value BEFORE the operation
     */
    T fetchOr(MemoryOrder order = MemoryOrder.seq)(T val) pure nothrow @nogc
    {
        return m_val.atomicFetchOr!(order)(val);
    }

    /**
     * Atomically replaces the current value with the result of bitwise XOR of the the atomic value and val.
     * The operation is read-modify-write operation. Memory is affected according to the value of order.
     *
     * Params:
     *  val = The other argument of bitwise XOR
     *
     * Returns:
     *  The atomic value BEFORE the operation
     */
    T fetchXor(MemoryOrder order = MemoryOrder.seq)(T val) pure nothrow @nogc
    {
        return m_val.atomicFetchXor!(order)(val);
    }

    /**
     * Atomically increments or decrements the current value. The operation is read-modify-write operation.
     *
     * operator ++ performs atomic pre-increment. Equivalent to return fetchAdd(1) + 1;.
     * operator ++ performs atomic pre-decrement. Equivalent to return fetchSub(1) - 1;.
     *
     * Returns:
     *  The atomic value AFTER the operation
     */
    T opUnary(string op)() pure nothrow @nogc
    {
        static if (op == "++")
        {
            return fetchAdd(1) + 1;
        }
        else static if (op == "--")
        {
            return fetchSub(1) - 1;
        }
        else static assert(false);
    }

    /**
     * Atomically increments or decrements the current value. The operation is read-modify-write operation.
     *
     * operator ++ performs atomic post-increment. Equivalent to return fetchAdd(1);.
     * operator -- performs atomic post-decrement. Equivalent to return fetchSub(1);.
     *
     * Returns:
     *  The atomic value BEFORE the operation
     */
    T opUnaryRight(string op)() pure nothrow @nogc
    {
        static if (op == "++")
        {
            return fetchAdd(1);
        }
        else static if (op == "--")
        {
            return fetchSub(1);
        }
        else static assert(false);
    }

    /**
     * Atomically replaces the underlying value with a desired value (a read-modify-write operation).
     * Memory is affected according to the value of order.
     *
     * Params:
     *  newVal = The new desired value
     *
     * Returns:
     *  The atomic value BEFORE the exchange
     */
    T exchange(MemoryOrder order = MemoryOrder.seq)(T newVal) pure nothrow @nogc
    {
        return atomicExchange!(order)(&m_val, newVal);
    }

    /**
     * Atomically compares the atomic value with that of expected. If those are bitwise-equal, replaces the former with desired
     * (performs read-modify-write operation). Otherwise, loads the actual atomic value stored into expected (performs load operation).
     *
     * compare_exchange_weak is allowed to fail spuriously, that is, acts as if atomic value != expected even if they are equal.
     * When a compare-and-exchange is in a loop, compare_exchange_weak will yield better performance on some platforms.
     *
     * Params:
     *  expected = The expected value
     *  desired = The new desired value
     *
     * Returns:
     *  true if the underlying atomic value was successfully changed, false otherwise.
     */
    bool compareExchangeWeak(MemoryOrder succ = MemoryOrder.seq, MemoryOrder fail = MemoryOrder.seq)(ref T expected, T desired) pure nothrow @nogc
    {
        return casWeak!(succ, fail)(&m_val, &expected, desired);
    }

    /**
     * Atomically compares the atomic value with that of expected. If those are bitwise-equal, replaces the former with desired
     * (performs read-modify-write operation). Otherwise, loads the actual atomic value stored into expected (performs load operation).
     *
     * Params:
     *  expected = The expected value
     *  desired = The new desired value
     *
     * Returns:
     *  true if the underlying atomic value was successfully changed, false otherwise.
     */
    bool compareExchangeStrong(MemoryOrder succ = MemoryOrder.seq, MemoryOrder fail = MemoryOrder.seq)(ref T expected, T desired) pure nothrow @nogc
    {
        return cas!(succ, fail)(&m_val, &expected, desired);
    }
}



unittest // For the entire Atomic generic struct implementation
{
    auto a = Atomic!int(0);

    // These test only test the operation and inteface, not if the operation is truly atomic

    // Test store
    a.store(2);

    // Test regular load
    int j = a.load();
    assert(j == 2);

    // Test load/store with custom memory order
    a.store!(MemoryOrder.raw)(4);
    j = a.load!(MemoryOrder.raw)();
    assert(j == 4);

    // Test fetchAdd
    j = a.fetchAdd(4);
    assert(j == 4 && a.load() == 8);

    // Test fetchSub
    j = a.fetchSub(4);
    assert(j == 8 && a.load() == 4);

    // Test fetchAnd
    a = 0xffff;
    j = a.fetchAnd(0x00ff);
    assert(j == 0xffff && a.load() == 0x00ff);

    // Test fetchOr
    a = 0xff;
    j = a.fetchOr(0xff00);
    assert(j == 0xff && a.load() == 0xffff);

    // Test fetchAnd
    a = 0xf0f0f0f0;
    j = a.fetchXor(0x0f0f0f0f);
    assert(j == 0xf0f0f0f0 && a.load() == 0xffffffff);

    // Test fetchAdd custom memory order
    a = 4;
    j = a.fetchAdd!(MemoryOrder.raw)(4);
    assert(j == 4 && a.load() == 8);

    // Test fetchSub custom memory order
    j = a.fetchSub!(MemoryOrder.raw)(4);
    assert(j == 8 && a.load() == 4);

    // Test fetchAnd custom memory order
    a = 0xffff;
    j = a.fetchAnd!(MemoryOrder.raw)(0x00ff);
    assert(j == 0xffff && a.load() == 0x00ff);

    // Test fetchOr custom memory order
    a = 0xff;
    j = a.fetchOr!(MemoryOrder.raw)(0xff00);
    assert(j == 0xff && a.load() == 0xffff);

    // Test fetchAnd custom memory order
    a = 0xf0f0f0f0;
    j = a.fetchXor!(MemoryOrder.raw)(0x0f0f0f0f);
    assert(j == 0xf0f0f0f0 && a.load() == 0xffffffff);

    // Test opAssign
    a = 3;
    j = a.load();
    assert(j == 3);

    // Test load
    assert(a == 3);

    // Test pre increment addition
    j = ++a;
    assert(j == 4 && a.load() == 4);

    // Test post increment addition
    j = a++;
    assert(j == 4 && a.load() == 5);

    // Test pre decrement subtraction
    j = --a;
    assert(j == 4 && a.load() == 4);

    j = a--;
    assert(j == 4 && a.load() == 3);

    // Test operator assign add
    j = (a += 4);
    assert(j == 7 && a.load() == 7);

    // Test operator assign sub
    j = (a -= 4);
    assert(j == 3 && a.load() == 3);

    // Test operator assign and
    a = 0xffff;
    j = (a &= 0x00ff);
    assert(j == 0x00ff && a.load() == 0x00ff);

    // Test operator assign and
    a = 0xffff;
    j = (a &= 0x00ff);
    assert(j == 0x00ff && a.load() == 0x00ff);

    // Test operator assign or
    a = 0xff;
    j = (a |= 0xff00);
    assert(j == 0xffff && a.load() == 0xffff);

    // Test operator assign xor
    a = 0xf0f0f0f0;
    j = (a ^= 0x0f0f0f0f);
    assert(j == 0xffffffff && a.load() == 0xffffffff);

    // Test exchange
    a = 3;
    j = a.exchange(10);
    assert(j == 3 && a.load() == 10);

    // Test exchange with custom memory order
    j = a.exchange!(MemoryOrder.raw)(3);
    assert(j == 10 && a.load() == 3);

    // Reset back to 10
    a = 10;

    // test compareExchangeWeak with successful assignment
    int expected = 10;
    bool res = a.compareExchangeWeak(expected, 3);
    assert(res == true && a.load() == 3);

    // test compareExchangeWeak with failed assignment result as well as custom memory order
    expected = 11;
    res = a.compareExchangeWeak!(MemoryOrder.raw, MemoryOrder.raw)(expected, 10);
    assert(res == false && a.load() == 3);

    // test compareExchangeStrong with successful assignment
    expected = 3;
    res = a.compareExchangeStrong(expected, 10);
    assert(res == true && a.load() == 10);

    // test compareExchangeStrong with false result as well as custom memory order
    expected = 3;
    res = a.compareExchangeStrong!(MemoryOrder.raw, MemoryOrder.raw)(expected, 10);
    assert(res == false && a.load() == 10);
}
