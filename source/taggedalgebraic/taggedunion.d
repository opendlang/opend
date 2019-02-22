/**
 * Generic tagged union and algebraic data type implementations.
 *
 * Copyright: Copyright 2015-2019, Sönke Ludwig.
 * License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Sönke Ludwig
*/
module taggedalgebraic.taggedunion;

import std.algorithm.mutation : move, swap;
import std.meta;
import std.traits : EnumMembers, FieldNameTuple, Unqual, isInstanceOf;


/** Implements a generic tagged union type.

	This struct takes a `union` or `struct` declaration as an input and builds
	an algebraic data type from its fields, using an automatically generated
	`Kind` enumeration to identify which field of the union is currently used.
	Multiple fields with the same value are supported.

	For each field defined by `U` a number of convenience members are generated.
	For a given field "foo", these fields are:

	$(UL
		$(LI `static foo(value)`) - returns a new tagged union with the specified value)
		$(LI `isFoo` - equivalent to `kind == Kind.foo`)
		$(LI `setFoo(value)` - equivalent to `set!(Kind.foo)(value)`)
		$(LI `getFoo` - equivalent to `get!(Kind.foo)`)
	)
*/
struct TaggedUnion(U) if (is(U == union) || is(U == struct) || is(U == enum))
{
	import std.traits : FieldTypeTuple, FieldNameTuple, Largest,
		hasElaborateCopyConstructor, hasElaborateDestructor, isCopyable;
	import std.ascii : toUpper;

	alias FieldDefinitionType = U;

	/// A type enum that identifies the type of value currently stored.
	alias Kind = UnionFieldEnum!U;

	alias FieldTypes = UnionKindTypes!Kind;
	alias fieldNames = UnionKindNames!Kind;

	static assert(FieldTypes.length > 0, "The TaggedUnions's union type must have at least one field.");
	static assert(FieldTypes.length == fieldNames.length);

	package alias FieldTypeByName(string name) = FieldTypes[__traits(getMember, Kind, name)];

	private {
		static if (isUnionType!(FieldTypes[0]) || __VERSION__ < 2072) {
			void[Largest!FieldTypes.sizeof] m_data;
		} else {
			union Dummy {
				FieldTypes[0] initField;
				void[Largest!FieldTypes.sizeof] data;
				alias data this;
			}
			Dummy m_data = { initField: FieldTypes[0].init };
		}
		Kind m_kind;
	}

	this(TaggedUnion other)
	{
		rawSwap(this, other);
	}

	void opAssign(TaggedUnion other)
	{
		rawSwap(this, other);
	}

	// disable default construction if first type is not a null/Void type
	static if (!isUnionType!(FieldTypes[0]) && __VERSION__ < 2072) {
		@disable this();
	}

	// postblit constructor
	static if (!allSatisfy!(isCopyable, FieldTypes)) {
		@disable this(this);
	} else static if (anySatisfy!(hasElaborateCopyConstructor, FieldTypes)) {
		this(this)
		{
			switch (m_kind) {
				default: break;
				foreach (i, tname; fieldNames) {
					alias T = FieldTypes[i];
					static if (hasElaborateCopyConstructor!T)
					{
						case __traits(getMember, Kind, tname):
							typeid(T).postblit(cast(void*)&trustedGet!T());
							return;
					}
				}
			}
		}
	}

	// destructor
	static if (anySatisfy!(hasElaborateDestructor, FieldTypes)) {
		~this()
		{
			final switch (m_kind) {
				foreach (i, tname; fieldNames) {
					alias T = FieldTypes[i];
					case __traits(getMember, Kind, tname):
						static if (hasElaborateDestructor!T) {
							.destroy(trustedGet!T);
						}
						return;
				}
			}
		}
	}

	/// Enables conversion or extraction of the stored value.
	T opCast(T)()
	{
		import std.conv : to;

		final switch (m_kind) {
			foreach (i, FT; FieldTypes) {
				case __traits(getMember, Kind, fieldNames[i]):
					static if (is(typeof(trustedGet!FT) : T))
						return trustedGet!FT;
					else static if (is(typeof(to!T(trustedGet!FT)))) {
						return to!T(trustedGet!FT);
					} else {
						assert(false, "Cannot cast a " ~ fieldNames[i]
								~ " value of type " ~ FT.stringof ~ " to " ~ T.stringof);
					}
			}
		}
		assert(false); // never reached
	}
	/// ditto
	T opCast(T)() const
	{
		// this method needs to be duplicated because inout doesn't work with to!()
		import std.conv : to;

		final switch (m_kind) {
			foreach (i, FT; FieldTypes) {
				case __traits(getMember, Kind, fieldNames[i]):
					static if (is(typeof(trustedGet!FT) : T))
						return trustedGet!FT;
					else static if (is(typeof(to!T(trustedGet!FT)))) {
						return to!T(trustedGet!FT);
					} else {
						assert(false, "Cannot cast a " ~ fieldNames[i]
								~ " value of type" ~ FT.stringof ~ " to " ~ T.stringof);
					}
			}
		}
		assert(false); // never reached
	}

