module rt.sys.freebsd.ostime;

version (FreeBSD):

public import rt.sys.posix.ostime: osCurrTime, osTicksPerSecond;

enum ClockType
{
    normal = 0,
    coarse = 2,
    precise = 3,
    second = 6,
    uptime = 8,
    uptimeCoarse = 9,
    uptimePrecise = 10,
}


auto _posixClock(ClockType clockType)
{
    import core.sys.freebsd.time;
    with(ClockType) final switch (clockType)
    {
        case coarse: return CLOCK_MONOTONIC_FAST;
        case normal: return CLOCK_MONOTONIC;
        case precise: return CLOCK_MONOTONIC_PRECISE;
        case uptime: return CLOCK_UPTIME;
        case uptimeCoarse: return CLOCK_UPTIME_FAST;
        case uptimePrecise: return CLOCK_UPTIME_PRECISE;
        case second: assert(0);
    }
}
