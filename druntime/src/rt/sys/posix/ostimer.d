module rt.sys.posix.ostimer;

// If this is Darwin, the this file should be skipped because it has an
// own implementation of the OsTimer.
version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (Darwin) {}
else version (Posix):

import core.time;
import core.timer : TimerException;
import core.thread;

import core.sys.posix.time;
import core.sys.posix.signal;
import core.sys.posix.semaphore;
import core.sys.posix.pthread;

private import rt.timerqueue;

import rt.sys.config;
mixin("import " ~ osMutexImport ~ ";");
mixin("import " ~ osSemaphoreImport ~ ";");


struct OsTimer
{
    void create(void function(void *arg) nothrow callbackFn, void* arg)
    {
        // Lazy initialization. The timer starts a new global thread and do a
        // WaitForSingleObject waiting for timeouts.
        // There is no point of creating the thread if the timer isn't used at all.
        initMutex.lockNoThrow();

        if(!timerInitialized)
        {
            initializeTimer();
            timerInitialized = true;
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
    void function(void *arg) nothrow m_callbackFn;
    void *m_arg;
}


private __gshared OsMutex initMutex;
private __gshared sem_t timerSem;
private __gshared timer_t timerId;
private __gshared bool timerInitialized = false;
private __gshared TimerQueue!(OsTimer*) m_timerQueue;
private __gshared pthread_t loopThread;


shared static this()
{
    initMutex.create();
}


shared static ~this()
{
    initMutex.destroy();

    if(timerInitialized)
    {
        sem_destroy( &timerSem );
        timer_delete(timerId);
    }
}

private void initializeTimer()
{
    m_timerQueue.initialize(&setTimer, &cancelTimer);

    sigaction_t sa;
    sa.sa_flags = SA_SIGINFO;
    sa.sa_sigaction = &handler;
    sigemptyset(&sa.sa_mask);
    if (sigaction(SIGALRM, &sa, null) == -1)
    {
        throw new TimerException("sigaction failed");
    }

    sigevent sev;
    sev.sigev_notify = SIGEV_SIGNAL;
    sev.sigev_signo = SIGALRM;
    sev.sigev_value.sival_ptr = &timerId;

    /* create timer */
    int res = timer_create(CLOCK_MONOTONIC, &sev, &timerId);
    if (res != 0){
        import core.stdc.stdio;
        printf("timer_create\n");
    }

    if(sem_init( &timerSem, 0, 0 ) != 0)
    {
        throw new TimerException("sem_init failed");
    }

    if(pthread_create(&loopThread, null, &timerWaitLoop, null) != 0)
    {
        throw new TimerException("pthread_create failed");
    }
}


private void setTimer(MonoTime expireTime)
{
    Duration d = expireTime - MonoTime.currTime();

    long total = d.total!"nsecs";

    itimerspec its;
    its.it_value.tv_sec  = cast(typeof(its.it_value.tv_sec))(total / 1_000_000_000);
    its.it_value.tv_nsec = cast(typeof(its.it_value.tv_nsec))(total % 1_000_000_000);
    its.it_interval.tv_sec  = 0;
    its.it_interval.tv_nsec = 0;

    int res = timer_settime(timerId, 0, &its, null);
    if (res != 0)
    {
        throw new TimerException("timer_settime failed");
    }
}


private void cancelTimer()
{
    itimerspec its;
    its.it_value.tv_sec  = 0;
    its.it_value.tv_nsec = 0;
    its.it_interval.tv_sec  = 0;
    its.it_interval.tv_nsec = 0;

    int res = timer_settime(timerId, 0, &its, null);
    if (res != 0)
    {
        throw new TimerException("timer_settime failed");
    }
}


private extern(C) void* timerWaitLoop(void*)
{
    while(true)
    {
        sem_wait( &timerSem );

        OsTimer *timedOut;
        while((timedOut = m_timerQueue.getNextExpiredTimer(MonoTime.currTime())) != null)
        {
            timedOut.m_callbackFn(timedOut.m_arg);
        }

        m_timerQueue.setTimer();
    }
}


private extern(C) void handler(int sig, siginfo_t *si, void *uc)
{
    sem_post( &timerSem );
}
