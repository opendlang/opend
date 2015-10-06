module ggplotd.geom;

import cairo = cairo.cairo;

import ggplotd.bounds;

version(unittest)
{
    import dunit.toolkit;
    import ggplotd.aes;
}

struct Geom( FUNC, Col )
{
    FUNC draw;
    Col colour;
    AdaptiveBounds bounds;
}

auto geomLine(AES)(AES aes )
{
    struct GeomRange(T)
    {
        this( T aes ) { _aes = aes; }
        @property auto front() {
            immutable tup = _aes.front;
            auto f = delegate(cairo.Context context) 
            {
                return context.rectangle( tup.x, tup.y, 0.2, 0.2 );
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
    auto gl = geomLine( aes );
    assertEqual( gl.front.colour, "c" );
    gl.popFront;
    assert( gl.empty );
}
