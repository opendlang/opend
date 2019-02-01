module ut.vector;

import ut;
import automem.vector;
import stdx.allocator.mallocator: Mallocator;
import test_allocator;


@("length")
@safe unittest {
    vector("foo", "bar", "baz").length.should == 3;
    vector("quux", "toto").length.should == 2;
}

@("vector.int")
@safe unittest {
    vector(1, 2, 3, 4, 5)[].shouldEqual([1, 2, 3, 4, 5]);
    vector(2, 3, 4)[].shouldEqual([2, 3, 4]);
}

@("vector.double")
@safe unittest {
    vector(33.3)[].shouldEqual([33.3]);
    vector(22.2, 77.7)[].shouldEqual([22.2, 77.7]);
}

@("copying")
@safe unittest {
    auto vec1 = vector(1, 2, 3);
    vec1.reserve(10);
    auto vec2 = vec1;
    vec1[1] = 7;

    vec1[].shouldEqual([1, 7, 3]);
    vec2[].shouldEqual([1, 2, 3]);
}

@("bounds check")
@safe unittest {

    auto vec = vector(1, 2, 3);
    vec.reserve(10);
    vec[3].shouldThrow!BoundsException;
    vec[-1].shouldThrow!BoundsException;
}

@("extend")
@safe unittest {
    import std.algorithm: map;

    auto vec = vector(0, 1, 2, 3);

    vec ~= 4;
    vec[].shouldEqual([0, 1, 2, 3, 4]);

    vec ~= [5, 6];
    vec[].shouldEqual([0, 1, 2, 3, 4, 5, 6]);

    vec ~= [1, 2].map!(a => a + 10);
    vec[].shouldEqual([0, 1, 2, 3, 4, 5, 6, 11, 12]);
}


@("put")
@safe unittest {
    import std.range: iota;

    auto vec = vector(0, 1, 2, 3);
    vec.put(4);
    vec[].shouldEqual([0, 1, 2, 3, 4]);
    vec.put(2.iota);
    vec[].shouldEqual([0, 1, 2, 3, 4, 0, 1]);
}

@("append")
@safe unittest {
    auto vec1 = vector(0, 1, 2);
    auto vec2 = vector(3, 4);

    auto vec3 =  vec1 ~ vec2;
    vec3[].shouldEqual([0, 1, 2, 3, 4]);

    vec1[0] = 7;
    vec2[0] = 9;
    vec3[].shouldEqual([0, 1, 2, 3, 4]);


    // make sure capacity is larger
    vec1 ~= 100;
    vec1.capacity.shouldBeGreaterThan(vec1.length);
    vec1[].shouldEqual([7, 1, 2, 100]);

    vec2 ~= 200;
    vec2.capacity.shouldBeGreaterThan(vec2.length);
    vec2[].shouldEqual([9, 4, 200]);

    (vec1 ~ vec2)[].shouldEqual([7, 1, 2, 100, 9, 4, 200]);
    (vec1 ~ vector(11, 12, 13, 14, 15))[].shouldEqual([7, 1, 2, 100, 11, 12, 13, 14, 15]);
}

@("slice")
@safe unittest {
    const vec = vector(0, 1, 2, 3, 4, 5);
    vec[][].shouldEqual([0, 1, 2, 3, 4, 5]);
    vec[1 .. 3][].shouldEqual([1, 2]);
    vec[1 .. 4][].shouldEqual([1, 2, 3]);
    vec[2 .. 5][].shouldEqual([2, 3, 4]);
    vec[1 .. $ - 1][].shouldEqual([1, 2, 3, 4]);
}

@("opDollar")
@safe unittest {
    auto vec = vector(0, 1, 2, 3, 4);
    vec ~= 5;
    vec ~= 6;
    vec.capacity.shouldBeGreaterThan(vec.length);

    vec[1 .. $ - 1][].shouldEqual([1, 2, 3, 4, 5]);
}

@("assign")
@safe unittest {
    import std.range: iota;
    auto vec = vector(10, 11, 12);
    vec = 5.iota;
    vec[].shouldEqual([0, 1, 2, 3, 4]);
}

@("construct from range")
@safe unittest {
    import std.range: iota;
    vector(5.iota)[].shouldEqual([0, 1, 2, 3, 4]);
}

@("front")
@safe unittest {
    vector(1, 2, 3).front.should == 1;
    vector(2, 3).front.should == 2;
}

@("popBack")
@safe unittest {
    auto vec = vector(0, 1, 2);
    vec.popBack;
    vec[].shouldEqual([0, 1]);
}

@("popFront")
@safe unittest {
    auto vec = vector(0, 1, 2, 3, 4);
    vec.popFront;
    vec[].shouldEqual([1, 2, 3, 4]);
    vec.empty.shouldBeFalse;

    foreach(i; 0 ..  vec.length) vec.popFront;
    vec.empty.shouldBeTrue;
}


@("back")
@safe unittest {
    const vec = vector("foo", "bar", "baz");
    vec.back[].shouldEqual("baz");
}

@("opSliceAssign")
@safe unittest {
    auto vec = vector("foo", "bar", "quux", "toto");

    vec[] = "haha";
    vec[].shouldEqual(["haha", "haha", "haha", "haha"]);

    vec[1..3] = "oops";
    vec[].shouldEqual(["haha", "oops", "oops", "haha"]);
}

@("opSliceOpAssign")
@safe unittest {
    auto vec = vector("foo", "bar", "quux", "toto");
    vec[] ~= "oops";
    vec[].shouldEqual(["foooops", "baroops", "quuxoops", "totooops"]);
}

