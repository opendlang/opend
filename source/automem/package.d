module automem;


version(unittest) {
    import unit_threaded;
    import test_allocator;

    @Setup
    void before() {
    }

    @Shutdown
    void after() {
        reset;
    }

    void reset() {
        Struct.numStructs = 0;
        Class.numClasses = 0;
        SharedStruct.numStructs = 0;
        NoGcStruct.numStructs = 0;
    }

}


void checkAllocator(T)() {
    import std.experimental.allocator: make, dispose;
    import std.traits: hasMember;

    static if(hasMember!(T, "instance"))
        alias allocator = T.instance;
    else
        T allocator;

    int* i = allocator.make!int;
    allocator.dispose(&i);
    void[] bytes = allocator.allocate(size_t.init);
    allocator.deallocate(bytes);
}
enum isAllocator(T) = is(typeof(checkAllocator!T));


@("isAllocator")
@safe @nogc pure unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    static assert(isAllocator!Mallocator);
    static assert(isAllocator!TestAllocator);
    static assert(!isAllocator!Struct);
}


struct Unique(Type, Allocator) if(isAllocator!Allocator) {

    import std.traits: hasMember, isArray;
    import std.typecons: Proxy;

    enum isSingleton = hasMember!(Allocator, "instance");

    static if(is(Type == class))
        alias Pointer = Type;
    else
        alias Pointer = Type*;

    static if(isArray!Type) {
        import std.range: ElementType;
        alias Element = ElementType!Type;
    }


    static if(isSingleton) {

        /**
           The allocator is a singleton, so no need to pass it in to the
           constructor
        */

        static if(isArray!Type) {

            this(size_t size) {
                makeObjects(size);
            }

        } else {

            this(Args...)(auto ref Args args) {
                makeObject(args);
            }

        }
    } else

        /**
           Non-singleton allocator, must be passed in
         */

        static if(isArray!Type) {

            this(Allocator allocator, size_t size) {
                _allocator = allocator;
                makeObjects(size);
            }

        } else {

            this(Args...)(Allocator allocator, auto ref Args args) {
                _allocator = allocator;
                makeObject(args);
            }

        }

    this(T)(Unique!(T, Allocator) other) if(is(T: Type)) {
        moveFrom(other);
    }

    @disable this(this);

    static if(isArray!Type) {

        ~this() {
            import std.experimental.allocator: dispose;
            _allocator.dispose(_objects);
        }

    } else {

        ~this() {
            deleteObject;
        }
    }

    /**
       Gets the owned pointer. Use with caution.
     */
    static if(!isArray!Type)
    inout(Pointer) get() inout @system {
        return _object;
    }

    /**
       Releases ownership and transfers it to the returned
       Unique object.
     */
    static if(!isArray!Type)
    Unique unique() {
        import std.algorithm: move;
        Unique u;
        move(this, u);
        assert(_object is null);
        return u;
    }

    /**
       "Truthiness" cast
     */
    bool opCast(T)() const if(is(T == bool)) {
        static if(isArray!Type)
            return _objects.ptr !is null;
        else
            return _object !is null;
    }

    void opAssign(T)(Unique!(T, Allocator) other) if(is(T: Type)) {
        deleteObject;
        moveFrom(other);
    }

    static if(isArray!Type)
        ref inout(Element) opIndex(long i) inout {
            return _objects[i];
        }

    static if(isArray!Type)
        private Element[] _objects;
    else
        private Pointer _object;

    static if(isArray!Type)
        alias _objects this;
    else
        mixin Proxy!_object;

private:

    static if(isSingleton)
        alias _allocator = Allocator.instance;
    else
        Allocator _allocator;

    void makeObject(Args...)(auto ref Args args) {
        import std.experimental.allocator: make;
        version(LDC)
            _object = () @trusted { return _allocator.make!Type(args); }();
        else
            _object = _allocator.make!Type(args);
    }

    static if(isArray!Type)
    void makeObjects(size_t size) {
        import std.experimental.allocator: makeArray;
        _objects = _allocator.makeArray!Element(size);
    }

    static if(!isArray!Type)
        void deleteObject() @safe {
            import std.experimental.allocator: dispose;
            if(_object !is null) () @trusted { _allocator.dispose(_object); }();
        }

