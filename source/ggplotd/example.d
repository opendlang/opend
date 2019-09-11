/**
    This module contains the different examples that are shown in the README

    It will only be included in unittest code, but is empty otherwise.
*/
module example;

version (unittest)

import dunit.toolkit;
import std.stdio : writeln;

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
    import std.range : iota, zip;
    import std.random : uniform;

    import ggplotd.aes : aes;
    import ggplotd.colour : colourGradient;
    import ggplotd.colourspace : XYZ;
    import ggplotd.geom : geomHist2D;
    import ggplotd.ggplotd : GGPlotD, putIn;
    import ggplotd.legend : continuousLegend;

    auto xs = iota(0,500,1).map!((x) => uniform(0.0,5)+uniform(0.0,5))
        .array;
    auto ys = iota(0,500,1).map!((y) => uniform(0.0,5)+uniform(0.0,5))
        .array;
    auto gg = xs.zip(ys)
                .map!((t) => aes!("x","y")(t[0], t[1]))
                .geomHist2D.putIn(GGPlotD());
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
    import std.range : repeat, iota, chain, zip;
    import std.random : uniform;

    import ggplotd.aes : aes;
    import ggplotd.geom : geomDensity;
    import ggplotd.ggplotd : GGPlotD, putIn;
    import ggplotd.legend : discreteLegend;
    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25));
    auto gg = xs.zip(cols, 0.45.repeat(xs.length))
        .map!((a) => aes!("x", "colour", "fill")(a[0], a[1], a[2]))
        .geomDensity
        .putIn(GGPlotD());
    gg = discreteLegend.putIn(gg);
    gg.save( "filled_density.svg" );
}

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/density2D.png
    import std.algorithm : map;
    import std.range : iota, zip;
    import std.random : uniform, Random, unpredictableSeed;

    import ggplotd.aes : aes;
    import ggplotd.colour : colourGradient;
    import ggplotd.colourspace : XYZ;
    import ggplotd.geom : geomDensity2D;
    import ggplotd.ggplotd : GGPlotD, putIn;
    import ggplotd.legend : continuousLegend;

    // For debugging reasons, print out the current seed
    import std.stdio : writeln;
    auto seed = unpredictableSeed;
    auto rnd = Random(seed);
    //auto rnd = Random(1193462362); // This is a seed that currently fails. Use it for debugging
    writeln("Random seed MCMC: ", seed);

    auto xs = iota(0,500,1).map!((x) => uniform(0.0,5, rnd)+uniform(0.0,5, rnd));
    auto ys = iota(0,500,1).map!((y) => uniform(0.5,1.5, rnd)+uniform(0.5,1.5, rnd));
    auto gg = zip(xs, ys)
        .map!((a) => aes!("x","y")(a[0], a[1]))
        .geomDensity2D
        .putIn( GGPlotD() );
    // Use a different colour scheme
    gg.put( colourGradient!XYZ( "white-cornflowerBlue-crimson" ) );
    gg.put(continuousLegend);

    gg.save( "density2D.png" );
}

///
unittest
{
    /// http://blackedder.github.io/ggplotd/images/labels.png
    import std.algorithm : map;
    import std.range : zip;
    import std.math : PI;

    import ggplotd.aes : aes;
    import ggplotd.geom : geomPoint, geomLabel;
    import ggplotd.ggplotd : GGPlotD;
    import ggplotd.axes : xaxisRange, yaxisRange;
    auto dt = zip( [0.0,1,2,3,4], [4.0,3,2,1,0], 
        ["center", "left", "right", "bottom", "top"],
        [0.0, 0.0, 0.0, 0.0, 0.0],
        ["center", "left", "right", "bottom", "top"])
        .map!((a) => aes!("x", "y", "label", "angle", "justify")
            (a[0], a[1], a[2], a[3], a[4]));

    auto gg = GGPlotD()
        .put(geomPoint( dt ))
        .put(geomLabel(dt))
        .put(xaxisRange(-2,11))
        .put(yaxisRange(-2,11));

    auto dt2 = zip( [1.0,2,3,4,5], [5.0,4,3,2,1], 
        ["center", "left", "right", "bottom", "top"],
        [0.5*PI, 0.5*PI, 0.5*PI, 0.5*PI, 0.5*PI],
        ["center", "left", "right", "bottom", "top"])
        .map!((a) => aes!("x", "y", "label", "angle", "justify")
            (a[0], a[1], a[2], a[3], a[4]));
    gg.put( geomLabel(dt2) ).put(geomPoint(dt2));

    auto dt3 = zip( [1.0,2,4,6,7], [8.0,7,5,3,2], 
        ["center", "left", "right", "bottom", "top"],
        [0.25*PI, 0.25*PI, 0.25*PI, 0.25*PI, 0.25*PI],
        ["center", "left", "right", "bottom", "top"])
        .map!((a) => aes!("x", "y", "label", "angle", "justify")
            (a[0], a[1], a[2], a[3], a[4]));
    gg.put( geomLabel(dt3) ).put(geomPoint(dt3));

    gg.save( "labels.png" );
}

