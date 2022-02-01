/++
Base reflection utilities.

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
Authors: Ilya Yaroshenko 
Macros:
+/
module mir.reflection;

import std.meta;
import std.traits: hasUDA, getUDAs, Parameters, isSomeFunction, FunctionAttribute, functionAttributes, EnumMembers, isAggregateType;
import mir.internal.meta: hasUDA;

deprecated
package alias isSomeStruct = isAggregateType;

/++
Attribute to force member serialization for static fields, compiletime `enum` members and non-property methods.
+/
enum reflectSerde;

/++
Match types like `std.typeconst: Nullable`.
+/
template isStdNullable(T)
{
    import std.traits : hasMember;

    T* aggregate;

    enum bool isStdNullable =
        hasMember!(T, "isNull") &&
        hasMember!(T, "get") &&
        hasMember!(T, "nullify") &&
        is(typeof(__traits(getMember, aggregate, "isNull")()) == bool) &&
        !is(typeof(__traits(getMember, aggregate, "get")()) == void) &&
        is(typeof(__traits(getMember, aggregate, "nullify")()) == void);
}

///
version(mir_core_test) unittest
{
    import std.typecons;
    static assert(isStdNullable!(Nullable!double));
}

///
version(mir_core_test) unittest
{
    import mir.algebraic;
    static assert(isStdNullable!(Nullable!double));
}

///  Attribute for deprecated API
struct reflectDeprecated(string target)
{
    ///
    string msg;

    /++
    Number in an issue tracker. Not mandatory.
    +/
    uint issueNumber = uint.max;
    /++
    Should be kind of version number if one can be given.
    Can be something else if that's not possible. Not mandatory.
    +/
    string removalTime;
}

/// Attribute to rename methods, types and functions
template ReflectName(string target)
{
    ///
    struct ReflectName(Args...)
    {
        ///
        string name;
    }
}

/// ditto
template reflectName(string target = null, Args...)
{
    ///
    auto reflectName(string name)
    {
        alias TargetName = ReflectName!target;
        return TargetName!Args(name);
    }
}

///
version(mir_core_test) unittest
{
    enum E { A, B, C }

    struct S
    {
        @reflectName("A")
        int a;

        @reflectName!"c++"("B")
        int b;

        @reflectName!("C",  double)("cd")
        @reflectName!("C",  float)("cf")
        F c(F)()
        {
            return b;
        }
    }

    import std.traits: hasUDA;

    alias UniName = ReflectName!null;
    alias CppName = ReflectName!"c++";
    alias CName = ReflectName!"C";

    static assert(hasUDA!(S.a, UniName!()("A")));
    static assert(hasUDA!(S.b, CppName!()("B")));

    // static assert(hasUDA!(S.c, ReflectName)); // doesn't work for now
    static assert(hasUDA!(S.c, CName));
    static assert(hasUDA!(S.c, CName!double));
    static assert(hasUDA!(S.c, CName!float));
    static assert(hasUDA!(S.c, CName!double("cd")));
    static assert(hasUDA!(S.c, CName!float("cf")));
}

/// Attribute to rename methods, types and functions
template ReflectMeta(string target, string[] fields)
{
    ///
    struct ReflectMeta(Args...)
    {
        ///
        Args args;
        static foreach(i, field; fields)
            mixin(`alias ` ~ field ~` = args[` ~ i.stringof ~`];`);
    }
}

/// ditto
template reflectMeta(string target, string[] fields)
{
    ///
    auto reflectMeta(Args...)(Args args)
        if (args.length <= fields.length)
    {
        alias TargetMeta = ReflectMeta!(target, fields);
        return TargetMeta!Args(args);
    }
}

///
version(mir_core_test) unittest
{
    enum E { A, B, C }

    struct S
    {
        int a;
        @reflectMeta!("c++", ["type"])(E.C)
        int b;
    }

    import std.traits: hasUDA;

    alias CppMeta = ReflectMeta!("c++", ["type"]);

    static assert(CppMeta!E(E.C).type == E.C);
    static assert(!hasUDA!(S.a, CppMeta!E(E.A)));
    static assert(hasUDA!(S.b, CppMeta!E(E.C)));
}

/++
Attribute to ignore a reflection target
+/
template reflectIgnore(string target)
{
    enum reflectIgnore;
}

