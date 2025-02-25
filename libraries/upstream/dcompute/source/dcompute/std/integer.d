@compute(CompileFor.hostAndDevice) module dcompute.std.integer;

import ldc.dcompute;

/*
 brev - bit reverse
 sad  - sum of absolute differences
 abs
 min
 max
 add_sat
 sub_sat
 mul_hi
 mul_low
 mad
 mad_hi
 mad_lo
 mad_hi_sat
 mul24_hi
 mul24_lo
 mad24_hi
 mad24_lo
 mad24_hi_sat
sm2.0 or higher
 popc   - count the number of set bits
 clz    - count the number of leading zeros
 bfind  - find most significant non-sign bit
 bfe    - bit field extract
 bfi    - bit field insert
 overflow arithmetic
 ctz - count trailing zeros
 rotate
 */
