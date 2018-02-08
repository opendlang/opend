module automem;

public import automem.unique;
public import automem.unique_array;
public import automem.ref_counted;

import automem.test_utils: TestUtils;

mixin TestUtils;

// can be @safe if the allocator has @safe functions
@system @nogc unittest {

    import std.experimental.allocator.mallocator: Mallocator;
    import std.algorithm: move;

    struct Point {
        int x;
        int y;
    }

    {
        // must pass arguments to initialise the contained object
        auto u1 = Unique!(Point, Mallocator)(2, 3);
        assert(*u1 == Point(2, 3));
        assert(u1.y == 3);

        // auto u2 = u1; // won't compile, can only move
        typeof(u1) u2 = u1.move;
        assert(cast(bool)u1 == false); // u1 is now empty
    }
    // memory freed for the Point structure created in the block

    {
        auto s1 = RefCounted!(Point, Mallocator)(4, 5);
        assert(*s1 == Point(4, 5));
        assert(s1.x == 4);
        {
            auto s2 = s1; // can be copied
        } // ref count goes to 1 here

    } // ref count goes to 0 here, memory released

    {
        // the constructor can also take (size, init) or (size, range) values
        auto arr = UniqueArray!(Point, Mallocator)(3);

        const Point[3] expected1 = [Point(), Point(), Point()]; // because array literals aren't @nogc
        assert(arr[] == expected1);

        const Point[1] expected2 = [Point()];
        arr.length = 1;
        assert(*arr == expected2); //deferencing is the same as slicing all of it

        arr ~= UniqueArray!(Point, Mallocator)(1, Point(6, 7));
        const Point[2] expected3 = [Point(), Point(6, 7)];
        assert(arr[] == expected3);

    } // memory for the array released here
}


@("theAllocator")
@system unittest {
    with(theTestAllocator) {
        auto ptr = Unique!int(42);
        assert(*ptr == 42);
    }
} // TestAllocator will throw here if any memory leaks
