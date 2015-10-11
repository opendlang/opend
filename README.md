# GGPlotD

GGPlotD is a plotting library for the D programming language. The design
is heavily inspired by ggplot2 for R, which is based on a general Grammar of
Graphics described by Leland Wilkinson. The library depends on cairo(D) for
the actual drawing. The library is designed to make it easy to build complex
plots from simple building blocks.

## Install

Easiest is to use dub and add the library to your dub configuration file,
which will automatically download the D dependencies. The library also
depends on cairo so you will need to have that installed. On ubuntu/debian
you can install cairo with:

``` 
sudo apt-get install libcairo2-dev 
```

### PDF and SVG support

Plotting to PDF and SVG is not supported yet (v0.0.1) but is the next
feature to be added. Note that by default cairoD disables pdf and svg
support. To enable it you need to add a local copy of cairoD that dub can
find:

```
git clone https://github.com/jpf91/cairoD.git
sed -i 's/PDF_SURFACE = false/PDF_SURFACE = true/g' cairoD/src/cairo/c/config.d
sed -i 's/SVG_SURFACE = false/SVG_SURFACE = true/g' cairoD/src/cairo/c/config.d
dub add-local cairoD
```

## Examples

At version v0.0.1 we only have quite basic support for simple plots.

```D 
unittest { 
auto aes = Aes!(double[],double[], string[])(
[1.0,0.9],[2.0,1.1], ["c", "d"] ); auto ge = geomPoint( aes ); ggplotdPNG(
ge, scale() ); }

unittest
{
    auto aes = Aes!(double[], double[], string[] )( 
            [1.0,2.0,1.1,3.0], 
            [3.0,1.5,1.1,1.8], 
            ["a","b","a","b"] );

    auto gl = geomLine( aes );
    ggplotdPNG( gl, scale() );
}

unittest
{
    auto aes = Aes!(double[], double[], string[] )( 
            [1.0,1.05,1.1,0.9,1.0,0.99,1.09,1.091], 
            [3.0,1.5,1.1,1.8], 
            ["a","a","b","b","a","a","a","a"] );

    auto gl = geomHist( aes );
    ggplotdPNG( gl, scale() );
}
```

## Extending GGplotD

Due to GGplotD’s design it is relatively straightforward to extend GGplotD to
support new types of plots. This is especially true if your function depends
on the already implemented base types geomLine and geomPoint. The main reason
for not having added more functions yet is lack of time. If you decide to
implement your own function then **please** open a pull request or at least
copy your code into an issue. That way we can all benefit from your work :)
Even if you think the code is not up to scratch it will be easier for the
maintainer(s) to take your code and adapt it than to start from scrap.


### geom*

In general a geom* function reads the data, does some transformation on it
and then returns a struct containing the transformed result. In GGPlotD
the low level geom* function such as geomLine and geomPoint draw directly
to a cairo.Context. Luckily most higher level geom* functions can just
rely on calling geomLine and geomPoint. For reference see below for the
geomHist drawing implementation. Again if you decide to define your own
function then please let us know and send us the code. That way we can add
the function to the library and everyone can benefit.

```D 
/// Draw histograms based on the x coordinates of the data (aes)
auto geomHist(AES)(AES aes)
{
    import std.algorithm : map;
    import std.array : array;
    import std.range : repeat;
    double[] xs;
    double[] ys;
    typeof(aes.front.colour)[] colours;
    foreach( grouped; group( aes ) ) // Split data by colour/id
    {
        auto bins = grouped
            .map!( (t) => t.x ) // Extract the x coordinates
            .array.bin( 11 );   // Bin the data
        foreach( bin; bins )
        {
            // Convert data into line coordinates
            xs ~= [ bin.range[0], bin.range[0],
               bin.range[1], bin.range[1] ];
            ys ~= [ 0, bin.count,
               bin.count, 0 ];

            // Each (new) line coordinate has the colour specified
            // in the original data
            colours ~= grouped.front.colour.repeat(4).array;
        }
    }
    // Use the xs/ys/colours to draw lines
    return geomLine( Aes!(typeof(xs),typeof(ys),typeof(colours))( xs, ys, colours ) );
}
```

Note that the above highlights the drawing part of the function.
Converting the data into bins is done in a separate bin function, which
can be found in the [code](./source/ggplotd/geom.d#L127).

### stat*

ggplot2 for R defines a number of functions that plot statistics of the
data. GGplotD does not come with any such functions out of the box, but
the implementation should be very similar to the above named geom*
functions. The main difference will be that a stat function will have to
do more data analysis. In that way the line between geom and stat
functions is quite blurry; it could be argued that geomHist is a stat
function. If you are interested in adding support for more advanced
statistics then you should use the [geom* example](#geom) as a starting
point. 

## References

Wilkinson, Leland. The Grammar of Graphics. Springer Science & Business Media, 2013.

