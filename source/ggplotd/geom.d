module ggplotd.geom;

import std.range : front, popFront, empty;

import cairo = cairo.cairo;

import ggplotd.bounds;
import ggplotd.aes;
import ggplotd.colour : ColourID, ColourMap;

version (unittest)
{
    import dunit.toolkit;
}

version (assert)
{
    import std.stdio : writeln;
}

/// Hold the data needed to draw to a plot context
struct Geom
{
    /// Construct from a tuple
    this(T)( in T tup ) //if (is(T==Tuple))
    {
        mask = tup.mask;
    }

    alias drawFunction = cairo.Context delegate(cairo.Context context, 
        ColourMap colourMap);

    /// Function to draw to a cairo context
    drawFunction draw; 

    /// Colours
    ColourID[] colours; 

    /// Plot Bounds
    AdaptiveBounds bounds;

    /// Whether to mask/prevent drawing outside plotting area
    bool mask = true; 

    import std.typecons : Tuple;

    /// Labels for xaxis ticks
    Tuple!(double, string)[] xTickLabels; 
    /// Labels for yaxis ticks
    Tuple!(double, string)[] yTickLabels;
}

import ggplotd.colourspace : RGBA;
private auto fillAndStroke( cairo.Context context, in RGBA colour, 
    in double fill, in double alpha )
{
    import ggplotd.colourspace : toCairoRGBA;
    context.save;

    context.identityMatrix();
    if (fill>0)
        {
        context.setSourceRGBA(
        RGBA(colour.r, colour.g, colour.b, fill).toCairoRGBA
        );
        context.fillPreserve();
    }
    context.setSourceRGBA(
        RGBA(colour.r, colour.g, colour.b, alpha).toCairoRGBA
    );
    context.stroke();
    context.restore;
    return context;
}

/+
TODO: All basic shapes, such as rectangle, ellipse, triangle and diamond share a lot of code. It should be possible to factor out the unique bit (drawing the shape), but till now that always leads to segmentation faults (either problem in the cairo bindings, or bug in compiler). Would be worth retrying this at some point with newer compiler (>2.70.0). Currently have a shapes_split branch. Could try that with new compiler. If no segfault, then problem is fixed and we can do those changes for all the shapes.
+/

/**
Draw rectangle centered at given x,y location

Aside from x and y also width and height are required.
If the type of width is of type Pixel (see aes.d) then dimensions are assumed to be in Pixel (not user coordinates).
*/
auto geomRectangle(AES)(AES aes)
{
    import std.algorithm : map;
    auto xsMap = aes.map!("a.x");
    auto ysMap = aes.map!("a.y");
    alias CoordX = typeof(NumericLabel!(typeof(xsMap))(xsMap));
    alias CoordY = typeof(NumericLabel!(typeof(ysMap))(ysMap));
    auto xsCoords = CoordX(xsMap);
    auto ysCoords = CoordY(ysMap);
    alias CoordType = typeof(DefaultValues
        .mergeRange(aes)
        .mergeRange( Aes!(CoordX, "x", CoordY, "y")
            (CoordX(xsMap), CoordY(ysMap))));

    struct GeomRange(T)
    {
        this(T aes)
        {
            _aes = DefaultValues
                .mergeRange(aes)
                .mergeRange( Aes!(CoordX, "x", CoordY, "y")(
                    xsCoords, ysCoords));
        }

        @property auto front()
        {
            immutable tup = _aes.front;
            immutable f = delegate(cairo.Context context, ColourMap colourMap ) 
            {
                import std.math : isFinite;
                if (!isFinite(tup.x[0]) || !isFinite(tup.y[0]))
                    return context;
                context.save();
                context.translate( tup.x[0], tup.y[0] );
                static if (is(typeof(tup.width)==immutable(Pixel)))
                    auto devP = context.deviceToUserDistance(cairo.Point!double( tup.width, tup.height )); //tup.width.to!double, tup.width.to!double ));
                context.rotate(tup.angle);
                static if (is(typeof(tup.width)==immutable(Pixel)))
                {
                    context.scale( devP.x, devP.y );
                } else {
                    context.scale( tup.width, tup.height );
                }
                context.moveTo( -0.5, -0.5 );
                context.lineTo( -0.5,  0.5 );
                context.lineTo(  0.5,  0.5 );
                context.lineTo(  0.5, -0.5 );
                context.closePath;


                auto col = colourMap(ColourID(tup.colour));
                context.restore();
                context.fillAndStroke( col, tup.fill, tup.alpha );
                return context;
            };

            AdaptiveBounds bounds;
            bounds.adapt(Point(tup.x[0], tup.y[0]));

            auto geom = Geom( tup );
            if (!xsCoords.numeric)
                geom.xTickLabels ~= tup[0];
            if (!ysCoords.numeric)
                geom.yTickLabels ~= tup[1];
            geom.draw = f;
            geom.colours ~= ColourID(tup.colour);
            geom.bounds = bounds;
            return geom;
        }

        void popFront()
        {
            _aes.popFront();
        }

        @property bool empty()
        {
            return _aes.empty;
        }

    private:
        CoordType _aes;
    }

    return GeomRange!AES(aes);
}

