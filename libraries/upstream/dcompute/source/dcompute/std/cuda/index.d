@compute(CompileFor.deviceOnly) module dcompute.std.cuda.index;

import ldc.dcompute;
pure: nothrow: @nogc:
//tid = threadId
pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.tid.x")
uint tid_x();

pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.tid.y")
uint tid_y();

pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.tid.z")
uint tid_z();

//ntid = blockDim
pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.ntid.x")
uint ntid_x();

pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.ntid.y")
uint ntid_y();

pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.ntid.z")
uint ntid_z();

//ctaid = blockIdx
pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.ctaid.x")
uint ctaid_x();

pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.ctaid.y")
uint ctaid_y();

pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.ctaid.z")
uint ctaid_z();

//nctaid = gridDim
pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.nctaid.x")
uint nctaid_x();

pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.nctaid.y")
uint nctaid_y();

pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.nctaid.z")
uint nctaid_z();

//warpsize
pragma(LDC_intrinsic, "llvm.nvvm.read.ptx.sreg.warpsize")
uint warpsize();


