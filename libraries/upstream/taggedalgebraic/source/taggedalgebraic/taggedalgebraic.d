/**
 * Algebraic data type implementation based on a tagged union.
 *
 * Copyright: Copyright 2015-2019, Sönke Ludwig.
 * License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Sönke Ludwig
*/
module taggedalgebraic.taggedalgebraic;

public import taggedalgebraic.taggedunion;

import std.algorithm.mutation : move, swap;
import std.meta;
import std.traits : EnumMembers, FieldNameTuple, Unqual, isInstanceOf;

// TODO:
//  - distinguish between @property and non@-property methods.
//  - verify that static methods are handled properly


/** Converts a given `TaggedUnion` to a `TaggedAlgebraic`.

	This allows to access members or operators of a `TaggedUnion` with a concise
	syntax.
*/
auto algebraic(TU)(TU tagged_union)
	if (isInstanceOf!(TaggedUnion, TU))
{
	TaggedAlgebraic!(TU.FieldDefinitionType) ret;
	ret.m_union = tagged_union;
	return ret;
}

///
unittest {
	import taggedalgebraic.visit : visit;

	struct Button {
		string caption;
		int callbackID;
	}

	struct Label {
		string caption;
	}

	union U {
		Button button;
		Label label;
	}

	alias Control = TaggedUnion!U;

	// define a generic list of controls
	Control[] controls = [
		Control(Button("Hello", -1)),
		Control(Label("World"))
	];

	// just a dummy for the sake of the example
	void print(string message) {}

	// short syntax using `algebraic`
	foreach (c; controls)
		print(algebraic(c).caption);

	// slightly longer and noisier alternative using `visit`
	foreach (c; controls)
		print(c.visit!(ct => ct.caption));

	// low level alternative
	foreach (c; controls) {
		final switch (c.kind) {
			case Control.Kind.button:
				print(c.buttonValue.caption);
				break;
			case Control.Kind.label:
				print(c.labelValue.caption);
				break;
		}
	}
}


