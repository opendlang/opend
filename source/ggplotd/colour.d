/**
Deal with colour related struct/functions, such as ColourSpaces etc.
*/
module ggplotd.colour;

import std.range : ElementType;
import std.typecons : Tuple;

import ggplotd.colourspace : RGBA;

version (unittest)
{
    import dunit.toolkit;
}

/++
    Returns an associative array with names as key and colours as values

    Set of colors defined by X11, adopted by the W3C, SVG, and other popular libraries.
    +/
auto createNamedColours()
{
    RGBA[string] nameMap;
    nameMap["none"] = RGBA(0, 0, 0, 0);
    nameMap["aliceBlue"] = RGBA(0.941176,0.972549,1.0,1);
    nameMap["antiqueWhite"] = RGBA(0.980392,0.921569,0.843137,1);
    nameMap["aqua"] = RGBA(0.0,1.0,1.0,1);
    nameMap["aquamarine"] = RGBA(0.498039,1.0,0.831373,1);
    nameMap["azure"] = RGBA(0.941176,1.0,1.0,1);
    nameMap["beige"] = RGBA(0.960784,0.960784,0.862745,1);
    nameMap["bisque"] = RGBA(1.0,0.894118,0.768627,1);
    nameMap["black"] = RGBA(0.0,0.0,0.0,1);
    nameMap["blanchedAlmond"] = RGBA(1.0,0.921569,0.803922,1);
    nameMap["blue"] = RGBA(0.0,0.0,1.0,1);
    nameMap["blueViolet"] = RGBA(0.541176,0.168627,0.886275,1);
    nameMap["brown"] = RGBA(0.647059,0.164706,0.164706,1);
    nameMap["burlyWood"] = RGBA(0.870588,0.721569,0.529412,1);
    nameMap["cadetBlue"] = RGBA(0.372549,0.619608,0.627451,1);
    nameMap["chartreuse"] = RGBA(0.498039,1.0,0.0,1);
    nameMap["chocolate"] = RGBA(0.823529,0.411765,0.117647,1);
    nameMap["coral"] = RGBA(1.0,0.498039,0.313725,1);
    nameMap["cornflowerBlue"] = RGBA(0.392157,0.584314,0.929412,1);
    nameMap["cornsilk"] = RGBA(1.0,0.972549,0.862745,1);
    nameMap["crimson"] = RGBA(0.862745,0.078431,0.235294,1);
    nameMap["cyan"] = RGBA(0.0,1.0,1.0,1);
    nameMap["darkBlue"] = RGBA(0.0,0.0,0.545098,1);
    nameMap["darkCyan"] = RGBA(0.0,0.545098,0.545098,1);
    nameMap["darkGoldenrod"] = RGBA(0.721569,0.52549,0.043137,1);
    nameMap["darkGray"] = RGBA(0.662745,0.662745,0.662745,1);
    nameMap["darkGrey"] = RGBA(0.662745,0.662745,0.662745,1);
    nameMap["darkGreen"] = RGBA(0.0,0.392157,0.0,1);
    nameMap["darkKhaki"] = RGBA(0.741176,0.717647,0.419608,1);
    nameMap["darkMagenta"] = RGBA(0.545098,0.0,0.545098,1);
    nameMap["darkOliveGreen"] = RGBA(0.333333,0.419608,0.184314,1);
    nameMap["darkOrange"] = RGBA(1.0,0.54902,0.0,1);
    nameMap["darkOrchid"] = RGBA(0.6,0.196078,0.8,1);
    nameMap["darkRed"] = RGBA(0.545098,0.0,0.0,1);
    nameMap["darkSalmon"] = RGBA(0.913725,0.588235,0.478431,1);
    nameMap["darkSeaGreen"] = RGBA(0.560784,0.737255,0.560784,1);
    nameMap["darkSlateBlue"] = RGBA(0.282353,0.239216,0.545098,1);
    nameMap["darkSlateGray"] = RGBA(0.184314,0.309804,0.309804,1);
    nameMap["darkSlateGrey"] = RGBA(0.184314,0.309804,0.309804,1);
    nameMap["darkTurquoise"] = RGBA(0.0,0.807843,0.819608,1);
    nameMap["darkViolet"] = RGBA(0.580392,0.0,0.827451,1);
    nameMap["deepPink"] = RGBA(1.0,0.078431,0.576471,1);
    nameMap["deepSkyBlue"] = RGBA(0.0,0.74902,1.0,1);
    nameMap["dimGray"] = RGBA(0.411765,0.411765,0.411765,1);
    nameMap["dimGrey"] = RGBA(0.411765,0.411765,0.411765,1);
    nameMap["dodgerBlue"] = RGBA(0.117647,0.564706,1.0,1);
    nameMap["fireBrick"] = RGBA(0.698039,0.133333,0.133333,1);
    nameMap["floralWhite"] = RGBA(1.0,0.980392,0.941176,1);
    nameMap["forestGreen"] = RGBA(0.133333,0.545098,0.133333,1);
    nameMap["fuchsia"] = RGBA(1.0,0.0,1.0,1);
    nameMap["gainsboro"] = RGBA(0.862745,0.862745,0.862745,1);
    nameMap["ghostWhite"] = RGBA(0.972549,0.972549,1.0,1);
    nameMap["gold"] = RGBA(1.0,0.843137,0.0,1);
    nameMap["goldenrod"] = RGBA(0.854902,0.647059,0.12549,1);
    nameMap["gray"] = RGBA(0.501961,0.501961,0.501961,1);
    nameMap["grey"] = RGBA(0.501961,0.501961,0.501961,1);
    nameMap["green"] = RGBA(0.0,0.501961,0.0,1);
    nameMap["greenYellow"] = RGBA(0.678431,1.0,0.184314,1);
    nameMap["honeydew"] = RGBA(0.941176,1.0,0.941176,1);
    nameMap["hotPink"] = RGBA(1.0,0.411765,0.705882,1);
    nameMap["indianRed"] = RGBA(0.803922,0.360784,0.360784,1);
    nameMap["indigo"] = RGBA(0.294118,0.0,0.509804,1);
    nameMap["ivory"] = RGBA(1.0,1.0,0.941176,1);
    nameMap["khaki"] = RGBA(0.941176,0.901961,0.54902,1);
    nameMap["lavender"] = RGBA(0.901961,0.901961,0.980392,1);
    nameMap["lavenderBlush"] = RGBA(1.0,0.941176,0.960784,1);
    nameMap["lawnGreen"] = RGBA(0.486275,0.988235,0.0,1);
    nameMap["lemonChiffon"] = RGBA(1.0,0.980392,0.803922,1);
    nameMap["lightBlue"] = RGBA(0.678431,0.847059,0.901961,1);
    nameMap["lightCoral"] = RGBA(0.941176,0.501961,0.501961,1);
    nameMap["lightCyan"] = RGBA(0.878431,1.0,1.0,1);
    nameMap["lightGoldenrodYellow"] = RGBA(0.980392,0.980392,0.823529,1);
    nameMap["lightGray"] = RGBA(0.827451,0.827451,0.827451,1);
    nameMap["lightGrey"] = RGBA(0.827451,0.827451,0.827451,1);
    nameMap["lightGreen"] = RGBA(0.564706,0.933333,0.564706,1);
    nameMap["lightPink"] = RGBA(1.0,0.713725,0.756863,1);
    nameMap["lightSalmon"] = RGBA(1.0,0.627451,0.478431,1);
    nameMap["lightSeaGreen"] = RGBA(0.12549,0.698039,0.666667,1);
    nameMap["lightSkyBlue"] = RGBA(0.529412,0.807843,0.980392,1);
    nameMap["lightSlateGray"] = RGBA(0.466667,0.533333,0.6,1);
    nameMap["lightSlateGrey"] = RGBA(0.466667,0.533333,0.6,1);
    nameMap["lightSteelBlue"] = RGBA(0.690196,0.768627,0.870588,1);
    nameMap["lightYellow"] = RGBA(1.0,1.0,0.878431,1);
    nameMap["lime"] = RGBA(0.0,1.0,0.0,1);
    nameMap["limeGreen"] = RGBA(0.196078,0.803922,0.196078,1);
    nameMap["linen"] = RGBA(0.980392,0.941176,0.901961,1);
    nameMap["magenta"] = RGBA(1.0,0.0,1.0,1);
    nameMap["maroon"] = RGBA(0.501961,0.0,0.0,1);
    nameMap["mediumAquamarine"] = RGBA(0.4,0.803922,0.666667,1);
    nameMap["mediumBlue"] = RGBA(0.0,0.0,0.803922,1);
    nameMap["mediumOrchid"] = RGBA(0.729412,0.333333,0.827451,1);
    nameMap["mediumPurple"] = RGBA(0.576471,0.439216,0.858824,1);
    nameMap["mediumSeaGreen"] = RGBA(0.235294,0.701961,0.443137,1);
    nameMap["mediumSlateBlue"] = RGBA(0.482353,0.407843,0.933333,1);
    nameMap["mediumSpringGreen"] = RGBA(0.0,0.980392,0.603922,1);
    nameMap["mediumTurquoise"] = RGBA(0.282353,0.819608,0.8,1);
    nameMap["mediumVioletRed"] = RGBA(0.780392,0.082353,0.521569,1);
    nameMap["midnightBlue"] = RGBA(0.098039,0.098039,0.439216,1);
    nameMap["mintCream"] = RGBA(0.960784,1.0,0.980392,1);
    nameMap["mistyRose"] = RGBA(1.0,0.894118,0.882353,1);
    nameMap["moccasin"] = RGBA(1.0,0.894118,0.709804,1);
    nameMap["navajoWhite"] = RGBA(1.0,0.870588,0.678431,1);
    nameMap["navy"] = RGBA(0.0,0.0,0.501961,1);
    nameMap["oldLace"] = RGBA(0.992157,0.960784,0.901961,1);
    nameMap["olive"] = RGBA(0.501961,0.501961,0.0,1);
    nameMap["oliveDrab"] = RGBA(0.419608,0.556863,0.137255,1);
    nameMap["orange"] = RGBA(1.0,0.647059,0.0,1);
    nameMap["orangeRed"] = RGBA(1.0,0.270588,0.0,1);
    nameMap["orchid"] = RGBA(0.854902,0.439216,0.839216,1);
    nameMap["paleGoldenrod"] = RGBA(0.933333,0.909804,0.666667,1);
    nameMap["paleGreen"] = RGBA(0.596078,0.984314,0.596078,1);
    nameMap["paleTurquoise"] = RGBA(0.686275,0.933333,0.933333,1);
    nameMap["paleVioletRed"] = RGBA(0.858824,0.439216,0.576471,1);
    nameMap["papayaWhip"] = RGBA(1.0,0.937255,0.835294,1);
    nameMap["peachPuff"] = RGBA(1.0,0.854902,0.72549,1);
    nameMap["peru"] = RGBA(0.803922,0.521569,0.247059,1);
    nameMap["pink"] = RGBA(1.0,0.752941,0.796078,1);
    nameMap["plum"] = RGBA(0.866667,0.627451,0.866667,1);
    nameMap["powderBlue"] = RGBA(0.690196,0.878431,0.901961,1);
    nameMap["purple"] = RGBA(0.501961,0.0,0.501961,1);
    nameMap["red"] = RGBA(1.0,0.0,0.0,1);
    nameMap["rosyBrown"] = RGBA(0.737255,0.560784,0.560784,1);
    nameMap["royalBlue"] = RGBA(0.254902,0.411765,0.882353,1);
    nameMap["saddleBrown"] = RGBA(0.545098,0.270588,0.07451,1);
    nameMap["salmon"] = RGBA(0.980392,0.501961,0.447059,1);
    nameMap["sandyBrown"] = RGBA(0.956863,0.643137,0.376471,1);
    nameMap["seaGreen"] = RGBA(0.180392,0.545098,0.341176,1);
    nameMap["seashell"] = RGBA(1.0,0.960784,0.933333,1);
    nameMap["sienna"] = RGBA(0.627451,0.321569,0.176471,1);
    nameMap["silver"] = RGBA(0.752941,0.752941,0.752941,1);
    nameMap["skyBlue"] = RGBA(0.529412,0.807843,0.921569,1);
    nameMap["slateBlue"] = RGBA(0.415686,0.352941,0.803922,1);
    nameMap["slateGray"] = RGBA(0.439216,0.501961,0.564706,1);
    nameMap["slateGrey"] = RGBA(0.439216,0.501961,0.564706,1);
    nameMap["snow"] = RGBA(1.0,0.980392,0.980392,1);
    nameMap["springGreen"] = RGBA(0.0,1.0,0.498039,1);
    nameMap["steelBlue"] = RGBA(0.27451,0.509804,0.705882,1);
    nameMap["tan"] = RGBA(0.823529,0.705882,0.54902,1);
    nameMap["teal"] = RGBA(0.0,0.501961,0.501961,1);
    nameMap["thistle"] = RGBA(0.847059,0.74902,0.847059,1);
    nameMap["tomato"] = RGBA(1.0,0.388235,0.278431,1);
    nameMap["turquoise"] = RGBA(0.25098,0.878431,0.815686,1);
    nameMap["violet"] = RGBA(0.933333,0.509804,0.933333,1);
    nameMap["wheat"] = RGBA(0.960784,0.870588,0.701961,1);
    nameMap["white"] = RGBA(1.0,1.0,1.0,1);
    nameMap["whiteSmoke"] = RGBA(0.960784,0.960784,0.960784,1);
    nameMap["yellow"] = RGBA(1.0,1.0,0.0,1);
    nameMap["yellowGreen"] = RGBA(0.603922,0.803922,0.196078,1);
    return nameMap;
}

