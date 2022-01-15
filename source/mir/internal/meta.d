module mir.internal.meta;

/++
    Gets the matching $(DDSUBLINK spec/attribute, uda, user-defined attributes)
    from the given symbol.
    If the UDA is a type, then any UDAs of the same type on the symbol will
    match. If the UDA is a template for a type, then any UDA which is an
    instantiation of that template will match. And if the UDA is a value,
    then any UDAs on the symbol which are equal to that value will match.
    See_Also:
        $(LREF hasUDA)
  +/
template getUDAs(T, string member, alias attribute)
{
    import std.meta : Filter, AliasSeq;
    T* aggregate;
    alias getUDAs = Filter!(isDesiredUDA!attribute, __traits(getAttributes, __traits(getMember, *aggregate, member)));
}

/++
    Determine if a symbol has a given
    $(DDSUBLINK spec/attribute, uda, user-defined attribute).
    See_Also:
        $(LREF getUDAs)
  +/
enum hasUDA(T, string member, alias attribute) = getUDAs!(T, member, attribute).length != 0;


private template isDesiredUDA(alias attribute)
{
    template isDesiredUDA(alias toCheck)
    {
        static if (is(typeof(attribute)) && !__traits(isTemplate, attribute))
        {
            static if (__traits(compiles, toCheck == attribute))
                enum isDesiredUDA = toCheck == attribute;
            else
                enum isDesiredUDA = false;
        }
        else static if (is(typeof(toCheck)))
        {
            static if (__traits(isTemplate, attribute))
                enum isDesiredUDA =  isInstanceOf!(attribute, typeof(toCheck));
            else
                enum isDesiredUDA = is(typeof(toCheck) == attribute);
        }
        else static if (__traits(isTemplate, attribute))
            enum isDesiredUDA = isInstanceOf!(attribute, toCheck);
        else
            enum isDesiredUDA = is(toCheck == attribute);
    }
}

template memberTypeOf(T, string member)
{
    T* aggregate;
    alias memberTypeOf = typeof(__traits(getMember, aggregate, member));
}

template isMemberType(T, string member)
{
    enum isMemberType = is(typeof((ref __traits(getMember, T, member) v){})) || is(__traits(getMember, T, member) : void);
}

template isSingleMember(T, string member)
{
    import std.meta: AliasSeq;
    enum isSingleMember = AliasSeq!(__traits(getMember, T, member)).length == 1;
}

template AllMembersRec(T)
{
    static if (is(T == class) || is(T == struct) || is(T == union) || is(T == interface))
    {
        static if (__traits(getAliasThis, T).length)
        {
            T* aggregate;
            static if (is(typeof(__traits(getMember, aggregate, __traits(getAliasThis, T)))))
            {
                import std.meta: Filter, AliasSeq;
                alias baseMembers = AllMembersRec!(typeof(__traits(getMember, aggregate, __traits(getAliasThis, T))));
                alias members = Erase!(__traits(getAliasThis, T)[0], __traits(allMembers, T));
                alias AllMembersRec = NoDuplicates!(AliasSeq!(baseMembers, members));
            }
            else
            {
                alias AllMembersRec = __traits(allMembers, T);
            }
        }
        else
        {
            alias AllMembersRec = __traits(allMembers, T);
        }
    }
    else
    {
        import std.meta: AliasSeq;
        alias AllMembersRec = AliasSeq!();
    }
}

alias ConstOf(T) = const T;
enum Alignof(T) = T.alignof;
enum canConstructWith(From, To) = __traits(compiles, (From a) { To b = a; } );
enum canImplicitlyRemoveConst(T) = __traits(compiles, {static T _function_(ref const T a) { return a; }} );
enum canRemoveConst(T) = canConstructWith!(const T, T);
enum canRemoveImmutable(T) = canConstructWith!(immutable T, T);
enum hasOpPostMove(T) = __traits(hasMember, T, "opPostMove");
enum hasToHash(T) = __traits(hasMember, T, "toHash");
static if (__VERSION__ < 2094)
    enum isCopyable(S) = is(typeof({ S foo = S.init; S copy = foo; }));
else
    enum isCopyable(S) = __traits(isCopyable, S); 
enum isPOD(T) = __traits(isPOD, T);
enum Sizeof(T) = T.sizeof;

