/++
Conversion utilities.

License:   $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Phobos Team, Ilya Yaroshenko
+/
module mir.conv;

public import core.lifetime: emplace;

import std.traits;

/++
The `to` template converts a value from one type _to another.
The source type is deduced and the target type must be specified, for example the
expression `to!int(42.0)` converts the number 42 from
`double` _to `int`. The conversion is "unsafe", i.e.,
it does not check for overflow.
+/
template to(T)
{
    ///
    auto ref T to(A...)(auto ref A args)
        if (A.length > 0)
    {
        static if (A.length == 1 && isImplicitlyConvertible!(A[0], T))
            return args[0];
        else
        static if (is(T == class) && is(typeof(new T(args))))
            return new T(args);
        else
        static if (is(typeof(T(args))))
            return T(args);
        else
        static if (A.length == 1)
        {
            static if (is(typeof(cast(T) args[0])))
                return cast(T) args[0];
            else
            static if (is(A[0] : const(char)[]) && !is(T : const(char)[]) && is(T == enum))
            {
                S: switch (args[0])
                {
                    static foreach(member; __traits(allMembers, T))
                    {
                        case member:
                            return __traits(getMember, T, member);
                    }
                default:
                    static immutable msg = "Can not convert string to the enum " ~ T.stringof;
                    version (D_Exceptions)
                    {
                        static immutable Exception exc = new Exception(msg);
                        throw exc;
                    }
                    else
                    {
                        assert(0, msg);
                    }
                }
            }
            else
                static assert(0);
        }
        else
            static assert(0);
    }
}

///
version(mir_core_test)
@safe pure @nogc
unittest
{
    enum Foo
    {
        A,
        B,
        C,
    }

    assert(to!Foo("B") == Foo.B);
}

/++
Emplace helper function.
+/
void emplaceInitializer(T)(scope ref T chunk) @trusted pure nothrow

{
    // Emplace T.init.
    // Previously, an immutable static and memcpy were used to hold an initializer.
    // With improved unions, this is no longer needed.
    union UntypedInit
    {
        T dummy;
    }
    static struct UntypedStorage
    {
        align(T.alignof) void[T.sizeof] dummy;
    }

    () @trusted {
        *cast(UntypedStorage*) &chunk = cast(UntypedStorage) UntypedInit.init;
    } ();
}

/++
+/
T[] uninitializedFillDefault(T)(return scope T[] array) nothrow @nogc
{
    static if (__VERSION__ < 2083)
    {
        static if (__traits(isIntegral, T) && 0 == cast(T) (T.init + 1))
        {
            import core.stdc.string : memset;
            memset(array.ptr, 0xff, T.sizeof * array.length);
            return array;
        }
        else
        {
            pragma(inline, false);
            foreach(ref e; array)
                emplaceInitializer(e);
            return array;
        }
    }
    else
    {
        static if (__traits(isZeroInit, T))
        {
            import core.stdc.string : memset;
            memset(array.ptr, 0, T.sizeof * array.length);
            return array;
        }
        else static if (__traits(isIntegral, T) && 0 == cast(T) (T.init + 1))
        {
            import core.stdc.string : memset;
            memset(array.ptr, 0xff, T.sizeof * array.length);
            return array;
        }
        else
        {
            pragma(inline, false);
            foreach(ref e; array)
                emplaceInitializer(e);
            return array;
        }
    }
}

///
version(mir_core_test)
pure nothrow @nogc
@system unittest
{
    static struct S { int x = 42; @disable this(this); }

    int[5] expected = [42, 42, 42, 42, 42];
    S[5] arr = void;
    uninitializedFillDefault(arr);
    assert((cast(int*) arr.ptr)[0 .. arr.length] == expected);
}

///
version(mir_core_test)
@system unittest
{
    int[] a = [1, 2, 4];
    uninitializedFillDefault(a);
    assert(a == [0, 0, 0]);
}

/++
Destroy structs and unions usnig `__xdtor` member if any.
Do nothing for other types.
+/
void xdestroy(T)(scope T[] ar)
{
    static if ((is(T == struct) || is(T == union)) && __traits(hasMember, T, "__xdtor"))
    {
        static if (__traits(isSame, T, __traits(parent, ar[0].__xdtor)))
        {
            pragma(inline, false);
            foreach (ref e; ar)
                e.__xdtor();
        }
    }
}

///
version(mir_core_test)
nothrow @nogc unittest
{
    __gshared int d;
    __gshared int c;
    struct D { ~this() nothrow @nogc {d++;} }
    extern(C++)
    struct C { ~this() nothrow @nogc {c++;} }
    C[2] carray;
    D[2] darray;
    carray.xdestroy;
    darray.xdestroy;
    assert(c == 2);
    assert(d == 2);
    c = 0;
    d = 0;
}


template emplaceRef(T)
{
    void emplaceRef(UT, Args...)(ref UT chunk, auto ref Args args)
    {
        import core.internal.lifetime: emplaceRef;
        return emplaceRef!T(chunk, args);
    }
}

void emplaceRef(UT, Args...)(ref UT chunk, auto ref Args args)
if (is(UT == Unqual!UT))
{
    import core.lifetime: forward;
    emplaceRef!UT(chunk, forward!args);
}
