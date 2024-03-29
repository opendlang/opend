module rt.sys.posix.osmemory;

version (Posix):

import core.sys.posix.sys.mman;
import core.stdc.stdlib;

import rt.sys.config;

void *os_mem_map(size_t nbytes, bool share = false) nothrow @nogc
{   void *p;

    auto map_f = share ? MAP_SHARED : MAP_PRIVATE;
    p = mmap(null, nbytes, PROT_READ | PROT_WRITE, map_f | MAP_ANON, -1, 0);
    return (p == MAP_FAILED) ? null : p;
}


int os_mem_unmap(void *base, size_t nbytes) nothrow @nogc
{
    return munmap(base, nbytes);
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
static if(usePosix_osmemory_isLowOnMem)
{
    bool isLowOnMem(size_t mapped) nothrow @nogc
    {
        enum GB = 2 ^^ 30;
        version (D_LP64)
            return false;

        // be conservative and assume 3GB
        enum size_t limit = 3UL * GB * 8 / 10;
        return mapped > limit;
    }
}


/**
   Get the size of available physical memory

   Returns:
       size of installed physical RAM
*/
static if(usePosix_osmemory_os_physical_mem)
{
    ulong os_physical_mem() nothrow @nogc
    {
        import core.sys.posix.unistd : sysconf, _SC_PAGESIZE, _SC_PHYS_PAGES;
        const pageSize = sysconf(_SC_PAGESIZE);
        const pages = sysconf(_SC_PHYS_PAGES);
        return pageSize * pages;
    }
}


/**
   Get get the page size of OS

   Returns:
       OS page size in bytes
*/
size_t getPageSize()
{
    import core.sys.posix.unistd : sysconf, _SC_PAGESIZE;

    return cast(size_t) sysconf(_SC_PAGESIZE);
}


// wait_pid is used in conservative GC
/// Possible results for the wait_pid() function.
enum ChildStatus
{
    done, /// The process has finished successfully
    running, /// The process is still running
    error /// There was an error waiting for the process
}

/**
    * Wait for a process with PID pid to finish.
    *
    * If block is false, this function will not block, and return ChildStatus.running if
    * the process is still running. Otherwise it will return always ChildStatus.done
    * (unless there is an error, in which case ChildStatus.error is returned).
    */
ChildStatus wait_pid(pid_t pid, bool block = true) nothrow @nogc @system
{
    import core.exception : onForkError;

    int status = void;
    pid_t waited_pid = void;
    // In the case where we are blocking, we need to consider signals
    // arriving while we wait, and resume the waiting if EINTR is returned
    do {
        errno = 0;
        waited_pid = waitpid(pid, &status, block ? 0 : WNOHANG);
    }
    while (waited_pid == -1 && errno == EINTR);
    if (waited_pid == 0)
        return ChildStatus.running;
    else if (errno ==  ECHILD)
        return ChildStatus.done; // someone called posix.syswait
    else if (waited_pid != pid || status != 0)
        onForkError();
    return ChildStatus.done;
}

public import core.sys.posix.unistd: pid_t, fork;
import core.sys.posix.sys.wait: waitpid, WNOHANG;
import core.stdc.errno: errno, EINTR, ECHILD;
