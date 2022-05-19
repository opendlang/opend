///
module mir.ion.examples;

/// A user may define setter and/or getter properties.
@safe pure
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;
    import mir.conv: to;

    static struct S
    {
        @serdeIgnore string str;
    @safe pure:
        string a() @property
        {
            return str;
        }

        void b(int s) @property
        {
            str = s.to!string;
        }
    }

    assert(S("str").serializeJson == `{"a":"str"}`);
    assert(`{"b":123}`.deserializeJson!S.str == "123");
}

/// Support for custom nullable types (types that has a bool property `isNull`,
/// non-void property `get` returning payload and void property `nullify` that
/// makes nullable type to null value)
@safe pure
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;

    static struct MyNullable
    {
        long value;

    @safe pure:

        @property
        isNull() const
        {
            return value == 0;
        }

        @property
        get()
        {
            return value;
        }

        @property
        nullify()
        {
            value = 0;
        }

        auto opAssign(long value)
        {
            this.value = value;
        }
    }

    static struct Foo
    {
        MyNullable my_nullable;
        string field;

        bool opEquals()(auto ref const(typeof(this)) rhs)
        {
            if (my_nullable.isNull && rhs.my_nullable.isNull)
                return field == rhs.field;

            if (my_nullable.isNull != rhs.my_nullable.isNull)
                return false;

            return my_nullable == rhs.my_nullable &&
                         field == rhs.field;
        }
    }

    Foo foo;
    foo.field = "it's a foo";

    assert (serializeJson(foo) == `{"my_nullable":null,"field":"it's a foo"}`);

    foo.my_nullable = 200;

    assert (deserializeJson!Foo(`{"my_nullable":200,"field":"it's a foo"}`) == Foo(MyNullable(200), "it's a foo"));

    import mir.algebraic: Nullable;

    static struct Bar
    {
        Nullable!long nullable;
        string field;

        bool opEquals()(auto ref const(typeof(this)) rhs)
        {
            if (nullable.isNull && rhs.nullable.isNull)
                return field == rhs.field;

            if (nullable.isNull != rhs.nullable.isNull)
                return false;

            return nullable == rhs.nullable &&
                         field == rhs.field;
        }
    }

    Bar bar;
    bar.field = "it's a bar";

    assert (serializeJson(bar) == `{"nullable":null,"field":"it's a bar"}`);

    bar.nullable = 777;
    assert (deserializeJson!Bar(`{"nullable":777,"field":"it's a bar"}`) == Bar(Nullable!long(777), "it's a bar"));
}

///
@safe pure
version(mir_ion_test) unittest
{
    import mir.ser.ion;
    import mir.ser.json;
    import mir.ion.stream;

    IonValueStream[string] map;

    map["num"] = IonValueStream(serializeIon(124));
    map["str"] = IonValueStream(serializeIon("value"));
    
    auto json = map.serializeJson;
    assert(json == `{"str":"value","num":124}` || json == `{"num":124,"str":"value"}`);
}

/// Support for floating point nan and (partial) infinity
version(mir_ion_test) unittest
{
    import mir.conv: to;
    import mir.ser.ion;
    import mir.ser.json;
    import mir.deser.json;
    import mir.ion.conv;

    static struct Foo
    {
        float f;

        bool opEquals()(auto ref const(typeof(this)) rhs)
        {
            return  f != f && rhs.f != rhs.f || f == rhs.f;
        }
    }

    // test for Not a Number
    assert (serializeJson(Foo()) == `{"f":"nan"}`, serializeJson(Foo()));
    assert (serializeIon(Foo()).ion2json == `{"f":"nan"}`, serializeIon(Foo()).ion2json);

    assert (deserializeJson!Foo(`{"f":"nan"}`) == Foo(), deserializeJson!Foo(`{"f":"nan"}`).to!string);

    assert (serializeJson(Foo(1f/0f)) == `{"f":"+inf"}`);
    assert (serializeIon(Foo(1f/0f)).ion2json == `{"f":"+inf"}`);
    assert (deserializeJson!Foo(`{"f":"+inf"}`)  == Foo( float.infinity));
    assert (deserializeJson!Foo(`{"f":"-inf"}`) == Foo(-float.infinity));

    assert (serializeJson(Foo(-1f/0f)) == `{"f":"-inf"}`);
    assert (serializeIon(Foo(-1f/0f)).ion2json == `{"f":"-inf"}`);
    assert (deserializeJson!Foo(`{"f":"-inf"}`) == Foo(-float.infinity));
}

