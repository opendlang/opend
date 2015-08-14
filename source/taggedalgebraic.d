/**
 * Algebraic data type implementation based on a tagged union.
 * 
 * Copyright: Copyright 2015, Sönke Ludwig.
 * License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Sönke Ludwig
*/
module taggedalgebraic;

import std.typetuple;

// TODO:
//  - distinguish between @property and non@-property methods.
//  - verify that static methods are handled properly

/** Implements a generic algebraic type using an enum to identify the stored type.

	This struct takes a `union` or `struct` declaration as an input and builds
	an algebraic data type from its fields, using an automatically generated
	`Type` enumeration to identify which field of the union is currently used.
	Multiple fields with the same value are supported.

	All operators and methods are transparently forwarded to the contained
	value. The caller has to make sure that the contained value supports the
	requested operation. Failure to do so will result in an assertion failure.

	The return value of forwarded operations is determined as follows:
	$(UL
		$(LI If the type can be uniquely determined, it is used as the return
			value)
		$(LI If there are multiple possible return values and all of them match
			the unique types defined in the `TaggedAlgebraic`, a
			`TaggedAlgebraic` is returned.)
		$(LI If there are multiple return values and none of them is a
			`Variant`, an `Algebraic` of the set of possible return types is
			returned.)
		$(LI If any of the possible operations returns a `Variant`, this is used
			as the return value.)
	)
*/
struct TaggedAlgebraic(U) if (is(U == union) || is(U == struct))
{
	import std.algorithm : among;
	import std.string : format;
	import std.traits : CopyTypeQualifiers, FieldTypeTuple, FieldNameTuple, Largest, hasElaborateCopyConstructor, hasElaborateDestructor;

	private alias FieldTypes = FieldTypeTuple!U;
	private alias fieldNames = FieldNameTuple!U;

	static assert(FieldTypes.length > 0, "The TaggedAlgebraic's union type must have at least one field.");
	static assert(FieldTypes.length == fieldNames.length);


	private {
		void[Largest!FieldTypes.sizeof] m_data;
		Type m_type;
	}

	/// A type enum that identifies the type of value currently stored.
	alias Type = TypeEnum!U;

	/// The type ID of the currently stored value.
	@property Type typeID() const { return m_type; }

	// constructors
	//pragma(msg, generateConstructors!U());
	mixin(generateConstructors!U);

	void opAssign(TaggedAlgebraic other)
	{
		import std.algorithm : swap;
		swap(this, other);
	}

	// postblit constructor
	static if (anySatisfy!(hasElaborateCopyConstructor, FieldTypes))
	{
		this(this)
		{
			switch (m_type) {
				default: break;
				foreach (i, tname; fieldNames) {
					alias T = typeof(__traits(getMember, U, tname));
					static if (hasElaborateCopyConstructor!T)
					{
						case __traits(getMember, Type, tname):
							typeid(T).postblit(cast(void*)&trustedGet!tname());
							return;
					}
				}
			}
		}
	}

	// destructor
	static if (anySatisfy!(hasElaborateDestructor, FieldTypes))
	{
		~this()
		{
			switch (m_type) {
				default: break;
				foreach (i, tname; fieldNames) {
					alias T = typeof(__traits(getMember, U, tname));
					static if (hasElaborateDestructor!T)
					{
						case __traits(getMember, Type, tname):
							.destroy(trustedGet!tname);
							return;
					}
				}
			}
		}
	}

	/// Enables conversion or extraction of the stored value.
	T opCast(T)() inout
	{
		import std.conv : to;

		switch (m_type) {
			default: assert(false, "Cannot cast a "~(cast(Type)m_type).to!string~" value to "~T.stringof);
			foreach (i, FT; FieldTypes) {
				static if (is(typeof(cast(T)trustedGet!(fieldNames[i])) == T)) {
					case __traits(getMember, Type, fieldNames[i]):
						return cast(T)trustedGet!(fieldNames[i]);
				}
			}
		}
		assert(false); // never reached
	}

	// NOTE: "this TA" is used here as the functional equivalent of inout,
	//       just that it generates one template instantiation per modifier
	//       combination, so that we can actually decide what to do for each
	//       case.

