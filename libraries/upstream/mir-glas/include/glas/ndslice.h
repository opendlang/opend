#ifndef Have_GLAS
#define Have_GLAS
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif

enum
{
	glas_ConjA = 0x1,
	glas_ConjB = 0x2,
	glas_Lower = 0x0,
	glas_Left = 0x0,
	glas_Upper = 0x0100,
	glas_Right = 0x0200,
};

struct glas_MatrixStructure
{
	size_t lengths[2];
	ptrdiff_t strides[2];
};

struct glas_MutVector
{
	size_t lengths[1];
	ptrdiff_t strides[1];
	void* ptr;
};

struct glas_ConstVector
{
	size_t lengths[1];
	ptrdiff_t strides[1];
	const void *ptr;
};

struct glas_MutMatrix
{
	size_t lengths[2];
	ptrdiff_t strides[2];
	void* ptr;
};

struct glas_ConstMatrix
{
	size_t lengths[2];
	ptrdiff_t strides[2];
	const void *ptr;
};

struct ErrorString
{
	size_t length;
	const char *ptr; // zero terminated
};

struct ErrorString glas_error(int error_code);
int glas_validate_gemm(struct glas_MatrixStructure as, struct glas_MatrixStructure bs, struct glas_MatrixStructure cs, unsigned long settings);
int glas_validate_symm(struct glas_MatrixStructure as, struct glas_MatrixStructure bs, struct glas_MatrixStructure cs, unsigned long settings);

void glas_sswap(struct glas_MutVector xsl, struct glas_MutVector ysl);
void glas_dswap(struct glas_MutVector xsl, struct glas_MutVector ysl);
void glas_cswap(struct glas_MutVector xsl, struct glas_MutVector ysl);
void glas_zswap(struct glas_MutVector xsl, struct glas_MutVector ysl);
void _glas_sswap(size_t n, size_t incx, float* x, size_t incy, float* y);
void _glas_dswap(size_t n, size_t incx, double* x, size_t incy, double* y);
void _glas_cswap(size_t n, size_t incx, float _Complex* x, size_t incy, float _Complex* y);
void _glas_zswap(size_t n, size_t incx, double _Complex* x, size_t incy, double _Complex* y);

void glas_scopy(struct glas_ConstVector xsl, struct glas_MutVector ysl);
void glas_dcopy(struct glas_ConstVector xsl, struct glas_MutVector ysl);
void glas_ccopy(struct glas_ConstVector xsl, struct glas_MutVector ysl);
void glas_zcopy(struct glas_ConstVector xsl, struct glas_MutVector ysl);
void _glas_scopy(size_t n, size_t incx, const float* x, size_t incy, float* y);
void _glas_dcopy(size_t n, size_t incx, const double* x, size_t incy, double* y);
void _glas_ccopy(size_t n, size_t incx, const float _Complex* x, size_t incy, float _Complex* y);
void _glas_zcopy(size_t n, size_t incx, const double _Complex* x, size_t incy, double _Complex* y);

void glas_saxpy(float a, struct glas_MutVector xsl, struct glas_MutVector ysl);
void glas_daxpy(double a, struct glas_MutVector xsl, struct glas_MutVector ysl);
void glas_caxpy(float _Complex a, struct glas_MutVector xsl, struct glas_MutVector ysl);
void glas_zaxpy(float _Complex a, struct glas_MutVector xsl, struct glas_MutVector ysl);
void _glas_saxpy(float a, size_t n, size_t incx, float* x, size_t incy, float* y);
void _glas_daxpy(double a, size_t n, size_t incx, double* x, size_t incy, double* y);
void _glas_caxpy(float _Complex a, size_t n, size_t incx, float _Complex* x, size_t incy, float _Complex* y);
void _glas_zaxpy(float _Complex a, size_t n, size_t incx, double _Complex* x, size_t incy, double _Complex* y);

float glas_snrm2(struct glas_ConstVector xsl);
double glas_dnrm2(struct glas_ConstVector xsl);
float glas_scnrm2(struct glas_ConstVector xsl);
double glas_dznrm2(struct glas_ConstVector xsl);
float _glas_snrm2(size_t n, size_t incx, const float* x);
double _glas_dnrm2(size_t n, size_t incx, const double* x);
float _glas_scnrm2(size_t n, size_t incx, const float _Complex* x);
double _glas_dznrm2(size_t n, size_t incx, const double _Complex* x);