///
version(mir_ion_test) unittest
{
    import mir.ser.ion;
    import mir.ser.json;
    import mir.deser.json;
    import mir.ion.conv;

    static struct S
    {
        string foo;
        uint bar;
    }

    static immutable json = `{"foo":"str","bar":4}`;
    assert(serializeIon(S("str", 4)).ion2json == json);
    assert(serializeJson(S("str", 4)) == json);
    assert(deserializeJson!S(json) == S("str", 4));
}

/// Proxy for members
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;

    struct S
    {
        // const(char)[] doesn't reallocate ASDF data.
        @serdeProxy!(const(char)[])
        uint bar;
    }

    auto json = `{"bar":"4"}`;
    assert(serializeJson(S(4)) == json);
    assert(deserializeJson!S(json) == S(4));
}

///
pure version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;
    import mir.serde: serdeKeys;
    static struct S
    {
        @serdeKeys("b", "a")
        string s;
    }
    assert(`{"a":"d"}`.deserializeJson!S.serializeJson == `{"b":"d"}`);
}

///
pure version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;
    import mir.serde: serdeKeys, serdeKeyOut;
    static struct S
    {
        @serdeKeys("a")
        @serdeKeyOut("s")
        string s;
    }
    assert(`{"a":"d"}`.deserializeJson!S.serializeJson == `{"s":"d"}`);
}

///
pure version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;
    import std.exception: assertThrown;

    struct S
    {
        string field;
    }
    
    assert(`{"field":"val"}`.deserializeJson!S.field == "val");
    // assertThrown(`{"other":"val"}`.deserializeJson!S);
}

///
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;

    static struct S
    {
        @serdeKeyOut("a")
        string s;
    }
    assert(`{"s":"d"}`.deserializeJson!S.serializeJson == `{"a":"d"}`);
}

///
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;
    import std.exception: assertThrown;

    static struct S
    {
        @serdeIgnore
        string s;
    }
    // assertThrown(`{"s":"d"}`.deserializeJson!S);
    assert(S("d").serializeJson == `{}`);
}

///
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;

    static struct Decor
    {
        int candles; // 0
        float fluff = float.infinity; // inf 
    }
    
    static struct Cake
    {
        @serdeIgnoreDefault string name = "Chocolate Cake";
        @serdeIgnoreDefault string nullStr;
        @serdeIgnoreDefault string emptyStr = "";
        int slices = 8;
        float flavor = 1;
        @serdeIgnoreDefault
        Decor dec = Decor(20); // { 20, inf }
    }
    
    assert(Cake("Normal Cake", "", null).serializeJson == `{"name":"Normal Cake","slices":8,"flavor":1.0}`);
    auto cake = Cake.init;
    cake.dec = Decor.init;
    assert(cake.serializeJson == `{"slices":8,"flavor":1.0,"dec":{"candles":0,"fluff":"+inf"}}`);
    assert(cake.dec.serializeJson == `{"candles":0,"fluff":"+inf"}`);
    
    static struct A
    {
        @serdeIgnoreDefault
        string str = "Banana";
        int i = 1;
    }
    assert(A.init.serializeJson == `{"i":1}`);
    
    static struct S
    {
        @serdeIgnoreDefault
        A a;
    }
    assert(S.init.serializeJson == `{}`);
    assert(S(A("Berry")).serializeJson == `{"a":{"str":"Berry","i":1}}`);
    
    static struct D
    {
        S s;
    }
    assert(D.init.serializeJson == `{"s":{}}`);
    assert(D(S(A("Berry"))).serializeJson == `{"s":{"a":{"str":"Berry","i":1}}}`);
    assert(D(S(A(null, 0))).serializeJson == `{"s":{"a":{"str":"","i":0}}}`);
    
    static struct F
    {
        D d;
    }
    assert(F.init.serializeJson == `{"d":{"s":{}}}`);
}

///
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;
    import mir.serde: serdeIgnoreOut;

    static struct S
    {
        @serdeIgnoreOut
        string s;
    }
    assert(`{"s":"d"}`.deserializeJson!S.s == "d");
    assert(S("d").serializeJson == `{}`);
}

///
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;

    static struct CustomType
    {
        int a;

        // can be part of a type as well (only omits on property keys)
        bool serdeIgnoreOut() const
        {
            return a < 0;
        }

        // and use custom serializer to serialize as int
        void serialize(S)(ref S serializer) const
        {
            import mir.ser : serializeValue;

            serializeValue(serializer, a);
        }
    }

    static struct S
    {
        @serdeIgnoreOutIf!`a < 0`
        int a;

        // b is not output if the serdeIgnoreOut property in its type evaluates to false.
        CustomType b;
    }

    assert(serializeJson(S(3, CustomType(2))) == `{"a":3,"b":2}`, serializeJson(S(3, CustomType(2))));
    assert(serializeJson(S(-3, CustomType(-2))) == `{}`);
}

