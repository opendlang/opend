module ggplotd.guide;

version (unittest)
{
    import dunit.toolkit;
}

private struct DiscreteStoreWithOffset
{
    import std.typecons : Tuple, tuple;
    size_t[string] store;
    Tuple!(double, double)[] offsets;

    bool put(in DiscreteStoreWithOffset ds)
    {
        bool added = false;
        foreach(el, offset1, offset2; ds.data) 
        {
            if (this.put(el, offset1))
                added = true;
            if (this.put(el, offset2))
                added = true;
        }
        return added;
    }

    bool put(string el, double offset = 0)
    {
        import ggplotd.algorithm : safeMin, safeMax;
        if (el !in store)
        {
            store[el] = store.length;
            offsets ~= tuple(offset, offset);
            _min = safeMin(store.length - 1 + offset, _min);
            _max = safeMax(store.length - 1 + offset, _max);
            return true;
        } else {
            auto id = store[el];
            offsets[id] = tuple(safeMin(offsets[id][0], offset),
                safeMax(offsets[id][1], offset));
            _min = safeMin(id + offsets[id][0], _min);
            _max = safeMax(id + offsets[id][1], _max);
        }
        return false;
    }

    double min() const
    {
        if (store.length == 0)
            return 0;
        return _min;
    }

    double max() const
    {
        if (store.length == 0)
            return 0;
        return _max;
    }

    auto data() const
    {
        import std.array : array;
        import std.algorithm : map, sort;
        auto kv = store.byKeyValue().array;
        auto sorted = kv.sort!((a, b) => a.value < b.value);
        return sorted.map!((a) => tuple(a.key, offsets[a.value][0], offsets[a.value][1]));
    }

    auto length() const
    {
        return offsets.length;
    }

    double _min;
    double _max;
}

unittest
{
    DiscreteStoreWithOffset ds;
    assertEqual(ds.min(), 0);
    assertEqual(ds.max(), 0);

    ds.put("b", 0.5);
    assertEqual(ds.min(), 0.5);
    assertEqual(ds.max(), 0.5);

    ds.put("a", 0.5);
    assertEqual(ds.min(), 0.5);
    assertEqual(ds.max(), 1.5);

    ds.put("b", -0.5);
    assertEqual(ds.min(), -0.5);
    assertEqual(ds.max(), 1.5);

    ds.put("c", -0.7);
    assertEqual(ds.min(), -0.5);
    assertEqual(ds.max(), 1.5);

    DiscreteStoreWithOffset ds2;
    ds2.put("d", 0.5);
    ds2.put("b", -1.0);
    ds.put(ds2);
    assertEqual(ds.min(), -1.0);
    assertEqual(ds.max(), 3.5);
}

/// Store values so we can later create guides from them
private struct GuideStore(string type = "")
{
    import std.range : isInputRange;
    /// Put another GuideStore into the store
    void put(T)(in T gs)
        if (is(T==GuideStore!(type))) 
    {
        _store.put(gs._store);

        import ggplotd.algorithm : safeMin, safeMax;
        _min = safeMin(_min, gs._min);
        _max = safeMax(_max, gs._max);
    }

    /// Add a range of values to the store
    void put(T)(in T range)
        if (!is(T==string) && isInputRange!T)
    {
        foreach(t; range)
            this.put(t);
    }

    import std.traits : TemplateOf;
    /// Add a value of anytype to the store
    void put(T)(in T value, double offset = 0)
        if (!is(T==GuideStore!(type)) &&
            (is(T==string) || !isInputRange!T)
        )
    {
        import std.conv : to;
        import std.traits : isNumeric;
        // For now we can just ignore colour I think
        static if (isNumeric!T)
        {
            import ggplotd.algorithm : safeMin, safeMax;
            _min = safeMin(_min, value.to!double + offset);
            _max = safeMax(_max, value.to!double + offset);
        } else {
            static if (type == "colour")
            {
                import ggplotd.colourspace : isColour;
                static if (!isColour!T) {
                    static if (is(T==string)) {
                        auto col = namedColour(value);
                        if (col.isNull) 
                        {
                            _store.put(value, offset);
                        }
                    } else {
                        _store.put(value.to!string, offset);
                    }
                }
            } else {
                _store.put(value.to!string, offset);
            }
        }
    }

    /// Minimum value encountered till now
    double min() const
    {
        import std.math : isNaN;
        import ggplotd.algorithm : safeMin;
        if (_store.length > 0 || isNaN(_min))
            return safeMin(_store.min, _min);
        return _min;
    }

