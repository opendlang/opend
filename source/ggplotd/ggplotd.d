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

///
void ggPlotd(GR, SF)(GR geomRange, SF scale, string file = "plotcli.png")
{
    import std.range : front;
    auto width = 470;
    auto height = 470;
    cairo.Surface surface;

    import std.stdio;

    bool pngWrite = false;

    static if (cconfig.CAIRO_HAS_PDF_SURFACE)
    {
        if (file[$ - 3 .. $] == "pdf")
        {
            surface = new cpdf.PDFSurface(file, width, height);
        }
    }
    else
    {
        if (file[$ - 3 .. $] == "pdf")
            assert(0, "PDF support not enabled by cairoD");
    }
    static if (cconfig.CAIRO_HAS_SVG_SURFACE)
    {
        if (file[$ - 3 .. $] == "svg")
        {
            surface = new csvg.SVGSurface(file, width, height);
        }
    }
    else
    {
        if (file[$ - 3 .. $] == "svg")
            assert(0, "SVG support not enabled by cairoD");
    }
    if (file[$ - 3 .. $] == "png")
    {
        surface = new cairo.ImageSurface(cairo.Format.CAIRO_FORMAT_ARGB32, width, height);
        pngWrite = true;
    }

    auto backcontext = cairo.Context(surface);
    backcontext.setSourceRGB(1, 1, 1);
    backcontext.rectangle(0, 0, width, height);
    backcontext.fill();

    // Create a sub surface. Makes sure everything is plotted within plot surface
    auto plotSurface = cairo.Surface.createForRectangle(surface,
        cairo.Rectangle!double(50, 20, // No support for margin at top yet. Would need to know the surface dimensions
        width - 70, height - 70));

    AdaptiveBounds bounds;
    typeof(geomRange.front.colour)[] colourIDs;
    auto xAxisTicks = geomRange.front.xTickLabels;
    auto yAxisTicks = geomRange.front.yTickLabels;

    foreach (geom; geomRange)
    {
        bounds.adapt(geom.bounds);
        colourIDs ~= geom.colour;
        xAxisTicks ~= geom.xTickLabels;
        yAxisTicks ~= geom.xTickLabels;
    }

    auto colourMap = createColourMap(colourIDs);

    foreach (geom; geomRange)
    {
        auto context = cairo.Context(surface);
        context.translate(50, 20);
        //auto context = cairo.Context(surface);
        auto col = colourMap(geom.colour);
        import cairo.cairo : RGBA;
        context.setSourceRGBA(RGBA(col.red, col.green, col.blue, geom.alpha));
        context = scale(context, bounds);
        context = geom.draw(context);
        context.identityMatrix();
        context.stroke();
    }

    // Axis
    import std.algorithm : sort, uniq;
    import std.range : chain;
    import std.array : array;
    import ggplotd.axes;

    auto sortedAxisTicks = xAxisTicks.sort().uniq.array;

    auto aesX = axisAes("x", bounds.min_x, bounds.max_x, bounds.min_y);

    auto aesY = axisAes("y", bounds.min_y, bounds.max_y, bounds.min_x);

    // TODO when we support setting colour outside of colourspace
    // add these geomRanges to the provided ranges 
    // and then draw them all
    auto gR = chain(geomAxis(aesX, bounds.height / 25.0), geomAxis(aesY, bounds.width / 25.0));

    foreach (g; gR)
    {
        auto context = cairo.Context(surface);
        context.translate(50, 20);
        context = scale(context, bounds);
        context.setSourceRGB(0, 0, 0);

        context = g.draw(context);
        context.identityMatrix();
        context.stroke();
    }

    if (pngWrite)
        (cast(cairo.ImageSurface)(surface)).writeToPNG(file);
}

unittest
{
    auto aes = Aes!(double[], "x", double[], "y", string[], "colour")([1.0,
        0.9], [2.0, 1.1], ["c", "d"]);
    auto ge = geomPoint(aes);
    ggPlotd(ge, scale(), "test1.png");
}

unittest
{
    auto aes = Aes!(double[], "x", double[], "y", string[], "colour")([1.0,
        2.0, 1.1, 3.0], [3.0, 1.5, 1.1, 1.8], ["a", "b", "a", "b"]);

    auto gl = geomLine(aes);
    ggPlotd(gl, scale(), "test2.pdf");
}

