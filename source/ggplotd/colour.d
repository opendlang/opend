module ggplotd.colour;

import std.range : ElementType;

import cairo.cairo : RGB;

//import std.experimental.color.conv;
//import std.experimental.color.rgb;
//import std.experimental.color.hsx;

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
