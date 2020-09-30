module ikod.containers.hashmap;

version(TestingContainers) {
    import ut;
}

import std.traits;
import std.format;
import std.typecons;
import std.algorithm : map, copy;
import core.memory;
import core.bitop;

import automem: RefCounted, refCounted;

private import std.experimental.allocator;
private import std.experimental.allocator.mallocator : Mallocator;
private import std.experimental.allocator.gc_allocator;

private import ikod.containers.internal;
public  import ikod.containers.hash;

///
class KeyNotFound : Exception {
    ///
    this(string msg = "key not found") @safe {
        super(msg);
    }
}
///
class KeyRemoved : Exception {
    ///
    this(string msg = "key not found") @safe {
        super(msg);
    }
}

private
{
    static if (hash_t.sizeof == 8) {
            enum EMPTY_HASH = 0x00_00_00_00_00_00_00_00;
            enum DELETED_HASH = 0x10_00_00_00_00_00_00_00;
            enum ALLOCATED_HASH = 0x20_00_00_00_00_00_00_00;
            enum TYPE_MASK = 0xF0_00_00_00_00_00_00_00;
            enum HASH_MASK = 0x0F_FF_FF_FF_FF_FF_FF_FF;
    }
    else static if (hash_t.sizeof == 4) {
            enum EMPTY_HASH = 0x00_00_00_00;
            enum DELETED_HASH = 0x10_00_00_00;
            enum ALLOCATED_HASH = 0x20_00_00_00;
            enum TYPE_MASK = 0xF0_00_00_00;
            enum HASH_MASK = 0x0F_FF_FF_FF;
    }
}

private bool keyEquals(K)(K a, K b) {
    static if (is(K == class)) {
        if (a is b) {
            return true;
        }
        if (a is null || b is null) {
            return false;
        }
        return a.opEquals(b);
    }
    else {
        return a == b;
    }
}

@("L" ~ to!string(__LINE__) ~ ".keyEquals")
@safe nothrow unittest {
    class C {
        int c;
        this(int v) {
            c = v;
        }

        bool opEquals(const C other) const nothrow @safe {
            return c == other.c;
        }
    }

    C a = new C(0);
    C b = new C(1);
    C c = a;
    C d = new C(0);
    assert(!keyEquals(a, b));
    assert(keyEquals(a, c));
    assert(keyEquals(a, d));
    assert(!keyEquals(null, a));
    assert(keyEquals(1, 1));
}
///
struct HashMap(K, V, Allocator = Mallocator, bool GCRangesAllowed = true)
{
    static if (hasAliasing!K)
    {
        pragma(msg, "type %s has aliasing and is unsafe as hashmap key".format(K.stringof));
    }
    private enum initial_buckets_num = 32;

    alias StoredKeyType = StoredType!K;
    alias StoredValueType = StoredType!V;

    package {
        alias allocator = Allocator.instance;
        //
        // Bucket is place where we store key, value and hash.
        // High bits of hash are used to distinguish between allocated, removed and
        // empty buckets.
        // Buckets form contigous array. We keep this array refcounted, so that
        // we can store reference to it from byPair, byKey, ... even if hashtable itself cleared or
        // destroyed.
        //
        struct _Bucket {
            hash_t hash;
            StoredKeyType key;
            StoredValueType value;
            string toString() const {
                import std.format;

                return "%s, hash: %0x,key: %s, value: %s".format([
                        EMPTY_HASH: "free",
                        DELETED_HASH: "deleted",
                        ALLOCATED_HASH: "allocated"
                ][cast(long)(hash & TYPE_MASK)], hash, key, value);
            }
        }

        private struct _BucketStorage {

            _Bucket[] bs;
            bool      cow_required;

            this(this) {
                auto newbs = makeArray!(_Bucket)(allocator, bs.length);
                () @trusted {
                    static if (UseGCRanges!(Allocator, K, V, GCRangesAllowed)) {
                        GC.addRange(newbs.ptr, bs.length * _Bucket.sizeof);
                    }
                }();
                copy(bs, newbs);
                bs = newbs;
            }

            this(size_t n) {
                bs = makeArray!(_Bucket)(allocator, n);
                () @trusted {
                    static if (UseGCRanges!(Allocator, K, V, GCRangesAllowed)) {
                        GC.addRange(bs.ptr, n * _Bucket.sizeof);
                    }
                }();
            }

            ~this() {
                if (!bs.length)
                    return;
                () @trusted {
                    static if (UseGCRanges!(Allocator, K, V, GCRangesAllowed)) {
                        GC.removeRange(bs.ptr);
                    }
                }();
                dispose(allocator, bs.ptr);
            }
        }

        private alias BucketStorage = RefCounted!(_BucketStorage, Allocator);

        BucketStorage   _buckets;
        int             _buckets_num;
        int             _mask;
        int             _allocated;
        int             _deleted;
        int             _empty;

        int             _grow_factor = 4;

    }

    ~this() {
        clear();
    }

    this(this) {
        auto obuckets = _buckets;
        _buckets = BucketStorage(_buckets_num);
        if (obuckets !is null)
        {
            copy(obuckets.bs, _buckets.bs);
        }
    }

    void opAssign(ref typeof(this) rhs) {
        //auto kv = rhs.byPair; // this will keep current copy of _buckets[]
        //
        // keep old _buckets_num(to avoid resizes) and _mask;
        //
        if (rhs is this) {
            return;
        }
        _empty = rhs._empty;
        _buckets_num = rhs._buckets_num;
        _allocated = rhs._allocated;
        _deleted = rhs._deleted;
        _mask = rhs._mask;
        _grow_factor = rhs.grow_factor;
        _buckets = BucketStorage(_buckets_num);
        copy(rhs._buckets.bs, _buckets.bs);
    }

    string toString() {
        import std.algorithm: map;
        import std.array: array, join;

        auto pairs = byPair;
        return "[%s]".format(pairs.map!(p => "%s:%s".format(p.key, p.value)).array.join(", "));
    }

    /// dump HashMap content to string
    /// (for debugging)
    string dump()
    {
        import std.array: join;
        string[] str;
        for(int i=0; i<_buckets_num;i++)
        {
            str ~= "[%5.5d][0x%16.16x][%s][%s]".format
                    (i,     _buckets.bs[i].hash, _buckets.bs[i].key, _buckets.bs[i].value);
        }
        return str.join("\n");
    }
    invariant {
        assert(_allocated >= 0 && _deleted >= 0 && _empty >= 0);
        assert(_allocated + _deleted + _empty == _buckets_num);
    }

    // Find allocated bucket for given key and computed hash starting from start_index
    // Returns: index if bucket found or hash_t.max otherwise
    //
    // Inherits @nogc from K opEquals()
    //
    private hash_t findEntryIndex(K)(const hash_t start_index, const hash_t hash, ref K key)
    in {
        assert(hash < DELETED_HASH); // we look for real hash
        assert(start_index < _buckets_num); // start position inside array
    }
    do {
        hash_t index = start_index;

        do {
            immutable h = _buckets.bs[index].hash;

            // debug (cachetools)
            //     safe_tracef("test entry index %d (%s) for key %s", index, _buckets.bs[index], key);

            if (h == EMPTY_HASH) {
                break;
            }

            if (h >= ALLOCATED_HASH && (h & HASH_MASK) == hash
                    && keyEquals(_buckets.bs[index].key, key)) {
                debug (cachetools) safe_tracef("test entry index %d for key %s - success", index, key);
                return index;
            }
            index = (index + 1) & _mask;
        }
        while (index != start_index);
        return hash_t.max;
    }

