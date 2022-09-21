/++
$(H1 Mutable YAML value)

This module contains a single alias definition and doesn't provide YAML serialization API.

See_also: YAML libraries $(MIR_PACKAGE mir-ion) and $(MIR_PACKAGE asdf);

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
Authors: Ilia Ki 
Macros:
+/
module mir.algebraic_alias.yaml;
import mir.serde: serdeLikeStruct;

import mir.algebraic:
    algVerbose,
    algMeta,
    algTransp,
    Algebraic,
    This;

import mir.exception: MirException;

///
public import mir.annotated: Annotated;
///
public import mir.lob: Blob;
///
public import mir.timestamp: Timestamp;
///
public import mir.parse: ParsePosition;

private alias AliasSeq(T...) = T;

///Scalar styles.
enum YamlScalarStyle
{
    /// Invalid (uninitialized) style
    none,
    /// `|` (Literal block style)
    literal,
    /// `>` (Folded block style)
    folded,
    /// Plain scalar
    plain,
    /// Single quoted scalar
    singleQuoted,
    /// Double quoted scalar
    doubleQuoted
}

///Collection styles.
enum YamlCollectionStyle
{
    /// Invalid (uninitialized) style
    none,
    /// Block style.
    block,
    /// Flow style.
    flow
}

/++
Definition union for $(LREF YamlAlgebraic).
+/
union Yaml_
{
    ///
    typeof(null) null_;
    ///
    bool boolean;
    ///
    long integer;
    ///
    double float_;
    ///
    immutable(char)[] string;
    ///
    Blob blob;
    ///
    Timestamp timestamp;
    /// Self alias in array.
    This[] array;
    /// Self alias in $(MREF mir,string_map).
    YamlMap object;
    /// Self alias in $(MREF mir,annotated).
    Annotated!This annotated;

@algMeta:
    ///
    immutable(char)[] tag;
@algTransp:
    ///
    YamlCollectionStyle collectionStyle;
    ///
    YamlScalarStyle scalarStyle;
    ///
    @algVerbose ParsePosition startMark;
}

/++
YAML tagged algebraic alias.

The example below shows only the basic features. Advanced API to work with algebraic types can be found at $(GMREF mir-core, mir,algebraic).
See also $(MREF mir,string_map) - ordered string-value associative array.
+/
alias YamlAlgebraic = Algebraic!Yaml_;

/++
YAML map representation.

The implementation preserves order and allows duplicated keys.
+/
@serdeLikeStruct
struct YamlMap
{
    /++
    +/
    YamlPair[] pairs;

    ///
    this(YamlPair[] pairs) @safe pure nothrow @nogc
    {
        this.pairs = pairs;
    }

    size_t length() scope const @property @safe pure nothrow @nogc
    {
        return pairs.length;
    }

    static foreach (V; AliasSeq!(YamlAlgebraic.AllowedTypes[1 .. $], YamlAlgebraic, int))
    {
        static foreach (K; AliasSeq!(YamlAlgebraic.AllowedTypes[1 .. $], YamlAlgebraic, int))
        ///
        this(K[] keys, V[] values) @safe pure nothrow
            in(keys.length == values.length)
        {
            import mir.ndslice.topology: zip, map;
            import mir.array.allocation: array;
            this.pairs = keys.zip(values).map!YamlPair.array;
        }

        ref YamlAlgebraic opIndexAssign(V value, string key) @safe pure return scope nothrow
        {
            if (auto valuePtr = key in this)
                return *valuePtr = value;
            pairs ~= YamlPair(key, value);
            return pairs[$ - 1].value;
        }

        ref YamlAlgebraic opIndexAssign(V value, YamlAlgebraic key) @safe pure return scope nothrow
        {
            if (auto valuePtr = key in this)
                return *valuePtr = value;
            pairs ~= YamlPair(key, value);
            return pairs[$ - 1].value;
        }
    }

    /++
    +/
    this(K, V)(K[V] associativeArray)
    {
        import mir.ndslice.topology: map;
        import mir.array.allocation: array;
        this.pairs = associativeArray
            .byKeyValue
            .map!(kv => YamlPair(kv.key, kv.value))
            .array;
    }

    /++
    Returns: the first value associated with the provided key.
    +/
    inout(YamlAlgebraic)* _opIn(scope string key) @safe pure nothrow @nogc inout return scope
    {
        foreach (ref pair; pairs)
            if (pair.key == key)
                return &pair.value;
        return null;
    }

    /// ditto
    inout(YamlAlgebraic)* _opIn(scope const YamlAlgebraic key) @safe pure nothrow @nogc inout return scope
    {
        foreach (ref pair; pairs)
            if (pair.key == key)
                return &pair.value;
        return null;
    }

    alias opBinaryRight(string op : "in") = _opIn;