///
version(mir_core_test) unittest
{
    struct S
    {
        @reflectIgnore!"c++"
        int a;
    }

    import std.traits: hasUDA;
    static assert(hasUDA!(S.a, reflectIgnore!"c++"));
}

/// Attribute for documentation and unittests
struct ReflectDoc(string target)
{
    ///
    string text;
    ///
    reflectUnittest!target test;

    ///
    @safe pure nothrow @nogc
    this(string text)
    {
        this.text = text;
    }

    ///
    @safe pure nothrow @nogc
    this(string text, reflectUnittest!target test)
    {
        this.text = text;
        this.test = test;
    }

    ///
    void toString(W)(scope ref W w) scope const
    {
        w.put(cast()this.text);

        if (this.test.text.length)
        {
            w.put("\nExample usage:\n");
            w.put(cast()this.test.text);
        }
    }

    ///
    @safe pure nothrow
    string toString()() scope const
    {
        return this.text ~ "\nExample usage:\n" ~ this.test.text;
    }
}

/++
Attribute for documentation.
+/
template reflectDoc(string target = null)
{
    ///
    ReflectDoc!target reflectDoc(string text)
    {
        return ReflectDoc!target(text);
    }

    ///
    ReflectDoc!target reflectDoc(string text, reflectUnittest!target test)
    {
        return ReflectDoc!target(text, test);
    }
}

/++
+/
template reflectGetDocs(string target, alias symbol)
{
    static if (hasUDA!(symbol, ReflectDoc!target))
        static immutable(ReflectDoc!target[]) reflectGetDocs = [getUDAs!(symbol, ReflectDoc!target)];
    else
        static immutable(ReflectDoc!target[]) reflectGetDocs = null;
}

/// ditto
template reflectGetDocs(string target)
{
    ///
    alias reflectGetDocs(alias symbol) = .reflectGetDocs!(target, symbol);

    /// ditto
    immutable(ReflectDoc!target)[] reflectGetDocs(T)(T value)
        @safe pure nothrow @nogc
        if (is(T == enum))
    {
        foreach (i, member; EnumMembers!T)
        {{
            alias all = __traits(getAttributes, EnumMembers!T[i]);
        }}
        static immutable ReflectDoc!target[][EnumMembers!T.length] docs = [staticMap!(reflectGetDocs, EnumMembers!T)];
        import mir.enums: getEnumIndex;
        uint index = void;
        if (getEnumIndex(value, index))
            return docs[index];
        assert(0);
    }
}

///
version(mir_core_test) unittest
{
    enum E
    {
        @reflectDoc("alpha")
        a,
        @reflectDoc!"C#"("Beta", reflectUnittest!"C#"("some c# code"))
        @reflectDoc("beta")
        b,
        c,
    }

    alias Doc = ReflectDoc!null;
    alias CSDoc = ReflectDoc!"C#";

    static assert(reflectGetDocs!null(E.a) == [Doc("alpha")]);
    static assert(reflectGetDocs!"C#"(E.b) == [CSDoc("Beta", reflectUnittest!"C#"("some c# code"))]);
    static assert(reflectGetDocs!null(E.b) == [Doc("beta")]);
    static assert(reflectGetDocs!null(E.c) is null);

    struct S
    {
        @reflectDoc("alpha")
        @reflectDoc!"C#"("Alpha")
        int a;
    }

    static assert(reflectGetDocs!(null, S.a) == [Doc("alpha")]);
    static assert(reflectGetDocs!("C#", S.a) == [CSDoc("Alpha")]);

    import std.conv: to;
    static assert(CSDoc("Beta", reflectUnittest!"C#"("some c# code")).to!string == "Beta\nExample usage:\nsome c# code");
}

/++
Attribute for extern unit-test.
+/
struct reflectUnittest(string target)
{
    ///
    string text;

@safe pure nothrow @nogc:

    this(string text)
    {
        this.text = text;
    }

    this(const typeof(this) other)
    {
        this.text = other.text;
    }
}

/++
+/
template reflectGetUnittest(string target, alias symbol)
{
    static if (hasUDA!(symbol, reflectUnittest!target))
        enum string reflectGetUnittest = getUDA!(symbol, reflectUnittest).text;
    else
        enum string reflectGetUnittest = null;
}

