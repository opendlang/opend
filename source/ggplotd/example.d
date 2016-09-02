/**
    This module contains the different examples that are shown in the README

    It will only be included in unittest code, but is empty otherwise.
*/
module example;

version (unittest)

import dunit.toolkit;

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/function.png
    import std.random : uniform;
    import std.typecons : Tuple;
    import ggplotd.stat : statFunction;
    import ggplotd.ggplotd : GGPlotD;
    import ggplotd.geom : geomLine, geomPoint;
    import ggplotd.range : mergeRange;

    auto f = (double x) { return x / (1 + x); };

    auto aes = statFunction(f, 0.0, 10);
    auto gg = GGPlotD().put(geomLine(aes));

    // Generate some noisy points 
    auto f2 = (double x) { return x / (1 + x) * uniform(0.75, 1.25); };
    auto aes2 = f2.statFunction(0.0, 10, 25);

    // Show points in different colour
    auto withColour = Tuple!(string, "colour")("aquamarine").mergeRange(aes2);
    gg = gg.put(withColour.geomPoint);

    gg.save("function.png");
}

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/hist2D.svg
    import std.array : array;
    import std.algorithm : map;
    import std.conv : to;
    import std.range : repeat, iota, zip;
    import std.random : uniform;

    import ggplotd.aes : aes;
    import ggplotd.colour : colourGradient;
    import ggplotd.colourspace : XYZ;
    import ggplotd.geom : geomHist2D;
    import ggplotd.ggplotd : GGPlotD, addTo;
    import ggplotd.legend : continuousLegend;

    auto xs = iota(0,500,1).map!((x) => uniform(0.0,5)+uniform(0.0,5))
        .array;
    auto ys = iota(0,500,1).map!((y) => uniform(0.0,5)+uniform(0.0,5))
        .array;
    auto gg = xs.zip(ys)
                .map!((t) => aes!("x","y")(t[0], t[1]))
                .geomHist2D.addTo(GGPlotD());
    // Use a different colour scheme
    gg.put( colourGradient!XYZ( "white-cornflowerBlue-crimson" ) );

    gg.put(continuousLegend);

    gg.save( "hist2D.svg" );
}

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/filled_density.svg
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain;
    import std.random : uniform;

    import ggplotd.aes : Aes;
    import ggplotd.geom : geomDensity;
    import ggplotd.ggplotd : GGPlotD;
    import ggplotd.legend : discreteLegend;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25));
    auto aes = Aes!(typeof(xs), "x", typeof(cols), "colour", 
        double[], "fill" )( 
            xs, cols, 0.45.repeat(xs.length).array);
    auto gg = GGPlotD().put( geomDensity( aes ) );
    gg.put(discreteLegend);
    gg.save( "filled_density.svg" );
}

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/density2D.png
    import std.array : array;
    import std.algorithm : map;
    import std.conv : to;
    import std.range : repeat, iota;
    import std.random : uniform;

    import ggplotd.aes : Aes;
    import ggplotd.colour : colourGradient;
    import ggplotd.colourspace : XYZ;
    import ggplotd.geom : geomDensity2D;
    import ggplotd.ggplotd : GGPlotD;
    import ggplotd.legend : continuousLegend;

    auto xs = iota(0,500,1).map!((x) => uniform(0.0,5)+uniform(0.0,5))
        .array;
    auto ys = iota(0,500,1).map!((y) => uniform(0.5,1.5)+uniform(0.5,1.5))
        .array;
    auto aes = Aes!(typeof(xs), "x", typeof(ys), "y")( xs, ys);
    auto gg = GGPlotD().put( geomDensity2D( aes ) );
    // Use a different colour scheme
    gg.put( colourGradient!XYZ( "white-cornflowerBlue-crimson" ) );
    gg.put(continuousLegend);

    gg.save( "density2D.png" );
}

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/labels.png
    import std.math : PI;

    import ggplotd.aes : Aes;
    import ggplotd.geom : geomPoint, geomLabel;
    import ggplotd.ggplotd : GGPlotD;
    import ggplotd.axes : xaxisRange, yaxisRange;
    auto dt = Aes!(double[], "x", double[], "y", string[], "label", double[], "angle",
        string[], "justify")( [0.0,1,2,3,4], [4.0,3,2,1,0], 
        ["center", "left", "right", "bottom", "top"],
        [0.0, 0.0, 0.0, 0.0, 0.0],
        ["center", "left", "right", "bottom", "top"]);

    auto gg = GGPlotD()
        .put(geomPoint( dt ))
        .put(geomLabel(dt))
        .put(xaxisRange(-2,11))
        .put(yaxisRange(-2,11));

    auto dt2 = Aes!(double[], "x", double[], "y", string[], "label", real[], "angle",
        string[], "justify")( [1.0,2,3,4,5], [5.0,4,3,2,1], 
        ["center", "left", "right", "bottom", "top"],
        [0.5*PI, 0.5*PI, 0.5*PI, 0.5*PI, 0.5*PI],
        ["center", "left", "right", "bottom", "top"]);
    gg.put( geomLabel(dt2) ).put(geomPoint(dt2));

    dt2 = Aes!(double[], "x", double[], "y", string[], "label", real[], "angle",
        string[], "justify")( [1.0,2,4,6,7], [8.0,7,5,3,2], 
        ["center", "left", "right", "bottom", "top"],
        [0.25*PI, 0.25*PI, 0.25*PI, 0.25*PI, 0.25*PI],
        ["center", "left", "right", "bottom", "top"]);
    gg.put( geomLabel(dt2) ).put(geomPoint(dt2));

    gg.save( "labels.png" );
}

