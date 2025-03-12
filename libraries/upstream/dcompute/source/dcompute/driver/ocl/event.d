module dcompute.driver.ocl.event;

import dcompute.driver.ocl;

struct Event
{
    cl_event raw;
    enum EnqueuedCommand
    {
        kernel            = 0x11F0,
        task              = 0x11F1,
        nativeKernel      = 0x11F2,
        bufferRead        = 0x11F3,
        bufferWrite       = 0x11F4,
        bufferCopy        = 0x11F5,
        imageRead         = 0x11F6,
        imageWrite        = 0x11F7,
        imageCopy         = 0x11F8,
        imageToBufferCopy = 0x11F9,
        bufferToImageCopy = 0x11FA,
        bufferMap         = 0x11FB,
        imageMap          = 0x11FC,
        unmap             = 0x11FD,
        marker            = 0x11FE,
        acquireGLObjects  = 0x11FF,
        releaseGLObjects  = 0x1200,
        bufferRectRead    = 0x1201,
        bufferRectWrite   = 0x1202,
        bufferRectCopy    = 0x1203,
        user              = 0x1204,
        barrier           = 0x1205,
        migrate           = 0x1206,
        bufferFill        = 0x1207,
        imageFill         = 0x1208,
        
        // Extensions
        acquireD3D10Objects = 0x4017,
        releaseD3D10Objects = 0x4018,
        acquireDX9MediaSurfaces = 0x202B,
        releaseDX9MediaSurfaces = 0x202C,
        acquireD3D11Objects = 0x4020,
        releaseD3D11Objects = 0x4021,
        GLFenceSyncObject   = 0x200D,
        EGLFenceSyncObject  = 0x202F,
        acquireEGLObjects   = 0x202D,
        releaseEGLObjects   = 0x202E,

    }
    
    
    enum EcexutionStatus
    {
        complete  = 0x0,
        running   = 0x1,
        submitted = 0x2,
        queued    = 0x3,
    }
    static struct Info
    {
        @(0x11D0) Queue queue;
        @(0x11D1) EnqueuedCommand type;
        @(0x11D2) uint referenceCount;
        @(0x11D3) EcexutionStatus status;
        @(0x11D4) Context context;
    }
    //mixin(generateGetInfo!(Info,clGetEventInfo));
    
    void retain()
    {
        status = cast(Status)clRetainEvent(raw);
        checkErrors();
    }
    
    void release()
    {
        status = cast(Status)clReleaseEvent(raw);
        checkErrors();
    }
    void wait()
    {
        clWaitForEvents(1,&raw);
    }
}

void wait(Event[] e)
{
    clWaitForEvents(cast(uint)e.length,cast(cl_event*)e.ptr);
}
