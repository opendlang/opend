/**
 * Cyclic Buffer
 * Copyright: © 2016 Economic Modeling Specialists, Intl.
 * Authors: Nickolay Bukreyev
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */

module containers.cyclicbuffer;

private import core.exception : onRangeError;
private import std.experimental.allocator.mallocator : Mallocator;
private import std.range.primitives : empty, front, back, popFront, popBack;
private import containers.internal.node : shouldAddGCRange;

/**
 * Array that provides constant time (amortized) appending and popping
 * at either end, as well as random access to the elements.
 *
 * Params:
 *     T = the array element type
 *     Allocator = the allocator to use. Defaults to `Mallocator`.
 *     supportGC = true if the container should support holding references to GC-allocated memory.
 */
struct CyclicBuffer(T, Allocator = Mallocator, bool supportGC = shouldAddGCRange!T)
{
	@disable this(this);

	private import std.conv : emplace;
	private import std.experimental.allocator.common : stateSize;
	private import std.traits : isImplicitlyConvertible, hasElaborateDestructor;

	static if (stateSize!Allocator != 0)
	{
		/// No default construction if an allocator must be provided.
		@disable this();

		/**
		 * Use the given `allocator` for allocations.
		 */
		this(Allocator allocator) nothrow pure @safe @nogc
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
		clear();
		static if (useGC)
		{
			import core.memory : GC;
			GC.removeRange(storage.ptr);
		}
		allocator.deallocate(storage);
	}

	/**
	 * Removes all contents from the buffer.
	 */
	void clear()
	{
		if (!empty)
		{
			static if (hasElaborateDestructor!T)
			{
				if (start <= end)
					foreach (ref item; storage[start .. end + 1])
						.destroy(item);
				else
				{
					foreach (ref item; storage[start .. $])
						.destroy(item);
					foreach (ref item; storage[0 .. end + 1])
						.destroy(item);
				}
			}
			start = (end + 1) % capacity;
			_length = 0;
		}
	}

	/**
	 * Ensures capacity is at least as large as specified.
	 */
	size_t reserve(size_t newCapacity)
	{
		immutable oldCapacity = capacity;
		if (newCapacity <= oldCapacity)
			return oldCapacity;
		auto old = storage;
		if (oldCapacity == 0)
			storage = cast(typeof(storage)) allocator.allocate(newCapacity * T.sizeof);
		else
		{
			auto a = cast(void[]) old;
			allocator.reallocate(a, newCapacity * T.sizeof);
			storage = cast(typeof(storage)) a;
		}
		static if (useGC)
		{
			import core.memory : GC;
			//Add, then remove. Exactly in that order.
			GC.addRange(storage.ptr, newCapacity * T.sizeof);
			GC.removeRange(old.ptr);
		}
		if (empty)
			end = (start - 1 + capacity) % capacity;
		else if (start > end)
		{
			//The buffer was wrapped around prior to reallocation.

			//`moveEmplaceAll` is only available in 2.069+, so use a low level alternative.
			//Even more, we don't have to .init the moved away data, because we don't .destroy it.
			import core.stdc.string : memcpy, memmove;
			immutable prefix = end + 1;
			immutable suffix = oldCapacity - start;
			if (prefix <= suffix)
			{
				//The prefix is being moved right behind of suffix.
				immutable space = newCapacity - oldCapacity;
				if (space >= prefix)
				{
					memcpy(storage.ptr + oldCapacity, storage.ptr, prefix * T.sizeof);
					end += oldCapacity;
				}
				else
				{
					//There is not enough space, so move what we can,
					//and shift the rest to the start of the buffer.
					memcpy(storage.ptr + oldCapacity, storage.ptr, space * T.sizeof);
					end -= space;
					memmove(storage.ptr, storage.ptr + space, (end + 1) * T.sizeof);
				}
			}
			else
			{
				//The suffix is being moved forward, to the end of the buffer.
				//Due to the fact that these locations may overlap, use `memmove`.
				memmove(storage.ptr + newCapacity - suffix, storage.ptr + start, suffix * T.sizeof);
				start = newCapacity - suffix;
			}
			//Ensure everything is still alright.
			if (start <= end)
				assert(end + 1 - start == length);
			else
				assert(end + 1 + (newCapacity - start) == length);
		}
		return capacity;
	}

