/++
$(H1 Bound Constrained Convex Quadratic Problem Solver)

Paper: $(HTTP www.cse.uoi.gr/tech_reports/publications/boxcqp.pdf, BOXCQP: AN ALGORITHM FOR BOUND CONSTRAINED CONVEX QUADRATIC PROBLEMS)

Copyright: Copyright © 2020, Symmetry Investments & Kaleidic Associates Advisory Limited
Authors:   Ilya Yaroshenko
+/
module mir.optim.boxcqp;

import mir.ndslice.slice: Slice, Canonical;
import lapack: lapackint;
import mir.math.common: fmin, fmax, sqrt, fabs;

/++
BOXCQP Exit Status
+/
enum BoxQPStatus
{
    ///
    solved,
    ///
    numericError,
    ///
    maxIterations,
}

// ? Not compatible with Intel MKL _posvx
// version = boxcqp_compact;

extern(C) @safe nothrow @nogc
{
    /++
    +/
    @safe pure nothrow @nogc
    size_t mir_box_qp_work_length(size_t n)
    {
        version(boxcqp_compact)
            return n ^^ 2 + n * 8;
        else
            return n ^^ 2 * 2 + n * 8;
    }

    /++
    +/
    @safe pure nothrow @nogc
    size_t mir_box_qp_iwork_length(size_t n)
    {
        return n + (n / lapackint.sizeof + (n % lapackint.sizeof != 0));
    }
}

/++
BOXCQP Algorithm Settings
+/
struct BoxQPSettings(T)
    if (is(T == float) || is(T == double))
{
    /++
    Relative active constraints tolerance.
    +/
    T relTolerance = T.epsilon * 16;
    /++
    Absolute active constraints tolerance.
    +/
    T absTolerance = T.epsilon * 16;
    /++
    Maximal iterations allowed. `0` is used for default value equals to `10 * N + 100`.
    +/
    uint maxIterations = 0;
}

/++
Solves:
    `argmin_x(xPx + qx) : l <= x <= u`
Params:
    P = Positive-definite Matrix, NxN
    q = Linear component, N
    l = Lower bounds in `[-inf, +inf$(RPAREN)`, N
    u = Upper bounds in `$(LPAREN)-inf, +inf]`, N
    x = solutoin, N
    settings = Iteration settings (optional)
+/
@safe pure nothrow @nogc
BoxQPStatus solveBoxQP(T)(
    Slice!(T*, 2, Canonical) P,
    Slice!(const(T)*) q,
    Slice!(const(T)*) l,
    Slice!(const(T)*) u,
    Slice!(T*) x,
    BoxQPSettings!T settings = BoxQPSettings!T.init,
    )
    if (is(T == float) || is(T == double))
{
    import mir.ndslice.allocation: rcslice;
    auto n = q.length;
    auto work = rcslice!T(mir_box_qp_work_length(n));
    auto iwork = rcslice!lapackint(mir_box_qp_iwork_length(n));
    auto workS = work.lightScope;
    auto iworkS = iwork.lightScope;
    return solveBoxQP(settings, P, q, l, u, x, false, workS, iworkS, true);
}

/++
Solves:
    `argmin_x(xPx + qx) : l <= x <= u`
Params:
    settings = Iteration settings
    P = Positive-definite Matrix (in lower triangular part is store), NxN.
        The upper triangular part (and diagonal) of the matrix is used for temporary data and then can be resotored.
        Matrix diagonal is always restored.
    q = Linear component, N
    l = Lower bounds in `[-inf, +inf$(RPAREN)`, N
    u = Upper bounds in `$(LPAREN)-inf, +inf]`, N
    x = solutoin, N
    unconstrainedSolution = 
    work = workspace, $(LREF mir_box_qp_work_length)(N)
    iwork = integer workspace, $(LREF mir_box_qp_iwork_length)(N)
    restoreUpperP = (optional) restore upper triangular part of P
+/
@safe pure nothrow @nogc
BoxQPStatus solveBoxQP(T)(
    ref const BoxQPSettings!T settings,
    Slice!(T*, 2, Canonical) P,
    Slice!(const(T)*) q,
    Slice!(const(T)*) l,
    Slice!(const(T)*) u,
    Slice!(T*) x,
    bool unconstrainedSolution,
    Slice!(T*) work,
    Slice!(lapackint*) iwork,
    bool restoreUpperP = true,
)
    if (is(T == float) || is(T == double))
