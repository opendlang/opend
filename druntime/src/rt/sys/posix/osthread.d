module rt.sys.posix.osthread;

version (Posix):

import core.thread.types;
import core.thread.context;
import core.stdc.errno;
import core.sys.posix.semaphore;
import core.sys.posix.pthread;
import core.sys.posix.signal;
import core.sys.posix.time;
import core.time;
import core.atomic;
import core.internal.traits : externDFunc;

import rt.sys.config;

version (D_InlineAsm_X86)    {} else
version (D_InlineAsm_X86_64)      {} else
version (AsmExternal)       {} else
{
    // NOTE: The ucontext implementation requires architecture specific
    //       data definitions to operate so testing for it must be done
    //       by checking for the existence of ucontext_t rather than by
    //       a version identifier.  Please note that this is considered
    //       an obsolescent feature according to the POSIX spec, so a
    //       custom solution is still preferred.
    import core.sys.posix.ucontext;
}


alias ThreadID = pthread_t;

struct OsThread
{
    alias TLSKey = pthread_key_t;

    void destroy(bool isMainThread) @trusted nothrow @nogc
    {
        if (isValid())
        {
            version (LDC)
            {
                // don't detach the main thread, TSan doesn't like it:
                // https://github.com/ldc-developers/ldc/issues/3519
                if (!isMainThread)
                    pthread_detach(m_pt);
            }
            else
            {
                pthread_detach(m_pt);
            }
        }

        m_handleIsValid = false;
    }


    ///////////////////////////////////////////////////////////////////////////
    // General Actions
    ///////////////////////////////////////////////////////////////////////////

    bool start(size_t stackSize, void *args, scope void delegate() nothrow @nogc lockAboutToStart) @trusted nothrow @nogc
    {
        size_t stksz = adjustStackSize( stackSize );

        pthread_attr_t  attr;

        if ( pthread_attr_init( &attr ) )
        {
            return false;
        }
        if ( stksz && pthread_attr_setstacksize( &attr, stksz ) )
        {
            return false;
        }

        lockAboutToStart();

        // NOTE: This is also set to true by thread_entryPoint, but set it
        //       here as well so the calling thread will see the isRunning
        //       state immediately.
        atomicStore!(MemoryOrder.raw)(m_isRunning, true);

        bool ret = true;
        if ( pthread_create( &m_pt, &attr, &thread_entryPoint, args ) != 0 )
        {
            atomicStore!(MemoryOrder.raw)(m_isRunning, false);
            ret = false;
        }

        m_handleIsValid = true;
            
        if ( pthread_attr_destroy( &attr ) != 0 )
        {
            atomicStore!(MemoryOrder.raw)(m_isRunning, false);
            ret = false;
        }

        return ret;
    }

    bool join()
    {
        if (isValid() && pthread_join( m_pt, null ) != 0 )
            return false;
        // NOTE: pthread_join acts as a substitute for pthread_detach,
        //       which is normally called by the dtor.  Setting m_addr
        //       to zero ensures that pthread_detach will not be called
        //       on object destruction.
        m_handleIsValid = false;

        return true;
    }


    private struct Priority
    {
        int PRIORITY_MIN = int.min;
        int PRIORITY_DEFAULT = int.min;
        int PRIORITY_MAX = int.min;
    }

    /*
    Lazily loads one of the members stored in a hidden global variable of
    type `Priority`. Upon the first access of either member, the entire
    `Priority` structure is initialized. Multiple initializations from
    different threads calling this function are tolerated.

    `which` must be one of `PRIORITY_MIN`, `PRIORITY_DEFAULT`,
    `PRIORITY_MAX`.
    */
    private static shared Priority cache;
    private static int loadGlobal(string which)()
    {
        auto local = atomicLoad(mixin("cache." ~ which));
        if (local != local.min) return local;
        // There will be benign races
        cache = loadPriorities;
        return atomicLoad(mixin("cache." ~ which));
    }

