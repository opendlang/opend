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
