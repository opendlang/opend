# dcompute

[![Latest version](https://img.shields.io/dub/v/dcompute.svg)](http://code.dlang.org/packages/dcompute)
[![Latest version](https://img.shields.io/github/tag/libmir/dcompute.svg?maxAge=3600)](http://code.dlang.org/packages/dcompute)
[![License](https://img.shields.io/dub/l/dcompute.svg)](http://code.dlang.org/packages/dcompute)
[![Gitter](https://img.shields.io/gitter/room/libmir/public.svg)](https://gitter.im/libmir/public)

## About

This project is a set of libraries designed to work with [LDC][1] to 
enable native execution of D on GPUs (and other more exotic targets of OpenCL such as FPGAs DSPs, hereafter just 'GPUs') on the OpenCL and CUDA runtimes. As DCompute depends on developments in LDC for the code generation, a relatively recent LDC is required, use [1.8.0](https://github.com/ldc-developers/ldc/releases/tag/v1.8.0) or newer.

There are four main parts: 
* [std](https://github.com/libmir/dcompute/tree/master/source/dcompute/std): A library containing standard functionality for targetting GPUs and abstractions over the intrinsics of OpenCL and CUDA.
* [driver](https://github.com/libmir/dcompute/tree/master/source/dcompute/driver): For handling all the compute API interactions and provide a friendly, easy-to-use, consistent interface. Of course you can always get down to a lower level of interaction if you need to. You can also use this to execute non-D kernels (e.g. OpenCL or CUDA).
* [kernels](https://github.com/libmir/dcompute/tree/master/source/dcompute/kernels): A set of standard kernels and primitives to cover a large number of use cases and serve as documentation on how (and how not) to use this library.
* [tests](https://github.com/libmir/dcompute/tree/master/source/dcompute/tests): A framework for testing kernels. The suite is runnable with `dub test` (see `dub.json` for the configuration used).

## Examples

Kernel:
```
@kernel void saxpy(GlobalPointer!(float) res,
                   float alpha,
                   GlobalPointer!(float) x,
                   GlobalPointer!(float) y, 
                   size_t N)
{
    auto i = GlobalIndex.x;
    if (i >= N) return;
    res[i] = alpha*x[i] + y[i];
}
```

Invoke with (CUDA):
```
q.enqueue!(saxpy)
    ([N,1,1],[1,1,1]) // Grid & block & optional shared memory
    (b_res,alpha,b_x,b_y, N); // kernel arguments
```
equivalent to the CUDA code
```
saxpy<<<1,N,0,q>>>(b_res,alpha,b_x,b_y, N);
```

For more examples and the full code see `source/dcompute/tests`.
## Build Instructions

To build DCompute you will need:
* [ldc][1] as the D dcompiler.
* a SPIRV capable LLVM (available [here](https://github.com/thewilsonator/llvm/tree/compute) to build ldc to to support SPIRV (required for OpenCL)).
* or LDC built with any LLVM 3.9.1 or greater that has the NVPTX backend enabled, to support CUDA.
* [dub](https://github.com/dlang/dub)
and then just run `$dub build` or add `"dcompute": "~>0.1.0"` to your `dub.json` or `dependency "dcompute" version="~>0.1.0"` to your `dub.sdl`.

If you get an error like `Error: unrecognized switch '-mdcompute-targets=cuda-210`, make sure you are using LDC and not DMD: passing `--compiler=/path/to/ldc2` to dub will force it to use `/path/to/ldc2` as the D compiler.

A dmd compatible d compiler,[dmd](https://github.com/dlang/dmd), ldmd or gdmd (available as part of [ldc][1] and [gdc](https://github.com/D-Programming-GDC/GDC) respectively), and cmake for building ldc is also required if you need to build ldc yourself.
 
## Getting Started

Please see the [documentation](https://github.com/libmir/dcompute/blob/master/docs/README.md).

## TODO

Generate OpenCL builtins from [here](https://github.com/KhronosGroup/SPIR-Tools/wiki/SPIR-2.0-built-in-functions)

[1]: https://github.com/ldc-developers/ldc


### Our sponsors

[<img src="https://raw.githubusercontent.com/libmir/mir-algorithm/master/images/symmetry.png" height="80" />](http://symmetryinvestments.com/) 	&nbsp; 	&nbsp;	&nbsp;	&nbsp;
[<img src="https://raw.githubusercontent.com/libmir/mir-algorithm/master/images/kaleidic.jpeg" height="80" />](https://github.com/kaleidicassociates)
