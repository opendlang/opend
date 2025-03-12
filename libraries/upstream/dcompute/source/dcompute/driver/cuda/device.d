module dcompute.driver.cuda.device;

import dcompute.driver.cuda;

struct Device
{
    int raw;
    //struct CUdevprop
    static struct Info
    {
        @(1)  int maxThreadsPerBlock;
        @(2)  int maxThreadsDimX;
        @(3)  int maxThreadsDimY;
        @(4)  int maxThreadsDimZ;
        @(5)  int maxGridSizeX;
        @(6)  int maxGridSizeY;
        @(7)  int maxGridSizeZ;
        @(8)  int sharedMemPerBlock;
        @(9)  int totalConstantMemory;
        @(10) int SIMDWidth; // warp size
        @(11) int maxPitch;
        @(12) int regsPerBlock;
        @(13) int clockRate;
        @(14) int textureAlign;
        @(15) int GPUOverlap;
        @(16) int multiprocessorCount;
        @(17) int kernelExecTimeout;
        @(18) int integrated;
        @(19) int canMapHostMemeory;
        @(20) int computeMode;
        @(21) int maxTexture1DWidth;
        @(22) int maxTexture2DWidth;
        @(23) int maxTexture2DHeight;
        @(24) int maxTexture3DWidth;
        @(25) int maxTexture3DHeight;
        @(26) int maxTexture3DDepth;
        @(27) int maxTexture2DLayeredWidth;
        @(28) int maxTexture2DLayeredHeight;
        @(29) int maxTexture2DLayeredLayers;
        @(27) int maxTexture2DArrayWidth;
        @(28) int maxTexture2DArrayHeight;
        @(29) int maxTexture2DArrayNumSlices;
        @(30) int surfaceAlignment;
        @(31) int concurrentKernels;
        @(32) int eccEnabled;
        @(33) int PCIBusID;
        @(34) int PCIDeviceID;
        @(35) int tccDriver;
        @(36) int memoryClockRate;
        @(37) int globalMemoryBusWidth;
        @(38) int L2CacheSize;
        @(39) int maxThreadPerMultiProcessor;
        @(40) int asyncEngineCount;
        @(41) int unifiedAddressing;
        @(42) int maxTexture1DLayeredWidth;
        @(43) int maxTexture1DLayeredLayers;
        @(44) int canTex2DGather;
        @(45) int maxTextrue2DGatherWidth;
        @(46) int maxTextrue2DGatherHeight;
        @(47) int maxTexture3DWidthAlternative;
        @(48) int maxTexture3DHeightAlternative;
        @(49) int maxTexture3DDepthAlternative;
        @(50) int PICDomainID;
        @(51) int texturePitchAlignment;
        @(52) int textureCubemapWidth;
        @(53) int textureCubemapLayeredWidths;
        @(54) int textureCubemapLayeredLayers;
        @(55) int maxSurface1DWidth;
        @(56) int maxSurface2DWidth;
        @(57) int maxSurface2DHeight;
        @(58) int maxSurface3DWidth;
        @(59) int maxSurface3DHeight;
        @(60) int maxSurface3DDepth;
        @(61) int maxSurface1DLayeredWidth;
        @(62) int maxSurface1DLayeredLayers;
        @(63) int maxSurface2DLayeredWidth;
        @(64) int maxSurface2DLayeredHeight;
        @(65) int maxSurface2DLayeredLayers;
        @(66) int maxSurfaceCubemapWidth;
        @(67) int maxSurfaceCubemapLayeredWidth;
        @(68) int maxSurfaceCubemapLayeredLayers;
        @(69) int maxTaxture1DLinearWidth;
        @(70) int maxTaxture2DLinearWidth;
        @(71) int maxTaxture2DLinearHeight;
        @(72) int maxTaxture2DLinearPitch;
        @(73) int maxTaxture2DMipmappedWidth;
        @(74) int maxTaxture2DMipmappedHeight;
        @(75) int computeCapabilityMajor;
        @(76) int computeCapabilityMinor;
        @(77) int maxTaxture1DMipmappedWidth;
        @(78) int streamPrioritiesSupported;
        @(79) int globalL1CacheSupported;
        @(80) int localL1CacheSupported;
        @(81) int maxSharedMemoryPerMultiprocessor;
        @(82) int maxRegistorsPerMultiprocessor;
        @(83) int managedMemory;
        @(84) int multiGPUBoard;
        @(85) int multiGPUBoardGroupID;
    }
    
    @property size_t totalMemory()
    {
        size_t ret;
        status = cast(Status)cuDeviceTotalMem(&ret,raw);
        checkErrors();
        return ret;
    }
    
    //char[] name : cuDeviceGetName

    static foreach (mem; __traits(allMembers, Info)) {
        mixin(
            ` @property int `,
            mem,
            ` () { int result; `,
            ` status = cast(Status)cuDeviceGetAttribute( `,
            ` &result, `,
             __traits(getAttributes, __traits(getMember, Info, mem))[0].stringof,
            `, raw); `,
            ` checkErrors(); `,
            ` return result; `,
            ` } `);
    }
}
