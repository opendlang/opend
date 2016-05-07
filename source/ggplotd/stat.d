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

    import std.stdio : writeln;
    if ( !(value <= max && value >= min) )
        writeln( value, " ", min, " ", max );

    assert( value <= max && value >= min, "Value must be within given range" );
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

private auto idToRange(T)( size_t value, T min, T width )
{
    auto base = min + value*width;
    return [ base, base + width ];
}

// Multidimensional bin. Data either is range of range, with each subrange
// a set of data. TODO: should we treat one dimensional data differently?
private auto bin(DATA)(DATA data, double[] mins, double[] maxs, 
    size_t noBins)
{
    import std.range : zip;
    import std.algorithm : filter, all, any, group, map;
    import ggplotd.range : groupBy;
    struct Bin
    {
        double[][] range;
        size_t count;
    }

    assert( noBins > 0, "noBins must be larger than 0" );

    auto widths = zip(mins, maxs).map!((t) => (t[1]-t[0])/noBins);

    auto binIDs = data
        .filter!((sample)
        { 
            return zip(sample, mins, maxs).
                all!( (args) => (args[0] >= args[1] && args[0] <= args[2]));
        })
        .map!((sample) 
        {
            import std.array : array; // Needed for groupBy to work correctly
            return zip(sample, mins, maxs, widths)
                .map!( (args) => binID( args[0], args[1], args[2], args[3] ) ).array;
        } );

    import std.typecons : tuple;

    return binIDs.groupBy!((a) => tuple(a)).values.map!((g) 
            {
                import std.array : array;
                Bin bin;
                bin.count = g.length;
                bin.range = zip( g[0], mins, widths )
                    .map!((args) => idToRange( args[0], args[1], args[2] ) )
                    .array;
                return bin;
            });
}

unittest {
    import std.algorithm : reduce;
    auto bins = bin( [[0.0],[0.1],[0.2],[0.2],[0.01],[0.3]], [0.0], [0.3], 10 );
    assertEqual( 6, reduce!((a,b) => a += b.count )( 0, bins ) );
    auto bins2 = bin( [[0.0,100],[0.1,101],[0.2,109],[0.01,110],[0.3,103.1]], [0.0,100], [0.3,110], 10 );
    assertEqual( 5, reduce!((a,b) => a += b.count )( 0, bins2 ) );
}

private auto bin(DATA)(DATA data, double min, double max, 
    size_t noBins)
{
    import std.algorithm : map;
    return bin( data.map!((d) => [d]), [min], [max], noBins );
}

unittest {
    import std.algorithm : reduce;
    auto bins = bin( [0.0,0.1,0.2,0.2,0.01,0.3], 0.0, 0.3, 10 );
    assertEqual( 6, reduce!((a,b) => a += b.count )( 0, bins ) );

    import std.algorithm : map;
    import std.array : array;
    import std.random : uniform;
    import std.range : iota, walkLength;
    auto xs = iota(0,10,1).map!((i)=>uniform(0,0.75)+uniform(0.25,1)).array;
    auto binsR = bin( xs, 0.0, 2.0, 5 );
    assertEqual( xs.walkLength, reduce!((a,b) => a += b.count )( 0, binsR ) );

    binsR = bin( xs, 0.0, 1.0, 5 );
    assertLessThanOrEqual( binsR.walkLength, 5 );
}

/**
 Create Aes that specifies the bins to draw an histogram 

 Params:
    aes = Data that the histogram will be based on 
    noBins  = Optional number of bins. On a value of 0 the number of bins will be chosen automatically.

 Returns: Range that holds rectangles representing different bins
*/
auto statHist(AES)(AES aesRaw, size_t noBins = 0)
{
    import std.stdio : writeln;
    struct VolderMort(AESV)
    {
        private import std.range : ElementType;
        private import std.typecons : Tuple;
        private import ggplotd.aes : group;

        typeof(group(AESV.init)) grouped;
        ElementType!(ElementType!(typeof(grouped))) defaults;
        typeof(bin!(double[])((double[]).init, double.init, double.init, size_t.init))
            binned;

        size_t _noBins;
        Tuple!(double, double) minmax;
        this( AESV )( AESV aes, size_t noBins )
        {
            import std.algorithm : min, max, reduce;
            import std.array : array;
            import std.range : empty, popFront, front, take, walkLength;

            import ggplotd.range : uniquer;
            auto xs = aes.map!((t) => t.x[0]) // Extract the x coordinates
                .array;
            _noBins = noBins;
            if (_noBins < 1)
                _noBins = min(xs.uniquer.take(30).walkLength,
                        min(30,max(11, xs.length/10)));
            minmax = xs.reduce!("min(a,b)","max(a,b)");

            grouped = group(aes);

            defaults = grouped.front.front;
            xs = grouped.front.map!((t) => t.x[0]) // Extract the x coordinates
                .array;
            binned = bin(xs, minmax[0], minmax[1], _noBins);
            assert( !grouped.empty, "Groups should not be empty" );
            grouped.popFront;
        }

        @property bool empty() { 
            import std.range : empty;
            return (grouped.empty && binned.empty); }

        @property auto front()
        {
            import ggplotd.aes : merge;
            auto w = binned.front.range[0][1]-binned.front.range[0][0];
            return defaults.merge(
                    Tuple!(double, "x", double, "y", double, "width", double, "height")(
                        binned.front.range[0][0] + 0.5*w, 0.5*binned.front.count, 
                        w, binned.front.count) );

        }

        void popFront()
        {
            import std.array : array;
            import std.range : empty, front, popFront;
            if (!binned.empty)
                binned.popFront;
            if (binned.empty && !grouped.empty)
            {
                defaults = grouped.front.front;
                auto xs = grouped.front.map!((t) => t.x[0]) // Extract the x coordinates
                    .array;
                binned = bin(xs, minmax[0], minmax[1], _noBins);
                grouped.popFront;
            }
        }


    }

    import std.algorithm : map;
    import ggplotd.aes : Aes, numericLabel, mergeRange;

    // Turn x into numericLabel
    auto xNumeric = numericLabel(aesRaw.map!((t) => t.x));
    auto aes = aesRaw.mergeRange( 
        Aes!(typeof(xNumeric), "x")( xNumeric ) );

    // Get maxs, mins and noBins
    return VolderMort!(typeof(aes))( aes, noBins );
}