    /*
    Loads all priorities and returns them as a `Priority` structure. This
    function is thread-neutral.
    */
    private static Priority loadPriorities() @nogc nothrow @trusted
    {
        Priority result;
       
        int         policy;
        sched_param param;
        pthread_getschedparam( pthread_self(), &policy, &param ) == 0
            || assert(0, "Internal error in pthread_getschedparam");

        result.PRIORITY_MIN = sched_get_priority_min( policy );
        result.PRIORITY_MIN != -1
            || assert(0, "Internal error in sched_get_priority_min");
        result.PRIORITY_DEFAULT = param.sched_priority;
        result.PRIORITY_MAX = sched_get_priority_max( policy );
        result.PRIORITY_MAX != -1 ||
            assert(0, "Internal error in sched_get_priority_max");
       
        return result;
    }

    /**
        * The minimum scheduling priority that may be set for a thread.  On
        * systems where multiple scheduling policies are defined, this value
        * represents the minimum valid priority for the scheduling policy of
        * the process.
        */
    static int getMinPriority() @nogc nothrow pure @trusted
    {
        return (cast(int function() @nogc nothrow pure @safe)
            &loadGlobal!"PRIORITY_MIN")();
    }

    /**
        * The maximum scheduling priority that may be set for a thread.  On
        * systems where multiple scheduling policies are defined, this value
        * represents the maximum valid priority for the scheduling policy of
        * the process.
        */
    static const(int) getMaxPriority() @nogc nothrow pure @trusted
    {
        return (cast(int function() @nogc nothrow pure @safe)
            &loadGlobal!"PRIORITY_MAX")();
    }

    /**
        * The default scheduling priority that is set for a thread.  On
        * systems where multiple scheduling policies are defined, this value
        * represents the default priority for the scheduling policy of
        * the process.
        */
    static int getDefaultPriority() @nogc nothrow pure @trusted
    {
        return (cast(int function() @nogc nothrow pure @safe)
            &loadGlobal!"PRIORITY_DEFAULT")();
    }

    int priority()
    {
        int         policy;
        sched_param param;

        if (auto err = pthread_getschedparam(m_pt, &policy, &param))
        {
            // ignore error if thread is not running => Bugzilla 8960
            if (!isRunning()) return getDefaultPriority();
            //throw new ThreadException("Unable to get thread priority");
        }
        return param.sched_priority;
    }

    bool priority( int val )
    {
        static if (__traits(compiles, pthread_setschedprio))
        {
            if (auto err = pthread_setschedprio(m_pt, val))
            {
                // ignore error if thread is not running => Bugzilla 8960
                if (!isRunning()) return true;
                return false;
            }
        }
        else
        {
            // NOTE: pthread_setschedprio is not implemented on Darwin, FreeBSD, OpenBSD,
            //       or DragonFlyBSD, so use the more complicated get/set sequence below.
            int         policy;
            sched_param param;

            if (auto err = pthread_getschedparam(m_pt, &policy, &param))
            {
                // ignore error if thread is not running => Bugzilla 8960
                if (!isRunning()) return true;
                return false;
            }
            param.sched_priority = val;
            if (auto err = pthread_setschedparam(m_pt, policy, &param))
            {
                // ignore error if thread is not running => Bugzilla 8960
                if (!isRunning()) return true;
                return false;
            }
        }

        return true;
    }

    bool isRunning() nothrow @nogc
    {
        return atomicLoad(m_isRunning);
    }

    bool isValid() nothrow @nogc
    {
        return m_handleIsValid;
    }

    ThreadID id() nothrow @nogc @safe
    {
        return m_pt;
    }

    void attachThisThread() @nogc nothrow
    {
        m_pt = pthread_self();
        m_handleIsValid = true;
        atomicStore!(MemoryOrder.raw)(m_isRunning, true);
    }


    ///////////////////////////////////////////////////////////////////////////
    // Actions on Calling Thread
    ///////////////////////////////////////////////////////////////////////////

    static void sleep( Duration val ) @nogc nothrow
    {
        timespec tin  = void;
        timespec tout = void;

        val.split!("seconds", "nsecs")(tin.tv_sec, tin.tv_nsec);
        if ( val.total!"seconds" > tin.tv_sec.max )
            tin.tv_sec  = tin.tv_sec.max;
        while ( true )
        {
            if ( !nanosleep( &tin, &tout ) )
                return;
            if ( errno != EINTR )
                assert(0, "Unable to sleep for the specified duration");
            tin = tout;
        }
    }

