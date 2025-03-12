module dcompute.driver.ocl.program;

import dcompute.driver.ocl;
import std.string : toStringz;

struct Program
{
    static struct Info
    {
        @(0x1160) uint referneceCount;
        @(0x1161) Context context;
        
        @(0x1162) uint _numDevices;
        @(0x1163) Device* _devices;
        ArrayAccesssor!(_devices,_numDevices) devices;
        
        @(0x1164) char* _source;
        StringzAccessor!(_source) source;
        
        @(0x1165) size_t* _binarySizes;
        @(0x1166) ubyte** _binaries;
        @(0x1167) size_t  _numKernels;
        ArrayAccesssor2D!(_binaries,_binarySizes,_numKernels) binaries;
        
        @(0x1168) char* _kernelNames;
        StringzAccessor!(_kernelNames) kernelNames;
    }
    static Program globalProgram;
    cl_program raw;
    mixin(generateGetInfo!(Info,clGetProgramInfo));
    void retain()
    {
        status = cast(Status)clRetainProgram(raw);
        checkErrors();
    }
    
    void release()
    {
        status = cast(Status)clReleaseProgram(raw);
        checkErrors();
    }
    void build(Device[] devices, string options)
    {
        status = cast(Status)clBuildProgram(raw,
                                cast(uint)devices.length,cast(cl_device_id*)devices.ptr,
                                options.toStringz,
                                null,null);
        checkErrors();
    }
    
    Kernel!(typeof(sym)) getKernel(alias sym)()
    {
        Kernel!void ret = getKernel(sym.mangleof);
        return cast(typeof(return))ret;
    }
    Kernel!void getKernel(string name)
    {
        Kernel!void ret;
        ret.raw = clCreateKernel(this.raw,name.toStringz,cast(int*)&status);
        checkErrors();
        return ret;
    }
    
}



struct Build
{
    Program program;
    Device  device;
    enum  BinaryType
    {
        none       = 0x0,
        object     = 0x1,
        library    = 0x2,
        executable = 0x4,
    }
    
    enum Status
    {
        success    =  0,
        none       = -1,
        error      = -2,
        inProgress = -3,
    }
    
    static struct Info
    {
        @(0x1181) Status status;
        @(0x1182) char* _options;
        StringzAccessor!(_options) options;
        @(0x1183) char* _log;
        StringzAccessor!(_log) log;
        @(0x1184) BinaryType binaryType;
    }
    mixin(generateGetInfo!(Info,clGetProgramBuildInfo,"program.raw,device.raw"));
}
