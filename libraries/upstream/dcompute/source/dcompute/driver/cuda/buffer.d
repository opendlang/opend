module dcompute.driver.cuda.buffer;

import dcompute.driver.cuda;

struct Buffer(T)
{
    size_t raw;

	// Host memory associated with this buffer
    T[] hostMemory;

    this(size_t elems)
    {
        status = cast(Status)cuMemAlloc(&raw,elems * T.sizeof);
        checkErrors();
        hostMemory = null;
    }

    this(T[] arr)
    {
        status = cast(Status)cuMemAlloc(&raw,arr.length * T.sizeof);
        checkErrors();
        hostMemory = arr;
    }
    void copy(Copy c)()
    {
        static if (c == Copy.hostToDevice)
        {
            status = cast(Status)cuMemcpyHtoD(raw, hostMemory.ptr,hostMemory.length * T.sizeof);
        }
        else static if  (c == Copy.deviceToHost)
        {
            status = cast(Status)cuMemcpyDtoH(hostMemory.ptr,raw,hostMemory.length * T.sizeof);
        }
        checkErrors();
    }
    alias hostArgOf(U : GlobalPointer!T) = raw; 
    void release()
    {
        status = cast(Status)cuMemFree(raw);
        checkErrors();
        raw = 0;
        hostMemory = null;
    }
}

alias bf = Buffer!float;
