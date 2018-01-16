module pdfd.color;

@safe:

ubyte[3] parseHTMLColor(string s)
{
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
        return [cast(ubyte)r, cast(ubyte)g, cast(ubyte)b];
    }
    else if (s.length == 7) // eg: "#44AAff"
    {
        int r = (fromHex(s[1]) << 4)| fromHex(s[2]);
        int g = (fromHex(s[3]) << 4)| fromHex(s[4]);
        int b = (fromHex(s[5]) << 4)| fromHex(s[6]);
        return [cast(ubyte)r, cast(ubyte)g, cast(ubyte)b];
    }
    else
        throw new Exception("Couldn't parse color " ~ s);
}