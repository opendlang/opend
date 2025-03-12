@compute(CompileFor.deviceOnly) module dcompute.std.warp;

import ldc.dcompute;
/*Warp functions
 *Vote:
 * int  any(int pred) - true if any lanes `pred` is true
 * int  all(int pred) - true iff all lanes `pred` are true
 * ulong ballot(int pred) - ith bit is set if pred is true for the ith lane
 *
 *Shuffle:
 * T shuffle(T val, int lane, int width=warpsize)
 * T shuffle_{up,down}(T val, uint lane_delta,int width=warpsize)
 * T shuffle_xor(T val, int lane_mask,int width=warpsize)
 *
 *Reduction:
 * T reduce!op(T val)
 * T inclusive_scan!op(T val)
 * T exclusive_scan!op(T val)
 */
