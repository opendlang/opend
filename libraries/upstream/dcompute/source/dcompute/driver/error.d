/**/

module dcompute.driver.error;

// Helpfully OpenCL errors are negative and CUDAs are positive
enum Status : int {
    Success = 0,
    // CUDA Errors.
    invalidValue                = 1,
    outOfMemory                 = 2,
    notInitialized              = 3,
    deinitialized               = 4,
    profilerDisabled            = 5,
    profilerNotInitialized      = 6,
    profilerAlreadyStarted      = 7,
    profilerAlradyStopped       = 8,
    noDevice                    = 100,
    invalidDevice               = 101,
    invalidImage                = 200,
    invalidContext              = 201,
    contextAlreadyCurrent       = 202,
    mapFailed                   = 205,
    unmapFailed                 = 206,
    arrayIsMapped               = 207,
    alreadyMapped               = 208,
    noBinaryForGPU              = 209,
    alreadyAcquired             = 210,
    notMapped                   = 211,
    notMappedAsArray            = 212,
    notMappedAsPointer          = 213,
    eccUncorrectable            = 214,
    unsupportedLimit            = 215,
    contextAlredyInUse          = 216,
    peerAccessUnsupported       = 217,
    invalidPtx                  = 218,
    invalidGraphicsContext      = 219,
    nvlinkUncorrectable         = 220,
    jitCompilerNotFound         = 221,
    invalidSource               = 300,
    fileNotFound                = 301,
    sharedObjectSymbolNotFound  = 302,
    sharedObjectInitFailed      = 303,
    operatingSystem             = 304,
    invalidHandle               = 400,
    illegalState                = 401,
    notFound                    = 500,
    notReady                    = 600,
    illegalAddress              = 700,
    launchOutOfResources        = 701,
    launchTimeout               = 702,
    launchIncompatibleTexturing = 703,
    peerAccessAlreadyEnabled    = 704,
    peerAccessNotEnabled        = 705,
    primaryContextActive        = 708,
    contextIsDestroyed          = 709,
    assertError                 = 710,
    tooManyPeers                = 711,
    hostMemoryAlreadyRegistered = 712,
    hostMemoryNotRegistered     = 713,
    hardwareStackError          = 714,
    illegalInstruction          = 715,
    misalignedAddress           = 716,
    invalidAddressSpace         = 717,
    invalidPC                   = 718,
    launchFailed                = 719,
    cooperativeLaunchTooLarge   = 720,
    notPermitted                = 800,
    notSupported                = 801,
    systemNotReady              = 802,
    systemDriverMismatch        = 803,
    compatNotSupportedOnDevice  = 804,
    streamCaptureUnsupported    = 900,
    streamCaptureInvalidated    = 901,
    streamCaptureMerge          = 902,
    streamCaptureUnmatched      = 903,
    streamCaptureUnjoined       = 904,
    streamCaptureIsolation      = 905,
    streamCaptureImplicit       = 906,
    capturedEvent               = 907,
    streamCaptureWrongThread    = 908,
    unknown                     = 999,

    // OpenCL Errors.
    deviceNotFound                 = -1,
    deviceNotAvailable             = -2,
    compilerNotAvailable           = -3,
    memoryObjectAloocationFailure  = -4,
    outOfResources                 = -5,
    outOfHostMemory                = -6,
    profilingInfomationAvailable   = -7,
    memoryCopyOverlap              = -8,
    imageFormatMismatch            = -9,
    imageFormatNotSupported        = -10,
    buildProgramFailed             = -11,
    mapFailure                     = -12,
    misalignedSubBufferOffset      = -13,
    errorsInWaitList               = -14,
    compileProgramFailure          = -15,
    linkerNotAvailable             = -16,
    linkerFailure                  = -17,
    devicePartitionFailure         = -18,
    kernelArgInfoNotAvailable      = -19,
    
    invalidValueCL                 = -30,
    invalidDeviceType              = -31,
    invalidPlatform                = -32,
    invalidDeviceCL                = -33,
    invalidContextCL               = -34,
    invalidQueueProperties         = -35,
    invalidQueue                   = -36,
    invalidHostPointerCL           = -37,
    invalidMemoryObject            = -38,
    invalidImageFormatDesctiptor   = -39,
    invalidImageSize               = -40,
    invalidSampler                 = -41,
    invalidBinary                  = -42,
    invalidBuildOptions            = -43,
    invalidProgram                 = -44,
    invalidExecutable              = -45,
    invalidKernelName              = -46,
    invalidKernelDefinition        = -47,
    invalidKernel                  = -48,
    invalidArgumentIndex           = -49,
    invalidArgumentValue           = -50,
    invalidArgumentSize            = -51,
    invalidKernelArguments         = -52,
    invalidWorkDimensions          = -53,
    invaildWorkGroupSize           = -54,
    invaildWorkItemSize            = -55,
    invalidGlobalOffest            = -56,
    invalidEventWaitList           = -57,
    invalidEvent                   = -58,
    invalidOperation               = -59,
    invalidGLObject                = -60,
    invalidBufferSize              = -61,
    invalidMipLevel                = -62,
    invalidGlobalWorkSize          = -63,
    invalidProperty                = -64,
    invalidImageDescriptor         = -65,
    invalidCompilerOptions         = -66,
    invalidLinkerOptions           = -67,
    invalidDevicePartitionCount    = -68,
    
    invalidGLSharegroupReference   = -1000,
    platformNotFound               = -1001,
    invalidD3D10Device             = -1002,
    invalidD3D10Resource           = -1003,
    D3D10ResouceAlreadyAcquired    = -1004,
    D3D10ResourceNotAcquires       = -1005,
    invalidD3D11Device             = -1006,
    invalidD3D11Resource           = -1007,
    D3D11ResourceAlredyAcquired    = -1008,
    D3D11ResourceNotAcquired       = -1009,
    invalidDX9MediaAdapter         = -1010,
    invalidDX9MediaSurface         = -1011,
    DX9MediaSurfaceAlreadyAcquired = -1012,
    DX9MediaSurfaceNotAcquired     = -1013,
    
    devicePartitionFailed          = -1057,
    invalidPartitionCount          = -1058,
    invalidPartitionName           = -1059,
    
    invalidEGLObject               = -1093,
    EGLResourceNotAcquired         = -1092,
}

version (D_BetterC)
{
    void delegate (Status) nothrow @nogc onDriverError = (Status _status) 
    { 
        defaultOnDriverError(_status);
    };
    
    immutable void delegate (Status) nothrow @nogc defaultOnDriverError = 
    (Status _status)
    {
        import core.stdc.stdio : fprintf, stderr;
        import std.conv : to;
        fprintf(stderr,"*** DCompute driver error:%s\n",
               _status.to!(string).toStringz);
    };
}
else
{
    class DComputeDriverException : Exception
    {
        this(string msg, string file = __FILE__,
             size_t line = __LINE__, Throwable next = null)
        {
            super(msg, file, line, next);
        }
        
        this(Status err, string file = __FILE__, 
             size_t line = __LINE__, Throwable next = null)
        {
            import std.conv : to;
            super(err.to!string, file, line, next);
        }
    }
    void delegate(Status) onDriverError = (Status _status) 
    {
        defaultOnDriverError(_status);
    };
    immutable void delegate(Status) defaultOnDriverError =
    (Status _status)
    {
        throw new DComputeDriverException(_status);
    };
}

// Thread local status
Status status;

version(DComputeIgnoreDriverErrors)
{
    void checkErrors() {}
}
else
{
    void checkErrors()
    {
        if (status) onDriverError(status);
    }

}
