module dcompute.driver.ocl.queue;

import dcompute.driver.ocl;
import dcompute.driver.util;
import std.typecons;

enum MapBufferFlags
{
    read                  = 1 << 0,
    write                 = 1 << 1,
    writeInvaildateRegion = 1 << 2,
}

enum  MemoryMigrationFlags
{
    host             = 1 << 0,
    contentUndefined = 1 << 1,
}

struct Queue
{
    cl_command_queue raw;
    // constructed from context
    
    enum Properties
    {
        outOfOrderExecution = 1 << 0,
        profiling = 1 << 1
    }
    static struct Info
    {
        @(0x1090) Context context;
        @(0x1091) Device device;
        @(0x1092) uint referenceCount;
        @(0x1093) Properties properties;
    }
    
    //mixin(generateGetInfo!(Info,clGetCommandQueueInfo));
    
    void retain()
    {
        status = cast(Status)clRetainCommandQueue(raw);
        checkErrors();
    }
    
    void release()
    {
        status = cast(Status)clReleaseCommandQueue(raw);
        checkErrors();
    }
    
    Event write(T)(Buffer!T buffer, T[] data,
                   Flag!"Blocking" blocking = Yes.Blocking,
                   size_t offset = 0, const Event[] waitList = null)
    {
        Event ret;
        status = clEnqueueWriteBuffer(queue, buffer, blocking, offset,
                                      data.memSize, data.ptr,
                                      cast(uint)waitList.length, waitList.ptr,
                                      &ret.raw);
        checkErrors();
        return ret;
                    
    }
    
    Event read(T)(Buffer!T buffer, T[] data,
                  Flag!"Blocking" blocking = Yes.Blocking,
                  size_t offset = 0, const Event[] waitList = null)
    {
        Event ret;
        status = clEnqueueReadBuffer(queue, buffer, blocking, offset,
                                     data.memSize, data.ptr,
                                     cast(uint)waitList.length, waitList.ptr,
                                     &ret.raw);
        checkErrors();
        return ret;
    }
    
    auto enqueue(alias k)(const size_t[] globalWorkSize,
                        const size_t[] globalWorkOffset = null, const size_t[] localWorkSize = null,
                        const Event[] waitList = null)
    in
    {
        if(globalWorkOffset)
            assert(globalWorkSize.length == globalWorkOffset.length);
        if(localWorkSize)
            assert(globalWorkSize.length == localWorkSize.length);
    }
    do
    {
        static struct Call
        {
            Queue q;
            const size_t[] globalWorkSize, globalWorkOffset,localWorkSize;
            const Event[] waitList;
            this(Queue _q,const size_t[] a, const size_t[] b, const size_t[] c, const Event[] d)
            {
                q = _q;
                globalWorkSize = a;
                globalWorkOffset = b;
                localWorkSize = c;
                waitList = d;
            }
            Event opCall(HostArgsOf!(typeof(k)) args)
            {
                auto kernel = Program.globalProgram.getKernel!k();
                foreach(uint i, a; args)
                {
                    kernel.setArg(i,a);
                }
                Event e;
                clEnqueueNDRangeKernel(q.raw, kernel.raw,
                                       cast(uint)globalWorkSize.length,
                                       globalWorkOffset.ptr, globalWorkSize.ptr, localWorkSize.ptr,
                                       cast(uint)waitList.length, cast(cl_event*)waitList.ptr,
                                       &e.raw);
                kernel.release();
                return e;
            }
        }
        
        return Call(this,globalWorkSize,globalWorkOffset,localWorkSize,waitList);
    }
    
    Queue flush()
    {
        clFlush(this.raw);
        return this;
    }

    Queue finish()
    {
        clFinish(this.raw);
        return this;
    }
    //TODO: fill, copy, marker, barrier [, rectFill, rect Copy]

    
}
