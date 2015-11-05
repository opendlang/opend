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
        foreach (annotation; Attr)
            static if (hasAnnotation!(f, annotation))
                return true;
        return false;
    })();
}

template hasValueAnnotation(alias f, Attr)
{
    enum bool hasValueAnnotation = (function() {
        foreach (attr; __traits(getAttributes, f))
            static if (is(typeof(attr) == Attr))
                return true;
        return false;
    })();
}

template hasAnyOfTheseValueAnnotations(alias f, Attr...)
{
    enum bool hasAnyOfTheseValueAnnotations = (function() {
        foreach (annotation; Attr)
            static if (hasValueAnnotation(f, annotation))
                return true;
        return false;
    })();
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
