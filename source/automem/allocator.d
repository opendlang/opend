/**
   Custom versions of std.experimental.allocator functions (unfortunately)
 */
module automem.allocator;

import automem.utils: destruct;

/**

Destroys and then deallocates (using $(D alloc)) the object pointed to by a
pointer, the class object referred to by a $(D class) or $(D interface)
reference, or an entire array. It is assumed the respective entities had been
allocated with the same allocator.

*/
void dispose(A, T)(auto ref A alloc, T* p)
{
    import std.traits: hasElaborateDestructor;

    static if (hasElaborateDestructor!T)
    {
        destruct(*p);
    }
    alloc.deallocate((cast(void*) p)[0 .. T.sizeof]);
}

/// Ditto
void dispose(A, T)(auto ref A alloc, T p)
if (is(T == class) || is(T == interface))
{

    if (!p) return;
    static if (is(T == interface))
    {
        version(Windows)
        {
            import core.sys.windows.unknwn : IUnknown;
            static assert(!is(T: IUnknown), "COM interfaces can't be destroyed in "
                ~ __PRETTY_FUNCTION__);
        }
        auto ob = cast(Object) p;
    }
    else
        alias ob = p;
    auto support = (cast(void*) ob)[0 .. typeid(ob).initializer.length];

    destruct(p);

    alloc.deallocate(support);
}

/// Ditto
void dispose(A, T)(auto ref A alloc, T[] array)
{
    import std.traits: hasElaborateDestructor;

    static if (hasElaborateDestructor!(typeof(array[0])))
    {
        foreach (ref e; array)
        {
            destruct(e);
        }
    }
    alloc.deallocate(array);
}

///
@system unittest
{

    import std.experimental.allocator: theAllocator, make, makeArray;

    static int x;
    static interface I
    {
        void method();
    }
    static class A : I
    {
        int y;
        override void method() { x = 21; }
        ~this() { x = 42; }
    }
    static class B : A
    {
    }
    auto a = theAllocator.make!A;
    a.method();
    assert(x == 21);
    theAllocator.dispose(a);
    assert(x == 42);

    B b = theAllocator.make!B;
    b.method();
    assert(x == 21);
    theAllocator.dispose(b);
    assert(x == 42);

    I i = theAllocator.make!B;
    i.method();
    assert(x == 21);
    theAllocator.dispose(i);
    assert(x == 42);

    int[] arr = theAllocator.makeArray!int(43);
    theAllocator.dispose(arr);
}

///
@system unittest //bugzilla 15721
{
    import std.experimental.allocator: make;
    import std.experimental.allocator.mallocator : Mallocator;

    interface Foo {}
    class Bar: Foo {}

    Bar bar;
    Foo foo;
    bar = Mallocator.instance.make!Bar;
    foo = cast(Foo) bar;
    Mallocator.instance.dispose(foo);
}
