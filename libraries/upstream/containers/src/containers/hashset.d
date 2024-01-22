/**
 * Hash Set
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */

module containers.hashset;

private import containers.internal.hash : generateHash, hashToIndex;
private import containers.internal.node : shouldAddGCRange;
private import std.experimental.allocator.mallocator : Mallocator;
private import std.traits : isBasicType;

/**
 * Hash Set.
 * Params:
 *     T = the element type
 *     Allocator = the allocator to use. Defaults to `Mallocator`.
 *     hashFunction = the hash function to use on the elements
 *     supportGC = true if the container should support holding references to
 *         GC-allocated memory.
 */
struct HashSet(T, Allocator = Mallocator, alias hashFunction = generateHash!T,
	bool supportGC = shouldAddGCRange!T,
	bool storeHash = !isBasicType!T)
{
	this(this) @disable;

	private import std.experimental.allocator.common : stateSize;

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
		 * Constructs a HashSet with an initial bucket count of bucketCount.
		 * bucketCount must be a power of two.
		 */
		this(size_t bucketCount, Allocator allocator)
		in
		{
			static if (is(typeof(allocator is null)))
				assert(allocator !is null, "Allocator must not be null");
			assert ((bucketCount & (bucketCount - 1)) == 0, "bucketCount must be a power of two");
		}
		do
		{
			this.allocator = allocator;
			initialize(bucketCount);
		}
	}
	else
	{
		/**
		 * Constructs a HashSet with an initial bucket count of bucketCount.
		 * bucketCount must be a power of two.
		 */
		this(size_t bucketCount)
		in
		{
			assert ((bucketCount & (bucketCount - 1)) == 0, "bucketCount must be a power of two");
		}
		do
		{
			initialize(bucketCount);
		}

	}

	~this()
	{
		import std.experimental.allocator : dispose;
		import core.memory : GC;
		static if (useGC)
			GC.removeRange(buckets.ptr);
		allocator.dispose(buckets);
	}

	/**
	 * Removes all items from the set
	 */
	void clear()
	{
		foreach (ref bucket; buckets)
		{
			destroy(bucket);
			bucket = Bucket.init;
		}
		_length = 0;
	}

	/**
	 * Removes the given item from the set.
	 * Returns: false if the value was not present
	 */
	bool remove(T value)
	{
		if (buckets.length == 0)
			return false;
		immutable Hash hash = hashFunction(value);
		immutable size_t index = hashToIndex(hash, buckets.length);
		static if (storeHash)
			immutable bool removed = buckets[index].remove(ItemNode(hash, value));
		else
			immutable bool removed = buckets[index].remove(ItemNode(value));
		if (removed)
			--_length;
		return removed;
	}

	/**
	 * Returns: true if value is contained in the set.
	 */
	bool contains(T value) inout
	{
		return (value in this) !is null;
	}

	/**
	 * Supports $(B a in b) syntax
	 */
	inout(T)* opBinaryRight(string op)(T value) inout if (op == "in")
	{
		if (buckets.length == 0 || _length == 0)
			return null;
		immutable Hash hash = hashFunction(value);
		immutable index = hashToIndex(hash, buckets.length);
		return buckets[index].get(value, hash);
	}

	/**
	 * Inserts the given item into the set.
	 * Params: value = the value to insert
	 * Returns: true if the value was actually inserted, or false if it was
	 *     already present.
	 */
	bool insert(T value)
	{
		if (buckets.length == 0)
			initialize(4);
		Hash hash = hashFunction(value);
		immutable size_t index = hashToIndex(hash, buckets.length);
		static if (storeHash)
			auto r = buckets[index].insert(ItemNode(hash, value));
		else
			auto r = buckets[index].insert(ItemNode(value));
		if (r)
			++_length;
		if (shouldRehash)
			rehash();
		return r;
	}

	/// ditto
	bool opOpAssign(string op)(T item) if (op == "~")
	{
		return insert(item);
	}

	/// ditto
	alias put = insert;

	/// ditto
	alias insertAnywhere = insert;

	/**
	 * Returns: true if the set has no items
	 */
	bool empty() const nothrow pure @nogc @safe @property
	{
		return _length == 0;
	}

	/**
	 * Returns: the number of items in the set
	 */
	size_t length() const nothrow pure @nogc @safe @property
	{
		return _length;
	}

	/**
	 * Forward range interface
	 */
	auto opSlice(this This)() nothrow @nogc @trusted
	{
		return Range!(This)(&this);
	}

