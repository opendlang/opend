module ikod.containers.compressedlist;

private import core.memory;

private import std.experimental.allocator;
private import std.experimental.allocator.mallocator : Mallocator;
private import std.experimental.allocator.gc_allocator;
private import std.experimental.logger;
private import std.format;
private import std.algorithm;

private import ikod.containers.internal;

private byte useFreePosition(ubyte[] m) @safe @nogc nothrow
{
    import core.bitop: bsf;
    //
    // find free position, mark it as used and return it
    // least significant bit in freeMap[0] means _nodes[0]
    // most significant bit in freeMap[$-1] means nodes[$-1]
    //
    auto l = m.length;
    for(uint i=0; i < l;i++)
    {
        ubyte v = m[i];
        if ( v < 255 )
        {
            auto p = bsf(v ^ 0xff);
            m[i] += 1 << p;
            return cast(byte)((i<<3)+p);
        }
    }
    assert(0);
}
private void markFreePosition(ubyte[] m, size_t position) @safe @nogc nothrow
{
    auto p = position >> 3;
    auto b = position & 0x7;
    m[p] &= (1<<b)^0xff;
}

private bool isFreePosition(ubyte[] m, size_t position) @safe @nogc nothrow
{
    auto p = position >> 3;
    auto b = position & 0x7;
    return (m[p] & (1<<b)) == 0;
}
private ubyte countBusy(ubyte[] m) @safe @nogc nothrow
{
    import core.bitop;
    ubyte s = 0;
    foreach(b; m)
    {
        s+=popcnt(b);
    }
    return s;
}
@safe unittest
{
    globalLogLevel = LogLevel.info;
    import std.algorithm.comparison: equal;
    ubyte[] map = [0,0];
    auto p = useFreePosition(map);
    assert(p == 0, "expected 0, got %s".format(p));
    assert(map[0] == 1);
    assert(!isFreePosition(map, 0));
    assert(isFreePosition(map, 1));

    p = useFreePosition(map);
    assert(p == 1, "expected 1, got %s".format(p));
    map = [255,0];
    p = useFreePosition(map);
    assert(p == 8, "expected 8, got %s".format(p));
    assert(map[1] == 1);
    map = [255,0x01];
    p = useFreePosition(map);
    assert(p == 9, "expected 9, got %s".format(p));
    assert(equal(map, [0xff, 0x03]));
    markFreePosition(map, 8);
    assert(equal(map, [0xff, 0x02]), "got %s".format(map));
    markFreePosition(map, 9);
    assert(equal(map, [0xff, 0x00]), "got %s".format(map));
    markFreePosition(map, 0);
    assert(equal(map, [0xfe, 0x00]), "got %s".format(map));
}

///
/// Unrolled list
///
struct CompressedList(T, Allocator = Mallocator, bool GCRangesAllowed = true)
{
    alias allocator = Allocator.instance;
    alias StoredT = StoredType!T;
    //enum MAGIC = 0x00160162;
    enum PageSize = 512;    // in bytes
    enum NodesPerPage = PageSize/Node.sizeof;
    static assert(NodesPerPage >= 1, "Node is too large to use this List, use DList instead");
    static assert(NodesPerPage <= 255, "Strange, but Node size is too small to use this List, use DList instead");

    enum BitMapLength = NodesPerPage % 8 ? NodesPerPage/8+1 : NodesPerPage/8;

    ///
    /// unrolled list with support only for:
    /// 1. insert/delete front
    /// 2. insert/delete back
    /// 3. keep unstable "pointer" to arbitrary element
    /// 4. remove element by pointer

    struct Page {
        ///
        /// Page is fixed-length array of list Nodes
        /// with batteries
        ///
        //uint                _magic = MAGIC;
        //uint                _epoque;    // increment each time we move to freelist
        ubyte[BitMapLength] _freeMap;
        Page*               _prevPage;
        Page*               _nextPage;
        byte                _firstNode;
        byte                _lastNode;
        ubyte               _count;      // nodes counter
        Node[NodesPerPage]  _nodes;
    }

    struct Node {
        StoredT v;
        byte    p; // prev index
        byte    n; // next index
    }

