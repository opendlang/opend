module rt.sys.darwin.osmemory;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (Darwin):

public import rt.sys.posix.osmemory: os_mem_map, os_mem_unmap, wait_pid, ChildStatus,
    getPageSize, pid_t, fork;

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
    enum GB = 2 ^^ 30;
    version (D_LP64)
        return false;
  
    // 80 % of available 4GB is used for GC (excluding malloc and mmap)
    enum size_t limit = 4UL * GB * 8 / 10;
    return mapped > limit;
}


/**
   Get the size of available physical memory

   Returns:
       size of installed physical RAM
*/

extern (C) int sysctl(const int* name, uint namelen, void* oldp, size_t* oldlenp, const void* newp, size_t newlen) @nogc nothrow;
ulong os_physical_mem() nothrow @nogc
{
    enum
    {
        CTL_HW = 6,
        HW_MEMSIZE = 24,
    }
    int[2] mib = [ CTL_HW, HW_MEMSIZE ];
    ulong system_memory_bytes;
    size_t len = system_memory_bytes.sizeof;
    if (sysctl(mib.ptr, 2, &system_memory_bytes, &len, null, 0) != 0)
        return 0;
    return system_memory_bytes;
}
