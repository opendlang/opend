module dcompute.driver.ocl.kernel;

import dcompute.driver.ocl;

struct Kernel(F) if (is(F == function) || is(F==void))
{
    cl_kernel raw;
    
    static struct Info
    {
        @(0x1190) immutable char* _name;
        StringzAccessor!(_name) name;
        @(0x1191) uint numArgs;
        @(0x1192) uint referenceCount;
        @(0x1193) Context context;
        @(0x1194) Program program;
        @(0x1195) immutable char* _attributes;
        StringzAccessor!(_attributes) attributes;
    }
    //mixin(generateGetInfo!(Info,clGetKernelInfo));
    void retain()
    {
        status = cast(Status)clRetainKernel(raw);
        checkErrors();
    }
    
    void release()
    {
        status = cast(Status)clReleaseKernel(raw);
        checkErrors();
    }
    
    void setArg(T)(uint index,T val)
    {
        status = cast(Status)clSetKernelArg(this.raw,index,T.sizeof,&val);
        checkErrors();
    }
}

struct Arg
{
    Kernel!void kernel;
    uint argIndex;
    enum AddressQualifier
    {
        global   = 0x119B,
        local    = 0x119C,
        constant = 0x119D,
        private_ = 0x119E,
    }
    
    enum AccessQualifier
    {
        readOnly  = 0x11A0,
        writeOnly = 0x11A1,
        readWrite = 0x11A2,
        none      = 0x11A3,
    }
    
    enum TypeQualifier
    {
        none     = 0,
        const_   = 1 << 0,
        restrict = 1 << 1,
        volatile = 1 << 2,
    }
    
    static struct Info
    {
        @(0x1196) AddressQualifier addressQualifier;
        @(0x1197) AccessQualifier accessQualifier;
        @(0x1198) immutable char* _typeName;
        StringzAccessor!(_typeName) typeName;
        @(0x1199) TypeQualifier typeQualifier;
        @(0x119A) immutable char* _name;
        StringzAccessor!(_name) name;
    }
    
    //mixin(generateGetInfo!(Info,clGetKernelArgInfo,"kernel.raw,argIndex"));
}

struct WorkGroup
{
    Kernel!void kernel;
    Device device;
    static struct Info
    {
        @(0x11B0) size_t workGroupSize;
        @(0x11B1) size_t[3] requiredWorkGroupSize;
        @(0x11B2) ulong localMemorySize;
        @(0x11B3) size_t preferredWorkGroupSizeMultiple;
        @(0x11B4) ulong privateMemSize;
        @(0x11B5) size_t[3] globalWorkSize;
    }
    
    //mixin(generateGetInfo!(Info,clGetKernelWorkGroupInfo,"kernel.raw,device.raw"));
}
