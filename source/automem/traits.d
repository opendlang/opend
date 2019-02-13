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
