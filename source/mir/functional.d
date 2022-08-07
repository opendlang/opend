/++
Functions that manipulate other functions.
This module provides functions for compile time function composition. These
functions are helpful when constructing predicates for the algorithms in
$(MREF mir, ndslice).
$(BOOKTABLE $(H2 Functions),
$(TR $(TH Function Name) $(TH Description))
    $(TR $(TD $(LREF naryFun))
        $(TD Create a unary, binary or N-nary function from a string. Most often
        used when defining algorithms on ranges and slices.
    ))
    $(TR $(TD $(LREF pipe))
        $(TD Join a couple of functions into one that executes the original
        functions one after the other, using one function's result for the next
        function's argument.
    ))
    $(TR $(TD $(LREF not))
        $(TD Creates a function that negates another.
    ))
    $(TR $(TD $(LREF reverseArgs))
        $(TD Predicate that reverses the order of its arguments.
    ))
    $(TR $(TD $(LREF forward))
        $(TD Forwards function arguments with saving ref-ness.
    ))
    $(TR $(TD $(LREF refTuple))
        $(TD Removes $(LREF Ref) shell.
    ))
    $(TR $(TD $(LREF unref))
        $(TD Creates a $(LREF RefTuple) structure.
    ))
    $(TR $(TD $(LREF __ref))
        $(TD Creates a $(LREF Ref) structure.
    ))
)
License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)
Authors: Ilia Ki, $(HTTP erdani.org, Andrei Alexandrescu (some original code from std.functional))

Macros:
NDSLICE = $(REF_ALTTEXT $(TT $2), $2, mir, ndslice, $1)$(NBSP)
+/
module mir.functional;

private enum isRef(T) = is(T : Ref!T0, T0);

import mir.math.common: optmath;

public import core.lifetime : forward;

@optmath:

/++
Constructs static array.
+/
T[N] staticArray(T, size_t N)(T[N] a...)
{
    return a;
}

/++
Simple wrapper that holds a pointer.
It is used for as workaround to return multiple auto ref values.
+/
struct Ref(T)
    if (!isRef!T)
{
    @optmath:

    @disable this();
    ///
    this(ref T value) @trusted
    {
        __ptr = &value;
    }
    ///
    T* __ptr;
    ///
    ref inout(T) __value() inout @property { return *__ptr; }
    ///
    alias __value this;

    ///
    bool opEquals(ref scope const T rhs) const scope
    {
        return __value == rhs;
    }

    ///
    bool opEquals(scope const T rhs) const scope
    {
        return __value == rhs;
    }

    static if (__traits(hasMember, T, "toHash") || __traits(isScalar, T))
    ///
    size_t toHash() const
    {
        return hashOf(__value);
    }
}

/// Creates $(LREF Ref) wrapper.
Ref!T _ref(T)(ref T value)
{
    return Ref!T(value);
}

private mixin template _RefTupleMixin(T...)
    if (T.length <= 26)
{
    static if (T.length)
    {
        enum i = T.length - 1;
        static if (isRef!(T[i]))
            mixin(`@optmath @property ref ` ~ cast(char)('a' + i) ~ `() { return *expand[` ~ i.stringof ~ `].__ptr; }` );
        else
            mixin(`alias ` ~ cast(char)('a' + i) ~ ` = expand[` ~ i.stringof ~ `];`);
        mixin ._RefTupleMixin!(T[0 .. $-1]);
    }
}

/++
Simplified tuple structure. Some fields may be type of $(LREF Ref).
Ref stores a pointer to a values.
+/
struct RefTuple(T...)
{
    @optmath:
    T expand;
    alias expand this;
    mixin _RefTupleMixin!T;
}

/// Removes $(LREF Ref) shell.
alias Unref(V : Ref!T, T) = T;
/// ditto
template Unref(V : RefTuple!T, T...)
{
    import std.meta: staticMap;
    alias Unref = RefTuple!(staticMap!(.Unref, T));
}

/// ditto
alias Unref(V) = V;

/++
Returns: a $(LREF RefTuple) structure.
+/
RefTuple!Args refTuple(Args...)(auto ref Args args)
{
    return RefTuple!Args(args);
}

