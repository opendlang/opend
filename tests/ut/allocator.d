module ut.allocator;

///
@system unittest
{
    import std.experimental.allocator: theAllocator, make, makeArray, dispose;

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
    import std.experimental.allocator: make, dispose;
    import std.experimental.allocator.mallocator : Mallocator;

    interface Foo {}
    class Bar: Foo {}

    Bar bar;
    Foo foo;
    bar = Mallocator.instance.make!Bar;
    foo = cast(Foo) bar;
    Mallocator.instance.dispose(foo);
}
