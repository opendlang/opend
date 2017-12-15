module mir.random.flex.internal.types;

import std.traits: ReturnType, isFloatingPoint;

version(Flex_logging)
{
    import std.experimental.logger;
}

/**
Major data unit of the Flex algorithm.
It is used to store
- (cached) values of the transformation (and its derivatives)
- area below the hat and squeeze function
- linked-list like reference to the right part of the interval (there will always
be exactly one interval with right = 0)
*/
struct Interval(S)
    if (isFloatingPoint!S)
{
    /// left position of the interval
    S lx;

    /// right position of the interval
    S rx;

    /// T_c family of the interval
    S c;

    /// transformed left value of lx
    S ltx;

    /// transformed value of the first derivate of the left lx value
    S lt1x;

    /// transformed value of the second derivate of the left lx value
    S lt2x;

    /// transformed right value of rx
    S rtx;

    /// transformed value of the first derivate of the right rx value
    S rt1x;

    /// transformed value of the second derivate of the right rx value
    S rt2x;

    /// hat function of the interval
    LinearFun!S hat;

    /// squeeze function of the interval
    LinearFun!S squeeze;

    /// calculated area of the integrated hat function
    S hatArea;

    /// calculated area of the integrated squeeze function
    S squeezeArea;

    // workaround against @@@BUG 16331@@@
    // sets NaN's to be equal on comparison
    version(Flex_logging)
    bool opEquals(const Interval s2) const
    {
        import std.math : isNaN, isFloatingPoint;
        import std.meta : AliasSeq;
        string buildMixin()
        {
            enum symbols = AliasSeq!("lx", "rx", "c", "ltx", "lt1x", "lt2x",
                                     "rtx", "rt1x", "rt2x", "hat", "squeeze", "hatArea", "squeezeArea");
            enum linSymbols = AliasSeq!("slope", "y", "a");
            string s = "return ";
            foreach (i, attr; symbols)
            {
                if (i > 0)
                    s ~= " && ";
                s ~= "(";
                auto attrName = symbols[i].stringof;
                alias T = typeof(mixin("typeof(this).init." ~ attr));

                if (isFloatingPoint!T)
                {
                    // allow NaNs
                    s ~= "this." ~ attr ~ ".isNaN && s2." ~ attr ~ ".isNaN ||";
                }
                else if (is(T == const LinearFun!S))
                {
                    // allow NaNs
                    s ~= "(";
                    foreach (j, linSymbol; linSymbols)
                    {
                        if (j > 0)
                            s ~= "||";
                        s ~= attr ~ "." ~ linSymbol ~ ".isNaN";
                        s ~= "&& s2." ~ attr ~ "." ~ linSymbol ~ ".isNaN";
                    }
                    s ~= ") ||";
                }
                s ~= attr ~ " == s2." ~ attr;
                s ~= ")";
            }
            s ~= ";";
            return s;
        }
        mixin(buildMixin());
    }

    ///
    version(Flex_logging_hex) string logHex()
    {
        import std.format : format;
        return "Interval!%s(%a, %a, %a, %a, %a, %a, %a, %a, %a, %s, %s, %a, %a)"
               .format(S.stringof, lx, rx, c, ltx, lt1x, lt2x, rtx, rt1x, rt2x,
                       hat.logHex, squeeze.logHex, hatArea, squeezeArea);
    }
}

/**
Notations of different function types according to Botts et al. (2013).
It is based on this naming scheme:

- a: concAve
- b: convex
- Type 4 is the pure case without any inflection point
*/
enum FunType {undefined, T1a, T1b, T2a, T2b, T3a, T3b, T4a, T4b}