enum hasInoutConstruction(T) = __traits(compiles, {static struct S { T a; this(ref return scope inout S rhs) inout { this.a = rhs.a; } }} );
enum hasConstConstruction(T) = __traits(compiles, {static struct S { T a; this(ref return scope const S rhs) const { this.a = rhs.a; } }} );
enum hasImmutableConstruction(T) = __traits(compiles, {static struct S { T a; this(ref return scope immutable S rhs) immutable { this.a = rhs.a; } }} );
enum hasMutableConstruction(T) = __traits(compiles, {static struct S { T a; this(ref return scope S rhs) { this.a = rhs.a; } }} );
enum hasSemiImmutableConstruction(T) = __traits(compiles, {static struct S { T a; this(ref return scope const S rhs) immutable { this.a = rhs.a; } }} );
enum hasSemiMutableConstruction(T) = __traits(compiles, {static struct S { T a; this(ref return scope const S rhs) { this.a = rhs.a; } }} );

@safe version(mir_core_test) unittest
{
    static struct S { this(ref return scope inout S) inout {} }
    static inout(S) _function_(ref inout S a) { return a; }
    static struct C2 { uint* a; this(ref return scope const S) const {} }
    static assert(hasInoutConstruction!uint);
    static assert(hasInoutConstruction!(immutable(uint)[]));
    static assert(hasInoutConstruction!(typeof(null)));
    static assert(hasInoutConstruction!S);
}

template staticIsSorted(alias cmp, Seq...)
{
    static if (Seq.length <= 1)
        enum staticIsSorted = true;
    else static if (Seq.length == 2)
        enum staticIsSorted = cmp!(Seq[0], Seq[1]);
    else
    {
        enum staticIsSorted =
            cmp!(Seq[($ / 2) - 1], Seq[$ / 2]) &&
            staticIsSorted!(cmp, Seq[0 .. $ / 2]) &&
            staticIsSorted!(cmp, Seq[$ / 2 .. $]);
    }
}

template TryRemoveConst(T)
{
    import std.traits: Unqual;
    alias U = Unqual!T;
    static if (canImplicitlyRemoveConst!U)
    {
        alias TryRemoveConst = U;
    }
    else
    {
        alias TryRemoveConst = T;
    }
}


template TypeCmp(A, B)
{
    enum bool TypeCmp = is(A == B) ? false:
    is(A == typeof(null)) ? true:
    is(B == typeof(null)) ? false:
    is(A == void) ? true:
    is(B == void) ? false:
    A.sizeof < B.sizeof ? true:
    A.sizeof > B.sizeof ? false:
    A.mangleof < B.mangleof;
}

template isInstanceOf(alias S)
{
    enum isInstanceOf(T) = is(T == S!Args, Args...);
}

version(mir_core_test) unittest
{
    static assert(is(TryRemoveConst!(const int) == int));
}


// taken from std.meta.allSatisfy
template allSatisfy(alias F, T...)
{
    static foreach (Ti; T)
    {
        static if (!is(typeof(allSatisfy) == bool) && // not yet defined
                   !F!(Ti))
        {
            enum allSatisfy = false;
        }
    }
    static if (!is(typeof(allSatisfy) == bool)) // if not yet defined
    {
        enum allSatisfy = true;
    }
}

template Erase(T, TList...)
{
    alias Erase = GenericErase!(T, TList).result;
}

template Erase(alias T, TList...)
{
    alias Erase = GenericErase!(T, TList).result;
}

template GenericErase(args...)
if (args.length >= 1)
{
    import std.meta: AliasSeq;

    alias e     = OldAlias!(args[0]);
    alias tuple = args[1 .. $] ;

    static if (tuple.length)
    {
        alias head = OldAlias!(tuple[0]);
        alias tail = tuple[1 .. $];

        static if (isSame!(e, head))
            alias result = tail;
        else
            alias result = AliasSeq!(head, GenericErase!(e, tail).result);
    }
    else
    {
        alias result = AliasSeq!();
    }
}

template Pack(T...)
{
    alias Expand = T;
    enum equals(U...) = isSame!(Pack!T, Pack!U);
}


template EraseAll(T, TList...)
{
    alias EraseAll = GenericEraseAll!(T, TList).result;
}

template EraseAll(alias T, TList...)
{
    alias EraseAll = GenericEraseAll!(T, TList).result;
}

template GenericEraseAll(args...)
if (args.length >= 1)
{
    import std.meta: AliasSeq;

    alias e     = OldAlias!(args[0]);
    alias tuple = args[1 .. $];

    static if (tuple.length)
    {
        alias head = OldAlias!(tuple[0]);
        alias tail = tuple[1 .. $];
        alias next = AliasSeq!(
            GenericEraseAll!(e, tail[0..$/2]).result,
            GenericEraseAll!(e, tail[$/2..$]).result
            );

        static if (isSame!(e, head))
            alias result = next;
        else
            alias result = AliasSeq!(head, next);
    }
    else
    {
        alias result = AliasSeq!();
    }
}

