module dcompute.driver.ocl.device;

import derelict.opencl.cl;
import dcompute.driver.ocl;

struct Device
{
    enum Type : int
    {
        default_     = 0x1,
        CPU         = 0x2,
        GPU         = 0x4,
        accelerator = 0x8,
        custom      = 0x10,
        all         = 0xFFFFFFFF
    }
    
    enum AffinityDomain
    {
        numa        = 0x1,
        l4_Cache    = 0x2,
        l3_Cache    = 0x4,
        l2_Cache    = 0x8,
        l1_Cache    = 0x10,
        nextPartitionable = 0x20
    }
    
    enum PartitionProperty
    {
        Equally          = 0x1086,
        ByCounts         = 0x1087,
        ByCountsListEnd  = 0,
        ByAffinityDomain = 0x1088,
    }
    
    enum FPConfig
    {
        denorm                  = 1 << 0,
        infNan                  = 1 << 1,
        roundNearest            = 1 << 2,
        roundZero               = 1 << 3,
        rounfInf                = 1 << 4,
        fma                     = 1 << 5,
        softFloat               = 1 << 6,
        correctlyRoundedDivSqrt = 1 << 7,
    }
    
    enum MemoryCacheType
    {
        none = 0,
        readOnly = 1,
        readWrite = 2,
    }
    
    enum LocalMemoryType
    {
        local,
        global,
    }
    
    enum ExecutionCapabilities
    {
        kernel,
        nativeKernel,
    }
    
    static struct Info
    {
        @(0x1000) Type type;
        @(0x1001) uint vendorID;
        @(0x1002) uint maxComputeUnits;
        @(0x1003) uint _maxWorkItemDimensions;
        @(0x1004) size_t maxWorkGroupSize;
        @(0x1005) size_t* _maxWorkItemSizes;
        ArrayAccesssor!(_maxWorkItemSizes,_maxWorkItemDimensions) maxWorkItems;
        @(0x1006) uint preferredVectorWidthByte;
        @(0x1007) uint preferredVectorWidthShort;
        @(0x1008) uint preferredVectorWidthInt;
        @(0x1009) uint preferredVectorWidthLong;
        @(0x100A) uint preferredVectorWidthFloat;
        @(0x100B) uint preferredVectorWidthDouble;
        @(0x100C) uint maxClockFrequency;
        @(0x1000) uint addressBits;
        @(0x100E) uint maxReadImageArgs;
        @(0x100F) uint maxWriteImageArgs;
        @(0x1010) ulong maxMemoryAllocSize;
        @(0x1011) size_t image2DMaxWidth;
        @(0x1012) size_t image2DMaxHeight;
        @(0x1013) size_t image3DMaxWidth;
        @(0x1014) size_t image3DMaxHeight;
        @(0x1015) size_t image3DMaxDepth;
        @(0x1016) bool imageSupport;
        @(0x1017) size_t maxParameterSize;
        @(0x1018) uint maxSamplers;
        @(0x1019) uint memeoryBaseAddressAlign;
        @(0x101A) uint minDataTypeAlignSize;        // Deprecated in OpenCl 1.2
        @(0x101B) FPConfig floatFPConfig;
        @(0x101C) MemoryCacheType GLobalMemoryCacheType;
        @(0x101D) uint  globalMemoryCachelineSize;
        @(0x101E) ulong globalMemoryCacheSize;
        @(0x101F) ulong globalMemorySize;
        @(0x1020) ulong maxConstantBufferSize;
        @(0x1021) uint  maxConstantArgs;
        @(0x1022) LocalMemoryType localMemoryType;
        @(0x1023) ulong localMemorySize;
        @(0x1024) bool errorCorrectionSupport;
        @(0x1025) size_t profilingTimerResolution;
        @(0x1026) bool endianLittle;
        @(0x1027) bool available;
        @(0x1028) bool compilerAvailable;
        @(0x1029) ExecutionCapabilities executionCapabilities;
        @(0x102A) Queue.Properties queueProperties;
        @(0x102B) char* _name;
        @(0x102C) char* _vendor;
        @(0x102D) char* _driverVersion;
        @(0x102E) char* _profile;
        @(0x102F) char* _deviceVersion;
        @(0x1030) char* _extensions;
        
        StringzAccessor!(_name) name;
        StringzAccessor!(_vendor) vendor;
        StringzAccessor!(_driverVersion) driverVersion;
        StringzAccessor!(_profile) profile;
        StringzAccessor!(_deviceVersion) deviceVersion;
        StringzAccessor!(_extensions) extensions;
        
        @(0x1031) Platform platform;
        @(0x1032) FPConfig doubleFPConfig;
        @(0x1033) FPConfig halfFPConfig;
        @(0x1034) uint pefferedVectorWidthHalf;
        @(0x1035) bool hostUnifiedMemory;
        @(0x1036) uint nativeVectorWidthByte;
        @(0x1037) uint nativeVectorWidthShort;
        @(0x1038) uint nativeVectorWidthInt;
        @(0x1039) uint nativeVectorWidthLong;
        @(0x103A) uint nativeVectorWidthFloat;
        @(0x103B) uint nativeVectorWidthDouble;
        @(0x103C) uint nativeVectorWidthHalf;
        @(0x103D) char* _OpenCLCVersion;
        StringzAccessor!(_OpenCLCVersion) OpenCLCVersion;
        @(0x103E) bool linkerAvailable;
        @(0x103F) char* _builtinKernels;
        StringzAccessor!(_builtinKernels) builtinKernels;
        @(0x1040) size_t imageMaxBufferSize;
        @(0x1041) size_t imageMaxArraySize;
        @(0x1042) Device parentDevice;
        @(0x1043) uint partitionMaxSubDevices;
        //@(0x1044) PartitionProperty* _partitionProperties;
        //ZeroTerminatedArrayAccessor!(_partitionProperties) partitionProperties;
        @(0x1045) AffinityDomain partitionAffinityDomain;
        //@(0x1046) PartitionProperty* _partitionType;
        //ZeroTerminatedArrayAccessor!(_partitionType) partitionType;
        @(0x1047) uint peferenceCount;
        @(0x1048) bool prefferedInteropUserSync;
        @(0x1049) size_t printfBufferSize;
        
        // Extensions
        //@(0x200F) khrTeminateCapability;
        //@(0x4000) nvComputeCapabilityMajor;
        //@(0x4001) nvComputeCapabilityMinor;
        //@(0x4002) nvRegistersPerBlock;
        //@(0x4003) nvWarpSize;
        //@(0x4004) nvGPUOverlap;
        //@(0x4005) nvKerenlExecTimeout;
        //@(0x4006) nvIntegratedMemory;
        
        //@(0x4036) amdProfilingTimerOffset
    }
    
    cl_device_id raw;

    mixin(generateGetInfo!(Info,clGetDeviceInfo));
    
    //Is this a double call function? Also what to do about properties
    //its zero terminated an can contain numbers
    //see http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clCreateSubDevices.html under the examples
    /*Device[] createSubDevices(cl.device_partition_property[] properites
                                cl.uint_ numSubDevices)
    {
        
    }
    */

    void retain()
    {
        status = cast(Status)clRetainDevice(raw);
        checkErrors();
    }
    
    void release()
    {
        status = cast(Status)clReleaseDevice(raw);
        checkErrors();
    }
    
}
