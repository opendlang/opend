/**
Common part of the renderers.

Copyright: Guillaume Piolat 2021.
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module printed.canvas.internals;


/// Validate line dash pattern. A dash pattern is valid if all values are
/// finite and non-negative.
bool isValidLineDashPattern(float[] segments)
{
    import std.algorithm : all;
    import std.range.primitives;

    return segments.all!(x => 0 <= x && x <= float.infinity);
}


/// Normalize line dash pattern, i.e. the array returned will always have an
/// even number of entries.
///
/// Returns: a copy of segments if the number of entries is even; otherwise
///          the concatenation of segments with itself.
float[] normalizeLineDashPattern(float[] segments)
{
    if (segments.length % 2 == 0)
        return segments.dup;
    else
        return segments ~ segments;
}