///
@safe pure
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;

    import std.uuid: UUID;

    static struct S
    {
        @serdeScoped
        @serdeProxy!string
        UUID id;
    }

    enum result = UUID("8AB3060E-2cba-4f23-b74c-b52db3bdfb46");
    assert(`{"id":"8AB3060E-2cba-4f23-b74c-b52db3bdfb46"}`.deserializeJson!S.id == result);
}

///
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;
    import mir.ion.value;
    import mir.algebraic: Variant;

    static struct ObjectA
    {
        string name;
    }
    static struct ObjectB
    {
        double value;
    }

    alias MyObject = Variant!(ObjectA, ObjectB);

    static struct MyObjectArrayProxy
    {
        MyObject[] array;

        this(MyObject[] array) @safe pure nothrow @nogc
        {
            this.array = array;
        }

        T opCast(T : MyObject[])()
        {
            return array;
        }

        void serialize(S)(ref S serializer) const
        {
            import mir.ser: serializeValue;
            // mir.algebraic has builtin support for serialization.
            // For other algebraic libraies one can use thier visitor handlers.
            serializeValue(serializer, array);
        }

        /++
        Returns: error msg if any
        +/
        @safe pure
        IonException deserializeFromIon(scope const char[][] symbolTable, IonDescribedValue value)
        {
            import mir.deser.ion: deserializeIon;
            import mir.ion.exception;
            foreach (IonErrorCode error, IonDescribedValue elem; value.get!IonList)
            {
                if (error)
                    return error.ionException;
                array ~= "name" in elem.get!IonStruct.withSymbols(symbolTable)
                    ? MyObject(deserializeIon!ObjectA(symbolTable, elem))
                    : MyObject(deserializeIon!ObjectB(symbolTable, elem));
            }
            return null;
        }
    }

    static struct SomeObject
    {
        @serdeProxy!MyObjectArrayProxy MyObject[] objects;
    }

    string data = q{{"objects":[{"name":"test"},{"value":1.5}]}};

    auto value = data.deserializeDynamicJson!SomeObject;
    assert (value.serializeJson == data, value.serializeJson);
}

// TODO
// version(none)
// unittest
// {
//     Asdf[string] map;

//     map["num"] = serializeToAsdf(124);
//     map["str"] = serializeToAsdf("value");

//     import std.stdio;
//     map.serializeToJson.writeln();
// }

// TODO
// version(none)
// unittest
// {
//     import mir.algebraic: Variant, Nullable, This;
//     alias V = Nullable!(double, string, This[], This[string]);
//     V v;
//     assert(v.serializeToJson == "null", v.serializeToJson);
//     v = [V(2), V("str"), V(["key":V(1.0)])];
//     assert(v.serializeToJson == `[2.0,"str",{"key":1.0}]`);
// }

/// reflectSerde support
version(mir_ion_test) unittest
{
    import mir.reflection: reflectSerde;
    static struct S
    {
        @reflectSerde enum s = "str";
    }

    import mir.ser.text: serializeText;
    assert(S().serializeText == `{s:"str"}`);
}

/// serdeIgnoreUnexpectedKeys support
version(mir_ion_test) unittest
{
    import mir.serde: serdeIgnoreUnexpectedKeys;
    @serdeIgnoreUnexpectedKeys
    static struct S { int i; }

    import mir.deser.text: deserializeText;
    assert(`{s:"str",i:4}`.deserializeText!S == S(4));
}

/// Iterable and serdeLikeList
version(mir_ion_test) unittest
{
    import mir.deser.text: deserializeText;
    import mir.ser.text: serializeText;
    import mir.serde: serdeIgnoreOut, serdeLikeList, serdeProxy, serdeKeys;
    import std.array: Appender;

    static struct S
    {
        @serdeLikeList
        @serdeProxy!string // input element type of
        @serdeIgnoreOut
        @serdeKeys("strings")
        Appender!(string[]) stringsApp; //`put` method is used

        this(const(string)[] strings)
        {
            stringsApp.put(strings);
        }

        auto strings() const @property // Iterable
        {
            import mir.ndslice.topology: map;
            return stringsApp.data.map!((string s) => "_" ~ s);
        }

    }

    assert(S([`a`, `b`]).serializeText == `{strings:["_a","_b"]}`);
    assert(`{strings:["a","b"]}`.deserializeText!S.stringsApp.data == [`a`, `b`]);

    @serdeLikeList
    @serdeProxy!string // input element type of
    static struct C
    {
        /// Used to make S deserializable
        Appender!(string[]) stringsApp; //`put` method is used
        alias stringsApp this;

        this(const(string)[] strings)
        {
            stringsApp.put(strings);
        }

        /// To make C iterable and serializable
        auto opIndex() const { return stringsApp.data; }
    }

    static struct S2 {
        static prop() @property { return "100"; };
    }

    assert(S2().serializeText == `{prop:"100"}`, S2().serializeText);
    assert(C([`a`, `b`]).serializeText == `["a","b"]`);
    assert(`["a","b"]`.deserializeText!C.stringsApp.data == [`a`, `b`]);
}

