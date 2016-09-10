module painlesstraits;

import std.traits;

template hasAnnotation(alias f, alias Attr)
{
    import std.typetuple : anySatisfy, TypeTuple;

    alias allAnnotations = TypeTuple!(__traits(getAttributes, f));
    template hasMatch(alias attr) {
        static if(is(Attr)) {
            alias hasMatch = Identity!(is(typeof(attr) == Attr) || is(attr == Attr));
        } else {
            alias hasMatch = Identity!(is(attr == Attr));
        }
    }
    enum bool hasAnnotation = anySatisfy!(hasMatch, allAnnotations);
}

unittest
{
    enum FooUDA;
    enum BarUDA;
    @FooUDA int x;

    static assert(hasAnnotation!(x, FooUDA));
    static assert(!hasAnnotation!(x, BarUDA));
}

template hasAnyOfTheseAnnotations(alias f, Attr...)
{
    enum bool hasAnyOfTheseAnnotations = (function() {
        bool any = false;
        foreach (annotation; Attr)
        {
            any |= hasAnnotation!(f, annotation);
        }
        return any;
    })();
}

version (unittest)
{
    // Some types are outside unittest block since old compilers couldn't find them otherwise
    // This might indicate brittleness of these functions but I'm not sure how to fix that
    enum AnyFooUDA;
    enum AnyBazUDA;
    enum AnyQuxUDA;
    struct AnyBarUDA { int data; }
    @AnyFooUDA @(AnyBarUDA(1)) int anyx;
    @(AnyBarUDA(1)) int anyy;
    @AnyFooUDA int anyz;
}

unittest
{
    static assert(!hasAnyOfTheseAnnotations!(anyy, AnyBazUDA, AnyQuxUDA));
    static assert(!hasAnyOfTheseAnnotations!(anyx, AnyBazUDA));
    static assert(!hasAnyOfTheseAnnotations!(anyx, AnyQuxUDA));
    static assert(hasAnyOfTheseAnnotations!(anyz, AnyFooUDA, AnyBarUDA));
    static assert(hasAnyOfTheseAnnotations!(anyx, AnyBarUDA, AnyQuxUDA));
}

template hasValueAnnotation(alias f, alias Attr)
{
    import std.typetuple : anySatisfy, TypeTuple;

    alias allAnnotations = TypeTuple!(__traits(getAttributes, f));
    alias hasMatch(alias attr) = Identity!(is(Attr) && is(typeof(attr) == Attr));
    enum bool hasValueAnnotation = anySatisfy!(hasMatch, allAnnotations);
}

unittest
{
    enum FooUDA;
    struct BarUDA { int data; }
    @FooUDA int x;
    @FooUDA @(BarUDA(1)) int y;

    static assert(!hasValueAnnotation!(x, BarUDA));
    static assert(!hasValueAnnotation!(x, FooUDA));
    static assert(hasValueAnnotation!(y, BarUDA));
    static assert(!hasValueAnnotation!(y, FooUDA));
}

template hasAnyOfTheseValueAnnotations(alias f, Attr...)
{
    enum bool hasAnyOfTheseValueAnnotations = (function() {
        bool any = false;
        foreach (annotation; Attr)
        {
            any |= hasValueAnnotation!(f, annotation);
        }
        return any;
    })();
}

unittest
{
    static assert(!hasAnyOfTheseValueAnnotations!(anyz, AnyBarUDA));
    static assert(!hasAnyOfTheseValueAnnotations!(anyz, AnyBarUDA, AnyFooUDA));
    static assert(hasAnyOfTheseValueAnnotations!(anyx, AnyBarUDA));
    static assert(!hasAnyOfTheseValueAnnotations!(anyx, AnyFooUDA));
    static assert(hasAnyOfTheseValueAnnotations!(anyx, AnyFooUDA, AnyBarUDA));
    static assert(hasAnyOfTheseValueAnnotations!(anyy, AnyBarUDA, AnyFooUDA));
}

template getAnnotation(alias f, Attr)
{
    static if (hasValueAnnotation!(f, Attr)) {
        enum getAnnotation = (function() {
            foreach (attr; __traits(getAttributes, f))
                static if (is(typeof(attr) == Attr))
                    return attr;
            assert(0);
        })();
    } else static assert(0);
}

