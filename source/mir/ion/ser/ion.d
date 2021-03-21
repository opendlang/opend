/++
$(H4 High level Ion serialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ion.ser.ion;

public import mir.serde;

/++
Ion serialization back-end
+/
struct IonSerializer(TapeHolder, string[] compiletimeSymbolTable)
{
    import mir.bignum.decimal: Decimal;
    import mir.bignum.integer: BigInt;
    import mir.ion.lob;
    import mir.ion.symbol_table: IonSymbolTable, IonSystemSymbolTable_v1;
    import mir.ion.tape;
    import mir.ion.type_code;
    import mir.string_table: createTable, minimalIndexType;
    import std.traits: isNumeric;

    private alias createTableChar = createTable!char;
    private alias U = minimalIndexType!(IonSystemSymbolTable_v1.length + compiletimeSymbolTable.length);

    private static immutable compiletimeTable = createTableChar!(IonSystemSymbolTable_v1 ~ compiletimeSymbolTable, false);
    static immutable U[IonSystemSymbolTable_v1.length + compiletimeTable.sortedKeys.length] compileTimeIndex = () {
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

    TapeHolder* tapeHolder;
    IonSymbolTable!true* runtimeTable;

@trusted:

    ///
    size_t structBegin()
    {
        auto ret = tapeHolder.currentTapePosition;
        tapeHolder.currentTapePosition += ionPutStartLength;
        return ret;
    }

    ///
    void structEnd(size_t state)
    {
        tapeHolder.currentTapePosition = state + ionPutEnd(tapeHolder.data.ptr + state, IonTypeCode.struct_, tapeHolder.currentTapePosition - (state + ionPutStartLength));
    }

    ///
    alias listBegin = structBegin;

    ///
    void listEnd(size_t state)
    {
        tapeHolder.currentTapePosition = state + ionPutEnd(tapeHolder.data.ptr + state, IonTypeCode.list, tapeHolder.currentTapePosition - (state + ionPutStartLength));
    }

    ///
    alias sexpBegin = listBegin;

    ///
    void sexpEnd(size_t state)
    {
        tapeHolder.currentTapePosition = state + ionPutEnd(tapeHolder.data.ptr + state, IonTypeCode.sexp, tapeHolder.currentTapePosition - (state + ionPutStartLength));
    }

    ///
    size_t annotationsBegin()
    {
        auto ret = tapeHolder.currentTapePosition;
        tapeHolder.currentTapePosition += ionPutAnnotationsListStartLength;
        return ret;
    }

    ///
    void annotationsEnd(size_t state)
    {
        tapeHolder.currentTapePosition = state + ionPutEnd(tapeHolder.data.ptr + state, IonTypeCode.annotations, tapeHolder.currentTapePosition - (state + ionPutAnnotationsListStartLength));
    }

    ///
    alias annotationWrapperBegin = structBegin;

    ///
    void annotationWrapperEnd(size_t state)
    {
        tapeHolder.currentTapePosition = state + ionPutEnd(tapeHolder.data.ptr + state, IonTypeCode.annotations, tapeHolder.currentTapePosition - (state + ionPutStartLength));
    }

    ///
    void putCompiletimeKey(string key)()
    {
        enum id = compiletimeTable[key];
        putKeyId(compileTimeIndex[id]);
    }

    ///
    void putKey()(scope const char[] key)
    {
        import mir.utility: _expect;
        uint id;
        if (_expect(compiletimeTable.get(key, id), true))
        {
            id = compileTimeIndex[id];
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
            id = runtimeTable.insert(cast(const(char)[])key);
        }
        putKeyId(id);
    }

    ///
    void putKeyId(T)(const T id)
        if (__traits(isUnsigned, T))
    {
        tapeHolder.reserve(10);
        tapeHolder.currentTapePosition += ionPutVarUInt(tapeHolder.data.ptr + tapeHolder.currentTapePosition, id);
    }

    ///
    alias putAnnotationId = putKeyId;

    ///
    void putValueId(uint id)
    {
        tapeHolder.reserve(5);
        tapeHolder.currentTapePosition += ionPutSymbolId(tapeHolder.data.ptr + tapeHolder.currentTapePosition, id);
    }

    ///
    void putValue(Num)(const Num num)
        if (isNumeric!Num && !is(Num == enum))
    {
        tapeHolder.reserve(Num.sizeof + 2 + 1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, num);
    }

    ///
    void putValue(size_t size)(auto ref const BigInt!size num)
    {
        auto view = num.view;
        auto len = view.unsigned.coefficients.length;
        tapeHolder.reserve(len * size_t.sizeof + 16);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, view);
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
        tapeHolder.reserve(1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, null);
    }

    ///
    void putValue(bool b)
    {
        tapeHolder.reserve(1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, b);
    }

    ///
    void putEscapedValue(scope const char[] value)
    {
        putValue(value);
    }

    ///
    void putValue(scope const char[] value)
    {
        tapeHolder.reserve(value.length + size_t.sizeof + 1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, value);
    }

    ///
    void putValue(IonClob value)
    {
        tapeHolder.reserve(value.data.length + size_t.sizeof + 1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, value);
    }

    ///
    void putValue(IonBlob value)
    {
        tapeHolder.reserve(value.data.length + size_t.sizeof + 1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, value);
    }

    ///
    void elemBegin()
    {
    }
}

/++
Ion serialization function.
+/
immutable(ubyte)[] serializeIon(T)(auto ref T value)
{
    import mir.utility: _expect;
    import mir.ion.internal.data_holder: ionPrefix, IonTapeHolder;
    import mir.ion.ser: serializeValue;
    import mir.ion.symbol_table: IonSymbolTable, removeSystemSymbols;

    enum nMax = 4096u;
    enum keys = serdeGetSerializationKeysRecurse!T.removeSystemSymbols;

    alias TapeHolder = IonTapeHolder!(nMax * 8);
    auto tapeHolder = TapeHolder(nMax * 8);
    IonSymbolTable!true table;
    auto serializer = IonSerializer!(TapeHolder, keys)(
        ()@trusted { return &tapeHolder; }(),
        ()@trusted { return &table; }()
    );
    serializeValue(serializer, value);

    static immutable ubyte[] compiletimePrefixAndTableTapeData = ionPrefix ~ serializer.compiletimeTableTape;

    // use runtime table
    if (_expect(table.initialized, false))
    {
        () @trusted { table.finalize; } ();
        return ionPrefix ~ table.tapeData ~ tapeHolder.tapeData;
    }
    // compile time table
    else
    {
        return compiletimePrefixAndTableTapeData ~ tapeHolder.tapeData;
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
    static immutable ubyte[] binaryDataAB = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    static immutable ubyte[] binaryDataBA = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x62, 0x81, 0x61, 0xd6, 0x8a, 0x21, 0x02, 0x8b, 0x21, 0x01];
    int[string] table = ["a" : 1, "b" : 2];
    auto data = table.serializeIon;
    assert(data == binaryDataAB || data == binaryDataBA);
}

/++
Ion low-level serialization function.
+/
void serializeIon(TapeHolder, T)(
    TapeHolder* tapeHolder,
    auto ref T value)
{
    import mir.ion.ser: serializeValue;
    import mir.ion.symbol_table;

    enum keys = IonSystemSymbolTable_v1 ~ serdeGetSerializationKeysRecurse!T;
    auto serializer = IonSerializer!(TapeHolder, keys)(tapeHolder);
    serializeValue(serializer, value);
}

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
//     assert(cake.serializeIon == `{"slices":8,"flavor":1.0,"dec":{"candles":0,"fluff":"inf"}}`);
//     assert(cake.dec.serializeIon == `{"candles":0,"fluff":"inf"}`);
    
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
//     import mir.ion.deser.ion;

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
//     import std.range;
//     import std.uuid;
//     import mir.serde: serdeIgnoreOut, serdeLikeList, serdeProxy;

//     static struct S
//     {
//         private int count;
//         @serdeLikeList
//         auto numbers() @property // uses `foreach`
//         {
//             return iota(count);
//         }

//         @serdeLikeList
//         @serdeProxy!string // input element type of
//         @serdeIgnoreOut
//         Appender!(string[]) strings; //`put` method is used
//     }

//     assert(S(5).serializeIon == `{"numbers":[0,1,2,3,4]}`);
//     // assert(`{"strings":["a","b"]}`.deserializeIon!S.strings.data == ["a","b"]);
// }

// ///
// unittest
// {
//     import mir.serde: serdeLikeStruct, serdeProxy;

//     static struct M
//     {
//         private int sum;

//         // opApply is used for serialization
//         int opApply(int delegate(scope const char[] key, int val) pure dg) pure
//         {
//             if(auto r = dg("a", 1)) return r;
//             if(auto r = dg("b", 2)) return r;
//             if(auto r = dg("c", 3)) return r;
//             return 0;
//         }

//         // opIndexAssign for deserialization
//         void opIndexAssign(int val, string key) pure
//         {
//             sum += val;
//         }
//     }

//     static struct S
//     {
//         @serdeLikeStruct
//         @serdeProxy!int
//         M obj;
//     }

//     assert(S.init.serializeIon == `{"obj":{"a":1,"b":2,"c":3}}`);
//     // assert(`{"obj":{"a":1,"b":2,"c":9}}`.deserializeIon!S.obj.sum == 12);
// }

// ///
// unittest
// {
//     import mir.ion.deser.ion;
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
void serializeIon(Appender, V)(ref Appender appender, auto ref V value)
{
}

///
@safe pure nothrow @nogc
unittest
{
    import mir.appender: ScopedBuffer;
    // ScopedBuffer!char buffer;
    // static struct S { int a; }
    // serializeIon(buffer, S(4));
    // assert(buffer.data == `{"a":4}`);
}

/++
Creates Ion serialization back-end.
Use `sep` equal to `"\t"` or `"    "` for pretty formatting.
+/
template ionSerializer(string sep = "")
{
    ///
    auto ionSerializer(Appender)(return Appender* appender)
    {
        return IonSerializer!(sep, Appender)(appender);
    }
}

///
@safe pure nothrow @nogc unittest
{
    // import mir.appender: ScopedBuffer;
    // import mir.bignum.integer;

    // ScopedBuffer!char buffer;
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
}

///
unittest
{
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
}
