// Written in the D programming language.

/**
    This module implements HSV, HSL, HSI, HCY _color types.

    Authors:    Manu Evans
    Copyright:  Copyright (c) 2015, Manu Evans.
    License:    $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Source:     $(PHOBOSSRC std/experimental/color/hsx.d)
*/
module std.experimental.color.hsx;

import std.experimental.color;
import std.experimental.color.colorspace : RGBColorSpace;

import std.traits : isInstanceOf, isFloatingPoint, isUnsigned;
import std.typetuple : TypeTuple;

@safe pure nothrow @nogc:

/**
Detect whether $(D T) is a member of the HSx color family.
*/
enum isHSx(T) = isInstanceOf!(HSx, T);

///
unittest
{
    static assert(isHSx!(HSV!ushort) == true);
    static assert(isHSx!string == false);
}

/**
Alias for a HSV (HSB) color.
*/
alias HSV(CT = float, RGBColorSpace cs = RGBColorSpace.sRGB) = HSx!(HSxType.HSV, CT, cs);

/**
Alias for a HSL color.
*/
alias HSL(CT = float, RGBColorSpace cs = RGBColorSpace.sRGB) = HSx!(HSxType.HSL, CT, cs);

/**
Alias for a HSI color.
*/
alias HSI(CT = float, RGBColorSpace cs = RGBColorSpace.sRGB) = HSx!(HSxType.HSI, CT, cs);

/**
Alias for a HCY' color.
*/
alias HCY(CT = float, RGBColorSpace cs = RGBColorSpace.sRGB) = HSx!(HSxType.HCY, CT, cs);

/**
Define a HSx family colour type.
*/
enum HSxType
{
    /** Hue-saturation-value (aka HSB: Hue-saturation-brightness) */
    HSV,
    /** Hue-saturation-lightness */
    HSL,
    /** Hue-saturation-intensity */
    HSI,
    /** Hue-chroma-luma */
    HCY
}

/**
HSx color space is used to describe a suite of angular color spaces including HSL, HSV, HSI, HSY.
*/
struct HSx(HSxType type_, CT = float, RGBColorSpace colorSpace_ = RGBColorSpace.sRGB) if(isFloatingPoint!CT || isUnsigned!CT)
{
@safe pure nothrow @nogc:

    /** Type of the color components. */
    alias ComponentType = CT;
    /** The color space specified. */
    enum colorSpace = colorSpace_;
    /** The color type from the HSx family. */
    enum type = type_;

    // mixin the color channels according to the type
    mixin("CT " ~ Components!type[0] ~ " = 0;");
    mixin("CT " ~ Components!type[1] ~ " = 0;");
    mixin("CT " ~ Components!type[2] ~ " = 0;");

    /** Cast to other color types */
    Color opCast(Color)() const if(isColor!Color)
    {
        return convertColor!Color(this);
    }

    // operators
    mixin ColorOperators!(Components!type);


package:

    alias ParentColor = RGB!("rgb", CT, false, colorSpace_);

    static To convertColorImpl(To, From)(From color) if(isHSx!From && isHSx!To)
    {
        // HACK: cast through RGB (this works fine, but could be faster)
        return convertColorImpl!(To)(convertColorImpl!(From.ParentColor)(color));
    }
    unittest
    {
        static assert(convertColorImpl!(HSL!float)(HSV!float(60, 1, 1)) == HSL!float(60, 1, 0.5));

        static assert(convertColorImpl!(HSV!float)(HSL!float(60, 1, 0.5)) == HSV!float(60, 1, 1));

        static assert(convertColorImpl!(HSI!float)(HSV!float(0, 1, 1)) == HSI!float(0, 1, 1.0/3.0));
        static assert(convertColorImpl!(HSI!float)(HSV!float(60, 1, 1)) == HSI!float(60, 1, 2.0/3.0));

        // TODO: HCY (needs approx ==)
    }

    static To convertColorImpl(To, From)(From color) if(isHSx!From && isRGB!To)
    {
        import std.math : abs;

        alias ToType = To.ComponentType;
        alias WT = FloatTypeFor!ToType;

        auto c = color.tupleof;
        WT h = cast(WT)c[0];
        WT s = cast(WT)c[1];
        WT x = cast(WT)c[2];

        WT C, m;
        static if(From.type == HSxType.HSV)
        {
            C = x*s;
            m = x - C;
        }
        else static if(From.type == HSxType.HSL)
        {
            C = (1 - abs(2*x - 1))*s;
            m = x - C/2;
        }
        else static if(From.type == HSxType.HSI)
        {
            C = s;
            m = x - (r+g+b)*WT(1.0/3.0);
        }
        else static if(From.type == HSxType.HCY)
        {
            C = s;
        }

        WT H = h/60;
        WT X = C*(1 - abs(H%2.0 - 1));

        WT r, g, b;
        if(H < 1)
            r = C, g = X, b = 0;
        else if(H < 2)
            r = X, g = C, b = 0;
        else if(H < 3)
            r = 0, g = C, b = X;
        else if(H < 4)
            r = 0, g = X, b = C;
        else if(H < 5)
            r = X, g = 0, b = C;
        else if(H < 6)
            r = C, g = 0, b = X;

        static if(From.type == HSxType.HCY)
        {
            enum YAxis = RGBColorSpaceMatrix!(From.colorSpace, WT)[1];
            m = x - (YAxis[0]*r + YAxis[1]*g + YAxis[2]*b); // Derive from Luma'
        }

        return To(cast(ToType)(r+m), cast(ToType)(g+m), cast(ToType)(b+m));
    }
    unittest
    {
        static assert(convertColorImpl!(RGB8)(HSV!float(0, 1, 1)) == RGB8(255, 0, 0));
        static assert(convertColorImpl!(RGB8)(HSV!float(60, 0.5, 0.5)) == RGB8(128, 128, 64));

        static assert(convertColorImpl!(RGB8)(HSL!float(0, 1, 0.5)) == RGB8(255, 0, 0));
        static assert(convertColorImpl!(RGB8)(HSL!float(60, 0.5, 0.5)) == RGB8(191, 191, 64));

//        static assert(convertColorImpl!(RGB8)(HSI!float(0, 1, 1)) == RGB8(1, 0, 0));

//        pragma(msg, convertColorImpl!(RGB8)(HCY!float(0, 0, 1)));
//        static assert(convertColorImpl!(RGB8)(HCY!float(0, 1, 1)) == RGB8(1, 0, 0));
    }

