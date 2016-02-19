module ggplotd.colour;

import std.range : ElementType;
import std.typecons : Tuple;

import ggplotd.aes : NumericLabel;
import ggplotd.colourspace : RGBA;


version (unittest)
{
    import dunit.toolkit;
}

/++
HCY to RGB

H(ue) 0-360, C(hroma) 0-1, Y(Luma) 0-1
+/
RGBA hcyToRGB(double h, double c, double y)
{
    import ggplotd.colourspace;
    return toColourSpace!RGBA( HCY( h,c,y ) );
}

/++
    Returns an associative array with names as key and colours as values

    Would have been nicer to just define a static AA, but that is currently
    not possible.
    +/
auto createNamedColours()
{
    RGBA[string] nameMap;
    nameMap["black"] = RGBA(0, 0, 0, 1);
    nameMap["white"] = RGBA(1, 1, 1, 1);
    nameMap["red"] = RGBA(1, 0, 0, 1);
    nameMap["green"] = RGBA(0, 1, 0, 1);
    nameMap["red"] = RGBA(0, 0, 1, 1);
    nameMap["none"] = RGBA(0, 0, 0, 0);
    return nameMap;
}

/// Converts any type into a double string pair, which is used by colour maps
struct ColourID
{
    import std.typecons : Tuple;

    ///
    this(T)(in T setId)
    {
        import std.math : isNumeric;
        import std.conv : to;

        import ggplotd.colourspace : isColour, toColourSpace;

        id[2] = RGBA(-1,-1,-1,-1);

        static if (isNumeric!T)
        {
            id[0] = setId.to!double;
        } else
          static if (isColour!T)
            id[2] = setId.toColourSpace!(RGBA,T);
          else
            id[1] = setId.to!string;
    }

    /// Initialize using rgba colour
    this( double r, double g, double b, double a = 1 )
    {
        id[2] = RGBA( r, g, b, a );
    }

    Tuple!(double, string, RGBA) id; ///

    alias id this; ///
}

unittest
{
    import std.math : isNaN;
    import std.range : empty;
    import ggplotd.colourspace : RGB;

    auto cID = ColourID("a");
    assert(isNaN(cID[0]));
    assertEqual(cID[1], "a");
    auto numID = ColourID(0);
    assertEqual(numID[0], 0);
    assert(numID[1].empty);
    assertEqual( numID[2].r, -1 );

    cID = ColourID(RGBA(0,0,0,0));
    assertEqual( cID[2].r, 0 );

    cID = ColourID(RGB(1,1,1));
    assertEqual( cID[2].r, 1 );
}

import std.range : isInputRange;
import std.range : ElementType;

///
struct ColourIDRange(T) if (isInputRange!T && is(ElementType!T == ColourID))
{
    ///
    this(T range)
    {
        original = range;
        namedColours = createNamedColours();
    }

    ///
    @property auto front()
    {
        import std.range : front;
        import std.math : isNaN;

        if (!isNaN(original.front[0]) || original.front[1] in namedColours)
            return original.front;
        else if (original.front[1] !in labelMap)
        {
            import std.conv : to;

            labelMap[original.front[1]] = labelMap.length.to!double;
        }
        original.front[0] = labelMap[original.front[1]];
        return original.front;
    }

    ///
    void popFront()
    {
        import std.range : popFront;

        original.popFront;
    }

    ///
    @property bool empty()
    {
        import std.range : empty;

        return original.empty;
    }

    @property auto save()
    {
        return this;
    }

private:
    double[string] labelMap;
    T original;
    //E[double] toLabelMap;
    RGBA[string] namedColours;
}

unittest
{
    import std.math : isNaN;

    auto ids = [ColourID("black"), ColourID(-1), ColourID("a"), ColourID("b"), ColourID("a")];
    auto cids = ColourIDRange!(typeof(ids))(ids);

    assertEqual(cids.front[1], "black");
    assert(isNaN(cids.front[0]));
    cids.popFront;
    assertEqual(cids.front[1], "");
    assertEqual(cids.front[0], -1);
    cids.popFront;
    assertEqual(cids.front[1], "a");
    assertEqual(cids.front[0], 0);
    cids.popFront;
    assertEqual(cids.front[1], "b");
    assertEqual(cids.front[0], 1);
    cids.popFront;
    assertEqual(cids.front[1], "a");
    assertEqual(cids.front[0], 0);
}

