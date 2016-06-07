/**
* Copyright: Copyright Auburn Sounds 2016.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module inteli.types;

version(LDC):

public import core.simd;

alias __m64 = long;
alias __m128 = float4;
alias __m128i = int4;
alias __m128d = double2;