module automem.utils;

import std.traits: isFunctionPointer, isDelegate, functionAttributes, FunctionAttribute;


enum hasNoGcDestructor(T) = is(T == class) && functionAttributes!(typeof(T.__dtor)) & FunctionAttribute.nogc;

@("hasNoGcDestructor")
@safe pure unittest {
    static assert(hasNoGcDestructor!NoGc);
    static assert(!hasNoGcDestructor!Gc);
}

// https://www.auburnsounds.com/blog/2016-11-10_Running-D-without-its-runtime.html
void destroyNoGC(T)(T x) nothrow @nogc
    if (is(T == class) || is(T == interface))
{
    assumeNothrowNoGC(
        (T x) {
            return destroy(x);
        })(x);
}

/**
   Assumes a function to be nothrow and @nogc
   From: https://www.auburnsounds.com/blog/2016-11-10_Running-D-without-its-runtime.html
*/
auto assumeNothrowNoGC(T)(T t) if (isFunctionPointer!T || isDelegate!T)
{
    import std.traits: functionAttributes, FunctionAttribute;

    enum attrs = functionAttributes!T
               | FunctionAttribute.nogc
               | FunctionAttribute.nothrow_;
    return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
}

version(unittest) {
    private class NoGc { ~this() @nogc {} }
    private class Gc { ~this() { }}
}
