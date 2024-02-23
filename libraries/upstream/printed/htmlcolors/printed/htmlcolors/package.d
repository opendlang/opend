/**
Implements CSS Color Module Level 4.

See_also: https://www.w3.org/TR/css-color-4/
Copyright: Guillaume Piolat 2018.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.htmlcolors;

import std.string: format;
import std.conv: to;
import std.math: PI, floor;


pure @safe:

/// Parses a HTML color and gives back a RGBA triplet.
///
/// Params:
///     htmlColorString = A CSS string describing a color.
///
/// Returns:
///     A 32-bit RGBA color, with each component between 0 and 255.
///
/// See_also: https://www.w3.org/TR/css-color-4/
///
///
/// Example:
/// ---
/// import printed.htmlcolors;
/// parseHTMLColor("black");                      // all HTML named colors
/// parseHTMLColor("#fe85dc");                    // hex colors including alpha versions
/// parseHTMLColor("rgba(64, 255, 128, 0.24)");   // alpha
/// parseHTMLColor("rgb(9e-1, 50%, 128)");        // percentage, floating-point
/// parseHTMLColor("hsl(120deg, 25%, 75%)");      // hsv colors
/// parseHTMLColor("gray(0.5)");                  // gray colors
/// parseHTMLColor(" rgb ( 245 , 112 , 74 )  ");  // strips whitespace
/// ---
///
ubyte[4] parseHTMLColor(const(char)[] htmlColorString)
{
    string s = htmlColorString.idup;

    // Add a terminal char (we chose zero)
    // PERF: remove that allocation
    s ~= '\0';
    
    int index = 0;    

    char peek() pure @safe
    {
        return s[index];
    }

    void next() pure @safe
    {
        index++;
    }

    bool parseChar(char ch) pure @safe
    {
        if (peek() == ch)
        {
            next;
            return true;
        }
        return false;
    }

    void expectChar(char ch) pure @safe
    {
        if (!parseChar(ch))
            throw new Exception(format("Expected char %s in color string", ch));
    }

    bool parseString(string s) pure @safe
    {
        int save = index;

        for (int i = 0; i < s.length; ++i)
        {
            if (!parseChar(s[i]))
            {
                index = save;
                return false;
            }
        }
        return true;
    }

    bool isWhite(char ch) pure @safe
    {
        return ch == ' ';
    }

    bool isDigit(char ch) pure @safe
    {
        return ch >= '0' && ch <= '9';
    }

    char expectDigit() pure @safe
    {
        char ch = peek();
        if (isDigit(ch))
        {            
            next;
            return ch;
        }
        else
            throw new Exception("Expected digit 0-9");
    }

    bool parseHexDigit(out int digit) pure @safe
    {
        char ch = peek();
        if (isDigit(ch))
        {
            next;
            digit = ch - '0';
            return true;
        }
        else if (ch >= 'a' && ch <= 'f')
        {
            next;
            digit = 10 + (ch - 'a');
            return true;
        }
        else if (ch >= 'A' && ch <= 'F')
        {
            next;
            digit = 10 + (ch - 'A');
            return true;
        }
        else
            return false;
    }

    void skipWhiteSpace() pure @safe
    {       
        while (isWhite(peek()))
            next;
    }

    void expectPunct(char ch) pure @safe
    {
        skipWhiteSpace();
        expectChar(ch);
        skipWhiteSpace();
    }

    ubyte clamp0to255(int a) pure @safe
    {
        if (a < 0) return 0;
        if (a > 255) return 255;
        return cast(ubyte)a;
    }

    // See: https://www.w3.org/TR/css-syntax/#consume-a-number
    double parseNumber() pure @safe
    {
        string repr = ""; // PERF: fixed size buffer or reusing input string
        if (parseChar('+'))
        {}
        else if (parseChar('-'))
        {
            repr ~= '-';
        }
        while(isDigit(peek()))
        {
            repr ~= peek();
            next;
        }
        if (peek() == '.')
        {
            repr ~= '.';
            next;
            repr ~= expectDigit();
            while(isDigit(peek()))
            {
                repr ~= peek();
                next;
            }
        }
        if (peek() == 'e' || peek() == 'E')
        {
            repr ~= 'e';
            next;
            if (parseChar('+'))
            {}
            else if (parseChar('-'))
            {
                repr ~= '-';
            }
            while(isDigit(peek()))
            {
                repr ~= peek();
                next;
            }
        }
        return to!double(repr);
    }

    ubyte parseColorValue(double range = 255.0) pure @safe
    {
        double num = parseNumber();
        bool isPercentage = parseChar('%');
        if (isPercentage)
            num *= (255.0 / 100.0);
        int c = cast(int)(0.5 + num); // round
        return clamp0to255(c);
    }

    ubyte parseOpacity() pure @safe
    {
        double num = parseNumber();
        bool isPercentage = parseChar('%');
        if (isPercentage)
            num *= 0.01;
        int c = cast(int)(0.5 + num * 255.0);
        return clamp0to255(c);
    }

    double parsePercentage() pure @safe
    {
        double num = parseNumber();
        expectChar('%');
        return num *= 0.01;
    }

    double parseHueInDegrees() pure @safe
    {
        double num = parseNumber();
        if (parseString("deg"))
            return num;
        else if (parseString("rad"))
            return num * 360.0 / (2 * PI);
        else if (parseString("turn"))
            return num * 360.0;
        else if (parseString("grad"))
            return num * 360.0 / 400.0;
        else
        {
            // assume degrees
            return num;
        }
    }

    skipWhiteSpace();

    ubyte red, green, blue, alpha = 255;

    if (parseChar('#'))
    {
       int[8] digits;
       int numDigits = 0;
       for (int i = 0; i < 8; ++i)
       {
          if (parseHexDigit(digits[i]))
              numDigits++;
          else
            break;
       }
       switch(numDigits)
       {
       case 4:
           alpha  = cast(ubyte)( (digits[3] << 4) | digits[3]);
           goto case 3;
       case 3:
           red   = cast(ubyte)( (digits[0] << 4) | digits[0]);
           green = cast(ubyte)( (digits[1] << 4) | digits[1]);
           blue  = cast(ubyte)( (digits[2] << 4) | digits[2]);
           break;
       case 8:
           alpha  = cast(ubyte)( (digits[6] << 4) | digits[7]);
           goto case 6;
       case 6:
           red   = cast(ubyte)( (digits[0] << 4) | digits[1]);
           green = cast(ubyte)( (digits[2] << 4) | digits[3]);
           blue  = cast(ubyte)( (digits[4] << 4) | digits[5]);
           break;
       default:
           throw new Exception("Expected 3, 4, 6 or 8 digit in hexadecimal color literal");
       }
    }
    else if (parseString("gray"))
    {
        
        skipWhiteSpace();
        if (!parseChar('('))
        {
            // This is named color "gray"
            red = green = blue = 128;
        }
        else
        {
            skipWhiteSpace();
            red = green = blue = parseColorValue();
            skipWhiteSpace();
            if (parseChar(','))
            {
                // there is an alpha value
                skipWhiteSpace();
                alpha = parseOpacity();
            }
            expectPunct(')');
        }
    }
    else if (parseString("rgb"))
    {
        bool hasAlpha = parseChar('a');
        expectPunct('(');
        red = parseColorValue();
        expectPunct(',');
        green = parseColorValue();
        expectPunct(',');
        blue = parseColorValue();
        if (hasAlpha)
        {
            expectPunct(',');
            alpha = parseOpacity();
        }
        expectPunct(')');
    }
    else if (parseString("hsl"))
    {
        bool hasAlpha = parseChar('a');
        expectPunct('(');
        double hueDegrees = parseHueInDegrees();
        // Convert to turns
        double hueTurns = hueDegrees / 360.0;
        hueTurns -= floor(hueTurns); // take remainder
        double hue = 6.0 * hueTurns;
        expectPunct(',');
        double sat = parsePercentage();
        expectPunct(',');
        double light = parsePercentage();

        if (hasAlpha)
        {
            expectPunct(',');
            alpha = parseOpacity();
        }
        expectPunct(')');
        double[3] rgb = convertHSLtoRGB(hue, sat, light);
        red   = clamp0to255( cast(int)(0.5 + 255.0 * rgb[0]) );
        green = clamp0to255( cast(int)(0.5 + 255.0 * rgb[1]) );
        blue  = clamp0to255( cast(int)(0.5 + 255.0 * rgb[2]) );
    }
    else
    {
        // Initiate a binary search inside the sorted named color array
        // See_also: https://en.wikipedia.org/wiki/Binary_search_algorithm

        // Current search range
        // this range will only reduce because the color names are sorted
        int L = 0;
        int R = cast(int)(namedColorKeywords.length); 
        int charPos = 0;

        matchloop:
        while (true)
        {
            // Expect 
            char ch = peek();
            if (ch >= 'A' && ch <= 'Z')
                ch += ('a' - 'A');
            if (ch < 'a' || ch > 'z') // not alpha?
            {
                // Examine all alive cases. Select the one which have matched entirely.               
                foreach(color; L..R)
                {
                    if (namedColorKeywords[color].length == charPos)// found it, return as there are no duplicates
                    {
                        // If we have matched all the alpha of the only remaining candidate, we have found a named color
                        uint rgba = namedColorValues[color];
                        red   = (rgba >> 24) & 0xff;
                        green = (rgba >> 16) & 0xff;
                        blue  = (rgba >>  8) & 0xff;
                        alpha = (rgba >>  0) & 0xff;
                        break matchloop;
                    }
                }
                throw new Exception(format("Unexpected char %s in named color", ch));
            }
            next;

            // PERF: there could be something better with a dichotomy
            // PERF: can elid search once we've passed the last match
            bool firstFound = false;
            int firstFoundIndex = R;
            int lastFoundIndex = -1;
            foreach(color; L..R)
            {
                // Have we found ch in name[charPos] position?
                string candidate = namedColorKeywords[color];
                bool charIsMatching = (candidate.length > charPos) && (candidate[charPos] == ch);
                if (!firstFound && charIsMatching)
                {
                    firstFound = true;
                    firstFoundIndex = color;
                }
                if (charIsMatching)
                    lastFoundIndex = color;
            }

            // Zero candidate remain
            if (lastFoundIndex < firstFoundIndex)
                throw new Exception("Can't recognize color string '%s'", s);
            else
            {
                // Several candidate remain, go on and reduce the search range
                L = firstFoundIndex;
                R = lastFoundIndex + 1;
                charPos += 1;
            }
        }
    }

    skipWhiteSpace();
    if (!parseChar('\0'))
        throw new Exception("Expected end of input at the end of color string");

    return [ red, green, blue, alpha];
}

private:

// 147 predefined color + "transparent"
static immutable string[147 + 1] namedColorKeywords =
[
    "aliceblue", "antiquewhite", "aqua", "aquamarine",     "azure", "beige", "bisque", "black",
    "blanchedalmond", "blue", "blueviolet", "brown",       "burlywood", "cadetblue", "chartreuse", "chocolate",
    "coral", "cornflowerblue", "cornsilk", "crimson",      "cyan", "darkblue", "darkcyan", "darkgoldenrod",
    "darkgray", "darkgreen", "darkgrey", "darkkhaki",      "darkmagenta", "darkolivegreen", "darkorange", "darkorchid",
    "darkred","darksalmon","darkseagreen","darkslateblue", "darkslategray", "darkslategrey", "darkturquoise", "darkviolet",
    "deeppink", "deepskyblue", "dimgray", "dimgrey",       "dodgerblue", "firebrick", "floralwhite", "forestgreen",
    "fuchsia", "gainsboro", "ghostwhite", "gold",          "goldenrod", "gray", "green", "greenyellow",
    "grey", "honeydew", "hotpink", "indianred",            "indigo", "ivory", "khaki", "lavender",
    "lavenderblush","lawngreen","lemonchiffon","lightblue","lightcoral", "lightcyan", "lightgoldenrodyellow", "lightgray",
    "lightgreen", "lightgrey", "lightpink", "lightsalmon", "lightseagreen", "lightskyblue", "lightslategray", "lightslategrey",
    "lightsteelblue", "lightyellow", "lime", "limegreen",  "linen", "magenta", "maroon", "mediumaquamarine",
    "mediumblue", "mediumorchid", "mediumpurple", "mediumseagreen", "mediumslateblue", "mediumspringgreen", "mediumturquoise", "mediumvioletred",
    "midnightblue", "mintcream", "mistyrose", "moccasin",  "navajowhite", "navy", "oldlace", "olive",
    "olivedrab", "orange", "orangered",  "orchid",         "palegoldenrod", "palegreen", "paleturquoise", "palevioletred",
    "papayawhip", "peachpuff", "peru", "pink",             "plum", "powderblue", "purple", "red",
    "rosybrown", "royalblue", "saddlebrown", "salmon",     "sandybrown", "seagreen", "seashell", "sienna",
    "silver", "skyblue", "slateblue", "slategray",         "slategrey", "snow", "springgreen", "steelblue",
    "tan", "teal", "thistle", "tomato",                    "transparent", "turquoise", "violet", "wheat", 
    "white", "whitesmoke", "yellow", "yellowgreen"
];

immutable static uint[147 + 1] namedColorValues =
[
    0xf0f8ffff, 0xfaebd7ff, 0x00ffffff, 0x7fffd4ff, 0xf0ffffff, 0xf5f5dcff, 0xffe4c4ff, 0x000000ff, 
    0xffebcdff, 0x0000ffff, 0x8a2be2ff, 0xa52a2aff, 0xdeb887ff, 0x5f9ea0ff, 0x7fff00ff, 0xd2691eff, 
    0xff7f50ff, 0x6495edff, 0xfff8dcff, 0xdc143cff, 0x00ffffff, 0x00008bff, 0x008b8bff, 0xb8860bff, 
    0xa9a9a9ff, 0x006400ff, 0xa9a9a9ff, 0xbdb76bff, 0x8b008bff, 0x556b2fff, 0xff8c00ff, 0x9932ccff, 
    0x8b0000ff, 0xe9967aff, 0x8fbc8fff, 0x483d8bff, 0x2f4f4fff, 0x2f4f4fff, 0x00ced1ff, 0x9400d3ff, 
    0xff1493ff, 0x00bfffff, 0x696969ff, 0x696969ff, 0x1e90ffff, 0xb22222ff, 0xfffaf0ff, 0x228b22ff, 
    0xff00ffff, 0xdcdcdcff, 0xf8f8ffff, 0xffd700ff, 0xdaa520ff, 0x808080ff, 0x008000ff, 0xadff2fff, 
    0x808080ff, 0xf0fff0ff, 0xff69b4ff, 0xcd5c5cff, 0x4b0082ff, 0xfffff0ff, 0xf0e68cff, 0xe6e6faff, 
    0xfff0f5ff, 0x7cfc00ff, 0xfffacdff, 0xadd8e6ff, 0xf08080ff, 0xe0ffffff, 0xfafad2ff, 0xd3d3d3ff, 
    0x90ee90ff, 0xd3d3d3ff, 0xffb6c1ff, 0xffa07aff, 0x20b2aaff, 0x87cefaff, 0x778899ff, 0x778899ff, 
    0xb0c4deff, 0xffffe0ff, 0x00ff00ff, 0x32cd32ff, 0xfaf0e6ff, 0xff00ffff, 0x800000ff, 0x66cdaaff, 
    0x0000cdff, 0xba55d3ff, 0x9370dbff, 0x3cb371ff, 0x7b68eeff, 0x00fa9aff, 0x48d1ccff, 0xc71585ff, 
    0x191970ff, 0xf5fffaff, 0xffe4e1ff, 0xffe4b5ff, 0xffdeadff, 0x000080ff, 0xfdf5e6ff, 0x808000ff, 
    0x6b8e23ff, 0xffa500ff, 0xff4500ff, 0xda70d6ff, 0xeee8aaff, 0x98fb98ff, 0xafeeeeff, 0xdb7093ff, 
    0xffefd5ff, 0xffdab9ff, 0xcd853fff, 0xffc0cbff, 0xdda0ddff, 0xb0e0e6ff, 0x800080ff, 0xff0000ff, 
    0xbc8f8fff, 0x4169e1ff, 0x8b4513ff, 0xfa8072ff, 0xf4a460ff, 0x2e8b57ff, 0xfff5eeff, 0xa0522dff,
    0xc0c0c0ff, 0x87ceebff, 0x6a5acdff, 0x708090ff, 0x708090ff, 0xfffafaff, 0x00ff7fff, 0x4682b4ff, 
    0xd2b48cff, 0x008080ff, 0xd8bfd8ff, 0xff6347ff, 0x00000000,  0x40e0d0ff, 0xee82eeff, 0xf5deb3ff, 
    0xffffffff, 0xf5f5f5ff, 0xffff00ff, 0x9acd32ff,
];


// Reference: https://www.w3.org/TR/css-color-4/#hsl-to-rgb
// this algorithm assumes that the hue has been normalized to a number in the half-open range [0, 6), 
// and the saturation and lightness have been normalized to the range [0, 1]. 
double[3] convertHSLtoRGB(double hue, double sat, double light) 
{
    double t2;
    if( light <= .5 ) 
        t2 = light * (sat + 1);
    else 
        t2 = light + sat - (light * sat);
    double t1 = light * 2 - t2;
    double r = convertHueToRGB(t1, t2, hue + 2);
    double g = convertHueToRGB(t1, t2, hue);
    double b = convertHueToRGB(t1, t2, hue - 2);
    return [r, g, b];
}

double convertHueToRGB(double t1, double t2, double hue) 
{
    if (hue < 0) 
        hue = hue + 6;
    if (hue >= 6) 
        hue = hue - 6;
    if (hue < 1) 
        return (t2 - t1) * hue + t1;
    else if(hue < 3) 
        return t2;
    else if(hue < 4) 
        return (t2 - t1) * (4 - hue) + t1;
    else 
        return t1;
}

unittest
{
    bool doesntParse(string color)
    {
        try
        {
            parseHTMLColor(color);
            return false;
        }
        catch(Exception e)
        {
            return true;
        }
    }

    assert(doesntParse(""));

    // #hex colors    
    assert(parseHTMLColor("#aB9")      == [0xaa, 0xBB, 0x99, 255]);
    assert(parseHTMLColor("#aB98")     == [0xaa, 0xBB, 0x99, 0x88]);
    assert(doesntParse("#"));
    assert(doesntParse("#ab"));
    assert(parseHTMLColor(" #0f1c4A ")   == [0x0f, 0x1c, 0x4a, 255]);    
    assert(parseHTMLColor(" #0f1c4A43 ") == [0x0f, 0x1c, 0x4A, 0x43]);
    assert(doesntParse("#0123456"));
    assert(doesntParse("#012345678"));

    // rgb() and rgba()
    assert(parseHTMLColor("  rgba( 14.01, 25.0e+0%, 16, 0.5)  ") == [14, 64, 16, 128]);
    assert(parseHTMLColor("rgb(10e3,112,-3.4e-2)")               == [255, 112, 0, 255]);

    // hsl() and hsla()
    assert(parseHTMLColor("hsl(0   ,  100%, 50%)")        == [255, 0, 0, 255]);
    assert(parseHTMLColor("hsl(720,  100%, 50%)")         == [255, 0, 0, 255]);
    assert(parseHTMLColor("hsl(180deg,  100%, 50%)")      == [0, 255, 255, 255]);
    assert(parseHTMLColor("hsl(0grad, 100%, 50%)")        == [255, 0, 0, 255]);
    assert(parseHTMLColor("hsl(0rad,  100%, 50%)")        == [255, 0, 0, 255]);
    assert(parseHTMLColor("hsl(0turn, 100%, 50%)")        == [255, 0, 0, 255]);
    assert(parseHTMLColor("hsl(120deg, 100%, 50%)")       == [0, 255, 0, 255]);
    assert(parseHTMLColor("hsl(123deg,   2.5%, 0%)")      == [0, 0, 0, 255]);
    assert(parseHTMLColor("hsl(5.4e-5rad, 25%, 100%)")    == [255, 255, 255, 255]);
    assert(parseHTMLColor("hsla(0turn, 100%, 50%, 0.25)") == [255, 0, 0, 64]);

    // gray values
    assert(parseHTMLColor(" gray( +0.0% )")      == [0, 0, 0, 255]);
    assert(parseHTMLColor(" gray ")              == [128, 128, 128, 255]);
    assert(parseHTMLColor(" gray( 100%, 50% ) ") == [255, 255, 255, 128]);

    // Named colors
    assert(parseHTMLColor("tRaNsPaREnt") == [0, 0, 0, 0]);
    assert(parseHTMLColor(" navy ") == [0, 0, 128, 255]);
    assert(parseHTMLColor("lightgoldenrodyellow") == [250, 250, 210, 255]);
    assert(doesntParse("animaginarycolorname")); // unknown named color
    assert(doesntParse("navyblahblah")); // too much chars
    assert(doesntParse("blac")); // incomplete color
    assert(parseHTMLColor("lime") == [0, 255, 0, 255]); // termination with 2 candidate alive
    assert(parseHTMLColor("limegreen") == [50, 205, 50, 255]);    
}