/// Converts any type into a double string pair, which is used by colour maps
struct ColourID
{
    import std.typecons : Tuple;

    /// Construct ColourID from different value
    this(T)(in T setId)
    {
        import std.math : isNumeric;
        import std.conv : to;

        import ggplotd.colourspace : isColour, toColourSpace;

        state[2] = RGBA(-1,-1,-1,-1);

        static if (isNumeric!T)
        {
            state[0] = setId.to!double;
        } else
          static if (isColour!T)
            state[2] = setId.toColourSpace!(RGBA,T);
          else
            state[1] = setId.to!string;
    }

    /// Initialize using rgba colour
    this( double r, double g, double b, double a = 1 )
    {
        state[2] = RGBA( r, g, b, a );
    }

    /// Internal representation of ColourID
    Tuple!(double, string, RGBA) state; 

    T to(T)() const
    {
        import std.conv : to;
        static if (is(T==double))
            return state[0];
        else {
            static if (is(T==RGBA))
                return state[2];
            else
                return state[1].to!T;
        }
    }

    alias state this; ///
}

unittest
{
    import std.math : isNaN;
    import std.range : empty;
    import ggplotd.colourspace : RGB;

    auto cID = ColourID("a");
    assert(isNaN(cID[0]));
    assertEqual(cID[1], "a");
    auto numID = ColourID(0);
    assertEqual(numID[0], 0);
    assert(numID[1].empty);
    assertEqual( numID[2].r, -1 );

    cID = ColourID(RGBA(0,0,0,0));
    assertEqual( cID[2].r, 0 );

    cID = ColourID(RGB(1,1,1));
    assertEqual( cID[2].r, 1 );
}

