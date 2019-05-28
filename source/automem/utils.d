module automem.utils;

import std.traits : isStaticArray;

// This is a destroy() copied and modified from
// druntime, to allow for destruction attribute inference

void destruct(T)(T obj) if (is(T == class)) {
    (cast(_finalizeType!T) &rt_finalize)(cast(void*) obj);
}

void destruct(T)(T obj) if (is(T == interface)) {
    destruct(cast(Object) obj);
}

void destruct(T)(ref T obj) if (is(T == struct)) {
    static if (__traits(hasMember, T, "__xdtor") &&
               __traits(isSame, T, __traits(parent, obj.__xdtor)))
        obj.__xdtor;
}

void destruct(T : U[n], U, size_t n)(ref T obj) if (!is(T == struct)) {
    foreach_reverse (ref e; obj[])
        destruct(e);
}

void destruct(T)(ref T obj)
if(!is(T == struct) && !is(T == class) && !is(T == interface) && !isStaticArray!T) {
    obj = T.init;
}

@("class dtor inference")
@safe @nogc pure unittest {
    class A { ~this() @nogc {} }
    class B : A { ~this() {} }
    class C : B { ~this() @nogc {} }

    static assert( __traits(compiles, () @nogc { A a; destruct(a); }));
    static assert(!__traits(compiles, () @nogc { B a; destruct(b); }));
    static assert(!__traits(compiles, () @nogc { C a; destruct(c); }));
}

@("class dtor inference with struct members")
@system @nogc pure unittest {
    import std.traits: functionAttributes, FunctionAttribute;
    import std.conv: text;

    struct A { ~this() @nogc {} }
    struct B { ~this() {} }
    class CA { A a; ~this() @nogc {} }
    class CB { B b; ~this() @nogc {} }

    static assert( __traits(compiles, () @nogc { CA a; destruct(a); }));
    static assert(!__traits(compiles, () @system @nogc { CB b; destruct(b); }));
}

private:

extern(C) void rt_finalize(void* p, bool det = true);

// A slightly better hack than the one presented by
// https://www.auburnsounds.com/blog/2016-11-10_Running-D-without-its-runtime.html
//
// This template infers destruction attributes from the given
// class hierarchy. It actually may be incorrect, as by
// the current language rules derived class can still
// have weaker set of destruction attributes.
extern(C)
template _finalizeType(T) {
    static if (is(T == Object)) {
        alias _finalizeType = typeof(&rt_finalize);
    } else {
        import std.traits : BaseClassesTuple;
        import std.meta : AliasSeq;
        alias _finalizeType = typeof((void* p, bool det = true) {
            // generate a body that calls all the destructors in the chain,
            // compiler should infer the intersection of attributes
            foreach (B; AliasSeq!(T, BaseClassesTuple!T)) {
                // __dtor, i.e. B.~this
                static if (__traits(hasMember, B, "__dtor"))
                    () { B obj; obj.__dtor; } ();
                // __xdtor, i.e. dtors for all RAII members
                static if (__traits(hasMember, B, "__xdtor"))
                    () { B obj; obj.__xdtor; } ();
            }
        });
    }
}
