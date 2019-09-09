module ggplotd.geom;

import std.range : front, popFront, empty;

import cairo = cairo.cairo;

import ggplotd.bounds;
import ggplotd.aes;

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
    import std.typecons : Nullable;

    /// Construct from a tuple
    this(T)( in T tup ) //if (is(T==Tuple))
    {
        import ggplotd.aes : hasAesField;
        static if (hasAesField!(T, "x"))
            xStore.put(tup.x);
        static if (hasAesField!(T, "y"))
            yStore.put(tup.y);
        static if (hasAesField!(T, "colour"))
            colourStore.put(tup.colour);
        static if (hasAesField!(T, "sizeStore"))
            sizeStore.put(tup.sizeStore);
        static if (hasAesField!(T, "mask"))
            mask = tup.mask;
    }

    import ggplotd.guide : GuideToColourFunction, GuideToDoubleFunction;
    /// Delegate that takes a context and draws to it
    alias drawFunction = cairo.Context delegate(cairo.Context context, 
        in GuideToDoubleFunction xFunc, in GuideToDoubleFunction yFunc,
        in GuideToColourFunction cFunc, in GuideToDoubleFunction sFunc);

    /// Function to draw to a cairo context
    Nullable!drawFunction draw; 

    import ggplotd.guide : GuideStore;
    GuideStore!"colour" colourStore;
    GuideStore!"x" xStore;
    GuideStore!"y" yStore;
    GuideStore!"size" sizeStore;

    /// Whether to mask/prevent drawing outside plotting area
    bool mask = true; 
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
    import ggplotd.range : mergeRange;
    alias CoordType = typeof(DefaultValues
        .mergeRange(AES.init));

    struct VolderMort 
    {
        this(AES aes)
        {
            import ggplotd.range : mergeRange;
            _aes = DefaultValues
                .mergeRange(aes);
        }

        @property auto front()
        {
            import ggplotd.guide : GuideToDoubleFunction, GuideToColourFunction;
            immutable tup = _aes.front;
            immutable f = delegate(cairo.Context context, 
                 in GuideToDoubleFunction xFunc, in GuideToDoubleFunction yFunc,
                 in GuideToColourFunction cFunc, in GuideToDoubleFunction sFunc ) {
                import std.math : isFinite;
                auto x = xFunc(tup.x, tup.fieldWithDefault!("scale")(true));
                auto y = yFunc(tup.y, tup.fieldWithDefault!("scale")(true));
                auto col = cFunc(tup.colour);
                if (!isFinite(x) || !isFinite(y))
                    return context;
                context.save();
                context.translate(x, y);
                import ggplotd.aes : hasAesField;
                static if (hasAesField!(typeof(tup), "sizeStore")) {
                    auto width = tup.width*sFunc(tup.sizeStore);
                    auto height = tup.height*sFunc(tup.sizeStore);
                } else  {
                    auto width = tup.width;
                    auto height = tup.height;
                }

                static if (is(typeof(tup.width)==immutable(Pixel)))
                    auto devP = context.deviceToUserDistance(cairo.Point!double( width, height )); //tup.width.to!double, tup.width.to!double ));
                context.rotate(tup.angle);
                static if (shape=="ellipse")
                {
                    import std.math : PI;
                    static if (is(typeof(tup.width)==immutable(Pixel)))
                    {
                        context.scale( devP.x/2.0, devP.y/2.0 );
                    } else {
                        context.scale( width/2.0, height/2.0 );
                    }
                    context.arc(0,0, 1.0, 0,2*PI);
                } else {
                    static if (is(typeof(tup.width)==immutable(Pixel)))
                    {
                        context.scale( devP.x, devP.y );
                    } else {
                        context.scale( width, height );
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

                context.restore();
                context.fillAndStroke( col, tup.fill, tup.alpha );
                return context;
            };

            auto geom = Geom( tup );
            geom.draw = f;

            static if (!is(typeof(tup.width)==immutable(Pixel))) 
            {
                geom.xStore.put(tup.x, 0.5*tup.width);
                geom.xStore.put(tup.x, -0.5*tup.width);
            }
            static if (!is(typeof(tup.height)==immutable(Pixel))) 
            {
                geom.yStore.put(tup.y, 0.5*tup.height);
                geom.yStore.put(tup.y, -0.5*tup.height);
            }

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
    import std.range : walkLength, zip;
    import std.algorithm : map;

    import ggplotd.aes : aes;
    auto aesRange = zip([1.0, 2.0], [3.0, 4.0], [1.0,1], [2.0,2])
        .map!((a) => aes!("x", "y", "width", "height")( a[0], a[1], a[2], a[3]));
    auto geoms = geomShape!("rectangle")(aesRange);

    assertEqual(geoms.walkLength, 2);
    assertEqual(geoms.front.xStore.min, 0.5);
    assertEqual(geoms.front.xStore.max, 1.5);
    geoms.popFront;
    assertEqual(geoms.front.xStore.max, 2.5);
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
auto geomPoint(AES)(AES aesRange)
{
    import std.algorithm : map;
    import ggplotd.aes : aes, Pixel;
    import ggplotd.range : mergeRange;
    return DefaultValues
        .mergeRange(aesRange)
        .map!((a) => a.merge(aes!("sizeStore", "width", "height", "fill")
            (a.size, Pixel(8), Pixel(8), a.alpha)))
        .geomEllipse;
}

///
unittest
{
    auto aes = Aes!(double[], "x", double[], "y")([1.0], [2.0]);
    auto gl = geomPoint(aes);
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
            import ggplotd.aes : aes;
            import ggplotd.guide : GuideToColourFunction, GuideToDoubleFunction;
            auto coordsZip = groupedAes.front
                .map!((a) => aes!("x","y")(a.x, a.y));

            immutable flags = groupedAes.front.front;
            immutable f = delegate(cairo.Context context, 
                 in GuideToDoubleFunction xFunc, in GuideToDoubleFunction yFunc,
                 in GuideToColourFunction cFunc, in GuideToDoubleFunction sFunc ) {

                import std.math : isFinite;
                auto coords = coordsZip.save;
                auto fr = coords.front;
                context.moveTo(
                    xFunc(fr.x, flags.fieldWithDefault!("scale")(true)), 
                    yFunc(fr.y, flags.fieldWithDefault!("scale")(true)));
                coords.popFront;
                foreach (tup; coords)
                {
                    auto x = xFunc(tup.x, flags.fieldWithDefault!("scale")(true));
                    auto y = yFunc(tup.y, flags.fieldWithDefault!("scale")(true));
                    // TODO should we actually move to next coordinate here?
                    if (isFinite(x) && isFinite(y))
                    {
                        context.lineTo(x, y);
                        context.lineWidth = 2.0*flags.size;
                    } else {
                        context.newSubPath();
                    }
                }

                auto col = cFunc(flags.colour);
                context.fillAndStroke( col, flags.fill, flags.alpha );
                return context;
            };


            auto geom = Geom(groupedAes.front.front);
            foreach (tup; coordsZip)
            {
                geom.xStore.put(tup.x);
                geom.yStore.put(tup.y);
            }
            geom.draw = f;
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

    assertHasValue([1.0, 2.0], gl.front.xStore.min());
    assertHasValue([1.1, 3.0], gl.front.xStore.max());
    gl.popFront;
    assertHasValue([1.1, 3.0], gl.front.xStore.max());
    gl.popFront;
    assert(gl.empty);
}

unittest
{
    auto aes = Aes!(string[], "x", string[], "y", string[], "colour")(["a",
        "b", "c", "b"], ["a", "b", "b", "a"], ["b", "b", "b", "b"]);

    auto gl = geomLine(aes);
    assertEqual(gl.front.xStore.store.length, 3);
    assertEqual(gl.front.yStore.store.length, 2);
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
auto geomAxis(AES)(AES aesRaw, double tickLength, string label, 
		double labelAngle)
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

    auto merged = DefaultValues.mergeRange(aesRaw);

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

            lxs ~= tick.x - 1.3*direction[1];
            lys ~= tick.y - 1.3*direction[0];
            lbls ~= tick.label;
            langles ~= tick.angle;
        }
    }

    // Main label
    auto xm = xs[0] + 0.5*(xs[$-1]-xs[0]) - 4.0*direction[1];
    auto ym = ys[0] + 0.5*(ys[$-1]-ys[0]) - 4.0*direction[0];
    auto aesM = Aes!(double[], "x", double[], "y", string[], "label", 
        double[], "angle", bool[], "mask", bool[], "scale", 
		)( [xm], [ym], [label], langles, [false], [false]);

    import std.algorithm : map;
    import std.range : zip;
    return xs.zip(ys).map!((a) => aes!("x", "y", "mask", "scale")
        (a[0], a[1], false, false)).geomLine()
        .chain( 
          lxs.zip(lys, lbls, langles)
            .map!((a) => 
                aes!("x", "y", "label", "labelAngle", "angle", "mask", "size", "scale")
                    (a[0], a[1], a[2], a[3], labelAngle, false, aesRaw.front.size, false ))
            .geomLabel
        )
        .chain( geomLabel(aesM) );
}

/**
    Draw Label at given x and y position

    You can specify justification, by passing a justify field in the passed data (aes).
       $(UL
        $(LI "center" (default))
        $(LI "left")
        $(LI "right")
        $(LI "bottom")
        $(LI "top"))
*/
template geomLabel(AES)
{
    import std.algorithm : map;
    import std.typecons : Tuple;
    import ggplotd.range : mergeRange;
    alias CoordType = typeof(DefaultValues
        .merge(Tuple!(string, "justify").init)
        .mergeRange(AES.init));

    struct VolderMort
    {
        this(AES aes)
        {
            import std.algorithm : map;
            import ggplotd.range : mergeRange;

            _aes = DefaultValues
                .merge(Tuple!(string, "justify")("center"))
                .mergeRange(aes);
        }

        @property auto front()
        {
            import ggplotd.guide : GuideToDoubleFunction, GuideToColourFunction;
            immutable tup = _aes.front;
            immutable f = delegate(cairo.Context context, 
                 in GuideToDoubleFunction xFunc, in GuideToDoubleFunction yFunc,
                 in GuideToColourFunction cFunc, in GuideToDoubleFunction sFunc ) {
                auto x = xFunc(tup.x, tup.fieldWithDefault!("scale")(true));
                auto y = yFunc(tup.y, tup.fieldWithDefault!("scale")(true));
                auto col = cFunc(tup.colour);
                import std.math : ceil, isFinite;
                if (!isFinite(x) || !isFinite(y))
                    return context;
                context.setFontSize(ceil(14.0*tup.size));
                context.moveTo(x, y);
                context.save();
                context.identityMatrix;
                context.rotate(tup.angle);
                auto extents = context.textExtents(tup.label);
                auto textSize = cairo.Point!double(extents.width, extents.height);
                // Justify
                if (tup.justify == "left")
                    context.relMoveTo(0, 0.5*textSize.y);
                else if (tup.justify == "right")
                    context.relMoveTo(-textSize.x, 0.5*textSize.y);
                else if (tup.justify == "bottom")
                    context.relMoveTo(-0.5*textSize.x, 0);
                else if (tup.justify == "top")
                    context.relMoveTo(-0.5*textSize.x, textSize.y);
                else
                    context.relMoveTo(-0.5*textSize.x, 0.5*textSize.y);

                import ggplotd.colourspace : RGBA, toCairoRGBA;

                context.setSourceRGBA(
                    RGBA(col.r, col.g, col.b, tup.alpha)
                        .toCairoRGBA
                );
 
				auto labelAngle = tup.fieldWithDefault!("labelAngle")(0.0);
                context.rotate(labelAngle);
                context.showText(tup.label);
                context.rotate(-labelAngle);
                context.restore();
                return context;
            };

            auto geom = Geom( tup );
            geom.draw = f;
 
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
auto geomBox(AES)(AES aesRange)
{
    import std.algorithm : filter, map;
    import std.array : array;
    import std.range : Appender, walkLength, ElementType;
    import std.typecons : Tuple;
    import ggplotd.aes : aes, hasAesField;
    import ggplotd.range : mergeRange;

    Appender!(Geom[]) result;

    // If has y, use that
    static if (hasAesField!(ElementType!AES, "y"))
    {
        auto myAes = aesRange.map!((a) => a.merge(aes!("label")(a.y)));
    } else {
        static if (!hasAesField!(ElementType!AES, "label"))
        {
            import std.range : repeat, walkLength;
            auto myAes = aesRange.map!((a) => a.merge(aes!("label")(0.0)));
        } else {
            auto myAes = aesRange;
        }
    }
    
    // TODO if x (y in the original aesRange) is numerical then this should relly scale 
    // by the range
    double delta = 0.2;

    foreach( grouped; myAes.group().filter!((a) => a.walkLength > 3) )
    {
        auto lims = grouped.map!("a.x.to!double")
            .array.limits( [0.1,0.25,0.5,0.75,0.9] ).array;
        auto x = grouped.front.label;
        result.put(
            [grouped.front.merge(aes!("x", "y", "width", "height")
                (x, (lims[2]+lims[1])/2.0, 2*delta, lims[2]-lims[1])),
             grouped.front.merge(aes!("x", "y", "width", "height")
                (x, (lims[3]+lims[2])/2.0, 2*delta, lims[3]-lims[2]))
            ].geomRectangle
        );

        result.put(
            [grouped.front.merge(aes!("x", "y")(x,lims[0])),
                grouped.front.merge(aes!("x", "y")(x,lims[1]))].geomLine);
        result.put(
            [grouped.front.merge(aes!("x", "y")(x,lims[3])),
                grouped.front.merge(aes!("x", "y")(x,lims[4]))].geomLine);

        // Increase plot bounds
        result.data.front.xStore.put(x, 2*delta);
        result.data.front.xStore.put(x, -2*delta);
    }

    return result.data;
}

///
unittest 
{
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain, zip;
    import std.random : uniform;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25)).array;
    auto aesRange = zip(xs, cols)
        .map!((a) => aes!("x", "colour", "fill", "label")(a[0], a[1], 0.45, a[1]));
    auto gb = geomBox( aesRange );
    assertEqual( gb.front.xStore.min(), -0.4 );
}

unittest 
{
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain, zip;
    import std.random : uniform;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25)).array;
    auto ys = 2.repeat(25).chain(3.repeat(25)).array;
    auto aesRange = zip(xs, cols, ys)
        .map!((a) => aes!("x", "colour", "fill", "y")(a[0], a[1], .45, a[2]));
    auto gb = geomBox( aesRange );
    assertEqual( gb.front.xStore.min, 1.6 );
}

unittest 
{
    // Test when passing one data point
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain;
    import std.random : uniform;
    auto xs = iota(0,1,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(1).array;
    auto ys = 2.repeat(1).array;
    auto aes = Aes!(typeof(xs), "x", typeof(cols), "colour", 
        double[], "fill", typeof(ys), "y" )( 
            xs, cols, 0.45.repeat(xs.length).array, ys);
    auto gb = geomBox( aes );
    assertEqual( gb.length, 0 );
}

unittest 
{
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain, zip;
    import std.random : uniform;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25)).array;
    auto aesRange = zip(xs, cols)
        .map!((a) => aes!("x", "colour", "fill")(a[0], a[1], .45));
    auto gb = geomBox( aesRange );
    assertEqual( gb.front.xStore.min, -0.4 );
}

