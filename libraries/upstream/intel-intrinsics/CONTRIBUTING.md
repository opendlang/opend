Advice:

- **GODBOLT EVERYTHING YOU COMMIT**

- Do intrinsics **one by one**, not all at once. This is very detailed work, it's not possible nor desirable to go fast while writing intrinsics. Please don't.

- Add PERF comment anywhere you feel that something could be done faster in a supported combination: DMD D_SIMD, LDC x86_64, LDC arm64, LDC x86, GDC x86_64, with or without optimizations, with or without instruction support... 
  * If this is supposed returns a SIMD literal, does it inline?
  * Can this be faster in -O0?
  * If instruction support is not there, is the alternative path fast?


To be merged a PR:

- need one unittest per intrinsic
- need a slow path that works on all compilers
- fast paths (actual intrinsics) can be added later, but is probably your real interest
- intrinsic order should be like in the Intrinsics Guide page: https://software.intel.com/sites/landingpage/IntrinsicsGuide/#othertechs=SHA
- add yourself to the Copyright list

Your PR doesn't have to implement every intrinsic in a given instruction set. It's best to do one intrinsics right, than several half-done, giving work to the maintainer.