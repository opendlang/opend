/**
 * Tree Map
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */

module containers.treemap;

private import containers.internal.node : shouldAddGCRange;
private import std.experimental.allocator.mallocator : Mallocator;

/**
 * A key→value mapping where the keys are guaranteed to be sorted.
 * Params:
 *     K = the key type
 *     V = the value type
 *     Allocator = the allocator to use. Defaults to `Mallocator`.
 *     less = the key comparison function to use
 *     supportGC = true to support storing GC-allocated objects, false otherwise
 *     cacheLineSize = the size of the internal nodes in bytes
 */
struct TreeMap(K, V, Allocator = Mallocator, alias less = "a < b",
	bool supportGC = shouldAddGCRange!K || shouldAddGCRange!V, size_t cacheLineSize = 64)
{
	this(this) @disable;

	private import std.experimental.allocator.common : stateSize;

	auto allocator()
	{
		return tree.allocator;
	}

	static if (stateSize!Allocator != 0)
	{
		/// No default construction if an allocator must be provided.
		this() @disable;

		/**
		 * Use the given `allocator` for allocations.
		 */
		this(Allocator allocator)
		{
			tree = TreeType(allocator);
		}
	}

	void clear()
	{
		tree.clear();
	}

	/**
	 * Inserts or overwrites the given key-value pair.
	 */
	void insert(const K key, V value) @trusted
	{
		auto tme = TreeMapElement(cast(ContainerStorageType!K) key, value);
		auto r = tree.equalRange(tme);
		if (r.empty)
			tree.insert(tme, true);
		else
			r._containersFront().value = value;
	}

	/// Supports $(B treeMap[key] = value;) syntax.
	void opIndexAssign(V value, const K key)
	{
		insert(key, value);
	}

	/**
	 * Supports $(B treeMap[key]) syntax.
	 *
	 * Throws: RangeError if the key does not exist.
	 */
	auto opIndex(this This)(const K key) inout
	{
		alias CET = ContainerElementType!(This, V);
		auto tme = TreeMapElement(cast(ContainerStorageType!K) key);
		return cast(CET) tree.equalRange(tme).front.value;
	}

	/**
	 * Returns: the value associated with the given key, or the given `defaultValue`.
	 */
	auto get(this This)(const K key, lazy V defaultValue) inout @trusted
	{
		alias CET = ContainerElementType!(This, V);
		auto tme = TreeMapElement(key);
		auto er = tree.equalRange(tme);
		if (er.empty)
			return cast(CET) defaultValue;
		else
			return cast(CET) er.front.value;
	}

	/**
	 * If the given key does not exist in the TreeMap, adds it with
	 * the value `defaultValue`.
	 *
	 * Params:
	 *     key = the key to look up
	 *     defaultValue = the default value
	 *
	 * Returns: A pointer to the existing value, or a pointer to the inserted
	 *     value.
	 */
	auto getOrAdd(this This)(const K key, lazy V defaultValue)
	{
		alias CET = ContainerElementType!(This, V);
		auto tme = TreeMapElement(key);
		auto er = tree.equalRange(tme);
		if (er.empty)
		{
			// TODO: This does two lookups and should be made faster.
			tree.insert(TreeMapElement(key, defaultValue));
			return cast(CET*) &tree.equalRange(tme)._containersFront().value;
		}
		else
		{
			return cast(CET*) &er._containersFront().value;
		}
	}

	/**
	 * Removes the key→value mapping for the given key.
	 *
	 * Params: key = the key to remove
	 * Returns: true if the key existed in the map
	 */
	bool remove(const K key)
	{
		auto tme = TreeMapElement(cast(ContainerStorageType!K) key);
		return tree.remove(tme);
	}

	/**
	 * Returns: true if the mapping contains the given key
	 */
	bool containsKey(const K key) inout pure nothrow @nogc @trusted
	{
		auto tme = TreeMapElement(cast(ContainerStorageType!K) key);
		return tree.contains(tme);
	}

	/**
	 * Returns: true if the mapping is empty
	 */
	bool empty() const pure nothrow @property @safe @nogc
	{
		return tree.empty;
	}

	/**
	 * Returns: the number of key→value pairs in the map
	 */
	size_t length() inout pure nothrow @property @safe @nogc
	{
		return tree.length;
	}

	/**
	 * Returns: a GC-allocated array of the keys in the map
	 */
	auto keys(this This)() inout pure @property @trusted
	{
		import std.array : array;

		return byKey!(This)().array();
	}

	/**
	 * Returns: a range of the keys in the map
	 */
	auto byKey(this This)() inout pure @trusted @nogc
	{
		import std.algorithm.iteration : map;
		alias CETK = ContainerElementType!(This, K);

		return tree[].map!(a => cast(CETK) a.key);
	}

	/**
	 * Returns: a GC-allocated array of the values in the map
	 */
	auto values(this This)() inout pure @property @trusted
	{
		import std.array : array;

		return byValue!(This)().array();
	}

	/**
	 * Returns: a range of the values in the map
	 */
	auto byValue(this This)() inout pure @trusted @nogc
	{
		import std.algorithm.iteration : map;
		alias CETV = ContainerElementType!(This, V);

		return tree[].map!(a => cast(CETV) a.value);
	}

	/// ditto
	alias opSlice = byValue;

	/**
	 * Returns: a range of the kev/value pairs in this map. The element type of
	 *     this range is a struct with `key` and `value` fields.
	 */
	auto byKeyValue(this This)() inout pure @trusted
	{
		import std.algorithm.iteration : map;
		alias CETV = ContainerElementType!(This, V);

		struct KeyValue
		{
			const K key;
			CETV value;
		}

		return tree[].map!(n => KeyValue(n.key, cast(CETV) n.value));
	}

    /**
     * Returns: The value associated with the first key in the map.
     */
    auto front(this This)() inout pure @trusted
    {
        alias CETV = ContainerElementType!(This, V);

        return cast(CETV) tree.front.value;
    }

    /**
     * Returns: The value associated with the last key in the map.
     */
    auto back(this This)() inout pure @trusted
    {
        alias CETV = ContainerElementType!(This, V);

        return cast(CETV) tree.back.value;
    }

private:

	import containers.ttree : TTree;
	import containers.internal.storage_type : ContainerStorageType;
	import containers.internal.element_type : ContainerElementType;

	enum bool useGC = supportGC && (shouldAddGCRange!K || shouldAddGCRange!V);

	static struct TreeMapElement
	{
		ContainerStorageType!K key;
		ContainerStorageType!V value;
		int opCmp(ref const TreeMapElement other) const
		{
			import std.functional : binaryFun;
			return binaryFun!less(key, other.key);
		}
	}

	alias TreeType = TTree!(TreeMapElement, Allocator, false, "a.opCmp(b) > 0", useGC, cacheLineSize);
	TreeType tree;
}

