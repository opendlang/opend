module rt.sys.windows.ostimer;

version (Windows):

import core.sys.windows.winbase;
import core.sys.windows.windef;
import core.time;
import core.atomic;
import core.exception;
import core.thread;
import core.sync.mutex;
import core.timer : TimerException;

import rt.timerqueue;

import rt.sys.windows.osmutex;


struct OsTimer
{
    void create(void function(void*) callbackFn, void* arg = null)
    {
        // Lazy initialization. The timer starts a new global thread and do a
        // WaitForSingleObject waiting for timeouts.
        // There is no point of creating the thread if the timer isn't used at all.
        initMutex.lockNoThrow();

        if(hTimer == NULL)
        {
            initializeTimer();
        }

        initMutex.unlockNoThrow();

        m_callbackFn = callbackFn;
        m_arg = arg;
    }

    void destroy()
    {

    }

    private void start(Duration firstDelay, Duration recurrentDelay)
    {
        m_expireTime = MonoTime.currTime() + firstDelay;
        m_recurrentDelay = recurrentDelay;

        m_timerQueue.insert(&this);
    }

    void start(Duration delay)
    {
        start(delay, Duration.zero());
    }

    void startRecurrent(Duration recurrentDelay)
    {
        start(recurrentDelay, recurrentDelay);
    }

    void startRecurrent(Duration firstDelay, Duration recurrentDelay)
    {
        start(firstDelay, recurrentDelay);
    }

    void stop()
    {
        m_timerQueue.remove(&this);
    }

    // These members are for TimerQueue
    MonoTime m_expireTime;
    Duration m_recurrentDelay;
    bool m_inserted;
    // --------------------------------

    import rt.util.intrusivedlist : IntrusiveDListNode;
    IntrusiveDListNode m_timerQueueNode;

private:
    void function(void*) m_callbackFn;
    void *m_arg;
}


private __gshared OsMutex initMutex;
private __gshared HANDLE hTimer = NULL;
private __gshared TimerQueue!(OsTimer*) m_timerQueue;


shared static this()
{
    initMutex.create();
}


shared static ~this()
{
    initMutex.destroy();
    if(hTimer != NULL)
    {
        CloseHandle(hTimer);
        hTimer = NULL;
    }
}

private void initializeTimer()
{
    m_timerQueue.initialize(&setTimer, &cancelTimer);

    hTimer = CreateWaitableTimerEx(NULL, NULL,
                                   CREATE_WAITABLE_TIMER_HIGH_RESOLUTION,
                                   TIMER_ALL_ACCESS);
    if (hTimer == NULL)
    {
        throw new TimerException("CreateWaitableTimerEx failed");
    }

    if(!CreateThread(null, 0, &timerWaitLoop, null, 0, null))
    {
        throw new TimerException("CreateThread failed");
    }
}


private void setTimer(MonoTime expireTime)
{
    Duration d = expireTime - MonoTime.currTime();

    LARGE_INTEGER dueTime;
    dueTime.QuadPart = -d.total!"hnsecs";
    if (!SetWaitableTimer(hTimer, &dueTime, 0, NULL, NULL, 0))
    {
        throw new TimerException("SetWaitableTimer failed");
    }
}


private void cancelTimer()
{
    if (!CancelWaitableTimer(hTimer))
    {
        throw new TimerException("CancelWaitableTimer failed");
    }
}


private extern(Windows) uint timerWaitLoop(void*)
{
    while(true)
    {
        DWORD ret = WaitForSingleObject(hTimer, INFINITE);
        if (ret != WAIT_OBJECT_0) {
            break;
        }

        OsTimer *timedOut;
        while((timedOut = m_timerQueue.getNextExpiredTimer(MonoTime.currTime())) != null)
        {
            timedOut.m_callbackFn(timedOut.m_arg);
        }

        m_timerQueue.setTimer();
    }

    return 0;
}