	/**
	 * Inserts the given item into the start of the buffer.
	 */
	void insertFront(U)(U value) if (isImplicitlyConvertible!(U, T))
	{
		if (empty)
			reserve(4);
		else if ((end + 1) % capacity == start)
			reserve(capacity >= 65_536 ? capacity + 65_536 : capacity * 2);
		start = (start - 1 + capacity) % capacity;
		_length++;
		emplace(&storage[start], value);
	}

	/**
	 * Inserts the given item into the end of the buffer.
	 */
	void insertBack(U)(U value) if (isImplicitlyConvertible!(U, T))
	{
		if (empty)
			reserve(4);
		else if ((end + 1) % capacity == start)
			reserve(capacity >= 65_536 ? capacity + 65_536 : capacity * 2);
		end = (end + 1) % capacity;
		_length++;
		emplace(&storage[end], value);
	}

	/// ditto
	alias insert = insertBack;

	/// ditto
	alias insertAnywhere = insertBack;

	/// ditto
	alias put = insertBack;

	/**
	 * Removes the item at the start of the buffer.
	 */
	void removeFront()
	{
		version (assert) if (empty) onRangeError();
		size_t pos = start;
		start = (start + 1) % capacity;
		_length--;
		static if (hasElaborateDestructor!T)
			.destroy(storage[pos]);
	}

	/// ditto
	alias popFront = removeFront;

	/**
	 * Removes the item at the end of the buffer.
	 */
	void removeBack()
	{
		version (assert) if (empty) onRangeError();
		size_t pos = end;
		end = (end - 1 + capacity) % capacity;
		_length--;
		static if (hasElaborateDestructor!T)
			.destroy(storage[pos]);
	}

	/// ditto
	alias popBack = removeBack;

	/// Accesses to the item at the start of the buffer.
	auto ref front(this This)() nothrow pure @property @safe
	{
		version (assert) if (empty) onRangeError();
		alias ET = ContainerElementType!(This, T, true);
		return cast(ET) storage[start];
	}

	/// Accesses to the item at the end of the buffer.
	auto ref back(this This)() nothrow pure @property @safe
	{
		version (assert) if (empty) onRangeError();
		alias ET = ContainerElementType!(This, T, true);
		return cast(ET) storage[end];
	}

	/// buffer[i]
	auto ref opIndex(this This)(size_t i) nothrow pure @safe
	{
		version (assert) if (i >= length) onRangeError();
		alias ET = ContainerElementType!(This, T, true);
		return cast(ET) storage[(start + i) % $];
	}

	/// buffer[]
	Range!This opIndex(this This)() nothrow pure @safe @nogc
	{
		if (empty)
			return typeof(return)(storage[0 .. 0], storage[0 .. 0]);
		if (start <= end)
			return typeof(return)(storage[start .. end + 1], storage[0 .. 0]);
		return typeof(return)(storage[start .. $], storage[0 .. end + 1]);
	}

	/// buffer[i .. j]
	size_t[2] opSlice(size_t k: 0)(size_t i, size_t j) const nothrow pure @safe @nogc
	{
		return [i, j];
	}

	/// ditto
	Range!This opIndex(this This)(size_t[2] indices) nothrow pure @safe
	{
		size_t i = indices[0], j = indices[1];
		version (assert)
		{
			if (i > j) onRangeError();
			if (j > length) onRangeError();
		}
		if (i == j)
			return typeof(return)(storage[0 .. 0], storage[0 .. 0]);
		i = (start + i) % capacity;
		j = (start + j) % capacity;
		if (i < j)
			return typeof(return)(storage[i .. j], storage[0 .. 0]);
		return typeof(return)(storage[i .. $], storage[0 .. j]);
	}

	static struct Range(ThisT)
	{
		private
		{
			static if (is(ThisT == immutable))
			{
				alias SliceT = immutable(ContainerStorageType!T)[];
			}
			else static if (is(ThisT == const))
			{
				alias SliceT = const(ContainerStorageType!T)[];
			}
			else
			{
				alias SliceT = ContainerStorageType!T[];
			}
		}

		@disable this();

		this(SliceT a, SliceT b) nothrow pure @safe @nogc
		{
			head = a;
			tail = b;
		}

		This save(this This)() nothrow pure @property @safe @nogc
		{
			return this;
		}

		bool empty() const nothrow pure @property @safe @nogc
		{
			return head.empty && tail.empty;
		}

		size_t length() const nothrow pure @property @safe @nogc
		{
			return head.length + tail.length;
		}

		alias opDollar = length;

