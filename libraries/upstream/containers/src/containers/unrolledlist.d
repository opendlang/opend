/**
 * Unrolled Linked List.
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */

module containers.unrolledlist;

private import core.lifetime : move;
private import containers.internal.node : shouldAddGCRange;
private import std.experimental.allocator.mallocator : Mallocator;

version (X86_64)
	version (LDC)
		version = LDC_64;

/**
 * Unrolled Linked List.
 *
 * Nodes are (by default) sized to fit within a 64-byte cache line. The number
 * of items stored per node can be read from the $(B nodeCapacity) field.
 * See_also: $(LINK http://en.wikipedia.org/wiki/Unrolled_linked_list)
 * Params:
 *     T = the element type
 *     Allocator = the allocator to use. Defaults to `Mallocator`.
 *     supportGC = true to ensure that the GC scans the nodes of the unrolled
 *         list, false if you are sure that no references to GC-managed memory
 *         will be stored in this container.
 *     cacheLineSize = Nodes will be sized to fit within this number of bytes.
 */
struct UnrolledList(T, Allocator = Mallocator,
	bool supportGC = shouldAddGCRange!T, size_t cacheLineSize = 64)
{
	this(this) @disable;

	private import std.experimental.allocator.common : stateSize;

	static if (stateSize!Allocator != 0)
	{
		/// No default construction if an allocator must be provided.
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
	}

	~this() nothrow
	{
		scope (failure) assert(false, "UnrolledList destructor threw an exception");
		clear();
	}

	/**
	 * Removes all items from the list
	 */
	void clear()
	{
		Node* previous;
		Node* current = _front;
		while (current !is null)
		{
			previous = current;
			current = current.next;

			static if (useGC)
			{
				import core.memory: GC;
				GC.removeRange(previous);
			}
			allocator.dispose(previous);
		}
		_length = 0;
		_front = null;
		_back = null;
	}

	/**
	 * Inserts the given item into the end of the list.
	 *
	 * Returns: a pointer to the inserted item.
	 */
	T* insertBack(T item)
	{
		ContainerStorageType!T* result;
		if (_back is null)
		{
			assert (_front is null, "front/back nullness mismatch");
			_back = allocateNode(move(mutable(item)));
			_front = _back;
			result = &_back.items[0];
		}
		else
		{
			size_t index = _back.nextAvailableIndex();
			if (index >= nodeCapacity)
			{
				Node* n = allocateNode(move(mutable(item)));
				n.prev = _back;
				_back.next = n;
				_back = n;
				index = 0;
				result = &n.items[0];
			}
			else
			{
				_back.items[index] = move(mutable(item));
				_back.markUsed(index);
				result = &_back.items[index];
			}
		}
		_length++;
		assert (_back.registry <= fullBitPattern, "Overflow");
		return cast(T*) result;
	}

	/**
	 * Inserts the given range into the end of the list
	 */
	void insertBack(R)(auto ref R range)
	{
		foreach (ref r; range)
			insertBack(r);
	}

	/// ditto
	T* opOpAssign(string op)(T item) if (op == "~")
	{
		return insertBack(item);
	}

	/// ditto
	alias put = insertBack;

	/// ditto
	alias insert = insertBack;

	/**
	 * Inserts the given item in the frontmost available cell, which may put the
	 * item anywhere in the list as removal may leave gaps in list nodes. Use
	 * this only if the order of elements is not important.
	 *
	 * Returns: a pointer to the inserted item.
	 */
	T* insertAnywhere(T item) @trusted
	{
		Node* n = _front;
		while (n !is null)
		{
			size_t i = n.nextAvailableIndex();
			if (i >= nodeCapacity)
			{
				if (n.next is null)
				{
					assert (n is _back, "Wrong _back");
					break;
				}
				n = n.next;
				continue;
			}
			n.items[i] = move(mutable(item));
			n.markUsed(i);
			_length++;
			assert (n.registry <= fullBitPattern, "Overflow");
			return cast(T*) &n.items[i];
		}
		n = allocateNode(move(mutable(item)));
		_length++;
		auto retVal = cast(T*) &n.items[0];
		if (_front is null)
		{
			assert(_back is null, "front/back nullness mismatch");
			_front = n;
		}
		else
		{
			n.prev = _back;
			_back.next = n;
		}
		_back = n;
		assert (_back.registry <= fullBitPattern, "Overflow");
		return retVal;
	}

	/// Returns: the length of the list
	size_t length() const nothrow pure @property @safe @nogc
	{
		return _length;
	}

	/// Returns: true if the list is empty
	bool empty() const nothrow pure @property @safe @nogc
	{
		return _length == 0;
	}

	/**
	 * Removes the first instance of the given item from the list.
	 *
	 * Returns: true if something was removed.
	 */
	bool remove(ref const T item)
	{
		if (_front is null)
			return false;
		bool retVal;
		loop: for (Node* n = _front; n !is null; n = n.next)
		{
			foreach (i; 0 .. nodeCapacity)
			{
				if (!n.isFree(i) && n.items[i] == item)
				{
					n.markUnused(i);
					--_length;
					retVal = true;
					if (n.registry == 0)
						deallocateNode(n);
					else if (shouldMerge(n, n.next))
						mergeNodes(n, n.next);
					else if (shouldMerge(n.prev, n))
						mergeNodes(n.prev, n);
					break loop;
				}
			}
		}
		return retVal;
	}
	bool remove(const T item) { return remove(item); }

	/// Pops the front item off of the list
	void popFront()
	{
		moveFront();
		assert (_front is null || _front.registry != 0, "Node is non-null but empty");
	}

	/// Pops the front item off of the list and returns it
	T moveFront()
	in
	{
		assert (!empty(), "Accessing .moveFront of empty UnrolledList");
		assert (_front.registry != 0, "Empty node");
	}
	do
	{
		version (LDC_64)
		{
			import ldc.intrinsics : llvm_cttz;
			size_t index = llvm_cttz(_front.registry, true);
		}
		else
		{
			import containers.internal.backwards : bsf;
			size_t index = bsf(_front.registry);
		}
		T r = move(_front.items[index]);
		_front.markUnused(index);
		_length--;
		if (_front.registry == 0)
		{
			auto f = _front;
			if (_front.next !is null)
				_front.next.prev = null;
			assert (_front.next !is _front, "Infinite loop");
			_front = _front.next;
			if (_front is null)
				_back = null;
			else
				assert (_front.registry <= fullBitPattern, "Overflow");
			deallocateNode(f);
			return r;
		}
		if (shouldMerge(_front, _front.next))
			mergeNodes(_front, _front.next);
		return r;
	}

	debug (EMSI_CONTAINERS) invariant
	{
		import std.string: format;
		assert (_front is null || _front.registry != 0, format("%x, %b", _front, _front.registry));
		assert (_front !is null || _back is null, "_front/_back nullness mismatch");
		if (_front !is null)
		{
			const(Node)* c = _front;
			while (c.next !is null)
				c = c.next;
			assert(c is _back, "_back pointer is wrong");
		}
	}

	/**
	 * Time complexity is O(1)
	 * Returns: the item at the front of the list
	 */
	ref inout(T) front() inout nothrow @property
	in
	{
		assert (!empty, "Accessing .front of empty UnrolledList");
		assert (_front.registry != 0, "Empty node");
	}
	do
	{
		version (LDC_64)
		{
			import ldc.intrinsics : llvm_cttz;
			immutable index = llvm_cttz(_front.registry, true);
		}
		else
		{
			import containers.internal.backwards : bsf;
			immutable index = bsf(_front.registry);
		}
		return *(cast(typeof(return)*) &_front.items[index]);
	}

	/**
	 * Time complexity is O(nodeCapacity), where the nodeCapacity
	 * is the number of items in a single list node. It is a constant
	 * related to the cache line size.
	 * Returns: the item at the back of the list
	 */
	ref inout(T) back() inout nothrow @property
	in
	{
		assert (!empty, "Accessing .back of empty UnrolledList");
		assert (!_back.empty, "Empty node");
	}
	do
	{
		size_t i = nodeCapacity - 1;
		while (_back.isFree(i))
			i--;
		return *(cast(typeof(return)*) &_back.items[i]);
	}

	/// Pops the back item off of the list.
	void popBack()
	{
		moveBack();
	}

	/// Removes an item from the back of the list and returns it.
	T moveBack()
	in
	{
		assert (!empty, "Accessing .moveBack of empty UnrolledList");
		assert (!_back.empty, "Empty node");
	}
	do
	{
		size_t i = nodeCapacity - 1;
		while (_back.isFree(i))
		{
			if (i == 0)
				break;
			else
				i--;
		}
		assert (!_back.isFree(i), "Empty node");
		T item = move(_back.items[i]);
		_back.markUnused(i);
		_length--;
		if (_back.registry == 0)
		{
			deallocateNode(_back);
			return item;
		}
		else if (shouldMerge(_back.prev, _back))
			mergeNodes(_back.prev, _back);
		return item;
	}

	/// Returns: a range over the list
	auto opSlice(this This)() const nothrow pure @nogc @trusted
	{
		return Range!(This)(_front);
	}

	static struct Range(ThisT)
	{
		@disable this();

		this(inout(Node)* current)
		{
			import std.format:format;

			this.current = current;
			if (current !is null)
			{
				version(LDC_64)
				{
					import ldc.intrinsics : llvm_cttz;
					index = llvm_cttz(current.registry, true);
				}
				else
				{
					import containers.internal.backwards : bsf;
					index = bsf(current.registry);
				}

				assert (index < nodeCapacity);
			}
			else
				current = null;
		}

		ref ET front() const nothrow @property @trusted @nogc
		{
			return *(cast(ET*) &current.items[index]);
			//return cast(T) current.items[index];
		}

		void popFront() nothrow pure @safe @nogc
		{
			index++;
			while (true)
			{

				if (index >= nodeCapacity)
				{
					current = current.next;
					if (current is null)
						return;
					index = 0;
				}
				else
				{
					if (current.isFree(index))
						index++;
					else
						return;
				}
			}
		}

		bool empty() const nothrow pure @property @safe @nogc
		{
			return current is null;
		}

		Range save() const nothrow pure @property @safe @nogc
		{
			return this;
		}

	private:

		alias ET = ContainerElementType!(ThisT, T);
		const(Node)* current;
		size_t index;
	}

private:

	import std.experimental.allocator: make, dispose;
	import containers.internal.node : FatNodeInfo, shouldAddGCRange,
		fullBits, shouldNullSlot;
	import containers.internal.storage_type : ContainerStorageType;
	import containers.internal.element_type : ContainerElementType;
	import containers.internal.mixins : AllocatorState;

	alias N = FatNodeInfo!(T.sizeof, 2, cacheLineSize);
	enum size_t nodeCapacity = N[0];
	alias BookkeepingType = N[1];
	enum fullBitPattern = fullBits!(BookkeepingType, nodeCapacity);
	enum bool useGC = supportGC && shouldAddGCRange!T;

	static ref ContainerStorageType!T mutable(ref T value) { return *cast(ContainerStorageType!T*)&value; }

	Node* _back;
	Node* _front;
	size_t _length;
	mixin AllocatorState!Allocator;

	Node* allocateNode(T item)
	{
		Node* n = make!Node(allocator);
		static if (useGC)
		{
			import core.memory: GC;
			GC.addRange(n, Node.sizeof);
		}
		n.items[0] = move(mutable(item));
		n.markUsed(0);
		return n;
	}

	void deallocateNode(Node* n)
	{
		if (n.prev !is null)
			n.prev.next = n.next;
		if (n.next !is null)
			n.next.prev = n.prev;
		if (_front is n)
			_front = n.next;
		if (_back is n)
			_back = n.prev;

		static if (useGC)
		{
			import core.memory: GC;
			GC.removeRange(n);
		}
		allocator.dispose(n);
	}

	static bool shouldMerge(const Node* first, const Node* second)
	{
		if (first is null || second is null)
			return false;
		version (LDC_64)
		{
			import ldc.intrinsics : llvm_ctpop;

			immutable f = llvm_ctpop(first.registry);
			immutable s = llvm_ctpop(second.registry);
		}
		else
		{
			import containers.internal.backwards : popcnt;

			immutable f = popcnt(first.registry);
			immutable s = popcnt(second.registry);
		}
		return f + s <= nodeCapacity;
	}

	void mergeNodes(Node* first, Node* second)
	in
	{
		assert (first !is null, "Invalid merge");
		assert (second !is null, "Invalid merge");
		assert (second is first.next, "Invalid merge");
	}
	do
	{
		size_t i;
		ContainerStorageType!T[nodeCapacity] temp;
		foreach (j; 0 .. nodeCapacity)
			if (!first.isFree(j))
				temp[i++] = move(first.items[j]);
		foreach (j; 0 .. nodeCapacity)
			if (!second.isFree(j))
				temp[i++] = move(second.items[j]);
		foreach (j; 0 .. i)
			first.items[j] = move(temp[j]);
		first.registry = 0;
		foreach (k; 0 .. i)
			first.markUsed(k);
		assert (first.registry <= fullBitPattern, "Overflow");
		deallocateNode(second);
	}

	static struct Node
	{
		size_t nextAvailableIndex() const nothrow pure @safe @nogc
		{
			static if (BookkeepingType.sizeof < uint.sizeof)
				immutable uint notReg = ~(cast(uint) registry);
			else
				immutable auto notReg = ~registry;
			version (LDC_64)
			{
				import ldc.intrinsics : llvm_cttz;
				return llvm_cttz(notReg, true);
			}
			else
			{
				import containers.internal.backwards : bsf;
				return bsf(notReg);
			}
		}

		void markUsed(size_t index) nothrow pure @safe @nogc
		{
			registry |= (BookkeepingType(1) << index);
		}

		void markUnused(size_t index) nothrow pure @safe @nogc
		{
			registry &= ~(BookkeepingType(1) << index);
			static if (shouldNullSlot!T)
				items[index] = null;
		}

		bool empty() const nothrow pure @safe @nogc
		{
			return registry == 0;
		}

		bool isFree(size_t index) const nothrow pure @safe @nogc
		{
			return (registry & (BookkeepingType(1) << index)) == 0;
		}

		debug(EMSI_CONTAINERS) invariant()
		{
			import std.string : format;
			assert (registry <= fullBitPattern, format("%016b %016b", registry, fullBitPattern));
			assert (prev !is &this, "Infinite loop");
			assert (next !is &this, "Infinite loop");
		}

		BookkeepingType registry;
		ContainerStorageType!T[nodeCapacity] items;
		Node* prev;
		Node* next;
	}
}

