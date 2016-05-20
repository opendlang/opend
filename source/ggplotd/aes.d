module ggplotd.aes;

import std.range : front, popFront, empty;

version (unittest)
{
    import dunit.toolkit;
}

import std.typecons : Tuple, Typedef;

/**
  Number of pixels

  Mainly used to differentiate between drawing in plot coordinates or in pixel based coordinates.
  */
struct Pixel
{
    /// Number of pixels in int
    this( int val ) { value = val; }

    /// Copy constructor
    this( Pixel val ) { value = val; }


    alias value this;

    /// Number of pixels
    int value;
}

unittest
{
    static if (is(typeof(Pixel(10))==Pixel))
        {} else 
        assert(false);
}

// TODO Also update default grouping if appropiate

/// Default values for most settings
static auto DefaultValues = Tuple!( 
    string, "label", string, "colour", double, "size",
    double, "angle", double, "alpha", bool, "mask", double, "fill" )
    ("", "black", 1.0, 0, 1, true, 0.0);

/++
    Aes is used to store and access data for plotting

    Aes is an InputRange, with named Tuples as the ElementType. The names
    refer to certain fields, such as x, y, colour etc.

    The fields commonly used are data fields, such as "x" and "y". Which data
    fields are required depends on the geom function being called. 
    
    Other common fields: 
    $(UL
        $(LI "label": Text labels (string))
        $(LI "colour": Identifier for the colour. In general data points with different colour ids get different colours. This can be almost any type. You can also specify the colour by name or cairo.Color type if you want to specify an exact colour (any type that isNumeric, cairo.Color.RGB(A), or can be converted to string))
        $(LI "size": Gives the relative size of points/lineWidth etc.)
        $(LI "angle": Angle of printed labels in radians (double))
        $(LI "alpha": Alpha value of the drawn object (double))
        $(LI "mask": Mask the area outside the axes. Prevents you from drawing outside of the area (bool))
        $(LI "fill": Whether to fill the object/holds the alpha value to fill with (double).))
    +/
