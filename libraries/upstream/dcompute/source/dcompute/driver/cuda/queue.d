// A stream in CUDA speak
module dcompute.driver.cuda.queue;

import dcompute.driver.cuda;
struct Queue
{
    void* raw;
    this (bool async)
    {
        status = cast(Status)cuStreamCreate(&raw, async ? 1 : 0);
        checkErrors();
    }
    this (bool async, int priority)
    {
        status = cast(Status)cuStreamCreateWithPriority(&raw, async ? 1 : 0, priority);
        checkErrors();
    }
    
    @property bool async()
    {
        uint ret;
        status = cast(Status)cuStreamGetFlags(raw,&ret);
        checkErrors();
        return cast(bool) ret;
    }
    
    @property int priority()
    {
        int ret;
        status = cast(Status)cuStreamGetPriority(raw,&ret);
        checkErrors();
        return ret;
    }

    void wait(Event e,uint flags)
    {
        status = cast(Status)cuStreamWaitEvent(raw,e.raw,flags);
        checkErrors();
    }
    
    // cuMemcpy.*Async and friends
    // TODO: implement this properly
    /*template copy(T, CopySource from, CopySource to, int dimentions = 1,
                  Flag!"peer" _peer = No.peer)
    {
        auto copy(Memory to)
        {
            status = cast(Status)cuMemcpy(to.ptr.raw,ptr.raw,length);
            checkErrors();
        }
    }*/

    
    /*void addCallback(void delegate(Queue,Status) dg)
    {
        static CUstreamCallback cb = (void* ,Status void*) =>
        cuStreamAddCallback
    }*/
    
    auto enqueue(alias k)(uint[3] _grid, uint[3] _block, uint _sharedMem = 0)
    {
        static struct Call
        {
            Queue q;
            uint[3] grid, block;
            uint sharedMem;
            
            this(Queue _q,uint[3] _grid, uint[3] _block, uint _sharedMem)
            {
                q= _q;
                grid = _grid;
                block = _block;
                sharedMem = _sharedMem;
            }
            //TODO integrate evnts into this.
            void opCall(HostArgsOf!(typeof(k)) args)
            {
                auto kernel = Program.globalProgram.getKernel!k();
                void*[typeof(args).length] vargs;
                foreach(uint i, ref a; args)
                {
                    vargs[i] = cast(void*)&a;
                }
                
                status = cast(Status)
                        cuLaunchKernel(kernel.raw,
                                       grid[0], grid[1], grid[2],
                                       block[0],block[1],block[2],
                                       sharedMem,
                                       q.raw,
                                       vargs.ptr,
                                       null);
                checkErrors();
            }
        }
        
        return Call(this,_grid,_block,_sharedMem);
    }
}