	/// Enables the invocation of methods of the stored value.
	auto opDispatch(string name, this TA, ARGS...)(auto ref ARGS args) if (hasOp!(TA, OpKind.method, name, ARGS)) { return implementOp!(OpKind.method, name)(this, args); }
	/// Enables equality comparison with the stored value.
	auto opEquals(T, this TA)(auto ref T other) if (hasOp!(TA, OpKind.binary, "==", T)) { return implementOp!(OpKind.binary, "==")(this, other); }
	/// Enables relational comparisons with the stored value.
	auto opCmp(T, this TA)(auto ref T other) if (hasOp!(TA, OpKind.binary, "<", T)) { assert(false, "TODO!"); }
	/// Enables the use of unary operators with the stored value.
	auto opUnary(string op, this TA)() if (hasOp!(TA, OpKind.unary, op)) { return implementOp!(OpKind.unary, op)(this); }
	/// Enables the use of binary operators with the stored value.
	auto opBinary(string op, T, this TA)(auto ref T other) inout if (hasOp!(TA, OpKind.binary, op, T)) { return implementOp!(OpKind.binary, op)(this, other); }
	/// Enables operator assignments on the stored value.
	auto opOpAssign(string op, T, this TA)(auto ref T other) if (hasOp!(TA, OpKind.binary, op~"=", T)) { return implementOp!(OpKind.binary, op~"=")(this, other); }
	/// Enables indexing operations on the stored value.
	auto opIndex(this TA, ARGS...)(auto ref ARGS args) if (hasOp!(TA, OpKind.index, null, ARGS)) { return implementOp!(OpKind.index, null)(this, args); }
	/// Enables index assignments on the stored value.
	auto opIndexAssign(this TA, ARGS...)(auto ref ARGS args) if (hasOp!(TA, OpKind.indexAssign, null, ARGS)) { return implementOp!(OpKind.indexAssign, null)(this, args); }
	/// Enables call syntax operations on the stored value.
	auto opCall(this TA, ARGS...)(auto ref ARGS args) if (hasOp!(TA, OpKind.call, null, ARGS)) { return implementOp!(OpKind.call, null)(this, args); }

	private template hasOp(TA, OpKind kind, string name, ARGS...)
	{
		alias UQ = CopyTypeQualifiers!(TA, U);
		enum hasOp = .hasOp!(UQ, kind, name, ARGS);
	}

	private static auto implementOp(OpKind kind, string name, T, ARGS...)(ref T self, auto ref ARGS args)
	{
		import std.array : join;
		import std.variant : Algebraic, Variant;
		alias UQ = CopyTypeQualifiers!(T, U);

		alias info = OpInfo!(UQ, kind, name, ARGS);

		switch (self.m_type) {
			default: assert(false, "Operator "~name~" ("~kind.stringof~") can only be used on values of the following types: "~[info.fields].join(", "));
			foreach (i, f; info.fields) {
				alias FT = FieldTypes[i];
				case __traits(getMember, Type, f):
					static if (NoDuplicates!(info.ReturnTypes).length == 1)
						return info.perform(self.trustedGet!f, args);
					else static if (allSatisfy!(isMatchingUniqueType!U, info.ReturnTypes))
						return TaggedAlgebraic(info.perform(self.trustedGet!f, args));
					else static if (allSatisfy!(isNoVariant, info.ReturnTypes))
						return Algebraic!(NoDuplicates!(info.ReturnTypes))(info.perform(self.trustedGet!f, args));
					else static if (is(FT == Variant))
						return info.perform(self.trustedGet!f, args);
					else
						return Variant(info.perform(self.trustedGet!f, args));
			}
		}

		assert(false); // never reached
	}

	private @trusted @property ref inout(typeof(__traits(getMember, U, f))) trustedGet(string f)() inout { return trustedGet!(inout(typeof(__traits(getMember, U, f)))); }
	private @trusted @property ref inout(T) trustedGet(T)() inout { return *cast(inout(T)*)m_data.ptr; }
}

bool hasType(T, U)(in ref TaggedAlgebraic!U ta)
{
	switch (ta.typeID) {
		default: return false;
		foreach (i, FT; ta.FieldTypes)
			static if (is(FT == T)) {
				case __traits(getMember, ta.Type, ta.fieldNames[i]):
					return true;
			}
	}
	assert(false); // never reached
}

ref inout(T) get(T, U)(ref inout(TaggedAlgebraic!U) ta)
{
	assert(hasType!(T, U)(ta));
	return ta.trustedGet!T;
}


