module ut.unique;


import ut;
import automem.unique;


mixin TestUtils;


///
@("with struct and test allocator")
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


@("with class and test allocator")
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

///
@("with struct and mallocator")
@safe unittest {

    import std.experimental.allocator.mallocator: Mallocator;
    {
        const foo = Unique!(Struct, Mallocator)(5);
        foo.twice.shouldEqual(10);
        Struct.numStructs.shouldEqual(1);
    }

    Struct.numStructs.shouldEqual(0);
}

@("default constructor")
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

@(".init")
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

@("move")
@system unittest {
    import std.algorithm: move;

    auto allocator = TestAllocator();
    auto oldPtr = Unique!(Struct, TestAllocator*)(&allocator, 5);
    Unique!(Struct, TestAllocator*) newPtr = oldPtr.move;
    oldPtr.shouldBeNull;
    newPtr.twice.shouldEqual(10);
    Struct.numStructs.shouldEqual(1);
}

@("copy")
@system unittest {
    auto allocator = TestAllocator();
    auto oldPtr = Unique!(Struct, TestAllocator*)(&allocator, 5);
    Unique!(Struct, TestAllocator*) newPtr;
    // non-copyable
    static assert(!__traits(compiles, newPtr = oldPtr));
}

@("construct base class")
@system unittest {
    auto allocator = TestAllocator();
    {
        Unique!(Object, TestAllocator*) bar = Unique!(Class, TestAllocator*)(&allocator, 5);
        Class.numClasses.shouldEqual(1);
    }

    Class.numClasses.shouldEqual(0);
}

@("assign base class")
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

@("unique")
@system unittest {
    auto allocator = TestAllocator();
    auto oldPtr = Unique!(Struct, TestAllocator*)(&allocator, 5);
    auto newPtr = oldPtr.unique;
    newPtr.twice.shouldEqual(10);
    oldPtr.shouldBeNull;
}

@("@nogc")
@safe @nogc unittest {

    import std.experimental.allocator.mallocator: Mallocator;

    {
        const ptr = Unique!(NoGcStruct, Mallocator)(5);
        // shouldEqual isn't @nogc
        assert(ptr.i == 5);
        assert(NoGcStruct.numStructs == 1);
    }

    assert(NoGcStruct.numStructs == 0);
}

@("@nogc @safe")
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

@("deref")
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

@("move from populated other unique")
@system unittest {

    import std.algorithm: move;

    {
        auto allocator = TestAllocator();

        auto ptr1 = Unique!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);

        {
            auto ptr2 = Unique!(Struct, TestAllocator*)(&allocator, 10);
            Struct.numStructs.shouldEqual(2);
            ptr1 = ptr2.move;
            Struct.numStructs.shouldEqual(1);
            ptr2.shouldBeNull;
            ptr1.twice.shouldEqual(20);
        }

    }

    Struct.numStructs.shouldEqual(0);
}

@("assign to rvalue")
@system unittest {

    {
        auto allocator = TestAllocator();

        auto ptr = Unique!(Struct, TestAllocator*)(&allocator, 5);
        ptr = Unique!(Struct, TestAllocator*)(&allocator, 7);

        Struct.numStructs.shouldEqual(1);
        ptr.twice.shouldEqual(14);
    }

    Struct.numStructs.shouldEqual(0);
}


@("theAllocator")
@system unittest {
    with(theTestAllocator){
        auto ptr = Unique!Struct(42);
        (*ptr).shouldEqual(Struct(42));
        Struct.numStructs.shouldEqual(1);
    }

    Struct.numStructs.shouldEqual(0);
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

@("@nogc class implementing @nogc interface ")
@nogc unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    {
        Unique!(NoGcInterface, Mallocator) ptr = Unique!(NoGcClassImplementingNoGcInterface, Mallocator).construct;
        assert(ptr.getNumber == 42);
    }
}

version(DIP1000) {
    @("borrow")
        @safe unittest {

        auto allocator = SafeAllocator();

        {
            const ptr = Unique!(Struct, SafeAllocator)(SafeAllocator(), 6);
            scopeFunc(ptr.borrow).shouldEqual(18);
        }
    }

    private int scopeFunc(scope const(Struct)* s) @safe {

        return s.i * 3;
    }
}