/** Implements a generic algebraic type using an enum to identify the stored type.

	This struct takes a `union` or `struct` declaration as an input and builds
	an algebraic data type from its fields, using an automatically generated
	`Kind` enumeration to identify which field of the union is currently used.
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
struct TaggedAlgebraic(U) if (is(U == union) || is(U == struct) || is(U == enum))
{
	import std.algorithm : among;
	import std.string : format;

	/// Alias of the type used for defining the possible storage types/kinds.
	deprecated alias Union = U;

	private alias FieldDefinitionType = U;

	/// The underlying tagged union type
	alias UnionType = TaggedUnion!U;

	private TaggedUnion!U m_union;

	/// A type enum that identifies the type of value currently stored.
	alias Kind = UnionType.Kind;

	/// Compatibility alias
	deprecated("Use 'Kind' instead.") alias Type = Kind;

	/// The type ID of the currently stored value.
	@property Kind kind() const { return m_union.kind; }

	// Compatibility alias
	deprecated("Use 'kind' instead.")
	alias typeID = kind;

	// constructors
	//pragma(msg, generateConstructors!U());
	mixin(generateConstructors!U);

	this(TaggedAlgebraic other)
	{
		rawSwap(this, other);
	}

	void opAssign(TaggedAlgebraic other)
	{
		rawSwap(this, other);
	}

	/// Enables conversion or extraction of the stored value.
	T opCast(T)() { return cast(T)m_union; }
	/// ditto
	T opCast(T)() const { return cast(T)m_union; }

	/// Uses `cast(string)`/`to!string` to return a string representation of the enclosed value.
	string toString() const { return cast(string)this; }

	// NOTE: "this TA" is used here as the functional equivalent of inout,
	//       just that it generates one template instantiation per modifier
	//       combination, so that we can actually decide what to do for each
	//       case.

	/// Enables the access to methods and propeties/fields of the stored value.
	template opDispatch(string name)
		if (hasAnyMember!(TaggedAlgebraic, name))
	{
		/// Enables the invocation of methods of the stored value.
		auto ref opDispatch(this TA, ARGS...)(auto ref ARGS args) if (hasOp!(TA, OpKind.method, name, ARGS)) { return implementOp!(OpKind.method, name)(this, args); }
		/// Enables accessing properties/fields of the stored value.
		@property auto ref opDispatch(this TA, ARGS...)(auto ref ARGS args) if (hasOp!(TA, OpKind.field, name, ARGS) && !hasOp!(TA, OpKind.method, name, ARGS)) { return implementOp!(OpKind.field, name)(this, args); }
	}

	static if (is(typeof(m_union.toHash()))) {
		size_t toHash()
		const @safe nothrow {
			return m_union.toHash();
		}
	}

	/// Enables equality comparison with the stored value.
	auto ref opEquals(T, this TA)(auto ref T other)
		if (is(Unqual!T == TaggedAlgebraic) || hasOp!(TA, OpKind.binary, "==", T))
	{
		static if (is(Unqual!T == TaggedAlgebraic)) {
			return m_union == other.m_union;
		} else return implementOp!(OpKind.binary, "==")(this, other);
	}
	/// Enables relational comparisons with the stored value.
	auto ref opCmp(T, this TA)(auto ref T other) if (hasOp!(TA, OpKind.binary, "<", T)) { assert(false, "TODO!"); }
	/// Enables the use of unary operators with the stored value.
	auto ref opUnary(string op, this TA)() if (hasOp!(TA, OpKind.unary, op)) { return implementOp!(OpKind.unary, op)(this); }
	/// Enables the use of binary operators with the stored value.
	auto ref opBinary(string op, T, this TA)(auto ref T other) if (hasOp!(TA, OpKind.binary, op, T)) { return implementOp!(OpKind.binary, op)(this, other); }
	/// Enables the use of binary operators with the stored value.
	auto ref opBinaryRight(string op, T, this TA)(auto ref T other) if (hasOp!(TA, OpKind.binaryRight, op, T) && !isInstanceOf!(TaggedAlgebraic, T)) { return implementOp!(OpKind.binaryRight, op)(this, other); }
	/// ditto
	auto ref opBinaryRight(string op, T, this TA)(auto ref T other) if (hasOp!(TA, OpKind.binaryRight, op, T) && isInstanceOf!(TaggedAlgebraic, T) && !hasOp!(T, OpKind.opBinary, op, TA)) { return implementOp!(OpKind.binaryRight, op)(this, other); }
	/// Enables operator assignments on the stored value.
	auto ref opOpAssign(string op, T, this TA)(auto ref T other) if (hasOp!(TA, OpKind.binary, op~"=", T)) { return implementOp!(OpKind.binary, op~"=")(this, other); }
	/// Enables indexing operations on the stored value.
	auto ref opIndex(this TA, ARGS...)(auto ref ARGS args) if (hasOp!(TA, OpKind.index, null, ARGS)) { return implementOp!(OpKind.index, null)(this, args); }
	/// Enables index assignments on the stored value.
	auto ref opIndexAssign(this TA, ARGS...)(auto ref ARGS args) if (hasOp!(TA, OpKind.indexAssign, null, ARGS)) { return implementOp!(OpKind.indexAssign, null)(this, args); }
	/// Enables call syntax operations on the stored value.
	auto ref opCall(this TA, ARGS...)(auto ref ARGS args) if (hasOp!(TA, OpKind.call, null, ARGS)) { return implementOp!(OpKind.call, null)(this, args); }
}

///
@safe unittest
{
	import taggedalgebraic.taggedalgebraic;

	struct Foo {
		string name;
		void bar() @safe {}
	}

	union Base {
		int i;
		string str;
		Foo foo;
	}

	alias Tagged = TaggedAlgebraic!Base;

	// Instantiate
	Tagged taggedInt = 5;
	Tagged taggedString = "Hello";
	Tagged taggedFoo = Foo();
	Tagged taggedAny = taggedInt;
	taggedAny = taggedString;
	taggedAny = taggedFoo;

	// Check type: Tagged.Kind is an enum
	assert(taggedInt.kind == Tagged.Kind.i);
	assert(taggedString.kind == Tagged.Kind.str);
	assert(taggedFoo.kind == Tagged.Kind.foo);
	assert(taggedAny.kind == Tagged.Kind.foo);

	// In most cases, can simply use as-is
	auto num = 4 + taggedInt;
	auto msg = taggedString ~ " World!";
	taggedFoo.bar();
	if (taggedAny.kind == Tagged.Kind.foo) // Make sure to check type first!
		taggedAny.bar();
	//taggedString.bar(); // AssertError: Not a Foo!

	// Convert back by casting
	auto i   = cast(int)    taggedInt;
	auto str = cast(string) taggedString;
	auto foo = cast(Foo)    taggedFoo;
	if (taggedAny.kind == Tagged.Kind.foo) // Make sure to check type first!
		auto foo2 = cast(Foo) taggedAny;
	//cast(Foo) taggedString; // AssertError!

	// Kind is an enum, so final switch is supported:
	final switch (taggedAny.kind) {
		case Tagged.Kind.i:
			// It's "int i"
			break;

		case Tagged.Kind.str:
			// It's "string str"
			break;

		case Tagged.Kind.foo:
			// It's "Foo foo"
			break;
	}
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
	assert(ta.kind == TA.Kind.null_);

	ta = 12;
	assert(ta.kind == TA.Kind.integer);
	assert(ta == 12);
	assert(cast(int)ta == 12);
	assert(cast(long)ta == 12);
	assert(cast(short)ta == 12);

	ta += 12;
	assert(ta == 24);
	assert(ta - 10 == 14);

	ta = ["foo" : "bar"];
	assert(ta.kind == TA.Kind.dictionary);
	assert(ta["foo"] == "bar");

	ta["foo"] = "baz";
	assert(ta["foo"] == "baz");

	ta = S(8);
	assert(ta.test() == 4);
}

unittest { // std.conv integration
	import std.conv : to;

	static struct S {
		int v;
		int test() { return v / 2; }
	}

	static union Test {
		typeof(null) null_;
		int number;
		string text;
	}

	alias TA = TaggedAlgebraic!Test;

	TA ta;
	assert(ta.kind == TA.Kind.null_);
	ta = "34";
	assert(ta == "34");
	assert(to!int(ta) == 34, to!string(to!int(ta)));
	assert(to!string(ta) == "34", to!string(ta));
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

	TA ta = TA(12, TA.Kind.count);
	assert(ta.kind == TA.Kind.count);
	assert(ta == 12);

	ta = null;
	assert(ta.kind == TA.Kind.null_);
}

@safe unittest { // comparison of whole TAs
	static union Test {
		typeof(null) a;
		typeof(null) b;
		Void c;
		Void d;
		int e;
		int f;
	}
	alias TA = TaggedAlgebraic!Test;

	assert(TA(null, TA.Kind.a) == TA(null, TA.Kind.a));
	assert(TA(null, TA.Kind.a) != TA(null, TA.Kind.b));
	assert(TA(null, TA.Kind.a) != TA(Void.init, TA.Kind.c));
	assert(TA(null, TA.Kind.a) != TA(0, TA.Kind.e));
	assert(TA(Void.init, TA.Kind.c) == TA(Void.init, TA.Kind.c));
	assert(TA(Void.init, TA.Kind.c) != TA(Void.init, TA.Kind.d));
	assert(TA(1, TA.Kind.e) == TA(1, TA.Kind.e));
	assert(TA(1, TA.Kind.e) != TA(2, TA.Kind.e));
	assert(TA(1, TA.Kind.e) != TA(1, TA.Kind.f));
}

unittest { // self-referential types
	struct S {
		int num;
		TaggedAlgebraic!This[] arr;
		TaggedAlgebraic!This[string] obj;
	}
	alias TA = TaggedAlgebraic!S;

	auto ta = TA([
			TA(12),
			TA(["bar": TA(13)])
		]);

	assert(ta.kind == TA.Kind.arr);
	assert(ta[0].kind == TA.Kind.num);
	assert(ta[0] == 12);
	assert(ta[1].kind == TA.Kind.obj);
	assert(ta[1]["bar"] == 13);
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

// test recursive definition using a wrapper dummy struct
// (needed to avoid "no size yet for forward reference" errors)
unittest {
	static struct TA {
		union U {
			TA[] children;
			int value;
		}
		TaggedAlgebraic!U u;
		alias u this;
		this(ARGS...)(ARGS args) { u = TaggedAlgebraic!U(args); }
	}

	auto ta = TA(null);
	ta ~= TA(0);
	ta ~= TA(1);
	ta ~= TA([TA(2)]);
	assert(ta[0] == 0);
	assert(ta[1] == 1);
	assert(ta[2][0] == 2);
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
		auto ta2 = TA2(S(true), TA2.Kind.a);
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
	assert((ta + 10).kind == TA.Kind.i);
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
	assert((a + b).kind == TA.Kind.i);
	assert(a + b == 3);
}

unittest {
	struct S {
		union U {
			@disableIndex string str;
			S[] array;
			S[string] object;
		}
		alias TA = TaggedAlgebraic!U;
		TA payload;
		alias payload this;
	}

	S a = S(S.TA("hello"));
	S b = S(S.TA(["foo": a]));
	S c = S(S.TA([a]));
	assert(b["foo"] == a);
	assert(b["foo"] == "hello");
	assert(c[0] == a);
	assert(c[0] == "hello");
}

static if (__VERSION__ >= 2072) unittest { // default initialization
	struct S {
		int i = 42;
	}

	union U { S s; int j; }

	TaggedAlgebraic!U ta;
	assert(ta.i == 42);
}

unittest
{
	union U { int[int] a; }

	foreach (TA; AliasSeq!(TaggedAlgebraic!U, const(TaggedAlgebraic!U)))
	{
		TA ta = [1 : 2];
		assert(cast(int[int])ta == [1 : 2]);
	}
}

static if (__VERSION__ >= 2072) {
	unittest { // issue #8
		static struct Result(T,E)
		{
			static union U
			{
				T ok;
				E err;
			}
			alias TA = TaggedAlgebraic!U;
			TA payload;
			alias payload this;

			this(T ok) { payload = ok; }
			this(E err) { payload = err; }
		}

		static struct Option(T)
		{
			static union U
			{
				T some;
				typeof(null) none;
			}
			alias TA = TaggedAlgebraic!U;
			TA payload;
			alias payload this;

			this(T some) { payload = some; }
			this(typeof(null) none) { payload = null; }
		}

		Result!(Option!size_t, int) foo()
		{
			return Result!(Option!size_t, int)(42);
		}

		assert(foo() == 42);
	}
}

unittest { // issue #13
	struct S1 { Void dummy; int foo; }
	struct S {
		struct T { TaggedAlgebraic!S1 foo() { return TaggedAlgebraic!S1(42); } }
		struct U { string foo() { return "foo"; } }
		Void dummy;
		T t;
		U u;
	}
	alias TA = TaggedAlgebraic!S;
	auto ta = TA(S.T.init);
	assert(ta.foo().get!(TaggedAlgebraic!S1) == 42);

	ta = TA(S.U.init);
	assert(ta.foo() == "foo");
}

unittest
{
	static union U { int[] a; }
	TaggedAlgebraic!U ta;
	ta = [1,2,3];
	assert(ta.length == 3);
	ta.length = 4;
	//assert(ta.length == 4); //FIXME
	assert(ta.opDispatch!"sizeof" == (int[]).sizeof);
}


/** Tests if the algebraic type stores a value of a certain data type.
*/
bool hasType(T, U)(const scope ref TaggedAlgebraic!U ta)
{
	alias Fields = Filter!(fieldMatchesType!(U, T), ta.m_union.fieldNames);
	static assert(Fields.length > 0, "Type "~T.stringof~" cannot be stored in a "~(TaggedAlgebraic!U).stringof~".");

	switch (ta.kind) {
		default: return false;
		foreach (i, fname; Fields)
			case __traits(getMember, ta.Kind, fname):
				return true;
	}
	assert(false); // never reached
}
/// ditto
bool hasType(T, U)(const scope TaggedAlgebraic!U ta)
{
	return hasType!(T, U)(ta);
}

