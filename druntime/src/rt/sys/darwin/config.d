module rt.sys.darwin.config;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (Darwin):

// This selects the implementation file of the various OS primitives
enum string osMutexImport = "rt.sys.posix.osmutex";
enum string osSemaphoreImport = "rt.sys.darwin.ossemaphore";
enum string osConditionImport = "rt.sys.posix.oscondition";
enum string osEventImport = "rt.sys.posix.osevent";
enum string osMemoryImport = "rt.sys.darwin.osmemory";
enum string osTimerImport = "rt.sys.darwin.ostimer";

// These turns on/off the generic implementations in the POSIX osthread module.
enum bool usePosix_osmemory_isLowOnMem = false;
enum bool usePosix_osmemory_os_physical_mem = false;

/**
* Indicates if an implementation supports fork().
*
* The value shown here is just demostrative, the real value is defined based
* on the OS it's being compiled in.
* enum HaveFork = true;
*/
enum HaveFork = true;
