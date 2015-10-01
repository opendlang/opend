module ggplotd.geom;

import cairo.cairo;

version(unittest)
{
    import ggplotd.aes;
}

auto geom_line(AES)( AES aes )
{
    return ( Context context ) 
    {
        context.rectangle( 0.4, 0.4, 0.2, 0.2 );
    };
}

unittest
{
    auto aes = Aes!(double[],double[], string[])( [1.0],[2.0],["c"] );
    auto pl = geom_line( aes );
}
