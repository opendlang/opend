module rt.sys.posix.ostime;

// Unfortunately we need to protect the implementation from Darwin as it
// uses its own implementation but still has the Posix version identifier.
// This is what we get when we compile all files regardless of OS target.
version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version(Darwin) {}
else version (Posix):

import core.sys.posix.time;
import core.sys.posix.sys.time;

import core.time : convClockFreq, MonoTime;

import rt.sys.config;
mixin("import " ~ osTimeImport ~ ";");


ulong osCurrTime(ClockType clockType) @trusted nothrow @nogc
{
    timespec ts = void;
    immutable error = clock_gettime(_posixClock(clockType), &ts);
    // clockArg is supported and if tv_sec is long or larger
    // overflow won't happen before 292 billion years A.D.
    if (ts.tv_sec.max < long.max)
    {
        if (error)
        {
            import core.internal.abort : abort;
            abort("Call to clock_gettime failed.");
        }
    }

    // Ugly hack to speed things up. Since ticksPerSecond is already in the
    // time.d module we reuse it in order to use for the convClockFreq calculation.
    // Otherwise we would have to duplicate the array here or call clock_getres every time.
    return convClockFreq(ts.tv_sec * 1_000_000_000L + ts.tv_nsec,
                            1_000_000_000L,
                            MonoTime(clockType).ticksPerSecond);
}


/++
    The number of ticks that MonoTime has per second - i.e. the resolution
    or frequency of the system's monotonic clock.

    e.g. if the system clock had a resolution of microseconds, then
    ticksPerSecond would be $(D 1_000_000).
+/
long osTicksPerSecond(ClockType clockType) @trusted nothrow @nogc
{
    if (clockType != ClockType.second)
    {
        timespec ts;
        if (clock_getres(_posixClock(clockType), &ts) == 0)
        {
            // For some reason, on some systems, clock_getres returns
            // a resolution which is clearly wrong:
            //  - it's a millisecond or worse, but the time is updated
            //    much more frequently than that.
            //  - it's negative
            //  - it's zero
            // In such cases, we'll just use nanosecond resolution.
            return ts.tv_sec != 0 || ts.tv_nsec <= 0 || ts.tv_nsec >= 1000
                ? 1_000_000_000L : 1_000_000_000L / ts.tv_nsec;
        }
    }

    return 0;
}
