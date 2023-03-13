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
    lambda = coefficient for the integral of the square of the second derivative
    configuration = spline configuration (optional)
Returns: $(FitSplineResult)
+/
FitSplineResult!T fitSpline(alias d = "a - b", T)(
    scope const ref LeastSquaresSettings!T settings,
    scope const T[2][] points,
    scope const T[] x,
    scope const T[] l,
    scope const T[] u,
    const T lambda = 0,
    SplineConfiguration!T configuration = SplineConfiguration!T(),
) @nogc @trusted pure
    if ((is(T == float) || is(T == double)))
    in (lambda >= 0)
{
    pragma(inline, false);

    import mir.functional: naryFun;
    import mir.math.common: sqrt, fabs;
    import mir.ndslice.slice: sliced, Slice;
    import mir.rc.array;

    if (points.length < x.length && lambda == 0)
    {
        static immutable exc = new Exception("fitSpline: points.length has to be greater or equal x.length when lambda is 0.0");
        throw exc;
    }

    FitSplineResult!T ret;

    ret.spline = x.rcarray!(immutable T).moveToSlice.Spline!T;

    auto y = x.length.RCArray!T;
    y[][] = 0;

    scope f = delegate(scope Slice!(const (T)*) splineY, scope Slice!(T*) y)
    {
        assert(y.length == points.length + !lambda);
        ret.spline._values = splineY;
        with(configuration)
            ret.spline._computeDerivatives(kind, param, leftBoundary, rightBoundary);
        foreach (i, ref point; points)
            y[i] = naryFun!d(ret.spline(point[0]), point[1]);

        T integral = 0;
        if (lambda)
        {
            T ld = ret.spline.withTwoDerivatives(x[0])[1];
            foreach (i; 1 .. x.length)
            {
                T rd = ret.spline.withTwoDerivatives(x[i])[1];
                integral += (rd * rd + rd * ld + ld * ld) * (x[i] - x[i - 1]);
                ld = rd;
            }
            assert(integral >= 0);
        }
        y[$ - 1] = sqrt(integral * lambda / 3);
    };

    ret.leastSquaresResult = optimize!(f)(settings, points.length + !lambda, y[].sliced, l[].sliced, u[].sliced);

    return ret;
}

@safe pure
unittest
{
    import mir.test;

    LeastSquaresSettings!double settings;

    auto x = [-1.0, 2, 4, 5, 8, 10, 12, 15, 19, 22];

    auto y = [17.0, 0, 16, 4, 10, 15, 19, 5, 18, 6];

    auto l = new double[x.length];
    l[] = -double.infinity;

    auto u = new double[x.length];
    u[] = +double.infinity;
    import mir.stdio;

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
    ];

    auto result = settings.fitSpline(points, x, l, u, 0);

    foreach (i; 0 .. x.length)
        result.spline(x[i]).shouldApprox == y[i];

    result = settings.fitSpline(points, x, l, u, 1);

    // this case sensetive for numeric noise
    y = [
        0.1971683531479794,
        5.936895050720581,
        7.451651002121712,
        5.122509287945581,
        11.908292461047825,
        13.701350302891292,
        16.97948422229589,
        7.868130112291985,
        16.20637990062554,
        19.58302823176968,
    ];

    foreach (i; 0 .. x.length)
        result.spline(x[i]).shouldApprox == y[i];
}
