
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

version (LDC)
{
    pragma(inline, true)
    int bsr(size_t v) pure
    {
        return cast(int)(size_t.sizeof * 8 - 1 - llvm_ctlz(v, true));
    }
}
else
{
    int bsr(size_t v) pure;
}

version (LDC)
{
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
	Returns: number (`n`) of bit tests strictly before the first positive test.
	`P(n) := 1 / (2^^(n + 1)) for n >= 0`.
+/
size_t randExponent(G)(ref G gen)
	if(isUniformRNG!G)
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

unittest
{
	auto gen = Xorshift(cast(uint)unpredictableSeed);
	auto v = gen.randExponent();
}