/** Operators and methods of the contained type can be used transparently.
*/
@safe unittest {
	static struct S {
		int v;
		int test() { return v / 2; }
	}

	static union Test {
		typeof(null) null_;
		int integer;
		string text;
		string[string] dictionary;
		S custom;
	}

	alias TA = TaggedAlgebraic!Test;

	TA ta;
	assert(ta.typeID == TA.Type.null_);

	ta = 12;
	assert(ta.typeID == TA.Type.integer);
	assert(ta == 12);
	assert(cast(int)ta == 12);
	assert(cast(short)ta == 12);

	ta += 12;
	assert(ta == 24);
	assert(ta - 10 == 14);

	ta = ["foo" : "bar"];
	assert(ta.typeID == TA.Type.dictionary);
	assert(ta["foo"] == "bar");

	ta["foo"] = "baz";
	assert(ta["foo"] == "baz");

	ta = S(8);
	assert(ta.test() == 4);
}

/** Multiple fields are allowed to have the same type, in which case the type
	ID enum is used to disambiguate.
*/
@safe unittest {
	static union Test {
		typeof(null) null_;
		int count;
		int difference;
	}

	alias TA = TaggedAlgebraic!Test;

	TA ta;
	ta = TA(12, TA.Type.count);
	assert(ta.typeID == TA.Type.count);
	assert(ta == 12);

	ta = null;
	assert(ta.typeID == TA.Type.null_);
}

unittest {
	// test proper type modifier support
	static struct  S {
		void test() {}
		void testI() immutable {}
		void testC() const {}
		void testS() shared {}
		void testSC() shared const {}
	}
	static union U {
		S s;
	}
	
	auto u = TaggedAlgebraic!U(S.init);
	const uc = u;
	immutable ui = cast(immutable)u;
	//const shared usc = cast(shared)u;
	//shared us = cast(shared)u;

	static assert( is(typeof(u.test())));
	static assert(!is(typeof(u.testI())));
	static assert( is(typeof(u.testC())));
	static assert(!is(typeof(u.testS())));
	static assert(!is(typeof(u.testSC())));

	static assert(!is(typeof(uc.test())));
	static assert(!is(typeof(uc.testI())));
	static assert( is(typeof(uc.testC())));
	static assert(!is(typeof(uc.testS())));
	static assert(!is(typeof(uc.testSC())));

	static assert(!is(typeof(ui.test())));
	static assert( is(typeof(ui.testI())));
	static assert( is(typeof(ui.testC())));
	static assert(!is(typeof(ui.testS())));
	static assert( is(typeof(ui.testSC())));

	/*static assert(!is(typeof(us.test())));
	static assert(!is(typeof(us.testI())));
	static assert(!is(typeof(us.testC())));
	static assert( is(typeof(us.testS())));
	static assert( is(typeof(us.testSC())));

	static assert(!is(typeof(usc.test())));
	static assert(!is(typeof(usc.testI())));
	static assert(!is(typeof(usc.testC())));
	static assert(!is(typeof(usc.testS())));
	static assert( is(typeof(usc.testSC())));*/
}

unittest {
	// test attributes on contained values
	import std.typecons : Rebindable, rebindable;

	class C {
		void test() {}
		void testC() const {}
		void testI() immutable {}
	}
	union U {
		Rebindable!(immutable(C)) c;
	}

	auto ta = TaggedAlgebraic!U(rebindable(new immutable C));
	static assert(!is(typeof(ta.test())));
	static assert( is(typeof(ta.testC())));
	static assert( is(typeof(ta.testI())));
}

version (unittest) {
	// test recursive definition using a wrapper dummy struct
	// (needed to avoid "no size yet for forward reference" errors)
	template ID(What) { alias ID = What; }
	private struct _test_Wrapper {
		TaggedAlgebraic!_test_U u;
		alias u this;
		this(ARGS...)(ARGS args) { u = TaggedAlgebraic!_test_U(args); }
	}
	private union _test_U {
		_test_Wrapper[] children;
		int value;
	}
	unittest {
		alias TA = _test_Wrapper;
		auto ta = TA(null);
		ta ~= TA(0);
		ta ~= TA(1);
		ta ~= TA([TA(2)]);
		assert(ta[0] == 0);
		assert(ta[1] == 1);
		assert(ta[2][0] == 2);
	}
}

