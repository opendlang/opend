module ggplotd.ggplotd;

import cconfig = cairo.c.config;
import cpdf = cairo.pdf;
import csvg = cairo.svg;
import cairo = cairo;

import ggplotd.aes;
import ggplotd.axes;
import ggplotd.colour;
import ggplotd.geom;
import ggplotd.bounds;
import ggplotd.scale;
import ggplotd.theme;

version (unittest)
{
    import dunit.toolkit;
}

alias TitleFunction = Title delegate(Title);

// Currently only holds the title. In the future could also be used to store details on location etc.
struct Title
{
    /// The actual title
    string title;
}

///
TitleFunction title( string title )
{
    return delegate(Title t) { t.title = title; return t; };
}

private auto createEmptySurface( string fname, int width, int height,
    RGBA colour )
{
    cairo.Surface surface;

    static if (cconfig.CAIRO_HAS_PDF_SURFACE)
        {
        if (fname[$ - 3 .. $] == "pdf")
            {
            surface = new cpdf.PDFSurface(fname, width, height);
        }
    }
    else
        {
        if (fname[$ - 3 .. $] == "pdf")
            assert(0, "PDF support not enabled by cairoD");
    }
    static if (cconfig.CAIRO_HAS_SVG_SURFACE)
        {
        if (fname[$ - 3 .. $] == "svg")
            {
            surface = new csvg.SVGSurface(fname, width, height);
        }
    }
    else
    {
        if (fname[$ - 3 .. $] == "svg")
            assert(0, "SVG support not enabled by cairoD");
    }
    if (fname[$ - 3 .. $] == "png")
    {
        surface = new cairo.ImageSurface(cairo.Format.CAIRO_FORMAT_ARGB32, width, height);
    }

    auto backcontext = cairo.Context(surface);
    backcontext.setSourceRGBA(colour);
    backcontext.paint;

    return surface;
}

///
auto drawTitle( in Title title, ref cairo.Surface surface,
    in Margins margins, int width, int height )
{
    auto context = cairo.Context(surface);
    context.setFontSize(16.0);
    context.moveTo( width/2, margins.top/2 );
    auto extents = context.textExtents(title.title);

    auto textSize = cairo.Point!double(0.5 * extents.width, 0.5 * extents.height);
    context.relMoveTo(-textSize.x, textSize.y);

    context.showText(title.title);
    return surface;
}

auto drawGeom( Geom geom, ref cairo.Surface surface,
    ColourMap colourMap, ScaleType scaleFunction, in Bounds bounds, 
    in Margins margins, int width, int height )
{
    cairo.Context context;
    if (geom.mask) {
        auto plotSurface = cairo.Surface.createForRectangle(surface,
            cairo.Rectangle!double(margins.left, margins.top,
            width - (margins.left+margins.right), 
            height - (margins.top+margins.bottom)));
        context = cairo.Context(plotSurface);
    } else {
        context = cairo.Context(surface);
        context.translate(margins.left, margins.top);
    }
    import std.conv : to;
    context = scaleFunction(context, bounds,
        width.to!double - (margins.left+margins.right),
        height.to!double - (margins.top+margins.bottom));
    context = geom.draw(context, colourMap);
    return surface;
}

///
struct Margins
{
    size_t left = 50; ///
    size_t right = 20; ///
    size_t bottom = 50; ///
    size_t top = 40; ///
}

///
struct GGPlotD
{
    Geom[] geomRange;

    XAxis xaxis;
    YAxis yaxis;

    Margins margins;

    Title title;
    Theme theme;

    ScaleType scaleFunction;