    static void yield() @nogc nothrow
    {
        sched_yield();
    }

private:
    bool        m_isRunning = false;
    bool        m_handleIsValid = false;
    pthread_t   m_pt;
}


extern (C) void thread_setGCSignals(int suspendSignalNo, int resumeSignalNo) nothrow @nogc
in
{
    assert(suspendSignalNo != 0);
    assert(resumeSignalNo  != 0);
}
out
{
    assert(suspendSignalNumber != 0);
    assert(resumeSignalNumber  != 0);
}
do
{
    suspendSignalNumber = suspendSignalNo;
    resumeSignalNumber  = resumeSignalNo;
}


private __gshared int suspendSignalNumber;
private __gshared int resumeSignalNumber;


ThreadID getCurrentThreadId() @nogc nothrow
{
    return pthread_self();
}


import core.sys.posix.unistd;

alias getpid = core.sys.posix.unistd.getpid;


static if (pThreadGetStackBottomType == PThreadGetStackBottomType.PThread_Getattr_NP)
{
    extern (C) @nogc nothrow int pthread_getattr_np(pthread_t thread, pthread_attr_t* attr);

    void* osGetStackBottom() nothrow @nogc @system
    {
        pthread_attr_t attr;
        void* addr; size_t size;

        pthread_attr_init(&attr);
        pthread_getattr_np(pthread_self(), &attr);
        pthread_attr_getstack(&attr, &addr, &size);
        pthread_attr_destroy(&attr);
        static if (isStackGrowingDown)
            addr += size;
        return addr;
    }
}
else static if (pThreadGetStackBottomType == PThreadGetStackBottomType.PThread_Attr_Get_NP)
{
    extern (C) @nogc nothrow int pthread_attr_get_np(pthread_t thread, pthread_attr_t* attr);

    void* osGetStackBottom() nothrow @nogc
    {
        pthread_attr_t attr;
        void* addr; size_t size;

        pthread_attr_init(&attr);
        pthread_attr_get_np(pthread_self(), &attr);
        pthread_attr_getstack(&attr, &addr, &size);
        pthread_attr_destroy(&attr);
        static if (isStackGrowingDown)
            addr += size;
        return addr;
    }
}


static if (usePosix_osthread_osSuspend)
{
    bool osSuspend(ref OsThread t, bool lock, StackContext* currentContext) nothrow @nogc
    {
        if ( t.m_pt != pthread_self() )
        {
            if ( pthread_kill( t.m_pt , suspendSignalNumber ) != 0 )
            {
                return false;
            }
        }
        else if ( !lock )
        {
            import core.thread.osthread : getStackTop;
            currentContext.tstack = getStackTop();
        }

        return true;
    }
}


bool osThreadSuspendAll(size_t cnt, bool suspendedSelf) nothrow
{
    // Subtract own thread if we called suspend() on ourselves.
    // For example, suspendedSelf would be false if the current
    // thread ran thread_detachThis().
    assert(cnt >= 1);
    if (suspendedSelf)
        --cnt;
    // wait for semaphore notifications
    for (; cnt; --cnt)
    {
        while (sem_wait(&suspendCount) != 0)
        {
            if (errno != EINTR)
                return false;
            errno = 0;
        }
    }
        
    return true;
}


static if (usePosix_osthread_osResume)
{
    bool osResume(ref OsThread t, bool lock, StackContext* currentContext) nothrow @nogc
    {
        if ( t.m_pt != pthread_self() )
        {
            if ( pthread_kill( t.m_pt, resumeSignalNumber ) != 0 )
            {
                return false;
            }
        }
        else if ( !lock )
        {
            currentContext.tstack = currentContext.bstack;
        }

        return true;
    }
}


