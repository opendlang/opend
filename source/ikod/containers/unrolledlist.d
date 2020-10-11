module ikod.containers.unrolledlist;

private import core.memory;
private import core.bitop;
private import core.exception;

private import std.experimental.allocator;
private import std.experimental.allocator.mallocator : Mallocator;
private import std.experimental.allocator.gc_allocator;
private import std.experimental.logger;
private import std.format;
private import std.algorithm;
private import std.typecons;
private import std.compiler;

private import automem.unique;

private import ikod.containers.internal;

///
struct UnrolledList(T, Allocator = Mallocator, bool GCRangesAllowed = true)
{
private:
    alias allocator = Allocator.instance;
    alias StoredT = StoredType!T;
    enum  ItemsPerNode = 32; // can be variable maybe

    //
    int     _count;
    Node*   _first_node, _last_node;

    struct Node
    {

        static assert(ItemsPerNode <= 32);

        uint                    _count;
        uint                    _bitmap;
        Node*                   _next_node;

        StoredT[ItemsPerNode]   _items;
        Node*                   _prev_node;

        bool empty() @safe @nogc nothrow
        {
            return _bitmap == 0;
        }
        bool full() pure @safe @nogc nothrow
        {
            return _count == ItemsPerNode;
        }
        int count_free_high_bits()
        in(_count>=0 && _count <= ItemsPerNode)
        {
            if ( _count == ItemsPerNode || test_bit(ItemsPerNode-1) )
            {
                return 0;
            }
            if ( _count == 0 )
            {
                return ItemsPerNode;
            }
            return(bsf(bitswap(_bitmap)));
        }
        int count_free_low_bits()
        in(_count>=0 && _count <= ItemsPerNode)
        {
            if ( _count == ItemsPerNode || test_bit(0) )
            {
                return 0;
            }
            if ( _count == 0 )
            {
                return ItemsPerNode;
            }
            return(bsf(_bitmap));
        }

        pragma(inline, true):
        void mark_bit(size_t n) pure @safe @nogc
        {
            debug assert(n < ItemsPerNode, format("%s must be less than %d", n, ItemsPerNode));
            _bitmap |= 1 << n;
        }

        pragma(inline, true):
        void clear_bit(size_t n) pure @safe @nogc nothrow
        {
            assert(n < ItemsPerNode);
            _bitmap &= uint.max ^ (1 << n);
        }

        pragma(inline, true):
        bool test_bit(size_t n) pure @safe @nogc
        {
            debug assert(n < ItemsPerNode, "%d must be < %d".format(n, ItemsPerNode));
            return (_bitmap & (1 << n)) != 0;
        }

        int translate_pos(size_t n) pure @safe @nogc
        in( n < ItemsPerNode )
        out(result; result == -1 || result < ItemsPerNode)
        {
            if (_count == ItemsPerNode )
            {
                return cast(int)n;
            }
            if ( _count <= n )
            {
                return -1;
            }
            int p = 0;
            foreach(i; bsf(_bitmap)..ItemsPerNode)
            {
                if ( !test_bit(i)) continue;
                if (p == n)
                {
                    return i;
                }
                p++;
            }
            assert(0);
        }
    }
    Node* makeNode()
    {
        Node* node = make!Node(allocator);
        static if ( UseGCRanges!(Allocator, T, GCRangesAllowed) ) {
            () @trusted {
                GC.addRange(&node._items[0], T.sizeof * ItemsPerNode);
            }();
        }
        return node;
    }
    void deallocNode(Node *p)
    {
        () @trusted {
            static if ( UseGCRanges!(Allocator,T, GCRangesAllowed) ) {
                GC.removeRange(&p._items[0]);
            }
            dispose(allocator, p);
        }();
    }
    enum IteratorMsgType
    {
        CLEAR = 0,
    }
    /++
    +/
    public struct Iterator(T)
    {
        private T*  _impl;
        package this(Args...)(auto ref Args args, string file = __FILE__, int line = __LINE__) @trusted
        {
            import std.functional: forward;
            import std.conv: emplace;
            _impl = cast(typeof(_impl)) allocator.allocate((*_impl).sizeof);
            emplace(_impl, forward!args);
        }
        this(this) @safe
        {
            if (!_impl)
            {
                return;
            }
            auto _new_impl = () @trusted {return cast(typeof(_impl)) allocator.allocate((*_impl).sizeof);}();
            _new_impl._list = null;
            _new_impl._ptr = null;
            *_new_impl = *_impl;
            _impl = _new_impl;
        }
        ~this()
        {
            _impl.reset();
            () @trusted {allocator.dispose(_impl);}();
        }
        /// test on emptiness
        bool empty()
        {
            return _impl.empty();
        }
        /// return front element of iterator
        auto front()
        {
            return _impl.front();
        }
        /// pop front element
        void popFront()
        {
            _impl.popFront();
        }
        /// reset iterator
        void reset()
        {
            _impl.reset();
        }
    }
    struct U
    {
        alias ListType = UnrolledList!(T, Allocator, GCRangesAllowed);
        alias NodeType = UnrolledList!(T, Allocator, GCRangesAllowed).Node;