/**
Draw ellipse centered at given x,y location

Aside from x and y also width and height are required.
If the type of width is of type Pixel (see aes.d) then dimensions are assumed to be in Pixel (not user coordinates).
*/
auto geomEllipse(AES)(AES aes)
{
    import std.algorithm : map;
    auto xsMap = aes.map!("a.x");
    auto ysMap = aes.map!("a.y");
    alias CoordX = typeof(NumericLabel!(typeof(xsMap))(xsMap));
    alias CoordY = typeof(NumericLabel!(typeof(ysMap))(ysMap));
    auto xsCoords = CoordX(xsMap);
    auto ysCoords = CoordY(ysMap);
    alias CoordType = typeof(DefaultValues
        .mergeRange(aes)
        .mergeRange( Aes!(CoordX, "x", CoordY, "y")
            (CoordX(xsMap), CoordY(ysMap))));

    struct GeomRange(T)
    {
        this(T aes)
        {
            _aes = DefaultValues
                .mergeRange(aes)
                .mergeRange( Aes!(CoordX, "x", CoordY, "y")(
                    xsCoords, ysCoords));
        }

        @property auto front()
        {
            immutable tup = _aes.front;
            immutable f = delegate(cairo.Context context, ColourMap colourMap ) 
            {
                import std.math : isFinite;
                if (!isFinite(tup.x[0]) || !isFinite(tup.y[0]))
                    return context;
                import std.math : PI;
                context.save();
                context.translate( tup.x[0], tup.y[0] );
                static if (is(typeof(tup.width)==immutable(Pixel)))
                    auto devP = context.deviceToUserDistance(cairo.Point!double( tup.width, tup.height )); //tup.width.to!double, tup.width.to!double ));
                context.rotate(tup.angle);
                static if (is(typeof(tup.width)==immutable(Pixel)))
                {
                    context.scale( devP.x/2.0, devP.y/2.0 );
                } else {
                    context.scale( tup.width/2.0, tup.height/2.0 );
                }
                context.arc(0,0, 1.0, 0,2*PI);

                auto col = colourMap(ColourID(tup.colour));
                context.restore();
                context.fillAndStroke( col, tup.fill, tup.alpha );
                return context;
            };

            AdaptiveBounds bounds;
            bounds.adapt(Point(tup.x[0], tup.y[0]));

            auto geom = Geom( tup );
            if (!xsCoords.numeric)
                geom.xTickLabels ~= tup[0];
            if (!ysCoords.numeric)
                geom.yTickLabels ~= tup[1];
            geom.draw = f;
            geom.colours ~= ColourID(tup.colour);
            geom.bounds = bounds;
            return geom;
        }

        void popFront()
        {
            _aes.popFront();
        }

        @property bool empty()
        {
            return _aes.empty;
        }

    private:
        CoordType _aes;
    }

    return GeomRange!AES(aes);
}

/**
Draw triangle centered at given x,y location

Aside from x and y also width and height are required.
If the type of width is of type Pixel (see aes.d) then dimensions are assumed to be in Pixel (not user coordinates).
*/
auto geomTriangle(AES)(AES aes)
{
    import std.algorithm : map;
    auto xsMap = aes.map!("a.x");
    auto ysMap = aes.map!("a.y");
    alias CoordX = typeof(NumericLabel!(typeof(xsMap))(xsMap));
    alias CoordY = typeof(NumericLabel!(typeof(ysMap))(ysMap));
    auto xsCoords = CoordX(xsMap);
    auto ysCoords = CoordY(ysMap);
    alias CoordType = typeof(DefaultValues
        .mergeRange(aes)
        .mergeRange( Aes!(CoordX, "x", CoordY, "y")
            (CoordX(xsMap), CoordY(ysMap))));

    struct GeomRange(T)
    {
        this(T aes)
        {
            _aes = DefaultValues
                .mergeRange(aes)
                .mergeRange( Aes!(CoordX, "x", CoordY, "y")(
                    xsCoords, ysCoords));
        }

        @property auto front()
        {
            immutable tup = _aes.front;
            immutable f = delegate(cairo.Context context, ColourMap colourMap ) 
            {
                import std.math : isFinite;
                if (!isFinite(tup.x[0]) || !isFinite(tup.y[0]))
                    return context;
                context.save();
                context.translate( tup.x[0], tup.y[0] );
                static if (is(typeof(tup.width)==immutable(Pixel)))
                    auto devP = context.deviceToUserDistance(cairo.Point!double( tup.width, -tup.height )); //tup.width.to!double, tup.width.to!double ));
                context.rotate(tup.angle);
                static if (is(typeof(tup.width)==immutable(Pixel)))
                {
                    context.scale( devP.x, devP.y );
                } else {
                    context.scale( tup.width, tup.height );
                }
                context.moveTo( -0.5, -0.5 );
                context.lineTo( 0.5, -0.5 );
                context.lineTo( 0, 0.5 );
                context.closePath;

                auto col = colourMap(ColourID(tup.colour));
                context.restore();
                context.fillAndStroke( col, tup.fill, tup.alpha );
                return context;
            };

            AdaptiveBounds bounds;
            bounds.adapt(Point(tup.x[0], tup.y[0]));

            auto geom = Geom( tup );
            if (!xsCoords.numeric)
                geom.xTickLabels ~= tup[0];
            if (!ysCoords.numeric)
                geom.yTickLabels ~= tup[1];
            geom.draw = f;
            geom.colours ~= ColourID(tup.colour);
            geom.bounds = bounds;
            return geom;
        }

        void popFront()
        {
            _aes.popFront();
        }

        @property bool empty()
        {
            return _aes.empty;
        }

    private:
        CoordType _aes;
    }

    return GeomRange!AES(aes);
}

