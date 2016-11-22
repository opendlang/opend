
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
	if(isUnsigned!T && isUniformRNG!G)
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
	gen = uniform random number generator
	m = positive module
Returns:
	Uniformly distributed integer for interval `[0 .. m)`.
+/
T randIndex(T, G)(ref G gen, T m)
	if(isUnsigned!T && isUniformRNG!G)
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
