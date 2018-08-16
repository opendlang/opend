module ut.array;

import ut;
import automem.array;

mixin TestUtils;


@("array.int")
@safe unittest {
    array(1, 2, 3, 4, 5).should == [1, 2, 3, 4, 5];
    array(2, 3, 4).should == [2, 3, 4];
}
