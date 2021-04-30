module mir.utf;

/++
+/
bool decodeFrontImpl(bool assumeNotEmpty = false, bool assumeFrontNotAscii = false)(scope ref inout(char)[] str, out dchar value) @safe pure nothrow @nogc
{
    /* The following encodings are valid:
     *  0xxxxxxx
     *  110xxxxx 10xxxxxx
     *  1110xxxx 10xxxxxx 10xxxxxx
     *  11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
     */

    import mir.bitop: ctlz;
    import mir.utility: max;

    static if (!assumeNotEmpty)
    {
        if (str.length == 0)
            return false;
    }
    else
    {
        assert(str.length);
    }

    uint f = str[0];
    value = f;
    str = str[1 .. $];

    static if (!assumeFrontNotAscii)
    {
        if (f < 0x80)
            return true;
    }

    uint len = ctlz(~(f << 25));
    if (len == 0 || len > max(3u, str.length)) // invalid UTF-8
        return false;
    value &= (1 << (6 - len)) - 1;

    do
    {
        auto c = str[0];
        str = str[1 .. $];
        value <<= 6;
        if ((c & 0xC0) != 0x80)
            return false;
        value |= c & 0x3F;
    }
    while(--len);
    return true;
}

version (D_Exceptions):

package static immutable utfException = new Exception("Invalid UTF-8 sequence");

///
dchar decodeFront(scope ref inout(char)[] str) @safe pure @nogc @property
{
    dchar ret;
    if (decodeFrontImpl(str, ret))
    {
        return ret;
    }
    throw utfException;
}

///
@safe pure unittest
{
    string str = "Hello, World!";

    assert(str.decodeFront == 'H' && str == "ello, World!");
    str = "å";
    assert(str.decodeFront == 'å' && str.length == 0);
    str = "å";
}