/**
Draw diamond centered at given x,y location

Aside from x and y also width and height are required.
If the type of width is of type Pixel (see aes.d) then dimensions are assumed to be in Pixel (not user coordinates).
*/
auto geomDiamond(AES)(AES aes)
{
    import std.algorithm : map;
    auto xsMap = aes.map!("a.x");
    auto ysMap = aes.map!("a.y");
    alias CoordX = typeof(NumericLabel!(typeof(xsMap))(xsMap));
    alias CoordY = typeof(NumericLabel!(typeof(ysMap))(ysMap));
    auto xsCoords = CoordX(xsMap);
    auto ysCoords = CoordY(ysMap);
    alias CoordType = typeof(DefaultValues
        .mergeRange(aes)
        .mergeRange( Aes!(CoordX, "x", CoordY, "y")
            (CoordX(xsMap), CoordY(ysMap))));

    struct GeomRange(T)
    {
        this(T aes)
        {
            _aes = DefaultValues
                .mergeRange(aes)
                .mergeRange( Aes!(CoordX, "x", CoordY, "y")(
                    xsCoords, ysCoords));
        }

        @property auto front()
        {
            immutable tup = _aes.front;
            immutable f = delegate(cairo.Context context, ColourMap colourMap ) 
            {
                import std.math : isFinite;
                if (!isFinite(tup.x[0]) || !isFinite(tup.y[0]))
                    return context;
                context.save();
                context.translate( tup.x[0], tup.y[0] );
                static if (is(typeof(tup.width)==immutable(Pixel)))
                    auto devP = context.deviceToUserDistance(cairo.Point!double( tup.width, tup.height )); //tup.width.to!double, tup.width.to!double ));
                context.rotate(tup.angle);
                static if (is(typeof(tup.width)==immutable(Pixel)))
                {
                    context.scale( devP.x, devP.y );
                } else {
                    context.scale( tup.width, tup.height );
                }
                context.moveTo( 0, -0.5 );
                context.lineTo( 0.5, 0 );
                context.lineTo( 0, 0.5 );
                context.lineTo( -0.5, 0 );
                context.closePath;

                auto col = colourMap(ColourID(tup.colour));
                context.restore();
                context.fillAndStroke( col, tup.fill, tup.alpha );
                return context;
            };

            AdaptiveBounds bounds;
            bounds.adapt(Point(tup.x[0], tup.y[0]));

            auto geom = Geom( tup );
            if (!xsCoords.numeric)
                geom.xTickLabels ~= tup[0];
            if (!ysCoords.numeric)
                geom.yTickLabels ~= tup[1];
            geom.draw = f;
            geom.colours ~= ColourID(tup.colour);
            geom.bounds = bounds;
            return geom;
        }

        void popFront()
        {
            _aes.popFront();
        }

        @property bool empty()
        {
            return _aes.empty;
        }

    private:
        CoordType _aes;
    }

    return GeomRange!AES(aes);
}


/// Create points from the data
auto geomPoint(AES)(AES aes)
{
    import std.algorithm : map;
    import std.conv : to;
    import ggplotd.aes : Aes, mergeRange, Pixel;
    auto _aes = DefaultValues.mergeRange(aes);
    auto wh = _aes.map!((a) => Pixel((8*a.size).to!int));
    auto filled = _aes.map!((a) => a.alpha);
    auto merged = Aes!(typeof(wh), "width", typeof(wh), "height",
        typeof(filled),"fill")( wh, wh, filled )
        .mergeRange( aes );
    return geomEllipse!(typeof(merged))(merged);
}