///
unittest {
	union Fields {
		int number;
		string text;
	}

	TaggedAlgebraic!Fields ta = "test";

	assert(ta.hasType!string);
	assert(!ta.hasType!int);

	ta = 42;
	assert(ta.hasType!int);
	assert(!ta.hasType!string);
}

unittest { // issue #1
	union U {
		int a;
		int b;
	}
	alias TA = TaggedAlgebraic!U;

	TA ta = TA(0, TA.Kind.b);
	static assert(!is(typeof(ta.hasType!double)));
	assert(ta.hasType!int);
}

unittest {
	union U {
		int a;
		float b;
	}
	alias TA = TaggedAlgebraic!U;

	const(TA) test() { return TA(12); }
	assert(test().hasType!int);
}


/** Gets the value stored in an algebraic type based on its data type.
*/
ref inout(T) get(T, U)(ref inout(TaggedAlgebraic!U) ta)
{
	static if (is(T == TaggedUnion!U))
		return ta.m_union;
	else return ta.m_union.value!T;
}
/// ditto
inout(T) get(T, U)(inout(TaggedAlgebraic!U) ta)
{
	return ta.m_union.value!T;
}

@nogc @safe nothrow unittest {
	struct Fields {
		int a;
		float b;
	}
	alias TA = TaggedAlgebraic!Fields;
	auto ta = TA(1);
	assert(ta.get!int == 1);
	ta.get!int = 2;
	assert(ta.get!int == 2);
	ta = TA(1.0);
	assert(ta.get!float == 1.0);
}

