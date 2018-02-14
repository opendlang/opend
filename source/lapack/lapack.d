/++
LAPACK bindings for D.

Authors:  William V. Baxter III, Lars Tandle Kyllingstad, Ilya Yaroshenko
Copyright:  Copyright (c) 2009, Lars T. Kyllingstad; Copyright © 2017, Symmetry Investments & Kaleidic Associates
+/
module lapack.lapack;

version(LAPACK_STD_COMPLEX)
{
    import std.complex: Complex;
    alias _cfloat = Complex!float;
    alias _cdouble = Complex!double;
}
else
{
    alias _cfloat = cfloat;
    alias _cdouble = cdouble;
}

version(LAPACKNATIVEINT)
{
    ///
    alias lapackint = ptrdiff_t;
}
else
{
    ///
    alias lapackint = int;
}

/*
    Copyright (C) 2006--2008 William V. Baxter III, OLM Digital, Inc.

    This software is provided 'as-is', without any express or implied
    warranty.  In no event will the authors be held liable for any
    damages arising from the use of this software.

    Permission is granted to anyone to use this software for any
    purpose, including commercial applications, and to alter it and
    redistribute it freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must
         not claim that you wrote the original software. If you use this
         software in a product, an acknowledgment in the product
         documentation would be appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must
         not be misrepresented as being the original software.
    3. This notice may not be removed or altered from any source distribution.

    William Baxter wbaxter@gmail.com
*/


// Prototypes for the raw Fortran interface to BLAS
nothrow @nogc extern(C):

alias FCB_CGEES_SELECT  = lapackint function(_cfloat *);
alias FCB_CGEESX_SELECT = lapackint function(_cfloat *);
alias FCB_CGGES_SELCTG  = lapackint function(_cfloat *, _cfloat *);
alias FCB_CGGESX_SELCTG = lapackint function(_cfloat *, _cfloat *);
alias FCB_DGEES_SELECT  = lapackint function(double *, double *);
alias FCB_DGEESX_SELECT = lapackint function(double *, double *);
alias FCB_DGGES_DELCTG  = lapackint function(double *, double *, double *);
alias FCB_DGGESX_DELCTG = lapackint function(double *, double *, double *);
alias FCB_SGEES_SELECT  = lapackint function(float *, float *);
alias FCB_SGEESX_SELECT = lapackint function(float *, float *);
alias FCB_SGGES_SELCTG  = lapackint function(float *, float *, float *);
alias FCB_SGGESX_SELCTG = lapackint function(float *, float *, float *);
alias FCB_ZGEES_SELECT  = lapackint function(_cdouble *);
alias FCB_ZGEESX_SELECT = lapackint function(_cdouble *);
alias FCB_ZGGES_DELCTG  = lapackint function(_cdouble *, _cdouble *);
alias FCB_ZGGESX_DELCTG = lapackint function(_cdouble *, _cdouble *);

version (FORTRAN_FLOAT_FUNCTIONS_RETURN_DOUBLE)
{
    alias lapack_float_ret_t = double;
}
else
{
    alias lapack_float_ret_t = float;
}

/* LAPACK routines */

//--------------------------------------------------------
// ---- SIMPLE and DIVIDE AND CONQUER DRIVER routines ----
//---------------------------------------------------------