import std.range : ElementType, isInputRange;

/// Convert any range to a range return ColourIDs
struct ColourIDRange(T) if (isInputRange!T && is(ElementType!T == ColourID))
{
    /// Wrap the given range into colourIDRange
    this(T range)
    {
        original = range;
        namedColours = createNamedColours();
    }

    /// The front of the range
    @property auto front()
    {
        import std.range : front;
        import std.math : isNaN;

        if (!isNaN(original.front[0]) || original.front[1] in namedColours)
            return original.front;
        else if (original.front[1] !in labelMap)
        {
            import std.conv : to;

            labelMap[original.front[1]] = labelMap.length.to!double;
        }
        original.front[0] = labelMap[original.front[1]];
        return original.front;
    }

    /// pop the front of the range
    void popFront()
    {
        import std.range : popFront;

        original.popFront;
    }

    /// Is the range empty?
    @property bool empty()
    {
        import std.range : empty;

        return original.empty;
    }

    /// Save the range
    @property auto save()
    {
        return this;
    }

private:
    double[string] labelMap;
    T original;
    RGBA[string] namedColours;
}

unittest
{
    import std.math : isNaN;

    auto ids = [ColourID("black"), ColourID(-1), ColourID("a"), ColourID("b"), ColourID("a")];
    auto cids = ColourIDRange!(typeof(ids))(ids);

    assertEqual(cids.front[1], "black");
    assert(isNaN(cids.front[0]));
    cids.popFront;
    assertEqual(cids.front[1], "");
    assertEqual(cids.front[0], -1);
    cids.popFront;
    assertEqual(cids.front[1], "a");
    assertEqual(cids.front[0], 0);
    cids.popFront;
    assertEqual(cids.front[1], "b");
    assertEqual(cids.front[0], 1);
    cids.popFront;
    assertEqual(cids.front[1], "a");
    assertEqual(cids.front[0], 0);
}

