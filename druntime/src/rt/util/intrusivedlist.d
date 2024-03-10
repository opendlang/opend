module rt.util.intrusivedlist;


private alias ListNode = IntrusiveDListNode;

public struct IntrusiveDListNode
{
private:
	ListNode* m_next;
	ListNode* m_prev;
	
public:
	void hook(IntrusiveDListNode* position) nothrow @nogc
	{
		m_next = position;
		m_prev = position.m_prev;
		position.m_prev.m_next = &this;
		position.m_prev = &this;
	}

	void unhook() nothrow @nogc
	{
		ListNode* nextNode = m_next;
		ListNode* prevNode = m_prev;
		prevNode.m_next = nextNode;
		nextNode.m_prev = prevNode;
	}
}


/** 
 * InstrusiveDList implements an intrusive double linked list. This means
 * that the next and previous pointers are embedded in to the struct or class.
 * In order to use the list in a struct or class, it is necessary to add a list
 * node into it.
 *
 * struct S
 * {
 *   IntrusiveDListNode listNode;
 * }
 *
 * IntrusiveDListNode(S, S.listNode) list;
 *
 * It is possible to use a struct/class in several list as long as an associated
 * list node is provided. A list node of each list is required.
 */
struct IntrusiveDList(T, alias MEMBER)
{
private:
	ListNode m_head;
	
	static void insertInternal(ListNode* pos, ListNode *item) nothrow @nogc
	{
		item.hook(pos);
	}

	static void eraseInternal(ListNode* pos) nothrow @nogc
	{
		pos.unhook();
	}

	enum memberOffset = MEMBER.offsetof;

	static T getParentFromMember(ListNode* f) nothrow @nogc pure
	{
		return cast(T)(cast(ubyte*)f - memberOffset);
	}

	static ListNode* getMemberFromParent(T f) nothrow @nogc pure
	{
		return cast(ListNode*)(cast(ubyte*)f + memberOffset);
	}

public:
	/**
	 * Initializes the list. Must be called before using the list
     */
	void initialize() nothrow @nogc
	{
		m_head.m_next = &m_head;
		m_head.m_prev = &m_head;
	}
	
	/**
	 * Checks if the list is empty
	 *
	 * Returns:
	 *   true if the list is empty, otherwise false
     */
	bool empty() const nothrow @nogc
	{
		return m_head.m_next == &m_head;
	}

	/**
	 * Inerts an item at the beginning of the list
     *
	 * Params:
     *  item = The element to insert
     */
	void pushFront(T item) nothrow @nogc
	{
		insertInternal(m_head.m_next, getMemberFromParent(item));
	}

	/**
	 * Inerts an item at the end of the list
     *
	 * Params:
     *  elem = The element to insert
     */
	void pushBack(T item) nothrow @nogc
	{
		insertInternal(&m_head, getMemberFromParent(item));
	}

	/**
	 * Removes the item at the beginning the list
     */
	void popFront() nothrow @nogc
	{
		eraseInternal(m_head.m_next);
	}

	/**
	 * Removes the element at the end the list
     */
	void popBack() nothrow @nogc
	{
		eraseInternal(m_head.m_prev);
	}
	
	/**
	 * Inerts an item before a desired position of the list
     *
	 * Params:
     *  pos = The element to insert the element before
	 *  item = Item to insert
     */
	void insertBefore(T pos, T item) nothrow @nogc
	{
		ListNode *posNode = getMemberFromParent(pos);
		ListNode *itemNode = getMemberFromParent(item);
		insertInternal(posNode, itemNode);
	}

	/**
	 * Erases an item from the list
     *
	 * Params:
     *  pos = The item to remove
     */
	T erase(T pos) nothrow @nogc
	{
		ListNode* posNode = getMemberFromParent(pos);
		ListNode* ret = posNode.m_next;
		eraseInternal(posNode);
		return getParentFromMember(ret);
    }

	/**
	 * Returns a range that iterates over all elements of the container, in
     * forward order.
     *
     * Complexity: $(BIGOH 1)
     *
	 * Returns:
	 *   The range to iterate over
     */
	Range opSlice() nothrow @nogc
    {
        if (empty())
            return Range(null, null);
        else
            return Range(m_head.m_next, m_head.m_prev);
    }

