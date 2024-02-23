import unit_threaded;


mixin runTestsMain!(
    "automem",         // example tests
    "automem.unique",  // has some tests that can't be moved out
    "automem.traits",  // static asserts
    "automem.utils",   // static asserts
    "ut.issues",
    "ut.ref_counted",
    "ut.unique",
    "ut.vector",
);


shared static this() @safe nothrow {
    import std.experimental.allocator: theAllocator, allocatorObject;
    import std.experimental.allocator.mallocator: Mallocator;
    () @trusted { theAllocator = allocatorObject(Mallocator.instance); }();
}
