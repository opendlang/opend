import glas.ndslice;
import mir.ndslice;

alias T = cdouble;

int main()
{
    auto a = slice!T(3, 3).universal;
    a[] =
        [[-2 + 0i, T.init, T.init],
         [+3 + 2i, -5 + 0i, T.init],
         [-4 + 7i, -2 + 3i, -3 + 0i]];

    auto b = slice!T(3, 4).universal;
    b[] =
        [[-5 + 3i, -3 + 9i,  3 + 2i, 1 + 2i],
         [ 4 + 5i,  3 + 4i,  6 + 5i, 4 + 9i],
         [-4 + 2i, -2 + 2i, -2 + 7i, 2 + 6i]];

    auto c = slice!T(3, 4).universal;
    auto d = slice!T(3, 4).universal;
    auto alpha = 1 + 0i;
    auto beta  = 0 + 0i;

    if(auto error_code = validate_symm(a.structure, b.structure, c.structure))
    {
        import core.stdc.stdio;
        puts(glas_error(error_code).ptr);
        return 1;
    }

    symm(alpha, a, b, beta, c, ConjA | Left | Lower);

    foreach(i; 0 .. a.length)
    foreach(j; i+1 .. a.length)
        a[i, j] = a[j, i].re - a[j, i].im * 1fi;

    gemm(alpha, a, b, beta, d);

    return all!"a == b"(c, d) ? 0 : -1;
}
