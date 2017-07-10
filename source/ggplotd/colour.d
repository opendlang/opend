/**
Deal with colour related struct/functions, such as ColourSpaces etc.
*/
module ggplotd.colour;

import std.range : ElementType;
import std.typecons : Tuple;

import ggplotd.colourspace : RGBA;

version (unittest)
{
    import dunit.toolkit;
}

/**
Convert a name (string) into a Nullable!colour.

Internally calls std.experimental.colorFromString and names supported are therefore exactly the same. This inludes all the colors defined by X11, adopted by the W3C, SVG, and other popular libraries.
*/
auto namedColour(in string name)
{
    import std.experimental.color : colorFromString;
    import ggplotd.colourspace : toColourSpace, RGB;
    import std.typecons : Nullable;
    Nullable!RGB colour;
    try
    {
        colour = colorFromString(name).toColourSpace!RGB;
    } catch (Throwable) {}
    return colour;
}

unittest
{
    import std.typecons : tuple;
    import ggplotd.colourspace : toTuple;
    auto col = namedColour("red");
    assert(!col.isNull);
    assertEqual(col.toTuple, tuple(1,0,0));

    auto col2 = namedColour("this colour does not exist you idiot");
    assert(col2.isNull);
}

struct ColourGradient(C)
{
    import ggplotd.colourspace : toColourSpace;
    void put( in double value, in C colour)
    {
        import std.range : back, empty;
        if (!stops.data.empty)
            assert( value > stops.data.back[0], 
                "Stops must be added in increasing value" );
        stops.put( Tuple!(double, C)( value, colour ) );
    }

    void put( in double value, string name )
    {
        auto rgb = namedColour(name);
        assert(!rgb.isNull, "Unknown colour name");
        auto colour = toColourSpace!C(rgb.get());
        this.put( value, colour );
    }

    /**
        To find the interval within which a value falls
    
        If value to high or low return respectively the highest two or lowest two
    */
    auto interval( in double value ) const
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

    /**
    Get the colour associated with passed value
    */
    auto colour( in double value ) const
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
    }

private:
    import std.range : Appender;
    Appender!(Tuple!(double,C)[]) stops;
}

unittest
{
    import ggplotd.colourspace : RGB;
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

/// 
alias ColourGradientFunction = RGBA delegate( double value, double from, double till );

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
GGPlotD().put( colourGradient( cg ) );
-----------------
*/
ColourGradientFunction colourGradient(T)( in ColourGradient!T cg, 
    bool absolute = false )
{
    if (absolute) {
        return ( double value, double from, double till ) 
        {
            import ggplotd.colourspace : RGBA, toColourSpace;
            return cg.colour( value ).toColourSpace!RGBA;
        };
    }
    return ( double value, double from, double till ) 
    { 
        import ggplotd.colourspace : RGBA, toColourSpace;
        return cg.colour( (value-from)/(till-from) ).toColourSpace!RGBA;
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
ColourGradientFunction colourGradient(T)( string name )
{
    import std.algorithm : splitter;
    import std.range : empty, walkLength;
    if ( !name.empty && name != "default" )
    {
        import ggplotd.colourspace : toColourSpace;
        auto cg = ColourGradient!T();
        auto splitted = name.splitter("-");
        immutable dim = splitted.walkLength;
        if (dim == 1)
        {
            auto col = namedColour(splitted.front);
            assert(!col.isNull, "Unknown named colour");
            auto c = col.get().toColourSpace!T; 
            cg.put(0, c );
            cg.put(1, c );
        }
        if (dim > 1)
        {
            auto value = 0.0;
            immutable width = 1.0/(dim-1);
            foreach(sp ; splitted)
            {
                auto col = namedColour(sp);
                assert(!col.isNull, "Unknown named colour");
                cg.put(value, col.get().toColourSpace!T);
                value += width;
            }
        }
        return colourGradient(cg, false);
    }
    import std.math : PI;
    import ggplotd.colourspace : HCY;
    auto cg = ColourGradient!HCY();
    cg.put( 0, HCY(200/360.0, 0.5, 0.1)); 
    cg.put( 1, HCY(200/360.0, 0.5, 0.8)); 
    return colourGradient(cg, false);
}

unittest
{
    import ggplotd.colourspace : HCY;
    auto cf = colourGradient!HCY( "red-white-blue" );
    assertEqual( cf( -1, -1, 2 ).r, 1 );
    assertEqual( cf( -1, -1, 2 ).g, 0 );
    assertEqual( cf( 2, -1, 2 ).b, 1 );
    assertLessThan( cf( 2, -1, 2 ).g, 1e-5 );
    assertEqual( cf( 0.5, -1, 2 ).b, 1 );
    assertEqual( cf( 0.5, -1, 2 ).g, 1 );
}
