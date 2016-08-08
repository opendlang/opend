module ggplotd.legend;

import cairo = cairo;

import ggplotd.colour : ColourIDRange, ColourGradient;

private struct Legend
{
    string type = "continuous";
    int height = 70;
    int width = 80;
}

/++
Create a legend using a continuous scale

Params:
    width Optional width in pixels
    height Optional height in pixels
+/
auto continuousLegend(int width = 80, int height = 70)
{
    return Legend("continuous", width, height);
}

/++
Create a legend using a discrete scale

Params:
    width Optional width in pixels
    height Optional height in pixels
+/
auto discreteLegend(int width = 80, int height = 70)
{
    return Legend("discrete", width, height);
}


/// Draw a legend for a continuous value to the given surface
auto drawContinuousLegend(CR, CG)
    (ref cairo.Surface surface, int width, int height,
        CR colourRange, CG colourGradient )
{
    import std.algorithm : reduce;
    import std.typecons : tuple;

    import ggplotd.ggplotd : GGPlotD, Margins;
    import ggplotd.algorithm : safeMin, safeMax;
    import ggplotd.aes : Aes;
    import ggplotd.geom : geomPolygon;
    import ggplotd.axes : xaxisShow;
    // TODO: constify
    // TODO: make sure to test with alternative coloursceme (the hist2D examples, should suffice)
    auto gg = GGPlotD();
    gg.put(Margins(10, 0, 0, 0));
    gg.put( colourGradient );

    auto minmax = reduce!((a,b) => safeMin(a, b.to!double),
        (a,b) => safeMax(a, b.to!double))(tuple(.0,.0), colourRange);

    auto aes = Aes!( double[], "x", double[], "y", typeof(minmax[0].init)[], "colour" )
        ( [0.0,0,1,1], 
            [minmax[0], minmax[1], minmax[1], minmax[0]], 
            [minmax[0], minmax[1], minmax[1], minmax[0]] );
    gg.put( geomPolygon(aes) );
    gg.put( xaxisShow(false) );
    
    gg.drawToSurface( surface, width, height );
    return surface;
}

/// Draw a legend for a discrete value to the given surface
auto drawDiscreteLegend(CR, CG)
    (ref cairo.Surface surface, int width, int height,
        CR colourRange, CG colourGradient )
{
    import std.algorithm : map;
    import std.array : array;
    import std.conv : to;
    import std.range : repeat, walkLength;
    import std.typecons : tuple;

    import ggplotd.ggplotd : GGPlotD, Margins;
    import ggplotd.algorithm : safeMin, safeMax;
    import ggplotd.aes : Aes;
    import ggplotd.geom : geomRectangle;
    import ggplotd.axes : xaxisShow, xaxisRange;
    import ggplotd.range : uniquer;
    // TODO: constify
    // TODO: make sure to test with alternative coloursceme (the hist2D examples, should suffice)
    auto gg = GGPlotD();
    gg.put(Margins(10, 0, 0, 0));
    gg.put(colourGradient);

    //auto ys = colourRange.uniquer.map!((a) => a.to!double);
    auto cols = colourRange.uniquer.map!((a) => a.to!string).array;
    auto xs = (1.0).repeat(cols.walkLength);
    auto dims = (0.8).repeat(cols.walkLength);
    auto aes = Aes!( typeof(xs), "x", typeof(cols), "y", 
        typeof(cols), "colour", typeof(dims), "width",
        typeof(dims), "height", typeof(xs), "fill")
        ( xs, cols, cols, dims, dims, xs);
    gg.put( geomRectangle(aes) );

    gg.put( xaxisShow(false) );
    gg.put( xaxisRange(0.5, 1.0) );
    gg.drawToSurface( surface, width, height );
    return surface;
}
