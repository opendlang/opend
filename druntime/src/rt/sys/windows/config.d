module rt.sys.windows.config;

version (Windows):

// This selects the implementation file of the various OS primitives
enum string osMutexImport = "rt.sys.windows.osmutex";
enum string osSemaphoreImport = "rt.sys.windows.ossemaphore";
enum string osConditionImport = "rt.sys.windows.oscondition";
enum string osEventImport = "rt.sys.windows.osevent";
enum string osMemoryImport = "rt.sys.windows.osmemory";


/**
* Indicates if an implementation supports fork().
*
* The value shown here is just demostrative, the real value is defined based
* on the OS it's being compiled in.
* enum HaveFork = true;
*/
enum HaveFork = false;
