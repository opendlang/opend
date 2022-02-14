/++
$(H2 Variant and Nullable types)

This module implements a
$(HTTP erdani.org/publications/cuj-04-2002.php.html,discriminated union)
type (a.k.a.
$(HTTP en.wikipedia.org/wiki/Tagged_union,tagged union),
$(HTTP en.wikipedia.org/wiki/Algebraic_data_type,algebraic type)).
Such types are useful
for type-uniform binary interfaces, interfacing with scripting
languages, and comfortable exploratory programming.

The module defines generic $(LREF Algebraic) type that contains a payload.
The allowed types of the paylad are defined by the unordered $(LREF TypeSet).

$(LREF Algebraic) template accepts two arguments: self type set id and a list of type sets.

$(BOOKTABLE $(H3 $(LREF Algebraic) Aliases),
$(TR $(TH Name) $(TH Description))
$(T2 Variant, an algebraic type)
$(T2 TaggedVariant, a tagged algebraic type)
$(T2 Nullable, an algebraic type with at least `typeof(null)`)
)

$(BOOKTABLE $(H3 Visitor Handlers),
$(TR $(TH Name) $(TH Ensures can match) $(TH Throws if no match) $(TH Returns $(LREF Nullable)) $(TH Multiple dispatch) $(TH Argumments count) $(TH Fuses Algebraic types on return))
$(LEADINGROWN 8, Classic handlers)
$(T8 visit, Yes, N/A, No, No, 1+, No)
$(T8 optionalVisit, No, No, Yes, No, 1+, No)
$(T8 autoVisit, No, No, auto, No, 1+, No)
$(T8 tryVisit, No, Yes, No, No, 1+, No)
$(LEADINGROWN 8, Multiple dispatch and algebraic fusion on return)
$(T8 match, Yes, N/A, No, Yes, 0+, Yes)
$(T8 optionalMatch, No, No, Yes, Yes, 0+, Yes)
$(T8 autoMatch, No, No, auto, Yes, 0+, Yes)
$(T8 tryMatch, No, Yes, No, Yes, 0+, Yes)
$(LEADINGROWN 8,  Inner handlers. Multiple dispatch and algebraic fusion on return.)
$(T8 suit, N/A(Yes), N/A, No, Yes, ?, Yes)
$(T8 some, N/A(Yes), N/A, No, Yes, 0+, Yes)
$(T8 none, N/A(Yes), N/A, No, Yes, 1+, Yes)
$(T8 assumeOk, Yes(No), No(Yes), No(Yes), Yes(No), 0+, Yes(No))
$(LEADINGROWN 8, Member access)
$(T8 getMember, Yes, N/A, No, No, 1+, No)
$(T8 optionalGetMember, No, No, Yes, No, 1+, No)
$(T8 autoGetMember, No, No, auto, No, 1+, No)
$(T8 tryGetMember, No, Yes, No, No, 1+, No)
$(LEADINGROWN 8, Member access with algebraic fusion on return)
$(T8 matchMember, Yes, N/A, No, No, 1+, Yes)
$(T8 optionalMatchMember, No, No, Yes, No, 1+, Yes)
$(T8 autoMatchMember, No, No, auto, No, 1+, Yes)
$(T8 tryMatchMember, No, Yes, No, No, 1+, Yes)
)

