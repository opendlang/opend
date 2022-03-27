/++
$(H4 High level Ion serialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ser.ion;

import mir.primitives: isOutputRange;
public import mir.serde;

/++
Ion serialization back-end
+/
struct IonSerializer(TapeHolder, string[] compiletimeSymbolTable, bool tableGC = true)
{
    import mir.bignum.decimal: Decimal;
    import mir.bignum.integer: BigInt;
    import mir.bignum.low_level_view: BigIntView, WordEndian;
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
        return table.tapeData;
    } ();

    ///
    TapeHolder* tapeHolder;

    ///
    IonSymbolTable!tableGC* runtimeTable;

    /// Mutable value used to choose format specidied or user-defined serialization specializations
    int serdeTarget = SerdeTarget.ion;

@trusted:

    private void putEnd(size_t state, IonTypeCode typeCode)
    {
        size_t totalElementLength = tapeHolder.currentTapePosition - (state + ionPutStartLength);
        tapeHolder.reserve(128 + 3);
        tapeHolder.currentTapePosition = state + ionPutEnd(tapeHolder.data.ptr + state, typeCode, totalElementLength);
    }

    ///
    size_t structBegin(size_t length = size_t.max)
    {
        auto ret = tapeHolder.currentTapePosition;
        tapeHolder.adjustPosition(ionPutStartLength);
        return ret;
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
        tapeHolder.reserve(str.length);
        (tapeHolder.data.ptr + tapeHolder.currentTapePosition)[0 .. str.length] = cast(const(ubyte)[])str;
        tapeHolder.currentTapePosition += str.length;
    }

    ///
    void stringEnd(size_t state)
    {
        putEnd(state, IonTypeCode.string);
    }

    ///
    size_t annotationsBegin()
    {
        auto ret = tapeHolder.currentTapePosition;
        tapeHolder.adjustPosition(ionPutAnnotationsListStartLength);
        return ret;
    }

    ///
    void annotationsEnd(size_t state)
    {
        size_t totalElementLength = tapeHolder.currentTapePosition - (state + ionPutAnnotationsListStartLength);
        if (_expect(totalElementLength >= 0x80, false))
            tapeHolder.reserve(9);
        tapeHolder.currentTapePosition = state + ionPutAnnotationsListEnd(tapeHolder.data.ptr + state, totalElementLength);
    }

    ///
    alias annotationWrapperBegin = structBegin;

    ///
    void annotationWrapperEnd(size_t state)
    {
        putEnd(state, IonTypeCode.annotations);
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

    ///
    void putKey()(scope const char[] key)
    {
        putKeyId(_getId(key));
    }

    ///
    alias putAnnotation = putKey;

    ///
    void putKeyId(T)(const T id)
        if (__traits(isUnsigned, T))
    {
        tapeHolder.reserve(19);
        tapeHolder.currentTapePosition += ionPutVarUInt(tapeHolder.data.ptr + tapeHolder.currentTapePosition, id);
    }

    ///
    alias putAnnotationId = putKeyId;

    ///
    void putSymbolId(size_t id)
    {
        tapeHolder.reserve(19);
        tapeHolder.currentTapePosition += ionPutSymbolId(tapeHolder.data.ptr + tapeHolder.currentTapePosition, id);
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
        tapeHolder.reserve(Num.sizeof + 2 + 1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, num);
    }

    ///
    void putValue(W, WordEndian endian)(BigIntView!(W, endian) view)
    {
        auto len = view.unsigned.coefficients.length;
        tapeHolder.reserve(len * size_t.sizeof + 16);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, view);
    }

    ///
    void putValue(size_t size)(auto ref const BigInt!size num)
    {
        putValue(num.view);
    }

    ///
    void putValue(size_t size)(auto ref const Decimal!size num)
    {
        auto view = num.view;
        auto len = view.coefficient.coefficients.length + 1; // +1 for exponent
        tapeHolder.reserve(len * size_t.sizeof + 16);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, view);
    }

    ///
    void putValue(typeof(null))
    {
        putNull(IonTypeCode.null_);
    }

    ///
    void putNull(IonTypeCode code)
    {
        tapeHolder.reserve(1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, null, code);
    }

    ///
    void putValue(bool b)
    {
        tapeHolder.reserve(1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, b);
    }

    ///
    void putValue(scope const char[] value)
    {
        tapeHolder.reserve(value.length + size_t.sizeof + 1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, value);
    }

    ///
    void putValue(Clob value)
    {
        tapeHolder.reserve(value.data.length + size_t.sizeof + 1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, value);
    }

    ///
    void putValue(Blob value)
    {
        tapeHolder.reserve(value.data.length + size_t.sizeof + 1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, value);
    }

    ///
    void putValue(Timestamp value)
    {
        tapeHolder.reserve(20);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, value);
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
    import mir.ion.internal.data_holder: ionPrefix, IonTapeHolder, ionTapeHolder;
    import mir.ser: serializeValue;
    import mir.ion.symbol_table: IonSymbolTable, removeSystemSymbols;

    enum nMax = 4096u;
    enum keys = serdeGetSerializationKeysRecurse!T.removeSystemSymbols;

    auto tapeHolder = ionTapeHolder!(nMax * 8);
    tapeHolder.initialize;
    IonSymbolTable!true table;
    auto serializer = IonSerializer!(IonTapeHolder!(nMax * 8), keys, true)(()@trusted { return &tapeHolder; }(), ()@trusted { return &table; }(), serdeTarget);
    serializeValue(serializer, value);

    static immutable ubyte[] compiletimePrefixAndTableTapeData = ionPrefix ~ serializer.compiletimeTableTape;

    // use runtime table
    if (_expect(table.initialized, false))
    {
        table.finalize; 
        return () @trusted { return  cast(immutable) (ionPrefix ~ table.tapeData ~ tapeHolder.tapeData); } ();
    }
    // compile time table
    else
    {
        return () @trusted { return  cast(immutable) (compiletimePrefixAndTableTapeData ~ tapeHolder.tapeData); } ();
    }
}

