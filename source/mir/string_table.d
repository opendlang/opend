/++
Mir String Table designed for fast deserialization routines.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
Authors: Ilya Yaroshenko 
Macros:
+/
module mir.string_table;

/++
Fast string table used to get key's id.
The keys should be first sorted by length and then lexicographically.
Params:
    U = an unsigned type that can hold an index of sorted keys. `U.max` must be less then length of the table.
    C = character type
+/
struct MirStringTable(U, C = char)
    if (__traits(isUnsigned, U) && (is(C == char) || is(C == wchar) || is(C == dchar)))
{
    /++
    Keys sorted by length and then lexicographically.
    +/
    const(immutable(C)[])[] sortedKeys;

    private U[] table;

    /++
    The keys should be first sorted by length and then lexicographically.

    The constructor uses GC.
    It can be used in `@nogc` code when if constructed in compile time.
    +/
    this()(const(immutable(C)[])[] sortedKeys)
        @trusted pure nothrow
    {
        pragma(inline, false);
        this.sortedKeys = sortedKeys;
        assert(sortedKeys.length <= U.max);
        const largest = sortedKeys.length ? sortedKeys[$ - 1].length : 0;
        table = new U[largest + 2];
        size_t ski;
        foreach (length; 0 .. largest + 1)
        {
            while(ski < sortedKeys.length && sortedKeys[ski].length == length)
                ski++;
            table[length + 1] = cast(U)ski;
        }
    }

    /++
    Params:
        key = string to find index for
        index = (ref) index to fill with key's position.
    Returns:
        true if keys index has been found
    +/
    bool get()(scope const C[] key, ref uint index)
         const @trusted pure nothrow @nogc
    {
        import mir.utility: _expect;
        if (_expect(key.length + 1 < table.length, true))
        {

            // 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16
            // 0 1 2 3 4 5 6   8 9 10    12          16

            auto low = table[key.length] + 0u;
            auto high = table[key.length + 1] + 0u;
            auto items = sortedKeys.ptr;
            if (low < high)
            {
                version (none)
                {
                    if (key.length == 0)
                    {
                        index = 0;
                        return true;
                    }
                }
                L: do {
                    auto mid = (low + high) / 2;

                    version (all)
                    {
                        import core.stdc.string: memcmp;
                        int r = void;

                        if (__ctfe)
                            r = __cmp(key, items[mid]);
                        else
                        version (BigEndian)
                            r = memcmp(key.ptr, items[mid].ptr, key.length);
                        else
                        static if (C.sizeof == 1)
                            r = memcmp(key.ptr, items[mid].ptr, key.length);
                        else
                            r = __cmp(key, items[mid]);

                        if (r == 0)
                        {
                            index = mid;
                            return true;
                        }
                        if (r > 0)
                            low = mid + 1;
                        else
                            high = mid;
                    }
                    else
                    {
                        size_t i;
                        auto value = items[mid];
                        do {
                            if (key[i] < value[i])
                            {
                                high = mid;
                                continue L;
                            }
                            else
                            if (key[i] > value[i])
                            {
                                low = mid + 1;
                                continue L;
                            }
                        } while (++i < key.length);
                        index = mid;
                        return true;
                    }
                }
                while(low < high);
            }
        }
        return false;
    }

    ///
    uint opIndex()(scope const C[] key)
         const @trusted pure nothrow @nogc
    {
        import mir.utility: _expect;
        uint ret = 0;
        if (get(key, ret)._expect(true))
            return ret;
        assert(0);
    }
}