/// Removes $(LREF Ref) shell.
ref T unref(V : Ref!T, T)(scope return V value)
{
    return *value.__ptr;
}

/// ditto
Unref!(RefTuple!T) unref(V : RefTuple!T, T...)(V value)
{
    typeof(return) ret;
    foreach(i, ref elem; ret.expand)
        elem = unref(value.expand[i]);
    return ret;
}

/// ditto
ref V unref(V)(scope return ref V value)
{
    return value;
}

/// ditto
V unref(V)(V value)
{
    import std.traits: hasElaborateAssign;
    static if (hasElaborateAssign!V)
    {
        import core.lifetime: move;
        return move(value);
    }
    else
        return value;
}

private template autoExpandAndForwardElem(alias value)
{

}

template autoExpandAndForward(alias value)
    if (is(typeof(value) : RefTuple!Types, Types...))
{

    import core.lifetime: move;
    enum isLazy = __traits(isRef,  value) || __traits(isOut,  value) || __traits(isLazy, value);
    template autoExpandAndForwardElem(size_t i)
    {
        alias T = typeof(value.expand[i]);
        static if (isRef!T)
        {
            ref autoExpandAndForwardElem()
            {
                return *value.expand[i].__ptr;
            }
        }
        else
        {
            static if (isLazy)
                @property ref autoExpandAndForwardElem(){ pragma(inline, true); return value.expand[i]; }
            else
            static if (is(typeof(move(value.expand[i]))))
                @property auto autoExpandAndForwardElem(){ pragma(inline, true); return move(value.expand[i]); }
            else
                @property auto autoExpandAndForwardElem(){ pragma(inline, true); return value.expand[i]; }
        }
    }

    import mir.internal.utility: Iota;
    import std.meta: staticMap;
    alias autoExpandAndForward = staticMap!(autoExpandAndForwardElem, Iota!(value.expand.length));
}

version(mir_core_test) unittest
{
    long v;
    auto tup = refTuple(v._ref, 2.3);

    auto f(ref long a, double b)
    {
        assert(b == 2.3);
        assert(a == v);
        assert(&a == &v);
    }

    f(autoExpandAndForward!tup);
}

private string joinStrings()(string[] strs)
{
    if (strs.length)
    {
        auto ret = strs[0];
        foreach(s; strs[1 .. $])
            ret ~= s;
        return ret;
    }
    return null;
}

private auto copyArg(alias a)()
{
    return a;
}

/++
Takes multiple functions and adjoins them together. The result is a
$(LREF RefTuple) with one element per passed-in function. Upon
invocation, the returned tuple is the adjoined results of all
functions.
Note: In the special case where only a single function is provided
(`F.length == 1`), adjoin simply aliases to the single passed function
(`F[0]`).
+/
template adjoin(fun...) if (fun.length && fun.length <= 26)
{
    static if (fun.length != 1)
    {
        import std.meta: staticMap, Filter;
        static if (Filter!(_needNary, fun).length == 0)
        {
            ///
            @optmath auto adjoin(Args...)(auto ref Args args)
            {
                template _adjoin(size_t i)
                {
                    static if (__traits(compiles, &(fun[i](forward!args))))
                        enum _adjoin = "Ref!(typeof(fun[" ~ i.stringof ~ "](forward!args)))(fun[" ~ i.stringof ~ "](args)), ";
                    else
                        enum _adjoin = "fun[" ~ i.stringof ~ "](args), ";
                }

                import mir.internal.utility;
                mixin("return refTuple(" ~ [staticMap!(_adjoin, Iota!(fun.length))].joinStrings ~ ");");
            }
        }
        else alias adjoin = .adjoin!(staticMap!(naryFun, fun));
    }
    else alias adjoin = naryFun!(fun[0]);
}

///
@safe version(mir_core_test) unittest
{
    static bool f1(int a) { return a != 0; }
    static int f2(int a) { return a / 2; }
    auto x = adjoin!(f1, f2)(5);
    assert(is(typeof(x) == RefTuple!(bool, int)));
    assert(x.a == true && x.b == 2);
}

@safe version(mir_core_test) unittest
{
    alias f = pipe!(adjoin!("a", "a * a"), "a[0]");
    static assert(is(typeof(f(3)) == int));
    auto d = 4;
    static assert(is(typeof(f(d)) == Ref!int));
}

