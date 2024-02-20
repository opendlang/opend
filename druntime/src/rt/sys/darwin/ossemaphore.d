module rt.sys.darwin.ossemaphore;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (Darwin):

import core.sync.exception;
import core.time;

import core.sync.config;
import core.stdc.errno;
import core.sys.posix.time;
import core.sys.darwin.mach.semaphore;


struct OsSemaphore
{
    semaphore_t m_hndl;

    void create(uint initialValue)
    {
        auto rc = semaphore_create( mach_task_self(), &m_hndl, SYNC_POLICY_FIFO, initialValue );
        if ( rc )
            throw new SyncError( "Unable to create semaphore" );
    }

    void destroy()
    {
        auto rc = semaphore_destroy( mach_task_self(), m_hndl );
        assert( !rc, "Unable to destroy semaphore" );
    }

    void wait()
    {
        while ( true )
        {
            auto rc = semaphore_wait( m_hndl );
            if ( !rc )
                return;
            if ( rc == KERN_ABORTED && errno == EINTR )
                continue;
            throw new SyncError( "Unable to wait for semaphore" );
        }
    }

    bool wait( Duration period )
    {
        mach_timespec_t t = void;
        (cast(byte*) &t)[0 .. t.sizeof] = 0;

        if ( period.total!"seconds" > t.tv_sec.max )
        {
            t.tv_sec  = t.tv_sec.max;
            t.tv_nsec = cast(typeof(t.tv_nsec)) period.split!("seconds", "nsecs")().nsecs;
        }
        else
            period.split!("seconds", "nsecs")(t.tv_sec, t.tv_nsec);
        while ( true )
        {
            auto rc = semaphore_timedwait( m_hndl, t );
            if ( !rc )
                return true;
            if ( rc == KERN_OPERATION_TIMED_OUT )
                return false;
            if ( rc != KERN_ABORTED || errno != EINTR )
                throw new SyncError( "Unable to wait for semaphore" );
        }
    }

    void notify()
    {
        auto rc = semaphore_signal( m_hndl );
        if ( rc )
            throw new SyncError( "Unable to notify semaphore" );
    }

    bool tryWait()
    {
        return wait( dur!"hnsecs"(0) );
    }
}