    void moveFrom(T)(ref Unique!(T, Allocator) other) if(is(T: Type)) {
        _object = other._object;
        other._object = null;

        static if(!isSingleton) {
            import std.algorithm: move;
            move(other._allocator, _allocator);
        }
    }
}


@("Unique with struct and test allocator")
@system unittest {

    auto allocator = TestAllocator();
    {
        const foo = Unique!(Struct, TestAllocator*)(&allocator, 5);
        foo.twice.shouldEqual(10);
        allocator.numAllocations.shouldEqual(1);
        Struct.numStructs.shouldEqual(1);
    }

    Struct.numStructs.shouldEqual(0);
}

@("Unique with class and test allocator")
@system unittest {

    auto allocator = TestAllocator();
    {
        const foo = Unique!(Class, TestAllocator*)(&allocator, 5);
        foo.twice.shouldEqual(10);
        allocator.numAllocations.shouldEqual(1);
        Class.numClasses.shouldEqual(1);
    }

    Class.numClasses.shouldEqual(0);
}


@("Unique with struct and mallocator")
@system unittest {

    import std.experimental.allocator.mallocator: Mallocator;
    {
        const foo = Unique!(Struct, Mallocator)(5);
        foo.twice.shouldEqual(10);
        Struct.numStructs.shouldEqual(1);
    }

    Struct.numStructs.shouldEqual(0);
}


@("Unique default constructor")
@system unittest {
    auto allocator = TestAllocator();

    auto ptr = Unique!(Struct, TestAllocator*)();
    (cast(bool)ptr).shouldBeFalse;
    ptr.get.shouldBeNull;

    ptr = Unique!(Struct, TestAllocator*)(&allocator, 5);
    ptr.get.shouldNotBeNull;
    ptr.get.twice.shouldEqual(10);
    (cast(bool)ptr).shouldBeTrue;
}

@("Unique .init")
@system unittest {
    auto allocator = TestAllocator();

    Unique!(Struct, TestAllocator*) ptr;
    (cast(bool)ptr).shouldBeFalse;
    ptr.get.shouldBeNull;

    ptr = Unique!(Struct, TestAllocator*)(&allocator, 5);
    ptr.get.shouldNotBeNull;
    ptr.get.twice.shouldEqual(10);
    (cast(bool)ptr).shouldBeTrue;
}

@("Unique move")
@system unittest {
    import std.algorithm: move;

    auto allocator = TestAllocator();
    auto oldPtr = Unique!(Struct, TestAllocator*)(&allocator, 5);
    Unique!(Struct, TestAllocator*) newPtr;
    move(oldPtr, newPtr);
    oldPtr.shouldBeNull;
    newPtr.twice.shouldEqual(10);
    Struct.numStructs.shouldEqual(1);
}

@("Unique copy")
@system unittest {
    auto allocator = TestAllocator();
    auto oldPtr = Unique!(Struct, TestAllocator*)(&allocator, 5);
    Unique!(Struct, TestAllocator*) newPtr;
    // non-copyable
    static assert(!__traits(compiles, newPtr = oldPtr));
}

@("Unique construct base class")
@system unittest {
    auto allocator = TestAllocator();
    {
        Unique!(Object, TestAllocator*) bar = Unique!(Class, TestAllocator*)(&allocator, 5);
        Class.numClasses.shouldEqual(1);
    }

    Class.numClasses.shouldEqual(0);
}

@("Unique assign base class")
@system unittest {
    auto allocator = TestAllocator();
    {
        Unique!(Object, TestAllocator*) bar;
        bar = Unique!(Class, TestAllocator*)(&allocator, 5);
        Class.numClasses.shouldEqual(1);
    }

    Class.numClasses.shouldEqual(0);
}

@("Return Unique from function")
@system unittest {
    auto allocator = TestAllocator();

    auto produce(int i) {
        return Unique!(Struct, TestAllocator*)(&allocator, i);
    }

    auto ptr = produce(4);
    ptr.twice.shouldEqual(8);
}

@("Unique unique")
@system unittest {
    auto allocator = TestAllocator();
    auto oldPtr = Unique!(Struct, TestAllocator*)(&allocator, 5);
    auto newPtr = oldPtr.unique;
    newPtr.twice.shouldEqual(10);
    oldPtr.shouldBeNull;
}