$(BOOKTABLE $(H3 Special Types),
$(TR $(TH Name) $(TH Description))
$(T2plain `void`, It is usefull to indicate a possible return type of the visitor. Can't be accesed by reference. )
$(T2plain `typeof(null)`, It is usefull for nullable types. Also, it is used to indicate that a visitor can't match the current value of the algebraic. Can't be accesed by reference. )
$(T2 This, Dummy structure that is used to construct self-referencing algebraic types. Example: `Variant!(int, double, string, This*[2])`)
$(T2plain $(LREF SetAlias)`!setId`, Dummy structure that is used to construct cyclic-referencing lists of algebraic types. )
$(T2 TaggedType, Dummy type used to associate tags with type. )
$(T2 Err, Wrapper to denote an error value type. )
$(T2 reflectErr, Attribute that denotes that the type is an error value type. )
)

$(BOOKTABLE $(H3 $(LREF Algebraic) Traits),
$(TR $(TH Name) $(TH Description))
$(T2 isVariant, Checks if the type is instance of $(LREF Algebraic).)
$(T2 isNullable, Checks if the type is instance of $(LREF Algebraic) with a self $(LREF TypeSet) that contains `typeof(null)`. )
$(T2 isTaggedVariant, Checks if the type is instance of tagged $(LREF Algebraic).)
$(T2 isTypeSet, Checks if the types are the same as $(LREF TypeSet) of them. )
$(T2 ValueTypeOfNullable, Gets type of $(LI $(LREF .Algebraic.get.2)) method. )
$(T2 SomeVariant, Gets subtype of algebraic without types for which $(LREF isErr) is true.)
$(T2 NoneVariant, Gets subtype of algebraic with types for which $(LREF isErr) is true.)
$(T2 isErr, Checks if T is a instance of $(LREF Err) or if it is annotated with $(LREF reflectErr).)
$(T2 isResultVariant, Checks if T is a Variant with at least one allowed type that satisfy $(LREF isErr) traits.)

)


$(H3 Type Set)
$(UL 
$(LI $(LREF TaggedTypeSet) is supported. Example:`TargetTypeSet!(["integer", "floating"], int, double)`).
$(LI Type set is unordered. Example:`TypeSet!(int, double)` and `TypeSet!(double, int)` are the same. )
$(LI Duplicats are ignored. Example: `TypeSet!(float, int, float)` and `TypeSet!(int, float)` are the same. )
$(LI Types are automatically unqualified if this operation can be performed implicitly. Example: `TypeSet!(const int) and `TypeSet!int` are the same. )
$(LI Non trivial `TypeSet!(A, B, ..., etc)` is allowed.)
$(LI Trivial `TypeSet!T` is allowed.)
$(LI Empty `TypeSet!()` is allowed.)
)

$(H3 Visitors)
$(UL 
$(LI Visitors are allowed to return values of different types If there are more then one return type then the an $(LREF Algebraic) type is returned. )
$(LI Visitors are allowed to accept additional arguments. The arguments can be passed to the visitor handler. )
$(LI Multiple visitors can be passes to the visitor handler. )
$(LI Visitors are matched according to the common $(HTTPS dlang.org/spec/function.html#function-overloading, Dlang Function Overloading) rules. )
$(LI Visitors are allowed accept algebraic value by reference except the value of `typeof(null)`. )
$(LI Visitors are called without algebraic value if its algebraic type is `void`. )
$(LI If the visitors arguments has known types, then such visitors should be passed to a visitor handler before others to make the compiler happy. This includes visitors with no arguments, which is used to match `void` type. )
)

$(H3 Implementation Features)
$(UL 
$(LI BetterC support. Runtime `TypeInfo` is not used.)
$(LI Copy-constructors and postblit constructors are supported. )
$(LI `toHash`, `opCmp`. `opEquals`, and `toString` support. )
$(LI No string or template mixins are used. )
$(LI Optimised for fast execution. )
$(LI $(LREF some) / $(LREF none) idiom. )
)

See_also: $(HTTPS en.wikipedia.org/wiki/Algebra_of_sets, Algebra of sets).

License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
Authors: Ilya Yaroshenko

Macros:
T2plain=$(TR $(TDNW $1) $(TD $+))
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
T4=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4))
T8=$(TR $(TDNW $(LREF $1)) $(TD $2) $(TD $3) $(TD $4) $(TD $5) $(TD $6) $(TD $7) $(TD $8))

+/
module mir.algebraic;

import mir.internal.meta;
import mir.functional: naryFun;

private static immutable variantExceptionMsg = "mir.algebraic: the algebraic stores other type then requested.";
private static immutable variantNullExceptionMsg = "mir.algebraic: the algebraic is empty and doesn't store any value.";
private static immutable variantMemberExceptionMsg = "mir.algebraic: the algebraic stores a type that isn't compatible with the user provided visitor and arguments.";

version (D_Exceptions)
{
    private static immutable variantException = new Exception(variantExceptionMsg);
    private static immutable variantNullException = new Exception(variantNullExceptionMsg);
    private static immutable variantMemberException = new Exception(variantMemberExceptionMsg);
}

private static struct _Null()
{
@safe pure nothrow @nogc const:
    int opCmp(_Null) { return 0; }
    this(typeof(null)) inout {}
    string toString() { return "null"; }
}

private static struct _Void()
{
 @safe pure nothrow @nogc const:
    int opCmp(_Void) { return 0; }
    string toString() { return "void"; }
}

/++
Checks if the type is instance of $(LREF Algebraic).
+/
enum bool isVariant(T) = is(immutable T == immutable Algebraic!Types, Types...);

///
@safe pure version(mir_core_test) unittest
{
    static assert(isVariant!(Variant!(int, string)));
    static assert(isVariant!(const Variant!(int[], string)));
    static assert(isVariant!(Nullable!(int, string)));
    static assert(!isVariant!int);
}

/++
Checks if the type is instance of tagged $(LREF Algebraic).

Tagged algebraics can be defined with $(LREF TaggedVariant).
+/
enum bool isTaggedVariant(T) = isVariant!T && is(T.Kind == enum);

///
@safe pure version(mir_core_test) unittest
{
    static assert(!isTaggedVariant!int);
    static assert(!isTaggedVariant!(Variant!(int, string)));
    static assert(isTaggedVariant!(TaggedVariant!(["integer", "string"], int, string)));
}

/++
Checks if the type is instance of $(LREF Algebraic) with a self $(LREF TypeSet) that contains `typeof(null)`.
+/
enum bool isNullable(T) = is(immutable T == immutable Algebraic!(typeof(null), Types), Types...);

///
@safe pure version(mir_core_test) unittest
{
    static assert(isNullable!(const Nullable!(int, string)));
    static assert(isNullable!(Nullable!()));

    static assert(!isNullable!(Variant!()));
    static assert(!isNullable!(Variant!string));
    static assert(!isNullable!int);
    static assert(!isNullable!string);
}

/++
Gets type of $(LI $(LREF .Algebraic.get.2)) method.
+/
template ValueTypeOfNullable(T : Algebraic!(typeof(null), Types), Types...)
{
    static if (Types.length == 1)
        alias ValueTypeOfNullable = Types[0];
    else
        alias ValueTypeOfNullable = Algebraic!Types;
}

///
@safe pure version(mir_core_test) unittest
{
    static assert(is(ValueTypeOfNullable!(const Nullable!(int, string)) == Algebraic!(int, string)));
    static assert(is(ValueTypeOfNullable!(Nullable!()) == Algebraic!()));
    static assert(is(typeof(Nullable!().get()) == Algebraic!()));
}

/++
Dummy type for $(LREF Variant) and $(LREF Nullable) self-referencing.
+/
struct This
{
@safe pure nothrow @nogc const:
    int opCmp(typeof(this)) { return 0; }
    string toString() { return typeof(this).stringof; }
}

/++
Dummy type used to associate tags with a type.
+/
struct TaggedType(T, string name)
    if (name.length)
{
    private enum tag = name;
    private alias Type = T;
    static if (!is(T == void) && !is(T == typeof(null)))
        private T payload;
@safe pure nothrow @nogc const:
    int opCmp(ref typeof(this)) { return 0; }
    string toString() { return typeof(this).stringof; }
}

/++
Checks if `T` is $(LREF TaggedType) instance.
+/
enum isTaggedType(T) = is(T == TaggedType!(I, name), I, string name);

/++
Gets $(LREF TaggedType) underlying type.
+/
alias getTaggedTypeUnderlying(T : TaggedType!(I, name), I, string name) = I;

/++
Gets $(LREF TaggedType) tag name.
+/
enum getTaggedTypeName(T : TaggedType!(I, name), I, string name) = name;

// example from std.variant
/++
$(H4 Self-Referential Types)
A useful and popular use of algebraic data structures is for defining
$(LUCKY self-referential data structures), i.e. structures that embed references to
values of their own type within.
This is achieved with $(LREF Variant) by using $(LREF This) as a placeholder whenever a
reference to the type being defined is needed. The $(LREF Variant) instantiation
will perform 
$(LINK2 https://en.wikipedia.org/wiki/Name_resolution_(programming_languages)#Alpha_renaming_to_make_name_resolution_trivial,
alpha renaming) on its constituent types, replacing $(LREF This)
with the self-referenced type. The structure of the type involving $(LREF This) may
be arbitrarily complex.
+/
@safe pure version(mir_core_test) unittest
{
    import mir.functional: Tuple = RefTuple;

    // A tree is either a leaf or a branch of two others
    alias Tree(Leaf) = Variant!(Leaf, Tuple!(This*, This*));
    alias Leafs = Tuple!(Tree!int*, Tree!int*);

    Tree!int tree = Leafs(new Tree!int(41), new Tree!int(43));
    Tree!int* right = tree.get!Leafs[1];
    assert(*right == 43);
}

///
@safe pure version(mir_core_test) unittest
{
    // An object is a double, a string, or a hash of objects
    alias Obj = Variant!(double, string, This[string], This[]);
    alias Map = Obj[string];

    Obj obj = "hello";
    assert(obj._is!string);
    assert(obj.trustedGet!string == "hello");
    obj = 42.0;
    assert(obj.get!double == 42);
    obj = ["customer": Obj("John"), "paid": Obj(23.95)];
    assert(obj.get!Map["customer"] == "John");
}

version(mir_core_test) unittest
{
   static struct Foo
   {
      ~this() @system
      {
      }
   }
   alias TFoo = TaggedType!(Foo, "foo");
   TFoo foo;
}


/++
Type set resolution template used to construct $(LREF Algebraic) .
+/
template TypeSet(T...)
{
    import std.meta: staticSort, staticMap, allSatisfy, anySatisfy;
    // sort types by sizeof and them mangleof
    // but typeof(null) goes first
    static if (is(staticMap!(TryRemoveConst, T) == T))
        static if (is(NoDuplicates!T == T))
            static if (staticIsSorted!(TypeCmp, T))
            {
                static if (anySatisfy!(isTaggedType, T))
                {
                    import std.meta: Filter, templateNot;
                    static assert(Filter!(templateNot!isTaggedType, T).length == 0,
                        "Either all or none types must be tagged. Types that doesn't have tags: " ~
                        Filter!(templateNot!isTaggedType, T).stringof);
                }
                alias TypeSet = T;
            }
            else
                alias TypeSet = .TypeSet!(staticSort!(TypeCmp, T));
        else
            alias TypeSet = TypeSet!(NoDuplicates!T);
    else
        alias TypeSet = TypeSet!(staticMap!(TryRemoveConst, T));
}

// IonNull goes first as well
private template isIonNull(T)
{
    static if (is(T == TaggedType!(U, name), U, string name))
        enum isIonNull = .isIonNull!U;
    else
        enum isIonNull = T.stringof == "IonNull";
}

private template TypeCmp(A, B)
{
    enum bool TypeCmp = is(A == B) ? false:
    is(A == typeof(null)) || is(A == TaggedType!(typeof(null), aname), string aname) ? true:
    is(B == typeof(null)) || is(B == TaggedType!(typeof(null), bname), string bname) ? false:
    isIonNull!A ? true:
    isIonNull!B ? false:
    is(A == void) || is(A == TaggedType!(void, vaname), string vaname) ? true:
    is(B == void) || is(A == TaggedType!(void, vbname), string vbname) ? false:
    A.sizeof < B.sizeof ? true:
    A.sizeof > B.sizeof ? false:
    A.mangleof < B.mangleof;
}

///
version(mir_core_test) unittest
{
    static struct S {}
    alias C = S;
    alias Int = int;
    static assert(is(TypeSet!(S, int) == TypeSet!(Int, C)));
    static assert(is(TypeSet!(S, int, int) == TypeSet!(Int, C)));
    static assert(!is(TypeSet!(uint, S) == TypeSet!(int, S)));
}

private template applyTags(string[] tagNames, T...)
    if (tagNames.length == T.length)
{
    import std.meta: AliasSeq;
    static if (tagNames.length == 0)
        alias applyTags = AliasSeq!();
    else
        alias applyTags =  AliasSeq!(TaggedType!(T[0], tagNames[0]), .applyTags!(tagNames[1 .. $], T[1 .. $]));
}

/++
Type set for tagged $(LREF Variants) self-referencing.
+/
alias TaggedTypeSet(string[] tagNames, T...) = TypeSet!(applyTags!(tagNames, T));

/++
Checks if the type list is $(LREF TypeSet).
+/
enum bool isTypeSet(T...) = is(T == TypeSet!T);

///
@safe pure version(mir_core_test) unittest
{
    static assert(isTypeSet!(TypeSet!()));
    static assert(isTypeSet!(TypeSet!void));
    static assert(isTypeSet!(TypeSet!(void, int, typeof(null))));
}

/++
Variant Type (aka Algebraic Type).

The impllementation is defined as
----
alias Variant(T...) = Algebraic!(TypeSet!T);
----

Compatible with BetterC mode.
+/
alias Variant(T...) = Algebraic!(TypeSet!T);

///
@safe pure @nogc 
version(mir_core_test) unittest
{
    Variant!(int, double, string) v = 5;
    assert(v.get!int == 5);
    v = 3.14;
    assert(v == 3.14);
    // auto x = v.get!long; // won't compile, type long not allowed
    // v = '1'; // won't compile, type char not allowed
}

/// Single argument Variant
// and Type with copy constructor
@safe pure nothrow @nogc 
version(mir_core_test) unittest 
{
    static struct S
    {
        int n;
        this(ref return scope inout S rhs) inout
        {
            this.n = rhs.n + 1;
        }
    }

    Variant!S a = S();
    auto b = a;

    import mir.conv;
    assert(a.get!S.n == 0);
    assert(b.n == 1); //direct access of a member in case of all algebraic types has this member
}

/// Empty type set
@safe pure nothrow @nogc version(mir_core_test) unittest 
{
    Variant!() a;
    auto b = a;
    assert(a.toHash == 0);
    assert(a == b);
    assert(a <= b && b >= a);
    static assert(typeof(a).sizeof == 1);
}

/// Small types
@safe pure nothrow @nogc version(mir_core_test) unittest 
{
    static struct S { ubyte d; }
    static assert(Nullable!(byte, char, S).sizeof == 2);
}

@safe pure nothrow @nogc version(mir_core_test) unittest 
{
    static struct S { ubyte[3] d; }
    static assert(Nullable!(ushort, wchar, S).sizeof == 6);
}

// /// opPostMove support
// @safe pure @nogc nothrow
// version(mir_core_test) unittest
// {
//     import std.algorithm.mutation: move;

//     static struct S
//     {
//         uint s;

//         void opPostMove(const ref S old) nothrow
//         {
//             this.s = old.s + 1;
//         }
//     }

//     Variant!S a;

//     auto b = a.move;
//     assert(b.s == 1);
// }

/++
Tagged Variant Type (aka Tagged Algebraic Type).

Compatible with BetterC mode.

Template has two declarations:
----
alias TaggedVariant(string[] tags, T...) = Variant!(applyTags!(tags, T));
// and
template TaggedVariant(T)
    if (is(T == union))
{
    ...
}
----

See_also: $(LREF Variant), $(LREF isTaggedVariant).
+/
alias TaggedVariant(string[] tags, T...) = Variant!(applyTags!(tags, T));

/// ditto
template TaggedVariant(T)
    if (is(T == union))
{
    import std.meta: staticMap;
    enum names = __traits(allMembers, T);
    alias TypeOf(string member) = typeof(__traits(getMember, T, member));
    alias Types = staticMap!(TypeOf, names);
    alias TaggedVariant = .TaggedVariant!([names], Types);
}

/// Json Value
@safe pure 
version(mir_core_test) unittest
{
    static union JsonUnion
    {
        long integer;
        double floating;
        bool boolean;
        typeof(null) null_;
        immutable(char)[] string;
        This[] array;
        This[immutable(char)[]] object;
    }

    alias JsonValue = TaggedVariant!JsonUnion;

    // typeof(null) has priority
    static assert(JsonValue.Kind.init == JsonValue.Kind.null_);
    static assert(JsonValue.Kind.null_ == 0);
    
    // Kind and AllowedTypes has the same order
    static assert (is(JsonValue.AllowedTypes[JsonValue.Kind.array] == JsonValue[]));
    static assert (is(JsonValue.AllowedTypes[JsonValue.Kind.boolean] == bool));
    static assert (is(JsonValue.AllowedTypes[JsonValue.Kind.floating] == double));
    static assert (is(JsonValue.AllowedTypes[JsonValue.Kind.integer] == long));
    static assert (is(JsonValue.AllowedTypes[JsonValue.Kind.null_] == typeof(null)));
    static assert (is(JsonValue.AllowedTypes[JsonValue.Kind.object] == JsonValue[string]));

    JsonValue v;
    assert(v.kind == JsonValue.Kind.null_);

    v = 1;
    assert(v.kind == JsonValue.Kind.integer);
    assert(v == 1);
    v = JsonValue(1);
    assert(v == 1);
    v = v.get!(long, double);

    v = "Tagged!";
    assert(v.get       !string                  == "Tagged!");
    assert(v.trustedGet!string                  == "Tagged!");

    assert(v.kind == JsonValue.Kind.string);

    assert(v.get!"string" == "Tagged!"); // string-based get
    assert(v.trustedGet!"string" == "Tagged!"); // string-based trustedGet

    assert(v.get!(JsonValue.Kind.string) == "Tagged!"); // Kind-based get
    assert(v.trustedGet!(JsonValue.Kind.string) == "Tagged!"); // Kind-based trustedGet

    v = [JsonValue("str"), JsonValue(4.3)];

    assert(v.kind == JsonValue.Kind.array);
    assert(v.trustedGet!(JsonValue[])[1].kind == JsonValue.Kind.floating);

    v = null;
    assert(v.kind == JsonValue.Kind.null_);
}

/// Wrapped algebraic with propogated primitives
@safe pure 
version(mir_core_test) unittest
{
    static struct Response
    {
        alias Union = TaggedVariant!(
            ["double_", "string", "array", "table"],
            double,
            string,
            Response[],
            Response[string],
        );

        Union data;
        alias Tag = Union.Kind;
        // propogates opEquals, opAssign, and other primitives
        alias data this;

        static foreach (T; Union.AllowedTypes)
            this(T v) @safe pure nothrow @nogc { data = v; }
    }

    Response v = 3.0;
    assert(v.kind == Response.Tag.double_);
    v = "str";
    assert(v == "str");
}

/++
Nullable $(LREF Variant) Type (aka Algebraic Type).

The impllementation is defined as
----
alias Nullable(T...) = Variant!(typeof(null), T);
----

In additional to common algebraic API the following members can be accesssed:
$(UL 
$(LI $(LREF .Algebraic.isNull))
$(LI $(LREF .Algebraic.nullify))
$(LI $(LREF .Algebraic.get.2))
)

Compatible with BetterC mode.
+/
alias Nullable(T...) = Variant!(typeof(null), T);

/// ditto
Nullable!T nullable(T)(T t)
{
    import core.lifetime: forward;
    return Nullable!T(forward!t);
}

/++
Single type `Nullable`
+/
@safe pure @nogc
version(mir_core_test) unittest
{
    static assert(is(Nullable!int == Variant!(typeof(null), int)));
    
    Nullable!int a = 5;
    assert(a.get!int == 5);

    a.nullify;
    assert(a.isNull);

    a = 4;
    assert(!a.isNull);
    assert(a.get == 4);
    assert(a == 4);
    a = 4;

    a = null;
    assert(a == null);
}

/// Empty nullable type set support
@safe pure nothrow @nogc version(mir_core_test) unittest 
{
    Nullable!() a;
    auto b = a;
    assert(a.toHash == 0);
    assert(a == b);
    assert(a <= b && b >= a);
    static assert(typeof(a).sizeof == 1);
}

/++
Algebraic implementation.
For more portable code, it is higly recommeded to don't use this template directly.
Instead, please use of $(LREF Variant) and $(LREF Nullable), which sort types.
+/
struct Algebraic(_Types...)
{
    import core.lifetime: moveEmplace;
    import mir.conv: emplaceRef;
    import mir.reflection: isPublic, hasField, isProperty;
    import std.meta: Filter, AliasSeq, ApplyRight, anySatisfy, allSatisfy, staticMap, templateOr, templateNot;
    import std.traits:
        hasElaborateAssign,
        hasElaborateCopyConstructor,
        hasElaborateDestructor,
        hasMember,
        isDynamicArray,
        isEqualityComparable,
        isOrderingComparable,
        Largest,
        Unqual
        ;

    private enum bool _variant_test_ = is(_Types == AliasSeq!(typeof(null), double));

    static if (anySatisfy!(isTaggedType, _Types))
    {
        private alias _UntaggedThisTypeSetList = staticMap!(getTaggedTypeUnderlying, _Types);
    }
    else
    {
        private alias _UntaggedThisTypeSetList = _Types;
    }

    /++
    Allowed types list
    See_also: $(LREF TypeSet)
    +/
    alias AllowedTypes = AliasSeq!(ReplaceTypeUnless!(isVariant, This, Algebraic!_Types, _UntaggedThisTypeSetList));

    version(mir_core_test)
    static if (_variant_test_)
    ///
    unittest
    {
        import std.meta: AliasSeq;

        alias V = Nullable!
        (
            This*,
            string,
            double,
            bool,
        );

        static assert(is(V.AllowedTypes == TypeSet!(
            typeof(null),
            bool,
            string,
            double,
            V*)));
    }

    private alias _Payload = Replace!(void, _Void!(), Replace!(typeof(null), _Null!(), AllowedTypes));

    private static union _Storage_
    {
        _Payload payload;

        static foreach (int i, P; _Payload)
            mixin(`alias _member_` ~ i.stringof ~ ` = payload[` ~ i.stringof ~ `];`);

        static if (AllowedTypes.length == 0 || is(AllowedTypes == AliasSeq!(typeof(null))))
            ubyte[0] bytes;
        else
            ubyte[Largest!_Payload.sizeof] bytes;
    }

    private _Storage_ _storage_;

    static if (AllowedTypes.length > 1)
    {
        static if ((_Storage_.alignof & 1) && _Payload.length <= ubyte.max)
            private alias _ID_ = ubyte;
        else
        static if ((_Storage_.alignof & 2) && _Payload.length <= ushort.max)
            private alias _ID_ = ushort;
        else
        static if (_Storage_.alignof & 3)
            private alias _ID_ = uint;
        else
            private alias _ID_ = ulong;
    
        _ID_ _identifier_;
    }
    else
    {
        alias _ID_ = uint;
        enum _ID_ _identifier_ = 0;
    }

    version (D_Ddoc)
    {
        /++
        Algebraic Kind.

        Defined as enum for tagged algebraics and as unsigned for common algebraics.

        The Kind enum contains the members defined using tag names.

        If the algebraic type is $(LREF Nullable) then the default Kind enum member has zero value and corresponds to `typeof(null)`.

        See_also: $(LREF TaggedVariant).
        +/
        enum Kind { _not_me_but_tags_name_list_ }
    }

    static if (anySatisfy!(isTaggedType, _Types))
    {
        version (D_Ddoc){}
        else
        {
            mixin(enumKindText([staticMap!(getTaggedTypeName, _Types)]));

        }
    }
    else
    {
        version (D_Ddoc){}
        else
        {
            alias Kind = _ID_;
        }
    }

    /++
    Returns: $(LREF .Algebraic.Kind).

    Defined as enum for tagged algebraics and as unsigned for common algebraics.
    See_also: $(LREF TaggedVariant).
    +/
    Kind kind() const @safe pure nothrow @nogc @property
    {
        assert(_identifier_ <= Kind.max);
        return cast(Kind) _identifier_;
    }

    static if (anySatisfy!(hasElaborateDestructor, _Payload))
    ~this() @trusted
    {
        S: switch (_identifier_)
        {
            static foreach (i, T; AllowedTypes)
            static if (hasElaborateDestructor!T)
            {
                case i:
                    (*cast(Unqual!(_Payload[i])*)&_storage_.payload[i]).__xdtor;
                    break S;
            }
            default:
        }
        version(mir_secure_memory)
            _storage_.bytes = 0xCC;
    }

    // static if (anySatisfy!(hasOpPostMove, _Payload))
    // void opPostMove(const ref typeof(this) old)
    // {
    //     S: switch (_identifier_)
    //     {
    //         static foreach (i, T; AllowedTypes)
    //         static if (hasOpPostMove!T)
    //         {
    //             case i:
    //                 this._storage_.payload[i].opPostMove(old._storage_.payload[i]);
    //                 return;
    //         }
    //         default: return;
    //     }
    // }

    static if (AllowedTypes.length)
    {
        static if (!__traits(compiles, (){ _Payload[0] arg; }))
        {
            @disable this();
        }

        static if (allSatisfy!(isDynamicArray, AllowedTypes))
        {
            auto length()() const @property
            {
                switch (_identifier_)
                {
                    static foreach (i, T; AllowedTypes)
                    {
                        case i:
                            return trustedGet!T().length;
                    }
                    default: assert(0);
                }
            }

            auto length()(size_t length) @property
            {
                switch (_identifier_)
                {
                    static foreach (i, T; AllowedTypes)
                    {
                        case i:
                            return trustedGet!T().length = length;
                    }
                    default: assert(0);
                }
            }

            alias opDollar(size_t pos : 0) = length;

            /// Returns: slice type of `Slice!(IotaIterator!size_t)`
            size_t[2] opSlice(size_t dimension)(size_t i, size_t j) @safe scope const
                if (dimension == 0)
            in(i <= j, "Algebraic.opSlice: the left opSlice boundary must be less than or equal to the right bound.")
            {
                return [i, j];
            }

            auto opIndex()(size_t index)
            {
                return this.visit!(a => a[index]);
            }

            auto opIndex()(size_t index) const
            {
                return this.visit!(a => a[index]);
            }

            auto opIndex()(size_t[2] index)
            {
                auto ret = this;
                S: switch (_identifier_)
                {
                    static foreach (i, T; AllowedTypes)
                    {
                        case i:
                            ret.trustedGet!T() = ret.trustedGet!T()[index[0] .. index[1]];
                            break S;
                    }
                    default: assert(0);
                }
                return ret;
            }

            auto opIndexAssign(T)(T value, size_t index)
            {
                return this.tryMatch!((ref array, ref value) => array[index] = value)(value);
            }
        }
    }

    /// Construct an algebraic type from its subset.
    this(RhsTypes...)(Algebraic!RhsTypes rhs)
        if (allSatisfy!(Contains!AllowedTypes, Algebraic!RhsTypes.AllowedTypes))
    {
        import core.lifetime: move;
        static if (is(RhsTypes == _Types))
            this = move(rhs);
        else
        {
            switch (rhs._identifier_)
            {
                static foreach (i, T; Algebraic!RhsTypes.AllowedTypes)
                {
                    case i:
                        static if (__traits(compiles, __ctor(move(rhs.trustedGet!T))))
                            __ctor(move(rhs.trustedGet!T));
                        else
                            __ctor(rhs.trustedGet!T);
                        return;
                }
                default:
                    assert(0, variantMemberExceptionMsg);
            }
        }
    }

    version(mir_core_test)
    static if (_variant_test_)
    ///
    unittest
    {
        alias Float = Variant!(float, double);
        alias Int = Variant!(long, int);
        alias Number = Variant!(Float.AllowedTypes, Int.AllowedTypes);

        Float fp = 3.0;
        Number number = fp; // constructor call
        assert(number == 3.0);

        Int integer = 12L;
        number = Number(integer);
        assert(number == 12L);
    }

    static if (!allSatisfy!(isCopyable, AllowedTypes))
        @disable this(this);
    else
    static if (anySatisfy!(hasElaborateCopyConstructor, AllowedTypes))
    {
        // private enum _allCanImplicitlyRemoveConst = allSatisfy!(canImplicitlyRemoveConst, AllowedTypes);
        // private enum _allCanRemoveConst = allSatisfy!(canRemoveConst, AllowedTypes);
        // private enum _allHaveImplicitSemiMutableConstruction = _allCanImplicitlyRemoveConst && _allHaveMutableConstruction;

        static if (__VERSION__ < 2094)
        private static union _StorageI(uint i)
        {
            _Payload[i] payload;
            ubyte[_Storage_.bytes.length] bytes;
        }

        static if (allSatisfy!(hasInoutConstruction, AllowedTypes))
        this(return ref scope inout Algebraic rhs) inout
        {
            static if (AllowedTypes.length > 1) this._identifier_ = rhs._identifier_;
            static foreach (int i, T; AllowedTypes)
            static if (!is(T == typeof(null)) && !is(T == void))
            {
                if (_identifier_ == i)
                {
                    static if (__VERSION__ < 2094)
                    {
                        _storage_.bytes = () inout @trusted {
                            auto ret =  inout _StorageI!i(rhs.trustedGet!T);
                            return ret.bytes;
                        } ();
                        return;
                    }
                    else
                    {
                        _storage_ = () inout {
                            mixin(`inout _Storage_ ret = { _member_` ~ i.stringof ~ ` : rhs.trustedGet!T };`);
                            return ret;
                        } ();
                        return;
                    }
                }
            }
        }
        else
        {
            static if (allSatisfy!(hasMutableConstruction, AllowedTypes))
            this(return ref scope Algebraic rhs)
            {
                static if (AllowedTypes.length > 1) this._identifier_ = rhs._identifier_;
                static foreach (int i, T; AllowedTypes)
                static if (!is(T == typeof(null)) && !is(T == void))
                {
                    if (_identifier_ == i)
                    {
                        _storage_ = () {
                            mixin(`_Storage_ ret = { _member_` ~ i.stringof ~ ` : rhs.trustedGet!T };`);
                            return ret;
                        } ();
                        return;
                    }
                }
            }

            static if (allSatisfy!(hasConstConstruction, AllowedTypes))
            this(return ref scope const Algebraic rhs) const
            {
                static if (AllowedTypes.length > 1) this._identifier_ = rhs._identifier_;
                static foreach (int i, T; AllowedTypes)
                static if (!is(T == typeof(null)) && !is(T == void))
                {
                    if (_identifier_ == i)
                    {
                        _storage_ = () const {
                            mixin(`const _Storage_ ret = { _member_` ~ i.stringof ~ ` : rhs.trustedGet!T };`);
                            return ret;
                        } ();
                        return;
                    }
                }
            }

            static if (allSatisfy!(hasImmutableConstruction, AllowedTypes))
            this(return ref scope immutable Algebraic rhs) immutable
            {
                static if (AllowedTypes.length > 1) this._identifier_ = rhs._identifier_;
                static foreach (int i, T; AllowedTypes)
                static if (!is(T == typeof(null)) && !is(T == void))
                {
                    if (_identifier_ == i)
                    {
                        _storage_ = () immutable {
                            mixin(`immutable _Storage_ ret = { _member_` ~ i.stringof ~ ` : rhs.trustedGet!T };`);
                            return ret;
                        } ();
                        return;
                    }
                }
            }

            static if (allSatisfy!(hasSemiImmutableConstruction, AllowedTypes))
            this(return ref scope const Algebraic rhs) immutable
            {
                static if (AllowedTypes.length > 1) this._identifier_ = rhs._identifier_;
                static foreach (int i, T; AllowedTypes)
                static if (!is(T == typeof(null)) && !is(T == void))
                {
                    if (_identifier_ == i)
                    {
                        _storage_ = () const {
                            mixin(`immutable _Storage_ ret = { _member_` ~ i.stringof ~ ` : rhs.trustedGet!T };`);
                            return ret;
                        } ();
                        return;
                    }
                }
            }

            static if (allSatisfy!(hasSemiMutableConstruction, AllowedTypes))
            this(return ref scope const Algebraic rhs)
            {
                static if (AllowedTypes.length > 1) this._identifier_ = rhs._identifier_;
                static foreach (int i, T; AllowedTypes)
                static if (!is(T == typeof(null)) && !is(T == void))
                {
                    if (_identifier_ == i)
                    {
                        _storage_ = () const {
                            mixin(`const _Storage_ ret = { _member_` ~ i.stringof ~ ` : rhs.trustedGet!T };`);
                            return ret;
                        } ();
                        return;
                    }
                }
            }
        }
    }

    /++
    +/
    size_t toHash() @trusted nothrow const
    {
        static if (AllowedTypes.length == 0 || is(AllowedTypes == AliasSeq!(typeof(null))))
        {
            return 0;
        }
        else
        switch (_identifier_)
        {
            static foreach (i, T; AllowedTypes)
            {
                case i:
                    static if (is(T == void))
                        return i;
                    else
                    static if (is(T == typeof(null)))
                        return i;
                    else
                    static if (__traits(compiles, hashOf(trustedGet!T, cast(size_t)i)))
                        return hashOf(trustedGet!T, cast(size_t)i);
                    else
                    {
                        debug pragma(msg, "Mir warning: can't compute hash of " ~ (const T).stringof);
                        return i;
                    }
            }
            default: assert(0);
        }
    }

    /++
    +/
    bool opEquals()(auto ref const typeof(this) rhs) const @trusted
    {
        static if (AllowedTypes.length == 0)
        {
            return true;
        }
        else
        {
            if (this._identifier_ != rhs._identifier_)
                return false;
            switch (_identifier_)
            {
                static foreach (i, T; AllowedTypes)
                {
                    case i:
                        return this.trustedGet!T == rhs.trustedGet!T;
                }
                default: assert(0);
            }
        }
    }

    /++
    +/
    static if (is(AllowedTypes == _Types))
    auto opCmp()(auto ref const typeof(this) rhs) const @trusted
    {
        static if (AllowedTypes.length == 0)
        {
            return 0;
        }
        else
        {
            import mir.internal.utility: isFloatingPoint;
            if (auto d = int(this._identifier_) - int(rhs._identifier_))
                return d;
            switch (_identifier_)
            {
                static foreach (i, T; AllowedTypes)
                {
                    case i:
                        static if (__traits(compiles, __cmp(trustedGet!T, rhs.trustedGet!T)))
                            return __cmp(trustedGet!T, rhs.trustedGet!T);
                        else
                        static if (__traits(hasMember, T, "opCmp") && !is(T == U*, U))
                            return this.trustedGet!T.opCmp(rhs.trustedGet!T);
                        else
                        // static if (isFloatingPoint!T)
                        //     return trustedGet!T == rhs ? 0 : trustedGet!T - rhs.trustedGet!T;
                        // else
                            return this.trustedGet!T < rhs.trustedGet!T ? -1 :
                                this.trustedGet!T > rhs.trustedGet!T ? +1 : 0;
                }
                default: assert(0);
            }
        }
    }

    /// Requires mir-algorithm package
    string toString()() const
    {
        static if (AllowedTypes.length == 0)
        {
            return "Algebraic";
        }
        else
        {
            import mir.conv: to;
            switch (_identifier_)
            {
                static foreach (i, T; AllowedTypes)
                {
                    case i:
                        static if (is(T == void))
                            return "void";
                        else
                        static if (is(T == typeof(null)))
                            return "null";
                        else
                        static if (__traits(compiles, { auto s = to!string(trustedGet!T);}))
                            return to!string(trustedGet!T);
                        else
                            return AllowedTypes[i].stringof;
                }
                default: assert(0);
            }
        }
    }

    ///ditto
    void toString(W)(scope ref W w) const
    {
        static if (AllowedTypes.length == 0)
        {
            return w.put("Algebraic");
        }
        else
        {
            switch (_identifier_)
            {
                static foreach (i, T; AllowedTypes)
                {
                    case i:
                        static if (is(T == void))
                            return w.put("void");
                        else
                        static if (is(T == typeof(null)))
                            return w.put("null");
                        else
                        static if (__traits(compiles, { import mir.format: print; print(w, trustedGet!T); }))
                            { import mir.format: print; print(w, trustedGet!T); }
                        else
                            w.put(AllowedTypes[i].stringof);
                        return;
                }
                default: assert(0);
            }
        }
    }

    static if (is(AllowedTypes[0] == typeof(null)))
    {
        ///
        bool opCast(C)() const
            if (is(C == bool))
        {
            return _identifier_ != 0;
        }

        ///
        Algebraic opCast(C)() const
            if (is(C == Algebraic))
        {
            return this;
        }

        /// Defined if the first type is `typeof(null)`
        bool isNull() const @property { return _identifier_ == 0; }
        /// ditto
        void nullify() { this = null; }

        /// ditto
        auto get()()
            if (allSatisfy!(isCopyable, AllowedTypes[1 .. $]) && AllowedTypes.length != 2)
        {
            import mir.utility: _expect;
            if (_expect(!_identifier_, false))
            {
                throw variantNullException;
            }
            static if (AllowedTypes.length != 2)
            {
                Algebraic!(_Types[1 .. $]) ret;

                S: switch (_identifier_)
                {
                    static foreach (i, T; AllowedTypes[1 .. $])
                    {
                        {
                            case i + 1:
                                if (!hasElaborateCopyConstructor!T && !__ctfe)
                                    goto default;
                                ret = this.trustedGet!T;
                                break S;
                        }
                    }
                    default:
                        ret._storage_.bytes = this._storage_.bytes;
                        static if (ret.AllowedTypes.length > 1)
                            ret._identifier_ = cast(typeof(ret._identifier_))(this._identifier_ - 1);
                }
                return ret;
            }
        }

        static if (AllowedTypes.length == 2)
        {
            /++
            Gets the value if not null. If `this` is in the null state, and the optional
            parameter `fallback` was provided, it will be returned. Without `fallback`,
            calling `get` with a null state is invalid.
        
            When the fallback type is different from the Nullable type, `get(T)` returns
            the common type.
        
            Params:
                fallback = the value to return in case the `Nullable` is null.
        
            Returns:
                The value held internally by this `Nullable`.
            +/
            auto ref inout(AllowedTypes[1]) get() return inout
            {
                assert(_identifier_, "Called `get' on null Nullable!(" ~ AllowedTypes[1].stringof ~ ").");
                return trustedGet!(AllowedTypes[1]);
            }

            version(mir_core_test)
            static if (_variant_test_)
            ///
            @safe pure nothrow @nogc
            unittest
            {
                enum E { a = "a", b = "b" }
                Nullable!E f = E.a;
                auto e = f.get();
                static assert(is(typeof(e) == E), Nullable!E.AllowedTypes.stringof);
                assert(e == E.a);

                assert(f.get(E.b) == E.a);

                f = null;
                assert(f.get(E.b) == E.b);
            }

            /// ditto
            @property auto ref inout(AllowedTypes[1]) get()(auto ref inout(AllowedTypes[1]) fallback) return inout
            {
                return isNull ? fallback : get();
            }
        }
    }

    /++
    Checks if the underlaying type is an element of a user provided type set.
    +/
    bool _is(R : Algebraic!RetTypes, RetTypes...)() @safe pure nothrow @nogc const @property
        if (allSatisfy!(Contains!AllowedTypes, Algebraic!RetTypes.AllowedTypes))
    {
        static if (is(RetTypes == _Types))
            return true;
        else
        {
            import std.meta: staticIndexOf;
            import std.traits: CopyTypeQualifiers;
            alias RhsAllowedTypes = Algebraic!RetTypes.AllowedTypes;
            alias Ret = CopyTypeQualifiers!(This, Algebraic!RetTypes);
            // uint rhsTypeId;
            switch (_identifier_)
            {
                foreach (i, T; AllowedTypes)
                static if (staticIndexOf!(T, RhsAllowedTypes) >= 0)
                {
                    case i:
                        return true;
                }
                default:
                    return false;
            }
        }
    }

    /// ditto
    bool _is(RetTypes...)() @safe pure nothrow @nogc const @property
        if (RetTypes.length > 1)
    {
        return this._is!(Variant!RetTypes);
    }

    /++
    `nothrow` $(LREF .Algebraic.get) alternative that returns an algebraic subset.
    +/
    auto ref trustedGet(R : Algebraic!RetTypes, this This, RetTypes...)() return @property
        if (allSatisfy!(Contains!AllowedTypes, Algebraic!RetTypes.AllowedTypes))
    {
        static if (is(RetTypes == _Types))
            return this;
        else
        {
            import std.meta: staticIndexOf;
            import std.traits: CopyTypeQualifiers;
            alias RhsAllowedTypes = Algebraic!RetTypes.AllowedTypes;
            alias Ret = CopyTypeQualifiers!(This, Algebraic!RetTypes);
            // uint rhsTypeId;
            switch (_identifier_)
            {
                foreach (i, T; AllowedTypes)
                static if (staticIndexOf!(T, RhsAllowedTypes) >= 0)
                {
                    case i:
                        static if (is(T == void))
                            return (()@trusted => cast(Ret) Ret._void)();
                        else
                            return Ret(trustedGet!T);
                }
                default:
                    assert(0, variantMemberExceptionMsg);
            }
        }
    }

    /// ditto
    template trustedGet(RetTypes...)
        if (RetTypes.length > 1)
    {
        ///
        auto ref trustedGet(this This)() return
        {
            return this.trustedGet!(Variant!RetTypes);
        }
    }

    version(mir_core_test)
    static if (_variant_test_)
    ///
    @safe pure nothrow @nogc
    unittest
    {
        alias Float = Variant!(float, double);
        alias Int = Variant!(long, int);
        alias Number = Variant!(Float.AllowedTypes, Int.AllowedTypes);

        Number number = 3.0;
        assert(number._is!Float);
        auto fp = number.trustedGet!Float;
        static assert(is(typeof(fp) == Float));
        assert(fp == 3.0);

        // type list overload
        number = 12L;
        assert(number._is!(int, long));
        auto integer = number.trustedGet!(int, long);
        static assert(is(typeof(integer) == Int));
        assert(integer == 12L);
    }

    static if (anySatisfy!(isTaggedType, _Types))
    {
        /// `trustedGet` overload that accept $(LREF .Algebraic.Kind).
        alias trustedGet(Kind kind) = trustedGet!(AllowedTypes[kind]);
        /// ditto
        alias trustedGet(string kind) = trustedGet!(__traits(getMember, Kind, kind));
    }

    /++
    Gets an algebraic subset.

    Throws: Exception if the storage contains value of the type that isn't represented in the allowed type set of the requested algebraic.
    +/
    auto ref get(R : Algebraic!RetTypes, this This, RetTypes...)() return @property
        if (allSatisfy!(Contains!AllowedTypes, Algebraic!RetTypes.AllowedTypes))
    {
        static if (is(RetTypes == _Types))
            return this;
        else
        {
            import std.meta: staticIndexOf;
            import std.traits: CopyTypeQualifiers;
            alias RhsAllowedTypes = Algebraic!RetTypes.AllowedTypes;
            alias Ret = CopyTypeQualifiers!(This, Algebraic!RetTypes);
            // uint rhsTypeId;
            switch (_identifier_)
            {
                foreach (i, T; AllowedTypes)
                static if (staticIndexOf!(T, RhsAllowedTypes) >= 0)
                {
                    case i:
                        static if (is(T == void))
                            return (()@trusted => cast(Ret) Ret._void)();
                        else
                            return Ret(trustedGet!T);
                }
                default:
                    throw variantMemberException;
            }
        }
    }

    /// ditto
    template get(RetTypes...)
        if (RetTypes.length > 1)
    {
        ///
        auto ref get(this This)() return
        {
            return this.get!(Variant!RetTypes);
        }
    }

    version(mir_core_test)
    static if (_variant_test_)
    ///
    @safe pure @nogc
    unittest
    {
        alias Float = Variant!(float, double);
        alias Int = Variant!(long, int);
        alias Number = Variant!(Float.AllowedTypes, Int.AllowedTypes);

        Number number = 3.0;
        auto fp = number.get!Float;
        static assert(is(typeof(fp) == Float));
        assert(fp == 3.0);

        // type list overload
        number = 12L;
        auto integer = number.get!(int, long);
        static assert(is(typeof(integer) == Int));
        assert(integer == 12L);
    }

    static if (anySatisfy!(isTaggedType, _Types))
    {
        /// `get` overload that accept $(LREF .Algebraic.Kind).
        alias get(Kind kind) = get!(AllowedTypes[kind]);
        /// ditto
        alias get(string kind) = get!(__traits(getMember, Kind, kind));
    }

    private alias _ReflectionTypes = AllowedTypes[is(AllowedTypes[0] == typeof(null)) .. $];

    static if (_ReflectionTypes.length)
    this(this This, Args...)(auto ref Args args)
        if (Args.length && (Args.length > 1 || !isVariant!(Args[0])))
    {
        import std.traits: CopyTypeQualifiers;
        import core.lifetime: forward;

        template CanCompile(T)
        {
            alias Q = CopyTypeQualifiers!(This, T);
            enum CanCompile = __traits(compiles, new Q(forward!args));
        }

        alias TargetType = Filter!(CanCompile, _ReflectionTypes);
        static if (TargetType.length == 0)
            static assert(0, typeof(this).stringof ~ ".this: no types can be constructed with arguments " ~ Args.stringof);
        static assert(TargetType.length == 1, typeof(this).stringof ~ ".this: multiple types " ~ TargetType.stringof ~ " can be constructed with arguments " ~ Args.stringof);
        alias TT = TargetType[0];
        static if (is(TT == struct) || is(TT == union))
            this(CopyTypeQualifiers!(This, TT)(forward!args));
        else
            this(new CopyTypeQualifiers!(This, TT)(forward!args));
    }

    static if (_ReflectionTypes.length && allSatisfy!(isSimpleAggregateType, _ReflectionTypes))
    {
        static foreach (member; AllMembersRec!(_ReflectionTypes[0]))
        static if (
            member != "_ID_" &&
            member != "_identifier_" &&
            member != "_is" &&
            member != "_storage_" &&
            member != "_Storage_" &&
            member != "_variant_test_" &&
            member != "_void" &&
            member != "AllowedTypes" &&
            member != "get" &&
            member != "isNull" &&
            member != "kind" &&
            member != "Kind" &&
            member != "nullify" &&
            member != "opAssign" &&
            member != "opCast" &&
            member != "opCmp" &&
            member != "opEquals" &&
            member != "opPostMove" &&
            member != "toHash" &&
            member != "toString" &&
            member != "trustedGet" &&
            member != "deserializeFromAsdf" &&
            member != "deserializeFromIon" &&
            !(member.length >= 2 && member[0 .. 2] == "__"))
        static if (allSatisfy!(ApplyRight!(hasMember, member), _ReflectionTypes))
        static if (!anySatisfy!(ApplyRight!(isMemberType, member), _ReflectionTypes))
        static if (allSatisfy!(ApplyRight!(isSingleMember, member), _ReflectionTypes))
        static if (allSatisfy!(ApplyRight!(isPublic, member), _ReflectionTypes))
        {
            static if (allSatisfy!(ApplyRight!(hasField, member), _ReflectionTypes) && NoDuplicates!(staticMap!(ApplyRight!(memberTypeOf, member), _ReflectionTypes)).length == 1)
            {
                mixin(`ref ` ~ member ~q{()() inout return @trusted pure nothrow @nogc @property { return this.getMember!member; }});
            }
            else
            static if (allSatisfy!(ApplyRight!(templateOr!(hasField, isProperty), member), _ReflectionTypes))
            {
                mixin(`auto ref ` ~ member ~q{(this This, Args...)(auto ref Args args) @property { static if (args.length) { import core.lifetime: forward; return this.getMember!member = forward!args; } else return this.getMember!member;  }});
            }
            static if (allSatisfy!(ApplyRight!(templateNot!(templateOr!(hasField, isProperty)), member), _ReflectionTypes))
            {
                mixin(`auto ref ` ~ member ~q{(this This, Args...)(auto ref Args args) { static if (args.length) { import core.lifetime: forward; return this.getMember!member(forward!args); } else return this.getMember!member;  }});
            }
        }
    }

    ///
    ref opAssign(RhsTypes...)(Algebraic!RhsTypes rhs) return @trusted
        if (RhsTypes.length < AllowedTypes.length && allSatisfy!(Contains!AllowedTypes, Algebraic!RhsTypes.AllowedTypes))
    {
        import core.lifetime: forward;
        static if (anySatisfy!(hasElaborateDestructor, AllowedTypes))
            this.__dtor();
        __ctor(forward!rhs);
        return this;
    }

    static foreach (int i, T; AllowedTypes)
    {
        /// Zero cost always nothrow `get` alternative
        auto ref trustedGet(E)() @trusted @property return inout nothrow
            if (is(E == T))
        {
            assert (i == _identifier_);
            static if (is(T == typeof(null)))
                return null;
            else
            static if (is(T == void))
                return;
            else
                return _storage_.payload[i];
        }

        /++
        Throws: Exception if the storage contains value of other type
        +/
        auto ref get(E)() @property return inout
            if (is(E == T))
        {
            import mir.utility: _expect;
            static if (AllowedTypes.length > 1)
            {
                if (_expect(i != _identifier_, false))
                {
                    throw variantException;
                }
            }
            return trustedGet!T;
        }

        /++
        Checks if the storage stores an allowed type.
        +/
        bool _is(E)() const @property nothrow @nogc
            if (is(E == T))
        {
            return _identifier_ == i;
        }

        static if (is(T == void))
        {
            /// Defined if `AllowedTypes` contains `void`
            static Algebraic _void()
            {
                Algebraic ret;
                ret._storage_ = () {
                    import core.lifetime: forward;
                    mixin(`_Storage_ ret = { _member_` ~ i.stringof ~ ` : _Void!().init };`);
                    return ret;
                } ();
                ret._identifier_ = i;
                return ret;
            }
        }
        else
        {
            ///
            static if (isCopyable!(const T) || is(Unqual!T == T))
            this(T value)
            {
                import core.lifetime: forward;
                static if (is(T == typeof(null)))
                    auto rhs = _Null!()();
                else
                    alias rhs = forward!value;

                static if (__VERSION__ < 2094 && anySatisfy!(hasElaborateCopyConstructor, AllowedTypes))
                {
                    _storage_.bytes = () @trusted {
                        auto ret =  _StorageI!i(rhs);
                        return ret.bytes;
                    } ();
                }
                else
                {
                    _storage_ = () {
                        mixin(`_Storage_ ret = { _member_` ~ i.stringof ~ ` : rhs };`);
                        return ret;
                    } ();
                }
                static if (_Payload.length > 1)
                    _identifier_ = i;
            }

            /// ditto
            static if (isCopyable!(const T))
            this(const T value) const
            {
                static if (is(T == typeof(null)))
                    auto rhs = _Null!()();
                else
                    alias rhs = value;
                static if (__VERSION__ < 2094 && anySatisfy!(hasElaborateCopyConstructor, AllowedTypes))
                {
                    _storage_.bytes = () const @trusted {
                        auto ret =  const _StorageI!i(rhs);
                        return ret.bytes;
                    } ();
                }
                else
                {
                    _storage_ = () {
                        mixin(`const _Storage_ ret = { _member_` ~ i.stringof ~ ` : rhs };`);
                        return ret;
                    } ();
                }
                static if (_Payload.length > 1)
                    _identifier_ = i;
            }

            /// ditto
            static if (isCopyable!(immutable T))
            this(immutable T value) immutable
            {
                static if (is(T == typeof(null)))
                    auto rhs = _Null!()();
                else
                    alias rhs = value;
                static if (__VERSION__ < 2094 && anySatisfy!(hasElaborateCopyConstructor, AllowedTypes))
                {
                    _storage_.bytes = () const @trusted {
                        auto ret = immutable  _StorageI!i(rhs);
                        return ret.bytes;
                    } ();
                }
                else
                {
                    _storage_ = () {
                        mixin(`immutable _Storage_ ret = { _member_` ~ i.stringof ~ ` : rhs };`);
                        return ret;
                    } ();
                }
                static if (_Payload.length > 1)
                    _identifier_ = i;
            }

            static if (__traits(compiles, (ref T a, ref T b) { moveEmplace(a, b); }))
            ///
            ref opAssign(T rhs) return @trusted
            {
                import core.lifetime: forward;
                static if (anySatisfy!(hasElaborateDestructor, AllowedTypes))
                    this.__dtor();
                __ctor(forward!rhs);
                return this;
            }

            /++
            +/
            auto opEquals()(auto ref const T rhs) const
            {
                static if (AllowedTypes.length > 1)
                    if (_identifier_ != i)
                        return false;
                return trustedGet!T == rhs;
            } 

            /++
            +/
            auto opCmp()(auto ref const T rhs) const
            {
                import mir.internal.utility: isFloatingPoint;
                static if (AllowedTypes.length > 1)
                    if (auto d = int(_identifier_) - int(i))
                        return d;
                static if (__traits(compiles, __cmp(trustedGet!T, rhs)))
                    return __cmp(trustedGet!T, rhs);
                else
                static if (__traits(hasMember, T, "opCmp") && !is(T == U*, U))
                    return trustedGet!T.opCmp(rhs);
                else
                static if (isFloatingPoint!T)
                    return trustedGet!T == rhs ? 0 : trustedGet!T - rhs;
                else
                    return trustedGet!T < rhs ? -1 :
                        trustedGet!T > rhs ? +1 : 0;
            }

            static if (is(Unqual!T == bool))
            {
                private alias contains = Contains!AllowedTypes;
                static if (contains!long && !contains!int)
                {
                    this(int value)
                    {
                        this(long(value));
                    }

                    this(int value) const
                    {
                        this(long(value));
                    }

                    this(int value) immutable
                    {
                        this(long(value));
                    }

                    ref opAssign(int rhs) return @trusted
                    {
                        return opAssign(long(rhs));
                    }

                    auto opEquals()(int rhs) const
                    {
                        return opEquals(long(rhs));
                    } 

                    auto opCmp()(int rhs) const
                    {
                        return opCmp(long(rhs));
                    }
                }

                static if (contains!ulong && !contains!uint)
                {
                    this(uint value)
                    {
                        this(ulong(value));
                    }

                    this(uint value) const
                    {
                        this(ulong(value));
                    }

                    this(uint value) immutable
                    {
                        this(ulong(value));
                    }

                    ref opAssign(uint rhs) return @trusted
                    {
                        return opAssign(ulong(rhs));
                    }

                    auto opEquals()(uint rhs) const
                    {
                        return opEquals(ulong(rhs));
                    } 

                    auto opCmp()(uint rhs) const
                    {
                        return opCmp(ulong(rhs));
                    }
                }
            }
        }
    }

    static if (anySatisfy!(isErr, _Types))
    {
        /++
        Determines if the variant holds value of some none-$(LREF isVariant) type.
        The property is avaliable only for $(ResultVariant)
        +/
        bool isOk() @safe pure nothrow @nogc const @property
        {
            switch (_identifier_)
            {
                static foreach (i, T; AllowedTypes)
                {
                    case i:
                        return !.isErr!T;
                }
                default: assert(0);
            }
        }
    }
}

