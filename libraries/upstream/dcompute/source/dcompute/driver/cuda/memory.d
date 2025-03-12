module dcompute.driver.cuda.memory;

import dcompute.driver.error;
import dcompute.driver.cuda;

// void pointer like
struct MemoryPointer
{
    size_t raw;
    static MemoryPointer allocate(size_t nbytes)
    {
        MemoryPointer ret;
        status = cast(Status)cuMemAlloc(&ret.raw,nbytes);
        checkErrors();
        return ret;
    }
    //static MemoryPointer allocatePitch(T)(size_t nbytes)

    Memory addressRange()
    {
        Memory ret;
        status = cast(Status)cuMemGetAddressRange(&ret.ptr.raw,&ret.length,raw);
        checkErrors();
        return ret;
    }

}

// void[] like
struct Memory
{
    MemoryPointer ptr;
    size_t length;

    enum CopySource
    {
        Host,
        Device,
        Array
    }

    // cuMemcpy and friends
    // TODO: implement this properly
    /*
    template copy(T, CopySource from, CopySource to, int dimentions = 1,
                  Flag!"peer" _peer = No.peer)
    {
        auto copy(Memory to)
        {
            status = cast(Status)cuMemcpy(to.ptr.raw,ptr.raw,length);
            checkErrors();
        }
    }*/

    // TODO: cuMemset & frineds

}
