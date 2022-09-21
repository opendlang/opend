/++
$(H4 High level YAML serialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ser.yaml;

import mir.serde: SerdeTarget;

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
    /// Preferred text width.
    uint textWidth = 80;
    /// Write scalars in canonical form?
    bool canonical;
    /// Always explicitly write document start? Default is no explicit start.
    bool explicitStart = false;
    /// Always explicitly write document end? Default is no explicit end.
    bool explicitEnd = false;
    /// YAML version string. Default is `1.1`.
    string YamlVersion = "1.1";
}

/++
Ion serialization function.
+/
@safe pure
string serializeYaml(V)(auto scope ref const V value, YamlSerializationParams params = YamlSerializationParams.init, int serdeTarget = SerdeTarget.yaml)
{
    import mir.algebraic_alias.yaml: YamlAlgebraic;
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

    import mir.internal.yaml.dumper;
    import std.array: appender;

    auto app = appender!string;
    dumper(params).dump(app, node);
    return app.data;
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
`%YAML 1.1
--- {foo: str, bar: 4}
`;
}

/// Tags (annotations) support
@safe pure
unittest
{
    import mir.test: should;
    import mir.algebraic: Variant;
    import mir.serde: serdeAlgebraicAnnotation;

    @serdeAlgebraicAnnotation("!S")
    static struct S
    {
        string foo;
        uint bar;
    }

    auto s = S("str", 4);

    s.serializeYaml.should ==
`%YAML 1.1
--- {foo: str, bar: 4}
`;

    s.Variant!S.serializeYaml.should ==
`%YAML 1.1
--- !S {foo: str, bar: 4}
`;
}
