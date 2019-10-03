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

import std.typecons : tuple;
/++
    Map data fields to "aesthetic" fields understood by the ggplotd geom functions

    The most commonly used aesthetic fields in ggplotd are "x" and "y". Which further data
    fields are used/required depends on the geom function being called. 
    
    Other common fields: 
    $(UL
        $(LI "colour": Identifier for the colour. In general data points with different colour ids get different colours. This can be almost any type. You can also specify the colour by name or cairo.Color type if you want to specify an exact colour (any type that isNumeric, cairo.Color.RGB(A), or can be converted to string))
        $(LI "size": Gives the relative size of points/lineWidth etc.)
        $(LI "label": Text labels (string))
        $(LI "angle": Angle of printed labels in radians (double))
        $(LI "alpha": Alpha value of the drawn object (double))
        $(LI "mask": Mask the area outside the axes. Prevents you from drawing outside of the area (bool))
        $(LI "fill": Whether to fill the object/holds the alpha value to fill with (double).))

    In practice aes is an alias for std.typecons.tuple.

Examples:
---------------------------
struct Diamond 
{
    string clarity = "SI2";
    double carat = 0.23;
    double price = 326;
}

Diamond diamond;

auto mapped = aes!("colour", "x", "y")(diamond.clarity, diamond.carat, diamond.price);
assert(mapped.colour == "SI2");
assert(mapped.x == 0.23);
assert(mapped.y == 326);
---------------------------

Examples:
---------------------------
import std.typecons : Tuple;
// aes returns a named tuple
assert(aes!("x", "y")(1.0, 2.0) == Tuple!(double, "x", double, "y")(1.0, 2.0));
---------------------------
 
    +/
alias aes = tuple;

unittest
{
    struct Diamond 
    {
        string clarity = "SI2";
        double carat = 0.23;
        double price = 326;
    }

    Diamond diamond;

    auto mapped = aes!("colour", "x", "y")(diamond.clarity, diamond.carat, diamond.price);
    assertEqual(mapped.colour, "SI2");
    assertEqual(mapped.x, 0.23);
    assertEqual(mapped.y, 326);


    import std.typecons : Tuple;
    // aes is a convenient alternative to a named tuple
    assert(aes!("x", "y")(1.0, 2.0) == Tuple!(double, "x", double, "y")(1.0, 2.0));
}

///
unittest
{
    auto a = aes!(int, "y", int, "x")(1, 2);
    assertEqual( a.y, 1 );
    assertEqual( a.x, 2 );

    auto a1 = aes!("y", "x")(1, 2);
    assertEqual( a1.y, 1 );
    assertEqual( a1.x, 2 );

    auto a2 = aes!("y")(1);
    assertEqual( a2.y, 1 );


    import std.range : zip;
    import std.algorithm : map;
    auto xs = [0,1];
    auto ys = [2,3];
    auto points = xs.zip(ys).map!((t) => aes!("x", "y")(t[0], t[1]));
    assertEqual(points.front.x, 0);
    assertEqual(points.front.y, 2);
    points.popFront;
    assertEqual(points.front.x, 1);
    assertEqual(points.front.y, 3);
}

// TODO Also update default grouping if appropiate
/// Default values for most settings
static auto DefaultValues = aes!(
    "label", "colour", "size",
    "angle", "alpha", "mask", "fill",
	"labelAngle")
    ("", "black", 1.0, 0.0, 1.0, true, 0.0, 0.0);

/// Returns field if it exists, otherwise uses the passed default
auto fieldWithDefault(alias field, AES, T)(AES aes, T theDefault)
{
    static if (hasAesField!(AES, field))
        return __traits(getMember, aes, field);
    else
        return theDefault;
}

