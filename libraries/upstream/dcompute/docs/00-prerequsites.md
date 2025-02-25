# Prerequisites

In order to use DCompute there are a few things you need before you start:

* Capable hardware

* Drivers for said hardware

* LDC: the LLVM D compiler

## Hardware & Drivers

For NVidia users any GPU with compute capability 2.1 or higher should work, 
although the hardware will dictate the available functionality.
You'll need to intall the CUDA development tools.

For everyone else you will need either a CPU or GPU (or other accellerator) 
with an OpenCL 2.1 or higher device implementation.

## LDC

Due to the fact that DCompute leverages the LLVM NVPTX (for CUDA) & SPIR-V (for OpenCL)
backends to generate compute kernel code.

To see what targets your version of LDC has, execute `ldc2 -version`.
We aim to support the most recent releases of LDC, but due to the nature of development
some features in DCompute are dependent on features of LDC that may require upgrading your
compiler.

If you wish to be on the bleeding edge we recommend building LLVM & LDC from source. 
Be warned that LLVM has the tendency to break compatibility with LDC so expect that you may
have to revert syncing with LLVM. This goes the other way too fixing LDC to be compatible 
with LLVM trunk will likely break it with a slightly older trunk.