version(emsi_containers_unittest) unittest
{
	import std.algorithm : equal;
	import std.range : iota;
	import std.string : format;
	UnrolledList!ubyte l;
	static assert (l.Node.sizeof <= 64);
	assert (l.empty);
	l.insert(0);
	assert (l.length == 1);
	assert (!l.empty);
	foreach (i; 1 .. 100)
		l.insert(cast(ubyte) i);
	assert (l.length == 100);
	assert (equal(l[], iota(100)));
	foreach (i; 0 .. 100)
		assert (l.remove(cast(ubyte) i), format("%d", i));
	assert (l.length == 0, format("%d", l.length));
	assert (l.empty);

	assert(*l.insert(1) == 1);
	assert(*l.insert(2) == 2);
	assert (l.remove(1));
	assert (!l.remove(1));
	assert (!l.empty);

	UnrolledList!ubyte l2;
	l2.insert(1);
	l2.insert(2);
	l2.insert(3);
	assert (l2.front == 1);
	l2.popFront();
	assert (l2.front == 2);
	assert (equal(l2[], [2, 3]));
	l2.popFront();
	assert (equal(l2[], [3]));
	l2.popFront();
	assert (l2.empty, format("%d", l2.front));
	assert (equal(l2[], cast(int[]) []));
	UnrolledList!int l3;
	foreach (i; 0 .. 200)
		l3.insert(i);
	foreach (i; 0 .. 200)
	{
		auto x = l3.moveFront();
		assert (x == i, format("%d %d", i, x));
	}
	assert (l3.empty);
	foreach (i; 0 .. 200)
		l3.insert(i);
	assert (l3.length == 200);
	foreach (i; 0 .. 200)
	{
		assert (l3.length == 200 - i);
		auto x = l3.moveBack();
		assert (x == 200 - i - 1, format("%d %d", 200 - 1 - 1, x));
	}
	assert (l3.empty);
}

