module mir.random.flex.internal.calc;

import mir.random.flex.internal.types : Interval;

/**
Calculate the mean between two points using the arcmean:

    tan(0.5 * (atan(l) + atan(r)))

In contrast to the normal mean (`0.5 * (l + r)`) being a geometric plane,
the arcmean favors the mean region more.

Params:
    iv = Interval with left point and right point

Returns:
    Splitting point within the interval

See_Also:
    WolframAlpha visualization of the arc-mean.

References:
    Hormann, W., J. Leydold, and G. Derflinger.
    "Automatic Nonuniform Random Number Generation." (2004): Formula 4.23
*/
auto arcmean(S)(const scope ref Interval!S iv)
{
    import std.math: atan, tan;
    // Use at least double precision trigonometric functions.
    static if (S.mant_dig < double.mant_dig)
        alias T = double;
    else
        alias T = S;

    with(iv)
    {
        if (rx < -S(1e3) || lx > S(1e3))
            return 2 / (1 / lx + 1 / rx);

        immutable d = atan(cast(T) lx);
        immutable b = atan(cast(T) rx);

        assert(d <= b);
        if (b - d < S(1e-6))
            return S(0.5) * lx + S(0.5) * rx;

        return tan(S(0.5) * (d + b));
    }
}
