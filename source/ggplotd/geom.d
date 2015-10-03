module ggplotd.geom;

import cairo.cairo;

version(unittest)
{
    import ggplotd.aes;
}

auto geom_line(AES)(AES aes )
{
    struct GeomRange(T)
    {
        this( T aes ) { _aes = aes; }
        @property auto front() {
            return (Context context) 
            {
                return context.rectangle( 0.4, 0.4, 0.2, 0.2 );
            };
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
