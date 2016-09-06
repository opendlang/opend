module ggplotd.guide;

version (unittest)
{
    import dunit.toolkit;
}

private struct GuideStore(string type = "")
{
    import std.range : isInputRange;
    void put(T)(T gs)
        if (is(T==GuideStore!(type))) 
    {
        _store.put(gs.store);
        import ggplotd.algorithm : safeMin, safeMax;
        _min = safeMin(_min, gs.min);
        _max = safeMax(_max, gs.max);
    }

    void put(T)(T range)
        if (!is(T==string) && isInputRange!T)
    {
        foreach(t; range)
            this.put(t);
    }

    void put(T)(T value)
        if (!is(T==GuideStore!(type)) && (is(T==string) || !isInputRange!T))
    {
        import std.conv : to;
        import std.traits : isNumeric;
        // For now we can just ignore colour I think
        static if (isNumeric!T)
        {
            import ggplotd.algorithm : safeMin, safeMax;
            _min = safeMin(_min, value.to!double);
            _max = safeMax(_max, value.to!double);
        } else {
            static if (type == "colour")
            {
                import ggplotd.colourspace : isColour;
                static if (!isColour!T) {
                    static if (is(T==string)) {
                        if (value !in namedColours) 
                        {
                            _store.put(value);
                        }
                    } else {
                        _store.put(value.to!string);
                    }
                }
            } else {
                _store.put(value.to!string);
            }
        }
    }

    double min()
    {
        // What if no min?
        return _min;
    }

    double max()
    {
        // What if no max?
        return _max;
    }

    @property auto store()
    {
        import ggplotd.range : uniquer;
        return _store.data.uniquer();
    }

    double _min;
    double _max;

    import std.range : Appender;
    Appender!(string[]) _store; // Should really only store uniques

    static if (type == "colour")
    {
        import ggplotd.colour : namedColours;
    }
}

unittest
{
    import std.array : array;
    import std.math : isNaN;
    import std.range : walkLength;
    // Not numeric -> add as string
    GuideStore!"" gs;
    gs.put("b");
    gs.put("b");
    assertEqual(gs.store.walkLength, 1);
    gs.put("a");
    assertEqual(gs.store.walkLength, 2);
    gs.put("b");
    assertEqual(gs.store.walkLength, 2);
    assertEqual(gs.store.array, ["b", "a"]);
    assert(isNaN(gs.min));
    assert(isNaN(gs.max));

    // Numeric -> add as min or max (also test int)
    gs.put(1);
    assertEqual(gs.min, 1.0);
    assertEqual(gs.max, 1.0);
    gs.put(2.0);
    assertEqual(gs.min, 1.0);
    assertEqual(gs.max, 2.0);
    gs.put(1.5);
    assertEqual(gs.min, 1.0);
    assertEqual(gs.max, 2.0);

    import ggplotd.colour: RGBA;
    GuideStore!"colour" gsc;
    // Test colour is ignored
    gsc.put(RGBA(0, 0, 0, 0));
    assertEqual(gsc.store.walkLength, 0);
    // Test named colour is ignored
    gsc.put("red");
    assertEqual(gsc.store.walkLength, 0);
    assert(isNaN(gsc.min));
    assert(isNaN(gsc.max));
    gsc.put("b");
    assertEqual(gsc.store.walkLength, 1);

    // Colour not ignored for standard gc
    gs.put(RGBA(0, 0, 0, 0));
    assertEqual(gs.store.walkLength, 3);
    // Test named colour is ignored
    gs.put("red");
    assertEqual(gs.store.walkLength, 4);
}

unittest
{
    GuideStore!"" gs;
    gs.put(["a", "b", "a"]);
    import std.range : walkLength;
    assertEqual(gs.store.walkLength, 2);

    GuideStore!"" gs2;
    gs2.put(["c", "b", "a"]);
    gs.put(gs2);
    assertEqual(gs.store.walkLength, 3);
    gs2.put([1.1,0.1]);
    gs.put(gs2);
    assertEqual(gs.min, 0.1);
    assertEqual(gs.max, 1.1);
}



/+
**** New :)

As always we return to a very similar place as where we started. We need a function that add IDs to the Geom. For x and y and size, this adds a tuple with double/string. Guess for numerical we'l only end up storing the min and max values? For colour we also accept anything of type Color.

This can then be passed through (continuous/discrete specific) type and result in a function that is a "guideFunction"

Note the min/max in the resulting guide should replace the bounds in the end.

Still to solve, how do things like barplots work where we need to plot around a discrete value. Still we want to have barplot use the standard functions, so either need a special type that has an offset, or for now we can just use rectangles, where width contains the offset, while the center is on the  discrete values. This would also work for histograms!

****

I think me and my betters have agreed. We start with two different guideOutputRange, discrete and continuous. Discrete converts everything to string and then stores it (in the order it arrived in) as breaks. Continuous just converts everything to double. These should be stored in each Geom

Before plotting, they are fed all the values in the geom chain (geom* functions shouldn't call numericLabel anymore). It derives the min and max value from that. Colourguide will ignore all values in the namedColours, since they are treated different.

Think we need guides for x, y, colour and size. Size will be special in that if range is between certain sizes (0.1 and 10?) do nothing, else limit scale it to be between 0.1 and 10. Probably achieved by setting these values at the start, while others have to derive them?.

Then the we create guideFunctions based on these that when receiving a value return the correct converted value (colour or doulbe (size)). Maybe at some point also pixels for x and y. We need to find out whether these guideFunctions can be templated in some way. Otherwise they must have a isDiscrete -> the draw function convertTo function that says either convert to string or double.

This design might not work for mixed types, but maybe we shouldn't support that anyway... Or allow multiple guides...
+/

/++
Support of different guides, i.e. continuous or discrete

T is the type that should always be returned (double for location, 
U is the "native" type
F is a special function that overwrites the default conversion. This is for example
    used in colours to support named colours. It should return a Nullable!T.

For continuous, both U and T should support arithmetic (- and /) operations? (one of them is enough?) aor provide a function that returns a T based on U and two breaks.

Guide(T, U, F) {
    /// Continuous or discrete
    string type;

    /// Here we control the scaling between breaks. Each break is equal distance in T
    U[] breaks
}
+/
