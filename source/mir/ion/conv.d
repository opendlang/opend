///
module mir.ion.conv;

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
    TapeHolder tapeHolder;
    tapeHolder.initialize;

    IonSymbolTable!false table;
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

The function performs `IonValueStream(data).serializeJson`.
+/
string ion2json(scope const(ubyte)[] data)
    @safe pure
{
    pragma(inline, false);
    import mir.ion.stream;
    import mir.ion.ser.json: serializeJson;
    return IonValueStream(data).serializeJson;
}

///
@safe pure
unittest
{
    const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    assert(data.ion2json == `{"a":1,"b":2}`);
}

/++
Converts Ion Value Stream data to JSON text

The function performs `IonValueStream(data).serializeJsonPretty`.
+/
string ion2jsonPretty(scope const(ubyte)[] data)
    @safe pure
{
    pragma(inline, false);
    import mir.ion.stream;
    import mir.ion.ser.json: serializeJsonPretty;
    return IonValueStream(data).serializeJsonPretty;
}

///
@safe pure
unittest
{
    const ubyte[] data = [0xe0, 0x01, 0x00, 0xea, 0xe9, 0x81, 0x83, 0xd6, 0x87, 0xb4, 0x81, 0x61, 0x81, 0x62, 0xd6, 0x8a, 0x21, 0x01, 0x8b, 0x21, 0x02];
    assert(data.ion2jsonPretty == "{\n\t\"a\": 1,\n\t\"b\": 2\n}");
}
