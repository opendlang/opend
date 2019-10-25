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
   The base type of a `Unique` pointer.
 */
template UniqueTarget(T)
{
    import automem.unique: Unique;
    static assert(isUnique!T);
    alias UniqueTarget = T.Type;
}

///
@("Get the base type of a Unique type")
@safe unittest {
    import automem.unique: Unique;

    static struct Point {
        int x;
        int y;
    }

    auto u = Unique!Point(2, 3);
    static assert(is(Point == UniqueTarget!(typeof(u))));
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
   The base type of a `RefCounted` pointer.
 */
template RefCountedTarget(T)
{
    import automem.ref_counted: RefCounted;
    static assert(isRefCounted!T);
    alias RefCountedTarget = T.Type;
}

///
@("Get the base type of a RefCounted type")
@safe unittest {
    import automem.ref_counted: RefCounted;

    static struct Point {
        int x;
        int y;
    }

    auto s = RefCounted!Point(2, 3);
    static assert(is(Point == RefCountedTarget!(typeof(s))));
}