    private hash_t findEntryIndex(K)(const hash_t start_index, const hash_t hash, ref K key) const
    in {
        assert(hash < DELETED_HASH); // we look for real hash
        assert(start_index < _buckets_num); // start position inside array
    }
    do {
        hash_t index = start_index;

        do {
            immutable h = _buckets.bs[index].hash;

            // debug (cachetools)
            //     safe_tracef("test entry index %d (%s) for key %s", index, _buckets.bs[index], key);

            if (h == EMPTY_HASH) {
                break;
            }

            if (h >= ALLOCATED_HASH && (h & HASH_MASK) == hash
                    && keyEquals(_buckets.bs[index].key, key)) {
                debug(cachetools) safe_tracef("test entry index %d for key %s - success", index, key);
                return index;
            }
            index = (index + 1) & _mask;
        }
        while (index != start_index);
        return hash_t.max;
    }

    //
    // Find place where we can insert(DELETED or EMPTY bucket) or update existent (ALLOCATED)
    // bucket for key k and precomputed hash starting from start_index
    //
    //
    // Inherits @nogc from K opEquals()
    //
    private hash_t findUpdateIndex(K)(const hash_t start_index, const hash_t computed_hash, ref K key)
    in {
        assert(computed_hash < DELETED_HASH);
        assert(start_index < _buckets_num);
    }
    do {
        hash_t index = start_index;

        do {
            immutable h = _buckets.bs[index].hash;

            // debug (cachetools)
            //     safe_tracef("test update index %d (%s) for key %s", index, _buckets.bs[index], key);

            if (h <= DELETED_HASH) // empty or deleted
            {
                // debug (cachetools)
                //     safe_tracef("test update index %d (%s) for key %s - success",
                //             index, _buckets.bs[index], key);
                return index;
            }
            assert((h & TYPE_MASK) == ALLOCATED_HASH);
            if ((h & HASH_MASK) == computed_hash && keyEquals(_buckets.bs[index].key, key)) {
                // debug (cachetools)
                //     safe_tracef("test update index %d (%s) for key %s - success",
                //             index, _buckets.bs[index], key);
                return index;
            }
            index = (index + 1) & _mask;
        }
        while (index != start_index);
        return hash_t.max;
    }
    //
    // Find unallocated entry in the buckets slice
    // We use this function during resize() only.
    //
    private long findEmptyIndexExtended(const hash_t start_index,
            ref BucketStorage buckets, int new_mask) pure const @safe @nogc
    in {
        assert(start_index < buckets.bs.length);
    }
    do {
        hash_t index = start_index;

        do {
            immutable t = buckets.bs[index].hash;

            debug (cachetools)
                safe_tracef("test empty index %d (%s)", index, buckets.bs[index]);

            if (t <= DELETED_HASH) // empty or deleted
            {
                return index;
            }

            index = (index + 1) & new_mask;
        }
        while (index != start_index);
        return hash_t.max;
    }

    private bool tooMuchDeleted() pure const @safe @nogc {
        //
        // _deleted > _buckets_num / 8
        //
        //return false;
        return _deleted << 3 > _buckets_num;
    }

    private bool tooHighLoad() pure const @safe @nogc {
        //
        // _allocated/_buckets_num > 0.8
        // 5 * allocated > 4 * buckets_num
        //
        return _allocated + (_allocated << 2) > _buckets_num << 2;
    }
    /// when capacity == 0 - next put for new key can trigger resize
    public auto capacity() pure const @safe @nogc {
        // capacity = 0.8*buckets_num - _allocated;

        return (( _buckets_num << 2 ) / 5) - _allocated + 1;
    }

    private void doResize(int dest) {
        immutable _new_buckets_num = dest;
        immutable _new_mask = dest - 1;
        BucketStorage _new_buckets = BucketStorage(_new_buckets_num);

        // iterate over entries

        debug (cachetools)
            safe_tracef("start resizing: old loadfactor: %s", (1.0 * _allocated) / _buckets_num);

        for (int i = 0; i < _buckets_num; i++) {
            immutable hash_t h = _buckets.bs[i].hash;
            if (h < ALLOCATED_HASH) { // empty or deleted
                continue;
            }

            immutable hash_t start_index = h & _new_mask;
            immutable new_position = findEmptyIndexExtended(start_index, _new_buckets, _new_mask);

            debug (cachetools)
                safe_tracef("old hash: %0x, old pos: %d, new_pos: %d", h, i, new_position);

            assert(new_position >= 0);
            assert(_new_buckets.bs[cast(hash_t) new_position].hash == EMPTY_HASH);

            _new_buckets.bs[cast(hash_t)new_position] = _buckets.bs[i];
        }
        _buckets = _new_buckets;
        _buckets_num = _new_buckets_num;
        _mask = _buckets_num - 1;
        _deleted = 0;
        _empty = _buckets_num - _allocated;

        assert(popcnt(_buckets_num) == 1, "Buckets number must be power of 2");
        debug (cachetools)
            safe_tracef("resizing done: new loadfactor: %s", (1.0 * _allocated) / _buckets_num);
    }

    //
    // Lookup methods
    //
    private hash_t getLookupIndex(K)(ref K k) {
        if (_buckets_num == 0) {
            return hash_t.max;
        }
        immutable computed_hash = hash_function(k) & HASH_MASK;
        immutable start_index = computed_hash & _mask;
        immutable lookup_index = findEntryIndex(start_index, computed_hash, k);
        return lookup_index;
    }

    private hash_t getLookupIndex(K)(ref K k) const {
        if (_buckets_num == 0) {
            return hash_t.max;
        }
        immutable computed_hash = hash_function(k) & HASH_MASK;
        immutable start_index = computed_hash & _mask;
        immutable lookup_index = findEntryIndex(start_index, computed_hash, k);
        return lookup_index;
    }
    /// key in table
    /// Returns: pointer to stored value (if key in table) or null 
    ///
    deprecated("very unsafe, use fetch instead")
    auto opBinaryRight(string op, K)(K k) @system if (op == "in") {

        immutable lookup_index = getLookupIndex(k);

        if (lookup_index == hash_t.max) {
            return null;
        }
        static if (is(V == StoredValueType)) {
            return &_buckets.bs[lookup_index].value;
        }
        else {
            V* r = cast(V*)&_buckets[lookup_index].value;
            return r;
        }
    }

    /// "in" is unsafe as it can point to arbitrary address after resize
    deprecated("very unsafe, use fetch instead")
    auto opBinaryRight(string op, K)(K k) const @system if (op == "in") {

        immutable lookup_index = getLookupIndex(k);

        if (lookup_index == hash_t.max) {
            return null;
        }
        static if (is(V == StoredValueType)) {
            return &_buckets.bs[lookup_index].value;
        }
        else {
            V* r = cast(V*)&_buckets[lookup_index].value;
            return r;
        }
    }
    bool contains(K)(K k)
    {
        return getLookupIndex(k) != hash_t.max;
    }
    ///
    /// fetch is safe(do not return pointer) and nogc (do not throw exception)
    /// variant of "in" but retuns tuple("ok", "value").
    /// You can check if result.ok == true. It this case you'll find value in "value"
    ///
    auto fetch(K)(K k) 
    {
        immutable lookup_index = getLookupIndex(k);
        if (lookup_index == hash_t.max) {
            return tuple!("ok", "value")(false, V.init);
        }
        return tuple!("ok", "value")(true, _buckets.bs[lookup_index].value);
    }
    auto fetch(K)(K k) const
    {
        immutable lookup_index = getLookupIndex(k);
        if (lookup_index == hash_t.max) {
            return tuple!("ok", "value")(false, cast(const V)V.init);
        }
        return tuple!("ok", "value")(true, _buckets.bs[lookup_index].value);
    }
    ///
    /// get value from hash or add if key is not in table. defaultValue can be callable.
    /// Returns: ref to value (maybe added)
    ///
    V getOrAdd(K, T)(K k, T defaultValue) {
        immutable lookup_index = getLookupIndex(k);

        if (lookup_index != hash_t.max) {
            return _buckets.bs[lookup_index].value;
        }

        static if (is(T == V) || isAssignable!(V, T)) {
            put(k, defaultValue);
            return defaultValue;
        }
        else static if (isCallable!T && isAssignable!(V, ReturnType!T)) {
            auto vv = defaultValue();
            put(k, vv);
            return vv;
        }
        else {
            static assert(0, "what?");
        }
    }

