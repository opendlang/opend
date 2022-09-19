/++
$(H4 High level (text) Ion serialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ser.text;

public import mir.serde;

private bool isIdentifier(scope const char[] str) @trusted pure nothrow @nogc @property
{
    import mir.algorithm.iteration: all;
    return str.length
        && (str[0] < '0' || str[0] > '9')
        && str != "nan"
        && str != "null"
        && str != "true"
        && str != "false"
        && str.all!(
            a => a >= 'a' && a <= 'z'
                || a >= 'A' && a <= 'Z'
                || a >= '0' && a <= '9'
                || a == '_'
                || a == '$');
}

/++
Ion serialization back-end
+/
struct TextSerializer(string sep, Appender)
{
    import mir.bignum.decimal: Decimal;
    import mir.bignum.integer: BigInt;
    import mir.ion.type_code;
    import mir.lob;
    import mir.timestamp;
    import std.traits: isNumeric;

    /++
    Ion string buffer
    +/
    Appender* appender;

    /// Mutable value used to choose format specidied or user-defined serialization specializations
    int serdeTarget = SerdeTarget.ion;

    private size_t state;

    static if(sep.length)
    {
        private uint deep;

        private void putSpace()
        {
            for(auto k = deep; k; k--)
            {
                static if(sep.length == 1)
                {
                    appender.put(sep[0]);
                }
                else
                {
                    appender.put(sep);
                }
            }
        }
    }

    private void pushState(size_t state)
    {
        this.state = state;
    }

    private size_t popState()
    {
        auto ret = state;
        state = 0;
        return ret;
    }

    private void incState()
    {
        if(state++)
        {
            static if(sep.length)
            {
                appender.put(",\n");
            }
            else
            {
                appender.put(',');
            }
        }
        else
        {
            static if(sep.length)
            {
                appender.put('\n');
            }
        }
    }

    private void sexpIncState()
    {
        if(state++)
        {
            static if(sep.length)
            {
                appender.put('\n');
            }
            else
            {
                appender.put(' ');
            }
        }
        else
        {
            static if(sep.length)
            {
                appender.put('\n');
            }
        }
    }

    private void putEscapedKey(scope const char[] key)
    {
        incState;
        static if(sep.length)
        {
            putSpace;
        }
        appender.put('\'');
        appender.put(key);
        static if(sep.length)
        {
            appender.put(`': `);
        }
        else
        {
            appender.put(`':`);
        }
    }

    private void putIdentifierKey(scope const char[] key)
    {
        incState;
        static if(sep.length)
        {
            putSpace;
        }
        appender.put(key);
        static if(sep.length)
        {
            appender.put(`: `);
        }
        else
        {
            appender.put(':');
        }
    }

    private void putCompiletimeSymbol(string str)()
    {
        static if (str.isIdentifier)
        {
            appender.put(str);
        }
        else
        {
            appender.put('\'');
            static if (str.any!(c => c == '"' || c == '\\' || c < ' '))
            {
                import str.array: appender;
                enum estr = () {
                    auto app = appender!string;
                    printEscaped!(char, EscapeFormat.ionSymbol)(app, str);
                    return app.data;
                } ();
                appender.put(estr);
            }
            else
            {
                appender.put(str);
            }
            appender.put('\'');
        }
    }

    ///
    size_t stringBegin()
    {
        appender.put('\"');
        return 0;
    }

    /++
    Puts string part. The implementation allows to split string unicode points.
    +/
    void putStringPart(scope const(char)[] value)
    {
        import mir.format: printEscaped, EscapeFormat;
        printEscaped!(char, EscapeFormat.ion)(appender, value);
    }

    ///
    void stringEnd(size_t)
    {
        appender.put('\"');
    }

    ///
    size_t structBegin(size_t length = size_t.max)
    {
        static if(sep.length)
        {
            deep++;
        }
        appender.put('{');
        return popState;
    }

    ///
    void structEnd(size_t state)
    {
        static if(sep.length)
        {
            deep--;
            if (this.state)
            {
                appender.put('\n');
                putSpace;
            }
        }
        appender.put('}');
        pushState(state);
    }

    ///
    size_t listBegin(size_t length = size_t.max)
    {
        static if(sep.length)
        {
            deep++;
        }
        appender.put('[');
        return popState;
    }

    ///
    void listEnd(size_t state)
    {
        static if(sep.length)
        {
            deep--;
            if (this.state)
            {
                appender.put('\n');
                putSpace;
            }
        }
        appender.put(']');
        pushState(state);
    }

    ///
    size_t sexpBegin(size_t length = size_t.max)
    {
        static if(sep.length)
        {
            deep++;
        }
        appender.put('(');
        return popState;
    }

    ///
    void sexpEnd(size_t state)
    {
        static if(sep.length)
        {
            deep--;
            if (this.state)
            {
                appender.put('\n');
                putSpace;
            }
        }
        appender.put(')');
        pushState(state);
    }

    ///
    void putAnnotation(scope const(char)[] annotation)
    {
        putSymbol(annotation);
        appender.put(`::`);
    }

    ///
    void putCompiletimeAnnotation(string annotation)()
    {
        putCompiletimeSymbol!annotation;
        appender.put(`::`);
    }

    ///
    size_t annotationsEnd(size_t state)
    {
        static if (sep.length)
            appender.put(' ');
        return state;
    }

    ///
    size_t annotationWrapperBegin()
    {
        return 0;
    }

    ///
    void annotationWrapperEnd(size_t, size_t)
    {
        static if (sep.length)
            appender.put(' ');
    }

    ///
    void nextTopLevelValue()
    {
        appender.put('\n');
    }

    ///
    void putCompiletimeKey(string key)()
    {
        import mir.algorithm.iteration: any;
        incState;
        static if(sep.length)
        {
            putSpace;
        }

        putCompiletimeSymbol!key;

        static if(sep.length)
        {
            appender.put(`: `);
        }
        else
        {
            appender.put(':');
        }
    }

    ///
    void putSymbol(scope const char[] key)
    {
        import mir.format: printEscaped, EscapeFormat;

        if (key.isIdentifier)
        {
            appender.put(key);
            return;
        }

        appender.put('\'');
        printEscaped!(char, EscapeFormat.ionSymbol)(appender, key);
        appender.put('\'');
    }

    ///
    void putKey(scope const char[] key)
    {
        import mir.format: printEscaped, EscapeFormat;

        incState;
        static if(sep.length)
        {
            putSpace;
        }

        putSymbol(key);

        static if(sep.length)
        {
            appender.put(`: `);
        }
        else
        {
            appender.put(':');
        }
    }

    ///
    void putValue(Num)(const Num num)
        if (isNumeric!Num && !is(Num == enum))
    {
        import mir.format: print;
        print(appender, num);
    }

    ///
    void putValue(size_t size)(auto ref const BigInt!size num)
    {
        num.toString(appender);
    }

    ///
    void putValue(size_t size)(auto ref const Decimal!size num)
    {
        import mir.format : NumericSpec;
        num.toString(appender, NumericSpec(NumericSpec.format.human, '\0', 'd'));
    }

    ///
    void putValue(typeof(null))
    {
        appender.put("null");
    }

    /// ditto 
    void putNull(IonTypeCode code)
    {
        appender.put(code.nullStringOf);
    }

    ///
    void putValue(bool b)
    {
        appender.put(b ? "true" : "false");
    }

    ///
    void putValue(scope const char[] value)
    {
        auto state = stringBegin;
        putStringPart(value);
        stringEnd(state);
    }

    ///
    void putValue(scope Clob value)
    {
        import mir.format: printEscaped, EscapeFormat;

        static if(sep.length)
            appender.put(`{{ "`);
        else
            appender.put(`{{"`);

        printEscaped!(char, EscapeFormat.ionClob)(appender, value.data);

        static if(sep.length)
            appender.put(`" }}`);
        else
            appender.put(`"}}`);
    }

    ///
    void putValue(scope Blob value)
    {
        import mir.base64 : encodeBase64;
        static if(sep.length)
            appender.put("{{ ");
        else
            appender.put("{{");

        encodeBase64(value.data, appender);

        static if(sep.length)
            appender.put(" }}");
        else
            appender.put("}}");
    }

    ///
    void putValue(Timestamp value)
    {
        value.toISOExtString(appender);
    }

    ///
    void elemBegin()
    {
        incState;
        static if(sep.length)
        {
            putSpace;
        }
    }

    ///
    void sexpElemBegin()
    {
        sexpIncState;
        static if(sep.length)
        {
            putSpace;
        }
    }
}

/++
Ion serialization function.
+/
string serializeText(V)(auto ref V value, int serdeTarget = SerdeTarget.ion)
{
    return serializeTextPretty!""(value, serdeTarget);
}

///
unittest
{
    struct S
    {
        string foo;
        uint bar;
    }

    assert(serializeText(S("str", 4)) == `{foo:"str",bar:4}`, serializeText(S("str", 4)));
}

unittest
{
    import mir.ser.text: serializeText;
    import mir.format: stringBuf;
    import mir.small_string;

    SmallString!8 smll = SmallString!8("ciaociao");
    auto buffer = stringBuf;

    serializeText(buffer, smll);
    assert(buffer.data == `"ciaociao"`);
}

///
unittest
{
    import mir.serde: serdeIgnoreDefault;

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
    
    assert(Cake("Normal Cake").serializeText == `{name:"Normal Cake",slices:8,flavor:1.0}`);
    auto cake = Cake.init;
    cake.dec = Decor.init;
    assert(cake.serializeText == `{slices:8,flavor:1.0,dec:{candles:0,fluff:+inf}}`, cake.serializeText);
    assert(cake.dec.serializeText == `{candles:0,fluff:+inf}`);
    
    static struct A
    {
        @serdeIgnoreDefault
        string str = "Banana";
        int i = 1;
    }
    assert(A.init.serializeText == `{i:1}`);
    
    static struct S
    {
        @serdeIgnoreDefault
        A a;
    }
    assert(S.init.serializeText == `{}`);
    assert(S(A("Berry")).serializeText == `{a:{str:"Berry",i:1}}`);
    
    static struct D
    {
        S s;
    }
    assert(D.init.serializeText == `{s:{}}`);
    assert(D(S(A("Berry"))).serializeText == `{s:{a:{str:"Berry",i:1}}}`);
    assert(D(S(A(null, 0))).serializeText == `{s:{a:{str:null.string,i:0}}}`, D(S(A(null, 0))).serializeText);
    
    static struct F
    {
        D d;
    }
    assert(F.init.serializeText == `{d:{s:{}}}`);
}

///
unittest
{
    import mir.serde: serdeIgnoreIn;

    static struct S
    {
        @serdeIgnoreIn
        string s;
    }
    // assert(`{"s":"d"}`.deserializeText!S.s == null, `{"s":"d"}`.serializeText!S.s);
    assert(S("d").serializeText == `{s:"d"}`);
}

///
unittest
{
    import mir.deser.ion;

    static struct S
    {
        @serdeIgnoreOut
        string s;
    }
    // assert(`{s:"d"}`.serializeText!S.s == "d");
    assert(S("d").serializeText == `{}`);
}

///
unittest
{
    import mir.serde: serdeIgnoreOutIf;

    static struct S
    {
        @serdeIgnoreOutIf!`a < 0`
        int a;
    }

    assert(serializeText(S(3)) == `{a:3}`, serializeText(S(3)));
    assert(serializeText(S(-3)) == `{}`);
}

///
unittest
{
    import mir.rc.array;
    auto ar = rcarray!int(1, 2, 4);
    assert(ar.serializeText == "[1,2,4]");
}

///
unittest
{
    import mir.deser.ion;
    import std.range;
    import std.algorithm;
    import std.conv;

    static struct S
    {
        @serdeTransformIn!"a += 2"
        @serdeTransformOut!(a =>"str".repeat.take(a).joiner("_").to!string)
        int a;
    }

    assert(serializeText(S(5)) == `{a:"str_str_str_str_str"}`);
}

/++
Ion serialization function with pretty formatting.
+/
string serializeTextPretty(string sep = "\t", V)(auto ref V value, int serdeTarget = SerdeTarget.ion)
{
    import std.array: appender;
    import std.functional: forward;

    auto app = appender!(char[]);
    serializeTextPretty!sep(app, forward!value, serdeTarget);
    return (()@trusted => cast(string) app.data)();
}

///
version(mir_ion_test) unittest
{
    static struct S { int a; }
    assert(S(4).serializeTextPretty!"    " == "{\n    a: 4\n}");
}

/++
Ion serialization for custom outputt range.
+/
void serializeText(Appender, V)(scope ref Appender appender, auto ref V value, int serdeTarget = SerdeTarget.ion)
{
    return serializeTextPretty!""(appender, value, serdeTarget);
}

///
@safe pure nothrow @nogc
unittest
{
    import mir.format: stringBuf;
    auto buffer = stringBuf;
    static struct S { int a; }
    serializeText(buffer, S(4));
    assert(buffer.data == `{a:4}`);
}

/++
Ion serialization function with pretty formatting and custom output range.
+/
template serializeTextPretty(string sep = "\t")
{
    import std.range.primitives: isOutputRange; 
    ///
    void serializeTextPretty(Appender, V)(scope ref Appender appender, auto ref V value, int serdeTarget = SerdeTarget.ion)
        if (isOutputRange!(Appender, const(char)[]))
    {
        import mir.ser: serializeValue;
        auto serializer = textSerializer!sep((()@trusted => &appender)(), serdeTarget);
        serializeValue(serializer, value);
    }
}

///
// @safe pure nothrow @nogc
unittest
{
    import mir.format: stringBuf;
    auto buffer = stringBuf;
    static struct S { int a; }
    serializeTextPretty!"    "(buffer, S(4));
    assert(buffer.data == "{\n    a: 4\n}");
}

/++
Creates Ion serialization back-end.
Use `sep` equal to `"\t"` or `"    "` for pretty formatting.
+/
template textSerializer(string sep = "")
{
    ///
    auto textSerializer(Appender)(return Appender* appender, int serdeTarget = SerdeTarget.ion)
    {
        return TextSerializer!(sep, Appender)(appender, serdeTarget);
    }
}

///
@safe pure nothrow @nogc unittest
{
    import mir.format: stringBuf;
    import mir.bignum.integer;

    auto buffer = stringBuf;
    auto ser = textSerializer((()@trusted=>&buffer)());
    auto state0 = ser.structBegin;

        ser.putKey("null");
        ser.putValue(null);

        ser.putKey("array");
        auto state1 = ser.listBegin();
            ser.elemBegin; ser.putValue(null);
            ser.elemBegin; ser.putValue(123);
            ser.elemBegin; ser.putValue(12300000.123);
            ser.elemBegin; ser.putValue("\t");
            ser.elemBegin; ser.putValue("\r");
            ser.elemBegin; ser.putValue("\n");
            ser.elemBegin; ser.putValue(BigInt!2(1234567890));
        ser.listEnd(state1);

    ser.structEnd(state0);

    assert(buffer.data == `{'null':null,array:[null,123,1.2300000123e+7,"\t","\r","\n",1234567890]}`);
}

///
unittest
{
    import std.array;
    import mir.bignum.integer;

    auto app = appender!string;
    auto ser = textSerializer!"    "(&app);
    auto state0 = ser.structBegin;

        ser.putKey("null");
        ser.putValue(null);

        ser.putKey("array");
        auto state1 = ser.listBegin();
            ser.elemBegin; ser.putValue(null);
            ser.elemBegin; ser.putValue(123);
            ser.elemBegin; ser.putValue(12300000.123);
            ser.elemBegin; ser.putValue("\t");
            ser.elemBegin; ser.putValue("\r");
            ser.elemBegin; ser.putValue("\n");
            ser.elemBegin; ser.putValue(BigInt!2("1234567890"));
        ser.listEnd(state1);

    ser.structEnd(state0);

    assert(app.data ==
`{
    'null': null,
    array: [
        null,
        123,
        1.2300000123e+7,
        "\t",
        "\r",
        "\n",
        1234567890
    ]
}`, app.data);
}
