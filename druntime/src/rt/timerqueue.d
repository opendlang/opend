module rt.timerqueue;

import core.time;

import rt.util.intrusivedlist;

import rt.sys.config;
mixin("import " ~ osMutexImport ~ ";");

struct TimerQueue(T)
{
    void initialize(void function(MonoTime) setTimer, void function() cancelTimer)
    {
        m_setTimer = setTimer;
        m_cancelTimer = cancelTimer;
        m_mutex.create();
        m_timerQueue.initialize();
    }

    ~this()
    {
        m_mutex.destroy();
    }

    void insert(T item)
    {
        m_mutex.lockNoThrow();

        if(item.m_inserted)
        {
            m_timerQueue.erase(item);
            item.m_inserted = false;
        }

        bool wasEmpty = m_timerQueue.empty();

        insertInList(item);
        item.m_inserted = true;

        if (wasEmpty || item.m_expireTime < m_currentExpireTime)
        {
            m_setTimer(item.m_expireTime);
            m_currentExpireTime = item.m_expireTime;
        }

        m_mutex.unlockNoThrow();
    }

    void remove(T item)
    {
        m_mutex.lockNoThrow();
        
        if(item.m_inserted)
        {
            m_timerQueue.erase(item);
            item.m_inserted = false;

            if(m_timerQueue.empty())
            {
                m_cancelTimer();
            }
            else if(m_timerQueue.front().m_expireTime != m_currentExpireTime)
            {
                MonoTime expireTime = m_timerQueue.front().m_expireTime;
                m_setTimer(expireTime);
                m_currentExpireTime = expireTime;
            }
        }

	    m_mutex.unlockNoThrow();
    }


    T getNextExpiredTimer(MonoTime timeNow)
    {
        T ret = null;

        m_mutex.lockNoThrow();

        if(!m_timerQueue.empty())
        {
            if(m_timerQueue.front().m_expireTime <= timeNow)
            {
                T t = m_timerQueue.front();
                m_timerQueue.popFront();

                if(t.m_recurrentDelay == Duration.zero())
                {
                    t.m_inserted = false;
                }
                else
                {
                    t.m_expireTime = t.m_expireTime + t.m_recurrentDelay;
                    insertInList(t);
                }

                ret = t;
            }
        }

        m_mutex.unlockNoThrow();

        return ret;
    }

    void setTimer()
    {
        m_mutex.lockNoThrow();

        if(!m_timerQueue.empty())
        {
            MonoTime expireTime = m_timerQueue.front().m_expireTime;
            m_setTimer(expireTime);
            m_currentExpireTime = expireTime;
        }

        m_mutex.unlockNoThrow();
    }


private:
    static if(is(T:S*, S))
    {
        IntrusiveDList!(T, S.m_timerQueueNode) m_timerQueue;
    }
    OsMutex m_mutex;
    void function(MonoTime) m_setTimer;
    void function() m_cancelTimer;
    MonoTime m_currentExpireTime;

    void insertInList(T item)
    {
        if(m_timerQueue.empty() || m_timerQueue.back().m_expireTime < item.m_expireTime)
        {
            m_timerQueue.pushBack(item);
        }
        else
        {
            foreach(e; m_timerQueue)
            {
                if(item.m_expireTime < e.m_expireTime)
                {
                    m_timerQueue.insertBefore(e, item);
                    break;
                }
            }
        }
    }
}