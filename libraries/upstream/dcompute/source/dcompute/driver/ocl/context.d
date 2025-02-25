module dcompute.driver.ocl.context;

import dcompute.driver.ocl;
import std.typecons;

import std.experimental.allocator.typed;

struct Context
{
    cl_context raw;
    
    enum Properties
    {
        platform        = 0x1084,
        interopUserSync = 0x1085,
    }
    
    static struct Info
    {
        @(0x1080) uint referenceCount;
        @(0x1081) Device* _devices;
        @(0x1082) Context.Properties* properties;
        @(0x1083) uint numDevices;
        ArrayAccesssor!(_devices,numDevices) devices;
        // Extensions
        //@(0x2010) khrTerminate;
        //@(0x200E) khrMemoryInitialise;
        //@(0x4014) CONTEXT_D3D10_DEVICE_KHR
        //@(0x402C) CONTEXT_D3D10_PREFER_SHARED_RESOURCES_KHR
        //@(0x401D) CONTEXT_D3D11_DEVICE_KHR
        //@(0x402D) CONTEXT_D3D11_PREFER_SHARED_RESOURCES_KHR
        //@(0x2025) CONTEXT_ADAPTER_D3D9_KHR
        //@(0x2026) CONTEXT_ADAPTER_D3D9EX_KHR
        //@(0x2027) CONTEXT_ADAPTER_DXVA_KHR
        //@(0x2008) GL_CONTEXT_KHR
        //@(0x2009) EGL_DISPLAY_KHR
        //@(0x200A) GLX_DISPLAY_KHR
        //@(0x200B) WGL_HDC_KHR
        //@(0x200C) CGL_SHAREGROUP_KHR

    }
    //mixin(generateGetInfo!(Info,clGetContextInfo));
    
    this(Device[] devs,const Properties[] props)
    {
        raw = clCreateContext(cast(const cl_context_properties*)props.ptr,
                              cast(uint)devs.length,cast(const cl_device_id*)devs.ptr,
                              null,null,
                              cast(int*)&status);
        checkErrors();
    }
    
    this(Device.Type type,const Properties[] props)
    {
        raw = clCreateContextFromType(cast(const cl_context_properties*)props.ptr,
                                      cast(cl_device_type)type,
                                      null,null,
                                      cast(int*)&status);
        checkErrors();
    }
    void retain()
    {
        status = cast(Status)clRetainContext(raw);
        checkErrors();
    }
    
    void release()
    {
        status = cast(Status)clReleaseContext(raw);
        checkErrors();
    }
    
    Queue createQueue(Device dev,Queue.Properties prop)
    {
        Queue ret;
        ret.raw = clCreateCommandQueue(this.raw,
                                       dev.raw,
                                       cast(cl_command_queue_properties)prop,
                                       cast(int*)&status);
        checkErrors();
        return ret;
    }
    
    Buffer!T createBuffer(T)(T[] arr,Memory.Flags flags = (Memory.Flags.useHostPointer | Memory.Flags.readWrite))
    {
        import std.stdio;
        Buffer!T ret;
        auto len = memSize(arr);
        ret.raw = clCreateBuffer(raw,flags,len,arr.ptr,cast(int*)&status);
        ret.hostMemory = arr;
        checkErrors();
        return ret;
    }
    
    /*Image.Format[] supportedImageFormats(A)(A allocator, Memory.Flags f,Memory.Type t)
    {
        //Double call
        clGetSupportedImageFormats
    }*/
    
    Sampler createSampler(Flag!"normalisedCoordinates" f,
                          Sampler.AddressingMode aMode,
                          Sampler.FilterMode fMode)
    {
        Sampler ret;
        ret.raw = clCreateSampler(this.raw,
                                  cast(cl_bool)f,
                                  cast(cl_addressing_mode)aMode,
                                  cast(cl_filter_mode)fMode,
                                  cast(int*)&status);
        checkErrors();
        return ret;
    }
    
    /**Program createProgramFromSource(string[][] sources)
     {
        clCreateProgramWithSource
     }
    */
    
    Program createProgramFromSPIR(A)(A a, Device[] devices,ubyte[] spir)
    {
        auto allocator = TypedAllocator!(A)(a);
        auto lengths = allocator.makeArray!(size_t)(devices.length);
        lengths[]    = spir.length;
        auto ptrs  = allocator.makeArray!(ubyte*)(devices.length);
        ptrs[]       = spir.ptr;
        Program ret;

        ret.raw = clCreateProgramWithBinary(
                                this.raw,
                                cast(uint)devices.length, cast(cl_device_id*)devices.ptr,
                                lengths.ptr,ptrs.ptr,
                                null, // TODO report individual errors
                                cast(int*)&status);
        allocator.dispose(lengths);
        allocator.dispose(ptrs);
        return ret;
    }
    Program createProgram(void[] spirv)
    {
        Program ret;

        ret.raw = clCreateProgramWithIL(this.raw,
										spirv.ptr,
										spirv.length,
										cast(int*)&status);
        return ret;
    }
    
    /*Program createProgramFromBuiltinKernels(Device[] devices, string kernelNames)
    {
        clCreateProgramWithBuiltInKernels
    }*/
}
