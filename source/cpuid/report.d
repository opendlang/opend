/++
Text information generators.

License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors:   Ilya Yaroshenko
+/
module cpuid.report;

/// Return report for `cpuid.unified`.
string reportUnified()
{
    import std.array;
    import std.format;
    import cpuid.unified;

    auto app = appender!string;

    return app.data;
}