/** Gets the value stored in an algebraic type based on its kind.
*/
ref get(alias kind, U)(ref inout(TaggedAlgebraic!U) ta) if (is(typeof(kind) == typeof(ta).Kind))
{
	return ta.m_union.value!kind;
}
/// ditto
auto get(alias kind, U)(inout(TaggedAlgebraic!U) ta) if (is(typeof(kind) == typeof(ta).Kind))
{
	return ta.m_union.value!kind;
}

@nogc @safe nothrow unittest {
	struct Fields {
		int a;
		float b;
	}
	alias TA = TaggedAlgebraic!Fields;
	auto ta = TA(1);
	assert(ta.get!(TA.Kind.a) == 1);
	ta.get!(TA.Kind.a) = 2;
	assert(ta.get!(TA.Kind.a) == 2);
	ta = TA(1.0);
	assert(ta.get!(TA.Kind.b) == 1.0);
}

/** Calls a the given callback with the static type of the contained value.

	The `handler` callback must be a lambda or a single-argument template
	function that accepts all possible types that the given `TaggedAlgebraic`
	can hold.

	Returns:
		If `handler` has a non-void return value, its return value gets
		forwarded to the caller.
*/
auto apply(alias handler, TA)(TA ta)
	if (isInstanceOf!(TaggedAlgebraic, TA))
{
	final switch (ta.kind) {
		foreach (i, fn; TA.m_union.fieldNames) {
			case __traits(getMember, ta.Kind, fn):
				return handler(get!(TA.m_union.FieldTypes[i])(ta));
		}
	}
	static if (__VERSION__ <= 2068) assert(false);
}
/// ditto
auto apply(alias handler, T)(T value)
	if (!isInstanceOf!(TaggedAlgebraic, T))
{
	return handler(value);
}

///
unittest {
	union U {
		int i;
		string s;
	}
	alias TA = TaggedAlgebraic!U;

	assert(TA(12).apply!((v) {
		static if (is(typeof(v) == int)) {
			assert(v == 12);
			return 1;
		} else {
			return 0;
		}
	}) == 1);

	assert(TA("foo").apply!((v) {
		static if (is(typeof(v) == string)) {
			assert(v == "foo");
			return 2;
		} else {
			return 0;
		}
	}) == 2);

	"baz".apply!((v) {
		assert(v == "baz");
	});
}


