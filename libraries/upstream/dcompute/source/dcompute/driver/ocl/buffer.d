module dcompute.driver.ocl.buffer;

import dcompute.driver.ocl;

struct Buffer(T)
{
    cl_mem raw;

    // Host memory associated with this buffer
    T[] hostMemory;
    enum CreateType
    {
        region =0x1220,
    }
    // opSlice clCreateSubBuffer
}
