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

void GGplotD(GR, SF)( GR geomRange, SF scale, 
       string file = "plotcli.png" )
{
    import std.algorithm : reduce;
    auto width = 470;
    auto height = 470;
    cairo.Surface surface;

    import std.stdio;
    bool pngWrite = false;

    static if (cconfig.CAIRO_HAS_PDF_SURFACE)
    {
        if (file[$-3..$]=="pdf")
        {
            surface = new cpdf.PDFSurface(file, 
                    width, height);
        }
    } else {
        if (file[$-3..$]=="pdf")
            assert( 0, "PDF support not enabled by cairoD" );
    }
    static if (cconfig.CAIRO_HAS_SVG_SURFACE)
    {
        if (file[$-3..$] == "svg")
        {
            surface = new csvg.SVGSurface(file, 
                    width, height);
        }
    } else {
        if (file[$-3..$]=="svg")
            assert( 0, "SVG support not enabled by cairoD" );
    }
    if (file[$-3..$] == "png")
    {
        surface = new cairo.ImageSurface(
                cairo.Format.CAIRO_FORMAT_ARGB32,
                width, height);
        pngWrite = true;
    }


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
    auto xAxisTicks = geomRange.front.xTickLabels;
    auto yAxisTicks = geomRange.front.yTickLabels;
    //bounds = reduce!((a,b) => a.adapt( b.bounds ))
    //    ( bounds, geomRange );
    foreach( geom; geomRange )
    {
        bounds.adapt( geom.bounds );
        colourIDs ~= geom.colour;
        xAxisTicks ~= geom.xTickLabels;
        yAxisTicks ~= geom.xTickLabels;
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
    import std.algorithm : sort, uniq, map;
    import std.range : chain, walkLength, popFront;
    import std.array : array;
    import ggplotd.axes;
    double[] xsticks;
    auto sortedAxisTicks = xAxisTicks.sort().uniq;
    if (sortedAxisTicks.walkLength > 0)
        xsticks = [bounds.min_x] ~
            sortedAxisTicks.map!((t) => t[0]).array ~
            [bounds.max_x];
    else 
        xsticks = Axis(bounds.min_x, bounds.max_x)
            .adjustTickWidth(5)
            .axisTicks.array;

    // Make sure first two positions are not the same;
    if (xsticks[1] == xsticks[0])
        xsticks.popFront;

    auto aesX = axisAes( "x", bounds.min_x, bounds.max_x,
            bounds.min_y, sortedAxisTicks.array );

    auto aesY = axisAes( "y", bounds.min_y, bounds.max_y,
            bounds.min_x, sortedAxisTicks.array );

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

    
    if (pngWrite)
        (cast(cairo.ImageSurface)(surface)).writeToPNG(file);
}

unittest
{
    auto aes = Aes!(double[],"x", double[], "y", string[], "colour")( 
            [1.0,0.9],[2.0,1.1],
            ["c", "d"] );
    auto ge = geomPoint( aes );
    GGplotD( ge, scale(), "test1.png" );
}

unittest
{
    auto aes = Aes!(double[], "x", double[], "y", 
            string[], "colour" )( 
            [1.0,2.0,1.1,3.0], 
            [3.0,1.5,1.1,1.8], 
            ["a","b","a","b"] );

    auto gl = geomLine( aes );
    GGplotD( gl, scale(), "test2.pdf"  );
}

unittest
{
    auto aes = Aes!(double[], "x", string[], "colour" )( 
            [1.0,1.05,1.1,0.9,1.0,0.99,1.09,1.091], 
            ["a","a","b","b","a","a","a","a"] );

    auto gl = geomHist( aes );
    GGplotD( gl, scale(), "test3.svg" );
}

unittest
{
    auto aes = Aes!(string[], "x", string[], "y", 
            string[], "colour" )( 
            ["a","b","c","b"], 
            ["a","b","b","a"], 
            ["b","b","b","b"] );

    auto gl = geomLine( aes );
    GGplotD( gl, scale(), "test4.png"  );
}


