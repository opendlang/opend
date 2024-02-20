/**
 * The event module provides a primitive for lightweight signaling of other threads
 * (emulating Windows events on Posix)
 *
 * Copyright: Copyright (c) 2019 D Language Foundation
 * License: Distributed under the
 *    $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors: Rainer Schuetze
 * Source:    $(DRUNTIMESRC core/sync/event.d)
 */
module core.sync.event;

// This ugly version switch case will eventually be replace with
// mixin("import core.sys." ~ config.osSysDir ~ ".sync.osmutex");

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;


version (Windows)
{
    import rt.sys.windows.osevent;
}
else version (linux)
{
    import rt.sys.linux.osevent;
}
else version (Darwin)
{
    import rt.sys.darwin.osevent;
}
else version (DragonFlyBSD)
{
    import rt.sys.dragonflybsd.osevent;
}
else version (FreeBSD)
{
    import rt.sys.freebsd.osevent;
}
else version (NetBSD)
{
    import crtore.sys.netbsd.osevent;
}
else version (OpenBSD)
{
    import rt.sys.openbsd.osevent;
}
else version (Solaris)
{
    import rt.sys.solaris.osevent;
}
else
{
    static assert(false, "Platform not supported");
}

import core.time;

/**
 * represents an event. Clients of an event are suspended while waiting
 * for the event to be "signaled".
 *
 * Implemented using `pthread_mutex` and `pthread_condition` on Posix and
 * `CreateEvent` and `SetEvent` on Windows.
---
import core.sync.event, core.thread, std.file;

struct ProcessFile
{
    ThreadGroup group;
    Event event;
    void[] buffer;

    void doProcess()
    {
        event.wait();
        // process buffer
    }

    void process(string filename)
    {
        event.initialize(true, false);
        group = new ThreadGroup;
        for (int i = 0; i < 10; ++i)
            group.create(&doProcess);

        buffer = std.file.read(filename);
        event.setIfInitialized();
        group.joinAll();
        event.terminate();
    }
}
---
 */
struct Event
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
        initialize(manualReset, initialState);
    }

    /**
     * Initializes an event object. Does nothing if the event is already initialized.
     *
     * Params:
     *  manualReset  = the state of the event is not reset automatically after resuming waiting clients
     *  initialState = initial state of the signal
     */
    void initialize(bool manualReset, bool initialState)
    {
        osEvent.create(manualReset, initialState);
    }

    // copying not allowed, can produce resource leaks
    @disable this(this);
    @disable void opAssign(Event);

    ~this()
    {
        terminate();
    }

    /**
     * deinitialize event. Does nothing if the event is not initialized. There must not be
     * threads currently waiting for the event to be signaled.
    */
    void terminate()
    {
        osEvent.destroy();
    }

    deprecated ("Use setIfInitialized() instead") void set()
    {
        setIfInitialized();
    }

    /// Set the event to "signaled", so that waiting clients are resumed
    void setIfInitialized()
    {
        osEvent.setIfInitialized();
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

    OsEvent osEvent;
}

// Test single-thread (non-shared) use.
@nogc nothrow unittest
{
    // auto-reset, initial state false
    Event ev1 = Event(false, false);
    assert(!ev1.wait(1.dur!"msecs"));
    ev1.setIfInitialized();
    assert(ev1.wait());
    assert(!ev1.wait(1.dur!"msecs"));

    // manual-reset, initial state true
    Event ev2 = Event(true, true);
    assert(ev2.wait());
    assert(ev2.wait());
    ev2.reset();
    assert(!ev2.wait(1.dur!"msecs"));
}

unittest
{
    import core.thread, core.atomic;

    scope event      = new Event(true, false);
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

    event.setIfInitialized();
    group.joinAll();

    assert(numRunning == numThreads);

    assert(MonoTime.currTime - start < 5.dur!"seconds");
}