/// serdeLikeStruct
unittest
{
    import mir.ser.text: serializeText;
    import mir.deser.text: deserializeText;
    import mir.serde: serdeLikeStruct, serdeProxy;

    // opApply for serialization & and opIndexAssign for deserialization
    static struct M
    {
        private int sum;

        // opApply is used for serialization
        int opApply(int delegate(scope const char[] key, ref const int val) pure @safe dg) pure @safe
        {
            { int var = 1; if (auto r = dg("a", var)) return r; }
            { int var = 2; if (auto r = dg("b", var)) return r; }
            { int var = 3; if (auto r = dg("c", var)) return r; }
            return 0;
        }

        // opIndexAssign for deserialization
        void opIndexAssign(int val, string key) pure @safe
        {
            sum += val;
        }
    }

    // attribute on member + opApply
    static struct S
    {
        @serdeLikeStruct
        @serdeProxy!int // for deserialization
        M obj;
    }

    assert(S().serializeText == `{obj:{a:1,b:2,c:3}}`);
    assert(`{obj:{a:1,b:2,c:3}}`.deserializeText!S.obj.sum == 6);

    // attribute on type + opApply
    @serdeLikeStruct
    @serdeProxy!int // for deserialization
    static struct C
    {
        M obj;
        alias obj this;
    }

    assert(C().serializeText == `{a:1,b:2,c:3}`);
    assert(`{a:1,b:2,c:3}`.deserializeText!C.obj.sum == 6);

    // byKeyValue
    static struct D
    {
        static struct KeyValue
        {
            string key;
            int value;
        }
        KeyValue[] byKeyValue = [KeyValue("a", 1), KeyValue("b", 2), KeyValue("c", 3)];
    }

    // attribute on member + byKeyValue
    static struct F
    {
        @serdeLikeStruct
        D obj;
    }

    assert(F().serializeText == `{obj:{a:1,b:2,c:3}}`);

    // attribute on type + byKeyValue
    @serdeLikeStruct
    static struct B
    {
        D obj;
        alias obj this;
    }

    assert(B().serializeText == `{a:1,b:2,c:3}`);
}

///
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;
    import std.range;
    import std.algorithm;
    import std.conv;

    static struct S
    {
        @serdeTransformIn!"a += 2"
        @serdeTransformOut!(a =>"str".repeat.take(a).joiner("_").to!string)
        int a;
    }

    auto s = deserializeJson!S(`{"a":3}`);
    assert(s.a == 5);
    assert(serializeJson(s) == `{"a":"str_str_str_str_str"}`);
}

///
@safe pure
version(mir_ion_test) unittest
{
    static struct Toto  
    {
        import mir.ndslice.slice: Slice;

        Slice!(int*, 2) a;
        Slice!(int*, 1) b;

        this(int x) @safe pure nothrow
        {
            import mir.ndslice.topology: iota, repeat;
            import mir.ndslice.allocation: slice;

            a = [2, 3].iota!int.slice;
            b = repeat(x, [2]).slice;
        }
    }

    auto toto = Toto(5);

    import mir.ser.json: serializeJson;
    import mir.deser.json: deserializeJson;

    auto description = toto.serializeJson!Toto;
    assert(description == q{{"a":[[0,1,2],[3,4,5]],"b":[5,5]}});
    assert(toto == description.deserializeJson!Toto);
}

///
@safe pure @nogc
version(mir_ion_test) unittest
{
    static struct Toto  
    {
        import mir.ndslice.slice: Slice;
        import mir.rc.array: RCI;

        Slice!(RCI!int, 2) a;
        Slice!(RCI!int, 1) b;

        this(int x) @safe pure nothrow @nogc
        {
            import mir.ndslice.topology: iota, repeat;
            import mir.ndslice.allocation: rcslice;

            a = [2, 3].iota!int.rcslice;
            b = repeat(x, [2]).rcslice;
        }
    }

    auto toto = Toto(5);

    import mir.ser.json: serializeJson;
    import mir.deser.json: deserializeJson;
    import mir.format: stringBuf;

    stringBuf buffer;
    serializeJson(buffer, toto);
    auto description = buffer.data;
    assert(description == q{{"a":[[0,1,2],[3,4,5]],"b":[5,5]}});
    assert(toto == description.deserializeJson!Toto);
}

