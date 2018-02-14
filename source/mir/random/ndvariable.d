/++
$(SCRIPT inhibitQuickIndex = 1;)

$(BOOKTABLE $(H2 Multidimensional Random Variables),

    $(TR $(TH Generator name) $(TH Description))
    $(RVAR Sphere, Uniform distribution on a unit-sphere)
    $(RVAR Simplex, Uniform distribution on a standard-simplex)
    $(RVAR Dirichlet, $(WIKI_D Dirichlet))
    $(RVAR MultivariateNormal, $(WIKI_D Multivariate_normal))
)

Authors: Simon Bürger, Ilya Yaroshenko
Copyright: Mir Community 2017-.
License:    $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Macros:
    WIKI_D = $(HTTP en.wikipedia.org/wiki/$1_distribution, $1 random variable)
    WIKI_D2 = $(HTTP en.wikipedia.org/wiki/$1_distribution, $2 random variable)
    T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
    RVAR = $(TR $(TDNW $(LREF $1Variable)) $(TD $+))
+/
module mir.random.ndvariable;

import mir.random;
import std.traits;
import mir.math.common;
import mir.ndslice;

/++
Uniform distribution on a sphere.
Returns: `X ~ 1` with `X[0]^^2 + .. + X[$-1]^^2 = 1`
+/
struct SphereVariable(T)
    if (isFloatingPoint!T)
{
    ///
    enum isRandomVariable = true;

    ///
    void opCall(G)(scope ref G gen, scope T[] result)
    {
        opCall(gen, result.sliced);
    }
    /// ditto
    void opCall(G)(scope G* gen, scope T[] result)
    {
        opCall(*gen, result.sliced);
    }

    ///
    void opCall(G, SliceKind kind)(scope ref G gen, scope Slice!(kind, [1], T*) result)
        if (isSaturatedRandomEngine!G)
    {
        import mir.math.sum : Summator, Summation;
        import mir.random.variable : NormalVariable;

        assert(result.length);
        Summator!(T, Summation.kbn) summator = 0;
        auto norm = NormalVariable!T(0, 1);
        foreach (ref e; result)
        {
            auto x = e = norm(gen);
            summator += x * x;
        }
        result[] /= summator.sum.sqrt;
    }
    /// ditto
    void opCall(G, SliceKind kind)(scope G* gen, scope Slice!(kind, [1], T*) result)
        if (isSaturatedRandomEngine!G)
    {
        pragma(inline, true);
        opCall(*gen, result);
    }
}

/// ditto
SphereVariable!T sphereVar(T = double)()
    if (isFloatingPoint!T)
{   
    return typeof(return).init;
}

/// Generate random points on a circle
@nogc nothrow @safe version(mir_random_test) unittest
{
    double[2] x;
    sphereVar()(rne, x);
    assert(fabs(x[0] * x[0] + x[1] * x[1] - 1) < 1e-10);
}

@nogc nothrow @safe version(mir_random_test) unittest
{
    Random* gen = threadLocalPtr!Random;
    double[2] x;
    sphereVar()(gen, x);
    assert(fabs(x[0] * x[0] + x[1] * x[1] - 1) < 1e-10);
}

/++
Uniform distribution on a simplex.
Returns: `X ~ 1` with `X[i] >= 0` and `X[0] + .. + X[$-1] = 1`
+/
struct SimplexVariable(T)
    if (isFloatingPoint!T)
{
    ///
    enum isRandomVariable = true;

    ///
    void opCall(G)(scope ref G gen, scope T[] result)
    {
        opCall(gen, result.sliced);
    }
    /// ditto
    void opCall(G)(scope G* gen, scope T[] result)
    {
        opCall(*gen, result.sliced);
    }

    ///
    void opCall(G, SliceKind kind)(scope ref G gen, scope Slice!(kind, [1], T*) result)
        if (isSaturatedRandomEngine!G)
    {
        import mir.ndslice.sorting : sort;
        import mir.ndslice.topology: diff, retro;

        assert(result.length);
        foreach (ref e; result[0 .. $ - 1])
            e = gen.rand!T.fabs;
        result.back = T(1);
        sort(result[0 .. $ - 1]);
        result[1 .. $].retro[] = result.diff.retro;
    }
    /// ditto
    void opCall(G, SliceKind kind)(scope G* gen, scope Slice!(kind, [1], T*) result)
        if (isSaturatedRandomEngine!G)
    {
        pragma(inline, true);
        opCall(*gen, result);
    }
}

/// ditto
SimplexVariable!T simplexVar(T = double)()
    if (isFloatingPoint!T)
{   
    return typeof(return).init;
}

