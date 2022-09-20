/++
+/
module mir.ion.symbol_table;

import mir.utility: min, max, swap, _expect;
import mir.internal.memory;

// hash - string hash
// key - string start position
// value - symbol id

/++
Each version of the Ion specification defines the corresponding system symbol table version.
Ion 1.0 uses the `"$ion"` symbol table, version 1,
and future versions of Ion will use larger versions of the `"$ion"` symbol table.
`$ion_1_1` will probably use version 2, while `$ion_2_0` might use version 5.

Applications and users should never have to care about these symbol table versions,
since they are never explicit in user data: this specification disallows (by ignoring) imports named `"$ion"`.

Here are the system symbols for Ion 1.0.
+/
static immutable string[] IonSystemSymbolTable_v1 = [
    "$0",
    "$ion",
    "$ion_1_0",
    "$ion_symbol_table",
    "name",
    "version",
    "imports",
    "symbols",
    "max_id",
    "$ion_shared_symbol_table",
];

/++
+/
enum IonSystemSymbol : ubyte
{
    ///
    zero,
    ///
    ion,
    ///
    ion_1_0,
    ///
    ion_symbol_table,
    ///
    name,
    ///
    version_,
    ///
    imports,
    ///
    symbols,
    ///
    max_id,
    ///
    ion_shared_symbol_table,
}

package(mir) string[] removeSystemSymbols(const(string)[] keys) @safe pure nothrow
{
    string[] ret;
    F: foreach (key; keys) switch(key)
    {
        static foreach (skey; IonSystemSymbolTable_v1)
        {
            case skey: continue F;
        }
        default:
            ret ~= key;
    }
    return ret;
}

struct IonSymbolTableSequental
{
    import mir.ser.ion: IonSerializer;
    import mir.ndslice.slice;
    import core.stdc.string;
    import core.stdc.stdio;

    static struct Entry
    {
        ulong* data;
        uint[] ids;
    }

    ulong[] temporalStorage;
    Entry[] entries;
    uint nextID = IonSystemSymbol.max + 1;
    IonSerializer!(1024, null, false) serializer = void;
    enum size_t annotationWrapperState = 0;
    enum size_t annotationsState = 5;
    enum size_t structState = 5;
    enum size_t listState = 9;

@trusted pure nothrow @nogc:

    // $ion_symbol_table::
    // {
    //     symbols:[ ... ]
    // }
    void initialize()(size_t n = 64)
    {
        pragma(inline, true);
        auto llen = n / ulong.sizeof + (n % ulong.sizeof != 0);
        auto temporalStoragePtr = cast(ulong*) malloc(llen * ulong.sizeof);
        this.temporalStorage = temporalStoragePtr[0 .. llen];
        auto entriesPtr = cast(Entry*) malloc(n * Entry.sizeof);
        this.entries = entriesPtr[0 .. n];
        this.entries[] = Entry.init;
        this.nextID = IonSystemSymbol.max + 1;
        this.serializer.initializeNoTable;

        auto annotationWrapperState = serializer.annotationWrapperBegin;
        assert(annotationWrapperState == this.annotationWrapperState);
        serializer.putAnnotationId(IonSystemSymbol.ion_symbol_table);
        auto annotationsState = serializer.annotationsEnd(annotationWrapperState);
        assert(annotationsState == this.annotationsState);
        auto structState = serializer.structBegin();
        assert(structState == this.structState);
        serializer.putKeyId(IonSystemSymbol.symbols);
        auto listState = serializer.listBegin();
        assert(listState == this.listState);
    }

    void finalize()()
    {
        pragma(inline, true);
        if (nextID > IonSystemSymbol.max + 1)
        {
            serializer.listEnd(listState);
            serializer.structEnd(structState);
            serializer.annotationWrapperEnd(annotationsState, annotationWrapperState);
        }
        else
        {
            serializer.buffer._currentLength = 0;
        }

        temporalStorage.ptr.free;
        foreach(ref e; entries)
        {
            e.data.free;
            e.ids.ptr.free;
        }
        entries.ptr.free;
    }