unittest
{
    static assert(getAnnotation!(anyy, AnyBarUDA).data == 1);
}

template isField(alias T)
{
    enum isField = (function() {
        // isTemplate is relatively new only use it if it exists
        static if (__traits(compiles, __traits(isTemplate, T)))
            return (!isSomeFunction!(T) && !__traits(isTemplate, T));
        else
            return (!isSomeFunction!(T));
    })();
}

unittest
{
    struct Foo {
        @property auto property() { return 1.0; }
        auto func() { return 1.0; }
        auto tmplt()() {return 1.0; }
        auto field = 0;
    }

    static assert( !isField!(Foo.property) );
    static assert( !isField!(Foo.func) );

    static if (__traits(compiles, __traits(isTemplate, Foo.tmplt)))
    {
        static assert( !isField!(Foo.tmplt) );
        static assert( !isSomeFunction!(Foo.tmplt) );
    }

    static assert( isField!(Foo.field) );

    // Make sure the struct behaves as expected
    Foo foo;
    assert( foo.property == 1.0 );
    assert( foo.func() == 1.0 );
    assert( foo.tmplt() == 1.0 );
    assert( foo.field == 0.0 );
}

template isFieldOrProperty(alias T)
{
    enum isFieldOrProperty = (function() {
        static if (isField!(T))
        {
            return true;
        } 
        else static if (isSomeFunction!(T))
        {
            return (functionAttributes!(T) & FunctionAttribute.property);
        } else 
            return false;
    })();
}

unittest {
    struct Foo {
        int success;
        int failure(int x) {return x;}
    }

    static assert(isFieldOrProperty!(Foo.success));
    static assert(!isFieldOrProperty!(Foo.failure));

    // Make sure the struct behaves as expected
    Foo foo;
    assert( foo.failure(1) == 1 );
}

private template publicMemberFilter(T, alias filter)
{
    template Filter(alias memberName)
    {
        static if (is(T == class))
        {
            static if (is(typeof(__traits(getMember, T, memberName))))
            {
                static if (isSomeFunction!(__traits(getMember, T, memberName)))
                {
                    static if (!__traits(compiles, { auto foo = __traits(getMember, T, memberName); }))
                    {
                        enum Filter = filter!(__traits(getMember, T, memberName));
                    }
                    else
                        enum Filter = false;
                }
                else
                {
                    static if (!__traits(compiles, { auto foo = &__traits(getMember, T, memberName); }))
                    {
                        enum Filter = filter!(__traits(getMember, T, memberName));
                    }
                    else
                        enum Filter = false;
                }
            }
            else
                enum Filter = false;
        }
        else
        {
            static if (is(typeof(__traits(getMember, T.init, memberName))))
            {
                static if (__traits(compiles, { enum Foo = __traits(getMember, T.init, memberName); }))
                {
                    enum Filter = filter!(__traits(getMember, T.init, memberName));
                }
                else
                    enum Filter = false;
            }
            else
                enum Filter = false;
        }
    }
}

// from std.meta to support older compilers
private template AliasSeq(TList...)
{
    alias AliasSeq = TList;
}

private template Filter(alias pred, TList...)
{
    static if (TList.length == 0)
    {
        alias Filter = AliasSeq!();
    }
    else static if (TList.length == 1)
    {
        static if (pred!(TList[0]))
            alias Filter = AliasSeq!(TList[0]);
        else
            alias Filter = AliasSeq!();
    }
    else
    {
        alias Filter =
            AliasSeq!(
                Filter!(pred, TList[ 0  .. $/2]),
                Filter!(pred, TList[$/2 ..  $ ]));
    }
}

template allPublicFieldsOrProperties(T)
{
    enum allPublicFieldsOrProperties = Filter!(publicMemberFilter!(T, isFieldOrProperty).Filter, __traits(allMembers, T));
    static assert(allPublicFieldsOrProperties.length > 0, "No properties for type " ~ T.stringof);
}

template allPublicFields(T)
{
    enum allPublicFields = Filter!(publicMemberFilter!(T, isField).Filter, __traits(allMembers, T));
    static assert(allPublicFields.length > 0, "No properties for type " ~ T.stringof);
}

unittest {
    import std.typecons : Tuple;
    // toString is template, should be ignored
    static assert(!isFieldOrProperty!(Tuple!(int)(0).toString));
}
