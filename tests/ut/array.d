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
