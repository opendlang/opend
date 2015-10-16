module painlesstraits;

import std.traits;

public:

template hasAnnotation(alias f, Attr)
{
    static bool helper()
    {
        foreach (attr; __traits(getAttributes, f))
            static if (is(attr == Attr) || is(typeof(attr) == Attr))
                return true;
        return false;
    }

    enum bool hasAnnotation = helper;
}

template hasAnyOfTheseAnnotations(alias f, Attr...)
{
    static bool helper()
    {
        foreach (annotation; Attr)
            static if (hasAnnotation!(f, annotation))
                return true;
        return false;
    }

    enum bool hasAnyOfTheseAnnotations = helper;
}

template hasValueAnnotation(alias f, Attr)
{
    static bool helper()
    {
        foreach (attr; __traits(getAttributes, f))
            static if (is(typeof(attr) == Attr))
                return true;
        return false;
    }

    enum bool hasValueAnnotation = helper;
}

template hasAnyOfTheseValueAnnotations(alias f, Attr...)
{
    static bool helper()
    {
        foreach (annotation; Attr)
            static if (hasValueAnnotation(f, annotation))
                return true;
        return false;
    }

    enum bool hasAnyOfTheseValueAnnotations = helper;
}

template getAnnotation(alias f, Attr)
	if (hasValueAnnotation!(f, Attr))
{
    static auto helper()
    {
        foreach (attr; __traits(getAttributes, f))
            static if (is(typeof(attr) == Attr))
                return attr;
        assert(0);
    }

    enum getAnnotation = helper;
}

template isFieldOrProperty(alias T)
{
    static bool helper()
    {
        static if (isSomeFunction!(T))
        {
            return (functionAttributes!(T) & FunctionAttribute.property) != 0;
        }
        else
        {
            return true;
        }
    }

    enum isFieldOrProperty = helper;
}
