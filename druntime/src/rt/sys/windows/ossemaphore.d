module rt.sys.windows.ossemaphore;

version (Windows):

public import core.sync.exception;
public import core.time;

import core.sys.windows.basetsd /+: HANDLE+/;
import core.sys.windows.winbase /+: CloseHandle, CreateSemaphoreA, INFINITE,
    ReleaseSemaphore, WAIT_OBJECT_0, WaitForSingleObject+/;
import core.sys.windows.windef /+: BOOL, DWORD+/;
import core.sys.windows.winerror /+: WAIT_TIMEOUT+/;



struct OsSemaphore
{
    HANDLE m_hndl;

    void create(uint initialValue)
    {
        m_hndl = CreateSemaphoreA( null, initialValue, int.max, null );
        if ( m_hndl == m_hndl.init )
            throw new SyncError( "Unable to create semaphore" );
    }

    void destroy()
    {
        BOOL rc = CloseHandle( m_hndl );
        assert( rc, "Unable to destroy semaphore" );
    }

    void wait()
    {
        DWORD rc = WaitForSingleObject( m_hndl, INFINITE );
        if ( rc != WAIT_OBJECT_0 )
            throw new SyncError( "Unable to wait for semaphore" );
    }

    bool wait( Duration period )
    {
        auto maxWaitMillis = dur!("msecs")( uint.max - 1 );

        while ( period > maxWaitMillis )
        {
            auto rc = WaitForSingleObject( m_hndl, cast(uint)maxWaitMillis.total!"msecs" );
            switch ( rc )
            {
                case WAIT_OBJECT_0:
                    return true;
                case WAIT_TIMEOUT:
                    period -= maxWaitMillis;
                    continue;
                default:
                    throw new SyncError( "Unable to wait for semaphore" );
            }
        }
        switch ( WaitForSingleObject( m_hndl, cast(uint) period.total!"msecs" ) )
        {
            case WAIT_OBJECT_0:
                return true;
            case WAIT_TIMEOUT:
                return false;
            default:
                throw new SyncError( "Unable to wait for semaphore" );
        }
    }

    void notify()
    {
        if ( !ReleaseSemaphore( m_hndl, 1, null ) )
            throw new SyncError( "Unable to notify semaphore" );
    }

    bool tryWait()
    {
        switch ( WaitForSingleObject( m_hndl, 0 ) )
        {
            case WAIT_OBJECT_0:
                return true;
            case WAIT_TIMEOUT:
                return false;
            default:
                throw new SyncError( "Unable to wait for semaphore" );
        }
    }
}