/// Draw a polygon 
auto geomPolygon(AES)(AES aes)
{
    // TODO would be nice to allow grouping of triangles
    import std.array : array;
    import std.algorithm : map, swap;
    import std.conv : to;
    import ggplotd.geometry : gradientVector, Vertex3D;
    import ggplotd.range : mergeRange;

    auto merged = DefaultValues.mergeRange(aes);

    immutable flags = merged.front;

    auto geom = Geom( flags );

    foreach(tup; merged)
    {
        geom.xStore.put(tup.x);
        geom.yStore.put(tup.y);
        geom.colourStore.put(tup.colour);
    }

    import ggplotd.guide : GuideToDoubleFunction, GuideToColourFunction;
    // Define drawFunction
    immutable f = delegate(cairo.Context context, 
         in GuideToDoubleFunction xFunc, in GuideToDoubleFunction yFunc,
         in GuideToColourFunction cFunc, in GuideToDoubleFunction sFunc ) 
    {
        // Turn into vertices.
        auto vertices = merged.map!((t) => Vertex3D( 
            xFunc(t.x, flags.fieldWithDefault!"scale"(true)),
            yFunc(t.y, flags.fieldWithDefault!"scale"(true)), 
            cFunc.toDouble(t.colour)));

            // Find lowest, highest
        auto triangle = vertices.array;
        if (triangle[1].z < triangle[0].z)
            swap( triangle[1], triangle[0] );
        if (triangle[2].z < triangle[0].z)
            swap( triangle[2], triangle[0] );
        if (triangle[1].z > triangle[2].z)
            swap( triangle[1], triangle[2] );

        if (triangle.length > 3) 
        { 
            foreach( v; triangle[3..$] )
            {
                if (v.z < triangle[0].z)
                    swap( triangle[0], v );
                else if ( v.z > triangle[2].z )
                    swap( triangle[2], v );
            }
        }
        auto gV = gradientVector( triangle[0..3] );

        auto gradient = new cairo.LinearGradient( gV[0].x, gV[0].y, 
            gV[1].x, gV[1].y );

        context.lineWidth = 0.0;

        /*
            We add a number of stops to the gradient. Optimally we should only add the top
            and bottom, but this is not possible for two reasons. First of all we support
            other colour spaces than rgba, while cairo only support rgba. We _simulate_ 
            the other colourspace in RGBA by taking small steps in the rgba colourspace.
            Secondly to support multiple colour stops in our own colourgradient we need to 
            add all those.

            The ideal way to solve the second problem would be by using the colourGradient
            stops here, but that wouldn't solve the first issue, so we go for the stupider
            solution here.

            Ideally we would see how cairo does their colourgradient and implement the same
            for other colourspaces.
i       */
        auto no_stops = 10.0; import std.range : iota;
        import std.array : array;
        auto stepsize = (gV[1].z - gV[0].z)/no_stops;
        auto steps = [gV[0].z, gV[1].z];
        if (stepsize > 0)
            steps = iota(gV[0].z, gV[1].z, stepsize).array ~ gV[1].z;

        foreach(i, z; steps) {
            auto col = cFunc(z);
            import ggplotd.colourspace : RGBA, toCairoRGBA;
            gradient.addColorStopRGBA(i/(steps.length-1.0),
                RGBA(col.r, col.g, col.b, flags.alpha).toCairoRGBA
            );
        }

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
    import ggplotd.legend : discreteLegend;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25));
    auto aes = Aes!(typeof(xs), "x", typeof(cols), "colour", 
        double[], "fill" )( 
            xs, cols, 0.45.repeat(xs.length).array);
    auto gg = GGPlotD().put( geomDensity( aes ) );
    gg.put(discreteLegend);
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
    import ggplotd.legend : continuousLegend;

    auto xs = iota(0,500,1).map!((x) => uniform(0.0,5)+uniform(0.0,5))
        .array;
    auto ys = iota(0,500,1).map!((y) => uniform(0.5,1.5)+uniform(0.5,1.5))
        .array;
    auto aes = Aes!(typeof(xs), "x", typeof(ys), "y")( xs, ys);
    auto gg = GGPlotD().put( geomDensity2D( aes ) );
    // Use a different colour scheme
    gg.put( colourGradient!XYZ( "white-cornflowerBlue-crimson" ) );
    gg.put(continuousLegend);

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
