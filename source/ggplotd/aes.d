module ggplotd.aes;

version(unittest)
{
    import dunit.toolkit;
}


template Aes2(Specs...)
{
    import std.traits : Identity;
    import std.typetuple : staticMap, TypeTuple;
    import std.range : isInputRange;

    // Parse (type,name) pairs (FieldSpecs) out of the specified
    // arguments. Some fields would have name, others not.
    template parseSpecs(Specs...)
    {
        static if (Specs.length == 0)
        {
            alias parseSpecs = TypeTuple!();
        }
        else static if (is(Specs[0]) && isInputRange!(Specs[0]))
        {
            static if (is(typeof(Specs[1]) : string))
            {
                alias parseSpecs =
                    TypeTuple!(FieldSpec!(Specs[0 .. 2]),
                            parseSpecs!(Specs[2 .. $]));
            }
            else
            {
                alias parseSpecs =
                    TypeTuple!(FieldSpec!(Specs[0]),
                            parseSpecs!(Specs[1 .. $]));
            }
        }
        else
        {
            static assert(0, "Attempted to instantiate Tuple with an "
                    ~"invalid argument: "~ Specs[0].stringof);
        }
    }

    template FieldSpec(T, string s = "")
    {
        alias Type = T;
        alias name = s;
    }

    alias fieldSpecs = parseSpecs!Specs;

    // Used with staticMap.
    alias extractType(alias spec) = spec.Type;
    alias extractName(alias spec) = spec.name;

    // Generates named fields as follows:
    //    alias name_0 = Identity!(field[0]);
    //    alias name_1 = Identity!(field[1]);
    //      :
    // NOTE: field[k] is an expression (which yields a symbol of a
    //       variable) and can't be aliased directly.
    string injectNamedFields()
    {
        string decl = "";

        foreach (i, name; staticMap!(extractName, fieldSpecs))
        {
            import std.format : format;

            decl ~= format("alias _%s = Identity!(field[%s]);", i, i);
            if (name.length != 0)
            {
                decl ~= format("alias %s = _%s;", name, i);
            }
        }
        return decl;
    }

    // Returns Specs for a subtuple this[from .. to] preserving field
    // names if any.
    alias sliceSpecs(size_t from, size_t to) =
        staticMap!(expandSpec, fieldSpecs[from .. to]);

    template expandSpec(alias spec)
    {
        static if (spec.name.length == 0)
        {
            alias expandSpec = TypeTuple!(spec.Type);
        }
        else
        {
            alias expandSpec = TypeTuple!(spec.Type, spec.name);
        }
    }

    enum areCompatibleTuples(Tup1, Tup2, string op) = isTuple!Tup2 && is(typeof(
                {
                Tup1 tup1 = void;
                Tup2 tup2 = void;
                static assert(tup1.field.length == tup2.field.length);
                foreach (i, _; Tup1.Types)
                {
                auto lhs = typeof(tup1.field[i]).init;
                auto rhs = typeof(tup2.field[i]).init;
                static if (op == "=")
                lhs = rhs;
                else
                auto result = mixin("lhs "~op~" rhs");
                }
                }));

    enum areBuildCompatibleTuples(Tup1, Tup2) = isTuple!Tup2 && is(typeof(
                {
                static assert(Tup1.Types.length == Tup2.Types.length);
                foreach (i, _; Tup1.Types)
                static assert(isBuildable!(Tup1.Types[i], Tup2.Types[i]));
                }));

    /+ Returns $(D true) iff a $(D T) can be initialized from a $(D U). +/
        enum isBuildable(T, U) =  is(typeof(
                    {
                    U u = U.init;
                    T t = u;
                    }));
    /+ Helper for partial instanciation +/
        template isBuildableFrom(U)
        {
            enum isBuildableFrom(T) = isBuildable!(T, U);
        }

    struct Aes2
    {
        /**
         * The type of the tuple's components.
         */
        alias Types = staticMap!(extractType, fieldSpecs);

        /**
         * The names of the tuple's components. Unnamed fields have empty names.
         *
         * Examples:
         * ----
         * alias Fields = Tuple!(int, "id", string, float);
         * static assert(Fields.fieldNames == TypeTuple!("id", "", ""));
         * ----
         */
        alias fieldNames = staticMap!(extractName, fieldSpecs);

        /**
         * Use $(D t.expand) for a tuple $(D t) to expand it into its
         * components. The result of $(D expand) acts as if the tuple components
         * were listed as a list of values. (Ordinarily, a $(D Tuple) acts as a
         * single value.)
         *
         * Examples:
         * ----
         * auto t = tuple(1, " hello ", 2.3);
         * writeln(t);        // Tuple!(int, string, double)(1, " hello ", 2.3)
         * writeln(t.expand); // 1 hello 2.3
         * ----
         */
        Types expand;
        mixin(injectNamedFields());

        static if (is(Specs))
        {
            // This is mostly to make t[n] work.
            alias expand this;
        }
        else
        {
            @property
                ref inout(Aes2!Types) _Tuple_super() inout @trusted
                {
                    foreach (i, _; Types)   // Rely on the field layout
                    {
                        static assert(typeof(return).init.tupleof[i].offsetof ==
                                expand[i].offsetof);
                    }
                    return *cast(typeof(return)*) &(field[0]);
                }
            // This is mostly to make t[n] work.
            alias _Tuple_super this;
        }

        // backwards compatibility
        alias field = expand;

        /**
         * Constructor taking one value for each field.
         */
        static if (Types.length > 0)
        {
            this(Types values)
            {
                field[] = values[];
            }
        }

        /**
         * Constructor taking a compatible array.
         *
         * Examples:
         * ----
         * int[2] ints;
         * Tuple!(int, int) t = ints;
         * ----
         */
        this(U, size_t n)(U[n] values)
            if (n == Types.length && allSatisfy!(isBuildableFrom!U, Types))
            {
                foreach (i, _; Types)
                {
                    field[i] = values[i];
                }
            }

        /**
         * Constructor taking a compatible tuple.
         */
        this(U)(U another)
            if (areBuildCompatibleTuples!(typeof(this), U))
            {
                field[] = another.field[];
            }

        // Set default values
        static if (!__traits(hasMember,typeof(this),"colour")) {
            import std.range : repeat, take;
            auto colour() { 
                return repeat("black").take(this.length); 
            };
        }

        ///
        size_t length()
        {
            import std.algorithm : min;
            import std.range : walkLength, isInfinite;
            size_t l = size_t.max; 
            foreach (i, type; Types[0..$])
            {
                static if (!isInfinite!type)
                {
                    if (field[i].walkLength < l)
                        l = field[i].walkLength;
                }
            }
            return l;
        }

        /**
         * Comparison for equality.
         */
        bool opEquals(R)(R rhs)
            if (areCompatibleTuples!(typeof(this), R, "=="))
            {
                return field[] == rhs.field[];
            }

        /// ditto
        bool opEquals(R)(R rhs) const
            if (areCompatibleTuples!(typeof(this), R, "=="))
            {
                return field[] == rhs.field[];
            }

        /**
         * Comparison for ordering.
         */
        int opCmp(R)(R rhs)
            if (areCompatibleTuples!(typeof(this), R, "<"))
            {
                foreach (i, Unused; Types)
                {
                    if (field[i] != rhs.field[i])
                    {
                        return field[i] < rhs.field[i] ? -1 : 1;
                    }
                }
                return 0;
            }

        /// ditto
        int opCmp(R)(R rhs) const
            if (areCompatibleTuples!(typeof(this), R, "<"))
            {
                foreach (i, Unused; Types)
                {
                    if (field[i] != rhs.field[i])
                    {
                        return field[i] < rhs.field[i] ? -1 : 1;
                    }
                }
                return 0;
            }

        /**
         * Assignment from another tuple. Each element of the source must be
         * implicitly assignable to the respective element of the target.
         */
        void opAssign(R)(auto ref R rhs)
            if (areCompatibleTuples!(typeof(this), R, "="))
            {
                import std.algorithm : swap;

                static if (is(R : Tuple!Types) && !__traits(isRef, rhs))
                {
                    if (__ctfe)
                    {
                        // Cannot use swap at compile time
                        field[] = rhs.field[];
                    }
                    else
                    {
                        // Use swap-and-destroy to optimize rvalue assignment
                        swap!(Tuple!Types)(this, rhs);
                    }
                }
                else
                {
                    // Do not swap; opAssign should be called on the fields.
                    field[] = rhs.field[];
                }
            }

        /**
         * Takes a slice of the tuple.
         *
         * Examples:
         * ----
         * Tuple!(int, string, float, double) a;
         * a[1] = "abc";
         * a[2] = 4.5;
         * auto s = a.slice!(1, 3);
         * static assert(is(typeof(s) == Tuple!(string, float)));
         * assert(s[0] == "abc" && s[1] == 4.5);
         * ----
         */
        @property
            ref Tuple!(sliceSpecs!(from, to)) slice(size_t from, size_t to)() @trusted
            if (from <= to && to <= Types.length)
            {
                return *cast(typeof(return)*) &(field[from]);
            }

        size_t toHash() const nothrow @trusted
        {
            size_t h = 0;
            foreach (i, T; Types)
                h += typeid(T).getHash(cast(const void*)&field[i]);
            return h;
        }

        /**
         * Converts to string.
         */
        void toString(DG)(scope DG sink)
        {
            enum header = typeof(this).stringof ~ "(",
                        footer = ")",
                        separator = ", ";
            sink(header);
            foreach (i, Type; Types)
            {
                static if (i > 0)
                {
                    sink(separator);
                }
                // TODO: Change this once toString() works for shared objects.
                static if (is(Type == class) && is(typeof(Type.init) == shared))
                {
                    sink(Type.stringof);
                }
                else
                {
                    import std.format : FormatSpec, formatElement;
                    FormatSpec!char f;
                    formatElement(sink, field[i], f);
                }
            }
            sink(footer);
        }

        string toString()()
        {
            import std.conv : to;
            return this.to!string;
        }
    }

}

