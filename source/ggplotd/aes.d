module ggplotd.aes;

version(unittest)
{
    import dunit.toolkit;
}

///
struct Aes( RX, RY, RCol )
{
    import std.range : zip, Zip, StoppingPolicy, ElementType;
    import std.typecons : Tuple;

    this( RX x, RY y, RCol colour )
    {
        _aes = zip(StoppingPolicy.longest, 
                x, y, colour);
        // TODO probably need to sort by colour
    }

    @property ref auto front()
    {
        auto t = _aes.front();
        return Tuple!(
                ElementType!RX, "x", 
                ElementType!RY, "y", 
                ElementType!RCol, "colour"
            )( t[0], t[1], t[2] );
    }

    void popFront()
    {
        _aes.popFront();
    }

    @property bool empty() 
    {
        return _aes.empty();
    }

    @property Aes save() {
        return this;
    }

    private:
        Zip!(RX, RY, RCol) _aes;
}

unittest
{
    auto aes = Aes!(double[], double[], string[] )( [1.0,2.0], [3.0,1.5], ["a","b"] );
    assertEqual( aes.front.x, 1.0 );
    aes.popFront;
    assertEqual( aes.front.y, 1.5 );

    aes.popFront;
    assert( aes.empty );
    // Make sure to test with empty y, colour
}

auto group(AES)( AES aes )
{
    import std.algorithm : filter, map, uniq, sort;
    import std.range : array;
    auto colours = aes.map!( (a) => a.colour )
        .array
        .sort()
        .uniq;
    return colours.map!( (c) => aes.filter!((a) => a.colour==c));
}

unittest
{
    auto aes = Aes!(double[], double[], string[] )( [1.0,2.0,1.1], 
            [3.0,1.5,1.1], ["a","b","a"] );

    import std.range : walkLength;
    auto grouped = aes.group;
    assertEqual( grouped.walkLength, 2 );
    assertEqual( grouped.front.walkLength, 2 );
    grouped.popFront;
    assertEqual( grouped.front.walkLength, 1 );
}


/+
http://forum.dlang.org/thread/hdxnptcikgojdkmldzrk@forum.dlang.org
template aes(fun...)
{
    void aes(R)(R range)
    {
        import std.stdio : writeln;
        import std.algorithm : countUntil;
        range.writeln;
        fun[1].countUntil("y").writeln;
        fun.countUntil("z").writeln;
    }
}

unittest
{
    import std.typecons : Tuple;
    import std.range : zip;
    import std.stdio : writeln;

    auto t = Tuple!(int, "number",
            string, "message")(42, "hello");
    assert( t.number == 42 );

    auto xs = [0.0,1.0];
    auto ys = [4.0,5.0];

    aes!("x", "y")(zip(xs,ys));
}
+/
