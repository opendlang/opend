module ggplotd.ggplotd;

import cconfig = cairo.c.config;
import cpdf = cairo.pdf;
import csvg = cairo.svg;
import cairo = cairo;

import ggplotd.colour;
import ggplotd.geom : Geom;
import ggplotd.bounds : Bounds;
import ggplotd.colourspace : RGBA;

version (unittest)
{
    import dunit.toolkit;
}

/// delegate that takes a Title struct and returns a changed Title struct
alias TitleFunction = Title delegate(Title);

/// Currently only holds the title. In the future could also be used to store details on location etc.
struct Title
{
    /// The actual title
    string title;
}

/** 
Draw the title

Examples:
--------------------
GGPlotD().put( title( "My title" ) );
--------------------
*/
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

    import ggplotd.colourspace : toCairoRGBA;
    auto backcontext = cairo.Context(surface);
    backcontext.setSourceRGBA(colour.toCairoRGBA);
    backcontext.paint;

    return surface;
}

///
private auto drawTitle( in Title title, ref cairo.Surface surface,
    in Margins margins, int width )
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

import ggplotd.scale : ScaleType;
private auto drawGeom( in Geom geom, ref cairo.Surface surface,
    in ColourMap colourMap, in ScaleType scaleFunction, in Bounds bounds, 
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

/// Specify margins in number of pixels
struct Margins
{
    /// left margin
    size_t left = 50;
    /// right margin
    size_t right = 20; 
    /// bottom margin
    size_t bottom = 50; 
    /// top margin
    size_t top = 40; 
}

/// GGPlotD contains the needed information to create a plot
struct GGPlotD
{
    import ggplotd.bounds : height, width;
    import ggplotd.colour : ColourGradientFunction;
    import ggplotd.scale : ScaleType;

    /**
    Draw the plot to a cairoD cairo surface.

    Params:
        surface = Surface object of type cairo.Surface from cairoD library, on top of which this plot is drawn.
        width = Width of the given surface.
        height = Height of the given surface.

    Returns:
        Resulting surface of the same type as input surface, with this plot drawn on top of it.
    */
    ref cairo.Surface drawToSurface( ref cairo.Surface surface, int width, int height ) const
    {
        import std.range : empty, front;
        import std.typecons : Tuple;

        import ggplotd.bounds : AdaptiveBounds;
        import ggplotd.colour : ColourID, createColourMap;

        AdaptiveBounds bounds;
        ColourID[] colourIDs;
        Tuple!(double, string)[] xAxisTicks;
        Tuple!(double, string)[] yAxisTicks;

        foreach (geom; geomRange.data)
        {
            bounds.adapt(geom.bounds);
            colourIDs ~= geom.colours;
            xAxisTicks ~= geom.xTickLabels;
            yAxisTicks ~= geom.yTickLabels;
        }

        auto colourMap = createColourMap( colourIDs, 
                this.colourGradient() );

        // Axis
        import std.algorithm : sort, uniq, min, max;
        import std.range : chain;
        import std.array : array;

        import ggplotd.axes : initialized, axisAes;

        // TODO move this out of here and add some tests
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

        // This needs to happen before the offset of x axis is set
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

        import std.math : isNaN;
        auto offset = bounds.min_y;
        if (!isNaN(xaxis.offset))
            offset = xaxis.offset;
        auto aesX = axisAes("x", bounds.min_x, bounds.max_x, offset,
            sortedTicks );

        offset = bounds.min_x;
        if (!isNaN(yaxis.offset))
            offset = yaxis.offset;
        auto aesY = axisAes("y", bounds.min_y, bounds.max_y, offset,
            sortedTicks );

        import ggplotd.geom : geomAxis;

        auto gR = chain(
                geomAxis(aesX, 10.0*bounds.height / height, xaxis.label), 
                geomAxis(aesY, 10.0*bounds.width / width, yaxis.label)
            );

        // Plot axis and geomRange
        foreach (geom; chain(geomRange.data, gR) )
        {
            surface = geom.drawGeom( surface,
                colourMap, scale(), bounds, 
                margins, width, height );
        }

        // Plot title
        surface = title.drawTitle( surface, margins, width );

        if (legend.type == "continuous") {
            import ggplotd.legend : drawContinuousLegend; 
            auto legendSurface = cairo.Surface.createForRectangle(surface,
                cairo.Rectangle!double(width - 100, //margins.right, 
                    0.5*height, 100, 100 ));//margins.right, margins.right));
            legendSurface = drawContinuousLegend( legendSurface, 
                100, 100, 
                colourIDs, this.colourGradient );
        }

        return surface;
    }
 
    version(ggplotdGTK) 
    {
        import gtkdSurface = cairo.Surface; // cairo surface module in GtkD package.

        /**
        Draw the plot to a GtkD cairo surface.

        Params:
            surface = Surface object of type cairo.Surface from GtkD library, on top of which this plot is drawn.
            width = Width of the given surface.
            height = Height of the given surface.

        Returns:
            Resulting surface of the same type as input surface, with this plot drawn on top of it.
        */
        auto drawToSurface( ref gtkdSurface.Surface surface, int width, int height ) const
        {
            import gtkc = gtkc.cairotypes;
            import cairod = cairo.c.cairo;

            alias gtkd_surface_t = gtkc.cairo_surface_t;
            alias cairod_surface_t = cairod.cairo_surface_t;

            cairo.Surface cairodSurface = new cairo.Surface(cast(cairod_surface_t*)surface.getSurfaceStruct());
            drawToSurface(cairodSurface, width, height);

            return surface;
        }
    }

    /// save the plot to a file
    void save( string fname, int width = 470, int height = 470 ) const
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
        import ggplotd.axes : XAxisFunction, YAxisFunction;
        import ggplotd.colour : ColourGradientFunction;
        static if (is(ElementType!T==Geom))
        {
            geomRange.put( rhs );
        }
        static if (is(T==ScaleType))
        {
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
        static if (is(T==ColourGradientFunction)) {
            colourGradientFunction = rhs;
        }
        static if (is(T==Legend)) {
            legend = rhs;
        }
        return this;
    }

    /// put/add to the plot
    ref GGPlotD put(T)(T rhs)
    {
        return this.opBinary!("+", T)(rhs);
    }

    /// Active scale
    ScaleType scale() const
    {
        import ggplotd.scale : defaultScale = scale;
        // Return active function or the default
        if (!scaleFunction.isNull)
            return scaleFunction;
        else 
            return defaultScale();
    }

    /// Active colourGradient
    ColourGradientFunction colourGradient() const
    {
        import ggplotd.colour : defaultColourGradient = colourGradient;
        import ggplotd.colourspace : HCY;
        if (!colourGradientFunction.isNull)
            return colourGradientFunction;
        else
            return defaultColourGradient!HCY("");
    }

private:
    import std.range : Appender;
    import ggplotd.theme : Theme, ThemeFunction;
    import ggplotd.legend : Legend;
    Appender!(Geom[]) geomRange;

    import ggplotd.axes : XAxis, YAxis;
    XAxis xaxis;
    YAxis yaxis;

    Margins margins;

    Title title;
    Theme theme;

    import std.typecons : Nullable;
    Nullable!(ScaleType) scaleFunction;
    Nullable!(ColourGradientFunction) colourGradientFunction;

    Legend legend;
}

unittest
{
    import ggplotd.geom;
    import ggplotd.aes;

    const win_width = 1024;
    const win_height = 1024;

    const radius = 400.;

    auto line_aes11 = Aes!(double[], "x", double[], "y")( [ 0, radius*0.45 ], [ 0, radius*0.45]);
    auto line_aes22 = Aes!(double[], "x", double[], "y")( [ 300, radius*0.45 ], [ 210, radius*0.45]);

    auto gg = GGPlotD();
    gg.put( geomLine(line_aes11) );
    gg.put( geomLine(line_aes22) );

    import ggplotd.theme : Theme, ThemeFunction;
    Theme theme;

    auto surface = createEmptySurface( "test.png", win_width, win_height,
        theme.backgroundColour );

    auto dim = gg.geomRange.data.length;
    surface = gg.drawToSurface( surface, win_width, win_height );
    assertEqual( dim, gg.geomRange.data.length );
    surface = gg.drawToSurface( surface, win_width, win_height );
    assertEqual( dim, gg.geomRange.data.length );
    surface = gg.drawToSurface( surface, win_width, win_height );
    assertEqual( dim, gg.geomRange.data.length );
}

version(ggplotdGTK) 
{
    unittest 
    {
        // Draw same plot on cairod.ImageSurface, and on gtkd.cairo.ImageSurface,
        // and prove resulting images are the same.

        import ggplotd.geom;
        import ggplotd.aes;

        import gtkSurface = cairo.Surface;
        import gtkImageSurface = cairo.ImageSurface;
        import gtkCairoTypes = gtkc.cairotypes;

        const win_width = 1024;
        const win_height = 1024;

        const radius = 400.;

        auto line_aes11 = Aes!(double[], "x", double[], "y")( [ 0, radius*0.45 ], [ 0, radius*0.45]);
        auto line_aes22 = Aes!(double[], "x", double[], "y")( [ 300, radius*0.45 ], [ 210, radius*0.45]);

        auto gg = GGPlotD();
        gg.put( geomLine(line_aes11) );
        gg.put( geomLine(line_aes22) );

        cairo.Surface cairodSurface = new cairo.ImageSurface(cairo.Format.CAIRO_FORMAT_RGB24, win_width, win_height);
        gtkSurface.Surface gtkdSurface = gtkImageSurface.ImageSurface.create(gtkCairoTypes.cairo_format_t.RGB24, win_width, win_height);

        auto cairodImageSurface = cast(cairo.ImageSurface)cairodSurface;
        auto gtkdImageSurface = cast(gtkImageSurface.ImageSurface)gtkdSurface;

        gg.drawToSurface(cairodSurface, win_width, win_height);
        gg.drawToSurface(gtkdSurface, win_width, win_height);

        auto byteSize = win_width*win_height*4;

        assertEqual(cairodImageSurface.getData()[0..byteSize], gtkdImageSurface.getData()[0..byteSize]);
    }
}

unittest
{
    import ggplotd.axes : yaxisLabel, yaxisRange;
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
    import ggplotd.aes : Aes;
    import ggplotd.geom : geomLine;
    import ggplotd.scale : scale;
    auto aes = Aes!(string[], "x", string[], "y", string[], "colour")(["a",
        "b", "c", "b"], ["x", "y", "y", "x"], ["b", "b", "b", "b"]);
    auto gg = GGPlotD();
    gg + geomLine(aes) + scale();
    gg.save( "test6.png");
}

///
unittest
{
    // http://blackedder.github.io/ggplotd/images/noise.png
    import std.array : array;
    import std.math : sqrt;
    import std.algorithm : map;
    import std.range : repeat, iota;
    import std.random : uniform;

    import ggplotd.aes : Aes;
    import ggplotd.geom : geomLine, geomPoint;
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
    // http://blackedder.github.io/ggplotd/images/hist.png
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota;
    import std.random : uniform;

    import ggplotd.aes : Aes;
    import ggplotd.geom : geomHist, geomPoint;
    import ggplotd.range : mergeRange;

    auto xs = iota(0,25,1).map!((x) => uniform(0.0,5)+uniform(0.0,5))
        .array;
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
    // http://blackedder.github.io/ggplotd/images/filled_hist.svg
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain;
    import std.random : uniform;

    import ggplotd.aes : Aes;
    import ggplotd.geom : geomHist;

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
    // http://blackedder.github.io/ggplotd/images/boxplot.svg
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain;
    import std.random : uniform;

    import ggplotd.aes : Aes;
    import ggplotd.geom : geomBox;

    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25)).array;
    auto aes = Aes!(typeof(xs), "x", typeof(cols), "colour", 
        double[], "fill", typeof(cols), "label" )( 
            xs, cols, 0.45.repeat(xs.length).array, cols);
    auto gg = GGPlotD().put( geomBox( aes ) );
    gg.save( "boxplot.svg" );
}