    uint insert()(scope const(char)[] str)
    {
        pragma(inline, true);
        auto n = str.length;
        auto llen = n / ulong.sizeof + (n % ulong.sizeof != 0);
        if (_expect(n >= entries.length, false))
        {
            auto oldLength = entries.length;
            auto temporalStoragePtr = cast(ulong*) realloc(temporalStorage.ptr, llen * ulong.sizeof);
            this.temporalStorage = temporalStoragePtr[0 .. llen];
            this.temporalStorage.ptr[0] = 0;
            auto entriesPtr = cast(Entry*) realloc(entries.ptr, n * Entry.sizeof);
            this.entries = entriesPtr[0 .. n];
            this.entries[oldLength .. $] = Entry.init;
        }
        temporalStorage.ptr[0] = 0;
        memcpy(cast(ubyte*)(temporalStorage.ptr + llen) - str.length, str.ptr, str.length);

        // {
        //     auto tempPtr0 = cast(ubyte*)(temporalStorage.ptr + llen) - str.length;
        //     foreach (i; 0 .. str.length)
        //         tempPtr0[i] = str[i];
        // }

        with(entries[n])
        {
            if (_expect(ids.length == 0, false))
            {
                auto idsPtr = cast(uint*)malloc(uint.sizeof);
                ids = idsPtr[0 .. 1];
                if (llen)
                {
                    data = cast(ulong*) malloc(ulong.sizeof * llen);
                    memcpy(data, temporalStorage.ptr, llen * ulong.sizeof);
                }
                goto R;
            }
            if (llen == 0)
                return ids[0];
            {
                sizediff_t i = ids.length - 1;
                L: do
                {
                    sizediff_t j = llen - 1;
                    auto datai = data + i * llen;
                    for(;;)
                    {
                        if (datai[j] == temporalStorage[j])
                        {
                            if (--j >= 0)
                                continue;
                            return ids.ptr[i];
                        }
                        break;
                    }
                }
                while (--i >= 0);
            }

            {
                auto idsPtr = cast(uint*)realloc(ids.ptr, (ids.length + 1) * uint.sizeof);
                ids = idsPtr[0 .. ids.length + 1];
                data = cast(ulong*) realloc(data, ids.length * ulong.sizeof * llen);
                memcpy(data + llen * (ids.length - 1), temporalStorage.ptr, llen * ulong.sizeof);
            }
        R:
            serializer.putValue(str);
            return ids.ptr[ids.length - 1] = nextID++;
        }
    }
}

unittest
{
    import mir.test;
    import mir.ion.conv: text2ion;

    {
        IonSymbolTableSequental symbolTable = void;
        symbolTable.initialize;
        symbolTable.finalize;
        symbolTable.serializer.data.should == [];
    }


    {
        IonSymbolTableSequental symbolTable = void;
        symbolTable.initialize;
        symbolTable.insert(`id`);
        symbolTable.finalize;
        symbolTable.serializer.data.should == [0xE8, 0x81, 0x83, 0xD5, 0x87, 0xB3, 0x82, 0x69, 0x64];
    }

    {
        IonSymbolTableSequental symbolTable = void;
        symbolTable.initialize;
        symbolTable.insert(`id`);
        symbolTable.insert(`id`);
        symbolTable.insert(`id`);
        symbolTable.insert(`id`);
        symbolTable.finalize;
        symbolTable.serializer.data.should == [0xE8, 0x81, 0x83, 0xD5, 0x87, 0xB3, 0x82, 0x69, 0x64];
    }

    {
        IonSymbolTableSequental symbolTable = void;
        symbolTable.initialize;
        auto d = symbolTable.insert(`id`);
        auto D = symbolTable.insert(`qwertyuioplkjhgfdszxcvbnm`);
        assert(symbolTable.insert(`id`) == d);
        assert(symbolTable.insert(`qwertyuioplkjhgfdszxcvbnm`) == D);
        symbolTable.finalize;
        symbolTable.serializer.data.should == [0xEE, 0xA5, 0x81, 0x83, 0xDE, 0xA1, 0x87, 0xBE, 0x9E, 0x82, 0x69, 0x64, 0x8E, 0x99, 0x71, 0x77, 0x65, 0x72, 0x74, 0x79, 0x75, 0x69, 0x6F, 0x70, 0x6C, 0x6B, 0x6A, 0x68, 0x67, 0x66, 0x64, 0x73, 0x7A, 0x78, 0x63, 0x76, 0x62, 0x6E, 0x6D];
    }

    {
        IonSymbolTableSequental symbolTable = void;
        symbolTable.initialize;
        auto d = symbolTable.insert(`id`);
        assert(symbolTable.insert(`qwertyuioOlkjhgfdszxcvbnm`) == d + 1);
        assert(symbolTable.insert(`ID`) == d + 2);
        assert(symbolTable.insert(`qwertyuioplkjhgfdszxcvbnm`) == d + 3);
        symbolTable.finalize;
        symbolTable.serializer.data.should == `[id, qwertyuioOlkjhgfdszxcvbnm, ID, qwertyuioplkjhgfdszxcvbnm]`.text2ion[4 .. $ - 9];
    }
}


