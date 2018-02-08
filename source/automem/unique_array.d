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

    import std.traits: hasMember, isScalarType;
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

        this(Allocator allocator) {
            _allocator = allocator;
        }

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
    alias move = unique;

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
        return _length;
    }

    @property void length(long size) {

        import std.experimental.allocator: expandArray, shrinkArray;

        if(_objects is null) {
            makeObjects(size);
        } else if(size == length) {
            return;
        } else if(size <= _capacity && size > length) {
            foreach(ref obj; _objects[_length .. size])
                obj = obj.init;
            _length = size;
        } else if(size < length) {
            _length = size;
        } else {
            if(size > length) {
                _allocator.expandArray(_objects, size - length);
                setLength;
            } else {
                _allocator.shrinkArray(_objects, length - size);
                setLength;
            }
        }
    }

    /**
       Dereference. const  since this otherwise could be used to try
       and append to the array, which would not be nice
     */
    const(Type[]) opUnary(string s)() const if(s == "*") {
        return this[];
    }

    UniqueArray opBinary(string s)(UniqueArray other) if(s == "~") {
        this ~= other.unique;
        return this.unique;
    }

    void opOpAssign(string op)(Type other) if(op == "~") {
        length(length + 1);
        _objects[$ - 1] = other;
    }

    void opOpAssign(string op)(Type[] other) if(op == "~") {
        const originalLength = length;
        length(originalLength + other.length);
        _objects[originalLength .. length] = other[];
    }

    void opOpAssign(string op)(UniqueArray other) if(op == "~") {
        this ~= other._objects;
    }

    void opAssign(Type[] other) {
        length = other.length;
        _objects[0 .. length] = other[0 .. length];
    }

    /**
       Reserves memory to prevent too many allocations
     */
    void reserve(in long size) {
        import std.experimental.allocator: expandArray;

        if(_objects is null) {
            const oldLength = length;
            makeObjects(size); // length = capacity here
            _length = oldLength;
            return;
        }

        if(size < _capacity) {
            if(size < _length) _length = size;
            return;
        }

        _capacity = size;
        _allocator.expandArray(_objects, _capacity);
    }

    /**
       Returns a pointer to the underlying data. @system
     */
    inout(Type)* ptr() inout {
        return _objects.ptr;
    }

    static if(isGlobal) {
        UniqueArray dup() const {
            return UniqueArray(_objects);
        }
    } else static if(isScalarType!Allocator && is(typeof(() { auto a = Allocator.init; auto b = a; }))) {
        UniqueArray dup() const {
            return UniqueArray(_allocator, _objects);
        }
    } else {
        UniqueArray dup() {
            return UniqueArray(_allocator, _objects);
        }
    }

