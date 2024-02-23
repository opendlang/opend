module rt.sys.posix.osmutex;

version (Posix):

import core.sync.exception;
import core.sys.posix.pthread;

struct OsMutex
{
    pthread_mutex_t     m_hndl;

    void create() nothrow @trusted @nogc
    {
        import core.internal.abort : abort;
        pthread_mutexattr_t attr = void;

        !pthread_mutexattr_init(&attr) ||
            abort("Error: pthread_mutexattr_init failed.");

        scope (exit) !pthread_mutexattr_destroy(&attr) ||
            abort("Error: pthread_mutexattr_destroy failed.");

        !pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE) ||
            abort("Error: pthread_mutexattr_settype failed.");

        !pthread_mutex_init(cast(pthread_mutex_t*) &m_hndl, &attr) ||
            abort("Error: pthread_mutex_init failed.");
    }

    void destroy() nothrow @trusted @nogc
    {
        import core.internal.abort : abort;
            !pthread_mutex_destroy(&m_hndl) ||
                abort("Error: pthread_mutex_destroy failed.");
    }

    void lockNoThrow() nothrow @trusted @nogc
    {
        if (pthread_mutex_lock(&m_hndl) == 0)
            return;

        SyncError syncErr = cast(SyncError) __traits(initSymbol, SyncError).ptr;
        syncErr.msg = "Unable to lock mutex.";
        throw syncErr;
    }

    void unlockNoThrow() nothrow @trusted @nogc
    {
         if (pthread_mutex_unlock(&m_hndl) == 0)
            return;

        SyncError syncErr = cast(SyncError) __traits(initSymbol, SyncError).ptr;
        syncErr.msg = "Unable to unlock mutex.";
        throw syncErr;
    }

    bool tryLockNoThrow() nothrow @trusted @nogc
    {
        return pthread_mutex_trylock(&m_hndl) == 0;
    }
}