///
unittest
{
    auto aes = Aes!(double[], "x", double[], "y")([1.0], [2.0]);
    auto gl = geomPoint(aes);
    assertEqual(gl.front.colours[0][1], "black");
    gl.popFront;
    assert(gl.empty);
}

/// Create lines from data 
auto geomLine(AES)(AES aes)
{
    import std.algorithm : map;
    import std.range : array, zip;

    struct GeomRange(T)
    {
        this(T aes)
        {
            groupedAes = aes.group;
        }

        @property auto front()
        {
            auto xs = numericLabel(groupedAes.front.map!((t) => t.x));
            auto ys = numericLabel(groupedAes.front.map!((t) => t.y));
            auto coordsZip = zip(xs, ys);

            immutable flags = groupedAes.front.front;
            immutable f = delegate(cairo.Context context, 
                ColourMap colourMap ) {

                import std.math : isFinite;
                auto coords = coordsZip.save;
                auto fr = coords.front;
                context.moveTo(fr[0][0], fr[1][0]);
                coords.popFront;
                foreach (tup; coords)
                {
                    // TODO should we actually move to next coordinate here?
                    if (isFinite(tup[0][0]) && isFinite(tup[1][0]))
                    {
                        context.lineTo(tup[0][0], tup[1][0]);
                        context.lineWidth = 2.0*flags.size;
                    } else {
                        context.newSubPath();
                    }
                }

                auto col = colourMap(ColourID(flags.colour));
                import ggplotd.colourspace : RGBA, toCairoRGBA;
                context.fillAndStroke( col, flags.fill, flags.alpha );
                return context;
            };

            AdaptiveBounds bounds;
            auto geom = Geom(groupedAes.front.front);
            foreach (tup; coordsZip)
            {
                bounds.adapt(Point(tup[0][0], tup[1][0]));
                if (!xs.numeric)
                    geom.xTickLabels ~= tup[0];
                if (!ys.numeric)
                    geom.yTickLabels ~= tup[1];
            }
            geom.draw = f;
            geom.colours ~= ColourID(groupedAes.front.front.colour);
            geom.bounds = bounds;
            return geom;
        }

        void popFront()
        {
            groupedAes.popFront;
        }

        @property bool empty()
        {
            return groupedAes.empty;
        }

    private:
        typeof(group(T.init)) groupedAes;
    }

    return GeomRange!AES(aes);
}

///
unittest
{
    auto aes = Aes!(double[], "x", double[], "y", string[], "colour")([1.0,
        2.0, 1.1, 3.0], [3.0, 1.5, 1.1, 1.8], ["a", "b", "a", "b"]);

    auto gl = geomLine(aes);

    import std.range : empty;

    assert(gl.front.xTickLabels.empty);
    assert(gl.front.yTickLabels.empty);

    assertEqual(gl.front.colours[0][1], "a");
    assertEqual(gl.front.bounds.min_x, 1.0);
    assertEqual(gl.front.bounds.max_x, 1.1);
    gl.popFront;
    assertEqual(gl.front.colours[0][1], "b");
    assertEqual(gl.front.bounds.max_x, 3.0);
    gl.popFront;
    assert(gl.empty);
}

unittest
{
    auto aes = Aes!(string[], "x", string[], "y", string[], "colour")(["a",
        "b", "c", "b"], ["a", "b", "b", "a"], ["b", "b", "b", "b"]);

    auto gl = geomLine(aes);
    assertEqual(gl.front.xTickLabels.length, 4);
    assertEqual(gl.front.yTickLabels.length, 4);
}

unittest
{
    auto aes = Aes!(string[], "x", string[], "y", string[], "colour")(["a",
        "b", "c", "b"], ["a", "b", "b", "a"], ["b", "b", "b", "b"]);

    auto gl = geomLine(aes);
    auto aes2 = Aes!(string[], "x", string[], "y", double[], "colour")(["a",
        "b", "c", "b"], ["a", "b", "b", "a"], [0, 1, 0, 0.1]);

    auto gl2 = geomLine(aes2);

    import std.range : chain, walkLength;

    assertEqual(gl.chain(gl2).walkLength, 4);
}

