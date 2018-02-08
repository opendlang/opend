# automem

[![Build Status](https://travis-ci.org/atilaneves/automem.png?branch=master)](https://travis-ci.org/atilaneves/automem)
[![Coverage](https://codecov.io/gh/atilaneves/automem/branch/master/graph/badge.svg)](https://codecov.io/gh/atilaneves/automem)
[![Open on run.dlang.io](https://img.shields.io/badge/run.dlang.io-open-blue.svg)](https://run.dlang.io/is/hZE7IT)

C++-style automatic memory management smart pointers for D using `std.experimental.allocator`.

Unlike the C++ variants, the smart pointers themselves allocate the memory for the objects they contain.
That ensures the right allocator is used to dispose of the memory as well.

Allocators are template arguments instead of using `theAllocator` so
that these smart pointers can be used in `@nogc` code. However, they
will default to `typeof(theAllocator)` for simplicity. The examples
above will be explicit.

Another reason to have to pass in the type of allocator is to decide how it is to
be stored. Stateless allocators can be "stored" by value and imply zero-cost `Unique` pointers.
Singleton allocators such as Mallocator (that have an `instance` attribute/member function)
don't need to be passed in to the constructor. This is detected at compile-time as an example
of design by instrospection.

`RefCounted` leverages D's type system by doing atomic reference counting *iff* the type of the contained
object is `shared`. Otherwise it's non-atomic.

Sample code:

```d
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

// just use theAllocator
@system unittest {
    auto ptr = Unique!int(42); // defaults to using theAllocator
    assert(*ptr == 42);
} // deallocates here using theAllocator
```