		auto ref front(this This)() nothrow pure @property @safe
		{
			if (!head.empty)
				return cast(ET) head.front;
			return cast(ET) tail.front;
		}

		auto ref back(this This)() nothrow pure @property @safe
		{
			if (!tail.empty)
				return cast(ET) tail.back;
			return cast(ET) head.back;
		}

		void popFront() nothrow pure @safe
		{
			if (head.empty)
			{
				import std.algorithm.mutation : swap;
				//Always try to keep `head` non-empty.
				swap(head, tail);
			}
			head.popFront();
		}

		void popBack() nothrow pure @safe
		{
			if (!tail.empty)
				tail.popBack();
			else
				head.popBack();
		}

		/// range[i]
		auto ref opIndex(this This)(size_t i) nothrow pure @safe
		{
			return cast(ET) (i < head.length ? head[i] : tail[i - head.length]);
		}

		/// range[]
		This opIndex(this This)() nothrow pure @safe @nogc
		{
			return this.save;
		}

		/// range[i .. j]
		size_t[2] opSlice(size_t k: 0)(size_t i, size_t j) const nothrow pure @safe @nogc
		{
			return [i, j];
		}

		/// ditto
		This opIndex(this This)(size_t[2] indices) nothrow pure @safe
		{
			size_t i = indices[0], j = indices[1];
			version (assert)
			{
				if (i > j) onRangeError();
				if (j > length) onRangeError();
			}
			if (i >= head.length)
				return typeof(return)(tail[i - head.length .. j - head.length], tail[0 .. 0]);
			if (j <= head.length)
				return typeof(return)(head[i .. j], head[0 .. 0]);
			return typeof(return)(head[i .. $], tail[0 .. j - head.length]);
		}

		/// range[...]++
		auto ref opUnary(string op)() nothrow pure @safe @nogc
		if (op == "++" || op == "--")
		{
			mixin(op ~ "head[];");
			mixin(op ~ "tail[];");
			return this;
		}

		/// range[...] = value
		auto ref opAssign(U)(const auto ref U value) nothrow pure @safe @nogc
		{
			head[] = value;
			tail[] = value;
			return this;
		}

		/// range[...] += value
		auto ref opOpAssign(string op, U)(const auto ref U value) nothrow pure @safe @nogc
		{
			mixin("head[] " ~ op ~ "= value;");
			mixin("tail[] " ~ op ~ "= value;");
			return this;
		}

	private:

		alias ET = ContainerElementType!(ThisT, T);

		SliceT head, tail;
	}

	/// Returns: the number of items in the buffer.
	size_t length() const nothrow pure @property @safe @nogc { return _length; }

	/// ditto
	alias opDollar = length;

	/// Returns: maximal number of items the buffer can hold without reallocation.
	size_t capacity() const nothrow pure @property @safe @nogc { return storage.length; }

	/// Returns: whether or not the CyclicBuffer is empty.
	bool empty() const nothrow pure @property @safe @nogc { return length == 0; }

private:

	import containers.internal.storage_type : ContainerStorageType;
	import containers.internal.element_type : ContainerElementType;
	import containers.internal.mixins : AllocatorState;

	enum bool useGC = supportGC && shouldAddGCRange!T;
	mixin AllocatorState!Allocator;
	ContainerStorageType!T[] storage;
	size_t start, end, _length;
}

version(emsi_containers_unittest) private
{
	import std.algorithm.comparison : equal;
	import std.experimental.allocator.gc_allocator : GCAllocator;
	import std.experimental.allocator.building_blocks.free_list : FreeList;
	import std.range : iota, lockstep, StoppingPolicy;

	struct S
	{
		int* a;

		~this()
		{
			(*a)++;
		}
	}

	class C
	{
		int* a;

		this(int* a)
		{
			this.a = a;
		}

		~this()
		{
			(*a)++;
		}
	}
}

version(emsi_containers_unittest) unittest
{
	static void test(int size)
	{
		{
			CyclicBuffer!int b;
			assert(b.empty);
			foreach (i; 0 .. size)
			{
				assert(b.length == i);
				b.insertBack(i);
				assert(b.back == i);
			}
			assert(b.length == size);
			foreach (i; 0 .. size)
			{
				assert(b.length == size - i);
				assert(b.front == i);
				b.removeFront();
			}
			assert(b.empty);
		}
		{
			CyclicBuffer!int b;
			foreach (i; 0 .. size)
			{
				assert(b.length == i);
				b.insertFront(i);
				assert(b.front == i);
			}
			assert(b.length == size);
			foreach (i; 0 .. size)
			{
				assert(b.length == size - i);
				assert(b.back == i);
				b.removeBack();
			}
			assert(b.empty);
		}
	}

	foreach (size; [1, 2, 3, 4, 5, 7, 8, 9, 512, 520, 0x10000, 0x10001, 0x20000])
		test(size);
}