/// ditto
struct MirStringTable(size_t length, size_t maxKeyLength, bool caseInsensetive = false, C = char)
    if (is(C == char) || is(C == wchar) || is(C == dchar))
{
    ///
    const(immutable(C)[])[length] sortedKeys;

    private alias U = minimalIndexType!length;
    private U[maxKeyLength + 2] table;

    /++
    The keys should be first sorted by length and then lexicographically.

    The constructor uses GC.
    It can be used in `@nogc` code when if constructed in compile time.
    +/
    this(immutable(C)[][length] sortedKeys)
        @trusted pure nothrow
    {
        pragma(inline, false);
        this.sortedKeys = sortedKeys;
        size_t ski;
        foreach (length; 0 .. maxKeyLength + 1)
        {
            while(ski < sortedKeys.length && sortedKeys[ski].length == length)
                ski++;
            table[length + 1] = cast(U)ski;
        }
    }

    /++
    Params:
        key = string to find index for
        index = (ref) index to fill with key's position.
    Returns:
        true if keys index has been found
    +/
    bool get()(scope const(C)[] key, ref uint index)
         const @trusted pure nothrow @nogc
    {
        import mir.utility: _expect;
        if (_expect(key.length <= maxKeyLength, true))
        {
            static if (caseInsensetive)
            {
                C[maxKeyLength] buffer = void;
                foreach(i, C c; key)
                    buffer[i] = c.fastToUpper;
                key = buffer[0 .. key.length];
            }
            auto low = table[key.length] + 0u;
            auto high = table[key.length + 1] + 0u;
            auto items = sortedKeys.ptr;
            if (low < high)
            {
                static if (!(maxKeyLength >= 16))
                {
                    if (key.length == 0)
                    {
                        index = 0;
                        return true;
                    }
                }
                L: do {
                    auto mid = (low + high) / 2;

                    static if (maxKeyLength >= 16)
                    {
                        import core.stdc.string: memcmp;
                        int r = void;

                        if (__ctfe)
                            r = __cmp(key, items[mid]);
                        else
                        version (BigEndian)
                            r = memcmp(key.ptr, items[mid].ptr, key.length);
                        else
                        static if (C.sizeof == 1)
                            r = memcmp(key.ptr, items[mid].ptr, key.length);
                        else
                            r = __cmp(key, items[mid]);

                        if (r == 0)
                        {
                            index = mid;
                            return true;
                        }
                        if (r > 0)
                            low = mid + 1;
                        else
                            high = mid;
                    }
                    else
                    {
                        size_t i;
                        auto value = items[mid];
                        do {
                            if (key[i] < value[i])
                            {
                                high = mid;
                                continue L;
                            }
                            else
                            if (key[i] > value[i])
                            {
                                low = mid + 1;
                                continue L;
                            }
                        } while (++i < key.length);
                        index = mid;
                        return true;
                    }
                }
                while(low < high);
            }
        }
        return false;
    }

    ///
    uint opIndex()(scope const C[] key)
         const @trusted pure nothrow @nogc
    {
        import mir.utility: _expect;
        uint ret = 0;
        if (get(key, ret)._expect(true))
            return ret;
        assert(0);
    }
}

///
@safe pure nothrow @nogc
version(mir_core_test) unittest
{
    static immutable sortedKeys = ["", "a", "b", "aab", "abb", "aaaaa"];
    static immutable table = MirStringTable!ubyte(sortedKeys); // CTFE
    static assert (table[""] == 0);
    static assert (table["a"] == 1);
    static assert (table["b"] == 2);
    static assert (table["abb"] == 4);
    assert (table["aaaaa"] == 5);
}


///
@safe pure nothrow
version(mir_core_test) unittest
{
    import mir.utility: simpleSort;
    auto keys = ["aaaaa", "abb", "", "b", "a", "aab"];
    // sorts keys by length and then lexicographically.
    keys.simpleSort!smallerStringFirst;
    assert(keys == ["", "a", "b", "aab", "abb", "aaaaa"]);
}

@safe pure nothrow
version(mir_core_test) unittest
{
    import mir.utility: simpleSort;
    auto keys = ["aaaaa"w, "abb"w, ""w, "b"w, "a"w, "aab"w];
    // sorts keys by length and then lexicographically.
    keys.simpleSort!smallerStringFirst;
    assert(keys == [""w, "a"w, "b"w, "aab"w, "abb"w, "aaaaa"w]);
}

