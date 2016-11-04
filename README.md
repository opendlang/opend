painlesstraits
==============

[![Build Status](https://travis-ci.org/msoucy/painlesstraits.svg)](https://travis-ci.org/msoucy/painlesstraits)
[![Coverage Status](https://coveralls.io/repos/msoucy/painlesstraits/badge.svg?branch=master&service=github)](https://coveralls.io/github/msoucy/painlesstraits?branch=master)

This module provides a few helper templates to make working with [dlang][]'s [User Defined Attributes][] just a bit nicer.

Inspired and derived from templates found in the [painlessjson][] project.

[dlang]: http://dlang.org
[User Defined Attributes]: http://dlang.org/attribute.html#uda
[painlessjson]: https://github.com/BlackEdder/painlessjson/blob/2c0a8245eefc83da044a89ff833199da136af262/source/painlessjson/traits.d

```d
import painlesstraits;

struct SomeContainer
{
	int a;
	string b;
	long c;

	string name() @property
	{
		return "SomeContainer." ~ b;
	}

	string someFunction()
	{
		return "Foo";
	}
}

pragma(msg, allPublicFieldsOrProperties!SomeContainer); // tuple("a", "b", "c", "name")
pragma(msg, allPublicFields!SomeContainer); // tuple("a", "b", "c")

// and much more
```