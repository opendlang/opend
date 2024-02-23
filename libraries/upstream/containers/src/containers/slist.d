/**
 * Singly-linked list.
 * Copyright: © 2015 Economic Modeling Specialists, Intl.
 * Authors: Brian Schott
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */

module containers.slist;

private import containers.internal.node : shouldAddGCRange;
private import std.experimental.allocator.mallocator : Mallocator;

/**
 * Single-linked allocator-backed list.
 * Params:
 *     T = the element type
 *     Allocator = the allocator to use. Defaults to `Mallocator`.
 *     supportGC = true if the container should support holding references to
 *         GC-allocated memory.
 */
struct SList(T, Allocator = Mallocator, bool supportGC = shouldAddGCRange!T)
{
	/// Disable copying.
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

	~this()
	{
		Node* current = _front;
		Node* prev = null;
		while (current !is null)
		{
			prev = current;
			current = current.next;
			typeid(Node).destroy(prev);
			static if (useGC)
			{
				import core.memory : GC;
				GC.removeRange(prev);
			}
			allocator.dispose(prev);
		}
		_front = null;
	}

	/**
	 * Complexity: O(1)
	 * Returns: the most recently inserted item
	 */
	auto front(this This)() inout @property
	in
	{
		assert (!empty, "Accessing .front of empty SList");
	}
	do
	{
		alias ET = ContainerElementType!(This, T);
		return cast(ET) _front.value;
	}

	/**
	 * Complexity: O(length)
	 * Returns: the least recently inserted item.
	 */
	auto back(this This)() inout @property
	in
	{
		assert (!empty, "Accessing .back of empty SList");
	}
	do
	{
		alias ET = ContainerElementType!(This, T);

		auto n = _front;
		for (; front.next !is null; n = n.next) {}
		return cast(ET) n.value;
	}

	/**
	 * Removes the first item in the list.
	 *
	 * Complexity: O(1)
	 * Returns: the first item in the list.
	 */
	T moveFront()
	in
	{
		assert (!empty, "Accessing .moveFront of empty SList");
	}
	do
	{
		Node* f = _front;
		_front = f.next;
		T r = f.value;
		static if (useGC)
		{
			import core.memory : GC;
			GC.removeRange(f);
		}
		allocator.dispose(f);
		--_length;
		return r;
	}

	/**
	 * Removes the first item in the list.
	 *
	 * Complexity: O(1)
	 */
	void popFront()
	{
		Node* f = _front;
		_front = f.next;
		static if (useGC)
		{
			import core.memory : GC;
			GC.removeRange(f);
		}
		allocator.dispose(f);
		--_length;
	}

	/**
	 * Complexity: O(1)
	 * Returns: true if this list is empty
	 */
	bool empty() inout pure nothrow @property @safe @nogc
	{
		return _front is null;
	}

	/**
	 * Complexity: O(1)
	 * Returns: the number of items in the list
	 */
	size_t length() inout pure nothrow @property @safe @nogc
	{
		return _length;
	}

	/**
	 * Inserts an item at the front of the list.
	 *
	 * Complexity: O(1)
	 * Params: t = the item to insert into the list
	 */
	void insertFront(T t) @trusted
	{
		_front = make!Node(allocator, _front, t);
		static if (useGC)
		{
			import core.memory : GC;
			GC.addRange(_front, Node.sizeof);
		}
		_length++;
	}

	/// ditto
	alias insert = insertFront;

	/// ditto
	alias insertAnywhere = insertFront;

	/// ditto
	alias put = insertFront;

	/**
	 * Supports `list ~= item` syntax
	 *
	 * Complexity: O(1)
	 */
	void opOpAssign(string op)(T t) if (op == "~")
	{
		put(t);
	}

	/**
	 * Removes the first instance of value found in the list.
	 *
	 * Complexity: O(length)
	 * Returns: true if a value was removed.
	 */
	bool remove(V)(V value) @trusted
	{
		Node* prev = null;
		Node* cur = _front;
		while (cur !is null)
		{
			if (cur.value == value)
			{
				if (prev !is null)
					prev.next = cur.next;
				if (_front is cur)
					_front = cur.next;
				static if (shouldAddGCRange!T)
				{
					import core.memory : GC;
					GC.removeRange(cur);
				}
				allocator.dispose(cur);
				_length--;
				return true;
			}
			prev = cur;
			cur = cur.next;
		}
		return false;
	}

	/**
	 * Forward range interface
	 */
	auto opSlice(this This)() inout
	{
		return Range!(This)(_front);
	}

	/**
	 * Removes all elements from the range
	 *
	 * Complexity: O(length)
	 */
	void clear()
	{
		Node* prev = null;
		Node* cur = _front;
		while (cur !is null)
		{
			prev = cur;
			cur = prev.next;
			static if (shouldAddGCRange!T)
			{
				import core.memory : GC;
				GC.removeRange(prev);
			}
			allocator.dispose(prev);
		}
		_front = null;
		_length = 0;
	}

private:

	import std.experimental.allocator : make, dispose;
	import containers.internal.node : shouldAddGCRange;
	import containers.internal.element_type : ContainerElementType;
	import containers.internal.mixins : AllocatorState;

	enum bool useGC = supportGC && shouldAddGCRange!T;

	static struct Range(ThisT)
	{
	public:
		ET front() pure nothrow @property @trusted @nogc
		{
			return cast(typeof(return)) current.value;
		}

		void popFront() pure nothrow @safe @nogc
		{
			current = current.next;
		}

		bool empty() const pure nothrow @property @safe @nogc
		{
			return current is null;
		}

	private:
		alias ET = ContainerElementType!(ThisT, T);
		const(Node)* current;
	}

	static struct Node
	{
		Node* next;
		T value;
	}

	mixin AllocatorState!Allocator;
	Node* _front;
	size_t _length;
}

version(emsi_containers_unittest) unittest
{
	import std.string : format;
	import std.algorithm : canFind;
	SList!int intList;
	foreach (i; 0 .. 100)
		intList.put(i);
	assert(intList.length == 100, "%d".format(intList.length));
	assert(intList.remove(10));
	assert(!intList.remove(10));
	assert(intList.length == 99);
	assert(intList[].canFind(9));
	assert(!intList[].canFind(10));
	SList!string l;
	l ~= "abcde";
	l ~= "fghij";
	assert (l.length == 2);
}

version(emsi_containers_unittest) unittest
{
	static class Foo
	{
		string name;
	}

	SList!Foo hs;
	auto f = new Foo;
	hs.put(f);
}
