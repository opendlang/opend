@compute(CompileFor.deviceOnly) module dcompute.std.sync;

import ldc.dcompute;

import ocl  = dcompute.std.opencl.sync;
import cuda = dcompute.std.cuda.sync;

//suspends work-item execution until all work-items in the work-group have called the barrier
void barrier()
{
    if(__dcompute_reflect(ReflectTarget.OpenCL))
        ocl.barrier();
    if(__dcompute_reflect(ReflectTarget.CUDA))
        cuda.barrier0();
}

void local_fence()
{
    if(__dcompute_reflect(ReflectTarget.OpenCL))
        ocl.mem_fence(0);
    if(__dcompute_reflect(ReflectTarget.CUDA))
        cuda.membar_cta();
}
// A global fence implies a local fence
void global_fence()
{
    if(__dcompute_reflect(ReflectTarget.OpenCL))
        ocl.mem_fence(1);
    if(__dcompute_reflect(ReflectTarget.CUDA))
        cuda.membar_gl();
}

//TODO: image fence?


