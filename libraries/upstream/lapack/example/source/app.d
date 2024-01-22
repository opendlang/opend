// betterC code style
static import lapack;
import lapack: lapackint;

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

nothrow @nogc extern(C)
int main()
{
    lapackint n    = 3;
    lapackint nrhs = 2;
    lapackint lda  = 3;
    lapackint ldb  = 3;
    lapackint info = void;

    // Solve systems of linear equations AX = B for X.
    // X stores in B
    lapack.gesv_(n, nrhs, a.ptr, lda, ipiv.ptr, b.ptr, ldb, info);

    if (info)
        return cast(int)(info << 1);

    // Check result
    foreach (i; 0 .. n * nrhs)
        if (b[i] != t[i])
            return 1;
    // OK
    return 0;
}
