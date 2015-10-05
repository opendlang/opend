module ggplotd.ggplotd;

import cconfig = cairo.c.config;
import cpdf = cairo.pdf;
import csvg = cairo.svg;
import cairo = cairo;

void ggplotdPNG(GR)( GR geomRange )
{
    auto width = 400;
    auto height = 400;
    auto surface = new cairo.ImageSurface(
            cairo.Format.CAIRO_FORMAT_ARGB32,
            width, height);
    foreach( geom; geomRange )
    {
        // TODO transparent context?
        // TODO use bounds from geom
        auto context = cairo.Context(surface);
        geom.draw( context );
        context.identityMatrix();
        context.stroke();
    }
    surface.writeToPNG(plot.name);
}

unittest
{
    auto aes = Aes!(double[],double[], string[])( [1.0],[2.0],["c"] );
    auto gl = geom_line( aes );
    ggplotdPNG( gl );
}