	/**
	 * Returns the first item of the list
     *
	 * Returns:
	 *   The first item
     */
	@property T front() nothrow @nogc
    {
        assert(!empty, "IntrusiveList.front: List is empty");
        return getParentFromMember(m_head.m_next);
    }

	/**
	 * Returns the last item of the list
     *
	 * Returns:
	 *   The last item
     */
	@property T back() nothrow @nogc
    {
        assert(!empty, "IntrusiveList.back: List is empty");
        return getParentFromMember(m_head.m_prev);
    }


	struct Range
	{
		ListNode* m_first;
		ListNode* m_last;

		private this(ListNode* first, ListNode* last)
        {
           	m_first = first;
			m_last = last;
        }

		/**
		 * Returns the first item of the list
		 *
		 * Returns:
		 *   The first item
		 */
		@property T front() nothrow @nogc
        {
            return getParentFromMember(m_first);
        }

		/**
		 * Returns the last item of the list
		 *
		 * Returns:
		 *   The last item
		 */
        @property T back() nothrow @nogc
        {
            return getParentFromMember(m_last);
        }

		/**
	 	 * Checks if the range is empty
		 *
		 * Returns:
		 *   true if the range is empty, otherwise false
         */
		@property bool empty() const scope nothrow @nogc
		{
			return m_first == null;
		}

		void popFront() scope nothrow @nogc
		{
			assert(!empty, "IntrusiveList.Range.popFront: Range is empty");
			if(m_first is m_last)
			{
				m_first = null;
				m_last = null;
			}
			else
			{
				m_first = m_first.m_next;
			}
		}

		void popBack() scope nothrow @nogc
		{
			assert(!empty, "IntrusiveList.Range.popFront: Range is empty");
			if(m_first is m_last)
			{
				m_first = null;
				m_last = null;
			}
			else
			{
				m_last = m_last.m_prev;
			}
		}
	}
}


unittest
{
	import std.stdio;
	import std.conv;

	struct LT
	{
		IntrusiveDListNode listNode;
		string s;
	}

	IntrusiveDList!(LT*, LT.listNode) list;
	list.initialize();

	assert(list.empty());

	foreach (i; 0..10) 
	{
		LT* elem = new LT();
		elem.s = "test" ~ i.to!string;
		list.pushFront(elem);
	}

	assert(!list.empty());

	foreach (i; 0..10) 
	{
		string s = "test" ~ (9 - i).to!string;
		assert(list.front().s == s);
		list.popFront();
	}

	assert(list.empty());

	foreach (i; 0..10) 
	{
		LT* elem = new LT();
		elem.s = "test" ~ i.to!string;
		list.pushBack(elem);
	}

	assert(!list.empty());

	foreach (i; 0..10) 
	{
		string s = "test" ~ (9 - i).to!string;
		assert(list.back().s == s);
		list.popBack();
	}

	assert(list.empty());
}


unittest
{
	import std.stdio;
	import std.conv;

	class LT
	{
		IntrusiveDListNode listNode;
		string s;
	}

	IntrusiveDList!(LT, LT.listNode) list;
	list.initialize();

	foreach (i; 0..10) 
	{
		LT elem = new LT();
		elem.s = "test" ~ i.to!string;
		list.pushBack(elem);
	}

	int k = 0;
	foreach(e; list)
	{
		if(k == 5)
		{
			LT elem = new LT();
			elem.s = "inserted";
			list.insertBefore(e, elem);
			break;
		}

		k++;
	}

	k = 0;
	int j = 0;
	foreach(e; list)
	{
		if(j == 5)
		{
			assert(e.s == "inserted");
		}
		else
		{
			string s = "test" ~ (k++).to!string;
			assert(e.s == s);
		}

		j++;
	}

	foreach(e; list)
	{
		if(e.s == "inserted")
		{
			list.erase(e);
		}
	}

	k = 0;
	foreach(e; list)
	{
		string s = "test" ~ (k++).to!string;
		assert(e.s == s);
	}

	while(!list.empty())
	{
		list.popFront();
	}

	assert(list.empty());
}