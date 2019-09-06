module ggplotd.axes;

import std.typecons : Tuple;

version (unittest)
{
    import dunit.toolkit;
}

/++
Struct holding details on axis
+/
struct Axis
{
    /// Creating axis giving a minimum and maximum value
    this(double newmin, double newmax)
    {
        min = newmin;
        max = newmax;
        min_tick = min;
    }

    /// Label of the axis
    string label;
	/// How to rotate the axis
	double labelAngle = 0.0;

    /// Minimum value of the axis
    double min;
    /// Maximum value of the axis
    double max;
    /// Location of the lowest tick
    double min_tick = -1;
    /// Distance between ticks
    double tick_width = 0.2;

    /// Offset of the axis
    double offset;

    /// Show the axis or hide it
    bool show = true;
}

/// XAxis
struct XAxis {
    /// The general Axis struct
    Axis axis;
    alias axis this;
}

/// YAxis
struct YAxis {
    /// The general Axis struct
    Axis axis;
    alias axis this;
}

/**
    Is the axis properly initialized? Valid range.
*/
bool initialized( in Axis axis )
{
    import std.math : isNaN;
    if ( isNaN(axis.min) || isNaN(axis.max) || axis.max <= axis.min )
        return false;
    return true;
}

unittest
{
    auto ax = Axis();
    assert( !initialized( ax ) );
    ax.min = -1;
    assert( !initialized( ax ) );
    ax.max = -1;
    assert( !initialized( ax ) );
    ax.max = 1;
    assert( initialized( ax ) );
}

/**
    Calculate optimal tick width given an axis and an approximate number of ticks
    */
Axis adjustTickWidth(Axis axis, size_t approx_no_ticks)
{
    import std.math : abs, floor, ceil, pow, log10, round;
    assert( initialized(axis), "Axis range has not been set" );

    auto axis_width = axis.max - axis.min;
    auto scale = cast(int) floor(log10(axis_width));
    auto acceptables = [0.1, 0.2, 0.5, 1.0, 2.0, 5.0]; // Only accept ticks of these sizes
    auto approx_width = pow(10.0, -scale) * (axis_width) / approx_no_ticks;
    // Find closest acceptable value
    double best = acceptables[0];
    double diff = abs(approx_width - best);
    foreach (accept; acceptables[1 .. $])
    {
        if (abs(approx_width - accept) < diff)
        {
            best = accept;
            diff = abs(approx_width - accept);
        }
    }

    if (round(best/approx_width)>1)
        best /= round(best/approx_width);
    if (round(approx_width/best)>1)
        best *= round(approx_width/best);
    axis.tick_width = best * pow(10.0, scale);
    // Find good min_tick
    axis.min_tick = ceil(axis.min * pow(10.0, -scale)) * pow(10.0, scale);
    //debug writeln( "Here 120 ", axis.min_tick, " ", axis.min, " ", 
    //		axis.max,	" ", axis.tick_width, " ", scale );
    while (axis.min_tick - axis.tick_width > axis.min)
        axis.min_tick -= axis.tick_width;
    return axis;
}

unittest
{
    adjustTickWidth(Axis(0, .4), 5);
    adjustTickWidth(Axis(0, 4), 8);
    assert(adjustTickWidth(Axis(0, 4), 5).tick_width == 1.0);
    assert(adjustTickWidth(Axis(0, 4), 8).tick_width == 0.5);
    assert(adjustTickWidth(Axis(0, 0.4), 5).tick_width == 0.1);
    assert(adjustTickWidth(Axis(0, 40), 8).tick_width == 5);
    assert(adjustTickWidth(Axis(-0.1, 4), 8).tick_width == 0.5);
    assert(adjustTickWidth(Axis(-0.1, 4), 8).min_tick == 0.0);
    assert(adjustTickWidth(Axis(0.1, 4), 8).min_tick == 0.5);
    assert(adjustTickWidth(Axis(1, 40), 8).min_tick == 5);
    assert(adjustTickWidth(Axis(3, 4), 5).min_tick == 3);
    assert(adjustTickWidth(Axis(3, 4), 5).tick_width == 0.2);
    assert(adjustTickWidth(Axis(1.79877e+07, 1.86788e+07), 5).min_tick == 1.8e+07);
    assert(adjustTickWidth(Axis(1.79877e+07, 1.86788e+07), 5).tick_width == 100_000);
}

private struct Ticks
{
    double currentPosition;
    Axis axis;

    @property double front()
    {
        import std.math : abs;
        if (currentPosition >= axis.max)
            return axis.max;
        // Special case for zero, because a small numerical error results in
        // wrong label, i.e. 0 + small numerical error (of 5.5e-17) is 
        // displayed as 5.5e-17, while any other numerical error falls 
        // away in rounding
        if (abs(currentPosition - 0) < axis.tick_width/1.0e5)
            return 0.0;
        return currentPosition;
    }

    void popFront()
    {
        if (currentPosition < axis.min_tick)
            currentPosition = axis.min_tick;
        else
            currentPosition += axis.tick_width;
    }

    @property bool empty()
    {
        if (currentPosition - axis.tick_width >= axis.max)
            return true;
        return false;
    }
}

