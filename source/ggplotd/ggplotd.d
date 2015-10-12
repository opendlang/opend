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
    auto width = 470;
    auto height = 470;
    auto surface = new cairo.ImageSurface(
            cairo.Format.CAIRO_FORMAT_ARGB32,
            width, height);
    auto backcontext = cairo.Context(surface);
    backcontext.setSourceRGB( 1,1,1 );
    backcontext.rectangle( 0, 0, width, height );
    backcontext.fill();

    // Create a sub surface. Makes sure everything is plotted within plot surface
    auto plotSurface = cairo.Surface.createForRectangle(surface, 
            cairo.Rectangle!double(50, 20,  // No support for margin at top yet. Would need to know the surface dimensions
                width-70, height-70));

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
        context.translate( 50, 20 );
        //auto context = cairo.Context(surface);
        context.setSourceRGB( colourMap(geom.colour) );
        context = scale( context, bounds );
        context = geom.draw( context );
        context.identityMatrix();
        context.stroke();
    }

    // Axis
    import std.array : array;
    import std.range : repeat, take, walkLength, chain;
    import ggplotd.axes;
    auto xaxisTicks = Axis(bounds.min_x, bounds.max_x)
        .adjustTickWidth(5)
        .axisTicks;

    auto aesX = Aes!(typeof(xaxisTicks), double[], double[])(
            xaxisTicks, 
            bounds.min_y
                .repeat()
                .take(xaxisTicks.walkLength)
                .array,
            0.0.repeat().take(xaxisTicks.walkLength).array);

    auto yaxisTicks = Axis(bounds.min_y, bounds.max_y)
        .adjustTickWidth(5)
        .axisTicks;

    auto aesY = Aes!(double[], typeof(yaxisTicks), double[])(
            bounds.min_x.repeat().take(yaxisTicks.walkLength).array,
            yaxisTicks, 
            0.0.repeat().take(yaxisTicks.walkLength).array);

    // TODO when we support setting colour outside of colourspace
    // add these geomRanges to the provided ranges 
    // and then draw them all
    auto gR = chain(geomAxis(aesX, bounds.height/25.0),
            geomAxis( aesY, bounds.width/25.0 ) );

    foreach( g; gR )
    {
        auto context = cairo.Context( surface );
        context.translate( 50, 20 );
        context = scale( context, bounds );
        context.setSourceRGB( 0,0,0 );

        context = g.draw( context );
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