/**
Determine the function type of an interval.
Based on Theorem 1 of the Flex paper.
Params:
    bl = left side of the interval
    br = right side of the interval
*/
FunType determineType(S)(in Interval!S iv)
in
{
    import std.math : isInfinity, isNaN;
    assert(iv.lx < iv.rx, "invalid interval");
}
out(type)
{
    version(Flex_logging)
    if (!type)
        warningf("Interval has an undefined type: %s", iv);
}
body
{
    with(FunType)
    {
        // In each unbounded interval f must be concave and strictly monotone
        // Condition 4 in section 2.3 from Botts et al. (2013)
        if (iv.lx == -S.infinity)
        {
            if (iv.rt2x < 0 && iv.rt1x > 0)
                return T4a;
            return undefined;
        }

        if (iv.rx == +S.infinity)
        {
            if (iv.lt2x < 0 && iv.lt1x < 0)
                return T4a;
            return undefined;
        }

        if (iv.c > 0  && iv.ltx == 0 || iv.c <= 0 && iv.ltx == -S.infinity)
        {
            if (iv.rt2x < 0 && iv.rt1x > 0)
                return T4a;
            if (iv.rt2x > 0 && iv.rt1x > 0)
                return T4b;
            return undefined;
        }

        if (iv.c > 0  && iv.rtx == 0 || iv.c <= 0 && iv.rtx == -S.infinity)
        {
            if (iv.lt2x < 0 && iv.lt1x < 0)
                return T4a;
            if (iv.lt2x > 0 && iv.lt1x < 0)
                return T4b;
            return undefined;
        }

        if (iv.c < 0)
        {
            if (iv.ltx == 0  && iv.rt2x > 0 || iv.rtx == 0 && iv.lt2x > 0)
                return T4b;
        }

        // slope of the interval
        auto R = (iv.rtx - iv.ltx) / (iv.rx- iv.lx);

        if (iv.lt1x >= R && iv.rt1x >= R)
            return T1a;
        if (iv.lt1x <= R && iv.rt1x <= R)
            return T1b;

        if (iv.lt2x <= 0 && iv.rt2x <= 0)
            return T4a;
        if (iv.lt2x >= 0 && iv.rt2x >= 0)
            return T4b;

        if (iv.lt1x >= R && R >= iv.rt1x)
        {
            if (iv.lt2x < 0 && iv.rt2x > 0)
                return T2a;
            if (iv.lt2x > 0 && iv.rt2x < 0)
                return T2b;
        }
        else if (iv.lt1x <= R && R <= iv.rt1x)
        {
            if (iv.lt2x < 0 && iv.rt2x > 0)
                return T3a;
            if (iv.lt2x > 0 && iv.rt2x < 0)
                return T3b;
        }

        return undefined;
    }
}

nothrow pure @safe version(mir_random_test) unittest
{
    import std.meta : AliasSeq;
    foreach (S; AliasSeq!(float, double, real)) with(FunType)
    {
        const f0 = (S x) => x ^^ 4;
        const f1 = (S x) => 4 * x ^^ 3;
        const f2 = (S x) => 12 * x * x;
        enum c = 42; // c doesn't matter here
        auto dt = (S l, S r) => determineType(Interval!S(l, r, c, f0(l), f1(l), f2(l),
                                                                  f0(r), f1(r), f2(r)));

        // entirely convex
        assert(dt(-3.0, -1) == T4b);
        assert(dt(-1.0, 1) == T4b);
        assert(dt(1.0, 3) == T4b);
    }
}

// test x^3
nothrow pure @safe version(mir_random_test) unittest
{
    import std.meta : AliasSeq;
    foreach (S; AliasSeq!(float, double, real)) with(FunType)
    {
        const f0 = (S x) => x ^^ 3;
        const f1 = (S x) => 3 * x ^^ 2;
        const f2 = (S x) => 6 * x;
        enum c = 42; // c doesn't matter here
        auto dt = (S l, S r) => determineType(Interval!S(l, r, c, f0(l), f1(l), f2(l),
                                                                  f0(r), f1(r), f2(r)));

        // concave
        assert(dt(-S.infinity, S(-1.0)) == T4a);
        assert(dt(S(-3.0), S(-1)) == T4a);

        // inflection point at x = 0, concave before
        assert(dt(S(-1.0), S(1)) == T1a);
        // convex
        assert(dt(S(1.0), S(3)) == T4b);
    }
}