auto runMCMC() {
    import std.algorithm : map;
    import std.array : array;
    import std.math : pow;
    import std.range : iota; import std.random : Random, unpredictableSeed; 
    // For debugging reasons, print out the current seed
    import std.stdio : writeln;
    auto seed = unpredictableSeed;
    auto rnd = Random(seed);
    //auto rnd = Random(1193462362); // This is a seed that currently fails. Use it for debugging
    writeln("Random seed MCMC: ", seed);
    //writeln("Random seed MCMC: ", rnd.front);


    import dstats.random : rNormal;
    return iota(0,1000).map!((i) {
        auto x = rNormal(1, 0.5, rnd);
        auto y = rNormal(pow(x,3), 0.5, rnd);
        auto z = rNormal(x + y, 0.5, rnd);
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
    import ggplotd.ggplotd : Facets, GGPlotD, putIn;
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

            gg = format("Parameter %s", i).xaxisLabel.putIn(gg);
            if (i != j)
            {
                // Change the colourGradient used
                gg = colourGradient!XYZ( "white-cornflowerBlue-crimson" )
                    .putIn(gg);
                gg = format("Parameter %s", j).yaxisLabel.putIn(gg);
                gg = samples.map!((sample) => aes!("x", "y")(sample[i], sample[j]))
                    .geomDensity2D
                    .putIn(gg);
            } else {
                gg = "Density".yaxisLabel.putIn(gg);
                gg = samples.map!((sample) => aes!("x", "y")(sample[i], sample[j]))
                    .geomDensity
                    .putIn(gg);
            }
            facets = gg.putIn(facets);
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
    import ggplotd.ggplotd : GGPlotD, putIn;
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
    .geomPoint.putIn(GGPlotD());

    // Axis labels
    gg = "Carat".xaxisLabel.putIn(gg);
    gg = "Price".yaxisLabel.putIn(gg);
    gg.save("diamonds.png"); 
}

/// Multiple histograms examples
unittest
{
    // http://blackedder.github.io/ggplotd/images/filled_hist.svg
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain, zip;
    import std.random : uniform;

    import ggplotd.aes : aes;
    import ggplotd.geom : geomHist;
    import ggplotd.ggplotd : putIn, GGPlotD;

    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5)).array;
    auto cols = "a".repeat(25).chain("b".repeat(25));
    auto gg = xs.zip(cols)
        .map!((a) => aes!("x", "colour", "fill")(a[0], a[1], 0.45))
        .geomHist
        .putIn(GGPlotD());
    gg.save( "filled_hist.svg" );
}

/// Size as third dimension
unittest
{
    import std.range : zip;
    import std.algorithm : map;
    import ggplotd.aes : aes;
    import ggplotd.geom : geomPoint;
    import ggplotd.ggplotd : putIn, GGPlotD;
    import ggplotd.axes : xaxisRange, yaxisRange;

    auto gg = [0.0,1.0,2.0].zip([0.5, 0.25, 0.75], [1000, 10000, 50000])
        .map!((a) => aes!("x", "y", "size")(a[0], a[1], a[2]))
        .geomPoint
        .putIn(GGPlotD());
    gg.put(xaxisRange(-0.5, 2.5));
    gg.put(yaxisRange(0, 1));
    gg.save("sizeStore.png");
}