@safe version(mir_core_test) unittest
{
    static bool F1(int a) { return a != 0; }
    auto x1 = adjoin!(F1)(5);
    static int F2(int a) { return a / 2; }
    auto x2 = adjoin!(F1, F2)(5);
    assert(is(typeof(x2) == RefTuple!(bool, int)));
    assert(x2.a && x2.b == 2);
    auto x3 = adjoin!(F1, F2, F2)(5);
    assert(is(typeof(x3) == RefTuple!(bool, int, int)));
    assert(x3.a && x3.b == 2 && x3.c == 2);

    bool F4(int a) { return a != x1; }
    alias eff4 = adjoin!(F4);
    static struct S
    {
        bool delegate(int) @safe store;
        int fun() { return 42 + store(5); }
    }
    S s;
    s.store = (int a) { return eff4(a); };
    auto x4 = s.fun();
    assert(x4 == 43);
}

//@safe
version(mir_core_test) unittest
{
    import std.meta: staticMap;
    alias funs = staticMap!(naryFun, "a", "a * 2", "a * 3", "a * a", "-a");
    alias afun = adjoin!funs;
    int a = 5, b = 5;
    assert(afun(a) == refTuple(Ref!int(a), 10, 15, 25, -5));
    assert(afun(a) == refTuple(Ref!int(b), 10, 15, 25, -5));

    static class C{}
    alias IC = immutable(C);
    IC foo(){return typeof(return).init;}
    RefTuple!(IC, IC, IC, IC) ret1 = adjoin!(foo, foo, foo, foo)();

    static struct S{int* p;}
    alias IS = immutable(S);
    IS bar(){return typeof(return).init;}
    enum RefTuple!(IS, IS, IS, IS) ret2 = adjoin!(bar, bar, bar, bar)();
}

private template needOpCallAlias(alias fun)
{
    /* Determine whether or not naryFun need to alias to fun or
     * fun.opCall. Basically, fun is a function object if fun(...) compiles. We
     * want is(naryFun!fun) (resp., is(naryFun!fun)) to be true if fun is
     * any function object. There are 4 possible cases:
     *
     *  1) fun is the type of a function object with static opCall;
     *  2) fun is an instance of a function object with static opCall;
     *  3) fun is the type of a function object with non-static opCall;
     *  4) fun is an instance of a function object with non-static opCall.
     *
     * In case (1), is(naryFun!fun) should compile, but does not if naryFun
     * aliases itself to fun, because typeof(fun) is an error when fun itself
     * is a type. So it must be aliased to fun.opCall instead. All other cases
     * should be aliased to fun directly.
     */
    static if (is(typeof(fun.opCall) == function))
    {
        import std.traits: Parameters;
        enum needOpCallAlias = !is(typeof(fun)) && __traits(compiles, () {
            return fun(Parameters!fun.init);
        });
    }
    else
        enum needOpCallAlias = false;
}

private template _naryAliases(size_t n)
    if (n <= 26)
{
    static if (n == 0)
        enum _naryAliases = "";
    else
    {
        enum i = n - 1;
        enum _naryAliases = _naryAliases!i ~ "alias " ~ cast(char)('a' + i) ~ " = args[" ~ i.stringof ~ "];\n";
    }
}

private template stringFun(string fun)
{
    /// Specialization for string lambdas
    @optmath auto ref stringFun(Args...)(auto ref Args args)
        if (args.length <= 26 && (Args.length == 0) == (fun.length == 0))
    {
        import mir.math.common;
        static if (fun.length)
        {
            mixin(_naryAliases!(Args.length));
            return mixin(fun);
        }
        else
        {
            return;
        }
    }
}

/++
Aliases itself to a set of functions.

Transforms strings representing an expression into a binary function. The
strings must use symbol names `a`, `b`, ..., `z`  as the parameters.
If `functions[i]` is not a string, `naryFun` aliases itself away to `functions[i]`.
+/
template naryFun(functions...)
    if (functions.length >= 1)
{
    static foreach (fun; functions)
    {
        static if (is(typeof(fun) : string))
        {
            alias naryFun = stringFun!fun;
        }
        else static if (needOpCallAlias!fun)
            alias naryFun = fun.opCall;
        else
            alias naryFun = fun;
    }
}