/// Returns a range starting at axis.min, ending axis.max and with
/// all the tick locations in between
auto axisTicks(Axis axis)
{
    return Ticks(axis.min, axis);
}

unittest
{
    import std.array : array, front, back;

    auto ax1 = adjustTickWidth(Axis(0, .4), 5).axisTicks;
    auto ax2 = adjustTickWidth(Axis(0, 4), 8).axisTicks;
    assertEqual(ax1.array.front, 0);
    assertEqual(ax1.array.back, .4);
    assertEqual(ax2.array.front, 0);
    assertEqual(ax2.array.back, 4);
    assertGreaterThan(ax1.array.length, 3);
    assertLessThan(ax1.array.length, 8);

    assertGreaterThan(ax2.array.length, 5);
    assertLessThan(ax2.array.length, 10);

    auto ax3 = adjustTickWidth(Axis(1.1, 2), 5).axisTicks;
    assertEqual(ax3.array.front, 1.1);
    assertEqual(ax3.array.back, 2);
}

/// Calculate tick length
double tickLength(in Axis axis)
{
    return (axis.max - axis.min) / 25.0;
}

unittest
{
    auto axis = Axis(-1, 1);
    assert(tickLength(axis) == 0.08);
}

/** Print (axis) value, uses scientific notation for higher decimals

TODO: Could generate code to support decimals > 3
*/
string scalePrint(in double value, in uint scaleMin, in uint scaleMax) {
    import std.math : abs;
    import std.format : format;
    auto diff = abs(scaleMax - scaleMin);
    if (diff == 0)
        return format( "%.1g", value );
    else if (diff == 1)
        return format( "%.2g", value );
    else if (diff == 2)
        return format( "%.3g", value );
    else if (diff == 3)
        return format( "%.4g", value );
    else if (diff == 4)
        return format( "%.5g", value );
    else if (diff == 5)
        return format( "%.6g", value );
    else if (diff == 6)
        return format( "%.7g", value );
    else if (diff == 7)
        return format( "%.8g", value );
    return format( "%g", value );
}

unittest {
    assertEqual(1.23456.scalePrint(-1, 1), "1.23");
}

/// Convert a value to an axis label
string toAxisLabel( double value, double max_value, double tick_width)
{
    import std.math : ceil, floor, log10;
    auto scaleMin = cast(int) floor(log10(tick_width));
    auto scaleMax = cast(int) ceil(log10(max_value));
    // Special rules for values that are human readible whole numbers 
    // (i.e. smaller than 10000)
    if (scaleMax <= 4 && scaleMin >= 0) {
        scaleMax = 4;
        scaleMin = 0;
    }
    return value.scalePrint(scaleMin, scaleMax);
}

unittest {
    assertEqual(10.toAxisLabel(20, 10), "10");
    assertEqual(10.toAxisLabel(10, 10), "10");
}

/// Calculate tick length in plot units
auto tickLength(double plotSize, size_t deviceSize, double scalingX, double scalingY)
{
    // We want ticks to be same size irrespcetvie of aspect ratio
    auto scaling = (scalingX+scalingY)/2.0;
    return scaling*10.0*plotSize/deviceSize;
}

unittest
{
    assertEqual(tickLength(10.0, 100, 1, 0.5), tickLength(10.0, 100, 0.5, 1));
    assertEqual(tickLength(10.0, 100, 1, 0.5), 2.0*tickLength(5.0, 100, 0.5, 1));
}

/// Aes describing the axis and its tick locations
auto axisAes(string type, double minC, double maxC, double lvl, double scaling = 1, Tuple!(double, string)[] ticks = [])
{
    import std.algorithm : sort, uniq, map;
    import std.array : array;
    import std.conv : to; 
    import std.range : empty, repeat, take, popFront, walkLength, front;

    import ggplotd.aes : Aes;

    double[] ticksLoc;
    auto sortedAxisTicks = ticks.sort().uniq;

    string[] labels;

    if (!sortedAxisTicks.empty)
    {
        ticksLoc = [minC] ~ sortedAxisTicks.map!((t) => t[0]).array ~ [maxC];
        // add voldermort type.. Using ticksLock and sortedAxisTicks
        import std.stdio : writeln;
        struct LabelRange(R) {
            bool init = false;
            double[] ticksLoc;
            string[] ticksLab;
            this(double[] tl, R sortedAxisTicks) {
                ticksLoc = tl;
                ticksLab = [""] ~ sortedAxisTicks.map!((t) => t[1]).array ~ [""];
            }
            @property bool empty() 
            {
                return ticksLoc.empty;
            }
            @property auto front()
            {
                import std.range : back;
                if (!init || ticksLoc.length == 1)
                    return "";
                if (!ticksLab.front.empty)
                    return ticksLab.front;
                return toAxisLabel(ticksLoc.front, ticksLoc.back, ticksLoc[1] - ticksLoc[0]);
            }
            void popFront() {
                ticksLoc.popFront;
                ticksLab.popFront;
                if (!init) {
                    init = true;
                }
            }
        }
        auto lr = LabelRange!(typeof(sortedAxisTicks))(ticksLoc, sortedAxisTicks);
        foreach(lab ; lr)
            labels ~= lab;
    }
    else
    {
        import std.math : round;
        import std.conv : to;
        auto axis = Axis(minC, maxC).adjustTickWidth(round(6.0*scaling).to!size_t);
        ticksLoc = axis.axisTicks.array;
        labels = ticksLoc.map!((a) => a.to!double.toAxisLabel(axis.max, axis.tick_width)).array;
    }

    if (type == "x")
    {
        return Aes!(double[], "x", double[], "y", string[], "label", double[], "angle",
            double[], "size")(
            ticksLoc, lvl.repeat().take(ticksLoc.walkLength).array, labels,
            (0.0).repeat(labels.walkLength).array,
            (scaling).repeat(labels.walkLength).array);
    }
    else
    {
        import std.math : PI;

        return Aes!(double[], "x", double[], "y", string[], "label", double[], "angle",
            double[], "size")(
            lvl.repeat().take(ticksLoc.walkLength).array, ticksLoc, labels,
            ((-0.5 * PI).to!double).repeat(labels.walkLength).array,
            (scaling).repeat(labels.walkLength).array);
    }
}