auto group2(AES)( AES aes )
{
    import std.algorithm : filter, map, uniq, sort;
    import std.range : array;
    auto colours = aes.map!( (a) => a.colour )
        .array
        .sort()
        .uniq;
    return colours.map!( (c) => aes.filter!((a) => a.colour==c));
}


unittest
{
    import std.stdio;
    auto tup = Aes2!(double[], "x", 
            double[], "y", string[], "colour")(
                [0,1],[2,1],
                ["white","white2"]);
    auto tup2 = Aes2!(double[], "x", 
            double[], "y")([0,1],[2,1]);
    assertEqual( tup.colour, ["white","white2"] );
    assertEqual( tup.length, 2 );
    assertEqual( tup2.length, 2 );
    assertEqual( tup2.colour.length, 2 );
    assertEqual( tup2.colour[0], "black" );

    tup2.x ~= 0.0;
    tup2.x ~= 0.0;
    assertEqual( tup2.length, 2 );
    tup2.y ~= 0.0;
    assertEqual( tup2.length, 3 );

    import std.range : repeat;
    auto xs = repeat(0);
    auto tup3 = Aes2!(typeof(xs), "x", 
            double[], "y")(xs,[2,1]);
    assertEqual(tup3.length,2);
}

unittest
{
    auto aes = Aes2!(double[], "x", double[], "y",
            string[], "colour" )( 
                [1.0,2.0,1.1], [3.0,1.5,1.1], ["a","b","a"] );

    import std.stdio;
    aes.group2.writeln;
    /+import std.range : walkLength;
    auto grouped = aes.group;
    assertEqual( grouped.length, 2 );
    assertEqual( grouped.front.length, 2 );
    grouped.popFront;
    assertEqual( grouped.front.length, 1 );
    +/

    auto aes2 = Aes2!(double[], "x", double[], "y" )( 
                [1.0,2.0,1.1], [3.0,1.5,1.1] );

    import std.stdio;
    aes2.group2.writeln;
 
}

