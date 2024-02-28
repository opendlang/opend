/**
 * The osthread module provides low-level, OS-dependent code
 * for thread creation and management.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Sean Kelly, Walter Bright, Alex Rønne Petersen, Martin Nowak
 * Source:    $(DRUNTIMESRC core/thread/osthread.d)
 */

module core.thread.osthread;

import core.thread.threadbase;
import core.thread.context;
import core.thread.types;
import core.atomic;
import core.memory : GC;
import core.time;
import core.exception : onOutOfMemoryError;
import core.internal.traits : externDFunc;

import core.stdc.stdlib : free, realloc, malloc;

import rt.sys.config;
mixin("import " ~ osThreadImport ~ ";");


version (LDC)
{
    import ldc.attributes;
    import ldc.llvmasm;

    version (ARM)     version = ARM_Any;
    version (AArch64) version = ARM_Any;

    version (MIPS32) version = MIPS_Any;
    version (MIPS64) version = MIPS_Any;

    version (PPC)   version = PPC_Any;
    version (PPC64) version = PPC_Any;

    version (RISCV32) version = RISCV_Any;
    version (RISCV64) version = RISCV_Any;

    version (SupportSanitizers)
    {
        import ldc.sanitizers_optionally_linked;
    }
}


///////////////////////////////////////////////////////////////////////////////
// Platform Detection and Memory Allocation
///////////////////////////////////////////////////////////////////////////////

version (GNU)
{
    import gcc.builtins;
}

/**
 * Hook for whatever EH implementation is used to save/restore some data
 * per stack.
 *
 * Params:
 *     newContext = The return value of the prior call to this function
 *         where the stack was last swapped out, or null when a fiber stack
 *         is switched in for the first time.
 */
private extern(C) void* _d_eh_swapContext(void* newContext) nothrow @nogc;

// LDC: changed from `version (DigitalMars)`
version (all)
{
    // LDC: changed from `version (Windows)`
    version (CRuntime_Microsoft)
    {
        extern(D) void* swapContext(void* newContext) nothrow @nogc
        {
            return _d_eh_swapContext(newContext);
        }
    }
    else
    {
        extern(C) void* _d_eh_swapContextDwarf(void* newContext) nothrow @nogc;

        extern(D) void* swapContext(void* newContext) nothrow @nogc
        {
            /* Detect at runtime which scheme is being used.
             * Eventually, determine it statically.
             */
            static int which = 0;
            final switch (which)
            {
                case 0:
                {
                    assert(newContext == null);
                    auto p = _d_eh_swapContext(newContext);
                    auto pdwarf = _d_eh_swapContextDwarf(newContext);
                    if (p)
                    {
                        which = 1;
                        return p;
                    }
                    else if (pdwarf)
                    {
                        which = 2;
                        return pdwarf;
                    }
                    return null;
                }
                case 1:
                    return _d_eh_swapContext(newContext);
                case 2:
                    return _d_eh_swapContextDwarf(newContext);
            }
        }
    }
}
else
{
    extern(D) void* swapContext(void* newContext) nothrow @nogc
    {
        return _d_eh_swapContext(newContext);
    }
}

///////////////////////////////////////////////////////////////////////////////
// Thread
///////////////////////////////////////////////////////////////////////////////

/**
 * This class encapsulates all threading functionality for the D
 * programming language.  As thread manipulation is a required facility
 * for garbage collection, all user threads should derive from this
 * class, and instances of this class should never be explicitly deleted.
 * A new thread may be created using either derivation or composition, as
 * in the following example.
 */
class Thread : ThreadBase
{
    alias TLSKey = OsThread.TLSKey;

