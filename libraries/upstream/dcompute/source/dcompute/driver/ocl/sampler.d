module dcompute.driver.ocl.sampler;

import dcompute.driver.ocl;
struct Sampler
{
    enum FilterMode
    {
        nearest = 0x1140,
        linear  = 0x1141,
    }
    
    enum AddressingMode
    {
        none           = 0x1130,
        clampToEdge    = 0x1131,
        clamp          = 0x1132,
        repeat         = 0x1133,
        mirroredRepeat = 0x1134,
    }
    static struct Info
    {
        @(0x1150) uint referenceCount;
        @(0x1151) Context context;
        @(0x1152) bool normalisedCoordinates; // CHECKME is this actually a bool?
        @(0x1153) AddressingMode addressingMode;
        @(0x1154) FilterMode filterMode;
    }

    cl_sampler raw;
    
    //mixin(generateGetInfo!(Info,clGetSamplerInfo));
    void retain()
    {
        status = cast(Status)clRetainSampler(raw);
        checkErrors();
    }
    
    void release()
    {
        status = cast(Status)clReleaseSampler(raw);
        checkErrors();
    }
    
}
