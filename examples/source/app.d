// betterC code style
import mir.ndslice.slice;
import mir.ndslice.topology;
import mir.ndslice.allocation;

import mir.lapack;

// column major storage
__gshared double[9] a = [
     1.0,  2, -1,
    -1.0,  2,  5,
     1.0, -4,  0];
// ditto
__gshared double[6] b = [
    2.0, -6, 9,
    0  , -6, 1];
// ditto
__gshared double[6] t = [
     1.0, 2, 3,
    -1.0, 0, 1];

__gshared lapackint[3] ipiv = [0, 0, 0];

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
    // Canonical kind is required
    auto as = a[].sliced(3, 3).canonical;
    auto bs = b[].sliced(2, 3).canonical;
    auto ts = b[].sliced(2, 3).canonical;
    auto ipivs = ipiv[].sliced(3);

    // Solve systems of linear equations AX = B for X.
    // X stores in B
    auto info = gesv(as, ipivs, bs);

    if (info)
        return cast(int)(info << 1);

    // Check result
    if (bs != ts)
        return 1;


    auto A_ = A[].sliced(3, 3).canonical;
    auto B_ = B[].sliced(3, 3).canonical;
    auto C_ = C[].sliced(3, 3).canonical;
    auto work_ = work[].sliced(double.sizeof).canonical;
    auto tau_ = tau[].sliced(3).canonical;
    geqrf(A_, tau_, work_);
    geqrs(A_, B_, tau_, work_);
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
    
    import std.math: approxEqual;
    import mir.ndslice.algorithm: all;
    if(!all!approxEqual(K_, C_))
        return 2;

    // OK
    return 0;
}