///
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

    assert (s.serializeIon == data);
    enum staticData = s.serializeIon;
    static assert (staticData == data);
}

///
unittest
{
    import mir.serde: SerdeTarget;
    static immutable ubyte[] binaryDataAB = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    static immutable ubyte[] binaryDataBA = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x62, 0x81, 0x61, 0xd6, 0x8a, 0x21, 0x02, 0x8b, 0x21, 0x01];
    int[string] table = ["a" : 1, "b" : 2];
    auto data = table.serializeIon(SerdeTarget.ion);
    assert(data == binaryDataAB || data == binaryDataBA);
}

// /++
// Ion low-level serialization function.
// +/
// void serializeIon(TapeHolder, T)(
//     TapeHolder* tapeHolder,
//     auto ref T value,
//     int serdeTarget = SerdeTarget.ion)
// {
//     import mir.ser: serializeValue;
//     import mir.ion.symbol_table;

//     enum keys = IonSystemSymbolTable_v1 ~ serdeGetSerializationKeysRecurse!T;
//     auto serializer = IonSerializer!(TapeHolder, keys)(tapeHolder, null, serdeTarget);
//     serializeValue(serializer, value);
// }

// ///
// unittest
// {
//     import mir.serde: serdeIgnoreDefault;

//     static struct Decor
//     {
//         int candles; // 0
//         float fluff = float.infinity; // inf 
//     }
    
//     static struct Cake
//     {
//         @serdeIgnoreDefault
//         string name = "Chocolate Cake";
//         int slices = 8;
//         float flavor = 1;
//         @serdeIgnoreDefault
//         Decor dec = Decor(20); // { 20, inf }
//     }
    
//     assert(Cake("Normal Cake").serializeIon == `{"name":"Normal Cake","slices":8,"flavor":1.0}`);
//     auto cake = Cake.init;
//     cake.dec = Decor.init;
//     assert(cake.serializeIon == `{"slices":8,"flavor":1.0,"dec":{"candles":0,"fluff":"+inf"}}`);
//     assert(cake.dec.serializeIon == `{"candles":0,"fluff":"+inf"}`);
    
//     static struct A
//     {
//         @serdeIgnoreDefault
//         string str = "Banana";
//         int i = 1;
//     }
//     assert(A.init.serializeIon == `{"i":1}`);
    
//     static struct S
//     {
//         @serdeIgnoreDefault
//         A a;
//     }
//     assert(S.init.serializeIon == `{}`);
//     assert(S(A("Berry")).serializeIon == `{"a":{"str":"Berry","i":1}}`);
    
//     static struct D
//     {
//         S s;
//     }
//     assert(D.init.serializeIon == `{"s":{}}`);
//     assert(D(S(A("Berry"))).serializeIon == `{"s":{"a":{"str":"Berry","i":1}}}`);
//     assert(D(S(A(null, 0))).serializeIon == `{"s":{"a":{"str":null,"i":0}}}`);
    
//     static struct F
//     {
//         D d;
//     }
//     assert(F.init.serializeIon == `{"d":{"s":{}}}`);
// }

// ///
// unittest
// {
//     import mir.serde: serdeIgnoreIn;

//     static struct S
//     {
//         @serdeIgnoreIn
//         string s;
//     }
//     // assert(`{"s":"d"}`.deserializeIon!S.s == null, `{"s":"d"}`.deserializeIon!S.s);
//     assert(S("d").serializeIon == `{"s":"d"}`);
// }

// ///
// unittest
// {
//     import mir.deser.ion;

//     static struct S
//     {
//         @serdeIgnoreOut
//         string s;
//     }
//     assert(`{"s":"d"}`.deserializeIon!S.s == "d");
//     assert(S("d").serializeIon == `{}`);
// }