    ///
    alias require = getOrAdd;

    ///
    /// Add key/value to hash if key is not in table. value can be lazy/callable.
    /// Returns: true if key were added.
    ///
    bool addIfMissed(T)(K k, T value) {
        immutable lookup_index = getLookupIndex(k);

        if (lookup_index != hash_t.max) {
            return false;
        }

        static if (is(T == V) || isAssignable!(V, T)) {
            put(k, value);
            return true;
        }
        else static if (isCallable!T && isAssignable!(V, ReturnType!T)) {
            put(k, value());
            return true;
        }
        else {
            static assert(0, "Can't assign value");
        }
    }

    /// get current grow factor.
    auto grow_factor() const @safe {
        return _grow_factor;
    }

    /// set grow factor (can be between 2, 4 or 8).
    void grow_factor(int gf) @safe {
        if (gf < 2) {
            _grow_factor = 2;
            return;
        }
        if (gf > 8) {
            _grow_factor = 8;
            return;
        }
        // enforce new grow_factor is power of 2
        if (popcnt(gf) > 1) {
            immutable p = bsr(gf);
            gf = 1 << (p + 1);
        }
        _grow_factor = gf;
    }
    ///
    /// get with default value
    /// it infers @safe, @nogc from user data: do not return ptr and do not thow
    /// 
    /// Returns: value from hash, or defaultValue if key not found (see also getOrAdd).
    /// defaultValue can be callable.
    ///
    V get(T)(K k, T defaultValue) const {
        immutable lookup_index = getLookupIndex(k);

        if (lookup_index != hash_t.max) {
                return _buckets.bs[lookup_index].value;
        }

        static if (is(V == T) || isAssignable!(V, T)) {
            return defaultValue;
        }
        else static if (isCallable!T && isAssignable!(V, ReturnType!T)) {
            return defaultValue();
        }
        else {
            static assert(0, "You must call 'get' with default value of HashMap 'value' type, or with callable, returning HashMap 'value'");
        }
    }

    V get(T)(K k, T defaultValue) {
        immutable lookup_index = getLookupIndex(k);

        if (lookup_index != hash_t.max) {
            return _buckets.bs[lookup_index].value;
        }

        static if (is(V == T) || isAssignable!(V, T)) {
            return defaultValue;
        }
        else static if (isCallable!T && isAssignable!(V, ReturnType!T)) {
            return defaultValue();
        }
        else {
            static assert(0, "You must call 'get' with default value of HashMap 'value' type, or with callable, returning HashMap 'value'");
        }
    }

    ///
    /// map[key]
    /// Attention: you can't use this method in @nogc code.
    /// Usual aa[key] method.
    /// Throws exception if key not found
    /// Returns: value for given key
    ///
    auto opIndex(K)(K k) inout {
        immutable lookup_index = getLookupIndex(k);

        if (lookup_index == hash_t.max) {
            throw new KeyNotFound();
        }

        static if (is(V == StoredValueType)) {
            return _buckets.bs[lookup_index].value;
        }
        else {
            return cast(V) _buckets.bs[lookup_index].value;
        }
    }

    ///
    /// map[k] = v;
    ///
    void opIndexAssign(K)(V v, K k)
    do {
        put(k, v);
    }
    ///
    /// put pair (k,v) into hash.
    ///
    /// inherits @safe and @nogc properties from K and V
    /// It can resize table if table is overloaded or has too much deleted entries.
    /// Returns: Nullable with old value if value was updated, or empty Nullable
    /// if we just stored new value.
    ///
    auto put(K)(K k, V v)
    do {
        if (!_buckets_num) {
            _buckets_num = _empty = initial_buckets_num;
            assert(popcnt(_buckets_num) == 1, "Buckets number must be power of 2");
            _mask = _buckets_num - 1;
            _buckets = BucketStorage(_buckets_num);
        }

        debug (cachetools)
            safe_tracef("put k: %s", k);

        if (tooHighLoad) {
            doResize(_grow_factor * _buckets_num);
        }

        if (_buckets.cow_required) // <- we have iterator over buckets, make copy on write
        {
            auto new_bs = BucketStorage(_buckets_num);
            copy(_buckets.bs, new_bs.bs);
            _buckets = new_bs;
        }

        immutable computed_hash = hash_function(k) & HASH_MASK;
        immutable start_index = computed_hash & _mask;
        immutable placement_index = findUpdateIndex(start_index, computed_hash, k);

        _Bucket* bucket = &_buckets.bs[placement_index];
        immutable h = bucket.hash;

        debug (cachetools)
            safe_tracef("start_index: %d, placement_index: %d", start_index, placement_index);

        if (h < ALLOCATED_HASH) {
            bucket.value = v;
            bucket.key = k;
            final switch (h) {
            case EMPTY_HASH:
                _empty--;
                break;
            case DELETED_HASH:
                _deleted--;
                break;
            }
            bucket.hash = computed_hash | ALLOCATED_HASH;
            _allocated++;
            return Nullable!(typeof(bucket.value))();
        } else {
            auto o = nullable(bucket.value);
            bucket.value = v;
            return o;
        }
    }

    ///
    /// remomve key from hash.
    /// Returns: true if actually removed, false otherwise.
    ///
    bool remove(K k) {

        if (tooMuchDeleted) {
            // do not shrink, just compact table
            doResize(_buckets_num);
        }

        if (_buckets_num == 0) {
            return false;
        }

        if (_buckets.cow_required) // <- we have iterator over buckets, make copy on write
        {
            auto new_bs = BucketStorage(_buckets_num);
            copy(_buckets.bs, new_bs.bs);
            _buckets = new_bs;
        }

        debug (cachetools)
            safe_tracef("remove k: %s", k);

        immutable lookup_index = getLookupIndex(k);
        if (lookup_index == hash_t.max) {
            // nothing to remove
            return false;
        }

        assert((_buckets.bs[lookup_index].hash & TYPE_MASK) == ALLOCATED_HASH,
                "tried to remove non allocated bucket");

        _allocated--;
        immutable next_index = (lookup_index + 1) & _mask;
        // if next bucket is EMPTY, then we can convert all DELETED buckets down staring from current to EMPTY buckets
        if (_buckets.bs[next_index].hash == EMPTY_HASH) {
            _empty++;
            debug (cachetools) safe_tracef("mark index %s empty(%d is empty hash)", lookup_index, next_index);
            _buckets.bs[lookup_index].hash = EMPTY_HASH;
            auto free_index = (lookup_index - 1) & _mask;
            while (free_index != lookup_index) {
                if (_buckets.bs[free_index].hash != DELETED_HASH) {
                    break;
                }
                debug (cachetools) safe_tracef("mark index %s empty", free_index);
                _buckets.bs[free_index].hash = EMPTY_HASH;
                _deleted--;
                _empty++;
                free_index = (free_index - 1) & _mask;
            }
            assert(free_index != lookup_index, "table full of deleted buckets?");
        }
        else {
            debug (cachetools) safe_tracef("mark index %s deleted", lookup_index);
            _buckets.bs[lookup_index].hash = DELETED_HASH;
            _deleted++;
        }
        return true;
    }
    /// throw away all keys
    void clear() {
        _buckets = BucketStorage.init;
        _allocated = _deleted = _empty = _buckets_num = 0;
    }
    /// get numter of keys in table
    auto length() const pure nothrow @nogc @safe {
        return _allocated;
    }

