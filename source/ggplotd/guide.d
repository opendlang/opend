module ggplotd.guide;

version (unittest)
{
    import dunit.toolkit;
}

/// Store values so we can later create guides from them
private struct GuideStore(string type = "")
{
    import std.range : isInputRange;
    /// Put another GuideStore into the store
    void put(T)(T gs)
        if (is(T==GuideStore!(type))) 
    {
        _store.put(gs._store);
        import ggplotd.algorithm : safeMin, safeMax;
        _min = safeMin(_min, gs.min);
        _max = safeMax(_max, gs.max);
    }

    /// Add a range of values to the store
    void put(T)(T range)
        if (!is(T==string) && isInputRange!T)
    {
        foreach(t; range)
            this.put(t);
    }

    /// Add a value of anytype to the store
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

    /// Minimum value encountered till now
    double min()
    {
        import std.math : isNaN;
        import ggplotd.algorithm : safeMin;
        if (_store.length > 0 || isNaN(_min))
            return safeMin(0, _min);
        return _min;
    }

    /// Maximum value encountered till now
    double max()
    {
        import std.math : isNaN;
        import ggplotd.algorithm : safeMax;
        if (_store.length > 0 || isNaN(_max))
            return safeMax(_store.length, _max);
        return _max;
    }

    /// The discete values in the store
    @property auto store() const
    {
        return _store.data;
    }

    /// A hash mapping the discrete values to continuous (double)
    @property auto storeHash() const
    {
        double[string] hash;
        double v = 0;
        foreach(k; this.store()) 
        {
            hash[k] = v;
            ++v;
        }
        return hash;
    }

    double _min;
    double _max;

    import ggplotd.range : HashSet;
    HashSet!(string) _store; // Should really only store uniques

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
    assertEqual(gs.storeHash, ["b":0.0, "a":1.0]);
    assertEqual(gs.min, 0);
    assertEqual(gs.max, 2);

    // Numeric -> add as min or max (also test int)
    gs.put(-1);
    assertEqual(gs.min, -1.0);
    assertEqual(gs.max, 2.0);
    gs.put(3.0);
    assertEqual(gs.min, -1.0);
    assertEqual(gs.max, 3.0);
    gs.put(1.5);
    assertEqual(gs.min, -1.0);
    assertEqual(gs.max, 3.0);

    import ggplotd.colour: RGBA;
    GuideStore!"colour" gsc;
    // Test colour is ignored
    gsc.put(RGBA(0, 0, 0, 0));
    assertEqual(gsc.store.walkLength, 0);
    // Test named colour is ignored
    gsc.put("red");
    assertEqual(gsc.store.walkLength, 0);
    assertEqual(gsc.min, 0);
    assertEqual(gsc.max, 0);
    gsc.put("b");
    assertEqual(gsc.store.walkLength, 1);

    // Colour not ignored for standard gc
    gs.put(RGBA(0, 0, 0, 0));
    assertEqual(gs.store.walkLength, 3);
    // Test named colour is ignored
    gs.put("red");
    assertEqual(gs.store.walkLength, 4);


    GuideStore!"" gs2;
    gs2.put(2);
    assertEqual(gs2.min, 2);
    assertEqual(gs2.max, 2);

    GuideStore!"" gs3;
    gs3.put(-2);
    assertEqual(gs3.min, -2);
    assertEqual(gs3.max, -2);
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
    gs2.put([10.1,-0.1]);
    gs.put(gs2);
    assertEqual(gs.min, -0.1);
    assertEqual(gs.max, 10.1);
}

/// A callable struct that translates any value into a double
struct GuideToDoubleFunction
{
    /// Call the function with a value
    auto opCall(T)(T value)
    {
        import std.conv : to;
        import std.traits : isNumeric;
        static if (isNumeric!T) {
            return doubleConvert(value.to!double);
        } else {
            return stringConvert(value.to!string);
        }
    }