template OldAlias(T)
{
    alias OldAlias = T;
}

template OldAlias(alias T)
{
    alias OldAlias = T;
}

template EraseAllN(uint N, TList...)
{
    static if (N == 1)
    {
        alias EraseAllN = EraseAll!(TList[0], TList[1 .. $]);
    }
    else
    {
        static if (N & 1)
            alias EraseAllN = EraseAllN!(N / 2, TList[N / 2 + 1 .. N],
                    EraseAllN!(N / 2 + 1, TList[0 .. N / 2 + 1], TList[N .. $]));
        else
            alias EraseAllN = EraseAllN!(N / 2, TList[N / 2 .. N],
                    EraseAllN!(N / 2, TList[0 .. N / 2], TList[N .. $]));
    }
}

template NoDuplicates(TList...)
{
    static if (TList.length >= 2)
    {
        import std.meta: AliasSeq;

        alias fst = NoDuplicates!(TList[0 .. $/2]);
        alias snd = NoDuplicates!(TList[$/2 .. $]);
        alias NoDuplicates = AliasSeq!(fst, EraseAllN!(fst.length, fst, snd));
    }
    else
    {
        alias NoDuplicates = TList;
    }
}


template isSame(ab...)
if (ab.length == 2)
{
    static if (is(ab[0]) && is(ab[1]))
    {
        enum isSame = is(ab[0] == ab[1]);
    }
    else static if (!is(ab[0]) && !is(ab[1]) &&
                    !(is(typeof(&ab[0])) && is(typeof(&ab[1]))) &&
                     __traits(compiles, { enum isSame = ab[0] == ab[1]; }))
    {
        enum isSame = (ab[0] == ab[1]);
    }
    else
    {
        enum isSame = __traits(isSame, ab[0], ab[1]);
    }
}

template Mod(From, To)
{
    template Mod(T)
    {
        static if (is(T == From))
            alias Mod = To;
        else
            alias Mod = T;
    }
}

template Replace(From, To, T...)
{
    import std.meta: staticMap;
    alias Replace = staticMap!(Mod!(From, To), T);
}

template ReplaceTypeUnless(alias pred, From, To, T...)
{
    static if (T.length == 1)
    {
        import std.meta: staticMap;
        static if (pred!(T[0]))
            alias ReplaceTypeUnless = T[0];
        else static if (is(T[0] == From))
            alias ReplaceTypeUnless = To;
        else static if (is(T[0] == const(U), U))
            alias ReplaceTypeUnless = const(ReplaceTypeUnless!(pred, From, To, U));
        else static if (is(T[0] == immutable(U), U))
            alias ReplaceTypeUnless = immutable(ReplaceTypeUnless!(pred, From, To, U));
        else static if (is(T[0] == shared(U), U))
            alias ReplaceTypeUnless = shared(ReplaceTypeUnless!(pred, From, To, U));
        else static if (is(T[0] == U*, U))
        {
            static if (is(U == function))
                alias ReplaceTypeUnless = replaceTypeInFunctionTypeUnless!(pred, From, To, T[0]);
            else
                alias ReplaceTypeUnless = ReplaceTypeUnless!(pred, From, To, U)*;
        }
        else static if (is(T[0] == delegate))
        {
            alias ReplaceTypeUnless = replaceTypeInFunctionTypeUnless!(pred, From, To, T[0]);
        }
        else static if (is(T[0] == function))
        {
            static assert(0, "Function types not supported," ~
                " use a function pointer type instead of " ~ T[0].stringof);
        }
        else static if (is(T[0] == U!V, alias U, V...))
        {
            template replaceTemplateArgs(T...)
            {
                static if (is(typeof(T[0])))
                    static if (__traits(compiles, {alias replaceTemplateArgs = T[0];}))
                        alias replaceTemplateArgs = T[0];
                    else
                        enum replaceTemplateArgs = T[0];
                else
                    alias replaceTemplateArgs = ReplaceTypeUnless!(pred, From, To, T[0]);
            }
            alias ReplaceTypeUnless = U!(staticMap!(replaceTemplateArgs, V));
        }
        else static if (is(T[0] == struct))
            // don't match with alias this struct below
            // https://issues.dlang.org/show_bug.cgi?id=15168
            alias ReplaceTypeUnless = T[0];
        else static if (is(T[0] == enum))
            alias ReplaceTypeUnless = T[0];
        else static if (is(T[0] == U[], U))
            alias ReplaceTypeUnless = ReplaceTypeUnless!(pred, From, To, U)[];
        else static if (is(T[0] == U[n], U, size_t n))
            alias ReplaceTypeUnless = ReplaceTypeUnless!(pred, From, To, U)[n];
        else static if (is(T[0] == U[V], U, V))
            alias ReplaceTypeUnless =
                ReplaceTypeUnless!(pred, From, To, U)[ReplaceTypeUnless!(pred, From, To, V)];
        else
            alias ReplaceTypeUnless = T[0];
    }
    else static if (T.length > 1)
    {
        import std.meta: AliasSeq;
        alias ReplaceTypeUnless = AliasSeq!(ReplaceTypeUnless!(pred, From, To, T[0]),
            ReplaceTypeUnless!(pred, From, To, T[1 .. $]));
    }
    else
    {
        import std.meta: AliasSeq;
        alias ReplaceTypeUnless = AliasSeq!();
    }
}

