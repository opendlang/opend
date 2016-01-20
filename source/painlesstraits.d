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

unittest
{
    enum FooUDA;
    enum BazUDA;
    enum QuxUDA;
    struct BarUDA { int data; }
    @FooUDA @(BarUDA(1)) int x;
    @(BarUDA(1)) int y;

    static assert(!hasAnyOfTheseAnnotations!(y, BazUDA, QuxUDA));
    static assert(!hasAnyOfTheseAnnotations!(x, BazUDA));
    static assert(!hasAnyOfTheseAnnotations!(x, QuxUDA));
    static assert(hasAnyOfTheseAnnotations!(x, FooUDA, BarUDA));
    static assert(hasAnyOfTheseAnnotations!(x, BarUDA, QuxUDA));
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
    enum FooUDA;
    struct BarUDA { int data; }
    @FooUDA int x;
    @FooUDA @(BarUDA(1)) int y;

    static assert(!hasAnyOfTheseValueAnnotations!(x, BarUDA));
    static assert(!hasAnyOfTheseValueAnnotations!(x, BarUDA, FooUDA));
    static assert(hasAnyOfTheseValueAnnotations!(y, BarUDA));
    static assert(!hasAnyOfTheseValueAnnotations!(y, FooUDA));
    static assert(hasAnyOfTheseValueAnnotations!(y, FooUDA, BarUDA));
    static assert(hasAnyOfTheseValueAnnotations!(y, BarUDA, FooUDA));
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

template isFieldOrProperty(alias T)
{
    enum isFieldOrProperty = (function() {
        static if (isSomeFunction!(T))
        {
            return (functionAttributes!(T) & FunctionAttribute.property) != 0;
        }
        else return true;
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
