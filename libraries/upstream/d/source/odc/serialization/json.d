/+
    == serialization.json ==
    Copyright Alexey Drozhzhin aka Grim Maple 2024
    Distributed under the Boost Software License, Version 1.0.
+/
/++
    This is a JSON serializer for OpenD programming language.

    $(PITFALL
        JSON Serializer relies on `new` to create arrays and objects, so it's incompatible
        with `@nogc` and `betterC` code. Limited compatibility might be provided if no
        arrays / objects are used in serializable object
    )

    ## Usage examples
    To use this serializer, annotate any field you want serialized with [serializable].
    JSON serializator will attempt to automatically convert primitives to corresponding
    JSON tupes, such as any of the number types to JSON Number, string to JSON String,
    bool to JSON true/false.

    ---
    struct Foo
    {
        @serializable int bar;
        @serializable string baz;
    }

    string test = serializeToJSONString(Foo());
    ---

    By default, serializer will skip serializing fields that are `null`.
    If you want to ensure that a ceratin field exists in the JSON object, use [jsonRequired]
    attribute:
    ---
    struct Foo
    {
        @serializable object bar;
        @serializable @jsonRequired object baz;
    }

    assert(serializeToJSONString(Foo()) == "{\"baz\": null}")
    ---

    Marking a field with [jsonRequired] will also result in an error if a required field was
    missing when deserializing:

    ---
    struct Foo
    {
        @serializeable @jsonRequired object bar;
    }

    deserializeJSONFromString!Foo("{}"); // Error
    ---
+/
module odc.serialization.json;

import std.traits;
import std.conv : to;

import std.exception : assertThrown, assertNotThrown;
import std.json;

import d.serialization;

/**
 * A UDA to mark a JSON field as required for deserialization
 *
 * When applied to a field, deserialization will throw if field is not found in json,
 * and serialization will produce `null` for `null` fields
 */
struct jsonRequired { }

/**
 * Serializes an object to a $(LREF JSONValue). To make this work, use $(LREF serializable) UDA on
 * any fields that you want to be serializable. Automatically maps marked fields to
 * corresponding JSON types. Any field not marked with $(LREF serializable) is not serialized.
 */
JSONValue serializeJSON(T)(auto ref T obj) @safe
{
    static if(isPointer!T)
        return serializeJSON!(PointerTarget!T)(*obj);
    else
    {
        JSONValue ret;
        foreach(alias prop; readableSerializables!T)
        {
            enum name = getSerializableName!prop;
            auto value = __traits(child, obj, prop);
            static if(isArray!(typeof(prop)))
            {
                if(value.length > 0)
                    ret[name] = serializeAutoObj(value);
                else if(isJSONRequired!prop)
                    ret[name] = JSONValue(null);
            }
            else ret[name] = serializeAutoObj(value);
        }
        return ret;
    }
}
///
@safe unittest
{
    struct Test
    {
        @serializable int test = 43;
        @serializable string other = "Hello, world";

        @serializable int foo() { return inaccessible; }
        @serializable void foo(int val) { inaccessible = val; }
    private:
        int inaccessible = 32;
    }

    auto val = serializeJSON(Test());
    assert(val["test"].get!int == 43);
    assert(val["other"].get!string == "Hello, world");
    assert(val["foo"].get!int == 32);
}

/**
 * Serialize `T` into a JSON string
 */
string serializeToJSONString(T)(auto ref T obj, in bool pretty = false) @safe
{
    auto val = serializeJSON(obj);
    return toJSON(val, pretty);
}
///
@safe unittest
{
    struct Test
    {
        @serializable int test = 43;
        @serializable string other = "Hello, world";

        @serializable int foo() { return inaccessible; }
        @serializable void foo(int val) { inaccessible = val; }
    private:
        int inaccessible = 32;
    }

    assert(serializeToJSONString(Test()) == `{"foo":32,"other":"Hello, world","test":43}`);
}
/**
 * Deserializes a $(LREF JSONValue) to `T`
 *
 * Throws: $(LREF SerializationException) if fails to create an instance of any class
 *         $(LREF SerializationException) if a $(LREF jsonRequired) $(LREF serializable) is missing
 */
