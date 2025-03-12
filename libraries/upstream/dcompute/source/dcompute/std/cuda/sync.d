@compute(CompileFor.deviceOnly) module dcompute.std.cuda.sync;

import ldc.dcompute;

pragma(LDC_intrinsic, "llvm.nvvm.barrier0")
void barrier0();

pragma(LDC_intrinsic, "llvm.nvvm.barrier0.and")
int barrier0_and(int);

pragma(LDC_intrinsic, "llvm.nvvm.barrier0.or")
int barrier0_or(int);

pragma(LDC_intrinsic, "llvm.nvvm.barrier0.popc")
int barrier0_popc(int);

//block memory barrier
pragma(LDC_intrinsic, "llvm.nvvm.membar.cta")
void membar_cta();

//device global
pragma(LDC_intrinsic, "llvm.nvvm.membar.gl")
void membar_gl();

//system global
pragma(LDC_intrinsic, "llvm.nvvm.membar.sys")
void membar_sys();

