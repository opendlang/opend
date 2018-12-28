/+ dub.sdl:
dependency "mir-core" path="./"
+/

import std.stdio;
import std.meta;
import std.datetime.stopwatch;

enum size_t length = 256;

void main()
{
    test!float;
    test!double;
    test!real;
}

void test(T)()
{
    static __gshared T[length] x, y;
    static __gshared int[length] z;
    static __gshared int exp_common;

    foreach(i; 0 .. length)
    {
        x[i] = i + 1 / T(i);
        y[i] = i - 100;
    }

    auto res = benchmark!(
        (){
            foreach(i; 0 .. length)
                y[i] = x[i] * z[i];
        },
        (){
            import mir.math;
            foreach(i; 0 .. length)
                y[i] = ldexp(x[i], z[i]);
        },
        (){
            import std.math;
            foreach(i; 0 .. length)
                y[i] = ldexp(x[i], z[i]);
        },
        (){
            import mir.math;
            foreach(i; 0 .. length)
                y[i] = frexp(x[i], exp_common);
        },
        (){
            import std.math;
            foreach(i; 0 .. length)
                y[i] = frexp(x[i], exp_common);
        },   
    )(100_000);

    writeln("---------------------------");
    writeln("++++ ", T.stringof, " ++++");
    writeln("ldexp (Phobos time / Mir time) = ", double(res[2].total!"usecs") / res[1].total!"usecs");
    writeln("frexp (Phobos time / Mir time) = ", double(res[4].total!"usecs") / res[3].total!"usecs");
}
