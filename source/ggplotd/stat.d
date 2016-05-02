module ggplotd.stat;

version( unittest )
{
    import dunit.toolkit;
}

import std.traits : isCallable;

/**
 Create Aes based on a function

 Params:
    func = Function
    min  = x coordinate to start from
    max  = x coordinate to end at
    precision = Number of points to calculate

  Examples:
  --------------
    /// http://blackedder.github.io/ggplotd/images/function.png
    import std.random : uniform;
    import std.typecons : Tuple;
    import ggplotd.stat : statFunction;
    import ggplotd.ggplotd : GGPlotD;
    import ggplotd.geom : geomLine, geomPoint;
    import ggplotd.aes : mergeRange;

    auto f = (double x) { return x / (1 + x); };

    auto aes = statFunction(f, 0.0, 10);
    auto gg = GGPlotD().put(geomLine(aes));

    // Generate some noisy points 
    auto f2 = (double x) { return x / (1 + x) * uniform(0.75, 1.25); };
    auto aes2 = f2.statFunction(0.0, 10, 25);

    // Show points in different colour
    auto withColour = Tuple!(string, "colour")("aquamarine").mergeRange(aes2);
    gg = gg.put(withColour.geomPoint);

    gg.save("function.png");
  --------------

*/
auto statFunction( FUNC, T )( FUNC func, T min, 
    T max, size_t precision = 50 ) if (isCallable!FUNC)
{
    import std.algorithm : map;
    import std.range : iota;

    import ggplotd.aes : Aes;
    auto stepSize = (max-min)/(precision-1);
    auto xs = iota( min, max+stepSize, stepSize );
    auto ys = xs.map!((x) => func(x));

    return Aes!(typeof(xs), "x", typeof(ys), "y")( xs, ys );
}

unittest
{
    import std.array : array;

    auto aes = statFunction( (double x) { return 2*x; }, 0.0, 1, 2 );
    assertEqual( aes.x.array, [0.0, 1.0] );
    assertEqual( aes.y.array, [0.0, 2.0] );

    aes = statFunction( (double x) { return 3*x; }, -1.0, 1, 3 );
    assertEqual( aes.x.array, [-1.0, 0.0, 1.0] );
    assertEqual( aes.y.array, [-3.0, 0.0, 3.0] );
}

/+++++++++++
Binning
+++++++++++/

private auto binID(T)( T value, T min, T max, T width )
{
    import std.conv : to;
    import std.math : floor;
    assert( min != max, "Minimum value of bin should differ from maximum" );
    assert( width != 0, "Bin width can't be 0" );
    if (value==max) // Corner case for highest value
        value -= 0.1*width; // Might not work correctly for integers
    auto id = floor((value - min) / width);
    return id.to!int;
}

unittest
{
    import std.algorithm : map;
    import std.array : array;
    assertEqual(
        [0.1,0.3,0.6,0.2,0.4].map!((a) => a.binID( 0, 0.6, 0.2 )).array,
        [0,1,2,1,2] 
    );
    // TODO: add tests for integers etc.
}

private auto idToRange(T)( T value, T min, T width )
{
    auto base = min + value*width;
    return [ base, base + width ];
}

// Multidimensional bin. Data either is range of range, with each subrange
// a set of data. TODO: should we treat one dimensional data differently?
private auto bin(DATA)(DATA data, double[] mins, double[] maxs, 
    size_t noBins = 10)
{
    import std.range : zip;
    import std.algorithm : group, map;
    struct Bin
    {
        double[][] range;
        size_t count;
    }

    auto widths = zip(mins, maxs).map!((t) => (t[1]-t[0])/noBins);

    auto binIDs = data.map!((sample) 
            {
                import std.array : array;
                return zip(sample, mins, maxs, widths)
                    .map!( (args) => binID( args[0], args[1], args[2], args[3] ) )
                    .array; // Needed for group to work
            } );

    return binIDs.group.map!((g) 
            {
                import std.array : array;
                Bin bin;
                bin.range = zip( g[0], mins, widths )
                    .map!((args) => idToRange( args[0], args[1], args[2] ) )
                    .array;
                bin.count = g[1];
                return bin;
            });
}

unittest {
    import std.algorithm : reduce;
    auto bins = bin( [[0.0],[0.1],[0.2],[0.2],[0.01],[0.3]], [0.0], [0.3] );
    assertEqual( 6, reduce!((a,b) => a += b.count )( 0, bins ) );
    auto bins2 = bin( [[0.0,100],[0.1,101],[0.2,109],[0.01,110],[0.3,103.1]], [0.0,100], [0.3,110] );
    assertEqual( 5, reduce!((a,b) => a += b.count )( 0, bins2 ) );
}

private auto bin(DATA)(DATA data, double min, double max, 
    size_t noBins = 10)
{
    import std.algorithm : map;
    return bin( data.map!((d) => [d]), [min], [max], noBins );
}

unittest {
    import std.algorithm : reduce;
    auto bins = bin( [0.0,0.1,0.2,0.2,0.01,0.3], 0.0, 0.3 );
    assertEqual( 6, reduce!((a,b) => a += b.count )( 0, bins ) );
} 
/+

// Should return aes that can be passed to geomRectangle, which plots each bin
// Only works for 1 or 2D case
private auto statBin(AES)(AES aes)
{
    import std.algorithm : min, max, reduce;
    import std.range : walkLength;
    assert(xs.walkLength > 0);

    auto minmax = xs.reduce!((a, b) => min(a, b), (a, b) => max(a, b));
    return bin( xs, minmax[0], minmax[1], noBins );
}
+/

