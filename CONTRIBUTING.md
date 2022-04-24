To be merged a PR:

- need one unittest per intrinsic
- need a slow path that works on all compilers
- fast paths (actual intrinsics) can be added later, but is probably your real interest ^^
- intrinsic order should be like in the Intrinsics Guide page: https://software.intel.com/sites/landingpage/IntrinsicsGuide/#othertechs=SHA
- add yourself to the Copyright list

Your PR doesn't have to implement every intrinsic in a given instruction set.
