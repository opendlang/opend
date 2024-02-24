/**
 * The semaphore module provides a general use semaphore for synchronization.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Sean Kelly
 * Source:    $(DRUNTIMESRC core/sync/_semaphore.d)
 */

/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.sync.semaphore;


public import core.sync.exception;
public import core.time;

import rt.sys.config;

mixin("import " ~ osSemaphoreImport ~ ";");

////////////////////////////////////////////////////////////////////////////////
// Semaphore
//
// void wait();
// void notify();
// bool tryWait();
////////////////////////////////////////////////////////////////////////////////


/**
 * This class represents a general counting semaphore as concieved by Edsger
 * Dijkstra.  As per Mesa type monitors however, "signal" has been replaced
 * with "notify" to indicate that control is not transferred to the waiter when
 * a notification is sent.
 */
class Semaphore
{
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Initializes a semaphore object with the specified initial count.
     *
     * Params:
     *  count = The initial count for the semaphore.
     *
     * Throws:
     *  SyncError on error.
     */
    this( uint count = 0 )
    {
        osSemaphore.create(count);
    }


    ~this()
    {
        osSemaphore.destroy();
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Actions
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Wait until the current count is above zero, then atomically decrement
     * the count by one and return.
     *
     * Throws:
     *  SyncError on error.
     */
    void wait()
    {
        osSemaphore.wait();
    }


    /**
     * Suspends the calling thread until the current count moves above zero or
     * until the supplied time period has elapsed.  If the count moves above
     * zero in this interval, then atomically decrement the count by one and
     * return true.  Otherwise, return false.
     *
     * Params:
     *  period = The time to wait.
     *
     * In:
     *  period must be non-negative.
     *
     * Throws:
     *  SyncError on error.
     *
     * Returns:
     *  true if notified before the timeout and false if not.
     */
    bool wait( Duration period )
    in
    {
        assert( !period.isNegative );
    }
    do
    {
        return osSemaphore.wait(period);
    }


    /**
     * Atomically increment the current count by one.  This will notify one
     * waiter, if there are any in the queue.
     *
     * Throws:
     *  SyncError on error.
     */
    void notify()
    {
        osSemaphore.notify();
    }


    /**
     * If the current count is equal to zero, return.  Otherwise, atomically
     * decrement the count by one and return true.
     *
     * Throws:
     *  SyncError on error.
     *
     * Returns:
     *  true if the count was above zero and false if not.
     */
    bool tryWait()
    {
        return osSemaphore.tryWait();
    }


protected:

    OsSemaphore osSemaphore;
}


////////////////////////////////////////////////////////////////////////////////
// Unit Tests
////////////////////////////////////////////////////////////////////////////////

unittest
{
    import core.thread, core.atomic;

    void testWait()
    {
        auto semaphore = new Semaphore;
        shared bool stopConsumption = false;
        immutable numToProduce = 20;
        immutable numConsumers = 10;
        shared size_t numConsumed;
        shared size_t numComplete;

        void consumer()
        {
            while (true)
            {
                semaphore.wait();

                if (atomicLoad(stopConsumption))
                    break;
                atomicOp!"+="(numConsumed, 1);
            }
            atomicOp!"+="(numComplete, 1);
        }

        void producer()
        {
            assert(!semaphore.tryWait());

            foreach (_; 0 .. numToProduce)
                semaphore.notify();

            // wait until all items are consumed
            while (atomicLoad(numConsumed) != numToProduce)
                Thread.yield();

            // mark consumption as finished
            atomicStore(stopConsumption, true);

            // wake all consumers
            foreach (_; 0 .. numConsumers)
                semaphore.notify();

            // wait until all consumers completed
            while (atomicLoad(numComplete) != numConsumers)
                Thread.yield();

            assert(!semaphore.tryWait());
            semaphore.notify();
            assert(semaphore.tryWait());
            assert(!semaphore.tryWait());
        }

        auto group = new ThreadGroup;

        for ( int i = 0; i < numConsumers; ++i )
            group.create(&consumer);
        group.create(&producer);
        group.joinAll();
    }


    void testWaitTimeout()
    {
        auto sem = new Semaphore;
        shared bool semReady;
        bool alertedOne, alertedTwo;

        void waiter()
        {
            while (!atomicLoad(semReady))
                Thread.yield();
            alertedOne = sem.wait(dur!"msecs"(1));
            alertedTwo = sem.wait(dur!"msecs"(1));
            assert(alertedOne && !alertedTwo);
        }

        auto thread = new Thread(&waiter);
        thread.start();

        sem.notify();
        atomicStore(semReady, true);
        thread.join();
        assert(alertedOne && !alertedTwo);
    }

    testWait();
    testWaitTimeout();
}