/// ditto
template reflectGetUnittest(string target)
{
    ///
    alias reflectGetUnittest(alias symbol) = .reflectGetUnittest!(target, symbol);

    ///
    string reflectGetUnittest(T)(T value)
        if (is(T == enum))
    {
        foreach (i, member; EnumMembers!T)
        {{
            alias all = __traits(getAttributes, EnumMembers!T[i]);
        }}
        static immutable string[EnumMembers!T.length] tests = [staticMap!(reflectGetUnittest, EnumMembers!T)];
        import mir.enums: getEnumIndex;
        uint index = void;
        if (getEnumIndex(value, index))
            return tests[index];
        assert(0);
    }
}

///
version(mir_core_test) unittest
{
    enum E
    {
        @reflectUnittest!"c++"("assert(E::a == 0);")
        a,
        @reflectUnittest!"c++"("assert(E::b == 1);")
        b,
        c,
    }

    static assert(reflectGetUnittest!"c++"(E.a) == "assert(E::a == 0);");
    static assert(reflectGetUnittest!"c++"(E.b) == "assert(E::b == 1);");
    static assert(reflectGetUnittest!"c++"(E.c) is null);

    struct S
    {
        @reflectUnittest!"c++"("alpha")
        int a;
    }

    static assert(reflectGetUnittest!("c++", S.a) == "alpha");
}

/++
Returns: single UDA.
+/
template getUDA(alias symbol, alias attribute)
{
    private alias all = getUDAs!(symbol, attribute);
    static if (all.length != 1)
        static assert(0, "Exactly one " ~ attribute.stringof ~ " attribute is required, " ~ "got " ~ all.length.stringof);
    else
    {
        static if (is(typeof(all[0])))
            enum getUDA = all[0];
        else
            alias getUDA = all[0];
    }
}

/++
Checks if T has a field member.
+/
enum bool isOriginalMember(T, string member) = __traits(identifier, __traits(getMember, T, member)) == member;

///
version(mir_core_test) unittest
{
    struct D
    {
        int a;
        alias b = a;
    }

    static assert(isOriginalMember!(D, "a"));
    static assert(!isOriginalMember!(D, "b"));
}

/++
Checks if T has a field member.
+/
enum bool hasField(T, string member) = __traits(compiles, (ref T aggregate) { return __traits(getMember, aggregate, member).offsetof; });

deprecated("use 'hasField' instead") alias isField = hasField;

///
version(mir_core_test) unittest
{
    struct D
    {
        int gi;
    }

    struct I
    {
        int f;

        D base;
        alias base this;

        void gi(double ) @property {}
        void gi(uint ) @property {}
    }

    struct S
    {
        int d;

        I i;
        alias i this;

        int gm() @property {return 0;}
        int gc() const @property {return 0;}
        void gs(int) @property {}
    }

    static assert(!hasField!(S, "gi"));
    static assert(!hasField!(S, "gs"));
    static assert(!hasField!(S, "gc"));
    static assert(!hasField!(S, "gm"));
    static assert(!hasField!(S, "gi"));
    static assert(hasField!(S, "d"));
    static assert(hasField!(S, "f"));
    static assert(hasField!(S, "i"));
}

///  with classes
version(mir_core_test) unittest
{
    class I
    {
        int f;

        void gi(double ) @property {}
        void gi(uint ) @property {}
    }

    class S
    {
        int d;

        I i;
        alias i this;

        int gm() @property {return 0;}
        int gc() const @property {return 0;}
        void gs(int) @property {}
    }

    static assert(!hasField!(S, "gi"));
    static assert(!hasField!(S, "gs"));
    static assert(!hasField!(S, "gc"));
    static assert(!hasField!(S, "gm"));
    static assert(hasField!(S, "d"));
    static assert(hasField!(S, "f"));
    static assert(hasField!(S, "i"));
}

/++
Checks if member is property.
+/
template isProperty(T, string member)
{
    T* aggregate;

    static if (__traits(compiles, isSomeFunction!(__traits(getMember, *aggregate, member))))
    {
        static if (isSomeFunction!(__traits(getMember, *aggregate, member)))
        {
            enum bool isProperty = isPropertyImpl!(__traits(getMember, *aggregate, member));
        }
        else
        {
            enum bool isProperty = false;
        }
    }
    else
        enum bool isProperty = false;
}

