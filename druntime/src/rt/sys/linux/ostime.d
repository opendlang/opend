module rt.sys.linux.ostime;

version (linux):

public import rt.sys.posix.ostime: osCurrTime, osTicksPerSecond;

enum ClockType
{
    normal = 0,
    bootTime = 1,
    coarse = 2,
    precise = 3,
    processCPUTime = 4,
    raw = 5,
    second = 6,
    threadCPUTime = 7,
}


auto _posixClock(ClockType clockType)
{
    import core.sys.linux.time;
    with(ClockType) final switch (clockType)
    {
        case bootTime: return CLOCK_BOOTTIME;
        case coarse: return CLOCK_MONOTONIC_COARSE;
        case normal: return CLOCK_MONOTONIC;
        case precise: return CLOCK_MONOTONIC;
        case processCPUTime: return CLOCK_PROCESS_CPUTIME_ID;
        case raw: return CLOCK_MONOTONIC_RAW;
        case threadCPUTime: return CLOCK_THREAD_CPUTIME_ID;
        case second: assert(0);
    }
}