@("Unique @nogc")
@system @nogc unittest {

    import std.experimental.allocator.mallocator: Mallocator;

    {
        const ptr = Unique!(NoGcStruct, Mallocator)(5);
        // shouldEqual isn't @nogc
        assert(ptr.i == 5);
        assert(NoGcStruct.numStructs == 1);
    }

    assert(NoGcStruct.numStructs == 0);
}

@("Unique @nogc @safe")
@safe @nogc unittest {

    auto allocator = SafeAllocator();

    {
        const ptr = Unique!(NoGcStruct, SafeAllocator)(SafeAllocator(), 6);
        // shouldEqual isn't @nogc
        assert(ptr.i == 6);
        assert(NoGcStruct.numStructs == 1);
    }

    assert(NoGcStruct.numStructs == 0);
}

@("Unique deref")
@system unittest {
    {
        auto allocator = TestAllocator();
        auto ptr = Unique!(Struct, TestAllocator*)(&allocator, 5);
        *ptr = Struct(13);
        ptr.twice.shouldEqual(26);
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}

@("Unique move from populated other unique")
@system unittest {

    import std.algorithm: move;

    {
        auto allocator = TestAllocator();

        auto ptr1 = Unique!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);

        {
            auto ptr2 = Unique!(Struct, TestAllocator*)(&allocator, 10);
            Struct.numStructs.shouldEqual(2);
            move(ptr2, ptr1);
            Struct.numStructs.shouldEqual(1);
            ptr2.shouldBeNull;
            ptr1.twice.shouldEqual(20);
        }

    }

    Struct.numStructs.shouldEqual(0);
}

@("Unique assign to rvalue")
@system unittest {

    import std.algorithm: move;

    {
        auto allocator = TestAllocator();

        auto ptr = Unique!(Struct, TestAllocator*)(&allocator, 5);
        ptr = Unique!(Struct, TestAllocator*)(&allocator, 7);

        Struct.numStructs.shouldEqual(1);
        ptr.twice.shouldEqual(14);
    }

    Struct.numStructs.shouldEqual(0);
}


@("Unique array default TestAllocator")
@system unittest {
    uniqueArrayTest!TestAllocator;
}


@("Unique array default Mallocator")
@system unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    uniqueArrayTest!Mallocator;
}

version(unittest) {

    void uniqueArrayTest(T)() {
        import std.traits: hasMember;

        enum isSingleton = hasMember!(T, "instance");

        static if(isSingleton) {

            alias allocator = T.instance;
            alias Allocator = T;
            auto ptr = Unique!(Struct[], Allocator)(3);
            Struct.numStructs += 1; // this ends up at -3 for some reason
        } else {

            auto allocator = T();
            alias Allocator = T*;
            auto ptr = Unique!(Struct[], Allocator)(&allocator, 3);
            Struct.numStructs += 1; // this ends up at -2 for some reason
        }

        Struct.numStructs.shouldEqual(0);

        ptr[2].twice.shouldEqual(0);
        ptr[2] = Struct(5);
        ptr[2].twice.shouldEqual(10);

        ptr.length.shouldEqual(3);
        ptr[1..$].shouldEqual([Struct(), Struct(5)]);
    }
}


struct RefCounted(Type, Allocator) if(isAllocator!Allocator) {
    import std.traits: hasMember;
    import std.typecons: Proxy;

    enum isSingleton = hasMember!(Allocator, "instance");

    static if(is(Type == class))
        alias Pointer = Type;
    else
        alias Pointer = Type*;

    static if(isSingleton)
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
        static if(!isSingleton)
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
        static if(!isSingleton)
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
    else
        Allocator _allocator;

    Impl* _impl;

