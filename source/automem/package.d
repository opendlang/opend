/**
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
*/
module automem;

public import automem.unique;
public import automem.ref_counted;
public import automem.vector;
public import automem.array;


@safe unittest {

    import std.algorithm: move;

    static struct Point {
        int x;
        int y;
    }

    // set theAllocator as desired beforehand, e.g.
    // theAllocator = allocatorObject(Mallocator.instance)

    {
        // must pass arguments to initialise the contained object
        auto u1 = Unique!Point(2, 3);
        assert(*u1 == Point(2, 3));
        assert(u1.y == 3);

        // auto u2 = u1; // won't compile, can only move
        typeof(u1) u2 = () @trusted { return u1.move; }();
        assert(cast(bool)u1 == false); // u1 is now empty
    }
    // memory freed for the Point structure created in the block

    {
        auto s1 = RefCounted!Point(4, 5);
        assert(*s1 == Point(4, 5));
        assert(s1.x == 4);
        {
            auto s2 = s1; // can be copied
        } // ref count goes to 1 here

    } // ref count goes to 0 here, memory released

    {
        import std.algorithm: map, equal;
        import std.range: iota;

        // `vector` is also known as `array`
        auto vec = vector(Point(1, 2), Point(3, 4), Point(5, 6));
        assert(equal(vec.range, [Point(1, 2), Point(3, 4), Point(5, 6)]));

        // reallocations are @system since old pointers can dangle
        () @trusted {
            vec.length = 1;
            assert(equal(vec.range, [Point(1, 2)]));

            vec ~= Point(7, 8);
            assert(equal(vec.range, [Point(1, 2), Point(7, 8)]));

            vec ~= 2.iota.map!(i => Point(i + 10, i + 11));
            assert(equal(vec.range, [Point(1, 2), Point(7, 8), Point(10, 11), Point(11, 12)]));
        }();
    } // memory for the array released here
}


// @nogc test - must explicitly use the allocator for compile-time guarantees
@safe @nogc unittest {
    import std.experimental.allocator.mallocator: Mallocator;

    static struct Point {
        int x;
        int y;
    }

    {
        // must pass arguments to initialise the contained object
        auto u1 = Unique!(Point, Mallocator)(2, 3);
        assert(*u1 == Point(2, 3));
        assert(u1.y == 3);
    }
    // memory freed for the Point structure created in the block

    // similarly for the other types
}
