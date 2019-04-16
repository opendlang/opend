TaggedAlgebraic
===============

Implementation of a generic `TaggedUnion` type along with a `TaggedAlgebraic` type that forwards all methods and operators of the contained types using dynamic dispatch.

[![Build Status](https://travis-ci.org/s-ludwig/taggedalgebraic.svg?branch=master)](https://travis-ci.org/s-ludwig/taggedalgebraic) [![codecov](https://codecov.io/gh/s-ludwig/taggedalgebraic/branch/master/graph/badge.svg)](https://codecov.io/gh/s-ludwig/taggedalgebraic)


Usage of `TaggedUnion`
----------------------

```d
import taggedalgebraic;

struct Foo {
	string name;
	void bar() {}
}

union Base {
	int count;
	int offset;
	string str;
	Foo foo;
}

alias TUnion = TaggedUnion!Base;

// Instantiate
TUnion taggedInt = TUnion.count(5);
TUnion taggedString = TUnion.str("Hello");
TUnion taggedFoo = TUnion.foo;
TUnion taggedAny = taggedInt;
taggedAny = taggedString;
taggedAny = taggedFoo;

// Default initializes to the first field
TUnion taggedDef;
assert(taggedDef.isCount);
assert(taggedDef.countValue == int.init);

// Check type: TUnion.Kind is an enum
assert(taggedInt.kind == TUnion.Kind.count);
assert(taggedString.kind == TUnion.Kind.str);
assert(taggedFoo.kind == TUnion.Kind.foo);
assert(taggedAny.kind == TUnion.Kind.foo);

// A shorter syntax is also available
assert(taggedInt.isCount);
assert(!taggedInt.isOffset);
assert(taggedString.isStr);
assert(taggedFoo.isFoo);
assert(taggedAny.isFoo);

// Set to a different type
taggedAny.setStr("bar");
assert(taggedAny.isStr);
assert(taggedAny.strValue == "bar");

// Modify contained value by reference
taggedAny.strValue = "baz";
assert(taggedAny.strValue == "baz");

// In addition to the getter, the contained value can be extracted using get!()
// or by casting
assert(taggedInt.value!(TUnion.Kind.count) == 5);
assert(taggedInt.value!int == 5);
assert(cast(byte)taggedInt == 5);

// Multiple kinds of the same type are supported
taggedAny.setOffset(5);
assert(taggedAny.isOffset);
assert(!taggedAny.isCount);

// Unique types can also be set directly
taggedAny = "foo";
assert(taggedAny.isStr);
taggedAny = TUnion(Foo.init);
assert(taggedAny.isFoo);
```


Usage of `TaggedAlgebraic`
--------------------------

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

alias TAlgebraic = TaggedAlgebraic!Base;

// Instantiate
TAlgebraic taggedInt = 5;
TAlgebraic taggedString = "Hello";
TAlgebraic taggedFoo = Foo();
TAlgebraic taggedAny = taggedInt;
taggedAny = taggedString;
taggedAny = taggedFoo;

// Check type: TAlgebraic.Kind is an enum
assert(taggedInt.kind == TAlgebraic.Kind.i);
assert(taggedString.kind == TAlgebraic.Kind.str);
assert(taggedFoo.kind == TAlgebraic.Kind.foo);
assert(taggedAny.kind == TAlgebraic.Kind.foo);

// In most cases, can simply use as-is
auto num = 4 + taggedInt;
auto msg = taggedString ~ " World!";
taggedFoo.bar();
if (taggedAny.kind == TAlgebraic.Kind.foo) // Make sure to check type first!
	taggedAny.bar();
//taggedString.bar(); // AssertError: Not a Foo!

// Convert back by casting
auto i   = cast(int)    taggedInt;
auto str = cast(string) taggedString;
auto foo = cast(Foo)    taggedFoo;
if (taggedAny.kind == TAlgebraic.Kind.foo) // Make sure to check type first!
	auto foo2 = cast(Foo) taggedAny;
//cast(Foo) taggedString; // AssertError!

// Kind is an enum, so final switch is supported:
final switch (taggedAny.kind) {
	case TAlgebraic.Kind.i:
		// It's "int i"
		break;

	case TAlgebraic.Kind.str:
		// It's "string str"
		break;

	case TAlgebraic.Kind.foo:
		// It's "Foo foo"
		break;
}
```

Compiler support
----------------

The library is tested to work on the following compilers:

- DMD 2.076.1 up to 2.084.1
- LDC 1.6.0 up to 1.14.0