/// Changing axes details
unittest
{
    // http://blackedder.github.io/ggplotd/images/axes.svg
    import std.array : array;
    import std.math : sqrt;
    import std.algorithm : map;
    import std.range : iota;

    import ggplotd.aes : Aes;
    import ggplotd.axes : xaxisLabel, yaxisLabel, xaxisOffset, yaxisOffset, xaxisRange, yaxisRange;
    import ggplotd.geom : geomLine;

    // Generate some noisy data with reducing width
    auto f = (double x) { return x/(1+x); };
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

    // Change Margins gg.put( Margins( 60, 60, 40, 30 ) );

    // Set a title
    gg.put( title( "And now for something completely different" ) );
    assertEqual( gg.title.title, "And now for something completely different" );

    // Saving on a 500x300 pixel surface
    gg.save( "axes.svg", 500, 300 );
}

/// Polygon
unittest
{
    import ggplotd.aes : Aes;
    import ggplotd.geom : geomPolygon;

    // http://blackedder.github.io/ggplotd/images/polygon.png
    auto gg = GGPlotD().put( geomPolygon( 
        Aes!(
            double[], "x",
            double[], "y",
            double[], "colour" )(
            [1,0,0.0], [ 1, 1, 0.0 ], [1,0.1,0] ) ) );
    gg.save( "polygon.png" );
}

