// gcc -std=c99 -I../../include -c gemm_example.c -o gemm_example.o
// gcc gemm_example.o -L../../ -lmir-glas -lmir-cpuid -o gemm_example
// ./gemm_example
#include <stdio.h>
#include <string.h>
#include "glas/ndslice.h"

struct glas_MutMatrix create_matrix(size_t m, size_t n, void *data)
{
	struct glas_MutMatrix matrix;
	matrix.lengths[0] = m;
	matrix.lengths[1] = n;
	matrix.strides[0] = n;
	matrix.strides[1] = 1;
	matrix.ptr = data;
	return matrix;
}

struct glas_ConstMatrix toConstMatrix(struct glas_MutMatrix mut)
{
	struct glas_ConstMatrix matrix;
	matrix.lengths[0] = mut.lengths[0];
	matrix.lengths[1] = mut.lengths[1];
	matrix.strides[0] = mut.strides[0];
	matrix.strides[1] = mut.strides[1];
	matrix.ptr        = mut.ptr;
	return matrix;
}

int main()
{
    double a_payload[] =
        {-5,  1,  7, 7, -4,
         -1, -5,  6, 3, -3,
         -5, -2, -3, 6,  0};

    double b_payload[] =
        {-5.0, -3,  3,  1,
          4.0,  3,  6,  4,
         -4.0, -2, -2,  2,
         -1.0,  9,  4,  8,
           9.0, 8,  3, -2};

    double c_payload[3 * 4];
    double d_payload[] =
        {-42.0,  35,  -7, 77,
         -69.0, -21, -42, 21,
          23.0,  69,   3, 29};

    struct glas_ConstMatrix a = toConstMatrix(create_matrix(3, 5, a_payload));
    struct glas_ConstMatrix b = toConstMatrix(create_matrix(5, 4, b_payload));
    struct glas_MutMatrix c = create_matrix(3, 4, c_payload);

    double alpha = 1.0;
    double beta  = 0.0;
    glas_dgemm(alpha, a, b, beta, c, 0);
    if(memcmp(c.ptr, d_payload, sizeof(double) * 3 * 4))
    {
    	puts("gemm_example: Error");
    	return -1;
    }
    return 0;
}