	/// Enables equality comparison with the stored value.
	bool opEquals()(auto ref inout(TaggedUnion) other)
	inout {
		if (this.kind != other.kind) return false;

		final switch (this.kind) {
			foreach (i, fname; TaggedUnion!U.fieldNames)
				case __traits(getMember, Kind, fname):
					return trustedGet!(FieldTypes[i]) == other.trustedGet!(FieldTypes[i]);
		}
		assert(false); // never reached
	}

	/// The type ID of the currently stored value.
	@property Kind kind() const { return m_kind; }

	static foreach (i, name; fieldNames) {
		// NOTE: using getX/setX here because using just x would be prone to
		//       misuse (attempting to "get" a value for modification when
		//       a different kind is set instead of assigning a new value)
		mixin("alias set"~pascalCase(name)~" = set!(Kind."~name~");");
		mixin("@property bool is"~pascalCase(name)~"() const { return m_kind == Kind."~name~"; }");

		static if (!isUnionType!(FieldTypes[i])) {
			mixin("alias get"~pascalCase(name)~" = get!(Kind."~name~");");

			mixin("static TaggedUnion "~name~"(FieldTypes["~i.stringof~"] value)"
				~ "{ TaggedUnion tu; tu.set!(Kind."~name~")(move(value)); return tu; }");

			// TODO: define assignment operator for unique types
		} else {
			mixin("static @property TaggedUnion "~name~"() { TaggedUnion tu; tu.set!(Kind."~name~"); return tu; }");
		}

	}

	ref inout(FieldTypes[kind]) get(Kind kind)()
	inout {
		if (this.kind != kind) {
			enum msg(.string k_is) = "Attempt to get kind "~kind.stringof~" from tagged union with kind "~k_is;
			final switch (this.kind) {
				static foreach (i, n; fieldNames)
					case __traits(getMember, Kind, n):
						assert(false, msg!n);
			}
		}
		//return trustedGet!(FieldTypes[kind]);
		return *() @trusted { return cast(const(FieldTypes[kind])*)m_data.ptr; } ();
	}


	ref inout(T) get(T)() inout
		if (staticIndexOf!(T, FieldTypes) >= 0)
	{
		final switch (this.kind) {
			static foreach (n; fieldNames) {
				case __traits(getMember, Kind, n):
					static if (is(FieldTypes[__traits(getMember, Kind, n)] == T))
						return trustedGet!T;
					else assert(false, "Attempting to get type "~T.stringof
						~ " from a TaggedUnion with type "
						~ FieldTypes[__traits(getMember, Kind, n)].stringof);
			}
		}
	}

	ref FieldTypes[kind] set(Kind kind)(FieldTypes[kind] value)
		if (!isUnionType!(FieldTypes[kind]))
	{
		if (m_kind != kind) {
			destroy(this);
			m_data.rawEmplace(value);
		} else {
			rawSwap(trustedGet!(FieldTypes[kind]), value);
		}
		m_kind = kind;

		return trustedGet!(FieldTypes[kind]);
	}

	void set(Kind kind)()
		if (isUnionType!(FieldTypes[kind]))
	{
		if (m_kind != kind) {
			destroy(this);
		}
		m_kind = kind;
	}

	package @trusted @property ref inout(T) trustedGet(T)() inout { return *cast(inout(T)*)m_data.ptr; }
}