// test sin(x)
nothrow pure @safe version(mir_random_test) unittest
{
    import std.math: PI;
    // due to numerical errors a small padding must be added
    // see e.g. https://gist.github.com/wilzbach/3d27d06b55821aa9795deb15d4d47679
    import std.math : cos, sin;

    import std.meta : AliasSeq;
    foreach (S; AliasSeq!(float, double, real)) with(FunType)
    {
        import std.stdio;
        const f0 = (S x) => sin(x);
        const f1 = (S x) => cos(x);
        const f2 = (S x) => -sin(x);
        enum c = 42; // c doesn't matter here
        auto dt = (S l, S r) => determineType(Interval!S(l, r, c, f0(l), f1(l), f2(l),
                                                                  f0(r), f1(r), f2(r)));
        // type 1a: concave
        assert(dt(0.01, 2 * PI - 0.01) == T1a);
        assert(dt(2 * PI + 0.01, 4 * PI - 0.01) == T1a);
        assert(dt(2, 4) == T1a);
        assert(dt(0.01, 5) == T1a);
        assert(dt(1, 5) == T1a);

        // type 1b: convex
        assert(dt(-PI, PI) == T1b);
        assert(dt(PI, 3 * PI) == T1b);
        assert(dt(4, 8) == T1b);

        // type 2a: concave
        assert(dt(1, 4) == T2a);

        // type 2b: convex
        assert(dt(6, 8) == T2b);

        // type 3a: concave
        assert(dt(3, 4) == T3a);
        assert(dt(2, 5.7) == T3a);

        // type 3b: concave
        assert(dt(-3, 0.1) == T3b);

        // type 4a - pure concave intervals (special case of 2a)
        assert(dt(0.01, PI - 0.01) == T4a);
        assert(dt(0.01, 3) == T4a);
        assert(dt(2 * PI + 0.01, 3 * PI - 0.01) == T4a);

        // type 4b - pure convex intervals (special case of 3b)
        assert(dt(-PI + 0.01, -0.01) == T4b);
        assert(dt(PI + 0.01, 2 * PI - 0.01) == T4b);
        assert(dt(4, 6) == T4b);
    }
}

nothrow pure @safe version(mir_random_test) unittest
{
    import std.meta : AliasSeq;
    foreach (S; AliasSeq!(float, double, real)) with(FunType)
    {
        const f0 = (S x) => x * x;
        const f1 = (S x) => 2 * x;
        const f2 = (S x) => 2.0;
        enum c = 42; // c doesn't matter here
        auto dt = (S l, S r) => determineType(Interval!S(l, r, c, f0(l), f1(l), f2(l),
                                                                  f0(r), f1(r), f2(r)));
        // entirely convex
        assert(dt(-1, 1) == T4b);
        assert(dt(1, 3) == T4b);
    }
}


/**
Representation of linear function of the form:

    y = slope * (x - y) + a

This representation allows a bit higher precision than the
typical representation `y = slope * x + a`.
*/
struct LinearFun(S)
{
    import std.format : FormatSpec;

    /// direction and steepness (aka beta)
    S slope;

    /// boundary point where f obtains it's maximum
    S y;

    /// constant intercept
    S a;

    /**
    Params:
        slope = direction and steepness
        y = boundary point, often f(x)
        a = constant intercept
    */
    this(S slope, S y, S a)
    {
        this.slope = slope;
        this.y = y;
        this.a = a;
    }

    private enum string _toString =
    q{
        import std.range : put;
        import std.format: formatValue, singleSpec;
        switch(fmt.spec)
        {
            case 'l':
                import std.math: abs, approxEqual, isNaN;
                if (slope.isNaN)
                    sink.put("#NaN#");
                else
                {
                    auto spec2g = singleSpec("%.2g");
                    if (!slope.approxEqual(0))
                    {
                        sink.formatValue(slope, spec2g);
                        sink.put("x");
                        if (!intercept.approxEqual(0))
                        {
                            sink.put(" ");
                            char sgn = intercept > 0 ? '+' : '-';
                            sink.put(sgn);
                            sink.put(" ");
                            sink.formatValue(abs(intercept), spec2g);
                        }
                    }
                    else
                    {
                        sink.formatValue(intercept, spec2g);
                    }
            }
                break;
            case 's':
            default:
                import std.traits : Unqual;
                sink.put(Unqual!(typeof(this)).stringof);
                auto spec2g = singleSpec("%.6g");
                sink.put("(");
                sink.formatValue(slope, spec2g);
                sink.put(", ");
                sink.formatValue(y, spec2g);
                sink.put(", ");
                sink.formatValue(a, spec2g);
                sink.put(")");
                break;
        }
    };

    /// textual representation of the function
    void toString()(scope void delegate(const(char)[]) @system sink,
                  FormatSpec!char fmt) const
    {
        mixin(_toString);
    }
    /// ditto
    void toString()(scope void delegate(const(char)[]) @safe sink,
                  FormatSpec!char fmt) const
    {
        mixin(_toString);
    }

    /// call the linear function with x
    S opCall(in S x) const
    {
        S val = slope * (x - y);
        val += a;
        return val;
    }

    /// calculate inverse of x
    S inverse(S x) const
    {
        return y + (x - a) / slope;
    }

    // calculate intercept (for debugging)
    S intercept() @property const
    {
        return slope * -y + a;
    }

    ///
    string logHex()
    {
        import std.format : format;
        return "LinearFun!%s(%a, %a, %a)".format(S.stringof, slope, y, a);
    }
}