unittest { // postblit/destructor test
	static struct S {
		static int i = 0;
		bool initialized = false;
		this(bool) { initialized = true; i++; }
		this(this) { if (initialized) i++; }
		~this() { if (initialized) i--; }
	}

	static struct U {
		S s;
		int t;
	}
	alias TA = TaggedAlgebraic!U;
	{
		assert(S.i == 0);
		auto ta = TA(S(true));
		assert(S.i == 1);
		{
			auto tb = ta;
			assert(S.i == 2);
			ta = tb;
			assert(S.i == 2);
			ta = 1;
			assert(S.i == 1);
			ta = S(true);
			assert(S.i == 2);
		}
		assert(S.i == 1);
	}
	assert(S.i == 0);

	static struct U2 {
		S a;
		S b;
	}
	alias TA2 = TaggedAlgebraic!U2;
	{
		auto ta2 = TA2(S(true), TA2.Type.a);
		assert(S.i == 1);
	}
	assert(S.i == 0);
}

unittest {
	static struct S {
		union U {
			int i;
			string s;
			U[] a;
		}
		alias TA = TaggedAlgebraic!U;
		TA p;
		alias p this;
	}
	S s = S(S.TA("hello"));
	assert(cast(string)s == "hello");
}

unittest { // multiple operator choices
	union U {
		int i;
		double d;
	}
	alias TA = TaggedAlgebraic!U;
	TA ta = 12;
	static assert(is(typeof(ta + 10) == TA)); // ambiguous, could be int or double
	assert((ta + 10).typeID == TA.Type.i);
	assert(ta + 10 == 22);
	static assert(is(typeof(ta + 10.5) == double));
	assert(ta + 10.5 == 22.5);
}

unittest { // Binary op between two TaggedAlgebraic values
	union U { int i; }
	alias TA = TaggedAlgebraic!U;

	TA a = 1, b = 2;
	static assert(is(typeof(a + b) == int));
	assert(a + b == 3);
}

unittest { // Ambiguous binary op between two TaggedAlgebraic values
	union U { int i; double d; }
	alias TA = TaggedAlgebraic!U;

	TA a = 1, b = 2;
	static assert(is(typeof(a + b) == TA));
	assert(a + b == 3);
}

/// Convenience type that can be used for union fields that have no value (`void` is not allowed).
struct Void {}

private enum hasOp(U, OpKind kind, string name, ARGS...) = TypeTuple!(OpInfo!(U, kind, name, ARGS).fields).length > 0;

unittest {
	static struct S {
		void m(int i) {}
		bool opEquals(int i) { return true; }
		bool opEquals(S s) { return true; }
	}

	static union U { int i; string s; S st; }

	static assert(hasOp!(U, OpKind.binary, "+", int));
	static assert(hasOp!(U, OpKind.binary, "~", string));
	static assert(hasOp!(U, OpKind.binary, "==", int));
	static assert(hasOp!(U, OpKind.binary, "==", string));
	static assert(hasOp!(U, OpKind.binary, "==", int));
	static assert(hasOp!(U, OpKind.binary, "==", S));
	static assert(hasOp!(U, OpKind.method, "m", int));
	static assert(hasOp!(U, OpKind.binary, "+=", int));
	static assert(!hasOp!(U, OpKind.binary, "~", int));
	static assert(!hasOp!(U, OpKind.binary, "~", int));
	static assert(!hasOp!(U, OpKind.method, "m", string));
	static assert(!hasOp!(U, OpKind.method, "m"));
	static assert(!hasOp!(const(U), OpKind.binary, "+=", int));
	static assert(!hasOp!(const(U), OpKind.method, "m", int));
}


private auto performOpRaw(U, OpKind kind, string name, T, ARGS...)(ref T value, /*auto ref*/ ARGS args)
{
	static if (kind == OpKind.binary) return mixin("value "~name~" args[0]");
	else static if (kind == OpKind.unary) return mixin("name "~value);
	else static if (kind == OpKind.method) return __traits(getMember, value, name)(args);
	else static if (kind == OpKind.index) return value[args];
	else static if (kind == OpKind.indexAssign) return value[args[1 .. $]] = args[0];
	else static if (kind == OpKind.call) return value(args);
	else static assert(false, "Unsupported kind of operator: "~kind.stringof);
}

unittest {
	union U { int i; string s; }

	{ int v = 1; assert(performOpRaw!(U, OpKind.binary, "+")(v, 3) == 4); }
	{ string v = "foo"; assert(performOpRaw!(U, OpKind.binary, "~")(v, "bar") == "foobar"); }
}


