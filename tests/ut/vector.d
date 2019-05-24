module ut.vector;


import ut;
import automem.vector;
import std.experimental.allocator.mallocator: Mallocator;
import test_allocator;


@("length")
@safe unittest {
    vector("foo", "bar", "baz").length.should == 3;
    vector("quux", "toto").length.should == 2;
}

@("vector.int")
@safe unittest {
    vector(1, 2, 3, 4, 5).range.should == [1, 2, 3, 4, 5];
    vector(2, 3, 4).range.should == [2, 3, 4];
    vector(2, 3, 4).range.should == [2, 3, 4];
}

@("vector.double")
@safe unittest {
    vector(33.3).range.should == [33.3];
    vector(22.2, 77.7).range.should == [22.2, 77.7];
}

@("copying")
@safe unittest {
    auto vec1 = vector(1, 2, 3);
    () @trusted { vec1.reserve(10); }();
    auto vec2 = vec1;
    vec1[1] = 7;

    vec1.range.should == [1, 7, 3];
    vec2.range.should == [1, 2, 3];
}

@("bounds check")
@safe unittest {

    auto vec = vector(1, 2, 3);
    () @trusted { vec.reserve(10); }();
    vec[3].shouldThrow!BoundsException;
    vec[-1].shouldThrow!BoundsException;
}

@("extend")
@system unittest {
    import std.algorithm: map;

    auto vec = vector(0, 1, 2, 3);

    vec ~= 4;
    vec.range.should == [0, 1, 2, 3, 4];

    vec ~= [5, 6];
    vec.range.should == [0, 1, 2, 3, 4, 5, 6];

    vec ~= [1, 2].map!(a => a + 10);
    vec.range.should == [0, 1, 2, 3, 4, 5, 6, 11, 12];
}


@("put")
@system unittest {
    import std.range: iota;

    auto vec = vector(0, 1, 2, 3);
    vec.put(4);
    vec.range.should == [0, 1, 2, 3, 4];
    vec.put(2.iota);
    vec.range.should == [0, 1, 2, 3, 4, 0, 1];
}

@("append")
@system unittest {
    auto vec1 = vector(0, 1, 2);
    auto vec2 = vector(3, 4);

    auto vec3 =  vec1 ~ vec2;
    vec3.range.should == [0, 1, 2, 3, 4];

    vec1[0] = 7;
    vec2[0] = 9;
    vec3.range.should == [0, 1, 2, 3, 4];


    // make sure capacity is larger
    vec1 ~= 100;
    vec1.capacity.shouldBeGreaterThan(vec1.length);
    vec1.range.should == [7, 1, 2, 100];

    vec2 ~= 200;
    vec2.capacity.shouldBeGreaterThan(vec2.length);
    vec2.range.should == [9, 4, 200];

    (vec1 ~ vec2).range.should == [7, 1, 2, 100, 9, 4, 200];
    (vec1 ~ vector(11, 12, 13, 14, 15)).range.should == [7, 1, 2, 100, 11, 12, 13, 14, 15];
}

@("slice")
@system unittest {
    const vec = vector(0, 1, 2, 3, 4, 5);
    vec[].should == [0, 1, 2, 3, 4, 5];
    vec[1 .. 3].should == [1, 2];
    vec[1 .. 4].should == [1, 2, 3];
    vec[2 .. 5].should == [2, 3, 4];
    vec[1 .. $ - 1].should == [1, 2, 3, 4];
}

@("opDollar")
@system unittest {
    auto vec = vector(0, 1, 2, 3, 4);
    vec ~= 5;
    vec ~= 6;
    vec.capacity.shouldBeGreaterThan(vec.length);

    vec[1 .. $ - 1].should == [1, 2, 3, 4, 5];
}

@("assign")
@system unittest {
    import std.range: iota;
    auto vec = vector(10, 11, 12);
    vec = 5.iota;
    vec.range.should == [0, 1, 2, 3, 4];
}