    static To convertColorImpl(To, From)(From color) if(isRGB!From && isHSx!To)
    {
        import std.algorithm : min, max;
        import std.math : abs;

        alias ToType = To.ComponentType;
        alias WT = FloatTypeFor!ToType;

        auto c = color.tristimulus;
        WT r = cast(WT)c[0];
        WT g = cast(WT)c[1];
        WT b = cast(WT)c[2];

        WT M = max(r, g, b);
        WT m = min(r, g, b);
        WT C = M-m;

        // Calculate Hue
        WT h;
        if(C == 0)
            h = 0;
        else if(M == r)
            h = WT(60) * ((g-b)/C % WT(6));
        else if(M == g)
            h = WT(60) * ((b-r)/C + WT(2));
        else if(M == b)
            h = WT(60) * ((r-g)/C + WT(4));

        WT s, x;
        static if(To.type == HSxType.HSV)
        {
            x = M; // 'Value'
            s = x == 0 ? WT(0) : C/x; // Saturation
        }
        else static if(To.type == HSxType.HSL)
        {
            x = (M + m)/WT(2); // Lightness
            s = (x == 0 || x == 1) ? WT(0) : C/(1 - abs(2*x - 1)); // Saturation
        }
        else static if(To.type == HSxType.HSI)
        {
            x = (r + g + b)/WT(3); // Intensity
            s = x == 0 ? WT(0) : 1 - m/x; // Saturation
        }
        else static if(To.type == HSxType.HCY)
        {
            enum YAxis = RGBColorSpaceMatrix!(To.colorSpace, WT)[1];
            x = YAxis[0]*r + YAxis[1]*g + YAxis[2]*b; // Luma'
            s = C; // Chroma
        }

        return To(cast(ToType)h, cast(ToType)s, cast(ToType)x);
    }
    unittest
    {
        static assert(convertColorImpl!(HSV!float)(RGB8(255, 0, 0)) == HSV!float(0, 1, 1));
        static assert(convertColorImpl!(HSL!float)(RGB8(255, 0, 0)) == HSL!float(0, 1, 0.5));
        static assert(convertColorImpl!(HSI!float)(RGB8(255, 0, 0)) == HSI!float(0, 1, 1.0/3));
        static assert(convertColorImpl!(HSI!float)(RGB8(255, 255, 0)) == HSI!float(60, 1, 2.0/3));
//        static assert(convertColorImpl!(HCY!float)(RGB8(255, 0, 0)) == HCY!float(0, 1, 1));
    }

private:
    template Components(HSxType type)
    {
        static if(type == HSxType.HSV)
            alias Components = TypeTuple!("h","s","v");
        else static if(type == HSxType.HSL)
            alias Components = TypeTuple!("h","s","l");
        else static if(type == HSxType.HSI)
            alias Components = TypeTuple!("h","s","i");
        else static if(type == HSxType.HCY)
            alias Components = TypeTuple!("h","c","y");
    }
}

///
unittest
{
    // HSV color with float components
    alias HSVf = HSV!float;

    HSVf c = HSVf(3.1415, 1, 0.5);

    // test HSV operators and functions
    static assert(HSVf(3.1415, 0.2, 0.5) + HSVf(0, 0.5, 0.5) == HSVf(3.1415, 0.7, 1));
    static assert(HSVf(2, 0.5, 1) * 100.0 == HSVf(200, 50, 100));
}
///
unittest
{
    // HSL color with float components
    alias HSLf = HSL!float;

    HSLf c = HSLf(3.1415, 1, 0.5);

    // test HSL operators and functions
    static assert(HSLf(3.1415, 0.2, 0.5) + HSLf(0, 0.5, 0.5) == HSLf(3.1415, 0.7, 1));
    static assert(HSLf(2, 0.5, 1) * 100.0 == HSLf(200, 50, 100));
}
///
unittest
{
    // HSI color with float components
    alias HSIf = HSI!float;

    HSIf c = HSIf(3.1415, 1, 0.5);

    // test HSI operators and functions
    static assert(HSIf(3.1415, 0.2, 0.5) + HSIf(0, 0.5, 0.5) == HSIf(3.1415, 0.7, 1));
    static assert(HSIf(2, 0.5, 1) * 100.0 == HSIf(200, 50, 100));
}
///
unittest
{
    // HCY color with float components
    alias HCYf = HCY!float;

    HCYf c = HCYf(3.1415, 1, 0.5);

    // test HCY operators and functions
    static assert(HCYf(3.1415, 0.2, 0.5) + HCYf(0, 0.5, 0.5) == HCYf(3.1415, 0.7, 1));
    static assert(HCYf(2, 0.5, 1) * 100.0 == HCYf(200, 50, 100));
}
