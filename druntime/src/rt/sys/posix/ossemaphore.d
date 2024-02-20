module rt.sys.posix.ossemaphore;

// If this is Darwin, the this file should be skipped because it has an
// own implementation of the OsSemaphore.
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

import core.sync.exception;
import core.time;

import core.sync.config;
import core.stdc.errno;
import core.sys.posix.pthread;
import core.sys.posix.semaphore;


struct OsSemaphore
{
    sem_t m_hndl;

    void create(uint initialValue)
    {
        int rc = sem_init( &m_hndl, 0, initialValue );
        if ( rc )
            throw new SyncError( "Unable to create semaphore" );
    }

    void destroy()
    {
        int rc = sem_destroy( &m_hndl );
        assert( !rc, "Unable to destroy semaphore" );
    }

    void wait()
    {
        while ( true )
        {
            if ( !sem_wait( &m_hndl ) )
                return;
            if ( errno != EINTR )
                throw new SyncError( "Unable to wait for semaphore" );
        }
    }

    bool wait( Duration period )
    {
        import core.sys.posix.time : clock_gettime, CLOCK_REALTIME;

        timespec t = void;
        clock_gettime( CLOCK_REALTIME, &t );
        mvtspec( t, period );

        while ( true )
        {
            if ( !sem_timedwait( &m_hndl, &t ) )
                return true;
            if ( errno == ETIMEDOUT )
                return false;
            if ( errno != EINTR )
                throw new SyncError( "Unable to wait for semaphore" );
        }
    }

    void notify()
    {
        int rc = sem_post( &m_hndl );
        if ( rc )
            throw new SyncError( "Unable to notify semaphore" );
    }

    bool tryWait()
    {
        while ( true )
        {
            if ( !sem_trywait( &m_hndl ) )
                return true;
            if ( errno == EAGAIN )
                return false;
            if ( errno != EINTR )
                throw new SyncError( "Unable to wait for semaphore" );
        }
    }
}