/// Solves a general system of linear equations AX=B.
void sgesv_(ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, lapackint *ipiv, float *b, ref lapackint ldb, ref lapackint info);
void dgesv_(ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, lapackint *ipiv, double *b, ref lapackint ldb, ref lapackint info);
void cgesv_(ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zgesv_(ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Solves a general banded system of linear equations AX=B.
void sgbsv_(ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, float *ab, ref lapackint ldab, lapackint *ipiv, float *b, ref lapackint ldb, ref lapackint info);
void dgbsv_(ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, double *ab, ref lapackint ldab, lapackint *ipiv, double *b, ref lapackint ldb, ref lapackint info);
void cgbsv_(ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, _cfloat *ab, ref lapackint ldab, lapackint *ipiv, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zgbsv_(ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, _cdouble *ab, ref lapackint ldab, lapackint *ipiv, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Solves a general tridiagonal system of linear equations AX=B.
void sgtsv_(ref lapackint n, ref lapackint nrhs, float *dl, float *d, float *du, float *b, ref lapackint ldb, ref lapackint info);
void dgtsv_(ref lapackint n, ref lapackint nrhs, double *dl, double *d, double *du, double *b, ref lapackint ldb, ref lapackint info);
void cgtsv_(ref lapackint n, ref lapackint nrhs, _cfloat *dl, _cfloat *d, _cfloat *du, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zgtsv_(ref lapackint n, ref lapackint nrhs, _cdouble *dl, _cdouble *d, _cdouble *du, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Solves a symmetric positive definite system of linear
/// equations AX=B.
void sposv_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *b, ref lapackint ldb, ref lapackint info);
void dposv_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *b, ref lapackint ldb, ref lapackint info);
void cposv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zposv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Solves a symmetric positive definite system of linear
/// equations AX=B, where A is held in packed storage.
void sppsv_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *ap, float *b, ref lapackint ldb, ref lapackint info);
void dppsv_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *ap, double *b, ref lapackint ldb, ref lapackint info);
void cppsv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zppsv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Solves a symmetric positive definite banded system
/// of linear equations AX=B.
void spbsv_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, float *ab, ref lapackint ldab, float *b, ref lapackint ldb, ref lapackint info);
void dpbsv_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, double *ab, ref lapackint ldab, double *b, ref lapackint ldb, ref lapackint info);
void cpbsv_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cfloat *ab, ref lapackint ldab, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zpbsv_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cdouble *ab, ref lapackint ldab, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Solves a symmetric positive definite tridiagonal system
/// of linear equations AX=B.
void sptsv_(ref lapackint n, ref lapackint nrhs, float *d, float *e, float *b, ref lapackint ldb, ref lapackint info);
void dptsv_(ref lapackint n, ref lapackint nrhs, double *d, double *e, double *b, ref lapackint ldb, ref lapackint info);
void cptsv_(ref lapackint n, ref lapackint nrhs, float *d, _cfloat *e, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zptsv_(ref lapackint n, ref lapackint nrhs, double *d, _cdouble *e, _cdouble *b, ref lapackint ldb, ref lapackint info);


/// Solves a real symmetric indefinite system of linear equations AX=B.
void ssysv_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, lapackint *ipiv, float *b, ref lapackint ldb, float *work, ref lapackint lwork, ref lapackint info);
void dsysv_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, lapackint *ipiv, double *b, ref lapackint ldb, double *work, ref lapackint lwork, ref lapackint info);
void csysv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zsysv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Solves a real symmetric indefinite system of linear equations AX=B. Rook method (LDL decomposition)
void ssysv_rk_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *e, lapackint *ipiv, float *b, ref lapackint ldb, float *work, ref lapackint lwork, ref lapackint info);
void dsysv_rk_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *e, lapackint *ipiv, double *b, ref lapackint ldb, double *work, ref lapackint lwork, ref lapackint info);
void csysv_rk_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *e, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zsysv_rk_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *e, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Solves a real symmetric indefinite system of linear equations AX=B. Rook method (LDL decomposition)
void ssysv_rook_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, lapackint *ipiv, float *b, ref lapackint ldb, float *work, ref lapackint lwork, ref lapackint info);
void dsysv_rook_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, lapackint *ipiv, double *b, ref lapackint ldb, double *work, ref lapackint lwork, ref lapackint info);
void csysv_rook_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zsysv_rook_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Solves a complex Hermitian indefinite system of linear equations AX=B.
void chesv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zhesv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Solves a real symmetric indefinite system of linear equations AX=B,
/// where A is held in packed storage.
void sspsv_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *ap, lapackint *ipiv, float *b, ref lapackint ldb, ref lapackint info);
void dspsv_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *ap, lapackint *ipiv, double *b, ref lapackint ldb, ref lapackint info);
void cspsv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, lapackint *ipiv, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zspsv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, lapackint *ipiv, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Solves a complex Hermitian indefinite system of linear equations AX=B,
/// where A is held in packed storage.
void chpsv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, lapackint *ipiv, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zhpsv_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, lapackint *ipiv, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Computes the least squares solution to an over-determined system
/// of linear equations, A X=B or A**H X=B,  or the minimum norm
/// solution of an under-determined system, where A is a general
/// rectangular matrix of full rank,  using a QR or LQ factorization
/// of A.
void sgels_(ref char trans, ref lapackint m, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *work, ref lapackint lwork, ref lapackint info);
void dgels_(ref char trans, ref lapackint m, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *work, ref lapackint lwork, ref lapackint info);
void cgels_(ref char trans, ref lapackint m, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zgels_(ref char trans, ref lapackint m, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Computes the least squares solution to an over-determined system
/// of linear equations, A X=B or A**H X=B,  or the minimum norm
/// solution of an under-determined system, using a divide and conquer
/// method, where A is a general rectangular matrix of full rank,
/// using a QR or LQ factorization of A.
void sgelsd_(ref lapackint m, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *s, ref float rcond, ref lapackint rank, float *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void dgelsd_(ref lapackint m, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *s, ref double rcond, ref lapackint rank, double *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void cgelsd_(ref lapackint m, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, float *s, ref float rcond, ref lapackint rank, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *iwork, ref lapackint info);
void zgelsd_(ref lapackint m, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, double *s, ref double rcond, ref lapackint rank, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *iwork, ref lapackint info);

/// Solves the LSE (Constrained Linear Least Squares Problem) using
/// the GRQ (Generalized RQ) factorization
void sgglse_(ref lapackint m, ref lapackint n, ref lapackint p, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *c, float *d, float *x, float *work, ref lapackint lwork, ref lapackint info);
void dgglse_(ref lapackint m, ref lapackint n, ref lapackint p, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *c, double *d, double *x, double *work, ref lapackint lwork, ref lapackint info);
void cgglse_(ref lapackint m, ref lapackint n, ref lapackint p, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *c, _cfloat *d, _cfloat *x, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zgglse_(ref lapackint m, ref lapackint n, ref lapackint p, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *c, _cdouble *d, _cdouble *x, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Solves the GLM (Generalized Linear Regression Model) using
/// the GQR (Generalized QR) factorization
void sggglm_(ref lapackint n, ref lapackint m, ref lapackint p, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *d, float *x, float *y, float *work, ref lapackint lwork, ref lapackint info);
void dggglm_(ref lapackint n, ref lapackint m, ref lapackint p, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *d, double *x, double *y, double *work, ref lapackint lwork, ref lapackint info);
void cggglm_(ref lapackint n, ref lapackint m, ref lapackint p, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *d, _cfloat *x, _cfloat *y, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zggglm_(ref lapackint n, ref lapackint m, ref lapackint p, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *d, _cdouble *x, _cdouble *y, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix.
void ssyev_(ref char jobz, ref char uplo, ref lapackint n, float *a, ref lapackint lda, float *w, float *work, ref lapackint lwork, ref lapackint info);
void dsyev_(ref char jobz, ref char uplo, ref lapackint n, double *a, ref lapackint lda, double *w, double *work, ref lapackint lwork, ref lapackint info);

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix.
void cheev_(ref char jobz, ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, float *w, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zheev_(ref char jobz, ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, double *w, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);


/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix.  If eigenvectors are desired, it uses a divide
/// and conquer algorithm.
void ssyevd_(ref char jobz, ref char uplo, ref lapackint n, float *a, ref lapackint lda, float *w, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dsyevd_(ref char jobz, ref char uplo, ref lapackint n, double *a, ref lapackint lda, double *w, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix.  If eigenvectors are desired, it uses a divide
/// and conquer algorithm.
void cheevd_(ref char jobz, ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, float *w, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void zheevd_(ref char jobz, ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, double *w, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix in packed storage.
void sspev_(ref char jobz, ref char uplo, ref lapackint n, float *ap, float *w, float *z, ref lapackint ldz, float *work, ref lapackint info);
void dspev_(ref char jobz, ref char uplo, ref lapackint n, double *ap, double *w, double *z, ref lapackint ldz, double *work, ref lapackint info);

/// Computes selected eigenvalues, and optionally, eigenvectors of a complex
/// Hermitian matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix in packed storage.
void chpev_(ref char jobz, ref char uplo, ref lapackint n, _cfloat *ap, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, float *rwork, ref lapackint info);
void zhpev_(ref char jobz, ref char uplo, ref lapackint n, _cdouble *ap, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, double *rwork, ref lapackint info);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix in packed storage.  If eigenvectors are desired,
/// it uses a divide and conquer algorithm.
void sspevd_(ref char jobz, ref char uplo, ref lapackint n, float *ap, float *w, float *z, ref lapackint ldz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dspevd_(ref char jobz, ref char uplo, ref lapackint n, double *ap, double *w, double *z, ref lapackint ldz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian matrix in packed storage.  If eigenvectors are desired, it
/// uses a divide and conquer algorithm.
void chpevd_(ref char jobz, ref char uplo, ref lapackint n, _cfloat *ap, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void zhpevd_(ref char jobz, ref char uplo, ref lapackint n, _cdouble *ap, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric band matrix.
void ssbev_(ref char jobz, ref char uplo, ref lapackint n, lapackint *kd, float *ab, ref lapackint ldab, float *w, float *z, ref lapackint ldz, float *work, ref lapackint info);
void dsbev_(ref char jobz, ref char uplo, ref lapackint n, lapackint *kd, double *ab, ref lapackint ldab, double *w, double *z, ref lapackint ldz, double *work, ref lapackint info);

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian band matrix.
void chbev_(ref char jobz, ref char uplo, ref lapackint n, lapackint *kd, _cfloat *ab, ref lapackint ldab, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, float *rwork, ref lapackint info);
void zhbev_(ref char jobz, ref char uplo, ref lapackint n, lapackint *kd, _cdouble *ab, ref lapackint ldab, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, double *rwork, ref lapackint info);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric band matrix.  If eigenvectors are desired, it uses a
/// divide and conquer algorithm.
void ssbevd_(ref char jobz, ref char uplo, ref lapackint n, lapackint *kd, float *ab, ref lapackint ldab, float *w, float *z, ref lapackint ldz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dsbevd_(ref char jobz, ref char uplo, ref lapackint n, lapackint *kd, double *ab, ref lapackint ldab, double *w, double *z, ref lapackint ldz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes all eigenvalues and, optionally, eigenvectors of a complex
/// Hermitian band matrix.  If eigenvectors are desired, it uses a divide
/// and conquer algorithm.
void chbevd_(ref char jobz, ref char uplo, ref lapackint n, lapackint *kd, _cfloat *ab, ref lapackint ldab, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void zhbevd_(ref char jobz, ref char uplo, ref lapackint n, lapackint *kd, _cdouble *ab, ref lapackint ldab, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric tridiagonal matrix.
void sstev_(ref char jobz, ref lapackint n, float *d, float *e, float *z, ref lapackint ldz, float *work, ref lapackint info);
void dstev_(ref char jobz, ref lapackint n, double *d, double *e, double *z, ref lapackint ldz, double *work, ref lapackint info);

/// Computes all eigenvalues, and optionally, eigenvectors of a real
/// symmetric tridiagonal matrix.  If eigenvectors are desired, it uses
/// a divide and conquer algorithm.
void sstevd_(ref char jobz, ref lapackint n, float *d, float *e, float *z, ref lapackint ldz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dstevd_(ref char jobz, ref lapackint n, double *d, double *e, double *z, ref lapackint ldz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes the eigenvalues and Schur factorization of a general
/// matrix, and orders the factorization so that selected eigenvalues
/// are at the top left of the Schur form.
void sgees_(ref char jobvs, ref char sort, FCB_SGEES_SELECT select, ref lapackint n, float *a, ref lapackint lda, lapackint *sdim, float *wr, float *wi, float *vs, ref lapackint ldvs, float *work, ref lapackint lwork, lapackint *bwork, ref lapackint info);
void dgees_(ref char jobvs, ref char sort, FCB_DGEES_SELECT select, ref lapackint n, double *a, ref lapackint lda, lapackint *sdim, double *wr, double *wi, double *vs, ref lapackint ldvs, double *work, ref lapackint lwork, lapackint *bwork, ref lapackint info);
void cgees_(ref char jobvs, ref char sort, FCB_CGEES_SELECT select, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *sdim, _cfloat *w, _cfloat *vs, ref lapackint ldvs, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *bwork, ref lapackint info);
void zgees_(ref char jobvs, ref char sort, FCB_ZGEES_SELECT select, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *sdim, _cdouble *w, _cdouble *vs, ref lapackint ldvs, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *bwork, ref lapackint info);

/// Computes the eigenvalues and left and right eigenvectors of
/// a general matrix.
void sgeev_(ref char jobvl, ref char jobvr, ref lapackint n, float *a, ref lapackint lda, float *wr, float *wi, float *vl, ref lapackint ldvl, float *vr, ref lapackint ldvr, float *work, ref lapackint lwork, ref lapackint info);
void dgeev_(ref char jobvl, ref char jobvr, ref lapackint n, double *a, ref lapackint lda, double *wr, double *wi, double *vl, ref lapackint ldvl, double *vr, ref lapackint ldvr, double *work, ref lapackint lwork, ref lapackint info);
void cgeev_(ref char jobvl, ref char jobvr, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *w, _cfloat *vl, ref lapackint ldvl, _cfloat *vr, ref lapackint ldvr, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zgeev_(ref char jobvl, ref char jobvr, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *w, _cdouble *vl, ref lapackint ldvl, _cdouble *vr, ref lapackint ldvr, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Computes the singular value decomposition (SVD) of a general
/// rectangular matrix.
void sgesvd_(ref char jobu, ref char jobvt, ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *s, float *u, ref lapackint ldu, float *vt, ref lapackint ldvt, float *work, ref lapackint lwork, ref lapackint info);
void dgesvd_(ref char jobu, ref char jobvt, ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *s, double *u, ref lapackint ldu, double *vt, ref lapackint ldvt, double *work, ref lapackint lwork, ref lapackint info);
void cgesvd_(ref char jobu, ref char jobvt, ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, float *s, _cfloat *u, ref lapackint ldu, _cfloat *vt, ref lapackint ldvt, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zgesvd_(ref char jobu, ref char jobvt, ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, double *s, _cdouble *u, ref lapackint ldu, _cdouble *vt, ref lapackint ldvt, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Computes the singular value decomposition (SVD) of a general
/// rectangular matrix using divide-and-conquer.
void sgesdd_(ref char jobz, ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *s, float *u, ref lapackint ldu, float *vt, ref lapackint ldvt, float *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void dgesdd_(ref char jobz, ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *s, double *u, ref lapackint ldu, double *vt, ref lapackint ldvt, double *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void cgesdd_(ref char jobz, ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, float *s, _cfloat *u, ref lapackint ldu, _cfloat *vt, ref lapackint ldvt, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *iwork, ref lapackint info);
void zgesdd_(ref char jobz, ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, double *s, _cdouble *u, ref lapackint ldu, _cdouble *vt, ref lapackint ldvt, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *iwork, ref lapackint info);

/// Computes all eigenvalues and the eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void ssygv_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *w, float *work, ref lapackint lwork, ref lapackint info);
void dsygv_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *w, double *work, ref lapackint lwork, ref lapackint info);

/// Computes all eigenvalues and the eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void chegv_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, float *w, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zhegv_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, double *w, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Computes all eigenvalues and the eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void ssygvd_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *w, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dsygvd_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *w, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
/// Computes all eigenvalues and the eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void chegvd_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, float *w, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void zhegvd_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, double *w, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes all eigenvalues and eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void sspgv_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, float *ap, float *bp, float *w, float *z, ref lapackint ldz, float *work, ref lapackint info);
void dspgv_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, double *ap, double *bp, double *w, double *z, ref lapackint ldz, double *work, ref lapackint info);

/// Computes all eigenvalues and eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void chpgv_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, _cfloat *ap, _cfloat *bp, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, float *rwork, ref lapackint info);
void zhpgv_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, _cdouble *ap, _cdouble *bp, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, double *rwork, ref lapackint info);

/// Computes all eigenvalues and eigenvectors of  a generalized
/// symmetric-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void sspgvd_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, float *ap, float *bp, float *w, float *z, ref lapackint ldz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dspgvd_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, double *ap, double *bp, double *w, double *z, ref lapackint ldz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes all eigenvalues and eigenvectors of  a generalized
/// Hermitian-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void chpgvd_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, _cfloat *ap, _cfloat *bp, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void zhpgvd_(lapackint *itype, ref char jobz, ref char uplo, ref lapackint n, _cdouble *ap, _cdouble *bp, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a real generalized symmetric-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be symmetric
/// and banded, and B is also positive definite.
void ssbgv_(ref char jobz, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, float *ab, ref lapackint ldab, float *bb, ref lapackint ldbb, float *w, float *z, ref lapackint ldz, float *work, ref lapackint info);
void dsbgv_(ref char jobz, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, double *ab, ref lapackint ldab, double *bb, ref lapackint ldbb, double *w, double *z, ref lapackint ldz, double *work, ref lapackint info);

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a complex generalized Hermitian-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be Hermitian
/// and banded, and B is also positive definite.
void chbgv_(ref char jobz, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, _cfloat *ab, ref lapackint ldab, _cfloat *bb, ref lapackint ldbb, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, float *rwork, ref lapackint info);
void zhbgv_(ref char jobz, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, _cdouble *ab, ref lapackint ldab, _cdouble *bb, ref lapackint ldbb, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, double *rwork, ref lapackint info);

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a real generalized symmetric-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be symmetric
/// and banded, and B is also positive definite.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void ssbgvd_(ref char jobz, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, float *ab, ref lapackint ldab, float *bb, ref lapackint ldbb, float *w, float *z, ref lapackint ldz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dsbgvd_(ref char jobz, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, double *ab, ref lapackint ldab, double *bb, ref lapackint ldbb, double *w, double *z, ref lapackint ldz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes all the eigenvalues, and optionally, the eigenvectors
/// of a complex generalized Hermitian-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be Hermitian
/// and banded, and B is also positive definite.
/// If eigenvectors are desired, it uses a divide and conquer algorithm.
void chbgvd_(ref char jobz, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, _cfloat *ab, ref lapackint ldab, _cfloat *bb, ref lapackint ldbb, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void zhbgvd_(ref char jobz, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, _cdouble *ab, ref lapackint ldab, _cdouble *bb, ref lapackint ldbb, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes the generalized eigenvalues, Schur form, and left and/or
/// right Schur vectors for a pair of nonsymmetric matrices
void sgegs_(ref char jobvsl, ref char jobvsr, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *alphar, float *alphai, float *betav, float *vsl, ref lapackint ldvsl, float *vsr, ref lapackint ldvsr, float *work, ref lapackint lwork, ref lapackint info);
void dgegs_(ref char jobvsl, ref char jobvsr, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *alphar, double *alphai, double *betav, double *vsl, ref lapackint ldvsl, double *vsr, ref lapackint ldvsr, double *work, ref lapackint lwork, ref lapackint info);
void cgegs_(ref char jobvsl, ref char jobvsr, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *alphav, _cfloat *betav, _cfloat *vsl, ref lapackint ldvsl, _cfloat *vsr, ref lapackint ldvsr, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zgegs_(ref char jobvsl, ref char jobvsr, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *alphav, _cdouble *betav, _cdouble *vsl, ref lapackint ldvsl, _cdouble *vsr, ref lapackint ldvsr, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Computes the generalized eigenvalues, Schur form, and left and/or
/// right Schur vectors for a pair of nonsymmetric matrices
void sgges_(ref char jobvsl, ref char jobvsr, ref char sort, FCB_SGGES_SELCTG selctg, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, lapackint *sdim, float *alphar, float *alphai, float *betav, float *vsl, ref lapackint ldvsl, float *vsr, ref lapackint ldvsr, float *work, ref lapackint lwork, lapackint *bwork, ref lapackint info);
void dgges_(ref char jobvsl, ref char jobvsr, ref char sort, FCB_DGGES_DELCTG delctg, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, lapackint *sdim, double *alphar, double *alphai, double *betav, double *vsl, ref lapackint ldvsl, double *vsr, ref lapackint ldvsr, double *work, ref lapackint lwork, lapackint *bwork, ref lapackint info);
void cgges_(ref char jobvsl, ref char jobvsr, ref char sort, FCB_CGGES_SELCTG selctg, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, lapackint *sdim, _cfloat *alphav, _cfloat *betav, _cfloat *vsl, ref lapackint ldvsl, _cfloat *vsr, ref lapackint ldvsr, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *bwork, ref lapackint info);
void zgges_(ref char jobvsl, ref char jobvsr, ref char sort, FCB_ZGGES_DELCTG delctg, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, lapackint *sdim, _cdouble *alphav, _cdouble *betav, _cdouble *vsl, ref lapackint ldvsl, _cdouble *vsr, ref lapackint ldvsr, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *bwork, ref lapackint info);

/// Computes the generalized eigenvalues, and left and/or right
/// generalized eigenvectors for a pair of nonsymmetric matrices
void sgegv_(ref char jobvl, ref char jobvr, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *alphar, float *alphai, float *betav, float *vl, ref lapackint ldvl, float *vr, ref lapackint ldvr, float *work, ref lapackint lwork, ref lapackint info);
void dgegv_(ref char jobvl, ref char jobvr, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *alphar, double *alphai, double *betav, double *vl, ref lapackint ldvl, double *vr, ref lapackint ldvr, double *work, ref lapackint lwork, ref lapackint info);
void cgegv_(ref char jobvl, ref char jobvr, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *alphar, _cfloat *betav, _cfloat *vl, ref lapackint ldvl, _cfloat *vr, ref lapackint ldvr, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zgegv_(ref char jobvl, ref char jobvr, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *alphar, _cdouble *betav, _cdouble *vl, ref lapackint ldvl, _cdouble *vr, ref lapackint ldvr, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Computes the generalized eigenvalues, and left and/or right
/// generalized eigenvectors for a pair of nonsymmetric matrices
void sggev_(ref char jobvl, ref char jobvr, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *alphar, float *alphai, float *betav, float *vl, ref lapackint ldvl, float *vr, ref lapackint ldvr, float *work, ref lapackint lwork, ref lapackint info);
void dggev_(ref char jobvl, ref char jobvr, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *alphar, double *alphai, double *betav, double *vl, ref lapackint ldvl, double *vr, ref lapackint ldvr, double *work, ref lapackint lwork, ref lapackint info);
void cggev_(ref char jobvl, ref char jobvr, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *alphav, _cfloat *betav, _cfloat *vl, ref lapackint ldvl, _cfloat *vr, ref lapackint ldvr, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zggev_(ref char jobvl, ref char jobvr, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *alphav, _cdouble *betav, _cdouble *vl, ref lapackint ldvl, _cdouble *vr, ref lapackint ldvr, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Computes the Generalized Singular Value Decomposition
void sggsvd_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint n, ref lapackint p, ref lapackint k, ref lapackint l, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *alphav, float *betav, float *u, ref lapackint ldu, float *v, ref lapackint ldv, float *q, ref lapackint ldq, float *work, lapackint *iwork, ref lapackint info);
void dggsvd_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint n, ref lapackint p, ref lapackint k, ref lapackint l, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *alphav, double *betav, double *u, ref lapackint ldu, double *v, ref lapackint ldv, double *q, ref lapackint ldq, double *work, lapackint *iwork, ref lapackint info);
void cggsvd_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint n, ref lapackint p, ref lapackint k, ref lapackint l, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, float *alphav, float *betav, _cfloat *u, ref lapackint ldu, _cfloat *v, ref lapackint ldv, _cfloat *q, ref lapackint ldq, _cfloat *work, float *rwork, lapackint *iwork, ref lapackint info);
void zggsvd_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint n, ref lapackint p, ref lapackint k, ref lapackint l, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, double *alphav, double *betav, _cdouble *u, ref lapackint ldu, _cdouble *v, ref lapackint ldv, _cdouble *q, ref lapackint ldq, _cdouble *work, double *rwork, lapackint *iwork, ref lapackint info);

//-----------------------------------------------------
//       ---- EXPERT and RRR DRIVER routines ----
//-----------------------------------------------------

/// Solves a general system of linear equations AX=B, A**T X=B
/// or A**H X=B, and provides an estimate of the condition number
/// and error bounds on the solution.
void sgesvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *af, ref lapackint ldaf, lapackint *ipiv, ref char equed, float *r, float *c, float *b, ref lapackint ldb, float *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dgesvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *af, ref lapackint ldaf, lapackint *ipiv, ref char equed, double *r, double *c, double *b, ref lapackint ldb, double *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cgesvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *af, ref lapackint ldaf, lapackint *ipiv, ref char equed, float *r, float *c, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zgesvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *af, ref lapackint ldaf, lapackint *ipiv, ref char equed, double *r, double *c, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Solves a general banded system of linear equations AX=B,
/// A**T X=B or A**H X=B, and provides an estimate of the condition
/// number and error bounds on the solution.
void sgbsvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, float *ab, ref lapackint ldab, float *afb, ref lapackint ldafb, lapackint *ipiv, ref char equed, float *r, float *c, float *b, ref lapackint ldb, float *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dgbsvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, double *ab, ref lapackint ldab, double *afb, ref lapackint ldafb, lapackint *ipiv, ref char equed, double *r, double *c, double *b, ref lapackint ldb, double *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cgbsvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, _cfloat *ab, ref lapackint ldab, _cfloat *afb, ref lapackint ldafb, lapackint *ipiv, ref char equed, float *r, float *c, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zgbsvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, _cdouble *ab, ref lapackint ldab, _cdouble *afb, ref lapackint ldafb, lapackint *ipiv, ref char equed, double *r, double *c, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Solves a general tridiagonal system of linear equations AX=B,
/// A**T X=B or A**H X=B, and provides an estimate of the condition
/// number  and error bounds on the solution.
void sgtsvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint nrhs, float *dl, float *d, float *du, float *dlf, float *df, float *duf, float *du2, lapackint *ipiv, float *b, ref lapackint ldb, float *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dgtsvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint nrhs, double *dl, double *d, double *du, double *dlf, double *df, double *duf, double *du2, lapackint *ipiv, double *b, ref lapackint ldb, double *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cgtsvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint nrhs, _cfloat *dl, _cfloat *d, _cfloat *du, _cfloat *dlf, _cfloat *df, _cfloat *duf, _cfloat *du2, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zgtsvx_(ref char fact, ref char trans, ref lapackint n, ref lapackint nrhs, _cdouble *dl, _cdouble *d, _cdouble *du, _cdouble *dlf, _cdouble *df, _cdouble *duf, _cdouble *du2, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Solves a symmetric positive definite system of linear
/// equations AX=B, and provides an estimate of the condition number
/// and error bounds on the solution.
void sposvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *af, ref lapackint ldaf, ref char equed, float *s, float *b, ref lapackint ldb, float *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dposvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *af, ref lapackint ldaf, ref char equed, double *s, double *b, ref lapackint ldb, double *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cposvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *af, ref lapackint ldaf, ref char equed, float *s, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zposvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *af, ref lapackint ldaf, ref char equed, double *s, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Solves a symmetric positive definite system of linear
/// equations AX=B, where A is held in packed storage, and provides
/// an estimate of the condition number and error bounds on the
/// solution.
void sppsvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, float *ap, float *afp, ref char equed, float *s, float *b, ref lapackint ldb, float *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dppsvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, double *ap, double *afp, ref char equed, double *s, double *b, ref lapackint ldb, double *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cppsvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, _cfloat *afp, ref char equed, float *s, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zppsvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, _cdouble *afp, ref char equed, double *s, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Solves a symmetric positive definite banded system
/// of linear equations AX=B, and provides an estimate of the condition
/// number and error bounds on the solution.
void spbsvx_(ref char fact, ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, float *ab, ref lapackint ldab, float *afb, ref lapackint ldafb, ref char equed, float *s, float *b, ref lapackint ldb, float *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dpbsvx_(ref char fact, ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, double *ab, ref lapackint ldab, double *afb, ref lapackint ldafb, ref char equed, double *s, double *b, ref lapackint ldb, double *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cpbsvx_(ref char fact, ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cfloat *ab, ref lapackint ldab, _cfloat *afb, ref lapackint ldafb, ref char equed, float *s, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zpbsvx_(ref char fact, ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cdouble *ab, ref lapackint ldab, _cdouble *afb, ref lapackint ldafb, ref char equed, double *s, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Solves a symmetric positive definite tridiagonal
/// system of linear equations AX=B, and provides an estimate of
/// the condition number and error bounds on the solution.
void sptsvx_(ref char fact, ref lapackint n, ref lapackint nrhs, float *d, float *e, float *df, float *ef, float *b, ref lapackint ldb, float *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, float *work, ref lapackint info);
void dptsvx_(ref char fact, ref lapackint n, ref lapackint nrhs, double *d, double *e, double *df, double *ef, double *b, ref lapackint ldb, double *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, double *work, ref lapackint info);
void cptsvx_(ref char fact, ref lapackint n, ref lapackint nrhs, float *d, _cfloat *e, float *df, _cfloat *ef, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zptsvx_(ref char fact, ref lapackint n, ref lapackint nrhs, double *d, _cdouble *e, double *df, _cdouble *ef, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Solves a real symmetric
/// indefinite system  of linear equations AX=B, and provides an
/// estimate of the condition number and error bounds on the solution.
void ssysvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *af, ref lapackint ldaf, lapackint *ipiv, float *b, ref lapackint ldb, float *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, float *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void dsysvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *af, ref lapackint ldaf, lapackint *ipiv, double *b, ref lapackint ldb, double *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, double *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void csysvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *af, ref lapackint ldaf, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zsysvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *af, ref lapackint ldaf, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Solves a complex Hermitian
/// indefinite system  of linear equations AX=B, and provides an
/// estimate of the condition number and error bounds on the solution.
void chesvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *af, ref lapackint ldaf, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zhesvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *af, ref lapackint ldaf, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Solves a real symmetric
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, and provides an estimate of the condition
/// number and error bounds on the solution.
void sspsvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, float *ap, float *afp, lapackint *ipiv, float *b, ref lapackint ldb, float *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dspsvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, double *ap, double *afp, lapackint *ipiv, double *b, ref lapackint ldb, double *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cspsvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, _cfloat *afp, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zspsvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, _cdouble *afp, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Solves a complex Hermitian
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, and provides an estimate of the condition
/// number and error bounds on the solution.
void chpsvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, _cfloat *afp, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, ref float rcond, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zhpsvx_(ref char fact, ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, _cdouble *afp, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, ref double rcond, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Computes the minimum norm least squares solution to an over-
/// or under-determined system of linear equations A X=B, using a
/// complete orthogonal factorization of A.
void sgelsx_(ref lapackint m, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *b, ref lapackint ldb, lapackint *jpvt, ref float rcond, ref lapackint rank, float *work, ref lapackint info);
void dgelsx_(ref lapackint m, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *b, ref lapackint ldb, lapackint *jpvt, ref double rcond, ref lapackint rank, double *work, ref lapackint info);
void cgelsx_(ref lapackint m, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, lapackint *jpvt, ref float rcond, ref lapackint rank, _cfloat *work, float *rwork, ref lapackint info);
void zgelsx_(ref lapackint m, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, lapackint *jpvt, ref double rcond, ref lapackint rank, _cdouble *work, double *rwork, ref lapackint info);

/// Computes the minimum norm least squares solution to an over-
/// or under-determined system of linear equations A X=B, using a
/// complete orthogonal factorization of A.
void sgelsy_(ref lapackint m, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *b, ref lapackint ldb, lapackint *jpvt, ref float rcond, ref lapackint rank, float *work, ref lapackint lwork, ref lapackint info);
void dgelsy_(ref lapackint m, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *b, ref lapackint ldb, lapackint *jpvt, ref double rcond, ref lapackint rank, double *work, ref lapackint lwork, ref lapackint info);
void cgelsy_(ref lapackint m, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, lapackint *jpvt, ref float rcond, ref lapackint rank, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zgelsy_(ref lapackint m, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, lapackint *jpvt, ref double rcond, ref lapackint rank, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Computes the minimum norm least squares solution to an over-
/// or under-determined system of linear equations A X=B,  using
/// the singular value decomposition of A.
void sgelss_(ref lapackint m, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *s, ref float rcond, ref lapackint rank, float *work, ref lapackint lwork, ref lapackint info);
void dgelss_(ref lapackint m, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *s, ref double rcond, ref lapackint rank, double *work, ref lapackint lwork, ref lapackint info);
void cgelss_(ref lapackint m, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, float *s, ref float rcond, ref lapackint rank, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zgelss_(ref lapackint m, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, double *s, ref double rcond, ref lapackint rank, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Computes selected eigenvalues and eigenvectors of a symmetric matrix.
void ssyevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, float *a, ref lapackint lda, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, float *z, ref lapackint ldz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *ifail, ref lapackint info);
void dsyevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, double *a, ref lapackint lda, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, double *z, ref lapackint ldz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues and eigenvectors of a Hermitian matrix.
void cheevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);
void zheevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues, and optionally, eigenvectors of a real
/// symmetric matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
void ssyevr_(ref char jobz, ref char range, ref char uplo, ref lapackint n, float *a, ref lapackint lda, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, float *z, ref lapackint ldz, lapackint *isuppz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dsyevr_(ref char jobz, ref char range, ref char uplo, ref lapackint n, double *a, ref lapackint lda, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, double *z, ref lapackint ldz, lapackint *isuppz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes selected eigenvalues, and optionally, eigenvectors of a complex
/// Hermitian matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
void cheevr_(ref char jobz, ref char range, ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, _cfloat *z, ref lapackint ldz, lapackint *isuppz, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void zheevr_(ref char jobz, ref char range, ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, _cdouble *z, ref lapackint ldz, lapackint *isuppz, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);


/// Computes selected eigenvalues, and optionally, the eigenvectors of
/// a generalized symmetric-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void ssygvx_(lapackint *itype, ref char jobz, ref char range, ref char uplo, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, float *z, ref lapackint ldz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *ifail, ref lapackint info);
void dsygvx_(lapackint *itype, ref char jobz, ref char range, ref char uplo, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, double *z, ref lapackint ldz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues, and optionally, the eigenvectors of
/// a generalized Hermitian-definite generalized eigenproblem,
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x.
void chegvx_(lapackint *itype, ref char jobz, ref char range, ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);
void zhegvx_(lapackint *itype, ref char jobz, ref char range, ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues and eigenvectors of a
/// symmetric matrix in packed storage.
void sspevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, float *ap, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, float *z, ref lapackint ldz, float *work, lapackint *iwork, lapackint *ifail, ref lapackint info);
void dspevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, double *ap, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, double *z, ref lapackint ldz, double *work, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues and eigenvectors of a
/// Hermitian matrix in packed storage.
void chpevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, _cfloat *ap, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, float *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);
void zhpevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, _cdouble *ap, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, double *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues, and optionally, eigenvectors of
/// a generalized symmetric-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void sspgvx_(lapackint *itype, ref char jobz, ref char range, ref char uplo, ref lapackint n, float *ap, float *bp, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, float *z, ref lapackint ldz, float *work, lapackint *iwork, lapackint *ifail, ref lapackint info);
void dspgvx_(lapackint *itype, ref char jobz, ref char range, ref char uplo, ref lapackint n, double *ap, double *bp, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, double *z, ref lapackint ldz, double *work, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues, and optionally, the eigenvectors of
/// a generalized Hermitian-definite generalized eigenproblem,  Ax= lambda
/// Bx,  ABx= lambda x,  or BAx= lambda x, where A and B are in packed
/// storage.
void chpgvx_(lapackint *itype, ref char jobz, ref char range, ref char uplo, ref lapackint n, _cfloat *ap, _cfloat *bp, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, float *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);
void zhpgvx_(lapackint *itype, ref char jobz, ref char range, ref char uplo, ref lapackint n, _cdouble *ap, _cdouble *bp, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, double *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues and eigenvectors of a
/// symmetric band matrix.
void ssbevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, lapackint *kd, float *ab, ref lapackint ldab, float *q, ref lapackint ldq, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, float *z, ref lapackint ldz, float *work, lapackint *iwork, lapackint *ifail, ref lapackint info);
void dsbevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, lapackint *kd, double *ab, ref lapackint ldab, double *q, ref lapackint ldq, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, double *z, ref lapackint ldz, double *work, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues and eigenvectors of a
/// Hermitian band matrix.
void chbevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, lapackint *kd, _cfloat *ab, ref lapackint ldab, _cfloat *q, ref lapackint ldq, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, float *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);
void zhbevx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, lapackint *kd, _cdouble *ab, ref lapackint ldab, _cdouble *q, ref lapackint ldq, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, double *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues, and optionally, the eigenvectors
/// of a real generalized symmetric-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be symmetric
/// and banded, and B is also positive definite.
void ssbgvx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, float *ab, ref lapackint ldab, float *bb, ref lapackint ldbb, float *q, ref lapackint ldq, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, float *z, ref lapackint ldz, float *work, lapackint *iwork, lapackint *ifail, ref lapackint info);
void dsbgvx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, double *ab, ref lapackint ldab, double *bb, ref lapackint ldbb, double *q, ref lapackint ldq, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, double *z, ref lapackint ldz, double *work, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues, and optionally, the eigenvectors
/// of a complex generalized Hermitian-definite banded eigenproblem, of
/// the form A*x=(lambda)*B*x.  A and B are assumed to be Hermitian
/// and banded, and B is also positive definite.
void chbgvx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, _cfloat *ab, ref lapackint ldab, _cfloat *bb, ref lapackint ldbb, _cfloat *q, ref lapackint ldq, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, _cfloat *z, ref lapackint ldz, _cfloat *work, float *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);
void zhbgvx_(ref char jobz, ref char range, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, _cdouble *ab, ref lapackint ldab, _cdouble *bb, ref lapackint ldbb, _cdouble *q, ref lapackint ldq, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, _cdouble *z, ref lapackint ldz, _cdouble *work, double *rwork, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues and eigenvectors of a real
/// symmetric tridiagonal matrix.
void sstevx_(ref char jobz, ref char range, ref lapackint n, float *d, float *e, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, float *z, ref lapackint ldz, float *work, lapackint *iwork, lapackint *ifail, ref lapackint info);
void dstevx_(ref char jobz, ref char range, ref lapackint n, double *d, double *e, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, double *z, ref lapackint ldz, double *work, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes selected eigenvalues, and optionally, eigenvectors of a real
/// symmetric tridiagonal matrix.  Eigenvalues are computed by the dqds
/// algorithm, and eigenvectors are computed from various "good" LDL^T
/// representations (also known as Relatively Robust Representations).
void sstevr_(ref char jobz, ref char range, ref lapackint n, float *d, float *e, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, float *z, ref lapackint ldz, lapackint *isuppz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dstevr_(ref char jobz, ref char range, ref lapackint n, double *d, double *e, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, double *z, ref lapackint ldz, lapackint *isuppz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes the eigenvalues and Schur factorization of a general
/// matrix, orders the factorization so that selected eigenvalues
/// are at the top left of the Schur form, and computes reciprocal
/// condition numbers for the average of the selected eigenvalues,
/// and for the associated right invariant subspace.
void sgeesx_(ref char jobvs, ref char sort, FCB_SGEESX_SELECT select, ref char sense, ref lapackint n, float *a, ref lapackint lda, lapackint *sdim, float *wr, float *wi, float *vs, ref lapackint ldvs, ref float rconde, ref float rcondv, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, lapackint *bwork, ref lapackint info);
void dgeesx_(ref char jobvs, ref char sort, FCB_DGEESX_SELECT select, ref char sense, ref lapackint n, double *a, ref lapackint lda, lapackint *sdim, double *wr, double *wi, double *vs, ref lapackint ldvs, ref double rconde, ref double rcondv, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, lapackint *bwork, ref lapackint info);
void cgeesx_(ref char jobvs, ref char sort, FCB_CGEESX_SELECT select, ref char sense, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *sdim, _cfloat *w, _cfloat *vs, ref lapackint ldvs, ref float rconde, ref float rcondv, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *bwork, ref lapackint info);
void zgeesx_(ref char jobvs, ref char sort, FCB_ZGEESX_SELECT select, ref char sense, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *sdim, _cdouble *w, _cdouble *vs, ref lapackint ldvs, ref double rconde, ref double rcondv, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *bwork, ref lapackint info);

/// Computes the generalized eigenvalues, the real Schur form, and,
/// optionally, the left and/or right matrices of Schur vectors.
void sggesx_(ref char jobvsl, ref char jobvsr, ref char sort, FCB_SGGESX_SELCTG selctg, ref char sense, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, lapackint *sdim, float *alphar, float *alphai, float *betav, float *vsl, ref lapackint ldvsl, float *vsr, ref lapackint ldvsr, ref float rconde, ref float rcondv, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, lapackint *bwork, ref lapackint info);
void dggesx_(ref char jobvsl, ref char jobvsr, ref char sort, FCB_DGGESX_DELCTG delctg, ref char sense, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, lapackint *sdim, double *alphar, double *alphai, double *betav, double *vsl, ref lapackint ldvsl, double *vsr, ref lapackint ldvsr, ref double rconde, ref double rcondv, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, lapackint *bwork, ref lapackint info);
void cggesx_(ref char jobvsl, ref char jobvsr, ref char sort, FCB_CGGESX_SELCTG selctg, ref char sense, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, lapackint *sdim, _cfloat *alphav, _cfloat *betav, _cfloat *vsl, ref lapackint ldvsl, _cfloat *vsr, ref lapackint ldvsr, ref float rconde, ref float rcondv, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *iwork, lapackint *liwork, lapackint *bwork, ref lapackint info);
void zggesx_(ref char jobvsl, ref char jobvsr, ref char sort, FCB_ZGGESX_DELCTG delctg, ref char sense, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, lapackint *sdim, _cdouble *alphav, _cdouble *betav, _cdouble *vsl, ref lapackint ldvsl, _cdouble *vsr, ref lapackint ldvsr, ref double rconde, ref double rcondv, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *iwork, lapackint *liwork, lapackint *bwork, ref lapackint info);

/// Computes the eigenvalues and left and right eigenvectors of
/// a general matrix,  with preliminary balancing of the matrix,
/// and computes reciprocal condition numbers for the eigenvalues
/// and right eigenvectors.
void sgeevx_(ref char balanc, ref char jobvl, ref char jobvr, ref char sense, ref lapackint n, float *a, ref lapackint lda, float *wr, float *wi, float *vl, ref lapackint ldvl, float *vr, ref lapackint ldvr, lapackint *ilo, lapackint *ihi, float *scale, float *abnrm, ref float rconde, ref float rcondv, float *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void dgeevx_(ref char balanc, ref char jobvl, ref char jobvr, ref char sense, ref lapackint n, double *a, ref lapackint lda, double *wr, double *wi, double *vl, ref lapackint ldvl, double *vr, ref lapackint ldvr, lapackint *ilo, lapackint *ihi, double *scale, double *abnrm, ref double rconde, ref double rcondv, double *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void cgeevx_(ref char balanc, ref char jobvl, ref char jobvr, ref char sense, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *w, _cfloat *vl, ref lapackint ldvl, _cfloat *vr, ref lapackint ldvr, lapackint *ilo, lapackint *ihi, float *scale, float *abnrm, ref float rconde, ref float rcondv, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zgeevx_(ref char balanc, ref char jobvl, ref char jobvr, ref char sense, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *w, _cdouble *vl, ref lapackint ldvl, _cdouble *vr, ref lapackint ldvr, lapackint *ilo, lapackint *ihi, double *scale, double *abnrm, ref double rconde, ref double rcondv, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Computes the generalized eigenvalues, and optionally, the left
/// and/or right generalized eigenvectors.
void sggevx_(ref char balanc, ref char jobvl, ref char jobvr, ref char sense, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *alphar, float *alphai, float *betav, float *vl, ref lapackint ldvl, float *vr, ref lapackint ldvr, lapackint *ilo, lapackint *ihi, float *lscale, float *rscale, float *abnrm, float *bbnrm, ref float rconde, ref float rcondv, float *work, ref lapackint lwork, lapackint *iwork, lapackint *bwork, ref lapackint info);
void dggevx_(ref char balanc, ref char jobvl, ref char jobvr, ref char sense, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *alphar, double *alphai, double *betav, double *vl, ref lapackint ldvl, double *vr, ref lapackint ldvr, lapackint *ilo, lapackint *ihi, double *lscale, double *rscale, double *abnrm, double *bbnrm, ref double rconde, ref double rcondv, double *work, ref lapackint lwork, lapackint *iwork, lapackint *bwork, ref lapackint info);
void cggevx_(ref char balanc, ref char jobvl, ref char jobvr, ref char sense, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *alphav, _cfloat *betav, _cfloat *vl, ref lapackint ldvl, _cfloat *vr, ref lapackint ldvr, lapackint *ilo, lapackint *ihi, float *lscale, float *rscale, float *abnrm, float *bbnrm, ref float rconde, ref float rcondv, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *iwork, lapackint *bwork, ref lapackint info);
void zggevx_(ref char balanc, ref char jobvl, ref char jobvr, ref char sense, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *alphav, _cdouble *betav, _cdouble *vl, ref lapackint ldvl, _cdouble *vr, ref lapackint ldvr, lapackint *ilo, lapackint *ihi, double *lscale, double *rscale, double *abnrm, double *bbnrm, ref double rconde, ref double rcondv, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *iwork, lapackint *bwork, ref lapackint info);



//----------------------------------------
//    ---- COMPUTATIONAL routines ----
//----------------------------------------


/// Computes the singular value decomposition (SVD) of a real bidiagonal
/// matrix, using a divide and conquer method.
void sbdsdc_(ref char uplo, ref char compq, ref lapackint n, float *d, float *e, float *u, ref lapackint ldu, float *vt, ref lapackint ldvt, float *q, lapackint *iq, float *work, lapackint *iwork, ref lapackint info);
void dbdsdc_(ref char uplo, ref char compq, ref lapackint n, double *d, double *e, double *u, ref lapackint ldu, double *vt, ref lapackint ldvt, double *q, lapackint *iq, double *work, lapackint *iwork, ref lapackint info);

/// Computes the singular value decomposition (SVD) of a real bidiagonal
/// matrix, using the bidiagonal QR algorithm.
void sbdsqr_(ref char uplo, ref lapackint n, ref lapackint ncvt, ref lapackint nru, ref lapackint ncc, float *d, float *e, float *vt, ref lapackint ldvt, float *u, ref lapackint ldu, float *c, ref lapackint ldc, float *work, ref lapackint info);
void dbdsqr_(ref char uplo, ref lapackint n, ref lapackint ncvt, ref lapackint nru, ref lapackint ncc, double *d, double *e, double *vt, ref lapackint ldvt, double *u, ref lapackint ldu, double *c, ref lapackint ldc, double *work, ref lapackint info);
void cbdsqr_(ref char uplo, ref lapackint n, ref lapackint ncvt, ref lapackint nru, ref lapackint ncc, float *d, float *e, _cfloat *vt, ref lapackint ldvt, _cfloat *u, ref lapackint ldu, _cfloat *c, ref lapackint ldc, float *rwork, ref lapackint info);
void zbdsqr_(ref char uplo, ref lapackint n, ref lapackint ncvt, ref lapackint nru, ref lapackint ncc, double *d, double *e, _cdouble *vt, ref lapackint ldvt, _cdouble *u, ref lapackint ldu, _cdouble *c, ref lapackint ldc, double *rwork, ref lapackint info);

/// Computes the reciprocal condition numbers for the eigenvectors of a
/// real symmetric or complex Hermitian matrix or for the left or right
/// singular vectors of a general matrix.
void sdisna_(ref char job, ref lapackint m, ref lapackint n, float *d, float *sep, ref lapackint info);
void ddisna_(ref char job, ref lapackint m, ref lapackint n, double *d, double *sep, ref lapackint info);

/// Reduces a general band matrix to real upper bidiagonal form
/// by an orthogonal transformation.
void sgbbrd_(ref char vect, ref lapackint m, ref lapackint n, ref lapackint ncc, ref lapackint kl, ref lapackint ku, float *ab, ref lapackint ldab, float *d, float *e, float *q, ref lapackint ldq, float *pt, ref lapackint ldpt, float *c, ref lapackint ldc, float *work, ref lapackint info);
void dgbbrd_(ref char vect, ref lapackint m, ref lapackint n, ref lapackint ncc, ref lapackint kl, ref lapackint ku, double *ab, ref lapackint ldab, double *d, double *e, double *q, ref lapackint ldq, double *pt, ref lapackint ldpt, double *c, ref lapackint ldc, double *work, ref lapackint info);
void cgbbrd_(ref char vect, ref lapackint m, ref lapackint n, ref lapackint ncc, ref lapackint kl, ref lapackint ku, _cfloat *ab, ref lapackint ldab, float *d, float *e, _cfloat *q, ref lapackint ldq, _cfloat *pt, ref lapackint ldpt, _cfloat *c, ref lapackint ldc, _cfloat *work, float *rwork, ref lapackint info);
void zgbbrd_(ref char vect, ref lapackint m, ref lapackint n, ref lapackint ncc, ref lapackint kl, ref lapackint ku, _cdouble *ab, ref lapackint ldab, double *d, double *e, _cdouble *q, ref lapackint ldq, _cdouble *pt, ref lapackint ldpt, _cdouble *c, ref lapackint ldc, _cdouble *work, double *rwork, ref lapackint info);

/// Estimates the reciprocal of the condition number of a general
/// band matrix, in either the 1-norm or the infinity-norm, using
/// the LU factorization computed by SGBTRF.
void sgbcon_(ref char norm, ref lapackint n, ref lapackint kl, ref lapackint ku, float *ab, ref lapackint ldab, lapackint *ipiv, float *anorm, ref float rcond, float *work, lapackint *iwork, ref lapackint info);
void dgbcon_(ref char norm, ref lapackint n, ref lapackint kl, ref lapackint ku, double *ab, ref lapackint ldab, lapackint *ipiv, double *anorm, ref double rcond, double *work, lapackint *iwork, ref lapackint info);
void cgbcon_(ref char norm, ref lapackint n, ref lapackint kl, ref lapackint ku, _cfloat *ab, ref lapackint ldab, lapackint *ipiv, float *anorm, ref float rcond, _cfloat *work, float *rwork, ref lapackint info);
void zgbcon_(ref char norm, ref lapackint n, ref lapackint kl, ref lapackint ku, _cdouble *ab, ref lapackint ldab, lapackint *ipiv, double *anorm, ref double rcond, _cdouble *work, double *rwork, ref lapackint info);

/// Computes row and column scalings to equilibrate a general band
/// matrix and reduce its condition number.
void sgbequ_(ref lapackint m, ref lapackint n, ref lapackint kl, ref lapackint ku, float *ab, ref lapackint ldab, float *r, float *c, float *rowcnd, float *colcnd, float *amax, ref lapackint info);
void dgbequ_(ref lapackint m, ref lapackint n, ref lapackint kl, ref lapackint ku, double *ab, ref lapackint ldab, double *r, double *c, double *rowcnd, double *colcnd, double *amax, ref lapackint info);
void cgbequ_(ref lapackint m, ref lapackint n, ref lapackint kl, ref lapackint ku, _cfloat *ab, ref lapackint ldab, float *r, float *c, float *rowcnd, float *colcnd, float *amax, ref lapackint info);
void zgbequ_(ref lapackint m, ref lapackint n, ref lapackint kl, ref lapackint ku, _cdouble *ab, ref lapackint ldab, double *r, double *c, double *rowcnd, double *colcnd, double *amax, ref lapackint info);

/// Improves the computed solution to a general banded system of
/// linear equations AX=B, A**T X=B or A**H X=B, and provides forward
/// and backward error bounds for the solution.
void sgbrfs_(ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, float *ab, ref lapackint ldab, float *afb, ref lapackint ldafb, lapackint *ipiv, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dgbrfs_(ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, double *ab, ref lapackint ldab, double *afb, ref lapackint ldafb, lapackint *ipiv, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cgbrfs_(ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, _cfloat *ab, ref lapackint ldab, _cfloat *afb, ref lapackint ldafb, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zgbrfs_(ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, _cdouble *ab, ref lapackint ldab, _cdouble *afb, ref lapackint ldafb, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Computes an LU factorization of a general band matrix, using
/// partial pivoting with row interchanges.
void sgbtrf_(ref lapackint m, ref lapackint n, ref lapackint kl, ref lapackint ku, float *ab, ref lapackint ldab, lapackint *ipiv, ref lapackint info);
void dgbtrf_(ref lapackint m, ref lapackint n, ref lapackint kl, ref lapackint ku, double *ab, ref lapackint ldab, lapackint *ipiv, ref lapackint info);
void cgbtrf_(ref lapackint m, ref lapackint n, ref lapackint kl, ref lapackint ku, _cfloat *ab, ref lapackint ldab, lapackint *ipiv, ref lapackint info);
void zgbtrf_(ref lapackint m, ref lapackint n, ref lapackint kl, ref lapackint ku, _cdouble *ab, ref lapackint ldab, lapackint *ipiv, ref lapackint info);

/// Solves a general banded system of linear equations AX=B,
/// A**T X=B or A**H X=B, using the LU factorization computed
/// by SGBTRF.
void sgbtrs_(ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, float *ab, ref lapackint ldab, lapackint *ipiv, float *b, ref lapackint ldb, ref lapackint info);
void dgbtrs_(ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, double *ab, ref lapackint ldab, lapackint *ipiv, double *b, ref lapackint ldb, ref lapackint info);
void cgbtrs_(ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, _cfloat *ab, ref lapackint ldab, lapackint *ipiv, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zgbtrs_(ref char trans, ref lapackint n, ref lapackint kl, ref lapackint ku, ref lapackint nrhs, _cdouble *ab, ref lapackint ldab, lapackint *ipiv, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Transforms eigenvectors of a balanced matrix to those of the
/// original matrix supplied to SGEBAL.
void sgebak_(ref char job, ref char side, ref lapackint n, lapackint *ilo, lapackint *ihi, float *scale, ref lapackint m, float *v, ref lapackint ldv, ref lapackint info);
void dgebak_(ref char job, ref char side, ref lapackint n, lapackint *ilo, lapackint *ihi, double *scale, ref lapackint m, double *v, ref lapackint ldv, ref lapackint info);
void cgebak_(ref char job, ref char side, ref lapackint n, lapackint *ilo, lapackint *ihi, float *scale, ref lapackint m, _cfloat *v, ref lapackint ldv, ref lapackint info);
void zgebak_(ref char job, ref char side, ref lapackint n, lapackint *ilo, lapackint *ihi, double *scale, ref lapackint m, _cdouble *v, ref lapackint ldv, ref lapackint info);

/// Balances a general matrix in order to improve the accuracy
/// of computed eigenvalues.
void sgebal_(ref char job, ref lapackint n, float *a, ref lapackint lda, lapackint *ilo, lapackint *ihi, float *scale, ref lapackint info);
void dgebal_(ref char job, ref lapackint n, double *a, ref lapackint lda, lapackint *ilo, lapackint *ihi, double *scale, ref lapackint info);
void cgebal_(ref char job, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *ilo, lapackint *ihi, float *scale, ref lapackint info);
void zgebal_(ref char job, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *ilo, lapackint *ihi, double *scale, ref lapackint info);

/// Reduces a general rectangular matrix to real bidiagonal form
/// by an orthogonal transformation.
void sgebrd_(ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *d, float *e, float *tauq, float *taup, float *work, ref lapackint lwork, ref lapackint info);
void dgebrd_(ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *d, double *e, double *tauq, double *taup, double *work, ref lapackint lwork, ref lapackint info);
void cgebrd_(ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, float *d, float *e, _cfloat *tauq, _cfloat *taup, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zgebrd_(ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, double *d, double *e, _cdouble *tauq, _cdouble *taup, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Estimates the reciprocal of the condition number of a general
/// matrix, in either the 1-norm or the infinity-norm, using the
/// LU factorization computed by SGETRF.
void sgecon_(ref char norm, ref lapackint n, float *a, ref lapackint lda, float *anorm, ref float rcond, float *work, lapackint *iwork, ref lapackint info);
void dgecon_(ref char norm, ref lapackint n, double *a, ref lapackint lda, double *anorm, ref double rcond, double *work, lapackint *iwork, ref lapackint info);
void cgecon_(ref char norm, ref lapackint n, _cfloat *a, ref lapackint lda, float *anorm, ref float rcond, _cfloat *work, float *rwork, ref lapackint info);
void zgecon_(ref char norm, ref lapackint n, _cdouble *a, ref lapackint lda, double *anorm, ref double rcond, _cdouble *work, double *rwork, ref lapackint info);

/// Computes row and column scalings to equilibrate a general
/// rectangular matrix and reduce its condition number.
void sgeequ_(ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *r, float *c, float *rowcnd, float *colcnd, float *amax, ref lapackint info);
void dgeequ_(ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *r, double *c, double *rowcnd, double *colcnd, double *amax, ref lapackint info);
void cgeequ_(ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, float *r, float *c, float *rowcnd, float *colcnd, float *amax, ref lapackint info);
void zgeequ_(ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, double *r, double *c, double *rowcnd, double *colcnd, double *amax, ref lapackint info);

/// Reduces a general matrix to upper Hessenberg form by an
/// orthogonal similarity transformation.
void sgehrd_(ref lapackint n, lapackint *ilo, lapackint *ihi, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dgehrd_(ref lapackint n, lapackint *ilo, lapackint *ihi, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);
void cgehrd_(ref lapackint n, lapackint *ilo, lapackint *ihi, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zgehrd_(ref lapackint n, lapackint *ilo, lapackint *ihi, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Computes an LQ factorization of a general rectangular matrix.
void sgelqf_(ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dgelqf_(ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);
void cgelqf_(ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zgelqf_(ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Computes a QL factorization of a general rectangular matrix.
void sgeqlf_(ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dgeqlf_(ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);
void cgeqlf_(ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zgeqlf_(ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Computes a QR factorization with column pivoting of a general
/// rectangular matrix using Level 3 BLAS.
void sgeqp3_(ref lapackint m, ref lapackint n, float *a, ref lapackint lda, lapackint *jpvt, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dgeqp3_(ref lapackint m, ref lapackint n, double *a, ref lapackint lda, lapackint *jpvt, double *tau, double *work, ref lapackint lwork, ref lapackint info);
void cgeqp3_(ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *jpvt, _cfloat *tau, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zgeqp3_(ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *jpvt, _cdouble *tau, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Computes a QR factorization with column pivoting of a general
/// rectangular matrix.
void sgeqpf_(ref lapackint m, ref lapackint n, float *a, ref lapackint lda, lapackint *jpvt, float *tau, float *work, ref lapackint info);
void dgeqpf_(ref lapackint m, ref lapackint n, double *a, ref lapackint lda, lapackint *jpvt, double *tau, double *work, ref lapackint info);
void cgeqpf_(ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *jpvt, _cfloat *tau, _cfloat *work, float *rwork, ref lapackint info);
void zgeqpf_(ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *jpvt, _cdouble *tau, _cdouble *work, double *rwork, ref lapackint info);

/// Computes a QR factorization of a general rectangular matrix.
void sgeqrf_(ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dgeqrf_(ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);
void cgeqrf_(ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zgeqrf_(ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Improves the computed solution to a general system of linear
/// equations AX=B, A**T X=B or A**H X=B, and provides forward and
/// backward error bounds for the solution.
void sgerfs_(ref char trans, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *af, ref lapackint ldaf, lapackint *ipiv, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dgerfs_(ref char trans, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *af, ref lapackint ldaf, lapackint *ipiv, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cgerfs_(ref char trans, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *af, ref lapackint ldaf, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zgerfs_(ref char trans, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *af, ref lapackint ldaf, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Computes an RQ factorization of a general rectangular matrix.
void sgerqf_(ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dgerqf_(ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);
void cgerqf_(ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zgerqf_(ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Computes an LU factorization of a general matrix, using partial
/// pivoting with row interchanges.
void sgetrf_(ref lapackint m, ref lapackint n, float *a, ref lapackint lda, lapackint *ipiv, ref lapackint info);
void dgetrf_(ref lapackint m, ref lapackint n, double *a, ref lapackint lda, lapackint *ipiv, ref lapackint info);
void cgetrf_(ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *ipiv, ref lapackint info);
void zgetrf_(ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *ipiv, ref lapackint info);

/// Computes the inverse of a general matrix, using the LU factorization
/// computed by SGETRF.
void sgetri_(ref lapackint n, float *a, ref lapackint lda, lapackint *ipiv, float *work, ref lapackint lwork, ref lapackint info);
void dgetri_(ref lapackint n, double *a, ref lapackint lda, lapackint *ipiv, double *work, ref lapackint lwork, ref lapackint info);
void cgetri_(ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zgetri_(ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Solves a general system of linear equations AX=B, A**T X=B
/// or A**H X=B, using the LU factorization computed by SGETRF.
void sgetrs_(ref char trans, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, lapackint *ipiv, float *b, ref lapackint ldb, ref lapackint info);
void dgetrs_(ref char trans, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, lapackint *ipiv, double *b, ref lapackint ldb, ref lapackint info);
void cgetrs_(ref char trans, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zgetrs_(ref char trans, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Forms the right or left eigenvectors of the generalized eigenvalue
/// problem by backward transformation on the computed eigenvectors of
/// the balanced pair of matrices output by SGGBAL.
void sggbak_(ref char job, ref char side, ref lapackint n, lapackint *ilo, lapackint *ihi, float *lscale, float *rscale, ref lapackint m, float *v, ref lapackint ldv, ref lapackint info);
void dggbak_(ref char job, ref char side, ref lapackint n, lapackint *ilo, lapackint *ihi, double *lscale, double *rscale, ref lapackint m, double *v, ref lapackint ldv, ref lapackint info);
void cggbak_(ref char job, ref char side, ref lapackint n, lapackint *ilo, lapackint *ihi, float *lscale, float *rscale, ref lapackint m, _cfloat *v, ref lapackint ldv, ref lapackint info);
void zggbak_(ref char job, ref char side, ref lapackint n, lapackint *ilo, lapackint *ihi, double *lscale, double *rscale, ref lapackint m, _cdouble *v, ref lapackint ldv, ref lapackint info);

/// Balances a pair of general real matrices for the generalized
/// eigenvalue problem A x = lambda B x.
void sggbal_(ref char job, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, lapackint *ilo, lapackint *ihi, float *lscale, float *rscale, float *work, ref lapackint info);
void dggbal_(ref char job, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, lapackint *ilo, lapackint *ihi, double *lscale, double *rscale, double *work, ref lapackint info);
void cggbal_(ref char job, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, lapackint *ilo, lapackint *ihi, float *lscale, float *rscale, float *work, ref lapackint info);
void zggbal_(ref char job, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, lapackint *ilo, lapackint *ihi, double *lscale, double *rscale, double *work, ref lapackint info);

/// Reduces a pair of real matrices to generalized upper
/// Hessenberg form using orthogonal transformations 
void sgghrd_(ref char compq, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *q, ref lapackint ldq, float *z, ref lapackint ldz, ref lapackint info);
void dgghrd_(ref char compq, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *q, ref lapackint ldq, double *z, ref lapackint ldz, ref lapackint info);
void cgghrd_(ref char compq, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *q, ref lapackint ldq, _cfloat *z, ref lapackint ldz, ref lapackint info);
void zgghrd_(ref char compq, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *q, ref lapackint ldq, _cdouble *z, ref lapackint ldz, ref lapackint info);

/// Computes a generalized QR factorization of a pair of matrices. 
void sggqrf_(ref lapackint n, ref lapackint m, ref lapackint p, float *a, ref lapackint lda, float *taua, float *b, ref lapackint ldb, float *taub, float *work, ref lapackint lwork, ref lapackint info);
void dggqrf_(ref lapackint n, ref lapackint m, ref lapackint p, double *a, ref lapackint lda, double *taua, double *b, ref lapackint ldb, double *taub, double *work, ref lapackint lwork, ref lapackint info);
void cggqrf_(ref lapackint n, ref lapackint m, ref lapackint p, _cfloat *a, ref lapackint lda, _cfloat *taua, _cfloat *b, ref lapackint ldb, _cfloat *taub, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zggqrf_(ref lapackint n, ref lapackint m, ref lapackint p, _cdouble *a, ref lapackint lda, _cdouble *taua, _cdouble *b, ref lapackint ldb, _cdouble *taub, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Computes a generalized RQ factorization of a pair of matrices.
void sggrqf_(ref lapackint m, ref lapackint p, ref lapackint n, float *a, ref lapackint lda, float *taua, float *b, ref lapackint ldb, float *taub, float *work, ref lapackint lwork, ref lapackint info);
void dggrqf_(ref lapackint m, ref lapackint p, ref lapackint n, double *a, ref lapackint lda, double *taua, double *b, ref lapackint ldb, double *taub, double *work, ref lapackint lwork, ref lapackint info);
void cggrqf_(ref lapackint m, ref lapackint p, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *taua, _cfloat *b, ref lapackint ldb, _cfloat *taub, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zggrqf_(ref lapackint m, ref lapackint p, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *taua, _cdouble *b, ref lapackint ldb, _cdouble *taub, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Computes orthogonal matrices as a preprocessing step
/// for computing the generalized singular value decomposition
void sggsvp_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint p, ref lapackint n, float *a, float *b, ref lapackint ldb, float *tola, float *tolb, ref lapackint k, ref lapackint ldu, float *v, ref lapackint ldv, float *q, ref lapackint ldq, lapackint *iwork, float *tau, float *work, ref lapackint info);
void dggsvp_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint p, ref lapackint n, double *a, double *b, ref lapackint ldb, double *tola, double *tolb, ref lapackint k, ref lapackint ldu, double *v, ref lapackint ldv, double *q, ref lapackint ldq, lapackint *iwork, double *tau, double *work, ref lapackint info);
void cggsvp_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint p, ref lapackint n, _cfloat *a, _cfloat *b, ref lapackint ldb, float *tola, float *tolb, ref lapackint k, ref lapackint ldu, _cfloat *v, ref lapackint ldv, _cfloat *q, ref lapackint ldq, lapackint *iwork, float *rwork, _cfloat *tau, _cfloat *work, ref lapackint info);
void zggsvp_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint p, ref lapackint n, _cdouble *a, _cdouble *b, ref lapackint ldb, double *tola, double *tolb, ref lapackint k, ref lapackint ldu, _cdouble *v, ref lapackint ldv, _cdouble *q, ref lapackint ldq, lapackint *iwork, double *rwork, _cdouble *tau, _cdouble *work, ref lapackint info);

/// Estimates the reciprocal of the condition number of a general
/// tridiagonal matrix, in either the 1-norm or the infinity-norm,
/// using the LU factorization computed by SGTTRF.
void sgtcon_(ref char norm, ref lapackint n, float *dl, float *d, float *du, float *du2, lapackint *ipiv, float *anorm, ref float rcond, float *work, lapackint *iwork, ref lapackint info);
void dgtcon_(ref char norm, ref lapackint n, double *dl, double *d, double *du, double *du2, lapackint *ipiv, double *anorm, ref double rcond, double *work, lapackint *iwork, ref lapackint info);
void cgtcon_(ref char norm, ref lapackint n, _cfloat *dl, _cfloat *d, _cfloat *du, _cfloat *du2, lapackint *ipiv, float *anorm, ref float rcond, _cfloat *work, ref lapackint info);
void zgtcon_(ref char norm, ref lapackint n, _cdouble *dl, _cdouble *d, _cdouble *du, _cdouble *du2, lapackint *ipiv, double *anorm, ref double rcond, _cdouble *work, ref lapackint info);

/// Improves the computed solution to a general tridiagonal system
/// of linear equations AX=B, A**T X=B or A**H X=B, and provides
/// forward and backward error bounds for the solution.
void sgtrfs_(ref char trans, ref lapackint n, ref lapackint nrhs, float *dl, float *d, float *du, float *dlf, float *df, float *duf, float *du2, lapackint *ipiv, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dgtrfs_(ref char trans, ref lapackint n, ref lapackint nrhs, double *dl, double *d, double *du, double *dlf, double *df, double *duf, double *du2, lapackint *ipiv, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cgtrfs_(ref char trans, ref lapackint n, ref lapackint nrhs, _cfloat *dl, _cfloat *d, _cfloat *du, _cfloat *dlf, _cfloat *df, _cfloat *duf, _cfloat *du2, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zgtrfs_(ref char trans, ref lapackint n, ref lapackint nrhs, _cdouble *dl, _cdouble *d, _cdouble *du, _cdouble *dlf, _cdouble *df, _cdouble *duf, _cdouble *du2, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Computes an LU factorization of a general tridiagonal matrix,
/// using partial pivoting with row interchanges.
void sgttrf_(ref lapackint n, float *dl, float *d, float *du, float *du2, lapackint *ipiv, ref lapackint info);
void dgttrf_(ref lapackint n, double *dl, double *d, double *du, double *du2, lapackint *ipiv, ref lapackint info);
void cgttrf_(ref lapackint n, _cfloat *dl, _cfloat *d, _cfloat *du, _cfloat *du2, lapackint *ipiv, ref lapackint info);
void zgttrf_(ref lapackint n, _cdouble *dl, _cdouble *d, _cdouble *du, _cdouble *du2, lapackint *ipiv, ref lapackint info);

/// Solves a general tridiagonal system of linear equations AX=B,
/// A**T X=B or A**H X=B, using the LU factorization computed by
/// SGTTRF.
void sgttrs_(ref char trans, ref lapackint n, ref lapackint nrhs, float *dl, float *d, float *du, float *du2, lapackint *ipiv, float *b, ref lapackint ldb, ref lapackint info);
void dgttrs_(ref char trans, ref lapackint n, ref lapackint nrhs, double *dl, double *d, double *du, double *du2, lapackint *ipiv, double *b, ref lapackint ldb, ref lapackint info);
void cgttrs_(ref char trans, ref lapackint n, ref lapackint nrhs, _cfloat *dl, _cfloat *d, _cfloat *du, _cfloat *du2, lapackint *ipiv, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zgttrs_(ref char trans, ref lapackint n, ref lapackint nrhs, _cdouble *dl, _cdouble *d, _cdouble *du, _cdouble *du2, lapackint *ipiv, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Implements a single-/double-shift version of the QZ method for
/// finding the generalized eigenvalues of the equation 
/// det(A - w(i) B) = 0
void shgeqz_(ref char job, ref char compq, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *alphar, float *alphai, float *betav, float *q, ref lapackint ldq, float *z, ref lapackint ldz, float *work, ref lapackint lwork, ref lapackint info);
void dhgeqz_(ref char job, ref char compq, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *alphar, double *alphai, double *betav, double *q, ref lapackint ldq, double *z, ref lapackint ldz, double *work, ref lapackint lwork, ref lapackint info);
void chgeqz_(ref char job, ref char compq, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *alphav, _cfloat *betav, _cfloat *q, ref lapackint ldq, _cfloat *z, ref lapackint ldz, _cfloat *work, ref lapackint lwork, float *rwork, ref lapackint info);
void zhgeqz_(ref char job, ref char compq, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *alphav, _cdouble *betav, _cdouble *q, ref lapackint ldq, _cdouble *z, ref lapackint ldz, _cdouble *work, ref lapackint lwork, double *rwork, ref lapackint info);

/// Computes specified right and/or left eigenvectors of an upper
/// Hessenberg matrix by inverse iteration.
void shsein_(ref char side, ref char eigsrc, ref char initv, lapackint *select, ref lapackint n, float *h, ref lapackint ldh, float *wr, float *wi, float *vl, ref lapackint ldvl, float *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, float *work, lapackint *ifaill, lapackint *ifailr, ref lapackint info);
void dhsein_(ref char side, ref char eigsrc, ref char initv, lapackint *select, ref lapackint n, double *h, ref lapackint ldh, double *wr, double *wi, double *vl, ref lapackint ldvl, double *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, double *work, lapackint *ifaill, lapackint *ifailr, ref lapackint info);
void chsein_(ref char side, ref char eigsrc, ref char initv, lapackint *select, ref lapackint n, _cfloat *h, ref lapackint ldh, _cfloat *w, _cfloat *vl, ref lapackint ldvl, _cfloat *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, _cfloat *work, float *rwork, lapackint *ifaill, lapackint *ifailr, ref lapackint info);
void zhsein_(ref char side, ref char eigsrc, ref char initv, lapackint *select, ref lapackint n, _cdouble *h, ref lapackint ldh, _cdouble *w, _cdouble *vl, ref lapackint ldvl, _cdouble *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, _cdouble *work, double *rwork, lapackint *ifaill, lapackint *ifailr, ref lapackint info);

/// Computes the eigenvalues and Schur factorization of an upper
/// Hessenberg matrix, using the multishift QR algorithm.
void shseqr_(ref char job, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, float *h, ref lapackint ldh, float *wr, float *wi, float *z, ref lapackint ldz, float *work, ref lapackint lwork, ref lapackint info);
void dhseqr_(ref char job, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, double *h, ref lapackint ldh, double *wr, double *wi, double *z, ref lapackint ldz, double *work, ref lapackint lwork, ref lapackint info);
void chseqr_(ref char job, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, _cfloat *h, ref lapackint ldh, _cfloat *w, _cfloat *z, ref lapackint ldz, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zhseqr_(ref char job, ref char compz, ref lapackint n, lapackint *ilo, lapackint *ihi, _cdouble *h, ref lapackint ldh, _cdouble *w, _cdouble *z, ref lapackint ldz, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Generates the orthogonal transformation matrix from
/// a reduction to tridiagonal form determined by SSPTRD.
void sopgtr_(ref char uplo, ref lapackint n, float *ap, float *tau, float *q, ref lapackint ldq, float *work, ref lapackint info);
void dopgtr_(ref char uplo, ref lapackint n, double *ap, double *tau, double *q, ref lapackint ldq, double *work, ref lapackint info);

/// Generates the unitary transformation matrix from
/// a reduction to tridiagonal form determined by CHPTRD.
void cupgtr_(ref char uplo, ref lapackint n, _cfloat *ap, _cfloat *tau, _cfloat *q, ref lapackint ldq, _cfloat *work, ref lapackint info);
void zupgtr_(ref char uplo, ref lapackint n, _cdouble *ap, _cdouble *tau, _cdouble *q, ref lapackint ldq, _cdouble *work, ref lapackint info);


/// Multiplies a general matrix by the orthogonal
/// transformation matrix from a reduction to tridiagonal form
/// determined by SSPTRD.
void sopmtr_(ref char side, ref char uplo, ref char trans, ref lapackint m, ref lapackint n, float *ap, float *tau, float *c, ref lapackint ldc, float *work, ref lapackint info);
void dopmtr_(ref char side, ref char uplo, ref char trans, ref lapackint m, ref lapackint n, double *ap, double *tau, double *c, ref lapackint ldc, double *work, ref lapackint info);

/// Generates the orthogonal transformation matrices from
/// a reduction to bidiagonal form determined by SGEBRD.
void sorgbr_(ref char vect, ref lapackint m, ref lapackint n, ref lapackint k, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dorgbr_(ref char vect, ref lapackint m, ref lapackint n, ref lapackint k, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);

/// Generates the unitary transformation matrices from
/// a reduction to bidiagonal form determined by CGEBRD.
void cungbr_(ref char vect, ref lapackint m, ref lapackint n, ref lapackint k, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zungbr_(ref char vect, ref lapackint m, ref lapackint n, ref lapackint k, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Generates the orthogonal transformation matrix from
/// a reduction to Hessenberg form determined by SGEHRD.
void sorghr_(ref lapackint n, lapackint *ilo, lapackint *ihi, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dorghr_(ref lapackint n, lapackint *ilo, lapackint *ihi, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);

/// Generates the unitary transformation matrix from
/// a reduction to Hessenberg form determined by CGEHRD.
void cunghr_(ref lapackint n, lapackint *ilo, lapackint *ihi, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zunghr_(ref lapackint n, lapackint *ilo, lapackint *ihi, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Generates all or part of the orthogonal matrix Q from
/// an LQ factorization determined by SGELQF.
void sorglq_(ref lapackint m, ref lapackint n, ref lapackint k, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dorglq_(ref lapackint m, ref lapackint n, ref lapackint k, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);

/// Generates all or part of the unitary matrix Q from
/// an LQ factorization determined by CGELQF.
void cunglq_(ref lapackint m, ref lapackint n, ref lapackint k, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zunglq_(ref lapackint m, ref lapackint n, ref lapackint k, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Generates all or part of the orthogonal matrix Q from
/// a QL factorization determined by SGEQLF.
void sorgql_(ref lapackint m, ref lapackint n, ref lapackint k, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dorgql_(ref lapackint m, ref lapackint n, ref lapackint k, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);

/// Generates all or part of the unitary matrix Q from
/// a QL factorization determined by CGEQLF.
void cungql_(ref lapackint m, ref lapackint n, ref lapackint k, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zungql_(ref lapackint m, ref lapackint n, ref lapackint k, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Generates all or part of the orthogonal matrix Q from
/// a QR factorization determined by SGEQRF.
void sorgqr_(ref lapackint m, ref lapackint n, ref lapackint k, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dorgqr_(ref lapackint m, ref lapackint n, ref lapackint k, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);

/// Generates all or part of the unitary matrix Q from
/// a QR factorization determined by CGEQRF.
void cungqr_(ref lapackint m, ref lapackint n, ref lapackint k, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zungqr_(ref lapackint m, ref lapackint n, ref lapackint k, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Generates all or part of the orthogonal matrix Q from
/// an RQ factorization determined by SGERQF.
void sorgrq_(ref lapackint m, ref lapackint n, ref lapackint k, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dorgrq_(ref lapackint m, ref lapackint n, ref lapackint k, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);

/// Generates all or part of the unitary matrix Q from
/// an RQ factorization determined by CGERQF.
void cungrq_(ref lapackint m, ref lapackint n, ref lapackint k, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zungrq_(ref lapackint m, ref lapackint n, ref lapackint k, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Generates the orthogonal transformation matrix from
/// a reduction to tridiagonal form determined by SSYTRD.
void sorgtr_(ref char uplo, ref lapackint n, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dorgtr_(ref char uplo, ref lapackint n, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);

/// Generates the unitary transformation matrix from
/// a reduction to tridiagonal form determined by CHETRD.
void cungtr_(ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zungtr_(ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by one of the orthogonal
/// transformation  matrices from a reduction to bidiagonal form
/// determined by SGEBRD.
void sormbr_(ref char vect, ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, float *a, ref lapackint lda, float *tau, float *c, ref lapackint ldc, float *work, ref lapackint lwork, ref lapackint info);
void dormbr_(ref char vect, ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, double *a, ref lapackint lda, double *tau, double *c, ref lapackint ldc, double *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by one of the unitary
/// transformation matrices from a reduction to bidiagonal form
/// determined by CGEBRD.
void cunmbr_(ref char vect, ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *c, ref lapackint ldc, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zunmbr_(ref char vect, ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *c, ref lapackint ldc, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by the orthogonal transformation
/// matrix from a reduction to Hessenberg form determined by SGEHRD.
void sormhr_(ref char side, ref char trans, ref lapackint m, ref lapackint n, lapackint *ilo, lapackint *ihi, float *a, ref lapackint lda, float *tau, float *c, ref lapackint ldc, float *work, ref lapackint lwork, ref lapackint info);
void dormhr_(ref char side, ref char trans, ref lapackint m, ref lapackint n, lapackint *ilo, lapackint *ihi, double *a, ref lapackint lda, double *tau, double *c, ref lapackint ldc, double *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by the unitary transformation
/// matrix from a reduction to Hessenberg form determined by CGEHRD.
void cunmhr_(ref char side, ref char trans, ref lapackint m, ref lapackint n, lapackint *ilo, lapackint *ihi, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *c, ref lapackint ldc, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zunmhr_(ref char side, ref char trans, ref lapackint m, ref lapackint n, lapackint *ilo, lapackint *ihi, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *c, ref lapackint ldc, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by the orthogonal matrix
/// from an LQ factorization determined by SGELQF.
void sormlq_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, float *a, ref lapackint lda, float *tau, float *c, ref lapackint ldc, float *work, ref lapackint lwork, ref lapackint info);
void dormlq_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, double *a, ref lapackint lda, double *tau, double *c, ref lapackint ldc, double *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by the unitary matrix
/// from an LQ factorization determined by CGELQF.
void cunmlq_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *c, ref lapackint ldc, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zunmlq_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *c, ref lapackint ldc, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by the orthogonal matrix
/// from a QL factorization determined by SGEQLF.
void sormql_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, float *a, ref lapackint lda, float *tau, float *c, ref lapackint ldc, float *work, ref lapackint lwork, ref lapackint info);
void dormql_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, double *a, ref lapackint lda, double *tau, double *c, ref lapackint ldc, double *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by the unitary matrix
/// from a QL factorization determined by CGEQLF.
void cunmql_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *c, ref lapackint ldc, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zunmql_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *c, ref lapackint ldc, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by the orthogonal matrix
/// from a QR factorization determined by SGEQRF.
void sormqr_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, float *a, ref lapackint lda, float *tau, float *c, ref lapackint ldc, float *work, ref lapackint lwork, ref lapackint info);
void dormqr_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, double *a, ref lapackint lda, double *tau, double *c, ref lapackint ldc, double *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by the unitary matrix
/// from a QR factorization determined by CGEQRF.
void cunmqr_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *c, ref lapackint ldc, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zunmqr_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *c, ref lapackint ldc, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Multiples a general matrix by the orthogonal matrix
/// from an RZ factorization determined by STZRZF.
void sormr3_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, lapackint *a, ref lapackint lda, float *tau, float *c, ref lapackint ldc, float *work, ref lapackint info);
void dormr3_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, lapackint *a, ref lapackint lda, double *tau, double *c, ref lapackint ldc, double *work, ref lapackint info);

/// Multiples a general matrix by the unitary matrix
/// from an RZ factorization determined by CTZRZF.
void cunmr3_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, lapackint *a, ref lapackint lda, _cfloat *tau, _cfloat *c, ref lapackint ldc, _cfloat *work, ref lapackint info);
void zunmr3_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, lapackint *a, ref lapackint lda, _cdouble *tau, _cdouble *c, ref lapackint ldc, _cdouble *work, ref lapackint info);

/// Multiplies a general matrix by the orthogonal matrix
/// from an RQ factorization determined by SGERQF.
void sormrq_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, float *a, ref lapackint lda, float *tau, float *c, ref lapackint ldc, float *work, ref lapackint lwork, ref lapackint info);
void dormrq_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, double *a, ref lapackint lda, double *tau, double *c, ref lapackint ldc, double *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by the unitary matrix
/// from an RQ factorization determined by CGERQF.
void cunmrq_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *c, ref lapackint ldc, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zunmrq_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *c, ref lapackint ldc, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Multiples a general matrix by the orthogonal matrix
/// from an RZ factorization determined by STZRZF.
void sormrz_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, lapackint *a, ref lapackint lda, float *tau, float *c, ref lapackint ldc, float *work, ref lapackint lwork, ref lapackint info);
void dormrz_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, lapackint *a, ref lapackint lda, double *tau, double *c, ref lapackint ldc, double *work, ref lapackint lwork, ref lapackint info);

/// Multiples a general matrix by the unitary matrix
/// from an RZ factorization determined by CTZRZF.
void cunmrz_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, lapackint *a, ref lapackint lda, _cfloat *tau, _cfloat *c, ref lapackint ldc, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zunmrz_(ref char side, ref char trans, ref lapackint m, ref lapackint n, ref lapackint k, lapackint *a, ref lapackint lda, _cdouble *tau, _cdouble *c, ref lapackint ldc, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by the orthogonal
/// transformation matrix from a reduction to tridiagonal form
/// determined by SSYTRD.
void sormtr_(ref char side, ref char uplo, ref char trans, ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *tau, float *c, ref lapackint ldc, float *work, ref lapackint lwork, ref lapackint info);
void dormtr_(ref char side, ref char uplo, ref char trans, ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *tau, double *c, ref lapackint ldc, double *work, ref lapackint lwork, ref lapackint info);

/// Multiplies a general matrix by the unitary
/// transformation matrix from a reduction to tridiagonal form
/// determined by CHETRD.
void cunmtr_(ref char side, ref char uplo, ref char trans, ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *c, ref lapackint ldc, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zunmtr_(ref char side, ref char uplo, ref char trans, ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *c, ref lapackint ldc, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Estimates the reciprocal of the condition number of a
/// symmetric positive definite band matrix, using the
/// Cholesky factorization computed by SPBTRF.
void spbcon_(ref char uplo, ref lapackint n, lapackint *kd, float *ab, ref lapackint ldab, float *anorm, ref float rcond, float *work, lapackint *iwork, ref lapackint info);
void dpbcon_(ref char uplo, ref lapackint n, lapackint *kd, double *ab, ref lapackint ldab, double *anorm, ref double rcond, double *work, lapackint *iwork, ref lapackint info);
void cpbcon_(ref char uplo, ref lapackint n, lapackint *kd, _cfloat *ab, ref lapackint ldab, float *anorm, ref float rcond, _cfloat *work, float *rwork, ref lapackint info);
void zpbcon_(ref char uplo, ref lapackint n, lapackint *kd, _cdouble *ab, ref lapackint ldab, double *anorm, ref double rcond, _cdouble *work, double *rwork, ref lapackint info);

/// Computes row and column scalings to equilibrate a symmetric
/// positive definite band matrix and reduce its condition number.
void spbequ_(ref char uplo, ref lapackint n, lapackint *kd, float *ab, ref lapackint ldab, float *s, float *scond, float *amax, ref lapackint info);
void dpbequ_(ref char uplo, ref lapackint n, lapackint *kd, double *ab, ref lapackint ldab, double *s, double *scond, double *amax, ref lapackint info);
void cpbequ_(ref char uplo, ref lapackint n, lapackint *kd, _cfloat *ab, ref lapackint ldab, float *s, float *scond, float *amax, ref lapackint info);
void zpbequ_(ref char uplo, ref lapackint n, lapackint *kd, _cdouble *ab, ref lapackint ldab, double *s, double *scond, double *amax, ref lapackint info);

/// Improves the computed solution to a symmetric positive
/// definite banded system of linear equations AX=B, and provides
/// forward and backward error bounds for the solution.
void spbrfs_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, float *ab, ref lapackint ldab, float *afb, ref lapackint ldafb, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dpbrfs_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, double *ab, ref lapackint ldab, double *afb, ref lapackint ldafb, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cpbrfs_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cfloat *ab, ref lapackint ldab, _cfloat *afb, ref lapackint ldafb, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zpbrfs_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cdouble *ab, ref lapackint ldab, _cdouble *afb, ref lapackint ldafb, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Computes a split Cholesky factorization of a real symmetric positive
/// definite band matrix.
void spbstf_(ref char uplo, ref lapackint n, lapackint *kd, float *ab, ref lapackint ldab, ref lapackint info);
void dpbstf_(ref char uplo, ref lapackint n, lapackint *kd, double *ab, ref lapackint ldab, ref lapackint info);
void cpbstf_(ref char uplo, ref lapackint n, lapackint *kd, _cfloat *ab, ref lapackint ldab, ref lapackint info);
void zpbstf_(ref char uplo, ref lapackint n, lapackint *kd, _cdouble *ab, ref lapackint ldab, ref lapackint info);

/// Computes the Cholesky factorization of a symmetric
/// positive definite band matrix.
void spbtrf_(ref char uplo, ref lapackint n, lapackint *kd, float *ab, ref lapackint ldab, ref lapackint info);
void dpbtrf_(ref char uplo, ref lapackint n, lapackint *kd, double *ab, ref lapackint ldab, ref lapackint info);
void cpbtrf_(ref char uplo, ref lapackint n, lapackint *kd, _cfloat *ab, ref lapackint ldab, ref lapackint info);
void zpbtrf_(ref char uplo, ref lapackint n, lapackint *kd, _cdouble *ab, ref lapackint ldab, ref lapackint info);

/// Solves a symmetric positive definite banded system
/// of linear equations AX=B, using the Cholesky factorization
/// computed by SPBTRF.
void spbtrs_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, float *ab, ref lapackint ldab, float *b, ref lapackint ldb, ref lapackint info);
void dpbtrs_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, double *ab, ref lapackint ldab, double *b, ref lapackint ldb, ref lapackint info);
void cpbtrs_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cfloat *ab, ref lapackint ldab, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zpbtrs_(ref char uplo, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cdouble *ab, ref lapackint ldab, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Estimates the reciprocal of the condition number of a
/// symmetric positive definite matrix, using the
/// Cholesky factorization computed by SPOTRF.
void spocon_(ref char uplo, ref lapackint n, float *a, ref lapackint lda, float *anorm, ref float rcond, float *work, lapackint *iwork, ref lapackint info);
void dpocon_(ref char uplo, ref lapackint n, double *a, ref lapackint lda, double *anorm, ref double rcond, double *work, lapackint *iwork, ref lapackint info);
void cpocon_(ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, float *anorm, ref float rcond, _cfloat *work, float *rwork, ref lapackint info);
void zpocon_(ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, double *anorm, ref double rcond, _cdouble *work, double *rwork, ref lapackint info);

/// Computes row and column scalings to equilibrate a symmetric
/// positive definite matrix and reduce its condition number.
void spoequ_(ref lapackint n, float *a, ref lapackint lda, float *s, float *scond, float *amax, ref lapackint info);
void dpoequ_(ref lapackint n, double *a, ref lapackint lda, double *s, double *scond, double *amax, ref lapackint info);
void cpoequ_(ref lapackint n, _cfloat *a, ref lapackint lda, float *s, float *scond, float *amax, ref lapackint info);
void zpoequ_(ref lapackint n, _cdouble *a, ref lapackint lda, double *s, double *scond, double *amax, ref lapackint info);

/// Improves the computed solution to a symmetric positive
/// definite system of linear equations AX=B, and provides forward
/// and backward error bounds for the solution.
void sporfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *af, ref lapackint ldaf, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dporfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *af, ref lapackint ldaf, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cporfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *af, ref lapackint ldaf, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zporfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *af, ref lapackint ldaf, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Computes the Cholesky factorization of a symmetric
/// positive definite matrix.
void spotrf_(ref char uplo, ref lapackint n, float *a, ref lapackint lda, ref lapackint info);
void dpotrf_(ref char uplo, ref lapackint n, double *a, ref lapackint lda, ref lapackint info);
void cpotrf_(ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, ref lapackint info);
void zpotrf_(ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, ref lapackint info);

/// Computes the inverse of a symmetric positive definite
/// matrix, using the Cholesky factorization computed by SPOTRF.
void spotri_(ref char uplo, ref lapackint n, float *a, ref lapackint lda, ref lapackint info);
void dpotri_(ref char uplo, ref lapackint n, double *a, ref lapackint lda, ref lapackint info);
void cpotri_(ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, ref lapackint info);
void zpotri_(ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, ref lapackint info);

/// Solves a symmetric positive definite system of linear
/// equations AX=B, using the Cholesky factorization computed by
/// SPOTRF.
void spotrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *b, ref lapackint ldb, ref lapackint info);
void dpotrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *b, ref lapackint ldb, ref lapackint info);
void cpotrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zpotrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Estimates the reciprocal of the condition number of a
/// symmetric positive definite matrix in packed storage,
/// using the Cholesky factorization computed by SPPTRF.
void sppcon_(ref char uplo, ref lapackint n, float *ap, float *anorm, ref float rcond, float *work, lapackint *iwork, ref lapackint info);
void dppcon_(ref char uplo, ref lapackint n, double *ap, double *anorm, ref double rcond, double *work, lapackint *iwork, ref lapackint info);
void cppcon_(ref char uplo, ref lapackint n, _cfloat *ap, float *anorm, ref float rcond, _cfloat *work, float *rwork, ref lapackint info);
void zppcon_(ref char uplo, ref lapackint n, _cdouble *ap, double *anorm, ref double rcond, _cdouble *work, double *rwork, ref lapackint info);

/// Computes row and column scalings to equilibrate a symmetric
/// positive definite matrix in packed storage and reduce its condition
/// number.
void sppequ_(ref char uplo, ref lapackint n, float *ap, float *s, float *scond, float *amax, ref lapackint info);
void dppequ_(ref char uplo, ref lapackint n, double *ap, double *s, double *scond, double *amax, ref lapackint info);
void cppequ_(ref char uplo, ref lapackint n, _cfloat *ap, float *s, float *scond, float *amax, ref lapackint info);
void zppequ_(ref char uplo, ref lapackint n, _cdouble *ap, double *s, double *scond, double *amax, ref lapackint info);

/// Improves the computed solution to a symmetric positive
/// definite system of linear equations AX=B, where A is held in
/// packed storage, and provides forward and backward error bounds
/// for the solution.
void spprfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *ap, float *afp, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dpprfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *ap, double *afp, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void cpprfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, _cfloat *afp, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zpprfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, _cdouble *afp, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Computes the Cholesky factorization of a symmetric
/// positive definite matrix in packed storage.
void spptrf_(ref char uplo, ref lapackint n, float *ap, ref lapackint info);
void dpptrf_(ref char uplo, ref lapackint n, double *ap, ref lapackint info);
void cpptrf_(ref char uplo, ref lapackint n, _cfloat *ap, ref lapackint info);
void zpptrf_(ref char uplo, ref lapackint n, _cdouble *ap, ref lapackint info);

/// Computes the inverse of a symmetric positive definite
/// matrix in packed storage, using the Cholesky factorization computed
/// by SPPTRF.
void spptri_(ref char uplo, ref lapackint n, float *ap, ref lapackint info);
void dpptri_(ref char uplo, ref lapackint n, double *ap, ref lapackint info);
void cpptri_(ref char uplo, ref lapackint n, _cfloat *ap, ref lapackint info);
void zpptri_(ref char uplo, ref lapackint n, _cdouble *ap, ref lapackint info);

/// Solves a symmetric positive definite system of linear
/// equations AX=B, where A is held in packed storage, using the
/// Cholesky factorization computed by SPPTRF.
void spptrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *ap, float *b, ref lapackint ldb, ref lapackint info);
void dpptrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *ap, double *b, ref lapackint ldb, ref lapackint info);
void cpptrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zpptrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Computes the reciprocal of the condition number of a
/// symmetric positive definite tridiagonal matrix,
/// using the LDL**H factorization computed by SPTTRF.
void sptcon_(ref lapackint n, float *d, float *e, float *anorm, ref float rcond, float *work, ref lapackint info);
void dptcon_(ref lapackint n, double *d, double *e, double *anorm, ref double rcond, double *work, ref lapackint info);
void cptcon_(ref lapackint n, float *d, _cfloat *e, float *anorm, ref float rcond, float *rwork, ref lapackint info);
void zptcon_(ref lapackint n, double *d, _cdouble *e, double *anorm, ref double rcond, double *rwork, ref lapackint info);

/// Computes all eigenvalues and eigenvectors of a real symmetric
/// positive definite tridiagonal matrix, by computing the SVD of
/// its bidiagonal Cholesky factor.
void spteqr_(ref char compz, ref lapackint n, float *d, float *e, float *z, ref lapackint ldz, float *work, ref lapackint info);
void dpteqr_(ref char compz, ref lapackint n, double *d, double *e, double *z, ref lapackint ldz, double *work, ref lapackint info);
void cpteqr_(ref char compz, ref lapackint n, float *d, float *e, _cfloat *z, ref lapackint ldz, float *work, ref lapackint info);
void zpteqr_(ref char compz, ref lapackint n, double *d, double *e, _cdouble *z, ref lapackint ldz, double *work, ref lapackint info);

/// Improves the computed solution to a symmetric positive
/// definite tridiagonal system of linear equations AX=B, and provides
/// forward and backward error bounds for the solution.
void sptrfs_(ref lapackint n, ref lapackint nrhs, float *d, float *e, float *df, float *ef, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, ref lapackint info);
void dptrfs_(ref lapackint n, ref lapackint nrhs, double *d, double *e, double *df, double *ef, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, ref lapackint info);
void cptrfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *d, _cfloat *e, float *df, _cfloat *ef, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zptrfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *d, _cdouble *e, double *df, _cdouble *ef, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Computes the LDL**H factorization of a symmetric
/// positive definite tridiagonal matrix.
void spttrf_(ref lapackint n, float *d, float *e, ref lapackint info);
void dpttrf_(ref lapackint n, double *d, double *e, ref lapackint info);
void cpttrf_(ref lapackint n, float *d, _cfloat *e, ref lapackint info);
void zpttrf_(ref lapackint n, double *d, _cdouble *e, ref lapackint info);

/// Solves a symmetric positive definite tridiagonal
/// system of linear equations, using the LDL**H factorization
/// computed by SPTTRF.
void spttrs_(ref lapackint n, ref lapackint nrhs, float *d, float *e, float *b, ref lapackint ldb, ref lapackint info);
void dpttrs_(ref lapackint n, ref lapackint nrhs, double *d, double *e, double *b, ref lapackint ldb, ref lapackint info);
void cpttrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *d, _cfloat *e, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zpttrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *d, _cdouble *e, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Reduces a real symmetric-definite banded generalized eigenproblem
/// A x = lambda B x to standard form, where B has been factorized by
/// SPBSTF (Crawford's algorithm).
void ssbgst_(ref char vect, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, float *ab, ref lapackint ldab, float *bb, ref lapackint ldbb, float *x, ref lapackint ldx, float *work, ref lapackint info);
void dsbgst_(ref char vect, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, double *ab, ref lapackint ldab, double *bb, ref lapackint ldbb, double *x, ref lapackint ldx, double *work, ref lapackint info);

/// Reduces a complex Hermitian-definite banded generalized eigenproblem
/// A x = lambda B x to standard form, where B has been factorized by
/// CPBSTF (Crawford's algorithm).
void chbgst_(ref char vect, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, _cfloat *ab, ref lapackint ldab, _cfloat *bb, ref lapackint ldbb, _cfloat *x, ref lapackint ldx, _cfloat *work, float *rwork, ref lapackint info);
void zhbgst_(ref char vect, ref char uplo, ref lapackint n, lapackint *ka, lapackint *kb, _cdouble *ab, ref lapackint ldab, _cdouble *bb, ref lapackint ldbb, _cdouble *x, ref lapackint ldx, _cdouble *work, double *rwork, ref lapackint info);

/// Reduces a symmetric band matrix to real symmetric
/// tridiagonal form by an orthogonal similarity transformation.
void ssbtrd_(ref char vect, ref char uplo, ref lapackint n, lapackint *kd, float *ab, ref lapackint ldab, float *d, float *e, float *q, ref lapackint ldq, float *work, ref lapackint info);
void dsbtrd_(ref char vect, ref char uplo, ref lapackint n, lapackint *kd, double *ab, ref lapackint ldab, double *d, double *e, double *q, ref lapackint ldq, double *work, ref lapackint info);

/// Reduces a Hermitian band matrix to real symmetric
/// tridiagonal form by a unitary similarity transformation.
void chbtrd_(ref char vect, ref char uplo, ref lapackint n, lapackint *kd, _cfloat *ab, ref lapackint ldab, float *d, float *e, _cfloat *q, ref lapackint ldq, _cfloat *work, ref lapackint info);
void zhbtrd_(ref char vect, ref char uplo, ref lapackint n, lapackint *kd, _cdouble *ab, ref lapackint ldab, double *d, double *e, _cdouble *q, ref lapackint ldq, _cdouble *work, ref lapackint info);

/// Estimates the reciprocal of the condition number of a
/// real symmetric indefinite
/// matrix in packed storage, using the factorization computed
/// by SSPTRF.
void sspcon_(ref char uplo, ref lapackint n, float *ap, lapackint *ipiv, float *anorm, ref float rcond, float *work, lapackint *iwork, ref lapackint info);
void dspcon_(ref char uplo, ref lapackint n, double *ap, lapackint *ipiv, double *anorm, ref double rcond, double *work, lapackint *iwork, ref lapackint info);
void cspcon_(ref char uplo, ref lapackint n, _cfloat *ap, lapackint *ipiv, float *anorm, ref float rcond, _cfloat *work, ref lapackint info);
void zspcon_(ref char uplo, ref lapackint n, _cdouble *ap, lapackint *ipiv, double *anorm, ref double rcond, _cdouble *work, ref lapackint info);

/// Estimates the reciprocal of the condition number of a
/// complex Hermitian indefinite
/// matrix in packed storage, using the factorization computed
/// by CHPTRF.
void chpcon_(ref char uplo, ref lapackint n, _cfloat *ap, lapackint *ipiv, float *anorm, ref float rcond, _cfloat *work, ref lapackint info);
void zhpcon_(ref char uplo, ref lapackint n, _cdouble *ap, lapackint *ipiv, double *anorm, ref double rcond, _cdouble *work, ref lapackint info);

/// Reduces a symmetric-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form,  where A and B are held in packed storage, and B has been
/// factorized by SPPTRF.
void sspgst_(lapackint *itype, ref char uplo, ref lapackint n, float *ap, float *bp, ref lapackint info);
void dspgst_(lapackint *itype, ref char uplo, ref lapackint n, double *ap, double *bp, ref lapackint info);

/// Reduces a Hermitian-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form,  where A and B are held in packed storage, and B has been
/// factorized by CPPTRF.
void chpgst_(lapackint *itype, ref char uplo, ref lapackint n, _cfloat *ap, _cfloat *bp, ref lapackint info);
void zhpgst_(lapackint *itype, ref char uplo, ref lapackint n, _cdouble *ap, _cdouble *bp, ref lapackint info);

/// Improves the computed solution to a real
/// symmetric indefinite system of linear equations
/// AX=B, where A is held in packed storage, and provides forward
/// and backward error bounds for the solution.
void ssprfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *ap, float *afp, lapackint *ipiv, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dsprfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *ap, double *afp, lapackint *ipiv, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void csprfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, _cfloat *afp, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zsprfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, _cdouble *afp, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Improves the computed solution to a complex
/// Hermitian indefinite system of linear equations
/// AX=B, where A is held in packed storage, and provides forward
/// and backward error bounds for the solution.
void chprfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, _cfloat *afp, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zhprfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, _cdouble *afp, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Reduces a symmetric matrix in packed storage to real
/// symmetric tridiagonal form by an orthogonal similarity
/// transformation.
void ssptrd_(ref char uplo, ref lapackint n, float *ap, float *d, float *e, float *tau, ref lapackint info);
void dsptrd_(ref char uplo, ref lapackint n, double *ap, double *d, double *e, double *tau, ref lapackint info);

/// Reduces a Hermitian matrix in packed storage to real
/// symmetric tridiagonal form by a unitary similarity
/// transformation.
void chptrd_(ref char uplo, ref lapackint n, _cfloat *ap, float *d, float *e, _cfloat *tau, ref lapackint info);
void zhptrd_(ref char uplo, ref lapackint n, _cdouble *ap, double *d, double *e, _cdouble *tau, ref lapackint info);

/// Computes the factorization of a real
/// symmetric-indefinite matrix in packed storage,
/// using the diagonal pivoting method.
void ssptrf_(ref char uplo, ref lapackint n, float *ap, lapackint *ipiv, ref lapackint info);
void dsptrf_(ref char uplo, ref lapackint n, double *ap, lapackint *ipiv, ref lapackint info);
void csptrf_(ref char uplo, ref lapackint n, _cfloat *ap, lapackint *ipiv, ref lapackint info);
void zsptrf_(ref char uplo, ref lapackint n, _cdouble *ap, lapackint *ipiv, ref lapackint info);

/// Computes the factorization of a complex
/// Hermitian-indefinite matrix in packed storage,
/// using the diagonal pivoting method.
void chptrf_(ref char uplo, ref lapackint n, _cfloat *ap, lapackint *ipiv, ref lapackint info);
void zhptrf_(ref char uplo, ref lapackint n, _cdouble *ap, lapackint *ipiv, ref lapackint info);

/// Computes the inverse of a real symmetric
/// indefinite matrix in packed storage, using the factorization
/// computed by SSPTRF.
void ssptri_(ref char uplo, ref lapackint n, float *ap, lapackint *ipiv, float *work, ref lapackint info);
void dsptri_(ref char uplo, ref lapackint n, double *ap, lapackint *ipiv, double *work, ref lapackint info);
void csptri_(ref char uplo, ref lapackint n, _cfloat *ap, lapackint *ipiv, _cfloat *work, ref lapackint info);
void zsptri_(ref char uplo, ref lapackint n, _cdouble *ap, lapackint *ipiv, _cdouble *work, ref lapackint info);

/// Computes the inverse of a complex
/// Hermitian indefinite matrix in packed storage, using the factorization
/// computed by CHPTRF.
void chptri_(ref char uplo, ref lapackint n, _cfloat *ap, lapackint *ipiv, _cfloat *work, ref lapackint info);
void zhptri_(ref char uplo, ref lapackint n, _cdouble *ap, lapackint *ipiv, _cdouble *work, ref lapackint info);

/// Solves a real symmetric
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, using the factorization computed
/// by SSPTRF.
void ssptrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *ap, lapackint *ipiv, float *b, ref lapackint ldb, ref lapackint info);
void dsptrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *ap, lapackint *ipiv, double *b, ref lapackint ldb, ref lapackint info);
void csptrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, lapackint *ipiv, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zsptrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, lapackint *ipiv, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Solves a complex Hermitian
/// indefinite system of linear equations AX=B, where A is held
/// in packed storage, using the factorization computed
/// by CHPTRF.
void chptrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *ap, lapackint *ipiv, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zhptrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *ap, lapackint *ipiv, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Computes selected eigenvalues of a real symmetric tridiagonal
/// matrix by bisection.
void sstebz_(ref char range, ref char order, ref lapackint n, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, float *d, float *e, ref lapackint m, ref lapackint nsplit, float *w, lapackint *iblock, lapackint *isplit, float *work, lapackint *iwork, ref lapackint info);
void dstebz_(ref char range, ref char order, ref lapackint n, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, double *d, double *e, ref lapackint m, ref lapackint nsplit, double *w, lapackint *iblock, lapackint *isplit, double *work, lapackint *iwork, ref lapackint info);

/// Computes all eigenvalues and, optionally, eigenvectors of a
/// symmetric tridiagonal matrix using the divide and conquer algorithm.
void sstedc_(ref char compz, ref lapackint n, float *d, float *e, float *z, ref lapackint ldz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dstedc_(ref char compz, ref lapackint n, double *d, double *e, double *z, ref lapackint ldz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void cstedc_(ref char compz, ref lapackint n, float *d, float *e, _cfloat *z, ref lapackint ldz, _cfloat *work, ref lapackint lwork, float *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void zstedc_(ref char compz, ref lapackint n, double *d, double *e, _cdouble *z, ref lapackint ldz, _cdouble *work, ref lapackint lwork, double *rwork, lapackint *lrwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes selected eigenvalues and, optionally, eigenvectors of a
/// symmetric tridiagonal matrix.  The eigenvalues are computed by the
/// dqds algorithm, while eigenvectors are computed from various "good"
/// LDL^T representations (also known as Relatively Robust Representations.)
void sstegr_(ref char jobz, ref char range, ref lapackint n, float *d, float *e, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, float *z, ref lapackint ldz, lapackint *isuppz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dstegr_(ref char jobz, ref char range, ref lapackint n, double *d, double *e, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, double *z, ref lapackint ldz, lapackint *isuppz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void cstegr_(ref char jobz, ref char range, ref lapackint n, float *d, float *e, float *vl, float *vu, lapackint *il, lapackint *iu, ref float abstol, ref lapackint m, float *w, _cfloat *z, ref lapackint ldz, lapackint *isuppz, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void zstegr_(ref char jobz, ref char range, ref lapackint n, double *d, double *e, double *vl, double *vu, lapackint *il, lapackint *iu, ref double abstol, ref lapackint m, double *w, _cdouble *z, ref lapackint ldz, lapackint *isuppz, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes selected eigenvectors of a real symmetric tridiagonal
/// matrix by inverse iteration.
void sstein_(ref lapackint n, float *d, float *e, ref lapackint m, float *w, lapackint *iblock, lapackint *isplit, float *z, ref lapackint ldz, float *work, lapackint *iwork, lapackint *ifail, ref lapackint info);
void dstein_(ref lapackint n, double *d, double *e, ref lapackint m, double *w, lapackint *iblock, lapackint *isplit, double *z, ref lapackint ldz, double *work, lapackint *iwork, lapackint *ifail, ref lapackint info);
void cstein_(ref lapackint n, float *d, float *e, ref lapackint m, float *w, lapackint *iblock, lapackint *isplit, _cfloat *z, ref lapackint ldz, float *work, lapackint *iwork, lapackint *ifail, ref lapackint info);
void zstein_(ref lapackint n, double *d, double *e, ref lapackint m, double *w, lapackint *iblock, lapackint *isplit, _cdouble *z, ref lapackint ldz, double *work, lapackint *iwork, lapackint *ifail, ref lapackint info);

/// Computes all eigenvalues and eigenvectors of a real symmetric
/// tridiagonal matrix, using the implicit QL or QR algorithm.
void ssteqr_(ref char compz, ref lapackint n, float *d, float *e, float *z, ref lapackint ldz, float *work, ref lapackint info);
void dsteqr_(ref char compz, ref lapackint n, double *d, double *e, double *z, ref lapackint ldz, double *work, ref lapackint info);
void csteqr_(ref char compz, ref lapackint n, float *d, float *e, _cfloat *z, ref lapackint ldz, float *work, ref lapackint info);
void zsteqr_(ref char compz, ref lapackint n, double *d, double *e, _cdouble *z, ref lapackint ldz, double *work, ref lapackint info);

/// Computes all eigenvalues of a real symmetric tridiagonal matrix,
/// using a root-free variant of the QL or QR algorithm.
void ssterf_(ref lapackint n, float *d, float *e, ref lapackint info);
void dsterf_(ref lapackint n, double *d, double *e, ref lapackint info);

/// Estimates the reciprocal of the condition number of a
/// real symmetric indefinite matrix,
/// using the factorization computed by SSYTRF.
void ssycon_(ref char uplo, ref lapackint n, float *a, ref lapackint lda, lapackint *ipiv, float *anorm, ref float rcond, float *work, lapackint *iwork, ref lapackint info);
void dsycon_(ref char uplo, ref lapackint n, double *a, ref lapackint lda, lapackint *ipiv, double *anorm, ref double rcond, double *work, lapackint *iwork, ref lapackint info);
void csycon_(ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *ipiv, float *anorm, ref float rcond, _cfloat *work, ref lapackint info);
void zsycon_(ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *ipiv, double *anorm, ref double rcond, _cdouble *work, ref lapackint info);

/// Estimates the reciprocal of the condition number of a
/// complex Hermitian indefinite matrix,
/// using the factorization computed by CHETRF.
void checon_(ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *ipiv, float *anorm, ref float rcond, _cfloat *work, ref lapackint info);
void zhecon_(ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *ipiv, double *anorm, ref double rcond, _cdouble *work, ref lapackint info);

/// Reduces a symmetric-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form, where B has been factorized by SPOTRF.
void ssygst_(lapackint *itype, ref char uplo, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, ref lapackint info);
void dsygst_(lapackint *itype, ref char uplo, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, ref lapackint info);

/// Reduces a Hermitian-definite generalized eigenproblem
/// Ax= lambda Bx,  ABx= lambda x,  or BAx= lambda x, to standard
/// form, where B has been factorized by CPOTRF.
void chegst_(lapackint *itype, ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zhegst_(lapackint *itype, ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Improves the computed solution to a real
/// symmetric indefinite system of linear equations
/// AX=B, and provides forward and backward error bounds for the
/// solution.
void ssyrfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *af, ref lapackint ldaf, lapackint *ipiv, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dsyrfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *af, ref lapackint ldaf, lapackint *ipiv, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void csyrfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *af, ref lapackint ldaf, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zsyrfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *af, ref lapackint ldaf, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Improves the computed solution to a complex
/// Hermitian indefinite system of linear equations
/// AX=B, and provides forward and backward error bounds for the
/// solution.
void cherfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *af, ref lapackint ldaf, lapackint *ipiv, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void zherfs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *af, ref lapackint ldaf, lapackint *ipiv, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Reduces a symmetric matrix to real symmetric tridiagonal
/// form by an orthogonal similarity transformation.
void ssytrd_(ref char uplo, ref lapackint n, float *a, ref lapackint lda, float *d, float *e, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dsytrd_(ref char uplo, ref lapackint n, double *a, ref lapackint lda, double *d, double *e, double *tau, double *work, ref lapackint lwork, ref lapackint info);

/// Reduces a Hermitian matrix to real symmetric tridiagonal
/// form by an orthogonal/unitary similarity transformation.
void chetrd_(ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, float *d, float *e, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zhetrd_(ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, double *d, double *e, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Computes the factorization of a real symmetric-indefinite matrix,
/// using the diagonal pivoting method.
void ssytrf_(ref char uplo, ref lapackint n, float *a, ref lapackint lda, lapackint *ipiv, float *work, ref lapackint lwork, ref lapackint info);
void dsytrf_(ref char uplo, ref lapackint n, double *a, ref lapackint lda, lapackint *ipiv, double *work, ref lapackint lwork, ref lapackint info);
void csytrf_(ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zsytrf_(ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Computes the factorization of a complex Hermitian-indefinite matrix,
/// using the diagonal pivoting method.
void chetrf_(ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *work, ref lapackint lwork, ref lapackint info);
void zhetrf_(ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Computes the inverse of a real symmetric indefinite matrix,
/// using the factorization computed by SSYTRF.
void ssytri_(ref char uplo, ref lapackint n, float *a, ref lapackint lda, lapackint *ipiv, float *work, ref lapackint info);
void dsytri_(ref char uplo, ref lapackint n, double *a, ref lapackint lda, lapackint *ipiv, double *work, ref lapackint info);
void csytri_(ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *work, ref lapackint info);
void zsytri_(ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *work, ref lapackint info);

/// Computes the inverse of a complex Hermitian indefinite matrix,
/// using the factorization computed by CHETRF.
void chetri_(ref char uplo, ref lapackint n, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *work, ref lapackint info);
void zhetri_(ref char uplo, ref lapackint n, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *work, ref lapackint info);

/// Solves a real symmetric indefinite system of linear equations AX=B,
/// using the factorization computed by SSPTRF.
void ssytrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, lapackint *ipiv, float *b, ref lapackint ldb, ref lapackint info);
void dsytrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, lapackint *ipiv, double *b, ref lapackint ldb, ref lapackint info);
void csytrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zsytrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Solves a complex Hermitian indefinite system of linear equations AX=B,
/// using the factorization computed by CHPTRF.
void chetrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, lapackint *ipiv, _cfloat *b, ref lapackint ldb, ref lapackint info);
void zhetrs_(ref char uplo, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, lapackint *ipiv, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Estimates the reciprocal of the condition number of a triangular
/// band matrix, in either the 1-norm or the infinity-norm.
void stbcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, lapackint *kd, float *ab, ref lapackint ldab, ref float rcond, float *work, lapackint *iwork, ref lapackint info);
void dtbcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, lapackint *kd, double *ab, ref lapackint ldab, ref double rcond, double *work, lapackint *iwork, ref lapackint info);
void ctbcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, lapackint *kd, _cfloat *ab, ref lapackint ldab, ref float rcond, _cfloat *work, float *rwork, ref lapackint info);
void ztbcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, lapackint *kd, _cdouble *ab, ref lapackint ldab, ref double rcond, _cdouble *work, double *rwork, ref lapackint info);

/// Provides forward and backward error bounds for the solution
/// of a triangular banded system of linear equations AX=B,
/// A**T X=B or A**H X=B.
void stbrfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, lapackint *kd, ref lapackint nrhs, float *ab, ref lapackint ldab, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dtbrfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, lapackint *kd, ref lapackint nrhs, double *ab, ref lapackint ldab, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void ctbrfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cfloat *ab, ref lapackint ldab, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void ztbrfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cdouble *ab, ref lapackint ldab, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Solves a triangular banded system of linear equations AX=B,
/// A**T X=B or A**H X=B.
void stbtrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, lapackint *kd, ref lapackint nrhs, float *ab, ref lapackint ldab, float *b, ref lapackint ldb, ref lapackint info);
void dtbtrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, lapackint *kd, ref lapackint nrhs, double *ab, ref lapackint ldab, double *b, ref lapackint ldb, ref lapackint info);
void ctbtrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cfloat *ab, ref lapackint ldab, _cfloat *b, ref lapackint ldb, ref lapackint info);
void ztbtrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, lapackint *kd, ref lapackint nrhs, _cdouble *ab, ref lapackint ldab, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Computes some or all of the right and/or left generalized eigenvectors
/// of a pair of upper triangular matrices.
void stgevc_(ref char side, ref char howmny, lapackint *select, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *vl, ref lapackint ldvl, float *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, float *work, ref lapackint info);
void dtgevc_(ref char side, ref char howmny, lapackint *select, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *vl, ref lapackint ldvl, double *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, double *work, ref lapackint info);
void ctgevc_(ref char side, ref char howmny, lapackint *select, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *vl, ref lapackint ldvl, _cfloat *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, _cfloat *work, float *rwork, ref lapackint info);
void ztgevc_(ref char side, ref char howmny, lapackint *select, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *vl, ref lapackint ldvl, _cdouble *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, _cdouble *work, double *rwork, ref lapackint info);

/// Reorders the generalized real Schur decomposition of a real
/// matrix pair (A,B) using an orthogonal equivalence transformation
/// so that the diagonal block of (A,B) with row index IFST is moved
/// to row ILST.
void stgexc_(lapackint *wantq, lapackint *wantz, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *q, ref lapackint ldq, float *z, ref lapackint ldz, lapackint *ifst, lapackint *ilst, float *work, ref lapackint lwork, ref lapackint info);
void dtgexc_(lapackint *wantq, lapackint *wantz, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *q, ref lapackint ldq, double *z, ref lapackint ldz, lapackint *ifst, lapackint *ilst, double *work, ref lapackint lwork, ref lapackint info);
void ctgexc_(lapackint *wantq, lapackint *wantz, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *q, ref lapackint ldq, _cfloat *z, ref lapackint ldz, lapackint *ifst, lapackint *ilst, ref lapackint info);
void ztgexc_(lapackint *wantq, lapackint *wantz, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *q, ref lapackint ldq, _cdouble *z, ref lapackint ldz, lapackint *ifst, lapackint *ilst, ref lapackint info);

/// Reorders the generalized real Schur decomposition of a real
/// matrix pair (A, B) so that a selected cluster of eigenvalues
/// appears in the leading diagonal blocks of the upper quasi-triangular
/// matrix A and the upper triangular B.
void stgsen_(lapackint *ijob, lapackint *wantq, lapackint *wantz, lapackint *select, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *alphar, float *alphai, float *betav, float *q, ref lapackint ldq, float *z, ref lapackint ldz, ref lapackint m, float *pl, float *pr, float *dif, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dtgsen_(lapackint *ijob, lapackint *wantq, lapackint *wantz, lapackint *select, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *alphar, double *alphai, double *betav, double *q, ref lapackint ldq, double *z, ref lapackint ldz, ref lapackint m, double *pl, double *pr, double *dif, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void ctgsen_(lapackint *ijob, lapackint *wantq, lapackint *wantz, lapackint *select, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *alphav, _cfloat *betav, _cfloat *q, ref lapackint ldq, _cfloat *z, ref lapackint ldz, ref lapackint m, float *pl, float *pr, float *dif, _cfloat *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void ztgsen_(lapackint *ijob, lapackint *wantq, lapackint *wantz, lapackint *select, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *alphav, _cdouble *betav, _cdouble *q, ref lapackint ldq, _cdouble *z, ref lapackint ldz, ref lapackint m, double *pl, double *pr, double *dif, _cdouble *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);

/// Computes the generalized singular value decomposition of two real
/// upper triangular (or trapezoidal) matrices as output by SGGSVP.
void stgsja_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint p, ref lapackint n, ref lapackint k, ref lapackint l, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *tola, float *tolb, float *alphav, float *betav, float *u, ref lapackint ldu, float *v, ref lapackint ldv, float *q, ref lapackint ldq, float *work, ref lapackint ncycle, ref lapackint info);
void dtgsja_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint p, ref lapackint n, ref lapackint k, ref lapackint l, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *tola, double *tolb, double *alphav, double *betav, double *u, ref lapackint ldu, double *v, ref lapackint ldv, double *q, ref lapackint ldq, double *work, ref lapackint ncycle, ref lapackint info);
void ctgsja_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint p, ref lapackint n, ref lapackint k, ref lapackint l, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, float *tola, float *tolb, float *alphav, float *betav, _cfloat *u, ref lapackint ldu, _cfloat *v, ref lapackint ldv, _cfloat *q, ref lapackint ldq, _cfloat *work, ref lapackint ncycle, ref lapackint info);
void ztgsja_(ref char jobu, ref char jobv, ref char jobq, ref lapackint m, ref lapackint p, ref lapackint n, ref lapackint k, ref lapackint l, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, double *tola, double *tolb, double *alphav, double *betav, _cdouble *u, ref lapackint ldu, _cdouble *v, ref lapackint ldv, _cdouble *q, ref lapackint ldq, _cdouble *work, ref lapackint ncycle, ref lapackint info);

/// Estimates reciprocal condition numbers for specified
/// eigenvalues and/or eigenvectors of a matrix pair (A, B) in
/// generalized real Schur canonical form, as returned by SGGES.
void stgsna_(ref char job, ref char howmny, lapackint *select, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *vl, ref lapackint ldvl, float *vr, ref lapackint ldvr, float *s, float *dif, lapackint *mm, ref lapackint m, float *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void dtgsna_(ref char job, ref char howmny, lapackint *select, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *vl, ref lapackint ldvl, double *vr, ref lapackint ldvr, double *s, double *dif, lapackint *mm, ref lapackint m, double *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void ctgsna_(ref char job, ref char howmny, lapackint *select, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *vl, ref lapackint ldvl, _cfloat *vr, ref lapackint ldvr, float *s, float *dif, lapackint *mm, ref lapackint m, _cfloat *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void ztgsna_(ref char job, ref char howmny, lapackint *select, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *vl, ref lapackint ldvl, _cdouble *vr, ref lapackint ldvr, double *s, double *dif, lapackint *mm, ref lapackint m, _cdouble *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);

/// Solves the generalized Sylvester equation.
void stgsyl_(ref char trans, lapackint *ijob, ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *c, ref lapackint ldc, float *d, ref lapackint ldd, float *e, ref lapackint lde, float *f, ref lapackint ldf, float *scale, float *dif, float *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void dtgsyl_(ref char trans, lapackint *ijob, ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *c, ref lapackint ldc, double *d, ref lapackint ldd, double *e, ref lapackint lde, double *f, ref lapackint ldf, double *scale, double *dif, double *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void ctgsyl_(ref char trans, lapackint *ijob, ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *c, ref lapackint ldc, _cfloat *d, ref lapackint ldd, _cfloat *e, ref lapackint lde, _cfloat *f, ref lapackint ldf, float *scale, float *dif, _cfloat *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);
void ztgsyl_(ref char trans, lapackint *ijob, ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *c, ref lapackint ldc, _cdouble *d, ref lapackint ldd, _cdouble *e, ref lapackint lde, _cdouble *f, ref lapackint ldf, double *scale, double *dif, _cdouble *work, ref lapackint lwork, lapackint *iwork, ref lapackint info);

/// Estimates the reciprocal of the condition number of a triangular
/// matrix in packed storage, in either the 1-norm or the infinity-norm.
void stpcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, float *ap, ref float rcond, float *work, lapackint *iwork, ref lapackint info);
void dtpcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, double *ap, ref double rcond, double *work, lapackint *iwork, ref lapackint info);
void ctpcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, _cfloat *ap, ref float rcond, _cfloat *work, float *rwork, ref lapackint info);
void ztpcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, _cdouble *ap, ref double rcond, _cdouble *work, double *rwork, ref lapackint info);

/// Provides forward and backward error bounds for the solution
/// of a triangular system of linear equations AX=B, A**T X=B or
/// A**H X=B, where A is held in packed storage.
void stprfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, float *ap, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dtprfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, double *ap, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void ctprfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, _cfloat *ap, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void ztprfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, _cdouble *ap, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

///  Computes the inverse of a triangular matrix in packed storage.
void stptri_(ref char uplo, ref char diag, ref lapackint n, float *ap, ref lapackint info);
void dtptri_(ref char uplo, ref char diag, ref lapackint n, double *ap, ref lapackint info);
void ctptri_(ref char uplo, ref char diag, ref lapackint n, _cfloat *ap, ref lapackint info);
void ztptri_(ref char uplo, ref char diag, ref lapackint n, _cdouble *ap, ref lapackint info);

/// Solves a triangular system of linear equations AX=B,
/// A**T X=B or A**H X=B, where A is held in packed storage.
void stptrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, float *ap, float *b, ref lapackint ldb, ref lapackint info);
void dtptrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, double *ap, double *b, ref lapackint ldb, ref lapackint info);
void ctptrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, _cfloat *ap, _cfloat *b, ref lapackint ldb, ref lapackint info);
void ztptrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, _cdouble *ap, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Estimates the reciprocal of the condition number of a triangular
/// matrix, in either the 1-norm or the infinity-norm.
void strcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, float *a, ref lapackint lda, ref float rcond, float *work, lapackint *iwork, ref lapackint info);
void dtrcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, double *a, ref lapackint lda, ref double rcond, double *work, lapackint *iwork, ref lapackint info);
void ctrcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, _cfloat *a, ref lapackint lda, ref float rcond, _cfloat *work, float *rwork, ref lapackint info);
void ztrcon_(ref char norm, ref char uplo, ref char diag, ref lapackint n, _cdouble *a, ref lapackint lda, ref double rcond, _cdouble *work, double *rwork, ref lapackint info);

/// Computes some or all of the right and/or left eigenvectors of
/// an upper quasi-triangular matrix.
void strevc_(ref char side, ref char howmny, lapackint *select, ref lapackint n, float *t, ref lapackint ldt, float *vl, ref lapackint ldvl, float *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, float *work, ref lapackint info);
void dtrevc_(ref char side, ref char howmny, lapackint *select, ref lapackint n, double *t, ref lapackint ldt, double *vl, ref lapackint ldvl, double *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, double *work, ref lapackint info);
void ctrevc_(ref char side, ref char howmny, lapackint *select, ref lapackint n, _cfloat *t, ref lapackint ldt, _cfloat *vl, ref lapackint ldvl, _cfloat *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, _cfloat *work, float *rwork, ref lapackint info);
void ztrevc_(ref char side, ref char howmny, lapackint *select, ref lapackint n, _cdouble *t, ref lapackint ldt, _cdouble *vl, ref lapackint ldvl, _cdouble *vr, ref lapackint ldvr, lapackint *mm, ref lapackint m, _cdouble *work, double *rwork, ref lapackint info);

/// Reorders the Schur factorization of a matrix by an orthogonal
/// similarity transformation.
void strexc_(ref char compq, ref lapackint n, float *t, ref lapackint ldt, float *q, ref lapackint ldq, lapackint *ifst, lapackint *ilst, float *work, ref lapackint info);
void dtrexc_(ref char compq, ref lapackint n, double *t, ref lapackint ldt, double *q, ref lapackint ldq, lapackint *ifst, lapackint *ilst, double *work, ref lapackint info);
void ctrexc_(ref char compq, ref lapackint n, _cfloat *t, ref lapackint ldt, _cfloat *q, ref lapackint ldq, lapackint *ifst, lapackint *ilst, ref lapackint info);
void ztrexc_(ref char compq, ref lapackint n, _cdouble *t, ref lapackint ldt, _cdouble *q, ref lapackint ldq, lapackint *ifst, lapackint *ilst, ref lapackint info);

/// Provides forward and backward error bounds for the solution
/// of a triangular system of linear equations A X=B, A**T X=B or
/// A**H X=B.
void strrfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *x, ref lapackint ldx, float *ferr, float *berr, float *work, lapackint *iwork, ref lapackint info);
void dtrrfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *x, ref lapackint ldx, double *ferr, double *berr, double *work, lapackint *iwork, ref lapackint info);
void ctrrfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *x, ref lapackint ldx, float *ferr, float *berr, _cfloat *work, float *rwork, ref lapackint info);
void ztrrfs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *x, ref lapackint ldx, double *ferr, double *berr, _cdouble *work, double *rwork, ref lapackint info);

/// Reorders the Schur factorization of a matrix in order to find
/// an orthonormal basis of a right invariant subspace corresponding
/// to selected eigenvalues, and returns reciprocal condition numbers
/// (sensitivities) of the average of the cluster of eigenvalues
/// and of the invariant subspace.
void strsen_(ref char job, ref char compq, lapackint *select, ref lapackint n, float *t, ref lapackint ldt, float *q, ref lapackint ldq, float *wr, float *wi, ref lapackint m, float *s, float *sep, float *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void dtrsen_(ref char job, ref char compq, lapackint *select, ref lapackint n, double *t, ref lapackint ldt, double *q, ref lapackint ldq, double *wr, double *wi, ref lapackint m, double *s, double *sep, double *work, ref lapackint lwork, lapackint *iwork, lapackint *liwork, ref lapackint info);
void ctrsen_(ref char job, ref char compq, lapackint *select, ref lapackint n, _cfloat *t, ref lapackint ldt, _cfloat *q, ref lapackint ldq, _cfloat *w, ref lapackint m, float *s, float *sep, _cfloat *work, ref lapackint lwork, ref lapackint info);
void ztrsen_(ref char job, ref char compq, lapackint *select, ref lapackint n, _cdouble *t, ref lapackint ldt, _cdouble *q, ref lapackint ldq, _cdouble *w, ref lapackint m, double *s, double *sep, _cdouble *work, ref lapackint lwork, ref lapackint info);

/// Estimates the reciprocal condition numbers (sensitivities)
/// of selected eigenvalues and eigenvectors of an upper
/// quasi-triangular matrix.
void strsna_(ref char job, ref char howmny, lapackint *select, ref lapackint n, float *t, ref lapackint ldt, float *vl, ref lapackint ldvl, float *vr, ref lapackint ldvr, float *s, float *sep, lapackint *mm, ref lapackint m, float *work, ref lapackint ldwork, lapackint *iwork, ref lapackint info);
void dtrsna_(ref char job, ref char howmny, lapackint *select, ref lapackint n, double *t, ref lapackint ldt, double *vl, ref lapackint ldvl, double *vr, ref lapackint ldvr, double *s, double *sep, lapackint *mm, ref lapackint m, double *work, ref lapackint ldwork, lapackint *iwork, ref lapackint info);
void ctrsna_(ref char job, ref char howmny, lapackint *select, ref lapackint n, _cfloat *t, ref lapackint ldt, _cfloat *vl, ref lapackint ldvl, _cfloat *vr, ref lapackint ldvr, float *s, float *sep, lapackint *mm, ref lapackint m, _cfloat *work, ref lapackint ldwork, float *rwork, ref lapackint info);
void ztrsna_(ref char job, ref char howmny, lapackint *select, ref lapackint n, _cdouble *t, ref lapackint ldt, _cdouble *vl, ref lapackint ldvl, _cdouble *vr, ref lapackint ldvr, double *s, double *sep, lapackint *mm, ref lapackint m, _cdouble *work, ref lapackint ldwork, double *rwork, ref lapackint info);

/// Solves the Sylvester matrix equation A X +/- X B=C where A
/// and B are upper quasi-triangular, and may be transposed.
void strsyl_(ref char trana, ref char tranb, lapackint *isgn, ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *b, ref lapackint ldb, float *c, ref lapackint ldc, float *scale, ref lapackint info);
void dtrsyl_(ref char trana, ref char tranb, lapackint *isgn, ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *b, ref lapackint ldb, double *c, ref lapackint ldc, double *scale, ref lapackint info);
void ctrsyl_(ref char trana, ref char tranb, lapackint *isgn, ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, _cfloat *c, ref lapackint ldc, float *scale, ref lapackint info);
void ztrsyl_(ref char trana, ref char tranb, lapackint *isgn, ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, _cdouble *c, ref lapackint ldc, double *scale, ref lapackint info);

/// Computes the inverse of a triangular matrix.
void strtri_(ref char uplo, ref char diag, ref lapackint n, float *a, ref lapackint lda, ref lapackint info);
void dtrtri_(ref char uplo, ref char diag, ref lapackint n, double *a, ref lapackint lda, ref lapackint info);
void ctrtri_(ref char uplo, ref char diag, ref lapackint n, _cfloat *a, ref lapackint lda, ref lapackint info);
void ztrtri_(ref char uplo, ref char diag, ref lapackint n, _cdouble *a, ref lapackint lda, ref lapackint info);

/// Solves a triangular system of linear equations AX=B,
/// A**T X=B or A**H X=B.
void strtrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, float *a, ref lapackint lda, float *b, ref lapackint ldb, ref lapackint info);
void dtrtrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, double *a, ref lapackint lda, double *b, ref lapackint ldb, ref lapackint info);
void ctrtrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, _cfloat *a, ref lapackint lda, _cfloat *b, ref lapackint ldb, ref lapackint info);
void ztrtrs_(ref char uplo, ref char trans, ref char diag, ref lapackint n, ref lapackint nrhs, _cdouble *a, ref lapackint lda, _cdouble *b, ref lapackint ldb, ref lapackint info);

/// Computes an RQ factorization of an upper trapezoidal matrix.
void stzrqf_(ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *tau, ref lapackint info);
void dtzrqf_(ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *tau, ref lapackint info);
void ctzrqf_(ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *tau, ref lapackint info);
void ztzrqf_(ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *tau, ref lapackint info);

/// Computes an RZ factorization of an upper trapezoidal matrix
/// (blocked version of STZRQF).
void stzrzf_(ref lapackint m, ref lapackint n, float *a, ref lapackint lda, float *tau, float *work, ref lapackint lwork, ref lapackint info);
void dtzrzf_(ref lapackint m, ref lapackint n, double *a, ref lapackint lda, double *tau, double *work, ref lapackint lwork, ref lapackint info);
void ctzrzf_(ref lapackint m, ref lapackint n, _cfloat *a, ref lapackint lda, _cfloat *tau, _cfloat *work, ref lapackint lwork, ref lapackint info);
void ztzrzf_(ref lapackint m, ref lapackint n, _cdouble *a, ref lapackint lda, _cdouble *tau, _cdouble *work, ref lapackint lwork, ref lapackint info);


/// Multiplies a general matrix by the unitary
/// transformation matrix from a reduction to tridiagonal form
/// determined by CHPTRD.
void cupmtr_(ref char side, ref char uplo, ref char trans, ref lapackint m, ref lapackint n, _cfloat *ap, _cfloat *tau, _cfloat *c, ref lapackint ldc, _cfloat *work, ref lapackint info);
void zupmtr_(ref char side, ref char uplo, ref char trans, ref lapackint m, ref lapackint n, _cdouble *ap, _cdouble *tau, _cdouble *c, ref lapackint ldc, _cdouble *work, ref lapackint info);


//------------------------------------
//     ----- MISC routines -----
//------------------------------------

///
lapackint ilaenv_(ref lapackint ispec, char* name, char* opts, ref lapackint n1, ref lapackint n2, ref lapackint n3, ref lapackint n4);
///
void ilaenvset_(ref lapackint ispec, char* name, char* opts, ref lapackint n1, ref lapackint n2, ref lapackint n3, ref lapackint n4, ref lapackint nvalue, ref lapackint info);

///
float slamch_(char* cmach);
double dlamch_(char* cmach);

version(CLAPACK_NETLIB)
{
    ///
    lapack_float_ret_t second_();
    ///
    double dsecnd_();
}
