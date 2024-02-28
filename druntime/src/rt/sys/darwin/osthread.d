module rt.sys.darwin.osthread;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (Darwin):

import core.thread.context;
import core.stdc.errno;
import core.sys.posix.semaphore;
import core.sys.posix.pthread;
import core.sys.posix.signal;
import core.sys.posix.time;

import core.sys.darwin.mach.thread_act;
import core.sys.darwin.pthread : pthread_mach_thread_np;

import rt.sys.posix.osthread;

public import rt.sys.posix.osthread : ThreadID, getpid, osJoinLowLevelThread, osCreateLowLevelThread,
    thread_entryPoint, getCurrentThreadId;


struct OsThread
{
    void destroy(bool isMainThread) @trusted nothrow @nogc
    {
        m_osThread.destroy(isMainThread);
        m_tmach = m_tmach.init;
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
    else version (AArch64)
    {
        ulong[33]       m_reg; // x0-x31, pc
    }
    else version (ARM)
    {
        uint[16]        m_reg; // r0-r15
    }
    else version (PPC)
    {
        // Make the assumption that we only care about non-fp and non-vr regs.
        // ??? : it seems plausible that a valid address can be copied into a VR.
        uint[32]        m_reg; // r0-31
    }
    else version (PPC64)
    {
        // As above.
        ulong[32]       m_reg; // r0-31
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
        bool success = m_osThread.start(stackSize, args, lockAboutToStart);
        if(success)
        {
            m_tmach = pthread_mach_thread_np( m_osThread.id() );
            if ( m_tmach == m_tmach.init )
                success = false;
        }

        return success;
    }

    void attachThisThread() @nogc nothrow
    {
        m_osThread.attachThisThread();
        m_tmach = pthread_mach_thread_np( m_osThread.id() );
        assert( m_tmach != m_tmach.init );
    }

    alias m_osThread this;

    rt.sys.posix.osthread.OsThread m_osThread;
private:
    mach_port_t     m_tmach;
}


void* osGetStackBottom() nothrow @nogc
{
    import core.sys.darwin.pthread;
    return pthread_get_stackaddr_np(pthread_self());
}


bool osSuspend(ref OsThread t, bool lock, StackContext* currentContext) nothrow @nogc @system
{
    import core.thread.threadbase : onThreadError;

    if ( t.id() != pthread_self() && thread_suspend( t.m_tmach ) != KERN_SUCCESS )
    {
        return false;
    }

    version (X86)
    {
        x86_thread_state32_t    state = void;
        mach_msg_type_number_t  count = x86_THREAD_STATE32_COUNT;

        if ( thread_get_state( t.m_tmach, x86_THREAD_STATE32, &state, &count ) != KERN_SUCCESS )
            onThreadError( "Unable to load thread state" );
        if ( !lock )
            currentContext.tstack = cast(void*) state.esp;
        // eax,ebx,ecx,edx,edi,esi,ebp,esp
        t.m_reg[0] = state.eax;
        t.m_reg[1] = state.ebx;
        t.m_reg[2] = state.ecx;
        t.m_reg[3] = state.edx;
        t.m_reg[4] = state.edi;
        t.m_reg[5] = state.esi;
        t.m_reg[6] = state.ebp;
        t.m_reg[7] = state.esp;
    }
    else version (X86_64)
    {
        x86_thread_state64_t    state = void;
        mach_msg_type_number_t  count = x86_THREAD_STATE64_COUNT;

        if ( thread_get_state( t.m_tmach, x86_THREAD_STATE64, &state, &count ) != KERN_SUCCESS )
            onThreadError( "Unable to load thread state" );
        if ( !lock )
            currentContext.tstack = cast(void*) state.rsp;
        // rax,rbx,rcx,rdx,rdi,rsi,rbp,rsp
        t.m_reg[0] = state.rax;
        t.m_reg[1] = state.rbx;
        t.m_reg[2] = state.rcx;
        t.m_reg[3] = state.rdx;
        t.m_reg[4] = state.rdi;
        t.m_reg[5] = state.rsi;
        t.m_reg[6] = state.rbp;
        t.m_reg[7] = state.rsp;
        // r8,r9,r10,r11,r12,r13,r14,r15
        t.m_reg[8]  = state.r8;
        t.m_reg[9]  = state.r9;
        t.m_reg[10] = state.r10;
        t.m_reg[11] = state.r11;
        t.m_reg[12] = state.r12;
        t.m_reg[13] = state.r13;
        t.m_reg[14] = state.r14;
        t.m_reg[15] = state.r15;
    }
    else version (AArch64)
    {
        arm_thread_state64_t state = void;
        mach_msg_type_number_t count = ARM_THREAD_STATE64_COUNT;

        if (thread_get_state(t.m_tmach, ARM_THREAD_STATE64, &state, &count) != KERN_SUCCESS)
            onThreadError("Unable to load thread state");
        // TODO: ThreadException here recurses forever!  Does it
        //still using onThreadError?
        //printf("state count %d (expect %d)\n", count ,ARM_THREAD_STATE64_COUNT);
        if (!lock)
            currentContext.tstack = cast(void*) state.sp;

        t.m_reg[0..29] = state.x;  // x0-x28
        t.m_reg[29] = state.fp;    // x29
        t.m_reg[30] = state.lr;    // x30
        t.m_reg[31] = state.sp;    // x31
        t.m_reg[32] = state.pc;
    }
    else version (ARM)
    {
        arm_thread_state32_t state = void;
        mach_msg_type_number_t count = ARM_THREAD_STATE32_COUNT;

        // Thought this would be ARM_THREAD_STATE32, but that fails.
        // Mystery
        if (thread_get_state(t.m_tmach, ARM_THREAD_STATE, &state, &count) != KERN_SUCCESS)
            onThreadError("Unable to load thread state");
        // TODO: in past, ThreadException here recurses forever!  Does it
        //still using onThreadError?
        //printf("state count %d (expect %d)\n", count ,ARM_THREAD_STATE32_COUNT);
        if (!lock)
            currentContext.tstack = cast(void*) state.sp;

        t.m_reg[0..13] = state.r;  // r0 - r13
        t.m_reg[13] = state.sp;
        t.m_reg[14] = state.lr;
        t.m_reg[15] = state.pc;
    }
    else version (PPC)
    {
        ppc_thread_state_t state = void;
        mach_msg_type_number_t count = PPC_THREAD_STATE_COUNT;

        if (thread_get_state(t.m_tmach, PPC_THREAD_STATE, &state, &count) != KERN_SUCCESS)
            onThreadError("Unable to load thread state");
        if (!t.m_lock)
            t.m_curr.tstack = cast(void*) state.r[1];
        t.m_reg[] = state.r[];
    }
    else version (PPC64)
    {
        ppc_thread_state64_t state = void;
        mach_msg_type_number_t count = PPC_THREAD_STATE64_COUNT;

        if (thread_get_state(t.m_tmach, PPC_THREAD_STATE64, &state, &count) != KERN_SUCCESS)
            onThreadError("Unable to load thread state");
        if (!lock)
            currentContext.tstack = cast(void*) state.r[1];
        t.m_reg[] = state.r[];
    }
    else
    {
        static assert(false, "Architecture not supported." );
    }

    return true;
}


bool osResume(ref OsThread t, bool lock, StackContext* currentContext) nothrow @nogc
{
    if ( t.id() != pthread_self() && thread_resume( t.m_tmach ) != KERN_SUCCESS )
    {
        return false;
    }

    if ( !lock )
        currentContext.tstack = currentContext.bstack;
    t.m_reg[0 .. $] = 0;

    return true;
}


void osThreadInit() @nogc nothrow
{
    import core.thread.osthread : Thread;

    // thread id different in forked child process
    static extern(C) void initChildAfterFork()
    {
        auto thisThread = Thread.getThis();
        thisThread.m_osThread.attachThisThread();
    }

    pthread_atfork(null, null, &initChildAfterFork);
}