private auto performOp(U, OpKind kind, string name, T, ARGS...)(ref T value, /*auto ref*/ ARGS args)
{
	import std.traits : isInstanceOf;
	static if (ARGS.length > 0 && isInstanceOf!(TaggedAlgebraic, ARGS[0])) {
		static if (is(typeof(performOpRaw!(U, kind, name, T, ARGS)(value, args)))) {
			return performOpRaw!(U, kind, name, T, ARGS)(value, args);
		} else {
			alias TA = ARGS[0];
			template MTypesImpl(size_t i) {
				static if (i < TA.FieldTypes.length) {
					alias FT = TA.FieldTypes[i];
					static if (is(typeof(&performOpRaw!(U, kind, name, T, FT, ARGS[1 .. $]))))
						alias MTypesImpl = TypeTuple!(FT, MTypesImpl!(i+1));
					else alias MTypesImpl = TypeTuple!(MTypesImpl!(i+1));
				} else alias MTypesImpl = TypeTuple!();
			}
			alias MTypes = NoDuplicates!(MTypesImpl!0);
			static assert(MTypes.length > 0, "No type of the TaggedAlgebraic parameter matches any function declaration.");
			static if (MTypes.length == 1) {
				if (args[0].hasType!(MTypes[0]))
					return performOpRaw!(U, kind, name)(value, args[0].get!(MTypes[0]), args[1 .. $]);
			} else {
				// TODO: allow all return types (fall back to Algebraic or Variant)
				foreach (FT; MTypes) {
					if (args[0].hasType!FT)
						return ARGS[0](performOpRaw!(U, kind, name)(value, args[0].get!FT, args[1 .. $]));
				}
			}
			throw new /*InvalidAgument*/Exception("Algebraic parameter type mismatch");
		}
	} else return performOpRaw!(U, kind, name, T, ARGS)(value, args);
}

unittest {
	union U { int i; double d; string s; }

	{ int v = 1; assert(performOp!(U, OpKind.binary, "+")(v, 3) == 4); }
	{ string v = "foo"; assert(performOp!(U, OpKind.binary, "~")(v, "bar") == "foobar"); }
	{ string v = "foo"; assert(performOp!(U, OpKind.binary, "~")(v, TaggedAlgebraic!U("bar")) == "foobar"); }
	{ int v = 1; assert(performOp!(U, OpKind.binary, "+")(v, TaggedAlgebraic!U(3)) == 4); }
}


private template OpInfo(U, OpKind kind, string name, ARGS...)
{
	import std.traits : FieldTypeTuple, FieldNameTuple, ReturnType;

	alias FieldTypes = FieldTypeTuple!U;
	alias fieldNames = FieldNameTuple!U;

	template fieldsImpl(size_t i)
	{
		static if (i < FieldTypes.length) {
			static if (is(typeof(&performOp!(U, kind, name, FieldTypes[i], ARGS)))) {
				alias fieldsImpl = TypeTuple!(fieldNames[i], fieldsImpl!(i+1));
			} else alias fieldsImpl = fieldsImpl!(i+1);
		} else alias fieldsImpl = TypeTuple!();
	}
	alias fields = fieldsImpl!0;

	template ReturnTypesImpl(size_t i) {
		static if (i < FieldTypes.length) {
			static if (is(typeof(&performOp!(U, kind, name, FieldTypes[i], ARGS)))) {
				alias T = ReturnType!(performOp!(U, kind, name, FieldTypes[i], ARGS));
				alias ReturnTypesImpl = TypeTuple!(T, ReturnTypesImpl!(i+1));
			} else alias ReturnTypesImpl = ReturnTypesImpl!(i+1);
		} else alias ReturnTypesImpl = TypeTuple!();
	}
	alias ReturnTypes = ReturnTypesImpl!0;

	static auto perform(T)(ref T value, auto ref ARGS args) { return performOp!(U, kind, name)(value, args); }
}

private enum OpKind {
	binary,
	unary,
	method,
	index,
	indexAssign,
	call
}

private template TypeEnum(U)
{
	import std.array : join;
	import std.traits : FieldNameTuple;
	mixin("enum TypeEnum { " ~ [FieldNameTuple!U].join(", ") ~ " }");
}

