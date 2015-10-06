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
