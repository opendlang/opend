/++
This module contains betterC compatible quadrature computation routines.
+/
module mir.quadrature;

import mir.math.common: sqrt, exp;
import mir.math.constant: PI, LN2;

@safe pure nothrow:

version(LDC){} else
@nogc extern(C)
{
    double lgamma(double);
    double tgamma(double);
}

/++
Gauss-Hermite Quadrature

Params:
    x = (out) user-allocated quadrature nodes in ascending order length of `N`
    w = (out) user-allocated corresponding quadrature weights length of `N`
    work = (temp) user-allocated workspace length of greate or equal to `(N + 1) ^^ 2`

Returns: 0 on success, `xSTEQR` LAPACK code on numerical error.

+/
size_t gaussHermiteQuadrature(T)(
    scope T[] x,
    scope T[] w,
    scope T[] work) @nogc
in {
    assert(x.length == w.length);
    if (x.length)
        assert(work.length >= x.length ^^ 2);
}
do {
    enum T mu0 = sqrt(PI);
    foreach (i; 0 .. x.length)
    {
        x[i] = 0;
        w[i] = T(0.5) * i;
    }
    return gaussQuadratureImpl!T(x, w, work, mu0, true);
}

///
unittest
{
    import mir.math.common;
    import mir.ndslice.allocation;

    auto n = 5;
    auto x = new double[n];
    auto w = new double[n];
    auto work = new double[(n + 1) ^^ 2];

    gaussHermiteQuadrature(x, w, work);

    static immutable xc =
       [-2.02018287,
        -0.95857246,
         0.        ,
         0.95857246,
         2.02018287];

    static immutable wc =
       [0.01995324,
        0.39361932,
        0.94530872,
        0.39361932,
        0.01995324];

    foreach (i; 0 .. n)
    {
        assert(x[i].approxEqual(xc[i]));
        assert(w[i].approxEqual(wc[i]));
    }
}

/++
Gauss-Jacobi Quadrature

Params:
    x = (out) user-allocated quadrature nodes in ascending order length of `N`
    w = (out) user-allocated corresponding quadrature weights length of `N`
    work = (temp) user-allocated workspace length of greate or equal to `(N + 1) ^^ 2`
    alpha = parameter '> -1'
    beta = parameter '> -1'

Returns: 0 on success, `xSTEQR` LAPACK code on numerical error.

+/
size_t gaussJacobiQuadrature(T)(
    scope T[] x,
    scope T[] w,
    scope T[] work,
    T alpha,
    T beta) @nogc
in {
    assert(T.infinity > alpha && alpha > -1);
    assert(T.infinity > beta && beta > -1);
    assert(x.length == w.length);
    if (x.length)
        assert(work.length >= x.length ^^ 2);
}
do {
    if (x.length == 0)
        return 0;
    auto s = alpha + beta;
    auto d = beta - alpha;
    version (LDC) import core.stdc.math: lgamma;
    auto mu0 = exp(double(LN2) * (s + 1) + (lgamma(double(alpha + 1)) + lgamma(double(beta + 1)) - lgamma(double(s + 2))));
    x[0] = d / (s + 2);
    const sd = s * d;
    foreach (i; 1 .. x.length)
    {
        const m_i = T(1) / i;
        const q = (2 + s * m_i);
        x[i] = sd * (m_i * m_i) / (q * (2 + (s + 2) * m_i));
        w[i] = 4 * (1 + alpha * m_i) * (1 + beta * m_i) * (1 + s * m_i)
            / ((2 + (s + 1) * m_i) * (2 + (s - 1) * m_i) * (q * q));
    }
    return gaussQuadratureImpl!T(x, w, work, mu0);
}

///
unittest
{
    import mir.math.common;
    import mir.ndslice.allocation;

    auto n = 5;
    auto x = new double[n];
    auto w = new double[n];
    auto work = new double[(n + 1) ^^ 2];

    gaussJacobiQuadrature(x, w, work, 2.3, 3.6);

    static immutable xc =
       [-0.6553677 ,
        -0.29480426,
         0.09956621,
         0.47584565,
         0.78356514];

    static immutable wc =
       [0.02262392,
        0.19871672,
        0.43585107,
        0.32146619,
        0.0615342 ];

    foreach (i; 0 .. n)
    {
        assert(x[i].approxEqual(xc[i]));
        assert(w[i].approxEqual(wc[i]));
    }
}

/++
Gauss-Laguerre Quadrature

Params:
    x = (out) user-allocated quadrature nodes in ascending order length of `N`
    w = (out) user-allocated corresponding quadrature weights length of `N`
    work = (temp) user-allocated workspace length of greate or equal to `(N + 1) ^^ 2`
    alpha = (optional) parameter '> -1'