///
@safe version(mir_core_test) unittest
{
    // Strings are compiled into functions:
    alias isEven = naryFun!("(a & 1) == 0");
    assert(isEven(2) && !isEven(1));
}

///
@safe version(mir_core_test) unittest
{
    alias less = naryFun!("a < b");
    assert(less(1, 2) && !less(2, 1));
    alias greater = naryFun!("a > b");
    assert(!greater("1", "2") && greater("2", "1"));
}

/// `naryFun` accepts up to 26 arguments.
@safe version(mir_core_test) unittest
{
    assert(naryFun!("a * b + c")(2, 3, 4) == 10);
}

/// `naryFun` can return by reference.
version(mir_core_test) unittest
{
    int a;
    assert(&naryFun!("a")(a) == &a);
}

/// `args` parameter tuple
version(mir_core_test) unittest
{
    assert(naryFun!("args[0] + args[1]")(2, 3) == 5);
}

/// Multiple functions
@safe pure nothrow @nogc
version(mir_core_test) unittest
{
    alias fun = naryFun!(
        (uint a) => a,
        (ulong a) => a * 2,
        a => a * 3,
    );

    int a = 10;
    long b = 10;
    float c = 10;

    assert(fun(a) == 10);
    assert(fun(b) == 20);
    assert(fun(c) == 30);
}

@safe version(mir_core_test) unittest
{
    static int f1(int a) { return a + 1; }
    static assert(is(typeof(naryFun!(f1)(1)) == int));
    assert(naryFun!(f1)(41) == 42);
    int f2(int a) { return a + 1; }
    static assert(is(typeof(naryFun!(f2)(1)) == int));
    assert(naryFun!(f2)(41) == 42);
    assert(naryFun!("a + 1")(41) == 42);

    int num = 41;
    assert(naryFun!"a + 1"(num) == 42);

    // Issue 9906
    struct Seen
    {
        static bool opCall(int n) { return true; }
    }
    static assert(needOpCallAlias!Seen);
    static assert(is(typeof(naryFun!Seen(1))));
    assert(naryFun!Seen(1));

    Seen s;
    static assert(!needOpCallAlias!s);
    static assert(is(typeof(naryFun!s(1))));
    assert(naryFun!s(1));

    struct FuncObj
    {
        bool opCall(int n) { return true; }
    }
    FuncObj fo;
    static assert(!needOpCallAlias!fo);
    static assert(is(typeof(naryFun!fo)));
    assert(naryFun!fo(1));

    // Function object with non-static opCall can only be called with an
    // instance, not with merely the type.
    static assert(!is(typeof(naryFun!FuncObj)));
}

@safe version(mir_core_test) unittest
{
    static int f1(int a, string b) { return a + 1; }
    static assert(is(typeof(naryFun!(f1)(1, "2")) == int));
    assert(naryFun!(f1)(41, "a") == 42);
    string f2(int a, string b) { return b ~ "2"; }
    static assert(is(typeof(naryFun!(f2)(1, "1")) == string));
    assert(naryFun!(f2)(1, "4") == "42");
    assert(naryFun!("a + b")(41, 1) == 42);
    //@@BUG
    //assert(naryFun!("return a + b;")(41, 1) == 42);

    // Issue 9906
    struct Seen
    {
        static bool opCall(int x, int y) { return true; }
    }
    static assert(is(typeof(naryFun!Seen)));
    assert(naryFun!Seen(1,1));

    struct FuncObj
    {
        bool opCall(int x, int y) { return true; }
    }
    FuncObj fo;
    static assert(!needOpCallAlias!fo);
    static assert(is(typeof(naryFun!fo)));
    assert(naryFun!fo(1,1));

    // Function object with non-static opCall can only be called with an
    // instance, not with merely the type.
    static assert(!is(typeof(naryFun!FuncObj)));
}


/++
N-ary predicate that reverses the order of arguments, e.g., given
`pred(a, b, c)`, returns `pred(c, b, a)`.
+/
template reverseArgs(alias fun)
{
    import std.meta: Reverse;
    ///
    @optmath auto ref reverseArgs(Args...)(auto ref Args args)
        if (is(typeof(fun(Reverse!args))))
    {
        return fun(Reverse!args);
    }

}