@safe version(mir_core_test) unittest
{
    import std.typecons: Tuple;
    import std.traits : isArray;
    static assert(
        is(ReplaceTypeUnless!(isArray, int, string, int*) == string*) &&
        is(ReplaceTypeUnless!(isArray, int, string, int[]) == int[]) &&
        is(ReplaceTypeUnless!(isArray, int, string, Tuple!(int, int[]))
            == Tuple!(string, int[]))
   );
}

template Contains(Types...)
{
    import std.meta: staticIndexOf;
    enum Contains(T) = staticIndexOf!(T, Types) >= 0;
}

template replaceTypeInFunctionTypeUnless(alias pred, From, To, fun)
{
    import std.meta;
    import std.traits;
    alias RX = ReplaceTypeUnless!(pred, From, To, ReturnType!fun);
    alias PX = AliasSeq!(ReplaceTypeUnless!(pred, From, To, Parameters!fun));
    // Wrapping with AliasSeq is neccesary because ReplaceType doesn't return
    // tuple if Parameters!fun.length == 1
    string gen()
    {
        enum  linkage = functionLinkage!fun;
        alias attributes = functionAttributes!fun;
        enum  variadicStyle = variadicFunctionStyle!fun;
        alias storageClasses = ParameterStorageClassTuple!fun;
        string result;
        result ~= "extern(" ~ linkage ~ ") ";
        static if (attributes & FunctionAttribute.ref_)
        {
            result ~= "ref ";
        }
        result ~= "RX";
        static if (is(fun == delegate))
            result ~= " delegate";
        else
            result ~= " function";
        result ~= "(";
        static foreach (i; 0 .. PX.length)
        {
            if (i)
                result ~= ", ";
            if (storageClasses[i] & ParameterStorageClass.scope_)
                result ~= "scope ";
            if (storageClasses[i] & ParameterStorageClass.out_)
                result ~= "out ";
            if (storageClasses[i] & ParameterStorageClass.ref_)
                result ~= "ref ";
            if (storageClasses[i] & ParameterStorageClass.lazy_)
                result ~= "lazy ";
            if (storageClasses[i] & ParameterStorageClass.return_)
                result ~= "return ";
            result ~= "PX[" ~ i.stringof ~ "]";
        }
        static if (variadicStyle == Variadic.typesafe)
            result ~= " ...";
        else static if (variadicStyle != Variadic.no)
            result ~= ", ...";
        result ~= ")";
        static if (attributes & FunctionAttribute.pure_)
            result ~= " pure";
        static if (attributes & FunctionAttribute.nothrow_)
            result ~= " nothrow";
        static if (attributes & FunctionAttribute.property)
            result ~= " @property";
        static if (attributes & FunctionAttribute.trusted)
            result ~= " @trusted";
        static if (attributes & FunctionAttribute.safe)
            result ~= " @safe";
        static if (attributes & FunctionAttribute.nogc)
            result ~= " @nogc";
        static if (attributes & FunctionAttribute.system)
            result ~= " @system";
        static if (attributes & FunctionAttribute.const_)
            result ~= " const";
        static if (attributes & FunctionAttribute.immutable_)
            result ~= " immutable";
        static if (attributes & FunctionAttribute.inout_)
            result ~= " inout";
        static if (attributes & FunctionAttribute.shared_)
            result ~= " shared";
        static if (attributes & FunctionAttribute.return_)
            result ~= " return";
        return result;
    }
    mixin("alias replaceTypeInFunctionTypeUnless = " ~ gen() ~ ";");
}

enum false_(T) = false;

