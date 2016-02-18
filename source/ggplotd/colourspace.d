/**

This module mostly exist to have a bridge with the ggplotd code and the ggplotd.color code. That is because the ggplotd.color code might become part of phobos one day and I don't want to depend directly on ggplotd's implementation, so that it stays easy to switch to an alternative (phobos) based implementation.

*/
module ggplotd.colourspace;

import chsx = ggplotd.color.hsx;
import crgb = ggplotd.color.rgb;
import cconv = ggplotd.color.conv;
import cColor = ggplotd.color;

alias HCY = chsx.HCY!double;
alias RGB = crgb.RGB!("rgb",double);
alias RGBA = crgb.RGB!("rgba",double);
alias toColourSpace = cconv.convertColor;
alias isColour = cColor.isColor;

import cairo = cairo.cairo;
cairo.RGBA toCairoRGBA(C)( C from )
{
    auto rgb = toColourSpace!(RGBA,C)( from );
    return cairo.RGBA(
        rgb.r, 
        rgb.g, 
        rgb.b, 
        rgb.a 
    );
}

C fromCairoRGBA(C)( cairo.RGBA crgb ) 
{
    auto rgba = RGBA( crgb.red, crgb.green, crgb.blue, crgb.alpha );
    return toColourSpace!C( rgba );
}

auto toTuple(T : HCY)( T colour )
{
    import std.typecons : Tuple;
    return Tuple!(double, double, double)( colour.h, colour.c, colour.y );
}

auto toTuple(T)( T colour )
{
    import std.typecons : Tuple;
    return Tuple!(double, double, double)( colour.r, colour.g, colour.b );
}

