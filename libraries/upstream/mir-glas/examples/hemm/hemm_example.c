// gcc -std=c99 -I../../include -c hemm_example.c -o hemm_example.o
// gcc hemm_example.o -L../../ -lmir-glas -lmir-cpuid -o hemm_example
// ./hemm_example
#include <complex.h>
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
    double _Complex a_payload[] =
        {-2 + 0i,   0/0.0,  0/0.0,
         +3 + 2i, -5 + 0i,  0/0.0,
         -4 + 7i, -2 + 3i, -3 + 0i};

    double _Complex b_payload[] =
        {-5 + 3i, -3 + 9i,  3 + 2i, 1 + 2i,
          4 + 5i,  3 + 4i,  6 + 5i, 4 + 9i,
         -4 + 2i, -2 + 2i, -2 + 7i, 2 + 6i};

    double _Complex c_payload[3 * 4];
    double _Complex d_payload[3 * 4];

    struct glas_ConstMatrix a = toConstMatrix(create_matrix(3, 3, a_payload));
    struct glas_ConstMatrix b = toConstMatrix(create_matrix(3, 4, b_payload));
    struct glas_MutMatrix c = create_matrix(3, 4, c_payload);
    struct glas_MutMatrix d = create_matrix(3, 4, d_payload);

    double _Complex alpha = 5 + 3i;
    double _Complex beta  = 0;

    glas_zsymm(alpha, a, b, beta, c, glas_ConjA | glas_Left | glas_Lower);

    // Check using general matrix-matrix multiplicaiton (GEMM)
    // .. initilize Upper part of A
    for(size_t i = 0; i < 3; i++)
    {
        for(size_t j = i + 1; j < 3; j++)
        {
            double _Complex *u = (double _Complex *)a.ptr + i * a.strides[0] + j * a.strides[1];
            double _Complex *v = (double _Complex *)a.ptr + i * a.strides[1] + j * a.strides[0];
            *u = creal(*v) - cimag(*v) * 1i;
        }
    }
    // Perform GEMM
    glas_zgemm(alpha, a, b, beta, d, 0);

    // Results should be identical
    for(size_t i = 0; i < 3; i++)
    {
        for(size_t j = 0; j < 4; j++)
        {
            double _Complex u = *((double _Complex *)c.ptr + i * c.strides[0] + j * c.strides[1]);
            double _Complex v = *((double _Complex *)d.ptr + i * d.strides[0] + j * d.strides[1]);
            if (u != v)
            {
                puts("hemm_example: Error");
                return -1;
            }
        }
    }

    return 0;
}
