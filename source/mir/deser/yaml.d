/++
$(H4 High level YAML deserialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.deser.yaml;

import std.traits: isMutable;

/++
Deserialize YAML document to a scpecified type.
Params:
    T = type of the value
    text = UTF-8 text (without BOM)
    fileNam = (optional) file name for better error information
Returns:
    value of type `T`
+/
T deserializeYaml(T)(scope const(char)[] text, string fileName = "<unknown>")
    if (isMutable!T)
{
    auto values = deserializeYamlValues!T(text, fileName);

    if (values.length != 1)
    {
        import mir.serde: SerdeMirException;
        throw new SerdeMirException(
            "Expected single YAML document in file", fileName,
            ", got ", values.length, " documents");
    }

    import core.lifetime: move;
    return move(values[0]);
}

///
@safe
unittest
{
    import mir.test: should;

    static struct S
    {
        string foo;
        uint bar;
    }

    `{foo: str, bar: 4}`.deserializeYaml!S.should == S("str", 4);
}

/// Tags (annotations) support
@safe
unittest
{
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

    `!S {foo: str, bar: 4}`.deserializeYaml!V.should == V("str", 4);

    // Multiple Ion annotations represented in a single tag using `::`.
    `!<rgb::dark_blue> {r: 23, g: 25, b: 55}`.deserializeYaml!V.should == V(RGB("dark_blue", 23, 25, 55));
}

/// YAML-specific deserialization
@safe pure
unittest
{
    import mir.algebraic_alias.yaml: YamlAlgebraic, YamlMap;
    import mir.test: should;

    auto yaml = `{foo: str, bar: 4}`;

    auto value = yaml.deserializeYaml!YamlAlgebraic("test.yml");
    value.object["bar"].should == 4;
    value.tag.should == `tag:yaml.org,2002:map`;
    value.startMark.file.should == "test.yml";


    // `YamlMap`, `YamlAlgebraic[]`, and `Annotated!YamlAlgebraic`
    // are YAML specific types as well
    auto object = yaml.deserializeYaml!YamlMap("test.yml");
    object["bar"].should == 4;
    object["bar"].tag.should == `tag:yaml.org,2002:int`;

    assert(value == object);
}

/// YAML-user-specific deserialization
@safe pure
unittest
{
    import mir.test: should;
    import mir.algebraic_alias.yaml: YamlAlgebraic;

    static struct MyYamlStruct
    {
        YamlAlgebraic node;

        this(YamlAlgebraic node) @safe pure
        {
            this.node = node;
        }
    }

    auto s = `{foo: str, bar: 4}`.deserializeYaml!MyYamlStruct("test.yml");
    s.node.object["bar"].should == 4;
    s.node.tag.should == `tag:yaml.org,2002:map`;
}

/++
Deserialize YAML documents to an array of scpecified type.
Params:
    T = type of the value
    text = UTF-8 text (without BOM)
    fileNam = (optional) file name for better error information
Returns:
    array of type `T`
+/
// pure
T[] deserializeYamlValues(T)(scope const(char)[] text, string fileName = "<unknown>")
    if (isMutable!T)
{
    import mir.algebraic_alias.yaml: YamlAlgebraic;
    import mir.array.allocation: array;
    import mir.ndslice.topology: map;
    import std.meta: staticIndexOf;

    static if (is(T == YamlAlgebraic))
    {
        import mir.yaml.internal.loader: Loader;
        pragma(inline, false)
        return text.Loader(fileName).loadAll;
    }
    else
    static if (staticIndexOf!(T, YamlAlgebraic.AllowedTypes) >= 0)
    {
        return text.deserializeYamlValues!YamlAlgebraic(fileName)
            .map!((ref value) => value.get!T).array;
    }
    else
    static if (is(typeof(YamlAlgebraic[].init.map!T.array())))
    {
        return text.deserializeYamlValues!YamlAlgebraic(fileName)
            .map!T.array;
    }
    else
    {
        import mir.ion.conv: serde;
        import mir.serde: SerdeTarget;
        return text.deserializeYamlValues!YamlAlgebraic(fileName)
            .map!((scope ref const value) => serde!T(value, SerdeTarget.yaml)).array;
    }
}