/// Setting background colour
unittest
{
    /// http://blackedder.github.io/ggplotd/images/background.svg
    import ggplotd.aes : Aes;
    import ggplotd.theme : background;
    import ggplotd.geom : geomPoint;

    auto gg = GGPlotD().put( background( RGBA(0.7,0.7,0.7,1) ) );
    gg.put( geomPoint( 
        Aes!(
            double[], "x",
            double[], "y",
            double[], "colour" )(
            [1.0,0,0], [ 1.0, 1, 0 ], [1,0.1,0] ) ) );
    gg.save( "background.svg" );
}

/// Other data type
unittest
{
    /// http://blackedder.github.io/ggplotd/images/data.png
    import std.array : array;
    import std.math : sqrt;
    import std.algorithm : map;
    import std.range : repeat, iota;
    import std.random : uniform;

    import ggplotd.geom : geomPoint;

    struct Point { double x; double y; }
    // Generate some noisy data with reducing width
    auto f = (double x) { return x/(1+x); };
    auto width = (double x) { return sqrt(0.1/(1+x)); };
    immutable xs = iota( 0, 10, 0.1 ).array;

    auto points = xs.map!((x) => Point(x,
        f(x) + uniform(-width(x),width(x))));

    auto gg = GGPlotD().put( geomPoint( points ) );

    gg.save( "data.png" );
}


