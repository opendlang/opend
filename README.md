# mir-optim

Dlang Nonlinear Optimisers with external C API.

### Algorithms
 
 - Modified Levenberg-Marquardt Algorithm (Nonlinear Least Squares).

### Features

 - Idiomatic BetterC library. See `example.cpp` for compilation details.
 - C/C++ header
 - Multithread C++ example
 - Tiny library size, <38KB
 - Based on LAPACK
 - Fast compilaiton speed. There are two  (for `float` and `double`) precompiled algorithm instatiations. All generic API is thin wrappers around them.
 - Four APIs for any purpose:
    1. Extern C/C++ API
    2. Powerfull high level generic D API
    3. Nothrow middle level generic D API
    4. Low level nongeneric D API

### Least Squares. Analitical Jacobian.

```d
unittest
{
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

###  Least Squares. Multithread Jacobian approximation.

Jacobian finite difference approximation computed using in multiple threads.

```d
unittest
{
    import mir.ndslice.allocation: slice;
    import mir.ndslice.slice: sliced;
    import mir.blas: nrm2;
    import std.parallelism: taskPool;

    auto lm = LeastSquaresLM!double(2, 2);
    lm.x[] = [100, 100];
    lm.optimize!(
        (x, y)
        {
            y[0] = x[0];
            y[1] = 2 - x[1];
        },
    )(taskPool);

    assert(nrm2((lm.x - [0, 2].sliced).slice) < 1e-8);
}
```

### TODO

 - More algorithms.
 - Appveyor CI.
 - Online documentation.

### Our sponsors

[<img src="https://raw.githubusercontent.com/libmir/mir-algorithm/master/images/symmetry.png" height="80" />](http://symmetryinvestments.com/) 	&nbsp; 	&nbsp;	&nbsp;	&nbsp;
[<img src="https://raw.githubusercontent.com/libmir/mir-algorithm/master/images/kaleidic.jpeg" height="80" />](https://github.com/kaleidicassociates)
