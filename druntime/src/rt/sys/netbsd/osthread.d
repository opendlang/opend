module rt.sys.netbsd.osthread;

version (NetBSD):

import rt.sys.posix.osthread;

public import rt.sys.posix.osthread : ThreadID, getpid, osJoinLowLevelThread, osCreateLowLevelThread,
    thread_entryPoint, getCurrentThreadId, osThreadInit, osResume, osSuspend, osThreadSuspendAll,
    osGetStackBottom;

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

    alias m_osThread this;

    rt.sys.posix.osthread.OsThread m_osThread;
}