static if (usePosix_osthread_osThreadInit)
{
    void osThreadInit() @nogc nothrow @system
    {
        if ( suspendSignalNumber == 0 )
        {
            suspendSignalNumber = SIGRTMIN;
        }

        if ( resumeSignalNumber == 0 )
        {
            resumeSignalNumber = SIGRTMIN + 1;
            assert(resumeSignalNumber <= SIGRTMAX);
        }
        int         status;
        sigaction_t suspend = void;
        sigaction_t resume = void;

        // This is a quick way to zero-initialize the structs without using
        // memset or creating a link dependency on their static initializer.
        (cast(byte*) &suspend)[0 .. sigaction_t.sizeof] = 0;
        (cast(byte*)  &resume)[0 .. sigaction_t.sizeof] = 0;

        // NOTE: SA_RESTART indicates that system calls should restart if they
        //       are interrupted by a signal, but this is not available on all
        //       Posix systems, even those that support multithreading.
        static if ( __traits( compiles, SA_RESTART ) )
            suspend.sa_flags = SA_RESTART;

        suspend.sa_handler = &thread_suspendHandler;
        // NOTE: We want to ignore all signals while in this handler, so fill
        //       sa_mask to indicate this.
        status = sigfillset( &suspend.sa_mask );
        assert( status == 0 );

        // NOTE: Since resumeSignalNumber should only be issued for threads within the
        //       suspend handler, we don't want this signal to trigger a
        //       restart.
        resume.sa_flags   = 0;
        resume.sa_handler = &thread_resumeHandler;
        // NOTE: We want to ignore all signals while in this handler, so fill
        //       sa_mask to indicate this.
        status = sigfillset( &resume.sa_mask );
        assert( status == 0 );

        status = sigaction( suspendSignalNumber, &suspend, null );
        assert( status == 0 );

        status = sigaction( resumeSignalNumber, &resume, null );
        assert( status == 0 );

        status = sem_init( &suspendCount, 0, 0 );
        assert( status == 0 );
    }
}


//
// exposed by compiler runtime
//
extern (C) void  rt_moduleTlsCtor();
extern (C) void  rt_moduleTlsDtor();

import core.sys.posix.stdlib; // for malloc, free

extern (C) void* thread_entryPoint( void* arg ) nothrow @system
{
    import core.thread.osthread : Thread;

    Thread obj = cast(Thread)arg;
    assert( obj );

    // loadedLibraries need to be inherited from parent thread
    // before initilizing GC for TLS (rt_tlsgc_init)
    version (Shared)
    {
        externDFunc!("rt.sections_elf_shared.inheritLoadedLibraries",
                        void function(void*) @nogc nothrow)(obj.m_loadedLibraries);
    }

    obj.initDataStorage();

    Thread.setThis(obj); // allocates lazy TLS (see Issue 11981)
    Thread.add(obj);     // can only receive signals from here on
    scope (exit)
    {
        Thread.remove(obj);
        atomicStore!(MemoryOrder.raw)(obj.m_osThread.m_isRunning, false);
        obj.destroyDataStorage();
    }
    Thread.add(&obj.m_main);

    static extern (C) void thread_cleanupHandler( void* arg ) nothrow @nogc
    {
        Thread  obj = cast(Thread) arg;
        assert( obj );

        // NOTE: If the thread terminated abnormally, just set it as
        //       not running and let thread_suspendAll remove it from
        //       the thread list.  This is safer and is consistent
        //       with the Windows thread code.
        atomicStore!(MemoryOrder.raw)(obj.m_osThread.m_isRunning, false);
    }

    // NOTE: Using void to skip the initialization here relies on
    //       knowledge of how pthread_cleanup is implemented.  It may
    //       not be appropriate for all platforms.  However, it does
    //       avoid the need to link the pthread module.  If any
    //       implementation actually requires default initialization
    //       then pthread_cleanup should be restructured to maintain
    //       the current lack of a link dependency.
    static if ( __traits( compiles, pthread_cleanup ) )
    {
        pthread_cleanup cleanup = void;
        cleanup.push( &thread_cleanupHandler, cast(void*) obj );
    }
    else static if ( __traits( compiles, pthread_cleanup_push ) )
    {
        pthread_cleanup_push( &thread_cleanupHandler, cast(void*) obj );
    }
    else
    {
        static assert( false, "Platform not supported." );
    }

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

    // NOTE: Normal cleanup is handled by scope(exit).

    static if ( __traits( compiles, pthread_cleanup ) )
    {
        cleanup.pop( 0 );
    }
    else static if ( __traits( compiles, pthread_cleanup_push ) )
    {
        pthread_cleanup_pop( 0 );
    }

    return null;
}