    // struct NodePointer {
    //     private
    //     {
    //         Page*   _page;
    //         byte    _index;
    //     }
    //     this(Page* page, byte index)
    //     {
    //         //_epoque = page._epoque;
    //         _page = page;
    //         _index = index;
    //     }
    //     ///
    //     /// This is unsafe as you may refer to deleted node.
    //     /// You are free to wrap it in @trusted code if you know what are you doing.
    //     ///
    //     T opUnary(string s)() @system if (s == "*")
    //     {
    //         assert(_page !is null);
    //         //assert(_page._magic == MAGIC, "Pointer resolution to freed or damaged page");
    //         //assert(_page._epoque == _epoque, "Page were freed");
    //         assert(!isFreePosition(_page._freeMap, _index), "you tried to access already free list element");
    //         return _page._nodes[_index].v;
    //     }
    // }

    struct Range {
        private Page* page;
        private byte  index;

        T front() @safe {
            if ( page !is null && index == -1)
            {
                index = page._firstNode;
            }
            return page._nodes[index].v;
        }
        void popFront() @safe {
            if ( page !is null && index == -1)
            {
                index = page._firstNode;
            }
            index = page._nodes[index].n;
            if ( index != -1 )
            {
                return;
            }
            page = page._nextPage;
            if ( page is null )
            {
                return;
            }
            index = page._firstNode;
        }
        bool empty() const @safe {
            return page is null;
        } 
    }
    /// Iterator over items.
    Range range() @safe {
        return Range(_pages_first, -1);
    }
    private
    {
        Page*   _pages_first, _pages_last;
        ulong   _length;

        static  Page*   _freelist;
        static int     _freelist_len;
        static enum    _freelist_len_max = 100;
    }
    this(this) @safe
    {
        auto r = range();
        _pages_first = _pages_last =null;
        _length = 0;
        foreach(e; r) {
            insertBack(e);
        }
    }
    private void move_to_freelist(Page* page) @safe @nogc {
        if ( _freelist_len >= _freelist_len_max )
        {
            debug(cachetools) safe_tracef("dispose page");
            () @trusted {
                static if ( UseGCRanges!(Allocator,T, GCRangesAllowed) ) {
                    GC.removeRange(&page._nodes[0]);
                }
                dispose(allocator, page);
            }();
            return;
        }
        debug(cachetools) safe_tracef("put page in freelist");
        //page._epoque++;
        page._nextPage = _freelist;
        _freelist = page;
        _freelist_len++;
    }

    private Page* peek_from_freelist() @safe {
        if ( _freelist is null )
        {
            Page* page = make!Page(allocator);
            static if ( UseGCRanges!(Allocator, T, GCRangesAllowed) ) {
                () @trusted {
                    GC.addRange(&page._nodes[0], Node.sizeof * NodesPerPage);
                }();
            }
            _freelist = page;
            _freelist_len = 1;
        }
        Page* p = _freelist;
        _freelist = p._nextPage;
        _freelist_len--;
        assert(_freelist_len>=0 && _freelist_len < _freelist_len_max);
        p._nextPage = p._prevPage = null;
        p._firstNode = p._lastNode = -1;
        return p;
    }

    ~this() @safe {
        clear();
    }

    /// remove anything from list
    void clear() @safe {
        _length = 0;
        Page* page = _pages_first, next;
        while(page)
        {
            next = page._nextPage;
            *page = Page();
            move_to_freelist(page);
            page = next;
        }
        _length = 0;
        _pages_first = _pages_last = null;
    }

    /// Is list empty?
    bool empty() @safe const {
        return _length == 0;
    }

    /// Items in the list.
    ulong length() @safe const {
        return _length;
    }

