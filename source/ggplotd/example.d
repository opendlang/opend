/**
    This module contains the different examples that are shown in the README

    It will only be included in unittest code, but is empty otherwise.
*/
module example;

version (unittest)
{
    import dunit.toolkit;
}

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/function.png
    import std.random : uniform;
    import std.typecons : Tuple;
    import ggplotd.stat : statFunction;
    import ggplotd.ggplotd : GGPlotD;
    import ggplotd.geom : geomLine, geomPoint;
    import ggplotd.aes : mergeRange;

    // Generate some noisy data with reducing width
    auto f = (double x) { return x / (1 + x); };

    auto aes = statFunction(f, 0.0, 10);
    auto gg = GGPlotD().put(geomLine(aes));

    auto f2 = (double x) { return x / (1 + x) * uniform(0.9, 1.1); };
    auto aes2 = f2.statFunction(0.0, 10, 25);
    // Show points in different colour
    auto withColour = Tuple!(double, "colour")(0).mergeRange(aes2);
    gg = gg.put(withColour.geomPoint);

    gg.save("function.png");
}