@("opSliceOpAssign range")
@safe unittest {
    auto vec = vector("foo", "bar", "quux", "toto");
    vec[1..3] ~= "oops";
    vec[].shouldEqual(["foo", "baroops", "quuxoops", "toto"]);
}

@("clear")
@safe unittest {
    auto vec = vector(0, 1, 2, 3);
    vec.clear;
    int[] empty;
    vec[].shouldEqual(empty);
}


@("Mallocator elements")
@safe @nogc unittest {
    import std.algorithm: equal;
    auto vec = vector!Mallocator(0, 1, 2, 3);
    int[4] exp = [0, 1, 2, 3];
    assert(equal(vec[], exp[]));
}

@("Mallocator range")
@safe @nogc unittest {
    import std.algorithm: equal;
    import std.range: iota;
    auto vec = vector!Mallocator(iota(5));
    int[5] exp = [0, 1, 2, 3, 4];
    assert(equal(vec[], exp[]));
}


@("theAllocator null")
@safe unittest {
    Vector!int vec;
}


@("Mallocator null")
@safe @nogc unittest {
    Vector!(int, Mallocator) vec;
}

@("Cannot escape slice")
@safe @nogc unittest {
    int[] ints1;
    scope vec = vector!Mallocator(0, 1, 2, 3);
    int[] ints2;

    static assert(!__traits(compiles, ints1 = vec[]));
    static assert(__traits(compiles, ints2 = vec[]));
}


@("TestAllocator elements capacity")
@safe unittest {
    static TestAllocator allocator;

    auto vec = vector(&allocator, 0, 1, 2);
    vec[].shouldEqual([0, 1, 2]);

    vec ~= 3;
    vec ~= 4;
    vec ~= 5;
    vec ~= 6;
    vec ~= 7;
    vec ~= 8;

    vec[].shouldEqual([0, 1, 2, 3, 4, 5, 6, 7, 8]);
    allocator.numAllocations.shouldBeSmallerThan(4);
}

@("TestAllocator reserve")
@safe unittest {
    static TestAllocator allocator;

    auto vec = vector!(TestAllocator*, int)(&allocator);

    vec.reserve(5);
    () @trusted { vec.shouldBeEmpty; }();

    vec ~= 0;
    vec ~= 1;
    vec ~= 2;
    vec ~= 3;
    vec ~= 4;

    vec[].shouldEqual([0, 1, 2, 3, 4]);
    allocator.numAllocations.should == 1;

    vec ~= 5;
    vec[].shouldEqual([0, 1, 2, 3, 4, 5]);
    allocator.numAllocations.should == 2;
}

@("TestAllocator shrink no length")
@safe unittest {
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
@safe unittest {
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
@safe unittest {
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
@safe unittest {
    static TestAllocator allocator;

    auto vec = vector(&allocator, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
    vec.capacity.should == 10;

    vec.shrink(5);
    vec[].shouldEqual([0, 1, 2, 3, 4]);
    vec.capacity.should == 5;

    vec ~= 5;
    vec[].shouldEqual([0, 1, 2, 3, 4, 5]);
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
@safe unittest {
    Vector!int vec;
    vec.length = 3;
    vec[].shouldEqual([0, 0, 0]);
}


@("foreach")
@safe unittest {
    foreach(e; vector(7, 7, 7)) {
        e.should == 7;
    }
}


@("equal")
@safe unittest {
    import std.range: iota;
    import std.algorithm: equal;

    auto v = vector(0, 1, 2, 3);
    assert(equal(v, 4.iota));
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
@safe unittest {
    {
        auto vec = vector('f', 'o', 'o');
        vec[].shouldEqual("foo");
        vec ~= 'b';
        vec ~= ['a', 'r'];
        vec[].shouldEqual("foobar");
        vec ~= "quux";
        vec[].shouldEqual("foobarquux");
    }

    {
        auto vec = vector("foo");
        vec[].shouldEqual("foo");
        vec.popBack;
        vec[].shouldEqual("fo");
    }

    {
        auto vec = vector("foo");
        vec ~= "bar";
        vec[].shouldEqual("foobar");
    }
}


@("immutable")
@safe unittest {
    Vector!(immutable int) vec;
    vec ~= 42;
    vec[].shouldEqual([42]);
}


@("String")
@safe unittest {
    foreach(c; String("oooooo"))
        c.should == 'o';
}

@("stringz")
@safe unittest {
    import std.string: fromStringz;
    auto str = vector("foobar");
    const strz = str.stringz;
    const back = () @trusted { return fromStringz(strz); }();
    back.should == "foobar";
    str[].shouldEqual("foobar");
}


@("ptr")
@safe unittest {
    const vec = vector(0, 1, 2, 3);
    takesScopePtr(vec.ptr);
    () @trusted { vec.ptr[1].shouldEqual(1); }();
}

private void takesScopePtr(T)(scope const(T)* ptr) {

}


@("StackFront")
@safe @nogc unittest {
    import stdx.allocator.showcase: StackFront;
    import stdx.allocator.mallocator: Mallocator;

    Vector!(int, StackFront!(1024, Mallocator)) v;
    v ~= 1;
}


version(Windows) {}
else {
    @("mmapRegionList")
        @system unittest {
        import stdx.allocator.showcase: mmapRegionList;
        import stdx.allocator.mallocator: Mallocator;
        import automem.vector: isAllocator;

        auto v = vector(mmapRegionList(1024), 0, 1, 2);
        v ~= 3;
    }
}