private:

	import containers.internal.element_type : ContainerElementType;
	import containers.internal.mixins : AllocatorState;
	import containers.internal.node : shouldAddGCRange, FatNodeInfo;
	import containers.internal.storage_type : ContainerStorageType;
	import std.traits : isPointer;

	alias LengthType = ubyte;
	alias N = FatNodeInfo!(ItemNode.sizeof, 1, 64, LengthType.sizeof);
	enum ITEMS_PER_NODE = N[0];
	static assert(LengthType.max > ITEMS_PER_NODE);
	enum bool useGC = supportGC && shouldAddGCRange!T;
	alias Hash = typeof({ T v = void; return hashFunction(v); }());

	void initialize(size_t bucketCount)
	{
		import core.memory : GC;
		import std.experimental.allocator : makeArray;

		makeBuckets(bucketCount);
		static if (useGC)
			GC.addRange(buckets.ptr, buckets.length * Bucket.sizeof);
	}

	static struct Range(ThisT)
	{
		this(ThisT* t)
		{
			foreach (i, ref bucket; t.buckets)
			{
				bucketIndex = i;
				if (bucket.root !is null)
				{
					currentNode = cast(Bucket.BucketNode*) bucket.root;
					break;
				}
			}
			this.t = t;
		}

		bool empty() const nothrow @safe @nogc @property
		{
			return currentNode is null;
		}

		ET front() nothrow @safe @nogc @property
		{
			return cast(ET) currentNode.items[nodeIndex].value;
		}

		void popFront() nothrow @trusted @nogc
		{
			if (nodeIndex + 1 < currentNode.l)
			{
				++nodeIndex;
				return;
			}
			else
			{
				nodeIndex = 0;
				if (currentNode.next is null)
				{
					++bucketIndex;
					while (bucketIndex < t.buckets.length && t.buckets[bucketIndex].root is null)
						++bucketIndex;
					if (bucketIndex < t.buckets.length)
						currentNode = cast(Bucket.BucketNode*) t.buckets[bucketIndex].root;
					else
						currentNode = null;
				}
				else
				{
					currentNode = currentNode.next;
					assert(currentNode.l > 0, "Empty node");
				}
			}
		}

	private:
		alias ET = ContainerElementType!(ThisT, T);
		ThisT* t;
		Bucket.BucketNode* currentNode;
		size_t bucketIndex;
		size_t nodeIndex;
	}

	void makeBuckets(size_t bucketCount)
	{
		import std.experimental.allocator : makeArray;

		static if (stateSize!Allocator == 0)
			buckets = allocator.makeArray!Bucket(bucketCount);
		else
		{
			import std.conv:emplace;

			buckets = cast(Bucket[]) allocator.allocate(Bucket.sizeof * bucketCount);
			foreach (ref bucket; buckets)
				emplace!Bucket(&bucket, allocator);
		}
	}

	bool shouldRehash() const pure nothrow @safe @nogc
	{
		immutable float numberOfNodes = cast(float) _length / cast(float) ITEMS_PER_NODE;
		return (numberOfNodes / cast(float) buckets.length) > 0.75f;
	}

	void rehash() @trusted
	{
		import std.experimental.allocator : makeArray, dispose;
		import core.memory : GC;

		immutable size_t newLength = buckets.length << 1;
		Bucket[] oldBuckets = buckets;
		makeBuckets(newLength);
		assert (buckets, "Bucket reallocation failed");
		assert (buckets.length == newLength, "Bucket reallocation size mismatch");
		static if (useGC)
			GC.addRange(buckets.ptr, buckets.length * Bucket.sizeof);
		foreach (ref const bucket; oldBuckets)
		{
			for (Bucket.BucketNode* node = cast(Bucket.BucketNode*) bucket.root; node !is null; node = node.next)
			{
				for (size_t i = 0; i < node.l; ++i)
				{
					static if (storeHash)
					{
						immutable Hash hash = node.items[i].hash;
						size_t index = hashToIndex(hash, buckets.length);
						buckets[index].insert(ItemNode(hash, node.items[i].value));
					}
					else
					{
						immutable Hash hash = hashFunction(node.items[i].value);
						size_t index = hashToIndex(hash, buckets.length);
						buckets[index].insert(ItemNode(node.items[i].value));
					}
				}
			}
		}
		static if (useGC)
			GC.removeRange(oldBuckets.ptr);
		allocator.dispose(oldBuckets);
	}

	static struct Bucket
	{
		this(this) @disable;

		static if (stateSize!Allocator != 0)
		{
			this(Allocator allocator)
			{
				this.allocator = allocator;
			}
			this() @disable;
		}

		~this()
		{
			import core.memory : GC;
			import std.experimental.allocator : dispose;

			BucketNode* current = root;
			BucketNode* previous;
			while (true)
			{
				if (previous !is null)
				{
					static if (useGC)
						GC.removeRange(previous);
					allocator.dispose(previous);
				}
				previous = current;
				if (current is null)
					break;
				current = current.next;
			}
		}

		static struct BucketNode
		{
			ContainerStorageType!(T)* get(ItemNode n)
			{
				foreach (ref item; items[0 .. l])
				{
					static if (storeHash)
					{
						static if (isPointer!T)
						{
							if (item.hash == n.hash && *item.value == *n.value)
								return &item.value;
						}
						else
						{
							if (item.hash == n.hash && item.value == n.value)
								return &item.value;
						}
					}
					else
					{
						static if (isPointer!T)
						{
							if (*item.value == *n.value)
								return &item.value;
						}
						else
						{
							if (item.value == n.value)
								return &item.value;
						}
					}
				}
				return null;
			}

			void insert(ItemNode n)
			{
				items[l] = n;
				++l;
			}

			bool remove(ItemNode n)
			{
				import std.algorithm : SwapStrategy, remove;

				foreach (size_t i, ref node; items[0 .. l])
				{
					static if (storeHash)
					{
						static if (isPointer!T)
							immutable bool matches = node.hash == n.hash && *node.value == *n.value;
						else
							immutable bool matches = node.hash == n.hash && node.value == n.value;
					}
					else
					{
						static if (isPointer!T)
							immutable bool matches = *node.value == *n.value;
						else
							immutable bool matches = node.value == n.value;
					}
					if (matches)
					{
						items[0 .. l].remove!(SwapStrategy.unstable)(i);
						l--;
						return true;
					}
				}
				return false;
			}

			BucketNode* next;
			LengthType l;
			ItemNode[ITEMS_PER_NODE] items;
		}

		bool insert(ItemNode n)
		{
			import core.memory : GC;
			import std.experimental.allocator : make;

			BucketNode* hasSpace = null;
			for (BucketNode* current = root; current !is null; current = current.next)
			{
				if (current.get(n) !is null)
					return false;
				if (current.l < current.items.length)
					hasSpace = current;
			}
			if (hasSpace !is null)
				hasSpace.insert(n);
			else
			{
				BucketNode* newNode = make!BucketNode(allocator);
				static if (useGC)
					GC.addRange(newNode, BucketNode.sizeof);
				newNode.insert(n);
				newNode.next = root;
				root = newNode;
			}
			return true;
		}

		bool remove(ItemNode n)
		{
			import core.memory : GC;
			import std.experimental.allocator : dispose;

			BucketNode* current = root;
			BucketNode* previous;
			while (current !is null)
			{
				immutable removed = current.remove(n);
				if (removed)
				{
					if (current.l == 0)
					{
						if (previous !is null)
							previous.next = current.next;
						else
							root = current.next;
						static if (useGC)
							GC.removeRange(current);
						allocator.dispose(current);
					}
					return true;
				}
				previous = current;
				current = current.next;
			}
			return false;
		}

		inout(T)* get(T value, Hash hash) inout
		{
			for (BucketNode* current = cast(BucketNode*) root; current !is null; current = current.next)
			{
				static if (storeHash)
				{
					auto v = current.get(ItemNode(hash, value));
				}
				else
				{
					auto v = current.get(ItemNode(value));
				}

				if (v !is null)
					return cast(typeof(return)) v;
			}
			return null;
		}

		BucketNode* root;
		mixin AllocatorState!Allocator;
	}

	static struct ItemNode
	{
		bool opEquals(ref const T v) const
		{
			static if (isPointer!T)
				return *v == *value;
			else
				return v == value;
		}

		bool opEquals(ref const ItemNode other) const
		{
			static if (storeHash)
				if (other.hash != hash)
					return false;
			static if (isPointer!T)
				return *other.value == *value;
			else
				return other.value == value;
		}

		static if (storeHash)
			Hash hash;
		ContainerStorageType!T value;

		static if (storeHash)
		{
			this(Z)(Hash nh, Z nv)
			{
				this.hash = nh;
				this.value = nv;
			}
		}
		else
		{
			this(Z)(Z nv)
			{
				this.value = nv;
			}
		}
	}

	mixin AllocatorState!Allocator;
	Bucket[] buckets;
	size_t _length;
}

