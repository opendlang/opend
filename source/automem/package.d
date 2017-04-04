module automem;


version(unittest) {
    import unit_threaded;
    import test_allocator;
}


private void checkAllocator(T)() {
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
@safe pure unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    static assert(isAllocator!Mallocator);
    static assert(isAllocator!TestAllocator);
    static assert(!isAllocator!Struct);
}

struct Unique(Type, Allocator) if(isAllocator!Allocator) {
    import std.traits: hasMember;
    import std.typecons: Proxy;

    enum hasInstance = hasMember!(Allocator, "instance");

    static if(is(Type == class))
        alias Pointer = Type;
    else
        alias Pointer = Type*;

    static if(hasInstance)
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

    this(T)(Unique!(T, Allocator) other) if(is(T: Type)) {
        moveFrom(other);
    }

    @disable this(this);

    ~this() {
        deleteObject;
    }

    inout(Pointer) get() inout {
        return _object;
    }

    Unique unique() {
        import std.algorithm: move;
        Unique u;
        move(this, u);
        assert(_object is null);
        return u;
    }

    Pointer release() {
        auto ret = _object;
        _object = null;
        return ret;
    }

    void reset(Pointer newObject) {
        deleteObject;
        _object = newObject;
    }

    bool opCast(T)() const if(is(T == bool)) {
        return _object !is null;
    }

    void opAssign(T)(Unique!(T, Allocator) other) if(is(T: Type)) {
        deleteObject;
        moveFrom(other);
    }

    mixin Proxy!_object;

private:

    Pointer _object;

    static if(hasInstance)
        alias _allocator = Allocator.instance;
    else
        Allocator _allocator;

    void makeObject(Args...)(auto ref Args args) {
        import std.experimental.allocator: make;
        _object = _allocator.make!Type(args);
    }

    void deleteObject() {
        import std.experimental.allocator: dispose;
        if(_object !is null) _allocator.dispose(_object);
    }


    void moveFrom(T)(ref Unique!(T, Allocator) other) if(is(T: Type)) {
        _object = other._object;
        other._object = null;

        static if(!hasInstance) {
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


@("Unique release")
@system unittest {
    import std.experimental.allocator: dispose;

    auto allocator = TestAllocator();

    auto ptr = Unique!(Struct, TestAllocator*)(&allocator, 5);
    auto obj = ptr.release;
    obj.twice.shouldEqual(10);
    allocator.dispose(obj);
}

@("Unique reset")
@system unittest {
    import std.experimental.allocator: make;

    auto allocator = TestAllocator();

    auto ptr = Unique!(Struct, TestAllocator*)(&allocator, 5);
    ptr.reset(allocator.make!Struct(2));
    ptr.twice.shouldEqual(4);
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
}

@("Unique copy")
@system unittest {
    import std.algorithm: move;

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
    import std.algorithm: move;
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


struct RefCounted(Type, Allocator) if(isAllocator!Allocator) {
    import std.traits: hasMember;
    import std.typecons: Proxy;

    enum hasInstance = hasMember!(Allocator, "instance");

    static if(is(Type == class))
        alias Pointer = Type;
    else
        alias Pointer = Type*;

    static if(hasInstance)
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

    void opAssign(ref RefCounted other) {

        if(_impl !is null) {
            release;
        }
        static if(!hasInstance)
            _allocator = other._allocator;

        _impl = other._impl;
        inc;
    }

    void opAssign(RefCounted other) {
        import std.algorithm: swap;
        swap(_impl, other._impl);
        static if(!hasInstance)
            swap(_allocator, other._allocator);
    }

    /**
     If the allocator isn't a singleton, assigning to the raw type is unsafe.
     If RefCounted was default-contructed then there is no allocator
     */
    static if(hasInstance) {
        void opAssign(Type object) {
            import std.algorithm: move;

            if(_impl is null) {
                allocateImpl;
            }

            move(object, _impl._object);
        }
    }

    ref inout(Type) get() inout {
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

    static if(hasInstance)
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


// TODO: get this to compile
// @("RefCounted reference semantics")
// @system unittest {
//     auto allocator = TestAllocator();
//     auto rc1 = RefCounted!(int, TestAllocator*)(&allocator, 5);

//     rc1.shouldEqual(5);
//     auto rc2 = rc1;
//     rc2 = 42;
//     rc1.shouldEqual(42);
// }

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

        a = Struct(5);
        ++Struct.numStructs; // compensate for move not calling the constructor
        Struct.numStructs.shouldEqual(1);
        // TODO - change this to not use get
        a.get.shouldEqual(Struct(5));

        RefCounted!(Struct, Mallocator) b;
        b = a;
        // TODO - change this to not use get
        b.get.shouldEqual(Struct(5));
        Struct.numStructs.shouldEqual(1);
    }

    Struct.numStructs.shouldEqual(0);
}

@("RefCounted SharedStruct")
@system unittest {
    auto allocator = TestAllocator();
    {
        auto ptr = RefCounted!(shared SharedStruct, TestAllocator*)(&allocator, 5);
        SharedStruct.numStructs.shouldEqual(1);
    }
    SharedStruct.numStructs.shouldEqual(0);
}


version(unittest) {

    private struct Struct {
        int i;
        static int numStructs = 0;

        this(int i) @safe nothrow {
            this.i = i;

            ++numStructs;
            try () @trusted {
                    writelnUt("Struct normal ctor ", &this, ", i=", i, ", N=", numStructs);
                }();
            catch(Exception ex) {}
        }

        this(this) @safe nothrow {
            ++numStructs;
            try () @trusted {
                    writelnUt("Struct postBlit ctor ", &this, ", i=", i, ", N=", numStructs);
                }();
            catch(Exception ex) {}
        }

        ~this() @safe nothrow {
            --numStructs;
            try () @trusted { writelnUt("Struct dtor ", &this, ", i=", i, ", N=", numStructs); }();
            catch(Exception ex) {}
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
                    writelnUt("Struct normal ctor ", &this, ", i=", i, ", N=", numStructs);
                }();
            catch(Exception ex) {}
        }

        this(this) @safe nothrow shared {
            ++numStructs;
            try () @trusted {
                    writelnUt("Struct postBlit ctor ", &this, ", i=", i, ", N=", numStructs);
                }();
            catch(Exception ex) {}
        }

        ~this() @safe nothrow shared {
            --numStructs;
            try () @trusted { writelnUt("Struct dtor ", &this, ", i=", i, ", N=", numStructs); }();
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
        void[] allocate(size_t) @safe pure nothrow @nogc { return []; }
        void deallocate(void[]) @safe pure nothrow @nogc {}
    }
}
