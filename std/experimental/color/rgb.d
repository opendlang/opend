// Written in the D programming language.

/**
    This module implements the RGB _color type.

    Authors:    Manu Evans
    Copyright:  Copyright (c) 2015, Manu Evans.
    License:    $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Source:     $(PHOBOSSRC std/experimental/color/rgb.d)
*/
module std.experimental.color.rgb;

import std.experimental.color;
import std.experimental.color.colorspace;
import std.experimental.color.xyz : XYZ, isXYZ;
import std.experimental.normint;

import std.traits : isInstanceOf, isNumeric, isIntegral, isFloatingPoint, isSomeChar;
import std.typetuple : TypeTuple;
import std.typecons : tuple;

@safe pure nothrow @nogc:


/**
Detect whether $(D T) is an RGB color.
*/
enum isRGB(T) = isInstanceOf!(RGB, T);

///
unittest
{
    static assert(isRGB!(RGB!("bgr", ushort)) == true);
    static assert(isRGB!LA8 == true);
    static assert(isRGB!int == false);
}


// DEBATE: which should it be?
template defaultAlpha(T)
{
/+
    enum defaultAlpha = isFloatingPoint!T ? T(1) : T.max;
+/
    enum defaultAlpha = T(0);
}


/**
An RGB color, parameterised with components, component type, and color space specification.

Params: components_ = Components that shall be available. Struct is populated with components in the order specified.
                      Valid components are:
                        "r" = red
                        "g" = green
                        "b" = blue
                        "a" = alpha
                        "l" = luminance
                        "x" = placeholder/padding (no significant value)
        ComponentType_ = Type for the color channels. May be a basic integer or floating point type.
        linear_ = Color is stored with linear luminance.
        colorSpace_ = Color will be within the specified color space.
*/
struct RGB(string components_, ComponentType_, bool linear_ = false, RGBColorSpace colorSpace_ = RGBColorSpace.sRGB)
    if(isNumeric!ComponentType_)
{
@safe pure nothrow @nogc:

    // RGB colors may only contain components 'rgb', or 'l' (luminance)
    // They may also optionally contain an 'a' (alpha) component, and 'x' (unused) components
    static assert(allIn!("rgblax", components), "Invalid Color component '"d ~ notIn!("rgblax", components) ~ "'. RGB colors may only contain components: r, g, b, l, a, x"d);
    static assert(anyIn!("rgbal", components), "RGB colors must contain at least one component of r, g, b, l, a.");
    static assert(!canFind!(components, 'l') || !anyIn!("rgb", components), "RGB colors may not contain rgb AND luminance components together.");

    static if(isFloatingPoint!ComponentType_)
    {
        /** Type of the color components. */
        alias ComponentType = ComponentType_;
    }
    else
    {
        /** Type of the color components. */
        alias ComponentType = NormalizedInt!ComponentType_;
    }

    /** The color components that were specified. */
    enum string components = components_;
    /** The color space specified. */
    enum RGBColorSpace colorSpace = colorSpace_;
    /** If the color is stored linearly (without gamma applied). */
    enum bool linear = linear_;


    // mixin will emit members for components
    template Components(string components)
    {
        static if(components.length == 0)
            enum Components = "";
        else
            enum Components = ComponentType.stringof ~ ' ' ~ components[0] ~ " = 0;\n" ~ Components!(components[1..$]);
    }
    mixin(Components!components);

    /** Test if a particular component is present. */
    enum bool hasComponent(char c) = mixin("is(typeof(this."~c~"))");
    /** If the color has alpha. */
    enum bool hasAlpha = hasComponent!'a';


    /** Return the RGB tristimulus values as a tuple.
        These will always be ordered (R, G, B).
        Any color channels not present will be 0. */
    @property auto tristimulus() const
    {
        static if(hasComponent!'l')
        {
            return tuple(l, l, l);
        }
        else
        {
            static if(!hasComponent!'r')
                enum r = ComponentType(0);
            static if(!hasComponent!'g')
                enum g = ComponentType(0);
            static if(!hasComponent!'b')
                enum b = ComponentType(0);
            return tuple(r, g, b);
        }
    }
    ///
    unittest
    {
        // BGR color
        auto c = BGR8(255, 128, 10);

        // tristimulus always returns tuple in RGB order
        assert(c.tristimulus == tuple(10, 128, 255));
    }

    /** Return the RGB tristimulus values + alpha as a tuple.
        These will always be ordered (R, G, B, A). */
    @property auto tristimulusWithAlpha() const
    {
        static if(!hasAlpha)
            enum a = defaultAlpha!ComponentType;
        return tuple(tristimulus.expand, a);
    }
    ///
    unittest
    {
        // BGRA color
        auto c = BGRA8(255, 128, 10, 80);

        // tristimulusWithAlpha always returns tuple in RGBA order
        assert(c.tristimulusWithAlpha == tuple(10, 128, 255, 80));
    }

    /** Construct a color from RGB and optional alpha values. */
    this(ComponentType r, ComponentType g, ComponentType b, ComponentType a = defaultAlpha!ComponentType)
    {
        foreach(c; TypeTuple!("r","g","b","a"))
            mixin(ComponentExpression!("this._ = _;", c, null));
        static if(canFind!(components, 'l'))
            this.l = toGrayscale!(linear, colorSpace)(r, g, b); // ** Contentious? I this this is most useful
    }

    /** Construct a color from a luminance and optional alpha value. */
    this(ComponentType l, ComponentType a = defaultAlpha!ComponentType)
    {
        foreach(c; TypeTuple!("l","r","g","b"))
            mixin(ComponentExpression!("this._ = l;", c, null));
        static if(canFind!(components, 'a'))
            this.a = a;
    }

    static if(!isFloatingPoint!ComponentType_)
    {
        /** Construct a color from RGB and optional alpha values. */
        this(ComponentType.IntType r, ComponentType.IntType g, ComponentType.IntType b, ComponentType.IntType a = defaultAlpha!(ComponentType.IntType))
        {
            foreach(c; TypeTuple!("r","g","b","a"))
                mixin(ComponentExpression!("this._ = ComponentType(_);", c, null));
            static if(canFind!(components, 'l'))
                this.l = toGrayscale!(linear, colorSpace)(ComponentType(r), ComponentType(g), ComponentType(b)); // ** Contentious? I this this is most useful
        }

        /** Construct a color from a luminance and optional alpha value. */
        this(ComponentType.IntType l, ComponentType.IntType a = defaultAlpha!(ComponentType.IntType))
        {
            foreach(c; TypeTuple!("l","r","g","b"))
                mixin(ComponentExpression!("this._ = ComponentType(l);", c, null));
            static if(canFind!(components, 'a'))
                this.a = ComponentType(a);
        }
    }

    /** Construct a color from a hex string. */
    this(C)(const(C)[] hex) if(isSomeChar!C)
    {
        this = colorFromString!(typeof(this))(hex);
    }

    /** Cast to other color types */
    Color opCast(Color)() const if(isColor!Color)
    {
        return convertColor!Color(this);
    }

    // comparison
    bool opEquals(typeof(this) rh) const
    {
        // this is required to exclude 'x' components from equality comparisons
        return tristimulusWithAlpha == rh.tristimulusWithAlpha;
    }

    // operators
    mixin ColorOperators!AllComponents;

    unittest
    {
        alias UnsignedRGB = RGB!("rgb", ubyte);
        alias SignedRGBX = RGB!("rgbx", byte);
        alias FloatRGBA = RGB!("rgba", float);

        // test construction
        static assert(UnsignedRGB("0x908000FF")  == UnsignedRGB(0x80,0,0xFF));
        static assert(FloatRGBA("0x908000FF")    == FloatRGBA(float(0x80)/float(0xFF),0,1,float(0x90)/float(0xFF)));

        // test operators
        static assert(-SignedRGBX(1,2,3) == SignedRGBX(-1,-2,-3));
        static assert(-FloatRGBA(1,2,3)  == FloatRGBA(-1,-2,-3));

        static assert(~UnsignedRGB(1,2,3) == UnsignedRGB(0xFE,0xFD,0xFC));
        static assert(~SignedRGBX(1,2,3)  == SignedRGBX(~1,~2,~3));

        static assert(UnsignedRGB(10,20,30)  + UnsignedRGB(4,5,6) == UnsignedRGB(14,25,36));
        static assert(SignedRGBX(10,20,30)   + SignedRGBX(4,5,6)  == SignedRGBX(14,25,36));
        static assert(FloatRGBA(10,20,30,40) + FloatRGBA(4,5,6,7) == FloatRGBA(14,25,36,47));

        static assert(UnsignedRGB(10,20,30)  - UnsignedRGB(4,5,6) == UnsignedRGB(6,15,24));
        static assert(SignedRGBX(10,20,30)   - SignedRGBX(4,5,6)  == SignedRGBX(6,15,24));
        static assert(FloatRGBA(10,20,30,40) - FloatRGBA(4,5,6,7) == FloatRGBA(6,15,24,33));

        static assert(UnsignedRGB(10,20,30)  * UnsignedRGB(128,128,128) == UnsignedRGB(5,10,15));
        static assert(SignedRGBX(10,20,30)   * SignedRGBX(-64,-64,-64)  == SignedRGBX(-5,-10,-15));
        static assert(FloatRGBA(10,20,30,40) * FloatRGBA(0,1,2,3)       == FloatRGBA(0,20,60,120));

        static assert(UnsignedRGB(10,20,30)  * 2 == UnsignedRGB(20,40,60));
        static assert(SignedRGBX(10,20,30)   * 2 == SignedRGBX(20,40,60));
        static assert(FloatRGBA(10,20,30,40) * 2 == FloatRGBA(20,40,60,80));

        static assert(UnsignedRGB(10,20,30)   / 2 == UnsignedRGB(5,10,15));
        static assert(SignedRGBX(-10,-20,-30) / 2 == SignedRGBX(-5,-10,-15));
        static assert(FloatRGBA(10,20,30,40)  / 2 == FloatRGBA(5,10,15,20));

        static assert(UnsignedRGB(10,20,30)  * 2.0 == UnsignedRGB(20,40,60));
        static assert(SignedRGBX(10,20,30)   * 2.0 == SignedRGBX(20,40,60));
        static assert(FloatRGBA(10,20,30,40) * 2.0 == FloatRGBA(20,40,60,80));

        static assert(UnsignedRGB(10,20,30)  / 0.5 == UnsignedRGB(20,40,60));
        static assert(SignedRGBX(10,20,30)   / 0.5 == SignedRGBX(20,40,60));
        static assert(FloatRGBA(10,20,30,40) / 0.5 == FloatRGBA(20,40,60,80));

        static assert(UnsignedRGB(10,20,30)   / 2.0 == UnsignedRGB(5,10,15));
        static assert(SignedRGBX(-10,-20,-30) / 2.0 == SignedRGBX(-5,-10,-15));
        static assert(FloatRGBA(10,20,30,40)  / 2.0 == FloatRGBA(5,10,15,20));
    }


package:

    alias ParentColor = XYZ!(FloatTypeFor!ComponentType);

    static To convertColorImpl(To, From)(From color) if(isRGB!From && isRGB!To)
    {
        alias ToType = To.ComponentType;
        alias FromType = From.ComponentType;

        auto src = color.tristimulusWithAlpha;

        static if(From.colorSpace == To.colorSpace && From.linear == To.linear)
        {
            // color space is the same, just do type conversion
            return To(cast(ToType)src[0], cast(ToType)src[1], cast(ToType)src[2], cast(ToType)src[3]);
        }
        else
        {
            // unpack the working values
            alias WorkType = WorkingType!(FromType, ToType);
            WorkType r = cast(WorkType)src[0];
            WorkType g = cast(WorkType)src[1];
            WorkType b = cast(WorkType)src[2];

            static if(From.linear == false)
            {
                r = toLinear!(From.colorSpace)(r);
                g = toLinear!(From.colorSpace)(g);
                b = toLinear!(From.colorSpace)(b);
            }
            static if(From.colorSpace != To.colorSpace)
            {
                enum toXYZ = RGBColorSpaceMatrix!(From.colorSpace, WorkType);
                enum toRGB = inverse(RGBColorSpaceMatrix!(To.colorSpace, WorkType));
                enum mat = multiply(toXYZ, toRGB);
                WorkType[3] v = multiply(mat, [r, g, b]);
                r = v[0]; g = v[1]; b = v[2];
            }
            static if(To.linear == false)
            {
                r = toGamma!(To.colorSpace)(r);
                g = toGamma!(To.colorSpace)(g);
                b = toGamma!(To.colorSpace)(b);
            }

            // convert and return the output
            static if(To.hasAlpha)
                return To(cast(ToType)r, cast(ToType)g, cast(ToType)b, cast(ToType)src[3]);
            else
                return To(cast(ToType)r, cast(ToType)g, cast(ToType)b);
        }
    }
    unittest
    {
        // test RGB format conversions
        alias UnsignedRGB = RGB!("rgb", ubyte);
        alias SignedRGBX = RGB!("rgbx", byte);
        alias FloatRGBA = RGB!("rgba", float);

        static assert(convertColorImpl!(UnsignedRGB)(SignedRGBX(0x20,0x30,-10)) == UnsignedRGB(0x40,0x60,0));
        static assert(convertColorImpl!(UnsignedRGB)(FloatRGBA(1,0.5,0,1)) == UnsignedRGB(0xFF,0x80,0));
        static assert(convertColorImpl!(FloatRGBA)(UnsignedRGB(0xFF,0x80,0)) == FloatRGBA(1,float(0x80)/float(0xFF),0,0));
        static assert(convertColorImpl!(FloatRGBA)(SignedRGBX(127,-127,-128)) == FloatRGBA(1,-1,-1,0));

        static assert(convertColorImpl!(UnsignedRGB)(convertColorImpl!(FloatRGBA)(UnsignedRGB(0xFF,0x80,0))) == UnsignedRGB(0xFF,0x80,0));

        // test greyscale conversion
        alias UnsignedL = RGB!("l", ubyte);
        assert(cast(UnsignedL)UnsignedRGB(0xFF,0x20,0x40) == UnsignedL(0x83));

        // TODO: we can't test this properly since DMD can't CTFE the '^^' operator! >_<

        alias sRGBA = RGB!("rgba", ubyte, false, RGBColorSpace.sRGB);

        // test linear conversion
        alias lRGBA = RGB!("rgba", ushort, true, RGBColorSpace.sRGB);
        assert(convertColorImpl!(lRGBA)(sRGBA(0xFF, 0xFF, 0xFF, 0xFF)) == lRGBA(0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF));

        // test gamma conversion
        alias gRGBA = RGB!("rgba", byte, false, RGBColorSpace.sRGB_Gamma2_2);
        assert(convertColorImpl!(gRGBA)(sRGBA(0xFF, 0x80, 0x01, 0xFF)) == gRGBA(0x7F, 0x3F, 0x03, 0x7F));
    }

    static To convertColorImpl(To, From)(From color) if(isRGB!From && isXYZ!To)
    {
        alias ToType = To.ComponentType;
        alias FromType = From.ComponentType;
        alias WorkType = WorkingType!(FromType, ToType);

        // unpack the working values
        auto src = color.tristimulus;
        WorkType r = cast(WorkType)src[0];
        WorkType g = cast(WorkType)src[1];
        WorkType b = cast(WorkType)src[2];

        static if(From.linear == false)
        {
            r = toLinear!(From.colorSpace)(r);
            g = toLinear!(From.colorSpace)(g);
            b = toLinear!(From.colorSpace)(b);
        }

        // transform to XYZ
        enum toXYZ = RGBColorSpaceMatrix!(From.colorSpace, WorkType);
        WorkType[3] v = multiply(toXYZ, [r, g, b]);
        return To(v[0], v[1], v[2]);
    }
    unittest
    {
        // TODO: needs approx ==
    }

    static To convertColorImpl(To, From)(From color) if(isXYZ!From && isRGB!To)
    {
        alias ToType = To.ComponentType;
        alias FromType = From.ComponentType;
        alias WorkType = WorkingType!(FromType, ToType);

        enum toRGB = inverse(RGBColorSpaceMatrix!(To.colorSpace, WorkType));
        WorkType[3] v = multiply(toRGB, [ WorkType(color.X), WorkType(color.Y), WorkType(color.Z) ]);

        static if(To.linear == false)
        {
            v[0] = toGamma!(To.colorSpace)(v[0]);
            v[1] = toGamma!(To.colorSpace)(v[1]);
            v[2] = toGamma!(To.colorSpace)(v[2]);
        }

        return To(cast(ToType)v[0], cast(ToType)v[1], cast(ToType)v[2]);
    }
    unittest
    {
        // TODO: needs approx ==
    }

private:
    alias AllComponents = TypeTuple!("l","r","g","b","a");
}