@("construct from range")
@safe unittest {
    import std.range: iota;
    vector(5.iota).range.should == [0, 1, 2, 3, 4];
}


@("popBack")
@safe unittest {
    auto vec = vector(0, 1, 2);
    vec.popBack;
    vec.range.should == [0, 1];
}

@("popFront")
@safe unittest {
    auto vec = vector(0, 1, 2, 3, 4);
    vec.popFront;
    vec.range.should == [1, 2, 3, 4];
    vec.empty.shouldBeFalse;

    foreach(i; 0 ..  vec.length) vec.popFront;
    vec.empty.shouldBeTrue;
}


@("opSliceAssign")
@safe unittest {
    auto vec = vector("foo", "bar", "quux", "toto");

    vec[] = "haha";
    vec.range.should == ["haha", "haha", "haha", "haha"];

    vec[1..3] = "oops";
    vec.range.should == ["haha", "oops", "oops", "haha"];
}

@("opSliceOpAssign")
@safe unittest {
    auto vec = vector("foo", "bar", "quux", "toto");
    vec[] ~= "oops";
    vec.range.should == ["foooops", "baroops", "quuxoops", "totooops"];
}

@("opSliceOpAssign range")
@safe unittest {
    auto vec = vector("foo", "bar", "quux", "toto");
    vec[1..3] ~= "oops";
    vec.range.should == ["foo", "baroops", "quuxoops", "toto"];
}

@("clear")
@safe unittest {
    auto vec = vector(0, 1, 2, 3);
    vec.clear;
    int[] empty;
    vec.range.should ==(empty);
}


@("Mallocator elements")
@safe @nogc unittest {
    import std.algorithm: equal;
    auto vec = vector!Mallocator(0, 1, 2, 3);
    int[4] exp = [0, 1, 2, 3];
    assert(equal(vec.range, exp[]));
}

@("Mallocator range")
@safe @nogc unittest {
    import std.algorithm: equal;
    import std.range: iota;
    auto vec = vector!Mallocator(iota(5));
    int[5] exp = [0, 1, 2, 3, 4];
    assert(equal(vec.range, exp[]));
}


@("theAllocator null")
@safe unittest {
    Vector!int vec;
}


@("Mallocator null")
@safe @nogc unittest {
    Vector!(int, Mallocator) vec;
}


@("escape.range")
@safe @nogc unittest {

    alias Ints = typeof(Vector!(int, Mallocator).init.range());

    Ints ints1;
    scope vec = vector!Mallocator(0, 1, 2, 3);
    Ints ints2;

    static assert(!__traits(compiles, ints1 = vec.range));
    ints2 = vec.range;  // should compile
}


@("escape.element")
@safe unittest {

    int i = 1;
    int j = 2;

    int* oops;
    scope vec = vector(&i, &j);
    int* ok;

    static assert(!__traits(compiles, oops = vec[0]));
    ok = vec[0];
}


@("TestAllocator elements capacity")
@system unittest {
    static TestAllocator allocator;

    auto vec = vector(&allocator, 0, 1, 2);
    vec.range.should == [0, 1, 2];

    vec ~= 3;
    vec ~= 4;
    vec ~= 5;
    vec ~= 6;
    vec ~= 7;
    vec ~= 8;

    vec.range.should == [0, 1, 2, 3, 4, 5, 6, 7, 8];
    allocator.numAllocations.shouldBeSmallerThan(4);
}

@("TestAllocator reserve")
@system unittest {
    static TestAllocator allocator;

    auto vec = vector!(TestAllocator*, int)(&allocator);

    vec.reserve(5);
    () @trusted { vec.empty.should == true; }();

    vec ~= 0;
    vec ~= 1;
    vec ~= 2;
    vec ~= 3;
    vec ~= 4;

    vec.range.should == [0, 1, 2, 3, 4];
    allocator.numAllocations.should == 1;

    vec ~= 5;
    vec.range.should == [0, 1, 2, 3, 4, 5];
    allocator.numAllocations.should == 2;
}