version(emsi_containers_unittest) unittest
{
	static void test(int prefix, int suffix, int newSize)
	{
		CyclicBuffer!int b;
		foreach_reverse (i; 0 .. suffix)
			b.insertFront(i);
		foreach (i; suffix .. suffix + prefix)
			b.insertBack(i);
		assert(b.length == prefix + suffix);
		b.reserve(newSize);
		assert(b.length == prefix + suffix);
		assert(equal(b[], iota(prefix + suffix)));
	}

	immutable prefixes = [2,  3,  3, 4, 4];
	immutable suffixes = [3,  2,  4, 3, 4];
	immutable sizes    = [16, 16, 9, 9, 9];

	foreach (a, b, c; lockstep(prefixes, suffixes, sizes, StoppingPolicy.requireSameLength))
		test(a, b, c);
}

version(emsi_containers_unittest) unittest
{
	int* a = new int;
	{
		CyclicBuffer!S b;
		{
			S s = { a };
			foreach (i; 0 .. 5)
				b.insertBack(s);
			assert(*a == 5);
			foreach (i; 0 .. 5)
				b.insertBack(S(a));
			assert(*a == 10);
			foreach (i; 0 .. 5)
			{
				b.removeBack();
				b.removeFront();
			}
			assert(*a == 20);
		}
		assert(*a == 21);
	}
	assert(*a == 21);
}

version(emsi_containers_unittest) unittest
{
	int* a = new int;
	CyclicBuffer!C b;
	{
		C c = new C(a);
		foreach (i; 0 .. 10)
			b.insertBack(c);
		assert(*a == 0);
		foreach (i; 0 .. 5)
		{
			b.removeBack();
			b.removeFront();
		}
		foreach (i; 0 .. b.capacity)
			b.insertFront(null);
		assert(*a == 0);
	}
	string s = "";
	foreach (i; 0 .. 1_000)
		s = s ~ 'a';
	s = "";
	import core.memory : GC;
	GC.collect();
	assert(*a == 0 || *a == 1);
}

version(emsi_containers_unittest) unittest
{
	CyclicBuffer!int b;
	b.insertFront(10);
	assert(b[0] == 10);
	b.insertFront(20);
	assert(b[0] == 20);
	assert(b[1] == 10);
	b.insertFront(30);
	assert(b[0] == 30);
	assert(b[1] == 20);
	assert(b[2] == 10);
	b.insertBack(5);
	assert(b[0] == 30);
	assert(b[1] == 20);
	assert(b[2] == 10);
	assert(b[3] == 5);
	b.back = 7;
	assert(b[3] == 7);
}

version(emsi_containers_unittest) unittest
{
	import std.range : isInputRange, isForwardRange, isBidirectionalRange, isRandomAccessRange;
	CyclicBuffer!int b;
	static assert(isInputRange!(typeof(b[])));
	static assert(isForwardRange!(typeof(b[])));
	static assert(isBidirectionalRange!(typeof(b[])));
	static assert(isRandomAccessRange!(typeof(b[])));
}

version(emsi_containers_unittest) unittest
{
	CyclicBuffer!int b;
	assert(b[].empty);
}

version(emsi_containers_unittest) unittest
{
	FreeList!(Mallocator, 0, 64) alloc;
	FreeList!(GCAllocator, 0, 64) alloc2;
	auto b = CyclicBuffer!(int, typeof(&alloc))(&alloc);
	auto b2 = CyclicBuffer!(int, typeof(&alloc2))(&alloc2);
	auto b3 = CyclicBuffer!(int, GCAllocator)();
}

version(emsi_containers_unittest) unittest
{
	static void testConst(const ref CyclicBuffer!int b, int x)
	{
		assert(b[0] == x);
		assert(b.front == x);
		static assert(!__traits(compiles, { ++b[0]; } ));
		assert(equal(b[], [x]));
	}

	CyclicBuffer!int b;
	b.insertFront(0);
	assert(b.front == 0);
	b.front++;
	assert(b[0] == 1);
	b[0]++;
	++b[0];
	assert(b.front == 3);
	assert(!b.empty);
	b[0] *= 2;
	assert(b[0] == 6);
	testConst(b, 6);
	b[]++;
	assert(equal(b[], [7]));
	b[0] = 5;
	assert(b[0] == 5);
	assert(b.front == 5);
	testConst(b, 5);
	assert(b[][0] == 5);
}

