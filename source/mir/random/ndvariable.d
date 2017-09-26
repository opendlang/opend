/++
$(SCRIPT inhibitQuickIndex = 1;)

$(BOOKTABLE $(H2 Utilities),

    $(TR $(TH Name), $(TH Description))
    $(T2 RandomVariable, Attribute)
    $(T2 isRandomVariable, Trait)
)

$(BOOKTABLE $(H2 Multidimensional Random Variables),

    $(TR $(TH Generator name) $(TH Description))
    $(RVAR Sphere, Uniform distribution on a unit-sphere)
    $(RVAR Simplex, Uniform distribution on a standard-simplex)
    $(RVAR Dirichlet, $(WIKI_D Dirichlet))
    $(RVAR MultivariateNormal, $(WIKI_D Multivariate_normal))
)

Authors: Simon Bürger
Copyright: Copyright, Simon Bürger, 2017-.
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
$(Uniform distribution on a sphere).
Returns: `X ~ 1` with `X[0]^^2 + .. + X[$-1]^^2 = 1`
+/
struct SphereVariable(T)
    if (isFloatingPoint!T)
{
    import mir.random.variable : NormalVariable;
    import mir.math.sum : sum;

    ///
    enum isRandomVariable = true;

    private NormalVariable!T norm;

    ///
    void opCall(G)(ref G gen, T[] result)
    {
        opCall(gen, result.sliced);
    }

    ///
    void opCall(G, SliceKind kind, Iterator)(ref G gen, Slice!(kind, [1], Iterator) result)
        if (isSaturatedRandomEngine!G)
    {
        assert(result.length);
        for(size_t i = 0; i < result.length; ++i)
            result[i] = norm(gen);
        result[] /= result.map!"a*a".sum!"kbn".sqrt;
    }
}

/// Generate random points on a circle
unittest
{
    auto gen = Random(unpredictableSeed);
    SphereVariable!double rv;
    double[2] x;
    rv(gen, x);
    assert(fabs(x[0]*x[0] + x[1]*x[1] - 1) < 1e-10);
}

/++
$(Uniform distribution on a simplex).
Returns: `X ~ 1` with `X[i] >= 0` and `X[0] + .. + X[$-1] = 1`
+/
struct SimplexVariable(T)
    if (isFloatingPoint!T)
{
    import mir.ndslice.sorting : sort;
    import mir.math.sum : sum;

    ///
    enum isRandomVariable = true;

    ///
    void opCall(G)(ref G gen, T[] result)
    {
        opCall(gen, result.sliced);
    }

    ///
    void opCall(G, SliceKind kind, Iterator)(ref G gen, Slice!(kind, [1], Iterator) result)
        if (isSaturatedRandomEngine!G)
    {
        assert(result.length);

        for(size_t i = 0; i < result.length; ++i)
            result[i] = gen.rand!T.fabs;
        result[$-1] = T(1);

        sort(result[]);
        for(size_t i = result.length-1; i > 0; --i)
            result[i] = result[i] - result[i-1];
    }
}

///
unittest
{
    auto gen = Random(unpredictableSeed);
    SimplexVariable!double rv;
    double[3] x;
    rv(gen, x);
    assert(x[0] >= 0 && x[1] >= 0 && x[2] >= 0);
    assert(fabs(x[0] + x[1] + x[2] - 1) < 1e-10);
}