        private:
            U**         _ptr;
            ListType*   _list;
            bool        _empty;
            NodeType*   _currentNode;
            int         _currentNodeItem;
            int         _currentNodeItemPosition; // in bitmap
            int         _currentNodeItemsTotal;
            size_t      _item;
            size_t      _itemsTotal;

        public:
            this(U** p, ListType* list = null, size_t item = 0, int items = 0, NodeType* node = null, int nodeItem = 0)
            {
                _ptr = p;
                *_ptr = &this;
                _list = list;
                _item = item;
                _itemsTotal = items;
                _currentNode = node;
                _currentNodeItem = nodeItem;
                if (node)
                {
                    _currentNodeItemsTotal = node._count;
                    _currentNodeItemPosition = node.translate_pos(nodeItem);
                }
            }
            /// create and register another instance of unstable range
            this(this)
            {
                if ( !_list || !_ptr )
                {
                    return;
                }
                for(auto i=0; i<MaxRanges; i++)
                {
                    if ( _list._unstableRanges[i] is null )
                    {
                        _list._unstableRanges_counter++;
                        _list._unstableRanges[i] = &this;
                        _ptr = &_list._unstableRanges[i];
                        return;
                    }
                }
                assert(0, "Too much active ranges");
            }
            ///
            void reset()
            {
                if (_list is null || _ptr is null )
                {
                    assert(_list is null && _ptr is null);
                    return;
                }
                assert(_list !is null);
                _list._unstableRanges_counter--;
                assert(_list._unstableRanges_counter >= 0);
                if ( _ptr !is null )
                {
                    assert(*_ptr == &this);
                    *_ptr = null;
                    _ptr = null;
                }
                _list = null;
            }
            ///
            ~this() @safe
            {
                if ( _list !is null )
                {
                    _list._unstableRanges_counter--;
                    assert(_list._unstableRanges_counter >= 0);
                }
                if (_ptr !is null)
                {
                    *_ptr = null;
                }
            }
            ///
            auto opAssign(V)(auto ref V other) if (is(V==typeof(this)))
            {
                if ( other is this )
                {
                    return;
                }
                if ( _list && other._list != _list )
                {
                    reset();
                }
                if ( _ptr is null && other._list !is null )
                {
                    // register
                    assert(_list is null);
                    auto l = other._list;
                    for(auto i=0; i<MaxRanges; i++)
                    {
                        if ( l._unstableRanges[i] is null )
                        {
                            l._unstableRanges_counter++;
                            assert(l._unstableRanges_counter<l.MaxRanges);
                            l._unstableRanges[i] = &this;
                            _ptr = &l._unstableRanges[i];
                            break;
                        }
                    }
                }
                _list = other._list;
                _item = other._item;
                _itemsTotal = other._itemsTotal;
                _currentNode = other._currentNode;
                _currentNodeItem = other._currentNodeItem;
                _currentNodeItemsTotal = other._currentNodeItemsTotal;
                _currentNodeItemPosition = other._currentNodeItemPosition;
                _empty = other._empty;
            }
            ///
            auto front()
            {
                // foreach(s; _list.dump)
                // {
                //     debug info(s);
                // }
                assert(_list && _currentNode);
                auto n = _currentNode;
                auto i = _currentNodeItem;
                auto p = _currentNodeItemPosition;
                assert(n.test_bit(p));
                return n._items[p];
            }
            ///
            void popFront()
            {
                if ( !_list || !_ptr )
                {
                    return;
                }
                if ( _item >= _itemsTotal-1 )
                {
                    _empty = true;
                    //reset();
                    return;
                }
                auto n = _currentNode;
                assert(n);
                _currentNodeItem++;
                if (  _currentNodeItem == _currentNodeItemsTotal )
                {
                    // goto next node
                    n = n._next_node;
                    _currentNode = n;
                    _currentNodeItem = 0;
                    _currentNodeItemPosition = cast(ubyte)bsf(n._bitmap);
                    _currentNodeItemsTotal = cast(short)n._count;
                }
                else
                {
                    if ( n._count == ItemsPerNode )
                    {   // full node, each token position equals it's number
                        _currentNodeItemPosition = _currentNodeItem;
                    }
                    else
                    {
                        // find next non-zero bit in bitmask
                        auto m = 0xffff_ffff ^ ((1<<(_currentNodeItemPosition+1)) - 1);
                        _currentNodeItemPosition = cast(ubyte)bsf(n._bitmap & m);
                    }
                }
                _item++;
            }
            bool empty()
            {
                return _empty;
            }
    }

    enum MaxRanges = 32;

    U*[MaxRanges]               _unstableRanges;
    short                       _unstableRanges_counter;

public:

