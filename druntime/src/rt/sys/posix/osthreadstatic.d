module rt.sys.posix.osthreadstatic;

version (Posix):

// This extra file is needed in order to break a cyclic contructor/decsontructor dependency
// between rt.sys.posix.osthread and core.thread.threadbase

static immutable size_t PTHREAD_STACK_MIN;

shared static this()
{
    import core.sys.posix.unistd;

    PTHREAD_STACK_MIN = cast(size_t)sysconf(_SC_THREAD_STACK_MIN);
}
