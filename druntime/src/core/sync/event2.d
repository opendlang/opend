/**
 * The event module provides a primitive for lightweight signaling of other threads
 * (emulating Windows events on Posix)
 *
 * Copyright: Copyright (c) 2019 D Language Foundation
 * License: Distributed under the
 *    $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 */
module core.sync.event2;

import core.time;

struct Event2
{
nothrow @nogc:
    /**
     * Creates an event object.
     *
     * Params:
     *  manualReset  = the state of the event is not reset automatically after resuming waiting clients
     *  initialState = initial state of the signal
     */
    this(bool manualReset, bool initialState)
    {
        osEvent = OsEvent(manualReset, initialState);
    }

    // copying not allowed, can produce resource leaks
    @disable this(this);

    ref Event2 opAssign(return scope Event2 s) @live
    {
        this.osEvent = s.osEvent;

        return this;
    }

    /// Set the event to "signaled", so that waiting clients are resumed
    void set()
    {
        osEvent.set();
    }

    /// Reset the event manually
    void reset()
    {
        osEvent.reset();
    }

    /**
     * Wait for the event to be signaled without timeout.
     *
     * Returns:
     *  `true` if the event is in signaled state, `false` if the event is uninitialized or another error occured
     */
    bool wait()
    {
        return osEvent.wait();
    }

    /**
     * Wait for the event to be signaled with timeout.
     *
     * Params:
     *  tmout = the maximum time to wait
     * Returns:
     *  `true` if the event is in signaled state, `false` if the event was nonsignaled for the given time or
     *  the event is uninitialized or another error occured
     */
    bool wait(Duration tmout)
    {
        return osEvent.wait(tmout);
    }

private:
    import rt.sys.config;

    mixin("import " ~ osEventImport ~ ";");
    OsEvent osEvent;
}

// Test single-thread (non-shared) use.
@nogc nothrow unittest
{
    // auto-reset, initial state false
    Event2 ev1 = Event2(false, false);
    assert(!ev1.wait(1.dur!"msecs"));
    ev1.set();
    assert(ev1.wait());
    assert(!ev1.wait(1.dur!"msecs"));

    // manual-reset, initial state true
    Event2 ev2 = Event2(true, true);
    assert(ev2.wait());
    assert(ev2.wait());
    ev2.reset();
    assert(!ev2.wait(1.dur!"msecs"));
}

unittest
{
    import core.thread, core.atomic;

    scope event      = new Event2(true, false);
    int  numThreads = 10;
    shared int numRunning = 0;

    void testFn()
    {
        event.wait(8.dur!"seconds"); // timeout below limit for druntime test_runner
        numRunning.atomicOp!"+="(1);
    }

    auto group = new ThreadGroup;

    for (int i = 0; i < numThreads; ++i)
        group.create(&testFn);

    auto start = MonoTime.currTime;
    assert(numRunning == 0);

    event.set();
    group.joinAll();

    assert(numRunning == numThreads);

    assert(MonoTime.currTime - start < 5.dur!"seconds");
}