/// User-defined attibute to disable `opIndex` forwarding for a particular tagged union member.
@property auto disableIndex() { assert(__ctfe, "disableIndex must only be used as an attribute."); return DisableOpAttribute(OpKind.index, null); }

private struct DisableOpAttribute {
	OpKind kind;
	string name;
}

/// User-defined attribute to enable only safe calls on the given member(s).
enum safeOnly;
///
@safe unittest
{
	union Fields
	{
		int intval;
		@safeOnly int *ptr;
	}

	// only safe operations allowed on pointer field
	@safe void test() {
		TaggedAlgebraic!Fields x = 1;
		x += 5; // only applies to intval
		auto p = new int(5);
		x = p;
		*x += 5; // safe pointer ops allowed
		assert(*p == 10);
	}

	test();
}

private template hasAnyMember(TA, string name)
{
	import std.traits : isAggregateType;

	alias Types = TA.UnionType.FieldTypes;

	template impl(size_t i) {
		static if (i >= Types.length) enum impl = false;
		else {
			alias T = Types[i];
			static if (__traits(hasMember, T, name)
				// work around https://issues.dlang.org/show_bug.cgi?id=20316
				|| (is(T : Q[], Q) && (name == "length" || name == "ptr" || name == "capacity")))
				enum impl = true;
			else enum impl = impl!(i+1);
		}
	}

	alias hasAnyMember = impl!0;
}

unittest {
	import std.range.primitives : isOutputRange;
	import std.typecons : Rebindable;

	struct S { int a, b; void foo() {}}
	interface I { void bar() immutable; }
	static union U { int x; S s; Rebindable!(const(I)) i; int[] a; }
	alias TA = TaggedAlgebraic!U;
	static assert(hasAnyMember!(TA, "a"));
	static assert(hasAnyMember!(TA, "b"));
	static assert(hasAnyMember!(TA, "foo"));
	static assert(hasAnyMember!(TA, "bar"));
	static assert(hasAnyMember!(TA, "length"));
	static assert(hasAnyMember!(TA, "ptr"));
	static assert(hasAnyMember!(TA, "capacity"));
	static assert(hasAnyMember!(TA, "sizeof"));
	static assert(!hasAnyMember!(TA, "put"));
	static assert(!isOutputRange!(TA, int));
}

private template hasOp(TA, OpKind kind, string name, ARGS...)
{
	import std.traits : CopyTypeQualifiers;
	alias UQ = CopyTypeQualifiers!(TA, TA.FieldDefinitionType);
	enum hasOp = AliasSeq!(OpInfo!(UQ, kind, name, ARGS).fields).length > 0;
}

unittest {
	static struct S {
		void m(int i) {}
		bool opEquals(int i) { return true; }
		bool opEquals(S s) { return true; }
	}

	static union U { int i; string s; S st; }
	alias TA = TaggedAlgebraic!U;

	static assert(hasOp!(TA, OpKind.binary, "+", int));
	static assert(hasOp!(TA, OpKind.binary, "~", string));
	static assert(hasOp!(TA, OpKind.binary, "==", int));
	static assert(hasOp!(TA, OpKind.binary, "==", string));
	static assert(hasOp!(TA, OpKind.binary, "==", int));
	static assert(hasOp!(TA, OpKind.binary, "==", S));
	static assert(hasOp!(TA, OpKind.method, "m", int));
	static assert(hasOp!(TA, OpKind.binary, "+=", int));
	static assert(!hasOp!(TA, OpKind.binary, "~", int));
	static assert(!hasOp!(TA, OpKind.binary, "~", int));
	static assert(!hasOp!(TA, OpKind.method, "m", string));
	static assert(!hasOp!(TA, OpKind.method, "m"));
	static assert(!hasOp!(const(TA), OpKind.binary, "+=", int));
	static assert(!hasOp!(const(TA), OpKind.method, "m", int));
	static assert(!hasOp!(TA, OpKind.method, "put", int));

	static union U2 { int *i; }
	alias TA2 = TaggedAlgebraic!U2;

	static assert(hasOp!(TA2, OpKind.unary, "*"));
}

unittest {
	struct S {
		union U {
			string s;
			S[] arr;
			S[string] obj;
		}
		alias TA = TaggedAlgebraic!(S.U);
		TA payload;
		alias payload this;
	}
	static assert(hasOp!(S.TA, OpKind.index, null, size_t));
	static assert(hasOp!(S.TA, OpKind.index, null, int));
	static assert(hasOp!(S.TA, OpKind.index, null, string));
	static assert(hasOp!(S.TA, OpKind.field, "length"));
}

unittest { // "in" operator
	union U {
		string[string] dict;
	}
	alias TA = TaggedAlgebraic!U;
	auto ta = TA(["foo": "bar"]);
	assert("foo" in ta);
	assert(*("foo" in ta) == "bar");
}