T deserializeJSON(T)(auto ref JSONValue root) @safe
{
    import std.stdio : writeln;
    static if(is(T == class) || isPointer!T)
    {
        if(root.isNull)
            return null;
    }
    T ret;
    static if(is(T == class))
    {
        ret = new T();
        if(ret is null)
            throw new SerializationException("Could not create an instance of " ~ fullyQualifiedName!T);
    }
    foreach(alias prop; writeableSerializables!T)
    {
        enum name = getSerializableName!prop;
        static if(isJSONRequired!prop)
        {
            if((name in root) is null && isJSONRequired!prop)
                throw new SerializationException("Missing required field \"" ~ name ~ "\" in JSON!");
        }
        if(name in root)
        {
            static if(isFunction!prop)
                __traits(child, ret, prop) = deserializeAutoObj!(Parameters!prop[0])(root[name]);
            else
                __traits(child, ret, prop) = deserializeAutoObj!(typeof(prop))(root[name]);
        }
    }
    return ret;
}
///
@safe unittest
{
    immutable json = `{"a": 123, "b": "Hello"}`;

    struct Test
    {
        @serializable int a;
        @serializable string b;
    }

    immutable test = deserializeJSON!Test(parseJSON(json));
    assert(test.a == 123 && test.b == "Hello");
}

/**
 * Deserialize a JSON string into `T`
 */
T deserializeJSONFromString(T)(string json) @safe
{
    return deserializeJSON!T(parseJSON(json));
}
///
@safe unittest
{
    immutable json = `{"a": 123, "b": "Hello"}`;

    struct Test
    {
        @serializable int a;
        @serializable string b;
    }

    immutable test = deserializeJSONFromString!Test(json);
    assert(test.a == 123 && test.b == "Hello");
}

@safe unittest
{
    immutable json = `{"a": 123}`;
    struct A { @serializable("b") @jsonRequired int b; }
    struct B { @serializable int a; }

    auto res = parseJSON(json);
    assertThrown(deserializeJSON!A(res));
    assertNotThrown(deserializeJSON!B(res));
}

private @safe
{
    JSONValue serializeAutoObj(T)(auto ref T obj) @trusted
    {
        static if(isJSONNumber!T || isJSONString!T || is(T == bool))
            return JSONValue(obj);
        else static if(is(T == struct))
            return serializeJSON(obj);
        else static if(is(T == class))
            return serializeJSON(obj);
        else static if(isPointer!T && is(PointerTarget!T == struct))
            return obj is null ? JSONValue(null) : serializeJSON(obj);
        else static if(isArray!T)
            return serializeJSONArray(obj);
        else static assert(false, "Cannot serialize type " ~ T.stringof);

    }

    JSONValue serializeJSONArray(T)(auto ref T obj) @trusted
    {
        JSONValue v = JSONValue(new JSONValue[0]);
        foreach(i; obj)
            v.array ~= serializeAutoObj(i);
        return v;
    }

    T deserializeAutoObj(T)(auto ref JSONValue value) @trusted
    {
        static if(is(T == struct))
            return deserializeJSON!T(value);
        else static if(isPointer!T && is(PointerTarget!T == struct))
        {
            if(value.isNull)
                return null;
            alias underlying = PointerTarget!T;
            underlying* ret = new underlying;
            *ret = deserializeAutoObj!underlying(value);
            return ret;
        }
        else static if(is(T == class))
        {
            return deserializeJSON!T(value);
        }
        else static if(isJSONString!T)
            return value.get!T;
        else static if(isArray!T)
            return deserializeJSONArray!T(value);
        else return value.get!T;
    }

    T deserializeJSONArray(T)(auto ref JSONValue value) @trusted
    {
        T ret;
        static if(!__traits(isStaticArray, T))
            ret = new T(value.arrayNoRef.length);
        foreach(i, val; value.arrayNoRef)
            ret[i] = deserializeAutoObj!(typeof(ret[0]))(val);
        return ret;
    }

    template isJSONRequired(alias T)
    {
        enum bool isJSONRequired = getUDAs!(T, jsonRequired).length > 0;
    }

    template isJSONNumber(T)
    {
        enum bool isJSONNumber = __traits(isScalar, T) && !isPointer!T && !is(T == bool);
    }
    ///
    unittest
    {
        assert(isJSONNumber!int);
        assert(isJSONNumber!float);
        assert(!isJSONNumber!bool);
        assert(!isJSONNumber!string);
    }

    template isJSONString(T)
    {
        enum bool isJSONString = is(T == string) || is(T == wstring) || is(T == dstring);
    }
    ///
    @safe unittest
    {
        assert(isJSONString!string && isJSONString!wstring && isJSONString!dstring);
    }
}
// For UT purposes. Declaring those in a unittest causes frame pointer errors
version(unittest)
{
    private struct TestStruct
    {
        @serializable int a;
        @serializable string b;

        @serializable void foo(int val) @safe { inaccessible = val; }
        @serializable int foo() @safe const { return inaccessible; }
    private:
        int inaccessible;
    }

    private class Test
    {
        @serializable int a;
        @serializable string b;
    }
}