// Bin a range of data
private auto bin(R)(R xs, double min, double max, size_t noBins = 10)
{
    struct Bin
    {
        double[] range;
        size_t count;
    }

    import std.typecons : Tuple;
    import std.algorithm : group;

    struct BinRange(Range)
    {
        this(Range xs, size_t noBins)
        {
            import std.math : floor;
            import std.algorithm : sort, map;
            import std.array : array;
            import std.range : walkLength;

            _width = (max - min) / (noBins - 1);
            _noBins = noBins;
            // If min == max or noBins == 1 we need to set a custom width
            if (noBins == 1 || _width == 0)
                _width = 0.1;
            _min = min - 0.5 * _width;

            // Count the number of data points that fall in a
            // bin. This is done by scaling them into whole numbers
            if (xs.walkLength > 0)
            {
                counts = xs.map!((a) => floor((a - _min) / _width)).array.sort().array.group();

                // Initialize our bins
                if (counts.front[0] == _binID)
                    {
                    _cnt = counts.front[1];
                    counts.popFront;
                }
            }
        }

        /// Return a bin describing the range and number of data points (count) that fall within that range.
        @property auto front()
        {
            return Bin([_min, _min + _width], _cnt);
        }

        void popFront()
        {
            _min += _width;
            _cnt = 0;
            ++_binID;
            if (!counts.empty && counts.front[0] == _binID)
            {
                _cnt = counts.front[1];
                counts.popFront;
            }
        }

        @property bool empty()
        {
            return _binID >= _noBins;
        }

    private:
        double _min;
        double _width;
        size_t _noBins;
        size_t _binID = 0;
        typeof(group(Range.init)) counts;
        size_t _cnt = 0;
    }

    return BinRange!R(xs, noBins);
}

private auto bin(R)(R xs, size_t noBins = 10)
{
    import std.algorithm : min, max, reduce;
    import std.range : walkLength;
    assert(xs.walkLength > 0);

    auto minmax = xs.reduce!((a, b) => min(a, b), (a, b) => max(a, b));
    return bin( xs, minmax[0], minmax[1], noBins );
}
 

unittest
{
    import std.array : array;
    import std.range : back, walkLength;

    auto binR = bin!(double[])([0.5, 0.01, 0.0, 0.9, 1.0, 0.99], 11);
    assertEqual(binR.walkLength, 11);
    assertEqual(binR.front.range, [-0.05, 0.05]);
    assertEqual(binR.front.count, 2);
    assertLessThan(binR.array.back.range[0], 1);
    assertGreaterThan(binR.array.back.range[1], 1);
    assertEqual(binR.array.back.count, 2);

    binR = bin!(double[])([0.01], 11);
    assertEqual(binR.walkLength, 11);
    assertEqual(binR.front.count, 1);

    binR = bin!(double[])([-0.01, 0, 0, 0, 0.01], 11);
    assertEqual(binR.walkLength, 11);
    assertLessThan(binR.front.range[0], -0.01);
    assertGreaterThan(binR.front.range[1], -0.01);
    assertEqual(binR.front.count, 1);
    assertLessThan(binR.array.back.range[0], 0.01);
    assertGreaterThan(binR.array.back.range[1], 0.01);
    assertEqual(binR.array.back.count, 1);
    assertEqual(binR.array[5].count, 3);
    assertLessThan(binR.array[5].range[0], 0.0);
    assertGreaterThan(binR.array[5].range[1], 0.0);

    import std.math : isNaN;
    auto b = [0.5].bin(1);
    assert( !isNaN(b.front.range[0]) );
    assertGreaterThan( b.front.range[1], b.front.range[0] );
}


/// Draw histograms based on the x coordinates of the data (aes)
auto geomHist(AES)(AES aes, size_t noBins = 0)
{
    import std.algorithm : map, max, min;
    import std.array : Appender, array;
    import std.range : repeat, take, walkLength;
    import std.typecons : Tuple;

    import ggplotd.range : uniquer;

    // New appender to hold lines for drawing histogram
    auto appender = Appender!(Geom[])([]);

    foreach (grouped; group(aes)) // Split data by colour/id
    {
        // Extract the x coordinates
        auto xsNL = numericLabel(grouped.map!((t) => t.x));
        auto xs = xsNL.map!((t) => t[0]) // Extract the x coordinates
            .array;
        if (noBins < 1)
            noBins = min(xsNL.uniquer.take(30).walkLength,
                    min(30,max(11, xs.length/10)));
        auto bins = xs.bin(noBins); // Bin the data

        foreach (bin; bins)
        {
            // Specifying the boxes for the histogram. The merge is used to keep the colour etc. information
            // contained in the original merged passed to geomHist.
            appender.put(
                geomLine( [
                    grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                            bin.range[0], 0.0 )),
                    grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                            bin.range[0], bin.count )),
                    grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                            bin.range[1], bin.count )),
                    grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                            bin.range[1], 0.0 )),
                ] )
            );
        }
    }

    // Return the different lines 
    return appender.data;
}

