/++
$(H4 High level serialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ion.ser;

import mir.conv;
import mir.ion.deser;
import mir.ion.deser.low_level: isNullable;
import mir.ion.internal.basic_types;
import mir.ion.type_code;
import mir.reflection;
import mir.reflection: isSomeStruct;
import std.meta;
import std.traits;

public import mir.serde;

/// `null` value serialization
void serializeValue(S)(ref S serializer, typeof(null))
{
    serializer.putValue(null);
}

///
unittest
{
    import mir.ion.ser.json: serializeJson;
    assert(serializeJson(null) == `null`, serializeJson(null));
}

/// Number serialization
void serializeValue(S, V)(ref S serializer, auto ref const V value)
    if (isNumeric!V && !is(V == enum))
{
    serializer.putValue(value);
}

///
unittest
{
    import mir.ion.ser.json: serializeJson;

    assert(serializeJson(2.40f) == `2.4`);
    assert(serializeJson(float.nan) == `"nan"`);
    assert(serializeJson(float.infinity) == `"+inf"`);
    assert(serializeJson(-float.infinity) == `"-inf"`);
}

/// Boolean serialization
void serializeValue(S, V)(ref S serializer, const V value)
    if (is(V == bool) && !is(V == enum))
{
    serializer.putValue(value);
}

/// Char serialization
void serializeValue(S, V : char)(ref S serializer, const V value)
    if (is(V == char) && !is(V == enum))
{
    char[1] v = value;
    serializer.putValue(v[]);
}

///
unittest
{
    import mir.ion.ser.json: serializeJson;
    assert(serializeJson(true) == `true`);
}

/// Enum serialization
void serializeValue(S, V)(ref S serializer, in V value)
    if(is(V == enum))
{
    static if (hasUDA!(V, serdeProxy))
    {
        serializer.serializeValue(value.to!(serdeGetProxy!V));
    }
    else
    {
        serializer.putValue(serdeGetKeyOut(value));
    }
}

///
unittest
{
    import mir.ion.ser.json: serializeJson;
    enum Key { @serdeKeys("FOO", "foo") foo }
    assert(serializeJson(Key.foo) == `"FOO"`);
}

/// String serialization
void serializeValue(S)(ref S serializer, scope const(char)[] value)
{
    if(value is null)
    {
        serializer.putNull(IonTypeCode.string);
        return;
    }
    serializer.putValue(value);
}

///
unittest
{
    import mir.ion.ser.json: serializeJson;
    assert(serializeJson("\t \" \\") == `"\t \" \\"`, serializeJson("\t \" \\"));
}

/// Array serialization
void serializeValue(S, T)(ref S serializer, T[] value)
    if(!isSomeChar!T)
{
    if(value is null)
    {
        serializer.putNull(IonTypeCode.list);
        return;
    }
    auto state = serializer.listBegin();
    foreach (ref elem; value)
    {
        serializer.elemBegin;
        serializer.serializeValue(elem);
    }
    serializer.listEnd(state);
}

/// Input range serialization
void serializeValue(S, R)(ref S serializer, R value)
    if (isIterable!R &&
        !isSomeChar!(ForeachType!R) &&
        !isDynamicArray!R &&
        !isNullable!R)
{
    auto state = serializer.listBegin();
    foreach (ref elem; value)
    {
        serializer.elemBegin;
        serializer.serializeValue(elem);
    }
    serializer.listEnd(state);
}

/// input range serialization
unittest
{
    import std.algorithm : filter;

    struct Foo
    {
        int i;
    }

    auto ar = [Foo(1), Foo(3), Foo(4), Foo(17)];

    auto filtered1 = ar.filter!"a.i & 1";
    auto filtered2 = ar.filter!"!(a.i & 1)";

    import mir.ion.ser.json: serializeJson;
    assert(serializeJson(filtered1) == `[{"i":1},{"i":3},{"i":17}]`);
    assert(serializeJson(filtered2) == `[{"i":4}]`);
}

///
unittest
{
    import mir.ion.ser.json: serializeJson;
    uint[2] ar = [1, 2];
    assert(serializeJson(ar) == `[1,2]`);
    assert(serializeJson(ar[]) == `[1,2]`);
    assert(serializeJson(ar[0 .. 0]) == `[]`);
    assert(serializeJson((uint[]).init) == `null`);
}

/// String-value associative array serialization
void serializeValue(S, T)(ref S serializer, auto ref T[string] value)
{
    if(value is null)
    {
        serializer.putNull(IonTypeCode.struct_);
        return;
    }
    auto state = serializer.structBegin();
    foreach (key, ref val; value)
    {
        serializer.putKey(key);
        serializer.serializeValue(val);
    }
    serializer.structEnd(state);
}

///
unittest
{
    import mir.ion.ser.json: serializeJson;
    uint[string] ar = ["a" : 1];
    assert(serializeJson(ar) == `{"a":1}`);
    ar.remove("a");
    assert(serializeJson(ar) == `{}`);
    assert(serializeJson((uint[string]).init) == `null`);
}

/// Enumeration-value associative array serialization
void serializeValue(S, V : const T[K], T, K)(ref S serializer, V value)
    if(is(K == enum))
{
    if(value is null)
    {
        serializer.putNull(IonTypeCode.struct_);
        return;
    }
    auto state = serializer.structBegin();
    foreach (key, ref val; value)
    {
        serializer.putKey(serdeGetKeyOut(key));
        serializer.putValue(val);
    }
    serializer.structEnd(state);
}

///
unittest
{
    import mir.ion.ser.json: serializeJson;
    enum E { a, b }
    uint[E] ar = [E.a : 1];
    assert(serializeJson(ar) == `{"a":1}`);
    ar.remove(E.a);
    assert(serializeJson(ar) == `{}`);
    assert(serializeJson((uint[string]).init) == `null`);
}

/// integral typed value associative array serialization
void serializeValue(S,  V : const T[K], T, K)(ref S serializer, V value)
    if (isIntegral!K && !is(K == enum))
{
    if(value is null)
    {
        serializer.putNull(IonTypeCode.struct_);
        return;
    }
    auto state = serializer.structBegin();
    foreach (key, ref val; value)
    {
        import mir.format: print;
        import mir.small_string : SmallString;
        SmallString!32 buffer;
        print(buffer, key);
        serializer.putKey(buffer[]);
        .serializeValue(serializer, val);
    }
    serializer.structEnd(state);
}

///
unittest
{
    import mir.ion.ser.json: serializeJson;
    uint[short] ar = [256 : 1];
    assert(serializeJson(ar) == `{"256":1}`);
    ar.remove(256);
    assert(serializeJson(ar) == `{}`);
    assert(serializeJson((uint[string]).init) == `null`);
    // assert(deserializeJson!(uint[short])(`{"256":1}`) == cast(uint[short]) [256 : 1]);
}


private IonTypeCode nullTypeCodeOf(T)()
{
    import mir.algebraic: isVariant, visit;
    import mir.serde: serdeGetFinalProxy;

    IonTypeCode code;

    static if (is(T == bool))
        code = IonTypeCode.bool_;
    else
    static if (isUnsigned!T)
        code = IonTypeCode.uInt;
    else
    static if (isIntegral!T || isBigInt!T)
        code = IonTypeCode.nInt;
    else
    static if (isFloatingPoint!T)
        code = IonTypeCode.float_;
    else
    static if (isDecimal!T)
        code = IonTypeCode.decimal;
    else
    static if (isClob!T)
        code = IonTypeCode.clob;
    else
    static if (isBlob!T)
        code = IonTypeCode.blob;
    else
    static if (isSomeString!T)
        code = IonTypeCode.string;
    else
    static if (!isVariant!T && isSomeStruct!T)
    {
        static if (hasUDA!(T, serdeProxy))
            code = .nullTypeCodeOf!(serdeGetFinalProxy!T);
        else
        static if (isIterable!T)
            code = IonTypeCode.list;
        else
            code = IonTypeCode.struct_;
    }
    else
    static if (isIterable!T)
        code = IonTypeCode.list;

    return code;
}

unittest
{
    static assert(nullTypeCodeOf!long == IonTypeCode.nInt);
}

private void serializeAnnotatedValue(S, V)(ref S serializer, auto ref V value, size_t annotationsState, size_t wrapperState)
{
    import mir.algebraic: isVariant;
    static if (serdeGetAnnotationMembersOut!V.length)
    {
        static foreach (annotationMember; serdeGetAnnotationMembersOut!V)
        {
            serializer.putAnnotation(__traits(getMember, value, annotationMember)[]);
        }
    }

    static if (isAlgebraicAliasThis!V)
    {
        serializeAnnotatedValue(serializer, __traits(getMember, value, __traits(getAliasThis, V)), annotationsState, wrapperState);
    }
    else
    static if (isVariant!V)
    {
        import mir.algebraic: visit;
        value.visit!(
            (auto ref v) {
                alias A = typeof(v);
                static if (serdeIsComplexVariant!V && serdeHasAlgebraicAnnotation!A)
                {
                    serializer.putCompiletimeAnnotation!(serdeGetAlgebraicAnnotation!A);
                }
                serializeAnnotatedValue(serializer, v, annotationsState, wrapperState);
            }
        );
    }
    else
    {
        serializer.annotationsEnd(annotationsState);
        static if (serdeGetAnnotationMembersOut!V.length)
            serializeValueImpl(serializer, value);
        else
            serializeValue(serializer, value);
        serializer.annotationWrapperEnd(wrapperState);
    }
}

/// Struct and class type serialization
void serializeValueImpl(S, V)(ref S serializer, auto ref V value)
    if (isSomeStruct!V && (!isIterable!V || hasUDA!(V, serdeProxy)))
{
    import mir.algebraic;
    auto state = serializer.structBegin();

    foreach(member; aliasSeqOf!(SerializableMembers!V))
    {{
        enum key = serdeGetKeyOut!(__traits(getMember, value, member));

        static if (key !is null)
        {
            static if (hasUDA!(__traits(getMember, value, member), serdeIgnoreDefault))
            {
                if (__traits(getMember, value, member) == __traits(getMember, V.init, member))
                    continue;
            }
            
            static if(hasUDA!(__traits(getMember, value, member), serdeIgnoreOutIf))
            {
                alias pred = serdeGetIgnoreOutIf!(__traits(getMember, value, member));
                if (pred(__traits(getMember, value, member)))
                    continue;
            }
            static if(hasUDA!(__traits(getMember, value, member), serdeTransformOut))
            {
                alias f = serdeGetTransformOut!(__traits(getMember, value, member));
                auto val = f(__traits(getMember, value, member));
            }
            else
            {
                auto val = __traits(getMember, value, member);
            }

            static if (__traits(hasMember, S, "putCompiletimeKey"))
            {
                serializer.putCompiletimeKey!key;
            }
            else
            {
                serializer.putKey(key);
            }

            static if(hasUDA!(__traits(getMember, value, member), serdeLikeList))
            {
                alias V = typeof(val);
                static if(is(V == interface) || is(V == class) || is(V : E[], E))
                {
                    if(val is null)
                    {
                        serializer.putNull(nullTypeCodeOf!V);
                        continue;
                    }
                }
                auto valState = serializer.listBegin();
                foreach (ref elem; val)
                {
                    serializer.elemBegin;
                    serializer.serializeValue(elem);
                }
                serializer.listEnd(valState);
            }
            else
            static if(hasUDA!(__traits(getMember, value, member), serdeLikeStruct))
            {
                static if(is(V == interface) || is(V == class) || is(V : E[T], E, T))
                {
                    if(val is null)
                    {
                        serializer.putNull(nullTypeCodeOf!V);
                        continue F;
                    }
                }
                auto valState = serializer.structBegin();
                foreach (key, elem; val)
                {
                    serializer.putKey(key);
                    serializer.serializeValue(elem);
                }
                serializer.structEnd(valState);
            }
            else
            static if(hasUDA!(__traits(getMember, value, member), serdeProxy))
            {
                serializer.serializeValue(val.to!(serdeGetProxy!(__traits(getMember, value, member))));
            }
            else
            {
                serializer.serializeValue(val);
            }
        }
    }}
    static if(__traits(hasMember, V, "finalizeSerialization"))
    {
        value.finalizeSerialization(serializer);
    }

    serializer.structEnd(state);
}

/// Struct and class type serialization
void serializeValue(S, V)(ref S serializer, auto ref V value)
    if (isSomeStruct!V && (!isIterable!V || hasUDA!(V, serdeProxy)))
{
    import mir.algebraic: Algebraic;

    static if(is(V == class) || is(V == interface))
    {
        if(value is null)
        {
            serializer.putNull(nullTypeCodeOf!V);
            return;
        }
    }

    static if (isBigInt!V || isDecimal!V || isTimestamp!V || isBlob!V || isClob!V)
    {
        serializer.putValue(value);
        return;
    }
    else
    static if (hasUDA!(V, serdeProxy))
    {{
        serializeValue(serializer, value.to!(serdeGetProxy!V));
        return;
    }}
    else
    static if(__traits(hasMember, V, "serialize"))
    {
        value.serialize(serializer);
        return;
    }
    else
    static if (serdeGetAnnotationMembersOut!V.length)
    {
        auto wrapperState = serializer.annotationWrapperBegin;
        auto annotationsState = serializer.annotationsBegin;
        serializeAnnotatedValue(serializer, value, annotationsState, wrapperState);
        return;
    }
    else
    static if (is(Unqual!V == Algebraic!TypeSet, TypeSet...))
    {
        import mir.algebraic: visit, isNullable;
        static if (serdeIsComplexVariant!V)
        {
            value.visit!(
                (auto ref v) {
                    alias A = typeof(v);
                    static if (serdeHasAlgebraicAnnotation!A)
                    {
                        auto wrapperState = serializer.annotationWrapperBegin;
                        auto annotationsState = serializer.annotationsBegin;
                        serializer.putCompiletimeAnnotation!(serdeGetAlgebraicAnnotation!A);
                        serializeAnnotatedValue(serializer, v, annotationsState, wrapperState);
                    }
                    else
                    {
                        serializeValue(serializer, v);
                    }
                }
            );
        }
        else
        static if (isNullable!V && V.AllowedTypes.length > 1)
        {
            value.visit!(
                (typeof(null)) => serializer.putNull(nullTypeCodeOf!(V.AllowedTypes[1])),
                (auto ref v) => .serializeValue(serializer, v)
            );
        }
        else
        {
            value.visit!(
                (auto ref v) => .serializeValue(serializer, v)
            );
        }
        return;
    }
    else
    static if (isNullable!V)
    {
        if(value.isNull)
        {
            serializer.putNull(nullTypeCodeOf!(typeof(value.get())));
            return;
        }
        serializeValue(serializer, value.get);
        return;
    }
    else
    {
        serializeValueImpl(serializer, value);
        return;
    }
}

/// Mir types
unittest
{
    import mir.bignum.integer;
    import mir.date;
    import mir.ion.ser.json: serializeJson;
    import mir.ion.ser.text: serializeText;
    assert(Date(2021, 4, 24).serializeJson == `"2021-04-24"`);
    assert(BigInt!2(123).serializeJson == `123`);
    assert(Date(2021, 4, 24).serializeText == `2021-04-24`);
    assert(BigInt!2(123).serializeText == `123`);
}

/// Alias this support
unittest
{
    struct S
    {
        int u;
    }

    struct C
    {
        int b;
        S s;
        alias s this; 
    }

    import mir.ion.ser.json: serializeJson;
    assert(C(4, S(3)).serializeJson == `{"u":3,"b":4}`);
}

/// Custom `serialize`
unittest
{
    struct S
    {
        void serialize(S)(ref S serializer) const
        {
            auto state = serializer.structBegin;
            serializer.putKey("foo");
            serializer.putValue("bar");
            serializer.structEnd(state);
        }
    }

    import mir.ion.ser.json: serializeJson;
    assert(serializeJson(S()) == `{"foo":"bar"}`);
}

/// Nullable type serialization
unittest
{
    import mir.ion.ser.json: serializeJson;
    import mir.algebraic: Nullable;

    struct Nested
    {
        float f;
    }

    struct T
    {
        string str;
        Nullable!Nested nested;
    }

    T t;
    assert(t.serializeJson == `{"str":null,"nested":null}`, t.serializeJson);
    t.str = "txt";
    t.nested = Nested(123);
    assert(t.serializeJson == `{"str":"txt","nested":{"f":123.0}}`);
}

///
unittest
{
    import mir.algebraic;
    import mir.small_string;

    @serdeAlgebraicAnnotation("$a")
    static struct B
    {
        double number;
    }

    static struct A
    {
        @serdeAnnotation
        SmallString!32 id1;

        @serdeAnnotation
        SmallString!32 id2;

        // Alias this is transparent for members and can catch algebraic annotation
        alias c this;
        B c;

        string s;
    }


    static assert(serdeHasAlgebraicAnnotation!B);
    static assert(serdeGetAlgebraicAnnotation!B == "$a");
    static assert(serdeHasAlgebraicAnnotation!A);
    static assert(serdeGetAlgebraicAnnotation!A == "$a");

    @serdeAlgebraicAnnotation("$c")
    static struct C
    {
    }

    @serdeAlgebraicAnnotation("$S")
    static struct S
    {
        @serdeAnnotation
        string sid;

        alias Data = Nullable!(A, C, int);

        alias data this;

        Data data;
    }

    Nullable!S value = S("LIBOR", S.Data(A(SmallString!32("Rate"), SmallString!32("USD"))));

    import mir.ion.conv: ion2text;
    import mir.ion.ser.ion: serializeIon;
    import mir.ion.ser.text: serializeText;
    static immutable text = `LIBOR::$a::Rate::USD::{number:nan,s:null.string}`;
    assert(value.serializeText == text);
    auto binary = value.serializeIon;
    assert(binary.ion2text == text);
    import mir.ion.deser.ion: deserializeIon;
    assert(binary.deserializeIon!S.serializeText == text);
}