///
struct Facets
{
    ///
    void put(GGPlotD facet)
    {
        ggs.put( facet );
    }

    ///
    auto drawToSurface( ref cairo.Surface surface, int dimX, int dimY, 
            int width, int height ) const
    {
        import std.conv : to;
        import std.math : floor;
        import std.range : save, empty, front, popFront;
        import cairo.cairo : Rectangle;
        int w = floor( width.to!double/dimX ).to!int;
        int h = floor( height.to!double/dimY ).to!int;

        auto gs = ggs.data.save;
        foreach( i; 0..dimX )
        {
            foreach( j; 0..dimY )
            {
                if (!gs.empty) 
                {
                    auto rect = Rectangle!double( w*i, h*j, w, h );
                    auto subS = cairo.Surface.createForRectangle( surface, rect );
                    gs.front.drawToSurface( subS, w, h ),
                    gs.popFront;
                }
            }
        }

        return surface;
    }

    ///
    auto drawToSurface( ref cairo.Surface surface,
            int width, int height ) const
    {
        import std.conv : to;
        // Calculate dimX/dimY from width/height
        auto grid = gridLayout( ggs.data.length, width.to!double/height );
        return drawToSurface( surface, grid[0], grid[1], width, height );
    }
 
 
    ///
    void save( string fname, int dimX, int dimY, int width = 470, int height = 470 ) const
    {
        bool pngWrite = false;
        auto surface = createEmptySurface( fname, width, height,
            RGBA(1,1,1,1) );

        surface = drawToSurface( surface, dimX, dimY, width, height );

        if (fname[$ - 3 .. $] == "png")
        {
            pngWrite = true;
        }

        if (pngWrite)
            (cast(cairo.ImageSurface)(surface)).writeToPNG(fname);
    }

