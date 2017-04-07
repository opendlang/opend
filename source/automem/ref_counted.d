module automem.ref_counted;

import automem.traits: isAllocator;
import automem.test_utils: TestUtils;
import std.experimental.allocator: theAllocator;

version(unittest) {
    import unit_threaded;
    import test_allocator: TestAllocator;
}

mixin TestUtils;


struct RefCounted(Type, Allocator = typeof(theAllocator)) if(isAllocator!Allocator) {
    import std.traits: hasMember;
    import std.typecons: Proxy;


    enum isSingleton = hasMember!(Allocator, "instance");
    enum isTheAllocator = is(Allocator == typeof(theAllocator));
    enum isGlobal = isSingleton || isTheAllocator;

    static if(is(Type == class))
        alias Pointer = Type;
    else
        alias Pointer = Type*;

    static if(isGlobal)
        /**
           The allocator is a singleton, so no need to pass it in to the
           constructor
        */
        this(Args...)(auto ref Args args) {
            makeObject(args);
        }
    else
        /**
           Non-singleton allocator, must be passed in
        */
        this(Args...)(Allocator allocator, auto ref Args args) {
            _allocator = allocator;
            makeObject(args);
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
    ref inout(Type) opUnary(string s)() inout if(s == "*") {
        return _impl._object;
    }

    alias _impl this;

private:

    static struct Impl {
        Type _object;

        static if(is(Type == shared))
            shared size_t _count;
        else
            size_t _count;

        alias _object this;
    }

    static if(isSingleton)
        alias _allocator = Allocator.instance;
    else static if(isTheAllocator)
        alias _allocator = theAllocator;
    else
        Allocator _allocator;

    public Impl* _impl; // or alias this doesn't work

    void makeObject(Args...)(auto ref Args args) @trusted {
        import std.conv: emplace;

        allocateImpl;
        emplace(&_impl._object, args);
    }

    void allocateImpl() {
        import std.experimental.allocator: make;
        import std.traits: hasIndirections;

        _impl = cast(Impl*)_allocator.allocate(Impl.sizeof);
        _impl._count= 1;

        static if (hasIndirections!Type) {
            import core.memory: GC;
            GC.addRange(&_impl._object, Type.sizeof);
        }
    }

    void release() {
        if(_impl is null) return;
        assert(_impl._count > 0);

        dec;

        if(_impl._count == 0) {
            destroy(_impl._object);
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

@("SharedStruct")
@system unittest {
    auto allocator = TestAllocator();
    {
        auto ptr = RefCounted!(shared SharedStruct, TestAllocator*)(&allocator, 5);
        SharedStruct.numStructs.shouldEqual(1);
    }
    SharedStruct.numStructs.shouldEqual(0);
}

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


@("cont object")
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
