module ggplotd.ggplotd;

import cconfig = cairo.c.config;
import cpdf = cairo.pdf;
import csvg = cairo.svg;
import cairo = cairo;

import ggplotd.aes;
import ggplotd.colour;
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


    /+
        // Create a sub surface. Makes sure everything is plotted within plot surface
        auto plotSurface = cairo.Surface.createForRectangle(surface, cairo.Rectangle!double(marginBounds
                    .min_x, 0,  // No support for margin at top yet. Would need to know the surface dimensions
                    marginBounds.width, marginBounds.height));
    +/

    // TODO use reduce to get the all encompasing bounds
    AdaptiveBounds bounds;
    typeof(geomRange.front.colour)[] colourIDs;
    //bounds = reduce!((a,b) => a.adapt( b.bounds ))
    //    ( bounds, geomRange );
    foreach( geom; geomRange )
    {
        bounds.adapt( geom.bounds );
        colourIDs ~= geom.colour;
    }

    auto colourMap = colourGradient(colourIDs);

    foreach( geom; geomRange )
    {
        auto context = cairo.Context(surface);
        context.setSourceRGB( colourMap(geom.colour) );
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
            ["c", "d"] );
    auto ge = geomPoint( aes );
    ggplotdPNG( ge, scale() );
}

unittest
{
    auto aes = Aes!(double[], double[], string[] )( 
            [1.0,2.0,1.1,3.0], 
            [3.0,1.5,1.1,1.8], 
            ["a","b","a","b"] );

    auto gl = geomLine( aes );
    ggplotdPNG( gl, scale() );
}

unittest
{
    auto aes = Aes!(double[], double[], string[] )( 
            [1.0,1.05,1.1,0.9,1.0,0.99,1.09,1.091], 
            [3.0,1.5,1.1,1.8], 
            ["a","a","b","b","a","a","a","a"] );

    auto gl = geomHist( aes );
    ggplotdPNG( gl, scale() );
}

