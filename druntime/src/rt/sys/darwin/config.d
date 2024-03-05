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
