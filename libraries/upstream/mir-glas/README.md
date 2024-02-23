[![Dub downloads](https://img.shields.io/dub/dt/mir-glas.svg)](http://code.dlang.org/packages/mir-glas)
[![License](https://img.shields.io/dub/l/mir-glas.svg)](http://code.dlang.org/packages/mir-glas)
[![Gitter](https://img.shields.io/gitter/room/libmir/public.svg)](https://gitter.im/libmir/public)

[![Latest version](https://img.shields.io/dub/v/mir-glas.svg)](http://code.dlang.org/packages/mir-glas)

[![Circle CI](https://circleci.com/gh/libmir/mir-glas.svg?style=svg)](https://circleci.com/gh/libmir/mir-glas)
[![Build Status](https://travis-ci.org/libmir/mir-glas.svg?branch=master)](https://travis-ci.org/libmir/mir-glas)

[![Benchmarks](http://blog.mir.dlang.io/images/bench_csingle.svg)](http://blog.mir.dlang.io/glas/benchmark/openblas/2016/09/23/glas-gemm-benchmark.html)

# glas
LLVM-accelerated Generic Linear Algebra Subprograms (GLAS)

## Description
GLAS is a C library written in Dlang. No C++/D runtime is required but libc, which is available everywhere.

The library provides

 1. [BLAS](http://netlib.org/blas/) (Basic Linear Algebra Subprograms) API.
 2. GLAS (Generic Linear Algebra Subprograms) API.

CBLAS API can be provided by linking with [Netlib's CBLAS](http://netlib.org/blas/#_cblas) library.

## dub

GLAS can be used with DMD and LDC but 
[LDC (LLVM D Compiler)](https://github.com/ldc-developers/ldc) >= `1.1.0 beta 6` should be installed in common path anyway.

Note performance issue https://github.com/libmir/mir-glas/issues/18.

GLAS can be included automatically in a project using [dub](http://code.dlang.org/) (the D package manager).
DUB will build GLAS and CPUID manually with LDC.

```json
{
   ...
   "dependencies": {
      "mir-glas": "~><current_mir-glas_version>",
      "mir-cpuid": "~><current_mir-cpuid_version>"
   },
   "lflags": ["-L$MIR_GLAS_PACKAGE_DIR", "-L$MIR_CPUID_PACKAGE_DIR"]
}
```

`$MIR_GLAS_PACKAGE_DIR` and `$MIR_CPUID_PACKAGE_DIR` will be replaced automatically by DUB to appropriate directories.

## Usage

`mir-glas` can be used like a common C library. It should be linked with `mir-cpuid`.
A compiler, for example GCC, may require `mir-cpuid` to be passed after `mir-glas`: `-lmir-glas -lmir-cpuid`.

### GLAS API

GLAS API is based on the new `ndslice` from [mir-algorithm](https://github.com/libmir/mir-algorithm).
Other languages can use simple structure definition.
[Examples](examples/) are available for C and for Dlang.

### Headers

C/C++ headers are located in [`include/`](include/).
D headers are located in [`source/`](source/).

There are two files:

 1. `glas/fortran.h` / `glas/fortran.d` - for Netilb's BLAS API
 2. `glas/ndslice.h` / `glas/ndslice.d` - for GLAS API


## Manual Compilation

#### Compiler installation

[LDC (LLVM D Compiler)](https://github.com/ldc-developers/ldc) >= `1.1.0 beta 6` is required to build a project.
You may want to build LDC from source or use [LDC 1.1.0 beta 6](https://github.com/ldc-developers/ldc/releases/tag/v1.1.0-beta2).
Beta 2 generates a lot of warnings that can be ignored. Beta 3 is not supported.

LDC binaries contains two compilers: ldc2 and ldmd2. It is recommended to use ldmd2 with mir-glas.

Recent LDC packages come with the [dub package manager](http://code.dlang.org/docs/commandline).
dub is used to build the project.

#### Mir CPUID
[Mir CPUID](https://github.com/libmir/mir-cpuid) is CPU Identification Routines.

Download `mir-cpuid`
```shell
dub fetch mir-cpuid --cache=local
```

Change the directory
```shell
cd mir-cpuid-<current-mir-cpuid-version>/mir-cpuid
```

Build `mir-cpuid`
```shell
dub build --build=release-nobounds --compiler=ldmd2 --build-mode=singleFile --parallel --force
```
You may need to add `--arch=x86_64`, if you use windows.

Copy `libmir-cpuid.a` to your project or add its directory to the library path.

#### Mir GLAS

Download `mir-glas`
```shell
dub fetch mir-glas --cache=local
```

Change the directory
```shell
cd mir-glas-<current-mir-glas-version>/mir-glas
```

Build `mir-glas`
```shell
dub build --config=static --build=target-native --compiler=ldmd2 --build-mode=singleFile --parallel --force
```
You may need to add `--arch=x86_64` if you use windows.

Copy `libmir-glas.a` to your project or add its directory to the library path.

## Status

We are open for contributing!
The hardest part (GEMM) is already implemented.

 - [x] CI testing with Netlib's BLAS test suite.
 - [x] CI testing with Netlib's CBLAS test suite.
 - [ ] CI testing with Netlib's LAPACK test suite.
 - [ ] CI testing with Netlib's LAPACKE test suite.
 - [ ] Multi-threading
 - [ ] GPU back-end
 - [ ] Shared library support - requires only DUB configuration fixes.
 - [ ] Level 3 - matrix-matrix operations
   - [x] GEMM - matrix matrix multiply
   - [x] SYMM - symmetric matrix matrix multiply
   - [x] HEMM - hermitian matrix matrix multiply
   - [ ] SYRK - symmetric rank-k update to a matrix
   - [ ] HERK - hermitian rank-k update to a matrix
   - [ ] SYR2K - symmetric rank-2k update to a matrix
   - [ ] HER2K - hermitian rank-2k update to a matrix
   - [ ] TRMM - triangular matrix matrix multiply
   - [ ] TRSM - solving triangular matrix with multiple right hand sides
 - [ ] Level 2 - matrix-vector operations
   - [ ] GEMV - matrix vector multiply
   - [ ] GBMV - banded matrix vector multiply
   - [ ] HEMV - hermitian matrix vector multiply
   - [ ] HBMV - hermitian banded matrix vector multiply
   - [ ] HPMV - hermitian packed matrix vector multiply
   - [ ] TRMV - triangular matrix vector multiply
   - [ ] TBMV - triangular banded matrix vector multiply
   - [ ] TPMV - triangular packed matrix vector multiply
   - [ ] TRSV - solving triangular matrix problems
   - [ ] TBSV - solving triangular banded matrix problems
   - [ ] TPSV - solving triangular packed matrix problems
   - [ ] GERU - performs the rank 1 operation `A := alpha*x*y' + A`
   - [ ] GERC - performs the rank 1 operation `A := alpha*x*conjg( y' ) + A`
   - [ ] HER - hermitian rank 1 operation `A := alpha*x*conjg(x') + A`
   - [ ] HPR - hermitian packed rank 1 operation `A := alpha*x*conjg( x' ) + A`
   - [ ] HER2 - hermitian rank 2 operation
   - [ ] HPR2 - hermitian packed rank 2 operation
 - [x] Level 1 - vector-vector and scalar operations. Note: [Mir](https://github.com/libmir/mir) already provides generic implementation.
   - [x] ROTG - setup Givens rotation
   - [x] ROTMG - setup modified Givens rotation
   - [X] ROT - apply Givens rotation
   - [x] ROTM - apply modified Givens rotation
   - [x] SWAP - swap x and y
   - [x] SCAL - `x = a*x`. Note: requires addition optimization for complex numbers.
   - [x] COPY - copy x into y
   - [x] AXPY - `y = a*x + y`. Note: requires addition optimization for complex numbers.
   - [x] DOT - dot product
   - [x] DOTU - dot product. Note: requires addition optimization for complex numbers.
   - [x] DOTC - dot product, conjugating the first vector. Note: requires addition optimization for complex numbers.
   - [x] DSDOT - dot product with extended precision accumulation and result
   - [x] SDSDOT - dot product with extended precision accumulation
   - [x] NRM2 - Euclidean norm
   - [x] ASUM - sum of absolute values
   - [x] IAMAX - index of max abs value

## Porting to a new target

Five steps

1. Implement `cpuid_init` function for `mir-cpuid`. This function should be implemented per platform or OS. Already implemented targets are
   - x86, any OS
   - x86_64, any OS
2. Verify that [source/glas/internal/memory.d](source/glas/internal/memory.d) contains an implementation for the OS. Already implemented targets are
   - Posix (Linux, macOS, and others)
   - Windows
3. Add new configuration for register blocking to [source/glas/internal/config.d](source/glas/internal/config.d). Already implemented configuration available for
   - x87
   - SSE2
   - AVX / AVX2
   - AVX512 (requires LLVM bug fixes).
4. Create a Pool Request.
5. Coordinate with LDC team in case of compiler bugs.

## Questions & Answers

#### Why GLAS is called "Generic ..."?

 1. GLAS has a generic internal implementation, which can be easily ported to any other architecture with minimal efforts (5 minutes).
 2. GLAS API provides more functionality comparing with BLAS.
 3. It is written in Dlang using generic programming.

#### Why it is better then other BLAS Open Source Libraries like OpenBLAS and Eigen?

 1. GLAS is [faster](http://blog.mir.dlang.io/glas/benchmark/openblas/2016/09/23/glas-gemm-benchmark.html).
 2. GLAS API is more user-friendly and does not require additional data copying.
 3. GLAS does not require C++ runtime comparing with Eigen.
 4. GLAS does not require platform specific optimizations like Eigen intrinsics micro kernels and OpenBLAS assembler macro kernels.
 5. GLAS has a simple implementation, which can be easily ported and extended.

#### Why GLAS does not have Lazy Evaluation and Aliasing like Eigen?

GLAS is a lower level library than Eigen. For example, GLAS can be an Eigen BLAS back-end in the future
Lazy Evaluation and Aliasing can be easily implemented in D.
Explicit composition of operations can be done using `mir.ndslice.algorithm` and multidimensional `map` from `mir.ndslice.topology`, which is a generic way to perform any lazy operations you want.
