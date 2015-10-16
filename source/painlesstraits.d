module painlesstraits;

import std.traits;

template hasAnnotation(alias f, Attr)
{
    enum bool hasAnnotation = (function() {
        foreach (attr; __traits(getAttributes, f))
            static if (is(attr == Attr) || is(typeof(attr) == Attr))
                return true;
        return false;
    })();
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