///
@nogc nothrow @safe version(mir_random_test) unittest
{
    auto rv = simplexVar;
    double[3] x;
    rv(rne, x);
    assert(x[0] >= 0 && x[1] >= 0 && x[2] >= 0);
    assert(fabs(x[0] + x[1] + x[2] - 1) < 1e-10);
}

///
@nogc nothrow @safe version(mir_random_test) unittest
{
    Random* gen = threadLocalPtr!Random;
    SimplexVariable!double rv;
    double[3] x;
    rv(gen, x);
    assert(x[0] >= 0 && x[1] >= 0 && x[2] >= 0);
    assert(fabs(x[0] + x[1] + x[2] - 1) < 1e-10);
}

/++
Dirichlet distribution.
+/
struct DirichletVariable(T)
    if (isFloatingPoint!T)
{
    import mir.random.variable : GammaVariable;

    ///
    enum isRandomVariable = true;

    ///
    Slice!(Contiguous, [1], const(T)*) alpha;

    /++
    Params:
        alpha = concentration parameters
    Constraints: `alpha[i] > 0`
    +/
    this()(Slice!(Contiguous, [1], const(T)*) alpha)
    {
        this.alpha = alpha;
    }

    /// ditto
    this()(const(T)[] alpha)
    {
        this.alpha = alpha.sliced;
    }

    ///
    void opCall(G)(scope ref G gen, scope T[] result)
    {
        opCall(gen, result.sliced);
    }
    /// ditto
    void opCall(G)(scope G* gen, scope T[] result)
    {
        opCall(*gen, result.sliced);
    }

    ///
    void opCall(G, SliceKind kind, Iterator)(scope ref G gen, scope Slice!(kind, [1], Iterator) result)
        if (isSaturatedRandomEngine!G)
    {
        assert(result.length == alpha.length);
        import mir.math.sum : Summator, Summation;
        Summator!(T, Summation.kbn) summator = 0;
        foreach (size_t i; 0 .. result.length)
            summator += result[i] = GammaVariable!T(alpha[i], 1)(gen);
        result[] /= summator.sum;
    }
    /// ditto
    void opCall(G, SliceKind kind, Iterator)(scope G* gen, scope Slice!(kind, [1], Iterator) result)
        if (isSaturatedRandomEngine!G)
    {
        pragma(inline, true);
        opCall(*gen, result);
    }
}

/// ditto
DirichletVariable!T dirichletVar(T)(in T[] alpha)
    if (isFloatingPoint!T)
{   
    return typeof(return)(alpha);
}

/// ditto
DirichletVariable!T dirichletVar(T)(Slice!(Contiguous, [1], const(T)*) alpha)
    if (isFloatingPoint!T)
{   
    return typeof(return)(alpha);
}

///
nothrow @safe version(mir_random_test) unittest
{
    auto rv = dirichletVar([1.0, 5.7, 0.3]);
    double[3] x;
    rv(rne, x);
    assert(x[0] >= 0 && x[1] >= 0 && x[2] >= 0);
    assert(fabs(x[0] + x[1] + x[2] - 1) < 1e-10);
}

///
nothrow @safe version(mir_random_test) unittest
{
    Random* gen = threadLocalPtr!Random;
    auto rv = DirichletVariable!double([1.0, 5.7, 0.3]);
    double[3] x;
    rv(gen, x);
    assert(x[0] >= 0 && x[1] >= 0 && x[2] >= 0);
    assert(fabs(x[0] + x[1] + x[2] - 1) < 1e-10);
}

/++
 Compute Cholesky decomposition in place. Only accesses lower/left half of
 the matrix. Returns false if the matrix is not positive definite.
 +/
private bool cholesky(SliceKind kind, Iterator)(scope Slice!(kind, [2], Iterator) m)
    if(isFloatingPoint!(DeepElementType!(typeof(m))))
{
    assert(m.length!0 == m.length!1);

    /* this is a straight-forward implementation of the Cholesky-Crout algorithm
    from https://en.wikipedia.org/wiki/Cholesky_decomposition#Computation */
    foreach(size_t i; 0 .. m.length)
    {
        auto r = m[i];
        foreach(size_t j; 0 .. i)
            r[j] = (r[j] - reduce!"a + b * c"(typeof(r[j])(0), r[0 .. j], m[j, 0 .. j])) / m[j, j];
        r[i] -= reduce!"a + b * b"(typeof(r[i])(0), r[0 .. i]);
        if (!(r[i] > 0)) // this catches nan's as well
            return false;
        r[i] = sqrt(r[i]);
    }
    return true;
}

