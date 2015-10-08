This document contains some overall design ideas and some simple notes on
implementation. I use it as a personal brainstorming document, and the
ideas can evolve while implementing them. The document is, therefore, not
guaranteed to be up to date (or coherent) and mainly in the git
repository for my own convenience.

# ggplotd

The design goal behind ggplotd is to split plotting into separate
composable elements. Plots actually often have a lot of interacting
components, making it quite difficult to decide on how to separate them
all into separate elements. The separation we use here is inspired by the elements used in the Grammar of Graphics and the ggplot library of R. In
general a plot follows the following logic. We start with data, we convert
that to points and lines, with points and lines having their own
attributes (colour ids and size for example). Other components that we
need are the scaling of the axes and the mapping of colour ids to actual
colours. Finally all this is combined into a plot.

Interesting this flow also makes it natural where to define things. For
example colour IDs are only needed at the point and line step, so we can
give them there, but we can also provide them earlier in the process by
giving them as attached to the data.

By following these rules strictly it becomes much easier to define new
plots/data analysis. For example if we want to add a histogram plot, we
won’t need to add a whole new plot that implements scaling etc. We just
need to read the data and convert it into lines. All the other components
will still work exactly the same way.

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

# General data structures

## Flexible range

Range that can be used for all the aes stuff. If given one value it will
just cycle over that value. If given range it will act as a range. Maybe
also option of default value in a template. dim returns left over length
of original array. Will need to check whether all given ranges have dim 1,
otherwise we will cycle forever. (Aes.empty() {return xs.dim<=0 && ys.dim
<=0 ). This makes me doubt if this is actually the best design)

## Label map

Map labels to coordinates and the other way around. Needed when provided
with labelled data instead of numerical data.

```D 
labelledx.map!((xl) => mapx.toCoord(xl)
```

## GGContext

Build on top of cairo context, but can take full scaling exp (x) =>
log(x). Other than that, implement point, line and colour functions.