/++
User defined algebraic types deserialization supports any subset of the following types:

$(UL 
$(LI `typeof(null)`)
$(LI `bool`)
$(LI `long`)
$(LI `double`)
$(LI `string`)
$(LI `AnyType[]`)
$(LI `StringMap!AnyType`)
$(LI `AnyType[string]`)
)

A `StringMap` has has priority over builtin associative arrays.

Serializations works with any algebraic types.

See_also: $(GMREF mir-core, mir,algebraic), $(GMREF mir-algorithm, mir,string_map)
+/
version(mir_ion_test) unittest
{
    import mir.string_map;
    import mir.deser.ion: deserializeIon;
    import mir.ion.conv: json2ion, ion2text;
    import mir.algebraic: Nullable, This; // Nullable, Variant, or TaggedVariant
    alias MyJsonAlgebraic = Nullable!(bool, string, double[], StringMap!This);

    auto json = `{"b" : true, "z" : null, "this" : {"c" : "str", "d" : [1, 2, 3, 4]}}`;
    auto binary = json.json2ion;
    auto value = binary.deserializeIon!MyJsonAlgebraic;

    auto object = value.get!(StringMap!MyJsonAlgebraic);
    assert(object["b"].get!bool == true);
    assert(object["z"].isNull);

    object = object["this"].get!(StringMap!MyJsonAlgebraic);
    assert(object["c"].get!string == "str");
    assert(object["d"].get!(double[]) == [1.0, 2, 3, 4]);
}

///
version(mir_ion_test) unittest
{
    import mir.algebraic_alias.json;
    import mir.ser.json: serializeJson;
    auto value = [JsonAlgebraic[].init.JsonAlgebraic, StringMap!JsonAlgebraic.init.JsonAlgebraic, string.init.JsonAlgebraic];
    assert(value.serializeJson == `[[],{},""]`, value.serializeJson);
}

///
version(mir_ion_test) @safe pure unittest
{
    import mir.serde : serdeFallbackStruct;
    import mir.algebraic;
    import mir.deser.text;
    import mir.deser.json;
    @serdeFallbackStruct struct S { string path; }
    alias V = Variant!(string, S);
    static immutable res = [V("str"), V(S("root"))];
    assert(q{["str", {path: root}]}.deserializeText!(V[]) == res);
    assert(q{["str", {"path": "root"}]}.deserializeDynamicJson!(V[]) == res);
}

/// Date serialization
version(mir_ion_test) unittest
{
    import mir.date;
    import mir.ion.conv: ion2text;
    import mir.ser.ion: serializeIon;
    import mir.ser.json: serializeJson;
    import mir.ser.text: serializeText;
    assert(Date(2021, 4, 24).serializeIon.ion2text == `2021-04-24`);
    assert(Date(2021, 4, 24).serializeText == `2021-04-24`);
    assert(Date(2021, 4, 24).serializeJson == `"2021-04-24"`);
}

/// Timestamp and LOB support in algebraic types
version(mir_ion_test) unittest
{
    import mir.algebraic;
    import mir.deser.ion: deserializeIon;
    import mir.ser.ion: serializeIon;
    import mir.lob;
    import mir.string_map;
    import mir.timestamp;

    alias IonLikeAlgebraic = Variant!(Blob, Clob, Timestamp, double, long, string, StringMap!This, This[]);

    StringMap!IonLikeAlgebraic map;
    map["ts"] = Timestamp(2021, 4, 24);
    map["clob"] = Clob("Some clob");
    map["blob"] = Blob([0x32, 0x52]);

    assert(map.serializeIon.deserializeIon!(StringMap!IonLikeAlgebraic) == map);
}