/++
Constructor and methods propagation.
+/
version(mir_core_test)
unittest
{
    static struct Base
    {
        double d;
    }

    static class C
    {
        // alias this members are supported 
        Base base;
        alias base this;

        int a;
        private string _b;

    @safe pure nothrow @nogc:

        string b() const @property { return _b; }
        void b(string b) @property { _b = b; }

        int retArg(int v) { return v; }

        this(int a, string b)
        {
            this.a = a;
            this._b = b;
        }
    }

    static struct S
    {
        string b;
        int a;

        double retArg(double v) { return v; }

        // alias this members are supported 
        Base base;
        alias base this;
    }

    static void inc(ref int a) { a++; }

    alias V = Nullable!(C, S); // or Variant!

    auto v = V(2, "str");
    assert(v._is!C);
    assert(v.a == 2);
    assert(v.b == "str");
    // members are returned by reference if possible
    inc(v.a);
    assert(v.a == 3);
    v.b = "s";
    assert(v.b == "s");
    // alias this members are supported 
    v.d = 10;
    assert(v.d == 10);
    // method call support
    assert(v.retArg(100)._is!int);
    assert(v.retArg(100) == 100);

    v = V("S", 5);
    assert(v._is!S);
    assert(v.a == 5);
    assert(v.b == "S");
    // members are returned by reference if possible
    inc(v.a);
    assert(v.a == 6);
    v.b = "s";
    assert(v.b == "s");
    // alias this members are supported 
    v.d = 15;
    assert(v.d == 15);
    // method call support
    assert(v.retArg(300)._is!double);
    assert(v.retArg(300) == 300.0);

}

