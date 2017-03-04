/**
* Copyright: Copyright Auburn Sounds 2016.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.types;

version(LDC):

public import core.simd;

alias __m64 = long; // Note: operation using __m64 are not available.
alias __m128 = float4;
alias __m128i = int4;
alias __m128d = double2;

int _MM_SHUFFLE2(int x, int y) pure nothrow @nogc @safe
{
    assert(x >= 0 && x <= 1);
    assert(y >= 0 && y <= 1);
    return (x << 1) | y;
}

int _MM_SHUFFLE(int z, int y, int x, int w)
{
    assert(x >= 0 && x <= 3);
    assert(y >= 0 && y <= 3);
    assert(z >= 0 && z <= 3);
    assert(w >= 0 && w <= 3);
    return (z<<6) | (y<<4) | (x<<2) | w;
}



