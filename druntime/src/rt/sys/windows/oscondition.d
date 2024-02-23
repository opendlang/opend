module rt.sys.windows.oscondition;

version (Windows):

import core.sync.exception;
import core.sync.mutex;
import core.time;

import core.exception : AssertError, staticError;

import core.sync.semaphore;
import core.sys.windows.basetsd /+: HANDLE+/;
import core.sys.windows.winbase /+: CloseHandle, CreateSemaphoreA, CRITICAL_SECTION,
    DeleteCriticalSection, EnterCriticalSection, INFINITE, InitializeCriticalSection,
    LeaveCriticalSection, ReleaseSemaphore, WAIT_OBJECT_0, WaitForSingleObject+/;
import core.sys.windows.windef /+: BOOL, DWORD+/;
import core.sys.windows.winerror /+: WAIT_TIMEOUT+/;


struct OsCondition
{
    void create(Mutex m) nothrow @trusted @nogc
    {
        m_blockLock = CreateSemaphoreA( null, 1, 1, null );
        if ( m_blockLock == m_blockLock.init )
            throw staticError!AssertError("Unable to initialize condition", __FILE__, __LINE__);
        scope(failure) CloseHandle( m_blockLock );

        m_blockQueue = CreateSemaphoreA( null, 0, int.max, null );
        if ( m_blockQueue == m_blockQueue.init )
            throw staticError!AssertError("Unable to initialize condition", __FILE__, __LINE__);
        scope(failure) CloseHandle( m_blockQueue );

        InitializeCriticalSection( cast(RTL_CRITICAL_SECTION*) &m_unblockLock );
        m_assocMutex = m;
    }

    void destroy() @nogc
    {
        BOOL rc = CloseHandle( m_blockLock );
        assert( rc, "Unable to destroy condition" );
        rc = CloseHandle( m_blockQueue );
        assert( rc, "Unable to destroy condition" );
        DeleteCriticalSection( &m_unblockLock );
    }

    void wait()
    {
        timedWait( INFINITE );
    }

    bool wait( Duration val)
    {
        auto maxWaitMillis = dur!("msecs")( uint.max - 1 );

        while ( val > maxWaitMillis )
        {
            if ( timedWait( cast(uint)
                            maxWaitMillis.total!"msecs" ) )
                return true;
            val -= maxWaitMillis;
        }
        return timedWait( cast(uint) val.total!"msecs" );
    }

    void notify()
    {
        notify_( false );
    }

    void notifyAll()
    {
        notify_( true );
    }

    @property Mutex mutex()
    {
        return m_assocMutex;
    }

     /// ditto
    @property shared(Mutex) mutex() shared
    {
        import core.atomic : atomicLoad;
        return atomicLoad(m_assocMutex);
    }

    // undocumented function for internal use
    final @property Mutex mutex_nothrow() pure nothrow @safe @nogc
    {
        return m_assocMutex;
    }

