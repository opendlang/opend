module ut.unique_array;

import ut;
import automem.unique_array;

mixin TestUtils;

@("default TestAllocator")
@system unittest {
    defaultTest!TestAllocator;
}


@("default Mallocator")
@system unittest {
    import stdx.allocator.mallocator: Mallocator;
    defaultTest!Mallocator;
}

private void defaultTest(T)() {
    import std.algorithm: move;
    import std.traits: hasMember;

    enum isGlobal = hasMember!(T, "instance");

    static if(isGlobal) {
        alias allocator = T.instance;
        alias Allocator = T;
    } else {
        auto allocator = T();
        alias Allocator = T*;
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
    ptr3.shouldEqual([Struct(), Struct(), Struct(5)]);
    (*ptr3).shouldEqual([Struct(), Struct(), Struct(5)]);

    ptr3 ~= Struct(10);
    ptr3.shouldEqual([Struct(), Struct(), Struct(5), Struct(10)]);

    ptr3 ~= [Struct(11), Struct(12)];
    ptr3.shouldEqual([Struct(), Struct(), Struct(5), Struct(10), Struct(11), Struct(12)]);

    ptr3.length = 3;
    ptr3.shouldEqual([Struct(), Struct(), Struct(5)]);

    ptr3.length = 4;
    ptr3.shouldEqual([Struct(), Struct(), Struct(5), Struct()]);

    ptr3.length = 1;

    ptr3 ~= makeUniqueArray!(Struct, Allocator)(allocator, 1);

    ptr3.shouldEqual([Struct(), Struct()]);

    auto ptr4 = makeUniqueArray!(Struct, Allocator)(allocator, 1);

    ptr3 ~= ptr4.unique;
    ptr3.shouldEqual([Struct(), Struct(), Struct()]);

    ptr3 = [Struct(7), Struct(9)];
    ptr3.shouldEqual([Struct(7), Struct(9)]);
}

///
@("@nogc")
@system @nogc unittest {

    import stdx.allocator.mallocator: Mallocator;

    auto arr = UniqueArray!(NoGcStruct, Mallocator)(2);
    assert(arr.length == 2);

    arr[0] = NoGcStruct(1);
    arr[1] = NoGcStruct(3);

    {
        NoGcStruct[2] expected = [NoGcStruct(1), NoGcStruct(3)];
        assert(arr == expected);
    }

    auto arr2 = UniqueArray!(NoGcStruct, Mallocator)(1);
    arr ~= arr2.unique;

    {
        NoGcStruct[3] expected = [NoGcStruct(1), NoGcStruct(3), NoGcStruct()];
        assert(arr == expected);
    }
}

@("@nogc @safe")
@safe @nogc unittest {
    auto allocator = SafeAllocator();
    auto arr = UniqueArray!(NoGcStruct, SafeAllocator)(SafeAllocator(), 6);
    assert(arr.length == 6);
    arr ~= NoGcStruct();
    assert(arr.length == 7);
}


@("init TestAllocator")
@system unittest {
    auto allocator = TestAllocator();
    auto arr = UniqueArray!(Struct, TestAllocator*)(&allocator, 2, Struct(7));
    arr.shouldEqual([Struct(7), Struct(7)]);
}

@("init Mallocator")
@system unittest {
    import stdx.allocator.mallocator: Mallocator;
    alias allocator = Mallocator.instance;
    auto arr = UniqueArray!(Struct, Mallocator)(2, Struct(7));
    arr.shouldEqual([Struct(7), Struct(7)]);
}


@("range TestAllocator")
@system unittest {
    auto allocator = TestAllocator();
    auto arr = UniqueArray!(Struct, TestAllocator*)(&allocator, [Struct(1), Struct(2)]);
    arr.shouldEqual([Struct(1), Struct(2)]);
}

@("range Mallocator")
@system unittest {
    import stdx.allocator.mallocator: Mallocator;
    auto arr = UniqueArray!(Struct, Mallocator)([Struct(1), Struct(2)]);
    arr.shouldEqual([Struct(1), Struct(2)]);
}


@("theAllocator")
@system unittest {
    with(theTestAllocator) {
        auto arr = UniqueArray!Struct(2);
        arr.shouldEqual([Struct(), Struct()]);
    }
}

@("issue 1 array")
@system unittest {
    import stdx.allocator.mallocator;
    UniqueArray!(int, Mallocator) a;
    a ~= [0, 1];
}

@("issue 1 value")
@system unittest {
    import stdx.allocator.mallocator;
    UniqueArray!(int, Mallocator) a;
    a ~= 7;
}

@("issue 1 UniqueArray")
@system unittest {
    import stdx.allocator.mallocator;
    UniqueArray!(int, Mallocator) a;
    a ~= UniqueArray!(int, Mallocator)([1, 2, 3]);
}

@("dereference")
unittest {
    import stdx.allocator.mallocator;
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
    a.shouldEqual([1, 2, 3, 4, 5, 6, 7, 8, 9]);
    allocator.numAllocations.shouldEqual(1);
}

@("reserve from existing expand")
@system unittest {
    auto allocator = TestAllocator();
    auto a = UniqueArray!(int, TestAllocator*)(&allocator, [1, 2]); //allocates here
    a.reserve(10); //allocates here
    a ~= [3, 4]; // should not allocate
    a ~= [5, 6, 7, 8, 9]; //should not allocate
    a.shouldEqual([1, 2, 3, 4, 5, 6, 7, 8, 9]);
    allocator.numAllocations.shouldEqual(2);
}

@("reserve from existing reduce")
@system unittest {
    auto allocator = TestAllocator();
    auto a = UniqueArray!(int, TestAllocator*)(&allocator, [1, 2, 3, 4, 5]); //allocates here
    a.reserve(2); // should not allocate, changes length to 2
    a ~= [5, 6];  // should not allocate
    a.shouldEqual([1, 2, 5, 6]);
    allocator.numAllocations.shouldEqual(1);
}

@("Append 2 arrays")
@system unittest {
    auto allocator = TestAllocator();
    auto a = UniqueArray!(int, TestAllocator*)(&allocator, [1, 2, 3]) ~
             UniqueArray!(int, TestAllocator*)(&allocator, [4, 5]);
    a.shouldEqual([1, 2, 3, 4, 5]);
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
    b.shouldEqual([1, 2, 3, 4, 5]);
}

@("dup Mallocator")
@system unittest {
    import stdx.allocator.mallocator: Mallocator;
    auto a = UniqueArray!(int, Mallocator)([1, 2, 3, 4, 5]);
    auto b = a.dup;
    b.shouldEqual([1, 2, 3, 4, 5]);
}

@("dup TestAllocator indirections")
@system unittest {
    auto allocator = TestAllocator();
    static struct String { string s; }
    auto a = UniqueArray!(String, TestAllocator*)(&allocator, [String("foo"), String("bar")]);
    auto b = a.dup;
    a[0] = String("quux");
    a[1] = String("toto");
    allocator.numAllocations.shouldEqual(2);
    a.shouldEqual([String("quux"), String("toto")]);
    b.shouldEqual([String("foo"), String("bar")]);
}

@("Set length to the same length")
unittest {
    auto allocator = TestAllocator();
    auto a = UniqueArray!(Struct, TestAllocator*)(&allocator, [Struct(2), Struct(3)]);
    a.length = 2;
}

@("UniqueString TestAllocator")
@safe unittest {
    auto allocator = TestAllocator();
    auto str = () @trusted { return UniqueString!(TestAllocator*)(&allocator); }();
    str ~= 'f';
    str ~= 'o';
    str ~= 'o';
    str.shouldEqual("foo");
}
