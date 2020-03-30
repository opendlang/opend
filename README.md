[![Build Status](https://travis-ci.org/libmir/mir-optim.svg?branch=master)](https://travis-ci.org/libmir/mir-optim)
[![Dub downloads](https://img.shields.io/dub/dt/mir-optim.svg)](http://code.dlang.org/packages/mir-optim)
[![Dub downloads](https://img.shields.io/dub/dm/mir-optim.svg)](http://code.dlang.org/packages/mir-optim)
[![License](https://img.shields.io/dub/l/mir-optim.svg)](http://code.dlang.org/packages/mir-optim)
[![Latest version](https://img.shields.io/dub/v/mir-optim.svg)](http://code.dlang.org/packages/mir-optim)

# mir-optim

Dlang BetterC Nonlinear Optimizers.

### Algorithms
 
 - Modified Levenberg-Marquardt Algorithm (Nonlinear Least Squares).
 - Boxed Constrained Quadratic Problem Solver

See also [online documentation](http://mir-optim.libmir.org).

### Features

 - Tiny BetterC library size
 - Based on LAPACK
 - Fast compilaiton speed. There are two  (for `float` and `double`) precompiled algorithm instatiations. Generic API is a thin wrappers around them.
 - Four APIs for any purpose:
    * Extern C API
    * Powerfull high level generic D API
    * Nothrow middle level generic D API
    * Low level nongeneric D API

## Required system libraries

See [wiki: Link with CBLAS & LAPACK](https://github.com/libmir/mir-lapack/wiki/Link-with-CBLAS-&-LAPACK).

### Our sponsors

[<img src="https://raw.githubusercontent.com/libmir/mir-algorithm/master/images/symmetry.png" height="80" />](http://symmetryinvestments.com/) 	&nbsp; 	&nbsp;	&nbsp;	&nbsp;
[<img src="https://raw.githubusercontent.com/libmir/mir-algorithm/master/images/kaleidic.jpeg" height="80" />](https://github.com/kaleidicassociates)