///
version(emsi_containers_unittest) unittest
{
	import std.algorithm : canFind;
	import std.array : array;
	import std.range : walkLength;
	import std.uuid : randomUUID;

	auto s = HashSet!string(16);
	assert(s.remove("DoesNotExist") == false);
	assert(!s.contains("nonsense"));
	assert(s.put("test"));
	assert(s.contains("test"));
	assert(!s.put("test"));
	assert(s.contains("test"));
	assert(s.length == 1);
	assert(!s.contains("nothere"));
	s.put("a");
	s.put("b");
	s.put("c");
	s.put("d");
	string[] strings = s[].array;
	assert(strings.canFind("a"));
	assert(strings.canFind("b"));
	assert(strings.canFind("c"));
	assert(strings.canFind("d"));
	assert(strings.canFind("test"));
	assert(*("a" in s) == "a");
	assert(*("b" in s) == "b");
	assert(*("c" in s) == "c");
	assert(*("d" in s) == "d");
	assert(*("test" in s) == "test");
	assert(strings.length == 5);
	assert(s.remove("test"));
	assert(s.length == 4);
	s.clear();
	assert(s.length == 0);
	assert(s.empty);
	s.put("abcde");
	assert(s.length == 1);
	foreach (i; 0 .. 10_000)
	{
		s.put(randomUUID().toString);
	}
	assert(s.length == 10_001);

	// Make sure that there's no range violation slicing an empty set
	HashSet!int e;
	foreach (i; e[])
		assert(i > 0);

	enum MAGICAL_NUMBER = 600_000;

	HashSet!int f;
	foreach (i; 0 .. MAGICAL_NUMBER)
		assert(f.insert(i));
	assert(f.length == f[].walkLength);
	foreach (i; 0 .. MAGICAL_NUMBER)
		assert(i in f);
	foreach (i; 0 .. MAGICAL_NUMBER)
		assert(f.remove(i));
	foreach (i; 0 .. MAGICAL_NUMBER)
		assert(!f.remove(i));

	HashSet!int g;
	foreach (i; 0 .. MAGICAL_NUMBER)
		assert(g.insert(i));

	static struct AStruct
	{
		int a;
		int b;
	}

	HashSet!(AStruct*, Mallocator, a => a.a) fred;
	fred.insert(new AStruct(10, 10));
	auto h = new AStruct(10, 10);
	assert(h in fred);
}

