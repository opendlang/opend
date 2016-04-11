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
        return (!isSomeFunction!(T) && !__traits(isTemplate, T));
    })();
}

unittest
{
    struct S {
        @property auto property() { return 1.0; }
        auto func() { return 1.0; }
        auto tmplt()() {return 1.0; }
        auto field = 0;
    }

    S s;
    static assert( !isField!(s.property) );
    static assert( !isField!(s.func) );
    static assert( !isField!(s.tmplt) );
    static assert( !isSomeFunction!(s.tmplt) );
    static assert( __traits(isTemplate,s.tmplt) );

    static assert( isField!(s.field) );
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
}

unittest {
    import std.typecons : Tuple;
    // toString is template, should be ignored
    static assert(!isFieldOrProperty!(Tuple!(int)(0).toString));
}
