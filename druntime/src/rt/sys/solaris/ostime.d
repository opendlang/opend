module rt.sys.solaris.ostime;

version (Solaris):

public import rt.sys.posix.ostime: osCurrTime, osTicksPerSecond;

enum ClockType
{
    normal = 0,
    coarse = 2,
    precise = 3,
    processCPUTime = 4,
    second = 6,
    threadCPUTime = 7,
}


auto _posixClock(ClockType clockType)
{
   import core.sys.solaris.time;
    with(ClockType) final switch (clockType)
    {
        case coarse: return CLOCK_MONOTONIC;
        case normal: return CLOCK_MONOTONIC;
        case precise: return CLOCK_MONOTONIC;
        case processCPUTime: return CLOCK_PROCESS_CPUTIME_ID;
        case threadCPUTime: return CLOCK_THREAD_CPUTIME_ID;
        case second: assert(0);
    }
}
