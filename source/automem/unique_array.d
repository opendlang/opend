module automem.unique_array;

import automem.traits: isAllocator;
import automem.test_utils: TestUtils;
import std.experimental.allocator: theAllocator;

version(unittest) {
    import unit_threaded;
    import test_allocator: TestAllocator;
}

mixin TestUtils;

struct UniqueArray(Type, Allocator = typeof(theAllocator)) if(isAllocator!Allocator) {

    import std.traits: hasMember;
    import std.range: isInputRange;

    enum isSingleton = hasMember!(Allocator, "instance");
    enum isTheAllocator = is(Allocator == typeof(theAllocator));
    enum isGlobal = isSingleton || isTheAllocator;

    static if(isGlobal) {

        /**
           The allocator is global, so no need to pass it in to the
           constructor
        */

        this(size_t size) {
            makeObjects(size);
        }

        this(size_t size, Type init) {
            makeObjects(size, init);
        }

        this(R)(R range) if(isInputRange!R) {
            makeObjects(range);
        }


    } else {

        /**
           Non-singleton allocator, must be passed in
         */

        this(Allocator allocator, size_t size) {
            _allocator = allocator;
            makeObjects(size);
        }

        this(Allocator allocator, size_t size, Type init) {
            _allocator = allocator;
            makeObjects(size, init);
        }

        this(R)(Allocator allocator, R range) if(isInputRange!R) {
            _allocator = allocator;
            makeObjects(range);
        }
    }


    this(T)(UniqueArray!(T, Allocator) other) if(is(T: Type[])) {
        moveFrom(other);
    }

    @disable this(this);

    ~this() {
        deleteObjects;
    }

    /**
       Releases ownership and transfers it to the returned
       Unique object.
     */
    UniqueArray unique() {
        import std.algorithm: move;
        UniqueArray u;
        move(this, u);
        assert(_objects.length == 0 && _objects.ptr is null);
        return u;
    }

    /**
       "Truthiness" cast
     */
    bool opCast(T)() const if(is(T == bool)) {
        return _objects.ptr !is null;
    }

    void opAssign(T)(UniqueArray!(T, Allocator) other) if(is(T: Type[])) {
        deleteObject;
        moveFrom(other);
    }

    ref inout(Type) opIndex(long i) inout nothrow {
        return _objects[i];
    }

    const(Type)[] opSlice(long i, long j) const nothrow {
        return _objects[i .. j];
    }

    const(Type)[] opSlice() const nothrow {
        return _objects[0 .. length];
    }

    long opDollar() const nothrow {
        return length;
    }

    @property long length() const nothrow {
        return _objects.length;
    }

    @property void length(long i) {
        import std.experimental.allocator: expandArray, shrinkArray;

        if(i > length)
            _allocator.expandArray(_objects, i - length);
        else
            _allocator.shrinkArray(_objects, length - i);
    }

    /**
       Dereference. const  since this otherwise could be used to try
       and append to the array, which would not be nice
     */
    ref const(Type[]) opUnary(string s)() const if(s == "*") {
        return _objects;
    }

    void opOpAssign(string op)(Type other) if(op == "~") {
        import std.experimental.allocator: expandArray;

        _allocator.expandArray(_objects, 1);
        _objects[$ - 1] = other;
    }

    void opOpAssign(string op)(Type[] other) if(op == "~") {
        import std.experimental.allocator: expandArray;
        const originalLength = length;
        _allocator.expandArray(_objects, other.length);
        _objects[originalLength .. $] = other[];
    }

    void opOpAssign(string op)(UniqueArray other) if(op == "~") {
        import std.experimental.allocator: expandArray;
        const originalLength = length;
        _allocator.expandArray(_objects, other.length);
        _objects[originalLength .. $] = other[];
    }

    void opAssign(Type[] other) {
        this.length = other.length;
        _objects[] = other[];
    }

private:

    Type[] _objects;

    static if(isSingleton)
        alias _allocator = Allocator.instance;
    else static if(isTheAllocator)
        alias _allocator = theAllocator;
    else
        Allocator _allocator;

    void makeObjects(size_t size) {
        import std.experimental.allocator: makeArray;
        version(LDC)
            _objects = () @trusted { return _allocator.makeArray!Type(size); }();
        else
            _objects = _allocator.makeArray!Type(size);

    }

    void makeObjects(size_t size, Type init) {
        import std.experimental.allocator: makeArray;
        _objects = _allocator.makeArray!Type(size, init);
    }

    void makeObjects(R)(R range) if(isInputRange!R) {
        import std.experimental.allocator: makeArray;
        _objects = _allocator.makeArray!Type(range);
    }


    void deleteObjects() {
        import std.experimental.allocator: dispose;
        import std.traits: isPointer;

        static if(isPointer!Allocator)
            assert((_objects.length == 0 && _objects.ptr is null) || _allocator !is null);

        if(_objects.ptr !is null) _allocator.dispose(_objects);
    }

    void moveFrom(T)(ref UniqueArray!(T, Allocator) other) if(is(T: Type[])) {
        _object = other._object;
        other._object = null;

        static if(!isGlobal) {
            import std.algorithm: move;
            move(other._allocator, _allocator);
        }
    }
}


