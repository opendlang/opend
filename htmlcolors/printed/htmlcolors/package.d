/**
Implements CSS Color Module Level 4.

See_also: https://www.w3.org/TR/css-color-4/
Copyright: Guillaume Piolat 2018.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.htmlcolors;

import std.algorithm;
import std.string;
import std.conv;


pure @safe:

/// Parses a HTML color and gives back a RGBA triplet.
/// Currently only some HTML colors are supported.
/// See_also: https://www.w3.org/TR/css-color-4/
///
/// Notes:
///    <color> = <rgb()> | <rgba()> | <hsl()> | <hsla()> |
///              <hwb()> | <gray()> | <device-cmyk()> | <color-mod()> |
///              <hex-color> | <named-color> | 
///              <deprecated-system-color>
///
ubyte[4] parseHTMLColor(string s)
{
    // Add a terminal char (we chose zero)
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

    void expect(char ch) pure @safe
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
        expect(ch);
        skipWhiteSpace();
    }

    ubyte clamp0to255(int a) pure @safe
    {
        if (a < 0) return 0;
        if (a > 255) return 255;
        return cast(ubyte)a;
    }

    ubyte clampOpacity0to255(double alpha) pure @safe
    {
        int c = cast(int)(0.5 + 255.0 * alpha);
        return clamp0to255(c);
    }

    ubyte clampNumber0to255(double i) pure @safe
    {
        int c = cast(int)(0.5 + i);
        return clamp0to255(c);
    }

    // See: https://www.w3.org/TR/css-syntax/#consume-a-number
    double parseNumber()
    {
        string repr = ""; // PERF: fixed size buffer?
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

    ubyte parseColorValue(double range = 255.0)
    {
        double num = parseNumber();
        bool isPercentage = parseChar('%');
        if (isPercentage)
            num *= (255.0 / 100.0);
        int c = cast(int)(0.5 + num); // round
        return clamp0to255(c);
    }

    ubyte parseOpacity()
    {
        double num = parseNumber();
        bool isPercentage = parseChar('%');
        if (isPercentage)
            num *= 0.01;
        int c = cast(int)(0.5 + num * 255.0);
        return clamp0to255(c);
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
    else if (parseString("hsv"))
    {
        bool hasAlpha = parseChar('a');
        expectPunct('(');
        int hue = parseColorValue();
        expectPunct(',');
        int sat = parseColorValue();
        expectPunct(',');
        int val = parseColorValue();
        if (hasAlpha)
        {
            expectPunct(',');
            alpha = parseOpacity();
        }
        expectPunct(')');
        // TODO convert
        red = clamp0to255(hue);
        green = clamp0to255(sat);
        blue = clamp0to255(val);
    }
    else
        throw new Exception("Expected #, rgb, rgba, or color name");

    skipWhiteSpace();
    if (!parseChar('\0'))
        throw new Exception("Expected end of input at the end of color string");


    return [ red, green, blue, alpha];

    // clamp and return
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
    assert(parseHTMLColor("#aB9")      == [0xaa, 0xBB, 0x99, 255]);
    assert(parseHTMLColor("#aB98")     == [0xaa, 0xBB, 0x99, 0x88]);
    assert(doesntParse("#"));
    assert(doesntParse("#ab"));
    assert(parseHTMLColor(" #0f1c4A ")   == [0x0f, 0x1c, 0x4a, 255]);    
    assert(parseHTMLColor(" #0f1c4A43 ") == [0x0f, 0x1c, 0x4A, 0x43]);
    assert(doesntParse("#0123456"));
    assert(doesntParse("#012345678"));

    assert(parseHTMLColor("  rgba( 14.01, 25.0e+0%, 16, 0.5)  ") == [14, 64, 16, 128]);
    assert(parseHTMLColor("rgb(10e3,112,-3.4e-2)")               == [255, 112, 0, 255]);

    assert(parseHTMLColor(" gray( +0.0% )")      == [0, 0, 0, 255]);
    assert(parseHTMLColor(" gray ")              == [128, 128, 128, 255]);
    assert(parseHTMLColor(" gray( 100%, 50% ) ") == [255, 255, 255, 128]);
}