Returns: 0 on success, `xSTEQR` LAPACK code on numerical error.

+/
size_t gaussLaguerreQuadrature(T)(
    scope T[] x,
    scope T[] w,
    scope T[] work,
    T alpha = 0) @nogc
in {
    assert(T.infinity > alpha && alpha > -1);
    assert(x.length == w.length);
    if (x.length)
        assert(work.length >= x.length ^^ 2);
}
do {

    version (LDC) import core.stdc.math: tgamma;
    auto mu0 = tgamma(double(alpha + 1));
    foreach (i; 0 .. x.length)
    {
        x[i] = 2 * i + (1 + alpha);
        w[i] = i * (i + alpha);
    }
    return gaussQuadratureImpl!T(x, w, work, mu0);
}

///
unittest
{
    import mir.math.common;
    import mir.ndslice.allocation;

    auto n = 5;
    auto x = new double[n];
    auto w = new double[n];
    auto work = new double[(n + 1) ^^ 2];

    gaussLaguerreQuadrature(x, w, work);

    static immutable xc =
       [ 0.26356032,
         1.41340306,
         3.59642577,
         7.08581001,
        12.64080084];

    static immutable wc =
       [5.21755611e-01,
        3.98666811e-01,
        7.59424497e-02,
        3.61175868e-03,
        2.33699724e-05];

    foreach (i; 0 .. n)
    {
        assert(x[i].approxEqual(xc[i]));
        assert(w[i].approxEqual(wc[i]));
    }
}

/++
Gauss-Legendre Quadrature

Params:
    x = (out) user-allocated quadrature nodes in ascending order length of `N`
    w = (out) user-allocated corresponding quadrature weights length of `N`
    work = (temp) user-allocated workspace length of greate or equal to `(N + 1) ^^ 2`

Returns: 0 on success, `xSTEQR` LAPACK code on numerical error.

+/
size_t gaussLegendreQuadrature(T)(
    scope T[] x,
    scope T[] w,
    scope T[] work) @nogc
in {
    assert(x.length == w.length);
    if (x.length)
        assert(work.length >= x.length ^^ 2);
}
do {
    if (x.length == 0)
        return 0;
    enum mu0 = 2;
    x[0] = 0;
    foreach (i; 1 .. x.length)
    {
        const m_i = T(1) / i;
        x[i] = 0;
        w[i] = 1 / (4 - (m_i * m_i));
    }
    return gaussQuadratureImpl!T(x, w, work, mu0, true);
}

///
unittest
{
    import mir.math.common;
    import mir.ndslice.allocation;

    auto n = 5;
    auto x = new double[n];
    auto w = new double[n];
    auto work = new double[(n + 1) ^^ 2];

    gaussLegendreQuadrature(x, w, work);

    static immutable xc =
       [-0.90617985,
        -0.53846931,
         0.        ,
         0.53846931,
         0.90617985];

    static immutable wc =
       [0.23692689,
        0.47862867,
        0.56888889,
        0.47862867,
        0.23692689];

    foreach (i; 0 .. n)
    {
        assert(x[i].approxEqual(xc[i]));
        assert(w[i].approxEqual(wc[i]));
    }
}

private size_t gaussQuadratureImpl(T)(
    scope T[] alpha_x,
    scope T[] beta_w,
    scope T[] work,
    double mu0,
    bool symmetrize = false) @nogc
in {
    assert(alpha_x.length == beta_w.length);
    if (alpha_x.length)
        assert(work.length >= (alpha_x.length + 1) ^^ 2);
    foreach (ref b; beta_w[1 .. $])
        assert (T.infinity > b && b > 0);
}
do {
    pragma(inline, false);
    auto n = alpha_x.length;
    if (n == 0)
        return n;
    foreach (ref b; beta_w[1 .. n])
        b = b.sqrt;
    auto nq = n * n;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: canonical;
    import mir.lapack: steqr;
    auto z = work[0 .. nq].sliced(n, n);
    auto info = steqr('I', alpha_x.sliced, beta_w[1 .. $].sliced, z.canonical, work[nq .. $].sliced);
    foreach (i; 0 .. n)
    {
        auto zi0 = z[i, 0];
        beta_w[i] = zi0 * zi0 * mu0;
    }
    if (symmetrize)
    {
        auto h = n / 2;
        alias x = alpha_x;
        alias w = beta_w;
        foreach (i; 0 .. h)
        {
            x[i] = -(x[n - (i + 1)] = T(0.5) * (x[n - (i + 1)] - x[i]));
            w[i] = +(w[n - (i + 1)] = T(0.5) * (w[n - (i + 1)] + w[i]));
        }
        if (n % 2)
        {
            x[h] = 0;
        }
    }
    return info;
}
