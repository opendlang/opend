/++
Enum utilities.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
Authors: Ilya Yaroshenko 
Macros:
+/
module mir.enums;

private bool hasSeqGrow(T)(T[] elems)
    if (__traits(isIntegral, T))
{
    assert(elems.length);
    auto min = elems[0];
    foreach (i, e; elems)
        if (i != e - min)
            return false;
    return true;
}

/++
Enum index that corresponds of the list returned by `std.traits.EnumMembers`.
Returns:
    enum member position index in the enum definition that corresponds the `value`.
+/
bool getEnumIndex(T)(const T value, ref uint index)
    @safe pure nothrow @nogc
    if (is(T == enum))
{
    import std.traits: EnumMembers, isSomeString;
        import mir.utility: _expect;

    static if (__traits(isFloating, T))
    {
        // TODO: index based binary searach
        foreach (i, member; enumMembers!T)
        {
            if (value == member)
            {
                index = cast(uint) i;
                return true;
            }
        }
        return false;
    }
    else
    static if (!__traits(isIntegral, T)) //strings
    {
        enum string[1] stringEnumValue(alias symbol) = [symbol];
        return getEnumIndexFromKey!(T, false, stringEnumValue)(value, index);
    }
    else
    static if (hasSeqGrow(enumMembers!T))
    {
        import std.traits: Unsigned;
        const shifted = cast(Unsigned!(typeof(value - T.min)))(value - T.min);
        if (_expect(shifted < enumMembers!T.length, true))
        {
            index = cast(uint) shifted;
            return true;
        }
        return false;
    }
    else
    static if (is(T : bool))
    {
        index = !value;
        return true;
    }
    else
    {
        import std.traits: Unsigned;
        alias U = Unsigned!(typeof(T.max - T.min + 1));

        enum length = cast(size_t)cast(U)(T.max - T.min + 1);

        const shifted = cast(size_t)cast(U)(value - T.min);

        static if (length <= 255)
        {
            static immutable ubyte[length] table = (){
                ubyte[length] ret;
                foreach (i, member; enumMembers!T)
                {
                    ret[member - T.min] = cast(ubyte)(i + 1);
                }
                return ret;
            }();

            if (_expect(shifted < length, true))
            {
                int id = table[shifted] - 1;
                if (_expect(id >= 0, true))
                {
                    index = id;
                    return true;
                }
            }
            return false;
        }
        else
        {
            switch (value)
            {
                foreach (i, member; EnumMembers!T)
                {
                case member:
                    index = i;
                    return true;
                }
                default: return false;
            }
        }
    }
}

///
@safe pure nothrow @nogc
version(mir_core_test) unittest
{
    import std.meta: AliasSeq;

    enum Common { a, b, c }
    enum Reversed { a = 1, b = 0, c = -1 }
    enum Shifted { a = -4, b, c }
    enum Small { a = -4, b, c = 10 }
    enum Big { a = -4, b, c = 1000 }
    enum InverseBool { True = true, False = false }
    enum FP : float { a = -4, b, c }
    enum S : string { a = "а", b = "б", c = "ц" }

    uint index = -1;
    foreach (E; AliasSeq!(Common, Reversed, Shifted, Small, Big, FP, S))
    {
        assert(getEnumIndex(E.a, index) && index == 0);
        assert(getEnumIndex(E.b, index) && index == 1);
        assert(getEnumIndex(E.c, index) && index == 2);
    }

    assert(getEnumIndex(InverseBool.True, index) && index == 0);
    assert(getEnumIndex(InverseBool.False, index) && index == 1);
}

/++
Static immutable instance of `[std.traits.EnumMembers!T]`.
+/
template enumMembers(T)
    if (is(T == enum))
{
    import std.traits: EnumMembers;
    ///
    static immutable T[EnumMembers!T.length] enumMembers = [EnumMembers!T];
}

///
version(mir_core_test) unittest
{
    enum E {a = 1, b = -1, c}
    static assert(enumMembers!E == [E.a, E.b, E.c]);
}

/++
Static immutable instance of Enum Identifiers.
+/
template enumIdentifiers(T)
    if (is(T == enum))
{
    import std.traits: EnumMembers;
    static immutable string[EnumMembers!T.length] enumIdentifiers = () {
        string[EnumMembers!T.length] identifiers;
        static foreach(i, member; EnumMembers!T)
            identifiers[i] = __traits(identifier, EnumMembers!T[i]);
        return identifiers;
    } ();
}

///
version(mir_core_test) unittest
{
    enum E {z = 1, b = -1, c}
    static assert(enumIdentifiers!E == ["z", "b", "c"]);
}

/++
Aliases itself to $(LREF enumMembers) for string enums and
$(LREF enumIdentifiers) for integral and floating point enums.
+/
template enumStrings(T)
    if (is(T == enum))
{
    static if (is(T : C[], C))
        alias enumStrings = enumMembers!T;
    else
        alias enumStrings = enumIdentifiers!T;
}

