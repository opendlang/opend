# ggplotd

High level usage roughly follows grammar of graphics/ggplot. High level
usage example is as follows:

```D
import std.range : zip;

zip(xs,ys,ids)
    .aes!("x","y","colour") // Return a range of named tuples, with
                            // default values added
    .geom!("line")          // Transforms data into plot specific data
                            // structs (groups by colour etc if needed)
    .scale!("x", (x) => log(x)) // Returns data and function that
                                // transforms a context correctly
    .scale!("y", (y) => log(y)) // See above
    .print("plot.png");     // Takes data struct and scaling and
                            // plots axes, and data struct
```

## aes

Aes is the basic struct, which acts like a range and returns a tuple with
the x, y, colour values. We will need to make this somehow compatible with
missing y values and maybe later also with z values etc.

It might be good to at a coordinates function which converts the x and
y into numeric variables, so we can gracefully handle labelled points.

## geom

Each geom_? function should return a range. The range can act on different
amount of data. For example geom_point/geom_line will act on every point
separately, while geom_hist first group by colour/other grouping and act
on the whole set.

.front should return a tuple, with a function that acts on a context (and
draws the needed thing) and some associated “meta” data, such as colour,
bounding box up till now.

## colour

We need a colour space function that converts a value into a colour. It
might be interesting to also rangify this, so that each aes value gets
a colour. Colour spaces should work on strings -> discrete and numerical
-> continuous. Will basically be a function that analysis the whole range
of colours and returns a function that converts a value into a colour.

## scale 

Returns a function converting a coordinate to a function that sets the
correct transformation matrix on on a context. (And probably something
with axes drawing)

## print

Brings it all together. Needs a geom range and colourspace.