    ///
    void save( string fname, int width = 470, int height = 470 ) const
    {
        import std.conv : to;
        // Calculate dimX/dimY from width/height
        auto grid = gridLayout( ggs.data.length, width.to!double/height );
        save( fname, grid[0], grid[1], width, height );
    }

    import std.range : Appender;

    Appender!(GGPlotD[]) ggs;
 }

auto gridLayout( size_t length, double ratio )
{
    import std.conv : to;
    import std.math : ceil, sqrt;
    import std.typecons : Tuple;
    auto h = ceil( sqrt(length/ratio) );
    auto w = ceil(length/h);
    return Tuple!(int, int)( w.to!int, h.to!int );
}

unittest
{
    import std.typecons : Tuple;
    assertEqual(gridLayout(4, 1), Tuple!(int, int)(2, 2));
    assertEqual(gridLayout(2, 1), Tuple!(int, int)(1, 2));
    assertEqual(gridLayout(3, 1), Tuple!(int, int)(2, 2));
    assertEqual(gridLayout(2, 2), Tuple!(int, int)(2, 1));
}

///
unittest
{
    // Drawing different shapes
    import ggplotd.aes : Aes, Pixel;
    import ggplotd.axes : xaxisRange, yaxisRange;
    import ggplotd.geom : geomDiamond, geomRectangle;

    auto gg = GGPlotD();

    auto aes1 = Aes!(double[], "x", double[], "y", double[], "width",
        double[], "height")( [1.0], [-1.0], [3.0], [5.0] );
    gg.put( geomDiamond( aes1 ) );
    gg.put( geomRectangle( aes1 ) );
    gg.put( xaxisRange( -5, 11.0 ) );
    gg.put( yaxisRange( -9, 9.0 ) );


    auto aes2 = Aes!(double[], "x", double[], "y", Pixel[], "width",
        Pixel[], "height")( [8.0], [5.0], [Pixel(10)], [Pixel(20)] );
    gg.put( geomDiamond( aes2 ) );
    gg.put( geomRectangle( aes2 ) );

    auto aes3 = Aes!(double[], "x", double[], "y", Pixel[], "width",
        Pixel[], "height")( [6.0], [-5.0], [Pixel(25)], [Pixel(25)] );
    gg.put( geomDiamond( aes3 ) );
    gg.put( geomRectangle( aes3 ) );
 
    gg.save( "shapes1.png", 300, 300 );
}

///
unittest
{
    // Drawing different shapes
    import ggplotd.aes : Aes, Pixel;
    import ggplotd.axes : xaxisRange, yaxisRange;

    import ggplotd.geom : geomEllipse, geomTriangle;

    auto gg = GGPlotD();

    auto aes1 = Aes!(double[], "x", double[], "y", double[], "width",
        double[], "height")( [1.0], [-1.0], [3.0], [5.0] );
    gg.put( geomEllipse( aes1 ) );
    gg.put( geomTriangle( aes1 ) );
    gg.put( xaxisRange( -5, 11.0 ) );
    gg.put( yaxisRange( -9, 9.0 ) );


    auto aes2 = Aes!(double[], "x", double[], "y", Pixel[], "width",
        Pixel[], "height")( [8.0], [5.0], [Pixel(10)], [Pixel(20)] );
    gg.put( geomEllipse( aes2 ) );
    gg.put( geomTriangle( aes2 ) );

    auto aes3 = Aes!(double[], "x", double[], "y", Pixel[], "width",
        Pixel[], "height")( [6.0], [-5.0], [Pixel(25)], [Pixel(25)] );
    gg.put( geomEllipse( aes3 ) );
    gg.put( geomTriangle( aes3 ) );
 
    gg.save( "shapes2.png", 300, 300 );
}