    /// get current buckets number
    auto size() const pure nothrow @nogc @safe {
        return _buckets_num;
    }

    private struct _kvRange {
        int             _pos;
        size_t           _buckets_num;
        BucketStorage   _buckets;

        ~this() {
            _buckets = BucketStorage.init;
        }

        this(ref BucketStorage _b) {
            if ( _b !is null )
            {
                _b.cow_required = true;
                _buckets = _b;
                _buckets_num = _b.bs.length;
                _pos = 0;
                while (_pos < _buckets_num && _buckets.bs[_pos].hash < ALLOCATED_HASH) {
                    _pos++;
                }
            }
        }

        bool empty() const pure nothrow @safe @nogc {
            return _pos == _buckets_num;
        }

        auto front() {
            return Tuple!(K, "key", V, "value")(_buckets.bs[_pos].key, _buckets.bs[_pos].value);
        }

        void popFront() pure nothrow @safe @nogc {
            _pos++;
            while (_pos < _buckets_num && _buckets.bs[_pos].hash < ALLOCATED_HASH) {
                _pos++;
            }
        }
    }

    /// iterator by keys
    auto byKey() {
        return _kvRange(_buckets).map!"a.key";
    }

    /// iterator by values
    auto byValue() {
        return _kvRange(_buckets).map!"a.value";
    }

    /// iterator by key/value pairs
    auto byPair() {
        return _kvRange(_buckets);
    }
}

/// Example
@("L" ~ to!string(__LINE__) ~ ".word dictionary")
@safe unittest {
    import std.range;
    import std.algorithm;
    import std.experimental.logger;
    HashMap!(string, int) counter;
    string[] words = [
        "hello", "this", "simple", "example", "should", "succeed", "or", "it",
        "should", "fail"
    ];
    // count words, simplest and fastest way
    foreach (word; words) {
        counter[word] = counter.getOrAdd(word, 0) + 1;
    }
    assert(!counter.fetch("world").ok);
    assert(counter.fetch("hello").value == 1);
    assert(counter["hello"] == 1);
    assert(counter["should"] == 2);
    assert(counter.contains("hello"));
    assert(counter.length == words.length - 1);
    // iterators
    assert(counter.byKey.count == counter.byValue.count);
    assert(words.all!(w => counter.contains(w))); // all words are in table
    assert(counter.byValue.sum == words.length); // sum of counters must equals to number of words
}
// Tests
@("L" ~ to!string(__LINE__) ~ ".remove")
@safe unittest {
    // test of nogc getOrAdd
    import std.experimental.logger;

    globalLogLevel = LogLevel.info;
    import std.meta;

    static foreach (T; AliasSeq!(HashMap!(int, int))) {
        () @nogc nothrow{
            T hashMap;
            debug (cachetools)
                safe_tracef("Testing %s", typeid(T));
            foreach (i; 0 .. 10) {
                hashMap.put(i, i);
            }
            foreach (i; 0 .. 10) {
                hashMap.put(i, i);
            }
            foreach (i; 0 .. 10) {
                auto v = hashMap.fetch(i);
                assert(v.ok && v.value == i);
            }
            assert(hashMap.length == 10);
            hashMap.remove(0);
            assert(hashMap.length == 9);
            assert(!hashMap.fetch(0).ok);
            hashMap.remove(1);
            assert(hashMap.length == 8);
            assert(!hashMap.fetch(1).ok);
            assert(hashMap.fetch(8).ok);
            hashMap.remove(8);
            assert(hashMap.length == 7);
            assert(!hashMap.fetch(8).ok);
            foreach (i; 0 .. 10) {
                hashMap.put(i, i);
            }
            assert(hashMap.length == 10);
            hashMap.remove(8);
            hashMap.remove(1);
            assert(hashMap.length == 8);
            assert(!hashMap.fetch(1).ok);
            assert(!hashMap.fetch(8).ok);
            assert(hashMap.remove(1) == false);
            foreach (i; 0 .. 10) {
                hashMap.remove(i);
            }
            assert(hashMap.length == 0);
        }();
    }
    //auto v = hashMap.getOrAdd(-1, -1);
    //assert(-1 in hashMap && v == -1);
    globalLogLevel = LogLevel.info;
}

// test get()
@("L" ~ to!string(__LINE__) ~ ".get")
@safe @nogc nothrow unittest {
    import std.meta;

    static foreach (T; AliasSeq!(HashMap!(int, int))) {
        {
            T hashMap;
            int i = hashMap.get(1, 55);
            assert(i == 55);
            i = hashMap.get(1, () => 66);
            assert(i == 66);
            hashMap[1] = 1;
            i = hashMap.get(1, () => 66);
            assert(i == 1);
        }
    }
}


// test immutable struct and class as Key type
@("L" ~ to!string(__LINE__) ~ ".immutable struct and class as Key type")
@safe unittest {
    import std.experimental.logger;

    globalLogLevel = LogLevel.info;
    info("Testing hash tables");
    import std.meta;

    struct S {
        int s;
    }

    static foreach (T; AliasSeq!(HashMap!(immutable S, int))) {
        () @nogc nothrow{
            T hs1;
            immutable ss = S(1);
            hs1[ss] = 1;
            assert(hs1.contains(ss) && hs1.fetch(ss).value == 1);
        }();
    }
    static foreach (T; AliasSeq!(HashMap!(int, immutable S))) {
        () @nogc nothrow{
            T hs2;
            immutable ss = S(1);
            hs2[1] = ss;
            // assert(1 in hs2 && *(1 in hs2) == ss);
            // assert(!(2 in hs2));
        }();
    }
    // class
    class C {
        int v;
        this(int _v) pure inout {
            v = _v;
        }

        bool opEquals(const C o) pure const @safe @nogc nothrow {
            return v == o.v;
        }

        override hash_t toHash() const @safe @nogc {
            return hash_function(v);
        }
    }

    static foreach (T; AliasSeq!(HashMap!(immutable C, int))) {
        {
            T hc1;
            immutable cc = new immutable C(1);
            hc1[cc] = 1;
            assert(hc1[cc] == 1);
        }
    }
    static foreach (T; AliasSeq!(HashMap!(int, immutable C))) {
        {
            immutable cc = new immutable C(1);
            T hc2;
            hc2[1] = cc;
            assert(hc2[1] is cc);
        }
    }
}

@("L" ~ to!string(__LINE__) ~ ".class as key")
@safe unittest {
    // test class as key
    import std.experimental.logger;

    globalLogLevel = LogLevel.info;
    class A {
        int v;

        bool opEquals(const A o) pure const @safe @nogc nothrow {
            return v == o.v;
        }

        override hash_t toHash() const @safe @nogc {
            return hash_function(v);
        }

        this(int v) {
            this.v = v;
        }

        override string toString() const {
            import std.format;

            return "A(%d)".format(v);
        }
    }

    globalLogLevel = LogLevel.info;
    auto x = new A(1);
    auto y = new A(2);
    HashMap!(A, string) dict;
    dict.put(x, "x");
    dict.put(y, "y");
}

