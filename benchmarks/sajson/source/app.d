import mir.ion;

import std.algorithm;
import std.conv;
import std.datetime;
import std.file;

static import std.stdio;

immutable folder = "testdata/";
immutable files = 
[
    "apache_builds.json",
    "github_events.json",
    "instruments.json",
    "mesh.json",
    "mesh.pretty.json",
    "nested.json",
    "svg_menu.json",
    "truenull.json",
    "twitter.json",
    "update-center.json",
    "whitespace.json",
];

immutable int max_string_length = files.map!"a.length".reduce!max + folder.length;

void run_benchmark(string fileName)
{
    auto text =  cast(string) fileName.read;
    // text ~= '\0';
    const size_t N = 1000;
    Duration minTime = Duration.max, avgTime;

    import std.experimental.allocator.mallocator : Mallocator;

    foreach (size_t i; 0 .. N)
    {
        auto sw = StopWatch();
        sw.start;
        import std.typecons: No, Yes;
        auto json = text.parseJson!(
            Yes.includingNewLine,
            Yes.spaces,
            No.assumeValid,
        )(Mallocator.instance);
        sw.stop;
        Mallocator.instance.deallocate(json.data.ptr[0 .. text.length * 6]);
        auto time = sw.peek.to!Duration;
        avgTime += time;
        minTime = min(minTime, time);
    }
    avgTime /= N;
    std.stdio.writef("%*s - %0.3f ms - %0.3f ms\n", max_string_length, fileName, double(avgTime.total!"usecs") / 1000, double(minTime.total!"usecs") / 1000);
}

void main()
{
    std.stdio.writef("%*s - %8s - %8s\n", max_string_length, "file", "avg", "min");
    std.stdio.writef("%*s - %8s - %8s\n", max_string_length, "----", "---", "---");

    foreach (file; files)
        run_benchmark(folder ~ file);
}
