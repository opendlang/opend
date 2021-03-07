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
