/++
$(H1 Nonlinear Least Squares Solver)

Copyright: Copyright © 2018, Symmetry Investments & Kaleidic Associates Advisory Limited
Authors:   Ilya Yaroshenko

Macros:
NDSLICE = $(REF_ALTTEXT $(TT $2), $2, mir, ndslice, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
+/
module mir.optim.least_squares;

import mir.ndslice.slice: Slice, SliceKind, Contiguous, sliced;
import std.meta;
import std.traits;
import lapack: lapackint;

/++
+/
enum LeastSquaresStatus
{
    /// Maximum number of iterations reached
    maxIterations = -1,
    /// The algorithm cann't improve the solution
    furtherImprovement,
    /// Stationary values
    xConverged,
    /// Stationary gradient
    gConverged,
    /// Good (small) residual
    fConverged,
    ///
    badBounds = -32,
    ///
    badGuess,
    ///
    badMinStepQuality,
    ///
    badGoodStepQuality,
    ///
    badStepQuality,
    ///
    badLambdaParams,
    ///
    numericError,
}

version(D_Exceptions)
{
    /+
    Exception for $(LREF optimize).
    +/
    private static immutable leastSquaresException_maxIterations = new Exception("mir-optim Least Squares: " ~ LeastSquaresStatus.maxIterations.leastSquaresStatusString);
    private static immutable leastSquaresException_badBounds = new Exception("mir-optim Least Squares: " ~ LeastSquaresStatus.badBounds.leastSquaresStatusString);
    private static immutable leastSquaresException_badGuess = new Exception("mir-optim Least Squares: " ~ LeastSquaresStatus.badGuess.leastSquaresStatusString);
    private static immutable leastSquaresException_badMinStepQuality = new Exception("mir-optim Least Squares: " ~ LeastSquaresStatus.badMinStepQuality.leastSquaresStatusString);
    private static immutable leastSquaresException_badGoodStepQuality = new Exception("mir-optim Least Squares: " ~ LeastSquaresStatus.badGoodStepQuality.leastSquaresStatusString);
    private static immutable leastSquaresException_badStepQuality = new Exception("mir-optim Least Squares: " ~ LeastSquaresStatus.badStepQuality.leastSquaresStatusString);
    private static immutable leastSquaresException_badLambdaParams = new Exception("mir-optim Least Squares: " ~ LeastSquaresStatus.badLambdaParams.leastSquaresStatusString);
    private static immutable leastSquaresException_numericError = new Exception("mir-optim Least Squares: " ~ LeastSquaresStatus.numericError.leastSquaresStatusString);
    private static immutable leastSquaresExceptions = [
        leastSquaresException_badBounds,
        leastSquaresException_badGuess,
        leastSquaresException_badMinStepQuality,
        leastSquaresException_badGoodStepQuality,
        leastSquaresException_badStepQuality,
        leastSquaresException_badLambdaParams,
        leastSquaresException_numericError,
    ];
}

/// Delegates for low level D API.
alias LeastSquaresFunction(T) = void delegate(Slice!(const(T)*) x, Slice!(T*) y) @safe nothrow @nogc pure;
/// ditto
alias LeastSquaresJacobian(T) = void delegate(Slice!(const(T)*) x, Slice!(T*, 2) J) @safe nothrow @nogc pure;

/// Delegates for low level C API.
alias LeastSquaresFunctionBetterC(T) = extern(C) void function(scope void* context, size_t m, size_t n, const(T)* x, T* y) @system nothrow @nogc pure;
///
alias LeastSquaresJacobianBetterC(T) = extern(C) void function(scope void* context, size_t m, size_t n, const(T)* x, T* J) @system nothrow @nogc pure;

/++
Least-Squares iteration settings.
+/
struct LeastSquaresSettings(T)
    if (is(T == double) || is(T == float))
{
    import mir.optim.boxcqp;
    import mir.math.common: sqrt;
    import mir.math.constant: GoldenRatio;
    import lapack: lapackint;

    /// Maximum number of iterations
    uint maxIterations = 1000;
    /// Maximum jacobian model age (0 for default selection)
    uint maxAge;
    /// epsilon for finite difference Jacobian approximation
    T jacobianEpsilon = T(2) ^^ ((1 - T.mant_dig) / 2);
    /// Absolute tolerance for step size, L2 norm
    T absTolerance = T.epsilon;
    /// Relative tolerance for step size, L2 norm
    T relTolerance = 0;
    /// Absolute tolerance for gradient, L-inf norm
    T gradTolerance = T.epsilon;
    /// The algorithm stops iteration when the residual value is less or equal to `maxGoodResidual`.
    T maxGoodResidual = T.epsilon ^^ 2;
    /// maximum norm of iteration step
    T maxStep = T.max.sqrt / 16;
    /// minimum trust region radius
    T maxLambda = T.max / 16;
    /// maximum trust region radius
    T minLambda = T.min_normal * 16;
    /// for steps below this quality, the trust region is shrinked
    T minStepQuality = 0.1;
    /// for steps above this quality, the trust region is expanded
    T goodStepQuality = 0.5;
    /// `lambda` is multiplied by this factor after step below min quality
    T lambdaIncrease = 2;
    /// `lambda` is multiplied by this factor after good quality steps
    T lambdaDecrease = 1 / (GoldenRatio * 2);
    /// Bound constrained convex quadratic problem settings
    BoxQPSettings!T qpSettings;
}

/++
Least-Squares results.
+/
struct LeastSquaresResult(T)
    if (is(T == double) || is(T == float))
{
    /// Computation status
    LeastSquaresStatus status = LeastSquaresStatus.numericError;
    /// Successful step count
    uint iterations;
    /// Number of the function calls
    uint fCalls;
    /// Number of the Jacobian calls
    uint gCalls;
    /// Final residual
    T residual = T.infinity;
    /// LMA variable for (inverse of) initial trust region radius
    T lambda = 0;
}

/++
High level D API for Levenberg-Marquardt Algorithm.

Computes the argmin over x of `sum_i(f(x_i)^2)` using the Levenberg-Marquardt
algorithm, and an estimate of the Jacobian of `f` at x.

The function `f` should take an input vector of length `n`, and fill an output
vector of length `m`.

The function `g` is the Jacobian of `f`, and should fill a row-major `m x n` matrix. 

Throws: $(LREF LeastSquaresException)
Params:
    f = `n -> m` function
    g = `m × n` Jacobian (optional)
    tm = thread manager for finite difference jacobian approximation in case of g is null (optional)
    settings = Levenberg-Marquardt data structure
    taskPool = task Pool with `.parallel` method for finite difference jacobian approximation in case of g is null (optional)
See_also: $(LREF optimizeLeastSquares)
+/
LeastSquaresResult!T optimize(alias f, alias g = null, alias tm = null, T)(
    scope ref LeastSquaresSettings!T settings,
    size_t m,
    Slice!(T*) x,
    Slice!(const(T)*) l,
    Slice!(const(T)*) u,
)
    if ((is(T == float) || is(T == double)))
{
    auto ret = optimizeLeastSquares!(f, g, tm, T)(settings, m, x, l, u);
    if (ret.status == -1)
        throw leastSquaresException_maxIterations;
    else
    if (ret.status < -1)
        throw leastSquaresExceptions[ret.status + 32];
    return ret;
}

/// ditto
LeastSquaresResult!T optimize(alias f, TaskPool, T)(
    scope ref LeastSquaresSettings!T settings,
    size_t m,
    Slice!(T*) x,
    Slice!(const(T)*) l,
    Slice!(const(T)*) u,
    TaskPool taskPool)
    if (is(T == float) || is(T == double))
{
    auto tm = delegate(uint count, scope LeastSquaresTask task)
    {
        version(all)
        {
            import mir.ndslice.topology: iota;
            foreach(i; taskPool.parallel(count.iota!uint))
                task(cast(uint)taskPool.size, cast(uint)(taskPool.size <= 1 ? 0 : taskPool.workerIndex - 1), i);
        }
        else // for debug
        {
            foreach(i; 0 .. count)
                task(1, 0, i);
        }
    };

    auto ret = optimizeLeastSquares!(f, null, tm, T)(settings, m, x, l, u);
    if (ret.status == -1)
        throw leastSquaresException_maxIterations;
    else
    if (ret.status < -1)
        throw leastSquaresExceptions[ret.status + 32];
    return ret;
}

/// With Jacobian
version(mir_optim_test)
@safe unittest
{
    import mir.ndslice.allocation: slice;
    import mir.ndslice.slice: sliced;
    import mir.blas: nrm2;

    LeastSquaresSettings!double settings;
    auto x = [100.0, 100].sliced;
    auto l = x.shape.slice(-double.infinity);
    auto u = x.shape.slice(+double.infinity);
    optimize!(
        (x, y)
        {
            y[0] = x[0];
            y[1] = 2 - x[1];
        },
        (x, J)
        {
            J[0, 0] = 1;
            J[0, 1] = 0;
            J[1, 0] = 0;
            J[1, 1] = -1;
        },
    )(settings, 2, x, l, u);

    assert(nrm2((x - [0, 2].sliced).slice) < 1e-8);
}

/// Using Jacobian finite difference approximation computed using in multiple threads.
version(mir_optim_test)
unittest
{
    import mir.ndslice.allocation: slice;
    import mir.ndslice.slice: sliced;
    import mir.blas: nrm2;
    import std.parallelism: taskPool;

    LeastSquaresSettings!double settings;
    auto x = [-1.2, 1].sliced;
    auto l = x.shape.slice(-double.infinity);
    auto u = x.shape.slice(+double.infinity);
    settings.optimize!(
        (x, y) // Rosenbrock function
        {
            y[0] = 10 * (x[1] - x[0]^^2);
            y[1] = 1 - x[0];
        },
    )(2, x, l, u, taskPool);

    // import std.stdio;
    // writeln(settings);
    // writeln(x);

    assert(nrm2((x - [1, 1].sliced).slice) < 1e-6);
}

/// Rosenbrock
version(mir_optim_test)
@safe unittest
{
    import mir.algorithm.iteration: all;
    import mir.ndslice.allocation: slice;
    import mir.ndslice.slice: Slice, sliced;
    import mir.blas: nrm2;

    LeastSquaresSettings!double settings;
    auto x = [-1.2, 1].sliced;
    auto l = x.shape.slice(-double.infinity);
    auto u = x.shape.slice(+double.infinity);

    alias rosenbrockRes = (x, y)
    {
        y[0] = 10 * (x[1] - x[0]^^2);
        y[1] = 1 - x[0];
    };

    alias rosenbrockJac = (x, J)
    {
        J[0, 0] = -20 * x[0];
        J[0, 1] = 10;
        J[1, 0] = -1;
        J[1, 1] = 0;
    };

    static class FFF
    {
        static auto opCall(Slice!(const(double)*) x, Slice!(double*, 2) J)
        {
            rosenbrockJac(x, J);
        }
    }

    settings.optimize!(rosenbrockRes, FFF)(2, x, l, u);

    // import std.stdio;

    // writeln(settings.iterations, " ", settings.fCalls, " ", settings.gCalls, " x = ", x);

    assert(nrm2((x - [1, 1].sliced).slice) < 1e-8);

    /////

    settings = settings.init;
    x[] = [150.0, 150.0];
    l[] = [10.0, 10.0];
    u[] = [200.0, 200.0];

    settings.optimize!(rosenbrockRes, rosenbrockJac)(2, x, l, u);

    // writeln(settings.iterations, " ", settings.fCalls, " ", settings.gCalls, " ", x);
    assert(nrm2((x - [10, 100].sliced).slice) < 1e-5);
    assert(x.all!"a >= 10");
}

///
version(mir_optim_test)
@safe unittest
{
    import mir.blas: nrm2;
    import mir.math.common;
    import mir.ndslice.allocation: slice;
    import mir.ndslice.topology: linspace, map;
    import mir.ndslice.slice: sliced;
    import mir.random;
    import mir.random.algorithm;
    import mir.random.variable;
    import std.parallelism: taskPool;

    alias model = (x, p) => p[0] * map!exp(-x * p[1]);

    auto p = [1.0, 2.0];

    auto xdata = [20].linspace([0.0, 10.0]);
    auto rng = Random(12345);
    auto ydata = slice(model(xdata, p) + 0.01 * rng.randomSlice(normalVar, xdata.shape));

    auto x = [0.5, 0.5].sliced;
    auto l = x.shape.slice(-double.infinity);
    auto u = x.shape.slice(+double.infinity);

    LeastSquaresSettings!double settings;
    settings.optimize!((p, y) => y[] = model(xdata, p) - ydata)(ydata.length, x, l, u);

    assert((x - [1.0, 2.0].sliced).slice.nrm2 < 0.05);
}

///
version(mir_optim_test)
@safe pure unittest
{
    import mir.algorithm.iteration: all;
    import mir.ndslice.allocation: slice;
    import mir.ndslice.topology: map, repeat, iota;
    import mir.ndslice.slice: sliced;
    import mir.random;
    import mir.random.variable;
    import mir.random.algorithm;
    import mir.math.common;

    alias model = (x, p) => p[0] * map!exp(-x / p[1]) + p[2];

    auto xdata = iota([100], 1);
    auto rng = Random(12345);
    auto ydata = slice(model(xdata, [10.0, 10.0, 10.0]) + 0.1 * rng.randomSlice(normalVar, xdata.shape));

    LeastSquaresSettings!double settings;

    auto x = [15.0, 15.0, 15.0].sliced;
    auto l = [5.0, 11.0, 5.0].sliced;
    auto u = x.shape.slice(+double.infinity);

    settings.optimize!((p, y) => y[] = model(xdata, p) - ydata)
        (ydata.length, x, l, u);

    assert(all!"a >= b"(x, l));

    // import std.stdio;

    // writeln(x);
    // writeln(settings.iterations, " ", settings.fCalls, " ", settings.gCalls);

    settings = settings.init;
    x[] = [5.0, 5.0, 5.0];
    l[] = -double.infinity;
    u[] = [15.0, 9.0, 15.0];
    settings.optimize!((p, y) => y[] = model(xdata, p) - ydata)
        (ydata.length, x, l , u);

    assert(x.all!"a <= b"(u));

    // writeln(x);
    // writeln(settings.iterations, " ", settings.fCalls, " ", settings.gCalls);
}

///
version(mir_optim_test)
@safe pure unittest
{
    import mir.blas: nrm2;
    import mir.math.common: sqrt;
    import mir.ndslice.allocation: slice;
    import mir.ndslice.slice: sliced;

    LeastSquaresSettings!double settings;
    auto x = [0.001, 0.0001].sliced;
    auto l = [-0.5, -0.5].sliced;
    auto u = [0.5, 0.5].sliced;
    settings.optimize!(
        (x, y)
        {
            y[0] = sqrt(1 - (x[0] ^^ 2 + x[1] ^^ 2));
        },
    )(1, x, l, u);

    assert(nrm2((x - u).slice) < 1e-8);
}

/++
High level nothtow D API for Levenberg-Marquardt Algorithm.

Computes the argmin over x of `sum_i(f(x_i)^2)` using the Least-Squares
algorithm, and an estimate of the Jacobian of `f` at x.

The function `f` should take an input vector of length `n`, and fill an output
vector of length `m`.

The function `g` is the Jacobian of `f`, and should fill a row-major `m x n` matrix. 

Returns: optimization status.
Params:
    f = `n -> m` function
    g = `m × n` Jacobian (optional)
    tm = thread manager for finite difference jacobian approximation in case of g is null (optional)
    settings = Levenberg-Marquardt data structure
    m = length (dimension) of `y = f(x)`
    x = initial (in) and final (out) X value
    l = lower X bound
    u = upper X bound
See_also: $(LREF optimize)
+/
LeastSquaresResult!T optimizeLeastSquares(alias f, alias g = null, alias tm = null, T)(
    scope ref LeastSquaresSettings!T settings,
    size_t m,
    Slice!(T*) x,
    Slice!(const(T)*) l,
    Slice!(const(T)*) u,
)
{
    auto fInst = delegate(Slice!(const(T)*) x, Slice!(T*) y)
    {
        f(x, y);
    };
    if (false)
    {
        fInst(x, x);
    }
    static if (is(typeof(g) == typeof(null)))
        enum LeastSquaresJacobian!T gInst = null;
    else
    {
        auto gInst = delegate(Slice!(const(T)*) x, Slice!(T*, 2) J)
        {
            g(x, J);
        };
        static if (isNullableFunction!(g))
            if (!g)
                gInst = null;
        if (false)
        {
            Slice!(T*, 2) J;
            gInst(x, J);
        }
    }

    static if (is(typeof(tm) == typeof(null)))
        enum LeastSquaresThreadManager tmInst = null;
    else
    {
        auto tmInst = delegate(
            uint count,
            scope LeastSquaresTask task)
        {
            tm(count, task);
        };
        static if (isNullableFunction!(tm))
            if (!tm)
                tmInst = null;
        if (false) with(settings)
            tmInst(0, null);
    }

    auto n = x.length;
    import mir.ndslice.allocation: rcslice;
    auto work = rcslice!T(mir_least_squares_work_length(m, n));
    auto iwork = rcslice!lapackint(mir_least_squares_iwork_length(m, n));
    auto workS = work.lightScope;
    auto iworkS = iwork.lightScope;
    return optimizeLeastSquares!T(settings, m, x, l, u, workS, iworkS, fInst.trustedAllAttr, gInst.trustedAllAttr, tmInst.trustedAllAttr);
}

/++
Status string for low (extern) and middle (nothrow) levels D API.
Params:
    st = optimization status
Returns: description for $(LeastSquaresStatus)
+/
pragma(inline, false)
string leastSquaresStatusString(LeastSquaresStatus st) @safe pure nothrow @nogc
{
    final switch(st) with(LeastSquaresStatus)
    {
        case furtherImprovement:
            return "The algorithm cann't improve the solution";
        case maxIterations:
            return "Maximum number of iterations reached";
        case xConverged:
            return "X converged";
        case gConverged:
            return "Jacobian converged";
        case fConverged:
            return "Residual is small enough";
        case badBounds:
            return "Initial guess must be within bounds.";
        case badGuess:
            return "Initial guess must be an array of finite numbers.";
        case badMinStepQuality:
            return "0 <= minStepQuality < 1 must hold.";
        case badGoodStepQuality:
            return "0 < goodStepQuality <= 1 must hold.";
        case badStepQuality:
            return "minStepQuality < goodStepQuality must hold.";
        case badLambdaParams:
            return "1 <= lambdaIncrease && lambdaIncrease <= T.max.sqrt and T.min_normal.sqrt <= lambdaDecrease && lambdaDecrease <= 1 must hold.";
        case numericError:
            return "Numeric Error";
    }
}

///
alias LeastSquaresTask = void delegate(
        uint totalThreads,
        uint threadId,
        uint i)
    @safe nothrow @nogc pure;

///
alias LeastSquaresTaskBetterC = extern(C) void function(
        scope const LeastSquaresTask,
        uint totalThreads,
        uint threadId,
        uint i)
    @safe nothrow @nogc pure;

/// Thread manager delegate type for low level `extern(D)` API.
alias LeastSquaresThreadManager = void delegate(
        uint count,
        scope LeastSquaresTask task)
    @safe nothrow @nogc pure;

/++
Low level `extern(D)` instatiation.
Params:
    settings = Levenberg-Marquardt data structure
    m = length (dimension) of `y = f(x)`
    x = initial (in) and final (out) X value
    l = lower X bound
    u = upper X bound
    f = `n -> m` function
    g = `m × n` Jacobian (optional)
    tm = thread manager for finite difference jacobian approximation in case of g is null (optional)
    work = floating point workspace length of at least $(LREF mir_least_squares_work_length)
    iwork = floating point workspace length of at least $(LREF mir_least_squares_iwork_length)
+/
pragma(inline, false)
LeastSquaresResult!double optimizeLeastSquaresD
    (
        scope ref LeastSquaresSettings!double settings,
        size_t m,
        Slice!(double*) x,
        Slice!(const(double)*) l,
        Slice!(const(double)*) u,
        Slice!(double*) work,
        Slice!(lapackint*) iwork,
        scope LeastSquaresFunction!double f,
        scope LeastSquaresJacobian!double g = null,
        scope LeastSquaresThreadManager tm = null,
    ) @trusted nothrow @nogc pure
{
    return optimizeLeastSquaresImplGeneric!double(settings, m, x, l, u, work, iwork, f, g, tm);
}


/// ditto
pragma(inline, false)
LeastSquaresResult!float optimizeLeastSquaresS
    (
        scope ref LeastSquaresSettings!float settings,
        size_t m,
        Slice!(float*) x,
        Slice!(const(float)*) l,
        Slice!(const(float)*) u,
        Slice!(float*) work,
        Slice!(lapackint*) iwork,
        scope LeastSquaresFunction!float f,
        scope LeastSquaresJacobian!float g = null,
        scope LeastSquaresThreadManager tm = null,
    ) @trusted nothrow @nogc pure
{
    return optimizeLeastSquaresImplGeneric!float(settings, 2, x, l, u, work, iwork, f, g, tm);
}

/// ditto
alias optimizeLeastSquares(T : double) = optimizeLeastSquaresD;
/// ditto
alias optimizeLeastSquares(T : float) = optimizeLeastSquaresS;

extern(C) @safe nothrow @nogc
{
    /++
    +/
    @safe pure nothrow @nogc
    size_t mir_least_squares_work_length(size_t m, size_t n)
    {
        import mir.optim.boxcqp: mir_box_qp_work_length;
        return mir_box_qp_work_length(n) + n * 5 + n ^^ 2 + n * m + m * 2;
    }

    /++
    +/
    @safe pure nothrow @nogc
    size_t mir_least_squares_iwork_length(size_t m, size_t n)
    {
        import mir.utility: max;
        import mir.optim.boxcqp: mir_box_qp_iwork_length;
        return max(mir_box_qp_iwork_length(n), n);
    }

    /++
    Status string for extern(C) API.
    Params:
        st = optimization status
    Returns: description for $(LeastSquaresStatus)
    +/
    extern(C)
    pragma(inline, false)
    immutable(char)* mir_least_squares_status_string(LeastSquaresStatus st) @trusted pure nothrow @nogc
    {
        return st.leastSquaresStatusString.ptr;
    }

    /// Thread manager function type for low level `extern(C)` API.
    alias LeastSquaresThreadManagerBetterC =
        extern(C) void function(
            scope void* context,
            uint count,
            scope const LeastSquaresTask taskContext,
            scope LeastSquaresTaskBetterC task)
            @system nothrow @nogc pure;

    /++
    Low level `extern(C)` wrapper instatiation.
    Params:
        settings = Levenberg-Marquardt data structure
        fContext = context for the function
        f = `n -> m` function
        gContext = context for the Jacobian (optional)
        g = `m × n` Jacobian (optional)
        tm = thread manager for finite difference jacobian approximation in case of g is null (optional)
        m = length (dimension) of `y = f(x)`
        n = length (dimension) of X
        x = initial (in) and final (out) X value
        l = lower X bound
        u = upper X bound
        f = `n -> m` function
        fContext = `f` context
        g = `m × n` Jacobian (optional)
        gContext = `g` context
        tm = thread manager for finite difference jacobian approximation in case of g is null (optional)
        tmContext = `tm` context
        work = floating point workspace length of at least $(LREF mir_least_squares_work_length)
        iwork = floating point workspace length of at least $(LREF mir_least_squares_iwork_length)
    +/
    extern(C)
    pragma(inline, false)
    LeastSquaresResult!double mir_optimize_least_squares_d
        (
            scope ref LeastSquaresSettings!double settings,
            size_t m,
            size_t n,
            double* x,
            const(double)* l,
            const(double)* u,
            Slice!(double*) work,
            Slice!(lapackint*) iwork,
            scope void* fContext,
            scope LeastSquaresFunctionBetterC!double f,
            scope void* gContext = null,
            scope LeastSquaresJacobianBetterC!double g = null,
            scope void* tmContext = null,
            scope LeastSquaresThreadManagerBetterC tm = null,
        ) @system nothrow @nogc pure
    {
        return optimizeLeastSquaresImplGenericBetterC!double(settings, m, n, x, l, u, work, iwork, fContext, f, gContext, g, tmContext, tm);
    }

    /// ditto
    extern(C)
    pragma(inline, false)
    LeastSquaresResult!float mir_optimize_least_squares_s
        (
            scope ref LeastSquaresSettings!float settings,
            size_t m,
            size_t n,
            float* x,
            const(float)* l,
            const(float)* u,
            Slice!(float*) work,
            Slice!(lapackint*) iwork,
            scope void* fContext,
            scope LeastSquaresFunctionBetterC!float f,
            scope void* gContext = null,
            scope LeastSquaresJacobianBetterC!float g = null,
            scope void* tmContext = null,
            scope LeastSquaresThreadManagerBetterC tm = null,
        ) @system nothrow @nogc pure
    {
        return optimizeLeastSquaresImplGenericBetterC!float(settings, m, n, x, l, u, work, iwork, fContext, f, gContext, g, tmContext, tm);
    }

    /// ditto
    alias mir_optimize_least_squares(T : double) = mir_optimize_least_squares_d;

    /// ditto
    alias mir_optimize_least_squares(T : float) = mir_optimize_least_squares_s;

    /++
    Initialize LM data structure with default params for iteration.
    Params:
        settings = Levenberg-Marquart data structure
    +/
    void mir_least_squares_init_d(ref LeastSquaresSettings!double settings) pure
    {
        settings = settings.init;
    }

    /// ditto
    void mir_least_squares_init_s(ref LeastSquaresSettings!float settings) pure
    {
        settings = settings.init;
    }

    /// ditto
    alias mir_least_squares_init(T : double) = mir_least_squares_init_d;

    /// ditto
    alias mir_least_squares_init(T : float) = mir_least_squares_init_s;

    /++
    Resets all counters and flags, fills `x`, `y`, `upper`, `lower`, vecors with default values.
    Params:
        settings = Levenberg-Marquart data structure
    +/
    void mir_least_squares_reset_d(ref LeastSquaresSettings!double settings) pure
    {
        settings = settings.init;
    }

    /// ditto
    void mir_least_squares_reset_s(ref LeastSquaresSettings!float settings) pure
    {
        settings = settings.init;
    }

    /// ditto
    alias mir_least_squares_reset(T : double) = mir_least_squares_reset_d;

    /// ditto
    alias mir_least_squares_reset(T : float) = mir_least_squares_reset_s;
}

private:

LeastSquaresResult!T optimizeLeastSquaresImplGenericBetterC(T)
    (
        scope ref LeastSquaresSettings!T settings,
        size_t m,
        size_t n,
        T* x,
        const(T)* l,
        const(T)* u,
        Slice!(T*) work,
        Slice!(lapackint*) iwork,
        scope void* fContext,
        scope LeastSquaresFunctionBetterC!T f,
        scope void* gContext,
        scope LeastSquaresJacobianBetterC!T g,
        scope void* tmContext,
        scope LeastSquaresThreadManagerBetterC tm,
    ) @system nothrow @nogc pure
{
    version(LDC) pragma(inline, true);

    if (g)
        return optimizeLeastSquares!T(
            settings,
            m,
            x[0 .. n].sliced,
            l[0 .. n].sliced,
            u[0 .. n].sliced,
            work,
            iwork,
            (x, y) @trusted => f(fContext, y.length, x.length, x.iterator, y.iterator),
            (x, J) @trusted => g(gContext, J.length, x.length, x.iterator, J.iterator),
            null
        );

    LeastSquaresTaskBetterC taskFunction = (scope const LeastSquaresTask context, uint totalThreads, uint threadId, uint i) @trusted
    {
        context(totalThreads, threadId, i);
    };

    if (tm)
        return optimizeLeastSquares!T(
            settings,
            m,
            x[0 .. n].sliced,
            l[0 .. n].sliced,
            u[0 .. n].sliced,
            work,
            iwork,
            (x, y) @trusted => f(fContext, y.length, x.length, x.iterator, y.iterator),
            null,
            (count, scope LeastSquaresTask task) @trusted => tm(tmContext, count, task, taskFunction)
        );
    return optimizeLeastSquares!T(
        settings,
        m,
        x[0 .. n].sliced,
        l[0 .. n].sliced,
        u[0 .. n].sliced,
        work,
        iwork,
        (x, y) @trusted => f(fContext, y.length, x.length, x.iterator, y.iterator),
        null,
        null
    );
}

// private auto assumePure(T)(T t)
// if (isFunctionPointer!T || isDelegate!T)
// {
//     enum attrs = functionAttributes!T | FunctionAttribute.pure_;
//     return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
// }

// LM algorithm
LeastSquaresResult!T optimizeLeastSquaresImplGeneric(T)
    (
        scope ref LeastSquaresSettings!T settings,
        size_t m,
        Slice!(T*) x,
        Slice!(const(T)*) lower,
        Slice!(const(T)*) upper,
        Slice!(T*) work,
        Slice!(lapackint*) iwork,
        scope LeastSquaresFunction!T f,
        scope LeastSquaresJacobian!T g,
        scope LeastSquaresThreadManager tm,
    ) @trusted nothrow @nogc pure
{ typeof(return) ret; with(ret) with(settings){
    pragma(inline, false);
    import mir.algorithm.iteration: all;
    import mir.blas;
    import mir.lapack;
    import mir.math.common;
    import mir.math.sum: sum;
    import mir.ndslice.allocation: stdcUninitSlice;
    import mir.ndslice.dynamic: transposed;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: canonical, diagonal;
    import mir.optim.boxcqp;
    import mir.utility: max;
    import mir.algorithm.iteration;
    import core.stdc.stdio;

    debug
    {
        work[] = 0;
        iwork[] = 0;
    }

    auto n = cast(uint)x.length;

    auto deltaX = work[0 .. n]; work = work[n .. $];
    auto Jy = work[0 .. n]; work = work[n .. $];
    auto nBuffer = work[0 .. n]; work = work[n .. $];

    auto JJ = work[0 .. n ^^ 2].sliced(n, n); work = work[n ^^ 2 .. $];
    auto J = work[0 .. m * n].sliced(m, n); work = work[m * n .. $];

    auto y = work[0 .. m]; work = work[m .. $];
    auto mBuffer = work[0 .. m]; work = work[m .. $];

    auto qpl = work[0 .. n]; work = work[n .. $];
    auto qpu = work[0 .. n]; work = work[n .. $];

    auto qpwork = work;

    version(LDC) pragma(inline, true);

    if (m == 0 || n == 0 || !x.all!"-a.infinity < a && a < a.infinity")
        { status = LeastSquaresStatus.badGuess; return ret; }
    if (!allLessOrEqual(lower, x) || !allLessOrEqual(x, upper))
        { status = LeastSquaresStatus.badBounds; return ret; }
    if (!(0 <= minStepQuality && minStepQuality < 1))
        { status = LeastSquaresStatus.badMinStepQuality; return ret; }
    if (!(0 <= goodStepQuality && goodStepQuality <= 1))
        { status = LeastSquaresStatus.badGoodStepQuality; return ret; }
    if (!(minStepQuality < goodStepQuality))
        { status = LeastSquaresStatus.badStepQuality; return ret; }
    if (!(1 <= lambdaIncrease && lambdaIncrease <= T.max.sqrt))
        { status = LeastSquaresStatus.badLambdaParams; return ret; }
    if (!(T.min_normal.sqrt <= lambdaDecrease && lambdaDecrease <= 1))
        { status = LeastSquaresStatus.badLambdaParams; return ret; }

    maxAge = maxAge ? maxAge : g ? 3 : 2 * n;

    if (!tm) tm = delegate(uint count, scope LeastSquaresTask task) pure @nogc nothrow @trusted
    {
        foreach(i; 0 .. count)
            task(1, 0, i);
    };

    f(x, y);
    ++fCalls;
    residual = dot(y, y);
    bool fConverged = residual <= maxGoodResidual;


    bool needJacobian = true;
    uint age = maxAge;

    int badPredictions;

    import core.stdc.stdio;

    lambda = 0;
    iterations = 0;
    T deltaX_dot;
    T mu = 1;
    enum T suspiciousMu = 16;
    status = LeastSquaresStatus.maxIterations;
    do
    {
        if (fConverged)
        {
            status = LeastSquaresStatus.fConverged;
            break;
        }
        if (!(lambda <= maxLambda))
        {
            status = LeastSquaresStatus.furtherImprovement;
            break;
        }
        if (mu > suspiciousMu && age)
        {
            needJacobian = true;
            age = maxAge;
            mu = 1;
        }
        if (!allLessOrEqual(x, x))
        {
            // cast(void) assumePure(&printf)("\n@@@@\nX != X\n@@@@\n");
            status = LeastSquaresStatus.numericError;
            break;
        }
        if (needJacobian)
        {
            needJacobian = false;
            if (age < maxAge)
            {
                age++;
                auto d = 1 / deltaX_dot;
                axpy(-1, y, mBuffer); // -deltaY
                gemv(1, J, deltaX, 1, mBuffer); //-(f_new - f_old - J_old*h)
                scal(-d, mBuffer);
                ger(1, mBuffer, deltaX, J); //J_new = J_old + u*h'
            }
            else
            {
                age = 0;
                if (g)
                {
                    g(x, J);
                    gCalls += 1;
                }
                else
                {
                    iwork[0 .. n] = 0;
                    tm(n, (uint totalThreads, uint threadId, uint j)
                        @trusted pure nothrow @nogc
                        {
                            auto idx = totalThreads >= n ? j : threadId;
                            auto p = JJ[idx];
                            if (iwork[idx]++ == 0)
                                copy(x, p);

                            auto save = p[j];
                            auto xmh = save - jacobianEpsilon;
                            auto xph = save + jacobianEpsilon;
                            xmh = fmax(xmh, lower[j]);
                            xph = fmin(xph, upper[j]);
                            auto Jj = J[0 .. $, j];
                            if (auto twh = xph - xmh)
                            {
                                p[j] = xph;
                                f(p, mBuffer);
                                copy(mBuffer, Jj);
                                p[j] = xmh;
                                f(p, mBuffer);
                                p[j] = save;
                                axpy(-1, mBuffer, Jj);
                                scal(1 / twh, Jj);
                            }
                            else
                            {
                                fill(T(0), Jj);
                            }
                        });
                    fCalls += iwork[0 .. n].sum;
                }
            }
            gemv(1, J.transposed, y, 0, Jy);
            if (!(Jy[Jy.iamax].fabs > gradTolerance))
            {
                if (age == 0)
                {
                    status = LeastSquaresStatus.gConverged;
                    break;
                }
                age = maxAge;
                continue;
            }
        }

        syrk(Uplo.Lower, 1, J.transposed, 0, JJ);

        if (!(lambda >= minLambda))
        {
            lambda = 0.001 * JJ.diagonal[JJ.diagonal.iamax];
            if (!(lambda >= minLambda))
                lambda = 1;
        }

        copy(lower, qpl);
        axpy(-1, x, qpl);
        copy(upper, qpu);
        axpy(-1, x, qpu);
        copy(JJ.diagonal, nBuffer);
        JJ.diagonal[] += lambda;
        if (qpSettings.solveBoxQP(JJ.canonical, Jy, qpl, qpu, deltaX, false, qpwork, iwork, false) != BoxQPStatus.solved)
        {
            // cast(void) assumePure(&printf)("\n@@@@\n error in solveBoxQP\n@@@@\n");
            status = LeastSquaresStatus.numericError;
            break;
        }

        if (!allLessOrEqual(deltaX, deltaX))
        {
            // cast(void) assumePure(&printf)("\n@@@@\ndX != dX\n@@@@\n");
            status = LeastSquaresStatus.numericError;
            break;
        }

        copy(nBuffer, JJ.diagonal);

        axpy(1, x, deltaX);
        axpy(-1, x, deltaX);

        auto newDeltaX_dot = dot(deltaX, deltaX);

        if (!(newDeltaX_dot.sqrt < maxStep))
        {
            lambda *= lambdaIncrease * mu;
            mu *= 2;
            continue;
        }

        copy(deltaX, nBuffer);
        axpy(1, x, nBuffer);
        applyBounds(nBuffer, lower, upper);

        ++fCalls;
        f(nBuffer, mBuffer);

        auto trialResidual = dot(mBuffer, mBuffer);

        if (!(trialResidual <= T.infinity))
        {
            // cast(void) assumePure(&printf)("\n@@@@\n trialResidual = %e\n@@@@\n", trialResidual);
            status = LeastSquaresStatus.numericError;
            break;
        }

        auto improvement = residual - trialResidual;
        if (!(improvement > 0))
        {
            lambda *= lambdaIncrease * mu;
            mu *= 2;
            continue;
        }

        needJacobian = true;
        mu = 1;
        iterations++;
        copy(nBuffer, x);
        swap(mBuffer, y);
        residual = trialResidual;
        fConverged = residual <= maxGoodResidual;
        deltaX_dot = newDeltaX_dot;

        symv(Uplo.Lower, 1, JJ, deltaX, 2, Jy); // use Jy as temporal storage
        auto predictedImprovement = -dot(Jy, deltaX);

        if (!(predictedImprovement > 0))
        {
            status = LeastSquaresStatus.furtherImprovement;
            break;
        }

        auto rho = predictedImprovement / improvement;

        if (rho < minStepQuality)
        {
            lambda *= lambdaIncrease * mu;
            mu *= 2;
        }
        else
        if (rho >= goodStepQuality)
        {
            lambda = fmax(lambdaDecrease * lambda * mu, minLambda);
        }

        // fmax(tolX, tolX * x.nrm2));
        if (!(deltaX_dot.sqrt > absTolerance && x.nrm2 > deltaX_dot.sqrt * relTolerance))
        {
            if (age == 0)
            {
                status = LeastSquaresStatus.xConverged;
                break;
            }
            age = maxAge;
            continue;
        }
    }
    while (iterations < maxIterations);
} return ret; }

pragma(inline, false)
void fill(T, SliceKind kind)(T value, Slice!(T*, 1, kind) x)
{
    x[] = value;
}

pragma(inline, false)
bool allLessOrEqual(T)(
    Slice!(const(T)*) a,
    Slice!(const(T)*) b,
    )
{
    import mir.algorithm.iteration: all;
    return all!"a <= b"(a, b);
}

uint normalizeSafety()(uint attrs)
{
    if (attrs & FunctionAttribute.system)
        attrs &= ~FunctionAttribute.safe;
    return attrs;
}

auto trustedAllAttr(T)(scope return T t) @trusted
    if (isFunctionPointer!T || isDelegate!T)
{
    enum attrs = (functionAttributes!T & ~FunctionAttribute.system) 
        | FunctionAttribute.pure_
        | FunctionAttribute.safe
        | FunctionAttribute.nogc
        | FunctionAttribute.nothrow_;
    return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
}

template isNullableFunction(alias f)
{
    enum isNullableFunction = __traits(compiles, { alias F = Unqual!(typeof(f)); auto r = function(ref F e) {e = null;};} );
}