@("TestAllocator shrink no length")
@system unittest {
    static TestAllocator allocator;

    auto vec = vector!(TestAllocator*, int)(&allocator);
    vec.reserve(10);

    vec ~= 0;
    vec ~= 1;
    vec ~= 2;
    vec ~= 3;

    vec.length.should == 4;
    vec.capacity.should == 10;

    vec.shrink;
    vec.length.should == 4;
    vec.capacity.should == 4;
}

@("TestAllocator shrink negative number")
@system unittest {
    static TestAllocator allocator;

    auto vec = vector(&allocator, 0);
    vec ~= 1;
    vec ~= 2;
    vec ~= 3;
    vec.capacity.shouldBeGreaterThan(vec.length);
    const oldCapacity = vec.capacity;

    vec.shrink(-1).shouldBeFalse;
    vec.capacity.should == oldCapacity;
}

@("TestAllocator shrink larger than capacity")
@system unittest {
    static TestAllocator allocator;

    auto vec = vector(&allocator, 0);
    vec ~= 1;
    vec ~= 2;
    vec ~= 3;
    vec.capacity.shouldBeGreaterThan(vec.length);
    const oldCapacity = vec.capacity;

    vec.shrink(oldCapacity * 2).shouldBeFalse;
    vec.capacity.should == oldCapacity;
}


