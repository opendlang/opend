/**
 * Templates for container node types.
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module containers.internal.node;

template FatNodeInfo(size_t bytesPerItem, size_t pointerCount, size_t cacheLineSize = 64,
	size_t extraSpace = size_t.max)
{
	import std.meta : AliasSeq;
	import std.format : format;
	template fatNodeCapacity(alias L, bool CheckLength = true)
	{
		enum size_t optimistic = (cacheLineSize
			- ((void*).sizeof * pointerCount) - L) / bytesPerItem;
		static if (optimistic > 0)
		{
			enum fatNodeCapacity = optimistic;
			static if (CheckLength)
			{
				static assert(optimistic <= L * 8, ("%d bits required for bookkeeping"
					~ " but only %d are possible. Try reducing the cache line size argument.")
					.format(optimistic, L * 8));
			}
		}
		else
			enum fatNodeCapacity = 1;
	}
	static if (extraSpace == size_t.max)
	{
		static if (__traits(compiles, fatNodeCapacity!(ubyte.sizeof)))
			alias FatNodeInfo = AliasSeq!(fatNodeCapacity!(ubyte.sizeof), ubyte);
		else static if (__traits(compiles, fatNodeCapacity!(ushort.sizeof)))
			alias FatNodeInfo = AliasSeq!(fatNodeCapacity!(ushort.sizeof), ushort);
		else static if (__traits(compiles, fatNodeCapacity!(uint.sizeof)))
			alias FatNodeInfo = AliasSeq!(fatNodeCapacity!(uint.sizeof), uint);
		else static if (__traits(compiles, fatNodeCapacity!(ulong.sizeof)))
			alias FatNodeInfo = AliasSeq!(fatNodeCapacity!(ulong.sizeof), ulong);
		else static assert(false, "No type big enough to store " ~ extraSpace.stringof);
	}
	else
		alias FatNodeInfo = AliasSeq!(fatNodeCapacity!(extraSpace, false), void);
}

// Double linked fat node of int with bookkeeping in a uint should be able to
// hold 11 ints per node.
// 64 - 16 - 4 = 4 * 11
version (X86_64)
	static assert (FatNodeInfo!(int.sizeof, 2)[0] == 11);

template shouldNullSlot(T)
{
	import std.traits;
	enum shouldNullSlot = isPointer!T || is (T == class) || is (T == interface) || isDynamicArray!T 
							|| is(T == delegate); // closures or class method shoulde be null for GC recycle
}

template shouldAddGCRange(T)
{
	import std.traits;
	enum shouldAddGCRange = hasIndirections!T;
}

static assert (shouldAddGCRange!string);
static assert (!shouldAddGCRange!int);

template fullBits(T, size_t n, size_t c = 0)
{
	static if (c >= (n - 1))
		enum T fullBits = (T(1) << c);
	else
		enum T fullBits = (T(1) << c) | fullBits!(T, n, c + 1);
}

static assert (fullBits!(ushort, 1) == 1);
static assert (fullBits!(ushort, 2) == 3);
static assert (fullBits!(ushort, 3) == 7);
static assert (fullBits!(ushort, 4) == 15);