unittest
{
    auto aes = Aes!(double[], "x", string[], "colour")([1.0, 1.05, 1.1, 0.9,
        1.0, 0.99, 1.09, 1.091], ["a", "a", "b", "b", "a", "a", "a", "a"]);

    auto gl = geomHist(aes);
    ggPlotd(gl, scale(), "test3.svg");
}

unittest
{
    auto aes = Aes!(string[], "x", string[], "y", string[], "colour")(["a",
        "b", "c", "b"], ["a", "b", "b", "a"], ["b", "b", "b", "b"]);

    auto gl = geomLine(aes);
    ggPlotd(gl, scale(), "test4.png");
}

unittest
{
    import std.algorithm : map;
    import std.conv : to;
    import std.range : iota, repeat, chain;
    import std.array : array;

    auto xs = iota(0, 1, 0.2,);
    auto ys = 0.0.repeat(5).chain(1.repeat(5).chain(2.repeat(5))).array;
    auto cols = iota(0, 3, 0.2).array;
    auto aes = Aes!(double[], "x", double[], "y", double[], "colour")(chain(xs,
        xs, xs).array, ys, cols);
    auto ge = geomPoint(aes);
    ggPlotd(ge, scale(), "test5.png");
}

///
struct GGPlotD
{
    Geom[] geomRange;

    alias ScaleType = 
        cairo.Context delegate(cairo.Context context, Bounds bounds);
    ScaleType scaleFunction;

    ///
    void save( string fname )
    {
        if (!initScale)
            scaleFunction = scale(); // This needs to be removed later
        ggPlotd( geomRange, scaleFunction, fname );
    }

    ///
    GGPlotD opBinary(string op, T)(T rhs)
    {
        static if (op == "+")
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
        }
        return this;
    }

    private:
        bool initScale = false;
}

///
unittest
{
    auto aes = Aes!(string[], "x", string[], "y", string[], "colour")(["a",
        "b", "c", "b"], ["a", "b", "b", "a"], ["b", "b", "b", "b"]);
    auto gg = GGPlotD();
    gg + geomLine(aes) + scale();
    gg.save( "test6.png");
}

///
unittest
{
    import std.array : array;
    import std.math : sqrt;
    import std.algorithm : map;
    import std.range : repeat, iota;
    import std.random : uniform;
    // Generate some noisy data with reducing width
    auto f = (double x) { return x/(1+x); };
    auto width = (double x) { return sqrt(0.1/(1+x)); };
    auto xs = iota( 0, 10, 0.1 ).array;

    auto ysfit = xs.map!((x) => f(x)).array;
    auto ysnoise = xs.map!((x) => f(x) + uniform(-width(x),width(x))).array;
    // Adding colour makes it stop working
    auto aes = Aes!(typeof(xs), "x",
        typeof(ysnoise), "y", string[], "colour" )( xs, ysnoise, ("a").repeat(xs.length).array );
    auto gg = GGPlotD() + geomPoint( aes );
    gg + geomLine( Aes!(typeof(xs), "x",
        typeof(ysfit), "y" )( xs, ysfit ) );

    //  
    auto ys2fit = xs.map!((x) => 1-f(x)).array;
    auto ys2noise = xs.map!((x) => 1-f(x) + uniform(-width(x),width(x))).array;


    gg + geomLine( Aes!(typeof(xs), "x", typeof(ys2fit), "y" )( xs,
        ys2fit) ); 
    gg + geomPoint( Aes!(typeof(xs), "x", typeof(ys2noise), "y", string[],
        "colour" )( xs, ys2noise, ("b").repeat(xs.length).array) );

    gg.save( "noise.png" );
}

///
unittest
{
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota;
    import std.random : uniform;
    auto xs = iota(0,25,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto aes = Aes!(typeof(xs), "x")( xs );
    auto gg = GGPlotD() + geomHist( aes );

    auto ys = (0.0).repeat( xs.length ).array;
    auto aesPs = aes.merge( Aes!(double[], "y", double[], "colour" )
        ( ys, ys ) );
    gg + geomPoint( aesPs );

    gg.save( "hist.png" );
}
