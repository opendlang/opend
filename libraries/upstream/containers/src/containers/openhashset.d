/**
 * Open-Addressed Hash Set
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module containers.openhashset;

private import containers.internal.hash;
private import containers.internal.node : shouldAddGCRange;
private import std.experimental.allocator.common : stateSize;
private import std.experimental.allocator.mallocator : Mallocator;

/**
 * Simple open-addressed hash set that uses linear probing to resolve sollisions.
 *
 * Params:
 *     T = the element type of the hash set
 *     Allocator = the allocator to use. Defaults to `Mallocator`.
 *     hashFunction = the hash function to use
 *     supportGC = if true, calls to GC.addRange and GC.removeRange will be used
 *         to ensure that the GC does not accidentally free memory owned by this
 *         container.
 */
struct OpenHashSet(T, Allocator = Mallocator,
	alias hashFunction = generateHash!T, bool supportGC = shouldAddGCRange!T)
{
	/**
	 * Disallow copy construction
	 */
	this(this) @disable;

	static if (stateSize!Allocator != 0)
	{
		this() @disable;

		/**
		 * Use the given `allocator` for allocations.
		 */
		this(Allocator allocator)
		in
		{
			static if (is(typeof(allocator is null)))
				assert(allocator !is null, "Allocator must not be null");
		}
		do
		{
			this.allocator = allocator;
		}

		/**
		 * Initializes the hash set with the given initial capacity.
		 *
		 * Params:
		 *     initialCapacity = the initial capacity for the hash set
		 *     allocator = allocator to use for allocations
		 */
		this(size_t initialCapacity, Allocator allocator)
		in
		{
			static if (is(typeof(allocator is null)))
				assert(allocator !is null, "Allocator must not be null");
			assert ((initialCapacity & initialCapacity - 1) == 0, "initialCapacity must be a power of 2");
		}
		do
		{
			this.allocator = allocator;
			initialize(initialCapacity);
		}
	}
	else
	{
		/**
		 * Initializes the hash set with the given initial capacity.
		 *
		 * Params:
		 *     initialCapacity = the initial capacity for the hash set
		 */
		this(size_t initialCapacity)
		in
		{
			assert ((initialCapacity & initialCapacity - 1) == 0, "initialCapacity must be a power of 2");
		}
		do
		{
			initialize(initialCapacity);
		}
	}

	~this() nothrow
	{
		static if (useGC)
			GC.removeRange(nodes.ptr);
		allocator.deallocate(nodes);
	}

	/**
	 * Removes all items from the hash set.
	 */
	void clear()
	{
		if (empty)
			return;
		foreach (ref node; nodes)
		{
			typeid(typeof(node)).destroy(&node);
			node.used = false;
		}
		_length = 0;
	}

	///
	bool empty() const pure nothrow @nogc @safe @property
	{
		return _length == 0;
	}

	///
	size_t length() const pure nothrow @nogc @safe @property
	{
		return _length;
	}

	/**
	 * Returns:
	 *     $(B true) if the hash set contains the given item, false otherwise.
	 */
	bool contains(T item) const
	{
		if (empty)
			return false;
		immutable size_t hash = hashFunction(item);
		size_t index = toIndex(nodes, item, hash);
		if (index == size_t.max)
			return false;
		return nodes[index].hash == hash && nodes[index].data == item;
	}

	/// ditto
	bool opBinaryRight(string op)(T item) inout if (op == "in")
	{
		return contains(item);
	}

	/**
	 * Inserts the given item into the set.
	 *
	 * Returns:
	 *     $(B true) if the item was inserted, false if it was already present.
	 */
	bool insert(T item)
	{
		if (nodes.length == 0)
			initialize(DEFAULT_BUCKET_COUNT);
		immutable size_t hash = hashFunction(item);
		size_t index = toIndex(nodes, item, hash);
		if (index == size_t.max)
		{
			grow();
			index = toIndex(nodes, item, hash);
		}
		else if (nodes[index].used && nodes[index].hash == hash && nodes[index].data == item)
			return false;
		nodes[index].used = true;
		nodes[index].hash = hash;
		nodes[index].data = item;
		_length++;
		return true;
	}

	/// ditto
	alias put = insert;

	/// ditto
	alias insertAnywhere = insert;

	/// ditto
	bool opOpAssign(string op)(T item) if (op == "~")
	{
		return insert(item);
	}

	/**
	 * Params:
	 *     item = the item to remove
	 * Returns:
	 *     $(B true) if the item was removed, $(B false) if it was not present
	 */
	bool remove(T item)
	{
		if (empty)
			return false;
		immutable size_t hash = hashFunction(item);
		size_t index = toIndex(nodes, item, hash);
		if (index == size_t.max)
			return false;
		nodes[index].used = false;
		destroy(nodes[index].data);
		_length--;
		return true;
	}

	/**
	 * Returns:
	 *     A range over the set.
	 */
	auto opSlice(this This)() nothrow pure @nogc @safe
	{
		return Range!(This)(nodes);
	}

	mixin AllocatorState!Allocator;

private:

	import containers.internal.element_type : ContainerElementType;
	import containers.internal.mixins : AllocatorState;
	import containers.internal.storage_type : ContainerStorageType;
	import core.memory : GC;

	enum bool useGC = supportGC && shouldAddGCRange!T;

	static struct Range(ThisT)
	{
		ET front()
		{
			return cast(typeof(return)) nodes[index].data;
		}

		bool empty() const pure nothrow @safe @nogc @property
		{
			return index >= nodes.length;
		}

		void popFront() pure nothrow @safe @nogc
		{
			index++;
			while (index < nodes.length && !nodes[index].used)
				index++;
		}

	private:

		alias ET = ContainerElementType!(ThisT, T);

		this(const Node[] nodes)
		{
			this.nodes = nodes;
			while (true)
			{
				if (index >= nodes.length || nodes[index].used)
					break;
				index++;
			}
		}

		size_t index;
		const Node[] nodes;
	}

	void grow()
	{
		immutable size_t newCapacity = nodes.length << 1;
		Node[] newNodes = (cast (Node*) allocator.allocate(newCapacity * Node.sizeof))
			[0 .. newCapacity];
		newNodes[] = Node.init;
		static if (useGC)
			GC.addRange(newNodes.ptr, newNodes.length * Node.sizeof, typeid(typeof(nodes)));
		foreach (ref node; nodes)
		{
			immutable size_t newIndex = toIndex(newNodes, node.data, node.hash);
			newNodes[newIndex] = node;
		}
		static if (useGC)
			GC.removeRange(nodes.ptr);
		allocator.deallocate(nodes);
		nodes = newNodes;
	}

	void initialize(size_t nodeCount)
	{
		nodes = (cast (Node*) allocator.allocate(nodeCount * Node.sizeof))[0 .. nodeCount];
		static if (useGC)
			GC.addRange(nodes.ptr, nodes.length * Node.sizeof, typeid(typeof(nodes)));
        nodes[] = Node.init;
		_length = 0;
	}

	// Returns: size_t.max if the item was not found
	static size_t toIndex(const Node[] n, T item, size_t hash)
	{
		assert (n.length > 0, "Empty node");
		immutable size_t index = hashToIndex(hash, n.length);
		size_t i = index;
		immutable bucketMask = n.length - 1;
		while (n[i].used && n[i].data != item)
		{
			i = (i + 1) & bucketMask;
			if (i == index)
				return size_t.max;
		}
		return i;
	}

	Node[] nodes;
	size_t _length;

	static struct Node
	{
		ContainerStorageType!T data;
		bool used;
		size_t hash;
	}
}

