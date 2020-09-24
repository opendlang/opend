import std.stdio;
import std.random;
import std.datetime.stopwatch;
import std.algorithm, std.range;
import std.conv;
import std.experimental.allocator.gc_allocator;
import std.experimental.allocator.mallocator;
import core.memory;
import std.typecons;
import std.experimental.logger;

// emsi_containers
import containers.hashmap;
import containers.unrolledlist;

// ikod containers
import ikod.containers.hashmap;
import ikod.containers.compressedlist;

immutable iterations = 1_000_000;
immutable trials = 1;

GC.Stats gcstart, gcstop;


struct LARGE {
    import std.conv;
    int i;
    long l;
    double d;
    long l1;
    long l2;
    long l3;
    long l4;
    hash_t toHash() const nothrow @safe @nogc
    {
        return hash_function(i);
    }
    bool opEquals(ref const LARGE other) pure const @safe nothrow
    {
        return i == other.i;
    }
    this(int i) inout @safe @nogc
    {
        this.i = i;
        l = i;
        d = i;
    }
}
struct LARGE_REF {
    import std.conv;
    int i;
    long l;
    double d;
    string s;
    long l1;
    long l2;
    long l3;
    long l4;
    hash_t toHash() const nothrow @safe @nogc
    {
        return hash_function(i);
    }
    bool opEquals(ref const LARGE_REF other) pure const @safe nothrow
    {
        return i == other.i;
    }
    this(int i) inout @safe @nogc
    {
        this.i = i;
        l = i;
        d = i;
        //s = "large struct";// to!string(i);
    }
}
class CLASS {
    import std.conv;
    int i;
    long l;
    double d;
    string s;
    long l1;
    long l2;
    long l3;
    long l4;
    override hash_t toHash() const @safe @nogc
    {
        return hash_function(i);
    }
    bool opEquals(const CLASS other) pure const @safe nothrow
    {
        return i == other.i;
    }
    this(int i) immutable @safe @nogc
    {
        this.i = i;
        l = i;
        d = i;
        s = "large class";// to!string(i);
    }
}