///
@safe nothrow unittest {
	union Kinds {
		int count;
		string text;
	}
	alias TU = TaggedUnion!Kinds;

	// default initialized to the first field defined
	TU tu;
	assert(tu.kind == TU.Kind.count);
	assert(tu.isCount); // qequivalent to the line above
	assert(!tu.isText);
	assert(tu.get!(TU.Kind.count) == int.init);

	// set to a specific count
	tu.setCount(42);
	assert(tu.isCount);
	assert(tu.getCount() == 42);
	assert(tu.get!(TU.Kind.count) == 42);
	assert(tu.get!int == 42); // can also get by type
	assert(tu.getCount() == 42);

	// assign a new tagged algebraic value
	tu = TU.count(43);

	// test equivalence with other tagged unions
	assert(tu == TU.count(43));
	assert(tu != TU.count(42));
	assert(tu != TU.text("hello"));

	// modify by reference
	tu.getCount()++;
	assert(tu.getCount() == 44);

	// set the second field
	tu.setText("hello");
	assert(!tu.isCount);
	assert(tu.isText);
	assert(tu.kind == TU.Kind.text);
	assert(tu.getText() == "hello");
}

///
@safe nothrow unittest {
	// Enum annotations supported since DMD 2.082.0. The mixin below is
	// necessary to keep the parser happy on older versions.
	static if (__VERSION__ >= 2082) {
		alias myint = int;
		// tagged unions can be defined in terms of an annotated enum
		mixin(q{enum E {
			none,
			@string text
		}});

		alias TU = TaggedUnion!E;
		static assert(is(TU.Kind == E));

		TU tu;
		assert(tu.isNone);
		assert(tu.kind == E.none);

		tu.setText("foo");
		assert(tu.kind == E.text);
		assert(tu.getText == "foo");
	}
}

unittest { // test for name clashes
	union U { .string string; }
	alias TU = TaggedUnion!U;
	TU tu;
	tu = TU.string("foo");
	assert(tu.isString);
	assert(tu.getString() == "foo");
}


/** Dispatches the value contained on a `TaggedUnion` to a set of visitors.

	A visitor can have one of three forms:

	$(UL
		$(LI function or delegate taking a single typed parameter)
		$(LI function or delegate taking no parameters)
		$(LI function or delegate template taking any single parameter)
	)

	....
*/
template visit(VISITORS...) {
	auto visit(TU)(auto ref TU tu)
		if (isInstanceOf!(TaggedUnion, TU))
	{
		final switch (tu.kind) {
			static foreach (k; EnumMembers!(TU.Kind)) {
				case k: {
					static if (isUnionType!(TU.FieldTypes[k]))
						alias T = void;
					else alias T = TU.FieldTypes[k];
					alias h = selectHandler!(T, VISITORS);
					static if (is(h == void)) static assert(false, "No handler is able to take type "~T.stringof);
					else static if (is(typeof(h) == string)) static assert(false, h);
					else static if (is(T == void)) return h();
					else return h(tu.get!k);
				}
			}
		}
	}
}

///
unittest {
	union U {
		int number;
		string text;
	}
	alias TU = TaggedUnion!U;

	auto tu = TU.number(42);
	tu.visit!(
		(int n) { assert(n == 42); },
		(string s) { assert(false); }
	);

	assert(tu.visit!((v) => to!int(v)) == 42);

	tu.setText("43");

	assert(tu.visit!((v) => to!int(v)) == 43);
}

// workaround for "template to is not defined" error in the unit test above
// happens on DMD 2.080 and below
private U to(U, T)(T val) {
	static import std.conv;
	return std.conv.to!U(val);
}


/** The same as `visit`, except that failure to handle types is checked at runtime.

	Instead of failing to compile, `tryVisit` will throw an `Exception` if none
	of the handlers is able to handle the value contained in `tu`.
*/
template tryVisit(VISITORS...) {
	auto tryVisit(TU)(auto ref TU tu)
		if (isInstanceOf!(TaggedUnion, TU))
	{
		final switch (tu.kind) {
			static foreach (k; EnumMembers!(TU.Kind)) {
				case k: {
					static if (isUnionType!(TU.FieldTypes[k]))
						alias T = void;
					else alias T = TU.FieldTypes[k];
					alias h = selectHandler!(T, VISITORS);
					static if (is(h == void)) throw new Exception("Type "~T.stringof~" not handled by any visitor.");
					else static if (is(typeof(h) == string)) static assert(false, h);
					else static if (is(T == void)) return h();
					else return h(tu.get!k);
				}
			}
		}
	}
}

///
unittest {
	import std.exception : assertThrown;

	union U {
		int number;
		string text;
	}
	alias TU = TaggedUnion!U;

	auto tu = TU.number(42);
	tu.tryVisit!((int n) { assert(n == 42); });
	assertThrown(tu.tryVisit!((string s) { assert(false); }));
}

