# intel-intrinsics

![Travis Status](https://travis-ci.org/p0nce/intel-intrinsics.svg?branch=master)

The goal is to allow you to use Intel intrinsics in D code.

Why Intel intrinsic syntax? Because it is more familiar to C++ programmers and there is a convenient online guide provided by Intel: https://software.intel.com/sites/landingpage/IntrinsicsGuide/

For now only LDC is supported.
But be sure to know about the superior SIMD capabilities of LDC exposed in `ldc.simd`.

## Usage

```d

import inteli.xmmintrin; // allows SSE1 intrinsics
import inteli.emmintrin; // allows SSE2 intrinsics

// distance between two points in 4D
float distance(float[4] a, float[4] b) nothrow @nogc
{
    __m128 va = _mm_loadu_ps(a.ptr);
    __m128 vb = _mm_loadu_ps(b.ptr);
    __m128 diffSquared = _mm_sub_ps(va, vb);
    diffSquared = _mm_mul_ps(diffSquared, diffSquared);
    __m128 sum = _mm_add_ps(diffSquared, _mm_srli_si128!8(diffSquared));
    sum = _mm_add_ps(sum, _mm_srli_si128!4(sum));
    return _mm_cvtss_f32(_mm_sqrt_ss(sum));
}
assert(distance([0, 2, 0, 0], [0, 0, 0, 0]) == 2);

```

## Supported instructions set

- SSE1
- SSE2
