module rt.sys.darwin.ostimer;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (Darwin):

import core.time;
import core.timer : TimerException;


struct OsTimer
{
    void create(void function(void*) callbackFn, void* arg = null)
    {
        throw new TimerException("not implemented");
    }

    void destroy()
    {
        throw new TimerException("not implemented");
    }

    private void start(Duration firstDelay, Duration recurrentDelay)
    {
        throw new TimerException("not implemented");
    }

    void start(Duration delay)
    {
        throw new TimerException("not implemented");
    }

    void startRecurrent(Duration recurrentDelay)
    {
        throw new TimerException("not implemented");
    }

    void startRecurrent(Duration firstDelay, Duration recurrentDelay)
    {
        throw new TimerException("not implemented");
    }

    void stop()
    {
        throw new TimerException("not implemented");
    }
}