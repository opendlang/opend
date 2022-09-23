/++
$(H4 High level YAML serialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ser.yaml;

import mir.serde: SerdeTarget;
import mir.algebraic_alias.yaml: YamlAlgebraic;

/++
YAML Serialization Params
+/
struct YamlSerializationParams
{
    import mir.algebraic_alias.yaml: YamlScalarStyle, YamlCollectionStyle;

    /// Default style for scalar nodes. If style is $(D YamlScalarStyle.none), the _style is chosen automatically.
    YamlScalarStyle defaultScalarStyle;
    /// Default style for collection nodes. If style is $(D YamlCollectionStyle.none), the _style is chosen automatically.
    YamlCollectionStyle defaultCollectionStyle;
    /// Always explicitly write document start? Default is no explicit start.
    bool explicitStart;
    /// Always explicitly write document end? Default is no explicit end.
    bool explicitEnd;
    /// Preferred text width.
    uint textWidth = 80;
    /// Write scalars in canonical form?
    bool canonical;
    /// YAML version string. Default value is null.
    string yamlVersion;
}

/++
Ion serialization function.

Params:
    value = value to serializa
    params = (optional) serialization param
    serdeTarget = (optional) serialization target ID
Returns:
    UTF-8 YAML text
+/
@safe pure
string serializeYaml(V)(auto scope ref const V value, YamlSerializationParams params = YamlSerializationParams.init, int serdeTarget = SerdeTarget.yaml)
{
    static if (is(V == YamlAlgebraic))
    {
        alias node = value;
    }
    else
    static if (is(typeof(const YamlAlgebraic(value))))
    {
        scope node = const YamlAlgebraic(value);
    }
    else
    static if (is(typeof(cast(const YamlAlgebraic) value)))
    {
        scope node = cast(const YamlAlgebraic) value;
    }
    else
    {
        import mir.ion.conv: serde;
        auto node = serde!YamlAlgebraic(value, serdeTarget);
    }

    return serializeYamlValues((()@trusted=>(&node)[0 .. 1])(), params);
}

///
@safe pure
unittest
{
    import mir.test: should;

    static struct S
    {
        string foo;
        uint bar;
    }

    S("str", 4).serializeYaml.should ==
`{foo: str, bar: 4}
`;
}

/// Tags (annotations) support
@safe pure
unittest
{
    import mir.test: should;
    import mir.algebraic: Variant;
    import mir.serde: serdeAlgebraicAnnotation;

    import mir.test: should;
    import mir.algebraic: Variant;
    import mir.serde: serdeAlgebraicAnnotation, serdeAnnotation, serdeOptional;

    @serdeAlgebraicAnnotation("!S")
    static struct S
    {
        string foo;
        uint bar;
    }

    @serdeAlgebraicAnnotation("rgb")
    static struct RGB
    {
        @serdeAnnotation @serdeOptional
        string name;

        ubyte r, g, b;
    }

    alias V = Variant!(S, RGB);

    S("str", 4).serializeYaml.should == "{foo: str, bar: 4}\n";
    V("str", 4).serializeYaml.should == "!S {foo: str, bar: 4}\n";

    // Multiple Ion annotations represented in a single tag using `::`.
    V(RGB("dark_blue", 23, 25, 55)).serializeYaml.should ==
`!<rgb::dark_blue> {r: 23, g: 25, b: 55}
`;
}

/// YAML-specific serialization
@safe pure
unittest
{
    import mir.algebraic_alias.yaml: YamlAlgebraic, YamlCollectionStyle;
    import mir.test: should;

    auto value = YamlAlgebraic(["foo".YamlAlgebraic, 123.9.YamlAlgebraic, "bar".YamlAlgebraic]);

    value.serializeYaml.should == "[foo, 123.9, bar]\n";

    value.collectionStyle = YamlCollectionStyle.block;
    value.serializeYaml.should == "- foo\n- 123.9\n- bar\n";
}

/// User API for YAML-specific serialization
@safe pure
version(none)
unittest
{
    import mir.algebraic_alias.yaml: YamlAlgebraic;
    import mir.test: should;

    static struct MyYamlStruct
    {
        int b;

        // has to be scope const
        auto opCast(T : YamlAlgebraic)() scope const @safe pure
        {
            return b.YamlAlgebraic;
        }
    }

    MyYamlStruct(40).serializeYaml.should == "40\n";
}

/++
Params:
    nodes = Algebraic nodes (documents)
    params = (optional) serialization param
Returns:
    UTF-8 YAML text
See_Also:
    $(IONREF, conv, serde).
+/
@safe pure
string serializeYamlValues(scope const YamlAlgebraic[] nodes, YamlSerializationParams params = YamlSerializationParams.init)
{
    import mir.yaml.internal.dumper;
    import std.array: appender;

    auto app = appender!string;
    auto dumper = dumper(params);
    foreach (ref node; nodes)
        dumper.dump(app, node);
    return app.data;
}