/// Draw histograms based on the x coordinates of the data (aes)
auto geomHist3D(AES)(AES aes, size_t noBinsX = 0, size_t noBinsY = 0)
{
    import std.algorithm : filter, group, map, reduce, max, min;
    import std.array : array, Appender;
    import std.range : take, walkLength, zip;
    import ggplotd.range : uniquer;
    // New appender to hold lines for drawing histogram
    auto appender = Appender!(Geom[])([]);

    auto xsNL = numericLabel(aes.map!("a.x"));
    auto xs = xsNL.map!((t) => t[0]) // Extract the x coordinates
            .array;
    auto ysNL = numericLabel(aes.map!("a.y"));
    auto ys = ysNL.map!((t) => t[0]) // Extract the y coordinates
            .array;

    // Work out min/max of the x and y data
    auto minmaxX = reduce!("min(a,b)","max(a,b)")( Tuple!(double,double)(xs.front, xs.front), xs );
    auto minmaxY = reduce!("min(a,b)","max(a,b)")( Tuple!(double,double)(ys.front, ys.front), ys );

    // Track maximum z value for colour scaling
    double maxZ = -1;

    if (noBinsX < 1)
        noBinsX = min(xsNL.uniquer.take(30).walkLength,
                min(30,max(11, xs.length/25)));
    if (noBinsY < 1)
        noBinsY = min(ysNL.uniquer.take(30).walkLength,
                min(30,max(11, ys.length/25)));

    auto coords = zip(xs, ys);


    foreach( binX; xs.bin( minmaxX[0], minmaxX[1], noBinsX ) )
    {
        // TODO this is not the most efficient way to create 2d bins
        foreach( binY; coords.filter!( 
                (a) => a[0] >= binX.range[0] && a[0] < binX.range[1] )
            .map!( (a) => a[1] ).array
            .bin( minmaxY[0], minmaxY[1], noBinsY ) )
        {
            maxZ = max( maxZ, binY.count );
            appender.put(
                geomPolygon(
            [aes.front.merge( 
                Tuple!( double, "x", double, "y", double, "colour" )
                    ( binX.range[0], binY.range[0], binY.count ) ),
             aes.front.merge( 
                Tuple!( double, "x", double, "y", double, "colour" )
                    ( binX.range[0], binY.range[1], binY.count ) ),
             aes.front.merge( 
                Tuple!( double, "x", double, "y", double, "colour" )
                    ( binX.range[1], binY.range[1], binY.count ) ),
             aes.front.merge( 
                Tuple!( double, "x", double, "y", double, "colour" )
                        ( binX.range[1], binY.range[0], binY.count ) )] )
            );
        }
    }
    // scale colours by max_z
    return appender.data;
}
/// Draw axis, first and last location are start/finish
/// others are ticks (perpendicular)
auto geomAxis(AES)(AES aes, double tickLength, string label)
{
    import std.algorithm : find;
    import std.array : array;
    import std.range : chain, empty, repeat;
    import std.math : sqrt, pow;

    double[] xs;
    double[] ys;

    double[] lxs;
    double[] lys;
    double[] langles;
    string[] lbls;

    auto merged = DefaultValues.mergeRange(aes);

    immutable toDir = 
        merged.find!("a.x != b.x || a.y != b.y")(merged.front).front; 
    auto direction = [toDir.x - merged.front.x, toDir.y - merged.front.y];
    immutable dirLength = sqrt(pow(direction[0], 2) + pow(direction[1], 2));
    direction[0] *= tickLength / dirLength;
    direction[1] *= tickLength / dirLength;
 
    while (!merged.empty)
    {
        auto tick = merged.front;
        xs ~= tick.x;
        ys ~= tick.y;

        merged.popFront;

        // Draw ticks perpendicular to main axis;
        if (xs.length > 1 && !merged.empty)
        {
            xs ~= [tick.x + direction[1], tick.x];
            ys ~= [tick.y + direction[0], tick.y];

            lxs ~= tick.x - 1.5*direction[1];
            lys ~= tick.y - 1.5*direction[0];
            lbls ~= tick.label;
            langles ~= tick.angle;
        }
    }

    // Main label
    auto xm = xs[0] + 0.5*(xs[$-1]-xs[0]) - 4.0*direction[1];
    auto ym = ys[0] + 0.5*(ys[$-1]-ys[0]) - 4.0*direction[0];
    auto aesM = Aes!(double[], "x", double[], "y", string[], "label", 
        double[], "angle", bool[], "mask")( [xm], [ym], [label], 
            langles, [false]);

    return geomLine(Aes!(typeof(xs), "x", typeof(ys), "y", bool[], "mask")(
        xs, ys, false.repeat(xs.length).array)).chain(
        geomLabel(Aes!(double[], "x", double[], "y", string[], "label",
        double[], "angle", bool[], "mask")(lxs, lys, lbls, langles, 
            false.repeat(lxs.length).array)))
            .chain( geomLabel(aesM) );
}

