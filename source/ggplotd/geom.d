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
                    context.lineTo( fr.front.x, fr.front.y );
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