/++
+/
struct IonSymbolTable(bool gc)
{
    private static align(16) struct Entry
    {
        int probeCount = -1;
        uint hash;
        uint keyPosition;
        uint keyLength;
        uint value;

    @safe pure nothrow @nogc @property:

        bool empty() const
        {
            return probeCount < 0;
        }
    }

    enum double maxLoadFactor = 0.8;
    enum uint initialMaxProbe = 8;
    enum uint initialLength = 1 << initialMaxProbe;

    Entry* entries;
    uint nextKeyPosition;
    uint lengthMinusOne = initialLength - 1;
    uint maxProbe = initialMaxProbe;
    uint elementCount;
    uint startId = IonSystemSymbol.max + 1;
    ubyte[] keySpace;

    static if (!gc)
    {
        Entry[initialLength + initialMaxProbe] initialStackSpace = void;
        ubyte[8192] initialKeysSpace = void;
    }

    import mir.ion.type_code: IonTypeCode;
    import mir.ion.tape: ionPut, ionPutEnd, ionPutVarUInt, ionPutAnnotationsListEnd, ionPutStartLength, ionPutAnnotationsListStartLength;

    @disable this(this);

pure nothrow:

    static if (!gc)
    ~this() @trusted
    {
        if (entries != initialStackSpace.ptr)
            free(entries);
        if (keySpace.ptr != initialKeysSpace.ptr)
            free(keySpace.ptr);
        entries = null;
        keySpace = null;
    }

    ///
    bool initialized() @property
    {
        return keySpace.length != 0;
    }

    ///
    void initializeNull() @property
    {
        entries = null;
        nextKeyPosition = 0;
        lengthMinusOne = initialLength - 1;
        maxProbe = initialMaxProbe;
        elementCount = 0;
        startId = IonSystemSymbol.max + 1;
        keySpace = null;
    }

    ///
    void initialize()
    {
        initializeNull;
        static if (gc)
        {
            entries = new Entry[initialLength + initialMaxProbe].ptr;
            keySpace = new ubyte[1024];
        }
        else
        {
            initialStackSpace[] = Entry.init;
            entries = initialStackSpace.ptr;
            keySpace = initialKeysSpace[];
        }

        assert(nextKeyPosition == 0);
        nextKeyPosition += ionPutStartLength; // annotation object
        nextKeyPosition += ionPutVarUInt(keySpace.ptr + nextKeyPosition, ubyte(1u));
        nextKeyPosition += ionPutVarUInt(keySpace.ptr + nextKeyPosition, ubyte(IonSystemSymbol.ion_symbol_table));
        assert(nextKeyPosition == 5);
        nextKeyPosition += ionPutStartLength; // object
        nextKeyPosition += ionPutVarUInt(keySpace.ptr + nextKeyPosition, IonSystemSymbol.symbols);
        assert(nextKeyPosition == 9);
        nextKeyPosition += ionPutStartLength; // symbol array
        assert(nextKeyPosition == unfinilizedFirstKeyPosition);
    }

    package enum unfinilizedFirstKeyPosition = 12;

    const(ubyte)[] unfinilizedKeysData() scope const {
        return keySpace[unfinilizedFirstKeyPosition .. nextKeyPosition];
    }