    // /// remove node (by 'Pointer')
    // void remove(ref NodePointer p) @system {
    //     if ( empty )
    //     {
    //         assert(0, "Tried to remove from empty list");
    //     }
    //     _length--;
    //     Page *page = p._page;
    //     byte index = p._index;
    //     assert(!isFreePosition(page._freeMap, index), "you tried to remove already free list element");
    //     with (page)
    //     {
    //         assert(_count>0);
    //         _count--;
    //         // unlink from list
    //         auto next = _nodes[index].n;
    //         auto prev = _nodes[index].p;
    //         if ( prev >= 0)
    //         {
    //             _nodes[prev].n = next;
    //         }
    //         else
    //         {
    //             _firstNode = next;
    //         }
    //         if ( next >= 0)
    //         {
    //             _nodes[next].p = prev;
    //         }
    //         else
    //         {
    //             _lastNode = prev;
    //         }
    //         //_nodes[index].n = _nodes[index].p = -1;
    //         markFreePosition(_freeMap, index);
    //     }
    //     if ( page._count == 0 )
    //     {
    //         // relase this page
    //         if ( _pages_first == page )
    //         {
    //             assert(page._prevPage is null);
    //             _pages_first = page._nextPage;
    //         }
    //         if ( _pages_last == page )
    //         {
    //             assert(page._nextPage is null);
    //             _pages_last = page._prevPage;
    //         }
    //         if ( page._nextPage !is null )
    //         {
    //             page._nextPage._prevPage = page._prevPage;
    //         }
    //         if ( page._prevPage !is null )
    //         {
    //             page._prevPage._nextPage = page._nextPage;
    //         }
    //         move_to_freelist(page);
    //     }
    //     // at this point page can be disposed
    // }

    /// List front item
    T front() @safe {
        if ( empty )
        {
            assert(0, "Tried to access front of empty list");
        }
        Page* p = _pages_first;
        assert( p !is null);
        assert( p._count > 0 );
        with(p)
        {
            return _nodes[_firstNode].v;
        }
    }

    /// Pop front item
    void popFront() @safe {
        if ( empty )
        {
            assert(0, "Tried to popFront from empty list");
        }
        _length--;
        Page* page = _pages_first;
        //debug(cachetools) safe_tracef("popfront: page before: %s", *page);
        assert(page !is null);
        with (page) {
            assert(_count>0);
            assert(!isFreePosition(_freeMap, _firstNode));
            auto first = _firstNode;
            auto next = _nodes[first].n;
            markFreePosition(_freeMap, first);
            if ( next >= 0 )
            {
                _nodes[next].p = -1;
            }
            //_nodes[first].n = _nodes[first].p = -1;
            _count--;
            _firstNode = next;
        }
        if ( page._count == 0 )
        {
            // relase this page
            _pages_first = page._nextPage;
            move_to_freelist(page);
            if ( _pages_first is null )
            {
                _pages_last = null;
            }
            else
            {
                _pages_first._prevPage = null;
            }
        }
        debug(cachetools) safe_tracef("popfront: page after: %s", *page);
    }

    /// Insert item at front.
    void insertFront(T v) {
        _length++;
        Page* page = _pages_first;
        if ( page is null )
        {
            page = peek_from_freelist();
            _pages_first = _pages_last = page;
        }
        if (page._count == NodesPerPage)
        {
            Page* new_page = peek_from_freelist();
            new_page._nextPage = page;
            page._prevPage = new_page;
            _pages_first = new_page;
            page = new_page;
        }
        // there is free space
        auto index = useFreePosition(page._freeMap);
        assert(index < NodesPerPage);
        Node nn = Node(v, -1, page._firstNode);
        move(nn, page._nodes[index]);
        if (page._count == 0)
        {
            page._firstNode = page._lastNode = cast(ubyte)index;
        }
        else
        {
            assert(page._firstNode >= 0);
            assert(!isFreePosition(page._freeMap, page._firstNode));
            page._nodes[page._firstNode].p = cast(ubyte)index;
            page._firstNode = cast(ubyte)index;
        }
        page._count++;
        assert(page._count == countBusy(page._freeMap));
        debug(cachetools) safe_tracef("page after insert front: %s", *page);
        return;
    }

    /// List back item.
    T back() @safe {
        if ( empty )
        {
            assert(0, "Tried to access back of empty list");
        }
        Page* p = _pages_last;
        assert( p !is null);
        assert( p._count > 0 );
        //debug(cachetools) safe_tracef("page: %s", *p);
        with(p)
        {
            return _nodes[_lastNode].v;
        }
    }