package template minimalIndexType(size_t length)
{
    static if (length <= ubyte.max)
        alias minimalIndexType = ubyte;
    else
    static if (length <= ushort.max)
        alias minimalIndexType = ushort;
    else
    static if (length <= uint.max)
        alias minimalIndexType = uint;
    else
        alias minimalIndexType = ulong;
}

package template minimalSignedIndexType(size_t length)
{
    static if (length <= byte.max)
        alias minimalSignedIndexType = byte;
    else
    static if (length <= short.max)
        alias minimalSignedIndexType = short;
    else
    static if (length <= int.max)
        alias minimalSignedIndexType = int;
    else
        alias minimalSignedIndexType = long;
}

/++
Compares strings by length and then lexicographically.
+/
sizediff_t smallerStringFirstCmp(T)(T[] a, T[] b)
{
    if (sizediff_t d = a.length - b.length)
    {
        return d;
    }

    import std.traits: Unqual;
    static if (is(Unqual!T == ubyte) || is(Unqual!T == char))
    {
        import core.stdc.string: memcmp;
        if (__ctfe)
            return __cmp(a, b);
        else
            return (() @trusted => memcmp(a.ptr, b.ptr, a.length))();
    }
    else
    {
        return __cmp(a, b);
    }
}

///
@safe pure nothrow @nogc
version(mir_core_test) unittest
{
    assert(smallerStringFirstCmp("aa", "bb") < 0);
    assert(smallerStringFirstCmp("aa", "aa") == 0);
    assert(smallerStringFirstCmp("aaa", "aa") > 0);

    static assert(smallerStringFirstCmp("aa", "bb") < 0);
    static assert(smallerStringFirstCmp("aa", "aa") == 0);
    static assert(smallerStringFirstCmp("aaa", "aa") > 0);
}

/++
Compares strings by length and then lexicographically.
+/
template smallerStringFirst(alias direction = "<")
    if (direction == "<" || direction == ">")
{
    ///
    bool smallerStringFirst(T)(T[] a, T[] b)
    {
        auto r = smallerStringFirstCmp(a, b);
        static if (direction == "<")
            return r < 0;
        else
            return r > 0;
    }
}

///
@safe pure nothrow @nogc
version(mir_core_test) unittest
{
    assert(smallerStringFirst("aa", "bb") == true);
    assert(smallerStringFirst("aa", "aa") == false);
    assert(smallerStringFirst("aaa", "aa") == false);
}

package auto fastToUpper(C)(const C a)
{   // std.ascii may not be inlined
    return 'a' <= a && a <= 'z' ? cast(C)(a ^ 0x20) : a;
}

package @safe pure nothrow @nogc
C[] fastToUpperInPlace(C)(scope return C[] a)
{
    foreach(ref C e; a)
        e = e.fastToUpper;
    return a;
}

package immutable(C)[][] prepareStringTableKeys(bool caseInsensetive = false, C)(immutable(C)[][] keys)
{
    static if (caseInsensetive)
    {
        foreach (ref key; keys)
        {
            auto upper = cast(immutable) key.dup.fastToUpperInPlace;
            if (upper != key)
                key = upper;
        }
    }
    import mir.utility: simpleSort;
    return keys.simpleSort!smallerStringFirst;
}

package template createTable(C)
    if (is(C == char) || is(C == wchar) || is(C == dchar))
{
    auto createTable(immutable(C)[][] keys, bool caseInsensetive = false)()
    {
        static immutable C[][] sortedKeys = prepareStringTableKeys!caseInsensetive(keys);
        alias Table = MirStringTable!(sortedKeys.length, sortedKeys.length ? sortedKeys[$ - 1].length : 0, caseInsensetive, C);
        static if (sortedKeys.length)
            return Table(sortedKeys[0 .. sortedKeys.length]);
        else
            return Table.init;
    }
}