// test CTFE
unittest
{
    static struct S { string s;}
    alias V = Nullable!(double, S);
    enum a = V(1.9);
    static assert (a == 1.9);
    enum b = V(S("str"));
    static assert(b == S("str"));
    static auto foo(int r)
    {
        auto s = V(S("str"));
        s = r;
        return s;
    }

    static assert(foo(3) == 3);
    static auto bar(int r)
    {
        auto s = V(S("str"));
        s = r;
        return s.visit!((double d) => d, (_)=> 0.0)();
    }
    assert(bar(3) == 3);
    static assert(bar(3) == 3);

    static auto bar3(int r)
    {
        auto s = V(S("str"));
        s = r;
        return s.match!((double d) => d, (_)=> "3")();
    }
    assert(bar(3) == 3);
    static assert(bar(3) == 3);
}

@safe pure @nogc nothrow
version(mir_core_test) unittest
{
    import core.stdc.string: memcmp;

    static struct C(ubyte payloadSize, bool isPOD, bool hasToHash = true, bool hasOpEquals = true)
    {
        ubyte[payloadSize] _payload;

    const:

        static if (!isPOD)
        {
            this(this) {}
            ~this() {}
        }

    @safe pure nothrow @nogc:


    static if (hasToHash)
        size_t toHash() { return hashOf(_payload); }

    static if (hasOpEquals)
        auto opEquals(ref const typeof(this) rhs) @trusted { return memcmp(_payload.ptr, rhs._payload.ptr, _payload.length); }
        auto opCmp(ref const typeof(this) rhs) { return _payload == rhs._payload; }
    }

    static foreach (size1; [1, 2, 4, 8, 10, 16, 20])
    static foreach (size2; [1, 2, 4, 8, 10, 16, 20])
    static if (size1 != size2)
    static foreach (isPOD; [true, false])
    static foreach (hasToHash; [true, false])
    static foreach (hasOpEquals; [true, false])
    {{
        alias T = Variant!(
                double,
                C!(size1, isPOD, hasToHash, hasOpEquals),
                C!(size2, isPOD, hasToHash, hasOpEquals));
        // static assert (__traits(compiles, T.init <= T.init));
    }}
}