    ///
    auto drawToSurface( ref cairo.Surface surface, int width, int height )
    {
        if (!initScale)
            scaleFunction = scale(); // This needs to be removed later
        import std.range : empty, front;

        AdaptiveBounds bounds;
        ColourID[] colourIDs;
        Tuple!(double, string)[] xAxisTicks;
        Tuple!(double, string)[] yAxisTicks;

        foreach (geom; geomRange)
        {
            bounds.adapt(geom.bounds);
            colourIDs ~= geom.colours;
            xAxisTicks ~= geom.xTickLabels;
            yAxisTicks ~= geom.yTickLabels;
        }

        auto colourMap = createColourMap(colourIDs);

        // Axis
        import std.algorithm : sort, uniq, min, max;
        import std.range : chain;
        import std.array : array;
        import ggplotd.axes;

        // If ticks are provided then we make sure the bounds include them
        auto sortedTicks = xAxisTicks.sort().uniq.array;
        if (!sortedTicks.empty)
        {
            bounds.min_x = min( bounds.min_x, sortedTicks[0][0] );
            bounds.max_x = max( bounds.max_x, sortedTicks[$-1][0] );
        }
        if (initialized(xaxis))
        {
            bounds.min_x = xaxis.min;
            bounds.max_x = xaxis.max;
        }

        import std.math : isNaN;
        auto offset = bounds.min_y;
        if (!isNaN(xaxis.offset))
            offset = xaxis.offset;
        auto aesX = axisAes("x", bounds.min_x, bounds.max_x, offset,
            sortedTicks );

        sortedTicks = yAxisTicks.sort().uniq.array;
        if (!sortedTicks.empty)
        {
            bounds.min_y = min( bounds.min_y, sortedTicks[0][0] );
            bounds.max_y = max( bounds.max_y, sortedTicks[$-1][0] );
        }
        if (initialized(yaxis))
        {
            bounds.min_y = yaxis.min;
            bounds.max_y = yaxis.max;
        }

        offset = bounds.min_x;
        if (!isNaN(yaxis.offset))
            offset = yaxis.offset;
        auto aesY = axisAes("y", bounds.min_y, bounds.max_y, offset,
            sortedTicks );

        auto gR = chain(geomAxis(aesX, 10.0*bounds.height / height, xaxis.label), geomAxis(aesY, 10.0*bounds.width / width, yaxis.label));

        // Plot axis and geomRange
        foreach (geom; chain(geomRange, gR) )
        {
            surface = geom.drawGeom( surface,
                colourMap, scaleFunction, bounds, 
                margins, width, height );
        }

        // Plot title
        surface = title.drawTitle( surface, margins, width, height );
        return surface;
    }
 

    ///
    void save( string fname, int width = 470, int height = 470 )
    {
        bool pngWrite = false;
        auto surface = createEmptySurface( fname, width, height,
            theme.backgroundColour );

        surface = drawToSurface( surface, width, height );

        if (fname[$ - 3 .. $] == "png")
        {
            pngWrite = true;
        }

        if (pngWrite)
            (cast(cairo.ImageSurface)(surface)).writeToPNG(fname);
    }

    /// Using + to extend the plot for compatibility to ggplot2 in R
    ref GGPlotD opBinary(string op, T)(T rhs) if (op == "+")
    {
        static if (is(ElementType!T==Geom))
        {
            import std.array : array;
            geomRange ~= rhs.array;
        }
        static if (is(T==ScaleType))
        {
            initScale = true;
            scaleFunction = rhs;
        }
        static if (is(T==XAxisFunction))
        {
            xaxis = rhs( xaxis );
        }
        static if (is(T==YAxisFunction))
        {
            yaxis = rhs( yaxis );
        }
        static if (is(T==TitleFunction))
        {
            title = rhs( title );
        }
        static if (is(T==ThemeFunction))
        {
            theme = rhs( theme );
        }
        static if (is(T==Margins))
        {
            margins = rhs;
        }
        return this;
    }

    ///
    ref GGPlotD put(T)(T rhs)
    {
        return this.opBinary!("+", T)(rhs);
    }

private:
    bool initScale = false;
}

unittest
{
    auto gg = GGPlotD()
        .put( yaxisLabel( "My ylabel" ) )
        .put( yaxisRange( 0, 2.0 ) );
    assertEqual( gg.yaxis.max, 2.0 );
    assertEqual( gg.yaxis.label, "My ylabel" );

    gg = GGPlotD(); 
    gg.put( yaxisLabel( "My ylabel" ) )
        .put( yaxisRange( 0, 2.0 ) );
    assertEqual( gg.yaxis.max, 2.0 );
    assertEqual( gg.yaxis.label, "My ylabel" );
}


