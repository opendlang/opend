module rt.sys.windows.osthread;

version (Windows):

import core.stdc.stdint : uintptr_t; // for _beginthreadex decl below
import core.stdc.stdlib;             // for malloc, atexit
import core.sys.windows.basetsd /+: HANDLE+/;
import core.sys.windows.threadaux /+: getThreadStackBottom, impersonate_thread, OpenThreadHandle+/;
import core.sys.windows.winbase /+: CloseHandle, CREATE_SUSPENDED, DuplicateHandle, GetCurrentThread,
    GetCurrentThreadId, GetCurrentProcess, GetExitCodeThread, GetSystemInfo, GetThreadContext,
    GetThreadPriority, INFINITE, ResumeThread, SetThreadPriority, Sleep,  STILL_ACTIVE,
    SuspendThread, SwitchToThread, SYSTEM_INFO, THREAD_PRIORITY_IDLE, THREAD_PRIORITY_NORMAL,
    THREAD_PRIORITY_TIME_CRITICAL, WAIT_OBJECT_0, WaitForSingleObject+/;
import core.sys.windows.windef /+: TRUE+/;
import core.sys.windows.winnt /+: CONTEXT, CONTEXT_CONTROL, CONTEXT_INTEGER+/;

private extern (Windows) alias btex_fptr = uint function(void*);
private extern (C) uintptr_t _beginthreadex(void*, uint, btex_fptr, void*, uint, uint*) nothrow @nogc;

import core.atomic;
import core.internal.traits : externDFunc;

version (LDC)
{
    import ldc.attributes;
    import ldc.llvmasm;
}

alias ThreadID = uint;

struct OsThread
{
    alias TLSKey = uint;