// const propogation
@safe pure nothrow @nogc
version(mir_core_test) unittest
{
    static struct S1 { immutable(ubyte)* value; }
    static struct C1 { immutable(uint)* value; }

    alias V = Variant!(S1, C1);
    const V v = S1();
    assert(v._is!S1);
    V w = v;
    w = v;

    immutable f = V(S1());
    auto t = immutable V(S1());
    // auto j = immutable V(t);
    // auto i = const V(t);
}

// ditto
@safe pure nothrow @nogc
version(mir_core_test) unittest
{
    static struct S2 {
        uint* value;
        this(return ref scope const typeof(this) rhs) {}
        ref opAssign(typeof(this) rhs) return { return this; }
    }
    static struct C2 { const(uint)* value; }

    alias V = Variant!(S2, C2);
    const V v = S2();
    V w = v;
    w = S2();
    w = v;
    w = cast(const) V.init;

    const f = V(S2());
    auto t = const V(f);
}

@safe pure nothrow @nogc
version(mir_core_test) unittest
{
    static struct S3 {
        uint* value;
        this(return ref scope typeof(this) rhs) {}
        this(return ref scope const typeof(this) rhs) const {}
        this(return ref scope immutable typeof(this) rhs) immutable {}
    }
    static struct C3 { immutable(uint)* value; }

    S3 s;
    S3 r = s;
    r = s;
    r = S3.init;

    alias V = Variant!(S3, C3);
    V v = S3();
    V w = v;
    w = S3();
    w = V.init;
    w = v;

    immutable V e = S3();
    auto t = immutable V(S3());
    auto j = const V(t);
    auto h = t;

    immutable V l = C3();
    auto g = immutable V(C3());
}

@safe pure nothrow @nogc
version(mir_core_test) unittest
{
    static struct S4 {
        uint* value;
        this(return ref scope const typeof(this) rhs) pure immutable {}
    }
    static struct C4 { immutable(uint)* value; }


    S4 s;
    S4 r = s;
    r = s;
    r = S4.init;

    alias V = Variant!(S4, C4);
    V v = S4();
    V w = v;
    w = S4();
    w = V.init;
    w = v;

    {
        const V e = S4();
        const k = w;
        auto t = const V(k);
        auto j = immutable V(k);
    }

    immutable V e = S4();
    immutable k = w;
    auto t = immutable V(S4());
    auto j = const V(t);
    auto h = t;

    immutable V l = C4();
    import core.lifetime;
    auto g = immutable V(C4());
    immutable b = immutable V(s);
}

@safe pure nothrow @nogc
version(mir_core_test) unittest
{
    import core.lifetime: move;

    static struct S5 {
        immutable(uint)* value;
        this(return ref scope typeof(this) rhs) {}
        this(return ref scope const typeof(this) rhs) immutable {}
    }
    static struct C5 { immutable(uint)* value; }

    S5 s;
    S5 r = s;
    r = s;
    r = S5.init;

    alias V = Variant!(S5, C5);
    V v = S5();
    V w = v;
    w = S5();
    w = V.init;
    w = v;

    immutable V e = S5();
    immutable f = V(S5());
    immutable k = w;
    auto t = immutable V(S5());
    auto j = const V(t);
    auto h = t;

    immutable V l = C5();
    import core.lifetime;
    immutable n = w.move;
    auto g = immutable V(C5());
    immutable b = immutable V(s);
}

@safe pure nothrow @nogc
version(mir_core_test) unittest
{
    static struct S {
        uint* value;
        this(this) @safe pure nothrow @nogc {}
        // void opAssign(typeof(this) rhs) {}
    }
    static struct C { const(uint)* value; }

    S s;
    S r = s;
    r = s;
    r = S.init;

    alias V = Variant!(S, C);
    V v = S();
    V w = v;
    w = S();
    w = V.init;
    w = v;
}

/++
Applies a delegate or function to the given Variant depending on the held type,
ensuring that all types are handled by the visiting functions.
+/
alias visit(visitors...) = visitImpl!(naryFun!visitors, Exhaustive.compileTime, false);

///
@safe pure @nogc nothrow
version(mir_core_test) unittest
{
    alias Number = Variant!(int, double);

    Number x = 23;
    Number y = 1.0;

    assert(x.visit!((int v) => true, (float v) => false));
    assert(y.visit!((int v) => false, (float v) => true));
}

///
@safe pure @nogc
version(mir_core_test) unittest
{
    alias Number = Nullable!(int, double);

    Number z = null; // default
    Number x = 23;
    Number y = 1.0;

    () nothrow {
        assert(x.visit!((int v) => true, (float v) => false));
        assert(y.visit!((int v) => false, (v) => true));
        assert(z.visit!((typeof(null) v) => true, (v) => false));
    } ();

    auto xx = x.get;
    static assert (is(typeof(xx) == Variant!(int, double)));
    assert(xx.visit!((int v) => v, (float v) => 0) == 23);
    assert(xx.visit!((ref v) => v) == 23);

    x = null;
    y.nullify;

    assert(x.isNull);
    assert(y.isNull);
    assert(z.isNull);
    assert(z == y);
}