auto runMCMC() {
    import std.algorithm : map;
    import std.array : array;
    import std.math : pow;
    import std.range : iota;
    import dstats.random : rNorm;
    return iota(0,1000).map!((i) {
        auto x = rNorm(1, 0.5);
        auto y = rNorm(pow(x,3), 0.5);
        auto z = rNorm(x + y, 0.5);
        return [x, y, z];
    }).array;
}

///
unittest
{
    // http://blackedder.github.io/ggplotd/images/parameter_distribution.png
    import std.algorithm : map;
    import std.format : format;
    import ggplotd.aes : aes;
    import ggplotd.axes : xaxisLabel, yaxisLabel;
    import ggplotd.geom : geomDensity, geomDensity2D;
    import ggplotd.ggplotd : Facets, GGPlotD, addTo;
    import ggplotd.colour : colourGradient;
    import ggplotd.colourspace : XYZ;

    // Running MCMC for a model that takes 3 parameters
    // Will return 1000 posterior samples for the 3 parameters
    // [[par1, par2, par3], ...]
    auto samples = runMCMC();

    // Facets can be used for multiple subplots
    Facets facets;

    // Cycle over the parameters
    foreach(i; 0..3) 
    {
        foreach(j; 0..3) 
        {
            auto gg = GGPlotD();

            gg = format("Parameter %s", i).xaxisLabel.addTo(gg);
            if (i != j)
            {
                // Change the colourGradient used
                gg = colourGradient!XYZ( "white-cornflowerBlue-crimson" )
                    .addTo(gg);
                gg = format("Parameter %s", j).yaxisLabel.addTo(gg);
                gg = samples.map!((sample) => aes!("x", "y")(sample[i], sample[j]))
                    .geomDensity2D
                    .addTo(gg);
            } else {
                gg = "Density".yaxisLabel.addTo(gg);
                gg = samples.map!((sample) => aes!("x", "y")(sample[i], sample[j]))
                    .geomDensity
                    .addTo(gg);
            }
            facets = gg.addTo(facets);
        }
    }
    facets.save("parameter_distribution.png", 670, 670);
}

///
unittest
{
    // http://blackedder.github.io/ggplotd/images/diamonds.png
    import std.csv : csvReader; import std.file : readText;
    import std.algorithm : map;
    import std.array : array;
    import ggplotd.aes : aes;
    import ggplotd.axes : xaxisLabel, yaxisLabel;
    import ggplotd.ggplotd : GGPlotD, addTo;
    import ggplotd.geom : geomPoint;


    struct Diamond {
        double carat;
        string clarity;
        double price;
    }

    // Read the data
    auto diamonds = readText("test_files/diamonds.csv").csvReader!(Diamond)(
    ["carat","clarity","price"]);

    auto gg = diamonds.map!((diamond) => 
        // Map data to aesthetics (x, y and colour)
        aes!("x", "y", "colour", "size")(diamond.carat, diamond.price, diamond.clarity, 0.8))
    .array
    // Draw points
    .geomPoint.addTo(GGPlotD());

    // Axis labels
    gg = "Carat".xaxisLabel.addTo(gg);
    gg = "Price".yaxisLabel.addTo(gg);
    gg.save("diamonds.png"); 
}
