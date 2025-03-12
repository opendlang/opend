module dcompute.driver.ocl.image;

import dcompute.driver.ocl;
struct Image
{
    cl_mem raw;
    
    enum ChannelOrder
    {
        r            = 0x10B0,
        a            = 0x10B1,
        rg           = 0x10B2,
        ra           = 0x10B3,
        rgb          = 0x10B4,
        rgba         = 0x10B5,
        bgra         = 0x10B6,
        argb         = 0x10B7,
        intesity     = 0x10B8,
        luminance    = 0x10B9,
        Rx           = 0x10BA,
        RGx          = 0x10BB,
        RGBx         = 0x10BC,
        depth        = 0x10BD,
        depthStencil = 0x10BE,
    }
    
    enum  ChannelType
    {
        snormInt8      = 0x10D0,
        snormInt16     = 0x10D1,
        unormInt8      = 0x10D2,
        unormInt16     = 0x10D3,
        uormShort565   = 0x10D4,
        uormShort555   = 0x10D5,
        unormInt101010 = 0x10D6,
        byte_          = 0x10D7,
        short_         = 0x10D8,
        int_           = 0x10D9,
        ubyte_         = 0x10DA,
        ushort_        = 0x10DB,
        uint_          = 0x10DC,
        half_          = 0x10DD,
        float_         = 0x10DE,
        unormInt24     = 0x10DF,
    }
    static struct Format
    {
        ChannelOrder order;
        ChannelType  type;
    }
    static struct Info
    {
        @(0x1110) Format format;
        @(0x1111) size_t elementSize;
        @(0x1112) size_t rowPitch;
        @(0x1113) size_t slicePitch;
        @(0x1114) size_t width;
        @(0x1115) size_t height;
        @(0x1116) size_t depth;
        @(0x1117) size_t arraySize;
        @(0x1118) Memory memory;
        @(0x1119) uint mipLevels;
        @(0x111A) uint samples;
        
        // Extensions
        //@(0x4016) D3D10_SUBRESOURCE_KHR
        //@(0x401F) D3D11_SUBRESOURCE_KHR
        //@(0x202A) DX9_MEDIA_PLANE_KHR
    }
    //mixin(generateGetInfo!(Info,clGetImageInfo));
}
