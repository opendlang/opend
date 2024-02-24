module rt.sys.windows.config;

version (Windows):

// This selects the implementation file of the various OS primitives
enum string osMutexImport = "rt.sys.windows.osmutex";
enum string osSemaphoreImport = "rt.sys.windows.ossemaphore";
enum string osConditionImport = "rt.sys.windows.oscondition";
enum string osEventImport = "rt.sys.windows.osevent";