    /// Maximum value encountered till now
    double max() const
    {
        import std.math : isNaN;
        import ggplotd.algorithm : safeMax;
        if (_store.length > 0 || isNaN(_max))
            return safeMax(_store.max, _max);
        return _max;
    }

    /// The discete values in the store
    @property auto store() const
    {
        import std.algorithm : map;
        return _store.data.map!((a) => a[0]);
    }

    /// A hash mapping the discrete values to continuous (double)
    @property auto storeHash() const
    {
        import std.conv : to;
        double[string] hash;
        foreach(k, v; _store.store) 
        {
            hash[k] = v.to!double;
        }
        return hash;
    }

    /// True if we encountered discrete values
    bool hasDiscrete() const
    {
        return _store.length > 0;
    }

    double _min;
    double _max;

    DiscreteStoreWithOffset _store; // Should really only store uniques

    static if (type == "colour")
    {
        import ggplotd.colour : namedColour;
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
    assertEqual(gs.max, 1);

    // Numeric -> add as min or max (also test int)
    gs.put(-1);
    assertEqual(gs.min, -1.0);
    assertEqual(gs.max, 1.0);
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
    import std.array : array;
    import std.range : walkLength;
    assertEqual(gs.store.walkLength, 2);

    GuideStore!"" gs2;
    gs2.put(["c", "b", "a"]);
    gs.put(gs2);
    assertEqual(gs.store.walkLength, 3);
    assertEqual(gs.store.array, ["a","b","c"]);
    gs2.put([10.1,-0.1]);
    gs.put(gs2);
    assertEqual(gs.min, -0.1);
    assertEqual(gs.max, 10.1);

    GuideStore!"" gs3;
    gs3.put(["a", "b", "a"]);
    const(GuideStore!"") cst_gs() {
        GuideStore!"" gs;
        gs.put(["c", "b", "a"]);
        return gs;
    }
    gs3.put(cst_gs());
    assertEqual(gs3.store.walkLength, 3);
    assertEqual(gs3.store.array, ["a","b","c"]);
 
}

unittest
{
    GuideStore!"" gs;
    gs.put("a", 0.5);
    assertEqual(gs.min(), 0.5);
    assertEqual(gs.max(), 0.5);

    GuideStore!"" gs2;
    gs2.put("b", 0.7);
    gs.put(gs2);
    assertEqual(gs.min(), 0.5);
    assertEqual(gs.max(), 1.7);

    GuideStore!"" gs3;
    gs3.put("b", -0.7);
    gs.put(gs3);
    import std.math : approxEqual;
    assert(approxEqual(gs.min(), 0.3));
    assert(approxEqual(gs.max(), 1.7));
}

/// A callable struct that translates any value into a double
struct GuideToDoubleFunction
{
    /// Convert the value to double
    private auto convert(T)(in T value, bool scale = true) const
    {
        import std.conv : to;
        import std.traits : isNumeric;
        double result;
        static if (isNumeric!T) {
            result = doubleConvert(value.to!double);
        } else {
            result = stringConvert(value.to!string);
        }
        return result;
    }

    auto unscaled(T)(in T value) const
    {
        return this.convert!T(value, false);
    }

    /// Call the function with a value
    auto opCall(T)(in T value, bool scale = true) const
    {
        auto result = unscaled!T(value);
        if (scaleFunction.isNull || !scale)
            return result;
        else
            return scaleFunction.get()(result);
    }

    /// Function that governs translation from double to double (continuous to continuous)
    double delegate(double) doubleConvert;
    /// Function that governs translation from string to double (discrete to continuous)
    double delegate(string) stringConvert;

    import std.typecons : Nullable;
    /// Additional scaling of the field (i.e. log10, polar coordinates)
    Nullable!(double delegate(double)) scaleFunction;
}

/// A callable struct that translates any value into a colour
struct GuideToColourFunction
{
    /// Call the function with a value
    auto opCall(T)(in T value, bool scale = true) const
    {
        import std.conv : to;
        import std.traits : isNumeric;
        static if (isNumeric!T) {
            return doubleConvert(toDouble(value));
        } else {
            static if (isColour!T) {
                import ggplotd.colourspace : RGBA, toColourSpace;
                return value.toColourSpace!RGBA;
            } else {
                static if (is(T==string)) {
                    auto col = namedColour(value);
                    if (!col.isNull)
                        return RGBA(col.r, col.g, col.b, 1);
                    else
                        return stringConvert(value);
                } else {
                    return stringConvert(value.to!string);
                }
            }
        }
    }

