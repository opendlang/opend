module automem.ref_counted;

import automem.traits: isAllocator;
import automem.test_utils: TestUtils;
import automem.unique: Unique;
import std.experimental.allocator: theAllocator, processAllocator;

version(unittest) {
    import unit_threaded;
    import test_allocator: TestAllocator;
}

mixin TestUtils;

struct RefCounted(Type, Allocator = typeof(theAllocator)) if(isAllocator!Allocator) {

    import std.traits: hasMember;

    enum isSingleton = hasMember!(Allocator, "instance");
    enum isTheAllocator = is(Allocator == typeof(theAllocator));
    enum isGlobal = isSingleton || isTheAllocator;

    static if(isGlobal)
        /**
           The allocator is a singleton, so no need to pass it in to the
           constructor
        */
        this(Args...)(auto ref Args args) {
            this.makeObject!args();
        }
    else
        /**
           Non-singleton allocator, must be passed in
        */
        this(Args...)(Allocator allocator, auto ref Args args) {
            _allocator = allocator;
            this.makeObject!args();
        }

    this(this) {
        assert(_impl !is null);
        inc;
    }

    ~this() {
        release;
    }

    /**
       Assign to an lvalue RefCounted
    */
    void opAssign(ref RefCounted other) {

        if (_impl == other._impl)
            return;

        if(_impl !is null) {
            release;
        }
        static if(!isGlobal)
            _allocator = other._allocator;

        _impl = other._impl;
        inc;
    }

    /**
       Assign to an rvalue RefCounted
     */
    void opAssign(RefCounted other) {
        import std.algorithm: swap;
        swap(_impl, other._impl);
        static if(!isGlobal)
            swap(_allocator, other._allocator);
    }

    /**
       Dereference the smart pointer and yield a reference
       to the contained type.
     */
    ref auto opUnary(string s)() inout if (s == "*") {
        return _impl._get;
    }

    // Prevent opSlice and opIndex from being hidden by Impl*.
    // This comment is deliberately not DDOC.
    auto ref opSlice(A...)(auto ref A args)
    if (__traits(compiles, Type.init.opSlice(args)))
    {
        return _impl._get.opSlice(args);
    }
    // ditto
    auto ref opIndex(A...)(auto ref A args)
    if (__traits(compiles, Type.init.opIndex(args)))
    {
        return _impl._get.opIndex(args);
    }
    // ditto
    auto ref opIndexAssign(A...)(auto ref A args)
    if (__traits(compiles, Type.init.opIndexAssign(args)))
    {
        return _impl._get.opIndexAssign(args);
    }

    alias _impl this;

private:

    static struct Impl {

        static if(is(Type == class)) {

            align ((void*).alignof)
            void[__traits(classInstanceSize, Type)] _rawMemory;

        } else
            Type _object;

        static if(is(Type == shared))
            shared size_t _count;
        else
            size_t _count;

        static if (is(Type == class)) {
            inout(Type) _get() inout {
                return cast(inout(Type))&_rawMemory[0];
            }

            inout(shared(Type)) _get() inout shared {
                return cast(inout(shared(Type)))&_rawMemory[0];
            }
        } else {
            ref inout(Type) _get() inout {
                return _object;
            }

            ref inout(shared(Type)) _get() inout shared {
                return _object;
            }
        }

        alias _get this;
    }

    static if(isSingleton)
        alias _allocator = Allocator.instance;
    else static if(isTheAllocator) {
        static if (is(Type == shared))
            // 'processAllocator' should be used for allocating
            // memory shared across threads
            alias _allocator = processAllocator;
        else
            alias _allocator = theAllocator;
    }
    else
        Allocator _allocator;

    static if(is(Type == shared))
        alias ImplType = shared Impl;
    else
        alias ImplType = Impl;

    public ImplType* _impl; // public or alias this doesn't work