    /++
    +   Create new unstable range. Unstable range save it's correctness by
    +   preventing you from any list mutations.
    +
    +   unstable range is `value `type` - assignment and initializations create its copy.
    +
    +   Unstable range can't make warranties on it's correctnes if you make any list mutation.
    +   So, while you have any active unstable range you can't make any mutation to list. At any
    +   atempt to remove, insert or clear list while unstable range active you'll get AssertionError.
    +   To make unstableRange inactive you have to consume it to the end or call `reset` on it.
    +
    +   Params:
    +   start = start position in list (default value - head of the list)
    +   end = end positions in list (default value - end of the list)
    + --------------------------------------------------------------------
    +     UnrolledList!int l;
    + 
    +     foreach(i; 0..50)
    +     {
    +         l.pushBack(i);
    +     }
    +     auto r = l.unstableRange();
    +     assert(equal(r, iota(50)));   // copy of range created 
    +     assertThrown!AssertError(l.clear); // r still active
    +     assertThrown!AssertError(l.remove(0)); // r still active
    +     assertThrown!AssertError(l.pushBack(0)); // r still active
    +     assertThrown!AssertError(l.pushFront(0)); // r still active
    +     assertThrown!AssertError(l.popBack()); // r still active
    +     assertThrown!AssertError(l.popFront()); // r still active
    +     r.reset();    // deactivate r
    +     l.clear();    // it is safe to clear list
    + -------------------------------------------------------------------
    +/
    auto unstableRange(int start=0, int end=int.max) @safe @nogc
    {
        U** slot;
        assert(_unstableRanges_counter < MaxRanges-1);
        for(auto i=0; i<MaxRanges; i++)
        {
            if ( _unstableRanges[i] is null )
            {
                slot = &_unstableRanges[i];
                break;
            }
        }
        if ( slot is null )
        {
            assert(0, "Too much active ranges");
        }

        _unstableRanges_counter++;

        auto result = Iterator!U(slot, &this);

        if ( _count == 0)
        {
            // empty list
            result._impl._empty = true;
            return result;
        }

        // static if (version_major == 2 && version_minor < 94 )
        // {
        //     () @trusted // address of variable this assigned to this with longer lifetime
        //     {r._list = &this;}();
        // }
        // else
        // {
        //     r._list = &this;
        // }

        // start counts from end
        if ( start < 0 )
        {
            start = _count + start;
        }
        if ( end < 0 )
        {
            end = _count + end;
        }
        // if end greater than list length - use list length
        if ( end > _count )
        {
            end = _count;
        }
        if ( start == end )
        {
            result._impl._empty = true;
            return result;
        }
        assert(start < _count && end <= _count && start < end);
        auto node = _first_node;
        auto item = 0;
        auto items = end - start;
        auto nodeItem = 0;
        while( node !is null && item + node._count <= start )
        {
            item += node._count;
            node = node._next_node;
        }
        nodeItem = start - item;
        result._impl._currentNode = node;
        result._impl._currentNodeItem = nodeItem;
        result._impl._currentNodeItemPosition = node.translate_pos(nodeItem);
        result._impl._currentNodeItemsTotal = node._count;
        result._impl._item = 0;
        result._impl._itemsTotal = items;
        return result;
        // return U(r, &this, 0, items, node, nodeItem);
    }

    this(this)
    {
        auto n = _first_node;
        _first_node = _last_node = null;
        _count = 0;

        _unstableRanges_counter = 0;
        _unstableRanges = _unstableRanges.init;

        while(n)
        {
            auto nn = n._next_node;
            for(auto i=0; i<ItemsPerNode; i++)
            {
                if ( n.test_bit(i) )
                {
                    pushBack(n._items[i]);
                }
            }
            n = nn;
        }
    }

    ~this()
    {
        foreach(ur; _unstableRanges)
        {
            if ( ur !is null )
            {
                ur._empty = true;
                ur._list = null;
                ur._ptr = null;
            }
        }
        auto n = _first_node;
        while(n)
        {
            auto nn = n._next_node;
            deallocNode(n);
            n = nn;
        }
    }

    auto dump()
    {
        string[] s;
        s ~= "<<<length: %d".format(_count);
        s ~= "first_node: %x".format(_first_node);
        s ~= "last_node: %x".format(_last_node);
        auto n = _first_node;
        while(n !is null)
        {
            s ~= "Page %2.2d nodes, %032b bitmap(swapped)".format(n._count, bitswap(n._bitmap));
            s ~= "               0....o....1....o....2....o....3.";
            s ~= "Prev page ptr: %x".format(n._prev_node);
            s ~= "Next page ptr: %x".format(n._next_node);
            s ~= "%s".format(n._items);
            s ~= "---";
            n = n._next_node;
        }
        s ~= ">>>";
        return s;
    }

    void clear()
    {
        assert(_unstableRanges_counter == 0, "You can't call mutating methods while unstableRange active. Use stableRange");
        auto n = _first_node;
        while(n)
        {
            auto nn = n._next_node;
            deallocNode(n);
            n = nn;
        }
        _count = 0;
        _first_node = _last_node = null;
    }

    private auto _node_and_index(size_t i)
        in(i<_count)
        out(r; r.node !is null && r.index < ItemsPerNode)
        do
    {
        Node *n;
        // select iteration direcion
        if ( i > ItemsPerNode && i > _count /2 )
        {
            // iterate from end to beg
            n = _last_node;
            auto b = _count;
            while ( b - n._count > i )
            {
                b -= n._count;
                n = n._prev_node;
            }
            i = i - b + n._count;
        }
        else
        {
            // iterate from beg to end
            n = _first_node;
            while(i >= n._count)
            {
                i -= n._count;
                n = n._next_node;
            }
        }
        return Tuple!(Node*, "node", size_t, "index")(n, i);
    }
    /++
        Get item at some position.

        To be @nogc it do not throw, but return tuple with bool `ok`member.

        Params:
        i = position
        Returns:
        tuple with succes indicator and value
        -------------------------------------
        UnrolledList!int l;
        foreach(i; 0..50)
        {
            l.pushBack(i);
        }
        auto v = l.get(25);
        assert(v.ok);
        assert(v.value == 25);
        -------------------------------------
    +/
    auto get(size_t i)
    {
        if (_count == 0 || i >= _count )
        {
            return Tuple!(bool, "ok", StoredT, "value")(false, T.init);
        }
        auto ni = _node_and_index(i);
        auto n = ni.node;
        auto pos = n.translate_pos(ni.index);
        assert(n.test_bit(pos));
        return Tuple!(bool, "ok", StoredT, "value")(true, n._items[pos]);
    }
    // O(N)
    auto opIndex(size_t i)
    {
        auto v = get(i);
        if ( !v.ok )
        {
            throw new RangeError("index %d out of range".format(i));
        }
        return v.value;
    }
    // O(N)
    void opAssign(ref typeof(this) other)
    {
        if (other is this)
        {
            return;
        }
        clear();
        auto n = other._first_node;
        while(n)
        {
            auto nn = n._next_node;
            for(auto i=0; i<ItemsPerNode; i++)
            {
                if ( n.test_bit(i) )
                {
                    pushBack(n._items[i]);
                }
            }
            n = nn;
        }
    }
    // O(N)
    void opIndexAssign(V)(V v, size_t i)
    {
        if (_count == 0 || i >= _count )
        {
            throw new RangeError("index %d out of range".format(i));
        }
        auto ni = _node_and_index(i);
        auto n = ni.node;
        auto pos = n.translate_pos(ni.index);
        assert(n.test_bit(pos));
        n._items[pos] = v;
    }
    // O(1)
    bool empty()
    {
        return _count == 0;
    }
    // O(1)
    auto length() pure @safe @nogc nothrow
    {
        return _count;
    }
    // O(1)
    auto front()
    {
        assert(_count > 0, "Attempting to fetch the front of an empty list");
        auto p = bsf(_first_node._bitmap);
        return _first_node._items[p];
    }
    /++
    + Get last item. O(1)
    +
    + Returns: last item.
    + Throws: AssertError when list is empty.
    +/
    auto back()
    {
        assert(_count > 0, "Attempting to fetch the front of an empty list");
        auto p = bsr(_last_node._bitmap);
        return _last_node._items[p];
    }
    /++
    + Append item to the list. O(1)
    +
    + Throws: AssertError if any unstable range is registered.
    +/
    void pushBack(V)(V v)
    {
        assert(_unstableRanges_counter == 0, "You can't mutate list while there are active unstable ranges");
        _count++;
        int pos;
        if ( _last_node && !_last_node.test_bit(ItemsPerNode-1))
        {
            pos = bsr(_last_node._bitmap) + 1;
        }
        else
        {
            Node* n = makeNode();
            if ( !_last_node )
            {
                assert(!_first_node);
                _first_node = _last_node = n;
            }
            else
            {
                n._prev_node = _last_node;
                _last_node._next_node = n;
                _last_node = n;
            }
        }
        _last_node._count++;
        // take most significant free bit
        _last_node.mark_bit(pos);
        _last_node._items[pos] = v;
    }
    /++
    + Prepend list with item v. O(1)
    +
    + Throws: AssertError if any unstable range is registered.
    +/
    void pushFront(V)(V v)
    {
        assert(_unstableRanges_counter == 0, "You can't mutate list while there are active unstable ranges");
        _count++;
        int pos;
        if ( _first_node && !_first_node.test_bit(0))
        {
            pos = bsf(_first_node._bitmap)-1;
        }
        else
        {
            Node* n = makeNode();
            if ( !_first_node )
            {
                assert(!_last_node);
                _first_node = _last_node = n;
            }
            else
            {
                n._next_node = _first_node;
                _first_node._prev_node = n;
                _first_node = n;
            }
            pos = ItemsPerNode - 1; // allow easy handle next pushFront
        }
        _first_node._count++;
        // take most significant free bit
        _first_node.mark_bit(pos);
        _first_node._items[pos] = v;
    }
    /++
    + Pop first item from the list. O(1)
    +
    + No action if list is empty.
    +
    + Throws: AssertError if any unstable range is registered.
    +/
    void popFront()
    {
        assert(_unstableRanges_counter == 0, "You can't mutate list while there are active unstable ranges");
        if ( _count == 0 )
        {
            return;
        }
        _count--;
        assert(_first_node);
        auto pos = bsf(_first_node._bitmap);
        _first_node._count--;
        _first_node.clear_bit(pos);
        _first_node._items[pos] = T.init;
        if (_first_node._count == 0)
        {
            // release this page
            auto n = _first_node;
            _first_node = n._next_node;
            if ( _first_node is null )
            {
                _last_node = null;
            }
            else
            {
                _first_node._prev_node = null;
            }
            deallocNode(n);
        }
    }
    /++
    + Pop last item from the list. O(1)
    +
    + No action if list is empty.
    +
    + Throws: AssertError if any unstable range is registered.
    +/
    void popBack()
    {
        assert(_unstableRanges_counter == 0, "You can't mutate list while there are active unstable ranges");
        if ( _count == 0 )
        {
            return;
        }
        _count--;
        assert(_last_node);
        auto pos = bsr(_last_node._bitmap);
        _last_node._count--;
        _last_node.clear_bit(pos);
        _last_node._items[pos] = T.init;
        if (_last_node._count == 0)
        {
            // release this node
            auto n = _last_node;
            _last_node._next_node = null;
            _last_node = n._prev_node;
            if ( _last_node is null )
            {
                _first_node = null;
            }
            else
            {
                _last_node._next_node = null;
            }
            deallocNode(n);
        }
    }
    /++
    + Remove item from the list by item index. O(N)
    +
    + No action if list is empty.
    + Returns: True if item were removed.
    + Throws: AssertError if any unstable range is registered.
    +/
    bool remove(size_t i)
    {
        assert(_unstableRanges_counter == 0, "You can't mutate list while there are active unstable ranges");
        if ( i >= _count )
        {
            return false;
        }
        if ( i == 0 )
        {
            popFront();
            return true;
        }
        if ( i == _count - 1)
        {
            popBack();
            return true;
        }
        auto ni = _node_and_index(i);
        auto index = ni.index;
        auto node  = ni.node;
        auto pos   = node.translate_pos(index);
        _count--;
        node._count--;
        node.clear_bit(pos);
        node._items[pos] = T.init;
        return true;
    }
    /++
    + Insert item at position i. O(N)
    +
    + Params:
    + v = value to insert
    + i = position for this value
    +
    + Returns: True if item were inserted (false if index is > list.length+1)
    + Throws: AssertError if any unstable range is registered.
    +/
    bool insert(V)(size_t i, V v)
    {
        assert(_unstableRanges_counter == 0, "You can't mutate list while there are active unstable ranges");
        debug(ikodcontainers) tracef("insert %s at %s", v, i);
        if ( i > _count )
        {
            return false;
        }
        if ( i == 0 )
        {
            pushFront(v);
            return true;
        }
        if ( i == _count )
        {
            pushBack(v);
            return true;
        }
        auto ni = _node_and_index(i);
        auto index = ni.index;
        auto node  = ni.node;
        auto pos   = node.translate_pos(index);

        int lo_mask = bitswap((((1<<pos) - 1) & node._bitmap) << (int.sizeof*8-pos));
        int hi_mask = (node._bitmap >> pos);

        uint lo_shift = lo_mask != 0 ? bsf(lo_mask ^ uint.max) :
                        pos == 0 ? uint.max : 0;
        uint hi_shift = hi_mask == 0 ? uint.max : bsf(hi_mask ^ uint.max);
        auto lo_overflow = lo_shift < hi_shift  && lo_shift >= pos;
        auto hi_overflow = hi_shift <= lo_shift && pos + hi_shift >= ItemsPerNode;

        // debug infof("pos: %s", pos);
        // debug infof("bitmap %32.32b", node._bitmap);
        // debug infof("lomask %32.32b", lo_mask);
        // debug infof("himask %32.32b", hi_mask);
        // debug infof("lo_shift: %d, hi shift: %d", lo_shift, hi_shift);
        // debug infof("lo_over:  %s, hi overfl: %s", lo_overflow, hi_overflow);
        if ( lo_overflow )
        {
            debug(ikodcontainers) tracef("low overflow");
            if ( node._prev_node
                && node._prev_node.count_free_high_bits() > 0 
                && node._prev_node.count_free_high_bits() >= lo_shift )
            {
                debug(ikodcontainers) tracef("low overflow to existent node with %s free high bits", node._prev_node.count_free_high_bits());
            }
            else
            {
                debug(ikodcontainers) tracef("low overflow to new node");
                auto new_node = makeNode();
                auto new_p = (ItemsPerNode - lo_shift) / 2;
                auto old_p = pos - lo_shift;
                for(auto s=0; s<lo_shift; s++)
                {
                    new_node._items[new_p+s] = node._items[old_p+s];
                    new_node.mark_bit(new_p+s);
                    new_node._count++;
                    node.clear_bit(old_p+s);
                    node._count--;
                }
                if ( _first_node == node )
                {
                    _first_node = new_node;
                }
                else
                {
                    node._prev_node._next_node = new_node;
                    new_node._prev_node = node._prev_node;
                }
                new_node._next_node = node;
                node._prev_node = new_node;
                if ( pos > 0 )
                {
                    node._count++;
                    node._items[pos-1] = v;
                    node.mark_bit(pos-1);
                }
                else
                {
                    new_node._count++;
                    new_node._items[new_p + lo_shift] = v;
                    new_node.mark_bit(new_p + lo_shift);
                }
                _count++;
                return true;
            }
        }
        if ( hi_overflow )
        {
            debug(ikodcontainers) tracef("high overflow");
            if (node._next_node && node._next_node.count_free_low_bits() >= hi_shift)
            {
                debug(ikodcontainers) tracef("high overflow to next existent node");
                auto next_node = node._next_node;
                auto next_node_pos = bsf(next_node._bitmap)-hi_shift;
                for(auto s=0;s<hi_shift;s++)
                {
                    next_node._items[next_node_pos + s] = node._items[pos+s];
                    next_node.mark_bit(next_node_pos + s);
                    next_node._count++;
                    node.clear_bit(pos+s);
                    node._count--;
                }
                node._count++;
                node._items[pos] = v;
                node.mark_bit(pos);
                _count++;
                return true;
            }
            else
            {
                debug(ikodcontainers) tracef("high overflow to new node");
                auto new_node = makeNode();
                auto new_p = (ItemsPerNode - hi_shift) / 2;
                for(auto s=0; s<hi_shift; s++)
                {
                    new_node._items[new_p+s] = node._items[pos+s];
                    new_node.mark_bit(new_p+s);
                    new_node._count++;
                    node.clear_bit(pos+s);
                    node._count--;
                }
                node._count++;
                node._items[pos] = v;
                node.mark_bit(pos);
                // link right
                if ( _last_node == node)
                {
                    _last_node = new_node;
                }
                else
                {
                    node._next_node._prev_node = new_node;
                    new_node._next_node = node._next_node;
                }
                new_node._prev_node = node;
                node._next_node = new_node;
                _count++;
                return true;
            }
        }
        if ( lo_shift == 0 )
        {
            // we have free space to insert
            assert(!node.test_bit(pos-1));
            node._count++;
            assert(node._count <= ItemsPerNode);
            node._items[pos-1] = v;
            node.mark_bit(pos-1);
            _count++;
            return true;
        }
        if ( lo_shift == uint.max )
        {
            auto new_node = makeNode();
            auto new_p = ItemsPerNode / 2;
            if ( _first_node == node )
            {
                _first_node = new_node;
            }
            else
            {
                node._prev_node._next_node = new_node;
                new_node._prev_node = node._prev_node;
            }
            new_node._next_node = node;
            node._prev_node = new_node;
            new_node._count = 1;
            new_node._items[new_p] = v;
            new_node.mark_bit(new_p);
            _count++;
            return true;
        }
        if ( lo_shift < hi_shift )
        {
            assert(!node.full);
            // shift to low items
            auto new_pos = pos-lo_shift - 1;
            for(auto s=0; s<lo_shift+1; s++)
            {
                node._items[new_pos+s] = node._items[new_pos+s+1];
            }
            node.mark_bit(new_pos);
            node._count++;
            assert(node._count <= ItemsPerNode);
            node._items[pos-1] = v;
            // node.mark_bit(pos);
            _count++;
            return true;
        }
        else
        {
            assert(!node.full);
            // shift to hight items
            auto new_pos = pos+hi_shift;
            for(auto s=hi_shift; s>0; s--)
            {
                node._items[pos+s] = node._items[pos+s-1];
            }
            node.mark_bit(new_pos);
            node._count++;
            assert(node._count <= ItemsPerNode);
            node._items[pos] = v;
            // node.mark_bit(pos);
            _count++;
            return true;
        }
        assert(0);
    }
}
unittest
{
    UnrolledList!int list;
    list.pushFront(1);
    assert(list.length == 1);
    assert(list.front == 1);
    assert(list.back == 1);
    list.pushFront(0);
    assert(list.length == 2);
    assert(list.front == 0);
    assert(list.back == 1);
    list.pushBack(2);
    assert(list.length == 3);
    assert(list.front == 0);
    assert(list.back == 2);
    list.pushBack(3);
    assert(list.length == 4);
    assert(list.front == 0);
    assert(list.back == 3);

    list.popFront();
    assert(list.length == 3);
    assert(list.front == 1);
    assert(list.back == 3);
    list.popFront();
    assert(list.length == 2);
    assert(list.front == 2);
    assert(list.back == 3);
    list.popFront();
    assert(list.length == 1);
    assert(list.front == 3);
    assert(list.back == 3);
    list.popFront();
    assert(list.empty);
    foreach(int i; 0..1000)
    {
        list.pushBack(i);
    }
    assert(list.length == 1000);
    assert(list.front == 0, "<%s>".format(list.front));
    assert(list.back == 999, "<%s>".format(list.back));
    foreach(int i; 0..1000)
    {
        assert(list[i] == i);
    }
    list.popFront();
    foreach(int i; 1..1000)
    {
        assert(list[i-1] == i);
    }
    foreach(int i; 1..1000)
    {
        list.popBack();
    }
    assert(list.length == 0);
    // fill it again
    foreach(int i; 0..1000)
    {
        list.pushBack(i);
    }
    list.remove(100);
    assert(list[100] == 101);
    foreach(_;0..list.ItemsPerNode)
    {
        list.remove(0);
    }
    assert(list[0] == list.ItemsPerNode);
    assert(list.length == 1000 - list.ItemsPerNode - 1);
    // test clear
    list.clear();
    assert(list.length == 0);
    // test inserts
    list.insert(0, 1);  // |1| |
    list.insert(0, 0);  // |0|1|
    assert(list.length == 2);
    assert(list[0] == 0);
    assert(list[1] == 1);
    list.clear();
    foreach(int i; 0..list.ItemsPerNode)
    {
        list.pushBack(i);
    }
    assert(list.length == list.ItemsPerNode); // |0|1|...|14|15|
    list.remove(14);        // |0|1|...|__|15|
    assert(list[14] == 15);
    list.insert(14,14);
    assert(list[14] == 14); // |0|1|...|14|15|
    list.popBack();         // |0|1|...|14|__|
    list[14] = 15;
    assert(list[14] == 15); // |0|1|...|15|__|
    list.insert(14,14);
    assert(list[14] == 14); // |0|1|...|14|15|
    assert(list[15] == 15); // |0|1|...|14|15|
    assert(list.length == list.ItemsPerNode);
    list.insert(2, 16);
    assert(list[2] == 16);
    assert(list.length == list.ItemsPerNode+1);
    assert(list.back == list.ItemsPerNode-2);
    list.insert(5, 17);
    list.insert(3,55);
    list.insert(17, 88);
    list.insert(15, 99);
    assert(list[15] == 99);
}

@("ul1")
@safe unittest
{
    UnrolledList!int l;
    assert(l.length == 0);
    l.pushBack(0);
    assert(l.length == 1);
    assert(l.front == 0);
    assert(l.back == 0);
    l.pushBack(1);
    assert(l.length == 2);
    assert(l.front == 0);
    assert(l.back == 1);
    l.pushFront(2);
    assert(l.length == 3);
    assert(l.front == 2);
    assert(l.back == 1);
    l.pushFront(3);
    assert(l.length == 4);
    assert(l.front == 3);
    assert(l.back == 1);
    l.popBack();
    assert(l.length == 3);
    assert(l.front == 3);
    assert(l.back == 0);
    l.popBack();
    assert(l.length == 2);
    assert(l.front == 3);
    assert(l.back == 2);
}
@("ul2")
@safe @nogc unittest
{
    UnrolledList!int l0, l1;
    foreach(i;0..1_000)
    {
        l0.pushBack(i);
    }
    l1 = l0;
    foreach(i;0..1_000)
    {
        immutable v = l1.get(i);
        assert(v.ok);
        assert(v.value == i);
    }
    l1 = l0;
    foreach(i;0..1_000)
    {
        immutable v = l1.get(i);
        assert(v.ok);
        assert(v.value == i);
    }
    auto l2 = l1;
    foreach(i;0..1_000)
    {
        immutable v = l2.get(i);
        assert(v.ok);
        assert(v.value == i);
    }
}

@("ul2")
@safe @nogc unittest
{
    UnrolledList!int l;
    foreach(i;0..1_000)
    {
        l.pushBack(i);
    }
    foreach(i;0..1_000)
    {
        immutable v = l.get(i);
        assert(v.ok);
        assert(v.value == i);
    }
}

@("ul3")
unittest
{
    import std.exception;
    UnrolledList!int l;
    assertThrown!RangeError(l[0]);
    foreach(i; 0..1_000)
    {
        l.pushBack(i);
    }
    assertThrown!RangeError(l[1000]);
    foreach(i; 0..1_000)
    {
        l[i] = i * 2;
    }
    foreach(i;0..1_000)
    {
        assert(l[i] == i * 2);
    }
}
@("ul4")
@safe unittest
{
    UnrolledList!int l;
    foreach(i;0..2*l.ItemsPerNode)
    {
        l.pushBack(i);
    }
    //          ↓ ins B
    // XXX....XXA->XXX....XXX
    l.insert(l.ItemsPerNode-1, 1000);
    // XXX....XXB->OOO..A..OOO->XXX....XXX
    assert(l[l.ItemsPerNode - 1] == 1000);
    assert(l.length == l.ItemsPerNode*2 + 1);
}
@("ul5")
@safe unittest
{
    UnrolledList!int l;
    foreach(i;0..2*l.ItemsPerNode)
    {
        l.pushBack(i);
    }
    l.remove(l.ItemsPerNode);
    //     ins B↓
    // XXX....XXA -> OXX....XXX
    l.insert(l.ItemsPerNode - 1, 1000);
    //
    // XXX....XXB -> AXX....XXX
    assert(l[l.ItemsPerNode - 1] == 1000);
    assert(l.length == 2 * l.ItemsPerNode);
}
@("ul6")
@safe unittest
{
    UnrolledList!int l;
    foreach(i;0..2*l.ItemsPerNode)
    {
        l.pushBack(i);
    }
    //          ins B↓
    // XXX....XXX -> XXX....XXX
    l.insert(l.ItemsPerNode, 1000);
    // XXX....XXX->OOO..B..OOO->XXX....XXX
    assert(l[l.ItemsPerNode] == 1000);
    assert(l.length == 2 * l.ItemsPerNode + 1);
}

@("ul7")
@safe unittest
{
    UnrolledList!int l;
    foreach(i;0..l.ItemsPerNode)
    {
        l.pushBack(i);
    }
    l.remove(2);
    //   B↓
    // XXOX..XXX
    l.insert(2, 1000);
    // XXBX..XXX
    assert(l[2] == 1000);
    assert(l.length == l.ItemsPerNode);
}

@("ul8")
@safe unittest
{
    UnrolledList!int l;
    foreach(i;0..l.ItemsPerNode)
    {
        l.pushBack(i);
    }
    l.remove(2);
    // B↓
    // XAOX..XXX
    l.insert(1, 1000);
    // XBAX..XXX
    assert(l[1] == 1000);
    assert(l.length == l.ItemsPerNode);
}

@("ul9")
@safe unittest
{
    UnrolledList!int l;
    foreach(i;0..l.ItemsPerNode)
    {
        l.pushBack(i);
    }
    l.remove(l.ItemsPerNode-2);
    l.remove(0);
    l.remove(1);
    //    B↓
    // OXOXXX..XXO
    l.insert(2, 1000);
    // XBAX..XXX
    l.insert(27, 2000);
    assert(l[27] == 2000);
    assert(l.length == l.ItemsPerNode-1);
}
@("ul10")
@safe unittest
{
    UnrolledList!int l;
    foreach(i;0..l.ItemsPerNode)
    {
        l.pushBack(i);
    }
    l.remove(0);
    l.insert(30,1000);
    assert(l[0]==1);
    assert(l[30] == 1000);
}

@("unstableIterator")
unittest
{
    import std.range;
    import std.exception;
    import std.algorithm;
    import std.stdio;

    UnrolledList!int l;

    foreach(i; 0..50)
    {
        l.pushBack(i);
    }
    auto r = l.unstableRange();
    assert(equal(r, iota(50)));
    assertThrown!AssertError(l.clear); // r still active
    assertThrown!AssertError(l.remove(0)); // r still active
    assertThrown!AssertError(l.pushBack(0)); // r still active
    assertThrown!AssertError(l.pushFront(0)); // r still active
    assertThrown!AssertError(l.popBack()); // r still active
    assertThrown!AssertError(l.popFront()); // r still active
    r.reset();  // deactivate r
    l.clear();
    foreach(i; 0..50)
    {
        l.pushBack(i);
    }
    r = l.unstableRange();
    auto r1 = r;
    r.reset();
    assert(equal(r1.take(10), iota(10))); // still can use r1
    r1 = l.unstableRange();
    r1 = r1;
    r.reset();
    assert(l._unstableRanges_counter == 1); // r1 only
    assert(equal(r1, iota(50)));
    // test negative indexing
    assert(equal(l.unstableRange(25), iota(25,50)));
    assert(l.unstableRange(-3, -3).count == 0);
    assertThrown!AssertError(l.unstableRange(0, -10000));
    assert(l._unstableRanges_counter == 1); // r1 only, temp ranges unregistered

    r = l.unstableRange();
    assert(l._unstableRanges_counter == 2); // r and r1
    foreach(i, v; r.enumerate)
    {
        r1 = l.unstableRange(cast(int)i, 50);
        assert(equal(r1, iota(i, 50)));
    }
    r1.reset();
    r.reset();
    assert(l._unstableRanges_counter == 0); // we cleared everything

    // test unregister on list destruction
    {
        UnrolledList!int l1;
        foreach(i; 0..50)
        {
            l1.pushBack(i);
        }
        r1 = l1.unstableRange();
        assert(r1.count == 50);
        foreach(i,v; r1.enumerate)
        {
            auto r2 = l1.unstableRange(cast(int)i);
            assert(equal(r2, iota(i, 50)));
        }
        assert(r1.count == 50);
    }
    assert(r1.count == 0); // lost container
}
@("classes")
@safe
unittest
{
    import std.range;
    class C
    {
        int c;
        this(int i)
        {
            c = i;
        }
    }
    UnrolledList!C l;
    foreach(i; 0..50)
    {
        l.pushBack(new C(i));
    }
    auto r = l.unstableRange;
    assert(equal(r.map!(c => c.c), iota(50)));
}
@("structs")
@safe
unittest
{
    import std.format: format;
    import std.range;
    struct S
    {
        int s;
        string ss;
        this(int i)
        {
            s = i;
            ss = "%s".format(i);
        }
    }
    UnrolledList!(S) l;
    foreach(i; 0..50)
    {
        S s = S(i);
        l.pushBack(s);
    }
    auto r = l.unstableRange;
    assert(equal(r.map!(s => s.s), iota(50)));
}