    /++
    Prepare the table for writing.
    The table shouldn't be used after that.
    +/
    void finalize() @trusted
    {
        if (nextKeyPosition == unfinilizedFirstKeyPosition)
        {
            nextKeyPosition = 0;
            return;
        }
        {
            auto shift = 9;
            auto length = nextKeyPosition - (shift + ionPutStartLength);
            nextKeyPosition = cast(uint)(shift + ionPutEnd(keySpace.ptr + shift, IonTypeCode.list, length));
        }

        {
            auto shift = 5;
            auto length = nextKeyPosition - (shift + ionPutStartLength);
            nextKeyPosition = cast(uint)(shift + ionPutEnd(keySpace.ptr + shift, IonTypeCode.struct_, length));
        }

        {
            auto shift = 0;
            auto length = nextKeyPosition - (shift + ionPutStartLength);
            nextKeyPosition = cast(uint)(shift + ionPutEnd(keySpace.ptr + shift, IonTypeCode.annotations, length));
        }
    }

    inout(ubyte)[] data() inout @property
    {
        return keySpace[0 .. nextKeyPosition];
    }

    private inout(Entry)[] currentEntries() inout @property
    {
        return entries[0 .. lengthMinusOne + 1 + maxProbe];
    }

    private void grow()
    {
        pragma(inline, false);
        auto currentEntries = this.currentEntries[0 .. $-1];

        lengthMinusOne = lengthMinusOne * 2 + 1;
        maxProbe++;

        static if (gc)
        {
            entries = new Entry[lengthMinusOne + 1 + maxProbe].ptr;
        }
        else
        {
            entries = cast(Entry*)malloc((lengthMinusOne + 1 + maxProbe) * Entry.sizeof);
            if (entries is null)
                assert(0);
        }

        this.currentEntries[] = Entry.init;
        this.currentEntries[$ - 1].probeCount = 0;

        foreach (i, ref entry; currentEntries)
        {
            if (!entry.empty)
            {
                auto current = entries + (entry.hash & lengthMinusOne);
                int probeCount;

                while (current[probeCount].probeCount >= probeCount)
                    probeCount++;

                assert (elementCount + 1 < (lengthMinusOne + 1) * maxLoadFactor && probeCount < maxProbe);

                entry.probeCount = probeCount;
                current += entry.probeCount;
                if (current.empty)
                {
                    *current = entry;
                    continue;
                }
                if (entry.probeCount <= current.probeCount)
                {
            L:
                    do {
                        entry.probeCount++;
                        current++;
                    }
                    while (entry.probeCount <= current.probeCount);
                }

                assert (current <= entries + lengthMinusOne + maxProbe);

                swap(*current, entry);
                if (!entry.empty)
                    goto L;
            }
        }

        static if (!gc)
        {
            if (currentEntries.ptr != initialStackSpace.ptr)
                free(currentEntries.ptr);
        }
    }

    ///
    uint insert(scope const(char)[] key)
    {
        pragma(inline, true);
        uint ret = insert(key, cast(uint)dlang_hll_murmurhash(key));
        return ret;
    }

