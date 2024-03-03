module rt.sys.darwin.ostime;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version(Darwin):

public import core.sys.darwin.mach.kern_return;


extern(C) nothrow @nogc
{
    struct mach_timebase_info_data_t
    {
        uint numer;
        uint denom;
    }

    alias mach_timebase_info_data_t* mach_timebase_info_t;

    kern_return_t mach_timebase_info(mach_timebase_info_t);

    ulong mach_absolute_time();
}


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

    return mach_absolute_time();
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

      // Be optimistic that ticksPerSecond (1e9*denom/numer) is integral. So far
    // so good on Darwin based platforms OS X, iOS.
    import core.internal.abort : abort;
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != 0)
        abort("Failed in mach_timebase_info().");

    long scaledDenom = 1_000_000_000L * info.denom;
    if (scaledDenom % info.numer != 0)
        abort("Non integral ticksPerSecond from mach_timebase_info.");
    return scaledDenom / info.numer;
}