version(emsi_containers_unittest) unittest
{
	int* a = new int;
	{
		CyclicBuffer!S b;
		foreach (i; 0 .. 5)
			b.insertBack(S(a));
		assert(*a == 5);
	}
	assert(*a == 10);
	*a = 0;
	{
		CyclicBuffer!S b;
		foreach (i; 0 .. 4)
			b.insertBack(S(a));
		assert(*a == 4);
		b.removeFront();
		assert(*a == 5);
		b.insertBack(S(a));
		assert(*a == 6);
	}
	assert(*a == 10);
}

version(emsi_containers_unittest) unittest
{
	CyclicBuffer!int b;
	foreach (i; 0 .. 4)
		b.insertBack(i);
	b.removeFront();
	b.removeFront();
	b.insertBack(4);
	b.insertBack(5);
	assert(equal(b[], [2, 3, 4, 5]));
	b.reserve(5);
	assert(equal(b[], [2, 3, 4, 5]));
}

version(emsi_containers_unittest) unittest
{
	CyclicBuffer!int b;
	foreach (i; 0 .. 4)
		b.insertBack(i);
	b.removeFront();
	b.removeFront();
	b.removeFront();
	b.insertBack(4);
	b.insertBack(5);
	b.insertBack(6);
	assert(equal(b[], [3, 4, 5, 6]));
	b.reserve(5);
	assert(equal(b[], [3, 4, 5, 6]));
}

version(emsi_containers_unittest) unittest
{
	static void test(ref CyclicBuffer!int b)
	{
		assert(equal(b[], [4, 5, 6, 7, 8, 9, 10, 11]));
		assert(b[3 .. 3].empty);
		auto slice = b[1 .. 6];
		assert(equal(slice, [5, 6, 7, 8, 9]));
		slice[3 .. 5] = 0;
		assert(equal(b[], [4, 5, 6, 7, 0, 0, 10, 11]));
		slice[0 .. 2] += 1;
		assert(equal(b[], [4, 6, 7, 7, 0, 0, 10, 11]));
		slice[0 .. 2]--;
		assert(equal(b[], [4, 5, 6, 7, 0, 0, 10, 11]));
		auto copy = slice.save;
		assert(equal(slice, copy));
		assert(equal(slice, copy[]));
		assert(slice.back == 0);
		slice.popBack();
		assert(equal(slice, [5, 6, 7, 0]));
		assert(slice.back == 0);
		slice.popBack();
		assert(equal(slice, [5, 6, 7]));
		assert(slice.back == 7);
		slice.popBack();
		assert(equal(slice, [5, 6]));
		assert(equal(copy, [5, 6, 7, 0, 0]));
		slice[1] = 10;
		assert(-copy[1] == -10);
		copy[1] *= 2;
		assert(slice[1] == 20);
		assert(b[2] == 20);
		auto copy2 = copy[0 .. $];
		assert(equal(copy, copy2));
	}

	{
		CyclicBuffer!int b;
		foreach (i; 4 .. 12)
			b.insertBack(i);
		test(b);
	}
	{
		CyclicBuffer!int b;
		foreach (i; 0 .. 8)
			b.insertBack(i);
		foreach (i; 0 .. 4)
			b.removeFront();
		foreach (i; 8 .. 12)
			b.insertBack(i);
		test(b);
	}
}

version(emsi_containers_unittest) unittest
{
	CyclicBuffer!int b;
	foreach (i; 0 .. 10)
		b.insertBack(i);
	assert(b.capacity >= 10);
	b.reserve(12);
	assert(b.capacity >= 12);
}

version(emsi_containers_unittest) unittest
{
	CyclicBuffer!int b;
	foreach (i; 0 .. 6)
		b.insertBack(i);
	foreach (i; 6 .. 8)
		b.insertFront(i);
	assert(equal(b[], [7, 6, 0, 1, 2, 3, 4, 5]));
	b.reserve(b.capacity + 1);
	assert(equal(b[], [7, 6, 0, 1, 2, 3, 4, 5]));
}

version(emsi_containers_unittest) unittest
{
    static class Foo
    {
        string name;
    }

    CyclicBuffer!Foo b;
}
