module ut.ref_counted;

import ut;
import automem.ref_counted;

mixin TestUtils;

///
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

@("struct test allocator one lvalue assignment from T.init")
@system unittest {

    auto allocator = TestAllocator();

    {
        RefCounted!(Struct, TestAllocator*) ptr1;
        Struct.numStructs.shouldEqual(0);

        auto ptr2 = RefCounted!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);

        ptr2 = ptr1;
        Struct.numStructs.shouldEqual(0);
    }

    Struct.numStructs.shouldEqual(0);
}

@("struct test allocator one lvalue assignment both non-null")
@system unittest {

    auto allocator = TestAllocator();

    {
        auto ptr1 = RefCounted!(Struct, TestAllocator*)(&allocator, 5);
        Struct.numStructs.shouldEqual(1);

        auto ptr2 = RefCounted!(Struct, TestAllocator*)(&allocator, 7);
        Struct.numStructs.shouldEqual(2);

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
@safe unittest {
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

@("default allocator (shared)")
@system unittest {
    {
        auto ptr = RefCounted!(shared SharedStruct)(5);
        SharedStruct.numStructs.shouldEqual(1);
    }
    SharedStruct.numStructs.shouldEqual(0);
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
@safe unittest {
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


@("const object")
@system unittest {
    auto allocator = TestAllocator();
    auto ptr1 = RefCounted!(const Struct, TestAllocator*)(&allocator, 5);
}


@("theAllocator")
@system unittest {

    with(theTestAllocator) {
        auto ptr = RefCounted!Struct(42);
        (*ptr).shouldEqual(Struct(42));
        Struct.numStructs.shouldEqual(1);
    }

    Struct.numStructs.shouldEqual(0);
}


@("threads Mallocator")
@system unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    static assert(__traits(compiles, sendRefCounted!Mallocator(7)));
}

@("threads SafeAllocator by value")
@system unittest {
    // can't even use TestAllocator because it has indirections
    // can't pass by pointer since it's an indirection
    auto allocator = SafeAllocator();
    static assert(__traits(compiles, sendRefCounted!(SafeAllocator)(allocator, 7)));
}

@("threads SafeAllocator by shared pointer")
@system unittest {
    // can't even use TestAllocator because it has indirections
    // can't only pass by pointer if shared
    auto allocator = shared SafeAllocator();
    static assert(__traits(compiles, sendRefCounted!(shared SafeAllocator*)(&allocator, 7)));
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

    import automem: Unique;

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

@("Construct RefCounted using global allocator for struct with zero-args ctor")
@system unittest {
    struct S {
        private ulong zeroArgsCtorTest = 3;
    }
    auto s = RefCounted!S.construct();
    static assert(is(typeof(s) == RefCounted!S));
    assert(s._impl !is null);
    assert(s.zeroArgsCtorTest == 3);
}



void sendRefCounted(Allocator, Args...)(Args args) {
    import std.concurrency: spawn, send;

    auto tid = spawn(&threadFunc);
    auto ptr = RefCounted!(shared SharedStruct, Allocator)(args);

    tid.send(ptr);
}

void threadFunc() {

}

@("shared struct with indirection")
@system unittest {
    auto s = RefCounted!(shared SharedStructWithIndirection)("foobar");
}


@("copy from T.init")
unittest {
    static struct X {
        int i;
    }
    static struct Y {
        RefCounted!X x;
    }
    Y y1;
    Y y2;
    y2 = y1;
}


@("number of allocations")
@safe unittest {
    static TestAllocator allocator;
    allocator.numAllocations.should == 0;

    auto ptr1 = RefCounted!(Struct, TestAllocator*)(&allocator, 77);
    allocator.numAllocations.should == 1;
    {
        auto ptr2 = ptr1;
        allocator.numAllocations.should == 1;

        {
            auto ptr = ptr2;
            allocator.numAllocations.should == 1;
        }

        auto produce(int i) {
            return typeof(ptr1)(&allocator, i);
        }

        ptr1 = produce(99);
        allocator.numAllocations.should == 2;
    }

    allocator.numAllocations.should == 2;
}
