import glas.ndslice;
import mir.ndslice;

alias T = double;

int main()
{
    auto a = slice!T(3, 5).universal;
    a[] =
        [[-5,  1,  7, 7, -4],
         [-1, -5,  6, 3, -3],
         [-5, -2, -3, 6,  0]];

    auto b = slice!T(5, 4).universal;
    b[] =
        [[-5.0, -3,  3,  1],
         [ 4.0,  3,  6,  4],
         [-4.0, -2, -2,  2],
         [-1.0,  9,  4,  8],
         [  9.0, 8,  3, -2]];

    auto c = slice!T(3, 4).universal;

    auto alpha = 1.0;
    auto beta  = 0.0;

    if(auto error_code = validate_gemm(a.structure, b.structure, c.structure))
    {
        import core.stdc.stdio;
        puts(glas_error(error_code).ptr);
        return 1;
    }

    gemm(alpha, a, b, beta, c);

    return c ==
        [[-42.0,  35,  -7, 77],
         [-69.0, -21, -42, 21],
         [ 23.0,  69,   3, 29]] ? 0 : -1;
}