/// Phobos date-time serialization
version(mir_ion_test) unittest
{
    import core.time : hnsecs, minutes;
    import mir.ion.conv: ion2text;
    import mir.ser.ion: serializeIon;
    import mir.ser.json: serializeJson;
    import mir.ser.text: serializeText;
    import mir.deser.ion: deserializeIon;
    import mir.deser.json: deserializeJson;
    import std.datetime.date : Date, DateTime;
    import std.datetime.systime : SysTime;
    import std.datetime.timezone : SimpleTimeZone;

    auto date = Date(2021, 4, 24);
    assert(date.serializeIon.ion2text == `2021-04-24`);
    assert(date.serializeText == `2021-04-24`);
    assert(date.serializeJson == `"2021-04-24"`);
    assert(`"2021-04-24"`.deserializeJson!Date == date);

    auto datetime = DateTime(1982, 4, 1, 20, 59, 22);
    assert(datetime.serializeIon.ion2text == `1982-04-01T20:59:22Z`);
    assert(datetime.serializeText == `1982-04-01T20:59:22Z`);
    assert(datetime.serializeJson == `"1982-04-01T20:59:22Z"`);
    assert(`"1982-04-01T20:59:22Z"`.deserializeJson!DateTime == datetime);

    auto dt = DateTime(1982, 4, 1, 20, 59, 22);
    auto tz = new immutable SimpleTimeZone(-330.minutes);
    auto st = SysTime(dt, 1234567.hnsecs, tz);
    assert(st.serializeIon.ion2text == `1982-04-01T20:59:22.1234567-05:30`);
    assert(st.serializeText == `1982-04-01T20:59:22.1234567-05:30`);
    assert(st.serializeJson == `"1982-04-01T20:59:22.1234567-05:30"`);
    assert(st.serializeIon.deserializeIon!SysTime == st);
    assert(`"1982-04-01T20:59:22.1234567-05:30"`.deserializeJson!SysTime == st);
}

version(mir_ion_test) unittest
{
    import mir.deser.json;
    auto s = q{"n2. Clone theproject_n_n        git clone git://github.com/rej\n2. Clone the project_n_n        git clone git://github.com/rejn"}.deserializeJson!string;
    assert(s == "n2. Clone theproject_n_n        git clone git://github.com/rej\n2. Clone the project_n_n        git clone git://github.com/rejn", s);
}

version(mir_ion_test) unittest
{
    import mir.deser.json;
    assert(q{"n2. Clone theproject_n_n        git clone git://github.com/rej\"). Clone the project_n_n        git clone git://github.com/rejn"}
        .deserializeJson!string == 
             "n2. Clone theproject_n_n        git clone git://github.com/rej\"). Clone the project_n_n        git clone git://github.com/rejn");
}

/// Static array support
@safe pure
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;
    int[3] value = [1, 2, 3];
    assert(`[1,2,3]`.deserializeJson!(int[3]) == value);
    assert(value.serializeJson == `[1,2,3]`);
}

/// ditto
@safe pure
version(mir_ion_test) unittest
{
    import mir.ser.json;
    import mir.deser.json;
    static struct S { int v; }
    S[3] value = [S(1), S(2), S(3)];
    auto text = `[{"v":1},{"v":2},{"v":3}]`;
    assert(text.deserializeJson!(S[3]) == value);
    assert(value.serializeJson == text);
}

// AliasThis and serdeProxy
version(mir_ion_test) unittest
{
    @serdeProxy!(int[3])
    static struct J
    {
        int[3] ar;
        alias ar this;
    }

    import mir.ser.json;
    import mir.deser.json;
    auto value = J([1, 2, 3]);
    assert(value.serializeJson == `[1,2,3]`);
    assert(`[1,2,3]`.deserializeJson!J == value);
}


version(mir_ion_test) unittest
{
    import mir.ser.text;

    static struct A {
        private int _a;
        const @property:
        int a() @safe pure { return _a; }
    }

    auto stra = A(3);

    assert(stra.serializeText == `{a:3}`, stra.serializeText);
}

///
version(mir_ion_test) unittest
{
    auto json = q{{
        "a": [
            0.0031
        ],
        "b": [
            0.999475,
            0.999425
        ]
    }};
    import mir.deser.json;
    static struct S {
        double[] a;

        void serdeUnexpectedKeyHandler(scope const(char)[] key) @safe pure nothrow @nogc
        {
            assert(key == "b");
        }
    }
    auto value = json.deserializeJson!(double[][string]);
    auto partialStruct = json.deserializeJson!S;
}

///
version(mir_ion_test) unittest
{
    auto json = q{{
        "index": 0.9962125,
        "data": 0.0001
    }};

    import mir.deser.json;
    import mir.series;

    alias T = Observation!(double, double);
    auto value = json.deserializeJson!T;
    assert(value.index == 0.9962125);
    assert(value.data == 0.0001);
}

///
version(mir_ion_test) unittest
{
    static class MyHugeRESTString
    {
        string s;

        this(string s)  @safe pure nothrow @nogc
        {
            this.s = s;
        }

        void serialize(S)(ref S serializer) const
        {
            auto state = serializer.stringBegin;
            // putStringPart is usefull in the loop and with buffers
            serializer.putStringPart(s);
            serializer.putStringPart(" Another chunk.");
            serializer.stringEnd(state);
        }
    }

    import mir.algebraic: Nullable, This;
    import mir.string_map;

    // Your JSON DOM Type
    alias Json = Nullable!(bool, long, double, string, MyHugeRESTString, StringMap!This, This[]);

    /// ordered
    StringMap!Json response;
    response["type"] = Json("response");
    response["data"] = Json(new MyHugeRESTString("First chunk."));

    import mir.ion.conv: ion2text;
    import mir.ser.ion;
    import mir.ser.json;
    import mir.ser.text;

    assert(response.serializeJson == `{"type":"response","data":"First chunk. Another chunk."}`);
    assert(response.serializeText == `{type:"response",data:"First chunk. Another chunk."}`);
    assert(response.serializeIon.ion2text == `{type:"response",data:"First chunk. Another chunk."}`);
}

