/**
 * Templates for determining range return types.
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */

module containers.internal.element_type;

/**
 * Figures out the types that should be shown to users of the containers when
 * functions such as front and opIndex are called.
 *
 * Params:
 *     ContainerType = The container type, usually taken from a `this This`
 *         template argument
 *     ElementType = The type of the elements of the container.
 *     isRef = If the type is being determined for a function that returns `ref`
 */
template ContainerElementType(ContainerType, ElementType, bool isRef = false)
{
	import std.traits : isMutable, hasIndirections, PointerTarget, isPointer, Unqual;

	template ET(bool isConst, T)
	{
		static if (isPointer!ElementType)
		{
			enum PointerIsConst = is(ElementType == const);
			enum PointerIsImmutable = is(ElementType == immutable);
			enum DataIsConst = is(PointerTarget!(ElementType) == const);
			enum DataIsImmutable = is(PointerTarget!(ElementType) == immutable);
			static if (isConst)
			{
				static if (PointerIsConst)
					alias ET = ElementType;
				else static if (PointerIsImmutable)
					alias ET = ElementType;
				else
					alias ET = const(PointerTarget!(ElementType))*;
			}
			else
			{
				static assert(DataIsImmutable, "An immutable container cannot reference const or mutable data");
				static if (PointerIsConst)
					alias ET = immutable(PointerTarget!ElementType)*;
				else
					alias ET = ElementType;
			}
		}
		else
		{
			static if (isConst)
			{
				static if (is(ElementType == immutable))
					alias ET = ElementType;
				else
					alias ET = const(Unqual!ElementType);
			}
			else
				alias ET = immutable(Unqual!ElementType);
		}
	}

	static if (isMutable!ContainerType)
	{
		alias ContainerElementType = ElementType;
	}
	else
	{
		static if (isRef || hasIndirections!ElementType)
			alias ContainerElementType = ET!(is(ContainerType == const), ElementType);
		else
			alias ContainerElementType = ElementType;
	}
}

unittest
{
	static struct Container {}
	static struct Data1 { int* x; }
	static class Data2 { int* x; }

	static assert(is(ContainerElementType!(Container, int) == int));
	static assert(is(ContainerElementType!(Container, const int) == const int));
	static assert(is(ContainerElementType!(Container, immutable int) == immutable int));
	static assert(is(ContainerElementType!(const Container, int) == int));
	static assert(is(ContainerElementType!(const Container, const int) == const int));
	static assert(is(ContainerElementType!(const Container, immutable int) == immutable int));
	static assert(is(ContainerElementType!(immutable Container, int) == int));
	static assert(is(ContainerElementType!(immutable Container, const int) == const int));
	static assert(is(ContainerElementType!(immutable Container, immutable int) == immutable int));

	static assert(is(ContainerElementType!(Container, Data1) == Data1));
	static assert(is(ContainerElementType!(Container, const Data1) == const Data1));
	static assert(is(ContainerElementType!(Container, immutable Data1) == immutable Data1));
	static assert(is(ContainerElementType!(const Container, Data1) == const Data1));
	static assert(is(ContainerElementType!(const Container, const Data1) == const Data1));
	static assert(is(ContainerElementType!(const Container, immutable Data1) == immutable Data1));
	static assert(is(ContainerElementType!(immutable Container, Data1) == immutable Data1));
	static assert(is(ContainerElementType!(immutable Container, const Data1) == immutable Data1));
	static assert(is(ContainerElementType!(immutable Container, immutable Data1) == immutable Data1));

	static assert(is(ContainerElementType!(Container, Data2) == Data2));
	static assert(is(ContainerElementType!(Container, const Data2) == const Data2));
	static assert(is(ContainerElementType!(Container, immutable Data2) == immutable Data2));
	static assert(is(ContainerElementType!(const Container, Data2) == const Data2));
	static assert(is(ContainerElementType!(const Container, const Data2) == const Data2));
	static assert(is(ContainerElementType!(const Container, immutable Data2) == immutable Data2));
	static assert(is(ContainerElementType!(immutable Container, Data2) == immutable Data2));
	static assert(is(ContainerElementType!(immutable Container, const Data2) == immutable Data2));
	static assert(is(ContainerElementType!(immutable Container, immutable Data2) == immutable Data2));

	static assert(is(ContainerElementType!(Container, int*) == int*));
	static assert(is(ContainerElementType!(Container, const int*) == const int*));
	static assert(is(ContainerElementType!(Container, const(int)*) == const(int)*));
	static assert(is(ContainerElementType!(Container, immutable int*) == immutable int*));
	static assert(is(ContainerElementType!(Container, immutable(int)*) == immutable(int)*));

	static assert(is(ContainerElementType!(Container, Data1*) == Data1*));
	static assert(is(ContainerElementType!(Container, const Data1*) == const Data1*));
	static assert(is(ContainerElementType!(Container, const(Data1)*) == const(Data1)*));
	static assert(is(ContainerElementType!(Container, immutable Data1*) == immutable Data1*));
	static assert(is(ContainerElementType!(Container, immutable(Data1)*) == immutable(Data1)*));

	static assert(is(ContainerElementType!(const Container, int*) == const(int)*));
	static assert(is(ContainerElementType!(const Container, const int*) == const int*));
	static assert(is(ContainerElementType!(const Container, const(int)*) == const(int)*));
	static assert(is(ContainerElementType!(const Container, immutable int*) == immutable int*));
	static assert(is(ContainerElementType!(const Container, immutable(int)*) == immutable(int)*));

	static assert(!__traits(compiles, ContainerElementType!(immutable Container, int*)));
	static assert(!__traits(compiles, ContainerElementType!(immutable Container, const int*)));

	static assert(is(ContainerElementType!(immutable Container, immutable int*) == immutable int*));
	static assert(is(ContainerElementType!(immutable Container, immutable(int)*) == immutable(int)*));
}
