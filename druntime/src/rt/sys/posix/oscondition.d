module rt.sys.posix.oscondition;

version (Posix):

import core.sync.exception;
import core.sync.mutex;
import core.time;

import core.exception : AssertError, staticError;

import core.sync.config;
import core.stdc.errno;
import core.sys.posix.pthread;
import core.sys.posix.time;


struct OsCondition
{
    void create(Mutex m) nothrow @trusted @nogc
    {
        static if ( is( typeof( pthread_condattr_setclock ) ) )
        {
            () @trusted
            {
                pthread_condattr_t attr = void;
                int rc  = pthread_condattr_init( &attr );
                if ( rc )
                    throw staticError!AssertError("Unable to initialize condition", __FILE__, __LINE__);
                rc = pthread_condattr_setclock( &attr, CLOCK_MONOTONIC );
                if ( rc )
                    throw staticError!AssertError("Unable to initialize condition", __FILE__, __LINE__);
                rc = pthread_cond_init( cast(pthread_cond_t*) &m_hndl, &attr );
                if ( rc )
                    throw staticError!AssertError("Unable to initialize condition", __FILE__, __LINE__);
                rc = pthread_condattr_destroy( &attr );
                if ( rc )
                    throw staticError!AssertError("Unable to initialize condition", __FILE__, __LINE__);
            } ();
        }
        else
        {
            int rc = pthread_cond_init( cast(pthread_cond_t*) &m_hndl, null );
            if ( rc )
                throw staticError!AssertError("Unable to initialize condition", __FILE__, __LINE__);
        }
        m_assocMutex = m;
    }

    void destroy() @nogc
    {
        int rc = pthread_cond_destroy( &m_hndl );
        assert( !rc, "Unable to destroy condition" );
    }

    void wait()
    {
        int rc = pthread_cond_wait( cast(pthread_cond_t*) &m_hndl, &m_assocMutex.osMutex.m_hndl);
        if ( rc )
            throw staticError!AssertError("Unable to wait for condition", __FILE__, __LINE__);
    }

    bool wait( Duration val)
    {
        timespec t = void;
        mktspec( t, val );

        int rc = pthread_cond_timedwait(cast(pthread_cond_t*) &m_hndl,
                                        &m_assocMutex.osMutex.m_hndl,
                                        &t );
        if ( !rc )
            return true;
        if ( rc == ETIMEDOUT )
            return false;
        throw staticError!AssertError("Unable to wait for condition", __FILE__, __LINE__);
    }

    void notify()
    {
        // Since OS X 10.7 (Lion), pthread_cond_signal returns EAGAIN after retrying 8192 times,
        // so need to retrying while it returns EAGAIN.
        //
        // 10.7.0 (Lion):          http://www.opensource.apple.com/source/Libc/Libc-763.11/pthreads/pthread_cond.c
        // 10.8.0 (Mountain Lion): http://www.opensource.apple.com/source/Libc/Libc-825.24/pthreads/pthread_cond.c
        // 10.10.0 (Yosemite):     http://www.opensource.apple.com/source/libpthread/libpthread-105.1.4/src/pthread_cond.c
        // 10.11.0 (El Capitan):   http://www.opensource.apple.com/source/libpthread/libpthread-137.1.1/src/pthread_cond.c
        // 10.12.0 (Sierra):       http://www.opensource.apple.com/source/libpthread/libpthread-218.1.3/src/pthread_cond.c
        // 10.13.0 (High Sierra):  http://www.opensource.apple.com/source/libpthread/libpthread-301.1.6/src/pthread_cond.c
        // 10.14.0 (Mojave):       http://www.opensource.apple.com/source/libpthread/libpthread-330.201.1/src/pthread_cond.c
        // 10.14.1 (Mojave):       http://www.opensource.apple.com/source/libpthread/libpthread-330.220.2/src/pthread_cond.c

        int rc;
        do {
            rc = pthread_cond_signal( cast(pthread_cond_t*) &m_hndl );
        } while ( rc == EAGAIN );
        if ( rc )
            throw staticError!AssertError("Unable to notify condition", __FILE__, __LINE__);
    }

    void notifyAll()
    {
        // Since OS X 10.7 (Lion), pthread_cond_broadcast returns EAGAIN after retrying 8192 times,
        // so need to retrying while it returns EAGAIN.
        //
        // 10.7.0 (Lion):          http://www.opensource.apple.com/source/Libc/Libc-763.11/pthreads/pthread_cond.c
        // 10.8.0 (Mountain Lion): http://www.opensource.apple.com/source/Libc/Libc-825.24/pthreads/pthread_cond.c
        // 10.10.0 (Yosemite):     http://www.opensource.apple.com/source/libpthread/libpthread-105.1.4/src/pthread_cond.c
        // 10.11.0 (El Capitan):   http://www.opensource.apple.com/source/libpthread/libpthread-137.1.1/src/pthread_cond.c
        // 10.12.0 (Sierra):       http://www.opensource.apple.com/source/libpthread/libpthread-218.1.3/src/pthread_cond.c
        // 10.13.0 (High Sierra):  http://www.opensource.apple.com/source/libpthread/libpthread-301.1.6/src/pthread_cond.c
        // 10.14.0 (Mojave):       http://www.opensource.apple.com/source/libpthread/libpthread-330.201.1/src/pthread_cond.c
        // 10.14.1 (Mojave):       http://www.opensource.apple.com/source/libpthread/libpthread-330.220.2/src/pthread_cond.c

        int rc;
        do {
            rc = pthread_cond_broadcast( cast(pthread_cond_t*) &m_hndl );
        } while ( rc == EAGAIN );
        if ( rc )
            throw staticError!AssertError("Unable to notify condition", __FILE__, __LINE__);
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
    Mutex               m_assocMutex;
    pthread_cond_t      m_hndl;
}