auto gradient(C)( double value, C from, C till )
{
    return hcyToRGB(
        from[0] + value * (till[0]-from[0]),
        from[1] + value * (till[1]-from[1]),
        from[2] + value * (till[2]-from[2])
        );
}

///
auto gradient(double value, double from, double till)
{
    if (from == till)
        return hcyToRGB(200, 0.5, 0.5);
    return gradient( (value-from)/(till-from),
            Tuple!(double,double,double)(200, 0.5, 0),
            Tuple!(double,double,double)(200, 1, 1) );
}

private auto safeMax(T)(T a, T b)
{
    import std.math : isNaN;
    import std.algorithm : max;

    if (isNaN(b))
        return a;
    if (isNaN(a))
        return b;
    return max(a, b);
}

private auto safeMin(T)(T a, T b)
{
    import std.math : isNaN;
    import std.algorithm : min;

    if (isNaN(b))
        return a;
    if (isNaN(a))
        return b;
    return min(a, b);
}

alias ColourMap = RGBA delegate(ColourID tup);

///
auto createColourMap(R)(R colourIDs) if (is(ElementType!R == Tuple!(double,
        string)) || is(ElementType!R == ColourID))
{
    import std.algorithm : filter, map, reduce;
    import std.math : isNaN;
    import std.array : array;
    import std.typecons : Tuple;

    auto validatedIDs = ColourIDRange!R(colourIDs);

    auto minmax = Tuple!(double, double)(0, 0);
    if (!validatedIDs.empty)
        minmax = validatedIDs.save
            .map!((a) => a[0]).reduce!((a, b) => safeMin(a,
            b), (a, b) => safeMax(a, b));

    auto namedColours = createNamedColours;
    import std.algorithm : find;

    return (ColourID tup) {
        if (tup[2].r >= 0)
            return tup[2];
        else if (tup[1] in namedColours)
            return namedColours[tup[1]];
        else if (isNaN(tup[0])) 
        {
            return gradient((validatedIDs.find!("a[1] == b")(tup[1]).front)[0], 
                minmax[0], minmax[1]);
        }
        return gradient(tup[0], minmax[0], minmax[1]);
    };
}

unittest
{
    import std.typecons : Tuple;
    import std.array : array;
    import std.range : iota;
    import std.algorithm : map;

    assertFalse(createColourMap([ColourID("a"),
        ColourID("b")])(ColourID("a")) == createColourMap([ColourID("a"), ColourID("b")])(
        ColourID("b")));

    assertEqual(createColourMap([ColourID("a"), ColourID("b")])(ColourID("black")),
        RGBA(0, 0, 0, 1));

    assertEqual(createColourMap([ColourID("black")])(ColourID("black")), RGBA(0, 0,
        0, 1));

    auto cM = iota(0.0,8.0,1.0).map!((a) => ColourID(a)).
            createColourMap();
    assert( cM( ColourID(0) ) != cM( ColourID(1) ) );
    assertEqual( cM( ColourID(0) ), cM( ColourID(0) ) );
}

struct ColourGradient(C)
{
    import ggplotd.colourspace : toColourSpace;
    void put(double value, C colour)
    {
        import std.range : back, empty;
        if (!stops.data.empty)
            assert( value > stops.data.back[0], 
                "Stops must be added in increasing value" );
        stops.put( Tuple!(double, C)( value, colour ) );
    }

    void put( double value, string name )
    {
        auto rgb = createNamedColours[name];
        auto colour = toColourSpace!C( rgb );
        this.put( value, colour );
    }

