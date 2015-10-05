# GGPlotD

GGPlotD is a plotting library for the D programming language. The design
is heavily inspired by ggplot2 for R, which is based on a general Grammar of
Graphics described by Leland Wilkinson. The library depends on cairo(D) for
the actual drawing. The library is designed to make it easy to build complex
plots from simple building blocks.

## Install

Easiest is to use dub and add the library to your dub configuration file,
which will automatically download the D dependencies. The library also depends
on cairo so you will need to have that installed.

### PDF and SVG support

By default cairoD disables pdf and svg support. To enable it you need to add
a local copy of cairoD that dub can find:

```
git clone https://github.com/jpf91/cairoD.git
sed -i 's/PDF_SURFACE = false/PDF_SURFACE = true/g' cairoD/src/cairo/c/config.d
sed -i 's/SVG_SURFACE = false/SVG_SURFACE = true/g' cairoD/src/cairo/c/config.d
dub add-local cairoD
```

## Examples

To come.

## Extending ggplotd

Due to ggplotd’s design it is relatively straightforward to extend ggplotd to
support new types of plots. This is especially true if your function depends
on the already implemented base types geomLine and geomPoint. The main reason
for not having added more functions yet is lack of time. If you decide to
implement your own function then **please** open a pull request or at least
copy your code into an issue. That way we can all benefit from your work :)
Even if you think the code is not up to scratch it will be much easier for
the maintainers to take your code and adapt it than to start from scrap.


### geom*

In general a geom* function reads the data, does some transformation on it and
then returns a struct containing the transformed result. For reference see
below for the geomHist implementation. That should get you started on defining
your own geom function. Again if you decide to define your own function then
please let us know and send us the code. That way we can add the function to
the library and everyone can benefit.

```D 
//TODO: To come! 
```

### stat*

ggplot2 for R defines a number of function that plot statistics of the data.
GGPlotD does not come with any such functions out of the box, but the
implementation should be very similar to the above named geom* functions. The
main difference will be that a stat function will have to do more data
analysis. If you are interested in adding support for certain statistics then
you should use the geom* functions as a starting point.

## References

Wilkinson, Leland. The Grammar of Graphics. Springer Science & Business Media, 2013.