private string generateConstructors(U)()
{
	import std.algorithm : map;
	import std.array : join;
	import std.string : format;
	import std.traits : FieldTypeTuple;

	string ret;

	// disable default construction if first type is not a null/Void type
	static if (!is(FieldTypeTuple!U[0] == typeof(null)) && !is(FieldTypeTuple!U[0] == Void))
	{
		ret ~= q{
			@disable this();
		};
	}

	// normal type constructors
	foreach (tname; UniqueTypeFields!U)
		ret ~= q{
			this(typeof(U.%s) value)
			{
				m_data.rawEmplace(value);
				m_type = Type.%s;
			}

			void opAssign(typeof(U.%s) value)
			{
				if (m_type != Type.%s) {
					// NOTE: destroy(this) doesn't work for some opDispatch-related reason
					static if (is(typeof(&this.__xdtor)))
						this.__xdtor();
					m_data.rawEmplace(value);
				} else {
					trustedGet!"%s" = value;
				}
				m_type = Type.%s;
			}
		}.format(tname, tname, tname, tname, tname, tname);

	// type constructors with explicit type tag
	foreach (tname; AmbiguousTypeFields!U)
		ret ~= q{
			this(typeof(U.%s) value, Type type)
			{
				assert(type.among!(%s), format("Invalid type ID for type %%s: %%s", typeof(U.%s).stringof, type));
				m_data.rawEmplace(value);
				m_type = type;
			}
		}.format(tname, [SameTypeFields!(U, tname)].map!(f => "Type."~f).join(", "), tname);

	return ret;
}

private template UniqueTypeFields(U) {
	import std.traits : FieldTypeTuple, FieldNameTuple;

	alias Types = FieldTypeTuple!U;

	template impl(size_t i) {
		static if (i < Types.length) {
			enum name = FieldNameTuple!U[i];
			alias T = Types[i];
			static if (staticIndexOf!(T, Types) == i && staticIndexOf!(T, Types[i+1 .. $]) < 0)
				alias impl = TypeTuple!(name, impl!(i+1));
			else alias impl = TypeTuple!(impl!(i+1));
		} else alias impl = TypeTuple!();
	}
	alias UniqueTypeFields = impl!0;
}

private template AmbiguousTypeFields(U) {
	import std.traits : FieldTypeTuple, FieldNameTuple;

	alias Types = FieldTypeTuple!U;

	template impl(size_t i) {
		static if (i < Types.length) {
			enum name = FieldNameTuple!U[i];
			alias T = Types[i];
			static if (staticIndexOf!(T, Types) == i && staticIndexOf!(T, Types[i+1 .. $]) >= 0)
				alias impl = TypeTuple!(name, impl!(i+1));
			else alias impl = impl!(i+1);
		} else alias impl = TypeTuple!();
	}
	alias AmbiguousTypeFields = impl!0;
}

unittest {
	union U {
		int a;
		string b;
		int c;
		double d;
	}
	static assert([UniqueTypeFields!U] == ["b", "d"]);
	static assert([AmbiguousTypeFields!U] == ["a"]);
}

private template SameTypeFields(U, string field) {
	import std.traits : FieldTypeTuple, FieldNameTuple;

	alias Types = FieldTypeTuple!U;

	alias T = typeof(__traits(getMember, U, field));
	template impl(size_t i) {
		static if (i < Types.length) {
			enum name = FieldNameTuple!U[i];
			static if (is(Types[i] == T))
				alias impl = TypeTuple!(name, impl!(i+1));
			else alias impl = TypeTuple!(impl!(i+1));
		} else alias impl = TypeTuple!();
	}
	alias SameTypeFields = impl!0;
}

private template MemberType(U) {
	template MemberType(string name) {
		alias MemberType = typeof(__traits(getMember, U, name));
	}
}

private template isMatchingType(U) {
	import std.traits : FieldTypeTuple;
	enum isMatchingType(T) = staticIndexOf!(T, FieldTypeTuple!U) >= 0;
}

private template isMatchingUniqueType(U) {
	import std.traits : FieldTypeTuple;
	template isMatchingUniqueType(T) {
		alias Types = FieldTypeTuple!U;
		enum idx = staticIndexOf!(T, Types);
		static if (idx < 0) enum isMatchingUniqueType = false;
		else static if (staticIndexOf!(T, Types[idx+1 .. $]) >= 0) enum isMatchingUniqueType = false;
		else enum isMatchingUniqueType = true;
	}
}

private template isNoVariant(T) {
	import std.variant : Variant;
	enum isNoVariant = !is(T == Variant);
}

private void rawEmplace(T)(void[] dst, ref T src)
{
	T* tdst = () @trusted { return cast(T*)dst.ptr; } ();
	static if (is(T == class)) {
		*tdst = src;
	} else {
		import std.conv : emplace;
		emplace(tdst);
		*tdst = src;
	}
}