    version (Shared)
    {
        // Used for pinned libs
        void* m_loadedLibraries;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Initialization
    ///////////////////////////////////////////////////////////////////////////


    /**
     * Initializes a thread object which is associated with a static
     * D function.
     *
     * Params:
     *  fn = The thread function.
     *  sz = The stack size for this thread.
     *
     * In:
     *  fn must not be null.
     */
    this( void function() fn, size_t sz = 0 ) @safe pure nothrow @nogc
    {
        super(fn, sz);
    }


    /**
     * Initializes a thread object which is associated with a dynamic
     * D function.
     *
     * Params:
     *  dg = The thread function.
     *  sz = The stack size for this thread.
     *
     * In:
     *  dg must not be null.
     */
    this( void delegate() dg, size_t sz = 0 ) @safe pure nothrow @nogc
    {
        super(dg, sz);
    }

    this( size_t sz = 0 ) @safe pure nothrow @nogc
    {
        super(sz);
    }

    //
    // Thread entry point.  Invokes the function or delegate passed on
    // construction (if any).
    //
    public final void run()
    {
        super.run();
    }

    /**
     * Provides a reference to the calling thread.
     *
     * Returns:
     *  The thread object representing the calling thread.  The result of
     *  deleting this object is undefined.  If the current thread is not
     *  attached to the runtime, a null reference is returned.
     */
    static Thread getThis() @safe nothrow @nogc
    {
        return ThreadBase.getThis().toThread;
    }

    ///////////////////////////////////////////////////////////////////////////
    // General Actions
    ///////////////////////////////////////////////////////////////////////////


    /**
     * Starts the thread and invokes the function or delegate passed upon
     * construction.
     *
     * In:
     *  This routine may only be called once per thread instance.
     *
     * Throws:
     *  ThreadException if the thread fails to start.
     */
    final Thread start() nothrow @system
    in
    {
        assert( !next && !prev );
    }
    do
    {
        auto wasThreaded  = multiThreadedFlag;
        multiThreadedFlag = true;
        scope( failure )
        {
            if ( !wasThreaded )
                multiThreadedFlag = false;
        }

        bool wasLocked = false;

        scope auto lockAboutToStart = () nothrow @nogc
        {
            slock.lock_nothrow();

            ++nAboutToStart;
            pAboutToStart = cast(ThreadBase*)realloc(pAboutToStart, Thread.sizeof * nAboutToStart);
            pAboutToStart[nAboutToStart - 1] = this;

            version (Shared)
            {
                m_loadedLibraries = externDFunc!("rt.sections_elf_shared.pinLoadedLibraries",
                                                 void* function() @nogc nothrow)();
            }

            wasLocked = true;
        };

        bool success = m_osThread.start(m_sz, cast(void*) this, lockAboutToStart);
        if(!success)
        {
            if (wasLocked)
            {
                version (Shared)
                {
                    externDFunc!("rt.sections_elf_shared.unpinLoadedLibraries",
                                void function(void*) @nogc nothrow)(m_loadedLibraries);
                }

                slock.unlock_nothrow();
            }

            onThreadError( "Failed to start thread" );
        }
        else
        {
            assert(wasLocked);
            if (wasLocked)
            {
                slock.unlock_nothrow();
            }
        }

        return this;
    }

    /**
     * Waits for this thread to complete.  If the thread terminated as the
     * result of an unhandled exception, this exception will be rethrown.
     *
     * Params:
     *  rethrow = Rethrow any unhandled exception which may have caused this
     *            thread to terminate.
     *
     * Throws:
     *  ThreadException if the operation fails.
     *  Any exception not handled by the joined thread.
     *
     * Returns:
     *  Any exception not handled by this thread if rethrow = false, null
     *  otherwise.
     */
    override final Throwable join( bool rethrow = true )
    {
        if(!m_osThread.join())
        {
            new ThreadException( "Unable to join thread" );
        }

        if ( m_unhandled )
        {
            if ( rethrow )
                throw m_unhandled;
            return m_unhandled;
        }
        return null;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Thread Priority Actions
    ///////////////////////////////////////////////////////////////////////////

    /**
     * The minimum scheduling priority that may be set for a thread.  On
     * systems where multiple scheduling policies are defined, this value
     * represents the minimum valid priority for the scheduling policy of
     * the process.
     */
    @property static int PRIORITY_MIN() @nogc nothrow pure @safe
    {
        return OsThread.getMinPriority();
    }

    /**
     * The maximum scheduling priority that may be set for a thread.  On
     * systems where multiple scheduling policies are defined, this value
     * represents the maximum valid priority for the scheduling policy of
     * the process.
     */
    @property static const(int) PRIORITY_MAX() @nogc nothrow pure @safe
    {
        return OsThread.getMaxPriority();
    }

    /**
     * The default scheduling priority that is set for a thread.  On
     * systems where multiple scheduling policies are defined, this value
     * represents the default priority for the scheduling policy of
     * the process.
     */
    @property static int PRIORITY_DEFAULT() @nogc nothrow pure @safe
    {
        return OsThread.getDefaultPriority();
    }

    /**
     * Gets the scheduling priority for the associated thread.
     *
     * Note: Getting the priority of a thread that already terminated
     * might return the default priority.
     *
     * Returns:
     *  The scheduling priority of this thread.
     */
    final @property int priority() @system
    {
        return m_osThread.priority();
    }

    /**
     * Sets the scheduling priority for the associated thread.
     *
     * Note: Setting the priority of a thread that already terminated
     * might have no effect.
     *
     * Params:
     *  val = The new scheduling priority of this thread.
     */
    final @property void priority( int val )
    {
        if(!m_osThread.priority(val))
        {
            onThreadError("Error setting priority");
        }
    }
   
    unittest
    {
        auto thr = Thread.getThis();
        immutable prio = thr.priority;
        scope (exit) thr.priority = prio;

        assert(prio == PRIORITY_DEFAULT);
        assert(prio >= PRIORITY_MIN && prio <= PRIORITY_MAX);
        thr.priority = PRIORITY_MIN;
        assert(thr.priority == PRIORITY_MIN);
        thr.priority = PRIORITY_MAX;
        assert(thr.priority == PRIORITY_MAX);
    }

    unittest // Bugzilla 8960
    {
        import core.sync.semaphore;

        auto thr = new Thread({});
        thr.start();
        Thread.sleep(1.msecs);       // wait a little so the thread likely has finished
        thr.priority = PRIORITY_MAX; // setting priority doesn't cause error
        auto prio = thr.priority;    // getting priority doesn't cause error
        assert(prio >= PRIORITY_MIN && prio <= PRIORITY_MAX);
    }

    /**
     * Tests whether this thread is running.
     *
     * Returns:
     *  true if the thread is running, false if not.
     */
    override final @property bool isRunning() nothrow @nogc
    {
        return super.isRunning();
            return false;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Actions on Calling Thread
    ///////////////////////////////////////////////////////////////////////////


    /**
     * Suspends the calling thread for at least the supplied period.  This may
     * result in multiple OS calls if period is greater than the maximum sleep
     * duration supported by the operating system.
     *
     * Params:
     *  val = The minimum duration the calling thread should be suspended.
     *
     * In:
     *  period must be non-negative.
     *
     * Example:
     * ------------------------------------------------------------------------
     *
     * Thread.sleep( dur!("msecs")( 50 ) );  // sleep for 50 milliseconds
     * Thread.sleep( dur!("seconds")( 5 ) ); // sleep for 5 seconds
     *
     * ------------------------------------------------------------------------
     */
    static void sleep( Duration val ) @nogc nothrow @system
    in
    {
        assert( !val.isNegative );
    }
    do
    {
        OsThread.sleep(val);
    }


    /**
     * Forces a context switch to occur away from the calling thread.
     */
    static void yield() @nogc nothrow
    {
        OsThread.yield();
    }
}

Thread toThread(return scope ThreadBase t) @trusted nothrow @nogc pure
{
    return cast(Thread) cast(void*) t;
}

private extern(D) static void thread_yield() @nogc nothrow
{
    Thread.yield();
}

///
unittest
{
    class DerivedThread : Thread
    {
        this()
        {
            super(&run);
        }

    private:
        void run()
        {
            // Derived thread running.
        }
    }

    void threadFunc()
    {
        // Composed thread running.
    }

    // create and start instances of each type
    auto derived = new DerivedThread().start();
    auto composed = new Thread(&threadFunc).start();
    new Thread({
        // Codes to run in the newly created thread.
    }).start();
}

unittest
{
    int x = 0;

    new Thread(
    {
        x++;
    }).start().join();
    assert( x == 1 );
}


unittest
{
    enum MSG = "Test message.";
    string caughtMsg;

    try
    {
        new Thread(
        function()
        {
            throw new Exception( MSG );
        }).start().join();
        assert( false, "Expected rethrown exception." );
    }
    catch ( Throwable t )
    {
        assert( t.msg == MSG );
    }
}


unittest
{
    // use >pageSize to avoid stack overflow (e.g. in an syscall)
    auto thr = new Thread(function{}, 4096 + 1).start();
    thr.join();
}


unittest
{
    import core.memory : GC;

    auto t1 = new Thread({
        foreach (_; 0 .. 20)
            ThreadBase.getAll;
    }).start;
    auto t2 = new Thread({
        foreach (_; 0 .. 20)
            GC.collect;
    }).start;
    t1.join();
    t2.join();
}

unittest
{
    import core.sync.semaphore;
    auto sem = new Semaphore();

    auto t = new Thread(
    {
        sem.notify();
        Thread.sleep(100.msecs);
    }).start();

    sem.wait(); // thread cannot be detached while being started
    thread_detachInstance(t);
    foreach (t2; Thread)
        assert(t !is t2);
    t.join();
}

unittest
{
    // NOTE: This entire test is based on the assumption that no
    //       memory is allocated after the child thread is
    //       started. If an allocation happens, a collection could
    //       trigger, which would cause the synchronization below
    //       to cause a deadlock.
    // NOTE: DO NOT USE LOCKS IN CRITICAL REGIONS IN NORMAL CODE.

    import core.sync.semaphore;

    auto sema = new Semaphore(),
         semb = new Semaphore();

    auto thr = new Thread(
    {
        thread_enterCriticalRegion();
        assert(thread_inCriticalRegion());
        sema.notify();

        semb.wait();
        assert(thread_inCriticalRegion());

        thread_exitCriticalRegion();
        assert(!thread_inCriticalRegion());
        sema.notify();

        semb.wait();
        assert(!thread_inCriticalRegion());
    });

    thr.start();

    sema.wait();
    synchronized (ThreadBase.criticalRegionLock)
        assert(thr.m_isInCriticalRegion);
    semb.notify();

    sema.wait();
    synchronized (ThreadBase.criticalRegionLock)
        assert(!thr.m_isInCriticalRegion);
    semb.notify();

    thr.join();
}

// https://issues.dlang.org/show_bug.cgi?id=22124
unittest
{
    Thread thread = new Thread({});
    auto fun(Thread t, int x)
    {
        t.__ctor({x = 3;});
        return t;
    }
    static assert(!__traits(compiles, () @nogc => fun(thread, 3) ));
}

unittest
{
    import core.sync.semaphore;

    shared bool inCriticalRegion;
    auto sema = new Semaphore(),
         semb = new Semaphore();

    auto thr = new Thread(
    {
        thread_enterCriticalRegion();
        inCriticalRegion = true;
        sema.notify();
        semb.wait();

        Thread.sleep(dur!"msecs"(1));
        inCriticalRegion = false;
        thread_exitCriticalRegion();
    });
    thr.start();

    sema.wait();
    assert(inCriticalRegion);
    semb.notify();

    thread_suspendAll();
    assert(!inCriticalRegion);
    thread_resumeAll();
}

///////////////////////////////////////////////////////////////////////////////
// GC Support Routines
///////////////////////////////////////////////////////////////////////////////

version (CoreDdoc)
{
    /**
     * Instruct the thread module, when initialized, to use a different set of
     * signals besides SIGRTMIN and SIGRTMIN + 1 for suspension and resumption of threads.
     * This function should be called at most once, prior to thread_init().
     * This function is Posix-only.
     */
    extern (C) void thread_setGCSignals(int suspendSignalNo, int resumeSignalNo) nothrow @nogc
    {
    }
}

private extern (D) ThreadBase attachThread(ThreadBase _thisThread) @nogc nothrow
{
    Thread thisThread = _thisThread.toThread();

    StackContext* thisContext = &thisThread.m_main;
    assert( thisContext == thisThread.m_curr );

    version (SupportSanitizers)
    {
        // Save this thread's fake stack handler, to be stored in each StackContext belonging to this thread.
        thisThread.asan_fakestack  = asanGetCurrentFakeStack();
        thisContext.asan_fakestack = thisThread.asan_fakestack;
    }

    thisThread.m_osThread.attachThisThread();
    thisContext.bstack = getStackBottom();
    thisContext.tstack = thisContext.bstack;

    thisThread.m_isDaemon = true;
    thisThread.tlsGCdataInit();
    Thread.setThis( thisThread );

    Thread.add( thisThread, false );
    Thread.add( thisContext );
    if ( Thread.sm_main !is null )
        multiThreadedFlag = true;
    return thisThread;
}

/**
 * Registers the calling thread for use with the D Runtime.  If this routine
 * is called for a thread which is already registered, no action is performed.
 *
 * NOTE: This routine does not run thread-local static constructors when called.
 *       If full functionality as a D thread is desired, the following function
 *       must be called after thread_attachThis:
 *
 *       extern (C) void rt_moduleTlsCtor();
 *
 * See_Also:
 *     $(REF thread_detachThis, core,thread,threadbase)
 */
extern(C) Thread thread_attachThis()
{
    return thread_attachThis_tpl!Thread();
}


// Calls the given delegate, passing the current thread's stack pointer to it.
extern(D) void callWithStackShell(scope callWithStackShellDg fn) nothrow @system
in (fn)
{
    // If callWithStackShell exists in the osthread implementation it will use that
    // version first.
    static if(is(typeof(osCallWithStackShell)))
    {
        osCallWithStackShell(fn);
    }
    else
    {
        // The purpose of the 'shell' is to ensure all the registers get
        // put on the stack so they'll be scanned. We only need to push
        // the callee-save registers.
        void *sp = void;

        version (GNU)
        {
            __builtin_unwind_init();
            sp = &sp;
        }
        else version (D_InlineAsm_X86)
        {
            size_t[3] regs = void;
            asm pure nothrow @nogc
            {
                mov [regs + 0 * 4], EBX;
                mov [regs + 1 * 4], ESI;
                mov [regs + 2 * 4], EDI;

                mov sp[EBP], ESP;
            }
        }
        else version (D_InlineAsm_X86_64)
        {
            size_t[5] regs = void;
            asm pure nothrow @nogc
            {
                mov [regs + 0 * 8], RBX;
                mov [regs + 1 * 8], R12;
                mov [regs + 2 * 8], R13;
                mov [regs + 3 * 8], R14;
                mov [regs + 4 * 8], R15;

                mov sp[RBP], RSP;
            }
        }
        else version (LDC)
        {
            version (PPC_Any)
            {
                // Nonvolatile registers, according to:
                // System V Application Binary Interface
                // PowerPC Processor Supplement, September 1995
                // ELFv1: 64-bit PowerPC ELF ABI Supplement 1.9, July 2004
                // ELFv2: Power Architecture, 64-Bit ELV V2 ABI Specification,
                //        OpenPOWER ABI for Linux Supplement, July 2014
                size_t[18] regs = void;
                static foreach (i; 0 .. regs.length)
                {{
                    enum int j = 14 + i; // source register
                    static if (j == 21)
                    {
                        // Work around LLVM bug 21443 (http://llvm.org/bugs/show_bug.cgi?id=21443)
                        // Because we clobber r0 a different register is chosen
                        asm pure nothrow @nogc { ("std "~j.stringof~", %0") : "=m" (regs[i]) : : "r0"; }
                    }
                    else
                        asm pure nothrow @nogc { ("std "~j.stringof~", %0") : "=m" (regs[i]); }
                }}

                asm pure nothrow @nogc { "std 1, %0" : "=m" (sp); }
            }
            else version (AArch64)
            {
                // Callee-save registers, x19-x28 according to AAPCS64, section
                // 5.1.1.  Include x29 fp because it optionally can be a callee
                // saved reg
                size_t[11] regs = void;
                // store the registers in pairs
                asm pure nothrow @nogc
                {
                    "stp x19, x20, %0" : "=m" (regs[ 0]), "=m" (regs[1]);
                    "stp x21, x22, %0" : "=m" (regs[ 2]), "=m" (regs[3]);
                    "stp x23, x24, %0" : "=m" (regs[ 4]), "=m" (regs[5]);
                    "stp x25, x26, %0" : "=m" (regs[ 6]), "=m" (regs[7]);
                    "stp x27, x28, %0" : "=m" (regs[ 8]), "=m" (regs[9]);
                    "str x29, %0"      : "=m" (regs[10]);
                    "mov %0, sp"       : "=r" (sp);
                }
            }
            else version (ARM)
            {
                // Callee-save registers, according to AAPCS, section 5.1.1.
                // arm and thumb2 instructions
                size_t[8] regs = void;
                asm pure nothrow @nogc
                {
                    "stm %0, {r4-r11}" : : "r" (regs.ptr) : "memory";
                    "mov %0, sp"       : "=r" (sp);
                }
            }
            else version (MIPS_Any)
            {
                version (MIPS32)      enum store = "sw";
                else version (MIPS64) enum store = "sd";
                else static assert(0);

                // Callee-save registers, according to MIPS Calling Convention
                // and MIPSpro N32 ABI Handbook, chapter 2, table 2-1.
                // FIXME: Should $28 (gp) and $30 (s8) be saved, too?
                size_t[8] regs = void;
                asm pure nothrow @nogc { ".set noat"; }
                static foreach (i; 0 .. regs.length)
                {{
                    enum int j = 16 + i; // source register
                    asm pure nothrow @nogc { (store ~ " $"~j.stringof~", %0") : "=m" (regs[i]); }
                }}
                asm pure nothrow @nogc { (store ~ " $29, %0") : "=m" (sp); }
                asm pure nothrow @nogc { ".set at"; }
            }
            else version (RISCV_Any)
            {
                version (RISCV32)      enum store = "sw";
                else version (RISCV64) enum store = "sd";
                else static assert(0);

                // Callee-save registers, according to RISCV Calling Convention
                // https://github.com/riscv-non-isa/riscv-elf-psabi-doc/blob/master/riscv-cc.adoc
                size_t[24] regs = void;
                static foreach (i; 0 .. 12)
                {{
                    enum int j = i;
                    asm pure nothrow @nogc { (store ~ " s"~j.stringof~", %0") : "=m" (regs[i]); }
                }}
                static foreach (i; 0 .. 12)
                {{
                    enum int j = i;
                    asm pure nothrow @nogc { ("f" ~ store ~ " fs"~j.stringof~", %0") : "=m" (regs[i + 12]); }
                }}
                asm pure nothrow @nogc { (store ~ " sp, %0") : "=m" (sp); }
            }
            else version (LoongArch64)
            {
                // Callee-save registers, according to LoongArch Calling Convention
                // https://loongson.github.io/LoongArch-Documentation/LoongArch-ELF-ABI-EN.html
                size_t[18] regs = void;
                static foreach (i; 0 .. 8)
                {{
                    enum int j = i;
                    // save $fs0 - $fs7
                    asm pure nothrow @nogc { ( "fst.d $fs"~j.stringof~", %0") : "=m" (regs[i]); }
                }}
                static foreach (i; 0 .. 9)
                {{
                    enum int j = i;
                    // save $s0 - $s8
                    asm pure nothrow @nogc { ( "st.d $s"~j.stringof~", %0") : "=m" (regs[i + 8]); }
                }}
                // save $fp (or $s9) and $sp
                asm pure nothrow @nogc { ( "st.d $fp, %0") : "=m" (regs[17]); }
                asm pure nothrow @nogc { ( "st.d $sp, %0") : "=m" (sp); }
            }
            else
            {
                static assert(false, "Architecture not supported for LDC.");
            }
        }
        else
        {
            static assert(false, "Architecture not supported.");
        }

        fn(sp);
    }
}


/**
 * Returns the process ID of the calling process, which is guaranteed to be
 * unique on the system. This call is always successful.
 *
 * Example:
 * ---
 * writefln("Current process id: %s", getpid());
 * ---
 */
mixin("public import " ~ osThreadImport ~ " : getpid;");

version (LDC)
{
    version (X86)      version = LDC_stackTopAsm;
    version (X86_64)   version = LDC_stackTopAsm;
    version (ARM_Any)  version = LDC_stackTopAsm;
    version (PPC_Any)  version = LDC_stackTopAsm;
    version (MIPS_Any) version = LDC_stackTopAsm;

    version (LDC_stackTopAsm)
    {
        /* The inline assembler is written in a style that the code can be inlined.
         * If it isn't, the function is still naked, so the caller's stack pointer
         * is used nevertheless.
         */
        extern(D) void* getStackTop() nothrow @nogc @naked
        {
            version (X86)
                return __asm!(void*)("movl %esp, $0", "=r");
            else version (X86_64)
                return __asm!(void*)("movq %rsp, $0", "=r");
            else version (ARM_Any)
                return __asm!(void*)("mov $0, sp", "=r");
            else version (PPC_Any)
                return __asm!(void*)("mr $0, 1", "=r");
            else version (MIPS_Any)
                return __asm!(void*)("move $0, $$sp", "=r");
            else
                static assert(0);
        }
    }
    else
    {
        /* The use of intrinsic llvm_frameaddress is a reasonable default for
         * cpu architectures without assembler support from LLVM. Because of
         * the slightly different meaning the function must neither be inlined
         * nor naked.
         */
        extern(D) void* getStackTop() nothrow @nogc
        {
            import ldc.intrinsics;
            pragma(LDC_never_inline);
            return llvm_frameaddress(0);
        }
    }
}
else
extern(D) void* getStackTop() nothrow @nogc
{
    version (D_InlineAsm_X86)
        asm pure nothrow @nogc { naked; mov EAX, ESP; ret; }
    else version (D_InlineAsm_X86_64)
        asm pure nothrow @nogc { naked; mov RAX, RSP; ret; }
    else version (GNU)
        return __builtin_frame_address(0);
    else
        static assert(false, "Architecture not supported.");
}


package extern(D) void* getStackBottom() nothrow @nogc
{
    return osGetStackBottom();
}

/**
 * Suspend the specified thread and load stack and register information for
 * use by thread_scanAll.  If the supplied thread is the calling thread,
 * stack and register information will be loaded but the thread will not
 * be suspended.  If the suspend operation fails and the thread is not
 * running then it will be removed from the global thread list, otherwise
 * an exception will be thrown.
 *
 * Params:
 *  t = The thread to suspend.
 *
 * Throws:
 *  ThreadError if the suspend operation fails for a running thread.
 * Returns:
 *  Whether the thread is now suspended (true) or terminated (false).
 */
private extern (D) bool suspend( Thread t ) nothrow @nogc
{
    Duration waittime = dur!"usecs"(10);
 Lagain:
    if (!t.isRunning)
    {
        Thread.remove(t);
        return false;
    }
    else if (t.m_isInCriticalRegion)
    {
        Thread.criticalRegionLock.unlock_nothrow();
        Thread.sleep(waittime);
        if (waittime < dur!"msecs"(10)) waittime *= 2;
        Thread.criticalRegionLock.lock_nothrow();
        goto Lagain;
    }

    if(!osSuspend(t.m_osThread, t.m_lock, t.m_curr))
    {
        if ( !t.isRunning() )
        {
            Thread.remove( t );
            return false;
        }
        onThreadError( "Unable to suspend thread" );
    }
    
    return true;
}

/**
 * Suspend all threads but the calling thread for "stop the world" garbage
 * collection runs.  This function may be called multiple times, and must
 * be followed by a matching number of calls to thread_resumeAll before
 * processing is resumed.
 *
 * Throws:
 *  ThreadError if the suspend operation fails for a running thread.
 */
extern (C) void thread_suspendAll() nothrow
{
    // NOTE: We've got an odd chicken & egg problem here, because while the GC
    //       is required to call thread_init before calling any other thread
    //       routines, thread_init may allocate memory which could in turn
    //       trigger a collection.  Thus, thread_suspendAll, thread_scanAll,
    //       and thread_resumeAll must be callable before thread_init
    //       completes, with the assumption that no other GC memory has yet
    //       been allocated by the system, and thus there is no risk of losing
    //       data if the global thread list is empty.  The check of
    //       Thread.sm_tbeg below is done to ensure thread_init has completed,
    //       and therefore that calling Thread.getThis will not result in an
    //       error.  For the short time when Thread.sm_tbeg is null, there is
    //       no reason not to simply call the multithreaded code below, with
    //       the expectation that the foreach loop will never be entered.
    if ( !multiThreadedFlag && Thread.sm_tbeg )
    {
        if ( ++suspendDepth == 1 )
            suspend( Thread.getThis() );

        return;
    }

    Thread.slock.lock_nothrow();
    {
        if ( ++suspendDepth > 1 )
            return;

        Thread.criticalRegionLock.lock_nothrow();
        scope (exit) Thread.criticalRegionLock.unlock_nothrow();
        size_t cnt;
        bool suspendedSelf;
        Thread t = ThreadBase.sm_tbeg.toThread;
        while (t)
        {
            auto tn = t.next.toThread;
            if (suspend(t))
            {
                if (t is ThreadBase.getThis())
                    suspendedSelf = true;
                ++cnt;
            }
            t = tn;
        }

        // Called if exists. POSIX needs this
        static if(is(typeof(osThreadSuspendAll)))
        {
            osThreadSuspendAll(cnt, suspendedSelf);
        }
    }
}

/**
 * Resume the specified thread and unload stack and register information.
 * If the supplied thread is the calling thread, stack and register
 * information will be unloaded but the thread will not be resumed.  If
 * the resume operation fails and the thread is not running then it will
 * be removed from the global thread list, otherwise an exception will be
 * thrown.
 *
 * Params:
 *  t = The thread to resume.
 *
 * Throws:
 *  ThreadError if the resume fails for a running thread.
 */
private extern (D) void resume(ThreadBase _t) nothrow @nogc
{
    Thread t = _t.toThread;

    if(!osResume(t.m_osThread, t.m_lock, t.m_curr))
    {
        if ( !t.isRunning() )
        {
            Thread.remove( t );
            return;
        }
        onThreadError( "Unable to resume thread" );
    }
}


/**
 * Initializes the thread module.  This function must be called by the
 * garbage collector on startup and before any other thread routines
 * are called.
 */
extern (C) void thread_init() @nogc nothrow @system
{
    // NOTE: If thread_init itself performs any allocations then the thread
    //       routines reserved for garbage collector use may be called while
    //       thread_init is being processed.  However, since no memory should
    //       exist to be scanned at this point, it is sufficient for these
    //       functions to detect the condition and return immediately.

    initLowlevelThreads();
    Thread.initLocks();

    // Called if necessary.
    static if (is(typeof(osThreadInit)))
    {
        osThreadInit();
    }
    
    _mainThreadStore[] = __traits(initSymbol, Thread)[];
    Thread.sm_main = attachThread((cast(Thread)_mainThreadStore.ptr).__ctor());
}

private alias MainThreadStore = void[__traits(classInstanceSize, Thread)];
package __gshared align(__traits(classInstanceAlignment, Thread)) MainThreadStore _mainThreadStore;

/**
 * Terminates the thread module. No other thread routine may be called
 * afterwards.
 */
extern (C) void thread_term() @nogc nothrow
{
    thread_term_tpl!(Thread)(_mainThreadStore);
}


///////////////////////////////////////////////////////////////////////////////
// lowlovel threading support
///////////////////////////////////////////////////////////////////////////////

/**
 * Create a thread not under control of the runtime, i.e. TLS module constructors are
 * not run and the GC does not suspend it during a collection.
 *
 * Params:
 *  dg        = delegate to execute in the created thread.
 *  stacksize = size of the stack of the created thread. The default of 0 will select the
 *              platform-specific default size.
 *  cbDllUnload = Windows only: if running in a dynamically loaded DLL, this delegate will be called
 *              if the DLL is supposed to be unloaded, but the thread is still running.
 *              The thread must be terminated via `joinLowLevelThread` by the callback.
 *
 * Returns: the platform specific thread ID of the new thread. If an error occurs, `ThreadID.init`
 *  is returned.
 */
ThreadID createLowLevelThread(void delegate() nothrow dg, uint stacksize = 0,
                              void delegate() nothrow cbDllUnload = null) nothrow @nogc @system
{
    void delegate() nothrow* context = cast(void delegate() nothrow*)malloc(dg.sizeof);
    *context = dg;

    bool wasLocked = false;
 
    scope auto lockAboutToStart = () @nogc nothrow
    {
        lowlevelLock.lock_nothrow();

        ll_nThreads++;
        ll_pThreads = cast(ll_ThreadData*)realloc(ll_pThreads, ll_ThreadData.sizeof * ll_nThreads);

        wasLocked = true;
    };

    ThreadID tid = osCreateLowLevelThread(lockAboutToStart,
                                          stacksize, context, cbDllUnload);

    if(wasLocked)
    {
        lowlevelLock.unlock_nothrow();
    }

    return tid;
}

/**
 * Wait for a thread created with `createLowLevelThread` to terminate.
 *
 * Note: In a Windows DLL, if this function is called via DllMain with
 *       argument DLL_PROCESS_DETACH, the thread is terminated forcefully
 *       without proper cleanup as a deadlock would happen otherwise.
 *
 * Params:
 *  tid = the thread ID returned by `createLowLevelThread`.
 */
void joinLowLevelThread(ThreadID tid) nothrow @nogc
{
    if(!osJoinLowLevelThread(tid))
    {
        onThreadError("Unable to join low level thread");
    }
}

nothrow unittest
{
    struct TaskWithContect
    {
        shared int n = 0;
        void run() nothrow
        {
            n.atomicOp!"+="(1);
        }
    }
    TaskWithContect task;

    ThreadID[8] tids;
    for (int i = 0; i < tids.length; i++)
    {
        tids[i] = createLowLevelThread(&task.run);
        assert(tids[i] != ThreadID.init);
    }

    for (int i = 0; i < tids.length; i++)
        joinLowLevelThread(tids[i]);

    assert(task.n == tids.length);
}