/// Boxplot example
unittest
{
    // http://blackedder.github.io/ggplotd/images/boxplot.svg
    import std.array : array;
    import std.algorithm : map;
    import std.range : repeat, iota, chain, zip;
    import std.random : uniform;

    import ggplotd.aes : aes;
    import ggplotd.geom : geomBox;
    import ggplotd.ggplotd : GGPlotD, putIn;

    auto xs = iota(0,50,1).map!((x) => uniform(0.0,5)+uniform(0.0,5));
    auto cols = "a".repeat(25).chain("b".repeat(25));
    auto gg = xs.zip(cols)
        .map!((a) => aes!("x", "colour", "fill", "label" )(a[0], a[1], 0.45, a[1]))
        .geomBox
        .putIn(GGPlotD());
    gg.save( "boxplot.svg" );
}

/// Changing axes details
unittest
{
    // http://blackedder.github.io/ggplotd/images/axes.svg
    import std.array : array;
    import std.math : sqrt;
    import std.algorithm : map;
    import std.range : iota;

    import ggplotd.aes : aes;
    import ggplotd.axes : xaxisLabel, yaxisLabel, xaxisOffset, yaxisOffset, 
		   xaxisRange, yaxisRange, xaxisLabelAngle;
    import ggplotd.geom : geomLine;
    import ggplotd.ggplotd : GGPlotD, putIn, Margins, title;
    import ggplotd.stat : statFunction;

    auto f = (double x) { return x/(1+x); };
    auto gg = statFunction(f, 0, 10.0)
        .geomLine
        .putIn(GGPlotD());

    // Setting range and label for xaxis
    gg.put( xaxisRange( 0, 8 ) )
		.put( xaxisLabel( "My xlabel" ) )
		.put( xaxisLabelAngle( 90 ) );
    // Setting range and label for yaxis
    gg.put( yaxisRange( 0, 2.0 ) ).put( yaxisLabel( "My ylabel" ) );

    // change offset
    gg.put( xaxisOffset( 0.25 ) ).put( yaxisOffset( 0.5 ) );

    // Change Margins 
    gg.put( Margins( 60, 60, 40, 30 ) );

    // Set a title
    gg.put( title( "And now for something completely different" ) );

    // Saving on a 500x300 pixel surface
    gg.save( "axes.svg", 500, 300 );
}

/// Example from the readme using aes and merge
unittest
{
    import ggplotd.aes : aes, merge;
    struct Data1
    {
        double value1 = 1.0;
        double value2 = 2.0;
    }

    Data1 dat1;

    // Merge to add a value
    auto merged = aes!("x", "y")(dat1.value1, dat1.value2)
        .merge(
            aes!("colour")("a")
        );
    assertEqual(merged.x, 1.0);
    assertEqual(merged.colour, "a");

    // Merge to a second data struct
    struct Data2 { string colour = "b"; } 
    Data2 dat2;

    auto merged2 = aes!("x", "y")(dat1.value1, dat1.value2)
        .merge( dat2 );
    assertEqual(merged2.x, 1.0);
    assertEqual(merged2.colour, "b");

    // Overriding a field 
    auto merged3 = aes!("x", "y")(dat1.value1, dat1.value2)
        .merge(
            aes!("y")("a")
        );
    assertEqual(merged3.y, "a");
}

/// Polygon
unittest
{
    import std.range : zip;
    import std.algorithm : map;
    import ggplotd.aes : aes;
    import ggplotd.geom : geomPolygon;
    import ggplotd.ggplotd : GGPlotD, putIn;

    // http://blackedder.github.io/ggplotd/images/polygon.png
    auto gg = zip([1, 0, 0.0], [1, 1, 0.0], [1, 0.1, 0])
        .map!((a) => aes!("x", "y", "colour")(a[0], a[1], a[2]))
        .geomPolygon
        .putIn(GGPlotD());
    gg.save( "polygon.png" );
}

/// Log scale
unittest
{
    import std.range : zip;
    import std.algorithm : map;
    import ggplotd.aes : aes;
    import ggplotd.scale : scale;
    import ggplotd.ggplotd : GGPlotD, putIn;
    import ggplotd.geom : geomLine;

    // http://blackedder.github.io/ggplotd/images/logScale.png
    auto gg = zip([1.0, 10.0, 15], [30, 100, 1000.0])
        .map!((a) => aes!("x", "y")(a[0], a[1]))
        .geomLine
        .putIn(GGPlotD());

    gg = scale!("x")("log").putIn(gg);
    gg = scale!("y")("log10").putIn(gg);
    gg.save( "logScale.png" );
}
