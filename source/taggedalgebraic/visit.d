module taggedalgebraic.visit;

import taggedalgebraic.taggedalgebraic;
import taggedalgebraic.taggedunion;

import std.meta : anySatisfy, staticMap;
import std.traits : Unqual, EnumMembers, isInstanceOf;


/** Dispatches the value contained on a `TaggedUnion` or `TaggedAlgebraic` to a
	set of visitors.

	A visitor can have one of three forms:

	$(UL
		$(LI function or delegate taking a single typed parameter)
		$(LI function or delegate taking no parameters)
		$(LI function or delegate template taking any single parameter)
	)

	....
*/
template visit(VISITORS...)
	if (VISITORS.length > 0)
{
	auto visit(TU)(auto ref TU tu)
		if (isInstanceOf!(TaggedUnion, TU))
	{
		alias val = validateHandlers!(TU, VISITORS);

		final switch (tu.kind) {
			static foreach (k; EnumMembers!(TU.Kind)) {
				case k: {
					static if (isUnitType!(TU.FieldTypes[k]))
						alias T = void;
					else alias T = TU.FieldTypes[k];
					alias h = selectHandler!(T, VISITORS);
					static if (is(typeof(h) == typeof(null))) static assert(false, "No visitor defined for type "~T.stringof);
					else static if (is(typeof(h) == string)) static assert(false, h);
					else static if (is(T == void)) return h();
					else return h(tu.value!k);
				}
			}
		}
	}

	auto visit(U)(auto ref TaggedAlgebraic!U ta)
	{
		return visit(ta.get!(TaggedUnion!U));
	}
}