version(emsi_containers_unittest) @system unittest
{
	TreeMap!(string, string) tm;
	tm["test1"] = "hello";
	tm["test2"] = "world";
	assert(tm.get("test1", "something") == "hello");
	tm.remove("test1");
	tm.remove("test2");
	assert(tm.length == 0);
	assert(tm.empty);
	assert(tm.get("test4", "something") == "something");
	assert(tm.get("test4", "something") == "something");
}

version(emsi_containers_unittest) unittest
{
	import std.range.primitives : walkLength;
	import std.stdio : stdout;
	import std.experimental.allocator.building_blocks.allocator_list : AllocatorList;
	import std.experimental.allocator.building_blocks.free_list : FreeList;
	import std.experimental.allocator.building_blocks.region : Region;
	import std.experimental.allocator.building_blocks.stats_collector : StatsCollector;

	StatsCollector!(FreeList!(AllocatorList!(a => Region!(Mallocator)(1024 * 1024)),
		64)) allocator;
	{
		auto intMap = TreeMap!(int, int, typeof(&allocator))(&allocator);
		foreach (i; 0 .. 10_000)
			intMap[i] = 10_000 - i;
		assert(intMap.length == 10_000);
	}
	assert(allocator.numAllocate == allocator.numDeallocate);
	assert(allocator.bytesUsed == 0);
}