///
struct Aes( RX, RY, RCol )
{
    import std.range : zip, Zip, StoppingPolicy, ElementType;
    import std.typecons : Tuple;

    this( RX x, RY y, RCol colour )
    {
        _aes = zip(StoppingPolicy.longest, 
                x, y, colour);
        // TODO probably need to sort by colour
    }

    @property ref auto front()
    {
        auto t = _aes.front();
        return Tuple!(
                ElementType!RX, "x", 
                ElementType!RY, "y", 
                ElementType!RCol, "colour"
            )( t[0], t[1], t[2] );
    }

    void popFront()
    {
        _aes.popFront();
    }

    @property bool empty() 
    {
        return _aes.empty();
    }

    @property Aes save() {
        return this;
    }

    private:
        Zip!(RX, RY, RCol) _aes;
}

unittest
{
    auto aes = Aes!(double[], double[], string[] )( [1.0,2.0], [3.0,1.5], ["a","b"] );
    assertEqual( aes.front.x, 1.0 );
    aes.popFront;
    assertEqual( aes.front.y, 1.5 );

    aes.popFront;
    assert( aes.empty );
    // Make sure to test with empty y, colour
}

auto group(AES)( AES aes )
{
    import std.algorithm : filter, map, uniq, sort;
    import std.range : array;
    auto colours = aes.map!( (a) => a.colour )
        .array
        .sort()
        .uniq;
    return colours.map!( (c) => aes.filter!((a) => a.colour==c));
}

unittest
{
    auto aes = Aes!(double[], double[], string[] )( [1.0,2.0,1.1], 
            [3.0,1.5,1.1], ["a","b","a"] );

    import std.range : walkLength;
    auto grouped = aes.group;
    assertEqual( grouped.walkLength, 2 );
    assertEqual( grouped.front.walkLength, 2 );
    grouped.popFront;
    assertEqual( grouped.front.walkLength, 1 );
}


/+
http://forum.dlang.org/thread/hdxnptcikgojdkmldzrk@forum.dlang.org
template aes(fun...)
{
    void aes(R)(R range)
    {
        import std.stdio : writeln;
        import std.algorithm : countUntil;
        range.writeln;
        fun[1].countUntil("y").writeln;
        fun.countUntil("z").writeln;
    }
}

unittest
{
    import std.typecons : Tuple;
    import std.range : zip;
    import std.stdio : writeln;

    auto t = Tuple!(int, "number",
            string, "message")(42, "hello");
    assert( t.number == 42 );

    auto xs = [0.0,1.0];
    auto ys = [4.0,5.0];

    aes!("x", "y")(zip(xs,ys));
}
+/
