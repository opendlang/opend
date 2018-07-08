# mir-optim
Dlang Nonlinear Optimisers with external C API.

Algorithms:
    - Modified Levenberg-Marquardt Algorithm (Nonlinear Least Squares).

### Least Squares With Jacobian
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

###  Least Squares Multithread Jacobian approximation.

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
