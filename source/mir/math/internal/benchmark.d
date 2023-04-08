module mir.math.internal.benchmark;

import core.time;
import std.traits: isMutable;

package(mir)
template benchmarkValues(fun...)
{
    Duration[fun.length] benchmarkValues(T)(size_t n, out T[fun.length] values)
    {
		import std.datetime.stopwatch: StopWatch, AutoStart;
        Duration[fun.length] result;
        auto sw = StopWatch(AutoStart.yes);

        foreach (i, unused; fun) {
            values[i] = 0;
            sw.reset();
            foreach (size_t j; 1 .. n) {
                values[i] += fun[i]();
            }
            result[i] = sw.peek();
            values[i] /= n;
        }

        return result;
    }
}

package(mir)
template benchmarkRandom(fun...)
{
    Duration[fun.length] benchmarkRandom(T)(size_t n, size_t m, out T[fun.length] values)
        if (isMutable!T)
    {
        import mir.ndslice.allocation: stdcFreeSlice, stdcUninitSlice;
        import mir.random.engine: Random, threadLocalPtr;
        import mir.random.variable: NormalVariable;
		import std.datetime.stopwatch: StopWatch, AutoStart;

        Random* gen = threadLocalPtr!Random;
        auto rv = NormalVariable!T(0, 1);

        Duration[fun.length] result;
        auto r = stdcUninitSlice!T(m);
        auto sw = StopWatch(AutoStart.yes);

        foreach (i, unused; fun) {
            values[i] = 0;
            sw.reset();
            foreach (size_t j; 1 .. n) {
                sw.stop();
                foreach (ref e; r)
                    e = rv(gen);
                sw.start();
                values[i] += fun[i](r);
            }
            result[i] = sw.peek();
            values[i] /= n;
        }
		r.stdcFreeSlice;
        return result;
    }
}

package(mir)
template benchmarkRandom2(fun...)
{
    Duration[fun.length] benchmarkRandom2(T)(size_t n, size_t m, out T[fun.length] values)
        if (isMutable!T)
    {
        import mir.ndslice.allocation: stdcFreeSlice, stdcUninitSlice;
        import mir.random.engine: Random, threadLocalPtr;
        import mir.random.variable: NormalVariable;
		import std.datetime.stopwatch: StopWatch, AutoStart;

        Random* gen = threadLocalPtr!Random;
        auto rv = NormalVariable!T(0, 1);

        Duration[fun.length] result;
        auto r1 = stdcUninitSlice!T(m);
        auto r2 = stdcUninitSlice!T(m);
        auto sw = StopWatch(AutoStart.yes);

        foreach (i, unused; fun) {
            values[i] = 0;
            sw.reset();
            foreach (size_t j; 1 .. n) {
                sw.stop();
                foreach (size_t k; 0 .. m) {
                    r1[k] = rv(gen);
                    r2[k] = r1[k] + rv(gen);
                }
                sw.start();
                values[i] += fun[i](r1, r2);
            }
            result[i] = sw.peek();
            values[i] /= n;
        }
		r1.stdcFreeSlice;
		r2.stdcFreeSlice;
        return result;
    }
}