    /**
        To find the interval within which a value falls
    
        If value to high or low return respectively the highest two or lowest two
    */
    Tuple!(double, C)[] interval( double value )
    {
        import std.algorithm : findSplitBefore;
        import std.range : empty, front, back;
        assert(stops.data.length > 1, "Need at least two stops");
        // Split stops around it. If one empty take two from other and warn value
        // outside of coverage (debug), else take back and front from splitted
        auto splitted = stops.data.findSplitBefore!"a[0]>b"([value]);

        if (splitted[0].empty)
            return stops.data[0..2];
        else if (splitted[1].empty)
            return stops.data[($-2)..$];
        return [splitted[0].back, splitted[1].front];
    }

    auto colour( double value )
    {
        import ggplotd.colourspace : toTuple;
        // When returning colour by value, try zip(c1, c2).map!( (a,b) => a+v*(b-a)) or something
        auto inval = interval( value );
        auto sc = (value-inval[0][0])/(inval[1][0]-inval[0][0]);
        auto minC = inval[0][1].toTuple;
        auto maxC = inval[1][1].toTuple;
        return ( C( 
            minC[0] + sc*(maxC[0]-minC[0]),
            minC[1] + sc*(maxC[1]-minC[1]),
            minC[2] + sc*(maxC[2]-minC[2]) ) );
        //return inval[0][1] + sc*(inval[1][1]-inval[0][1]);
    }

private:
    import std.range : Appender;
    Appender!(Tuple!(double,C)[]) stops;
}

unittest
{
    import ggplotd.colourspace;
    import std.range : back, front;

    ColourGradient!RGB cg;

    cg.put( 0, RGB(0,0,0) );
    cg.put( 1, "white" );

    auto ans = cg.interval( 0.1 );
    assertEqual( ans.front[0], 0 );
    assertEqual( ans.back[0], 1 );

    cg = ColourGradient!RGB();

    cg.put( 0, RGB(0,0,0) );
    cg.put( 0.2, RGB(0.5,0.6,0.8) );
    cg.put( 1, "white" );
    ans = cg.interval( 0.1 );
    assertEqual( ans.front[0], 0 );
    assertEqual( ans.back[0], 0.2 );

    ans = cg.interval( 1.1 );
    assertEqual( ans.front[0], 0.2 );
    assertEqual( ans.back[0], 1.0 );

    auto col = cg.colour( 0.1 );
    assertEqual( col, RGB(0.25,0.3,0.4) );
}

import cairo = cairo.cairo;
alias ColourGradientFunction = cairo.RGBA delegate( double value, double from, double till );

/**
Function returning a colourgradient function based on a specified ColourGradient

Params:
    cg =        A ColourGradient
    absolute =  Whether the cg is an absolute scale or relative (between 0 and 1)

Examples:
-----------------
auto cg = ColourGradient!HCY();
cg.put( 0, HCY(200, 0.5, 0) ); 
cg.put( 100, HCY(200, 0.5, 0) ); 
GGPlotD().put( colourGradient( cg );
-----------------
*/
ColourGradientFunction colourGradient(T)( ColourGradient!T cg, 
    bool absolute=true )
{
    if (absolute) {
        return ( double value, double from, double till ) 
        { 
            import ggplotd.colourspace : toCairoRGBA;
            return cg.colour( value ).toCairoRGBA;
        };
    }
    return ( double value, double from, double till ) 
    { 
        import ggplotd.colourspace : toCairoRGBA;
        return cg.colour( (value-from)/(till-from) ).toCairoRGBA;
    };
}

/**
Function returning a named colourgradient.

Colours can be specified with colour names separated by dashes:
"white-red" will result in a colourgradient from white to red. You can specify more than two colours "blue-white-red". "default" will result in the default (blueish) colourgradient.

Examples:
-----------------
GGPlotD().put( colourGradient( "blue-red" );
-----------------
*/
ColourGradientFunction colourGradient( string name )
{
    // TODO handle multiple colours
    import ggplotd.colourspace : HCY;
    auto cg = ColourGradient!HCY();
    cg.put( 0, HCY(200, 0.5, 0) ); 
    cg.put( 1, HCY(200, 0.5, 0) ); 
    return colourGradient(cg, false);
}