alias ColourMap = RGBA delegate(ColourID tup);

///
auto createColourMap(R)(R colourIDs, ColourGradientFunction gradient) if (is(ElementType!R == Tuple!(double,
        string)) || is(ElementType!R == ColourID))
{
    import std.algorithm : filter, map, reduce;
    import std.math : isNaN;
    import std.array : array;
    import std.typecons : Tuple;

    import ggplotd.colourspace : toCairoRGBA;

    auto validatedIDs = ColourIDRange!R(colourIDs);

    auto minmax = Tuple!(double, double)(0, 0);
    if (!validatedIDs.empty) {
        import ggplotd.algorithm : safeMax, safeMin;
        minmax = validatedIDs.save
            .map!((a) => a[0]).reduce!((a, b) => safeMin(a,
            b), (a, b) => safeMax(a, b));
    }

    auto namedColours = createNamedColours;
    import std.algorithm : find;

    return (ColourID tup) {
        if (tup[2].r >= 0)
            return tup[2];
        else if (tup[1] in namedColours)
            return namedColours[tup[1]];
        else if (isNaN(tup[0])) 
        {
            return gradient((validatedIDs.find!("a[1] == b")(tup[1]).front)[0], 
                minmax[0], minmax[1]);
        }
        return gradient(tup[0], minmax[0], minmax[1]);
    };
}