    auto toDouble(T)(in T value, bool scale = true) const
    {
        import std.conv : to;
        import std.traits : isNumeric;
        double result = this.unscaled(value);
        if (scaleFunction.isNull || !scale)
            return result;
        else
            return scaleFunction.get()(result);
    }

    auto unscaled(T)(in T value) const
    {
        import std.conv : to;
        import std.traits : isNumeric;
        double result;
        static if (isNumeric!T)
            result = value.to!double;
        else
            result = stringToDoubleConvert(value.to!string);
        return result;
    }

    /// Function that governs translation from double to colour (continuous to colour)
    RGBA delegate(double) doubleConvert;
    /// Function that governs translation from string to colour (discrete to colour)
    RGBA delegate(string) stringConvert;

    /// Function that governs translation from string to double (discrete to continuous)
    double delegate(string) stringToDoubleConvert;
    import ggplotd.colourspace : isColour;
    import ggplotd.colour : namedColour, RGBA;

    import std.typecons : Nullable;
    /// Additional scaling of the field (i.e. log10, polar coordinates)
    Nullable!(double delegate(double)) scaleFunction;
}

/// Create an appropiate GuidToDoubleFunction from a GuideStore
auto guideFunction(string type)(GuideStore!type gs)
    if (type != "colour")
{
    GuideToDoubleFunction gf;
    static if (type == "size") {
        gf.doubleConvert = (a) {
            import std.math : isNaN;
            if (isNaN(a))
                return a;
            assert(a >= gs.min() || a <= gs.max(), "Value falls outside of range");
            if (gs.min() < 0.4 || gs.max() > 5.0) // Limit the size to between these values
            {
                if (gs.max() == gs.min())
                    return 1.0;
                return 0.7 + a*(5.0 - 0.7)/(gs.max() - gs.min());
            }
            return a;
        };

    } else {
        gf.doubleConvert = (a) {
            import std.math : isNaN;
            if (isNaN(a))
                return a;
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

    import std.math : isNaN;
    assert(isNaN(gf(double.init)));
}

unittest
{
    GuideStore!"size" gs;
    gs.put( [0.5, 4] );
    auto gf = guideFunction(gs);
    assertEqual(gf(0.6), 0.6);

    gs.put( [0.0] );
    auto gf2 = guideFunction(gs);
    assertEqual(gf2(0.0), 0.7);
    assertEqual(gf2(4.0), 5.0);

    GuideStore!"size" gs3;
    gs3.put( [0.0] );
    auto gf3 = guideFunction(gs3);
    assertEqual(gf3(0.0), 1.0);
}

import ggplotd.colour : ColourGradientFunction;
/// Create an appropiate GuidToColourFunction from a GuideStore
auto guideFunction(string type)(GuideStore!type gs, ColourGradientFunction colourFunction)
    if (type == "colour")
{
    GuideToColourFunction gc;
    gc.doubleConvert = (a) {
        import std.math : isNaN;
        if (isNaN(a)) {
            import ggplotd.colourspace : RGBA;
            return RGBA(0,0,0,0);
        }
        assert(a >= gs.min() || a <= gs.max(), "Value falls outside of range");
        return colourFunction(a, gs.min(), gs.max());
    };

    immutable storeHash = gs.storeHash;

    gc.stringToDoubleConvert = (a) {
        assert(a in storeHash, "Value not in storeHash");
        return storeHash[a];
    };

    gc.stringConvert = (a) {
        assert(a in storeHash, "Value not in storeHash");
        return gc.doubleConvert(gc.stringToDoubleConvert(a));
    };
    return gc;
}

unittest
{
    import ggplotd.colour : colourGradient, namedColour;
    import ggplotd.colourspace : HCY, RGBA, toTuple;
    GuideStore!"colour" gs;
    gs.put([0.1, 3.0]);
    auto gf = guideFunction(gs, colourGradient!HCY("blue-red"));
    assertEqual(gf(0.1).toTuple, namedColour("blue").get().toTuple);
    assertEqual(gf(3.0).toTuple, namedColour("red").get().toTuple);
    assertEqual(gf("green").toTuple, namedColour("green").get().toTuple);
    assertEqual(gf(namedColour("green").get()).toTuple, namedColour("green").get().toTuple);
    assertEqual(gf(double.init).toTuple, RGBA(0,0,0,0).toTuple);
}