version(emsi_containers_unittest) unittest
{
	struct A { int a; int b; }
	UnrolledList!(const(A)) objs;
	objs.insert(A(10, 11));
	static assert (is (typeof(objs.front) == const));
	static assert (is (typeof(objs[].front) == const));
}

version(emsi_containers_unittest) unittest
{
	static class A
	{
		int a;
		int b;

		this(int a, int b)
		{
			this.a = a;
			this.b = b;
		}
	}

	UnrolledList!(A) objs;
	objs.insert(new A(10, 11));
}

// Issue #52
version(emsi_containers_unittest) unittest
{
	UnrolledList!int list;
	list.insert(0);
	list.insert(0);
	list.insert(0);
	list.insert(0);
	list.insert(0);

	foreach (ref it; list[])
		it = 1;

	foreach (it; list[])
		assert(it == 1);
}

// Issue #53
version(emsi_containers_unittest) unittest
{
	UnrolledList!int ints;
	ints.insertBack(0);
	ints.insertBack(0);

	ints.front = 1;
	ints.back = 11;

	assert(ints.front == 1);
	assert(ints.back == 11);
}

// Issue #168
version(emsi_containers_unittest) unittest
{
	import std.typecons : RefCounted;
	alias E = RefCounted!int;

	E e = E(12);
	UnrolledList!E ints;
	ints.insertBack(e);
	ints.clear();
	// crucial: no assert failure
	assert (e == 12);
}

// Issue #170
version(emsi_containers_unittest) unittest
{
	static struct S { @disable this(this); }
	UnrolledList!S list;

	list.insert(S());
	list.remove(S());

	list.insert(S());
	S s;
	list.remove(s);
}
