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
    import std.typecons : Tuple; import ggplotd.stat : statFunction; import ggplotd.ggplotd : GGPlotD; import ggplotd.geom : geomLine, geomPoint;
    import ggplotd.range : mergeRange;

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
    size_t[] noBins)
{
    import std.range : zip;
    import std.algorithm : filter, all, group, map;
    import ggplotd.range : groupBy;
    struct Bin
    {
        double[][] range;
        size_t count;
    }

    assert( noBins.all!((a) => a > 0), "noBins must be larger than 0" );

    auto widths = zip(mins, maxs, noBins).map!((t) => (t[1]-t[0])/(t[2]));

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
    auto bins = bin( [[0.0],[0.1],[0.2],[0.2],[0.01],[0.3]], [0.0], [0.3], [10] );
    assertEqual( 6, reduce!((a,b) => a += b.count )( 0, bins ) );
    auto bins2 = bin( [[0.0,100],[0.1,101],[0.2,109],[0.01,110],[0.3,103.1]], [0.0,100], [0.3,110], [10,10] );
    assertEqual( 5, reduce!((a,b) => a += b.count )( 0, bins2 ) );
}

private auto bin(DATA)(DATA data, double min, double max, 
    size_t noBins)
{
    import std.algorithm : map;
    return bin( data.map!((d) => [d]), [min], [max], [noBins] );
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

private auto statHistND(int dim, AES)(AES aesRaw, size_t[] noBins)
{
    struct VolderMort(AESV)
    {
        private import std.range : ElementType;
        private import std.typecons : Tuple;
        private import ggplotd.aes : group;

        typeof(group(AESV.init)) grouped;
        ElementType!(ElementType!(typeof(grouped))) defaults;
        typeof(bin!(double[][])((double[][]).init, (double[]).init, 
                    (double[]).init, (size_t[]).init))
            binned;

        size_t[] _noBins;
        double[] mins;
        double[] maxs;

        this( AESV )( AESV aes, size_t[] noBins )
        {
            import std.algorithm : min, max, reduce;
            import std.array : array;
            import std.conv : to;
            import std.range : empty, popFront, front, take, walkLength;
            import std.typecons : tuple;

            import ggplotd.math : safeMin, safeMax;
            import ggplotd.range : uniquer;

            static assert( dim == 1 || dim == 2, "Only dimension of 1 or 2 i supported" );

            _noBins = noBins;
            static if (dim == 1) {
                if (_noBins[0] < 1)
                    _noBins[0] = min(aes.map!((a) => a.x.to!double)
                            .uniquer.take(30).walkLength,
                            min(30,max(11, aes.length/10)));
                auto seed = tuple(
                        aes.front.x.to!double, aes.front.x.to!double );
                auto minmax = reduce!((a,b) => safeMin(a,b.x.to!double),
                        (a,b) => safeMax(a,b.x.to!double))(seed,aes);
                mins = [minmax[0]];
                maxs = [minmax[1]];
            }
            else
            {
                if (_noBins[0] < 1)
                    _noBins[0] = min(aes.map!((a) => a.x.to!double)
                            .uniquer.take(30).walkLength,
                            min(30,max(11, aes.length/25)));
                if (_noBins[1] < 1)
                    _noBins[1] = min(aes.map!((a) => a.y.to!double)
                            .uniquer.take(30).walkLength,
                            min(30,max(11, aes.length/25)));
                auto seed = tuple(
                        aes.front.x.to!double, aes.front.x.to!double,
                        aes.front.y.to!double, aes.front.y.to!double );
                auto minmax = reduce!(
                            (a,b) => safeMin(a,b.x.to!double),
                            (a,b) => safeMax(a,b.x.to!double),
                            (a,b) => safeMin(a,b.y.to!double),
                            (a,b) => safeMax(a,b.y.to!double)
                        )(seed,aes);
                mins = [minmax[0],minmax[2]];
                maxs = [minmax[1],minmax[3]];
             }

            grouped = group(aes);

            defaults = grouped.front.front;
            static if (dim == 1)
              auto data = grouped.front.map!((t) => [t.x.to!double]); // Extract the x coordinates
            else 
              auto data = grouped.front.map!((t) => [t.x.to!double,t.y.to!double]); // Extract the x coordinates
            binned = bin(
                    data.array, 
                    mins, maxs, 
                    _noBins);
            assert( !grouped.empty, "Groups should not be empty" );
            grouped.popFront;
        }

        @property bool empty() { 
            import std.range : empty;
            return (grouped.empty && binned.empty); }

        @property auto front()
        {
            import ggplotd.aes : merge;
            import std.conv : to;
            static if (dim == 1)
            {
                auto w = binned.front.range[0][1]-binned.front.range[0][0];
                return defaults.merge(
                        Tuple!(double, "x", double, "y", double, "width", double, "height")(
                            binned.front.range[0][0] + 0.5*w, 0.5*binned.front.count, 
                            w, binned.front.count) );
            }
            else
            {
                // Returning polygons. In theory could also return rectangle, but their lines
                // will overlap which will make it look wrong. Ideally would be able to set 
                // linewidth to 0 for the rectangles and that would solve it.
                return [
                    defaults.merge(
                        Tuple!(double, "x", double, "y", double, "colour")(
                            binned.front.range[0][0], binned.front.range[1][0],
                            binned.front.count.to!double)),

                    defaults.merge(
                        Tuple!(double, "x", double, "y", double, "colour")(
                            binned.front.range[0][1], binned.front.range[1][0],
                            binned.front.count.to!double)),

                    defaults.merge(
                        Tuple!(double, "x", double, "y", double, "colour")(
                            binned.front.range[0][1], binned.front.range[1][1],
                            binned.front.count.to!double)),

                    defaults.merge(
                        Tuple!(double, "x", double, "y", double, "colour")(
                            binned.front.range[0][0], binned.front.range[1][1],
                            binned.front.count.to!double)),

                    ];
            }
        }

        void popFront()
        {
            import std.array : array;
            import std.conv : to;
            import std.range : empty, front, popFront;
            if (!binned.empty)
                binned.popFront;
            if (binned.empty && !grouped.empty)
            {
                defaults = grouped.front.front;
                static if (dim == 1) // Extract the coordinates
                    auto data = grouped.front.map!((t) => [t.x.to!double]); 
                else 
                    auto data = grouped.front.map!((t) => [t.x.to!double,t.y.to!double]);
                binned = bin(data.array, mins, maxs, _noBins);
                grouped.popFront;
            }
        }


    }

    import std.algorithm : map;
    import ggplotd.aes : Aes, numericLabel;
    import ggplotd.range : mergeRange;

    // Turn x into numericLabel
    auto xNumeric = numericLabel(aesRaw.map!((t) => t.x));
    static if (dim == 1)
        auto aes = aesRaw.mergeRange( 
                Aes!(typeof(xNumeric), "x")( xNumeric ) );
    else 
    {
        auto yNumeric = numericLabel(aesRaw.map!((t) => t.y));
        auto aes = aesRaw.mergeRange( 
                Aes!(typeof(xNumeric), "x", typeof(yNumeric), "y")( xNumeric, yNumeric ) );
    }

    // Get maxs, mins and noBins
    return VolderMort!(typeof(aes))( aes, noBins );
}

/**
 Create Aes that specifies the bins to draw an histogram 

 Params:
    aesRaw = Data that the histogram will be based on 
    noBins  = Optional number of bins. On a value of 0 the number of bins will be chosen automatically.

 Returns: Range that holds rectangles representing different bins
*/
auto statHist(AES)(AES aesRaw, size_t noBins = 0)
{
    return statHistND!(1,AES)( aesRaw, [noBins] );
}

unittest
{
    import std.stdio : writeln;

    import std.algorithm : each, map, sort;
    import std.array : array;
    import std.random : uniform;
    import std.range : iota, walkLength;

    import ggplotd.aes : Aes;

    auto xs = iota(0,100,1).map!((a) => uniform(0,6) ).array;
    auto sh = statHist( Aes!(int[], "x")(xs) );
    auto binXs = sh.map!((b) => b.x).array.sort().array;
    assertEqual( binXs.length, 6 );
}

/**
 Create Aes that specifies the bins to draw an histogram 

 Params:
    aesRaw = Data that the histogram will be based on 
    noBinsX  = Optional number of bins for x axis. On a value of 0 the number of bins will be chosen automatically.
    noBinsY  = Optional number of bins for y axis. On a value of 0 the number of bins will be chosen automatically.

 Returns: Range that holds rectangles representing different bins
*/
auto statHist2D(AES)(AES aesRaw, size_t noBinsX = 0, size_t noBinsY = 0)
{
    return statHistND!(2,AES)( aesRaw, [noBinsX, noBinsY]);
}

/**
Calculate kernel density for given data

Params:
   aesRaw = Data that the histogram will be based on 

Returns: InputRange that holds x and y coordinates for the kernel
*/
auto statDensity(AES)( AES aesRaw )
{
    import std.algorithm : joiner, map, min, max, reduce;
    import std.range : chain, front;
    import std.typecons : tuple, Tuple;
    import ggplotd.aes : Aes, numericLabel, group;
    import ggplotd.range : mergeRange;
    import ggplotd.math : safeMin, safeMax;

    auto xNumeric = aesRaw.map!((t) => t.x).numericLabel;
    auto aes = aesRaw.mergeRange( Aes!(typeof(xNumeric),"x")(xNumeric) );
    auto minmax = reduce!(
            (a,b) => safeMin(a,b.x.to!double),
            (a,b) => safeMax(a,b.x.to!double))(tuple(double.init,double.init), aes);
    auto margin = (minmax[1] - minmax[0])/10.0;
    minmax[0] -= margin;
    minmax[1] += margin;



    return aes.group.map!((g) {
        auto xs = g.map!((t) => t.x.to!double);

        // Calculate the kernel width (using scott thing in dstats)
        // Initialize kernel with normal distribution.
        import dstats.kerneldensity : scottBandwidth, KernelDensity;
        import dstats.random : normalPDF;
        auto sigma = scottBandwidth(xs);
        auto kernel = (double x) { return normalPDF(x, 0.0, sigma); };
        auto density = KernelDensity.fromCallable(kernel, xs);

        // Use statFunction with the kernel to produce a line
        // Also add points to close the path down to zero
        auto coords = chain(
                [Tuple!(double, "x", double, "y")( minmax[0], 0.0 )],
                statFunction( density, minmax[0], minmax[1] ),
                [Tuple!(double, "x", double, "y")( minmax[1], 0.0 )]);


        return g.front.mergeRange( coords );
    }).joiner;
}

///
unittest
{
    import std.stdio : writeln;
    import std.algorithm : map;
    import std.array : array;
    import std.random : uniform;
    import std.range : chain, iota, repeat, walkLength;

    import ggplotd.aes : Aes;

    auto xs = iota(0,100,1)
        .map!((i)=>uniform(0,0.75)+uniform(0.25,1))
        .array;

    auto dens = statDensity( Aes!( typeof(xs), "x")( xs ) );
    auto dim = dens.walkLength;
    assertGreaterThan( dim, 1 );

    // Test that grouping leads to longer (twice as long) result
    auto cols = chain("a".repeat(50),"b".repeat(50) );
    auto dens2 = statDensity( Aes!(typeof(cols), "colour", typeof(xs), "x")( cols, xs ) );
    assertGreaterThan( dens2.walkLength, 1.9*dim );
    assertLessThan( dens2.walkLength, 2.1*dim );

    // Test that colour is passed through (merged)
    assertEqual( dens2.front.colour.length, 1 );
}

/**
Calculate kernel density for given x and y data

Params:
   aesRaw = Data that the histogram will be based on 

Returns: Range of ranges that holds polygons for the kernel
*/
auto statDensity2D(AES)( AES aesRaw )
{
    import std.algorithm : joiner, map, min, max, reduce;
    import std.array : array;
    import std.range : chain, front, iota, zip;
    import std.typecons : Erase, tuple, Tuple;
    import ggplotd.aes : Aes, numericLabel, group, DefaultGroupFields;
    import ggplotd.math : safeMin, safeMax;
    import ggplotd.range : mergeRange;

    auto xNumeric = aesRaw.map!((t) => t.x).numericLabel;
    auto yNumeric = aesRaw.map!((t) => t.y).numericLabel;
    auto aes = aesRaw.mergeRange( Aes!(typeof(xNumeric),"x",
                typeof(yNumeric),"y")(xNumeric, yNumeric) );
    auto minmax = reduce!(
            (a,b) => safeMin(a,b.x.to!double),
            (a,b) => safeMax(a,b.x.to!double),
            (a,b) => safeMin(a,b.y.to!double),
            (a,b) => safeMax(a,b.y.to!double),
            )(tuple(double.init,double.init,double.init,double.init), aes);

    return aes.group!(Erase!("colour",DefaultGroupFields)).map!((g) {
        auto xs = g.map!((t) => t.x.to!double);
        auto ys = g.map!((t) => t.y.to!double);

        // Calculate the kernel width (using scott thing in dstats)
        // Initialize kernel with normal distribution.
        import dstats.kerneldensity : scottBandwidth, KernelDensity;
        import dstats.random : normalPDF;
        auto sigmaX = scottBandwidth(xs);
        auto sigmaY = scottBandwidth(ys);
        auto kernel = (double x, double y) { return normalPDF(x, 0.0, sigmaX)*
            normalPDF(y, 0.0, sigmaY); };
        auto density = KernelDensity.fromCallable(kernel, xs, ys);

        auto marginX = (minmax[1] - minmax[0])/10.0;
        auto marginY = (minmax[3] - minmax[2])/10.0;

        minmax[0] -= marginX;
        minmax[1] += marginX;
        minmax[2] -= marginY;
        minmax[3] += marginY;


        // Use statFunction with the kernel to produce a line
        // Also add points to close the path down to zero
        auto stepX = (minmax[1] - minmax[0])/25.0;
        auto stepY = (minmax[3] - minmax[2])/25.0;
        auto xCoords = iota( minmax[0], minmax[1] + stepX, stepX ).array;
        auto yCoords = iota( minmax[2], minmax[3] + stepY, stepY ).array;
        auto coords = zip(xCoords, xCoords[1..$]).map!( (xr) {
                return zip(yCoords, yCoords[1..$]).map!( (yr) {
                        // Two polygons
                        return [
                        g.front.mergeRange(Aes!( double[], "x", double[], "y", double[], "colour" )
                        ([xr[0], xr[0], xr[1]],
                         [yr[0], yr[1], yr[1]],
                         [density(xr[0],yr[0]),density(xr[0],yr[1]),density(xr[1],yr[1])])),
                        g.front.mergeRange(
                                Aes!( double[], "x", double[], "y", double[], "colour" )
                        ([xr[0], xr[1], xr[1]],
                         [yr[0], yr[0], yr[1]],
                         [density(xr[0],yr[0]),density(xr[1],yr[0]),density(xr[1],yr[1])]))
                         ];
                }).joiner;
        }).joiner;
        return coords;
        //return g;
    }).joiner;
}

///
unittest
{
    import std.algorithm : map;
    import std.array : array;
    import std.random : uniform;
    import std.range : iota, walkLength;

    import ggplotd.aes : Aes;
    auto xs = iota(0,500,1).map!((x) => uniform(0.0,5)+uniform(0.0,5))
        .array;
    auto ys = iota(0,500,1).map!((y) => uniform(1.0,1.5)+uniform(1.0,1.5))
        .array;
    auto aes = Aes!(typeof(xs), "x", typeof(ys), "y")( xs, ys);

    auto sD = statDensity2D( aes );
    assertGreaterThan( sD.walkLength, 1200 );
    assertLessThan( sD.walkLength, 1300 );
    assertEqual( sD.front.walkLength, 3 );
}
