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
    invariant(_nodes_counter>=0 && _count>=0);
private:
    alias allocator = Allocator.instance;
    alias StoredT = StoredType!T;
    enum  ItemsPerNode = 32; // can be variable maybe
    enum  MaxRanges = 16;
    enum  NewItemPosition = ItemsPerNode/2;
    //
    int                      _count;
    int                      _nodes_counter;
    Node*                    _first_node, _last_node;
    short                    _constRanges_counter;
    short                    _mutRanges_counter;
    Impl!"mut"*[MaxRanges]   _mutRanges;
    Impl!"const"*[MaxRanges] _constRanges;

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
            if ( n >= ItemsPerNode )
            {
                debug throw new Exception("X");
            }
            assert(n < ItemsPerNode);
            _bitmap &= uint.max ^ (1 << n);
        }
        pragma(inline, true):
        int _hi_mask(int pos)
        {
            return _bitmap >> pos;
        }
        pragma(inline, true):
        int _lo_mask(int pos)
        {
            return bitswap((((1<<pos) - 1) & _bitmap) << (int.sizeof*8-pos));
        }
        pragma(inline, true):
        bool test_bit(size_t n) pure @safe @nogc nothrow
        in(n<ItemsPerNode)
        {
            return cast(bool)(_bitmap & (1 << n));
        }

        int translate_pos(int n) pure @safe @nogc nothrow
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

    Node* _free_list;
    int   _free_list_count;

    Node* makeNode()
    {
        if ( _free_list_count > 0 )
        {
            Node* n = _free_list;
            _free_list_count--;
            _free_list = n._next_node;
            n._prev_node = n._next_node = null;
            n._count = n._bitmap = 0;
            return n;
        }
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
        if (_free_list_count < 100)
        {
            _free_list_count++;
            p._next_node = _free_list;
            _free_list = p;
            return;
        }
        () @trusted {
            static if ( UseGCRanges!(Allocator,T, GCRangesAllowed) ) {
                GC.removeRange(&p._items[0]);
            }
            dispose(allocator, p);
        }();
    }
    enum Sig
    {
        CLEAR = 0,
        REMOVE,
        INSERT
    }
    /++
    +/
    public struct Iterator(I)
    {
        private I*  _impl;
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
        // save
        auto save()
        {
            return this;
        }
        /// reset iterator
        void reset()
        {
            _impl.reset();
        }
        int opApply(scope int delegate(T) dg)
        {
            int result = 0;
            while(!empty)
            {
                result = dg(front);
                popFront;
                if (result)
                    break;
            }
            return result;
        }
        static if (is(I == Impl!"mut"))
        {
            void set(T v)
            {
                auto list = _impl._list;
                assert(list._constRanges_counter == 0);
                auto node = _impl._currentNode;
                auto pos = _impl._currentNodeItemPosition;
                assert(node.test_bit(pos));
                node._items[pos] = v;
            }
            ///
            /// remove current front Item from list
            /// +--------------+-----------------------+-----------------+
            /// | this         | other                 | list            |
            /// | Iter         | Iter                  |                 |
            /// +--------------+-----------------------+-----------------+
            /// | remove list  | if points to removed: | free item;      |
            /// | item;        |   mark invalid        | adjust counters |
            /// | do popFront; | else:                 |                 |
            /// |              |   adjust everything   |                 |
            /// +--------------+-----------------------+-----------------+
            ///
            void remove()
            {
                auto list = _impl._list;
                assert(list._constRanges_counter == 0);
                auto node = _impl._currentNode;
                auto pos = _impl._currentNodeItemPosition;
                //debug infof("before remove item: %d, node= %s, pos=%s", _impl._item, _impl._currentNode, _impl._currentNodeItemPosition);
                assert(node.test_bit(pos));
                if ( list._mutRanges_counter > 0) foreach(mr; list._mutRanges)
                {
                    if (mr !is null && mr != this._impl)
                    {
                        // debug infof("callback %x", mr);
                        mr.signal(Sig.REMOVE, _impl._item, node, _impl._currentNodeItem);
                    }
                }
                list._count--;
                node._count--;
                //_impl._item--;
                _impl._end--;
                _impl._currentNodeItemsTotal--;
                node.clear_bit(pos);
                node._items[pos] = T.init;
                // debug infof("after remove item: %d", _impl._item);
                if ( _impl._item == _impl._end)
                {
                    // debug info("become empty");
                    _impl._empty = true;
                    return;
                }
                if ( _impl._currentNodeItem == node._count )
                {
                    // debug info("jump next node");
                    node = node._next_node;
                    while (node && node._count == 0 )
                    {
                        // debug info("jump next node");
                        auto next_node = node._next_node;
                        if ( list._constRanges_counter == 0 && list._mutRanges_counter == 1)
                        {
                            // safe to remove empty node
                            if ( _impl._currentNode )
                            {
                                _impl._currentNodeItemsTotal = _impl._currentNode._count;
                            }
                            if ( node == list._first_node )
                            {
                                list._first_node = node._next_node;
                            }
                            if ( node == list._last_node )
                            {
                                list._last_node = node._prev_node;
                            }
                            if ( node._prev_node )
                            {
                                node._prev_node._next_node = node._next_node;
                            }
                            if ( node._next_node )
                            {
                                node._next_node._prev_node = node._prev_node;
                            }
                            list._nodes_counter--;
                            list.deallocNode(node);
                        }
                        node = next_node;
                    }
                    _impl._currentNodeItem = 0;
                    _impl._currentNode = node;
                    _impl._currentNodeItemsTotal = node._count;
                }
                _impl._currentNodeItemPosition = node.translate_pos(_impl._currentNodeItem);
                // debug infof("after remove item: %d, node= %s, pos=%s", _impl._item, _impl._currentNode, _impl._currentNodeItemPosition);
            }
            void insert(T v)
            {
                auto list = _impl._list;
                Node* node = _impl._currentNode;
                int pos = _impl._currentNodeItemPosition;
                if ( list._mutRanges_counter > 0) foreach(mr; list._mutRanges)
                {
                    if (mr !is null && mr != this._impl)
                    {
                        // debug infof("callback %x", mr);
                        mr.signal(Sig.INSERT, _impl._item, node, _impl._currentNodeItem);
                    }
                }
                if ( _impl._empty )
                {
                    // debug info("insert to empty range");
                    // debug infof("it_item: %s, it_end: %s, it_nodeItem: %s", _impl._item, _impl._end, _impl._currentNodeItem);
                    // debug infof("list_end: %s", _impl._list._count);
                    list._doRealPushBack(v);
                    _impl._end++;
                    _impl._item++;
                    return;
                }
                _impl._end++;
                _impl._item++;
                assert(_impl._currentNodeItemPosition>=0);
                int lo_mask = node._lo_mask(pos);
                int hi_mask = node._hi_mask(pos);
                int lo_shift = lo_mask != 0 ? bsf(lo_mask ^ uint.max) :
                                pos == 0 ? uint.max : 0;
                int hi_shift = hi_mask == 0 ? uint.max : bsf(hi_mask ^ uint.max);
                auto lo_overflow = lo_shift < hi_shift  && lo_shift >= pos;
                auto hi_overflow = hi_shift <= lo_shift && pos + hi_shift >= ItemsPerNode;
                auto nodeItem = _impl._currentNodeItem;
                // debug infof("nodeItemPos: %s", pos);
                // debug infof("nodeItem: %s", nodeItem);
                // debug infof("bitmap %32.32b", node._bitmap);
                // debug infof("lomask %32.32b", lo_mask);
                // debug infof("himask %32.32b", hi_mask);
                // debug infof("lo_shift: %d, hi shift: %d", lo_shift, hi_shift);
                // debug infof("lo_over:  %s, hi overfl: %s", lo_overflow, hi_overflow);

                _impl._list._doRealInsert(node, nodeItem, v);

                if (!lo_overflow && !hi_overflow && lo_shift != -1)
                {
                    _impl._currentNodeItem++;
                    _impl._currentNodeItemsTotal++;
                    if ( lo_shift >= hi_shift)
                    {
                        _impl._currentNodeItemPosition++;
                    }
                }
                if ( hi_overflow )
                {
                    _impl._currentNodeItem++;
                    _impl._currentNodeItemPosition++;
                }
                if (_impl._currentNodeItem >= _impl._currentNodeItemsTotal)
                {
                    _impl._currentNodeItem = 0;
                    _impl._currentNode = _impl._currentNode._next_node;
                    if ( _impl._currentNode )
                    {
                        _impl._currentNodeItemPosition = _impl._currentNode.translate_pos(0);
                        _impl._currentNodeItemsTotal = _impl._currentNode._count;
                    }
                }
                // debug infof("nodeItem: %s", _impl._currentNodeItem);
            }
        }
    }

    template Impl(string kind) if (kind == "mut" || kind == "const")
    {
        alias ListType = typeof(this);
        alias NodeType = ListType.Node;
        struct Impl
        {
            alias T = typeof(this);
            T**         _ptr;
            ListType*   _list;
            bool        _empty;
            NodeType*   _currentNode;
            int         _currentNodeItem;
            int         _currentNodeItemPosition; // in bitmap
            int         _currentNodeItemsTotal;
            int         _item;
            size_t      _end;

            static if (kind == "mut")
            {
                private auto refc()
                {
                    return &_list._mutRanges_counter;
                }
                private auto refptr(int i)
                {
                    return &_list._mutRanges[i];
                }
                // Params: sig - signal type
                //         i - index of the item inside node
                //         n - node
                void signal(Sig sig, int item, Node* n, int nodeItem) nothrow
                {
                    final switch(sig)
                    {
                        case Sig.CLEAR:
                            _item = 0;
                            _end = 0;
                            _empty = true;
                            _currentNode = null;
                            _currentNodeItem = 0;
                            return;
                        case Sig.REMOVE:
                            if ( _empty )
                            {
                                // nothing to do
                                return;
                            }
                            // debug infof("signal remove: old item# %s, i'm at %s, end: %s", item, _item, _end);
                            if ( item <= _item )
                            {
                                //    ,-remove
                                // ___X___b....e___
                                _item--;
                                _end--;
                                if ( n != _currentNode )
                                {
                                    return;
                                }
                                _currentNodeItem--;
                                _currentNodeItemsTotal--;
                                if (_currentNodeItemsTotal == 0)
                                {
                                    // goto next node
                                    while(n && n._next_node && n._next_node._count == 0)
                                    {
                                        n = n._next_node;
                                    }
                                    n = n._next_node;
                                    _currentNode = n;
                                    _currentNodeItem = -1;
                                    //_currentNodeItemPosition = cast(ubyte)bsf(n._bitmap);
                                    if ( n ) _currentNodeItemsTotal = cast(short)n._count;
                                }
                                return;
                            }
                            if ( _item <= item && item < _end )
                            {
                                //    ,-remove
                                // _b.X....e___
                                _end--;
                                if ( n != _currentNode )
                                {
                                    return;
                                }
                                _currentNodeItemsTotal--;
                                return;
                            }
                            //           ,-remove
                            // _b.....e__X__
                            // nothing to do
                            break;
                        case Sig.INSERT:
                            // debug infof("signal insert: old item# %s, i'm at %s, end: %s", item, _item, _end);
                            if ( item >= _end)
                            {
                                // debug info("insert after end");
                                return;
                            }
                            if ( item <= _item )
                            {
                                _item++;
                                if (n == _currentNode)
                                {
                                    _currentNodeItem++;
                                }
                            }
                            if (n !is null && n == _currentNode)
                            {
                                auto pos   = n.translate_pos(nodeItem);

                                int lo_mask = n._lo_mask(pos);
                                int hi_mask = n._hi_mask(pos);

                                int lo_shift = lo_mask != 0 ? bsf(lo_mask ^ uint.max) :
                                                pos == 0 ? uint.max : 0;
                                int hi_shift = hi_mask == 0 ? uint.max : bsf(hi_mask ^ uint.max);
                                auto lo_overflow = lo_shift < hi_shift  && lo_shift >= pos;
                                auto hi_overflow = hi_shift <= lo_shift && pos + hi_shift >= ItemsPerNode;
                                // debug infof("lomask %32.32b", lo_mask);
                                // debug infof("himask %32.32b", hi_mask);
                                // debug infof("lo_shift: %d, hi shift: %d", lo_shift, hi_shift);
                                // debug infof("lo_over:  %s, hi overfl: %s", lo_overflow, hi_overflow);


                                if ( lo_overflow && _currentNodeItemPosition == 0) 
                                {
                                    // debug info("going to move left");
                                    // this item becomes highest item in the prev node
                                    Node* prev_node = n._prev_node;
                                    int prev_pos = prev_node.translate_pos(prev_node._count-1)+1;
                                    // debug infof("my new position: %d", prev_pos);
                                    _currentNode = prev_node;
                                    _currentNodeItem = _currentNode._count;
                                    _currentNodeItemsTotal = _currentNode._count+1;
                                    _currentNodeItemPosition = prev_pos;
                                }
                                else
                                {
                                    int p = n.translate_pos(nodeItem);
                                    if ( (_currentNodeItemPosition < p) && (lo_shift < hi_shift))
                                    {
                                        // we might be affectd by the left shift
                                        // debug infof("my pos = %s, his pos = %s", _currentNodeItemPosition, p);
                                        if ( p - _currentNodeItemPosition < lo_shift )
                                        {
                                            // we shifted left
                                            _currentNodeItemPosition--;
                                            assert(_currentNodeItemPosition>=0);
                                        }
                                    }
                                    if (!hi_overflow)
                                    {
                                        _currentNodeItemsTotal = _currentNode._count+1;
                                    }
                                }
                                _end++;
                                // debug infof("_item: %d, _nodeItem: %d, _currentNodeItemsTotal: %s", _item, _currentNodeItem, _currentNodeItemsTotal);
                                return;
                            }
                            if ( n !is null && n == _currentNode._next_node )
                            {
                                n = _currentNode._next_node;
                                auto pos   = n.translate_pos(nodeItem);

                                int lo_mask = n._lo_mask(pos);
                                int hi_mask = n._hi_mask(pos);

                                int lo_shift = lo_mask != 0 ? bsf(lo_mask ^ uint.max) :
                                                pos == 0 ? uint.max : 0;
                                int hi_shift = hi_mask == 0 ? -1 : bsf(hi_mask ^ uint.max);
                                auto lo_overflow = lo_shift < hi_shift  && lo_shift >= pos;
                                auto hi_overflow = hi_shift <= lo_shift && pos + hi_shift >= ItemsPerNode;

                                // debug infof("lomask2 %32.32b", lo_mask);
                                // debug infof("himask2 %32.32b", hi_mask);
                                // debug infof("lo_shift2: %d, hi shift2: %d", lo_shift, hi_shift);
                                // debug infof("lo_over2:  %s, hi overfl2: %s", lo_overflow, hi_overflow);

                                if ( (lo_overflow || lo_shift==-1) && _currentNode.count_free_high_bits()>0)
                                {
                                    // debug infof("will overflow to me, new _currentNodeItemsTotal: %s", _currentNodeItemsTotal+1);
                                    // overflow to my node from
                                    _currentNodeItemsTotal++;
                                }
                                _end++;
                                return;
                            }
                            _end++;
                            // debug infof("signal insert: new item# %d, new end: %d", item, _end);
                            break;
                    }
                }
            }
            else
            {
                private auto refc()
                {
                    return &_list._constRanges_counter;
                }
                private auto refptr(int i)
                {
                    return &_list._constRanges[i];
                }
            }
        public:
            this(T** p, ListType* list = null, int item = 0, int end = 0, NodeType* node = null, int nodeItem = 0) @nogc
            {
                _ptr = p;
                if (p)
                {
                    *_ptr = &this;
                }
                _list = list;
                _item = item;
                _end = end;
                _currentNode = node;
                _currentNodeItem = nodeItem;
                if (node)
                {
                    _currentNodeItemsTotal = node._count;
                    _currentNodeItemPosition = node.translate_pos(nodeItem);
                }
            }
            /// create and register another instance of stable range
            this(this)
            {
                if ( !_list || !_ptr )
                {
                    return;
                }
                for(auto i=0; i<MaxRanges; i++)
                {
                    if ( *refptr(i) is null )
                    {
                        (*refc)++;
                        *refptr(i) = &this;
                        _ptr = refptr(i);
                        return;
                    }
                }
                assert(0, "Too much active stable ranges");
            }
            ~this() @safe
            {
                if ( _list !is null )
                {
                    (*refc)--;
                    assert((*refc) >= 0);
                }
                if (_ptr !is null)
                {
                    *_ptr = null;
                }
            }
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
                    _list = other._list;
                    for(auto i=0; i<MaxRanges; i++)
                    {
                        if ( *refptr(i) is null )
                        {
                            (*refc)++;
                            assert(*refc < _list.MaxRanges);
                            *refptr(i) = &this;
                            _ptr = refptr(i);
                            break;
                        }
                    }
                }
                _item = other._item;
                _end = other._end;
                _currentNode = other._currentNode;
                _currentNodeItem = other._currentNodeItem;
                _currentNodeItemsTotal = other._currentNodeItemsTotal;
                _currentNodeItemPosition = other._currentNodeItemPosition;
                _empty = other._empty;
            }
            void reset()
            {
                if (_list is null || _ptr is null )
                {
                    assert(_list is null && _ptr is null);
                    return;
                }
                assert(_list !is null);
                (*refc)--;
                assert(*refc >= 0);
                if ( _ptr !is null )
                {
                    assert(*_ptr == &this);
                    *_ptr = null;
                    _ptr = null;
                }
                _list = null;
            }
            auto front()
            {
                assert(_list && _currentNode);
                auto n = _currentNode;
                auto p = _currentNodeItemPosition;
                assert(_item >= 0);
                assert(n.test_bit(p), "You tried to access empty item.");
                return n._items[p];
            }
            void popFront()
            {
                // if ( !_list || !_ptr )
                // {
                //     return;
                // }
                // debug infof("popping from item %s, nodeItem: %s", _item, _currentNodeItem);
                _item++;
                if ( _item >= _end )
                {
                    _empty = true;
                    static if (kind == "const")
                    {
                        reset();
                    }
                    return;
                }
                auto n = _currentNode;
                if ( !n )
                {
                    debug throw new Exception("y");
                }
                assert(n);
                _currentNodeItem++;
                // debug infof("_item=%s, _end=%s, _currentnodeItem now =%s, _currentNodeItems = %s", _item, _end, _currentNodeItem, _currentNodeItemsTotal);
                if (  _currentNodeItem == _currentNodeItemsTotal )
                {
                    // debug infof("jump next node");
                    // goto next node
                    while(n && n._next_node && n._next_node._count == 0)
                    {
                        //debug infof("skip empty node");
                        n = n._next_node;
                    }
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
                        // debug infof("m: %32.32b", bitswap(m));
                        // debug infof("b: %32.32b", bitswap(n._bitmap));
                        // debug infof("r: %32.32b", bitswap(n._bitmap&m));
                        _currentNodeItemPosition = cast(ubyte)bsf(n._bitmap & m);
                        // debug infof("nodeItem: %s, cp: %d, itemsTotal: %s", _currentNodeItem, _currentNodeItemPosition, _currentNodeItemsTotal);
                    }
                }
            }
            bool empty()
            {
                return _empty;
            }
        }
    }


