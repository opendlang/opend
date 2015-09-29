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

Aes is supposed to be composable. I.e. the following should work:

```D
xs.aes("x") + ys.aes("y"); // Combine into x and y vector
zip(xs1,ys1).aes("x","y") + zip(xs2,ys2).aes("x","y"); // Append data sets
```