unittest 
{
    struct Point { double x; double y; string label = "Point"; }
    auto point = Point(1.0, 2.0);
    assertEqual(fieldWithDefault!("x")(point, "1"), 1.0);
    assertEqual(fieldWithDefault!("z")(point, "1"), "1");
}

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
    import std.meta : AliasSeq;
    template parseSpecs(Specs...)
    {
        import std.range : isInputRange, ElementType;
        static if (Specs.length < 2)
        {
            alias parseSpecs = AliasSeq!();
        }
        else static if (
             isInputRange!(Specs[0])
             && is(typeof(Specs[1]) : string)
        )
        {
            alias parseSpecs = AliasSeq!(
            ElementType!(Specs[0]), Specs[1],
                parseSpecs!(Specs[2 .. $]));
        }
        else
        {
            pragma(msg, Specs);
            static assert(0,
                "Attempted to instantiate Tuple with an " ~ "invalid argument: " ~ Specs[0].stringof);
        }
    }

    template parseTypes(Specs...)
    {
        import std.range : isInputRange;
        static if (Specs.length < 2)
        {
            alias parseTypes = AliasSeq!();
        }
        else static if (
             isInputRange!(Specs[0])
             && is(typeof(Specs[1]) : string)
        )
        {
            alias parseTypes = AliasSeq!(
                Specs[0], 
                parseTypes!(Specs[2 .. $]));
        }
        else
        {
            pragma(msg, Specs);
            static assert(0,
                "Attempted to instantiate Tuple with an " ~ "invalid argument: " ~ Specs[0].stringof);
        }
    }

    // maps a type to its init value 
    private auto init(T)()
    {
        return T.init; 
    }

    // ArgsCall taken from https://dlang.org/library/std/meta/alias_seq.html
    private auto ref ArgCall(alias Func, arg)()
    {
        return Func!(arg)();
    }

    // Map taken from https://dlang.org/library/std/meta/alias_seq.html
    private template Map(alias Func, args...)
    {
        static if (args.length > 1)
        {
            alias Map = AliasSeq!(ArgCall!(Func, args[0]), Map!(Func, args[1 .. $]));
        }
        else
        {
            alias Map = ArgCall!(Func, args[0]);
        }
    }

    alias elementsType = parseSpecs!Specs;
    alias types = parseTypes!Specs;

    struct Aes
    {
        import std.range : zip;
        
        // from 2.080.0 on zip can return not only Zip, but also ZipShortest. On top of that it is not accessible from
        // outside. Therefore, use "typeof" the accessible convenience template function "zip" only. 
        private typeof(zip!types(Map!(init, types))) aes;

        // use explicit types as they are known from template argument deduction stage
        this(types args)
        {
            import std.range : zip;
            aes = zip(args);
        }

        void popFront()
        {
            aes.popFront;
        }

        auto @property empty() 
        {
            return aes.empty;
        }

        auto @property front()
        {
            return Tuple!(elementsType)( aes.front.expand );
        }
    }
}

/// Basic Aes usage
unittest
{
    auto aes = Aes!(double[], "x", double[], "y", string[], "colour")([0.0, 1],
        [2, 1.0], ["white", "white2"]);

    aes.popFront;
    assertEqual(aes.front.y, 1);
    assertEqual(aes.front.colour, "white2");

    auto aes2 = Aes!(double[], "x", double[], "y")([0.0, 1], [2.0, 1]);
    assertEqual(aes2.front.y, 2);

    import std.range : repeat;

    auto xs = repeat(0);
    auto aes3 = Aes!(typeof(xs), "x", double[], "y")(xs, [2.0, 1]);

    assertEqual(aes3.front.x, 0);
    aes3.popFront;
    aes3.popFront;
    assertEqual(aes3.empty, true);
}


import std.typetuple : TypeTuple;
private template fieldValues( T, Specs... )
{
    import std.typecons : Tuple, tuple;
    auto fieldValues( T t )
    {
        static if (Specs.length == 0)
            return tuple();
        else
            return tuple( __traits(getMember, t, Specs[0]),
                (fieldValues!(typeof(t), Specs[1..$])(t)).expand );
    }
}

unittest 
{
    struct Point { double x; double y; string label = "Point"; }
    auto pnt = Point( 1.0, 2.0 );
    auto fv = fieldValues!(Point, "x","y","label")(pnt);
    assertEqual(fv[0], 1.0);
    assertEqual(fv[1], 2.0);
    assertEqual(fv[2], "Point");
    auto fv2 = fieldValues!(Point, "x","label")(pnt);
    assertEqual(fv2[0], 1.0);
    assertEqual(fv2[1], "Point");
}

private template typeAndFields( T, Specs... )
{
    import std.meta : AliasSeq;
    static if (Specs.length == 0)
        alias typeAndFields = AliasSeq!();
    else
        alias typeAndFields = AliasSeq!( 
            typeof(__traits(getMember, T, Specs[0])), 
            Specs[0], typeAndFields!(T, Specs[1..$]) );
}

unittest 
{
    struct Point { double x; double y; string label = "Point"; }
    alias fts = typeAndFields!(Point, "x","y","label");

    auto pnt = Point( 1.0, 2.0 );
    auto fv = fieldValues!(Point, "x","y","label")(pnt);
    auto tp = Tuple!( fts )( fv.expand );
    assertEqual(tp.x, 1.0);
    assertEqual(tp.y, 2.0);
    assertEqual(tp.label, "Point");
 }

// Default fields to group by
alias DefaultGroupFields = TypeTuple!("alpha","colour","label");