unittest
{
    import std.stdio : writeln;

    auto aes = axisAes("x", 0.0, 1.0, 2.0);
    assertEqual(aes.front.x, 0.0);
    assertEqual(aes.front.y, 2.0);
    assertEqual(aes.front.label, "0");

    aes = axisAes("y", 0.0, 1.0, 2.0, 1.0, [Tuple!(double, string)(0.2, "lbl")]);
    aes.popFront;
    assertEqual(aes.front.x, 2.0);
    assertEqual(aes.front.y, 0.2);
    assertEqual(aes.front.label, "lbl");
}

private string ctReplaceAll( string orig, string pattern, string replacement )
{

    import std.string : split;
    auto spl = orig.split( pattern );
    string str = spl[0];
    foreach( sp; spl[1..$] )
        str ~= replacement ~ sp;
    return str;
}

// Create a specialised x and y axis version of a given function.
private string xy( string func )
{
    import std.format : format;
    return format( "///\n%s\n\n///\n%s",
        func
            .ctReplaceAll( "axis", "xaxis" )
            .ctReplaceAll( "Axis", "XAxis" ),
        func
            .ctReplaceAll( "axis", "yaxis" )
            .ctReplaceAll( "Axis", "YAxis" ) );
}

alias XAxisFunction = XAxis delegate(XAxis);
alias YAxisFunction = YAxis delegate(YAxis);

// Below are the external functions to be used by library users.

// Set the range of an axis
mixin( xy( q{auto axisRange( double min, double max ) 
{ 
    AxisFunction func = ( Axis axis ) { axis.min = min; axis.max = max; return axis; }; 
    return func;
}} ) );

///
unittest
{
    XAxis ax;
    auto f = xaxisRange( 0, 1 );
    assertEqual( f(ax).min, 0 );
    assertEqual( f(ax).max, 1 );

    YAxis yax;
    auto yf = yaxisRange( 0, 1 );
    assertEqual( yf(yax).min, 0 );
    assertEqual( yf(yax).max, 1 );
}

// Set the label of an axis
mixin( xy( q{auto axisLabel( string label ) 
{ 
    // Need to declare it as an X/YAxisFunction for the GGPlotD + overload
    AxisFunction func = ( Axis axis ) { axis.label = label; return axis; }; 
    return func;
}} ) );

///
unittest
{
    XAxis xax;
    auto xf = xaxisLabel( "x" );
    assertEqual( xf(xax).label, "x" );

    YAxis yax;
    auto yf = yaxisLabel( "y" );
    assertEqual( yf(yax).label, "y" );
}

// Set the range of an axis
mixin( xy( q{auto axisOffset( double offset ) 
{ 
    AxisFunction func = ( Axis axis ) { axis.offset = offset; return axis; }; 
    return func;
}} ) );

///
unittest
{
    XAxis xax;
    auto xf = xaxisOffset( 1 );
    assertEqual( xf(xax).offset, 1 );

    YAxis yax;
    auto yf = yaxisOffset( 2 );
    assertEqual( yf(yax).offset, 2 );
}

// Hide the axis 
mixin( xy( q{auto axisShow( bool show ) 
{ 
    // Need to declare it as an X/YAxisFunction for the GGPlotD + overload
    AxisFunction func = ( Axis axis ) { axis.show = show; return axis; }; 
    return func;
}} ) );


// Set the angle of an axis label
mixin( xy( q{auto axisLabelAngle( double angle ) 
{ 
    AxisFunction func = ( Axis axis ) { axis.labelAngle = angle; return axis; }; 
    return func;
}} ) );

///
unittest
{
    XAxis xax;
    auto xf = xaxisLabelAngle( 90.0 );
    assertEqual( xf(xax).labelAngle, 90.0 );

    YAxis yax;
    auto yf = yaxisLabelAngle( 45.0 );
    assertEqual( yf(yax).labelAngle, 45.0 );
}
