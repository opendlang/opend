module ggplotd.algorithm;
/// Max function that skips NaN values
auto safeMax(T)(T a, T b)
{
    import std.math : isNaN;
    import std.algorithm : max;

    if (isNaN(b))
        return a;
    if (isNaN(a))
        return b;
    return max(a, b);
}

/// Min function that skips NaN values
auto safeMin(T)(T a, T b)
{
    import std.math : isNaN;
    import std.algorithm : min;

    if (isNaN(b))
        return a;
    if (isNaN(a))
        return b;
    return min(a, b);
}