/**
Constructs a linear function of the form `y = slope * (x - y) + a`.

Params:
    slope = direction and steepness
    y = boundary point, often f(x)
    a = constant intercept
Returns:
    A linear function constructed with the given parameters.
*/
LinearFun!S linearFun(S)(S slope, S y, S a)
{
    return LinearFun!S(slope, y, a);
}

/// tangent of a point
@safe version(mir_random_test) unittest
{
    import std.format : format;
    auto f = (double x) => x * x + 1;
    auto df = (double x) => 2 * x;
    auto buildTan = (double x) => linearFun(df(x), x, f(x));

    auto t0 = buildTan(0);
    assert("%l".format(t0)== "1");
    assert(t0(0) == 1);
    assert(t0(42) == 1);

    auto t1 = buildTan(1);
    assert("%l".format(t1) == "2x");
    assert(t1(1) == 2);
    assert(t1(2) == 4);

    auto t2 = buildTan(2);
    assert("%l".format(t2) == "4x - 3");
    assert(t2(1) == 1);
    assert(t2(2) == 5);
}

/// secant of two points
@safe version(mir_random_test) unittest
{
    import std.format : format;
    auto f = (double x) => x * x + 1;
    auto lx = 1, rx = 3;
    // compute the slope between lx and rx
    auto lf = linearFun((f(rx) - f(lx)) / (rx - lx), lx, f(lx));

    assert("%l".format(lf) == "4x - 2");
    assert(lf(1) == 2); // f(1)
    assert(lf(3) == 10); // f(3)
}

/// construct an arbitrary linear function
@safe version(mir_random_test) unittest
{
    import std.format : format;

    // 2 * x + 1
    auto t = linearFun!double(2, 0, 1);
    assert("%l".format(t) == "2x + 1");
    assert(t(1) == 3);
    assert(t(-2) == -3);
}

@nogc nothrow pure @safe version(mir_random_test) unittest
{
    import std.meta : AliasSeq;
    foreach (S; AliasSeq!(float, double, real))
    {
        auto f1 = (S x) => 2 * x;

        auto t1 = linearFun!S(f1(1), 1, 1);
        assert(t1.slope == 2);
        assert(t1.intercept == -1);

        auto t2 = linearFun!S(f1(0), 0, 0);
        assert(t2.slope == 0);
        assert(t2.intercept == 0);
    }
}

nothrow pure @safe version(mir_random_test) unittest
{
    import std.math : cos;
    import std.math : PI, approxEqual;
    import std.meta : AliasSeq;
    foreach (S; AliasSeq!(float, double, real))
    {
        auto f = (S x) => cos(x);
        auto buildTan = (S x, S y) => linearFun(f(x), x, y);
        auto t1 = buildTan(0, 0);
        assert(t1.slope == 1);
        assert(t1.intercept == 0);

        auto t2 = buildTan(PI / 2, 1);
        assert(t2.slope.approxEqual(0));
        assert(t2.intercept.approxEqual(1));
    }
}

// test default toString
@safe version(mir_random_test) unittest
{
    import std.format : format;
    auto t = linearFun!double(2, 0, 1);
    assert("%s".format(t) == "LinearFun!double(2, 0, 1)");
}

// test NaN behavior
@safe version(mir_random_test) unittest
{
    import std.format : format;
    auto t = linearFun!double(double.nan, 0, 1);
    assert("%s".format(t) == "LinearFun!double(nan, 0, 1)");
    assert("%l".format(t) == "#NaN#");
}

/**
Compares whether to linear functions are approximately equal.

Params:
    x = first linear function to compare
    y = second linear function to compare
    maxRelDiff = maximum relative difference
    maxAbsDiff = maximum absolute difference

Returns:
    True if both linear functions are approximately equal.
*/
bool approxEqual(S)(LinearFun!S x, LinearFun!S y, S maxRelDiff = 1e-2, S maxAbsDiff = 1e-5)
{
    import std.math : approxEqual;
    return x.slope.approxEqual(y.slope, maxRelDiff, maxAbsDiff) &&
           x.y.approxEqual(y.y, maxRelDiff, maxAbsDiff) &&
           x.a.approxEqual(y.a, maxRelDiff, maxAbsDiff);
}

///
@nogc nothrow pure @safe version(mir_random_test) unittest
{
    auto x = linearFun!double(2, 0, 1);
    auto x2 = linearFun!double(2, 0, 1);
    assert(x.approxEqual(x2));

    auto y = linearFun!double(2, 1e-9, 1);
    assert(x.approxEqual(y));

    auto z = linearFun!double(2, 4, 1);
    assert(!x.approxEqual(z));
}
