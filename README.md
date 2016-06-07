# intel-intrinsics

The goal is to allow you to use Intel intrinsics in D code.

Why Intel intrinsic syntax? Because it is more familier to C++ programmers and there is a convenient online guide provided by Intel: https://software.intel.com/sites/landingpage/IntrinsicsGuide/

For now only LDC is supported.

## Usage

```d

import inteli.xmmintrin; // allows SSE1 intrinsics
import inteli.emmintrin; // allows SSE2 intrinsics

```

**This library is an incomplete work in progress.**