///
unittest {
	static if (__VERSION__ >= 2081) {
		import std.conv : to;

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
}

unittest {
	// repeat test from TaggedUnion
	union U {
		Void none;
		int count;
		float length;
	}
	TaggedAlgebraic!U u;

	//
	static assert(is(typeof(u.visit!((int) {}, (float) {}, () {}))));
	static assert(is(typeof(u.visit!((_) {}, () {}))));
	static assert(is(typeof(u.visit!((_) {}, (float) {}, () {}))));
	static assert(is(typeof(u.visit!((float) {}, (_) {}, () {}))));

	static assert(!is(typeof(u.visit!((_) {})))); // missing void handler
	static assert(!is(typeof(u.visit!(() {})))); // missing value handler

	static assert(!is(typeof(u.visit!((_) {}, () {}, (string) {})))); // invalid typed handler
	static assert(!is(typeof(u.visit!((int) {}, (float) {}, () {}, () {})))); // duplicate void handler
	static assert(!is(typeof(u.visit!((_) {}, () {}, (_) {})))); // duplicate generic handler
	static assert(!is(typeof(u.visit!((int) {}, (float) {}, (float) {}, () {})))); // duplicate typed handler

	// TODO: error out for superfluous generic handlers
	//static assert(!is(typeof(u.visit!((int) {}, (float) {}, () {}, (_) {})))); // superfluous generic handler
}

unittest {
	union U {
		Void none;
		int count;
		float length;
	}
	TaggedUnion!U u;

	//
	static assert(is(typeof(u.visit!((int) {}, (float) {}, () {}))));
	static assert(is(typeof(u.visit!((_) {}, () {}))));
	static assert(is(typeof(u.visit!((_) {}, (float) {}, () {}))));
	static assert(is(typeof(u.visit!((float) {}, (_) {}, () {}))));

	static assert(!is(typeof(u.visit!((_) {})))); // missing void handler
	static assert(!is(typeof(u.visit!(() {})))); // missing value handler

	static assert(!is(typeof(u.visit!((_) {}, () {}, (string) {})))); // invalid typed handler
	static assert(!is(typeof(u.visit!((int) {}, (float) {}, () {}, () {})))); // duplicate void handler
	static assert(!is(typeof(u.visit!((_) {}, () {}, (_) {})))); // duplicate generic handler
	static assert(!is(typeof(u.visit!((int) {}, (float) {}, (float) {}, () {})))); // duplicate typed handler

	// TODO: error out for superfluous generic handlers
	//static assert(!is(typeof(u.visit!((int) {}, (float) {}, () {}, (_) {})))); // superfluous generic handler
}

unittest {
	// make sure that the generic handler is not instantiated with types for
	// which it doesn't compile
	class C {}
	union U { int i; C c; }
	TaggedUnion!U u;
	u.visit!(
		(C c) => c !is null,
		(v) {
			static assert(is(typeof(v) == int));
			return v != 0;
		}
	);
}

unittest {
	static struct S {
		Void nothing;
		int num;
		int[] nums;
	}
	alias TU = TaggedUnion!S;

	TU tu = [1];
	tu.visit!(
		() { assert(false); },
		(int num) { assert(false); },
		(int[] num) { assert(num == [1]); }
	);
	tu.visit!(
		() { assert(false); },
		(const int num) { assert(false); },
		(const int[] num) { assert(num == [1]); }
	);
	tu.visit!(
		() { assert(false); },
		(const int num) { assert(false); },
		(const(int)[] num) { assert(num == [1]); }
	);

	const(TU) tuc = TU([1]);
	tuc.visit!(
		() { assert(false); },
		(int num) { assert(false); },
		(const(int)[] num) { assert(num == [1]); }
	);
	tuc.visit!(
		() { assert(false); },
		(const(int) num) { assert(false); },
		(const(int[]) num) { assert(num == [1]); }
	);
}


/** The same as `visit`, except that failure to handle types is checked at runtime.

	Instead of failing to compile, `tryVisit` will throw an `Exception` if none
	of the handlers is able to handle the value contained in `tu`.
*/
template tryVisit(VISITORS...)
	if (VISITORS.length > 0)
{
	auto tryVisit(TU)(auto ref TU tu)
		if (isInstanceOf!(TaggedUnion, TU))
	{
		final switch (tu.kind) {
			static foreach (k; EnumMembers!(TU.Kind)) {
				case k: {
					static if (isUnitType!(TU.FieldTypes[k]))
						alias T = void;
					else alias T = TU.FieldTypes[k];
					alias h = selectHandler!(T, VISITORS);
					static if (is(typeof(h) == typeof(null))) throw new Exception("Type "~T.stringof~" not handled by any visitor.");
					else static if (is(typeof(h) == string)) static assert(false, h);
					else static if (is(T == void)) return h();
					else return h(tu.value!k);
				}
			}
		}
	}

	auto tryVisit(U)(auto ref TaggedAlgebraic!U ta)
	{
		return tryVisit(ta.get!(TaggedUnion!U));
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

// repeat from TaggedUnion
unittest {
	import std.exception : assertThrown;

	union U {
		int number;
		string text;
	}
	alias TA = TaggedAlgebraic!U;

	auto ta = TA(42);
	ta.tryVisit!((int n) { assert(n == 42); });
	assertThrown(ta.tryVisit!((string s) { assert(false); }));
}


private template validateHandlers(TU, VISITORS...)
{
	import std.traits : CopyConstness, isSomeFunction;

	alias ApplyConst(T) = CopyConstness!(TU, T);
	alias Types = staticMap!(ApplyConst, TU.FieldTypes);

	static foreach (int i; 0 .. VISITORS.length) {
		static if (isSomeFunction!(VISITORS[i])) {
			static assert(anySatisfy!(matchesType!(VISITORS[i]), Types),
				"Visitor at index "~i.stringof~" does not match any type of "~Types.stringof);
		} else {
			static assert(__traits(isTemplate, VISITORS[i]),
				"Visitor at index "~i.stringof~" must be a function/delegate literal: "~VISITORS[i].stringof);
		}
	}
}

private template matchesType(alias fun) {
	import std.traits : ParameterTypeTuple, isSomeFunction;

	template matchesType(T) {
		static if (isSomeFunction!fun) {
			alias Params = ParameterTypeTuple!fun;
			static if (Params.length == 0 && isUnitType!(Unqual!T)) enum matchesType = true;
			else static if (Params.length == 1 && isMatch!(Params[0], T)) enum matchesType = true;
			else enum matchesType = false;
		} else static if (!isUnitType!(Unqual!T)) {
			static if (__traits(compiles, fun!T) && isSomeFunction!(fun!T)) {
				alias Params = ParameterTypeTuple!(fun!T);
				static if (Params.length == 1 && isMatch!(Params[0], T)) enum matchesType = true;
				else enum matchesType = false;
			} else enum matchesType = false;
		} else enum matchesType = false;
	}
}

unittest {
	class C {}
	alias mt1 = matchesType!((C c) => true);
	alias mt2 = matchesType!((c) { static assert(!is(typeof(c) == C)); });
	static assert(mt1!C);
	static assert(!mt1!int);
	static assert(mt2!int);
	static assert(!mt2!C);
}

private template selectHandler(T, VISITORS...)
{
	import std.traits : ParameterTypeTuple, isSomeFunction;

	template typedIndex(int i, int matched_index = -1) {
		static if (i < VISITORS.length) {
			alias fun = VISITORS[i];
			static if (isSomeFunction!fun) {
				alias Params = ParameterTypeTuple!fun;
				static if (Params.length > 1) enum typedIndex = "Visitor at index "~i.stringof~" must not take more than one parameter.";
				else static if (Params.length == 0 && is(Unqual!T == void) || Params.length == 1 && isMatch!(Params[0], T)) {
					static if (matched_index >= 0) enum typedIndex = "Vistor at index "~i.stringof~" conflicts with visitor at index "~matched_index~".";
					else enum typedIndex = typedIndex!(i+1, i);
				} else enum typedIndex = typedIndex!(i+1, matched_index);
			} else enum typedIndex = typedIndex!(i+1, matched_index);
		} else enum typedIndex = matched_index;
	}

	template genericIndex(int i, int matched_index = -1) {
		static if (i < VISITORS.length) {
			alias fun = VISITORS[i];
			static if (!isSomeFunction!fun) {
				static if (!__traits(isTemplate, fun)) enum genericIndex = "Visitor at index " ~ i.stringof ~ " is neither a function, nor a template.";
				else static if (__traits(compiles, fun!T) && isSomeFunction!(fun!T)) {
					static if (ParameterTypeTuple!(fun!T).length == 1) {
						static if (matched_index >= 0) enum genericIndex = "Only one generic visitor allowed";
						else enum genericIndex = genericIndex!(i+1, i);
					} else enum genericIndex = "Generic visitor at index "~i.stringof~" must have a single parameter.";
				} else enum genericIndex = genericIndex!(i+1, i); // let this fail within the template instantiation instead of here
			} else enum genericIndex = genericIndex!(i+1, matched_index);
		} else enum genericIndex = matched_index;
	}

	enum typed_index = typedIndex!0;
	static if (is(T == void) || (is(typeof(typed_index) == string) && typed_index != -1))
		enum generic_index = -1;
	else enum generic_index = genericIndex!0;

	static if (is(typeof(typed_index) == string)) enum selectHandler = typed_index;
	else static if (is(typeof(generic_index) == string)) enum selectHandler = generic_index;
	else static if (typed_index >= 0) alias selectHandler = VISITORS[typed_index];
	else static if (generic_index >= 0) alias selectHandler = VISITORS[generic_index];
	else enum selectHandler = null;
}

private enum isMatch(PT, T) = is(Unqual!(immutable(T)) == Unqual!(immutable(PT))) && is(T : PT);
