module rt.sys.windows.osmutex;

version (Windows):

import core.sys.windows.winbase /+: CRITICAL_SECTION, DeleteCriticalSection,
        EnterCriticalSection, InitializeCriticalSection, LeaveCriticalSection,
        TryEnterCriticalSection+/;

struct OsMutex
{
    CRITICAL_SECTION    m_hndl;

    void create() nothrow @trusted @nogc
    {
        InitializeCriticalSection(cast(CRITICAL_SECTION*) &m_hndl);
    }

    void destroy() nothrow @trusted @nogc
    {
        DeleteCriticalSection(&m_hndl);
    }

    void lockNoThrow() nothrow @trusted @nogc
    {
        EnterCriticalSection(&m_hndl);
    }

    void unlockNoThrow() nothrow @trusted @nogc
    {
        LeaveCriticalSection(&m_hndl);
    }

    bool tryLockNoThrow() nothrow @trusted @nogc
    {
        return TryEnterCriticalSection(&m_hndl) != 0;
    }
}