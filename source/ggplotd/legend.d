module ggplotd.legend;

import cairo = cairo;

import ggplotd.colour : ColourIDRange, ColourGradient;

/// Draw a legend for a continuous value to the given surface
auto drawContinuousLegend(CR, CG)
    (ref cairo.Surface surface, int width, int height,
        CR colourRange, CG colourGradient )
{
    import std.algorithm : reduce;
    import std.typecons : tuple;

    import ggplotd.ggplotd : GGPlotD;
    import ggplotd.algorithm : safeMin, safeMax;
    import ggplotd.aes : Aes;
    import ggplotd.geom : geomPolygon;
    // TODO: constify
    // TODO: make sure to test with alternative coloursceme (the hist2D examples, should suffice)
    auto gg = GGPlotD();
    gg.put( colourGradient );

    auto minmax = reduce!((a,b) => safeMin(a, b.to!double),
        (a,b) => safeMax(a, b.to!double))(tuple(.0,.0), colourRange);

    auto aes = Aes!( double[], "x", double[], "y", typeof(minmax[0].init)[], "colour" )
        ( [0.0,0,1,1], 
            [minmax[0], minmax[1], minmax[1], minmax[0]], 
            [minmax[0], minmax[1], minmax[1], minmax[0]] );
    gg.put( geomPolygon(aes) );
    gg.drawToSurface( surface, width, height );
    return surface;
}

/+
Continuous in many way is a small GGPlotD object, that can be drawn to the main surface. So just define an aes for the polygon, with the apropiate y values. Set x ticks to empty.

Discrete is just number of lines (unmasked) with labels next to them. We can recreate this, as a GGPlotD() struct, by moving axis outside of plane (offset).

Note that not only colour, but also size is often used as an indicator.
+/
