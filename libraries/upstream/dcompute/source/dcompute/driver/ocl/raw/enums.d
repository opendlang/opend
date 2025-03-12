module dcompute.driver.ocl.raw.enums;

import dcompute.driver.ocl;

enum //: profiling_info
{
    PROFILING_COMMAND_QUEUED = 0x1280,
    PROFILING_COMMAND_SUBMIT = 0x1281,
    PROFILING_COMMAND_START  = 0x1282,
    PROFILING_COMMAND_END    = 0x1283,
}

// device_partition_property_ext extension
enum
{
    DEVICE_PARTITION_EQUALLY_EXT             = 0x4050,
    DEVICE_PARTITION_BY_COUNTS_EXT           = 0x4051,
    DEVICE_PARTITION_BY_NAMES_EXT            = 0x4052,
    DEVICE_PARTITION_BY_AFFINITY_DOMAIN_EXT  = 0x4053,
}

// clDeviceGetInfo selectors
enum
{
    DEVICE_PARENT_DEVICE_EXT                 = 0x4054,
    DEVICE_PARTITION_TYPES_EXT               = 0x4055,
    DEVICE_AFFINITY_DOMAINS_EXT              = 0x4056,
    DEVICE_REFERENCE_COUNT_EXT               = 0x4057,
    DEVICE_PARTITION_STYLE_EXT               = 0x4058,
}

// AFFINITY_DOMAINs
enum
{
    AFFINITY_DOMAIN_L1_CACHE_EXT             = 0x1,
    AFFINITY_DOMAIN_L2_CACHE_EXT             = 0x2,
    AFFINITY_DOMAIN_L3_CACHE_EXT             = 0x3,
    AFFINITY_DOMAIN_L4_CACHE_EXT             = 0x4,
    AFFINITY_DOMAIN_NUMA_EXT                 = 0x10,
    AFFINITY_DOMAIN_NEXT_FISSIONABLE_EXT     = 0x100,
}

// device_partition_property_ext list terminators
enum
{
    PROPERTIES_LIST_END_EXT          =  0,
    PARTITION_BY_COUNTS_LIST_END_EXT =  0,
    PARTITION_BY_NAMES_LIST_END_EXT  =  0 - 1,
}


// egl.h

// gl.h

// gl_object_type
enum
{
    GL_OBJECT_BUFFER                         = 0x2000,
    GL_OBJECT_TEXTURE2D                      = 0x2001,
    GL_OBJECT_TEXTURE3D                      = 0x2002,
    GL_OBJECT_RENDERBUFFER                   = 0x2003,
    GL_OBJECT_TEXTURE2D_ARRAY                = 0x200E,
    GL_OBJECT_TEXTURE1D                      = 0x200F,
    GL_OBJECT_TEXTURE1D_ARRAY                = 0x2010,
    GL_OBJECT_TEXTURE_BUFFER                 = 0x2011,
}

// gl_texture_info
enum
{
    GL_TEXTURE_TARGET                        = 0x2004,
    GL_MIPMAP_LEVEL                          = 0x2005,
    GL_NUM_SAMPLES                           = 0x2012,
}

// gl_context_info
enum
{
    CURRENT_DEVICE_FOR_GL_CONTEXT_KHR        = 0x2006,
    DEVICES_FOR_GL_CONTEXT_KHR               = 0x2007,
}


// d3d10_device_source_nv
enum
{
    D3D10_DEVICE_KHR                             = 0x4010,
    D3D10_DXGI_ADAPTER_KHR                       = 0x4011,
}

// d3d10_device_set_nv
enum
{
    PREFERRED_DEVICES_FOR_D3D10_KHR              = 0x4012,
    ALL_DEVICES_FOR_D3D10_KHR                    = 0x4013,
}

// d3d11_device_source
enum
{
    D3D11_DEVICE_KHR                             = 0x4019,
    D3D11_DXGI_ADAPTER_KHR                       = 0x401A,
}

// d3d11_device_set
enum
{
    PREFERRED_DEVICES_FOR_D3D11_KHR              = 0x401B,
    ALL_DEVICES_FOR_D3D11_KHR                    = 0x401C,
}

// media_adapter_type_khr
enum
{
    ADAPTER_D3D9_KHR                             = 0x2020,
    ADAPTER_D3D9EX_KHR                           = 0x2021,
    ADAPTER_DXVA_KHR                             = 0x2022,
}

// media_adapter_set_khr
enum
{
    PREFERRED_DEVICES_FOR_DX9_MEDIA_ADAPTER_KHR  = 0x2023,
    ALL_DEVICES_FOR_DX9_MEDIA_ADAPTER_KHR        = 0x2024,
}