    void destroy(bool isMainThread) @trusted nothrow @nogc
    {
        m_addr = m_addr.init;
        CloseHandle( m_hndl );
        m_hndl = m_hndl.init;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Thread Context and GC Scanning Support
    ///////////////////////////////////////////////////////////////////////////

    version (X86)
    {
        uint[8]         m_reg; // edi,esi,ebp,esp,ebx,edx,ecx,eax
    }
    else version (X86_64)
    {
        ulong[16]       m_reg; // rdi,rsi,rbp,rsp,rbx,rdx,rcx,rax
                                // r8,r9,r10,r11,r12,r13,r14,r15
    }
    else
    {
        static assert(false, "Architecture not supported." );
    }

    ///////////////////////////////////////////////////////////////////////////
    // General Actions
    ///////////////////////////////////////////////////////////////////////////

    bool start(size_t stackSize, void *args, scope void delegate() nothrow @nogc lockAboutToStart) @trusted nothrow @nogc
    {
        // NOTE: If a thread is just executing DllMain()
        //       while another thread is started here, it holds an OS internal
        //       lock that serializes DllMain with CreateThread. As the code
        //       might request a synchronization on slock (e.g. in thread_findByAddr()),
        //       we cannot hold that lock while creating the thread without
        //       creating a deadlock
        //
        // Solution: Create the thread in suspended state and then
        //       add and resume it with slock acquired
        assert(stackSize <= uint.max, "m_sz must be less than or equal to uint.max");

        m_hndl = cast(HANDLE) _beginthreadex( null, cast(uint) stackSize, &thread_entryPoint, args, CREATE_SUSPENDED, &m_addr);
        if ( cast(size_t) m_hndl == 0 )
            return false;

        lockAboutToStart();
      
        if ( ResumeThread( m_hndl ) == -1 )
        {
            return false;
        }

        return true;
    }

    bool join()
    {
        if ( isValid() && WaitForSingleObject( m_hndl, INFINITE ) != WAIT_OBJECT_0 )
            return false;
        // NOTE: m_addr must be cleared before m_hndl is closed to avoid
        //       a race condition with isRunning. The operation is done
        //       with atomicStore to prevent compiler reordering.
        atomicStore!(MemoryOrder.raw)(*cast(shared)&m_addr, m_addr.init);
        CloseHandle( m_hndl );
        m_hndl = m_hndl.init;

        return true;
    }

    static int getMinPriority() @nogc nothrow pure @safe
    {
        return THREAD_PRIORITY_IDLE;
    }

    static int getMaxPriority() @nogc nothrow pure @safe
    {
        return THREAD_PRIORITY_TIME_CRITICAL;
    }

    static int getDefaultPriority() @nogc nothrow pure @safe
    {
        return THREAD_PRIORITY_NORMAL;
    }

    int priority()
    {
        return GetThreadPriority( m_hndl );
    }

    bool priority( int val )
    {
        if ( !SetThreadPriority( m_hndl, val ) )
            return false;

        return true;
    }

    bool isRunning() nothrow @nogc
    {
        uint ecode = 0;
        GetExitCodeThread( m_hndl, &ecode );
        return ecode == STILL_ACTIVE;
    }

    bool isValid() nothrow @nogc
    {
        return m_addr != m_addr.init;
    }

    ThreadID id() nothrow @nogc @safe
    {
        return m_addr;
    }

    void attachThisThread() @nogc nothrow
    {
        m_hndl = GetCurrentThreadHandle();
        m_addr = GetCurrentThreadId();
    }

    ///////////////////////////////////////////////////////////////////////////
    // Actions on Calling Thread
    ///////////////////////////////////////////////////////////////////////////

    static void sleep( Duration val ) @nogc nothrow
    {
        auto maxSleepMillis = dur!("msecs")( uint.max - 1 );

        // avoid a non-zero time to be round down to 0
        if ( val > dur!"msecs"( 0 ) && val < dur!"msecs"( 1 ) )
            val = dur!"msecs"( 1 );

        // NOTE: In instances where all other threads in the process have a
        //       lower priority than the current thread, the current thread
        //       will not yield with a sleep time of zero.  However, unlike
        //       yield(), the user is not asking for a yield to occur but
        //       only for execution to suspend for the requested interval.
        //       Therefore, expected performance may not be met if a yield
        //       is forced upon the user.
        while ( val > maxSleepMillis )
        {
            Sleep( cast(uint)
                    maxSleepMillis.total!"msecs" );
            val -= maxSleepMillis;
        }
        Sleep( cast(uint) val.total!"msecs" );
    }

    /**
     * Forces a context switch to occur away from the calling thread.
     */
    static void yield() @nogc nothrow
    {
        SwitchToThread();
    }

    HANDLE          m_hndl;
    ThreadID        m_addr;
}


ThreadID getCurrentThreadId() @nogc nothrow
{
    return GetCurrentThreadId();
}

// NOTE: These calls are not safe on Posix systems that use signals to
//       perform garbage collection.  The suspendHandler uses getThis()
//       to get the thread handle so getThis() must be a simple call.
//       Mutexes can't safely be acquired inside signal handlers, and
//       even if they could, the mutex needed (Thread.slock) is held by
//       thread_suspendAll().  So in short, these routines will remain
//       Windows-specific.  If they are truly needed elsewhere, the
//       suspendHandler will need a way to call a version of getThis()
//       that only does the TLS lookup without the fancy fallback stuff.

/// ditto
extern (C) Thread thread_attachByAddr( ThreadID addr )
{
    return thread_attachByAddrB( addr, getThreadStackBottom( addr ) );
}


/// ditto
extern (C) Thread thread_attachByAddrB( ThreadID addr, void* bstack )
{
    import core.memory : GC;
    import core.thread.osthread;
    import core.thread.threadbase;

    GC.disable(); scope(exit) GC.enable();

    if (auto t = thread_findByAddr(addr).toThread)
        return t;

    Thread        thisThread  = new Thread();
    StackContext* thisContext = &thisThread.m_main;
    assert( thisContext == thisThread.m_curr );

    thisThread.m_osThread.m_addr  = addr;
    thisContext.bstack = bstack;
    thisContext.tstack = thisContext.bstack;

    thisThread.m_isDaemon = true;

    if ( addr == GetCurrentThreadId() )
    {
        thisThread.m_osThread.m_hndl = GetCurrentThreadHandle();
        thisThread.tlsGCdataInit();
        Thread.setThis( thisThread );

        version (SupportSanitizers)
        {
            // Save this thread's fake stack handler, to be stored in each StackContext belonging to this thread.
            thisThread.asan_fakestack  = asanGetCurrentFakeStack();
        }
    }
    else
    {
        thisThread.m_osThread.m_hndl = OpenThreadHandle( addr );
        impersonate_thread(addr,
        {
            thisThread.tlsGCdataInit();
            Thread.setThis( thisThread );

            version (SupportSanitizers)
            {
                // Save this thread's fake stack handler, to be stored in each StackContext belonging to this thread.
                thisThread.asan_fakestack  = asanGetCurrentFakeStack();
            }
        });
    }

    version (SupportSanitizers)
    {
        thisContext.asan_fakestack = thisThread.asan_fakestack;
    }

    Thread.add( thisThread, false );
    Thread.add( thisContext );
    if ( Thread.sm_main !is null )
        multiThreadedFlag = true;
    return thisThread;
}


// This is the x86 versions of callWithStackShell, if callWithStackShell exist here it will
// be used in core.thread.osthread, otherwise generic ABI ones in core.thread.osthread will be used.
version (D_InlineAsm_X86)
{
    // Calls the given delegate, passing the current thread's stack pointer to it.
    void osCallWithStackShell(scope callWithStackShellDg fn) nothrow @system
    {
        void *sp = void;

        size_t[3] regs = void;
        asm pure nothrow @nogc
        {
            mov [regs + 0 * 4], EBX;
            mov [regs + 1 * 4], ESI;
            mov [regs + 2 * 4], EDI;

            mov sp[EBP], ESP;
        }

        fn(sp);
    }
}
else version (D_InlineAsm_X86_64)
{
    // Calls the given delegate, passing the current thread's stack pointer to it.
    void osCallWithStackShell(scope callWithStackShellDg fn) nothrow @system
    {
        void *sp = void;

        size_t[7] regs = void;
        asm pure nothrow @nogc
        {
            mov [regs + 0 * 8], RBX;
            mov [regs + 1 * 8], RSI;
            mov [regs + 2 * 8], RDI;
            mov [regs + 3 * 8], R12;
            mov [regs + 4 * 8], R13;
            mov [regs + 5 * 8], R14;
            mov [regs + 6 * 8], R15;

            mov sp[RBP], RSP;
        }

        fn(sp);
    }
}


extern (D) void scanWindowsOnly(scope ScanAllThreadsTypeFn scan, ThreadBase _t) nothrow @system
{
    auto t = _t.toThread;

    scan( ScanType.stack, t.m_osThread.m_reg.ptr, t.m_osThread.m_reg.ptr + t.m_osThread.m_reg.length );
}


alias getpid = core.sys.windows.winbase.GetCurrentProcessId;


version (LDC)
{
    void* osGetStackBottom() nothrow @nogc @naked
    {
        version (X86)
            return __asm!(void*)("mov %fs:(4), $0", "=r");
        else version (X86_64)
            return __asm!(void*)("mov %gs:0($1), $0", "=r,r", 8);
        else
            static assert(false, "Architecture not supported.");
    }
}
else
{
    void* osGetStackBottom() nothrow @nogc
    {
        version (D_InlineAsm_X86)
            asm pure nothrow @nogc { naked; mov EAX, FS:4; ret; }
        else version (D_InlineAsm_X86_64)
            asm pure nothrow @nogc
            {    naked;
                    mov RAX, 8;
                    mov RAX, GS:[RAX];
                    ret;
            }
        else
            static assert(false, "Architecture not supported.");
    }
}


bool osSuspend(ref OsThread t, bool lock, StackContext* currentContext) nothrow @nogc
{
    if ( t.m_addr != GetCurrentThreadId() && SuspendThread( t.m_hndl ) == 0xFFFFFFFF )
    {
       return false;
    }

    CONTEXT context = void;
    context.ContextFlags = CONTEXT_INTEGER | CONTEXT_CONTROL;

    if ( !GetThreadContext( t.m_hndl, &context ) )
        return false;
    version (X86)
    {
        if ( !lock )
            currentContext.tstack = cast(void*) context.Esp;
        // eax,ebx,ecx,edx,edi,esi,ebp,esp
        t.m_reg[0] = context.Eax;
        t.m_reg[1] = context.Ebx;
        t.m_reg[2] = context.Ecx;
        t.m_reg[3] = context.Edx;
        t.m_reg[4] = context.Edi;
        t.m_reg[5] = context.Esi;
        t.m_reg[6] = context.Ebp;
        t.m_reg[7] = context.Esp;
    }
    else version (X86_64)
    {
        if ( !lock )
            currentContext.tstack = cast(void*) context.Rsp;
        // rax,rbx,rcx,rdx,rdi,rsi,rbp,rsp
        t.m_reg[0] = context.Rax;
        t.m_reg[1] = context.Rbx;
        t.m_reg[2] = context.Rcx;
        t.m_reg[3] = context.Rdx;
        t.m_reg[4] = context.Rdi;
        t.m_reg[5] = context.Rsi;
        t.m_reg[6] = context.Rbp;
        t.m_reg[7] = context.Rsp;
        // r8,r9,r10,r11,r12,r13,r14,r15
        t.m_reg[8]  = context.R8;
        t.m_reg[9]  = context.R9;
        t.m_reg[10] = context.R10;
        t.m_reg[11] = context.R11;
        t.m_reg[12] = context.R12;
        t.m_reg[13] = context.R13;
        t.m_reg[14] = context.R14;
        t.m_reg[15] = context.R15;
    }
    else
    {
        static assert(false, "Architecture not supported." );
    }

    return true;
}


bool osResume(ref OsThread t, bool lock, StackContext* currentContext) nothrow @nogc
{
    if ( t.m_addr != GetCurrentThreadId() && ResumeThread( t.m_hndl ) == 0xFFFFFFFF )
    {
        return false;
    }

    if ( !lock )
        currentContext.tstack = currentContext.bstack;
    t.m_reg[0 .. $] = 0;

    return true;
}


private
{


    //
    // Entry point for Windows threads
    //
    extern (Windows) uint thread_entryPoint( void* arg ) nothrow @system
    {
        version (Shared)
        {
            Thread obj = cast(Thread)(cast(void**)arg)[0];
            auto loadedLibraries = (cast(void**)arg)[1];
            .free(arg);
        }
        else
        {
            Thread obj = cast(Thread)arg;
        }
        assert( obj );

        // loadedLibraries need to be inherited from parent thread
        // before initilizing GC for TLS (rt_tlsgc_init)
        version (Shared)
        {
            externDFunc!("rt.sections_elf_shared.inheritLoadedLibraries",
                            void function(void*) @nogc nothrow)(loadedLibraries);
        }

        obj.initDataStorage();

        Thread.setThis(obj);
        Thread.add(obj);
        scope (exit)
        {
            Thread.remove(obj);
            obj.destroyDataStorage();
        }
        Thread.add(&obj.m_main);

        // NOTE: No GC allocations may occur until the stack pointers have
        //       been set and Thread.getThis returns a valid reference to
        //       this thread object (this latter condition is not strictly
        //       necessary on Windows but it should be followed for the
        //       sake of consistency).

        // TODO: Consider putting an auto exception object here (using
        //       alloca) forOutOfMemoryError plus something to track
        //       whether an exception is in-flight?

        void append( Throwable t )
        {
            obj.m_unhandled = Throwable.chainTogether(obj.m_unhandled, t);
        }

        version (D_InlineAsm_X86)
        {
            asm nothrow @nogc { fninit; }
        }

        try
        {
            rt_moduleTlsCtor();
            try
            {
                obj.run();
            }
            catch ( Throwable t )
            {
                append( t );
            }
            rt_moduleTlsDtor();
            version (Shared)
            {
                externDFunc!("rt.sections_elf_shared.cleanupLoadedLibraries",
                                void function() @nogc nothrow)();
            }
        }
        catch ( Throwable t )
        {
            append( t );
        }
        return 0;
    }


    HANDLE GetCurrentThreadHandle() nothrow @nogc
    {
        const uint DUPLICATE_SAME_ACCESS = 0x00000002;

        HANDLE curr = GetCurrentThread(),
                proc = GetCurrentProcess(),
                hndl;

        DuplicateHandle( proc, curr, proc, &hndl, 0, TRUE, DUPLICATE_SAME_ACCESS );
        return hndl;
    }
}


///////////////////////////////////////////////////////////////////////////////
// lowlovel threading support
///////////////////////////////////////////////////////////////////////////////

private
{
    // If the runtime is dynamically loaded as a DLL, there is a problem with
    // threads still running when the DLL is supposed to be unloaded:
    //
    // - with the VC runtime starting with VS2015 (i.e. using the Universal CRT)
    //   a thread created with _beginthreadex increments the DLL reference count
    //   and decrements it when done, so that the DLL is no longer unloaded unless
    //   all the threads have terminated. With the DLL reference count held up
    //   by a thread that is only stopped by a signal from a static destructor or
    //   the termination of the runtime will cause the DLL to never be unloaded.
    //
    // - with the DigitalMars runtime and VC runtime up to VS2013, the thread
    //   continues to run, but crashes once the DLL is unloaded from memory as
    //   the code memory is no longer accessible. Stopping the threads is not possible
    //   from within the runtime termination as it is invoked from
    //   DllMain(DLL_PROCESS_DETACH) holding a lock that prevents threads from
    //   terminating.
    //
    // Solution: start a watchdog thread that keeps the DLL reference count above 0 and
    // checks it periodically. If it is equal to 1 (plus the number of started threads), no
    // external references to the DLL exist anymore, threads can be stopped
    // and runtime termination and DLL unload can be invoked via FreeLibraryAndExitThread.
    // Note: runtime termination is then performed by a different thread than at startup.
    //
    // Note: if the DLL is never unloaded, process termination kills all threads
    // and signals their handles before unconditionally calling DllMain(DLL_PROCESS_DETACH).

    import core.sys.windows.winbase : FreeLibraryAndExitThread, GetModuleHandleExW,
        GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT;
    import core.sys.windows.windef : HMODULE;
    import core.sys.windows.dll : dll_getRefCount;

    version (CRuntime_Microsoft)
        extern(C) extern __gshared ubyte msvcUsesUCRT; // from rt/msvc.d

    /// set during termination of a DLL on Windows, i.e. while executing DllMain(DLL_PROCESS_DETACH)
    public __gshared bool thread_DLLProcessDetaching;

    __gshared HMODULE ll_dllModule;
    __gshared ThreadID ll_dllMonitorThread;

    int ll_countLowLevelThreadsWithDLLUnloadCallback() nothrow @system
    {
        lowlevelLock.lock_nothrow();
        scope(exit) lowlevelLock.unlock_nothrow();

        int cnt = 0;
        foreach (i; 0 .. ll_nThreads)
            if (ll_pThreads[i].cbDllUnload)
                cnt++;
        return cnt;
    }

    bool ll_dllHasExternalReferences() nothrow
    {
        version (CRuntime_DigitalMars)
            enum internalReferences = 1; // only the watchdog thread
        else
            int internalReferences =  msvcUsesUCRT ? 1 + ll_countLowLevelThreadsWithDLLUnloadCallback() : 1;

        int refcnt = dll_getRefCount(ll_dllModule);
        return refcnt > internalReferences;
    }

    private void monitorDLLRefCnt() nothrow @system
    {
        // this thread keeps the DLL alive until all external references are gone
        while (ll_dllHasExternalReferences())
        {
            Thread.sleep(100.msecs);
        }

        // the current thread will be terminated below
        ll_removeThread(GetCurrentThreadId());

        for (;;)
        {
            ThreadID tid;
            void delegate() nothrow cbDllUnload;
            {
                lowlevelLock.lock_nothrow();
                scope(exit) lowlevelLock.unlock_nothrow();

                foreach (i; 0 .. ll_nThreads)
                    if (ll_pThreads[i].cbDllUnload)
                    {
                        cbDllUnload = ll_pThreads[i].cbDllUnload;
                        tid = ll_pThreads[0].tid;
                    }
            }
            if (!cbDllUnload)
                break;
            cbDllUnload();
            assert(!findLowLevelThread(tid));
        }

        FreeLibraryAndExitThread(ll_dllModule, 0);
    }

    int ll_getDLLRefCount() nothrow @nogc
    {
        if (!ll_dllModule &&
            !GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                                cast(const(wchar)*) &ll_getDLLRefCount, &ll_dllModule))
            return -1;
        return dll_getRefCount(ll_dllModule);
    }

