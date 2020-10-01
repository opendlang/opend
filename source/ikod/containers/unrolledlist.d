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

private import ikod.containers.internal;

struct UnrolledList(T, Allocator = Mallocator, bool GCRangesAllowed = true)
{
private:
    alias allocator = Allocator.instance;
    alias StoredT = StoredType!T;
    enum ItemsPerNode = 32; // can be variable maybe

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
        void mark_bit(size_t n) pure @safe @nogc
        {
            debug assert(n < ItemsPerNode, format("%s must be less than %d", n, ItemsPerNode));
            _bitmap |= 1 << n;
        }
        void clear_bit(size_t n) pure @safe @nogc nothrow
        {
            assert(n < ItemsPerNode);
            _bitmap &= uint.max ^ (1 << n);
        }
        bool test_bit(size_t n) pure @safe @nogc
        {
            debug assert(n < ItemsPerNode, "%d must be < %d".format(n, ItemsPerNode));
            return (_bitmap & (1 << n)) != 0;
        }
        int translate_pos(size_t n) @safe @nogc
        out(result; result == -1 || result < ItemsPerNode)
        {
            int p = 0;
            int mask = 1;
            int result = -1;
            foreach(i; 0..ItemsPerNode)
            {
                immutable v = _bitmap & mask;
                mask <<= 1;
                if (!v) continue;
                if (p == n)
                {
                    result = i;
                    break;
                }
                p++;
            }
            return result;
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

public:
    @disable this(ref typeof(this));
    ~this()
    {
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
    // O(N)
    auto get(size_t i)
    {
        if (_count == 0 || i >= _count )
        {
            return Tuple!(bool, "ok", T, "value")(false, T.init);
        }
        auto ni = _node_and_index(i);
        auto n = ni.node;
        auto pos = n.translate_pos(ni.index);
        assert(n.test_bit(pos));
        return Tuple!(bool, "ok", T, "value")(true, n._items[pos]);
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
    void opIndexAssign(T v, size_t i)
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
        if ( _count == 0 )
        {
            return Tuple!(bool, "ok", T, "value")(false, T.init);
        }
        auto p = bsf(_first_node._bitmap);
        return Tuple!(bool, "ok", T, "value")(true, _first_node._items[p]);
    }
    // O(1)
    auto back()
    {
        if ( _count == 0 )
        {
            return Tuple!(bool, "ok", T, "value")(false, T.init);
        }
        auto p = bsr(_last_node._bitmap);
        return Tuple!(bool, "ok", T, "value")(true, _last_node._items[p]);
    }
    // O(1)
    void pushBack(T v)
    {
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
    // O(1)
    void pushFront(T v)
    {
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
    // O(1)
    void popFront()
    {
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
    // O(1)
    void popBack()
    {
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
    // O(N)
    bool remove(size_t i)
    {
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
    bool insert(size_t i, T v)
    {
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
            //| (((1<<(pos)) - 1)^uint.max);
        int hi_mask = (node._bitmap >> pos);
            //| (((1<<(int.sizeof*8-pos)) - 1)^uint.max);
        uint lo_shift = bsf(lo_mask ^ uint.max);
        uint hi_shift = bsf(hi_mask ^ uint.max);
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
            assert(!node.test_bit(pos-1));
            node._count++;
            node._items[pos-1] = v;
            node.mark_bit(pos-1);
            _count++;
            return true;
        }
        if ( lo_shift < hi_shift )
        {
            // shift to low items
            auto new_pos = pos-lo_shift - 1;
            for(auto s=0; s<lo_shift+1; s++)
            {
                node._items[new_pos+s] = node._items[new_pos+s+1];
            }
            node.mark_bit(new_pos);
            node._count++;
            node._items[pos-1] = v;
            // node.mark_bit(pos);
            _count++;
            return true;
        }
        else
        {
            // shift to hight items
            auto new_pos = pos+hi_shift;
            for(auto s=hi_shift; s>0; s--)
            {
                node._items[pos+s] = node._items[pos+s-1];
            }
            node.mark_bit(new_pos);
            node._count++;
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
    assert(list.front.value == 1);
    assert(list.back.value == 1);
    list.pushFront(0);
    assert(list.length == 2);
    assert(list.front.value == 0);
    assert(list.back.value == 1);
    list.pushBack(2);
    assert(list.length == 3);
    assert(list.front.value == 0);
    assert(list.back.value == 2);
    list.pushBack(3);
    assert(list.length == 4);
    assert(list.front.value == 0);
    assert(list.back.value == 3);

    list.popFront();
    assert(list.length == 3);
    assert(list.front.value == 1);
    assert(list.back.value == 3);
    list.popFront();
    assert(list.length == 2);
    assert(list.front.value == 2);
    assert(list.back.value == 3);
    list.popFront();
    assert(list.length == 1);
    assert(list.front.value == 3);
    assert(list.back.value == 3);
    list.popFront();
    assert(list.empty);
    foreach(int i; 0..1000)
    {
        list.pushBack(i);
    }
    assert(list.length == 1000);
    assert(list.front.value == 0, "<%s>".format(list.front));
    assert(list.back.value == 999, "<%s>".format(list.back));
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
    assert(list.back.value == list.ItemsPerNode-2);
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
    assert(l.front.ok == true && l.front.value == 0);
    assert(l.back.ok == true && l.back.value == 0);
    l.pushBack(1);
    assert(l.length == 2);
    assert(l.front.ok == true && l.front.value == 0);
    assert(l.back.ok == true && l.back.value == 1);
    l.pushFront(2);
    assert(l.length == 3);
    assert(l.front.ok == true && l.front.value == 2);
    assert(l.back.ok == true && l.back.value == 1);
    l.pushFront(3);
    assert(l.length == 4);
    assert(l.front.ok == true && l.front.value == 3);
    assert(l.back.ok == true && l.back.value == 1);
    l.popBack();
    assert(l.length == 3);
    assert(l.front.ok == true && l.front.value == 3);
    assert(l.back.ok == true && l.back.value == 0);
    l.popBack();
    assert(l.length == 2);
    assert(l.front.ok == true && l.front.value == 3);
    assert(l.back.ok == true && l.back.value == 2);
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
