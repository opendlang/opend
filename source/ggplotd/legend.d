module ggplotd.legend;

/+
Continuous in many way is a small GGPlotD object, that can be drawn to the main surface. So just define an aes for the polygon, with the apropiate y values. Set x ticks to empty.

Discrete is just number of lines (unmasked) with labels next to them. We can recreate this, as a GGPlotD() struct, by moving axis outside of plane (offset).

Note that not only colour, but also size is often used as an indicator.
+/
