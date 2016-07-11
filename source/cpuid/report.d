/++
Text information generators.
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
