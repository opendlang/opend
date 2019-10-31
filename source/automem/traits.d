module automem.traits;


void checkAllocator(T)() {
    import std.experimental.allocator: make, dispose;
    import std.traits: hasMember;

    static if(hasMember!(T, "instance"))
        alias allocator = T.instance;
    else
        T allocator;

    int* i = allocator.make!int;
    allocator.dispose(&i);
    void[] bytes = allocator.allocate(size_t.init);
    allocator.deallocate(bytes);
}

enum isAllocator(T) = is(typeof(checkAllocator!T));


@("isAllocator")
@safe @nogc pure unittest {
    import std.experimental.allocator.mallocator: Mallocator;
    import test_allocator: TestAllocator;

    static assert( isAllocator!Mallocator);
    static assert( isAllocator!TestAllocator);
    static assert(!isAllocator!int);
}


template isGlobal(Allocator) {
    enum isGlobal = isSingleton!Allocator || isTheAllocator!Allocator;
}

template isSingleton(Allocator) {
    import std.traits: hasMember;
    enum isSingleton = hasMember!(Allocator, "instance");
}

template isTheAllocator(Allocator) {
    import std.experimental.allocator: theAllocator;
    enum isTheAllocator = is(Allocator == typeof(theAllocator));
}

/**
   Determines if a type is Unique.
 */
template isUnique(T) {
    import automem.unique: Unique;
    import std.traits: TemplateOf;
    enum isUnique = __traits(isSame, TemplateOf!T, Unique);
}

///
@("isUnique")
@safe unittest {
    import automem.unique: Unique;

    static struct Point {
        int x;
        int y;
    }

    auto u = Unique!Point(2, 3);
    static assert(isUnique!(typeof(u)));

    auto p = Point(2, 3);
    static assert(!isUnique!(typeof(p)));
}

/**
   Determines if a type is RefCounted.
 */
template isRefCounted(T) {
    import automem.ref_counted: RefCounted;
    import std.traits: TemplateOf;
    enum isRefCounted = __traits(isSame, TemplateOf!T, RefCounted);
}

///
@("isRefCounted")
@safe unittest {
    import automem.ref_counted: RefCounted;
    
    static struct Point {
        int x;
        int y;
    }

    auto s = RefCounted!Point(2, 3);
    static assert(isRefCounted!(typeof(s)));

    auto p = Point(2, 3);
    static assert(!isRefCounted!(typeof(p)));
}


/**
   The target of a `Unique` or `RefCounted` pointer.
 */
template PointerTarget(T)
    if (isUnique!T || isRefCounted!T)
{
    alias PointerTarget = T.Type;
}

///
@("Get the target of a Unique or RefCounter pointer")
@safe unittest {
    import automem.unique: Unique;
    import automem.ref_counted: RefCounted;

    static struct Point {
        int x;
        int y;
    }

    auto u = Unique!Point(2, 3);
    static assert(is(Point == PointerTarget!(typeof(u))));

    auto s = RefCounted!Point(2, 3);
    static assert(is(Point == PointerTarget!(typeof(s))));
}

///
@("Mixing Unique and RefCounted pointers")
unittest {
	import std.math : approxEqual;
    import automem.unique: Unique;
    import automem.ref_counted: RefCounted;

    static struct Point {
        int x;
        int y;
    }

    static double distance(T, U)(auto ref T p1, auto ref U p2)
        if (is(PointerTarget!T == Point) && 
            is(PointerTarget!U == Point))
    {
        import std.conv : to;
        import std.math : sqrt, pow;
        return((pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2)).to!double.sqrt);
    }

    int x1 = 2;
    int y1 = 3;
    int x2 = x1 + 3;
    int y2 = y1 + 4;

    auto u_p1 = Unique!Point(x1, y1);
    auto u_p2 = Unique!Point(x2, y2);
    assert(approxEqual(distance(u_p1, u_p2), 5.0));

    auto rc_p1 = RefCounted!Point(x1, y1);
    auto rc_p2 = RefCounted!Point(x2, y2);
    assert(approxEqual(distance(rc_p1, rc_p2), 5.0));

    assert(approxEqual(distance(u_p1, rc_p2), 5.0));
    assert(approxEqual(distance(rc_p1, u_p2), 5.0));
}