template Aes(Specs...)
{
    import std.traits : Identity;
    import std.typecons : isTuple;
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
                alias parseSpecs = TypeTuple!(FieldSpec!(Specs[0 .. 2]), parseSpecs!(Specs[2 .. $]));
            }
            else
            {
                alias parseSpecs = TypeTuple!(FieldSpec!(Specs[0]), parseSpecs!(Specs[1 .. $]));
            }
        }
        else
        {
            static assert(0,
                "Attempted to instantiate Tuple with an " ~ "invalid argument: " ~ Specs[0].stringof);
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

    alias fieldNames = staticMap!(extractName, fieldSpecs);

    string injectFront()
    {
        import std.format : format;

        string tupleType = "Tuple!(";
        string values = "(";

        foreach (i, name; fieldNames)
        {

            tupleType ~= format(q{typeof(%s.front),q{%s},}, name, name);
            values ~= format("this.%s.front,", name);
        }

        return format( "auto front() { import std.range : ElementType; import std.typecons : Tuple; import std.range : front; return %s ) %s );}", tupleType[0 .. $ - 1], values[0 .. $ - 1]);
    }

    // Returns Specs for a subtuple this[from .. to] preserving field
    // names if any.
    alias sliceSpecs(size_t from, size_t to) = staticMap!(expandSpec, fieldSpecs[from .. to]);

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

    enum areCompatibleTuples(Tup1, Tup2, string op) = isTuple!Tup2 && is(typeof({
        Tup1 tup1 = void;
        Tup2 tup2 = void;
        static assert(tup1.field.length == tup2.field.length);
        foreach (i, _;
        Tup1.Types)
        {
            auto lhs = typeof(tup1.field[i]).init;
            auto rhs = typeof(tup2.field[i]).init;
            static if (op == "=")
                lhs = rhs;
            else
            { 
                import std.format : format;
                auto result = mixin(format("lhs %s rhs", op));
            }
        }
    }));

    enum areBuildCompatibleTuples(Tup1, Tup2) = isTuple!Tup2 && is(typeof({
        static assert(Tup1.Types.length == Tup2.Types.length);
        foreach (i, _;
        Tup1.Types)
        static assert(isBuildable!(Tup1.Types[i], Tup2.Types[i]));
    }));

    /+ Returns $(D true) iff a $(D T) can be initialized from a $(D U). +/
    enum isBuildable(T, U) = is(typeof({ U u = U.init; T t = u; }));
    /+ Helper for partial instanciation +/
    template isBuildableFrom(U)
    {
        enum isBuildableFrom(T) = isBuildable!(T, U);
    }

    struct Aes
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
        /+this(U, size_t n)(U[n] values) if (n == Types.length
                && allSatisfy!(isBuildableFrom!U, Types))
        {
            foreach (i, _; Types)
            {
                field[i] = values[i];
            }
        }+/

        /**
         * Constructor taking a compatible tuple.
         */
        this(U)(U another) if (areBuildCompatibleTuples!(typeof(this), U))
        {
            field[] = another.field[];
        }

        mixin(injectFront());

        ///
        void popFront()
        {
            import std.range : popFront;

            foreach (i, _; Types[0 .. $])
            {
                field[i].popFront();
            }
        }

        ///
        auto save() const
        {
            return this;
        }

        ///
        @property bool empty()
        {
            if (length == 0)
                return true;
            return false;
        }

        ///
        size_t length()
        {
            import std.algorithm : min;
            import std.range : walkLength, isInfinite;

            size_t l = size_t.max;
            foreach (i, type; Types[0 .. $])
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
        bool opEquals(R)(in R rhs) const if (areCompatibleTuples!(typeof(this), R, "=="))
        {
            return field[] == rhs.field[];
        }

        /// ditto
        bool opEquals(R)(R rhs) const if (areCompatibleTuples!(typeof(this), R, "=="))
        {
            return field[] == rhs.field[];
        }

        /**
         * Comparison for ordering.
         */
        int opCmp(R)(in R rhs) const if (areCompatibleTuples!(typeof(this), R, "<")) 
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
        int opCmp(R)(R rhs) const if (areCompatibleTuples!(typeof(this), R, "<"))
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
        void opAssign(R)(auto ref R rhs) if (areCompatibleTuples!(typeof(this), R,
                "="))
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
        @property ref Tuple!(sliceSpecs!(from, to)) slice(size_t from, size_t to)() @trusted if (
                from <= to && to <= Types.length)
        {
            return *cast(typeof(return)*)&(field[from]);
        }

        ///
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
        void toString(DG)(scope DG sink) const
        {
            enum header = typeof(this).stringof ~ "(", footer = ")", separator = ", ";
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

        /**
         * Converts to string.
         */
        string toString()() const
        {
            import std.conv : to;

            return this.to!string;
        }
    }
}

unittest
{
    auto tup = Aes!(double[], "x", double[], "y", string[], "colour")([0, 1],
        [2, 1], ["white", "white2"]);
    auto tup2 = Aes!(double[], "x", double[], "y")([0, 1], [2, 1]);
    assertEqual(tup.colour, ["white", "white2"]);
    assertEqual(tup.length, 2);
    assertEqual(tup2.length, 2);

    tup2.x ~= 0.0;
    tup2.x ~= 0.0;
    assertEqual(tup2.length, 2);
    tup2.y ~= 0.0;
    assertEqual(tup2.length, 3);
}

/// Basic Aes usage
unittest
{
    auto aes = Aes!(double[], "x", double[], "y", string[], "colour")([0, 1],
        [2, 1], ["white", "white2"]);

    aes.popFront;
    assertEqual(aes.front.y, 1);
    assertEqual(aes.front.colour, "white2");

    auto aes2 = Aes!(double[], "x", double[], "y")([0, 1], [2, 1]);
    assertEqual(aes2.front.y, 2);

    import std.range : repeat;

    auto xs = repeat(0);
    auto aes3 = Aes!(typeof(xs), "x", double[], "y")(xs, [2, 1]);

    assertEqual(aes3.front.x, 0);
    aes3.popFront;
    aes3.popFront;
    assertEqual(aes3.empty, true);

}


import std.typetuple : TypeTuple;
// Default fields to group by
alias DefaultGroupFields = TypeTuple!("alpha","colour","label");

/++
    Groups data by colour label etc.

    Will also add DefaultValues for label etc to the data. It is also possible to specify exactly what to group by on as a template parameter. See example.
+/
template group(Specs...)
{
    string injectExtractKey(A)()
    {
        import std.format : format;
        static if (Specs.length == 0)
        {
            import std.typetuple : TypeTuple;
            alias Specs = DefaultGroupFields;
        }
        string types = "";
        string values = "";
        foreach( spec; Specs )
        {
            import std.range : ElementType;
            import std.traits;
            import painlesstraits : isFieldOrProperty;
            static if(hasMember!((ElementType!A),spec)
                && isFieldOrProperty!(
                    __traits(getMember,ElementType!A,spec))
            )
            {
                types ~= format("typeof(a.%s),",spec);
                values ~= format("a.%s,", spec);
            }
        }

        // Default case if no matching fields
        if (!types.empty)
            return format("auto extractKey(T)(T a) 
                { return Tuple!(%s)(%s); }", types[0..$-1],   
                values[0..$-1] );
        else
            return "auto extractKey(T)(T a) 
                { return 1; }";
    }
        
    auto group(AES)(AES aes)
    {
        mixin(injectExtractKey!(typeof(aes))());
        import ggplotd.range : groupBy;

        return aes.groupBy!((a) => extractKey(a)).values;
    }
}

///
unittest
{
    import std.range : walkLength;
    auto aes = Aes!(double[], "x", string[], "colour", double[], "alpha")
        ([0,1,2,3], ["a","a","b","b"], [0,1,0,1]);

    assertEqual(group!("colour","alpha")(aes).walkLength,4);
    assertEqual(group!("alpha")(aes).walkLength,2);

    // Ignores field that does not exist
    assertEqual(group!("alpha","abcdef")(aes).walkLength,2);

    // Should return one group holding them all
    assertEqual(group!("abcdef")(aes)[0].walkLength,4);

    assertEqual(group(aes).walkLength,4);
}

///
unittest
{
    auto aes = Aes!(double[], "x", double[], "y", string[], "colour")([1.0,
        2.0, 1.1], [3.0, 1.5, 1.1], ["a", "b", "a"]);

    import std.range : walkLength, front, popFront;

    auto grouped = aes.group;
    assertEqual(grouped.walkLength, 2);
    size_t totalLength = grouped.front.walkLength;
    assertGreaterThan(totalLength, 0);
    assertLessThan(totalLength, 3);
    grouped.popFront;
    assertEqual(totalLength + grouped.front.walkLength, 3);
}

import std.range : isInputRange;

/**
  DataID is used to refer represent any type as a usable type
  */
struct DataID
{
    /// Create DataID with given value and id
    this( double value, string id )
    {
        import std.typecons : tuple;
        state = tuple( value, id );
    }

    /// Overloading to for the DataID
    T to(T)() const
    {
        import std.conv : to;
        static if (is(T==double))
            return state[0];
        else 
            return state[1].to!T;
    }

    /// Tuple holding the value and id
    Tuple!(double, string) state; 

    alias state this;
}

unittest
{
    import std.conv : to;
    auto did = DataID( 0.1, "a" );
    assertEqual( did[0], 0.1 );
    assertEqual( did.to!double, 0.1 );
    assertEqual( did.to!string, "a" );
}

/**
  Wrap a range of any type into a range containing DataIDs

  Used throughout the code to convert user given values into usable x/y coordinates.
  */
struct NumericLabel(T) if (isInputRange!T)
{
    import std.range : ElementType;
    import std.traits : isNumeric;

    alias E = ElementType!T;

    /// Wrap the given range into a NumericLabel range
    this(T range)
    {
        original = range;
    }

    /// Get the front from the range
    @property auto front()
    {
        import std.typecons : Tuple;
        import std.range : front;
        import std.conv : to;

        static if (isNumeric!E)
            return DataID(original.front.to!double, original.front.to!string);
        else
        {
            if (original.front !in fromLabelMap)
            {
                fromLabelMap[original.front] = fromLabelMap.length.to!double;
                //toLabelMap[fromLabelMap[original.front]] 
                //    = original.front;
            }
            return DataID(fromLabelMap[original.front], original.front.to!string,
                );
        }
    }

    /// pop the front from the range
    void popFront()
    {
        import std.range : popFront;

        original.popFront;
    }

    /// is the range empty
    @property bool empty()
    {
        import std.range : empty;

        return original.empty;
    }

    /// save the range
    @property auto save()
    {
        return this;
    }

    /// Is the ElementType numeric?
    @property bool numeric()
    {
        static if (isNumeric!E)
            return true;
        else
            return false;
    }

private:
    T original;
    //E[double] toLabelMap;
    double[E] fromLabelMap;
}

unittest
{
    import std.stdio : writeln;
    import std.array : array;
    import std.algorithm : map;
    import std.typecons : tuple;

    auto num = NumericLabel!(double[])([0.0, 0.1, 1.0, 0.0]);
    assertEqual(num.map!((a) => a[0]).array, [0.0, 0.1, 1.0, 0.0]);
    assertEqual(num.map!((a) => a[1]).array, ["0", "0.1", "1", "0"]);
    auto strs = NumericLabel!(string[])(["a", "c", "b", "a"]);
    assertEqual(strs.map!((a) => a[0]).array, [0, 1, 2.0, 0.0]);
    assertEqual(strs.map!((a) => a[1]).array, ["a", "c", "b", "a"]);
}

///
auto numericLabel(Range)( Range r ) if (isInputRange!Range)
{
    return NumericLabel!(Range)(r);
}

unittest
{
    import std.stdio : writeln;
    import std.array : array;
    import std.algorithm : map;

    auto num = numericLabel([0.0, 0.1, 1.0, 0.0]);
    assertEqual(num.map!((a) => a[0]).array, [0.0, 0.1, 1.0, 0.0]);
    assertEqual(num.map!((a) => a[1]).array, ["0", "0.1", "1", "0"]);
    auto strs = numericLabel(["a", "c", "b", "a"]);
    assertEqual(strs.map!((a) => a[0]).array, [0, 1, 2.0, 0.0]);
    assertEqual(strs.map!((a) => a[1]).array, ["a", "c", "b", "a"]);
}


unittest
{
    import painlesstraits : isFieldOrProperty;

    auto t = Tuple!(double,"x")(1.0);

    static assert(isFieldOrProperty!(t.x));
}

/++
Merge two types by their members. 

If it has similar named members, then it uses the second one.

returns a named Tuple (or Aes) with all the members and their values. 
+/
template merge(T, U)
{
    import std.traits;
    import painlesstraits;
    auto injectCode()
    {
        import std.format : format;
        import std.string : split;
        string typing = "Tuple!(";
        //string typing = T.stringof.split("!")[0] ~ "!(";
        //string typingU = U.stringof.split("!")[0] ~ "!(";
        string variables = "(";
        foreach (name; __traits(allMembers, U))
        {
            static if (__traits(compiles, isFieldOrProperty!(
                            __traits(getMember, U, name)))
                    && __traits(compiles, ( in U u ) {
                        auto a = __traits(getMember, u, name);
                        Tuple!(typeof(a),name)(a); } )
                    && isFieldOrProperty!(__traits(getMember,U,name))
                    && name[0] != "_"[0] )
            {
                typing ~= format("typeof(other.%s),\"%s\",",name,name);
                variables ~= format("other.%s,", name);
            }
        }

        foreach (name; __traits(allMembers, T))
        {
            static if (__traits(compiles, isFieldOrProperty!(
                __traits(getMember, T, name)))
                     && __traits(compiles, ( in T u ) {
                auto a = __traits(getMember, u, name); 
                Tuple!(typeof(a),name)(a); } )
                && isFieldOrProperty!(__traits(getMember,T,name))
                     && name[0] != "_"[0] )
                {
                bool contains = false;
                foreach (name2; __traits(allMembers, U))
                {
                    if (name == name2)
                        contains = true;
                }
                if (!contains)
                {
                    typing ~= format("typeof(base.%s),\"%s\",",name,name);
                    variables ~= format("base.%s,",name);
                }
            }
        }
        return format("return %s)%s);", typing[0 .. $ - 1], variables[0 .. $ - 1] );
    }

    auto merge(T base, U other)
    {
        mixin(injectCode());
    }
}

///
unittest
{
    import std.range : front;

    auto xs = ["a", "b"];
    auto ys = ["c", "d"];
    auto labels = ["e", "f"];
    auto aes = Aes!(string[], "x", string[], "y", string[], "label")(xs, ys, labels);

    auto nlAes = merge(aes, Aes!(NumericLabel!(string[]), "x",
        NumericLabel!(string[]), "y")(NumericLabel!(string[])(aes.x),
        NumericLabel!(string[])(aes.y)));

    assertEqual(nlAes.x.front[0], 0);
    assertEqual(nlAes.label.front, "e");
}

unittest
{
    auto pnt = Tuple!(double, "x", double, "y", string, "label" )( 1.0, 2.0, "Point" );
    auto merged = DefaultValues.merge( pnt );
    assertEqual( merged.x, 1.0 );
    assertEqual( merged.y, 2.0 );
    assertEqual( merged.colour, "black" );
    assertEqual( merged.label, "Point" );
}

/// 
unittest
{
    struct Point { double x; double y; string label = "Point"; }
    auto pnt = Point( 1.0, 2.0 );

    auto merged = DefaultValues.merge( pnt );
    assertEqual( merged.x, 1.0 );
    assertEqual( merged.y, 2.0 );
    assertEqual( merged.colour, "black" );
    assertEqual( merged.label, "Point" );
}


static import ggplotd.range;
/**
Deprecated: Moved to ggplotd.range;
*/
deprecated alias mergeRange = ggplotd.range.mergeRange;