    bool ll_startDLLUnloadThread() nothrow @nogc
    {
        int refcnt = ll_getDLLRefCount();
        if (refcnt < 0)
            return false; // not a dynamically loaded DLL

        if (ll_dllMonitorThread !is ThreadID.init)
            return true;

        // if a thread is created from a DLL, the MS runtime (starting with VC2015) increments the DLL reference count
        // to avoid the DLL being unloaded while the thread is still running. Mimick this behavior here for all
        // runtimes not doing this
        version (CRuntime_DigitalMars)
            enum needRef = true;
        else
            bool needRef = !msvcUsesUCRT;

        if (needRef)
        {
            HMODULE hmod;
            GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, cast(const(wchar)*) &ll_getDLLRefCount, &hmod);
        }

        ll_dllMonitorThread = core.thread.osthread.createLowLevelThread(() { monitorDLLRefCnt(); });
        return ll_dllMonitorThread != ThreadID.init;
    }
}


ThreadID osCreateLowLevelThread(scope void delegate() @nogc nothrow lockAboutToStart,
                                uint stacksize = 0, void delegate() nothrow* context,
                                void delegate() nothrow cbDllUnload = null) nothrow @nogc @system
{
    ThreadID tid;

    // the thread won't start until after the DLL is unloaded
    if (thread_DLLProcessDetaching)
        return ThreadID.init;

    static extern (Windows) uint thread_lowlevelEntry(void* ctx) nothrow
    {
        auto dg = *cast(void delegate() nothrow*)ctx;
        free(ctx);

        dg();
        ll_removeThread(GetCurrentThreadId());
        return 0;
    }

    // see Thread.start() for why thread is created in suspended state
    HANDLE hThread = cast(HANDLE) _beginthreadex(null, stacksize, &thread_lowlevelEntry,
                                                    context, CREATE_SUSPENDED, &tid);
    if (!hThread)
        return ThreadID.init;

    lockAboutToStart();

    ll_pThreads[ll_nThreads - 1].tid = tid;
    ll_pThreads[ll_nThreads - 1].cbDllUnload = cbDllUnload;
    if (ResumeThread(hThread) == -1)
        onThreadError("Error resuming thread");
    CloseHandle(hThread);

    if (cbDllUnload)
        ll_startDLLUnloadThread();
   
    return tid;
}


bool osJoinLowLevelThread(ThreadID tid) nothrow @nogc
{
    HANDLE handle = OpenThreadHandle(tid);
    if (!handle)
        return true;

    if (thread_DLLProcessDetaching)
    {
        // When being called from DllMain/DLL_DETACH_PROCESS, threads cannot stop
        //  due to the loader lock being held by the current thread.
        // On the other hand, the thread must not continue to run as it will crash
        //  if the DLL is unloaded. The best guess is to terminate it immediately.
        TerminateThread(handle, 1);
        WaitForSingleObject(handle, 10); // give it some time to terminate, but don't wait indefinitely
    }
    else
        WaitForSingleObject(handle, INFINITE);
    CloseHandle(handle);

    return true;
}