/// Array primitives propagation
@safe pure version(mir_core_test) unittest
{
    Variant!(long[], double[]) array;
    array = new long[3];
    array[2] = 100;
    assert(array == [0L, 0, 100]);
    assert(array.length == 3);
    assert(array[2] == 100);
    array.length = 4;
    assert(array == [0L, 0, 100, 0]);
    array = array[2 .. 3];    
    assert(array.length == 1);
    assert(array[0] == 100);
    array[0] = 10.Variant!(long, double);
    assert(array[0] == 10);
}

/++
Checks $(LREF .Algebraic.toString) and `void`
$(LREF Algerbraic)`.toString` requries `mir-algorithm` package
+/
@safe pure nothrow version(mir_core_test) unittest
{
    import mir.conv: to;
    enum MIR_ALGORITHM = __traits(compiles, { import mir.format; });

    alias visitorHandler = visit!(
        (typeof(null)) => "NULL",
        () => "VOID",
        (ref r) {r += 1;}, // returns void
    );

    alias secondOrderVisitorHandler = visit!(
        () => "SO VOID", // void => to "RV VOID"
        (str) => str, // string to => it self
    );

    alias V = Nullable!(void, int);
    static assert(is(V == Variant!(typeof(null), void, int)));

    V variant;

    assert(secondOrderVisitorHandler(visitorHandler(variant)) == "NULL");
    assert(variant.to!string == "null");

    variant = V._void;
    assert(variant._is!void);
    assert(is(typeof(variant.get!void()) == void));

    assert(secondOrderVisitorHandler(visitorHandler(variant)) == "VOID");
    assert(variant.to!string == "void");

    variant = 5;

    assert(secondOrderVisitorHandler(visitorHandler(variant)) == "SO VOID");
    assert(variant == 6);
    assert(variant.to!string == (MIR_ALGORITHM ? "6" : "int"));
}

version(mir_core_test)
unittest
{
    Nullable!() value;
    alias visitHandler = visit!((typeof(null)) => null, err);
    auto d = visitHandler(value);
    assert(d == value);
}

/++
Behaves as $(LREF visit) but doesn't enforce at compile time that all types can be handled by the visiting functions.
Throws: Exception if `naryFun!visitors` can't be called with provided arguments
+/
alias tryVisit(visitors...) = visitImpl!(naryFun!visitors, Exhaustive.exception, false);

///
@safe pure @nogc
version(mir_core_test) unittest
{
    alias Number = Variant!(int, double);

    Number x = 23;

    assert(x.tryVisit!((int v) => true));
}

/++
Behaves as $(LREF visit) but doesn't enforce at compile time that all types can be handled by the visiting functions.
Returns: nullable variant, null value is used if `naryFun!visitors` can't be called with provided arguments.
+/
alias optionalVisit(visitors...) = visitImpl!(naryFun!visitors, Exhaustive.nullable, false);

///
@safe pure @nogc nothrow
version(mir_core_test) unittest
{
    static struct S { int a; }

    Variant!(S, double) variant;

    alias optionalVisitInst = optionalVisit!((ref value) => value + 0);

    // do nothing because of variant isn't initialized
    Nullable!double result = optionalVisitInst(variant);
    assert(result.isNull);

    variant = S(2);
    // do nothing because of lambda can't compile
    result = optionalVisitInst(variant);
    assert(result == null);

    variant = 3.0;
    result = optionalVisitInst(variant);
    assert (result == 3.0);
}

/++
Behaves as $(LREF visit) but doesn't enforce at compile time that all types can be handled by the visiting functions.
Returns: optionally nullable type, null value is used if `naryFun!visitors` can't be called with provided arguments.
+/
alias autoVisit(visitors...) = visitImpl!(naryFun!visitors, Exhaustive.auto_, false);


/++
Applies a delegate or function to the given arguments depending on the held type,
ensuring that all types are handled by the visiting functions.

The handler supports multiple dispatch or multimethods: a feature of handler in which
a function or method can be dynamically dispatched based on the run time (dynamic) type or,
in the more general case, some other attribute of more than one of its arguments.

Fuses algebraic types on return.

See_also: $(HTTPS en.wikipedia.org/wiki/Multiple_dispatch, Multiple dispatch)
+/
alias match(visitors...) = visitImpl!(naryFun!visitors, Exhaustive.compileTime, true);

///
version(mir_core_test)
unittest
{
    static struct Asteroid { uint size; }
    static struct Spaceship { uint size; }
    alias SpaceObject = Variant!(Asteroid, Spaceship);

    alias collideWith = match!(
        (Asteroid x, Asteroid y) => "a/a",
        (Asteroid x, Spaceship y) => "a/s",
        (Spaceship x, Asteroid y) => "s/a",
        (Spaceship x, Spaceship y) => "s/s",
    );

    import mir.utility: min;

    // Direct access of a member in case of all algebraic types has this member
    alias oops = (a, b) => (a.size + b.size) > 3 && min(a.size, b.size) > 1;

    alias collide = (x, y) => oops(x, y) ? "big-boom" : collideWith(x, y);

    auto ea = Asteroid(1);
    auto es = Spaceship(2);
    auto oa = SpaceObject(ea);
    auto os = SpaceObject(es);

    // Asteroid-Asteroid
    assert(collide(ea, ea) == "a/a");
    assert(collide(ea, oa) == "a/a");
    assert(collide(oa, ea) == "a/a");
    assert(collide(oa, oa) == "a/a");

    // Asteroid-Spaceship
    assert(collide(ea, es) == "a/s");
    assert(collide(ea, os) == "a/s");
    assert(collide(oa, es) == "a/s");
    assert(collide(oa, os) == "a/s");

    // Spaceship-Asteroid
    assert(collide(es, ea) == "s/a");
    assert(collide(es, oa) == "s/a");
    assert(collide(os, ea) == "s/a");
    assert(collide(os, oa) == "s/a");

    // Spaceship-Spaceship
    assert(collide(es, es) == "big-boom");
    assert(collide(es, os) == "big-boom");
    assert(collide(os, es) == "big-boom");
    assert(collide(os, os) == "big-boom");
}

/++
Behaves as $(LREF match) but doesn't enforce at compile time that all types can be handled by the visiting functions.
Throws: Exception if `naryFun!visitors` can't be called with provided arguments

Fuses algebraic types on return.
+/
alias tryMatch(visitors...) = visitImpl!(naryFun!visitors, Exhaustive.exception, true);

///
version(mir_core_test)
unittest
{
    import std.exception: assertThrown;
    static struct Asteroid { uint size; }
    static struct Spaceship { uint size; }
    alias SpaceObject = Variant!(Asteroid, Spaceship);

    alias collideWith = tryMatch!(
        (Asteroid x, Asteroid y) => "a/a",
        // No visitor for A/S pair 
        // (Asteroid x, Spaceship y) => "a/s",
        (Spaceship x, Asteroid y) => "s/a",
        (Spaceship x, Spaceship y) => "s/s",
    );

    import mir.utility: min;
    // Direct access of a member in case of all algebraic types has this member
    alias oops = (a, b) => (a.size + b.size) > 3 && min(a.size, b.size) > 1;

    alias collide = (x, y) => oops(x, y) ? "big-boom" : collideWith(x, y);

    auto ea = Asteroid(1);
    auto es = Spaceship(2);
    auto oa = SpaceObject(ea);
    auto os = SpaceObject(es);

    // Asteroid-Asteroid
    assert(collide(ea, ea) == "a/a");
    assert(collide(ea, oa) == "a/a");
    assert(collide(oa, ea) == "a/a");
    assert(collide(oa, oa) == "a/a");

    // Asteroid-Spaceship
    assertThrown!Exception(collide(ea, es));
    assertThrown!Exception(collide(ea, os));
    assertThrown!Exception(collide(oa, es));
    assertThrown!Exception(collide(oa, os));

    // can deduce the type based on other return values
    static assert(is(typeof(collide(ea, os)) == string));
    static assert(is(typeof(collide(oa, es)) == string));
    static assert(is(typeof(collide(oa, os)) == string));

    // Also allows newer compilers to detect combinations which always throw an exception
    static if (is(typeof(collideWith(ea, es)) == noreturn))
    {
        static assert(is(typeof(collide(ea, es)) == string));
    }
    else
    {
        // not enough information to deduce the type from (ea, es) pair
        static assert(is(typeof(collide(ea, es)) == void));
    }

    // Spaceship-Asteroid
    assert(collide(es, ea) == "s/a");
    assert(collide(es, oa) == "s/a");
    assert(collide(os, ea) == "s/a");
    assert(collide(os, oa) == "s/a");

    // Spaceship-Spaceship
    assert(collide(es, es) == "big-boom");
    assert(collide(es, os) == "big-boom");
    assert(collide(os, es) == "big-boom");
    assert(collide(os, os) == "big-boom");
}

/++
Behaves as $(LREF match) but doesn't enforce at compile time that all types can be handled by the visiting functions.
Returns: nullable variant, null value is used if `naryFun!visitors` can't be called with provided arguments.

Fuses algebraic types on return.
+/
alias optionalMatch(visitors...) = visitImpl!(naryFun!visitors, Exhaustive.nullable, true);

///
version(mir_core_test)
unittest
{
    static struct Asteroid { uint size; }
    static struct Spaceship { uint size; }
    alias SpaceObject = Variant!(Asteroid, Spaceship);

    alias collideWith = optionalMatch!(
        (Asteroid x, Asteroid y) => "a/a",
        // No visitor for A/S pair 
        // (Asteroid x, Spaceship y) => "a/s",
        (Spaceship x, Asteroid y) => "s/a",
        (Spaceship x, Spaceship y) => "s/s",
    );

    import mir.utility: min;
    // Direct access of a member in case of all algebraic types has this member
    alias oops = (a, b) => (a.size + b.size) > 3 && min(a.size, b.size) > 1;

    alias collide = (x, y) => oops(x, y) ? "big-boom".nullable : collideWith(x, y);

    auto ea = Asteroid(1);
    auto es = Spaceship(2);
    auto oa = SpaceObject(ea);
    auto os = SpaceObject(es);

    // Asteroid-Asteroid
    assert(collide(ea, ea) == "a/a");
    assert(collide(ea, oa) == "a/a");
    assert(collide(oa, ea) == "a/a");
    assert(collide(oa, oa) == "a/a");

    // Asteroid-Spaceship
    // assert(collide(ea, es).isNull);  // Compiler error: incompatible types
    assert(collideWith(ea, es).isNull); // OK
    assert(collide(ea, os).isNull);
    assert(collide(oa, es).isNull);
    assert(collide(oa, os).isNull);


    // Spaceship-Asteroid
    assert(collide(es, ea) == "s/a");
    assert(collide(es, oa) == "s/a");
    assert(collide(os, ea) == "s/a");
    assert(collide(os, oa) == "s/a");

    // Spaceship-Spaceship
    assert(collide(es, es) == "big-boom");
    assert(collide(es, os) == "big-boom");
    assert(collide(os, es) == "big-boom");
    assert(collide(os, os) == "big-boom");

    // check types  

    static assert(!__traits(compiles, collide(Asteroid.init, Spaceship.init)));
    static assert(is(typeof(collideWith(Asteroid.init, Spaceship.init)) == Nullable!()));

    static assert(is(typeof(collide(Asteroid.init, Asteroid.init)) == Nullable!string));
    static assert(is(typeof(collide(Asteroid.init, SpaceObject.init)) == Nullable!string));
    static assert(is(typeof(collide(SpaceObject.init, Asteroid.init)) == Nullable!string));
    static assert(is(typeof(collide(SpaceObject.init, SpaceObject.init)) == Nullable!string));
    static assert(is(typeof(collide(SpaceObject.init, Spaceship.init)) == Nullable!string));
    static assert(is(typeof(collide(Spaceship.init, Asteroid.init)) == Nullable!string));
    static assert(is(typeof(collide(Spaceship.init, SpaceObject.init)) == Nullable!string));
    static assert(is(typeof(collide(Spaceship.init, Spaceship.init)) == Nullable!string));
}

/++
Behaves as $(LREF match) but doesn't enforce at compile time that all types can be handled by the visiting functions.
Returns: optionally nullable type, null value is used if `naryFun!visitors` can't be called with provided arguments.

Fuses algebraic types on return.
+/
alias autoMatch(visitors...) = visitImpl!(naryFun!visitors, Exhaustive.auto_, true);

