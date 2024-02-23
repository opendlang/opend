/++
$(H2 GLAS API)

Copyright: Copyright © 2016-, Ilya Yaroshenko.
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Ilya Yaroshenko

$(H4 Transposition)
GLAS does not require transposition parameters.
Use $(LINK2 http://dlang.org/phobos/std_experimental_ndslice_iteration.html#transposed, transposed)
to perform zero cost ndslice transposition.

Note: $(LINK2 , ndslice) uses is row major representation.
    $(BR)
+/
module glas.ndslice;

version(D_Ddoc)
{
    enum SliceKind
    {
        universal,
        canonical,
        contiguous,
    }
    struct Structure(size_t N) {}
    struct Slice(SliceKind kind, size_t[] packs, Iterator) {}
}
else
{
    import mir.ndslice.slice: Slice, SliceKind, Structure;
}

extern(C) nothrow @nogc @system:

/++
Specifies if the matrix `asl` stores conjugated elements.
+/
enum ulong ConjA = 0x1;
/++
Specifies if the matrix `bsl` stores conjugated elements.
+/
enum ulong ConjB = 0x2;
/++
Specifies if the lower  triangular
part of the symmetric matrix A is to be referenced.

The lower triangular part of the matrix `asl`
must contain the lower triangular part of the symmetric / hermitian
matrix A and the strictly upper triangular part of `asl` is not
referenced.

Note: Lower is default flag.
+/
enum ulong Lower = 0x0;
/++
Specifies if the upper  triangular
part of the symmetric matrix A is to be referenced.

The upper triangular
part of the matrix `asl`  must contain the upper triangular part
of the symmetric / hermitian matrix A and the strictly lower triangular
part of `asl` is not referenced.
+/
enum ulong Upper = 0x0100;
/++
Specifies if the symmetric/hermitian matrix A
    appears on the left in the  operation.

Note: Left is default flag.
+/
enum ulong Left = 0x0;
/++
Specifies if the symmetric/hermitian matrix A
    appears on the left in the  operation.
+/
enum ulong Right = 0x0200;

/++
Params:
    error_code = Error code
Returns:
    error message
+/
string glas_error(int error_code);

/++
Validates input data for GEMM operations.
Params:
    as = structure for matrix A
    bs = structure for matrix B
    cs = structure for matrix C
    settings = Operation settings. Allowed flags are
            $(LREF ConjA), $(LREF ConjB).
Returns: 0 on success and error code otherwise.
+/
int glas_validate_gemm(Structure!2 as, Structure!2 bs, Structure!2 cs, ulong settings = 0);
/// ditto
alias validate_gemm = glas_validate_gemm;

/++
Validates input data for SYMM operations.
Params:
    as = structure for matrix A
    bs = structure for matrix B
    cs = structure for matrix C
    settings = Operation settings. Allowed flags are
            $(LREF Left), $(LREF Right),
            $(LREF Lower), $(LREF Upper),
            $(LREF ConjA), $(LREF ConjB).
            $(LREF ConjA) flag specifies if the matrix A is hermitian.
Returns: 0 on success and error code otherwise.
+/
int glas_validate_symm(Structure!2 as, Structure!2 bs, Structure!2 cs, ulong settings = 0);
/// ditto
alias validate_symm = glas_validate_symm;

/++
Performs general matrix-matrix multiplication.

Pseudo_code: `C := alpha A × B + beta C`.

Params:
    alpha = scalar
    asl = `m ⨉ k` matrix
    bsl = `k ⨉ n` matrix
    beta = scalar. When  `beta`  is supplied as zero then the matrix `csl` need not be set on input.
    csl = `m ⨉ n` matrix with one stride equal to `±1`.
    settings = Operation settings. Allowed flags are $(LREF ConjA) and $(LREF ConjB).

Unified_alias: `gemm`

BLAS: SGEMM, DGEMM, CGEMM, ZGEMM
+/
void glas_sgemm(float alpha, Slice!(SliceKind.universal, [2], const(float)*) asl, Slice!(SliceKind.universal, [2], const(float)*) bsl, float beta, Slice!(SliceKind.universal, [2], float*) csl, ulong settings = 0);
/// ditto
void glas_dgemm(double alpha, Slice!(SliceKind.universal, [2], const(double)*) asl, Slice!(SliceKind.universal, [2], const(double)*) bsl, double beta, Slice!(SliceKind.universal, [2], double*) csl, ulong settings = 0);
/// ditto
void glas_cgemm(cfloat alpha, Slice!(SliceKind.universal, [2], const(cfloat)*) asl, Slice!(SliceKind.universal, [2], const(cfloat)*) bsl, cfloat beta, Slice!(SliceKind.universal, [2], cfloat*) csl, ulong settings = 0);
/// ditto
void glas_zgemm(cdouble alpha, Slice!(SliceKind.universal, [2], const(cdouble)*) asl, Slice!(SliceKind.universal, [2], const(cdouble)*) bsl, cdouble beta, Slice!(SliceKind.universal, [2], cdouble*) csl, ulong settings = 0);

/// ditto
alias gemm = glas_sgemm;
/// ditto
alias gemm = glas_dgemm;
/// ditto
alias gemm = glas_cgemm;
/// ditto
alias gemm = glas_zgemm;

/++
Performs symmetric or hermitian matrix-matrix multiplication.

Pseudo_code: `C := alpha A × B + beta C` or `C := alpha B × A + beta C`,
    where  `alpha` and `beta` are scalars, `A` is a symmetric or hermitian matrix and `B` and
    `C` are `m × n` matrices.

Params:
    alpha = scalar
    asl = `k ⨉ k` matrix, where `k` is `n`  when $(LREF Right) flag is set
           and is `m` otherwise.
    bsl = `m ⨉ n` matrix
    beta = scalar. When  `beta`  is supplied as zero then the matrix `csl` need not be set on input.
    csl = `m ⨉ n` matrix with one stride equals to `±1`.
    settings = Operation settings.
        Allowed flags are
            $(LREF Left), $(LREF Right),
            $(LREF Lower), $(LREF Upper),
            $(LREF ConjA), $(LREF ConjB).
            $(LREF ConjA) flag specifies if the matrix A is hermitian.

Unified_alias: `symm`

If your matrix is not SliceKind.universal, you can use `mir.ndslice.topology.universal` 
to convert it before passing it.

BLAS: SSYMM, DSYMM, CSYMM, ZSYMM, SHEMM, DHEMM, CHEMM, ZHEMM
+/
void glas_ssymm(float alpha, Slice!(SliceKind.universal, [2], const(float)*) asl, Slice!(SliceKind.universal, [2], const(float)*) bsl, float beta, Slice!(SliceKind.universal, [2], float*) csl, ulong settings = 0);
/// ditto
void glas_dsymm(double alpha, Slice!(SliceKind.universal, [2], const(double)*) asl, Slice!(SliceKind.universal, [2], const(double)*) bsl, double beta, Slice!(SliceKind.universal, [2], double*) csl, ulong settings = 0);
/// ditto
void glas_csymm(cfloat alpha, Slice!(SliceKind.universal, [2], const(cfloat)*) asl, Slice!(SliceKind.universal, [2], const(cfloat)*) bsl, cfloat beta, Slice!(SliceKind.universal, [2], cfloat*) csl, ulong settings = 0);
/// ditto
void glas_zsymm(cdouble alpha, Slice!(SliceKind.universal, [2], const(cdouble)*) asl, Slice!(SliceKind.universal, [2], const(cdouble)*) bsl, cdouble beta, Slice!(SliceKind.universal, [2], cdouble*) csl, ulong settings = 0);

/// ditto
alias symm = glas_ssymm;
/// ditto
alias symm = glas_dsymm;
/// ditto
alias symm = glas_csymm;
/// ditto
alias symm = glas_zsymm;

pure:

/++
`copy` copies a vector, `x`, to a vector, `y`.

Pseudo_code: `y := x`.

Unified_alias: `copy`

BLAS: SCOPY, DCOPY, CCOPY, ZCOPY
+/
void glas_scopy(Slice!(SliceKind.universal, [1], const(float)*) xsl, Slice!(SliceKind.universal, [1], float*) ysl);
/// ditto
void glas_dcopy(Slice!(SliceKind.universal, [1], const(double)*) xsl, Slice!(SliceKind.universal, [1], double*) ysl);
/// ditto
void glas_ccopy(Slice!(SliceKind.universal, [1], const(cfloat)*) xsl, Slice!(SliceKind.universal, [1], float*) ysl);
/// ditto
void glas_zcopy(Slice!(SliceKind.universal, [1], const(cdouble)*) xsl, Slice!(SliceKind.universal, [1], cdouble*) ysl);

/// ditto
void _glas_scopy(size_t n, ptrdiff_t incx, const(float)* x, ptrdiff_t incy, float* y);
/// ditto
void _glas_dcopy(size_t n, ptrdiff_t incx, const(double)* x, ptrdiff_t incy, double* y);
/// ditto
void _glas_ccopy(size_t n, ptrdiff_t incx, const(cfloat)* x, ptrdiff_t incy, cfloat* y);
/// ditto
void _glas_zcopy(size_t n, ptrdiff_t incx, const(cdouble)* x, ptrdiff_t incy, cdouble* y);

/// ditto
alias copy = glas_scopy;
/// ditto
alias copy = glas_dcopy;
/// ditto
alias copy = glas_ccopy;
/// ditto
alias copy = glas_zcopy;

/// ditto
alias copy = _glas_scopy;
/// ditto
alias copy = _glas_dcopy;
/// ditto
alias copy = _glas_ccopy;
/// ditto
alias copy = _glas_zcopy;

/++
`swap` interchanges two vectors.

Pseudo_code: `x <-> y`.

Unified_alias: `swap`

BLAS: SSWAP, DSWAP, CSWAP, ZSWAP
+/
void glas_sswap(Slice!(SliceKind.universal, [1], float*) xsl, Slice!(SliceKind.universal, [1], float*) ysl);
/// ditto
void glas_dswap(Slice!(SliceKind.universal, [1], double*) xsl, Slice!(SliceKind.universal, [1], double*) ysl);
/// ditto
void glas_cswap(Slice!(SliceKind.universal, [1], cfloat*) xsl, Slice!(SliceKind.universal, [1], float*) ysl);
/// ditto
void glas_zswap(Slice!(SliceKind.universal, [1], cdouble*) xsl, Slice!(SliceKind.universal, [1], cdouble*) ysl);

/// ditto
void _glas_sswap(size_t n, ptrdiff_t incx, float* x, ptrdiff_t incy, float* y);
/// ditto
void _glas_dswap(size_t n, ptrdiff_t incx, double* x, ptrdiff_t incy, double* y);
/// ditto
void _glas_cswap(size_t n, ptrdiff_t incx, cfloat* x, ptrdiff_t incy, cfloat* y);
/// ditto
void _glas_zswap(size_t n, ptrdiff_t incx, cdouble* x, ptrdiff_t incy, cdouble* y);

/// ditto
alias swap = glas_sswap;
/// ditto
alias swap = glas_dswap;
/// ditto
alias swap = glas_cswap;
/// ditto
alias swap = glas_zswap;

/// ditto
alias swap = _glas_sswap;
/// ditto
alias swap = _glas_dswap;
/// ditto
alias swap = _glas_cswap;
/// ditto
alias swap = _glas_zswap;

/++
Constant times a vector plus a vector.

Pseudo_code: `y += a * x`.

Unified_alias: `axpy`

BLAS: SAXPY, DAXPY, CAXPY, ZAXPY
+/
void glas_saxpy(float a, Slice!(SliceKind.universal, [1], const(float)*) xsl, Slice!(SliceKind.universal, [1], float*) ysl);
/// ditto
void glas_daxpy(double a, Slice!(SliceKind.universal, [1], const(double)*) xsl, Slice!(SliceKind.universal, [1], double*) ysl);
/// ditto
void glas_caxpy(cfloat a, Slice!(SliceKind.universal, [1], const(cfloat)*) xsl, Slice!(SliceKind.universal, [1], float*) ysl);
/// ditto
void glas_zaxpy(cdouble a, Slice!(SliceKind.universal, [1], const(cdouble)*) xsl, Slice!(SliceKind.universal, [1], cdouble*) ysl);

/// ditto
void _glas_saxpy(float a, size_t n, ptrdiff_t incx, const(float)* x, ptrdiff_t incy, float* y);
/// ditto
void _glas_daxpy(double a, size_t n, ptrdiff_t incx, const(double)* x, ptrdiff_t incy, double* y);
/// ditto
void _glas_caxpy(cfloat a, size_t n, ptrdiff_t incx, const(cfloat)* x, ptrdiff_t incy, cfloat* y);
/// ditto
void _glas_zaxpy(cdouble a, size_t n, ptrdiff_t incx, const(cdouble)* x, ptrdiff_t incy, cdouble* y);

/// ditto
alias axpy = glas_saxpy;
/// ditto
alias axpy = glas_daxpy;
/// ditto
alias axpy = glas_caxpy;
/// ditto
alias axpy = glas_zaxpy;

/// ditto
alias axpy = _glas_saxpy;
/// ditto
alias axpy = _glas_daxpy;
/// ditto
alias axpy = _glas_caxpy;
/// ditto
alias axpy = _glas_zaxpy;


/++
Applies a  plane rotation.

Unified_alias: `rot`

BLAS: SROT, DROT, CSROT, ZDROT
+/
void glas_srot(Slice!(SliceKind.universal, [1], float*) xsl, Slice!(SliceKind.universal, [1], float*) ysl, float c, float s);
/// ditto
void glas_drot(Slice!(SliceKind.universal, [1], double*) xsl, Slice!(SliceKind.universal, [1], double*) ysl, double c, double s);
/// ditto
void glas_csrot(Slice!(SliceKind.universal, [1], cfloat*) xsl, Slice!(SliceKind.universal, [1], float*) ysl, float c, float s);
/// ditto
void glas_zdrot(Slice!(SliceKind.universal, [1], cdouble*) xsl, Slice!(SliceKind.universal, [1], cdouble*) ysl, double c, double s);

/// ditto
void _glas_srot(size_t n, ptrdiff_t incx, float* x, ptrdiff_t incy, float* y, float c, float s);
/// ditto
void _glas_drot(size_t n, ptrdiff_t incx, double* x, ptrdiff_t incy, double* y, double c, double s);
/// ditto
void _glas_csrot(size_t n, ptrdiff_t incx, cfloat* x, ptrdiff_t incy, cfloat* y, float c, float s);
/// ditto
void _glas_zdrot(size_t n, ptrdiff_t incx, cdouble* x, ptrdiff_t incy, cdouble* y, double c, double s);

/// ditto
alias rot = glas_srot;
/// ditto
alias rot = glas_drot;
/// ditto
alias rot = glas_csrot;
/// ditto
alias rot = glas_zdrot;

/// ditto
alias rot = _glas_srot;
/// ditto
alias rot = _glas_drot;
/// ditto
alias rot = _glas_csrot;
/// ditto
alias rot = _glas_zdrot;


/++
Applies a modified plane rotation.

Unified_alias: `rotn`

BLAS: SROTM, DROTM
+/
void glas_srotm(Slice!(SliceKind.universal, [1], float*) xsl, Slice!(SliceKind.universal, [1], float*) ysl, ref const float[5] sparam);
/// ditto
void glas_drotm(Slice!(SliceKind.universal, [1], double*) xsl, Slice!(SliceKind.universal, [1], double*) ysl, ref const double[5] sparam);

/// ditto
void _glas_srotm(size_t n, ptrdiff_t incx, float* x, ptrdiff_t incy, float* y, ref const float[5] sparam);
/// ditto
void _glas_drotm(size_t n, ptrdiff_t incx, double* x, ptrdiff_t incy, double* y, ref const double[5] sparam);

/// ditto
alias rotm = glas_srotm;
/// ditto
alias rotm = glas_drotm;

/// ditto
alias rotm = _glas_srotm;
/// ditto
alias rotm = _glas_drotm;

/++
Forms the dot product of two vectors.
Uses unrolled loops for increments equal to one.

Unified_alias: `dot`

Pseudo_code: `X^T * Y`

BLAS: SDOT, DDOT
+/
float glas_sdot(Slice!(SliceKind.universal, [1], const(float)*) xsl, Slice!(SliceKind.universal, [1], const(float)*) ysl);
/// ditto
double glas_ddot(Slice!(SliceKind.universal, [1], const(double)*) xsl, Slice!(SliceKind.universal, [1], const(double)*) ysl);

/// ditto
float _glas_sdot(size_t n, ptrdiff_t incx, const(float)* x, ptrdiff_t incy, const(float)* y);
/// ditto
double _glas_ddot(size_t n, ptrdiff_t incx, const(double)* x, ptrdiff_t incy, const(double)* y);

/// ditto
alias dot = glas_sdot;
/// ditto
alias dot = glas_ddot;

/// ditto
alias dot = _glas_sdot;
/// ditto
alias dot = _glas_ddot;

/++
Compute the inner product of two vectors with extended
precision accumulation and result.
Uses unrolled loops for increments equal to one.

Unified_alias: `dot`

Pseudo_code: `X^T * Y`

BLAS: DSDOT
+/
double glas_dsdot(Slice!(SliceKind.universal, [1], const(float)*) xsl, Slice!(SliceKind.universal, [1], const(float)*) ysl);

/// ditto
double _glas_dsdot(size_t n, ptrdiff_t incx, const(float)* x, ptrdiff_t incy, const(float)* y);

/// ditto
alias dsdot = glas_dsdot;

/// ditto
alias dsdot = _glas_dsdot;

/++
Forms the dot product of two complex vectors.
Uses unrolled loops for increments equal to one.

Unified_alias: `dotu`

Pseudo_code: `X^T * Y`

BLAS: CDOTU, ZDOTU
+/
cfloat glas_cdotu(Slice!(SliceKind.universal, [1], const(cfloat)*) xsl, Slice!(SliceKind.universal, [1], const(cfloat)*) ysl);
/// ditto
cdouble glas_zdotu(Slice!(SliceKind.universal, [1], const(cdouble)*) xsl, Slice!(SliceKind.universal, [1], const(cdouble)*) ysl);

/// ditto
cfloat _glas_cdotu(size_t n, ptrdiff_t incx, const(cfloat)* x, ptrdiff_t incy, const(cfloat)* y);
/// ditto
cdouble _glas_zdotu(size_t n, ptrdiff_t incx, const(cdouble)* x, ptrdiff_t incy, const(cdouble)* y);

/// ditto
alias dotu = glas_cdotu;
/// ditto
alias dotu = glas_zdotu;

/// ditto
alias dotu = _glas_cdotu;
/// ditto
alias dotu = _glas_zdotu;


/++
Forms the dot product of two complex vectors.
Uses unrolled loops for increments equal to one.

Unified_alias: `dotc`

Pseudo_code: `X^H * Y`

BLAS: CDOTC, ZDOTC
+/
cfloat glas_cdotc(Slice!(SliceKind.universal, [1], const(cfloat)*) xsl, Slice!(SliceKind.universal, [1], const(cfloat)*) ysl);
/// ditto
cdouble glas_zdotc(Slice!(SliceKind.universal, [1], const(cdouble)*) xsl, Slice!(SliceKind.universal, [1], const(cdouble)*) ysl);

/// ditto
cfloat _glas_cdotc(size_t n, ptrdiff_t incx, const(cfloat)* x, ptrdiff_t incy, const(cfloat)* y);
/// ditto
cdouble _glas_zdotc(size_t n, ptrdiff_t incx, const(cdouble)* x, ptrdiff_t incy, const(cdouble)* y);

/// ditto
alias dotc = glas_cdotc;
/// ditto
alias dotc = glas_zdotc;

/// ditto
alias dotc = _glas_cdotc;
/// ditto
alias dotc = _glas_zdotc;


/++
Returns the euclidean norm of a vector via the function.

Pseudo_code: `sqrt( x'*x )`.

Unified_alias: `nrm2`

BLAS: SNRM2, DNRM2, SCNRM2, DZNRM2
+/
float glas_snrm2(Slice!(SliceKind.universal, [1], const(float)*) xsl);
/// ditto
double glas_dnrm2(Slice!(SliceKind.universal, [1], const(double)*) xsl);
/// ditto
float glas_scnrm2(Slice!(SliceKind.universal, [1], const(cfloat)*) xsl);
/// ditto
double glas_dznrm2(Slice!(SliceKind.universal, [1], const(cdouble)*) xsl);

/// ditto
float _glas_snrm2(size_t n, ptrdiff_t incx, const(float)* x);
/// ditto
double _glas_dnrm2(size_t n, ptrdiff_t incx, const(double)* x);
/// ditto
float _glas_scnrm2(size_t n, ptrdiff_t incx, const(cfloat)* x);
/// ditto
double _glas_dznrm2(size_t n, ptrdiff_t incx, const(cdouble)* x);

/// ditto
alias nrm2 = glas_snrm2;
/// ditto
alias nrm2 = glas_dnrm2;
/// ditto
alias nrm2 = glas_scnrm2;
/// ditto
alias nrm2 = glas_dznrm2;

/// ditto
alias nrm2 = _glas_snrm2;
/// ditto
alias nrm2 = _glas_dnrm2;
/// ditto
alias nrm2 = _glas_scnrm2;
/// ditto
alias nrm2 = _glas_dznrm2;

/++
Takes the sum of the absolute values.

Unified_alias: `asum`

BLAS: SASUM, DASUM, SCASUM, DZASUM
+/
float glas_sasum(Slice!(SliceKind.universal, [1], const(float)*) xsl);
/// ditto
double glas_dasum(Slice!(SliceKind.universal, [1], const(double)*) xsl);
/// ditto
float glas_scasum(Slice!(SliceKind.universal, [1], const(cfloat)*) xsl);
/// ditto
double glas_dzasum(Slice!(SliceKind.universal, [1], const(cdouble)*) xsl);

/// ditto
float _glas_sasum(size_t n, ptrdiff_t incx, const(float)* x);
/// ditto
double _glas_dasum(size_t n, ptrdiff_t incx, const(double)* x);
/// ditto
float _glas_scasum(size_t n, ptrdiff_t incx, const(cfloat)* x);
/// ditto
double _glas_dzasum(size_t n, ptrdiff_t incx, const(cdouble)* x);

/// ditto
alias asum = glas_sasum;
/// ditto
alias asum = glas_dasum;
/// ditto
alias asum = glas_scasum;
/// ditto
alias asum = glas_dzasum;

/// ditto
alias asum = _glas_sasum;
/// ditto
alias asum = _glas_dasum;
/// ditto
alias asum = _glas_scasum;
/// ditto
alias asum = _glas_dzasum;

/++
Finds the index of the first element having maximum `|Re(.)| + |Im(.)|`.

Unified_alias: `amax`

BLAS: ISAMAX, IDAMAX, ICAMAX, IZAMAX
+/
ptrdiff_t glas_isamax(Slice!(SliceKind.universal, [1], const(float)*) xsl);
/// ditto
ptrdiff_t glas_idamax(Slice!(SliceKind.universal, [1], const(double)*) xsl);
/// ditto
ptrdiff_t glas_icamax(Slice!(SliceKind.universal, [1], const(cfloat)*) xsl);
/// ditto
ptrdiff_t glas_izamax(Slice!(SliceKind.universal, [1], const(cdouble)*) xsl);

/// ditto
ptrdiff_t _glas_isamax(size_t n, ptrdiff_t incx, const(float)* x);
/// ditto
ptrdiff_t _glas_idamax(size_t n, ptrdiff_t incx, const(double)* x);
/// ditto
ptrdiff_t _glas_icamax(size_t n, ptrdiff_t incx, const(cfloat)* x);
/// ditto
ptrdiff_t _glas_izamax(size_t n, ptrdiff_t incx, const(cdouble)* x);

/// ditto
alias iamax = glas_isamax;
/// ditto
alias iamax = glas_idamax;
/// ditto
alias iamax = glas_icamax;
/// ditto
alias iamax = glas_izamax;

/// ditto
alias iamax = _glas_isamax;
/// ditto
alias iamax = _glas_idamax;
/// ditto
alias iamax = _glas_icamax;
/// ditto
alias iamax = _glas_izamax;

/++
`scal` scales a vector by a constant.

Pseudo_code: `x := a x`.

Unified_alias: `scal`

BLAS: SSSCAL, DSSCAL, CSSCAL, ZSSCAL, CSCAL, ZSCAL
+/
void glas_sscal(float a, Slice!(SliceKind.universal, [1], float*) xsl);
/// ditto
void glas_dscal(double a, Slice!(SliceKind.universal, [1], double*) xsl);
/// ditto
void glas_csscal(float a, Slice!(SliceKind.universal, [1], cfloat*) xsl);
/// ditto
void glas_cscal(cfloat a, Slice!(SliceKind.universal, [1], cfloat*) xsl);
/// ditto
void glas_csIscal(ifloat a, Slice!(SliceKind.universal, [1], cfloat*) xsl);
/// ditto
void glas_zdscal(double a, Slice!(SliceKind.universal, [1], cdouble*) xsl);
/// ditto
void glas_zscal(cdouble a, Slice!(SliceKind.universal, [1], cdouble*) xsl);
/// ditto
void glas_zdIscal(idouble a, Slice!(SliceKind.universal, [1], cdouble*) xsl);

/// ditto
void _glas_sscal(float a, size_t n, ptrdiff_t incx, float* x);
/// ditto
void _glas_dscal(double a, size_t n, ptrdiff_t incx, double* x);
/// ditto
void _glas_csscal(float a, size_t n, ptrdiff_t incx, cfloat* x);
/// ditto
void _glas_cscal(cfloat a, size_t n, ptrdiff_t incx, cfloat* x);
/// ditto
void _glas_csIscal(ifloat a, size_t n, ptrdiff_t incx, cfloat* x);
/// ditto
void _glas_zdscal(double a, size_t n, ptrdiff_t incx, cdouble* x);
/// ditto
void _glas_zscal(cdouble a, size_t n, ptrdiff_t incx, cdouble* x);
/// ditto
void _glas_zdIscal(idouble a, size_t n, ptrdiff_t incx, cdouble* x);

/// ditto
alias scal = glas_sscal;
/// ditto
alias scal = glas_dscal;
/// ditto
alias scal = glas_csscal;
/// ditto
alias scal = glas_cscal;
/// ditto
alias scal = glas_csIscal;
/// ditto
alias scal = glas_zdscal;
/// ditto
alias scal = glas_zscal;
/// ditto
alias scal = glas_zdIscal;

/// ditto
alias scal = _glas_sscal;
/// ditto
alias scal = _glas_dscal;
/// ditto
alias scal = _glas_csscal;
/// ditto
alias scal = _glas_cscal;
/// ditto
alias scal = _glas_csIscal;
/// ditto
alias scal = _glas_zdscal;
/// ditto
alias scal = _glas_zscal;
/// ditto
alias scal = _glas_zdIscal;
