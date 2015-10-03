module ggplotd.geom;

import cairo.cairo;

version(unittest)
{
    import ggplotd.aes;
}

struct Geom( FUNC, Col )
{
    FUNC draw;
    Col colour;
}

auto geom_line(AES)(AES aes )
{
    struct GeomRange(T)
    {
        this( T aes ) { _aes = aes; }
        @property auto front() {
            immutable tup = _aes.front;
            auto f = delegate(Context context) 
            {
                return context.rectangle( tup.x, tup.y, 0.2, 0.2 );
            };
            return Geom!(typeof(f),typeof(tup.colour))
                ( f, tup.colour );
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
    auto pl = geom_line( aes );
}