///
version(mir_core_test) unittest
{
    enum E {z = 1, b = -1, c}
    static assert(enumStrings!E == ["z", "b", "c"]);

    enum S {a = "A", b = "B", c = ""}
    static assert(enumStrings!S == [S.a, S.b, S.c]);
}

/++
Params:
    index  = enum index `std.traits.EnumMembers!T`
Returns:
    A enum value that corresponds to the index.
Note:
    The function doesn't check that index is less then `EnumMembers!T.length`.
+/
T unsafeEnumFromIndex(T)(size_t index)
    @trusted pure nothrow @nogc
    if (is(T == enum))
{
    static if (__traits(isIntegral, T))
        enum bool fastConv = hasSeqGrow(enumMembers!T);
    else
        enum bool fastConv = false;
    
    assert(index < enumMembers!T.length);
    
    static if (fastConv)
    {
        return cast(T) index;
    }
    else
    {
        return enumMembers!T[index];
    }
}

/++
Params:
    T = enum type to introspect
    key = some string that corresponds to some key name of the given enum
    index = resulting enum index if this method returns true.
Returns:
    boolean whether the key was found in the enum keys and if so, index is set.
+/
template getEnumIndexFromKey(T, bool caseInsensitive = true, getKeysTemplate...)
    if (is(T == enum) && getKeysTemplate.length <= 1)
{
    ///
    bool getEnumIndexFromKey(C)(scope const(C)[] key, ref uint index)
        @safe pure nothrow @nogc
        if (is(C == char) || is(C == wchar) || is(C == dchar))
    {
        import mir.string_table;
        import mir.utility: simpleSort, _expect;
        import std.traits: EnumMembers;
        import std.meta: staticIndexOf;

        alias String = immutable(C)[];

        static if (getKeysTemplate.length)
        {
            alias keysOfImpl = getKeysTemplate[0];
            enum String[] keysOf(alias symbol) = keysOfImpl!symbol;
        }
        else
        static if (is(T : W[], W))
            enum String[1] keysOf(alias symbol) = [cast(String)symbol];
        else
            enum String[1] keysOf(alias symbol) = [__traits(identifier, symbol)];

        enum keys = () {
            String[] keys;
            foreach(i, member; EnumMembers!T)
                keys ~= keysOf!(EnumMembers!T[i]);
            return keys;
        } ();

        static if (keys.length == 0)
        {
            return false;
        }
        else
        {
            enum indexLength = keys.length + 1;
            alias ct = createTable!C;
            static immutable table = ct!(keys, caseInsensitive);
            static immutable indices = ()
            {
                minimalSignedIndexType!indexLength[indexLength] indices;

                foreach (i, member; EnumMembers!T)
                foreach (key; keysOf!(EnumMembers!T[i]))
                {
                    static if (caseInsensitive)
                    {
                        key = key.dup.fastToUpperInPlace;
                    }
                    indices[table[key]] = i;
                }

                return indices;
            } ();

            uint stringId = void;
            if (_expect(table.get(key, stringId), true))
            {
                index = indices[stringId];
                return true;
            }
            return false;
        }
    }
}

///
unittest
{
    enum Short
    {
        hello,
        world
    }

    enum Long
    {
        This,
        Is,
        An,
        Enum,
        With,
        Lots,
        Of,
        Very,
        Long,
        EntriesThatArePartiallyAlsoVeryLongInStringLengthAsWeNeedToTestALotOfDifferentCasesThatCouldHappenInRealWorldCode_tm
    }

    uint i;
    assert(getEnumIndexFromKey!Short("hello", i));
    assert(i == 0);
    assert(getEnumIndexFromKey!Short("world", i));
    assert(i == 1);
    assert(!getEnumIndexFromKey!Short("foo", i));

    assert(getEnumIndexFromKey!Short("HeLlO", i));
    assert(i == 0);
    assert(getEnumIndexFromKey!Short("WoRLd", i));
    assert(i == 1);

    assert(!getEnumIndexFromKey!(Short, false)("HeLlO", i));
    assert(!getEnumIndexFromKey!(Short, false)("WoRLd", i));

    assert(getEnumIndexFromKey!Long("Is", i));
    assert(i == 1);
    assert(getEnumIndexFromKey!Long("Long", i));
    assert(i == 8);
    assert(getEnumIndexFromKey!Long("EntriesThatArePartiallyAlsoVeryLongInStringLengthAsWeNeedToTestALotOfDifferentCasesThatCouldHappenInRealWorldCode_tm", i));
    assert(i == 9);
    assert(!getEnumIndexFromKey!Long("EntriesThatArePartiallyAlsoVeryLongInStringLengthAsWeNeedToTestALotOfDifferentCasesThatCouldHappenInRealWorldCodeatm", i));

    assert(!getEnumIndexFromKey!(Long, false)("EntriesThatArePartiallyAlsoVeryLongInStringLengthAsWeNeedToTestALotOfDifferentCasesThatCouldHappenInRealWorldCode_tM", i));
    assert(!getEnumIndexFromKey!(Long, false)("entriesThatArePartiallyAlsoVeryLongInStringLengthAsWeNeedToTestALotOfDifferentCasesThatCouldHappenInRealWorldCode_tm", i));
}
