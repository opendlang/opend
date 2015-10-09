module ggplotd.geom;

import cairo = cairo.cairo;

import ggplotd.bounds;
import ggplotd.aes;

version(unittest)
{
    import dunit.toolkit;
}

struct Geom( FUNC, Col )
{
    FUNC draw;
    Col colour;
    AdaptiveBounds bounds;
}

auto geomPoint(AES)(AES aes)
{
    struct GeomRange(T)
    {
        size_t size=6;
        this( T aes ) { _aes = aes; }
        @property auto front() {
            immutable tup = _aes.front;
            auto f = delegate(cairo.Context context) 
            {
                auto devP = 
                    context.userToDevice(
                            cairo.Point!double( tup.x, tup.y ));
                context.save();
                context.identityMatrix;
                context.rectangle( devP.x-0.5*size, devP.y-0.5*size, 
                        size, size );
                context.restore();
                return context;
            };

            AdaptiveBounds bounds;
            bounds.adapt( Point( tup.x, tup.y ) );

            return Geom!(typeof(f),typeof(tup.colour))
                ( f, tup.colour, bounds );
        }

        void popFront() {
            _aes.popFront();
        }

        @property bool empty() { return _aes.empty; }
        private:
            T _aes;
    }
    return GeomRange!AES(aes);
}

unittest
{
    auto aes = Aes!(double[],double[], string[])( [1.0],[2.0],["c"] );
    auto gl = geomPoint( aes );
    assertEqual( gl.front.colour, "c" );
    gl.popFront;
    assert( gl.empty );
}

auto geomLine(AES)(AES aes)
{
    struct GeomRange(T)
    {
        this( T aes ) { groupedAes = aes.group; }

        @property auto front() {
            auto f = delegate(cairo.Context context) 
            {
                auto fr = groupedAes.front;
                context.moveTo( fr.front.x, fr.front.y );
                fr.popFront;
                foreach( tup; fr )
                {
                    context.lineTo( tup.x, tup.y );
                }
                return context;
            };

            AdaptiveBounds bounds;
            auto fr = groupedAes.front;
            foreach( tup; fr )
            {
                bounds.adapt( Point( tup.x, tup.y ) );
            }

            return Geom!(typeof(f),typeof(fr.front.colour))
                ( f, fr.front.colour, bounds );
        }

        void popFront() {
            groupedAes.popFront;
        }

        @property bool empty() { return groupedAes.empty; }
        private:
            typeof( group(T.init) ) groupedAes;
    }
    return GeomRange!AES(aes);
}

unittest
{
    auto aes = Aes!(double[], double[], string[] )( 
            [1.0,2.0,1.1,3.0], 
            [3.0,1.5,1.1,1.8], 
            ["a","b","a","b"] );

    auto gl = geomLine( aes );
    assertEqual( gl.front.colour, "a" );
    assertEqual( gl.front.bounds.min_x, 1.0 );
    assertEqual( gl.front.bounds.max_x, 1.1 );
    gl.popFront;
    assertEqual( gl.front.colour, "b" );
    assertEqual( gl.front.bounds.max_x, 3.0 );
    gl.popFront;
    assert( gl.empty );
}

/// Bin a range of data
private auto bin(R)( R xs, size_t noBins = 10 )
{
    struct Bin {
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
            assert( xs.walkLength > 0 );

            // Find the min and max values
            auto minmax = xs.reduce!((a,b) => min(a,b),(a,b)=>max(a,b));
            _width = (minmax[1]-minmax[0])/(noBins-1);
            _noBins = noBins;
            // If min == max we need to set a custom width
            if (_width == 0) 
                _width = 0.1;
            _min = minmax[0] - 0.5*_width;

            // Count the number of data points that fall in a
            // bin. This is done by scaling them into whole numbers
            counts = xs.map!( (a) => floor((a-_min)/_width) )
                .array
                .sort().array
                .group();
            
            // Initialize our bins
            if (counts.front[0] == _binID)
            {
                _cnt = counts.front[1];
                counts.popFront;
            }
        }

        /// Return a bin describing the range and number of data points (count) that fall within that range.
        @property auto front() {
            return Bin( [_min, _min+_width], _cnt );
        }

        void popFront() {
            _min += _width;
            _cnt = 0;
            ++_binID;
            if (!counts.empty && counts.front[0] == _binID)
            {
                _cnt = counts.front[1];
                counts.popFront;
            }
        }

        @property bool empty() { return _binID >=_noBins; }
 
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
    auto binR = bin!(double[])( [0.5,0.01,0.0,0.9,1.0,0.99], 11 );
    assertEqual( binR.walkLength, 11 );
    assertEqual( binR.front.range, [-0.05,0.05] );
    assertEqual( binR.front.count, 2 );
    assertLessThan( binR.array.back.range[0], 1 );
    assertGreaterThan( binR.array.back.range[1], 1 );
    assertEqual( binR.array.back.count, 2 );

    binR = bin!(double[])( [0.01], 11 );
    assertEqual( binR.walkLength, 11 );
    assertEqual( binR.front.count, 1 );


    binR = bin!(double[])( [-0.01, 0,0,0, 0.01 ], 11 );
    assertEqual( binR.walkLength, 11 );
    assertLessThan( binR.front.range[0], -0.01 );
    assertGreaterThan( binR.front.range[1], -0.01 );
    assertEqual( binR.front.count, 1 );
    assertLessThan( binR.array.back.range[0], 0.01 );
    assertGreaterThan( binR.array.back.range[1], 0.01 );
    assertEqual( binR.array.back.count, 1 );
    assertEqual( binR.array[5].count, 3 );
    assertLessThan( binR.array[5].range[0], 0.0 );
    assertGreaterThan( binR.array[5].range[1], 0.0 );
}

/// Draw histograms based on the x coordinates of the data (aes)
auto geomHist(AES)(AES aes)
{
    import std.algorithm : map;
    import std.array : array;
    import std.range : repeat;
    double[] xs;
    double[] ys;
    typeof(aes.front.colour)[] colours;
    foreach( grouped; group( aes ) ) // Split data by colour/id
    {
        auto bins = grouped
            .map!( (t) => t.x ) // Extract the x coordinates
            .array.bin( 11 );   // Bin the data
        foreach( bin; bins )
        {
            // Convert data into line coordinates
            xs ~= [ bin.range[0], bin.range[0],
               bin.range[1], bin.range[1] ];
            ys ~= [ 0, bin.count,
               bin.count, 0 ];

            // Each (new) line coordinate has the colour specified
            // in the original data
            colours ~= grouped.front.colour.repeat(4).array;
        }
    }
    // Use the xs/ys/colours to draw lines
    return geomLine( Aes!(typeof(xs),typeof(ys),typeof(colours))( xs, ys, colours ) );
}