@("default TestAllocator")
@system unittest {
    defaultTest!TestAllocator;
}


@("default Mallocator")
@system unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    defaultTest!Mallocator;
}

version(unittest) {

    void defaultTest(T)() {
        import std.algorithm: move;

        mixin AllocatorAlias!T;

        auto ptr = makeUniqueArray!(Struct, Allocator)(allocator, 3);
        ptr.length.shouldEqual(3);

        ptr[2].twice.shouldEqual(0);
        ptr[2] = Struct(5);
        ptr[2].twice.shouldEqual(10);

        ptr[1..$].shouldEqual([Struct(), Struct(5)]);

        typeof(ptr) ptr2;
        move(ptr, ptr2);

        ptr.length.shouldEqual(0);
        (cast(bool)ptr).shouldBeFalse;
        ptr2.length.shouldEqual(3);
        (cast(bool)ptr2).shouldBeTrue;

        // not copyable
        static assert(!__traits(compiles, ptr2 = ptr1));

        auto ptr3 = ptr2.unique;
        ptr3.length.shouldEqual(3);
        ptr3[].shouldEqual([Struct(), Struct(), Struct(5)]);
        (*ptr3).shouldEqual([Struct(), Struct(), Struct(5)]);

        ptr3 ~= Struct(10);
        ptr3[].shouldEqual([Struct(), Struct(), Struct(5), Struct(10)]);

        ptr3 ~= [Struct(11), Struct(12)];
        ptr3[].shouldEqual([Struct(), Struct(), Struct(5), Struct(10), Struct(11), Struct(12)]);

        ptr3.length = 3;
        ptr3[].shouldEqual([Struct(), Struct(), Struct(5)]);

        ptr3.length = 4;
        ptr3[].shouldEqual([Struct(), Struct(), Struct(5), Struct()]);

        ptr3.length = 1;

        ptr3 ~= makeUniqueArray!(Struct, Allocator)(allocator, 1);

        ptr3[].shouldEqual([Struct(), Struct()]);

        auto ptr4 = makeUniqueArray!(Struct, Allocator)(allocator, 1);

        ptr3 ~= ptr4.unique;
        ptr3[].shouldEqual([Struct(), Struct(), Struct()]);

        ptr3 = [Struct(7), Struct(9)];
        ptr3[].shouldEqual([Struct(7), Struct(9)]);
    }
}

@("@nogc")
@system @nogc unittest {

    import std.experimental.allocator.mallocator: Mallocator;

    auto arr = UniqueArray!(NoGcStruct, Mallocator)(2);
    assert(arr.length == 2);

    arr[0] = NoGcStruct(1);
    arr[1] = NoGcStruct(3);

    {
        NoGcStruct[2] expected = [NoGcStruct(1), NoGcStruct(3)];
        assert(arr[] == expected[]);
    }

    auto arr2 = UniqueArray!(NoGcStruct, Mallocator)(1);
    arr ~= arr2.unique;

    {
        NoGcStruct[3] expected = [NoGcStruct(1), NoGcStruct(3), NoGcStruct()];
        assert(arr[] == expected[]);
    }
}

@("@nogc @safe")
@safe @nogc unittest {
    auto allocator = SafeAllocator();
    auto arr = UniqueArray!(NoGcStruct, SafeAllocator)(SafeAllocator(), 6);
    assert(arr.length == 6);
}


@("init TestAllocator")
@system unittest {
    auto allocator = TestAllocator();
    auto arr = UniqueArray!(Struct, TestAllocator*)(&allocator, 2, Struct(7));
    arr[].shouldEqual([Struct(7), Struct(7)]);
}

@("init Mallocator")
@system unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    alias allocator = Mallocator.instance;
    auto arr = UniqueArray!(Struct, Mallocator)(2, Struct(7));
    arr[].shouldEqual([Struct(7), Struct(7)]);
}


@("range TestAllocator")
@system unittest {
    auto allocator = TestAllocator();
    auto arr = UniqueArray!(Struct, TestAllocator*)(&allocator, [Struct(1), Struct(2)]);
    arr[].shouldEqual([Struct(1), Struct(2)]);
}

@("range Mallocator")
@system unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    alias allocator = Mallocator.instance;
    auto arr = UniqueArray!(Struct, Mallocator)([Struct(1), Struct(2)]);
    arr[].shouldEqual([Struct(1), Struct(2)]);
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

    auto arr = UniqueArray!Struct(2);
    arr[].shouldEqual([Struct(), Struct()]);
}


version(unittest) {

    mixin template AllocatorAlias(T) {
        import std.traits: hasMember;

        enum isGlobal = hasMember!(T, "instance");

        static if(isGlobal) {
            alias allocator = T.instance;
            alias Allocator = T;
        } else {
            auto allocator = T();
            alias Allocator = T*;
        }
    }


    auto makeUniqueArray(T, A1, A2, Args...)(ref A2 allocator, Args args) {

        import std.traits: isPointer, hasMember;

        enum isGlobal = hasMember!(A1, "instance");

        static if(isGlobal)
            return UniqueArray!(T, A1)(args);
        else static if(isPointer!A1)
            return UniqueArray!(T, A1)(&allocator, args);
        else
            return UniqueArray!(T, A1)(allocator, args);
    }

}
