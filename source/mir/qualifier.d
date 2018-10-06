/++

Copyright: Ilya Yaroshenko 2018-.
License:   $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors:   Ilya Yaroshenko

Macros:
NDSLICE = $(REF_ALTTEXT $(TT $2), $2, mir, ndslice, $1)$(NBSP)
+/
module mir.qualifier;

import std.traits;

/++
+/
template LightConstOf(T)
{
    static if (isPointer!T)
    {
        alias LightConstOf = const(PointerTarget!T)*;
    }
    else
    {
        alias LightConstOf = typeof(const(T).init.lightConst());
    }
}

/// ditto
template LightImmutableOf(T)
{
    static if (isPointer!T)
    {
        alias LightImmutableOf = immutable(PointerTarget!T)*;
    }
    else
    {
        alias LightImmutableOf = typeof(immutable(T).init.lightImmutable());
    }
}

@property:

/// ditto
auto lightImmutable(T)(auto ref immutable T v)
    if (!is(T : P*, P) && __traits(hasMember, immutable T, "lightImmutable"))
{
    return v.lightImmutable;
}

///
auto lightConst(T)(auto ref const T v)
    if (!is(T : P*, P) && __traits(hasMember, const T, "lightConst"))
{
    return v.lightConst;
}

///
auto lightConst(T)(auto ref immutable T v)
    if (!is(T : P*, P) && __traits(hasMember, immutable T, "lightConst"))
{
    return v.lightConst;
}

/// ditto
T lightConst(T)(auto ref const T e)
    if (isImplicitlyConvertible!(const T, T) && !__traits(hasMember, const T, "lightConst"))
{
    return e;
}

/// ditto
T lightConst(T)(auto ref immutable T e)
    if (isImplicitlyConvertible!(immutable T, T) && !__traits(hasMember, immutable T, "lightConst"))
{
    return e;
}

/// ditto
T lightImmutable(T)(auto ref immutable T e)
    if (isImplicitlyConvertible!(immutable T, T) && !__traits(hasMember, immutable T, "lightImmutable"))
{
    return e;
}

/// ditto
auto lightConst(T)(const(T)[] e)
{
    return e;
}

/// ditto
auto lightConst(T)(immutable(T)[] e)
{
    return e;
}

/// ditto
auto lightImmutable(T)(immutable(T)[] e)
{
    return e;
}

/// ditto
auto lightConst(T)(const(T)* e)
{
    return e;
}

/// ditto
auto lightConst(T)(immutable(T)* e)
{
    return e;
}

/// ditto
auto lightImmutable(T)(immutable(T)* e)
{
    return e;
}

/// ditto
auto trustedImmutable(T)(auto ref const T e) @trusted
{
    return lightImmutable(cast(immutable) e);
}