    void allocateImpl() {
        import std.experimental.allocator: make;
        import std.traits: hasIndirections;

        _impl = cast(typeof(_impl))_allocator.allocate(Impl.sizeof);
        _impl._count= 1;

        static if (is(Type == class)) {
            // class representation:
            // void* classInfoPtr
            // void* monitorPtr
            // []    interfaces
            // T...  members
            import core.memory: GC;
            if (!(typeid(Type).m_flags & TypeInfo_Class.ClassFlags.noPointers))
                // members have pointers: we have to watch the monitor
                // and all members; skip the classInfoPtr
                GC.addRange(&_impl._rawMemory[(void*).sizeof],
                        __traits(classInstanceSize, Type) - (void*).sizeof);
            else
                // representation doesn't have pointers, just watch the
                // monitor pointer; skip the classInfoPtr
                GC.addRange(&_impl._rawMemory[(void*).sizeof], (void*).sizeof);
        } else static if (hasIndirections!Type) {
            import core.memory: GC;
            GC.addRange(&_impl._object, Type.sizeof);
        }
    }

    void release() {
        import std.traits : hasIndirections;
        import core.memory : GC;
        import automem.utils : destruct;
        if(_impl is null) return;
        assert(_impl._count > 0, "Trying to release a RefCounted but ref count is 0 or less");

        dec;

        if(_impl._count == 0) {
            destruct(_impl._get);
            static if (is(Type == class)) {
                GC.removeRange(&_impl._rawMemory[(void*).sizeof]);
            } else static if (hasIndirections!Type) {
                GC.removeRange(&_impl._object);
            }
            auto mem = cast(void*)_impl;
            _allocator.deallocate(() @trusted { return mem[0 .. Impl.sizeof]; }());
        }
    }

    void inc() {
        static if(is(Type == shared)) {
            import core.atomic: atomicOp;
            _impl._count.atomicOp!"+="(1);
        } else
            ++_impl._count;

    }

    void dec() {
        static if(is(Type == shared)) {
            import core.atomic: atomicOp;
            _impl._count.atomicOp!"-="(1);
        } else
            --_impl._count;
    }

}

private template makeObject(args...)
{
    void makeObject(Type, A)(ref RefCounted!(Type, A) rc) @trusted {
        import std.conv: emplace;
        import std.functional : forward;

        rc.allocateImpl;

        static if(is(Type == class))
            emplace!Type(rc._impl._rawMemory, forward!args);
        else
            emplace(&rc._impl._object, forward!args);
    }
}

