module mir.optim.fit_spline;

import mir.optim.least_squares;
import mir.interpolate.spline;

///
struct FitSplineResult(T)
{
    ///
    LeastSquaresResult!T leastSquaresResult;
    ///
    Spline!T spline;
}

/++
Params:
    settings = LMA settings
    points = points to fit
    x = fixed X values of the spline
    l = lower bounds for spline(X) values
    u = upper bounds for spline(X) values
    configuration = spline configuration (optional)
Returns: $(FitSplineResult)
+/
FitSplineResult!T fitSpline(alias d = "a - b", T)(
    scope ref LeastSquaresSettings!T settings,
    scope const T[2][] points,
    scope const T[] x,
    scope const T[] l,
    scope const T[] u,
    SplineConfiguration!T configuration = SplineConfiguration!T(),
) @nogc @trusted pure
    if ((is(T == float) || is(T == double)))
{
    pragma(inline, false);

    import mir.ndslice.slice: sliced, Slice;

    if (points.length < x.length)
    {
        static immutable exc = new Exception("fitSpline: points.length has to be greater or equal x.length");
        throw exc;
    }

    import mir.functional: naryFun;
    import mir.rc.array;

    FitSplineResult!T ret;

    ret.spline = x.rcarray!(immutable T).moveToSlice.Spline!T;

    auto y = x.length.RCArray!T;
    y[][] = 0;

    scope f = delegate(scope Slice!(const (T)*) x, scope Slice!(T*) y)
    {
        assert(y.length == points.length);
        ret.spline._values = x;
        with(configuration)
            ret.spline._computeDerivatives(kind, param, leftBoundary, rightBoundary);
        foreach (i, ref point; points)
            y[i] = naryFun!d(ret.spline(point[0]), point[1]);
    };

    ret.leastSquaresResult = optimize!(f)(settings, points.length, y[].sliced, l.sliced, u.sliced);

    return ret;
}

@safe pure
unittest
{

    LeastSquaresSettings!double settings;

    auto x = [-1.0, 2, 4, 5, 8, 10, 12, 15, 19, 22];

    auto y = [17.0, 0, 16, 4, 10, 15, 19, 5, 18, 6];

    auto l = new double[x.length];
    l[] = -double.infinity;

    auto u = new double[x.length];
    u[] = +double.infinity;

    double[2][] points = [
        [x[0] + 0.5, -0.68361541],
        [x[1] + 0.5,  7.28568719],
        [x[2] + 0.5, 10.490694  ],
        [x[3] + 0.5,  0.36192032],
        [x[4] + 0.5, 11.91572713],
        [x[5] + 0.5, 16.44546433],
        [x[6] + 0.5, 17.66699525],
        [x[7] + 0.5,  4.52730869],
        [x[8] + 0.5, 19.22825394],
        [x[9] + 0.5, -2.3242592 ],
    ]; // length of X or more

    auto result = settings.fitSpline(points, x, l, u);

    import mir.test;
    foreach (i; 0 .. x.length)
        result.spline(x[i]).shouldApprox == y[i];
}