/++
$(Dirichlet distribution).
+/
struct DirichletVariable(T, AlphaParams = const(T)[])
    if (isFloatingPoint!T)
{
    import mir.random.variable : GammaVariable;
    import mir.math.sum : sum;

    ///
    enum isRandomVariable = true;

    private AlphaParams alpha;

    /++
    Params:
        alpha = (array of) concentration parameters
    Constraints: `alpha[i] > 0`
    +/
    this(AlphaParams alpha)
    {
        assert(alpha.length >= 1);
        for(size_t i = 0; i < alpha.length; ++i)
            assert(alpha[i] > T(0));

        this.alpha = alpha;
    }

    ///
    void opCall(G)(ref G gen, T[] result)
    {
        opCall(gen, result.sliced);
    }

    ///
    void opCall(G, SliceKind kind, Iterator)(ref G gen, Slice!(kind, [1], Iterator) result)
        if (isSaturatedRandomEngine!G)
    {
        assert(result.length == alpha.length);
        for(size_t i = 0; i < result.length; ++i)
            result[i] = GammaVariable!T(alpha[i])(gen);
        result[] /= result.sum!"kbn";
    }
}

///
unittest
{
    auto gen = Random(unpredictableSeed);
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
private bool cholesky(SliceKind kind, Iterator)(Slice!(kind, [2], Iterator) m)
    if(isFloatingPoint!(DeepElementType!(typeof(m))))
{
    alias dotm = reduce!"a - b * c"; // note the `-`
    assert(m.length!0 == m.length!1);

    /* this is a straight-forward implementation of the Cholesky-Crout algorithm
    from https://en.wikipedia.org/wiki/Cholesky_decomposition#Computation */
    for(size_t i = 0; i < m.length!0; ++i)
    {
        for(size_t j = 0; j < i; ++j)
            m[i,j] = dotm(m[i,j], m[i,0..j], m[j,0..j]) / m[j,j];
        m[i,i] = dotm(m[i,i], m[i,0..i], m[i,0..i]);
        if(!(m[i,i] > 0)) // this catches nan's as well
            return false;
        m[i,i] = sqrt(m[i,i]);
    }
    return true;
}

/++
$(Multivariate normal distribution).
+/
struct MultivariateNormalVariable(T, MuParams = const(T)[], SigmaParams = ContiguousMatrix!T)
    if(isFloatingPoint!T)
{
    import mir.random.variable : NormalVariable;

    ///
    enum isRandomVariable = true;

    private MuParams mu; // mean vector (can be empty)
    private SigmaParams sigma; // cholesky decomposition of covariance matrix
    private NormalVariable!T norm;

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
    this(MuParams mu, SigmaParams sigma, bool chol = false)
    {
        assert(mu.length == sigma.length!0);
        assert(mu.length == sigma.length!1);

        if(!chol && !cholesky(sigma))
            assert(false, "covariance matrix not positive definite");

        this.mu = mu;
        this.sigma = sigma;
        this.norm = NormalVariable!T(0, 1);
    }

    /++ ditto +/
    this(SigmaParams sigma, bool chol = false)
    {
        assert(sigma.length!0 == sigma.length!1);

        if(!chol && !cholesky(sigma))
            assert(false, "covariance matrix not positive definite");

        this.sigma = sigma;
        this.norm = NormalVariable!T(0, 1);
    }

    ///
    void opCall(G)(ref G gen, T[] result)
    {
        opCall(gen, result.sliced);
    }

    ///
    void opCall(G, SliceKind kind, Iterator)(ref G gen, Slice!(kind, [1], Iterator) result)
        if (isSaturatedRandomEngine!G)
    {
        alias dot = reduce!"a + b * c";
        assert(result.length == sigma.length!0);
        for(size_t i = 0; i < result.length; ++i)
            result[i] = norm(gen);
        if(mu.length)
            for(size_t i = result.length; i > 0; --i)
                result[i-1] = dot(mu[i-1], sigma[i-1,0..i], result[0..i]);
        else
            for(size_t i = result.length; i > 0; --i)
                result[i-1] = dot(T(0), sigma[i-1,0..i], result[0..i]);
    }
}

///
unittest
{
    auto gen = Random(unpredictableSeed);
    auto mu = [0.0, 0.0];
    auto sigma = [2.0, -1.5, -1.5, 2.0].sliced(2,2);
    auto rv = MultivariateNormalVariable!double(mu, sigma);
    double[2] x;
    rv(gen, x);
}