@("struct test allocator no copies")
@system unittest {
    auto allocator = TestAllocator();
    {
        auto ptr = RefCounted!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}

@("struct test allocator one lvalue assignment")
@system unittest {
    auto allocator = TestAllocator();
    {
        auto ptr1 = RefCounted!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);
        RefCounted!(Struct, TestAllocator*) ptr2;
        ptr2 = ptr1;
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}

@("struct test allocator one rvalue assignment test allocator")
@system unittest {
    auto allocator = TestAllocator();
    {
        RefCounted!(Struct, TestAllocator*) ptr;
        ptr = RefCounted!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}

@("struct test allocator one rvalue assignment mallocator")
@system unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    {
        RefCounted!(Struct, Mallocator) ptr;
        ptr = RefCounted!(Struct, Mallocator)(5);
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}


@("struct test allocator one lvalue copy constructor")
@system unittest {
    auto allocator = TestAllocator();
    {
        auto ptr1 = RefCounted!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);
        auto ptr2 = ptr1;
        Struct.numStructs.shouldEqual(1);

        ptr1.i.shouldEqual(5);
        ptr2.i.shouldEqual(5);
    }
    Struct.numStructs.shouldEqual(0);
}

@("struct test allocator one rvalue copy constructor")
@system unittest {
    auto allocator = TestAllocator();
    {
        auto ptr = RefCounted!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}

@("many copies made")
@system unittest {
    auto allocator = TestAllocator();

    // helper function for intrusive testing, in case the implementation
    // ever changes
    size_t refCount(T)(ref T ptr) {
        return ptr._impl._count;
    }

    {
        auto ptr1 = RefCounted!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);

        auto ptr2 = ptr1;
        Struct.numStructs.shouldEqual(1);

        {
            auto ptr3 = ptr2;
            Struct.numStructs.shouldEqual(1);

            refCount(ptr1).shouldEqual(3);
            refCount(ptr2).shouldEqual(3);
            refCount(ptr3).shouldEqual(3);
        }

        Struct.numStructs.shouldEqual(1);
        refCount(ptr1).shouldEqual(2);
        refCount(ptr2).shouldEqual(2);

        auto produce() {
            return RefCounted!(Struct, TestAllocator*)(&allocator, 3);
        }

        ptr1 = produce;
        Struct.numStructs.shouldEqual(2);
        refCount(ptr1).shouldEqual(1);
        refCount(ptr2).shouldEqual(1);

        ptr1.twice.shouldEqual(6);
        ptr2.twice.shouldEqual(10);
    }

    Struct.numStructs.shouldEqual(0);
}

@("default allocator")
@system unittest {
    {
        auto ptr = RefCounted!Struct(5);
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}

// FIXME: Github #13
// @("default allocator (shared)")
// @system unittest {
//     {
//         auto ptr = RefCounted!(shared SharedStruct)(5);
//         SharedStruct.numStructs.shouldEqual(1);
//     }
//     SharedStruct.numStructs.shouldEqual(0);
// }

@("deref")
@system unittest {
    auto allocator = TestAllocator();
    auto rc1 = RefCounted!(int, TestAllocator*)(&allocator, 5);

    (*rc1).shouldEqual(5);
    auto rc2 = rc1;
    *rc2 = 42;
    (*rc1).shouldEqual(42);
}

@("swap")
@system unittest {
    import std.algorithm: swap;
    RefCounted!(int, TestAllocator*) rc1, rc2;
    swap(rc1, rc2);
}

@("phobos bug 6606")
@system unittest {

    union U {
       size_t i;
       void* p;
    }

    struct S {
       U u;
    }

    alias SRC = RefCounted!(S, TestAllocator*);
}

@("phobos bug 6436")
@system unittest
{
    static struct S {
        this(ref int val, string file = __FILE__, size_t line = __LINE__) {
            val.shouldEqual(3, file, line);
            ++val;
        }
    }

    auto allocator = TestAllocator();
    int val = 3;
    auto s = RefCounted!(S, TestAllocator*)(&allocator, val);
    val.shouldEqual(4);
}

@("assign from T")
@system unittest {
    import std.experimental.allocator.mallocator: Mallocator;

    {
        auto a = RefCounted!(Struct, Mallocator)(3);
        Struct.numStructs.shouldEqual(1);

        *a = Struct(5);
        Struct.numStructs.shouldEqual(1);
        (*a).shouldEqual(Struct(5));

        RefCounted!(Struct, Mallocator) b;
        b = a;
        (*b).shouldEqual(Struct(5));
        Struct.numStructs.shouldEqual(1);
    }

    Struct.numStructs.shouldEqual(0);
}

@("assign self")
@system unittest {
    auto allocator = TestAllocator();
    {
        auto a = RefCounted!(Struct, TestAllocator*)(&allocator, 1);
        a = a;
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}

// FIXME: Github #13
// @("SharedStruct")
// @system unittest {
//     auto allocator = TestAllocator();
//     {
//         auto ptr = RefCounted!(shared SharedStruct, TestAllocator*)(&allocator, 5);
//         SharedStruct.numStructs.shouldEqual(1);
//     }
//     SharedStruct.numStructs.shouldEqual(0);
// }

@("@nogc @safe")
@safe @nogc unittest {

    auto allocator = SafeAllocator();

    {
        const ptr = RefCounted!(NoGcStruct, SafeAllocator)(SafeAllocator(), 6);
        assert(ptr.i == 6);
        assert(NoGcStruct.numStructs == 1);
    }

    assert(NoGcStruct.numStructs == 0);
}


@("const object")
@system unittest {
    auto allocator = TestAllocator();
    auto ptr1 = RefCounted!(const Struct, TestAllocator*)(&allocator, 5);
}


@("theAllocator")
@system unittest {
    import std.experimental.allocator: allocatorObject, dispose;

    auto allocator = TestAllocator();
    auto oldAllocator = theAllocator;
    scope(exit) {
        allocator.dispose(theAllocator);
        theAllocator = oldAllocator;
    }
    theAllocator = allocatorObject(allocator);

    {
        auto ptr = RefCounted!Struct(42);
        (*ptr).shouldEqual(Struct(42));
        Struct.numStructs.shouldEqual(1);
    }

    Struct.numStructs.shouldEqual(0);
}

// FIXME: Github #13
// @("threads Mallocator")
// @system unittest {
//     import std.experimental.allocator.mallocator: Mallocator;
//     static assert(__traits(compiles, sendRefCounted!Mallocator(7)));
// }

// FIXME: Github #13
// @("threads SafeAllocator by value")
// @system unittest {
//     // can't even use TestAllocator because it has indirections
//     // can't pass by pointer since it's an indirection
//     auto allocator = SafeAllocator();
//     static assert(__traits(compiles, sendRefCounted!(SafeAllocator)(allocator, 7)));
// }

// FIXME: Github #13
// @("threads SafeAllocator by shared pointer")
// @system unittest {
//     // can't even use TestAllocator because it has indirections
//     // can't only pass by pointer if shared
//     auto allocator = shared SafeAllocator();
//     static assert(__traits(compiles, sendRefCounted!(shared SafeAllocator*)(&allocator, 7)));
// }

auto refCounted(Type, Allocator)(Unique!(Type, Allocator) ptr) {

    RefCounted!(Type, Allocator) ret;

    static if(!ptr.isGlobal)
        ret._allocator = ptr.allocator;

    ret.allocateImpl;
    *ret = *ptr;

    return ret;
}

@("Construct RefCounted from Unique")
@system unittest {
    import automem.unique: Unique;
    auto allocator = TestAllocator();
    auto ptr = refCounted(Unique!(int, TestAllocator*)(&allocator, 42));
    (*ptr).shouldEqual(42);
}

@("RefCounted with class")
@system unittest {
    auto allocator = TestAllocator();
    {
        writelnUt("Creating ptr");
        auto ptr = RefCounted!(Class, TestAllocator*)(&allocator, 33);
        (*ptr).i.shouldEqual(33);
        Class.numClasses.shouldEqual(1);
    }
    Class.numClasses.shouldEqual(0);
}

@("@nogc class destructor")
@nogc unittest {

    auto allocator = SafeAllocator();

    {
        const ptr = Unique!(NoGcClass, SafeAllocator)(SafeAllocator(), 6);
        // shouldEqual isn't @nogc
        assert(ptr.i == 6);
        assert(NoGcClass.numClasses == 1);
    }

    assert(NoGcClass.numClasses == 0);
}

@("RefCounted opSlice and opIndex")
@system unittest {
    import std.mmfile: MmFile;
    auto file = RefCounted!MmFile(null, MmFile.Mode.readWriteNew, 120, null);
    // The type of file[0] should be ubyte, not Impl.
    static assert(is(typeof(file[0]) == typeof(MmFile.init[0])));
    // opSlice should result in void[] not Impl[].
    static assert(is(typeof(file[0 .. size_t.max]) == typeof(MmFile.init[0 .. size_t.max])));
    ubyte[] data = cast(ubyte[]) file[0 .. cast(size_t) file.length];
    immutable ubyte b = file[1];
    file[1] = cast(ubyte) (b + 1);
    assert(data[1] == cast(ubyte) (b + 1));
}

version(unittest):

void sendRefCounted(Allocator, Args...)(Args args) {
    import std.concurrency: spawn, send;

    auto tid = spawn(&threadFunc);
    auto ptr = RefCounted!(shared SharedStruct, Allocator)(args);

    tid.send(ptr);
}

void threadFunc() {

}