///
version(mir_core_test) unittest
{
    struct D
    {
        int y;

        void gf(double ) @property {}
        void gf(uint ) @property {}
    }

    struct I
    {
        int f;

        D base;
        alias base this;

        void gi(double ) @property {}
        void gi(uint ) @property {}
    }

    struct S
    {
        int d;

        I i;
        alias i this;

        int gm() @property {return 0;}
        int gc() const @property {return 0;}
        void gs(int) @property {}
    }

    static assert(isProperty!(S, "gf"));
    static assert(isProperty!(S, "gi"));
    static assert(isProperty!(S, "gs"));
    static assert(isProperty!(S, "gc"));
    static assert(isProperty!(S, "gm"));
    static assert(!isProperty!(S, "d"));
    static assert(!isProperty!(S, "f"));
    static assert(!isProperty!(S, "y"));
}

version(mir_core_test) unittest
{
    struct S
    {
        @reflectSerde enum s = "str";
        enum t = "str";
    }
    static assert(hasUDA!(S, "s", reflectSerde));
    static assert(!hasUDA!(S, "t", reflectSerde));
}

/++
Returns: list of the setter properties.

Note: The implementation ignores templates.
+/
template getSetters(T, string member)
{
    static if (__traits(hasMember, T, member))
        alias getSetters = Filter!(hasSingleArgument, Filter!(isPropertyImpl, __traits(getOverloads, T, member)));
    else
        alias getSetters = AliasSeq!();
}

///
version(mir_core_test) unittest
{
    struct I
    {
        int f;

        void gi(double ) @property {}
        void gi(uint ) @property {}
    }

    struct S
    {
        int d;

        I i;
        alias i this;

        int gm() @property {return 0;}
        int gc() const @property {return 0;}
        void gs(int) @property {}
    }

    static assert(getSetters!(S, "gi").length == 2);
    static assert(getSetters!(S, "gs").length == 1);
    static assert(getSetters!(S, "gc").length == 0);
    static assert(getSetters!(S, "gm").length == 0);
    static assert(getSetters!(S, "d").length == 0);
    static assert(getSetters!(S, "f").length == 0);
}

/++
Returns: list of the serializable (public getters) members.
+/
enum string[] SerializableMembers(T) = [Filter!(ApplyLeft!(Serializable, T), SerdeFieldsAndProperties!T)];

///
version(mir_core_test) unittest
{
    struct D
    {
        int y;

        int gf() @property {return 0;}
    }

    struct I
    {
        int f;

        D base;
        alias base this;

        int gi() @property {return 0;}
    }

    struct S
    {
        int d;

        package int p;

        enum s = "str";
        @reflectSerde enum t = "str";

        int gm() @property {return 0;}

        private int q;

        I i;
        alias i this;

        int gc() const @property {return 0;}
        void gs(int) @property {}
    }

    static assert(SerializableMembers!S == ["y", "gf", "f", "gi", "d", "t", "gm", "gc"]);
    static assert(SerializableMembers!(const S) == ["y", "f", "d", "t", "gc"]);
}

/++
Returns: list of the deserializable (public setters) members.
+/
enum string[] DeserializableMembers(T) = [Filter!(ApplyLeft!(Deserializable, T), SerdeFieldsAndProperties!T)];

///
version(mir_core_test) unittest
{
    struct I
    {
        int f;
        void ga(int) @property {}
    }

    struct S
    {
        int d;
        package int p;

        int gm() @property {return 0;}
        void gm(int) @property {}

        private int q;

        I i;
        alias i this;


        void gc(int, int) @property {}
        void gc(int) @property {}
    }

    S s;
    // s.gc(0);

    static assert (DeserializableMembers!S == ["f", "ga", "d", "gm", "gc"]);
    static assert (DeserializableMembers!(const S) == []);
}

// This trait defines what members should be serialized -
// public members that are either readable and writable or getter properties
private template Serializable(T, string member)
{
    static if (!isPublic!(T, member))
        enum Serializable = false;
    else
        enum Serializable = isReadable!(T, member); // any readable is good
}

private enum bool hasSingleArgument(alias fun) = Parameters!fun.length == 1;
private enum bool hasZeroArguments(alias fun) = Parameters!fun.length == 0;