///
@safe version(mir_core_test) unittest
{
    int abc(int a, int b, int c) { return a * b + c; }
    alias cba = reverseArgs!abc;
    assert(abc(91, 17, 32) == cba(32, 17, 91));
}

@safe version(mir_core_test) unittest
{
    int a(int a) { return a * 2; }
    alias _a = reverseArgs!a;
    assert(a(2) == _a(2));
}

@safe version(mir_core_test) unittest
{
    int b() { return 4; }
    alias _b = reverseArgs!b;
    assert(b() == _b());
}

@safe version(mir_core_test) unittest
{
    alias gt = reverseArgs!(naryFun!("a < b"));
    assert(gt(2, 1) && !gt(1, 1));
    int x = 42;
    bool xyz(int a, int b) { return a * x < b / x; }
    auto foo = &xyz;
    foo(4, 5);
    alias zyx = reverseArgs!(foo);
    assert(zyx(5, 4) == foo(4, 5));
}

/++
Negates predicate `pred`.
+/
template not(alias pred)
{
    static if (!is(typeof(pred) : string) && !needOpCallAlias!pred)
    ///
    @optmath bool not(T...)(auto ref T args)
    {
        return !pred(args);
    }
    else
        alias not = .not!(naryFun!pred);
}

///
@safe version(mir_core_test) unittest
{
    import std.algorithm.searching : find;
    import std.uni : isWhite;
    string a = "   Hello, world!";
    assert(find!(not!isWhite)(a) == "Hello, world!");
}

@safe version(mir_core_test) unittest
{
    assert(not!"a != 5"(5));
    assert(not!"a != b"(5, 5));

    assert(not!(() => false)());
    assert(not!(a => a != 5)(5));
    assert(not!((a, b) => a != b)(5, 5));
    assert(not!((a, b, c) => a * b * c != 125 )(5, 5, 5));
}

private template _pipe(size_t n)
{
    static if (n)
    {
        enum i = n - 1;
        enum _pipe = "f[" ~ i.stringof ~ "](" ~ ._pipe!i ~ ")";
    }
    else
        enum _pipe = "forward!args";
}

private template _unpipe(alias fun)
{
    import std.traits: TemplateArgsOf, TemplateOf;
    static if (__traits(compiles, TemplateOf!fun))
        static if (__traits(isSame, TemplateOf!fun, .pipe))
            alias _unpipe = TemplateArgsOf!fun;
        else
            alias _unpipe = fun;
    else
        alias _unpipe = fun;

}

private enum _needNary(alias fun) = is(typeof(fun) : string) || needOpCallAlias!fun;

/++
Composes passed-in functions `fun[0], fun[1], ...` returning a
function `f(x)` that in turn returns
`...(fun[1](fun[0](x)))...`. Each function can be a regular
functions, a delegate, a lambda, or a string.
+/
template pipe(fun...)
{
    static if (fun.length != 1)
    {
        import std.meta: staticMap, Filter;
        alias f = staticMap!(_unpipe, fun);
        static if (f.length == fun.length && Filter!(_needNary, f).length == 0)
        {
            ///
            @optmath auto ref pipe(Args...)(auto ref Args args)
            {
                return mixin (_pipe!(fun.length));
            }
        }
        else alias pipe = .pipe!(staticMap!(naryFun, f));
    }
    else alias pipe = naryFun!(fun[0]);
}

///
@safe version(mir_core_test) unittest
{
    assert(pipe!("a + b", a => a * 10)(2, 3) == 50);
}

/// `pipe` can return by reference.
version(mir_core_test) unittest
{
    int a;
    assert(&pipe!("a", "a")(a) == &a);
}

/// Template bloat reduction
version(mir_core_test) unittest
{
    enum  a = "a * 2";
    alias b = e => e + 2;

    alias p0 = pipe!(pipe!(a, b), pipe!(b, a));
    alias p1 = pipe!(a, b, b, a);

    static assert(__traits(isSame, p0, p1));
}