/// Draw Label at given x and y position
auto geomLabel(AES)(AES aes)
{
    import std.algorithm : map;
    auto xsMap = aes.map!("a.x");
    auto ysMap = aes.map!("a.y");
    alias CoordX = typeof(NumericLabel!(typeof(xsMap))(xsMap));
    alias CoordY = typeof(NumericLabel!(typeof(ysMap))(ysMap));
    alias CoordType = typeof(DefaultValues
        .mergeRange(aes)
        .mergeRange( Aes!(CoordX, "x", CoordY, "y")
            (CoordX(xsMap), CoordY(ysMap))));


    struct GeomRange(T)
    {
        this(T aes)
        {
            _aes = DefaultValues
                .mergeRange(aes)
                .mergeRange( Aes!(CoordX, "x", CoordY, "y")(
                    CoordX(xsMap), CoordY(ysMap)));
        }

        @property auto front()
        {
            immutable tup = _aes.front;
            immutable f = delegate(cairo.Context context, ColourMap colourMap) {
                import std.math : isFinite;
                if (!isFinite(tup.x[0]) || !isFinite(tup.y[0]))
                    return context;
                context.setFontSize(14.0*tup.size);
                context.moveTo(tup.x[0], tup.y[0]);
                context.save();
                context.identityMatrix;
                context.rotate(tup.angle);
                auto extents = context.textExtents(tup.label);
                auto textSize = cairo.Point!double(0.5 * extents.width, 0.5 * extents.height);
                context.relMoveTo(-textSize.x, textSize.y);

                auto col = colourMap(ColourID(tup.colour));
                import ggplotd.colourspace : RGBA, toCairoRGBA;

                context.setSourceRGBA(
                    RGBA(col.r, col.g, col.b, tup.alpha)
                        .toCairoRGBA
                );
 
                context.showText(tup.label);
                context.restore();
                return context;
            };

            AdaptiveBounds bounds;
            bounds.adapt(Point(tup.x[0], tup.y[0]));

            auto geom = Geom( tup );
            geom.draw = f;
            geom.colours ~= ColourID(tup.colour);
            geom.bounds = bounds;
 
            return geom;
        }

        void popFront()
        {
            _aes.popFront();
        }

        @property bool empty()
        {
            return _aes.empty;
        }

    private:
        CoordType _aes;
    }

    return GeomRange!AES(aes);
}

unittest
{
    auto aes = Aes!(string[], "x", string[], "y", string[], "label")(["a", "b",
        "c", "b"], ["a", "b", "b", "a"], ["b", "b", "b", "b"]);

    auto gl = geomLabel(aes);
    import std.range : walkLength;

    assertEqual(gl.walkLength, 4);
}

// geomBox
/// Return the limits indicated with different alphas
private auto limits( RANGE )( RANGE range, double[] alphas )
{
    import std.algorithm : sort, map, min, max;
    import std.math : floor;
    import std.conv : to;
    auto sorted = range.sort();
    return alphas.map!( (a) { 
        auto id = min( sorted.length.to!int-2,
            max(0,floor( a*(sorted.length+1) ).to!int-1 ) );
        assert( id >= 0 );
        if (a<=0.5)
            return sorted[id];
        else
            return sorted[id+1];
    });
}

unittest
{
    import std.range : array, front;
    assertEqual( [1,2,3,4,5].limits( [0.01, 0.5, 0.99] ).array, 
            [1,3,5] );

    assertEqual( [1,2,3,4].limits( [0.41] ).front, 2 );
    assertEqual( [1,2,3,4].limits( [0.39] ).front, 1 );
    assertEqual( [1,2,3,4].limits( [0.61] ).front, 4 );
    assertEqual( [1,2,3,4].limits( [0.59] ).front, 3 );
}

/// Draw a boxplot. The "x" data is used. If labels are given then the data is grouped by the label
auto geomBox(AES)(AES aes)
{
    import std.algorithm : map;
    import std.array : array;
    import std.range : Appender;

    Appender!(Geom[]) result;

    // If has y, use that
    immutable fr = aes.front;
    static if (__traits(hasMember, fr, "y"))
    {
        auto labels = numericLabel( aes.map!("a.y") );
        auto myAes = aes.mergeRange( Aes!(typeof(labels), "label")( labels ) );
    } else {
        static if (__traits(hasMember, fr, "label"))
        {
            // esle If has label, use that
            auto labels = numericLabel( aes.map!("a.label.to!string") );
            auto myAes = aes.mergeRange( Aes!(typeof(labels), "label")( labels ) );
        } else {
            import std.range : repeat;
            auto labels = numericLabel( repeat("a", aes.length) );
            auto myAes = aes.mergeRange( Aes!(typeof(labels), "label")( labels ) );
        }
    }
    
    double delta = 0.2;
    Tuple!(double, string)[] xTickLabels;

    foreach( grouped; myAes.group() )
    {
        auto lims = grouped.map!("a.x")
            .array.limits( [0.1,0.25,0.5,0.75,0.9] ).array;
        auto x = grouped.front.label[0];
        xTickLabels ~= grouped.front.label;
        // TODO this should be some kind of loop
        result.put(
            geomLine( [
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x, lims[0] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x, lims[1] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x+delta, lims[1] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x+delta, lims[2] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x-delta, lims[2] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x-delta, lims[3] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x, lims[3] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x, lims[4] )),

                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x, lims[3] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x+delta, lims[3] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x+delta, lims[2] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x-delta, lims[2] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x-delta, lims[1] )),
                grouped.front.merge(Tuple!(double, "x", double, "y" )( 
                    x, lims[1] ))
             ] )
        );
    }

    import std.algorithm : sort;
    xTickLabels = xTickLabels.sort!((a,b) => a[0] < b[0]).array;

    foreach( ref g; result.data )
    {
        g.xTickLabels = xTickLabels;
        g.bounds.min_x = xTickLabels.front[0] - 0.5;
        g.bounds.max_x = xTickLabels[$-1][0] + 0.5;
    }

    return result.data;
}