@("L" ~ to!string(__LINE__) ~ ".remove/put to same hash position")
@safe unittest {
    import std.experimental.logger;

    globalLogLevel = LogLevel.info;
    () @nogc nothrow{
        HashMap!(int, int) int2int;
        foreach (i; 0 .. 15) {
            int2int.put(i, i);
        }
        assert(int2int.length() == 15);
        foreach (i; 0 .. 15) {
            assert(int2int.contains(i));
        }
        foreach (i; 0 .. 15) {
            int2int.remove(i);
        }
        assert(int2int.length() == 0);
    }();
    () @nogc nothrow{
        struct LargeStruct {
            ulong a;
            ulong b;
        }

        HashMap!(int, LargeStruct) int2ls;
        foreach (i; 1 .. 5) {
            int2ls.put(i, LargeStruct(i, i));
        }
        int2ls.put(33, LargeStruct(33, 33)); // <- follow key 1, move key 2 on pos 3
        foreach (i; 1 .. 5) {
            assert(int2ls.contains(i));
        }
        assert(int2ls.contains(33), "33 not in hash");
        int2ls.remove(33);
        int2ls.put(2, LargeStruct(2, 2)); // <- must replace key 2 on pos 3
        assert(int2ls.contains(2), "2 not in hash");
    }();
}
@("L" ~ to!string(__LINE__) ~ ".structs as value")
@safe unittest {
    import std.experimental.logger;

    globalLogLevel = LogLevel.info;
    () @nogc nothrow{
        assert(SmallValueFootprint!int());
        assert(SmallValueFootprint!double());
        struct SmallStruct {
            ulong a;
        }
        //assert(SmallValueFootprint!SmallStruct);
        struct LargeStruct {
            ulong a;
            ulong b;
        }

        assert(!SmallValueFootprint!LargeStruct);
        class SmallClass {
            ulong a;
        }
        //assert(!SmallValueFootprint!SmallClass);

        HashMap!(int, string) int2string;
        auto u = int2string.put(1, "one");
        {
            auto v = int2string.fetch(1);
            assert(v.ok);
            assert(v.value == "one");
        }
        assert(!int2string.contains(2));
        u = int2string.put(32 + 1, "33");
        assert(int2string.contains(33));
        assert(int2string.remove(33));
        assert(!int2string.remove(33));

        HashMap!(int, LargeStruct) int2LagreStruct;
        int2LagreStruct.put(1, LargeStruct(1, 2));
        {
            auto v = int2LagreStruct.fetch(1);
            assert(v.ok);
            assert(v.value == LargeStruct(1, 2));
        }
    }();

    globalLogLevel = LogLevel.info;
}

@("L" ~ to!string(__LINE__) ~ ".@safe @nogc nothrow for map")
@safe unittest {
    import std.experimental.logger;
    import std.experimental.allocator.gc_allocator;

    globalLogLevel = LogLevel.info;
    static int i;
    () @safe @nogc nothrow{
        struct LargeStruct {
            ulong a;
            ulong b;
            ~this() @safe @nogc {
                i++;
            }
        }

        HashMap!(int, LargeStruct) int2LagreStruct;
        int2LagreStruct.put(1, LargeStruct(1, 2));
        int2LagreStruct.get(1, LargeStruct(0, 0));
    }();
    globalLogLevel = LogLevel.info;
}

@("L" ~ to!string(__LINE__) ~ ".tuple as key")
@safe unittest  /* not nothrow as opIndex may throw */ {
    import std.typecons;

    alias K = Tuple!(int, int);
    alias V = int;
    HashMap!(K, V) h;
    K k0 = K(0, 1);
    V v0 = 1;
    h.put(k0, v0);
    auto v = h.fetch(k0);
    assert(v.ok);
    assert(v.value == 1);
    h[k0] = v0;
    assert(h[k0] == v0);
}
import std.conv;
@("L" ~ to!string(__LINE__) ~ ".@safe @nogc nothrow with class as key")
@safe nothrow unittest {
    class c {
        int a;
        this(int a) {
            this.a = a;
        }

        override hash_t toHash() const pure @nogc @safe {
            return hash_function(a);
        }

        bool opEquals(const c other) pure const nothrow @safe @nogc {
            return this is other || this.a == other.a;
        }
    }

    alias K = c;
    alias V = int;
    K k0 = new c(0);
    V v0 = 1;
    () @nogc nothrow{
        HashMap!(K, V) h;
        h.put(k0, v0);
        auto v = h.fetch(k0);
        assert(v.ok);
        assert(v.value == 1);
        h[k0] = 2;
        v = h.fetch(k0);
        assert(v.value == 2);
    }();
}

// Test if we can work with non-@nogc opEquals for class-key.
// opEquals anyway must be non-@system.
@("L" ~ to!string(__LINE__) ~ ".non-@nogc class as key")
@safe nothrow unittest {
    class c {
        int a;
        this(int a) {
            this.a = a;
        }

        override hash_t toHash() const pure @safe {
            int[] _ = [1, 2, 3]; // this cause GC
            return hash_function(a);
        }

        bool opEquals(const c other) const pure nothrow @safe {
            auto _ = [1, 2, 3]; // this cause GC
            return this is other || this.a == other.a;
        }
    }

    alias K = c;
    alias V = int;
    HashMap!(K, V) h;
    K k0 = new c(0);
    V v0 = 1;
    h.put(k0, v0);
    auto v = h.fetch(k0);
    assert(v.ok);
    assert(v.value == 1);
    K k1 = new c(1);
    V v1 = 1;
    h.put(k0, v0);
    assert(!keyEquals(k0, k1));
}
//
// test byKey, byValue, byPair
//
@("L" ~ to!string(__LINE__) ~ ".byKey, byValue, byPair")
@safe nothrow unittest {
    import std.algorithm;
    import std.array;

    HashMap!(int, string) m;
    m[1] = "one";
    m[2] = "two";
    m[10] = "ten";
    assert(equal(m.byKey.array.sort, [1, 2, 10]));
    assert(equal(m.byValue.array.sort, ["one", "ten", "two"]));
    assert(equal(m.byPair.map!"tuple(a.key, a.value)".array.sort, [
                tuple(1, "one"), tuple(2, "two"), tuple(10, "ten")
            ]));
    m.remove(1);
    m.remove(10);
    assert(equal(m.byPair.map!"tuple(a.key, a.value)".array.sort, [
                tuple(2, "two")
            ]));
    m.remove(2);
    assert(m.byPair.map!"tuple(a.key, a.value)".array.sort.length() == 0);
    m.remove(2);
    assert(m.byPair.map!"tuple(a.key, a.value)".array.sort.length() == 0);
}
// test byKey, byValue, byPair compiles with GCRangesAllowed=false
@("L" ~ to!string(__LINE__) ~ ".byKey, byValue, byPair compiles with GCRangesAllowed=false")
@nogc unittest {
    import std.experimental.allocator.mallocator : Mallocator;

    HashMap!(int, int, Mallocator, false) map;
    map[1] = 2;

    auto keys = map.byKey();
    assert(keys.empty == false);
    assert(keys.front == 1);

    auto values = map.byValue();
    assert(values.empty == false);
    assert(values.front == 2);

    auto pairs = map.byPair();
    assert(pairs.empty == false);
    assert(pairs.front.key == 1);
    assert(pairs.front.value == 2);
}
// 
// compare equivalence to AA
//
/* not @safe because of AA */
@("L" ~ to!string(__LINE__) ~ ".equivalence to AA")
unittest {
    import std.random;
    import std.array;
    import std.algorithm;
    import std.stdio;
    import std.experimental.logger;

    enum iterations = 400_000;

    globalLogLevel = LogLevel.info;

    HashMap!(int, int) hashMap;
    int[int] AA;

    auto rnd = Random(unpredictableSeed);

    foreach (i; 0 .. iterations) {
        int k = uniform(0, iterations, rnd);
        hashMap.put(k, i);
        AA[k] = i;
    }
    assert(equal(AA.keys().sort(), hashMap.byKey().array.sort()));
    assert(equal(AA.values().sort(), hashMap.byValue().array.sort()));
    assert(AA.length == hashMap.length);
    AA.remove(1);
    hashMap.remove(1);
    assert(equal(AA.keys().sort(), hashMap.byKey().array.sort()));
    assert(equal(AA.values().sort(), hashMap.byValue().array.sort()));
    assert(AA.length == hashMap.length);
}
//
// check remove
//
@("L" ~ to!string(__LINE__) ~ ".remove all items")
@safe unittest {
    // test removal while iterating
    import std.random;
    import std.array;
    import std.algorithm;
    import std.stdio;
    import std.experimental.logger;

    enum iterations = 400_000;

    globalLogLevel = LogLevel.info;

    HashMap!(int, int) hashMap;

    auto rnd = Random(unpredictableSeed);

    foreach (i; 0 .. iterations) {
        int k = uniform(0, iterations, rnd);
        hashMap[k] = i;
    }
    foreach (k; hashMap.byKey) {
        assert(hashMap.remove(k));
    }
    assert(hashMap.length == 0);
}
//
// test clear
//
@("L" ~ to!string(__LINE__) ~ ".clear()")
@safe @nogc nothrow unittest {
    // test clear
    import std.algorithm;
    import std.array;

    HashMap!(int, int) hashMap;

    foreach (i; 0 .. 100) {
        hashMap[i] = i;
    }
    hashMap.clear();
    assert(hashMap.length == 0);
    hashMap[1] = 1;
    assert(hashMap.contains(1) && hashMap.length == 1);
}