    /++
    Returns: the first value associated with the provided key.
    +/
    ref inout(YamlAlgebraic) opIndex(scope string key) @safe pure inout return scope
    {
        if (auto valuePtr = key in this)
            return *valuePtr;
        throw new MirException("YamlMap: can't find key '", key, "'");
    }

    /// ditto
    ref inout(YamlAlgebraic) opIndex(scope const YamlAlgebraic key) @safe pure inout return scope
    {
        if (key._is!string)
            return this[key.get!string];
        if (auto valuePtr = key in this)
            return *valuePtr;
        import mir.format: stringBuf, getData;
        auto buf = stringBuf;
        key.toString(buf);
        throw new MirException("YamlMap: can't find key ", buf << getData);
    }

    bool opEquals(scope const typeof(this) rhs) scope const @safe pure nothrow @nogc
    {
        return pairs == rhs.pairs;
    }

    int opCmp(scope const typeof(this) rhs) scope const @safe pure nothrow @nogc
    {
        return __cmp(pairs, rhs.pairs);
    }

    ///
    auto byKeyValue() @trusted return scope pure nothrow @nogc
    {
        import mir.ndslice.slice: sliced;
        return pairs.sliced;
    }

    ///
    auto byKeyValue() const @trusted return scope pure nothrow @nogc
    {
        import mir.ndslice.slice: sliced;
        return pairs.sliced;
    }
}

///
version(mir_test)
unittest
{
    YamlMap map = ["a" : 1];
    assert(map["a"] == 1);
    map[1.YamlAlgebraic] = "a";
    map["a"] = 3;
    map["a"].get!long++;
    map["a"].get!"integer" += 3;
    assert(map["a"] == 7);
    assert(map[1.YamlAlgebraic] == "a");
}

/++
+/
struct YamlPair
{
    ///
    YamlAlgebraic key;
    ///
    YamlAlgebraic value;

    static foreach (K; AliasSeq!(YamlAlgebraic.AllowedTypes, YamlAlgebraic, int))
    static foreach (V; AliasSeq!(YamlAlgebraic.AllowedTypes, YamlAlgebraic, int))
    ///
    this(K key, V value) @safe pure nothrow @nogc
    {
        static if (is(K == YamlAlgebraic))
            this.key = key;
        else
            this.key.__ctor(key);
        static if (is(V == YamlAlgebraic))
            this.value = value;
        else
            this.value.__ctor(value);
    }

    ///
    int opCmp(ref scope const typeof(this) rhs) scope const @safe pure nothrow @nogc
    {
        if (auto d = key.opCmp(rhs.key))
            return d;
        return value.opCmp(rhs.value);
    }

    ///
    int opCmp(scope const typeof(this) rhs) scope const @safe pure nothrow @nogc
    {
        return this.opCmp(rhs);
    }
}

///
version(mir_test)
unittest
{
    import mir.ndslice.topology: map;
    import mir.array.allocation: array;

    YamlAlgebraic value;

    // Default
    assert(value.isNull);
    assert(value.kind == YamlAlgebraic.Kind.null_);

    // Boolean
    value = true;

    assert(!value.isNull);
    assert(value == true);
    assert(value.kind == YamlAlgebraic.Kind.boolean);
    assert(value.boolean == true);
    assert(value.get!bool == true);
    assert(value.get!(YamlAlgebraic.Kind.boolean) == true);

    // Null
    value = null;
    assert(value.isNull);
    assert(value == null);
    assert(value.kind == YamlAlgebraic.Kind.null_);
    assert(value.null_ == null);
    assert(value.get!(typeof(null)) == null);
    assert(value.get!(YamlAlgebraic.Kind.null_) == null);

    // String
    value = "s";
    assert(value.kind == YamlAlgebraic.Kind.string);
    assert(value == "s");
    assert(value.string == "s");
    assert(value.get!string == "s");
    assert(value.get!(YamlAlgebraic.Kind.string) == "s");

    // Integer
    value = 4;
    assert(value.kind == YamlAlgebraic.Kind.integer);
    assert(value == 4);
    assert(value != 4.0);
    assert(value.integer == 4);

    // Float
    value = 3.0;
    assert(value.kind == YamlAlgebraic.Kind.float_);
    assert(value != 3);
    assert(value == 3.0);
    assert(value.float_ == 3.0);
    assert(value.get!double == 3.0);
    assert(value.get!(YamlAlgebraic.Kind.float_) == 3.0);

    // Array
    YamlAlgebraic[] arr = [0, 1, 2, 3, 4].map!YamlAlgebraic.array;

    value = arr;
    assert(value.kind == YamlAlgebraic.Kind.array);
    assert(value == arr);
    assert(value.array[3] == 3);

    // Object
    value = [1 : "a"].YamlAlgebraic;
    assert(value.kind == YamlAlgebraic.Kind.object);
    assert(value.object.pairs == [YamlPair(1, "a")]);
    assert(value.object[1.YamlAlgebraic] == "a");

    assert(value == value);
    assert(value <= value);
    assert(value >= value);
}
