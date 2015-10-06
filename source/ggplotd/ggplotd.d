module ggplotd.ggplotd;

import cconfig = cairo.c.config;
import cpdf = cairo.pdf;
import csvg = cairo.svg;
import cairo = cairo;

import ggplotd.aes;
import ggplotd.geom;
import ggplotd.bounds;
import ggplotd.scale;

void ggplotdPNG(GR, SF)( GR geomRange, SF scale )
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
        auto context = cairo.Context(surface);
        import std.stdio;
        context = scale( context, bounds );
        context = geom.draw( context );
        context.identityMatrix();
        context.stroke();
    }
    surface.writeToPNG("plotcli.png");
}

unittest
{
    auto aes = Aes!(double[],double[], string[])( [1.0,0.9],[2.0,1.1],
            ["c"] );
    auto ge = geomPoint( aes );
    ggplotdPNG( ge, scale() );
}