///
unittest 
{
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain;
    import std.random : uniform;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25)).array;
    auto aes = Aes!(typeof(xs), "x", typeof(cols), "colour", 
        double[], "fill", typeof(cols), "label" )( 
            xs, cols, 0.45.repeat(xs.length).array, cols);
    auto gb = geomBox( aes );
    assertEqual( gb.front.bounds.min_x, -0.5 );
}

unittest 
{
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain;
    import std.random : uniform;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25)).array;
    auto ys = 2.repeat(25).chain(3.repeat(25)).array;
    auto aes = Aes!(typeof(xs), "x", typeof(cols), "colour", 
        double[], "fill", typeof(ys), "y" )( 
            xs, cols, 0.45.repeat(xs.length).array, ys);
    auto gb = geomBox( aes );
    assertEqual( gb.front.bounds.min_x, 1.5 );
}

unittest 
{
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain;
    import std.random : uniform;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25)).array;
    auto aes = Aes!(typeof(xs), "x", typeof(cols), "colour", 
        double[], "fill")( 
            xs, cols, 0.45.repeat(xs.length).array);
    auto gb = geomBox( aes );
    assertEqual( gb.front.bounds.min_x, -0.5 );
}

/// Draw a polygon 
auto geomPolygon(AES)(AES aes)
{
    import std.array : array;
    import std.algorithm : map, swap;
    import std.conv : to;
    import ggplotd.geometry : gradientVector, Vertex3D;

    auto merged = DefaultValues.mergeRange(aes);
    // Turn into vertices.
    static if (is(typeof(merged.front.colour)==ColourID))
        auto vertices = merged.map!( (t) => Vertex3D( t.x.to!double, t.y.to!double, 
                    t.colour[0] ) );
    else
        auto vertices = merged.map!( (t) => Vertex3D( t.x.to!double, t.y.to!double, 
                    t.colour.to!double ) );

    // Find lowest, highest
    auto triangle = vertices.array;
    if (triangle[1].z < triangle[0].z)
        swap( triangle[1], triangle[0] );
    if (triangle[2].z < triangle[0].z)
        swap( triangle[2], triangle[0] );
    if (triangle[1].z > triangle[2].z)
        swap( triangle[1], triangle[2] );

    if (triangle.length > 3)
        foreach( v; triangle[3..$] )
        {
            if (v.z < triangle[0].z)
                swap( triangle[0], v );
            else if ( v.z > triangle[2].z )
                swap( triangle[2], v );
        }
    auto gV = gradientVector( triangle[0..3] );

    immutable flags = merged.front;

    auto geom = Geom( flags );

    foreach( v; vertices )
        geom.bounds.adapt(Point(v.x, v.y));

    // Define drawFunction
    immutable f = delegate(cairo.Context context, ColourMap colourMap ) 
    {
        auto gradient = new cairo.LinearGradient( gV[0].x, gV[0].y, 
            gV[1].x, gV[1].y );

        auto col0 = colourMap(ColourID(gV[0].z));
        auto col1 = colourMap(ColourID(gV[1].z));
        import ggplotd.colourspace : RGBA, toCairoRGBA;
        gradient.addColorStopRGBA( 0,
            RGBA(col0.r, col0.g, col0.b, flags.alpha)
                .toCairoRGBA
        );
        gradient.addColorStopRGBA( 1,
            RGBA(col1.r, col1.g, col1.b, flags.alpha)
                .toCairoRGBA
        );
        context.moveTo( vertices.front.x, vertices.front.y );
        vertices.popFront;
        foreach( v; vertices )
            context.lineTo( v.x, v.y );
        context.closePath;
        context.setSource( gradient );
        context.fillPreserve;
        context.identityMatrix();
        context.stroke;
        return context;
    };

    geom.draw = f;

    geom.colours = merged.map!((t) => ColourID(t.colour)).array;

    return [geom];
}
