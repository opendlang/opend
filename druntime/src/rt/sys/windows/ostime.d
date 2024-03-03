module rt.sys.windows.ostime;

version (Windows):

import core.sys.windows.winbase /+: QueryPerformanceCounter, QueryPerformanceFrequency+/;


enum ClockType
{
    normal = 0,
    coarse = 2,
    precise = 3,
    second = 6,
}


private void checkAllowedClockType(ClockType clockType) nothrow @nogc
{
    if (clockType != ClockType.coarse &&
        clockType != ClockType.normal &&
        clockType != ClockType.precise &&
        clockType != ClockType.second)
    {
        assert(0, clockType.stringof ~ " is not supported by MonoTimeImpl on this system.");
    }
}

ulong osCurrTime(ClockType clockType) @trusted nothrow @nogc
{
    checkAllowedClockType(clockType);

    long ticks = void;
    QueryPerformanceCounter(&ticks);
    return ticks;
}


/++
    The number of ticks that MonoTime has per second - i.e. the resolution
    or frequency of the system's monotonic clock.

    e.g. if the system clock had a resolution of microseconds, then
    ticksPerSecond would be $(D 1_000_000).
+/
long osTicksPerSecond(ClockType clockType) @trusted nothrow @nogc
{
    checkAllowedClockType(clockType);

    long ticksPerSecond;
    if (QueryPerformanceFrequency(&ticksPerSecond) != 0)
    {
        return ticksPerSecond;
    }

    return 0;
}