private:

    Type[] _objects;
    long _length;
    long _capacity;

    static if(isSingleton)
        alias _allocator = Allocator.instance;
    else static if(isTheAllocator)
        alias _allocator = theAllocator;
    else
        Allocator _allocator;

    void makeObjects(size_t size) {
        import std.experimental.allocator: makeArray;
        _objects = _allocator.makeArray!Type(size);
        setLength;
    }

    void makeObjects(size_t size, Type init) {
        import std.experimental.allocator: makeArray;
        _objects = _allocator.makeArray!Type(size, init);
        setLength;

    }

    void makeObjects(R)(R range) if(isInputRange!R) {
        import std.experimental.allocator: makeArray;
        _objects = _allocator.makeArray!Type(range);
        setLength;
    }

    void setLength() {
        _capacity = _length = _objects.length;
    }

    void deleteObjects() {
        import std.experimental.allocator: dispose;
        import std.traits: isPointer;

        static if(isPointer!Allocator)
            assert((_objects.length == 0 && _objects.ptr is null) || _allocator !is null);

        if(_objects.ptr !is null) _allocator.dispose(_objects);
        _length = 0;
    }

    void moveFrom(T)(ref UniqueArray!(T, Allocator) other) if(is(T: Type[])) {
        import std.algorithm: swap;
        _object = other._object;
        other._object = null;

        swap(_length, other._length);
        swap(_capacity, other._capacity);

        static if(!isGlobal) {
            import std.algorithm: move;
            _allocator = other._allocator.move;
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

        typeof(ptr) ptr2 = ptr.move;

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
    auto arr = UniqueArray!(Struct, Mallocator)([Struct(1), Struct(2)]);
    arr[].shouldEqual([Struct(1), Struct(2)]);
}


@("theAllocator")
@system unittest {
    with(theTestAllocator) {
        auto arr = UniqueArray!Struct(2);
        arr[].shouldEqual([Struct(), Struct()]);
    }
}

@("issue 1 array")
@system unittest {
    import std.experimental.allocator.mallocator;
    UniqueArray!(int, Mallocator) a;
    a ~= [0, 1];
}

@("issue 1 value")
@system unittest {
    import std.experimental.allocator.mallocator;
    UniqueArray!(int, Mallocator) a;
    a ~= 7;
}

@("issue 1 UniqueArray")
@system unittest {
    import std.experimental.allocator.mallocator;
    UniqueArray!(int, Mallocator) a;
    a ~= UniqueArray!(int, Mallocator)([1, 2, 3]);
}

@("dereference")
unittest {
    import std.experimental.allocator.mallocator;
    UniqueArray!(int, Mallocator) a;
    a ~= [0, 1];
    (*a).shouldEqual([0, 1]);
}

@("reserve from nothing")
@system unittest {
    auto allocator = TestAllocator();
    auto a = UniqueArray!(int, TestAllocator*)(&allocator);
    a.reserve(10); //allocates here
    a ~= [1, 2, 3]; // should not allocate
    a ~= [4, 5, 6, 7, 8, 9]; //should not allocate
    a[].shouldEqual([1, 2, 3, 4, 5, 6, 7, 8, 9]);
    allocator.numAllocations.shouldEqual(1);
}

@("reserve from existing expand")
@system unittest {
    auto allocator = TestAllocator();
    auto a = UniqueArray!(int, TestAllocator*)(&allocator, [1, 2]); //allocates here
    a.reserve(10); //allocates here
    a ~= [3, 4]; // should not allocate
    a ~= [5, 6, 7, 8, 9]; //should not allocate
    a[].shouldEqual([1, 2, 3, 4, 5, 6, 7, 8, 9]);
    allocator.numAllocations.shouldEqual(2);
}

@("reserve from existing reduce")
@system unittest {
    auto allocator = TestAllocator();
    auto a = UniqueArray!(int, TestAllocator*)(&allocator, [1, 2, 3, 4, 5]); //allocates here
    a.reserve(2); // should not allocate, changes length to 2
    a ~= [5, 6];  // should not allocate
    a[].shouldEqual([1, 2, 5, 6]);
    allocator.numAllocations.shouldEqual(1);
}

@("Append 2 arrays")
@system unittest {
    auto allocator = TestAllocator();
    auto a = UniqueArray!(int, TestAllocator*)(&allocator, [1, 2, 3]) ~
             UniqueArray!(int, TestAllocator*)(&allocator, [4, 5]);
    a[].shouldEqual([1, 2, 3, 4, 5]);
}

@("ptr")
@system unittest {
    auto allocator = TestAllocator();
    auto a = UniqueArray!(int, TestAllocator*)(&allocator, [1, 2, 3, 4, 5]);
    auto ptr = a.ptr;
    ++ptr;
    (*ptr).shouldEqual(2);
}

@("dup TestAllocator")
@system unittest {
    auto allocator = TestAllocator();
    auto a = UniqueArray!(int, TestAllocator*)(&allocator, [1, 2, 3, 4, 5]);
    auto b = a.dup;
    allocator.numAllocations.shouldEqual(2);
    b[].shouldEqual([1, 2, 3, 4, 5]);
}

@("dup Mallocator")
@system unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    auto a = UniqueArray!(int, Mallocator)([1, 2, 3, 4, 5]);
    auto b = a.dup;
    b[].shouldEqual([1, 2, 3, 4, 5]);
}

@("dup TestAllocator indirections")
@system unittest {
    auto allocator = TestAllocator();
    struct String { string s; }
    auto a = UniqueArray!(String, TestAllocator*)(&allocator, [String("foo"), String("bar")]);
    auto b = a.dup;
    a[0] = String("quux");
    a[1] = String("toto");
    allocator.numAllocations.shouldEqual(2);
    a[].shouldEqual([String("quux"), String("toto")]);
    b[].shouldEqual([String("foo"), String("bar")]);
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
