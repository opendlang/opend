[![Gitter](https://img.shields.io/gitter/room/libmir/public.svg)](https://gitter.im/libmir/public)
[![Build Status](https://travis-ci.org/libmir/mir-optim.svg?branch=master)](https://travis-ci.org/libmir/mir-optim)
[![Dub downloads](https://img.shields.io/dub/dt/mir-optim.svg)](http://code.dlang.org/packages/mir-optim)
[![Dub downloads](https://img.shields.io/dub/dm/mir-optim.svg)](http://code.dlang.org/packages/mir-optim)
[![License](https://img.shields.io/dub/l/mir-optim.svg)](http://code.dlang.org/packages/mir-optim)
[![Latest version](https://img.shields.io/dub/v/mir-optim.svg)](http://code.dlang.org/packages/mir-optim)

# mir-optim

Dlang Nonlinear Optimisers with external C API.

# Konwn bugs

 - Random wrong results when `taskPool` is passed.

### Algorithms
 
 - Modified Levenberg-Marquardt Algorithm (Nonlinear Least Squares).

See also [online documentation](https://mir-optim.dpldocs.info/mir.html).

### Features

 - Idiomatic BetterC library. See `examples/least_squares.cpp` for compilation details.
 - C/C++ header
 - Multithread C++ examples
 - Tiny BetterC library size, <38KB
 - Based on LAPACK
 - Fast compilaiton speed. There are two  (for `float` and `double`) precompiled algorithm instatiations. Generic API is a thin wrappers around them.
 - Four APIs for any purpose:
    * Extern C/C++ API
    * Powerfull high level generic D API
    * Nothrow middle level generic D API
    * Low level nongeneric D API

## Required system libraries

See [wiki: Link with CBLAS & LAPACK](https://github.com/libmir/mir-lapack/wiki/Link-with-CBLAS-&-LAPACK).

# Examples

### Least Squares. Analytical Jacobian.

```d
unittest
{
    import mir.optim.least_squares;
    import mir.ndslice.allocation: slice;
    import mir.ndslice.slice: sliced;
    import mir.blas: nrm2;

    auto lm = LeastSquaresLM!double(2, 2);
    lm.x[] = [100, 100]; // initial X
    // argmin_x f_0(x)^^2 + f_1(x)^^2
    lm.optimize!(
        (x, y) // f(x)
        {
            y[0] = x[0];
            y[1] = 2 - x[1];
        },
        (x, J) // J(x)
        {
            J[0, 0] = 1;
            J[0, 1] = 0;
            J[1, 0] = 0;
            J[1, 1] = -1;
        },
    );

    assert(nrm2((lm.x - [0, 2].sliced).slice) < 1e-8);
}
```

###  Least Squares. Multithreaded Jacobian approximation.

Jacobian finite difference approximation computed in multiple threads.

```d
unittest
{
    import mir.optim.least_squares;
    import mir.ndslice.allocation: slice;
    import mir.ndslice.slice: sliced;
    import mir.blas: nrm2;
    import std.parallelism: taskPool;

    auto lm = LeastSquaresLM!double(2, 2);
    lm.x[] = [-1.2, 1];
    lm.optimize!(
        (x, y) // Rosenbrock function
        {
            y[0] = 10 * (x[1] - x[0]^^2);
            y[1] = 1 - x[0];
        },
    )(taskPool);

    assert(nrm2((lm.x - [1, 1].sliced).slice) < 1e-8);
}
```

### Our sponsors

[<img src="https://raw.githubusercontent.com/libmir/mir-algorithm/master/images/symmetry.png" height="80" />](http://symmetryinvestments.com/) 	&nbsp; 	&nbsp;	&nbsp;	&nbsp;
[<img src="https://raw.githubusercontent.com/libmir/mir-algorithm/master/images/kaleidic.jpeg" height="80" />](https://github.com/kaleidicassociates)