///
version(mir_core_test)
unittest
{
    static struct Asteroid { uint size; }
    static struct Spaceship { uint size; }
    alias SpaceObject = Variant!(Asteroid, Spaceship);

    alias collideWith = autoMatch!(
        (Asteroid x, Asteroid y) => "a/a",
        // No visitor for A/S pair 
        // (Asteroid x, Spaceship y) => "a/s",
        (Spaceship x, Asteroid y) => "s/a",
        (Spaceship x, Spaceship y) => "s/s",
    );

    import mir.utility: min;
    // Direct access of a member in case of all algebraic types has this member
    alias oops = (a, b) => (a.size + b.size) > 3 && min(a.size, b.size) > 1;

    import mir.conv: to;
    alias collide = (x, y) => oops(x, y) ? "big-boom".to!(typeof(collideWith(x, y))) : collideWith(x, y);

    auto ea = Asteroid(1);
    auto es = Spaceship(2);
    auto oa = SpaceObject(ea);
    auto os = SpaceObject(es);

    // Asteroid-Asteroid
    assert(collide(ea, ea) == "a/a");
    assert(collide(ea, oa) == "a/a");
    assert(collide(oa, ea) == "a/a");
    assert(collide(oa, oa) == "a/a");

    // Asteroid-Spaceship
    // assert(collide(ea, es).isNull);  // Compiler error: incompatible types
    assert(collideWith(ea, es).isNull); // OK
    assert(collide(ea, os).isNull);
    assert(collide(oa, es).isNull);
    assert(collide(oa, os).isNull);

    // Spaceship-Asteroid
    assert(collide(es, ea) == "s/a");
    assert(collide(es, oa) == "s/a");
    assert(collide(os, ea) == "s/a");
    assert(collide(os, oa) == "s/a");

    // Spaceship-Spaceship
    assert(collide(es, es) == "big-boom");
    assert(collide(es, os) == "big-boom");
    assert(collide(os, es) == "big-boom");
    assert(collide(os, os) == "big-boom");

    // check types  

    static assert(!__traits(compiles, collide(Asteroid.init, Spaceship.init)));
    static assert(is(typeof(collideWith(Asteroid.init, Spaceship.init)) == Nullable!()));

    static assert(is(typeof(collide(Asteroid.init, Asteroid.init)) == string));
    static assert(is(typeof(collide(SpaceObject.init, Asteroid.init)) == string));
    static assert(is(typeof(collide(Spaceship.init, Asteroid.init)) == string));
    static assert(is(typeof(collide(Spaceship.init, SpaceObject.init)) == string));
    static assert(is(typeof(collide(Spaceship.init, Spaceship.init)) == string));

    static assert(is(typeof(collide(Asteroid.init, SpaceObject.init)) == Nullable!string));
    static assert(is(typeof(collide(SpaceObject.init, SpaceObject.init)) == Nullable!string));
    static assert(is(typeof(collide(SpaceObject.init, Spaceship.init)) == Nullable!string));
}

/++
Applies a member handler to the given Variant depending on the held type,
ensuring that all types are handled by the visiting handler.
+/
alias getMember(string member) = visitImpl!(getMemberHandler!member, Exhaustive.compileTime, false);

///
@safe pure @nogc nothrow
version(mir_core_test) unittest
{
    static struct S { auto bar(int a) { return a; } enum boolean = true; }
    static struct C { alias bar = (double a) => a * 2; enum boolean = false; }

    alias V = Variant!(S, C);

    V x = S();
    V y = C();

    static assert(is(typeof(x.getMember!"bar"(2)) == Variant!(int, double)));
    assert(x.getMember!"bar"(2) == 2);
    assert(y.getMember!"bar"(2) != 4);
    assert(y.getMember!"bar"(2) == 4.0);

    // direct implementation
    assert(x.bar(2) == 2);
    assert(y.bar(2) != 4);
    assert(y.bar(2) == 4.0);
    assert(x.boolean);
    assert(!y.boolean);
}

/++
Applies a member handler to the given Variant depending on the held type,
ensuring that all types are handled by the visiting handler.

Fuses algebraic types on return.
+/
alias matchMember(string member) = visitImpl!(getMemberHandler!member, Exhaustive.compileTime, true);

///
@safe pure @nogc nothrow
version(mir_core_test) unittest
{
    static struct S
    {
        Nullable!int m;
    }

    static struct C
    {
        Variant!(float, double) m;
    }

    alias V = Variant!(S, C);

    V x = S(2.nullable);
    V y = C(Variant!(float, double)(4.0));

    // getMember returns an algebraic of algebaics
    static assert(is(typeof(x.getMember!"m") == Variant!(Variant!(float, double), Nullable!int)));
    // matchMember returns a fused algebraic
    static assert(is(typeof(x.matchMember!"m") == Nullable!(int, float, double)));
    assert(x.matchMember!"m" == 2);
    assert(y.matchMember!"m" != 4);
    assert(y.matchMember!"m" == 4.0);
}

/++
Behaves as $(LREF getMember) but doesn't enforce at compile time that all types can be handled by the member visitor.
Throws: Exception if member can't be accessed with provided arguments
+/
alias tryGetMember(string member) = visitImpl!(getMemberHandler!member, Exhaustive.exception, false);

///
@safe pure @nogc
version(mir_core_test) unittest
{
    static struct S { int bar(int a) { return a; }}
    static struct C { alias Bar = (double a) => a * 2; }

    alias V = Variant!(S, C);

    V x = S();
    V y = C();

    static assert(is(typeof(x.tryGetMember!"bar"(2)) == int));
    static assert(is(typeof(y.tryGetMember!"Bar"(2)) == double));
    assert(x.tryGetMember!"bar"(2) == 2);
    assert(y.tryGetMember!"Bar"(2) == 4.0);
}

///
@safe pure @nogc nothrow
version(mir_core_test) unittest
{
    alias Number = Variant!(int, double);

    Number x = Number(23);
    Number y = Number(1.0);

    assert(x.visit!((int v) => true, (float v) => false));
    assert(y.visit!((int v) => false, (float v) => true));
}

/++
Behaves as $(LREF matchMember) but doesn't enforce at compile time that all types can be handled by the member visitor.
Throws: Exception if member can't be accessed with provided arguments

Fuses algebraic types on return.
+/
alias tryMatchMember(string member) = visitImpl!(getMemberHandler!member, Exhaustive.exception, true);

/++
Behaves as $(LREF getMember) but doesn't enforce at compile time that all types can be handled by the member visitor.
Returns: nullable variant, null value is used if the member can't be called with provided arguments.
+/
alias optionalGetMember(string member) = visitImpl!(getMemberHandler!member, Exhaustive.nullable, false);

/++
Behaves as $(LREF matchMember) but doesn't enforce at compile time that all types can be handled by the member visitor.
Returns: nullable variant, null value is used if the member can't be called with provided arguments.

Fuses algebraic types on return.
+/
alias optionalMatchMember(string member) = visitImpl!(getMemberHandler!member, Exhaustive.nullable, true);

/++
Behaves as $(LREF getMember) but doesn't enforce at compile time that all types can be handled by the member visitor.
Returns: optionally nullable type, null value is used if the member can't be called with provided arguments.
+/
alias autoGetMember(string member) = visitImpl!(getMemberHandler!member, Exhaustive.auto_, false);

/++
Behaves as $(LREF matchMember) but doesn't enforce at compile time that all types can be handled by the member visitor.
Returns: optionally nullable type, null value is used if the member can't be called with provided arguments.

Fuses algebraic types on return.
+/
alias autoMatchMember(string member) = visitImpl!(getMemberHandler!member, Exhaustive.auto_, true);

private template getMemberHandler(string member)
{
    ///
    auto ref getMemberHandler(V, Args...)(ref V value, auto ref Args args)
    {
        static if (Args.length == 0)
        {
            return __traits(getMember, value, member);
        }
        else
        {
            import core.lifetime: forward;
            import mir.reflection: hasField;
            static if (hasField!(V, member) && Args.length == 1)
                return __traits(getMember, value, member) = forward!args;
            else
                return __traits(getMember, value, member)(forward!args);
        }
    }
}

private template VariantReturnTypes(T...)
{
    import std.meta: staticMap;

    alias VariantReturnTypes = NoDuplicates!(staticMap!(TryRemoveConst, T));
}

private enum Exhaustive
{
    compileTime,
    exception,
    nullable,
    auto_,
}

private template nextVisitor(T, alias visitor, alias arg)
{
    static if (is(T == void))
    {
        alias nextVisitor = visitor;
    }
    else
    auto ref nextVisitor(NextArgs...)(auto ref NextArgs nextArgs)
    {
        import core.lifetime: forward;

        static if (__traits(isRef,  arg))
            return visitor(arg.trustedGet!T, forward!nextArgs);
        else
        static if (is(typeof(move(arg.trustedGet!T))))
            return visitor(move(arg.trustedGet!T), forward!nextArgs);
        else
            return visitor((() => arg.trustedGet!T)(), forward!nextArgs);
    }
}

private template nextVisitor(alias visitor, alias arg)
{
    auto ref nextVisitor(NextArgs...)(auto ref NextArgs nextArgs)
    {
        import core.lifetime: forward;
        return visitor(forward!arg, forward!nextArgs);
    }
}

private template visitThis(alias visitor, Exhaustive nextExhaustive)
{
    template visitThis(T)
    {
        auto ref visitThis(Args...)(auto ref Args args)
        {
            import core.lifetime: forward;
            return .visitImpl!(nextVisitor!(T, visitor, forward!(args[0])), nextExhaustive, true)(forward!(args[1 .. $]));
        }
    }
}

private template visitLast(alias visitor)
{
    template visitLast(T)
    {
        static if (is(T == void))
        {
            auto ref visitLast(Args...)(auto ref Args args)
            {
                import core.lifetime: forward;
                return visitor(forward!(args[1 .. $]));
            }
        }
        else
        {
            auto ref visitLast(Args...)(auto ref Args args)
            {
                import core.lifetime: forward, move;
                static if (__traits(isRef,  args[0]))
                    return visitor(args[0].trustedGet!T, forward!(args[1 .. $]));
                else
                static if (is(typeof(move(args[0].trustedGet!T))))
                    return visitor(move(args[0].trustedGet!T), forward!(args[1 .. $]));
                else
                    return visitor((() => args[0].trustedGet!T)(), forward!(args[1 .. $]));
            }
        }
    }
}

private enum _AcceptAll(Args...) = true;

template visitImpl(alias visitor, Exhaustive exhaustive, bool fused, alias Filter = _AcceptAll)
{
    ///
    auto ref visitImpl(Args...)(auto ref Args args)
        if (Filter!Args)
    {
        import std.meta: anySatisfy, staticMap, AliasSeq;
        import core.lifetime: forward;

        static if (!anySatisfy!(isVariant, Args))
        {
            static if (exhaustive == Exhaustive.compileTime)
            {
                return visitor(forward!args);
            }
            else
            static if (exhaustive == Exhaustive.exception)
            {
                static if (__traits(compiles, visitor(forward!args)))
                    return visitor(forward!args);
                else
                    return throwMe(variantMemberException);
            }
            else
            static if (exhaustive == Exhaustive.nullable)
            {
                static if (__traits(compiles, visitor(forward!args)))
                    return Nullable!(typeof(visitor(forward!args)))(visitor(forward!args));
                else
                    return Nullable!().init;
            }
            else
            static if (exhaustive == Exhaustive.auto_)
            {
                static if (__traits(compiles, visitor(forward!args)))
                    return visitor(forward!args);
                else
                    return Nullable!().init;
            }
            else
            static assert(0, "not implemented");
        }
        else
        static if (!isVariant!(Args[0]))
        {
            return .visitImpl!(nextVisitor!(visitor, args[0]), exhaustive, fused)(forward!(args[1 .. $]));
        }
        else
        {
            static if (fused && anySatisfy!(isVariant, Args[1 .. $]))
            {
                alias fun = visitThis!(visitor, exhaustive);
            }
            else
            {
                static assert (isVariant!(Args[0]), "First argument should be a Mir Algebraic type");
                alias fun = visitLast!visitor;
            }

            template VariantReturnTypesImpl(T)
            {
                static if (__traits(compiles, fun!T(forward!args)))
                {
                    alias R = typeof(fun!T(forward!args));
                    static if (fused && isVariant!R)
                        alias VariantReturnTypesImpl = staticMap!(TryRemoveConst, R.AllowedTypes);
                    else
                    static if (is(immutable R == immutable noreturn))
                        alias VariantReturnTypesImpl = AliasSeq!();
                    else
                        alias VariantReturnTypesImpl = AliasSeq!(TryRemoveConst!R);
                }
                else
                static if (exhaustive == Exhaustive.auto_)
                    alias VariantReturnTypesImpl = AliasSeq!(typeof(null));
                else
                    alias VariantReturnTypesImpl = AliasSeq!();
            }

            static if (exhaustive == Exhaustive.nullable)
                alias AllReturnTypes = NoDuplicates!(typeof(null), staticMap!(VariantReturnTypesImpl, Args[0].AllowedTypes));
            else
                alias AllReturnTypes = NoDuplicates!(staticMap!(VariantReturnTypesImpl, Args[0].AllowedTypes));

            switch (args[0]._identifier_)
            {
                static foreach (i, T; Args[0].AllowedTypes)
                {
                    case i:
                        static if (__traits(compiles, fun!T(forward!args)) || exhaustive == Exhaustive.compileTime && !is(T == typeof(null)))
                        {
                            static if (AllReturnTypes.length == 1)
                            {
                                return fun!T(forward!args);
                            }
                            else
                            static if (is(VariantReturnTypesImpl!T == AliasSeq!void))
                            {
                                fun!T(forward!args);
                                return Variant!AllReturnTypes._void;
                            }
                            else
                            static if (is(typeof(fun!T(forward!args)) == Variant!AllReturnTypes))
                            {
                                return fun!T(forward!args);
                            }
                            else
                            {
                                return Variant!AllReturnTypes(fun!T(forward!args));
                            }
                        }
                        else
                        static if (exhaustive == Exhaustive.compileTime && is(T == typeof(null)))
                        {
                            assert(0, "Null " ~ Args[0].stringof);
                        }
                        else
                        static if (exhaustive == Exhaustive.nullable || exhaustive == Exhaustive.auto_)
                        {
                            return Variant!AllReturnTypes(null);
                        }
                        else
                        {
                            return throwMe(variantMemberException);
                        }
                }
                default: assert(0);
            }
        }
    }
}

private string enumKindText()(string[] strs)
{
    auto r = "enum Kind {";
    foreach (s; strs)
    {
        r ~= s;
        r ~= ", ";
    }
    r ~= "}";
    return r;
}

