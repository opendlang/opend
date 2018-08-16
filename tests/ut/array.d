module ut.array;

import ut;
import automem.array;

mixin TestUtils;



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

@("append")
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


@("slice")
@safe unittest {
    const arr = array(0, 1, 2, 3, 4, 5);
    arr[].should == [0, 1, 2, 3, 4, 5];
    arr[1 .. 3].should == [1, 2];
    arr[1 .. 4].should == [1, 2, 3];
    arr[2 .. 5].should == [2, 3, 4];
    arr[1 .. $ - 1].should == [1, 2, 3, 4];
}