// Test case for deserialization with getters
@safe unittest
{
    string json = `{"a": 123, "b": "Hello", "foo": 345}`;
    auto t = deserializeJSON!TestStruct(parseJSON(json));
    assert(t.a == 123 && t.b == "Hello" && t.foo == 345);
}

// Test case for deserializing classes
@safe unittest
{
    string json = `{"a": 123, "b": "Hello"}`;
    auto t = deserializeJSON!Test(parseJSON(json));
    assert(t.a == 123 && t.b == "Hello");
}

// Global unittest for everything
unittest
{
    struct Other
    {
        @serializable
        string name;

        @serializable
        int id;
    }

    static class TTT
    {
        @serializable string o = "o";
    }

    struct Foo
    {
        // Works with or without brackets
        @serializable int a = 123;
        @serializable() double floating = 123;
        @serializable int[3] arr = [1, 2, 3];
        @serializable string name = "Hello";
        @serializable("flag") bool check = true;
        @serializable() Other object;
        @serializable Other[3] arrayOfObjects;
        @serializable Other* nullable = null;
        @serializable Other* structField = new Other("t", 1);
        @serializable Test classField = new Test();
    }

    auto orig = Foo();
    auto val = serializeJSON(Foo());
    string res = toJSON(val);
    auto back = deserializeJSON!Foo(parseJSON(res));
    assert(back.a == orig.a);
    assert(back.floating == orig.floating);
    assert(back.structField.id == orig.structField.id);
}

// Special tests to check compile-time messages
unittest
{
    struct TooMany
    {
        @serializable @serializable int a;
    }

    struct NotSetter
    {
        @serializable void b(int a, int b);
    }

    TooMany a;
    NotSetter b;

    assert(!__traits(compiles, serializeJSON(a))); // Error: Only 1 UDA is allowed per property
    assert(!__traits(compiles, serializeJSON(b))); // Error: not a getter or a setter
}

// Test for using return value
@safe unittest
{
    struct A
    {
        @serializable int a;
    }

    A a = deserializeJSON!A(parseJSON("{\"a\": 123}"));
}

// Test for const and immutable objects
@safe unittest
{
    struct A
    {
        @serializable int a = 12;
    }

    static class B
    {
        @serializable int a = 12;
    }

    struct C
    {
        @serializable int a() const { return _a; }
        private int _a = 12;
    }

    immutable aa = A();
    const ab = A();

    immutable ba = new B();
    immutable bb = new B();

    immutable ca = C();

    immutable expected = `{"a":12}`;

    assert(serializeToJSONString(aa) == expected);
    assert(serializeToJSONString(ab) == expected);

    assert(serializeToJSONString(ba) == expected);
    assert(serializeToJSONString(bb) == expected);

    assert(serializeToJSONString(C()) == expected);
    assert(serializeToJSONString(ca) == expected);
}

// Unittest for virtual getters
@safe unittest
{
    static class A
    {
        @serializable int b() @safe { return 0; }
    }

    static class B : A
    {
        override int b() @safe { return 1; }
    }

    B b = new B();

    assert(serializeToJSONString(cast(A)b) == `{"b":1}`);
}