    // ditto
    final @property shared(Mutex) mutex_nothrow() shared pure nothrow @safe @nogc
    {
        import core.atomic : atomicLoad;
        return atomicLoad(m_assocMutex);
    }

private:
    bool timedWait( DWORD timeout )
    {
        int   numSignalsLeft;
        int   numWaitersGone;
        DWORD rc;

        rc = WaitForSingleObject( cast(HANDLE) m_blockLock, INFINITE );
        assert( rc == WAIT_OBJECT_0 );

        EnterCriticalSection( &m_unblockLock );
        m_numWaitersBlocked++;
        LeaveCriticalSection( &m_unblockLock );

        rc = ReleaseSemaphore( cast(HANDLE) m_blockLock, 1, null );
        assert( rc );

        m_assocMutex.unlock();
        scope(failure) m_assocMutex.lock();

        rc = WaitForSingleObject( cast(HANDLE) m_blockQueue, timeout );
        assert( rc == WAIT_OBJECT_0 || rc == WAIT_TIMEOUT );
        bool timedOut = (rc == WAIT_TIMEOUT);

        EnterCriticalSection( &m_unblockLock );
        scope(failure) LeaveCriticalSection( &m_unblockLock );

        if ( (numSignalsLeft = m_numWaitersToUnblock) != 0 )
        {
            if ( timedOut )
            {
                // timeout (or canceled)
                if ( m_numWaitersBlocked != 0 )
                {
                    m_numWaitersBlocked--;
                    // do not unblock next waiter below (already unblocked)
                    numSignalsLeft = 0;
                }
                else
                {
                    // spurious wakeup pending!!
                    m_numWaitersGone = 1;
                }
            }
            if ( (--m_numWaitersToUnblock) == 0 )
            {
                if ( m_numWaitersBlocked != 0 )
                {
                    // open the gate
                    rc = ReleaseSemaphore( cast(HANDLE) m_blockLock, 1, null );
                    assert( rc );
                    // do not open the gate below again
                    numSignalsLeft = 0;
                }
                else if ( (numWaitersGone = m_numWaitersGone) != 0 )
                {
                    m_numWaitersGone = 0;
                }
            }
        }
        else if ( (++m_numWaitersGone) == int.max / 2 )
        {
            // timeout/canceled or spurious event :-)
            rc = WaitForSingleObject( cast(HANDLE) m_blockLock, INFINITE );
            assert( rc == WAIT_OBJECT_0 );
            // something is going on here - test of timeouts?
            m_numWaitersBlocked -= m_numWaitersGone;
            rc = ReleaseSemaphore( cast(HANDLE) m_blockLock, 1, null );
            assert( rc == WAIT_OBJECT_0 );
            m_numWaitersGone = 0;
        }

        LeaveCriticalSection( &m_unblockLock );

        if ( numSignalsLeft == 1 )
        {
            // better now than spurious later (same as ResetEvent)
            for ( ; numWaitersGone > 0; --numWaitersGone )
            {
                rc = WaitForSingleObject( cast(HANDLE) m_blockQueue, INFINITE );
                assert( rc == WAIT_OBJECT_0 );
            }
            // open the gate
            rc = ReleaseSemaphore( cast(HANDLE) m_blockLock, 1, null );
            assert( rc );
        }
        else if ( numSignalsLeft != 0 )
        {
            // unblock next waiter
            rc = ReleaseSemaphore( cast(HANDLE) m_blockQueue, 1, null );
            assert( rc );
        }
        m_assocMutex.lock();
        return !timedOut;
    }


    void notify_( bool all )
    {
        DWORD rc;

        EnterCriticalSection( &m_unblockLock );
        scope(failure) LeaveCriticalSection( &m_unblockLock );

        if ( m_numWaitersToUnblock != 0 )
        {
            if ( m_numWaitersBlocked == 0 )
            {
                LeaveCriticalSection( &m_unblockLock );
                return;
            }
            if ( all )
            {
                m_numWaitersToUnblock += m_numWaitersBlocked;
                m_numWaitersBlocked = 0;
            }
            else
            {
                m_numWaitersToUnblock++;
                m_numWaitersBlocked--;
            }
            LeaveCriticalSection( &m_unblockLock );
        }
        else if ( m_numWaitersBlocked > m_numWaitersGone )
        {
            rc = WaitForSingleObject( cast(HANDLE) m_blockLock, INFINITE );
            assert( rc == WAIT_OBJECT_0 );
            if ( 0 != m_numWaitersGone )
            {
                m_numWaitersBlocked -= m_numWaitersGone;
                m_numWaitersGone = 0;
            }
            if ( all )
            {
                m_numWaitersToUnblock = m_numWaitersBlocked;
                m_numWaitersBlocked = 0;
            }
            else
            {
                m_numWaitersToUnblock = 1;
                m_numWaitersBlocked--;
            }
            LeaveCriticalSection( &m_unblockLock );
            rc = ReleaseSemaphore( cast(HANDLE) m_blockQueue, 1, null );
            assert( rc );
        }
        else
        {
            LeaveCriticalSection( &m_unblockLock );
        }
    }


    // NOTE: This implementation uses Algorithm 8c as described here:
    //       http://groups.google.com/group/comp.programming.threads/
    //              browse_frm/thread/1692bdec8040ba40/e7a5f9d40e86503a
    HANDLE              m_blockLock;    // auto-reset event (now semaphore)
    HANDLE              m_blockQueue;   // auto-reset event (now semaphore)
    Mutex               m_assocMutex;   // external mutex/CS
    CRITICAL_SECTION    m_unblockLock;  // internal mutex/CS
    int                 m_numWaitersGone        = 0;
    int                 m_numWaitersBlocked     = 0;
    int                 m_numWaitersToUnblock   = 0;
}