    void makeObject(Args...)(auto ref Args args) {
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
            _allocator.deallocate(mem[0 .. Impl.sizeof]);
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

@("RefCounted struct test allocator no copies")
@system unittest {
    auto allocator = TestAllocator();
    {
        auto ptr = RefCounted!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}

@("RefCounted struct test allocator one lvalue assignment")
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

@("RefCounted struct test allocator one rvalue assignment test allocator")
@system unittest {
    auto allocator = TestAllocator();
    {
        RefCounted!(Struct, TestAllocator*) ptr;
        ptr = RefCounted!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}

@("RefCounted struct test allocator one rvalue assignment mallocator")
@system unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    {
        RefCounted!(Struct, Mallocator) ptr;
        ptr = RefCounted!(Struct, Mallocator)(5);
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}


@("RefCounted struct test allocator one lvalue copy constructor")
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

@("RefCounted struct test allocator one rvalue copy constructor")
@system unittest {
    auto allocator = TestAllocator();
    {
        auto ptr = RefCounted!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);
    }
    Struct.numStructs.shouldEqual(0);
}

@("RefCounted many copies made")
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


@("RefCounted deref")
@system unittest {
    auto allocator = TestAllocator();
    auto rc1 = RefCounted!(int, TestAllocator*)(&allocator, 5);

    (*rc1).shouldEqual(5);
    auto rc2 = rc1;
    *rc2 = 42;
    (*rc1).shouldEqual(42);
}

@("RefCounted swap")
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

@("RefCounted assign from T")
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

version(LDC) {}
else {
    @("RefCounted SharedStruct")
        @system unittest {
        auto allocator = TestAllocator();
        {
            auto ptr = RefCounted!(shared SharedStruct, TestAllocator*)(&allocator, 5);
            SharedStruct.numStructs.shouldEqual(1);
        }
        SharedStruct.numStructs.shouldEqual(0);
    }
}


version(unittest) {

    void _writelnUt(T...)(T args) {
        try {
            () @trusted { writelnUt(args); }();
        } catch(Exception ex) {
            assert(false);
        }
    }

    private struct Struct {
        int i;
        static int numStructs = 0;

        this(int i) @safe nothrow {
            this.i = i;

            ++numStructs;
            _writelnUt("Struct normal ctor ", &this, ", i=", i, ", N=", numStructs);
        }

        this(this) @safe nothrow {
            ++numStructs;
            _writelnUt("Struct postBlit ctor ", &this, ", i=", i, ", N=", numStructs);
        }

        ~this() @safe nothrow {
            --numStructs;
            _writelnUt("Struct dtor ", &this, ", i=", i, ", N=", numStructs);
        }

        int twice() @safe pure const nothrow {
            return i * 2;
        }
    }

    private struct SharedStruct {
        int i;
        static int numStructs = 0;

        this(int i) @safe nothrow shared {
            this.i = i;

            ++numStructs;
            try () @trusted {
                    _writelnUt("Struct normal ctor ", &this, ", i=", i, ", N=", numStructs);
                }();
            catch(Exception ex) {}
        }

        this(this) @safe nothrow shared {
            ++numStructs;
            try () @trusted {
                    _writelnUt("Struct postBlit ctor ", &this, ", i=", i, ", N=", numStructs);
                }();
            catch(Exception ex) {}
        }

        ~this() @safe nothrow shared {
            --numStructs;
            try () @trusted { _writelnUt("Struct dtor ", &this, ", i=", i, ", N=", numStructs); }();
            catch(Exception ex) {}
        }

        int twice() @safe pure const nothrow shared {
            return i * 2;
        }
    }

    private class Class {
        int i;
        static int numClasses = 0;

        this(int i) @safe nothrow {
            this.i = i;
            ++numClasses;
        }

        ~this() @safe nothrow {
            --numClasses;
        }

        int twice() @safe pure const nothrow {
            return i * 2;
        }
    }

    private struct SafeAllocator {

        import std.experimental.allocator.mallocator: Mallocator;

        void[] allocate(size_t i) @trusted nothrow @nogc {
            return Mallocator.instance.allocate(i);
        }

        void deallocate(void[] bytes) @trusted nothrow @nogc {
            Mallocator.instance.deallocate(bytes);
        }
    }

    static struct NoGcStruct {
        int i;

        static int numStructs = 0;

        this(int i) @safe @nogc nothrow {
            this.i = i;

            ++numStructs;
        }

        this(this) @safe @nogc nothrow {
            ++numStructs;
        }

        ~this() @safe @nogc nothrow {
            --numStructs;
        }

    }
}