/** Convert a value from gamma compressed space to linear. */
T toLinear(RGBColorSpace src, T)(T v) if(isFloatingPoint!T)
{
    enum ColorSpace = RGBColorSpaceDefs!T[src];
    return ColorSpace.toLinear(v);
}
/** Convert a value to gamma compressed space. */
T toGamma(RGBColorSpace src, T)(T v) if(isFloatingPoint!T)
{
    enum ColorSpace = RGBColorSpaceDefs!T[src];
    return ColorSpace.toGamma(v);
}

/** Convert a color to linear space. */
auto toLinear(C)(C color) if(isRGB!C)
{
    return cast(RGB!(C.components, C.ComponentType, true, C.colorSpace))color;
}
/** Convert a color to gamma space. */
auto toGamma(C)(C color) if(isRGB!C)
{
    return cast(RGB!(C.components, C.ComponentType, false, C.colorSpace))color;
}


package:

T toGrayscale(bool linear, RGBColorSpace colorSpace = RGBColorSpace.sRGB, T)(T r, T g, T b) pure if(isFloatingPoint!T)
{
    // calculate the luminance (Y) value by multiplying the Y row of the XYZ matrix with the color
    enum YAxis = RGBColorSpaceMatrix!(colorSpace, T)[1];

    static if(linear)
    {
        return YAxis[0]*r + YAxis[1]*g + YAxis[2]*b;
    }
    else
    {
        // sRGB Luma' coefficients match the Y axis. Assume other RGB color spaces also follow the same pattern(?)
        // Rec.709 (HDTV) was also refined to suit, so it will work without special-case
        // TODO: When we support Rec.601 (SDTV), we need to special-case for Luma' coefficients: 0.299, 0.587, 0.114

        return YAxis[0]*r + YAxis[1]*g + YAxis[2]*b;
    }
}
T toGrayscale(bool linear, RGBColorSpace colorSpace = RGBColorSpace.sRGB, T)(T r, T g, T b) pure if(is(T == NormalizedInt!U, U))
{
    alias F = FloatTypeFor!T;
    return T(toGrayscale!(linear, colorSpace)(cast(F)r, cast(F)g, cast(F)b));
}


// helpers to parse color components from color component string
template canFind(string s, char c)
{
    static if(s.length == 0)
        enum canFind = false;
    else
        enum canFind = s[0] == c || canFind!(s[1..$], c);
}
template allIn(string s, string chars)
{
    static if(chars.length == 0)
        enum allIn = true;
    else
        enum allIn = canFind!(s, chars[0]) && allIn!(s, chars[1..$]);
}
template anyIn(string s, string chars)
{
    static if(chars.length == 0)
        enum anyIn = false;
    else
        enum anyIn = canFind!(s, chars[0]) || anyIn!(s, chars[1..$]);
}
template notIn(string s, string chars)
{
    static if(chars.length == 0)
        enum notIn = char(0);
    else static if(!canFind!(s, chars[0]))
        enum notIn = chars[0];
    else
        enum notIn = notIn!(s, chars[1..$]);
}

unittest
{
    static assert(canFind!("string", 'i'));
    static assert(!canFind!("string", 'x'));
    static assert(allIn!("string", "sgi"));
    static assert(!allIn!("string", "sgix"));
    static assert(anyIn!("string", "sx"));
    static assert(!anyIn!("string", "x"));
}
