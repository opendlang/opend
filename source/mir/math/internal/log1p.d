/++
License: $(HTTP www.apache.org/licenses/LICENSE-2.0, Apache-2.0)

Authors: John Michael Hall

Copyright: 2023 Mir Stat Authors.

+/

module mir.math.internal.log1p;


// There are issues with the v2.102.2 point release for `log1p` producing the
// wrong results. This takes a simpler approach for 2.102 as a whole
static if (__VERSION__ != 2102) {
    public import std.math.exponential: log1p;
} else {
    import std.math.exponential: log;
    package(mir)
    @safe pure nothrow @nogc
    float log1p(const float x) {
        return log(x + 1);
    }

    package(mir)
    @safe pure nothrow @nogc
    double log1p(const double x) {
        return log(x + 1);
    }

    package(mir)
    @safe pure nothrow @nogc
    real log1p(const real x) {
        return log(x + 1);
    }
}
