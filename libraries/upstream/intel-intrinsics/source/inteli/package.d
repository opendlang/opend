/**
* Public API. You can `import inteli;` if want access to all intrinsics, under any circumstances.
* That's the what intel-intrinsics enables.
*
* Copyright: Copyright Guillaume Piolat 2016-2020.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module inteli; 

// Importing with `import inteli;` simply imports all available intrinsics.
public import inteli.types;
public import inteli.mmx;        // MMX
public import inteli.emmintrin;  // SSE
public import inteli.xmmintrin;  // SSE2
public import inteli.pmmintrin;  // SSE3
public import inteli.tmmintrin;  // SSSE3
public import inteli.smmintrin;  // SSE4.1
public import inteli.nmmintrin;  // SSE4.2
public import inteli.shaintrin;  // SHA
public import inteli.bmi2intrin; // BMI2
public import inteli.avxintrin;  // AVX
public import inteli.avx2intrin; // AVX2

public import inteli.math; // Bonus