unittest { // issue #15 - by-ref return values
	static struct S {
		int x;
		ref int getx() return { return x; }
	}
	static union U { S s; }
	alias TA = TaggedAlgebraic!U;
	auto ta = TA(S(10));
	assert(ta.x == 10);
	ta.getx() = 11;
	assert(ta.x == 11);
}

private static auto ref implementOp(OpKind kind, string name, T, ARGS...)(ref T self, auto ref ARGS args)
{
	import std.array : join;
	import std.traits : CopyTypeQualifiers;
	import std.variant : Algebraic, Variant;
	alias UQ = CopyTypeQualifiers!(T, T.FieldDefinitionType);

	alias info = OpInfo!(UQ, kind, name, ARGS);

	static assert(hasOp!(T, kind, name, ARGS));

	static assert(info.fields.length > 0, "Implementing operator that has no valid implementation for any supported type.");

	//pragma(msg, "Fields for "~kind.stringof~" "~name~", "~T.stringof~": "~info.fields.stringof);
	//pragma(msg, "Return types for "~kind.stringof~" "~name~", "~T.stringof~": "~info.ReturnTypes.stringof);
	//pragma(msg, typeof(T.Union.tupleof));
	//import std.meta : staticMap; pragma(msg, staticMap!(isMatchingUniqueType!(T.Union), info.ReturnTypes));

	switch (self.kind) {
		enum assert_msg = "Operator "~name~" ("~kind.stringof~") can only be used on values of the following types: "~[info.fields].join(", ");
		default: assert(false, assert_msg);
		foreach (i, f; info.fields) {
			alias FT = T.UnionType.FieldTypeByName!f;
			case __traits(getMember, T.Kind, f):
				static if (NoDuplicates!(info.ReturnTypes).length == 1)
					return info.perform(self.m_union.trustedGet!FT, args);
				else static if (allSatisfy!(isMatchingUniqueType!T, info.ReturnTypes))
					return TaggedAlgebraic!(T.FieldDefinitionType)(info.perform(self.m_union.trustedGet!FT, args));
				else static if (allSatisfy!(isNoVariant, info.ReturnTypes)) {
					alias Alg = Algebraic!(NoDuplicates!(info.ReturnTypes));
					info.ReturnTypes[i] ret = info.perform(self.m_union.trustedGet!FT, args);
					import std.traits : isInstanceOf;
					return Alg(ret);
				}
				else static if (is(FT == Variant))
					return info.perform(self.m_union.trustedGet!FT, args);
				else
					return Variant(info.perform(self.m_union.trustedGet!FT, args));
		}
	}

	assert(false); // never reached
}

unittest { // opIndex on recursive TA with closed return value set
	static struct S {
		union U {
			char ch;
			string str;
			S[] arr;
		}
		alias TA = TaggedAlgebraic!U;
		TA payload;
		alias payload this;

		this(T)(T t) { this.payload = t; }
	}
	S a = S("foo");
	S s = S([a]);

	assert(implementOp!(OpKind.field, "length")(s.payload) == 1);
	static assert(is(typeof(implementOp!(OpKind.index, null)(s.payload, 0)) == S.TA));
	assert(implementOp!(OpKind.index, null)(s.payload, 0) == "foo");
}

unittest { // opIndex on recursive TA with closed return value set using @disableIndex
	static struct S {
		union U {
			@disableIndex string str;
			S[] arr;
		}
		alias TA = TaggedAlgebraic!U;
		TA payload;
		alias payload this;

		this(T)(T t) { this.payload = t; }
	}
	S a = S("foo");
	S s = S([a]);

	assert(implementOp!(OpKind.field, "length")(s.payload) == 1);
	static assert(is(typeof(implementOp!(OpKind.index, null)(s.payload, 0)) == S));
	assert(implementOp!(OpKind.index, null)(s.payload, 0) == "foo");
}

unittest { // test safeOnly
	static struct S
	{
		int foo() @system { return 1; }
	}

	static struct T
	{
		string foo() @safe { return "hi"; }
	}

	union GoodU {
		int x;
		@safeOnly int *ptr;
		@safeOnly S s;
		T t;
	}

	union BadU {
		int x;
		int *ptr;
		S s;
		T t;
	}

	union MixedU {
		int x;
		@safeOnly int *ptr;
		S s;
		T t;
	}

	TaggedAlgebraic!GoodU allsafe;
	TaggedAlgebraic!BadU nosafe;
	TaggedAlgebraic!MixedU somesafe;
	import std.variant : Algebraic;
	static assert(is(typeof(allsafe += 1)));
	static assert(is(typeof(allsafe.foo()) == string));
	static assert(is(typeof(nosafe += 1)));
	static assert(is(typeof(nosafe.foo()) == Algebraic!(int, string)));
	static assert(is(typeof(somesafe += 1)));
	static assert(is(typeof(somesafe.foo()) == Algebraic!(int, string)));

	static assert( is(typeof( () @safe => allsafe += 1)));
	static assert( is(typeof( () @safe => allsafe.foo())));
	static assert(!is(typeof( () @safe => nosafe += 1)));
	static assert(!is(typeof( () @safe => nosafe.foo())));
	static assert( is(typeof( () @safe => somesafe += 1)));
	static assert(!is(typeof( () @safe => somesafe.foo())));
}


