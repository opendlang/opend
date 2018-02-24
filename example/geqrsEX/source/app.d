import std.stdio;

import mir.ndslice.slice;
import mir.ndslice.topology;
import mir.ndslice.allocation;

import mir.lapack;

void main()
{
    auto a =
            [ 1,  1,  0,
              1,  0,  1,
              0,  1,  1 ]
              .sliced(3, 3)
              .as!double.slice
              .canonical;
    auto b =
            [ 1,  1,  1,
              1,  1,  1,
              1,  1,  1 ]
              .sliced(3, 3)
              .as!double.slice
              .canonical;
    auto c = b.slice.canonical;

    auto work = [double.sizeof * a.length].uninitSlice!double;
    auto tau = (cast(int) min(a.length!0, a.length!1)).uninitSlice!double;
    geqrf(a, tau, work);
    geqrs(a, b, tau, work);
    auto k = uninitSlice!double(3, 3);
    k[] = 0;
    foreach(i;0..a.length!0)
    {
        foreach(j;0..b.length!1)
        {
            foreach(m;0..a.length!1)
            {
                k[i][j] += a[i][m] * b[m][j];
            }
        }
    }
    
    import std.math: approxEqual;
    import mir.ndslice.algorithm: all;
    assert(all!approxEqual(k, c));
}