/// Float proxy for integer types
version(mir_ion_test) unittest
{
    import mir.deser.json;
    static struct S {
        @serdeProxy!double
        long integralValue;
    }

    assert(`{"integralValue":1.23e+2}`.deserializeJson!S.integralValue == 123);
}

/// Annotated variant
version(mir_ion_test) unittest
{
    import mir.algebraic;
    import mir.deser.json;
    import mir.deser.text;
    import mir.ser.json;
    import mir.ser.text;

    @serdeAlgebraicAnnotation("s1")
    static struct S1 {
        string key;
    }

    @serdeAlgebraicAnnotation("s2")
    static struct S2 {
        long key;
    }

    alias V = Variant!(S1, S2);
    auto v = V(S2(123));

    auto ion = `s2::{key:123}`;
    auto json = `{"s2":{"key":123}}`;
    assert(v.serializeText == ion);
    assert(ion.deserializeText!V == v);
    assert(v.serializeJson == json);
    assert(json.deserializeJson!V == v);
}

/// Annotated arrays
version(mir_ion_test) unittest
{
    import mir.algebraic;
    import mir.deser.ion;
    import mir.ser.ion;
    import mir.ser.text;
    import mir.serde;

    @serdeAlgebraicAnnotation("annotation")
    @serdeProxy!(long[])
    static struct St3 {
        long[] arr;
        alias arr this;
    }
    alias V = Variant!St3;

    assert(V(St3([123])).serializeText == `annotation::[123]`);
    assert(V(St3([123])).serializeIon.deserializeIon!V == St3([123]));
}

version(mir_ion_test) @nogc unittest
{
    import mir.ion.conv: text2ion;
    import mir.deser.ion;
    import mir.serde;

    @serdeScoped
    @serdeProxy!(const(char)[])
    static struct S
    {
        bool r;
        this(scope const(char)[] s) @safe pure nothrow @nogc
        {
            this.r = s == `simpleSymbol`;
        }
    }
    static immutable data = `simpleSymbol`.text2ion;
    assert(data.deserializeIon!S.r);
}

version(unittest) private
{
    import mir.serde: serdeProxy;

    @serdeProxy!ProxyE
    enum E
    {
        none,
        bar,
    }

    // const(char)[] doesn't reallocate ASDF data.
    @serdeProxy!(const(char)[])
    struct ProxyE
    {
        E e;

    @safe pure:

        this(E e)
        {
            this.e = e;
        }

        this(in char[] str) @trusted
        {
            switch(str)
            {
                case "NONE":
                case "NA":
                case "N/A":
                    e = E.none;
                    break;
                case "BAR":
                case "BR":
                    e = E.bar;
                    break;
                default:
                    throw new Exception("Unknown: " ~ cast(string)str);
            }
        }

        string toString() const
        {
            if (e == E.none)
                return "NONE";
            else
                return "BAR";
        }

        E opCast(T : E)()
        {
            return e;
        }
    }

    version(mir_ion_test) unittest
    {
        import mir.ser.json;
        import mir.deser.json;

        assert(serializeJson(E.bar) == `"BAR"`);
        assert(`"N/A"`.deserializeJson!E == E.none);
        assert(`"NA"`.deserializeJson!E == E.none);
    }
}

// check symbols support
// check typed nullable support
// check void support
version(mir_ion_test) unittest
{
    import mir.algebraic_alias.ion;
    import mir.algebraic;
    import mir.annotated;
    import mir.deser.text;
    import mir.ser.text;
    import mir.ion.type_code;
    import mir.ion.value: IonNull;
    import mir.small_string;
    import mir.timestamp;
    assert(`aSymbol`.deserializeText!(Nullable!(bool, double, long, string, Timestamp)) == `aSymbol`);
    assert(`aSymbol`.deserializeText!(Nullable!(bool, double, long, SmallString!32, Timestamp)) == `aSymbol`.SmallString!32);
    assert(`null.timestamp`.deserializeText!(Nullable!Timestamp) == null);
    assert(`null.timestamp`.deserializeText!(Nullable!(bool, Timestamp)) == null);
    //IonNull support
    assert(`null.timestamp`.deserializeText!(Variant!(IonNull, bool, Timestamp)) == IonTypeCode.timestamp.IonNull);
    //Annotated support
    auto annotated = Annotated!IonAlgebraic(["birthday"], Timestamp("2001-01-01"));
    auto variant = `birthday::2001-01-01`.deserializeText!IonAlgebraic;
    // assert(variant == annotated);
    assert(Nullable!(void, int)(3).serializeText == "3");
}

