/++
$(H4 High level Ion serialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ser.ion;

import mir.primitives: isOutputRange;
public import mir.serde;

import mir.ion.symbol_table: IonSymbolTable;

@trusted pure nothrow @nogc
IonSerializer!(bufferStackSize, compiletimeSymbolTable, tableGC)
    ionSerializer
    (uint bufferStackSize, string[] compiletimeSymbolTable = null, bool tableGC)
    ()
{
    import core.lifetime: move;
    typeof(return) ret = void;

    ret.buffer.allData = null;
    ret.buffer.currentTapePosition = 0;
    version(assert) ret.buffer.ctrlStack = 0;

    // ret.initialize(runtimeTable, serdeTarget);
    return ret;
}

struct IonSerializer(uint bufferStackSize, string[] compiletimeSymbolTable, bool tableGC = true)
{
    import mir.appender: ScopedBuffer;
    import mir.bignum.decimal: Decimal;
    import mir.bignum.integer: BigInt;
    import mir.bignum.low_level_view: BigIntView;
    import mir.ion.symbol_table: IonSymbolTable, IonSystemSymbolTable_v1;
    import mir.ion.tape;
    import mir.ion.type_code;
    import mir.lob;
    import mir.string_table: createTable, minimalIndexType;
    import mir.timestamp;
    import mir.utility: _expect;
    import std.traits: isNumeric;

    private alias createTableChar = createTable!char;
    private alias U = minimalIndexType!(IonSystemSymbolTable_v1.length + compiletimeSymbolTable.length);

    private static immutable compiletimeTable = createTableChar!(IonSystemSymbolTable_v1 ~ compiletimeSymbolTable, false);
    static immutable U[IonSystemSymbolTable_v1.length + compiletimeTable.sortedKeys.length] compiletimeIndex = () {
        U[IonSystemSymbolTable_v1.length + compiletimeTable.sortedKeys.length] index;
        foreach (i, key; IonSystemSymbolTable_v1 ~ compiletimeSymbolTable)
            index[compiletimeTable[key]] = cast(U) i;
        return index;
    } ();
    static immutable ubyte[] compiletimeTableTape = () {
        IonSymbolTable!true table;
        table.initialize;
        foreach (key; compiletimeSymbolTable)
            table.insert(key);
        table.finalize;
        return table.data;
    } ();

    ///
    import mir.ion.internal.data_holder;
    IonTapeHolder!(bufferStackSize) buffer = void;

    ///
    IonSymbolTable!tableGC* runtimeTable;

    /// Mutable value used to choose format specidied or user-defined serialization specializations
    int serdeTarget = SerdeTarget.ion;

nothrow pure @trusted:

    void initialize(ref IonSymbolTable!tableGC runtimeTable, int serdeTarget = SerdeTarget.ion) @trusted
    {
        buffer.initialize;
        this.runtimeTable = &runtimeTable;
        this.serdeTarget = serdeTarget;
        version (thunderbolt)
            buffer._currentLength = 15;
    }

    void initializeNoTable(int serdeTarget = SerdeTarget.ion) @trusted
    {
        pragma(inline, true);
        buffer.initialize;
        this.runtimeTable = null;
        this.serdeTarget = serdeTarget;
        version (thunderbolt)
            buffer._currentLength = 15;
    }

    void finalize() @trusted
    {
        import mir.ion.thunderbolt;

        version (thunderbolt)
        {
            auto reserve = buffer.reserve(15);
            if (__ctfe)
                reserve[] = 0;
            auto joy = buffer.data.ptr +  15;
            auto ion = joy + 15;
            auto length = buffer._currentLength - 15;
            buffer._currentLength += 15;

            debug
            {
                // d.printHexArray(joy[0 .. length]);
                // d << endl;
            }

            auto status = thunderbolt(ion, joy, length);

            debug
            {
                // d.printHexArray(ion[0 .. length]);
                // d << endl;
            }

            assert(!status);
        }
        else
        {

        }
    }

    inout(ubyte)[] data() inout scope return
    {
        version (thunderbolt)
        {
           return buffer.data[30 .. $];
        }
        else
        {
            return buffer.data;
        }
    }

scope:

    private void putEnd(size_t beginPosition, IonTypeCode typeCode)
    {
        version (thunderbolt)
        {
            buffer.reserve(11);
            auto length = buffer._currentLength - beginPosition;
            buffer._currentLength = beginPosition + joyPutEnd(buffer.data.ptr + beginPosition, typeCode, length);
        }
        else
        {
            buffer.reserve(128 + 3);
            auto length = buffer._currentLength - beginPosition - ionPutStartLength;
            buffer._currentLength = beginPosition + ionPutEnd(buffer.data.ptr + beginPosition, typeCode, length);
        }
    }

    ///
    size_t structBegin(size_t length = size_t.max)
    {
        version (thunderbolt)
        {
            return buffer._currentLength;
        }
        else
        {
            auto ret = buffer._currentLength;
            buffer.reserve(ionPutStartLength);
            buffer._currentLength += ionPutStartLength;
            return ret;
        }
    }

    ///
    void structEnd(size_t state)
    {
        putEnd(state, IonTypeCode.struct_);
    }

    ///
    alias listBegin = structBegin;

    ///
    void listEnd(size_t state)
    {
        putEnd(state, IonTypeCode.list);
    }

    ///
    alias sexpBegin = listBegin;

    ///
    void sexpEnd(size_t state)
    {
        putEnd(state, IonTypeCode.sexp);
    }

    ///
    alias stringBegin = structBegin;

    /++
    Puts string part. The implementation allows to split string unicode points.
    +/
    void putStringPart(scope const(char)[] str)
    {
        buffer.put(cast(const ubyte[]) str);
    }

    ///
    void stringEnd(size_t state)
    {
        putEnd(state, IonTypeCode.string);
    }

    ///
    auto annotationsEnd(size_t state)
    {
        version (thunderbolt)
        {
            return buffer._currentLength;
        }
        else
        {
            size_t length = buffer._currentLength - (state + ionPutStartLength + ionPutAnnotationsListStartLength);
            if (_expect(length >= 0x80, false))
                buffer.reserve(9);
            return buffer._currentLength = state + ionPutStartLength + ionPutAnnotationsListEnd(buffer.data.ptr + state + ionPutStartLength, length);
        }
    }

    ///
    version (thunderbolt)
    alias annotationWrapperBegin = structBegin;
    else
    size_t annotationWrapperBegin(size_t length = size_t.max)
    {
        auto ret = buffer._currentLength;
        buffer.reserve(ionPutStartLength + ionPutAnnotationsListStartLength);
        buffer._currentLength += ionPutStartLength + ionPutAnnotationsListStartLength;
        return ret;
    }

    ///
    void annotationWrapperEnd(size_t annotationsState, size_t state)
    {
        version (thunderbolt)
        {
            assert(state < annotationsState);
            buffer._currentLength += joyPutVarUInt(buffer.reserve(22).ptr, annotationsState - state);
            buffer._currentLength = state + joyPutEnd(buffer.data.ptr + state, IonTypeCode.annotations, buffer._currentLength - state);
        }
        else
        {
            putEnd(state, IonTypeCode.annotations);
        }
    }

    ///
    void putCompiletimeKey(string key)()
    {
        enum id = compiletimeTable[key];
        putKeyId(compiletimeIndex[id]);
    }

    ///
    alias putCompiletimeAnnotation = putCompiletimeKey;

    uint _getId(scope const char[] key)
    {
        import mir.utility: _expect;
        uint id;
        if (_expect(compiletimeTable.get(key, id), true))
        {
            return id = compiletimeIndex[id];
        }
        else // use GC CTFE symbol table because likely `putKey` is used either for Associative array of for similar types.
        {
            if (_expect(!runtimeTable.initialized, false))
            {
                runtimeTable.initialize;
                foreach (ctKey; compiletimeSymbolTable)
                {
                    runtimeTable.insert(ctKey);
                }
             }
            return runtimeTable.insert(cast(const(char)[])key);
        }
    }

    static if (tableGC)
    ///
    void putKey(scope const char[] key)
    {
        putKeyId(_getId(key));
    }
    else
    ///
    void putKey(scope const char[] key) @nogc
    {
        putKeyId(_getId(key));
    }

    static if (tableGC)
    ///
    void putAnnotation(scope const char[] key)
    {
        putAnnotationId(_getId(key));
    }
    else
    ///
    void putAnnotation(scope const char[] key) @nogc
    {
        putAnnotationId(_getId(key));
    }

    ///
    void putKeyId(T)(const T id)
        if (__traits(isUnsigned, T))
    {
        version (thunderbolt)
            buffer._currentLength += joyPutVarUInt(buffer.reserve(11).ptr, id);
        else
            buffer._currentLength += ionPutVarUInt(buffer.reserve(11).ptr, id);
    }

    ///
    ///
    void putAnnotationId(T)(const T id)
        if (__traits(isUnsigned, T))
    {
        buffer._currentLength += ionPutVarUInt(buffer.reserve(11).ptr, id);
    }

    ///
    void putSymbolId(size_t id)
    {
        version (thunderbolt)
            buffer._currentLength += joyPutSymbolId(buffer.reserve(9).ptr, id);
        else
            buffer._currentLength += ionPutSymbolId(buffer.reserve(9).ptr, id);
    }

    ///
    void putSymbol(scope const char[] key)
    {
        import mir.utility: _expect;
        putSymbolId(_getId(key));
    }

    ///
    void putValue(Num)(const Num num)
        if (isNumeric!Num && !is(Num == enum))
    {
        version (thunderbolt)
            buffer._currentLength += joyPut(buffer.reserve(Num.sizeof + 1).ptr, num);
        else
            buffer._currentLength += ionPut(buffer.reserve(Num.sizeof + 1).ptr, num);
    }

    ///
    void putValue(W)(BigIntView!W view)
    {
        version (thunderbolt)
            buffer._currentLength += joyPut(buffer.reserve(view.unsigned.coefficients.length * W.sizeof + 12).ptr, view);
        else
            buffer._currentLength += ionPut(buffer.reserve(view.unsigned.coefficients.length * W.sizeof + 12).ptr, view);
    }

    ///
    void putValue(size_t size)(auto ref const BigInt!size num)
    {
        putValue(num.view);
    }

    ///
    void putValue(size_t size)(auto ref const Decimal!size num)
    {
        version (thunderbolt)
            buffer._currentLength += joyPut(buffer.reserve(num.coefficient.coefficients.length * size_t.sizeof + 23).ptr, num.view);
        else
            buffer._currentLength += ionPut(buffer.reserve(num.coefficient.coefficients.length * size_t.sizeof + 23).ptr, num.view);
    }

    ///
    void putValue(typeof(null))
    {
        putNull(IonTypeCode.null_);
    }

    ///
    void putNull(IonTypeCode code)
    {
        buffer._currentLength += ionPut(buffer.reserve(1).ptr, null, code);
    }

    ///
    void putValue(bool b)
    {
        buffer._currentLength += ionPut(buffer.reserve(1).ptr, b);
    }

    ///
    void putValue(scope const char[] value)
    {
        version (thunderbolt)
            buffer._currentLength += joyPut(buffer.reserve(value.length + size_t.sizeof + 1).ptr, value);
        else
            buffer._currentLength += ionPut(buffer.reserve(value.length + size_t.sizeof + 1).ptr, value);
    }

    ///
    void putValue(scope Clob value)
    {
        version (thunderbolt)
            buffer._currentLength += joyPut(buffer.reserve(value.data.length + size_t.sizeof + 1).ptr, value);
        else
            buffer._currentLength += ionPut(buffer.reserve(value.data.length + size_t.sizeof + 1).ptr, value);
    }

    ///
    void putValue(scope Blob value)
    {
        version (thunderbolt)
            buffer._currentLength += joyPut(buffer.reserve(value.data.length + size_t.sizeof + 1).ptr, value);
        else
            buffer._currentLength += ionPut(buffer.reserve(value.data.length + size_t.sizeof + 1).ptr, value);
    }

    ///
    void putValue(Timestamp value)
    {
        version (thunderbolt)
            buffer._currentLength += joyPut(buffer.reserve(20).ptr, value);
        else
            buffer._currentLength += ionPut(buffer.reserve(20).ptr, value);
    }

    ///
    void elemBegin()
    {
    }

    ///
    alias sexpElemBegin = elemBegin;

    ///
    void nextTopLevelValue()
    {
    }
}

/++
Ion serialization function.
+/
immutable(ubyte)[] serializeIon(T)(auto ref T value, int serdeTarget = SerdeTarget.ion)
{
    import mir.utility: _expect;
    import mir.ion.internal.data_holder: ionPrefix;
    import mir.ser: serializeValue;
    import mir.ion.symbol_table: IonSymbolTable, removeSystemSymbols;

    enum nMax = 4096u;
    enum keys = serdeGetSerializationKeysRecurse!T.removeSystemSymbols;

    IonSymbolTable!true table;
    auto serializer = ionSerializer!(nMax * 8, keys, true);
    serializer.initialize(table, serdeTarget);

    serializeValue(serializer, value);
    serializer.finalize;

    static immutable ubyte[] compiletimePrefixAndTableTapeData = ionPrefix ~ serializer.compiletimeTableTape;

    // use runtime table
    if (_expect(table.initialized, false))
    {
        table.finalize; 
        return () @trusted { return  cast(immutable) (ionPrefix ~ table.data ~ serializer.data); } ();
    }
    // compile time table
    else
    {
        return () @trusted { return  cast(immutable) (compiletimePrefixAndTableTapeData ~ serializer.data); } ();
    }
}

///
version(mir_ion_ser_test)
unittest
{
    static struct S
    {
        string s;
        double aaaa;
        int bbbb;
    }

    enum s = S("str", 1.23, 123);

    static immutable ubyte[] data = [
        0xe0, 0x01, 0x00, 0xea, 0xee, 0x92, 0x81, 0x83,
        0xde, 0x8e, 0x87, 0xbc, 0x81, 0x73, 0x84, 0x61,
        0x61, 0x61, 0x61, 0x84, 0x62, 0x62, 0x62, 0x62,
        0xde, 0x92, 0x8a, 0x83, 0x73, 0x74, 0x72, 0x8b,
        0x48, 0x3f, 0xf3, 0xae, 0x14, 0x7a, 0xe1, 0x47,
        0xae, 0x8c, 0x21, 0x7b,
    ];

    import mir.test;
    s.serializeIon.should == data;
    enum staticData = s.serializeIon;
    static assert (staticData == data);
}

///
version(mir_ion_ser_test)
unittest
{
    import mir.serde: SerdeTarget;
    static immutable ubyte[] binaryDataAB = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    static immutable ubyte[] binaryDataBA = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x62, 0x81, 0x61, 0xd6, 0x8a, 0x21, 0x02, 0x8b, 0x21, 0x01];
    int[string] table = ["a" : 1, "b" : 2];
    auto data = table.serializeIon(SerdeTarget.ion);
    assert(data == binaryDataAB || data == binaryDataBA);
}