// ///
// unittest
// {
//     import mir.serde: serdeIgnoreOutIf;

//     static struct S
//     {
//         @serdeIgnoreOutIf!`a < 0`
//         int a;
//     }

//     assert(serializeIon(S(3)) == `{"a":3}`, serializeIon(S(3)));
//     assert(serializeIon(S(-3)) == `{}`);
// }

// ///
// unittest
// {
//     import mir.deser.ion;
//     import std.range;
//     import std.algorithm;
//     import std.conv;

//     static struct S
//     {
//         @serdeTransformIn!"a += 2"
//         @serdeTransformOut!(a =>"str".repeat.take(a).joiner("_").to!string)
//         int a;
//     }

//     auto s = deserializeIon!S(`{"a":3}`);
//     assert(s.a == 5);
//     assert(serializeIon(s) == `{"a":"str_str_str_str_str"}`);
// }

/++
Ion serialization for custom outputt range.
+/
void serializeIon(Appender, T)(ref Appender appender, auto ref T value, int serdeTarget = SerdeTarget.ion)
    if (isOutputRange!(Appender, const(ubyte)[]) && !is(T == SerdeTarget))
{
    import mir.utility: _expect;
    import mir.ion.internal.data_holder: ionPrefix, IonTapeHolder, ionTapeHolder;
    import mir.ser: serializeValue;
    import mir.ion.symbol_table: IonSymbolTable, removeSystemSymbols;

    enum nMax = 4096u;
    enum keys = serdeGetSerializationKeysRecurse!T.removeSystemSymbols;

    auto tapeHolder = ionTapeHolder!(nMax * 8);
    tapeHolder.initialize;
    IonSymbolTable!false table;
    auto serializer = IonSerializer!(IonTapeHolder!(nMax * 8), keys, false)(()@trusted { return &tapeHolder; }(), ()@trusted { return &table; }(), serdeTarget);
    serializeValue(serializer, value);

    appender.put(ionPrefix);

    // use runtime table
    if (_expect(table.initialized, false))
    {
        table.finalize; 
        appender.put(table.tapeData);
    }
    // compile time table
    else
    {
        appender.put(serializer.compiletimeTableTape);
    }
    appender.put(tapeHolder.tapeData);
}

///
@safe pure nothrow @nogc
unittest
{
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
    assert (data == buffer.data);
}

/++
Creates Ion serialization back-end.
Use `sep` equal to `"\t"` or `"    "` for pretty formatting.
+/
template ionSerializer(string sep = "")
{
    ///
    auto ionSerializer(Appender)(return Appender* appender, int serdeTarget = SerdeTarget.ion)
    {
        return IonSerializer!(sep, Appender)(appender, serdeTarget);
    }
}

///
// @safe pure nothrow @nogc unittest
// {
    // import mir.format: stringBuf;
    // import mir.bignum.integer;

    // stringBuf buffer;
    // auto ser = ionSerializer((()@trusted=>&buffer)());
    // auto state0 = ser.structBegin;

    //     ser.putEscapedKey("null");
    //     ser.putValue(null);

    //     ser.putEscapedKey("array");
    //     auto state1 = ser.listBegin();
    //         ser.elemBegin; ser.putValue(null);
    //         ser.elemBegin; ser.putValue(123);
    //         ser.elemBegin; ser.putValue(12300000.123);
    //         ser.elemBegin; ser.putValue("\t");
    //         ser.elemBegin; ser.putValue("\r");
    //         ser.elemBegin; ser.putValue("\n");
    //         ser.elemBegin; ser.putValue(BigInt!2(1234567890));
    //     ser.listEnd(state1);

    // ser.structEnd(state0);

    // assert(buffer.data == `{"null":null,"array":[null,123,1.2300000123e7,"\t","\r","\n",1234567890]}`);
// }

///
// unittest
// {
//     import std.array;
//     import mir.bignum.integer;

//     auto app = appender!string;
//     auto ser = ionSerializer!"    "(&app);
//     auto state0 = ser.structBegin;

//         ser.putEscapedKey("null");
//         ser.putValue(null);

//         ser.putEscapedKey("array");
//         auto state1 = ser.listBegin();
//             ser.elemBegin; ser.putValue(null);
//             ser.elemBegin; ser.putValue(123);
//             ser.elemBegin; ser.putValue(12300000.123);
//             ser.elemBegin; ser.putValue("\t");
//             ser.elemBegin; ser.putValue("\r");
//             ser.elemBegin; ser.putValue("\n");
//             ser.elemBegin; ser.putValue(BigInt!2("1234567890"));
//         ser.listEnd(state1);

//     ser.structEnd(state0);

//     assert(app.data ==
// `{
//     "null": null,
//     "array": [
//         null,
//         123,
//         1.2300000123e7,
//         "\t",
//         "\r",
//         "\n",
//         1234567890
//     ]
// }`);
// }