/++
Multivariate normal distribution.
Beta version (has not properly tested).
+/
struct MultivariateNormalVariable(T)
    if(isFloatingPoint!T)
{
    ///
    enum isRandomVariable = true;

    private size_t n;
    private const(T)* sigma; // cholesky decomposition of covariance matrix
    private const(T)* mu; // mean vector (can be empty)

    /++
    Constructor computes the Cholesky decomposition of `sigma` in place without
    memory allocation. Furthermore it is assumed to be a symmetric matrix, but
    only the lower/left half is actually accessed.

    Params:
        mu = mean vector (assumed zero if not supplied)
        sigma = covariance matrix
        chol = optional flag indicating that sigma is already Cholesky decomposed

    Constraints: sigma has to be positive-definite
    +/
    this()(Slice!(Contiguous, [1], const(T)*) mu, Slice!(Contiguous, [2], T*) sigma, bool chol = false)
    {
        //Check the dimenstions even in release mode to _guarantee_
        //that unless memory corruption has already occurred sigma
        //and mu have the correct dimensions and it is correct in opCall
        //to "@trust" slicing sigma to [n x n] and mu to [n].
        if ((mu.length != sigma.length!0) | (mu.length != sigma.length!1))
            assert(false);

        if(!chol && !cholesky(sigma))
            assert(false, "covariance matrix not positive definite");

        this.n = sigma.length;
        this.mu = mu.iterator;
        this.sigma = sigma.iterator;
    }

    /++ ditto +/
    this()(Slice!(Contiguous, [2], T*) sigma, bool chol = false)
    {
        //Check the dimenstions even in release mode to _guarantee_
        //that unless memory corruption has already occurred sigma
        //and mu have the correct dimensions and it is correct in opCall
        //to "@trust" slicing sigma as (n,n) and slicing mu as (n).
        if (sigma.length!0 != sigma.length!1)
            assert(false);

        if(!chol && !cholesky(sigma))
            assert(false, "covariance matrix not positive definite");

        this.n = sigma.length;
        this.mu = null;
        this.sigma = sigma.iterator;
    }

    ///
    void opCall(G)(scope ref G gen, scope T[] result)
    {
        opCall(gen, result.sliced);
    }

    /// ditto
    void opCall(G)(scope G* gen, scope T[] result)
    {
        opCall(*gen, result.sliced);
    }

    ///
    void opCall(G, SliceKind kind)(scope ref G gen, scope Slice!(kind, [1], T*) result)
        if (isSaturatedRandomEngine!G)
    {
        assert(result.length == n);
        import mir.random.variable : NormalVariable;
        auto norm = NormalVariable!T(0, 1);

        auto s = (() @trusted => sigma.sliced(n, n))();//sigma is n x n matrix.
        foreach(ref e; result)
            e = norm(gen);
        foreach_reverse(size_t i; 0 .. n - 1)
            result[i] = reduce!"a + b * c"(T(0), s[i, 0 .. i + 1], result[0 .. i + 1]);
        if (mu)
            result[] += (() @trusted => mu.sliced(n))();//mu is n vector.
    }
    /// ditto
    void opCall(G, SliceKind kind)(scope G* gen, scope Slice!(kind, [1], T*) result)
        if (isSaturatedRandomEngine!G)
    {
        pragma(inline, true);
        opCall(*gen, result);
    }
}

/// ditto
MultivariateNormalVariable!T multivariateNormalVar(T)(Slice!(Contiguous, [1], const(T)*) mu, Slice!(Contiguous, [2], T*) sigma, bool chol = false)
    if (isFloatingPoint!T)
{   
    return typeof(return)(mu, sigma, chol);
}

/// ditto
MultivariateNormalVariable!T multivariateNormalVar(T)(Slice!(Contiguous, [2], T*) sigma, bool chol = false)
    if (isFloatingPoint!T)
{   
    return typeof(return)(sigma, chol);
}

///
nothrow @safe version(mir_random_test) unittest
{
    auto mu = [10.0, 0.0].sliced;
    auto sigma = [2.0, -1.5, -1.5, 2.0].sliced(2,2);
    auto rv = multivariateNormalVar(mu, sigma);
    double[2] x;
    rv(rne, x[]);
}

///
nothrow @safe version(mir_random_test) unittest
{
    Random* gen = threadLocalPtr!Random;
    auto mu = [10.0, 0.0].sliced;
    auto sigma = [2.0, -1.5, -1.5, 2.0].sliced(2,2);
    auto rv = multivariateNormalVar(mu, sigma);
    double[2] x;
    rv(gen, x[]);
}
