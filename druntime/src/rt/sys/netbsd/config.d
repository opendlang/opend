module rt.sys.netbsd.config;

version (NetBSD):

// This selects the implementation file of the various OS primitives
enum string osMutexImport = "rt.sys.posix.osmutex";
enum string osSemaphoreImport = "rt.sys.posix.ossemaphore";
enum string osConditionImport = "rt.sys.posix.oscondition";
enum string osEventImport = "rt.sys.posix.osevent";
