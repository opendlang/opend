module rt.sys.openbsd.ostime;

version (OpenBSD):

public import rt.sys.posix.ostime: osCurrTime, osTicksPerSecond;

enum ClockType
{
    normal = 0,
    bootTime = 1,
    coarse = 2,
    precise = 3,
    processCPUTime = 4,
    second = 6,
    threadCPUTime = 7,
    uptime = 8,
}


auto _posixClock(ClockType clockType)
{
    import core.sys.openbsd.time;
    with(ClockType) final switch (clockType)
    {
        case bootTime: return CLOCK_BOOTTIME;
        case coarse: return CLOCK_MONOTONIC;
        case normal: return CLOCK_MONOTONIC;
        case precise: return CLOCK_MONOTONIC;
        case processCPUTime: return CLOCK_PROCESS_CPUTIME_ID;
        case threadCPUTime: return CLOCK_THREAD_CPUTIME_ID;
        case uptime: return CLOCK_UPTIME;
        case second: assert(0);
    }
}
