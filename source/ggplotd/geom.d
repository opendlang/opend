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

/++
General function for drawing geomShapes
+/
private template geomShape( string shape, AES )
{
    import std.algorithm : map;
    import ggplotd.aes : numericLabel;
    import ggplotd.range : mergeRange;
    alias CoordX = typeof(numericLabel(AES.init.map!("a.x")));
    alias CoordY = typeof(numericLabel(AES.init.map!("a.y")));
    alias CoordType = typeof(DefaultValues
        .mergeRange(AES.init)
        .mergeRange(Aes!(CoordX, "x", CoordY, "y").init));

    struct VolderMort 
    {
        this(AES aes)
        {
            import std.algorithm : map;
            import ggplotd.range : mergeRange;
            _aes = DefaultValues
                .mergeRange(aes)
                .mergeRange( Aes!(CoordX, "x", CoordY, "y")(
                    CoordX(aes.map!("a.x")), 
                    CoordY(aes.map!("a.y"))));
        }

        @property auto front()
        {
            immutable tup = _aes.front;
            immutable f = delegate(cairo.Context context, ColourMap colourMap ) 
            {
                import std.math : isFinite;
                if (!isFinite(tup.x.to!double) || !isFinite(tup.y.to!double))
                    return context;
                context.save();
                context.translate( tup.x.to!double, tup.y.to!double );
                static if (is(typeof(tup.width)==immutable(Pixel)))
                    auto devP = context.deviceToUserDistance(cairo.Point!double( tup.width, tup.height )); //tup.width.to!double, tup.width.to!double ));
                context.rotate(tup.angle);
                static if (shape=="ellipse")
                {
                    import std.math : PI;
                    static if (is(typeof(tup.width)==immutable(Pixel)))
                    {
                        context.scale( devP.x/2.0, devP.y/2.0 );
                    } else {
                        context.scale( tup.width/2.0, tup.height/2.0 );
                    }
                    context.arc(0,0, 1.0, 0,2*PI);
                } else {
                    static if (is(typeof(tup.width)==immutable(Pixel)))
                    {
                        context.scale( devP.x, devP.y );
                    } else {
                        context.scale( tup.width, tup.height );
                    }
                    static if (shape=="triangle")
                    {
                        context.moveTo( -0.5, -0.5 );
                        context.lineTo( 0.5, -0.5 );
                        context.lineTo( 0, 0.5 );
                    } else static if (shape=="diamond") {
                        context.moveTo( 0, -0.5 );
                        context.lineTo( 0.5, 0 );
                        context.lineTo( 0, 0.5 );
                        context.lineTo( -0.5, 0 );
                    } else {
                        context.moveTo( -0.5, -0.5 );
                        context.lineTo( -0.5,  0.5 );
                        context.lineTo(  0.5,  0.5 );
                        context.lineTo(  0.5, -0.5 );
                    }
                    context.closePath;
                }

                auto col = colourMap(ColourID(tup.colour));
                context.restore();
                context.fillAndStroke( col, tup.fill, tup.alpha );
                return context;
            };

            AdaptiveBounds bounds;
            static if (is(typeof(tup.width)==immutable(Pixel)))
                bounds.adapt(Point(tup.x[0], tup.y[0]));
            else
            {
                bounds.adapt(Point(tup.x[0]-0.5*tup.width, 
                            tup.y[0]-0.5*tup.height));
                bounds.adapt(Point(tup.x[0]+0.5*tup.width,
                            tup.y[0]+0.5*tup.height));
            }

            auto geom = Geom( tup );
            static if (CoordX.numeric)
                geom.xTickLabels ~= tup.x;
            static if (CoordY.numeric)
                geom.yTickLabels ~= tup.y;
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

    auto geomShape(AES aes)
    {
        return VolderMort(aes);
    }
}

unittest
{
    auto xs = numericLabel!(double[])([ 1.0, 2.0 ]);

    auto aes = Aes!( typeof(xs), "x", double[], "y", double[], "width", double[], "height" )
        ( xs, [3.0, 4.0], [1.0,1], [2.0,2] );
    auto geoms = geomShape!("rectangle", typeof(aes))( aes );

    import std.range : walkLength;
    assertEqual( geoms.walkLength, 2 );
}

/**
Draw any type of geom

The type field is required, which should be a string. Any of the geom* functions in ggplotd.geom 
can be passed using a lower case string minus the geom prefix, i.e. hist2d calls geomHist2D etc.

  Examples:
  --------------
    import ggplotd.geom : geomType;
    geomType(Aes!(double[], "x", double[], "y", string[], "type")
        ( [0.0,1,2], [5.0,6,7], ["line", "point", "line"] ));
  --------------

*/
template geomType(AES)
{
    string injectToGeom()
    {
        import std.format : format;
        import std.traits;
        import std.string : toLower;
        string str = "auto toGeom(A)( A aes, string type ) {\nimport std.traits; import std.array : array;\n";
        foreach( name; __traits(allMembers, ggplotd.geom) )
        {
            static if (name.length > 6 && name[0..4] == "geom" 
                    && name != "geomType"
                    )
            {
                str ~= format( "static if(__traits(compiles,(A a) => %s(a))) {\nif (type == q{%s})\n\treturn %s!A(aes).array;\n}\n", name, name[4..$].toLower, name );
            }
        }

        str ~= "assert(0, q{Unknown type passed to geomType});\n}\n";
        return str;
    }

    /**
Draw any type of geom

The type field is required, which should be a string. Any of the geom* functions in ggplotd.geom 
can be passed using a lower case string minus the geom prefix, i.e. hist2d calls geomHist2D etc.
*/
    auto geomType( AES aes )
    {
        import std.algorithm : map, joiner;

        import ggplotd.aes : group;
        mixin(injectToGeom());

        return aes
            .group!"type"
            .map!((g) => toGeom(g, g[0].type)).joiner;
    }
}

///
unittest
{
    import std.range : walkLength;
    assertEqual(
            geomType(Aes!(double[], "x", double[], "y", string[], "type")
                ( [0.0,1,2], [5.0,6,7], ["line", "point", "line"] )).walkLength, 2
            );
}

/**
Draw rectangle centered at given x,y location

Aside from x and y also width and height are required.
If the type of width is of type Pixel (see aes.d) then dimensions are assumed to be in Pixel (not user coordinates).
*/
auto geomRectangle(AES)(AES aes)
{
    return geomShape!("rectangle", AES)(aes);
}

/**
Draw ellipse centered at given x,y location

Aside from x and y also width and height are required.
If the type of width is of type Pixel (see aes.d) then dimensions are assumed to be in Pixel (not user coordinates).
*/
auto geomEllipse(AES)(AES aes)
{
    return geomShape!("ellipse", AES)(aes);
}

/**
Draw triangle centered at given x,y location

Aside from x and y also width and height are required.
If the type of width is of type Pixel (see aes.d) then dimensions are assumed to be in Pixel (not user coordinates).
*/
auto geomTriangle(AES)(AES aes)
{
    return geomShape!("triangle", AES)(aes);
}

/**
Draw diamond centered at given x,y location

Aside from x and y also width and height are required.
If the type of width is of type Pixel (see aes.d) then dimensions are assumed to be in Pixel (not user coordinates).
*/
auto geomDiamond(AES)(AES aes)
{
    return geomShape!("diamond", AES)(aes);
}

/// Create points from the data
auto geomPoint(AES)(AES aes)
{
    import std.algorithm : map;
    import std.conv : to;
    import ggplotd.aes : Aes, Pixel;
    import ggplotd.range : mergeRange;
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
template geomLine(AES)
{
    import std.algorithm : map;
    import std.range : array, zip;

    import ggplotd.range : mergeRange;
 
    struct VolderMort 
    {
        this(AES aes)
        {
            groupedAes = DefaultValues.mergeRange(aes).group;
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
        typeof(group(DefaultValues.mergeRange(AES.init))) groupedAes;
    }

    auto geomLine(AES aes)
    {
        return VolderMort(aes);
    }
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

/// Draw histograms based on the x coordinates of the data
auto geomHist(AES)(AES aes, size_t noBins = 0)
{
    import ggplotd.stat : statHist;
    return geomRectangle( statHist( aes, noBins ) );
}

/** 
Draw histograms based on the x and y coordinates of the data
  
  Examples:
  --------------
    /// http://blackedder.github.io/ggplotd/images/hist2D.svg
     import std.array : array;
    import std.algorithm : map;
    import std.conv : to;
    import std.range : repeat, iota;
    import std.random : uniform;

    import ggplotd.aes : Aes;
    import ggplotd.colour : colourGradient;
    import ggplotd.colourspace : XYZ;
    import ggplotd.geom : geomHist2D;
    import ggplotd.ggplotd : GGPlotD;

    auto xs = iota(0,500,1).map!((x) => uniform(0.0,5)+uniform(0.0,5))
        .array;
    auto ys = iota(0,500,1).map!((y) => uniform(0.0,5)+uniform(0.0,5))
        .array;
    auto aes = Aes!(typeof(xs), "x", typeof(ys), "y")( xs, ys);
    auto gg = GGPlotD().put( geomHist2D( aes ) );
    // Use a different colour scheme
    gg.put( colourGradient!XYZ( "white-cornflowerBlue-crimson" ) );

    gg.save( "hist2D.svg" );
  --------------
*/
auto geomHist2D(AES)(AES aes, size_t noBinsX = 0, size_t noBinsY = 0)
{
    import std.algorithm : map, joiner;
    import ggplotd.stat : statHist2D;

    return statHist2D( aes, noBinsX, noBinsY )
            .map!( (poly) => geomPolygon( poly ) ).joiner;
}


/**
    Deprecated: superseded by geomHist2D
*/
deprecated alias geomHist3D = geomHist2D;

/// Draw axis, first and last location are start/finish
/// others are ticks (perpendicular)
auto geomAxis(AES)(AES aes, double tickLength, string label)
{
    import std.algorithm : find;
    import std.array : array;
    import std.range : chain, empty, repeat;
    import std.math : sqrt, pow;

    import ggplotd.range : mergeRange;

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
template geomLabel(AES)
{
    import std.algorithm : map;
    import ggplotd.aes : numericLabel;
    import ggplotd.range : mergeRange;
    alias CoordX = typeof(numericLabel(AES.init.map!("a.x")));
    alias CoordY = typeof(numericLabel(AES.init.map!("a.y")));
    alias CoordType = typeof(DefaultValues
        .mergeRange(AES.init)
        .mergeRange(Aes!(CoordX, "x", CoordY, "y").init));

    struct VolderMort
    {
        this(AES aes)
        {
            import std.algorithm : map;
            import ggplotd.range : mergeRange;
            _aes = DefaultValues
                .mergeRange(aes)
                .mergeRange( Aes!(CoordX, "x", CoordY, "y")(
                    CoordX(aes.map!("a.x")), 
                    CoordY(aes.map!("a.y"))));
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

    auto geomLabel(AES aes)
    {
        return VolderMort(aes);
    }
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
    import std.typecons : Tuple;
    import ggplotd.range : mergeRange;

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
            import std.range : repeat, walkLength;
            auto labels = numericLabel( repeat("a", aes.walkLength) );
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
    import ggplotd.range : mergeRange;

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

        context.lineWidth = 0.0;
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


/**
  Draw kernel density based on the x coordinates of the data

  Examples:
  --------------
    /// http://blackedder.github.io/ggplotd/images/filled_density.svg
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain;
    import std.random : uniform;

    import ggplotd.aes : Aes;
    import ggplotd.geom : geomDensity;
    import ggplotd.ggplotd : GGPlotD;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25));
    auto aes = Aes!(typeof(xs), "x", typeof(cols), "colour", 
        double[], "fill" )( 
            xs, cols, 0.45.repeat(xs.length).array);
    auto gg = GGPlotD().put( geomDensity( aes ) );
    gg.save( "filled_density.svg" );
  --------------
*/
auto geomDensity(AES)(AES aes)
{
    import ggplotd.stat : statDensity;
    return geomLine( statDensity( aes ) );
}

/**
  Draw kernel density based on the x and y coordinates of the data

  Examples:
  --------------
    /// http://blackedder.github.io/ggplotd/images/density2D.png
    import std.array : array;
    import std.algorithm : map;
    import std.conv : to;
    import std.range : repeat, iota;
    import std.random : uniform;

    import ggplotd.aes : Aes;
    import ggplotd.colour : colourGradient;
    import ggplotd.colourspace : XYZ;
    import ggplotd.geom : geomDensity2D;
    import ggplotd.ggplotd : GGPlotD;

    auto xs = iota(0,500,1).map!((x) => uniform(0.0,5)+uniform(0.0,5))
        .array;
    auto ys = iota(0,500,1).map!((y) => uniform(0.5,1.5)+uniform(0.5,1.5))
        .array;
    auto aes = Aes!(typeof(xs), "x", typeof(ys), "y")( xs, ys);
    auto gg = GGPlotD().put( geomDensity2D( aes ) );
    // Use a different colour scheme
    gg.put( colourGradient!XYZ( "white-cornflowerBlue-crimson" ) );

    gg.save( "density2D.png" );
  --------------
*/
auto geomDensity2D(AES)(AES aes) 
{
    import std.algorithm : map, joiner;
    import ggplotd.stat : statDensity2D;

    return statDensity2D( aes )
            .map!( (poly) => geomPolygon( poly ) ).joiner;
}
