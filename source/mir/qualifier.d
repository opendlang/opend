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
template LightScopeOf(T)
{
    static if (isPointer!T)
    {
        alias LightScopeOf = T;
    }
    else
    {
        static if (__traits(hasMember, T, "lightScope"))
            alias LightScopeOf = typeof(T.init.lightScope());
        else
        static if (is(T == immutable))
            alias LightScopeOf = LightImmutableOf!T;
        else
        static if (is(T == const))
            alias LightScopeOf = LightConstOf!T;
        else
            alias LightScopeOf = T;
    }
}

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

/++
Tries to strip a reference counting handles from the value.
This funciton should be used only when the result never skips the current scope.

This function is used by some algorithms to optimise work with reference counted types.
+/
auto ref lightScope(T)(auto ref return T v)
    if (!is(T : P*, P) && __traits(hasMember, T, "lightScope"))
{
    return v.lightScope;
}

/// ditto
auto ref lightScope(T)(auto return ref T v)
    if (is(T : P*, P) || !__traits(hasMember, T, "lightScope"))
{
    static if (is(T == immutable))
        return lightImmutable(v);
    else
    static if (is(T == const))
        return lightConst(v);
    else
        return v;
}

///
auto lightImmutable(T)(auto ref immutable T v)
    if (!is(T : P*, P) && __traits(hasMember, immutable T, "lightImmutable"))
{
    return v.lightImmutable;
}

/// ditto
T lightImmutable(T)(auto ref immutable T e)
    if (!isDynamicArray!T && isImplicitlyConvertible!(immutable T, T) && !__traits(hasMember, immutable T, "lightImmutable"))
{
    return e;
}

/// ditto
auto lightImmutable(T)(immutable(T)[] e)
{
    return e;
}

/// ditto
auto lightImmutable(T)(immutable(T)* e)
{
    return e;
}

///
auto lightConst(T)(auto ref const T v)
    if (!is(T : P*, P) && __traits(hasMember, const T, "lightConst"))
{
    return v.lightConst;
}

/// ditto
auto lightConst(T)(auto ref immutable T v)
    if (!is(T : P*, P) && __traits(hasMember, immutable T, "lightConst"))
{
    return v.lightConst;
}

/// ditto
T lightConst(T)(auto ref const T e)
    if (!isDynamicArray!T && isImplicitlyConvertible!(const T, T) && !__traits(hasMember, const T, "lightConst"))
{
    return e;
}

/// ditto
T lightConst(T)(auto ref immutable T e)
    if (!isDynamicArray!T && isImplicitlyConvertible!(immutable T, T) && !__traits(hasMember, immutable T, "lightConst"))
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
auto lightConst(T)(const(T)* e)
{
    return e;
}

/// ditto
auto lightConst(T)(immutable(T)* e)
{
    return e;
}

///
auto trustedImmutable(T)(auto ref const T e) @trusted
{
    return lightImmutable(*cast(immutable) &e);
}
