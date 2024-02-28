module rt.sys.solaris.osthread;

version (Solaris):

import rt.sys.posix.osthread;

import core.sys.posix.semaphore;
import core.sys.posix.pthread;
import core.sys.posix.signal;
import core.sys.posix.time;

import core.sys.solaris.sys.priocntl;
import core.sys.solaris.sys.types;
import core.sys.posix.sys.wait : idtype_t;

public import rt.sys.posix.osthread : ThreadID, getpid, osJoinLowLevelThread, osCreateLowLevelThread,
    thread_entryPoint, getCurrentThreadId, osThreadInit, osResume, osSuspend, osThreadSuspendAll;

struct OsThread
{
    int fakePriority = int.max;

    int priority()
    {
        return fakePriority==int.max? getDefaultPriority() : fakePriority;
    }

    bool priority( int val )
    {
        fakePriority = val;
        return true;
    }

    private static Priority loadPriorities() @nogc nothrow @trusted
    {
        Priority result;
        
        pcparms_t pcParms;
        pcinfo_t pcInfo;

        pcParms.pc_cid = PC_CLNULL;
        if (priocntl(idtype_t.P_PID, P_MYID, PC_GETPARMS, &pcParms) == -1)
            assert( 0, "Unable to get scheduling class" );

        pcInfo.pc_cid = pcParms.pc_cid;
        // PC_GETCLINFO ignores the first two args, use dummy values
        if (priocntl(idtype_t.P_PID, 0, PC_GETCLINFO, &pcInfo) == -1)
            assert( 0, "Unable to get scheduling class info" );

        pri_t* clparms = cast(pri_t*)&pcParms.pc_clparms;
        pri_t* clinfo = cast(pri_t*)&pcInfo.pc_clinfo;

        result.PRIORITY_MAX = clparms[0];

        if (pcInfo.pc_clname == "RT")
        {
            m_isRTClass = true;

            // For RT class, just assume it can't be changed
            result.PRIORITY_MIN = clparms[0];
            result.PRIORITY_DEFAULT = clparms[0];
        }
        else
        {
            m_isRTClass = false;

            // For all other scheduling classes, there are
            // two key values -- uprilim and maxupri.
            // maxupri is the maximum possible priority defined
            // for the scheduling class, and valid priorities
            // range are in [-maxupri, maxupri].
            //
            // However, uprilim is an upper limit that the
            // current thread can set for the current scheduling
            // class, which can be less than maxupri.  As such,
            // use this value for priorityMax since this is
            // the effective maximum.

            // maxupri
            result.PRIORITY_MIN = -cast(int)(clinfo[0]);
            // by definition
            result.PRIORITY_DEFAULT = 0;
        }

        return result;
    }

    bool priority( int val )
    {
        // the pthread_setschedprio(3c) and pthread_setschedparam functions
        // are broken for the default (TS / time sharing) scheduling class.
        // instead, we use priocntl(2) which gives us the desired behavior.

        // We hardcode the min and max priorities to the current value
        // so this is a no-op for RT threads.
        if (m_isRTClass)
            return true;

        pcparms_t   pcparm;

        pcparm.pc_cid = PC_CLNULL;
        if (priocntl(idtype_t.P_LWPID, P_MYID, PC_GETPARMS, &pcparm) == -1)
            throw new ThreadException( "Unable to get scheduling class" );

        pri_t* clparms = cast(pri_t*)&pcparm.pc_clparms;

        // clparms is filled in by the PC_GETPARMS call, only necessary
        // to adjust the element that contains the thread priority
        clparms[1] = cast(pri_t) val;

        if (priocntl(idtype_t.P_LWPID, P_MYID, PC_SETPARMS, &pcparm) == -1)
            throw new ThreadException( "Unable to set scheduling class" );

        return true;
    }

    alias m_osThread this;

    rt.sys.posix.osthread.OsThread m_osThread;
private:
    __gshared bool m_isRTClass;
}


extern (C) @nogc nothrow
{
    int thr_stksegment(stack_t* stk);
}

void* osGetStackBottom() nothrow @nogc
{
    stack_t stk;

    thr_stksegment(&stk);
    return stk.ss_sp;
}