void main()
{

    import std.string;
    import std.experimental.logger;
    globalLogLevel = LogLevel.info;
    string test;
    Duration[1] r;

    int hits;
    int[iterations] randw, randr;

    auto rnd = Random(unpredictableSeed);
    foreach(i;0..iterations)
    {
        randw[i] = uniform(0, iterations, rnd);
        randr[i] = uniform(0, iterations, rnd);
    }

    CompressedList!(string) words;
    auto f = File("t8.shakespeare.txt", "r");
    foreach(word; f.byLine.map!splitter.joiner) {
        words.insertBack(word.idup);
    }
    f.close();


    void f_AA() @safe {
        gcstart = () @trusted {return GC.stats;}();

        int[int] c;
        foreach(i;0..iterations) {
            int k = randw[i];
            c[k] = i;
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            auto v = k in c;
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;} ();
    }
    void f_oahashmap() @safe {
        gcstart = () @trusted {return GC.stats;}();

        ikod.containers.hashmap.HashMap!(int, int) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c.put(k, i);
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            auto v = c.contains(k);
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;} ();
    }

    void f_oahashmapGC() @safe {
        gcstart = () @trusted {return GC.stats;}();

        ikod.containers.hashmap.HashMap!(int, int, GCAllocator) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c.put(k, i);
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            auto v = c.contains(k);
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;} ();
    }


    void f_hashmap() {
        gcstart = () @trusted {return GC.stats;}();

        containers.hashmap.HashMap!(int, int) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c[k] = i;
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            auto v = k in c;
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;} ();
    }


    void f_aahashmapscan() @safe {
        gcstart = () @trusted {return GC.stats;}();

        int[int] c;

        foreach(k;0..10)
            foreach(i;0..iterations) {
                c[i]= i;
                c.remove(i-50000);
                if ( randw[i] in c)
                {
                    ++hits;
                }
            }

        gcstop = () @trusted {return GC.stats;} ();
    }
    void f_oahashmapscan() @safe {
        gcstart = () @trusted {return GC.stats;}();

        ikod.containers.hashmap.HashMap!(int, int) c;

        foreach(k;0..10)
            foreach(i;0..iterations) {
                c.put(i, i);
                c.remove(i-50000);
                if ( c.contains(randw[i]))
                {
                    ++hits;
                }
            }

        gcstop = () @trusted {return GC.stats;} ();
    }

    void f_emsiscan() /*@safe*/ {
        gcstart = () @trusted {return GC.stats;}();

        containers.hashmap.HashMap!(int, int) c;

        foreach(k;0..10)
            foreach(i;0..iterations) {
                c[i] = i;
                c.remove(i-50000);
                if ( randw[i] in c )
                {
                    ++hits;
                }
            }

        gcstop = () @trusted {return GC.stats;} ();
    }

    void f_AA_remove() @safe {
        gcstart = () @trusted {return GC.stats;}();

        int[int] c;
        foreach(i;0..iterations) {
            int k = randw[i];
            c[k] = i;
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            c.remove(k);
        }
        foreach(i; 0..iterations) {
            int k = randw[i];
            auto v = k in c;
        }
        gcstop = () @trusted {return GC.stats;} ();
    }
    void f_oahashmapGC_remove() @safe {
        gcstart = () @trusted {return GC.stats;}();

        ikod.containers.hashmap.HashMap!(int, int, GCAllocator) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c.put(k, i);
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            c.remove(k);
        }
        foreach(i; 0..iterations) {
            int k = randw[i];
            auto v = c.contains(k);
        }
        gcstop = () @trusted {return GC.stats;} ();
    }
    void f_oahashmap_remove() @safe {
        gcstart = () @trusted {return GC.stats;}();

        ikod.containers.hashmap.HashMap!(int, int) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c.put(k, i);
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            c.remove(k);
        }
        foreach(i; 0..iterations) {
            int k = randw[i];
            auto v = c.contains(k);
        }
        gcstop = () @trusted {return GC.stats;} ();
    }

    void f_hashmap_remove() {
        gcstart = () @trusted {return GC.stats;}();

        containers.hashmap.HashMap!(int, int) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c[k] = i;
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            c.remove(k);
        }
        foreach(i; 0..iterations) {
            int k = randw[i];
            auto v = k in c;
        }
        gcstop = () @trusted {return GC.stats;} ();
    }

    void LARGE_AA() @safe {
        gcstart = () @trusted {return GC.stats;}();

        LARGE[int] c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c[k] = LARGE(i);
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            auto v = k in c;
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    void OALARGE() @safe {
        gcstart = () @trusted {return GC.stats;}();

        ikod.containers.hashmap.HashMap!(int, LARGE) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c.put(k, LARGE(i));
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            auto v = c.contains(k);
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    void OALARGE_GC() @safe {
        gcstart = () @trusted {return GC.stats;}();

        ikod.containers.hashmap.HashMap!(int, LARGE, GCAllocator) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c.put(k, LARGE(i));
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            auto v = c.contains(k);
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    void HMLARGE() {
        gcstart = () @trusted {return GC.stats;}();

        containers.hashmap.HashMap!(int, LARGE) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c[k] = LARGE(i);
        }

        foreach(i; 0..iterations) {
            int k = randr[i];
            auto v = k in c;
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void structkey_AA() @safe {
        gcstart = () @trusted {return GC.stats;}();

        int[immutable LARGE] c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c[LARGE(k)] = k;
        }

        foreach(i; 0..iterations) {
            immutable k = immutable LARGE(randr[i]);
            auto v = k in c;
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    void structkey_OA() @safe {
        gcstart = () @trusted {return GC.stats;}();

        ikod.containers.hashmap.HashMap!(immutable LARGE, int) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c[LARGE(k)] = k;
        }

        foreach(i; 0..iterations) {
            immutable k = immutable LARGE(randr[i]);
            auto v = c.contains(k);
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    void structkey_OAGC() @safe {
        gcstart = () @trusted {return GC.stats;}();

        ikod.containers.hashmap.HashMap!(immutable LARGE, int, GCAllocator) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c[LARGE(k)] = k;
        }

        foreach(i; 0..iterations) {
            immutable k = immutable LARGE(randr[i]);
            auto v = c.contains(k);
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    void structkey_emsi()
    {
        gcstart = () @trusted {return GC.stats;}();

        containers.hashmap.HashMap!(immutable LARGE, int) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            c[LARGE(k)] = k;
        }

        foreach(i; 0..iterations) {
            immutable k = immutable LARGE(randr[i]);
            auto v = k in c;
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void classkey_AA() @safe {
        gcstart = () @trusted {return GC.stats;}();

        int[immutable CLASS] c;

        foreach(i;0..iterations) {
            int k = randw[i];
            immutable key = new immutable CLASS(k);
            c[key] = i;
        }

        foreach(i; 0..iterations) {
            immutable k = new immutable CLASS(randr[i]);
            auto v = k in c;
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    void classkey_OA() @safe {
        gcstart = () @trusted {return GC.stats;}();

        ikod.containers.hashmap.HashMap!(immutable CLASS, int) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            immutable key = new immutable CLASS(k);
            c[key] = i;
        }

        foreach(i; 0..iterations) {
            immutable k = new immutable CLASS(randr[i]);
            auto v = c.contains(k);
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    void classkey_OAGC() @safe
    {
        gcstart = () @trusted {return GC.stats;}();

        ikod.containers.hashmap.HashMap!(immutable CLASS, int, GCAllocator) c;

        foreach(i;0..iterations) {
            int k = randw[i];
            immutable key = new immutable CLASS(k);
            c[key] = i;
        }

        foreach(i; 0..iterations) {
            immutable k = new immutable CLASS(randr[i]);
            auto v = c.contains(k);
            if ( v ) {
                hits++;
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    // void classkey_emsi()
    // {
    //     // emsi do not support immutable classes?
    //     gcstart = () @trusted {return GC.stats;}();

    //     containers.hashmap.HashMap!(immutable CLASS, int) c;

    //     foreach(i;0..iterations) {
    //         int k = randw[i];
    //         immutable key = new immutable CLASS(k);
    //         c[key] = i;
    //     }

    //     foreach(i; 0..iterations) {
    //         immutable k = new immutable CLASS(randr[i]);
    //         auto v = k in c;
    //         if ( v ) {
    //             hits++;
    //         }
    //     }
    //     gcstop = () @trusted {return GC.stats;}();
    // }
    void test_dlist_std()
    {
        import std.container.dlist;
        gcstart = () @trusted {return GC.stats;}();
        auto intList = new DList!int;
        foreach(i; randw)
        {
            intList.insertBack(i);
            if (i < iterations/10)
            {
                intList.removeFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_slist_std()
    {
        import std.container.slist;
        gcstart = () @trusted {return GC.stats;}();
        auto intList = new SList!int;
        foreach(i; randw)
        {
            intList.insertFront(i);
            if (i < iterations/10)
            {
                intList.removeFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
/*
    void test_dlist_cachetools() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        DList!int intList;
        foreach(i; randw)
        {
            intList.insert_last(i);
            if (i < iterations/10)
            {
                intList.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    void test_slist_cachetools() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        SList!int intList;
        foreach(i; randw)
        {
            intList.insertFront(i);
            if (i < iterations/10)
            {
                intList.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_dlist_cachetools_GC() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        DList!(int, GCAllocator) intList;
        foreach(i; randw)
        {
            intList.insert_last(i);
            if (i < iterations/10)
            {
                intList.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    void test_slist_cachetools_GC() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        SList!(int, GCAllocator) intList;
        foreach(i; randw)
        {
            intList.insertFront(i);
            if (i < iterations/10)
            {
                intList.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
*/
    void test_clist_cachetools() @safe
    {
        import ikod.containers.compressedlist;
        gcstart = () @trusted {return GC.stats;}();
        CompressedList!int intList;
        foreach(i; randw)
        {
            intList.insertFront(i);
            if (i < iterations/10)
            {
                intList.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_clist_cachetoolsGC() @safe
    {
        import ikod.containers.compressedlist;
        gcstart = () @trusted {return GC.stats;}();
        CompressedList!(int, GCAllocator) intList;
        foreach(i; randw)
        {
            intList.insertFront(i);
            if (i < iterations/10)
            {
                intList.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    void test_dlist_emsi()
    {
        import containers.unrolledlist;
        gcstart = () @trusted {return GC.stats;}();
        UnrolledList!int intList;
        foreach(i; randw)
        {
            intList.insertBack(i);
            if (i < iterations/10)
            {
                intList.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
/*
    void test_slist_emsi()
    {
        import containers.slist: SList;
        gcstart = () @trusted {return GC.stats;}();
        SList!int intList;
        foreach(i; randw)
        {
            intList.insertFront(i);
            if (i < iterations/10)
            {
                intList.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    // --
    void test_dlist_std_LARGE()
    {
        import std.container.dlist;
        gcstart = () @trusted {return GC.stats;}();
        auto list = new DList!LARGE;
        foreach(i; randw)
        {
            list.insertBack(LARGE(i));
            if (i < iterations/10)
            {
                list.removeFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_dlist_cachetools_LARGE() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        DList!LARGE list;
        foreach(i; randw)
        {
            list.insert_last(LARGE(i));
            if (i < iterations/10)
            {
                list.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_dlist_cachetools_LARGE_GC() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        DList!(LARGE, GCAllocator) list;
        foreach(i; randw)
        {
            list.insert_last(LARGE(i));
            if (i < iterations/10)
            {
                list.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_clist_cachetools_LARGE() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        CompressedList!(LARGE) list;
        foreach(i; randw)
        {
            list.insertBack(LARGE(i));
            if (i < iterations/10)
            {
                list.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_clist_cachetools_LARGE_GC() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        CompressedList!(LARGE, GCAllocator) list;
        foreach(i; randw)
        {
            list.insertBack(LARGE(i));
            if (i < iterations/10)
            {
                list.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_dlist_emsi_LARGE()
    {
        import containers.unrolledlist;
        gcstart = () @trusted {return GC.stats;}();
        UnrolledList!LARGE list;
        foreach(i; randw)
        {
            list.insertBack(LARGE(i));
            if (i < iterations/10)
            {
                list.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
    // - large with ref
    // --
    void test_dlist_std_LARGE_REF()
    {
        import std.container.dlist;
        gcstart = () @trusted {return GC.stats;}();
        auto list = new DList!LARGE_REF;
        foreach(i; randw)
        {
            list.insertBack(LARGE_REF(i));
            if (i < iterations/10)
            {
                list.removeFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_dlist_cachetools_LARGE_REF() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        DList!(LARGE_REF) list;
        foreach(i; randw)
        {
            list.insertBack(LARGE_REF(i));
            if (i < iterations/10)
            {
                list.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_dlist_cachetools_LARGE_REF_GC() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        DList!(LARGE_REF, GCAllocator) list;
        foreach(i; randw)
        {
            list.insertBack(LARGE_REF(i));
            if (i < iterations/10)
            {
                list.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_clist_cachetools_LARGE_REF() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        CompressedList!(LARGE_REF) list;
        foreach(i; randw)
        {
            list.insertBack(LARGE_REF(i));
            if (i < iterations/10)
            {
                list.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_clist_cachetools_LARGE_REF_GC() @safe
    {
        import cachetools.containers.lists;
        gcstart = () @trusted {return GC.stats;}();
        CompressedList!(LARGE_REF, GCAllocator) list;
        foreach(i; randw)
        {
            list.insertBack(LARGE_REF(i));
            if (i < iterations/10)
            {
                list.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }

    void test_dlist_emsi_LARGE_REF()
    {
        import containers.unrolledlist;
        gcstart = () @trusted {return GC.stats;}();
        UnrolledList!LARGE_REF list;
        foreach(i; randw)
        {
            list.insertBack(LARGE_REF(i));
            if (i < iterations/10)
            {
                list.popFront();
            }
        }
        gcstop = () @trusted {return GC.stats;}();
    }
*/
    ///
    void shakespeare_std()
    {
        gcstart = () @trusted {return GC.stats;} ();

        int[string] count;
        void updateCount(string word) {
            auto ptr = word in count;
            if (!ptr)
                count[word] = 1;
            else
                (*ptr)++;
        }
        foreach(word; words.range()) {
            updateCount(word);
        }
        gcstop = () @trusted {return GC.stats;} ();
    }
    void shakespeare_OAHashMap()
    {
        gcstart = () @trusted {return GC.stats;} ();

        ikod.containers.hashmap.HashMap!(string, int) count;

        void updateCount(string word) {
            count[word] = count.get(word, 0)+1;
        }

        foreach(word; words.range()) {
            updateCount(word);
        }
        gcstop = () @trusted {return GC.stats;} ();
    }
    void shakespeare_OAHashMapGC()
    {
        gcstart = () @trusted {return GC.stats;} ();

        ikod.containers.hashmap.HashMap!(string, int, GCAllocator) count;

        void updateCount(string word) {
            count[word] = count.get(word, 0)+1;
        }

        foreach(word; words.range()) {
            updateCount(word);
        }
        gcstop = () @trusted {return GC.stats;} ();
    }

    void shakespeare_HashMap()
    {
        gcstart = () @trusted {return GC.stats;} ();

        containers.hashmap.HashMap!(string, int) count;

        void updateCount(string word) {
            auto ptr = word in count;
            if (!ptr)
                count[word] = 1;
            else
                (*ptr)++;
        }

        foreach(word; words.range()) {
            updateCount(word);
        }
        gcstop = () @trusted {return GC.stats;} ();
    }

    void test_integrity()
    {
        int[string] stdcount;
        void updateStdCount(string word) {
            auto ptr = word in stdcount;
            if (!ptr)
                stdcount[word] = 1;
            else
                (*ptr)++;
        }
        foreach(word; words.range()) {
            updateStdCount(word);
        }

        ikod.containers.hashmap.HashMap!(string, int) mycount;

        void updateMyCount(string word) {
            mycount[word] = mycount.get(word, 0)+1;
        }

        foreach(word; words.range()) {
            updateMyCount(word);
        }
        assert(stdcount.length == mycount.length);
        foreach(pair; mycount.byPair)
        {
            assert(pair.value == stdcount[pair.key]);
        }
    }

    string fmt  = "|%-11.11s | %-31.31s | GC memory Δ %6.2f MB|";
    string fmth = "|%-11.11s | %-31.31s | GC memory Δ %6.2f MB| hits %.2f|";

    writeln("\n", center(" Test inserts and lookups int[int] ", 50, ' '));
    writeln(      center(" ================================= ", 50, ' '));

    GC.collect();GC.minimize();
    test = "std";
    r = benchmark!(f_AA)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.";
    r = benchmark!(f_oahashmap)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.+GC";
    r = benchmark!(f_oahashmapGC)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    version(Posix)
    {
        // emsi-containers do not work for me under windows
        GC.collect();GC.minimize();
        test = "emsi";
        r = benchmark!(f_hashmap)(trials);
        writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);
    }

    writeln("\n", center(" Test scan ", 50, ' '));
    writeln(      center(" ========= ", 50, ' '));

    GC.collect();GC.minimize();
    test = "std";
    r = benchmark!(f_aahashmapscan)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.";
    r = benchmark!(f_oahashmapscan)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);
    
    GC.collect();GC.minimize();
    test = "emsi";
    r = benchmark!(f_emsiscan)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);
    
    
    writeln("\n", center(" Test insert, remove, lookup for int[int]", 50, ' '));
    writeln(      center(" ======================================= ", 50, ' '));

    GC.collect();GC.minimize();
    test = "std";
    r = benchmark!(f_AA_remove)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.";
    r = benchmark!(f_oahashmap_remove)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.+GC";
    r = benchmark!(f_oahashmapGC_remove)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    version(Posix)
    {
        // emsi-containers do not work for me under windows
        GC.collect();GC.minimize();
        test = "emsi";
        r = benchmark!(f_hashmap_remove)(trials);
        writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);
    }

    writeln("\n", center(" Test inserts and lookups for struct[int] ", 50, ' '));
    writeln(      center(" ======================================= ", 50, ' '));

    GC.collect();GC.minimize();
    test = "std";
    r = benchmark!(LARGE_AA)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.";
    r = benchmark!(OALARGE)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.+GC";
    r = benchmark!(OALARGE_GC)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    version(Posix)
    {
        // emsi-containers do not work for me under windows
        GC.collect();GC.minimize();
        test = "emsi";
        r = benchmark!(HMLARGE)(trials);
        writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);
    }

    writeln("\n", center(" Test inserts and lookups for int[struct] ", 50, ' '));
    writeln(      center(" ======================================= ", 50, ' '));

    GC.collect();GC.minimize();
    test = "std";
    r = benchmark!(structkey_AA)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.";
    r = benchmark!(structkey_OA)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.+GC";
    r = benchmark!(structkey_OAGC)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    version(Posix)
    {
         //this test lead to crash under win and linux
         GC.collect();GC.minimize();
         test = "emsi";
         r = benchmark!(structkey_emsi)(trials);
         writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);
    }

    writeln("\n", center(" Test inserts and lookups for int[class] ", 50, ' '));
    writeln(      center(" ======================================= ", 50, ' '));

    GC.collect();GC.minimize();
    test = "std";
    r = benchmark!(classkey_AA)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.";
    r = benchmark!(classkey_OA)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.+GC";
    r = benchmark!(structkey_OAGC)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    // emsi wont compile with immutable class as key
    // version(Posix)
    // {
    //    GC.collect();GC.minimize();
    //    test = "emsi";
    //    r = benchmark!(classkey_emsi)(trials);
    //    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);
    // }
    writefln(fmt, "emsi", "can't compile", 0.0);


    writeln("\n", center(" Test word counting int[string]", 50, ' '));
    writeln(      center(" ============================= ", 50, ' '));

    GC.collect();GC.minimize();
    test = "std";
    r = benchmark!shakespeare_std(1);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.";
    r = benchmark!shakespeare_OAHashMap(1);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    GC.collect();GC.minimize();
    test = "i.c.+GC";
    r = benchmark!shakespeare_OAHashMapGC(1);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

    version(Posix)
    {
        // emsi-containers do not work for me under windows
        GC.collect();GC.minimize();
        test = "emsi  ";
        r = benchmark!shakespeare_HashMap(1);
        writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);
    }

    GC.collect();GC.minimize();
    test = "correctness";
    r = benchmark!test_integrity(1);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);


    writeln("\n", center(" Test double-linked list DList!int ", 50, ' '));
    writeln(      center(" ================================= ", 50, ' '));

    GC.collect();GC.minimize();
    test = "std";
    r = benchmark!(test_dlist_std)(trials);
    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.";
//    r = benchmark!(test_dlist_cachetools)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.+GC";
//    r = benchmark!(test_dlist_cachetools_GC)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

   GC.collect();GC.minimize();
   test = "i.c.unroll";
   r = benchmark!(test_clist_cachetools)(trials);
   writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

   GC.collect();GC.minimize();
   test = "i.c.unr+GC";
   r = benchmark!(test_clist_cachetoolsGC)(trials);
   writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

   GC.collect();GC.minimize();
   test = "emsiunroll";
   r = benchmark!(test_dlist_emsi)(trials);
   writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);


//    writeln("\n", center(" Test single-linked list SList!int ", 50, ' '));
//    writeln(      center(" ================================= ", 50, ' '));

//    GC.collect();GC.minimize();
//    test = "std";
//    r = benchmark!(test_slist_std)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.";
//    r = benchmark!(test_slist_cachetools)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.+GC";
//    r = benchmark!(test_slist_cachetools_GC)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "emsi";
//    r = benchmark!(test_slist_emsi)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);


//    writeln("\n", center(" Test double-linked list of structs ", 50, ' '));
//    writeln(      center(" ================================== ", 50, ' '));

//    GC.collect();GC.minimize();
//    test = "std";
//    r = benchmark!(test_dlist_std_LARGE)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.";
//    r = benchmark!(test_dlist_cachetools_LARGE)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.+GC";
//    r = benchmark!(test_dlist_cachetools_LARGE_GC)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.unr";
//    r = benchmark!(test_clist_cachetools_LARGE)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.unr+GC";
//    r = benchmark!(test_clist_cachetools_LARGE_GC)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "emsi";
//    r = benchmark!(test_dlist_emsi_LARGE)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    writeln("\n", center(" Test double-linked list of structs with ref ", 50, ' '));
//    writeln(      center(" =========================================== ", 50, ' '));

//    GC.collect();GC.minimize();
//    test = "std";
//    r = benchmark!(test_dlist_std_LARGE_REF)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.";
//    r = benchmark!(test_dlist_cachetools_LARGE_REF)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.+GC";
//    r = benchmark!(test_dlist_cachetools_LARGE_REF_GC)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.unr";
//    r = benchmark!(test_clist_cachetools_LARGE_REF)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "i.c.unr+GC";
//    r = benchmark!(test_clist_cachetools_LARGE_REF_GC)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    GC.collect();GC.minimize();
//    test = "emsi";
//    r = benchmark!(test_dlist_emsi_LARGE_REF)(trials);
//    writefln(fmt, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024);

//    writeln("\n", center(" Test cache ", 50, ' '));
//    writeln(      center(" ========== ", 50, ' '));

//    test = "lru";
//    GC.collect();GC.minimize();
//    r = benchmark!(test_ct_cache)(trials);
//    writefln(fmth, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024, (1e0*hits)/words.length/2);

//    test = "lru+GC";
//    GC.collect();GC.minimize();
//    r = benchmark!(test_ct_cache_gc)(trials);
//    writefln(fmth, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024, (1e0*hits)/words.length/2);

//    test = "2Q";
//    GC.collect();GC.minimize();
//    r = benchmark!(test_2q_cache)(trials);
//    writefln(fmth, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024, (1e0*hits)/words.length/2);

//    test = "2Q+GC";
//    GC.collect();GC.minimize();
//    r = benchmark!(test_2q_gc_cache)(trials);
//    writefln(fmth, test, to!string(r[0]), 1e0*(gcstop.usedSize - gcstart.usedSize)/1024/1024, (1e0*hits)/words.length/2);
}
