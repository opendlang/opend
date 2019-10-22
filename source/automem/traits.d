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
   Determines if a type is Unique with a supported Allocator.
 */
template isUnique(T) {
    import automem.unique: Unique;
    import std.typecons: Flag;

    static if (is(T == Unique!(Type, Allocator, supportsGC), 
                  Type, Allocator, Flag!"supportGC" supportsGC))
    {
        static if (isAllocator!Allocator)
            enum bool isUnique = true;
        else
            enum bool isUnique = false;
    }
    else
    {
        enum bool isUnique = false;
    }
}

///
@("isUnique")
@safe @nogc pure unittest {
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
template UniqueType(T)
{
    import automem.unique: Unique;
    
    static if (isUnique!T) {
        import std.typecons: Flag;

        static if (is(T == Unique!(Type, Allocator, supportsGC), 
                      Type, Allocator, Flag!"supportGC" supportsGC))
            alias UniqueType = Type;
        else
            alias UniqueType = void;
    } else {
        static assert(0, "UniqueType: input type is not a valid Unique type");
    }
}

///
@("Get the base type of a Unique type")
@safe @nogc pure unittest {
    import automem.unique: Unique;

    static struct Point {
        int x;
        int y;
    }

    auto u = Unique!Point(2, 3);
    static assert(is(Point == UniqueType!(typeof(u))));
}

/**
   Determines if a type is RefCounted with a supported Allocator.
 */
template isRefCounted(T) {
    import automem.ref_counted: RefCounted;
    import std.typecons: Flag;

    static if (is(T == RefCounted!(Type, Allocator, supportsGC), 
                  Type, Allocator, Flag!"supportGC" supportsGC))
    {
        static if (isAllocator!Allocator)
            enum bool isRefCounted = true;
        else
            enum bool isRefCounted = false;
    }
    else
    {
        enum bool isRefCounted = false;
    }
}

///
@("isRefCounted")
@safe @nogc pure unittest {
    import automem.ref_counted: RefCounted;
    
    static struct Point {
        int x;
        int y;
    }

    auto s = RefCountedType!Point(2, 3);
    static assert(isRefCounted!(typeof(s)));

    auto p = Point(2, 3);
    static assert(!isRefCounted!(typeof(p)));
}

/**
   The base type of a `RefCounted` pointer.
 */
template RefCountedType(T)
{
    import automem.ref_counted: RefCounted;
    
    static if (isRefCounted!T) {
        import std.typecons: Flag;

        static if (is(T == RefCounted!(Type, Allocator, supportsGC), 
                      Type, Allocator, Flag!"supportGC" supportsGC))
            alias RefCountedType = Type;
        else
            alias RefCountedType = void;
    } else {
    	static assert(0, "RefCountedType: input type is not a valid RefCounted type");
    }
}

///
@("Get the base type of a RefCounted type")
@safe @nogc pure unittest {
    import automem.ref_counted: RefCounted;

    static struct Point {
        int x;
        int y;
    }

    auto s = RefCounted!Point(2, 3);
    static assert(is(Point == RefCountedType!(typeof(s))));
}
