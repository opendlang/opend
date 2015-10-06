module ggplotd.ggplotd;

import cconfig = cairo.c.config;
import cpdf = cairo.pdf;
import csvg = cairo.svg;
import cairo = cairo;

import ggplotd.aes;
import ggplotd.geom;
import ggplotd.bounds;

void ggplotdPNG(GR)( GR geomRange )
{
    import std.algorithm : reduce;
    auto width = 400;
    auto height = 400;
    auto surface = new cairo.ImageSurface(
            cairo.Format.CAIRO_FORMAT_ARGB32,
            width, height);
    // TODO use reduce to get the all encompasing bounds
    AdaptiveBounds bounds;
    //bounds = reduce!((a,b) => a.adapt( b.bounds ))
    //    ( bounds, geomRange );
    foreach( geom; geomRange )
    {
        bounds.adapt( geom.bounds );
    }
    

    foreach( geom; geomRange )
    {
        // TODO transparent context?
        // TODO use bounds from geom
        auto context = cairo.Context(surface);
        geom.draw( context );
        context.identityMatrix();
        context.stroke();
    }
    surface.writeToPNG("plotcli.png");
}

unittest
{
    auto aes = Aes!(double[],double[], string[])( [1.0],[2.0],["c"] );
    auto gl = geomLine( aes );
    ggplotdPNG( gl );
}