@("TestAllocator shrink with length")
@system unittest {
    static TestAllocator allocator;

    auto vec = vector(&allocator, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
    vec.capacity.should == 10;

    vec.shrink(5);
    vec.range.should == [0, 1, 2, 3, 4];
    vec.capacity.should == 5;

    vec ~= 5;
    vec.range.should == [0, 1, 2, 3, 4, 5];
    allocator.numAllocations.should == 3;

    vec.reserve(10);
    vec.length.should == 6;
    vec.capacity.shouldBeGreaterThan(6);
}

@("TestAllocator copy")
@safe unittest {
    static TestAllocator allocator;

    auto vec1 = vector(&allocator, "foo", "bar", "baz");
    allocator.numAllocations.should == 1;

    auto vec2 = vec1;
    allocator.numAllocations.should == 2;
}

@("TestAllocator move")
@safe unittest {
    static TestAllocator allocator;

    auto vec = vector(&allocator, "foo", "bar", "baz");
    allocator.numAllocations.should == 1;

    consumeVec(vec);
    allocator.numAllocations.should == 1;
}


private void consumeVec(T)(auto ref T vec) {

}


@("set length")
@system unittest {
    Vector!int vec;
    vec.length = 3;
    vec.range.should == [0, 0, 0];
}


@("foreach")
@safe unittest {
    foreach(e; vector(7, 7, 7).range) {
        e.should == 7;
    }
}


@("equal")
@safe unittest {
    import std.range: iota;
    import std.algorithm: equal;

    auto v = vector(0, 1, 2, 3);
    assert(equal(v.range, 4.iota));
}


@("bool")
@safe unittest {
    vector(0, 1, 2).shouldBeTrue;
    Vector!int v;
    if(v) {
        assert(0);
    }
}

@("char")
@system unittest {
    {
        auto vec = vector('f', 'o', 'o');
        vec.range.should ==("foo");
        vec ~= 'b';
        vec ~= ['a', 'r'];
        vec.range.should ==("foobar");
        vec ~= "quux";
        vec.range.should ==("foobarquux");
    }

    {
        auto vec = vector("foo");
        vec.range.should ==("foo");
        vec.popBack;
        vec.range.should ==("fo");
    }

    {
        auto vec = vector("foo");
        vec ~= "bar";
        vec.range.should ==("foobar");
    }
}


@("immutable.append")
@system unittest {
    Vector!(immutable int) vec;
    vec ~= 42;
    vec.range.should == [42];
}


@("String")
@safe unittest {
    foreach(c; String("oooooo").range)
        c.should == 'o';
}

@("stringz")
@safe unittest {
    import std.string: fromStringz;
    auto str = vector("foobar");
    const strz = () @trusted { return str.stringz; }();
    const back = () @trusted { return fromStringz(strz); }();
    back.should == "foobar";
    str.range.should ==("foobar");
}


@("ptr")
@safe unittest {
    const vec = vector(0, 1, 2, 3);
    takesScopePtr(vec.ptr);
    () @trusted { vec.ptr[1].should == 1; }();
}

private void takesScopePtr(T)(scope const(T)* ptr) {

}


@("StackFront")
@safe @nogc unittest {
    import std.algorithm: equal;
    import std.experimental.allocator.showcase: StackFront;
    import std.experimental.allocator.mallocator: Mallocator;

    alias Allocator = StackFront!(1024, Mallocator);

    {
        Vector!(int, Allocator) v;
        () @trusted { v ~= 1; }();
        {
            int[1] expected = [1];
            assert(equal(v.range, expected[]));
        }
    }

    {
        static void fun(Allocator)(ref Allocator allocator) {
            Vector!(int, Allocator) v;
        }
    }
}


version(Windows) {}
else {
    @("mmapRegionList")
        @system unittest {
        import std.experimental.allocator.showcase: mmapRegionList;
        import std.experimental.allocator.mallocator: Mallocator;
        import automem.vector: isAllocator;

        auto v = vector(mmapRegionList(1024), 0, 1, 2);
        v ~= 3;
    }
}



@("2d")
@safe unittest {
    auto v = vector(vector(0, 0, 0), vector(1, 1, 1, 1));
    v[0].range.should == [0, 0, 0];
    v[1].range.should == [1, 1, 1, 1];
}


@("toString")
@safe unittest {
    import std.conv: text;
    auto v = vector(1, 2, 3);
    v.range.text.should == `[1, 2, 3]`;
}


@("return")
@system unittest {

    static auto fun() {
        auto v = vector(1, 2, 3);
        v ~= 4;
        return v;
    }

    auto v = fun;
    v ~= 5;
    v.range.should == [1, 2, 3, 4, 5];
}


@("noconsume.range")
@safe unittest {
    import std.algorithm: equal;

    scope v = vector(1, 2, 3);

    static void fun(R)(R range) {
        import std.array: array;
        assert(equal(range, [1, 2, 3]));
    }

    fun(v.range);
    assert(equal(v.range, [1, 2, 3]));
}


@("noconsume.foreach")
@safe unittest {
    scope v = vector(1, 2, 3);
    foreach(e; v.range) {}
    v.range.should == [1, 2, 3];
}


@("noconsume.map")
@safe unittest {
    import std.algorithm: map;

    scope v = vector(1, 2, 3);
    v.range.map!(a => a * 2).should == [2, 4, 6];
    v.range.should == [1, 2, 3];
}


@("reserve")
@safe unittest {
    scope vec = vector(1, 2, 3);
    vec.range.should == [1, 2, 3];
    () @trusted { vec.reserve(10); }();
    vec.range.should == [1, 2, 3];
}


@("range.reserve")
@safe unittest {
    scope vec = vector(1, 2, 3);
    scope range = vec.range;

    range.save.should == [1, 2, 3];
    () @trusted { vec.reserve(10); }();

    range.should == [1, 2, 3];
}


@("range.const")
@safe unittest {
    const vec = vector(1, 2, 3);
    vec.range.should == [1, 2, 3];
}


@("range.bounds")
@safe unittest {
    const vec = vector(1, 2, 3, 4, 5);
    vec.range(1, 4).should == [2, 3, 4];
    vec.range(2, vec.length).should == [3, 4, 5];
    vec.range(2, -1).should == [3, 4, 5];
    vec.range(2, -2).should == [3, 4];
}


@("equals")
@safe unittest {
    import std.range: iota, only;

    const vec = vector(0, 1, 2);

    (vec == 3.iota).should == true;
    (vec == 2.iota).should == false;
    (vec == 4.iota).should == false;
    (vec == only(0)).should == false;
}
