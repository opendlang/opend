module rt.sys.posix.osevent;

version (Posix):

import core.sys.posix.pthread;
import core.sys.posix.sys.types;
import core.sys.posix.time;

import core.time;
import core.internal.abort : abort;

struct OsEvent
{
    void create(bool manualReset, bool initialState) nothrow @trusted @nogc
    {
        if (m_initalized)
            return;
        pthread_mutex_init(cast(pthread_mutex_t*) &m_mutex, null) == 0 ||
            abort("Error: pthread_mutex_init failed.");
        static if ( is( typeof( pthread_condattr_setclock ) ) )
        {
            pthread_condattr_t attr = void;
            pthread_condattr_init(&attr) == 0 ||
                abort("Error: pthread_condattr_init failed.");
            pthread_condattr_setclock(&attr, CLOCK_MONOTONIC) == 0 ||
                abort("Error: pthread_condattr_setclock failed.");
            pthread_cond_init(&m_cond, &attr) == 0 ||
                abort("Error: pthread_cond_init failed.");
            pthread_condattr_destroy(&attr) == 0 ||
                abort("Error: pthread_condattr_destroy failed.");
        }
        else
        {
            pthread_cond_init(&m_cond, null) == 0 ||
                abort("Error: pthread_cond_init failed.");
        }

        m_state = initialState;
        m_manualReset = manualReset;
        m_initalized = true;
    }

    void destroy() nothrow @trusted @nogc
    {
        if (m_initalized)
        {
            pthread_mutex_destroy(&m_mutex) == 0 ||
                abort("Error: pthread_mutex_destroy failed.");
            pthread_cond_destroy(&m_cond) == 0 ||
                abort("Error: pthread_cond_destroy failed.");
            m_initalized = false;
        }
    }

    void setIfInitialized() nothrow @trusted @nogc
    {
        if (m_initalized)
        {
            pthread_mutex_lock(&m_mutex);
            m_state = true;
            pthread_cond_broadcast(&m_cond);
            pthread_mutex_unlock(&m_mutex);
        }
    }

    void reset() nothrow @trusted @nogc
    {
        if (m_initalized)
        {
            pthread_mutex_lock(&m_mutex);
            m_state = false;
            pthread_mutex_unlock(&m_mutex);
        }
    }

    bool wait() nothrow @trusted @nogc
    {
        return wait(Duration.max);
    }

    bool wait(Duration tmout) nothrow @trusted @nogc
    {
        if (!m_initalized)
            return false;

        pthread_mutex_lock(&m_mutex);

        int result = 0;
        if (!m_state)
        {
            if (tmout == Duration.max)
            {
                result = pthread_cond_wait(&m_cond, &m_mutex);
            }
            else
            {
                import core.sync.config;

                timespec t = void;
                mktspec(t, tmout);

                result = pthread_cond_timedwait(&m_cond, &m_mutex, &t);
            }
        }
        if (result == 0 && !m_manualReset)
            m_state = false;

        pthread_mutex_unlock(&m_mutex);

        return result == 0;
    }

private:

    pthread_mutex_t m_mutex;
    pthread_cond_t m_cond;
    bool m_initalized;
    bool m_state;
    bool m_manualReset;
}