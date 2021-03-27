///
module mir.ion.examples;

/// A user may define setter and/or getter properties.
@safe pure
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;
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
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;

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
unittest
{
    import mir.ion.ser.ion;
    import mir.ion.ser.json;
    import mir.ion.stream;

    IonValueStream[string] map;

    map["num"] = IonValueStream(serializeIon(124));
    map["str"] = IonValueStream(serializeIon("value"));
    
    auto json = map.serializeJson;
    assert(json == `{"str":"value","num":124}` || json == `{"num":124,"str":"value"}`);
}

/// Support for floating point nan and (partial) infinity
unittest
{
    import mir.conv: to;
    import mir.ion.ser.ion;
    import mir.ion.ser.json;
    import mir.ion.deser.json;
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

    assert (serializeJson(Foo(1f/0f)) == `{"f":"inf"}`);
    assert (serializeIon(Foo(1f/0f)).ion2json == `{"f":"inf"}`);
    assert (deserializeJson!Foo(`{"f":"inf"}`)  == Foo( float.infinity));
    assert (deserializeJson!Foo(`{"f":"-inf"}`) == Foo(-float.infinity));

    assert (serializeJson(Foo(-1f/0f)) == `{"f":"-inf"}`);
    assert (serializeIon(Foo(-1f/0f)).ion2json == `{"f":"-inf"}`);
    assert (deserializeJson!Foo(`{"f":"-inf"}`) == Foo(-float.infinity));
}

///
unittest
{
    import mir.ion.ser.ion;
    import mir.ion.ser.json;
    import mir.ion.deser.json;
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
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;

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

        this(E e)
        {
            this.e = e;
        }

        this(in char[] str)
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

    unittest
    {
        import mir.ion.ser.json;
        import mir.ion.deser.json;

        assert(serializeJson(E.bar) == `"BAR"`);
        assert(`"N/A"`.deserializeJson!E == E.none);
        assert(`"NA"`.deserializeJson!E == E.none);
    }
}

///
pure unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;
    import mir.serde: serdeKeys;
    static struct S
    {
        @serdeKeys("b", "a")
        string s;
    }
    assert(`{"a":"d"}`.deserializeJson!S.serializeJson == `{"b":"d"}`);
}

///
pure unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;
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
pure unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;
    import std.exception: assertThrown;

    struct S
    {
        string field;
    }
    
    assert(`{"field":"val"}`.deserializeJson!S.field == "val");
    assertThrown(`{"other":"val"}`.deserializeJson!S);
}

///
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;

    static struct S
    {
        @serdeKeyOut("a")
        string s;
    }
    assert(`{"s":"d"}`.deserializeJson!S.serializeJson == `{"a":"d"}`);
}

///
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;
    import std.exception: assertThrown;

    static struct S
    {
        @serdeIgnore
        string s;
    }
    assertThrown(`{"s":"d"}`.deserializeJson!S);
    assert(S("d").serializeJson == `{}`);
}

///
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;

    static struct Decor
    {
        int candles; // 0
        float fluff = float.infinity; // inf 
    }
    
    static struct Cake
    {
        @serdeIgnoreDefault
        string name = "Chocolate Cake";
        int slices = 8;
        float flavor = 1;
        @serdeIgnoreDefault
        Decor dec = Decor(20); // { 20, inf }
    }
    
    assert(Cake("Normal Cake").serializeJson == `{"name":"Normal Cake","slices":8,"flavor":1.0}`);
    auto cake = Cake.init;
    cake.dec = Decor.init;
    assert(cake.serializeJson == `{"slices":8,"flavor":1.0,"dec":{"candles":0,"fluff":"inf"}}`);
    assert(cake.dec.serializeJson == `{"candles":0,"fluff":"inf"}`);
    
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
    assert(D(S(A(null, 0))).serializeJson == `{"s":{"a":{"str":null,"i":0}}}`);
    
    static struct F
    {
        D d;
    }
    assert(F.init.serializeJson == `{"d":{"s":{}}}`);
}

///
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;
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
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;

    static struct S
    {
        @serdeIgnoreOutIf!`a < 0`
        int a;
    }

    assert(serializeJson(S(3)) == `{"a":3}`, serializeJson(S(3)));
    assert(serializeJson(S(-3)) == `{}`);
}

///
@safe pure
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;

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
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.ion;
    import mir.ion.value;
    import mir.ion.conv;
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
            import mir.ion.ser: serializeValue;
            // mir.algebraic has builtin support for serialization.
            // For other algebraic libraies one can use thier visitor handlers.
            serializeValue(serializer, array);
        }

        /++
        
        Returns: error msg if any
        +/
        string deserializeFromIon(string[] keys)(scope const char[][] symbolTable, IonDescribedValue value)
        {
            foreach (elem; value.get!IonList)
            {
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

    auto value = data.json2ion.deserializeIon!SomeObject;
    // assert (value.serializeJson == data);
}

///
version(none)
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;

    import std.range;
    import std.uuid;

    static struct S
    {
        private int count;
        @serdeLikeList
        auto numbers() @property // uses `foreach`
        {
            return iota(count);
        }

        @serdeLikeList
        @serdeProxy!string // input element type of
        @serdeIgnoreOut
        Appender!(string[]) strings; //`put` method is used
    }

    assert(S(5).serializeJson == `{"numbers":[0,1,2,3,4]}`);
    assert(`{"strings":["a","b"]}`.deserializeJson!S.strings.data == ["a","b"]);
}

///
version(none)
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;

    static struct M
    {
        private int sum;

        // opApply is used for serialization
        int opApply(int delegate(in char[] key, int val) pure dg) pure
        {
            if(auto r = dg("a", 1)) return r;
            if(auto r = dg("b", 2)) return r;
            if(auto r = dg("c", 3)) return r;
            return 0;
        }

        // opIndexAssign for deserialization
        void opIndexAssign(int val, string key) pure
        {
            sum += val;
        }
    }

    static struct S
    {
        @serdeLikeStruct
        @serdeProxy!int
        M obj;
    }

    assert(S.init.serializeJson == `{"obj":{"a":1,"b":2,"c":3}}`);
    assert(`{"obj":{"a":1,"b":2,"c":9}}`.deserializeJson!S.obj.sum == 12);
}

///
unittest
{
    import mir.ion.ser.json;
    import mir.ion.deser.json;
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
unittest
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

    import mir.ion.ser.json: serializeJson;
    import mir.ion.deser.json: deserializeJson;

    auto description = toto.serializeJson!Toto;
    assert(description == q{{"a":[[0,1,2],[3,4,5]],"b":[5,5]}});
    assert(toto == description.deserializeJson!Toto);
}

///
@safe pure @nogc
unittest
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

    import mir.ion.ser.json: serializeJson;
    import mir.ion.deser.json: deserializeJson;
    import mir.appender: ScopedBuffer;

    ScopedBuffer!char buffer;
    serializeJson(buffer, toto);
    auto description = buffer.data;
    assert(description == q{{"a":[[0,1,2],[3,4,5]],"b":[5,5]}});
    assert(toto == description.deserializeJson!Toto);
}