    /// Function that governs translation from double to double (continuous to continuous)
    double delegate(double) doubleConvert;
    /// Function that governs translation from string to double (discrete to continuous)
    double delegate(string) stringConvert;
}

/// A callable struct that translates any value into a colour
struct GuideToColourFunction
{
    /// Call the function with a value
    auto opCall(T)(T value)
    {
        import std.conv : to;
        import std.traits : isNumeric;
        static if (isNumeric!T) {
            return doubleConvert(value.to!double);
        } else {
            static if (isColour!T) {
                import ggplotd.colourspace : RGBA, toColourSpace;
                return value.toColourSpace!RGBA;
            } else {
                static if (is(T==string)) {
                    if (value in namedColours)
                        return namedColours[value];
                    else
                        return stringConvert(value);
                } else {
                    return stringConvert(value.to!string);
                }
            }
        }
    }

    /// Function that governs translation from double to colour (continuous to colour)
    RGBA delegate(double) doubleConvert;
    /// Function that governs translation from string to colour (discrete to colour)
    RGBA delegate(string) stringConvert;
    import ggplotd.colourspace : isColour;
    import ggplotd.colour : namedColours, RGBA;
}

/// Create an appropiate GuidToDoubleFunction from a GuideStore
auto guideFunction(string type)(GuideStore!type gs)
    if (type != "colour")
{
    GuideToDoubleFunction gf;
    static if (type == "size") {
        gf.doubleConvert = (a) {
            assert(a >= gs.min() || a <= gs.max(), "Value falls outside of range");
            if (gs.min() < 0.2 || gs.max() > 5.0) // Limit the size to between these values
                return 0.2 + a*(5.0 - 0.2)/(gs.max() - gs.min());
            return a;
        };

    } else {
        gf.doubleConvert = (a) {
            assert(a >= gs.min() || a <= gs.max(), "Value falls outside of range");
            return a;
        };

    }
    immutable storeHash = gs.storeHash;

    gf.stringConvert = (a) {
        assert(a in storeHash, "Value not in guide");
        return gf.doubleConvert(storeHash[a]);
    };
    return gf;
}

unittest
{
    GuideStore!"" gs;
    gs.put(["b","a"]);
    auto gf = guideFunction(gs);
    assertEqual(gf(0.1), 0.1);
    assertEqual(gf("a"), 1);
}

unittest
{
    GuideStore!"size" gs;
    gs.put( [0.3, 4] );
    auto gf = guideFunction(gs);
    assertEqual(gf(0.5), 0.5);

    gs.put( [0.0] );
    auto gf2 = guideFunction(gs);
    assertEqual(gf2(0.0), 0.2);
    assertEqual(gf2(4.0), 5.0);
}

import ggplotd.colour : ColourGradientFunction;
/// Create an appropiate GuidToColourFunction from a GuideStore
auto guideFunction(string type)(GuideStore!type gs, ColourGradientFunction colourFunction)
    if (type == "colour")
{
    GuideToColourFunction gc;
    gc.doubleConvert = (a) {
        assert(a >= gs.min() || a <= gs.max(), "Value falls outside of range");
        return colourFunction(a, gs.min(), gs.max());
    };

    immutable storeHash = gs.storeHash;

    gc.stringConvert = (a) {
        assert(a in storeHash, "Value not in guide");
        return gc.doubleConvert(storeHash[a]);
    };
    return gc;
}

unittest
{
    import ggplotd.colour : colourGradient, namedColours;
    import ggplotd.colourspace : HCY, RGBA, toTuple;
    GuideStore!"colour" gs;
    gs.put([0.1, 3.0]);
    auto gf = guideFunction(gs, colourGradient!HCY("blue-red"));
    assertEqual(gf(0.1).toTuple, namedColours["blue"].toTuple);
    assertEqual(gf(3.0).toTuple, namedColours["red"].toTuple);
    assertEqual(gf("green").toTuple, namedColours["green"].toTuple);
    assertEqual(gf(namedColours["green"]).toTuple, namedColours["green"].toTuple);
}