unittest
{
    import std.typecons : Tuple;
    import std.array : array;
    import std.range : iota;
    import std.algorithm : map;

    import ggplotd.colourspace : HCY, toCairoRGBA;

    auto dc = colourGradient!HCY("");

    assertFalse(
        createColourMap([ColourID("a"), ColourID("b")], dc )(ColourID("a")) 
         == createColourMap([ColourID("a"), ColourID("b")], dc )(
            ColourID("b"))
    );

    assertEqual(createColourMap([ColourID("a"), ColourID("b")], 
        dc )(ColourID("black")),
            RGBA(0, 0, 0, 1));

    assertEqual(createColourMap([ColourID("black")], dc)(ColourID("black")), 
        RGBA(0, 0, 0, 1));

    auto cM = iota(0.0,8.0,1.0).map!((a) => ColourID(a)).
            createColourMap(dc);
    assert( cM( ColourID(0) ) != cM( ColourID(1) ) );
    assertEqual( cM( ColourID(0) ), cM( ColourID(0) ) );
}

struct ColourGradient(C)
{
    import ggplotd.colourspace : toColourSpace;
    void put( in double value, in C colour)
    {
        import std.range : back, empty;
        if (!stops.data.empty)
            assert( value > stops.data.back[0], 
                "Stops must be added in increasing value" );
        stops.put( Tuple!(double, C)( value, colour ) );
    }

    void put( in double value, string name )
    {
        auto rgb = createNamedColours[name];
        auto colour = toColourSpace!C( rgb );
        this.put( value, colour );
    }

    /**
        To find the interval within which a value falls
    
        If value to high or low return respectively the highest two or lowest two
    */
    auto interval( in double value ) const
    {
        import std.algorithm : findSplitBefore;
        import std.range : empty, front, back;
        assert(stops.data.length > 1, "Need at least two stops");
        // Split stops around it. If one empty take two from other and warn value
        // outside of coverage (debug), else take back and front from splitted
        auto splitted = stops.data.findSplitBefore!"a[0]>b"([value]);

        if (splitted[0].empty)
            return stops.data[0..2];
        else if (splitted[1].empty)
            return stops.data[($-2)..$];
        return [splitted[0].back, splitted[1].front];
    }

    /**
    Get the colour associated with passed value
    */
    auto colour( in double value ) const
    {
        import ggplotd.colourspace : toTuple;
        // When returning colour by value, try zip(c1, c2).map!( (a,b) => a+v*(b-a)) or something
        auto inval = interval( value );
        auto sc = (value-inval[0][0])/(inval[1][0]-inval[0][0]);
        auto minC = inval[0][1].toTuple;
        auto maxC = inval[1][1].toTuple;
        return ( C( 
            minC[0] + sc*(maxC[0]-minC[0]),
            minC[1] + sc*(maxC[1]-minC[1]),
            minC[2] + sc*(maxC[2]-minC[2]) ) );
    }

private:
    import std.range : Appender;
    Appender!(Tuple!(double,C)[]) stops;
}

