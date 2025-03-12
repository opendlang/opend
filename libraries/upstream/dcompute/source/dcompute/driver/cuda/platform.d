module dcompute.driver.cuda.platform;

import dcompute.driver.error;
import dcompute.driver.cuda;
import std.experimental.allocator.typed;

struct Platform
{
    static void initialise(uint flags =0)
    {
        DerelictCUDADriver.load();
        status = cast(Status)cuInit(flags);
        checkErrors();
    }
    
    static Device[] getDevices(A)(A a)
    {
        int len;
        TypedAllocator!(A) allocator;
        status = cast(Status)cuDeviceGetCount(&len);
        checkErrors();

        //TODO:
        //Device[] ret = allocator.makeArray!(Device)(len);
            Device[] ret = new Device[len];
        foreach(int i; 0 .. len)
        {
            status = cast(Status)cuDeviceGet(&ret[i].raw,i);
            checkErrors();
        }
        return ret;
    }
    
}