private
{
    //
    // Used to track the number of suspended threads
    //
    __gshared sem_t suspendCount;


    extern (C) void thread_suspendHandler( int sig ) nothrow
    in
    {
        assert( sig == suspendSignalNumber );
    }
    do
    {
        void op(void* sp) nothrow
        {
            import core.thread.osthread : Thread, getStackTop;

            // NOTE: Since registers are being pushed and popped from the
            //       stack, any other stack data used by this function should
            //       be gone before the stack cleanup code is called below.
            Thread obj = Thread.getThis();
            assert(obj !is null);

            if ( !obj.m_lock )
            {
                obj.m_curr.tstack = getStackTop();
            }

            sigset_t    sigres = void;
            int         status;

            status = sigfillset( &sigres );
            assert( status == 0 );

            status = sigdelset( &sigres, resumeSignalNumber );
            assert( status == 0 );

            status = sem_post( &suspendCount );
            assert( status == 0 );

            sigsuspend( &sigres );

            if ( !obj.m_lock )
            {
                obj.m_curr.tstack = obj.m_curr.bstack;
            }
        }

        import trd = core.thread.osthread : callWithStackShell;
        trd.callWithStackShell(&op);
    }


    extern (C) void thread_resumeHandler( int sig ) nothrow
    in
    {
        assert( sig == resumeSignalNumber );
    }
    do
    {

    }
}


ThreadID osCreateLowLevelThread(scope void delegate() nothrow @nogc lockAboutToStart,
                                uint stacksize = 0, void delegate() nothrow* context,
                                void delegate() nothrow cbDllUnload = null) nothrow @nogc @system
{
    import core.thread.threadbase : ll_removeThread, ll_pThreads, ll_nThreads;

    ThreadID tid;
   
    lockAboutToStart();    

    static extern (C) void* thread_lowlevelEntry(void* ctx) nothrow
    {
        auto dg = *cast(void delegate() nothrow*)ctx;
        free(ctx);

        dg();
        ll_removeThread(pthread_self());
        return null;
    }

    size_t stksz = adjustStackSize(stacksize);

    pthread_attr_t  attr;

    int rc;
    if ((rc = pthread_attr_init(&attr)) != 0)
        return ThreadID.init;
    if (stksz && (rc = pthread_attr_setstacksize(&attr, stksz)) != 0)
        return ThreadID.init;
    if ((rc = pthread_create(&tid, &attr, &thread_lowlevelEntry, context)) != 0)
        return ThreadID.init;
    if ((rc = pthread_attr_destroy(&attr)) != 0)
        return ThreadID.init;

    ll_pThreads[ll_nThreads - 1].tid = tid;

    return tid;
}


bool osJoinLowLevelThread(ThreadID tid) nothrow @nogc
{
    if (pthread_join(tid, null) != 0)
    {
        return false;
    }

    return true;
}


private size_t adjustStackSize(size_t sz) nothrow @nogc
{
    import rt.sys.posix.osthreadstatic;
    import core.memory : pageSize;

    if (sz == 0)
        return 0;

    // stack size must be at least PTHREAD_STACK_MIN for most platforms.
    if (PTHREAD_STACK_MIN > sz)
        sz = PTHREAD_STACK_MIN;

    version (CRuntime_Glibc)
    {
        // On glibc, TLS uses the top of the stack, so add its size to the requested size
        sz += externDFunc!("rt.sections_elf_shared.sizeOfTLS",
                           size_t function() @nogc nothrow)();
    }

    // stack size must be a multiple of pageSize
    sz = ((sz + pageSize - 1) & ~(pageSize - 1));

    return sz;
}