///
unittest
{
    auto aes = Aes!(string[], "x", string[], "y", string[], "colour")(["a",
        "b", "c", "b"], ["x", "y", "y", "x"], ["b", "b", "b", "b"]);
    auto gg = GGPlotD();
    gg + geomLine(aes) + scale();
    gg.save( "test6.png");
}

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/noise.png
    import std.array : array;
    import std.math : sqrt;
    import std.algorithm : map;
    import std.range : repeat, iota;
    import std.random : uniform;
    // Generate some noisy data with reducing width
    auto f = (double x) { return x/(1+x); };
    auto width = (double x) { return sqrt(0.1/(1+x)); };
    auto xs = iota( 0, 10, 0.1 ).array;

    auto ysfit = xs.map!((x) => f(x));
    auto ysnoise = xs.map!((x) => f(x) + uniform(-width(x),width(x))).array;

    auto aes = Aes!(typeof(xs), "x",
        typeof(ysnoise), "y", string[], "colour" )( xs, ysnoise, ("a").repeat(xs.length).array );
    auto gg = GGPlotD().put( geomPoint( aes ) );
    gg.put( geomLine( Aes!(typeof(xs), "x",
        typeof(ysfit), "y" )( xs, ysfit ) ) );

    //  
    auto ys2fit = xs.map!((x) => 1-f(x));
    auto ys2noise = xs.map!((x) => 1-f(x) + uniform(-width(x),width(x))).array;

    gg.put( geomLine( Aes!(typeof(xs), "x", typeof(ys2fit), "y" )( xs,
        ys2fit) ) )
        .put(
            geomPoint( Aes!(typeof(xs), "x", typeof(ys2noise), "y", string[],
        "colour" )( xs, ys2noise, ("b").repeat(xs.length).array) ) );

    gg.save( "noise.png" );
}

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/hist.png
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota;
    import std.random : uniform;
    auto xs = iota(0,25,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto aes = Aes!(typeof(xs), "x")( xs );
    auto gg = GGPlotD().put( geomHist( aes ) );

    auto ys = (0.0).repeat( xs.length ).array;
    auto aesPs = aes.mergeRange( Aes!(double[], "y", double[], "colour" )
        ( ys, ys ) );
    gg.put( geomPoint( aesPs ) );

    gg.save( "hist.png" );
}

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/filled_hist.svg
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain;
    import std.random : uniform;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25));
    auto aes = Aes!(typeof(xs), "x", typeof(cols), "colour", 
        double[], "fill" )( 
            xs, cols, 0.45.repeat(xs.length).array);
    auto gg = GGPlotD().put( geomHist( aes ) );
    gg.save( "filled_hist.svg" );
}

/// Boxplot example
unittest
{
    /// http://blackedder.github.io/ggplotd/images/boxplot.svg
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain;
    import std.random : uniform;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25)).array;
    auto aes = Aes!(typeof(xs), "x", typeof(cols), "colour", 
        double[], "fill", typeof(cols), "label" )( 
            xs, cols, 0.45.repeat(xs.length).array, cols);
    auto gg = GGPlotD().put( geomBox( aes ) );
    gg.save( "boxplot.svg" );
}

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/hist3D.svg
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota;
    import std.random : uniform;

    auto xs = iota(0,25,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto ys = iota(0,25,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto aes = Aes!(typeof(xs), "x", typeof(ys), "y")( xs, ys);
    auto gg = GGPlotD().put( geomHist3D( aes ) );

    gg.save( "hist3D.svg" );
}



/// Changing axes details
unittest
{
    /// http://blackedder.github.io/ggplotd/images/axes.svg
    import std.array : array;
    import std.math : sqrt;
    import std.algorithm : map;
    import std.range : iota;
    // Generate some noisy data with reducing width
    auto f = (double x) { return x/(1+x); };
    auto width = (double x) { return sqrt(0.1/(1+x)); };
    auto xs = iota( 0, 10, 0.1 ).array;

    auto ysfit = xs.map!((x) => f(x)).array;

    auto gg = GGPlotD().put( geomLine( Aes!(typeof(xs), "x",
        typeof(ysfit), "y" )( xs, ysfit ) ) );

    // Setting range and label for xaxis
    gg.put( xaxisRange( 0, 8 ) ).put( xaxisLabel( "My xlabel" ) );
    assertEqual( gg.xaxis.min, 0 );
    // Setting range and label for yaxis
    gg.put( yaxisRange( 0, 2.0 ) ).put( yaxisLabel( "My ylabel" ) );
    assertEqual( gg.yaxis.max, 2.0 );
    assertEqual( gg.yaxis.label, "My ylabel" );

    // change offset
    gg.put( xaxisOffset( 0.25 ) ).put( yaxisOffset( 0.5 ) );

    // Change Margins
    gg.put( Margins( 60, 60, 40, 30 ) );

    // Set a title
    gg.put( title( "And now for something completely different" ) );
    assertEqual( gg.title.title, "And now for something completely different" );

    // Saving on a 500x300 pixel surface
    gg.save( "axes.svg", 500, 300 );
}

/// Polygon
unittest
{
    /// http://blackedder.github.io/ggplotd/images/polygon.png
    auto gg = GGPlotD().put( geomPolygon( 
        Aes!(
            double[], "x",
            double[], "y",
            double[], "colour" )(
            [1,0,0], [ 1, 1, 0 ], [1,0.1,0] ) ) );
    gg.save( "polygon.png" );
}

/// Setting background colour
unittest
{
    /// http://blackedder.github.io/ggplotd/images/background.svg
    import ggplotd.theme;
    auto gg = GGPlotD().put( background( RGBA(0.7,0.7,0.7,1) ) );
    gg.put( geomPoint( 
        Aes!(
            double[], "x",
            double[], "y",
            double[], "colour" )(
            [1,0,0], [ 1, 1, 0 ], [1,0.1,0] ) ) );
    gg.save( "background.svg" );
}
