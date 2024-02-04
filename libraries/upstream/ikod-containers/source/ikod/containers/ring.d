module ikod.containers.ring;

private import std.typecons;
private import core.bitop;

private import std.experimental.allocator;
private import std.experimental.allocator.mallocator : Mallocator;
private import std.experimental.allocator.gc_allocator;

version(TestingContainers) {
    import ut;
}

struct Ring(T, alias N, Allocator = Mallocator, bool GCRangesAllowed = true)
{
    static if (popcnt(N) == 1)
    {
        enum _useMask = true;
        enum _mask = N - 1;
    }
    else
    {
        enum _useMask = false;
    }
    public
    {
        enum OverflowPolicy
        {
            DROP,
            OVERWRITE,
            ERROR
        }
        enum PutStatus
        {
            OK,
            DROPPPED,
            OVERWRITTEN,
            ERROR
        }
        enum GetStatus
        {
            OK,
            EMPTY
        }
    }
    private
    {
        alias allocator = Allocator.instance;
        T[]                 _buffer;
        immutable size_t    _size = N;
        size_t              _head, _tail, _length; // write to head, read from tail
        OverflowPolicy      _overflow_policy = OverflowPolicy.ERROR;
    }
    void init(OverflowPolicy p = OverflowPolicy.ERROR)
    {
        _buffer = makeArray!(T)(allocator, _size);
        _overflow_policy = p;
    }
    ~this() @trusted
    {
        if (_buffer)
        {
            dispose(allocator, &_buffer[0]);
        }
    }
    auto put(T)(T item)
    {
        if (_length == _size)
        {
            final switch(_overflow_policy)
            {
                case OverflowPolicy.ERROR:
                    return PutStatus.ERROR;
                case OverflowPolicy.DROP:
                    return PutStatus.DROPPPED;
                case OverflowPolicy.OVERWRITE:
                    _buffer[_head] = item;
                    static if(_useMask)
                    {
                        _head = (_head + 1) & _mask;
                        _tail = (_tail + 1) & _mask;
                    }
                    else
                    {
                        _head = (_head+1) % N;
                        _tail = (_tail+1) % N;
                    }
                    return PutStatus.OVERWRITTEN;
            }
        }
        _buffer[_head] = item;
        _length++;
        static if (_useMask)
        {
            _head = (_head + 1) & _mask;
        }
        else
        {
            _head = (_head+1) % N;
        }
        return PutStatus.OK;
    }
    auto get()
    {
        if (_length == 0)
        {
            return tuple!("status", "value")(GetStatus.EMPTY, T.init);
        }
        auto r = tuple!("status", "value")(GetStatus.OK, _buffer[_tail]);
        static if(_useMask)
        {
            _tail = (_tail + 1) & _mask;
        }
        else
        {
            _tail = (_tail+1) % N;
        }
        _length--;
        return r;
    }
    auto length()
    {
        return _length;
    }
    auto empty()
    {
        return _length == 0;
    }
    auto full()
    {
        return _length == N;
    }
}

@("basic")
@safe unittest
{
    import std.algorithm;
    import std.range;

    Ring!(int, 10) ring;
    ring.init();
    assert(ring.empty);
    auto p = ring.put(1);
    assert(p == ring.PutStatus.OK);
    assert(!ring.empty);
    assert(!ring.full);
    auto g = ring.get();
    assert(g.status == ring.GetStatus.OK);
    assert(g.value == 1);
    assert(ring.empty);
    foreach(i;0..10)
    {
        p = ring.put(i);
        assert(p == ring.PutStatus.OK);
    }
    assert(ring.full);
    assert(ring.length == 10);
    p = ring.put(10);
    assert(p == ring.PutStatus.ERROR);
    int[] a;
    while(!ring.empty)
    {
        a ~= ring.get().value;
    }
    assert(equal(a, iota(10)));
    assert(ring.empty);
}
@("class")
@safe
unittest
{
    class C
    {
        int _i;
        this(int i)
        {
            _i = i;
        }
    }
    Ring!(C, 32) ring;
    ring.init();
    ring.put(new C(1));
}
@("N=32")
unittest
{
    import std.algorithm;
    import std.range;
    enum N = 32;
    Ring!(int, N) ring;
    ring.init();
    assert(ring.empty);
    auto p = ring.put(1);
    assert(p == ring.PutStatus.OK);
    assert(!ring.empty);
    assert(!ring.full);
    auto g = ring.get();
    assert(g.status == ring.GetStatus.OK);
    assert(g.value == 1);
    assert(ring.empty);
    foreach(i;0..N)
    {
        p = ring.put(i);
        assert(p == ring.PutStatus.OK);
    }
    assert(ring.full);
    assert(ring.length == N);
    p = ring.put(N);
    assert(p == ring.PutStatus.ERROR);
    int[] a;
    while(!ring.empty)
    {
        a ~= ring.get().value;
    }
    assert(equal(a, iota(N)));
    assert(ring.empty);
}