version(mir_ion_test) unittest
{
    import mir.deser.text;
    import mir.ser.text;
    enum CaseSensitive
    {
        no,
        yes,
        osDefault = yes,
    }

    assert(CaseSensitive.osDefault.serializeText == `yes`);
    assert(`yes`.deserializeText!CaseSensitive == CaseSensitive.yes);

    enum TextAlignment : uint {
        Left = 0, ///
        Center = 1, ///
        Right = 2, ///

        VerticalTop = 0, ///
        VerticalCenter = 4, ///
        VerticalBottom = 8, ///
    }

    assert(TextAlignment.VerticalTop.serializeText == `Left`);
    assert(`Left`.deserializeText!TextAlignment == TextAlignment.Left);
}

version(mir_ion_test) unittest
{
    import mir.ndslice.topology: iota, as;
    auto range = as!char(3.iota + 'a');
    assert(range == "abc");
    import mir.ser.text;
    assert(range.serializeText == `"abc"`);
}

/// Series de/serialization
@safe version(mir_ion_test) unittest
{
    import mir.deser.text;
    import mir.ser.text;
    import mir.series;
    auto s = ["a", "b"].series([5, 6]);
    auto t = `{index:["a","b"],data:[5,6]}`;
    auto r = `{index:["b","a"],data:[6,5]}`;
    assert(s.serializeText == t);
    assert(r.deserializeText!(typeof(s)) == s, r.deserializeText!(typeof(s)).serializeText);
}

// Const series de/serialization
@safe version(mir_ion_test) unittest
{
    import mir.deser.text;
    import mir.ser.text;
    import mir.series;
    auto s = ["a", "b"].series([5, 6]).lightConst;
    auto t = `{index:["a","b"],data:[5,6]}`;
    auto r = `{index:["b","a"],data:[6,5]}`;
    assert(s.serializeText == t);
    assert(r.deserializeText!(typeof(s)) == s, r.deserializeText!(typeof(s)).serializeText);
}

/// RC Series de/serialization
@safe version(mir_ion_test) unittest
{
    import mir.deser.text;
    import mir.ser.text;
    import mir.ndslice.allocation: rcslice;
    import mir.series;
    import mir.small_string;
    auto s = [SmallString!32("a"), SmallString!32("b")].rcslice.series([5, 6].rcslice);
    auto t = `{index:["a","b"],data:[5,6]}`;
    auto r = `{index:["b","a"],data:[6,5]}`;
    assert(s.serializeText == t);
    assert(r.deserializeText!(typeof(s)) == s, r.deserializeText!(typeof(s)).serializeText);
}

// Const RC Series de/serialization
@safe version(mir_ion_test) unittest
{
    import mir.deser.text;
    import mir.ser.text;
    import mir.ndslice.allocation: rcslice;
    import mir.series;
    import mir.small_string;
    auto s = [SmallString!32("a"), SmallString!32("b")].rcslice.series([5, 6].rcslice).lightConst;
    auto t = `{index:["a","b"],data:[5,6]}`;
    auto r = `{index:["b","a"],data:[6,5]}`;
    assert(s.serializeText == t);
    assert(r.deserializeText!(typeof(s)) == s, r.deserializeText!(typeof(s)).serializeText);
}

version(mir_ion_test)
unittest
{
    import std.exception: assertThrown;
    import mir.deser.json;
    static struct S {}
    ",".deserializeJson!S.assertThrown!Exception;
}

///
@safe pure version(mir_ion_test) unittest
{
    import mir.algebraic: Nullable;
    import mir.ser.text: serializeText;
    import mir.deser.text: deserializeText;
    import mir.serde: serdeDiscriminatedField;

    @serdeDiscriminatedField("tag", "data")
    static struct D
    {
        int num;
    }

    @serdeDiscriminatedField("tag", "gr")
    static struct G
    {
        string val;
    }

    alias V = Nullable!(string, D, G);

    assert(D(123).serializeText == `{tag:data,num:123}`);
    assert(V(D(123)).serializeText == `{tag:data,num:123}`);
    assert(`{tag:data,num:123}`.deserializeText!V == D(123));
    assert(`{val:"str",tag:gr}`.deserializeText!V == G("str"));
}
