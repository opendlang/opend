module dcompute.driver.ocl.memory;

import dcompute.driver.ocl;

struct Memory
{
    enum Type
    {
        buffer         = 0x10F0,
        image2D        = 0x10F1,
        image3D        = 0x10F2,
        image2Darray   = 0x10F3,
        image1D        = 0x10F4,
        image1Darray   = 0x10F5,
        image1Dbuffer = 0x10F6,
    }
    
    enum Flags
    {
        none                = 0,
        readWrite           = 1 << 0,
        writeOnly           = 1 << 1,
        readOnly            = 1 << 2,
        useHostPointer      = 1 << 3,
        allocateHostPointer = 1 << 4,
        copyHostPointer     = 1 << 5,
        //reserved            1 << 6,
        hostReadWrite       = 1 << 7,
        hostReadOnly        = 1 << 8,
        hostNoAccess        = 1 << 9,
    }
    
    static struct Info
    {
        @(0x1100) Type type;
        @(0x1101) Flags flags;
        @(0x1102) size_t size;
        @(0x1103) void* hostPointer;
        @(0x1104) uint mapCount;
        @(0x1105) uint referenceCount;
        @(0x1106) Context context;
        @(0x1107) Memory associatedMemory;
        @(0x1108) size_t offset;
        
        // Extensions
        //@(0x4015) D3D10_RESOURCE_KHR
        //@(0x401E) D3D10_RESOURCE_KHR
        //@(0x2028) DX9_MEDIA_ADAPTER_TYPE_KHR
        //@(0x2029) DX9_MEDIA_SURFACE_INFO_KHR
    }
    cl_mem raw;
    
    //mixin(generateGetInfo!(Info,clGetMemObjectInfo));
    void retain()
    {
        status = cast(Status)clRetainMemObject(raw);
        checkErrors();
    }
    void release()
    {
        status = cast(Status)clReleaseMemObject(raw);
        checkErrors();
    }
}
