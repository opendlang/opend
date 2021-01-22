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
struct IonSerializer(SymbolTable, TapeHolder, string[] compileTimeSymbolTable)
{
    import mir.bignum.decimal: Decimal;
    import mir.bignum.integer: BigInt;
    import std.traits: isNumeric;

    SymbolTable* runtimeTable;
    TapeHolder* tapeHolder;

    import mir.string_table: createTable;
    private alias createTableChar = createTable!char;
    private static immutable compiletimeTable = createTableChar!(compileTimeSymbolTable, false);
    static immutable U[key.length] compileTimeIndex = () {
        U[compiletimeTable.sortedKeys.length] index;
        foreach (i, key; compileTimeSymbolTable)
            index[compiletimeTable[key]] = cast(U) (i + 1);
        return index;
    } ();

@trusted:
    /// Serialization primitives
    size_t objectBegin()
    {
        auto ret = tapeHolder.currentTapePosition;
        tapeHolder.currentTapePosition += ionPutStartLength;
        return ret;
    }

    ///ditto
    void objectEnd(size_t state)
    {
        tapeHolder.currentTapePosition = state + ionPutEnd(tapeHolder.data.ptr + state, IonTypeCode.struct_, tapeHolder.currentTapePosition - (state + ionPutStartLength));
    }

    ///ditto
    size_t arrayBegin()
    {
        auto ret = tapeHolder.currentTapePosition;
        tapeHolder.currentTapePosition += ionPutStartLength;
        return ret;
    }

    ///ditto
    void arrayEnd(size_t state)
    {
        tapeHolder.currentTapePosition = state + ionPutEnd(tapeHolder.data.ptr + state, IonTypeCode.list, tapeHolder.currentTapePosition - (state + ionPutStartLength));
    }

    ///ditto
    void putCompileTimeKey(string key)()
    {
        enum id = compiletimeTable[key];
        putKeyId(compileTimeIndex[id]);
    }

    ///ditto
    void putKey()(scope const char[] key)
    {
        uint id;
        if (_expect(compiletimeTable.get(key, id), true))
        {
            id = compileTimeIndex[id];
        }
        else // use GC CTFE symbol table because likely `putKey` is used either for Associative array of for similar types.
        {
            if (_expect(runtimeTable is null, false))
                runtimeTable = new SymbolTable();
            id = runtimeTable.insert(cast(const(char)[])key);
        }
        putKeyId(compileTimeIndex[id]);
    }

    void putKeyId(uint id)
    {
        tapeHolder.reserve(5);
        tapeHolder.currentTapePosition += ionPutVarUInt(tapeHolder.data.ptr + tapeHolder.currentTapePosition, id);
    }

    ///ditto
    void putValue(Num)(const Num num)
        if (isNumeric!Num && !is(Num == enum))
    {
        tapeHolder.reserve(Num.sizeof + 2 + 1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, num);
    }

    ///ditto
    void putValue(size_t size)(auto ref const BigInt!size num)
    {
        auto view = num.view;
        auto len = view.unsigned.coefficients.length;
        tapeHolder.reserve(len * size_t.sizeof + 16);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, view);
    }

    ///ditto
    void putValue(size_t size)(auto ref const Decimal!size num)
    {
        auto view = num.view;
        auto len = view.coefficient.coefficients.length + 1; // +1 for exponent
        tapeHolder.reserve(len * size_t.sizeof + 16);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, view);
    }

    ///ditto
    void putValue(typeof(null))
    {
        tapeHolder.reserve(1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, null);
    }

    ///ditto
    void putValue(bool b)
    {
        tapeHolder.reserve(1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, b);
    }

    ///ditto
    void putEscapedValue(scope const char[] value)
    {
        putValue(value);
    }

    ///ditto
    void putValue(scope const char[] value)
    {
        tapeHolder.reserve(value.length + size_t.sizeof + 1);
        tapeHolder.currentTapePosition += ionPut(tapeHolder.data.ptr + tapeHolder.currentTapePosition, b);
    }

    ///ditto
    void elemBegin()
    {
    }
}

/++
Ion serialization function.
+/
immutable(ubyte)[] serializeIon(V)(auto ref V value)
{
    IonSymbolTable table;
    IonTapeHolder tapeHolder;
    serializeIon(()@trusted { return &table; }(), ()@trusted { return &tapeHolder; }(), value);
    return tapeHolder.tapeData.idup;
}

/++
Ion low-level serialization function.
+/
void serializeIon(SymbolTable, TapeHolder, V)(
    SymbolTable* table,
    TapeHolder* tapeHolder,
    auto ref V value)
{
    import mir.ion.ser: serializeValue;
    auto serializer = IonSerializer!(SymbolTable, TapeHolder)(table, tapeHolder);
    serializeValue(serializer, value);
}

///
unittest
{

}

// ///
// unittest
// {
//     struct S
//     {
//         string foo;
//         uint bar;
//     }

//     assert(serializeIon(S("str", 4)) == `{"foo":"str","bar":4}`);
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
    // auto state0 = ser.objectBegin;

    //     ser.putEscapedKey("null");
    //     ser.putValue(null);

    //     ser.putEscapedKey("array");
    //     auto state1 = ser.arrayBegin();
    //         ser.elemBegin; ser.putValue(null);
    //         ser.elemBegin; ser.putValue(123);
    //         ser.elemBegin; ser.putValue(12300000.123);
    //         ser.elemBegin; ser.putValue("\t");
    //         ser.elemBegin; ser.putValue("\r");
    //         ser.elemBegin; ser.putValue("\n");
    //         ser.elemBegin; ser.putValue(BigInt!2(1234567890));
    //     ser.arrayEnd(state1);

    // ser.objectEnd(state0);

    // assert(buffer.data == `{"null":null,"array":[null,123,1.2300000123e7,"\t","\r","\n",1234567890]}`);
}

///
unittest
{
//     import std.array;
//     import mir.bignum.integer;

//     auto app = appender!string;
//     auto ser = ionSerializer!"    "(&app);
//     auto state0 = ser.objectBegin;

//         ser.putEscapedKey("null");
//         ser.putValue(null);

//         ser.putEscapedKey("array");
//         auto state1 = ser.arrayBegin();
//             ser.elemBegin; ser.putValue(null);
//             ser.elemBegin; ser.putValue(123);
//             ser.elemBegin; ser.putValue(12300000.123);
//             ser.elemBegin; ser.putValue("\t");
//             ser.elemBegin; ser.putValue("\r");
//             ser.elemBegin; ser.putValue("\n");
//             ser.elemBegin; ser.putValue(BigInt!2("1234567890"));
//         ser.arrayEnd(state1);

//     ser.objectEnd(state0);

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
