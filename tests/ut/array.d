module ut.array;

import ut;
import automem.array;
import stdx.allocator.mallocator: Mallocator;
import test_allocator;

mixin TestUtils;


@("length")
@safe unittest {
    array("foo", "bar", "baz").length.should == 3;
    array("quux", "toto").length.should == 2;
}

@("array.int")
@safe unittest {
    array(1, 2, 3, 4, 5)[].shouldEqual([1, 2, 3, 4, 5]);
    array(2, 3, 4)[].shouldEqual([2, 3, 4]);
}

@("array.double")
@safe unittest {
    array(33.3)[].shouldEqual([33.3]);
    array(22.2, 77.7)[].shouldEqual([22.2, 77.7]);
}

@("copying")
@safe unittest {
    auto arr1 = array(1, 2, 3);
    auto arr2 = arr1;
    arr1[1] = 7;

    arr1[].shouldEqual([1, 7, 3]);
    arr2[].shouldEqual([1, 2, 3]);
}

@("bounds check")
@safe unittest {
    import core.exception: RangeError;

    auto arr = array(1, 2, 3);
    arr[3].shouldThrow!RangeError;
}

@("extend")
@safe unittest {
    import std.algorithm: map;

    auto arr = array(0, 1, 2, 3);

    arr ~= 4;
    arr[].shouldEqual([0, 1, 2, 3, 4]);

    arr ~= [5, 6];
    arr[].shouldEqual([0, 1, 2, 3, 4, 5, 6]);

    arr ~= [1, 2].map!(a => a + 10);
    arr[].shouldEqual([0, 1, 2, 3, 4, 5, 6, 11, 12]);
}

@("append")
@safe unittest {
    auto arr1 = array(0, 1, 2);
    auto arr2 = array(3, 4);

    auto arr3 =  arr1 ~ arr2;
    arr3[].shouldEqual([0, 1, 2, 3, 4]);

    arr1[0] = 7;
    arr2[0] = 9;
    arr3[].shouldEqual([0, 1, 2, 3, 4]);
}

@("slice")
@safe unittest {
    const arr = array(0, 1, 2, 3, 4, 5);
    arr[][].shouldEqual([0, 1, 2, 3, 4, 5]);
    arr[1 .. 3][].shouldEqual([1, 2]);
    arr[1 .. 4][].shouldEqual([1, 2, 3]);
    arr[2 .. 5][].shouldEqual([2, 3, 4]);
    arr[1 .. $ - 1][].shouldEqual([1, 2, 3, 4]);
}

@("assign")
@safe unittest {
    import std.range: iota;
    auto arr = array(10, 11, 12);
    arr = 5.iota;
    arr[].shouldEqual([0, 1, 2, 3, 4]);
}

@("construct from range")
@safe unittest {
    import std.range: iota;
    array(5.iota)[].shouldEqual([0, 1, 2, 3, 4]);
}

@("front")
@safe unittest {
    array(1, 2, 3).front.should == 1;
    array(2, 3).front.should == 2;
}

@("popBack")
@safe unittest {
    auto arr = array(0, 1, 2);
    arr.popBack;
    arr[].shouldEqual([0, 1]);
}

@("back")
@safe unittest {
    const arr = array("foo", "bar", "baz");
    arr.back[].shouldEqual("baz");
}

@("opSliceAssign")
@safe unittest {
    auto arr = array("foo", "bar", "quux", "toto");

    arr[] = "haha";
    arr[].shouldEqual(["haha", "haha", "haha", "haha"]);

    arr[1..3] = "oops";
    arr[].shouldEqual(["haha", "oops", "oops", "haha"]);
}

@("opSliceOpAssign")
@safe unittest {
    auto arr = array("foo", "bar", "quux", "toto");
    arr[] ~= "oops";
    arr[].shouldEqual(["foooops", "baroops", "quuxoops", "totooops"]);
}

@("opSliceOpAssign range")
@safe unittest {
    auto arr = array("foo", "bar", "quux", "toto");
    arr[1..3] ~= "oops";
    arr[].shouldEqual(["foo", "baroops", "quuxoops", "toto"]);
}

@("clear")
@safe unittest {
    auto arr = array(0, 1, 2, 3);
    arr.clear;
    int[] empty;
    arr[].shouldEqual(empty);
}


@("Mallocator")
@safe @nogc unittest {
    auto arr = array!Mallocator(0, 1, 2, 3);
}

@("Mallocator null")
@safe @nogc unittest {
    Array!(Mallocator, int) arr;
}

@("Cannot escape slice")
@safe @nogc unittest {
    int[] ints1;
    scope arr = array!Mallocator(0, 1, 2, 3);
    int[] ints2;

    static assert(!__traits(compiles, ints1 = arr[]));
    static assert(__traits(compiles, ints2 = arr[]));
}


@("TestAllocator elements capacity")
@safe unittest {
    static TestAllocator allocator;

    auto arr = array(&allocator, 0, 1, 2);
    arr[].shouldEqual([0, 1, 2]);

    arr ~= 3;
    arr ~= 4;
    arr ~= 5;
    arr ~= 6;
    arr ~= 7;
    arr ~= 8;

    arr[].shouldEqual([0, 1, 2, 3, 4, 5, 6, 7, 8]);
    allocator.numAllocations.shouldBeSmallerThan(4);
}
