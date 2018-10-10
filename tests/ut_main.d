import unit_threaded;


mixin runTestsMain!(
    "automem",         // example tests
    "automem.unique",  // has some tests that can't be moved out
    "automem.traits",  // static asserts
    "automem.utils",   // static asserts
    "ut.allocator",
    "ut.ref_counted",
    "ut.unique",
    "ut.vector",
);


shared static this() @safe nothrow {
    import stdx.allocator: theAllocator, allocatorObject;
    import stdx.allocator.mallocator: Mallocator;
    theAllocator = () @trusted { return allocatorObject(Mallocator.instance); }();
}