@safe version(mir_core_test) unittest
{
    import std.algorithm.comparison : equal;
    import std.algorithm.iteration : map;
    import std.array : split;
    import std.conv : to;

    // First split a string in whitespace-separated tokens and then
    // convert each token into an integer
    assert(pipe!(split, map!(to!(int)))("1 2 3").equal([1, 2, 3]));
}


struct AliasCall(T, string methodName, TemplateArgs...)
{
    T __this;
    alias __this this;

    ///
    auto lightConst()() const @property
    {
        import mir.qualifier;
        return AliasCall!(LightConstOf!T, methodName, TemplateArgs)(__this.lightConst);
    }

    ///
    auto lightImmutable()() immutable @property
    {
        import mir.qualifier;
        return AliasCall!(LightImmutableOf!T, methodName, TemplateArgs)(__this.lightImmutable);
    }

    this()(auto ref T value)
    {
        __this = value;
    }
    auto ref opCall(Args...)(auto ref Args args)
    {
        import std.traits: TemplateArgsOf;
        mixin("return __this." ~ methodName ~ (TemplateArgs.length ? "!TemplateArgs" : "") ~ "(forward!args);");
    }
}

/++
Replaces call operator (`opCall`) for the value using its method.
The funciton is designed to use with  $(NDSLICE, topology, vmap) or $(NDSLICE, topology, map).
Params:
    methodName = name of the methods to use for opCall and opIndex
    TemplateArgs = template arguments
+/
template aliasCall(string methodName, TemplateArgs...)
{
    /++
    Params:
        value = the value to wrap
    Returns:
        wrapped value with implemented opCall and opIndex methods
    +/
    AliasCall!(T, methodName, TemplateArgs) aliasCall(T)(T value) @property
    {
        return typeof(return)(value);
    }

    /// ditto
    ref AliasCall!(T, methodName, TemplateArgs) aliasCall(T)(return ref T value) @property @trusted
    {
        return  *cast(typeof(return)*) &value;
    }
}

///
@safe pure nothrow version(mir_core_test) unittest
{
    static struct S
    {
        auto lightConst()() const @property { return S(); }

        auto fun(size_t ct_param = 1)(size_t rt_param) const
        {
            return rt_param + ct_param;
        }
    }

    S s;

    auto sfun = aliasCall!"fun"(s);
    assert(sfun(3) == 4);

    auto sfun10 = aliasCall!("fun", 10)(s);   // uses fun!10
    assert(sfun10(3) == 13);
}

/++
+/
template recurseTemplatePipe(alias Template, size_t N, Args...)
{
    static if (N == 0)
        alias recurseTemplatePipe = Args;
    else
    {
        alias recurseTemplatePipe = Template!(.recurseTemplatePipe!(Template, N - 1, Args));
    }
}

///
@safe version(mir_core_test) unittest
{
    // import mir.ndslice.topology: map;
    alias map(alias fun) = a => a; // some template
    static assert (__traits(isSame, recurseTemplatePipe!(map, 2, "a * 2"), map!(map!"a * 2")));
}

/++
+/
template selfAndRecurseTemplatePipe(alias Template, size_t N, Args...)
{
    static if (N == 0)
        alias selfAndRecurseTemplatePipe = Args;
    else
    {
        alias selfAndRecurseTemplatePipe = Template!(.selfAndRecurseTemplatePipe!(Template, N - 1, Args));
    }
}

///
@safe version(mir_core_test) unittest
{
    // import mir.ndslice.topology: map;
    alias map(alias fun) = a => a; // some template
    static assert (__traits(isSame, selfAndRecurseTemplatePipe!(map, 2, "a * 2"), map!(pipe!("a * 2", map!"a * 2"))));
}

/++
+/
template selfTemplatePipe(alias Template, size_t N, Args...)
{
    static if (N == 0)
        alias selfTemplatePipe = Args;
    else
    {
        alias selfTemplatePipe = Template!(.selfTemplatePipe!(Template, N - 1, Args));
    }
}

///
@safe version(mir_core_test) unittest
{
    // import mir.ndslice.topology: map;
    alias map(alias fun) = a => a; // some template
    static assert (__traits(isSame, selfTemplatePipe!(map, 2, "a * 2"), map!(pipe!("a * 2", map!"a * 2"))));
}
