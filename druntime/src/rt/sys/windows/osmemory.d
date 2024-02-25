module rt.sys.windows.osmemory;

version (Windows):

import core.sys.windows.winbase : GetCurrentThreadId, VirtualAlloc, VirtualFree;
import core.sys.windows.winnt : MEM_COMMIT, MEM_RELEASE, MEM_RESERVE, PAGE_READWRITE;

alias pthread_t = int;

pthread_t pthread_self() nothrow
{
    return cast(pthread_t) GetCurrentThreadId();
}

/**
 * Map memory.
 */
void *os_mem_map(size_t nbytes) nothrow @nogc
{
    return VirtualAlloc(null, nbytes, MEM_RESERVE | MEM_COMMIT,
            PAGE_READWRITE);
}


/**
 * Unmap memory allocated with os_mem_map().
 * Returns:
 *      0       success
 *      !=0     failure
 */
int os_mem_unmap(void *base, size_t nbytes) nothrow @nogc
{
    return cast(int)(VirtualFree(base, 0, MEM_RELEASE) == 0);
}

/**
   Check for any kind of memory pressure.

   Params:
      mapped = the amount of memory mapped by the GC in bytes
   Returns:
       true if memory is scarce
*/
// TODO: get virtual mem sizes and current usage from OS
// TODO: compare current RSS and avail. physical memory
bool isLowOnMem(size_t mapped) nothrow @nogc
{
    import core.sys.windows.winbase : GlobalMemoryStatusEx, MEMORYSTATUSEX;

    MEMORYSTATUSEX stat;
    stat.dwLength = stat.sizeof;
    const success = GlobalMemoryStatusEx(&stat) != 0;
    assert(success, "GlobalMemoryStatusEx() failed");
    if (!success)
        return false;

    // dwMemoryLoad is the 'approximate percentage of physical memory that is in use'
    // https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/ns-sysinfoapi-memorystatusex
    const percentPhysicalRAM = stat.ullTotalPhys / 100;
    return (stat.dwMemoryLoad >= 95 && mapped > percentPhysicalRAM)
        || (stat.dwMemoryLoad >= 90 && mapped > 10 * percentPhysicalRAM);
}


/**
   Get the size of available physical memory

   Returns:
       size of installed physical RAM
*/
ulong os_physical_mem() nothrow @nogc
{
    import core.sys.windows.winbase : GlobalMemoryStatus, MEMORYSTATUS;
    MEMORYSTATUS stat;
    GlobalMemoryStatus(&stat);
    return stat.dwTotalPhys; // limited to 4GB for Win32
}


/**
   Get get the page size of OS

   Returns:
       OS page size in bytes
*/
size_t getPageSize()
{
    import core.sys.windows.winbase : GetSystemInfo, SYSTEM_INFO;

    SYSTEM_INFO si;
    GetSystemInfo(&si);
    return cast(size_t) si.dwPageSize;
}
