/++
Conversion utilities.
+/
module mir.ion.conv;

/++
Serialize value to binary ion data and deserialize it back to requested type.
Uses GC allocated string tables.
+/
template serde(T)
{
    import mir.serde: SerdeTarget;
    ///
    T serde(V)(auto ref const V value, SerdeTarget serdeTarget = SerdeTarget.ion)
    {
        import mir.ion.exception;
        import mir.appender: ScopedBuffer;
        import mir.ion.deser.ion: deserializeIon;
        import mir.ion.internal.data_holder: ionPrefix, IonTapeHolder;
        import mir.ion.ser: serializeValue;
        import mir.ion.ser.ion: IonSerializer;
        import mir.ion.symbol_table: IonSymbolTable, removeSystemSymbols, IonSystemSymbolTable_v1;
        import mir.ion.value: IonValue, IonDescribedValue, IonList;
        import mir.serde: serdeGetSerializationKeysRecurse;
        import mir.utility: _expect;

        enum nMax = 4096u;
        enum keys = serdeGetSerializationKeysRecurse!V.removeSystemSymbols;

        immutable(string)[] symbolTable;

        if (false)
        {
            IonTapeHolder!(nMax * 8) tapeHolder;
            tapeHolder.initialize;
            IonSymbolTable!true table;
            auto serializer = IonSerializer!(IonTapeHolder!(nMax * 8), keys, true)(
                ()@trusted { return &tapeHolder; }(),
                ()@trusted { return &table; }(),
                serdeTarget,
            );
            serializeValue(serializer, value);
            return deserializeIon!T(symbolTable, IonDescribedValue.init);
        }

        auto ret () @trusted {
            ScopedBuffer!(immutable string) symbolTableBuffer = void;
            IonTapeHolder!(nMax * 8) tapeHolder = void;
            symbolTableBuffer.initialize;
            tapeHolder.initialize;
            IonSymbolTable!true table;
            auto serializer = IonSerializer!(IonTapeHolder!(nMax * 8), keys, true)(&tapeHolder, &table, serdeTarget);
            serializeValue(serializer, value);

            // use runtime table
            if (table.initialized)
            {
                symbolTableBuffer.put(IonSystemSymbolTable_v1);
                foreach (IonErrorCode error, IonDescribedValue symbolValue; IonList(table.unfinilizedKeysData))
                {
                    assert(!error);
                    symbolTableBuffer.put(cast(string)symbolValue.trustedGet!(const(char)[]));
                }
                symbolTable = symbolTableBuffer.data;
            }
            else
            {
                static immutable compileTimeTable = IonSystemSymbolTable_v1 ~ keys;
                symbolTable = compileTimeTable;
            }
            IonDescribedValue ionValue;
            auto error = tapeHolder.data.IonValue.describe(ionValue);
            return deserializeIon!T(symbolTable, ionValue);
        }
        return ret();
    }
}

///
version(mir_ion_test)
unittest {
    import mir.algebraic_alias.json: JsonAlgebraic;
    static struct S
    {
        double a;
        string s;
    }
    auto s = S(12.34, "str");
    assert(s.serde!JsonAlgebraic.serde!S == s);
}

/++
Converts JSON Value Stream to binary Ion data.
+/
immutable(ubyte)[] json2ion(scope const(char)[] text)
    @trusted pure
{
    pragma(inline, false);
    import mir.exception: MirException;
    import mir.ion.exception: ionErrorMsg;
    import mir.ion.internal.data_holder: ionPrefix, IonTapeHolder;
    import mir.ion.internal.stage4_s;
    import mir.ion.symbol_table: IonSymbolTable;
    import mir.utility: _expect;

    enum nMax = 4096u;

    alias TapeHolder = IonTapeHolder!(nMax * 8);
    TapeHolder tapeHolder = void;
    tapeHolder.initialize;

    IonSymbolTable!false table = void;
    table.initialize;
    auto error = singleThreadJsonText!nMax(table, tapeHolder, text);
    if (error.code)
        throw new MirException(error.code.ionErrorMsg, ". location = ", error.location, ", last input key = ", error.key);

    return ()@trusted {
        table.finalize;
        return cast(immutable(ubyte)[])(ionPrefix ~ table.tapeData ~ tapeHolder.tapeData);
    }();
}

///
@safe pure
unittest
{
    const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    assert(`{"a":1,"b":2}`.json2ion == data);
}


