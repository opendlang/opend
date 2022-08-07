/++
Conversion utilities.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
Authors: Ilia Ki
+/
module mir.conv;

public import core.lifetime: emplace;

import std.traits;

private template isMirString(T)
{
    static if (isSomeString!T)
    {
        enum isMirString = true;
    }
    else
    {
        static if (__traits(compiles, {import mir.small_string;}))
        {
            import mir.small_string;
            enum isMirString = is(T : SmallString!size, size_t size);
        }
        else
        {
            enum isMirString = false;
        }
    }
}

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
        import mir.utility;
        import mir.functional: forward;
        static if (A.length == 1 && isImplicitlyConvertible!(A[0], T))
            return args[0];
        else
        static if (is(T == class) && is(typeof(new T(forward!args))))
            return new T(forward!args);
        else
        static if (is(typeof(T(args))))
            return T(forward!args);
        else
        static if (A.length == 1)
        {
            alias I = A[0];
            alias arg = args[0];
            static if (is(typeof(cast(T) arg)) && !(isDynamicArray!T && isDynamicArray!I) && !isSomeString!T)
                return cast(T) forward!arg;
            else
            static if (isSomeString!I && is(T == enum))
            {
                import mir.enums;
                uint index = void;
                if (getEnumIndexFromKey!T(arg, index)._expect(true))
                    return index.unsafeEnumFromIndex!T;
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
            else
            static if (is(I == enum) && isSomeString!T)
            {
                import mir.enums;
                uint id = void;
                if (getEnumIndex(arg, id)._expect(true))
                    return enumStrings!I[id];
                assert(0);
            }
            else
            static if (isMirString!I && !isSomeString!T)
            {
                static assert (__traits(compiles, { import mir.parse: fromString; }));
                import mir.parse: fromString;
                return fromString!(Unqual!T)(arg[]);
            }
            else
            static if (!isSomeString!I && isMirString!T)
            {
                // static if (is(Unqual!I == typeof(null)))
                // {
                //     enum immutable(T) ret = "null";
                //     static if (isImplicitlyConvertible!(immutable T, T))
                //         return ret;
                //     else
                //         return .to!T(ret[]);
                // }
                // else
                static if (is(Unqual!I == bool))
                {
                    enum immutable(T) t = "true";
                    enum immutable(T) f = "false";
                    auto ret = arg ? t : f;
                    static if (isImplicitlyConvertible!(immutable T, T))
                        return ret;
                    else
                        return .to!T(ret[]);
                }
                else
                {
                    static if (isImplicitlyConvertible!(T, string) && __traits(compiles, () {const(char)[] s =  arg.toString; return s;}))
                    {
                        auto ret = arg.toString;
                        static if (is(typeof(ret) == string))
                            return ret;
                        else
                            return ret.idup;
                    }
                    else
                    {
                        static assert (__traits(compiles, { import mir.format: print; }));
                        import mir.format: print;
                        static if (isSomeString!T)
                        {
                            static if (isNumeric!I)
                            {
                                import mir.appender: UnsafeArrayBuffer;
                                alias C = Unqual!(ForeachType!T);
                                C[64] array = '\0';
                                auto buffer = UnsafeArrayBuffer!C(array);
                            }
                            else
                            {
                                import mir.appender: scopedBuffer;
                                auto buffer = scopedBuffer!(Unqual!(ForeachType!T));
                            }
                            buffer.print(arg);
                            static if (isMutable!(ForeachType!(T)))
                                return buffer.data.dup;
                            else
                                return buffer.data.idup;
                        }
                        else
                        {
                            Unqual!T buffer;
                            buffer.print(arg);
                            return buffer;
                        }
                    }
                }
            }
            else
            static if (is(I : const(C)[], C) && is(T : immutable(C)[]))
            {
                static if (is(I : immutable(C)[]))
                    return arg;
                else
                    return idup(arg);
            }
            else
            static if (is(I : const(D)[], D) && is(T : D[]))
            {
                static if (is(I : D[]))
                    return arg;
                else
                    return dup(arg);
            }
            else 
                static assert(0, T.stringof);
        }
        else
            static assert(0, T.stringof);
    }
}

///
@safe pure @nogc
version(mir_core_test) unittest
{
    enum E
    {
        A,
        B,
        C,
    }

    assert(to!E("B") == E.B);
    assert(to!string(E.B) == "B");
    assert(to!string(null) is null);
    assert(to!string(true) == "true");
    assert(to!string(false) == "false");

    enum S : wstring
    {
        a = "A",
        b = "B",
    }

    assert(to!wstring(S.b) == "B"w);
    assert(to!S("B"w) == S.b);
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
pure nothrow @nogc @system
version(mir_core_test) unittest
{
    static struct S { int x = 42; @disable this(this); }

    int[5] expected = [42, 42, 42, 42, 42];
    S[5] arr = void;
    uninitializedFillDefault(arr);
    assert((cast(int*) arr.ptr)[0 .. arr.length] == expected);
}

///
@system 
version(mir_core_test) unittest
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
            foreach_reverse (ref e; ar)
                e.__xdtor();
        }
    }
}

///
nothrow @nogc version(mir_core_test) unittest
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
        import core.lifetime: forward;
        import core.internal.lifetime: emplaceRef;
        return emplaceRef!T(chunk, forward!args);
    }
}

void emplaceRef(UT, Args...)(ref UT chunk, auto ref Args args)
if (is(UT == Unqual!UT))
{
    import core.lifetime: forward;
    emplaceRef!UT(chunk, forward!args);
}