@safe pure @nogc
version(mir_core_test) unittest
{
    static struct S { int a; }

    Variant!(S, double) variant;
    variant = 1.0;
    variant.tryVisit!((ref value, b) => value += b)(2);
    assert (variant.get!double == 3);

    alias fun = (ref value) {
        static if (is(typeof(value) == S))
            value.a += 2;
        else
           value += 2;
    };

    variant.tryVisit!fun;
    assert (variant.get!double == 5);

    variant = S(4);
    variant.tryVisit!fun;
    assert (variant.get!S.a == 6);

    alias D = Variant!(Variant!(S, double));
}

@safe pure @nogc
version(mir_core_test) unittest
{
    import std.meta: AliasSeq;

    static struct PODWithLongPointer {
        long* x;
        this(long l) pure
        {
            x = new long(l);
        }

    @property:
        long a() const {
            return x ? *x : 0;
        }

        void a(long l) {
            if (x) {
                *x = l;
            } else {
                x = new long(l);
            }
        }
    }
    static assert(is(TypeSet!(byte, immutable PODWithLongPointer) == AliasSeq!(byte, immutable PODWithLongPointer)));
}

private enum isSimpleAggregateType(T) = is(T == class) || is(T == struct) || is(T == union) || is(T == interface);

unittest
{
    static struct Test
    {
        alias Value = void;
    }

    alias B = Nullable!Test;
}

/++
Wrapper to denote an error value type.

The wrapper is autostripped by $(LREF none).

See_also: $(LREF reflectErr).
+/
template Err(T)
{
    static if (!isErr!T)
    {
        ///
        struct Err
        {
            ///
            T value;
        }
    }
    else
    {
        alias Err = T;
    }
}

/// ditto
auto err(T)(T value) {
    import core.lifetime: move;
    static if (isErr!T)
        return move(value);
    else
        return Err!T(move(value));
}

///
unittest
{
    @reflectErr static struct E {}

    static assert(is(Err!string == Err!string));
    static assert(is(Err!(Err!string) == Err!string));
    static assert(is(Err!E == E));
    static assert(is(Err!Exception == Exception));

    static assert(is(typeof("str".err) == Err!string));
    static assert(is(typeof(E().err) == E));
    static assert(is(typeof(new Exception("str").err) == Exception));
}

/// Strips out $(LREF Err) wrapper from the type.
template stripErr(T)
{
    static if (is(immutable T : immutable Err!U, U))
        alias stripErr = U;
    else
        alias stripErr = T;
}

///
version(mir_core_test)
unittest
{
    static assert(is(stripErr!Exception == Exception));
    static assert(is(stripErr!string == string));
    static assert(is(stripErr!(Err!string) == string));
}

/++

See_also: $(LREF some) and $(LREF none).

Params:
    visitors = visitors to $(LREF match) with.
+/
alias suit(alias filter, visitors...) = visitImpl!(naryFun!visitors, Exhaustive.compileTime, true, filter);

///
version(mir_core_test)
@safe pure nothrow @nogc unittest
{
    import std.traits: isDynamicArray, Unqual;
    import std.meta: templateNot;
    alias V = Variant!(long, int, string, long[], int[]);
    alias autoGetElementType = match!(
        (string s) => "string", // we override the suit handler below for string
        suit!(isDynamicArray, a => Unqual!(typeof(a[0])).stringof), 
        suit!(templateNot!isDynamicArray, a => Unqual!(typeof(a)).stringof), 
    );
    assert(autoGetElementType(V(string.init)) == "string");
    assert(autoGetElementType(V((long[]).init)) == "long");
    assert(autoGetElementType(V((int[]).init)) == "int");
    assert(autoGetElementType(V(long.init)) == "long");
    assert(autoGetElementType(V(int.init)) == "int");
}

///
version(mir_core_test)
@safe pure nothrow @nogc unittest
{
    import std.traits: allSameType;
    import std.meta: templateNot;

    static struct Asteroid { uint size; }
    static struct Spaceship { uint size; }
    alias SpaceObject = Variant!(Asteroid, Spaceship);

    auto errorMsg = "can't unite an asteroid with a spaceship".err;

    alias unite = match!(
        suit!(allSameType, (a, b) => typeof(a)(a.size + b.size)),
        suit!(templateNot!allSameType, (a, b) => errorMsg),
    );

    auto ea = Asteroid(10);
    auto es = Spaceship(1);
    auto oa = SpaceObject(ea);
    auto os = SpaceObject(es);

    static assert(is(typeof(unite(oa, oa)) == Variant!(Err!string, Asteroid, Spaceship)));

    // Asteroid-Asteroid
    assert(unite(ea, ea) == Asteroid(20));
    assert(unite(ea, oa) == Asteroid(20));
    assert(unite(oa, ea) == Asteroid(20));
    assert(unite(oa, oa) == Asteroid(20));

    // Asteroid-Spaceship
    assert(unite(ea, es) == errorMsg);
    assert(unite(ea, os) == errorMsg);
    assert(unite(oa, es) == errorMsg);
    assert(unite(oa, os) == errorMsg);

    // Spaceship-Asteroid
    assert(unite(es, ea) == errorMsg);
    assert(unite(es, oa) == errorMsg);
    assert(unite(os, ea) == errorMsg);
    assert(unite(os, oa) == errorMsg);

    // Spaceship-Spaceship
    assert(unite(es, es) == Spaceship(2));
    assert(unite(es, os) == Spaceship(2));
    assert(unite(os, es) == Spaceship(2));
    assert(unite(os, os) == Spaceship(2));
}

private template unwrapErrImpl(alias arg)
{
    static if (is(immutable typeof(arg) == immutable Err!V, V))
        auto ref unwrapErrImpl() @property { return arg.value; }
    else
        alias unwrapErrImpl = arg;
}


private template unwrapErr(alias fun)
{
    auto ref unwrapErr(Args...)(auto ref return Args args)
    {
        import std.meta: staticMap;
        return fun(staticMap!(unwrapErrImpl, args));
    }
}

/++
$(LREF some) is a variant of $(LREF suit) that forces that type of any argument doesn't satisfy $(LREF isErr) template.

$(LREF none) is a variant of $(LREF suit) that forces that type of all arguments satisfy $(LREF isErr) template. The handler automatically strips the $(LREF Err) wrapper.

See_also: $(LREF suit), $(LREF Err), $(LREF isErr),  $(LREF isResultVariant), and $(LREF reflectErr).

Params:
    visitors = visitors to $(LREF match) with.
+/
alias some(visitors...) = suit!(allArgumentsIsNotInstanceOfErr, naryFun!visitors);

/// ditto
alias none(visitors...) = suit!(anyArgumentIsInstanceOfErr, unwrapErr!(naryFun!visitors));

///
version(mir_core_test)
unittest
{
    import mir.conv: to;

    alias orElse(alias fun) = visit!(some!"a", none!fun);
    alias errToString = orElse!(to!string);

    // can any other type including integer enum
    @reflectErr
    static struct ErrorInfo {
        string msg;
        auto toString() const { return msg; }
    }

    alias V = Variant!(Err!string, ErrorInfo, Exception, long, double);
    alias R = typeof(errToString(V.init));

    static assert(is(R == Variant!(string, long, double)), R.stringof);

    {
        V v = 1;
        assert(v.isOk);
        assert(errToString(v) == 1);
    }

    {
        V v = 1.0;
        assert(v.isOk);
        assert(errToString(v) == 1.0);
    }

    {
        V v = ErrorInfo("msg");
        assert(!v.isOk);
        assert(errToString(v) == "msg");
    }

    {
        V v = "msg".err;
        assert(!v.isOk);
        assert(errToString(v) == "msg");
    }

    {
        V v = new Exception("msg"); enum line = __LINE__;
        assert(!v.isOk);
        assert(errToString(v) == "object.Exception@" ~ __FILE__ ~ "(" ~ line.stringof ~ "): msg");
    }
}

/++
Attribute that denotes an error type. Can be used with $(LREF some) and $(LREF none).

See_also: $(LREF Err).
+/
enum reflectErr;

/++
Checks if T is a instance of $(LREF Err) or if it is annotated with $(LREF reflectErr).
+/
template isErr(T)
{
    import std.traits: isAggregateType, hasUDA;
    static if (is(T == enum) || isAggregateType!T)
    {
        static if (isTaggedType!T)
        {
            enum isErr = .isErr!(getTaggedTypeUnderlying!T);
        }
        else
        static if (is(immutable T == immutable Err!V, V))
        {
            enum isErr = true;
        }
        else
        static if (hasUDA!(T, reflectErr))
        {
            enum isErr = true;
        }
        else
        version (D_Exceptions)
        {
            enum isErr = is(immutable T : immutable Throwable);
        }
        else
        {
            enum isErr = false;
        }
    }
    else
    {
        enum isErr = false;
    }
}

/++
Checks if T is a Variant with at least one allowed type that satisfy $(LREF isErr) traits.
+/
template isResultVariant(T)
{
    static if (is(immutable T == immutable Algebraic!Types, Types...))
    {
        import std.meta: anySatisfy;
        enum isResultVariant = anySatisfy!(isErr, Types);
    }
    else
    {
        enum isResultVariant = false;
    }
}

deprecated("Use isResultVariant instead") alias isErrVariant = isResultVariant;

private template anyArgumentIsInstanceOfErr(Args...)
{
    import std.meta: anySatisfy;
    enum anyArgumentIsInstanceOfErr = anySatisfy!(isErr, Args);
}

private template allArgumentsIsNotInstanceOfErr(Args...)
{
    import std.meta: anySatisfy;
    enum allArgumentsIsNotInstanceOfErr = !anySatisfy!(isErr, Args);
}

/++
Gets subtype of algebraic without types for which $(LREF isErr) is true.
+/
template SomeVariant(T : Algebraic!Types, Types...)
{
    import std.meta: Filter, templateNot;
    alias SomeVariant = Algebraic!(Filter!(templateNot!isErr, Types));
}

///
@safe pure version(mir_core_test) unittest
{
    @reflectErr static struct ErrorS { }
    alias V = Variant!(ErrorS, Err!string, long, double, This[]);
    static assert(is(SomeVariant!V == Variant!(long, double, This[])));
}

/++
Gets subtype of algebraic with types for which $(LREF isErr) is true.
+/
template NoneVariant(T : Algebraic!Types, Types...)
{
    import std.meta: Filter;
    alias NoneVariant = Algebraic!(Filter!(isErr, Types));
}

///
@safe pure version(mir_core_test) unittest
{
    @reflectErr static struct ErrorS { }
    alias V = Variant!(ErrorS, Err!string, long, double, This[]);
    static assert(is(NoneVariant!V == Variant!(ErrorS, Err!string)));
}

private template withNewLine(alias arg)
{
    import std.meta: AliasSeq;
    alias withNewLine = AliasSeq!("\n", arg);
}

private noreturn throwMe(Args...)(auto ref Args args) {
    static if (Args.length == 1)
        enum simpleThrow = is(immutable Args[0] : immutable Throwable);
    else
        enum simpleThrow = false;
    static if (simpleThrow)
    {
        throw args[0];
    }
    else
    {
        import mir.exception: MirException;
        static if (__traits(compiles, { import mir.format: print; }))
        {
            import std.meta: staticMap;
            throw new MirException("assumeOk failure:", staticMap!(withNewLine, args)); 
        }
        else
        {
            import mir.conv: to;
            auto msg = "assumeOk failure:";
            foreach(ref arg; args)
            {
                msg ~= "\n";
                msg ~= arg.to!string;
            }
            throw new MirException(msg);
        }
    }
}

version(D_Exceptions)
/++
Validates that the result doesn't contain an error value.

Params:
    visitor = (compiletime) visitor function. Default value is `naryFun!("", "a")`.
    handler = (compiletime) visitor handler to use. Default value is $(LREF match).
Throws:
    Throws an exception if at least one parameter passed to
    `visitor` satisfies $(LREF isErr) traits.
    If there is only one paramter (common case) and its value is `Throwable`, throws it.
    Otherwise, _all_ paramters will be printed to the exception message using `mir.format.print`.
+/
alias assumeOk(alias visitor = naryFun!("", "a"), alias handler = .match) = handler!(some!visitor, none!throwMe);

///
version(mir_core_test) version(D_Exceptions)
unittest
{
    import std.exception: collectExceptionMsg;
    import mir.exception: MirException;

    alias SingleTypeValue = typeof(assumeOk(Variant!(Exception, long).init));
    static assert(is(SingleTypeValue == long), SingleTypeValue.stringof);


    // can any other type including integer enum
    @reflectErr
    static struct ErrorInfo {
        string msg;
        auto toString() const { return msg; }
    }

    alias V = Variant!(Err!string, ErrorInfo, Exception, long, double);
    alias R = typeof(assumeOk(V.init));

    static assert(is(R == Variant!(long, double)), R.stringof);

    {
        V v = 1;
        assert(v.isOk);
        assert(v.assumeOk == 1);
    }

    {
        V v = 1.0;
        assert(v.isOk);
        assert(v.assumeOk == 1.0);
    }

    {
        V v = ErrorInfo("msg");
        assert(!v.isOk);
        assert(v.assumeOk.collectExceptionMsg == "assumeOk failure:\nmsg");
    }

    {
        V v = "msg".err;
        assert(!v.isOk);
        assert(v.assumeOk.collectExceptionMsg == "assumeOk failure:\nmsg");
    }

    {
        V v = new Exception("msg");
        assert(!v.isOk);
        assert(v.assumeOk.collectExceptionMsg == "msg");
    }
}