unittest
{
    import ggplotd.colourspace : RGB;
    import std.range : back, front;

    ColourGradient!RGB cg;

    cg.put( 0, RGB(0,0,0) );
    cg.put( 1, "white" );

    auto ans = cg.interval( 0.1 );
    assertEqual( ans.front[0], 0 );
    assertEqual( ans.back[0], 1 );

    cg = ColourGradient!RGB();

    cg.put( 0, RGB(0,0,0) );
    cg.put( 0.2, RGB(0.5,0.6,0.8) );
    cg.put( 1, "white" );
    ans = cg.interval( 0.1 );
    assertEqual( ans.front[0], 0 );
    assertEqual( ans.back[0], 0.2 );

    ans = cg.interval( 1.1 );
    assertEqual( ans.front[0], 0.2 );
    assertEqual( ans.back[0], 1.0 );

    auto col = cg.colour( 0.1 );
    assertEqual( col, RGB(0.25,0.3,0.4) );
}

alias ColourGradientFunction = RGBA delegate( double value, double from, double till );

/**
Function returning a colourgradient function based on a specified ColourGradient

Params:
    cg =        A ColourGradient
    absolute =  Whether the cg is an absolute scale or relative (between 0 and 1)

Examples:
-----------------
auto cg = ColourGradient!HCY();
cg.put( 0, HCY(200, 0.5, 0) ); 
cg.put( 100, HCY(200, 0.5, 0) ); 
GGPlotD().put( colourGradient( cg ) );
-----------------
*/
ColourGradientFunction colourGradient(T)( in ColourGradient!T cg, 
    bool absolute=true )
{
    if (absolute) {
        return ( double value, double from, double till ) 
        {
            import ggplotd.colourspace : RGBA, toColourSpace;
            return cg.colour( value ).toColourSpace!RGBA;
        };
    }
    return ( double value, double from, double till ) 
    { 
        import ggplotd.colourspace : RGBA, toColourSpace;
        return cg.colour( (value-from)/(till-from) ).toColourSpace!RGBA;
    };
}

/**
Function returning a named colourgradient.

Colours can be specified with colour names separated by dashes:
"white-red" will result in a colourgradient from white to red. You can specify more than two colours "blue-white-red". "default" will result in the default (blueish) colourgradient.

Examples:
-----------------
GGPlotD().put( colourGradient( "blue-red" );
-----------------
*/
ColourGradientFunction colourGradient(T)( string name )
{
    import std.algorithm : splitter;
    import std.range : empty, walkLength;
    if ( !name.empty && name != "default" )
    {
        import ggplotd.colourspace : toColourSpace;
        auto namedColours = createNamedColours();
        auto cg = ColourGradient!T();
        auto splitted = name.splitter("-");
        immutable dim = splitted.walkLength;
        if (dim == 1)
        {
            auto c = namedColours[splitted.front].toColourSpace!T; 
            cg.put(0, c );
            cg.put(1, c );
        }
        if (dim > 2)
        {
            auto value = 0.0;
            immutable width = 1.0/(dim-1);
            foreach( sp ; splitted )
            {
                cg.put( value, namedColours[sp].toColourSpace!T );
                value += width;
            }
        }
        return colourGradient(cg, false);
    }
    import ggplotd.colourspace : HCY;
    auto cg = ColourGradient!HCY();
    cg.put( 0, HCY(200, 0.5, 0) ); 
    cg.put( 1, HCY(200, 0.5, 0.7) ); 
    return colourGradient(cg, false);
}

unittest
{
    import ggplotd.colourspace : HCY;
    auto cf = colourGradient!HCY( "red-white-blue" );
    assertEqual( cf( -1, -1, 2 ).r, 1 );
    assertEqual( cf( -1, -1, 2 ).g, 0 );
    assertEqual( cf( 2, -1, 2 ).b, 1 );
    assertLessThan( cf( 2, -1, 2 ).g, 1e-5 );
    assertEqual( cf( 0.5, -1, 2 ).b, 1 );
    assertEqual( cf( 0.5, -1, 2 ).g, 1 );
}