/++
    Groups data by colour label etc.

    Will also add DefaultValues for label etc to the data. It is also possible to specify exactly what to group by on as a template parameter. See example.
+/
template group(Specs...)
{
    static if (Specs.length == 0)
    {
        alias Specs = DefaultGroupFields;
    }

    auto extractKey(T)(T a)
    {
        import ggplotd.meta : ApplyLeft;
        import std.meta : Filter;
        alias hasFieldT = ApplyLeft!(hasAesField, T);
        alias fields = Filter!(hasFieldT, Specs);
        static if (fields.length == 0)
            return 1;
        else
            return fieldValues!(T, fields)(a);
    } 

    auto group(AES)(AES aes)
    {
        import ggplotd.range : groupBy;
        return aes.groupBy!((a) => extractKey(a)).values;
    }
}

///
unittest
{
    import std.range : walkLength;
    auto aes = Aes!(double[], "x", string[], "colour", double[], "alpha")
        ([0.0,1,2,3], ["a","a","b","b"], [0.0,1,0,1]);

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

private template aesFields(T)
{
    import std.traits;
    template isAesField(alias name)
    {
        import painlesstraits : isFieldOrProperty;
        import std.typecons : Tuple;
        // To be honest, I am not sure why isFieldOrProperty!name does not
        // suffice (instead of the first two), but that 
        // results in toHash for Tuple
        static if ( __traits(compiles, isFieldOrProperty!(
            __traits(getMember, T, name) ) )
             && isFieldOrProperty!(__traits(getMember,T,name))
             && name[0] != "_"[0]
             && __traits(compiles, ( in T u ) {
            auto a = __traits(getMember, u, name); 
            Tuple!(typeof(a),name)(a); } )
            )
            enum isAesField = true;
        else
            enum isAesField = false;
    }

    import std.meta : Filter;
    enum aesFields = Filter!(isAesField, __traits(allMembers, T));
}

unittest
{
    struct Point { double x; double y; string label = "Point"; }
    assertEqual( "x", aesFields!Point[0] );
    assertEqual( "y", aesFields!Point[1] );
    assertEqual( "label", aesFields!Point[2] );
    assertEqual( 3, aesFields!(Point).length );

    auto pnt2 = Tuple!(double, "x", double, "y", string, "label" )( 1.0, 2.0, "Point" );
    assertEqual( "x", aesFields!(typeof(pnt2))[0] );
    assertEqual( "y", aesFields!(typeof(pnt2))[1] );
    assertEqual( "label", aesFields!(typeof(pnt2))[2] );
    assertEqual( 3, aesFields!(typeof(pnt2)).length );
}

package template hasAesField(T, alias name)
{
    enum bool hasAesField = (function() {
        bool has = false;
        foreach (name2; aesFields!T)
        { 
            if (name == name2)
                has = true;
        }
        return has;
    })();
}

unittest
{
    struct Point { double x; double y; string label = "Point"; }
    static assert( hasAesField!(Point, "x") );
    static assert( !hasAesField!(Point, "z") );
}

/++
Merge two types by their members. 

If it has similar named members, then it uses the second one.

returns a named Tuple (or Aes) with all the members and their values. 
+/
template merge(T, U)
{
    auto merge(T base, U other)
    {
        import ggplotd.meta : ApplyLeft;
        import std.meta : Filter, AliasSeq, templateNot;
        alias fieldsU = aesFields!U;
        alias notHasAesFieldU = ApplyLeft!(templateNot!(hasAesField),U);
        alias fieldsT = Filter!(notHasAesFieldU, aesFields!T);

        auto vT = fieldValues!(T, fieldsT)(base);
        auto vU = fieldValues!(U, fieldsU)(other);

        return Tuple!(AliasSeq!(
            typeAndFields!(T,fieldsT),
            typeAndFields!(U,fieldsU)
            ))(vT.expand, vU.expand);
    }
}

unittest
{
    auto pnt = Tuple!(double, "x", double, "y", string, "label" )( 1.0, 2.0, "Point" );
    auto merged = DefaultValues.merge( pnt );
    assertEqual( merged.x, 1.0 );
    assertEqual( merged.y, 2.0 );
    assertEqual( merged.colour, "black" );
    assertEqual( merged.label, "Point" );

    // Test whether type/ordering is consistent
    // Given enough benefit we can break this, but we'll have to adapt plotcli to match,
    // which to be fair is relatively straightforward
    static assert( is(Tuple!(string, "colour", double, "size", 
		double, "angle", double, "alpha", bool, "mask", 
		double, "fill", double, "labelAngle", 
		double, "x", double, "y", string, "label") == typeof(merged) ) );
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