/++
Converts Ion Value Stream data to JSON text.

The function performs `data.IonValueStream.serializeJson`.
+/
string ion2json(scope const(ubyte)[] data)
    @safe pure
{
    pragma(inline, false);
    import mir.ion.stream;
    import mir.ion.ser.json: serializeJson;
    return data.IonValueStream.serializeJson;
}

///
@safe pure
unittest
{
    const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    assert(data.ion2json == `{"a":1,"b":2}`);
}

unittest
{
    import std.stdio;
    assert("".json2ion.ion2text == "");
}

/++
Converts Ion Value Stream data to JSON text

The function performs `data.IonValueStream.serializeJsonPretty`.
+/
string ion2jsonPretty(scope const(ubyte)[] data)
    @safe pure
{
    pragma(inline, false);
    import mir.ion.stream;
    import mir.ion.ser.json: serializeJsonPretty;
    return data.IonValueStream.serializeJsonPretty;
}

///
@safe pure
unittest
{
    const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    assert(data.ion2jsonPretty == "{\n\t\"a\": 1,\n\t\"b\": 2\n}");
}

/++
Convert an Ion Text value to a Ion Value Stream.
Params:
    addSymbolTable = Add the symbol table to the data stream outputted
    text = The text to convert
Returns:
    An array containing the Ion Text value as an Ion Value Stream.
+/
immutable(ubyte)[] text2ion(bool addSymbolTable = true)(scope const(char)[] text)

    @trusted pure
{
    import mir.ion.internal.data_holder: ionPrefix, IonTapeHolder;
    import mir.ion.internal.stage4_s;
    import mir.ion.symbol_table: IonSymbolTable;
    import mir.ion.internal.data_holder: ionPrefix;
    import mir.ion.ser.ion : IonSerializer;
    import mir.serde : SerdeTarget;
    import mir.ion.deser.text : IonTextDeserializer;
    enum nMax = 4096;
    IonTapeHolder!(nMax * 8) tapeHolder = void;
    tapeHolder.initialize;
    IonSymbolTable!true table;
    auto ser = IonSerializer!(typeof(tapeHolder), null, true)(
        () @trusted { return &tapeHolder; }(),
        () @trusted { return &table; }(),
        SerdeTarget.ion
    );

    auto deser = IonTextDeserializer!(typeof(ser))(
        () @trusted { return &ser; }()
    );

    deser(text);

    static if (addSymbolTable)
    {
        static immutable ctPrefixAndTable = ionPrefix ~ ser.compiletimeTableTape;
        if (table.initialized)
        {
            table.finalize;
            return cast(immutable) (ionPrefix ~ table.tapeData ~ tapeHolder.tapeData);
        }
        else
        {
            return cast(immutable) (ctPrefixAndTable ~ tapeHolder.tapeData);
        }
    }   
    else 
    {
        return cast(immutable) tapeHolder.tapeData;
    }
}
///
@safe pure
unittest
{
    const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    assert(`{"a":1,"b":2}`.text2ion == data);
}

/++
Converts Ion Value Stream data to text.

The function performs `data.IonValueStream.serializeText`.
+/
string ion2text(scope const(ubyte)[] data)
    @safe pure
{
    pragma(inline, false);
    import mir.ion.stream;
    import mir.ion.ser.text: serializeText;
    return data.IonValueStream.serializeText;
}

///
@safe pure
unittest
{
    const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    assert(data.ion2text == `{a:1,b:2}`);
}

///
@safe pure
unittest
{
    const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xea, 0x81, 0x83, 0xde, 0x86, 0x87, 0xb4, 0x83, 0x55, 0x53, 0x44, 0xe6, 0x81, 0x8a, 0x53, 0xc1, 0x04, 0xd2];
    assert(data.ion2text == `USD::123.4`);
}

// 

/++
Converts Ion Value Stream data to text

The function performs `data.IonValueStream.serializeTextPretty`.
+/
string ion2textPretty(scope const(ubyte)[] data)
    @safe pure
{
    pragma(inline, false);
    import mir.ion.stream;
    import mir.ion.ser.text: serializeTextPretty;
    return data.IonValueStream.serializeTextPretty;
}

///
@safe pure
unittest
{
    const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    assert(data.ion2textPretty == "{\n\ta: 1,\n\tb: 2\n}");
}
