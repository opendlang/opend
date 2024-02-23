module rt.sys.windows.osevent;

version (Windows):

import core.sys.windows.basetsd /+: HANDLE +/;
import core.sys.windows.winerror /+: WAIT_TIMEOUT +/;
import core.sys.windows.winbase /+: CreateEvent, CloseHandle, SetEvent, ResetEvent,
    WaitForSingleObject, INFINITE, WAIT_OBJECT_0+/;

import core.time;
import core.internal.abort : abort;

struct OsEvent
{
    void create(bool manualReset, bool initialState) nothrow @trusted @nogc
    {
        if (m_event)
            return;
        m_event = CreateEvent(null, manualReset, initialState, null);
        m_event || abort("Error: CreateEvent failed.");
    }

    void destroy() nothrow @trusted @nogc
    {
        if (m_event)
            CloseHandle(m_event);
        m_event = null;
    }

    void setIfInitialized() nothrow @trusted @nogc
    {
        if (m_event)
            SetEvent(m_event);
    }

    void reset() nothrow @trusted @nogc
    {
        if (m_event)
            ResetEvent(m_event);
    }

    bool wait() nothrow @trusted @nogc
    {
        return m_event && WaitForSingleObject(m_event, INFINITE) == WAIT_OBJECT_0;
    }

    bool wait(Duration tmout) nothrow @trusted @nogc
    {
        if (!m_event)
            return false;

        auto maxWaitMillis = dur!("msecs")(uint.max - 1);

        while (tmout > maxWaitMillis)
        {
            auto res = WaitForSingleObject(m_event, uint.max - 1);
            if (res != WAIT_TIMEOUT)
                return res == WAIT_OBJECT_0;
            tmout -= maxWaitMillis;
        }
        auto ms = cast(uint)(tmout.total!"msecs");
        return WaitForSingleObject(m_event, ms) == WAIT_OBJECT_0;
    }

private:

    HANDLE m_event;
}