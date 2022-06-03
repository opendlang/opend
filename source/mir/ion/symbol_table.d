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

/++
+/
struct IonSymbolTable(bool gc)
{
    private static align(16) struct Entry
    {
        int probeCount = -1;
        uint hash;
        uint keyPosition;
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
    void initialize()
    {
        entries = null;
        nextKeyPosition = 0;
        lengthMinusOne = initialLength - 1;
        maxProbe = initialMaxProbe;
        elementCount = 0;
        startId = IonSystemSymbol.max + 1;
        keySpace = null;

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

    inout(ubyte)[] tapeData() inout @property
    {
        return keySpace[0 .. nextKeyPosition];
    }

    private const(char)[] getStringKey(uint keyPosition) scope const
    {
        version (LDC) pragma(inline, true);
        import mir.ion.value;
        uint length;
        uint s = keySpace[keyPosition++];
        assert(s >> 4 == 8); //string
        s &= 0xF;
        if (s < 0xE)
            return cast(const(char)[])keySpace[keyPosition .. s + keyPosition];
        auto data = keySpace[keyPosition .. $];
        parseVarUInt!false(data, length);
        return cast(const(char)[])data[0 .. length];
    }

    private inout(Entry)[] data() inout @property
    {
        return entries[0 .. lengthMinusOne + 1 + maxProbe];
    }

    private void grow()
    {
        auto currentEntries = data[0 .. $-1];

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

        data[] = Entry.init;
        data[$ - 1].probeCount = 0;

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
    uint find(scope const(char)[] key) const
    {
        return find(key, cast(uint)hashOf(key));
    }

    ///
    uint find(scope const(char)[] key, uint hash) const
    {
        auto current = entries + (hash & lengthMinusOne);
        for (size_t probeCount; ;)
        {
            if (current[probeCount].probeCount < probeCount)
            {
                return 0;
            }
            probeCount++;
            if (hash != current[probeCount - 1].hash)
                continue;
            if (key == getStringKey(current[probeCount - 1].keyPosition))
                return current[probeCount - 1].value;
        }
    }

    ///
    uint insert(scope const(char)[] key)
    {
        pragma(inline, false);
        uint ret = insert(key, cast(uint)hashOf(key));
        return ret;
    }

    ///
    uint insert(scope const(char)[] key, uint hash)
    {
    L0:
        auto current = entries + (hash & lengthMinusOne);
        int probeCount;
        for (;;)
        {
            if (current[probeCount].probeCount < probeCount)
                break;
            probeCount++;
            if (hash != current[probeCount - 1].hash)
                continue;
            if (key == getStringKey(current[probeCount - 1].keyPosition))
                return current[probeCount - 1].value;
        }

        if (_expect(elementCount + 1 > (lengthMinusOne + 1) * maxLoadFactor || probeCount == maxProbe, false))
        {
            grow();
            goto L0;
        }

        Entry entry;
        entry.probeCount = probeCount;
        entry.hash = hash;
        entry.value = elementCount++ + startId;
        entry.keyPosition = nextKeyPosition;
        current += entry.probeCount;

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

version(mir_ion_test_table) unittest
{
    IonSymbolTable!false table = void;
    table.initialize;

    import mir.format;

    foreach(i; IonSystemSymbol.max + 1 ..10_000_000)
    {
        auto key = stringBuf() << i;
        auto j = table.insert(key.data);
        assert(i == j);
        auto k = table.find(key.data);
        assert (i == k);
        if (i == 9 || i == 99 || i == 999 || i == 9_999 || i == 99_999 || i == 999_999 || i == 9_999_999)
        {
            foreach (l; IonSystemSymbol.max + 1 .. i + 1)
            {
                auto vkey = stringBuf() << l;
                assert(table.find(vkey.data));
            }
        }
    }

    table.finalize;
}


version(mir_ion_test) unittest
{
    IonSymbolTable!true table;
    table.initialize;

    import mir.format;

    foreach(i; IonSystemSymbol.max + 1 ..10_000_00)
    {
        auto key = stringBuf() << i;
        auto j = table.insert(key.data);
        assert(i == j);
        auto k = table.find(key.data);
        assert (i == k);
        if (i == 9 || i == 99 || i == 999 || i == 9_999 || i == 99_999 || i == 999_999 || i == 9_999_999)
        {
            foreach (l; IonSystemSymbol.max + 1 .. i + 1)
            {
                auto vkey = stringBuf() << l;
                assert(table.find(vkey.data));
            }
        }
    }

    table.finalize;
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