    ///
    uint insert(scope const(char)[] key, uint hash)
    {
    L0:
        pragma(inline, true);
        auto current = entries + (hash & lengthMinusOne);
        int probeCount;
        for (;;)
        {
            if (current[probeCount].probeCount < probeCount)
                break;
            probeCount++;
            if (hash != current[probeCount - 1].hash)
                continue;
            auto pos = current[probeCount - 1].keyPosition;
            auto len = current[probeCount - 1].keyLength;
            if (key == keySpace[pos .. pos + len])
                return current[probeCount - 1].value;
        }

        if (_expect(elementCount + 1 > (lengthMinusOne + 1) * maxLoadFactor || probeCount == maxProbe, false))
        {
            grow();
            goto L0;
        }

        // add key
        if (_expect(nextKeyPosition + key.length + 16 > keySpace.length, false))
        {
            auto newLength = max(nextKeyPosition + key.length + 16, keySpace.length * 2);
            static if (gc)
            {
                keySpace.length = newLength;
            }
            else
            {
                if (keySpace.ptr == initialKeysSpace.ptr)
                {
                    import core.stdc.string: memcpy;
                    keySpace = (cast(ubyte*)malloc(newLength))[0 .. newLength];
                    if (keySpace.ptr is null)
                        assert(0);
                    memcpy(keySpace.ptr, initialKeysSpace.ptr, initialKeysSpace.length);
                }
                else
                {
                    if (keySpace.length == 0)
                        assert(0);
                    keySpace = (cast(ubyte*)realloc(keySpace.ptr, newLength))[0 .. newLength];
                    if (keySpace.ptr is null)
                        assert(0);
                }
            }
        }
        nextKeyPosition += cast(uint) ionPut(keySpace.ptr + nextKeyPosition, key);

        Entry entry;
        entry.probeCount = probeCount;
        entry.hash = hash;
        entry.value = elementCount++ + startId;
        entry.keyPosition = nextKeyPosition - cast(uint)key.length;
        entry.keyLength = cast(uint)key.length;
        current += entry.probeCount;

        auto ret = entry.value;

        if (current.empty)
        {
            *current = entry;
            return ret;
        }
    L1:
        if (entry.probeCount <= current.probeCount)
        {
    L2:
            do {
                entry.probeCount++;
                current++;
            }
            while (entry.probeCount <= current.probeCount);
        }
        if (_expect(current < entries + lengthMinusOne + maxProbe, true))
        {
            swap(*current, entry);
            if (!entry.empty)
                goto L2;
            return ret;
        }
        grow();
        current = entries + (entry.hash & lengthMinusOne);
        entry.probeCount = 0;
        for (;;)
        {
            if (current.probeCount < entry.probeCount)
                break;
            current++;
            entry.probeCount++;
        }
        goto L1;
    }
}

version(mir_ion_test) unittest
{
    IonSymbolTable!true table;
    table.initialize;

    foreach (i; 0 .. 20)
    {
        auto id = table.insert("a key a bit larger then 14");
        assert(id == IonSystemSymbol.max + 1);
    }

    table.finalize;
}

package(mir) auto findKey()(const string[] symbolTable, string key)
{
    import mir.algorithm.iteration: findIndex;
    auto ret = symbolTable.findIndex!(a => a == key);
    assert(ret != size_t.max, "Missing key: " ~ key);
    return ret;
}

private:

pragma(inline, true)
uint dlang_hll_murmurhash(scope const(char)[] data)
    @trusted pure nothrow @nogc
{
    if (__ctfe)
        return cast(uint) hashOf(data);
    return murmur3_32(cast(const ubyte*)data.ptr, data.length);
}


pragma(inline, true)
    @safe pure nothrow @nogc
static uint murmur_32_scramble(uint k) {
    k *= 0xcc9e2d51;
    k = (k << 15) | (k >> 17);
    k *= 0x1b873593;
    return k;
}
pragma(inline, true)
    @trusted pure nothrow @nogc
uint murmur3_32(const(ubyte)* key, size_t len, uint seed = 0)
{
	uint h = seed;
    uint k;
    /* Read in groups of 4. */
    for (size_t i = len >> 2; i; i--) {
        import core.stdc.string;
        // Here is a source of differing results across endiannesses.
        // A swap here has no effects on hash properties though.
        k = *cast(const uint*) key;
        key += 4;
        h ^= murmur_32_scramble(k);
        h = (h << 13) | (h >> 19);
        h = h * 5 + 0xe6546b64;
    }
    /* Read the rest. */
    k = 0;
    for (size_t i = len & 3; i; i--) {
        k <<= 8;
        k |= key[i - 1];
    }
    // A swap is *not* necessary here because the preceding loop already
    // places the low bytes in the low places according to whatever endianness
    // we use. Swaps only apply when the memory is copied in a chunk.
    h ^= murmur_32_scramble(k);
    /* Finalize. */
	h ^= len;
	h ^= h >> 16;
	h *= 0x85ebca6b;
	h ^= h >> 13;
	h *= 0xc2b2ae35;
	h ^= h >> 16;
	return h;
}