enum isUnionType(T) = is(T == Void) || is(T == void) || is(T == typeof(null));

private template selectHandler(T, VISITORS...)
{
	import std.traits : ParameterTypeTuple, isSomeFunction;

	// TODO: error out for ambiguous handlers and handlers that don't match any type!

	template impl(int i) {
		static if (i < VISITORS.length) {
			alias fun = VISITORS[i];
			static if (isSomeFunction!fun) {
				alias Params = ParameterTypeTuple!fun;
				static if (Params.length == 0) {
					static if (is(T == void))
						alias impl = fun;
					else alias impl = impl!(i+1);
				} else static if (Params.length == 1) {
					static if (is(T : Params[0]))
						alias impl = fun;
					else alias impl = impl!(i+1);
				} else enum impl = "Visitor at index "~i.stringof~" must not take more than one parameter.";
			} else static if (isSomeFunction!(fun!T)) {
				static if (ParameterTypeTuple!(fun!T).length == 1)
					alias impl = fun!T;
				else enum impl = "Generic visitor at index "~i.stringof~" must have a single parameter.";
			} else enum impl = "Visitor at index "~i.stringof~" (or its template instantiation with type "~T.stringof~") must be a valid function or delegate.";
		} else alias impl = void;
	}
	alias selectHandler = impl!0;
}

private string pascalCase(string camel_case)
{
	if (!__ctfe) assert(false);
	import std.ascii : toUpper;
	return camel_case[0].toUpper ~ camel_case[1 .. $];
}

static if (__VERSION__ >= 2072) {
	/** Maps a kind enumeration value to the corresponding field type.

		`kind` must be a value of the `TaggedAlgebraic!T.Kind` enumeration.
	*/
	template TypeOf(alias kind)
		if (is(typeof(kind) == enum))
	{
		static if (isInstanceOf!(UnionFieldEnum, typeof(kind))) {
			import std.traits : FieldTypeTuple, TemplateArgsOf;
			alias U = TemplateArgsOf!(typeof(kind));
			alias TypeOf = FieldTypeTuple!U[kind];
		} else {
			alias Types = UnionKindTypes!(typeof(kind));
			alias uda = AliasSeq!(__traits(getAttributes, kind));
			static if (uda.length == 0) alias TypeOf = void;
			else alias TypeOf = uda[0];
		}
	}

	///
	unittest {
		static struct S {
			int a;
			string b;
			string c;
		}
		alias TU = TaggedUnion!S;

		static assert(is(TypeOf!(TU.Kind.a) == int));
		static assert(is(TypeOf!(TU.Kind.b) == string));
		static assert(is(TypeOf!(TU.Kind.c) == string));
	}
}


/// Convenience type that can be used for union fields that have no value (`void` is not allowed).
struct Void {}

private template UnionFieldEnum(U)
{
	static if (is(U == enum)) alias UnionFieldEnum = U;
	else {
		import std.array : join;
		import std.traits : FieldNameTuple;
		mixin("enum UnionFieldEnum { " ~ [FieldNameTuple!U].join(", ") ~ " }");
	}
}

deprecated alias TypeEnum(U) = UnionFieldEnum!U;

private alias UnionKindTypes(FieldEnum) = staticMap!(TypeOf, EnumMembers!FieldEnum);
private alias UnionKindNames(FieldEnum) = AliasSeq!(__traits(allMembers, FieldEnum));



package void rawEmplace(T)(void[] dst, ref T src)
{
	T[] tdst = () @trusted { return cast(T[])dst[0 .. T.sizeof]; } ();
	static if (is(T == class)) {
		tdst[0] = src;
	} else {
		import std.conv : emplace;
		emplace!T(&tdst[0]);
		tdst[0] = src;
	}
}

// std.algorithm.mutation.swap sometimes fails to compile due to
// internal errors in hasElaborateAssign!T/isAssignable!T. This is probably
// caused by cyclic dependencies. However, there is no reason to do these
// checks in this context, so we just directly move the raw memory.
package void rawSwap(T)(ref T a, ref T b)
@trusted {
	void[T.sizeof] tmp = void;
	void[] ab = (cast(void*)&a)[0 .. T.sizeof];
	void[] bb = (cast(void*)&b)[0 .. T.sizeof];
	tmp[] = ab[];
	ab[] = bb[];
	bb[] = tmp[];
}
