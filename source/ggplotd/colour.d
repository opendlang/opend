module ggplotd.colour;

import std.range : ElementType;
import std.typecons : Tuple;

import cairo.cairo : RGB;

//import std.experimental.color.conv;
//import std.experimental.color.rgb;
//import std.experimental.color.hsx;

import ggplotd.aes : NumericLabel;

version(unittest)
{
    import dunit.toolkit;
}

// TODO build helper functions that returns a function 
// like below with to and from colours

auto colourGradient(R)( R colourIDs )
{
    import std.range : iota, enumerate, walkLength;
    RGB[ElementType!R] colourMap;
    auto values = iota( 0, 1, 1.0/colourIDs.walkLength );
    foreach( ref i, col; colourIDs.enumerate )
        colourMap[col] = 
            RGB(1.0, 0.0, 0 + values[i]);
    //RGB!("rgba", float)
    return (ElementType!R id)
    {
        return colourMap[id];
    };
}

unittest
{
    assertEqual(colourGradient(["a","b"])("a"), RGB(1,0,0));
    assertEqual(colourGradient(["a","b"])("b"), RGB(1,0,0.5));
}

/// Converts any type into a double string pair, which is used by colour maps
struct ColourID
{
    import std.typecons : Tuple;

    ///
    this(T)( in T setId )
    {
        import std.math : isNumeric;
        import std.conv : to;
        static if (isNumeric!T)
        {
            id[0] = setId.to!double;
        }
        else 
            id[1] = setId.to!string;
    }

    Tuple!(double, string) id; ///

    alias id this; ///
}

unittest 
{
    import std.math : isNaN;
    import std.range : empty;
    auto cID = ColourID( "a" );
    assert( isNaN(cID[0]) );
    assertEqual( cID[1], "a" );
    auto numID = ColourID( 0 );
    assertEqual( numID[0], 0 );
    assert( numID[1].empty );
}

auto gradient( double value, double from, double till )
{
    return RGB( 1, 0, (value-from)/(till-from) );
}

auto createColourMap(R)( R colourIDs )
    if (is(ElementType!R == Tuple!(double, string)))
{
    import std.algorithm : map, reduce;
    import std.typecons : Tuple;

    auto minmax = colourIDs 
        .map!((a) => a[0])
        .reduce!("min(a,b)","max(a,b)");
    //RGB!("rgba", float)
    return ( Tuple!(double, string) tup )
    {
        if (tup[1]=="black")
            return RGB(0,0,0);
        return gradient(tup[0],minmax[0],minmax[1]);
    };
}


auto createColourMap(R)( R colourIDs )
    if (!is(ElementType!R == Tuple!(double, string)))
{
    import std.algorithm : map, reduce;
    import ggplotd.aes : NumericLabel;
    import std.typecons : Tuple;

    auto r = NumericLabel!R( colourIDs );

    auto minmax = r
        .map!((a) => a[0])
        .reduce!("min(a,b)","max(a,b)");
    //RGB!("rgba", float)
    return ( Tuple!(double, string) tup )
    {
        if (tup[1]=="black")
            return RGB(0,0,0);
        return gradient(tup[0],minmax[0],minmax[1]);
    };
}

unittest
{
    import std.typecons : Tuple;
    assertEqual(createColourMap(["a","b"])(
                Tuple!(double,string)(0,"a")), RGB(1,0,0));
    assertEqual(createColourMap(["a","b"])(
                Tuple!(double,string)(0.5,"b")), RGB(1,0,0.5));

    assertEqual(createColourMap(["a","b"])(
                Tuple!(double,string)(0.5,"black")), RGB(0,0,0));

    // Colour is numericLabel type
    import ggplotd.aes : NumericLabel;
    assertEqual(createColourMap(
                NumericLabel!(string[])(["a","b"]))(
                Tuple!(double,string)(0.5,"b")), RGB(1,0,0.5));
}

