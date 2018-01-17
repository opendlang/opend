TaggedAlgebraic
===============

Implementation of a generic algebraic data type with a tagged union storage. All operations of the contained types are available for the `TaggedAlgebraic`

[![Build Status](https://travis-ci.org/s-ludwig/taggedalgebraic.svg?branch=master)](https://travis-ci.org/s-ludwig/taggedalgebraic) [![codecov](https://codecov.io/gh/s-ludwig/taggedalgebraic/branch/master/graph/badge.svg)](https://codecov.io/gh/s-ludwig/taggedalgebraic)


Usage
-----

```d
import taggedalgebraic;

struct Foo {
	string name;
	void bar() {}
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
```
