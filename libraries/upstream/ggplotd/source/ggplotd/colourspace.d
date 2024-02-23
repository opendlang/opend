/**

This module mostly exist to have a bridge with the ggplotd code and the ggplotd.color code. That is because the ggplotd.color code might become part of phobos one day and I don't want to depend directly on ggplotd's implementation, so that it stays easy to switch to an alternative (phobos) based implementation.

*/
module ggplotd.colourspace;

import chsx = std.experimental.color.hsx;
import crgb = std.experimental.color.rgb;
import cxyz = std.experimental.color.xyz;
import cspace = std.experimental.color.colorspace;
import cColor = std.experimental.color;

/// HCY colourspace
alias HCY = chsx.HCY!double;
/// RGB colourspace
alias RGB = crgb.RGB!("rgb",double);
/// RGBA colourspace
alias RGBA = crgb.RGB!("rgba",double);
/// XYZ colourspace
alias XYZ = cxyz.XYZ!double;

/// Convert to another colour space
alias toColourSpace = cspace.convertColor;

/// Check whether it is a colour
alias isColour = cColor.isColor;

import cairo = cairo.cairo;

/// Convert to Cairo colour
cairo.RGBA toCairoRGBA(C)( in C from )
{
    auto rgb = toColourSpace!(RGBA,C)( from );
    return cairo.RGBA(
        rgb.r,
        rgb.g,
        rgb.b,
        rgb.a
    );
}

/// Convert from Cairo colour to specified type (template)
C fromCairoRGBA(C)( in cairo.RGBA crgb )
{
    auto rgba = RGBA( crgb.red, crgb.green, crgb.blue, crgb.alpha );
    return toColourSpace!C( rgba );
}

/// Convert colour to a tuple holding the values
auto toTuple(T : HCY)( T colour )
{
    import std.typecons : Tuple;
    return Tuple!(double, double, double)( colour.h, colour.c, colour.y );
}

/// Convert colour to a tuple holding the values
auto toTuple(T : XYZ)( T colour )
{
    import std.typecons : Tuple;
    return Tuple!(double, double, double)( colour.X, colour.Y, colour.Z );
}

/// Convert colour to a tuple holding the values
auto toTuple(T)( T colour )
{
    import std.typecons : Tuple;
    import std.typecons : Nullable;
    import std.traits : isInstanceOf;
    static if (isInstanceOf!(Nullable, T))
        return Tuple!(double, double, double)( colour.get().r, colour.get().g, colour.get().b );
    else
        return Tuple!(double, double, double)( colour.r, colour.g, colour.b );
}