float glas_sasum(struct glas_ConstVector xsl);
double glas_dasum(struct glas_ConstVector xsl);
float glas_scasum(struct glas_ConstVector xsl);
double glas_dzasum(struct glas_ConstVector xsl);
float _glas_sasum(size_t n, size_t incx, const float* x);
double _glas_dasum(size_t n, size_t incx, const double* x);
float _glas_scasum(size_t n, size_t incx, const float _Complex* x);
double _glas_dzasum(size_t n, size_t incx, const double _Complex* x);

ptrdiff_t glas_isamax(struct glas_ConstVector xsl);
ptrdiff_t glas_idamax(struct glas_ConstVector xsl);
ptrdiff_t glas_icamax(struct glas_ConstVector xsl);
ptrdiff_t glas_izamax(struct glas_ConstVector xsl);
ptrdiff_t _glas_isamax(size_t n, size_t incx, const float* x);
ptrdiff_t _glas_idamax(size_t n, size_t incx, const double* x);
ptrdiff_t _glas_icamax(size_t n, size_t incx, const float _Complex* x);
ptrdiff_t _glas_izamax(size_t n, size_t incx, const double _Complex* x);

void glas_sscal(float a, struct glas_MutVector xsl);
void glas_dscal(double a, struct glas_MutVector xsl);
void glas_csscal(float a, struct glas_MutVector xsl);
void glas_cscal(float _Complex a, struct glas_MutVector xsl);
void glas_csIscal(float a, struct glas_MutVector xsl);
void glas_zdscal(double a, struct glas_MutVector xsl);
void glas_zscal(double _Complex a, struct glas_MutVector xsl);
void glas_zdIscal(double a, struct glas_MutVector xsl);

void _glas_sscal(float a, size_t n, size_t incx, float* x);
void _glas_dscal(double a, size_t n, size_t incx, double* x);
void _glas_csscal(float a, size_t n, size_t incx, float _Complex* x);
void _glas_cscal(float _Complex a, size_t n, size_t incx, float _Complex* x);
void _glas_csIscal(float a, size_t n, size_t incx, float _Complex* x);
void _glas_zdscal(double a, size_t n, size_t incx, double _Complex* x);
void _glas_zscal(double _Complex a, size_t n, size_t incx, double _Complex* x);
void _glas_zdIscal(double a, size_t n, size_t incx, double _Complex* x);

void glas_sgemm(float alpha, struct glas_ConstMatrix asl, struct glas_ConstMatrix bsl, float beta, struct glas_MutMatrix csl, unsigned long settings);
void glas_dgemm(double alpha, struct glas_ConstMatrix asl, struct glas_ConstMatrix bsl, double beta, struct glas_MutMatrix csl, unsigned long settings);
void glas_cgemm(float _Complex alpha, struct glas_ConstMatrix asl, struct glas_ConstMatrix bsl, float _Complex beta, struct glas_MutMatrix csl, unsigned long settings);
void glas_zgemm(double _Complex alpha, struct glas_ConstMatrix asl, struct glas_ConstMatrix bsl, double _Complex beta, struct glas_MutMatrix csl, unsigned long settings);

void glas_ssymm(float alpha, struct glas_ConstMatrix asl, struct glas_ConstMatrix bsl, float beta, struct glas_MutMatrix csl, unsigned long settings);
void glas_dsymm(double alpha, struct glas_ConstMatrix asl, struct glas_ConstMatrix bsl, double beta, struct glas_MutMatrix csl, unsigned long settings);
void glas_csymm(float _Complex alpha, struct glas_ConstMatrix asl, struct glas_ConstMatrix bsl, float _Complex beta, struct glas_MutMatrix csl, unsigned long settings);
void glas_zsymm(double _Complex alpha, struct glas_ConstMatrix asl, struct glas_ConstMatrix bsl, double _Complex beta, struct glas_MutMatrix csl, unsigned long settings);

#ifdef __cplusplus
}
#endif
#endif