public:
    auto makeRange(string R)(int start=0, int end=int.max) @safe
    {
        static if (R == "mut")
        {
            alias _rCounter = _mutRanges_counter;
            alias _rArray = _mutRanges;
            alias T = Impl!"mut";
        }
        else static if (R == "const")
        {
            alias _rCounter = _constRanges_counter;
            alias _rArray = _constRanges;
            alias T = Impl!"const";
        }
        else
        {
            static assert(0, "Wrong type");
        }
        //


        T** slot;
        assert(_rCounter < MaxRanges-1);
        for(auto i=0; i<MaxRanges; i++)
        {
            if ( _rArray[i] is null )
            {
                slot = &_rArray[i];
                break;
            }
        }
        if ( slot is null )
        {
            assert(0, "Too much active ranges");
        }

        _rCounter++;

        auto result = Iterator!T(slot, &this);
        if ( _count == 0)
        {
            // empty list
            result._impl._empty = true;
            return result;
        }

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
        result._impl._item = start;
        result._impl._end = end;
        return result;
    }
    alias mutRange = makeRange!("mut");
    /++
    +   Create new const range. Const range preserve it's correctness by
    +   preventing you from any list mutations.
    +
    +   const range is `value `type` - assignment and initializations create its copy.
    +
    +   const range can't make warranties on it's correctnes if you make any list mutation.
    +   So, while you have any active const range you can't make any mutation to list. At any
    +   atempt to remove, insert or clear list while const range active you'll get AssertionError.
    +   To make constRange inactive you have to consume it to the end or call `reset` on it.
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
    +     auto r = l.constRange();
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
    alias constRange = makeRange!"const";

    this(this)
    {
        auto n = _first_node;
        _first_node = _last_node = null;
        _count = 0;

        _constRanges_counter = 0;
        _constRanges = _constRanges.init;

        _mutRanges_counter = 0;
        _mutRanges = _mutRanges.init;

        _free_list = null;
        _free_list_count = 0;

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
        foreach(r; _constRanges)
        {
            if ( r !is null )
            {
                r._empty = true;
                r._list = null;
                r._ptr = null;
            }
        }
        foreach(r; _mutRanges)
        {
            if ( r !is null )
            {
                r._empty = true;
                r._list = null;
                r._ptr = null;
            }
        }
        auto n = _first_node;
        while(n)
        {
            auto nn = n._next_node;
            deallocNode(n);
            n = nn;
            _nodes_counter--;
        }

        while(_free_list_count)
        {
            Node* p = _free_list;
            _free_list = p._next_node;
            _free_list_count--;
            () @trusted {
                static if ( UseGCRanges!(Allocator,T, GCRangesAllowed) ) {
                    GC.removeRange(&p._items[0]);
                }
                dispose(allocator, p);
            }();
        }
    }

    auto dump()
    {
        string[] s;
        s ~= "<<<";
        s ~= "length: %d".format(_count);
        s ~= "nodes: %d".format(_nodes_counter);
        s ~= "density: %f".format(_nodes_counter>0?1e0*_count/_nodes_counter/ItemsPerNode:0e0);
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
        assert(_constRanges_counter == 0, "You can't call mutating methods while constRange active. Use stableRange");
        if (_mutRanges_counter)
            sendnotify(Sig.CLEAR, 0, null, 0);
        auto n = _first_node;
        while(n)
        {
            auto nn = n._next_node;
            deallocNode(n);
            _nodes_counter--;
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
        return Tuple!(Node*, "node", int, "index")(n, cast(int)i);
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
        auto n = _first_node;
        while(n && n._count == 0)
        {
            n = n._next_node;
        }
        auto p = bsf(n._bitmap);
        return n._items[p];
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
        auto n = _last_node;
        while(n && n._count == 0)
        {
            n = n._prev_node;
        }
        auto p = bsr(n._bitmap);
        return n._items[p];
    }
    ///
    /// send notifications to mutrange's
    /// Params: 
    ///  s=    - Sig type
    ///  item= - number of the item in the list, where we place new item(this would be its number).
    ///  n=    - current node (where we hope to place new item)
    ///  nodeItem= - number of the new item for this node
    //
    private void sendnotify(Sig s, int item, Node* n, int nodeItem) pure @nogc @safe nothrow
    {
        auto mcs = _mutRanges_counter;
        for(int mr; mcs>0 && mr < MaxRanges; mr++)
        {
            if (_mutRanges[mr] !is null)
            {
                _mutRanges[mr].signal(s, item, n, nodeItem);
                mcs--;
            }
        }
    }
    /++
    + Append item to the list. O(1)
    +
    + Throws: AssertError if any const range is registered.
    +/
    void pushBack(V)(V v)
    {
        assert(_constRanges_counter == 0, "You can't mutate list while there are active const ranges");
        if (_mutRanges_counter>0)
        {
            sendnotify(Sig.INSERT, _count, _last_node, _last_node?_last_node._count:-1);
        }
        _doRealPushBack(v);
    }
    /++
    + Prepend list with item v. O(1)
    +
    + Throws: AssertError if any const range is registered.
    +/
    void pushFront(V)(V v)
    {
        assert(_constRanges_counter == 0, "You can't mutate list while there are active const ranges");
        if (_mutRanges_counter)
            sendnotify(Sig.INSERT, 0, _first_node, 0);
        _doRealInsert(_first_node, 0, v);
    }
    /++
    + Pop first item from the list. O(1)
    +
    + No action if list is empty.
    +
    + Throws: AssertError if any const range is registered.
    +/
    void popFront()
    {
        assert(_constRanges_counter == 0, "You can't mutate list while there are active const ranges");
        if ( _count == 0 )
        {
            return;
        }
        assert(_first_node);
        auto node = _first_node;
        while(node._count == 0)
        {
            node = node._next_node;
        }
        if (_mutRanges_counter>0)
            sendnotify(Sig.REMOVE, 0, node, 0);
        _count--;
        auto pos = bsf(node._bitmap);
        node._count--;
        node.clear_bit(pos);
        node._items[pos] = T.init;
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
            _nodes_counter--;
        }
    }
    /++
    + Pop last item from the list. O(1)
    +
    + No action if list is empty.
    +
    + Throws: AssertError if any const range is registered.
    +/
    void popBack()
    {
        assert(_constRanges_counter == 0, "You can't mutate list while there are active const ranges");
        if ( _count == 0 )
        {
            return;
        }
        if (_mutRanges_counter>0)
            sendnotify(Sig.REMOVE, _count - 1, _last_node, _last_node._count - 1);
        _count--;
        auto node = _last_node;
        while(node && node._count == 0)
        {
            node = node._prev_node;
        }
        auto pos = bsr(node._bitmap);
        node._count--;
        assert(node._count>=0 && node._count < ItemsPerNode);
        node.clear_bit(pos);
        node._items[pos] = T.init;
        if (_last_node._count == 0 && _mutRanges_counter == 0)
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
            _nodes_counter--;
        }
    }
    /++
    + Remove item from the list by item index. O(N)
    +
    + No action if list is empty.
    + Returns: True if item were removed.
    + Throws: AssertError if any const range is registered.
    +/
    bool remove(int i)
    {
        assert(_constRanges_counter == 0, "You can't mutate list while there are active const ranges");
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
        int mcs = _mutRanges_counter;
        for(int mr; mcs>0 && mr < MaxRanges; mr++)
        {
            if (_mutRanges[mr] !is null)
            {
                _mutRanges[mr].signal(Sig.REMOVE, i, node, index);
                mcs--;
            }
        }
    _count--;
        node._count--;
        node.clear_bit(pos);
        node._items[pos] = T.init;
        return true;
    }
    pragma(inline, true):
    private void _doRealPushBack(V)(V v)
    {
        int pos;
        Node* node = _last_node;
        while( node && node._count == 0 && node._prev_node )
        {
            node = node._prev_node;
        }

        if ( node && !node.test_bit(ItemsPerNode-1))
        {
            pos = node._bitmap ? bsr(node._bitmap) + 1 : 0;
        }
        else
        {
            node = makeNode();
            if ( !_last_node )
            {
                assert(!_first_node);
                _first_node = _last_node = node;
            }
            else
            {
                node._prev_node = _last_node;
                _last_node._next_node = node;
                _last_node = node;
            }
            _nodes_counter++;
            pos = 0;
        }
        node._count++;
        // take most significant free bit
        node.mark_bit(pos);
        node._items[pos] = v;
        _count++;
    }
    private bool _doRealInsert(V)(Node* node, int index, V v)
    {
        int pos;
        if (node is null)
        {
            assert(_first_node is null && _last_node is null, "head and tail must be null");
            node = makeNode();
            pos = NewItemPosition;
            _first_node = _last_node = node;
            _nodes_counter++;
        }
        else
        {
            pos   = node.translate_pos(index);
        }

        int lo_mask = node._lo_mask(pos);
        int hi_mask = node._hi_mask(pos);

        int lo_shift = lo_mask != 0 ? bsf(lo_mask ^ uint.max) :
                        pos == 0 ? -1 : 0;
        int hi_shift = hi_mask == 0 ? uint.max : bsf(hi_mask ^ uint.max);
        auto lo_overflow = lo_shift < hi_shift  && lo_shift >= pos;
        auto hi_overflow = hi_shift <= lo_shift && pos + hi_shift >= ItemsPerNode;

        // debug infof("itemPos: %s", pos);
        // debug infof("index: %s", index);
        // debug infof("bitmap %32.32b", node._bitmap);
        // debug infof("lomask %32.32b", lo_mask);
        // debug infof("himask %32.32b", hi_mask);
        // debug infof("lo_shift: %d, hi shift: %d", lo_shift, hi_shift);
        // debug infof("lo_over:  %s, hi overfl: %s", lo_overflow, hi_overflow);
        if ( lo_overflow )
        {
            debug(ikodcontainers) tracef("low overflow");
            if ( node._prev_node
                && node._prev_node.count_free_high_bits() > 0 )
            {
                Node* n = node._prev_node;
                debug(ikodcontainers) tracef("low overflow to existent node with %s free high bits", n.count_free_high_bits());
                // find free bit _0000100000^ _111v1111^
                int fp = n._bitmap ? bsf(bitswap(n._bitmap)) : NewItemPosition;
                debug(ikodcontainers) tracef("overflow to %s", ItemsPerNode - fp);
                int p = ItemsPerNode - fp;
                n._count++;
                n.mark_bit(p);
                n._items[p] = node._items[0];
                // now do shift left for lo_shift-1
                for(int i=0;i < lo_shift - 1; i++)
                {
                    node._items[i] = node._items[i+1];
                }
                node._items[index-1] = v;
                _count++;
                return true;
            }
            else
            {
                debug(ikodcontainers) tracef("low overflow to new node");
                auto new_node = makeNode();
                auto new_p = NewItemPosition;
                new_node.mark_bit(new_p);
                new_node._items[new_p] = node._items[0];
                new_node._count = 1;
                for(int i=0;i < lo_shift - 1; i++)
                {
                    node._items[i] = node._items[i+1];
                }
                node._items[index-1] = v;
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
                _count++;
                _nodes_counter++;
                return true;
            }
        }
        if ( hi_overflow )
        {
            debug(ikodcontainers) tracef("high overflow");
            if (node._next_node && node._next_node.count_free_low_bits() > 0)
            {
                debug(ikodcontainers) tracef("high overflow to next existent node");
                auto next_node = node._next_node;
                auto next_node_pos = next_node._bitmap ? bsf(next_node._bitmap)-1 : NewItemPosition;
                next_node.mark_bit(next_node_pos);
                next_node._count++;
                next_node._items[next_node_pos] = node._items[ItemsPerNode-1];
                for(auto s=hi_shift; s>0; s--)
                {
                    node._items[pos+s-1] = node._items[pos+s-2];
                }
                node._items[pos] = v;
                _count++;
                return true;
            }
            else
            {
                debug(ikodcontainers) tracef("high overflow to new node");
                auto new_node = makeNode();
                auto new_p = NewItemPosition;
                new_node.mark_bit(new_p);
                new_node._items[new_p] = node._items[ItemsPerNode-1];
                new_node._count++;
                for(auto s=hi_shift; s>0; s--)
                {
                    node._items[pos+s-1] = node._items[pos+s-2];
                }
                node._items[pos] = v;
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
                _nodes_counter++;
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
        if ( lo_shift == -1 )
        {
            // +-- insert here
            // v
            // XXXXXXXX
            if ( node._prev_node )
            {
                immutable fhb = node._prev_node.count_free_high_bits();
                if ( fhb>0 )
                {
                    // we can store it in prev node
                    node = node._prev_node;
                    auto new_p = ItemsPerNode - fhb;
                    assert(!node.test_bit(new_p));
                    node.mark_bit(new_p);
                    node._items[new_p] = v;
                    node._count++;
                    _count++;
                    return true;
                }
            }
            auto new_node = makeNode();
            auto new_p = NewItemPosition;
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
            _nodes_counter++;
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
    /++
    + Insert item at position i. O(N)
    +
    + Params:
    + v = value to insert
    + i = position for this value
    +
    + Returns: True if item were inserted (false if index is > list.length+1)
    + Throws: AssertError if any const range is registered.
    +/
    bool insert(V)(int i, V v)
    {
        assert(_constRanges_counter == 0, "You can't mutate list while there are active const ranges");
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
        auto  ni    = _node_and_index(i);
        int   index = ni.index;
        Node* node  = ni.node;

        if ( _mutRanges_counter>0)
            sendnotify(Sig.INSERT, i, node, index);

        return _doRealInsert(node, index, v);
    }
}
@("ul0")
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

@("mutIterator1")
unittest
{
    import std.stdio;
    import std.range;
    import std.exception;
    import std.math;

    UnrolledList!int l;

    foreach(i; 0..50)
    {
        l.pushBack(i);
    }
    auto r = l.mutRange(1, -1);
    foreach(v; r)
    {
        assert(v>=0);
    }
    r = l.mutRange();
    while(!r.empty)
    {
        auto v = r.front;
        if ( v % 2 )
        {
            r.remove();
        }
        else
        {
            r.popFront;
        }
    }
    assert(equal(l.constRange,iota(0, 50, 2)));
    l.clear;
    //
    // Build Eratosphenes seed, compare with correct list and clear it
    //
    enum limit = 100_500;
    uint[] sieve(in uint limit) nothrow @safe {
        // https://rosettacode.org/wiki/Sieve_of_Eratosthenes#Simpler_Version
        if (limit < 2)
            return [];
        auto composite = new bool[limit];
    
        foreach (immutable uint n; 2 .. cast(uint)(limit ^^ 0.5) + 1)
            if (!composite[n])
                for (uint k = n * n; k < limit; k += n)
                    composite[k] = true;
    
        return iota(2, limit).filter!(i => !composite[i]).array;
    }
    foreach(i; 2..limit)
    {
        l.pushBack(i);
    }
    foreach(index,value; l.mutRange(0, cast(int)sqrt(real(limit))+1).enumerate)
    {
        for(auto r1 = l.mutRange(cast(int)index); !r1.empty;)
        {
            if (r1.front > value && r1.front % value == 0)
            {
                r1.remove;
            }
            else
            {
                r1.popFront;
            }
        }
    }
    // foreach(s; l.dump)
    // {
    //     info(s);
    // }
    assert(equal(l.constRange, sieve(limit)));
    l.popFront;
    l.popBack;
    r = l.mutRange();
    while(!r.empty)
    {
        r.remove();
    }
    assert(r.empty);
    assert(r.count == 0);
    assert(l.length == 0);
    //
    // test popFront/popBack handling by mutRange
    foreach(i; 0..50)
    {
        l.pushBack(i);
    }
    // foreach(s; l.dump)
    // {
    //     info(s);
    // }
    r = l.mutRange();
    while(!l.empty)
    {
        l.popFront;
        l.popBack;
        assertThrown!AssertError(r.front); // you tried to access deleted item
        r.popFront;
        assert(equal(r, l.constRange));
    }
}
@("mutIterator2")
unittest
{
    import std.stdio;
    import std.range;
    import std.exception;

    auto l = UnrolledList!int();
    foreach(i; iota(1, 50, 2))
    {
        l.pushBack(i);
    }
    assert(equal(l.constRange(0, 5), [1,3,5,7,9]));
    auto r0 = l.mutRange();
    auto r1 = r0;
    // foreach(s; l.dump)
    // {
    //     info(s);
    // }
    while(!r0.empty)
    {
        // infof("---insert %s", r0.front-1);
        r0.insert(r0.front - 1);
        r0.popFront;
    }
    assert(equal(l.constRange(0, 5), [0,1,2,3,4]));
    assert(equal(l.constRange(), iota(50)));
    // foreach(s; l.dump)
    // {
    //     info(s);
    // }
    // while(!r1.empty)
    // {
    //     writeln(r1.front);
    //     r1.popFront;
    // }
    assert(equal(r1, iota(1,50)));
    assert(equal(l.constRange, iota(50)));
    r0 = l.mutRange();
    while(!r0.empty)
    {
        // infof("front %s", r0.front);
        if ( r0.front % 2 == 0)
        {
            // infof("remove %s", r0.front);
            r0.remove();
        }
        else
        {
            r0.popFront;
        }
        // foreach(s; l.dump)
        // {
        //     info(s);
        // }
    }
    assert(equal(r1, iota(1, 50, 2)));
    r0 = l.mutRange();
    int x = 0;
    while(!r0.empty)
    {
        // infof("---insert %s", x);
        r0.insert(x);
        x += 2;
        r0.popFront;
        // foreach(s; l.dump)
        // {
        //     info(s);
        // }
    }
    assert(equal(l.constRange(), iota(50)));
    // while(!r1.empty)
    // {
    //     writeln(r1.front);
    //     r1.popFront;
    // }
    assert(equal(r1, iota(1, 50)));
}
@("mutIterator3")
unittest
{
    import std.stdio;
    import std.range;
    import std.exception;
    import std.random;
    auto rnd = Random(19);

    auto l = UnrolledList!int();
    while(l.length < 5)
    {
        int v = uniform(0, 10000, rnd);
        auto i = l.mutRange();
        while(!i.empty && i.front > v)
        {
            i.popFront;
        }
        i.insert(v);
    }
}

@("constIterator")
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
    auto r = l.constRange();
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
    r = l.constRange();
    auto r1 = r;
    r.reset();
    assert(equal(r1.take(10), iota(10))); // still can use r1
    r1 = l.constRange();
    r1 = r1;
    r.reset();
    assert(l._constRanges_counter == 1); // r1 only
    assert(equal(r1, iota(50)));
    // test negative indexing
    assert(equal(l.constRange(25), iota(25,50)));
    assert(l.constRange(-3, -3).count == 0);
    assertThrown!AssertError(l.constRange(0, -10000));
    assert(l._constRanges_counter == 1); // r1 only, temp ranges unregistered

    r = l.constRange();
    assert(l._constRanges_counter == 2); // r and r1
    foreach(i, v; r.enumerate)
    {
        r1 = l.constRange(cast(int)i, 50);
        assert(equal(r1, iota(i, 50)));
    }
    r1.reset();
    r.reset();
    assert(l._constRanges_counter == 0); // we cleared everything

    // test unregister on list destruction
    {
        UnrolledList!int l1;
        foreach(i; 0..50)
        {
            l1.pushBack(i);
        }
        r1 = l1.constRange();
        assert(r1.count == 50);
        foreach(i,v; r1.enumerate)
        {
            auto r2 = l1.constRange(cast(int)i);
            assert(equal(r2, iota(i, 50)));
        }
        assert(r1.count == 50);
    }
    assert(r1.count == 0); // lost container
    r = l.constRange();
    assertThrown!AssertError(l.clear);
    while(!r.empty)
    {
        r.popFront;
    }
    l.clear;

    foreach(i; 0..50)
    {
        l.pushBack(i);
    }
    r = l.constRange();
    assertThrown!AssertError(l.clear);
    foreach(i; r)
    {
        assert(i>=0);
    }
    // iterator consumed by opApply
    l.clear;
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
    auto r = l.constRange;
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
    auto r = l.constRange;
    assert(equal(r.map!(s => s.s), iota(50)));
}