private auto ref performOpRaw(U, OpKind kind, string name, T, ARGS...)(ref T value, /*auto ref*/ ARGS args)
{
	static if (kind == OpKind.binary) return mixin("value "~name~" args[0]");
	else static if (kind == OpKind.binaryRight) return mixin("args[0] "~name~" value");
	else static if (kind == OpKind.unary) return mixin(name~" value");
	else static if (kind == OpKind.method) return __traits(getMember, value, name)(args);
	else static if (kind == OpKind.field) return __traits(getMember, value, name);
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


private auto ref performOp(U, OpKind kind, string name, T, ARGS...)(ref T value, /*auto ref*/ ARGS args)
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
						alias MTypesImpl = AliasSeq!(FT, MTypesImpl!(i+1));
					else alias MTypesImpl = AliasSeq!(MTypesImpl!(i+1));
				} else alias MTypesImpl = AliasSeq!();
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

private template canPerform(U, bool doSafe, OpKind kind, string name, T, ARGS...)
{
	static if(doSafe)
		@safe auto ref doIt()(ref T t, ARGS args) { return performOp!(U, kind, name, T, ARGS)(t, args); }
	else
		auto ref doIt()(ref T t, ARGS args) { return performOp!(U, kind, name, T, ARGS)(t, args); }
	enum canPerform = is(typeof(&doIt!()));
}

private template OpInfo(U, OpKind kind, string name, ARGS...)
{
	import std.traits : CopyTypeQualifiers, ReturnType;

	private alias FieldKind = UnionFieldEnum!U;
	private alias FieldTypes = UnionKindTypes!FieldKind;
	private alias fieldNames = UnionKindNames!FieldKind;

	private template isOpEnabled(string field)
	{
		alias attribs = AliasSeq!(__traits(getAttributes, __traits(getMember, U, field)));
		template impl(size_t i) {
			static if (i < attribs.length) {
				static if (is(typeof(attribs[i]) == DisableOpAttribute)) {
					static if (kind == attribs[i].kind && name == attribs[i].name)
						enum impl = false;
					else enum impl = impl!(i+1);
				} else enum impl = impl!(i+1);
			} else enum impl = true;
		}
		enum isOpEnabled = impl!0;
	}

	private template isSafeOpRequired(string field)
	{
		alias attribs = AliasSeq!(__traits(getAttributes, __traits(getMember, U, field)));
		template impl(size_t i) {
			static if (i < attribs.length) {
				static if (__traits(isSame, attribs[i], safeOnly))
					enum impl = true;
				else enum impl = impl!(i+1);
			} else enum impl = false;
		}
		enum isSafeOpRequired = impl!0;
	}

	template fieldsImpl(size_t i)
	{
		static if (i < FieldTypes.length) {
			static if (isOpEnabled!(fieldNames[i]) && canPerform!(U, isSafeOpRequired!(fieldNames[i]), kind, name, FieldTypes[i], ARGS)) {
				alias fieldsImpl = AliasSeq!(fieldNames[i], fieldsImpl!(i+1));
			} else alias fieldsImpl = fieldsImpl!(i+1);
		} else alias fieldsImpl = AliasSeq!();
	}
	alias fields = fieldsImpl!0;

	template ReturnTypesImpl(size_t i) {
		static if (i < fields.length) {
			alias FT = CopyTypeQualifiers!(U, TypeOf!(__traits(getMember, FieldKind, fields[i])));
			alias ReturnTypesImpl = AliasSeq!(ReturnType!(performOp!(U, kind, name, FT, ARGS)), ReturnTypesImpl!(i+1));
		} else alias ReturnTypesImpl = AliasSeq!();
	}
	alias ReturnTypes = ReturnTypesImpl!0;

	static auto ref perform(T)(ref T value, auto ref ARGS args) { return performOp!(U, kind, name)(value, args); }
}

private template ImplicitUnqual(T) {
	import std.traits : Unqual, hasAliasing;
	static if (is(T == void)) alias ImplicitUnqual = void;
	else {
		private static struct S { T t; }
		static if (hasAliasing!S) alias ImplicitUnqual = T;
		else alias ImplicitUnqual = Unqual!T;
	}
}

private enum OpKind {
	binary,
	binaryRight,
	unary,
	method,
	field,
	index,
	indexAssign,
	call
}

deprecated alias TypeEnum(U) = UnionFieldEnum!U;


