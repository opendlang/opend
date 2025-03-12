@compute(CompileFor.deviceOnly) module dcompute.std.opencl.sync;

import ldc.dcompute;

extern(C) void barrier();

extern(C) void mem_fence(ulong);

extern(C) void read_mem_fence();

extern(C) void write_mem_fence();
