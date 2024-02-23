#ifndef Have_GLASB
#define Have_GLASB
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif

typedef int FortranInt;

int xerbla_(const char *srname, FortranInt *info);

int scopy_(const FortranInt *n, const float *x, const FortranInt *incx, float *y, const FortranInt *incy);
int dcopy_(const FortranInt *n, const double *x, const FortranInt *incx, double *y, const FortranInt *incy);
int ccopy_(const FortranInt *n, const float _Complex *x, const FortranInt *incx, float _Complex *y, const FortranInt *incy);
int zcopy_(const FortranInt *n, const double _Complex *x, const FortranInt *incx, double _Complex *y, const FortranInt *incy);

int sswap_(const FortranInt *n, float *x, const FortranInt *incx, float *y, const FortranInt *incy);
int dswap_(const FortranInt *n, double *x, const FortranInt *incx, double *y, const FortranInt *incy);
int cswap_(const FortranInt *n, float _Complex *x, const FortranInt *incx, float _Complex *y, const FortranInt *incy);
int zswap_(const FortranInt *n, double _Complex *x, const FortranInt *incx, double _Complex *y, const FortranInt *incy);

int saxpy_(const FortranInt *n, const float *a, const float *x, const FortranInt *incx, float *y, const FortranInt *incy);
int daxpy_(const FortranInt *n, const double *a, const double *x, const FortranInt *incx, double *y, const FortranInt *incy);
int caxpy_(const FortranInt *n, const float _Complex *a, const float _Complex *x, const FortranInt *incx, float _Complex *y, const FortranInt *incy);
int zaxpy_(const FortranInt *n, const double _Complex *a, const double _Complex *x, const FortranInt *incx, double _Complex *y, const FortranInt *incy);

float snrm2_(const FortranInt *n, const float *x, const FortranInt *incx);
double dnrm2_(const FortranInt *n, const double *x, const FortranInt *incx);
float scnrm2_(const FortranInt *n, const float _Complex *x, const FortranInt *incx);
double dznrm2_(const FortranInt *n, const double _Complex *x, const FortranInt *incx);

float sasum_(const FortranInt *n, const float *x, const FortranInt *incx);
double dasum_(const FortranInt *n, const double *x, const FortranInt *incx);
float scasum_(const FortranInt *n, const float _Complex *x, const FortranInt *incx);
double dzasum_(const FortranInt *n, const double _Complex *x, const FortranInt *incx);

FortranInt isamax_(const FortranInt *n, const float *x, const FortranInt *incx);
FortranInt idamax_(const FortranInt *n, const double *x, const FortranInt *incx);
FortranInt icamax_(const FortranInt *n, const float _Complex *x, const FortranInt *incx);
FortranInt izamax_(const FortranInt *n, const double _Complex *x, const FortranInt *incx);

int sscal_(const FortranInt *n, const float *a, float *x, const FortranInt *incx);
int dscal_(const FortranInt *n, const double *a, double *x, const FortranInt *incx);
int csscal_(const FortranInt *n, const float *a, float _Complex *x, const FortranInt *incx);
int cscal_(const FortranInt *n, const float _Complex *a, float _Complex *x, const FortranInt *incx);
int csIscal_(const FortranInt *n, const float *a, float _Complex *x, const FortranInt *incx);
int zdscal_(const FortranInt *n, const double *a, double _Complex *x, const FortranInt *incx);
int zscal_(const FortranInt *n, const double _Complex *a, double _Complex *x, const FortranInt *incx);
int zdIscal_(const FortranInt *n, const double *a, double _Complex *x, const FortranInt *incx);

int sgemm_(const char *transa, const char *transb, const FortranInt *m, const FortranInt *n, const FortranInt *k, const float *alpha, const float *a, const FortranInt *lda, const float *b, const FortranInt *ldb, const float *beta, float *c, const FortranInt *ldc);
int dgemm_(const char *transa, const char *transb, const FortranInt *m, const FortranInt *n, const FortranInt *k, const double *alpha, const double *a, const FortranInt *lda, const double *b, const FortranInt *ldb, const double *beta, double *c, const FortranInt *ldc);
int cgemm_(const char *transa, const char *transb, const FortranInt *m, const FortranInt *n, const FortranInt *k, const float _Complex *alpha, const float _Complex *a, const FortranInt *lda, const float _Complex *b, const FortranInt *ldb, const float _Complex *beta, float _Complex *c, const FortranInt *ldc);
int zgemm_(const char *transa, const char *transb, const FortranInt *m, const FortranInt *n, const FortranInt *k, const double _Complex *alpha, const double _Complex *a, const FortranInt *lda, const double _Complex *b, const FortranInt *ldb, const double _Complex *beta, double _Complex *c, const FortranInt *ldc);

int ssymm_(const char *side, const char *uplo, const FortranInt *m, const FortranInt *n, const float *alpha, const float *a, const FortranInt *lda, const float *b, const FortranInt *ldb, const float *beta, float *c, const FortranInt *ldc);
int dsymm_(const char *side, const char *uplo, const FortranInt *m, const FortranInt *n, const double *alpha, const double *a, const FortranInt *lda, const double *b, const FortranInt *ldb, const double *beta, double *c, const FortranInt *ldc);
int csymm_(const char *side, const char *uplo, const FortranInt *m, const FortranInt *n, const float _Complex *alpha, const float _Complex *a, const FortranInt *lda, const float _Complex *b, const FortranInt *ldb, const float _Complex *beta, float _Complex *c, const FortranInt *ldc);
int zsymm_(const char *side, const char *uplo, const FortranInt *m, const FortranInt *n, const double _Complex *alpha, const double _Complex *a, const FortranInt *lda, const double _Complex *b, const FortranInt *ldb, const double _Complex *beta, double _Complex *c, const FortranInt *ldc);

int chemm_(const char *side, const char *uplo, const FortranInt *m, const FortranInt *n, const float _Complex *alpha, const float _Complex *a, const FortranInt *lda, const float _Complex *b, const FortranInt *ldb, const float _Complex *beta, float _Complex *c, const FortranInt *ldc);
int zhemm_(const char *side, const char *uplo, const FortranInt *m, const FortranInt *n, const double _Complex *alpha, const double _Complex *a, const FortranInt *lda, const double _Complex *b, const FortranInt *ldb, const double _Complex *beta, double _Complex *c, const FortranInt *ldc);

#ifdef __cplusplus
}
#endif
#endif
