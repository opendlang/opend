module core.timer;

import core.time;



/++
    Exception type used by core.timer.
  +/
class TimerException : Exception
{
    /++
        Params:
            msg  = The message for the exception.
            file = The file where the exception occurred.
            line = The line number where the exception occurred.
            next = The previous exception in the chain of exceptions, if any.
      +/
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        super(msg, file, line, next);
    }

    /++
        Params:
            msg  = The message for the exception.
            next = The previous exception in the chain of exceptions.
            file = The file where the exception occurred.
            line = The line number where the exception occurred.
      +/
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) @safe pure nothrow
    {
        super(msg, file, line, next);
    }
}


/++
    The Timer object is is a programmable timer that can time out at a desired duration.
    The timer is intended for low level functionality which libraries can build upon.

    When the timer times out, the a configurable timer callback is called.

    NOTE: that the timer callback context is using a low lever thread which means
    that garbage collecting is not enabled. The timer callback should perform simple
    tasks like raising a semaphore, set a condition variable or similar.
  +/
class Timer
{
    /**
     * Constructs a timer
     *
     * Params:
     *  callbackDg = a delegate that is called when the timer times out
     *  arg = optional argument for the timer callback delgate
     */
    this(void delegate(void*) nothrow callbackDg, void* arg = null)
    {
        m_osTimer.create(&timeoutHandler, cast(void*)this);
        m_arg = arg;
        m_callbackDg = callbackDg;
    }

    /**
     * Desconstructor for the timer
     */
    ~this()
    {
        m_osTimer.destroy();
    }

    /**
     * Starts the timer in a single shot mode. If called when the timer is running,
     * rearms the timer.
     *
     * Params:
     *  duration = The duration until the timer times out
     */
    void start(Duration duration)
    {
        m_osTimer.start(duration);
    }

    /**
     * Starts the timer in a recurrent mode. The timer keeps going until stop 
     * is called. If called when the timer is running, rearms the timer.
     *
     * Params:
     *  recurrentDuration = The duration of the reccurent timeout
     */
    void startRecurrent(Duration recurrentDuration)
    {
        m_osTimer.startRecurrent(recurrentDuration);
    }

    /**
     * Starts the timer in a recurrent mode. The timer keeps going until stop 
     * is called. The timer is initially to timeout on the first timeout argument
     * and then recurrent timeouts for the second duration argument. If called
     * when the timer is running, rearms the timer.
     *
     * Params:
     *  firstDuration = The duration of the first timeout
     *  recurrentDuration = The duration of the subsequent timeouts
     */
    void startRecurrent(Duration firstDuration, Duration recurrentDuration)
    {
        m_osTimer.startRecurrent(firstDuration, recurrentDuration);
    }

    /**
     * Stops the timer if it is enabled.
     */
    void stop()
    {
        m_osTimer.stop();
    }

private:
    import rt.sys.config;
    mixin("import " ~ osTimerImport ~ ";");

    OsTimer m_osTimer;
    void *m_arg;
    void delegate(void *arg) nothrow m_callbackDg;
}


private void timeoutHandler(void *arg) nothrow
{
    Timer timer = cast(Timer)arg;
    timer.m_callbackDg(timer.m_arg);
}

unittest // Test single shot timer
{
    import std.stdio;
    import core.sync.semaphore;
    import std.functional;
    import std.datetime.stopwatch;

    auto sem = new Semaphore();

    const Duration desiredAccuracy = dur!"msecs"(4);

    void timerCb(void* arg) nothrow
    {
        assert(cast(int)arg == 42);
        try
        {
            sem.notify();
        }
        catch(Exception e)
        {
            assert(false, "failed to semaphore notify");
        }
    }

    auto elapsedTime = dur!"msecs"(50);

    Timer timer = new Timer(toDelegate(&timerCb), cast(void*)42);

    StopWatch w;
    w.start();
    timer.start(elapsedTime);

    if(!sem.wait(dur!"seconds"(1)))
    {
        assert(0, "The callback never occurred");
    }

    w.stop();
    auto d = w.peek();
    writeln("got timer after ", d.total!"usecs");

    //assert(abs((d - elapsedTime)) <= desiredAccuracy);
}


unittest // Test recurrent timer with initial timeout of 20ms then 10ms
{
    import std.stdio;
    import core.sync.semaphore;
    import std.functional;
    import std.datetime.stopwatch;

    const Duration desiredAccuracy = dur!"msecs"(4);

    auto sem = new Semaphore();

    void timerCb(void* arg) nothrow
    {
        assert(cast(int)arg == 42);
        try
        {
            sem.notify();
        }
        catch(Exception e)
        {
            assert(false, "failed to semaphore notify");
        }
    }

    auto elapsedTime = dur!"msecs"(20);
    auto elapsedTime2 = dur!"msecs"(10);

    Timer timer = new Timer(toDelegate(&timerCb), cast(void*)42);

    StopWatch w;
    w.start();
    timer.startRecurrent(elapsedTime, elapsedTime2);

    int i = 0;
    while(true)
    {
        if(!sem.wait(dur!"seconds"(5)))
        {
            assert(0, "The callback never occurred");
        }

        w.stop();
        auto d = w.peek();
        w.reset();
        w.start();
        writeln("got timer after ", d.total!"usecs");

        i++;
        if(i == 0)
        {
            //assert(abs((d - elapsedTime)) <= desiredAccuracy);
        }
        else if(i >= 1 && i <= 4)
        {
            //assert(abs((d - elapsedTime2)) <= desiredAccuracy);
        }
        if(i == 5)
        {
            timer.stop();
            break;
        }
    }
}


unittest // Test stacking up timers in the queue
{
    import std.stdio;
    import core.sync.semaphore;
    import std.functional;
    import std.datetime.stopwatch;

    const Duration desiredAccuracy = dur!"msecs"(4);

    auto sem = new Semaphore();

    void timerCb(void* arg) nothrow
    {
        assert(cast(int)arg == 42);
        try
        {
            sem.notify();
        }
        catch(Exception e)
        {
            assert(false, "failed to semaphore notify");
        }
    }

    StopWatch w;
    w.start();
    foreach(i; 0..5)
    {
        Timer timer = new Timer(toDelegate(&timerCb), cast(void*)42);
        timer.start(dur!"msecs"(10 + (i * 10)));
    }

    int i = 0;
    while(true)
    {
        if(!sem.wait(dur!"seconds"(5)))
        {
            assert(0, "The callback never occurred");
        }

        i++;

        writeln("got timer after ", w.peek().total!"usecs");
        if(i == 5)
        {
            w.stop();
            break;
        }
    }
}