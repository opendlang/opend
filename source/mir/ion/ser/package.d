/++
$(H4 High level serialization API)

Macros:
IONREF = $(REF_ALTTEXT $(TT $2), $2, mir, ion, $1)$(NBSP)
+/
module mir.ion.ser;

import mir.bignum.decimal: Decimal;
import mir.bignum.integer: BigInt;
import mir.conv;
import mir.ion.deser;
import mir.ion.deser.low_level: isNullable;
import mir.reflection;
import std.meta;
import std.range.primitives;
import std.traits;

public import mir.serde;


private auto assumePure(T)(T t) @trusted
    // if (isFunctionPointer!T || isDelegate!T)
{
    import std.traits;
    enum attrs = (functionAttributes!T | FunctionAttribute.pure_) & ~FunctionAttribute.system;
    return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
}

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
    if ((isNumeric!V && !is(V == enum)) || is(V == BigInt!size0, size_t size0) || is(V == Decimal!size1, size_t size1))
{
    static if (isFloatingPoint!V)
    {
        import mir.math.common: fabs;
        import mir.math.ieee: signbit;

        if (value.fabs < value.infinity)
            serializer.putValue(value);
        else if (value != value)
            serializer.putValue(signbit(value) ? "-nan" : "nan");
        else if (value == V.infinity)
            serializer.putValue("inf");
        else if (value == -V.infinity)
            serializer.putValue("-inf");
    }
    else
        serializer.putValue(value);
}

///
unittest
{
    import mir.bignum.integer;
    import mir.ion.ser.json: serializeJson;

    assert(serializeJson(BigInt!2(123)) == `123`);
    assert(serializeJson(2.40f) == `2.4`);
    assert(serializeJson(float.nan) == `"nan"`);
    assert(serializeJson(float.infinity) == `"inf"`);
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
    auto v = cast(char[1])value;
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
void serializeValue(S)(ref S serializer, in char[] value)
{
    if(value is null)
    {
        serializer.putValue(null);
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
        serializer.putValue(null);
        return;
    }
    auto state = serializer.arrayBegin();
    foreach (ref elem; value)
    {
        serializer.elemBegin;
        serializer.serializeValue(elem);
    }
    serializer.arrayEnd(state);
}

/// Input range serialization
void serializeValue(S, R)(ref S serializer, R value)
    if ((isInputRange!R) &&
        !isSomeChar!(ElementType!R) &&
        !isDynamicArray!R &&
        !isNullable!R)
{
    auto state = serializer.arrayBegin();
    foreach (ref elem; value)
    {
        serializer.elemBegin;
        serializer.serializeValue(elem);
    }
    serializer.arrayEnd(state);
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
        serializer.putValue(null);
        return;
    }
    auto state = serializer.objectBegin();
    foreach (key, ref val; value)
    {
        serializer.putKey(key);
        serializer.serializeValue(val);
    }
    serializer.objectEnd(state);
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
        serializer.putValue(null);
        return;
    }
    auto state = serializer.objectBegin();
    foreach (key, ref val; value)
    {
        serializer.putKey(serdeGetKeyOut(key));
        serializer.putValue(val);
    }
    serializer.objectEnd(state);
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
    if((isIntegral!K) && !is(K == enum))
{
    if(value is null)
    {
        serializer.putValue(null);
        return;
    }
    auto state = serializer.objectBegin();
    foreach (key, ref val; value)
    {
        import mir.format: print;
        import mir.small_string : SmallString;
        SmallString!32 buffer;
        print(buffer, key);
        serializer.putKey(buffer[]);
        .serializeValue(serializer, val);
    }
    serializer.objectEnd(state);
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

/// Nullable type serialization
void serializeValue(S, N)(ref S serializer, auto ref N value)
    if (isNullable!N)
{
    if(value.isNull)
    {
        serializer.putValue(null);
        return;
    }
    serializer.serializeValue(value.get);
}

///
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

/// Struct and class type serialization
void serializeValue(S, V)(ref S serializer, auto ref V value)
    if (!isNullable!V && isAggregateType!V && !is(V == BigInt!size0, size_t size0) && !isInputRange!V)
{
    static if(is(V == class) || is(V == interface))
    {
        if(value is null)
        {
            serializer.putValue(null);
            return;
        }
    }

    static if (hasUDA!(V, serdeProxy))
    {{
        serializer.serializeValue(value.to!(serdeGetProxy!V));
        return;
    }}
    else
    static if(__traits(hasMember, V, "serialize"))
    {
        value.serialize(serializer);
    }
    else
    {
        auto state = serializer.objectBegin();
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

                static if (__traits(hasMember, S, "putCompileTimeKey"))
                {
                    serializer.putCompileTimeKey!key;
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
                            serializer.putValue(null);
                            continue;
                        }
                    }
                    auto valState = serializer.arrayBegin();
                    foreach (ref elem; val)
                    {
                        serializer.elemBegin;
                        serializer.serializeValue(elem);
                    }
                    serializer.arrayEnd(valState);
                }
                else
                static if(hasUDA!(__traits(getMember, value, member), serdeLikeStruct))
                {
                    static if(is(V == interface) || is(V == class) || is(V : E[T], E, T))
                    {
                        if(val is null)
                        {
                            serializer.putValue(null);
                            continue F;
                        }
                    }
                    auto valState = serializer.objectBegin();
                    foreach (key, ref elem; val)
                    {
                        serializer.putKey(key);
                        serializer.serializeValue(elem);
                    }
                    serializer.objectEnd(valState);
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
        serializer.objectEnd(state);
    }
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
            auto state = serializer.objectBegin;
            serializer.putKey("foo");
            serializer.putValue("bar");
            serializer.objectEnd(state);
        }
    }

    import mir.ion.ser.json: serializeJson;
    assert(serializeJson(S()) == `{"foo":"bar"}`);
}
