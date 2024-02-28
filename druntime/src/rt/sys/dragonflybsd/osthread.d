module rt.sys.dragonflybsd.osthread;

version (DragonFlyBSD):

// This unittest is here because it was moved from core.thread.osthread. Otherwise that
// this unittest there is not DragonFlyBSD specific implementation of osthread but
// it can just use the POSIX version.

// regression test for Issue 13416
unittest
{
    static void loop()
    {
        pthread_attr_t attr;
        pthread_attr_init(&attr);
        auto thr = pthread_self();
        foreach (i; 0 .. 50)
            pthread_attr_get_np(thr, &attr);
        pthread_attr_destroy(&attr);
    }

    auto thr = new Thread(&loop).start();
    foreach (i; 0 .. 50)
    {
        thread_suspendAll();
        thread_resumeAll();
    }
    thr.join();
}
