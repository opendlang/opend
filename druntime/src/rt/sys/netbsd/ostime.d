module rt.sys.netbsd.ostime;

version (NetBSD):

public import rt.sys.posix.ostime: osCurrTime, osTicksPerSecond;

enum ClockType
{
    normal = 0,
    coarse = 2,
    precise = 3,
    second = 6,
}


auto _posixClock(ClockType clockType)
{
    import core.sys.netbsd.time;
    with(ClockType) final switch (clockType)
    {
        case coarse: return CLOCK_MONOTONIC;
        case normal: return CLOCK_MONOTONIC;
        case precise: return CLOCK_MONOTONIC;
        case second: assert(0);
    }
}