/++
Ion serialization for custom outputt range.
+/
void serializeIon(Appender, T)(scope ref Appender appender, auto ref T value, int serdeTarget = SerdeTarget.ion)
    if (isOutputRange!(Appender, const(ubyte)[]) && !is(T == SerdeTarget))
{
    import mir.utility: _expect;
    import mir.ion.internal.data_holder: ionPrefix;
    import mir.ser: serializeValue;
    import mir.ion.symbol_table: IonSymbolTable, removeSystemSymbols;

    enum nMax = 4096u;
    enum keys = serdeGetSerializationKeysRecurse!T.removeSystemSymbols;

    auto table = () @trusted { IonSymbolTable!false ret = void; ret.initializeNull; return ret; }();
    auto serializer = ionSerializer!(nMax * 8, keys, false);
    serializer.initialize(table, serdeTarget);

    serializeValue(serializer, value);
    serializer.finalize;

    appender.put(ionPrefix);

    // use runtime table
    if (_expect(table.initialized, false))
    {
        table.finalize; 
        appender.put(table.data);
    }
    // compile time table
    else
    {
        appender.put(serializer.compiletimeTableTape);
    }
    appender.put(serializer.data);
}

///
version(mir_ion_ser_test)
@safe pure nothrow @nogc
unittest
{
    import mir.test;
    import mir.appender: scopedBuffer;

    static struct S
    {
        string s;
        double aaaa;
        int bbbb;
    }

    auto s = S("str", 1.23, 123);

    static immutable ubyte[] data = [
        0xe0, 0x01, 0x00, 0xea, 0xee, 0x92, 0x81, 0x83,
        0xde, 0x8e, 0x87, 0xbc, 0x81, 0x73, 0x84, 0x61,
        0x61, 0x61, 0x61, 0x84, 0x62, 0x62, 0x62, 0x62,
        0xde, 0x92, 0x8a, 0x83, 0x73, 0x74, 0x72, 0x8b,
        0x48, 0x3f, 0xf3, 0xae, 0x14, 0x7a, 0xe1, 0x47,
        0xae, 0x8c, 0x21, 0x7b,
    ];

    auto buffer = scopedBuffer!ubyte;
    serializeIon(buffer, s);
    buffer.data.should == data;
}