version(emsi_containers_unittest) unittest
{
	static class Foo
	{
		string name;
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

	HashSet!(Foo, Mallocator, FooToHash) hs;
	auto f = new Foo;
	hs.insert(f);
	assert(f in hs);
	auto r = hs[];
}

version(emsi_containers_unittest) unittest
{
	static class Foo
	{
		string name;
		this(string n) { this.name = n; }
		bool opEquals(const Foo of) const {
			if(of !is null) { return this.name == of.name; }
			else { return false; }
		}
	}

	hash_t stringToHash(string str) @safe pure nothrow @nogc
	{
		hash_t hash = 5381;
		return hash;
	}

	hash_t FooToHash(in Foo e) pure @safe nothrow @nogc
	{
		return stringToHash(e.name);
	}

	string foo = "foo";
	HashSet!(const(Foo), Mallocator, FooToHash) hs;
	const(Foo) f = new const Foo(foo);
	hs.insert(f);
	assert(f in hs);
	auto r = hs[];
	assert(!r.empty);
	auto fro = r.front;
	assert(fro.name == foo);
}

version(emsi_containers_unittest) unittest
{
	hash_t maxCollision(ulong x)
	{
		return 0;
	}

	HashSet!(ulong, Mallocator, maxCollision) set;
	auto ipn = set.ITEMS_PER_NODE; // Need this info to trigger this bug, so I made it public
	assert(ipn > 1); // Won't be able to trigger this bug if there's only 1 item per node

	foreach (i; 0 .. 2 * ipn - 1)
		set.insert(i);

	assert(0 in set); // OK
	bool ret = set.insert(0); // 0 should be already in the set
	assert(!ret); // Fails
	assert(set.length == 2 * ipn - 1); // Fails
}

version(emsi_containers_unittest) unittest
{
	import std.experimental.allocator.showcase;
	auto allocator = mmapRegionList(1024);
	auto set = HashSet!(ulong, typeof(&allocator))(0x1000, &allocator);
	set.insert(124);
}
