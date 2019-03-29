module ut.issues;


import ut;
import automem;


private typeof(vector(1).range()) gVectorIntRange;

version(AutomemAsan) {}
else {

    @ShouldFail("https://issues.dlang.org/show_bug.cgi?id=19752")
    @("26")
    @safe unittest {
        static void escape() {
            auto vec = vector(1, 2, 3);
            gVectorIntRange = vec.range;
        }

        static void stackSmash() {
            long[4096] arr = 42;
        }

        escape;
        gVectorIntRange.length.should == 0;
        stackSmash;
        gVectorIntRange.length.should == 0;
    }
}


@("27")
@safe unittest {
    const str = String("foobar");

    (str == "foobar").should == true;
    (str == "barfoo").should == false;
    (str == "quux").should == false;

    (str == String("foobar")).should == true;
    (str == String("barfoo")).should == false;
    (str == String("quux")).should == false;
}
