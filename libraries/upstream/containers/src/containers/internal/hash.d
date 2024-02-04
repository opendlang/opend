/**
 * Templates for hashing types.
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module containers.internal.hash;

static if (hash_t.sizeof == 4)
{
	hash_t generateHash(T)(const T value)
	{
		return hashOf(value);
	}
}
else
{
	hash_t generateHash(T)(const T value) if (!is(T == string))
	{
		return hashOf(value);
	}

	/**
	 * A variant of the FNV-1a (64) hashing algorithm.
	 */
	hash_t generateHash(T)(T value) pure nothrow @nogc @trusted if (is(T == string))
	{
		hash_t h = 0xcbf29ce484222325;
		foreach (const ubyte c; cast(ubyte[]) value)
		{
			h ^= ((c - ' ') * 13);
			h *= 0x100000001b3;
		}
		return h;
	}
}

/**
 * Convert a hash code into a valid array index.
 *
 * Prams:
 *     hash = the hash code to be mapped
 *     len = the length of the array that backs the hash container.
 */
size_t hashToIndex(const size_t hash, const size_t len) pure nothrow @nogc @safe
{
	// This magic number taken from
	// https://probablydance.com/2018/06/16/fibonacci-hashing-the-optimization-that-the-world-forgot-or-a-better-alternative-to-integer-modulo/
	//
	// It's amazing how much faster this makes the hash data structures
	// when faced with low quality hash functions.
	static if (size_t.sizeof == 8)
		enum ulong magic = 11_400_714_819_323_198_485UL;
	else
		enum uint magic = 2_654_435_769U;

	if (len <= 1)
		return 0;
	version(LDC)
	{
		import ldc.intrinsics : llvm_cttz;
		return (hash * magic) >>> ((size_t.sizeof * 8) - llvm_cttz(len, true));
	}
	else
	{
		import core.bitop : bsf;
		return (hash * magic) >>> ((size_t.sizeof * 8) - bsf(len));
	}
}

enum size_t DEFAULT_BUCKET_COUNT = 8;