version(emsi_containers_unittest) unittest
{
	import std.algorithm.comparison : equal;
	import std.algorithm.iteration : each;
	import std.range : repeat, take;

	TreeMap!(int, int) tm;
	int[] a = [1, 2, 3, 4, 5];
	a.each!(a => tm[a] = 0);
	assert(equal(tm.keys, a));
	assert(equal(tm.values, repeat(0).take(a.length)));
}

version(emsi_containers_unittest) unittest
{
	static class Foo
	{
		string name;
	}

	TreeMap!(string, Foo) tm;
	auto f = new Foo;
	tm["foo"] = f;
}


version(emsi_containers_unittest) unittest
{
	import std.uuid : randomUUID;
	import std.range.primitives : walkLength;

	auto hm = TreeMap!(string, int)();
	assert (hm.length == 0);
	assert (!hm.remove("abc"));
	hm["answer"] = 42;
	assert (hm.length == 1);
	assert (hm.containsKey("answer"));
	hm.remove("answer");
	assert (hm.length == 0);
	hm["one"] = 1;
	hm["one"] = 1;
	assert (hm.length == 1);
	assert (hm["one"] == 1);
	hm["one"] = 2;
	assert(hm["one"] == 2);
	foreach (i; 0 .. 1000)
	{
		hm[randomUUID().toString] = i;
	}
	assert (hm.length == 1001);
	assert (hm.keys().length == hm.length);
	assert (hm.values().length == hm.length);
	() @nogc {
		assert (hm.byKey().walkLength == hm.length);
		assert (hm.byValue().walkLength == hm.length);
		assert (hm[].walkLength == hm.length);
		assert (hm.byKeyValue().walkLength == hm.length);
	}();
	foreach (v; hm) {}

	auto hm2 = TreeMap!(char, char)();
	hm2['a'] = 'a';

	TreeMap!(int, int) hm3;
	assert (hm3.get(100, 20) == 20);
	hm3[100] = 1;
	assert (hm3.get(100, 20) == 1);
	auto pValue = hm3.containsKey(100);
	assert(pValue == 1);
}

version(emsi_containers_unittest) unittest
{
	static class Foo
	{
		string name;
	}

	void someFunc(const scope ref TreeMap!(string,Foo) map) @safe
	{
		foreach (kv; map.byKeyValue())
		{
			assert (kv.key == "foo");
			assert (kv.value.name == "Foo");
		}
	}

	auto hm = TreeMap!(string, Foo)();
	auto f = new Foo;
	f.name = "Foo";
	hm.insert("foo", f);
	assert(hm.containsKey("foo"));
}

// Issue #54
version(emsi_containers_unittest) unittest
{
	TreeMap!(string, int) map;
	map.insert("foo", 0);
	map.insert("bar", 0);

	foreach (key; map.keys())
		map[key] = 1;
	foreach (key; map.byKey())
		map[key] = 1;

	foreach (value; map.byValue())
		assert(value == 1);
	foreach (value; map.values())
		assert(value == 1);
}

version(emsi_containers_unittest) unittest
{
	TreeMap!(int, int) map;
	auto p = map.getOrAdd(1, 1);
	assert(*p == 1);
}

version(emsi_containers_unittest) unittest
{
	import std.uuid : randomUUID;
	import std.range.primitives : walkLength;
	//import std.stdio;

	auto hm = TreeMap!(string, int)();
	foreach (i; 0 .. 1_000_000)
	{
		auto str = randomUUID().toString;
		//writeln("Inserting ", str);
		hm[str] = i;
		//if (i > 0 && i % 100 == 0)
			//writeln(i);
	}
	//writeln(hm.buckets.length);

	import std.algorithm.sorting:sort;
	//ulong[ulong] counts;
	//foreach (i, ref bucket; hm.buckets[])
		//counts[bucket.length]++;
	//foreach (k; counts.keys.sort())
		//writeln(k, "=>", counts[k]);
}
