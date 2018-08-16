module ut.array;

import ut;
import automem.array;

mixin TestUtils;


@("length")
@safe unittest {
    array("foo", "bar", "baz").length.should == 3;
    array("quux", "toto").length.should == 2;
}

@("array.int")
@safe unittest {
    array(1, 2, 3, 4, 5).should == [1, 2, 3, 4, 5];
    array(2, 3, 4).should == [2, 3, 4];
}

@("array.double")
@safe unittest {
    array(33.3).should == [33.3];
    array(22.2, 77.7).should == [22.2, 77.7];
}

@("copying")
@safe unittest {
    auto arr1 = array(1, 2, 3);
    auto arr2 = arr1;
    arr1[1] = 7;

    arr1.should == [1, 7, 3];
    arr2.should == [1, 2, 3];
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
    arr.should == [0, 1, 2, 3, 4];

    arr ~= [5, 6];
    arr.should == [0, 1, 2, 3, 4, 5, 6];

    arr ~= [1, 2].map!(a => a + 10);
    arr.should == [0, 1, 2, 3, 4, 5, 6, 11, 12];
}

@("append")
@safe unittest {
    auto arr1 = array(0, 1, 2);
    auto arr2 = array(3, 4);

    auto arr3 =  arr1 ~ arr2;
    arr3.should == [0, 1, 2, 3, 4];

    arr1[0] = 7;
    arr2[0] = 9;
    arr3.should == [0, 1, 2, 3, 4];
}

@("slice")
@safe unittest {
    const arr = array(0, 1, 2, 3, 4, 5);
    arr[].should == [0, 1, 2, 3, 4, 5];
    arr[1 .. 3].should == [1, 2];
    arr[1 .. 4].should == [1, 2, 3];
    arr[2 .. 5].should == [2, 3, 4];
    arr[1 .. $ - 1].should == [1, 2, 3, 4];
}

@("assign")
@safe unittest {
    import std.range: iota;
    auto arr = array(10, 11, 12);
    arr = 5.iota;
    arr.should == [0, 1, 2, 3, 4];
}

@("construct from range")
@safe unittest {
    import std.range: iota;
    array(5.iota).should == [0, 1, 2, 3, 4];
}

@("popBack")
@safe unittest {
    auto arr = array(0, 1, 2);
    arr.popBack;
    arr.should == [0, 1];
}
