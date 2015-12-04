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

///
struct Geom
{
    this(T)( in T tup ) //if (is(T==Tuple))
    {
        mask = tup.mask;
    }

    alias drawFunction = cairo.Context delegate(cairo.Context context, 
        ColourMap colourMap);
    drawFunction draw; ///
    ColourID[] colours; ///
    AdaptiveBounds bounds; ///

    bool mask = true; /// Whether to mask/prevent drawing outside plotting area

    import std.typecons : Tuple;

    Tuple!(double, string)[] xTickLabels; ///
    Tuple!(double, string)[] yTickLabels; ///
}

///
auto geomPoint(AES)(AES aes)
{
    alias CoordX = typeof(NumericLabel!(typeof(AES.x))(AES.x));
    alias CoordY = typeof(NumericLabel!(typeof(AES.y))(AES.y));
    alias CoordType = typeof(merge(aes, Aes!(CoordX, "x", CoordY,
        "y")(CoordX(AES.x), CoordY(AES.y))));

    struct GeomRange(T)
    {
        this(T aes)
        {
            _aes = merge(aes, Aes!(CoordX, "x", CoordY, "y")(CoordX(aes.x), CoordY(aes.y)));
        }

        @property auto front()
        {
            immutable tup = _aes.front;
            auto f = delegate(cairo.Context context, ColourMap colourMap ) 
            {
                auto devP = context.userToDevice(cairo.Point!double(tup.x[0], tup.y[0]));
                context.save();
                context.identityMatrix;
                context.rectangle(devP.x - 0.5 * tup.size, devP.y - 0.5 * tup.size, tup.size, tup.size);
                context.restore();

                auto col = colourMap(ColourID(tup.colour));
                import cairo.cairo : RGBA;

                context.identityMatrix();

                context.setSourceRGBA(RGBA(col.red, col.green, col.blue, tup.alpha));
                context.fill();

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

///
unittest
{
    auto aes = Aes!(double[], "x", double[], "y")([1.0], [2.0]);
    auto gl = geomPoint(aes);
    assertEqual(gl.front.colours[0][1], "black");
    gl.popFront;
    assert(gl.empty);
}

///
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
            auto xs = NumericLabel!(typeof(groupedAes.front.front.x)[])(
                groupedAes.front.map!((t) => t.x).array);
            auto ys = NumericLabel!(typeof(groupedAes.front.front.y)[])(
                groupedAes.front.map!((t) => t.y).array);
            auto coords = zip(xs, ys);

            immutable flags = groupedAes.front.front;
            auto f = delegate(cairo.Context context, ColourMap colourMap ) {
                auto fr = coords.front;
                context.moveTo(fr[0][0], fr[1][0]);
                coords.popFront;
                foreach (tup; coords)
                {
                    context.lineTo(tup[0][0], tup[1][0]);
                }

                auto col = colourMap(ColourID(flags.colour));
                import cairo.cairo : RGBA;

                context.identityMatrix();
                if (flags.fill>0)
                {
                    context.setSourceRGBA(RGBA(col.red, col.green, col.blue, flags.fill));
                    context.fillPreserve();
                }
                context.setSourceRGBA(RGBA(col.red, col.green, col.blue, flags.alpha));
                context.stroke();

                return context;
            };

            AdaptiveBounds bounds;
            coords = zip(xs, ys);
            auto geom = Geom(groupedAes.front.front);
            foreach (tup; coords)
            {
                bounds.adapt(Point(tup[0][0], tup[1][0]));
                if (!xs.numeric)
                    geom.xTickLabels ~= tup[0];
                if (!ys.numeric)
                    geom.yTickLabels ~= tup[0];
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
private auto bin(R)(R xs, size_t noBins = 10)
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
            import std.algorithm : min, max, reduce, sort, map;
            import std.array : array;
            import std.range : walkLength;

            assert(xs.walkLength > 0);

            // Find the min and max values
            auto minmax = xs.reduce!((a, b) => min(a, b), (a, b) => max(a, b));
            _width = (minmax[1] - minmax[0]) / (noBins - 1);
            _noBins = noBins;
            // If min == max we need to set a custom width
            if (_width == 0)
                _width = 0.1;
            _min = minmax[0] - 0.5 * _width;

            // Count the number of data points that fall in a
            // bin. This is done by scaling them into whole numbers
            counts = xs.map!((a) => floor((a - _min) / _width)).array.sort().array.group();

            // Initialize our bins
            if (counts.front[0] == _binID)
            {
                _cnt = counts.front[1];
                counts.popFront;
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
}


/// Draw histograms based on the x coordinates of the data (aes)
auto geomHist(AES)(AES aes)
{
    import std.algorithm : map;
    import std.array : Appender, array;
    import std.range : repeat;
    import std.typecons : Tuple;

    // New appender to hold lines for drawing histogram
    auto appender = Appender!(Geom[])([]);

    foreach (grouped; group(aes)) // Split data by colour/id
    {
        auto bins = grouped.map!((t) => t.x) // Extract the x coordinates
            .array.bin(11); // Bin the data

        foreach (bin; bins)
        {
            // Specifying the boxes for the histogram. The merge is used to keep the colour etc. information
            // contained in the original aes passed to geomHist.
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

/// Draw axis, first and last location are start/finish
/// others are ticks (perpendicular)
auto geomAxis(AES)(AES aes, double tickLength, string label)
{
    import std.array : array;
    import std.range : chain, empty, repeat;
    import std.math : sqrt, pow;

    double[] xs;
    double[] ys;

    double[] lxs;
    double[] lys;
    double[] langles;
    string[] lbls;

    auto colour = aes.front.colour;
    double[2] orig = [aes.front.x, aes.front.y];
    double[2] direction;

    while (!aes.empty)
    {
        auto tick = aes.front;
        xs ~= tick.x;
        ys ~= tick.y;

        aes.popFront;

        // Draw ticks perpendicular to main axis;
        if (xs.length > 1 && !aes.empty)
        {
            if (xs.length == 2)
            {
                // Calculate tick direction and size
                direction = [tick.x - orig[0], tick.y - orig[1]];
                auto dirLength = sqrt(pow(direction[0], 2) + pow(direction[1], 2));
                direction[0] *= tickLength / dirLength;
                direction[1] *= tickLength / dirLength;
            }
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
    alias CoordX = typeof(NumericLabel!(typeof(AES.x))(AES.x));
    alias CoordY = typeof(NumericLabel!(typeof(AES.y))(AES.y));
    alias CoordType = typeof(merge(aes, Aes!(CoordX, "x", CoordY,
        "y")(CoordX(AES.x), CoordY(AES.y))));

    struct GeomRange(T)
    {
        size_t size = 6;
        this(T aes)
        {
            _aes = merge(aes, Aes!(CoordX, "x", CoordY, "y")(CoordX(aes.x), CoordY(aes.y)));
        }

        @property auto front()
        {
            immutable tup = _aes.front;
            auto f = delegate(cairo.Context context, ColourMap colourMap) {
                context.setFontSize(14.0);
                context.moveTo(tup.x[0], tup.y[0]);
                context.save();
                context.identityMatrix;
                context.rotate(tup.angle);
                auto extents = context.textExtents(tup.label);
                auto textSize = cairo.Point!double(0.5 * extents.width, 0.5 * extents.height);
                context.relMoveTo(-textSize.x, textSize.y);

                auto col = colourMap(ColourID(tup.colour));
                import cairo.cairo : RGBA;

                context.setSourceRGBA(RGBA(col.red, col.green, col.blue, tup.alpha));
 
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
        auto id = min( sorted.length-2,
            max(0,floor( a*(sorted.length+1) ).to!int-1 ) );
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
    auto labels = NumericLabel!(string[])( 
        aes.map!("a.label.to!string").array );
    auto myAes = aes.merge( Aes!(typeof(labels), "label")( labels ) );

    double delta = 0.2;
    Tuple!(double, string)[] xTickLabels;

    foreach( grouped; myAes.group() )
    {
        auto lims = grouped.map!("a.x")
            .array.limits( [0.1,0.25,0.5,0.75,0.9] ).array;
        auto x = grouped.front.label[0];
        xTickLabels ~= grouped.front.label;
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

    foreach( ref g; result.data )
    {
        g.xTickLabels = xTickLabels;
        g.bounds.min_x = xTickLabels.front[0] - 0.5;
        g.bounds.max_x = xTickLabels[$-1][0] + 0.5;
    }

    return result.data;
}

