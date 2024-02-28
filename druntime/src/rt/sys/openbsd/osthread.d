module rt.sys.openbsd.osthread;

version (NetBSD):

import rt.sys.posix.osthread;

import core.sys.posix.semaphore;
import core.sys.posix.pthread;
import core.sys.posix.signal;
import core.sys.posix.time;

public import rt.sys.posix.osthread : OsThread, ThreadID, getpid, osJoinLowLevelThread, osCreateLowLevelThread,
    thread_entryPoint, getCurrentThreadId, osResume, osSuspend, osThreadSuspendAll;


extern (C) @nogc nothrow
{
    int pthread_stackseg_np(pthread_t thread, stack_t* sinfo);
}

void* osGetStackBottom() nothrow @nogc
{
    stack_t stk;

    pthread_stackseg_np(pthread_self(), &stk);
    return stk.ss_sp;
}

void osThreadInit() @nogc nothrow
{
    // OpenBSD does not support SIGRTMIN or SIGRTMAX
    // Use SIGUSR1 for SIGRTMIN, SIGUSR2 for SIGRTMIN + 1
    // And use 32 for SIGRTMAX (32 is the max signal number on OpenBSD)
    enum SIGRTMIN = SIGUSR1;
    enum SIGRTMAX = 32;

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
