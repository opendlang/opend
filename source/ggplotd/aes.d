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

    // Make sure to test with empty y, colour
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
