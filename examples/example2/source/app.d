import mir.ndslice.slice;
import mir.ndslice.topology;
import mir.ndslice.allocation;

import mir.lapack;

__gshared double[9] A =
                [ 1,  1,  0,
                  1,  0,  1,
                  0,  1,  1 ];

__gshared double[9] B =
                [ 1,  1,  1,
                  1,  1,  1,
                  1,  1,  1 ];

__gshared double[9] C =
                [ 1,  1,  1,
                  1,  1,  1,
                  1,  1,  1 ];
__gshared double[double.sizeof * 3] work;
__gshared double[3] tau;
__gshared double[9] K;

nothrow @nogc extern(C)
int main()
{
    auto A_ = A[].sliced(3, 3).canonical;
    auto B_ = B[].sliced(3, 3).canonical;
    auto C_ = C[].sliced(3, 3).canonical;
    auto work_ = work[].sliced(double.sizeof).canonical;
    auto tau_ = tau[].sliced(3).canonical;
    geqrf(A_, tau_, work_);

    auto K_ = K[].sliced(3, 3).canonical;
    K_[] = 0;
    foreach(i;0..A_.length!0)
    {
        foreach(j;0..B_.length!1)
        {
            foreach(m;0..A_.length!1)
            {
                K_[i][j] += A_[i][m] * B_[m][j];
            }
        }
    }
    return 0;
}