//
// test getOrAdd with value
//
@("L" ~ to!string(__LINE__) ~ ".@safe @nogc nothrow getOrAdd()")
@safe @nogc nothrow unittest {
    // test of nogc getOrAdd

    HashMap!(int, int) hashMap;

    foreach (i; 0 .. 100) {
        hashMap[i] = i;
    }
    auto v = hashMap.getOrAdd(-1, -1);
    assert(hashMap.contains(-1) && v == -1);
}

//
// test getOrAdd with callable
//
@("L" ~ to!string(__LINE__) ~ ".@safe @nogc nothrow getOrAdd with lazy default value")
@safe @nogc nothrow unittest {
    // test of nogc getOrAdd with lazy default value

    HashMap!(int, int) hashMap;

    foreach (i; 0 .. 100) {
        hashMap[i] = i;
    }
    int v = hashMap.getOrAdd(-1, () => -1);
    assert(hashMap.contains(-1) && v == -1);
    assert(hashMap.get(-1, 0) == -1); // key -1 is in hash, return value
    assert(hashMap.get(-2, 0) == 0); // key -2 not in map, return default value
    assert(hashMap.get(-3, () => 0) == 0); // ditto
}

//
// test getOrAdd with complex data
//
@("L" ~ to!string(__LINE__) ~ ".Some real class as value")
@safe unittest {
    import std.socket, std.meta;

    static foreach (T; AliasSeq!(HashMap!(string, Socket))) {
        {
            T socketPool;
            Socket s0 = socketPool.getOrAdd("http://example.com",
                    () => new Socket(AddressFamily.INET, SocketType.STREAM));
            assert(s0 !is null);
            assert(s0.addressFamily == AddressFamily.INET);
            Socket s1 = socketPool.getOrAdd("http://example.com",
                    () => new Socket(AddressFamily.INET, SocketType.STREAM));
            assert(s1 !is null);
            assert(s1 is s0);
        }
    }
}
//
// test with real class (socket)
//
@("L" ~ to!string(__LINE__) ~ ".Some real class as key")
@safe unittest {
    import std.socket;

    class Connection {
        Socket s;
        bool opEquals(const Connection other) const pure @safe {
            return s is other.s;
        }

        override hash_t toHash() const @safe {
            return hash_function(s.handle);
        }

        this() {
            s = new Socket(AddressFamily.INET, SocketType.STREAM);
        }
    }

    HashMap!(Connection, string) socketPool;
    auto c1 = new Connection();
    auto c2 = new Connection();
    socketPool[c1] = "conn1";
    socketPool[c2] = "conn2";
    assert(socketPool[c1] == "conn1");
    assert(socketPool[c2] == "conn2");
}
@("L" ~ to!string(__LINE__) ~ ".@safe get() with lazy default")
@safe unittest {
    // test of non-@nogc getOrAdd with lazy default value
    import std.conv;
    import std.exception;
    import std.experimental.logger;
    import std.meta;

    globalLogLevel = LogLevel.info;
    class C {
        string v;
        this(int _v) @safe {
            v = to!string(_v);
        }
    }

    static foreach (T; AliasSeq!(HashMap!(int, C))) {
        {
            T hashMap;

            foreach (i; 0 .. 100) {
                hashMap[i] = new C(i);
            }
            C v = hashMap.getOrAdd(-1, () => new C(-1));
            assert(hashMap.contains(-1) && v.v == "-1");
            assert(hashMap[-1].v == "-1");
            //hashMap[-1].v ~= "1";
            //assert(hashMap[-1].v == "-11");
            assertThrown!KeyNotFound(hashMap[-2]);
            // check lazyness
            bool called;
            v = hashMap.getOrAdd(-1, delegate C() { called = true; return new C(0); });
            assert(!called);
            v = hashMap.getOrAdd(-2, delegate C() { called = true; return new C(0); });
            assert(called);
        }
    }
}
//
// test if we can handle some exotic value type
//
@("L" ~ to!string(__LINE__) ~ ".@safe @nogc nothrow get() with lazy default")
@safe @nogc nothrow unittest {
    // test of nogc getOrAdd with lazy default value
    // corner case when V is callable

    alias F = int function() @safe @nogc nothrow;

    F one = function() { return 1; };
    F two = function() { return 2; };
    F three = function() { return 3; };
    F four = function() { return 4; };
    HashMap!(int, F) hashMap;
    hashMap.put(1, one);
    hashMap.put(2, two);
    auto p = hashMap.fetch(1);
    assert(p.ok);
    assert(p.value() == 1);
    p = hashMap.fetch(2);
    assert(p.ok);
    assert(p.value() == 2);
    auto f3 = hashMap.getOrAdd(3, () => function int() { return 3; }); // used as default()
    assert(f3() == 3);
    auto f4 = hashMap.getOrAdd(4, four);
    assert(f4() == 4);
}

// test get()
@("L" ~ to!string(__LINE__) ~ ".@safe @nogc nothrow get() with value as default")
@safe @nogc nothrow unittest {
    HashMap!(int, int) hashMap;
    int i = hashMap.get(1, 55);
    assert(i == 55);
    i = hashMap.get(1, () => 66);
    assert(i == 66);
    hashMap[1] = 1;
    i = hashMap.get(1, () => 66);
    assert(i == 1);
}
// test grow_factor()
@("L" ~ to!string(__LINE__) ~ ".test grow_factor")
unittest {
    import std.experimental.logger;

    globalLogLevel = LogLevel.info;
    HashMap!(int, int) hashMap;
    hashMap.grow_factor(3);
    assert(hashMap.grow_factor() == 4);
    hashMap.grow_factor(0);
    assert(hashMap.grow_factor() == 2);
    hashMap.grow_factor(16);
    assert(hashMap.grow_factor() == 8);
    assert(hashMap.size == 0);
    assert(hashMap.length == 0);
}