alias ReplaceType(From, To, T...) = ReplaceTypeUnless!(false_, From, To, T);

version(mir_core_test) @safe unittest
{
    import std.typecons: Unique, Tuple;
    template Test(Ts...)
    {
        static if (Ts.length)
        {
            //pragma(msg, "Testing: ReplaceType!("~Ts[0].stringof~", "
            //    ~Ts[1].stringof~", "~Ts[2].stringof~")");
            static assert(is(ReplaceType!(Ts[0], Ts[1], Ts[2]) == Ts[3]),
                "ReplaceType!("~Ts[0].stringof~", "~Ts[1].stringof~", "
                    ~Ts[2].stringof~") == "
                    ~ReplaceType!(Ts[0], Ts[1], Ts[2]).stringof);
            alias Test = Test!(Ts[4 .. $]);
        }
        else alias Test = void;
    }
    //import core.stdc.stdio;
    alias RefFun1 = ref int function(float, long);
    alias RefFun2 = ref float function(float, long);
    extern(C) int printf(const char*, ...) nothrow @nogc @system;
    extern(C) float floatPrintf(const char*, ...) nothrow @nogc @system;
    int func(float);
    int x;
    struct S1 { void foo() { x = 1; } }
    struct S2 { void bar() { x = 2; } }
    alias Pass = Test!(
        int, float, typeof(&func), float delegate(float),
        int, float, typeof(&printf), typeof(&floatPrintf),
        int, float, int function(out long, ...),
            float function(out long, ...),
        int, float, int function(ref float, long),
            float function(ref float, long),
        int, float, int function(ref int, long),
            float function(ref float, long),
        int, float, int function(out int, long),
            float function(out float, long),
        int, float, int function(lazy int, long),
            float function(lazy float, long),
        int, float, int function(out long, ref const int),
            float function(out long, ref const float),
        int, int, int, int,
        int, float, int, float,
        int, float, const int, const float,
        int, float, immutable int, immutable float,
        int, float, shared int, shared float,
        int, float, int*, float*,
        int, float, const(int)*, const(float)*,
        int, float, const(int*), const(float*),
        const(int)*, float, const(int*), const(float),
        int*, float, const(int)*, const(int)*,
        int, float, int[], float[],
        int, float, int[42], float[42],
        int, float, const(int)[42], const(float)[42],
        int, float, const(int[42]), const(float[42]),
        int, float, int[int], float[float],
        int, float, int[double], float[double],
        int, float, double[int], double[float],
        int, float, int function(float, long), float function(float, long),
        int, float, int function(float), float function(float),
        int, float, int function(float, int), float function(float, float),
        int, float, int delegate(float, long), float delegate(float, long),
        int, float, int delegate(float), float delegate(float),
        int, float, int delegate(float, int), float delegate(float, float),
        int, float, Unique!int, Unique!float,
        int, float, Tuple!(float, int), Tuple!(float, float),
        int, float, RefFun1, RefFun2,
        S1, S2,
            S1[1][][S1]* function(),
            S2[1][][S2]* function(),
        int, string,
               int[3] function(   int[] arr,    int[2] ...) pure @trusted,
            string[3] function(string[] arr, string[2] ...) pure @trusted,
    );
    // https://issues.dlang.org/show_bug.cgi?id=15168
    static struct T1 { string s; alias s this; }
    static struct T2 { char[10] s; alias s this; }
    static struct T3 { string[string] s; alias s this; }
    alias Pass2 = Test!(
        ubyte, ubyte, T1, T1,
        ubyte, ubyte, T2, T2,
        ubyte, ubyte, T3, T3,
    );
}
// https://issues.dlang.org/show_bug.cgi?id=17116
version(mir_core_test) @safe unittest
{
    alias ConstDg = void delegate(float) const;
    alias B = void delegate(int) const;
    alias A = ReplaceType!(float, int, ConstDg);
    static assert(is(B == A));
}
 // https://issues.dlang.org/show_bug.cgi?id=19696
version(mir_core_test) @safe unittest
{
    static struct T(U) {}
    static struct S { T!int t; alias t this; }
    static assert(is(ReplaceType!(float, float, S) == S));
}
 // https://issues.dlang.org/show_bug.cgi?id=19697
version(mir_core_test) @safe unittest
{
    class D(T) {}
    class C : D!C {}
    static assert(is(ReplaceType!(float, float, C)));
}
// https://issues.dlang.org/show_bug.cgi?id=16132
version(mir_core_test) @safe unittest
{
    interface I(T) {}
    class C : I!int {}
    static assert(is(ReplaceType!(int, string, C) == C));
}