version(emsi_containers_unittest) unittest
{
	import std.string : format;
	import std.algorithm : equal, sort;
	import std.range : iota;
	import std.array : array;
	OpenHashSet!int ints;
	assert (ints.empty);
	assert (equal(ints[], cast(int[]) []));
	ints.clear();
	ints.insert(10);
	assert (!ints.empty);
	assert (ints.length == 1);
	assert (equal(ints[], [10]));
	assert (ints.contains(10));
	ints.clear();
	assert (ints.length == 0);
	assert (ints.empty);
	ints ~= 0;
	assert (!ints.empty);
	assert (ints.length == 1);
	assert (equal(ints[], [0]));
	ints.clear();
	assert (ints.length == 0);
	assert (ints.empty);
	foreach (i; 0 .. 100)
		ints ~= i;
	assert (ints.length == 100, "%d".format(ints.length));
	assert (!ints.empty);
	foreach (i; 0 .. 100)
		assert (i in ints);
	assert (equal(ints[].array().sort(), iota(0, 100)));
	assert (ints.insert(10) == false);
	auto ohs = OpenHashSet!int(8);
	assert (!ohs.remove(1000));
	assert (ohs.contains(99) == false);
	assert (ohs.insert(10) == true);
	assert (ohs.insert(10) == false);
	foreach (i; 0 .. 7)
		ohs.insert(i);
	assert (ohs.contains(6));
	assert (!ohs.contains(100));
	assert (!ohs.remove(9999));
	assert (ohs.remove(0));
	assert (ohs.remove(1));
}

version(emsi_containers_unittest) unittest
{
	static class Foo
	{
		string name;

		override bool opEquals(Object other) const @safe pure nothrow @nogc
		{
			Foo f = cast(Foo)other;
			return f !is null && f.name == this.name;
		}
	}

	hash_t stringToHash(string str) @safe pure nothrow @nogc
	{
		hash_t hash = 5381;
		return hash;
	}

	hash_t FooToHash(Foo e) pure @safe nothrow @nogc
	{
		return stringToHash(e.name);
	}

	OpenHashSet!(Foo, Mallocator, FooToHash) hs;
	auto f = new Foo;
	hs.insert(f);
	assert(f in hs);
	auto r = hs[];
}