// test unsafe types
@("L" ~ to!string(__LINE__) ~ ".unsafe types")
unittest {
    import std.variant;
    import std.stdio;
    import std.algorithm;

    alias UnsafeType = Algebraic!(int, string);

    HashMap!(UnsafeType, string) unsafeKeyMap;
    UnsafeType k = "one";
    unsafeKeyMap[k] = "value one";
    assert(k in unsafeKeyMap);
    assert(unsafeKeyMap[k] == "value one");
    k = 1;
    assert(k !in unsafeKeyMap);
    unsafeKeyMap[UnsafeType(2)] = "value two";
    assert(unsafeKeyMap.getOrAdd(k, "value one 2") == "value one 2");
    assert(unsafeKeyMap.get(k, "value one 3") == "value one 2");
    assert(equal(unsafeKeyMap.byKey, unsafeKeyMap.byPair.map!"a.key"));
    assert(equal(unsafeKeyMap.byValue, unsafeKeyMap.byPair.map!"a.value"));
    unsafeKeyMap.clear;

    HashMap!(int, UnsafeType) unsafeValueMap;
    auto uv1 = UnsafeType("one");
    auto uv2 = UnsafeType(2);
    auto uv3 = UnsafeType("three");
    unsafeValueMap[1] = uv1;
    unsafeValueMap[2] = uv2;
    assert(1 in unsafeValueMap && unsafeValueMap[1] == "one");
    assert(2 in unsafeValueMap && unsafeValueMap[2] == 2);
    assert(unsafeValueMap.getOrAdd(3, uv3) == "three");
    assert(unsafeValueMap.get(3, UnsafeType("3")) == "three");
    assert(equal(unsafeValueMap.byKey, unsafeValueMap.byPair.map!"a.key"));
    assert(equal(unsafeValueMap.byValue, unsafeValueMap.byPair.map!"a.value"));
    unsafeValueMap.clear;

}

// issue #4
@("L" ~ to!string(__LINE__) ~ ".issue #4")
unittest {
    HashMap!(string, string) foo;
    foo.remove("a");
}

//
// to use HashMap in @safe @nogc code using class as key, class has to implement
// @safe @nogc opEquals, hoHash, this()
//
@("L" ~ to!string(__LINE__) ~ ".@safe @nogc with class as key")
unittest {
    import std.experimental.allocator.mallocator;

    class C {
        int s;
        bool opEquals(const C other) inout @safe @nogc {
            return s == other.s;
        }

        override hash_t toHash() @safe @nogc {
            return hash_function(s);
        }

        this(int i) @safe @nogc {
            s = i;
        }
    }

    auto allocator = Mallocator.instance;

    int i;
    auto c0 = make!C(allocator, ++i);
    auto c1 = make!C(allocator, ++i);
    auto c2 = make!C(allocator, ++i);

    () @safe @nogc {
        HashMap!(C, string) map;
        map[c0] = "c0";
        map[c1] = "c1";
        assert(map.contains(c0) && map.contains(c1));
        assert(map.get(c0, "") == "c0");
        assert(map.get(c1, "") == "c1");
        assert(map.getOrAdd(c2, "c2 added") == "c2 added");
        assert(map.length == 3);
        map.clear;
    }();

    dispose(allocator, c0);
    dispose(allocator, c1);
    dispose(allocator, c2);
}
// ditto, with @nogc only
@("L" ~ to!string(__LINE__) ~ ".@nogc with class as key")
unittest {
    import std.experimental.allocator.mallocator;

    static int i;
    class C {
        int s;
        bool opEquals(const C other) inout @nogc {
            return s == other.s;
        }

        override hash_t toHash() @nogc {
            return hash_function(s);
        }

        this() @nogc {
            s = ++i;
        }
    }

    auto allocator = Mallocator.instance;
    auto c0 = () @trusted { return make!C(allocator); }();
    auto c1 = () @trusted { return make!C(allocator); }();
    auto c2 = () @trusted { return make!C(allocator); }();
    () @nogc {
        HashMap!(C, string) map;
        map[c0] = "c0";
        map[c1] = "c1";
        assert(c0 in map && c1 in map);
        assert(map.get(c0, "") == "c0");
        assert(map.get(c1, "") == "c1");
        assert(map.getOrAdd(c2, "c2 added") == "c2 added");
        assert(map.length == 3);
    }();
    () @trusted {
        dispose(allocator, cast(C) c0);
        dispose(allocator, cast(C) c1);
        dispose(allocator, cast(C) c2);
    }();
}
// ditto, with @safe only
@("L" ~ to!string(__LINE__) ~ ".@safe with class as key")
@safe unittest {
    import std.experimental.allocator.mallocator;

    static int i;
    class C {
        int s;
        bool opEquals(const C other) inout @safe {
            return s == other.s;
        }

        override hash_t toHash() const @safe {
            return hash_function(s);
        }

        this() @safe {
            s = ++i;
        }
    }

    HashMap!(C, string) map;
    auto allocator = Mallocator.instance;
    auto c0 = () @trusted { return make!C(allocator); }();
    auto c1 = () @trusted { return make!C(allocator); }();
    auto c2 = () @trusted { return make!C(allocator); }();
    map[c0] = "c0";
    map[c1] = "c1";
    assert(map.contains(c0) && map.contains(c1));
    assert(map.get(c0, "") == "c0");
    assert(map.get(c1, "") == "c1");
    assert(map.getOrAdd(c2, "c2 added") == "c2 added");
    assert(map.length == 3);
    () @trusted {
        dispose(allocator, cast(C) c0);
        dispose(allocator, cast(C) c1);
        dispose(allocator, cast(C) c2);
    }();
}
//
// Nothing special required when using class as value
//
@("L" ~ to!string(__LINE__) ~ ".@safe @nogc with class as value")
@safe unittest {
    import std.experimental.allocator.mallocator;

    class C {
        int s;
        this(int i) @safe @nogc immutable {
            s = i;
        }

        bool opEquals(C other) @safe const {
            return s == other.s;
        }
    }

    int i;
    alias T = immutable C;
    auto allocator = Mallocator.instance;

    T c0 = () @trusted { return make!T(allocator, ++i); }();
    T c1 = () @trusted { return make!T(allocator, ++i); }();
    T c2 = () @trusted { return make!T(allocator, ++i); }();
    () @safe @nogc {
        HashMap!(string, T) map;
        map["c0"] = c0;
        map["c1"] = c1;
        assert(map.get("c0", c2) is c0);
        assert(map.get("c1", c2) is c1);
        assert(map.getOrAdd("c2", c2) is c2);
        map["c2"] = c2;
        assert(map.length == 3);
    }();
    () @trusted {
        dispose(allocator, cast(C) c0);
        dispose(allocator, cast(C) c1);
        dispose(allocator, cast(C) c2);
    }();
}
//
// You can use immutable class instances as key when opEquals and toHash are const.
//
@("L" ~ to!string(__LINE__) ~ ".immutable key")
@safe unittest {
    import std.experimental.allocator.mallocator;

    class C {
        int s;
        bool opEquals(const C other) const @safe @nogc {
            return s == other.s;
        }

        override hash_t toHash() const @safe @nogc {
            return hash_function(s);
        }

        this(int i) @safe @nogc {
            s = i;
        }
    }

    int i;
    alias T = immutable C;
    auto allocator = Mallocator.instance;

    auto c0 = () @trusted { return make!T(allocator, ++i); }();
    auto c1 = () @trusted { return make!T(allocator, ++i); }();
    auto c2 = () @trusted { return make!T(allocator, ++i); }();
    () @nogc {
        HashMap!(T, string) map;
        map[c0] = "c0";
        map[c1] = "c1";
        assert(map.contains(c0) && map.contains(c1));
        assert(map.get(c0, "") == "c0");
        assert(map.get(c1, "") == "c1");
        assert(map.getOrAdd(c2, "c2 added") == "c2 added");
        assert(map.length == 3);
    }();
    () @trusted {
        dispose(allocator, cast(C) c0);
        dispose(allocator, cast(C) c1);
        dispose(allocator, cast(C) c2);
    }();
}