in {
    auto n = q.length;
    assert(P.length!0 == n);
    assert(P.length!1 == n);
    assert(q.length == n);
    assert(l.length == n);
    assert(u.length == n);
    assert(x.length == n);
    assert(work.length >= mir_box_qp_work_length(n));
    assert(iwork.length >= mir_box_qp_iwork_length(n));
}
do {
    import mir.blas: dot, copy;
    import mir.lapack: posvx;
    import mir.math.sum;
    import mir.ndslice.slice: sliced;
    import mir.ndslice.topology: canonical, diagonal;

    enum Flag : byte
    {
        l = -1,
        s = 0,
        u = 1,
    }

    auto n = q.length;

    if (n == 0)
        return BoxQPStatus.solved;

    auto bwork = iwork[n .. $];
    iwork = iwork[0 .. n];

    if (!unconstrainedSolution)
    {
        auto buffer = work;
        auto Pdiagonal = buffer[0 .. n]; buffer = buffer[n .. $];
        auto scaling = buffer[0 .. n]; buffer = buffer[n .. $];
        auto b = buffer[0 .. n]; buffer = buffer[n .. $];
        auto lapackWorkSpace = buffer[0 .. n * 3]; buffer = buffer[n * 3 .. $];
        auto F = buffer[0 .. n ^^ 2].sliced(n, n); buffer = buffer[n ^^ 2 .. $];

        version(boxcqp_compact)
        {
            foreach(i; 1 .. n)
                copy(P[i, 0 .. i], P[0 .. i, i]);
            copy(P.diagonal, Pdiagonal);
            alias A = P;
        }
        else
        {
            auto A = buffer[0 .. n ^^ 2].sliced(n, n); buffer = buffer[n ^^ 2 .. $];
            foreach(i; 0 .. n)
                copy(P[i, 0 .. i + 1], A[0 .. i + 1, i]);
        }

        b[] = -q;
        char equed;
        T rcond, ferr, berr;
        auto info = posvx('E', 'L',
            A.canonical,
            F.canonical,
            equed,
            scaling,
            b,
            x,
            rcond,
            ferr,
            berr,
            lapackWorkSpace,
            iwork);

        version(boxcqp_compact)
        {
            copy(Pdiagonal, P.diagonal);
        }

        if (info != 0 && info != n + 1)
            return BoxQPStatus.numericError;
    }

    foreach (i; 0 .. n)
        if (!(l[i] <= x[i] && x[i] <= u[i]))
            goto Start;
    return BoxQPStatus.solved;

Start:
    auto flags = (()@trusted=>(cast(Flag*)bwork.ptr).sliced(n))();

    auto maxIterations = cast()settings.maxIterations;
    if (!maxIterations)
        maxIterations = cast(uint)n * 10 + 100; // fix

    auto la  = work[0 .. n]; work = work[n .. $];
    auto mu  = work[0 .. n]; work = work[n .. $];

    la[] = 0;
    mu[] = 0;

    MainLoop: foreach (step; 0 .. maxIterations)
    {
        {
            size_t s;

            with(settings) foreach (i; 0 .. n)
            {
                auto xl = x[i] - l[i];
                auto ux = u[i] - x[i];
                if (xl < 0 || xl < relTolerance + absTolerance * l[i].fabs && la[i] >= 0)
                {
                    flags[i] = Flag.l;
                    x[i] = l[i];
                    mu[i] = 0;
                }
                else
                if (ux < 0 || ux < relTolerance + absTolerance * u[i].fabs && mu[i] >= 0)
                {
                    flags[i] = Flag.u;
                    x[i] = u[i];
                    la[i] = 0;
                }
                else
                {
                    flags[i] = Flag.s;
                    iwork[s++] = cast(lapackint)i;
                    mu[i]  = 0;
                    la[i]  = 0;
                }
            }

            if (s == n)
                break;

            {
                auto SIWorkspace = iwork[0 .. s];
                auto buffer = work;
                auto scaling = buffer[0 .. s]; buffer = buffer[s .. $];
                auto sX = buffer[0 .. s]; buffer = buffer[s .. $];
                auto b = buffer[0 .. s]; buffer = buffer[s .. $];
                auto lapackWorkSpace = buffer[0 .. s * 3]; buffer = buffer[s * 3 .. $];
                auto F = buffer[0 .. s ^^ 2].sliced(s, s); buffer = buffer[s ^^ 2 .. $];

                version(boxcqp_compact)
                    auto A = P[0 .. $ - 1, 1 .. $][$ - s .. $, $ - s .. $];
                else
                    auto A = buffer[0 .. s ^^ 2].sliced(s, s); buffer = buffer[s ^^ 2 .. $];

                foreach (ii, i; SIWorkspace.field)
                {
                    Summator!(T, Summation.kbn) sum = q[i];
                    uint jj;
                    {
                        auto Aii = A[0 .. $, ii];
                        auto Pi = P[i, 0 .. $];
                        foreach (j; 0 .. i)
                            if (flags[j])
                                sum += Pi[j] * (flags[j] < 0 ? l : u)[j];
                            else
                                Aii[jj++] = Pi[j];
                    }
                    {
                        auto Aii = A[ii, 0 .. $];
                        auto Pi = P[0 .. $, i];
                        foreach (j; i .. n)
                            if (flags[j])
                                sum += Pi[j] * (flags[j] < 0 ? l : u)[j];
                            else
                                Aii[jj++] = Pi[j];
                    }
                    b[ii] = -sum.sum;
                }

                {
                    char equed;
                    T rcond, ferr, berr;
                    auto info = posvx('E', 'L',
                        A.canonical,
                        F.canonical,
                        equed,
                        scaling,
                        b,
                        sX,
                        rcond,
                        ferr,
                        berr,
                        lapackWorkSpace,
                        SIWorkspace);
                    
                    if (info != 0 && info != s + 1)
                        return BoxQPStatus.numericError;
                }

                size_t ii;
                foreach (i; 0 .. n) if (flags[i] == Flag.s)
                    x[i] = sX[ii++];
            }
        }

        foreach (i; 0 .. n) if (flags[i])
        {
            auto val = dot!T(P[i, 0 .. i], x[0 .. i]) + dot!T(P[i .. $, i], x[i .. $]) + q[i];
            (flags[i] < 0 ? la : mu)[i] = flags[i] < 0 ? val : -val;
        }

        foreach (i; 0 .. n)
        {
            final switch (flags[i])
            {
                case Flag.l: if (la[i] >= 0) continue; continue MainLoop;
                case Flag.u: if (mu[i] >= 0) continue; continue MainLoop;
                case Flag.s: if (x[i] >= l[i] && x[i] <= u[i]) continue; continue MainLoop;
            }
        }

        applyBounds(x, l, u);

        version(none)
        {
            import std.traits, std.meta;
            static auto assumePure(T)(T t)
            if (isFunctionPointer!T || isDelegate!T)
            {
                enum attrs = functionAttributes!T | FunctionAttribute.pure_;
                return cast(SetFunctionAttributes!(T, functionLinkage!T, attrs)) t;
            }

            import core.stdc.stdio;
            (()@trusted => cast(void) assumePure(&printf)("#### BOXCQP iters = %d\n", step + 1))();
        }

        if (restoreUpperP)
        {
            while(P.length > 1)
            {
                copy(P[1 .. $, 0], P[0, 1 .. $]);
                P.popFront!1;
                P.popFront!0;
            }
        }

        return BoxQPStatus.solved;
    }

    return BoxQPStatus.maxIterations;
}

///
version(mir_optim_test)
unittest
{
    import mir.ndslice;
    import mir.algorithm.iteration;
    import mir.math.common;

    auto P = [
        [ 2.0, -1, 0],
        [-1.0, 2, -1],
        [ 0.0, -1, 2],
    ].fuse.canonical;

    auto q = [3.0, -7, 5].sliced;
    auto l = [-100.0, -2, 1].sliced;
    auto u = [100.0, 2, 1].sliced;
    auto x = slice!double(q.length);

    solveBoxQP(P, q, l, u, x);
    assert(x.equal!approxEqual([-0.5, 2, 1]));
}

package(mir) void applyBounds(T)(Slice!(T*) x, Slice!(const(T)*) l, Slice!(const(T)*) u)
{
    pragma(inline, false);
    import mir.math.common: fmin, fmax;
    foreach (i; 0 .. x.length)
        x[i] = x[i].fmin(u[i]).fmax(l[i]);
}
