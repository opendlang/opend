/**
 * Templates for determining data storage types.
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module containers.internal.storage_type;

/**
 * This template is used to determine the type that a container should contain
 * a given type T.
 *
 * $(P In many cases it is not possible for a Container!(T) to hold T if T is
 * $(B const) or $(B immutable). For instance, a binary heap will need to
 * rearrange items in its internal data storage, or an unrolled list will need
 * to move items within a node.)
 *
 * $(P All containers must only return const references or const copies of data
 * stored within them if the contained type is const. This template exists
 * because containers may need to move entire items but not change internal
 * state of those items and D's type system would otherwise not allow this.)
 *
 * $(UL
 * $(LI If $(B T) is mutable (i.e. not $(B immutable) or $(B const)), this
 * template aliases itself to T.)
 * $(LI $(B Class and Interface types:) Rebindable is used. Using this properly
 *     in a container requires that $(LINK2 https://issues.dlang.org/show_bug.cgi?id=8663,
 *     issue 8663) be fixed. Without this fix it is not possible to implement
 *     containers such as a binary heap that must compare container elements
 *     using $(B opCmp()))
 * $(LI $(B Struct and Union types:)
 *     $(UL
 *         $(LI Stuct and union types that have elaborate constructors,
 *         elaboriate opAssign, or a destructor cannot be stored in containers
 *         because there may be user-visible effects of discarding $(B const)
 *         or $(B immutable) on these struct types.)
 *         $(LI Other struct and union types will be stored as non-const
 *         versions of themselves.)
 *     ))
 * $(LI $(B Basic types:) Basic types will have their const or immutable status
 *     removed.)
 * $(LI $(B Pointers:) Pointers will have their type constructors shifted. E.g.
 *     const(int*) becomes const(int)*)
 * )
 */
template ContainerStorageType(T)
{
	import std.traits : hasElaborateCopyConstructor, hasElaborateDestructor,
		hasElaborateAssign, isBasicType, isDynamicArray, isPointer, Unqual;
	import std.typecons : Rebindable;
	static if (is (T == const) || is (T == immutable))
	{
		static if (isBasicType!T || isDynamicArray!T || isPointer!T)
			alias ContainerStorageType = Unqual!T;
		else static if (is (T == class) || is (T == interface))
			alias ContainerStorageType = Rebindable!T;
		else static if (is (T == struct))
		{
			alias U = Unqual!T;
			static if (hasElaborateAssign!U || hasElaborateCopyConstructor!U || hasElaborateDestructor!U)
				static assert (false, "Cannot store " ~ T.stringof ~ " because of postblit, opAssign, or ~this");
			else
				alias ContainerStorageType = U;
		}
		else
			static assert (false, "Don't know how to handle type " ~ T.stringof);
	}
	else
		alias ContainerStorageType = T;
}

///
unittest
{
	static assert (is (ContainerStorageType!(int) == int));
	static assert (is (ContainerStorageType!(const int) == int));
}

///
unittest
{
	import std.typecons : Rebindable;
	static assert (is (ContainerStorageType!(Object) == Object));
	static assert (is (ContainerStorageType!(const(Object)) == Rebindable!(const(Object))));
}

///
unittest
{
	struct A { int foo; }
	struct B { void opAssign(typeof(this)) { this.foo *= 2; }  int foo;}

	// A can be stored easily because it is plain data
	static assert (is (ContainerStorageType!(A) == A));
	static assert (is (ContainerStorageType!(const(A)) == A));

	// const(B) cannot be stored in the container because of its
	// opAssign. Casting away const could lead to some very unexpected
	// behavior.
	static assert (!is (typeof(ContainerStorageType!(const(B)))));
	// Mutable B is not a problem
	static assert (is (ContainerStorageType!(B) == B));

	// Arrays can be stored because the entire pointer-length pair is moved as
	// a unit.
	static assert (is (ContainerStorageType!(const(int[])) == const(int)[]));
}

///
unittest
{
	static assert (is (ContainerStorageType!(const(int*)) == const(int)*));
}