// This trait defines what members should be serialized -
// public members that are either readable and writable or setter properties
private template Deserializable(T, string member)
{
    static if (!isPublic!(T, member))
        enum Deserializable = false;
    else
    static if (isReadableAndWritable!(T, member))
        enum Deserializable = true;
    else
    static if (getSetters!(T, member).length == 1)
        enum Deserializable =  is(typeof((ref T val){ __traits(getMember, val, member) = Parameters!(getSetters!(T, member)[0])[0].init; }));
    else
        enum Deserializable = false;
}

private enum SerdeFieldsAndProperties(T) = Reverse!(NoDuplicates!(Reverse!(SerdeFieldsAndPropertiesImpl!T)));

private template allMembers(T)
{
    static if (isAggregateType!T)
        alias allMembers = __traits(allMembers, T);
    else
        alias allMembers = AliasSeq!();
}

private template SerdeFieldsAndPropertiesImpl(T)
{
    alias isProperty = ApplyLeft!(.isProperty, T);
    alias hasField = ApplyLeft!(.hasField, T);
    alias isOriginalMember = ApplyLeft!(.isOriginalMember, T);
    T* aggregate;
    template hasReflectSerde(string member)
    {
        static if (is(typeof(__traits(getMember, *aggregate, member))))
            enum hasReflectSerde = hasUDA!(T, member, reflectSerde);
        else
            enum hasReflectSerde = false;
    }
    alias isMember = templateAnd!(templateOr!(hasField, isProperty, hasReflectSerde), isOriginalMember);
    static if (__traits(getAliasThis, T).length)
    {
        alias A = typeof(__traits(getMember, aggregate, __traits(getAliasThis, T)));
        static if (isAggregateType!T)
            alias baseMembers = SerdeFieldsAndPropertiesImpl!A;
        else
            alias baseMembers = AliasSeq!();
        alias members = Erase!(__traits(getAliasThis, T)[0], __traits(allMembers, T));
        alias SerdeFieldsAndPropertiesImpl = AliasSeq!(baseMembers, Filter!(isMember, members));
    }
    else
    {
        import mir.algebraic;
        static if (isVariant!T)
            alias members = staticMap!(allMembers, T.AllowedTypes);
        else
            alias members = allMembers!T;
        alias SerdeFieldsAndPropertiesImpl = AliasSeq!(Filter!(isMember, members));
    }
}

// check if the member is readable
private template isReadable(T, string member)
{
    T* aggregate;
    enum bool isReadable = __traits(compiles, { static fun(T)(auto ref T t) {} fun(__traits(getMember, *aggregate, member)); });
}

// check if the member is readable/writeble?
private template isReadableAndWritable(T, string member)
{
    T* aggregate;
    enum bool isReadableAndWritable = __traits(compiles, __traits(getMember, *aggregate, member) = __traits(getMember, *aggregate, member));
}

package template isPublic(T, string member)
{
    T* aggregate;
    enum bool isPublic = !__traits(getProtection, __traits(getMember, *aggregate, member)).privateOrPackage;
}

// check if the member is property
private template isSetter(T, string member)
{
    T* aggregate;
    static if (__traits(compiles, isSomeFunction!(__traits(getMember, *aggregate, member))))
    {
        static if (isSomeFunction!(__traits(getMember, *aggregate, member)))
        {
            enum bool isSetter = getSetters!(T, member).length > 0;;
        }
        else
        {
            enum bool isSetter = false;
        }
    }
    else
        enum bool isSetter = false;
}

private template isGetter(T, string member)
{
    T* aggregate;
    static if (__traits(compiles, isSomeFunction!(__traits(getMember, *aggregate, member))))
    {
        static if (isSomeFunction!(__traits(getMember, *aggregate, member)))
        {
            enum bool isGetter = Filter!(hasZeroArguments, Filter!(isPropertyImpl, __traits(getOverloads, T, member))).length == 1;
        }
        else
        {
            enum bool isGetter = false;
        }
    }
    else
        enum bool isGetter = false;
}

private enum bool isPropertyImpl(alias member) = (functionAttributes!member & FunctionAttribute.property) != 0;

private bool privateOrPackage()(string protection)
{
    return protection == "private" || protection == "package";
}
