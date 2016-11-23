/++
Authors: Ilya Yaroshenko
Copyright: Copyright, Ilya Yaroshenko 2016-.
License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
+/
module random;

import std.traits;

public import random.generator;

/++
Params:
	gen = random random number generator
Returns:
	Uniformly distributed integer for interval `[0 .. T.max]`.
+/
T rand(T, G)(ref G gen)
	if (isUnsigned!T && isSURBG!G && !is(T == enum))
{
	alias R = ReturnType!G;
	enum P = T.sizeof / R.sizeof;
	static if (P > 1)
	{
		T ret = void;
		foreach(p; 0..P)
			(cast(R*)(&ret))[p] = gen();
		return ret;
	}
	else
	{
		version(LDC) pragma(inline, true);
		return cast(T) gen();
	}
}

///
unittest
{
	auto gen = Xorshift(1);
	auto s = gen.rand!ushort;
	auto n = gen.rand!ulong;
}

/++
Params:
	gen = random random number generator
Returns:
	Uniformly distributed boolean.
+/
bool rand(T : bool, G)(ref G gen)
	if (isSURBG!G)
{
	return gen() & 1;
}

///
unittest
{
	auto gen = Xorshift(1);
	auto s = gen.rand!bool;
}

private alias Iota(size_t j) = Iota!(0, j);

private template Iota(size_t i, size_t j)
{
	import std.meta;
    static assert(i <= j, "Iota: i should be less than or equal to j");
    static if (i == j)
        alias Iota = AliasSeq!();
    else
        alias Iota = AliasSeq!(i, Iota!(i + 1, j));
}

/++
Params:
	gen = random random number generator
Returns:
	Uniformly distributed boolean.
+/
T rand(T, G)(ref G gen)
	if (isSURBG!G && is(T == enum))
{
	static if (is(T : long))
		enum tiny = [EnumMembers!T] == [Iota!(EnumMembers!T.length)];
	else
		enum tiny = false;
	static if (tiny)
	{
		return cast(T) gen.randIndex(EnumMembers!T.length);
	}
	else
	{
	    static immutable T[EnumMembers!T.length] members = [EnumMembers!T];
		return members[gen.randIndex($)];
	}
}

///
unittest
{
	auto gen = Xorshift(1);
	enum A { a, b, c }
	auto e = gen.rand!A;
}

///
unittest
{
	auto gen = Xorshift(1);
	enum A : dchar { a, b, c }
	auto e = gen.rand!A;
}

///
unittest
{
	auto gen = Xorshift(1);
	enum A : string { a = "a", b = "b", c = "c" }
	auto e = gen.rand!A;
}

/++
Params:
	gen = uniform random number generator
	m = positive module
Returns:
	Uniformly distributed integer for interval `[0 .. m)`.
+/
T randIndex(T, G)(ref G gen, T m)
	if(isUnsigned!T && isSURBG!G)
{
	assert(m, "m must be positive");
    T ret = void;
    T val = void;
    do
    {
        val = gen.rand!T;
        ret = val % m;
    }
    while (val - ret > -m);
    return ret;
}

///
unittest
{
	auto gen = Xorshift(1);
	auto s = gen.randIndex!uint(100);
	auto n = gen.randIndex!ulong(-100);
}

version (LDC)
{
	private
    pragma(inline, true)
    size_t bsf(size_t v) pure @safe nothrow @nogc
    {
    	import ldc.intrinsics;
        return cast(int)llvm_cttz(v, true);
    }
}
else
{
    import core.bitop: bsf;
}

/++
	Returns: `n >= 0` such that `P(n) := 1 / (2^^(n + 1))`.
+/
size_t randGeometric(G)(ref G gen)
	if(isSURBG!G)
{
	alias R = ReturnType!G;
	static if (is(R == ulong))
		alias T = size_t;
	else
		alias T = R;
	size_t count = 0;
	for(;;)
	{
		if(auto val = gen.rand!T())
			return count + bsf(val);
		count += T.sizeof * 8;
	}
}

///
unittest
{
	auto gen = Xorshift(cast(uint)unpredictableSeed);
	auto v = gen.randGeometric();
}
