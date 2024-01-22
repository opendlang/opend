/++
$(H2 BLAS API for GLAS)

Please read $(LINK2 http://www.netlib.org/blas/ , Netlib BLAS) for more details.

Note: Standard (fortran) BLAS API is column major.

Copyright: Copyright © 2016-, Ilya Yaroshenko.
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko
+/
module glas.fortran;

/// Alias for Fortran77 integer.
alias FortranInt = int;

extern(C) nothrow @nogc @system:

/++
 `gemm_`  performs one of the matrix-matrix operations

    `C := alpha*op( A )*op( B ) + beta*C`,

 where  `op( X )` is one of

    `op( X ) = X   or   op( X ) = X**T or op( X ) = X**H`,

 alpha and beta are scalars, and `A`, `B` and `C` are matrices, with `op( A )`
 an `m ⨉ k` matrix,  `op( B )`  a  `k ⨉ n` matrix and  `C` an `m ⨉ n` matrix.

Unified_alias: `gemm_`
+/
int sgemm_(ref const char transa, ref const char transb, ref const FortranInt m, ref const FortranInt  n, ref const FortranInt k, ref const float alpha, const(float)* a, ref const FortranInt lda, const(float)* b, ref const FortranInt ldb, ref const float beta, float* c, ref const FortranInt ldc);
/// ditto
int dgemm_(ref const char transa, ref const char transb, ref const FortranInt m, ref const FortranInt  n, ref const FortranInt k, ref const double alpha, const(double)* a, ref const FortranInt lda, const(double)* b, ref const FortranInt ldb, ref const double beta, double* c, ref const FortranInt ldc);
/// ditto
int cgemm_(ref const char transa, ref const char transb, ref const FortranInt m, ref const FortranInt  n, ref const FortranInt k, ref const cfloat alpha, const(cfloat)* a, ref const FortranInt lda, const(cfloat)* b, ref const FortranInt ldb, ref const cfloat beta, cfloat* c, ref const FortranInt ldc);
/// ditto
int zgemm_(ref const char transa, ref const char transb, ref const FortranInt m, ref const FortranInt  n, ref const FortranInt k, ref const cdouble alpha, const(cdouble)* a, ref const FortranInt lda, const(cdouble)* b, ref const FortranInt ldb, ref const cdouble beta, cdouble* c, ref const FortranInt ldc);

alias gemm_ = sgemm_;
alias gemm_ = dgemm_;
alias gemm_ = cgemm_;
alias gemm_ = zgemm_;

/++
 `symm_`  performs one of the matrix-matrix operations

    `C := alpha*A*B + beta*C`,

 where  `op( X )` is one of

    `C := alpha*B*A + beta*C`,

 alpha and beta are scalars, `A` is a symmetric matrix and `B` and
 `C` are `m ⨉ n` matrices..

Unified_alias: `symm_`
+/
int ssymm_(ref const char side, ref const char uplo, ref const FortranInt m, ref const FortranInt  n, ref const float alpha, const(float)* a, ref const FortranInt lda, const(float)* b, ref const FortranInt ldb, ref const float beta, float* c, ref const FortranInt ldc);
/// ditto
int dsymm_(ref const char side, ref const char uplo, ref const FortranInt m, ref const FortranInt  n, ref const double alpha, const(double)* a, ref const FortranInt lda, const(double)* b, ref const FortranInt ldb, ref const double beta, double* c, ref const FortranInt ldc);
/// ditto
int csymm_(ref const char side, ref const char uplo, ref const FortranInt m, ref const FortranInt  n, ref const cfloat alpha, const(cfloat)* a, ref const FortranInt lda, const(cfloat)* b, ref const FortranInt ldb, ref const cfloat beta, cfloat* c, ref const FortranInt ldc);
/// ditto
int zsymm_(ref const char side, ref const char uplo, ref const FortranInt m, ref const FortranInt  n, ref const cdouble alpha, const(cdouble)* a, ref const FortranInt lda, const(cdouble)* b, ref const FortranInt ldb, ref const cdouble beta, cdouble* c, ref const FortranInt ldc);

alias symm_ = ssymm_;
alias symm_ = dsymm_;
alias symm_ = csymm_;
alias symm_ = zsymm_;

/++
 `hemm_`  performs one of the matrix-matrix operations

    `C := alpha*A*B + beta*C`,

 where  `op( X )` is one of

    `C := alpha*B*A + beta*C`,

 alpha and beta are scalars, `A` is a hermitian matrix and `B` and
 `C` are `m ⨉ n` matrices..

Unified_alias: `hemm_`
+/
int chemm_(ref const char side, ref const char uplo, ref const FortranInt m, ref const FortranInt  n, ref const cfloat alpha, const(cfloat)* a, ref const FortranInt lda, const(cfloat)* b, ref const FortranInt ldb, ref const cfloat beta, cfloat* c, ref const FortranInt ldc);
/// ditto
int zhemm_(ref const char side, ref const char uplo, ref const FortranInt m, ref const FortranInt  n, ref const cdouble alpha, const(cdouble)* a, ref const FortranInt lda, const(cdouble)* b, ref const FortranInt ldb, ref const cdouble beta, cdouble* c, ref const FortranInt ldc);

alias hemm_ = chemm_;
alias hemm_ = zhemm_;

/++
Copies a vector, `x`, to a vector, `y`.

Unified_alias: `copy_`
+/
int scopy_(ref const FortranInt n, const(float)* x, ref const FortranInt incx, float* y, ref const FortranInt incy);
/// ditto 
int dcopy_(ref const FortranInt n, const(double)* x, ref const FortranInt incx, double* y, ref const FortranInt incy);
/// ditto 
int ccopy_(ref const FortranInt n, const(cfloat)* x, ref const FortranInt incx, cfloat* y, ref const FortranInt incy);
/// ditto 
int zcopy_(ref const FortranInt n, const(cdouble)* x, ref const FortranInt incx, cdouble* y, ref const FortranInt incy);

alias copy_ = scopy_;
alias copy_ = dcopy_;
alias copy_ = ccopy_;
alias copy_ = zcopy_;

/++
Interchanges two vectors.

Unified_alias: `swap_`
+/
int sswap_(ref const FortranInt n, float* x, ref const FortranInt incx, float* y, ref const FortranInt incy);
/// ditto 
int dswap_(ref const FortranInt n, double* x, ref const FortranInt incx, double* y, ref const FortranInt incy);
/// ditto 
int cswap_(ref const FortranInt n, cfloat* x, ref const FortranInt incx, cfloat* y, ref const FortranInt incy);
/// ditto 
int zswap_(ref const FortranInt n, cdouble* x, ref const FortranInt incx, cdouble* y, ref const FortranInt incy);

alias swap_ = sswap_;
alias swap_ = dswap_;
alias swap_ = cswap_;
alias swap_ = zswap_;

/++
Copies a vector, `x`, to a vector, `y`.

Unified_alias: `axpy_`
+/
int saxpy_(ref const FortranInt n, ref const float a, const(float)* x, ref const FortranInt incx, float* y, ref const FortranInt incy);
/// ditto 
int daxpy_(ref const FortranInt n, ref const double a, const(double)* x, ref const FortranInt incx, double* y, ref const FortranInt incy);
/// ditto 
int caxpy_(ref const FortranInt n, ref const cfloat a, const(cfloat)* x, ref const FortranInt incx, cfloat* y, ref const FortranInt incy);
/// ditto 
int zaxpy_(ref const FortranInt n, ref const cdouble a, const(cdouble)* x, ref const FortranInt incx, cdouble* y, ref const FortranInt incy);

alias axpy_ = saxpy_;
alias axpy_ = daxpy_;
alias axpy_ = caxpy_;
alias axpy_ = zaxpy_;

/++
Returns the euclidean norm of a vector via the function.

Unified_alias: `nrm2_`
+/
int snrm2_(ref const FortranInt n, const(float)* x, ref const FortranInt incx);
/// ditto 
int dnrm2_(ref const FortranInt n, const(double)* x, ref const FortranInt incx);
/// ditto 
int scnrm2_(ref const FortranInt n, const(cfloat)* x, ref const FortranInt incx);
/// ditto 
int dznrm2_(ref const FortranInt n, const(cdouble)* x, ref const FortranInt incx);

alias nrm2_ = snrm2_;
alias nrm2_ = dnrm2_;
alias nrm2_ = scnrm2_;
alias nrm2_ = dznrm2_;

/++
Takes the sum of the absolute values.

Unified_alias: `asum_`
+/
int sasum_(ref const FortranInt n, const(float)* x, ref const FortranInt incx);
/// ditto 
int dasum_(ref const FortranInt n, const(double)* x, ref const FortranInt incx);
/// ditto 
int scasum_(ref const FortranInt n, const(cfloat)* x, ref const FortranInt incx);
/// ditto 
int dzasum_(ref const FortranInt n, const(cdouble)* x, ref const FortranInt incx);

alias asum_ = sasum_;
alias asum_ = dasum_;
alias asum_ = scasum_;
alias asum_ = dzasum_;

/++
Finds the index of the first element having maximum `|Re(.)| + |Im(.)|`.

Unified_alias: `iamax_`
+/
int isamax_(ref const FortranInt n, const(float)* x, ref const FortranInt incx);
/// ditto 
int idamax_(ref const FortranInt n, const(double)* x, ref const FortranInt incx);
/// ditto 
int icamax_(ref const FortranInt n, const(cfloat)* x, ref const FortranInt incx);
/// ditto 
int izamax_(ref const FortranInt n, const(cdouble)* x, ref const FortranInt incx);

alias iamax_ = isamax_;
alias iamax_ = idamax_;
alias iamax_ = icamax_;
alias iamax_ = izamax_;

/++
`scal_` scales a vector by a constant.

Unified_alias: `scal_`
+/
int sscal_(ref const FortranInt n, ref const float a, float* x, ref const FortranInt incx);
/// ditto 
int dscal_(ref const FortranInt n, ref const double a, double* x, ref const FortranInt incx);
/// ditto 
int csscal_(ref const FortranInt n, ref const float a, cfloat* x, ref const FortranInt incx);
/// ditto 
int cscal_(ref const FortranInt n, ref const cfloat a, cfloat* x, ref const FortranInt incx);
/// ditto 
int csIscal_(ref const FortranInt n, ref const ifloat a, cfloat* x, ref const FortranInt incx);
/// ditto 
int zdscal_(ref const FortranInt n, ref const double a, cdouble* x, ref const FortranInt incx);
/// ditto 
int zscal_(ref const FortranInt n, ref const cdouble a, cdouble* x, ref const FortranInt incx);
/// ditto 
int zdIscal_(ref const FortranInt n, ref const idouble a, cdouble* x, ref const FortranInt incx);

alias scal_ = sscal_;
alias scal_ = dscal_;
alias scal_ = csscal_;
alias scal_ = cscal_;
alias scal_ = csIscal_;
alias scal_ = zdscal_;
alias scal_ = zscal_;
alias scal_ = zdIscal_;

/++
 XERBLA  is an error handler for the LAPACK routines.
 It is called by an LAPACK routine if an input parameter has an
 invalid value.  A message is printed and execution stops.

 Installers may consider modifying the STOP statement in order to
 call system-specific exception-handling facilities.
+/
int xerbla_(in char* srname, ref FortranInt info);