//
// test copy constructor
//
@("L" ~ to!string(__LINE__) ~ ".@safe @nogc copy cnstructor")
@safe @nogc unittest {
    import std.experimental.logger;
    import std.stdio;

    HashMap!(int, int) hashMap0, hashMap1;

    foreach (i; 0 .. 100) {
        hashMap0[i] = i;
    }

    hashMap1 = hashMap0; // behave as value
    hashMap0.clear();
    assert(hashMap0.length == 0);
    hashMap0[1] = 1;
    assert(hashMap0.contains(1) && hashMap0.length == 1);
    foreach (i; 0 .. 100) {
        assert(hashMap1.contains(i));
    }
}
//
// test addIfMissed
//
@("L" ~ to!string(__LINE__) ~ ".@safe @nogc addIfMissed()")
@safe @nogc unittest {
    HashMap!(int, int) map;

    foreach (i; 0 .. 100) {
        map[i] = i;
    }
    assert(map.addIfMissed(101, 101));
    assert(!map.addIfMissed(101, 102));
}

@("L" ~ to!string(__LINE__) ~ ".using const keys")
@safe unittest {
    class CM {
    }

    class C {
        hash_t c;
        override hash_t toHash() const @safe {
            return c;
        }

        bool opEquals(const C other) const @safe {
            return c == other.c;
        }

        this(hash_t i) {
            c = i;
        }
    }
    // try const keys
    HashMap!(C, int) map;
    int f(const C c) {
        auto v = map[c];
        // can't do this with classes because put require key assignment which can't convert const object to mutable
        //map.put(c, 2);
        return map.fetch(c).value;
    }

    C c = new C(1);
    map[c] = 1;
    f(c);
    /// try const map
    const HashMap!(C, bool) cmap;
    auto a = cmap.fetch(c);
    try {
        auto b = cmap[c];
    }
    catch (Exception e) {
    }

    struct S {
        int[] a;
        void opAssign(const S rhs) {
        }
    }

    HashMap!(S, int) smap;
    auto fs(const S s) {
        // can be done with struct if there is no references or if you have defined opAssign from const
        smap.put(s, 2);
        return smap.fetch(s);
    }

    S s = S();
    fs(s);
    ///
}


@("L" ~ to!string(__LINE__) ~ ".safety with various dangerous ops")
@safe unittest {
    import std.stdio;
    import std.array;
    import std.algorithm;
    import std.range;
    import std.conv;

    class C {
        int c;
        this(int i) {
            c = i;
        }

        override hash_t toHash() const @safe @nogc {
            return hash_function(c);
        }

        bool opEquals(const C other) const @safe {
            return c == other.c;
        }
    }

    HashMap!(int, C) h;
    foreach (i; 0 .. 500) {
        h[i] = new C(i);
    }
    auto pairs = h.byPair();
    auto keys = h.byKey();
    auto values = h.byValue();
    h.clear();
    foreach (i; 0 .. 50000) {
        h[i] = new C(i);
    }
    auto after_clear_pairs = pairs.array.sort!"a.key < b.key";
    assert(equal(after_clear_pairs.map!"a.key", iota(500)));
    assert(equal(after_clear_pairs.map!"a.value.c", iota(500)));

    auto after_clear_keys = keys.array.sort!"a < b";
    assert(equal(after_clear_keys, iota(500)));

    auto after_clear_values = values.array
        .sort!"a.c < b.c"
        .map!"a.c";
    assert(equal(after_clear_values, iota(500)));

    HashMap!(C, int) hc;
    auto nc = new C(1);
    hc[nc] = 1;
    auto p = hc.fetch(nc);
    assert(p.ok && p.value == 1);
    p = hc.fetch(new C(2));
    assert(!p.ok);
}

@("L" ~ to!string(__LINE__) ~ ".hashMap assignments")
@safe
unittest {
    class C {
        int c;
        this(int i) {
            c = i;
        }

        override hash_t toHash() const @safe @nogc {
            return hash_function(c);
        }

        bool opEquals(const C other) inout @safe {
            return c == other.c;
        }
    }
    HashMap!(C, int) m1;
    m1[new C(1)] = 1;
    m1 = m1;
    assert(m1[new C(1)] == 1);
}

@("L" ~ to!string(__LINE__) ~ ".reallocate works as for slices")
@safe
unittest {
    HashMap!(int, string) amap, bmap;
    int i;
    do {
        amap[i++] = "a";
    } while(amap.capacity>0);
    assert(amap.capacity == 0);
    // at this point amap capacity is 0 and any insertion will resize/reallocate
    bmap = amap;    // amap and bmap share underlying storage
    assert(amap[0] == bmap[0]);
    amap[i] = "a";          // after this assignment amap will reallocate
    amap[0] = "b";          // this write goes to new store
    assert(amap[0] == "b"); // amap use new storage
    assert(bmap[0] == "a"); // bmap still use old storage

    // the same story with dynamic arrays
    int[4] sarray = [1,2,3,4];
    int[] aslice = sarray[], bslice;
    assert(aslice.capacity == 0);
    // at this point aslice capacity is 0 and any appending will reallocate
    bslice = aslice;                // aslice and bslice will share storage until aslice reallocate
    assert(aslice[0] == bslice[0]);
    assert(aslice[0] is bslice[0]);
    aslice ~= 1;                    // this append reallocate
    aslice[0] = 2;                  // this write goes to new storage
    assert(bslice[0] == 1);         // bslice still use old storage
    assert(aslice[0] == 2);         // aslice use new storage
}

@("L" ~ to!string(__LINE__) ~ ".table consistency after exception")
@safe
unittest {
    import std.exception;
    import std.stdio;
    import std.format;
    import std.array;

    struct FaultyHash {
        int c;
        this(int i) {
            c = i;
        }

        hash_t toHash() inout @safe {
            if ( c > 0 )
                throw new Exception("hash");
            return hash_function(c);
        }

        bool opEquals(FaultyHash other) inout @safe {
            return c == other.c;
        }
    }

    HashMap!(FaultyHash, int) map;
    auto c1 = FaultyHash(1);
    assertThrown!Exception(map.put(c1, 1));
    assertThrown!Exception(map[c1] = 1);
    assert(map.length == 0);
    auto c0 = FaultyHash(0);
    map[c0] = 1;
    assert(map.length == 1);

    static int counter;
    static bool throw_enabled = true;

    struct FaultyCopyCtor {
        int c;

        this(int i) {
            c = i;
        }

        this(this) @safe {
            counter++;
            if (counter > 1 && throw_enabled ) throw new Exception("copy");
        }
        hash_t toHash() inout @safe {
            return 0;
        }

        bool opEquals(FaultyCopyCtor other) @safe {
            return true;
        }
        auto toString() inout {
            return "[%d]".format(c);
        }
    }
    FaultyCopyCtor fcc1 = FaultyCopyCtor(1);
    HashMap!(int, FaultyCopyCtor) map2;
    assertThrown!Exception(map2.put(1, fcc1));
    assert(map2.length == 0);
    throw_enabled = false;
    map2.put(1, fcc1);
    assert(map2.byValue.array.length == 1);
    assert(map2.length == 1);
    counter = 0;
    throw_enabled = true;
    map2.clear;
    assertThrown!Exception(map2[1] = fcc1);
    assert(map2.length == 0);
}

@("L" ~ to!string(__LINE__) ~ ".iterator correctness after mutation")
@safe
unittest
{
    import std.range, std.algorithm;
    HashMap!(int, int) m;
    iota(16).each!(i => m[2*i] = 2*i);
    assert(m.length == 16);
    int removed;
    foreach(k; m.byKey)
    {
        removed += m.remove(k) ? 1 : 0;
        m[k+1] = k+1;
        m[32+k] = 32 + k;
    }
    assert(removed == 16);
    assert(m.length == 32);
    iota(16).all!(i => !m.contains(i));
}