private string generateConstructors(U)()
{
	import std.algorithm : map;
	import std.array : join;
	import std.string : format;
	import std.traits : FieldTypeTuple;

	string ret;


	// normal type constructors
	foreach (tname; UniqueTypeFields!U)
		ret ~= q{
			this(UnionType.FieldTypeByName!"%1$s" value)
			{
				static if (isUnitType!(UnionType.FieldTypeByName!"%1$s"))
					m_union.set!(Kind.%1$s)();
				else
					m_union.set!(Kind.%1$s)(value);
			}

			void opAssign(UnionType.FieldTypeByName!"%1$s" value)
			{
				static if (isUnitType!(UnionType.FieldTypeByName!"%1$s"))
					m_union.set!(Kind.%1$s)();
				else
					m_union.set!(Kind.%1$s)(value);
			}
		}.format(tname);

	// type constructors with explicit type tag
	foreach (tname; AliasSeq!(UniqueTypeFields!U, AmbiguousTypeFields!U))
		ret ~= q{
			this(UnionType.FieldTypeByName!"%1$s" value, Kind type)
			{
				switch (type) {
					foreach (i, n; TaggedUnion!U.fieldNames) {
						static if (is(UnionType.FieldTypeByName!"%1$s" == UnionType.FieldTypes[i])) {
							case __traits(getMember, Kind, n):
								static if (isUnitType!(UnionType.FieldTypes[i]))
									m_union.set!(__traits(getMember, Kind, n))();
								else m_union.set!(__traits(getMember, Kind, n))(value);
								return;
						}
					}
					// NOTE: the default case needs to be at the bottom to avoid bogus
					//       unreachable code warnings (DMD issue 21671)
					default: assert(false, format("Invalid type ID for type %%s: %%s", UnionType.FieldTypeByName!"%1$s".stringof, type));
				}
			}
		}.format(tname);

	return ret;
}

private template UniqueTypeFields(U) {
	alias Enum = UnionFieldEnum!U;
	alias Types = UnionKindTypes!Enum;
	alias indices = UniqueTypes!Types;
	enum toName(int i) = UnionKindNames!Enum[i];
	alias UniqueTypeFields = staticMap!(toName, indices);
}

private template AmbiguousTypeFields(U) {
	alias Enum = UnionFieldEnum!U;
	alias Types = UnionKindTypes!Enum;
	alias indices = AmbiguousTypes!Types;
	enum toName(int i) = UnionKindNames!Enum[i];
	alias AmbiguousTypeFields = staticMap!(toName, indices);
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

private template isMatchingUniqueType(TA) {
	import std.traits : staticMap;
	alias FieldTypes = UnionKindTypes!(UnionFieldEnum!(TA.FieldDefinitionType));
	alias F(size_t i) = FieldTypes[i];
	alias UniqueTypes = staticMap!(F, .UniqueTypes!FieldTypes);
	template isMatchingUniqueType(T) {
		static if (is(T : TA)) enum isMatchingUniqueType = true;
		else enum isMatchingUniqueType = staticIndexOfImplicit!(T, UniqueTypes) >= 0;
	}
}

unittest {
	union U {
		int i;
		TaggedAlgebraic!This[] array;
	}
	alias TA = TaggedAlgebraic!U;
	alias pass(alias templ, T) = templ!T;
	static assert(pass!(isMatchingUniqueType!TA, TaggedAlgebraic!U));
	static assert(!pass!(isMatchingUniqueType!TA, string));
	static assert(pass!(isMatchingUniqueType!TA, int));
	static assert(pass!(isMatchingUniqueType!TA, (TaggedAlgebraic!U[])));
}

private template fieldMatchesType(U, T)
{
	enum fieldMatchesType(string field) = is(TypeOf!(__traits(getMember, UnionFieldEnum!U, field)) == T);
}

private template FieldTypeOf(U) {
	template FieldTypeOf(string name) {
		alias FieldTypeOf = TypeOf!(__traits(getMember, UnionFieldEnum!U, name));
	}
}

private template staticIndexOfImplicit(T, Types...) {
	template impl(size_t i) {
		static if (i < Types.length) {
			static if (is(T : Types[i])) enum impl = i;
			else enum impl = impl!(i+1);
		} else enum impl = -1;
	}
	enum staticIndexOfImplicit = impl!0;
}

unittest {
	static assert(staticIndexOfImplicit!(immutable(char), char) == 0);
	static assert(staticIndexOfImplicit!(int, long) == 0);
	static assert(staticIndexOfImplicit!(long, int) < 0);
	static assert(staticIndexOfImplicit!(int, int, double) == 0);
	static assert(staticIndexOfImplicit!(double, int, double) == 1);
}


private template isNoVariant(T) {
	import std.variant : Variant;
	enum isNoVariant = !is(T == Variant);
}


unittest {
	struct TU { int i; }
	alias TA = TaggedAlgebraic!TU;

	auto ta = TA(12);
	static assert(!is(typeof(ta.put(12))));
}

@safe nothrow unittest {
	struct TU { int i; string s; }
	alias TA = TaggedAlgebraic!TU;

	static assert(is(typeof(TA.init.toHash()) == size_t));

	int[TA] aa;
	aa[TA(1)] = 1;
	aa[TA("foo")] = 2;

	assert(aa[TA(1)] == 1);
	assert(aa[TA("foo")] == 2);
}
