module dcompute.driver.cuda.program;

import dcompute.driver.cuda;

import std.string;
struct Program
{
    void* raw;
    
    Kernel!void getKernelByName(immutable(char)* name)
    {
        Kernel!void ret;
        status = cast(Status)cuModuleGetFunction(&ret.raw,this.raw,name);
        checkErrors();
        return ret;
    }
    Kernel!(typeof(k)) getKernel(alias k)()
    {
        return cast(typeof(return)) getKernelByName(k.mangleof.ptr);
    }
    // TODO: Support globals & images. Requires competent compiler. 
    //cuModuleGetGlobal
    //cuModuleGetTexRef
    //cuModuleGetSurfRef
    
    static Program fromFile(string name)
    {
        Program ret;
        status = cast(Status)cuModuleLoad(&ret.raw,name.toStringz);
        checkErrors();
        return ret;
    }

    static Program fromString(string name)
    {
        Program ret;
        status = cast(Status)cuModuleLoadData(&ret.raw,name.toStringz);
        checkErrors();
        return ret;
    }
    
    __gshared static Program globalProgram;
    //cuModuleLoadDataEx
    //cuModuleLoadFatBinary
    
    void unload()
    {
        status = cast(Status)cuModuleUnload(raw);
        checkErrors();
    }
    
    //TODO: linkstate
}



