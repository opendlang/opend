// betterC code style
import mir.ndslice.slice: sliced;
import mir.ndslice.topology: canonical;
import mir.lapack: gesv, lapackint;

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

    // OK
    return 0;
}