    /// Pop back item from list.
    void popBack() @safe {
        if ( empty )
        {
            assert(0, "Tried to popBack from empty list");
        }
        _length--;
        Page* page = _pages_last;
        assert(page !is null);
        with (page) {
            assert(_count>0);
            assert(!isFreePosition(_freeMap, _lastNode));
            auto last = _lastNode;
            auto prev = _nodes[last].p;
            markFreePosition(_freeMap, last);
            if ( prev >=0 )
            {
                _nodes[prev].n = -1;
            }
            //_nodes[last].n = _nodes[last].p = -1;
            _count--;
            _lastNode = prev;
        }
        if ( page._count == 0 )
        {
            debug(cachetools) safe_tracef("release page");
            // relase this page
            _pages_last = page._prevPage;
            move_to_freelist(page);
            if ( _pages_last is null )
            {
                _pages_first = null;
            }
            else
            {
                _pages_last._nextPage = null;
            }
        }
    }

    /// Insert item back.
    void insertBack(T v) {
        _length++;
        Page* page = _pages_last;
        if ( page is null )
        {
            page = peek_from_freelist();
            _pages_first = _pages_last = page;
        }
        if (page._count == NodesPerPage)
        {
            Page* new_page = peek_from_freelist();
            new_page._prevPage = page;
            page._nextPage = new_page;
            _pages_last = new_page;
            page = new_page;
        }
        // there is free space
        auto index = useFreePosition(page._freeMap);
        assert(index < NodesPerPage);
        Node nn = Node(v, page._lastNode, -1);
        move(nn, page._nodes[index]);
        if (page._count == 0)
        {
            page._firstNode = page._lastNode = cast(ubyte)index;
        }
        else
        {
            assert(page._lastNode >= 0);
            assert(!isFreePosition(page._freeMap, page._lastNode));
            page._nodes[page._lastNode].n = cast(ubyte)index;
            page._lastNode = cast(ubyte)index;
        }
        page._count++;
        assert(page._count == countBusy(page._freeMap));
        //debug(cachetools) safe_tracef("page: %s", *page);
        return;
    }
}

///
@safe unittest
{
    import std.experimental.logger;
    import std.algorithm;
    import std.range;

    globalLogLevel = LogLevel.info;
    CompressedList!int list;
    foreach(i;0..66)
    {
        list.insertFront(i);
        assert(list.front == i);
    }
    assert(list.length == 66);
    assert(list.back == 0);
    list.popFront();
    assert(list.length == 65);
    assert(list.front == 64);
    list.popFront();
    assert(list.length == 64);
    assert(list.front == 63);
    while( !list.empty )
    {
        list.popFront();
    }
    foreach(i;1..19)
    {
        list.insertFront(i);
        assert(list.front == i);
    }
    foreach(i;1..19)
    {
        assert(list.back == i);
        assert(list.length == 19-i);
        list.popBack();
    }
    assert(list.empty);
    list.insertBack(99);
    assert(list.front == 99);
    assert(list.back == 99);
    list.insertBack(100);
    assert(list.front == 99);
    assert(list.back == 100);
    list.insertFront(98);
    list.insertBack(101);
    () @trusted // * and remove for poiners is unsafe
    {
        list.clear();
        assert(list.empty);

        foreach(i;0..1000)
        {
            list.insertBack(i);
        }
        assert(equal(list.range(), iota(0,1000)));
        list.clear();

        assert(list.empty);
        iota(0, 1000).each!(i => list.insertBack(i));
        auto r = list.range();
        while(!r.empty)
        {
            int v = r.front;
            r.popFront();
        }
        assert(list.length == 1000, "expected empty list, got length %d".format(list.length));
    }();

    () @nogc
    {
        struct S {}
        CompressedList!(immutable S) islist;
        immutable S s = S();
        islist.insertFront(s);
    }();
    class C
    {
        int c;
        this(int v) {
            c = v;
        }
    }
    CompressedList!C clist;
    foreach(i;0..5000)
    {
        clist.insertBack(new C(i));
    }
    foreach(i;0..4500)
    {
        clist.popBack();
    }
    assert(clist.length == 500);
    clist.clear();
}

// unittest for unsafe types
unittest {
    import std.variant;
    alias T = Algebraic!(int, string);
    auto v = T(1);
    CompressedList!T cl;
    cl.insertFront(v);
    assert(cl.front == v);
    cl.insertBack(v);
    cl.popFront;
    cl.popBack;
}

@safe @nogc unittest {
    import std.range, std.algorithm;
    CompressedList!int a, b;
    iota(0,100).each!(e => a.insertBack(e));
    a.popFront();
    b = a;
    assert(equal(a, b));
}