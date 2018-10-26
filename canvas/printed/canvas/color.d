module printed.canvas.color;

import std.algorithm;

@safe:

/// Parses a HTML color and gives back a RGB triplet.
/// Currently only some HTML colors are supported.
ubyte[4] parseHTMLColor(string s)
{
    // Add a terminal char (we chose zero)
    s ~= '\0';
    
    int index = 0;

    char peek()
    {
        return s[index];
    }

    void next()
    {
        index++;
    }

    void expect(char ch)
    {
        if (!parse(ch))
            throw new Exception(format("Expected char %s in color string", ch));
    }

    bool parse(char ch)
    {
        if (peek() == ch)
        {
            next;
            return true;
        }
        return false;
    }

    bool parse(string s)
    {
        int save = index;

        for (int i = 0; i < s.length; ++i)
        {
            if (!parse(s[i]))
            {
                index = save;
                return false;
            }
        }
        return true;
    }

    void skipWhiteSpace()
    {
        while (!eol)
        {
            char ch = peek();
            if (ch == ' ') next;
        }
    }

    skipWhiteSpace();

    if (peek() == '#')
    {

    }
    else if (parse("rgb"))
    {
        bool hasAlpha = parse("a");
        skipWhiteSpace();
        expect('(');

        expect(')');
    }
    else if (parse("hsv"))
    {
        bool hasAlpha = parse("a");
        skipWhiteSpace();
        expect('(');
        int r = parseInt();
        expect(')');
    }

    skipWhiteSpace();
    if (!parse('\0'))
        throw new Exception("Expected end of input at the end of color string");

    // clamp and return
}

/*
    int fromHex(char ch)
    {
        if (ch >= '0' && ch <= '9')
            return ch - '0';
        if (ch >= 'a' && ch <= 'f')
            return ch + 10 - 'a';
        if (ch >= 'A' && ch <= 'F')
            return ch + 10 - 'A';
        throw new Exception("Couldn't parse color " ~ s);
    }

    if (s.length == 4) // eg: "#4af"
    {
        if (s[0] != '#')
            throw new Exception("Couldn't parse color " ~ s);

        int r = fromHex(s[1]);
        int g = fromHex(s[2]);
        int b = fromHex(s[3]);
        r |= (r << 4);
        g |= (g << 4);
        b |= (b << 4);
        return [cast(ubyte)r, cast(ubyte)g, cast(ubyte)b, 255];
    }
    else if (s.length == 7) // eg: "#44AAff"
    {
        int r = (fromHex(s[1]) << 4)| fromHex(s[2]);
        int g = (fromHex(s[3]) << 4)| fromHex(s[4]);
        int b = (fromHex(s[5]) << 4)| fromHex(s[6]);
        return [cast(ubyte)r, cast(ubyte)g, cast(ubyte)b, 255];
    }
    else
        throw new Exception("Couldn't parse color " ~ s);
}
*/